# Phase 32: Component Representation & Formatting Customization - Context

**Gathered:** 2026-09-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Systematically audit and customize all 17 bar components across Tier 1 (native dots-hyprland JSON options in `capture/ii/`) and Tier 2 (personal QML overrides in `restow/quickshell/`):

1. **System Resources (COMP-01, COMP-02):** Reformat RAM to definite gigabytes `X.X/Y.Y GB (ZZ%)`, keep CPU percentage alongside with standard icon, dynamic swap visibility and formatting matching RAM, and establish a two-tier alerting system (Amber Warning / Red Critical) synchronized across both icons and text.
2. **Clock & Date Representation (COMP-03):** Display time in 12h format with seconds (`hh:mm:ss AP`), date as `ddd, dd-MM-yyyy`, separated by a subtle spacer without glyph bullets, retaining hover calendar popup and right sidebar click toggle.
3. **Media Player & Status Indicators (COMP-04, COMP-08, COMP-10):** Preserve upstream track title formatting and click interactions; auto-collapse media pill when idle; connect built-in `services/Privacy.qml` to show active microphone (Amber) and screen sharing (Red) in-use alerts in the status cluster with quick-mute/recorder actions; retain all status icons; hide/remove active window title on the left; disable background volume/brightness scrolling.
4. **Utilities, Updates & System Tray (COMP-05, COMP-06, COMP-07, COMP-09):** Enable the full utility buttons suite (Screen Snip, Color Picker, Keyboard Toggle, Mic Toggle, Performance Profile) plus Screen Recording; deploy dynamic pending updates pill checking Pacman and AUR (`checkupdates` + `yay -Qua`); retain upstream weather widget with static Dhaka city; retain monochrome Material You system tray icons with 4px spacing and overflow menu.

Out of scope:
- Rearranging modular bar sections across Left, Center, and Right or dual-monitor testing across `DP-1` and `HDMI-A-1` (Phase 33 owns this).
- Full milestone verification, wallpaper dynamic palette switching tests, and `./bootstrap.sh` fresh-machine deployment (Phase 34 owns this).

</domain>

<decisions>
## Implementation Decisions

### System Resources (RAM, CPU, Swap)
- **D-01 (RAM Formatting):** Format memory in `Resource.qml` / `Resources.qml` as definite `X.X/Y.Y GB (ZZ%)` (e.g. `5.4/31.2 GB (17%)`) where `ZZ%` is the rounded integer usage percentage, positioned alongside the circular progress icon.
- **D-02 (CPU Formatting):** CPU usage represented with Material Symbol icon (`planner_review`) and percentage badge (`XX%`), always visible alongside RAM.
- **D-03 (Dynamic Swap Visibility & Format):** Swap memory is dynamically hidden when swap usage is 0, and revealed on the bar only when actively in use (> 0%). When visible, formatted identically to RAM: `X.X/Y.Y GB (ZZ%)`.
- **D-04 (Two-Tier Alert System):** Implement two-tier visual threshold alerting with synchronous color change on **both the icon and the text**:
  - Tier 1 (Warning): Material 3 Warning / Amber accent token.
  - Tier 2 (Critical / Error): Material 3 Error accent token (`colError` / red).
- **D-05 (Custom Resource Thresholds):**
  - RAM: 80% Warning / 90% Critical
  - CPU: 60% Warning / 90% Critical
  - Swap: 70% Warning / 85% Critical

### Clock & Date Representation
- **D-06 (Time Formatting):** Set 12h format with seconds: `"format": "hh:mm:ss AP"` (e.g. `07:25:10 AM`) with `"secondPrecision": true` via native `config.json`.
- **D-07 (Date Formatting):** Set date pattern: `"dateFormat": "ddd, dd-MM-yyyy"` (e.g. `Sun, 20-09-2026`) via native `config.json`.
- **D-08 (Clock Separator Styling):** In `ClockWidget.qml`, replace the bullet dot (`•`) with a subtle pill-internal spacer without glyph (`07:25:10 AM  Sun, 20-09-2026`).
- **D-09 (Clock & Calendar Interactions):** Retain dots-hyprland default interaction behavior (hover preview for Calendar popup, click toggles Right Sidebar).

