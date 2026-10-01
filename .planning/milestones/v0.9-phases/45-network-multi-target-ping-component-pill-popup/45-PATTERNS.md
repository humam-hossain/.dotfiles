# Phase 45: Network & Multi-Target Ping Component (Pill & Popup) - Pattern Map

**Gathered:** 2026-09-29  
**Phase:** 45 - network-multi-target-ping-component-pill-popup  
**Milestone:** v0.9 (Top Status Bar Resource Components & Hardware Telemetry)  
**Status:** Complete & Ready for Planning  

---

## 1. Executive Summary

This document establishes the authoritative architectural patterns, code blueprints, concrete code excerpts, and anti-pattern guardrails for Phase 45: **Network & Multi-Target Ping Telemetry Component** (`NetworkUsage.qml`, `NetworkPingPill.qml`, `NetworkPingPopup.qml`, and `scripts/phase45-network-ping-assert.sh`).

Following the design system and telemetry architectures established in Phase 42 (`HardwareTelemetry.qml`), Phase 43 (`CpuGpuPill.qml` / `CpuGpuPopup.qml`), and Phase 44 (`MemoryStoragePill.qml` / `MemoryStoragePopup.qml`), Phase 45 delivers:

1. **Status Bar Symmetry & Real-Time Throughput**: `NetworkPingPill.qml` provides compact, continuous network visibility partitioned by a vertical divider into two segments: local throughput using directional text glyphs (`↓ 1.2M  ↑ 45K` derived directly from `/proc/net/dev`) on the left, and all 3 ping latency targets (WAN `8.8.8.8`, Gateway `192.168.0.1`, Home Server `192.168.0.104`) on the right with distinct Material Symbols (`public`, `router`, `dns`) and dynamic health status colors (`good` = theme primary, `warning` = amber, `dead` = red).
2. **Balanced Two-Column Inspector Overlay**: `NetworkPingPopup.qml` matches the structural dimensions (320px Left, 320px Right) of `CpuGpuPopup` and `MemoryStoragePopup`. The Left column features active NIC interface telemetry, connection type, IP address/subnet mask, gateway, DNS servers, link speed/duplex, MAC address, NIC hardware temperature (Realtek `r8169`), packet drop/error counters, and dual `StyledProgressBar` activity meters for Rx and Tx alongside cumulative session totals. The Right column presents 3 dedicated ping diagnostic cards displaying target hostnames, IP badges, large latency numbers, quality pills, and daemon status classes, alongside a header action button to launch the web dashboard.
3. **Dedicated Telemetry Singleton (`NetworkUsage.qml`)**: Telemetry separation of concerns backed by a new singleton service `NetworkUsage.qml` in `restow/quickshell/.config/quickshell/ii/services/`. It performs sub-millisecond procfs reading of `/proc/net/dev` via `FileView`, carrier priority interface detection (`en*`/`eth*` carrier=1 prioritized over `wl*`), dynamic `r8169` hwmon temperature tracking, and an adaptive polling cadence (2000ms idle, 1000ms fast inspector polling).
4. **Direct Browser Dashboard Launching**: Left-clicking either the status bar pill or the explicit action button in the popup header launches the web ping dashboard at `http://127.0.0.1:8765/` in the default browser using non-blocking `Quickshell.execDetached(["xdg-open", "http://127.0.0.1:8765/"])` with Material press feedback, preserving popup visibility during launch.
5. **Zero Working Tree Drift**: Packaged strictly under `restow/quickshell/` using GNU Stow leaf symlinks, maintaining upstream `vendor/dots-hyprland` pristine and passing `./arch/dots-hyprland.sh verify --strict`.

Every planned component is mapped to authoritative analog files in the codebase with line numbers, property interfaces, pragmas, lifecycle bindings, and concrete implementation blueprints.

---

## 2. File Inventory & Classification

| File Path | Role | Data Flow | Closest Analog |
| :--- | :--- | :--- | :--- |
| `restow/quickshell/.config/quickshell/ii/services/NetworkUsage.qml` | Telemetry Singleton Service | Parses `/proc/net/dev` via `FileView` (1s/2s adaptive); executes asynchronous discovery process for IP/gateway/DNS/link/MAC; scans `r8169` hwmon | `restow/quickshell/.../services/ResourceUsage.qml`<br>`restow/quickshell/.../services/StorageUsage.qml`<br>`restow/quickshell/.../services/HardwareTelemetry.qml` |
| `restow/quickshell/.config/quickshell/ii/modules/ii/bar/NetworkPingPill.qml` | UI Component (Status Bar Widget) | Downward read-only bindings from `NetworkUsage` (Rx/Tx rates) and `PingService` (3 targets); hosts interactive MouseArea anchor | `restow/quickshell/.../bar/CpuGpuPill.qml`<br>`restow/quickshell/.../bar/MemoryStoragePill.qml` |
| `restow/quickshell/.config/quickshell/ii/modules/ii/bar/NetworkPingPopup.qml` | UI Component (Overlay Inspector) | Bidirectional lifecycle gating with `NetworkUsage.isInspectorActive`; reads detailed interface card, throughput meters, and 3 ping cards | `restow/quickshell/.../bar/CpuGpuPopup.qml`<br>`restow/quickshell/.../bar/MemoryStoragePopup.qml` |
| `scripts/phase45-network-ping-assert.sh` | Quality Assertion Test Suite | CLI test harness validating AST, properties, syntax, Stow symlinks, live kernel metrics, and `./arch/dots-hyprland.sh verify --strict` | `scripts/phase44-memory-storage-assert.sh` |

