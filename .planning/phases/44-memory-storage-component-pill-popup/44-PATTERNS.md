# Phase 44: Memory & Storage Component (Pill & Popup) - Pattern Map

**Gathered:** 2026-09-28  
**Phase:** 44 - memory-storage-component-pill-popup  
**Milestone:** v0.9 (Top Status Bar Resource Components & Hardware Telemetry)  
**Status:** Complete & Ready for Planning  

---

## 1. Executive Summary

This document establishes the exact architectural patterns, code blueprints, and anti-pattern guardrails for Phase 44: **Memory & Storage Telemetry Component** (`MemoryStoragePill.qml` and `MemoryStoragePopup.qml`).

Following the design parity established in Phase 43 (`CpuGpuPill.qml` and `CpuGpuPopup.qml`), Phase 44 builds the visual status bar widget and interactive two-column inspector popup for RAM and storage devices. Every file to be created or modified is mapped to an authoritative existing analog in the codebase with verbatim code excerpts, property declarations, and implementation guidelines.

---

## 2. File Inventory & Classification

| File Path | Role | Data Flow | Closest Analog |
| :--- | :--- | :--- | :--- |
| `restow/quickshell/.config/quickshell/ii/modules/ii/bar/MemoryStoragePill.qml` | UI Component (Status Bar Widget) | Downward read-only bindings from `ResourceUsage` and `StorageUsage`; hosts inert MouseArea hover anchor for popup | `restow/quickshell/.../bar/CpuGpuPill.qml` |
| `restow/quickshell/.config/quickshell/ii/modules/ii/bar/MemoryStoragePopup.qml` | UI Component (Overlay Inspector) | Bidirectional lifecycle gating with `ResourceUsage` and `StorageUsage`; reads detailed telemetry for memory breakdown & drives | `restow/quickshell/.../bar/CpuGpuPopup.qml` |
| `restow/quickshell/.config/quickshell/ii/services/ResourceUsage.qml` | Telemetry Singleton Service | Parses `/proc/meminfo` and `/proc/stat`; exposes distinct `MemFree` vs `MemAvailable` | Existing `ResourceUsage.qml` |
| `restow/quickshell/.config/quickshell/ii/services/StorageUsage.qml` | Telemetry Singleton Service | Samples `/proc/diskstats` (1s); runs `timeout 3 df -k -P` on I/O delta, 30s background timer, or on-demand | Existing `StorageUsage.qml` |
| `scripts/phase44-memory-storage-assert.sh` | Quality Assertion Test Suite | CLI test harness validating AST, properties, syntax, Stow symlinks, and `./arch/dots-hyprland.sh verify --strict` | `scripts/phase43-cpu-gpu-assert.sh` |

---

## 3. Per-File Pattern Assignments

### 3.1 `MemoryStoragePill.qml`

- **Target File:** `restow/quickshell/.config/quickshell/ii/modules/ii/bar/MemoryStoragePill.qml`
- **Role:** Status bar telemetry pill widget in the top bar left zone.
- **Data Flow:**
  - Reads `ResourceUsage.memoryUsedPercentage` for RAM load.
  - Reads `StorageUsage.rootDisk?.usePercent` for Root filesystem `/` capacity.
  - Computes two-tier alert states (`ramCritical`, `ramWarning`, `storageCritical`, `storageWarning`).
  - Re-parents inert `MouseArea` to `root` to consume clicks and serve as `hoverTarget` for `MemoryStoragePopup`.
