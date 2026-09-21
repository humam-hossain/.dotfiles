# Phase 35: Voice Telemetry & State Service Architecture - Context

**Gathered:** 2026-09-21
**Status:** Ready for planning

<domain>
## Phase Boundary

Implement a centralized, non-blocking Quickshell Singleton service (`Voice.qml` located under `restow/quickshell/.config/quickshell/ii/services/`) observing `$XDG_RUNTIME_DIR/voice-stt/` state files:

1. **State Observation & Parsing (TELEM-01, TELEM-02):** Observe runtime state files (`recorder.pid`, `tts.pid`, and process telemetry) using native `FileView` with adaptive polling intervals (100ms active / 500ms idle). Detect and parse full speech lifecycle states: `idle`, `starting`, `recording`, `transcribing`, `typing`, and `speaking`.
2. **Process Liveness & Stale Lock Invalidation (TELEM-03):** Verify process liveness and command identity against `/proc/<pid>/cmdline`. Automatically purge stale or recycled PID files using `Quickshell.execDetached` and return state to `idle`.
3. **Elapsed Duration Counter (TELEM-04):** Compute drift-free duration via wall-clock timestamps (`Date.now() - startTime`) anchored to process start time for Quickshell reload recovery (`Ctrl+Super+R`). Expose both integer `elapsedSeconds` / `formattedDuration` (`M:SS`) and fractional `elapsedMs`. Freeze duration during `transcribing` and `typing` phases, resetting on return to `idle`.
4. **TTS Voice Metadata Extraction (TELEM-05):** Extract active TTS voice ID (e.g. Kokoro `af_heart`) and backend from `/proc/<tts_pid>/cmdline`, falling back to Kokoro defaults.

Out of scope:
- Visual Voice Pill component (`VoicePill.qml`), audio waveform visualization, and pulse styling (Phase 36 owns this).
- Status bar placement in `BarContent.qml`, dual-monitor validation, and milestone packaging (Phase 37 owns this).
- Hover tooltips, transcript history popups, and click interactions (explicitly deferred per user instruction).

</domain>

<decisions>
## Implementation Decisions

### Observation & Polling Architecture (TELEM-01)
- **D-01 (Adaptive Polling via FileView):** Monitor `$XDG_RUNTIME_DIR/voice-stt/` files using native Quickshell `FileView` coupled to an adaptive QML `Timer`. Polling frequency throttles dynamically: 100ms when any activity or transition is underway (`starting`, `recording`, `transcribing`, `typing`, `speaking`), relaxing to 500ms when completely `idle`. Eliminates child subprocess overhead and leverages Linux tmpfs RAM speed. — **Reversibility:** reversible.
- **D-02 (Unified Cmdline Read for Liveness & Voice Metadata):** Read `/proc/<tts_pid>/cmdline` via `FileView` in a single pass. Simultaneously validates process liveness/identity (checking for `"voice"`) and extracts `--tts-voice` (e.g. `af_heart`) and `--tts-backend` (`kokoro`), falling back gracefully to runtime defaults (`af_heart`). — **Reversibility:** reversible.
- **D-03 (Cold-Boot Silent Defaulting):** If `$XDG_RUNTIME_DIR/voice-stt/` or its `.pid` files do not exist at system startup, `Voice.qml` silently defaults all states to `idle` and duration to `0`, suppressing all console error/warning noise until files appear. — **Reversibility:** reversible.

### State Precedence & Transition Flow (TELEM-02)
- **D-04 (STT Priority with Discrete Sub-States):** Expose discrete reactive properties `sttState` (`"idle"`, `"starting"`, `"recording"`, `"transcribing"`, `"typing"`), `ttsState` (`"idle"`, `"speaking"`), and a synthesized `overallState`. If both STT and TTS processes overlap, STT user input takes precedence according to: `recording` > `transcribing` > `speaking` > `typing` > `starting` > `idle`. — **Reversibility:** reversible.
- **D-05 (Explicit State Emission & Resilient Fallback):** Update `voice.py` to explicitly publish `typing` during text insertion (`write_pid_state(pid, "typing")`) and `speaking` during speech playback (`write_pid_state(pid, "speaking", TTS_PID_FILE)`). `Voice.qml` also implements resilient fallback mapping any active `tts.pid` to `speaking` and inferring `typing` if `voice.py` is un-updated. — **Reversibility:** reversible.
- **D-06 (Visual Linger Window for Rapid Insertion):** When transitioning from `transcribing` to `typing`, start a 1000ms single-shot QML timer (`typingLingerTimer`) holding `sttState = "typing"` and `overallState = "typing"`. Prevents rapid text insertion (50–200ms) from flickering imperceptibly before returning to `idle`, even if `recorder.pid` is unlinked immediately on disk. — **Reversibility:** reversible.

### Duration Counter Precision & Lifecycle (TELEM-04)
- **D-07 (Wall-Clock Timestamp Anchor & Reload Recovery):** Calculate elapsed duration using `Date.now() - startTime`. On Quickshell reload (`Ctrl+Super+R`), inspect `/proc/<pid>` or file mtime to anchor `startTime` to the process creation timestamp, preventing duration from resetting to 0 mid-recording. — **Reversibility:** reversible.
- **D-08 (Processing Duration Freeze & Idle Reset):** Freeze `elapsedSeconds` and `formattedDuration` at the final speech recording length (e.g. `0:14`) during `transcribing` and `typing`, providing clear operator feedback while transcription executes. Reset duration to `0` / `"0:00"` when the service returns to `idle`. — **Reversibility:** reversible.
- **D-09 (Dual-Resolution Metrics & Limit Metadata):** Expose both integer `elapsedSeconds` (1s updates for `formattedDuration` `"M:SS"`) and fractional `elapsedMs` (for smooth waveform and pulse animations in Phase 36), along with `readonly property int maxDurationSeconds: 300` reflecting the 5-minute safety limit. — **Reversibility:** reversible.

