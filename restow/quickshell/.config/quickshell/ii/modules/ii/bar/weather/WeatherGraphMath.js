// WeatherGraphMath.js — Phase 54.4 pure graph, size and axis math for the weather popup.
//
// Plain JS resource (same form as the vendor calendar_layout.js): no .pragma, no imports.
// Top level declares ONLY with `var` and `function` so the Node `vm` assert harness
// (scripts/phase54.4-weather-assert.sh) sees every symbol on its sandbox. Block-scoped
// declarations inside functions are fine.
//
// Draw functions take the Context2D as an argument and only call Context2D methods, so the
// harness can drive them with a recording mock (RESEARCH Pattern 7).
//
// All fixed hex colours of Phase 54.4 live in this file and nowhere else (D-54.4-11).

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

var EPS = 0.001;

// Fixed temperature ramp (D-54.4-14, PA-10): blue <=20°C, amber ~28°C, red >=34°C.
// Interpolated smoothly between anchors.
var TEMP_RAMP = [
    { v: 20, color: "#64b5f6" },
    { v: 28, color: "#ffb300" },
    { v: 34, color: "#ef5350" }
];

// Feels-like dashed spline alpha (PA-12, D-54.4-15).
var FEELS_ALPHA = 0.7;

var DASH_DASHED = [4, 3];
var DASH_DOTTED = [2, 3];

// Graph 2 rain-probability tiers (D-54.4-23): <30% light blue, 30-60% blue, >60% deep blue.
var RAIN_EDGES = [30, 60];
var RAIN_COLORS = ["#90caf9", "#42a5f5", "#2979ff"];

var Y_LABEL_FONT = "10px sans-serif";
var LABEL_FONT = "bold 10px sans-serif";

// Minimum popup OUTER width in px (D-54.4-03): keeps each of the three graphs ~280px wide.
var MIN_OUTER_W = 900;

// ---------------------------------------------------------------------------
// Small numeric helpers
// ---------------------------------------------------------------------------

function clamp01(v) {
    var n = Number(v);
    if (!isFinite(n))
        return 0;
    return Math.max(0, Math.min(1, n));
}

// True only for a finite number (null, undefined, NaN, Infinity and strings are rejected).
function isNum(v) {
    return typeof v === "number" && isFinite(v);
}

// User-editable percent from config.json -> 20..100, or dflt for garbage (T-54.4-01).
function sanePercent(v, dflt) {
    var fallback = isNum(dflt) ? dflt : 50;
    if (v === null || v === undefined)
        return fallback;
    var n = Number(v);
    if (!isFinite(n))
        return fallback;
    return Math.max(20, Math.min(100, n));
}

// ---------------------------------------------------------------------------
// Popup size (D-54.4-03, RESEARCH Pattern 5)
// ---------------------------------------------------------------------------

// Returns the popup CONTENT size {width, height} (integers) for a screen and two percents.
// opts: chrome (popup chrome around content, default 40), edgeGap (default 5),
//       barHeight (default 40), minOuterW (default 900), minContentH (default 0).
function popupContentSize(screenW, screenH, wPct, hPct, opts) {
    var o = opts || {};
    var chrome = isNum(o.chrome) ? o.chrome : 40;
    var edgeGap = isNum(o.edgeGap) ? o.edgeGap : 5;
    var barHeight = isNum(o.barHeight) ? o.barHeight : 40;
    var minOuterW = isNum(o.minOuterW) ? o.minOuterW : MIN_OUTER_W;
    var minContentH = isNum(o.minContentH) ? o.minContentH : 0;

    var sw = (isNum(screenW) && screenW > 0) ? screenW : 1920;
    var sh = (isNum(screenH) && screenH > 0) ? screenH : 1080;

    var maxW = sw - 2 * edgeGap - chrome;
    var maxH = sh - barHeight - 2 * edgeGap - chrome;

    var width = Math.min(maxW, Math.max(minOuterW - chrome, sw * sanePercent(wPct, 50) / 100 - chrome));
    var height = Math.min(maxH, Math.max(minContentH, sh * sanePercent(hPct, 50) / 100 - chrome));

    return {
        width: Math.max(0, Math.round(width)),
        height: Math.max(0, Math.round(height))
    };
}

// ---------------------------------------------------------------------------
// Slots
// ---------------------------------------------------------------------------

function _int(v) {
    var n = parseInt(v, 10);
    return isNaN(n) ? 0 : n;
}

function _float(v) {
    var n = parseFloat(v);
    return isNaN(n) ? 0.0 : n;
}

function _rawHour(time) {
    var t = parseInt(String(time), 10);
    if (isNaN(t))
        return 0;
    return Math.floor(t / 100) % 24;
}

