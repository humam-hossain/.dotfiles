# Phase 45: Network & Multi-Target Ping Component (Pill & Popup) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-29
**Phase:** 45-network-multi-target-ping-component-pill-popup
**Areas discussed:** Pill Layout & Ping Presentation, Popup Inspector Architecture & Diagnostics, Network Telemetry Service & Interface Detection, Click Interaction & Dashboard Launching

---

## Pill Layout & Ping Presentation

| Option | Description | Selected |
|--------|-------------|----------|
| Directional text glyphs (↓ 1.2M  ↑ 45K) | Clean and space-efficient text readouts matching Waybar and desktop net status conventions | ✓ |
| Circular progress rings | Twin mini rings for Rx and Tx matching CpuGpuPill/MemoryStoragePill circular ring aesthetic | |
| You decide | Select the representation that best balances visual symmetry and compact status bar space | |

**User's choice:** Directional text glyphs (↓ 1.2M  ↑ 45K)
**Notes:** Provides maximum readability while avoiding visual clutter alongside the circular rings of CpuGpuPill and MemoryStoragePill.

| Option | Description | Selected |
|--------|-------------|----------|
| Distinct target icons with latency numbers | Material/Nerd symbols for WAN, Gateway, Server with latency colored by target health | ✓ |
| Compact letter prefixes with colored latency | Ultra-clean single-letter prefixes with quality-colored numbers | |
| Status dots with numeric latency | Minimalist colored status dots next to each target latency | |
| You decide | Pick whichever fits most comfortably within the status bar pill without crowding | |

**User's choice:** Distinct target Material icons with latency numbers colored by target health (`public` for WAN, `router` for Gateway, `dns` for Server).
**Notes:** User specifically emphasized using standard Material symbols.

| Option | Description | Selected |
|--------|-------------|----------|
| Two visual segments with a subtle vertical divider | [Net Icon + Throughput] \| [3 Ping Targets] — Clear partition between bandwidth metrics and latency telemetry | ✓ |
| Unified horizontal row with even spacing | Seamless single flow without explicit divider lines | |
| You decide | Match the internal spacing and divider conventions of CpuGpuPill and MemoryStoragePill | |

**User's choice:** Two visual segments with a subtle vertical divider: `[Net Icon + Throughput] | [3 Ping Targets]`.
**Notes:** Creates clean logical partitioning between local I/O bandwidth and remote latency telemetry.

| Option | Description | Selected |
|--------|-------------|----------|
| Full fidelity across all widths (no dropping metrics) | Retain both throughput rates and all 3 ping latencies even when useShortenedForm > 0 (100% parity with CpuGpuPill/MemoryStoragePill) | ✓ |
| Adaptive ping compaction on useShortenedForm > 0 | Display throughput and primary WAN ping only when screen space is constricted | |
| You decide | Maintain legibility while ensuring the Center Workspaces widget remains uncrowded | |

**User's choice:** Full fidelity across all widths (no dropping metrics) — Retain both throughput rates and all 3 ping latencies even when `useShortenedForm > 0`.
**Notes:** Preserves consistent behavior and parity across all status bar pills without layout squishing.

---

## Popup Inspector Architecture & Diagnostics

| Option | Description | Selected |
|--------|-------------|----------|
| Balanced two-column layout | Left column = Interface & Live Bandwidth, Right column = 3 Ping Diagnostic Cards | ✓ |
| Stacked single-column layout | Top section for Interface & Bandwidth, Bottom section for 3 Ping Diagnostic Cards | |
| You decide | Maintain exact visual parity with CpuGpuPopup and MemoryStoragePopup card styling | |

**User's choice:** Balanced two-column layout (Interface/Bandwidth on Left, 3 Ping Cards on Right) with NIC temperature explicitly added to the Left column.
**Notes:** Hardware NIC temp confirmed available on the system at `/sys/class/hwmon/hwmon4/temp1_input` (`r8169_0_400:00` Realtek Ethernet).

| Option | Description | Selected |
|--------|-------------|----------|
| Dedicated target cards with rich diagnostics | Card per target with icon, host/IP badge, prominent latency readout, quality badge ('good' / 'warning' / 'offline'), and daemon status class | ✓ |
| Compact row-based table | Clean 3-row diagnostic table showing Target, IP, Latency, and Status in aligned columns | |
| You decide | Design target cards that mirror the metric card conventions in CpuGpuPopup and MemoryStoragePopup | |

**User's choice:** Dedicated target cards with rich diagnostics.
**Notes:** Each host card gives high-fidelity diagnostic insight into latency, quality tier, and daemon class.

| Option | Description | Selected |
|--------|-------------|----------|
| Dual StyledProgressBars with live rates & session totals | Visual Rx and Tx activity bars alongside live speeds (KB/MB/s) and cumulative session bandwidth (Rx/Tx GB) | ✓ |
| Metric typography rows only | Clean numeric rows for interface details, rates, and totals without progress bars | |
| You decide | Choose the layout that best complements the Storage throughput card in MemoryStoragePopup | |

**User's choice:** Dual StyledProgressBars with live rates & session totals.
**Notes:** Visual activity bars complement the Storage throughput card in `MemoryStoragePopup.qml`.

| Option | Description | Selected |
|--------|-------------|----------|
| Warning banner + dimmed cards with offline badge | Banner indicating daemon or network state with cards displaying '-- ms' and muted/alert styling | ✓ |
| Minimal inline placeholder text | Cards simply show '-- ms' and 'Offline' badges without extra banner headers | |
| You decide | Graceful fallback consistent with PingService offline state handling | |

