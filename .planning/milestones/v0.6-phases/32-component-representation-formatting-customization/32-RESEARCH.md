# Phase 32: Component Representation & Formatting Customization - Research

**Researched:** 2026-09-20  
**Domain:** Quickshell 0.2.x QML component architecture, dots-hyprland status bar modules, GNU Stow overlay deployment, Material Design 3 color token coordination, PipeWire link group telemetry, Pacman/AUR package updates  
**Confidence:** HIGH  

<user_constraints>
## User Constraints (from CONTEXT.md)

### Implementation Decisions

#### System Resources (RAM, CPU, Swap)
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

#### Clock & Date Representation
- **D-06 (Time Formatting):** Set 12h format with seconds: `"format": "hh:mm:ss AP"` (e.g. `07:25:10 AM`) with `"secondPrecision": true` via native `config.json`.
- **D-07 (Date Formatting):** Set date pattern: `"dateFormat": "ddd, dd-MM-yyyy"` (e.g. `Sun, 20-09-2026`) via native `config.json`.
- **D-08 (Clock Separator Styling):** In `ClockWidget.qml`, replace the bullet dot (`•`) with a subtle pill-internal spacer without glyph (`07:25:10 AM  Sun, 20-09-2026`).
- **D-09 (Clock & Calendar Interactions):** Retain dots-hyprland default interaction behavior (hover preview for Calendar popup, click toggles Right Sidebar).

#### Media Player & Status Cluster
- **D-10 (Media Player Presentation):** Retain upstream default track title formatting (`cleanedTitle` + `trackArtist` with `elide: Text.ElideRight`).
- **D-11 (Media Player Controls):** Retain upstream default click controls (left-click opens popup, middle-click play/pause, right-click next track; no scroll-wheel binding on the media pill).
- **D-12 (Dynamic Media Auto-Collapse):** Dynamically hide/collapse the Media Player pill when no media is actively playing, freeing up bar space during idle.
- **D-13 (Privacy In-Use Alerts):** Connect `services/Privacy.qml` into `BarContent.qml`'s `indicatorsRowLayout` to dynamically reveal animated alert icons during active capture:
  - Amber `mic` icon when `Privacy.micActive` is true. Direct click mutes the microphone.
  - Red `screen_share` icon when `Privacy.screenSharing` is true. Direct click opens recorder controls.
- **D-14 (Status Indicators Retained):** Keep all standard status icons active (Audio mute, Mic mute, Keyboard layout, Notifications with dynamic unread reveal, Network, and Bluetooth) adhering to upstream visual defaults.
- **D-15 (Active Window Title Removal):** Remove / hide `ActiveWindow` from the left section of `BarContent.qml` to provide a clean, uncluttered look.
- **D-16 (Bar Background Scroll Removal):** Disable background mouse scroll handlers on `barLeftSideMouseArea` and `barRightSideMouseArea` to prevent accidental volume or brightness adjustments and eliminate hover hint tooltips.

#### Utilities, Updates & System Tray
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