- **Closest Analog:** `restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPill.qml` [restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPill.qml:1-220](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPill.qml#L1-L220)

#### Architectural Blueprint & Patterns to Copy
1. **Pragma & Base Component:**
   Must declare `pragma ComponentBehavior: Bound` and inherit `BarGroup` as root.
2. **Inert MouseArea Anchor with Re-parenting:**
   Because `BarGroup` exposes `default property alias items: gridLayout.children`, any child element defaults to being placed in `gridLayout`. The `MouseArea` MUST specify `parent: root` and `anchors.fill: parent` so it escapes the grid layout, covers the whole pill, consumes clicks (`acceptedButtons: Qt.AllButtons`, `onClicked: event => event.accepted = true`), and hosts `MemoryStoragePopup { hoverTarget: root.hoverArea }`.
3. **Circular Progress Rings & Glyphs:**
   Dual `ClippedFilledCircularProgress` items (`implicitSize: 20`, `lineWidth: Appearance.rounding.unsharpen`) with centered `MaterialSymbol` icons:
   - RAM: `memory` icon, `${Math.round((ResourceUsage.memoryUsedPercentage || 0.0) * 100)}%` StyledText.
   - Storage: `storage` icon, `Layout.leftMargin: root.vertical ? 0 : 6` visual cluster separation, `${StorageUsage.rootDisk?.usePercent ?? 0}%` StyledText.
4. **Responsive Shortened Form Behavior (D-03):**
   Retain both RAM and Storage rings and percentages even when `useShortenedForm > 0`. Do NOT squish or hide metrics.
5. **Two-Tier Alert Thresholds & Breathing Pulse (D-04):**
   - Warning threshold: $\ge 70\%$ load $\rightarrow$ `Appearance.colors.colWarning ?? "#FFA000"`
   - Critical threshold: $\ge 90\%$ load $\rightarrow$ `Appearance.colors.colError`
   - Normal threshold: $< 70\%$ load $\rightarrow$ `Appearance.colors.colOnLayer1`
   - Critical breathing pulse: Infinite `SequentialAnimation` cycling opacity between 0.4 and 1.0 over 600ms, with `onRunningChanged` resetting opacity to 1.0 when running ceases.

#### Concrete Code Excerpts from Analog (`CpuGpuPill.qml`)

```qml
// restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPill.qml:1-53
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell

BarGroup {
    id: root

    property real useShortenedForm: 0

    // Public alias for popup anchoring (D-17)
    readonly property alias hoverArea: inertMouseArea

    // Two-tier alert state thresholds (D-09, D-10)
    readonly property bool ramCritical: (ResourceUsage.memoryUsedPercentage || 0.0) >= 0.90
    readonly property bool ramWarning: !ramCritical && (ResourceUsage.memoryUsedPercentage || 0.0) >= 0.70

    readonly property bool storageCritical: ((StorageUsage.rootDisk?.usePercent ?? 0) / 100.0) >= 0.90
    readonly property bool storageWarning: !storageCritical && ((StorageUsage.rootDisk?.usePercent ?? 0) / 100.0) >= 0.70

    // Dynamic Material You token resolution with dots-hyprland amber warning color fallback
    readonly property color warningColor: Appearance.colors.colWarning !== undefined ? Appearance.colors.colWarning : "#FFA000"
    readonly property color ramColor: ramCritical ? Appearance.colors.colError : (ramWarning ? warningColor : Appearance.colors.colOnLayer1)
    readonly property color storageColor: storageCritical ? Appearance.colors.colError : (storageWarning ? warningColor : Appearance.colors.colOnLayer1)

    // Re-parented inert MouseArea (D-17, Pitfall 1)
    MouseArea {
        id: inertMouseArea
        parent: root
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        cursorShape: Qt.ArrowCursor
        hoverEnabled: true
        onPressed: event => event.accepted = true
        onClicked: event => event.accepted = true

        MemoryStoragePopup {
            hoverTarget: root.hoverArea
        }
    }
```

```qml
// restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPill.qml:86-110
// Critical Breathing Pulse Pattern:
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
```

#### Anti-Patterns to Avoid
- **DO NOT** omit `parent: root` on the `MouseArea`. Omitting it causes `MouseArea` to be added into `gridLayout`, breaking the pill dimensions and failing to cover the pill.
- **DO NOT** use hardcoded hex alert colors (e.g. `#FF0000` or `#FF5555`). Always use `Appearance.colors.colError` and `warningColor` with `#FFA000` fallback.
- **DO NOT** hide the storage or RAM ring when `useShortenedForm > 0`. Per D-03, both metrics must remain visible with unchanged spacing.

---

### 3.2 `MemoryStoragePopup.qml`

- **Target File:** `restow/quickshell/.config/quickshell/ii/modules/ii/bar/MemoryStoragePopup.qml`
- **Role:** Interactive two-column inspector popup window overlay anchored to `MemoryStoragePill.qml`.
- **Data Flow:**
  - Manages demand-gated fast-polling: accelerates `ResourceUsage` polling to 1000ms (`isInspectorActive = true`) and triggers `ResourceUsage.pollMetrics()` and `StorageUsage.refresh()` on activation. Restores 3000ms idle cadence on close.
  - Left Column reads `ResourceUsage` telemetry: `memoryTotal`, `memoryUsed`, `memoryAvailable`, `memoryBuffers`, `memoryCached`, `memoryFree`, `swapTotal`, `swapUsed`.
  - Right Column reads `StorageUsage` telemetry: `readBytesPerSec`, `writeBytesPerSec`, `physicalDisks`, `cloudDisks`, `activeDisk`, `diskIoPercentage`.
- **Closest Analog:** `restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPopup.qml` [restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPopup.qml:1-338](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPopup.qml#L1-L338)

#### Architectural Blueprint & Patterns to Copy
1. **Base Type & Bound Pragma:**
   Must declare `pragma ComponentBehavior: Bound` and inherit `StyledPopup` as root.
2. **Lifecycle Gating:**
   ```qml
   onActiveChanged: {
       ResourceUsage.isInspectorActive = active;
       if (active) {
           ResourceUsage.pollMetrics();
           StorageUsage.refresh();
       }
   }

   Component.onDestruction: {
       if (active) {
           ResourceUsage.isInspectorActive = false;
       }
   }
   ```
3. **Two-Column Balanced Architecture (D-08):**
   `RowLayout { spacing: 16 }` centered in parent.
   - Left Column: `ColumnLayout { Layout.preferredWidth: 320; spacing: 8 }` (Memory Inspector).
   - Center Vertical Separator: `Rectangle { Layout.fillHeight: true; implicitWidth: 1; color: Appearance.colors.colLayer0Border }`.
   - Right Column: `ColumnLayout { Layout.preferredWidth: 320; spacing: 8 }` (Storage Inspector).
4. **Popup Gated Pulse Animation:**
   Pulse animation on critical state MUST be gated on `root.active && root.isCritical`, resetting `criticalPulseOpacity = 1.0` on stop to prevent CPU churn when the popup is closed.
5. **Left Column (Memory) Hierarchy:**
   - Header: `StyledPopupHeaderRow { icon: "memory"; label: "Memory" }`
   - Multi-Segment Stacked Allocation Bar:
     - Header text: `RAM Allocation` on left, `${root.formatKB(ResourceUsage.memoryUsed)} / ${root.formatKB(ResourceUsage.memoryTotal)} (${Math.round(ResourceUsage.memoryUsedPercentage * 100)}%)` on right.
     - Container: `Rectangle { Layout.fillWidth: true; implicitHeight: 8; radius: 4; clip: true; color: Appearance.m3colors.m3surfaceContainerHigh }`
     - Sub-segment 1: Used (active memory), width `parent.width * (ResourceUsage.memoryUsed / ResourceUsage.memoryTotal)`, color `root.getLoadColor(ResourceUsage.memoryUsedPercentage)`.
     - Sub-segment 2: Buffers/Cached (reclaimable memory), width `parent.width * (Math.max(0, ResourceUsage.memoryAvailable - ResourceUsage.memoryFree) / ResourceUsage.memoryTotal)`, color `Appearance.colors.colSecondary ?? Appearance.colors.colPrimary`, opacity 0.6.
     - Legend row: Color dot badges for "Used", "Buffers/Cache", "Free".
   - Horizontal separator: `Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Appearance.colors.colLayer0Border }`
   - Detailed Numeric Tier Rows (`component MemoryTierRow: RowLayout`):
     - Used: `root.formatKB(ResourceUsage.memoryUsed)` with alert color.
     - Available: `root.formatKB(ResourceUsage.memoryAvailable)`.
     - Buffers: `root.formatKB(ResourceUsage.memoryBuffers)`.
     - Cached: `root.formatKB(ResourceUsage.memoryCached)`.
     - Free: `root.formatKB(ResourceUsage.memoryFree)`.
     - Dynamic Swap Row (gated on `ResourceUsage.swapTotal > 0`): `${root.formatKB(ResourceUsage.swapUsed)} / ${root.formatKB(ResourceUsage.swapTotal)} (${Math.round(ResourceUsage.swapUsedPercentage * 100)}%)`.
6. **Right Column (Storage) Hierarchy:**
   - Header Row:
     - Left: `StyledPopupHeaderRow { icon: "storage"; label: "Storage" }`
     - Right: Live Throughput Badge showing `arrow_downward` + `root.formatThroughput(StorageUsage.readBytesPerSec)` and `arrow_upward` + `root.formatThroughput(StorageUsage.writeBytesPerSec)`.
   - Sub-section: "Physical Drives"
     - Sub-heading StyledText: `Physical Drives`
     - Repeater over `StorageUsage.physicalDisks` with `StorageDriveRow`
   - Sub-section: "Cloud Mounts (Google Drive)"
     - Conditional on `StorageUsage.cloudDisks && StorageUsage.cloudDisks.length > 0` (D-11).
     - Horizontal separator
     - Sub-heading StyledText: `Cloud Mounts (Google Drive)`
     - Repeater over `StorageUsage.cloudDisks` with `StorageDriveRow`
   - `StorageDriveRow` Sub-Component (`component StorageDriveRow: ColumnLayout`):
     - Active drive indicator dot (visible if `StorageUsage.activeDisk === modelData.mount && StorageUsage.diskIoPercentage > 0`).
     - Label: `root.formatDriveLabel(modelData.fs, modelData.mount)` (e.g., `nvme0n1p2 (/)`, `sda1 (/mnt/hdd)`).
     - Numeric detail: `${root.formatKB(modelData.usedKb)} / ${root.formatKB(modelData.totalKb)} (${modelData.usePercent}%)`.
     - `StyledProgressBar` with `value: modelData.usePercent / 100.0`, highlight color based on alert threshold.

#### Concrete Code Excerpts from Analog (`CpuGpuPopup.qml`)

```qml
// restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPopup.qml:10-52
StyledPopup {
    id: root

    readonly property color warningColor: Appearance.colors.colWarning !== undefined ? Appearance.colors.colWarning : "#FFA000"

    function getLoadColor(val) {
        if (val >= 0.90) return Appearance.colors.colError;
        if (val >= 0.70) return root.warningColor;
        return Appearance.colors.colPrimary;
    }

    readonly property bool isCritical: (ResourceUsage.memoryUsedPercentage || 0.0) >= 0.90 || ((StorageUsage.rootDisk?.usePercent ?? 0) / 100.0) >= 0.90
    property real criticalPulseOpacity: 1.0

    // Gated critical pulse animation (D-10)
    SequentialAnimation {
        id: popupCriticalPulse
        running: root.active && root.isCritical
        loops: Animation.Infinite
        onRunningChanged: {
            if (!running) root.criticalPulseOpacity = 1.0;
        }
        NumberAnimation {
            target: root
            property: "criticalPulseOpacity"
            to: 0.4
            duration: 600
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: root
            property: "criticalPulseOpacity"
            to: 1.0
            duration: 600
            easing.type: Easing.InOutSine
        }
    }
```

```qml
// restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPopup.qml:162-266
// Balanced Two-Column Proportions:
RowLayout {
    id: popupContent
    anchors.centerIn: parent
    spacing: 16

    ColumnLayout {
        Layout.preferredWidth: 320
        spacing: 8
        // Left Column Content
    }

    Rectangle {
        Layout.fillHeight: true
        implicitWidth: 1
        color: Appearance.colors.colLayer0Border
    }

    ColumnLayout {
        Layout.preferredWidth: 320
        spacing: 8
        // Right Column Content
    }
}
```

#### Formatting Helper Functions

```javascript
function formatKB(kb) {
    if (!kb || kb <= 0) return "0.0 GB";
    return (kb / (1024 * 1024)).toFixed(1) + " GB";
}

function formatThroughput(bytesPerSec) {
    if (!bytesPerSec || bytesPerSec <= 0) return "0 B/s";
    if (bytesPerSec < 1024) return bytesPerSec.toFixed(0) + " B/s";
    if (bytesPerSec < 1024 * 1024) return (bytesPerSec / 1024).toFixed(1) + " KB/s";
    if (bytesPerSec < 1024 * 1024 * 1024) return (bytesPerSec / (1024 * 1024)).toFixed(1) + " MB/s";
    return (bytesPerSec / (1024 * 1024 * 1024)).toFixed(1) + " GB/s";
}

function formatDriveLabel(fs, mount) {
    if (!fs) return mount || "Drive";
    if (fs.startsWith("/dev/")) {
        const devName = fs.substring(5);
        return `${devName} (${mount})`;
    }
    const cleanFs = fs.replace(/:$/, "");
    if (cleanFs.includes("gdrive")) {
        return cleanFs;
    }
    return `${cleanFs} (${mount})`;
}
```

#### Anti-Patterns to Avoid
- **DO NOT** run `popupCriticalPulse` unconditionally. It must include `running: root.active && root.isCritical` and reset `criticalPulseOpacity = 1.0` on stop.
- **DO NOT** display Swap when `swapTotal === 0`. Hide the swap row completely when no swap partition exists on the host.
- **DO NOT** hardcode disk mount paths or assume `/` is on `nvme1n1`. Use the dynamic `fs` and `mount` properties provided by `StorageUsage`.
- **DO NOT** leave `ResourceUsage.isInspectorActive` set to `true` when the popup is destroyed.

---

### 3.3 `ResourceUsage.qml`

- **Target File:** `restow/quickshell/.config/quickshell/ii/services/ResourceUsage.qml`
- **Role:** Singleton service parsing procfs memory metrics and providing dynamic polling timers.
- **Data Flow:**
  - Reads `/proc/meminfo` on each trigger of `pollTimer` (1000ms when inspector active, 3000ms idle).
  - Updates `memoryTotal`, `memoryAvailable`, `memoryFree`, `memoryBuffers`, `memoryCached`, `memoryUsed`, `memoryUsedPercentage`, `swapTotal`, `swapFree`, `swapUsed`.
- **Closest Analog:** Existing `ResourceUsage.qml` [restow/quickshell/.config/quickshell/ii/services/ResourceUsage.qml:1-146](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/services/ResourceUsage.qml#L1-L146)

#### Architectural Defect & Required Modification
In the existing implementation at line 85:
```qml
// DEFECT:
memoryAvailable = Number(textMeminfo.match(/MemAvailable:\s*(\d+)/)?.[1] ?? 0);
memoryFree = memoryAvailable; // <--- Incorrect: MemFree is unallocated memory, MemAvailable includes reclaimable page cache
```

#### Code Change Excerpt
```qml
// restow/quickshell/.config/quickshell/ii/services/ResourceUsage.qml:83-89
memoryTotal = Number(textMeminfo.match(/MemTotal:\s*(\d+)/)?.[1] ?? 1);
memoryAvailable = Number(textMeminfo.match(/MemAvailable:\s*(\d+)/)?.[1] ?? 0);
memoryFree = Number(textMeminfo.match(/MemFree:\s*(\d+)/)?.[1] ?? 0);
memoryBuffers = Number(textMeminfo.match(/Buffers:\s*(\d+)/)?.[1] ?? 0);
memoryCached = Number(textMeminfo.match(/^Cached:\s*(\d+)/m)?.[1] ?? 0);
swapTotal = Number(textMeminfo.match(/SwapTotal:\s*(\d+)/)?.[1] ?? 1);
swapFree = Number(textMeminfo.match(/SwapFree:\s*(\d+)/)?.[1] ?? 0);
```

#### Verification Standard
`memoryUsed` preserves standard Linux `free -m` calculation:
```qml
property real memoryUsed: Math.max(0, memoryTotal - (memoryAvailable > 0 ? memoryAvailable : memoryFree))
```
`memoryFree` reflects raw unallocated RAM (`MemFree`), while `memoryAvailable` reflects reclaimable memory capacity.

---

### 3.4 `StorageUsage.qml`

- **Target File:** `restow/quickshell/.config/quickshell/ii/services/StorageUsage.qml`
- **Role:** Singleton service monitoring `/proc/diskstats` I/O rates and asynchronously discovering mounts via `df -k -P`.
- **Data Flow:**
  - `updateDiskIo()` samples `/proc/diskstats` every 1000ms to calculate read/write bytes per second and determine `activeDisk`.
  - Discovers mounts via `Process { command: ["bash", "-c", "timeout 3 df -k -P"] }`.
  - Emits `physicalDisks` and `cloudDisks` arrays, plus `rootDisk` object.
- **Closest Analog:** Existing `StorageUsage.qml` [restow/quickshell/.config/quickshell/ii/services/StorageUsage.qml:1-237](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/services/StorageUsage.qml#L1-L237)

#### Architectural Defects & Required Modifications
1. **Defect 1: Hardcoded Inverted NVMe Device Mapping:**
   Lines 136-141 currently hardcode:
   ```qml
   function deviceToMount(dev) {
       if (dev.startsWith("nvme1n1")) return "/";
       if (dev.startsWith("nvme0n1")) return "/mnt/windows";
       if (dev.startsWith("sda")) return "/mnt/hdd";
       return "/";
   }
   ```
   On the host machine, `/` is on `/dev/nvme0n1p2`, and `/mnt/windows` is on `/dev/nvme1n1p3`.
   **Fix:** Match dynamically against the populated `mounts` array:
   ```qml
   function deviceToMount(dev) {
       for (let i = 0; i < mounts.length; i++) {
           if (mounts[i].fs && mounts[i].fs.includes(dev)) {
               return mounts[i].mount;
           }
       }
       return "/";
   }
   ```
2. **Defect 2: Missing Periodic Background Polling Fallback (MEMDSK-04):**
   Line 131 only triggers `df` when `totalIoTicksDelta > 0 && (now - lastDfTime) > dfCooldownMs`. During extended disk idle, `df` never runs in the background.
   **Fix:** Add 30s background fallback:
   ```qml
   if ((totalIoTicksDelta > 0 && (now - lastDfTime) > dfCooldownMs) || (now - lastDfTime) > 30000) {
       root.refresh();
   }
   ```

---

### 3.5 `scripts/phase44-memory-storage-assert.sh`

- **Target File:** `scripts/phase44-memory-storage-assert.sh`
- **Role:** Automated assertion harness for Phase 44 validating requirements MEMDSK-01..04 and decisions D-01..D-16.
- **Closest Analog:** `scripts/phase43-cpu-gpu-assert.sh` [scripts/phase43-cpu-gpu-assert.sh:1-555](file:///home/pera/github_repo/.dotfiles/scripts/phase43-cpu-gpu-assert.sh#L1-L555)

#### Assertion Structure to Replicate
1. **Section Selection CLI:**
   Supports positional section argument `[1-5]`, `--section|-s <1-5>`, `--quick|-q`, `--syntax|-c`, `--help`.
2. **Trap Cleanup & Counter Setup:**
   `set -euo pipefail`, non-root check, `TMP_FILES` array with `trap cleanup EXIT INT TERM`, `pass()`, `fail()`, `finding()`, `info()` functions, tracking `FAIL` and `FINDINGS`.
3. **Section 1: Static AST & Syntax Verification:**
   - Validates existence of `MemoryStoragePill.qml` and `MemoryStoragePopup.qml`.
   - Validates `pragma ComponentBehavior: Bound` in both files.
   - Material Symbols validation (`memory`, `storage`, `arrow_downward`, `arrow_upward`).
   - Zero hardcoded alert hex colors check (permits `#FFA000` fallback and warningColor).
4. **Section 2: `MemoryStoragePill.qml` Component Logic:**
   - Base type `BarGroup`.
   - Re-parented `MouseArea` (`parent: root`, `anchors.fill: parent`, `acceptedButtons: Qt.AllButtons`).
   - Circular progress rings with `implicitSize: 20` and `lineWidth: Appearance.rounding.unsharpen`.
   - Alert threshold logic (70% warning, 90% critical).
   - Infinite breathing pulse animations (`ramPulseAnimation`, `storagePulseAnimation`) with opacity cleanup on stopped.
   - Unconditional metric retention regardless of `useShortenedForm`.
5. **Section 3: `MemoryStoragePopup.qml` Layout & Telemetry Bindings:**
   - Base type `StyledPopup`.
   - Lifecycle gating (`onActiveChanged` sets `isInspectorActive`, calls `ResourceUsage.pollMetrics()` and `StorageUsage.refresh()`).
   - Balanced two-column 320px architecture (`Layout.preferredWidth: 320`, center vertical separator).
   - Multi-segment stacked allocation bar with Used, Buffers/Cached, and Free segments.
   - Numeric memory tier rows (Used, Available, Buffers, Cached, Free).
   - Dynamic Swap row gating (`swapTotal > 0`).
   - Storage physical and cloud FUSE mount sections with `StyledProgressBar` and `formatDriveLabel`.
   - Header live throughput badge (`arrow_downward` / `arrow_upward` with `formatThroughput`).
   - Active I/O drive dot indicator.
6. **Section 4: Telemetry Services Hardening:**
   - `ResourceUsage.qml` parses `MemFree` distinctly from `MemAvailable`.
   - `StorageUsage.qml` implements dynamic `deviceToMount` mapping without hardcoded NVMe inversions.
   - `StorageUsage.qml` includes 30s background timer fallback.
7. **Section 5: Stow Integrity & Packaging Verification:**
   - Symlinks exist in `${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/ii/modules/ii/bar/` pointing to `restow/quickshell/...`.
   - `vendor/dots-hyprland` git status is completely clean (zero modifications).
   - `./arch/dots-hyprland.sh verify --strict` exits 0.

---

## 4. Cross-Cutting Patterns & Design Rules

### 4.1 QML Bound Component Behavior
All newly authored and modified QML files MUST begin with:
```qml
pragma ComponentBehavior: Bound
```
This enables static compilation checks, strict type safety, and optimal performance under the Quickshell QML runtime engine.

### 4.2 Material You Dynamic Alert Tokens & Fallback
Status indicators and progress bars use dynamic Material You tokens:
```qml
readonly property color warningColor: Appearance.colors.colWarning !== undefined ? Appearance.colors.colWarning : "#FFA000"
```
- `< 70%`: `Appearance.colors.colOnLayer1` (in pills) / `Appearance.colors.colPrimary` (in popups)
- `70% .. 89%`: `warningColor`
- `≥ 90%`: `Appearance.colors.colError`

### 4.3 Inert MouseArea Anchor Pattern in `BarGroup`
To attach a hover-activated `StyledPopup` to a status bar pill built with `BarGroup`:
```qml
// Because BarGroup aliases items to gridLayout.children,
// the MouseArea MUST be re-parented to root:
MouseArea {
    id: inertMouseArea
    parent: root
    anchors.fill: parent
    acceptedButtons: Qt.AllButtons
    cursorShape: Qt.ArrowCursor
    hoverEnabled: true
    onPressed: event => event.accepted = true
    onClicked: event => event.accepted = true

    MemoryStoragePopup {
        hoverTarget: root.hoverArea
    }
}
```

### 4.4 Demand-Gated Fast Polling Lifecycle
Popups that request accelerated telemetry MUST manage their lifecycle explicitly:
```qml
onActiveChanged: {
    ResourceUsage.isInspectorActive = active;
    if (active) {
        ResourceUsage.pollMetrics();
        StorageUsage.refresh();
    }
}

Component.onDestruction: {
    if (active) {
        ResourceUsage.isInspectorActive = false;
    }
}
```

### 4.5 Critical State Gated Breathing Pulse
Critical pulse animations MUST only animate while the popup/pill is active or visible:
```qml
SequentialAnimation {
    id: popupCriticalPulse
    running: root.active && root.isCritical
    loops: Animation.Infinite
    onRunningChanged: {
        if (!running) root.criticalPulseOpacity = 1.0;
    }
    NumberAnimation {
        target: root
        property: "criticalPulseOpacity"
        to: 0.4
        duration: 600
        easing.type: Easing.InOutSine
    }
    NumberAnimation {
        target: root
        property: "criticalPulseOpacity"
        to: 1.0
        duration: 600
        easing.type: Easing.InOutSine
    }
}
```

### 4.6 GNU Stow Leaf Symlink Packaging Rule
- **Rule:** Never modify `vendor/dots-hyprland/` directly. All custom files belong in `restow/quickshell/`.
- Deploying a new file in `restow/quickshell/.config/quickshell/ii/modules/ii/bar/` requires symlinking into `~/.config/quickshell/ii/modules/ii/bar/` without directory folding:
  ```bash
  stow -d restow -t "$HOME" quickshell
  ```
- Strict verification via `./arch/dots-hyprland.sh verify --strict` must always succeed.

---

## 5. Implementation Checklist for Planner

When constructing implementation plans (e.g. `44-01-PLAN.md` and `44-02-PLAN.md`), the planner should reference the following verification steps:

- [ ] `ResourceUsage.qml`: Line 85 assigns `memoryFree = Number(textMeminfo.match(/MemFree:\s*(\d+)/)?.[1] ?? 0);`.
- [ ] `StorageUsage.qml`: `deviceToMount()` scans `mounts` array dynamically; `updateDiskIo()` includes `(now - lastDfTime) > 30000` fallback.
- [ ] `MemoryStoragePill.qml`: Inherits `BarGroup`, bound pragma, re-parented `inertMouseArea`, dual circular rings (size 20), Material Symbols `memory` and `storage`, two-tier alerts, breathing pulse, unchanged layout when `useShortenedForm > 0`.
- [ ] `MemoryStoragePopup.qml`: Inherits `StyledPopup`, bound pragma, demand-gated fast-polling, two 320px columns, multi-segment stacked allocation bar, memory tier rows, conditional swap row, segregated physical vs cloud storage, active drive dot highlight, header throughput badge with auto-scaling units.
- [ ] Symlink deployment in `~/.config/quickshell/ii/modules/ii/bar/` via Stow.
- [ ] `scripts/phase44-memory-storage-assert.sh`: Passes all 5 sections with `FAIL=0 FINDINGS=0`.
- [ ] Upstream integrity: `./arch/dots-hyprland.sh verify --strict` passes cleanly.

---

*Pattern Map Completed: 2026-09-28*  
*Author: Phase 44 Pattern Mapper Agent*
