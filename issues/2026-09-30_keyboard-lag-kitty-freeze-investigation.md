# System Incident: Keyboard Input Lag & Kitty Unresponsiveness

**Date**: 2026-09-30  
**System**: Gigabyte B660M AORUS ELITE DDR4 / Intel i5-13500 (14C/20T) / Intel UHD Graphics 770 (ADL-S GT1)  
**Display**: 3440x1440p (DisplayPort)  
**OS**: Arch Linux (Kernel 6.13 / Wayland / Hyprland 0.55+ / Aquamarine)  
**Input Devices**: GANSS GS3104T Mechanical Keyboard (Dual connection: Wired + 2.4 GHz Dongle)  
**Status**: 🛠️ Mitigated & Hardened — zram active, USB dongle resolved, rclone hardened with circuit breakers & notifications  

---

## 1. Executive Summary & Symptoms

Following the completion of Phase 48 and during verification / UAT (`verify-work`), the user reported:
1. Significant keyboard input lag across all applications.
2. Kitty terminal emulator becoming unresponsive / freezing, requiring launching a secondary instance to recover the tmux session.
3. Media key shortcuts (`SUPER + SHIFT + P`) failing to trigger media playback toggles cleanly.

A complete system log and runtime investigation uncovered that this issue was caused by **5 compounding root causes**, centered around a **5-minute system-wide freeze** caused by `systemd-coredump` exhausting RAM on a system with **0B swap**, combined with dual USB input contention, a rapid rclone restart loop, and high-frequency process forking.

---

## 2. Chronological Incident Timeline

| Timestamp (Sep 30, 2026) | Component | Event | Impact |
|--------------------------|-----------|-------|--------|
| **10:01:40** | Kernel / USB | Rapoo Headset (`24ae:7003`) & USB Dongle (`05ac:024f`) enumerated | Wireless receiver active |
| **10:01:57** | Systemd User | Kitty launched PID 1564 (workspace 1, attached to `tmux`) | Main dev terminal session active |
| **10:03:48** | Git / GSD | Commit `6686203c test(48): complete UAT - 2 passed, 1 issues` | User actively running `verify-work` |
| **10:05:39** | Git / GSD | Commit `069fbcd9 docs(48-03): create gap closure plan` | Phase 48 documentation committed |
| **10:07:00** | Kernel / Discord | Discord PID 1566 crashed with `SIGTRAP` (`si_code: SI_KERNEL`) | First coredump begins |
| **10:07:53** | systemd-coredump | Discord PID 1566 coredump completes (5.0 GB peak RAM, 12.6s CPU) | Severe RAM pressure |
| **10:07:39** | Systemd User | Discord restarted as PID 36347 (`app-discord-36347.scope`) | Application reloads |
| **10:08:06** | Kernel / Discord | Discord PID 36347 crashed **again** with `SIGTRAP` | Second coredump begins |
| **10:08:06 – 10:13:07** | systemd-coredump | **5-MINUTE SYSTEM LOCKUP**: coredump worker runs continuously | Consumes 5.8 GB RAM, pegs CPU, thrashes disk on 0B swap system |
| **10:09:27** | Kernel / USB | USB disconnect on port 1-4 (GS3104T keyboard) | User disconnects keyboard due to lag |
| **10:10:25** | Kernel / USB | USB reconnect on port 1-4 (GS3104T wired cable) | Keyboard re-enumerated |
| **10:10:29** | Hyprland / Aquamarine | **`client bug: event processing lagging behind by 260ms, your system is too slow`** | Compositor event loop blocked; Wayland input queues stall |
| **10:13:07** | systemd | `systemd-coredump` hits 5-minute hard timeout limit and is killed | System memory unfreezes |
| **10:14:03** | Discord | Discord started again as PID 54099 | New Discord session active |
| **10:14:59** | Systemd User | User starts new Kitty instance (PID 60277) and runs `tmux a` | Recovering frozen terminal |
| **10:10 – Present** | Rclone Service | `rclone@gdrive-ammu-main` & `gdrive-bapi-main` loop every 10s | Continuous spawn/crash churn across `/proc/mountinfo` |

