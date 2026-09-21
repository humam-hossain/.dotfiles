# Phase 37: Bar Layout Integration, Dual-Monitor Verification & Strict Packaging - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-21
**Phase:** 37-bar-layout-integration-dual-monitor-verification-strict-packaging
**Areas discussed:** Multi-Monitor & Responsive Behavior, Pill Interaction & Click Handlers, Bar Mounting & Lifecycle Structure, Automated Test Harness & Verification Drill

---

## Multi-Monitor & Responsive Behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Show on all monitors | The pill is compact (26px idle) and globally informative, mirroring status across both ultrawide DP-1 and secondary HDMI-A-2. | ✓ |
| Primary monitor (DP-1) only | Restrict VoicePill to the primary screen to keep secondary display bars minimal. | |
| You decide | Match whichever pattern the existing status bar widgets use. | |

**User's choice:** Show on all monitors
**Notes:** Universal distribution is cleanly supported since Bar.qml mounts BarContent across all screens in Quickshell.screens.

| Option | Description | Selected |
|--------|-------------|----------|
| Icon-only mode on narrow screens | Keep the resting 26px icon with reactive color changes and pulse, but suppress text expansion when useShortenedForm == 2 (e.g. rotated HDMI-A-2 at 720px width) to prevent collisions. | ✓ |
| Full expansion on all screens | Allow text to expand even on narrow/vertical screens, trusting Right zone flex spacing. | |
| Hide entirely when hella-shortened | Completely hide the voice pill when useShortenedForm == 2, matching Media and Battery behavior. | |
| You decide | Choose the safest layout behavior for narrow displays. | |

**User's choice:** Icon-only mode on narrow screens
**Notes:** Prevents text expansion collision on vertical rotated displays like HDMI-A-2 (720px logical width).

| Option | Description | Selected |
|--------|-------------|----------|
| Full expansion enabled on standard/shortened screens (useShortenedForm < 2) | Allow full timer and stage badges on 1000px–1200px widths since max pill expansion is only ~100px. | ✓ |
| Abbreviated badges | Keep timers (0:05) but abbreviate stage labels on 1000px–1200px screens (e.g. STT... / TTS...). | |
| You decide | Choose based on aesthetic balance with adjacent Media widget. | |

**User's choice:** Full expansion enabled on standard/shortened screens (useShortenedForm < 2)
**Notes:** Standard 1080p horizontal displays have sufficient margin for full timer and stage badges.

| Option | Description | Selected |
|--------|-------------|----------|
| Icon-only centered in vertical bar mode | In vertical orientation, display the icon centered with reactive colors and pulse, omitting horizontal text expansion. | ✓ |
| Hide in vertical bar mode | Only display VoicePill on horizontal top/bottom bars. | |
| You decide | Handle vertical orientation cleanly according to upstream BarGroup vertical patterns. | |

**User's choice:** Icon-only centered in vertical bar mode
**Notes:** Vertical bars have fixed width (~40-48px), so horizontal text expansion is suppressed.

---

## Pill Interaction & Click Handlers

| Option | Description | Selected |
|--------|-------------|----------|
| Pass-through to toggle Right Sidebar | Treat the pill as part of the bar background surface, letting left-clicks toggle the right control center sidebar. | |
| Toggle voice recording | Left-click triggers the voice assistant script / toggles recording via Quickshell.execDetached. | |
| Inert absorber (No-op) | Swallow mouse clicks so clicking the pill does not open the sidebar or trigger accidental actions. | ✓ |

**User's choice:** "nothing for now" (confirmed as inert pill)
**Notes:** Operator explicitly directed "nothing for now"; confirmed as an inert surface that consumes clicks to avoid accidental sidebar popups.

| Option | Description | Selected |
|--------|-------------|----------|
| Static surface (no hover effect) | No hover highlight or pointer cursor, clearly signaling to the operator that it is an ambient telemetry widget rather than an action button. | ✓ |
| Subtle hover highlight | Show a gentle background brightness change on hover matching other bar groups. | |
| Status tooltip | Show a simple hover tooltip with current state and TTS engine. | |

**User's choice:** Static surface (no hover effect)
**Notes:** Keeps the pill visually stable without misleading hover affordance.

| Option | Description | Selected |
|--------|-------------|----------|
| All mouse buttons inert | Consume all mouse clicks (Left, Right, Middle) on the pill surface to keep it completely stable and protected from accidental triggers. | ✓ |
| Allow right-click pass-through | Absorb left click, but let right click pass through to the bar background. | |
| You decide | Align with standard inert widget handling in Quickshell. | |

**User's choice:** All mouse buttons inert
**Notes:** Prevents any mouse button event from propagating down to parent bar mouse areas.

---

## Bar Mounting & Lifecycle Structure

