# Phase 54: Multi-Modal Popup Inspector & Interactive Graphs - Context

**Gathered:** 2026-10-09T23:42:00+06:00  
**Status:** Ready for planning  

<domain>
## Phase Boundary

Build and deliver the production multi-modal weather popup inspector (`WeatherPopup.qml`) and interactive spline graphs (`WeatherGraph.qml`), replacing the basic upstream prototype popup with a rich Material 3 desktop inspector anchored under `WeatherBar.qml`. Deployed as a personal overlay in `restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/` to shadow upstream `vendor/dots-hyprland/.../weather/WeatherPopup.qml` via GNU Stow leaf symlinks with zero upstream git churn.

**In scope:**
- Production `WeatherPopup.qml` container anchored via `StyledPopup` with 1000ms hover intent delay and horizontal screen boundary clamping.
- Modular component architecture consisting of 9 dedicated files in `modules/ii/bar/weather/`:
  1. `WeatherPopup.qml` (root container, layout, and popup lifecycle)
  2. `WeatherBaseCard.qml` (standardized M3 card container with header icon, title, and borders)
  3. `WeatherHeroCard.qml` (large temperature readout, condition glyph, location, description, and passive cache reload button)
  4. `WeatherGraph.qml` (24-hour Canvas 2D spline curves + precipitation bars + QML hover scrub overlay)
  5. `WeatherAtmosphericCard.qml` (2x2 grid for Humidity, Barometric Pressure, UV Index, and Visibility)
  6. `WeatherWindCard.qml` (circular compass rose dial, rotating needle, 16-point direction, wind speed, and gusts)
  7. `WeatherAqiCard.qml` (US-EPA color-coded health badge, 6-segment meter, PM2.5 and PM10 concentrations)
  8. `WeatherAstronomyCard.qml` (sunrise, sunset, and Canvas 2D dynamic lunar phase disc with illumination %)
  9. `WeatherAlertBanner.qml` (prominent glowing severe alert banner with expandable advisory drawer and multi-alert carousel)
- 24-hour Canvas 2D graph with dual splines (solid actual temperature with gradient fill; dashed feels-like temperature) using Monotone Cubic Spline interpolation (Fritsch-Carlson) and min/max guidelines.
- Hourly precipitation columns (height = rain chance %, saturation = volume in mm).
- Zero-repaint hover scrub overlay: Canvas repaints strictly once on data load / popup open; scrub hairline, snap dot, and floating tooltip pill are lightweight QtQuick Items tracking mouse position with 0.0% CPU overhead.
- Quiescent idle CPU $\le 1.68\%$ with discrete hover gating and visibility gating.
- Full Material 3 dark/light dynamic styling adhering to `fill: 0` outline iconography and `Appearance.colors.colLayer2`.
- Comprehensive automated verification harness `scripts/phase54-weather-assert.sh` and 4 mock JSON fixtures in `tests/fixtures/weather/`.
- Strict zero-churn vendor cleanliness gate (`arch/dots-hyprland.sh verify --strict`).

**Out of scope:**
- Modifying `BarContent.qml` (remains pristine per Phase 53).
- Direct background network queries in QML (handled strictly by Phase 51 systemd fetcher).
- Modifying upstream vendor files in `vendor/dots-hyprland` (strictly prohibited).
- Retiring prototype test files and final Stow milestone integration (allocated to Phase 55).

</domain>

<decisions>
## Implementation Decisions

