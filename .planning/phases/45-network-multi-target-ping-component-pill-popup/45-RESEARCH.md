# Phase 45: Network & Multi-Target Ping Component (Pill & Popup) - Research & Planning Specification

**Target Milestone:** v0.9 (Top Status Bar Resource Components & Hardware Telemetry)  
**Dependencies:** Phase 42 (Telemetry Services & Sensor Infrastructure), Phase 43 (CPU & GPU Component), Phase 43.5 (Dynamic Telemetry & Ergonomics), Phase 44 (Memory & Storage Component)  
**Requirements Covered:** NETPING-01, NETPING-02, NETPING-03, NETPING-04, NETPING-05  
**Decisions Covered:** D-01 through D-17  
**Status:** Complete & Ready for Planning  

---

## 1. Executive Summary

Phase 45 designs and implements the fourth major status bar telemetry module for Quickshell: the **Network & Multi-Target Ping Telemetry Component**, consisting of the dedicated `NetworkPingPill.qml` status bar widget and the interactive `NetworkPingPopup.qml` inspector overlay [VERIFIED: .planning/phases/45-network-multi-target-ping-component-pill-popup/45-CONTEXT.md:9-13].

Following the high-fidelity design standards established in Phase 43 for `CpuGpuPill` / `CpuGpuPopup` and Phase 44 for `MemoryStoragePill` / `MemoryStoragePopup`, Phase 45 delivers:

1. **Status Bar Symmetry & Real-Time Throughput**: `NetworkPingPill.qml` provides continuous, space-efficient network visibility. It is cleanly partitioned by a vertical divider into two distinct segments: local bandwidth throughput using directional glyphs (`↓ 1.2M  ↑ 45K` derived directly from `/proc/net/dev`) on the left, and all 3 ping latency targets (WAN `8.8.8.8`, Gateway `192.168.0.1`, Home Server `192.168.0.104`) on the right with distinct Material Symbols (`public`, `router`, `dns`) and health status colors [VERIFIED: 45-CONTEXT.md:20-23].
2. **Balanced Two-Column Inspector Overlay**: `NetworkPingPopup.qml` matches the structural dimensions (320px Left, 320px Right) of `CpuGpuPopup` and `MemoryStoragePopup`. The Left column features active NIC interface telemetry, connection type, IP address/subnet mask, gateway, DNS servers, link speed/duplex, MAC address, NIC hardware temperature (Realtek `r8169`), packet drop/error counters, and dual `StyledProgressBar` activity meters for Rx and Tx alongside cumulative session totals. The Right column presents 3 dedicated ping diagnostic cards displaying target hostnames, IP badges, large latency numbers, quality pills, and daemon status classes [VERIFIED: 45-CONTEXT.md:27-31].
3. **Dedicated Telemetry Singleton (`NetworkUsage.qml`)**: Telemetry separation of concerns backed by a new singleton service `NetworkUsage.qml` in `restow/quickshell/.config/quickshell/ii/services/`. It performs sub-millisecond procfs reading of `/proc/net/dev` via `FileView`, carrier priority interface detection (`en*`/`eth*` carrier=1 prioritized over `wl*`), dynamic `r8169` hwmon temperature tracking, and an adaptive polling cadence (2000ms idle, 1000ms fast inspector polling) [VERIFIED: 45-CONTEXT.md:35-48].
4. **Direct Browser Dashboard Launching**: Left-clicking either the status bar pill or the explicit action button in the popup header launches the web ping dashboard at `http://127.0.0.1:8765/` in the default browser using non-blocking `Quickshell.execDetached(["xdg-open", "http://127.0.0.1:8765/"])` with Material press feedback, preserving popup visibility during launch [VERIFIED: 45-CONTEXT.md:52-55].
5. **Zero Working Tree Drift**: Packaged strictly under `restow/quickshell/` using GNU Stow leaf symlinks, maintaining upstream `vendor/dots-hyprland` pristine and passing `./arch/dots-hyprland.sh verify --strict` [VERIFIED: REQUIREMENTS.md:48].

---

## 2. Domain & Boundary Analysis

### Phase Inclusions
- `restow/quickshell/.config/quickshell/ii/services/NetworkUsage.qml`: Dedicated singleton service for procfs `/proc/net/dev` throughput parsing, carrier priority interface selection, IP/gateway/DNS configuration discovery, link speed/duplex, NIC hardware temperature, and adaptive sampling [VERIFIED: 45-CONTEXT.md:35-48].
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/NetworkPingPill.qml`: Status bar pill widget displaying live throughput directional glyphs (`↓` / `↑`), vertical divider, and all 3 ping targets (`8.8.8.8`, `192.168.0.1`, `192.168.0.104`) with latency readouts and status colors [VERIFIED: 45-CONTEXT.md:20-23].
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/NetworkPingPopup.qml`: Interactive two-column inspector popup overlay anchored to the pill with 1000ms hover delay, 200ms close grace period, dual throughput activity meters, comprehensive interface telemetry, 3 target diagnostic cards, and dashboard launcher [VERIFIED: 45-CONTEXT.md:27-31, 53].
- Stow leaf symlink management under `restow/quickshell/` without folding parent directories [VERIFIED: restow/README.md:55-65].
- Automated assertion test suite `scripts/phase45-network-ping-assert.sh` verifying all visual properties, AST structure, bindings, formatting math, and zero working tree drift.

