pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.bar
import qs.services
import "WeatherGraphMath.js" as GM

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

    // Non-scrolling, percent-sized content (D-54.4-03). Centred so padding stays even on all sides.
    Item {
        id: contentRoot
        anchors.centerIn: parent

        // Popup's own screen first (D-54.4-03); the bar's screen while the popup window is not yet
        // resolved (Pitfall 12); 1920x1080 last.
        readonly property var popupScreen: contentRoot.QsWindow?.window?.screen ?? root.hoverTarget?.QsWindow?.window?.screen ?? root.QsWindow?.window?.screen ?? null
        readonly property real sw: (contentRoot.popupScreen && contentRoot.popupScreen.width > 0) ? contentRoot.popupScreen.width : 1920
        readonly property real sh: (contentRoot.popupScreen && contentRoot.popupScreen.height > 0) ? contentRoot.popupScreen.height : 1080

        // Read-only sizing from config (D-54.4-04: no runtime config writes)
        readonly property var popupSize: GM.popupContentSize(contentRoot.sw, contentRoot.sh, Config.options.bar.weather.popupWidthPercent, Config.options.bar.weather.popupHeightPercent, {
            chrome: Appearance.sizes.elevationMargin * 2 + 20,
            edgeGap: Appearance.sizes.hyprlandGapsOut,
            barHeight: Appearance.sizes.barHeight,
            minOuterW: 900,
            minContentH: alertBanner.implicitHeight + heroCard.implicitHeight + contentColumn.spacing * 2 + 240
        })

        // Shared graph gutter: widest temperature y-label plus padding (D-54.4-05)
        readonly property real graphGutter: Math.max(24, Math.ceil(gutterMetrics.width) + 6)

        implicitWidth: contentRoot.popupSize.width
        implicitHeight: contentRoot.popupSize.height

        TextMetrics {
            id: gutterMetrics
            font.family: "sans-serif"
            font.pixelSize: 10
            text: "-88°"
        }

        ColumnLayout {
            id: contentColumn
            anchors.fill: parent
            spacing: 12

            // 1. Severe Weather Alert Banner (collapses when empty per D-54-07, D-54-10)
            WeatherAlertBanner {
                id: alertBanner
                Layout.fillWidth: true
            }

            // 2. Primary Desktop Overview Hero Card (D-54-10, POPUP-02)
            WeatherHeroCard {
                id: heroCard
                Layout.fillWidth: true
            }

            // Hidden, not deleted, until Phase 54.5 decides their fate (D-54.4-01)
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                visible: false

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

            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                visible: false

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

            // 3. Three equal graph cards side by side: Temp, Rain/Wind/Vis, Air/UV/Pressure (D-54.4-02)
            RowLayout {
                id: graphRow
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12

                readonly property real cardWidth: Math.floor((width - spacing * 2) / 3)

                WeatherGraph {
                    id: tempGraph
                    graphKind: "temp"
                    Layout.preferredWidth: graphRow.cardWidth
                    Layout.fillHeight: true
                    gutter: contentRoot.graphGutter
                    popupActive: root.active
                }

                WeatherGraph {
                    id: rainGraph
                    graphKind: "rainwind"
                    Layout.preferredWidth: graphRow.cardWidth
                    Layout.fillHeight: true
                    gutter: contentRoot.graphGutter
                    popupActive: root.active
                }

                WeatherGraph {
                    id: airGraph
                    graphKind: "airuv"
                    Layout.preferredWidth: graphRow.cardWidth
                    Layout.fillHeight: true
                    gutter: contentRoot.graphGutter
                    popupActive: root.active
                }
            }
        }
    }
}