---

## 3. Per-File Pattern Assignments

### 3.1 `NetworkUsage.qml`

- **Target File:** `restow/quickshell/.config/quickshell/ii/services/NetworkUsage.qml`
- **Role:** Dedicated singleton service providing sub-millisecond procfs network throughput calculation, carrier priority interface selection, system network configuration discovery, and NIC hardware temperature tracking.
- **Data Flow:**
  - **Procfs Reading (`/proc/net/dev`):** High-frequency polling timer (2000ms idle, 1000ms active) reloads `FileView` for `/proc/net/dev`. Parses `rx_bytes`, `tx_bytes`, `rx_errs`, `rx_drop`, `tx_errs`, `tx_drop` for `activeInterface`.
  - **Rate Delta Calculation:** Computes $\Delta Rx / dt$ and $\Delta Tx / dt$, emitting `rxBytesPerSec`, `txBytesPerSec`, `rxRateString`, `txRateString`, `rxShortRate`, `txShortRate`, `totalRxBytes`, `totalTxBytes`, `totalRxString`, `totalTxString`.
  - **NIC Hardware Temperature (`hwmon`):** Scans `/sys/class/hwmon/hwmon*/name` at startup matching `r8169*`. Binds `FileView` to `hwmonNicPath + "/temp1_input"`, converting millidegrees C to degrees C (`nicTempString`).
  - **Interface Configuration Discovery:** Runs lightweight asynchronous `Process` with bash script at startup, on `refreshConfig()`, and periodically on a 30s background timer to discover `activeInterface` (Carrier Priority), `connectionType`, `ipAddress`, `gatewayIp`, `dnsServers`, `linkSpeed`, `macAddress`.
  - **Wi-Fi Synchronization:** When `isWireless` is true, syncs with upstream `Network.qml` (`networkName` and `networkStrength`).
