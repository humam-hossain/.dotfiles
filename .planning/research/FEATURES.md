# Feature Research

**Domain:** Quickshell Status Bar Voice Component (STT & TTS Telemetry)  
**Researched:** 2026-09-21  
**Confidence:** HIGH  

## Feature Landscape

### Table Stakes (Users Expect These)

Features required for a complete, production-ready Voice status component.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| AI Visual Identity | Generic mic icon does not communicate AI transcription/synthesis; user explicitly requested an AI-centric icon matching the existing Material Symbols visual language. | LOW | Use `auto_awesome` (sparkles) or `smart_toy` / `psychology` rendered via `MaterialSymbol.qml`. |
| STT Recording Indicator | User must know immediately that the system is actively capturing speech. | LOW | Pulse animation, accent color change (e.g. primary or error/red tone), and recording state text. |
| Live Duration Timer | When recording or speaking, users need to see the elapsed time in seconds (`0:03`, `0:15`) as an indicator of capture duration. | LOW | Elapsed time timer formatted as `M:SS` or `S`s, active only during recording/speaking. |
| STT Transcribing State | After the user stops talking, there is a compute window where Whisper processes audio; without feedback, user might think the app froze or failed. | MEDIUM | Distinct state badge ("Transcribing..."), animated wave or spinner. |
| STT Writing/Typing State | Indicates that text injection into the focused Wayland window is active. | LOW | Brief "Typing..." state or pen/text indicator before resetting to idle. |
| TTS Speaking State | Visual indication that speech playback is active, preventing confusion if audio output is soft or routed to headphones. | LOW | Audio wave icon/animation, elapsed playback time, and active voice name/badge (e.g. `af_heart`). |
| Clean Reset to Idle | Once transcription or speech finishes, the component must smoothly return to resting idle state without stuck indicators. | LOW | Reset state variables, stop duration timers, collapse expanded pill width smoothly. |
| Status Bar Placement | Placed in Right zone after Media (`mediaLoader`), harmonizing with the 3-zone modular layout established in v0.6. | LOW | Add `VoicePill` Loader right after `mediaLoader` in `BarContent.qml`. |
| Standardized Pill Geometry | Consistent with the desktop shell's rounded rectangle pill geometry (12–16px radius, 4–6px padding, 250ms M3 emphasized deceleration width transition). | LOW | Encapsulated within `BarGroup.qml`. |

### Differentiators (Competitive Advantage)

Features that provide exceptional user experience and desktop polish.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Animated Audio Equalizer Wave | Replaces static text with a lively 3-4 bar bouncing equalizer wave during speech recording and TTS playback. | MEDIUM | Pure declarative QML animation (`SequentialAnimation` loops) with staggered phase offsets. Zero CPU spike. |
| Fluid Adaptive Expansion | Pill remains a sleek, compact AI icon when idle (~32px), expanding smoothly to reveal status badge and duration timer (~110–140px) only when active. | LOW | Leverages `BarGroup.qml`'s built-in 250ms Material 3 width transition Behavior. |
| Dynamic Material You Adaptation | Honors active wallpaper palette tokens (`surface_container_high`, `primary`, `on_primary`, `tertiary_container`) generated via Matugen. | LOW | Directly binds to `Appearance.colors` with zero hardcoded hex strings. |
| Zero-Drift Deployment | Symlinked via GNU Stow (`restow/quickshell/`) with strict verification (`arch/dots-hyprland.sh verify --strict` 0 findings). | LOW | Inherits repo's anti-rot architecture. |

### Anti-Features (Commonly Requested, Often Problematic)

Features that seem appealing but degrade simplicity, performance, or violate operator constraints.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Clickable popup / interactive dashboard in v0.7 | Users often think status pills must have menus. | User explicitly stated: *"Right now we don't need anything about click interactions. We don't need that. For now no need click interactions."* Adding unnecessary click popups adds clutter and scope bloat. | Pure telemetry / status monitor pill for v0.7. Keep click handlers disabled or reserve for future milestones. |
| Standard microphone icon (`mic`, `mic_none`) | Common convention in traditional operating systems. | User explicitly rejected mic icon: *"I don't want like mic icon I would rather want is something like you know AI type of icon that is kind of like listening to me"*. | Use `auto_awesome` (sparkles / AI assistant). |
| Background daemon / custom socket server | Writing a Python or C daemon to push status over Unix domain sockets. | Overkill; the existing `voice.py` CLI already writes state to `$XDG_RUNTIME_DIR/voice-stt/` PID files (`recorder.pid`, `tts.pid`). Creating a separate daemon creates another service to manage, fail, and maintain. | Quickshell `FileView` + polling timer reads existing runtime state files directly. |
| Full-waveform FFT audio capture in QML | Real-time audio FFT visualization from PulseAudio/PipeWire monitor source. | High CPU usage, requires native C++ Qt plugin or heavy PipeWire C bindings. | Lightweight CSS/QML simulated audio wave bars that animate while active state is true. |

---
*Feature research for: Quickshell Voice Status Bar Pill*  
*Researched: 2026-09-21*  
