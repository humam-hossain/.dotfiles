---
phase: 14
slug: script-backed-widgets
status: verified
threats_open: 0
asvs_level: 1
created: 2026-05-22
---

# Phase 14 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Process ↔ System | Quickshell services execute subprocesses (bash, awk, nmcli, ddcutil, etc.) via Process + StdioCollector | System metrics: CPU, memory, disk, network, backlight, notifications |
| Shell ↔ Filesystem | Service scripts read /proc/stat, df, sysfs, and Pipewire state | Read-only kernel/proc values, hardware registers |
| Network ↔ External | Weather/Forecast services fetch remote data; PingService pings external hosts | Weather data, latency, network status (read-only) |
| Service ↔ Widget | Singleton services expose readonly properties consumed by ModulePill widgets | Numerical values, formatted strings, icon text |
| Click ↔ Application | Widget MouseArea triggers startDetached() for nautilus, nmtui, swaync-client | No data flow — pure action dispatch |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-14-PROC-01 | Injection | All Process command arrays | mitigate | Static literal arrays (`["bash", "-c", "..."]`). No user input in any command string. Backlight write target is clamped integer 0–100. | closed |
| T-14-PROC-02 | Tampering | BacklightService ddcutil write | mitigate | delta clamped to ±100, target clamped to 0–100. Process uses StdioCollector for re-read confirmation. | closed |
| T-14-DOS-01 | Denial of Service | BacklightService rapid writes | mitigate | 300ms debounce timer gates ddcutil writes. Rapid calls accumulate into single pending delta. | closed |
| T-14-PROC-03 | Tampering | Service JSON parsing | mitigate | All parseInt/parse wrapped in try/catch. Malformed output falls back to "err". | closed |
| T-14-SYS-01 | Information Disclosure | /proc/stat CPU data | accept | Local system data visible only on same machine. No network exposure. | closed |
| T-14-NET-01 | Information Disclosure | nmcli SSID exposure | accept | SSID shown on bar — local display only, same as any network indicator. | closed |
| T-14-WID-01 | Injection | Widget Process.command | mitigate | Static literals: `["nautilus"]`, `["kitty", "-e", "nmtui"]`, `["swaync-client", "-t"]`, `["xdg-open", "http://localhost:8765/"]`. | closed |
| T-14-WID-02 | Tampering | BacklightWidget onWheel | mitigate | Service clamps cumulative delta to ±100 and writes to 0–100 range. Widget passes `5 * Math.sign(delta)` only. | closed |
| T-14-WID-03 | Denial of Service | NotificationWidget clicks | accept | Rapid clicking spawns concurrent swaync-client processes — system-managed, no resource exhaustion path. | closed |
| T-14-WID-04 | Elevation of Privilege | DiskWidget nautilus | accept | Launches nautilus as current user. No privilege escalation — same as running from terminal. | closed |
| T-14-WID-05 | Spoofing | Service text as QML Text | accept | Text rendering uses Catppuccin theme — no external content injection. Font rendering is safe. | closed |
| T-14-BAR-01 | Denial of Service | Missing widget imports | mitigate | All widget files compile without ToolTip references (ToolTip usage removed in 14-05 gap closure). No import-related crashes. | closed |
| T-14-BAR-02 | Elevation of Privilege | Widget process.spawn | mitigate | All Process.command arrays are static literals. try/catch + console.warn around startDetached(). No user data in arguments. | closed |
| T-14-OSD-01 | Denial of Service | Volume OSD show/hide cycling | accept | 1.5s hide timer prevents rapid cycling. PopupWindow has no keyboard focus — no event loop pressure. | closed |
| T-14-OSD-02 | Spoofing | Volume OSD opacity:0 | mitigate | Uses `visible: false` (P-03 compliant). Not `opacity: 0`. | closed |
| T-14-OSD-03 | Information Disclosure | Volume OSD volume % | accept | Volume percentage shown briefly on change. Local display only, auto-hides after 1.5s. | closed |
| T-14-GAP-01 | Tampering | widget .qml files (14-04) | accept | Read-only import line addition. No user-controlled inputs. | closed |
| T-14-GAP-05-01 | Information Disclosure | AudioService polling Timer | accept | AudioService polls wpctl for volume state every 500ms. Data never leaves local display. | closed |
| T-14-GAP-05-02 | Denial of Service | AudioService polling (500ms) | accept | 500ms interval is well within system capability. Single subprocess call per tick. | closed |
| T-14-GAP-05-03 | Tampering | widget .qml files (14-05) | accept | Read/write within existing patterns. No new attack surface introduced. | closed |
| T-14-06-01 | Information Disclosure | $HOME path in 4 services | accept | $HOME shell expansion in Process commands — local system path, no external exposure. | closed |
| T-14-06-02 | Denial of Service | Debug logging (temporary) | mitigate | All console.warn/log/debug calls removed before final commit (verified by grep). | closed |
| T-14-07-01 | Denial of Service | AudioService wpctl polling | accept | 500ms wpctl subprocess — lightweight, single call per interval. No fork bomb risk. | closed |
| T-14-07-02 | Tampering | NetworkService nmcli fields | accept | nmcli output uses lastIndexOf for colon-safe SSID parsing. No injection vector. | closed |
| T-14-07-03 | Information Disclosure | NetworkService device/SSID | accept | SSID shown on bar — local display only. Same as any network status indicator. | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-01 | T-14-SYS-01 | /proc/stat CPU data visible on local bar — same as `top` or `btop` on same machine | design | 2026-05-22 |
| AR-02 | T-14-NET-01 | SSID shown on bar — local display only, no network transmission | design | 2026-05-22 |
| AR-03 | T-14-WID-03 | Rapid notification clicks spawn concurrent swaync-client — system-managed, no DoS path | design | 2026-05-22 |
| AR-04 | T-14-WID-04 | nautilus launches as current user — same as terminal invocation | design | 2026-05-22 |
| AR-05 | T-14-WID-05 | QML Text rendering of Catppuccin-themed service text — no injection | design | 2026-05-22 |
| AR-06 | T-14-OSD-01 | Volume OSD 1.5s hide timer prevents cycling issues | design | 2026-05-22 |
| AR-07 | T-14-OSD-03 | Volume % shown on local display, auto-hides after 1.5s | design | 2026-05-22 |
| AR-08 | T-14-GAP-01 | Import line addition — no new attack surface | design | 2026-05-22 |
| AR-09 | T-14-GAP-05-01 | Audio wpctl polling — local state, never transmitted | design | 2026-05-22 |
| AR-10 | T-14-GAP-05-02 | 500ms wpctl — single call, low resource impact | design | 2026-05-22 |
| AR-11 | T-14-GAP-05-03 | Widget edits within existing patterns — no new surface | design | 2026-05-22 |
| AR-12 | T-14-06-01 | $HOME in shell command — local path, no exposure | design | 2026-05-22 |
| AR-13 | T-14-07-01 | wpctl at 500ms — lightweight, bounded | design | 2026-05-22 |
| AR-14 | T-14-07-02 | nmcli field parsing — colon-safe, no injection | design | 2026-05-22 |
| AR-15 | T-14-07-03 | SSID on bar — local display only | design | 2026-05-22 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-05-22 | 26 | 26 | 0 | gsd-security-auditor |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-05-22
