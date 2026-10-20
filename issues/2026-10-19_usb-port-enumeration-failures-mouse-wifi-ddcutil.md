# Hardware Incident & Root Cause Analysis: USB Port Enumeration Failures, Wi-Fi Dongle Port Binding, and DDC/CI Startup Warnings

**Date**: 2026-10-19  
**System**: Gigabyte B660M AORUS ELITE DDR4 / Intel Core i5-13500 (14C/20T) / Intel 600 Series Chipset xHCI Host Controller  
**Display**: ASUS ROG PG348Q (3440x1440p @ DisplayPort `card1-DP-1`)  
**OS**: Arch Linux (Kernel `7.2.11-arch1-1` / Hyprland Wayland Session / QuickShell `ii`)  
**Devices Involved**:  
- **Wi-Fi Adapter**: Realtek RTL8710BU 802.11n WLAN Adapter (`0bda:b711`, MAC: `50:2b:73:64:16:51`, Driver: `rtl8xxxu`)
- **Mouse**: A4Tech USB Optical Mouse (`09da:c10a`, Low-Speed 1.5 Mbps USB HID)
- **Monitored Hubs**: Realtek RTS5411 4-Port USB 3.0/2.0 Hub (`0bda:5411` / `0bda:0411`) & Genesys Logic GL850G 4-Port Hub (`05e3:0608`)
**Status**: 🛠️ Resolved & Documented — Wi-Fi port-agnostic profile applied, QuickShell DDC queries disabled, hardware root causes identified.

---

## 1. Executive Summary & Reported Symptoms

Two interrelated hardware and desktop incidents were investigated across consecutive sessions:

1. **Incident 1 (Wi-Fi Dongle Inoperable After Port Change)**:
   The user reported that their USB Wi-Fi dongle worked initially, but stopped functioning completely when moved to a different USB port.
2. **Incident 2 (Startup USB Error Storm & Frozen Mouse)**:
   At system boot, the console and system journal were flooded with USB handshake errors. Upon reaching the Hyprland desktop, the USB mouse was completely non-functional. Concurrently, repeated `ddcutil` error logs appeared during desktop startup.

A comprehensive hardware topology, kernel log, and configuration analysis revealed that:
- None of the user's manual configuration adjustments caused the failures.
- Both failures were physical USB enumeration breakdowns caused by **hub power starvation** and **intermittent signal disconnect loops**, leading the Linux kernel to permanently disable the affected ports for self-protection.
- The Wi-Fi dongle suffered a secondary software issue: **Linux systemd predictable interface naming** locked NetworkManager profiles to physical USB port paths.
- The `ddcutil` errors were completely independent DisplayPort I2C queries from QuickShell attempting to read unsupported monitor brightness registers.

---

## 2. Chronological Incident Timelines

### Timeline A: Wi-Fi Dongle Failure & Port Migration (2026-10-18)

| Timestamp | Component | Event | Impact |
|:---|:---|:---|:---|
| **21:14:45** | Kernel / `rtl8xxxu` | Wi-Fi dongle initialized on direct rear port `usb 1-7` (`wlp0s20f0u7`) | Network active & connected |
| **22:06:48** | Kernel / USB | Bus error on `usb 1-7`: `rtl8710b_indirect_read32: Failed to read from 0x40000138` | Dongle resets |
| **22:06:49** | `usb_modeswitch` | Dongle reappears as storage `0bda:1a2b`, switched to WLAN `0bda:b711` | Mode switch completes |
| **22:06:50** | Kernel / Driver | `probe with driver rtl8xxxu failed with error -11` (`-EAGAIN`) | Driver init fails |
| **22:06:51** | Kernel / xHCI | Repeated handshake failures: `device descriptor read/64, error -71` | Port disabled |
| **22:23:51** | System Boot | User rebooted and moved dongle to `usb 1-6.1` (Genesys Logic Hub) | New port attempted |
| **22:26:32 – 22:26:52** | Kernel / Hub | Rapid failure loop on `usb 1-6.1`: `error -32`, `error -71` (>30 attempts) | Hub brownout |
| **22:26:52** | Kernel / Hub | `usb 1-6-port1: Cannot enable. Maybe the USB cable is bad?` | **Kernel disables port** |

