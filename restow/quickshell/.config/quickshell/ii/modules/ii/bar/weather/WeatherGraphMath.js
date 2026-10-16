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

// Graph 2 visibility tiers (D-54.4-23/26): <1 km Fog, 1-4 Poor, 4-10 Moderate, >=10 Good.
var VIS_EDGES = [1, 4, 10];
var VIS_COLORS = ["#ef5350", "#ffa726", "#ffee58", "#66bb6a"];

// Graph 2 wind and gust lines, and the rain mm bars (D-54.4-23, PA-13).
var WIND_COLOR = "#ffffff";
var WIND_ALPHA = 0.9;
var MM_COLOR = "#26c6da";
var MM_ALPHA = 0.6;
// Bars use at most this share of the plot height (PA-13, mirrors D-54.4-29).
var BAR_CAP = 0.4;

// Graph 3 UV index WHO tiers (D-54.4-30/33): <3 Low green, 3-5 Moderate yellow, 6-7 High orange,
// 8-10 Very High red, 11+ Extreme violet. The violet is #ce93d8 (A4), not the EPA violet.
var UV_EDGES = [3, 6, 8, 11];
var UV_COLORS = ["#66bb6a", "#ffee58", "#ffa726", "#ef5350", "#ce93d8"];
// Height in px of the EPA tier ribbon along the bottom of the Graph 3 plot (D-54.4-27).
var RIBBON_H = 6;

// Graph 3 EPA tier ribbon (D-54.4-28), indexed by the API us-epa-index 1..6; index 0 is unused.
// Very Unhealthy and Hazardous sit below 3:1 on the card surface and are kept as locked (PA-3).
// Not the WeatherGlyphs AQI palette, which differs from the locked one.
var EPA_COLORS = [null, "#66bb6a", "#ffee58", "#ffa726", "#ef5350", "#ab47bc", "#c2185b"];
var EPA_NAMES = [null, "Good", "Moderate", "Unhealthy for Sensitive", "Unhealthy", "Very Unhealthy", "Hazardous"];

// Graph 3 solar radiation bars (D-54.4-29): amber at 45%, capped at BAR_CAP of the plot.
var SOLAR_COLOR = "#ffb300";
var SOLAR_ALPHA = 0.45;

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

