# Phase 46: Left-Zone Integration, Verification & Repository Integrity - Research

**Researched:** 2026-09-29  
**Domain:** Quickshell Top Bar Left-Zone Integration, Responsive Layout Invariants, Component Ordering, Legacy Component Retirement, and Milestone v0.9 Assertion Suite  
**Confidence:** HIGH  

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Implementation Decisions

#### Left-Zone Pill Sequence & Layout Architecture
- **D-01 (Left Zone Pill Sequence):** The Left zone of `BarContent.qml` is arranged in the sequence: `LeftSidebarButton` → `MemoryStoragePill` (Storage & Memory) → `CpuGpuPill` (CPU & GPU) → `NetworkPingPill` (Network & Ping) → `utilButtonsGroup` (wrapped in BarGroup). — **Reversibility:** reversible
- **D-02 (Storage & Memory Pill Internal Ordering):** Inside the `MemoryStoragePill.qml` component, the metric order is swapped: Storage (`/` root disk usage %) is displayed on the left, followed by Memory (RAM usage GB / %) on the right. — **Reversibility:** reversible
- **D-03 (Storage & Memory Popup Column Ordering):** In `MemoryStoragePopup.qml`, the two-column inspector layout is swapped to match the pill's presentation: Left column displays Storage (multi-mount filesystem breakdown, root `/`, physical drives, and FUSE cloud mounts), while Right column displays Memory (RAM breakdown, buffers/cached/swap meters). — **Reversibility:** reversible
- **D-04 (Pill Spacing & Dividers):** Maintain uniform 4px inter-pill spacing (`spacing: 4`) with zero vertical dividers between pills, consistent with Phase 33's modular 3-zone layout contract. — **Reversibility:** reversible
- **D-05 (UtilButtons Placement & Visibility Gating):** `utilButtonsGroup` remains immediately after `NetworkPingPill`, gated by `visible: (Config.options.bar.verbose && root.useShortenedForm === 0)` so it automatically drops when verbose is off or when screen width is constrained. — **Reversibility:** reversible

#### Responsive Behavior & Workspace Centering Protection
- **D-06 (All-Width Pill Visibility & Adaptive Compaction):** All 3 telemetry pills remain visible across standard and narrow screen widths (`useShortenedForm` 0, 1, and 2). Responsive compaction relies on individual pill adaptations (CPU pill hides `°C` label when `useShortenedForm > 0`; UtilButtons drops when `useShortenedForm > 0`). — **Reversibility:** reversible
- **D-07 (Strict Middle Section Centering):** `middleSection` remains strictly anchored via `anchors.centerIn: parent` in `BarContent.qml`, guaranteeing that Workspaces stays dead-center regardless of Left or Right zone content width shifts. No artificial clipping guard (`clip: true`) is required; layout relies on natural flex geometry and standard display resolutions. — **Reversibility:** reversible

#### Legacy Resources Component Retirement & Cleanup
- **D-08 (Clean Removal of Legacy Resources):** Completely remove `Resources.qml` and `Resource.qml` from `restow/quickshell/.config/quickshell/ii/modules/ii/bar/` to eliminate dead code and obsolete overlays, completing the retirement planned since Phase 43.3. — **Reversibility:** reversible
- **D-09 (Zero Git Churn & Upstream Cleanliness):** Ensure `vendor/dots-hyprland` remains 100% clean with zero git churn; deployment is handled purely through GNU Stow leaf symlinks in `restow/quickshell/`. — **Reversibility:** reversible

#### Consolidated Test Harness Architecture (`phase46-telemetry-assert.sh`)
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

### Deferred Ideas
- None — discussion stayed strictly within the phase scope.
</user_constraints>

---

## Executive Recommendation

Phase 46 concludes Milestone v0.9 ("Top Status Bar Resource Components & Hardware Telemetry"). All telemetry services (CPU/GPU, Storage, Ping, ResourceUsage) and their interactive components (`CpuGpuPill`/`CpuGpuPopup`, `MemoryStoragePill`/`MemoryStoragePopup`, `NetworkPingPill`/`NetworkPingPopup`) have been implemented, profiled, and verified in Phases 42–45.

This final integration phase executes four concrete tasks:
1. **Left-Zone Re-sequencing (`BarContent.qml`):** Align `leftSectionRowLayout` to D-01: `LeftSidebarButton` → `MemoryStoragePill` → `CpuGpuPill` → `NetworkPingPill` → `utilButtonsGroup`. [VERIFIED: restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml:92-136]
2. **Storage-First Metric & Inspector Reordering (D-02, D-03):**
   - In `MemoryStoragePill.qml`: swap Root Storage to the left and Memory (RAM) to the right; swap inter-cluster margin (`Layout.leftMargin: root.vertical ? 0 : 6`) from Storage to RAM. [VERIFIED: restow/quickshell/.config/quickshell/ii/modules/ii/bar/MemoryStoragePill.qml:46-201]
   - In `MemoryStoragePopup.qml`: swap the two 320px columns so the Left column hosts Storage (throughput header, physical partitions, Google Drive cloud mounts) and the Right column hosts Memory (RAM stacked bar, tiers, swap). [VERIFIED: restow/quickshell/.config/quickshell/ii/modules/ii/bar/MemoryStoragePopup.qml:173-424]
