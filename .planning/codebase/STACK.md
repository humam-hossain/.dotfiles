# Technology Stack

**Analysis Date:** 2026-05-21

## Languages

**Primary:**
- **Lua / LuaJIT** — All Neovim configuration under `.config/nvim/`. Runtime: LuaJIT (configured via `.config/nvim/.luarc.json`: `"runtime.version": "LuaJIT"`). Used for editor options, keymaps, plugin configuration, and health checks.
- **QML (Qt Markup Language)** — Quickshell desktop panel bar under `.config/quickshell/`. Used with Qt Quick and Quickshell extensions for UI rendering, services, and widgets.
- **Bash** — Platform-specific install scripts (`arch/`, `debian/`, `ubuntu/`), validation harness (`scripts/nvim-validate.sh`, `scripts/nvim-audit-failures.sh`), and Waybar helper scripts (`.config/waybar/scripts/`).

**Secondary:**
- **CSS** — Waybar styling (`.config/waybar/style.css`, `.config/waybar/mocha.css`) and swaync notification styling (`.config/swaync/style.css`, `.config/swaync/mocha.css`).
- **TOML** — Starship prompt config (`.config/starship.toml`), Alacritty terminal config (`alacritty.toml`), Yazi file manager config (`yazi.toml`).
- **JSON/JSONC** — Waybar config (`config.jsonc`), swaync config (`config.json`), Neovim plugin lockfile (`lazy-lock.json`).
- **Rasi** — Rofi launcher theme and config (`.config/rofi/*.rasi`).
- **Zsh** — Shell config (`.config/.zshrc`, `.zprofile`) with Oh My Zsh.
- **Fish** — Fish shell config (`.config/fish/`) for Arch Linux.
- **Markdown** — Neovim README (`.config/nvim/README.md`), Waybar PRD (`.config/waybar/PRD.md`).

## Runtime

**Neovim Environment:**
- **Neovim >= 0.12.0** — Required baseline. Uses native `vim.lsp.config()` and `vim.lsp.enable()` APIs (0.11+/0.12+). Compatibility guarded in `.config/nvim/lua/config/health.lua` and `.config/nvim/lua/core/health.lua`.
- **lazy.nvim** — Plugin manager bootstrapped via `git clone` in `init.lua`. Loads plugin specs from `.config/nvim/lua/plugins/*.lua`. Version pinned in `.config/nvim/lazy-lock.json`.
- **Mason plugin suite** (`mason.nvim`, `mason-lspconfig.nvim`, `mason-tool-installer.nvim`) — Provisions LSP servers, formatters, and linters. Default tool install path.

**Desktop Environment:**
- **Hyprland** — Wayland compositor, configured in `.config/hypr/hyprland.conf`. Runs on Arch Linux.
- **Waybar** — Wayland status bar, configured in `.config/waybar/config.jsonc` with CSS styling.
- **Quickshell** — QML-based shell panel system (secondary/experimental Waybar alternative), configured in `.config/quickshell/`. Runs as `quickshell` process.
- **Hypridle** — Idle management daemon (`.config/hypr/hypridle.conf`).
- **Hyprlock** — Screen locker (`.config/hypr/hyprlock.conf`).
- **Hyprpaper** — Wallpaper utility (`.config/hypr/hyprpaper.conf`).
- **swaync** — Notification center daemon (`.config/swaync/`).

**Terminal Multiplexer:**
- **tmux** — with TPM (Tmux Plugin Manager). Configured via `.config/.tmux.conf`. Plugins managed through `~/.tmux/plugins/`.

## Frameworks

