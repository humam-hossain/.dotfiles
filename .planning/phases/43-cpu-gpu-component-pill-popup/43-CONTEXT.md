# Phase 43: CPU & GPU Component (Pill & Popup) - Context

**Gathered:** 2026-09-26
**Status:** Ready for planning

<domain>
## Phase Boundary

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

</domain>

<decisions>
## Implementation Decisions

### Pill Layout & Metrics Density (`CpuGpuPill.qml`)
- **D-01 (Visible Metrics):** Pill displays CPU % + Package Temp + GPU % — e.g. `[planner_review] 14% 42°C  [speed] 5%`. — **Reversibility:** reversible.
- **D-02 (Section Separation & Iconography):** Distinct Material Symbols icons (`planner_review` for CPU, `speed` for GPU) matching the current bar icon styling and size (`Appearance.font.pixelSize.normal`) visually anchor and separate the CPU and GPU sections. — **Reversibility:** reversible.
- **D-03 (Shortened Form Adaptability):** When `useShortenedForm` is active on narrow screens, drop temperature only and preserve both CPU and GPU load percentages (`[planner_review] 14%  [speed] 5%`), preventing center workspaces from being shifted off-center. — **Reversibility:** reversible.
- **D-04 (Fluid M3 Width Resizing):** Numbers use natural standard formatting (e.g. `5%`, `14%`, `100%`) with `BarGroup.qml`'s 250ms Material 3 `emphasizedDecel` animation for smooth width transitions. — **Reversibility:** reversible.
- **D-05 (Telemetry Element Ordering):** Elements are strictly ordered with CPU first, then GPU: `[planner_review] <cpuLoad>% <packageTemp>°C  [speed] <gpuLoad>%`. — **Reversibility:** reversible.
- **D-06 (Single Thermal Metric):** Pill temperature strictly references CPU Package Temp (`packageTemp` from `hwmon5/temp1_input`). NVMe and Motherboard temperatures are kept out of the pill to avoid clutter. — **Reversibility:** reversible.
- **D-07 (Container Styling):** Inherit standard `BarGroup` container background (`Appearance.colors.colLayer1`) and borderless setting (`Config.options.bar.borderless`), maintaining 100% aesthetic harmony with Workspaces, Clock, and Voice pills. — **Reversibility:** reversible.
- **D-08 (Vertical Orientation Support):** In vertical bar mode (`Config.options.bar.vertical`), elements stack vertically in a clean Column: `[planner_review]`, CPU %, Temp, `[speed]`, GPU %. — **Reversibility:** reversible.

### Alert Escalation & Pulse Animation
- **D-09 (Independent Color Escalation):** CPU cluster colors by CPU load, GPU cluster colors by GPU load, and Temperature colors by thermal degrees independently. — **Reversibility:** reversible.
- **D-10 (Two-Tier Thresholds):** Amber warning triggers at 70% load or 75°C; Red critical alert triggers at 90% load or 85°C. — **Reversibility:** reversible.
- **D-11 (Dynamic Material You Tokens):** Amber warning maps to `Appearance.colors.colTertiary` (harmonized dynamic gold/amber); Red critical maps to `Appearance.colors.colError` (dynamic M3 error red), with zero hardcoded hex colors. — **Reversibility:** reversible.
- **D-12 (Critical Breathing Pulse):** Under critical Red alert (≥90% load or ≥85°C), the active critical icon (`planner_review` or `speed`) executes a subtle breathing opacity animation (1.0 to 0.6 over 600ms) to draw peripheral awareness without visual clutter. — **Reversibility:** reversible.

### Popup Inspector Layout & Core Breakdown (`CpuGpuPopup.qml`)
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

### Interaction & Tooling
- **D-17 (Strict Hover Trigger / Inert Clicks):** `CpuGpuPill` reveals `CpuGpuPopup` strictly on mouse hover via `StyledPopup`. Mouse clicks are completely inert to prevent click bleeding or unintended window actions. — **Reversibility:** reversible.
- **D-18 (Seamless Cursor Tracking):** Popup remains open while the mouse cursor is over either the pill or within the popup window itself, enabling inspection of meters without premature closing. — **Reversibility:** reversible.
- **D-19 (Popup Centering & Screen Clamping):** `CpuGpuPopup` centers directly underneath `CpuGpuPill`, with automatic horizontal screen boundary clamping to prevent off-screen overflow. — **Reversibility:** reversible.
- **D-20 (Entrance Transition):** 150ms Material 3 entrance crossfade with a subtle 4px downward slide using `Appearance.animationCurves.expressiveEffects`. — **Reversibility:** reversible.

