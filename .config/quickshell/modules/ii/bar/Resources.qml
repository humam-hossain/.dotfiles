import qs.modules.common
import qs.services
import QtQuick
import QtQuick.Layouts

// Display-only strip (D-09, D-25): no hover popup, no click actions.
Item {
    id: root
    property bool borderless: Config.options.bar.borderless
    // Kept for BarContent assignment API; strip always shows CPU/RAM/Disk (D-05).
    property bool alwaysShowAllResources: false
    implicitWidth: rowLayout.implicitWidth + rowLayout.anchors.leftMargin + rowLayout.anchors.rightMargin
    implicitHeight: Appearance.sizes.barHeight

    RowLayout {
        id: rowLayout

        spacing: 0
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 4

        // Order L→R: CPU → RAM → Disk (D-06, D-12). Always shown (D-05).
        Resource {
            iconName: "planner_review"
            percentage: ResourceUsage.cpuUsage
            shown: true
            warningThreshold: Config.options.bar.resources.cpuWarningThreshold
            errorThreshold: Config.options.bar.resources.cpuErrorThreshold
            // labelText empty → Resource default N% (D-02)
        }

        Resource {
            iconName: "memory"
            percentage: ResourceUsage.memoryUsedPercentage
            shown: true
            Layout.leftMargin: 6
            warningThreshold: Config.options.bar.resources.memoryWarningThreshold
            errorThreshold: Config.options.bar.resources.memoryErrorThreshold
            labelText: ResourceUsage.memoryUsedTotalString
        }

        Resource {
            iconName: "hard_drive"
            percentage: ResourceUsage.diskUsedPercentage
            shown: true
            Layout.leftMargin: 6
            warningThreshold: Config.options.bar.resources.diskWarningThreshold
            errorThreshold: Config.options.bar.resources.diskErrorThreshold
            labelText: ResourceUsage.diskFreeTotalString
        }
    }
}