### Phase Exclusions (Strict Scope Fencing)
- **Top Bar Left Zone Layout Integration (`BarContent.qml`)**: Integration of `NetworkPingPill.qml` alongside `CpuGpuPill` and `MemoryStoragePill` in `BarContent.qml` is deferred to Phase 46 (INTG-01) [VERIFIED: 45-CONTEXT.md:11, 125-127].
- **Cross-Service Automated Regression Suite (`scripts/phase46-telemetry-assert.sh`)**: Repo-wide telemetry assertion harness testing all resource services simultaneously is deferred to Phase 46 (INTG-03) [VERIFIED: REQUIREMENTS.md:49-50].
- **Raw ICMP Ping Spawning from QML**: Spawning raw `ping` processes from QML is explicitly prohibited [VERIFIED: REQUIREMENTS.md:68]. Ping telemetry is exclusively gathered by the existing local Python daemon on port 8765 and queried via `PingService.qml`.

---

## 3. Requirements Coverage Matrix

| Requirement ID | Summary | Architectural Approach | Confidence |
| :--- | :--- | :--- | :--- |
| **NETPING-01** | Bar pill displays real-time network throughput rates (Rx/Tx KB/s or MB/s) derived from `/proc/net/dev`. | Implemented in `NetworkUsage.qml` via `FileView` reading `/proc/net/dev` without subprocess churn, calculating rate deltas per second; displayed in `NetworkPingPill.qml` using directional text glyphs (`↓ 1.2M  ↑ 45K`) [VERIFIED: 45-CONTEXT.md:20, 45]. | **HIGH** |
| **NETPING-02** | Bar pill displays **all 3 ping targets** (WAN `8.8.8.8`, Gateway `192.168.0.1`, Home Server `192.168.0.104`) with numeric latency (ms) and quality status colors. | Implemented in `NetworkPingPill.qml` binding to `PingService.wanTarget`, `gatewayTarget`, and `homeServerTarget` using Material Symbols `public`, `router`, and `dns` alongside numeric latency texts colored by health class (`good`, `medium`/`warning`, `dead`) [VERIFIED: 45-CONTEXT.md:21]. | **HIGH** |
| **NETPING-03** | Ping client service polls local system monitor daemon (`http://127.0.0.1:8765/api/status`) asynchronously at 5s intervals with graceful fallback if the daemon is offline. | Backed by existing `restow/.../services/PingService.qml` running `XMLHttpRequest` at 5s online / 15s offline backoff, setting `isOffline` and default `-- ms` values on failure [VERIFIED: restow/quickshell/.config/quickshell/ii/services/PingService.qml:34-90]. | **HIGH** |
| **NETPING-04** | Network popup inspector displays active NIC interface name, IPv4 address, link speed, and detailed 3-target ping diagnostic cards. | Implemented in `NetworkPingPopup.qml` with a balanced two-column layout: Left column contains comprehensive interface telemetry (interface, IP/subnet, gateway, DNS, link speed, MAC, NIC temp, errors/drops, dual throughput progress bars); Right column contains 3 dedicated ping diagnostic cards [VERIFIED: 45-CONTEXT.md:27-31, 37-46]. | **HIGH** |
| **NETPING-05** | Clicking Network pill or popup launches the web ping dashboard at `http://127.0.0.1:8765/` in the default browser. | Pill `MouseArea.onClicked` and popup header action button execute non-blocking `Quickshell.execDetached(["xdg-open", "http://127.0.0.1:8765/"])` with click feedback while keeping popup open until pointer exits [VERIFIED: 45-CONTEXT.md:52-55]. | **HIGH** |

---

## 4. Implementation Decisions & Design Contracts

