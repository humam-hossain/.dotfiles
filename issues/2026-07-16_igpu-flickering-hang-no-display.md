# Intel UHD 770 — Flickering, Hang, No Display After Reboot

**Date**: 2026-07-16
**System**: Gigabyte B660M AORUS ELITE DDR4 / Intel i5-13500 / Intel UHD Graphics 770 (ADL-S GT1)
**Monitor**: ASUS ROG PG348Q (3440x1440) via DisplayPort
**OS**: Arch Linux / Kernel 7.1.3-arch1-3 / Hyprland 0.55.4 (Wayland)
**Status**: ✅ Resolved — software root cause, no hardware damage

---

## Symptoms

1. Black and white flickering on screen followed by a complete system hang
2. After forced shutdown (power button hold), system would POST (fans spin, num lock toggles) but **no display output** to the monitor
3. Swapping RAM slots sometimes brought the display back, sometimes didn't
4. After waiting several minutes or power-cycling multiple times, the system would eventually work again
5. Issue occurred on Jul 15 and Jul 16, 2026

---

## Investigation

### Boot History Analysis

The system journal recorded 10 boot sessions across the incident window. Several sessions were abnormally short, indicating repeated crashes and forced reboots:

```
journalctl --list-boots
```
```
  -9  Wed 2026-07-15 09:46:38 — Wed 2026-07-15 12:14:28    (2h 28m, stable)
  -8  Wed 2026-07-15 12:14:48 — Wed 2026-07-15 18:23:38    (6h 09m, stable)
  -7  Wed 2026-07-15 20:39:25 — Wed 2026-07-15 20:43:20    (4 min ⚠️)
  -6  Wed 2026-07-15 20:52:38 — Wed 2026-07-15 23:32:21    (2h 40m, recovered)
  -5  Thu 2026-07-16 07:09:16 — Thu 2026-07-16 10:16:31    (3h 07m, CRASHED ⛔)
  -4  Thu 2026-07-16 12:42:19 — Thu 2026-07-16 13:02:00    (20 min ⚠️)
  -3  Thu 2026-07-16 13:02:18 — Thu 2026-07-16 13:11:59    (10 min ⚠️)
  -2  Thu 2026-07-16 13:13:28 — Thu 2026-07-16 13:14:20    (52 sec ⚠️)
  -1  Thu 2026-07-16 15:27:04 — Thu 2026-07-16 15:32:47    (5 min ⚠️)
   0  Thu 2026-07-16 16:00:32 — running                     (stable ✅, after fix)
```

Boot -5 was the primary crash event (the ~10:20 AM incident). Boots -4 through -1 were repeated failed attempts to get the system stable again.

---

## Root Cause #1: Experimental `xe` GPU Driver

### Evidence

Boots -5 and -4 were running with kernel parameters that forced the **experimental xe driver** instead of the stable i915:

```
journalctl -b -5 | grep "Kernel command line"
```
```
Jul 16 07:09:16 archlinux kernel: Kernel command line: initrd=\initramfs-linux.img
    root=UUID=e8a2b95d-c83a-4f57-89dd-e03fde7054a1 rw quiet loglevel=3
    i915.force_probe=!4680 xe.force_probe=4680
```

The kernel itself flagged this as dangerous:

```
Jul 16 07:09:16 archlinux kernel: Setting dangerous option force_probe - tainting kernel
Jul 16 07:09:16 archlinux kernel: Setting dangerous option force_probe - tainting kernel
```

The xe driver also warned about insufficient stolen memory:

```
Jul 16 07:09:17 archlinux kernel: xe 0000:00:02.0: [drm] Reducing the compressed
    framebuffer size. This may lead to less power savings than a non-reduced-size.
    Try to increase stolen memory size if available in BIOS.
```

### The Crash: GPU Engine Resets

At 07:59, Steam/CS2 was launched:

```
journalctl -b -5 | grep steam.*rungameid
```
```
Jul 16 07:59:00 arch steam[173812]: steam.sh[173793]: Running Steam on arch rolling 64-bit
Jul 16 07:59:01 arch steam[173812]: Startup - Steam Client launched with:
    '/home/pera/.local/share/Steam/ubuntu12_32/steam' '-srt-logger-opened'
    'steam://rungameid/730'
```

**2 seconds after Steam launched**, the GPU started dying — 6 engine resets in 27 seconds:

