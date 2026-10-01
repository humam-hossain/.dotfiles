---
phase: "45"
slug: "network-multi-target-ping-component-pill-popup"
status: verified
threats_open: 0
asvs_level: 1
created: "2026-09-29"
---

# Phase 45 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Kernel /proc/net/dev & /sys/class/hwmon → QML Services | Parsing kernel procfs/sysfs virtual file tables into QML properties | Network throughput and NIC temp telemetry |
| Status Bar UI → Mouse & Pointer Events | Pill MouseArea event handling interacting with status bar click handlers | Pointer and click events |
| QML UI Runtime → External Process Execution | Spawning xdg-open to launch web dashboard | Process execution via execDetached |
| QML Scenegraph → Wayland Layer-Shell | Popup window geometry, placement, and screen edge clamping | Window geometry and rendering |
| Quickshell runtime → Local Ping Daemon | Consuming JSON status payload from loopback port 8765 | HTTP / XMLHttpRequest JSON data |
| GNU Stow symlinks → Upstream dots-hyprland | Overlay file packaging without contaminating vendor submodule | Leaf symlink mappings |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-45-SC | Tampering | Test harness execution | low | mitigate | `scripts/phase45-network-ping-assert.sh` runs with `set -euo pipefail` and fails closed if run as root (`EUID == 0`). | closed |
| T-45-01 | Denial of Service | Telemetry parsing & polling loops | medium | mitigate | Enforce FileView procfs reading (<1ms) instead of subprocess spawning; clamp rate deltas ($\max(0, \Delta)$) and enforce non-zero fallbacks to prevent division by zero or NaN rendering. | closed |
| T-45-02 | Elevation of Privilege / Tampering | Status bar mouse event bleeding | medium | mitigate | Re-parent `MouseArea` to `root` with `anchors.fill: parent` and `acceptedButtons: Qt.AllButtons`, explicitly isolating left-click browser launch from status bar toggle handlers. | closed |
| T-45-03 | Command Injection | External URL launch | medium | mitigate | Use `Quickshell.execDetached(["xdg-open", "http://127.0.0.1:8765/"])` passing arguments as an array without shell invocation (`bash -c`), preventing command injection; endpoint URL is hardcoded loopback. | closed |
| T-45-04 | Denial of Service | NetworkPingPopup layout geometry | medium | mitigate | Fixed 320px column widths and trailing vertical spacers prevent layout expansion cycles; total popup width (673px) fits safely within layer-shell bounds. | closed |
| T-45-05 | Information Disclosure / Spoofing | Unvalidated Daemon Responses | medium | mitigate | `PingService.qml` wraps JSON parsing in try/catch and falls back to `handleOffline()` on error or timeout; `NetworkPingPopup` gracefully handles null/undefined latency readouts with "-- ms" fallback. | closed |
| T-45-06 | Tampering / Drift | Stow package structure | high | mitigate | Strictly manage overlay files in `restow/quickshell/` without folding parent directories and enforce zero drift via `./arch/dots-hyprland.sh verify --strict`. | closed |
| T-45-07 | Denial of Service | Process Flooding on Fast-Polling | medium | mitigate | Fast polling (1000ms) is demand-gated strictly while `active` is true and reverted immediately on destruction/close, maintaining CPU wakeups within budget. | closed |

*Status: open · closed · open — below high threshold (non-blocking)*  
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*  
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*  

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| R-45-01 | T-45-SC | Test script root execution prevention accepted as sufficient safeguard | Orchestrator | 2026-09-29 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-09-29 | 8 | 8 | 0 | Antigravity Orchestrator |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-09-29