**Neovim Plugin Ecosystem:**
| Plugin | Purpose | Config File |
|--------|---------|-------------|
| `folke/lazy.nvim` | Plugin manager (bootstrapped) | `init.lua` |
| `neovim/nvim-lspconfig` | LSP client configuration | `lua/plugins/lsp.lua` |
| `mason-org/mason.nvim` | LSP/tool installer | `lua/plugins/lsp.lua` |
| `saghen/blink.cmp` | Completion engine (Rust) | `lua/plugins/blink-cmp.lua` |
| `stevearc/conform.nvim` | Format-on-save dispatcher | `lua/plugins/conform.lua` |
| `nvim-treesitter/nvim-treesitter` | Syntax parsing | `lua/plugins/treesitter.lua` |
| `folke/snacks.nvim` | Pick, dashboard, notifier, indent, explorer, lazygit, words, scroll | `lua/plugins/snacks.lua` |
| `catppuccin/nvim` | Colorscheme (Mocha) | `lua/plugins/colortheme.lua` |
| `nvim-lualine/lualine.nvim` | Statusline | `lua/plugins/lualine.lua` |
| `akinsho/bufferline.nvim` | Buffer tabline | `lua/plugins/bufferline.lua` |
| `kevinhwang91/nvim-ufo` | Folding provider | `lua/plugins/ufo.lua` |
| `lewis6991/gitsigns.nvim` | Git indicators in signcolumn | `lua/plugins/git.lua` |
| `tpope/vim-fugitive` | Git porcelain commands | `lua/plugins/git.lua` |
| `folke/which-key.nvim` | Keybinding popup helper | `lua/plugins/misc.lua` |
| `windwp/nvim-autopairs` | Auto-close brackets/quotes | `lua/plugins/misc.lua` |
| `folke/todo-comments.nvim` | TODO/FIXME highlighting | `lua/plugins/misc.lua` |
| `MeanderingProgrammer/render-markdown.nvim` | Markdown rendering | `lua/plugins/misc.lua` |
| `ahmedkhalf/project.nvim` | Project root detection | `lua/plugins/project.lua` |
| `hat0uma/csvview.nvim` | CSV column viewer | `lua/plugins/misc.lua` |
| `christoomey/vim-tmux-navigator` | Tmux pane navigation | `lua/plugins/misc.lua` |

**Desktop Frameworks:**
- **Qt Quick / Qt 6** (via Quickshell) — QML-based desktop panel with `Quickshell`, `Quickshell.Wayland`, `Quickshell.Hyprland`, `Quickshell.Io`, `Quickshell.Services.Pipewire` imports. Configured under `.config/quickshell/`.

**Shell Frameworks:**
- **Oh My Zsh** — Zsh framework, configured in `.config/.zshrc`.
- **Powerlevel10k** — Zsh theme, configured in `.config/.zshrc` and `~/.p10k.zsh`.
- **Starship** — Cross-shell prompt (TOML config present at `.config/starship.toml` but disabled in `.zshrc`).

## Key Dependencies

**Critical Neovim Plugins:**
- `folke/lazy.nvim` (latest stable via git branch) — Plugin bootstrapping; failure blocks all Neovim config loading
- `neovim/nvim-lspconfig` (master) — LSP client config; 15+ language servers registered
- `saghen/blink.cmp` (v1.\*) — Completion engine with Rust fuzzy matcher (`prefer_rust`)
- `folke/snacks.nvim` (main) — Replaces 5+ separate plugins (picker, dashboard, notifier, indent, words, scroll, explorer, lazygit)
- `nvim-treesitter/nvim-treesitter` (master) — 25+ language parsers configured for `ensure_installed`

**External Binaries Required (via `core/health.lua`):**
| Tool | Required | Affects |
|------|----------|---------|
| `git` | YES | gitsigns, lazy, diff/blame |
| `rg` (ripgrep) | YES | snacks.picker live grep, file search |
| `node` | No | ts-ls, prettierd runtime |
| `go` | No | gopls, shfmt build |

**External Binaries (via Mason provisioning in `lsp.lua`):**
- **LSP servers:** bash-language-server, marksman, clangd, gopls, css-lsp, html-lsp, json-lsp, jdtls, texlab, typescript-language-server, vim-language-server, yaml-language-server, lua-language-server, pyright
- **Formatters:** stylua, asmfmt, clang-format, prettierd, prettier, isort, black, google-java-format, latexindent, shfmt

**Desktop Environment Dependencies:**
- `waybar`, `swaync`, `hyprpaper`, `hyprlock`, `hypridle`, `hyprshot`, `rofi`, `wl-clipboard`, `wl-clip-persist`, `cliphist`, `polkit-kde-authentication-agent-1`, `playerctl`, `brightnessctl`, `ddcutil`, `pavucontrol`, `blueman-manager`, `wireplumber`, `pipewire`

