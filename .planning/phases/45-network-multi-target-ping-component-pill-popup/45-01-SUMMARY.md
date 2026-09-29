---
phase: "45"
plan: "01"
subsystem: network-ping-telemetry
tags: [quickshell, qml, telemetry, network, ping, pill, test-harness]

requires:
  - phase: 44-memory-storage-component-pill-popup
    provides: Status bar pill and popup component architectural patterns
provides:
  - Wave 0 test harness scripts/phase45-network-ping-assert.sh
  - Dedicated NetworkUsage.qml telemetry singleton service
  - Top status bar NetworkPingPill.qml widget with directional throughput and 3 ping targets
affects: [45-02]

actuals:
  tokens: 45000
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns: [Directional Glyph Throughput, Carrier Priority Interface Selection, Vertical Divider Partitioning, Dynamic Health Status Colors, Re-parented MouseArea Browser Launcher]

key-files:
  created:
    - scripts/phase45-network-ping-assert.sh
    - restow/quickshell/.config/quickshell/ii/services/NetworkUsage.qml
    - restow/quickshell/.config/quickshell/ii/modules/ii/bar/NetworkPingPill.qml
  modified: []

key-decisions:
  - "D-01: Live throughput formatted compactly using directional text glyphs (↓ and ↑) with auto-scaling units (K, M, G)."
  - "D-02: All 3 ping targets (WAN, Gateway, Home Server) rendered with Material Symbols public, router, dns and dynamic health status colors."
  - "D-03: Status bar pill partitioned by a vertical divider separating local bandwidth throughput from ping targets."
  - "D-04: Full fidelity maintained across screen widths without dropping metrics when useShortenedForm > 0."
  - "D-06: Dynamic Realtek r8169 hwmon temperature scanning across /sys/class/hwmon with graceful fallback."
  - "D-10: Clean architectural separation via dedicated NetworkUsage.qml singleton service."
  - "D-11: Exposes complete suite of 27 public telemetry properties."
  - "D-12: Adaptive polling interval running at 2000ms idle and 1000ms fast inspector polling."
  - "D-13: Carrier Priority Hierarchy prioritizes physical Ethernet (en*/eth*) over Wi-Fi (wl*), filtering virtual interfaces."
  - "D-14: Left-clicking status bar pill launches web dashboard at http://127.0.0.1:8765/ via Quickshell.execDetached."
  - "D-17: Subtle press feedback animation on pill mouse area."

requirements-completed:
  - NETPING-01
  - NETPING-02
  - NETPING-03
  - NETPING-05

duration: 10 min
completed: 2026-09-29
status: complete
---

# Phase 45 Plan 01: Wave 0 Test Harness, Telemetry Service & Status Bar Pill Widget Summary

**Established automated assertion suite `scripts/phase45-network-ping-assert.sh`, implemented dedicated singleton telemetry service `NetworkUsage.qml`, and built top status bar `NetworkPingPill.qml` widget.**

## Performance & Execution Metrics

- **Duration:** 10 min
- **Completed:** 2026-09-29
- **Tasks:** 3
- **Files created:** 3 (`scripts/phase45-network-ping-assert.sh`, `NetworkUsage.qml`, `NetworkPingPill.qml`)
- **Files modified:** 0
- **Commits:** `10f70ea1`, `814ad33b`, `5810766c`

## Accomplishments

1. **Created Wave 0 Assertion Suite (`scripts/phase45-network-ping-assert.sh`):**
   - Implemented 5 test sections covering telemetry services and ping client, status bar pill component logic, popup layout and diagnostics, live telemetry math & hardware probes, and GNU Stow symlink integrity.
   - Enforced root fail-closed execution (`EUID == 0`), `--quick`, `--syntax`, positional selectors `1-5`, and `--section`.

2. **Built Dedicated Telemetry Service (`NetworkUsage.qml`):**
   - Singleton service declaring `pragma Singleton` and `pragma ComponentBehavior: Bound`.
   - Sub-millisecond procfs throughput delta parsing of `/proc/net/dev` via `FileView` without blocking the event loop.
   - Adaptive polling interval (2000ms idle, 1000ms when `isInspectorActive` is true).
   - Carrier Priority Hierarchy selecting physical Ethernet (`en*`/`eth*`) with `carrier=1` and `operstate=up` over Wi-Fi (`wl*`), ignoring virtual/docker/bridge interfaces.
   - Dynamic discovery of Realtek `r8169` NIC temperature via `/sys/class/hwmon` with graceful fallback.
   - Full public telemetry suite including IP/subnet, default gateway, DNS servers, link speed, MAC address, session totals, and drop/error counters.

3. **Built Top Status Bar Widget (`NetworkPingPill.qml`):**
   - Inherits `BarGroup` as root and declares `pragma ComponentBehavior: Bound`.
   - Re-parented interactive `MouseArea` covering root (`parent: root`, `anchors.fill: parent`, `acceptedButtons: Qt.AllButtons`, `cursorShape: Qt.PointingHandCursor`).
   - Left-click handler launching `http://127.0.0.1:8765/` in default browser via non-blocking `Quickshell.execDetached(["xdg-open", ...])` with scale press feedback animation.
   - Clean partitioning via vertical divider line separating directional throughput (`↓ 1.2M  ↑ 45K`) from all 3 ping latency targets (WAN `8.8.8.8`, Gateway `192.168.0.1`, Home Server `192.168.0.104`).
   - Dynamic health status colors using Material You primary, warning color (`#FFA000` fallback), and error color.
   - Responsive width parity preserving both throughput and all 3 ping latencies unconditionally regardless of `useShortenedForm`.

## Verification Results

- `scripts/phase45-network-ping-assert.sh 1` PASSED: All service assertions verified.
- `scripts/phase45-network-ping-assert.sh 2` PASSED: All status bar pill assertions verified.
- `scripts/phase45-network-ping-assert.sh 4` PASSED: Formatting mathematics and live hardware probes verified.

## Self-Check: PASSED
- [x] scripts/phase45-network-ping-assert.sh exists and is executable
- [x] restow/quickshell/.config/quickshell/ii/services/NetworkUsage.qml verified
- [x] restow/quickshell/.config/quickshell/ii/modules/ii/bar/NetworkPingPill.qml verified
- [x] Commits `10f70ea1`, `814ad33b`, `5810766c` present in git history
