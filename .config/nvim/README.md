# Neovim config

## File Inventory

| File | Purpose |
|------|---------|
| lua/core/options.lua | Editor defaults |
| lua/core/keymaps.lua | Global keymaps |
| lua/core/keymaps/registry.lua | Keymap registry |
| lua/core/keymaps/whichkey.lua | Which-key groups |
| lua/core/keymaps/apply.lua | Global mapping app |
| lua/core/keymaps/attach.lua | Buffer-local mappings |
| lua/core/keymaps/lazy.lua | Lazy keymap compilation |
| lua/core/health.lua | Health snapshot |
| lua/core/open.lua | External open |
| lua/plugins/lsp.lua | LSP setup |
| lua/plugins/blink-cmp.lua | Completion |
| lua/plugins/conform.lua | Format-on-save |
| lua/plugins/treesitter.lua | Parsers |
| lua/plugins/git.lua | Git integration |
| lua/plugins/colortheme.lua | Colorscheme |
| lua/plugins/lualine.lua | Statusline |
| lua/plugins/ufo.lua | Folding |
| lua/plugins/snacks.lua | UI enhancements |
| lua/plugins/misc.lua | Misc plugins |
| lua/plugins/bufferline.lua | Buffer tabs |
| lua/plugins/project.lua | Project scoping |
| lua/plugins/vim-indent-object.lua | Indent textobjects |

## Rollout and Update Workflow

This section is the single entry point for applying this config to a new or existing machine, verifying it, and rolling back if something breaks. It assumes the dotfiles repo is cloned at `~/github_repo/.dotfiles` (adjust paths if yours differs).

### Machine Update Checklist

Run these steps in order from the dotfiles repo root. Each step is idempotent.

1. **Pull the latest config**

   ```bash
   cd ~/github_repo/.dotfiles
   git pull --ff-only
   ```

   If the pull is not a fast-forward, resolve manually before continuing — do not `--rebase` against local edits to `.config/nvim/` without reading the phase summaries under `.planning/phases/` first.

