---
phase: "49"
slug: "quickshell-resource-profiling-component-performance-audit"
status: verified
threats_open: 0
asvs_level: 1
created: "2026-09-30"
updated: "2026-09-30"
---

# Phase 49 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Test Harness Process → System Environment | Assertion script execution validating local file contents, AST structures, and system procfs/sysfs | Process execution, exit codes, procfs telemetry |
| Cursor Automation Engine → Wayland Compositor | Synthetic pointer input dispatch via `ydotool` on DP-1 display | Virtual uinput mouse move coordinates |
| External IPC Client → Quickshell Daemon | Quickshell IPC socket triggers toggling layer shell popups | Local socket commands (`qs -c ii ipc call <target> open/close`) |
| External Subprocess → QML Event Loop | Audio visualizer subprocess (`cava`) streaming frequency data over stdout pipe | Pipe stdout stream into Qt SplitParser |
| GNU Stow Symlink Farm → Live Home Directory (`$HOME/.config/`) | File system symlink mapping linking repository overlays to runtime desktop environment | Filesystem inodes and leaf symlinks |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-49-01 | Tampering | Test harness execution (`scripts/phase49-audit-assert.sh`) | low | mitigate | Script executes with `set -euo pipefail`, non-root execution check (`EUID != 0`), signal traps on `EXIT INT TERM`, and non-destructive read-only assertions. | closed |
| T-49-02 | Denial of Service | External GPU decode pollution during baseline capture | medium | mitigate | `scripts/profile-quickshell.sh` implements `check_and_pause_media` to pause MPRIS players before sampling, eliminating spurious video/audio decode load. | closed |
| T-49-03 | Tampering | Upstream baseline measurement environment isolation | medium | mitigate | Isolated upstream state via `stow -D` without modifying repository files or persistent configs, and restored immediately via `stow -R`. | closed |
| T-49-04 | UI Spoofing / Unintended Action | Automated mouse navigation via `ydotool` | medium | mitigate | Calibrated coordinates targeted precisely to top status bar pills at `Y=10` with verified neutral center reset `(860, 360)` on teardown. | closed |
| T-49-05 | Denial of Service / Hang | IPC overlay open/close toggles | low | mitigate | IPC calls use non-blocking commands (`2>/dev/null || true`) with bounded sleep intervals and layer surface presence verification. | closed |
| T-49-06 | Denial of Service | Unbounded visualizer process execution (`cava`) | high | mitigate | `cavaProc.running` in `MediaControls.qml` strictly gated behind active playback (`MprisPlaybackState.Playing`), terminating subprocess when paused. | closed |
| T-49-07 | Denial of Service | GUI thread event loop starvation from 60 FPS IPC stream | medium | mitigate | Downsampled `cava` split parsing by 3x (`_cavaFrameSkip % 3 !== 0`), reducing dispatch load from 60 FPS to 20 FPS. | closed |
| T-49-08 | Resource Exhaustion | Unbounded animation loops in background components | medium | mitigate | De-escalated `cardPulseAnimation` in `NetworkPingPopup.qml` from `Animation.Infinite` to 3 bounded cycles settling on static opacity. | closed |
| T-49-09 | Resource Exhaustion | Garbage collection churn from dynamic model generation | low | mitigate | Memoized DNS server list in `ifaceCard.cachedDnsServers` instead of instantiating new JavaScript arrays on every QML evaluation pass. | closed |
| T-49-10 | Resource Exhaustion | Aggressive idle polling timers waking CPU cores | low | mitigate | Relaxed `StorageUsage.qml` ioPollTimer from 1000ms to 3000ms and `Voice.qml` pollTimer from 500ms to 2500ms when idle. | closed |
| T-49-11 | Elevation of Privilege / Tampering | Symlink hijacking / Path traversal (ASVS V14.2) | high | block | All overlays deployed as leaf symlinks pointing strictly to repository paths under `restow/quickshell/`. `./arch/dots-hyprland.sh verify --strict` enforces canonical resolution. | closed |
| T-49-12 | Tampering | Submodule drift and unstaged repository pollution | high | block | Section 5 checks `git status --porcelain` before and after test execution, verifying zero working tree drift and zero churn in `vendor/dots-hyprland`. | closed |

*Status: closed (12/12 threats resolved)*  
*Severity: critical > high > medium > low*  
*Disposition: mitigate (implementation required) · accept (documented risk) · block (strict gate)*  

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| R-49-01 | T-49-01 | Test script root execution prevention and pipefail traps accepted as sufficient safeguard | Orchestrator | 2026-09-30 |
| R-49-02 | T-49-04 | User notification emitted before `ydotool` moves cursor; calibrated bounds avoid screen edges | Orchestrator | 2026-09-30 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-09-30 | 12 | 12 | 0 | Antigravity Orchestrator |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / block)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-09-30
