# Architecture Research

**Domain:** Desktop Shell Weather Telemetry & Visualization (Quickshell / Qt 6 / Linux)  
**Researched:** 2026-10-02  
**Confidence:** HIGH  

## Standard Architecture

### System Data Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       External Meteorological Source                         │
│                    WorldWeatherOnline API (WWO Premium)                     │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │ HTTP GET (every 15–20 min)
                                       │ Protected under 500 calls/day budget
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│               Decoupled Background Service Layer (Systemd / Python)         │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │ scripts/weather-fetch.py (Standard Library: urllib + json + os.replace)│  │
│  │ - Reads credentials from secure configuration                         │  │
│  │ - Queries WWO: format=json, tp=1, num_of_days=3, aqi=yes, alerts=yes  │  │
│  │ - Performs atomic file rename to prevent partial JSON read            │  │
│  └───────────────────────────────────┬───────────────────────────────────┘  │
└──────────────────────────────────────┼──────────────────────────────────────┘
                                       │ Atomic Write (${tmpfs}/weather.json.tmp -> weather.json)
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                 Linux In-Memory IPC Cache ($XDG_RUNTIME_DIR)                │
│                 $XDG_RUNTIME_DIR/weather/weather.json                       │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │ Inotify File-Watch Trigger
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                   Quickshell Presentation Layer (Qt 6 / QML)                │
│                                                                             │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │ WeatherService.qml (Singleton Service)                                │  │
│  │ - Quickshell.Io.FileView watching weather.json synchronously          │  │
│  │ - Parses raw JSON into structured models (current, hourly, aqi, etc.) │  │
│  │ - WeatherGlyphs.qml: Maps weatherCode + isDayTime -> Material Symbol  │  │
│  └──────────────────┬─────────────────────────────────┬──────────────────┘  │
│                     │                                 │                     │
│                     ▼                                 ▼                     │
│  ┌────────────────────────────────────┐ ┌────────────────────────────────┐  │
│  │ WeatherPill.qml (Status Bar)       │ │ WeatherPopup.qml (Inspector)   │  │
│  │ - BarGroup in Center Zone          │ │ - StyledPopup (1000ms delay)   │  │
│  │ - Dynamic condition glyph          │ │ - Hero card (Temp, condition)  │  │
│  │ - Current temperature (°C)         │ │ - Interactive Canvas Graph     │  │
│  │ - Rain/severe alert badge          │ │ - Atmospheric Metrics Grid     │  │
│  │ - M3 fluid width resizing          │ │ - AQI card & Astronomy Card    │  │
│  └────────────────────────────────────┘ └────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Implementation Details |
|-----------|----------------|------------------------|
| `scripts/weather-fetch.py` | API client & cache generator | Standalone Python 3 script using `urllib.request`. Enforces timeout, error handling, rate-limiting, and atomic file write. |
| `stow/systemd/.../wwo-weather.timer` | Scheduled cadence execution | Systemd user timer triggering every 15 minutes, with `Persistent=true` to fetch on boot/wake. |
| `WeatherService.qml` | Desktop shell state provider | Singleton instantiated once. Holds parsed reactive objects for `current`, `hourly24h`, `aqi`, `astronomy`, `alerts`, and `meta`. |
| `WeatherGlyphs.qml` | Meteorological iconography mapper | Pure JavaScript/QML function dictionary mapping WWO `weatherCode` (113–395) and `isdaytime` to Material Symbol ligature strings. |
| `WeatherPill.qml` | Status bar component | Placed in `BarContent.qml` Center Zone. Inherits `BarGroup` for standard pill styling, 12–16px radius, and fluid width transitions. |
| `WeatherPopup.qml` | Rich multi-modal inspector | Derived from `StyledPopup.qml`. Displays dual-column or tabbed views with interactive graphs, metrics, and alerts. |
| `WeatherGraph.qml` | Interactive time-series plot | Canvas 2D component with 24-slot data points, Bezier spline curves, linear gradient fills, and hover scrub detection. |

## Recommended Project File Layout

```
.
├── test_wwo_api/                                        # Reference & sandbox scripts
│   ├── WEATHER_PARAMETERS.md                            # Complete API parameter catalog
│   ├── raw_response.json                                # Mock payload fixture for test suites
│   └── test_wwo.py                                      # Standalone test runner
├── scripts/
│   ├── weather-fetch.py                                 # Production WWO fetcher & cache generator
│   └── phase51-weather-assert.sh                        # CI/regression test assertion harness
├── stow/
│   └── systemd/
│       └── .config/systemd/user/
│           ├── wwo-weather.service                      # Oneshot service executing weather-fetch.py
│           └── wwo-weather.timer                        # 15-minute scheduled timer unit
└── restow/
    └── quickshell/
        └── .config/quickshell/ii/
            ├── services/
            │   ├── WeatherService.qml                   # Primary weather singleton
            │   └── WeatherGlyphs.qml                    # Icon/glyph lookup helper
            └── modules/ii/bar/
                ├── BarContent.qml                       # Center Zone bar mount
                ├── weather/
                │   ├── WeatherPill.qml                  # Top status bar pill
                │   ├── WeatherPopup.qml                 # Main inspector popup (StyledPopup)
                │   ├── WeatherGraph.qml                 # Interactive Canvas time-series plot
                │   ├── WeatherMetricsGrid.qml           # Humidity, Pressure, Wind, UV grid
                │   ├── WeatherAqiCard.qml               # US-EPA air quality badge & PM2.5
                │   └── WeatherAstronomyCard.qml         # Sunrise/Sunset & Moon phase
```

## Architectural Patterns & Guarantees

1. **Strict Quota Isolation:**  
   Quickshell UI components *never* initiate external HTTP requests. They communicate exclusively with the local cache file in `$XDG_RUNTIME_DIR`. UI development, rapid code changes, and shell restarts cause 0 external network requests.

2. **Atomic Cache File Swaps:**  
   The background fetcher writes to a temporary file (`weather.json.tmp.<PID>`) and uses POSIX atomic rename (`os.replace`). This guarantees `Quickshell.Io.FileView` never reads a partially written or corrupt JSON document.

3. **Event-Driven UI Painting (No Render Loop Churn):**  
   `WeatherGraph.qml` executes `plotCanvas.requestPaint()` *only* when the popup opens, data arrives, or mouse cursor moves across the chart area. There are no continuous timers or idle render loops.

4. **Zero Upstream Submodule Drift:**  
   All QML components reside in `restow/quickshell/` and deploy as leaf symlinks via GNU Stow (`stow --no-folding`). Upstream `vendor/dots-hyprland` remains 100% untouched.

---
*Architecture research for: Desktop Shell Weather Telemetry & Visualization*  
*Researched: 2026-10-02*  
