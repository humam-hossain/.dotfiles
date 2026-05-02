import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.theme

PanelWindow {
    id: root
    required property var modelData
    screen: modelData

    color: "transparent"          // D-04
    exclusiveZone: height          // D-12 dynamic, content-driven

    anchors {
        top:   true                // D-11 flush top
        left:  true
        right: true
    }

    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None  // P-16 mandatory

    // D-04 / D-05: black background strip with drop shadow
    Rectangle {
        id: bgRect
        anchors.fill: parent
        color: Colours.barBg       // #000000 D-02

        layer.enabled: true
        layer.effect: DropShadow {
            verticalOffset:   4    // D-05 mirrors Waybar box-shadow: 0 4px 6px rgba(0,0,0,0.3)
            horizontalOffset: 0
            radius:           6
            color:            Qt.rgba(0, 0, 0, 0.3)
        }
    }

    // D-03 three-section RowLayout (RowLayout chosen over Row per Quickshell docs — Layout.fillWidth requires RowLayout)
    RowLayout {
        anchors {
            left:    parent.left
            right:   parent.right
            top:     parent.top
            bottom:  parent.bottom
            margins: 4
        }
        spacing: 0

        BarGroup {
            ModulePill {
                Text {
                    text:           "Left"        // D-01 placeholder
                    font.family:    "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    font.bold:      true
                    color:          Colours.textColor
                }
            }
        }

        Item { Layout.fillWidth: true }   // flexible spacer

        BarGroup {
            ModulePill {
                Text {
                    text:           "Center"      // D-01 placeholder
                    font.family:    "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    font.bold:      true
                    color:          Colours.textColor
                }
            }
        }

        Item { Layout.fillWidth: true }   // flexible spacer

        BarGroup {
            ModulePill {
                Text {
                    text:           "Right"       // D-01 placeholder
                    font.family:    "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    font.bold:      true
                    color:          Colours.textColor
                }
            }
        }
    }
}
