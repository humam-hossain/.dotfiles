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
            color: Colours.notifColor
            text: "󰂚"
        }
        Text {
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 14
            font.bold: true
            color: Colours.notifColor
            visible: NotificationService.count > 0
            text: NotificationService.formatted
        }
    }

    Process {
        id: toggleProc
        command: ["swaync-client", "-t"]
        running: false
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: toggleProc.startDetached()
    }
}
