# Phase 54: Multi-Modal Popup Inspector & Interactive Graphs - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-10-09T23:42:00+06:00  
**Phase:** 54-Multi-Modal Popup Inspector & Interactive Graphs  
**Areas discussed:** Popup Layout & Dimension Strategy, Canvas Graph & Hover Scrub UX, Rich Widget Visuals: Wind Compass, AQI & Astronomy, Severe Weather Alert Banner & Edge States, Component Modularization & File Architecture, Interactive Actions & Manual Refresh, Typography Hierarchy & Icon Sizing, Test Fixtures & Verification Strategy  

---

## Popup Layout & Dimension Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Modular width (~440px) | Hero + Graph full width on top, followed by a 2-column card grid for metrics (balances compact footprint with breathing room) | ✓ |
| Compact vertical stack (~360px) | Single-column stack with condensed metric rows | |
| Wider dashboard (~520px) | Multi-column grid with spacious cards and large dials | |

**User's choice:** Modular width (~440px)  
**Notes:** Balances screen economy on status bar hover with ample width for the 24h forecast graph.

| Option | Description | Selected |
|--------|-------------|----------|
| Auto-sizing with Flickable fallback | Expands naturally up to 80% screen height, smoothly scrolling if vertical room is constrained on smaller displays | ✓ |
| Strictly non-scrollable compact layout | Fixed dimensions tuned to fit 1080p without scrollbar | |
| Multi-tab / segmented view | Split between Forecast & Details tabs | |

**User's choice:** Auto-sizing with Flickable fallback  
**Notes:** Guarantees fit across all monitor heights and vertical bar orientations.

| Option | Description | Selected |
|--------|-------------|----------|
| 2-column paired cards | [Atmospheric Grid \| Wind Compass] on one row, followed by [AQI Card \| Astronomy Card] on the next row | ✓ |
| Horizontal 4-metric strip + 3 sub-cards | Compact 4-item strip followed by 3 cards | |
| Collapsible details drawer | Secondary cards tucked into expandable drawer | |

**User's choice:** 2-column paired cards  
**Notes:** Clean visual symmetry and balanced weight.

| Option | Description | Selected |
|--------|-------------|----------|
| M3 surface cards | Distinct rounded card containers (Appearance.colors.colLayer2, 12px radius, subtle border) | ✓ |
| Flat divider layout | Borderless layout separated by subtle hairline divider lines | |
| Single unified container | All metrics inside one single card background | |

**User's choice:** M3 surface cards  
**Notes:** Matches system telemetry card aesthetic (CpuGpuPill, Audio cards).

---

## Canvas Graph & Hover Scrub UX

| Option | Description | Selected |
|--------|-------------|----------|
| Dual curves | Solid primary curve for actual temp with soft vertical gradient fill below; dashed/dotted secondary curve for feels-like temp | ✓ |
| Single solid curve | Only actual temperature curve rendered on Canvas | |
| Dual distinct colored lines | Two solid contrasting colored splines | |

**User's choice:** Dual curves  
**Notes:** Provides both actual and perceived temperature at a glance.

| Option | Description | Selected |
|--------|-------------|----------|
| Dual-tier split within graph card | Upper ~70% for temperature Bezier splines, lower ~30% for hourly rain probability bars | ✓ |
| Full-height background columns | Translucent vertical columns spanning full height | |
| Dual axis overlay | Rain bars along bottom baseline with secondary Y-axis | |

**User's choice:** Dual-tier split within graph card  
**Notes:** Prevents temperature splines and rain columns from obscuring each other.

| Option | Description | Selected |
|--------|-------------|----------|
| Dual-layering / Zero-repaint QML overlay | Canvas paints once on data load / popup open; scrub hairline, snap dot, and floating tooltip pill are lightweight QtQuick Items tracking mouseX | ✓ |
| Single Canvas with gated requestPaint() | All elements drawn in Canvas 2D context with integer index gating | |
| One-shot animated reveal | Spline draw-in animation on popup open | |

**User's choice:** Dual-layering / Zero-repaint QML overlay (Consolidated via simplification review)  
**Notes:** Guarantees 0.0% CPU usage during mouse scrub and butter-smooth 60fps tracking.