// Maps one raw WWO hourly item (the Weather.hourly fallback) into the timeline slot shape,
// using the same parse rules as the future-slot branch of Weather.qml rebuildTimeline().
function normalizeRawHour(raw, i) {
    var r = raw || {};
    var aq = r.air_quality || {};
    var hr = _rawHour(r.time);
    var t = parseInt(r.tempC, 10);
    var f = parseInt(r.FeelsLikeC, 10);
    var desc = "";
    if (r.weatherDesc && r.weatherDesc[0] && r.weatherDesc[0].value !== undefined)
        desc = String(r.weatherDesc[0].value);

    return {
        index: i,
        isPast: false,
        isNow: false,
        isFuture: true,
        isHistoricalUnavailable: false,
        hourNum: hr,
        isDay: hr >= 6 && hr < 18,
        isDayBoundary: hr === 0,
        glyph: "",
        desc: desc,
        dateStr: "",
        time: r.time,
        timeLabel: clock12(hr),
        thermal: {
            tempC: !isNaN(t) ? t : 0,
            feelsLikeC: !isNaN(f) ? f : 0,
            dewPointC: _int(r.DewPointC),
            heatIndexC: _int(r.HeatIndexC),
            windChillC: _int(r.WindChillC)
        },
        moisture: {
            precipMM: _float(r.precipMM),
            rainProb: _int(r.chanceofrain),
            humidity: _int(r.humidity),
            cloudCover: _int(r.cloudcover),
            snowProb: _int(r.chanceofsnow),
            thunderProb: _int(r.chanceofthunder)
        },
        wind: {
            speedKmph: _int(r.windspeedKmph),
            gustKmph: _int(r.WindGustKmph),
            degree: _int(r.winddirDegree),
            dir16: r.winddir16Point || "N"
        },
        aqi: {
            epaIndex: _int(aq["us-epa-index"]),
            pm2_5: _float(aq.pm2_5),
            pm10: _float(aq.pm10),
            co: _float(aq.co),
            no2: _float(aq.no2),
            o3: _float(aq.o3),
            so2: _float(aq.so2),
            defraIndex: _int(aq["gb-defra-index"])
        },
        atmosphere: {
            pressureHpa: _int(r.pressure),
            visibilityKm: _int(r.visibility)
        },
        solar: {
            uvIndex: _int(r.uvIndex),
            shortRad: _float(r.shortrad),
            diffRad: _float(r.diffrad)
        }
    };
}

// Timeline slots (entries carry a `thermal` group) are returned as a copy. Anything else is
// treated as raw WWO hourly items: "24" dropped, capped at 24, normalised per item.
function normalizeSlots(model) {
    if (!model || typeof model.length !== "number")
        return [];
    var arr = [];
    var hasThermal = false;
    for (var i = 0; i < model.length; ++i) {
        var e = model[i];
        arr.push(e);
        if (e && typeof e === "object" && e.thermal)
            hasThermal = true;
    }
    if (hasThermal)
        return arr;

    var out = [];
    for (var j = 0; j < arr.length && out.length < 24; ++j) {
        var raw = arr[j];
        if (!raw || typeof raw !== "object")
            continue;
        if (String(raw.time) === "24")
            continue;
        out.push(normalizeRawHour(raw, out.length));
    }
    return out;
}

function isAvailable(slot) {
    return !!slot && typeof slot === "object" && !slot.isHistoricalUnavailable;
}

function slotHour(slot) {
    if (!slot || typeof slot !== "object")
        return 0;
    if (isNum(slot.hourNum))
        return slot.hourNum;
    return _rawHour(slot.time);
}

// ---------------------------------------------------------------------------
// X axis (D-54.4-06)
// ---------------------------------------------------------------------------

// 0 -> "12AM", 12 -> "12PM", 13 -> "1PM", 23 -> "11PM". Never "0AM" (Pitfall 8).
function clock12(h) {
    var n = Number(h);
    if (!isFinite(n))
        return "";
    var hr = ((Math.floor(n) % 24) + 24) % 24;
    var suffix = hr < 12 ? "AM" : "PM";
    var k = hr % 12 === 0 ? 12 : hr % 12;
    return k + suffix;
}

function axisTicks(n, stride) {
    var count = isNum(n) ? Math.floor(n) : 0;
    var s = isNum(stride) && stride >= 1 ? Math.floor(stride) : 1;
    var ticks = [];
    for (var i = 0; i < count; i += s)
        ticks.push(i);
    return ticks;
}

// "Now" at the timeline centre, otherwise a 12-hour clock label. Never a relative +4h tag.
function axisTickLabel(i, slot, isTimeline25) {
    if (isTimeline25 && i === 12)
        return "Now";
    if (!slot || typeof slot !== "object")
        return "";
    return clock12(slotHour(slot));
}

// ---------------------------------------------------------------------------
// Geometry and scales
// ---------------------------------------------------------------------------

function slotCenterX(geom, i) {
    return geom.plotLeft + (i + 0.5) * geom.slotW;
}

// Linear map with hi -> top and lo -> bottom. A flat scale (hi === lo) draws at the bottom for a
// zero-anchored scale and at the vertical centre otherwise (Pitfall 7).
function valueToY(v, lo, hi, top, bottom) {
    if (hi === lo)
        return lo === 0 ? bottom : (top + bottom) / 2;
    return bottom - (v - lo) / (hi - lo) * (bottom - top);
}

// Integer temperature scale over available slots; historical-unavailable slots never enter.
function tempScale(slots) {
    var lo = Infinity;
    var hi = -Infinity;
    var list = (slots && typeof slots.length === "number") ? slots : [];
    for (var i = 0; i < list.length; ++i) {
        var s = list[i];
        if (!isAvailable(s) || !s.thermal)
            continue;
        var vals = [s.thermal.tempC, s.thermal.feelsLikeC];
        for (var k = 0; k < vals.length; ++k) {
            if (isNum(vals[k])) {
                if (vals[k] < lo)
                    lo = vals[k];
                if (vals[k] > hi)
                    hi = vals[k];
            }
        }
    }
    if (lo === Infinity)
        return { min: 0, max: 1, empty: true };
    var min = Math.floor(lo);
    var max = Math.ceil(hi);
    if (max === min)
        max = min + 1;
    return { min: min, max: max, empty: false };
}

