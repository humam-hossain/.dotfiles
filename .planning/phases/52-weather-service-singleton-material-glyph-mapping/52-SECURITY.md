---
phase: "52"
slug: "weather-service-singleton-material-glyph-mapping"
status: verified
threats_open: 0
asvs_level: 1
created: "2026-10-03"
updated: "2026-10-03"
---

# Phase 52 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Cache File → QML Engine | Read-only `FileView` observation of tmpfs weather envelope (`$XDG_RUNTIME_DIR/weather/weather.json`) | Inbound JSON telemetry data (current, hourly, aqi, astronomy, alerts) |
| QML Service → UI Components | Reactive property bindings, Material You tokens, and legacy facade | Structured properties exported to `WeatherWidget.qml` and future desktop widgets |
| Restow Symlink Farm → User Config | Deployment of `restow/quickshell` package to `~/.config/quickshell/ii/services/` | Discrete QML singleton service leaf symlinks |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-52-01 | Input Validation | Input Validation & Fallbacks (`WeatherGlyphs.qml`, `Weather.qml`) | high | mitigate | Defensive input normalization for `isdaytime` (boolean, string, integer), universal neutral fallback (`"cloud"`) for invalid/empty codes, and cold-boot defaults (`"--"`, `"cloud_off"`, `"Offline"`) prevent script exceptions or UI crashes. Tested in Section 2 & 4. | closed |
| T-52-02 | Integrity | Symlink & File Deployment (`restow/quickshell`) | high | block | GNU Stow canonical leaf symlinks verified; vendor backup artifact `Weather.qml.bak` preserved without drift; non-root execution enforced in assertion harness. Tested in Section 1. | closed |
| T-52-03 | Denial of Service | Process Execution & Overhead (`Weather.qml`) | high | mitigate | Eliminated upstream `Process` subshells and curl/wttr.in calls in favor of passive `Quickshell.Io.FileView` inotify disk observation with 60-second fallback timer ($\le 0.01\%$ CPU). Tested in Section 4 & 5. | closed |
| T-52-04 | Information Disclosure | Secret Isolation (`Weather.qml`) | high | block | QML singletons strictly observe local unprivileged JSON cache; no access to `WWO_API_KEY` or credential storage (`~/.config/weather/.env`). Secrets remain isolated in background fetcher. Tested in Section 4. | closed |

*Status: closed (4/4 threats resolved)*  
*Severity: critical > high > medium > low*  
*Disposition: mitigate (implementation required) · accept (documented risk) · block (strict gate)*  

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| R-52-01 | T-52-03 | 60-second inotify fallback timer in QML provides recovery against inode invalidation during atomic cache replacement with negligible timer overhead | Orchestrator | 2026-10-03 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-03 | 4 | 4 | 0 | Antigravity Orchestrator |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / block)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-10-03
