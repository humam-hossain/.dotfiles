# Pitfalls Research

**Domain:** Quickshell Status Bar Voice Component & Telemetry Integration  
**Researched:** 2026-09-21  
**Confidence:** HIGH  

## Critical Pitfalls

### Pitfall 1: QML Render Thread Blocking from Subprocesses

**What goes wrong:**
Calling synchronous shell commands (e.g. `sh -c "voice --status"`) or running synchronous process wait loops inside QML property bindings or timers causes frame drops, cursor stutter, and micro-freezes across the Hyprland desktop shell.

**Why it happens:**
Developers frequently write quick inline shell calls to query command-line tools without realizing that Quickshell's UI thread shares the event loop with QML JavaScript expressions.

**How to avoid:**
Never execute blocking CLI commands to probe state. Consume `$XDG_RUNTIME_DIR/voice-stt/` state files directly via Quickshell's asynchronous `FileView` or non-blocking timers. Let the voice worker write state, and let QML simply observe.

**Warning signs:**
Frame stutter when tapping `SUPER + SHIFT + M` or periodic UI hitching every second.

**Phase to address:**
Phase 1 (Service & Telemetry Architecture).

---

### Pitfall 2: High Frequency Polling & Battery Drain

**What goes wrong:**
Running tight polling loops (< 100ms) to detect voice recording starts keeps CPU cores in C0 states, generating unnecessary thermals and draining laptop batteries.

**Why it happens:**
Developers seek zero-latency visual feedback when the hotkey is pressed, resorting to 20–50ms timers.

**How to avoid:**
Use an adaptive timer strategy:
1. When idle: low-frequency check (e.g. 500ms–1000ms) to detect initial PID creation.
2. When active (recording or speaking): standard 1000ms duration clock tick and 200ms transition poll.
3. Smooth UI animations (pulse, waveform) are handled entirely GPU-side by QML `NumberAnimation` loops, independent of the polling rate.

**Warning signs:**
`quickshell` showing up in `top` or `powertop` with measurable CPU utilization while the desktop is idle.

**Phase to address:**
Phase 1 (Service & Telemetry Architecture).

---

### Pitfall 3: Stale PID State & Phantom Active Indicators

**What goes wrong:**
If the speech process crashes or is killed externally (e.g. `kill -9` or system restart), the `recorder.pid` or `tts.pid` file remains on disk, causing the status bar to show "Recording" or "Transcribing..." indefinitely.

**Why it happens:**
Abrupt process termination bypasses Python `finally:` cleanups.

**How to avoid:**
When `Voice.qml` reads a PID from the state file, it should verify process liveness (e.g., checking if `/proc/<pid>` exists or probing with a fail-soft check). If the process is dead, the state must immediately drop back to `"idle"`.

**Warning signs:**
The voice pill stays in "Recording" or "Transcribing" after a failed dictation run.

**Phase to address:**
Phase 1 (Service & Telemetry Architecture).

---

### Pitfall 4: Violating Design Language & Icon Inconsistency

**What goes wrong:**
Using generic microphone icons or importing random third-party SVGs clashes with the rest of the status bar.

**Why it happens:**
Defaulting to standard microphone icons (`mic`, `mic_none`) instead of respecting the user's explicit requirement for an AI visual identity that matches the system's Material Symbols font.

**How to avoid:**
Strictly use `MaterialSymbol.qml` with Google Material Symbols (`auto_awesome`, `graphic_eq`, `smart_toy`, `psychology`). Never hardcode custom SVG paths or non-system font glyphs. Bind colors directly to `Appearance.colors` (e.g. `colPrimary`, `colTertiary`, `colError`).

**Warning signs:**
Visual mismatch in line weight, style, or scaling compared to adjacent status bar icons (Media, Updates, Tray).

**Phase to address:**
Phase 2 (Visual Presentation & Animations).

---

### Pitfall 5: GNU Stow Symlink Folding & Tree Drift

**What goes wrong:**
Placing new QML files in `restow/quickshell/` without ensuring parent directories exist in `~/.config/quickshell/ii/` can cause GNU Stow to fold directories into whole-folder symlinks, breaking live hot-reloading or creating git churn.

**Why it happens:**
GNU Stow automatically folds ancestor directories if they don't already exist as physical directories on the target filesystem.

**How to avoid:**
1. Maintain explicit directory pre-creation in `./bootstrap.sh` and verification harnesses.
2. Deploy via leaf symlinks only (`stow --no-folding`).
3. Assert zero drift after deployment with `arch/dots-hyprland.sh verify --strict`.

**Warning signs:**
`arch/dots-hyprland.sh verify --strict` returning exit code 1 or 2 with findings.

**Phase to address:**
Phase 3 (Bar Integration & Verification).

---
*Pitfalls research for: Quickshell Voice Status Bar Pill*  
*Researched: 2026-09-21*  