### Process Liveness & Stale Lock Invalidation (TELEM-03)
- **D-10 (Cmdline Process Verification & Automated Purge):** Verify `/proc/<pid>/cmdline` contains `"voice"` via `FileView`. If the PID is dead or recycled by the OS, automatically purge the stale `.pid` file using `Quickshell.execDetached(["rm", "-f", path])` and return the service state to `idle`. — **Reversibility:** reversible.
- **D-11 (Silent Console Recovery Logging):** On purging a stale lock, emit a discreet `console.warn("[Voice] Purged stale PID lock: " + pid)` without triggering desktop notification popups, keeping the desktop notification space quiet. — **Reversibility:** reversible.

### the agent's Discretion
- Exact easing parameters and duration for the typing linger timer (default 1000ms).
- Exact internal helper functions in `Voice.qml` for parsing null-delimited `/proc/<pid>/cmdline` buffers.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap & Requirements
- `.planning/ROADMAP.md` §Phase 35 — Phase goal, requirements mapping, and success criteria.
- `.planning/REQUIREMENTS.md` lines 12–16 — TELEM-01 through TELEM-05 specifications.
- `.planning/STATE.md` §Milestone v0.7 — Accumulated milestone context.

### Speech Runtime Implementation & State Files
- `/home/pera/github_repo/Voice/voice.py` lines 44–48 — `STATE_DIR`, `PID_FILE`, `TTS_PID_FILE`, and `LOG_FILE` definitions.
- `/home/pera/github_repo/Voice/voice.py` lines 588–615 — `read_pid_state`, `write_pid_state`, and process lifecycle handlers.
- `/home/pera/github_repo/Voice/voice.py` lines 1041–1055, 1170–1220 — TTS background execution and argument structure (`--tts-voice`, `--tts-backend`).
- `/run/user/1000/voice-stt/` — Live runtime directory for PID locks and logs.

### Quickshell Services Architecture & Patterns
- `vendor/dots-hyprland/dots/.config/quickshell/ii/services/ResourceUsage.qml` — Polling patterns, `FileView` usage, and dynamic intervals.
- `restow/quickshell/.config/quickshell/ii/services/Privacy.qml` — Primitive status service and process execution (`Process`, `pgrep`).
- `restow/quickshell/.config/quickshell/ii/services/Updates.qml` — Asynchronous shell process execution and state management.

### Repository Stow & Overlay Architecture
- `collision-map.tsv` line 83 — `$XDG_CONFIG_HOME/quickshell` tracked as `restow` (`rsync-replace`).
- `restow/README.md` — Restow contract and `--no-folding` symlink rules.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Quickshell.Io.FileView`: Native C++ element for asynchronous, non-blocking file reads on Linux tmpfs (`/proc/` and `$XDG_RUNTIME_DIR/`).
- `Quickshell.execDetached`: Lightweight process execution utility for non-blocking operations like `rm -f` stale lock cleanup.
- `QML Timer`: For adaptive 100ms/500ms polling shifts and 1000ms visual linger windows.

### Established Patterns
- Singleton Services: Services in `services/` declare `pragma Singleton` and `pragma ComponentBehavior: Bound` for global QML binding accessibility.
- Restow Overlay Discipline: Custom services reside in `restow/quickshell/.config/quickshell/ii/services/` and are symlinked with GNU Stow `--no-folding`.
- Non-blocking I/O: UI thread must never stall waiting on child processes or file reads.

### Integration Points
- `restow/quickshell/.config/quickshell/ii/services/Voice.qml` -> symlinked to `~/.config/quickshell/ii/services/Voice.qml`.
- Downstream consumer `VoicePill.qml` (Phase 36) binds directly to `Voice.overallState`, `Voice.formattedDuration`, `Voice.elapsedMs`, and `Voice.ttsVoice`.

</code_context>

<specifics>
## Specific Ideas

- **User Directives from Speech Transcript:**
  - *"So we will create a component for voice and it should basically tell me everything... there has to be some status like speaking yes status idle recording speaking then let's say when I'm using SST after I stop speaking then it starts to like convert it to text so it should show in this status convert into text or transcribing or whatever that will show and then when it's done then it starts writing right then it should show that it's writing in this status when it's finished and it goes back to idle"*
  - *"it should like a recording style type of thing has to have it has to be there live duration yeah current TTS voice yes that's also too"*
  - *"recent transcription preview tools tooltip on hover tooltip we don't need it right now we'll think about it later"*
  - *"Right now we don't need anything about click interactions. We don't need that."*

</specifics>

<deferred>
## Deferred Ideas

- **Phase 36 (Visual Voice Pill Component & Dynamic Animations):**
  - AI sparkle icon (`auto_awesome` from Material Symbols) matching desktop shell visual language.
  - Pulsing active recording indicators and animated waveform visualizations for STT vs TTS.
  - Fluid Material 3 pill width transitions.
- **Phase 37 (Bar Layout Integration, Dual-Monitor Verification & Strict Packaging):**
  - Placement in `BarContent.qml` Right zone.
  - Multi-monitor (`DP-1` and `HDMI-A-1`) layout testing and Matugen theme adaptation.
  - Automated test harness `scripts/phase35-voice-service-assert.sh` and milestone regression pass.
- **Future Milestone Considerations:**
  - Hover tooltips showing recent transcription previews.
  - Interactive click actions (e.g. click to cancel or toggle mute).

</deferred>

---

*Phase: 35-voice-telemetry-state-service-architecture*
*Context gathered: 2026-09-21*
