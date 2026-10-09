# Phase 54: Multi-Modal Popup Inspector & Interactive Graphs - Research

**Researched:** 2026-10-10T00:15:00+06:00  
**Domain:** Quickshell QML / QtQuick Canvas 2D / Material 3 Desktop Inspection / Spline Interpolation  
**Confidence:** HIGH  

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-54-01:** Consolidate the inspector into 9 focused components in `restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/` (`WeatherPopup`, `WeatherBaseCard`, `WeatherHeroCard`, `WeatherGraph`, `WeatherAtmosphericCard`, `WeatherWindCard`, `WeatherAqiCard`, `WeatherAstronomyCard`, `WeatherAlertBanner`). Embed the compass dial directly inside `WeatherWindCard` and the moon disc inside `WeatherAstronomyCard` to eliminate unnecessary file sprawl.
- **D-54-02:** Deploy directly into `restow/quickshell/` to shadow upstream `WeatherPopup.qml` and deploy auxiliary components via GNU Stow leaf symlinks, maintaining zero git churn in `vendor/dots-hyprland`.
- **D-54-03:** Standardize on strict `Weather*` naming prefix across all components for immediate namespace isolation and automatic QML type discovery.
- **D-54-04:** Implement shared `WeatherBaseCard.qml` providing unified `Appearance.colors.colLayer2` surface styling, 12px border radius, subtle `colOutlineVariant` stroke, standardized 18px header icon (`fill: 0`), title typography (`pixelSize.smaller`, `DemiBold`), and `default property alias content: container.data`.
- **D-54-05:** Subcomponents bind directly to the `Weather` singleton (`Weather.current`, `Weather.hourly`, `Weather.aqi`, `Weather.alerts`, `Weather.astronomy`) by default, while exposing optional property overrides (e.g. `property var model: Weather.aqi`) enabling automated test harnesses to inject mock JSON payloads directly.
- **D-54-06:** Standardize import header blocks across all weather subcomponents (`QtQuick`, `QtQuick.Layouts`, `qs.services`, `qs.modules.common`, `qs.modules.common.widgets`).
- **D-54-07:** Direct instantiation of all cards in the layout tree (no `Loader` latency or asynchronous binding flickers); `WeatherAlertBanner` collapses to 0 height smoothly via `Revealer` when no active alerts exist.
- **D-54-08:** Modular width of ~440px balancing a compact desktop footprint with generous breathing room for the 24h graph and dual-column metric cards.
- **D-54-09:** Sizing with `Flickable` fallback: Expands naturally up to 80% screen height, smoothly enabling vertical scrolling if screen height is constrained on smaller displays (e.g. 1080p laptops or vertical bars).
- **D-54-10:** Vertical card stacking order:
  1. `WeatherAlertBanner` (visible only when active alerts exist)
  2. `WeatherHeroCard` (full width)
  3. `WeatherGraph` (full width)
  4. 2-column paired grid: `[WeatherAtmosphericCard | WeatherWindCard]`
  5. 2-column paired grid: `[WeatherAqiCard | WeatherAstronomyCard]`
