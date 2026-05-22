# Phase 14: Script-Backed Widgets - Context

**Gathered:** 2026-05-21
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver all script-backed and control widgets — CPU, memory, disk, network, ping, weather (current + forecast), clock, backlight, volume OSD, and notification count — achieving full Waybar widget parity in the Quickshell bar. Center BarGroup is populated with weather, clock, and forecast. Each widget uses existing Waybar scripts via Process (reused in-place) or inline Process for data sources with no existing script. No popup panels (Phase 15), no animations (Phase 16). Lock and power buttons are explicitly skipped.

</domain>

<decisions>
## Implementation Decisions

### CPU Widget (SYS-01)
- **D-01:** `CpuService.qml` pragma Singleton in `services/`, not inline. Consistent with Phase 14 service pattern.
- **D-02:** Poll interval = 3s. Responsive enough for a bar display without excessive Process spawns.
- **D-03:** Sources `/proc/stat` via inline awk command: `["bash", "-c", "awk '/^cpu / {print 100-($5/($2+$3+$4+$5))*100}' /proc/stat"]`. No external script needed.
- **D-04:** Color thresholds per SYS-01: ≥50% = `Colours.warning` (yellow), ≥90% = `Colours.critical` (red).
- **D-05:** No click action (matches Waybar CPU behavior).
- **D-06:** Tooltip: none (Waybar CPU had no tooltip).

### Memory Widget (SYS-02)
- **D-07:** `MemoryService.qml` pragma Singleton in `services/`. Calls existing `memory.sh` via Process.
- **D-08:** Poll interval = 5s (matches Waybar config and memory.sh execution interval).
- **D-09:** Script path: `["bash", "-c", "$HOME/.config/waybar/scripts/system/memory.sh"]`. Reused in-place per scripts strategy.
- **D-10:** Tooltip: yes — memory.sh already provides a tooltip with top processes (via smem).
- **D-11:** Color thresholds: same as CPU — ≥50% warning, ≥90% critical. Uses Colours.warning / Colours.critical.
- **D-12:** No click action (Waybar had `kitty -e btop`; user opted out).

### Disk Widget (SYS-03)
- **D-13:** `DiskService.qml` pragma Singleton in `services/`. Inline `df -h` command, no existing script.
- **D-14:** Poll interval = 30s (matches Waybar disk interval).
- **D-15:** Command: `["bash", "-c", "df -h / | awk 'NR==2 {printf \"%s/%s\", $3, $2}'"]`. Returns used/total in human-readable format.
- **D-16:** Color thresholds: same warning/critical policy — ≥50% warning, ≥90% critical.
- **D-17:** Click action: opens nautilus via `Process { command: ["nautilus"]; running: false }` with `.startDetached()`.
- **D-18:** Tooltip: yes — show free/total and usage percentage (matches Waybar disk tooltip).

### Network Widget (SYS-04)
- **D-19:** `NetworkService.qml` pragma Singleton in `services/`. Uses nmcli Process.
- **D-20:** Poll interval = 10s (matches Waybar network interval).
- **D-21:** Shows: WiFi SSID or ethernet interface name. Disconnected state shows "No Network" with disconnected icon.
- **D-22:** Command pattern: `["bash", "-c", "nmcli -t -f active,ssid,signal,type dev wifi | head -1"]` for WiFi; fallback to `["bash", "-c", "nmcli -t -f device,type,state dev status | grep ethernet"]` for wired.
- **D-23:** Icon thresholds by signal: 4 signal levels using Nerd Font WiFi icons (󰤯 󰤟 󰤢 󰤥 󰤨), matching Waybar.
- **D-24:** Click action: opens nmtui in kitty terminal via `Process { command: ["kitty", "-e", "nmtui"]; running: false }` with `.startDetached()`. Per SYS-04 requirement.
- **D-25:** Tooltip: yes — show SSID, interface, IP address (matches Waybar network tooltip).

### Ping Widget (CUST-01)
- **D-26:** `PingService.qml` pragma Singleton in `services/`. Calls existing `ping_status.sh` via Process.
- **D-27:** Poll interval = 5s (matches Waybar ping interval).
- **D-28:** Script path: `["bash", "-c", "$HOME/.config/waybar/scripts/network/ping_status.sh"]`. Reused in-place.
- **D-29:** Color classes from script output: `good`/`medium`/`bad`/`critical`/`dead`. Maps to semantic colors:
  - good → Colours.pingGood (blue)
  - medium → Colours.pingMedium (yellow)
  - bad → Colours.pingBad (peach)
  - critical → Colours.pingCritical (red)
  - dead → Colours.pingDead (mauve)
