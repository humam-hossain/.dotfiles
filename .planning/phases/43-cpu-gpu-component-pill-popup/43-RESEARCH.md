# Phase 43: CPU & GPU Component (Pill & Popup) - Research

**Researched:** 2026-09-26  
**Domain:** Quickshell QML desktop shell components, top bar status pills, interactive overlay inspector popups, hardware telemetry integration, and Material You / Material 3 styling.  
**Confidence Level:** HIGH [VERIFIED: live sysfs/procfs probes, existing Quickshell components, BarGroup/VoicePill/StyledPopup codebase inspection, and Quickshell 0.2.1 runtime].

---

<user_constraints>
## User Constraints (verbatim from CONTEXT.md)

### Phase Boundary

Build dedicated `CpuGpuPill.qml` status bar pill and interactive `CpuGpuPopup.qml` inspector overlay in Quickshell (`restow/quickshell/.config/quickshell/ii/modules/ii/bar/`):

1. **Status Bar Pill (`CpuGpuPill.qml`):**
   - Displays live CPU load %, CPU Package Temp (°C), and Intel UHD 770 iGPU load % with distinct Material Symbols icons (`planner_review`, `speed`).
   - Adapts to narrow screens / `useShortenedForm` by dropping temperature while preserving both CPU and GPU load percentages.
   - Smooth 250ms M3 `emphasizedDecel` width resizing animation via `BarGroup.qml`.
   - Independent two-tier alert coloring (Amber warning at 70% load or 75°C, Red critical at 90% load or 85°C) across icons and text badges with a subtle breathing pulse during critical Red state.
   - Strictly hover-activated (`StyledPopup`), clicks are inert.

2. **Inspector Overlay (`CpuGpuPopup.qml`):**
   - Dual-column layout with right-side vertical split:
     - **Left Column (CPU):** Overall CPU load %, Package temperature, segregated P-Core (12T) and E-Core (8T) progress bars with active frequencies (MHz), and CPU scaling governor.
     - **Right Column Top (GPU):** Intel UHD 770 iGPU load progress bar (RC6 delta), active render clock (MHz), and thermal throttle status badge.
     - **Right Column Bottom (Motherboard Platform):** Gigabyte B760 VRM/PCH temperature probe and Energy Performance Preference (EPP).
   - Seamless cursor tracking across pill and popup bounds, centered directly beneath the pill with screen boundary clamping.

**Out of scope:**
- Storage & NVMe drive thermals — Phase 44 (`MemoryStoragePill.qml` & `MemoryStoragePopup.qml`) owns storage mounts and NVMe 1 & 2 thermals.
- Network & Ethernet transceiver telemetry — Phase 45 (`NetworkPingPill.qml` & `NetworkPingPopup.qml`) owns network rates, ping daemon bridging, and Realtek PHY temp.
- Top bar left-zone integration and layout rearrangement in `BarContent.qml` — Phase 46 owns final placement alongside `LeftSidebarButton`.
- CPU/GPU power wattage readouts — Phase 42 (D-05) locked omission to maintain 100% unprivileged execution without root or udev dependencies.

### Implementation Decisions

#### Pill Layout & Metrics Density (`CpuGpuPill.qml`)
- **D-01 (Visible Metrics):** Pill displays CPU % + Package Temp + GPU % — e.g. `[planner_review] 14% 42°C  [speed] 5%`. — **Reversibility:** reversible.
- **D-02 (Section Separation & Iconography):** Distinct Material Symbols icons (`planner_review` for CPU, `speed` for GPU) matching the current bar icon styling and size (`Appearance.font.pixelSize.normal`) visually anchor and separate the CPU and GPU sections. — **Reversibility:** reversible.
- **D-03 (Shortened Form Adaptability):** When `useShortenedForm` is active on narrow screens, drop temperature only and preserve both CPU and GPU load percentages (`[planner_review] 14%  [speed] 5%`), preventing center workspaces from being shifted off-center. — **Reversibility:** reversible.
- **D-04 (Fluid M3 Width Resizing):** Numbers use natural standard formatting (e.g. `5%`, `14%`, `100%`) with `BarGroup.qml`'s 250ms Material 3 `emphasizedDecel` animation for smooth width transitions. — **Reversibility:** reversible.
- **D-05 (Telemetry Element Ordering):** Elements are strictly ordered with CPU first, then GPU: `[planner_review] <cpuLoad>% <packageTemp>°C  [speed] <gpuLoad>%`. — **Reversibility:** reversible.
- **D-06 (Single Thermal Metric):** Pill temperature strictly references CPU Package Temp (`packageTemp` from `hwmon5/temp1_input`). NVMe and Motherboard temperatures are kept out of the pill to avoid clutter. — **Reversibility:** reversible.
- **D-07 (Container Styling):** Inherit standard `BarGroup` container background (`Appearance.colors.colLayer1`) and borderless setting (`Config.options.bar.borderless`), maintaining 100% aesthetic harmony with Workspaces, Clock, and Voice pills. — **Reversibility:** reversible.
- **D-08 (Vertical Orientation Support):** In vertical bar mode (`Config.options.bar.vertical`), elements stack vertically in a clean Column: `[planner_review]`, CPU %, Temp, `[speed]`, GPU %. — **Reversibility:** reversible.