**External API Dependencies (Waybar/Quickshell):**
- open-meteo.com — Weather forecast data (no auth)
- accuWeather API — Commented out in `config.jsonc`, requires API key
- USGS earthquake data — `waybar/scripts/alerts/earthquake.sh`

## Configuration

**Neovim Config Structure (`.config/nvim/`):**
- `init.lua` — Entry point: loads core options + keymaps, bootstraps lazy.nvim, starts plugin loader
- `lua/core/options.lua` — Editor defaults (50+ `vim.o` options)
- `lua/core/keymaps.lua` — Global keymap bootstrap (leader key, autosave, dispatches to registry)
- `lua/core/keymaps/` — Declarative keymap registry subsystem:
  - `registry.lua` — Central source of truth (all custom mappings with id/lhs/mode/desc/domain/scope)
  - `apply.lua` — Applies global mappings at startup
  - `lazy.lua` — Compiles lazy key specs for lazy.nvim
  - `attach.lua` — Applies buffer-local mappings on LspAttach
  - `whichkey.lua` — Registers which-key domain groups
- `lua/core/open.lua` — Cross-platform external file open helper
- `lua/core/health.lua` — Shared probe infrastructure (plugin load, tool detection, snapshot)
- `lua/config/health.lua` — `:checkhealth config` provider (6 sections)
- `lua/plugins/*.lua` — 13 plugin modules (one per plugin or plugin group)
- `lazy-lock.json` — Plugin version pinning (commit-level, JSON format)

**Desktop Config (`.config/`):**
- `hypr/hyprland.conf` — Hyprland compositor config (monitors, binds, rules, animations, input)
- `hypr/hypridle.conf`, `hypr/hyprlock.conf`, `hypr/hyprpaper.conf` — Companion daemon configs
- `waybar/config.jsonc` + `waybar/style.css` + `waybar/mocha.css` — Status bar
- `swaync/config.json` + `swaync/style.css` + `swaync/mocha.css` — Notifications
- `quickshell/` — 9 QML files (shell.qml, Bar.qml, BarContent.qml, BarGroup.qml, ModulePill.qml), 14 services, 15 widgets, 1 popup, theme colors

**Shell Config:**
- `.config/.zshrc` — Oh My Zsh + Powerlevel10k + plugins
- `.config/starship.toml` — Starship prompt (disabled)
- `.config/.tmux.conf` — Tmux with TPM and plugins
- `.config/.p10k.zsh` — Powerlevel10k theme config

**Environment Variables (`.config/hypr/hyprland.conf`):**
- `XCURSOR_THEME=Catppuccin-Mocha-Dark-Cursors`, `XCURSOR_SIZE=30`
- `PYOPENGL_PLATFORM=x11` (for Wayland Python tools)

## Platform Requirements

**Operating Systems:**
- **Arch Linux** — Primary development platform. Full desktop environment stack (Hyprland, Waybar, etc.).
- **Debian / Ubuntu** — Secondary targets. Platform-specific install scripts in `debian/` and `ubuntu/` directories.
- **Windows** — Supported for Neovim config only (manual copy to `%LOCALAPPDATA%\nvim\`).

**Hardware / Environment:**
- **Dual monitor setup** — `DP-1` (preferred, auto) + `HDMI-A-2` (preferred, 1.5x scale, rotated) configured in `hyprland.conf`.
- **Nerd Font required** — `JetBrainsMono Nerd Font` expected for UI icons in Waybar, Quickshell, Neovim (dashboards, diagnostics, git signs, bufferline, statusline).
- **Display server** — Wayland (hyprland compositor); XWayland compatibility for Python viewer tools.

**External System Tools Required:**
- Polkit authentication agent (for GUI privilege escalation)
- pipewire + wireplumber (audio server)
- NetworkManager + nmtui (network management)
- `curl`, `jq` (for Waybar weather and network scripts)
- `python3` (for some Waybar scripts)

---

*Stack analysis: 2026-05-21*
