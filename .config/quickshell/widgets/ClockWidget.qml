import QtQuick
import qs.theme
import qs.services
import "../" as Local

Local.ModulePill {
    id: root

    Text {
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 14
        font.bold: true
        color: Colours.clockColor
        text: ClockService.text
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            var p = root.parent
            while (p && typeof p.openPopup === 'undefined') {
                p = p.parent
            }
            if (p) {
                p.openPopup(p.calendarPopup)
            }
        }
    }
}