### Timeline B: Mouse Failure & Startup Error Storm (2026-10-19)

| Timestamp | Component | Event | Impact |
|:---|:---|:---|:---|
| **19:08:26** | Kernel / USB | A4Tech Mouse enumerated as device 8 on `usb 1-9.1` (Realtek RTS5411 Hub) | Mouse initially working |
| **19:13:48** | Kernel / USB | `usb 1-9.1: USB disconnect, device number 8` | First disconnect |
| **19:14:14** | Kernel / USB | Mouse reconnected as device 9 | Recovered |
| **19:15:35** | Kernel / USB | Mouse disconnected and reconnected as device 10 | Intermittent contact |
| **19:15:58 – 19:20:32** | Kernel / xHCI | **Over 30 disconnect/reconnect loops**: `error -32`, `error -71`, `error -110`, `error -62` | xHCI setup timeout |
| **19:19:42 – 19:19:58** | QuickShell / `ddcutil` | QuickShell startup queries DDC features `0xdd` / `0x41` on `/dev/i2c-15` | Retries logged to journal |
| **19:20:32** | Kernel / Hub | `usb 1-9-port1: unable to enumerate USB device` | **Kernel shuts off port** |
| **19:21:28** | User Physical Action | Mouse moved to direct motherboard port `usb 1-8` | **Enumerates instantly (0 errors)** |
| **19:21:35** | User Physical Action | Mouse moved back to `usb 1-9.1` | Enumerates as dev 44 (stable) |

---

## 3. Log Evidence & Root Cause Analysis

### A. Root Cause 1: USB Hub Power Starvation & Bus Disconnect Loops

When the Wi-Fi dongle and mouse failed, the kernel output the same signature errors:
- **`error -32` (`-EPIPE` / Broken pipe)**: Control transfer to endpoint 0 stalled or connection dropped mid-packet.
- **`error -71` (`-EPROTO` / Protocol error)**: Bitstuffing error, CRC failure, or signal timing collapse.
- **`error -110` (`-ETIMEDOUT`) / `error -62` (`-ETIME`)**: The xHCI host controller timed out waiting for device setup commands.

```text
usb 1-9.1: device descriptor read/64, error -32
usb 1-9.1: Device not responding to setup address.
usb 1-9.1: device not accepting address 36, error -71
xhci_hcd 0000:00:14.0: Timeout while waiting for setup device command
usb 1-9.1: device descriptor read/64, error -110
usb 1-9.1: device not accepting address 42, error -62
usb 1-9-port1: unable to enumerate USB device
```

#### Why Did This Happen on Those Specific Ports?
1. **Genesys Logic Hub (`usb 1-6`) — Power Overload**:
   - The Genesys Logic hub (`05e3:0608`) is an unpowered/bus-powered 4-port hub reporting `MaxPower = 100mA`.
   - Connected simultaneously:
     - Port 2: Samsung Galaxy phone (`04e8:6864`), drawing heavy current for battery charging and RNDIS tethering.
     - Port 3: Rapoo Gaming Headset (`24ae:7003`) with audio DAC and LED lighting.
     - Port 4: Bluetooth dongle (`0a12:0001`).
     - Port 1: Realtek RTL8710BU Wi-Fi dongle.
   - Wi-Fi dongles draw 300–500 mA spikes during radio calibration and mode switching. Under load, the shared 5V line suffered an immediate voltage drop (brownout), causing `-32` and `-71` errors until the kernel disabled the port.
2. **Realtek RTS5411 Hub (`usb 1-9`) — Low-Speed Micro-Disconnects**:
   - The A4Tech mouse is a **Low-Speed USB 1.1 (1.5 Mbps)** device.
   - USB 3.0/2.0 hubs handle Low-Speed devices through a Transaction Translator (TT).
   - Loose physical contact or cable strain triggered 30+ disconnects in under 5 minutes. The xHCI driver timed out trying to reset and re-address the device during active input polling, triggering kernel circuit-breaker logic that shut off `usb 1-9-port1`.