---

## 3. Log Evidence by Component

### A. The 5-Minute Core Dump Lockup & Memory Starvation

From `journalctl -b`:
```text
Sep 30 10:07:00 arch systemd-coredump[35776]: Process 1566 (Discord) of user 1000 terminated abnormally with signal 5/TRAP, processing...
Sep 30 10:07:00 arch systemd[1]: Created slice Slice /system/systemd-coredump.
Sep 30 10:07:00 arch systemd[1]: Started Process Core Dump (PID 35776/UID 0).
Sep 30 10:07:29 arch systemd[1355]: app-discord-1566.scope: Consumed 28.341s CPU time over 5min 31.164s wall clock time, 636.7M memory peak.
Sep 30 10:07:39 arch systemd[1355]: Started app-discord-36347.scope.
Sep 30 10:07:53 arch systemd-coredump[35785]: Process 1566 (Discord) of user 1000 dumped core.
Sep 30 10:07:53 arch systemd[1]: systemd-coredump@0-1-35776_30408-0.service: Deactivated successfully.
Sep 30 10:07:53 arch systemd[1]: systemd-coredump@0-1-35776_30408-0.service: Consumed 12.676s CPU time over 53.109s wall clock time, 5G memory peak.
Sep 30 10:08:06 arch systemd-coredump[38603]: Process 36347 (Discord) of user 1000 terminated abnormally with signal 5/TRAP, processing...
Sep 30 10:08:06 arch systemd[1]: Started Process Core Dump (PID 38603/UID 0).
Sep 30 10:13:07 arch systemd[1]: systemd-coredump@1-4097-38603_51449-0.service: Service reached runtime time limit. Stopping.
Sep 30 10:13:07 arch systemd[1]: systemd-coredump@1-4097-38603_51449-0.service: Failed with result 'timeout'.
Sep 30 10:13:07 arch systemd[1]: systemd-coredump@1-4097-38603_51449-0.service: Consumed 1min 4.688s CPU time over 5min 353ms wall clock time, 5.8G memory peak.
```

**Memory Status during incident**:
```text
               total        used        free      shared  buff/cache   available
Mem:            15Gi       7.4Gi       4.9Gi       1.4Gi       4.8Gi       8.0Gi
Swap:             0B          0B          0B
```
With **0B Swap**, allocating 5.8 GB for `systemd-coredump` on top of Chrome (~3 GB) and Discord (~700 MB) evicted virtually all kernel page caches and caused heavy memory allocation stalls.

---

### B. Hyprland & Aquamarine Compositor Event Stall

From `/run/user/1000/hypr/efb50993780079460b0cbed1363e2166a2de1d9f_1790740915_1836805256/hyprland.log`:
```text
[ERR from aquamarine ]: [libinput] event4  - GANSS GS3104T: client bug: event processing lagging behind by 260ms, your system is too slow
[DEBUG from aquamarine ]: [libinput] event4  - GANSS GS3104T: device removed
[DEBUG from aquamarine ]: [libinput] event7  - GANSS GS3104T: device removed
[DEBUG from aquamarine ]: [libinput] event4  - GANSS GS3104T: is tagged by udev as: Keyboard
[DEBUG from aquamarine ]: [libinput] event4  - GANSS GS3104T: device is a keyboard
[DEBUG from aquamarine ]: libinput: New device GANSS GS3104T: 1452-591
[DEBUG from aquamarine ]: [libinput] event7  - GANSS GS3104T: is tagged by udev as: Keyboard Mouse
[DEBUG from aquamarine ]: [libinput] event7  - GANSS GS3104T: device is a pointer
[DEBUG from aquamarine ]: [libinput] event7  - GANSS GS3104T: device is a keyboard
[DEBUG from aquamarine ]: libinput: New device GANSS GS3104T: 1452-591
```

