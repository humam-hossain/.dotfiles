import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import "WeatherGraphMath.js" as GM

// Phase 54.4 graph card frame. One component, three kinds ("temp", "rainwind", "airuv"),
// drawn through the pure WeatherGraphMath.js module (D-54.4-02). The legend row (plan 05) is the
// card header, so the WeatherBaseCard title row stays hidden (PA-9).
WeatherBaseCard {
    id: root

    // Drawing branch in WeatherGraphMath.js (D-54.4-02)
    property string graphKind: "temp"
    // Shared left gutter, bound by the popup so plots line up hour for hour (D-54.4-05)
    property real gutter: 24
    property bool popupActive: true
    property var model: (Weather.timeline && Weather.timeline.length === 25) ? Weather.timeline : Weather.hourly

    readonly property bool isTimeline25: (root.model && root.model.length === 25 && root.model[12] && root.model[12].isNow !== undefined)
    property int axisStride: root.isTimeline25 ? 4 : 3

    readonly property var validHours: GM.normalizeSlots(root.model)
    readonly property var scales: GM.computeScales(root.graphKind, root.validHours)

    // Single-source geometry (RESEARCH Pattern 1): canvas, axis and later markers read only these
    readonly property real plotLeft: root.gutter
    readonly property real plotRight: graphArea.width - 8
    readonly property real slotW: root.validHours.length > 0 ? Math.max(0, root.plotRight - root.plotLeft) / root.validHours.length : 0
    readonly property real plotTop: 16 // peak-label headroom
    readonly property real plotBottom: graphArea.height

    property bool _paintErrorLogged: false

    function slotX(i) {
        return root.plotLeft + (i + 0.5) * root.slotW;
    }

    function geom() {
        return {
            width: graphArea.width,
            height: graphArea.height,
            plotLeft: root.plotLeft,
            plotRight: root.plotRight,
            plotTop: root.plotTop,
            plotBottom: root.plotBottom,
            slotW: root.slotW,
            n: root.validHours.length,
            isTimeline25: root.isTimeline25
        };
    }

    function theme() {
        return {
            grid: Appearance.colors.colOutlineVariant,
            text: Appearance.colors.colOnSurfaceVariant,
            shade: Appearance.colors.colLayer1,
            now: Appearance.colors.colPrimary
        };
    }

    function requestRepaint() {
        if (root.popupActive) {
            graphCanvas.requestPaint();
        }
    }

    title: ""
    icon: ""
    Layout.fillWidth: true

    Item {
        id: graphArea
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 120

        Canvas {
            id: graphCanvas
            anchors.fill: parent
            renderStrategy: Canvas.Immediate

            onWidthChanged: root.requestRepaint()
            onHeightChanged: root.requestRepaint()

            onPaint: {
                const ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                try {
                    GM.drawKind(ctx, root.graphKind, root.geom(), root.validHours, root.scales);
                } catch (e) {
                    if (!root._paintErrorLogged) {
                        root._paintErrorLogged = true;
                        console.warn("WeatherGraph paint failed for kind " + root.graphKind + ": " + e);
                    }
                }
            }
        }
    }

    // Own x-axis, identical on every card: 7 ticks, condition icon over a 12-hour label, centre "Now" (D-54.4-06)
    Item {
        id: axisRow
        Layout.fillWidth: true
        Layout.preferredHeight: 32

        Repeater {
            model: GM.axisTicks(root.validHours.length, root.axisStride)

            delegate: Column {
                id: tick

                required property int modelData
                readonly property var slot: root.validHours[tick.modelData]
                readonly property bool isNowTick: root.isTimeline25 && tick.modelData === 12

                x: root.slotX(tick.modelData) - width / 2
                spacing: 0

                MaterialSymbol {
                    anchors.horizontalCenter: parent.horizontalCenter
                    iconSize: 14
                    fill: 0
                    color: Appearance.colors.colOnSurfaceVariant
                    text: (tick.slot && tick.slot.glyph) ? tick.slot.glyph : "cloud"
                }

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    textFormat: Text.PlainText
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    font.weight: tick.isNowTick ? Font.Bold : Font.Normal
                    color: tick.isNowTick ? Appearance.colors.colPrimary : Appearance.colors.colOnSurfaceVariant
                    text: GM.axisTickLabel(tick.modelData, tick.slot, root.isTimeline25)
                }
            }
        }
    }

    // Repaint gating (54.3 invariant): paint only while the popup is open
    Connections {
        target: Weather

        function onHourlyChanged() {
            root.requestRepaint();
        }

        function onTimelineChanged() {
            root.requestRepaint();
        }
    }

    onPopupActiveChanged: root.requestRepaint()
    onGutterChanged: root.requestRepaint()
    Component.onCompleted: root.requestRepaint()
}
