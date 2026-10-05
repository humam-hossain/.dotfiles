# Phase 53: Top Status Bar Weather Pill Component - Context

**Gathered:** 2026-10-05T15:58:00+06:00  
**Status:** Ready for planning  

<domain>
## Phase Boundary

Build and integrate the top status bar weather component (`WeatherBar.qml`) deployed as a personal overlay in `restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherBar.qml` to shadow upstream `vendor/dots-hyprland/.../WeatherBar.qml` via GNU Stow. The pill renders in the Center Zone of `BarContent.qml` (to the right of Workspaces) inside the existing outer `BarGroup` wrapper, displaying ambient integer Celsius (`XX°C`), dynamic Material Symbols condition glyphs from the `Weather` and `WeatherGlyphs` singletons (Phase 52), context-sensitive warning badges (imminent rain > 50%, active severe meteorological alerts), and 1000ms hover-only popup anchoring.

**In scope:**
- Single personal overlay `WeatherBar.qml` in `restow/quickshell/` shadowing upstream `WeatherBar.qml`.
- `BarContent.qml` remains 100% UNTOUCHED to preserve flawless upstream updateability.
- Consuming modern Phase 52 `Weather.current.*` properties (`tempC`, `glyph`, `desc`), `Weather.alerts`, and `Weather.hourly`.
- Displaying integer Celsius with `XX°C` format, dropping `C` (`XX°`) only on hella-shortened screen widths (`useShortenedForm === 2`).
- Context-sensitive imminent rain badge (`water_drop` + percentage) in a smooth `Revealer` when probability > 50% in the upcoming 2–3 hour window.
- Severe weather alert indicator (`warning` symbol) with 3-loop breathing pulse animation (opacity 1.0 ↔ 0.4 over ~1.2s each) settling at full opacity.
- Multi-tier responsive reduction matching screen width tiers (`useShortenedForm`).
- Vertical bar support stacking glyph above temperature when `root.vertical === true`.
- Dimming stale/offline data with `Appearance.m3colors.m3onSurfaceVariant` and `cloud_off` fallback on cold boot.
- Anchoring upstream `WeatherPopup.qml` with 1000ms hover-only trigger and `popupActive` lifecycle tracking.
- Automated assertion test harness `scripts/phase53-weather-assert.sh`.

**Out of scope:**
- Modifying `BarContent.qml` (stays pristine).
- Custom multi-modal popup inspector or interactive Canvas graphs (Phases 54 & 55).
- Upstream vendor file mutations in `vendor/dots-hyprland` (strictly prohibited).

</domain>

<decisions>
## Implementation Decisions

