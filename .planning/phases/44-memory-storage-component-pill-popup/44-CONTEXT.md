# Phase 44: Memory & Storage Component (Pill & Popup) - Context

**Gathered:** 2026-09-28
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase delivers the visual and interactive UI components for memory and storage monitoring in the Quickshell desktop status bar:

1. **`MemoryStoragePill.qml`**: Dedicated status bar pill placed in the top bar left zone, displaying real-time RAM usage and Root `/` storage usage with dual circular progress rings, percentage readouts, and Material Symbols, matching the exact styling and layout parity of `CpuGpuPill.qml`.
2. **`MemoryStoragePopup.qml`**: Interactive inspector popup overlay anchored to the pill with a 1000ms hover intent delay. Features a balanced two-column architecture:
   - **Left Column (Memory)**: Multi-segment stacked allocation overview bar, detailed numeric metrics for Used, Available, Buffers, Cached, Free, and dynamic Swap when configured, with two-tier amber/critical red alert colors and pulse animations.
   - **Right Column (Storage)**: Header disk I/O throughput badge (auto-scaling Read/Write speeds), structured sections for Physical Drives and Cloud FUSE Mounts, labeled with block device names and mount points, accompanied by `StyledProgressBar` meters and numeric capacity details (`Used / Total GB (XX%)`).
3. **Data Binding & Lifecycle Gating**: Full integration with `ResourceUsage.qml` and `StorageUsage.qml` singletons, with fast-polling and immediate on-demand `df` refresh on popup open.

**Out of Scope:**
- Network throughput and ping monitoring (`NetworkPingPill.qml` and `NetworkPingPopup.qml`) — Phase 45 owns this.
- Integration of all three pills into `BarContent.qml` left zone and repo-wide automated test harness — Phase 46 owns this.

</domain>

<decisions>
## Implementation Decisions

### Status Bar Pill Presentation & Responsive Layout

- **D-01 (RAM Metric Format):** Display RAM utilization as a percentage with a circular progress ring and inner `memory` MaterialSymbol (e.g. ring + `46%`), identical to the `CpuGpuPill` layout. — **Reversibility:** reversible.
- **D-02 (Storage Metric Format):** Display Storage utilization as a dual circular progress ring with inner `storage` MaterialSymbol and percentage text for Root `/` (e.g. ring + `38%`), creating visual symmetry with CpuGpuPill's CPU+GPU layout. — **Reversibility:** reversible.
- **D-03 (Responsive Layout Parity):** Retain both RAM and Storage rings and percentages even when `useShortenedForm > 0`, matching the exact spacing of `CpuGpuPill` without artificial hiding or squishing. — **Reversibility:** reversible.
- **D-04 (Two-Tier Alert Standards):** Apply unified two-tier alert thresholds for both RAM and Storage: warning amber at >=70%, critical red at >=90% with breathing pulse animation cycling opacity between 0.4 and 1.0 (100% parity with CpuGpuPill). — **Reversibility:** reversible.

### Popup Memory Breakdown & Visual Hierarchy

- **D-05 (Memory Overview Visualization):** Top of the Memory column features a multi-segment stacked allocation bar partitioned into Used (active), Buffers/Cached (reclaimable memory), and Free/Available space, with total `Used / Total GB` readout. — **Reversibility:** reversible.
- **D-06 (Clean Memory Tier Rows & Threshold Alerts):** Display clear numeric rows for Used, Available, Buffers, Cached, Free, and Swap with two-tier amber (>=70%) and critical red (>=90%) alert threshold colors with pulsing effects for critical states without overcomplicating the UI. — **Reversibility:** reversible.
- **D-07 (Swap Visibility Policy):** Popup displays the Swap row only when swap space actually exists on the system (`swapTotal > 0`); if no swap is configured on the machine, the swap row is hidden. Swap is never displayed on the status bar pill. — **Reversibility:** reversible.
- **D-08 (Balanced Two-Column Popup Architecture):** Arrange the inspector popup in a balanced two-column layout: Memory card on the Left column, Storage & Disks card on the Right column, matching the width and structural proportions of `CpuGpuPopup.qml`. — **Reversibility:** reversible.

### Multi-Mount Storage & Cloud FUSE Layout

- **D-09 (Drive Labeling with Block Device & Mount):** Label each drive row using its raw block device or filesystem name alongside its mount point (e.g., `nvme1n1p2 (/)`, `sda1 (/mnt/hdd)`). — **Reversibility:** reversible.
- **D-10 (Physical vs Cloud FUSE Sub-Sections):** Group storage mounts into two distinct sub-sections inside the Storage card: "Physical Drives" (NVMe, SATA) and "Cloud Mounts" (Google Drive), each with its own list of clean progress bars. — **Reversibility:** reversible.
- **D-11 (Dynamic Cloud Mount Display):** Dynamically display currently mounted cloud drives; if no cloud drives are connected/mounted, hide the "Cloud Mounts" sub-section entirely to eliminate visual clutter. — **Reversibility:** reversible.
- **D-12 (Drive Numeric Progress Details):** Accompany each drive's `StyledProgressBar` with `Used / Total GB` and percentage text (e.g., `45.2 / 120.0 GB (38%)`), following standard desktop conventions. — **Reversibility:** reversible.

