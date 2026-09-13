# Backlog: Legacy Configuration Readers in `ubuntu/` and `debian/`

## Status
- **Date logged:** 2026-09-14 (Phase 18, Plan 18-09)
- **Status:** Open / Deferred
- **Disposition:** Out of scope for Phase 18 (tracked for future platform maintenance or script retirement)

## Context & Measured Facts
During Phase 18 research (F-9), a census of working-directory- and `$REPO_ROOT`-relative `.config/` references across the repository measured **30 files across 53 lines**:

- `scripts/phase17-unblock-assert.sh`: 19 lines (quoted grep patterns, not active reads; frozen closed-phase record)
- `scripts/nvim-validate.sh`: 14 lines (retargeted to `stow/nvim/` in Plan 18-09 Task 1)
- `scripts/phase13-d19-assert.sh`: 8 lines (repointed in Plan 18-09 Task 2)
- `scripts/phase14-verify.sh`: 5 lines (repointed in Plan 18-09 Task 2)
- `ubuntu/zsh.sh`: 2 lines
- `ubuntu/monitor_system.sh`: 2 lines
- `debian/zsh.sh`: 2 lines
- `debian/system_monitor.sh`: 1 line
- `scripts/nvim-audit-failures.sh`: 1 line (retargeted to `stow/nvim/` in Plan 18-09 Task 1)
- `arch/system_monitor.sh`: 1 line (retargeted to `stow/system_monitor/` in Plan 18-09 Task 1)
- 1 line each across 10 `ubuntu/` installer scripts: `yazi`, `xterm`, `wezterm`, `tools`, `tmux`, `rofi`, `nvim`, `kitty`, `define`, `alacritty`
- 1 line each across 10 `debian/` installer scripts: `yazi`, `xterm`, `wezterm`, `tools`, `tmux`, `rofi`, `nvim`, `kitty`, `define`, `alacritty`

Roughly 24 scripts under `ubuntu/` and `debian/` reference repo-root-relative configuration paths that do not exist today (e.g. `.config/nvim`, `.config/waybar`, `.config/.tmux.conf`, `.config/.zshrc`, etc.) and have not existed for the entire milestone. They were broken independently of Phase 18's removal of repo-root `.config/`.

## Scope Decision for Phase 18 Criterion 6
Phase 18's criterion 6 assertion (`scripts/phase18-capture-model-assert.sh` Section 6) is deliberately scoped to:
1. The twelve files moved during Phase 18 redistribution (`hypr/` subtree and the two KDE configs: `dolphinrc`, `kdeglobals`).
2. The three active scripts retargeted in Plan 18-09 Task 1 (`scripts/nvim-validate.sh`, `scripts/nvim-audit-failures.sh`, `arch/system_monitor.sh`).

## Candidate Resolutions
When Ubuntu/Debian support is next prioritized:
1. **Option A (Retarget):** Retarget each reference to its corresponding `stow/<pkg>/.config/...` package directory, mirroring the canonical Arch stow layout.
2. **Option B (Retire):** Retire or consolidate obsolete Ubuntu/Debian scripts if Arch Linux remains the sole tier-1 target for this dotfiles repository.
