import QtQuick
import Quickshell.Io
import qs.theme
import qs.services
import "../" as Local

Local.ModulePill {
    id: root

    Row {
        spacing: 4
        Text {
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 14
            font.bold: true
            color: Colours.networkColor
            text: NetworkService.iconText
        }
        Text {
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 14
            font.bold: true
            color: Colours.networkColor
            text: NetworkService.ssid
        }
    }

    Process {
        id: nmtuiProc
        command: ["kitty", "-e", "nmtui"]
        running: false
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            try {
                nmtuiProc.startDetached()
            } catch (e) {
                console.warn("NetworkWidget: failed to launch nmtui:", e)
            }
        }
    }

}
