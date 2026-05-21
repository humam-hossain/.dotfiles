# Integrations

**Analysis Date:** 2026-05-21

## External Services

**Weather Data (open-meteo.com):**
- **Used by:** Waybar (`custom/weather`, `custom/weather2` modules in `.config/waybar/config.jsonc`) and Quickshell (`Services/WeatherService.qml`)
- **Protocol:** HTTPS REST via `curl` + `jq`
- **Endpoint:** `https://api.open-meteo.com/v1/forecast?latitude=23.763953&longitude=90.424419&current=temperature_2m,relative_humidity_2m,weather_code&temperature_unit=celsius`
- **Auth model:** None (free public API)
- **Scripts:** `.config/waybar/scripts/weather/curr_weather.sh`, `.config/waybar/scripts/weather/forcast_weather.sh`, `.config/waybar/scripts/weather/functions.sh`
- **Quickshell integration:** `WeatherService.qml` spawns a `Process` calling `curr_weather.sh` every 200s, parses JSON response, exposes `text` and `tooltip` properties to QML widgets

**AccuWeather API (commented out):**
- **Used by:** Waybar config (commented out in `.config/waybar/config.jsonc` lines 55-58)
- **Protocol:** HTTPS REST
- **Endpoint:** `http://dataservice.accuweather.com/currentconditions/v1/28081` (with `apikey` query parameter)
- **Auth model:** API key (`s4pMSAgGyyOUFrF5jAzulZw8bCQGGbJz` visible in commented code)
- **Status:** Not actively used; replaced by open-meteo

**USGS Earthquake Data:**
- **Used by:** Waybar alert script (`waybar/scripts/alerts/earthquake.sh`)
- **Protocol:** HTTPS REST via `curl`
- **Endpoint:** Inferred: USGS earthquake API (`earthquake.usgs.gov`)
- **Auth model:** None (public government data)

**GitHub (vim-rhubarb):**
- **Used by:** Neovim plugin `tpope/vim-rhubarb` (loaded in `.config/nvim/lua/plugins/misc.lua`)
- **Protocol:** GitHub API via `vim-fugitive` extensions
- **Auth model:** Inherits from `git` CLI credentials (no explicit config)
- **Function:** Enables `:Gbrowse` in fugitive to open GitHub URLs

**Git (via Neovim):**
- **Used by:** `lazy.nvim` (plugin cloning), `gitsigns.nvim` (diff/blame), `vim-fugitive` (porcelain commands)
- **Protocol:** Local filesystem + SSH/HTTPS remotes (inherits system git config)
- **Required binary:** `git` (marked `required=true` in `.config/nvim/lua/core/health.lua`)
- **Validation:** Lockfile-based pinning via `.config/nvim/lazy-lock.json`; headless sync via `scripts/nvim-validate.sh sync`

## Plugin Ecosystem

**Plugin Manager Architecture (lazy.nvim):**
- **Bootstrap:** `init.lua` clones `https://github.com/folke/lazy.nvim.git` if not present at `stdpath("data")/lazy/lazy.nvim`
- **Discovery:** `require("lazy").setup("plugins")` scans `.config/nvim/lua/plugins/*.lua` for plugin spec tables
- **Lazy-loading:** Plugins specify `event`, `cmd`, `keys`, or `ft` triggers for deferred loading
- **Locking:** All 37 plugins pinned by commit hash in `.config/nvim/lazy-lock.json`; `:Lazy restore` resets to locked versions
- **Key-driven loading:** `snacks.lua` uses `keys = function() return require("core.keymaps.lazy").get_all_keys() end` — keymaps compiled from central registry trigger plugin load on first keypress

**Plugin Dependency Chains:**
```
snacks.nvim                         (standalone, replaces 6+ plugins)
├── blink.cmp (provides LSP capabilities)
└── core.keymaps.lazy (key specs)

bufferline.nvim
├── moll/vim-bbye (buffer close command)
└── nvim-tree/nvim-web-devicons

lualine.nvim
├── lewis6991/gitsigns.nvim (diff/diagnostics components)
├── nvim-tree/nvim-web-devicons
└── vimpostor/vim-tpipeline (tmux statusline forwarding)

nvim-lspconfig
├── mason-org/mason.nvim (tool installer backend)
├── mason-org/mason-lspconfig.nvim (auto-config bridge)
├── WhoIsSethDaniel/mason-tool-installer.nvim (ensure_installed)
├── j-hui/fidget.nvim (LSP progress UI)
└── saghen/blink.cmp (completion capability extension)

blink.cmp
├── rafamadriz/friendly-snippets (snippet source)
└── moyiz/blink-emoji.nvim (emoji completion)

nvim-ufo
└── kevinhwang91/promise-async (async utilities)

which-key.nvim, todo-comments.nvim
└── nvim-lua/plenary.nvim (utility library)

render-markdown.nvim
├── nvim-treesitter/nvim-treesitter (syntax parsing)
└── nvim-tree/nvim-web-devicons (file icons)
```