#### Alert Escalation & Pulse Animation
- **D-09 (Independent Color Escalation):** CPU cluster colors by CPU load, GPU cluster colors by GPU load, and Temperature colors by thermal degrees independently. — **Reversibility:** reversible.
- **D-10 (Two-Tier Thresholds):** Amber warning triggers at 70% load or 75°C; Red critical alert triggers at 90% load or 85°C. — **Reversibility:** reversible.
- **D-11 (Dynamic Material You Tokens):** Amber warning maps to `Appearance.colors.colTertiary` (harmonized dynamic gold/amber); Red critical maps to `Appearance.colors.colError` (dynamic M3 error red), with zero hardcoded hex colors. — **Reversibility:** reversible.
- **D-12 (Critical Breathing Pulse):** Under critical Red alert (≥90% load or ≥85°C), the active critical icon (`planner_review` or `speed`) executes a subtle breathing opacity animation (1.0 to 0.6 over 600ms) to draw peripheral awareness without visual clutter. — **Reversibility:** reversible.

#### Popup Inspector Layout & Core Breakdown (`CpuGpuPopup.qml`)
- **D-13 (Dual-Column Right-Split Architecture):** `CpuGpuPopup.qml` uses a balanced two-column layout with a vertical split on the right side:
  - **Left Column:** Full CPU Section (overall load %, P-core vs E-core metrics, active frequencies, governor, package temp).
  - **Right Column (Top):** Intel UHD 770 iGPU Section (load progress bar, active render clock in MHz, thermal throttling status tag).
  - **Right Column (Bottom):** Motherboard & Platform Telemetry (Gigabyte B760 VRM/PCH temperature, scaling governor, EPP). — **Reversibility:** reversible.
- **D-14 (Segregated P-Core & E-Core Breakdown):** On the host's 14-core / 20-thread Intel Core i5-13500, CPU metrics are rendered as two distinct progress bars: "P-Cores (12T)" (CPUs 0–11) and "E-Cores (8T)" (CPUs 12–19) alongside their respective active clock MHz. — **Reversibility:** reversible.
- **D-15 (GPU Metrics Presentation):** Intel UHD 770 iGPU metrics feature an active load progress bar, render clock speed (MHz), and a clean status badge ("Normal" or "Thermal Throttle"). — **Reversibility:** reversible.
- **D-16 (Domain-Specific Thermal Mapping):** System sensors are strictly assigned to their domain:
  - `coretemp-isa-0000` (CPU Package & P/E Cores) & `gigabyte_wmi-virtual-0` (Motherboard VRM) belong in Phase 43 (`CpuGpuPopup`).
  - `nvme-pci-0100` (PM9A1) and `nvme-pci-0200` (980) belong in Phase 44 (`MemoryStoragePopup`).
  - `r8169_0_400:00-mdio-0` (Ethernet PHY transceiver) belong in Phase 45 (`NetworkPingPopup`). — **Reversibility:** reversible.

#### Interaction & Tooling
- **D-17 (Strict Hover Trigger / Inert Clicks):** `CpuGpuPill` reveals `CpuGpuPopup` strictly on mouse hover via `StyledPopup`. Mouse clicks are completely inert to prevent click bleeding or unintended window actions. — **Reversibility:** reversible.
- **D-18 (Seamless Cursor Tracking):** Popup remains open while the mouse cursor is over either the pill or within the popup window itself, enabling inspection of meters without premature closing. — **Reversibility:** reversible.
- **D-19 (Popup Centering & Screen Clamping):** `CpuGpuPopup` centers directly underneath `CpuGpuPill`, with automatic horizontal screen boundary clamping to prevent off-screen overflow. — **Reversibility:** reversible.
- **D-20 (Entrance Transition):** 150ms Material 3 entrance crossfade with a subtle 4px downward slide using `Appearance.animationCurves.expressiveEffects`. — **Reversibility:** reversible.

### the agent's Discretion
- Exact spacing constants and margins between progress bars in `CpuGpuPopup.qml`.
- Internal helper bindings for mapping temperature values to formatted strings.

### Deferred Ideas
- **Phase 44 (Memory & Storage Component):**
  - Dedicated `MemoryStoragePill.qml` and `MemoryStoragePopup.qml`.
  - Integration of `nvme-pci-0100` (Samsung PM9A1 root) and `nvme-pci-0200` (Samsung 980) temperatures alongside disk usage bars.
- **Phase 45 (Network & Multi-Target Ping Component):**
  - Dedicated `NetworkPingPill.qml` and `NetworkPingPopup.qml`.
  - Integration of `r8169_0_400:00-mdio-0` (Realtek 2.5GbE PHY transceiver) temperature into the network inspector card.
- **Phase 46 (Left-Zone Bar Integration & Verification Harness):**
  - Replacing legacy `Resources.qml` in `BarContent.qml` Left zone with `CpuGpuPill`, `MemoryStoragePill`, and `NetworkPingPill`.
  - Comprehensive automated test script `scripts/phase46-telemetry-assert.sh`.
</user_constraints>

---

<phase_requirements>
## Phase Requirements & Implementation Mapping

