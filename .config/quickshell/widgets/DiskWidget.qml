import QtQuick
import QtQuick.Controls
import Quickshell.Io
import qs.theme
import qs.services
import "../" as Local

Local.ModulePill {
    id: root

    Text {
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 14
        font.bold: true
        color: {
            const pct = DiskService.percent
            if (pct >= 90)      return Colours.critical
            else if (pct >= 50) return Colours.warning
            else                return Colours.diskColor
        }
        text: " " + DiskService.text
    }

    Process {
        id: nautilusProc
        command: ["nautilus"]
        running: false
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: nautilusProc.startDetached()
    }

    ToolTip.visible: hover.hovered
    ToolTip.text: DiskService.tooltip
    HoverHandler { id: hover }
}
