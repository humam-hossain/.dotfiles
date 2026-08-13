# Codebase Concerns & Technical Debt

This document outlines the current technical debt, architectural flaws, known issues, and areas for improvement within the `.dotfiles` project.

## 1. Architectural Complexity & Fragility
- **Wrapper around Upstream Installer**: The project shifted from a hand-rolled `Quickshell` product to wrapping the upstream `end-4/dots-hyprland` repository via a git submodule (`vendor/dots-hyprland`). The `.dotfiles` repo relies on a thin, yet fragile wrapper (`arch/dots-hyprland.sh`) to invoke upstream's `./setup` script. Maintaining injection flags like `SAFE_DEFAULTS=(--core --skip-hyprland --skip-sysupdate)` to protect personal files and limit blast radius adds significant cognitive overhead.
- **Dual-run UI Stopgap**: The desktop shell is currently running in a "dual-run" mode, retaining the legacy Waybar, rofi, and swaync stack alongside the newly introduced `illogical-impulse` (`ii`) shell. The final cutover (CUT-01) has been deferred, leaving multiple overlapping UI components active in the `exec-once` path.
- **Configuration Sidecars**: Because the environment is not a "firstrun" machine, the upstream setup script handles conflicts by generating `*.new` sidecar files (e.g., `hyprlock.conf.new`, `hypridle.conf.new`) instead of safely migrating or merging state. These require manual operator disposition, causing the project state to accumulate `UNKNOWN` or deferred migration gaps.
- **Dependency Management Risk**: The `implicitize_old_dependencies` (asdeps) demotion behavior in the upstream installer leaves machine-time residuals (`previous_dependencies.conf`). This makes the package state non-deterministic and difficult to track purely through git history.

## 2. Neovim Configuration Skeleton
- **Incomplete Implementation**: The Neovim configuration inside `stow/nvim/.config/nvim/lua/` is completely hollow. Every file (e.g., `plugins/lsp.lua`, `plugins/snacks.lua`, `core/keymaps.lua`) is a skeleton containing only `--- TODO: ... ---` markers. The editor lacks an actual LSP client, UI enhancements, syntax parsing, and keymap registry.
- **Premature Auditing**: Despite the Neovim setup being merely a stub, there are already enforcement scripts (`scripts/nvim-audit-failures.sh`) policing these `TODO` markers, adding unnecessary CI/audit friction for work that hasn't started yet.

## 3. Capability Regressions (Waybar Parity)
- Transitioning fully to the `ii` shell means losing custom Waybar modules (e.g., self-hosted ping monitor, weather, earthquake data - CUST-01..03). The ports of these features to the new shell have been explicitly deferred past the v0.3 milestone, meaning the final cutover will suffer a temporary capability regression.

## 4. Hardware Constraints & Known Bugs
- **iGPU DDC/CI Crash**: As documented in `issues/2026-07-16_igpu-flickering-hang-no-display.md`, aggressive `ddcutil` polling over the DDC/CI bus causes the Intel UHD 770 iGPU to suffer engine resets, resulting in a progressive system freeze and black screen. This hardware quirk completely blocks the implementation of native brightness/backlight controls in the desktop shell.

## 5. Process & Workflow Friction
- **Strict Debt Markers**: The custom verification harness (`.claude/gsd-core/workflows/verify-phase.md`) strictly enforces that any `TBD`, `FIXME`, or `XXX` marker must be accompanied by a formal issue reference (e.g., `issue #123`). This prohibits lightweight developer notes and forces immediate formalization of all debt, which can slow down rapid prototyping or exploration phases.
