# Phase 52: Weather Service Singleton & Material Glyph Mapping - Research

<user_constraints>
## User Constraints from 52-CONTEXT.md

### Locked Decisions

#### 1. Service Singleton Architecture
- **D-52-01:** Directly override upstream `Weather.qml` in `restow/quickshell/.config/quickshell/ii/services/Weather.qml`. Expose modern structured properties (`current`, `hourly`, `aqi`, `astronomy`, `alerts`) alongside a backward-compatible `Weather.data.*` facade so existing desktop widgets (`WeatherWidget.qml`) and legacy components operate seamlessly without code breakage. — **Reversibility:** costly — Downstream components and legacy widgets bind directly to `Weather.*`.
- **D-52-02:** Observe the cache file using `Quickshell.Io.FileView` with `watchChanges: true`, supplemented by a 60-second safety fallback `Timer` calling `fileView.reload()`. This ensures instantaneous reaction to filesystem inotify events while guaranteeing recovery if an atomic `os.replace` tempfile rename misses a watcher notification on certain Linux tmpfs kernels. — **Reversibility:** reversible
- **D-52-03:** Resolve cache path dynamically using `Quickshell.env("XDG_RUNTIME_DIR") + "/weather/weather.json"`. On cold boot or machine startup before the first background fetch completes, check and fall back to the persistent disk mirror at `~/.local/state/weather/last_known_weather.json` with `isStale: true`. — **Reversibility:** reversible
- **D-52-04:** Strictly passive cache observation — no manual refresh buttons or CLI process triggers in the UI. Network calls remain strictly managed by the background systemd timer (`wwo-fetcher.timer`) to prevent rate-limit exhaustion against the 500-call daily WWO quota. — **Reversibility:** reversible

#### 2. Reactive Data Normalization
- **D-52-05:** Structure reactive properties into logical groups on `Weather` root: `current` (temperature, apparent temperature, description, condition glyph, humidity, UV, wind, precipitation), `hourly` (24-item array), `aqi` (EPA index, PM2.5, PM10, color), `astronomy` (sunrise, sunset, moon phase), `alerts` (array of active severe alerts), and status flags (`isStale`, `isOffline`, `lastRefresh`). — **Reversibility:** costly — Downstream QML pills (Phase 53), graphs (Phase 54), and popups (Phase 55) bind directly to these schema properties.
- **D-52-06:** Store the 24-slot hourly forecast array (`root.hourly`) as raw JSON objects with original strings preserved. Downstream Canvas 2D graph components (Phase 54) and popups parse numeric coordinates on-demand using `parseInt` / `parseFloat`, avoiding eager memory allocations and garbage collection thrashing in the service. — **Reversibility:** reversible
- **D-52-07:** Expose strictly Celsius and Metric values throughout the service (Celsius, km/h, mm, hPa). No USCS / Imperial conversion logic or configuration switches in `Weather.qml`. — **Reversibility:** reversible
- **D-52-08:** Initialize all property groups with safe placeholder defaults (`tempC: "--"`, `desc: "Offline"`, `glyph: "cloud_off"`, `hourly: []`, `alerts: []`, `aqi: { epaIndex: 0, category: "Unavailable", color: "transparent" }`) to eliminate QML `TypeError: cannot read property of null` console spam during cold boot or offline states. — **Reversibility:** reversible