- **Closest Analogs:**
  - `restow/quickshell/.config/quickshell/ii/services/ResourceUsage.qml` [ResourceUsage.qml:1-146](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/services/ResourceUsage.qml#L1-L146) (Singleton structure, `FileView` virtual file observers, adaptive polling cadence)
  - `restow/quickshell/.config/quickshell/ii/services/StorageUsage.qml` [StorageUsage.qml:1-239](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/services/StorageUsage.qml#L1-L239) (Procfs delta rate math, asynchronous helper `Process` with `StdioCollector`, throughput string formatting)
  - `restow/quickshell/.config/quickshell/ii/services/HardwareTelemetry.qml` [HardwareTelemetry.qml:48-75](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/services/HardwareTelemetry.qml#L48-L75) (Dynamic `/sys/class/hwmon` scanning and device path resolution)

#### Architectural Blueprint & Patterns to Copy

1. **Pragmas & Base Type:**
   Must declare `pragma Singleton` and `pragma ComponentBehavior: Bound`. Root element is `Singleton`.
2. **Adaptive Polling Cadence (D-12):**
   ```qml
   property bool isInspectorActive: false

   Timer {
       id: pollTimer
       interval: root.isInspectorActive ? 1000 : 2000
       repeat: true
       running: true
       onTriggered: root.pollMetrics()
   }
   ```
3. **Dynamic NIC Hardware Temperature Resolution (D-06):**
   Dynamic scan of `/sys/class/hwmon/hwmon*` discovering `r8169_0_400:00` without hardcoding `hwmon4`:
   ```qml
   property string hwmonNicPath: ""
   property var nicTemp: null
   property string nicTempString: "--"

   Process {
       id: hwmonDiscoveryProc
       running: true
       command: ["bash", "-c", "for h in /sys/class/hwmon/hwmon*; do [ -f \"$h/name\" ] && echo \"$(cat $h/name 2>/dev/null):$h\"; done"]
       stdout: StdioCollector {
           onStreamFinished: {
               const lines = text.trim().split("\n");
               for (let i = 0; i < lines.length; i++) {
                   const parts = lines[i].split(":");
                   if (parts.length === 2 && parts[0].trim().startsWith("r8169")) {
                       root.hwmonNicPath = parts[1].trim();
                       break;
                   }
               }
           }
       }
   }

   FileView {
       id: fileNicTemp
       path: root.hwmonNicPath ? (root.hwmonNicPath + "/temp1_input") : ""
       printErrors: false
       blockLoading: true
   }
   ```
4. **Carrier Priority Interface Detection (D-13):**
   Examining `/sys/class/net/*/carrier`:
   - Rule 1: Prioritize physical Ethernet (`en*`/`eth*`) if carrier == 1 and operstate == "up".
   - Rule 2: If Ethernet carrier == 0 or unplugged, check wireless (`wl*`); if carrier == 1 or operstate == "up", select Wireless.
   - Rule 3: Fall back to interface associated with the default IPv4 route (`ip route show default`).
   - Ignores virtual interfaces (`lo`, `docker*`, `veth*`, `br-*`, `virbr*`, `tailscale*`, `tun*`, `tap*`, `wg*`).
5. **Procfs Throughput Rate Calculation & Auto-Scaling Formatting (D-01, D-11):**
   Reads `/proc/net/dev` without subprocess overhead. Line format:
   `iface: rx_bytes rx_packets rx_errs rx_drop ... tx_bytes tx_packets tx_errs tx_drop ...`
   Extracts `rxErrors`, `rxDrops`, `txErrors`, `txDrops`.

#### Concrete Code Excerpts from Analogs

```qml
// restow/quickshell/.config/quickshell/ii/services/ResourceUsage.qml:1-16, 117-128
pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool isInspectorActive: false

    Timer {
        id: pollTimer
        interval: root.isInspectorActive ? 1000 : 2000
        running: true 
        repeat: true
        onTriggered: root.pollMetrics()
    }

    FileView { id: fileNetDev; path: "/proc/net/dev"; printErrors: false; blockLoading: true }
}
```

```qml
// restow/quickshell/.config/quickshell/ii/services/HardwareTelemetry.qml:48-75
// One-shot dynamic device resolver at startup
Process {
    id: hwmonDiscoveryProc
    running: true
    command: ["bash", "-c", "for h in /sys/class/hwmon/hwmon*; do [ -f \"$h/name\" ] && echo \"$(cat $h/name 2>/dev/null):$h\"; done"]
    stdout: StdioCollector {
        onStreamFinished: {
            const lines = text.trim().split("\n");
            for (let i = 0; i < lines.length; i++) {
                const parts = lines[i].split(":");
                if (parts.length === 2) {
                    const name = parts[0].trim();
                    const path = parts[1].trim();
                    if (name.startsWith("r8169")) {
                        root.hwmonNicPath = path;
                        break;
                    }
                }
            }
        }
    }
}
```

```javascript
// Rate math and formatting helper implementations
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

---

### 3.2 `NetworkPingPill.qml`

- **Target File:** `restow/quickshell/.config/quickshell/ii/modules/ii/bar/NetworkPingPill.qml`
- **Role:** Status bar telemetry pill widget in the top bar left zone.
- **Data Flow:**
  - Reads `NetworkUsage.rxShortRate` and `NetworkUsage.txShortRate` for directional bandwidth glyphs.
  - Reads `PingService.wanLatency`, `wanStatus`, `gatewayLatency`, `gatewayStatus`, `homeServerLatency`, `homeServerStatus`.
  - Maps `statusClass` (`good` / `medium` / `dead`) to theme colors via `getStatusColor()`.
  - Re-parents interactive `MouseArea` to `root` to trigger browser launch on left click (`Quickshell.execDetached(["xdg-open", "http://127.0.0.1:8765/"])`) and serve as `hoverTarget` for `NetworkPingPopup`.
- **Closest Analogs:**
  - `restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPill.qml` [CpuGpuPill.qml:1-120](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPill.qml#L1-L120) (Base type `BarGroup`, bound pragma, re-parented `MouseArea`, popup anchoring, dynamic warningColor fallback)
  - `restow/quickshell/.config/quickshell/ii/modules/ii/bar/MemoryStoragePill.qml` [MemoryStoragePill.qml:1-53](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/ii/bar/MemoryStoragePill.qml#L1-L53) (BarGroup root, `useShortenedForm` responsive width parity, `hoverArea` alias)

#### Architectural Blueprint & Patterns to Copy

1. **Pragma & Base Component:**
   Must declare `pragma ComponentBehavior: Bound` and inherit `BarGroup` as root.
2. **Interactive Re-parented MouseArea with Browser Launcher (D-14, D-16, D-17):**
   Because `BarGroup` aliases default children into `gridLayout.children`, the `MouseArea` MUST declare `parent: root` and `anchors.fill: parent`. It sets `cursorShape: Qt.PointingHandCursor` and intercepts left clicks to launch `http://127.0.0.1:8765/`:
   ```qml
   readonly property alias hoverArea: pillMouseArea

   MouseArea {
       id: pillMouseArea
       parent: root
       anchors.fill: parent
       acceptedButtons: Qt.AllButtons
       cursorShape: Qt.PointingHandCursor
       hoverEnabled: true

       onClicked: (mouse) => {
           if (mouse.button === Qt.LeftButton) {
               Quickshell.execDetached(["xdg-open", "http://127.0.0.1:8765/"]);
           }
       }

       NetworkPingPopup {
           hoverTarget: root.hoverArea
       }
   }
   ```
3. **Subtle Press Animation Feedback (D-17):**
   Subtle scale compression when pressed:
   `scale: pillMouseArea.pressed ? 0.97 : 1.0` with `Behavior on scale { NumberAnimation { duration: 100 } }`.
4. **Pill Internal Partitioning (D-03):**
   Visual structure: `[Segment 1: Net Icon + Throughput] | [Segment 2: 3 Ping Targets]`
   - Segment 1:
     - Material Symbol: `NetworkUsage.materialSymbol` (e.g. `wifi` or `lan`), `color: Appearance.colors.colOnLayer1`.
     - Live throughput text (D-01): `StyledText { text: `↓ ${NetworkUsage.rxShortRate}  ↑ ${NetworkUsage.txShortRate}`; font.pixelSize: Appearance.font.pixelSize.small; color: Appearance.colors.colOnLayer1 }`.
   - Divider (D-03):
     - Vertical separator: `Rectangle { implicitWidth: 1; Layout.fillHeight: true; color: Appearance.colors.colLayer0Border; opacity: 0.6; Layout.leftMargin: 3; Layout.rightMargin: 3 }`.
   - Segment 2 (D-02):
     - WAN cluster: Material Symbol `public` + `StyledText { text: PingService.wanLatency; color: root.getStatusColor(PingService.wanStatus) }`.
     - Gateway cluster: Material Symbol `router` + `StyledText { text: PingService.gatewayLatency; color: root.getStatusColor(PingService.gatewayStatus); Layout.leftMargin: 3 }`.
     - Home Server cluster: Material Symbol `dns` + `StyledText { text: PingService.homeServerLatency; color: root.getStatusColor(PingService.homeServerStatus); Layout.leftMargin: 3 }`.
5. **Responsive Width Parity (D-04):**
   `property real useShortenedForm: 0`. Maintains full fidelity across all screen widths (`useShortenedForm > 0`), retaining both throughput rates and all 3 ping latencies without dropping metrics or squishing text.
6. **Dynamic Status Health Colors (D-02):**
   ```qml
   readonly property color warningColor: Appearance.colors.colWarning !== undefined ? Appearance.colors.colWarning : "#FFA000"

   function getStatusColor(statusClass) {
       if (statusClass === "good" || statusClass === "normal") return Appearance.colors.colPrimary;
       if (statusClass === "medium" || statusClass === "warning" || statusClass === "elevated") return root.warningColor;
       return Appearance.colors.colError;
   }
   ```

#### Concrete Code Excerpts from Analogs

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
    readonly property alias hoverArea: pillMouseArea

    readonly property color warningColor: Appearance.colors.colWarning !== undefined ? Appearance.colors.colWarning : "#FFA000"

    function getStatusColor(statusClass) {
        if (statusClass === "good" || statusClass === "normal") return Appearance.colors.colPrimary;
        if (statusClass === "medium" || statusClass === "warning" || statusClass === "elevated") return root.warningColor;
        return Appearance.colors.colError;
    }

    MouseArea {
        id: pillMouseArea
        parent: root
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true

        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                Quickshell.execDetached(["xdg-open", "http://127.0.0.1:8765/"]);
            }
        }

        NetworkPingPopup {
            hoverTarget: root.hoverArea
        }
    }
```

---

### 3.3 `NetworkPingPopup.qml`

- **Target File:** `restow/quickshell/.config/quickshell/ii/modules/ii/bar/NetworkPingPopup.qml`
- **Role:** Interactive two-column inspector popup window overlay anchored to `NetworkPingPill.qml`.
- **Data Flow:**
  - Manages demand-gated fast-polling: accelerates `NetworkUsage` polling to 1000ms (`isInspectorActive = true`), calls `NetworkUsage.pollMetrics()`, `NetworkUsage.refreshConfig()`, and `PingService.fetchStatus()` on activation. Restores 2000ms idle cadence on close.
  - Left Column reads `NetworkUsage` telemetry: active interface, connection type, Wi-Fi SSID/signal, IP/subnet, gateway, DNS, link speed/duplex, MAC address, NIC temp, packet drops/errors, and Rx/Tx live rates with cumulative totals.
  - Right Column reads `PingService` telemetry: `wanTarget`, `gatewayTarget`, `homeServerTarget`, and `isOffline` banner.
  - Action button triggers non-blocking browser launch to `http://127.0.0.1:8765/` via `Quickshell.execDetached`.
- **Closest Analogs:**
  - `restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPopup.qml` [CpuGpuPopup.qml:1-52, 162-280](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPopup.qml#L1-L52) (Base type `StyledPopup`, bound pragma, lifecycle fast-polling hook, balanced two-column 320px layout, center vertical separator)
  - `restow/quickshell/.config/quickshell/ii/modules/ii/bar/MemoryStoragePopup.qml` [MemoryStoragePopup.qml:1-66, 141-260, 340-385](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/ii/bar/MemoryStoragePopup.qml#L1-L66) (Dual 320px column layout, `StyledProgressBar`, header row with throughput badge `arrow_downward` / `arrow_upward`, sub-cards, formatting helper functions)
  - `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/StyledPopupHeaderRow.qml` [StyledPopupHeaderRow.qml:1-30](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/StyledPopupHeaderRow.qml#L1-L30) (Standardized column header with icon and title)

#### Architectural Blueprint & Patterns to Copy

1. **Base Type & Bound Pragma:**
   Must declare `pragma ComponentBehavior: Bound` and inherit `StyledPopup` as root.
2. **Lifecycle Gating (D-12):**
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
       if (active) {
           NetworkUsage.isInspectorActive = false;
       }
   }
   ```
3. **Two-Column Balanced Architecture (D-05):**
   `RowLayout { id: popupContent; anchors.centerIn: parent; spacing: 16 }`
   - Left Column: `ColumnLayout { Layout.preferredWidth: 320; spacing: 8 }` (Interface & Bandwidth Inspector).
   - Center Vertical Separator: `Rectangle { Layout.fillHeight: true; implicitWidth: 1; color: Appearance.colors.colLayer0Border }`.
   - Right Column: `ColumnLayout { Layout.preferredWidth: 320; spacing: 8 }` (Ping Diagnostic Cards & Dashboard Launcher).
4. **Left Column (Interface & Bandwidth) Hierarchy (D-08, D-11):**
   - Header: `StyledPopupHeaderRow { icon: NetworkUsage.materialSymbol; label: "Network Interface" }`
   - Interface Details Card (`Rectangle { Layout.fillWidth: true; radius: Appearance.rounding.small; color: Appearance.m3colors.m3surfaceContainerHigh; ... }`):
     - Key-value rows (`component NetworkDetailRow: RowLayout`):
       - Interface: `${NetworkUsage.activeInterface} (${NetworkUsage.connectionType})`
       - Wi-Fi Details: `${NetworkUsage.wifiSsid} (${NetworkUsage.wifiSignal}%)` (visible when `NetworkUsage.isWireless`)
       - IP Address: `NetworkUsage.ipAddress`
       - Default Gateway: `NetworkUsage.gatewayIp`
       - DNS Servers: `NetworkUsage.dnsServers`
       - Link Speed: `NetworkUsage.linkSpeed`
       - MAC Address: `NetworkUsage.macAddress`
       - NIC Temp (D-06): `NetworkUsage.nicTempString` with `device_thermostat` icon
       - Drops / Errors: `Rx: ${NetworkUsage.rxDrops}d / ${NetworkUsage.rxErrors}e  Tx: ${NetworkUsage.txDrops}d / ${NetworkUsage.txErrors}e`
   - Horizontal separator: `Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Appearance.colors.colLayer0Border }`
   - Bandwidth Activity Section (D-08):
     - Sub-heading: `StyledText { text: "Live Bandwidth Activity"; font.pixelSize: Appearance.font.pixelSize.smaller; font.weight: Font.Medium; color: Appearance.colors.colOnSurfaceVariant }`
     - Rx Progress Meter:
       - Header row: `MaterialSymbol { text: "arrow_downward" }`, `StyledText { text: "Rx Rate: " + NetworkUsage.rxRateString }`, Spacer, `StyledText { text: "Total: " + NetworkUsage.totalRxString }`
       - `StyledProgressBar { Layout.fillWidth: true; value: Math.min(1.0, NetworkUsage.rxBytesPerSec / (10 * 1024 * 1024)); highlightColor: Appearance.colors.colPrimary }`
     - Tx Progress Meter:
       - Header row: `MaterialSymbol { text: "arrow_upward" }`, `StyledText { text: "Tx Rate: " + NetworkUsage.txRateString }`, Spacer, `StyledText { text: "Total: " + NetworkUsage.totalTxString }`
       - `StyledProgressBar { Layout.fillWidth: true; value: Math.min(1.0, NetworkUsage.txBytesPerSec / (10 * 1024 * 1024)); highlightColor: Appearance.colors.colSecondary !== undefined ? Appearance.colors.colSecondary : Appearance.colors.colPrimary }`
5. **Right Column (Ping Telemetry & Cards) Hierarchy (D-07, D-09, D-15):**
   - Header Row:
     - Left: `StyledPopupHeaderRow { icon: "speed"; label: "Ping Telemetry" }`
     - Spacer: `Item { Layout.fillWidth: true }`
     - Right: Action Button "Open Web Dashboard" (D-15):
       ```qml
       Rectangle {
           id: btnDashboard
           implicitWidth: 28
           implicitHeight: 28
           radius: Appearance.rounding.circle
           color: btnMouse.containsMouse ? Appearance.colors.colLayer1Hover : "transparent"

           MaterialSymbol {
               anchors.centerIn: parent
               text: "open_in_new"
               iconSize: Appearance.font.pixelSize.small
               color: Appearance.colors.colPrimary
           }

           PopupToolTip {
               text: "Open Web Dashboard (http://127.0.0.1:8765/)"
               extraVisibleCondition: btnMouse.containsMouse
           }

           MouseArea {
               id: btnMouse
               anchors.fill: parent
               cursorShape: Qt.PointingHandCursor
               hoverEnabled: true
               onClicked: {
                   Quickshell.execDetached(["xdg-open", "http://127.0.0.1:8765/"]);
               }
           }
       }
       ```
   - Offline Alert Banner (D-09):
     Visible when `PingService.isOffline`:
     `Rectangle { Layout.fillWidth: true; radius: Appearance.rounding.small; color: Appearance.colors.colError; opacity: 0.2; ... }` with Material Symbol `cloud_off` and `"Ping Daemon Offline (http://127.0.0.1:8765)"`.
   - Dedicated Ping Diagnostic Cards (D-07):
     Three dedicated cards for WAN (`8.8.8.8`), Gateway (`192.168.0.1`), and Home Server (`192.168.0.104`).
     Sub-component `PingDiagnosticCard`:
     - Container: `Rectangle { radius: Appearance.rounding.small; color: Appearance.m3colors.m3surfaceContainerHigh; border.color: cardBorderColor; border.width: 1; opacity: PingService.isOffline ? 0.6 : 1.0 }`
     - Header row: Target icon (`public` / `router` / `dns`), Target Title ("WAN (Google DNS)" / "Local Gateway" / "Home Server"), Spacer, Quality badge pill (`normal` green / `elevated` amber / `offline` red).
     - Center latency readout: Large prominent text (`PingService.wanLatency` / `gatewayLatency` / `homeServerLatency`), `font.pixelSize: Appearance.font.pixelSize.large`, `font.weight: Font.Bold`, colored dynamically.
     - Footer row: Host IP pill badge (`8.8.8.8` / `192.168.0.1` / `192.168.0.104`) and daemon status class label (`PingService.wanStatus` / `gatewayStatus` / `homeServerStatus`).

#### Concrete Code Excerpts from Analogs

```qml
// restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPopup.qml:162-266
// Balanced Two-Column Proportions (320px Left, 320px Right):
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

```qml
// Sub-component PingDiagnosticCard blueprint
component PingDiagnosticCard: Rectangle {
    id: diagCard
    required property string iconName
    required property string title
    required property string hostIp
    required property string latencyText
    required property string qualityText
    required property string statusClass
    required property color statusColor

    Layout.fillWidth: true
    radius: Appearance.rounding.small
    color: Appearance.m3colors.m3surfaceContainerHigh
    border.color: diagCard.statusColor
    border.width: 1
    opacity: PingService.isOffline ? 0.6 : 1.0

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            MaterialSymbol {
                text: diagCard.iconName
                iconSize: Appearance.font.pixelSize.normal
                color: diagCard.statusColor
            }

            StyledText {
                text: diagCard.title
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnSurfaceVariant
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                implicitHeight: 18
                implicitWidth: qualityLabel.implicitWidth + 10
                radius: Appearance.rounding.circle
                color: diagCard.statusColor
                opacity: 0.2

                StyledText {
                    id: qualityLabel
                    anchors.centerIn: parent
                    text: diagCard.qualityText
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    font.weight: Font.DemiBold
                    color: diagCard.statusColor
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            StyledText {
                text: diagCard.latencyText
                font.pixelSize: Appearance.font.pixelSize.large
                font.weight: Font.Bold
                color: diagCard.statusColor
            }
            Item { Layout.fillWidth: true }
            StyledText {
                text: diagCard.hostIp
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
            }
        }
    }
}
```

---

### 3.4 `scripts/phase45-network-ping-assert.sh`

- **Target File:** `scripts/phase45-network-ping-assert.sh`
- **Role:** Comprehensive automated assertion harness validating requirements NETPING-01..05 and decisions D-01..D-17.
- **Closest Analog:** `scripts/phase44-memory-storage-assert.sh` [phase44-memory-storage-assert.sh:1-534](file:///home/pera/github_repo/.dotfiles/scripts/phase44-memory-storage-assert.sh#L1-L534)

#### Assertion Structure to Replicate

1. **CLI Interface & Options:**
   - Positional section argument `[1-5]`, `--section|-s <1-5>`, `--quick|-q`, `--syntax|-c`, `-h|--help`.
   - Non-root validation, `set -euo pipefail`.
   - Temporary file array `TMP_FILES` with trap cleanup on `EXIT INT TERM`.
   - Helper functions: `pass()`, `fail()`, `finding()`, `info()`.
2. **Section 1: Telemetry Services & Ping Client (`NetworkUsage.qml`, `PingService.qml`):**
   - Validates existence of `NetworkUsage.qml` and `PingService.qml`.
   - Validates `pragma Singleton` and `pragma ComponentBehavior: Bound` in `NetworkUsage.qml`.
   - Validates adaptive polling cadence (`isInspectorActive ? 1000 : 2000`) per D-12.
   - Validates `FileView` for `/proc/net/dev` with `printErrors: false` and `blockLoading: true`.
   - Validates Carrier Priority Hierarchy (`en*`/`eth*` carrier=1 prioritized over `wl*`) per D-13.
   - Validates dynamic `r8169` hwmon scanning and NIC temperature parsing per D-06.
   - Validates exposed telemetry properties per D-11 (`activeInterface`, `ipAddress`, `gatewayIp`, `dnsServers`, `linkSpeed`, `macAddress`, `rxBytesPerSec`, `txBytesPerSec`, `rxDrops`, etc.).
   - Validates `PingService.qml` endpoint `http://127.0.0.1:8765/api/status` and 3 targets (`8.8.8.8`, `192.168.0.1`, `192.168.0.104`).
3. **Section 2: `NetworkPingPill.qml` Component Architecture:**
   - Base type `BarGroup` and `pragma ComponentBehavior: Bound`.
   - Re-parented `MouseArea` (`parent: root`, `anchors.fill: parent`, `acceptedButtons: Qt.AllButtons`).
   - Exports `readonly property alias hoverArea: pillMouseArea`.
   - Implements direct left-click browser launch via `Quickshell.execDetached(["xdg-open", "http://127.0.0.1:8765/"])` per D-14.
   - Displays live throughput directional glyphs (`↓` and `↑`) with compact short rate formatting per D-01.
   - Displays all 3 ping targets with Material Symbols `public`, `router`, and `dns` per D-02.
   - Dynamic health status colors (`colPrimary` for good, amber warning for medium/warning, `colError` for dead/critical).
   - Vertical divider line separating throughput segment from ping targets per D-03.
   - Responsive width parity: preserves throughput and all 3 ping latencies unconditionally regardless of `useShortenedForm` per D-04.
   - Embeds `NetworkPingPopup { hoverTarget: root.hoverArea }`.
4. **Section 3: `NetworkPingPopup.qml` Two-Column Inspector Overlay:**
   - Base type `StyledPopup` and `pragma ComponentBehavior: Bound`.
   - Lifecycle fast-polling gating: sets `NetworkUsage.isInspectorActive = active` on `activeChanged` and cleans up on destruction per D-12.
   - Balanced two-column 320px architecture (`Layout.preferredWidth: 320` count >= 2, center vertical separator) per D-05.
   - Left column comprehensive interface card (interface, connection type, IP/subnet, gateway, DNS, link speed, MAC, NIC temp, errors/drops) per D-11.
   - Left column dual `StyledProgressBar` meters for Rx and Tx activity alongside cumulative session totals per D-08.
   - Right column header includes "Open Web Dashboard" button with `open_in_new` MaterialSymbol and `xdg-open` launcher per D-15.
   - Right column displays offline warning banner when `PingService.isOffline` is true per D-09.
   - Right column renders 3 dedicated diagnostic cards (WAN, Gateway, Home Server) with titles, IP badges, latency readouts (ms), and quality pills per D-07.
5. **Section 4: Live Telemetry & Formatting Mathematics:**
   - Unit tests throughput formatting math (`formatThroughput`, `formatShortRate`, `formatGigabytes`).
   - Live query of `/proc/net/dev` verifies non-zero byte counters for active interface.
   - Live query to local daemon at `http://127.0.0.1:8765/api/status` returns valid JSON with 3 targets.
   - Live query to Realtek `r8169` hwmon temp returns realistic millidegree integer (>20000 and <90000).
   - Prohibited hardcoded alert hex colors check across QML files.
6. **Section 5: Stow Symlink Integrity & Working Tree Verification:**
   - Validates symlinks exist in `${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/...`.
   - Verifies `vendor/dots-hyprland` working tree remains 100% clean with zero modifications (`git status --porcelain` is empty).
   - Verifies `./arch/dots-hyprland.sh verify --strict` completes cleanly with `FAIL=0 FINDINGS=0`.

---

## 4. Anti-Patterns & Pitfalls to Avoid

### 4.1 Spawning Subprocesses for Throughput Calculations
- **Anti-Pattern:** Running `sar -n DEV`, `bmon`, `vnstat`, or `ip -s link` on high-frequency timers to calculate network rates.
- **Why it breaks:** Spawning processes every 1–2 seconds creates continuous fork/exec churn, triggers desktop stutter, spikes CPU wakeups, and violates the Quickshell performance budget.
- **Correct Pattern:** Read `/proc/net/dev` directly via `FileView.reload()` and calculate deltas in JavaScript. Procfs reads execute in <1ms directly in kernel virtual memory.

### 4.2 Spawning Raw ICMP Ping Commands from QML
- **Anti-Pattern:** Invoking `Process { command: ["ping", "-c", "1", "8.8.8.8"] }` from QML.
- **Why it breaks:** Raw `ping` spawning from QML is explicitly prohibited [REQUIREMENTS.md:68]. ICMP ping operations can hang or block when packets are dropped, creating zombie processes and desynchronizing UI states.
- **Correct Pattern:** All ping latency telemetry is exclusively collected by the dedicated background Python system monitor daemon on port 8765 and queried via `PingService.qml` HTTP polling.

### 4.3 Reading Sysfs `speed` on Wireless or Disconnected Links
- **Anti-Pattern:** Binding `FileView` unconditionally to `/sys/class/net/<iface>/speed` without checking interface type.
- **Why it breaks:** Linux kernel sysfs throws `EINVAL` (Invalid argument, exit code 1) when reading `/speed` on wireless interfaces (`wlp*`) or down links (`enp4s0` when unplugged).
- **Correct Pattern:** Only read `/sys/class/net/<iface>/speed` when `isEthernet` is true and `carrier == 1`. For Wi-Fi, obtain link bitrate via `iw dev <iface> link` or fallback gracefully to `"Wi-Fi Link"` or `"--"`. Always set `printErrors: false` on sysfs `FileView` observers.

### 4.4 Hardcoding Realtek Hwmon Path
- **Anti-Pattern:** Assuming `hwmon4` is always the Realtek `r8169` network controller.
- **Why it breaks:** Linux kernel hwmon enumeration depends on module load order and hardware probe timing. Following a kernel update or device insertion, `r8169` could become `hwmon3` or `hwmon5`.
- **Correct Pattern:** Dynamically resolve the device path at startup by scanning `/sys/class/hwmon/hwmon*/name` for `r8169*` (mirroring `HardwareTelemetry.qml` lines 48-75). If not found, gracefully set `nicTemp: null` without throwing errors.

### 4.5 Abrupt Popup Dismissal on Pill Click
- **Anti-Pattern:** Re-closing or destroying the popup when the pill is clicked to open the browser dashboard.
- **Why it breaks:** The user wants to see the popup while deciding to inspect further or open the browser; clicking the pill should launch `xdg-open` without causing the popup to flash or disappear violently.
- **Correct Pattern:** `MouseArea.onClicked` launches `Quickshell.execDetached(["xdg-open", "http://127.0.0.1:8765/"])`. Because the cursor remains inside the pill's hover boundary, `hoverTarget.containsMouse` remains true and `StyledPopup` remains visible until the pointer exits the hover area.

### 4.6 Omitting `parent: root` on `MouseArea` in `BarGroup`
- **Anti-Pattern:** Placing `MouseArea` inside `BarGroup` without `parent: root`.
- **Why it breaks:** `BarGroup` exposes `default property alias items: gridLayout.children`. Any child without `parent: root` is treated as a grid item, squishing adjacent icons and failing to cover the entire pill surface.
- **Correct Pattern:** Always specify `parent: root` and `anchors.fill: parent` on `pillMouseArea`.

### 4.7 Hardcoding Prohibited Alert Hex Colors
- **Anti-Pattern:** Using hardcoded hex strings like `"#FF0000"`, `"#FF5555"`, or `"#00FF00"`.
- **Why it breaks:** Breaks Material You dynamic theming and fails automated test verification.
- **Correct Pattern:** Use `Appearance.colors.colPrimary` (good/normal), `warningColor` with `#FFA000` fallback (warning/elevated), and `Appearance.colors.colError` (dead/critical).

---

## 5. Summary Table

| Component | Target File | Base Type | Pragmas | Key Features & Responsibilities | Closest Analog |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **NetworkUsage** | `restow/.../services/NetworkUsage.qml` | `Singleton` | `pragma Singleton`<br>`pragma ComponentBehavior: Bound` | `/proc/net/dev` FileView delta parsing; Carrier Priority interface selection; dynamic `r8169` hwmon temp; 1s/2s adaptive polling | `ResourceUsage.qml`<br>`StorageUsage.qml`<br>`HardwareTelemetry.qml` |
| **NetworkPingPill** | `restow/.../bar/NetworkPingPill.qml` | `BarGroup` | `pragma ComponentBehavior: Bound` | `[Net Icon + Throughput] \| [3 Ping Targets]`; directional glyphs (`↓ 1.2M ↑ 45K`); dynamic health status colors; re-parented MouseArea with left-click browser launch; responsive width parity | `CpuGpuPill.qml`<br>`MemoryStoragePill.qml` |
| **NetworkPingPopup** | `restow/.../bar/NetworkPingPopup.qml` | `StyledPopup` | `pragma ComponentBehavior: Bound` | Symmetrical 320px two-column inspector; Left: active interface card, NIC temp, dual `StyledProgressBar` meters, session totals; Right: header action button (`open_in_new`), offline alert banner, 3 ping diagnostic cards | `CpuGpuPopup.qml`<br>`MemoryStoragePopup.qml` |
| **Test Harness** | `scripts/phase45-network-ping-assert.sh` | Bash Script | `set -euo pipefail` | 5-section validation: Services, Pill, Popup, Formatting/Live Kernel, Stow/Upstream Cleanliness; options `[1-5]`, `--quick`, `--syntax` | `scripts/phase44-memory-storage-assert.sh` |

---

*Pattern Map Completed: 2026-09-29*  
*Author: Phase 45 Pattern Mapper Agent*
