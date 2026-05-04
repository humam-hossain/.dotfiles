import QtQuick
import Quickshell.Hyprland
import qs.theme
import qs.services
import "../" as Local

Local.ModulePill {
    id: root

    Row {
        spacing: 8

        Repeater {
            model: HyprWorkspaces.workspaces

            delegate: Item {
                id: cell
                required property var modelData

                width: glyph.implicitWidth
                height: glyph.implicitHeight

                Text {
                    id: glyph
                    anchors.centerIn: parent
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    font.bold: true
                    text: cell.modelData.active ? "" : ""
                    color: HyprWorkspaces.isUrgent(cell.modelData.id) ? Colours.critical
                         : cell.modelData.active                       ? Colours.accent
                         :                                              Colours.textColor
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: cell.modelData.activate()
                }
            }
        }
    }

    // Wheel cycling uses static dispatch strings only.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: wheel => {
            if (wheel.angleDelta.y < 0) Hyprland.dispatch("workspace e+1")
            else                        Hyprland.dispatch("workspace e-1")
        }
    }
}
