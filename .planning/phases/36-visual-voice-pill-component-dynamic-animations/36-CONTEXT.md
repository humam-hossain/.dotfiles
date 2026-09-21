# Phase 36: Visual Voice Pill Component & Dynamic Animations - Context

**Gathered:** 2026-09-21
**Status:** Ready for planning

<domain>
## Phase Boundary

Author the dedicated `VoicePill.qml` status bar component styled with standard `BarGroup.qml` rounded-rectangle pill geometry (12–16px corner radius, 4–6px internal padding), Material Symbols AI iconography (`graphic_eq`), dynamic reactive state flows, live duration display, and smooth Material 3 250ms width resizing transitions.

Specifically in scope:
- Create `VoicePill.qml` under `restow/quickshell/.config/quickshell/ii/modules/ii/bar/`.
- Compact resting state when idle displaying only the `graphic_eq` icon in standard status bar color (`Appearance.colors.colOnLayer1`).
- Dynamic expansion to display live duration (`M:SS`), status badges (`"Transcribing..."`, `"Typing..."`), and final speech duration wrap-up via Sequential Linear Flow.
- Gentle breathing pulse animation during active recording.
- Reactive Material You palette shifts across lifecycle states via Matugen tokens (`colPrimary`, `colTertiary`, `colSecondary`, `colOnLayer1`).
- Fluid 250ms Material 3 emphasized deceleration width resizing animation.

Out of scope:
- Layout insertion into `BarContent.qml`, dual-monitor testing, and packaging / stow deployment (Phase 37 owns this).
- Hover tooltips, transcript history popups, and click interactions (deferred to v0.8+ per user instruction).

</domain>

<decisions>
## Implementation Decisions

### Idle & Resting State Geometry & Display
- **D-01 (Compact Resting Pill):** In `idle` state, the Voice pill remains visible on the status bar in a compact resting state displaying only the `graphic_eq` icon without text, timer, or badges, visually anchoring voice readiness. — **Reversibility:** reversible.
- **D-02 (AI Voice Identity Icon):** Use `graphic_eq` from Google Material Symbols Rounded (`ttf-material-symbols-variable-git`) rendered via `MaterialSymbol.qml` to represent voice/soundwave telemetry. — **Reversibility:** reversible.
- **D-03 (Idle Coloration):** The resting `graphic_eq` icon renders in default status bar text/icon color (`Appearance.colors.colOnLayer1`) to blend seamlessly with adjacent status bar widgets until voice activates. — **Reversibility:** reversible.
- **D-04 (M3 Width Resizing Transitions):** Width transitions between compact resting state and expanded telemetry state use standard `BarGroup.qml` 250ms Material 3 emphasized deceleration (`Appearance.animationCurves.emphasizedDecel`), smoothly expanding on voice activity and smoothly contracting back to the resting icon when returning to idle. — **Reversibility:** reversible.

### Visual Streamlining & Waveform Simplification
- **D-05 (No Separate Waveform Bars):** Omit separate vertical equalizer bars to keep the pill minimal, clean, and elegant. Visual telemetry is conveyed directly by the `graphic_eq` icon coupled to reactive state transitions. — **Reversibility:** reversible.

### State Transition Flow & Badging (Sequential Linear Flow)
- **D-06 (Sequential Linear Content Flow):** Implement Sequential Linear Flow to avoid rapid, jarring text cycling across fast transcription/typing stages:
  - **Recording / Speaking:** Displays `[graphic_eq]  M:SS` (live timer counting up second-by-second).
  - **Transcribing:** Cross-fades to `[graphic_eq]  Transcribing...`.
  - **Typing:** Cross-fades to `[graphic_eq]  Typing...`.
  - **Completion Wrap-up:** Displays the final total speech duration (`[graphic_eq]  M:SS`) for ~1.5s so the operator can review talk duration, then smoothly collapses back to resting `graphic_eq`. — **Reversibility:** reversible.
- **D-07 (TTS Playback Display):** During Kokoro TTS speech synthesis (`speaking`), the pill displays `[graphic_eq]  M:SS` with the live speech playback duration, matching the STT recording display style. — **Reversibility:** reversible.

### Pulse Animation & Dynamic Theming
- **D-08 (Recording Breathing Pulse):** During active recording, apply a gentle breathing pulse animation on the `graphic_eq` icon (opacity cycling 1.0 ↔ 0.5 over 1000ms) to subtly indicate live microphone capture without distracting the operator. — **Reversibility:** reversible.
- **D-09 (Distinct Dynamic State Palette):** Style the icon and dynamic text with distinct Material You palette tokens derived from the active wallpaper via Matugen:
  - `recording`: `Appearance.colors.colPrimary` (wallpaper primary accent)
  - `transcribing`: `Appearance.colors.colTertiary` (tertiary accent)
  - `typing` & `speaking`: `Appearance.colors.colSecondary` (secondary accent)
  - `idle`: `Appearance.colors.colOnLayer1` (standard bar text color)
  - Zero hardcoded hex colors. — **Reversibility:** reversible.