| Requirement ID | Specification | Research Findings & Implementation Approach |
|----------------|---------------|---------------------------------------------|
| **CPUGPU-01** | Bar pill displays live CPU usage % and GPU usage % with Material Symbols icons (`planner_review`, `speed`) and 250ms M3 emphasized deceleration width resizing. | Implemented in `CpuGpuPill.qml` as a `BarGroup` component. Binds to `HardwareTelemetry.overallCpuLoad` and `HardwareTelemetry.gpuLoad`. Includes `HardwareTelemetry.packageTemp` (`D-01`), dropped conditionally when `useShortenedForm > 0` (`D-03`). Icon sizes use `Appearance.font.pixelSize.normal`. M3 250ms width resizing is inherited natively from `BarGroup.qml`'s `Behavior on implicitWidth` using `Appearance.animationCurves.emphasizedDecel`. |
| **CPUGPU-02** | CPU popup inspector displays overall load %, package temperature (°C via `/sys/class/hwmon/hwmon5/temp1_input`), power draw in Watts (RAPL `/sys/class/powercap/intel-rapl` with unprivileged fallback placeholder), and clock frequencies (MHz). | Implemented in Left Column of `CpuGpuPopup.qml`. Reads `HardwareTelemetry.overallCpuLoad`, `HardwareTelemetry.packageTemp`, `HardwareTelemetry.pCoreLoad`, `HardwareTelemetry.eCoreLoad`, `HardwareTelemetry.pCoreFrequencyMhz`, and `HardwareTelemetry.eCoreFrequencyMhz`. Power draw in Watts is rendered as a clean unprivileged fallback placeholder (`"N/A (unprivileged)"` or `"-- W"`) strictly conforming to Phase 42 D-05 locked decision (0400 root permission Platypus mitigation). |
| **CPUGPU-03** | GPU popup inspector displays Intel iGPU load % (via RC6 residency delta), average load, active clock frequency (MHz via `rps_act_freq_mhz`), and temperature. | Implemented in Right Column Top of `CpuGpuPopup.qml`. Binds to `HardwareTelemetry.gpuLoad`, `HardwareTelemetry.gpuClockMhz`, and `HardwareTelemetry.gpuThrottled` badge ("Normal" vs "Thermal Throttle"). On Alder Lake GT0, GPU shares the CPU package silicon thermal zone (`packageTemp`). |
| **CPUGPU-04** | Synchronized two-tier alert coloring (Amber warning at 70%, Red critical at 90%) across icons, text badges, and popup headers. | Implemented across both `CpuGpuPill.qml` and `CpuGpuPopup.qml`. Independent color escalation (`D-09`): CPU cluster evaluates `overallCpuLoad >= 0.9` (Critical) / `>= 0.7` (Warning); GPU cluster evaluates `gpuLoad >= 0.9` / `>= 0.7`; Thermals evaluate `packageTemp >= 85` / `>= 75`. Warning binds to `Appearance.colors.colTertiary`; Critical binds to `Appearance.colors.colError` (`D-11`, zero hardcoded hex colors). Breathing pulse animation (1.0 to 0.6 over 600ms) runs on the critical icon (`D-12`). |
</phase_requirements>

---

## Architectural Responsibility Map

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                                 Quickshell Shell UI                                    │
│                                                                                        │
│   ┌──────────────────────────────────────────────────┐                                 │
│   │ CpuGpuPill.qml (Top Bar Pill)                    │                                 │
│   │ - Inherits BarGroup (M3 width animation)         │                                 │
│   │ - Re-parented MouseArea (Inert clicks, D-17)     │                                 │
│   │ - Icons: [planner_review] [speed]                │                                 │
│   │ - Metrics: CPU % + Temp + GPU %                  │                                 │
│   │ - Responsive: drops Temp if useShortenedForm > 0 │                                 │
│   │ - Breathing pulse animation on critical red      │                                 │
│   └──────────────────────┬───────────────────────────┘                                 │
│                          │ hoverTarget (D-17)                                          │
│                          ▼                                                             │
│   ┌────────────────────────────────────────────────────────────────────────────────┐   │
│   │ StyledPopup.qml (Restow Overlay Base Container)                                │   │
│   │ - PanelWindow (WlrLayershell.layer: Overlay)                                   │   │
│   │ - Hover Bridge: Pill <-> Popup cursor tracking with debounce timer (D-18)      │   │
│   │ - Screen Clamping: Math.max(minX, Math.min(rawX, maxX)) (D-19)                 │   │
│   │ - Entrance Animation: 150ms M3 crossfade + 4px downward slide (D-20)           │   │
│   └──────────────────────┬─────────────────────────────────────────────────────────┘   │
│                          │ contentItem                                                 │
│                          ▼                                                             │
│   ┌────────────────────────────────────────────────────────────────────────────────┐   │
│   │ CpuGpuPopup.qml (Inspector Overlay)                                            │   │
│   │ ┌───────────────────────────────────┬────────────────────────────────────────┐ │   │
│   │ │ Left Column: CPU Section          │ Right Column Top: GPU Section (UHD 770)│ │   │
│   │ │ - Header: CPU (i5-13500)          │ - Header: GPU                          │ │   │
│   │ │ - Overall Load & Progress Bar     │ - iGPU Load Progress Bar               │ │   │
│   │ │ - Package Temp (°C)               │ - Render Clock (MHz)                   │ │   │
│   │ │ - P-Cores (12T) Load & Clock      │ - Throttling Badge ("Normal"/"Throttle")│ │  │
│   │ │ - E-Cores (8T) Load & Clock       ├────────────────────────────────────────┤ │   │
│   │ │ - Scaling Governor & Wattage N/A  │ Right Column Bottom: Platform (B760)   │ │   │
│   │ │                                   │ - Header: Platform                     │ │   │
│   │ │                                   │ - Motherboard VRM Temp (°C)            │ │   │
│   │ │                                   │ - Energy Performance Preference (EPP)  │ │   │
│   │ │                                   │ - Scaling Governor                     │ │   │
│   │ └───────────────────────────────────┴────────────────────────────────────────┘ │   │
│   │ Boosts HardwareTelemetry.fastPollingRequests++ while active                    │   │
│   └────────────────────────────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────┬─────────────────────────────────────────────┘
                                           │ Data Binding
                                           ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ HardwareTelemetry.qml Singleton (restow/.../ii/services/HardwareTelemetry.qml)         │