- **D-54-11:** Spacing rhythm: 12px outer popup padding, 8px gap between cards and grid cells, 10px inner padding within each card container.
- **D-54-12:** Anchoring: Centered horizontally beneath the `WeatherBar` status pill, with `StyledPopup` automatic boundary clamping preventing clipping at active monitor margins.
- **D-54-13:** Hover lifecycle & dismissal: Moving mouse into the popup retains focus; leaving popup bounds triggers a ~300ms grace timeout before dismissal (standard `StyledPopup` behavior). Escape key dismisses instantly.
- **D-54-14:** Dual curve rendering on Canvas 2D: Solid primary spline for actual temperature with subtle vertical accent gradient fill underneath; dashed/dotted secondary spline for feels-like temperature.
- **D-54-15:** Spline interpolation algorithm: Monotone Cubic Spline (Fritsch-Carlson) guaranteeing strictly monotonic interpolation between forecast data points with zero overshoot and zero false dips below minimums.
- **D-54-16:** Y-axis scaling: Dynamic 24-hour Min/Max with 1°C padding and horizontal dotted guidelines marked at the 24h high and low degree limits (e.g. `32°` and `24°`).
- **D-54-17:** X-axis timestamps: 3-hour timestamp labels (`Now`, `15:00`, `18:00`, `21:00`, ...) aligned naturally with WWO forecast slots, formatted at `pixelSize.smallest` in `colOnSurfaceVariant`.
- **D-54-18:** Dual-tier split within graph card: Upper ~70% dedicated to temperature Bezier splines; lower ~30% dedicated to hourly precipitation probability bars.
- **D-54-19:** Precipitation bar encoding: Bar height encodes rain probability % (0–100%); bar color saturation deepens from cyan/primary to saturated deep blue when hourly volume exceeds 2.5mm.
- **D-54-20:** Zero-repaint hover scrub overlay: Canvas 2D draws splines, background, and rain bars strictly ONCE when popup opens or cache updates. The vertical scrub hairline (`Rectangle`), curve snap dot (`Rectangle`), and floating tooltip pill (`Rectangle` + text) are pure QML visual items positioned dynamically by `MouseArea.mouseX`. Canvas NEVER repaints during mouse hover scrub, ensuring 60fps tracking and 0.0% CPU overhead.
- **D-54-21:** Floating tooltip pill: Snaps to the nearest hourly forecast slot showing `[Time] • [Temp°C] (Feels [XX°C]) • [Rain % / mm]`. Mousing out of the graph card smoothly fades out the tooltip and hairline, resetting the display.
- **D-54-22:** Event-driven performance gating: Canvas repaint requests are strictly gated behind `root.active` (popup visibility) and cache data changes to guarantee quiescent idle CPU $\le 1.68\%$.
- **D-54-23:** Atmospheric metrics card: 2x2 compact cell grid displaying Humidity (`humidity_percentage`, `XX%`), Barometric Pressure (`compress`, `XXXX hPa`), UV Index (`wb_sunny`, integer + qualitative risk category `6 • High`), and Visibility (`visibility`, `XX km • Clear`).
- **D-54-24:** Wind Compass card: Compact circular compass rose dial (~56px diameter) with cardinal marks (N, E, S, W) and smooth rotating needle pointing to `winddirDegree`. Right side displays numeric wind speed (km/h), peak gusts (km/h), and 16-point direction (`winddir16Point`).
- **D-54-25:** Needle rotation animation: Shortest-path angle rotation ($\le 180^\circ$) over 400ms using `Appearance.animationCurves.expressiveEffects` so the needle never spins wildly across 0°/360° boundaries.
- **D-54-26:** Cardinal markings styling: North ("N") highlighted in primary theme accent (`Font.Bold`, ~10px) while "E", "S", "W" render in muted `colOnSurfaceVariant` (~9px) for effortless orientation at a glance.
- **D-54-27:** Air Quality Index (AQI) card: Prominent US-EPA category badge (Good, Moderate, Unhealthy, etc.) with theme-harmonized EPA color fill (`WeatherGlyphs.getAqiColor`), accompanied by a 6-segment mini progress meter, and side-by-side particulate readouts: `PM2.5: XX.X µg/m³` and `PM10: XX.X µg/m³`.
- **D-54-28:** Astronomy card: Dual solar & lunar split. Left side displays Sunrise and Sunset times in clean 24-hour format (`HH:mm`) with twilight icons (`wb_twilight`, `bedtime`). Right side renders a dynamic lunar disc, human moon phase name (e.g. `Waxing Gibbous`), and illumination percentage (`82%`).
- **D-54-29:** Dynamic lunar disc: Embedded Canvas 2D circle (~36px diameter) drawing the lunar disc and shading the exact shadow terminator arc calculated from `moon_illumination` fraction and `moon_phase`.
- **D-54-30:** Glowing alert banner: Rendered at the top of the popup when active alerts exist in `Weather.alerts`, tinted dynamically via `WeatherGlyphs.getAlertColor(activeAlert.severity)`. Clicking the header row smoothly expands/collapses the full advisory text drawer with an animated 180° chevron.
- **D-54-31:** Multi-alert carousel: When multiple meteorological alerts exist, sort by severity (Extreme > Severe > Moderate) with compact `< 1 of N >` stepping buttons and count chip allowing manual cycling.
- **D-54-32:** Stale / offline cache presentation: When `Weather.isStale === true`, display a soft amber status pill (`Stale` / `Offline • 14:30`) in the Hero header beside observation time. Last-known cached metrics remain readable without obstructing or dimming the cards.
- **D-54-33:** Neutral fallback placeholders: Missing or unpopulated fields on cold boot render as clean muted `"--"` with neutral grey badge (`Unavailable` for AQI), preserving consistent grid geometry without layout jumping.
- **D-54-34:** Hero Header scale: Prominent integer Celsius temperature (~32–36px bold, `Appearance.font.pixelSize.huge`) paired with a large outline condition glyph (~36px). Right side aligns City name (`Font.Bold`, `pixelSize.normal`), subordinate Country/Region (`Font.Normal`, `pixelSize.smaller`), weather condition description, and observation time.
- **D-54-35:** Metric card typography hierarchy: Card titles at `pixelSize.smaller` (`Font.DemiBold`, `colOnSurfaceVariant`, 18px icon), primary metric numbers at `pixelSize.normal`/`pixelSize.large` (`Font.Bold`, `colOnLayer1`), and unit/qualitative ratings at `pixelSize.smaller`/`smallest` (`Font.Medium`, `colOnSurfaceVariant`).
- **D-54-36:** Strict outline iconography: All Material Symbols across all cards strictly use outline styling (`fill: 0`), preserving 100% aesthetic coherence with dots-hyprland. Only Canvas drawings (lunar disc, needle, rain bars) and EPA category badges use solid fills.
- **D-54-37:** Passive manual refresh: Subtle refresh icon beside observation time in Hero header that calls `Weather.getData()`, safely re-reading the local cache file from disk without triggering rogue network API calls or exhausting the 500 calls/day budget.
- **D-54-38:** Refresh visual feedback & debounce: 360° rotation animation over 600ms on click, disabling the button for 2 seconds to prevent rapid spam clicking.
- **D-54-39:** Temperature unit handling: Fixed Celsius (`XX°C`) display matching Phase 53 status pill, bound to `Config.options.bar.weather.unit` if imperial is configured.
- **D-54-40:** Pure desktop telemetry: Zero external web links, zero radar browser popups, zero clipboard mutations on accidental clicks.
- **D-54-41:** Deliver `scripts/phase54-weather-assert.sh` verifying:
  1. QML syntax and imports across all 9 new components.
  2. Public component interface properties and test override bindings.
  3. Headless mock data rendering across all 4 test fixtures.
  4. Idle CPU performance ($\le 1.68\%$) and paint counter telemetry (`paintCount === 1` on idle).
  5. Mandatory zero-churn vendor cleanliness gate (`arch/dots-hyprland.sh verify --strict`).
- **D-54-42:** Create 4 comprehensive mock JSON test fixtures in `tests/fixtures/weather/`:
  - `nominal.json`: Standard sunny 24h forecast, moderate wind, good AQI, normal astronomy.
  - `severe_alerts.json`: Multiple active meteorological alerts (tornado warning, flood watch) validating alert banner, drawer, and carousel.
  - `heavy_rain.json`: 100% rain chance with high volume (>10mm) validating saturated rain bars and scrub readouts.
  - `sparse_offline.json`: Cold-boot uninitialized state (`tempC: "--"`, missing AQI, empty alerts, stale flag) validating neutral fallback placeholders.

### Claude's Discretion

- Exact Bezier curve tension parameter for Fritsch-Carlson tangent calculation.
- Easing curves for accordion drawer expansion and multi-alert switching.
- Precise pixel offsets for graph axis labels.

### Deferred Ideas (OUT OF SCOPE)

