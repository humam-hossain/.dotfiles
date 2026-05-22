import QtQuick
import qs.theme
import qs.services
import "../" as Local

Local.ModulePill {
    id: root

    signal popupRequested()

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
        onClicked: root.popupRequested()
    }
}
