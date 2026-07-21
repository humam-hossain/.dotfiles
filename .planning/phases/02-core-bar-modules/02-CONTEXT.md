# Phase 2: Core Bar Modules - Context

**Gathered:** 2026-07-21
**Status:** Ready for planning

<domain>
## Phase Boundary

Implement and verify the four essential status-bar modules — **workspaces (BAR-01)**, **clock (BAR-02)**, **system tray (BAR-03)**, and **network (BAR-04)** — on the existing Illogical Impulse bar from Phase 1. Scope is configuration, layout rewiring, and bugfixes so these modules meet roadmap success criteria day-to-day — not building modules from scratch (they already exist under `modules/ii/bar/`).

Phase 3 owns CPU/memory/disk/volume as product goals. Phase 4 owns IPC/keybinds/cutover. Weather (v2 CMOD) stays off for this phase.

</domain>

<decisions>
## Implementation Decisions

### Workspace appearance (BAR-01)
- **D-01:** Keep ii app icons — `Config.options.bar.workspaces.showAppIcons: true` (not Waybar-style dots only).
- **D-02:** Show **10** workspace slots (`shown: 10`) to match Hyprland workspaces 1–10 (DP-1: 1–5, HDMI-A-2: 6–10).
- **D-03:** Monochrome workspace app icons — `monochromeIcons: true`.
- **D-04:** Interaction: **click** switches workspace; **wheel** cycles (`workspace r±1`). Stock Hyprland `workspace N` dispatch from Phase 1 gap fix stays (no `hl.dsp.focus`).

### Clock format & click (BAR-02)
- **D-05:** Waybar-like clock with **seconds** — configure `Config.options.time` so the bar shows a full datetime comparable to Waybar `{:%a %Y-%m-%d %I:%M:%S %p}` (Qt format + `secondPrecision: true`). Exact Qt format string is planner discretion as long as weekday, date, 12-hour time, seconds, and AM/PM are present.
- **D-06:** Click/hover keeps **ii `ClockWidgetPopup`** (date, uptime, todos) — do **not** open Google Calendar URL like Waybar.
- **D-07:** Timezone = **system** (host is Asia/Dhaka). Do not hardcode timezone unless system TZ drifts.
- **D-08:** **Time only in the bar** for the clock widget — no separate longDate/`verbose` date text beside the clock once the format string already includes date parts (avoid duplication).

### Network bar detail (BAR-04)
- **D-09:** Bar surface remains **icon-only** (`Network.materialSymbol` Material glyph) — no SSID/signal text on the bar.
- **D-10:** State distinction via **ii Material symbol set only** (ethernet / signal_wifi_* / disconnected / off / bad) — no extra color coding required for Phase 2.
- **D-11:** Click path: network lives on the **right-sidebar indicators pill**; click opens **right sidebar / wifi panel** (existing ii path). No dedicated NetworkPopup in Phase 2.
- **D-12:** SSID/signal detail: **keep current ii behavior** (“the way it is right now is fine”) — do not invent new tooltip requirements beyond what already works; UAT must still be able to verify connected SSID/signal and disconnected states via existing UI (sidebar/service state).

### System tray (BAR-03)
- **D-13:** Full-color tray icons (not monochrome) for app recognition (Discord, Steam, etc.).
- **D-14:** Keep ii tray pin/overflow defaults — `invertPinnedItems: true`, `pinnedItems: ["Fcitx"]` (pin list acts as blacklist; overflow for unpinned). Left-click activate, right-click menu.

### Bar layout (module order)
User-locked order (visual left → right). Planner rewires `BarContent.qml` (and related groups) to match:

| Region | Order (L→R) | Modules |
|--------|-------------|---------|
| **Left** | 1, 2, 5, 3 | LeftSidebarButton → ActiveWindow → **Workspaces** → Resources |
| **Center** | 6, 7 | **ClockWidget** → UtilButtons (weather slot reserved but **off**) |
| **Right** | 4, 8, 10, 9 | Media → BatteryIndicator → **SysTray** → **Indicators pill** |

- **D-15:** Apply the table above as the Phase 2 bar layout contract.
- **D-16:** **WeatherBar stays disabled** for Phase 2 (`bar.weather.enable: false`). Center is Clock + UtilButtons only; weather is a later/v2 concern even though user may re-enable later in the same center region.
- **D-17:** Non-core modules (LeftSidebar, ActiveWindow, Resources, Media, Battery, UtilButtons) **remain present** at the positions above — rearrange, do not strip them for Phase 2.

### Indicators pill (item 9)
- **D-18:** Keep **full ii cluster** contents: mute revealer, mic revealer, HyprlandXkb, NotificationUnreadCount, Network, Bluetooth.
- **D-19:** Reorder icons **on the bar pill only** to:  
  **mute → mic → xkb → Bluetooth → Network → notif**  
  (sidebar panel contents/order unchanged; whole pill still toggles `GlobalStates.sidebarRightOpen`).