3. **Legacy Retirement & Symlink Cleanup (D-08):**
   - Remove `restow/quickshell/.config/quickshell/ii/modules/ii/bar/Resource.qml` and `Resources.qml` from git.
   - Remove live symlinks `~/.config/quickshell/ii/modules/ii/bar/Resource.qml` and `Resources.qml`, and restore the upstream `.bak` backups so upstream remains pristine with zero dangling symlinks into the repo. [VERIFIED: arch/dots-hyprland.sh:1302-1307]
4. **Milestone v0.9 Automated Test Harness (`scripts/phase46-telemetry-assert.sh`) (D-10, D-11):**
   - Structure a comprehensive 6-section test suite following `scripts/phase41-interactions-assert.sh`.
   - Orchestrate all milestone sub-harnesses (`phase42`, `phase43.6`, `phase43-perf --quick`, `phase44`, `phase45`) and `./arch/dots-hyprland.sh verify --strict` guaranteeing `FAIL=0 FINDINGS=0` with zero working tree drift. [VERIFIED: command run this session]

---

## Phase Requirements Table

| Requirement ID | Description | Source | Status / How Satisfied |
|---|---|---|---|
| **INTG-01** | Three standalone `BarGroup` pills integrated into `BarContent.qml` Left zone alongside `LeftSidebarButton` and `UtilButtons` with responsive `useShortenedForm` support. | `.planning/REQUIREMENTS.md:47` | Satisfied by ordering `leftSectionRowLayout` to D-01: `LeftSidebarButton` → `MemoryStoragePill` → `CpuGpuPill` → `NetworkPingPill` → `utilButtonsGroup`, binding `useShortenedForm: root.useShortenedForm` across all 3 pills. |
| **INTG-02** | Deployed via GNU Stow leaf symlinks under `restow/quickshell/` without folding parent directories, maintaining `vendor/dots-hyprland` pristine and passing `arch/dots-hyprland.sh verify --strict`. | `.planning/REQUIREMENTS.md:48` | Satisfied by managing all overlays under `restow/quickshell/`, removing legacy `Resources.qml`/`Resource.qml`, restoring live stubs from `.bak`, and asserting `FAIL=0 FINDINGS=0` via `./arch/dots-hyprland.sh verify --strict`. |
| **INTG-03** | Automated regression assertion suite (`scripts/phase46-telemetry-assert.sh`) verifying sensor polling, daemon bridge, multi-mount discovery, and zero working tree drift. | `.planning/REQUIREMENTS.md:49` | Satisfied by implementing `scripts/phase46-telemetry-assert.sh` across Sections 1 to 6 with fail-closed exit and zero-churn porcelain diffing. |

---

