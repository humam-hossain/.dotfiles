# Phase 46: Left-Zone Integration, Verification & Repository Integrity - Context

**Gathered:** 2026-09-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Integrate all three status bar telemetry pills into `BarContent.qml` Left zone alongside `LeftSidebarButton` and `UtilButtons`, retirement and clean removal of legacy `Resources.qml` / `Resource.qml`, responsive layout verification ensuring dead-center Workspaces positioning is mathematically preserved across screen widths (`useShortenedForm` 0, 1, and 2), GNU Stow leaf symlink deployment under `restow/quickshell/` without folding parent directories, and consolidated milestone v0.9 assertion suite (`scripts/phase46-telemetry-assert.sh`) verifying telemetry sensors, daemon bridge, multi-mount discovery, and strict repository integrity (`arch/dots-hyprland.sh verify --strict` with `FAIL=0 FINDINGS=0`).

</domain>

<decisions>
## Implementation Decisions

### Left-Zone Pill Sequence & Layout Architecture

- **D-01 (Left Zone Pill Sequence):** The Left zone of `BarContent.qml` is arranged in the sequence: `LeftSidebarButton` → `MemoryStoragePill` (Storage & Memory) → `CpuGpuPill` (CPU & GPU) → `NetworkPingPill` (Network & Ping) → `utilButtonsGroup` (wrapped in BarGroup). — **Reversibility:** reversible
- **D-02 (Storage & Memory Pill Internal Ordering):** Inside the `MemoryStoragePill.qml` component, the metric order is swapped: Storage (`/` root disk usage %) is displayed on the left, followed by Memory (RAM usage GB / %) on the right. — **Reversibility:** reversible
- **D-03 (Storage & Memory Popup Column Ordering):** In `MemoryStoragePopup.qml`, the two-column inspector layout is swapped to match the pill's presentation: Left column displays Storage (multi-mount filesystem breakdown, root `/`, physical drives, and FUSE cloud mounts), while Right column displays Memory (RAM breakdown, buffers/cached/swap meters). — **Reversibility:** reversible
- **D-04 (Pill Spacing & Dividers):** Maintain uniform 4px inter-pill spacing (`spacing: 4`) with zero vertical dividers between pills, consistent with Phase 33's modular 3-zone layout contract. — **Reversibility:** reversible
- **D-05 (UtilButtons Placement & Visibility Gating):** `utilButtonsGroup` remains immediately after `NetworkPingPill`, gated by `visible: (Config.options.bar.verbose && root.useShortenedForm === 0)` so it automatically drops when verbose is off or when screen width is constrained. — **Reversibility:** reversible

### Responsive Behavior & Workspace Centering Protection

- **D-06 (All-Width Pill Visibility & Adaptive Compaction):** All 3 telemetry pills remain visible across standard and narrow screen widths (`useShortenedForm` 0, 1, and 2). Responsive compaction relies on individual pill adaptations (CPU pill hides `°C` label when `useShortenedForm > 0`; UtilButtons drops when `useShortenedForm > 0`). — **Reversibility:** reversible
- **D-07 (Strict Middle Section Centering):** `middleSection` remains strictly anchored via `anchors.centerIn: parent` in `BarContent.qml`, guaranteeing that Workspaces stays dead-center regardless of Left or Right zone content width shifts. No artificial clipping guard (`clip: true`) is required; layout relies on natural flex geometry and standard display resolutions. — **Reversibility:** reversible

### Legacy Resources Component Retirement & Cleanup

- **D-08 (Clean Removal of Legacy Resources):** Completely remove `Resources.qml` and `Resource.qml` from `restow/quickshell/.config/quickshell/ii/modules/ii/bar/` to eliminate dead code and obsolete overlays, completing the retirement planned since Phase 43.3. — **Reversibility:** reversible
- **D-09 (Zero Git Churn & Upstream Cleanliness):** Ensure `vendor/dots-hyprland` remains 100% clean with zero git churn; deployment is handled purely through GNU Stow leaf symlinks in `restow/quickshell/`. — **Reversibility:** reversible

### Consolidated Test Harness Architecture (`phase46-telemetry-assert.sh`)

- **D-10 (Multi-Section Orchestrated Suite):** Implement `scripts/phase46-telemetry-assert.sh` following the proven Phase 41 pattern (`phase41-interactions-assert.sh`):
  - Section 1: Stow leaf symlink topology & packaging integrity under `restow/quickshell/` (verifying parent directory unfolding and absence of legacy Resources symlinks).
  - Section 2: `BarContent.qml` Left zone layout AST & pill sequence verification (asserting `LeftSidebarButton` → `MemoryStoragePill` → `CpuGpuPill` → `NetworkPingPill` → `utilButtonsGroup`).
  - Section 3: Component internal ordering & AST verification (Storage-first in `MemoryStoragePill.qml` and `MemoryStoragePopup.qml`).
  - Section 4: Telemetry service sensors & ping daemon bridge liveness assertions (`HardwareTelemetry.qml`, `StorageUsage.qml`, `NetworkUsage.qml`, `PingService.qml`).
  - Section 5: Responsive layout & invariant checks (`useShortenedForm` bindings and `middleSection` dead-centering).
  - Section 6: Sub-harness orchestration (`phase42`, `phase43.6`, `phase43-perf --quick`, `phase44`, `phase45`) plus strict repository verification (`arch/dots-hyprland.sh verify --strict` with `FAIL=0 FINDINGS=0`). — **Reversibility:** reversible
