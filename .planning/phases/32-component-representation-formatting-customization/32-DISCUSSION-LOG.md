# Phase 32: Component Representation & Formatting Customization - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-20
**Phase:** 32-component-representation-formatting-customization
**Areas discussed:** System Resources (RAM & CPU), Clock & Date, Media Player & Status Indicators, Utilities, Updates & System Tray

---

## System Resources (RAM & CPU)

| Option | Description | Selected |
|--------|-------------|----------|
| Definite Used / Total GB ("X.X / Y.Y GB") | Alongside circular progress icon | |
| Definite Used GB with percentage ("5.4 GB (17%)") | Combined format | |
| Compact Used GB ("5.4 GB") | Reserving full total for hover popup | |
| X.X/Y.Y GB (ZZ%) -> ZZ= percentage used | User-specified custom format | ✓ |

**User's choice:** `X.X/Y.Y GB (ZZ%) -> ZZ= percentage used`
**Notes:** Definite memory used out of total memory with percentage used badge in parentheses.

| Option | Description | Selected |
|--------|-------------|----------|
| Icon + percentage ("XX%") | Always visible alongside RAM with standard warning threshold coloring | ✓ |
| Label + percentage ("CPU XX%") | Always visible alongside RAM | |
| Show CPU only above threshold | Kept compact during idle | |

**User's choice:** Icon + percentage ("XX%"), always visible alongside RAM with standard warning threshold coloring.

| Option | Description | Selected |
|--------|-------------|----------|
| Dynamic Swap | Hide when swap is 0, only display on bar when > 0%, matching RAM design | ✓ |
| Keep Swap in hover popup only | Keep top bar streamlined | |
| Always show Swap | Even when 0% used | |

**User's choice:** Option 1: Dynamic Swap, hidden when 0% and formatted identically to RAM (`X.X/Y.Y GB (ZZ%)`).

| Option | Description | Selected |
|--------|-------------|----------|
| Two-tier alert system | User brainstormed two-tier threshold with matching color on both icon and text | ✓ |
| Standard single threshold | 90% CPU, 95% RAM, 85% Swap | |

**User's choice:** Two-tier alert system with synchronous icon and text coloring. RAM: 80% Warning (Amber) / 90% Critical (Red); CPU: 60% Warning (Amber) / 90% Critical (Red); Swap: 70% Warning (Amber) / 85% Critical (Red).

---

## Clock & Date

| Option | Description | Selected |
|--------|-------------|----------|
| Keep current 12h format with seconds | "hh:mm:ss AP" (e.g. "07:25:10 AM") | ✓ |
| 12h format without seconds | "hh:mm AP" | |
| 24h format with seconds | "HH:mm:ss" | |
| 24h format without seconds | "HH:mm" | |

**User's choice:** Keep current 12h format with seconds ("hh:mm:ss AP").

| Option | Description | Selected |
|--------|-------------|----------|
| Keep current format: "ddd, dd-MM-yyyy" | e.g. "Sun, 20-09-2026" | ✓ |
| Full weekday + date | "dddd, dd MMMM yyyy" | |
| Month day year | "MMM dd, yyyy" | |
| Short date | "ddd, dd/MM" | |

**User's choice:** Keep current format: "ddd, dd-MM-yyyy".

| Option | Description | Selected |
|--------|-------------|----------|
| Bullet dot separator | "07:25:10 AM • Sun, 20-09-2026" | |
| Vertical pipe separator | "07:25:10 AM | Sun, 20-09-2026" | |
| Subtle pill-internal spacer without glyph | "07:25:10 AM  Sun, 20-09-2026" | ✓ |

**User's choice:** Subtle pill-internal spacer without glyph ("07:25:10 AM  Sun, 20-09-2026").

| Option | Description | Selected |
|--------|-------------|----------|
| Keep current default behavior | Hover preview for Calendar popup, click toggles right sidebar | ✓ |
| Click toggles Calendar popup | Dedicated button for right sidebar | |

**User's choice:** Keep current default behavior for now.

---

## Media Player & Status Indicators

| Option | Description | Selected |
|--------|-------------|----------|
| Keep upstream default formatting | cleanedTitle + trackArtist with elide: Text.ElideRight | ✓ |
| Unconstrained width | Dynamic expansion | |
| Compact title only | No artist | |

