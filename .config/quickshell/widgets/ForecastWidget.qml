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
        color: Colours.textColor
        text: ForecastService.text
    }

    ToolTip.visible: hover.hovered
    ToolTip.text: ForecastService.tooltip
    HoverHandler { id: hover }
}