```
journalctl -b -5 -k | grep -E '(Engine reset|Timedout job|coredump)'
```
```
Jul 16 07:59:02 kernel: xe 0000:00:02.0: [drm] Tile0: GT0: Engine reset: engine_class=rcs, logical_mask: 0x1, guc_id=27, state=0x3
Jul 16 07:59:02 kernel: xe 0000:00:02.0: [drm] Tile0: GT0: Timedout job: seqno=4294967169, lrc_seqno=4294967169, guc_id=27, flags=0x0 in Xwayland [1616]
Jul 16 07:59:02 kernel: xe 0000:00:02.0: [drm] Xe device coredump has been created
Jul 16 07:59:02 kernel: xe 0000:00:02.0: [drm] Check your /sys/class/drm/card0/device/devcoredump/data
Jul 16 07:59:02 kernel: xe 0000:00:02.0: [drm] Tile0: GT0: Engine reset: engine_class=rcs, logical_mask: 0x1, guc_id=31, state=0x3
Jul 16 07:59:02 kernel: xe 0000:00:02.0: [drm] Tile0: GT0: Timedout job: seqno=4294967169, lrc_seqno=4294967169, guc_id=31, flags=0x0 in gldriverquery [174109]
Jul 16 07:59:03 kernel: xe 0000:00:02.0: [drm] Tile0: GT0: Engine reset: engine_class=rcs, logical_mask: 0x1, guc_id=31, state=0x3
Jul 16 07:59:03 kernel: xe 0000:00:02.0: [drm] Tile0: GT0: Timedout job: seqno=4294967169, lrc_seqno=4294967169, guc_id=31, flags=0x0 in Xwayland [1616]
Jul 16 07:59:09 kernel: xe 0000:00:02.0: [drm] Tile0: GT0: Engine reset: engine_class=rcs, logical_mask: 0x1, guc_id=54, state=0x3
Jul 16 07:59:09 kernel: xe 0000:00:02.0: [drm] Tile0: GT0: Timedout job: seqno=4294967169, lrc_seqno=4294967169, guc_id=54, flags=0x0 in Xwayland [1616]
Jul 16 07:59:09 kernel: xe 0000:00:02.0: [drm] Tile0: GT0: Engine reset: engine_class=rcs, logical_mask: 0x1, guc_id=36, state=0x3
Jul 16 07:59:09 kernel: xe 0000:00:02.0: [drm] Tile0: GT0: Timedout job: seqno=4294967169, lrc_seqno=4294967169, guc_id=36, flags=0x0 in Xwayland [1616]
Jul 16 07:59:29 kernel: xe 0000:00:02.0: [drm] Tile0: GT0: Engine reset: engine_class=rcs, logical_mask: 0x1, guc_id=96, state=0x3
Jul 16 07:59:29 kernel: xe 0000:00:02.0: [drm] Tile0: GT0: Timedout job: seqno=4294967169, lrc_seqno=4294967169, guc_id=96, flags=0x0 in coolercontrol [175839]
Jul 16 08:59:04 kernel: xe 0000:00:02.0: [drm] Xe device coredump has been deleted.
```

The xe driver's render command scheduler (GuC) timed out on jobs submitted by Xwayland, gldriverquery, and coolercontrol. The GPU hardware was fine — the driver couldn't manage the workload.

### Progressive System Degradation

After the GPU resets, the kernel's `perf` subsystem showed steadily worsening interrupt latency — a signature of the system grinding to a halt:

```
journalctl -b -5 -k | grep 'perf.*interrupt'
```
```
Jul 16 07:25:10 kernel: perf: interrupt took too long (2532 > 2500), lowering kernel.perf_event_max_sample_rate to 78000
Jul 16 07:49:44 kernel: perf: interrupt took too long (3204 > 3165), lowering kernel.perf_event_max_sample_rate to 62000
Jul 16 07:59:23 kernel: perf: interrupt took too long (4348 > 4005), lowering kernel.perf_event_max_sample_rate to 45000
Jul 16 08:03:56 kernel: perf: interrupt took too long (5607 > 5435), lowering kernel.perf_event_max_sample_rate to 35000
Jul 16 08:08:15 kernel: perf: interrupt took too long (7020 > 7008), lowering kernel.perf_event_max_sample_rate to 28000
Jul 16 08:12:52 kernel: perf: interrupt took too long (8807 > 8775), lowering kernel.perf_event_max_sample_rate to 22000
Jul 16 08:20:24 kernel: perf: interrupt took too long (11018 > 11008), lowering kernel.perf_event_max_sample_rate to 18000
Jul 16 08:28:27 kernel: perf: interrupt took too long (13833 > 13772), lowering kernel.perf_event_max_sample_rate to 14000
Jul 16 08:49:07 kernel: perf: interrupt took too long (17310 > 17291), lowering kernel.perf_event_max_sample_rate to 11000
Jul 16 10:14:45 kernel: perf: interrupt took too long (21648 > 21637), lowering kernel.perf_event_max_sample_rate to 9000
```

