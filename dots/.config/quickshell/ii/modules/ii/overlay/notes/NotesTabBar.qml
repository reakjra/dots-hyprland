import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    property var tabs: []
    property int currentTab: 0
    property int editingTabIndex: -1

    signal tabClicked(int index)
    signal tabClosed(int index)
    signal tabRenamed(int index, string newName)
    signal newTabRequested()

    implicitHeight: 30

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
            rightMargin: 6
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

                    width: tabBg.width
                    height: 26

                    Rectangle {
                        id: tabBg
                        width: contentRow.width + 20
                        height: parent.height
                        radius: Appearance.rounding.small
                        color: isActive ? Appearance.colors.colSecondaryContainer : (tabMouseArea.containsMouse ? Appearance.colors.colLayer2 : Appearance.colors.colLayer1)
                        opacity: isActive ? 1.0 : (tabMouseArea.containsMouse ? 0.7 : 0.5)

                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                                easing.type: Easing.OutCubic
                            }
                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 150
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    Row {
                        id: contentRow
                        anchors.centerIn: parent
                        spacing: 2

                        StyledTextInput {
                            id: tabNameInput
                            width: Math.max(40, implicitWidth)
                            height: tabBg.height
                            visible: isEditing
                            text: tabDelegate.modelData.name || "Untitled"
                            font.pixelSize: Appearance.font.pixelSize.small
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
                        }

                        StyledText {
                            id: tabNameText
                            anchors.verticalCenter: parent.verticalCenter
                            visible: !isEditing
                            text: tabDelegate.modelData.name || "Untitled"
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: isActive ? Font.Medium : Font.Normal
                            color: isActive ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnSurface

                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }
                            }
                        }

                        Item {
                            width: 6
                            height: 1
                            visible: root.tabs.length > 1
                        }

                        Rectangle {
                            width: 16
                            height: 16
                            anchors.verticalCenter: parent.verticalCenter
                            visible: root.tabs.length > 1
                            radius: 8
                            color: closeMouseArea.containsMouse ? Appearance.colors.colLayer3 : "transparent"

                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }
                            }

                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "close"
                                iconSize: 12
                                color: isActive ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colSubtext
                                opacity: closeMouseArea.containsMouse ? 1.0 : 0.6

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 150
                                    }
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
                        anchors.rightMargin: root.tabs.length > 1 ? 18 : 0
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

    Item {
        id: newTabButton
        anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
        width: 24
        height: 24

        RippleButton {
            anchors.fill: parent
            buttonRadius: Appearance.rounding.small
            colBackground: Appearance.colors.colLayer2
            colBackgroundHover: Appearance.colors.colLayer3

            onClicked: root.newTabRequested()

            contentItem: MaterialSymbol {
                anchors.fill: parent
                text: "add"
                iconSize: 16
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: Appearance.colors.colOnSurface
            }
        }
    }
}
