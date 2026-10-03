# Phase 52: Weather Service Singleton & Material Glyph Mapping - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-10-03T17:45:00+06:00
**Phase:** 52-Weather Service Singleton & Material Glyph Mapping
**Areas discussed:** Service Singleton Architecture, Reactive Data Normalization, Material Symbols Glyph Mapping, Theme Color Tokens for AQI & Alerts

---

## Service Singleton Architecture

### Question 1: Singleton Filename & Upstream Integration Strategy
| Option | Description | Selected |
|--------|-------------|----------|
| Override upstream Weather.qml | Override upstream Weather.qml directly in restow/quickshell/ — exposes both modern properties (current, hourly, aqi) and legacy Weather.data.* compatibility for existing widgets | ✓ |
| Separate WeatherService.qml | Create a separate WeatherService.qml singleton — leaves upstream Weather.qml untouched and builds an isolated v0.10 service | |
| WeatherService.qml + shim | Create WeatherService.qml as core engine, with a thin Weather.qml overlay shim forwarding to it | |
| the agent's Discretion | Pick the cleanest architecture that avoids code duplication | |

**User's choice:** Override upstream Weather.qml directly in restow/quickshell/ — exposes both modern properties (current, hourly, aqi) and legacy Weather.data.* compatibility for existing widgets.
**Notes:** Prevents breaking existing desktop background widgets like `WeatherWidget.qml` while providing the modern interface for Milestone v0.10.

### Question 2: Cache File Observation & Reactivity
| Option | Description | Selected |
|--------|-------------|----------|
| FileView + Fallback Poll | FileView with watchChanges: true + fallback low-frequency poll timer (e.g. 60s) — ensures instant update on inotify events while guaranteeing recovery if atomic rename misses a watcher tick | ✓ |
| FileView Only | Strictly reactive FileView only (watchChanges: true) with zero polling timers — purest event-driven architecture to keep quiescent CPU minimal | |
| the agent's Discretion | Use the safest pattern that prevents missed updates on atomic file replacement | |

**User's choice:** FileView with watchChanges: true + fallback low-frequency poll timer (e.g. 60s).
**Notes:** 60-second backup poll protects against atomic tempfile replacement inotify edge cases on tmpfs without adding CPU overhead.

### Question 3: Cache Path Resolution & Cold-Boot Fallback
| Option | Description | Selected |
|--------|-------------|----------|
| Dynamic Path + Persistent Fallback | Resolve runtime path via Quickshell.env("XDG_RUNTIME_DIR") + fallback to persistent state (~/.local/state/weather/last_known_weather.json) if runtime cache is absent | ✓ |
| Strict Runtime Path | Strictly target $XDG_RUNTIME_DIR/weather/weather.json with a built-in empty/offline JSON skeleton fallback — no secondary disk read | |
| the agent's Discretion | Pick the most reliable fallback hierarchy for cold boot | |

**User's choice:** Resolve runtime path via Quickshell.env("XDG_RUNTIME_DIR") + fallback to persistent state (~/.local/state/weather/last_known_weather.json) if runtime cache is absent.
**Notes:** Matches the persistent caching layer designed in Phase 51 (D-51-08).

### Question 4: Manual Refresh Handling
| Option | Description | Selected |
|--------|-------------|----------|
| UI Refresh Button | Provide refresh() invoking systemctl --user start wwo-fetcher.service with a 10s cooldown debounce | |
| Passive Only | Weather.qml only reloads the local cache file; external network fetching remains strictly timer-driven by systemd | |
| User Write-in | "no need for any refresh button" | ✓ |

**User's choice:** "no need for any refresh button" — passive observation only.
**Notes:** Network fetches remain strictly timer-driven by systemd; eliminates UI complexity and protects daily API call budget.

---

## Reactive Data Normalization

### Question 1: Reactive Properties Structure
| Option | Description | Selected |
|--------|-------------|----------|
| Grouped Properties | Grouped reactive properties — root.current (temp, desc, glyph, etc.), root.hourly (24-item array of normalized hourly objects), root.aqi, root.astronomy, root.alerts, and root.isStale/isOffline | ✓ |
| Flat Properties | Flat root properties — individual properties for each metric (root.temperature, root.humidity, root.uv, etc.) plus raw arrays for hourly and alerts | |
| Raw JSON Object | Keep parsed JSON object raw — expose root.data directly and provide helper getter methods | |
| the agent's Discretion | Pick the structure best suited for QtQuick Canvas and QML property bindings | |

**User's choice:** Grouped reactive properties — root.current, root.hourly, root.aqi, root.astronomy, root.alerts, and root.isStale/isOffline.
**Notes:** Clean, organized API for downstream status bar pills, graphs, and popups.