### Media Player & Status Cluster
- **D-10 (Media Player Presentation):** Retain upstream default track title formatting (`cleanedTitle` + `trackArtist` with `elide: Text.ElideRight`).
- **D-11 (Media Player Controls):** Retain upstream default click controls (left-click opens popup, middle-click play/pause, right-click next track; no scroll-wheel binding on the media pill).
- **D-12 (Dynamic Media Auto-Collapse):** Dynamically hide/collapse the Media Player pill when no media is actively playing, freeing up bar space during idle.
- **D-13 (Privacy In-Use Alerts):** Connect `services/Privacy.qml` into `BarContent.qml`'s `indicatorsRowLayout` to dynamically reveal animated alert icons during active capture:
  - Amber `mic` icon when `Privacy.micActive` is true. Direct click mutes the microphone.
  - Red `screen_share` icon when `Privacy.screenSharing` is true. Direct click opens recorder controls.
- **D-14 (Status Indicators Retained):** Keep all standard status icons active (Audio mute, Mic mute, Keyboard layout, Notifications with dynamic unread reveal, Network, and Bluetooth) adhering to upstream visual defaults.
- **D-15 (Active Window Title Removal):** Remove / hide `ActiveWindow` from the left section of `BarContent.qml` to provide a clean, uncluttered look.
- **D-16 (Bar Background Scroll Removal):** Disable background mouse scroll handlers on `barLeftSideMouseArea` and `barRightSideMouseArea` to prevent accidental volume or brightness adjustments and eliminate hover hint tooltips.

### Utilities, Updates & System Tray
- **D-17 (Utility Buttons Suite):** Enable the full suite in `config.json` / `UtilButtons.qml`: Screen Snip, Color Picker, Keyboard Toggle, Mic Toggle, Performance Profile, **plus** Screen Recording (`showScreenRecord: true`). Retain default dots-hyprland button behavior (Option B).
- **D-18 (Dynamic Package Updates Pill):** Implement a dedicated status pill for pending package updates:
  - Dynamically hidden when pending update count is 0.
  - Reveals icon + update count badge (e.g. `14`) when updates > 0.
  - Click action launches terminal update via `kitty -1 --hold=yes fish -i -c 'yay -Syu'`.
  - Service aggregates both official Arch repositories and AUR packages (`checkupdates` + `yay -Qua`).
- **D-19 (Weather Representation):** Retain upstream default weather presentation (glyph + temperature `XX°C`, hover forecast popup, right-click refresh) with static location "Dhaka" and metric Celsius.
- **D-20 (System Tray):** Retain monochrome Material You icon tinting, 4px icon spacing, and expandable overflow chevron drawer for unpinned apps. Power actions remain in keybindings and sidebar menus (no redundant power icon).

### the agent's Discretion
- Implementation details of the `customText` or `textOverride` property in `Resource.qml` to cleanly support `X.X/Y.Y GB (ZZ%)`.
- Helper script or command execution logic in `services/Updates.qml` to reliably count `checkupdates` and `yay -Qua` without hang.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap and Requirements
- `.planning/ROADMAP.md` §Phase 32 — Component Representation & Formatting Customization goal and success criteria
- `.planning/REQUIREMENTS.md` lines 15–27 — COMP-01 through COMP-10 specifications
- `.planning/STATE.md` §Milestone v0.6 — Current project status and decisions log

### Native Configuration (Tier 1)
- `capture/ii/.config/illogical-impulse/config.json` — Native JSON options for time, weather, utilButtons, tray, and resources
- `~/.config/illogical-impulse/config.json` — Live active config file