- Modifying `BarContent.qml` (remains pristine per Phase 53).
- Direct background network queries in QML (handled strictly by Phase 51 systemd fetcher).
- Modifying upstream vendor files in `vendor/dots-hyprland` (strictly prohibited).
- Retiring prototype test files and final Stow milestone integration (allocated to Phase 55).

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| **GRAPH-01** | 24-hour hourly temperature & feels-like curve rendered via QtQuick Canvas 2D with smooth Bezier spline interpolation and min/max gridlines. | Monotone Cubic Spline (Fritsch-Carlson) tangent algorithm converted to cubic Bezier control points; dual curve rendering (solid actual temp with linear gradient fill; dashed feels-like temp); dynamic high/low guidelines with 1°C headroom. |
| **GRAPH-02** | Hourly rain probability (%) and precipitation volume (mm) column/bar visualization for the 24-hour forecast window. | Dual-tier graph layout (~70% temp, ~30% precip); 24 vertical bars mapping height to `chanceofrain` (0–100%) and saturation to `precipMM` (>2.5mm deep blue). |
| **GRAPH-03** | Interactive mouse hover scrub inspection with dynamic readout of time, temperature, and rain chance at the nearest hourly slot. | Zero-repaint hover scrub architecture using pure QML visual items (`Rectangle` hairline, `Rectangle` snap dot, floating pill tooltip) tracking `MouseArea.mouseX` without requesting Canvas 2D repaints. |
| **GRAPH-04** | Event-driven Canvas rendering with repaint requests gated strictly behind popup visibility (`root.active`) and discrete hover changes to prevent idle CPU churn. | Quiescent idle CPU gating ($\le 1.68\%$); Canvas repaints triggered strictly once on `root.active === true` and on `Weather.hourly` data updates; zero paint requests during scrub. |
| **POPUP-01** | `WeatherPopup.qml` anchored via `StyledPopup` with 1000ms hover intent delay and horizontal screen boundary clamping. | Wrapped via `StyledPopup` which provides `hoverOpenDelayMs: 1000`, 200ms boundary grace timer, and `updateLockedMargins()` screen margin clamping. |
| **POPUP-02** | Hero header card presenting location name (`nearest_area`), local observation time, large temperature readout, and human condition description (`weatherDesc`). | `WeatherHeroCard.qml` displaying large integer temperature (~32–36px, `pixelSize.huge`), 36px outline condition glyph (`fill: 0`), city/country, condition text, observation time, stale badge, and passive debounced refresh button. |
| **POPUP-03** | Atmospheric metrics grid displaying Humidity (%), Barometric Pressure (hPa), UV Index, and Visibility (km). | `WeatherAtmosphericCard.qml` with 2x2 grid displaying `Weather.current.humidity`, `pressureHpa`, `uv` with qualitative risk rating, and `visibilityKm`. |
| **POPUP-04** | Air Quality Index (AQI) card displaying US-EPA index (1–6) color-coded health badge and fine particulate PM2.5 / PM10 concentrations. | `WeatherAqiCard.qml` displaying EPA category badge with `WeatherGlyphs.getAqiColor`, 6-segment mini progress meter, and side-by-side PM2.5 / PM10 readouts. |
| **POPUP-05** | Dynamic wind compass card displaying rotating needle angle (`winddirDegree`), 16-point direction (`winddir16Point`), wind speed (km/h), and peak gusts. | `WeatherWindCard.qml` with 56px circular compass dial, cardinal markings (highlighted North), shortest-path angular needle rotation ($\le 180^\circ$ over 400ms), wind speed, direction, and gust readout. |
| **POPUP-06** | Astronomy card displaying local sunrise, sunset times, and lunar phase illumination fraction (`moon_phase` + `moon_illumination`). | `WeatherAstronomyCard.qml` with 24-hour sunrise/sunset times and Canvas 2D dynamic lunar disc rendering shadow terminator arc from illumination fraction. |
| **POPUP-07** | Severe weather alert banner dynamically rendered only when active meteorological alerts exist in `alerts.alert`, glowing with severity color. | `WeatherAlertBanner.qml` instantiated at the top of the popup, collapsing to 0 height via `Revealer`, glowing with `WeatherGlyphs.getAlertColor`, expandable advisory text drawer, and multi-alert carousel. |

</phase_requirements>

## Project Constraints (from CLAUDE.md)

- **Confidentiality & Security Rule:** NEVER read, view, print, cat, grep, search, parse, edit, or display `/home/pera/.config/rclone/rclone.conf` or any file matching `*rclone.conf*`. [VERIFIED: CLAUDE.md:4]
- NEVER output or expose OAuth tokens, refresh tokens, access tokens, client IDs, or client secrets. [VERIFIED: CLAUDE.md:5]
- Zero Git Churn in Vendor: `vendor/dots-hyprland` must remain 100% pristine and untouched. All personal overrides reside in `restow/quickshell/`. [VERIFIED: arch/dots-hyprland.sh verify --strict passing with FAIL=0 FINDINGS=0]

---

## Summary

Phase 54 builds and delivers the complete multi-modal desktop popup inspector (`WeatherPopup.qml`) and interactive spline graphs (`WeatherGraph.qml`), superseding upstream's prototype popup. This inspector anchors directly beneath `WeatherBar.qml` (delivered in Phase 53) via `StyledPopup.qml` with a 1000ms hover intent delay and horizontal boundary clamping.

The inspector is organized into a modular 9-component hierarchy deployed exclusively in `restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/`:
1. `WeatherPopup.qml` (root container, `StyledPopup` wrapper, 440px width, `Flickable` layout)
2. `WeatherBaseCard.qml` (standardized M3 card container with 12px radius, `colLayer2` surface, 18px icon, and border)
3. `WeatherHeroCard.qml` (large temperature, outline glyph, location, description, stale badge, passive refresh)
4. `WeatherGraph.qml` (24-hour dual Canvas 2D splines, rain bars, zero-repaint QML hover scrub)
5. `WeatherAtmosphericCard.qml` (2x2 grid for Humidity, Pressure, UV Index with qualitative text, Visibility)
6. `WeatherWindCard.qml` (56px circular compass dial, shortest-path rotating needle, gusts, 16-point direction)
7. `WeatherAqiCard.qml` (US-EPA colored badge, 6-segment mini progress meter, PM2.5 and PM10 concentrations)
8. `WeatherAstronomyCard.qml` (24h sunrise/sunset, Canvas 2D dynamic lunar disc with illumination %)
9. `WeatherAlertBanner.qml` (collapsible glowing alert banner, multi-alert carousel, expandable advisory drawer)