- **D-30:** Click action: opens `http://localhost:8765/` via xdg-open. Matches Waybar config.
- **D-31:** Tooltip: yes — shows ping status details from script output.

### Weather Widgets (CUST-02, CUST-03)
- **D-32:** Two separate services: `WeatherService.qml` (current) and `ForecastService.qml` (forecast). pragma Singletons in `services/`.
- **D-33:** Poll interval = 200s for both (matches Waybar intervals and current scripts).
- **D-34:** Script paths: `["bash", "-c", "$HOME/.config/waybar/scripts/weather/curr_weather.sh"]` and `["bash", "-c", "$HOME/.config/waybar/scripts/weather/forcast_weather.sh"]`. Reused in-place.
- **D-35:** Each widget shows the full text output from its respective script (includes weather icon, temperature, humidity per current format).
- **D-36:** Tooltips: yes. Both scripts already provide detailed tooltip JSON output.
- **D-37:** No click actions in Phase 14. Phase 15 popups will handle click-to-expand.

### Clock Widget (CUST-04)
- **D-38:** `ClockService.qml` pragma Singleton in `services/`. Wraps QML `Timer { interval: 1000 }` + Qt.formatDateTime for Asia/Dhaka timezone.
- **D-39:** Clock format: `"{:%a %Y-%m-%d %I:%M:%S %p}"` — matches current Waybar clock format exactly.
- **D-40:** Updates every 1 second.
- **D-41:** Service singleton enables Phase 15 calendar popup to reuse date context (month navigation, today highlighting).

### Backlight Widget (CTRL-01)
- **D-42:** `BacklightService.qml` pragma Singleton in `services/`.
- **D-43:** Poll interval = 30s read via `["bash", "-c", "ddcutil getvcp 10 2>/dev/null | awk '/current value/ {gsub(/,/,\"\",$9); print $9}'"]`.
- **D-44:** Click: adjusts brightness with 300ms debounced ddcutil write. `Timer { interval: 300; running: false }` gates the write.
- **D-45:** Display format: sun icon (Nerd Font ) + brightness percentage.
- **D-46:** Tooltip: none (Waybar backlight had no tooltip).

### Volume OSD (AUDIO-02)
- **D-47:** PopupWindow anchored below VolumeWidget, not center-screen. Uses `WlrLayer.Overlay`.
- **D-48:** Trigger: fires on ANY `AudioService.volumePercent` change — scroll on volume widget, media keys, pavucontrol updates.
- **D-49:** Visual: horizontal progress bar in a pill container, ~150x8px. Pill shaped like ModulePill with Catppuccin styling.
- **D-50:** Auto-hide: 1.5s Timer per AUDIO-02 requirement.
- **D-51:** Uses `AudioService.volumePercent` directly (singleton indirection pays off — no re-binding PwObjectTracker).

### Notification Widget (TRAY-02, TRAY-03)
- **D-52:** `NotificationService.qml` pragma Singleton in `services/`.
- **D-53:** Polling via `swaync-client -c` on a 5s Timer with StdioCollector. Not streaming (avoids P-11 StdioLineParser complexity for a simple badge count).
- **D-54:** Click toggles swaync panel via `Process { command: ["swaync-client", "-t"]; running: false }` with `.startDetached()`. Per TRAY-03.
- **D-55:** Display format: Nerd Font bell icon (󰂚) + unread count. When count is 0, shows only the bell icon. Matches Waybar `custom/notification` style.

### Center BarGroup Layout
- **D-56:** Widget order: WeatherWidget → ClockWidget → ForecastWidget (matching Waybar: custom/weather, clock, custom/weather2).
- **D-57:** Each widget in its own ModulePill wrapper — consistent with left/right section per-module pill pattern.

### General Design Decisions
- **D-58:** Error state: when a service's Process fails or returns no data, show Nerd Font error glyph + "err" in Colours.critical red. User knows the widget should be there. Matches Waybar error behavior.
- **D-59:** Tooltips enabled for: disk, memory, weather (current + forecast), clock, network, ping. Matches Waybar tooltip coverage.
- **D-60:** Script strategy: call Waybar scripts in-place via `["bash", "-c", "$HOME/.config/waybar/scripts/..."]`. No `.config/quickshell/scripts/` directory created. No copies or symlinks. Waybar scripts remain the single source of truth.