// Scales computed once per timeline change. Plan 07 owns the airuv branch.
function computeScales(kind, slots) {
    if (kind === "temp")
        return { temp: tempScale(slots) };
    if (kind === "rainwind")
        return { rain: { min: 0, max: 100 } };
    return {};
}

// ---------------------------------------------------------------------------
// Colour and gradient helpers (D-54.4-14, Pitfall 1)
// ---------------------------------------------------------------------------

function _parseHex(hex) {
    var h = String(hex || "").replace("#", "");
    if (h.length === 3)
        h = h.charAt(0) + h.charAt(0) + h.charAt(1) + h.charAt(1) + h.charAt(2) + h.charAt(2);
    var n = parseInt(h.substring(0, 6), 16);
    if (isNaN(n))
        return [0, 0, 0];
    return [(n >> 16) & 255, (n >> 8) & 255, n & 255];
}

function _hex2(n) {
    var s = Math.max(0, Math.min(255, Math.round(n))).toString(16);
    return s.length < 2 ? "0" + s : s;
}

function lerpColor(a, b, t) {
    var ca = _parseHex(a);
    var cb = _parseHex(b);
    var k = clamp01(t);
    return "#" + _hex2(ca[0] + (cb[0] - ca[0]) * k) + _hex2(ca[1] + (cb[1] - ca[1]) * k) + _hex2(ca[2] + (cb[2] - ca[2]) * k);
}

// Colour of a smooth ramp at value v; v is clamped to the end anchors.
function rampColorAt(anchors, v) {
    if (!anchors || anchors.length === 0)
        return "#000000";
    var first = anchors[0];
    var last = anchors[anchors.length - 1];
    if (!isNum(v) || v <= first.v)
        return isNum(v) ? first.color : last.color;
    if (v >= last.v)
        return last.color;
    for (var i = 0; i < anchors.length - 1; ++i) {
        var a = anchors[i];
        var b = anchors[i + 1];
        if (v >= a.v && v <= b.v)
            return lerpColor(a.color, b.color, b.v === a.v ? 0 : (v - a.v) / (b.v - a.v));
    }
    return last.color;
}

// Value -> gradient offset for a vertical gradient from plotTop (offset 0 = vTop) to plotBottom
// (offset 1 = vBottom).
function valueOffset(v, vTop, vBottom) {
    if (vTop === vBottom)
        return 0.5;
    return (vTop - v) / (vTop - vBottom);
}

// Smooth-ramp gradient stops. Endpoint stops at 0 and 1 carry the interpolated colour at vTop and
// vBottom; interior anchors are kept only strictly inside (0,1). Every offset is clamped and the
// result is sorted non-decreasing, because an out-of-range addColorStop throws and blanks the
// whole paint (Pitfall 1, T-54.4-02).
function smoothRampStops(anchors, vTop, vBottom) {
    var stops = [{ offset: 0, color: rampColorAt(anchors, vTop) }];
    if (anchors && vTop !== vBottom) {
        for (var i = 0; i < anchors.length; ++i) {
            var off = valueOffset(anchors[i].v, vTop, vBottom);
            if (isNum(off) && off > 0 && off < 1)
                stops.push({ offset: clamp01(off), color: anchors[i].color });
        }
    }
    stops.push({ offset: 1, color: rampColorAt(anchors, vBottom) });
    stops.sort(function (a, b) {
        return a.offset - b.offset;
    });
    return stops;
}

// Rain probability -> tier colour (D-54.4-23): below 30, 30..60 inclusive, above 60.
function rainColor(v) {
    if (!isNum(v) || v < RAIN_EDGES[0])
        return RAIN_COLORS[0];
    if (v <= RAIN_EDGES[1])
        return RAIN_COLORS[1];
    return RAIN_COLORS[2];
}

// Hard-edged tier gradient stops (PA-10). A start stop at 0 with colorAt(vTop); for each edge
// strictly between vBottom and vTop, in ascending offset order, a stop at the edge offset with the
// colour on the vTop side and a second stop EPS further with the colour on the vBottom side (equal
// offsets would replace each other, Pitfall 2); an end stop at 1 with colorAt(vBottom). Offsets
// are clamped to [0,1] and forced non-decreasing, so addColorStop never throws (Pitfall 1).
function tierStops(edges, colorAt, vTop, vBottom) {
    var stops = [{ offset: 0, color: colorAt(vTop) }];
    if (edges && isNum(vTop) && isNum(vBottom) && vTop !== vBottom) {
        var lo = Math.min(vTop, vBottom);
        var hi = Math.max(vTop, vBottom);
        var toward = vTop > vBottom ? 1e-6 : -1e-6;
        var inner = [];
        for (var i = 0; i < edges.length; ++i) {
            var e = edges[i];
            if (isNum(e) && e > lo && e < hi)
                inner.push({ v: e, offset: valueOffset(e, vTop, vBottom) });
        }
        inner.sort(function (a, b) {
            return a.offset - b.offset;
        });
        for (var k = 0; k < inner.length; ++k) {
            var off = clamp01(inner[k].offset);
            stops.push({ offset: off, color: colorAt(inner[k].v + toward) });
            stops.push({ offset: Math.min(1, off + EPS), color: colorAt(inner[k].v - toward) });
        }
    }
    stops.push({ offset: 1, color: colorAt(vBottom) });
    var prev = 0;
    for (var j = 0; j < stops.length; ++j) {
        var o = Math.max(prev, clamp01(stops[j].offset));
        stops[j].offset = o;
        prev = o;
    }
    return stops;
}