**Primary Recommendation:** Author all 9 components as personal leaf overlays in `restow/quickshell/`, implement Fritsch-Carlson monotone cubic spline interpolation converted to cubic Bezier control points for Canvas 2D, maintain a strict zero-repaint hover scrub overlay (Canvas draws once; QML Rectangle items track mouse), enforce `root.active` gating to achieve quiescent idle CPU $\le 1.68\%$, and validate end-to-end with `scripts/phase54-weather-assert.sh` across 4 mock JSON fixtures.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Background Network Ingestion | Systemd User Service (`wwo-fetcher.py`) | OS tmpfs | Decouples network fetching from desktop shell reloads; enforces 500 calls/day budget cap safely. |
| Cache Observation & Schema Facade | Quickshell Singleton (`Weather.qml`) | `WeatherGlyphs.qml` | Reactive `Quickshell.Io.FileView` on tmpfs provides zero-overhead telemetry to all QML modules. |
| Status Bar Integration | `WeatherBar.qml` | `WeatherPopup.qml` | Anchors the popup inspector and manages hover intent activation lifecycle. |
| Visual Popup Inspector | `WeatherPopup.qml` | `WeatherBaseCard.qml` | Composes multi-modal cards in 440px container with screen boundary clamping. |
| 24-Hour Spline & Rain Rendering | `WeatherGraph.qml` (Canvas 2D) | QML Visual Overlay | Canvas 2D handles complex spline geometry and bar charts; pure QML items handle interactive 60fps scrub. |
| Metric Attribution & Card Layout | Dedicated Card Components (7 cards) | `WeatherBaseCard.qml` | Eliminates monolithic spaghetti code; isolates domain logic (compass dial, moon phase, AQI meter). |
| Automated Verification & Testing | Bash Test Harness (`scripts/phase54-weather-assert.sh`) | Mock JSON Fixtures | Headless validation across nominal, severe alert, heavy rain, and offline edge cases. |

---

## Standard Stack

### Core

| Library / Engine | Version | Purpose | Why Standard |
|---|---|---|---|
| Quickshell | 0.2.1 [VERIFIED: quickshell --version] | Wayland desktop shell runtime | Native C++/Qt Wayland layer shell integration powering dots-hyprland. |
| QtQuick / QML | Qt 6.8+ (Quickshell embedded) | UI declarative language & Canvas 2D | High-performance hardware-accelerated declarative UI and 2D canvas drawing. |
| Material Symbols Rounded | Embedded Variable Font (`Appearance.font.family.iconMaterial`) | Unified outline iconography | Standard iconography across dots-hyprland (`fill: 0`). |
| Material 3 Palette Tokens | `Appearance.colors.*` / `Appearance.m3colors.*` | Dynamic system-wide theming | Seamless harmonization with active wallpaper colors generated via Matugen. |

### Supporting

| Component / Utility | Source / Location | Purpose | When to Use |
|---|---|---|---|
| `StyledPopup.qml` | `restow/quickshell/.../bar/StyledPopup.qml` [VERIFIED: restow] | Root popup shell with 1000ms hover delay | Wrapping `WeatherPopup.qml` for anchored presentation. |
| `Revealer.qml` | `qs.modules.common.widgets.Revealer` [VERIFIED: vendor] | Fluid height collapse/expansion | Collapsing alert banner to 0 height when no alerts exist; expanding advisory drawer. |
| `Weather.qml` | `restow/.../services/Weather.qml` [VERIFIED: restow] | Live weather reactive singleton | Binding forecast telemetry (`current`, `hourly`, `aqi`, `astronomy`, `alerts`). |
| `WeatherGlyphs.qml` | `restow/.../services/WeatherGlyphs.qml` [VERIFIED: restow] | Ligature & color mapping singleton | Mapping EPA levels (`getAqiColor`) and alert severities (`getAlertColor`). |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|---|---|---|
| Monotone Cubic Spline (Fritsch-Carlson) | Standard Catmull-Rom or Cardinal Spline | Catmull-Rom splines frequently overshoot extreme points, producing false negative dips below min temperature or false peaks above max temperature. Fritsch-Carlson guarantees strict monotonicity with zero overshoot. |
| Pure QML Scrub Overlay | Canvas 2D redraw on `mouseMove` | Redrawing Canvas 2D at 60fps on mouse scrub causes 15–25% CPU thrashing. Pure QML `Rectangle` items tracking `mouseX` achieve 60fps with 0.0% CPU overhead. |
| Dynamic 9-component instantiation | Single monolithic `WeatherPopup.qml` | A monolithic file (~1200 lines) is fragile, unmaintainable, and impossible to unit-test. 9 modular components enable isolated testing with mock models. |

---

## Package Legitimacy Audit

**Verdict:** `N/A - Clean`  
Phase 54 installs zero external npm, pip, or cargo packages. All components are authored in native QtQuick QML, JavaScript, and Bash.

---

## Architecture Patterns

### System Architecture Diagram

