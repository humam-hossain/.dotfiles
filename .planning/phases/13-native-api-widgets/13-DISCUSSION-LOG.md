# Phase 13: Native API Widgets - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-03
**Phase:** 13-native-api-widgets
**Areas discussed:** Service layer split, Workspaces widget, Volume widget, Music & Tray widgets, plus 8 follow-up passes covering edge cases

---

## Service Layer Split

| Option | Description | Selected |
|--------|-------------|----------|
| Service singletons | pragma Singleton wrappers in services/ — AudioService, MprisService, HyprWorkspaces. Per ARCHITECTURE.md. Pays off in Phase 14 OSD + Phase 15 popups. | ✓ |
| Direct API imports | Widgets import Quickshell.Services.* / Quickshell.Hyprland directly. PwObjectTracker rebound per consumer. | |
| Hybrid | AudioService singleton (reused by OSD); workspaces and tray import directly. | |

**User's choice:** Service singletons (Recommended)
**Notes:** Foundational decision — Phase 14 OSD reuse requires the indirection.

---

| Option | Description | Selected |
|--------|-------------|----------|
| services/ subdir + qmldir | Mirrors theme/ pattern. `import qs.services`. | ✓ |
| Top-level | Service files at quickshell root next to Bar.qml. | |

**User's choice:** services/ subdir (Recommended)

---

| Option | Description | Selected |
|--------|-------------|----------|
| Derived only | Expose volume/muted/volumePercent. Hide PwObjectTracker + sink internals. | ✓ |
| Both raw + derived | Expose defaultSink PwNode + convenience aliases. | |

**User's choice:** Derived only (Recommended)

---

| Option | Description | Selected |
|--------|-------------|----------|
| First playing, fallback first | Auto-follow active playback; show paused if none playing. | ✓ |
| First in list always | `Mpris.players.values[0]`. Simpler. | |
| User-cyclable via click | Click cycles players. Adds complexity. | |

**User's choice:** First playing, fallback to first (Recommended)

---

## Workspaces Widget

| Option | Description | Selected |
|--------|-------------|----------|
| Waybar dot icons |  active /  default. Visual continuity. | ✓ |
| Numbered | 1, 2, 3... | |
| Workspace name fallback | ws.name when set, number otherwise. | |

**User's choice:** Waybar dot icons (Recommended)

---

| Option | Description | Selected |
|--------|-------------|----------|
| Only existing workspaces | Iterate Hyprland.workspaces ObjectModel; dynamic. | ✓ |
| Always show 1-10 | Fixed slots. Stable layout. | |

**User's choice:** Only existing (Recommended)

---

| Option | Description | Selected |
|--------|-------------|----------|
| One pill containing all buttons | Single ModulePill wraps Repeater. | ✓ |
| Per-button pill | Each workspace its own pill. | |

**User's choice:** One pill (Recommended)

---

| Option | Description | Selected |
|--------|-------------|----------|
| Scroll down=next, wraps | Hyprland's `e+1` / `e-1` dispatchers. | ✓ |
| Scroll up=next, wraps | Inverted. | |
| Scroll down=next, no wrap | Stop at edges. | |

**User's choice:** Scroll down=next, wraps (Recommended)

---

| Option | Description | Selected |
|--------|-------------|----------|
| Red dot color (Colours.critical) | Replace icon color on .urgent. Simple. | ✓ |
| Pulsing animation | ColorAnimation. Animations are Phase 16 — scope creep risk. | |
| Border/outline | 1px critical border. Adds geometry shift. | |

**User's choice:** Red dot color (Recommended)

---

| Option | Description | Selected |
|--------|-------------|----------|
| Color only — active=mauve, occupied=text, empty=subtext | Three states by color. | ✓ |
| Filled vs outline icon | Icon swap based on toplevels. | |
| Same icon, different opacity | 40% empty. | |

**User's choice:** Color only (Recommended)

---

## Volume Widget

| Option | Description | Selected |
|--------|-------------|----------|
| Icon + percentage |  75%. Matches Waybar. | ✓ |
| Icon-only | Just speaker icon. | |
| Percentage-only | Just '75%'. Loses mute affordance. | |

**User's choice:** Icon + percentage (Recommended)

---