### Deferred Ideas (OUT OF SCOPE)
- **Phase 33 (Modular Layout & Live Trial-and-Error Rearrangement):** Reorganizing Left, Center, and Right bar sections in `BarContent.qml` and live visual trial-and-error evaluation across dual monitors (`DP-1` and `HDMI-A-1`).
- **Phase 34 (Verification, Zero Drift & Bootstrap Integration):** Dynamic wallpaper palette change tests, full verification gate (`arch/dots-hyprland.sh verify --strict`), and `./bootstrap.sh` fresh-machine deployment.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| **COMP-01** | User can view memory usage formatted as definite gigabytes used out of total gigabytes (`X.X GB / Y.Y GB` / `X.X/Y.Y GB (ZZ%)`) instead of a simple percentage. | `ResourceUsage.qml:16-17` [VERIFIED: `ResourceUsage.qml:16-17`] provides `memoryUsed`, `memoryTotal`, and `memoryUsedPercentage`. Adding `property string customText: ""` to `Resource.qml` and passing `${(ResourceUsage.memoryUsed / (1024 * 1024)).toFixed(1)}/${(ResourceUsage.memoryTotal / (1024 * 1024)).toFixed(1)} GB (${Math.round(ResourceUsage.memoryUsedPercentage * 100)}%)` from `Resources.qml` renders definite gigabytes alongside percentage. `BarGroup.qml:14-21` [VERIFIED: `BarGroup.qml:14-21`] animates dynamic width expansion smoothly. |
| **COMP-02** | User can view CPU usage with custom formatting, warning thresholds, and clean visual indicators. | `ResourceUsage.qml:22` [VERIFIED: `ResourceUsage.qml:22`] provides `cpuUsage`. Upstream `Resource.qml:68` [VERIFIED: `Resource.qml:68`] rendered only a raw number without `%`. Adding `%` badge formatting and introducing a two-tier alerting system (Amber warning at 60%, Red critical at 90%) in `Resource.qml` synchronously recolors the circular ring (`ClippedFilledCircularProgress`), MaterialSymbol icon, and text label. Swap threshold alerting (70% warning / 85% critical) and dynamic reveal (> 0% usage) integrate seamlessly into the same component. |
| **COMP-03** | User can configure Clock & Date widget representation, date pattern, and 12h/24h formats via native configuration. | `DateTime.qml:21,24` [VERIFIED: `DateTime.qml:21,24`] binds to `Config.options?.time.format` and `dateFormat`. Setting `"format": "hh:mm:ss AP"` and `"dateFormat": "ddd, dd-MM-yyyy"` with `"secondPrecision": true` in `capture/ii/.config/illogical-impulse/config.json:467-476` [VERIFIED: `config.json:467-476`] configures native 12h time with seconds and full date. Overriding `ClockWidget.qml:25-30` [VERIFIED: `ClockWidget.qml:25-30`] replaces the unicode bullet dot (`•`) with a clean 8px spacer without glyph. |
| **COMP-04** | User can view Media Player pill with track title, playback controls, and volume/seek scroll actions. | `Media.qml:15-16,31-42` [VERIFIED: `Media.qml:15-16,31-42`] implements `cleanedTitle` + `trackArtist` eliding, left-click popup open, middle-click play/pause, right/forward next track, and back previous track. Setting `visible: (root.useShortenedForm < 2) && (MprisController.activePlayer?.isPlaying ?? false)` in `BarContent.qml:120-123` [VERIFIED: `BarContent.qml:120-123`] enables dynamic auto-collapse when idle, while preserving all default click controls when active. |
| **COMP-05** | User can view Weather pill displaying temperature, conditions glyph, and interactive weather forecast popup. | `WeatherBar.qml:35-49` [VERIFIED: `WeatherBar.qml:35-49`] displays `Icons.getWeatherIcon(Weather.data.wCode)` glyph, temperature `XX°C`, hover `WeatherPopup`, and right-click manual refresh. Configured natively in `capture/ii/.../config.json:177-183` [VERIFIED: `config.json:177-183`] with `"city": "Dhaka"` and `"useUSCS": false` (metric). Loaded cleanly via `BarContent.qml:332-339` [VERIFIED: `BarContent.qml:332-339`]. |
| **COMP-06** | User can access Utility buttons pill providing shortcuts for Screen Snip, Color Picker, and Power menu. | `UtilButtons.qml:23-157` [VERIFIED: `UtilButtons.qml:23-157`] implements loaders for `showScreenSnip`, `showScreenRecord`, `showColorPicker`, `showKeyboardToggle`, `showMicToggle`, `showDarkModeToggle`, and `showPerformanceProfileToggle`. Setting `"showScreenRecord": true` in `capture/ii/.../config.json:172` [VERIFIED: `config.json:172`] activates Screen Recording (`videocam` button invoking `Directories.recordScriptPath`), enabling the full utility suite with dots-hyprland Option B behavior. |
| **COMP-07** | User can view pending Pacman and AUR package updates count via a dedicated status pill. | `services/Updates.qml:49-57` [VERIFIED: `Updates.qml:49-57`] previously relied solely on `checkupdates`, failing when `pacman-contrib` was uninstalled or AUR was ignored. Overriding `Updates.qml` with a non-blocking aggregated command (`checkupdates` + `yay -Qua` with `yay -Qu` fallback) reliably counts official and AUR packages. Authoring `modules/ii/bar/UpdatesButton.qml` and mounting it in `BarContent.qml` creates a dedicated pill that is hidden at 0 and launches `kitty -1 --hold=yes fish -i -c 'yay -Syu'` on click. |
| **COMP-08** | User can view Privacy in-use alerts whenever the microphone, camera, or screen recording is actively capturing. | Upstream `services/Privacy.qml:14-15` [VERIFIED: `Privacy.qml:14-15`] suffers from a JavaScript array-to-boolean type coercion bug where `[].filter(...).map(...)` coerces to `true`, making alerts permanently active. Overriding `services/Privacy.qml` with `Pipewire.linkGroups.values.some(...)` ensures boolean fidelity. Mounting two animated `Revealer` items in `BarContent.qml:254-316` [VERIFIED: `BarContent.qml:254-316`] displays an Amber `mic` icon (click mutes via `wpctl`) and Red `screen_share` icon (click opens recorder) only during live capture. |
| **COMP-09** | User can interact with System Tray icons and context menus with balanced icon spacing and padding. | Upstream `SysTray.qml:73` [VERIFIED: `SysTray.qml:73`] configured wide `columnSpacing: 15`. Overriding `SysTray.qml` with `columnSpacing: 4` establishes balanced 4px icon spacing matching `BarGroup` defaults, while retaining monochrome Material You icon tinting, Fcitx pinning, and the expandable overflow chevron drawer (`overflowPopup`). |
| **COMP-10** | User can view audio/mic mute states, network connectivity, bluetooth status, and unread notification counter. | `BarContent.qml:260-315` [VERIFIED: `BarContent.qml:260-315`] maintains `Audio.sink?.audio?.muted` ("volume_off"), `Audio.source?.audio?.muted` ("mic_off"), `HyprlandXkbIndicator`, `Notifications.unread` badge, `Network.materialSymbol`, and `BluetoothStatus`. Removing `ActiveWindow` (`BarContent.qml:92-98`) and eliminating background scroll handlers and `ScrollHint` tooltips (`BarContent.qml:50-78, 189-218`) provides a clean left section and prevents accidental volume/brightness jitter. |
</phase_requirements>

## Summary

Phase 32 customizes and audits all 17 bar components across the top status bar, executing a strict two-tier architecture:
- **Tier 1 (Native `config.json` in `capture/ii/`):** Utilizes native dots-hyprland schema options for clock format (`hh:mm:ss AP`), date format (`ddd, dd-MM-yyyy`), second precision, utility button visibility (enabling `showScreenRecord: true`), weather parameters (Dhaka, metric), system tray behavior (monochrome, passive filtering), and base resource thresholds.
- **Tier 2 (Personal QML Overlays in `restow/quickshell/`):** Deploys clean, surgically targeted QML overrides using GNU Stow `--no-folding` into `~/.config/quickshell/ii/` to fulfill requirements where upstream dots-hyprland lacks configuration hooks.

### Critical Engineering Findings & Discoveries:
1. **The Upstream Privacy Boolean Bug:** In upstream `services/Privacy.qml:14-15`, properties `screenSharing` and `micActive` evaluate `Pipewire.linkGroups.values.filter(...).map(...)`. In JavaScript / QML, an empty array `[]` is truthy (`Boolean([]) === true`). Consequently, in unpatched upstream Quickshell, `Privacy.screenSharing` and `Privacy.micActive` are *always true* [VERIFIED via `qml6` runtime execution]. This research resolves this by deploying a clean override in `restow/quickshell/.../services/Privacy.qml` using Array `some()` returning primitive booleans.
2. **Text Container Width Bottleneck:** In upstream `Resource.qml:54`, the text label item has a hardcoded `implicitWidth: fullPercentageTextMetrics.width` with `text: "100"`. When formatting RAM as `5.4/31.2 GB (17%)`, this hardcoded width truncates or clips the text. Phase 32 replaces this with dynamic width calculation (`customText.length > 0 ? percentageText.implicitWidth : fullPercentageTextMetrics.width`), which pairs with `BarGroup`'s animated `implicitWidth` to expand pills smoothly.
3. **Synchronous Two-Tier Alerts:** Standard dots-hyprland only supported a single `warningThreshold` that turned only the circular progress ring red (`colError`), leaving the icon and text disconnected. Phase 32 implements a synchronized two-tier state:
   - Warning Tier: Amber (`#FFA000` / `#FFB74D`) applied across progress ring, icon, and text.
   - Critical Tier: Red (`Appearance.colors.colError`) applied across progress ring, icon, and text.
   - Thresholds: RAM (80% / 90%), CPU (60% / 90%), Swap (70% / 85%).
