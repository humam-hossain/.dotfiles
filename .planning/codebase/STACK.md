# Technology Stack

This document outlines the primary technology stack, languages, frameworks, and core libraries used in this dotfiles repository.

## Languages

- **Shell / Bash**: The primary language used across the codebase for system setup, configuration management, application installation, and automation tasks (`arch/*.sh`, `scripts/*.sh`).
- **Python (3.x)**: Used for test harnesses, assertion scripts, and validation workflows (e.g., `scripts/phase*-assert.py`).
- **QML**: The declarative UI language used heavily for the Quickshell-based desktop environment (integrated via `end-4/dots-hyprland`).
- **Lua**: The language used for Neovim configuration (`stow/nvim`).

## Frameworks & Core Libraries

- **GNU Stow**: Core dotfiles symlink manager utilized for deploying configurations across different tools in the `stow/` directory.
- **Hyprland**: The Wayland compositor forming the core window management foundation of the graphical environment.
- **dots-hyprland (illogical-impulse)**: An upstream framework based on Hyprland, integrated as a submodule (`vendor/dots-hyprland`). It provides the overarching UI/UX patterns and themes for the shell.
- **Quickshell**: A QML-based UI framework heavily utilized within the desktop shell to render status bars, interactive widgets, and dynamic popups.
- **Waybar**: A highly customizable Wayland status bar configured as part of the environment, often used in a dual-run mode alongside Quickshell.

## Development & Environment Tools

- **Neovim**: The primary terminal-based text editor, managed entirely using Lua configurations and lazy-loaded plugins.
- **Tmux**: Terminal multiplexer used to manage persistent terminal sessions.
- **Terminal Emulators**: Configurations are maintained for various terminals including Alacritty, Kitty, Wezterm, and Xterm.
- **System Monitors & Utilities**: `btop` for terminal-based resource monitoring and `smartmontools` for disk health.
- **Package Managers**: `pacman` and `yay` for Arch Linux targets, with support mapped for `apt` in Debian/Ubuntu scripts.
