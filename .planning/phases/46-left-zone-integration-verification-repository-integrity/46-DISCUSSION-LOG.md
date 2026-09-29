# Phase 46: Left-Zone Integration, Verification & Repository Integrity - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-29
**Phase:** 46-Left-Zone Integration, Verification & Repository Integrity
**Areas discussed:** Pill Sequence & Spacing in Left Zone, Responsive Behavior & Workspace Centering Protection, Legacy Resources Retirement & Cleanup, Consolidated Test Harness Architecture

---

## Pill Sequence & Spacing in Left Zone

| Option | Description | Selected |
|--------|-------------|----------|
| Standard Compute → Memory/Disk → Network | CpuGpuPill → MemoryStoragePill → NetworkPingPill | |
| User Directive: Storage/Memory First | LeftSidebarButton → Storage & Memory Pill → CPU/GPU Pill → Network/Ping Pill → UtilButtons | ✓ |
| Uniform 4px spacing with no vertical dividers | Preserves Phase 33 3-zone design contract and clean visual rhythm | ✓ |
| Add subtle vertical separator lines | Adds 1px colOutlineVariant vertical lines between pills | |
| Keep UtilButtons right after NetworkPingPill | Gated by verbose && useShortenedForm === 0 (current behavior) | ✓ |
| Always hide UtilButtons | Omit UtilButtons entirely from Left zone | |

**User's choice:** 
- Sequence: `LeftSidebarButton` → `StorageMemoryPill` → `CpuGpuPill` → `NetworkPingPill` → `utilButtonsGroup`.
- Internal metric order in Storage & Memory pill swapped: Storage first on left, Memory second on right.
- Storage & Memory popup columns swapped: Left column = Storage, Right column = Memory.
- Spacing: Uniform 4px spacing with zero dividers.
- UtilButtons: Positioned right after NetworkPingPill, visible when verbose and standard width.

---

## Responsive Behavior & Workspace Centering Protection

| Option | Description | Selected |
|--------|-------------|----------|
| Keep all 3 pills visible at all widths | Rely on pill compaction (hide °C on CPU, hide UtilButtons) and strict middleSection centering | ✓ |
| Progressive pill suppression | On ultra-narrow screens, hide ping targets or drop 3rd pill completely | |
| Add clip: true guard | Add clip: true on Left zone container to prevent visual overlap | |
| No clip needed | Rely on natural layout constraints and standard monitor resolutions | ✓ |

**User's choice:** Keep all 3 pills visible across all widths with adaptive compaction. Strict `middleSection` centering (`anchors.centerIn: parent`). No `clip: true` needed.

---

## Legacy Resources Retirement & Cleanup

| Option | Description | Selected |
|--------|-------------|----------|
| Remove Resources.qml and Resource.qml completely | Clean retirement with zero dead code in restow/quickshell/ overlay | ✓ |
| Keep in restow/quickshell/ as inert fallbacks | Retain files unreferenced in bar overlay | |
| Move to docs/archive/ | Archive old files for historical reference | |

**User's choice:** Completely remove `Resources.qml` and `Resource.qml` from `restow/quickshell/`.

---

## Consolidated Test Harness Architecture

| Option | Description | Selected |
|--------|-------------|----------|
| Orchestrated suite matching Phase 41 | Standalone sections (Stow leaf topology, layout AST, sensors, daemon bridge) + Phase 42–45 sub-harnesses + strict repo verify | ✓ |
| Standalone-only suite | Execute all checks directly inside phase46-telemetry-assert.sh without calling earlier sub-harnesses | |
| Standard CLI flags | Support -s/--section, -q/--quick/--standalone, -c/--syntax, -h/--help with fail-closed summary exit code | ✓ |

**User's choice:** Orchestrated suite following Phase 41 pattern with standard CLI flags.

---

## the agent's Discretion

- Exact internal layout adjustments in `MemoryStoragePill.qml` and `MemoryStoragePopup.qml` when swapping Storage and Memory order (preserving exact padding, animations, and hover anchors).
- Implementation details of AST grep patterns in `phase46-telemetry-assert.sh`.

## Deferred Ideas

None — discussion stayed strictly within the phase scope.