### Question 2: Hourly Forecast Array Normalization
| Option | Description | Selected |
|--------|-------------|----------|
| Pre-normalized Numbers | Pre-normalized numbers & pre-resolved glyphs — time, hour, tempC, feelsLikeC, chanceOfRain, precipMM, glyph, isDayTime | |
| Raw JSON Objects | Raw JSON objects with strings preserved — downstream components parse values on-demand using parseInt/parseFloat | ✓ |
| the agent's Discretion | Optimize strictly for Canvas 2D render performance and zero garbage collection in hover scrub | |

**User's choice:** Raw JSON objects with strings preserved — downstream components parse values on-demand using parseInt/parseFloat.
**Notes:** Keeps the singleton lightweight by avoiding unnecessary transformation of 24 hourly objects on each cache reload.

### Question 3: Unit System Handling
| Option | Description | Selected |
|--------|-------------|----------|
| Dual Exposure | Dual exposure with config binding — provide explicit metric properties alongside helper display strings reacting to Config.options.bar.weather.useUSCS | |
| Metric-First Direct | Expose tempC, feelsLikeC, precipMM directly; let UI components format units as needed | |
| Strictly Celsius & Metric | Strictly Celsius & Metric only — no USCS conversion logic in the service | ✓ |
| the agent's Discretion | Keep backward compatibility with Config.options.bar.weather.useUSCS | |

**User's choice:** Strictly Celsius & Metric only — no USCS conversion logic in the service.
**Notes:** Follows project requirements (BAR-02, GRAPH-01, POPUP-03) which mandate Celsius, km/h, mm, and hPa.

### Question 4: Cold-Boot / Missing Cache Default State
| Option | Description | Selected |
|--------|-------------|----------|
| Safe Defaults | Safe placeholder defaults — root.current with tempC: "--", desc: "Offline", glyph: "cloud_off", empty arrays for hourly/alerts, prevents QML TypeError null dereferences | ✓ |
| Null / Undefined | Leave properties null when data is missing and rely on QML optional chaining | |
| the agent's Discretion | Ensure zero console TypeError spam on cold boot before first fetch | |

**User's choice:** Safe placeholder defaults — root.current with tempC: "--", desc: "Offline", glyph: "cloud_off", empty arrays for hourly/alerts, prevents QML TypeError null dereferences.
**Notes:** Guarantees zero console noise on boot.

---

## Material Symbols Glyph Mapping

### Question 1: Organization of WeatherGlyphs Mapper
| Option | Description | Selected |
|--------|-------------|----------|
| Dedicated Singleton in services/ | Dedicated WeatherGlyphs.qml singleton in services/ with helper getGlyph(code, isDaytime) + Weather.current.glyph pre-bound for instant access | ✓ |
| Component in modules/common/ | Component in modules/common/WeatherGlyphs.qml — accessible like Icons.qml across all modules | |
| Inline in Weather.qml | Inline inside Weather.qml without a separate singleton file | |
| the agent's Discretion | Place it where it follows established Quickshell module conventions | |

**User's choice:** Dedicated WeatherGlyphs.qml singleton in services/ with helper getGlyph(code, isDaytime) + Weather.current.glyph pre-bound for instant access.
**Notes:** Clean separation of concerns between data ingestion (Weather.qml) and meteorological visualization (WeatherGlyphs.qml).

### Question 2: Day vs Night Mapping Structure
| Option | Description | Selected |
|--------|-------------|----------|
| Two-Level Dictionary | Two-level dictionary with day/night branches for sky conditions (clear_day/clear_night, partly_cloudy_day/partly_cloudy_night) and universal glyphs for obscured conditions (rainy, thunderstorm, foggy, snowing) | ✓ |
| Explicit Day & Night Entries | Explicit day & night entry for every single WWO code ({ day: '...', night: '...' }) | |
| the agent's Discretion | Ensure clean lookup performance with zero undefined results | |

**User's choice:** Two-level dictionary with day/night branches for sky conditions and universal glyphs for obscured conditions.
**Notes:** Efficient and deterministic; handles all 40+ WWO codes.

### Question 3: Fallback Glyph for Unknown Weather Codes
| Option | Description | Selected |
|--------|-------------|----------|
| Universal Neutral "cloud" | Universal neutral fallback "cloud" — consistent with upstream Icons.qml and unambiguous for unrecognized conditions | ✓ |
| Contextual Fallback | Contextual fallback based on isdaytime — "clear_night" at night, "clear_day" during daytime, "cloud" if unknown | |
| the agent's Discretion | Choose the safest glyph that renders reliably across all Material Symbols font variants | |

