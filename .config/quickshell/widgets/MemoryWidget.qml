import QtQuick
import QtQuick.Controls
import qs.theme
import qs.services
import "../" as Local

Local.ModulePill {
    id: root

    Text {
        id: memText
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 14
        font.bold: true
        color: {
            const pct = MemoryService.percent
            if (pct >= 90)      return Colours.critical
            else if (pct >= 50) return Colours.warning
            else                return Colours.memoryColor
        }
        text: " " + MemoryService.text
    }

    ToolTip.visible: hover.hovered
    ToolTip.text: MemoryService.tooltip
    HoverHandler { id: hover }
}
