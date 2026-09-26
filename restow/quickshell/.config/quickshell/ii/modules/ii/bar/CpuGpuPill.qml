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
    // Warning: >= 70% load or >= 75°C; Critical: >= 90% load or >= 85°C
    readonly property bool cpuCritical: (HardwareTelemetry.overallCpuLoad || 0.0) >= 0.90 || (HardwareTelemetry.packageTemp || 0) >= 85
    readonly property bool cpuWarning: !cpuCritical && ((HardwareTelemetry.overallCpuLoad || 0.0) >= 0.70 || (HardwareTelemetry.packageTemp || 0) >= 75)

    readonly property bool tempCritical: (HardwareTelemetry.packageTemp || 0) >= 85
    readonly property bool tempWarning: !tempCritical && (HardwareTelemetry.packageTemp || 0) >= 75

    readonly property bool gpuCritical: (HardwareTelemetry.gpuLoad || 0.0) >= 0.90
    readonly property bool gpuWarning: !gpuCritical && (HardwareTelemetry.gpuLoad || 0.0) >= 0.70

    // Dynamic Material You token resolution (zero hardcoded hex colors per D-11)
    readonly property color cpuColor: cpuCritical ? Appearance.colors.colError : (cpuWarning ? Appearance.colors.colTertiary : Appearance.colors.colOnLayer1)
    readonly property color tempColor: tempCritical ? Appearance.colors.colError : (tempWarning ? Appearance.colors.colTertiary : Appearance.colors.colOnLayer1)
    readonly property color gpuColor: gpuCritical ? Appearance.colors.colError : (gpuWarning ? Appearance.colors.colTertiary : Appearance.colors.colOnLayer1)

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
    }

    // --- CPU Section ---
    MaterialSymbol {
        id: cpuIcon
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
            onRunningChanged: { if (!running) cpuIcon.opacity = 1.0; }
            NumberAnimation {
                target: cpuIcon
                property: "opacity"
                to: 0.6
                duration: 600
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                target: cpuIcon
                property: "opacity"
                to: 1.0
                duration: 600
                easing.type: Easing.InOutSine
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

    // --- GPU Section ---
    MaterialSymbol {
        id: gpuIcon
        text: "speed"
        iconSize: Appearance.font.pixelSize.normal
        color: root.gpuColor
        Layout.leftMargin: root.vertical ? 0 : 6 // Visual cluster separation per D-02

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
            onRunningChanged: { if (!running) gpuIcon.opacity = 1.0; }
            NumberAnimation {
                target: gpuIcon
                property: "opacity"
                to: 0.6
                duration: 600
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                target: gpuIcon
                property: "opacity"
                to: 1.0
                duration: 600
                easing.type: Easing.InOutSine
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