│ - overallCpuLoad, pCoreLoad, eCoreLoad, pCoreFrequencyMhz, eCoreFrequencyMhz           │
│ - gpuLoad, gpuClockMhz, gpuThrottled                                                   │
│ - packageTemp, vrmTemp, energyPerformancePreference, scalingGovernor                   │
│ - fastPolling: fastPollingRequests > 0 (1000ms active / 3000ms idle)                   │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

| Component | Repository Path | Live Target Symlink | Primary Responsibility |
|-----------|-----------------|---------------------|------------------------|
| **`CpuGpuPill.qml`** | `restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPill.qml` | `~/.config/quickshell/ii/modules/ii/bar/CpuGpuPill.qml` | Top bar pill displaying CPU % + Temp + GPU % with responsive `useShortenedForm`, independent two-tier alert coloring, breathing pulse, and inert click handling. |
| **`CpuGpuPopup.qml`** | `restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPopup.qml` | `~/.config/quickshell/ii/modules/ii/bar/CpuGpuPopup.qml` | Dual-column inspector overlay displaying CPU metrics (P/E cores, frequencies), GPU metrics (render load, clock, throttle), and B760 motherboard VRM/EPP. |
| **`StyledPopup.qml`** | `restow/quickshell/.config/quickshell/ii/modules/ii/bar/StyledPopup.qml` | `~/.config/quickshell/ii/modules/ii/bar/StyledPopup.qml` | Overlays upstream `StyledPopup.qml` to provide seamless cursor tracking (`D-18`), screen boundary clamping (`D-19`), and M3 expressive entrance transition (`D-20`). |
| **`HardwareTelemetry.qml`** | `restow/quickshell/.config/quickshell/ii/services/HardwareTelemetry.qml` | `~/.config/quickshell/ii/services/HardwareTelemetry.qml` | Backend singleton providing CPU, GPU, and thermal properties with adaptive 1000ms/3000ms polling. |

---

## Standard Stack & QML/C++ Bindings

| Element | Source / Provider | Usage in Phase 43 |
|---------|-------------------|-------------------|
| **Quickshell** | `0.2.1` (AUR `quickshell-git`) | C++/Qt 6 desktop shell environment executing QML components. |
| **`BarGroup`** | `restow/quickshell/.../ii/bar/BarGroup.qml` | Base pill container providing 250ms Material 3 `emphasizedDecel` width resizing animation and `Appearance.colors.colLayer1` surface background. |
| **`MaterialSymbol`** | `vendor/.../ii/modules/common/widgets/MaterialSymbol.qml` | System Material Symbols icon renderer (`planner_review`, `speed`, `device_thermostat`, `tune`, `developer_board`). |
| **`StyledText`** | `vendor/.../ii/modules/common/widgets/StyledText.qml` | Font-aware typography component bound to `Appearance.font.pixelSize`. |
| **`StyledProgressBar`** | `vendor/.../ii/modules/common/widgets/StyledProgressBar.qml` | Material 3 progress bar for CPU overall load, P-core load, E-core load, and iGPU load. |
| **`StyledPopupHeaderRow`** | `vendor/.../ii/modules/ii/bar/StyledPopupHeaderRow.qml` | Standard section headers in popup cards. |
| **`StyledPopupValueRow`** | `vendor/.../ii/modules/ii/bar/StyledPopupValueRow.qml` | Key-value data rows with leading icons in popup cards. |
| **`Appearance`** | `qs.modules.common` | Centralized system design tokens: `colors.colLayer1`, `colors.colTertiary`, `colors.colError`, `colors.colOnLayer1`, `font.pixelSize`, and `animationCurves`. |
| **`Config`** | `qs.modules.common` | User configuration tokens: `Config.options.bar.borderless`, `Config.options.bar.vertical`. |
| **`HardwareTelemetry`** | `qs.services` | Backend singleton service delivering hardware metrics. |

---

## Architecture Patterns & Component Structure

### 1. Pill Layout & Responsive Architecture (`CpuGpuPill.qml`)

`CpuGpuPill.qml` inherits `BarGroup` as its root element.