#### 3. Material Symbols Glyph Mapping
- **D-52-09:** Package meteorological iconography in a dedicated singleton `WeatherGlyphs.qml` at `restow/quickshell/.config/quickshell/ii/services/WeatherGlyphs.qml`. Expose helper method `getGlyph(weatherCode, isDaytime)` and pre-bind `Weather.current.glyph` for zero-boilerplate consumption in status bar components. — **Reversibility:** reversible
- **D-52-10:** Implement a two-level dictionary mapping all 40+ WWO condition codes (113–395). For sky conditions where daylight affects appearance (113 Clear, 116 Partly Cloudy), branch by `isdaytime` (`clear_day` vs `clear_night`, `partly_cloudy_day` vs `partly_cloudy_night`). For sky-obscuring conditions (rain, thunderstorms, fog, snow, sleet), use universal condition ligatures (`rainy`, `thunderstorm`, `foggy`, `cloudy_snowing`, `weather_hail`). — **Reversibility:** reversible
- **D-52-11:** Default to `"cloud"` as the universal neutral fallback glyph for any unknown, invalid, or missing weather code, matching upstream `Icons.qml` conventions. — **Reversibility:** reversible
- **D-52-12:** Centralize standardized Material Symbols ligatures in `WeatherGlyphs.qml` for atmospheric and celestial metrics: humidity (`water_drop`), pressure (`speed`), UV index (`wb_sunny`), visibility (`visibility`), wind speed (`air`), sunrise (`wb_twilight`), sunset (`bedtime`), and severe weather alerts (`warning`). — **Reversibility:** reversible

#### 4. Theme Color Tokens for AQI & Alerts
- **D-52-13:** Map US-EPA Air Quality Index (1–6) using the standard international meteorological color spectrum tuned for Material You background contrast: EPA 1 Good (Green), EPA 2 Moderate (Yellow), EPA 3 Unhealthy for Sensitive Groups (Orange), EPA 4 Unhealthy (Red), EPA 5 Very Unhealthy (Purple), EPA 6 Hazardous (Maroon). — **Reversibility:** reversible
- **D-52-14:** Implement a three-tier severity hierarchy for meteorological alerts: Warning / Extreme → `Appearance.m3colors.m3error` (pulsing/accent red), Watch / Severe → Amber (`Appearance.m3colors.m3errorContainer`), Advisory / Statement → Subtle informative (`Appearance.m3colors.m3secondary` / `m3tertiary`). — **Reversibility:** reversible
- **D-52-15:** Place color calculation methods in `WeatherGlyphs.qml` (`getAqiColor(epaIndex)`, `getAlertColor(severity)`) and pre-bind computed color tokens directly onto `Weather.aqi.color` and `Weather.alerts[i].color`. — **Reversibility:** reversible
- **D-52-16:** Visually communicate stale or offline data by dimming text and glyph colors using `Appearance.m3colors.m3onSurfaceVariant` or `m3outline` and presenting a small `cloud_off` indicator, maintaining readability without jarring alarms. — **Reversibility:** reversible

### the agent's Discretion
- Exact fallback poll timer interval (60s chosen for zero measurable CPU overhead).
- Internal regex and string parsing helpers inside `Weather.qml` for the legacy `Weather.data.*` compatibility bridge.
- Specific hex shades for the 6 international AQI levels to ensure high legibility against dark Material You container backgrounds.

