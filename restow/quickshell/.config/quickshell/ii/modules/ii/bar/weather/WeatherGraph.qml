import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

WeatherBaseCard {
    id: root

    property int activeSlotIndex: 0
    property real activeScrubX: 0
    property real activeScrubY: 0
    property var model: Weather.hourly
    property bool popupActive: true

    readonly property var validHours: {
        const raw = root.model || [];
        const filtered = [];
        for (let i = 0; i < raw.length; ++i) {
            if (raw[i] && String(raw[i].time) !== "24") {
                filtered.push(raw[i]);
            }
        }
        return filtered.slice(0, 24);
    }

    icon: "show_chart"
    implicitHeight: 400
    Layout.fillWidth: true
    title: "24-Hour Forecast"

    function computeMonotoneSplineControlPoints(points) {
        const n = points.length;
        if (n < 2)
            return [];

        const dx = [];
        const dy = [];
        const m = []; // secants
        for (let i = 0; i < n - 1; ++i) {
            const dxi = points[i + 1].x - points[i].x;
            const dyi = points[i + 1].y - points[i].y;
            dx.push(dxi);
            dy.push(dyi);
            m.push(dxi === 0 ? 0 : dyi / dxi);
        }

        const tangents = new Array(n);
        tangents[0] = m[0];
        tangents[n - 1] = m[n - 2];
        for (let i = 1; i < n - 1; ++i) {
            tangents[i] = (m[i - 1] + m[i]) / 2;
        }

        // Fritsch-Carlson monotonicity check & clamping
        for (let i = 0; i < n - 1; ++i) {
            if (m[i] === 0) {
                tangents[i] = 0;
                tangents[i + 1] = 0;
            } else {
                const alpha = tangents[i] / m[i];
                const beta = tangents[i + 1] / m[i];
                if (alpha < 0)
                    tangents[i] = 0;
                if (beta < 0)
                    tangents[i + 1] = 0;
                const distSq = alpha * alpha + beta * beta;
                if (distSq > 9) {
                    const tau = 3 / Math.sqrt(distSq);
                    tangents[i] = tau * alpha * m[i];
                    tangents[i + 1] = tau * beta * m[i];
                }
            }
        }

        const controlPoints = [];
        for (let i = 0; i < n - 1; ++i) {
            const segmentDx = dx[i];
            controlPoints.push({
                cp1x: points[i].x + segmentDx / 3,
                cp1y: points[i].y + tangents[i] * segmentDx / 3,
                cp2x: points[i + 1].x - segmentDx / 3,
                cp2y: points[i + 1].y - tangents[i + 1] * segmentDx / 3
            });
        }
        return controlPoints;
    }

    Item {
        id: graphArea

        anchors.fill: parent
        anchors.topMargin: 2

        Canvas {
            id: graphCanvas

            anchors.fill: parent
            renderStrategy: Canvas.Immediate
            renderTarget: Canvas.FramebufferObject

            onPaint: {
                const ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);

                const hours = root.validHours;
                if (!hours || hours.length < 2)
                    return;

                const plotLeft = 14;
                const plotRight = width - 14;
                const plotW = Math.max(10, plotRight - plotLeft);
                const n = hours.length;
                const slotW = plotW / n;

                const tempAreaTop = 16;
                const tempAreaBottom = height * 0.62;
                const precipAreaTop = height * 0.68;
                const precipAreaBottom = height - 20;

                // 1. Min / Max range calculation with 1°C padding (D-54-16)
                let minT = 999;
                let maxT = -999;
                for (let i = 0; i < n; ++i) {
                    const t = Number(hours[i].tempC ?? 20);
                    const f = Number(hours[i].FeelsLikeC ?? t);
                    if (t < minT)
                        minT = t;
                    if (t > maxT)
                        maxT = t;
                    if (f < minT)
                        minT = f;
                    if (f > maxT)
                        maxT = f;
                }
                if (minT === 999) {
                    minT = 15;
                    maxT = 25;
                }
                const padMin = minT - 1;
                const padMax = maxT + 1;
                const rangeT = Math.max(1, padMax - padMin);

                function getY(val) {
                    return tempAreaBottom - ((val - padMin) / rangeT) * (tempAreaBottom - tempAreaTop);
                }

                // 2. High / Low Dotted Guidelines (D-54-16)
                ctx.save();
                ctx.strokeStyle = Appearance.colors.colOutlineVariant || "#444";
                ctx.fillStyle = Appearance.colors.colOnSurfaceVariant || "#888";
                ctx.font = "9px sans-serif";
                ctx.setLineDash([2, 3]);
                ctx.lineWidth = 1;

                // Max guideline
                const yHigh = getY(maxT);
                ctx.beginPath();
                ctx.moveTo(plotLeft, yHigh);
                ctx.lineTo(plotRight, yHigh);
                ctx.stroke();
                ctx.fillText(Math.round(maxT) + "°", plotLeft - 10, yHigh + 3);

                // Min guideline
                const yLow = getY(minT);
                ctx.beginPath();
                ctx.moveTo(plotLeft, yLow);
                ctx.lineTo(plotRight, yLow);
                ctx.stroke();
                ctx.fillText(Math.round(minT) + "°", plotLeft - 10, yLow + 3);
                ctx.restore();

                // 3. Coordinate Generation
                const actualPoints = [];
                const feelsPoints = [];
                for (let i = 0; i < n; ++i) {
                    const cx = plotLeft + (i + 0.5) * slotW;
                    const tVal = Number(hours[i].tempC ?? 20);
                    const fVal = Number(hours[i].FeelsLikeC ?? tVal);
                    actualPoints.push({
                        x: cx,
                        y: getY(tVal)
                    });
                    feelsPoints.push({
                        x: cx,
                        y: getY(fVal)
                    });
                }

                const actualCP = root.computeMonotoneSplineControlPoints(actualPoints);
                const feelsCP = root.computeMonotoneSplineControlPoints(feelsPoints);

                // 4. Gradient Fill under Actual Temp Spline (D-54-14)
                if (actualCP.length > 0) {
                    ctx.save();
                    const grad = ctx.createLinearGradient(0, tempAreaTop, 0, tempAreaBottom);
                    grad.addColorStop(0, Appearance.colors.colPrimary ? Appearance.colors.colPrimary : "#4fc3f7");
                    grad.addColorStop(1, "transparent");

                    ctx.beginPath();
                    ctx.moveTo(actualPoints[0].x, tempAreaBottom);
                    ctx.lineTo(actualPoints[0].x, actualPoints[0].y);
                    for (let i = 0; i < actualCP.length; ++i) {
                        ctx.bezierCurveTo(actualCP[i].cp1x, actualCP[i].cp1y, actualCP[i].cp2x, actualCP[i].cp2y, actualPoints[i + 1].x, actualPoints[i + 1].y);
                    }
                    ctx.lineTo(actualPoints[actualPoints.length - 1].x, tempAreaBottom);
                    ctx.closePath();
                    ctx.fillStyle = grad;
                    ctx.globalAlpha = 0.22;
                    ctx.fill();
                    ctx.restore();
                }

                // 5. Solid Actual Temperature Spline Stroke (D-54-14)
                if (actualCP.length > 0) {
                    ctx.save();
                    ctx.strokeStyle = Appearance.colors.colPrimary || "#4fc3f7";
                    ctx.lineWidth = 2;
                    ctx.beginPath();
                    ctx.moveTo(actualPoints[0].x, actualPoints[0].y);
                    for (let i = 0; i < actualCP.length; ++i) {
                        ctx.bezierCurveTo(actualCP[i].cp1x, actualCP[i].cp1y, actualCP[i].cp2x, actualCP[i].cp2y, actualPoints[i + 1].x, actualPoints[i + 1].y);
                    }
                    ctx.stroke();
                    ctx.restore();
                }

                // 6. Dashed Feels-Like Temperature Spline Stroke (D-54-14)
                if (feelsCP.length > 0) {
                    ctx.save();
                    ctx.strokeStyle = Appearance.colors.colSecondary || "#81c784";
                    ctx.setLineDash([3, 3]);
                    ctx.lineWidth = 1.5;
                    ctx.beginPath();
                    ctx.moveTo(feelsPoints[0].x, feelsPoints[0].y);
                    for (let i = 0; i < feelsCP.length; ++i) {
                        ctx.bezierCurveTo(feelsCP[i].cp1x, feelsCP[i].cp1y, feelsCP[i].cp2x, feelsCP[i].cp2y, feelsPoints[i + 1].x, feelsPoints[i + 1].y);
                    }
                    ctx.stroke();
                    ctx.restore();
                }

                // 7. Lower Tier Hourly Rain Columns (GRAPH-02, D-54-18, D-54-19)
                const precipH = precipAreaBottom - precipAreaTop;
                ctx.save();
                for (let i = 0; i < n; ++i) {
                    const chance = Math.max(0, Math.min(100, parseInt(hours[i].chanceofrain ?? 0, 10)));
                    const precipMM = parseFloat(hours[i].precipMM ?? 0);
                    const barH = (chance / 100) * precipH;
                    const barW = Math.max(2, slotW - 3);
                    const barX = plotLeft + (i + 0.5) * slotW - barW / 2;

                    // Bar color: deep saturated blue if > 2.5mm per GRAPH-02, D-54-19
                    ctx.fillStyle = (precipMM > 2.5) ? "#1976D2" : (Appearance.colors.colPrimary || "#4fc3f7");
                    ctx.globalAlpha = (chance > 0) ? 0.75 : 0.15;
                    ctx.fillRect(barX, precipAreaBottom - Math.max(1, barH), barW, Math.max(1, barH));
                }
                ctx.restore();

                // 8. X-Axis Timestamps (3-Hour Increments) (D-54-17)
                ctx.save();
                ctx.fillStyle = Appearance.colors.colOnSurfaceVariant || "#888";
                ctx.font = "9px sans-serif";
                ctx.textAlign = "center";
                for (let i = 0; i < n; i += 3) {
                    const cx = plotLeft + (i + 0.5) * slotW;
                    const rawTime = String(hours[i].time ?? "0");
                    let timeLabel = "Now";
                    if (i > 0) {
                        const hr = rawTime.length > 2 ? rawTime.slice(0, -2) : (rawTime === "0" ? "00" : rawTime);
                        timeLabel = hr.padStart(2, "0") + ":00";
                    }
                    ctx.fillText(timeLabel, cx, height - 5);
                }
                ctx.restore();
            }
        }

        // Zero-Repaint Interactive Hover Scrub Overlay (GRAPH-03, D-54-20)
        Item {
            id: scrubOverlay

            anchors.fill: parent
            visible: scrubMouseArea.containsMouse

            // Hairline indicator
            Rectangle {
                id: scrubHairline

                color: Appearance.colors.colOutlineVariant
                height: parent.height - 20
                width: 1
                x: root.activeScrubX
                y: 10
            }

            // Snap Dot indicator on actual temperature curve
            Rectangle {
                id: snapDot

                border.color: Appearance.colors.colLayer2
                border.width: 2
                color: Appearance.colors.colPrimary
                height: 8
                radius: 4
                width: 8
                x: root.activeScrubX - 4
                y: root.activeScrubY - 4
            }

            // Floating Tooltip Pill (D-54-21)
            Rectangle {
                id: tooltipPill

                border.color: Appearance.colors.colOutlineVariant
                border.width: 1
                color: Appearance.m3colors.m3surfaceContainerHigh || Appearance.colors.colLayer1
                implicitHeight: tooltipRow.implicitHeight + 8
                implicitWidth: tooltipRow.implicitWidth + 12
                radius: Appearance.rounding.verysmall
                x: Math.max(4, Math.min(parent.width - implicitWidth - 4, root.activeScrubX - implicitWidth / 2))
                y: Math.max(2, root.activeScrubY - implicitHeight - 8)

                RowLayout {
                    id: tooltipRow

                    anchors.centerIn: parent
                    spacing: 4

                    StyledText {
                        color: Appearance.colors.colOnLayer1
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        font.weight: Font.Bold
                        text: {
                            const h = root.validHours[root.activeSlotIndex];
                            if (!h)
                                return "--:--";
                            const rawTime = String(h.time ?? "0");
                            const hr = rawTime.length > 2 ? rawTime.slice(0, -2) : (rawTime === "0" ? "00" : rawTime);
                            return hr.padStart(2, "0") + ":00";
                        }
                    }

                    StyledText {
                        color: Appearance.colors.colOnSurfaceVariant
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        text: "•"
                    }

                    StyledText {
                        color: Appearance.colors.colPrimary
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        font.weight: Font.DemiBold
                        text: {
                            const h = root.validHours[root.activeSlotIndex];
                            if (!h)
                                return "--°C";
                            const t = h.tempC ?? "--";
                            const f = h.FeelsLikeC ?? t;
                            return `${t}°C (Feels ${f}°C)`;
                        }
                    }

                    StyledText {
                        color: Appearance.colors.colOnSurfaceVariant
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        text: "•"
                    }

                    StyledText {
                        color: Appearance.m3colors.m3secondary
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        text: {
                            const h = root.validHours[root.activeSlotIndex];
                            if (!h)
                                return "0%";
                            const chance = h.chanceofrain ?? "0";
                            const mm = h.precipMM ?? "0.0";
                            return `${chance}% (${mm}mm)`;
                        }
                    }
                }
            }
        }

        MouseArea {
            id: scrubMouseArea

            anchors.fill: parent
            hoverEnabled: true

            onPositionChanged: mouse => {
                const hours = root.validHours;
                if (!hours || hours.length === 0)
                    return;

                const plotLeft = 14;
                const plotRight = width - 14;
                const plotW = Math.max(10, plotRight - plotLeft);
                const n = hours.length;
                const slotW = plotW / n;

                const idx = Math.max(0, Math.min(n - 1, Math.floor((mouse.x - plotLeft) / slotW)));
                root.activeSlotIndex = idx;
                root.activeScrubX = plotLeft + (idx + 0.5) * slotW;

                // Derive Y coordinate directly without canvas paint
                const tempAreaTop = 16;
                const tempAreaBottom = height * 0.62;
                let minT = 999;
                let maxT = -999;
                for (let i = 0; i < n; ++i) {
                    const t = Number(hours[i].tempC ?? 20);
                    const f = Number(hours[i].FeelsLikeC ?? t);
                    if (t < minT)
                        minT = t;
                    if (t > maxT)
                        maxT = t;
                    if (f < minT)
                        minT = f;
                    if (f > maxT)
                        maxT = f;
                }
                if (minT === 999) {
                    minT = 15;
                    maxT = 25;
                }
                const padMin = minT - 1;
                const padMax = maxT + 1;
                const rangeT = Math.max(1, padMax - padMin);
                const val = Number(hours[idx].tempC ?? 20);
                root.activeScrubY = tempAreaBottom - ((val - padMin) / rangeT) * (tempAreaBottom - tempAreaTop);
            }
        }
    }

    // Event-driven Canvas rendering strictly gated behind visibility and data updates (GRAPH-04, D-54-22)
    Connections {
        function onHourlyChanged() {
            if (root.popupActive) {
                graphCanvas.requestPaint();
            }
        }
        target: Weather
    }

    onPopupActiveChanged: {
        if (root.popupActive) {
            graphCanvas.requestPaint();
        }
    }

    Component.onCompleted: {
        if (root.popupActive) {
            graphCanvas.requestPaint();
        }
    }
}