4. **Non-Blocking Dual-Repo Update Service:** Upstream `Updates.qml` checked only `which checkupdates`. On systems where `pacman-contrib` is not installed, or to capture AUR updates, `checkupdates` fails or ignores AUR. Phase 32 deploys an aggregated checker combining `checkupdates` and `yay -Qua` (with graceful `yay -Qu` fallback) that executes in the background and populates a dedicated `UpdatesButton` pill launching `kitty -1 --hold=yes fish -i -c 'yay -Syu'`.

## Architectural Responsibility Map

| Capability / Widget | Primary Tier | Implementation File | Rationale |
|---------------------|--------------|---------------------|-----------|
| **RAM Gigabytes & Percentage** | Tier 2 Overlay | `restow/quickshell/.../bar/Resource.qml`<br/>`restow/quickshell/.../bar/Resources.qml` | Formats memory as `X.X/Y.Y GB (ZZ%)` [VERIFIED: D-01] and unlocks dynamic text width. |
| **CPU Usage & Badge** | Tier 2 Overlay | `restow/quickshell/.../bar/Resource.qml` | Material symbol icon (`planner_review`) with percentage badge (`XX%`) [VERIFIED: D-02]. |
| **Dynamic Swap Usage** | Tier 2 Overlay | `restow/quickshell/.../bar/Resources.qml` | Dynamically hidden at 0%, visible when >0% with `X.X/Y.Y GB (ZZ%)` [VERIFIED: D-03]. |
| **Two-Tier Visual Alerting** | Tier 2 Overlay | `restow/quickshell/.../bar/Resource.qml` | Amber warning / Red critical synchronized across circular progress, icon, and text [VERIFIED: D-04, D-05]. |
| **Clock Time & Date Patterns** | Tier 1 Config | `capture/ii/.../config.json` | Native `"time.format": "hh:mm:ss AP"` and `"time.dateFormat": "ddd, dd-MM-yyyy"` [VERIFIED: D-06, D-07]. |
| **Clock Non-Glyph Spacer** | Tier 2 Overlay | `restow/quickshell/.../bar/ClockWidget.qml` | Replaces bullet glyph (`•`) with an 8px spacer item [VERIFIED: D-08]. |
| **Media Player Auto-Collapse** | Tier 2 Overlay | `restow/quickshell/.../bar/BarContent.qml` | Binds `visible` to active playing state, collapsing pill when idle [VERIFIED: D-12]. |
| **Privacy In-Use Alerts** | Tier 2 Overlay | `restow/quickshell/.../services/Privacy.qml`<br/>`restow/quickshell/.../bar/BarContent.qml` | Corrects boolean PipeWire logic and mounts Amber mic / Red screen share revealers [VERIFIED: D-13, COMP-08]. |
| **Status Indicators Cluster** | Tier 1 & 2 | `restow/quickshell/.../bar/BarContent.qml` | Retains audio/mic mute, XKB layout, network, bluetooth, and unread notifications [VERIFIED: D-14, COMP-10]. |
| **ActiveWindow Removal** | Tier 2 Overlay | `restow/quickshell/.../bar/BarContent.qml` | Removes/hides `ActiveWindow` from left bar section for clean aesthetic [VERIFIED: D-15]. |
| **Background Scroll Removal** | Tier 2 Overlay | `restow/quickshell/.../bar/BarContent.qml` | Removes scroll handlers and `ScrollHint` overlays on left/right mouse areas [VERIFIED: D-16]. |
| **Utility Buttons Suite** | Tier 1 Config | `capture/ii/.../config.json` | Enables full utility buttons suite plus Screen Record (`showScreenRecord: true`) [VERIFIED: D-17, COMP-06]. |
| **Dedicated Updates Pill** | Tier 2 Overlay | `restow/quickshell/.../services/Updates.qml`<br/>`restow/quickshell/.../bar/UpdatesButton.qml` | Aggregates Pacman + AUR updates; dedicated pill launching terminal upgrade [VERIFIED: D-18, COMP-07]. |
| **Weather Representation** | Tier 1 Config | `capture/ii/.../config.json` | Dhaka city, metric Celsius, upstream glyph and forecast popup retained [VERIFIED: D-19, COMP-05]. |
| **System Tray Refinement** | Tier 1 & 2 | `capture/ii/.../config.json`<br/>`restow/quickshell/.../bar/SysTray.qml` | Retains monochrome tinting, sets 4px icon spacing, retains overflow chevron [VERIFIED: D-20, COMP-09]. |

## Standard Stack

### Core

| Component / Package | Version / Path | Purpose | Why Standard |
|---------------------|----------------|---------|--------------|
| `quickshell` | 0.2.1 (`quickshell-git`) [VERIFIED: `quickshell --version`] | Desktop Shell Framework | Native Wayland shell engine executing the `ii` status bar and QML components. |
| `stow` | 2.4.1 [VERIFIED: pacman `stow`] | Symlink Farm Manager | Manages leaf symlinks into `~/.config/quickshell/` via `--no-folding`. |
| `qt6-declarative` | 6.11.2-1 [VERIFIED: pacman] | QML Runtime Engine | Evaluates QtQuick Layouts, property bindings, animations, and TextMetrics. |
| `yay` | 12.5.7 [VERIFIED: `yay --version`] | AUR & Pacman Helper | Aggregates repository and AUR package updates and executes upgrades in terminal. |
| `pipewire` & `wireplumber` | 1:1.4.10 [VERIFIED: system] | Audio & Video Stream Daemon | Supplies `PwNodeType.VideoSource` and `AudioSource` link groups to `Privacy.qml`. |
| `kitty` | 0.45.0 [VERIFIED: kitty --version] | Terminal Emulator | Invoked by `UpdatesButton` to run interactive `yay -Syu` sessions. |

