# Requirements: Quickshell Desktop Shell

**Defined:** 2026-09-25  
**Core Value:** Desktop capability via upstream dots-hyprland + personal overlays with unified system-wide Material You theming across GTK, Qt/KDE, Hyprland, Quickshell ii, and terminal/launcher tools with zero git churn.  

## Milestone v0.9 Requirements

Scoped requirements for Milestone v0.9 (Top Status Bar Resource Components & Hardware Telemetry). Each maps to roadmap phases.

### CPU & GPU Telemetry

- [x] **CPUGPU-01**: Bar pill displays live CPU usage % and GPU usage % with Material Symbols icons (`planner_review`, `speed`) and 250ms M3 emphasized deceleration width resizing.
- [x] **CPUGPU-02**: CPU popup inspector displays overall load %, package temperature (°C via `/sys/class/hwmon/hwmon5/temp1_input`), power draw in Watts (RAPL `/sys/class/powercap/intel-rapl` with unprivileged fallback placeholder), and clock frequencies (MHz).
- [x] **CPUGPU-03**: GPU popup inspector displays Intel iGPU load % (via RC6 residency delta), average load, active clock frequency (MHz via `rps_act_freq_mhz`), and temperature.
- [x] **CPUGPU-04**: Synchronized two-tier alert coloring (Amber warning at 70%, Red critical at 90%) across icons, text badges, and popup headers.

### Memory & Storage Telemetry

- [ ] **MEMDSK-01**: Bar pill displays RAM usage in gigabytes (`X.X/Y.Y GB` or `%`) and root filesystem `/` usage (`ZZ%`).
- [ ] **MEMDSK-02**: Memory popup inspector displays detailed memory allocation tiers: Used, Available, Cached, Buffers, Free, and Swap with dynamic swap reveal (> 0%).
- [ ] **MEMDSK-03**: Storage popup inspector displays clean progress bars for root `/` and all mounted filesystems (physical `/boot`, `/mnt/windows`, `/mnt/hdd`, and FUSE cloud mounts `GoogleDrive`) showing mount point, size, used, and free space.
- [ ] **MEMDSK-04**: Asynchronous non-blocking storage mount discovery via `Quickshell.Io.Process` running `df` at 15–30s intervals, preventing UI rendering freezes.

### Network & Multi-Target Ping Telemetry

- [ ] **NETPING-01**: Bar pill displays real-time network throughput rates (Rx/Tx KB/s or MB/s) derived from `/proc/net/dev`.
- [ ] **NETPING-02**: Bar pill displays **all 3 ping targets** (WAN `8.8.8.8`, Gateway `192.168.0.1`, Home Server `192.168.0.104`) with numeric latency (ms) and quality status colors.
- [ ] **NETPING-03**: Ping client service polls local system monitor daemon (`http://127.0.0.1:8765/api/status`) asynchronously at 5s intervals with graceful fallback if the daemon is offline.
- [ ] **NETPING-04**: Network popup inspector displays active NIC interface name, IPv4 address, link speed, and detailed 3-target ping diagnostic cards.
- [ ] **NETPING-05**: Clicking Network pill or popup launches the web ping dashboard at `http://127.0.0.1:8765/` in the default browser.

### Quickshell Performance & Profiling

- [x] **PERF-01**: Baseline & Staged Resource Profiling Harness (`scripts/profile-quickshell.sh`) capturing pure upstream `dots-hyprland` reference metrics via `stow -D`, executing declarative multi-stage attribution runs, and recording CPU %, deep memory (RSS, PSS, Private Dirty), context switches, I/O syscall rates, and Intel UHD 770 iGPU activity.
- [x] **PERF-02**: Comprehensive Diagnostic Reporting & Bottleneck Attribution Matrix producing human-readable `BENCHMARK.md` and machine-readable `benchmark-latest.json` detailing marginal component costs, dual-state idle vs active popup interaction deltas, and static timer/FileView inventory audit.
- [x] **PERF-03**: Automated Performance Assertion Suite (`scripts/phase43-perf-assert.sh`) enforcing resource budgets, file descriptor leak caps (< 150), idle CPU (< 15%), and zero working tree drift under `./arch/dots-hyprland.sh verify --strict`, accompanied by an evidence-based optimization framework.

### Shell Integration & Repository Integrity

- [ ] **INTG-01**: Three standalone `BarGroup` pills integrated into `BarContent.qml` Left zone alongside `LeftSidebarButton` and `UtilButtons` with responsive `useShortenedForm` support.
- [ ] **INTG-02**: Deployed via GNU Stow leaf symlinks under `restow/quickshell/` without folding parent directories, maintaining `vendor/dots-hyprland` pristine and passing `arch/dots-hyprland.sh verify --strict`.
- [ ] **INTG-03**: Automated regression assertion suite (`scripts/phase46-telemetry-assert.sh`) verifying sensor polling, daemon bridge, multi-mount discovery, and zero working tree drift.

## Future Requirements

Deferred to future release. Tracked but not in current roadmap.

### Advanced Diagnostics

- **DIAG-01**: Per-core CPU load and temperature breakdown in expanded hardware popup.
- **DIAG-02**: Canvas-based real-time sparkline history graphs for CPU, RAM, and network throughput.
- **DIAG-03**: Top process consumer list (CPU / RAM hogs) embedded directly in Quickshell popup.

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| `ddcutil` backlight polling | Proven to trigger fatal Intel iGPU hangs and kernel crashes (`issues/2026-07-16_igpu-flickering-hang-no-display.md`). |
| Raw ICMP ping spawning from QML | Process churn and duplicate network traffic; local daemon on port 8765 already collects ping data into SQLite. |
| Synchronous CLI commands | Blocks Qt Quick event loop, resulting in UI freezes and dropped frames. |
| Discrete NVIDIA GPU telemetry | Host is Intel Alder Lake iGPU only; discrete GPU tools (`nvidia-smi`) are not applicable. |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| CPUGPU-01 | Phase 43 | Complete |
| CPUGPU-02 | Phase 43 | Complete |
| CPUGPU-03 | Phase 43 | Complete |
| CPUGPU-04 | Phase 43 | Complete |
| PERF-01 | Phase 43.1 | Complete |
| PERF-02 | Phase 43.1 | Complete |
| PERF-03 | Phase 43.1 | Complete |
| MEMDSK-01 | Phase 44 | Pending |
| MEMDSK-02 | Phase 44 | Pending |
| MEMDSK-03 | Phase 44 | Pending |
| MEMDSK-04 | Phase 44 | Pending |
| NETPING-01 | Phase 45 | Pending |
| NETPING-02 | Phase 45 | Pending |
| NETPING-03 | Phase 45 | Pending |
| NETPING-04 | Phase 45 | Pending |
| NETPING-05 | Phase 45 | Pending |
| INTG-01 | Phase 46 | Pending |
| INTG-02 | Phase 46 | Pending |
| INTG-03 | Phase 46 | Pending |
