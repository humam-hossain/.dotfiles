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
        color: Colours.backlightColor
        text: " " + BacklightService.formatted
    }

    MouseArea {
        anchors.fill: parent
        onWheel: wheel => {
            const step = 5 * Math.sign(wheel.angleDelta.y)
            BacklightService.adjustBrightness(step)
        }
    }
}
