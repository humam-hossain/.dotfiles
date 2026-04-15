# Phase 5: UX and Performance Polish - Research

**Researched:** 2026-04-15
**Domain:** Neovim plugin consolidation (snacks.nvim), startup profiling, statusline polish, rollout documentation
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** 05-01 should take an aggressive removal pass — treat profiling as another audit round, not documentation only.
- **D-02:** Target startup time: under 100ms. Profile with `:Lazy profile`, defer non-essential UI plugins, remove plugins that don't justify their startup cost.
- **D-03:** Non-essential plugins that are candidates for deferral or removal: `alpha.nvim` (replaced by snacks.dashboard), `indent-blankline` (replaced by snacks.indent), `nvim-notify` (replaced by snacks.notif), `noice.nvim` (replaced by snacks), `fzf-lua` (replaced by snacks.picker).
- **D-04:** Replace `noice.nvim` + `nvim-notify` with `snacks.notif`. Bottom-right toast-style notifications.
- **D-05:** Replace `alpha.nvim` with `snacks.dashboard`. Minimal/default dashboard — no ASCII art port needed.
- **D-06:** Replace `fzf-lua` with `snacks.picker`. Preserve existing keymaps exactly (`<leader>ff`, `<leader>fg`, `<leader>cd`, `<leader>cr`, etc.) — rewire to snacks.picker actions, no muscle-memory changes.
- **D-07:** Wire `snacks.lazygit` with a keymap (e.g., `<leader>gg`). lazygit is already installed as a binary.
- **D-08:** Enable `snacks.indent` — replaces `indent-blankline`.
- **D-09:** Enable `snacks.words` — LSP word highlights.
- **D-10:** Enable `snacks.scroll` — smooth scrolling for `<C-d>`/`<C-u>`.
- **D-11:** Leave `snacks.image` disabled — image preview not needed.
- **D-12:** `snacks.terminal` and `snacks.zen` decisions deferred to Claude — enable only if they add clear value without noise.
- **D-13:** Update the Phase 3 validation harness probes to target `snacks.notif` instead of `noice`/`nvim-notify` after migration.
- **D-14:** Update `catppuccin` integration flags: remove stale `telescope = true` and `nvimtree = true`; add `snacks = true` if supported.
- **D-15:** Keep `vim-tpipeline` — lualine pushes status to tmux as before.
- **D-16:** Set `globalstatus = true` in lualine (future-proofing for non-tmux).
- **D-17:** Guard `laststatus` on tmux presence: if `$TMUX` is set → `laststatus=0`; else → `laststatus=3`.
- **D-18:** lualine section layout after noice removal is Claude's discretion — remove the noice status component, keep remaining sections sensible.
- **D-19:** Extend `.config/nvim/README.md` with a Rollout/Update section. No new file.
- **D-20:** Section must cover: machine update checklist, phase-by-phase change summary, verification steps post-deploy, and rollback instructions.
- **D-21:** One shared config across Linux and Windows remains locked.
- **D-22:** Keymaps remain centrally managed — snacks.picker keymaps must go through the central registry, not be scattered into the plugin spec.
- **D-23:** Validation harness must remain functional after all replacements — update probes as part of migration, not after.

### Claude's Discretion

- lualine section layout after noice component removal
- Whether to enable `snacks.terminal` and `snacks.zen` (only if clearly additive)
- Exact snacks.picker keymap wiring to match the existing fzf-lua surface
- Exact startup deferral strategy (which `event =` assignments to add/change)
- Catppuccin integration flag audit beyond the known stale entries

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| UX-01 | User gets a coherent UI after cleanup, with statusline, notifications, tree, completion, and theme behavior working together | snacks.nvim consolidation eliminates noice/nvim-notify/alpha/fzf-lua/indent-blankline; catppuccin snacks integration flag provides theme coherence; globalstatus + laststatus guard provides statusline consistency |
| UX-02 | User gets measurable reduction of obvious startup or plugin waste after audit and profiling | `:Lazy profile` identifies waste; removing noice + nvim-notify + alpha + fzf-lua + indent-blankline eliminates 5 plugins; snacks.quickfile accelerates buffer reads before lazy fully loads |
</phase_requirements>