**User's choice:** Universal neutral fallback "cloud" — consistent with upstream Icons.qml and unambiguous for unrecognized conditions.
**Notes:** Predictable, graceful degradation.

### Question 4: Standardized Atmospheric Metric Glyphs
| Option | Description | Selected |
|--------|-------------|----------|
| Centralize Metric Glyphs | Yes, centralize metric glyphs in WeatherGlyphs — humidity (water_drop), pressure (speed), uv (wb_sunny), visibility (visibility), wind (air), sunrise (wb_twilight), alert (warning) | ✓ |
| Condition Codes Only | Condition codes only — WeatherGlyphs maps weatherCode only; popup components specify their own inline metric icons | |
| the agent's Discretion | Evaluate if centralizing metric icons improves UI consistency | |

**User's choice:** Yes, centralize metric glyphs in WeatherGlyphs — humidity (water_drop), pressure (speed), uv (wb_sunny), visibility (visibility), wind (air), sunrise (wb_twilight), alert (warning).
**Notes:** Single source of truth for all weather-related iconography.

---

## Theme Color Tokens for AQI & Alerts

### Question 1: Air Quality Index (US-EPA 1–6) Color Mapping
| Option | Description | Selected |
|--------|-------------|----------|
| Standard AQI Spectrum + M3 Tuning | Standard AQI color spectrum with M3 theme contrast tuning — EPA 1 Good (Green), 2 Moderate (Yellow), 3 Sensitive (Orange), 4 Unhealthy (Red), 5 Very Unhealthy (Purple), 6 Hazardous (Maroon) with M3 background/text pairings | ✓ |
| Strict Material You Role Tokens | Map EPA 1 to m3primary, 2 to m3secondary, 3 to m3tertiary, 4 to m3errorContainer, 5-6 to m3error | |
| the agent's Discretion | Pick the color mapping that gives the clearest visual warning hierarchy | |

**User's choice:** Standard AQI color spectrum with M3 theme contrast tuning.
**Notes:** Preserves internationally recognized health color standards while tuning luminosity for dark theme contrast.

### Question 2: Alert Severity Tier Mapping
| Option | Description | Selected |
|--------|-------------|----------|
| Three-Tier Alert Mapping | Three-tier alert mapping — Warning/Extreme -> m3error, Watch/Severe -> Amber/m3errorContainer, Advisory/Statement -> m3secondary/tertiary | ✓ |
| Binary Mapping | Binary mapping — all active alerts use m3error with m3onErrorContainer for maximum urgency | |
| the agent's Discretion | Match the notification/warning conventions in dots-hyprland | |

**User's choice:** Three-tier alert mapping — Warning/Extreme -> m3error, Watch/Severe -> Amber/m3errorContainer, Advisory/Statement -> m3secondary/tertiary.
**Notes:** Provides clear visual distinction between catastrophic warnings and minor advisories.

### Question 3: Location of Color Mapping Functions
| Option | Description | Selected |
|--------|-------------|----------|
| WeatherGlyphs + Pre-bind on Weather | Expose color functions in WeatherGlyphs + pre-bind computed color on Weather.aqi.color and Weather.alerts[i].color for direct consumption in UI bindings | ✓ |
| Direct in Weather.qml | Implement color lookup methods directly in Weather.qml without WeatherGlyphs involvement | |
| the agent's Discretion | Place them where they maintain consistent separation of concerns | |

**User's choice:** Expose color functions in WeatherGlyphs + pre-bind computed color on Weather.aqi.color and Weather.alerts[i].color for direct consumption in UI bindings.
**Notes:** UI components can bind directly to `Weather.aqi.color` without needing separate function calls.

### Question 4: Stale and Offline Visual Indication
| Option | Description | Selected |
|--------|-------------|----------|
| Dimmed Tone + cloud_off | Dimmed tone via m3onSurfaceVariant / m3outline + small cloud_off indicator — keeps data readable while clearly communicating stale/offline state | ✓ |
| Accent Tint | Accent tint using m3errorContainer — actively highlights that telemetry is stale | |
| the agent's Discretion | Follow the established pattern used by PingService and NetworkPingPill for offline state | |

**User's choice:** Dimmed tone via m3onSurfaceVariant / m3outline + small cloud_off indicator.
**Notes:** Graceful degradation that indicates age without alarming the user.

---

## the agent's Discretion
- Fallback poll timer set to 60s for zero CPU overhead.
- Compatibility bridge regex and field extraction matching upstream `Weather.qml` behaviors.
- Precise contrast tuning for AQI hex colors against dark container backgrounds.

## Deferred Ideas
- None — all topics fell strictly within Phase 52 scope.
