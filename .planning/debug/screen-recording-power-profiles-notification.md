# Debug Session: Screen Recording Privacy Indicator, Power Profiles Toggle, & Recording Stop Notification

**Status:** ROOT CAUSE FOUND
**Phase:** 32
**Gap ID:** G-32-3
**Discovered During:** UAT (Test 1)

## Symptoms
User reported:
"using SUPER + R to screen recording starts but privacy stuff that supposed to show icon in the system tray does not show up. But when i screen share that icon shows up in the system tray though. power profiles - clicking on it does nothing, is it broken or not i don't know. Also after screen recording is done the notification should include the path of the record"

## Root Causes

### 1. Privacy Screen Recording Indicator Not Triggering
- **Mechanism:** `restow/quickshell/.config/quickshell/ii/services/Privacy.qml` evaluates screen sharing strictly against PipeWire link groups:
  ```qml
  readonly property bool screenSharing: Pipewire.linkGroups.values.some(pwlg => pwlg.source?.type === PwNodeType.VideoSource)
  ```
- **Finding:** While browser screen sharing (via WebRTC / xdg-desktop-portal-hyprland) sets up a PipeWire `VideoSource` stream node, screen recording via `SUPER + R` (or quickshell util buttons) invokes `record.sh` which executes `wf-recorder`. `wf-recorder` connects directly to the Wayland compositor via `wlr-screencopy` protocol and does NOT register a PipeWire `VideoSource` node.
- **Evidence:** `wf-recorder` runs without creating a PipeWire `VideoSource` node. As a result, `Privacy.screenSharing` remains `false` throughout the screen recording session.

### 2. Missing Saved File Path in Recording Stop Notification
- **Mechanism:** `vendor/dots-hyprland/dots/.config/quickshell/ii/scripts/videos/record.sh` starts recording by generating a dynamic filename `recording_$(date '+%Y-%m-%d_%H.%M.%S').mp4` inside `$RECORDING_DIR`.
- **Finding:** When stopping an active recording (lines 49-52):
  ```bash
  if pgrep wf-recorder > /dev/null; then
      notify-send "Recording Stopped" "Stopped" -a 'Recorder' &
      pkill wf-recorder &
  ```
  The script unconditionally emits the generic message `"Stopped"` and discards knowledge of which file was recorded. No state file or metadata persists the active recording path across invocations.

### 3. Power Profiles Button Click Does Nothing
- **Mechanism:** `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/UtilButtons.qml` mounts a power profile toggle button when `Config.options.bar.utilButtons.showPerformanceProfileToggle` is `true`. On click, it sets `PowerProfiles.profile`.
- **Finding:** Quickshell's `PowerProfiles` engine interacts with the `net.hadess.PowerProfiles` / `org.freedesktop.UPower.PowerProfiles` D-Bus interface provided by the `power-profiles-daemon` system service.
- **Evidence:** `power-profiles-daemon` is not installed on this system (`pacman -Qs power-profiles-daemon` returns empty; `systemctl status power-profiles-daemon` reports unit not found; `which powerprofilesctl` fails). Without the daemon running, setting `PowerProfiles.profile` is a silent no-op with no user feedback.

## Files Involved
- `restow/quickshell/.config/quickshell/ii/services/Privacy.qml`: Lacks detection for `wf-recorder` process / recording state.
- `vendor/dots-hyprland/dots/.config/quickshell/ii/scripts/videos/record.sh`: Needs overlay in `restow/quickshell/.config/quickshell/ii/scripts/videos/record.sh` to track active recording file and report `Saved to: <path>` upon stop.
- `capture/ii/.config/illogical-impulse/config.json` & `UtilButtons.qml`: Power profile toggle either requires `power-profiles-daemon` package installed/enabled or fallback feedback informing user that the daemon is inactive.

## Suggested Fix Directions
1. **Record Script Enhancement & Overlay:**
   - Create `restow/quickshell/.config/quickshell/ii/scripts/videos/record.sh` deployed via GNU Stow.
   - On start: record the target recording file path to `/tmp/current_recording_path` (or `$XDG_RUNTIME_DIR/current_recording_path`).
   - On stop: read target recording path, remove the state file, and dispatch `notify-send "Recording Stopped" "Saved to: $filepath" -a 'Recorder'`.
2. **Privacy Service Screen Recording Telemetry:**
   - In `restow/quickshell/.config/quickshell/ii/services/Privacy.qml`, add a reactive `screenRecording` property (checking `pgrep -x wf-recorder` or state file).
   - Combine `screenRecording` into the privacy alert:
     `readonly property bool screenSharing: screenRecording || Pipewire.linkGroups.values.some(pwlg => pwlg.source?.type === PwNodeType.VideoSource)`
   - This ensures the red recording/screen-share indicator reveals in `BarContent.qml` whenever either `wf-recorder` or PipeWire screen sharing is active.
3. **Power Profiles Resolution:**
   - Document `power-profiles-daemon` requirement (`sudo pacman -S power-profiles-daemon && sudo systemctl enable --now power-profiles-daemon.service`) for native D-Bus power switching.
   - In `UtilButtons.qml`, provide feedback or handle daemon absence cleanly.