| Option | Description | Selected |
|--------|-------------|----------|
| Monotone Cubic Spline (Fritsch-Carlson) | Strictly monotonic interpolation between forecast points, eliminating overshoot and false dips | ✓ |
| Catmull-Rom Spline | Standard smooth curve with 0.5 tension | |
| Linear segments | Crisp straight line segments | |

**User's choice:** Monotone Cubic Spline (Fritsch-Carlson)  
**Notes:** Mathematically eliminates false peaks and dips below adjacent minimum temperatures.

---

## Rich Widget Visuals: Wind Compass, AQI & Astronomy

| Option | Description | Selected |
|--------|-------------|----------|
| Circular compass rose dial | Compact circular dial (~56px diameter) with cardinal marks (N, E, S, W) and smoothly rotating needle | ✓ |
| Rotating directional icon badge | Material Symbol navigation arrow next to speed readings | |
| Full-width wind vector card | Large animated compass dial with Beaufort scale | |

**User's choice:** Circular compass rose dial  
**Notes:** Embedded directly in WeatherWindCard.qml with shortest-path rotation animation (≤180°).

| Option | Description | Selected |
|--------|-------------|----------|
| Color-coded health badge + 6-segment meter | Prominent EPA category badge with themed color fill, 6-segment indicator, and PM2.5/PM10 concentrations | ✓ |
| Circular arc gauge | Radial meter with needle or colored arc | |
| Minimalist status chip & stats | Compact EPA level pill with particulate values | |

**User's choice:** Color-coded health badge + 6-segment meter  
**Notes:** Uses theme-harmonized EPA palette via WeatherGlyphs.getAqiColor.

| Option | Description | Selected |
|--------|-------------|----------|
| Canvas 2D dynamic lunar disc | Lightweight Canvas drawing circle with exact shadow arc calculated from moon_illumination and moon_phase | ✓ |
| Material Symbol mapped icons | Contextual font glyphs mapped by phase name | |
| Pre-rendered SVG assets | Static SVG graphics | |

**User's choice:** Canvas 2D dynamic lunar disc  
**Notes:** Embedded directly inside WeatherAstronomyCard.qml with exact terminator geometry.

---

## Severe Weather Alert Banner & Edge States

| Option | Description | Selected |
|--------|-------------|----------|
| Prominent glowing banner with expandable drawer | Alert card above Hero header (WeatherGlyphs.getAlertColor) with click-to-expand advisory body drawer | ✓ |
| Full static alert card | Permanently displays full body text | |
| Embedded alert chip in Hero | Badge inside Hero header | |

**User's choice:** Prominent glowing banner with expandable drawer  
**Notes:** Urgent visibility when hazardous weather is active without cluttering default resting view.

| Option | Description | Selected |
|--------|-------------|----------|
| Highest severity first with carousel/chips | Sorts by severity (Extreme > Severe > Moderate) with compact < 1 of N > stepping buttons | ✓ |
| Vertical stacked banners | Separate banner for every active alert | |
| Highest severity single alert | Strictly highest severity alert | |

**User's choice:** Highest severity first with carousel/chips  
**Notes:** Allows reviewing all active advisories without vertical layout explosions.

| Option | Description | Selected |
|--------|-------------|----------|
| Subtle header status pill | Observation time in Hero displays soft amber status pill ('Stale' / 'Offline • 14:30') | ✓ |
| Prominent offline banner | Dedicated yellow/orange warning banner | |
| Dimmed overlay | Reduced opacity across all cards | |

**User's choice:** Subtle header status pill  
**Notes:** Leaves last-known cached values completely legible during network interruptions.

---

## Component Modularization & File Architecture

| Option | Description | Selected |
|--------|-------------|----------|
| Consolidated 9-file architecture | WeatherPopup, WeatherBaseCard, WeatherHeroCard, WeatherGraph, WeatherAtmosphericCard, WeatherWindCard, WeatherAqiCard, WeatherAstronomyCard, WeatherAlertBanner | ✓ |
| 11-file split | Standalone WeatherCompassDial and WeatherMoonDisc files | |
| Monolithic single-file | All cards in WeatherPopup.qml | |

