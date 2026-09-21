# Architecture Research

**Domain:** Quickshell Status Bar Voice Component & Telemetry Integration  
**Researched:** 2026-09-21  
**Confidence:** HIGH  

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     Desktop Bar (BarContent.qml)                         │
│  ┌───────────────────────┐  ┌──────────────┐  ┌──────────────────────┐  │
│  │ Left Zone (Status)    │  │ Center Zone  │  │ Right Zone           │  │
│  │ [Weather] [Resources] │  │ [Workspaces] │  │ [Media] [VOICE PILL] │  │
│  └───────────────────────┘  └──────────────┘  │ [Tray] [Sidebar]     │  │
│                                               └──────────┬───────────┘  │
└──────────────────────────────────────────────────────────┼──────────────┘
                                                           │
                                 ┌─────────────────────────▼──────────────┐
                                 │     VoicePill.qml (modules/ii/bar)     │
                                 │  - BarGroup (M3 pill container)        │
                                 │  - MaterialSymbol ("auto_awesome")     │
                                 │  - Animated Audio Waveform             │
                                 │  - Live Duration Counter ("0:08")      │
                                 │  - State Badge ("Transcribing", etc.)  │
                                 └─────────────────────────▲──────────────┘
                                                           │ (bindings)
                                 ┌─────────────────────────┴──────────────┐
                                 │       Voice.qml (Singleton Service)    │
                                 │  - FileView / Watcher on state files   │
                                 │  - State evaluator & duration timer    │
                                 │  - Exports: state, elapsed, active     │
                                 └─────────────────────────▲──────────────┘
                                                           │
                                        ┌──────────────────┴─────────────┐
                                        │ $XDG_RUNTIME_DIR/voice-stt/     │
                                        │  ├── recorder.pid (<pid> state)│
                                        │  ├── tts.pid (<pid> state)     │
                                        │  └── voice.log / tts.log       │
                                        └──────────────────▲─────────────┘
                                                           │ (file writes)
                                        ┌──────────────────┴─────────────┐
                                        │ voicemode CLI (voice.py)       │
                                        │  - SUPER + SHIFT + M (STT)     │
                                        │  - SUPER + T (TTS)             │
                                        └────────────────────────────────┘
```

## Component Breakdown

### 1. Telemetry Producer: `voice.py` / `voicemode`

- **Location:** `/home/pera/github_repo/Voice/voice.py` (symlinked as `~/.local/bin/voice`).
- **State Contracts:**
  - `recorder.pid`: Created when STT starts. Contains `<pid> <state>` where state is `starting`, `recording`, or `transcribing`. Unlinked when STT completes.
  - `tts.pid`: Created when TTS starts. Contains `<pid> speaking`. Unlinked when speech finishes.
- **Key Invariant:** Zero modifications required to the core speech model logic. The runtime files are already written to `$XDG_RUNTIME_DIR/voice-stt/`.

### 2. Quickshell Singleton Service: `Voice.qml`

- **Location:** `restow/quickshell/.config/quickshell/ii/services/Voice.qml`
- **Role:** Centralized state engine for speech operations.
- **Properties Exported:**
  - `readonly property string state`: `"idle" | "recording" | "transcribing" | "typing" | "speaking"`
  - `readonly property int elapsedSeconds`: Number of seconds in current active state.
  - `readonly property string formattedDuration`: Formatted as `"M:SS"` (e.g. `"0:05"`).
  - `readonly property string ttsVoice`: Current or last active TTS voice name (e.g. `"af_heart"`).
  - `readonly property bool active`: `state !== "idle"`.
- **Implementation Strategy:**
  - `FileView` watching `$XDG_RUNTIME_DIR/voice-stt/recorder.pid` and `tts.pid`.
  - A lightweight 200ms `Timer` to re-poll state file existence/content when transitions occur, and a 1000ms `Timer` to advance `elapsedSeconds` while `active` is true.

### 3. Visual Status Pill: `VoicePill.qml`

- **Location:** `restow/quickshell/.config/quickshell/ii/modules/ii/bar/VoicePill.qml`
- **Role:** Visual presentation in the top status bar.
- **Structure:**
  - Outer: `BarGroup` ensuring standard pill styling (12–16px radius, 4–6px padding, 250ms M3 emphasized deceleration width transition).
  - Content:
    - **Icon:** `MaterialSymbol { text: "auto_awesome" }` (sparkles).
      - Idle: Muted tertiary/outline color, resting state.
      - Recording: Tinted primary or error/red with gentle pulse animation (`SequentialAnimation` on opacity 0.6 -> 1.0).
      - Transcribing: Tinted amber/warning with rotating or glowing cadence.
      - Speaking: Tinted primary/tertiary with synchronized audio wave.
    - **Waveform:** 3-4 vertical rounded rectangle bars with staggered height animations during `recording` and `speaking`.
    - **Label:** Dynamic text showing either duration (`"0:05"`), state (`"Transcribing..."`, `"Typing..."`), or voice name (`"af_heart"`).
- **Expansion Behavior:**
  - Idle: Compact pill (icon only, width ~32px) or hidden when idle (can be configurable; idle icon keeps bar layout anchored).
  - Active: Smoothly expands to ~120px to display wave, duration, and status label.

### 4. Layout Integration: `BarContent.qml`

- **Location:** `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml`
- **Right Section Order:**
  1. Spacer (`Layout.fillWidth: true`)
  2. `mediaLoader` (Media player)
  3. `voiceLoader` (`VoicePill`) — positioned immediately after Media per user requirement
  4. `updatesLoader` (Package updates)
  5. `batteryLoader` (Battery status)
  6. `sysTrayGroup` (System tray)
  7. `rightSidebarButton` (Sidebar toggle)

## Data Flow & Lifecycle Transitions

1. **User triggers STT hotkey (`SUPER + SHIFT + M`):**
   - `voice.py` starts background worker, writes `<pid> starting` then `<pid> recording` to `recorder.pid`.
   - `Voice.qml` detects file update, sets `state = "recording"`, resets duration to `0`, starts 1s timer.
   - `VoicePill.qml` expands width, switches icon to pulsing primary color, starts audio equalizer wave, displays `"0:01"`.
2. **User stops STT (`SUPER + SHIFT + M` again):**
   - `voice.py` updates `recorder.pid` to `<pid> transcribing`.
   - `Voice.qml` transitions `state = "transcribing"`.
   - `VoicePill.qml` switches wave to processing cadence and displays `"Transcribing..."`.
3. **Transcription complete & text typing:**
   - Text is injected via `wtype`/`ydotool`.
   - `Voice.qml` reflects brief `"typing"` state if signaled, then `voice.py` deletes `recorder.pid`.
4. **Return to Idle:**
   - `Voice.qml` detects removal of `recorder.pid`, sets `state = "idle"`.
   - `VoicePill.qml` stops duration timer and contracts width back to resting state.
5. **TTS Playback (`SUPER + T`):**
   - `voice.py` writes `<pid> speaking` to `tts.pid`.
   - `Voice.qml` transitions to `state = "speaking"`.
   - `VoicePill.qml` displays audio wave, speech duration, and active voice badge until `tts.pid` is removed.

---
*Architecture research for: Quickshell Voice Status Bar Pill*  
*Researched: 2026-09-21*  
