import qs.modules.common
import qs.services
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root
    property bool borderless: Config.options.bar.borderless
    property bool alwaysShowAllResources: false
    implicitWidth: rowLayout.implicitWidth + rowLayout.anchors.leftMargin + rowLayout.anchors.rightMargin
    implicitHeight: Appearance.sizes.barHeight
    hoverEnabled: !Config.options.bar.tooltips.clickToShow

    RowLayout {
        id: rowLayout
        spacing: 0
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 4

        // RAM: Definite gigabytes used / total + percentage badge (D-01, COMP-01)
        Resource {
            iconName: "memory"
            percentage: ResourceUsage.memoryUsedPercentage
            customText: `${(ResourceUsage.memoryUsed / (1024 * 1024)).toFixed(1)}/${(ResourceUsage.memoryTotal / (1024 * 1024)).toFixed(1)} GB [${Math.round(ResourceUsage.memoryUsedPercentage * 100)}%]`
            warningThreshold: 70
            criticalThreshold: 90
        }

        // Swap: Dynamically revealed only when swap is actively in use (> 0%) (D-03, COMP-02)
        Resource {
            iconName: "swap_horiz"
            percentage: ResourceUsage.swapUsedPercentage
            shown: ResourceUsage.swapUsed > 0
            Layout.leftMargin: shown ? 8 : 0
            customText: `${(ResourceUsage.swapUsed / (1024 * 1024)).toFixed(1)}/${(ResourceUsage.swapTotal / (1024 * 1024)).toFixed(1)} GB (${Math.round(ResourceUsage.swapUsedPercentage * 100)}%)`
            warningThreshold: 70
            criticalThreshold: 85
        }

        // CPU: Planner review icon + percentage badge (D-02, COMP-02)
        Resource {
            iconName: "planner_review"
            percentage: ResourceUsage.cpuUsage
            shown: Config.options.bar.resources.alwaysShowCpu || root.alwaysShowAllResources
            Layout.leftMargin: shown ? 8 : 0
            warningThreshold: 60
            criticalThreshold: 90
        }
    }

    ResourcesPopup {
        hoverTarget: root
    }
}
