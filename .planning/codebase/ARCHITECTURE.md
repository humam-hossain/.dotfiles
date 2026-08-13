# System Architecture & Design Patterns (arch)

This document describes the high-level architecture, design patterns, and overall system design for the `arch/` focus area within the dotfiles repository.

## High-Level Architecture

The `arch/` ecosystem serves as an idempotent, modular bootstrapping environment designed for Arch Linux. Rather than relying on a single monolithic installation script, the system splits components into discrete executable modules (e.g., `bash arch/alacritty.sh`). This enables targeted package installation and configuration deployment without rerunning the entire setup process. 

Configuration management relies heavily on symlinking by GNU `stow`, while complex ecosystems (like Hyprland dotfiles) are treated as external vendor dependencies managed through git submodules and safe wrapper scripts.

## Design Patterns

### 1. Thin Wrappers for Submodules (`dots-hyprland.sh`)
Instead of duplicating upstream dotfile configurations, the system integrates the external repository `illogical-impulse/dots-hyprland` as a git submodule (`vendor/dots-hyprland`). The local `arch/dots-hyprland.sh` script is designed as a **thin wrapper** that invokes the submodule's installation script (`./setup`). This avoids polluting the local repository with upstream changes while allowing the user to update the submodule seamlessly.

### 2. Safe Defaults & Guardrails
A key architectural principle in this project is "Safe by Default." The `dots-hyprland.sh` wrapper intercepts the upstream installation sequence and forcefully injects safety flags to protect the operator's environment:
- **`--skip-hyprland`**: Ensures the user's personal `hyprland.conf` is not unexpectedly overwritten.
- **`--skip-sysupdate`**: Prevents unattended total system upgrades during dotfile configuration.
- **Backup Gate**: Explicit interactive confirmations are required before overwriting files. The script only enables destructive paths (the `FULL PROFILE`) when explicitly requested via the `--full` flag.

### 3. Declarative Package Protection
Many setup scripts demote dependencies during installation (e.g., via `--asdeps`). The architecture includes a **`protect` pattern** within `dots-hyprland.sh`. It maintains an explicit list of critical dual-run packages (such as `hyprland`, `waybar`, `fish`, `kitty`). The script automatically re-marks these explicitly (using `pacman -D --asexplicit`) so they are not accidentally wiped by system-wide orphan cleanups (e.g., `pacman -Rsu` or `yay -Yc`).

### 4. Idempotency & Targeted Deployments
Most setup scripts are written to be idempotent.
- **Package Installation**: Commands like `pacman -Sy --needed` ensure packages are skipped if they are already installed.
- **File Syncing**: Custom deployment modules (like `arch/waybar.sh`) explicitly loop through `MANAGED_FILES` to install components and `STALE_MANAGED_FILES` to clean up deprecated artifacts, ensuring the target state accurately reflects the current repository state without leaving stale ghost files.

### 5. Separation of Concerns
The system delineates between *installation* (pacman/yay), *deployment* (stow/cp), and *environment hooks* (hyprland configurations). Modules strictly handle their own concerns. 

### 6. Dual-Run Capability
The architecture intentionally allows overlapping software ecosystems to run simultaneously. The system accommodates maintaining a personalized layout (e.g., a local `waybar` setup deployed via `stow` or script sync) while safely isolating the submodule's interface (e.g., `quickshell`). Uninstall implementations (`arch/dots-hyprland.sh uninstall`) cleanly dismantle the vendor's components and kill lingering processes without compromising the user's primary operating stack.