### Colour Aliases — Added to Colours.qml
- **D-61:** New semantic aliases added to Colours.qml (from ARCHITECTURE.md):
  - `diskColor` = `blue` (#89b4fa)
  - `cpuColor` = `sapphire` (#74c7ec)
  - `memoryColor` = `sky` (#89dceb)
  - `networkColor` = `teal` (#94e2d5)
  - `pingGood` = `blue` (#89b4fa)
  - `pingMedium` = `yellow` (#f9e2af)
  - `pingBad` = `peach` (#fab387)
  - `pingCritical` = `red` (#f38ba8)
  - `pingDead` = `mauve` (#cba6f7)
  - `clockColor` = `rosewater` (#f5e0dc)
  - `backlightColor` = `rosewater` (#f5e0dc)
  - `notifColor` = `lavender` (#b4befe)

### Poll Interval Summary
- **D-62:** CPU: 3s | Memory: 5s | Disk: 30s | Network: 10s | Ping: 5s | Weather: 200s | Backlight: 30s | Clock: 1s | Notification: 5s

### Agent's Discretion
- Exact internal property names in service singletons beyond the public API documented above.
- Detailed QML import lists, ID naming, and internal Item structure.
- Exact icon glyphs for network signal levels and notification bell.
- Tooltip string formatting and capitalization.
- Volume OSD pill exact border-radius, font-size, and color values (use Colours.moduleBg + Colours.accent for bar fill).
- BacklightService debounce timer implementation details (single-shot vs repeating).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Architecture and Patterns
- `.planning/research/ARCHITECTURE.md` — Service singleton pattern, Process + Timer + StdioCollector pattern, script path strategy, per-widget semantic colors (lines 146-166), polling intervals table (lines 232-238), data flow diagram (lines 415-436).
- `.planning/research/SUMMARY.md` — Stack additions, feature table stakes, architecture approach, pitfall prevention.
- `.planning/research/PITFALLS.md` — P-05 (ddcutil I2C saturation: 30s poll), P-06 (Process $HOME expansion), P-08 (QML binding loops), P-11 (StdioLineParser for streaming), P-18 (deferred Process start).
- `.planning/research/FEATURES.md` — Widget parity table mapping Waybar modules to implementations.

### Phase 12 & 13 Carryover
- `.planning/phases/12-bar-skeleton-and-theme/12-CONTEXT.md` — ModulePill API (D-07/D-10), BarGroup default-children (D-09), Colours semantic aliases (D-08), D-20 (scripts/ deferred), D-02 (surface0=#000000).
- `.planning/phases/13-native-api-widgets/13-CONTEXT.md` — AudioService singleton API (D-04/D-05), BarContent center empty (D-56), Phase 13 deferred (volume OSD, notification count), ModulePill precedent.
- `.config/quickshell/BarContent.qml` — Current layout: left=WorkspacesWidget, right=Music+Volume+Tray, center empty. Phase 14 fills center.

### Waybar Reference (behavior to match)
- `.config/waybar/config.jsonc` — Full module list with intervals, format strings, click actions, tooltip configs. Reference for every Phase 14 widget.
- `.config/waybar/style.css` — Visual dimensions (border-radius, font-size, padding) that inform QML equivalent values.

### Script References (reused in-place)
- `.config/waybar/scripts/system/memory.sh` — Called by MemoryService. JSON output format: `{"text", "tooltip", "class", "percentage"}`.
- `.config/waybar/scripts/network/ping_status.sh` — Called by PingService. JSON output format: `{"text", "class"}`.
- `.config/waybar/scripts/weather/curr_weather.sh` — Called by WeatherService. JSON output: `{"text", "tooltip"}`.
- `.config/waybar/scripts/weather/forcast_weather.sh` — Called by ForecastService. JSON output: `{"text", "tooltip"}`.

### Requirements
- `.planning/REQUIREMENTS.md` §SYS — SYS-01 (CPU), SYS-02 (memory), SYS-03 (disk), SYS-04 (network).
- `.planning/REQUIREMENTS.md` §CUST — CUST-01 (ping), CUST-02 (weather current), CUST-03 (weather forecast), CUST-04 (clock).
- `.planning/REQUIREMENTS.md` §CTRL — CTRL-01 (backlight).
- `.planning/REQUIREMENTS.md` §AUDIO — AUDIO-02 (volume OSD).
- `.planning/REQUIREMENTS.md` §TRAY — TRAY-02 (notification count), TRAY-03 (notification click toggle).
- `.planning/ROADMAP.md` §"Phase 14: Script-Backed Widgets" — Success criteria 1-6.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `.config/quickshell/services/AudioService.qml` — pragma Singleton pattern. `volumePercent` property drives Volume OSD trigger. Phase 14 services follow the identical pattern.
- `.config/quickshell/services/qmldir` — Existing service registration file. Phase 14 adds entries for: CpuService, MemoryService, DiskService, NetworkService, PingService, WeatherService, ForecastService, ClockService, BacklightService, NotificationService.
- `.config/quickshell/widgets/qmldir` — Existing widget registration. Phase 14 adds widgets: CpuWidget, MemoryWidget, DiskWidget, NetworkWidget, PingWidget, WeatherWidget, ClockWidget, ForecastWidget, BacklightWidget, NotificationWidget.
- `.config/waybar/scripts/` — Five existing scripts: `memory.sh`, `ping_status.sh`, `curr_weather.sh`, `forcast_weather.sh`, `weather/functions.sh`. All called in-place via Process.

### Established Patterns (Phase 13)
- `pragma Singleton` + `qmldir` registration for data services (services/ pattern).
- `import qs.services` and `import qs.widgets` for module loading.
- Process: `Timer { interval; running: true; repeat: true; triggeredOnStart: true; onTriggered: proc.running = true }` + `Process { command; stdout: StdioCollector { onStreamFinished: { parse JSON } } }`.
- Process path: `["bash", "-c", "$HOME/.config/waybar/scripts/..."]` — always wrap in bash for $HOME expansion.
- Deferred start: Timer at 0ms interval rather than `Component.onCompleted` (P-18).
- ModulePill wrapper for every widget (radius 8, padding 6/14, moduleBg).
- Click handlers: inline Process with `running: false` and `.startDetached()` on click.
- Tooltips via QML ToolTip component.

### Integration Points
- `BarContent.qml` — Center BarGroup currently commented as empty. Phase 14 replaces with: `WeatherWidget {}`, `ClockWidget {}`, `ForecastWidget {}`.
- Service singletons auto-instantiate on first `import qs.services` — no explicit registration in shell.qml or Bar.qml.
- Colours.qml — new semantic aliases added (D-61): diskColor, cpuColor, memoryColor, networkColor, pingGood/Medium/Bad/Critical/Dead, clockColor, backlightColor, notifColor.
- New widget files import `qs.theme` (Colours) + `qs.services` (specific services). Cross-widget imports avoided per Phase 13 D-54.

### Greenfield Areas
- No existing `.config/quickshell/popups/` directory — Phase 14 creates only `VolumeOsd.qml` (all other popups are Phase 15).
- No existing backlight, cpu, disk, memory, network, ping, weather, or notification QML — all new files.
- Volume OSD uses `PopupWindow` (not PanelWindow) with `WlrLayer.Overlay` — first use of PopupWindow in the project.

</code_context>

<specifics>
## Specific Ideas

- All script-backed services call Waybar scripts in-place — no copies, no symlinks, no scripts/ directory. Waybar tree is the single source of truth.
- Per-widget semantic colours centralized in Colours.qml — widgets reference `Colours.cpuColor`, `Colours.diskColor` etc. rather than hardcoding hex values.
- Volume OSD triggers on ANY volume change (not just scroll) — AudioService singleton indirection enables this without re-binding PwObjectTracker.
- Error = visible error glyph + "err" in red, not hidden. User should always know a widget is supposed to be there.
- Lock (CTRL-02) and Power (CTRL-03) widgets explicitly skipped per user decision. Not implemented in Phase 14 or any v1.2 phase.
- Clock format identical to Waybar: `{:%a %Y-%m-%d %I:%M:%S %p}` — visual continuity during parallel deploy.

</specifics>

<deferred>
## Deferred Ideas

- Lock button (CTRL-02) — explicitly dropped. No Phase 14 implementation.
- Power button (CTRL-03) — explicitly dropped. No Phase 14 implementation.
- Calendar popup — Phase 15 (POPUP-01). ClockService singleton provides date context.
- Network popup — Phase 15 (POPUP-02). NetworkService singleton provides SSID/IP data.
- Weather popup — Phase 15 (not in spec but from ARCHITECTURE.md). WeatherService singleton provides tooltip data.
- Hover animations — Phase 16 (ANIM-01).
- Notification streaming (swaync-client -swb) — not chosen; polling is sufficient for a badge count.

</deferred>

---

*Phase: 14-script-backed-widgets*
*Context gathered: 2026-05-21*
