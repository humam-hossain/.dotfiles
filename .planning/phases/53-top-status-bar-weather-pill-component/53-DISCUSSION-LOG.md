# Phase 53: Top Status Bar Weather Pill Component - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-10-05T15:58:00+06:00  
**Phase:** 53-top-status-bar-weather-pill-component  
**Areas discussed:** Pill architecture, Alert indicator design, Temperature & glyph layout, Popup wiring  

---

## Pill Architecture

### Q1: Weather Pill Structure
| Option | Description | Selected |
|--------|-------------|----------|
| Override upstream WeatherBar.qml in-place | Create `restow/quickshell/.../bar/weather/WeatherBar.qml` that shadows vendor file via Stow. BarContent.qml stays unchanged. | ✓ |
| Create a new WeatherPill.qml alongside upstream WeatherBar | Modify BarContent.qml to replace WeatherBar Loader with WeatherPill. | |
| Rename to WeatherPill.qml AND update BarContent.qml | Both files in restow overlay. | |

**User's choice:** Override upstream WeatherBar.qml in-place.  
**Notes:** Reaffirmed during conflict review: BarContent.qml must stay untouched to preserve seamless upstream updates.

### Q2: Root Component Type
| Option | Description | Selected |
|--------|-------------|----------|
| Single WeatherBar.qml with MouseArea root | Sits inside BarContent.qml's existing outer BarGroup wrapper with zero redundant borders. | ✓ |
| BarGroup as root | Would result in double-nested BarGroup inside BarContent.qml. | |

**User's choice:** Single WeatherBar.qml with MouseArea root (refined during conflict resolution).  
**Notes:** BarContent.qml line 197 already provides the outer BarGroup wrapper.

### Q3: Data Path
| Option | Description | Selected |
|--------|-------------|----------|
| Modern Weather.current.* properties | Direct bindings to `tempC`, `glyph`, `desc`. | ✓ |
| Legacy bridge Weather.data.* | Compatibility layer properties. | |

**User's choice:** Modern Weather.current.* properties directly.

### Q4: Right-Click Behavior
| Option | Description | Selected |
|--------|-------------|----------|
| Remove right-click refresh | Systemd user timer handles refreshes; clicks absorbed. | ✓ |
| Preserve upstream right-click refresh | Keep `Weather.getData()` + `notify-send`. | |
| Both clicks toggle popup | Mirror left-click. | |

**User's choice:** Remove right-click refresh.

### Q5: Cold Boot & Stale Data State
| Option | Description | Selected |
|--------|-------------|----------|
| Dim text & glyph with m3onSurfaceVariant | Preserve last-known temperature reading; show `cloud_off` on cold boot. | ✓ |
| Warning dot indicator | Show subtle indicator dot beside temp. | |
| Strict offline display | Replace temp with `--°C` and glyph with `cloud_off`. | |

**User's choice:** Dim text & glyph with m3onSurfaceVariant while preserving last-known temperature.

### Q6: Multi-Monitor & Vertical Bar Support
| Option | Description | Selected |
|--------|-------------|----------|
| Uniform multi-monitor + full vertical bar support | Stacks glyph above temp on vertical bar; renders on all enabled screens. | ✓ |
| Primary monitor only / horizontal only | Constrain rendering. | |

**User's choice:** Uniform multi-monitor + full vertical bar support.

---

## Alert Indicator Design

### Q1: Imminent Rain Presentation
| Option | Description | Selected |
|--------|-------------|----------|
| Contextual rain badge | Secondary `water_drop` icon + rain % in a `Revealer` when chance > 50% in upcoming 2–3 hours. | ✓ |
| Subtle badge dot | Small colored indicator dot without extra text. | |
| Tint condition glyph | Tint main icon to blue. | |

**User's choice:** Contextual rain badge.

### Q2: Severe Weather Alerts
| Option | Description | Selected |
|--------|-------------|----------|
| Warning icon + alert color | Render `warning` MaterialSymbol with 3-loop breathing pulse animation settling at full opacity. | ✓ |
| Solid alert tint | Tint condition glyph and background. | |
| Alert badge dot | Corner badge dot. | |

**User's choice:** Warning icon + alert color with 3-loop breathing pulse animation.

