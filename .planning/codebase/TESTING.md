# TESTING

> Validation and verification strategy for the `.dotfiles` repository.

## Summary

There is **no unit-test framework** (no Bats, pytest, or busted/luaunit). Verification relies heavily on shell-orchestrated and Python headless scripts. It focuses on validating system configuration state (Neovim, Quickshell, environment configs) without destructively modifying the system.

## Neovim Validation Harness — `scripts/nvim-validate.sh`

The centerpiece of the repo's Neovim verification. A Bash script running Neovim headlessly against the repo config:
```bash
nvim --headless -u "$REPO_ROOT/.config/nvim/init.lua" --cmd "set rtp^=$REPO_ROOT/.config/nvim"
```

### Subcommands
| Subcommand | What it does | Failure signal |
|------------|--------------|----------------|
| `startup` | `nvim --headless "+qa"` smoke; deferred quit after 50ms | non-zero exit OR `Error\|E5108` in log |
| `sync` | `Lazy! sync` with **120s timeout** | timeout, non-zero, or error keywords |
| `smoke` | `pcall(require, ...)` high-risk plugin modules | any load failure |
| `health` | invokes `core.health.snapshot()`, writes `health.json` | `loaded=false` or required tool missing |
| `checkhealth` | headless `:checkhealth`, dumps buffer | unexpected `ERROR:` lines |
| `keymaps` | probes lazy key dispatcher | probe exception thrown |
| `formats` | calls `format_on_save` guard directly | wrong return value |
| `all` | runs startup→sync→smoke→health→checkhealth→keymaps→formats | fail fast |

Artifacts are written to `.planning/tmp/nvim-validate/` (gitignored).

## Phase Assertion Scripts (`scripts/phase*-assert.*`)

Python and Bash scripts validate system state for specific migration milestones ("phases"):
- **Python Config Checkers** (`phase02-config-assert.py`, `phase03-config-assert.py`, `phase04-ipc-reload-assert.py`):
  Reads JSON configuration files (e.g., `~/.config/illogical-impulse/config.json`) into memory and validates specific key constraints, typings, and values without side effects.
- **Bash Structural/Disposition Checkers** (`phase10-inventory-assert.sh`, `phase11-dispositions-assert.sh`, `phase07-live-smoke.sh`):
  Act as lint/structural gates. They verify presence of files (`test -e`), read-only host checklists, and parse documentation via `grep` to ensure required tracking/decisions exist (e.g., in `11-DISPOSITIONS.md`).

### Safety Constraints
These scripts strictly adhere to:
- Structural/lint only. They **never** `rsync`, `cp`, `mv`, or `rm` into XDG or backup dirs.
- They act as CI-like gates returning exit code `1` (FAIL) or `0` (PASS).

## Provisioning-Script Verification (`verify()`)

Modern setup scripts include explicit post-install assertions before exiting:
- `arch/system_monitor.sh`: Asserts `docker compose ps` shows running state, `/api/status` returns valid JSON, and web UI serves `<html>`.
- `arch/quickshell.sh`: Asserts `command -v quickshell`, validates symlink correctness for `~/.config/quickshell`, and checks for kernel modules.

## Manual / Interactive Verification

Documented in `.config/nvim/README.md` as a post-deploy checklist:
1. Run `./scripts/nvim-validate.sh all`.
2. Check `:checkhealth` in-editor.
3. Manual keymap smoke testing (`<leader>ff`, etc.).
4. Verify LSP attachments (`:checkhealth vim.lsp`).

## Rollback Strategy (Documented, Not Automated)

Rollbacks are handled via git source control:
- **Single-file**: `git checkout <commit> -- <file>`
- **Phase-level**: `git revert` of plan commits (`feat({phase}-{plan}):`)
- **Plugin-set**: Restore `lazy-lock.json` + `:Lazy restore`

## What Is NOT Tested
- **Quickshell QML**: No QML syntax validation; only checks that symlinks resolve.
- **Waybar custom modules**: No automated tests.
- **Hyprland config**: Evaluated only at session start.
- **Shell configs**: `.zshrc`, `fish`, `tmux` configs have no formal validation.
- **CI**: There are no automated GitHub Actions or pre-commit hooks enforcing tests; all validation is user-triggered locally.
