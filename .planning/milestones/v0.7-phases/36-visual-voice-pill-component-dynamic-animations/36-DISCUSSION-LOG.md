# Phase 36: Visual Voice Pill Component & Dynamic Animations - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-21
**Phase:** 36-visual-voice-pill-component-dynamic-animations
**Areas discussed:** Idle & Resting State Display, Animated Audio Waveform Design, Content Layout & Badging, Visual Pulse & State Color Theming

---

## Idle & Resting State Display

### Question 1: Idle Visibility
| Option | Description | Selected |
|--------|-------------|----------|
| (Recommended) Compact resting icon | Keep a small pill visible with just the icon in neutral layer color when idle, expanding smoothly via M3 curve when active | ✓ |
| Completely hidden when idle | Hide the pill entirely when idle, appearing and expanding only when active | |
| You decide | Pick whichever fits the status bar aesthetic best | |

**User's choice:** Compact resting icon (freeform: "When idle I think there should be an icon... So when it is idle Let's just use that icon and show the icon only")  
**Notes:** User emphasized prioritizing the icon decision first, then established that the idle state should stay visible in a compact form showing the icon only.

### Question 2: AI Voice Identity Icon
| Option | Description | Selected |
|--------|-------------|----------|
| auto_awesome | Sparkles / AI starburst (Google / Gemini standard) | |
| graphic_eq | Sound frequency equalizer bars from Material Symbols Rounded | ✓ |
| mic / mic_none | Traditional microphone | |
| record_voice_over | Person speaking with soundwaves | |
| speech_to_text | Speech bubble with lines | |
| assistant | Smart assistant box | |

**User's choice:** `graphic_eq` from Google Material Symbols Rounded  
**Notes:** User inquired about the font and origin of existing status bar icons (`ttf-material-symbols-variable-git`), then chose `graphic_eq` from the catalog.

### Question 3: Idle Icon Color Styling
| Option | Description | Selected |
|--------|-------------|----------|
| (Recommended) Subtle neutral layer color (`Appearance.colors.colOnLayer1`) | Blends with standard status bar widgets | ✓ |
| Accent / Primary color (`Appearance.colors.colPrimary`) | Stands out prominently in wallpaper accent | |
| You decide | Follow bar conventions | |

**User's choice:** Default status bar color (`Appearance.colors.colOnLayer1`)  
**Notes:** User requested: "I think it should match the whole status bar default color. I think it's white or something like that in the whole status bar... All the text in the status bar and icons have this color. So keep that."

### Question 4: Idle Return Animation
| Option | Description | Selected |
|--------|-------------|----------|
| (Recommended) Smooth M3 contraction (250ms) | Smoothly contract width using Material 3 emphasized deceleration curve | ✓ |
| Brief fade-out before contraction | Linger 500ms after idle return | |
| You decide | Follow BarGroup animation curves | |

**User's choice:** Smooth M3 contraction (250ms)  
**Notes:** Matches standard `BarGroup.qml` width transitions.

---

## Animated Audio Waveform Design

### Question 1: Waveform Bar Count & Dynamics
| Option | Description | Selected |
|--------|-------------|----------|
| 4 vertical bars | Compact 4-bar equalizer | |
| 5-6 vertical bars | Denser audio studio equalizer | |
| (User preference) No waveform bars | Omit separate vertical equalizer bars entirely | ✓ |

**User's choice:** No vertical waveform bars needed  
**Notes:** User noted: "I don't think this is necessary like vertical parts or whatever I've just icon that we have chosen already then the time let's just say the timer will run when I'm speaking". The pill remains minimal and clean with just the `graphic_eq` icon and reactive text.

---

## Content Layout & Badging

### Question 1: State Flow Architecture
| Option | Description | Selected |
|--------|-------------|----------|
| Option 1: Side-by-Side Pill | Show status text and timer simultaneously (`Transcribing... • 0:14`) | |
| Option 2: Sequential Linear Flow | Single text label per stage: timer during speech -> `Transcribing...` -> `Typing...` -> final duration wrap-up -> collapse to idle | ✓ |
| Option 3: Compact Hybrid | Duration during speech, badges during processing | |

**User's choice:** Option 2: Sequential Linear Flow  
**Notes:** User recognized that rapid local STT stages (300–800ms) could clash with arbitrary timer cycling, selecting Option 2 as the cleanest approach.

### Question 2: TTS Playback Display
| Option | Description | Selected |
|--------|-------------|----------|
| `[graphic_eq]  Speaking 0:03` | Shows state label with live playback duration | |
| `[graphic_eq]  0:03` | Just the icon and live timer, matching STT recording style | ✓ |
| You decide | Default | |

**User's choice:** `[graphic_eq]  0:03`  
**Notes:** Unified appearance between STT recording and TTS speaking.

---

## Visual Pulse & State Color Theming

### Question 1: Active Recording Pulse
| Option | Description | Selected |
|--------|-------------|----------|
| (Recommended) Primary accent (`colPrimary`) with breathing pulse | Pulses icon opacity (1.0 ↔ 0.5 every 1s) smoothly in dynamic primary color | ✓ |
| Red recording accent (`colError`) with pulse | Traditional red recording indicator | |
| You decide | Default | |

**User's choice:** Primary accent (`Appearance.colors.colPrimary`) with gentle breathing pulse  
**Notes:** Non-distracting visual indicator of live mic activity.

### Question 2: State Color Differentiation
| Option | Description | Selected |
|--------|-------------|----------|
| Uniform Primary Accent | `colPrimary` across all active states | |
| Distinct state accents | `colPrimary` (recording), `colTertiary` (transcribing), `colSecondary` (typing/speaking) | ✓ |
| You decide | Default | |

**User's choice:** Distinct state accents per lifecycle state  
**Notes:** Provides clear color cues as the speech process advances through transcription and insertion.

---

## the agent's Discretion

- Cross-fade easing curves and opacity durations for text transitions.
- Internal wrap-up timer duration (1.5s) before collapsing to idle.
- Spacing between icon and text (4px standard).

---

## Deferred Ideas

- Interactive voice controls, popups, or click handlers (deferred to v0.8+).
- Hover tooltips showing recent transcription history (deferred to v0.8+).
- Status bar placement, dual-monitor validation, and stow packaging (Phase 37).
