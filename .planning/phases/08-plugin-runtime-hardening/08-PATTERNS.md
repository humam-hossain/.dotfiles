# Phase 08: plugin-runtime-hardening - Pattern Map

**Mapped:** 2026-04-22
**Files analyzed:** 6
**Analogs found:** 6 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.config/nvim/lua/core/keymaps/registry.lua` | config | event-driven | `.config/nvim/lua/plugins/misc.lua` | exact |
| `.config/nvim/lua/core/health.lua` | utility | file-I/O | `scripts/nvim-validate.sh` | dataflow-match |
| `.config/nvim/lua/core/open.lua` | utility | request-response | `.config/nvim/lua/plugins/conform.lua` | partial |
| `.config/nvim/lua/plugins/lsp.lua` | config | event-driven | `.config/nvim/lua/core/keymaps/attach.lua` | role-match |
| `.config/nvim/lazy-lock.json` | config | batch | `.config/nvim/lua/plugins/treesitter.lua` | partial |
| `.planning/phases/06-runtime-failure-inventory/FAILURES.md` | test | request-response | `.planning/phases/08-plugin-runtime-hardening/08-CONTEXT.md` | partial |

## Pattern Assignments

### `.config/nvim/lua/core/keymaps/registry.lua` (config, event-driven)

**Analog:** `.config/nvim/lua/plugins/misc.lua`

**Why this analog:** Phase 8 is deleting registry-owned mappings so a plugin can own its keyspace. `misc.lua` is where `vim-tmux-navigator` is already declared.

**Plugin ownership pattern** ([.config/nvim/lua/plugins/misc.lua](/home/pera/github_repo/.dotfiles/.config/nvim/lua/plugins/misc.lua:3), lines 3-8):
```lua
return {
	{
		-- Tmux & split window navigation
		"christoomey/vim-tmux-navigator",
	},
```

**Global mapping application pattern** ([.config/nvim/lua/core/keymaps/apply.lua](/home/pera/github_repo/.dotfiles/.config/nvim/lua/core/keymaps/apply.lua:13), lines 13-27):
```lua
function M.apply_global()
  local global_maps = registry.get_by_scope("global")

  for _, map in ipairs(global_maps) do
    local opts = map.opts or {}
    opts.desc = map.desc

    if type(map.action) == "string" then
      vim.keymap.set(map.mode, map.lhs, map.action, opts)
    elseif type(map.action) == "function" then
      vim.keymap.set(map.mode, map.lhs, map.action, opts)
    end
  end
end
```

**Concrete removal target** ([.config/nvim/lua/core/keymaps/registry.lua](/home/pera/github_repo/.dotfiles/.config/nvim/lua/core/keymaps/registry.lua:119), lines 119-159):
```lua
  -- Window navigation (preserved direct keys)
  {
    id = "window.move_up",
    lhs = "<C-k>",
    mode = "n",
    desc = "Move to window above",
    domain = "w",
    scope = "global",
    action = ":wincmd k<CR>",
    opts = { noremap = true, silent = true },
  },
  {
    id = "window.move_down",
    lhs = "<C-j>",
    ...
  },
  {
    id = "window.move_left",
    lhs = "<C-h>",
    ...
  },
  {
    id = "window.move_right",
    lhs = "<C-l>",
    ...
  },
```

**Planner instruction:** Copy the repo’s existing “plugin owns behavior-specific keys” pattern from `misc.lua`; do not replace these mappings with new guards or wrappers.

---

### `.config/nvim/lua/core/health.lua` (utility, file-I/O)

**Analog:** `scripts/nvim-validate.sh`

**Why this analog:** `core.health.snapshot()` is the Lua side of the same validation contract: collect probes, serialize output, and fail loudly on bad state.

**Probe list pattern** ([scripts/nvim-validate.sh](/home/pera/github_repo/.dotfiles/scripts/nvim-validate.sh:20), lines 20-23):
```bash
PLUGIN_LIST="{'snacks','lualine','neo-tree','lspconfig','conform','nvim-treesitter.configs','blink.cmp','gitsigns','ufo','bufferline','which-key','render-markdown'}"
TOOL_LIST="{'stylua','black','isort','prettierd','prettier','clang-format','shfmt','rg','git','node','go','clangd','gopls','lua-language-server'}"
```

**Snapshot assembly pattern** ([.config/nvim/lua/core/health.lua](/home/pera/github_repo/.dotfiles/.config/nvim/lua/core/health.lua:70), lines 70-117):
```lua
function M.snapshot(opts)
	opts = opts or {}
	local out_path = opts.out_path
	if type(out_path) ~= "string" or out_path == "" then
		vim.api.nvim_echo({ { "core.health.snapshot: opts.out_path required", "ErrorMsg" } }, true, {})
		return 1
	end

	local plugins = opts.plugins or {}
	local tools = opts.tools or {}
  ...
	local ok_enc, encoded = pcall(vim.json.encode, snapshot)
	if not ok_enc then
		vim.api.nvim_echo({ { "core.health.snapshot: json encode failed: " .. tostring(encoded), "ErrorMsg" } }, true, {})
		return 1
	end
  ...
	local fd, ferr = io.open(out_path, "w")
	if not fd then
		vim.api.nvim_echo({ { "core.health.snapshot: open failed: " .. tostring(ferr), "ErrorMsg" } }, true, {})
		return 1
	end
	fd:write(encoded)
	fd:close()
	return 0
end
```

**Probe helper pattern** ([.config/nvim/lua/core/health.lua](/home/pera/github_repo/.dotfiles/.config/nvim/lua/core/health.lua:26), lines 26-45):
```lua
local function probe_plugin(name)
	local ok, err = pcall(require, name)
	return {
		name = name,
		loaded = ok and true or false,
		error = (not ok) and tostring(err) or vim.NIL,
	}
end

local function probe_tool(name)
	local available = vim.fn.executable(name) == 1
	local path = available and vim.fn.exepath(name) or ""
```

**Planner instruction:** Keep the current probe/write/error structure intact; only align stale plugin names with the active stack. For Phase 8 that means removing `neo-tree` from the probe contract rather than adding compatibility logic.

---

### `.config/nvim/lua/core/open.lua` (utility, request-response)

**Analog:** `.config/nvim/lua/plugins/conform.lua`

**Why this analog:** `conform.lua` is the clearest local pattern for “guard inputs first, then call the API, return `false` on non-applicable buffers instead of throwing.”

**Guard-first pattern** ([.config/nvim/lua/plugins/conform.lua](/home/pera/github_repo/.dotfiles/.config/nvim/lua/plugins/conform.lua:16), lines 16-49):
```lua
format_on_save = function(bufnr)
	local bufname = vim.api.nvim_buf_get_name(bufnr)
	local ft = vim.bo[bufnr].filetype
	local buftype = vim.bo[bufnr].buftype

	if buftype ~= "" and buftype ~= "acwrite" then
		return false
	end

	if not vim.bo[bufnr].modifiable then
		return false
	end

	if bufname == "" then
		return false
	end
  ...
	return { timeout_ms = 500, lsp_format = "fallback" }
end
```

**Current error notification pattern** ([.config/nvim/lua/core/open.lua](/home/pera/github_repo/.dotfiles/.config/nvim/lua/core/open.lua:9), lines 9-29):
```lua
local function notify_error(msg)
	vim.notify(msg, vim.log.levels.ERROR, { title = "External Open" })
end

function M.open(target)
	if not target or target == "" then
		notify_error("No target provided to open")
		return
	end

	local success, err = pcall(vim.ui.open, target)
	if not success then
		notify_error("Failed to open: " .. tostring(err))
		return
	end

	if err == nil or err == false then
		notify_error("Could not open: " .. target)
		return
	end
end
```

**Current caller pattern** ([.config/nvim/lua/core/open.lua](/home/pera/github_repo/.dotfiles/.config/nvim/lua/core/open.lua:31), lines 31-40):
```lua
function M.open_current_buffer()
	local buf_name = vim.api.nvim_buf_get_name(0)
	if not buf_name or buf_name == "" then
		notify_error("No file in current buffer to open")
		return
	end

	local target = vim.fn.fnamemodify(buf_name, ":p")
	M.open(target)
end
```

**Planner instruction:** Preserve the existing `notify_error()` and guard shape, but switch from `pcall(vim.ui.open, ...)` to direct tuple capture so returned `errmsg` reaches the notification.

---

### `.config/nvim/lua/plugins/lsp.lua` (config, event-driven)

**Analog:** `.config/nvim/lua/core/keymaps/attach.lua`

**Why this analog:** Both files define attach-time behavior. `attach.lua` shows the repo’s current pattern for buffer-local work gated by `LspAttach` and a real client lookup.

**Attach guard pattern** ([.config/nvim/lua/core/keymaps/attach.lua](/home/pera/github_repo/.dotfiles/.config/nvim/lua/core/keymaps/attach.lua:77), lines 77-89):
```lua
function M.setup_lsp_attach()
  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("keymaps-attach-lsp", { clear = true }),
    callback = function(args)
      local bufnr = args.buf
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client then
        M.apply_lsp(bufnr)
      end
    end,
  })
