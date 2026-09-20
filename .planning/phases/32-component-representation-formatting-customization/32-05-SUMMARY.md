---
phase: 32-component-representation-formatting-customization
plan: "05"
subsystem: ui
tags: [quickshell, qml, dots-hyprland, screen-recording, wf-recorder, privacy, notifications, power-profiles, gap-closure]

requires:
  - phase: 32-component-representation-formatting-customization
    plan: "01"
    provides: Phase 32 Nyquist assertion harness & native Tier 1 config
  - phase: 32-component-representation-formatting-customization
    plan: "02"
    provides: Tier 2 personal QML overlays and initial BarContent integration
  - phase: 32-component-representation-formatting-customization
    plan: "03"
    provides: Initial gap closure fixes for top bar controls and update launcher
  - phase: 32-component-representation-formatting-customization
    plan: "04"
    provides: Visual refinement and gap closure for mic indicator, update flags, and media width
provides:
  - restow overlay for record.sh tracking active recording target and notifying with 'Saved to: <path>'
  - Privacy.qml reactive wf-recorder process telemetry driving the red screen recording alert revealer
  - Power profiles configuration verification and power-profiles-daemon dependency documentation
  - Synchronized Nyquist assertion suite in phase32-component-formatting-assert.sh
affects: [quickshell, dots-hyprland, recording, privacy, power]

actuals:
  tokens: 12500
  tasks: 4
  commits: 4

tech-stack:
  added: []
  patterns: [runtime state tracking for shell scripts, periodic process polling in QML singletons]

key-files:
  created:
    - restow/quickshell/.config/quickshell/ii/scripts/videos/record.sh
  modified:
    - restow/quickshell/.config/quickshell/ii/services/Privacy.qml
    - capture/ii/.config/illogical-impulse/config.json
    - scripts/phase32-component-formatting-assert.sh

key-decisions:
  - "Overlay record.sh in restow/quickshell/.config/quickshell/ii/scripts/videos/record.sh to record active path into /tmp/quickshell-current-recording.txt on start, and report Saved to: $saved_path upon stop."
  - "In Privacy.qml, add reactive screenRecording boolean polling 'pgrep -x wf-recorder' every 1000ms, unified with screenSharing to reveal the red alert pill in BarContent.qml."
  - "Retain showPerformanceProfileToggle: true in config.json and document systemd requirement for power-profiles-daemon on Arch Linux."
  - "Extend phase32-component-formatting-assert.sh Section 3 with assertions for record.sh execution, leaf symlink, Saved to notification, and Privacy.qml wf-recorder telemetry."

patterns-established:
  - "Runtime file-based state handover between separate invocations of toggle shell scripts."
  - "Process polling inside Quickshell singleton services for non-PipeWire external processes."

requirements-completed: [COMP-06, COMP-08]

coverage:
  - id: D1
    description: "Overlay record.sh with active file tracking and notification path"
    requirement: COMP-06
    verification:
      - kind: integration
        ref: "scripts/phase32-component-formatting-assert.sh --section 3"
        status: pass
    human_judgment: false
  - id: D2
    description: "Add reactive screen recording telemetry to Privacy.qml"
    requirement: COMP-08
    verification:
      - kind: integration
        ref: "scripts/phase32-component-formatting-assert.sh --section 3"
        status: pass
    human_judgment: false
  - id: D3
    description: "Verify power profiles configuration and system daemon requirements"
    requirement: COMP-06
    verification:
      - kind: integration
        ref: "scripts/phase32-component-formatting-assert.sh --section 1"
        status: pass
    human_judgment: false
  - id: D4
    description: "Update Nyquist assertion harness and verify repository integrity"
    requirement: INTG-02
    verification:
      - kind: integration
        ref: "scripts/phase32-component-formatting-assert.sh"
        status: pass
      - kind: integration
        ref: "arch/dots-hyprland.sh verify --strict"
        status: pass
    human_judgment: false

duration: 8 min
completed: "2026-09-20T14:50:00+06:00"
---

# Phase 32 Plan 05: Screen Recording Telemetry, Notification Path & Power Profiles Summary

Resolved UAT gap G-32-3 by overlaying `record.sh` to track active recording paths and report `Saved to: <path>` on stop, augmenting `Privacy.qml` with reactive `wf-recorder` process telemetry to reveal the red screen recording alert pill, validating power profiles configuration and documenting the `power-profiles-daemon` Arch requirement, and synchronizing Nyquist assertions.

## Accomplishments

1. **Active Recording State Tracking & Path Notification (COMP-06):**
   - Created `restow/quickshell/.config/quickshell/ii/scripts/videos/record.sh` deployed as an executable leaf symlink via GNU Stow `--no-folding`.
   - On recording start, records the exact timestamped output file path to `/tmp/quickshell-current-recording.txt`.
   - On recording stop, reads the state file, removes it, and emits `notify-send "Recording Stopped" "Saved to: $saved_path" -a 'Recorder'`.

2. **Reactive Screen Recording Privacy Telemetry (COMP-08):**
   - Enhanced `restow/quickshell/.config/quickshell/ii/services/Privacy.qml` with `screenRecording` property and a 1000ms polling `Process` targeting `pgrep -x wf-recorder`.
   - Combined `screenRecording` into `screenSharing`:
     ```qml
     readonly property bool screenSharing: screenRecording || Pipewire.linkGroups.values.some(pwlg => pwlg.source?.type === PwNodeType.VideoSource)
     ```
   - Dynamically triggers the red `screen_record` Material Symbol revealer in `BarContent.qml` during active screen recordings.

3. **Power Profiles Handling & Verification (COMP-06):**
   - Verified that `capture/ii/.config/illogical-impulse/config.json` and live active configuration retain `.bar.utilButtons.showPerformanceProfileToggle: true`.
   - Documented that Quickshell's PowerProfiles service uses the D-Bus interface provided by `power-profiles-daemon` (`sudo pacman -S power-profiles-daemon && sudo systemctl enable --now power-profiles-daemon.service`).

4. **Nyquist Assertion Synchronization & Strict Repo Verification (INTG-02):**
   - Added assertions to `scripts/phase32-component-formatting-assert.sh` Section 3 validating `record.sh` leaf symlinking, execution bit, notification path formatting, and `Privacy.qml` telemetry.
   - All 4 sections passed with `FAIL=0 FINDINGS=0`.
   - `./arch/dots-hyprland.sh verify --strict` passed with 0 findings.

## Verification Results

- `scripts/phase32-component-formatting-assert.sh`: `FAIL=0 FINDINGS=0`
- `arch/dots-hyprland.sh verify --strict`: `FAIL=0 FINDINGS=0`
- `git status --porcelain`: clean across test runs

## Self-Check: PASSED
