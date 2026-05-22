import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.theme
import qs.services

PopupWindow {
    id: root

    property int volumePercent: AudioService.volumePercent
    onVolumePercentChanged: show()

    visible: false

    width:  250
    height: 16

    // Position below bar center
    anchor.rect.x: parentWindow.width / 2 - implicitWidth / 2
    anchor.rect.y: parentWindow.height + 12

    Rectangle {
        anchors.fill: parent
        color: Colours.moduleBg
        radius: 4
        clip: true

        Rectangle {
            id: barFill
            anchors {
                left:   parent.left
                top:    parent.top
                bottom: parent.bottom
            }
            width: parent.width * AudioService.volume
            radius: 4
            color: AudioService.muted ? Colours.critical : "#ffffff"
            opacity: 0.85
        }

        Text {
            anchors.centerIn: parent
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 7
            font.bold: true
            color: "#1e1e2e"
            text: AudioService.volumePercent + "%"
            visible: AudioService.volumePercent > 0
        }
    }

    Timer {
        id: hideTimer
        interval: 1500
        running: false
        repeat: false
        onTriggered: root.close()
    }

    function show() {
        hideTimer.stop()
        root.visible = true
        hideTimer.start()
    }

    function close() {
        root.visible = false
    }
}