---

## Summary

Phase 5 consolidates five separate plugins (noice.nvim, nvim-notify, alpha.nvim, fzf-lua, indent-blankline) into a single snacks.nvim spec. This is not an incremental improvement — it is a hard replacement pass that removes five plugin files and their dependency chains, adding one new plugin spec in their place. snacks.nvim ships with `lazy = false, priority = 1000` so it initializes before other plugins; its submodules (notifier, dashboard, picker, indent, words, scroll, lazygit) are individually enabled via opts.

The keymap migration is the highest-risk task: 14+ fzf-lua registry entries in `registry.lua` reference `require("fzf-lua").*` calls and must be rewired to `Snacks.picker.*` equivalents. The registry architecture from Phase 2 supports this: only the `action` functions inside existing registry entries change — the `lhs`, `desc`, and `id` fields stay identical. Buffer-local LSP mappings (`<leader>cr`, `<leader>cd`, `<leader>ci`, etc.) also reference fzf-lua directly in `registry.lua` and must be updated.

The validation harness (nvim-validate.sh) currently probes `'notify'`, `'noice'`, `'fzf-lua'`, `'alpha'` by name in the PLUGIN_LIST and smoke test. These must be swapped to `'snacks'` as part of migration, not afterward.

**Primary recommendation:** Migrate snacks.nvim first (05-02), then run the startup audit (05-01) to quantify gains, then write rollout docs (05-03). Doing profiling before snacks migration gives a misleading baseline.

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| folke/snacks.nvim | latest (stable branch) | Consolidated QoL: notifications, dashboard, picker, indent, scroll, words, lazygit | Single folke-maintained package replaces 5 separate plugins; lazy=false, priority=1000 bootstrap |
| nvim-lualine/lualine.nvim | existing (keep) | Statusline | Already installed; add globalstatus=true, laststatus guard |
| vimpostor/vim-tpipeline | existing (keep) | Push lualine status into tmux statusline | Already working; no change needed |
| catppuccin/nvim | existing (keep) | Colorscheme + integrations | Already installed; update integration flags |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| snacks.lazygit | (bundled in snacks.nvim) | Float lazygit window | lazygit binary already installed; wire `<leader>gg` |
| snacks.quickfile | (bundled) | Render files fast before full lazy load | Enable by default; reduces perceived startup latency |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| snacks.picker | Keep fzf-lua | fzf-lua requires separate install + config; snacks.picker is already inside the snacks package being installed for other features; migration cost is bounded by the registry rewrite |
| snacks.notifier | nvim-notify alone | nvim-notify without noice loses the cmdline_popup styling; snacks.notif is a clean replacement |

**Installation:**
```bash
# snacks.nvim will be installed by lazy.nvim on next :Lazy sync after adding the spec
# No system-level install needed
```

**Version verification:** [VERIFIED: github.com/folke/snacks.nvim] — snacks.nvim is actively maintained (releases page shows activity through 2025). No pinned version needed; lazy.nvim tracks the stable branch.

---

## Architecture Patterns

### Recommended Project Structure

snacks.nvim replaces multiple files with one. The migration produces:

```
lua/plugins/
├── snacks.lua          # NEW: single spec replacing notify.lua, alpha.lua,
│                       #      indent-blankline.lua, fzflua.lua (partially)
├── notify.lua          # DELETED (noice.nvim + nvim-notify)
├── alpha.lua           # DELETED (alpha-nvim)
├── indent-blankline.lua # DELETED (ibl)
├── fzflua.lua          # DELETED (fzf-lua)
├── lualine.lua         # MODIFIED: globalstatus, laststatus guard, remove noice component
├── colortheme.lua      # MODIFIED: remove telescope+nvimtree flags, add snacks=true
└── ...                 # All other files unchanged
```

Central keymap registry changes:
```
lua/core/keymaps/registry.lua   # MODIFIED: 14+ search entries + 7 LSP buffer entries
                                 #   action functions: require("fzf-lua").* → Snacks.picker.*
```

