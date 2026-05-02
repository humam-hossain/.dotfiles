# Cross-Platform Dotfiles

**Last updated:** 2026-05-02 — v1.2 milestone (Waybar → Quickshell Migration) started.

## What This Is

A `.dotfiles` repo that ships a complete Hyprland desktop environment across Arch Linux and Debian/Ubuntu. Includes a shared Neovim configuration (cross-platform, with Windows OS guards), a Waybar status bar with custom widgets, swaync notifications, and supporting scripts. v1.0–v1.1 modernized and hardened the Neovim config; v1.2 replaces Waybar with a Quickshell/QML bar.

## Current Milestone: v1.2 Waybar → Quickshell Migration

**Goal:** Build a Quickshell/QML status bar for Hyprland that replaces Waybar with full widget parity, popup panels, and animations — parallel deployment so Waybar stays live until the new bar is verified.

**Target features:**
- Bar shell: Quickshell `Bar.qml` with left/center/right `BarGroup` layout, Catppuccin Mocha theme, pill-shaped modules, JetBrainsMono Nerd Font
- Widget parity: workspaces (Hyprland IPC), disk, CPU, memory, network, ping monitor, weather ×2, clock, tray, music, volume, backlight, lock, power, notification count
- Popup panels: calendar (clock click), volume OSD (scroll), network panel (network click), notification center
- Animations: module hover transitions, popup open/close
- Parallel deploy: Waybar untouched until verified; `arch/quickshell.sh` install script

## Current State

**Shipped:** v1.1 Neovim Setup Bug Fixes (2026-04-25)

- All 10 BUG-01 shared keymaps fixed — no Lua/E488 errors on invocation
- Plugin runtime misconfigurations removed; crash-prone editor flows hardened
- `:checkhealth config` provider ships with 6 sections and required/optional severity classification
- `nvim-validate.sh` expanded with `keymaps` and `formats` regression subcommands
- README Machine Update Checklist and Post-Deploy Verification refreshed for stable rollout

**Active:** v1.2 Waybar → Quickshell Migration (started 2026-05-02)

## Core Value

One dotfiles repo gives a clean, modern, bug-resistant desktop and editor experience across Linux (and Windows for Neovim) without the setup fighting the user.

## Requirements

### Validated

- ✓ All config-caused runtime errors removed from keymaps, plugins, and crash-prone flows — v1.1 (BUG-01–03, validated Phase 11)
- ✓ Config-caused E488/Lua errors removed from 9 shared keymaps; registry-driven mappings execute safely — v1.1 (BUG-01, Phase 7)
- ✓ `:checkhealth` is trustworthy first-line diagnostic — 6-section provider, required/optional severity classification — v1.1 (HEAL-01–02, Phase 9)
- ✓ Regression detection expanded: `keymaps` and `formats` subcommands cover flows `:checkhealth` cannot probe — v1.1 (TEST-01–03, Phase 10)
- ✓ Modular Neovim config loads from `.config/nvim/init.lua` with `core/` and `plugins/` split — existing
- ✓ Plugin management via `lazy.nvim` with pinned revisions in `lazy-lock.json` — existing
- ✓ LSP, Mason, formatting, Treesitter, search, file explorer, git UI, statusline, folding, and theme — existing
- ✓ Custom editor behavior via centralized options and keymaps — existing
- ✓ Cross-platform OS-aware open helper (`vim.ui.open()`) replacing hardcoded shell commands — v1.0 (PLAT-01–04)
- ✓ Buffer-first close with confirmation, conservative FocusLost-only autosave — v1.0 (CORE-01–03)
- ✓ Central keymap registry with domain taxonomy; all plugins consume registry keys — v1.0 (KEY-01–03)
- ✓ Plugin audit: keep/remove/replace decisions for every plugin; refreshed lockfile — v1.0 (PLUG-01, PLUG-03)
- ✓ Headless validation harness (`scripts/nvim-validate.sh` + `core/health.lua`) for startup/sync/health/smoke — v1.0 (TOOL-01)
- ✓ Actionable health output for missing external tools — v1.0 (TOOL-03)
- ✓ Neovim 0.11-native LSP (`vim.lsp.config/enable`); format-on-save with filetype safety policy — v1.0 (PLUG-02, TOOL-02)
- ✓ Coherent UI: snacks.nvim replacing 5 plugins, globalstatus statusline, tmux-aware laststatus — v1.0 (UX-01)
- ✓ Rollout documentation: machine checklist, phase summary, verification steps, rollback modes — v1.0 (UX-02)

### Active