### Disk I/O Activity & Live Throughput

- **D-13 (Pure Capacity Pill):** Status bar pill remains strictly dedicated to capacity percentages; all real-time disk I/O percentages and read/write speeds are reserved exclusively for the popup inspector. — **Reversibility:** reversible.
- **D-14 (Header Throughput Badge):** Integrate live Read and Write throughput rates into a compact badge directly within the Storage card's title header in the popup. — **Reversibility:** reversible.
- **D-15 (Subtle Active Drive Highlight):** Highlight whichever drive is actively performing I/O with a subtle indicator dot or accent highlight on its progress bar based on `StorageUsage.activeDisk`. — **Reversibility:** reversible.
- **D-16 (Auto-Scaling Throughput Units):** Format read and write throughput rates with auto-scaling units (`B/s`, `KB/s`, `MB/s` with 1 decimal place, e.g. `350 KB/s`, `12.4 MB/s`). — **Reversibility:** reversible.

### the agent's Discretion

- Exact mathematical smoothing or threshold rounding for multi-segment stacked bar sub-segments.
- Exact icon glyphs for Google Drive cloud mounts if distinguished from generic storage icons.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Services & Telemetry Providers
- `restow/quickshell/.config/quickshell/ii/services/ResourceUsage.qml` — Singleton service providing parsed `/proc/meminfo` metrics (`memoryTotal`, `memoryFree`, `memoryAvailable`, `memoryBuffers`, `memoryCached`, `memoryUsed`, `memoryUsedPercentage`, `swapTotal`, `swapFree`, `swapUsed`)
- `restow/quickshell/.config/quickshell/ii/services/StorageUsage.qml` — Singleton service executing non-blocking `df -k -P` mount discovery, `/proc/diskstats` I/O tracking, `activeDisk`, and throughput rates

### Shell UI Blueprints & Design Tokens
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPill.qml` — Reference pill architecture (circular progress rings, MaterialSymbol, alert colors, breathing pulse animation, and inert MouseArea popup anchoring)
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPopup.qml` — Reference popup architecture (two-column layout, card framing, `StyledProgressBar`, metric rows, and demand-gated fast polling)
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/StyledPopup.qml` — Universal popup window, layer-shell placement, 1000ms hover delay, and 200ms close grace period

### Requirements & Roadmap
- `.planning/ROADMAP.md` §Phase 44 — Phase goals and success criteria
- `.planning/REQUIREMENTS.md` §Memory & Storage Telemetry — Formal requirements MEMDSK-01..04

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ClippedFilledCircularProgress`: Circular progress ring component used in `CpuGpuPill.qml` for load visualization
- `MaterialSymbol`: Vector icons (`memory`, `storage`, `cloud`)
- `StyledProgressBar`: Linear progress bar component with highlight colors
- `StyledText`: Theme-aware typography component
- `ResourceUsage`: Global memory and swap singleton
- `StorageUsage`: Global storage and disk I/O singleton

### Established Patterns
- **Inert MouseArea Anchor**: Pill contains an inert `MouseArea` that consumes clicks and acts as `hoverTarget` for `StyledPopup`.
- **Demand-Gated Fast Polling**: Popup toggles `ResourceUsage.isInspectorActive` and triggers `StorageUsage.refresh()` on `activeChanged`.
- **Material 3 Tokens**: Uses `Appearance.colors.colPrimary`, `Appearance.colors.colOnLayer1`, `Appearance.colors.colWarning`, and `Appearance.colors.colError`.
- **Critical Pulse Animation**: Critical states (>90%) trigger an infinite opacity animation (0.4 to 1.0 over 600ms).

### Integration Points
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/MemoryStoragePill.qml`: New component to be instantiated in left zone
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/MemoryStoragePopup.qml`: New popup overlay instantiated inside the pill's MouseArea

</code_context>

<specifics>
## Specific Ideas

- **Symmetry with CpuGpuPill**: Ensure `MemoryStoragePill` looks like an identical twin to `CpuGpuPill` (RAM on left with circular ring and `memory` icon, Storage on right with circular ring and `storage` icon, matching spacing and font sizes).
- **No Squishing on Shortened Form**: The user explicitly requested to retain both RAM and Storage circular rings and percentage texts with unchanged spacing when `useShortenedForm > 0`.
- **Raw Device Names**: In the storage popup, label rows with block device names (e.g. `nvme1n1p2 (/)`, `sda1 (/mnt/hdd)`) so the exact drive partition is unambiguous.
- **Dynamic Cloud Section**: Cloud section disappears completely when no Google Drive FUSE mounts are active.

</specifics>

<deferred>
## Deferred Ideas

- **Phase 46 (Left-Zone Integration & Automated Assertion Harness)**:
  - Placing `MemoryStoragePill.qml` alongside `CpuGpuPill.qml` and `NetworkPingPill.qml` in `BarContent.qml`.
  - Comprehensive automated assertion harness (`scripts/phase46-telemetry-assert.sh`) testing all telemetry services and bar components.

</deferred>

---

*Phase: 44-memory-storage-component-pill-popup*
*Context gathered: 2026-09-28*
