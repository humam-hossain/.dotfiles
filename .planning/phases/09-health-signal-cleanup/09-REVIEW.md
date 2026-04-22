---
phase: 09-health-signal-cleanup
reviewed: 2026-04-23T00:00:00Z
depth: standard
files_reviewed: 33
files_reviewed_list:
  - .config/.tmux.conf
  - .config/nvim/.luarc.json
  - .config/nvim/README.md
  - .config/nvim/init.lua
  - .config/nvim/lazy-lock.json
  - .config/nvim/lua/config/health.lua
  - .config/nvim/lua/core/health.lua
  - .config/nvim/lua/core/keymaps.lua
  - .config/nvim/lua/core/keymaps/apply.lua
  - .config/nvim/lua/core/keymaps/attach.lua
  - .config/nvim/lua/core/keymaps/lazy.lua
  - .config/nvim/lua/core/keymaps/registry.lua
  - .config/nvim/lua/core/keymaps/whichkey.lua
  - .config/nvim/lua/core/open.lua
  - .config/nvim/lua/core/options.lua
  - .config/nvim/lua/plugins/blink-cmp.lua
  - .config/nvim/lua/plugins/bufferline.lua
  - .config/nvim/lua/plugins/colortheme.lua
  - .config/nvim/lua/plugins/conform.lua
  - .config/nvim/lua/plugins/git.lua
  - .config/nvim/lua/plugins/lsp.lua
  - .config/nvim/lua/plugins/lualine.lua
  - .config/nvim/lua/plugins/misc.lua
  - .config/nvim/lua/plugins/project.lua
  - .config/nvim/lua/plugins/snacks.lua
  - .config/nvim/lua/plugins/treesitter.lua
  - .config/nvim/lua/plugins/ufo.lua
  - .config/nvim/lua/plugins/vim-indent-object.lua
  - AGENTS.md
  - arch/nvim.sh
  - debian/nvim.sh
  - scripts/nvim-audit-failures.sh
  - scripts/nvim-validate.sh
  - ubuntu/nvim.sh
findings:
  critical: 0
  warning: 7
  info: 8
  total: 15
status: issues_found
---

# Phase 09: Code Review Report

**Reviewed:** 2026-04-23T00:00:00Z
**Depth:** standard
**Files Reviewed:** 33
**Status:** issues_found

## Summary

This phase adds a `config.health` provider (`:checkhealth config`), a `core.health` compatibility shim, the `core.open` external-file helper, the `section_known_environment_gaps` health section, and BUG-019 tmux companion bindings. Supporting scripts (`nvim-validate.sh`, `nvim-audit-failures.sh`) and install scripts are also in scope.

The code is generally well-structured with consistent pcall guards throughout the health provider. The most actionable findings are:

- A dead keymap dispatch branch in `keymaps/lazy.lua` and `keymaps/apply.lua` that silently does nothing when a registry entry has neither a string nor a function action.
- A `SMOKE_FAIL` file written to the repo working directory (`$CWD`) instead of the report directory, leaving behind an untracked file on failure.
- A window-picker keymap that extracts a window ID with `tonumber` but does not guard against a `nil` parse result.
- An `all_ok` flag in `section_optional_tools` that is set to `false` on any missing tool but only emits `ok("All optional tools available")` when the flag is still `true` — the positive-case message fires even when `all_ok` was never touched because the loop body always falls into the `if not meta.required` branch correctly, but the flag name is misleading and the `ok()` call runs while still inside the pcall body.
- Minor stale documentation and shell robustness issues.

No security vulnerabilities, hardcoded secrets, or data-loss risks were found.

---

## Warnings

### WR-01: `SMOKE_FAIL` written to CWD, not to the report directory

**File:** `scripts/nvim-validate.sh:351-356`
**Issue:** The Lua smoke script writes the failure sentinel to a bare relative path `'SMOKE_FAIL'`. When nvim is invoked from the repo root (the usual case), this creates `.dotfiles/SMOKE_FAIL` — a file visible in `git status` and already present as an untracked file in the current tree. The companion shell check on line 377 looks for `$REPORT_DIR/SMOKE_FAIL`, so the file is never found there and the failure is silently swallowed; the script falls through to the exit-code check instead.

The two paths are inconsistent: the Lua writes to `$CWD/SMOKE_FAIL`, but the shell reads `$REPORT_DIR/SMOKE_FAIL`.

**Fix:**
```lua
-- Pass the full report-dir path into the Lua script via a variable substitution,
-- the same way cmd_checkhealth passes `artifact`.
local f = io.open('$REPORT_DIR/SMOKE_FAIL', 'w')
```
Or inject the path via the here-doc expansion before writing to the temp file:
```bash
lua_script=$(cat <<LUA
local smoke_fail = '$REPORT_DIR/SMOKE_FAIL'
...
  local f = io.open(smoke_fail, 'w')
LUA
)
```

