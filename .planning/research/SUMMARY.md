# Project Research Summary

**Project:** Quickshell Desktop Shell (Milestone v0.7)  
**Domain:** Quickshell Status Bar Voice Component & Audio Telemetry  
**Researched:** 2026-09-21  
**Confidence:** HIGH  

## Executive Summary

Milestone v0.7 delivers a dedicated custom Voice status bar component for the Quickshell desktop shell on Arch Linux / Hyprland. The component connects to the local `voice` STT/TTS engine (`faster-whisper` and `Kokoro` TTS) located in `/home/pera/github_repo/Voice`, providing real-time visual telemetry and lifecycle feedback in the top status bar.

The architectural approach integrates a non-blocking Quickshell Singleton service (`services/Voice.qml`) that monitors runtime state files (`$XDG_RUNTIME_DIR/voice-stt/recorder.pid` and `tts.pid`) with an interactive status bar pill (`modules/ii/bar/VoicePill.qml`). The visual design adheres strictly to the system's Google Material Symbols visual language, utilizing an AI-centric icon (`auto_awesome` / sparkles) rather than a generic hardware microphone icon. During speech recording and synthesis, the component features reactive color pulsing, an animated audio waveform, live elapsed duration counters, and distinct status badges ("Transcribing...", "Typing...", "Speaking").

Key technical risks—such as QML thread blocking from CLI execution, CPU drain from high-frequency polling, and GNU Stow symlink folding—are mitigated by using asynchronous `FileView` state detection, adaptive timer intervals, GPU-driven QML animations, and strict repository verification (`arch/dots-hyprland.sh verify --strict`).

## Key Findings

### Recommended Stack

Quickshell QML provides the entire UI and state presentation layer, binding natively into the existing dots-hyprland architecture. Telemetry is read asynchronously from the file-backed PID state created by `voicemode` (`voice.py`).

**Core technologies:**
- **Quickshell QML (Qt 6.7+):** Declarative UI rendering, `BarGroup` pill geometry, and Material 3 transitions.
- **Quickshell.Io (`FileView`):** Inotify-backed state file observation in `$XDG_RUNTIME_DIR/voice-stt/` with zero subprocess overhead.
- **Material Symbols Font (`MaterialSymbol.qml`):** Consistent vector iconography rendering AI visual symbols (`auto_awesome`, `graphic_eq`).
- **voicemode (`voice.py`):** Existing local speech engine providing STT (`SUPER + SHIFT + M`) and TTS (`SUPER + T`).

### Expected Features

**Must have (table stakes):**
- **AI Visual Identity:** Material Symbol `auto_awesome` (sparkles) icon matching the desktop shell's design language.
- **STT Recording Telemetry:** Pulse animation, accent color change (primary/error), live duration counter (seconds elapsed), and animated audio wave.
- **STT Transcribing State:** Distinct status indicator ("Transcribing...") while Whisper model processes audio.
- **STT Typing/Writing State:** Visual feedback during synthetic keystroke injection into focused window.
- **TTS Speaking Telemetry:** Speech synthesis state with audio wave animation, elapsed playback seconds, and active voice name badge.
- **Return to Idle:** Clean, seamless reset to resting state once speech operations finish.
- **Placement:** Positioned in Right zone immediately after Media (`mediaLoader`).
- **Standardized Geometry:** 12–16px corner radius, 4–6px padding, and 250ms Material 3 emphasized deceleration width transition.
- **Pure Telemetry Pill:** Clean status monitor without click popups or intrusive menus.

### Architectural Structure

1. **`services/Voice.qml`**: Centralized state Singleton reading `$XDG_RUNTIME_DIR/voice-stt/` state and exposing `state`, `elapsedSeconds`, `formattedDuration`, and `ttsVoice`.
2. **`modules/ii/bar/VoicePill.qml`**: Visual component encapsulated in `BarGroup`, rendering the AI icon, wave bars, and duration text with dynamic Material You palette tokens.
3. **`modules/ii/bar/BarContent.qml`**: Placed in `rightSectionRowLayout` between `mediaLoader` and `updatesLoader`.

### Critical Pitfalls & Mitigations

- **Pitfall:** Blocking the QML render loop by running synchronous CLI commands.  
  *Mitigation:* Read runtime state files directly via `FileView` and non-blocking timers; never invoke synchronous shell subshells.
- **Pitfall:** Stale PID state keeping UI in perpetual recording mode after an unexpected crash.  
  *Mitigation:* Check process liveness in `/proc/<pid>` before transitioning to active states.
- **Pitfall:** Battery drain from aggressive polling.  
  *Mitigation:* Use low-frequency (500–1000ms) background polling when idle; handle fluid wave animations with native QML `NumberAnimation` loops.
- **Pitfall:** GNU Stow directory folding.  
  *Mitigation:* Ensure parent directory pre-creation in `./bootstrap.sh` and assert zero drift via `arch/dots-hyprland.sh verify --strict`.

## Implications for Roadmap

The implementation cleanly decomposes into 3 sequential phases:

1. **Phase 35: Voice Telemetry & State Service Architecture (`services/Voice.qml`)**
   - Implement `Voice.qml` Singleton service to observe `$XDG_RUNTIME_DIR/voice-stt/`.
   - Track STT states (`starting`, `recording`, `transcribing`, `typing`) and TTS states (`speaking`).
   - Liveness checking against `/proc/<pid>` to prevent stale lock states.
   - Live elapsed seconds counter with formatted duration string.
   - Automated service verification harness.

2. **Phase 36: Visual Voice Pill Component & Dynamic Animations (`VoicePill.qml`)**
   - Implement `VoicePill.qml` with `BarGroup` geometry and fluid 250ms M3 width animation.
   - Integrate `MaterialSymbol` with `auto_awesome` (sparkles) icon and reactive state color bindings.
   - Implement declarative audio waveform equalizer bars with smooth looping animations.
   - Support compact resting idle state and expanded active state with duration and status labels.

3. **Phase 37: Bar Layout Integration, Dual-Monitor Verification & Strict Packaging**
   - Integrate `VoicePill` into `BarContent.qml` Right zone immediately after Media (`mediaLoader`).
   - Reconcile `restow/quickshell/` deployment with GNU Stow.
   - Verify Material You palette reactivity across wallpaper switches via `switchwall.sh`.
   - Dual-monitor testing across ultrawide (`DP-1`) and secondary (`HDMI-A-1`) displays.
   - Strict repository integrity sign-off (`arch/dots-hyprland.sh verify --strict` 0 findings).

## Sources

- `/home/pera/github_repo/Voice/voice.py` — runtime state tracking and PID conventions.
- `restow/quickshell/.config/quickshell/ii/services/Privacy.qml` — reference for Quickshell IO integration.
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml` — 3-zone layout contracts.
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarGroup.qml` — pill styling and M3 width animation Behavior.

---
*Executive research summary for: Quickshell Desktop Shell v0.7*  
*Researched: 2026-09-21*  