// Vertical gradient from plotTop to plotBottom carrying the given stops.
function _verticalGradient(ctx, geom, stops) {
    var grad = ctx.createLinearGradient(0, geom.plotTop, 0, geom.plotBottom);
    for (var i = 0; i < stops.length; ++i)
        grad.addColorStop(clamp01(stops[i].offset), stops[i].color);
    return grad;
}

// ---------------------------------------------------------------------------
// Spline (D-54.4-13) — moved verbatim from the Phase 54.3 WeatherGraph.qml
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Series runs and stroking
// ---------------------------------------------------------------------------

// Consecutive available slots with finite values, mapped to {x, y, i} points. An unavailable slot
// or a missing value breaks the run, so no spline segment ever spans those columns (Pitfall 5).
function seriesRuns(slots, getter, geom, scale) {
    var runs = [];
    var cur = null;
    var list = (slots && typeof slots.length === "number") ? slots : [];
    for (var i = 0; i < list.length; ++i) {
        var s = list[i];
        var v = isAvailable(s) ? getter(s) : null;
        if (isNum(v)) {
            if (!cur) {
                cur = [];
                runs.push(cur);
            }
            cur.push({
                x: slotCenterX(geom, i),
                y: valueToY(v, scale.min, scale.max, geom.plotTop, geom.plotBottom),
                i: i
            });
        } else {
            cur = null;
        }
    }
    return runs;
}

// moveTo plus one bezierCurveTo per segment; runs shorter than 2 points are skipped.
function strokeRuns(ctx, runs) {
    for (var r = 0; r < runs.length; ++r) {
        var run = runs[r];
        if (!run || run.length < 2)
            continue;
        var cps = computeMonotoneSplineControlPoints(run);
        ctx.beginPath();
        ctx.moveTo(run[0].x, run[0].y);
        for (var k = 0; k < cps.length; ++k)
            ctx.bezierCurveTo(cps[k].cp1x, cps[k].cp1y, cps[k].cp2x, cps[k].cp2y, run[k + 1].x, run[k + 1].y);
        ctx.stroke();
    }
}

function _hasStrokableRun(runs) {
    for (var i = 0; i < runs.length; ++i) {
        if (runs[i] && runs[i].length >= 2)
            return true;
    }
    return false;
}

function _tempOf(s) {
    return s.thermal ? s.thermal.tempC : undefined;
}

function _feelsOf(s) {
    return s.thermal ? s.thermal.feelsLikeC : undefined;
}

// ---------------------------------------------------------------------------
// Draw: temperature card (D-54.4-13/14/15/17)
// ---------------------------------------------------------------------------

// Temperature: smooth monotone spline stroked with the fixed ramp gradient (lineWidth 2).
// Feels-like: dashed spline, same gradient at FEELS_ALPHA (lineWidth 1.5). No band, no fill and
// no rain drawing.
function drawTemp(ctx, geom, slots, scales) {
    if (!ctx || !geom || !slots || typeof slots.length !== "number" || slots.length < 2)
        return;
    var scale = (scales && scales.temp) ? scales.temp : tempScale(slots);
    if (!scale || scale.empty)
        return;

    var tempRuns = seriesRuns(slots, _tempOf, geom, scale);
    var feelsRuns = seriesRuns(slots, _feelsOf, geom, scale);
    if (!_hasStrokableRun(tempRuns) && !_hasStrokableRun(feelsRuns))
        return;

    var grad = ctx.createLinearGradient(0, geom.plotTop, 0, geom.plotBottom);
    var stops = smoothRampStops(TEMP_RAMP, scale.max, scale.min);
    for (var i = 0; i < stops.length; ++i)
        grad.addColorStop(clamp01(stops[i].offset), stops[i].color);

    ctx.save();
    ctx.strokeStyle = grad;
    ctx.lineWidth = 2;
    ctx.lineJoin = "round";
    ctx.lineCap = "round";
    ctx.setLineDash([]);
    strokeRuns(ctx, tempRuns);
    ctx.restore();

    ctx.save();
    ctx.strokeStyle = grad;
    ctx.globalAlpha = FEELS_ALPHA;
    ctx.setLineDash(DASH_DASHED.slice());
    ctx.lineWidth = 1.5;
    ctx.lineJoin = "round";
    strokeRuns(ctx, feelsRuns);
    ctx.restore();
}

// ---------------------------------------------------------------------------
// Draw: rain, wind and visibility card (D-54.4-21..24)
// ---------------------------------------------------------------------------

function _rainOf(s) {
    return s.moisture ? s.moisture.rainProb : undefined;
}