---

### WR-02: Dead dispatch branch — `apply_global` / `apply_by_id` silently no-ops on invalid action type

**File:** `scripts/nvim/lua/core/keymaps/apply.lua:21-26` and `apply.lua:39-44`
**Issue:** Both `apply_global` and `apply_by_id` check `type(map.action) == "string"` and `type(map.action) == "function"` but have no `else` branch. A registry entry whose `action` is `nil` or another unexpected type is silently skipped with no warning. Because the registry is hand-edited, this failure mode is hard to detect; the mapping will simply not exist at runtime.

**Fix:**
```lua
if type(map.action) == "string" or type(map.action) == "function" then
  vim.keymap.set(map.mode, map.lhs, map.action, opts)
else
  vim.notify(
    string.format("[keymaps.apply] mapping '%s' has invalid action type: %s", map.lhs, type(map.action)),
    vim.log.levels.WARN
  )
end
```
The same pattern applies in `keymaps/lazy.lua` inside `get_keys()` (lines 22-43) and `fold_keys()` (lines 117-130): the outermost `if ok and mod and mod[map.action]` chain has no final `else` to warn about unresolvable actions.

---

### WR-03: Window picker parses window ID with unguarded `tonumber`

**File:** `.config/nvim/lua/core/keymaps/registry.lua:352-354`
**Issue:** The window picker action extracts the window ID with `choice:match("Window (%d+)")` and passes the result to `tonumber`. If `match` returns `nil` (e.g., the choice string format changed) `win_id` is `nil` and `vim.api.nvim_set_current_win(nil)` will throw an error.

```lua
local win_id = tonumber(choice:match("Window (%d+)"))
if win_id then
  vim.api.nvim_set_current_win(win_id)
end
```
The inner `if win_id` guard only covers `tonumber` returning `nil`; it does not prevent the pattern from returning `nil` first and crashing `tonumber(nil)`. `tonumber(nil)` is actually valid Lua and returns `nil`, so this is safe — but if `choice` itself were `nil` the `match` call would crash. `vim.ui.select` passes `nil` to the callback when the user cancels, but that is already caught by the outer `if choice` guard. The actual bug is more subtle: `choice:match("Window (%d+)")` returns `nil` for any unexpected format, and `tonumber(nil)` quietly yields `nil`, so `nvim_set_current_win` is never called. No crash, but also no navigation. A `vim.notify` on the nil case would make the silent failure visible.

**Fix:**
```lua
vim.ui.select(choices, { prompt = "Pick window:" }, function(choice)
  if not choice then return end
  local win_id = tonumber(choice:match("Window (%d+)"))
  if win_id then
    vim.api.nvim_set_current_win(win_id)
  else
    vim.notify("[window.picker] could not parse window ID from: " .. choice, vim.log.levels.WARN)
  end
end)
```

---

### WR-04: `section_optional_tools` `all_ok` message fires even when tools are missing (misleading positive signal)

**File:** `.config/nvim/lua/config/health.lua:81-104`
**Issue:** The `all_ok` variable is initialized to `true` and set to `false` only inside the `else` branch (tool unavailable). The `vim.health.ok("All optional tools available")` at line 99 will fire if every tool entry is available. This logic is correct. However, there is a subtle issue: `all_ok` is checked after the loop at line 98 (`if all_ok then`), which means if the tool loop body calls `vim.health.ok()` for each available tool AND then also calls `vim.health.ok("All optional tools available")`, the section emits one summary `ok` line on top of the per-tool `ok` lines. This doubles up the positive signal. More importantly, if a tool is missing (`all_ok = false`), the summary line is suppressed — but no summary line says "some optional tools are missing." A reader scanning `:checkhealth config` sees only `warn` lines with no closing summary. Consider adding an `else` path:

**Fix:**
```lua
if all_ok then
  vim.health.ok("All optional tools available")
else
  vim.health.ok("Optional tools check complete — see warnings above for missing tools")
end
```

---

### WR-05: `LspDetach` autocmd uses `clear = true` and may clobber other handlers

**File:** `.config/nvim/lua/plugins/lsp.lua:183-188`
**Issue:** The `LspDetach` autocmd is created with `vim.api.nvim_create_augroup("kickstart-lsp-detach", { clear = true })`. Using `clear = true` inside a per-buffer `LspAttach` callback means every time any LSP client attaches to any buffer, the `kickstart-lsp-detach` group is cleared and recreated. If two LSP clients attach to the same buffer, the `LspDetach` handler registered for the first client is erased before the second client triggers `LspDetach`. This means `clear_references` may not fire reliably when the first client detaches from a multi-LSP buffer.