// Scales computed once per timeline change.
function computeScales(kind, slots) {
    if (kind === "temp")
        return { temp: tempScale(slots) };
    if (kind === "rainwind") {
        // D-54.4-22: rain % on its own 0..100 scale; wind, gust and visibility share one invisible
        // 0..max scale (floored at 1 so it is never flat); mm bars have their own 0..max scale.
        var windMax = 1;
        var mmMax = 0;
        var list = (slots && typeof slots.length === "number") ? slots : [];
        for (var i = 0; i < list.length; ++i) {
            var s = list[i];
            if (!isAvailable(s))
                continue;
            var vals = [_speedOf(s), _gustOf(s), _visOf(s)];
            for (var k = 0; k < vals.length; ++k) {
                if (isNum(vals[k]) && vals[k] > windMax)
                    windMax = vals[k];
            }
            var p = _mmOf(s);
            if (isNum(p) && p > mmMax)
                mmMax = p;
        }
        return {
            rain: { min: 0, max: 100 },
            wind: { min: 0, max: windMax },
            mm: { min: 0, max: mmMax }
        };
    }
    if (kind === "airuv") {
        // D-54.4-29/30: the UV index on its own 0..max scale (floored at 1 so it is never flat);
        // solar bars on their own 0..max scale. Historical-unavailable slots never enter a scale.
        var uvMax = 1;
        var radMax = 0;
        var alist = (slots && typeof slots.length === "number") ? slots : [];
        for (var a = 0; a < alist.length; ++a) {
            var as = alist[a];
            if (!isAvailable(as))
                continue;
            var uv = _uvOf(as);
            if (isNum(uv) && uv > uvMax)
                uvMax = uv;
            var rad = _radOf(as);
            if (isNum(rad) && rad > radMax)
                radMax = rad;
        }
        return {
            uv: { min: 0, max: uvMax },
            solar: { min: 0, max: radMax }
        };
    }
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

// Visibility km -> tier word (D-54.4-26): >=10 Good, >=4 Moderate, >=1 Poor, else Fog.
function visibilityTier(km) {
    if (!isNum(km))
        return "";
    if (km >= VIS_EDGES[2])
        return "Good";
    if (km >= VIS_EDGES[1])
        return "Moderate";
    if (km >= VIS_EDGES[0])
        return "Poor";
    return "Fog";
}

// Visibility km -> tier colour, on the visibilityTier boundaries (D-54.4-23).
function visColor(km) {
    if (!isNum(km) || km >= VIS_EDGES[2])
        return VIS_COLORS[3];
    if (km >= VIS_EDGES[1])
        return VIS_COLORS[2];
    if (km >= VIS_EDGES[0])
        return VIS_COLORS[1];
    return VIS_COLORS[0];
}

// Visibility km as text: an integer when whole, otherwise one decimal.
function formatKm(km) {
    var r = Math.round(Number(km) * 10) / 10;
    if (!isFinite(r))
        return "";
    return r === Math.round(r) ? String(r) : r.toFixed(1);
}

// UV index -> WHO tier word (D-54.4-33): >=11 Extreme, >=8 Very High, >=6 High, >=3 Moderate,
// else Low. Non-finite input gives "".
function uvTier(uv) {
    if (!isNum(uv))
        return "";
    if (uv >= UV_EDGES[3])
        return "Extreme";
    if (uv >= UV_EDGES[2])
        return "Very High";
    if (uv >= UV_EDGES[1])
        return "High";
    if (uv >= UV_EDGES[0])
        return "Moderate";
    return "Low";
}

// UV index -> WHO tier colour, on the uvTier boundaries (D-54.4-30).
function uvColor(uv) {
    if (!isNum(uv) || uv < UV_EDGES[0])
        return UV_COLORS[0];
    if (uv < UV_EDGES[1])
        return UV_COLORS[1];
    if (uv < UV_EDGES[2])
        return UV_COLORS[2];
    if (uv < UV_EDGES[3])
        return UV_COLORS[3];
    return UV_COLORS[4];
}

// True only for an integer EPA index 1..6. Anything else (0, 7, 2.5, null, a string) is missing
// data and gets no ribbon segment and no tier word (T-54.4-17).
function _epaValid(idx) {
    return isNum(idx) && Math.floor(idx) === idx && idx >= 1 && idx <= 6;
}

// EPA index -> locked tier colour (D-54.4-28), or null when the index is not 1..6.
function epaColor(idx) {
    return _epaValid(idx) ? EPA_COLORS[idx] : null;
}

// EPA index -> tier name, or "--" when the index is not 1..6.
function epaName(idx) {
    return _epaValid(idx) ? EPA_NAMES[idx] : "--";
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

function _mmOf(s) {
    return s.moisture ? s.moisture.precipMM : undefined;
}

function _speedOf(s) {
    return s.wind ? s.wind.speedKmph : undefined;
}

function _gustOf(s) {
    return s.wind ? s.wind.gustKmph : undefined;
}

function _visOf(s) {
    return s.atmosphere ? s.atmosphere.visibilityKm : undefined;
}

// Graph 2 scales, falling back to computeScales for any piece the caller did not pass.
function _rainwindScales(slots, scales) {
    var sc = scales || {};
    var full = computeScales("rainwind", slots);
    return {
        rain: sc.rain ? sc.rain : full.rain,
        wind: sc.wind ? sc.wind : full.wind,
        mm: sc.mm ? sc.mm : full.mm
    };
}

// mm bar rects {i, p, x, y, w, h}: only available slots with precipMM > 0 (D-54.4-21), centred on
// the slot, max(2, slotW*0.6) wide, height precipMM / mm.max * BAR_CAP of the plot, standing on
// plotBottom (PA-13). mm.max > 0 whenever a bar exists, so there is no 0/0 (T-54.4-15).
function mmBarRects(geom, slots, mmScale) {
    return _barRects(geom, slots, _mmOf, mmScale);
}

// Shared bar geometry for the mm and solar bars: only available slots whose value is above 0,
// centred, max(2, slotW*0.6) wide, value / scale.max * BAR_CAP of the plot (geom.plotTop to
// geom.plotBottom) tall, standing on geom.plotBottom.
function _barRects(geom, slots, getter, scale) {
    var out = [];
    if (!geom || !slots || typeof slots.length !== "number" || !scale || !isNum(scale.max) || scale.max <= 0)
        return out;
    var plotH = geom.plotBottom - geom.plotTop;
    var w = Math.max(2, geom.slotW * 0.6);
    for (var i = 0; i < slots.length; ++i) {
        var s = slots[i];
        if (!isAvailable(s))
            continue;
        var p = getter(s);
        if (!isNum(p) || p <= 0)
            continue;
        var h = Math.min(p, scale.max) / scale.max * BAR_CAP * plotH;
        out.push({ i: i, p: p, x: slotCenterX(geom, i) - w / 2, y: geom.plotBottom - h, w: w, h: h });
    }
    return out;
}

// Graph 2 (D-54.4-21..24), drawn in this order, each inside save/restore:
// (a) mm bars under the lines, MM_COLOR at MM_ALPHA;
// (b) rain probability: monotone spline on its own 0..100 scale, stroked with the hard RAIN tier
//     gradient, lineWidth 2, solid;
// (c) wind: solid WIND_COLOR at WIND_ALPHA, lineWidth 1.5, on the shared wind scale;
// (d) gust: the same colour and alpha, DASH_DASHED, lineWidth 1.2;
// (e) visibility: VIS tier gradient over the wind scale, DASH_DOTTED, lineWidth 1.5.
// No y-axis labels or units.
function drawRainWind(ctx, geom, slots, scales) {
    if (!ctx || !geom || !slots || typeof slots.length !== "number" || slots.length < 1)
        return;
    var sc = _rainwindScales(slots, scales);

    var bars = mmBarRects(geom, slots, sc.mm);
    if (bars.length > 0) {
        ctx.save();
        ctx.fillStyle = MM_COLOR;
        ctx.globalAlpha = MM_ALPHA;
        for (var b = 0; b < bars.length; ++b)
            ctx.fillRect(bars[b].x, bars[b].y, bars[b].w, bars[b].h);
        ctx.restore();
    }

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

    var windRuns = seriesRuns(slots, _speedOf, geom, sc.wind);
    if (_hasStrokableRun(windRuns)) {
        ctx.save();
        ctx.strokeStyle = WIND_COLOR;
        ctx.globalAlpha = WIND_ALPHA;
        ctx.lineWidth = 1.5;
        ctx.lineJoin = "round";
        ctx.lineCap = "round";
        ctx.setLineDash([]);
        strokeRuns(ctx, windRuns);
        ctx.restore();
    }

    var gustRuns = seriesRuns(slots, _gustOf, geom, sc.wind);
    if (_hasStrokableRun(gustRuns)) {
        ctx.save();
        ctx.strokeStyle = WIND_COLOR;
        ctx.globalAlpha = WIND_ALPHA;
        ctx.lineWidth = 1.2;
        ctx.lineJoin = "round";
        ctx.setLineDash(DASH_DASHED.slice());
        strokeRuns(ctx, gustRuns);
        ctx.restore();
    }

    var visRuns = seriesRuns(slots, _visOf, geom, sc.wind);
    if (_hasStrokableRun(visRuns)) {
        ctx.save();
        ctx.strokeStyle = _verticalGradient(ctx, geom, tierStops(VIS_EDGES, visColor, sc.wind.max, sc.wind.min));
        ctx.lineWidth = 1.5;
        ctx.lineJoin = "round";
        ctx.lineCap = "round";
        ctx.setLineDash(DASH_DOTTED.slice());
        strokeRuns(ctx, visRuns);
        ctx.restore();
    }
}

// ---------------------------------------------------------------------------
// Draw: air, UV and pressure card (D-54.4-27..34)
// ---------------------------------------------------------------------------

function _uvOf(s) {
    return s.solar ? s.solar.uvIndex : undefined;
}

function _radOf(s) {
    return s.solar ? s.solar.shortRad : undefined;
}

function _epaOf(s) {
    return s.aqi ? s.aqi.epaIndex : undefined;
}

// Graph 3 scales, falling back to computeScales for any piece the caller did not pass.
function _airuvScales(slots, scales) {
    var sc = scales || {};
    var full = computeScales("airuv", slots);
    return {
        uv: sc.uv ? sc.uv : full.uv,
        solar: sc.solar ? sc.solar : full.solar
    };
}

// Graph 3 series geometry: the lines and bars live between plotTop and the top of the EPA
// ribbon, so nothing is drawn over the ribbon (D-54.4-27/29).
function airuvRibbonTop(geom) {
    return geom.plotBottom - RIBBON_H;
}

function _airuvGeom(geom) {
    return Object.assign({}, geom, { plotBottom: airuvRibbonTop(geom) });
}

// Solar bar rects {i, p, x, y, w, h} on the Graph 3 geometry: bars stand on the ribbon top and
// use at most BAR_CAP of the height above it (D-54.4-29). Only shortRad > 0, so no 0/0 (T-54.4-16).
function solarBarRects(geom, slots, solarScale) {
    if (!geom)
        return [];
    return _barRects(_airuvGeom(geom), slots, _radOf, solarScale);
}

// Graph 3 (D-54.4-27..31), drawn in this order, each inside save/restore:
// (a) EPA tier ribbon: one RIBBON_H strip per available slot whose epaIndex is 1..6, in the locked
//     tier colour at full opacity, along the bottom of the plot;
// (b) solar bars: SOLAR_COLOR at SOLAR_ALPHA, standing on the ribbon top;
// (c) UV index: monotone spline over the full height above the ribbon, stroked with the hard WHO
//     tier gradient, lineWidth 2, solid.
// PM2.5, PM10, diffRad and DEFRA are never drawn (D-54.4-27).
function drawAirUv(ctx, geom, slots, scales) {
    if (!ctx || !geom || !slots || typeof slots.length !== "number" || slots.length < 1)
        return;
    var sc = _airuvScales(slots, scales);
    var ug = _airuvGeom(geom);
    var ribbonTop = airuvRibbonTop(geom);

    ctx.save();
    ctx.globalAlpha = 1;
    for (var i = 0; i < slots.length; ++i) {
        var s = slots[i];
        if (!isAvailable(s))
            continue;
        var col = epaColor(_epaOf(s));
        if (col === null)
            continue;
        ctx.fillStyle = col;
        ctx.fillRect(geom.plotLeft + i * geom.slotW, ribbonTop, geom.slotW, RIBBON_H);
    }
    ctx.restore();

    var bars = solarBarRects(geom, slots, sc.solar);
    if (bars.length > 0) {
        ctx.save();
        ctx.fillStyle = SOLAR_COLOR;
        ctx.globalAlpha = SOLAR_ALPHA;
        for (var b = 0; b < bars.length; ++b)
            ctx.fillRect(bars[b].x, bars[b].y, bars[b].w, bars[b].h);
        ctx.restore();
    }

    var uvRuns = seriesRuns(slots, _uvOf, ug, sc.uv);
    if (_hasStrokableRun(uvRuns)) {
        ctx.save();
        ctx.strokeStyle = _verticalGradient(ctx, ug, tierStops(UV_EDGES, uvColor, sc.uv.max, sc.uv.min));
        ctx.lineWidth = 2;
        ctx.lineJoin = "round";
        ctx.lineCap = "round";
        ctx.setLineDash([]);
        strokeRuns(ctx, uvRuns);
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
// colour dot before the swatch. Plan 07 adds the "airuv" entries.
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
            { label: "Rain%", style: "solid", color: RAIN_COLORS[1], colors: RAIN_COLORS.slice(), dot: true },
            { label: "mm", style: "bar", color: MM_COLOR, colors: [MM_COLOR], dot: true },
            { label: "Wind", style: "solid", color: WIND_COLOR, colors: [WIND_COLOR], dot: true },
            { label: "Gust", style: "dashed", color: WIND_COLOR, colors: [WIND_COLOR], dot: true },
            { label: "Vis", style: "dotted", color: VIS_COLORS[3], colors: VIS_COLORS.slice(), dot: true }
        ];
    }
    if (kind === "airuv") {
        // D-54.4-32 order: UV, Solar, AQI, Pressure.
        return [
            { label: "UV", style: "solid", color: UV_COLORS[1], colors: UV_COLORS.slice(), dot: false },
            { label: "Solar", style: "bar", color: SOLAR_COLOR, colors: [SOLAR_COLOR], dot: false },
            { label: "AQI", style: "ribbon", color: EPA_COLORS[1], colors: EPA_COLORS.slice(1, 4), dot: false }
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
    // A bar value is written above its bar only, never beside or inside it (D-54.4-24).
    if (c.anchor === "bar-top")
        return [[centre, above]];
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
// Plan 07 adds the "airuv" candidates here.
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
        var lineSeries = [
            { get: _speedOf, priority: 3, text: function (v) { return String(Math.round(v)); }, color: function () { return WIND_COLOR; } },
            { get: _gustOf, priority: 3, text: function (v) { return "G" + Math.round(v); }, color: function () { return WIND_COLOR; } },
            { get: _visOf, priority: 4, text: function (v) { return formatKm(v) + " km"; }, color: visColor }
        ];
        for (var ls = 0; ls < lineSeries.length; ++ls) {
            var ser = lineSeries[ls];
            var lpk = _peakOf(slots, ser.get);
            if (!lpk || lpk.v <= 0)
                continue;
            var ltext = ser.text(lpk.v);
            out.push({
                text: ltext,
                x: slotCenterX(geom, lpk.i),
                y: valueToY(lpk.v, rsc.wind.min, rsc.wind.max, geom.plotTop, geom.plotBottom),
                w: ctx.measureText(ltext).width,
                h: 10,
                priority: ser.priority,
                rank: lpk.v,
                color: ser.color(lpk.v),
                anchor: "above"
            });
        }
        // One mm value per bar, written above its bar and never inside it (D-54.4-24, PA-11).
        // The "bar-top" anchor offers only the above-centre spot, so when neighbouring values
        // collide the larger (placed first by rank) is kept and the smaller one is dropped; its
        // exact value stays in tooltip line 2.
        var mmBars = mmBarRects(geom, slots, rsc.mm);
        for (var mb = 0; mb < mmBars.length; ++mb) {
            var mtext = Number(mmBars[mb].p).toFixed(1);
            out.push({
                text: mtext,
                x: slotCenterX(geom, mmBars[mb].i),
                y: mmBars[mb].y,
                w: ctx.measureText(mtext).width,
                h: 10,
                priority: 7,
                rank: mmBars[mb].p,
                color: MM_COLOR,
                anchor: "bar-top"
            });
        }
        ctx.restore();
    }
    if (kind === "airuv") {
        var asc = _airuvScales(slots, scales);
        var ag = _airuvGeom(geom);
        ctx.save();
        ctx.font = LABEL_FONT;
        // UV max at its high point in its tier colour; a UV that never rises above 0 gets none.
        var upk = _peakOf(slots, _uvOf);
        if (upk && upk.v > 0) {
            var utext = String(Math.round(upk.v));
            out.push({
                text: utext,
                x: slotCenterX(geom, upk.i),
                y: valueToY(upk.v, asc.uv.min, asc.uv.max, ag.plotTop, ag.plotBottom),
                w: ctx.measureText(utext).width,
                h: 10,
                priority: 4,
                rank: upk.v,
                color: uvColor(upk.v),
                anchor: "above"
            });
        }
        // Solar peak W/m² written above the tallest bar (D-54.4-29). The "bar-top" anchor offers
        // only the above-centre spot, so the value is never drawn inside its bar.
        var sbars = solarBarRects(geom, slots, asc.solar);
        var tallest = null;
        for (var sb = 0; sb < sbars.length; ++sb) {
            if (tallest === null || sbars[sb].p > tallest.p)
                tallest = sbars[sb];
        }
        if (tallest !== null && tallest.p > 0) {
            var stext = Math.round(tallest.p) + " W/m²";
            out.push({
                text: stext,
                x: slotCenterX(geom, tallest.i),
                y: tallest.y,
                w: ctx.measureText(stext).width,
                h: 10,
                priority: 6,
                rank: tallest.p,
                color: SOLAR_COLOR,
                anchor: "bar-top"
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
// collision-free peak labels. Plan 07 adds the "airuv" branch.
function drawKind(ctx, kind, geom, slots, scales, theme) {
    drawBackdrop(ctx, geom, slots, theme);
    if (kind === "temp") {
        var scale = (scales && scales.temp) ? scales.temp : tempScale(slots);
        drawTempAxis(ctx, geom, scale, theme);
        drawTemp(ctx, geom, slots, scales);
    }
    if (kind === "rainwind")
        drawRainWind(ctx, geom, slots, scales);
    if (kind === "airuv")
        drawAirUv(ctx, geom, slots, scales);
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
// Plan 07 appends the "airuv" lines here.
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
        // Line 3 "<speed> km/h · G<gust> · <dir16> <deg>°"; line 4 "<km> km <tier>" (D-54.4-26).
        var wi = slot.wind || {};
        if (isNum(wi.speedKmph)) {
            var l3 = Math.round(wi.speedKmph) + " km/h";
            if (isNum(wi.gustKmph))
                l3 += " · G" + Math.round(wi.gustKmph);
            var dirPart = [wi.dir16 ? String(wi.dir16) : "", isNum(wi.degree) ? Math.round(wi.degree) + "°" : ""].filter(function (x) {
                return x.length > 0;
            }).join(" ");
            if (dirPart.length > 0)
                l3 += " · " + dirPart;
            lines.push({ lead: "", icon: "air", text: l3 });
        }
        var vis = slot.atmosphere ? slot.atmosphere.visibilityKm : null;
        if (isNum(vis))
            lines.push({ lead: "", icon: "visibility", text: formatKm(vis) + " km " + visibilityTier(vis) });
    }
    if (kind === "airuv") {
        // D-54.4-33 line 2 "<light_mode> UV <n> <WHO tier> · <shortRad> W/m²". The tier word is
        // taken from the rounded index, so the number and the word always agree.
        var so = slot.solar || {};
        var uvR = isNum(so.uvIndex) ? Math.round(so.uvIndex) : null;
        var al2 = _joinDot([
            uvR !== null ? "UV " + uvR + " " + uvTier(uvR) : "",
            isNum(so.shortRad) ? Math.round(so.shortRad) + " W/m²" : ""
        ]);
        if (al2.length > 0)
            lines.push({ lead: "", icon: "light_mode", text: al2 });
        // Line 3 "<masks> AQI <EPA tier> · PM2.5 <n> · PM10 <n>" (an index outside 1..6 reads
        // "AQI --"); line 4 "CO <n> · NO₂ <n> · O₃ <n> · SO₂ <n>" in µg/m³, with no icon.
        var aq = slot.aqi || {};
        var al3 = _joinDot([
            "AQI " + epaName(aq.epaIndex),
            isNum(aq.pm2_5) ? "PM2.5 " + Math.round(aq.pm2_5) : "",
            isNum(aq.pm10) ? "PM10 " + Math.round(aq.pm10) : ""
        ]);
        lines.push({ lead: "", icon: "masks", text: al3 });
        var al4 = _joinDot([
            isNum(aq.co) ? "CO " + Math.round(aq.co) : "",
            isNum(aq.no2) ? "NO₂ " + Math.round(aq.no2) : "",
            isNum(aq.o3) ? "O₃ " + Math.round(aq.o3) : "",
            isNum(aq.so2) ? "SO₂ " + Math.round(aq.so2) : ""
        ]);
        if (al4.length > 0)
            lines.push({ lead: "", icon: "", text: al4 });
    }
    return lines;
}

// Marker points {y, color} for slot i, in graph-area coordinates. Empty for an invalid or
// unavailable slot. Plan 07 appends the "airuv" series here.
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
        var wv = [[_speedOf(slot), WIND_COLOR], [_gustOf(slot), WIND_COLOR], [_visOf(slot), null]];
        for (var w = 0; w < wv.length; ++w) {
            if (!isNum(wv[w][0]))
                continue;
            pts.push({
                y: valueToY(wv[w][0], rsc.wind.min, rsc.wind.max, geom.plotTop, geom.plotBottom),
                color: wv[w][1] !== null ? wv[w][1] : visColor(wv[w][0])
            });
        }
    }
    if (kind === "airuv") {
        var asc = _airuvScales(slots, scales);
        var ag = _airuvGeom(geom);
        var uvv = _uvOf(slot);
        if (isNum(uvv))
            pts.push({ y: valueToY(uvv, asc.uv.min, asc.uv.max, ag.plotTop, ag.plotBottom), color: uvColor(uvv) });
    }
    return pts;
}
