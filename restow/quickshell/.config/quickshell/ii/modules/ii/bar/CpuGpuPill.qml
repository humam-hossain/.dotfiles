pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell

BarGroup {
    id: root

    property real useShortenedForm: 0

    // Public alias for popup anchoring (D-17)
    readonly property alias hoverArea: inertMouseArea

    // Two-tier alert state thresholds (D-09, D-10)
    // Multi-tier temperature color thresholds (warning >= 65°C, critical >= 80°C)
    readonly property bool tempCritical: (HardwareTelemetry.packageTemp || 0) >= 80
    readonly property bool tempWarning: !tempCritical && (HardwareTelemetry.packageTemp || 0) >= 65

    readonly property bool cpuCritical: (HardwareTelemetry.overallCpuLoad || 0.0) >= 0.90 || tempCritical
    readonly property bool cpuWarning: !cpuCritical && ((HardwareTelemetry.overallCpuLoad || 0.0) >= 0.70 || tempWarning)

    readonly property bool gpuCritical: (HardwareTelemetry.gpuLoad || 0.0) >= 0.90
    readonly property bool gpuWarning: !gpuCritical && (HardwareTelemetry.gpuLoad || 0.0) >= 0.70

    readonly property real quantizedCpuLoad: Math.round((HardwareTelemetry.overallCpuLoad || 0.0) * 100) / 100
    readonly property real quantizedGpuLoad: Math.round((HardwareTelemetry.gpuLoad || 0.0) * 100) / 100

    // Dynamic Material You token resolution with dots-hyprland amber warning color fallback
    readonly property color warningColor: Appearance.colors.colWarning !== undefined ? Appearance.colors.colWarning : "#FFA000"
    readonly property color cpuColor: cpuCritical ? Appearance.colors.colError : (cpuWarning ? warningColor : Appearance.colors.colOnLayer1)
    readonly property color tempColor: tempCritical ? Appearance.colors.colError : (tempWarning ? warningColor : Appearance.colors.colOnLayer1)
    readonly property color gpuColor: gpuCritical ? Appearance.colors.colError : (gpuWarning ? warningColor : Appearance.colors.colOnLayer1)

    // Re-parented inert MouseArea (D-17, Pitfall 1)
    MouseArea {
        id: inertMouseArea
        parent: root
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        cursorShape: Qt.ArrowCursor
        hoverEnabled: true
        onPressed: event => event.accepted = true
        onClicked: event => event.accepted = true

        CpuGpuPopup {
            hoverTarget: root.hoverArea
        }
    }

    // --- CPU Section (Circular progress indicator + MaterialSymbol) ---
    ClippedFilledCircularProgress {
        id: cpuCircProg
        Layout.alignment: Qt.AlignVCenter
        lineWidth: Appearance.rounding.unsharpen
        value: Math.max(0.0, Math.min(1.0, root.quantizedCpuLoad))
        implicitSize: 20
        colPrimary: root.cpuColor
        accountForLightBleeding: !root.cpuCritical && !root.cpuWarning
        enableAnimation: false

        Item {
            anchors.centerIn: parent
            width: cpuCircProg.implicitSize
            height: cpuCircProg.implicitSize

            MaterialSymbol {
                id: cpuIcon
                anchors.centerIn: parent
                text: "planner_review"
                iconSize: Appearance.font.pixelSize.normal
                color: root.cpuColor

                Behavior on color {
                    ColorAnimation {
                        duration: 200
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.animationCurves.expressiveEffects
                    }
                }

                // Breathing pulse animation on critical red (D-12)
                SequentialAnimation {
                    id: cpuPulseAnimation
                    running: root.cpuCritical
                    loops: Animation.Infinite
                    onRunningChanged: { if (!running) cpuIcon.opacity = 1.0;
                        if (!running) {
                            cpuCircProg.opacity = 1.0;
                            cpuText.opacity = 1.0;
                            tempText.opacity = 1.0;
                        }
                    }
                    ParallelAnimation {
                        NumberAnimation { target: cpuIcon; property: "opacity"; to: 0.4; duration: 600; easing.type: Easing.InOutSine }
                        NumberAnimation { target: cpuCircProg; property: "opacity"; to: 0.4; duration: 600; easing.type: Easing.InOutSine }
                        NumberAnimation { target: cpuText; property: "opacity"; to: 0.4; duration: 600; easing.type: Easing.InOutSine }
                        NumberAnimation { target: tempText; property: "opacity"; to: 0.4; duration: 600; easing.type: Easing.InOutSine }
                    }
                    ParallelAnimation {
                        NumberAnimation { target: cpuIcon; property: "opacity"; to: 1.0; duration: 600; easing.type: Easing.InOutSine }
                        NumberAnimation { target: cpuCircProg; property: "opacity"; to: 1.0; duration: 600; easing.type: Easing.InOutSine }
                        NumberAnimation { target: cpuText; property: "opacity"; to: 1.0; duration: 600; easing.type: Easing.InOutSine }
                        NumberAnimation { target: tempText; property: "opacity"; to: 1.0; duration: 600; easing.type: Easing.InOutSine }
                    }
                }
            }
        }
    }

    StyledText {
        id: cpuText
        text: `${Math.round((HardwareTelemetry.overallCpuLoad || 0.0) * 100)}%`
        font.pixelSize: Appearance.font.pixelSize.small
        color: root.cpuColor

        Behavior on color {
            ColorAnimation {
                duration: 200
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.expressiveEffects
            }
        }
    }

    // Single thermal metric: CPU Package Temp (D-01, D-06)
    // Drops when useShortenedForm > 0 (D-03)
    StyledText {
        id: tempText
        visible: root.useShortenedForm === 0
        text: `${HardwareTelemetry.packageTemp || 0}°C`
        font.pixelSize: Appearance.font.pixelSize.small
        color: root.tempColor

        Behavior on color {
            ColorAnimation {
                duration: 200
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.expressiveEffects
            }
        }
    }

    // --- GPU Section (Circular progress indicator + sports_esports icon) ---
    ClippedFilledCircularProgress {
        id: gpuCircProg
        Layout.alignment: Qt.AlignVCenter
        Layout.leftMargin: root.vertical ? 0 : 6 // Visual cluster separation per D-02
        lineWidth: Appearance.rounding.unsharpen
        value: Math.max(0.0, Math.min(1.0, root.quantizedGpuLoad))
        implicitSize: 20
        colPrimary: root.gpuColor
        accountForLightBleeding: !root.gpuCritical && !root.gpuWarning
        enableAnimation: false

        Item {
            anchors.centerIn: parent
            width: gpuCircProg.implicitSize
            height: gpuCircProg.implicitSize

            MaterialSymbol {
                id: gpuIcon
                anchors.centerIn: parent
                text: "sports_esports"
                iconSize: Appearance.font.pixelSize.normal
                color: root.gpuColor

                Behavior on color {
                    ColorAnimation {
                        duration: 200
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.animationCurves.expressiveEffects
                    }
                }

                // Breathing pulse animation on critical red (D-12)
                SequentialAnimation {
                    id: gpuPulseAnimation
                    running: root.gpuCritical
                    loops: Animation.Infinite
                    onRunningChanged: { if (!running) gpuIcon.opacity = 1.0;
                        if (!running) {
                            gpuCircProg.opacity = 1.0;
                            gpuText.opacity = 1.0;
                        }
                    }
                    ParallelAnimation {
                        NumberAnimation { target: gpuIcon; property: "opacity"; to: 0.4; duration: 600; easing.type: Easing.InOutSine }
                        NumberAnimation { target: gpuCircProg; property: "opacity"; to: 0.4; duration: 600; easing.type: Easing.InOutSine }
                        NumberAnimation { target: gpuText; property: "opacity"; to: 0.4; duration: 600; easing.type: Easing.InOutSine }
                    }
                    ParallelAnimation {
                        NumberAnimation { target: gpuIcon; property: "opacity"; to: 1.0; duration: 600; easing.type: Easing.InOutSine }
                        NumberAnimation { target: gpuCircProg; property: "opacity"; to: 1.0; duration: 600; easing.type: Easing.InOutSine }
                        NumberAnimation { target: gpuText; property: "opacity"; to: 1.0; duration: 600; easing.type: Easing.InOutSine }
                    }
                }
            }
        }
    }

    StyledText {
        id: gpuText
        text: `${Math.round((HardwareTelemetry.gpuLoad || 0.0) * 100)}%`
        font.pixelSize: Appearance.font.pixelSize.small
        color: root.gpuColor

        Behavior on color {
            ColorAnimation {
                duration: 200
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.expressiveEffects
            }
        }
    }
}
