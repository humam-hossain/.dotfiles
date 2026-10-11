pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.services

Singleton {
    id: root

    // Cache Paths (D-52-03)
    readonly property string runtimeDir: {
        const xdg = Quickshell.env("XDG_RUNTIME_DIR");
        return (xdg && xdg.length > 0) ? xdg : ("/run/user/" + Quickshell.env("UID"));
    }
    readonly property string runtimeCachePath: runtimeDir + "/weather/weather.json"

    readonly property string stateDir: {
        const xdgState = Quickshell.env("XDG_STATE_HOME");
        if (xdgState && xdgState.length > 0) return xdgState;
        const home = Quickshell.env("HOME");
        return (home && home.length > 0) ? (home + "/.local/state") : "";
    }
    readonly property string persistentCachePath: stateDir + "/weather/last_known_weather.json"

    // Operational Status Flags (D-52-05)
    property bool isStale: true
    property bool isOffline: true
    property string lastRefresh: "--:--"
    property string city: ""
    property string country: ""

    // Grouped Reactive Properties with Safe Defaults (D-52-05, D-52-08)
    property var current: ({
        tempC: "--",
        tempFeelsLikeC: "--",
        desc: "Offline",
        glyph: "cloud_off",
        humidity: "--",
        uv: 0,
        windKmph: "--",
        windDir: "--",
        windDegree: 0,
        precipMM: "--",
        pressureHpa: "--",
        visibilityKm: "--",
        isDaytime: true
    })

    property var hourly: []
    property var alerts: []

    property var aqi: ({
        epaIndex: 0,
        category: "Unavailable",
        pm2_5: "--",
        pm10: "--",
        color: "transparent"
    })

    property var astronomy: ({
        sunrise: "--:--",
        sunset: "--:--",
        moonPhase: "--",
        moonIllumination: "--"
    })

    // Backward Compatibility Facade for WeatherWidget.qml (D-52-01, D-52-08)
    property var data: ({
        uv: 0,
        humidity: "--%",
        sunrise: "--:--",
        sunset: "--:--",
        windDir: "--",
        wCode: "",
        city: "",
        wind: "-- km/h",
        precip: "-- mm",
        visib: "-- km",
        press: "-- hPa",
        temp: "--°C",
        tempFeelsLike: "--°C",
        lastRefresh: "--"
    })

    // Continuous 25-Point Rolling Timeline Model (D-54.2-01, D-54.2-02, D-54.2-07)
    property var timeline: []
    property var tempBounds: ({ min: 0, max: 0 })
    property var rainBounds: ({ maxProb: 0, maxMM: 0 })
    property int activeTimelineHour: -1

    // Memoized Series Accessor Internal Cache (D-54.2-19)
    property var _seriesCache: ({})
    property int _timelineRevision: 0

    // Stored active payload for synchronous hour-rollover rebuilds
    property var activePayload: null

    // Safe Passive Handler (D-52-04)
    function getData() {
        runtimeCacheFile.reload();
        root.loadCache();
    }

    // Reactive File Observers (D-52-02, D-52-03)
    FileView {
        id: runtimeCacheFile
        path: root.runtimeCachePath
        watchChanges: true
        blockLoading: true
        printErrors: false

        onFileChanged: {
            this.reload();
            root.loadCache();
        }
        onLoadedChanged: root.loadCache()
    }

    FileView {
        id: persistentCacheFile
        path: root.persistentCachePath
        watchChanges: false
        blockLoading: true
        printErrors: false
    }

    // 60-Second Safety Fallback Poll Timer & Top-of-Hour Trigger (D-52-02, D-54.2-04)
    Timer {
        id: fallbackTimer
        interval: 60000
        repeat: true
        running: true
        onTriggered: {
            const currentHour = (new Date()).getHours();
            if (currentHour !== root.activeTimelineHour) {
                root.rebuildTimeline();
            }
            runtimeCacheFile.reload();
            root.loadCache();
        }
    }

    function loadCache() {
        let text = runtimeCacheFile.text().trim();
        let payload = null;

        if (text.length > 0) {
            try {
                payload = JSON.parse(text);
            } catch (e) {
                payload = null;
            }
        }

        // Cold boot fallback to persistent disk mirror if runtime data missing (D-52-03)
        if (!payload || !payload.data) {
            persistentCacheFile.reload();
            const persistText = persistentCacheFile.text().trim();
            if (persistText.length > 0) {
                try {
                    const fallbackPayload = JSON.parse(persistText);
                    if (fallbackPayload && fallbackPayload.data) {
                        payload = fallbackPayload;
                        payload.is_stale = true;
                    }
                } catch (e) {}
            }
        }

        if (!payload || !payload.data) {
            root.activePayload = null;
            root.isOffline = true;
            root.isStale = true;
            root.rebuildTimeline();
            return;
        }

        root.activePayload = payload;
        root.isOffline = (payload.status === "offline");
        root.isStale = !!payload.is_stale;

        // Parse Timestamps
        let timeStr = "";
        if (payload.fetched_at) {
            try {
                const d = new Date(payload.fetched_at);
                timeStr = d.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
            } catch (e) {}
        }
        if (!timeStr && payload.data.current_condition?.[0]?.observation_time) {
            timeStr = payload.data.current_condition[0].observation_time;
        }
        root.lastRefresh = timeStr || "--:--";

        const raw = payload.data;
        const cur = raw.current_condition?.[0] || {};
        const weather0 = raw.weather?.[0] || {};
        const astro = weather0.astronomy?.[0] || {};
        const loc = raw.nearest_area?.[0] || {};
        const aq = cur.air_quality || {};

        root.city = loc.areaName?.[0]?.value || "";
        root.country = loc.country?.[0]?.value || "";

        // 1. Current Conditions
        const wCode = cur.weatherCode || "";
        const isDayStr = cur.isdaytime || "yes";
        const glyph = WeatherGlyphs.getGlyph(wCode, isDayStr);

        const tempVal = parseInt(cur.temp_C);
        const feelsLikeVal = parseInt(cur.FeelsLikeC);

        root.current = {
            tempC: !isNaN(tempVal) ? tempVal : "--",
            tempFeelsLikeC: !isNaN(feelsLikeVal) ? feelsLikeVal : "--",
            desc: cur.weatherDesc?.[0]?.value || "Clear",
            glyph: glyph,
            humidity: (cur.humidity || "0") + "%",
            uv: parseInt(cur.uvIndex || 0),
            windKmph: (cur.windspeedKmph || "0") + " km/h",
            windDir: cur.winddir16Point || "N",
            windDegree: parseInt(cur.winddirDegree || 0),
            precipMM: (cur.precipMM || "0.0") + " mm",
            pressureHpa: (cur.pressure || "0") + " hPa",
            visibilityKm: (cur.visibility || "0") + " km",
            isDaytime: (isDayStr === "yes" || isDayStr === true || isDayStr === 1 || isDayStr === "1")
        };

        // 2. Hourly Forecast Array (Raw Preserved JSON) (D-52-06)
        root.hourly = weather0.hourly || [];

        // 3. Air Quality
        const epa = parseInt(aq["us-epa-index"] || 0);
        root.aqi = {
            epaIndex: epa,
            category: WeatherGlyphs.getAqiCategory(epa),
            pm2_5: aq.pm2_5 ? String(aq.pm2_5) : "--",
            pm10: aq.pm10 ? String(aq.pm10) : "--",
            color: WeatherGlyphs.getAqiColor(epa)
        };

        // 4. Astronomy
        root.astronomy = {
            sunrise: astro.sunrise || "--:--",
            sunset: astro.sunset || "--:--",
            moonPhase: astro.moon_phase || "--",
            moonIllumination: astro.moon_illumination || "--"
        };

        // 5. Severe Alerts
        let alertArray = [];
        if (raw.alerts?.alert) {
            if (Array.isArray(raw.alerts.alert)) alertArray = raw.alerts.alert;
            else if (typeof raw.alerts.alert === "object") alertArray = [raw.alerts.alert];
        }
        root.alerts = alertArray.map(a => ({
            headline: a.headline || "",
            event: a.event || "",
            severity: a.severity || "",
            urgency: a.urgency || "",
            areas: a.areas || "",
            effective: a.effective || "",
            expires: a.expires || "",
            desc: a.desc || "",
            color: WeatherGlyphs.getAlertColor(a.severity || a.event || "")
        }));

        // 6. Legacy Facade Update (D-52-01)
        root.data = {
            uv: parseInt(cur.uvIndex || 0),
            humidity: (cur.humidity || "0") + "%",
            sunrise: astro.sunrise || "--:--",
            sunset: astro.sunset || "--:--",
            windDir: cur.winddir16Point || "N",
            wCode: wCode,
            city: root.city || "Dhaka",
            wind: (cur.windspeedKmph || "0") + " km/h",
            precip: (cur.precipMM || "0.0") + " mm",
            visib: (cur.visibility || "0") + " km",
            press: (cur.pressure || "0") + " hPa",
            temp: (cur.temp_C !== undefined && cur.temp_C !== null ? cur.temp_C : "--") + "°C",
            tempFeelsLike: (cur.FeelsLikeC !== undefined && cur.FeelsLikeC !== null ? cur.FeelsLikeC : "--") + "°C",
            lastRefresh: root.lastRefresh
        };

        // 7. Continuous 25-Point Rolling Timeline Model (D-54.2-01, D-54.2-20)
        root.rebuildTimeline();
    }

    function rebuildTimeline() {
        const payload = root.activePayload;
        if (!payload || !payload.data) {
            root.timeline = [];
            root.tempBounds = { min: 0, max: 0 };
            root.rainBounds = { maxProb: 0, maxMM: 0 };
            root._seriesCache = ({});
            root._timelineRevision++;
            return;
        }

        const now = new Date();
        const nowHour = now.getHours();
        root.activeTimelineHour = nowHour;

        const raw = payload.data;
        const slotMap = {};

        // Ingest multi-day slots into slotMap by ISO key YYYY-MM-DDTHH:00 (D-54.2-06)
        function ingestDay(dayObj) {
            if (!dayObj || !dayObj.date || !Array.isArray(dayObj.hourly)) return;
            const dayDate = dayObj.date; // "YYYY-MM-DD"
            for (let i = 0; i < dayObj.hourly.length; ++i) {
                const h = dayObj.hourly[i];
                if (!h) continue;
                // FILTER RULE: Skip WWO daily summary slot (time: "24" or 24)
                if (h.time === "24" || h.time === 24) continue;

                const hrNum = Math.floor(parseInt(h.time, 10) / 100);
                const hrStr = ("0" + hrNum).slice(-2);
                const isoKey = dayDate + "T" + hrStr + ":00";
                slotMap[isoKey] = h;
            }
        }

        // Ingest history (yesterday) if present
        if (Array.isArray(payload.history)) {
            for (let d = 0; d < payload.history.length; ++d) {
                ingestDay(payload.history[d]);
            }
        }

        // Ingest forecast days (today, tomorrow, day+2)
        if (Array.isArray(raw.weather)) {
            for (let d = 0; d < raw.weather.length; ++d) {
                ingestDay(raw.weather[d]);
            }
        }

        const cur = raw.current_condition?.[0] || {};
        const nowMidnight = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
        const slots = new Array(25);
        const validTemps = [];
        let maxRainProb = 0;
        let maxRainMM = 0.0;

        for (let i = 0; i < 25; ++i) {
            const offset = i - 12;
            const slotDate = new Date(now.getFullYear(), now.getMonth(), now.getDate(), nowHour + offset, 0, 0, 0);

            const yr = slotDate.getFullYear();
            const mo = ("0" + (slotDate.getMonth() + 1)).slice(-2);
            const da = ("0" + slotDate.getDate()).slice(-2);
            const hr = slotDate.getHours();
            const hrStr = ("0" + hr).slice(-2);
            const dateStr = yr + "-" + mo + "-" + da;
            const isoKey = dateStr + "T" + hrStr + ":00";

            const isPast = (i < 12);
            const isNow = (i === 12);
            const isFuture = (i > 12);

            const rawSlot = slotMap[isoKey] || null;
            const isHistoricalUnavailable = isPast && !rawSlot;

            const slotMidnight = new Date(yr, slotDate.getMonth(), slotDate.getDate()).getTime();
            const dayOffset = Math.round((slotMidnight - nowMidnight) / 86400000);
            const isDayBoundary = (hr === 0);

            let isDay = false;
            if (rawSlot) {
                isDay = (rawSlot.isdaytime === "yes" || rawSlot.isdaytime === true || rawSlot.isdaytime === 1 || rawSlot.isdaytime === "1");
            } else {
                isDay = (hr >= 6 && hr < 18);
            }

            const wCode = rawSlot ? (rawSlot.weatherCode || "") : "";
            let glyph = "cloud_off";
            let desc = "No Data";
            if (isHistoricalUnavailable) {
                glyph = "cloud_off";
                desc = "No Data";
            } else if (rawSlot) {
                glyph = WeatherGlyphs.getGlyph(wCode, isDay);
                desc = rawSlot.weatherDesc?.[0]?.value || "Clear";
            } else {
                glyph = WeatherGlyphs.getGlyph("", isDay);
                desc = "Clear";
            }

            // Domain sub-objects with strict numeric parsing
            let thermal = {};
            let moisture = {};
            let wind = {};
            let aqi = {};
            let atmosphere = {};
            let solar = {};

            if (isHistoricalUnavailable) {
                thermal = {
                    tempC: null,
                    feelsLikeC: null,
                    dewPointC: null,
                    heatIndexC: null,
                    windChillC: null
                };
                moisture = {
                    precipMM: 0.0,
                    rainProb: 0,
                    humidity: 0,
                    cloudCover: 0,
                    snowProb: 0,
                    thunderProb: 0
                };
                wind = {
                    speedKmph: 0,
                    gustKmph: 0,
                    degree: 0,
                    dir16: "N"
                };
                aqi = {
                    epaIndex: 0,
                    pm2_5: 0.0,
                    pm10: 0.0,
                    co: 0.0,
                    no2: 0.0,
                    o3: 0.0,
                    so2: 0.0,
                    defraIndex: 0
                };
                atmosphere = {
                    pressureHpa: 0,
                    visibilityKm: 0
                };
                solar = {
                    uvIndex: 0,
                    shortRad: 0.0,
                    diffRad: 0.0
                };
            } else if (isNow) {
                // Center NOW reconciliation (D-54.2-21, D-54.2-22)
                const liveTemp = parseInt(cur.temp_C, 10);
                const liveFeels = parseInt(cur.FeelsLikeC, 10);
                const curAq = cur.air_quality || {};

                thermal = {
                    tempC: !isNaN(liveTemp) ? liveTemp : (rawSlot ? parseInt(rawSlot.tempC, 10) : 0),
                    feelsLikeC: !isNaN(liveFeels) ? liveFeels : (rawSlot ? parseInt(rawSlot.FeelsLikeC, 10) : 0),
                    dewPointC: rawSlot ? parseInt(rawSlot.DewPointC, 10) || 0 : 0,
                    heatIndexC: rawSlot ? parseInt(rawSlot.HeatIndexC, 10) || 0 : 0,
                    windChillC: rawSlot ? parseInt(rawSlot.WindChillC, 10) || 0 : 0
                };

                const obsPrecip = parseFloat(cur.precipMM) || 0.0;
                const forecastRainProb = rawSlot ? (parseInt(rawSlot.chanceofrain, 10) || 0) : 0;
                moisture = {
                    precipMM: obsPrecip,
                    rainProb: forecastRainProb,
                    humidity: parseInt(cur.humidity, 10) || (rawSlot ? parseInt(rawSlot.humidity, 10) : 0) || 0,
                    cloudCover: parseInt(cur.cloudcover, 10) || (rawSlot ? parseInt(rawSlot.cloudcover, 10) : 0) || 0,
                    snowProb: rawSlot ? (parseInt(rawSlot.chanceofsnow, 10) || 0) : 0,
                    thunderProb: rawSlot ? (parseInt(rawSlot.chanceofthunder, 10) || 0) : 0
                };

                wind = {
                    speedKmph: parseInt(cur.windspeedKmph, 10) || 0,
                    gustKmph: rawSlot ? (parseInt(rawSlot.WindGustKmph, 10) || 0) : 0,
                    degree: parseInt(cur.winddirDegree, 10) || 0,
                    dir16: cur.winddir16Point || "N"
                };

                const epa = parseInt(curAq["us-epa-index"], 10) || 0;
                aqi = {
                    epaIndex: epa,
                    pm2_5: parseFloat(curAq.pm2_5) || 0.0,
                    pm10: parseFloat(curAq.pm10) || 0.0,
                    co: parseFloat(curAq.co) || 0.0,
                    no2: parseFloat(curAq.no2) || 0.0,
                    o3: parseFloat(curAq.o3) || 0.0,
                    so2: parseFloat(curAq.so2) || 0.0,
                    defraIndex: parseInt(curAq["gb-defra-index"], 10) || 0
                };

                atmosphere = {
                    pressureHpa: parseInt(cur.pressure, 10) || 0,
                    visibilityKm: parseInt(cur.visibility, 10) || 0
                };

                solar = {
                    uvIndex: parseInt(cur.uvIndex, 10) || (rawSlot ? parseInt(rawSlot.uvIndex, 10) : 0) || 0,
                    shortRad: rawSlot ? (parseFloat(rawSlot.shortrad) || 0.0) : 0.0,
                    diffRad: rawSlot ? (parseFloat(rawSlot.diffrad) || 0.0) : 0.0
                };

                if (thermal.tempC !== null && !isNaN(thermal.tempC)) {
                    validTemps.push(thermal.tempC);
                }
                if (moisture.rainProb > maxRainProb) maxRainProb = moisture.rainProb;
                if (moisture.precipMM > maxRainMM) maxRainMM = moisture.precipMM;
            } else {
                // Historical past or Future slot
                const r = rawSlot || {};
                const rAq = r.air_quality || {};

                const slotTemp = parseInt(r.tempC, 10);
                const slotFeels = parseInt(r.FeelsLikeC, 10);

                thermal = {
                    tempC: !isNaN(slotTemp) ? slotTemp : 0,
                    feelsLikeC: !isNaN(slotFeels) ? slotFeels : 0,
                    dewPointC: parseInt(r.DewPointC, 10) || 0,
                    heatIndexC: parseInt(r.HeatIndexC, 10) || 0,
                    windChillC: parseInt(r.WindChillC, 10) || 0
                };

                const pMM = parseFloat(r.precipMM) || 0.0;
                const rProb = parseInt(r.chanceofrain, 10) || 0;
                moisture = {
                    precipMM: pMM,
                    rainProb: rProb,
                    humidity: parseInt(r.humidity, 10) || 0,
                    cloudCover: parseInt(r.cloudcover, 10) || 0,
                    snowProb: parseInt(r.chanceofsnow, 10) || 0,
                    thunderProb: parseInt(r.chanceofthunder, 10) || 0
                };

                wind = {
                    speedKmph: parseInt(r.windspeedKmph, 10) || 0,
                    gustKmph: parseInt(r.WindGustKmph, 10) || 0,
                    degree: parseInt(r.winddirDegree, 10) || 0,
                    dir16: r.winddir16Point || "N"
                };

                const epa = parseInt(rAq["us-epa-index"], 10) || 0;
                aqi = {
                    epaIndex: epa,
                    pm2_5: parseFloat(rAq.pm2_5) || 0.0,
                    pm10: parseFloat(rAq.pm10) || 0.0,
                    co: parseFloat(rAq.co) || 0.0,
                    no2: parseFloat(rAq.no2) || 0.0,
                    o3: parseFloat(rAq.o3) || 0.0,
                    so2: parseFloat(rAq.so2) || 0.0,
                    defraIndex: parseInt(rAq["gb-defra-index"], 10) || 0
                };

                atmosphere = {
                    pressureHpa: parseInt(r.pressure, 10) || 0,
                    visibilityKm: parseInt(r.visibility, 10) || 0
                };

                solar = {
                    uvIndex: parseInt(r.uvIndex, 10) || 0,
                    shortRad: parseFloat(r.shortrad) || 0.0,
                    diffRad: parseFloat(r.diffrad) || 0.0
                };

                if (thermal.tempC !== null && !isNaN(thermal.tempC)) {
                    validTemps.push(thermal.tempC);
                }
                if (moisture.rainProb > maxRainProb) maxRainProb = moisture.rainProb;
                if (moisture.precipMM > maxRainMM) maxRainMM = moisture.precipMM;
            }

            slots[i] = {
                index: i,
                normalizedX: Number((i / 24.0).toFixed(4)),
                isPast: isPast,
                isNow: isNow,
                isFuture: isFuture,
                isHistoricalUnavailable: isHistoricalUnavailable,
                isoKey: isoKey,
                dateStr: dateStr,
                timeStr: hrStr + ":00",
                hourNum: hr,
                dayOffset: dayOffset,
                isDayBoundary: isDayBoundary,
                timeLabel: isNow ? "Now" : (hrStr + ":00"),
                fullTimeLabel: isNow ? ("Now (" + hrStr + ":00)") : (hrStr + ":00"),
                observationTime: isNow ? (cur.observation_time || "") : "",
                isDay: isDay,
                glyph: glyph,
                desc: desc,
                weatherCode: wCode,
                thermal: thermal,
                moisture: moisture,
                wind: wind,
                aqi: aqi,
                atmosphere: atmosphere,
                solar: solar
            };
        }

        root.timeline = slots;
        root.tempBounds = {
            min: validTemps.length > 0 ? Math.min(...validTemps) : 0,
            max: validTemps.length > 0 ? Math.max(...validTemps) : 0
        };
        root.rainBounds = {
            maxProb: maxRainProb,
            maxMM: maxRainMM
        };

        // Synchronous cache invalidation (D-54.2-19)
        root._seriesCache = ({});
        root._timelineRevision++;
    }

    function getSeries(metricPath) {
        if (!metricPath || root.timeline.length !== 25) return [];
        if (root._seriesCache[metricPath]) return root._seriesCache[metricPath];

        const parts = metricPath.split(".");
        const series = new Array(25);

        for (let i = 0; i < 25; ++i) {
            const slot = root.timeline[i];
            let val = null;
            if (parts.length === 2) {
                val = slot[parts[0]]?.[parts[1]];
            } else if (parts.length === 1) {
                val = slot[metricPath] ?? slot.thermal?.[metricPath] ?? slot.moisture?.[metricPath];
            }
            series[i] = (val !== null && val !== undefined && !isNaN(val)) ? Number(val) : (parts[0] === "thermal" ? null : 0);
        }

        root._seriesCache[metricPath] = series;
        return series;
    }

    Component.onCompleted: {
        root.loadCache();
    }
}
