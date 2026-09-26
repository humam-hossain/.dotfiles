# DEBUG: CpuGpuPill and CpuGpuPopup not mounted in BarContent.qml (G-43-1..6)

**Status:** root_cause_found  
**Phase:** 43-cpu-gpu-component-pill-popup  
**Gaps:** G-43-1, G-43-2, G-43-3, G-43-4, G-43-5, G-43-6  
**Discovered:** UAT tests 1–6

## Symptoms

- expected: Top bar renders `CpuGpuPill` with live CPU/GPU telemetry, M3 width resizing, and hover-triggered `CpuGpuPopup` inspector overlay.
- actual: User reported:
  - Test 1: "no they don't. that's the issue, it remains the same as before this phase"
  - Test 2: "no popup shows up on hover other than media. like datetime, weather they also don't show popup and the memory cpu single component from before also don't show popup"
  - Test 3: "well the popup does not showing up so there is no ay to know"
  - Test 4: "same there is no way i can know as it does not exists yet"
  - Test 5: "same question i told you these verification all should fail as the popup does not show up"
  - Test 6: "don't work"
- reproduction: Launch Quickshell and inspect the top status bar. The legacy monolithic `Resources.qml` widget is rendered instead of `CpuGpuPill`, and hovering does not summon `CpuGpuPopup`.

## Root Cause

`CpuGpuPill.qml`, `CpuGpuPopup.qml`, and `StyledPopup.qml` were created and deployed via GNU Stow leaf symlinks in `~/.config/quickshell/ii/modules/ii/bar/`. However, they were never instantiated into the active bar scene graph:

1. `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml` lines 104–112 still instantiates the legacy `Resources.qml` component inside `resourcesGroup`.
2. `CpuGpuPill` is not declared or instantiated inside `BarContent.qml`.
3. `CpuGpuPopup` is not instantiated or anchored to `CpuGpuPill`'s `hoverArea` inside `BarContent.qml` or `Bar.qml`.

While Phase 46 (`46-left-zone-integration`) in `ROADMAP.md` was originally planned to handle full left-zone integration once all three pills (CPU/GPU, RAM/Disk, Network/Ping) are complete, conversational UAT in Phase 43 requires live user-facing verification of the CPU/GPU pill and popup on desktop. Without being mounted into `BarContent.qml`, the newly built components remain completely invisible to the user.

## Evidence

- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml` L104–112:
  ```qml
  BarGroup {
      id: resourcesGroup
      Layout.alignment: Qt.AlignVCenter

      Resources {
          alwaysShowAllResources: root.useShortenedForm === 2
          Layout.fillWidth: root.useShortenedForm === 2
      }
  }
  ```
- Grepping `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml` for `CpuGpuPill` yields 0 matches.
- Grepping `restow/quickshell/.config/quickshell/ii/modules/ii/bar/Bar.qml` for `CpuGpuPopup` yields 0 matches.

## Files Involved

- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml`: Needs `CpuGpuPill` mounted in place of (or alongside) `Resources`, with popup overlay anchored to its exported `hoverArea`.
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/Bar.qml`: Or instantiate `CpuGpuPopup` in `Bar.qml` floating overlay layer anchored to the pill.

## Suggested Fix Direction

1. In `BarContent.qml`, replace the legacy `Resources` block or add `CpuGpuPill` with `useShortenedForm: root.useShortenedForm`.
2. Instantiate `CpuGpuPopup` anchored to `cpuGpuPill.hoverArea`.
3. Restow dotfiles and reload Quickshell (`quickshell -p ...` or restart systemd/hyprland service) so the changes take effect live on the user's screen.