#### Property Interface & State
```qml
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

    // Two-tier alert state bindings (D-10)
    readonly property bool cpuCritical: HardwareTelemetry.overallCpuLoad >= 0.90 || HardwareTelemetry.packageTemp >= 85
    readonly property bool cpuWarning: !cpuCritical && (HardwareTelemetry.overallCpuLoad >= 0.70 || HardwareTelemetry.packageTemp >= 75)
    readonly property bool tempCritical: HardwareTelemetry.packageTemp >= 85
    readonly property bool tempWarning: !tempCritical && HardwareTelemetry.packageTemp >= 75
    readonly property bool gpuCritical: HardwareTelemetry.gpuLoad >= 0.90
    readonly property bool gpuWarning: !gpuCritical && HardwareTelemetry.gpuLoad >= 0.70

    // Dynamic Material You color mapping (D-11, zero hardcoded hex)
    readonly property color cpuColor: cpuCritical ? Appearance.colors.colError : (cpuWarning ? Appearance.colors.colTertiary : Appearance.colors.colOnLayer1)
    readonly property color tempColor: tempCritical ? Appearance.colors.colError : (tempWarning ? Appearance.colors.colTertiary : Appearance.colors.colOnLayer1)
    readonly property color gpuColor: gpuCritical ? Appearance.colors.colError : (gpuWarning ? Appearance.colors.colTertiary : Appearance.colors.colOnLayer1)
...
```

#### Inert Click Handling & Re-Parenting
In `BarGroup.qml`, items declared inside the body automatically append to `gridLayout.children`. To prevent a `MouseArea` from consuming a layout cell and distorting the grid:
- Re-parent the `MouseArea` directly to `root` (`parent: root`).
- Set `anchors.fill: parent`.
- Set `acceptedButtons: Qt.AllButtons`, `cursorShape: Qt.ArrowCursor`.
- Consume all mouse clicks (`onPressed: event => event.accepted = true`, `onClicked: event => event.accepted = true`).
- Enable hover tracking (`hoverEnabled: true`) so `pillMouseArea` serves as the `hoverTarget` for `CpuGpuPopup`.

#### Telemetry Grid Items (D-01..D-06, D-08)
Items placed inside `BarGroup` are arranged by `BarGroup`'s internal `GridLayout` (`columns: root.vertical ? 1 : -1`, `columnSpacing: 4`):
1. **CPU Icon (`MaterialSymbol`):** `text: "planner_review"`, `color: root.cpuColor`, with `SequentialAnimation` pulse when `root.cpuCritical`.
2. **CPU Load Text (`StyledText`):** `text: `${Math.round(HardwareTelemetry.overallCpuLoad * 100)}%``, `color: root.cpuColor`.
3. **Package Temp Text (`StyledText`):** `text: `${HardwareTelemetry.packageTemp}°C``, `color: root.tempColor`, `visible: root.useShortenedForm === 0`.
4. **GPU Icon (`MaterialSymbol`):** `text: "speed"`, `color: root.gpuColor`, `Layout.leftMargin: root.vertical ? 0 : 6` (distinct visual cluster separation per `D-02`), with `SequentialAnimation` pulse when `root.gpuCritical`.
5. **GPU Load Text (`StyledText`):** `text: `${Math.round(HardwareTelemetry.gpuLoad * 100)}%``, `color: root.gpuColor`.

#### Critical Breathing Pulse Animation (D-12)
```qml
SequentialAnimation {
    id: cpuPulseAnimation
    running: root.cpuCritical
    loops: Animation.Infinite
    onRunningChanged: {
        if (!running) cpuIcon.opacity = 1.0;
    }
    NumberAnimation {
        target: cpuIcon
        property: "opacity"
        to: 0.6
        duration: 600
        easing.type: Easing.InOutSine
    }
    NumberAnimation {
        target: cpuIcon
        property: "opacity"
        to: 1.0
        duration: 600
        easing.type: Easing.InOutSine
    }
}
```
*Guaranteed State Reset:* When `root.cpuCritical` flips to false, `onRunningChanged` forces `cpuIcon.opacity = 1.0` immediately, eliminating stuck low-opacity states.

---

### 2. Inspector Overlay Architecture (`CpuGpuPopup.qml`)

`CpuGpuPopup.qml` instantiates `StyledPopup` as its root element and anchors to `CpuGpuPill`'s `pillMouseArea`.

#### Fast Polling Lifecycle Boost
To provide instantaneous 1000ms telemetry refreshes while the popup is visible without burning idle CPU cycles:
```qml
StyledPopup {
    id: root

    // Reactive adaptive polling boost
    onActiveChanged: {
        if (active) {
            HardwareTelemetry.fastPollingRequests++;
        } else {
            HardwareTelemetry.fastPollingRequests--;
        }
    }
    Component.onDestruction: {
        if (active) {
            HardwareTelemetry.fastPollingRequests--;
        }
    }
...
```

