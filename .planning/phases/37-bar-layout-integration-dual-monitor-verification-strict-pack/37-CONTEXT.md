# Phase 37: Bar Layout Integration, Dual-Monitor Verification & Strict Packaging - Context

**Gathered:** 2026-09-21
**Status:** Ready for planning

<domain>
## Phase Boundary

Integrate `VoicePill` into `BarContent.qml` Right zone immediately after Media (`mediaLoader`), deploy via `restow/quickshell/` leaf symlinks without folding ancestor directories or modifying `vendor/dots-hyprland`, verify Material You theming across wallpaper switches with zero working-tree churn, ensure responsive multi-monitor adaptation (suppressing text expansion to icon-only on narrow/rotated screens like `HDMI-A-2`), and validate with an automated assertion test harness (`scripts/phase37-voice-pill-assert.sh`) along with strict repository verification (`arch/dots-hyprland.sh verify --strict` 0 findings).

</domain>

<decisions>
## Implementation Decisions

### Multi-Monitor & Responsive Behavior
- **D-01 (All Displays Distribution):** Display `VoicePill` across all connected displays (`DP-1` and `HDMI-A-2`). Because `Bar.qml` instantiates `BarContent.qml` across each screen via `Variants`, embedding `VoicePill` directly inside `BarContent.qml` provides ambient status everywhere without custom routing. — **Reversibility:** reversible.
- **D-02 (Narrow/Rotated Screen Icon-Only Suppression):** When screen width is heavily constrained (`useShortenedForm == 2`, such as rotated `HDMI-A-2` with 1080x1920 scaled 1.5 yielding 720px logical width), suppress text expansion (`isExpanded: effectiveState !== "idle" && useShortenedForm < 2 && !vertical`). The pill remains clamped to its resting 26px size, showing the `graphic_eq` icon with reactive color shifts and breathing pulse while preventing horizontal collisions with the right sidebar button or system tray. — **Reversibility:** reversible.
- **D-03 (Standard & Shortened Width Full Expansion):** On displays with `useShortenedForm < 2` (both ultrawide `DP-1` at 3440px and standard 1080p width at 1000px–1200px), allow full text label expansion during speech for live duration timers (`0:05`) and stage badges (`Transcribing...`, `Typing...`). — **Reversibility:** reversible.
- **D-04 (Vertical Bar Centered Icon):** In Quickshell vertical bar mode (`vertical: true`), width clamps to `Appearance.sizes.baseVerticalBarWidth` and text expansion is suppressed (`!vertical`), centering the `graphic_eq` icon with reactive colors. — **Reversibility:** reversible.

### Pill Interaction & Mouse Handling
- **D-05 (Inert Telemetry Pill):** The Voice Pill is strictly an ambient status indicator for v0.7 ("nothing for now"). Embed an internal `MouseArea` in `VoicePill.qml` (`acceptedButtons: Qt.AllButtons; cursorShape: Qt.ArrowCursor; hoverEnabled: false; onPressed: event => event.accepted = true`) that absorbs all mouse clicks (Left, Right, Middle) so clicking the pill does nothing and never propagates down to `barRightSideMouseArea` (which would accidentally toggle the right sidebar). — **Reversibility:** reversible.
- **D-06 (Static Visual Surface):** No hover background highlight or pointer cursor changes; the pill maintains a stable, static `colLayer1` surface reinforcing that it is a passive indicator. — **Reversibility:** reversible.