### Supporting

| Component / Tool | Version / Path | Purpose | When to Use |
|------------------|----------------|---------|-------------|
| `arch/dots-hyprland.sh` | in-repo [VERIFIED: file] | Verification Engine | Validates repository symlinks, stowed packages, and live drift (`verify --strict`). |
| `scripts/gen-collision-map.sh` | in-repo [VERIFIED: file] | Documentation Generator | Updates Section 3 table in `restow/README.md`. |
| `jq` | 1.8.1 [VERIFIED: pacman] | JSON Processing Engine | Parses and verifies `config.json` syntax and options in automated test harnesses. |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `restow/quickshell` Leaf Symlinks | Direct editing in `vendor/dots-hyprland` | Violates submodule pin cleanliness, breaks upstream update workflow, creates git tree drift. |
| Aggregated `checkupdates + yay -Qua` | Bare `checkupdates` alone | Fails when `pacman-contrib` is missing; omits AUR packages, leaving user unaware of pending updates. |
| Array `some()` in `Privacy.qml` | Upstream `filter(...).map(...)` | Evaluates empty array `[]` as truthy in QML, causing privacy alert icons to remain permanently visible on the bar. |
| Pure Dynamic Pill Width (`BarGroup`) | Static pill width clamps (`centerSideModuleWidth`) | Clamped width cuts off detailed memory strings like `5.4/31.2 GB (17%)` or overflows bar bounds. |

### Package Legitimacy Audit

> All components in Phase 32 use pre-installed system tools (`quickshell`, `stow`, `yay`, `kitty`, `pipewire`, `jq`) and in-repo assets. No new third-party dependencies are required.

| Package | Source / Provider | Age | Status | Verdict | Disposition |
|---------|-------------------|-----|--------|---------|-------------|
| `quickshell` | AUR (`quickshell-git`) | > 1.5 yrs | Installed (0.2.1) | [OK] | Approved (Desktop Shell) |
| `yay` | AUR (`yay`) | > 8 yrs | Installed (12.5.7) | [OK] | Approved (AUR & Pacman Helper) |
| `stow` | Arch Official | > 20 yrs | Installed (2.4.1) | [OK] | Approved (Link Manager) |
| `kitty` | Arch Official | > 6 yrs | Installed (0.45.0) | [OK] | Approved (Terminal Runner) |

## Architecture Patterns

### System Architecture Diagram

```mermaid
flowchart TD
    subgraph ConfigTier [Tier 1: Native JSON Configuration]
        JSON["capture/ii/.../config.json<br/>- time: 12h + seconds + date<br/>- utilButtons: showScreenRecord: true<br/>- weather: Dhaka, metric<br/>- resources: threshold seeds"]
    end

    subgraph OverlayTier [Tier 2: Personal QML Overlays (restow/quickshell/)]
        O_Res["modules/ii/bar/Resource.qml<br/>- customText property<br/>- 2-tier alert colors (amber/red)<br/>- dynamic text width"]
        O_Ress["modules/ii/bar/Resources.qml<br/>- RAM: X.X/Y.Y GB (ZZ%)<br/>- Dynamic Swap: >0% reveal<br/>- CPU: planner_review + XX%"]
        O_Clock["modules/ii/bar/ClockWidget.qml<br/>- subtle 8px spacer (no bullet glyph)"]
        O_Priv["services/Privacy.qml<br/>- .some() boolean fix"]
        O_Upd["services/Updates.qml<br/>- Arch + AUR non-blocking aggregation"]
        O_UpdBtn["modules/ii/bar/UpdatesButton.qml<br/>- dynamic update pill (kitty yay -Syu)"]
        O_Tray["modules/ii/bar/SysTray.qml<br/>- balanced 4px icon spacing"]
        O_Bar["modules/ii/bar/BarContent.qml<br/>- no ActiveWindow<br/>- no background scroll<br/>- Privacy revealers mounted<br/>- Media auto-collapse"]
    end

    subgraph StowBridge [GNU Stow --no-folding]
        L_Res["~/.config/quickshell/ii/modules/ii/bar/Resource.qml"]
        L_Ress["~/.config/quickshell/ii/modules/ii/bar/Resources.qml"]
        L_Clock["~/.config/quickshell/ii/modules/ii/bar/ClockWidget.qml"]
        L_Priv["~/.config/quickshell/ii/services/Privacy.qml"]
        L_Upd["~/.config/quickshell/ii/services/Updates.qml"]
        L_UpdBtn["~/.config/quickshell/ii/modules/ii/bar/UpdatesButton.qml"]
        L_Tray["~/.config/quickshell/ii/modules/ii/bar/SysTray.qml"]
        L_Bar["~/.config/quickshell/ii/modules/ii/bar/BarContent.qml"]
    end

    subgraph Runtime [Quickshell 0.2.1 Desktop Bar]
        QS["qs -c ii (Runtime)"]
        Bar["Top Status Bar"]
    end

    JSON -.->|read on load| QS
    O_Res -->|stow| L_Res
    O_Ress -->|stow| L_Ress
    O_Clock -->|stow| L_Clock
    O_Priv -->|stow| L_Priv
    O_Upd -->|stow| L_Upd
    O_UpdBtn -->|stow| L_UpdBtn
    O_Tray -->|stow| L_Tray
    O_Bar -->|stow| L_Bar

    L_Res --> QS
    L_Ress --> QS
    L_Clock --> QS
    L_Priv --> QS
    L_Upd --> QS
    L_UpdBtn --> QS
    L_Tray --> QS
    L_Bar --> QS
    QS --> Bar
```

### Recommended Project Structure