### 1. Architecture, Modularization & Stow Deployment
- **D-54-01:** Consolidate the inspector into 9 focused components in `restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/` (`WeatherPopup`, `WeatherBaseCard`, `WeatherHeroCard`, `WeatherGraph`, `WeatherAtmosphericCard`, `WeatherWindCard`, `WeatherAqiCard`, `WeatherAstronomyCard`, `WeatherAlertBanner`). Embed the compass dial directly inside `WeatherWindCard` and the moon disc inside `WeatherAstronomyCard` to eliminate unnecessary file sprawl. — **Reversibility:** reversible
- **D-54-02:** Deploy directly into `restow/quickshell/` to shadow upstream `WeatherPopup.qml` and deploy auxiliary components via GNU Stow leaf symlinks, maintaining zero git churn in `vendor/dots-hyprland`. — **Reversibility:** reversible
- **D-54-03:** Standardize on strict `Weather*` naming prefix across all components for immediate namespace isolation and automatic QML type discovery. — **Reversibility:** reversible
- **D-54-04:** Implement shared `WeatherBaseCard.qml` providing unified `Appearance.colors.colLayer2` surface styling, 12px border radius, subtle `colOutlineVariant` stroke, standardized 18px header icon (`fill: 0`), title typography (`pixelSize.smaller`, `DemiBold`), and `default property alias content: container.data`. — **Reversibility:** reversible
- **D-54-05:** Subcomponents bind directly to the `Weather` singleton (`Weather.current`, `Weather.hourly`, `Weather.aqi`, `Weather.alerts`, `Weather.astronomy`) by default, while exposing optional property overrides (e.g. `property var model: Weather.aqi`) enabling automated test harnesses to inject mock JSON payloads directly. — **Reversibility:** reversible
- **D-54-06:** Standardize import header blocks across all weather subcomponents (`QtQuick`, `QtQuick.Layouts`, `qs.services`, `qs.modules.common`, `qs.modules.common.widgets`). — **Reversibility:** reversible
- **D-54-07:** Direct instantiation of all cards in the layout tree (no `Loader` latency or asynchronous binding flickers); `WeatherAlertBanner` collapses to 0 height smoothly via `Revealer` when no active alerts exist. — **Reversibility:** reversible

### 2. Popup Layout, Sizing & Anchoring
- **D-54-08:** Modular width of ~440px balancing a compact desktop footprint with generous breathing room for the 24h graph and dual-column metric cards. — **Reversibility:** reversible
- **D-54-09:** Sizing with `Flickable` fallback: Expands naturally up to 80% screen height, smoothly enabling vertical scrolling if screen height is constrained on smaller displays (e.g. 1080p laptops or vertical bars). — **Reversibility:** reversible
- **D-54-10:** Vertical card stacking order:
  1. `WeatherAlertBanner` (visible only when active alerts exist)
  2. `WeatherHeroCard` (full width)
  3. `WeatherGraph` (full width)
  4. 2-column paired grid: `[WeatherAtmosphericCard | WeatherWindCard]`
  5. 2-column paired grid: `[WeatherAqiCard | WeatherAstronomyCard]`
  — **Reversibility:** reversible
- **D-54-11:** Spacing rhythm: 12px outer popup padding, 8px gap between cards and grid cells, 10px inner padding within each card container. — **Reversibility:** reversible
- **D-54-12:** Anchoring: Centered horizontally beneath the `WeatherBar` status pill, with `StyledPopup` automatic boundary clamping preventing clipping at active monitor margins. — **Reversibility:** reversible
- **D-54-13:** Hover lifecycle & dismissal: Moving mouse into the popup retains focus; leaving popup bounds triggers a ~300ms grace timeout before dismissal (standard `StyledPopup` behavior). Escape key dismisses instantly. — **Reversibility:** reversible

### 3. Canvas 2D Temperature & Feels-Like Splines
- **D-54-14:** Dual curve rendering on Canvas 2D: Solid primary spline for actual temperature with subtle vertical accent gradient fill underneath; dashed/dotted secondary spline for feels-like temperature. — **Reversibility:** reversible
- **D-54-15:** Spline interpolation algorithm: Monotone Cubic Spline (Fritsch-Carlson) guaranteeing strictly monotonic interpolation between forecast data points with zero overshoot and zero false dips below minimums. — **Reversibility:** reversible
- **D-54-16:** Y-axis scaling: Dynamic 24-hour Min/Max with 1°C padding and horizontal dotted guidelines marked at the 24h high and low degree limits (e.g. `32°` and `24°`). — **Reversibility:** reversible
- **D-54-17:** X-axis timestamps: 3-hour timestamp labels (`Now`, `15:00`, `18:00`, `21:00`, ...) aligned naturally with WWO forecast slots, formatted at `pixelSize.smallest` in `colOnSurfaceVariant`. — **Reversibility:** reversible