### Bar Mounting & Lifecycle Structure
- **D-07 (Direct Component Declaration):** Instantiate `VoicePill {}` directly within `BarContent.qml`'s `rightSectionRowLayout` immediately following `mediaLoader` without a redundant `Loader` wrapper, avoiding unnecessary QML tree depth and avoiding double `BarGroup` nesting. — **Reversibility:** reversible.
- **D-08 (Explicit Responsive Property Binding):** Pass `useShortenedForm: root.useShortenedForm` explicitly when declaring `VoicePill` in `BarContent.qml` to maintain a clear, testable property contract. — **Reversibility:** reversible.
- **D-09 (Vertical Center Alignment):** Align `VoicePill` via `Layout.alignment: Qt.AlignVCenter` in `rightSectionRowLayout`, centering the 26px pill within the 28px status bar height matching adjacent Media and Updates widgets. — **Reversibility:** reversible.
- **D-10 (Locked Position Flow):** Position is strictly anchored to `INTG-01` directly after `mediaLoader`. When Media is idle/hidden (`mediaLoader.visible == false`), `VoicePill` naturally anchors the leftmost position of the right status cluster with clean 4px gaps. — **Reversibility:** reversible.

### Automated Test Harness & Verification Drill
- **D-11 (Phase 37 Test Harness Filename):** Standardize the test harness filename to `scripts/phase37-voice-pill-assert.sh` (resolving the typo in `ROADMAP.md` line 24 which referenced phase 35), implementing a 5-section test suite. — **Reversibility:** reversible.
- **D-12 (Non-Destructive Theme Probe):** Verify Matugen theme token adaptability (`INTG-03`) non-destructively: assert `Appearance.colors.*` bindings in QML AST, audit `restow/quickshell` for zero unauthorized hardcoded hex codes, and verify script integrity without mutating the operator's active desktop wallpaper. — **Reversibility:** reversible.
- **D-13 (Geometry Evaluation & Mock Display Defense):** Verify multi-monitor responsive behavior by querying `hyprctl monitors -j` for active display geometry (`DP-1` expansion allowed) while testing synthetic/mock display widths (720px, 1080px, 3440px) and AST logic to ensure tests pass regardless of whether a physical secondary display is currently powered on. — **Reversibility:** reversible.
- **D-14 (Soft-Detect Live Quickshell Reload):** If the `quickshell` process is active during testing, trigger live reload and verify process survival without crashes; if not running, soft-pass with `[SOFT]`. — **Reversibility:** reversible.
- **D-15 (Strict Verification Gate):** Require `arch/dots-hyprland.sh verify --strict` to pass with `FAIL=0 FINDINGS=0` and 0 git working tree drift before and after harness execution. — **Reversibility:** one-way — Enforces strict repository packaging contract; failure blocks milestone completion.

### the agent's Discretion
- Exact QML `MouseArea` placement and event consumption syntax inside `VoicePill.qml`.
- Test harness assertion helper functions and terminal formatting matching `scripts/phase36-voice-pill-assert.sh`.
- Synthetic monitor geometry test thresholds in the test harness.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap & Requirements
- `.planning/ROADMAP.md` §Phase 37 — Phase goal, requirements mapping, and success criteria.
- `.planning/REQUIREMENTS.md` §Layout & System Integration — `INTG-01`, `INTG-02`, `INTG-03`, `INTG-04` specifications.
- `.planning/STATE.md` §Milestone v0.7 — Accumulated milestone context and phase dependencies.
- `.planning/phases/36-visual-voice-pill-component-dynamic-animations/36-CONTEXT.md` — Visual component and animation decisions.
- `.planning/phases/35-voice-telemetry-state-service-architecture/35-CONTEXT.md` — Voice telemetry service contracts.

