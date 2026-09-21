pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell

BarGroup {
    id: root

    clip: true

    property real useShortenedForm: 0

    // Internal State Tracking
    property string previousState: "idle"
    property string lastRecordedDuration: "0:00"
    readonly property bool inWrapUp: wrapUpTimer.running

    // Public Component Aliases for Telemetry & Verification
    readonly property alias wrapUpTimer: wrapUpTimer
    readonly property alias pulseAnimation: pulseAnimation
    readonly property alias voiceIcon: voiceIcon
    readonly property alias voiceLabel: voiceLabel
    readonly property alias contentContainer: contentContainer
    readonly property alias inertMouseArea: inertMouseArea

    // Effective Lifecycle State (Sequential Linear Flow)
    readonly property string effectiveState: {
        if (inWrapUp) return "wrapup";
        return Voice.overallState;
    }

    // Dynamic Material You Palette Mapping (D-09, zero hardcoded hex colors)
    readonly property color currentColor: {
        switch (effectiveState) {
            case "recording": return Appearance.colors.colPrimary;
            case "transcribing": return Appearance.colors.colTertiary;
            case "typing": return Appearance.colors.colSecondary;
            case "speaking": return Appearance.colors.colSecondary;
            case "wrapup": return Appearance.colors.colSecondary;
            case "starting": return Appearance.colors.colPrimary;
            default: return Appearance.colors.colOnLayer1;
        }
    }

    // Dynamic Text Content Mapping (D-06, D-07)
    readonly property string displayText: {
        switch (effectiveState) {
            case "recording": return Voice.formattedDuration;
            case "speaking": return Voice.formattedDuration;
            case "transcribing": return Translation.tr("Transcribing...");
            case "typing": return Translation.tr("Typing...");
            case "wrapup": return lastRecordedDuration;
            case "starting": return Voice.formattedDuration;
            default: return "";
        }
    }

    readonly property bool isExpanded: effectiveState !== "idle" && useShortenedForm < 2 && !vertical

    // Responsive Width Binding with M3 250ms Emphasized Deceleration (D-04, VOICE-06, Pitfall 1)
    implicitWidth: vertical ? Appearance.sizes.baseVerticalBarWidth : (
        voiceIcon.implicitWidth + (isExpanded ? (voiceLabel.implicitWidth + 4) : 0) + padding * 2
    )

    resources: [
        // Completion Wrap-up Linger Timer (~1.5s per D-06)
        Timer {
            id: wrapUpTimer
            interval: 1500
            repeat: false
        },

        // React to Voice State Shifts & Duration Caching (D-06, Pitfall 4)
        Connections {
            target: Voice

            function onOverallStateChanged() {
                if (Voice.overallState === "recording" || Voice.overallState === "speaking") {
                    wrapUpTimer.stop();
                } else if (Voice.overallState === "idle") {
                    if (root.previousState === "typing" || root.previousState === "speaking") {
                        wrapUpTimer.restart();
                    } else {
                        wrapUpTimer.stop();
                    }
                } else {
                    wrapUpTimer.stop();
                }
                root.previousState = Voice.overallState;
            }

            function onFormattedDurationChanged() {
                if (Voice.formattedDuration !== "0:00") {
                    root.lastRecordedDuration = Voice.formattedDuration;
                }
            }
        }
    ]

    MouseArea {
        id: inertMouseArea
        parent: root
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        cursorShape: Qt.ArrowCursor
        hoverEnabled: false
        onPressed: event => event.accepted = true
    }

    // Content Layout Container (Pitfall 2)
    Item {
        id: contentContainer
        implicitWidth: voiceIcon.implicitWidth + (root.isExpanded ? (voiceLabel.implicitWidth + 4) : 0)
        implicitHeight: Appearance.font.pixelSize.normal
        Layout.alignment: root.vertical ? Qt.AlignCenter : Qt.AlignVCenter

        // AI Identity Soundwave Icon (D-02, D-03)
        MaterialSymbol {
            id: voiceIcon
            anchors.left: root.vertical ? undefined : parent.left
            anchors.centerIn: root.vertical ? parent : undefined
            anchors.verticalCenter: root.vertical ? undefined : parent.verticalCenter
            text: "graphic_eq"
            iconSize: Appearance.font.pixelSize.normal
            color: root.currentColor

            Behavior on color {
                ColorAnimation {
                    duration: 200
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.animationCurves.expressiveEffects
                }
            }

            // Gentle Breathing Pulse Animation (D-08, VOICE-03, Pitfall 3)
            SequentialAnimation {
                id: pulseAnimation
                running: root.effectiveState === "recording"
                loops: Animation.Infinite

                // Pitfall 3: Guarantee opacity resets to 1.0 on stop
                onRunningChanged: {
                    if (!running) voiceIcon.opacity = 1.0;
                }

                NumberAnimation {
                    target: voiceIcon
                    property: "opacity"
                    to: 0.5
                    duration: 500
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    target: voiceIcon
                    property: "opacity"
                    to: 1.0
                    duration: 500
                    easing.type: Easing.InOutSine
                }
            }
        }

        // Live Telemetry Label & State Badges (D-06, VOICE-05)
        StyledText {
            id: voiceLabel
            anchors.left: voiceIcon.right
            anchors.leftMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            text: root.displayText
            font.pixelSize: Appearance.font.pixelSize.small
            color: root.currentColor
            visible: root.isExpanded
            opacity: root.isExpanded ? 1.0 : 0.0

            Behavior on color {
                ColorAnimation {
                    duration: 200
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.animationCurves.expressiveEffects
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.animationCurves.expressiveEffects
                }
            }
        }
    }
}