#### Dual-Column Layout Structure (D-13)
Content is hosted inside a `RowLayout`:
```
RowLayout (spacing: 16)
 ├── Left Column: ColumnLayout (CPU Section)
 │    ├── StyledPopupHeaderRow (icon: "planner_review", label: "CPU (i5-13500)")
 │    ├── Overall CPU Load: StyledProgressBar + percentage value
 │    ├── Package Temp: StyledPopupValueRow (temp1_input)
 │    ├── P-Cores (12T): Meter Row (Load progress bar + Frequency MHz)
 │    ├── E-Cores (8T): Meter Row (Load progress bar + Frequency MHz)
 │    ├── Scaling Governor: StyledPopupValueRow
 │    └── Power Draw: StyledPopupValueRow ("N/A (unprivileged)" placeholder)
 ├── Vertical Separator: Rectangle (width: 1, Layout.fillHeight: true)
 └── Right Column: ColumnLayout
      ├── GPU Section (Top)
      │    ├── StyledPopupHeaderRow (icon: "speed", label: "GPU (UHD 770)")
      │    ├── iGPU Load: StyledProgressBar + percentage value
      │    ├── Active Render Clock: StyledPopupValueRow (MHz)
      │    └── Thermal Throttle: Status tag ("Normal" vs "Thermal Throttle")
      ├── Horizontal Separator: Rectangle (height: 1, Layout.fillWidth: true)
      └── Platform Section (Bottom)
           ├── StyledPopupHeaderRow (icon: "developer_board", label: "Platform (B760)")
           ├── Motherboard VRM Temp: StyledPopupValueRow (°C)
           ├── Energy Performance Preference (EPP): StyledPopupValueRow
           └── Scaling Governor: StyledPopupValueRow
```

#### MetricProgressRow Pattern
For multi-attribute meter rows (such as P-cores and E-cores showing both percentage and active MHz frequency):
```qml
component MetricProgressRow: ColumnLayout {
    property string title: ""
    property real value: 0.0
    property string subtitle: ""
    property color barColor: Appearance.colors.colPrimary
    spacing: 2
    Layout.fillWidth: true

    RowLayout {
        Layout.fillWidth: true
        StyledText {
            text: title
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colOnSurfaceVariant
        }
        Item { Layout.fillWidth: true }
        StyledText {
            text: subtitle
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
        }
        StyledText {
            text: `${Math.round(value * 100)}%`
            font.pixelSize: Appearance.font.pixelSize.smaller
            font.weight: Font.DemiBold
            color: barColor
        }
    }

    StyledProgressBar {
        Layout.fillWidth: true
        value: Math.max(0.0, Math.min(1.0, root.value))
        highlightColor: barColor
    }
}
```

---

### 3. Base Popup Overlay Enhancements (`StyledPopup.qml`)

Upstream `vendor/.../StyledPopup.qml` has three structural limitations that violate Phase 43 requirements:
1. `active: hoverTarget && hoverTarget.containsMouse` causes the popup window to immediately destroy itself the millisecond the cursor exits the pill toward the popup (violating D-18).
2. `margins.left` does not clamp to screen width. On top bar left-zone pills, centered popup calculations yield negative margins, clipping the window off-screen to the left (violating D-19).
3. The popup window appears instantly with 0ms animation (violating D-20).

By overlaying `StyledPopup.qml` in `restow/quickshell/.config/quickshell/ii/modules/ii/bar/StyledPopup.qml`, these capabilities are delivered cleanly while maintaining 100% backward compatibility for all existing popups (`ResourcesPopup`, `BatteryPopup`, `ClockWidgetPopup`, etc.).

#### Seamless Cursor Tracking (D-18)
A close debounce timer provides a 200ms grace period allowing the mouse cursor to seamlessly bridge the spatial gap between the pill and popup window:
```qml
property bool hovered: (hoverTarget && hoverTarget.containsMouse) || popupHovered
property bool shouldBeActive: false

Timer {
    id: closeTimer
    interval: 200
    repeat: false
    onTriggered: {
        if (!root.hovered) {
            root.shouldBeActive = false;
        }
    }
}

onHoveredChanged: {
    if (hovered) {
        closeTimer.stop();
        shouldBeActive = true;
    } else {
        closeTimer.restart();
    }
}

active: shouldBeActive
```
Inside `popupWindow`:
```qml
HoverHandler {
    id: popupHoverHandler
}
// Bound to root.popupHovered = popupHoverHandler.hovered
```

#### Screen Boundary Clamping (D-19)
The popup centers under `hoverTarget`, clamped between screen bounds:
```qml
margins {
    left: {
        if (!Config.options.bar.vertical) {
            const screenWidth = root.QsWindow?.screen?.width ?? 1920;
            const targetX = root.QsWindow?.mapFromItem(
                root.hoverTarget, 
                (root.hoverTarget.width - popupBackground.implicitWidth) / 2, 0
            ).x ?? 0;
            const gap = Appearance.sizes.hyprlandGapsOut;
            const minX = gap;
            const maxX = screenWidth - popupBackground.implicitWidth - gap;
            if (maxX < minX) return minX;
            return Math.round(Math.max(minX, Math.min(targetX, maxX)));
        }
        return Appearance.sizes.verticalBarWidth;
    }
    top: {
        if (!Config.options.bar.vertical) return Appearance.sizes.barHeight;
        const screenHeight = root.QsWindow?.screen?.height ?? 1080;
        const targetY = root.QsWindow?.mapFromItem(
            root.hoverTarget, 
            0, (root.hoverTarget.height - popupBackground.implicitHeight) / 2
        ).y ?? 0;
        const gap = Appearance.sizes.hyprlandGapsOut;
        const minY = gap;
        const maxY = screenHeight - popupBackground.implicitHeight - gap;
        if (maxY < minY) return minY;
        return Math.round(Math.max(minY, Math.min(targetY, maxY)));
    }
}
```

