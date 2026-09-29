# Phase 45: Network & Multi-Target Ping Component (Pill & Popup) - Context

**Gathered:** 2026-09-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Build dedicated `NetworkPingPill.qml` status bar pill and interactive `NetworkPingPopup.qml` inspector overlay. The pill displays real-time throughput rates (Rx/Tx) and all 3 ping targets (WAN `8.8.8.8`, Gateway `192.168.0.1`, Home Server `192.168.0.104`) with latency numbers and status colors. The popup inspector displays active NIC interface details, IPv4 address, link speed, NIC temperature, live bandwidth activity meters, and detailed 3-target ping diagnostic cards. Left-clicking the pill or popup action button launches the web ping dashboard at `http://127.0.0.1:8765/` in the default browser. Backed by a dedicated `NetworkUsage.qml` singleton service and existing `PingService.qml`.

Integration into `BarContent.qml` Left Zone and automated test harness are deferred to Phase 46.

</domain>

<decisions>
## Implementation Decisions

### Pill Layout & Ping Presentation

- **D-01 (Throughput Representation):** Live network throughput (Rx / Tx) is visually represented using space-efficient directional text glyphs (e.g. `↓ 1.2M  ↑ 45K`), providing clear and compact bandwidth visibility matching Waybar and desktop net status conventions. — **Reversibility:** reversible
- **D-02 (Ping Targets Formatting):** All 3 ping targets (WAN `8.8.8.8`, Gateway `192.168.0.1`, Home Server `192.168.0.104`) are displayed with distinct MaterialSymbols (`public` for WAN, `router` for Gateway, `dns` for Server) accompanied by numeric latency values (ms) colored dynamically by target health status (`good` = theme primary/green, `bad`/`warning` = amber, `dead`/`critical` = red). — **Reversibility:** reversible
- **D-03 (Pill Internal Partitioning):** The pill is partitioned into two clear visual segments separated by a subtle vertical divider line: `[Net Icon + Throughput] | [3 Ping Targets]`, cleanly separating local I/O bandwidth from external latency telemetry. — **Reversibility:** reversible
- **D-04 (Responsive Width Parity):** NetworkPingPill maintains full fidelity across all screen widths (`useShortenedForm > 0`), retaining both throughput rates and all 3 ping latencies without dropping metrics or squishing text, ensuring 100% architectural parity with `CpuGpuPill` and `MemoryStoragePill`. — **Reversibility:** reversible

### Popup Inspector Architecture & Diagnostics

- **D-05 (Balanced Two-Column Architecture):** Arrange `NetworkPingPopup.qml` in a balanced two-column layout matching the width and structural proportions of `CpuGpuPopup` and `MemoryStoragePopup`: Left column for Interface & Live Bandwidth, Right column for 3 Ping Diagnostic Cards. — **Reversibility:** reversible
- **D-06 (NIC Hardware Temperature):** Include real-time NIC hardware temperature in the Left column of the popup inspector, sourced from `/sys/class/hwmon/hwmon4/temp1_input` (`r8169_0_400:00` Realtek Ethernet controller) with graceful fallback if the sensor file is absent. — **Reversibility:** reversible
- **D-07 (Dedicated Target Cards with Rich Diagnostics):** Right column presents dedicated diagnostic cards for WAN, Gateway, and Home Server. Each card displays target icon, host title, IP badge, prominent latency readout (ms), quality pill ('good' / 'warning' / 'offline'), and daemon status class. — **Reversibility:** reversible
- **D-08 (Dual Throughput Progress Bars):** Left column features dual `StyledProgressBar` meters for visual Rx and Tx throughput activity (scaled dynamically or against link speed) alongside live rate readouts (KB/MB/s) and cumulative session bandwidth totals (Rx/Tx GB). — **Reversibility:** reversible
- **D-09 (Offline State Presentation):** When the ping daemon is unreachable (`http://127.0.0.1:8765/api/status` offline/timeout) or the network is disconnected, display a prominent warning banner at the top of the ping column, dimming target cards to show last known or `-- ms` with muted/alert status styling. — **Reversibility:** reversible

### Network Telemetry Service & Interface Detection