// Graph 2 scales, falling back to computeScales for any piece the caller did not pass.
function _rainwindScales(slots, scales) {
    var sc = scales || {};
    var full = computeScales("rainwind", slots);
    return {
        rain: sc.rain ? sc.rain : full.rain
    };
}

// Rain probability: monotone spline on its own 0..100 scale (D-54.4-22), stroked with the hard
// RAIN tier gradient (D-54.4-23), lineWidth 2, solid. No y-axis labels or units.
function drawRainWind(ctx, geom, slots, scales) {
    if (!ctx || !geom || !slots || typeof slots.length !== "number" || slots.length < 1)
        return;
    var sc = _rainwindScales(slots, scales);

    var rainRuns = seriesRuns(slots, _rainOf, geom, sc.rain);
    if (_hasStrokableRun(rainRuns)) {
        ctx.save();
        ctx.strokeStyle = _verticalGradient(ctx, geom, tierStops(RAIN_EDGES, rainColor, sc.rain.max, sc.rain.min));
        ctx.lineWidth = 2;
        ctx.lineJoin = "round";
        ctx.lineCap = "round";
        ctx.setLineDash([]);
        strokeRuns(ctx, rainRuns);
        ctx.restore();
    }
}

// ---------------------------------------------------------------------------
// Legend (D-54.4-09/18)
// ---------------------------------------------------------------------------

function _rampColors(anchors) {
    var out = [];
    for (var i = 0; i < anchors.length; ++i)
        out.push(anchors[i].color);
    return out;
}

// Legend entries for one card, drawn by the WeatherGraph.qml legend row: an array of
// {label, style, color, colors, dot}. style is one of "solid", "dashed", "dotted", "bar" or
// "ribbon"; color is the label colour; colors (optional) are the swatch parts in order; dot adds a
// colour dot before the swatch. Plans 06 and 07 add the "rainwind" and "airuv" entries.
function legendEntries(kind) {
    if (kind === "temp") {
        return [
            { label: "Temp", style: "solid", color: "#ffb300", colors: _rampColors(TEMP_RAMP), dot: false },
            { label: "Feels", style: "dashed", color: "#ffb300", colors: _rampColors(TEMP_RAMP), dot: false }
        ];
    }
    if (kind === "rainwind") {
        // D-54.4-25 short names with a colour dot, then the D-54.4-09 line-style swatch (PA-15).
        return [
            { label: "Rain%", style: "solid", color: RAIN_COLORS[1], colors: RAIN_COLORS.slice(), dot: true }
        ];
    }
    return [];
}

// ---------------------------------------------------------------------------
// Card furniture: temperature y axis (D-54.4-05/16) and the shared backdrop (PA-4)
// ---------------------------------------------------------------------------

// Neutral stand-ins used only when a caller passes no theme (QML always passes theme()).
var THEME_FALLBACK = { grid: "#5f6368", text: "#c4c7c5", shade: "#000000", now: "#a8c7fa" };

function _theme(theme) {
    var t = theme || {};
    return {
        grid: t.grid !== undefined && t.grid !== null ? t.grid : THEME_FALLBACK.grid,
        text: t.text !== undefined && t.text !== null ? t.text : THEME_FALLBACK.text,
        shade: t.shade !== undefined && t.shade !== null ? t.shade : THEME_FALLBACK.shade,
        now: t.now !== undefined && t.now !== null ? t.now : THEME_FALLBACK.now
    };
}

// Gridline every 1 degree; labels every 1 degree when rows are at least 12px apart, otherwise
// every 2 degrees (D-54.4-16).
function tempGridPlan(scale, plotH) {
    if (!scale || !isNum(scale.min) || !isNum(scale.max) || scale.max <= scale.min || !isNum(plotH))
        return { step: 1, labelStep: 1 };
    var rowPx = plotH / (scale.max - scale.min);
    return { step: 1, labelStep: rowPx >= 12 ? 1 : 2 };
}

// Horizontal gridline per integer degree and right-aligned "<v>°" labels in the left gutter.
// The gutter is sized from the "-88°" text width plus 6 (plan 01), so labels fit (D-54.4-05).
// The loop is bounded by the integer scale range from tempScale (T-54.4-13).
function drawTempAxis(ctx, geom, scale, theme) {
    if (!ctx || !geom || !scale || scale.empty || !isNum(scale.min) || !isNum(scale.max) || scale.max < scale.min)
        return;
    var th = _theme(theme);
    var lo = Math.ceil(scale.min);
    var hi = Math.floor(scale.max);
    var plan = tempGridPlan(scale, geom.plotBottom - geom.plotTop);

    ctx.save();
    ctx.strokeStyle = th.grid;
    ctx.globalAlpha = 0.35;
    ctx.lineWidth = 1;
    ctx.setLineDash([]);
    for (var v = lo; v <= hi; v += plan.step) {
        var y = valueToY(v, scale.min, scale.max, geom.plotTop, geom.plotBottom);
        ctx.beginPath();
        ctx.moveTo(geom.plotLeft, y);
        ctx.lineTo(geom.plotRight, y);
        ctx.stroke();
    }

    ctx.globalAlpha = 1;
    ctx.font = Y_LABEL_FONT;
    ctx.fillStyle = th.text;
    ctx.textAlign = "right";
    ctx.textBaseline = "middle";
    for (var w = lo; w <= hi; w += plan.step) {
        if ((w - scale.min) % plan.labelStep !== 0)
            continue;
        ctx.fillText(w + "°", geom.plotLeft - 4, valueToY(w, scale.min, scale.max, geom.plotTop, geom.plotBottom));
    }
    ctx.restore();
}

