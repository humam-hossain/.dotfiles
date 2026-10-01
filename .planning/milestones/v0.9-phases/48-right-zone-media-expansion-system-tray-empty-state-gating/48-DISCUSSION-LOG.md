# Phase 48: Right-Zone Media Expansion & System Tray Empty State Gating - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-30
**Phase:** 48-right-zone-media-expansion-system-tray-empty-state-gating
**Areas discussed:** Media pill responsive width formula, Track & artist typography & separator styling, System tray empty-state gating & transition, Media popup anchor synchronization & interaction polish

---

## Media pill responsive width formula

### Question 1: Sizing Model
| Option | Description | Selected |
|--------|-------------|----------|
| Clamped percentage of screen width | Math.min(Math.max(screen.width * 0.12, 220), 450) px (~410px on 3440px ultrawide, ~230px on 1080p) | ✓ |
| Stepped tiers by monitor resolution | Discrete caps (450px for ultrawide, 320px for 1440p/1080p, 160px for compact) | |
| Fixed generous ceiling | Fixed 400px across standard screens, 160px for shortened | |
| You decide | Cleanest responsive formula | |

**User's choice:** Clamped percentage of screen width — e.g. Math.min(Math.max(screen.width * 0.12, 220), 450) px
**Notes:** Scales smoothly across multi-monitor setups without crowding center widgets.

### Question 2: Shortened Tier Scaling
| Option | Description | Selected |
|--------|-------------|----------|
| Proportional compact clamp | Clamp width between 140px and 180px (Math.min(Math.max(screen.width * 0.10, 140), 180)) | ✓ |
| Fixed compact width | Hardcode exactly 160px when useShortenedForm === 1 | |
| You decide | Best proportion preserving layout balance on secondary displays | |

**User's choice:** Proportional compact clamp — When useShortenedForm === 1, clamp width between 140px and 180px
**Notes:** Prevents layout crowding or overflow on rotated or narrow screens (e.g. HDMI-A-2).

### Question 3: Dynamic Content Hugging
| Option | Description | Selected |
|--------|-------------|----------|
| Dynamic content-fit up to maximum width | Pill expands fluidly to fit text length up to responsive maximum; short titles stay compact | ✓ |
| Fixed width ceiling whenever active | Pill always stretches to calculated maximum limit | |
| You decide | Smoothest aesthetic integration | |

**User's choice:** Dynamic content-fit up to maximum width
**Notes:** Pill hugs text length naturally rather than leaving large empty gaps for short song titles.

### Question 4: Resizing Animation
| Option | Description | Selected |
|--------|-------------|----------|
| Fluid Material 3 animation | Retain BarGroup's 250ms emphasized deceleration width animation on track changes and start/stop | ✓ |
| Instant snappy resize | Jump immediately to target width without animation | |
| You decide | Standard shell animation conventions | |

**User's choice:** Fluid Material 3 animation
**Notes:** Preserves visual continuity and polished M3 transitions across the top status bar.

---

## Track & artist typography & separator styling

### Question 1: Visual Distinction
| Option | Description | Selected |
|--------|-------------|----------|
| Visual hierarchy with muted artist | Primary foreground color (colOnLayer1) for title, subtle muted subtext (colSubtext / 70% opacity) for artist with " • " | ✓ |
| Unified single-color text | Keep title, bullet, and artist in exact same color token (colOnLayer1) | |
| Two-line stacked layout | Stacked column with title on top and artist below | |
| You decide | Cleanest Material 3 hierarchy | |

**User's choice:** Visual hierarchy with muted artist
**Notes:** Distinct coloring ensures track titles stand out prominently while keeping artist metadata visible.

### Question 2: Missing Artist Fallback
| Option | Description | Selected |
|--------|-------------|----------|
| Clean title-only fallback | Display just track title without trailing separator | |
| Player name fallback | Fall back to player identity ("Title • Spotify") | |
| Write-in | "default behavior which how right now is" | ✓ |

**User's choice:** default behavior which how right now is
**Notes:** Renders cleanedTitle without trailing separator or placeholder when artist metadata is missing.

### Question 3: Text Overflow
| Option | Description | Selected |
|--------|-------------|----------|
| Right elision with full popup/tooltip | Truncate cleanly on right with "..." (Text.ElideRight); full title in popup/tooltip | |
| Horizontal marquee on hover | Scroll long text horizontally on mouse hover | |
| Continuous marquee while playing | Continuously scroll overflowing text slowly in a loop | |
| Write-in | "no need to change anything in the popup" | ✓ |

**User's choice:** no need to change anything in the popup (keep standard Text.ElideRight on pill)
**Notes:** Retains standard right elision with "..." on the pill; popup remains completely untouched.

### Question 4: Verbose Toggle Gating
| Option | Description | Selected |
|--------|-------------|----------|
| Preserve Config.options.bar.verbose gating | Show text when verbose enabled, collapse to circular progress icon when disabled | ✓ |
| Always show text regardless of verbose toggle | Keep track/artist visible whenever media is active | |
| You decide | Honor existing shell configuration contracts | |