**User's choice:** Consolidated 9-file architecture (Adopted via simplification review)  
**Notes:** Clean separation of concerns while keeping dial and disc tightly scoped to their parent cards.

| Option | Description | Selected |
|--------|-------------|----------|
| Reusable WeatherBaseCard.qml | Shared card container handling M3 background, border, corner radius, padding, and standardized title header | ✓ |
| Individual card wrappers | Each subcomponent defines custom Rectangle | |
| Upstream WeatherCard.qml reuse | Adapt upstream template | |

**User's choice:** Reusable WeatherBaseCard.qml  
**Notes:** Eliminates hundreds of lines of duplicated container code across sub-cards.

---

## Interactive Actions & Manual Refresh

| Option | Description | Selected |
|--------|-------------|----------|
| Passive cache-reload icon in header | Subtle refresh icon beside observation time calling Weather.getData() (disk-only reload) | ✓ |
| Direct systemd fetch trigger | Runs systemctl --user start wwo-fetcher.service | |
| Strictly passive display | Zero refresh buttons | |

**User's choice:** Passive cache-reload icon in header  
**Notes:** Never triggers direct HTTP calls, strictly preserving the 500 calls/day budget.

| Option | Description | Selected |
|--------|-------------|----------|
| 360° spin animation + 2-second debounce | Refresh icon rotates 360° over 600ms, disabling re-triggering for 2 seconds | ✓ |
| Temporary checkmark icon | Switches icon to check for 1000ms | |
| Instant silent reload | Silent reload without animation | |

**User's choice:** 360° spin animation + 2-second debounce  
**Notes:** Clear tactile visual feedback.

---

## Typography Hierarchy & Icon Sizing

| Option | Description | Selected |
|--------|-------------|----------|
| Expressive Hero scale | Huge temperature readout (~32–36px bold, Appearance.font.pixelSize.huge) paired with ~36px outline glyph | ✓ |
| Moderate balanced scale | Large temperature (~24px) and large glyph (~28px) | |
| Compact low-profile scale | Medium temperature (~18px) | |

**User's choice:** Expressive Hero scale  
**Notes:** Creates an immediate focal point on popup open.

| Option | Description | Selected |
|--------|-------------|----------|
| Uniform fill: 0 outline styling | All Material Symbols across all cards strictly use outline styling (fill: 0) | ✓ |
| Contextual fill | Filled symbols for alerts/hazards | |
| Filled icons throughout | Solid filled glyphs | |

**User's choice:** Uniform fill: 0 outline styling  
**Notes:** 100% adherence to dots-hyprland minimalist outline line aesthetic.

---

## Test Fixtures & Verification Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Comprehensive automated harness | scripts/phase54-weather-assert.sh validating QML syntax, exports, mock rendering, CPU quiescence, and vendor cleanliness | ✓ |
| Lightweight file check | Simple existence check | |
| Manual verification only | No automated script | |

**User's choice:** Comprehensive automated harness  
**Notes:** Strict gating mirroring Phase 53 standards.

| Option | Description | Selected |
|--------|-------------|----------|
| 4 targeted mock fixtures | nominal.json, severe_alerts.json, heavy_rain.json, sparse_offline.json | ✓ |
| Single comprehensive fixture | One all-in-one fixture | |
| Live cache testing only | Existing live cache | |

**User's choice:** 4 targeted mock fixtures  
**Notes:** Rigorously exercises nominal, extreme alerts, maximum rain, and uninitialized edge states.

---

## the agent's Discretion

- Exact Bezier curve tension parameter for Fritsch-Carlson tangent calculation.
- Easing curves for accordion drawer expansion and multi-alert switching.
- Precise pixel offsets for graph axis labels.

## Deferred Ideas

- None — all requirements GRAPH-01 through GRAPH-04 and POPUP-01 through POPUP-07 are fully addressed within Phase 54.
- Prototype file cleanup (`TestPill.qml`, `TestPopup.qml`) will occur in Phase 55.
