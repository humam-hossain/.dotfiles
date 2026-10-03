pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.modules.common

Singleton {
    id: root

    // Centralized Atmospheric & Celestial Metric Glyphs (D-52-12)
    readonly property string glyphHumidity: "water_drop"
    readonly property string glyphPressure: "speed"
    readonly property string glyphUv: "wb_sunny"
    readonly property string glyphVisibility: "visibility"
    readonly property string glyphWind: "air"
    readonly property string glyphSunrise: "wb_twilight"
    readonly property string glyphSunset: "bedtime"
    readonly property string glyphAlert: "warning"
    readonly property string glyphOffline: "cloud_off"
    readonly property string glyphDefault: "cloud"

    // Authoritative 59-Code WWO Mapping Table (wwoConditionCodes.txt, D-52-10)
    readonly property var glyphMap: ({
        // Clear & Skies (Day/Night Aware)
        "113": { day: "clear_day", night: "clear_night" },
        "116": { day: "partly_cloudy_day", night: "partly_cloudy_night" },
        "119": "cloud",
        "122": "cloud",

        // Haze, Dust, Smoke, Fog
        "125": "foggy", // Haze
        "128": "foggy", // Dust haze
        "131": "air",   // Blowing dust
        "134": "air",   // Dust storm
        "137": "air",   // Sandstorm
        "140": "air",   // Severe sandstorm
        "143": "foggy", // Mist
        "146": "foggy", // Smoke
        "149": "foggy", // Smoky haze (Dhaka active)
        "152": "foggy", // Smog
        "155": "foggy", // Severe smog
        "158": "air",   // Saharan dust
        "161": "foggy", // Dust
        "248": "foggy", // Fog
        "260": "foggy", // Freezing fog

        // Rain & Drizzle
        "176": "rainy",
        "263": "rainy",
        "266": "rainy",
        "281": "rainy",
        "284": "rainy",
        "293": "rainy",
        "296": "rainy",
        "299": "rainy",
        "302": "rainy",
        "305": "rainy",
        "308": "weather_hail",
        "311": "rainy",
        "314": "weather_hail",
        "353": "rainy",
        "356": "rainy",
        "359": "weather_hail",

        // Snow & Blizzard
        "179": "cloudy_snowing",
        "227": "cloudy_snowing",
        "230": "snowing_heavy",
        "323": "cloudy_snowing",
        "326": "cloudy_snowing",
        "329": "snowing_heavy",
        "332": "snowing_heavy",
        "335": "snowing_heavy",
        "338": "snowing_heavy",
        "368": "cloudy_snowing",
        "371": "snowing_heavy",

        // Sleet & Pellets
        "182": "rainy",
        "185": "rainy",
        "317": "rainy",
        "320": "cloudy_snowing",
        "350": "rainy",
        "362": "rainy",
        "365": "rainy",
        "374": "rainy",
        "377": "weather_hail",

        // Thunderstorms
        "200": "thunderstorm",
        "386": "thunderstorm",
        "389": "thunderstorm",
        "392": "thunderstorm",
        "395": "snowing_heavy"
    })

    // Resolve Material Symbols Rounded ligature from WWO code with day/night awareness
    function getGlyph(code, isDaytime) {
        if (code === undefined || code === null || code === "") return root.glyphDefault;
        const key = String(code);
        const isDay = (isDaytime === true || isDaytime === "yes" || isDaytime === 1 || isDaytime === "1");
        if (Object.prototype.hasOwnProperty.call(root.glyphMap, key)) {
            const entry = root.glyphMap[key];
            if (typeof entry === "object" && entry !== null) {
                return isDay ? entry.day : entry.night;
            }
            return entry;
        }
        return root.glyphDefault; // Safe universal neutral fallback (D-52-11)
    }

    // US-EPA Air Quality Index Category (D-52-08)
    function getAqiCategory(epaIndex) {
        switch (parseInt(epaIndex)) {
            case 1: return "Good";
            case 2: return "Moderate";
            case 3: return "Unhealthy for Sensitive Groups";
            case 4: return "Unhealthy";
            case 5: return "Very Unhealthy";
            case 6: return "Hazardous";
            default: return "Unavailable";
        }
    }

    // US-EPA Air Quality Index Color Mapping (D-52-13, D-52-15)
    function getAqiColor(epaIndex) {
        switch (parseInt(epaIndex)) {
            case 1: return "#81C784"; // Good (Green)
            case 2: return "#FFD54F"; // Moderate (Yellow/Amber)
            case 3: return "#FF9800"; // Unhealthy for Sensitive (Orange)
            case 4: return "#E53935"; // Unhealthy (Red)
            case 5: return "#BA68C8"; // Very Unhealthy (Purple)
            case 6: return "#880E4F"; // Hazardous (Maroon)
            default: return "transparent";
        }
    }

    // Severe Weather Alert Severity Color Mapping (D-52-14, D-52-15)
    function getAlertColor(severity) {
        if (!severity) return Appearance.m3colors.m3secondary;
        const s = String(severity).toLowerCase();
        if (s.includes("extreme") || s.includes("warning") || s.includes("danger")) {
            return Appearance.m3colors.m3error;
        }
        if (s.includes("severe") || s.includes("watch")) {
            return Appearance.m3colors.m3errorContainer;
        }
        return Appearance.m3colors.m3secondary;
    }
}