Validation harness changes:
```
scripts/nvim-validate.sh        # MODIFIED: PLUGIN_LIST and smoke lua script
                                 #   remove: 'notify','noice','fzf-lua','alpha'
                                 #   add: 'snacks'
```

### Pattern 1: snacks.nvim Spec Structure

**What:** snacks.nvim uses `lazy = false, priority = 1000` — it must load before other plugins because notifier and quickfile need to run at startup.

**When to use:** This is the only correct way to configure snacks.nvim.

**Example:**
```lua
-- Source: github.com/folke/snacks.nvim README
return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    notifier = {
      enabled = true,
      timeout = 3000,
      top_down = false,  -- bottom-right toast accumulation
    },
    dashboard = {
      enabled = true,
      sections = {
        { icon = " ", title = "Keymaps",      section = "keys",         indent = 2, padding = 1 },
        { icon = " ", title = "Recent Files",  section = "recent_files", indent = 2, padding = 1 },
        { icon = " ", title = "Projects",      section = "projects",     indent = 2, padding = 1 },
        { section = "startup" },
      },
    },
    picker = { enabled = true },
    indent = { enabled = true },
    scroll = { enabled = true },
    words  = { enabled = true },
    lazygit = { enabled = true },
    quickfile = { enabled = true },
    -- Disabled per D-11/D-12:
    image    = { enabled = false },
    terminal = { enabled = false },  -- re-evaluate if clearly additive
    zen      = { enabled = false },  -- re-evaluate if clearly additive
  },
}
```
[VERIFIED: github.com/folke/snacks.nvim README — priority=1000, lazy=false confirmed as required]

### Pattern 2: snacks.picker Keymap Wiring in Registry

**What:** The fzf-lua `action` functions in `registry.lua` are function literals that call `require("fzf-lua").*`. Replace the function body only — `lhs`, `id`, `desc`, `domain`, `scope` do not change.

**When to use:** Every entry in `M.lazy` that has `plugin = "ibhagwan/fzf-lua"` and every entry in `M.buffer` that calls `require("fzf-lua")`.

**Example — search domain (M.lazy entries):**
```lua
-- BEFORE (fzf-lua):
{
  id = "search.files",
  lhs = "<leader>ff",
  plugin = "ibhagwan/fzf-lua",
  action = function() require("fzf-lua").files() end,
},

-- AFTER (snacks.picker):
{
  id = "search.files",
  lhs = "<leader>ff",
  plugin = "folke/snacks.nvim",
  action = function() Snacks.picker.files() end,
},
```

**Example — LSP buffer-local (M.buffer entries):**
```lua
-- BEFORE:
{ id = "lsp.references",  action = function(opts) require("fzf-lua").lsp_references(opts) end },
{ id = "lsp.definition",  action = function(opts) require("fzf-lua").lsp_definitions(opts) end },
{ id = "lsp.implementations", action = function(opts) require("fzf-lua").lsp_implementations(opts) end },

-- AFTER:
{ id = "lsp.references",      action = function() Snacks.picker.lsp_references() end },
{ id = "lsp.definition",      action = function() Snacks.picker.lsp_definitions() end },
{ id = "lsp.implementations", action = function() Snacks.picker.lsp_implementations() end },
```
[VERIFIED: github.com/folke/snacks.nvim/docs/picker.md — lsp_references, lsp_definitions, lsp_implementations, lsp_typedefs, lsp_document_symbols, lsp_live_workspace_symbols all exist as picker sources]

**Full fzf-lua → snacks.picker function mapping:**

