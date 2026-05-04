import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import Quickshell.Hyprland
import qs.theme
import "../" as Local

Local.ModulePill {
    id: root
    visible: SystemTray.items.values.length > 0
    readonly property var hostWindow: Window.window

    Row {
        spacing: 8

        Repeater {
            model: SystemTray.items

            delegate: Item {
                id: trayItem
                required property var modelData
                width: 21
                height: 21

                IconImage {
                    id: iconImg
                    anchors.fill: parent
                    source: trayItem.modelData.icon
                    asynchronous: true
                    visible: status !== Image.Error
                }

                Text {
                    anchors.centerIn: parent
                    visible: iconImg.status === Image.Error
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    font.bold: true
                    color: Colours.textColor
                    text: "\uf128"
                }

                Rectangle {
                    anchors.fill: parent
                    visible: trayItem.modelData.status === Status.NeedsAttention
                    color: Colours.critical
                    opacity: 0.35
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: mouse => {
                        if (mouse.button === Qt.LeftButton) {
                            trayItem.modelData.activate(mouse.x, mouse.y)
                        } else if (mouse.button === Qt.RightButton) {
                            menuAnchor.anchor.item = trayItem
                            menuAnchor.anchor.rect = Qt.rect(0, trayItem.height, trayItem.width, 0)
                            menuAnchor.menu = trayItem.modelData.menu
                            menuAnchor.open()
                        }
                    }
                }
            }
        }
    }

    QsMenuAnchor {
        id: menuAnchor
    }

    HyprlandFocusGrab {
        windows: menuAnchor.visible ? [root.hostWindow] : []
        active: menuAnchor.visible
        onCleared: menuAnchor.close()
    }
}