// Shared backdrop for every card (PA-4): night shading, dotted midnight divider, dashed Now
// hairline and the past-data hatch. No NOW badge and no date chip.
function drawBackdrop(ctx, geom, slots, theme) {
    if (!ctx || !geom || !slots || typeof slots.length !== "number")
        return;
    var th = _theme(theme);
    var n = slots.length;
    var top = geom.plotTop;
    var bottom = geom.plotBottom;
    var h = Math.max(0, bottom - top);

    ctx.save();

    // Night shading
    ctx.fillStyle = th.shade;
    ctx.globalAlpha = 0.12;
    for (var i = 0; i < n; ++i) {
        var s = slots[i];
        if (s && typeof s === "object" && s.isDay === false)
            ctx.fillRect(geom.plotLeft + i * geom.slotW, top, geom.slotW, h);
    }
    ctx.globalAlpha = 1;

    // Midnight divider
    ctx.strokeStyle = th.grid;
    ctx.lineWidth = 1;
    ctx.setLineDash(DASH_DOTTED.slice());
    for (var j = 1; j < n; ++j) {
        var m = slots[j];
        if (m && typeof m === "object" && (m.isDayBoundary === true || m.hourNum === 0)) {
            var mx = geom.plotLeft + j * geom.slotW;
            ctx.beginPath();
            ctx.moveTo(mx, top);
            ctx.lineTo(mx, bottom);
            ctx.stroke();
        }
    }

    // Now hairline at the centre slot of the 25-slot timeline
    if (geom.isTimeline25 && n > 12) {
        var nx = slotCenterX(geom, 12);
        ctx.strokeStyle = th.now;
        ctx.lineWidth = 1;
        ctx.setLineDash([3, 3]);
        ctx.beginPath();
        ctx.moveTo(nx, top);
        ctx.lineTo(nx, bottom);
        ctx.stroke();
    }
    ctx.setLineDash([]);

    // Past-data hatch over the leading run of unavailable slots
    var run = 0;
    while (run < n && !isAvailable(slots[run]))
        ++run;
    if (run > 0) {
        var hatchW = run * geom.slotW;
        ctx.fillStyle = th.shade;
        ctx.globalAlpha = 0.25;
        ctx.fillRect(geom.plotLeft, top, hatchW, h);
        ctx.globalAlpha = 1;
        ctx.font = "italic 9px sans-serif";
        var tw = ctx.measureText("No data").width;
        if (isNum(tw) && hatchW >= tw + 4) {
            ctx.fillStyle = th.text;
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";
            ctx.fillText("No data", geom.plotLeft + hatchW / 2, (top + bottom) / 2);
        }
    }

    ctx.restore();
}

// ---------------------------------------------------------------------------
// Peak labels (D-54.4-10, RESEARCH Pattern 6)
// ---------------------------------------------------------------------------

var LABEL_GAP = 3;

// Strict overlap of two {x, y, w, h} rects; rects that only touch at an edge do not intersect.
function rectsIntersect(a, b) {
    return a.x < b.x + b.w && b.x < a.x + a.w && a.y < b.y + b.h && b.y < a.y + a.h;
}

function _rectInside(r, b) {
    return r.x >= b.left && r.x + r.w <= b.right && r.y >= b.top && r.y + r.h <= b.bottom;
}

// Top-left corners to try for one candidate, in order (Planner Assumptions, plan 05).
function _labelOffsets(c) {
    var g = LABEL_GAP;
    var above = c.y - c.h - g;
    var below = c.y + g;
    var centre = c.x - c.w / 2;
    var left = c.x - c.w - g;
    var right = c.x + g;
    if (c.anchor === "below")
        return [[centre, below], [left, below], [right, below], [centre, above]];
    return [[centre, above], [left, above], [right, above], [centre, below]];
}

// Greedy placement. Candidates {text, x, y, w, h, priority, rank, color, anchor} are sorted
// stably by priority ascending (0 first), then rank descending. Each takes the first offset whose
// rect lies inside bounds {left, right, top, bottom} and intersects neither an accepted label nor
// a reserved rect; a candidate with no such offset is dropped, never drawn overlapping. Returns
// [{text, x, y, w, h, color}] with x, y the top-left corner. Bounded work: four offsets per
// candidate, no retry loop (T-54.4-13).
function placeLabels(cands, bounds, reserved) {
    if (!cands || typeof cands.length !== "number" || !bounds)
        return [];
    var res = (reserved && typeof reserved.length === "number") ? reserved : [];
    var list = [];
    for (var i = 0; i < cands.length; ++i) {
        var c = cands[i];
        if (!c || typeof c !== "object" || !isNum(c.x) || !isNum(c.y) || !isNum(c.w) || !isNum(c.h) || c.w < 0 || c.h < 0)
            continue;
        list.push({ c: c, order: i });
    }
    list.sort(function (a, b) {
        var pa = isNum(a.c.priority) ? a.c.priority : 0;
        var pb = isNum(b.c.priority) ? b.c.priority : 0;
        if (pa !== pb)
            return pa - pb;
        var ra = isNum(a.c.rank) ? a.c.rank : 0;
        var rb = isNum(b.c.rank) ? b.c.rank : 0;
        if (ra !== rb)
            return rb - ra;
        return a.order - b.order;
    });

    var placed = [];
    for (var k = 0; k < list.length; ++k) {
        var cand = list[k].c;
        var offs = _labelOffsets(cand);
        for (var o = 0; o < offs.length; ++o) {
            var r = { text: cand.text, x: offs[o][0], y: offs[o][1], w: cand.w, h: cand.h, color: cand.color };
            if (!_rectInside(r, bounds))
                continue;
            var clear = true;
            for (var p = 0; clear && p < placed.length; ++p) {
                if (rectsIntersect(r, placed[p]))
                    clear = false;
            }
            for (var q = 0; clear && q < res.length; ++q) {
                if (res[q] && rectsIntersect(r, res[q]))
                    clear = false;
            }
            if (clear) {
                placed.push(r);
                break;
            }
        }
    }
    return placed;
}