### 1. Architecture & Bar Integration
- **D-53-01:** Leave `BarContent.qml` 100% UNTOUCHED. This preserves pristine upstream compatibility and enables effortless `git pull` updates from upstream dots-hyprland. — **Reversibility:** reversible
- **D-53-02:** Deploy as a single personal overlay file `restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherBar.qml` that shadows `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/weather/WeatherBar.qml` via GNU Stow leaf symlinks. No separate `WeatherPill.qml` wrapper file needed since `BarContent.qml` references `WeatherBar` directly. — **Reversibility:** reversible
- **D-53-03:** Use `MouseArea` as the root element of `WeatherBar.qml` (matching upstream signature and layout constraints). Because `BarContent.qml` (line 197) already wraps `WeatherBar` in an outer `BarGroup`, keeping `MouseArea` as root eliminates double-nested `BarGroup` borders, margins, and padding while inheriting `BarGroup` pill geometry and width animations. — **Reversibility:** reversible
- **D-53-04:** Directly bind to modern Phase 52 `Weather.current.*` properties (`Weather.current.tempC`, `Weather.current.glyph`, `Weather.current.desc`), bypassing the legacy `Weather.data.*` bridge. — **Reversibility:** reversible
- **D-53-05:** Remove upstream right-click manual refresh (`Weather.getData()`) — the Phase 51 systemd user timer is authoritative. Absorb all click events on the root `MouseArea` to prevent bubbling. — **Reversibility:** reversible
- **D-53-06:** Dim temperature text and condition glyph using `Appearance.m3colors.m3onSurfaceVariant` when `Weather.isStale == true` while continuing to display the last-known temperature reading. Render `cloud_off` fallback glyph during cold boot if no cached data has loaded (`tempC === "--"`). — **Reversibility:** reversible
- **D-53-07:** Render uniformly across all active monitors where the status bar is active, governed solely by `Config.options.bar.weather.enable`. — **Reversibility:** reversible
- **D-53-08:** Support vertical status bar mode (`root.vertical === true`) by stacking the condition glyph above the temperature text with compact spacing, matching `CpuGpuPill` conventions. — **Reversibility:** reversible
- **D-53-09:** Retain standard `BarGroup` background styling without adding custom background hover highlights, preserving visual consistency with adjacent system telemetry pills. — **Reversibility:** reversible
- **D-53-10:** Deliver an automated test harness `scripts/phase53-weather-assert.sh` verifying QML syntax, BarContent.qml integrity, restow symlinks, and zero vendor git churn (`arch/dots-hyprland.sh verify --strict`). — **Reversibility:** reversible

### 2. Alert Indicator Design
- **D-53-11:** Imminent rain indicator: Display a compact secondary icon (`water_drop`) and rain probability percentage (e.g. `60%`) in a `Revealer` that animates in only when rain probability > 50% in the immediate upcoming 2–3 hour window (`Weather.hourly`). — **Reversibility:** reversible
- **D-53-12:** Rain badge color: Style the `water_drop` glyph and percentage text with `Appearance.m3colors.m3primary` to provide a clear, themed accent color contrasting with neutral temperature text. — **Reversibility:** reversible
- **D-53-13:** Rain badge persistence: Keep the rain percentage badge visible even during ongoing rain (`weatherCode` 293–395) to indicate precipitation intensity. — **Reversibility:** reversible
- **D-53-14:** Severe weather alert indicator: Render a `warning` Material Symbol colored dynamically via `WeatherGlyphs.getAlertColor(severity)` when active meteorological alerts exist in `Weather.alerts`. — **Reversibility:** reversible
- **D-53-15:** Breathing pulse animation: On arrival of an Extreme/Severe alert, trigger a subtle 3-loop breathing pulse animation (opacity 1.0 ↔ 0.4 over ~1.2s each) settling at full opacity (matching `CpuGpuPill` D-12) to avoid permanent peripheral distraction. — **Reversibility:** reversible
- **D-53-16:** Severe alert presentation: Display only the warning icon on the status bar pill without textual headline chips, preserving Center Zone symmetry and preventing workspace displacement. Full descriptions appear in the popup inspector. — **Reversibility:** reversible
- **D-53-17:** Alert precedence: When both imminent rain (>50%) and an active severe alert coincide, the severe alert warning icon takes precedence, suppressing the rain percentage badge to keep the pill compact. — **Reversibility:** reversible

