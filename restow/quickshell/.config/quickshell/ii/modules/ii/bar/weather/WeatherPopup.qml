pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.bar
import qs.services

StyledPopup {
    id: root

    onActiveChanged: {
        if (active) {
            GlobalStates.activeInspectorCount++;
        } else {
            GlobalStates.activeInspectorCount = Math.max(0, GlobalStates.activeInspectorCount - 1);
        }
    }

    Component.onDestruction: {
        if (active) {
            GlobalStates.activeInspectorCount = Math.max(0, GlobalStates.activeInspectorCount - 1);
        }
    }

    StyledFlickable {
        id: flickable
        anchors.centerIn: parent
        implicitWidth: 880
        implicitHeight: Math.min(contentColumn.implicitHeight, (root.QsWindow?.window?.screen?.height ?? 1080) * 0.85)
        contentWidth: width
        contentHeight: contentColumn.implicitHeight
        clip: true

        ColumnLayout {
            id: contentColumn
            width: parent.width
            spacing: 12

            // 1. Severe Weather Alert Banner (collapses when empty per D-54-07, D-54-10)
            WeatherAlertBanner {
                id: alertBanner
                Layout.fillWidth: true
            }

            // 2. Primary Desktop Overview Hero Card (D-54-10)
            WeatherHeroCard {
                id: heroCard
                Layout.fillWidth: true
            }

            // 3. 24-Hour Forecast Splines & Rain Graph (GRAPH-01..04, D-54-10)
            WeatherGraph {
                id: weatherGraph
                Layout.fillWidth: true
                activeMetric: "temp"
                popupActive: root.active
            }

            // 3b. Locked Wind Graph Instance (G-54.3-4 stack-instances, no tab chrome)
            WeatherGraph {
                id: windGraph
                Layout.fillWidth: true
                title: "Hourly Wind Speed and Direction"
                activeMetric: "wind"
                popupActive: root.active
            }

            // 3c. Locked Air Quality Graph Instance (G-54.3-4 stack-instances, no tab chrome)
            WeatherGraph {
                id: aqiGraph
                Layout.fillWidth: true
                title: "Hourly Air Quality"
                activeMetric: "aqi"
                popupActive: root.active
            }

            // 3d. Locked Pressure Graph Instance (G-54.3-4 stack-instances, no tab chrome)
            WeatherGraph {
                id: baroGraph
                Layout.fillWidth: true
                title: "Hourly Pressure and Visibility"
                activeMetric: "baro"
                popupActive: root.active
            }

            // 3e. Locked UV Graph Instance (G-54.3-4 stack-instances, no tab chrome)
            WeatherGraph {
                id: uvGraph
                Layout.fillWidth: true
                title: "Hourly UV and Solar Radiation"
                activeMetric: "uv"
                popupActive: root.active
            }

            // 4. Paired Domain Grid 1: Atmospheric & Wind (POPUP-03, POPUP-05, D-54-10)
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                WeatherAtmosphericCard {
                    id: atmosphericCard
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                }

                WeatherWindCard {
                    id: windCard
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                }
            }

            // 5. Paired Domain Grid 2: Air Quality & Astronomy (POPUP-04, POPUP-06, D-54-10)
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                WeatherAqiCard {
                    id: aqiCard
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                }

                WeatherAstronomyCard {
                    id: astronomyCard
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                }
            }
        }
    }
}