### Deferred Ideas
- None — all discussion items remained strictly within Phase 52 scope.

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Requirement | Research Support & Implementation Approach |
| :--- | :--- | :--- |
| **GLYPH-01** | `WeatherService.qml` / `Weather.qml` singleton observes the local cache file via reactive `Quickshell.Io.FileView` with non-blocking updates and zero external API calls on desktop shell reload. | Personal overlay at `restow/quickshell/.config/quickshell/ii/services/Weather.qml` directly overrides upstream `Weather.qml` [VERIFIED: `vendor/.../services/Weather.qml:1`]. Uses `FileView` watching `$XDG_RUNTIME_DIR/weather/weather.json` with `watchChanges: true`, backed by a 60s fallback poll timer [VERIFIED: `MaterialThemeLoader.qml:61-74`]. 0 child processes spawned and 0 network requests made from QML. |
| **GLYPH-02** | Comprehensive `WeatherGlyphs.qml` dictionary mapper converts all 40+ WWO condition codes (`weatherCode` 113–395) to Material Symbols ligature strings with verified fallbacks. | Dedicated singleton at `restow/.../services/WeatherGlyphs.qml` catalogs all 59 official WWO condition codes from the authoritative specification (`wwoConditionCodes.txt`) [VERIFIED: `wwoConditionCodes.txt:10-69`], including the 15+ codes missing from upstream `Icons.qml` (such as Dhaka's active code 149 "Smoky haze"). Unmapped or missing codes fall back safely to `"cloud"` [VERIFIED: `Icons.qml:109`]. |
| **GLYPH-03** | Daytime vs. nighttime glyph switching dynamically driven by WWO `isdaytime` field across all weather conditions. | Two-level condition dictionary branching codes 113 (`clear_day` vs `clear_night`) and 116 (`partly_cloudy_day` vs `partly_cloudy_night`). `WeatherGlyphs.getGlyph(code, isDaytime)` normalizes both boolean and `"yes"`/`"no"` string values from WWO API [VERIFIED: `raw_response.json:47`]. Obscuring phenomena (rain, snow, fog, storms) map to universal ligatures. |
| **GLYPH-04** | Health and severity color mapping assigning Material You palette tokens (`Appearance.m3colors.*`) to air quality levels (US-EPA) and severe weather alerts. | `WeatherGlyphs.getAqiColor(epaIndex)` returns high-contrast international EPA AQI colors (Green, Yellow, Orange, Red, Purple, Maroon). `WeatherGlyphs.getAlertColor(severity)` returns Material You theme tokens (`Appearance.m3colors.m3error`, `m3errorContainer`, `m3secondary`) [VERIFIED: `Appearance.qml:73-75`]. Pre-bound onto `Weather.aqi.color` and `Weather.alerts[i].color`. Stale/offline state uses `Appearance.m3colors.m3outline` and `cloud_off`. |
</phase_requirements>

---

## Summary

Phase 52 establishes the core presentation data pipeline for weather telemetry in the Quickshell desktop environment. It decouples the UI from network operations by replacing the legacy upstream `Weather.qml` service—which spawned unconstrained `bash` subshells and direct `curl wttr.in` requests [VERIFIED: `vendor/.../Weather.qml:84-127`]—with a purely event-driven, non-blocking service singleton consuming the local atomic JSON cache (`$XDG_RUNTIME_DIR/weather/weather.json`) written by the Phase 51 Python fetcher (`wwo-fetcher.py`).

Key findings during investigation:
1. **Critical Code Gap in Upstream:** Upstream `dots-hyprland`'s `Icons.qml` only maps 44 codes and omits the entire haze/dust/smoke/smog series (codes 125, 128, 131, 134, 137, 140, 146, 149, 152, 155, 158, 161) [VERIFIED: `Icons.qml:54-103` vs `wwoConditionCodes.txt:14-26`]. In fact, live queries in Dhaka currently report `weatherCode: "149"` ("Smoky haze"), which upstream fails to map and displays as missing. `WeatherGlyphs.qml` must implement the complete 59-code specification.
2. **Legacy Consumer Contracts:** Background widgets (`WeatherWidget.qml`) [VERIFIED: `WeatherWidget.qml:36`] and bar components bind directly to `Weather.data.temp` and perform string slicing (`temp.substring(0, temp.length - 1)`). To prevent crashes, `Weather.qml` must provide a full backward compatibility facade (`Weather.data.*`) with safe initial defaults like `temp: "--°C"`.
3. **Reactive Inotify Mechanics:** Because the background fetcher replaces the cache via `os.replace` (atomic inode change) [VERIFIED: `wwo-fetcher.py:124`], `Quickshell.Io.FileView` with `watchChanges: true` needs an explicit `.reload()` call on `onFileChanged` alongside a 60-second fallback timer to guarantee update propagation across all Linux tmpfs kernel variations [VERIFIED: `MaterialThemeLoader.qml:65-68`].

---

## Architectural Responsibility Map

The weather subsystem operates in four distinct tiers:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ Tier 1: Ingestion & Telemetry Daemon (Phase 51)                             │
│   wwo-fetcher.py + wwo-fetcher.timer                                        │
│   • Enforces rate budget (≤ 470 calls/day, min 3m pacing)                  │
│   • Atomically writes $XDG_RUNTIME_DIR/weather/weather.json                 │
│   • Mirrors to ~/.local/state/weather/last_known_weather.json                │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │ POSIX filesystem / tmpfs
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ Tier 2: Quickshell Reactive File Observer (Phase 52)                        │
│   Quickshell.Io.FileView inside Weather.qml                                 │
│   • watchChanges: true (inotify kernel events)                              │
│   • 60s fallback Timer (safety catch for atomic rename inodes)              │
│   • Cold boot fallback to persistent state mirror if runtime cache is empty │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │ Internal JS JSON parser & binding
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ Tier 3: Service Singletons & Glyph Engine (Phase 52)                        │
│   Weather.qml (Data Store & Compatibility Bridge)                           │
│   ├── Structured groups: current, hourly, aqi, astronomy, alerts, isStale  │
│   └── Legacy facade: Weather.data.* (temp, wCode, city, humidity, etc.)     │
│   WeatherGlyphs.qml (Iconography & Color Tokens)                            │
│   ├── getGlyph(weatherCode, isDaytime) -> Material Symbol ligature         │
│   ├── getAqiColor(epaIndex) & getAqiCategory(epaIndex)                      │
│   ├── getAlertColor(severity) -> Appearance.m3colors.* token                │
│   └── Metric glyph constants (water_drop, speed, air, wb_twilight, etc.)    │
└──────────────────┬───────────────────────────────────────┬──────────────────┘
                   │                                       │
        ┌──────────┴──────────┐                 ┌──────────┴──────────┐
        ▼                     ▼                 ▼                     ▼
┌───────────────┐     ┌───────────────┐ ┌───────────────┐     ┌───────────────┐
│ Status Bar    │     │ Legacy Widget │ │ Canvas Graphs │     │ Popup Drawer  │
│ WeatherPill   │     │ WeatherWidget │ │ WeatherGraph  │     │ WeatherPopup  │
│ (Phase 53)    │     │ (Dots Upstr.) │ │ (Phase 54)    │     │ (Phase 55)    │
└───────────────┘     └───────────────┘ └───────────────┘     └───────────────┘
```

---

## Standard Stack

| Technology / Component | Source / Module | Purpose |
| :--- | :--- | :--- |
| `Quickshell.Io.FileView` | `import Quickshell.Io` [VERIFIED: `MaterialThemeLoader.qml:7`] | Inotify-backed reactive file loading and string extraction (`fileView.text()`) without spawning child processes. |
| `Quickshell.Singleton` | `import Quickshell` [VERIFIED: `Voice.qml:6-9`] | Base class for globally accessible QML singletons with `pragma Singleton`. |
| `pragma ComponentBehavior: Bound` | QML Engine [VERIFIED: `Weather.qml:2`] | Strict component scoping and compile-time binding validation in Qt 6 / Quickshell. |
| `Appearance.m3colors` | `import qs.modules.common` [VERIFIED: `Appearance.qml:37-109`] | Reactive Material You color tokens (`m3error`, `m3errorContainer`, `m3secondary`, `m3tertiary`, `m3onSurfaceVariant`, `m3outline`, `m3success`). |
| Material Symbols Font | Google Material Symbols Rounded [VERIFIED: `MaterialSymbol.qml:12`] | Font ligature system rendering icons through text labels (e.g. `clear_day`, `water_drop`). |
| GNU Stow Overlay | `restow/quickshell` package [VERIFIED: `bootstrap.sh:561-571`] | Leaf symlink overlay mechanism deploying personal services over vendor dots without git churn. |

---

## Architecture Patterns

### Pattern 1: Reactive FileView with Fallback Timer & Cold-Boot Defaults

**Goal:** Monitor the cache file with 0 CPU overhead at rest, instant response on updates, resilience against missed inotify events during atomic file replacement, and zero null reference errors on startup.

**Mechanism:**
1. Configure primary `FileView` pointing to `$XDG_RUNTIME_DIR/weather/weather.json`. Set `watchChanges: true`, `blockLoading: true`, and `printErrors: false` [VERIFIED: `Voice.qml:55-60`].
2. Configure secondary `FileView` pointing to `~/.local/state/weather/last_known_weather.json`.
3. In `onFileChanged`, invoke `this.reload()` followed by JSON parsing.
4. Add a 60,000 ms (60s) `Timer` that calls `runtimeCacheFile.reload()`.
5. On cold boot or when cache is empty/invalid, populate all properties with safe placeholder defaults.

```qml
// Pattern 1 implementation snippet
readonly property string runtimeDir: {
    const xdg = Quickshell.env("XDG_RUNTIME_DIR");
    return (xdg && xdg.length > 0) ? xdg : ("/run/user/" + Quickshell.env("UID"));
}
readonly property string cachePath: runtimeDir + "/weather/weather.json"

FileView {
    id: cacheFile
    path: root.cachePath
    watchChanges: true
    blockLoading: true
    printErrors: false

    onFileChanged: {
        cacheFile.reload();
        root.parseCache();
    }
    onLoadedChanged: root.parseCache()
}

Timer {
    interval: 60000
    repeat: true
    running: true
    onTriggered: cacheFile.reload()
}
```

### Pattern 2: Two-Level Weather Code Glyph Dictionary with Day/Night Awareness

**Goal:** Map all 59 WWO condition codes (113–395) to standard Material Symbols Rounded ligatures, dynamically distinguishing between daytime and nighttime for sky conditions, and falling back safely to `"cloud"`.

**Mechanism:**
Dictionary values are either a direct string ligature (for condition-obscured sky like rain or snow) or a two-property object `{ day: "...", night: "..." }` for clear/partly cloudy conditions [VERIFIED: `52-CONTEXT.md:108`].

```javascript
// Pattern 2 implementation snippet
readonly property var glyphMap: ({
    "113": { day: "clear_day", night: "clear_night" },
    "116": { day: "partly_cloudy_day", night: "partly_cloudy_night" },
    "119": "cloud",
    "122": "cloud",
    "125": "foggy", // Haze
    "143": "foggy", // Mist
    "146": "foggy", // Smoke
    "149": "foggy", // Smoky haze (Dhaka active)
    "152": "foggy", // Smog
    "176": "rainy", // Patchy rain nearby
    "200": "thunderstorm",
    "230": "snowing_heavy",
    "248": "foggy",
    "296": "rainy", // Light rain
    "308": "weather_hail", // Heavy rain
    // ... complete 59 codes cataloged
})

function getGlyph(code, isDaytime) {
    const key = String(code);
    const isDay = (isDaytime === true || isDaytime === "yes" || isDaytime === 1 || isDaytime === "1");
    if (glyphMap.hasOwnProperty(key)) {
        const val = glyphMap[key];
        if (typeof val === "object" && val !== null) {
            return isDay ? val.day : val.night;
        }
        return val;
    }
    return "cloud"; // Universal fallback (D-52-11)
}
```

### Pattern 3: Legacy Compatibility Bridge for `Weather.data.*`

**Goal:** Allow upstream `WeatherWidget.qml` and `WeatherBar.qml` to continue functioning seamlessly without code alterations [VERIFIED: `WeatherWidget.qml:36-48`].

**Mechanism:**
Expose a reactive `property var data` that mirrors the exact property names and string formats produced by upstream `Weather.qml.refineData()`:
- `temp`: formatted as `"XX°C"` (so `temp.substring(0, temp.length - 1)` yields `"XX°"`).
- `tempFeelsLike`: formatted as `"XX°C"`.
- `wCode`: string weather code (e.g. `"113"`).
- `wind`: formatted as `"X km/h"`.
- `precip`: formatted as `"X.X mm"`.
- `humidity`: formatted as `"XX%"`.
- `visib`: formatted as `"X km"`.
- `press`: formatted as `"XXXX hPa"`.
- `getData()`: exposed as a safe no-op that reloads the cache rather than executing bash curls.

### Pattern 4: Material You Theme Color Mapping for AQI & Alerts

**Goal:** Assign international standard meteorological colors for AQI and Material You theme tokens for alerts, ensuring high contrast on dark container surfaces.

**Mechanism:**
1. **US-EPA AQI (1–6):**
   - EPA 1 Good: `#81C784` (Green 300 / high contrast)
   - EPA 2 Moderate: `#FFD54F` (Amber 300)
   - EPA 3 Unhealthy for Sensitive Groups: `#FF9800` (Orange 500)
   - EPA 4 Unhealthy: `#E53935` (Red 600)
   - EPA 5 Very Unhealthy: `#BA68C8` (Purple 400)
   - EPA 6 Hazardous: `#880E4F` (Maroon 900 / Deep Pink)
2. **Alert Severity Hierarchy:**
   - Extreme / Warning: `Appearance.m3colors.m3error` (`#ffb4ab`) [VERIFIED: `Appearance.qml:73`]
   - Severe / Watch: `Appearance.m3colors.m3errorContainer` (`#93000a`) [VERIFIED: `Appearance.qml:75`]
   - Moderate / Minor / Advisory: `Appearance.m3colors.m3secondary` (`#cac5c8`) [VERIFIED: `Appearance.qml:65`]

---

## Don't Hand-Roll

| Component / Task | Why Not Custom? | Standard Solution |
| :--- | :--- | :--- |
| Network fetching in QML | Spawns heavy bash/curl child processes, risks exceeding 500 calls/day quota, and slows down shell startup [VERIFIED: `52-CONTEXT.md:36`]. | Strictly rely on Phase 51 background systemd fetcher (`wwo-fetcher.service`). |
| File change polling loops | A tight timer loop polling files spikes CPU and wakes up the processor continuously [VERIFIED: `Phase 49 Empirical Audit`]. | Use `Quickshell.Io.FileView` with `watchChanges: true` (inotify kernel events) and a slow 60s fallback timer. |
| In-app weather icon PNGs | Vector or raster weather images require packaging, scaling, asset loading, and disk I/O. | Use Google Material Symbols Rounded ligatures directly through text strings in `MaterialSymbol.qml` [VERIFIED: `MaterialSymbol.qml:12`]. |
| Imperative USCS unit conversions | Adds state complexity and arithmetic bugs into data model [VERIFIED: `52-CONTEXT.md:41`]. | Strictly standardize on Celsius and Metric units (Celsius, km/h, mm, hPa). |
| Custom theme color generation | Hardcoding custom themes desynchronizes weather cards from wallpaper palette shifts. | Bind directly to dynamic Material You tokens (`Appearance.m3colors.*`) [VERIFIED: `Appearance.qml:37-109`]. |

---

## Common Pitfalls

### 1. Inotify Inode Invalidation on Atomic Replacement (`os.replace`)
- **Problem:** `wwo-fetcher.py` writes data to `weather.json.tmp.<pid>` and calls `os.replace` to rename it to `weather.json` [VERIFIED: `wwo-fetcher.py:124`]. On Linux, `rename()` swaps the directory entry to a new inode. Some inotify implementations watching the specific file descriptor rather than directory notifications can stop receiving updates after the first rename.
- **Solution:** Configure `watchChanges: true`, explicitly call `this.reload()` inside the `onFileChanged` signal handler, and run a 60-second safety fallback timer [VERIFIED: `52-CONTEXT.md:34`].

### 2. Null Reference Errors on Cold Boot
- **Problem:** When Quickshell boots before the fetcher runs, or during an offline network drop, `data` is `null` [VERIFIED: `wwo-fetcher.py:186`]. Direct bindings like `Weather.current.tempC` or `Weather.data.temp.substring(...)` will crash with `TypeError: cannot read property of null` and flood systemd journals.
- **Solution:** Initialize root properties with full placeholder objects (`tempC: "--"`, `desc: "Offline"`, `glyph: "cloud_off"`, `hourly: []`, `alerts: []`, `data: { temp: "--°C", ... }`) [VERIFIED: `52-CONTEXT.md:42`].

### 3. Slicing Assumptions in Legacy `WeatherWidget.qml`
- **Problem:** `WeatherWidget.qml` executes `Weather.data?.temp.substring(0, Weather.data?.temp.length - 1)` [VERIFIED: `WeatherWidget.qml:36`]. If `Weather.data.temp` is initialized as `""` or `"--"`, `substring(0, -1)` throws or produces `"-"`.
- **Solution:** Default `Weather.data.temp` to `"--°C"`. Slicing off the last character (`length - 1`) cleanly evaluates to `"--°"`.

### 4. String vs Boolean in WWO `isdaytime`
- **Problem:** WorldWeatherOnline API returns `isdaytime` as a string (`"yes"` or `"no"`) [VERIFIED: `raw_response.json:47`]. Strict equality checks like `isDaytime === true` evaluate to `false` if passed raw strings.
- **Solution:** In `WeatherGlyphs.getGlyph()`, normalize the flag: `const isDay = (isDaytime === true || isDaytime === "yes" || isDaytime === 1 || isDaytime === "1");`.

### 5. GNU Stow Symlink Conflicts with Existing Vendor Files
- **Problem:** `~/.config/quickshell/ii/services/Weather.qml` currently exists as a regular file from the base vendor setup [VERIFIED: `ls -la ~/.config/quickshell/ii/services/Weather.qml`]. Running `stow` without preparing the target causes a conflict error.
- **Solution:** Follow the repository pattern established for `Audio.qml.bak` and `Updates.qml.bak` [VERIFIED: `ls -la ~/.config/quickshell/ii/services/`]: move the vendor file to `Weather.qml.bak` before creating the leaf symlink from `restow/quickshell`.

---

## Code Examples

### 1. `WeatherGlyphs.qml` Singleton

```qml
// Location: restow/quickshell/.config/quickshell/ii/services/WeatherGlyphs.qml
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

    // Authoritative 59-Code WWO Mapping Table (wwoConditionCodes.txt)
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
        "149": "foggy", // Smoky haze (Dhaka current)
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

    function getGlyph(code, isDaytime) {
        if (!code) return glyphDefault;
        const key = String(code);
        const isDay = (isDaytime === true || isDaytime === "yes" || isDaytime === 1 || isDaytime === "1");
        if (glyphMap.hasOwnProperty(key)) {
            const entry = glyphMap[key];
            if (typeof entry === "object" && entry !== null) {
                return isDay ? entry.day : entry.night;
            }
            return entry;
        }
        return glyphDefault;
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

    // US-EPA Air Quality Index Color Mapping (D-52-13)
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

    // Severe Weather Alert Severity Color Mapping (D-52-14)
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
```

### 2. `Weather.qml` Service Singleton

```qml
// Location: restow/quickshell/.config/quickshell/ii/services/Weather.qml
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

        root.current = {
            tempC: cur.temp_C ? parseInt(cur.temp_C) : "--",
            tempFeelsLikeC: cur.FeelsLikeC ? parseInt(cur.FeelsLikeC) : "--",
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
            isDaytime: (isDayStr === "yes" || isDayStr === true)
        };

        // 2. Hourly Forecast Array (Raw Preserved JSON) (D-52-06)
        root.hourly = weather0.hourly || [];

        // 3. Air Quality
        const epa = parseInt(aq["us-epa-index"] || 0);
        root.aqi = {
            epaIndex: epa,
            category: WeatherGlyphs.getAqiCategory(epa),
            pm2_5: aq.pm2_5 || "--",
            pm10: aq.pm10 || "--",
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
            temp: (cur.temp_C || "--") + "°C",
            tempFeelsLike: (cur.FeelsLikeC || "--") + "°C",
            lastRefresh: root.lastRefresh
        };
    }

    Component.onCompleted: {
        root.loadCache();
    }
}
```

---

## Validation Architecture

### 1. Multi-Section Assert Harness (`scripts/phase52-weather-assert.sh`)

Following the strict regression testing standard of Phase 46 and Phase 51 [VERIFIED: `scripts/phase46-telemetry-assert.sh:1-120`], Phase 52 will provide an automated test harness covering:

- **Section 1: Stow Packaging & Symlink Topology (INTG-02, D-52-01)**
  - Assert `restow/quickshell/.config/quickshell/ii/services/Weather.qml` exists.
  - Assert `restow/quickshell/.config/quickshell/ii/services/WeatherGlyphs.qml` exists.
  - Assert `~/.config/quickshell/ii/services/Weather.qml` is a valid symlink pointing to the restow overlay.
  - Assert `~/.config/quickshell/ii/services/WeatherGlyphs.qml` is a valid symlink pointing to the restow overlay.
  - Assert vendor backup `Weather.qml.bak` exists in `~/.config/quickshell/ii/services/`.

- **Section 2: Code Dictionary Coverage (GLYPH-02, GLYPH-03)**
  - Extract `glyphMap` via Node.js or Python test runner.
  - Verify all 59 WWO condition codes (from `wwoConditionCodes.txt`) are present.
  - Verify day/night resolution for codes 113 (`clear_day` / `clear_night`) and 116 (`partly_cloudy_day` / `partly_cloudy_night`).
  - Verify neutral fallback returns `"cloud"` for unknown codes (e.g. 999, "", null).

- **Section 3: Color & Severity Mapping (GLYPH-04)**
  - Test `getAqiCategory` and `getAqiColor` across indices 1 to 6 and invalid inputs.
  - Test `getAlertColor` for "Warning", "Extreme", "Watch", "Severe", "Advisory", "Minor".
  - Verify tokens match `Appearance.m3colors.m3error` and `Appearance.m3colors.m3errorContainer`.

- **Section 4: Reactive Schema & Legacy Facade Invariants (GLYPH-01, D-52-01, D-52-08)**
  - Parse real `$XDG_RUNTIME_DIR/weather/weather.json` using the parsing logic.
  - Assert `Weather.data.temp` format matches `"[0-9]+°C"` so `temp.substring(0, temp.length - 1)` succeeds.
  - Assert `Weather.current` contains all 13 standard fields without `undefined`.
  - Assert cold-boot defaults prevent `null` dereferences when `data: null`.

- **Section 5: Live Quickshell Log & Zero-Error Check (INTG-04)**
  - Inspect `quickshell log --config ii` for any `TypeError`, `ReferenceError`, or QML syntax warnings associated with `Weather.qml` or `WeatherGlyphs.qml`.
  - Ensure zero network subshell spawns (verify no `curl wttr.in` or child bash calls in process tree).

---

## Security Domain

### Threat Modeling & ASVS Alignment

| Threat ID | Threat Category | Risk Description | Mitigation Strategy |
| :--- | :--- | :--- | :--- |
| **T-52-01** | Input Validation (ASVS V5.1) | Malformed JSON in cache crashes QML or executes prototype pollution | JSON parsing is strictly wrapped in `try / catch`. Schema validation uses optional chaining and defaults; no `eval()` or unvalidated property assignment. |
| **T-52-02** | Cache Tampering / Injection | Local unprivileged user modifies cache file to inject misleading alerts | Cache is stored in `$XDG_RUNTIME_DIR/weather/weather.json` (filesystem permissions `0700` owned by operator user) [VERIFIED: `wwo-fetcher.py:28`]. |
| **T-52-03** | Denial of Service / CPU Spikes | Fast timer loops or live external curl spawns saturate CPU and throttle desktop | Eliminates upstream's `Process` curl subshell [VERIFIED: `vendor/.../Weather.qml:111-127`]. Employs passive `FileView` inotify observation and a 60s fallback timer (CPU impact $\le 0.01\%$). |
| **T-52-04** | Secret Leakage | API key or token accidentally read by UI service | `Weather.qml` has no access to `WWO_API_KEY` or `~/.config/weather/.env`; secrets remain strictly isolated within Phase 51 background fetcher. |

---

*Phase: 52-Weather Service Singleton & Material Glyph Mapping*
*Research completed: 2026-10-03*