| Decision ID | Summary | Technical Rule & Contract |
| :--- | :--- | :--- |
| **D-01** | Throughput Representation | Live network throughput (Rx/Tx) represented using space-efficient directional glyphs (`↓ 1.2M  ↑ 45K`), formatted compactly with auto-scaling unit suffixes (`K`, `M`, `G`) matching Waybar conventions [VERIFIED: 45-CONTEXT.md:20]. |
| **D-02** | Ping Targets Formatting | All 3 ping targets (WAN `8.8.8.8`, Gateway `192.168.0.1`, Home Server `192.168.0.104`) displayed with distinct Material Symbols (`public` for WAN, `router` for Gateway, `dns` for Server) and numeric latencies (ms) colored dynamically (`good` = theme primary/green, `medium`/`warning` = amber, `dead` = red) [VERIFIED: 45-CONTEXT.md:21]. |
| **D-03** | Pill Internal Partitioning | Pill visually partitioned into two segments separated by a vertical divider line: `[Net Icon + Throughput] \| [3 Ping Targets]` [VERIFIED: 45-CONTEXT.md:22]. |
| **D-04** | Responsive Width Parity | Full fidelity maintained across all screen widths (`useShortenedForm > 0`), retaining both throughput rates and all 3 ping latencies without dropping metrics or squishing text, ensuring architectural parity with `CpuGpuPill` and `MemoryStoragePill` [VERIFIED: 45-CONTEXT.md:23]. |
| **D-05** | Balanced Two-Column Architecture | `NetworkPingPopup.qml` arranged in a balanced two-column layout (320px Left, 320px Right) matching `CpuGpuPopup` and `MemoryStoragePopup` proportions [VERIFIED: 45-CONTEXT.md:27]. |
| **D-06** | NIC Hardware Temperature | Left column includes real-time NIC temperature sourced from Realtek `r8169` (`/sys/class/hwmon/hwmon4/temp1_input`) with dynamic hwmon path scanning and graceful fallback if absent [VERIFIED: 45-CONTEXT.md:28]. |
| **D-07** | Dedicated Ping Diagnostic Cards | Right column presents 3 dedicated cards (WAN, Gateway, Home Server) with target icon, host title, IP badge, prominent latency readout (ms), quality pill ('good'/'warning'/'offline'), and status class [VERIFIED: 45-CONTEXT.md:29]. |
| **D-08** | Dual Throughput Progress Bars | Left column features dual `StyledProgressBar` meters for visual Rx and Tx throughput activity (scaled dynamically or against link speed) alongside live rates (KB/MB/s) and cumulative session totals (Rx/Tx GB) [VERIFIED: 45-CONTEXT.md:30]. |
| **D-09** | Offline State Presentation | When ping daemon is unreachable or network disconnected, display a prominent warning banner at top of ping column; dim target cards to show last known or `-- ms` with alert styling [VERIFIED: 45-CONTEXT.md:31]. |
| **D-10** | Dedicated Singleton Service | Dedicated singleton `NetworkUsage.qml` in `restow/quickshell/.config/quickshell/ii/services/`, cleanly separating concerns following `StorageUsage.qml` and `ResourceUsage.qml` patterns [VERIFIED: 45-CONTEXT.md:35]. |
| **D-11** | Comprehensive Telemetry Field Suite | `NetworkUsage.qml` captures: 1) Active interface & connection type, 2) Wi-Fi SSID & Signal Strength (via `Network.qml`), 3) IPv4 & CIDR subnet mask, 4) Default Gateway IP, 5) DNS Nameservers (`/etc/resolv.conf`), 6) Link Speed & Duplex, 7) NIC Hardware Temp, 8) MAC Address, 9) Live Throughput Rates & Session Totals, 10) Packet Errors & Drops [VERIFIED: 45-CONTEXT.md:36-46]. |
| **D-12** | Adaptive Polling Cadence | `NetworkUsage.qml` runs at 2000ms idle background sampling, boosting to 1000ms fast sampling when `isInspectorActive = true` [VERIFIED: 45-CONTEXT.md:47]. |
| **D-13** | Carrier Priority Interface Detection | Primary interface selected via Carrier Priority Hierarchy: Check `/sys/class/net/*/carrier`; prioritize physical Ethernet (`enp*`/`eth*`) if carrier=1; if unplugged, fall back to wireless (`wlan*`/`wlp*`), filtering out virtual/docker/bridge interfaces [VERIFIED: 45-CONTEXT.md:48]. |
| **D-14** | Direct Pill Left-Click Launcher | Left-clicking status bar pill launches `http://127.0.0.1:8765/` via `Quickshell.execDetached(["xdg-open", "http://127.0.0.1:8765/"])`. Hovering triggers popup inspector [VERIFIED: 45-CONTEXT.md:52]. |
| **D-15** | Popup Header Action Button | Ping column header includes an explicit "Open Web Dashboard" button with `open_in_new` Material Symbol and tooltip, triggering `xdg-open http://127.0.0.1:8765/` [VERIFIED: 45-CONTEXT.md:53]. |
| **D-16** | Popup Visibility on Click | Clicking pill or popup action button to launch browser does not abruptly dismiss popup; popup remains visible until pointer exits hover area or 200ms grace period elapses [VERIFIED: 45-CONTEXT.md:54]. |
| **D-17** | Non-Blocking Spawn & Visual Feedback | Launching `xdg-open` is executed via `Quickshell.execDetached` with subtle press animation / ripple feedback, guaranteeing zero event loop stalls [VERIFIED: 45-CONTEXT.md:55]. |

---

## 5. Architectural & Implementation Specifications

### 5.1 Service: `NetworkUsage.qml`

- **Location:** `restow/quickshell/.config/quickshell/ii/services/NetworkUsage.qml` [VERIFIED: 45-CONTEXT.md:35]
- **Base Type:** `Singleton` [VERIFIED: restow/quickshell/.config/quickshell/ii/services/ResourceUsage.qml:12]
- **Pragmas:**
  ```qml
  pragma Singleton
  pragma ComponentBehavior: Bound
  ```
- **Lifecycle & Adaptive Polling:**
  - `property bool isInspectorActive: false`
  - Polling Timer: `interval: isInspectorActive ? 1000 : 2000` (per D-12)
  - Fast-polling path: Only reads procfs (`/proc/net/dev`) and NIC temp via `FileView` (<1ms execution time, zero fork/exec overhead)
  - Slow-refresh path: Periodic or event-driven interface configuration refresh (IP, Gateway, DNS, Link speed, MAC) via lightweight asynchronous `Process` runs every 30s or immediately on `isInspectorActive` opening
- **Carrier Priority Hierarchy Interface Selection (D-13):**
  - Examines network interfaces excluding virtual types (`lo`, `docker*`, `veth*`, `br-*`, `virbr*`, `tailscale*`, `tun*`, `tap*`, `wg*`)
  - Rule 1: If an Ethernet interface (`en*`, `eth*`) has `carrier == 1` and `operstate == "up"`, select Ethernet
  - Rule 2: If Ethernet carrier == 0 or unplugged, check wireless interfaces (`wl*`); if `carrier == 1` or `operstate == "up"`, select Wireless
  - Rule 3: Fall back to interface associated with the default IPv4 route (`ip -j route show default`)