| Option | Description | Selected |
|--------|-------------|----------|
| Slashed icon + dim text | Two signals. Robust. | ✓ |
| Slashed icon only | Subtler. | |
| Color change | Easier to miss. | |

**User's choice:** Slashed icon + dim text (Recommended)

---

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — scroll ±5% steps | Standard waybar pulseaudio. Triggers OSD in Phase 14. | ✓ |
| No — click only | Click opens pavucontrol; no quick-adjust. | |

**User's choice:** Yes — scroll ±5% (Recommended)

---

| Option | Description | Selected |
|--------|-------------|----------|
| Toggle mute | Right-click flips audio.muted. | ✓ |
| No action | Mute via pavucontrol only. | |
| Open mixer / sound settings | Alternate app. | |

**User's choice:** Toggle mute (Recommended)

---

## Music & Tray Widgets

| Option | Description | Selected |
|--------|-------------|----------|
| Icon + 'artist - title' |  Artist - Title. Matches Waybar. | ✓ |
| Icon + title only | Shorter. | |
| Per-state format | Different prefix paused vs playing. | |

**User's choice:** Icon + 'artist - title' (Recommended)

---

| Option | Description | Selected |
|--------|-------------|----------|
| Elide right at 50 chars | Match Waybar max-length=50. | |
| Fixed 30 chars | Tighter. | ✓ |
| No truncation | Risks pushing widgets offscreen. | |

**User's choice:** Fixed 30 chars (DEVIATION from recommended 50)
**Notes:** User explicitly preferred tighter truncation. Compensated by full-text tooltip (D-34).

---

| Option | Description | Selected |
|--------|-------------|----------|
| One pill, all icons | Compact tray group. | ✓ |
| Per-icon pill | Heavy visual weight. | |
| No pill, raw icons | Breaks Phase 12 D-07. | |

**User's choice:** One pill (Recommended)

---

| Option | Description | Selected |
|--------|-------------|----------|
| 21px, hide pill when empty | Match Waybar; auto-collapse. | ✓ |
| 21px, always visible empty | Layout stable, useless empty pill. | |
| 16px, hide when empty | Smaller, may not match Nerd Font icon scale. | |

**User's choice:** 21px, hide when empty (Recommended)

---

## Follow-up Pass 1: Tray menu, MPRIS empty state

| Option | Description | Selected |
|--------|-------------|----------|
| QsMenuOpener (native) | Renders SNI item.menu DBus tree natively. Idiomatic. | ✓ |
| item.display() fallback | Less control over style. | |

**User's choice:** QsMenuOpener (Recommended)

---

| Option | Description | Selected |
|--------|-------------|----------|
| workspace.activate() | QML-native method. | ✓ |
| HyprlandIpc.dispatch | Raw dispatch call. | |

**User's choice:** workspace.activate() (Recommended)

---

| Option | Description | Selected |
|--------|-------------|----------|
| Show icon + 'No track' | Avoid flicker between tracks. | ✓ |
| Hide entirely | Causes show/hide flicker. | |
| Show icon-only | Subtle. | |

**User's choice:** Show icon + 'No track' (Recommended)

---

| Option | Description | Selected |
|--------|-------------|----------|
| Show full untruncated metadata | Compensates for 30-char truncation. | ✓ |
| No tooltip | Truncated title is enough. | |

**User's choice:** Show full untruncated (Recommended)

---

## Follow-up Pass 2: pavucontrol launch, SNI status, scroll throttle, MPRIS prio

| Option | Description | Selected |
|--------|-------------|----------|
| Process.startDetached, no dedup | pavucontrol DBus single-instance handles re-focus. | ✓ |
| Check running first via pgrep | Adds Process overhead per click. | |

**User's choice:** Process.startDetached (Recommended)

---

| Option | Description | Selected |
|--------|-------------|----------|
| Render all + critical-tint NeedsAttention | Matches Waybar; preserves attention signal. | ✓ |
| Hide Passive items | Loses idle items like Dropbox. | |
| Render all, no special handling | Loses attention signal. | |

**User's choice:** Render all (Recommended)

---

| Option | Description | Selected |
|--------|-------------|----------|
| No debounce, direct write | PipeWire handles rapid updates. | ✓ |
| Debounce 50ms | Premature optimization. | |

**User's choice:** No debounce (Recommended)

