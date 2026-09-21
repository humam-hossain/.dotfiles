# Roadmap: Quickshell Desktop Shell (Milestone v0.7)

## Overview

Milestone v0.7 builds and integrates a custom Voice status bar component for the Quickshell desktop shell on Arch Linux / Hyprland. The component connects to the local `voice` CLI and speech runtime (`faster-whisper` STT and `Kokoro` TTS) located in `/home/pera/github_repo/Voice`, providing real-time visual telemetry, lifecycle indicators, duration counters, and animated audio waveforms in the top status bar.

The work is organized into 3 sequential phases: establishing the non-blocking state and telemetry service (`services/Voice.qml`), authoring the visual pill component with Material Symbols AI aesthetic and animated waveforms (`VoicePill.qml`), and integrating the component into the Right zone of `BarContent.qml` with dual-monitor verification and strict packaging.

## Phases

**Phase Numbering:**

- Integer phases (35, 36, 37): Planned milestone work continuing numbering from Milestone v0.6 (Phases 31–34).
- Decimal phases (35.1, 35.2): Urgent insertions if required.

- [x] **Phase 35: Voice Telemetry & State Service Architecture** - Implement `Voice.qml` Singleton service observing runtime state files with process liveness and duration tracking. (completed 2026-09-21)
- [x] **Phase 36: Visual Voice Pill Component & Dynamic Animations** - Author `VoicePill.qml` with `auto_awesome` AI iconography, pulse animations, animated waveform, and M3 width transitions. (completed 2026-09-21)
- [ ] **Phase 37: Bar Layout Integration, Dual-Monitor Verification & Strict Packaging** - Place Voice pill in `BarContent.qml` Right zone after Media, deploy via `restow/quickshell/`, verify Material You palette adaptation, and sign off with automated assertion harness.

## Phase Details

### Phase 35: Voice Telemetry & State Service Architecture

**Goal**: Build a centralized, non-blocking Quickshell Singleton service (`Voice.qml`) that observes `$XDG_RUNTIME_DIR/voice-stt/` state files, tracks STT/TTS lifecycles, validates PID liveness, and counts live elapsed duration.
**Depends on**: Milestone v0.6 overlay foundation
**Requirements**: TELEM-01, TELEM-02, TELEM-03, TELEM-04, TELEM-05
**Success Criteria** (what must be TRUE):

  1. Service detects and parses speech lifecycle states (`idle`, `starting`, `recording`, `transcribing`, `typing`, `speaking`) from `$XDG_RUNTIME_DIR/voice-stt/` asynchronously without blocking the UI thread.
  2. Process liveness verification against `/proc/<pid>` reliably purges stale PID states, automatically returning state to `idle` upon abnormal speech process termination.
  3. Active recording and TTS playback track live elapsed duration in seconds, exposing both raw seconds (`elapsedSeconds`) and formatted duration (`formattedDuration` as `M:SS`).
  4. Active TTS voice metadata is parsed and exposed to QML bindings.

**Plans:** 1/1 plans complete

Plans:

- [x] 35-01-PLAN.md — Implement Voice.qml Singleton service with state file observation, liveness check, duration timers, and TTS voice metadata extraction.

### Phase 36: Visual Voice Pill Component & Dynamic Animations

**Goal**: Author the dedicated `VoicePill.qml` status bar component styled with `BarGroup.qml` pill geometry, Material Symbols AI iconography, pulsing active states, animated audio waveform, and fluid Material 3 width expansion.
**Depends on**: Phase 35
**Requirements**: VOICE-01, VOICE-02, VOICE-03, VOICE-04, VOICE-05, VOICE-06
**Success Criteria** (what must be TRUE):

  1. `VoicePill.qml` renders within `BarGroup.qml` with standard rounded rectangle geometry (12–16px radius, 4–6px internal padding).
  2. Material Symbol `auto_awesome` (sparkles) icon displays with reactive color states matching the desktop shell's design language.
  3. Recording state triggers a fluid pulse animation and accent color change.
  4. Multi-bar animated audio waveform equalizer plays during active recording and speaking.
  5. Component displays live duration counter (`0:05`) and transition state badges ("Transcribing...", "Typing...").
  6. Component animates width expansion between compact resting state and expanded active telemetry state via 250ms Material 3 emphasized deceleration.

**Plans:** 1/1 plans complete

Plans:

- [x] 36-01-PLAN.md — Author `VoicePill.qml` with `BarGroup` container, `graphic_eq` icon, breathing pulse animation, duration label, wrap-up linger, and reactive state bindings.

### Phase 37: Bar Layout Integration, Dual-Monitor Verification & Strict Packaging

**Goal**: Integrate `VoicePill` into `BarContent.qml` Right zone immediately after Media (`mediaLoader`), deploy via `restow/quickshell/` leaf symlinks, verify Material You theming across wallpaper switches, and validate with an automated assertion test harness.
**Depends on**: Phase 36
**Requirements**: INTG-01, INTG-02, INTG-03, INTG-04
**Success Criteria** (what must be TRUE):

  1. `VoicePill` is integrated into `BarContent.qml` Right zone positioned immediately after Media (`mediaLoader`) with clean 4px gaps.
  2. QML files are packaged in `restow/quickshell/` and deployed via GNU Stow leaf symlinks without folding ancestor directories or touching `vendor/dots-hyprland`.
  3. Voice pill colors adapt reactively to wallpaper switches via `switchwall.sh` Matugen tokens with zero working tree drift.
  4. Automated test harness (`scripts/phase35-voice-pill-assert.sh`) verifies QML syntax, state binding, and strict repository integrity (`arch/dots-hyprland.sh verify --strict` 0 findings).

**Plans**: 1 plan (37-01)

Plans:

- [ ] 37-01: Update `BarContent.qml`, deploy via Stow, verify wallpaper theme reactivity and multi-monitor balance, and execute validation test harness.

## Progress

**Execution Order:**
Phases execute in numeric order: 35 → 36 → 37

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 35. Voice Telemetry & State Service Architecture | 1/1 | Complete    | 2026-09-21 |
| 36. Visual Voice Pill Component & Dynamic Animations | 1/1 | Complete    | 2026-09-21 |
| 37. Bar Layout Integration, Dual-Monitor Verification & Strict Packaging | 0/1 | Not started | - |

---
*Roadmap created: 2026-09-21*  
*Milestone: v0.7 Voice Status Bar Component & Audio Telemetry*  