- **Throughput Rate & Formatting Mathematics:**
  - `/proc/net/dev` line format for interface:
    `iface: rx_bytes rx_packets rx_errs rx_drop ... tx_bytes tx_packets tx_errs tx_drop ...`
  - $dt = (now - lastSampleTime) / 1000.0$
  - $\Delta Rx = \max(0, rx\_bytes - prev\_rx\_bytes)$
  - $\Delta Tx = \max(0, tx\_bytes - prev\_tx\_bytes)$
  - $rxRate = \Delta Rx / dt$, $txRate = \Delta Tx / dt$
  - Formatting functions:
    ```javascript
    function formatThroughput(bytesPerSec) {
        if (!bytesPerSec || bytesPerSec <= 0) return "0 B/s";
        if (bytesPerSec < 1024) return bytesPerSec.toFixed(0) + " B/s";
        if (bytesPerSec < 1024 * 1024) return (bytesPerSec / 1024).toFixed(1) + " KB/s";
        if (bytesPerSec < 1024 * 1024 * 1024) return (bytesPerSec / (1024 * 1024)).toFixed(1) + " MB/s";
        return (bytesPerSec / (1024 * 1024 * 1024)).toFixed(1) + " GB/s";
    }

    function formatShortRate(bytesPerSec) {
        if (!bytesPerSec || bytesPerSec < 1024) return "0K";
        if (bytesPerSec < 1024 * 1024) return Math.round(bytesPerSec / 1024) + "K";
        if (bytesPerSec < 1024 * 1024 * 1024) return (bytesPerSec / (1024 * 1024)).toFixed(1) + "M";
        return (bytesPerSec / (1024 * 1024 * 1024)).toFixed(1) + "G";
    }

    function formatGigabytes(bytes) {
        if (!bytes || bytes <= 0) return "0.0 GB";
        return (bytes / (1024 * 1024 * 1024)).toFixed(1) + " GB";
    }
    ```
- **NIC Hardware Temperature Discovery (D-06):**
  - Scans `/sys/class/hwmon/hwmon*/name` at startup for `r8169*` (on the live system, `/sys/class/hwmon/hwmon4` is `r8169_0_400:00`) [VERIFIED: live system hwmon audit].
  - Binds `FileView` to `hwmonNicPath + "/temp1_input"`. Reads raw millidegrees C (e.g. `37500`), converts to degrees C (`37.5°C`).
  - Gracefully sets `nicTemp: null` / `"--"` if unreadable or absent.
- **Wi-Fi Integration:**
  - When connection type is Wi-Fi, reads `Network.networkName` (SSID) and `Network.networkStrength` directly from upstream `vendor/.../services/Network.qml`.
- **Exposed Public Properties:**
  - `property bool isInspectorActive: false`
  - `property string activeInterface: ""`
  - `property string connectionType: "Unknown"` ("Ethernet", "Wi-Fi", "Disconnected")
  - `property bool isEthernet: false`
  - `property bool isWireless: false`
  - `property bool isConnected: false`
  - `property string materialSymbol: "wifi"`
  - `property real rxBytesPerSec: 0.0`
  - `property real txBytesPerSec: 0.0`
  - `property string rxRateString: "0 B/s"`
  - `property string txRateString: "0 B/s"`
  - `property string rxShortRate: "0K"`
  - `property string txShortRate: "0K"`
  - `property real totalRxBytes: 0`
  - `property real totalTxBytes: 0`
  - `property string totalRxString: "0.0 GB"`
  - `property string totalTxString: "0.0 GB"`
  - `property string ipAddress: "--"`
  - `property string gatewayIp: "--"`
  - `property string dnsServers: "--"`
  - `property string linkSpeed: "--"`
  - `property string macAddress: "--"`
  - `property var nicTemp: null`
  - `property string nicTempString: "--"`
  - `property int rxErrors: 0`
  - `property int txErrors: 0`
  - `property int rxDrops: 0`
  - `property int txDrops: 0`

---

### 5.2 Component: `NetworkPingPill.qml`

- **Location:** `restow/quickshell/.config/quickshell/ii/modules/ii/bar/NetworkPingPill.qml` [VERIFIED: 45-CONTEXT.md:108]
- **Base Type:** `BarGroup` [VERIFIED: restow/.../bar/CpuGpuPill.qml:10]
- **Pragmas:**
  ```qml
  pragma ComponentBehavior: Bound
  ```
- **Properties & Aliases:**
  ```qml
  property real useShortenedForm: 0
  readonly property alias hoverArea: pillMouseArea
  ```
- **Status Health Colors (D-02):**
  ```qml
  readonly property color warningColor: Appearance.colors.colWarning !== undefined ? Appearance.colors.colWarning : "#FFA000"

  function getStatusColor(statusClass) {
      if (statusClass === "good" || statusClass === "normal") return Appearance.colors.colPrimary;
      if (statusClass === "medium" || statusClass === "warning" || statusClass === "elevated") return root.warningColor;
      return Appearance.colors.colError;
  }
  ```