- **D-10 (Dedicated Singleton Service):** Create a dedicated singleton `NetworkUsage.qml` in `restow/quickshell/.config/quickshell/ii/services/`, cleanly separating concerns following the established `StorageUsage.qml` and `ResourceUsage.qml` architecture. — **Reversibility:** costly — changing service structure later touches multiple imports across pill, popup, and verify scripts.
- **D-11 (Comprehensive Telemetry Field Suite):** `NetworkUsage.qml` and the popup inspector capture and expose the full suite of network metrics:
  1. Active interface name & connection type (Ethernet or Wi-Fi)
  2. Wi-Fi SSID & Signal Strength (when connected wirelessly via `Network.qml`)
  3. Local IPv4 address & CIDR subnet mask (e.g. `192.168.0.50/24`)
  4. Default Gateway IP (e.g. `192.168.0.1`)
  5. DNS Nameservers (parsed from `/etc/resolv.conf`)
  6. Link Speed & Duplex (e.g. `1000 Mbps Full Duplex` from `/sys/class/net/<iface>/speed`)
  7. NIC Hardware Temperature (from `r8169` hwmon with fallback)
  8. MAC Hardware Address (`/sys/class/net/<iface>/address`)
  9. Live Throughput Rates (Rx/Tx KB/MB/s) & Session Totals (Rx/Tx GB)
  10. Packet Error & Drop counts (`/proc/net/dev`) — **Reversibility:** reversible
- **D-12 (Adaptive Polling Cadence):** `NetworkUsage.qml` runs at an adaptive cadence: 2000ms idle background sampling (minimizing CPU wakeups per Quickshell performance budget) and boosts to 1000ms fast sampling when the popup inspector is open (`isInspectorActive = true`). — **Reversibility:** reversible
- **D-13 (Carrier Priority Interface Detection):** Select the primary network interface using a Carrier Priority Hierarchy: Check `/sys/class/net/*/carrier` and prioritize physical Ethernet (`enp*`/`eth*`) if carrier=1; if unplugged, fall back to wireless (`wlan*`), filtering out virtual interfaces, bridges, and docker networks. — **Reversibility:** reversible

### Click Interaction & Dashboard Launching

- **D-14 (Direct Pill Left-Click Launcher):** Left-clicking the status bar pill directly launches the web ping dashboard at `http://127.0.0.1:8765/` in the default browser using `Quickshell.execDetached(["xdg-open", "http://127.0.0.1:8765/"])`. Hovering continues to trigger the popup inspector overlay. — **Reversibility:** reversible
- **D-15 (Popup Header Action Button):** The Ping column header in `NetworkPingPopup.qml` includes an explicit "Open Web Dashboard" action button featuring the `open_in_new` MaterialSymbol icon and tooltip, triggering `xdg-open http://127.0.0.1:8765/`. — **Reversibility:** reversible
- **D-16 (Popup Visibility on Click):** Clicking the pill or popup action button to launch the browser does not abruptly dismiss the popup; the popup remains visible until the user moves the pointer out of the hover area or the standard 200ms close grace period elapses. — **Reversibility:** reversible
- **D-17 (Non-Blocking Spawn & Visual Feedback):** Launching `xdg-open` is executed via `Quickshell.execDetached` to guarantee zero event loop stalls, accompanied by a subtle Material-style press animation / click ripple feedback. — **Reversibility:** reversible

### the agent's Discretion

- Exact threshold math and dynamic scale ceiling for the dual Rx/Tx progress bars in the popup.
- Exact MaterialSymbol icon choices for WiFi (`wifi`) vs Ethernet (`lan`), WAN (`public`), Gateway (`router`), and Home Server (`dns`).
- Graceful formatting and placeholder strings when DNS or Wi-Fi fields are empty or unavailable.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Services & Telemetry Providers
- `restow/quickshell/.config/quickshell/ii/services/PingService.qml` — Singleton service polling `http://127.0.0.1:8765/api/status` at 5s/15s cadence, exposing targets model, latency, and classes
- `vendor/dots-hyprland/dots/.config/quickshell/ii/services/Network.qml` — Upstream Network singleton providing nmcli integration, Wi-Fi SSID, signal strength, and network status
- `restow/quickshell/.config/quickshell/ii/services/ResourceUsage.qml` — Singleton reference for `/proc` parsing, FileView, and demand-gated fast polling
- `restow/quickshell/.config/quickshell/ii/services/StorageUsage.qml` — Singleton reference for throughput formatting and async Process execution