### 4. Precipitation Visualization & Zero-Repaint Hover Scrub UX
- **D-54-18:** Dual-tier split within graph card: Upper ~70% dedicated to temperature Bezier splines; lower ~30% dedicated to hourly precipitation probability bars. — **Reversibility:** reversible
- **D-54-19:** Precipitation bar encoding: Bar height encodes rain probability % (0–100%); bar color saturation deepens from cyan/primary to saturated deep blue when hourly volume exceeds 2.5mm. — **Reversibility:** reversible
- **D-54-20:** Zero-repaint hover scrub overlay: Canvas 2D draws splines, background, and rain bars strictly ONCE when popup opens or cache updates. The vertical scrub hairline (`Rectangle`), curve snap dot (`Rectangle`), and floating tooltip pill (`Rectangle` + text) are pure QML visual items positioned dynamically by `MouseArea.mouseX`. Canvas NEVER repaints during mouse hover scrub, ensuring 60fps tracking and 0.0% CPU overhead. — **Reversibility:** costly — changing back to canvas-drawn scrub requires complete Canvas redraw loop refactoring
- **D-54-21:** Floating tooltip pill: Snaps to the nearest hourly forecast slot showing `[Time] • [Temp°C] (Feels [XX°C]) • [Rain % / mm]`. Mousing out of the graph card smoothly fades out the tooltip and hairline, resetting the display. — **Reversibility:** reversible
- **D-54-22:** Event-driven performance gating: Canvas repaint requests are strictly gated behind `root.active` (popup visibility) and cache data changes to guarantee quiescent idle CPU $\le 1.68\%$. — **Reversibility:** reversible

### 5. Atmospheric Metrics & Wind Compass Card
- **D-54-23:** Atmospheric metrics card: 2x2 compact cell grid displaying Humidity (`humidity_percentage`, `XX%`), Barometric Pressure (`compress`, `XXXX hPa`), UV Index (`wb_sunny`, integer + qualitative risk category `6 • High`), and Visibility (`visibility`, `XX km • Clear`). — **Reversibility:** reversible
- **D-54-24:** Wind Compass card: Compact circular compass rose dial (~56px diameter) with cardinal marks (N, E, S, W) and smooth rotating needle pointing to `winddirDegree`. Right side displays numeric wind speed (km/h), peak gusts (km/h), and 16-point direction (`winddir16Point`). — **Reversibility:** reversible
- **D-54-25:** Needle rotation animation: Shortest-path angle rotation ($\le 180^\circ$) over 400ms using `Appearance.animationCurves.expressiveEffects` so the needle never spins wildly across 0°/360° boundaries. — **Reversibility:** reversible
- **D-54-26:** Cardinal markings styling: North ("N") highlighted in primary theme accent (`Font.Bold`, ~10px) while "E", "S", "W" render in muted `colOnSurfaceVariant` (~9px) for effortless orientation at a glance. — **Reversibility:** reversible

### 6. Air Quality Index (AQI) & Astronomy Card
- **D-54-27:** Air Quality Index (AQI) card: Prominent US-EPA category badge (Good, Moderate, Unhealthy, etc.) with theme-harmonized EPA color fill (`WeatherGlyphs.getAqiColor`), accompanied by a 6-segment mini progress meter, and side-by-side particulate readouts: `PM2.5: XX.X µg/m³` and `PM10: XX.X µg/m³`. — **Reversibility:** reversible
- **D-54-28:** Astronomy card: Dual solar & lunar split. Left side displays Sunrise and Sunset times in clean 24-hour format (`HH:mm`) with twilight icons (`wb_twilight`, `bedtime`). Right side renders a dynamic lunar disc, human moon phase name (e.g. `Waxing Gibbous`), and illumination percentage (`82%`). — **Reversibility:** reversible
- **D-54-29:** Dynamic lunar disc: Embedded Canvas 2D circle (~36px diameter) drawing the lunar disc and shading the exact shadow terminator arc calculated from `moon_illumination` fraction and `moon_phase`. — **Reversibility:** reversible

### 7. Severe Weather Alert Banner & Edge States
- **D-54-30:** Glowing alert banner: Rendered at the top of the popup when active alerts exist in `Weather.alerts`, tinted dynamically via `WeatherGlyphs.getAlertColor(activeAlert.severity)`. Clicking the header row smoothly expands/collapses the full advisory text drawer with an animated 180° chevron. — **Reversibility:** reversible
- **D-54-31:** Multi-alert carousel: When multiple meteorological alerts exist, sort by severity (Extreme > Severe > Moderate) with compact `< 1 of N >` stepping buttons and count chip allowing manual cycling. — **Reversibility:** reversible
- **D-54-32:** Stale / offline cache presentation: When `Weather.isStale === true`, display a soft amber status pill (`Stale` / `Offline • 14:30`) in the Hero header beside observation time. Last-known cached metrics remain readable without obstructing or dimming the cards. — **Reversibility:** reversible
- **D-54-33:** Neutral fallback placeholders: Missing or unpopulated fields on cold boot render as clean muted `"--"` with neutral grey badge (`Unavailable` for AQI), preserving consistent grid geometry without layout jumping. — **Reversibility:** reversible