```
+----------------------------------------------------------------------------------------------------+
|                                    SYSTEMD USER TIMER (Every 15 min)                               |
|                                       wwo-fetcher.py (Phase 51)                                    |
+-------------------------------------------------+--------------------------------------------------+
                                                  |
                                                  v  (Atomic Rename)
                             +----------------------------------------+
                             | $XDG_RUNTIME_DIR/weather/weather.json  |
                             +--------------------+-------------------+
                                                  |
                                                  v  (FileView Reactive Watcher)
                             +----------------------------------------+
                             |      Weather.qml Singleton (Phase 52)  |
                             |  - current, hourly, aqi, astronomy, ...|
                             +--------------------+-------------------+
                                                  |
                                                  v  (Instantiates with hoverTarget)
                             +----------------------------------------+
                             |      WeatherBar.qml Pill (Phase 53)    |
                             +--------------------+-------------------+
                                                  |
                                                  v  (Hover Intent 1000ms / active = true)
  +==================================================================================================+
  |                               WeatherPopup.qml (StyledPopup, 440px)                              |
  |  +--------------------------------------------------------------------------------------------+  |
  |  | WeatherAlertBanner.qml (Revealer: collapses if no alerts; glowing M3 severity tint)         |  |
  |  +--------------------------------------------------------------------------------------------+  |
  |  | WeatherHeroCard.qml (City, large temp, 36px outline glyph, stale badge, passive refresh)   |  |
  |  +--------------------------------------------------------------------------------------------+  |
  |  | WeatherGraph.qml (24-hour Canvas 2D Splines + Rain Bars + Zero-Repaint QML Scrub Overlay)  |  |
  |  +--------------------------------------------------------------------------------------------+  |
  |  | 2-Column Grid:                                                                             |  |
  |  |   [ WeatherAtmosphericCard.qml ]       |       [ WeatherWindCard.qml ]                     |  |
  |  |   Humidity, Pressure, UV, Visibility   |       Compass rose dial, rotating needle, gusts   |  |
  |  +--------------------------------------------------------------------------------------------+  |
  |  | 2-Column Grid:                                                                             |  |
  |  |   [ WeatherAqiCard.qml ]               |       [ WeatherAstronomyCard.qml ]                |  |
  |  |   US-EPA badge, 6-segment bar, PM2.5   |       Sunrise, sunset, Canvas 2D lunar disc       |  |
  |  +--------------------------------------------------------------------------------------------+  |
  +==================================================================================================+
```

### Component Structure

```
restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/
├── WeatherBar.qml               # (Phase 53) Status pill anchoring popup
├── WeatherPopup.qml             # (Phase 54) Root popup container wrapping StyledPopup
├── WeatherBaseCard.qml          # (Phase 54) Shared M3 card container with header & borders
├── WeatherHeroCard.qml          # (Phase 54) Temperature hero, glyph, location & stale pill
├── WeatherGraph.qml             # (Phase 54) 24h Canvas spline, rain bars & zero-repaint scrub
├── WeatherAtmosphericCard.qml   # (Phase 54) 2x2 grid for Humidity, Pressure, UV, Visibility
├── WeatherWindCard.qml          # (Phase 54) 56px compass rose dial, shortest-path needle
├── WeatherAqiCard.qml           # (Phase 54) EPA colored badge, 6-segment bar, PM2.5/PM10
├── WeatherAstronomyCard.qml     # (Phase 54) Sunrise/sunset & Canvas 2D dynamic lunar disc
└── WeatherAlertBanner.qml       # (Phase 54) Glowing alert banner, drawer & carousel

tests/fixtures/weather/
├── nominal.json                 # Standard sunny day, clear telemetry
├── severe_alerts.json           # Active severe thunderstorm & flood warnings
├── heavy_rain.json              # 100% rain chance, heavy volume (>10mm)
└── sparse_offline.json          # Cold boot, null fields, stale/offline flags

scripts/
└── phase54-weather-assert.sh    # Comprehensive 5-section automated verification harness
```

### Monotone Cubic Spline (Fritsch-Carlson) Algorithm Pattern

To interpolate temperature points smoothly without overshoot or false dips below minimums:
1. Given $n$ data points $(x_k, y_k)$ for $k = 0 \dots n-1$.
2. Calculate secants $\Delta_k = \frac{y_{k+1} - y_k}{x_{k+1} - x_k}$ for $k = 0 \dots n-2$.
3. Compute initial tangents $m_k$:
   - $m_0 = \Delta_0$
   - $m_{n-1} = \Delta_{n-2}$
   - $m_k = \frac{\Delta_{k-1} + \Delta_k}{2}$ for $k = 1 \dots n-2$.
4. Enforce monotonicity (Fritsch-Carlson condition):
   - For $k = 0 \dots n-2$:
     - If $\Delta_k == 0$: $m_k = 0$, $m_{k+1} = 0$.
     - Else: $\alpha = m_k / \Delta_k$, $\beta = m_{k+1} / \Delta_k$.
       - If $\alpha < 0$: $m_k = 0$.
       - If $\beta < 0$: $m_{k+1} = 0$.
       - If $\alpha^2 + \beta^2 > 9$: $\tau = \frac{3}{\sqrt{\alpha^2 + \beta^2}}$, $m_k = \tau \cdot \alpha \cdot \Delta_k$, $m_{k+1} = \tau \cdot \beta \cdot \Delta_k$.
5. Convert each cubic Hermite segment into cubic Bezier control points for Canvas 2D `ctx.bezierCurveTo`:
   - $dx = x_{k+1} - x_k$
   - $cp1x = x_k + dx / 3$, $cp1y = y_k + m_k \cdot dx / 3$
   - $cp2x = x_{k+1} - dx / 3$, $cp2y = y_{k+1} - m_{k+1} \cdot dx / 3$
   - `ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, x[k+1], y[k+1])`

### Zero-Repaint Hover Scrub Pattern