### 3. Temperature & Glyph Layout
- **D-53-18:** Temperature format: Display integer Celsius with unit suffix `XX°C` (e.g. `28°C`), dropping `C` (`XX°`) only on hella-shortened screen widths (`useShortenedForm === 2`). — **Reversibility:** reversible
- **D-53-19:** Robust numeric parsing: Compute temperature string via `Math.round(Number(Weather.current.tempC))` with fallback to `"--"` if `isNaN`, preventing NaN artifacts. — **Reversibility:** reversible
- **D-53-20:** Sizing & typography: Large condition glyph (`Appearance.font.pixelSize.large`) with small temperature text (`Appearance.font.pixelSize.small`), matching upstream WeatherBar proportions and keeping glyph details legible. — **Reversibility:** reversible
- **D-53-21:** Symbol outline styling: Use outline styling (`fill: 0`) for the condition `MaterialSymbol`, adhering to the desktop shell's minimalist line aesthetic. — **Reversibility:** reversible
- **D-53-22:** Rain badge scale: Subordinate rain chance visually with `Appearance.font.pixelSize.small` for `water_drop` and `Appearance.font.pixelSize.smaller` for the percentage text. — **Reversibility:** reversible
- **D-53-23:** Internal element ordering: Left-to-right sequential layout: `[⚠ Alert]` (if active) -> `[Condition Glyph]` -> `[XX°C]` -> `[💧 Rain%]` (if active). Critical hazards lead on the left, primary condition/temp centered, secondary rain probability trails on the right. — **Reversibility:** reversible
- **D-53-24:** Intra-element spacing: Maintain 4px spacing (`spacing: 4`) between inline elements, matching standard bar spacing across `CpuGpuPill` and `BarContent.qml`. — **Reversibility:** reversible
- **D-53-25:** M3 expressive color animations: Apply 200ms `expressiveEffects` ColorAnimation on glyph and text color transitions for smooth wallpaper shifts. — **Reversibility:** reversible
- **D-53-26:** Dynamic badge reveal: Wrap leading alert icon and trailing rain badge in `Revealer` components for fluid width expansion/contraction without layout snapping. — **Reversibility:** reversible
- **D-53-27:** Neutral temperature colors: Retain standard neutral text color (`Appearance.colors.colOnLayer1`) for both sub-freezing (<= 0°C) and hot ambient temperatures (> 38°C) to avoid alarm fatigue; official alerts in `Weather.alerts` handle genuine temperature hazards. — **Reversibility:** reversible
- **D-53-28:** Progressive responsive reduction: Tier 0/1 (`useShortenedForm < 2`) show full glyph + `XX°C` + badges; Tier 2 (`useShortenedForm === 2`) drops the rain badge, shortens temperature to `XX°`, while keeping the severe alert icon. — **Reversibility:** reversible

### 4. Popup Wiring & Interaction
- **D-53-29:** Wire to upstream `WeatherPopup.qml` via `StyledPopup` pattern (`hoverTarget: root`), providing an immediately functional popup in Phase 53 until Phase 55 delivers the multi-modal inspector. — **Reversibility:** reversible
- **D-53-30:** Hover-only trigger: Popup opens strictly via 1000ms hover intent delay; mouse clicks are absorbed and ignored. — **Reversibility:** reversible
- **D-53-31:** Built-in `StyledPopup` mechanisms: Rely on `StyledPopup` for hover exit delay, screen boundary clamping, and Escape key dismissal without custom timer/key boilerplate in `WeatherBar.qml`. — **Reversibility:** reversible
- **D-53-32:** Per-pill instance instantiation: Instantiate `WeatherPopup` directly inside `WeatherBar.qml` root `MouseArea`, guaranteeing automatic per-monitor coordinate mapping. — **Reversibility:** reversible
- **D-53-33:** Popup lifecycle property: Expose `readonly property bool popupActive: weatherPopup.active ?? false` for Phase 54 Canvas graph rendering gating. — **Reversibility:** reversible

### the agent's Discretion
- Exact easing curve parameters for the `Revealer` slide transitions (aligned to `Appearance.animation.elementMoveFast`).
- Internal layout container type (`RowLayout` vs `GridLayout`).
- Exact property alias names for internal test hooks.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Weather Data Contract & Iconography
- `.planning/phases/51-wwo-fetcher-service-local-cache-architecture/51-CONTEXT.md` — Authoritative cache envelope schema for `$XDG_RUNTIME_DIR/weather/weather.json`.
- `.planning/phases/52-weather-service-singleton-material-glyph-mapping/52-CONTEXT.md` — `Weather` and `WeatherGlyphs` singletons API specification.
- `restow/quickshell/.config/quickshell/ii/services/Weather.qml` — Live weather service singleton exposing `current`, `alerts`, `hourly`, `aqi`.
- `restow/quickshell/.config/quickshell/ii/services/WeatherGlyphs.qml` — Live weather glyph and color mapping dictionary.
- `test_wwo_api/WEATHER_PARAMETERS.md` — Complete catalog of WWO fields and condition codes.

