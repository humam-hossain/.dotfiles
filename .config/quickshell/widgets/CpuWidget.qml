import QtQuick
import qs.theme
import qs.services
import "../" as Local

Local.ModulePill {
    id: root

    property string displayColor: Colours.cpuColor

    Text {
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 14
        font.bold: true
        color: root.displayColor
        text: " " + CpuService.cpuPercentFormatted
    }

    Connections {
        target: CpuService
        function onCpuPercentChanged() {
            const pct = CpuService.cpuPercent
            if (pct >= 90)      root.displayColor = Colours.critical
            else if (pct >= 50) root.displayColor = Colours.warning
            else                root.displayColor = Colours.cpuColor
        }
    }
}
