---
phase: "45"
plan: "02"
subsystem: network-ping-telemetry
tags: [quickshell, qml, telemetry, network, ping, popup, stow]

requires:
  - phase: 45-01
    provides: NetworkUsage service and NetworkPingPill widget
provides:
  - Two-column interactive inspector overlay NetworkPingPopup.qml
  - Left column comprehensive interface card with Realtek r8169 NIC temp and dual Rx/Tx activity meters
  - Right column header with web dashboard launcher button, offline alert banner, and 3 dedicated ping diagnostic cards
  - Anchoring of NetworkPingPopup to NetworkPingPill hoverArea
  - Verified GNU Stow leaf symlinks in ~/.config/quickshell/ii/services/ and ~/.config/quickshell/ii/modules/ii/bar/
affects: []

actuals:
  tokens: 50000
  tasks: 2
  commits: 1

tech-stack:
  added: []
  patterns: [Two-Column Overlay Layout, Demand-Gated Fast Polling, Diagnostic Quality Cards, Leaf Symlink Deployment]

key-files:
  created:
    - restow/quickshell/.config/quickshell/ii/modules/ii/bar/NetworkPingPopup.qml
  modified:
    - restow/quickshell/.config/quickshell/ii/modules/ii/bar/NetworkPingPill.qml

key-decisions:
  - "D-05: NetworkPingPopup.qml arranged in a balanced two-column layout (320px Left, 320px Right) matching CpuGpuPopup and MemoryStoragePopup proportions."
  - "D-06: Left column features real-time NIC temperature sourced dynamically from Realtek r8169 hwmon."
  - "D-07: Right column renders 3 dedicated diagnostic cards (WAN, Gateway, Home Server) with target icons, host titles, IP badges, large latency readouts, and quality pills."
  - "D-08: Left column features dual StyledProgressBar meters for Rx and Tx activity alongside live rate readouts and cumulative session totals."
  - "D-09: Prominent offline warning banner displayed in ping column when PingService.isOffline is true."
  - "D-12: Demand-gated fast-polling: accelerates NetworkUsage to 1000ms cadence, immediately calls pollMetrics(), refreshConfig(), PingService.fetchStatus(), and restores idle cadence on close and destruction."
  - "D-15: Ping column header includes an explicit Open Web Dashboard action button with open_in_new icon launching http://127.0.0.1:8765/."
  - "D-16: Clicking pill or popup action button to launch browser does not abruptly dismiss popup."
  - "D-17: Non-blocking xdg-open spawn via Quickshell.execDetached."
  - "INTG-02: Deployed via GNU Stow leaf symlinks to ~/.config/quickshell/ without folding parent directories."

requirements-completed:
  - NETPING-01
  - NETPING-02
  - NETPING-03
  - NETPING-04
  - NETPING-05

duration: 12 min
completed: 2026-09-29
status: complete
---

# Phase 45 Plan 02: Interactive Inspector Overlay, Pill Anchoring & GNU Stow Deployment Summary

**Built the interactive two-column inspector overlay `NetworkPingPopup.qml`, anchored it to `NetworkPingPill.qml`, deployed leaf symlinks via GNU Stow, and completed end-to-end suite and strict repository verification.**

## Performance & Execution Metrics

- **Duration:** 12 min
- **Completed:** 2026-09-29
- **Tasks:** 2
- **Files created:** 1 (`NetworkPingPopup.qml`)
- **Files modified:** 1 (`NetworkPingPill.qml`)
- **Commits:** `26c8d86c`

## Accomplishments

1. **Created Interactive Inspector Overlay (`NetworkPingPopup.qml`):**
   - Declared `pragma ComponentBehavior: Bound` and inherited `StyledPopup` root.
   - Built balanced two-column 320px architecture with center vertical separator matching `CpuGpuPopup` and `MemoryStoragePopup`.
   - Integrated lifecycle demand-gated fast polling: toggles `NetworkUsage.isInspectorActive` to `true`, triggers immediate `pollMetrics()`, `refreshConfig()`, and `PingService.fetchStatus()`, restoring idle cadence on close and destruction.
   - Left column (320px) displays comprehensive interface telemetry: active interface name, connection type, Wi-Fi SSID and signal strength, IP address and subnet mask, default gateway IP, DNS nameservers, link speed and duplex, MAC address, Realtek `r8169` NIC hardware temperature, and packet drop/error counters.
   - Left column includes dual `StyledProgressBar` meters for visual Rx and Tx throughput activity alongside live rates and cumulative session totals.
   - Right column (320px) header includes an explicit "Open Web Dashboard" button (`open_in_new` icon, tooltip, and non-blocking `xdg-open` launcher).
   - Right column renders prominent offline warning banner when `PingService.isOffline` is true.
   - Right column renders 3 dedicated ping diagnostic cards (WAN `8.8.8.8`, Gateway `192.168.0.1`, Home Server `192.168.0.104`) with target icons, host titles, IP badges, prominent latency readouts (ms), quality badge pills, and daemon status colors.

2. **Anchored Overlay to Status Bar Pill (`NetworkPingPill.qml`):**
   - Instantiated `NetworkPingPopup` inside the re-parented interactive `MouseArea` bound to `root.hoverArea`.

3. **Deployed via GNU Stow Leaf Symlinks & Verified Integrity:**
   - Ran `stow -d restow -t "$HOME" quickshell` deploying leaf symlinks to `~/.config/quickshell/ii/services/` and `~/.config/quickshell/ii/modules/ii/bar/` without directory folding.
   - Executed `./scripts/phase45-network-ping-assert.sh`: All 5 sections passed with FAIL=0, FINDINGS=0.
   - Executed `./arch/dots-hyprland.sh verify --strict`: Passed with exit code 0 and zero git churn in `vendor/dots-hyprland`.

## Verification Results

- `scripts/phase45-network-ping-assert.sh 1` PASSED: Telemetry services & ping client verified.
- `scripts/phase45-network-ping-assert.sh 2` PASSED: Status bar pill widget verified.
- `scripts/phase45-network-ping-assert.sh 3` PASSED: Two-column popup inspector verified.
- `scripts/phase45-network-ping-assert.sh 4` PASSED: Formatting mathematics and live hardware probes verified.
- `scripts/phase45-network-ping-assert.sh 5` PASSED: Stow leaf symlinks and repository cleanliness verified.
- `./arch/dots-hyprland.sh verify --strict` PASSED: 0 findings, pristine repository structure.

## Self-Check: PASSED
- [x] restow/quickshell/.config/quickshell/ii/modules/ii/bar/NetworkPingPopup.qml exists
- [x] restow/quickshell/.config/quickshell/ii/modules/ii/bar/NetworkPingPill.qml embeds popup
- [x] GNU Stow leaf symlinks active in ~/.config/quickshell/
- [x] Commit `26c8d86c` present in git history
- [x] Full assertion harness runs clean (FAIL=0 FINDINGS=0)
