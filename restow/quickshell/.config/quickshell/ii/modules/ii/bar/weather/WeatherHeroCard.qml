import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

WeatherBaseCard {
    id: root

    property string city: Weather.city
    property string country: Weather.country
    property bool isOffline: Weather.isOffline
    property bool isStale: Weather.isStale
    property var model: Weather.current
    property string observationTime: Weather.lastRefresh

    RowLayout {
        anchors.fill: parent
        spacing: 12

        // Large Temperature & Glyph
        RowLayout {
            spacing: 8

            MaterialSymbol {
                color: (root.isStale || root.isOffline) ? Appearance.m3colors.m3onSurfaceVariant : Appearance.colors.colOnLayer1
                fill: 0
                iconSize: 36
                text: root.model?.glyph || WeatherGlyphs.glyphDefault
            }

            StyledText {
                color: (root.isStale || root.isOffline) ? Appearance.m3colors.m3onSurfaceVariant : Appearance.colors.colOnLayer1
                font.pixelSize: Appearance.font.pixelSize.huge
                font.weight: Font.Bold
                text: (root.model?.tempC !== undefined && root.model?.tempC !== null && root.model?.tempC !== "--" && !isNaN(Number(root.model.tempC))) ? (Math.round(Number(root.model.tempC)) + "°C") : "--°C"
            }
        }

        Item {
            Layout.fillWidth: true
        }

        // Location & Condition Metadata
        ColumnLayout {
            spacing: 2

            StyledText {
                color: Appearance.colors.colOnLayer1
                font.pixelSize: Appearance.font.pixelSize.normal
                font.weight: Font.Bold
                text: root.city || "Dhaka"
            }

            StyledText {
                color: Appearance.colors.colOnSurfaceVariant
                font.pixelSize: Appearance.font.pixelSize.smaller
                text: root.model?.desc || "Clear"
            }

            RowLayout {
                spacing: 6

                // Stale / Offline Pill (D-54-32)
                Rectangle {
                    color: Appearance.m3colors.m3errorContainer
                    implicitHeight: staleText.implicitHeight + 4
                    implicitWidth: staleText.implicitWidth + 8
                    radius: Appearance.rounding.verysmall
                    visible: root.isStale || root.isOffline

                    StyledText {
                        id: staleText

                        anchors.centerIn: parent
                        color: Appearance.m3colors.m3onErrorContainer
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        text: root.isOffline ? "Offline" : "Stale"
                    }
                }

                // Observation Time
                StyledText {
                    color: Appearance.colors.colOnSurfaceVariant
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    text: root.observationTime || "--:--"
                }

                // Passive Reload Button (D-54-37, D-54-38)
                MaterialSymbol {
                    id: refreshIcon

                    color: Appearance.colors.colOnSurfaceVariant
                    fill: 0
                    iconSize: 16
                    opacity: refreshDebounceTimer.running ? 0.5 : 1.0
                    text: "refresh"

                    MouseArea {
                        anchors.fill: parent
                        enabled: !refreshDebounceTimer.running
                        onClicked: {
                            refreshAnimation.restart();
                            refreshDebounceTimer.restart();
                            Weather.getData();
                        }
                    }

                    RotationAnimation on rotation {
                        id: refreshAnimation

                        duration: 600
                        easing.bezierCurve: Appearance.animationCurves.expressiveEffects
                        easing.type: Easing.BezierSpline
                        from: 0
                        running: false
                        to: 360
                    }

                    Timer {
                        id: refreshDebounceTimer

                        interval: 2000
                        repeat: false
                        running: false
                    }
                }
            }
        }
    }
}