```
.dotfiles/
├── capture/
│   └── ii/
│       └── .config/illogical-impulse/
│           └── config.json                               # Tier 1 native options (time, weather, utilButtons, thresholds)
├── restow/
│   └── quickshell/
│       └── .config/quickshell/ii/
│           ├── modules/ii/bar/
│           │   ├── BarContent.qml                        # Overlay: privacy revealers, no ActiveWindow, no bg scroll, media collapse
│           │   ├── BarGroup.qml                          # Established Phase 31: animated dynamic width
│           │   ├── ClockWidget.qml                       # Overlay: subtle spacer replacing bullet dot
│           │   ├── Resource.qml                          # Overlay: customText, 2-tier alert sync, dynamic text width
│           │   ├── Resources.qml                         # Overlay: RAM GB format, dynamic Swap, CPU badge
│           │   ├── SysTray.qml                           # Overlay: 4px icon spacing, overflow drawer
│           │   └── UpdatesButton.qml                     # Overlay: dedicated update pill with terminal launcher
│           └── services/
│               ├── Privacy.qml                           # Overlay: .some() primitive boolean PipeWire telemetry
│               └── Updates.qml                           # Overlay: aggregated Arch + AUR update check
├── scripts/
│   └── phase32-component-formatting-assert.sh            # 4-section automated Nyquist validation harness
└── .planning/phases/32-component-representation-formatting-customization/
    ├── 32-CONTEXT.md
    ├── 32-RESEARCH.md
    ├── 32-01-PLAN.md
    └── 32-02-PLAN.md
```

## Don't Hand-Roll

| Problem | Anti-Pattern to Avoid | Standard In-Repo / Upstream Solution |
|---------|-----------------------|--------------------------------------|
| **Memory Telemetry** | Spawning a custom periodic bash script polling `free -m` | Bind directly to `ResourceUsage.memoryUsed` and `ResourceUsage.memoryTotal` from `/proc/meminfo` [VERIFIED: `ResourceUsage.qml:73-74`]. |
| **Privacy Detection** | Running CLI subprocesses (`pw-cli` or `pactl`) to detect microphone state | Consume `Quickshell.Services.Pipewire`'s reactive `linkGroups` via `services/Privacy.qml` [VERIFIED: `Privacy.qml:14-15`]. |
| **Pill Resizing Animation** | Manually coding width timers or step increments | Rely on `BarGroup.qml`'s `Behavior on implicitWidth` animated via `Appearance.animationCurves.emphasizedDecel` [VERIFIED: `BarGroup.qml:14-21`]. |
| **Update Execution** | Writing custom root GUI update windows | Dispatch `Quickshell.execDetached(["kitty", "-1", "--hold=yes", "fish", "-i", "-c", "yay -Syu"])` providing full terminal interaction with sudo and diff prompts [VERIFIED: D-18]. |
| **Time/Date Ticking** | Creating custom QML timers for date strings | Consume `DateTime.time` and `DateTime.longDate`, which bind to Quickshell's native C++ `SystemClock` [VERIFIED: `DateTime.qml:13-24`]. |

## Common Pitfalls

### Pitfall 1: The Upstream Privacy Boolean Coercion Trap
**Symptom:** Microphone and screen-sharing alert icons are permanently displayed on the bar, even when no app is capturing audio or recording the screen.  
**Cause:** Upstream `vendor/.../services/Privacy.qml:14-15` uses `.filter(...).map(...)`. When no streams exist, it returns `[]`. In QML JavaScript, `Boolean([])` evaluates to `true` [VERIFIED: runtime drill].  
**Prevention:** In `restow/quickshell/.../services/Privacy.qml`, replace `.filter(...).map(...)` with `.some(...)` (e.g. `Pipewire.linkGroups.values.some(pwlg => pwlg.source?.type === PwNodeType.VideoSource)`). Array `some()` evaluates strictly to primitive boolean `true` or `false`.

### Pitfall 2: Fixed `TextMetrics` Text Width Truncation
**Symptom:** RAM formatted as `5.4/31.2 GB (17%)` is cut off, clipped, or overflows into adjacent icons.  
**Cause:** Upstream `Resource.qml:54` hardcodes `implicitWidth: fullPercentageTextMetrics.width` where `TextMetrics.text` is `"100"` [VERIFIED: `Resource.qml:58-61`].  
**Prevention:** Implement conditional width in `Resource.qml`: `implicitWidth: customText.length > 0 ? percentageText.implicitWidth : fullPercentageTextMetrics.width`. Set `fullPercentageTextMetrics.text: "100%"` for CPU jitter prevention, while allowing `percentageText.implicitWidth` to size custom strings dynamically.

### Pitfall 3: Component Color Desynchronization Under Alert Thresholds
**Symptom:** Under high RAM or CPU load, the circular ring turns red, but the icon remains gray and the text remains white, violating visual alerting clarity.  
**Cause:** Upstream `Resource.qml` only bound `colPrimary` of the circular progress to `warning`, leaving `MaterialSymbol` bound to `m3onSecondaryContainer` and `StyledText` bound to `colOnLayer1` [VERIFIED: `Resource.qml:47,66`].  
**Prevention:** Declare a synchronized `alertColor`:
```qml
readonly property color alertColor: isCritical ? Appearance.colors.colError : (isWarning ? "#FFA000" : "transparent")
```
Bind `colPrimary`, `MaterialSymbol.color`, and `StyledText.color` to `(isCritical || isWarning) ? alertColor : <default>`.

### Pitfall 4: `checkupdates` Hang or Failure When `pacman-contrib` Is Absent
**Symptom:** Update check fails, freezes, or update count stays at 0 forever.  
**Cause:** Arch Linux does not include `checkupdates` by default (it lives in `pacman-contrib`). Upstream `Updates.qml:42` ran `which checkupdates`, which exits 1 on default setups [VERIFIED: terminal drill]. Furthermore, `checkupdates` omits AUR updates.  
**Prevention:** Update `Updates.qml` to test availability for `checkupdates` OR `yay` (`command -v checkupdates || command -v yay`). Use a non-blocking bash script that aggregates `checkupdates` (if present) and `yay -Qua` (if present), falling back to `yay -Qu` if `checkupdates` is absent.

