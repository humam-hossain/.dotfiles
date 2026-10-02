# Feature Research

**Domain:** Desktop Shell Weather Telemetry & Visualization (Quickshell / Qt 6 / Linux)  
**Researched:** 2026-10-02  
**Confidence:** HIGH  

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist in a modern desktop weather module. Missing these makes the component feel incomplete or unpolished.

| Feature | Why Expected | Complexity | Implementation Notes |
|---------|--------------|------------|----------------------|
| Current Ambient Temperature (`temp_C`) | Core purpose of a weather pill. | LOW | Formatted as integer degrees `XX°C` on status bar pill. |
| Dynamic Weather Condition Glyph | Visual cue of current sky condition (Sunny, Cloudy, Rainy, Stormy). | LOW | Mapped from WWO `weatherCode` to Material Symbols font glyphs. |
| Day / Night Icon Switching (`isdaytime`) | Showing a sun at 2 AM is jarring; night requires moon/star variants. | LOW | Checked via WWO `isdaytime` field (`"yes"` vs `"no"`) to swap glyphs. |
| Status Bar Pill Integration | Fits into Center Zone layout flanking Workspaces with uniform 4px margins. | LOW | Implements `BarGroup` with M3 emphasized deceleration width resizing animation. |
| Decoupled Local File Cache | Protects the 500 calls/day free-tier API budget from shell reloads. | MEDIUM | Background timer writes `$XDG_RUNTIME_DIR/weather/weather.json` every 15–20 mins; read via `FileView`. |
| Popup Hero Weather Card | Primary view upon hovering/clicking pill. | LOW | City/neighborhood, current condition text (`weatherDesc`), large temperature, and `FeelsLikeC`. |
| Core Atmospheric Metrics Grid | Humidity, Pressure, Wind Speed, UV Index. | MEDIUM | Compact 2x2 or 2x3 metrics grid with descriptive icons and localized units (km/h, hPa, %). |

### Differentiators (Competitive Advantage)

Features that elevate this implementation above standard minimalist status bar plugins (like stock Waybar or basic wttr.in scripts).

| Feature | Value Proposition | Complexity | Implementation Notes |
|---------|-------------------|------------|----------------------|
| Interactive 24-Hour Temperature Canvas Curve | Visualizes thermal progression across the entire day with smooth Bezier curves and hover scrub readouts. | MEDIUM | Canvas 2D plot with grid lines, gradient area fill, min/max bounds, and interactive cursor point inspection. |
| Hourly Rain Probability & Volume Graph | Instant visual prediction of whether and when it will rain today (`chanceofrain` % + `precipMM`). | MEDIUM | Dual-axis or stacked bar/line visualization showing precipitation probability curve alongside rain volume. |
| Air Quality Index (AQI) Health Card | Real-time pollution tracking (`us-epa-index` 1–6 and `pm2_5` µg/m³). | LOW | Color-coded health badge (Green=Good, Yellow=Moderate, Orange=Unhealthy for sensitive, Red=Unhealthy, Purple=Hazardous). |
| Dynamic Wind Compass | Meteorological precision with rotating arrow/needle matching exact degrees. | LOW | Rotates compass needle icon via `winddirDegree` (0–360°) with 16-point textual direction (`winddir16Point`). |
| Astronomy & Lunar Phase Card | Golden hour and night sky tracking. | LOW | Sunrise and sunset times with daytime progress gauge, plus lunar phase name and illumination % graphic. |
| Severe Weather Alert Banner | Immediate life-safety awareness during storms, floods, or extreme heat. | MEDIUM | Renders an alert strip at the top of the popup only when WWO `alerts.alert` is non-empty, glowing with severity color. |
| Thermal Comfort Detail | Deeper insight into how the air actually feels. | LOW | Displays Heat Index, Dew Point, and Wind Chill when divergence from ambient temp is significant. |

### Anti-Features (Commonly Requested, Often Problematic)

