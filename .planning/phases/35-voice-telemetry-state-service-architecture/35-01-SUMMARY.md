---
phase: 35-voice-telemetry-state-service-architecture
plan: 01
subsystem: ui
tags: [quickshell, qml, voice, stt, tts, telemetry, procfs, linux]

requires:
  - phase: 34-verification-zero-drift-bootstrap-integration
    provides: Restow overlay symlink discipline, strict verification harness, and Quickshell service patterns
provides:
  - Centralized Voice.qml Singleton service in restow/quickshell/.config/quickshell/ii/services/
  - Speech lifecycle state machine (idle, starting, recording, transcribing, typing, speaking)
  - Precedence hierarchy with STT priority and 1000ms visual typing linger window
  - Procfs process liveness verification and automated stale PID lock purging via Quickshell.execDetached
  - Drift-free wall-clock duration calculation with procfs reload recovery anchor
  - Null-delimited TTS voice metadata extraction (--tts-voice, --tts-backend)
  - 6-section automated assertion test harness scripts/phase35-voice-telemetry-assert.sh
  - Published speaking and typing state emissions in /home/pera/github_repo/Voice/voice.py
affects: [36-voice-pill-component-audio-visualizer, 37-bar-layout-integration-packaging]

actuals:
  tokens: 45000
  tasks: 3
  commits: 2

tech-stack:
  added: []
  patterns:
    - Quickshell Singleton service observing RAM tmpfs via FileView with adaptive polling (100ms active / 500ms idle)
    - Procfs cmdline liveness validation and silent Quickshell.execDetached stale lock cleanup
    - Wall-clock Date.now() duration calculation with /proc/<pid>/stat field 22 reload recovery

key-files:
  created:
    - restow/quickshell/.config/quickshell/ii/services/Voice.qml
    - scripts/phase35-voice-telemetry-assert.sh
  modified:
    - /home/pera/github_repo/Voice/voice.py

key-decisions:
  - "D-01: Adaptive polling via native FileView shifting between 100ms when active and 500ms when idle."
  - "D-02: Unified /proc/<tts_pid>/cmdline read for process liveness and null-delimited --tts-voice / --tts-backend extraction."
  - "D-03: Cold-boot silent defaulting with printErrors: false and blockLoading: true on all FileView instances."
  - "D-04: STT precedence hierarchy: recording > transcribing > speaking > typing > starting > idle."
  - "D-05: Explicit state publication in voice.py (speaking during audio playback, typing before text insertion)."
  - "D-06: 1000ms visual linger timer on transcribing-to-typing transition to prevent UI flicker on fast text insertion."
  - "D-07: Drift-free wall-clock duration calculation anchored to /proc/<pid>/stat field 22 start time across Quickshell reload."
  - "D-08: Duration metrics freeze at final recorded length during transcribing and typing, resetting to 0 on return to idle."
  - "D-09: Dual-resolution duration metrics (elapsedSeconds, elapsedMs) and maxDurationSeconds safety limit (300s)."
  - "D-10: Stale or recycled PID lock purging using Quickshell.execDetached(['rm', '-f', path])."
  - "D-11: Discrete console warning logging on stale lock purge without desktop notification popups."

patterns-established:
  - "Pattern 1: Non-blocking tmpfs observation via FileView with dynamic Timer interval."
  - "Pattern 2: Procfs process identity validation against command line tokens."
  - "Pattern 3: Process reload recovery anchor using Linux kernel procfs uptime and stat jiffies."

requirements-completed:
  - TELEM-01
  - TELEM-02
  - TELEM-03
  - TELEM-04
  - TELEM-05