**User's choice:** Warning banner + dimmed cards with offline badge.
**Notes:** Clear visual feedback whenever network connectivity is lost or the local daemon (`http://127.0.0.1:8765/api/status`) is offline.

---

## Network Telemetry Service & Interface Detection

| Option | Description | Selected |
|--------|-------------|----------|
| Dedicated singleton NetworkUsage.qml in services/ | Clean separation of concerns (StorageUsage/ResourceUsage pattern), exposing activeInterface, rxSpeed, txSpeed, rxTotal, txTotal, ipAddress, linkSpeed, and nicTemp | ✓ |
| Extend PingService.qml | Consolidate local ping daemon client and system network interface telemetry into a single service | |
| You decide | Choose the architecture that minimizes code churn and maximizes maintainability | |

**User's choice:** Dedicated singleton `NetworkUsage.qml` in `services/`.
**Notes:** User requested maximum network telemetry detail in the popup inspector.

| Field Selection | Selected |
|-----------------|----------|
| Interface name & Connection type | ✓ |
| Wi-Fi SSID & Signal Strength | ✓ |
| Local IPv4 Address & Subnet | ✓ |
| Default Gateway IP | ✓ |
| DNS Nameservers | ✓ |
| Link Speed & Duplex | ✓ |
| NIC Hardware Temperature (r8169) | ✓ |
| MAC Hardware Address | ✓ |
| Live Bandwidth Rates & Session Totals | ✓ |
| Packet Error / Drop Statistics | ✓ |

**User's choice:** User selected all network telemetry fields for inclusion in `NetworkUsage.qml` and `NetworkPingPopup.qml`.

| Option | Description | Selected |
|--------|-------------|----------|
| Adaptive Cadence (2000ms idle / 1000ms fast) | Consistent with ResourceUsage & HardwareTelemetry, keeping idle CPU footprint negligible | ✓ |
| Continuous 1000ms sampling | Constant 1s throughput updates on the bar pill at all times | |
| You decide | Tune timer intervals according to Quickshell performance budget | |

**User's choice:** Adaptive Cadence: 2000ms idle background sampling / 1000ms fast sampling when popup is open (`isInspectorActive`).
**Notes:** Preserves Quickshell performance budget established in Phase 43.1-43.4.

| Option | Description | Selected |
|--------|-------------|----------|
| Default Gateway Route Auto-Detection | Detect active egress interface via routing table (/proc/net/route or ip route get 1.1.1.1) | |
| Carrier priority hierarchy (Ethernet first, then Wi-Fi) | Check /sys/class/net/*/carrier and select Ethernet if plugged in, otherwise fallback to Wi-Fi, filtering virtual bridges | ✓ |
| You decide | Choose the most resilient auto-detection approach requiring zero manual configuration | |

**User's choice:** Carrier priority hierarchy (Ethernet first, then Wi-Fi).
**Notes:** Checks `/sys/class/net/*/carrier` to select active physical interface automatically.

---

## Click Interaction & Dashboard Launching

| Option | Description | Selected |
|--------|-------------|----------|
| Left-click pill opens web dashboard | Clicking status bar pill directly executes 'xdg-open http://127.0.0.1:8765/' in default browser; hover triggers popup | ✓ |
| Popup-only launch button | Left-clicking pill toggles/focuses popup; action button in popup launches browser | |
| Middle-click on pill opens web dashboard | Left-click reserved for popup inspection, middle-click dedicated to opening browser | |

**User's choice:** Left-click pill opens web dashboard (`xdg-open http://127.0.0.1:8765/`), hovering triggers popup.
**Notes:** Direct, rapid access to full ping dashboard.

| Option | Description | Selected |
|--------|-------------|----------|
| Header action button with icon & tooltip | 'Open Web Dashboard' action button with 'open_in_new' icon in Ping card header | ✓ |
| Bottom full-width action bar | Prominent action button at the bottom of the popup spanning ping card | |
| Clickable ping cards + header button | Both header button and clicking directly on any ping card opens dashboard | |

**User's choice:** Header action button with icon & tooltip in Ping card header.
**Notes:** Clear, discoverable entry point within the popup inspector.

| Option | Description | Selected |
|--------|-------------|----------|
| Close popup immediately upon launching browser | Dismiss popup overlay as soon as browser is spawned | |
| Keep popup open until mouse leaves | Allow popup to remain visible until standard 200ms close grace period or pointer exit | ✓ |
| You decide | Follow cleanest windowing ergonomics in Hyprland | |

**User's choice:** Keep popup open until mouse leaves / pointer exit.
**Notes:** Avoids jarring popup flickering on click.

| Option | Description | Selected |
|--------|-------------|----------|
| Quickshell.execDetached with click ripple / press feedback | Non-blocking detached process spawn with Material press animation feedback | ✓ |
| Simple Quickshell.execDetached without animation | Standard detached spawn with immediate execution and no extra animations | |
| You decide | Match established button interaction patterns in Quickshell common widgets | |

**User's choice:** `Quickshell.execDetached` with subtle click ripple / press feedback.
**Notes:** Zero event loop blocking with visual confirmation of action.

---

## the agent's Discretion

- Exact scaling ceiling and formula for Rx/Tx activity progress bars (relative to link speed or rolling peak).
- Fallback placeholders when DNS or Wi-Fi fields are empty or unavailable.
- Exact MaterialSymbol icon choices for WiFi (`wifi`) vs Ethernet (`lan`), WAN (`public`), Gateway (`router`), and Home Server (`dns`).

## Deferred Ideas

- Phase 46: Integration of all 3 pills into `BarContent.qml` Left Zone and automated test harness (`scripts/phase46-telemetry-assert.sh`).
