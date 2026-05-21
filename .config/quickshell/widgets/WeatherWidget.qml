import QtQuick
import QtQuick.Controls
import qs.theme
import qs.services
import "../" as Local

Local.ModulePill {
    id: root

    Text {
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 14
        font.bold: true
        color: Colours.textColor
        text: WeatherService.text
    }

    ToolTip.visible: hover.hovered
    ToolTip.text: WeatherService.tooltip
    HoverHandler { id: hover }
}
