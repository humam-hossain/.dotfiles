import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.theme
import qs.services

PopupWindow {
    id: root

    property bool open: false

    visible: false

    width: 340
    height: 290

    anchor.rect.x: parentWindow.width / 2 - implicitWidth / 2
    anchor.rect.y: parentWindow.height + 12

    Rectangle {
        anchors.fill: parent
        color: Colours.moduleBg
        radius: 8

        Column {
            anchors.centerIn: parent
            spacing: 8

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 14
                font.bold: true
                color: Colours.textColor
                text: CalendarService.monthHeader
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
                color: Colours.subtextColor
                text: "Calendar"
            }
        }
    }

    function show() {
        root.visible = true
        root.open = true
    }

    function close() {
        root.visible = false
        root.open = false
    }

    onVisibleChanged: {
        if (!visible) root.open = false
    }
}
