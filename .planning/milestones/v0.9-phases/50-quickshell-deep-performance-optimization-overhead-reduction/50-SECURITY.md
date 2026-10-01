---
phase: "50"
slug: "quickshell-deep-performance-optimization-overhead-reduction"
status: verified
threats_open: 0
asvs_level: 1
created: "2026-10-01"
updated: "2026-10-01"
---

# Phase 50 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Test Harness Process → System Environment | Assertion script execution validating local file contents, AST structures, and system procfs/sysfs | Process execution, exit codes, procfs telemetry |
| Subprocess Execution → Direct Binary Invocation | Replacing shell evaluation (`bash -c`) with structured parameter arrays (`["ip", ...], ["timeout", ...]`) | Argument vectors, stdout/stderr streams |
| Network Socket Engine → External Network Endpoints | XHR HTTP ping telemetry requests via `PingService.qml` | Network packets, socket descriptors, response latency |
| Hardware Telemetry → Procfs/Sysfs Filesystem | FileView observers reading `/proc/net/dev`, `/proc/net/route`, `/sys/devices/system/cpu/` | Kernel telemetry text streams |
| Scenegraph Pipeline → GPU Driver (Intel UHD 770) | Canvas 2D repainting, shader blurs, drop shadows, and opacity mask passes | Scenegraph nodes, FBO allocations, draw calls |
| GNU Stow Symlink Farm → Live Home Directory (`$HOME/.config/`) | Symlink deployment linking repository overlays to runtime desktop environment | Filesystem inodes and leaf symlinks |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-50-01 | Elevated Privilege | Test harness execution (`scripts/phase50-opt-assert.sh`) | high | block | Script enforces `[[ "${EUID:-$(id -u)}" -ne 0 ]]` fail-closed check immediately on entry to prevent root corruption of user home or repository. | closed |
| T-50-02 | Denial of Service | Telemetry state counters (`GlobalStates.qml`) | medium | mitigate | Counter updates clamped via `Math.max(0, activeInspectorCount - 1)` preventing integer underflow and guaranteeing boolean evaluation of `fastTelemetryRate`. | closed |
| T-50-03 | Submodule Contamination | Personal overlay boundaries (`vendor/dots-hyprland`) | high | block | All modifications strictly confined to `restow/quickshell/`. Section 5 verifies `git status --porcelain vendor/dots-hyprland` is empty. | closed |
| T-50-04 | Command Injection | Subprocess execution in singletons (`ResourceUsage`, `StorageUsage`, `NetworkUsage`) | high | block | Shell interpreter (`bash -c`) eliminated across all singletons; commands invoked directly via structured argument arrays (`["ip", "-j", "-4", "addr", "show"]`, `["timeout", "3", "df", "-k", "-P"]`). | closed |
| T-50-05 | Denial of Service | Network socket exhaustion (`PingService.qml`) | medium | mitigate | Added `isRequestInFlight` concurrency guard and 2000ms timeout dropping duplicate overlapping requests, preventing socket leakage and thread pool exhaustion. | closed |
| T-50-06 | Information Disclosure | Procfs/sysfs telemetry observers (`NetworkUsage.qml`) | low | mitigate | `FileView` observers strictly constrained to standard public unprivileged Linux kernel telemetry interfaces (`/proc/net/dev`, `/proc/net/route`, `/sys/class/net/`). | closed |
| T-50-07 | Resource Exhaustion | Unbounded GPU render loops & Canvas repaints | high | mitigate | Interactive popup Canvas charts clamped to 10 FPS (100ms deadband), drop shadows cached via `layer.enabled`, and animations bounded to finite cycles (`loops: 3`). | closed |
| T-50-08 | Path Traversal / Injection | Album art fetcher (`PlayerControl.qml`) | medium | mitigate | Removed `bash -c` wrapper; executes `["curl", "-4", "-sSL", targetFile, "-o", artFilePath]` with sanitized paths locked to the user cache directory. | closed |
| T-50-09 | Tampering | Benchmark telemetry ingestion (`phase50-opt-assert.sh`) | low | mitigate | Telemetry JSON validated with `jq empty` prior to extraction; strict numeric bounds checking applied to all parsed metrics. | closed |
| T-50-10 | Measurement Integrity | Profiling session interference (`profile-quickshell.sh`) | low | mitigate | Active MPRIS players paused via `playerctl pause -a` before benchmarking to prevent background audio/video decode pollution. | closed |

*Status: closed (10/10 threats resolved)*  
*Severity: critical > high > medium > low*  
*Disposition: mitigate (implementation required) · accept (documented risk) · block (strict gate)*  

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| R-50-01 | T-50-01 | Test harness non-root assertion and pipefail exit traps accepted as sufficient protection against privileged execution risks | Orchestrator | 2026-10-01 |
| R-50-02 | T-50-06 | Reading standard unprivileged Linux kernel procfs telemetry is standard practice for system monitoring widgets | Orchestrator | 2026-10-01 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-01 | 10 | 10 | 0 | Antigravity Orchestrator |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / block)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-10-01