### Q3: Alert Precedence & Time Window
| Option | Description | Selected |
|--------|-------------|----------|
| Severe alert takes precedence | Severe alert warning icon suppresses rain badge; time window is next 2–3 hours. | ✓ |
| Show both side-by-side | Render both icons. | |

**User's choice:** Severe alert takes precedence; check next 2–3 hours window.

### Q4: Rain Badge Persistence & Color
| Option | Description | Selected |
|--------|-------------|----------|
| Persistent rain badge with m3primary color | Keep rain % visible even during ongoing rain; style with `Appearance.m3colors.m3primary`. | ✓ |
| Suppress if already raining / monochrome | Hide if already raining. | |

**User's choice:** Persistent rain badge with m3primary color.

---

## Temperature & Glyph Layout

### Q1: Temperature Unit & Format
| Option | Description | Selected |
|--------|-------------|----------|
| Integer Celsius with unit suffix `XX°C` | Drops `C` (`XX°`) only on hella-shortened displays (`useShortenedForm === 2`). | ✓ |
| Compact degree only `XX°` | Legacy format. | |
| Unconditional `XX°C` | Never truncate. | |

**User's choice:** Integer Celsius with unit suffix `XX°C`.

### Q2: Glyph & Typography Sizing
| Option | Description | Selected |
|--------|-------------|----------|
| Large glyph (`font.pixelSize.large`) + small text (`font.pixelSize.small`) | Matches upstream WeatherBar proportions; 4px spacing; outline `fill: 0`. | ✓ |
| Normal glyph + small text | Smaller scale. | |

**User's choice:** Large glyph + small text.

### Q3: Element Ordering & Animations
| Option | Description | Selected |
|--------|-------------|----------|
| Leading Alert -> Glyph -> Temp -> Trailing Rain | `[⚠ Alert]` -> `[Glyph]` -> `[XX°C]` -> `[💧 Rain%]`; dynamic badges in `Revealer`; 200ms `expressiveEffects` ColorAnimation. | ✓ |
| Standard sequential | Glyph -> Temp -> Badges. | |

**User's choice:** Leading Alert -> Glyph -> Temp -> Trailing Rain with Revealers.

### Q4: Temperature Range Styling
| Option | Description | Selected |
|--------|-------------|----------|
| Neutral `colOnLayer1` across all temperatures | Neutral for sub-freezing and summer heat; avoids alert fatigue. | ✓ |
| Temperature-dependent color shifts | Blue for freezing, amber for heat. | |

**User's choice:** Neutral `colOnLayer1` across all temperatures.

---

## Popup Wiring

### Q1: Popup Target Component
| Option | Description | Selected |
|--------|-------------|----------|
| Wire to upstream WeatherPopup via StyledPopup | Immediate functional popup in Phase 53; cleanly superseded by Phase 55 multi-modal inspector. | ✓ |
| Placeholder empty popup | Defer all visuals. | |

**User's choice:** Wire to upstream WeatherPopup via StyledPopup.

### Q2: Trigger & Interaction Model
| Option | Description | Selected |
|--------|-------------|----------|
| Hover-only via 1000ms hover intent delay | Clicks ignored/absorbed; rely on StyledPopup built-ins for exit grace period, boundary clamping, and Escape dismissal. | ✓ |
| Dual trigger (click + hover) | Both triggers active. | |
| Click-only | Hover disabled. | |

**User's choice:** Hover-only via 1000ms hover intent delay; rely on StyledPopup built-in exit delay and Escape handling.

### Q3: Lifecycle Tracking & Multi-Monitor
| Option | Description | Selected |
|--------|-------------|----------|
| Per-pill instance instantiation with `popupActive` property | Guarantees clean per-monitor coordinates; exposes `readonly property bool popupActive` for Phase 54 canvas throttling. | ✓ |
| Global shared popup | Single instance. | |

**User's choice:** Per-pill instance instantiation with `popupActive` property.

---

## the agent's Discretion
- Exact easing curve parameters for the Revealer animations (following `Appearance.animation.elementMoveFast`).
- Internal layout container type (`RowLayout` vs `GridLayout`).

## Deferred Ideas
- Interactive 24-hour Canvas graph with Bezier splines (Phase 54).
- Rich multi-modal popup inspector with Air Quality, Wind Compass, Astronomy, and Alert banner (Phase 55).