### 8. Typography Hierarchy, Iconography & Styling
- **D-54-34:** Hero Header scale: Prominent integer Celsius temperature (~32–36px bold, `Appearance.font.pixelSize.huge`) paired with a large outline condition glyph (~36px). Right side aligns City name (`Font.Bold`, `pixelSize.normal`), subordinate Country/Region (`Font.Normal`, `pixelSize.smaller`), weather condition description, and observation time. — **Reversibility:** reversible
- **D-54-35:** Metric card typography hierarchy: Card titles at `pixelSize.smaller` (`Font.DemiBold`, `colOnSurfaceVariant`, 18px icon), primary metric numbers at `pixelSize.normal`/`pixelSize.large` (`Font.Bold`, `colOnLayer1`), and unit/qualitative ratings at `pixelSize.smaller`/`smallest` (`Font.Medium`, `colOnSurfaceVariant`). — **Reversibility:** reversible
- **D-54-36:** Strict outline iconography: All Material Symbols across all cards strictly use outline styling (`fill: 0`), preserving 100% aesthetic coherence with dots-hyprland. Only Canvas drawings (lunar disc, needle, rain bars) and EPA category badges use solid fills. — **Reversibility:** reversible

### 9. Interactive Actions & Passive Operations
- **D-54-37:** Passive manual refresh: Subtle refresh icon beside observation time in Hero header that calls `Weather.getData()`, safely re-reading the local cache file from disk without triggering rogue network API calls or exhausting the 500 calls/day budget. — **Reversibility:** reversible
- **D-54-38:** Refresh visual feedback & debounce: 360° rotation animation over 600ms on click, disabling the button for 2 seconds to prevent rapid spam clicking. — **Reversibility:** reversible
- **D-54-39:** Temperature unit handling: Fixed Celsius (`XX°C`) display matching Phase 53 status pill, bound to `Config.options.bar.weather.unit` if imperial is configured. — **Reversibility:** reversible
- **D-54-40:** Pure desktop telemetry: Zero external web links, zero radar browser popups, zero clipboard mutations on accidental clicks. — **Reversibility:** reversible

### 10. Test Fixtures & Automated Verification Harness
- **D-54-41:** Deliver `scripts/phase54-weather-assert.sh` verifying:
  1. QML syntax and imports across all 9 new components.
  2. Public component interface properties and test override bindings.
  3. Headless mock data rendering across all 4 test fixtures.
  4. Idle CPU performance ($\le 1.68\%$) and paint counter telemetry (`paintCount === 1` on idle).
  5. Mandatory zero-churn vendor cleanliness gate (`arch/dots-hyprland.sh verify --strict`).
  — **Reversibility:** reversible
- **D-54-42:** Create 4 comprehensive mock JSON test fixtures in `tests/fixtures/weather/`:
  - `nominal.json`: Standard sunny 24h forecast, moderate wind, good AQI, normal astronomy.
  - `severe_alerts.json`: Multiple active meteorological alerts (tornado warning, flood watch) validating alert banner, drawer, and carousel.
  - `heavy_rain.json`: 100% rain chance with high volume (>10mm) validating saturated rain bars and scrub readouts.
  - `sparse_offline.json`: Cold-boot uninitialized state (`tempC: "--"`, missing AQI, empty alerts, stale flag) validating neutral fallback placeholders.
  — **Reversibility:** reversible

### the agent's Discretion
- Exact Bezier curve tension parameter for Fritsch-Carlson tangent calculation.
- Easing curves for accordion drawer expansion and multi-alert switching.
- Precise pixel offsets for graph axis labels.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Weather Data Contract & Singletons
- `.planning/phases/51-wwo-fetcher-service-local-cache-architecture/51-CONTEXT.md` — Authoritative cache envelope schema for `$XDG_RUNTIME_DIR/weather/weather.json`.
- `.planning/phases/52-weather-service-singleton-material-glyph-mapping/52-CONTEXT.md` — `Weather` and `WeatherGlyphs` singletons API specification.
- `.planning/phases/53-top-status-bar-weather-pill-component/53-CONTEXT.md` — `WeatherBar.qml` status pill integration, `popupActive` lifecycle property, and styling conventions.
- `restow/quickshell/.config/quickshell/ii/services/Weather.qml` — Live weather service singleton exposing `current`, `hourly`, `aqi`, `astronomy`, `alerts`, `isStale`.
- `restow/quickshell/.config/quickshell/ii/services/WeatherGlyphs.qml` — Glyph mapping, `getAqiColor(epaIndex)`, and `getAlertColor(severity)`.
- `test_wwo_api/WEATHER_PARAMETERS.md` — Complete catalog of WWO fields, hourly parameters, and condition codes.