**User's choice:** Preserve Config.options.bar.verbose gating
**Notes:** Retains upstream config toggle capability for minimalist bar configurations.

---

## System tray empty-state gating & transition

### Question 1: Gating Mechanism
| Option | Description | Selected |
|--------|-------------|----------|
| Reactive visibility check on BarGroup | Bind visible: (root.useShortenedForm === 0) && (SystemTray.items.values.length > 0) directly on sysTrayGroup | ✓ |
| Loader pattern matching adjacent modules | Wrap SysTray in Loader { active: ...; visible: active } | |
| You decide | Most performant and reliable pattern | |

**User's choice:** Reactive visibility check on BarGroup
**Notes:** Keeps D-Bus tray service hot in memory while preventing empty rectangle pill from rendering when 0 apps exist.

### Question 2: Source of Truth
| Option | Description | Selected |
|--------|-------------|----------|
| Direct Quickshell SystemTray.items.values.length > 0 | Check Quickshell SNI service collection, matching SysTray.qml separator logic | ✓ |
| TrayService combined length | Check (TrayService.pinnedItems.length + TrayService.unpinnedItems.length) > 0 | |
| You decide | Direct and reliable service binding | |

**User's choice:** Direct Quickshell SystemTray.items.values.length > 0
**Notes:** Zero intermediary overhead, directly tracks registered status notifier items.

### Question 3: Reflow Behavior
| Option | Description | Selected |
|--------|-------------|----------|
| Instant clean reflow via RowLayout visibility | Toggling visible immediately removes/inserts tray pill in RowLayout with 4px spacing | ✓ |
| Fade and collapse animation | Animate opacity to 0 then collapse width over 150ms | |
| You decide | Established shell pill transition patterns | |

**User's choice:** Instant clean reflow via RowLayout visibility
**Notes:** Avoids empty floating borders or ghost spaces in the Right zone.

### Question 4: Multi-Monitor Policy
| Option | Description | Selected |
|--------|-------------|----------|
| Keep restricted to primary full-width screens (useShortenedForm === 0) | Only show when useShortenedForm === 0 and items exist | ✓ |
| Permit on shortened screens if space allows | Show on useShortenedForm < 2 if tray items exist | |
| You decide | Preserve multi-monitor space defense rules | |

**User's choice:** Keep restricted to primary full-width screens (useShortenedForm === 0)
**Notes:** Keeps compact/vertical displays clean and uncluttered.

---

## Media popup anchor synchronization & interaction polish

### Question 1: Click Mapping
| Option | Description | Selected |
|--------|-------------|----------|
| Retain full-pill click mapping | Left-click toggles popup, Middle-click toggles play/pause, Right/Forward-click next, Back-click previous | ✓ |
| Split click targets | Left-click icon toggles play/pause, click text toggles popup | |
| You decide | Keep current upstream click mapping | |

**User's choice:** Retain full-pill click mapping
**Notes:** Retains existing user muscle memory across the enlarged ~450px pill footprint.

### Question 2: Wheel Events
| Option | Description | Selected |
|--------|-------------|----------|
| Transparent scroll events | Do not intercept mouse wheel events on media pill | ✓ |
| Wheel adjusts media player volume | Scrolling up/down adjusts player volume in 5% increments | |
| You decide | Keep behavior transparent | |

**User's choice:** Transparent scroll events
**Notes:** Keeps bar-level scroll behavior consistent without accidental volume changes.

### Question 3: Continuous Coordinate Tracking
| Option | Description | Selected |
|--------|-------------|----------|
| Continuous real-time coordinate tracking | Retain onWidthChanged and onXChanged connections so popup stays centered during width shifts | ✓ |
| Lock coordinates upon opening | Freeze popup at opened position until dismissed | |
| You decide | Maintain Phase 39 reactive anchoring contracts | |

**User's choice:** Continuous real-time coordinate tracking
**Notes:** Smoothly slides the open popup in sync with the pill center across width animation frames.

### Question 4: Idle Auto-Collapse
| Option | Description | Selected |
|--------|-------------|----------|
| Complete idle auto-collapse | Hide media pill completely when no media is playing or title is empty | |
| Compact paused icon state | Show compact 28px music note icon when paused/idle | |
| Write-in | "keep right now state" | ✓ |

**User's choice:** keep right now state (complete idle auto-collapse)
**Notes:** Completely hides the pill when no active media player with a title exists, freeing status bar space.

---

## the agent's Discretion

- Precise implementation of rich-text formatting in `Media.qml` to achieve the primary/muted color distinction while preserving single-line right elision.
- Automated assertion test suite validating responsive formulas and empty-state tray gating.

## Deferred Ideas

None — all discussions focused strictly on Phase 48 scope.
