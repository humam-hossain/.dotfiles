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

    // Two-tier alert state thresholds (D-04)
    readonly property bool ramCritical: (ResourceUsage.memoryUsedPercentage || 0.0) >= 0.90
    readonly property bool ramWarning: !ramCritical && (ResourceUsage.memoryUsedPercentage || 0.0) >= 0.70

    readonly property bool storageCritical: ((StorageUsage.rootDisk?.usePercent ?? 0) / 100.0) >= 0.90
    readonly property bool storageWarning: !storageCritical && ((StorageUsage.rootDisk?.usePercent ?? 0) / 100.0) >= 0.70

    // Dynamic Material You token resolution with dots-hyprland amber warning color fallback
    readonly property color warningColor: Appearance.colors.colWarning !== undefined ? Appearance.colors.colWarning : "#FFA000"
    readonly property color ramColor: ramCritical ? Appearance.colors.colError : (ramWarning ? warningColor : Appearance.colors.colOnLayer1)
    readonly property color storageColor: storageCritical ? Appearance.colors.colError : (storageWarning ? warningColor : Appearance.colors.colOnLayer1)

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

        MemoryStoragePopup {
            hoverTarget: root.hoverArea
        }
    }

    // --- RAM Section (MaterialSymbol + capacity readout) ---
    MaterialSymbol {
        id: ramIcon
        Layout.alignment: Qt.AlignVCenter
        text: "memory"
        iconSize: Appearance.font.pixelSize.normal
        color: root.ramColor

        Behavior on color {
            ColorAnimation {
                duration: 200
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.expressiveEffects
            }
        }

        // Breathing pulse animation on critical red (D-04)
        SequentialAnimation {
            id: ramPulseAnimation
            running: root.ramCritical
            loops: Animation.Infinite
            onRunningChanged: {
                if (!running) {
                    ramIcon.opacity = 1.0;
                    ramText.opacity = 1.0;
                }
            }
            ParallelAnimation {
                NumberAnimation { target: ramIcon; property: "opacity"; to: 0.4; duration: 600; easing.type: Easing.InOutSine }
                NumberAnimation { target: ramText; property: "opacity"; to: 0.4; duration: 600; easing.type: Easing.InOutSine }
            }
            ParallelAnimation {
                NumberAnimation { target: ramIcon; property: "opacity"; to: 1.0; duration: 600; easing.type: Easing.InOutSine }
                NumberAnimation { target: ramText; property: "opacity"; to: 1.0; duration: 600; easing.type: Easing.InOutSine }
            }
        }
    }

    StyledText {
        id: ramText
        Layout.alignment: Qt.AlignVCenter
        text: {
            const freeGb = ((ResourceUsage.memoryAvailable > 0 ? ResourceUsage.memoryAvailable : ResourceUsage.memoryFree) / (1024 * 1024)).toFixed(1);
            const totalGb = (ResourceUsage.memoryTotal / (1024 * 1024)).toFixed(0);
            return `${freeGb} / ${totalGb} GB`;
        }
        font.pixelSize: Appearance.font.pixelSize.small
        color: root.ramColor

        Behavior on color {
            ColorAnimation {
                duration: 200
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.expressiveEffects
            }
        }
    }

    // --- Storage Section (storage icon + capacity readout) ---
    MaterialSymbol {
        id: storageIcon
        Layout.alignment: Qt.AlignVCenter
        Layout.leftMargin: root.vertical ? 0 : 6 // Visual cluster separation per D-02
        text: "storage"
        iconSize: Appearance.font.pixelSize.normal
        color: root.storageColor

        Behavior on color {
            ColorAnimation {
                duration: 200
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.expressiveEffects
            }
        }

        // Breathing pulse animation on critical red (D-04)
        SequentialAnimation {
            id: storagePulseAnimation
            running: root.storageCritical
            loops: Animation.Infinite
            onRunningChanged: {
                if (!running) {
                    storageIcon.opacity = 1.0;
                    storageText.opacity = 1.0;
                }
            }
            ParallelAnimation {
                NumberAnimation { target: storageIcon; property: "opacity"; to: 0.4; duration: 600; easing.type: Easing.InOutSine }
                NumberAnimation { target: storageText; property: "opacity"; to: 0.4; duration: 600; easing.type: Easing.InOutSine }
            }
            ParallelAnimation {
                NumberAnimation { target: storageIcon; property: "opacity"; to: 1.0; duration: 600; easing.type: Easing.InOutSine }
                NumberAnimation { target: storageText; property: "opacity"; to: 1.0; duration: 600; easing.type: Easing.InOutSine }
            }
        }
    }

    StyledText {
        id: storageText
        Layout.alignment: Qt.AlignVCenter
        text: {
            const rootAvailGb = ((StorageUsage.rootDisk?.availKb ?? 0) / (1024 * 1024)).toFixed(1);
            const rootTotalGb = ((StorageUsage.rootDisk?.totalKb ?? 0) / (1024 * 1024)).toFixed(0);
            return `${rootAvailGb} / ${rootTotalGb} GB`;
        }
        font.pixelSize: Appearance.font.pixelSize.small
        color: root.storageColor

        Behavior on color {
            ColorAnimation {
                duration: 200
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.expressiveEffects
            }
        }
    }
}