---

| Option | Description | Selected |
|--------|-------------|----------|
| First playing in list order | Predictable; stable per-session. | ✓ |
| Hardcoded preference list | Spotify > firefox > others. | |
| Most recently activated | Heaviest. | |

**User's choice:** First playing in list order (Recommended)

---

## Follow-up Pass 3: hit area, PwObjectTracker, vol thresholds, cross-monitor

| Option | Description | Selected |
|--------|-------------|----------|
| Full ModulePill clickable | Better Fitts' law. | ✓ |
| Icon/text only | Tighter; users complain. | |

**User's choice:** Full ModulePill (Recommended)

---

| Option | Description | Selected |
|--------|-------------|----------|
| Inside AudioService singleton | One tracker for all consumers. | ✓ |
| Per-widget tracker | Wastes binds. | |

**User's choice:** Inside AudioService (Recommended)

---

| Option | Description | Selected |
|--------|-------------|----------|
| 0%=mute, <33%=low, <66%=mid, ≥66%=high | Standard Waybar thresholds. | ✓ |
| 0%=mute, else=high (single non-mute icon) | Loses gradient. | |
| 0%=mute, <50%=low, ≥50%=high | Two-step gradient. | |

**User's choice:** Three-step thresholds (Recommended)

---

| Option | Description | Selected |
|--------|-------------|----------|
| workspace.activate() native behavior | Hyprland default. | ✓ |
| Always focus original monitor first | Two-step dispatch. | |

**User's choice:** Native behavior (Recommended)

---

## Follow-up Pass 4: special workspaces, audio API, no-sink, hover anim

| Option | Description | Selected |
|--------|-------------|----------|
| Filter out (id<0 / 'special:') | Don't include scratchpad in row. | ✓ |
| Show all including special | Unpredictable layout. | |

**User's choice:** Filter out (Recommended)

---

| Option | Description | Selected |
|--------|-------------|----------|
| Properties + helper methods | Centralizes clamping + mute interaction. | ✓ |
| Properties only | Each consumer duplicates clamping. | |

**User's choice:** Properties + helpers (Recommended)

---

| Option | Description | Selected |
|--------|-------------|----------|
| Hide volume widget | visible:false; layout collapses. | ✓ |
| Show muted icon disabled | No clue what's wrong. | |
| Show 'No audio' text | Rare condition. | |

**User's choice:** Hide widget (Recommended)

---

| Option | Description | Selected |
|--------|-------------|----------|
| No animations — defer to Phase 16 | Avoid scope creep. | ✓ |
| Add Behavior on color now | Mild scope creep. | |

**User's choice:** No animations Phase 13 (Recommended)

---

## Follow-up Pass 5: tray anchor, menu close, MPRIS gate, MPRIS aux

| Option | Description | Selected |
|--------|-------------|----------|
| Below bar, top-aligned to icon | Standard top-bar tray menu. | ✓ |
| Default (let QsMenuAnchor decide) | May open offscreen. | |

**User's choice:** Below bar (Recommended)

---

| Option | Description | Selected |
|--------|-------------|----------|
| HyprlandFocusGrab | Per Phase 12 + P-16. | ✓ |
| grabFocus: true | Steals keyboard focus — forbidden. | |

**User's choice:** HyprlandFocusGrab (Recommended)

---

| Option | Description | Selected |
|--------|-------------|----------|
| Disable click + dim | Avoids silent click failure. | ✓ |
| Always allow click; let it no-op | Confusing UX. | |

**User's choice:** Disable click + dim (Recommended)

---

| Option | Description | Selected |
|--------|-------------|----------|
| Click only — play/pause | Per AUDIO-03. Lean. | ✓ |
| Add scroll = next/prev track | Convenient. | |
| Add right-click = next track | Less discoverable. | |

**User's choice:** Click only (Recommended)

---

## Follow-up Pass 6: tray icon API, audio scope, ws icon size, wheel math

| Option | Description | Selected |
|--------|-------------|----------|
| Quickshell IconImage | Built-in pixmap+iconName fallback. | ✓ |
| QtQuick Image manual | More code. | |

**User's choice:** IconImage (Recommended)

---

