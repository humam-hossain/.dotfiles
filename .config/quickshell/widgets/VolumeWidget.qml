import QtQuick
import Quickshell.Io
import qs.theme
import qs.services
import "../" as Local

Local.ModulePill {
    id: root
    visible: AudioService.defaultSink !== null

    Row {
        spacing: 4

        Text {
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 14
            font.bold: true
            color: Colours.textColor
            opacity: AudioService.muted ? 0.6 : 1.0
            text: {
                if (AudioService.muted || AudioService.volumePercent === 0) return ""
                if (AudioService.volumePercent < 33)                         return ""
                if (AudioService.volumePercent < 66)                         return ""
                return ""
            }
        }

        Text {
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 14
            font.bold: true
            color: Colours.textColor
            opacity: AudioService.muted ? 0.6 : 1.0
            text: AudioService.volumePercent + "%"
        }
    }

    Process {
        id: pavucontrolProc
        command: ["pavucontrol"]
        running: false
        onExited: code => { if (code !== 0) console.warn("pavucontrol exited", code) }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton)       pavucontrolProc.startDetached()
            else if (mouse.button === Qt.RightButton) AudioService.toggleMute()
        }
        onWheel: wheel => {
            const step = 5 * Math.sign(wheel.angleDelta.y)
            AudioService.bumpVolume(step)
        }
    }

    ToolTip.visible: hover.hovered
    ToolTip.text: "Default sink: " + AudioService.sinkName + " — " + AudioService.volumePercent + "%" + (AudioService.muted ? " (muted)" : "")
    HoverHandler { id: hover }
}
