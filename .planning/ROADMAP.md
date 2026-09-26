# Roadmap: Quickshell Desktop Shell

## Milestones

- ✅ **v0.8 Notification Experience & Shell Interaction Polish** — Phases 38–41 (shipped 2026-09-25) — [Archive](milestones/v0.8-ROADMAP.md)
- 📋 **v0.9 Top Status Bar Resource Components & Hardware Telemetry** — Phases 42–46 (in progress)

## Phases

<details>
<summary>✅ v0.8 Notification Experience & Shell Interaction Polish (Phases 38–41) — SHIPPED 2026-09-25</summary>

- [x] **Phase 38: Power Profiles Daemon System Integration** (1/1 plans) — completed 2026-09-23
- [x] **Phase 39: Dynamic Media Popup Anchoring** (1/1 plans) — completed 2026-09-23
- [x] **Phase 40: Notification Center Quick-Dismiss & Smart Interaction** (3/3 plans) — completed 2026-09-24
- [x] **Phase 40.1: Clock Pill Padding and Unified Volume Ceiling Ergonomics (INSERTED)** (2/2 plans) — completed 2026-09-24
- [x] **Phase 41: End-to-End Verification & Repository Integrity** (2/2 plans) — completed 2026-09-25

See full archived phase details in [milestones/v0.8-ROADMAP.md](milestones/v0.8-ROADMAP.md).

</details>

### 📋 v0.9 Top Status Bar Resource Components & Hardware Telemetry (Phases 42–46)

- [x] **Phase 42: Telemetry Services & Sensor Infrastructure** (4 plans) (completed 2026-09-25)
- [x] **Phase 43: CPU & GPU Component (Pill & Popup)** (4 plans) (completed 2026-09-26)
- [ ] **Phase 44: Memory & Storage Component (Pill & Popup)** (0 plans)
- [ ] **Phase 45: Network & Multi-Target Ping Component (Pill & Popup)** (0 plans)
- [ ] **Phase 46: Left-Zone Integration, Verification & Repository Integrity** (0 plans)

## Phase Details

### Phase 42: Telemetry Services & Sensor Infrastructure

**Goal**: Implement backend telemetry services and data acquisition singletons for CPU/GPU hardware sensors, multi-mount storage discovery, and local ping daemon bridging.  
**Depends on**: Phase 41  
**Requirements**: Foundation for CPUGPU-01..04, MEMDSK-01..04, NETPING-01..05  
**Plans**: 4 plans (00, 01, 02, 03)

Success criteria:

1. `HardwareTelemetry.qml` reads CPU package temp (`coretemp`), RAPL power draw (with unprivileged fallback), frequencies, and Intel iGPU active load (RC6 residency delta) and clock MHz without blocking the event loop.
2. `StorageUsage.qml` asynchronously enumerates mount points (`df`) every 15–30s into a reactive model containing root `/`, physical partitions (`/boot`, `/mnt/windows`, `/mnt/hdd`), and FUSE cloud mounts (`GoogleDrive`).
3. `PingService.qml` polls `http://127.0.0.1:8765/api/status` at 5s intervals exposing latency for WAN (`8.8.8.8`), Gateway (`192.168.0.1`), and Home Server (`192.168.0.104`) with offline fallback.
4. `ResourceUsage.qml` exposes extended memory fields (`memoryAvailable`, `memoryBuffers`, `memoryCached`).

### Phase 43: CPU & GPU Component (Pill & Popup)

**Goal**: Build dedicated `CpuGpuPill.qml` status bar pill and interactive `CpuGpuPopup.qml` inspector overlay.  
**Depends on**: Phase 42  
**Requirements**: CPUGPU-01, CPUGPU-02, CPUGPU-03, CPUGPU-04  
**Plans**: 7/7 plans executed

- [x] 43-07-PLAN.md

- [x] 43-05-PLAN.md
- [x] 43-06-PLAN.md

- [x] 43-01-PLAN.md
- [x] 43-02-PLAN.md
- [x] 43-03-PLAN.md
- [x] 43-04-PLAN.md

Success criteria:

1. Status bar pill displays live CPU % and GPU % with distinct Material Symbols icons (`planner_review`, `speed`) and 250ms M3 emphasized deceleration width resizing.
2. Popup inspector displays CPU load %, package temperature (°C), wattage draw, clock speeds (MHz), and Intel iGPU load %, average load, frequency (MHz), and thermal status.
3. Synchronized two-tier alert coloring (Amber at 70%, Red at 90%) applied consistently across pill icons, text labels, and popup headers.

