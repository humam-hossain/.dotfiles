# Phase 46: Left-Zone Integration, Verification & Repository Integrity - Pattern Map

**Gathered:** 2026-09-29  
**Phase:** 46 - left-zone-integration-verification-repository-integrity  
**Milestone:** v0.9 (Top Status Bar Resource Components & Hardware Telemetry)  
**Status:** Complete & Ready for Planning  

---

## 1. Executive Summary

This document establishes the authoritative architectural patterns, code blueprints, concrete code excerpts, anti-pattern guardrails, and validation structures for **Phase 46: Left-Zone Integration, Verification & Repository Integrity**.

Phase 46 represents the milestone culmination of Milestone v0.9. All underlying telemetry sensor services (`HardwareTelemetry.qml`, `ResourceUsage.qml`, `StorageUsage.qml`, `NetworkUsage.qml`, `PingService.qml`) and interactive status bar pill and popup inspector pairs (`CpuGpuPill` / `CpuGpuPopup`, `MemoryStoragePill` / `MemoryStoragePopup`, `NetworkPingPill` / `NetworkPingPopup`) were engineered and profiled in Phases 42–45.

Phase 46 executes four core objectives:
1. **Left-Zone Re-sequencing (`BarContent.qml`)**: Reorganize the top status bar's Left zone sequence per Decision **D-01**: `LeftSidebarButton` → `MemoryStoragePill` (Storage & Memory) → `CpuGpuPill` (CPU & GPU) → `NetworkPingPill` (Network & Ping) → `utilButtonsGroup` (wrapped in `BarGroup`). Spacing remains uniform at 4px (`spacing: 4`) with zero vertical dividers between pills (**D-04**).
2. **Storage-First Metric & Column Reordering**:
   - In `MemoryStoragePill.qml`, swap internal metric display: Root Storage (`/` usage and capacity) is displayed on the left, followed by Memory (RAM) on the right (**D-02**). The visual separation margin (`Layout.leftMargin: root.vertical ? 0 : 6`) is transferred from Storage to RAM.
   - In `MemoryStoragePopup.qml`, swap the two 320px inspector columns to match the pill: Left column presents Storage (live throughput rates, physical partitions, Google Drive cloud mounts), while Right column presents Memory (RAM allocation stacked bar, breakdown tiers, swap) (**D-03**).
3. **Legacy Component Retirement & Symlink Cleanup**:
   - Permanently remove deprecated monolithic resource widgets `Resources.qml` and `Resource.qml` from `restow/quickshell/.config/quickshell/ii/modules/ii/bar/` (**D-08**).
   - Remove live symlinks in `$HOME/.config/quickshell/ii/modules/ii/bar/Resource*.qml` and restore upstream `.bak` files so upstream files return to pristine stubs, avoiding dangling symlink failures in `./arch/dots-hyprland.sh verify --strict` (**D-09**).
4. **Milestone v0.9 Consolidated Test Harness (`scripts/phase46-telemetry-assert.sh`)**:
   - Author a 6-section consolidated assertion suite modeled on the proven Milestone v0.8 pattern (`scripts/phase41-interactions-assert.sh`) (**D-10**, **D-11**).
   - Orchestrate milestone sub-harnesses (`phase42`, `phase43.6`, `phase43-perf-assert.sh --quick`, `phase44`, `phase45`) and `./arch/dots-hyprland.sh verify --strict`, asserting fail-closed zero failure (`FAIL=0 FINDINGS=0`) and zero working tree drift.

All code modifications are strictly mapped to existing codebase analogs with line references, property bindings, and AST check formulas.

---

## 2. File Inventory & Classification