### UI Shell & Upstream Components
- `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/weather/WeatherPopup.qml` — Upstream popup being shadowed.
- `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/StyledPopup.qml` — Upstream popup wrapper providing 1000ms hover delay, exit delay, and screen boundary clamping.
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherBar.qml` — Personal overlay weather pill anchoring `WeatherPopup`.
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPill.qml` — Reference pill for pulsing animations, M3 color transitions, and test contracts.

### Requirements & Roadmap
- `.planning/REQUIREMENTS.md` § GRAPH-01 through GRAPH-04, POPUP-01 through POPUP-07 — Core requirements for Phase 54.
- `.planning/ROADMAP.md` § Phase 54 — Phase goals, dependencies, and success criteria.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `qs.modules.common.widgets.Revealer`: Provides smooth animated collapse/reveal for dynamic elements like `WeatherAlertBanner`.
- `Appearance.animationCurves.expressiveEffects`: Standard Bezier easing curve for Material 3 fluid visual feedback.
- `Appearance.colors.colLayer2`: Standard elevated card background color.
- `Appearance.colors.colOutlineVariant`: Standard subtle border outline color.
- `WeatherGlyphs.getAlertColor(severity)`: Dynamic M3 alert color lookup.
- `WeatherGlyphs.getAqiColor(epaIndex)`: Dynamic M3 AQI safety color lookup.

### Established Patterns
- **GNU Stow Leaf Symlinks:** Overlay files in `restow/quickshell/` shadow upstream files in `~/.config/quickshell/` without modifying `vendor/dots-hyprland`.
- **Zero Idle CPU Policy:** Canvas repainting strictly event-driven; mouse scrub implemented via QML overlay items rather than continuous Canvas repainting.
- **Minimalist Outline Line Aesthetic:** Material Symbols strictly use `fill: 0`.

### Integration Points
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherPopup.qml`: Destination root popup component.
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherGraph.qml`: Destination graph component.
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherBaseCard.qml`: Reusable card container.
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherHeroCard.qml`: Hero header component.
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherAtmosphericCard.qml`: Atmospheric metrics grid.
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherWindCard.qml`: Wind compass card.
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherAqiCard.qml`: AQI card.
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherAstronomyCard.qml`: Astronomy card.
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherAlertBanner.qml`: Severe alert banner.
- `scripts/phase54-weather-assert.sh`: Verification script to be authored in execution phase.
- `tests/fixtures/weather/*.json`: Mock data fixtures.

</code_context>

<specifics>
## Specific Ideas
- Monotone Cubic Spline (Fritsch-Carlson) tangent calculation:
  ```javascript
  // For each interval [x_k, x_{k+1}], calculate delta = (y_{k+1} - y_k) / (x_{k+1} - x_k)
  // Ensure tangents m_k, m_{k+1} satisfy monotonicity condition:
  // if delta == 0, m_k = m_{k+1} = 0; else clamp alpha^2 + beta^2 <= 9
  ```
- Canvas 2D Lunar Disc calculation:
  ```javascript
  // ctx.arc(cx, cy, r, 0, Math.PI * 2) for base circle
  // ctx.ellipse(...) with dynamic x-radius r * (1 - 2 * illumination) to render exact crescent/gibbous shadow terminator
  ```
- Compass needle rotation:
  ```qml
  property real targetDegree: Weather.current.windDegree || 0
  // Shortest path:
  // let diff = (targetDegree - currentDegree) % 360;
  // if (diff > 180) diff -= 360; else if (diff < -180) diff += 360;
  ```

</specifics>

<deferred>
## Deferred Ideas
- None — all requirements GRAPH-01 through GRAPH-04 and POPUP-01 through POPUP-07 are fully addressed within Phase 54.
- Prototype file cleanup (`TestPill.qml`, `TestPopup.qml`) and final system verification will occur in Phase 55 per ROADMAP.md.

</deferred>

---

*Phase: 54-Multi-Modal Popup Inspector & Interactive Graphs*  
*Context gathered: 2026-10-09T23:42:00+06:00*  
