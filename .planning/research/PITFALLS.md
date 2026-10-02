# Pitfalls Research

**Domain:** Desktop Shell Weather Telemetry & Visualization (Quickshell / Qt 6 / Linux)  
**Researched:** 2026-10-02  
**Confidence:** HIGH  

## Critical Pitfalls

### Pitfall 1: Free-Tier API Quota Exhaustion (500 calls/24 hours)

**What goes wrong:**  
WorldWeatherOnline returns HTTP 429 Too Many Requests or cuts off API access for 24 hours. The weather pill and popup show blank or error states.

**Why it happens:**  
Placing API fetch logic directly inside QML (e.g. `Timer` or `Component.onCompleted`). In development, every time a QML file is saved, Quickshell reloads the entire process tree. 30 reloads in an hour can burn 30 calls. Add multi-monitor bars or multiple `Weather.qml` instances and the 500-call daily quota is exhausted in a single afternoon.

**How to avoid:**  
1. Decouple network fetching entirely from Quickshell. Run an external background timer (e.g. Systemd user timer or Python cron) at a fixed 15–20 minute interval (72–96 calls/day max, well under the 500 limit).  
2. Quickshell only observes the local file `$XDG_RUNTIME_DIR/weather/weather.json` using `Quickshell.Io.FileView`.  
3. Quickshell reloads read from local cache with 0 API calls.

**Warning signs:**  
API call counter exceeding 100 in logs; HTTP 429 in fetcher output; `test_wwo.py` failing with unauthorized or rate-limit message.

**Phase to address:**  
Phase 1 (Decoupled Background Service & Local Cache).

---

### Pitfall 2: Partial File Read Race Conditions in `FileView`

**What goes wrong:**  
`WeatherService.qml` crashes or logs `SyntaxError: Unexpected end of JSON input` when reading the weather cache, setting weather properties to `undefined` and breaking UI bindings.

**Why it happens:**  
`Quickshell.Io.FileView` triggers an inotify event immediately when a file is modified. If the fetcher script writes data directly using `open('weather.json', 'w')`, `FileView` attempts to read while the write is still buffered in memory or half-flushed, reading an incomplete JSON payload.

**How to avoid:**  
Always perform **atomic file replacement**:  
Write the full payload to a temporary file on the same filesystem (e.g. `$XDG_RUNTIME_DIR/weather/weather.json.tmp.<PID>`), flush and close it, then call POSIX `os.replace()` / `mv`. Inotify will only fire on the atomic inode swap when the file is 100% complete and valid.

**Warning signs:**  
Intermittent JSON parse errors in `journalctl -u quickshell` or stderr right after the fetcher runs.

**Phase to address:**  
Phase 1 & Phase 2.

---

### Pitfall 3: Canvas Graph Over-Rendering & Idle CPU Churn

**What goes wrong:**  
Quickshell's quiescent idle CPU usage spikes back up to 5–15%, undoing the major optimization achievements of Milestone v0.9 (which drove quiescent CPU down to 1.68%).

**Why it happens:**  
Using continuous animation timers on Canvas plots, repainting while the popup is closed, or calling `requestPaint()` on every tiny mouse hover position change without integer/index quantization.

**How to avoid:**  
1. Gate Canvas painting strictly behind `root.active` (only paint when the popup is actually visible).  
2. Clamp graph hover scrub resolution to the discrete data points (24 hourly slots), requesting paint only when `hoveredIndex !== newIndex`.  
3. Clamping Canvas FPS (deadband 10 FPS max) as established in Phase 50 (`OPT-04`).

**Warning signs:**  
`scripts/profile-quickshell.sh` reporting CPU > 2.5% during stationary bar idle or popup inspection.

**Phase to address:**  
Phase 4 (Canvas Graph Components) & Phase 6 (Performance Regression).

---

### Pitfall 4: Missing or Misaligned WWO Weather Code Mappings

**What goes wrong:**  
Weather pill or popup displays a blank space, broken icon box, or fallback error icon for specific regional conditions (e.g. "Patchy light drizzle", "Blowing snow", or "Heavy freezing drizzle").

**Why it happens:**  
WWO defines over 40 distinct numeric `weatherCode` values (from 113 to 395). Relying on a small naive lookup table misses edge-case codes, especially when combined with daytime vs nighttime variants (`isdaytime: "no"`).

**How to avoid:**  
Construct a comprehensive dictionary mapper in `WeatherGlyphs.qml` covering all 40+ documented WWO weather codes, paired with explicit `isdaytime` day/night Material Symbol ligature mappings, and a verified graceful fallback (e.g. `cloud` or `partly_cloudy_day`).

**Warning signs:**  
Undefined icon properties or empty MaterialSymbol labels when testing against diverse mock weather conditions.

**Phase to address:**  
Phase 2 (Iconography & Glyph Mapping).

---

### Pitfall 5: Hardcoded Colors Breaking Material You / Matugen Theming

**What goes wrong:**  
Graph curves, grid lines, or text labels become invisible (e.g. dark gray on dark background) or visually jarring when switching wallpapers with Matugen dynamic palette generation.

**Why it happens:**  
Using hardcoded CSS color strings (e.g. `#A8C7FA`, `#FFFFFF`, `rgba(255, 255, 255, 0.08)`) inside Canvas 2D contexts or QML text labels.

**How to avoid:**  
Always derive Canvas stroke, fill, and text colors from `Appearance.colors` (e.g. `Appearance.colors.colPrimary`, `Appearance.colors.colSurface`, `Appearance.colors.colSubtext`). For alpha transparencies in Canvas, use helper functions to apply alpha dynamically: `Qt.rgba(c.r, c.g, c.b, alpha)`.

**Warning signs:**  
Testing wallpaper change (`switchwall.sh`) leaves graph text unreadable against the new background color scheme.

**Phase to address:**  
Phase 3, Phase 4, and Phase 5.

---
*Pitfalls research for: Desktop Shell Weather Telemetry & Visualization*  
*Researched: 2026-10-02*  