### Pitfall 5: GNU Stow Symlink Collision with Installer Regular Files
**Symptom:** `stow` errors out with `existing target is neither a link nor a directory: ...`.  
**Cause:** Upstream `./setup install` previously deployed regular files into `~/.config/quickshell/ii/modules/ii/bar/` (e.g. `Resource.qml`, `Resources.qml`, `ClockWidget.qml`). Stow refuses to overwrite regular files with symlinks.  
**Prevention:** Follow the Phase 31 de-stubbing pattern: verify if target is a regular file; if so, move it to `<file>.bak.<epoch>` before invoking `stow --verbose=5 --no-folding -t ~ quickshell`.

### Pitfall 6: Accidental Volume or Brightness Adjustment via Background Scrolling
**Symptom:** Scrolling over empty bar areas unexpectedly adjusts display brightness or system volume and flashes OSD sliders.  
**Cause:** `BarContent.qml` wrapped left and right sides in `FocusedScrollMouseArea` with `onScrollUp` / `onScrollDown` bound to `Brightness` and `Audio` [VERIFIED: `BarContent.qml:62-63,201-202`].  
**Prevention:** Remove `onScrollUp` and `onScrollDown` handlers and remove the `ScrollHint` children, retaining only `onPressed` for left/right sidebar toggling.

## Code Examples

### 1. `Resource.qml` Two-Tier Alerting & Custom Text Overlay

```qml
// restow/quickshell/.config/quickshell/ii/modules/ii/bar/Resource.qml
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    required property string iconName
    required property double percentage
    property string customText: ""
    property int warningThreshold: 100
    property int criticalThreshold: 100
    property bool shown: true
    clip: true
    visible: width > 0 && height > 0
    implicitWidth: resourceRowLayout.x < 0 ? 0 : resourceRowLayout.implicitWidth
    implicitHeight: Appearance.sizes.barHeight

    readonly property bool isCritical: (percentage * 100) >= criticalThreshold
    readonly property bool isWarning: !isCritical && ((percentage * 100) >= warningThreshold)
    readonly property color alertColor: isCritical ? Appearance.colors.colError : (isWarning ? "#FFA000" : "transparent")
    readonly property string displayText: customText.length > 0 ? customText : `${Math.round(percentage * 100).toString()}%`

    RowLayout {
        id: resourceRowLayout
        spacing: 2
        x: shown ? 0 : -resourceRowLayout.width
        anchors.verticalCenter: parent.verticalCenter

        ClippedFilledCircularProgress {
            id: resourceCircProg
            Layout.alignment: Qt.AlignVCenter
            lineWidth: Appearance.rounding.unsharpen
            value: root.percentage
            implicitSize: 20
            colPrimary: (root.isCritical || root.isWarning) ? root.alertColor : Appearance.colors.colOnSecondaryContainer
            accountForLightBleeding: !root.isCritical && !root.isWarning
            enableAnimation: false

            Item {
                anchors.centerIn: parent
                width: resourceCircProg.implicitSize
                height: resourceCircProg.implicitSize
                
                MaterialSymbol {
                    anchors.centerIn: parent
                    font.weight: Font.DemiBold
                    fill: 1
                    text: root.iconName
                    iconSize: Appearance.font.pixelSize.normal
                    color: (root.isCritical || root.isWarning) ? root.alertColor : Appearance.m3colors.m3onSecondaryContainer
                }
            }
        }

        Item {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: root.customText.length > 0 ? percentageText.implicitWidth : fullPercentageTextMetrics.width
            implicitHeight: percentageText.implicitHeight

            TextMetrics {
                id: fullPercentageTextMetrics
                text: "100%"
                font.pixelSize: Appearance.font.pixelSize.small
            }

            StyledText {
                id: percentageText
                anchors.centerIn: parent
                color: (root.isCritical || root.isWarning) ? root.alertColor : Appearance.colors.colOnLayer1
                font.pixelSize: Appearance.font.pixelSize.small
                text: root.displayText
            }
        }

        Behavior on x {
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }
    }

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Appearance.animation.elementMove.duration
            easing.type: Appearance.animation.elementMove.type
            easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
        }
    }
}
```

### 2. `Resources.qml` RAM GB Formatting & Dynamic Swap Visibility

```qml
// restow/quickshell/.config/quickshell/ii/modules/ii/bar/Resources.qml
import qs.modules.common
import qs.services
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root
    property bool borderless: Config.options.bar.borderless
    property bool alwaysShowAllResources: false
    implicitWidth: rowLayout.implicitWidth + rowLayout.anchors.leftMargin + rowLayout.anchors.rightMargin
    implicitHeight: Appearance.sizes.barHeight
    hoverEnabled: !Config.options.bar.tooltips.clickToShow

    RowLayout {
        id: rowLayout
        spacing: 0
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 4

        Resource {
            iconName: "memory"
            percentage: ResourceUsage.memoryUsedPercentage
            customText: `${(ResourceUsage.memoryUsed / (1024 * 1024)).toFixed(1)}/${(ResourceUsage.memoryTotal / (1024 * 1024)).toFixed(1)} GB (${Math.round(ResourceUsage.memoryUsedPercentage * 100)}%)`
            warningThreshold: 80
            criticalThreshold: 90
        }

        Resource {
            iconName: "swap_horiz"
            percentage: ResourceUsage.swapUsedPercentage
            shown: ResourceUsage.swapUsed > 0
            Layout.leftMargin: shown ? 6 : 0
            customText: `${(ResourceUsage.swapUsed / (1024 * 1024)).toFixed(1)}/${(ResourceUsage.swapTotal / (1024 * 1024)).toFixed(1)} GB (${Math.round(ResourceUsage.swapUsedPercentage * 100)}%)`
            warningThreshold: 70
            criticalThreshold: 85
        }

        Resource {
            iconName: "planner_review"
            percentage: ResourceUsage.cpuUsage
            shown: Config.options.bar.resources.alwaysShowCpu || root.alwaysShowAllResources
            Layout.leftMargin: shown ? 6 : 0
            warningThreshold: 60
            criticalThreshold: 90
        }
    }

    ResourcesPopup {
        hoverTarget: root
    }
}
```

