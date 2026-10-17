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

    // Shared hover hour for all three graphs (D-54.4-07). The popup is its only writer.
    property int hoverSlot: -1

    // Non-scrolling, percent-sized content (D-54.4-03). Centred so padding stays even on all sides.
    Item {
        id: contentRoot
        anchors.centerIn: parent

        // Closing the popup clears the shared hover slot. Separate block so the handler above stays intact.
        // Lives inside contentRoot: StyledPopup's default property is a single Item, so a top-level
        // Connections fails to load ("Cannot assign object of type Connections").
        Connections {
            target: root
            function onActiveChanged() {
                if (!root.active)
                    root.hoverSlot = -1;
            }
        }

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
                    hoverSlot: root.hoverSlot
                    onHoverRequested: idx => root.hoverSlot = idx
                }

                WeatherGraph {
                    id: rainGraph
                    graphKind: "rainwind"
                    Layout.preferredWidth: graphRow.cardWidth
                    Layout.fillHeight: true
                    gutter: contentRoot.graphGutter
                    popupActive: root.active
                    hoverSlot: root.hoverSlot
                    onHoverRequested: idx => root.hoverSlot = idx
                }

                WeatherGraph {
                    id: airGraph
                    graphKind: "airuv"
                    Layout.preferredWidth: graphRow.cardWidth
                    Layout.fillHeight: true
                    gutter: contentRoot.graphGutter
                    popupActive: root.active
                    hoverSlot: root.hoverSlot
                    onHoverRequested: idx => root.hoverSlot = idx
                }
            }
        }

        // Popup-level tooltip overlay above the cards, so a tooltip is never clipped by its own card
        // and can float over a neighbour (D-54.4-08). No MouseArea or HoverHandler here: hover passes
        // through to the graphs.
        Item {
            id: tooltipLayer
            anchors.fill: parent
            z: 10
            visible: root.hoverSlot >= 0

            Repeater {
                model: [tempGraph, rainGraph, airGraph]

                delegate: Rectangle {
                    id: tip

                    required property var modelData

                    readonly property var lines: root.hoverSlot >= 0 ? GM.tooltipLines(tip.modelData.graphKind, tip.modelData.validHours, root.hoverSlot) : []

                    // Reactive arithmetic only; item-mapping calls do not update reactively
                    readonly property real cardX: contentColumn.x + graphRow.x + tip.modelData.x
                    readonly property real cardY: contentColumn.y + graphRow.y + tip.modelData.y
                    readonly property real anchorX: tip.cardX + tip.modelData.plotOriginX + tip.modelData.slotX(root.hoverSlot)
                    readonly property real anchorY: tip.cardY + tip.modelData.plotOriginY + tip.modelData.markerTopY

                    visible: tip.lines.length > 0
                    color: "transparent"
                    implicitWidth: tipBody.implicitWidth + 20
                    implicitHeight: tipBody.implicitHeight + 12

                    // Stay inside the own card when it fits, else float over the neighbours; always inside the layer
                    x: {
                        const want = tip.anchorX - tip.width / 2;
                        if (tip.width <= tip.modelData.width)
                            return Math.max(tip.cardX, Math.min(tip.cardX + tip.modelData.width - tip.width, want));
                        return Math.max(0, Math.min(tooltipLayer.width - tip.width, want));
                    }
                    y: {
                        const above = tip.anchorY - tip.height - 8;
                        const want = above >= tip.cardY ? above : tip.anchorY + 14;
                        return Math.max(0, Math.min(tooltipLayer.height - tip.height, want));
                    }

                    // Translucent background; the text above it stays fully opaque
                    Rectangle {
                        anchors.fill: parent
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        opacity: 0.9
                        radius: Appearance.rounding.verysmall
                        border.width: 1
                        border.color: Appearance.colors.colOutlineVariant
                    }

                    ColumnLayout {
                        id: tipBody
                        x: 10
                        y: 6
                        spacing: 2

                        Repeater {
                            model: tip.lines

                            delegate: RowLayout {
                                id: tipRow

                                required property var modelData

                                spacing: 4

                                StyledText {
                                    visible: tipRow.modelData.lead.length > 0
                                    textFormat: Text.PlainText
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    font.weight: Font.Bold
                                    color: Appearance.colors.colOnLayer1
                                    text: tipRow.modelData.lead
                                }

                                StyledText {
                                    visible: tipRow.modelData.lead.length > 0 && (tipRow.modelData.icon.length > 0 || tipRow.modelData.text.length > 0)
                                    textFormat: Text.PlainText
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: Appearance.colors.colOnSurfaceVariant
                                    text: "·"
                                }

                                MaterialSymbol {
                                    visible: tipRow.modelData.icon.length > 0
                                    iconSize: 14
                                    fill: 0
                                    color: Appearance.colors.colOnSurfaceVariant
                                    text: tipRow.modelData.icon
                                }

                                StyledText {
                                    visible: tipRow.modelData.text.length > 0
                                    textFormat: Text.PlainText
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: Appearance.colors.colOnSurfaceVariant
                                    text: tipRow.modelData.text
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