### Upstream Quickshell Modules & Services
- `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/Resources.qml` — Bar resources layout
- `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/Resource.qml` — Single resource metric component
- `vendor/dots-hyprland/dots/.config/quickshell/ii/services/ResourceUsage.qml` — RAM, Swap, CPU polling service
- `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/ClockWidget.qml` — Time & date bar component
- `vendor/dots-hyprland/dots/.config/quickshell/ii/services/DateTime.qml` — System clock date & time service
- `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/Media.qml` — MPRIS media player component
- `vendor/dots-hyprland/dots/.config/quickshell/ii/services/Privacy.qml` — PipeWire screensharing and microphone activity service
- `vendor/dots-hyprland/dots/.config/quickshell/ii/services/Updates.qml` — System update check service
- `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/UtilButtons.qml` — Shortcut action buttons
- `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/weather/WeatherBar.qml` — Weather bar widget
- `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/SysTray.qml` — System tray container and overflow menu

### Personal Quickshell Overlay (Tier 2)
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml` — Personal overlay bar layout and component mounting
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarGroup.qml` — Personal overlay pill container and resize animation

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ResourceUsage.qml`: Provides `memoryUsed`, `memoryTotal`, `memoryUsedPercentage`, `swapUsed`, `swapTotal`, `swapUsedPercentage`, `cpuUsage`, and `kbToGbString()`.
- `services/Privacy.qml`: Exists as a singleton monitoring `Privacy.micActive` and `Privacy.screenSharing` via PipeWire link groups; ready for direct binding.
- `services/Updates.qml`: Existing service with timer and process runner, extensible to aggregate AUR updates via `yay -Qua`.

### Established Patterns
- Two-tier customization architecture: Native settings in `config.json` (Tier 1, tracked in `capture/ii/`), custom QML code in `restow/quickshell/` (Tier 2).
- Dynamic pill expansion established in Phase 31 (`implicitWidth` behavior in `BarGroup.qml` with `emphasizedDecel` animation).
- Revealer animations: Using `Revealer { reveal: condition ... }` with `Appearance.animation.elementMoveFast` for smooth icon reveals.

### Integration Points
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/Resource.qml`: Adds `customText` property and 2-tier warning/error color bindings.
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/Resources.qml`: Passes formatted `X.X/Y.Y GB (ZZ%)` string to RAM and Swap.
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml`: Updates mouse scroll area, removes `ActiveWindow`, connects `Privacy` revealer icons, and mounts dynamic `UpdatesButton`.
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/ClockWidget.qml`: Replaces bullet dot separator with a subtle spacer.

</code_context>

<specifics>
## Specific Ideas

- **User Directives:**
  - RAM format: `"X.X/Y.Y GB (ZZ%) -> ZZ= percentage used"`
  - Alert system: `"two tear alert systems ... the color would be two different colors but those colors has to be also not only in the icon but also in the text itself same color"`
  - Thresholds: `"RAM: warning amber at 80% and critical at 90% ... CPU: warning at 60% and critical at 90% ... Swap: 70% warning and critical at 85%"`
  - Media & Status: `"i think the default is good enough"`, `"Keep upstream default click actions only"`, `"Dynamically hide the Media Player pill when no music/media is actively playing"`
  - Active Window: `"active window display on the left side of the bar is not needed"`
  - Background scrolling: `"Disable background scrolling entirely (adjust volume/brightness only via sidebar sliders)"`
  - Utility buttons: `"option 3. but the current setupt + the screen recording button"`
  - Upstream fidelity: `"just don't change anything from default dots-hyprland behavior"`

</specifics>

<deferred>
## Deferred Ideas

- **Phase 33 (Modular Layout & Live Trial-and-Error Rearrangement):** Reorganizing Left, Center, and Right bar sections in `BarContent.qml` and live visual trial-and-error evaluation across dual monitors (`DP-1` and `HDMI-A-1`).
- **Phase 34 (Verification, Zero Drift & Bootstrap Integration):** Dynamic wallpaper palette change tests, full verification gate (`arch/dots-hyprland.sh verify --strict`), and `./bootstrap.sh` fresh-machine deployment.

</deferred>

---

*Phase: 32-component-representation-formatting-customization*
*Context gathered: 2026-09-20*
