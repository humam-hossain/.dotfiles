import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

WeatherBaseCard {
    id: root

    // Composite essentials view is fixed (temp spline + feels-like + rain bars); no tab switching per G-54.3-1 tab-less preference.
    property string activeMetric: "temp"
    property int activeSlotIndex: 12
    property real activeScrubX: 0
    property real activeScrubY: 0
    property var model: (Weather.timeline && Weather.timeline.length === 25) ? Weather.timeline : Weather.hourly
    property bool popupActive: true

    readonly property bool isTimeline25: (root.model && root.model.length === 25 && root.model[12] && root.model[12].isNow !== undefined)

    readonly property var validHours: {
        const raw = root.model || [];
        if (root.isTimeline25) {
            return raw;
        }
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
    title: "Hourly Temperature and Rain Outlook"

    function computeMonotoneSplineControlPoints(points) {
        const n = points.length;
        if (n < 2)
            return [];

        const dx = [];
        const dy = [];
        const m = [];
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

    function calcTempBounds() {
        const hours = root.validHours || [];
        let minT = 999;
        let maxT = -999;
        for (let i = 0; i < hours.length; ++i) {
            const h = hours[i];
            if (root.isTimeline25 && h.isHistoricalUnavailable)
                continue;
            let t = 20;
            let f = 20;
            if (h.thermal && h.thermal.tempC !== null && h.thermal.tempC !== undefined) {
                t = Number(h.thermal.tempC);
                f = (h.thermal.feelsLikeC !== null && h.thermal.feelsLikeC !== undefined) ? Number(h.thermal.feelsLikeC) : t;
            } else {
                t = Number(h.tempC !== undefined ? h.tempC : 20);
                f = Number(h.FeelsLikeC !== undefined ? h.FeelsLikeC : t);
            }
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
        return {
            min: minT - 1,
            max: maxT + 1
        };
    }

    function calcWindMax() {
        const hours = root.validHours || [];
        let maxSpd = 0;
        for (let i = 0; i < hours.length; ++i) {
            const h = hours[i];
            if (root.isTimeline25 && h.isHistoricalUnavailable)
                continue;
            let spd = 0;
            let gst = 0;
            if (h.wind && h.wind.speedKmph !== null && h.wind.speedKmph !== undefined) {
                spd = Number(h.wind.speedKmph);
                gst = (h.wind.gustKmph !== null && h.wind.gustKmph !== undefined) ? Number(h.wind.gustKmph) : spd;
            } else {
                spd = parseInt(h.windspeedKmph !== undefined ? h.windspeedKmph : 0, 10) || 0;
                gst = parseInt(h.WindGustKmph !== undefined ? h.WindGustKmph : spd, 10) || spd;
            }
            if (spd > maxSpd)
                maxSpd = spd;
            if (gst > maxSpd)
                maxSpd = gst;
        }
        return Math.max(20, Math.ceil((maxSpd + 5) / 5) * 5);
    }

    function calcBaroBounds() {
        const hours = root.validHours || [];
        let minP = 9999;
        let maxP = -9999;
        for (let i = 0; i < hours.length; ++i) {
            const h = hours[i];
            if (root.isTimeline25 && h.isHistoricalUnavailable)
                continue;
            let p = 1013;
            if (h.atmosphere && h.atmosphere.pressureHpa !== null && h.atmosphere.pressureHpa !== undefined) {
                p = Number(h.atmosphere.pressureHpa);
            } else {
                p = parseInt(h.pressure !== undefined ? h.pressure : 1013, 10) || 1013;
            }
            if (p < minP)
                minP = p;
            if (p > maxP)
                maxP = p;
        }
        if (minP === 9999) {
            minP = 1010;
            maxP = 1020;
        }
        return {
            min: minP - 1,
            max: maxP + 1
        };
    }

    function calcUvMax() {
        const hours = root.validHours || [];
        let maxUV = 0;
        for (let i = 0; i < hours.length; ++i) {
            const h = hours[i];
            if (root.isTimeline25 && h.isHistoricalUnavailable)
                continue;
            let uv = 0;
            if (h.solar && h.solar.uvIndex !== null && h.solar.uvIndex !== undefined) {
                uv = Number(h.solar.uvIndex);
            } else {
                uv = parseInt(h.uvIndex !== undefined ? h.uvIndex : 0, 10) || 0;
            }
            if (uv > maxUV)
                maxUV = uv;
        }
        return Math.max(11, maxUV + 1);
    }

    function getMetricY(metricKey, slotIndex, plotTop, plotBottom) {
        const hours = root.validHours;
        if (!hours || slotIndex < 0 || slotIndex >= hours.length) {
            return plotBottom;
        }
        const h = hours[slotIndex];
        if (!h) {
            return plotBottom;
        }
        if (root.isTimeline25 && h.isHistoricalUnavailable) {
            return plotBottom;
        }

        const plotHeight = plotBottom - plotTop;

        switch (metricKey) {
        case "temp":
            {
                const bounds = root.calcTempBounds();
                const range = Math.max(1, bounds.max - bounds.min);
                let val = 20;
                if (h.thermal && h.thermal.tempC !== null && h.thermal.tempC !== undefined) {
                    val = Number(h.thermal.tempC);
                } else if (h.tempC !== undefined && h.tempC !== null) {
                    val = Number(h.tempC);
                }
                return plotBottom - ((val - bounds.min) / range) * plotHeight;
            }
        case "rain":
            {
                let prob = 0;
                if (h.moisture && h.moisture.rainProb !== null && h.moisture.rainProb !== undefined) {
                    prob = Number(h.moisture.rainProb);
                } else if (h.chanceofrain !== undefined && h.chanceofrain !== null) {
                    prob = parseInt(h.chanceofrain, 10) || 0;
                }
                const clamped = Math.max(0, Math.min(100, prob));
                return plotBottom - (clamped / 100.0) * plotHeight;
            }
        case "wind":
            {
                const maxSpeed = root.calcWindMax();
                let val = 0;
                if (h.wind && h.wind.speedKmph !== null && h.wind.speedKmph !== undefined) {
                    val = Number(h.wind.speedKmph);
                } else if (h.windspeedKmph !== undefined && h.windspeedKmph !== null) {
                    val = parseInt(h.windspeedKmph, 10) || 0;
                }
                const clamped = Math.max(0, val);
                return plotBottom - (clamped / maxSpeed) * plotHeight;
            }
        case "aqi":
            {
                let epa = 1;
                if (h.aqi && h.aqi.epaIndex !== null && h.aqi.epaIndex !== undefined) {
                    epa = Number(h.aqi.epaIndex);
                } else if (h.air_quality && h.air_quality["us-epa-index"]) {
                    epa = parseInt(h.air_quality["us-epa-index"], 10) || 1;
                }
                const clamped = Math.max(1, Math.min(6, epa));
                return plotBottom - ((clamped - 1) / 5.0) * plotHeight;
            }
        case "baro":
            {
                const bounds = root.calcBaroBounds();
                const range = Math.max(4, bounds.max - bounds.min);
                let val = 1013;
                if (h.atmosphere && h.atmosphere.pressureHpa !== null && h.atmosphere.pressureHpa !== undefined) {
                    val = Number(h.atmosphere.pressureHpa);
                } else if (h.pressure !== undefined && h.pressure !== null) {
                    val = parseInt(h.pressure, 10) || 1013;
                }
                return plotBottom - ((val - bounds.min) / range) * plotHeight;
            }
        case "uv":
            {
                const maxUV = root.calcUvMax();
                let val = 0;
                if (h.solar && h.solar.uvIndex !== null && h.solar.uvIndex !== undefined) {
                    val = Number(h.solar.uvIndex);
                } else if (h.uvIndex !== undefined && h.uvIndex !== null) {
                    val = parseInt(h.uvIndex, 10) || 0;
                }
                const clamped = Math.max(0, val);
                return plotBottom - (clamped / maxUV) * plotHeight;
            }
        default:
            return plotBottom;
        }
    }

    function getActiveMetricColor() {
        switch (root.activeMetric) {
        case "temp":
            return Appearance.colors.colPrimary;
        case "rain":
            return Appearance.m3colors.m3primary || Appearance.colors.colSecondary;
        case "wind":
            return Appearance.colors.colTertiary;
        case "aqi":
            {
                const h = root.validHours[root.activeSlotIndex];
                const epa = (h && h.aqi) ? h.aqi.epaIndex : 1;
                return WeatherGlyphs.getAqiColor(epa) || Appearance.colors.colPrimary;
            }
        case "baro":
            return Appearance.colors.colOutlineVariant;
        case "uv":
            {
                const h = root.validHours[root.activeSlotIndex];
                const uv = (h && h.solar) ? h.solar.uvIndex : 0;
                if (uv >= 8)
                    return Appearance.m3colors.m3error || "#E53935";
                if (uv >= 6)
                    return Appearance.colors.colTertiary || "#FF9800";
                return Appearance.colors.colPrimary;
            }
        default:
            return Appearance.colors.colPrimary;
        }
    }

    function formatDateChip(dateStr) {
        if (!dateStr)
            return "";
        const parts = String(dateStr).split("-");
        if (parts.length < 3)
            return dateStr;
        const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        const mIdx = parseInt(parts[1], 10) - 1;
        const day = parseInt(parts[2], 10);
        const mName = (mIdx >= 0 && mIdx < 12) ? months[mIdx] : parts[1];
        return mName + " " + day;
    }

    function formatTemporalLabel(slotIndex, slot) {
        if (!slot)
            return "--:--";
        if (root.isTimeline25) {
            const rel = slotIndex - 12;
            const timeStr = slot.timeStr || slot.timeLabel || "";
            if (rel === 0)
                return "NOW (" + (timeStr ? timeStr : "12:00") + ")";
            if (rel < 0) {
                if (slot.dayOffset !== undefined && slot.dayOffset < 0) {
                    return "Yesterday " + timeStr + " (" + rel + "h)";
                }
                return rel + "h (" + timeStr + ")";
            } else {
                if (slot.dayOffset !== undefined && slot.dayOffset > 0) {
                    return "Tomorrow " + timeStr + " (+" + rel + "h)";
                }
                return "+" + rel + "h (" + timeStr + ")";
            }
        }
        const rawTime = String(slot.time !== undefined ? slot.time : "0");
        const hr = rawTime.length > 2 ? rawTime.slice(0, -2) : (rawTime === "0" ? "00" : rawTime);
        return hr.padStart(2, "0") + ":00";
    }

    function formatTooltipMetric(metricKey, slot) {
        if (!slot)
            return "--";
        if (root.isTimeline25 && slot.isHistoricalUnavailable) {
            return "Past data unavailable";
        }

        switch (metricKey) {
        case "temp":
            {
                let t = "--";
                let f = "--";
                if (slot.thermal && slot.thermal.tempC !== null && slot.thermal.tempC !== undefined) {
                    t = slot.thermal.tempC;
                    f = (slot.thermal.feelsLikeC !== null && slot.thermal.feelsLikeC !== undefined) ? slot.thermal.feelsLikeC : t;
                } else {
                    t = slot.tempC !== undefined ? slot.tempC : "--";
                    f = slot.FeelsLikeC !== undefined ? slot.FeelsLikeC : t;
                }
                let prob = 0;
                let mm = 0.0;
                if (slot.moisture) {
                    prob = slot.moisture.rainProb !== undefined ? slot.moisture.rainProb : 0;
                    mm = slot.moisture.precipMM !== undefined ? slot.moisture.precipMM : 0.0;
                } else {
                    prob = slot.chanceofrain !== undefined ? slot.chanceofrain : 0;
                    mm = slot.precipMM !== undefined ? slot.precipMM : 0.0;
                }
                return t + "°C (Feels " + f + "°C) • Rain " + prob + "% (" + mm + "mm)";
            }
        case "rain":
            {
                let prob = 0;
                let mm = 0.0;
                let cloud = 0;
                if (slot.moisture) {
                    prob = slot.moisture.rainProb !== undefined ? slot.moisture.rainProb : 0;
                    mm = slot.moisture.precipMM !== undefined ? slot.moisture.precipMM : 0.0;
                    cloud = slot.moisture.cloudCover !== undefined ? slot.moisture.cloudCover : 0;
                } else {
                    prob = slot.chanceofrain !== undefined ? slot.chanceofrain : 0;
                    mm = slot.precipMM !== undefined ? slot.precipMM : 0.0;
                    cloud = slot.cloudcover !== undefined ? slot.cloudcover : 0;
                }
                return "Rain " + prob + "% • Precip " + mm + "mm • Cloud " + cloud + "%";
            }
        case "wind":
            {
                let spd = 0;
                let gst = "--";
                let dir = "N";
                let deg = 0;
                if (slot.wind) {
                    spd = slot.wind.speedKmph !== undefined ? slot.wind.speedKmph : 0;
                    gst = slot.wind.gustKmph !== undefined ? slot.wind.gustKmph : "--";
                    dir = slot.wind.dir16 !== undefined ? slot.wind.dir16 : "N";
                    deg = slot.wind.degree !== undefined ? slot.wind.degree : 0;
                } else {
                    spd = slot.windspeedKmph !== undefined ? slot.windspeedKmph : 0;
                    gst = slot.WindGustKmph !== undefined ? slot.WindGustKmph : "--";
                    dir = slot.winddir16Point !== undefined ? slot.winddir16Point : "N";
                    deg = slot.winddirDegree !== undefined ? slot.winddirDegree : 0;
                }
                return spd + " km/h • Gust " + gst + " km/h • " + dir + " (" + deg + "°)";
            }
        case "aqi":
            {
                let epa = 1;
                let p25 = 0.0;
                let p10 = 0.0;
                if (slot.aqi) {
                    epa = slot.aqi.epaIndex !== undefined ? slot.aqi.epaIndex : 1;
                    p25 = slot.aqi.pm2_5 !== undefined ? slot.aqi.pm2_5 : 0.0;
                    p10 = slot.aqi.pm10 !== undefined ? slot.aqi.pm10 : 0.0;
                } else if (slot.air_quality) {
                    epa = parseInt(slot.air_quality["us-epa-index"] || 1, 10);
                    p25 = parseFloat(slot.air_quality.pm2_5 || 0);
                    p10 = parseFloat(slot.air_quality.pm10 || 0);
                }
                const cat = WeatherGlyphs.getAqiCategory(epa);
                return "EPA " + epa + " (" + cat + ") • PM2.5: " + p25 + " µg/m³ • PM10: " + p10 + " µg/m³";
            }
        case "baro":
            {
                let press = 1013;
                let vis = 10;
                if (slot.atmosphere) {
                    press = slot.atmosphere.pressureHpa !== undefined ? slot.atmosphere.pressureHpa : 1013;
                    vis = slot.atmosphere.visibilityKm !== undefined ? slot.atmosphere.visibilityKm : 10;
                } else {
                    press = slot.pressure !== undefined ? slot.pressure : 1013;
                    vis = slot.visibility !== undefined ? slot.visibility : 10;
                }
                return press + " hPa • Vis " + vis + " km";
            }
        case "uv":
            {
                let uv = 0;
                let rad = 0.0;
                if (slot.solar) {
                    uv = slot.solar.uvIndex !== undefined ? slot.solar.uvIndex : 0;
                    rad = slot.solar.shortRad !== undefined ? slot.solar.shortRad : 0.0;
                } else {
                    uv = slot.uvIndex !== undefined ? slot.uvIndex : 0;
                }
                let tier = "Low";
                if (uv > 10)
                    tier = "Extreme";
                else if (uv >= 8)
                    tier = "Very High";
                else if (uv >= 6)
                    tier = "High";
                else if (uv >= 3)
                    tier = "Moderate";
                return "UV " + uv + " (" + tier + ") • Solar " + rad + " W/m²";
            }
        default:
            return "--";
        }
    }

    ColumnLayout {
        id: contentColumn
        anchors.fill: parent
        spacing: 6

        RowLayout {
            id: legendRow
            Layout.fillWidth: true
            Layout.preferredHeight: 22
            spacing: 14

            Row {
                id: legendActualEntry
                Layout.alignment: Qt.AlignVCenter
                spacing: 6

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    color: Appearance.colors.colPrimary
                    height: 3
                    radius: 1.5
                    width: 18
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    color: Appearance.colors.colOnSurfaceVariant
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    text: "Actual temp"
                }
            }

            Row {
                id: legendFeelsEntry
                Layout.alignment: Qt.AlignVCenter
                spacing: 6

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Rectangle {
                        color: Appearance.colors.colTertiary
                        height: 3
                        radius: 1.5
                        width: 7
                    }

                    Rectangle {
                        color: Appearance.colors.colTertiary
                        height: 3
                        radius: 1.5
                        width: 7
                    }

                    Rectangle {
                        color: Appearance.colors.colTertiary
                        height: 3
                        radius: 1.5
                        width: 7
                    }
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    color: Appearance.colors.colOnSurfaceVariant
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    text: "Feels-like"
                }
            }

            Row {
                id: legendRainEntry
                Layout.alignment: Qt.AlignVCenter
                spacing: 6

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    color: Appearance.colors.colSecondary
                    height: 10
                    radius: 2
                    width: 10
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    color: Appearance.colors.colOnSurfaceVariant
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    text: "Rain chance (darker = heavier)"
                }
            }
        }

        Item {
            id: graphArea
            Layout.fillWidth: true
            Layout.fillHeight: true

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

                    const plotTop = 20;
                    const plotUpperBottom = height * 0.60;
                    const plotLowerTop = height * 0.66;
                    const plotLowerBottom = height - 28;

                    // 1. Nocturnal background shading (D-54.3-24)
                    ctx.save();
                    ctx.fillStyle = Appearance.colors.colLayer1 || "#1e1e2e";
                    ctx.globalAlpha = 0.12;
                    for (let i = 0; i < n; ++i) {
                        if (!hours[i].isDay) {
                            ctx.fillRect(plotLeft + i * slotW, 0, slotW, height);
                        }
                    }
                    ctx.restore();

                    // 2. Midnight 00:00 divider with compact date label (D-54.3-25)
                    for (let i = 0; i < n; ++i) {
                        if (hours[i].isDayBoundary || hours[i].hourNum === 0) {
                            const midX = plotLeft + i * slotW;
                            ctx.save();
                            ctx.strokeStyle = Appearance.colors.colOutlineVariant || "#444";
                            ctx.setLineDash([2, 3]);
                            ctx.beginPath();
                            ctx.moveTo(midX, plotTop);
                            ctx.lineTo(midX, plotLowerBottom);
                            ctx.stroke();

                            ctx.setLineDash([]);
                            ctx.font = "9px sans-serif";
                            ctx.fillStyle = Appearance.colors.colOnSurfaceVariant || "#888";
                            ctx.textAlign = "center";
                            const dateChip = root.formatDateChip(hours[i].dateStr);
                            ctx.fillText(dateChip, midX, plotTop - 4);
                            ctx.restore();
                        }
                    }

                    // 3. Center NOW Hairline & Pill Badge (Slot 12)
                    if (root.isTimeline25) {
                        const nowX = plotLeft + (12 + 0.5) * slotW;
                        ctx.save();
                        ctx.strokeStyle = Appearance.colors.colPrimary || "#4fc3f7";
                        ctx.lineWidth = 1.5;
                        ctx.setLineDash([3, 3]);
                        ctx.beginPath();
                        ctx.moveTo(nowX, plotTop);
                        ctx.lineTo(nowX, plotLowerBottom);
                        ctx.stroke();

                        ctx.setLineDash([]);
                        const badgeW = 32;
                        const badgeH = 14;
                        const badgeX = nowX - badgeW / 2;
                        const badgeY = plotTop - 14;
                        ctx.fillStyle = Appearance.colors.colPrimary || "#4fc3f7";
                        ctx.beginPath();
                        ctx.rect(badgeX, badgeY, badgeW, badgeH);
                        ctx.fill();

                        ctx.fillStyle = Appearance.colors.colOnPrimary || "#000000";
                        ctx.font = "bold 9px sans-serif";
                        ctx.textAlign = "center";
                        ctx.textBaseline = "middle";
                        ctx.fillText("NOW", nowX, badgeY + badgeH / 2);
                        ctx.restore();
                    }

                    // 4. Cold-boot Past Data Hatch Fallback (D-54.3-18)
                    let firstValidIdx = 0;
                    while (firstValidIdx < n && hours[firstValidIdx].isHistoricalUnavailable) {
                        firstValidIdx++;
                    }
                    if (firstValidIdx > 0) {
                        ctx.save();
                        const hatchW = firstValidIdx * slotW;
                        ctx.fillStyle = Appearance.colors.colLayer1 || "#1e1e2e";
                        ctx.globalAlpha = 0.25;
                        ctx.fillRect(plotLeft, plotTop, hatchW, plotUpperBottom - plotTop);

                        ctx.fillStyle = Appearance.colors.colOnSurfaceVariant || "#888";
                        ctx.font = "italic 9px sans-serif";
                        ctx.textAlign = "center";
                        ctx.fillText("Past data unavailable", plotLeft + hatchW / 2, (plotTop + plotUpperBottom) / 2);
                        ctx.restore();
                    }

                    // 5. Upper Tier Splines
                    ctx.save();
                    const primaryPoints = [];
                    const secondaryPoints = [];

                    for (let i = firstValidIdx; i < n; ++i) {
                        const cx = plotLeft + (i + 0.5) * slotW;
                        const cy = root.getMetricY(root.activeMetric, i, plotTop, plotUpperBottom);
                        primaryPoints.push({
                            x: cx,
                            y: cy
                        });

                        if (root.activeMetric === "temp") {
                            const bounds = root.calcTempBounds();
                            const range = Math.max(1, bounds.max - bounds.min);
                            const h = hours[i];
                            let fVal = 20;
                            if (h.thermal && h.thermal.feelsLikeC !== null && h.thermal.feelsLikeC !== undefined) {
                                fVal = Number(h.thermal.feelsLikeC);
                            } else if (h.FeelsLikeC !== undefined && h.FeelsLikeC !== null) {
                                fVal = Number(h.FeelsLikeC);
                            }
                            const fy = plotUpperBottom - ((fVal - bounds.min) / range) * (plotUpperBottom - plotTop);
                            secondaryPoints.push({
                                x: cx,
                                y: fy
                            });
                        } else if (root.activeMetric === "wind") {
                            const maxSpeed = root.calcWindMax();
                            const h = hours[i];
                            let gst = 0;
                            if (h.wind && h.wind.gustKmph !== null && h.wind.gustKmph !== undefined) {
                                gst = Number(h.wind.gustKmph);
                            } else if (h.WindGustKmph !== undefined && h.WindGustKmph !== null) {
                                gst = parseInt(h.WindGustKmph, 10) || 0;
                            }
                            const gy = plotUpperBottom - (Math.max(0, gst) / maxSpeed) * (plotUpperBottom - plotTop);
                            secondaryPoints.push({
                                x: cx,
                                y: gy
                            });
                        }
                    }

                    const primaryCP = root.computeMonotoneSplineControlPoints(primaryPoints);
                    const secondaryCP = (secondaryPoints.length > 1) ? root.computeMonotoneSplineControlPoints(secondaryPoints) : [];

                    // Metric specific background guidelines
                    if (root.activeMetric === "temp") {
                        const bounds = root.calcTempBounds();
                        ctx.save();
                        ctx.strokeStyle = Appearance.colors.colOutlineVariant || "#444";
                        ctx.fillStyle = Appearance.colors.colOnSurfaceVariant || "#888";
                        ctx.font = "9px sans-serif";
                        ctx.setLineDash([2, 3]);

                        const yMax = root.getMetricY("temp", -1, plotTop, plotUpperBottom);
                        const yMin = plotUpperBottom - ((bounds.min - bounds.min) / Math.max(1, bounds.max - bounds.min)) * (plotUpperBottom - plotTop);
                        const yHigh = plotUpperBottom - ((bounds.max - 1 - bounds.min) / Math.max(1, bounds.max - bounds.min)) * (plotUpperBottom - plotTop);
                        const yLow = plotUpperBottom - ((bounds.min + 1 - bounds.min) / Math.max(1, bounds.max - bounds.min)) * (plotUpperBottom - plotTop);

                        ctx.beginPath();
                        ctx.moveTo(plotLeft, yHigh);
                        ctx.lineTo(plotRight, yHigh);
                        ctx.stroke();
                        ctx.fillText(Math.round(bounds.max - 1) + "°", plotLeft - 10, yHigh + 3);

                        ctx.beginPath();
                        ctx.moveTo(plotLeft, yLow);
                        ctx.lineTo(plotRight, yLow);
                        ctx.stroke();
                        ctx.fillText(Math.round(bounds.min + 1) + "°", plotLeft - 10, yLow + 3);
                        ctx.restore();
                    }

                    // Gradient fill under primary curve
                    if (primaryCP.length > 0) {
                        ctx.save();
                        const grad = ctx.createLinearGradient(0, plotTop, 0, plotUpperBottom);
                        const accent = root.getActiveMetricColor();
                        grad.addColorStop(0, accent);
                        grad.addColorStop(1, "transparent");

                        ctx.beginPath();
                        ctx.moveTo(primaryPoints[0].x, plotUpperBottom);
                        ctx.lineTo(primaryPoints[0].x, primaryPoints[0].y);
                        for (let i = 0; i < primaryCP.length; ++i) {
                            ctx.bezierCurveTo(primaryCP[i].cp1x, primaryCP[i].cp1y, primaryCP[i].cp2x, primaryCP[i].cp2y, primaryPoints[i + 1].x, primaryPoints[i + 1].y);
                        }
                        ctx.lineTo(primaryPoints[primaryPoints.length - 1].x, plotUpperBottom);
                        ctx.closePath();
                        ctx.fillStyle = grad;
                        ctx.globalAlpha = 0.22;
                        ctx.fill();
                        ctx.restore();
                    }

                    // Solid primary curve stroke
                    if (primaryCP.length > 0) {
                        ctx.save();
                        ctx.strokeStyle = root.getActiveMetricColor();
                        ctx.lineWidth = 2;
                        ctx.beginPath();
                        ctx.moveTo(primaryPoints[0].x, primaryPoints[0].y);
                        for (let i = 0; i < primaryCP.length; ++i) {
                            ctx.bezierCurveTo(primaryCP[i].cp1x, primaryCP[i].cp1y, primaryCP[i].cp2x, primaryCP[i].cp2y, primaryPoints[i + 1].x, primaryPoints[i + 1].y);
                        }
                        ctx.stroke();
                        ctx.restore();
                    }

                    // Secondary dashed curve (feels-like temp or wind gust)
                    if (secondaryCP.length > 0) {
                        ctx.save();
                        ctx.strokeStyle = Appearance.colors.colTertiary || "#81c784";
                        ctx.setLineDash([3, 3]);
                        ctx.lineWidth = 1.5;
                        ctx.beginPath();
                        ctx.moveTo(secondaryPoints[0].x, secondaryPoints[0].y);
                        for (let i = 0; i < secondaryCP.length; ++i) {
                            ctx.bezierCurveTo(secondaryCP[i].cp1x, secondaryCP[i].cp1y, secondaryCP[i].cp2x, secondaryCP[i].cp2y, secondaryPoints[i + 1].x, secondaryPoints[i + 1].y);
                        }
                        ctx.stroke();
                        ctx.restore();
                    }
                    ctx.restore();

                    // 6. Lower Tier Context Bars (plotLowerTop to plotLowerBottom)
                    const lowerH = plotLowerBottom - plotLowerTop;
                    ctx.save();
                    for (let i = 0; i < n; ++i) {
                        const h = hours[i];
                        const barW = Math.max(2, slotW - 3);
                        const barX = plotLeft + (i + 0.5) * slotW - barW / 2;

                        if (root.activeMetric === "temp" || root.activeMetric === "rain") {
                            let prob = 0;
                            let precipMM = 0.0;
                            if (h.moisture) {
                                prob = h.moisture.rainProb !== undefined ? h.moisture.rainProb : 0;
                                precipMM = h.moisture.precipMM !== undefined ? h.moisture.precipMM : 0.0;
                            } else {
                                prob = parseInt(h.chanceofrain !== undefined ? h.chanceofrain : 0, 10) || 0;
                                precipMM = parseFloat(h.precipMM !== undefined ? h.precipMM : 0);
                            }
                            const barH = (Math.max(0, Math.min(100, prob)) / 100.0) * lowerH;
                            ctx.fillStyle = Appearance.colors.colSecondary || "#81c784";
                            ctx.globalAlpha = (precipMM > 2.5) ? 1.0 : ((prob > 0) ? 0.75 : 0.15);
                            ctx.fillRect(barX, plotLowerBottom - Math.max(1, barH), barW, Math.max(1, barH));
                        }
                    }
                    ctx.restore();

                    // 7. Bottom Axis Band (Condition glyphs + Timestamps)
                    ctx.save();
                    ctx.textAlign = "center";

                    const step = root.isTimeline25 ? 4 : 3;
                    for (let i = 0; i < n; i += step) {
                        const cx = plotLeft + (i + 0.5) * slotW;
                        const h = hours[i];

                        // Condition glyph symbol in 12px
                        ctx.font = "12px sans-serif";
                        ctx.fillStyle = Appearance.colors.colOnSurfaceVariant || "#888";
                        const glyphText = (h && h.glyph) ? h.glyph : "cloud";
                        ctx.fillText(glyphText, cx, height - 14);

                        // Timestamps
                        const isNowSlot = (root.isTimeline25 && i === 12);
                        ctx.font = isNowSlot ? "bold 9px sans-serif" : "9px sans-serif";
                        ctx.fillStyle = isNowSlot ? (Appearance.colors.colPrimary || "#4fc3f7") : (Appearance.colors.colOnSurfaceVariant || "#888");

                        let timeLabel = "";
                        if (root.isTimeline25) {
                            const rel = i - 12;
                            if (rel === 0) {
                                timeLabel = "NOW";
                            } else {
                                const sign = rel > 0 ? "+" : "";
                                timeLabel = sign + rel + "h";
                            }
                        } else {
                            const rawTime = String(h.time !== undefined ? h.time : "0");
                            const hr = rawTime.length > 2 ? rawTime.slice(0, -2) : (rawTime === "0" ? "00" : rawTime);
                            timeLabel = hr.padStart(2, "0") + ":00";
                        }
                        ctx.fillText(timeLabel, cx, height - 2);
                    }

                    if (root.isTimeline25 && (12 % step !== 0)) {
                        const cx12 = plotLeft + (12 + 0.5) * slotW;
                        ctx.font = "bold 9px sans-serif";
                        ctx.fillStyle = Appearance.colors.colPrimary || "#4fc3f7";
                        ctx.fillText("NOW", cx12, height - 2);
                    }
                    ctx.restore();
                }
            }

            Item {
                id: scrubOverlay
                anchors.fill: parent
                visible: scrubMouseArea.containsMouse
                opacity: scrubMouseArea.containsMouse ? 1.0 : 0.0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutQuad
                    }
                }

                Rectangle {
                    id: scrubHairline
                    color: Appearance.colors.colOutlineVariant
                    width: 1
                    height: parent.height - 28
                    x: root.activeScrubX
                    y: 10
                }

                Rectangle {
                    id: snapDot
                    border.color: Appearance.colors.colLayer2
                    border.width: 2
                    color: root.getActiveMetricColor()
                    height: 8
                    radius: 4
                    width: 8
                    x: root.activeScrubX - 4
                    y: root.activeScrubY - 4
                }

                Rectangle {
                    id: tooltipPill
                    border.color: Appearance.colors.colOutlineVariant
                    border.width: 1
                    color: Appearance.m3colors.m3surfaceContainerHigh || Appearance.colors.colLayer1
                    implicitHeight: tooltipRow.implicitHeight + 8
                    implicitWidth: tooltipRow.implicitWidth + 14
                    radius: Appearance.rounding.verysmall
                    x: Math.max(6, Math.min(parent.width - implicitWidth - 6, root.activeScrubX - implicitWidth / 2))
                    y: (root.activeScrubY < 60) ? (root.activeScrubY + 14) : (root.activeScrubY - implicitHeight - 8)

                    RowLayout {
                        id: tooltipRow
                        anchors.centerIn: parent
                        spacing: 5

                        StyledText {
                            color: Appearance.colors.colOnLayer1
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            font.weight: Font.Bold
                            text: root.formatTemporalLabel(root.activeSlotIndex, root.validHours[root.activeSlotIndex])
                        }

                        StyledText {
                            color: Appearance.colors.colOnSurfaceVariant
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            text: "•"
                        }

                        MaterialSymbol {
                            iconSize: 12
                            fill: 0
                            color: Appearance.colors.colOnSurfaceVariant
                            text: (root.validHours[root.activeSlotIndex] && root.validHours[root.activeSlotIndex].glyph) ? root.validHours[root.activeSlotIndex].glyph : "cloud"
                        }

                        StyledText {
                            color: Appearance.colors.colOnSurfaceVariant
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            text: "•"
                        }

                        StyledText {
                            color: root.getActiveMetricColor()
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            font.weight: Font.DemiBold
                            text: root.formatTooltipMetric(root.activeMetric, root.validHours[root.activeSlotIndex])
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

                    const plotTop = 20;
                    const plotUpperBottom = height * 0.60;
                    root.activeScrubY = root.getMetricY(root.activeMetric, idx, plotTop, plotUpperBottom);
                }
            }
        }
    }

    Connections {
        target: Weather

        function onHourlyChanged() {
            if (root.popupActive) {
                graphCanvas.requestPaint();
            }
        }

        function onTimelineChanged() {
            if (root.popupActive) {
                graphCanvas.requestPaint();
            }
        }
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
