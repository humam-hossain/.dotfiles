# Directory Structure & Module Boundaries (arch)

This document describes the directory structure, component organization, and module boundaries for the `arch/` focus area within the dotfiles repository.

## Directory Layout

The `arch/` directory is the core of the Arch Linux setup and configuration process. It contains bash scripts responsible for installing packages, handling system configuration, and linking dotfiles.

```text
arch/
├── README.md               # Arch installation documentation and bootloader guide
├── dots-hyprland.sh        # Core wrapper script for vendor/dots-hyprland setup
├── hyprland.sh             # Hyprland session and baseline environment setup
├── waybar.sh               # Custom deployment script for Waybar
├── * .sh                   # Specialized installers for specific applications/tools
```

## Component Organization

The scripts within the `arch/` directory can be categorized into distinct functional boundaries:

### 1. Vendor Wrappers and Core Architecture
- **`dots-hyprland.sh`**: The most complex script in the directory. It acts as a safety-conscious wrapper for the `illogical-impulse` dots-hyprland repository (stored in `vendor/dots-hyprland`). It manages package protection, configures hooks, and allows integration with upstream tools while retaining local control.

### 2. Graphical Session and Compositor
- **`hyprland.sh`**: Installs Hyprland and its immediate ecosystem (`hyprpaper`, `hyprshot`, `hyprlock`, `xdg-desktop-portal`). It copies `.config/hypr` files into the live directory and sets up base graphical targets using `stow`.
- **`waybar.sh`**: Deploys Waybar. Unlike `stow`-based scripts, it explicitly syncs managed files to `~/.config/waybar/`, cleans up stale files (e.g., deprecated python analysis tools), and ensures precise file permissions (e.g., `0755` for executable scripts).

### 3. Applications and Terminals
- **Terminals**: `alacritty.sh`, `kitty.sh`, `wezterm.sh`, `xterm.sh`
- **Editors and Dev Environments**: `nvim.sh`, `vscode.sh`, `wakatime.sh`, `tmux.sh`
- **Browsers and Media**: `google_chrome.sh`, `obs_studio.sh`
- **File Managers and Utilities**: `nautilus.sh`, `yazi.sh`, `rofi.sh`, `scrutiny.sh`

### 4. System utilities and Drivers
- **Networking**: `wifi.sh` (NetworkManager configuration), `bluetooth.sh`
- **Audio**: `audio.sh` (Pipewire, Wireplumber, ALSA)
- **Monitoring**: `system_monitor.sh`, `btop.sh`
- **AUR and Packages**: `aur.sh` (installs `yay`), `necessary.sh` (base-devel and essentials)
- **Miscellaneous Tools**: `tools.sh` (CLI tools, docker setup), `python3.sh`

### 5. Shell and Environments
- **Shells**: `fish.sh`, `zsh.sh`
- **Prompt Utilities**: `zsh_powerlevel.sh`

## Module Boundaries

- **Installation vs. Configuration**: Scripts typically maintain a clear boundary between installing a package via `pacman`/`yay` (Installation) and linking the configuration (Configuration).
- **GNU Stow for Configurations**: Most individual scripts utilize `stow` by navigating to the `../stow` directory and invoking `stow -v=5 -t ~ <package-name>`.
- **Custom Deployment Logic**: Modules like `waybar` break away from `stow` in favor of declarative sync scripts.
- **Upstream Delegation**: For heavy desktop environments (e.g., `dots-hyprland`), the setup logic is delegated to the git submodule, with `dots-hyprland.sh` handling only the cross-boundary safety mechanisms (guardrails against destructive updates).
