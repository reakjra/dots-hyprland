pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

// Seperate store for color overrides + presets so they dont bloat config.json
Singleton {
    id: root
    property string filePath: Directories.colorOverridesPath
    property alias data: overrideAdapter
    property bool ready: false
    property int readWriteDelay: 50

    Timer {
        id: fileReloadTimer
        interval: root.readWriteDelay
        repeat: false
        onTriggered: overrideFileView.reload()
    }

    Timer {
        id: fileWriteTimer
        interval: root.readWriteDelay
        repeat: false
        onTriggered: overrideFileView.writeAdapter()
    }

    FileView {
        id: overrideFileView
        path: root.filePath
        watchChanges: true
        onFileChanged: fileReloadTimer.restart()
        onAdapterUpdated: fileWriteTimer.restart()
        onLoaded: root.ready = true
        onLoadFailed: error => {
            if (error == FileViewError.FileNotFound) {
                writeAdapter()
            }
        }

        JsonAdapter {
            id: overrideAdapter
            // Stringified JSON bc dynamic keys cant be JsonObject properteis
            property string colorOverrides: "{}"
            property string customPresets: "[]"
            property bool preserveOnWallpaperChange: false
        }
    }
}