- BAR-01: Quickshell bar renders at top of screen on Hyprland startup — v1.2
- BAR-02: Bar has left/center/right layout with Catppuccin Mocha pill modules — v1.2
- WS-01: Workspaces widget shows Hyprland workspaces; active highlighted in Mauve — v1.2
- SYS-01: CPU, memory, disk, network widgets with system monitor popup — v1.2
- CUST-01: Ping widget fetches from `localhost:8765` ping monitor server — v1.2
- CUST-02: Weather (current + forecast) widgets via open-meteo — v1.2
- CUST-03: Clock widget (Asia/Dhaka) with calendar popup on click — v1.2
- MEDIA-01: Music widget (playerctl), volume widget (PulseAudio), backlight (ddcutil) — v1.2
- NOTIF-01: System tray, swaync notification count, lock + power buttons — v1.2
- POPUP-01: Popup panels: calendar, volume OSD, network, notification center — v1.2
- ANIM-01: Module hover transitions and popup open/close animations — v1.2
- DEPLOY-01: Parallel deploy — Waybar stays live; `arch/quickshell.sh` install script — v1.2

### Out of Scope

- Forked per-OS Neovim configs — one shared config remains source of truth
- Eliminating warnings caused only by optional user tooling or machine-local preferences — classify and document instead
- CI-based multi-OS automation — deferred until local validation surface is proven stable (AUTO-01, AUTO-02)
- Machine-role optional plugin profiles — deferred until core setup is stable across machines (PROF-01)

## Context

Shipped v1.0 on 2026-04-15, v1.1 on 2026-04-25. Current config has:
- Modular Lua structure under `.config/nvim/` — `core/`, `plugins/`, `config/`
- Central keymap registry (`lua/core/registry.lua`) with domain taxonomy; safe dispatcher in `lazy.lua`
- `:checkhealth config` provider (`lua/config/health.lua`) with 6 sections and severity classification
- Headless validator (`scripts/nvim-validate.sh`) with 7 subcommands: startup, sync, health, smoke, keymaps, formats, all
- Rollout docs in `.config/nvim/README.md` — Machine Update Checklist + Post-Deploy Verification table
- ~3800 LOC Lua + shell

Known deferred tech debt (non-blocking):
- Two dead functions in `attach.lua` (`apply_neotree`, `setup_lsp_attach`) — no callers since Phase 8 neo-tree removal
- Windows external-open (`<leader>o`) interactive verification — no Windows machine available
- README "Validation Commands" summary table missing `keymaps`/`formats` rows (full Entrypoint table at line 325 is correct)

## Constraints

- **Platform**: One shared config across Arch Linux, Debian/Ubuntu, and Windows — portability remains first-class
- **Workflow**: This lives in a `.dotfiles` repo — changes must be safe for rollout onto existing machines
- **Reliability**: Bug fixes outrank feature additions — regression prevention is part of done
- **Validation**: `:checkhealth` is primary signal; scripts cover runtime gaps health cannot prove
- **Compatibility**: Preserve existing modern architecture unless a bug requires targeted rollback or replacement

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Keep one shared Neovim config repo across Linux and Windows | Single source of truth is easier to maintain than separate per-OS setups | ✓ Shipped v1.0 with OS guards |
| Use OS-specific guards inside config rather than separate codepaths | Cross-platform support required but divergence stays controlled | ✓ `vim.ui.open()` pattern established |
| Centralize all custom keymaps in one registry | Scattered mappings were hard to audit safely | ✓ Registry with domain taxonomy, all plugins consume keys |
| Allow aggressive plugin cleanup and replacement | Goal is best-fit modern config, not preservation of existing choices | ✓ Dropped 3 plugins, migrated 5 to snacks.nvim |
| Include reliability, plugin audit, performance, UI polish, and regression prevention in v1 scope | User wanted a clean up-to-date Neovim config, not a narrow bugfix patch | ✓ Delivered |
| Neovim 0.11-native LSP via `vim.lsp.config/enable` | Removes legacy setup path; follows upstream direction | ✓ Clean migration, all servers work |
| snacks.nvim replaces dashboard, indent, input, notifier, scope (5 plugins) | UX coherence: one well-maintained plugin over several overlapping plugins | ✓ Shipped in v1.0 |
| Format-on-save with filetype safety policy | Avoid polluting commit messages, markdown, and scratch buffers with formatter noise | ✓ Exclusion list well-tested |
| Headless validation harness lives in-repo | Catch regressions without full UI session | ✓ `scripts/nvim-validate.sh` shipped |
| v1.1 treats `:checkhealth` as first diagnostic surface | Health output is fastest shared debugging entry point across machines | ✓ `config.health` provider ships with 6 sections, required/optional severity classification |
| Add scripts only where `:checkhealth` cannot prove setup correctness | Avoid duplicate validation surfaces and keep maintenance cost bounded | ✓ `checkhealth` subcommand added; `core.health` is shared probe infrastructure |
| which-key group registration guard: skip group add() when lhs already owned by real mapping | `<leader>e` and `<leader>b` were both group specs and real mappings — which-key warned on duplicate | ✓ Duplicate-prefix warnings eliminated in Phase 10 |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-05-02 — v1.2 milestone (Waybar → Quickshell Migration) started*