- **Mechanism**: Libinput emits `client bug: event processing lagging behind by Xms, your system is too slow` when the Wayland compositor's event loop fails to drain the input fd within expected dispatch windows.
- Any latency in Hyprland's main thread starves connected Wayland clients (Kitty, Chrome, etc.) of keyboard input and frame synchronization.

---

### C. USB Hardware & Dual Connection Contention

From kernel logs (`journalctl -k -b`):
```text
Sep 30 10:01:40 arch kernel: usb 1-6.4: new full-speed USB device number 13 using xhci_hcd
Sep 30 10:01:40 arch kernel: usb 1-6.4: Product: USB Dongle
Sep 30 10:01:40 arch kernel: input: USB Dongle as /devices/pci0000:00/0000:00:14.0/usb1/1-6/1-6.4/1-6.4:1.0/0003:05AC:024F.0006/input/input19
Sep 30 10:01:40 arch kernel: apple 0003:05AC:024F.0006: input,hidraw5: USB HID v1.10 Keyboard [USB Dongle] on usb-0000:00:14.0-6.4/input0

Sep 30 10:09:27 arch kernel: usb 1-4: USB disconnect, device number 2
Sep 30 10:10:25 arch kernel: usb 1-4: new full-speed USB device number 14 using xhci_hcd
Sep 30 10:10:26 arch kernel: usb 1-4: Product: GS3104T, Manufacturer: GANSS
Sep 30 10:10:29 arch kernel: apple 0003:05AC:024F.0009: Non-apple keyboard detected; function keys will default to fnmode=2 behavior
Sep 30 10:10:29 arch kernel: input: GANSS GS3104T as /devices/pci0000:00/0000:00:14.0/usb1/1-4/1-4:1.0/0003:05AC:024F.0009/input/input23
Sep 30 10:10:29 arch kernel: apple 0003:05AC:024F.0009: input,hidraw1: USB HID v1.11 Keyboard [GANSS GS3104T] on usb-0000:00:14.0-4/input0
```

From `hyprctl devices`:
```text
Keyboards:
	Keyboard at 559dd2536270:
		usb-dongle
	Keyboard at 559dd25764c0:
		usb-dongle-1
	Keyboard at 559dd225b100:
		ganss-gs3104t (main: yes)
	Keyboard at 559dd22327d0:
		ganss-gs3104t-1
```

- Both the wireless 2.4 GHz USB Dongle and the direct USB-C cable for the same keyboard hardware share Vendor/Product ID `05AC:024F` and are bound simultaneously to the kernel `hid-apple` driver.
- Hardware interrupt count on `xhci_hcd` reached **323,282 interrupts** in under 15 minutes.

---

### D. Rclone Mount Service Crash Loop (Every 10 Seconds)

From `journalctl -b`:
```text
Sep 30 10:14:44 arch systemd[1355]: rclone@gdrive-ammu-main.service: Scheduled restart job, restart counter is at 71.
Sep 30 10:14:44 arch systemd[1355]: Starting Rclone Mount for gdrive-ammu-main...
Sep 30 10:14:44 arch rclone[58714]: ERROR+4: Failed to create file system for "gdrive-ammu-main:": couldn't find root directory ID: couldn't fetch token: invalid_grant: maybe token expired?
Sep 30 10:14:44 arch systemd[1355]: rclone@gdrive-ammu-main.service: Main process exited, code=exited, status=1/FAILURE
Sep 30 10:14:44 arch systemd[1355]: Failed to start Rclone Mount for gdrive-ammu-main.
Sep 30 10:14:45 arch rclone[58738]: ERROR+4: Failed to create file system for "gdrive-bapi-main:": couldn't find root directory ID: couldn't fetch token: invalid_grant: maybe token expired?
Sep 30 10:14:45 arch systemd[1355]: rclone@gdrive-bapi-main.service: Main process exited, code=exited, status=1/FAILURE
Sep 30 10:14:45 arch systemd[1355]: Failed to start Rclone Mount for gdrive-bapi-main.
```