### Agent's Discretion
- Exact Qt `time.format` / date format strings that realize D-05 + D-08 without double date text
- How to restructure `BarContent.qml` Row/BarGroup/layoutDirection so visual L→R matches D-15 despite existing `RightToLeft` on the right section
- Whether tray monochrome default needs an explicit Config flip vs Appearance path
- Tooltip polish for network if UAT cannot verify SSID without code change (only if current behavior fails success criteria)
- Dual-monitor: same panel on all screens (Phase 1 D-13) unless layout rewiring surfaces a per-monitor issue

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Planning
- `.planning/PROJECT.md` — Core value (Waybar parity before cutover), constraints, Material theme decisions
- `.planning/REQUIREMENTS.md` — BAR-01, BAR-02, BAR-03, BAR-04 (Phase 2); weather is v2 CMOD
- `.planning/ROADMAP.md` — Phase 2 goal + 4 success criteria
- `.planning/STATE.md` — Current position Phase 2
- `.planning/phases/01-shell-foundation-theme/01-CONTEXT.md` — Wholesale ii, Material theme, stock workspace dispatch, all-monitors panel
- `.planning/phases/01-shell-foundation-theme/01-LEARNINGS.md` — Stock `workspace` dispatch; font stack; gap-fix patterns
- `.planning/phases/01-shell-foundation-theme/01-04-SUMMARY.md` — Workspaces.widgetPadding + dispatch fix already landed

### Implementation (this repo)
- `.config/quickshell/modules/ii/bar/BarContent.qml` — Module groups and indicators pill (primary rewiring target)
- `.config/quickshell/modules/ii/bar/Workspaces.qml` — Workspace UI + click/wheel dispatch
- `.config/quickshell/modules/ii/bar/ClockWidget.qml` / `ClockWidgetPopup.qml` — Clock display + popup
- `.config/quickshell/modules/ii/bar/SysTray.qml` / `SysTrayItem.qml` / `SysTrayMenu.qml` — Tray UI
- `.config/quickshell/services/TrayService.qml` — Pin/overflow logic
- `.config/quickshell/services/Network.qml` — wifi/ethernet state + `materialSymbol`
- `.config/quickshell/services/DateTime.qml` — time/date strings + second precision
- `.config/quickshell/services/HyprlandData.qml` — workspace data
- `.config/quickshell/modules/common/Config.qml` — `bar.workspaces`, `time`, `tray`, `bar.weather` defaults
- `.config/hypr/hyprland.conf` — workspace 1–10 monitor assignment (DP-1 / HDMI-A-2)
- `.config/waybar/config.jsonc` — Parity reference for clock format, tray, network, workspace habits (not a code base to port)

### Prior architecture maps (may be stale vs wholesale ii tree)
- `.planning/codebase/ARCHITECTURE.md` — High-level desktop/quickshell patterns
- `.planning/codebase/STRUCTURE.md` — Repo layout
- `.planning/codebase/STACK.md` — Tooling stack

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Workspaces.qml` — Fully implemented; Phase 1 fixed `widgetPadding` and stock `workspace` dispatch
- `ClockWidget.qml` + `DateTime.qml` — Format driven by `Config.options.time.*`; popup already has calendar/uptime/todos
- `SysTray.qml` + `TrayService.qml` — Pin/overflow + menus via `Quickshell.Services.SystemTray`
- `Network.qml` + bar `MaterialSymbol` — Icon-only status; full wifi UI in sidebar (`wifiNetworks/`)
- `Config.qml` — All toggles for workspaces/time/tray/weather without hardcoding widgets

### Established Patterns
- Service singleton → widget render (FWK-03)
- Material symbols + Appearance tokens for chrome; tray icons may stay full-color per D-13
- Right section uses `layoutDirection: Qt.RightToLeft` — visual order ≠ child declaration order; rewiring must preserve intended L→R
- Indicators are a single `RippleButton` pill toggling right sidebar — Network is not a separate click target

### Integration Points
- `panelFamilies/IllogicalImpulseFamily.qml` loads horizontal `Bar` when not vertical
- Hyprland workspaces 1–10 split across DP-1 and HDMI-A-2
- Waybar still coexists until Phase 4 cutover — dual bars may show during Phase 2 testing
- `nmcli`-backed Network service; tray may also host nm-applet if installed (orthogonal to Network icon)

</code_context>

<specifics>
## Specific Ideas

- Phase 1 philosophy carries forward: **embrace ii**, fix/config rather than rewrite — but **layout is user-custom**, not stock ii order
- Clock should feel like current Waybar datetime (with seconds) while click stays native ii popup
- User listed modules by number and ordered regions explicitly; treat that list as the layout source of truth
- Indicators pill internal order customized: mute | mic | xkb | Bluetooth | Network | notif
- Weather intentionally off despite being in the original center wishlist

</specifics>

<deferred>
## Deferred Ideas

- **WeatherBar enabled + center placement** — user wants layout slot eventually; `bar.weather.enable` remains false for Phase 2 (v2 CMOD / later)
- **CPU / memory / disk / volume product goals** — Phase 3 (Resources already on bar left but Phase 3 owns metrics parity)
- **Google Calendar on clock click** — rejected for Phase 2; could revisit if user wants dual action later
- **SSID text on bar** — rejected; icon-only + existing ii detail paths
- **IPC / keybinds / Waybar cutover** — Phase 4
- **nm-applet coexistence policy** — not decided; leave default system behavior

</deferred>

---

*Phase: 2-Core Bar Modules*
*Context gathered: 2026-07-21*