### the agent's Discretion
- Easing curves and opacity transitions for smooth text cross-fades between states.
- Exact spacing between `graphic_eq` icon and text label (standard 4px matching `BarGroup.qml` columnSpacing).
- Internal state timer logic for the 1.5s completion wrap-up linger before contracting to idle.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap & Requirements
- `.planning/ROADMAP.md` §Phase 36 — Phase goal, requirements mapping, and success criteria.
- `.planning/REQUIREMENTS.md` lines 20–26 — VOICE-01 through VOICE-06 specifications.
- `.planning/STATE.md` §Milestone v0.7 — Accumulated milestone context.
- `.planning/phases/35-voice-telemetry-state-service-architecture/35-CONTEXT.md` — Preceding state service contracts.

### Quickshell Widgets & Theming Patterns
- `restow/quickshell/.config/quickshell/ii/services/Voice.qml` — Authoritative voice service providing `overallState`, `formattedDuration`, `elapsedSeconds`, `elapsedMs`, `ttsVoice`.
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarGroup.qml` — Authoritative pill container providing geometry, margins, and 250ms emphasized deceleration resizing.
- `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/widgets/MaterialSymbol.qml` — Glyph renderer for Google Material Symbols Rounded font.
- `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/Appearance.qml` — Color definitions (`colLayer1`, `colOnLayer1`, `colPrimary`, `colSecondary`, `colTertiary`) and animation curves (`emphasizedDecel`).
- `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/Media.qml` — Reference bar widget layout and typography.
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/Resources.qml` — Reference pill content spacing and icon bindings.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `BarGroup.qml`: Custom status bar container with `radius: Appearance.rounding.small`, `padding: 5`, and `Behavior on implicitWidth` (250ms `Appearance.animationCurves.emphasizedDecel`).
- `MaterialSymbol.qml`: Renders font glyphs using `Appearance.font.family.iconMaterial` ("Material Symbols Rounded").
- `StyledText.qml`: Consistent typography rendering for status labels and timers.
- `Voice.qml`: Non-blocking singleton service exposing `Voice.overallState`, `Voice.formattedDuration`, `Voice.elapsedSeconds`, `Voice.elapsedMs`.

### Established Patterns
- Rounded-rectangle pill geometry: 12–16px corner radius, 4–6px internal padding, 4px column spacing.
- Material You color tokens: `Appearance.colors.colOnLayer1` for neutral resting text, `Appearance.colors.colPrimary` for active accent, zero hardcoded hex colors.
- Restow overlay discipline: Component authored in `restow/quickshell/.config/quickshell/ii/modules/ii/bar/` for leaf symlink deployment.

### Integration Points
- `VoicePill.qml` will bind to `Voice.overallState`, `Voice.formattedDuration`, `Voice.elapsedSeconds`.
- Future Phase 37 will import `VoicePill` into `BarContent.qml` immediately after `mediaLoader`.

</code_context>

<specifics>
## Specific Ideas

- **User Directives from Discussion:**
  - *"So when it is idle Let's just use that icon and show the icon only"* — Idle pill displays only the icon, staying compact.
  - *"Graphic Eq from the link that you gave me"* — Use `graphic_eq` from Material Symbols Rounded as the visual identity icon.
  - *"I think it should match the whole status bar default color. I think it's white or something like that in the whole status bar. So in an ideal state it should be default. This default color of the whole status bar. All the text in the status bar and icons have this color. So keep that."* — Idle icon uses `colOnLayer1`.
  - *"I don't think this is necessary like vertical parts or whatever I've just icon that we have chosen already"* — Omit separate vertical equalizer bars.
  - *"Sequential linear flow: Speaking (live timer) -> Transcribing... -> Typing... -> Show total speech time -> Go back to idle"* — Option 2 selected for state progression.
  - Distinct state accents selected: `colPrimary` for recording, `colTertiary` for transcribing, `colSecondary` for typing/speaking.

</specifics>

<deferred>
## Deferred Ideas

- **Phase 37 (Bar Layout Integration, Dual-Monitor Verification & Strict Packaging):**
  - Placement in `BarContent.qml` Right zone after Media (`mediaLoader`).
  - Dual-monitor testing across `DP-1` and `HDMI-A-1`.
  - Automated test harness `scripts/phase36-voice-pill-assert.sh`.
- **Future Milestone (v0.8+):**
  - Hover tooltips showing recent transcription previews.
  - Click interactions (cancel recording, toggle mute, voice picker).

</deferred>

---

*Phase: 36-visual-voice-pill-component-dynamic-animations*
*Context gathered: 2026-09-21*