**Fix:** Use `clear = false` for the LspDetach group so handlers accumulate rather than reset, or scope the group name per-buffer:
```lua
vim.api.nvim_create_autocmd("LspDetach", {
  group = vim.api.nvim_create_augroup("kickstart-lsp-detach", { clear = false }),
  ...
})
```

---

### WR-06: `debian/nvim.sh` does not remove the old `/opt/nvim` before extracting

**File:** `debian/nvim.sh:17`
**Issue:** `arch/nvim.sh` is not affected (it uses `pacman`), but `debian/nvim.sh` lacks the `sudo rm -rf /opt/nvim` step that `ubuntu/nvim.sh` correctly adds on line... actually checking: `ubuntu/nvim.sh` at line 17 does `sudo mv nvim-linux-x86_64 /opt/nvim` (no `rm -rf`), while `debian/nvim.sh` also does `sudo mv -fv nvim-linux-x86_64 /opt/nvim` (adds `-f` and `-v` flags). Neither script removes the old installation before moving the new one in, but `mv -f` over an existing directory will fail: `mv` does not overwrite a non-empty destination directory with `-f` — it moves the source *inside* the destination. The result on a re-run is `/opt/nvim/nvim-linux-x86_64/` rather than `/opt/nvim/`, and the symlink on line 18/19 (`/opt/nvim/bin/nvim`) breaks.

`debian/nvim.sh` has the correct guard (`sudo rm -rf /opt/nvim`) that `ubuntu/nvim.sh` is missing.

Wait — re-reading: `debian/nvim.sh` line 17 is `sudo rm -rf /opt/nvim` and line 18 is `sudo mv -fv nvim-linux-x86_64 /opt/nvim`. `ubuntu/nvim.sh` line 17 is `sudo mv nvim-linux-x86_64 /opt/nvim` with NO preceding `rm -rf`. So `ubuntu/nvim.sh` is the one with the bug.

**Fix in `ubuntu/nvim.sh`:**
```bash
sudo rm -rf /opt/nvim
sudo mv nvim-linux-x86_64 /opt/nvim
sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
```

---

### WR-07: `nvim-validate.sh` `cmd_checkhealth` uses internal `vim.health._check` API

**File:** `scripts/nvim-validate.sh:269`
**Issue:** The headless checkhealth invocation calls `require('vim.health')._check('', '')`. The `_check` function is an underscore-prefixed internal, not part of the documented public API. Neovim may rename or remove it in a future release. The current Neovim 0.12 target has a stable `:checkhealth` path via `vim.cmd('checkhealth')` in headless mode. The buffer-capture approach works today but is fragile.

This is a maintainability concern rather than an immediate breakage. No immediate fix is required, but worth tracking if a future Neovim upgrade breaks headless checkhealth capture.

**Suggested alternative to track:** `:checkhealth` in headless mode writes to a buffer that can be captured via `:w` to a file, which avoids calling internal APIs.

---

## Info

### IN-01: `section_known_environment_gaps` always emits `warn` regardless of environment state

**File:** `.config/nvim/lua/config/health.lua:176-214`
**Issue:** The section unconditionally emits two `vim.health.warn()` items — tmux companion bindings and Linux external-open — even on machines where tmux is not used or the bindings are already correctly configured. The comment at line 176 acknowledges this ("always rendered unconditionally"). This is a design choice, not a bug, but it means `:checkhealth config` will always show warnings. Users who have already applied the tmux fix will see a persistent false-positive warning that they cannot silence without editing the health provider. Consider adding an active probe (e.g., check `$TMUX`, check whether the tmux bindings are actually present) so the section shows `ok` when the environment is correctly configured.

---

### IN-02: Stale references to removed plugins in `AGENTS.md` and `README.md`

**File:** `AGENTS.md:76-83` and `README.md:61`
**Issue:** `AGENTS.md` references `ibhagwan/fzf-lua`, `nvim-neo-tree/neo-tree.nvim`, `folke/noice.nvim`, `rcarriga/nvim-notify`, and `notify.lua`/`neotree.lua`/`fzflua.lua` as current key dependencies. These plugins were removed in Phase 5 and replaced by `folke/snacks.nvim`. `README.md` also still mentions `neo-tree` in the `:checkhealth` guidance section (line 123). These stale references would mislead an agent or maintainer debugging a missing-plugin error.

---

### IN-03: `file.jump_forward` mapping is a no-op identity remap

