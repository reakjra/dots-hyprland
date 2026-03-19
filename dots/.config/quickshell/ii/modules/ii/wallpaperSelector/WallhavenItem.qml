import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

MouseArea {
    id: root
    property string thumbUrl
    property string resolution
    property string ratio
    property int views
    property int favorites
    property bool isDownloading: false

    property alias colBackground: background.color
    property alias colText: infoText.color
    property alias radius: background.radius
    property alias margins: background.anchors.margins
    margins: Appearance.sizes.wallpaperSelectorItemMargins

    signal activated()

    hoverEnabled: true
    onClicked: root.activated()

    Rectangle {
        id: background
        anchors.fill: parent
        radius: Appearance.rounding.normal
        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        ColumnLayout {
            id: contentLayout
            anchors {
                fill: parent
                margins: Appearance.sizes.wallpaperSelectorItemPadding
            }
            spacing: 4

            Item {
                id: imageContainer
                Layout.fillHeight: true
                Layout.fillWidth: true

                Image {
                    id: thumbImage
                    anchors.fill: parent
                    source: root.thumbUrl
                    fillMode: Image.PreserveAspectCrop
                    clip: true
                    cache: true
                    asynchronous: true

                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: imageContainer.width
                            height: imageContainer.height
                            radius: Appearance.rounding.small
                        }
                    }
                }

                Loader {
                    active: thumbImage.status === Image.Loading
                    anchors.centerIn: parent
                    sourceComponent: MaterialLoadingIndicator {}
                }

                // Download overlay
                Rectangle {
                    visible: root.isDownloading
                    anchors.fill: parent
                    radius: Appearance.rounding.small
                    color: ColorUtils.transparentize(Appearance.colors.colLayer0, 0.4)
                    MaterialLoadingIndicator {
                        anchors.centerIn: parent
                    }
                }

                // Fav count badge
                Rectangle {
                    visible: root.favorites > 0
                    anchors {
                        bottom: parent.bottom
                        right: parent.right
                        margins: 6
                    }
                    width: favRow.implicitWidth + 10
                    height: favRow.implicitHeight + 4
                    radius: Appearance.rounding.full
                    color: ColorUtils.transparentize(Appearance.m3colors.m3surfaceContainer, 0.3)

                    Row {
                        id: favRow
                        anchors.centerIn: parent
                        spacing: 2
                        MaterialSymbol {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "favorite"
                            iconSize: Appearance.font.pixelSize.smaller
                            fill: 1
                            color: Appearance.colors.colError
                        }
                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.favorites
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colOnLayer0
                        }
                    }
                }
            }

            StyledText {
                id: infoText
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                font.pixelSize: Appearance.font.pixelSize.smaller
                Behavior on color {
                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                }
                text: root.ratio ? `${root.resolution} · ${root.ratio}` : root.resolution
            }
        }
    }
}