---

### B. Root Cause 2: Predictable Interface Naming in Linux NetworkManager

Even on functional USB ports, moving the Wi-Fi dongle prevented automatic connection due to systemd/udev predictable interface naming:
- Port 8 -> named `wlp0s20f0u8`
- Port 7 -> named `wlp0s20f0u7`
- Hub Port -> named `wlp0s20f0u6u1`

Inspection of NetworkManager configuration confirmed the issue:
```text
Connection "no internet":   connection.interface-name: wlp0s20f0u8
Connection "no internet 1": connection.interface-name: wlp0s20f0u7
```
NetworkManager profiles were tied strictly to the physical interface name. Moving the dongle changed its device node path, causing NetworkManager to view it as an unconfigured adapter.

---

### C. Root Cause 3: DDC/CI Startup Warnings (`ddcutil`)

During boot, the following logs appeared:
```text
Oct 19 19:19:54 arch ddcutil[6785]: busno=15, sleep-multiplier= 2.00, Testing for unsupported feature 0xdd returned Error_Info[DDCRC_RETRIES in ddc_write_read_with_retry, causes: DDCRC_READ_ALL_ZERO(10)]
Oct 19 19:19:57 arch ddcutil[6785]: busno=15, sleep-multiplier= 2.00, Testing for unsupported feature 0x41 returned Error_Info[DDCRC_RETRIES in ddc_write_read_with_retry, causes: DDCRC_READ_ALL_ZERO(10)]
```

- **Origin**: QuickShell (`~/.config/quickshell/ii/services/Brightness.qml`) calls `ddcutil detect --brief` and `ddcutil getvcp 10` on startup to populate the desktop brightness slider.
- **Mechanism**: Communication occurs over the DisplayPort I2C bus (`/dev/i2c-15`) to the ASUS ROG PG348Q monitor.
- **Significance**: The monitor's scaler firmware does not support optional VCP codes `0xdd` and `0x41`. The warnings are entirely unrelated to USB and have zero impact on input hardware.

---

## 4. Remediations & Mitigations Applied

### 1. Wi-Fi Connection Port Unbinding
Cleared the hardcoded interface names from saved NetworkManager connections so the dongle connects regardless of the physical port:
```bash
nmcli connection modify "no internet" connection.interface-name ""
nmcli connection modify "no internet 1" connection.interface-name ""
```

### 2. Realtek Driver Hardening
Created `/etc/modprobe.d/rtl8xxxu.conf` with:
```text
options rtl8xxxu dma_aggregation=0
```
This stabilizes DMA transfers and prevents `-11` (`-EAGAIN`) probe timeouts during adapter initialization.

### 3. Disabled DDC Queries in QuickShell
Patched `~/.config/quickshell/ii/services/Brightness.qml` to prevent unnecessary `ddcutil` executions:
- Added `property bool enableDdc: false` guard.
- Bypassed `ddcProc` during `onMonitorsChanged`.
- Guarded `isDdc` detection so monitor initialization defaults immediately to standard backlight fallback without probing I2C bus 15.
- Created backup at `~/.config/quickshell/ii/services/Brightness.qml.bak`.

---

## 5. Hardware Recommendations & Best Practices

1. **Direct Motherboard Connection for Input & High-Draw Devices**:
   - Always plug mice, keyboards, and Wi-Fi dongles directly into the **black USB 2.0 ports on the rear motherboard I/O shield** (such as port `1-8`).
   - Direct rear ports provide clean, unshared 500 mA power rails and bypass hub Transaction Translators (TT).
2. **Avoid Charging Phones on Multi-Port USB Hubs**:
   - Smartphones negotiate up to 1.5A–2.0A of charging current. On unpowered hubs, this deprives other peripherals of voltage and triggers cascading disconnects.
3. **Avoid Blue USB 3.0 Ports for 2.4 GHz Wi-Fi Dongles**:
   - USB 3.0 data buses radiate broadband radio frequency interference across 2.4–2.5 GHz. Wi-Fi dongles plugged into or adjacent to USB 3.0 ports experience severe packet loss and degraded signal-to-noise ratio.