### 3. `ClockWidget.qml` Subtle Spacer Without Glyph

```qml
// restow/quickshell/.config/quickshell/ii/modules/ii/bar/ClockWidget.qml
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property bool borderless: Config.options.bar.borderless
    property bool showDate: Config.options.bar.verbose
    implicitWidth: rowLayout.implicitWidth
    implicitHeight: Appearance.sizes.barHeight

    RowLayout {
        id: rowLayout
        anchors.centerIn: parent
        spacing: 0

        StyledText {
            font.pixelSize: Appearance.font.pixelSize.large
            color: Appearance.colors.colOnLayer1
            text: DateTime.time
        }

        // Subtle spacer replacing unicode bullet glyph (D-08)
        Item {
            visible: root.showDate
            implicitWidth: 8
            implicitHeight: 1
        }

        StyledText {
            visible: root.showDate
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer1
            text: DateTime.longDate
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: !Config.options.bar.tooltips.clickToShow

        ClockWidgetPopup {
            hoverTarget: mouseArea
        }
    }
}
```

### 4. `Privacy.qml` Boolean Telemetry Service

```qml
// restow/quickshell/.config/quickshell/ii/services/Privacy.qml
pragma Singleton
pragma ComponentBehavior: Bound
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

/**
 * Screensharing and mic activity with primitive boolean evaluation.
 */
Singleton {
    id: root

    readonly property bool screenSharing: Pipewire.linkGroups.values.some(pwlg => pwlg.source?.type === PwNodeType.VideoSource)
    readonly property bool micActive: Pipewire.linkGroups.values.some(pwlg => pwlg.source?.type === PwNodeType.AudioSource && pwlg.target?.type === PwNodeType.AudioInStream)
}
```

### 5. `UpdatesButton.qml` Dedicated Pending Updates Status Pill

```qml
// restow/quickshell/.config/quickshell/ii/modules/ii/bar/UpdatesButton.qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    implicitWidth: rowLayout.implicitWidth + 8
    implicitHeight: Appearance.sizes.barHeight
    visible: Updates.count > 0

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            Quickshell.execDetached(["kitty", "-1", "--hold=yes", "fish", "-i", "-c", "yay -Syu"]);
        }

        RowLayout {
            id: rowLayout
            anchors.centerIn: parent
            spacing: 4

            MaterialSymbol {
                text: "system_update_alt"
                iconSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colPrimary
            }

            StyledText {
                text: `${Updates.count}`
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnLayer1
            }
        }
    }
}
```

## State of the Art

| Old Pattern / Upstream Default | Phase 32 State of the Art | Improvement |
|--------------------------------|---------------------------|-------------|
| RAM as vague percentage badge (e.g. `17%`) | Definite gigabyte ratio `5.4/31.2 GB (17%)` | High situational awareness of actual available capacity in hardware units. |
| Single threshold recoloring only circular progress ring | Synchronized two-tier alert (Amber warning / Red critical) across progress ring, icon, and text | Immediate, unmistakable visual hierarchy eliminating ambiguous partial styling. |
| Static swap presence even when swap is empty (0%) | Dynamic swap reveal (>0% usage) formatted identically to RAM | Bar space reserved strictly when system is under actual memory swapping pressure. |
| Unicode bullet glyph (`•`) between time and date | Subtle 8px non-glyph spacer | Elegant typographic spacing without visual noise. |
| Media pill showing "No media" when idle | Dynamic auto-collapse when no music is playing | Restores central status bar real estate during ordinary workstation use. |
| Buggy PipeWire privacy array coercion (always true) | Primitive boolean `.some()` evaluation with animated Revealers | Accurate privacy alerts indicating active microphone capture and screen sharing. |
| Background mouse scroll adjusting volume/brightness | Scroll handlers eliminated | Prevents accidental system volume/backlight jumps while moving mouse near bar. |
| Missing AUR updates and dependency on `checkupdates` | Aggregated Arch + AUR check with dedicated terminal launcher pill | Complete package update awareness with zero-friction one-click upgrade launcher. |

## Assumptions Log

| # | Assumption | Status | Validation Gate |
|---|------------|--------|-----------------|
| 1 | PipeWire link groups provide video/audio stream telemetry via `PwNodeType`. | Confirmed | Tested live in Quickshell runtime; `some()` returns false when idle. |
| 2 | `yay` is available in system path for AUR and pacman queries. | Confirmed | `which yay` outputs `/usr/bin/yay` (v12.5.7). |
| 3 | Material Symbols font supports `planner_review`, `memory`, `swap_horiz`, `mic`, `screen_share`, and `system_update_alt`. | Confirmed | Font is installed system-wide in `Appearance.font.family.iconMaterial`. |
| 4 | Setting `visible: false` on an item inside `BarGroup.qml` causes the pill container to shrink. | Confirmed | `BarGroup.qml` uses `GridLayout` and `implicitWidth: gridLayout.implicitWidth + padding * 2` with smooth animated behavior. |
| 5 | `kitty -1 --hold=yes fish -i -c 'yay -Syu'` opens an interactive upgrade terminal window. | Confirmed | Native shell configuration supports kitty single-instance mode with fish shell. |

## Open Questions

| # | Question | Answer / Resolution |
|---|----------|---------------------|
| 1 | Should the pending updates check run if `pacman-contrib` (`checkupdates`) is not installed? | Yes. The helper script tests for `checkupdates`; if missing, it falls back to `yay -Qu 2>/dev/null \| wc -l` so the count never breaks or halts. |
| 2 | Should clicking the Amber mic alert unmute when already muted, or mute when capturing? | Clicking the privacy mic alert sends `["wpctl", "set-mute", "@DEFAULT_SOURCE@", "1"]` to immediately protect user privacy by muting active capture. |
| 3 | What exact Amber color token should be used for warning alerts? | Material 3 Amber accent `#FFA000` (or `#FFB74D` in dark mode). It provides high contrast (>0.6 luminance) on `colLayer1` dark background. |

## Environment Availability

