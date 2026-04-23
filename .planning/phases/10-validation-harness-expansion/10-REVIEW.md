---
phase: 10-validation-harness-expansion
reviewed: 2026-04-23T13:39:32Z
depth: standard
files_reviewed: 4
files_reviewed_list:
  - .config/nvim/README.md
  - .config/nvim/lua/core/keymaps/whichkey.lua
  - .config/nvim/lua/plugins/conform.lua
  - scripts/nvim-validate.sh
findings:
  critical: 1
  warning: 3
  info: 4
  total: 8
status: issues_found
---

# Phase 10: Code Review Report

**Reviewed:** 2026-04-23T13:39:32Z
**Depth:** standard
**Files Reviewed:** 4
**Status:** issues_found

## Summary

Four files were reviewed: the validation harness shell script, the conform.nvim plugin spec, the which-key registration module, and the Neovim README. The shell script introduced two new subcommands (`keymaps`, `formats`) and wired them into `all`. The Lua source files are structurally clean.

One critical bug was found: the smoke probe writes its failure sentinel to a bare relative path (`SMOKE_FAIL` in nvim's cwd) but the shell checks a different absolute path (`$REPORT_DIR/SMOKE_FAIL`). This is a silent failure bypass — the probe can fail and the harness reports PASS. The bug is confirmed by the presence of a stray `SMOKE_FAIL` file at the repo root in the current working tree.

Three warnings cover: a dead function in `lazy.lua` whose plugin filter never matches (fold_keys), an unrecognised option key nested inside `default_format_options` in conform.lua, and missing error-exit after `pcall` failure in the formats probe Lua script.

Four info items cover stale documentation, a TODO comment left in source, and minor inconsistencies in the README.

---

## Critical Issues

### CR-01: `cmd_smoke` SMOKE_FAIL sentinel is written to wrong path — failure is silently ignored

**File:** `scripts/nvim-validate.sh:364` and `scripts/nvim-validate.sh:389`

**Issue:** The embedded Lua script writes the failure file with a bare relative path:

```lua
local f = io.open('SMOKE_FAIL', 'w')
```

`nvim --headless` inherits the shell's working directory (wherever the caller invoked the script from, typically the repo root). The file therefore lands at `$PWD/SMOKE_FAIL`. The shell check on line 389 looks for it at `$REPORT_DIR/SMOKE_FAIL` (`.planning/tmp/nvim-validate/SMOKE_FAIL`). Because the paths never match, a real plugin load failure causes `cq` (non-zero exit) but nvim's exit code is also checked at line 397 — however the Lua script calls `vim.cmd('cq')` *after* writing SMOKE_FAIL, so the shell falls through to the `rc != 0` branch at line 397 and reports FAIL via that path instead. The SMOKE_FAIL file then persists in the repo root across runs, and on the *next* run a stale file at the repo root could mislead diagnosis. More importantly, if any future code path changes the exit handling, the misrouted sentinel becomes a silent bypass.

The bug is already observable: `SMOKE_FAIL` exists at the repo root in the current worktree with a real neo-tree load error, indicating a previous smoke failure left the artifact in the wrong place.

**Fix:** Pass the target path to the Lua script via an environment variable (consistent with how `KEYMAP_LOG` and `FORMAT_LOG` are handled in the other two probes):

```bash
# in cmd_smoke, before the nvim invocation:
SMOKE_FAIL_PATH="$REPORT_DIR/SMOKE_FAIL" nvim --headless \
    -u "$REPO_ROOT/.config/nvim/init.lua" \
    --cmd "set rtp^=$REPO_ROOT/.config/nvim" \
    -l "$lua_tmp" \
    > "$log" 2>&1
```

In the Lua script, replace the bare path:

```lua
local smoke_fail_path = vim.fn.expand(os.getenv('SMOKE_FAIL_PATH') or '')
-- ...
local f = io.open(smoke_fail_path, 'w')
```

Also clean up any stale `SMOKE_FAIL` file from the repo root and add it to `.gitignore`.

---

## Warnings

### WR-01: `fold_keys()` plugin filter never matches — always returns empty table

**File:** `.config/nvim/lua/core/keymaps/lazy.lua:113`

**Issue:** `fold_keys()` filters registry entries with:

```lua
if map.plugin == "ufo" then
```

But every fold mapping in `registry.lua` declares:

```lua
plugin = "kevinhwang91/nvim-ufo",
```

The string `"ufo"` never equals `"kevinhwang91/nvim-ufo"`, so `fold_keys()` always returns `{}`. Any plugin spec that calls `require("core.keymaps.lazy").fold_keys()` silently gets no key triggers, meaning `zR`, `zM`, and `zK` are never registered as lazy-load triggers for ufo.

**Fix:** Align the filter string with the registry value:

```lua
-- lazy.lua line 113
if map.plugin == "kevinhwang91/nvim-ufo" then
```

Or, for a more robust approach, match on the plugin's short name suffix:

```lua
if map.plugin:match("nvim%-ufo$") then
```

---

### WR-02: `default_format_options.format_on_save = true` is not a recognized conform.nvim option

**File:** `.config/nvim/lua/plugins/conform.lua:64-65`

**Issue:** The `default_format_options` table is passed to conform's formatter calls as default options. The valid keys for this table are formatter-level options such as `timeout_ms`, `lsp_format`, `quiet`, `stop_after_first`, and formatter-specific passthrough flags. The key `format_on_save` is not a formatter option — it is a top-level conform.nvim setup key. Placing it inside `default_format_options` makes it a no-op: conform ignores unknown keys silently.

```lua
default_format_options = {
    trim_trailing_whitespace = true,
    format_on_save = true,  -- no-op: not a valid formatter option
},
```

`trim_trailing_whitespace` is also not a standard conform option key (it belongs to editorconfig/LSP layer) and will likewise be silently ignored.

**Fix:** Remove the `format_on_save` key entirely (format-on-save is already controlled by the `format_on_save` function above). If trailing whitespace trimming is desired, handle it in the formatter config or via an autocmd:

```lua
default_format_options = {
    timeout_ms = 500,
    lsp_format = "fallback",
},
```

---

### WR-03: Missing early return after `pcall` failure in `cmd_formats` Lua probe

**File:** `scripts/nvim-validate.sh:551-562`

**Issue:** After the `pcall(require, 'plugins.conform')` failure branch, the script writes the log and calls `vim.cmd('cq')` but does not `return`. Execution continues to the `local guard = spec and spec.opts and spec.opts.format_on_save` line where `spec` is the error string (not a table), so `spec.opts` raises a Lua error (indexing a string). In practice, `cq` terminates nvim before the next line runs, so the extra line is dead code — but this is fragile: if `vim.cmd('cq')` ever yields (e.g., during a pcall-wrapped test run) the subsequent code path crashes instead of exiting cleanly.

The same pattern appears in the guard-type check block at line 558-562.

**Fix:** Add explicit `return` after each `vim.cmd('cq')` call in the failure branches:

```lua
if not ok then
  local msg = 'FAIL: could not load plugins.conform: ' .. tostring(spec)
  table.insert(lines, msg)
  io.stderr:write(msg .. '\n')
  vim.fn.writefile(lines, log_path)
  vim.cmd('cq')
  return  -- guard against fall-through if cq is intercepted
end
```

Apply the same fix to the guard-type check block at line 556.

---

## Info

### IN-01: Stale `--- TODO:` comment left in production source

**File:** `.config/nvim/lua/core/keymaps/whichkey.lua:1`

**Issue:** The file begins with `--- TODO: Which-key group registration ---`. This is a leftover planning artifact from when the file was scaffolded. The implementation is complete; the TODO is misleading.

**Fix:** Remove line 1 or replace it with a standard module docstring matching the style used elsewhere (e.g., `-- KEYMAP WHICHKEY - …`).

---

### IN-02: README documents stale `<leader>cf` keybinding that does not exist in the registry

**File:** `.config/nvim/README.md:100` and `.config/nvim/README.md:236`

**Issue:** Two locations document `<leader>cf` as the manual format trigger:

- Line 100 (Phase 4 change summary): "`<leader>cf` manual format"
- Line 236 (Save-Format Policy section): "**Manual format**: `<leader>cf` forces format without saving"

The actual registry (`registry.lua`) has no `<leader>cf` binding. The current format-and-save key is `<C-s>` (`save.format_and_write`). There is no standalone "format without saving" keybinding in the registry.

**Fix:** Update both occurrences to reflect the actual binding, or document that no standalone format-only binding exists.

---

### IN-03: README Smoke Checklist has a malformed list item and wrong keymap

**File:** `.config/nvim/README.md:443`

**Issue:** Item 5 of the Smoke Checklist reads:

```
. **Split close**: Press `<leader>xs>` - should close only current split
```

Two problems:
1. The list number is missing (`. ` instead of `5. `).
2. The keymap has a stray `>` at the end: `<leader>xs>` should be `<leader>xs`.

**Fix:**

```markdown
5. **Split close**: Press `<leader>xs` - should close only current split
```

---

### IN-04: README has three inconsistent descriptions of what `all` runs

**File:** `.config/nvim/README.md:81`, `.config/nvim/README.md:113`, `.config/nvim/README.md:255`

**Issue:** The README describes the `all` subcommand in multiple places with conflicting scope:

- Line 81 (Machine Update Checklist step 5): "runs `startup`, `sync`, `smoke`, and `health` in order" — missing `checkhealth`, `keymaps`, `formats`
- Line 113 (Post-Deploy Verification step 1): "runs `startup`, `sync`, `smoke`, `health`, and `checkhealth`" — missing `keymaps`, `formats`
- Line 255 (Phase 4 Validation Commands table): "`startup → sync → smoke → health → checkhealth`" — missing `keymaps`, `formats`
- Line 330 (Phase 3 Entrypoint table): correct — "`startup → sync → smoke → health → checkhealth → keymaps → formats`"

The script itself (line 731) confirms the full 7-step sequence.

**Fix:** Update lines 81, 113, and 255 to match the current 7-step sequence: `startup → sync → smoke → health → checkhealth → keymaps → formats`.

---

_Reviewed: 2026-04-23T13:39:32Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