### Codebase Integration Points & Layout
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml` — Primary integration target: Right zone row layout, `mediaLoader`, `useShortenedForm` logic.
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/VoicePill.qml` — Component implementation: `isExpanded` boolean logic, `useShortenedForm` property, inert `MouseArea`.
- `restow/quickshell/.config/quickshell/ii/services/Voice.qml` — Singleton state service providing `overallState`, `formattedDuration`.
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarGroup.qml` — Authoritative container providing geometry, background rendering, and 250ms emphasized deceleration resizing.
- `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/Bar.qml` — Scope and Variants iterating over `Quickshell.screens`.
- `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/Appearance.qml` — `Appearance.colors` and `Appearance.sizes.barHellaShortenScreenWidthThreshold` (1000px).
- `vendor/dots-hyprland/dots/.config/quickshell/ii/scripts/colors/switchwall.sh` — Matugen color generation and theme switching script.

### Repository Packaging & Verification
- `arch/dots-hyprland.sh` — Verification policy wrapper (`verify --strict`).
- `restow/README.md` — GNU Stow overlay package contract (`rsync-replace` for `quickshell`).
- `scripts/phase36-voice-pill-assert.sh` — Preceding test harness reference for AST, symlink, and working tree invariance checks.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `VoicePill.qml`: Pre-existing component in `restow/quickshell/.config/quickshell/ii/modules/ii/bar/VoicePill.qml`, inheriting `BarGroup`.
- `BarContent.qml`: Pre-existing status bar overlay in `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml`.
- `root.useShortenedForm`: In `BarContent.qml`, calculates `0` (> 1200px), `1` (1000px–1200px), or `2` (<= 1000px).

### Established Patterns
- **Direct Child Placement in BarContent:** Direct instantiation without wrapping in redundant `BarGroup` since `VoicePill` is already a `BarGroup`.
- **Inert Status Indicators:** Ambient status elements without click actions absorb events rather than allowing click-through to parent sidebar triggers.
- **GNU Stow Leaf Symlinks:** All files deployed into `~/.config/quickshell/` via `restow/quickshell` as individual leaf symlinks, maintaining real directories to prevent directory folding.
- **Zero Hex Policy:** Dynamic theming derived exclusively through `Appearance.colors.*` tokens; zero unauthorized `#HEX` codes.

### Integration Points
- `BarContent.qml` lines 191–205: Insert `VoicePill` directly after `mediaLoader` in `rightSectionRowLayout`.
- `VoicePill.qml`: Add `property real useShortenedForm: 0`, update `isExpanded` condition, and attach inert `MouseArea`.

</code_context>

<specifics>
## Specific Ideas

- **User Directives from Discussion:**
  - *"Show on all monitors — The pill is compact (26px idle) and globally informative, mirroring status across both ultrawide DP-1 and secondary HDMI-A-2."*
  - *"Icon-only mode on narrow screens — Keep the resting 26px icon with reactive color changes and pulse, but suppress text expansion when useShortenedForm == 2 (e.g. rotated HDMI-A-2 at 720px width) to prevent collisions."*
  - *"Full expansion enabled on standard/shortened screens (useShortenedForm < 2)"*
  - *"Icon-only centered in vertical bar mode"*
  - *"nothing for now" / "(Recommended) Inert pill (absorb clicks) — Clicking the pill does nothing, preventing accidental triggers or sidebar popups while keeping it purely informative."*
  - *"All mouse buttons inert — Consume all mouse clicks (Left, Right, Middle) on the pill surface"*
  - *"Static surface (no hover effect) — No hover highlight or pointer cursor"*
  - *"Direct VoicePill declaration — Instantiate VoicePill {} directly in rightSectionRowLayout immediately following mediaLoader without a redundant Loader wrapper"*
  - *"Explicit property binding — Pass useShortenedForm: root.useShortenedForm explicitly when instantiating VoicePill"*
  - *"after media, voice pill would be there, so i don't understand what would be the issue?" — Strictly preserve INTG-01 right after mediaLoader.*
  - *"scripts/phase37-voice-pill-assert.sh — Standard phase-numbered test harness filename"*
  - *"Non-destructive live theme probe"*
  - *"Hyprland monitor geometry evaluation & AST checks"*
  - *"Soft-detect live reload"*

</specifics>

<deferred>
## Deferred Ideas

- **Interactive Voice Controls (Milestone v0.8+):**
  - Left-click to start/stop speech recording or toggle Gemini voice script.
  - Right-click context popup to select Kokoro TTS voice (`af_heart`, etc.) or switch STT backends.
  - Hover tooltip displaying transcription history previews or audio input device meters.

</deferred>

---

*Phase: 37-bar-layout-integration-dual-monitor-verification-strict-packaging*
*Context gathered: 2026-09-21*