// First available slot holding the maximum finite value of getter, or null.
function _peakOf(slots, getter) {
    var best = null;
    for (var i = 0; i < slots.length; ++i) {
        var s = slots[i];
        if (!isAvailable(s))
            continue;
        var v = getter(s);
        if (isNum(v) && (best === null || v > best.v))
            best = { v: v, i: i };
    }
    return best;
}

// Peak-label candidates for one card. Historical-unavailable slots never yield one (T-54.4-14).
// Plans 06 and 07 add the "rainwind" and "airuv" candidates here.
function peakCandidates(kind, ctx, geom, slots, scales) {
    if (!ctx || !geom || !slots || typeof slots.length !== "number")
        return [];
    var out = [];
    if (kind === "temp") {
        var scale = (scales && scales.temp) ? scales.temp : tempScale(slots);
        if (!scale || scale.empty)
            return [];
        var series = [_tempOf, _feelsOf];
        ctx.save();
        ctx.font = LABEL_FONT;
        for (var k = 0; k < series.length; ++k) {
            var pk = _peakOf(slots, series[k]);
            if (!pk)
                continue;
            var text = Math.round(pk.v) + "°";
            out.push({
                text: text,
                x: slotCenterX(geom, pk.i),
                y: valueToY(pk.v, scale.min, scale.max, geom.plotTop, geom.plotBottom),
                w: ctx.measureText(text).width,
                h: 10,
                priority: k,
                rank: pk.v,
                color: rampColorAt(TEMP_RAMP, pk.v),
                anchor: "above"
            });
        }
        ctx.restore();
    }
    if (kind === "rainwind") {
        var rsc = _rainwindScales(slots, scales);
        ctx.save();
        ctx.font = LABEL_FONT;
        // A series whose max is 0 or less peaks nowhere, so it gets no label.
        var rpk = _peakOf(slots, _rainOf);
        if (rpk && rpk.v > 0) {
            var rtext = Math.round(rpk.v) + "%";
            out.push({
                text: rtext,
                x: slotCenterX(geom, rpk.i),
                y: valueToY(rpk.v, rsc.rain.min, rsc.rain.max, geom.plotTop, geom.plotBottom),
                w: ctx.measureText(rtext).width,
                h: 10,
                priority: 2,
                rank: rpk.v,
                color: rainColor(rpk.v),
                anchor: "above"
            });
        }
        ctx.restore();
    }
    return out;
}

// Draws placed labels at full opacity: text is never drawn at a bar alpha (Pitfall 11).
function drawLabels(ctx, placed) {
    if (!ctx || !placed || typeof placed.length !== "number")
        return;
    ctx.save();
    ctx.globalAlpha = 1;
    ctx.font = LABEL_FONT;
    ctx.textBaseline = "top";
    ctx.textAlign = "left";
    for (var i = 0; i < placed.length; ++i) {
        var p = placed[i];
        if (!p)
            continue;
        ctx.fillStyle = p.color;
        ctx.fillText(p.text, p.x, p.y);
    }
    ctx.restore();
}

// Per-kind dispatch: the shared backdrop first, then the per-kind furniture and series, then the
// collision-free peak labels. Plans 06 and 07 add the "rainwind" and "airuv" branches.
function drawKind(ctx, kind, geom, slots, scales, theme) {
    drawBackdrop(ctx, geom, slots, theme);
    if (kind === "temp") {
        var scale = (scales && scales.temp) ? scales.temp : tempScale(slots);
        drawTempAxis(ctx, geom, scale, theme);
        drawTemp(ctx, geom, slots, scales);
    }
    if (kind === "rainwind")
        drawRainWind(ctx, geom, slots, scales);
    if (!geom || !slots || typeof slots.length !== "number")
        return;
    drawLabels(ctx, placeLabels(peakCandidates(kind, ctx, geom, slots, scales), {
        left: geom.plotLeft,
        right: geom.plotRight,
        top: 0,
        bottom: geom.plotBottom
    }, []));
}

// ---------------------------------------------------------------------------
// Hover: comfort word, tooltip lines and marker points (D-54.4-07/12/19/20)
// ---------------------------------------------------------------------------