- **Click Launcher & Hover Anchor (D-14, D-16, D-17):**
  - Re-parented `MouseArea` covering the entire pill (`parent: root`, `anchors.fill: parent`).
  - Sets `cursorShape: Qt.PointingHandCursor`.
  - `onClicked: (mouse) => { if (mouse.button === Qt.LeftButton) { Quickshell.execDetached(["xdg-open", "http://127.0.0.1:8765/"]); } }`.
  - Press animation: subtle inner scale or opacity response `scale: pillMouseArea.pressed ? 0.97 : 1.0` with `Behavior on scale { NumberAnimation { duration: 100 } }`.
  - Embeds `NetworkPingPopup { hoverTarget: root.hoverArea }`.
- **Pill Visual Layout (D-01, D-02, D-03):**
  - **Segment 1 (Throughput):**
    - Material Symbol for active net connection: `NetworkUsage.isWireless ? (Network.materialSymbol || "wifi") : "lan"`, colored `Appearance.colors.colOnLayer1`.
    - Throughput text: `StyledText { text: `↓ ${NetworkUsage.rxShortRate}  ↑ ${NetworkUsage.txShortRate}`; font.pixelSize: Appearance.font.pixelSize.small; color: Appearance.colors.colOnLayer1 }`.
  - **Divider (D-03):**
    - Vertical line: `Rectangle { implicitWidth: 1; Layout.fillHeight: true; color: Appearance.colors.colLayer0Border; opacity: 0.6; Layout.leftMargin: 2; Layout.rightMargin: 2 }`.
  - **Segment 2 (3 Ping Targets):**
    - RowLayout with 3 target clusters:
      1. WAN: Material Symbol `public` + `StyledText { text: PingService.wanLatency }`, colored with `getStatusColor(PingService.wanStatus)`.
      2. Gateway: Material Symbol `router` + `StyledText { text: PingService.gatewayLatency }`, colored with `getStatusColor(PingService.gatewayStatus)`.
      3. Home Server: Material Symbol `dns` + `StyledText { text: PingService.homeServerLatency }`, colored with `getStatusColor(PingService.homeServerStatus)`.
- **Responsive Width Parity (D-04):**
  - Does NOT drop or collapse metrics when `useShortenedForm > 0`. Retains throughput rates and all 3 ping latencies to maintain 100% architectural parity with `CpuGpuPill` and `MemoryStoragePill`.

---

### 5.3 Component: `NetworkPingPopup.qml`

- **Location:** `restow/quickshell/.config/quickshell/ii/modules/ii/bar/NetworkPingPopup.qml` [VERIFIED: 45-CONTEXT.md:109]
- **Base Type:** `StyledPopup` [VERIFIED: restow/.../bar/CpuGpuPopup.qml:10]
- **Pragmas:**
  ```qml
  pragma ComponentBehavior: Bound
  ```
- **Lifecycle Fast-Polling Gating (D-12):**
  ```qml
  onActiveChanged: {
      NetworkUsage.isInspectorActive = active;
      if (active) {
          NetworkUsage.pollMetrics();
          NetworkUsage.refreshConfig();
          PingService.fetchStatus();
      }
  }
  Component.onDestruction: {
      if (active) NetworkUsage.isInspectorActive = false;
  }
  ```
