import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets

Loader {
    id: root
    property bool vertical: false
    property color color: Appearance.colors.colOnSurfaceVariant
    property bool capsLockOn: false

    active: capsLockOn && (Config?.options.bar.indicators.capsLock.enable ?? true)
    visible: active
    opacity: active ? 1 : 0

    Behavior on opacity {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(root)
    }

    Timer {
        interval: 200
        running: true
        repeat: true
        onTriggered: checkCapsLock.running = true
    }

    Process {
        id: checkCapsLock
        command: ["bash", "-c", "cat /sys/class/leds/*capslock/brightness 2>/dev/null | head -n1"]

        stdout: StdioCollector {
            onStreamFinished: {
                const value = text.trim()
                root.capsLockOn = (value === "1")
            }
        }
    }

    sourceComponent: MaterialSymbol {
        text: "font_download"
        fill: root.capsLockOn ? 1 : 0
        iconSize: Appearance.font.pixelSize.larger
        color: root.color
    }
}
