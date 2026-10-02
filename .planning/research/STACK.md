# Stack Research

**Domain:** Desktop Shell Weather Telemetry & Visualization (Quickshell / Qt 6 / Linux)  
**Researched:** 2026-10-02  
**Confidence:** HIGH  

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| WorldWeatherOnline (WWO) API | v1 (premium/v1/weather.ashx) | Weather data provider | Rich parameter set (hourly breakdown `tp=1`, AQI EPA/PM2.5, official alerts, astronomy, 16-point wind, thermal indices). Reliable single-endpoint payload. |
| Python 3 (`urllib.request` / `json`) | 3.12+ (system python) | Decoupled background caching fetcher | Zero external dependency (standard library only), low overhead (<15MB RSS), fast execution (<500ms), safe atomic JSON file writing. |
| Systemd User Timer (`systemd --user`) | Systemd 256+ | Cadence scheduler (15–20 min) | Native Linux service management, handles suspend/resume cleanly, runs independently of compositor or Quickshell lifecycle. |
| Quickshell `FileView` | Quickshell 0.0.12+ / Qt 6.8 | Reactive inotify file observer | Zero IPC socket daemon overhead, non-blocking asynchronous file watching over tmpfs, auto-reloads state on file change without subshell spawning. |
| QtQuick Canvas (HTML5 2D API) | Qt 6.8 | Time-series curve & bar rendering | Native high-performance 2D drawing in QML for smooth Bezier/cardinal spline curves, linear gradient fills, gridlines, and hover scrubbers without heavy third-party plotting libraries. |
| Material Symbols Rounded | Variable font | Weather & diagnostic iconography | Matches existing desktop shell design language (`Appearance.font`, `MaterialSymbol`), scalable vector glyphs, dynamic palette coloring. |

### Supporting Libraries & System Services

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Python `tempfile` + `os.replace` | Stdlib | Atomic file replacement | Writing `$XDG_RUNTIME_DIR/weather/weather.json.tmp.$$` -> `weather.json` to prevent partial reads by Quickshell `FileView`. |
| GNU Stow | 2.4+ (`--no-folding`) | Symlink deployment | Overlaying `restow/quickshell/` into `~/.config/quickshell/ii/` without modifying `vendor/dots-hyprland`. |
| `jq` | 1.7+ | CLI test & JSON validation | Asserting schema validity in test harnesses (`scripts/phase51-weather-assert.sh`). |

### Development & Test Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| `test_wwo_api/test_wwo.py` | Local API validation & sandbox testing | Test harness validating query params, token handling, and raw response structure. |
| `scripts/phase51-weather-assert.sh` | Automated CI/regression harness | Verifies atomic caching, schema conformance, `FileView` reactivity, and zero git churn. |

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| Decoupled Python fetcher + tmpfs cache | In-QML `Quickshell.Io.Process` / `curl` | Acceptable only if no background timer is available, but risks exceeding the 500 calls/day free-tier limit whenever Quickshell is reloaded during development or testing. |
| Decoupled Python fetcher | Upstream `wttr.in` curl pipeline | `wttr.in` is heavily rate-limited, frequently times out or returns HTML errors, and lacks fine-grained hourly AQI and official severe weather alerts. |
| Native Canvas 2D graphing | QtGraphs / QML Charts module | QtCharts requires extra C++ plugin packages that are not consistently bundled or styled with Material You dynamic palettes. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Polling WWO API directly inside QML `Timer` | Quickshell reloads on file save; rapid iteration will quickly exhaust the 500 free-tier daily call limit (40 reloads = 40 wasted calls). | Decoupled background cache in `$XDG_RUNTIME_DIR/weather/weather.json` read via `FileView`. |
| Unthrottled continuous Canvas animation loops | Renders at 60–140 FPS and consumes 5–15% CPU, regressing Milestone v0.9 performance gains. | Event-driven painting: only paint on `onDataChanged`, popup `onActiveChanged`, or mouse hover scrub. |
| Hardcoded hex colors in QML weather widgets | Breaks Material You dynamic theming across wallpaper transitions. | Bind strictly to `Appearance.colors.col*` tokens. |
| External HTTP requests in test suites | Exceeds API quota and introduces flaky network dependencies. | Mock JSON fixtures (`test_wwo_api/raw_response.json`) in test assertions. |

## Stack Patterns by Variant

**If offline or network drops:**
- The background fetcher catches `URLError` / timeout and preserves the existing cached `weather.json`, marking `is_stale: true` and recording `last_attempt_error`.
- Quickshell continues rendering the cached forecast seamlessly while showing a subtle offline/stale status dot.

**If severe weather alert is returned (`alerts.alert.length > 0`):**
- Dynamic badge/marquee color transitions to `Appearance.colors.colError` or warning tone matching severity level (`Extreme`, `Severe`, `Moderate`).

## Sources

- WorldWeatherOnline Local Weather API documentation (`https://www.worldweatheronline.com/developer/api/docs/local-city-town-weather-api.aspx`)
- Quickshell Io documentation (`Quickshell.Io.FileView`, `Quickshell.Io.Process`)
- Local validation: `test_wwo_api/WEATHER_PARAMETERS.md` and `test_wwo_api/raw_response.json`

---
*Stack research for: Desktop Shell Weather Telemetry & Visualization*  
*Researched: 2026-10-02*  