- **Two-Column Symmetrical Layout (D-05):**
  - Overall popup container: RowLayout with `spacing: 16` and center vertical separator (`implicitWidth: 1`, `color: Appearance.colors.colLayer0Border`).
  - **Left Column (320px): Interface & Live Bandwidth Telemetry**
    1. Header: `StyledPopupHeaderRow { icon: NetworkUsage.materialSymbol; label: "Network Interface" }`.
    2. Interface Telemetry Sub-Card (Card Rectangle with `radius: Appearance.rounding.small`, `color: Appearance.m3colors.m3surfaceContainerHigh`, padding 10):
       - Active Interface Name: e.g. `wlp0s20f0u7 (Wi-Fi)` or `enp4s0 (Ethernet)`
       - Wi-Fi SSID & Signal Strength: visible when `NetworkUsage.isWireless` (e.g. `no internet (85%)`)
       - IP Address & CIDR Subnet: `NetworkUsage.ipAddress` (e.g. `192.168.0.103/24`)
       - Default Gateway: `NetworkUsage.gatewayIp` (e.g. `192.168.0.1`)
       - DNS Nameservers: `NetworkUsage.dnsServers` (e.g. `8.8.8.8, 8.8.4.4`)
       - Link Speed & Duplex: `NetworkUsage.linkSpeed` (e.g. `1000 Mbps Full Duplex` or `150 Mbps`)
       - MAC Address: `NetworkUsage.macAddress`
       - NIC Hardware Temperature: `NetworkUsage.nicTempString` (`37.5°C`) with `device_thermostat` icon
       - Packet Errors & Drops: `Rx: ${NetworkUsage.rxDrops}d / ${NetworkUsage.rxErrors}e  Tx: ${NetworkUsage.txDrops}d / ${NetworkUsage.txErrors}e`
    3. Dual Throughput Activity Meters (D-08):
       - Sub-heading: `Live Bandwidth Activity`
       - Rx Progress Meter:
         - Row with `arrow_downward` icon, `Rx Rate: ${NetworkUsage.rxRateString}`, and `Total: ${NetworkUsage.totalRxString}`
         - `StyledProgressBar` showing normalized throughput activity (adaptive rolling peak or 100 Mbps baseline)
       - Tx Progress Meter:
         - Row with `arrow_upward` icon, `Tx Rate: ${NetworkUsage.txRateString}`, and `Total: ${NetworkUsage.totalTxString}`
         - `StyledProgressBar` showing normalized throughput activity
  - **Right Column (320px): 3 Ping Diagnostic Cards & Action Button (D-07, D-09, D-15)**
    1. Header RowLayout:
       - Left: `StyledPopupHeaderRow { icon: "speed"; label: "Ping Telemetry" }`
       - Right: "Open Web Dashboard" button (D-15):
         - `Rectangle` with `radius: Appearance.rounding.circle`, `implicitWidth: 28`, `implicitHeight: 28`, hover highlight
         - Material Symbol `open_in_new` (size small, color `Appearance.colors.colPrimary`)
         - `PopupToolTip { text: "Open Web Dashboard"; extraVisibleCondition: btnMouse.containsMouse }`
         - `MouseArea { id: btnMouse; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["xdg-open", "http://127.0.0.1:8765/"]) }`
    2. Daemon Offline Banner (D-09):
       - Visible when `PingService.isOffline`:
         Rounded container with amber/red alert background, Material Symbol `cloud_off`, and text `"Ping Daemon Offline (http://127.0.0.1:8765)"`
    3. Dedicated Diagnostic Cards (3 cards for WAN, Gateway, Home Server):
       - Delegate / Component `PingDiagnosticCard`:
         - Card container: `Rectangle { radius: Appearance.rounding.small; color: Appearance.m3colors.m3surfaceContainerHigh; border.color: cardBorderColor; border.width: 1 }`
         - Header row: Target icon (`public` / `router` / `dns`), Title ("WAN (Google DNS)" / "Local Gateway" / "Home Server"), Spacer, Quality pill badge (`normal` green / `elevated` amber / `offline` red)
         - Latency readout: Prominent text (`PingService.wanLatency` / `gatewayLatency` / `homeServerLatency`) with `font.pixelSize: Appearance.font.pixelSize.large`, `font.weight: Font.Bold`, colored dynamically
         - Footer row: Host IP badge (`8.8.8.8` / `192.168.0.1` / `192.168.0.104`) in a subtle pill tag, and daemon status class label

---

## 6. Technology Stack & Key Dependencies

| Dependency | Purpose | Integration Details |
| :--- | :--- | :--- |
| **`PingService.qml`** | Local Ping Daemon HTTP Bridge | Singleton in `qs.services`, polls `http://127.0.0.1:8765/api/status` every 5s/15s, exposes `wanTarget`, `gatewayTarget`, `homeServerTarget`, `wanLatency`, `gatewayLatency`, `homeServerLatency`, `wanStatus`, `isOffline` [VERIFIED: restow/.../services/PingService.qml:7-91]. |
| **`Network.qml`** | Upstream Network & Wi-Fi Service | Singleton in `qs.services.network` / `qs.services`, provides `Network.networkName` (SSID), `Network.networkStrength` (%), `Network.materialSymbol`, `Network.wifiStatus` [VERIFIED: vendor/.../services/Network.qml:14-55]. |
| **`Quickshell.Io.FileView`** | High-performance virtual file reading | Synchronous kernel procfs reading (`/proc/net/dev`, `/etc/resolv.conf`, `/sys/class/hwmon/.../temp1_input`) without subprocess spawning overhead or file descriptor leaks [VERIFIED: restow/.../services/ResourceUsage.qml:127-128]. |
| **`Quickshell.Io.Process`** | Asynchronous system discovery | Non-blocking execution of `ip -j` or helper script at startup / 30s fallback, capturing standard output via `StdioCollector` [VERIFIED: restow/.../services/StorageUsage.qml:166-175]. |
| **`Appearance` Design Tokens** | Unified Material You theme tokens | `Appearance.colors.colPrimary`, `colWarning`, `colError`, `colOnLayer1`, `colLayer0Border`, `colSubtext`, `Appearance.m3colors.m3surfaceContainer`, `m3surfaceContainerHigh`, `Appearance.rounding.small`, `Appearance.font.pixelSize.*` [VERIFIED: restow/.../modules/ii/bar/MemoryStoragePopup.qml:55-62, 145-150]. |
| **Material Symbols Font** | Scalable vector glyphs | `MaterialSymbol` component with `public` (WAN), `router` (Gateway), `dns` (Home Server), `lan` (Ethernet), `wifi` (Wi-Fi), `open_in_new` (launcher), `speed` (latency), `device_thermostat` (NIC temp) [VERIFIED: live system font audit]. |
| **`StyledProgressBar`** | Linear progress bars | Used for live Rx and Tx bandwidth activity meters in popup [VERIFIED: vendor/.../widgets/StyledProgressBar.qml]. |
| **`StyledPopup`** | Universal popup container | Layer-shell overlay, 1000ms hover open delay, 200ms close grace period, screen edge boundary clamping [VERIFIED: restow/.../modules/ii/bar/StyledPopup.qml:11-182]. |

---

## 7. Common Pitfalls & Guardrails

