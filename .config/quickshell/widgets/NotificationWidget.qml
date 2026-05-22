import QtQuick
import Quickshell.Io
import qs.theme
import qs.services
import "../" as Local

Local.ModulePill {
    id: root

    Item {
        width: bellIcon.implicitWidth + 6
        height: 16
        Text {
            id: bellIcon
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 14
            font.bold: true
            color: Colours.notifColor
            text: "󰂚"
        }
        Rectangle {
            width: 6
            height: 6
            radius: 3
            color: "#f38ba8"
            visible: NotificationService.count > 0
            anchors.top: parent.top
            anchors.right: parent.right
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