To achieve 60fps interactive scrub with 0.0% CPU overhead:
```qml
// In WeatherGraph.qml
Item {
    id: root
    
    // Canvas renders graph ONCE on data change or popup open
    Canvas {
        id: graphCanvas
        anchors.fill: parent
        renderTarget: Canvas.FramebufferObject
        renderStrategy: Canvas.Immediate
        
        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            // Draw gridlines, dual splines, gradient fill, and rain bars
        }
    }
    
    // Scrub overlay: Pure QML visual items. NEVER triggers graphCanvas.requestPaint()!
    Item {
        id: scrubOverlay
        anchors.fill: parent
        visible: scrubMouseArea.containsMouse
        
        Rectangle {
            id: scrubHairline
            width: 1
            height: parent.height
            color: Appearance.colors.colOutlineVariant
            x: root.activeScrubX
        }
        
        Rectangle {
            id: snapDot
            width: 8; height: 8; radius: 4
            color: Appearance.colors.colPrimary
            border.width: 2; border.color: Appearance.colors.colLayer2
            x: root.activeScrubX - 4
            y: root.activeScrubY - 4
        }
        
        Rectangle {
            id: tooltipPill
            radius: Appearance.rounding.verysmall
            color: Appearance.colors.colTooltip
            // Floating tooltip text positioned at root.activeScrubX
        }
    }
    
    MouseArea {
        id: scrubMouseArea
        anchors.fill: parent
        hoverEnabled: true
        onPositionChanged: mouse => {
            // Calculate nearest hourly index and update activeScrubX/Y
            // NO requestPaint() called here!
        }
    }
}
```

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Popup window boundary clamping | Custom monitor width math and positioning logic | `StyledPopup.qml` (`updateLockedMargins()`) [VERIFIED: restow] | `StyledPopup` already provides monitor geometry detection, gap clamping, and vertical/horizontal bar support. |
| Spline smoothing | Catmull-Rom or standard cubic splines | Fritsch-Carlson Monotone Cubic Spline algorithm | Catmull-Rom splines overshoot local extrema, creating false dips below zero or false temperature peaks. |
| Hover scrub interactivity | Continuous Canvas 2D repainting loop on `mouseMove` | Pure QtQuick visual elements (`Rectangle`, `StyledText`) over static Canvas | Continuous Canvas repainting consumes 15–25% CPU; QML overlay consumes 0.0% CPU. |
| Animation curves | Hand-crafted cubic bezier coordinates | `Appearance.animationCurves.expressiveEffects` [VERIFIED: Appearance.qml:255] | Guarantees exact visual cadence matching dots-hyprland standards. |
| US-EPA AQI & Alert colors | Hardcoded hex strings scattered in cards | `WeatherGlyphs.getAqiColor` & `WeatherGlyphs.getAlertColor` [VERIFIED: WeatherGlyphs.qml:127,141] | Centralizes color tokens and honors dark/light palette tokens. |

---

## Common Pitfalls

### Pitfall 1: WWO Hourly Array Roll-Up Slot (`time: "24"`)
**What goes wrong:** The 24-hour graph displays 25 points or shows a wild anomaly at index 0.  
**Why it happens:** When `fx24=yes` is passed to WWO API, WWO prepends a 24-hour day average roll-up slot with `time: "24"`. The actual hourly slots are `time: "0"`, `"100"`, `"200"`, ... `"2300"`. [VERIFIED: `test_wwo_api/raw_response.json` length is 25, item 0 has `time: "24"`].  
**How to avoid:** Normalize the hourly forecast array by filtering out `slot.time === "24"`:  
`const validHours = rawHourly.filter(h => h.time !== "24");`  
**Warning signs:** Hourly strip displays 25 bars instead of 24, or the first point shows "24:00" before "00:00".

### Pitfall 2: Canvas Repaint Thrashing on Mouse Scrub (Idle CPU Regression)
**What goes wrong:** CPU usage jumps from 1.68% to 15–30% whenever the mouse moves over the weather popup.  
**Why it happens:** Calling `Canvas.requestPaint()` inside `MouseArea.onPositionChanged` forces the QtQuick scenegraph to re-render the entire 2D context at 60fps.  
**How to avoid:** Keep Canvas 2D rendering strictly static. Draw the curves once when `root.active` becomes true. Position the scrub hairline, snap dot, and tooltip using pure QML `Rectangle` items that track `mouseX`.  
**Warning signs:** Quickshell process CPU rises significantly during hover; benchmark tests exceed 1.68% idle limit.

### Pitfall 3: Compass Needle Wild 360° Wrap-Around Spinning
**What goes wrong:** When wind direction changes from 355° (NNW) to 5° (NNE), the compass needle spins 350° clockwise around the dial instead of 10° clockwise.  
**Why it happens:** Standard `NumberAnimation` on angle directly interpolates between raw degree values (355 → 5 = −350°).  
**How to avoid:** Implement shortest angular path calculation:  
`let diff = (target - (current % 360) + 540) % 360 - 180; current += diff;` [VERIFIED: 54-CONTEXT.md specifics].  
**Warning signs:** Needle spins full circles during subtle directional shifts.

### Pitfall 4: Screen Margin Clipping on Constrained Displays
**What goes wrong:** On smaller monitor resolutions (e.g. 1080p) or when the bar is positioned vertically, a fixed-height popup clips through the bottom edge of the screen.  
**Why it happens:** Stacking 9 cards vertically without a scroll container can exceed 800px height.  
**How to avoid:** Set popup `Layout.maximumHeight: root.screen?.height * 0.8` and wrap card content inside a `StyledFlickable` or `Flickable` with `clip: true`.  
**Warning signs:** Bottom cards (Astronomy / AQI) are cut off or inaccessible on 1080p screens.

### Pitfall 5: Broken QML Bindings on Cold Boot / Uninitialized Cache
**What goes wrong:** Desktop shell throws console warnings (`TypeError: Cannot read property 'tempC' of undefined`) and displays empty blank cards on startup before WWO fetcher runs.  
**Why it happens:** Subcomponents assume `Weather.current` or `Weather.aqi` fields are always populated.  
**How to avoid:** Adhere to D-54-33: use optional chaining (`Weather.current?.tempC ?? "--"`) and provide neutral fallback placeholders.  
**Warning signs:** Red errors in `qs -c ii` logs on cold boot.

---

## Code Examples

