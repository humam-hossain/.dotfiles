pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.bar
import qs.services

MouseArea {
    id: root

    property bool hovered: containsMouse

    property var screen: root.QsWindow?.window?.screen
    property real useShortenedForm: (Appearance.sizes.barHellaShortenScreenWidthThreshold >= (root.screen?.width ?? 1920)) ? 2 : (Appearance.sizes.barShortenScreenWidthThreshold >= (root.screen?.width ?? 1920)) ? 1 : 0

    property bool vertical: (parent && parent.vertical !== undefined) ? parent.vertical : (Config.options?.bar?.vertical ?? false)

    implicitWidth: root.vertical ? Appearance.sizes.baseVerticalBarWidth : (contentLayout.implicitWidth + 10 * 2)
    implicitHeight: root.vertical ? (contentLayout.implicitHeight + 10 * 2) : Appearance.sizes.barHeight

    acceptedButtons: Qt.AllButtons
    cursorShape: Qt.ArrowCursor
    hoverEnabled: true

    onPressed: event => event.accepted = true
    onClicked: event => event.accepted = true

    // Temperature parsing & reactive telemetry (D-53-04, D-53-06, D-53-18, D-53-19, D-53-27, D-53-28)
    readonly property string formattedTemp: {
        const raw = Weather.current?.tempC;
        if (raw === undefined || raw === null || raw === "" || raw === "--") {
            return root.useShortenedForm === 2 ? "--°" : "--°C";
        }
        const num = Math.round(Number(raw));
        if (isNaN(num)) {
            return root.useShortenedForm === 2 ? "--°" : "--°C";
        }
        return num + (root.useShortenedForm === 2 ? "°" : "°C");
    }

    readonly property color contentColor: (Weather.isStale || Weather.isOffline) ? Appearance.m3colors.m3onSurfaceVariant : Appearance.colors.colOnLayer1

    readonly property string conditionGlyph: {
        if ((Weather.current?.tempC === "--" || Weather.current?.tempC === undefined || Weather.current?.tempC === null) && (!Weather.current?.glyph || Weather.current?.glyph === "cloud_off" || Weather.current?.glyph === "")) {
            return WeatherGlyphs.glyphOffline ?? "cloud_off";
        }
        return Weather.current?.glyph || (WeatherGlyphs.glyphDefault ?? "cloud");
    }

    // Imminent Rain & Severe Alert Hazard Indicators (D-53-11, D-53-12, D-53-13, D-53-14, D-53-15, D-53-16, D-53-17)
    readonly property int imminentRainChance: {
        if (!Weather.hourly || Weather.hourly.length === 0) return 0;
        let maxChance = 0;
        const slots = Math.min(3, Weather.hourly.length);
        for (let i = 0; i < slots; ++i) {
            const chance = parseInt(Weather.hourly[i]?.chanceofrain ?? "0", 10);
            if (!isNaN(chance) && chance > maxChance) {
                maxChance = chance;
            }
        }
        return maxChance;
    }

    readonly property bool imminentRain: imminentRainChance > 50

    readonly property bool hasSevereAlert: (Weather.alerts !== undefined && Weather.alerts !== null && Weather.alerts.length > 0)
    readonly property var activeAlert: hasSevereAlert ? Weather.alerts[0] : null
    readonly property color alertColor: activeAlert?.color ?? (activeAlert?.severity ? WeatherGlyphs.getAlertColor(activeAlert.severity) : Appearance.m3colors.m3error)

    readonly property bool showRainBadge: imminentRain && !hasSevereAlert && (root.useShortenedForm < 2)

    SequentialAnimation {
        id: alertPulseAnimation
        running: root.hasSevereAlert
        loops: 3
        onRunningChanged: {
            if (!running) {
                alertIcon.opacity = 1.0;
            }
        }
        ParallelAnimation {
            NumberAnimation {
                target: alertIcon
                property: "opacity"
                to: 0.4
                duration: 600
                easing.type: Easing.InOutSine
            }
        }
        ParallelAnimation {
            NumberAnimation {
                target: alertIcon
                property: "opacity"
                to: 1.0
                duration: 600
                easing.type: Easing.InOutSine
            }
        }
    }

    Connections {
        target: Weather
        function onAlertsChanged() {
            if (root.hasSevereAlert) {
                alertPulseAnimation.restart();
            }
        }
    }

    GridLayout {
        id: contentLayout
        anchors.centerIn: parent
        columns: root.vertical ? 1 : -1
        rowSpacing: 2
        columnSpacing: 4

        // 1. Severe Alert Warning Badge (D-53-14, D-53-23, D-53-26)
        Revealer {
            id: alertRevealer
            reveal: root.hasSevereAlert
            vertical: root.vertical
            implicitWidth: reveal ? alertIcon.implicitWidth : 0
            implicitHeight: reveal ? alertIcon.implicitHeight : 0

            MaterialSymbol {
                id: alertIcon
                fill: 0
                text: "warning"
                iconSize: Appearance.font.pixelSize.small
                color: root.alertColor
            }
        }

        // 2. Condition Glyph (D-53-20, D-53-21, D-53-23, D-53-25)
        MaterialSymbol {
            id: conditionGlyph
            fill: 0
            text: root.conditionGlyph
            iconSize: Appearance.font.pixelSize.large
            color: root.contentColor

            Behavior on color {
                ColorAnimation {
                    duration: 200
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.animationCurves.expressiveEffects
                }
            }
        }

        // 3. Temperature Text (D-53-18, D-53-19, D-53-20, D-53-23, D-53-25)
        StyledText {
            id: tempText
            text: root.formattedTemp
            font.pixelSize: Appearance.font.pixelSize.small
            color: root.contentColor

            Behavior on color {
                ColorAnimation {
                    duration: 200
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.animationCurves.expressiveEffects
                }
            }
        }

        // 4. Imminent Rain Badge (D-53-11, D-53-12, D-53-22, D-53-23, D-53-26)
        Revealer {
            id: rainRevealer
            reveal: root.showRainBadge
            vertical: root.vertical
            implicitWidth: reveal ? rainRow.implicitWidth : 0
            implicitHeight: reveal ? rainRow.implicitHeight : 0

            RowLayout {
                id: rainRow
                spacing: 2

                MaterialSymbol {
                    fill: 0
                    text: WeatherGlyphs.glyphHumidity ?? "water_drop"
                    iconSize: Appearance.font.pixelSize.small
                    color: Appearance.m3colors.m3primary
                }

                StyledText {
                    text: root.imminentRainChance + "%"
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.m3colors.m3primary
                }
            }
        }
    }

    WeatherPopup {
        id: weatherPopup
        hoverTarget: root
    }

    readonly property alias popup: weatherPopup
    readonly property bool popupActive: weatherPopup.active ?? false
}
