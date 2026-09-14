# DEBUG: Upstream keybind duplicates and inverted audio mute (G-20-2)

**Status:** resolved  
**Phase:** 20-hypr-custom-overlays-and-startup-restore  
**Gap:** G-20-2  
**Discovered:** UAT post-test review

## Symptoms

- expected:
  1. Upstream redundant defaults (SUPER+Q for close, SUPER+Left/Right/Up/Down for focus) are unbound in favor of adopted personal binds (SUPER+C, SUPER+H/J/K/L).
  2. Upstream media mute shortcuts (SUPER+ALT+M, SUPER+SHIFT+M) are unbound.
  3. SUPER+M toggles microphone mute (`@DEFAULT_AUDIO_SOURCE@`).
  4. SUPER+ALT+M toggles speaker volume mute (`@DEFAULT_AUDIO_SINK@`).
- actual:
  1. SUPER+Q and arrow keys still exist in Hyprland alongside personal binds.
  2. Upstream SUPER+ALT+M (mic toggle) and SUPER+SHIFT+M (mute toggle) conflict.
  3. SUPER+M was previously bound to sink mute instead of mic mute.
- reproduction: Query `hyprctl -i 0 -j binds` and observe active bindings for `SUPER + Q`, arrow keys, and `SUPER + M`.

## Root Cause

In `stow/hypr/.config/hypr/custom/keybinds.lua`, only 9 unbinds were originally declared (D-06). Upstream `hyprland/keybinds.lua` binds:
- `SUPER + Q` to `Window: Close` (line 181)
- `SUPER + Left/Right/Up/Down` to `Window: Focus <dir>` (lines 156-161)
- `SUPER + SHIFT + M` to `Media: Toggle mute` (line 142)
- `SUPER + ALT + M` to `Media: Toggle mic` (line 146)

Because these were not explicitly unbound, Hyprland retained both bindings. Additionally, `SUPER + M` was wired to `@DEFAULT_AUDIO_SINK@` per initial discussion rather than `@DEFAULT_AUDIO_SOURCE@` (microphone).

## Evidence

- `hyprctl -i 0 -j binds`:
  - `key: Q, modmask: 64` present (`Window: Close`).
  - `key: Left, modmask: 64` present (`Window: Focus Left`).
  - `key: M, modmask: 65` present (`Media: Toggle mute`).
  - `key: M, modmask: 72` present (`Media: Toggle mic`).
- `stow/hypr/.config/hypr/custom/keybinds.lua`:
  - L29: `hl.bind("SUPER + M", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { description = "Audio: Toggle mute" })`
  - L5-13: missing unbinds for `SUPER + Q`, arrow keys, and media M chords.

## Files Involved

- `stow/hypr/.config/hypr/custom/keybinds.lua`
- `scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh`

## Suggested Fix Direction

1. Add unbinds to `stow/hypr/.config/hypr/custom/keybinds.lua`:
   ```lua
   hl.unbind("SUPER + Q")
   hl.unbind("SUPER + Left")
   hl.unbind("SUPER + Right")
   hl.unbind("SUPER + Up")
   hl.unbind("SUPER + Down")
   hl.unbind("SUPER + ALT + M")
   hl.unbind("SUPER + SHIFT + M")
   ```
2. Update audio controls:
   ```lua
   hl.bind("SUPER + M", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true, description = "Audio: Toggle mic" })
   hl.bind("SUPER + ALT + M", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, description = "Audio: Toggle mute" })
   ```
3. Update assert script Section 6 to verify all 16 unbinds, taxonomy, and non-duplication.
4. Reload compositor (`hyprctl reload`) and verify.
