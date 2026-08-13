# CONVENTIONS

> Coding and authoring conventions observed across the `.dotfiles` repository.

## Bash Install & Verification Scripts

### Shebang & Strict Mode
```bash
#!/usr/bin/env bash
set -euo pipefail
```
`set -x` is used liberally to trace provisioning steps in legacy scripts. Structured scripts drop `set -x` in favor of explicit labeled echos.

### Echo Vocabulary — `[LABEL] message`
A consistent tagged-prefix convention for progress output:
- `[INSTALL]` — package installation
- `[CONFIG]` — config deployment / setup
- `[COPY]` — single-file copy
- `[VERIFY]` — post-install assertion
- `[DONE]` — completion / summary
- `[SKIP]` — optional step skipped
- `[PASS]` / `[FAIL]` — assertion results

### Package Install Idiom (Arch)
```bash
sudo pacman -Sy --noconfirm --needed <packages>
yay -Sy --noconfirm --needed <aur-packages>
```
`-Sy` (without `-u`) is **intentional** in targeted scripts to avoid an unattended full-system upgrade.

### Structured Script Template
```bash
#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$REPO_ROOT/.config/<app>"
DST="$HOME/.config/<app>"

PACKAGES=( ... )
MANAGED_FILES=( ... )

install_packages() { ... }
sync_managed_files() { ... }
verify()          { ... }
main() { install_packages; sync_managed_files; verify; }
main "$@"
```
Always includes an explicit `verify()` step and explicit `MANAGED_FILES` arrays deployed with `install -Dm0644`.

### Formatting
Enforced via `shfmt`.

## Python Scripts (Assertions & Tooling)

- **Type Hints**: Uses `from __future__ import annotations` and strong typing (e.g., `def main() -> int:`).
- **Formatting**: `black` for code formatting and `isort` for import sorting.
- **Style**: Uses explicit error handling (`try/except KeyError as exc:`) and routes errors to `sys.stderr`. Strict exit code management (0 for pass, 1 for fail).

## Neovim (Lua)

### Module Layout
- `core/` — framework-y infrastructure (options, keymaps, health, open)
- `config/` — Neovim-own config extensions (`config/health.lua` for `:checkhealth config`)
- `plugins/` — one file per lazy.nvim plugin spec

### Central Keymap Rule (Enforced)
- **All user mappings declared in `lua/core/keymaps/registry.lua`**.
- Plugin specs must **NOT** define inline `keys = {}`; they consume the registry.
- Domain prefixes: `f` search, `c` code, `g` git, `e` explorer, `b` buffers, `w` windows, `t` toggles, `s` save.

### LSP & Formatting
- Mason-first provisioning with system-binary fallback.
- **Format-on-save policy**: Enabled for normal file buffers using `stylua` (Lua), `prettierd`/`prettier` (Web), `clang-format` (C/C++), and `black`/`isort` (Python).
- **Graceful degradation policy (D-07)**: Runtime startup never `vim.notify`s about missing external tools. Missing tools surface via `./scripts/nvim-validate.sh health`.

## Quickshell (QML)

- **Singleton services** declared in `services/qmldir`.
- **Widget components** declared in `widgets/qmldir`.
- **Theme singleton** in `theme/qmldir`.
- Entry point `shell.qml` is minimal, delegating to variants for per-screen rendering.

## Theming Convention

- **Catppuccin Mocha** is the de facto theme contract across Hyprland (borders, cursors), Waybar (`mocha.css`), swaync, rofi, and Quickshell (`theme/Colours.qml`).
- Cursor theme: `catppuccin-mocha-dark-cursors`, size 30.

## Shell Config Conventions

- `.zshrc` uses `# INFO: Section` comment headers to organize.
- `setopt AUTO_CD`; `unsetopt CORRECT`.
- `EDITOR=nvim`.
- Aliases are grouped by function (ls variants, grep, etc.).

## Documentation & Comments

- App configs that are non-trivial ship a `README.md` and sometimes a `PRD.md`.
- Incident post-mortems live in `issues/YYYY-MM-DD_<slug>.md`.
- Bash: sparse; `set -x` serves as implicit logging or explicit labeled echos.
- Lua: section comments like `-- INFO: ...` and `-- Set up ...`.
- Python: Module-level docstrings detailing intent and constraints.

## Path Assumptions

- Repo assumed at `~/github_repo/.dotfiles`.
- Structured scripts resolve `REPO_ROOT` from `BASH_SOURCE` rather than hardcoding.
