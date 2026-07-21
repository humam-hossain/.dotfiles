---
status: diagnosed
gap_id: G-01-1
phase: 01-shell-foundation-theme
created: 2026-07-21T12:25:00Z
---

# Debug: Bar visible but icons missing / text overlapping / design inconsistent

## Symptoms

- Bar layer loads (`Configuration Loaded`, bar visible)
- User: "lots of image missing, text overlapping, design is not consistent"
- Logs:
  - `Cannot assign to non-existent property "m3primaryDim"`
  - `Unable to assign [undefined] to double` @ `BarContent.qml:134`
  - `Could not load icon "image-missing"` (repeated)
  - `TypeError: Cannot read property 'enable' of undefined` @ `NotificationPopup.qml:17`
  - `Unable to assign [undefined] to QQuickItem*` @ `ToolbarTabBar.qml:59`
  - `Invalid dispatcher` for `hl.dsp.focus({workspace = 2})`

## Investigation

### Fonts (primary)

| Config family | Installed? |
|---------------|------------|
| Google Sans Flex | **No** (`fc-list` count 0) |
| Material Symbols Rounded | **No** |
| Readex Pro | **No** |
| Space Grotesk | **No** |
| JetBrains Mono NF | **No** (installed as `JetBrainsMono Nerd Font`) |

- `Appearance.font.family.iconMaterial` hardcodes `"Material Symbols Rounded"`
- Material bar icons are **font glyphs** via `MaterialSymbol.qml`, not PNG assets
- `arch/fonts.sh` installs Font Awesome, JetBrains Mono Nerd, Noto — **not** Material Symbols or Google Sans Flex
- `arch/quickshell.sh` PACKAGES also omit font deps

Missing Material Symbols → empty/missing-looking icons. Missing UI fonts → wrong metrics → overlapping text / inconsistent design.

### BarContent padding (layout)

`BarContent.qml:134`:

```qml
padding: workspacesWidget.widgetPadding
```

`Workspaces.qml` defines many size properties but **no** `widgetPadding` → assigns `undefined` to `BarGroup.padding` (typed `real`).

### Config key skew (notifications)

- `NotificationPopup.qml` / settings UI: `Config.options.notifications.forceMonitor.enable`
- `Config.qml`: `notifications.monitor.enable` (not `forceMonitor`)

→ `forceMonitor` is undefined → TypeError on `.enable`.

### Workspace dispatch

`Workspaces.qml` uses `Hyprland.dispatch('hl.dsp.focus({workspace = N})')`.

- `hyprctl plugin list` → **no plugins loaded**
- Stock Hyprland 0.55 has no `hl.dsp.focus` dispatcher → every workspace click logs `Invalid dispatcher`

### Theme token map (non-fatal)

`colors.json` includes `primary_dim`, `secondary_dim`, etc. `Appearance.m3colors` lacks matching `m3*Dim` / palette-key properties. `MaterialThemeLoader.applyColors` assigns blindly → warnings only; user confirmed Material colors **do** look applied.

### image-missing icon

`AppSearch.guessIcon` / workspace app icons fall back to FreeDesktop name `"image-missing"`. That icon is not in the active icon theme → repeated load warnings. Secondary to missing Material Symbols for shell chrome icons.

## Root Cause

**Primary:** Runtime font dependencies for the wholesale ii shell were never provisioned. Without Material Symbols Rounded and the configured UI fonts, the bar cannot render its intended iconography or typography — manifests as missing images, overlapping text, and inconsistent design.

**Contributing defects in the vendored tree / host integration:**

1. `Workspaces.widgetPadding` referenced but never defined → broken center-group padding
2. `forceMonitor` vs `monitor` Config key mismatch → notification popup TypeError
3. `hl.dsp.focus` requires a Hyprland plugin not installed → workspace focus broken
4. Incomplete `Appearance.m3colors` property set vs generator output (warnings only)

## Files Involved

| File | Issue |
|------|-------|
| `arch/fonts.sh` / `arch/quickshell.sh` | Missing Material Symbols (+ UI font) packages |
| `modules/common/Config.qml` | Default font families not available on system; `monitor` not `forceMonitor` |
| `modules/common/Appearance.qml` | Hardcoded Material Symbols; missing m3*Dim props |
| `modules/ii/bar/BarContent.qml` | `workspacesWidget.widgetPadding` undefined |
| `modules/ii/bar/Workspaces.qml` | Missing `widgetPadding`; invalid `hl.dsp.focus` dispatch |
| `modules/ii/notificationPopup/NotificationPopup.qml` | Reads non-existent `forceMonitor` |

## Recommended Fix Direction

1. Install `ttf-material-symbols-variable` (and optional UI fonts or Config fallbacks to installed families: Noto Sans / JetBrainsMono Nerd Font).
2. Define `widgetPadding` on Workspaces (or use literal/default in BarContent).
3. Align Config + consumers on one notifications monitor key.
4. Replace `hl.dsp.focus` with stock `workspace` dispatcher (or document/install plugin).
5. Optionally declare missing m3*Dim properties on Appearance.m3colors.
