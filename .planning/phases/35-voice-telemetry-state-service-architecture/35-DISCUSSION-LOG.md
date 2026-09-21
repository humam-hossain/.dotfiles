# Phase 35: Voice Telemetry & State Service Architecture - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-21
**Phase:** 35-voice-telemetry-state-service-architecture
**Areas discussed:** Observation & Polling Strategy, State Precedence & Transition Flow, Duration Counter Precision & Lifecycle, PID Liveness & Stale Lock Handling

---

## Observation & Polling Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Adaptive Polling via FileView | Fast 100ms poll when active/transitioning, slow 500ms poll when idle (low CPU, zero subprocess overhead) | ✓ |
| Inotify Event Streaming | Long-running 'inotifywait' Process listening for file events in $XDG_RUNTIME_DIR/voice-stt/ | |
| Constant Polling | Fixed 200ms timer interval regardless of state | |
| You decide | Adaptive polling with 100ms active / 500ms idle | |

**User's choice:** Adaptive Polling via FileView
**Notes:** User requested a detailed pros/cons breakdown of each option. We evaluated that native QML `FileView` reading tmpfs RAM files avoids subprocess management, eliminates crash cascades, and delivers sub-perceptible latency (100ms active / 500ms idle).

### TTS Voice Metadata Extraction

| Option | Description | Selected |
|--------|-------------|----------|
| Read /proc/<tts_pid>/cmdline via FileView | Zero modification to voice runtime, extracts exact --tts-voice and --tts-backend directly from the active process | ✓ |
| Direct Metadata File in state dir | Enhance voice.py to write tts_meta.json ($STATE_DIR/tts_meta.json) with voice name and backend | |
| Parse tts.log header | Read the latest speak session banner from $XDG_RUNTIME_DIR/voice-stt/voice.log | |
| You decide | Proc cmdline with Kokoro af_heart fallback | |

**User's choice:** Read `/proc/<tts_pid>/cmdline` via `FileView`
**Notes:** Keeps voice runtime decoupled while directly parsing `--tts-voice` arguments from the running process.

### Cold-Boot / Missing Directory Handling

| Option | Description | Selected |
|--------|-------------|----------|
| Silent Graceful Handling | Treat missing directory or files as 'idle' and suppress console warning spam until files appear | ✓ |
| Auto-create Directory at Init | Run 'mkdir -p $XDG_RUNTIME_DIR/voice-stt' on service startup | |
| You decide | Silent graceful defaults to 'idle' | |

**User's choice:** Silent Graceful Handling
**Notes:** If `$XDG_RUNTIME_DIR/voice-stt/` does not exist on fresh system boot before first voice trigger, default to `idle` cleanly without warning noise.

---

## State Precedence & Transition Flow

| Option | Description | Selected |
|--------|-------------|----------|
| STT Priority with Dedicated Sub-states | Expose overallState with STT priority (recording > transcribing > speaking > typing > starting > idle), while also exposing discrete sttState and ttsState properties | ✓ |
| Strict Exclusive Mutex | Only allow one active state at a time, immediately suppressing TTS state whenever any STT state is not idle | |
| Unified Flattened Enum | Only expose a single 'state' string without separate sub-state properties | |
| You decide | STT priority with dedicated sub-states | |

**User's choice:** STT Priority with Dedicated Sub-states
**Notes:** User requested a thorough explanation of Option 1 and how both STT and TTS processes are tracked. Explained that `recording` takes precedence as live human speech input, while keeping `sttState` and `ttsState` independent prevents state collisions.

### State Emission Synchronization

| Option | Description | Selected |
|--------|-------------|----------|
| Explicit Runtime State Emission | Update voice.py to explicitly write 'typing' during text insertion and 'speaking' for TTS, with Voice.qml gracefully falling back if older runtime is used | ✓ |
| Inference in Voice.qml Only | Keep voice.py untouched; Voice.qml maps any active tts.pid to 'speaking' and infers 'typing' transiently | |
| You decide | Update voice.py for explicit typing/speaking + QML fallback | |

**User's choice:** Explicit Runtime State Emission (with QML fallback)
**Notes:** Ensures clean runtime contract between `voice.py` and desktop shell.

### Visual Linger for Rapid Completions