- **D-11 (Standard CLI Flags & Fail-Closed Exit):** `scripts/phase46-telemetry-assert.sh` supports `-s, --section <1-6>`, `-q, --quick, --standalone`, `-c, --syntax`, and `-h, --help`, exiting 0 only when all assertions pass (`FAIL=0 FINDINGS=0`) and non-zero on any failure. — **Reversibility:** reversible

### the agent's Discretion

- Internal layout adjustments in `MemoryStoragePill.qml` and `MemoryStoragePopup.qml` when swapping Storage and Memory order (preserving exact padding, animations, and hover anchors).
- Implementation details of AST grep patterns in `phase46-telemetry-assert.sh`.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Shell UI Blueprints & Layout
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml` — Primary top bar container defining Left, Middle, and Right zone layouts and responsive thresholds
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/MemoryStoragePill.qml` — Storage & Memory status bar pill (needs Storage-first order update)
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/MemoryStoragePopup.qml` — Storage & Memory popup inspector (needs Left=Storage, Right=Memory column swap)
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPill.qml` — CPU & GPU status bar pill (middle pill in Left zone)
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPopup.qml` — Streamlined CPU & GPU popup inspector (Phase 43.6)
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/NetworkPingPill.qml` — Network throughput & 3-target ping status bar pill
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/NetworkPingPopup.qml` — Network & ping popup inspector with web dashboard launcher
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarGroup.qml` — Container for status bar pills with M3 fluid width resizing

### Telemetry Services
- `restow/quickshell/.config/quickshell/ii/services/HardwareTelemetry.qml` — CPU/GPU temps, power, clocks, and hybrid core topology
- `restow/quickshell/.config/quickshell/ii/services/ResourceUsage.qml` — Memory and CPU usage service
- `restow/quickshell/.config/quickshell/ii/services/StorageUsage.qml` — Multi-mount filesystem discovery service
- `restow/quickshell/.config/quickshell/ii/services/NetworkUsage.qml` — Network throughput, interface carrier detection, and IP configuration
- `restow/quickshell/.config/quickshell/ii/services/PingService.qml` — Ping daemon bridge polling `http://127.0.0.1:8765/api/status`

### Test Harnesses & Repository Contracts
- `scripts/phase41-interactions-assert.sh` — Reference milestone consolidated assertion harness pattern
- `scripts/phase42-telemetry-services-assert.sh` — Phase 42 sub-harness
- `scripts/phase43.6-streamline-assert.sh` — Phase 43.6 sub-harness (authoritative for streamlined CPU/GPU popup)
- `scripts/phase43-perf-assert.sh` — Phase 43.1 performance assertion harness (runs with `--quick`)
- `scripts/phase44-memory-storage-assert.sh` — Phase 44 sub-harness
- `scripts/phase45-network-ping-assert.sh` — Phase 45 sub-harness
- `arch/dots-hyprland.sh` — Wrapper script providing `verify --strict` command
- `.planning/ROADMAP.md` §Phase 46 — Milestone v0.9 Left-Zone Integration, Verification & Repository Integrity
- `.planning/REQUIREMENTS.md` §Shell Integration & Repository Integrity — Formal requirements INTG-01, INTG-02, INTG-03

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `BarGroup`: Container for status bar pills providing consistent padding, margins, and Material 3 emphasized deceleration width expansion.
- `LeftSidebarButton`: Anchored on the far left of the Left zone with `Layout.leftMargin: Appearance.rounding.screenRounding`.
- `UtilButtons`: Wrapped in `BarGroup` and gated by `Config.options.bar.verbose && root.useShortenedForm === 0`.
- `arch/dots-hyprland.sh verify --strict`: Authoritative repository integrity verification ensuring clean leaf symlinks and zero git drift in `vendor/dots-hyprland`.

### Established Patterns
- Modular 3-zone layout in `BarContent.qml` where `middleSection` has `anchors.centerIn: parent` to keep Workspaces dead-center.
- GNU Stow leaf symlink overlay topology under `restow/quickshell/` mapping to `~/.config/quickshell/ii/` without modifying upstream files.
- Fail-closed multi-section assertion suites (`scripts/phase41-interactions-assert.sh`) enforcing `FAIL=0 FINDINGS=0`.

### Integration Points
- `BarContent.qml`: Line 92 `RowLayout { id: leftSectionRowLayout }` is the integration point for the Left zone pill sequence.
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/`: Legacy `Resources.qml` and `Resource.qml` to be removed.

</code_context>

<specifics>
## Specific Ideas

- The user specifically requested changing the pill sequence in the Left zone to: `LeftSidebarButton` → `StorageMemoryPill` → `CpuGpuPill` → `NetworkPingPill` → `utilButtonsGroup`.
- The user specifically requested that inside the Storage & Memory pill itself, the order be swapped: Storage first on the left, Memory second on the right.
- The user specifically requested that in `MemoryStoragePopup.qml`, the popup columns be swapped to match the pill: Left column = Storage (mounts), Right column = Memory (RAM/Swap breakdown).

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed strictly within the phase scope.

</deferred>

---

*Phase: 46-Left-Zone Integration, Verification & Repository Integrity*
*Context gathered: 2026-09-29*
