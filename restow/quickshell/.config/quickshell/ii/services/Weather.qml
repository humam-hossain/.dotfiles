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

    // 60-Second Safety Fallback Poll Timer (D-52-02)
    Timer {
        id: fallbackTimer
        interval: 60000
        repeat: true
        running: true
        onTriggered: {
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
            root.isOffline = true;
            root.isStale = true;
            return;
        }

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
    }

    Component.onCompleted: {
        root.loadCache();
    }
}
