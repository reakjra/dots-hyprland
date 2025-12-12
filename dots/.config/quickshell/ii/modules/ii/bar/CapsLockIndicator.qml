import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets

Revealer {
    id: root
    property bool vertical: false
    property color color: Appearance.colors.colOnSurfaceVariant
    property bool capsLockOn: false
    property real spacing: 15

    reveal: capsLockOn
    Layout.fillHeight: true
    Layout.rightMargin: reveal ? (vertical ? 0 : spacing) : 0
    Layout.bottomMargin: reveal ? (vertical ? spacing : 0) : 0

    Behavior on Layout.rightMargin {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    Behavior on Layout.bottomMargin {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
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

    MaterialSymbol {
        id: capsIcon
        anchors.centerIn: parent
        text: "shift"
        iconSize: Appearance.font.pixelSize.larger
        color: root.color
    }
}