| Option | Description | Selected |
|--------|-------------|----------|
| Sink only for Phase 13 | AUDIO-01 only. | ✓ |
| Sink + source from day one | Unused property surface. | |

**User's choice:** Sink only (Recommended)

---

| Option | Description | Selected |
|--------|-------------|----------|
| Match text 14px | Visually balanced. | ✓ |
| Larger 16-18px | Inconsistent. | |

**User's choice:** 14px (Recommended)

---

| Option | Description | Selected |
|--------|-------------|----------|
| Divide by 120, sign → ±5 step | Robust across mice. | ✓ |
| Sign-only, ignore magnitude | Too jumpy on touchpads. | |

**User's choice:** Divide by 120 (Recommended)

---

## Follow-up Pass 7: ws active state, ws sort, urgent source, logging

| Option | Description | Selected |
|--------|-------------|----------|
| ws.active (currently visible) | Per-monitor highlight tracks visibility. | ✓ |
| ws.focused (currently receiving input) | Other monitors never highlight. | |
| Both (focused + active tier) | Visual noise. | |

**User's choice:** ws.active (Recommended)

---

| Option | Description | Selected |
|--------|-------------|----------|
| Sort by ws.id ascending | Stable ordering. | ✓ |
| Trust ObjectModel order | Jumpy when out-of-sequence. | |

**User's choice:** Sort by id (Recommended)

---

| Option | Description | Selected |
|--------|-------------|----------|
| Derive from toplevels | If no .urgent on Workspace, check toplevels. | ✓ |
| Skip urgent indicator if API absent | Loses WS-02 partial. | |

**User's choice:** Derive from toplevels (Recommended)

---

| Option | Description | Selected |
|--------|-------------|----------|
| Quiet — console.warn on Process exit !=0 | Silent on success. | ✓ |
| Verbose — console.log on every click | Noisy. | |
| No logging | Hardest to debug. | |

**User's choice:** Quiet (Recommended)

---

## Follow-up Pass 8: vol round, sink reactive, repeater model, UAT

| Option | Description | Selected |
|--------|-------------|----------|
| Math.round | Symmetric. | ✓ |
| Math.floor | Underrepresents. | |
| Math.ceil | Atypical. | |

**User's choice:** Math.round (Recommended)

---

| Option | Description | Selected |
|--------|-------------|----------|
| Auto-rebind PwObjectTracker on sink change | Headphone-plug works. | ✓ |
| Bind once at startup | Stale data on switch. | |

**User's choice:** Auto-rebind (Recommended)

---

| Option | Description | Selected |
|--------|-------------|----------|
| Use values + sort, returning array | Allows sort + filter. | ✓ |
| Bind ObjectModel directly | Loses sort/filter. | |

**User's choice:** values + sort (Recommended)

---

| Option | Description | Selected |
|--------|-------------|----------|
| Manual checklist per widget | One checkbox per native API behavior. | ✓ |
| Automated headless test | No QML test infrastructure in repo. | |
| Visual diff snapshots | No tooling installed. | |

**User's choice:** Manual checklist (Recommended)

---

## Follow-up Pass 9: multi-monitor ws, PwTracker target, tray fallback, MPRIS stop

| Option | Description | Selected |
|--------|-------------|----------|
| Each bar shows ALL workspaces | Matches Waybar default. | ✓ |
| Per-monitor filtered | Loses global view. | |

**User's choice:** All workspaces per bar (Recommended)

---

| Option | Description | Selected |
|--------|-------------|----------|
| defaultAudioSink only | .audio auto-tracked. | ✓ |
| Sink + audio explicitly | Redundant per QS docs. | |

**User's choice:** Sink only (Recommended)

---

| Option | Description | Selected |
|--------|-------------|----------|
| Render fallback Nerd Font glyph | Tray remains usable. | ✓ |
| Hide failed items silently | Loses access to actions. | |
| Render empty placeholder rectangle | Click works but visually odd. | |

**User's choice:** Fallback glyph (Recommended)

---

| Option | Description | Selected |
|--------|-------------|----------|
| Treat same as paused — click resumes | Spotify/Firefox behavior. | ✓ |
| Disable click in Stopped state | Conservative. | |

**User's choice:** Resumes (Recommended)

---

## Follow-up Pass 10: cursor, layout collapse, vol zero, music elide

