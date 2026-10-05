---
phase: "53"
slug: "top-status-bar-weather-pill-component"
status: verified
threats_open: 0
asvs_level: 1
created: "2026-10-05"
updated: "2026-10-05"
---

# Phase 53 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Quickshell Scenegraph → QML Components | Event handling and user interactions within the top status bar | Mouse click/press/hover events absorbed by `WeatherBar.qml` root `MouseArea` |
| Weather Service → WeatherBar Pill | Reactive property bindings consuming `Weather` and `WeatherGlyphs` singletons | Telemetry properties (`tempC`, `glyph`, `alerts`, `hourly`) |
| Restow Symlink Farm → User Config | Deployment of `restow/quickshell` overlay to `~/.config/quickshell/ii/modules/ii/bar/weather/` | Discrete QML component leaf symlinks (`WeatherBar.qml`) |
| Test Harness → System State | Execution of automated assertions in `scripts/phase53-weather-assert.sh` | Read-only file inspection, QML AST checks, and sandboxed Node.js VM execution |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-53-01 | Least Privilege | Process Execution (`scripts/phase53-weather-assert.sh`) | high | block | ASVS L1 Least Privilege Guard: script immediately fails closed if executed with superuser privileges (`EUID == 0`). Tested in Section 1. | closed |
| T-53-02 | Input Validation | Telemetry Parsing & Fallbacks (`WeatherBar.qml`) | high | mitigate | Safe numeric coercion via `Math.round(Number(Weather.current.tempC))` with safe `"--"` fallback prevents NaN poisoning; condition glyph falls back cleanly to `cloud_off` or `cloud`. Tested in Section 3. | closed |
| T-53-03 | UI Interaction | Event Bubbling & Scenegraph Hijacking (`WeatherBar.qml`) | medium | mitigate | Root `MouseArea` absorbs all button clicks (`event.accepted = true`) and eliminates deprecated right-click manual refresh, preventing unwanted click-through into desktop background. Tested in Section 5. | closed |
| T-53-04 | Repository Integrity | Vendor Tree Hygiene & Stow Deployment (`vendor/dots-hyprland`, `restow/quickshell`) | high | block | `BarContent.qml` kept 100% UNTOUCHED (0 diff lines); vendor tree remains pristine; GNU Stow leaf symlink deployed with safe `.bak` preservation; verified by `./arch/dots-hyprland.sh verify --strict`. Tested in Sections 1 & 2. | closed |
| T-53-05 | Confidentiality | Secret Isolation (`WeatherBar.qml`, `phase53-weather-assert.sh`) | high | block | STRICT PROHIBITION: Zero access to credential stores or `.env`. Component binds solely to public telemetry singletons. Tested in Sections 1 & 3. | closed |

*Status: closed (5/5 threats resolved)*  
*Severity: critical > high > medium > low*  
*Disposition: mitigate (implementation required) · accept (documented risk) · block (strict gate)*  

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| R-53-01 | T-53-03 | 1000ms hover intent delay inherited from `StyledPopup` prevents accidental popup flashing during fast cursor traversal | Orchestrator | 2026-10-05 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-05 | 5 | 5 | 0 | Antigravity Orchestrator |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / block)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-10-05