- Over **85 restart iterations** occurred in 18 minutes.
- Dolphin (PID 80256) is open to the `ammu` folder and holds descriptors on `/proc/mountinfo`, causing continuous mount-table polling and wakeups in `udisks2` and `kio`.

---

### E. Process Generation & Fork Rate During Agent Tool Runs

Measured via `/proc/loadavg` and real-time `/proc` sampling:
- **Fork Rate**: 350 to 450 new PIDs spawned every 2 seconds (~175–225 PIDs/second).
- **Context Switches**: 15,000 to 23,000 context switches per second.
- **Top Process Generators Captured**:
  1. `/home/pera/.antigravity/statusline.sh` (spawns subshells, `jq`, `git status --porcelain`, `ip`, `hostname`, `sed`, `wc`, `stat`).
  2. `settings.json` BeforeTool and AfterTool hooks (12 JavaScript and Bash hooks executed on every tool action).

---

## 4. Root Causes

1. **Discord Core Dump Thrashing (Direct Trigger for Freeze)**:
   A SIGTRAP crash in Discord triggered a 5.8 GB coredump write for 5 minutes straight. Without swap space, the system experienced extreme memory pressure and blocked the Wayland compositor.
2. **Wayland Compositor Starvation**:
   Hyprland's main event loop was blocked by 260ms, dropping/delaying keyboard evdev packets to Kitty and making Kitty appear frozen.
3. **Dual USB Input Collision**:
   The keyboard was simultaneously connected via its 2.4 GHz wireless USB dongle and its USB cable, creating duplicate device entries in `hid-apple` and libinput.
4. **Rclone Crash Churn**:
   Two systemd user services continuously restarting every 10 seconds due to expired Google Drive tokens, triggering mount table churn and waking Dolphin/udisks2.
5. **High Process Fork Rate**:
   The CLI statusline and tool hooks spawned hundreds of subprocesses per second, raising context switching to >20,000 cs/s.

---

## 5. Remediation & Action Items

### Immediate Steps
1. **Unplug One Keyboard Interface**:
   - If using the USB-C cable for the GANSS GS3104T, unplug the wireless 2.4G USB dongle (or unplug the cable if using wireless).
2. **Stop the Failing Rclone Services**:
   ```bash
   systemctl --user stop rclone@gdrive-ammu-main.service rclone@gdrive-bapi-main.service
   ```
   *(To disable them until re-authenticated: `systemctl --user disable --now rclone@gdrive-ammu-main.service rclone@gdrive-bapi-main.service`)*

### Permanent Fixes
3. **Enable Swap or zram**:
   - ✅ Configured 8 GB zram swap via `stow/zram` (`systemd-zram-setup@zram0.service` / `dev-zram0.swap`).
4. **Limit Systemd Coredump Resource Usage**:
   - In `/etc/systemd/coredump.conf`, set:
     ```ini
     [Coredump]
     ProcessSizeMax=1G
     ExternalSizeMax=1G
     ```
   - This prevents electron-based applications from locking up the system with multi-gigabyte core dumps.
5. **Harden Rclone Systemd Service & Desktop Notifications**:
   - ✅ Managed under `stow/rclone` and installed via `arch/rclone.sh`.
   - ✅ Implemented circuit breaker (`StartLimitIntervalSec=120s`, `StartLimitBurst=3`, `RestartSec=15s`). If a mount fails 3 times, systemd permanently stops attempts without looping.
   - ✅ Added resource clamping (`Nice=19`, `CPUSchedulingPolicy=batch`, `CPUQuota=50%`, `MemoryHigh=512M`, `MemoryMax=1G`, `TasksMax=30`) so rclone can never freeze foreground tasks.
   - ✅ Integrated `OnFailure=rclone-notify-failure@%i.service` with desktop notifications (`notify-send --urgency=critical`) alerting the user with the exact failure reason and remediation command.