#### Material 3 Expressive Entrance Transition (D-20)
Inside `popupBackground`:
```qml
transform: Translate { id: entranceTranslate; y: 0 }

ParallelAnimation {
    running: true
    NumberAnimation {
        target: popupBackground
        property: "opacity"
        from: 0.0
        to: 1.0
        duration: 150
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.animationCurves.expressiveEffects
    }
    NumberAnimation {
        target: entranceTranslate
        property: "y"
        from: -4
        to: 0
        duration: 150
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.animationCurves.expressiveEffects
    }
}
```

---

## Don't Hand-Roll

| Anti-Pattern | Standard / Preferred Alternative | Why Avoid Hand-Rolling |
|--------------|----------------------------------|------------------------|
| **Custom pill container with custom width animations** | Inherit `BarGroup.qml` | `BarGroup.qml` already implements `Behavior on implicitWidth` with Material 3 `emphasizedDecel` (250ms), background rectangles, and borderless options. |
| **Hardcoding alert hex colors (`#FFA000`, `#FF5252`)** | Bind `Appearance.colors.colTertiary` (Warning) and `Appearance.colors.colError` (Critical) | Breaks dynamic Material You wallpaper harmony and dark/light switching. |
| **Spawning CLI processes (`sensors`, `lscpu`) from pill/popup** | Bind directly to `HardwareTelemetry` singleton | Blocking CLI execution stalls the Qt Quick scene graph, causing micro-stutter in animations. |
| **Unclamped popup coordinate arithmetic** | Use `Math.max(minX, Math.min(targetX, maxX))` with `hyprlandGapsOut` | Left-anchored pills produce negative `margins.left`, causing layer shell clipping or Hyprland monitor misplacement. |
| **Pill MouseArea declared directly inside `BarGroup` layout** | Set `parent: root` on `MouseArea` to extract it from `BarGroup.gridLayout` | Unparented `MouseArea` becomes a cell in `BarGroup`'s `GridLayout`, adding phantom whitespace. |
| **Reading RAPL power files (`energy_uj`)** | Display unprivileged fallback placeholder `"N/A (unprivileged)"` | Violates Phase 42 (D-05) Platypus mitigation (0400 root permission); unprivileged read fails closed. |

---

## Common Pitfalls & Edge Cases

### Pitfall 1: Pill MouseArea Re-parenting in `BarGroup`
**Issue:** `BarGroup.qml` defines `default property alias items: gridLayout.children`. Any component placed in `CpuGpuPill` without explicit parenting is automatically reparented into `gridLayout`. An unparented `MouseArea` will take up layout width and height, pushing the icons and text off-center.  
**Fix:** Explicitly set `parent: root` and `anchors.fill: parent` on the `MouseArea` [VERIFIED in `VoicePill.qml:106`].

### Pitfall 2: Popup Hover Gap & Premature Close Race (D-18)
**Issue:** Between the bottom edge of the top bar and the top of the popup window, the cursor moves across window boundaries. If `active` checks only `containsMouse` without hysteresis, the popup unloads mid-transit.  
**Fix:** Introduce a 200ms close debounce timer in `StyledPopup.qml`. While the cursor transitions from the pill to the popup window, the timer keeps `shouldBeActive = true`. Entering the popup window resets the timer and keeps the window open.

### Pitfall 3: Pulse Opacity Restoration on State Exit (D-12)
**Issue:** A `SequentialAnimation` oscillating `opacity` between 1.0 and 0.6 may be interrupted mid-cycle when CPU load drops below 90%. If stopped at `opacity: 0.6`, the icon remains permanently dimmed in normal state.  
**Fix:** Attach an `onRunningChanged` handler to the pulse animation:
```qml
onRunningChanged: {
    if (!running) targetIcon.opacity = 1.0;
}
```
[VERIFIED in `VoicePill.qml:146`].

### Pitfall 4: Horizontal Screen Clamping & Layer Shell Negative Margins (D-19)
**Issue:** `CpuGpuPill` will be mounted on the far left of the top bar (next to `LeftSidebarButton`). Centering a 460px popup directly underneath a 150px pill located at `x = 60px` calculates `margins.left = 60 + (150 - 460)/2 = -95px`. In Wayland `wlr-layer-shell`, negative margins clip the popup off-screen.  
**Fix:** Enforce `minX = Appearance.sizes.hyprlandGapsOut` via `Math.max(minX, ...)` in `StyledPopup.qml`.

### Pitfall 5: Fast Polling Reference Count Leaks
**Issue:** If `CpuGpuPopup` increments `fastPollingRequests` on creation but fails to decrement on destruction or closure, `HardwareTelemetry` will remain permanently in 1000ms fast polling mode, wasting CPU cycles indefinitely.  
**Fix:** Pair `onActiveChanged` with `Component.onDestruction`:
```qml
onActiveChanged: {
    if (active) HardwareTelemetry.fastPollingRequests++;
    else HardwareTelemetry.fastPollingRequests--;
}
Component.onDestruction: {
    if (active) HardwareTelemetry.fastPollingRequests--;
}
```