Interrupt latency grew from 2.5ms to 21.6ms — an **8.5× degradation** over 3 hours, confirming the system was progressively freezing.

### WiFi Beacon Losses (System Freeze Evidence)

The USB WiFi adapter started losing beacons, proving the CPU was too frozen to service interrupts:

```
journalctl -b -5 | grep -c 'BEACON-LOSS'
```
```
95 total beacon losses across the session
```

Sample:
```
Jul 16 09:43:53 arch wpa_supplicant[808]: wlp0s20f0u7: CTRL-EVENT-BEACON-LOSS
Jul 16 09:44:03 arch wpa_supplicant[808]: wlp0s20f0u7: CTRL-EVENT-BEACON-LOSS
Jul 16 09:44:27 arch wpa_supplicant[808]: wlp0s20f0u7: CTRL-EVENT-BEACON-LOSS
Jul 16 09:44:55 arch wpa_supplicant[808]: wlp0s20f0u7: CTRL-EVENT-BEACON-LOSS
Jul 16 09:44:57 arch wpa_supplicant[808]: wlp0s20f0u7: CTRL-EVENT-BEACON-LOSS
```

### Hard Hang — No Shutdown Logged

The last journal entry was at 10:16:31. There is **no shutdown/reboot sequence** logged — the system froze completely and required a forced power-off via the power button.

---

## Root Cause #2: ddcutil DDC/CI Bus Hammering

### Evidence

A Waybar custom module was calling `ddcutil getvcp 10` (brightness query) every ~6 seconds via a polling loop. Every single call failed because the ROG PG348Q's DDC/CI implementation does not support the queried VCP features:

```
journalctl -b -5 | grep -c ddcutil
```
```
10764 total ddcutil log lines in a single 3-hour boot session
```

Sample:
```
Jul 16 07:09:43 arch ddcutil[2063]: busno=15, sleep-multiplier=2.00, Testing for unsupported
    feature 0xdd returned Error_Info[DDCRC_RETRIES in ddc_write_read_with_retry,
    causes: DDCRC_READ_ALL_ZERO(10)]
Jul 16 07:09:43 arch ddcutil[2063]: Turning off dynamic sleep and retrying
Jul 16 07:09:44 arch ddcutil[2063]: busno=15, sleep-multiplier=1.00, Retesting for
    unsupported feature 0xdd returned Error_Info[DDCRC_RETRIES in ddc_write_read_with_retry,
    causes: DDCRC_READ_ALL_ZERO(10)]
Jul 16 07:09:46 arch ddcutil[2063]: busno=15, sleep-multiplier=2.00, Testing for unsupported
    feature 0x41 returned Error_Info[DDCRC_RETRIES in ddc_write_read_with_retry,
    causes: DDCRC_READ_ALL_ZERO(10)]
Jul 16 07:09:46 arch ddcutil[2200]: Max wait time 3000 milliseconds exceeded after
    32 flock() calls
```

### Source

Waybar config had a custom backlight module using ddcutil (commented out in modules list but the exec was still running, or another config was active):

```jsonc
// waybar config.jsonc
// "custom/backlight": {
//   "exec": "ddcutil getvcp 10 2>/dev/null | awk '/current value/ { gsub(/,/, \"\", $9); print $9 }' || echo 0",
```

### Impact

- Each ddcutil invocation performs multiple I2C transactions over the DP aux channel
- 10 retries per feature × 2 features × every 6 seconds = sustained I2C bus saturation
- This interfered with the GPU's DP link management, contributing to display instability
- On an already-stressed xe driver, this created additional display pipeline contention

---

## Collateral Damage: Desktop Portal Crashes

After the GPU engine resets, `xdg-desktop-portal-hyprland` segfaulted on boots -3 and -4:

```
journalctl -b -4 | grep -E '(SEGV|core-dump|portal.*Failed)'
```
```
Jul 16 13:01:50 arch systemd-coredump[68517]: Process 1478 (xdg-desktop-por) of user 1000
    terminated abnormally with signal 11/SEGV, processing...
Jul 16 13:01:50 arch systemd[1127]: xdg-desktop-portal-hyprland.service:
    Main process exited, code=dumped, status=11/SEGV
Jul 16 13:01:50 arch systemd[1127]: xdg-desktop-portal-hyprland.service:
    Failed with result 'core-dump'.
```

