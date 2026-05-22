import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.theme
import qs.services

PopupWindow {
    id: root

    property bool open: false

    visible: false

    width: 300
    height: 200

    anchor.rect.x: parentWindow.width / 2 - implicitWidth / 2
    anchor.rect.y: parentWindow.height + 12

    Rectangle {
        anchors.fill: parent
        color: Colours.moduleBg
        radius: 8

        Text {
            anchors.centerIn: parent
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 14
            color: Colours.textColor
            text: "Network Panel"
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
