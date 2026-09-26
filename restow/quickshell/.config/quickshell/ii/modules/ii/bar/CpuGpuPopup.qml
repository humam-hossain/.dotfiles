pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell

StyledPopup {
    id: root

    // Reactive fast-polling lifecycle boost (1000ms active / 3000ms idle)
    // Guarantees zero reference count leaks (Pitfall 5)
    onActiveChanged: {
        if (active) {
            HardwareTelemetry.fastPollingRequests++;
        } else {
            HardwareTelemetry.fastPollingRequests--;
        }
    }

    Component.onDestruction: {
        if (active) {
            HardwareTelemetry.fastPollingRequests--;
        }
    }

    // Alert threshold color mappings (D-10, D-11)
    readonly property color cpuLoadColor: (HardwareTelemetry.overallCpuLoad || 0.0) >= 0.90 ? Appearance.colors.colError : ((HardwareTelemetry.overallCpuLoad || 0.0) >= 0.70 ? Appearance.colors.colTertiary : Appearance.colors.colPrimary)
    readonly property color gpuLoadColor: (HardwareTelemetry.gpuLoad || 0.0) >= 0.90 ? Appearance.colors.colError : ((HardwareTelemetry.gpuLoad || 0.0) >= 0.70 ? Appearance.colors.colTertiary : Appearance.colors.colPrimary)

    // Reusable progress meter row sub-component
    component MetricProgressRow: ColumnLayout {
        id: meterRow
        property string title: ""
        property string subtitle: ""
        property real value: 0.0
        property color barColor: Appearance.colors.colPrimary
        spacing: 2
        Layout.fillWidth: true

        RowLayout {
            Layout.fillWidth: true
            StyledText {
                text: meterRow.title
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colOnSurfaceVariant
            }
            Item { Layout.fillWidth: true }
            StyledText {
                text: meterRow.subtitle
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
            }
            StyledText {
                text: `${Math.round(meterRow.value * 100)}%`
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.weight: Font.DemiBold
                color: meterRow.barColor
            }
        }

        StyledProgressBar {
            Layout.fillWidth: true
            value: Math.max(0.0, Math.min(1.0, meterRow.value))
            highlightColor: meterRow.barColor
        }
    }

    RowLayout {
        spacing: 16

        // =====================================================================
        // Left Column: CPU Section (CPUGPU-02, D-13, D-14)
        // =====================================================================
        ColumnLayout {
            Layout.preferredWidth: 230
            spacing: 8

            StyledPopupHeaderRow {
                icon: "planner_review"
                label: "CPU (i5-13500)"
            }

            // Overall CPU Load
            MetricProgressRow {
                title: "Overall Load"
                value: HardwareTelemetry.overallCpuLoad || 0.0
                barColor: root.cpuLoadColor
            }

            // Segregated P-Cores (12T) (CPUs 0-11)
            MetricProgressRow {
                title: "P-Cores (12T)"
                subtitle: `${Math.round(HardwareTelemetry.pCoreFrequencyMhz || 0)} MHz`
                value: HardwareTelemetry.pCoreLoad || 0.0
                barColor: root.cpuLoadColor
            }

            // Segregated E-Cores (8T) (CPUs 12-19)
            MetricProgressRow {
                title: "E-Cores (8T)"
                subtitle: `${Math.round(HardwareTelemetry.eCoreFrequencyMhz || 0)} MHz`
                value: HardwareTelemetry.eCoreLoad || 0.0
                barColor: root.cpuLoadColor
            }

            // Telemetry Value Rows
            StyledPopupValueRow {
                Layout.fillWidth: true
                icon: "device_thermostat"
                label: "Package Temp:"
                value: `${HardwareTelemetry.packageTemp || 0}°C`
            }

            StyledPopupValueRow {
                Layout.fillWidth: true
                icon: "tune"
                label: "Governor:"
                value: HardwareTelemetry.scalingGovernor || ""
            }

            // Unprivileged Power Fallback (D-05 Platypus mitigation)
            StyledPopupValueRow {
                Layout.fillWidth: true
                icon: "bolt"
                label: "Power Draw:"
                value: "N/A (unprivileged)"
            }
        }

        // Vertical Separator
        Rectangle {
            Layout.fillHeight: true
            implicitWidth: 1
            color: Appearance.colors.colLayer0Border
        }

        // =====================================================================
        // Right Column: GPU Top + Motherboard Bottom (CPUGPU-03, D-13, D-15, D-16)
        // =====================================================================
        ColumnLayout {
            Layout.preferredWidth: 230
            spacing: 8

            // --- GPU Section (Top) ---
            StyledPopupHeaderRow {
                icon: "speed"
                label: "GPU (Intel UHD 770)"
            }

            MetricProgressRow {
                title: "iGPU Load"
                value: HardwareTelemetry.gpuLoad || 0.0
                barColor: root.gpuLoadColor
            }

            StyledPopupValueRow {
                Layout.fillWidth: true
                icon: "speed"
                label: "Render Clock:"
                value: `${Math.round(HardwareTelemetry.gpuClockMhz || 0)} MHz`
            }

            StyledPopupValueRow {
                Layout.fillWidth: true
                icon: "warning"
                label: "Thermal Throttle:"
                value: HardwareTelemetry.gpuThrottled ? "Throttling" : "Normal"
            }

            // Horizontal Separator
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Appearance.colors.colLayer0Border
            }

            // --- Motherboard & Platform Telemetry (Bottom) ---
            StyledPopupHeaderRow {
                icon: "developer_board"
                label: "Platform (B760)"
            }

            StyledPopupValueRow {
                Layout.fillWidth: true
                icon: "device_thermostat"
                label: "VRM Temp:"
                value: `${HardwareTelemetry.vrmTemp || 0}°C`
            }

            StyledPopupValueRow {
                Layout.fillWidth: true
                icon: "energy_program_saving"
                label: "EPP:"
                value: HardwareTelemetry.energyPerformancePreference || ""
            }
        }
    }
}
