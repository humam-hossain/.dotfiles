# Coding Conventions

**Analysis Date:** 2026-08-21

First-party product code lives in `arch/`, `scripts/`, `stow/`, `.config/hypr/`, `debian/`, `ubuntu/`. Treat `vendor/dots-hyprland` as upstream submodule — do not copy its style into new first-party files.

## Naming Patterns

**Files:**
- Arch installers: `arch/<tool>.sh` — lowercase, underscore for multi-word (`google_chrome.sh`, `zsh_powerlevel.sh`, `system_monitor.sh`, `dots-hyprland.sh`).
- Phase asserts: `scripts/phaseNN-<topic>-assert.{py,sh}` or `scripts/phaseNN-*-smoke.sh` (`scripts/phase02-config-assert.py`, `scripts/phase07-live-smoke.sh`, `scripts/phase12-full-smoke.sh`).
- Neovim Lua: kebab-or-dot modules under `stow/nvim/.config/nvim/lua/` — `lua/plugins/<plugin>.lua`, `lua/core/keymaps/<role>.lua`.
- Waybar scripts: snake_case under `stow/waybar/.config/waybar/scripts/<domain>/` (`ping_status.sh`, `curr_weather.sh`).

**Functions (bash):**
- Use `snake_case`: `install_packages`, `ensure_dirs`, `usage`, `pass`, `fail`.
- Installer sections: `install_packages` then config helpers then `main` dispatcher when the script is more than a linear package list.
- Subcommand handlers in harnesses: `cmd_<name>` (`scripts/nvim-validate.sh`: `cmd_startup`, `cmd_sync`).

**Functions (Python):**
- `snake_case`. Type-annotated returns: `def main() -> int:`.
- Fail helpers raise `AssertionError` or return non-zero (`scripts/phase04-ipc-reload-assert.py` `fail()`).

**Functions (Lua):**
- Modules return tables: `local M = {}` then `return M` (`lua/core/health.lua`, `lua/core/keymaps/registry.lua`).
- Lazy plugins: `return { "user/repo", ... }` (`lua/plugins/lsp.lua`, `lua/plugins/conform.lua`).
- Keymap ids: dotted taxonomy `domain.action` (`mode.switch_escape`, `edit.delete_char`).

**Variables:**
- Bash: `SCREAMING_SNAKE` for constants and paths (`REPO_ROOT`, `II_ROOT`, `PACKAGES`, `SAFE_DEFAULTS`, `FAIL`).
- Locals in functions: `snake_case` (`local log`, `local rc`).
- Python: `CONFIG_PATH`, `REPO_ROOT` at module scope; `snake_case` locals.
- Env overrides: `${XDG_CONFIG_HOME:-$HOME/.config}`, `${PORT:-8765}`, `${BIND_HOST:-127.0.0.1}`.

**Types:**
- Python: `from __future__ import annotations`; `Path` for files; `dict[str, Any]` for JSON-ish structures (`stow/system_monitor/.config/system_monitor/ping/server.py`).
- Lua: no LuaCATS annotations required; plugin specs are tables.

## Code Style

**Formatting:**
- No repo-root Prettier/ESLint/Biome/ruff/pyproject. Format via Neovim Conform (`stow/nvim/.config/nvim/lua/plugins/conform.lua`):
  - Lua: `stylua`
  - Python: `isort` then `black`
  - Shell: `shfmt` (optional tool in `lua/core/health.lua`)
  - JS/TS: `prettierd` / `prettier`
  - C/C++: `clang-format`
- Lua modeline on `stow/nvim/.config/nvim/init.lua`: `ts=2 sts=2 sw=2 et`.
- Bash: 2-space indent in phase/assert scripts; some nvim-validate functions use tabs. Prefer 2 spaces for new bash.
- Python: 4-space indent, UTF-8 reads, stdlib-only for phase asserts.

**Linting:**
- No committed `.shellcheckrc`. Use inline `# shellcheck disable=SCxxxx` only with a reason nearby (`scripts/phase12-full-smoke.sh` SC2064 on `trap`; `arch/dots-hyprland.sh` SC2016).
- Syntax gate: `bash -n arch/dots-hyprland.sh` in `scripts/phase12-full-smoke.sh`.
- Do not invent a CI linter; keep scripts `set -euo pipefail`.

## Import Organization

**Python:**
1. Module docstring
2. `from __future__ import annotations`
3. Stdlib (`json`, `sys`, `pathlib`)
4. No third-party in `scripts/phase*.py`

**Lua:**
1. Optional `--- TODO:` file banner
2. `require("core.*")` / `require("lazy")` at init
3. Plugin files: `return { spec }` with `config = function()` closing over `require("core.keymaps.attach")` as needed

**Path aliases:**
- Not applicable (no TS path aliases). Resolve repo root as:
  `REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"` from `arch/` or `scripts/`.

## Error Handling