### Shell UI Blueprints & Design Tokens
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPill.qml` — Reference pill architecture (BarGroup, alert tokens, pulse animation, and hoverArea anchor)
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/MemoryStoragePill.qml` — Reference pill architecture (BarGroup, responsive width parity, inert MouseArea anchor)
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPopup.qml` — Reference popup architecture (two-column layout, card framing, MetricProgressRow, demand-gated fast polling)
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/MemoryStoragePopup.qml` — Reference popup architecture (two-column card layout, StyledProgressBar, metric rows)
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/StyledPopup.qml` — Universal popup window, layer-shell placement, 1000ms hover delay, and 200ms close grace period

### Requirements & Roadmap
- `.planning/ROADMAP.md` §Phase 45 — Network & Multi-Target Ping Component (Pill & Popup)
- `.planning/REQUIREMENTS.md` §Network & Multi-Target Ping Telemetry — Formal requirements NETPING-01..05

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `StyledPopup`: Universal popup container with layer-shell anchoring, 1000ms hover delay, and 200ms close grace period
- `StyledProgressBar`: Linear progress bar component with theme-aware styling
- `StyledText`: Typography component adhering to Material 3 tokens
- `MaterialSymbol`: Vector icons (`public`, `router`, `dns`, `lan`, `wifi`, `open_in_new`, `speed`, `device_thermostat`)
- `BarGroup`: Container for status bar pills with standard padding and margins
- `PingService`: Global singleton already polling local system monitor daemon at `http://127.0.0.1:8765/api/status`

### Established Patterns
- **Inert MouseArea Anchor**: Pill contains a MouseArea that handles hover tracking for `StyledPopup` and captures left-clicks to execute external browser launch via `Quickshell.execDetached`.
- **Demand-Gated Fast Polling**: Popup inspector sets `NetworkUsage.isInspectorActive = active` on `activeChanged`, boosting sampling rate from 2000ms to 1000ms.
- **Two-Tier Threshold Alerts**: Warning state (amber) at >=70%, Critical state (red) at >=90% with breathing pulse animation cycling opacity between 0.4 and 1.0.
- **Material 3 Token Resolution**: Uses `Appearance.colors.colPrimary`, `Appearance.colors.colOnLayer1`, `Appearance.colors.colWarning`, and `Appearance.colors.colError`.

### Integration Points
- `restow/quickshell/.config/quickshell/ii/services/NetworkUsage.qml`: New singleton service to be instantiated and exposed via `qs.services`
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/NetworkPingPill.qml`: New bar pill component in `qs.modules.ii.bar`
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/NetworkPingPopup.qml`: New inspector overlay anchored to `NetworkPingPill`

</code_context>

<specifics>
## Specific Ideas

- **NIC Hardware Temperature Discovery**: Sourced directly from `/sys/class/hwmon/hwmon4/temp1_input` (Realtek `r8169_0_400:00` Gigabit Ethernet) with dynamic scanning across `/sys/class/hwmon/` for `r8169*` or network hwmon devices so it is resilient to kernel hwmon re-enumeration.
- **Comprehensive Network Inspector**: The user explicitly requested an exhaustive network telemetry card in the popup displaying: Interface name & type, Wi-Fi SSID & Signal Strength, IPv4 address/subnet, Gateway IP, DNS servers, Link Speed/Duplex, NIC Temp, MAC address, Rx/Tx live rates & session totals, and Packet Drops/Errors.
- **Direct Pill Left-Click Action**: Clicking the pill immediately launches `http://127.0.0.1:8765/` in the default browser via `xdg-open` without closing the popup, while hovering opens the inspector.

</specifics>

<deferred>
## Deferred Ideas

- **Phase 46 (Left-Zone Integration & Automated Assertion Harness)**:
  - Integration of `NetworkPingPill.qml` alongside `CpuGpuPill.qml` and `MemoryStoragePill.qml` in `BarContent.qml` Left Zone.
  - Comprehensive automated assertion harness (`scripts/phase46-telemetry-assert.sh`) testing all telemetry services, bar components, and verification against zero git churn.

</deferred>

---

*Phase: 45-network-multi-target-ping-component-pill-popup*
*Context gathered: 2026-09-29*
