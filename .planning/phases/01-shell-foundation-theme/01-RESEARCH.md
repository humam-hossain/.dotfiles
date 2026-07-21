<Phase 1 Research: Shell Foundation & Theme>
**Researched:** 2026-07-21
**Status:** Complete

## Executive Summary
The goal of this phase is to establish the Quickshell desktop shell foundation by adopting the `dots-hyprland` `ii` architecture wholesale. This includes mirroring the directory structure (`modules/`, `panelFamilies/`, `services/`, `scripts/`, etc.), setting up the `shell.qml` entry point with the `PanelLoader` mechanism, porting all singletons (including unused ones to preserve fidelity), and implementing the Material Theme system driven by static color generation. The symlink deploy method in `arch/quickshell.sh` will provide live updates from the dotfiles repo.

## Technical Analysis

### Architecture
- **Entry Point (`shell.qml`)**: Bootstraps the application, calls `MaterialThemeLoader.reapplyTheme()` and loads active features and background services (like Hyprsunset, Cliphist). It uses `PanelFamilyLoader` (a wrapper around `LazyLoader`) to dynamically load the active panel family (e.g., `IllogicalImpulseFamily`).
- **Panel Families**: Located in `panelFamilies/`, they define the bar layouts and specific screen components. The shell applies these to all connected monitors (e.g., DP-1, HDMI-A-2).
- **Service Singletons**: Located in `services/`. Each is a QML singleton registered via `qmldir`. They handle system interaction, state management, and backend logic, exposing properties for widgets to consume.
- **Theme System**: Instead of dynamic wallpaper extraction, a static Material color palette is generated once by a Python script (`scripts/colors/generate_colors_material.py` using `materialyoucolor`). `MaterialThemeLoader.qml` reads this JSON via `FileView`, mapping properties to `Appearance.m3colors`.

### Dependencies
- **Core Environment**: `quickshell`, `qt6-wayland`, `qt6-declarative`, `hyprland`
- **Theme Generation**: Python `materialyoucolor` library to generate the material JSON.
- **Provisioning**: `arch/quickshell.sh` which installs packages and symlinks `$REPO_ROOT/.config/quickshell` to `$HOME/.config/quickshell`.

### Existing Patterns
- **Wholesale Copy-Paste**: We are adopting `dots-hyprland` almost exactly. Unused services (AI, Booru, SongRec) remain as dead code to ensure maximum compatibility and avoid cascading errors.
- **`qmldir` Manifests**: Every directory contains a `qmldir` file that explicitly binds QML files to namespaces and designates Singletons.
- **Symlink Deploy**: The provisioning script uses `ln -s` rather than copying files, meaning edits inside the git repository are immediately live in the system configuration.

### Risk Areas
- **`ddcutil` iGPU Hangs**: A documented crash (iGPU flickering/hang) was caused by `ddcutil` polling. It's critical to ensure any Brightness or Backlight widgets do not actively poll `ddcutil`.
- **Python Script Dependencies**: `generate_colors_material.py` requires `materialyoucolor`. If missing, the theme generation fails, leading to an unthemed/invisible shell.
- **Dead Services Triggering Hard Errors**: Some dead services might invoke missing executables (like `ydotool` or APIs). We must fix *only* hard errors that prevent Quickshell from starting.

## Implementation Approach
1. **Directory Setup**: Create `.config/quickshell/` and copy the entire `ii` structure from `../dots-hyprland/dots/.config/quickshell/ii/`.
2. **Seed Color Selection**: Pick a default static seed color (e.g., a dark vibrant hex) and integrate the Python script call in the build/provisioning process (or generate the JSON manually for Phase 1) to populate `~/.cache/quickshell/material_colors.json` or its equivalent path.
3. **Entry Point Integration**: Ensure `shell.qml` correctly targets the `ii` panel family and resolves all `qmldir` modules properly.
4. **Symlink Deployment**: Ensure `arch/quickshell.sh` accurately symlinks the directory (it already does, but double check it creates the right path).
5. **Fix Hard Errors**: Run `quickshell`. Monitor logs. If an import fails or a missing dependency causes a hard crash, patch it minimally.

## Validation Architecture
- **Startup**: Execute `quickshell` from the terminal.
- **Visual Rendering**: A top bar must appear on every connected monitor (`DP-1` and `HDMI-A-2`).
- **Theme Delivery**: The Material color scheme (dark mode) must be visibly applied, proving that `MaterialThemeLoader` successfully read the generated JSON and populated `Appearance.m3colors`.
- **Service Verification**: At least one singleton (e.g., `DateTime.qml` rendering the clock or `HyprlandData.qml` rendering workspaces) must visibly work, proving the pattern is functional.
- **Graceful Failures**: The shell should stay running despite missing backends for "dead" services.

## Key Files
- `.config/quickshell/shell.qml` — The application entry point.
- `.config/quickshell/services/MaterialThemeLoader.qml` — Theme loader singleton.
- `.config/quickshell/modules/common/Appearance.qml` — Theme token registry.
- `.config/quickshell/scripts/colors/generate_colors_material.py` — The color generation script.
- `arch/quickshell.sh` — The deployment script.
- `.config/quickshell/**/qmldir` — Module manifests critical for QML resolution.

## RESEARCH COMPLETE
</Phase 1 Research: Shell Foundation & Theme>