coverage:
  - id: D1
    description: "Dedicated Quickshell Singleton service (Voice.qml) observing $XDG_RUNTIME_DIR/voice-stt/ state files asynchronously"
    requirement: TELEM-01
    verification:
      - kind: integration
        ref: "./scripts/phase35-voice-telemetry-assert.sh --section 1"
        status: pass
    human_judgment: false
  - id: D2
    description: "Speech lifecycle state detection and strict priority hierarchy with 1000ms typing linger"
    requirement: TELEM-02
    verification:
      - kind: integration
        ref: "./scripts/phase35-voice-telemetry-assert.sh --section 2"
        status: pass
    human_judgment: false
  - id: D3
    description: "Process liveness verification against /proc/<pid>/cmdline and automated stale lock purge"
    requirement: TELEM-03
    verification:
      - kind: integration
        ref: "./scripts/phase35-voice-telemetry-assert.sh --section 3"
        status: pass
    human_judgment: false
  - id: D4
    description: "Live elapsed duration counter, transcription freeze, idle reset, and reload recovery anchor"
    requirement: TELEM-04
    verification:
      - kind: integration
        ref: "./scripts/phase35-voice-telemetry-assert.sh --section 4"
        status: pass
    human_judgment: false
  - id: D5
    description: "Active TTS voice metadata extraction from /proc/<tts_pid>/cmdline with fallback defaults"
    requirement: TELEM-05
    verification:
      - kind: integration
        ref: "./scripts/phase35-voice-telemetry-assert.sh --section 5"
        status: pass
    human_judgment: false

duration: 12 min
completed: 2026-09-21
status: complete
---

# Phase 35 Plan 01: Voice Telemetry & State Service Architecture Summary

**Centralized non-blocking Quickshell Singleton service (`Voice.qml`) implemented in `restow/quickshell/` with procfs liveness validation, drift-free duration counting, and TTS voice metadata extraction, verified by a comprehensive 6-section automated assertion suite.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-09-21T03:37:00Z
- **Completed:** 2026-09-21T03:45:00Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Implemented `Voice.qml` as a centralized QML Singleton (`restow/quickshell/.config/quickshell/ii/services/Voice.qml`) deployed via GNU Stow without directory folding.
- Added adaptive polling timer (100ms during speech activity, 500ms during idle) using native `Quickshell.Io.FileView` over RAM tmpfs (`$XDG_RUNTIME_DIR/voice-stt/`).
- Full speech lifecycle state tracking (`idle`, `starting`, `recording`, `transcribing`, `typing`, `speaking`) with strict priority hierarchy (`recording` > `transcribing` > `speaking` > `typing` > `starting` > `idle`) and a 1000ms visual typing linger window to prevent UI flicker on fast text insertion.
- Procfs process liveness verification against `/proc/<pid>/cmdline` and automated stale PID lock cleanup via `Quickshell.execDetached(["rm", "-f", path])` with discrete warning logs.
- Drift-free wall-clock duration calculation exposing `elapsedSeconds`, `elapsedMs`, and `formattedDuration` (`M:SS`), frozen during transcription and typing, resetting on idle, and recovering across Quickshell reloads via `/proc/<pid>/stat` field 22 start time.
- Extraction of active TTS voice ID (`--tts-voice`) and backend (`--tts-backend`) from null-delimited `/proc/<tts_pid>/cmdline` buffers with fallback to Kokoro defaults (`af_heart`).
- Published explicit `speaking` and `typing` states in `/home/pera/github_repo/Voice/voice.py`.
- Authored and verified the automated 6-section assertion test harness `scripts/phase35-voice-telemetry-assert.sh` passing all checks with zero findings and zero git working-tree churn.

## Task Commits

1. **Task 1: End-to-end voice telemetry tracer — state emission, assert harness, and Quickshell Singleton service** - `6c5006b` (feat)
2. **Task 2: Process liveness verification and automated stale PID lock purging** - verified in `6c5006b` (feat)
3. **Task 3: Elapsed duration counter with procfs reload anchor and TTS voice metadata extraction** - `89a5a75` (feat)

**Voice daemon updates:** `7186bb8` in `/home/pera/github_repo/Voice` (feat)

## Self-Check: PASSED

- All key files created exist on disk:
  - `restow/quickshell/.config/quickshell/ii/services/Voice.qml`
  - `scripts/phase35-voice-telemetry-assert.sh`
- All acceptance criteria from tasks 1, 2, and 3 pass:
  - `./scripts/phase35-voice-telemetry-assert.sh` passed with `FAIL=0 FINDINGS=0`
  - `./arch/dots-hyprland.sh verify --strict` passed with `FAIL=0 FINDINGS=0`
- Commits found in git history: `6c5006b`, `89a5a75`