**Notable Plugin Interactions:**
- `blink.cmp` extends LSP capabilities: `require("blink.cmp").get_lsp_capabilities(lsp_capabilities)` called in `lsp.lua` before server config
- `vim-tpipeline` + `lualine.nvim`: Inside tmux, `vim-tpipeline` forwards lualine's rendered statusline to the tmux status bar; Neovim sets `laststatus=0` inside tmux, `laststatus=3` outside (guarded on `$TMUX` env var)
- `snacks.nvim` replaces `vim.ui.select`: `vim.ui.select = Snacks.picker.select` set in `snacks.lua`
- `nvim-treesitter` compatibility patch: `init.lua` patches `vim.treesitter.get_node_text` to guard against stale TSNode objects from injection queries
- `render-markdown.nvim` disables in `nofile` buffers to avoid treesitter nil-node crashes in snacks picker previews
- `project.nvim` sets `detection_methods = { "pattern" }` to avoid deprecated `vim.lsp.buf_get_clients()` warnings on Neovim 0.12+

## Editor/IDE Integration

**LSP Integration Model:**
- **Registration:** Neovim >= 0.11/0.12 native API — `vim.lsp.config(server_name, opts)` + `vim.lsp.enable(...)` in `.config/nvim/lua/plugins/lsp.lua`
- **Server definitions:** 15 servers defined with minimal overrides; nvim-lspconfig v2 auto-registers `cmd`/`filetypes`/`root_markers` from its bundled `lsp/*.lua` files via runtimepath
- **Mason provisioning:** `mason-tool-installer.nvim` ensures 14 LSP servers + 10 formatters installed; `mason-lspconfig.nvim` bridges registry; `automatic_enable = false` (manual enable via `vim.lsp.enable`)
- **Per-server config:** Override table in `lsp.lua` lines 46-69 — `bashls` (disables shellcheck path), `lua_ls` (single_file_support), plus defaults for `marksman`, `clangd`, `gopls`, `ty`, `cssls`, `html`, `jsonls`, `jdtls`, `texlab`, `ts_ls`, `vimls`, `yamlls`, `pyright`
- **LspAttach behavior:** Diagnostic config (severity sort, round float, Nerd Font signs), buffer-local keymaps via `core.keymaps.attach.apply_lsp()`, document highlight on CursorHold
- **Capabilities:** Extended by blink.cmp for completion; `client_supports_method` check guards documentHighlight setup

**Formatter Integration:**
- **Engine:** `stevearc/conform.nvim` configured in `.config/nvim/lua/plugins/conform.lua`
- **Per-filetype formatters:** `lua` → stylua, `python` → isort+black, `js/ts` → prettierd/prettier, `java` → google-java-format, `c/cpp` → clang-format, `asm` → asmfmt, `tex` → latexindent
- **Format-on-save:** `format_on_save` function with 4 guards (buftype, modifiable, bufname, filetype exclusion list) + `lsp_format = "fallback"` timeout
- **Manual format:** `<C-s>` triggers `conform.format()` then `:w` (in registry `save.format_and_write`)
- **Format without save:** `<leader>sn` does `noautocmd w` to skip formatters
- **Filetype exclusions:** gitcommit, text, markdown, gitrebase, diff, NeogitCommitMessage, neo-tree, qf, fugitive, git

**Completion Integration:**
- **Engine:** `saghen/blink.cmp` with Rust fuzzy matcher (`implementation = "prefer_rust"`)
- **Sources:** `lsp`, `path`, `snippets` (friendly-snippets), `buffer`, `emoji` (blink-emoji.nvim, restricted to markdown/gitcommit)
- **LSP integration:** Capabilities extended via `.get_lsp_capabilities()`; signature help enabled
- **UI:** Menu with kind_icon, kind, label, description, source_name columns; ghost text enabled; auto-show documentation

**Folding Integration:**
- **Provider:** `kevinhwang91/nvim-ufo` with `provider_selector = { "lsp", "indent" }` in `.config/nvim/lua/plugins/ufo.lua`
- **Custom virt text handler:** Shows `"...  N"` suffix with `UfoSuffixHighlight` styling
- **Keymaps:** `zR` (open all), `zM` (close all), `zK` (peek, falls back to `vim.lsp.buf.hover`)

## Platform Integration

**Cross-Platform Abstractions:**

