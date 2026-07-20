# CONVENTIONS

> Coding and authoring conventions observed across the `.dotfiles` repository.

## Bash Install Scripts

### Shebang & strict mode (universal)
```bash
#!/usr/bin/env bash
set -euo pipefail
set -x
```
`set -x` is used liberally to trace provisioning steps. Legacy scripts stop here; structured scripts drop `set -x` in favor of explicit labeled echos.

### Echo vocabulary — `[LABEL] message`
A consistent tagged-prefix convention for progress output:
- `[INSTALL]` — package installation
- `[CONFIG]` — config deployment / setup
- `[COPY]` — single-file copy
- `[VERIFY]` — post-install assertion
- `[DONE]` — completion / summary
- `[SKIP]` — optional step skipped

### Package install idiom (Arch)
```bash
sudo pacman -Sy --noconfirm --needed <packages>
yay -Sy --noconfirm --needed <aur-packages>
```
`-Sy` (without `-u`) is **intentional** in targeted scripts to avoid an unattended full-system upgrade (documented in `arch/nvim.sh`: "caller must run `pacman -Syu` first"). `necessary.sh` is the exception that does `-Syu`.

### Structured script template (newer generation)
```bash
#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$REPO_ROOT/.config/<app>"
DST="$HOME/.config/<app>"

PACKAGES=( ... )

install_packages() { ... }
ensure_dirs()      { ... }
sync_managed_files() { ... }   # or symlink_config()
start_service()   { ... }
verify()          { ... }
print_summary()   { ... }

main() { install_packages; ensure_dirs; sync_managed_files; start_service; verify; print_summary; }
main "$@"
```
Seen in `arch/quickshell.sh` and `arch/system_monitor.sh`. Always includes a `verify()` step.

### Config deployment — three mechanisms
1. **Per-file copy**: `cp -rf .config/<app>/* ~/.config/<app>/`
2. **rsync mirror**: `rsync -a --delete .config/nvim/ ~/.config/nvim/` (nvim only)
3. **Single-dir symlink**: `ln -s $SRC $DST` (quickshell only — enables live repo editing)

### MANAGED_FILES pattern
Structured scripts enumerate an explicit `MANAGED_FILES=(...)` array and deploy each with `install -Dm0644` (preserves modes, creates parents). Seen in `arch/system_monitor.sh`.

## Neovim (Lua)

### Module layout
- `core/` — framework-y infrastructure (options, keymaps, health, open)
- `config/` — Neovim-own config extensions (`config/health.lua` for `:checkhealth config`)
- `plugins/` — one file per lazy.nvim plugin spec

### Central keymap rule (enforced)
- **All user mappings declared in `lua/core/keymaps/registry.lua`** with fields `{id, lhs, mode, desc, domain, scope, plugin, action}`
- Plugin specs must **NOT** define inline `keys = {}`; they consume the registry via `require("core.keymaps.lazy").*_keys()`
- Domain prefixes: `f` search, `c` code, `g` git, `e` explorer, `b` buffers, `w` windows, `t` toggles, `s` save

### LSP (Neovim 0.11+ baseline)
- Uses native `vim.lsp.config()` + `vim.lsp.enable()` (not legacy `lspconfig[server].setup()`)
- Mason-first provisioning with system-binary fallback

### Format-on-save policy
- Enabled for normal file buffers
- **Excluded filetypes**: `gitcommit`, `text`, `markdown`, `gitrebase`, `diff`, `NeogitCommitMessage`, `neo-tree`, `qf`
- `lsp_format = "fallback"` when formatter absent
- `<leader>cf` manual format; `<leader>sn` save-without-format

### Graceful degradation policy (D-07)
- Runtime startup never `vim.notify`s about missing external tools (formatters, LSP binaries)
- Missing tools surfaced **only** via `./scripts/nvim-validate.sh health` and `core.health.snapshot` JSON
- Each tool entry carries `affected_feature` + `install_hint`
- Only missing **plugins** fail the harness; missing **tools** warn

### init.lua defensive patch
`init.lua` monkeypatches `vim.treesitter.get_node_text` to guard against stale TSNode objects (nil `node:range()`) from nvim-treesitter injection queries — avoids needing upstream edits.

## Quickshell (QML)

- **Singleton services** declared in `services/qmldir` (`singleton Name Name.qml`)
- **Widget components** declared in `widgets/qmldir`
- **Theme singleton** in `theme/qmldir` (`singleton Colours Colours.qml`)
- `qmldir` manifests are the component registry per directory
- Entry point `shell.qml` is minimal: `Scope { Bar {} }`; `Bar.qml` uses `Variants { model: Quickshell.screens }` for per-screen rendering

## Theming Convention

- **Catppuccin Mocha** is the de facto theme contract across Hyprland (borders, cursors), Waybar (`mocha.css`), swaync, rofi (`catppuccin-lavrent-mocha.rasi`), and Quickshell (`theme/Colours.qml`)
- Cursor theme: `catppuccin-mocha-dark-cursors`, size 30 (set both via `hyprctl setcursor` and `env XCURSOR_THEME`)

## Shell Config Conventions

- `.zshrc` uses `# INFO: Section` comment headers to organize (Powerlevel10k, Path Definitions, Theme, User Configuration, Plugins)
- History: `HISTSIZE=50000`, `SAVEHIST=10000`, `APPEND_HISTORY`, `SHARE_HISTORY`, `HIST_IGNORE_DUPS`, `HIST_IGNORE_SPACE`
- `setopt AUTO_CD`; `unsetopt CORRECT`
- `EDITOR=nvim`
- Aliases are grouped (ls variants, grep, waybar_history, conda, define)

## Documentation Conventions

- App configs that are non-trivial ship a `README.md` (nvim, waybar, system_monitor/ping) and sometimes a `PRD.md` (waybar, system_monitor/ping)
- Incident post-mortems live in `issues/` named `YYYY-MM-DD_<slug>.md` with structured sections (Symptoms, Investigation, Root Cause, Resolution, Conclusion)
- `arch/README.md` is a full Arch installation walkthrough (bootloader, EFI, user creation)
- nvim README uses tables heavily (file inventory, phase summaries, validation commands, LSP expected servers, common errors)

## Comment Style

- Bash: sparse; `set -x` serves as implicit logging. Structured scripts add a header comment block explaining pattern/divergence (e.g., quickshell.sh notes "mirrors arch/waybar.sh ... Divergence: single directory symlink")
- Lua: section comments like `-- INFO: ...` and `-- Set up ...`; the keymap registry uses inline field documentation
- QML: minimal comments; structure is self-documenting via naming

## Path Assumptions

- Repo assumed at `~/github_repo/.dotfiles` (referenced in READMEs and `waybar/README.md`)
- Structured scripts resolve `REPO_ROOT` from `BASH_SOURCE` rather than hardcoding
- `define.sh` is copied to `~/` (home root), referenced as `~/define.sh` / `$HOME/define.sh`