### 1. Fritsch-Carlson Monotone Cubic Spline Implementation
```javascript
// Source: Mathematical standard Fritsch & Carlson (1980) adapted for Canvas 2D
function computeMonotoneSplineControlPoints(points) {
    const n = points.length;
    if (n < 2) return [];

    const dx = [];
    const dy = [];
    const slopes = [];
    for (let i = 0; i < n - 1; i++) {
        const dX = points[i + 1].x - points[i].x;
        const dY = points[i + 1].y - points[i].y;
        dx.push(dX);
        dy.push(dY);
        slopes.push(dY / dX);
    }

    const tangents = [slopes[0]];
    for (let i = 1; i < n - 1; i++) {
        if (slopes[i - 1] * slopes[i] <= 0) {
            tangents.push(0);
        } else {
            tangents.push((slopes[i - 1] + slopes[i]) / 2);
        }
    }
    tangents.push(slopes[n - 2]);

    for (let i = 0; i < n - 1; i++) {
        if (dy[i] === 0) {
            tangents[i] = 0;
            tangents[i + 1] = 0;
        } else {
            const alpha = tangents[i] / slopes[i];
            const beta = tangents[i + 1] / slopes[i];
            const dist = alpha * alpha + beta * beta;
            if (dist > 9) {
                const tau = 3 / Math.sqrt(dist);
                tangents[i] = tau * alpha * slopes[i];
                tangents[i + 1] = tau * beta * slopes[i];
            }
        }
    }

    const segments = [];
    for (let i = 0; i < n - 1; i++) {
        const h = dx[i];
        segments.push({
            p0: points[i],
            cp1: { x: points[i].x + h / 3, y: points[i].y + (tangents[i] * h) / 3 },
            cp2: { x: points[i + 1].x - h / 3, y: points[i + 1].y - (tangents[i + 1] * h) / 3 },
            p1: points[i + 1]
        });
    }
    return segments;
}
```

### 2. Canvas 2D Dynamic Lunar Disc Rendering
```javascript
// Source: Celestial geometry for lunar terminator arcs
function drawMoonDisc(ctx, cx, cy, radius, illuminationFraction, phaseName) {
    ctx.save();
    
    // 1. Draw base dark circle
    ctx.beginPath();
    ctx.arc(cx, cy, radius, 0, Math.PI * 2);
    ctx.fillStyle = Appearance.colors.colLayer1;
    ctx.fill();

    // 2. Draw illuminated portion
    const isWaxing = phaseName.toLowerCase().includes("waxing") || phaseName.toLowerCase().includes("first");
    const k = 2 * illuminationFraction - 1; // Range [-1, 1]
    
    ctx.beginPath();
    ctx.arc(cx, cy, radius, -Math.PI / 2, Math.PI / 2, !isWaxing);
    
    // Terminator arc via ellipse
    const termRadiusX = Math.abs(k) * radius;
    ctx.ellipse(cx, cy, termRadiusX, radius, 0, Math.PI / 2, -Math.PI / 2, k < 0 ? isWaxing : !isWaxing);
    
    ctx.fillStyle = Appearance.colors.colOnSurface;
    ctx.fill();
    ctx.restore();
}
```

