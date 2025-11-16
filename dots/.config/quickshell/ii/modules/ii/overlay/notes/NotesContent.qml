import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.overlay

OverlayBackground {
    id: root

    property alias content: textInput.text
    property bool pendingReload: false
    property var copyListEntries: []
    property string lastParsedCopylistText: ""
    property var parsedCopylistLines: []
    property bool isClickthrough: false
    property real maxCopyButtonSize: 20
    property bool previewMode: false

    property int currentTabIndex: Persistent.states.overlay.notes.currentTab
    property bool tabBarVisible: Persistent.states.overlay.notes.tabBarVisible
    property var noteFileViews: ({})
    property var tabs: []

    Component.onCompleted: {
        tabs = Persistent.states.overlay.notes.tabs;
        loadCurrentTab();
        updateCopyListEntries();
    }

    Connections {
        target: Persistent.states.overlay.notes
        function onTabsChanged() {
            root.tabs = Persistent.states.overlay.notes.tabs;
        }
    }

    function getCurrentTabId() {
        if (currentTabIndex >= 0 && currentTabIndex < tabs.length) {
            return tabs[currentTabIndex].id;
        }
        return "default";
    }

    function getNotePath(tabId) {
        return `${Directories.notesDir}/${tabId}.txt`;
    }

    function loadCurrentTab() {
        const tabId = getCurrentTabId();
        if (!noteFileViews[tabId]) {
            createFileView(tabId);
        } else {
            noteFileViews[tabId].reload();
        }
    }

    function createFileView(tabId) {
        const component = Qt.createComponent("Quickshell.Io", "FileView");
        if (component.status === Component.Ready) {
            const fileView = component.createObject(root, {
                path: Qt.resolvedUrl(getNotePath(tabId))
            });

            fileView.onLoaded.connect(() => {
                if (getCurrentTabId() === tabId) {
                    root.content = fileView.text();
                    if (pendingReload) {
                        pendingReload = false;
                        Qt.callLater(root.focusAtEnd);
                    }
                    Qt.callLater(root.updateCopyListEntries);
                }
            });

            fileView.onLoadFailed.connect((error) => {
                if (error === FileViewError.FileNotFound) {
                    fileView.setText("");
                    if (getCurrentTabId() === tabId) {
                        root.content = "";
                        if (pendingReload) {
                            pendingReload = false;
                            Qt.callLater(root.focusAtEnd);
                        }
                        Qt.callLater(root.updateCopyListEntries);
                    }
                }
            });

            noteFileViews[tabId] = fileView;
            fileView.reload();
        }
    }

    function switchToTab(index) {
        if (index >= 0 && index < tabs.length) {
            saveContent();
            currentTabIndex = index;
            Persistent.states.overlay.notes.currentTab = index;
            loadCurrentTab();
        }
    }

    function addNewTab() {
        const newId = `note_${Date.now()}`;
        const newTab = { "name": "New Tab", "id": newId };
        let updatedTabs = tabs.slice();
        updatedTabs.push(newTab);
        Persistent.states.overlay.notes.tabs = updatedTabs;
        tabs = updatedTabs;
        switchToTab(tabs.length - 1);
    }

    function closeTab(index) {
        if (tabs.length <= 1) return;

        let updatedTabs = tabs.slice();
        const removedTab = updatedTabs[index];
        updatedTabs.splice(index, 1);

        Persistent.states.overlay.notes.tabs = updatedTabs;

        if (currentTabIndex >= updatedTabs.length) {
            currentTabIndex = updatedTabs.length - 1;
            Persistent.states.overlay.notes.currentTab = currentTabIndex;
        } else if (currentTabIndex === index) {
            currentTabIndex = Math.max(0, index - 1);
            Persistent.states.overlay.notes.currentTab = currentTabIndex;
        }

        loadCurrentTab();
    }

    function renameTab(index, newName) {
        let updatedTabs = tabs.slice();
        updatedTabs[index] = { "name": newName, "id": updatedTabs[index].id };
        Persistent.states.overlay.notes.tabs = updatedTabs;
        tabs = updatedTabs;
    }

    function saveContent() {
        if (!textInput)
            return;
        const tabId = getCurrentTabId();
        if (noteFileViews[tabId]) {
            noteFileViews[tabId].setText(root.content);
        }
    }

    function focusAtEnd() {
        if (!textInput)
            return;
        textInput.forceActiveFocus();
        const endPos = root.content.length;
        applySelection(endPos, endPos);
    }

    function applySelection(cursorPos, anchorPos) {
        if (!textInput)
            return;
        const textLength = root.content.length;
        const cursor = Math.max(0, Math.min(cursorPos, textLength));
        const anchor = Math.max(0, Math.min(anchorPos, textLength));
        textInput.select(anchor, cursor);
        if (cursor === anchor)
            textInput.deselect();
    }

    function scheduleCopylistUpdate(immediate = false) {
        if (!textInput)
            return;
        if (immediate) {
            copyListDebounce?.stop();
            updateCopyListEntries();
        } else {
            copyListDebounce.restart();
        }
    }

    function updateCopyListEntries() {
        if (!textInput)
            return;
        const textValue = root.content;
        if (!textValue || textValue.length === 0) {
            lastParsedCopylistText = "";
            parsedCopylistLines = [];
            root.copyListEntries = [];
            return;
        }

        if (textValue !== lastParsedCopylistText) {
            const lineRegex = /(.*?)(\r?\n|$)/g;
            let match = null;
            const parsed = [];
            while ((match = lineRegex.exec(textValue)) !== null) {
                const lineText = match[1];
                const newlineText = match[2];
                const lineStart = match.index;
                const lineEnd = lineStart + lineText.length;
                const bulletMatch = lineText.match(/^\s*-\s+(.*\S)\s*$/);
                if (bulletMatch) {
                    parsed.push({
                        content: bulletMatch[1].trim(),
                        start: lineStart,
                        end: lineEnd
                    });
                }
                if (newlineText === "")
                    break;
            }
            lastParsedCopylistText = textValue;
            parsedCopylistLines = parsed;
            if (parsed.length === 0) {
                root.copyListEntries = [];
                return;
            }
        }

        updateCopylistPositions();
    }

    function updateCopylistPositions() {
        if (!textInput || parsedCopylistLines.length === 0)
            return;
        const rawSelectionStart = textInput.selectionStart;
        const rawSelectionEnd = textInput.selectionEnd;
        const selectionStart = rawSelectionStart === -1 ? textInput.cursorPosition : rawSelectionStart;
        const selectionEnd = rawSelectionEnd === -1 ? textInput.cursorPosition : rawSelectionEnd;
        const rangeStart = Math.min(selectionStart, selectionEnd);
        const rangeEnd = Math.max(selectionStart, selectionEnd);

        const entries = parsedCopylistLines.map(line => {
            // Don't show copy button if line is (partially) selected
            const caretIntersects = rangeEnd > line.start && rangeStart <= line.end;
            if (caretIntersects)
                return null;
            const startRect = textInput.positionToRectangle(line.start);
            let endRect = textInput.positionToRectangle(line.end);
            if (!isFinite(startRect.y))
                return null;
            if (!isFinite(endRect.y))
                endRect = startRect;
            const lineBottom = endRect.y + endRect.height;
            const rectHeight = Math.max(lineBottom - startRect.y, textInput.font.pixelSize + 8);
            return {
                content: line.content,
                y: startRect.y,
                height: rectHeight
            };
        }).filter(entry => entry !== null);

        root.copyListEntries = entries;
    }

    implicitWidth: 300
    implicitHeight: 200

    ColumnLayout {
        id: contentItem
        anchors.fill: parent
        spacing: 0

        NotesTabBar {
            id: tabBar
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            Layout.topMargin: 6
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            Layout.bottomMargin: 4
            visible: root.tabBarVisible
            tabs: root.tabs
            currentTab: root.currentTabIndex

            onTabClicked: index => root.switchToTab(index)
            onTabClosed: index => root.closeTab(index)
            onTabRenamed: (index, newName) => root.renameTab(index, newName)
            onNewTabRequested: root.addNewTab()
        }

        ScrollView {
            id: editorScrollView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.vertical.policy: ScrollBar.AsNeeded
            onWidthChanged: root.scheduleCopylistUpdate(true)

            StyledTextArea { // This has to be a direct child of ScrollView for proper scrolling
                id: textInput
                anchors {
                    left: parent.left
                    right: parent.right
                }
                visible: !root.previewMode
                wrapMode: TextEdit.Wrap
                placeholderText: Translation.tr("Write something here...\nUse '-' to create copyable bullet points, like this:\n\nSheep fricker\n- 4x Slab\n- 1x Boat\n- 4x Redstone Dust\n- 1x Sticky Piston\n- 1x End Rod\n- 4x Redstone Repeater\n- 1x Redstone Torch\n- 1x Sheep")
                selectByMouse: true
                persistentSelection: true
                textFormat: TextEdit.PlainText
                background: null
                padding: 24

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_M && (event.modifiers & Qt.ControlModifier)) {
                        root.previewMode = !root.previewMode;
                        event.accepted = true;
                    } else if (event.key === Qt.Key_T && (event.modifiers & Qt.ControlModifier)) {
                        root.tabBarVisible = !root.tabBarVisible;
                        Persistent.states.overlay.notes.tabBarVisible = root.tabBarVisible;
                        event.accepted = true;
                    }
                }

                onTextChanged: {
                    if (textInput.activeFocus) {
                        saveDebounce.restart();
                    }
                    root.scheduleCopylistUpdate(true);
                }
                
                onHeightChanged: root.scheduleCopylistUpdate(true)
                onContentHeightChanged: root.scheduleCopylistUpdate(true)
                onCursorPositionChanged: root.scheduleCopylistUpdate()
                onSelectionStartChanged: root.scheduleCopylistUpdate()
                onSelectionEndChanged: root.scheduleCopylistUpdate()
            }

            Item {
                id: previewContainer
                anchors {
                    left: parent.left
                    right: parent.right
                }
                visible: root.previewMode
                implicitHeight: previewText.implicitHeight
                focus: root.previewMode

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_M && (event.modifiers & Qt.ControlModifier)) {
                        root.previewMode = false;
                        textInput.forceActiveFocus();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_T && (event.modifiers & Qt.ControlModifier)) {
                        root.tabBarVisible = !root.tabBarVisible;
                        Persistent.states.overlay.notes.tabBarVisible = root.tabBarVisible;
                        event.accepted = true;
                    }
                }

                StyledText {
                    id: previewText
                    anchors {
                        left: parent.left
                        right: parent.right
                    }
                    leftPadding: 24
                    rightPadding: 24
                    topPadding: 24
                    bottomPadding: 24
                    text: root.content
                    textFormat: Text.MarkdownText
                    wrapMode: Text.Wrap
                    onLinkActivated: link => Qt.openUrlExternally(link)
                }

                Component.onCompleted: {
                    if (root.previewMode) forceActiveFocus();
                }
            }

            Connections {
                target: root
                function onPreviewModeChanged() {
                    if (root.previewMode) {
                        previewContainer.forceActiveFocus();
                    }
                }
            }

            Item {
                anchors.fill: parent
                visible: !root.previewMode && root.copyListEntries.length > 0
                clip: true

                Repeater {
                    model: ScriptModel {
                        values: root.copyListEntries
                    }
                    delegate: RippleButton {
                        id: copyButton
                        required property var modelData
                        readonly property real lineHeight: Math.min(Math.max(modelData.height, Appearance.font.pixelSize.normal + 6), root.maxCopyButtonSize)
                        readonly property real iconSizeLocal: Appearance.font.pixelSize.normal
                        readonly property real hitPadding: 6
                        property bool justCopied: false

                        implicitHeight: lineHeight
                        implicitWidth: lineHeight
                        buttonRadius: height / 2
                        y: modelData.y
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        z: 5

                        Timer {
                            id: resetState
                            interval: 700
                            onTriggered: {
                                copyButton.justCopied = false;
                            }
                        }

                        onClicked: {
                            Quickshell.clipboardText = copyButton.modelData.content;
                            justCopied = true;
                            resetState.start();
                        }

                        contentItem: Item {
                            anchors.centerIn: parent
                            MaterialSymbol {
                                id: iconItem
                                anchors.centerIn: parent
                                text: copyButton.justCopied ? "check" : "content_copy"
                                iconSize: copyButton.iconSizeLocal
                                color: Appearance.colors.colOnLayer1
                            }
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 16
            spacing: 12

            StyledText {
                id: modeIndicator
                Layout.alignment: Qt.AlignLeft
                text: {
                    const mode = root.previewMode ? Translation.tr("Preview") : Translation.tr("Edit");
                    return `${mode} (Ctrl+M | Ctrl+T)`;
                }
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.small * 0.85
            }

            Item {
                Layout.fillWidth: true
            }

            StyledText {
                id: statusLabel
                Layout.alignment: Qt.AlignRight
                text: saveDebounce.running ? Translation.tr("Saving...") : Translation.tr("Saved    ")
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.small * 0.85
            }
        }
    }

    Timer {
        id: saveDebounce
        interval: 500
        repeat: false
        onTriggered: saveContent()
    }

    Timer {
        id: copyListDebounce
        interval: 100
        repeat: false
        onTriggered: updateCopylistPositions()
    }
}
