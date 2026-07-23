# DEBUG: Keyboard volume cannot exceed 100% (G-03-4)

**Status:** root_cause_found  
**Phase:** 03-system-audio-modules  
**Gap:** G-03-4  
**Discovered:** UAT tests 4 + 7

## Symptoms

- expected: Scroll **and** keyboard raise past 100% up to ~130% (D-22)
- actual: Mouse scroll works above 100%; keyboard volume wheel does not

## Root Cause

Keyboard path is Hyprland `XF86AudioRaiseVolume` → `wpctl set-volume -l LIMIT …`.  
**Live** `~/.config/hypr/hyprland.conf` still has **`-l 1`** (100% hard limit).  
**Repo** `.config/hypr/hyprland.conf` already has **`-l 1.3`**, but the two files are **different inodes** (not linked/stowed together), so the phase change never reached the running compositor.

Bar scroll uses `Audio.incrementVolume()` → `maxVolume: 1.30`, which works — explains the mouse/keyboard split.

## Evidence

```
# repo
bindel = ,XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.3 @DEFAULT_AUDIO_SINK@ 5%+

# live (~/.config/hypr/hyprland.conf)
bindel = ,XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+

# different inodes
stat: live 15997905 vs repo 9043975
```

- `Audio.qml` L19, L61–69: `maxVolume: 1.30`, scroll path OK
- Live audio protection: `enable: false` (not the clamper)

## Files Involved

- `.config/hypr/hyprland.conf` (repo — already correct)
- `~/.config/hypr/hyprland.conf` (live — still `-l 1`)

## Suggested Fix Direction

1. Apply `-l 1.3` to the live Hyprland config (or restow/link so live tracks repo).
2. `hyprctl reload` (or rebind) so the new limit is active.
3. Optionally document that keyboard ceiling is Hyprland `wpctl -l`, not Quickshell `Audio.maxVolume`.