### Pitfall 1: Blocking the Qt Quick Event Loop
- **Risk:** Spawning synchronous CLI commands (`ip`, `nmcli`, `iw`, or raw `ping`) or polling too frequently blocks the UI render thread, causing desktop stutter, dropped animations, and violating Quickshell performance budgets [VERIFIED: REQUIREMENTS.md:68-69].
- **Guardrail:** Throughput rates MUST be derived exclusively from `/proc/net/dev` via `FileView` reload. Raw ICMP ping spawning from QML is strictly prohibited; all ping telemetry is asynchronously gathered by the local ping daemon and queried via `PingService.qml` HTTP polling. Dynamic configuration queries (`ip`, `iw`) MUST run asynchronously via `Quickshell.Io.Process` on a 30s background cycle or demand-gated popup trigger.

### Pitfall 2: Handling Disconnected & Daemon Offline States Gracefully
- **Risk:** If the local ping daemon is stopped, times out, or returns malformed JSON, or if the network cable is unplugged and Wi-Fi disabled, unhandled exceptions or `undefined` property access will crash QML bindings or freeze the status bar.
- **Guardrail:** In `NetworkUsage.qml`, initialize all metrics with safe defaults (`ipAddress: "--"`, `gatewayIp: "--"`, `rxShortRate: "0K"`, `nicTemp: null`). In `PingService.qml`, `handleOffline()` guarantees fallback target objects (`{ host: "...", ms: null, text_value: "-- ms", class: "dead", quality: "offline" }`). In `NetworkPingPopup.qml`, display the D-09 offline warning banner and dim target cards without throwing errors.

### Pitfall 3: Linux Sysfs `speed` Throws `EINVAL` on Wireless and Down Links
- **Risk:** Reading `/sys/class/net/<iface>/speed` on wireless interfaces (`wlp0s20f0u7`) or disconnected interfaces (`enp4s0` when down) returns exit code 1 with `cat: Invalid argument` (EINVAL). Pointing a `FileView` directly to `/sys/class/net/wlp0s20f0u7/speed` produces errors [VERIFIED: live system audit].
- **Guardrail:** Only read `/sys/class/net/<iface>/speed` when `isEthernet` is true and `carrier == 1`. For Wi-Fi, obtain link bitrate from `iw dev <iface> link` or fallback gracefully to `"Wi-Fi Link"` or `"--"`. Always set `printErrors: false` on any sysfs `FileView`.

### Pitfall 4: Hwmon Device Index Instability Across Kernel Reboots
- **Risk:** Assuming Realtek `r8169` is permanently mapped to `hwmon4` will fail if a kernel update, USB device insertion, or module probe order shifts indices (e.g. `hwmon3` or `hwmon5`).
- **Guardrail:** Implement dynamic hwmon scanning at startup in `NetworkUsage.qml` (mirroring `HardwareTelemetry.qml` lines 48-75): scan `/sys/class/hwmon/hwmon*/name` for names matching `r8169*`, resolving the exact directory path dynamically before reading `temp1_input`. If no `r8169` sensor is found, gracefully fallback to `nicTemp: null` without failing.

### Pitfall 5: Popup Click-Through & Dismissal Prevention
- **Risk:** In `CpuGpuPill` and `MemoryStoragePill`, the re-parented `MouseArea` swallowed all clicks to prevent click-through. In `NetworkPingPill`, the user must be able to left-click to launch `http://127.0.0.1:8765/` (D-14), but clicking must NOT cause the popup to violently flash open and close or dismiss abruptly (D-16).
- **Guardrail:** In `NetworkPingPill`, `MouseArea.onClicked` launches `xdg-open` via `Quickshell.execDetached`. The `hoverTarget` of `StyledPopup` remains tied to `pillMouseArea`. Because the cursor remains within the pill bounds during the click, `containsMouse` remains true and the popup stays open as mandated by Decision D-16.

---

## 8. Validation Architecture

### 8.1 Verification Strategy
Validation follows the established test harness standard demonstrated by `scripts/phase44-memory-storage-assert.sh`: a modular, zero-dependency bash assertion script `scripts/phase45-network-ping-assert.sh` supporting targeted section execution (`[1-5]`), `--quick` static checks, and `--syntax` QML checks.

### 8.2 Test Script Specification: `scripts/phase45-network-ping-assert.sh`

```
Usage: ./scripts/phase45-network-ping-assert.sh [1-5] [--section <1-5>] [--quick] [--syntax]
Exit Code: 0 on success (FAIL=0, FINDINGS=0), 1 on any failure.
```

The script implements five rigorous verification sections:

#### Section 1: Telemetry Services & Ping Client (`NetworkUsage.qml`, `PingService.qml`)
- **Assert 1.1:** `NetworkUsage.qml` exists under `restow/quickshell/.../services/` and has valid syntax.
- **Assert 1.2:** `NetworkUsage.qml` contains required pragmas: `pragma Singleton` and `pragma ComponentBehavior: Bound`.
- **Assert 1.3:** `NetworkUsage.qml` implements adaptive polling interval (`isInspectorActive ? 1000 : 2000`) per D-12.
- **Assert 1.4:** `NetworkUsage.qml` uses `FileView` for `/proc/net/dev` with `printErrors: false` and `blockLoading: true`.
- **Assert 1.5:** `NetworkUsage.qml` implements Carrier Priority Hierarchy (prioritizing `en*`/`eth*` carrier=1 over `wl*`) per D-13.
- **Assert 1.6:** `NetworkUsage.qml` implements dynamic `r8169` hwmon scanning and NIC temperature parsing per D-06.
- **Assert 1.7:** `NetworkUsage.qml` exposes all required telemetry properties per D-11 (`activeInterface`, `ipAddress`, `gatewayIp`, `dnsServers`, `linkSpeed`, `macAddress`, `rxBytesPerSec`, `txBytesPerSec`, `rxDrops`, etc.).
- **Assert 1.8:** `PingService.qml` exists, targets `http://127.0.0.1:8765/api/status`, and maps all 3 target hosts (`8.8.8.8`, `192.168.0.1`, `192.168.0.104`) per NETPING-02/03.