**User's choice:** Default dots-hyprland formatting is good enough.

| Option | Description | Selected |
|--------|-------------|----------|
| Keep upstream default click actions | Left popup, middle play/pause, right next; no scroll wheel | ✓ |
| Scroll wheel seek | +/- 5s seek | |
| Scroll wheel volume | Adjust volume on hover | |

**User's choice:** Keep upstream default click actions only (no scroll wheel on media).

| Option | Description | Selected |
|--------|-------------|----------|
| Dynamic privacy indicators in status cluster | Reveal animated icons (mic, screen_share) only while actively capturing | ✓ |
| Dedicated standalone alert pill | Separate pill | |
| Keep upstream as-is | No active privacy alert | |

**User's choice:** Integrated in the right status cluster with amber mic and red screen_share, with direct click actions (mic click mutes, screen share click opens recorder).

| Option | Description | Selected |
|--------|-------------|----------|
| Keep all current status indicators | Mute, Mic Mute, Keyboard layout, Notifications, Network, Bluetooth | ✓ |
| Hide keyboard layout | Single layout setup | |

**User's choice:** Keep all current indicators active using upstream defaults.

| Option | Description | Selected |
|--------|-------------|----------|
| Auto-collapse idle media | Dynamically hide Media Player pill when no music is actively playing | ✓ |
| Always keep Media Player visible | Displays "No media" | |

**User's choice:** Dynamically hide the Media Player pill when no music/media is actively playing.

| Option | Description | Selected |
|--------|-------------|----------|
| Disable bar background scrolling entirely | Adjust volume/brightness via sidebar sliders | ✓ |
| Keep background scroll | Upstream behavior | |

**User's choice:** Disable background scrolling entirely to prevent accidental changes and eliminate hover hints.

| Option | Description | Selected |
|--------|-------------|----------|
| Remove Active Window title | Not needed on the left side of the bar | ✓ |
| Keep 2-line title | Upstream behavior | |

**User's choice:** Active window display on the left side of the bar is not needed.

---

## Utilities, Updates & System Tray

| Option | Description | Selected |
|--------|-------------|----------|
| Current setup + Screen Recording button | Screen Snip, Color Picker, Keyboard Toggle, Mic Toggle, Performance Profile + Screen Record | ✓ |
| Streamlined utilities | Screen Snip, Color Picker, Power Menu | |

**User's choice:** Current setup + Screen Recording button (`showScreenRecord: true`). Retain default dots-hyprland mic button behavior (Option B).

| Option | Description | Selected |
|--------|-------------|----------|
| Dynamic updates pill | Hidden when 0; reveals icon + count when updates pending; click launches terminal update | ✓ |
| Always-visible status pill | Shows 0 or checkmark | |

**User's choice:** Dynamic updates pill (hidden when 0, shows icon + count, click launches yay -Syu), aggregating both official Pacman repos and AUR (`checkupdates` + `yay -Qua`).

| Option | Description | Selected |
|--------|-------------|----------|
| Keep upstream default weather | Glyph + temp, hover popup, right-click refresh, static Dhaka, Celsius | ✓ |
| Condition text included | "28°C Partly Cloudy" | |

**User's choice:** Keep upstream default weather for now with static city "Dhaka".

| Option | Description | Selected |
|--------|-------------|----------|
| Keep monochrome Material You icons | With overflow drawer for unpinned apps | ✓ |
| Full-color original icons | No tinting | |

**User's choice:** Keep monochrome icons (tinted to Material You theme) with overflow drawer for unpinned apps.

| Option | Description | Selected |
|--------|-------------|----------|
| Keep power actions in keybinds/sidebar | No dedicated power button in utility pill | ✓ |
| Add dedicated power button | On the bar | |

**User's choice:** Keep current setup of power actions.

---

## the agent's Discretion

- Clean modular extension pattern in `Resource.qml` (`customText` property) so the formatting can be driven dynamically by `Resources.qml`.
- Helper script and robust parsing for combining `checkupdates` and `yay -Qua` in `Updates.qml`.

## Deferred Ideas

- None — discussion stayed within phase scope.