### Phase 44: Memory & Storage Component (Pill & Popup)

**Goal**: Build dedicated `MemoryStoragePill.qml` status bar pill and interactive `MemoryStoragePopup.qml` inspector overlay.  
**Depends on**: Phase 42  
**Requirements**: MEMDSK-01, MEMDSK-02, MEMDSK-03, MEMDSK-04  
**Plans**: 0 plans

Success criteria:

1. Status bar pill displays live RAM usage (`X.X/Y.Y GB` or `%`) and root filesystem `/` usage (`ZZ%`).
2. Popup inspector displays detailed memory allocation tiers: Used, Available, Cached, Buffers, Free, and Swap (with dynamic swap reveal when > 0%).
3. Storage popup inspector displays clean progress bars for root `/` and all mounted filesystems (physical and FUSE cloud mounts) with used and free space.
4. Storage discovery executes asynchronously via `Process` without causing UI stutter or dropped frames.

### Phase 45: Network & Multi-Target Ping Component (Pill & Popup)

**Goal**: Build dedicated `NetworkPingPill.qml` status bar pill and interactive `NetworkPingPopup.qml` inspector overlay.  
**Depends on**: Phase 42  
**Requirements**: NETPING-01, NETPING-02, NETPING-03, NETPING-04, NETPING-05  
**Plans**: 0 plans

Success criteria:

1. Status bar pill displays live network throughput rates (Rx/Tx KB/s or MB/s) derived from `/proc/net/dev`.
2. Status bar pill displays **all 3 ping targets** (WAN `8.8.8.8`, Gateway `192.168.0.1`, Home Server `192.168.0.104`) with latency numbers and status colors.
3. Popup inspector displays active NIC interface name, IP address, link speed, and detailed 3-target ping diagnostic cards.
4. Left-clicking the pill or popup action button opens the web ping dashboard at `http://127.0.0.1:8765/` in the default browser.

### Phase 46: Left-Zone Integration, Verification & Repository Integrity

**Goal**: Integrate all 3 pills into `BarContent.qml` Left zone, verify responsive layouts, and create comprehensive automated test harness with strict zero git churn.  
**Depends on**: Phase 43, Phase 44, Phase 45  
**Requirements**: INTG-01, INTG-02, INTG-03  
**Plans**: 0 plans

Success criteria:

1. Three standalone pills replace legacy `Resources.qml` in `BarContent.qml` Left zone alongside `LeftSidebarButton` and `UtilButtons`.
2. Responsive layout adapts cleanly across standard and `useShortenedForm` screen widths without pushing Center Workspaces off-center.
3. All files deployed via GNU Stow leaf symlinks under `restow/quickshell/` without folding parent directories, maintaining `vendor/dots-hyprland` pristine.
4. Consolidated assertion harness (`scripts/phase46-telemetry-assert.sh`) verifies all sensor parsers, daemon bridge, multi-mount discovery, and `arch/dots-hyprland.sh verify --strict` passes with `FAIL=0 FINDINGS=0`.

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|---|---|---|---|---|
| 38. Power Profiles Daemon System Integration | v0.8 | 1/1 | Complete | 2026-09-23 |
| 39. Dynamic Media Popup Anchoring | v0.8 | 1/1 | Complete | 2026-09-23 |
| 40. Notification Center Quick-Dismiss & Smart Interaction | v0.8 | 3/3 | Complete | 2026-09-24 |
| 40.1. Clock Pill Padding and Unified Volume Ceiling Ergonomics | v0.8 | 2/2 | Complete | 2026-09-24 |
| 41. End-to-End Verification & Repository Integrity | v0.8 | 2/2 | Complete | 2026-09-25 |
| 42. Telemetry Services & Sensor Infrastructure | v0.9 | 4/4 | Complete    | 2026-09-25 |
| 43. CPU & GPU Component (Pill & Popup) | v0.9 | 7/7 | In Progress|  |
| 44. Memory & Storage Component (Pill & Popup) | v0.9 | 0 plans | Planned | — |
| 45. Network & Multi-Target Ping Component (Pill & Popup) | v0.9 | 0 plans | Planned | — |
| 46. Left-Zone Integration, Verification & Repository Integrity | v0.9 | 0 plans | Planned | — |