Features that seem appealing initially but create performance, quota, or UX issues.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Direct API polling inside QML on startup | Simpler single-process architecture. | Every time the user edits QML and Quickshell hot-reloads, an external API call is burned. 40 reloads during dev burns 10% of daily quota. | Decoupled background service writing to `$XDG_RUNTIME_DIR/weather/weather.json`; QML reads via `FileView`. |
| Embedded animated radar maps in popup | Visually striking radar GIFs. | Heavy bandwidth consumption, high memory/FBO thrashing in Quickshell, slow loading times. | Clickable web link to WWO radar map in default browser (`nearest_area.weatherUrl`). |
| Permanent multi-city ticker in status bar | Monitoring multiple cities at once. | Clutters the top status bar and exhausts screen real estate on 1080p monitors. | Focus status bar on primary location; provide city switcher or expand secondary locations inside popup. |
| Continuous 60 FPS graph pulsing / particle rain effects | "Live" aesthetic effects. | Constant GPU redraw causes idle power consumption and laptop battery drain, regressing Milestone v0.9 optimizations. | Clean static Canvas rendering that redraws only on data change, popup open, or active mouse hover. |

## Feature Dependencies

```
[Decoupled WWO Fetcher Service]
    └──writes──> [$XDG_RUNTIME_DIR/weather/weather.json]
                     └──read_by──> [WeatherService.qml Singleton]
                                       ├──binds──> [WeatherPill.qml (Top Bar)]
                                       │               └──anchors──> [WeatherPopup.qml]
                                       │                                 ├──contains──> [Temperature Canvas Curve]
                                       │                                 ├──contains──> [Rain Probability Graph]
                                       │                                 ├──contains──> [Atmospheric Metrics Grid]
                                       │                                 ├──contains──> [AQI Card]
                                       │                                 └──contains──> [Astronomy / Alerts]
                                       └──binds──> [WeatherGlyphMapper.qml]
```

## MVP Definition (Milestone v0.10)

### Phase 1: Background Fetcher & Local Cache Engine
- [ ] Standalone Python 3 fetcher script reading WWO API key from secure configuration
- [ ] Rate-limited timer / runner (15–20 min intervals, ~72–96 calls/day)
- [ ] Atomic JSON cache file writer to `$XDG_RUNTIME_DIR/weather/weather.json` with offline fallback

### Phase 2: Weather Service Singleton & Glyph Mapper
- [ ] `WeatherService.qml` consuming local JSON cache via reactive `FileView`
- [ ] Comprehensive `WeatherGlyphs.qml` mapping every WWO `weatherCode` + `isdaytime` to Material Symbols
- [ ] Stale data detection and offline indicators

### Phase 3: Top Status Bar Weather Pill
- [ ] `WeatherPill.qml` replacing temporary test pills in Center Zone
- [ ] Temperature formatting (°C), dynamic glyph, and M3 emphasized width resizing
- [ ] Subtle alert indicator when severe weather or rain (>50%) is imminent

### Phase 4: Time-Series Canvas Graphs & Hourly Forecast
- [ ] 24-hour smooth temperature & feels-like curve with min/max gridlines and area gradient
- [ ] Hourly precipitation volume & rain probability bar/column visualizer
- [ ] Interactive mouse hover scrub inspection with readout badges

### Phase 5: Multi-Modal Popup Inspector
- [ ] `WeatherPopup.qml` anchored via `StyledPopup` with 1000ms hover delay
- [ ] Atmospheric grid: Humidity, Barometric Pressure, UV Index, Wind Compass
- [ ] Air Quality Index (AQI) card with US-EPA color banding and PM2.5 concentration
- [ ] Astronomy card (Sunrise, Sunset, Moon phase) and Severe Weather alert banner

### Phase 6: System Integration, Retirement & Verification
- [ ] Remove temporary `TestPill.qml` and `TestPopup.qml`
- [ ] Deploy via GNU Stow leaf symlinks in `restow/quickshell/`
- [ ] Automated regression assertion suite (`scripts/phase51-weather-assert.sh`) and strict repository cleanliness

---
*Feature research for: Desktop Shell Weather Telemetry & Visualization*  
*Researched: 2026-10-02*  