| Option | Description | Selected |
|--------|-------------|----------|
| Direct VoicePill declaration | Instantiate VoicePill {} directly in rightSectionRowLayout immediately following mediaLoader without a redundant Loader wrapper, keeping QML tree lightweight. | ✓ |
| Wrap in a Loader | Use Loader { id: voiceLoader; sourceComponent: VoicePill {} } for lazy component loading. | |
| You decide | Use whichever approach best matches upstream Quickshell practices. | |

**User's choice:** Direct VoicePill declaration
**Notes:** Avoids redundant Loader wrapper and avoids double BarGroup nesting since VoicePill is already a BarGroup.

| Option | Description | Selected |
|--------|-------------|----------|
| Explicit property binding | Pass useShortenedForm: root.useShortenedForm explicitly when instantiating VoicePill, making the contract clear and testable. | ✓ |
| Auto-resolve internally | Let VoicePill resolve its own screen width threshold internally from QsWindow.window?.screen. | |
| You decide | Pick whichever provides the most reliable reactive binding across screen resize/rotation. | |

**User's choice:** Explicit property binding
**Notes:** Clear contract and direct binding from BarContent.

| Option | Description | Selected |
|--------|-------------|----------|
| Layout.alignment: Qt.AlignVCenter | Vertically center the VoicePill within the 28px status bar height, matching Media and Updates. | ✓ |
| Fill bar height | Stretch the pill container to fill the full bar height (Layout.fillHeight: true). | |
| You decide | Ensure pixel-perfect vertical centering matching adjacent pills. | |

**User's choice:** Layout.alignment: Qt.AlignVCenter
**Notes:** Centers 26px pill vertically within the 28px base bar height.

| Option | Description | Selected |
|--------|-------------|----------|
| Anchor left of right cluster when Media is idle | When Media is hidden, VoicePill naturally sits at the outer left boundary of the right cluster with clean 4px gaps to Updates/SysTray. | ✓ |
| Place further right | Keep VoicePill clustered closer to the hardware/system indicators. | |
| You decide | Preserve INTG-01 strictly (immediately following mediaLoader). | |

**User's choice:** User affirmed: "after media, voice pill would be there, so i don't understand what would be the issue?"
**Notes:** Strictly anchored to INTG-01 directly following mediaLoader in rightSectionRowLayout.

---

## Automated Test Harness & Verification Drill

| Option | Description | Selected |
|--------|-------------|----------|
| scripts/phase37-voice-pill-assert.sh | Standard phase-numbered test harness filename consistent with scripts/phase36-voice-pill-assert.sh and earlier phases. | ✓ |
| scripts/phase37-voice-integration-assert.sh | Emphasize the layout integration and multi-monitor verification scope in the filename. | |
| You decide | Standardize on repo conventions. | |

**User's choice:** scripts/phase37-voice-pill-assert.sh
**Notes:** Resolves typo in ROADMAP.md line 24.

| Option | Description | Selected |
|--------|-------------|----------|
| Non-destructive live theme probe | Assert Appearance.colors.* bindings in QML AST, audit restow/quickshell for zero unauthorized hex colors, and verify token presence without mutating active wallpaper or causing working tree churn. | ✓ |
| Full live wallpaper switch & restore drill | Trigger switchwall.sh on a temporary test palette, poll palette reload, and restore the original wallpaper. | |
| You decide | Maximize test rigor while guaranteeing zero working tree drift. | |

**User's choice:** Non-destructive live theme probe
**Notes:** Rigorous AST and token validation with guaranteed zero working-tree churn.

| Option | Description | Selected |
|--------|-------------|----------|
| Hyprland monitor geometry evaluation & AST checks | Read active monitors from hyprctl monitors -j, assert that DP-1 (width > 1200) allows full expansion while rotated HDMI-A-2 (logical width < 1000) evaluates to useShortenedForm == 2 (icon-only), and verify QML logic. | ✓ |
| Live Quickshell window geometry probe only | Query running Quickshell Bar instances via QML/IPC. | |
| You decide | Ensure both headless CI/script validation and live multi-monitor validation pass cleanly. | |

**User's choice:** Hyprland monitor geometry evaluation & AST checks
**Notes:** Includes synthetic/mock geometry evaluation so the harness passes even if physical HDMI-A-2 is powered off.

| Option | Description | Selected |
|--------|-------------|----------|
| Soft-detect live reload | If quickshell is actively running, trigger live reload and assert process survival without crashes; soft-pass if headless or not running. | ✓ |
| Mandatory live reload | Require Quickshell to be running and reload cleanly during harness execution. | |
| Omit process reload from harness | Limit harness to static, AST, symlink, and repository assertions. | |

**User's choice:** Soft-detect live reload
**Notes:** Checks running quickshell process survival without breaking in headless/TTY environments.

---

## the agent's Discretion

- QML MouseArea event consumption syntax inside VoicePill.qml.
- Test harness formatting and helper routines.
- Synthetic screen width values (720px, 1080px, 3440px) for multi-monitor logic tests.

## Deferred Ideas

- Interactive click actions (left-click to record, right-click voice picker) deferred to Milestone v0.8+.
- Transcription history preview hover tooltips deferred to Milestone v0.8+.
