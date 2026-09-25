# Domain Pitfalls Research

**Domain:** Top Status Bar Telemetry & Hardware Sensors (Quickshell ii / Arch Linux)  
**Researched:** 2026-09-25  
**Confidence:** HIGH  

## Critical Pitfalls

### Pitfall 1: Root Permission Restrictions on Intel RAPL Powercap

**Warning Signs:** `/sys/class/powercap/intel-rapl/intel-rapl:0/energy_uj` returns empty or permission denied (0400 root-only). Wattage display shows `NaN` or crashes parsing logic.  
**Root Cause:** Due to Linux kernel security mitigation for CVE-2020-8694 (PLATYPUS side-channel attack), energy counters are restricted to root by default.  
**Prevention Strategy:**
1. Code must verify read accessibility before parsing.
2. If inaccessible, display graceful placeholder `-- W` rather than failing.
3. Provide an optional systemd/udev rule tracked in `arch/` (e.g. `/etc/udev/rules.d/99-rapl.rules`) that allows unprivileged read access for the local wheel/user group if desired.

---

### Pitfall 2: UI Stutter from Synchronous Subprocess Execution

**Warning Signs:** Status bar animations stutter, clock skips seconds, or mouse clicks feel sluggish whenever disk usage or ping status updates.  
**Root Cause:** Synchronous execution (`Quickshell.execDetached` or blocking subshells) runs on the main Qt Quick event loop. Slow FUSE cloud mounts (`GoogleDrive`) or network timeouts block UI rendering.  
**Prevention Strategy:**
1. Direct memory, CPU load, and network throughput MUST use `Quickshell.Io.FileView` over `/proc/meminfo`, `/proc/stat`, and `/proc/net/dev`. These are virtual in-RAM filesystem reads taking < 50 microseconds.
2. Multi-mount disk enumeration (`df`) must use `Quickshell.Io.Process` asynchronously with a relaxed 15–30s interval.
3. Ping queries must use asynchronous `curl` via `Process` or consume the existing daemon's HTTP JSON response with a strict 2-second timeout.

---

### Pitfall 3: Popup Screen Boundary Clipping on Multi-Monitor Displays

**Warning Signs:** Popups for pills located near screen edges or across secondary monitors render partially off-screen or jump coordinates when adjacent pills resize.  
**Root Cause:** Hardcoding popup `x` coordinates or relying on unmapped local item coordinates causes incorrect placement on secondary screens or left-aligned layouts.  
**Prevention Strategy:**
1. Implement dynamic coordinate anchoring via `mapToItem(null, item.width / 2, item.height / 2)`.
2. Apply horizontal clamping formula: `Math.max(screenX + margin, Math.min(centerX - popupWidth / 2, screenX + screenWidth - popupWidth - margin))` as proven in Phase 39 (`MediaControls.qml`).

---

### Pitfall 4: Top Status Bar Left-Zone Crowding on Narrow Screens

**Warning Signs:** 3 expanded pills push the dead-center Workspaces widget to the right, causing visual asymmetry or overlapping the Center and Right zones.  
**Root Cause:** Left-side pill widths expanding beyond the available width buffer on 1080p displays (minimum 180px gap required between Left and Center zones).  
**Prevention Strategy:**
1. Implement `useShortenedForm` responsive tiers:
   - Standard width: Full labels (`350/958 GB`, `WAN 27ms | GW 2ms | SRV 1.6ms`).
   - Shortened (`useShortenedForm >= 1`): Compact icon + percentage or latency numbers only.
2. Maintain `BarGroup` 250ms emphasized deceleration width resizing to prevent layout snapping.

---

### Pitfall 5: Directory Folding in `restow/quickshell/`

**Warning Signs:** Symlinks point to whole directories rather than leaf files, modifying `vendor/dots-hyprland` or triggering `arch/dots-hyprland.sh verify --strict` failures.  
**Root Cause:** Running GNU Stow without `--no-folding` or failing to pre-create target subdirectories causes Stow to fold directories into single symlinks.  
**Prevention Strategy:**
1. Ensure all new files under `restow/quickshell/` follow the leaf symlink overlay topology.
2. Verify with `arch/dots-hyprland.sh verify --strict` before closing each phase.