| Concern | Approach | File |
|---------|----------|------|
| File system path | `vim.fn.stdpath("data")` — cross-platform data dir | `.config/nvim/init.lua` |
| External open | `vim.ui.open()` — uses `xdg-open` (Linux), `open` (macOS), `explorer.exe` (Windows) | `.config/nvim/lua/core/open.lua` |
| Clipboard | `vim.o.clipboard = "unnamedplus"` — unified OS clipboard | `.config/nvim/lua/core/options.lua` |
| Tmux detection | `vim.env.TMUX` — guards statusline visibility | `.config/nvim/lua/plugins/lualine.lua` |
| Nerd Font detection | `vim.g.have_nerd_font` — guards icon usage in diagnostics, alpha, folds | `.config/nvim/lua/core/options.lua`, `lsp.lua` |
| Plugin manager path | Separate runtimepath for Vim vs Neovim (`runtimepath:remove`) | `.config/nvim/lua/core/options.lua` |

**OS-Specific Behavior:**
- **Arch Linux:** Primary DE target. `arch/` scripts install hyprland, waybar, rofi, kitty, tmux, etc. Full desktop environment active.
- **Debian/Ubuntu:** `debian/` and `ubuntu/` scripts install subset (tmux, terminal tools, Neovim) without hyprland/Wayland stack.
- **Windows:** Neovim config only (no desktop environ). Manual copy to `%LOCALAPPDATA%\nvim\`. `vim.ui.open()` routes to `explorer.exe`.

**Shell/Tool Integration:**
- **tmux:** `<C-h/j/k/l>` forwarded to Neovim via `vim-tmux-navigator` plugin; tmux companion bindings in `.config/.tmux.conf` enable cross-pane and cross-window navigation. `vim-tpipeline` forwards lualine render to tmux status bar.
- **Ripgrep:** Required for `snacks.picker` grep functionality (`rg` marked `required=true` in health probe)
- **Kitty terminal:** Primary terminal (`$terminal = kitty` in `hyprland.conf`); cursor trail enabled in `.config/kitty/kitty.conf`
- **Rofi:** Application launcher (`$menu = rofi -show drun`) and clipboard history viewer (`cliphist list | rofi -dmenu -i -p ...`)
- **fzf:** Zsh keybindings via `eval "$(fzf --zsh)"` in `.config/.zshrc` (shell-level fzf, separate from Neovim picker)

## Build/Dev Tooling

**Validation Harness (`.config/nvim/README.md` + `scripts/nvim-validate.sh`):**
- **Script:** `scripts/nvim-validate.sh` (773 lines, `bash`, `set -euo pipefail`)
- **Subcommands:** `startup`, `sync`, `health`, `smoke`, `checkhealth`, `keymaps`, `formats`, `all`
- **Output directory:** `.planning/tmp/nvim-validate/` (gitignored) — stores logs, health JSON, regression reports
- **Headless Neovim:** Runs `nvim --headless` with `+qa` for startup test, `:Lazy! sync` for plugin sync, `:checkhealth` for diagnostic report
- **Health snapshot:** `core.health.snapshot()` produces machine-readable `health.json` with plugin load status, tool availability, and lazy stats
- **Health provider:** `:checkhealth config` (backed by `.config/nvim/lua/config/health.lua`) — 6 sections: version, required tools, optional tools, plugin load, config guards, known environment gaps

**Install Scripts (platform provisioning):**
| Script | Platform | Purpose |
|--------|----------|---------|
| `arch/nvim.sh` | Arch Linux | Install neovim + dependencies, copy config |
| `arch/hyprland.sh` | Arch Linux | Install Hyprland + companions |
| `arch/waybar.sh` | Arch Linux | Install Waybar + dependencies |
| `arch/rofi.sh` | Arch Linux | Install Rofi |
| `arch/tmux.sh` | Arch Linux | Install tmux + config |
| `arch/system_monitor.sh` | Arch Linux | System monitoring tools |
| `debian/nvim.sh` | Debian | Install Neovim on Debian |
| `ubuntu/nvim.sh` | Ubuntu | Install Neovim on Ubuntu |
| `scripts/clone_repo.sh` | All | Clone dotfiles repo to target machine |

**Plugin Management Workflow:**
1. Update plugin spec in `.config/nvim/lua/plugins/*.lua`
2. Run `nvim --headless "+Lazy! sync" +qa` (or `scripts/nvim-validate.sh sync`)
3. Updated `lazy-lock.json` committed to repo
4. On target machines: `git pull && scripts/nvim-validate.sh all`

**Mason Tool Management:**
- `ensure_installed` list in `lsp.lua` (lines 73-104) defines all desired packages
- `mason-tool-installer.nvim` auto-installs missing tools on startup
- Manual update: `:MasonUpdate` to refresh registry
- System binary fallback: Config degrades gracefully if tools installed outside Mason

---

*Integration audit: 2026-05-21*
