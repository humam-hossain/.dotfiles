---
phase: 02
slug: core-bar-modules
status: verified
threats_open: 0
asvs_level: 1
created: 2026-07-23
verified: 2026-07-23
register_authored_at_plan_time: false
---

# Phase 02 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.
> Retroactive STRIDE (no `<threat_model>` in PLAN.md at plan time). ASVS L1.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Local user session | Quickshell bar runs as logged-in user | QML, GlobalStates, Hyprland IPC |
| Host filesystem | Config dual-write `Config.qml` ↔ `~/.config/illogical-impulse/config.json` | Bar/time/tray/workspace keys |
| System services | PipeWire/Pulse (Audio), NetworkManager (Network), StatusNotifier (tray) | Volume, mute, wifi state, tray icons |
| Optional network (vendored) | Left sidebar AI/Anime panes (not Phase 2 goal surface) | HTTP when user opens left sidebar |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-02-01 | Tampering | Config dual-write + phase02-config-assert.py | medium | mitigate | Assert script validates live keys; dual-write keeps defaults and live JSON aligned | closed |
| T-02-02 | Elevation | Workspaces.qml Hyprland.dispatch | medium | mitigate | Stock `workspace` / `workspace r±1` only — no plugin focus dispatcher (D-04) | closed |
| T-02-03 | Spoofing | SysTray / StatusNotifier items | low | accept | Tray icons from session bus; activation is user-click only | closed |
| T-02-04 | Information disclosure | Network.materialSymbol on bar | low | mitigate | SSID/signal not on bar; details only in right sidebar (D-09/D-10) | closed |
| T-02-05 | Denial of service | barLeftSideMouseArea / ScreenCorners sidebar open | medium | mitigate | G-02-13: empty-bar click and cornerOpen disabled; LeftSidebarButton sole open path | closed |
| T-02-06 | Injection | Audio.toggleMute / toggleMicMute from bar icons | low | mitigate | Local PipeWire/Pulse toggles only; no shell interpolation in bar click handlers | closed |
| T-02-07 | Information disclosure | Left sidebar AI/Anime (vendored) | medium | accept | Out of Phase 2 success criteria; UAT logs show load-time nulls only when user opens sidebar | closed |

*Severity: critical > high > medium > low — only open threats at or above `workflow.security_block_on` (high) count toward threats_open*  
*Disposition: mitigate · accept · transfer*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-02-01 | T-02-03 | Session-local tray SNI is expected desktop model | phase 02 security review | 2026-07-23 |
| AR-02-02 | T-02-07 | AI/Anime sidebar not Phase 2 BAR-01..04 surface; residual load warnings when opened | phase 02 UAT + security | 2026-07-23 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-07-23 | 7 | 7 | 0 | orchestrator-inline (retroactive STRIDE, ASVS L1) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-07-23