| File Path | Role | Data Flow | Closest Codebase Analog |
| :--- | :--- | :--- | :--- |
| `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml` | UI Layout Container / Coordinator | Top-level bar Flex `RowLayout`; distributes `useShortenedForm` to pills; coordinates Left zone pill sequence | Existing `BarContent.qml` [BarContent.qml:92-136](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml#L92-L136) |
| `restow/quickshell/.config/quickshell/ii/modules/ii/bar/MemoryStoragePill.qml` | Status Bar UI Pill Component | Consumes `StorageUsage.rootDisk` & `ResourceUsage.memory*`; renders dual circular progress rings and capacity text readouts | Existing `MemoryStoragePill.qml` [MemoryStoragePill.qml:46-202](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/ii/bar/MemoryStoragePill.qml#L46-L202) & `CpuGpuPill.qml` [CpuGpuPill.qml:1-120](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPill.qml#L1-L120) |
| `restow/quickshell/.config/quickshell/ii/modules/ii/bar/MemoryStoragePopup.qml` | Telemetry Inspector Popup Overlay | Demand-gated active lifecycle with `ResourceUsage` & `StorageUsage`; presents balanced dual 320px column layout | Existing `MemoryStoragePopup.qml` [MemoryStoragePopup.qml:173-424](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/ii/bar/MemoryStoragePopup.qml#L173-L424) & `CpuGpuPopup.qml` [CpuGpuPopup.qml:1-338](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPopup.qml#L1-L338) |
| `restow/quickshell/.config/quickshell/ii/modules/ii/bar/Resource.qml`<br>`restow/quickshell/.config/quickshell/ii/modules/ii/bar/Resources.qml` | Deprecated Legacy UI Components | Obsolete monolithic resource meters; slated for complete removal from git repository and live symlink farm | Legacy component retirement pattern in Phase 16 [phase16-retire-assert.sh:1-120](file:///home/pera/github_repo/.dotfiles/scripts/phase16-retire-assert.sh#L1-L120) & Phase 43.3 |
| `scripts/phase46-telemetry-assert.sh` | Quality Assertion Engine / Test Suite | CLI test harness validating AST ordering, sensor liveness, responsive geometry invariants, sub-harness orchestration, and strict repo integrity | `scripts/phase41-interactions-assert.sh` [phase41-interactions-assert.sh:1-909](file:///home/pera/github_repo/.dotfiles/scripts/phase41-interactions-assert.sh#L1-L909) |

---

## 3. Per-File Pattern Assignments

### 3.1 `BarContent.qml` (Left-Zone Layout Integration)

- **Target File:** `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml`
- **Role:** Master top status bar container orchestrating the Left, Middle, and Right visual zones.
- **Data Flow:**
  - Receives `root.useShortenedForm` from the bar parent.
  - Passes `useShortenedForm: root.useShortenedForm` to all 3 telemetry pills (`MemoryStoragePill`, `CpuGpuPill`, `NetworkPingPill`).
  - Evaluates `visible: (Config.options.bar.verbose && root.useShortenedForm === 0)` for `utilButtonsGroup`.
- **Closest Analog:**
  - `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml` lines 92–136 (`leftSectionRowLayout`).

#### Architectural Blueprint & Layout Sequence (D-01, D-04, D-05)

The Left zone container is an expanding `RowLayout` (`id: leftSectionRowLayout`) with `spacing: 4`.
To satisfy Decision **D-01**, `MemoryStoragePill` is positioned before `CpuGpuPill`:
1. `LeftSidebarButton` (Leftmost, with `Layout.leftMargin: Appearance.rounding.screenRounding`)
2. `MemoryStoragePill` (`id: memoryStoragePill`, `useShortenedForm: root.useShortenedForm`)
3. `CpuGpuPill` (`id: cpuGpuPill`, `useShortenedForm: root.useShortenedForm`)
4. `NetworkPingPill` (`id: networkPingPill`, `useShortenedForm: root.useShortenedForm`)
5. `BarGroup { id: utilButtonsGroup }` (`visible: (Config.options.bar.verbose && root.useShortenedForm === 0)`)
6. `Item { Layout.fillWidth: true; Layout.fillHeight: true }` (Trailing elastic spacer)

#### Concrete Code Excerpt to Implement

```qml
// restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml:92-136
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

#### Guardrails & Anti-Patterns
- **DO NOT** add artificial divider lines or rectangles between pills in `leftSectionRowLayout` (violates **D-04**).
- **DO NOT** remove `useShortenedForm: root.useShortenedForm` bindings; responsive telemetry compaction relies on this property.
- **DO NOT** alter the trailing `Item { Layout.fillWidth: true; Layout.fillHeight: true }`; it absorbs remaining width up to `middleSection.left`.

---

### 3.2 `MemoryStoragePill.qml` (Storage-First Metric Swapping)

- **Target File:** `restow/quickshell/.config/quickshell/ii/modules/ii/bar/MemoryStoragePill.qml`
- **Role:** Dual-metric status bar pill component displaying Root Storage and Memory usage.
- **Data Flow:**
  - Consumes `StorageUsage.rootDisk` (`availKb`, `totalKb`, `usePercent`) and `ResourceUsage` (`memoryUsedPercentage`, `memoryAvailable`, `memoryFree`, `memoryTotal`).
  - Exports `readonly property alias hoverArea: inertMouseArea` to anchor `MemoryStoragePopup`.
- **Closest Analogs:**
  - `restow/quickshell/.config/quickshell/ii/modules/ii/bar/MemoryStoragePill.qml` lines 46–201 [MemoryStoragePill.qml:46-201](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/ii/bar/MemoryStoragePill.qml#L46-L201).
  - `restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPill.qml` lines 1–120 [CpuGpuPill.qml:1-120](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPill.qml#L1-L120).

#### Architectural Blueprint & Swapping Pattern (D-02)

To satisfy Decision **D-02**, the visual metric sequence is inverted:
1. **Storage Cluster (Left):**
   - `storageCircProg` (ClippedFilledCircularProgress) wrapping `storageIcon` (MaterialSymbol `"storage"`).
   - `storageText` (StyledText displaying `rootAvailGb / rootTotalGb GB`).
   - Remove `Layout.leftMargin` from `storageCircProg` so Storage sits flush with standard pill padding.
2. **RAM Cluster (Right):**
   - `ramCircProg` (ClippedFilledCircularProgress) wrapping `ramIcon` (MaterialSymbol `"memory"`).
   - **Crucial Spacing Transfer (Pitfall 2):** Add `Layout.leftMargin: root.vertical ? 0 : 6` to `ramCircProg` to maintain visual separation between the Storage cluster and the RAM cluster.
   - `ramText` (StyledText displaying `freeGb / totalGb GB`).
3. Retain all property declarations, alert colors (`warningColor`, `root.storageColor`, `root.ramColor`), and breathing animations (`storagePulseAnimation`, `ramPulseAnimation`).

#### Concrete Code Excerpt to Implement

```qml
// restow/quickshell/.config/quickshell/ii/modules/ii/bar/MemoryStoragePill.qml:46-202

    // --- Storage Section (Circular progress indicator + storage icon) (D-02) ---
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

    // --- RAM Section (Circular progress indicator + MaterialSymbol) (D-02) ---
    ClippedFilledCircularProgress {
        id: ramCircProg
        Layout.alignment: Qt.AlignVCenter
        Layout.leftMargin: root.vertical ? 0 : 6 // Visual cluster separation transferred to RAM per D-02
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

#### Guardrails & Anti-Patterns
- **DO NOT** leave `Layout.leftMargin: root.vertical ? 0 : 6` on `storageCircProg`. If retained, Storage will be indented 6px from the pill's left edge, leaving RAM flush against Storage.
- **DO NOT** hide RAM or Storage elements on `useShortenedForm > 0`; both metrics must remain visible unconditionally across screen widths (**D-06**).

---

### 3.3 `MemoryStoragePopup.qml` (Storage-First Column Swapping)

- **Target File:** `restow/quickshell/.config/quickshell/ii/modules/ii/bar/MemoryStoragePopup.qml`
- **Role:** Two-column inspector overlay showing detailed multi-mount storage and memory breakdown.
- **Data Flow:**
  - Demand-gated active lifecycle with `ResourceUsage.isInspectorActive = active` and `StorageUsage.refresh()`.
  - Left column binds to `StorageUsage` (`readBytesPerSec`, `writeBytesPerSec`, `physicalDisks`, `cloudDisks`).
  - Right column binds to `ResourceUsage` (`memoryUsed`, `memoryAvailable`, `memoryFree`, `memoryBuffers`, `memoryCached`, `swapUsed`, `swapTotal`).
- **Closest Analogs:**
  - `restow/quickshell/.config/quickshell/ii/modules/ii/bar/MemoryStoragePopup.qml` lines 170–424 [MemoryStoragePopup.qml:170-424](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/ii/bar/MemoryStoragePopup.qml#L170-L424).
  - `restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPopup.qml` lines 105–338 [CpuGpuPopup.qml:105-338](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPopup.qml#L105-L338).

#### Architectural Blueprint & Swapping Pattern (D-03)

In `popupContent` (`RowLayout { anchors.centerIn: parent; spacing: 16 }`):
1. **Left Column (320px): Storage Card (D-03)**
   - Header row with `icon: "storage"` and live I/O throughput rate badge (`arrow_downward` + read, `arrow_upward` + write).
   - "Physical Drives" section with `Repeater { model: StorageUsage.physicalDisks; delegate: StorageDriveRow {} }`.
   - "Cloud Mounts (Google Drive)" section dynamically gated by `visible: StorageUsage.cloudDisks && StorageUsage.cloudDisks.length > 0`.
   - Trailing vertical spacer `Item { Layout.fillHeight: true }`.
2. **Center Separator:**
   - `Rectangle { Layout.fillHeight: true; implicitWidth: 1; color: Appearance.colors.colLayer0Border }`.
3. **Right Column (320px): Memory Card (D-03)**
   - Header row with `icon: "memory"`, label `"Memory"`.
   - RAM Allocation stacked bar (`allocBarContainer`, `subSegUsed`, `subSegBuff`) and Legend (`Used`, `Buff/Cache`, `Available`).
   - Numeric memory tier breakdown rows (`Used`, `Available`, `Buffers`, `Cached`, `Free`).
   - Dynamic Swap row gated by `visible: ResourceUsage.swapTotal > 0`.
   - Trailing vertical spacer `Item { Layout.fillHeight: true }`.

#### Concrete Code Excerpt to Implement

```qml
// restow/quickshell/.config/quickshell/ii/modules/ii/bar/MemoryStoragePopup.qml:170-425

    RowLayout {
        id: popupContent
        anchors.centerIn: parent
        spacing: 16

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

                    MaterialSymbol {
                        text: "arrow_downward"
                        iconSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }

                    StyledText {
                        text: root.formatThroughput(StorageUsage.readBytesPerSec)
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }

                    MaterialSymbol {
                        text: "arrow_upward"
                        iconSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }

                    StyledText {
                        text: root.formatThroughput(StorageUsage.writeBytesPerSec)
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }
                }
            }

            // Sub-section: Physical Drives (D-10)
            StyledText {
                text: "Physical Drives"
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.weight: Font.Medium
                color: Appearance.colors.colOnSurfaceVariant
            }

            Repeater {
                model: StorageUsage.physicalDisks
                delegate: StorageDriveRow {}
            }

            // Sub-section: Cloud Mounts (Google Drive) (D-10, D-11)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                visible: StorageUsage.cloudDisks && StorageUsage.cloudDisks.length > 0

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: Appearance.colors.colLayer0Border
                }

                StyledText {
                    text: "Cloud Mounts (Google Drive)"
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnSurfaceVariant
                }

                Repeater {
                    model: StorageUsage.cloudDisks
                    delegate: StorageDriveRow {}
                }
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

            // Header
            StyledPopupHeaderRow {
                icon: "memory"
                label: "Memory"
            }

            // Multi-Segment Stacked Allocation Bar (D-05)
            RowLayout {
                Layout.fillWidth: true
                StyledText {
                    text: "RAM Allocation"
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colOnSurfaceVariant
                }
                Item { Layout.fillWidth: true }
                StyledText {
                    text: `${root.formatKB(ResourceUsage.memoryUsed)} / ${root.formatKB(ResourceUsage.memoryTotal)} (${Math.round((ResourceUsage.memoryUsedPercentage || 0.0) * 100)}%)`
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    font.weight: Font.DemiBold
                    color: root.getLoadColor(ResourceUsage.memoryUsedPercentage || 0.0)
                    opacity: (ResourceUsage.memoryUsedPercentage || 0.0) >= 0.90 ? root.criticalPulseOpacity : 1.0
                }
            }

            Rectangle {
                id: allocBarContainer
                Layout.fillWidth: true
                implicitHeight: 8
                radius: 4
                clip: true
                color: Appearance.m3colors.m3surfaceContainerHigh

                Rectangle {
                    id: subSegUsed
                    height: parent.height
                    width: parent.width * Math.max(0.0, Math.min(1.0, (ResourceUsage.memoryUsed || 0.0) / (ResourceUsage.memoryTotal || 1.0)))
                    color: root.getLoadColor(ResourceUsage.memoryUsedPercentage || 0.0)
                    radius: 4
                }

                Rectangle {
                    id: subSegBuff
                    x: subSegUsed.width
                    height: parent.height
                    width: parent.width * Math.max(0.0, Math.min(1.0, Math.max(0, (ResourceUsage.memoryAvailable || 0.0) - (ResourceUsage.memoryFree || 0.0)) / (ResourceUsage.memoryTotal || 1.0)))
                    color: Appearance.colors.colSecondary !== undefined ? Appearance.colors.colSecondary : Appearance.colors.colPrimary
                    opacity: 0.6
                    radius: 4
                }
            }

            // Legend Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                RowLayout {
                    spacing: 4
                    Rectangle {
                        implicitWidth: 6
                        implicitHeight: 6
                        radius: 3
                        color: root.getLoadColor(ResourceUsage.memoryUsedPercentage || 0.0)
                    }
                    StyledText {
                        text: "Used"
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }
                }

                RowLayout {
                    spacing: 4
                    Rectangle {
                        implicitWidth: 6
                        implicitHeight: 6
                        radius: 3
                        color: Appearance.colors.colSecondary !== undefined ? Appearance.colors.colSecondary : Appearance.colors.colPrimary
                        opacity: 0.6
                    }
                    StyledText {
                        text: "Buff/Cache"
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }
                }

                Item { Layout.fillWidth: true }

                RowLayout {
                    spacing: 4
                    Rectangle {
                        implicitWidth: 6
                        implicitHeight: 6
                        radius: 3
                        color: Appearance.colors.colLayer0Border
                    }
                    StyledText {
                        text: "Available"
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }
                }
            }

            // Numeric Breakdown Tier Rows (D-06)
            StyledPopupValueRow {
                label: "Used"
                value: root.formatKB(ResourceUsage.memoryUsed)
                valueColor: root.getLoadColor(ResourceUsage.memoryUsedPercentage || 0.0)
                isAlert: (ResourceUsage.memoryUsedPercentage || 0.0) >= 0.70
            }

            StyledPopupValueRow {
                label: "Available"
                value: root.formatKB(ResourceUsage.memoryAvailable)
            }

            StyledPopupValueRow {
                label: "Buffers"
                value: root.formatKB(ResourceUsage.memoryBuffers)
            }

            StyledPopupValueRow {
                label: "Cached"
                value: root.formatKB(ResourceUsage.memoryCached)
            }

            StyledPopupValueRow {
                label: "Free"
                value: root.formatKB(ResourceUsage.memoryFree)
            }

            // Dynamic Swap Row (D-07)
            StyledPopupValueRow {
                visible: ResourceUsage.swapTotal > 0
                label: "Swap"
                value: `${root.formatKB(ResourceUsage.swapUsed)} / ${root.formatKB(ResourceUsage.swapTotal)} (${Math.round((ResourceUsage.swapUsedPercentage || 0.0) * 100)}%)`
                valueColor: root.getLoadColor(ResourceUsage.swapUsedPercentage || 0.0)
                isAlert: (ResourceUsage.swapUsedPercentage || 0.0) >= 0.70
            }

            Item { Layout.fillHeight: true }
        }
    }
```

#### Guardrails & Anti-Patterns
- **DO NOT** change `Layout.preferredWidth: 320` on either column; the dual 320px column layout is a contract tested in `phase44-memory-storage-assert.sh`.
- **DO NOT** omit `Item { Layout.fillHeight: true }` at the base of either column; doing so creates vertical alignment jitter when drive lists or swap rows change height.

---

### 3.4 Legacy Resources Retirement & Symlink Cleanup Architecture (D-08, D-09)

- **Target Files to Remove:**
  - Repo files:
    - `restow/quickshell/.config/quickshell/ii/modules/ii/bar/Resource.qml`
    - `restow/quickshell/.config/quickshell/ii/modules/ii/bar/Resources.qml`
  - Live symlinks in `$HOME/.config/quickshell/ii/modules/ii/bar/`:
    - `Resource.qml`
    - `Resources.qml`
  - Upstream backup restores:
    - `Resource.qml.bak` -> `Resource.qml`
    - `Resources.qml.bak` -> `Resources.qml`

#### Safe Retirement Pattern

When repo files are removed, if the symlinks pointing to them in `$HOME/.config/...` remain, they become dangling symlinks into the repository. `./arch/dots-hyprland.sh verify --strict` detects this under Arm 3 (`fail "dangling symlink into repo: $entry -> $dangling_raw_target"`) and fails immediately.

To prevent this:
```bash
# 1. Remove tracked repo files
git rm "restow/quickshell/.config/quickshell/ii/modules/ii/bar/Resource.qml"
git rm "restow/quickshell/.config/quickshell/ii/modules/ii/bar/Resources.qml"

# 2. Clean up live symlinks
rm -f "$HOME/.config/quickshell/ii/modules/ii/bar/Resource.qml"
rm -f "$HOME/.config/quickshell/ii/modules/ii/bar/Resources.qml"

# 3. Restore upstream backup files if present
if [[ -f "$HOME/.config/quickshell/ii/modules/ii/bar/Resource.qml.bak" ]]; then
    mv "$HOME/.config/quickshell/ii/modules/ii/bar/Resource.qml.bak" "$HOME/.config/quickshell/ii/modules/ii/bar/Resource.qml"
fi
if [[ -f "$HOME/.config/quickshell/ii/modules/ii/bar/Resources.qml.bak" ]]; then
    mv "$HOME/.config/quickshell/ii/modules/ii/bar/Resources.qml.bak" "$HOME/.config/quickshell/ii/modules/ii/bar/Resources.qml"
fi
```

#### Why Upstream Stubs Pass Verification (Arm 7 Exemption)
In `arch/dots-hyprland.sh:1363-1370`, regular files in managed directories that are not symlinks into the repo are classified as `unclaimed upstream stub` under Arm 7:
```bash
info "unclaimed upstream stub: $entry"
return 0
```
This logs `[INFO]` and does NOT increment `FAIL` or `FINDINGS`.

---

### 3.5 Consolidated Milestone Test Suite (`scripts/phase46-telemetry-assert.sh`)

- **Target File:** `scripts/phase46-telemetry-assert.sh`
- **Role:** Milestone v0.9 automated regression test harness and repository integrity gate.
- **Data Flow:**
  - Evaluates CLI arguments (`-s, --section`, `-q, --quick`, `-c, --syntax`, `-h, --help`).
  - Verifies prerequisite binaries (`bash`, `jq`, `curl`, `stow`, `git`, `python3`).
  - Records git porcelain snapshot before execution; asserts identical porcelain after execution.
  - Traps temporary files on `EXIT INT TERM`.
  - Executes 6 orchestrated sections and exits with code 0 only if `FAIL=0 FINDINGS=0`.
- **Closest Analog:**
  - `scripts/phase41-interactions-assert.sh` lines 1–909 [phase41-interactions-assert.sh:1-909](file:///home/pera/github_repo/.dotfiles/scripts/phase41-interactions-assert.sh#L1-L909).

#### Architectural Blueprint & Section Breakdown (D-10, D-11)

```
┌────────────────────────────────────────────────────────────────────────┐
│              scripts/phase46-telemetry-assert.sh                       │
├────────────────────────────────────────────────────────────────────────┤
│ Section 1: Stow Leaf Symlink Topology & Packaging Integrity            │
│            (INTG-02, D-08, D-09)                                       │
│   - Verifies 0 directory folding under restow/quickshell/              │
│   - Confirms live symlinks for all 3 pills and popups                  │
│   - Asserts absence of legacy Resource(s).qml symlinks in live tree    │
│   - Verifies vendor/dots-hyprland submodule has 0 uncommitted diffs    │
├────────────────────────────────────────────────────────────────────────┤
│ Section 2: BarContent.qml Left Zone Layout AST & Sequence Verification  │
│            (INTG-01, D-01, D-04, D-05)                                 │
│   - Numerical line monotonicity check:                                 │
│     LeftSidebarButton < MemoryStoragePill < CpuGpuPill <               │
│     NetworkPingPill < utilButtonsGroup                                 │
│   - Inter-pill spacing: 4 with zero dividers                          │
│   - utilButtonsGroup visibility gating check                           │
├────────────────────────────────────────────────────────────────────────┤
│ Section 3: Component Internal Ordering & AST Verification              │
│            (D-02, D-03)                                                │
│   - MemoryStoragePill: pos(storageCircProg) < pos(ramCircProg)         │
│   - MemoryStoragePill: Layout.leftMargin assigned to ramCircProg       │
│   - MemoryStoragePopup: pos(storageHeader) < pos(memoryHeader)         │
│   - MemoryStoragePopup: dual 320px column layout preserved             │
├────────────────────────────────────────────────────────────────────────┤
│ Section 4: Telemetry Service Sensors & Ping Daemon Bridge Liveness      │
│            (INTG-03, D-10)                                             │
│   - Procfs / sysfs readability (/proc/stat, /proc/meminfo,             │
│     /proc/net/dev, /sys/class/hwmon)                                   │
│   - Ping daemon loopback query: http://127.0.0.1:8765/api/status       │
│   - Multi-mount filesystem discovery check                             │
├────────────────────────────────────────────────────────────────────────┤
│ Section 5: Responsive Layout & Workspace Centering Invariants          │
│            (D-06, D-07)                                                │
│   - middleSection / middleCenterGroup anchors.horizontalCenter check   │
│   - useShortenedForm property bindings on all 3 pills                  │
│   - Headless geometric simulation of center preservation               │
├────────────────────────────────────────────────────────────────────────┤
│ Section 6: Sub-Harness Orchestration & Strict Repository Verification  │
│            (INTG-02, INTG-03, D-10)                                    │
│   - Sub-harness: phase42-telemetry-services-assert.sh                  │
│   - Sub-harness: phase43.6-streamline-assert.sh                        │
│   - Sub-harness: phase43-perf-assert.sh --quick                        │
│   - Sub-harness: phase44-memory-storage-assert.sh                      │
│   - Sub-harness: phase45-network-ping-assert.sh                        │
│   - Strict repo gate: ./arch/dots-hyprland.sh verify --strict          │
└────────────────────────────────────────────────────────────────────────┘
```

#### Concrete Code Patterns for AST Assertions

```bash
# Robust numerical monotonicity AST check pattern for Section 2
pos_sidebar=$(grep -n "LeftSidebarButton" "$BAR_CONTENT" | head -n1 | cut -d: -f1)
pos_memdsk=$(grep -n "MemoryStoragePill" "$BAR_CONTENT" | head -n1 | cut -d: -f1)
pos_cpugpu=$(grep -n "CpuGpuPill" "$BAR_CONTENT" | head -n1 | cut -d: -f1)
pos_netping=$(grep -n "NetworkPingPill" "$BAR_CONTENT" | head -n1 | cut -d: -f1)
pos_util=$(grep -n "utilButtonsGroup" "$BAR_CONTENT" | head -n1 | cut -d: -f1)

if [[ -n "$pos_sidebar" && -n "$pos_memdsk" && -n "$pos_cpugpu" && -n "$pos_netping" && -n "$pos_util" ]]; then
  if (( pos_sidebar < pos_memdsk && pos_memdsk < pos_cpugpu && pos_cpugpu < pos_netping && pos_netping < pos_util )); then
    pass "S2: Left zone sequence verified (LeftSidebarButton -> MemoryStoragePill -> CpuGpuPill -> NetworkPingPill -> utilButtonsGroup)"
  else
    fail "S2: Left zone sequence violation: sidebar=$pos_sidebar memdsk=$pos_memdsk cpugpu=$pos_cpugpu netping=$pos_netping util=$pos_util"
  fi
else
  fail "S2: One or more Left zone components missing from BarContent.qml"
fi
```

```bash
# Storage-first AST check in MemoryStoragePill for Section 3
pos_storage_circ=$(grep -n "id: storageCircProg" "$PILL_QML" | head -n1 | cut -d: -f1)
pos_ram_circ=$(grep -n "id: ramCircProg" "$PILL_QML" | head -n1 | cut -d: -f1)

if [[ -n "$pos_storage_circ" && -n "$pos_ram_circ" ]]; then
  if (( pos_storage_circ < pos_ram_circ )); then
    pass "S3: MemoryStoragePill metric sequence is Storage-first (storageCircProg at line $pos_storage_circ < ramCircProg at line $pos_ram_circ)"
  else
    fail "S3: MemoryStoragePill metric sequence is not Storage-first (storageCircProg at line $pos_storage_circ >= ramCircProg at line $pos_ram_circ)"
  fi
else
  fail "S3: storageCircProg or ramCircProg missing from MemoryStoragePill.qml"
fi
```

```bash
# Sub-harness delegation in Section 6 (D-10)
SUB_HARNESSES=(
  "scripts/phase42-telemetry-services-assert.sh"
  "scripts/phase43.6-streamline-assert.sh"
  "scripts/phase43-perf-assert.sh --quick"
  "scripts/phase44-memory-storage-assert.sh"
  "scripts/phase45-network-ping-assert.sh"
)

for sub_cmd in "${SUB_HARNESSES[@]}"; do
  sub_script="${sub_cmd%% *}"
  sub_args="${sub_cmd#* }"
  [[ "$sub_args" == "$sub_script" ]] && sub_args=""

  if [[ -x "$REPO_ROOT/$sub_script" ]]; then
    if "$REPO_ROOT/$sub_script" $sub_args >/dev/null 2>&1; then
      pass "S6: Sub-harness $sub_cmd passed cleanly"
    else
      fail "S6: Sub-harness $sub_cmd encountered failures"
    fi
  else
    fail "S6: Sub-harness $sub_script is missing or not executable"
  fi
done
```

---

## 4. Workspaces Centering & Responsive Invariants

### 4.1 Dead-Center Mathematical Guarantee (D-07)

In `BarContent.qml`:
- Line 163: `middleCenterGroup` specifies `anchors.horizontalCenter: parent.horizontalCenter`.
- Line 140: `middleSection` wraps `middleCenterGroup`, `weatherGroup` (to the left of center), and `rightCenterGroup` (to the right of center).
- The Left zone's `leftSectionRowLayout` terminates in `Item { Layout.fillWidth: true; Layout.fillHeight: true }`, which expands to fill the distance between the last pill and `middleSection.left`.
- Therefore, the horizontal center of `middleCenterGroup` is locked to $\text{ScreenWidth} / 2$, completely decoupled from Left zone and Right zone content widths.

### 4.2 Responsive Adaptation Matrix across Screen Widths (D-06)

| Width Threshold | `useShortenedForm` | Left Zone Adaptation | Middle Zone Adaptation | Right Zone Adaptation | Workspaces Centering |
| :--- | :--- | :--- | :--- | :--- | :--- |
| $> 1200\text{px}$ | `0` | All 3 pills visible.<br>`utilButtonsGroup` visible if verbose.<br>`CpuGpuPill` shows temp text. | Full weather bar & full workspaces widget. | Media widget active.<br>Full tray & control buttons. | Dead-center |
| $\le 1200\text{px}$ | `1` | All 3 pills visible.<br>`utilButtonsGroup` automatically hides.<br>`CpuGpuPill` hides temp text. | Weather bar contracts to short form. | Media widget active.<br>Compact tray items. | Dead-center |
| $\le 900\text{px}$ | `2` | All 3 pills visible.<br>`utilButtonsGroup` hidden. | Center side modules contract to minimal width. | Media widget hides (`useShortenedForm < 2`). | Dead-center |

---

## 5. Security Domain (ASVS L1 Compliance)

| ASVS Control | Security Threat / Requirement | Architectural Mitigation in Phase 46 |
| :--- | :--- | :--- |
| **V14.2 Dependency and Resource Integrity** | Symlink hijacking, path traversal, or folded ancestor injection | All shell overlays are packaged strictly as leaf symlinks under `restow/quickshell/`. Non-leaf directories are physical directories without folding. Confirmed via `./arch/dots-hyprland.sh verify --strict`. |
| **V12.1 Command Execution** | Argument injection via shell interpolation | No shell interpolation in QML. Subprocess calls use argument arrays (`Quickshell.execDetached(["xdg-open", ...])`). In test harness, paths are quoted and sanitized. |
| **V13.1 API and Web Service Security** | Exposure of telemetry data or untrusted inputs | Local ping monitor daemon bridge binds exclusively to `127.0.0.1:8765/api/status`. No external interfaces or unauthenticated modification endpoints. |
| **V14.1 Third-Party Software and Architecture** | Stale code, dead attack surface, and shadowing | Complete removal of legacy `Resources.qml` and `Resource.qml` eliminates unmanaged components and removes risk of live symlink dangling. |

---

## 6. Planning & Execution Roadmap

Phase 46 execution decomposes into two sequential, deterministic plans:

### Plan 46-01: BarContent Left Zone Integration, Storage-First Swaps & Legacy Retirement
1. **Edit `BarContent.qml`:** Swap `CpuGpuPill` and `MemoryStoragePill` in `leftSectionRowLayout` to establish `LeftSidebarButton` → `MemoryStoragePill` → `CpuGpuPill` → `NetworkPingPill` → `utilButtonsGroup` (**D-01**).
2. **Edit `MemoryStoragePill.qml`:** Swap internal Storage and RAM metric sections; transfer 6px visual separation margin to `ramCircProg` (**D-02**).
3. **Edit `MemoryStoragePopup.qml`:** Swap inspector columns around the center divider: Left column = Storage, Right column = Memory (**D-03**).
4. **Retire Legacy Components:** Remove `Resources.qml` and `Resource.qml` from repo (`git rm`), remove live symlinks, and restore upstream `.bak` files (**D-08**, **D-09**).
5. **Verify:** Run `./arch/dots-hyprland.sh verify --strict` to verify clean stow leaf topology and zero dangling symlinks.

### Plan 46-02: Milestone v0.9 Consolidated Test Harness & Final Verification
1. **Author `scripts/phase46-telemetry-assert.sh`:** Implement 6-section test suite following the `phase41-interactions-assert.sh` pattern (**D-10**, **D-11**).
2. **Validate Test Suite:** Run with `-c, --syntax`, `-s, --section <1-6>`, `-q, --quick`, and full execution.
3. **Run Full Sub-Harness Verification:** Run all sub-harnesses (`phase42`, `phase43.6`, `phase43-perf --quick`, `phase44`, `phase45`) and `./arch/dots-hyprland.sh verify --strict`.
4. **Assert Zero Churn:** Verify `vendor/dots-hyprland` submodule is 100% clean and working tree has zero drift.