## Architectural Responsibility Map

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                                 Quickshell Top Status Bar                              │
├─────────────────────────────────────────────────┬───────────────────┬──────────────────┤
│             Left Zone (Flex RowLayout)          │    Middle Zone    │    Right Zone    │
├─────────────────────────────────────────────────┼───────────────────┼──────────────────┤
│ 1. LeftSidebarButton (Screen rounding margin)   │ WeatherBar (Opt)  │ Media (Active)   │
│ 2. MemoryStoragePill (Storage [L] + RAM [R])    │ Workspaces        │ VoicePill        │
│ 3. CpuGpuPill (CPU + GPU + Package Temp)        │ (Dead-Centered via│ UpdatesIndicator │
│ 4. NetworkPingPill (Throughput + 3 Latencies)   │  horizontalCenter │ BatteryIndicator │
│ 5. UtilButtons (Visible if verbose && form==0)  │  to parent)       │ SysTrayGroup     │
│ 6. Expanding Spacer (Item Layout.fillWidth)     │                   │ RightSidebarBtn  │
└─────────────────────────────────────────────────┴───────────────────┴──────────────────┘
        │
        ├── Storage & Memory: StorageUsage (Process 'df') + ResourceUsage (/proc/meminfo)
        ├── CPU & GPU: HardwareTelemetry (/sys/class/hwmon, /proc/stat, RC6 residency)
        └── Network & Ping: NetworkUsage (/proc/net/dev) + PingService (http://127.0.0.1:8765)
```

---

## Standard Stack / Component Map

| Component | File Path | Role | Phase 46 State & Action |
|---|---|---|---|
| **BarContent** | `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml` | Master horizontal bar container | Swap `cpuGpuPill` and `memoryStoragePill` order so `MemoryStoragePill` precedes `CpuGpuPill` per D-01. |
| **MemoryStoragePill** | `restow/quickshell/.config/quickshell/ii/modules/ii/bar/MemoryStoragePill.qml` | Disk & RAM status pill | Swap metrics: Storage first on left, RAM second on right per D-02. Transfer 6px inter-cluster margin to RAM. |
| **MemoryStoragePopup** | `restow/quickshell/.config/quickshell/ii/modules/ii/bar/MemoryStoragePopup.qml` | Multi-mount & memory inspector | Swap columns: Storage card on left, Memory card on right per D-03. |
| **CpuGpuPill** | `restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPill.qml` | CPU/GPU load & temp pill | Retained in position 3 in Left zone. Responsive hiding of `°C` temp text when `useShortenedForm > 0`. |
| **CpuGpuPopup** | `restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPopup.qml` | Streamlined CPU/GPU inspector | Verified intact (Phase 43.6 two-column layout). |
| **NetworkPingPill** | `restow/quickshell/.config/quickshell/ii/modules/ii/bar/NetworkPingPill.qml` | Bandwidth & 3-target latency pill | Positioned immediately after `CpuGpuPill`. Left-click launches web dashboard at `http://127.0.0.1:8765/`. |
| **NetworkPingPopup** | `restow/quickshell/.config/quickshell/ii/modules/ii/bar/NetworkPingPopup.qml` | Network details & ping cards | Verified intact (Phase 45 cards and action button). |
| **UtilButtons** | `restow/quickshell/.config/quickshell/ii/modules/ii/bar/UtilButtons.qml` | Quick action button group | Gated by `visible: (Config.options.bar.verbose && root.useShortenedForm === 0)` after `NetworkPingPill`. |
| **Legacy Resources** | `restow/quickshell/.config/quickshell/ii/modules/ii/bar/Resources.qml` & `Resource.qml` | Deprecated monolithic resource meters | Completely deleted from repo per D-08; symlinks unlinked; `.bak` restored. |
| **Test Suite** | `scripts/phase46-telemetry-assert.sh` | Milestone v0.9 assertion harness | New test harness created across 6 orchestrated sections per D-10 & D-11. |

---

## Architecture Patterns

### 1. Left-Zone Layout Sequence Pattern (`BarContent.qml`)

In `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml`, lines 92–136 define `RowLayout { id: leftSectionRowLayout }`.

**Current Sequence [VERIFIED: BarContent.qml:97-136]:**
```qml
LeftSidebarButton  // 1
CpuGpuPill         // 2 (incorrect order)
MemoryStoragePill  // 3 (incorrect order)
NetworkPingPill    // 4
BarGroup { id: utilButtonsGroup } // 5
Item { Layout.fillWidth: true }   // Spacer
```

**Target Sequence per D-01:**
```qml
LeftSidebarButton {
    id: leftSidebarButton
    Layout.alignment: Qt.AlignVCenter
    Layout.leftMargin: Appearance.rounding.screenRounding
    colBackground: barLeftSideMouseArea.hovered ? Appearance.colors.colLayer1Hover : ColorUtils.transparentize(Appearance.colors.colLayer1Hover, 1)
}

MemoryStoragePill {
    id: memoryStoragePill
    Layout.alignment: Qt.AlignVCenter
    useShortenedForm: root.useShortenedForm
}

CpuGpuPill {
    id: cpuGpuPill
    Layout.alignment: Qt.AlignVCenter
    useShortenedForm: root.useShortenedForm
}

NetworkPingPill {
    id: networkPingPill
    Layout.alignment: Qt.AlignVCenter
    useShortenedForm: root.useShortenedForm
}

BarGroup {
    id: utilButtonsGroup
    Layout.alignment: Qt.AlignVCenter
    visible: (Config.options.bar.verbose && root.useShortenedForm === 0)

    UtilButtons {
        Layout.alignment: Qt.AlignVCenter
    }
}

Item {
    Layout.fillWidth: true
    Layout.fillHeight: true
}
```

### 2. Storage-First Metric Swapping Pattern (`MemoryStoragePill.qml`)

In `restow/quickshell/.config/quickshell/ii/modules/ii/bar/MemoryStoragePill.qml`:
- Lines 46–122 currently define `ramCircProg` and `ramText`.
- Lines 124–201 currently define `storageCircProg` and `storageText`, with `storageCircProg` carrying `Layout.leftMargin: root.vertical ? 0 : 6`.

To satisfy D-02:
1. Move the Storage cluster (`storageCircProg` + `storageText`) to lines 46+. Remove the `Layout.leftMargin` from `storageCircProg` (or set to 0).
2. Move the RAM cluster (`ramCircProg` + `ramText`) to lines 124+. Apply `Layout.leftMargin: root.vertical ? 0 : 6` to `ramCircProg` to establish the visual separation between the Storage cluster and RAM cluster.
3. Keep all property bindings, alert thresholds, `hoverArea` alias, and animations (`ramPulseAnimation`, `storagePulseAnimation`) intact.

### 3. Inspector Column Swapping Pattern (`MemoryStoragePopup.qml`)

In `restow/quickshell/.config/quickshell/ii/modules/ii/bar/MemoryStoragePopup.qml`:
- Lines 173–326 define the Memory column (`ColumnLayout { Layout.preferredWidth: 320; ... StyledPopupHeaderRow { icon: "memory"; label: "Memory" } ... }`).
- Lines 331–335 define the center vertical divider (`Rectangle { Layout.fillHeight: true; implicitWidth: 1; color: Appearance.colors.colLayer0Border }`).
- Lines 340–424 define the Storage column (`ColumnLayout { Layout.preferredWidth: 320; ... StyledPopupHeaderRow { icon: "storage"; label: "Storage" } ... }`).

To satisfy D-03:
1. Place the Storage column FIRST (Left column):
   - Header with `icon: "storage"` and throughput read/write rate badges
   - Physical drives repeater
   - Google Drive cloud mounts repeater
2. Retain the vertical divider in the middle.
3. Place the Memory column SECOND (Right column):
   - Header with `icon: "memory"`
   - RAM allocation stacked bar with legend
   - Numeric tier rows (Used, Available, Buffers, Cached, Free)
   - Dynamic Swap row

### 4. Centering Math & Responsive Width Allocation Pattern

The dead-centering invariant of Workspaces (D-07) operates as follows:
- `middleCenterGroup` is anchored directly with `anchors.horizontalCenter: parent.horizontalCenter` in `BarContent.qml:163`.
- `middleSection` wraps `middleCenterGroup`, `weatherGroup` (left of center), and `rightCenterGroup` (right of center).
- `barLeftSideMouseArea` anchors left to `parent.left` and right to `middleSection.left`.
- Within `leftSectionRowLayout`, the trailing `Item { Layout.fillWidth: true; Layout.fillHeight: true }` expands into all available space between the pills and `middleSection.left`.
- Because `middleCenterGroup` uses `parent.horizontalCenter`, the center of the Workspaces widget is pinned to `screenWidth / 2`.
- As screen width narrows:
  - On displays > 1200px (e.g. 1920x1080, 2560x1440, 3440x1440): `useShortenedForm === 0`. Left zone width is ~817px (without verbose) or ~887px (with verbose). On a 1920px screen, `1920 / 2 = 960px`. With Workspaces centered at 960px (~180px wide), the left boundary of Workspaces is at `870px`. With `utilButtonsGroup` taking ~70px, if weather is enabled, weather sits at ~770px.
  - On displays <= 1200px: `useShortenedForm === 1`. `utilButtonsGroup` hides automatically (`visible: (Config.options.bar.verbose && root.useShortenedForm === 0)`), reclaiming ~70px. `CpuGpuPill` hides its `°C` label (`visible: root.useShortenedForm === 0`), reclaiming ~35px.
  - On displays <= 900px: `useShortenedForm === 2`. Media module hides (`visible: root.useShortenedForm < 2`), center side modules contract to `barCenterSideModuleWidthHellaShortened`, preserving Workspaces dead-center.

---

## Don't Hand-Roll

| Component / Functionality | Do NOT Hand-Roll | Use Standard Repo / Upstream Facility Instead |
|---|---|---|
| **Repository Integrity Verification** | Do not invent custom link scanners or partial git checks in bash | Run `./arch/dots-hyprland.sh verify --strict` which implements canonical multi-tree scanning, folded ancestor detection, and porcelain status. [VERIFIED: arch/dots-hyprland.sh:754] |
| **Sub-Harness Execution** | Do not re-implement sensor or daemon tests in phase46 | Delegate to existing verified sub-harnesses (`phase42`, `phase43.6`, `phase43-perf-assert.sh --quick`, `phase44`, `phase45`) via orchestration. [VERIFIED: D-10] |
| **Symlink Topology Management** | Do not manually copy files into `~/.config/quickshell/` | Manage purely as GNU Stow leaf files under `restow/quickshell/` with `--no-folding`. |
| **Bar Pill Containers** | Do not use raw Rectangle / Row containers for status bar items | Use `BarGroup.qml` which encapsulates 250ms M3 emphasized deceleration width resizing and appearance tokens. [VERIFIED: restow/quickshell/.../BarGroup.qml] |
| **Popup Hover Intent** | Do not implement ad-hoc hover timers | Rely on `StyledPopup.qml` universal 1000ms hover intent delay and 200ms grace period established in Phase 43.5. [VERIFIED: REQUIREMENTS.md:22] |

---

## Runtime State Inventory

Because Phase 46 involves the permanent removal of legacy components (`Resources.qml` and `Resource.qml`) from the repository, the runtime state must be meticulously inventoried and tracked across live filesystem locations, git tracking, and backup stubs.

| Target Item | Current State | Target State | Action Required |
|---|---|---|---|
| `restow/quickshell/.../bar/Resource.qml` | Tracked git file in repo [VERIFIED: git ls-files] | Deleted from git repo | `git rm restow/quickshell/.config/quickshell/ii/modules/ii/bar/Resource.qml` |
| `restow/quickshell/.../bar/Resources.qml` | Tracked git file in repo [VERIFIED: git ls-files] | Deleted from git repo | `git rm restow/quickshell/.config/quickshell/ii/modules/ii/bar/Resources.qml` |
| `~/.config/.../bar/Resource.qml` | Live symlink pointing to repo file [VERIFIED: ls -la] | Restored upstream regular file stub | `rm` symlink; `mv Resource.qml.bak Resource.qml` if backup exists |
| `~/.config/.../bar/Resources.qml` | Live symlink pointing to repo file [VERIFIED: ls -la] | Restored upstream regular file stub | `rm` symlink; `mv Resources.qml.bak Resources.qml` if backup exists |
| `~/.config/.../bar/Resource.qml.bak` | Live backup stub from initial stow [VERIFIED: ls -la] | Restored to `Resource.qml` | Rename back to original upstream file |
| `~/.config/.../bar/Resources.qml.bak` | Live backup stub from initial stow [VERIFIED: ls -la] | Restored to `Resources.qml` | Rename back to original upstream file |
| `vendor/dots-hyprland/` | Clean git submodule [VERIFIED: git status] | 100% clean, 0 git churn | Untouched |
| `BarContent.qml` `leftSectionRowLayout` | CpuGpuPill preceding MemoryStoragePill [VERIFIED: line 104] | `MemoryStoragePill` preceding `CpuGpuPill` | Move `MemoryStoragePill` before `CpuGpuPill` |
| `MemoryStoragePill.qml` | RAM preceding Storage [VERIFIED: line 46] | Storage preceding RAM | Swap internal sections and adjust margins |
| `MemoryStoragePopup.qml` | Memory col left, Storage col right [VERIFIED: line 173] | Storage col left, Memory col right | Swap columns around center divider |

---

## Common Pitfalls

### Pitfall 1: Dangling Live Symlinks on Repo File Deletion
**Risk:** When `Resource.qml` and `Resources.qml` are deleted from `restow/quickshell/`, if the corresponding symlinks in `$HOME/.config/quickshell/ii/modules/ii/bar/` are not removed or restored, they become dangling symlinks pointing into the repository.
**Consequence:** `./arch/dots-hyprland.sh verify --strict` flags Arm 3 in `classify_sweep_entry` (`fail "dangling symlink into repo: $entry -> $dangling_raw_target"`) and fails immediately. [VERIFIED: arch/dots-hyprland.sh:1302-1307]
**Prevention:**
1. Remove live symlinks `rm -f "$HOME/.config/quickshell/ii/modules/ii/bar/Resource.qml" "$HOME/.config/quickshell/ii/modules/ii/bar/Resources.qml"`.
2. Restore upstream backup files: if `Resource.qml.bak` exists, `mv` it back to `Resource.qml`.
3. In `arch/dots-hyprland.sh verify`, restored upstream stubs are classified under Arm 7 as `[INFO] unclaimed upstream stub: ...` which exits 0 with `FAIL=0 FINDINGS=0`.

### Pitfall 2: Forgetting to Swap Inter-Cluster Margin in `MemoryStoragePill.qml`
**Risk:** In `MemoryStoragePill.qml`, the 6px separation margin (`Layout.leftMargin: root.vertical ? 0 : 6`) is currently on `storageCircProg` because Storage is the second cluster. If Storage and RAM are swapped without moving this margin, Storage will have an extra 6px margin against the pill border, and RAM will be squished against Storage with 0px spacing.
**Prevention:**
Remove `Layout.leftMargin` from `storageCircProg` (so Storage sits flush with the pill's left padding). Add `Layout.leftMargin: root.vertical ? 0 : 6` to `ramCircProg` so the 6px separation is preserved between the Storage cluster and the RAM cluster.

### Pitfall 3: Broken AST Sequence Checks in Test Assertions
**Risk:** Asserting the ordering of items in `BarContent.qml` using a single multi-line regex or brittle whitespace-sensitive patterns can fail across minor indentation or formatting changes.
**Prevention:**
Extract line numbers using `grep -n` and verify numerical monotonicity:
```bash
pos_sidebar=$(grep -n "LeftSidebarButton" "$BAR_CONTENT" | head -n1 | cut -d: -f1)
pos_memdsk=$(grep -n "MemoryStoragePill" "$BAR_CONTENT" | head -n1 | cut -d: -f1)
pos_cpugpu=$(grep -n "CpuGpuPill" "$BAR_CONTENT" | head -n1 | cut -d: -f1)
pos_netping=$(grep -n "NetworkPingPill" "$BAR_CONTENT" | head -n1 | cut -d: -f1)
pos_util=$(grep -n "utilButtonsGroup" "$BAR_CONTENT" | head -n1 | cut -d: -f1)

if (( pos_sidebar < pos_memdsk && pos_memdsk < pos_cpugpu && pos_cpugpu < pos_netping && pos_netping < pos_util )); then
  pass "S2: Left zone sequence verified (LeftSidebarButton -> MemoryStoragePill -> CpuGpuPill -> NetworkPingPill -> utilButtonsGroup)"
fi
```

### Pitfall 4: Sub-Harness Execution Timeout in Automated CI / Test Runs
**Risk:** Running `scripts/phase43-perf-assert.sh` without `--quick` triggers full multi-stage benchmarking runs taking upwards of 60 seconds and causing test run timeouts.
**Prevention:**
Always invoke `scripts/phase43-perf-assert.sh` with `--quick` in Section 6 orchestration, exactly as specified in D-10. [VERIFIED: D-10]

### Pitfall 5: Accidental Working Tree Drift During Test Harness Execution
**Risk:** Running sub-harnesses or temporary commands that write unignored files or touch tracked files will trigger a git porcelain mismatch.
**Prevention:**
Capture a porcelain snapshot at the beginning (`porcelain_snapshot > "$PORCELAIN_BEFORE"`) and diff at the end (`diff -u "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER"`). Ensure all temporary files are routed through `/tmp/` and trapped on `EXIT INT TERM`.

---

## Code Examples

### Example 1: `BarContent.qml` Left Zone Integration

```qml
// restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml
        RowLayout {
            id: leftSectionRowLayout
            anchors.fill: parent
            spacing: 4

            LeftSidebarButton { // Left sidebar button
                id: leftSidebarButton
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: Appearance.rounding.screenRounding
                colBackground: barLeftSideMouseArea.hovered ? Appearance.colors.colLayer1Hover : ColorUtils.transparentize(Appearance.colors.colLayer1Hover, 1)
            }

            MemoryStoragePill {
                id: memoryStoragePill
                Layout.alignment: Qt.AlignVCenter
                useShortenedForm: root.useShortenedForm
            }

            CpuGpuPill {
                id: cpuGpuPill
                Layout.alignment: Qt.AlignVCenter
                useShortenedForm: root.useShortenedForm
            }

            NetworkPingPill {
                id: networkPingPill
                Layout.alignment: Qt.AlignVCenter
                useShortenedForm: root.useShortenedForm
            }

            BarGroup {
                id: utilButtonsGroup
                Layout.alignment: Qt.AlignVCenter
                visible: (Config.options.bar.verbose && root.useShortenedForm === 0)

                UtilButtons {
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
```

### Example 2: `MemoryStoragePill.qml` Metric Swap (Storage First, RAM Second)

```qml
// restow/quickshell/.config/quickshell/ii/modules/ii/bar/MemoryStoragePill.qml

    // --- Storage Section (Circular progress indicator + storage icon) ---
    ClippedFilledCircularProgress {
        id: storageCircProg
        Layout.alignment: Qt.AlignVCenter
        lineWidth: Appearance.rounding.unsharpen
        value: Math.max(0.0, Math.min(1.0, (StorageUsage.rootDisk?.usePercent ?? 0) / 100.0))
        implicitSize: 20
        colPrimary: root.storageColor
        accountForLightBleeding: !root.storageCritical && !root.storageWarning
        enableAnimation: false

        Item {
            anchors.centerIn: parent
            width: storageCircProg.implicitSize
            height: storageCircProg.implicitSize

            MaterialSymbol {
                id: storageIcon
                anchors.centerIn: parent
                text: "storage"
                iconSize: Appearance.font.pixelSize.normal
                color: root.storageColor

                Behavior on color {
                    ColorAnimation {
                        duration: 200
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.animationCurves.expressiveEffects
                    }
                }

                // Breathing pulse animation on critical red (D-04)
                SequentialAnimation {
                    id: storagePulseAnimation
                    running: root.storageCritical
                    loops: Animation.Infinite
                    onRunningChanged: {
                        if (!running) {
                            storageIcon.opacity = 1.0;
                            storageCircProg.opacity = 1.0;
                            storageText.opacity = 1.0;
                        }
                    }
                    ParallelAnimation {
                        NumberAnimation { target: storageIcon; property: "opacity"; to: 0.4; duration: 600; easing.type: Easing.InOutSine }
                        NumberAnimation { target: storageCircProg; property: "opacity"; to: 0.4; duration: 600; easing.type: Easing.InOutSine }
                        NumberAnimation { target: storageText; property: "opacity"; to: 0.4; duration: 600; easing.type: Easing.InOutSine }
                    }
                    ParallelAnimation {
                        NumberAnimation { target: storageIcon; property: "opacity"; to: 1.0; duration: 600; easing.type: Easing.InOutSine }
                        NumberAnimation { target: storageCircProg; property: "opacity"; to: 1.0; duration: 600; easing.type: Easing.InOutSine }
                        NumberAnimation { target: storageText; property: "opacity"; to: 1.0; duration: 600; easing.type: Easing.InOutSine }
                    }
                }
            }
        }
    }

    StyledText {
        id: storageText
        Layout.alignment: Qt.AlignVCenter
        text: {
            const rootAvailGb = ((StorageUsage.rootDisk?.availKb ?? 0) / (1024 * 1024)).toFixed(1);
            const rootTotalGb = ((StorageUsage.rootDisk?.totalKb ?? 0) / (1024 * 1024)).toFixed(0);
            return `${rootAvailGb} / ${rootTotalGb} GB`;
        }
        font.pixelSize: Appearance.font.pixelSize.small
        color: root.storageColor

        Behavior on color {
            ColorAnimation {
                duration: 200
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.expressiveEffects
            }
        }
    }

    // --- RAM Section (Circular progress indicator + MaterialSymbol) ---
    ClippedFilledCircularProgress {
        id: ramCircProg
        Layout.alignment: Qt.AlignVCenter
        Layout.leftMargin: root.vertical ? 0 : 6 // Visual cluster separation per D-02
        lineWidth: Appearance.rounding.unsharpen
        value: Math.max(0.0, Math.min(1.0, ResourceUsage.memoryUsedPercentage || 0.0))
        implicitSize: 20
        colPrimary: root.ramColor
        accountForLightBleeding: !root.ramCritical && !root.ramWarning
        enableAnimation: false

        Item {
            anchors.centerIn: parent
            width: ramCircProg.implicitSize
            height: ramCircProg.implicitSize

            MaterialSymbol {
                id: ramIcon
                anchors.centerIn: parent
                text: "memory"
                iconSize: Appearance.font.pixelSize.normal
                color: root.ramColor

                Behavior on color {
                    ColorAnimation {
                        duration: 200
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.animationCurves.expressiveEffects
                    }
                }

                // Breathing pulse animation on critical red (D-04)
                SequentialAnimation {
                    id: ramPulseAnimation
                    running: root.ramCritical
                    loops: Animation.Infinite
                    onRunningChanged: {
                        if (!running) {
                            ramIcon.opacity = 1.0;
                            ramCircProg.opacity = 1.0;
                            ramText.opacity = 1.0;
                        }
                    }
                    ParallelAnimation {
                        NumberAnimation { target: ramIcon; property: "opacity"; to: 0.4; duration: 600; easing.type: Easing.InOutSine }
                        NumberAnimation { target: ramCircProg; property: "opacity"; to: 0.4; duration: 600; easing.type: Easing.InOutSine }
                        NumberAnimation { target: ramText; property: "opacity"; to: 0.4; duration: 600; easing.type: Easing.InOutSine }
                    }
                    ParallelAnimation {
                        NumberAnimation { target: ramIcon; property: "opacity"; to: 1.0; duration: 600; easing.type: Easing.InOutSine }
                        NumberAnimation { target: ramCircProg; property: "opacity"; to: 1.0; duration: 600; easing.type: Easing.InOutSine }
                        NumberAnimation { target: ramText; property: "opacity"; to: 1.0; duration: 600; easing.type: Easing.InOutSine }
                    }
                }
            }
        }
    }

    StyledText {
        id: ramText
        Layout.alignment: Qt.AlignVCenter
        text: {
            const freeGb = ((ResourceUsage.memoryAvailable > 0 ? ResourceUsage.memoryAvailable : ResourceUsage.memoryFree) / (1024 * 1024)).toFixed(1);
            const totalGb = (ResourceUsage.memoryTotal / (1024 * 1024)).toFixed(0);
            return `${freeGb} / ${totalGb} GB`;
        }
        font.pixelSize: Appearance.font.pixelSize.small
        color: root.ramColor

        Behavior on color {
            ColorAnimation {
                duration: 200
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.expressiveEffects
            }
        }
    }
```

### Example 3: `MemoryStoragePopup.qml` Column Swap (Storage Left, Memory Right)

```qml
// restow/quickshell/.config/quickshell/ii/modules/ii/bar/MemoryStoragePopup.qml
    RowLayout {
        id: popupContent
        anchors.centerIn: parent
        spacing: 16

        // Gated critical pulse animation (D-06)
        ...

        // =====================================================================
        // Left Column (320px): Storage Card (Throughput + Drives) (D-03)
        // =====================================================================
        ColumnLayout {
            Layout.preferredWidth: 320
            spacing: 8

            // Header Row with Live Throughput Badge (D-14, D-16)
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                StyledPopupHeaderRow {
                    icon: "storage"
                    label: "Storage"
                }

                Item { Layout.fillWidth: true }

                RowLayout {
                    spacing: 4
                    MaterialSymbol { text: "arrow_downward"; ... }
                    StyledText { text: root.formatThroughput(StorageUsage.readBytesPerSec); ... }
                    MaterialSymbol { text: "arrow_upward"; ... }
                    StyledText { text: root.formatThroughput(StorageUsage.writeBytesPerSec); ... }
                }
            }

            // Physical Drives
            StyledText { text: "Physical Drives"; ... }
            Repeater { model: StorageUsage.physicalDisks; delegate: StorageDriveRow {} }

            // Cloud Mounts
            ColumnLayout {
                visible: StorageUsage.cloudDisks && StorageUsage.cloudDisks.length > 0
                ...
                Repeater { model: StorageUsage.cloudDisks; delegate: StorageDriveRow {} }
            }

            Item { Layout.fillHeight: true }
        }

        // =====================================================================
        // Center Vertical Separator
        // =====================================================================
        Rectangle {
            Layout.fillHeight: true
            implicitWidth: 1
            color: Appearance.colors.colLayer0Border
        }

        // =====================================================================
        // Right Column (320px): Memory Card (RAM Allocation + Tiers) (D-03)
        // =====================================================================
        ColumnLayout {
            Layout.preferredWidth: 320
            spacing: 8

            StyledPopupHeaderRow {
                icon: "memory"
                label: "Memory"
            }

            // RAM Allocation Stacked Bar + Legend + Tiers (Used, Avail, Buffers, Cached, Free, Swap)
            ...

            Item { Layout.fillHeight: true }
        }
    }
```

---

## Assumptions Log

| # | Assumption | Status | Impact / Validation |
|---|---|---|---|
| 1 | Moving `MemoryStoragePill` ahead of `CpuGpuPill` preserves all mouse events and popup triggers without click bleed. | Verified | Inherited from Phase 43/44/45 architecture: each pill encapsulates an inert `MouseArea { parent: root; anchors.fill: parent; acceptedButtons: Qt.AllButtons; onClicked: event => event.accepted = true }`. |
| 2 | Removing `Resources.qml` and `Resource.qml` from `restow/` will not break any unmanaged component or service. | Verified | Codebase search confirmed zero remaining consumers of `Resources.qml` or `Resource.qml` in `restow/` or `capture/`. |
| 3 | Restoring upstream `.bak` files when unlinking leaves upstream files in an "unclaimed upstream stub" state that passes `./arch/dots-hyprland.sh verify --strict` cleanly. | Verified | Checked `classify_sweep_entry` Arm 7 in `arch/dots-hyprland.sh:1363-1370`; outputs `[INFO]` without increasing `FAIL` or `FINDINGS`. |
| 4 | Running `scripts/phase43-perf-assert.sh --quick` provides necessary performance verification without long benchmark delays. | Verified | Verified in terminal this session; completed in 5s with `FAIL: 0 FINDINGS: 0`. |

---

## Environment Availability

| Tool / Dependency | Version / Path | Status | Role in Phase 46 |
|---|---|---|---|
| `bash` | 5.3+ `/usr/bin/bash` | Confirmed | Test harness script execution |
| `stow` | GNU Stow `/usr/bin/stow` | Confirmed | Symlink farm management |
| `git` | 2.51+ `/usr/bin/git` | Confirmed | Porcelain drift verification & commit management |
| `jq` | 1.8+ `/usr/bin/jq` | Confirmed | JSON configuration parse tests |
| `curl` | 8.15+ `/usr/bin/curl` | Confirmed | Ping daemon bridge HTTP assertion |
| `python3` | 3.13+ `/usr/bin/python3` | Confirmed | Dynamic AST parsing and verification |
| `arch/dots-hyprland.sh` | Local repo wrapper | Confirmed | Strict verification gate (`verify --strict`) |

---

## Validation Architecture

### Script Scaffold: `scripts/phase46-telemetry-assert.sh`

The test harness follows the proven pattern from `scripts/phase41-interactions-assert.sh`:

```bash
#!/usr/bin/env bash
# ===========================================================================
# Phase 46: Left-Zone Integration, Verification & Repository Integrity Assert Harness
#
# Requirements Enforced:
#   INTG-01: Three standalone BarGroup pills integrated into BarContent.qml Left zone
#   INTG-02: Deployed via GNU Stow leaf symlinks under restow/quickshell/ (0 folding)
#   INTG-03: Consolidated assertion harness verifying sensors, bridge, mounts, zero churn
#
# Flags:
#   -s, --section <1-6>    Run only specified section
#   -q, --quick            Skip sub-harness delegation in Section 6
#   -c, --syntax           Syntax validation mode only
#   -h, --help             Show usage help
# ===========================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$REPO_ROOT"

# Counters
FAIL=0
FINDINGS=0

# Helpers: pass, fail, finding, info, soft
...

# Trap temporary files
TMP_FILES=()
cleanup() { rm -f "${TMP_FILES[@]}"; }
trap cleanup EXIT INT TERM

# Porcelain snapshot before execution
...

# Section 1: Stow Leaf Symlink Topology & Packaging Integrity (INTG-02, D-08, D-09)
# Section 2: BarContent.qml Left Zone Layout AST & Pill Sequence (INTG-01, D-01, D-04, D-05)
# Section 3: Component Internal Ordering & AST Verification (D-02, D-03)
# Section 4: Telemetry Service Sensors & Ping Daemon Bridge Liveness (INTG-03, D-10)
# Section 5: Responsive Layout & Workspace Centering Invariants (D-06, D-07)
# Section 6: Sub-Harness Orchestration & Strict Repository Verification (INTG-02, INTG-03, D-10)

# Final Porcelain diff assertion
```

### Sub-Harness Orchestration Matrix

| Step | Sub-Harness / Command | Target Component | Flags | Expected Outcome |
|---|---|---|---|---|
| 1 | `scripts/phase42-telemetry-services-assert.sh` | HardwareTelemetry, StorageUsage, PingService, ResourceUsage | None | `FAIL=0 FINDINGS=0`, exit 0 |
| 2 | `scripts/phase43.6-streamline-assert.sh` | CpuGpuPopup streamlined two-column layout | None | `FAIL=0 FINDINGS=0`, exit 0 |
| 3 | `scripts/phase43-perf-assert.sh` | Quickshell FD, CPU, RSS, Private Dirty limits | `--quick` | `FAIL=0 FINDINGS=0`, exit 0 |
| 4 | `scripts/phase44-memory-storage-assert.sh` | StorageUsage, ResourceUsage, MemoryStoragePill, MemoryStoragePopup | None | `FAIL=0 FINDINGS=0`, exit 0 |
| 5 | `scripts/phase45-network-ping-assert.sh` | NetworkUsage, PingService, NetworkPingPill, NetworkPingPopup | None | `FAIL=0 FINDINGS=0`, exit 0 |
| 6 | `./arch/dots-hyprland.sh verify --strict` | Full repo stow/restow/capture symlink farm and vendor submodule | None | Output matches `=== done: FAIL=0 FINDINGS=0 ===`, exit 0 |

---

## Security Domain (ASVS L1)

| Threat / Risk | ASVS L1 Control | Mitigation in Phase 46 |
|---|---|---|
| **Symlink Hijacking / Path Traversal** | V14.2 Dependency and Resource Integrity | All overlays are deployed as leaf symlinks strictly pointing to repository paths under `restow/quickshell/`. `./arch/dots-hyprland.sh verify --strict` enforces canonical resolution and fails if any symlink points outside the repo or is dangling. |
| **Uncontrolled Process Spawning** | V12.1 Command Execution | Left-click browser launch on `NetworkPingPill` uses argument array `Quickshell.execDetached(["xdg-open", "http://127.0.0.1:8765/"])` without shell interpolation. `StorageUsage` executes `["df", "-kP"]` via `Process`. |
| **Information Disclosure / Daemon Security** | V13.1 API and Web Service Security | Local ping monitor daemon communicates exclusively over loopback (`127.0.0.1:8765`) without exposing network endpoints or accepting untrusted input. |
| **Dead Code / Stale Attack Surface** | V14.1 Third-Party Software and Architecture | Complete retirement of legacy `Resources.qml` and `Resource.qml` removes obsolete QML code and prevents shadowing of upstream stubs. |

---

## Conclusion & Planning Guidance

Phase 46 is straightforward, high-confidence, and well-bounded:
- **Plan 46-01:** BarContent Left Zone Integration, Pill/Popup Storage-First Swaps & Legacy Retirement
  - Edit `BarContent.qml`: swap `CpuGpuPill` and `MemoryStoragePill` to achieve D-01 sequence.
  - Edit `MemoryStoragePill.qml`: swap Storage and Memory sections; transfer 6px separation margin to RAM per D-02.
  - Edit `MemoryStoragePopup.qml`: swap Storage (left) and Memory (right) columns around center divider per D-03.
  - Remove `restow/.../bar/Resource.qml` and `Resources.qml` from git; clean up live symlinks and restore upstream `.bak` files per D-08.
- **Plan 46-02:** Milestone v0.9 Consolidated Test Harness (`scripts/phase46-telemetry-assert.sh`) & Final Verification
  - Author `scripts/phase46-telemetry-assert.sh` covering Sections 1–6 per D-10 & D-11.
  - Run full test suite, verify zero git churn in `vendor/dots-hyprland`, zero working tree drift, and confirm milestone completion.
