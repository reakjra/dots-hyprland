pragma ComponentBehavior: Bound
import QtQuick
import Qt5Compat.GraphicalEffects
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.utils
import qs.modules.ii.overlay

StyledOverlayWidget {
    id: root
    showClickabilityButton: false
    resizable: true
    clickthrough: true
    minimumWidth: 50
    minimumHeight: 50

    property string imageSource: Config.options.overlay.floatingImage.imageSource
    property real scaleFactor: Config.options.overlay.floatingImage.scale
    property int imageWidth: 0
    property int imageHeight: 0

    onImageSourceChanged: {
        imageDownloader.running = false;
        imageDownloader.sourceUrl = root.imageSource;
        imageDownloader.filePath = Qt.resolvedUrl(Directories.tempImages + "/" + Qt.md5(root.imageSource))
        imageDownloader.running = true;
    }

    contentItem: OverlayBackground {
        id: bg
        anchors.fill: parent
        color: ColorUtils.transparentize(Appearance.m3colors.m3surfaceContainer, root.actuallyPinned ? 1 : 0)
        radius: root.contentRadius

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: bg.width
                height: bg.height
                radius: bg.radius
            }
        }

        AnimatedImage {
            id: animatedImage
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            sourceSize.width: width
            sourceSize.height: height

            playing: visible
            asynchronous: true
            source: ""

            ImageDownloaderProcess {
                id: imageDownloader
                filePath: Qt.resolvedUrl(Directories.tempImages + "/" + Qt.md5(root.imageSource))
                sourceUrl: root.imageSource

                onDone: (path, width, height) => {
                    root.imageWidth = width;
                    root.imageHeight = height;

                    // Initial sizing if not set
                    if (root.persistentStateEntry.width <= 1) {
                        let initialScale = root.scaleFactor > 0 ? root.scaleFactor : 1.0;
                        root.savePosition(root.x, root.y, width * initialScale, height * initialScale);
                    }

                    animatedImage.source = path;
                }
            }
        }
    }
}