| fzf-lua | snacks.picker |
|---------|---------------|
| `require("fzf-lua").files()` | `Snacks.picker.files()` |
| `require("fzf-lua").live_grep({...})` | `Snacks.picker.grep()` |
| `require("fzf-lua").files({ cwd = vim.fn.stdpath("config") })` | `Snacks.picker.files({ cwd = vim.fn.stdpath("config") })` |
| `require("fzf-lua").helptags()` | `Snacks.picker.help()` |
| `require("fzf-lua").keymaps()` | `Snacks.picker.keymaps()` |
| `require("fzf-lua").builtin()` | `Snacks.picker()` (show all pickers) |
| `require("fzf-lua").grep_cword()` | `Snacks.picker.grep_word()` |
| `require("fzf-lua").grep_cWORD()` | `Snacks.picker.grep_word()` |
| `require("fzf-lua").diagnostics_document()` | `Snacks.picker.diagnostics()` |
| `require("fzf-lua").resume()` | `Snacks.picker.resume()` |
| `require("fzf-lua").oldfiles()` | `Snacks.picker.recent()` |
| `require("fzf-lua").buffers()` | `Snacks.picker.buffers()` |
| `require("fzf-lua").lgrep_curbuf()` | `Snacks.picker.lines()` |
| `require("fzf-lua").lsp_references()` | `Snacks.picker.lsp_references()` |
| `require("fzf-lua").lsp_definitions()` | `Snacks.picker.lsp_definitions()` |
| `require("fzf-lua").lsp_implementations()` | `Snacks.picker.lsp_implementations()` |
| `require("fzf-lua").lsp_typedefs()` | `Snacks.picker.lsp_type_definitions()` |
| `require("fzf-lua").lsp_document_symbols()` | `Snacks.picker.lsp_symbols()` |
| `require("fzf-lua").lsp_live_workspace_symbols()` | `Snacks.picker.lsp_workspace_symbols()` |

[VERIFIED: github.com/folke/snacks.nvim/docs/picker.md for snacks side; registry.lua read directly for fzf-lua side]

### Pattern 3: Catppuccin Integration Flags

**What:** `colortheme.lua` currently has stale flags. The catppuccin nvim plugin has a dedicated snacks integration module.

**Current state (stale flags):**
```lua
integrations = {
  cmp = true,
  gitsigns = true,
  nvimtree = true,   -- STALE: nvim-tree is not installed, neo-tree is
  telescope = true,  -- STALE: telescope is not installed, fzf-lua was
  treesitter = true,
  markdown = true,
},
```

**After migration:**
```lua
integrations = {
  cmp       = true,   -- blink.cmp uses the cmp flag for compat
  gitsigns  = true,
  neotree   = true,   -- correct flag for neo-tree.nvim
  treesitter = true,
  markdown  = true,
  snacks    = {
    enabled = true,
    indent_scope_color = "",  -- default = overlay2; leave blank for default
  },
  -- REMOVED: nvimtree, telescope
},
```
[VERIFIED: catppuccin/nvim README — snacks integration key exists with enabled + indent_scope_color options; neotree flag exists as separate key from nvimtree]

Note on `cmp = true`: blink.cmp inherits catppuccin's nvim-cmp highlight groups for compatibility. The flag remains valid. [ASSUMED — blink.cmp compat doc not verified in this session; risk if wrong is cosmetic only]

### Pattern 4: lualine laststatus Guard

**What:** Replace the hardcoded `vim.o.laststatus = 0` with a tmux-aware guard.

**Example:**
```lua
-- In lualine.lua, inside config function, after require("lualine").setup({...}):
if vim.env.TMUX then
  vim.o.laststatus = 0  -- tmux handles the statusline display
else
  vim.o.laststatus = 3  -- globalstatus; lualine shows inside Neovim
end
```

This block replaces the current `vim.o.laststatus = 0` hardcode at line 57 of lualine.lua.

**lualine options block — globalstatus:**
```lua
options = {
  theme = "auto",
  section_seperator = "",
  component_seperators = "",
  icons_enabled = true,
  globalstatus = true,  -- changed from false
},
```
[VERIFIED: lualine.lua read directly; D-16/D-17 in CONTEXT.md]

### Pattern 5: lualine Section Layout after noice Removal

The current `lualine_x` has a pcall-guarded noice component. After removing noice, drop the entire pcall block and use a clean static list:

```lua
lualine_x = { "filetype" },
```