// Dew point -> comfort word (D-54.4-20): <16 Comfortable, 16-20 Humid, 21-23 Muggy, >=24 Oppressive.
// Non-finite input gives "" so the caller can drop the segment.
function comfortWord(dew) {
    if (!isNum(dew))
        return "";
    if (dew < 16)
        return "Comfortable";
    if (dew <= 20)
        return "Humid";
    if (dew <= 23)
        return "Muggy";
    return "Oppressive";
}

// The 25-slot timeline with "Now" at the centre index.
function isTimeline25(slots) {
    return !!slots && slots.length === 25 && !!slots[12] && slots[12].isNow === true;
}

// Joins the non-empty parts with " · ".
function _joinDot(parts) {
    var out = [];
    for (var i = 0; i < parts.length; ++i) {
        if (parts[i] !== null && parts[i] !== undefined && String(parts[i]).length > 0)
            out.push(String(parts[i]));
    }
    return out.join(" · ");
}

// Tooltip lines for one graph at slot i: an array of {lead, icon, text}. The popup renders each
// line as "<lead> · <icon> <text>". Plain strings only; the QML side renders them as PlainText.
// Plans 06 and 07 append the "rainwind" and "airuv" lines here.
function tooltipLines(kind, slots, i) {
    if (!slots || typeof slots.length !== "number" || !isNum(i) || i < 0 || i >= slots.length)
        return [];
    var slot = slots[i];
    if (!slot || typeof slot !== "object")
        return [];
    var lead = axisTickLabel(i, slot, isTimeline25(slots));
    if (!isAvailable(slot))
        return [{ lead: lead, icon: "", text: "No data" }];

    var header = {
        lead: lead,
        icon: slot.glyph ? String(slot.glyph) : "",
        text: slot.desc ? String(slot.desc) : ""
    };
    var lines = [header];

    // PA-1 option: l1-suffix (user-approved at 54.4-03 Task 2)
    if (kind === "temp") {
        // Locked D-54.4-19 lines: "<time> · <icon> <desc> · <comfort>" and
        // "<thermostat> <temp>° (<feels>°) · Dew <dew>°". POPUP-03 humidity rides on line 1
        // after the comfort word ("· 70% RH"); a non-finite humidity adds nothing.
        var th = slot.thermal || {};
        var hum = slot.moisture ? slot.moisture.humidity : null;
        header.text = _joinDot([header.text, comfortWord(th.dewPointC), isNum(hum) ? Math.round(hum) + "% RH" : ""]);
        if (isNum(th.tempC)) {
            var l2 = Math.round(th.tempC) + "°";
            if (isNum(th.feelsLikeC))
                l2 += " (" + Math.round(th.feelsLikeC) + "°)";
            if (isNum(th.dewPointC))
                l2 += " · Dew " + Math.round(th.dewPointC) + "°";
            lines.push({ lead: "", icon: "thermostat", text: l2 });
        }
    }
    if (kind === "rainwind") {
        // D-54.4-26 amended by D-54.4-36: line 1 always ends with cloud cover; line 2 is
        // "<rain>% · <mm> mm", then Thunder and Snow only when above 0, in that order.
        var mo = slot.moisture || {};
        header.text = _joinDot([header.text, isNum(mo.cloudCover) ? "Cloud " + Math.round(mo.cloudCover) + "%" : ""]);
        var rl2 = _joinDot([
            isNum(mo.rainProb) ? Math.round(mo.rainProb) + "%" : "",
            isNum(mo.precipMM) ? Number(mo.precipMM).toFixed(1) + " mm" : "",
            isNum(mo.thunderProb) && mo.thunderProb > 0 ? "Thunder " + Math.round(mo.thunderProb) + "%" : "",
            isNum(mo.snowProb) && mo.snowProb > 0 ? "Snow " + Math.round(mo.snowProb) + "%" : ""
        ]);
        if (rl2.length > 0)
            lines.push({ lead: "", icon: "water_drop", text: rl2 });
    }
    return lines;
}

// Marker points {y, color} for slot i, in graph-area coordinates. Empty for an invalid or
// unavailable slot. Plans 06 and 07 append the "rainwind" and "airuv" series here.
function markerPoints(kind, slots, i, geom, scales) {
    if (!geom || !slots || typeof slots.length !== "number" || !isNum(i) || i < 0 || i >= slots.length)
        return [];
    var slot = slots[i];
    if (!isAvailable(slot))
        return [];
    var pts = [];
    if (kind === "temp") {
        var scale = (scales && scales.temp) ? scales.temp : tempScale(slots);
        if (!scale || scale.empty || !slot.thermal)
            return [];
        var vals = [slot.thermal.tempC, slot.thermal.feelsLikeC];
        for (var k = 0; k < vals.length; ++k) {
            if (!isNum(vals[k]))
                continue;
            pts.push({
                y: valueToY(vals[k], scale.min, scale.max, geom.plotTop, geom.plotBottom),
                color: rampColorAt(TEMP_RAMP, vals[k])
            });
        }
    }
    if (kind === "rainwind") {
        var rsc = _rainwindScales(slots, scales);
        var rp = _rainOf(slot);
        if (isNum(rp))
            pts.push({ y: valueToY(rp, rsc.rain.min, rsc.rain.max, geom.plotTop, geom.plotBottom), color: rainColor(rp) });
    }
    return pts;
}
