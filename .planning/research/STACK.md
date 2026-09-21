# Stack Research

**Domain:** Quickshell QML Status Bar Component & STT/TTS Telemetry Integration  
**Researched:** 2026-09-21  
**Confidence:** HIGH  

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Quickshell QML / Qt 6 | Qt 6.7+ / Quickshell 0.0.x | UI presentation and reactive status bar pill | Native desktop shell engine used across `dots-hyprland`, supports declarative UI, zero-overhead animations, and sub-millisecond property bindings. |
| Quickshell.Io (`FileView`, `Process`) | Quickshell native | Asynchronous IPC, state observation, and telemetry polling | Provides inotify-backed `FileView` to detect state transitions in `$XDG_RUNTIME_DIR/voice-stt/` without running wasteful bash subshells. |
| Material Symbols Font | Outlined/Rounded 2024+ | Iconography adhering to existing system visual language | Standardized across dots-hyprland (`MaterialSymbol.qml`); provides AI-centric symbols (`auto_awesome`, `graphic_eq`, `psychology`, `smart_toy`) matching desktop theme. |
| voicemode (`voice.py`) | Local Python 3.12 daemon | Core STT (faster-whisper) and TTS (Kokoro/Edge) engine | Existing fully configured local speech pipeline located at `~/.local/bin/voice` with built-in PID and state tracking in `$XDG_RUNTIME_DIR/voice-stt/`. |

### Supporting Libraries & QML Primitives

| Component / Library | Version / Import | Purpose | When to Use |
|---------------------|------------------|---------|-------------|
| `BarGroup.qml` | `modules/ii/bar` | Standard rounded-rectangle pill container | Encapsulates 12–16px corner radius, internal padding, and fluid 250ms Material 3 width animation. |
| `MaterialSymbol.qml` | `qs.modules.common` | Vector glyph rendering | Rendering the AI icon and audio wave glyphs with reactive color bindings. |
| `SequentialAnimation` / `NumberAnimation` | `QtQuick` | Reactive pulse and audio wave bar animations | Used during `recording` and `speaking` states for smooth visual feedback without CPU burden. |
| `Timer` | `QtQuick` | Elapsed seconds counter (1s tick) | Active exclusively during recording and speaking to track live duration (`0:05`). |

### Development & Test Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| `arch/dots-hyprland.sh verify --strict` | Anti-rot and stow link verification | Strict exit-code check ensuring zero drift and proper symlink hygiene. |
| `quickshell` live reload | Rapid UI iteration | Hot-reloading on file save via Stow leaf symlinks in `restow/quickshell/`. |
| `scripts/phase35-voice-pill-assert.sh` | Automated validation harness | Multi-section assertion script validating QML syntax, service state bindings, and visual indicators. |

## Installation & Deployment

No new external packages need to be installed. Infrastructure utilizes existing Quickshell runtime and local `Voice` repository:

```bash
# Verify Voice CLI and state directory exist
which voice
ls -ld "${XDG_RUNTIME_DIR}/voice-stt"

# Verify Quickshell overlay structure
mkdir -p restow/quickshell/.config/quickshell/ii/services
mkdir -p restow/quickshell/.config/quickshell/ii/modules/ii/bar
```

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| `FileView` on `$XDG_RUNTIME_DIR/voice-stt/` state | D-Bus service / custom daemon | D-Bus would be necessary if bidirectional complex RPC were needed. For telemetry observation, reading lightweight PID state files is zero-maintenance and decoupled. |
| AI Symbol (`auto_awesome` / sparkles) | Microphone icon (`mic`) | Mic icon is standard for hardware input devices, but user explicitly rejected generic mic glyphs in favor of an AI visual identity. |
| Pure status telemetry pill | Clickable modal popup dashboard | Full interactive dashboard is useful for settings, but user explicitly requested pure telemetry with no click handlers for this milestone. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Synchronous `Process` execution (`sh -c ...`) in QML | Blocks the Qt rendering thread, introducing noticeable frame stutter in Hyprland | Use asynchronous `FileView` watching or non-blocking event handlers. |
| Generic mic icon (`mic`, `mic_none`) | Violates user's explicit design requirement for AI visual identity | Use `auto_awesome` (sparkles) or `graphic_eq` (waveform). |
| High-frequency polling timers (< 50ms) | Causes unnecessary CPU wakeups and battery drain on mobile/laptop setups | Use state-driven timers (only run 1s duration timer when active state is true). |
| Editing `vendor/dots-hyprland` directly | Violates repository architectural invariant (vendor submodule is clean upstream) | Author all QML files under `restow/quickshell/` and deploy via GNU Stow. |

## Version Compatibility

| Package / Runtime | Compatible With | Notes |
|-------------------|-----------------|-------|
| Quickshell | Qt 6.7+ | Requires Bound ComponentBehavior and valid Singleton declarations. |
| voicemode (`voice.py`) | Python 3.12 | Writes `$XDG_RUNTIME_DIR/voice-stt/recorder.pid` and `tts.pid`. |

## Sources

- `restow/quickshell/.config/quickshell/ii/services/Privacy.qml` — reference for Quickshell IO and PipeWire integration.
- `/home/pera/github_repo/Voice/voice.py` — state tracking implementation via `PID_FILE` and `TTS_PID_FILE`.
- `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/BarContent.qml` — 3-zone bar layout and Loader contracts.

---
*Stack research for: Quickshell Voice Status Bar Pill*  
*Researched: 2026-09-21*  
