import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Rectangle {
    id: root

    property var tabs: []
    property int currentTab: 0
    property int editingTabIndex: -1

    signal tabClicked(int index)
    signal tabClosed(int index)
    signal tabRenamed(int index, string newName)
    signal newTabRequested()

    implicitHeight: 48
    color: Appearance.colors.colLayer0
    radius: Appearance.rounding.normal

    function scrollToEnd() {
        Qt.callLater(() => {
            scrollView.ScrollBar.horizontal.position = 1.0 - scrollView.ScrollBar.horizontal.size;
        });
    }

    ScrollView {
        id: scrollView
        anchors {
            left: parent.left
            right: newTabButton.left
            top: parent.top
            bottom: parent.bottom
            leftMargin: 8
            topMargin: 8
            bottomMargin: 8
            rightMargin: 4
        }
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AsNeeded
        ScrollBar.vertical.policy: ScrollBar.AlwaysOff

        Row {
            spacing: 6

            Repeater {
                model: ScriptModel {
                    values: root.tabs
                }

                delegate: Item {
                    id: tabDelegate
                    required property var modelData
                    required property int index

                    property bool isActive: root.currentTab === index
                    property bool isEditing: root.editingTabIndex === index

                    width: contentRow.width + 18
                    height: 32

                    Connections {
                        target: root
                        function onEditingTabIndexChanged() {
                            if (root.editingTabIndex !== tabDelegate.index && tabNameInput.activeFocus) {
                                tabNameInput.focus = false;
                            }
                        }
                    }

                    Rectangle {
                        id: tabBg
                        anchors.fill: parent

                        radius: Appearance.rounding.normal
                        color: isActive ? Appearance.colors.colPrimaryContainer : (tabMouseArea.containsMouse ? Appearance.colors.colLayer1 : "transparent")

                        Behavior on color {
                            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(tabBg)
                        }

                    }

                    Row {
                        id: contentRow
                        anchors.centerIn: parent
                        spacing: 6

                        StyledTextInput {
                            id: tabNameInput
                            width: Math.max(16, contentWidth + 4)
                            height: tabBg.height
                            visible: isEditing
                            text: tabDelegate.modelData.name || "Untitled"
                            font.family: Appearance.font.family.title
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer1
                            verticalAlignment: TextInput.AlignVCenter

                            Keys.onReturnPressed: {
                                root.tabRenamed(tabDelegate.index, text);
                                root.editingTabIndex = -1;
                            }
                            Keys.onEscapePressed: {
                                text = tabDelegate.modelData.name;
                                root.editingTabIndex = -1;
                            }

                            onActiveFocusChanged: {
                                if (!activeFocus && isEditing) {
                                    root.tabRenamed(tabDelegate.index, text);
                                    root.editingTabIndex = -1;
                                }
                            }

                            onVisibleChanged: {
                                if (!visible && activeFocus) {
                                    focus = false;
                                }
                            }

                            Component.onCompleted: {
                                if (isEditing) {
                                    Qt.callLater(() => {
                                        forceActiveFocus();
                                        selectAll();
                                    });
                                }
                            }
                        }

                        StyledText {
                            id: tabNameText
                            height: tabBg.height
                            anchors.verticalCenter: parent.verticalCenter
                            visible: !isEditing
                            text: tabDelegate.modelData.name || "Untitled"
                            font.family: Appearance.font.family.title
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: isActive ? Font.Medium : Font.Normal
                            color: isActive ? Appearance.colors.colOnLayer1 : Appearance.colors.colSubtext

                            Behavior on color {
                                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                            }
                        }

                        Rectangle {
                            width: 20
                            height: 20
                            anchors.verticalCenter: parent.verticalCenter
                            visible: root.tabs.length > 1
                            radius: Appearance.rounding.small
                            color: closeMouseArea.containsMouse ? Appearance.colors.colLayer2 : "transparent"

                            Behavior on color {
                                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                            }

                            MaterialSymbol {
                                anchors.centerIn: parent
                                height: tabBg.height
                                text: "close"
                                iconSize: 14
                                color: Appearance.colors.colSubtext

                                Behavior on color {
                                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                                }
                            }

                            MouseArea {
                                id: closeMouseArea
                                anchors.fill: parent
                                anchors.margins: -2
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.tabClosed(tabDelegate.index)
                            }
                        }
                    }

                    MouseArea {
                        id: tabMouseArea
                        anchors.fill: tabBg
                        anchors.rightMargin: root.tabs.length > 1 ? 24 : 0
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor

                        onClicked: mouse => {
                            if (mouse.button === Qt.LeftButton) {
                                root.tabClicked(tabDelegate.index);
                            } else if (mouse.button === Qt.RightButton) {
                                root.editingTabIndex = tabDelegate.index;
                                tabNameInput.forceActiveFocus();
                                tabNameInput.selectAll();
                            }
                        }
                    }
                }
            }
        }
    }

    RippleButton {
        id: newTabButton
        anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
            rightMargin: 8
        }
        width: 32
        height: 32
        buttonRadius: Appearance.rounding.small
        colBackground: "transparent"
        colBackgroundHover: Appearance.colors.colLayer1

        onClicked: root.newTabRequested()

        contentItem: MaterialSymbol {
            anchors.centerIn: parent
            text: "add"
            iconSize: 16
            color: Appearance.colors.colSubtext
        }
    }
}
