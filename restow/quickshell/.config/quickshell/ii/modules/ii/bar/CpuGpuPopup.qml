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

    // Alert threshold color mappings (D-10, D-11) with dots-hyprland amber warning color fallback
    readonly property color warningColor: Appearance.colors.colWarning !== undefined ? Appearance.colors.colWarning : "#FFA000"

    function getLoadColor(val) {
        if (val >= 0.90) return Appearance.colors.colError;
        if (val >= 0.70) return root.warningColor;
        return Appearance.colors.colPrimary;
    }

    function getTempColor(temp) {
        if (temp >= 80) return Appearance.colors.colError;
        if (temp >= 65) return root.warningColor;
        return Appearance.colors.colOnLayer1;
    }

    readonly property color cpuLoadColor: getLoadColor(HardwareTelemetry.overallCpuLoad || 0.0)
    readonly property color gpuLoadColor: getLoadColor(HardwareTelemetry.gpuLoad || 0.0)

    property real criticalPulseOpacity: 1.0

    // Reusable progress meter row sub-component
    component MetricProgressRow: ColumnLayout {
        id: meterRow
        property string title: ""
        property string mhzText: ""
        property string subtitle: mhzText
        property real value: 0.0
        property string tempText: ""
        property color barColor: Appearance.colors.colPrimary
        property color tempColor: Appearance.colors.colOnLayer1
        property bool isCritical: false
        spacing: 2
        Layout.fillWidth: true

        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            StyledText {
                text: meterRow.title
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colOnSurfaceVariant
            }
            Item { Layout.fillWidth: true }
            StyledText {
                visible: (meterRow.mhzText.length > 0 || meterRow.subtitle.length > 0)
                text: meterRow.mhzText.length > 0 ? meterRow.mhzText : meterRow.subtitle
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
            }
            StyledText {
                text: `${Math.round(meterRow.value * 100)}%`
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.weight: Font.DemiBold
                color: meterRow.barColor
                opacity: meterRow.isCritical ? root.criticalPulseOpacity : 1.0
            }
            StyledText {
                visible: meterRow.tempText.length > 0
                text: meterRow.tempText
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.weight: Font.DemiBold
                color: meterRow.tempColor
                opacity: meterRow.isCritical ? root.criticalPulseOpacity : 1.0
            }
        }

        StyledProgressBar {
            Layout.fillWidth: true
            value: Math.max(0.0, Math.min(1.0, meterRow.value))
            highlightColor: meterRow.barColor
            opacity: meterRow.isCritical ? root.criticalPulseOpacity : 1.0
        }
    }

    // Reusable per-thread mini meter row
    component ThreadMeter: RowLayout {
        id: tMeter
        property int threadIdx: 0
        property real load: (HardwareTelemetry.perThreadLoads && HardwareTelemetry.perThreadLoads[threadIdx]) || 0.0
        property real freq: (HardwareTelemetry.threadFrequencies && HardwareTelemetry.threadFrequencies[threadIdx]) || 0.0
        readonly property int coreTemp: {
            if (tMeter.threadIdx < 12) {
                const cIdx = Math.floor(tMeter.threadIdx / 2);
                return (HardwareTelemetry.pCoreTemps && HardwareTelemetry.pCoreTemps[cIdx] > 0) ? HardwareTelemetry.pCoreTemps[cIdx] : (HardwareTelemetry.pCoreTempAvg || HardwareTelemetry.packageTemp || 0);
            } else {
                const cIdx = tMeter.threadIdx - 12;
                return (HardwareTelemetry.eCoreTemps && HardwareTelemetry.eCoreTemps[cIdx] > 0) ? HardwareTelemetry.eCoreTemps[cIdx] : (HardwareTelemetry.eCoreTempAvg || HardwareTelemetry.packageTemp || 0);
            }
        }
        readonly property color tLoadColor: root.getLoadColor(tMeter.load)
        readonly property color tTempColor: root.getTempColor(tMeter.coreTemp)
        readonly property bool isCritical: tMeter.load >= 0.90 || tMeter.coreTemp >= 80

        spacing: 4
        Layout.fillWidth: true

        StyledText {
            text: `C${tMeter.threadIdx}`
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colOnSurfaceVariant
            Layout.preferredWidth: 26
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 4

            Rectangle {
                anchors.fill: parent
                radius: 2
                color: Appearance.colors.colLayer2
            }

            Rectangle {
                anchors.left: parent.left
                width: parent.width * Math.max(0.0, Math.min(1.0, tMeter.load))
                height: parent.height
                radius: 2
                color: tMeter.tLoadColor
                opacity: tMeter.isCritical ? root.criticalPulseOpacity : 1.0
            }
        }

        StyledText {
            text: `${Math.round(tMeter.load * 100)}%`
            font.pixelSize: Appearance.font.pixelSize.smaller
            font.weight: Font.DemiBold
            color: tMeter.tLoadColor
            opacity: tMeter.isCritical ? root.criticalPulseOpacity : 1.0
            Layout.preferredWidth: 32
            horizontalAlignment: Text.AlignRight
        }

        StyledText {
            text: `${Math.round(tMeter.freq)} MHz`
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
            Layout.preferredWidth: 54
            horizontalAlignment: Text.AlignRight
        }

        StyledText {
            text: `${tMeter.coreTemp}°C`
            font.pixelSize: Appearance.font.pixelSize.smaller
            font.weight: Font.Medium
            color: tMeter.tTempColor
            opacity: tMeter.isCritical ? root.criticalPulseOpacity : 1.0
            Layout.preferredWidth: 36
            horizontalAlignment: Text.AlignRight
        }
    }

    RowLayout {
        id: popupContent
        anchors.centerIn: parent
        spacing: 16

        SequentialAnimation {
            id: popupCriticalPulse
            running: (HardwareTelemetry.overallCpuLoad || 0.0) >= 0.90 || (HardwareTelemetry.packageTemp || 0) >= 80 || (HardwareTelemetry.gpuLoad || 0.0) >= 0.90
            loops: Animation.Infinite
            onRunningChanged: {
                if (!running) root.criticalPulseOpacity = 1.0;
            }
            NumberAnimation {
                target: root
                property: "criticalPulseOpacity"
                to: 0.4
                duration: 600
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                target: root
                property: "criticalPulseOpacity"
                to: 1.0
                duration: 600
                easing.type: Easing.InOutSine
            }
        }

        // =====================================================================
        // Left Column: CPU Section (CPUGPU-02, D-13, D-14)
        // =====================================================================
        ColumnLayout {
            Layout.preferredWidth: 320
            spacing: 8

            StyledPopupHeaderRow {
                icon: "planner_review"
                label: "CPU (i5-13500)"
            }

            // Overall CPU Load
            MetricProgressRow {
                title: "Overall Load"
                mhzText: `${Math.round((HardwareTelemetry.pCoreFrequencyMhz || 0) * 0.6 + (HardwareTelemetry.eCoreFrequencyMhz || 0) * 0.4)} MHz`
                value: HardwareTelemetry.overallCpuLoad || 0.0
                tempText: `${HardwareTelemetry.packageTemp || 0}°C`
                barColor: root.cpuLoadColor
                tempColor: root.getTempColor(HardwareTelemetry.packageTemp || 0)
                isCritical: (HardwareTelemetry.overallCpuLoad || 0.0) >= 0.90 || (HardwareTelemetry.packageTemp || 0) >= 80
            }

            // Segregated P-Cores (12T) (CPUs 0-11)
            MetricProgressRow {
                title: "P-Cores (12T)"
                mhzText: `${Math.round(HardwareTelemetry.pCoreFrequencyMhz || 0)} MHz`
                value: HardwareTelemetry.pCoreLoad || 0.0
                tempText: `${HardwareTelemetry.pCoreTempAvg || 0}°C`
                barColor: root.getLoadColor(HardwareTelemetry.pCoreLoad || 0.0)
                tempColor: root.getTempColor(HardwareTelemetry.pCoreTempAvg || 0)
                isCritical: (HardwareTelemetry.pCoreLoad || 0.0) >= 0.90 || (HardwareTelemetry.pCoreTempAvg || 0) >= 80
            }

            // Individual P-Core Threads (C0 - C11)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Repeater {
                    model: 12
                    delegate: ThreadMeter {
                        required property int index
                        threadIdx: index
                    }
                }
            }

            // Segregated E-Cores (8T) (CPUs 12-19)
            MetricProgressRow {
                title: "E-Cores (8T)"
                mhzText: `${Math.round(HardwareTelemetry.eCoreFrequencyMhz || 0)} MHz`
                value: HardwareTelemetry.eCoreLoad || 0.0
                tempText: `${HardwareTelemetry.eCoreTempAvg || 0}°C`
                barColor: root.getLoadColor(HardwareTelemetry.eCoreLoad || 0.0)
                tempColor: root.getTempColor(HardwareTelemetry.eCoreTempAvg || 0)
                isCritical: (HardwareTelemetry.eCoreLoad || 0.0) >= 0.90 || (HardwareTelemetry.eCoreTempAvg || 0) >= 80
            }

            // Individual E-Core Threads (C12 - C19)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Repeater {
                    model: 8
                    delegate: ThreadMeter {
                        required property int index
                        threadIdx: index + 12
                    }
                }
            }

            // Telemetry Value Rows
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
            Layout.preferredWidth: 320
            spacing: 8

            // --- GPU Section (Top) ---
            StyledPopupHeaderRow {
                icon: "sports_esports"
                label: "GPU (Intel UHD 770)"
            }

            MetricProgressRow {
                title: "iGPU Load"
                value: HardwareTelemetry.gpuLoad || 0.0
                barColor: root.gpuLoadColor
                isCritical: (HardwareTelemetry.gpuLoad || 0.0) >= 0.90
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
                icon: "thermostat"
                label: "Platform Avg Temp:"
                value: `${HardwareTelemetry.platformTempAvg || 0}°C`
            }

            // 6 Gigabyte WMI platform sensors breakdown
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                StyledText {
                    text: "Platform Sensors (1–6):"
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnSurfaceVariant
                }

                component PlatformSensorRow: RowLayout {
                    id: psRow
                    property string label: ""
                    property int temp: 0
                    spacing: 4
                    Layout.fillWidth: true

                    StyledText {
                        text: psRow.label
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colOnSurfaceVariant
                    }

                    Item { Layout.fillWidth: true }

                    StyledText {
                        text: `${psRow.temp}°C`
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        font.weight: Font.Medium
                        color: root.getTempColor(psRow.temp)
                        opacity: psRow.temp >= 80 ? root.criticalPulseOpacity : 1.0
                    }
                }

                PlatformSensorRow {
                    label: "VRM / Sensor 1:"
                    temp: HardwareTelemetry.platformTemp1 || HardwareTelemetry.vrmTemp || 0
                }
                PlatformSensorRow {
                    label: "Sensor 2:"
                    temp: HardwareTelemetry.platformTemp2 || 0
                }
                PlatformSensorRow {
                    label: "Sensor 3:"
                    temp: HardwareTelemetry.platformTemp3 || 0
                }
                PlatformSensorRow {
                    label: "Sensor 4:"
                    temp: HardwareTelemetry.platformTemp4 || 0
                }
                PlatformSensorRow {
                    label: "Sensor 5:"
                    temp: HardwareTelemetry.platformTemp5 || 0
                }
                PlatformSensorRow {
                    label: "Sensor 6:"
                    temp: HardwareTelemetry.platformTemp6 || 0
                }
            }
        }
    }
}