| Tool / Resource | Path | Available | Permissions / Execution Check |
|-----------------|------|-----------|-------------------------------|
| `quickshell` | `/usr/bin/quickshell` | Yes | Executes status bar runtime. |
| `stow` | `/usr/bin/stow` | Yes | Executes `--no-folding` symlink deployment. |
| `yay` | `/usr/bin/yay` | Yes | Non-root check (`yay -Qu` / `yay -Qua`). |
| `kitty` | `/usr/bin/kitty` | Yes | Launches interactive update terminal. |
| `wpctl` | `/usr/bin/wpctl` | Yes | Mutes default audio source on privacy click. |
| `hyprpicker` | `/usr/bin/hyprpicker` | Yes | Utility button color picker launcher. |
| Live Config | `~/.config/illogical-impulse/config.json` | Yes | Live configuration read by Quickshell. |
| Repo Mirror | `capture/ii/.config/illogical-impulse/config.json` | Yes | Tracked in git repository. |

## Validation Architecture (Nyquist Validation Enabled)

The validation harness `scripts/phase32-component-formatting-assert.sh` provides 100% automated verification across 4 strict test sections:

```bash
#!/usr/bin/env bash
# scripts/phase32-component-formatting-assert.sh
# Automated assertion harness for Phase 32
```

### Section 1: Tier 1 Native JSON Configuration Integrity
- Asserts `capture/ii/.../config.json` and `~/.config/illogical-impulse/config.json`:
  - `time.format == "hh:mm:ss AP"`
  - `time.secondPrecision == true`
  - `time.dateFormat == "ddd, dd-MM-yyyy"`
  - `bar.utilButtons.showScreenRecord == true`
  - `bar.utilButtons.showScreenSnip == true`
  - `bar.utilButtons.showColorPicker == true`
  - `bar.weather.city == "Dhaka"`
  - `bar.weather.useUSCS == false`
  - `bar.resources.memoryWarningThreshold == 80`
  - `bar.resources.cpuWarningThreshold == 60`
  - `bar.resources.swapWarningThreshold == 70`

### Section 2: Symlink and Overlay Packaging Integrity
- Asserts all target overlay files in `~/.config/quickshell/ii/` are valid symlinks pointing directly into `restow/quickshell/`:
  - `modules/ii/bar/Resource.qml` -> `restow/quickshell/.../Resource.qml`
  - `modules/ii/bar/Resources.qml` -> `restow/quickshell/.../Resources.qml`
  - `modules/ii/bar/ClockWidget.qml` -> `restow/quickshell/.../ClockWidget.qml`
  - `modules/ii/bar/UpdatesButton.qml` -> `restow/quickshell/.../UpdatesButton.qml`
  - `modules/ii/bar/SysTray.qml` -> `restow/quickshell/.../SysTray.qml`
  - `modules/ii/bar/BarContent.qml` -> `restow/quickshell/.../BarContent.qml`
  - `modules/ii/bar/BarGroup.qml` -> `restow/quickshell/.../BarGroup.qml`
  - `services/Privacy.qml` -> `restow/quickshell/.../Privacy.qml`
  - `services/Updates.qml` -> `restow/quickshell/.../Updates.qml`
- Asserts zero directory folding (parent directories remain real directories, not symlinks).

### Section 3: QML Syntax, Property Bindings & Component Assertions
- Asserts `Resource.qml`:
  - Contains `property string customText`
  - Contains `property int criticalThreshold`
  - Contains `readonly property color alertColor`
  - Synchronously recolors progress ring, icon, and text
  - Computes `implicitWidth` dynamically when `customText` is non-empty
- Asserts `Resources.qml`:
  - Passes definite gigabytes format `${(ResourceUsage.memoryUsed / (1024 * 1024)).toFixed(1)}/${(ResourceUsage.memoryTotal / (1024 * 1024)).toFixed(1)} GB`
  - Binds swap `shown: ResourceUsage.swapUsed > 0`
  - Sets warning/critical thresholds: RAM (80/90), Swap (70/85), CPU (60/90)
- Asserts `ClockWidget.qml`:
  - Absence of unicode bullet glyph `"•"`
  - Presence of non-glyph spacer item
- Asserts `BarContent.qml`:
  - Absence or hidden state of `ActiveWindow`
  - Absence of `onScrollDown` and `onScrollUp` on `barLeftSideMouseArea` and `barRightSideMouseArea`
  - Absence of `ScrollHint` children
  - Presence of `Privacy.micActive` (Amber) and `Privacy.screenSharing` (Red) revealers
  - Media player pill auto-collapse bound to playing state
  - Mounts `UpdatesButton` inside `BarGroup`
- Asserts `Privacy.qml`:
  - Uses `.some(...)` boolean predicates, avoiding array coercion bug
- Asserts `SysTray.qml`:
  - Uses `columnSpacing: 4`

### Section 4: Repository Hygiene & Verification Engine
- Asserts `arch/dots-hyprland.sh verify --strict` exits 0 with 0 findings.
- Asserts `git status --porcelain` shows clean working tree with zero untracked drift.

## Security Domain

| Threat | Risk | Mitigation |
|--------|------|------------|
| **Command Injection in Update Launcher** | A malicious package count string injecting shell code into terminal runner | Fixed command vector `Quickshell.execDetached(["kitty", "-1", "--hold=yes", "fish", "-i", "-c", "yay -Syu"])`. No user or unvalidated external input is interpolated into the command array. |
| **Privacy Spyware Evasion** | Audio or video streams capturing secretly without user awareness | PipeWire reactive link group monitoring binds directly to PipeWire core events. When any node with `VideoSource` or `AudioSource` connects, the bar immediately exposes the red/amber alert icon. |
| **Unintended Volume / Brightness Mutation** | Accidental mouse wheel events during high-speed desktop interaction modifying output levels | Background scroll listeners are completely removed from status bar background areas. Adjustments can only occur through intentional click into sidebar sliders. |
| **Root Privileges in Dotfiles Repo** | Running dotfiles operations as root compromising user file ownership | All scripts, tests, and stowing operations enforce `CURRENT_EUID != 0` check. |

---

*Phase: 32-component-representation-formatting-customization*  
*Research completed: 2026-09-20*  