#### Section 2: `NetworkPingPill.qml` Component Architecture
- **Assert 2.1:** `NetworkPingPill.qml` exists under `restow/quickshell/.../modules/ii/bar/` and has valid syntax.
- **Assert 2.2:** Root item is `BarGroup` and includes `pragma ComponentBehavior: Bound`.
- **Assert 2.3:** Exposes `property real useShortenedForm: 0` and maintains responsive width parity (retaining both throughput and all 3 ping latencies without dropping metrics) per D-04.
- **Assert 2.4:** Displays live throughput directional glyphs (`↓` and `↑`) with compact formatting per D-01.
- **Assert 2.5:** Displays all 3 ping targets with Material Symbols `public`, `router`, and `dns` per D-02.
- **Assert 2.6:** Implements dynamic health status colors (`colPrimary` for good/normal, amber warning for medium/warning, `colError` for dead/critical) per D-02.
- **Assert 2.7:** Implements vertical divider separating throughput segment from ping targets segment per D-03.
- **Assert 2.8:** Implements re-parented `MouseArea` exposing `readonly property alias hoverArea: pillMouseArea`.
- **Assert 2.9:** Pill click handler executes `Quickshell.execDetached(["xdg-open", "http://127.0.0.1:8765/"])` per D-14.
- **Assert 2.10:** Embeds `NetworkPingPopup { hoverTarget: root.hoverArea }`.

#### Section 3: `NetworkPingPopup.qml` Two-Column Inspector Overlay
- **Assert 3.1:** `NetworkPingPopup.qml` exists and inherits `StyledPopup`.
- **Assert 3.2:** Implements lifecycle fast-polling hook setting `NetworkUsage.isInspectorActive = active` on `activeChanged` and cleanup on destruction per D-12.
- **Assert 3.3:** Implements balanced two-column layout with 320px Left column and 320px Right column separated by 1px divider per D-05.
- **Assert 3.4:** Left column displays comprehensive interface card: interface name, connection type, IP/subnet, gateway, DNS, link speed, MAC, NIC temperature, and drop/error counts per D-11.
- **Assert 3.5:** Left column includes dual `StyledProgressBar` meters for Rx and Tx activity alongside rate readouts and cumulative session totals per D-08.
- **Assert 3.6:** Right column header includes "Open Web Dashboard" button with `open_in_new` icon, tooltip, and `xdg-open http://127.0.0.1:8765/` launcher per D-15.
- **Assert 3.7:** Right column displays offline warning banner when `PingService.isOffline` is true per D-09.
- **Assert 3.8:** Right column renders 3 dedicated diagnostic cards (WAN, Gateway, Home Server) with host titles, IP badges, latency readouts (ms), and quality pills per D-07.

#### Section 4: Live Telemetry & Formatting Mathematics
- **Assert 4.1:** Unit test formatting functions (`formatThroughput`, `formatShortRate`, `formatGigabytes`) with test cases: 0 B/s -> `0K`, 500 B/s -> `0K`, 1500 B/s -> `1K`, 1.5 MB/s -> `1.5M`, 1.2 GB/s -> `1.2G`.
- **Assert 4.2:** Live reading of `/proc/net/dev` confirms active interface has non-zero byte counters.
- **Assert 4.3:** Live query to `http://127.0.0.1:8765/api/status` returns valid JSON with 3 targets.
- **Assert 4.4:** Live query to Realtek `r8169` hwmon temp returns realistic integer (>20000 and <90000).

#### Section 5: Stow Symlink Integrity & Working Tree Verification
- **Assert 5.1:** `restow/quickshell/` contains new files as leaf symlinks without parent directory folding.
- **Assert 5.2:** `vendor/dots-hyprland` working tree remains 100% clean with zero modifications (`git status --porcelain` is empty).
- **Assert 5.3:** `./arch/dots-hyprland.sh verify --strict` completes with `FAIL=0 FINDINGS=0`.

---

## 9. Next Steps for Planning

With this research established:
1. **Plan Phase 45**: Decompose Phase 45 into structured tasks covering:
   - Task 1: Create `restow/.../services/NetworkUsage.qml` singleton service with procfs parsing, carrier detection, and adaptive polling.
   - Task 2: Create `restow/.../modules/ii/bar/NetworkPingPill.qml` with directional glyphs, divider, 3 ping targets, and click launcher.
   - Task 3: Create `restow/.../modules/ii/bar/NetworkPingPopup.qml` with balanced two-column layout, dual progress bars, 3 diagnostic cards, and dashboard launcher.
   - Task 4: Create automated assertion test harness `scripts/phase45-network-ping-assert.sh` enforcing all requirements and decisions.
   - Task 5: Run Stow deployment and verify zero drift under `./arch/dots-hyprland.sh verify --strict`.
2. Proceed to `/gsd-plan-phase` to generate `45-PLAN.md`.