### Pitfall 6: Live File Overwrite during GNU Stow Restow
**Issue:** Upstream dots-hyprland installed an initial `StyledPopup.qml` as a plain file in `~/.config/quickshell/ii/modules/ii/bar/StyledPopup.qml`. If `StyledPopup.qml` is added to `restow/quickshell/` without renaming the existing live file, `stow` will fail with: `existing target is neither a link nor a directory`.  
**Fix:** The deployment step must rename `~/.config/.../StyledPopup.qml` to `StyledPopup.qml.bak` before running `cd restow && stow --no-folding -t ~ quickshell`, preserving the exact pattern established for `BarGroup.qml.bak`, `ClockWidget.qml.bak`, and `Resource.qml.bak`.

---

## Validation Architecture (Nyquist)

### 1. Test Harness (`scripts/phase43-cpu-gpu-assert.sh`)
An automated assert harness enforcing all requirements and decisions with exit 0 on `FAIL=0 FINDINGS=0`:

```bash
./scripts/phase43-cpu-gpu-assert.sh [--section <1-5>] [-s <1-5>] [--quick] [--syntax]
```

- **Section 1: Static AST & Syntax Verification:**
  - Validates `CpuGpuPill.qml`, `CpuGpuPopup.qml`, and `StyledPopup.qml` exist under `restow/quickshell/.../ii/bar/`.
  - Verifies `pragma ComponentBehavior: Bound` is declared on all files.
  - Verifies presence of Material Symbols `planner_review` and `speed`.
  - Verifies use of dynamic tokens (`Appearance.colors.colTertiary`, `Appearance.colors.colError`) and strictly bans hardcoded hex colors (`#FFA000`, etc.).
- **Section 2: `CpuGpuPill.qml` Component Logic (CPUGPU-01, CPUGPU-04, D-01..D-12):**
  - Confirms root component is `BarGroup`.
  - Asserts reactive property `useShortenedForm` drops temperature text visibility.
  - Asserts independent color alert threshold variables (70%/75°C warning, 90%/85°C critical).
  - Asserts breathing pulse animation on `planner_review` and `speed` icons with `onRunningChanged` opacity restoration.
  - Asserts inert mouse area (`acceptedButtons: Qt.AllButtons`, `onPressed` consumption).
- **Section 3: `CpuGpuPopup.qml` Layout & Telemetry Bindings (CPUGPU-02, CPUGPU-03, D-13..D-16):**
  - Confirms dual-column structure (CPU left, GPU + Platform right).
  - Asserts segregated P-Core (12T) and E-Core (8T) load and frequency bindings.
  - Asserts Intel UHD 770 GPU load, active clock (MHz), and thermal throttle status badge.
  - Asserts Motherboard VRM temperature (`vrmTemp`) and EPP bindings.
  - Asserts power draw fallback placeholder (`"N/A (unprivileged)"` or `"-- W"`).
  - Asserts `fastPollingRequests` reference counting on `active` state changes.
- **Section 4: `StyledPopup.qml` Geometry & Transition Logic (D-17..D-20):**
  - Asserts close debounce timer for seamless cursor tracking.
  - Asserts screen boundary horizontal clamping (`minX` to `maxX`).
  - Asserts 150ms M3 entrance transition crossfade + 4px downward slide.
- **Section 5: Stow & Packaging Integrity (INTG-02):**
  - Asserts valid leaf symlinks in `~/.config/quickshell/ii/modules/ii/bar/` pointing to `restow/quickshell/...`.
  - Executes `./arch/dots-hyprland.sh verify --strict` to verify zero drift and `FAIL=0 FINDINGS=0`.
  - Asserts `vendor/dots-hyprland` submodule remains completely pristine (`git status --porcelain` clean).

### 2. Headless QML Runtime Execution Check
Using the headless runner pattern established in Phase 37:
```bash
timeout 4.5s quickshell -p <runner.qml>
```
Executes a test harness importing `CpuGpuPill` and `CpuGpuPopup`, verifying that QML components compile, instantiate, and bind to `HardwareTelemetry` without throwing property lookup warnings or layout evaluation exceptions.

### 3. Manual Inspection Verification Checkpoints
- **Pill Visual Check:** Hover over top bar; pill displays `[planner_review] <cpuLoad>% <packageTemp>°C  [speed] <gpuLoad>%`.
- **Shortened Form Check:** Test screen width scaling or simulate `useShortenedForm = 1`; package temperature vanishes while CPU and GPU loads remain visible.
- **Hover Bridge Check:** Move mouse slowly from `CpuGpuPill` downward into `CpuGpuPopup`; popup remains visible without flickering or premature closing.
- **Clamping Check:** Verify popup does not clip off the left edge of the monitor.
- **Inert Clicks Check:** Click left, right, and middle buttons directly on `CpuGpuPill`; no underlying windows or menus are triggered.
- **Fast Polling Check:** Monitor `HardwareTelemetry.fastPolling`; verify it switches to 1000ms while popup is open and returns to 3000ms when closed.