2. **Run the install script** (Arch)

   ```bash
   bash arch/nvim.sh
   ```

   This installs `python-pynvim`, `luarocks`, `tree-sitter-cli`, and `neovim` via `pacman -Sy --needed`, then copies `.config/nvim/*` into `~/.config/nvim/`. On Debian/Ubuntu use the `ubuntu/` equivalent if present; on Windows copy `.config/nvim/` into `%LOCALAPPDATA%\nvim\` manually.

3. **Sync plugins against the locked set**

   ```bash
   ./scripts/nvim-validate.sh sync
   ```

   This runs `:Lazy! sync` headlessly with a 120-second timeout. It installs newly added plugins (like `folke/snacks.nvim` introduced in Phase 5) and uninstalls anything removed from the spec tree (`noice.nvim`, `nvim-notify`, `alpha.nvim`, `indent-blankline`, `fzf-lua`). Expected last line: `PASS: sync OK`.

   If you prefer the interactive path, open Neovim and run `:Lazy sync` then quit.

4. **Update Mason-managed tools**

   Open Neovim and run:

   ```
   :MasonUpdate
   ```

   This refreshes the Mason registry so LSP servers, formatters, and linters pull in any new versions. Tools installed system-wide (outside Mason) are untouched — the config's system-binary fallback (Phase 4) handles those.

5. **Run the full validation harness**

   ```bash
   ./scripts/nvim-validate.sh all
   ```

   This runs `startup`, `sync`, `smoke`, and `health` in order and fails fast. Expected final line: `==> all PASS`. See **Post-Deploy Verification** below for what to do on failure.

6. **Launch Neovim and confirm the UI**

   ```bash
   nvim
   ```

   You should see the snacks.nvim dashboard, not the old alpha banner. Press `<leader>ff` to confirm `snacks.picker` opens for file search. Press `<leader>gg` to confirm `snacks.lazygit` opens the lazygit float. These three checks cover the Phase 5 UX-01 coherence surface.

### Phase-by-Phase Change Summary

This summary captures what each phase changed so a maintainer updating a machine from an older config knows what behavior is now different.

| Phase | What Changed | User-Visible Effect |
|-------|--------------|---------------------|
| **Phase 1** | Buffer-first lifecycle; autosave runs only on `FocusLost` for normal buffers; external open uses `vim.ui.open()` | `<C-q>` closes current buffer (not the whole session); special buffers never auto-save; `<C-S-o>` works on Linux, macOS, and Windows |
| **Phase 2** | All custom keymaps moved into `lua/core/keymaps/registry.lua`; leader prefixes organized by domain (`f` search, `c` code, `g` git, `e` explorer, `b` buffers, `w` windows, `t` toggles, `s` save) | Plugin specs no longer define their own `keys = {}`; `:WhichKey` shows grouped, labeled commands |
| **Phase 3** | Added `scripts/nvim-validate.sh` with `startup`/`sync`/`health`/`smoke`/`all` subcommands; added `core.health.snapshot` producing `health.json`; missing external tools degrade silently at runtime and surface only via `health` | Startup no longer nags about missing formatters; validation harness is the single source of truth for "what's missing" |
| **Phase 4** | LSP migrated to Neovim 0.11+ `vim.lsp.config()` + `vim.lsp.enable()`; Mason-first provisioning with system-binary fallback; save-format policy with filetype exclusions (`gitcommit`, `markdown`, `text`, `gitrebase`, `diff`, `NeogitCommitMessage`, `neo-tree`, `qf`); `<leader>cf` manual format; `<leader>sn` save-without-format | Faster LSP startup; no unwanted formatting in commit messages or markdown; cleaner plugin specs |
| **Phase 5** | `noice.nvim`, `nvim-notify`, `alpha.nvim`, `fzf-lua`, and `indent-blankline` replaced by `folke/snacks.nvim` submodules (notifier, dashboard, picker, indent, scroll, words, lazygit, quickfile); lualine `globalstatus = true` with `laststatus` guarded on `$TMUX`; catppuccin integrations pruned (`telescope`/`nvimtree` removed) and `snacks` integration added | Bottom-right toast notifications; minimal snacks dashboard on empty launch; same fuzzy-find keymaps (`<leader>ff`, `<leader>fg`, `<leader>cd`, `<leader>cr`, etc.) now backed by snacks.picker; `<leader>gg` opens lazygit float; statusline visible outside tmux |

### Post-Deploy Verification

Run these checks in order after step 5 of the update checklist. Each check has an expected outcome; anything else is a regression.

1. **Harness: full validation suite**

   ```bash
   ./scripts/nvim-validate.sh all
   ```

   Expected final line: `==> all PASS`. The suite runs `startup`, `sync`, `smoke`, `health`, and `checkhealth`. Output artifacts land in `.planning/tmp/nvim-validate/` — inspect `health.json` if `health` fails or `checkhealth.txt` if `checkhealth` fails.

2. **In-editor: :checkhealth**

   Open Neovim and run:

   ```
   :checkhealth
   ```

   Scroll through each section. Expected: no errors (`ERROR:` lines) from `snacks`, `lazy`, `lspconfig`, `mason`, `blink.cmp`, `gitsigns`, `neo-tree`, `lualine`, `treesitter`. Warnings (`WARNING:`) about optional tooling (e.g., a missing language LSP you do not use) are acceptable.

3. **Manual keymap smoke**

   | Keymap | Expected Behavior |
   |--------|-------------------|
   | `<leader>ff` | snacks.picker files float opens |
   | `<leader>fg` | snacks.picker grep float opens and finds matches including in hidden files |
   | `<leader>gg` | snacks.lazygit float opens the lazygit TUI |
   | `<leader>cd` | snacks.picker jumps to LSP definition (on a symbol) |
   | `<leader>cr` | snacks.picker lists LSP references |
   | `:echo "test"` + Enter | Bottom-right notification toast appears (snacks.notif) |

4. **Statusline placement check**

   - Inside tmux: Neovim should have no statusline inside its own window; the tmux status bar at the bottom should reflect the current mode/branch/filename (vim-tpipeline forwards lualine's render).
   - Outside tmux (direct terminal or Windows or VS Code embedded): Neovim should show its own statusline at the bottom (guard flips `laststatus=3`).

5. **Dashboard check**

   Launching `nvim` with no file argument should show the snacks.nvim default dashboard sections (Keymaps, Recent Files, Projects, startup footer). If you still see the old alpha ASCII banner, `:Lazy sync` did not clean — rerun step 3 of the checklist.

### Rollback Instructions

If post-deploy verification fails and you cannot fix forward quickly, use the most targeted rollback that matches the failure mode.

#### A. Single-file rollback (config-level regression)

If a specific file broke (e.g., `lualine.lua` or `registry.lua`), revert just that file:

```bash
cd ~/github_repo/.dotfiles
git log --oneline .config/nvim/lua/plugins/lualine.lua
git checkout <commit-before-breakage> -- .config/nvim/lua/plugins/lualine.lua
bash arch/nvim.sh
./scripts/nvim-validate.sh all
```

Use this when one plan's changes misbehave but other plans are fine.

#### B. Phase-level rollback (one plan broke, others are OK)

Revert the commits of the offending plan only. Each plan commit message starts with `feat({phase}-{plan}):` or `docs({phase}-{plan}):`.

```bash
cd ~/github_repo/.dotfiles
git log --oneline --grep='05-01'   # find the plan's commits
git revert <commit-sha>...<commit-sha>   # creates new revert commits (does not rewrite history)
bash arch/nvim.sh
./scripts/nvim-validate.sh all
```

Prefer `git revert` over `git reset --hard` so the history remains linear and other machines can pull the revert cleanly.

#### C. Plugin-set rollback (lazy-lock.json regression)

If `:Lazy sync` pulled a new plugin version that breaks startup, restore the previous lockfile and pin plugins back:

```bash
cd ~/github_repo/.dotfiles
git log --oneline lazy-lock.json
git checkout <previous-commit> -- lazy-lock.json
```

Then inside Neovim:

```
:Lazy restore
```

`:Lazy restore` reads `lazy-lock.json` and resets every plugin to the commit recorded there. Re-run `./scripts/nvim-validate.sh all` to confirm the rollback is healthy.

#### D. Full phase rollback (last resort)

If Phase 5 is the problem and you want the pre-Phase-5 state back:

```bash
cd ~/github_repo/.dotfiles
git log --oneline --grep='05-'                # list all Phase 5 commits
git revert <oldest-05-commit>..<newest-05-commit>
bash arch/nvim.sh
./scripts/nvim-validate.sh all
```

Expect `snacks.nvim` to be uninstalled on the next `:Lazy sync` and the old `noice.nvim`, `nvim-notify`, `alpha.nvim`, `fzf-lua`, `indent-blankline` plugin specs to be restored by the revert.

#### Rollback Sanity Checks

After any rollback path above, the same post-deploy verification suite applies:

```bash
./scripts/nvim-validate.sh all
nvim   # confirm dashboard, <leader>ff, <leader>gg interactively
```

If the harness is still red after rollback, the breakage is upstream of the reverted commit range — widen the revert window or open a fresh branch and bisect with `git bisect` against `./scripts/nvim-validate.sh startup`.


## Phase 4: Tooling and Ecosystem Modernization

This phase modernizes the Neovim tooling stack around a current ecosystem baseline: Neovim 0.11+ native LSP registration, safe format-on-save, and productivity-first defaults.

### Neovim 0.11+ Baseline

- **LSP registration**: Uses `vim.lsp.config()` + `vim.lsp.enable()` instead of legacy `lspconfig[server].setup()`
- **Mason-first provisioning**: Preferred path for LSP servers and formatters
- **System-binary fallback**: Config degrades gracefully when tools are installed system-wide rather than via Mason

### Save-Format Policy

- **Enabled by default** for normal file buffers
- **Excluded filetypes**: `gitcommit`, `text`, `markdown`, `gitrebase`, `diff`, `NeogitCommitMessage`, `neo-tree`, `qf`
- **Fallback**: Uses `lsp_format = "fallback"` for predictable behavior when formatter is absent
- **Manual format**: `<leader>cf` forces format without saving
- **Save without format**: `<leader>sn` saves without triggering format

### Productivity-First Defaults

- **Completion**: blink.cmp with docs, signature help, and ghost text enabled by default
- **Search**: fzf-lua with live grep, file search, buffers
- **Tree**: neo-tree with external open via `vim.ui.open()` (cross-platform)
- **Git**: gitsigns + fugitive with inline hunk preview

### Validation Commands

| Command | Purpose |
|---------|---------|
| `./scripts/nvim-validate.sh startup` | Headless startup smoke test |
| `./scripts/nvim-validate.sh sync` | Lazy sync with 120s timeout |
| `./scripts/nvim-validate.sh health` | Core health snapshot (plugins + tools) |
| `./scripts/nvim-validate.sh smoke` | pcall-require high-risk plugins |
| `./scripts/nvim-validate.sh checkhealth` | Headless `:checkhealth` — dumps full report to `.planning/tmp/nvim-validate/checkhealth.txt`; fails on any ERROR line |
| `./scripts/nvim-validate.sh all` | Run all validations in order (startup → sync → smoke → health → checkhealth) |

### Central Keymap Rule

Per Phase 2 architecture, all user-facing mappings are declared in `lua/core/keymaps/registry.lua`. Plugin specs must NOT introduce inline `keys = { ... }` — instead, they reference the registry via `require("core.keymaps.lazy").*_keys()`.

## Phase 2: Central Command and Keymap Architecture

This phase centralizes all custom keymaps under a declarative registry for discoverability and maintainability.

### Domain Taxonomy

All leader-prefixed keymaps follow explicit domain prefixes:

| Prefix | Domain | Description |
|--------|--------|-------------|
| `<leader>f` | search | Fuzzy find, grep, files, buffers |
| `<leader>c` | code | LSP goto, references, actions |
| `<leader>g` | git | Status, blame, hunk navigation |
| `<leader>e` | explorer | File tree, reveal |
| `<leader>b` | buffers | Buffer list, close |
| `<leader>w` | windows | Window navigation, resize |
| `<leader>t` | toggles | Fold, inlay hints |
| `<leader>s` | save | Write, session |

### Preserved Direct Keys

These non-leader keys are intentionally preserved:

| Key | Action |
|-----|--------|
| `jk` | Switch to normal mode |
| `<C-h>` | Window left |
| `<C-j>` | Window down |
| `<C-k>` | Window up |
| `<C-l>` | Window right |
| `<C-_>` | Toggle comment |
| `<Tab>` | Next buffer |
| `<S-Tab>` | Previous buffer |

### Mapping Scopes

- **global**: Applied immediately at startup via `core.keymaps.apply`
- **lazy**: Loaded on key trigger via `lazy.nvim` — defined in registry, consumed by plugin specs
- **buffer**: Applied on LSP attach via `core.keymaps.attach`
- **plugin-local**: Context-specific (neo-tree windows, treesitter incremental)

### Registry Architecture

```
lua/core/keymaps/
├── registry.lua   -- Declarative source of truth
├── apply.lua      -- Applies global mappings
├── lazy.lua       -- Compiles lazy.nvim keys specs
├── attach.lua     -- Applies buffer-local mappings
└── whichkey.lua  -- Registers which-key groups
```

All custom mappings are declared in `registry.lua` with: `id`, `lhs`, `mode`, `desc`, `domain`, `scope`, `plugin`, `action`.

## Phase 3: Validation Harness

The repo ships a shell-orchestrated headless validation harness so maintainers can catch startup, sync, health, and plugin-load regressions without launching an interactive Neovim.

### Entrypoint

| Command | Purpose |
|---------|---------|
| `./scripts/nvim-validate.sh startup` | Run `nvim --headless "+qa"` against this config; fail on any error message or non-zero exit |
| `./scripts/nvim-validate.sh sync` | Run headless `Lazy! sync` with a 120s timeout; fail on timeout or stack traceback |
| `./scripts/nvim-validate.sh health` | Invoke `core.health.snapshot` and write JSON to `.planning/tmp/nvim-validate/health.json`; fail on any plugin with `loaded=false` |
| `./scripts/nvim-validate.sh smoke` | pcall-require the high-risk plugin modules one by one; fail on any load failure |
| `./scripts/nvim-validate.sh checkhealth` | Run headless `:checkhealth`, dump full report to `.planning/tmp/nvim-validate/checkhealth.txt`; fail on any ERROR line |
| `./scripts/nvim-validate.sh keymaps` | pcall-test the keymap dispatcher against Phase 7 error-prone action string types; fail on any error thrown; artifact: `keymap-regression.log` |
| `./scripts/nvim-validate.sh formats` | Call the `format_on_save` guard directly with mock buffer contexts (nofile, unnamed, acwrite); verify correct false/options return; artifact: `format-regression.log` |
| `./scripts/nvim-validate.sh all` | Run startup → sync → smoke → health → checkhealth → keymaps → formats in order; fail fast |

### Report Output

All reports are written to `.planning/tmp/nvim-validate/` (gitignored):

- `startup.log` — stdout+stderr from headless startup
- `sync.log` — output from `Lazy! sync`
- `smoke.log` — per-plugin pcall results
- `health.json` — machine-readable snapshot (schema below)
- `health.log` — stderr from the health invocation
- `checkhealth.txt` — full rendered `:checkhealth` output
- `keymap-regression.log` — per-action-type pcall results from the keymap dispatcher probe
- `format-regression.log` — per-buffer-context guard return values from the format-on-save probe

### Health Snapshot Schema

`health.json` is produced by `require('core.health').snapshot({...})` and conforms to:

```json
{
  "neovim_version": "<semver>",
  "timestamp": "<ISO-8601 UTC>",
  "plugins": [ { "name": "<module>", "loaded": true, "error": null } ],
  "tools":   [ { "name": "<binary>", "available": true, "path": "/usr/bin/..." } ],
  "lazy":    { "installed": 42, "loaded": 42, "problems": [] }
}
```

Missing external tools are reported as `available: false` with install hints printed by the shell wrapper. Missing tools do NOT fail the harness (per Phase 3 D-07 graceful degradation policy); only missing plugins fail.

### Missing Tool Policy

Per Phase 3 decisions D-07 through D-09:

- Runtime startup does NOT emit `vim.notify` warnings when external tools (formatters, LSP binaries) are missing. Startup stays graceful and silent.
- Missing tools are surfaced ONLY through `./scripts/nvim-validate.sh health` and the `core.health.snapshot` JSON.
- Each tool entry in `health.json` includes `affected_feature` (what stops working) and `install_hint` (how to install).
- Tool-sensitive plugins (conform.nvim formatters, mason-managed LSPs) degrade silently when their binary is absent; the health command is the single source of truth for what is missing.

Example missing-tool output from `./scripts/nvim-validate.sh health`:

```
MISSING TOOLS:
WARN: missing tool 'shfmt' — affects Shell formatting — install: go install mvdan.cc/sh/v3/cmd/shfmt@latest
WARN: missing tool 'gopls' — affects Go LSP — install: mason: :MasonInstall gopls
```

### When To Run

- After any change in `.config/nvim/lua/plugins/*.lua`: `./scripts/nvim-validate.sh startup`
- After refreshing `lazy-lock.json`: `./scripts/nvim-validate.sh all`
- Before concluding Phase 3 or starting Phase 4: `./scripts/nvim-validate.sh all`

## Phase 1: Reliability and Portability Baseline

This config is designed to work across Arch Linux, Debian/Ubuntu, and Windows with a unified buffer-first lifecycle model.

### Buffer, Window, and Tab Model

- **Buffer-first**: `<C-q>` closes the current buffer with confirmation if modified
- **Windows are layout only**: `<leader>xs` closes only the current split
- **Tabs are explicit workspaces**: Not affected by normal buffer-close commands

### Autosave Policy

- Autosave runs only on `FocusLost` for normal file buffers
- Checks: `buftype == ""`, `modifiable`, `modified`, non-empty filename
- Special buffers (terminal, quickfix, prompt, nofile, help) are never auto-written

### External Open Behavior

- `<C-S-o>` opens the current buffer's file with the system default application
- Neo-tree `<c-o>` opens the selected node with the same helper
- Uses `vim.ui.open()` for cross-platform support (Linux, macOS, Windows)

### Supported Platforms

| Platform | Status | Notes |
|----------|--------|-------|
| Arch Linux | Tested | Uses system default app via vim.ui.open |
| Debian/Ubuntu | Tested | Same as Arch |
| Windows | Tested | Uses explorer.exe via vim.ui.open |

### Smoke Checklist

1. **Load test**: `nvim --headless "+qa"`
2. **External open**: Press `<C-S-o>` - should open in system default app
3. **Neo-tree open**: In neo-tree, press `<c-o>` on a file - should open externally
4. **Buffer close**: Press `<C-q>` on modified buffer - should prompt for confirmation
. **Split close**: Press `<leader>xs>` - should close only current split
6. **Autosave**: Edit a file, switch focus away - should auto-save (FocusLost)

## Manual LSP Verification

### Quick Check

```bash
# View LSP log for errors
tail -50 ~/.local/state/nvim/lsp.log
```

In Neovim, open a file and run:

```
:LspInfo
```

Shows active LSP clients for the current buffer.

### Per-Language Test

Open a file with a known filetype and check the log for successful start:

| Filetype | Expected LSP |
|----------|--------------|
| `.lua` | lua_ls |
| `.py` | ty |
| `.js`/`.ts` | ts_ls |
| `.rs` | rust_analyzer |
| `.go` | gopls |
| `.c`/`.h` | clangd |
| `.md` | marksman |
| `.sh` | bashls |
| `.json` | jsonls |
| `.html` | html |
| `.css` | cssls |
| `.yaml` | yamlls |

Expected log entry: `"Starting <server> LSP server"` or `"Starting Marksman LSP server"`.

### Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `invalid "eslint_d" config: cmd: expected table, got nil` | eslint_d not in config or not installed | Remove from lsp_servers or install eslint |
| `ShellCheck: disabling linting as no executable was found` | shellcheck not installed | Install `pacman -S shellcheck` or set `shellcheckPath = ""` in bashls |
| `locale-loader error` | lua_ls root_dir callback issue | Remove custom root_dir from lua_ls config |
| `jdtls: Java 21 not found` | Java 21 not installed | Install Java 21 or disable jdtls |

### Verify All Servers Enabled

```bash
nvim --headless -c "lua print(vim.inspect(vim.lsp.get_active_clients()))" -c "qa" 2>&1 | grep -v "deprecated"
```

## Resources

- typecraft yt: [youtube.com/watch?v=iXIwm4mCpuc&list=PLsz00TDipIffreIaUNk64KxTIkQaGguqn](https://www.youtube.com/watch?v=iXIwm4mCpuc&list=PLsz00TDipIffreIaUNk64KxTIkQaGguqn)
- Andrew Courter: [youtube.com/watch?v=NG7P_fPeuA8](https://www.youtube.com/watch?v=NG7P_fPeuA8)
- Henry Misc: [youtu.be/KYDG3AHgYEs?si=6Jfkb2AHaWKDDYmx](https://youtu.be/KYDG3AHgYEs?si=6Jfkb2AHaWKDDYmx)
- MrJackob (Much more detailed): [youtube.com/watch?v=g1gyYttzxcI&list=PLy68GuC77sURrnMNi2XR1h58m674KOvLG](https://www.youtube.com/watch?v=g1gyYttzxcI&list=PLy68GuC77sURrnMNi2XR1h58m674KOvLG)
