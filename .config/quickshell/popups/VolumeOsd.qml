import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.theme
import qs.services

PopupWindow {
    id: root

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    property int volumePercent: AudioService.volumePercent
    onVolumePercentChanged: show()

    visible: false

    width:  150
    height: 8

    Rectangle {
        anchors.fill: parent
        color: Colours.moduleBg
        radius: 4

        Rectangle {
            id: barFill
            anchors {
                left:   parent.left
                top:    parent.top
                bottom: parent.bottom
            }
            width: parent.width * (AudioService.volume / 1.0)
            radius: 4
            color: AudioService.muted ? Colours.critical : Colours.accent
            opacity: 0.85
        }

        Text {
            anchors.centerIn: parent
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 7
            font.bold: true
            color: Colours.textColor
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