### the agent's Discretion
- Exact spacing constants and margins between progress bars in `CpuGpuPopup.qml`.
- Internal helper bindings for mapping temperature values to formatted strings.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap & Requirements
- `.planning/ROADMAP.md` §Phase 43 — CPU & GPU Component (Pill & Popup) goals and success criteria.
- `.planning/REQUIREMENTS.md` lines 10–16 — Milestone v0.9 requirements (CPUGPU-01..CPUGPU-04).
- `.planning/phases/42-telemetry-services-sensor-infrastructure/42-CONTEXT.md` — Phase 42 telemetry service architecture and decisions (D-01..D-07).

### Backend Telemetry Singletons
- `restow/quickshell/.config/quickshell/ii/services/HardwareTelemetry.qml` — Singleton providing live CPU load, P/E core loads, frequencies, EPP, scaling governor, GPU load, GPU clock MHz, GPU throttling, package temp, and motherboard VRM temp.

### Base Components & UI Patterns
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarGroup.qml` — Pill container providing 250ms M3 emphasized deceleration width resizing and background styling.
- `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/StyledPopup.qml` — Base popup container using `PanelWindow`, `WlrLayershell.layer: Overlay`, and elevation margins.
- `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/StyledPopupHeaderRow.qml` — Standard popup section header component.
- `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/StyledPopupValueRow.qml` — Standard popup value row component.
- `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/ResourcesPopup.qml` — Legacy resources popup reference.
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/VoicePill.qml` — Reference implementation for custom animated pills, breathing pulse animations, and inert mouse areas.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `BarGroup`: Root container for pills with built-in width animation (`Behavior on implicitWidth`).
- `MaterialSymbol`: System-wide Material Symbols icon renderer (`Appearance.font.pixelSize.normal`).
- `StyledText`: System-wide font-aware label renderer (`Appearance.font.pixelSize.small`).
- `StyledPopup`: Layer-shell overlay window that anchors to a `hoverTarget` and tracks mouse hover.
- `HardwareTelemetry`: Singleton service (`HardwareTelemetry.overallCpuLoad`, `HardwareTelemetry.pCoreLoad`, `HardwareTelemetry.eCoreLoad`, `HardwareTelemetry.packageTemp`, `HardwareTelemetry.gpuLoad`, `HardwareTelemetry.gpuClockMhz`, `HardwareTelemetry.gpuThrottled`, `HardwareTelemetry.vrmTemp`, etc.).

### Established Patterns
- Restow Overlay Discipline: All new QML files are created under `restow/quickshell/.config/quickshell/ii/modules/ii/bar/` and symlinked cleanly with GNU Stow `--no-folding`.
- Semantic Palette Tokens: Colors strictly resolve via `Appearance.colors` and `Appearance.m3colors` (e.g. `colTertiary` for Amber warning, `colError` for Red critical).
- Zero Root Dependency: Telemetry reads virtual `/proc/` and `/sys/` paths in user space without external root binaries.

### Integration Points
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPill.qml` -> Top bar pill component.
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPopup.qml` -> Inspector overlay anchored to `CpuGpuPill`.
- Future integration in Phase 46 places `CpuGpuPill` into `BarContent.qml` Left zone.

</code_context>

<specifics>
## Specific Ideas

- **P-Core vs E-Core Visual Contrast:** P-cores (12 threads up to 4.8 GHz) handle foreground interactive tasks, while E-cores (8 threads up to 3.5 GHz) handle background daemons and compilation. Displaying them as two distinct progress bars gives immediate visual proof of Intel Thread Director scheduling.
- **Hardware-Specific Sensor Grounding:** On this host, `coretemp-isa-0000` accurately reports CPU package id 0 at +34°C, and `gigabyte_wmi-virtual-0` reports the B760 VRM MOS temperature at +40°C. NVMe drive thermals (+38°C and +41°C) are specifically preserved for Phase 44.

</specifics>

<deferred>
## Deferred Ideas

- **Phase 44 (Memory & Storage Component):**
  - Dedicated `MemoryStoragePill.qml` and `MemoryStoragePopup.qml`.
  - Integration of `nvme-pci-0100` (Samsung PM9A1 root) and `nvme-pci-0200` (Samsung 980) temperatures alongside disk usage bars.
- **Phase 45 (Network & Multi-Target Ping Component):**
  - Dedicated `NetworkPingPill.qml` and `NetworkPingPopup.qml`.
  - Integration of `r8169_0_400:00-mdio-0` (Realtek 2.5GbE PHY transceiver) temperature into the network inspector card.
- **Phase 46 (Left-Zone Bar Integration & Verification Harness):**
  - Replacing legacy `Resources.qml` in `BarContent.qml` Left zone with `CpuGpuPill`, `MemoryStoragePill`, and `NetworkPingPill`.
  - Comprehensive automated test script `scripts/phase46-telemetry-assert.sh`.

</deferred>

---

*Phase: 43-cpu-gpu-component-pill-popup*
*Context gathered: 2026-09-26*