**File:** `.config/nvim/lua/core/keymaps/registry.lua:231-238`
**Issue:** The `file.jump_forward` entry maps `<C-i>` to `<C-i>` with `noremap = true`. A noremap mapping whose action is the same key as the lhs is effectively a no-op that prevents the original `<C-i>` (jump list forward) from being remapped by plugins, but it adds nothing functionally. The comment in the registry is absent, so the intent is unclear. If the goal is to protect `<C-i>` from plugin remapping, this is correct but should have a comment. If the goal was to bind jump-forward to something else, the action is wrong.

---

### IN-04: `search.WORD` and `search.word` are duplicates

**File:** `.config/nvim/lua/core/keymaps/registry.lua:488-496`
**Issue:** `search.word` (`<leader>fw`) and `search.WORD` (`<leader>fW`) both call `Snacks.picker.grep_word()` with no difference in arguments. The distinction between `word` and `WORD` in Vim typically means `<cword>` vs `<cWORD>` (current word vs WORD under cursor). If `Snacks.picker.grep_word` already handles both via its own detection, the duplicate is harmless but confusing. If it was intended to pass a `WORD` variant, the action should differ.

---

### IN-05: `nvim-audit-failures.sh` `derive_owner` uses unquoted `echo … | grep` for path matching

**File:** `scripts/nvim-audit-failures.sh:175-199`
**Issue:** The `derive_owner` function uses `echo "$file" | grep -qE '...'` patterns. With `set -euo pipefail`, a failed `grep` (exit 1 = no match) inside a command substitution used in a conditional is fine, but the pattern is fragile and non-standard. `case` statements or `[[ "$file" =~ ... ]]` would be safer and avoid subshell overhead. Not a runtime correctness bug given the `if/elif` chain structure, but worth noting for maintainability.

---

### IN-06: `TODO` stub comments in production module headers

**File:** Multiple files: `keymaps.lua:1`, `apply.lua:1`, `attach.lua:1`, `lazy.lua:1`, `registry.lua:1`, `whichkey.lua:1`, `open.lua:1`, `options.lua:1`, various plugin files
**Issue:** Every Lua file in the config starts with `--- TODO: <description> ---`. These are currently used as section titles/file-level doc strings rather than actual action items, but they will trigger any TODO scanner (including `nvim-audit-failures.sh`'s own `scan_todo_fixme`) and inflate the failure inventory with false positives. Consider converting them to standard comments (`-- Description: ...`) or removing the `TODO:` prefix if no action is pending.

---

### IN-07: `keymaps/lazy.lua` `fold_keys` duplicates the dispatch logic from `get_keys`

**File:** `.config/nvim/lua/core/keymaps/lazy.lua:110-140`
**Issue:** `fold_keys()` reimplements the same plugin-module dispatch closure that already exists in `get_keys()`, adding ~30 lines of duplicated code. The only difference is that `fold_keys` filters by `map.plugin == "ufo"`. This could be replaced with `M.get_keys()` filtered by plugin:

```lua
function M.fold_keys()
  local lazy_maps = registry.get_by_scope("lazy")
  local keys = {}
  for _, map in ipairs(lazy_maps) do
    if map.plugin == "kevinhwang91/nvim-ufo" then
      table.insert(keys, M._build_key_spec(map))
    end
  end
  return keys
end
```
Note: the filter in `fold_keys` checks `map.plugin == "ufo"` (line 113) but the registry entries use `plugin = "kevinhwang91/nvim-ufo"` (lines 641, 651, 661). This mismatch means `fold_keys` returns an empty table, and the fold keymaps in `ufo.lua` (line 40-42) bind unresolvable specs. The fold keymaps registered in the registry do call their action directly as a function closure (lines 642-670), so the ufo config's inline `for` loop over `fold_keys()` silently binds nothing.

**This is the most impactful info-level finding**: fold keymaps from the registry are not being applied via `fold_keys()` due to the plugin name mismatch. The keymaps work at startup only because the registry entries use inline function closures that are called directly — but the `ufo.lua` binding loop is dead code.

---

### IN-08: `section_config_guards` duplicates the Neovim version check from `section_neovim_version`

**File:** `.config/nvim/lua/config/health.lua:135-173`
**Issue:** `section_config_guards` re-checks `vim.version.cmp(ver, { 0, 12, 0 })` at line 141, which is the same check already performed in `section_neovim_version` (line 33). The check runs twice and emits an `ok` or `error` twice for the same condition. This doubles the noise in `:checkhealth config` output for the version gate. One of the two should be removed, or the guards section should skip the version check and focus exclusively on infrastructure reachability checks.

---

_Reviewed: 2026-04-23T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