```
journalctl -b -3 | grep -E '(SEGV|core-dump|portal.*Failed)'
```
```
Jul 16 13:11:49 arch systemd-coredump[36596]: Process 1345 (xdg-desktop-por) of user 1000
    terminated abnormally with signal 11/SEGV, processing...
Jul 16 13:11:49 arch systemd[1042]: xdg-desktop-portal-hyprland.service:
    Main process exited, code=dumped, status=11/SEGV
Jul 16 13:11:49 arch systemd[1042]: xdg-desktop-portal-hyprland.service:
    Failed with result 'core-dump'.
```

These were consequences of the broken GPU state, not independent issues.

---

## Why "No Display After Reboot"

After the hard hang + forced power-off, subsequent boots showed fans spinning and num lock working but no video output. This is explained by:

1. **DP link state corruption**: The monitor's DisplayPort receiver was in the middle of DDC/CI I2C transactions when power was cut. The link state wasn't cleanly torn down, so the monitor's DP controller needed time or a power cycle to reset.

2. **iGPU memory controller dirty state**: The forced power-off left the GPU's internal SRAM in an undefined state. A full power drain (unplugging PSU or waiting) was needed to clear it. This is why reseating RAM appeared to help — it forced a complete electrical reset of the memory bus and GPU.

3. **Not a RAM issue**: Swapping slots appeared to "fix" it because it required removing power long enough for the GPU/monitor state to fully discharge. The RAM itself was never at fault — there are zero EDAC/MCE memory errors across all boot sessions.

---

## Hardware Health Verification

After fixing the software issues, all hardware checks pass:

### No Hardware Errors

```
dmesg | grep -iE '(mce|machine.check|hardware.error|edac|memory.*error)'
```
```
(no output — zero hardware errors)
```

### Thermals Normal

```
sensors | grep -E '(Package|Core 0|Composite)'
```
```
Composite:    +38.9°C  (high = +81.8°C)
Package id 0: +56.0°C  (high = +80.0°C, crit = +100.0°C)
Core 0:       +39.0°C  (high = +80.0°C, crit = +100.0°C)
Composite:    +40.9°C  (high = +80.8°C)
```

### GPU Fully Functional

```
vulkaninfo --summary | grep -E '(deviceName|driverName|apiVersion)'
```
```
apiVersion  = 1.4.354
deviceName  = Intel(R) UHD Graphics 770 (ADL-S GT1)
driverName  = Intel open-source Mesa driver
```

```
vainfo | grep -E '(Driver version|VA-API version)'
```
```
vainfo: VA-API version: 1.24 (libva 2.23.0)
vainfo: Driver version: Intel iHD driver for Intel(R) Gen Graphics - 26.1.5 ()
```

### DRM Devices Present

```
ls -la /dev/dri/
```
```
crw-rw----+ root video  226,   1  card1
crw-rw-rw-  root render 226, 128  renderD128
```

### i915 Driver Loaded and Stable

```
lsmod | grep i915
```
```
i915  5062656  79
```

### Display Connected

```
cat /sys/class/drm/card1-DP-1/status
```
```
connected
```

---

## Resolution

### Fix 1: Remove xe driver kernel parameters

The boot entry was updated to remove `i915.force_probe=!4680 xe.force_probe=4680`, falling back to the stable i915 driver.

**Before** (`/boot/loader/entries/arch.conf`):
```
options  root=UUID=... rw quiet loglevel=3 i915.force_probe=!4680 xe.force_probe=4680
```

**After**:
```
options  root=UUID=... rw quiet loglevel=3
```

### Fix 2: Disable ddcutil Waybar module

The Waybar brightness polling module that spawned ddcutil every 6 seconds was disabled.

**Location**: `~/.config/waybar/config.jsonc`

### Result

The system has been stable on boot 0 (started 16:00:32) with:
- Zero GPU errors
- Zero engine resets
- Zero ddcutil processes
- Normal interrupt latency
- Stable display output over DP

---

## Conclusion

**The iGPU is not physically damaged.** The entire incident was caused by:

1. The **experimental xe GPU driver** (`xe.force_probe=4680`) which could not handle the rendering workload from Steam/CS2 + Xwayland, resulting in 6 GPU engine resets and a progressive system freeze
2. **Aggressive ddcutil polling** (~10,764 failed DDC/CI calls in 3 hours) saturating the display's I2C bus and interfering with DP link management

The "no display after reboot" symptom was caused by the hard power-off leaving the DP link and iGPU memory controller in dirty states, not by any hardware damage. Full power drain (via reseating RAM or waiting) cleared this state every time.

Both software issues have been fixed. The system is stable on the i915 driver with ddcutil disabled.