| Option | Description | Selected |
|--------|-------------|----------|
| Visual Linger Window (800ms–1.2s) | Keep 'typing' visible for a brief moment even if insertion finishes in milliseconds, ensuring clear human feedback before returning to 'idle' | ✓ |
| Instant Raw Transition | Transition to 'idle' immediately the millisecond the file/process disappears | |
| You decide | 1.0s minimum linger for typing before returning to idle | |

**User's choice:** Visual Linger Window (800ms–1.2s)
**Notes:** Decoupled from disk deletion: when `typing` starts, a 1000ms QML timer holds the visual state so the user sees completion feedback before transitioning to `idle`.

---

## Duration Counter Precision & Lifecycle

| Option | Description | Selected |
|--------|-------------|----------|
| Wall-clock Timestamp with Proc/File Start Anchor | Store timestamp on state transition and anchor to process start time if Quickshell reloads (zero drift, seamless reload recovery) | ✓ |
| Simple QML Incremental Tick | Start at 0 on state transition and increment a counter every 1000ms via QML Timer | |
| You decide | Wall-clock timestamp with reload recovery | |

**User's choice:** Wall-clock Timestamp with Proc/File Start Anchor
**Notes:** Eliminates timer drift and recovers true duration if Quickshell is reloaded mid-recording via `Ctrl+Super+R`.

### Duration Display During Processing

| Option | Description | Selected |
|--------|-------------|----------|
| Freeze Duration during Processing, Reset on Idle | Freeze elapsed time at the final recording length (e.g. '0:14') while transcribing/typing, then reset to '0:00' when returning to idle | ✓ |
| Reset Immediately on Stop | Reset elapsed duration to '0:00' the exact moment recording stops | |
| Continuous Total Time | Keep ticking upward through transcription and typing | |
| You decide | Freeze during processing, reset on idle | |

**User's choice:** Freeze Duration during Processing, Reset on Idle
**Notes:** Operator can see how long their speech was while Whisper transcribes it and text is typed.

### Duration Resolution & Metadata

| Option | Description | Selected |
|--------|-------------|----------|
| Dual Resolution + Max Limit Exposure | Expose both integer elapsedSeconds (1s ticks for formattedDuration 'M:SS') and raw elapsedMs (for smooth waveform/animations), along with maxDurationSeconds (300s limit) | ✓ |
| Pure 1-Second Integer Resolution | Keep it minimal with integer seconds and 'M:SS' string only | |
| You decide | Dual resolution with max limit metadata | |

**User's choice:** Dual Resolution + Max Limit Exposure
**Notes:** Exposes both text duration and high-precision millisecond timing for Phase 36 animation shaders and waveforms.

---

## PID Liveness & Stale Lock Handling

| Option | Description | Selected |
|--------|-------------|----------|
| Proc Cmdline Validation + Auto Purge File | Verify /proc/<pid>/cmdline contains 'voice' via FileView; if dead or recycled, purge the stale .pid file with Quickshell.execDetached(['rm', '-f', ...]) and return to 'idle' | ✓ |
| Passive State Reset Only | If /proc/<pid> is dead, reset QML service state to 'idle' but do not delete the file on disk | |
| Process Polling via kill -0 | Run 'kill -0 <pid>' via Process component on every check | |
| You decide | Cmdline verification + auto purge | |

**User's choice:** Proc Cmdline Validation + Auto Purge File
**Notes:** Automatically unblocks both the desktop UI and the CLI if an abnormal process termination leaves a dead PID lock behind.

### Stale Lock Notification Level

| Option | Description | Selected |
|--------|-------------|----------|
| Silent Console Log | Emit console.warn('[Voice] Purged stale PID lock...') in Quickshell log without disturbing user with desktop popups | ✓ |
| Desktop Notification Alert | Send a brief low-urgency desktop notification via notify-send | |
| You decide | Silent console warning log | |

**User's choice:** Silent Console Log
**Notes:** Self-healing service without noisy popup notifications.

---

## the agent's Discretion

- Exact easing curve parameters and duration for the typing linger timer (default 1000ms).
- Exact regex / split helpers for parsing null-delimited `/proc/<pid>/cmdline` buffers in QML.

## Deferred Ideas

- Visual Voice Pill component design (`VoicePill.qml`), AI sparkles icon, pulsing active states, and waveform visualization (Phase 36).
- Status bar placement in `BarContent.qml` Right zone, dual-monitor verification, and packaging (Phase 37).
- Hover tooltips showing recent transcription previews (future milestone).
- Interactive click actions on status bar pill (future milestone).