### Status Bar & Component Baselines
- `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/weather/WeatherBar.qml` — Upstream WeatherBar being shadowed.
- `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/weather/WeatherPopup.qml` — Upstream popup component anchored in Phase 53.
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml` — Center Zone layout mounting `WeatherBar` (L190–200).
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarGroup.qml` — Status bar pill container providing M3 background and 250ms width resizing animation.
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPill.qml` — Reference pill implementation for pulsing alerts, M3 color transitions, and test contracts.
- `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/StyledPopup.qml` — Reference popup wrapper providing 1000ms hover intent delay and boundary clamping.

### Requirements & Roadmap
- `.planning/REQUIREMENTS.md` § BAR-01 through BAR-04 — Core requirements for Phase 53.
- `.planning/ROADMAP.md` § Phase 53 — Phase goals, dependencies, and success criteria.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `qs.modules.common.widgets.Revealer`: Provides animated slide/expansion for dynamic inline elements like the rain chance badge and alert warning icon.
- `Appearance.animationCurves.expressiveEffects`: Standard Bezier curve for Material 3 fluid visual feedback.
- `Appearance.animation.elementMoveFast`: Standard fast animation timing for UI state transitions.
- `WeatherGlyphs.getAlertColor(severity)`: Returns dynamic `Appearance.m3colors.*` token corresponding to alert severity.

### Established Patterns
- **GNU Stow Leaf Symlink Overlays:** Personal customizations live in `restow/quickshell/` and are symlinked into `~/.config/quickshell/`, keeping `vendor/dots-hyprland` completely clean.
- **Center Zone Layout:** Center Zone holds `ClockWidget` (left), `Workspaces` (dead-center), and `WeatherBar` (right) with 4px inter-pill spacing.
- **Hover Intent Delay:** Popups use `StyledPopup` with 1000ms delay to prevent visual pop-in during transient cursor traverses.

### Integration Points
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherBar.qml`: Destination overlay file.
- `BarContent.qml` lines 190–200: Existing `Loader` with `id: weatherGroup` loading `WeatherBar` inside `BarGroup`.
- `scripts/phase53-weather-assert.sh`: Verification script to be authored in execution phase.

</code_context>

<specifics>
## Specific Ideas
- Imminent rain probability calculation:
  ```qml
  readonly property int imminentRainChance: {
      if (!Weather.hourly || Weather.hourly.length === 0) return 0;
      let maxChance = 0;
      for (let i = 0; i < Math.min(3, Weather.hourly.length); ++i) {
          const chance = parseInt(Weather.hourly[i].chanceofrain || "0", 10);
          if (chance > maxChance) maxChance = chance;
      }
      return maxChance;
  }
  readonly property bool imminentRain: imminentRainChance > 50
  ```
- Active severe alerts check:
  ```qml
  readonly property bool hasSevereAlert: (Weather.alerts && Weather.alerts.length > 0)
  readonly property var activeAlert: hasSevereAlert ? Weather.alerts[0] : null
  ```

</specifics>

<deferred>
## Deferred Ideas
- Interactive 24-hour Canvas graph with Bezier splines — allocated to Phase 54 (`WeatherGraph.qml`).
- Full multi-modal popup inspector with Air Quality, Wind Compass, Astronomy, and Alert banner — allocated to Phase 55 (`WeatherPopup.qml`).

</deferred>

---

*Phase: 53-Top Status Bar Weather Pill Component*  
*Context gathered: 2026-10-05T15:58:00+06:00*  