end
```

**Current LSP server + Mason sync pattern** ([.config/nvim/lua/plugins/lsp.lua](/home/pera/github_repo/.dotfiles/.config/nvim/lua/plugins/lsp.lua:45), lines 45-105):
```lua
local lsp_servers = {
	bashls = { ... },
	marksman = {},
	clangd = {},
	gopls = {},
	ty = {},
	cssls = {},
	html = {},
	jsonls = {},
	jdtls = {},
	texlab = {},
	ts_ls = {},
	vimls = {},
	yamlls = {},
	lua_ls = {
		single_file_support = true,
	},
}

local mason_lsp_servers = {
	"bash-language-server",
	"marksman",
	"clangd",
	"gopls",
  ...
	"yaml-language-server",
	"lua-language-server",
}

local all_mason_packages = vim.list_extend(vim.list_extend({}, mason_lsp_servers), mason_tools)
require("mason-tool-installer").setup({ ensure_installed = all_mason_packages })
```

**Current attach safety pattern** ([.config/nvim/lua/plugins/lsp.lua](/home/pera/github_repo/.dotfiles/.config/nvim/lua/plugins/lsp.lua:132), lines 132-169):
```lua
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
	callback = function(event)
		local client = vim.lsp.get_client_by_id(event.data.client_id)
		if not client then
			return
		end

		attach.apply_lsp(event.buf)

		if
			client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf)
			and not vim.b[event.buf]._lsp_highlight_attached
		then
      ...
		end
	end,
})
```

**Existing unstaged delta to preserve** ([.config/nvim/lua/plugins/lsp.lua](/home/pera/github_repo/.dotfiles/.config/nvim/lua/plugins/lsp.lua:65), via `git diff`):
```diff
-			basedpyright = {},
...
-			"basedpyright",
```

**Planner instruction:** Keep LSP changes paired. Any provider swap must update both `lsp_servers` and `mason_lsp_servers`, and any Phase 8 hardening should follow the existing `client` nil-check boundary before buffer-local work.

---

### `.config/nvim/lazy-lock.json` (config, batch)

**Analog:** `.config/nvim/lua/plugins/treesitter.lua`

**Why this analog:** The lockfile change is not standalone; it should be traceable to the owning plugin spec and a single deprecation source.

**Owning plugin spec pattern** ([.config/nvim/lua/plugins/treesitter.lua](/home/pera/github_repo/.dotfiles/.config/nvim/lua/plugins/treesitter.lua:2), lines 2-8):
```lua
return { -- Highlight, edit, and navigate code
	"nvim-treesitter/nvim-treesitter",
	build = ":TSUpdate",
	main = "nvim-treesitter.configs",
	opts = {
```

**Current pinned entries** ([.config/nvim/lazy-lock.json](/home/pera/github_repo/.dotfiles/.config/nvim/lazy-lock.json:4), lines 4-4 and 21-21):
```json
"bufferline.nvim": { "branch": "main", "commit": "655133c3b4c3e5e05ec549b9f8cc2894ac6f51b3" },
"nvim-treesitter": { "branch": "master", "commit": "cf12346a3414fa1b06af75c79faebe7f76df080a" },
```

**Trace-before-bump evidence** (`rg` against installed plugins):
```text
/home/pera/.local/share/nvim/lazy/bufferline.nvim/lua/bufferline/utils/init.lua:279:function M.tbl_flatten(t) return is_version_11 and vim.iter(t):flatten(math.huge):totable() or vim.tbl_flatten(t) end
/home/pera/.local/share/nvim/lazy/nvim-treesitter/lua/nvim-treesitter/compat.lua:35:    return vim.tbl_flatten(t)
```

**Planner instruction:** Treat the lockfile as a surgical batch config edit. First identify the actual warning source from startup output, then update only that plugin’s pin. Do not plan a broad lockfile refresh.

---

### `.planning/phases/06-runtime-failure-inventory/FAILURES.md` (test, request-response)

**Analog:** `.planning/phases/08-plugin-runtime-hardening/08-CONTEXT.md`

**Why this analog:** Both files are operational planning artifacts that record status transitions, not code. The repo pattern is concise markdown with decision/status statements tied to file paths and bug IDs.

**Status table pattern** ([.planning/phases/06-runtime-failure-inventory/FAILURES.md](/home/pera/github_repo/.dotfiles/.planning/phases/06-runtime-failure-inventory/FAILURES.md:35), lines 35-51):
```md
| ID | Description | Owner | Status | Repro Steps / lhs | Provenance |
|----|-------------|-------|--------|-------------------|------------|
| BUG-001 | neo-tree plugin failed to load (module not found) | plugin | By Design | — | health |
...
| BUG-016 | `vim.tbl_flatten is deprecated` at startup/sync/smoke | unknown plugin dependency | Discovered | — | health |
| BUG-017 | vim-tmux-navigator `<C-h/j/k/l>` vs registry window.move_* | plugins/misc.lua + registry | Discovered | `<C-h/j/k/l>` | static |
```

**Disposition-note pattern** ([.planning/phases/06-runtime-failure-inventory/FAILURES.md](/home/pera/github_repo/.dotfiles/.planning/phases/06-runtime-failure-inventory/FAILURES.md:115), lines 115-127):
```md
**BUG-001:** neo-tree replaced by snacks.explorer in v1.0. Health snapshot still probes for it — health.lua should remove the probe.

**BUG-016:** `vim.tbl_flatten` deprecation visible in startup/smoke/sync logs. Origin is an unknown plugin dependency calling the deprecated API. Does not crash but produces noise.

**BUG-017:** `vim-tmux-navigator` and registry both define `<C-h/j/k/l>`.
```

**Decision artifact pattern** ([.planning/phases/08-plugin-runtime-hardening/08-CONTEXT.md](/home/pera/github_repo/.dotfiles/.planning/phases/08-plugin-runtime-hardening/08-CONTEXT.md:12), lines 12-23):
```md
### BUG-017: vim-tmux-navigator vs registry window navigation

- **D-01:** Remove the 4 `window.move_*` entries from `registry.lua`
- **D-02:** No `$TMUX` guard needed.
- **D-03:** vim-tmux-navigator stays installed
- **D-04:** FAILURES.md BUG-017 status → `Fixed`
```

**Planner instruction:** Update the existing row/disposition format in place. Do not introduce a new report structure; just transition BUG-001/016/017 statuses and notes with verification evidence.

## Shared Patterns

### Guard Before Side Effects
**Source:** [.config/nvim/lua/plugins/conform.lua](/home/pera/github_repo/.dotfiles/.config/nvim/lua/plugins/conform.lua:16)
**Apply to:** `core/open.lua`, `plugins/lsp.lua`, any Phase 8 autocmd review
```lua
if buftype ~= "" and buftype ~= "acwrite" then
	return false
end

if not vim.bo[bufnr].modifiable then
	return false
end

if bufname == "" then
	return false
end
```

### LSP Attach Safety Boundary
**Source:** [.config/nvim/lua/plugins/lsp.lua](/home/pera/github_repo/.dotfiles/.config/nvim/lua/plugins/lsp.lua:132)
**Apply to:** all LSP attach hardening in Plan 8-02
```lua
local client = vim.lsp.get_client_by_id(event.data.client_id)
if not client then
	return
end

attach.apply_lsp(event.buf)
```

### Plugin Owns Plugin-Specific Keys
**Source:** [.config/nvim/lua/plugins/misc.lua](/home/pera/github_repo/.dotfiles/.config/nvim/lua/plugins/misc.lua:3)
**Apply to:** `registry.lua` tmux-navigation conflict fix
```lua
{
	-- Tmux & split window navigation
	"christoomey/vim-tmux-navigator",
},
```

### Validation Contract Stays Centralized
**Source:** [scripts/nvim-validate.sh](/home/pera/github_repo/.dotfiles/scripts/nvim-validate.sh:161)
**Apply to:** `core/health.lua` and Phase 8 re-verification
```bash
nvim --headless \
	-u "$REPO_ROOT/.config/nvim/init.lua" \
	--cmd "set rtp^=$REPO_ROOT/.config/nvim" \
	+"lua local h=require('core.health'); local rc=h.snapshot({ out_path='$json', plugins=$PLUGIN_LIST, tools=$TOOL_LIST }); vim.cmd(rc==0 and 'qa!' or 'cq')" \
	> "$log" 2>&1
```

### User-Facing Errors Use `vim.notify`
**Source:** [.config/nvim/lua/core/open.lua](/home/pera/github_repo/.dotfiles/.config/nvim/lua/core/open.lua:9)
**Apply to:** `core/open.lua` runtime failures
```lua
local function notify_error(msg)
	vim.notify(msg, vim.log.levels.ERROR, { title = "External Open" })
end
```

## No Analog Found

None. Every scoped Phase 8 file has at least a workable local analog or owner pattern.

## Metadata

**Analog search scope:** `.config/nvim/lua/core/**`, `.config/nvim/lua/plugins/**`, `scripts/`, `.planning/phases/**`
**Files scanned:** 16
**Pattern extraction date:** 2026-04-22