| Option | Description | Selected |
|--------|-------------|----------|
| Pointing hand cursor on all clickable | Standard hover affordance. | ✓ |
| Default arrow cursor | Loses affordance. | |

**User's choice:** Pointing hand (Recommended)

---

| Option | Description | Selected |
|--------|-------------|----------|
| visible:false collapses | QML default. | ✓ |
| Reserve space (opacity 0) | Forbidden by Phase 12. | |

**User's choice:** visible:false (Recommended)

---

| Option | Description | Selected |
|--------|-------------|----------|
| Show 0% with low icon | Differentiates zero from muted. | |
| Show as muted | Conflates zero and muted. | ✓ |

**User's choice:** Show as muted (DEVIATION from recommended)
**Notes:** User accepts conflation between 0% and muted state.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Right elide | Matches Waybar text-overflow. | ✓ |
| Middle elide | Loses middle. | |
| No elide — hard truncate | Users may not notice. | |

**User's choice:** Right elide (Recommended)

---

## Follow-up Pass 11: cursor scope, audio null guards, wheel+click, singleton reg

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, all clickable widgets | Universal affordance. | ✓ |
| Only buttons / volume; not tray/music | Inconsistent. | |

**User's choice:** All clickable (Recommended)

---

| Option | Description | Selected |
|--------|-------------|----------|
| Computed properties guard against null | Defensive QML. | ✓ |
| Assume non-null | Crashes on PipeWire restart. | |

**User's choice:** Null guards (Recommended)

---

| Option | Description | Selected |
|--------|-------------|----------|
| Single MouseArea handles wheel + click | Standard pattern. | ✓ |
| Separate WheelHandler + TapHandler | Unfamiliar. | |

**User's choice:** Single MouseArea (Recommended)

---

| Option | Description | Selected |
|--------|-------------|----------|
| pragma Singleton + qmldir 'singleton' | Mirrors Phase 12 theme/Colours.qml. | ✓ |
| Plain QtObject + manual instance | Loses guarantee. | |

**User's choice:** pragma Singleton (Recommended)

---

## Follow-up Pass 12: shell.qml delta, widgets dir, cross-widget, pavu focus

| Option | Description | Selected |
|--------|-------------|----------|
| No, only BarContent.qml + new files | Minimal Phase 13 footprint. | ✓ |
| Add service init to shell.qml | Unnecessary; pragma Singleton auto-instantiates. | |

**User's choice:** Only BarContent.qml + new files (Recommended)

---

| Option | Description | Selected |
|--------|-------------|----------|
| widgets/ subdir + qmldir | Mirrors theme/ + services/. | ✓ |
| Top-level next to BarContent | Mixes shell + widget files. | |

**User's choice:** widgets/ subdir (Recommended)

---

| Option | Description | Selected |
|--------|-------------|----------|
| Avoid — widgets stand alone | Self-contained components. | ✓ |
| Allow cross-imports | Opens door to coupling. | |

**User's choice:** Avoid cross-imports (Recommended)

---

| Option | Description | Selected |
|--------|-------------|----------|
| Default — Process + Hyprland window rules | No special handling. | ✓ |
| Force-focus launched window | Brittle. | |

**User's choice:** Default behavior (Recommended)

---

## Claude's Discretion

- Repeater vs ListView vs RowLayout-of-Items inside ModulePill for workspace row
- Internal spacing inside the workspace pill (between buttons)
- IconImage props for SNI icons (sourceSize, smooth, mipmap)
- AudioService / MprisService / HyprWorkspaces internal property naming beyond public API
- Tooltip strings and capitalization
- QML import order and ID naming
- Right BarGroup widget order (music/volume/tray vs tray/music/volume)

## Deferred Ideas

- Volume OSD (AUDIO-02) → Phase 14
- Notification badge + swaync toggle (TRAY-02, TRAY-03) → Phase 14
- Hover animations (ANIM-01) → Phase 16
- Workspace tooltips, tray-item explicit tooltips → Phase 16 polish
- Mic/source volume widget — out of v1.2 scope
- Multi-player UI affordance → not in v1.2
- Music next/prev track buttons → future milestone
- Tray monochrome theme tint → rejected, original colors preserved
- Always-show 1-10 workspace slots → rejected
- Per-button workspace pill → rejected