**Patterns:**
- Bash installers: `set -euo pipefail`; many also `set -x` (`arch/necessary.sh`, `arch/waybar.sh`). Do **not** add `set -x` to operator wrappers that need clean help/dry-run output (`arch/dots-hyprland.sh`).
- Echo labels: `[INSTALL]`, `[CONFIG]`, `[DONE]`, `[PASS]`, `[FAIL]`, `[SOFT]`.
- Assert scripts: accumulate `FAIL` counter; print `[PASS]`/`[FAIL]`; exit non-zero if `FAIL > 0`. Soft skips use `[SOFT]` when ii is absent (`scripts/phase07-live-smoke.sh`).
- Python asserts: print `error:` or `config assert FAIL:` to stderr; `return 1`; `sys.exit(main())`.
- Waybar widgets: never crash the bar — on curl/JSON failure print a JSON fallback and `exit 0` (`stow/waybar/.config/waybar/scripts/network/ping_status.sh`).
- Lua: `pcall(require, name)` for plugin probes (`lua/core/health.lua`); Lazy clone uses `vim.v.shell_error` then `error(...)`.
- Dangerous operations: interactive `yes` gates, `--dry-run`, refuse `--skip-backup` without `--allow-skip-backup` (`arch/dots-hyprland.sh`).

## Logging

**Framework:** stdout/stderr + Python `logging` in ping-viz only.

**Patterns:**
- Installers: `echo "[INSTALL] …"` then the command.
- Asserts: `echo "=== Phase N … ==="` then `[CONFIG] key=value`.
- Ping server: `logging.Formatter("[%(asctime)s] [%(levelname)s] %(message)s")` to console and rotating file (`stow/system_monitor/.config/system_monitor/ping/server.py`).
- Nvim harness: write logs under `.planning/tmp/nvim-validate/`; on fail `print_tail` last 50 lines to stderr.

## Comments

**When to Comment:**
- File header: purpose, usage, exit codes, mutation constraints (phase scripts).
- Safety policy: what must never be deleted/called (`arch/dots-hyprland.sh` uninstall comments).
- Guards: numbered lists in Lua autosave/format (`lua/core/keymaps.lua`, `lua/plugins/conform.lua`).
- Do not narrate `pacman -S` lines.

**JSDoc/TSDoc:**
- Not used. Python module docstrings required on phase scripts. Lua uses `-- NOTE:` / `-- TODO:` banners.

## Function Design

**Size:**
- Tiny installers may be linear (no functions) like `arch/necessary.sh`.
- Multi-step installers split `install_packages` / dir ensure / copy / chmod (`arch/waybar.sh`).
- Wrapper: `usage` + allowlist dispatcher + dedicated uninstall/protect functions (`arch/dots-hyprland.sh`).

**Parameters:**
- Prefer arrays: `PACKAGES=(...)`, `MANAGED_FILES=(...)`, `EXECUTABLE_FILES=(...)`.
- CLI: parse `--full`, `--dry-run`, `--help` in a `for arg` / `case` loop; unknown args fail (`scripts/phase10-inventory-assert.sh`).

**Return Values:**
- Bash functions: `return 0/1`; scripts `exit`.
- Python `main() -> int`.
- Lua health probes return tables `{ name, loaded, error }`.

## Module Design

**Exports:**
- Lua: `local M = {}` public API; keymap registry `M.global` / plugin-scoped lists (`lua/core/keymaps/registry.lua`).
- Python phase scripts: no package; `__main__` only.
- Bash: no sourced libraries except optional `.env` in `arch/system_monitor.sh` (`set -a; source ...; set +a`).

**Barrel Files:**
- Neovim: `require("lazy").setup("plugins")` loads all `lua/plugins/*.lua`.
- Keymaps: `lua/core/keymaps.lua` bootstraps `core.keymaps.apply`.

## Installer Pattern (prescriptive)

When adding a new Arch package script:

1. `#!/usr/bin/env bash` + `set -euo pipefail`.
2. `REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"`.
3. Package array + `sudo pacman -Sy --noconfirm --needed`.
4. If shipping config: copy from `stow/<pkg>/.config/...` or document stow; chmod scripts.
5. Label echoes `[INSTALL]` / `[CONFIG]` / `[DONE]`.
6. Mirror Debian/Ubuntu only if the same tool exists there (`debian/`, `ubuntu/`).

When wrapping upstream (`vendor/dots-hyprland`):

- Allowlist subcommands; inject safe defaults unless `--full`.
- Keep uninstall/protect wrapper-owned; never call upstream uninstall unless an explicit dangerous flag.

## Config / Overlay Pattern

- Current dual-run Hyprland: edit `.config/hypr/hyprland.conf` (repo), not the vendor tree. Helper scripts: small, `command -v` then `exec` (`.config/hypr/hyprland/scripts/launch_first_available.sh`).
- Stow packages: GNU Stow layout `stow/<name>/.config/<app>/`.
- ii Lua overlays (when adding files): parent `.config/hypr/custom/<slot>.lua` matching `vendor/dots-hyprland/dots/.config/hypr/hyprland.lua`:
  - Guarded requires: `custom.env`, `custom.execs`, `custom.general`, `custom.rules`, `custom.keybinds`
  - Use `hl.monitor` / `hl.workspace_rule` in `general.lua` for layout; keep `env.lua` / `execs.lua` as empty require slots unless adding env/exec content
  - Do not add `custom/keybinds.lua` or `custom/rules.lua` unless a phase explicitly migrates binds/rules
  - Never author machine overlays inside `vendor/dots-hyprland`

---

*Convention analysis: 2026-08-21*