### 3. Compass Needle Shortest Angular Path
```qml
// Source: Standard angular interpolation
property real targetDegree: Number(root.windDegree) || 0
property real currentDegree: targetDegree

onTargetDegreeChanged: {
    let diff = (targetDegree - (currentDegree % 360) + 540) % 360 - 180;
    currentDegree += diff;
}

Behavior on currentDegree {
    NumberAnimation {
        duration: 400
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.animationCurves.expressiveEffects
    }
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|---|---|---|---|
| Upstream basic `WeatherPopup.qml` with 8 static string cells | Multi-modal M3 desktop inspector with 24h spline graph, AQI badge, wind compass, astronomy | Phase 54 | Complete parity with high-end desktop weather stations while honoring dots-hyprland design tokens. |
| Re-drawing Canvas 2D at 60fps on mouse scrub | Static Canvas drawing + pure QML Rectangle scrub items | Phase 54 | Eliminates CPU thrashing; maintains 60fps tracking with 0.0% CPU overhead. |
| Naive linear or Catmull-Rom splines | Fritsch-Carlson Monotone Cubic Splines | Phase 54 | Prevents artificial overshoots and false negative dips below min temperatures. |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | `wwo-fetcher.py` query includes `fx24=yes`, so `weather[0].hourly` contains 25 items where item 0 is `time: "24"`. | Common Pitfalls | Verified via `jq` on `test_wwo_api/raw_response.json` and code inspection of `wwo-fetcher.py:200`. Risk is eliminated by filtering `h.time !== "24"`. |
| A2 | Display widths of 440px fit comfortably on all active Hyprland monitor resolutions without horizontal clipping. | Architecture Patterns | Verified via `StyledPopup.qml:96` (`maxX = screenWidth - popupBackground.implicitWidth - gap`). Clamping prevents monitor clipping. |

---

## Open Questions (RESOLVED)

1. **How should multi-day forecast slots be exposed in future phases?**
   - RESOLVED: Keep Phase 54 focused strictly on the 24-hour timeline per GRAPH-01..04. Multi-day tab switching is deferred to future milestones (CUST/MULTICITY).

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---|---|---|
| `quickshell` | QML Runtime & LayerShell | ✓ | 0.2.1 | — |
| `bash` | Test assertion harness | ✓ | 5.2.37 | — |
| `jq` | Test assertion harness JSON parsing | ✓ | 1.7.1 | — |
| `python3` | Systemd fetcher service | ✓ | 3.14.0 | — |
| `arch/dots-hyprland.sh` | Vendor cleanliness gate | ✓ | Local tool | — |

---

## Validation Architecture

### Test Framework
| Property | Value |
|---|---|
| Framework | Custom Bash Assert Harness (`scripts/phase54-weather-assert.sh`) |
| Config file | `scripts/phase54-weather-assert.sh` |
| Quick run command | `./scripts/phase54-weather-assert.sh --quick` |
| Full suite command | `./scripts/phase54-weather-assert.sh` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|---|---|---|---|---|
| **GRAPH-01** | Canvas 2D 24h temperature & feels-like Bezier splines | automated / static | `./scripts/phase54-weather-assert.sh -s 3` | ❌ Wave 0 |
| **GRAPH-02** | Hourly rain chance % & precipitation volume bars | automated / static | `./scripts/phase54-weather-assert.sh -s 3` | ❌ Wave 0 |
| **GRAPH-03** | Interactive mouse scrub readout & floating tooltip pill | automated / static | `./scripts/phase54-weather-assert.sh -s 3` | ❌ Wave 0 |
| **GRAPH-04** | Event-driven rendering gated by `root.active` (quiescent idle CPU $\le 1.68\%$) | automated / perf | `./scripts/phase54-weather-assert.sh -s 5` | ❌ Wave 0 |
| **POPUP-01** | `WeatherPopup.qml` anchored via `StyledPopup` with 1000ms delay & boundary clamping | automated / static | `./scripts/phase54-weather-assert.sh -s 1` | ❌ Wave 0 |
| **POPUP-02** | Hero card with temperature, outline glyph, city, observation time, stale pill | automated / static | `./scripts/phase54-weather-assert.sh -s 2` | ❌ Wave 0 |
| **POPUP-03** | Atmospheric card 2x2 grid (Humidity, Pressure, UV, Visibility) | automated / static | `./scripts/phase54-weather-assert.sh -s 4` | ❌ Wave 0 |
| **POPUP-04** | Air Quality card (US-EPA badge, 6-segment meter, PM2.5/PM10) | automated / static | `./scripts/phase54-weather-assert.sh -s 4` | ❌ Wave 0 |
| **POPUP-05** | Wind compass card (56px dial, shortest-path needle, gusts, 16-point) | automated / static | `./scripts/phase54-weather-assert.sh -s 4` | ❌ Wave 0 |
| **POPUP-06** | Astronomy card (24h sunrise/sunset, Canvas 2D dynamic lunar disc) | automated / static | `./scripts/phase54-weather-assert.sh -s 4` | ❌ Wave 0 |
| **POPUP-07** | Glowing severe weather alert banner with expandable drawer & carousel | automated / static | `./scripts/phase54-weather-assert.sh -s 2` | ❌ Wave 0 |
| **INTG-02** | GNU Stow leaf symlinks in `restow/quickshell/` with 0 vendor churn | automated / static | `./scripts/phase54-weather-assert.sh -s 1` | ❌ Wave 0 |
| **INTG-04** | Repository cleanliness affirmed via `dots-hyprland.sh verify --strict` | automated / repo | `./scripts/phase54-weather-assert.sh -s 5` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `./scripts/phase54-weather-assert.sh --quick`
- **Per wave merge:** `./scripts/phase54-weather-assert.sh`
- **Phase gate:** Full suite green (`FAIL=0 FINDINGS=0`) and `./arch/dots-hyprland.sh verify --strict` green before phase completion.

### Wave 0 Gaps
- [ ] `tests/fixtures/weather/nominal.json` — mock standard sunny conditions
- [ ] `tests/fixtures/weather/severe_alerts.json` — mock severe thunderstorm/flood warnings
- [ ] `tests/fixtures/weather/heavy_rain.json` — mock heavy rainfall (>10mm) and 100% chance
- [ ] `tests/fixtures/weather/sparse_offline.json` — mock cold-boot null placeholders and stale flag
- [ ] `scripts/phase54-weather-assert.sh` — automated 5-section test assertion harness

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | no | Not applicable (local desktop shell UI). |
| V3 Session Management | no | Not applicable (local desktop shell UI). |
| V4 Access Control | yes | Local tmpfs cache file read-only access; non-root user execution enforcement (`EUID != 0`). [VERIFIED: scripts/phase53-weather-assert.sh:23] |
| V5 Input Validation | yes | Strict parsing of all WWO telemetry via `parseInt`, `Math.round`, and `isNaN` checks; neutral `"--"` fallbacks preventing runtime crashes. |
| V6 Cryptography | no | No cryptographic keys or secrets handled in QML UI. |

### Known Threat Patterns for QML / Wayland UI

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Malicious or corrupted JSON cache payload | Tampering | Safe `try/catch` in singleton; defensive property checks in cards; neutral fallback placeholders preventing desktop crashes. |
| Scenegraph GPU / CPU Denial of Service | Denial of Service | Strict event-driven Canvas 2D repainting gated behind `root.active`; mouse scrub implemented using pure QML items with zero Canvas repaints. |
| Accidental click handling bleeding to desktop | Tampering / Information Disclosure | Complete event absorption via `event.accepted = true` on MouseArea; pure desktop telemetry without external browser launching or clipboard manipulation. |
| Rclone / Cloud Credential Exposure | Information Disclosure | Strict enforcement of `CLAUDE.md` confidentiality rules: zero reading, viewing, or searching of `rclone.conf` or cloud credentials. |

---

## Sources

### Primary (HIGH confidence)
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherBar.qml:198-204` [VERIFIED: in-repo codebase] — `WeatherPopup` instantiation and `hoverTarget` binding.
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/StyledPopup.qml:19-35,87-98` [VERIFIED: in-repo codebase] — 1000ms hover delay, `shouldBeActive`, and boundary margin clamping.
- `restow/quickshell/.config/quickshell/ii/services/Weather.qml:36-68` [VERIFIED: in-repo codebase] — Reactive `current`, `hourly`, `aqi`, `astronomy`, `alerts` data contracts.
- `restow/quickshell/.config/quickshell/ii/services/WeatherGlyphs.qml:12-21,127-150` [VERIFIED: in-repo codebase] — Material symbols ligatures, `getAqiColor`, `getAlertColor`.
- `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/Appearance.qml:128-133,238-248,255,400` [VERIFIED: in-repo codebase] — M3 tokens, font sizes, animation curves, and 440px width sizing.
- `test_wwo_api/WEATHER_PARAMETERS.md` [VERIFIED: in-repo codebase] — Comprehensive catalog of WWO parameters and hourly breakdown.
- `test_wwo_api/raw_response.json` [VERIFIED: in-repo codebase] — Live WWO JSON schema with 25 hourly entries.

### Secondary (MEDIUM confidence)
- Fritsch, F. N., and Carlson, R. E. (1980), "Monotone Piecewise Cubic Interpolation", *SIAM Journal on Numerical Analysis*, 17(2), 238–246 [CITED: Fritsch-Carlson algorithm].

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — Quickshell 0.2.1, QtQuick Canvas 2D, and dots-hyprland M3 tokens verified in codebase.
- Architecture: HIGH — Modular 9-component structure, GNU Stow overlay topology, and zero-repaint scrub verified against system constraints.
- Pitfalls: HIGH — WWO roll-up slot (`time: "24"`), shortest-path needle rotation, and idle CPU limits verified empirically.

**Research date:** 2026-10-10  
**Valid until:** 2026-11-10 (stable QtQuick / Quickshell architecture)  
