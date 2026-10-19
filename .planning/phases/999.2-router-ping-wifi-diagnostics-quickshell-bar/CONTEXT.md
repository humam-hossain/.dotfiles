# Phase 999.2: Router Ping & Wi-Fi Link Diagnostics with Quickshell Status Bar Integration

## Origin & Context
- **Incident Date**: 2026-10-19
- **Problem**: Ping to the default gateway (router `192.168.0.1`) spiked intermittently to 200ms – 1,500ms with packet drops.
- **Root Cause Analysis (verified against `system.db` over 53,765 samples)**:
  - Latency to router (`192.168.0.1`) and another LAN peer (`192.168.0.104`) showed a **0.9955 (99.55%)** Pearson correlation, proving the delay occurs on the first-hop wireless link on this host (`192.168.0.107`), NOT inside the router.
  - Primary causes:
    1. 2.4 GHz 40 MHz channel bonding on Channel 1 overlapping with high-power neighboring networks (`Shohochor` on Ch 8 with 82% signal, `anik eusha` on Ch 3), causing CSMA/CA carrier backoffs and forcing TX rate down to MCS 2 (40.5 Mbps).
    2. Realtek RTL8188GU USB Wi-Fi dongle (`0bda:b711`, RTL8710BU) running on the in-kernel `rtl8xxxu` driver experiencing USB bus register read/write stalls (`indirect_read32/write32 failed`) and lack of bufferbloat mitigation.
  - Immediate fix applied:
    - Router 2.4 GHz channel width set to 20 MHz.
    - `/etc/modprobe.d/rtl8xxxu.conf` set with `options rtl8xxxu dma_aggregation=0`.
    - Result: latency dropped to 1.1–2.1 ms, 0% packet loss, locked to MCS 7 (72.2 Mbps).

---

## Objective
Build an automated diagnostic and status indicator pipeline so any recurrence of local wireless link degradation, high gateway ping, or driver stalls is immediately detected, visually indicated on the Quickshell top status bar, and alerted proactively via desktop notifications.

---

## Architectural Breakdown

### 1. `system-monitor` Telemetry & Anomaly Engine (`stow/system_monitor/.config/system_monitor/ping/`)
- **Automated Root-Cause Classification in `server.py`**:
  - Compare router latency (`192.168.0.1`) vs Internet latency (`8.8.8.8`):
    - **Local Wi-Fi Degraded**: Router ping > 20ms and $\approx$ Internet ping (correlated local bottleneck).
    - **ISP / WAN Degraded**: Internet ping > 100ms but Router ping $\le 5$ms.
    - **Link Loss / Stalled**: Router ping NULL (dropped packet) or `iw` reports link disconnected.
- **Wi-Fi Telemetry Enrichment**:
  - Query `iw dev <iface> link` / `station dump` every N cycles for:
    - Current frequency & channel
    - Channel width (20MHz vs 40MHz)
    - Signal strength (dBm)
    - Active TX bitrate and MCS index
  - Expose telemetry in `/api/status` JSON response.
- **Proactive Notification Hook**:
  - If local Wi-Fi hop degradation persists for $\ge 3$ consecutive cycles (15 seconds), invoke `notify-send` / `swaync-client` with urgency `critical`:
    `"High Router Latency: 250ms (Wi-Fi link contention detected)"`.

### 2. `dots-hyprland` Quickshell Bar Integration (`dots/.config/quickshell/ii/`)
- **Service: `PingService.qml` (`services/`)**:
  - Quickshell singleton that queries `http://127.0.0.1:8765/api/status` via `Quickshell.Io.Process` or `HttpRequest`.
  - Exposes reactive properties: `routerPingMs`, `gatewayPingMs`, `linkStatus` (`normal`, `elevated`, `bad`, `critical`, `offline`), `channelInfo`, `bitrateInfo`.
- **Top Bar Widget / Badge in `BarContent.qml`**:
  - Placed in `indicatorsRowLayout` alongside network indicator.
  - Visual state:
    - Hidden or subtle green dot when latency $\le 5$ms.
    - Turns yellow/orange when $20\text{ms} < \text{ping} < 100\text{ms}$.
    - Turns red / flashes when $> 100\text{ms}$ or packet loss occurs.
  - Hover tooltip: Rich pango/formatted tooltip displaying:
    `Router: 2.1ms | Internet: 26ms | Ch 5 (20MHz, MCS 7)`.
  - Left click: Opens `http://localhost:8765/` (the existing ping visualization dashboard).

---

## Verification & Testing Strategy
- Simulated latency injection using `tc qdisc add dev wlp0s20f0u2 root netem delay 250ms`.
- Verify Quickshell top bar changes state dynamically within 5 seconds.
- Verify desktop notification triggers after 15 seconds of sustained delay.
- Teardown netem and verify recovery back to normal.