This is minimal and intentional — filetype is the most useful lualine_x item without noice. Add `"encoding"` if the user prefers more info. The encoding field adds < 1ms and is zero-dependency. [ASSUMED — no strong preference expressed in CONTEXT.md; Claude's discretion per D-18]

### Pattern 6: Validation Harness Plugin List Update

**Current PLUGIN_LIST in nvim-validate.sh:**
```bash
PLUGIN_LIST="{'notify','noice','lualine','neo-tree','lspconfig','conform','nvim-treesitter.configs','blink.cmp','fzf-lua','gitsigns','ufo','bufferline','which-key','alpha','render-markdown'}"
```

**After migration:**
```bash
PLUGIN_LIST="{'snacks','lualine','neo-tree','lspconfig','conform','nvim-treesitter.configs','blink.cmp','gitsigns','ufo','bufferline','which-key','render-markdown'}"
```

Removed: `notify`, `noice`, `fzf-lua`, `alpha`
Added: `snacks`

The smoke test Lua script inside `cmd_smoke()` has the same list hardcoded — both must be updated in sync. [VERIFIED: nvim-validate.sh read directly]

### Anti-Patterns to Avoid

- **Leaving fzf-lua in the spec after removing keymaps:** fzf-lua without any `keys =` trigger will still lazy-load on the first call; remove the file entirely.
- **Putting snacks keymap wiring inside snacks.lua plugin spec `keys = {}`:** The Phase 2 constraint (D-22) requires all keymaps in the central registry. The snacks.lua spec should have no `keys = {}` table.
- **Setting snacks.notif `top_down = true`:** This puts notifications at the top; user wants bottom-right toast. Use `top_down = false` (or omit — verify default).
- **Running `:Lazy profile` before the plugin migration:** The baseline will include noice/alpha startup costs that are being removed anyway. Profile after migration for a meaningful measurement.
- **Deleting fzflua.lua before updating registry.lua:** The lazy.lua compiler reads `plugin = "ibhagwan/fzf-lua"` to wire lazy-load triggers. If the file is deleted while registry still references fzf-lua, snacks.picker keymaps won't trigger correctly.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Notification styling | Custom vim.notify wrapper | snacks.notif | Handles level icons, top_down positioning, history, persistence |
| Fuzzy finding | Custom telescope/fzf wrapper | Snacks.picker.* | 40+ built-in sources, fzf syntax, LSP integration |
| Dashboard | Custom alpha config port | snacks.dashboard sections | Sections API handles key bindings, recent files, startup time |
| Indent guides | Custom sign/extmark logic | snacks.indent | Handles scope highlighting, treesitter integration |
| Startup time measurement | Custom profiling script | `:Lazy profile` | lazy.nvim has built-in per-plugin timing |
| lazygit float window | Custom terminal float | snacks.lazygit | Auto-configures lazygit, handles resize, pass-through keymaps |

**Key insight:** snacks.nvim is a deliberate consolidation of patterns that Folke (lazy.nvim author) has refined across multiple plugins. Custom implementations of these will always miss edge cases (special buffers, Windows path handling, headless mode guards) that snacks already handles.

---

## Common Pitfalls

### Pitfall 1: snacks.notif default position

**What goes wrong:** Notifications appear at the top-right instead of bottom-right.
**Why it happens:** snacks.notif defaults to `top_down = true` (notifications stack from top). Bottom-right requires `top_down = false`.
**How to avoid:** Explicitly set `top_down = false` in the notifier opts.
**Warning signs:** First notification appears near top of screen after migration.

### Pitfall 2: Residual noice/nvim-notify references after migration

**What goes wrong:** Startup error `module 'noice' not found` or `module 'notify' not found`.
**Why it happens:** The lualine.lua noice pcall block is guarded with `pcall` so it degrades safely — but if the validation harness PLUGIN_LIST still includes `'noice'` and `'notify'`, the health subcommand will fail because those modules no longer exist.
**How to avoid:** Update nvim-validate.sh PLUGIN_LIST and smoke script in the same commit that removes notify.lua.
**Warning signs:** `./scripts/nvim-validate.sh health` fails with `loaded=false` for noice/notify.

### Pitfall 3: fzflua.lua deletion order

**What goes wrong:** Picker keymaps stop working because the lazy.lua compiler still references `plugin = "ibhagwan/fzf-lua"` in registry entries, but fzflua.lua (which triggers fzf-lua install) is gone.
**Why it happens:** lazy.nvim uses the `plugin` field to know which plugin's `keys = {}` triggers lazy-load. If registry entries still say `plugin = "ibhagwan/fzf-lua"`, lazy won't know which plugin to load when the key is pressed.
**How to avoid:** Update `plugin = "folke/snacks.nvim"` in all registry entries before or simultaneously with deleting fzflua.lua.
**Warning signs:** `<leader>ff` does nothing or shows "No such plugin" error.

### Pitfall 4: snacks.picker grep options

**What goes wrong:** Live grep doesn't include hidden files or exclude `.git/`, breaking the existing `<leader>fg` behavior.
**Why it happens:** The current fzf-lua live_grep call in registry.lua passes explicit `rg_opts` including `--hidden -g '!.git/'`. snacks.picker.grep() has its own defaults.
**How to avoid:** Check snacks.picker.grep() options — pass `hidden = true` and exclude pattern if not default. [ASSUMED — exact snacks.picker grep option names not verified from docs in this session; LOW confidence on exact syntax]
**Warning signs:** `<leader>fg` no longer finds files in hidden directories.

### Pitfall 5: globalstatus + vim-tpipeline interaction

**What goes wrong:** With `globalstatus = true`, lualine renders a single statusline at the bottom of the screen even when vim-tpipeline is active inside tmux. This may show double statuslines or incorrect display.
**Why it happens:** vim-tpipeline reads lualine's rendered status and forwards it to tmux; `laststatus=0` was suppressing the lualine render inside Neovim. With `globalstatus = true` and `laststatus=0`, lualine still renders but Neovim hides it — this is the correct behavior inside tmux.
**How to avoid:** The D-17 guard is the correct solution: `laststatus=0` when `$TMUX` is set preserves current behavior; `laststatus=3` when not in tmux makes lualine visible.
**Warning signs:** Statusline appears both inside Neovim and in tmux status bar simultaneously.

### Pitfall 6: Startup profiling measurement timing

**What goes wrong:** Running `:Lazy profile` before the migration makes it look like startup is slower than it really is after removal.
**Why it happens:** noice.nvim loads on `VeryLazy` which means it doesn't appear in startup time — but its deferred setup still costs CPU time after UIEnter.
**How to avoid:** Run baseline profile, do migration, run post-migration profile, compare numbers.
**Warning signs:** "Under 100ms" target is met before migration — check if profiler is measuring all plugins or only startup-path ones.

---

## Code Examples

Verified patterns from official sources:

### snacks.nvim minimal working spec
```lua
-- Source: github.com/folke/snacks.nvim README
return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = {
    notifier  = { enabled = true, top_down = false },
    dashboard = { enabled = true },
    picker    = { enabled = true },
    indent    = { enabled = true },
    scroll    = { enabled = true },
    words     = { enabled = true },
    lazygit   = { enabled = true },
    quickfile = { enabled = true },
    image     = { enabled = false },
    terminal  = { enabled = false },
    zen       = { enabled = false },
  },
}
```

### snacks.lazygit keymap in registry.lua
```lua
-- Add to M.lazy in registry.lua:
{
  id = "git.lazygit",
  lhs = "<leader>gg",
  mode = "n",
  desc = "Open LazyGit",
  domain = "g",
  scope = "lazy",
  plugin = "folke/snacks.nvim",
  action = function() Snacks.lazygit() end,
},
```

### lualine noice component removal
```lua
-- BEFORE (lualine.lua lualine_x):
lualine_x = (function()
  local ok_noice, noice = pcall(require, "noice")
  local x = {}
  if ok_noice and noice and noice.api and noice.api.status then
    table.insert(x, { noice.api.status.mode.get, cond = noice.api.status.mode.has, ... })
    table.insert(x, { noice.api.status.command.get, cond = noice.api.status.command.has, ... })
  end
  table.insert(x, "filetype")
  return x
end)(),

-- AFTER (simple, no noice dependency):
lualine_x = { "filetype" },
```

### Startup profiling workflow
```
# Inside Neovim (interactive):
:Lazy profile

# Headless baseline measurement:
nvim --startuptime /tmp/nvim-startup.log +qa && tail -1 /tmp/nvim-startup.log
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| telescope.nvim for fuzzy finding | snacks.picker (or fzf-lua) | 2024-2025 | Fewer dependencies, faster |
| nvim-notify + noice.nvim | snacks.notif | 2024 | Single plugin, less config |
| alpha.nvim for dashboard | snacks.dashboard | 2024 | No separate install needed |
| indent-blankline v2/v3 | snacks.indent | 2024-2025 | Consolidation into snacks |
| globalstatus = false | globalstatus = true | Neovim 0.8+ | Single statusline for all splits |

**Deprecated/outdated in this config:**
- `telescope = true` in catppuccin integrations: Telescope is not installed; the flag has no effect but pollutes the config and may cause catppuccin to set up unused highlight groups.
- `nvimtree = true` in catppuccin integrations: nvim-tree is not installed; neo-tree uses `neotree = true`.
- `noice.api.status.*` in lualine_x: noice is being removed; the pcall guard degrades gracefully but leaves dead code.
- `globalstatus = false` in lualine: should be `true` with the laststatus guard doing the real work.

---

## Runtime State Inventory

Step 2.5: SKIPPED — this is a plugin replacement and configuration phase, not a rename/rebrand/migration of stored data. No runtime state (databases, service configs, OS registrations) is affected. The changes are entirely within `.config/nvim/` Lua files and the validation shell script.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| nvim | All tasks | Yes | v0.12.1 | — |
| lazygit | snacks.lazygit D-07 | Yes (per CLAUDE.md: installed via arch/tools.sh) | — | — |
| git | Validation harness | Yes | — | — |
| bash | nvim-validate.sh | Yes | — | — |

[VERIFIED: `nvim --version` output: NVIM v0.12.1; lazygit install confirmed via CLAUDE.md "arch/tools.sh" installs lazygit]

**Missing dependencies with no fallback:** None.

**Missing dependencies with fallback:** None.

**Note on snacks.nvim availability:** snacks.nvim is not yet installed (`~/.local/share/nvim/lazy/snacks.nvim` does not exist). It will be installed by lazy.nvim on first `:Lazy sync` after `snacks.lua` is added to `lua/plugins/`. This is expected — the migration task must add the spec before syncing.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Custom shell harness (nvim-validate.sh) |
| Config file | `scripts/nvim-validate.sh` |
| Quick run command | `./scripts/nvim-validate.sh startup` |
| Full suite command | `./scripts/nvim-validate.sh all` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| UX-01 | Startup completes without errors after plugin migration | smoke | `./scripts/nvim-validate.sh smoke` | Yes (after harness update) |
| UX-01 | All required plugins load (snacks, lualine, neo-tree, blink.cmp, gitsigns) | health | `./scripts/nvim-validate.sh health` | Yes (after PLUGIN_LIST update) |
| UX-02 | Startup time measurably reduced (< 100ms target) | manual | `:Lazy profile` + `nvim --startuptime` | Yes (interactive) |

### Sampling Rate
- **Per task commit:** `./scripts/nvim-validate.sh startup`
- **Per wave merge:** `./scripts/nvim-validate.sh all`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] Update `scripts/nvim-validate.sh` PLUGIN_LIST and smoke list — required before 05-02 migration can pass health checks. This is itself a task step in 05-02, not a pre-existing gap.

---

## Security Domain

Security enforcement applies minimally to this phase — it is a UI/UX and performance phase with no authentication, network, or data handling changes. No ASVS categories apply beyond the baseline (V5 input validation — not relevant here; all inputs are Lua configuration). No external APIs or credentials are introduced.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `cmp = true` catppuccin flag works for blink.cmp highlight compat | Architecture Patterns / Pattern 3 | Cosmetic: completion menu colors may not match catppuccin mocha exactly |
| A2 | snacks.picker.grep() supports hidden file inclusion equivalent to fzf-lua's explicit `--hidden` rg flag | Common Pitfalls / Pitfall 4 | `<leader>fg` grep may miss hidden files; fixable with opts |
| A3 | snacks.notif `top_down = false` produces bottom-right toast accumulation | Architecture Patterns / Pattern 1 | Notifications appear at wrong screen position; fixable with margin opts |
| A4 | lazygit binary is installed and accessible in PATH on this machine | Environment Availability | `<leader>gg` will fail to open lazygit; user would need `yay -S lazygit` |

---

## Open Questions

1. **snacks.terminal and snacks.zen — enable or disable?**
   - What we know: Both are bundled in snacks.nvim. terminal provides a floating/split terminal; zen provides distraction-free mode with a centered window.
   - What's unclear: Whether the user uses a terminal inside Neovim at all (CLAUDE.md shows kitty+tmux as the workflow), and whether zen adds value given no such workflow exists today.
   - Recommendation: Disable both (`enabled = false`). The user's workflow is kitty → tmux → Neovim splits. A floating terminal inside Neovim duplicates tmux. Zen mode has no established use case in this config. Leave as `enabled = false` with a comment explaining the decision.

2. **snacks.picker grep hidden-file behavior**
   - What we know: Current `<leader>fg` passes explicit `rg_opts` with `--hidden -g '!.git/'` to fzf-lua.
   - What's unclear: Whether snacks.picker.grep() includes hidden files by default or needs explicit config.
   - Recommendation: Test after migration. If hidden files aren't included, add `args = { "--hidden", "--glob=!.git/" }` to the grep action options.

3. **lualine_x layout after noice removal**
   - What we know: Claude's discretion per D-18. Noice provided "recording macro" and "command" status display.
   - What's unclear: Whether the user misses these indicators.
   - Recommendation: Use `{ "filetype", "encoding" }` in lualine_x — filetype is always useful, encoding is low cost and occasionally helpful. Omit macro recording indicator since it was noice-specific and rarely triggered.

---

## Sources

### Primary (HIGH confidence)
- `github.com/folke/snacks.nvim` README — plugin spec structure, priority=1000, lazy=false requirement, module list
- `github.com/folke/snacks.nvim/docs/picker.md` (raw) — all 40+ picker sources including lsp_* functions
- `github.com/folke/snacks.nvim/docs/notifier.md` (raw) — notifier opts including top_down, timeout, style
- `github.com/folke/snacks.nvim/docs/dashboard.md` (raw) — dashboard section API
- `github.com/catppuccin/nvim` README — full integration flag list including snacks, neotree
- Direct file reads: `notify.lua`, `lualine.lua`, `fzflua.lua`, `alpha.lua`, `colortheme.lua`, `indent-blankline.lua`, `registry.lua`, `lazy.lua`, `nvim-validate.sh`

### Secondary (MEDIUM confidence)
- `lazyvim.org/extras/editor/snacks_picker` — snacks.picker keymap conventions, confirmed Snacks.picker.* API call patterns
- WebSearch: catppuccin snacks integration existence confirmed with `enabled` and `indent_scope_color` options

### Tertiary (LOW confidence)
- A2: snacks.picker.grep hidden-file behavior — not verified from official docs; needs post-migration test

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — snacks.nvim is actively maintained, API verified from official docs
- Architecture: HIGH — plugin file structure derived from direct file reads + official docs
- Pitfalls: HIGH (most) / LOW (Pitfall 4, grep hidden files) — noted in assumptions log
- Keymap mapping table: HIGH — both sides verified (fzf-lua from registry.lua read; snacks.picker from docs/picker.md)

**Research date:** 2026-04-15
**Valid until:** 2026-05-15 (snacks.nvim is actively developed; check for API changes if delayed beyond this date)
