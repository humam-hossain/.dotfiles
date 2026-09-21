# Requirements: Quickshell Desktop Shell (Milestone v0.7)

**Defined:** 2026-09-21  
**Core Value:** Desktop capability via upstream dots-hyprland + personal overlays with unified system-wide Material You theming across GTK, Qt/KDE, Hyprland, Quickshell ii, and terminal/launcher tools with zero git churn.  

## Milestone v0.7 Requirements

Requirements for Milestone v0.7: Voice Status Bar Component & Audio Telemetry. Each requirement maps to roadmap phases.

### Telemetry & State Service

- [x] **TELEM-01**: User has a dedicated Quickshell Singleton service (`Voice.qml`) that observes `$XDG_RUNTIME_DIR/voice-stt/` state files asynchronously without blocking the UI thread.
- [x] **TELEM-02**: Service detects and parses full speech lifecycle states (`idle`, `starting`, `recording`, `transcribing`, `typing`, and `speaking`).
- [x] **TELEM-03**: Service implements process liveness verification against `/proc/<pid>` to prevent stale PID locks from persisting on abnormal process termination.
- [x] **TELEM-04**: Service provides a live elapsed duration counter (`elapsedSeconds` and `formattedDuration` as `M:SS`) tracking active recording and TTS playback time.
- [x] **TELEM-05**: Service extracts and exposes active TTS voice metadata (e.g. Kokoro `af_heart`) during speech synthesis.

### Voice Component & Animations

- [ ] **VOICE-01**: User sees a dedicated `VoicePill.qml` status bar pill styled with `BarGroup.qml` rounded rectangle geometry (12–16px corner radius, 4–6px internal padding).
- [ ] **VOICE-02**: Component displays an AI visual symbol (`auto_awesome` / sparkles) rendered via `MaterialSymbol.qml` that matches the desktop shell's design language.
- [ ] **VOICE-03**: Component displays a reactive pulse animation and accent color change during active STT recording.
- [ ] **VOICE-04**: Component displays dynamic animated audio wave bars during active recording and speaking states.
- [ ] **VOICE-05**: Component displays live duration text (`0:05`) while recording/speaking and status badges ("Transcribing...", "Typing...") during state transitions.
- [ ] **VOICE-06**: Component smoothly transitions width between a compact resting state and an expanded active telemetry state using Material 3 250ms emphasized deceleration.

### Layout & System Integration

- [ ] **INTG-01**: Component is integrated into `BarContent.qml` Right zone positioned immediately after Media (`mediaLoader`).
- [ ] **INTG-02**: Component and service are deployed under `restow/quickshell/` via GNU Stow leaf symlinks without folding ancestor directories or modifying `vendor/dots-hyprland`.
- [ ] **INTG-03**: Component dynamically adapts to active wallpaper Material You palette tokens via Matugen without hardcoded hex colors or git working-tree churn.
- [ ] **INTG-04**: Milestone deliverables pass an automated multi-section assertion test harness and strict repository verification (`arch/dots-hyprland.sh verify --strict` 0 findings).

## Future Requirements (v0.8+)

Deferred to future releases. Tracked but not in current roadmap.

### Interactive Voice Controls & Dashboard

- **VOICE-F01**: Click interactions to toggle STT recording or speak selected text directly from the bar.
- **VOICE-F02**: Voice settings popup to switch Kokoro TTS voices and adjust speech speed multiplier.
- **VOICE-F03**: Microphone input selector and audio sensitivity gauge in a voice popup.
- **VOICE-F04**: Recent transcriptions history preview on hover or popup click.

## Out of Scope

Explicitly excluded to maintain stability and prevent scope creep.

| Feature | Reason |
|---------|--------|
| Generic microphone glyphs (`mic`, `mic_none`) | Explicitly rejected by operator in favor of an AI assistant visual language (`auto_awesome`). |
| Clickable popup menus and action buttons in v0.7 | Operator explicitly requested pure telemetry with no click interactions for this milestone. |
| Custom background IPC socket daemon | Unnecessary complexity; existing `voice.py` CLI already writes runtime state files to `$XDG_RUNTIME_DIR/voice-stt/`. |
| Modifying `vendor/dots-hyprland` directly | Violates repository architectural invariant; all overrides must live in `restow/quickshell/`. |
| Real-time PipeWire audio FFT capture in QML | High CPU overhead; simulated declarative wave bars provide fluid visual feedback with zero CPU drain. |

## Traceability

Which phases cover which requirements. Populated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| TELEM-01 | Phase 35 | Complete |
| TELEM-02 | Phase 35 | Complete |
| TELEM-03 | Phase 35 | Complete |
| TELEM-04 | Phase 35 | Complete |
| TELEM-05 | Phase 35 | Complete |
| VOICE-01 | Phase 36 | Pending |
| VOICE-02 | Phase 36 | Pending |
| VOICE-03 | Phase 36 | Pending |
| VOICE-04 | Phase 36 | Pending |
| VOICE-05 | Phase 36 | Pending |
| VOICE-06 | Phase 36 | Pending |
| INTG-01 | Phase 37 | Pending |
| INTG-02 | Phase 37 | Pending |
| INTG-03 | Phase 37 | Pending |
| INTG-04 | Phase 37 | Pending |

**Coverage:**

- v0.7 requirements: 15 total
- Mapped to phases: 15
- Unmapped: 0 ✓

---
*Requirements defined: 2026-09-21*  
*Last updated: 2026-09-21 — Milestone v0.7 scoped*  
