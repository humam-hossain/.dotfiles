---
phase: "08-plugin-runtime-hardening"
plan: "02"
subsystem: "nvim-config"
tags: ["runtime-hardening", "lsp", "autosave", "format-on-save", "open-helper", "bug-fix"]
dependency_graph:
  requires:
    - "08-01: clean baseline (registry conflict removed, pyright wired, tbl_flatten gone)"
  provides:
    - "core/open.lua with direct vim.ui.open() tuple capture and real errmsg propagation"
    - "core/keymaps.lua FocusLost autosave gated on all five special-buffer guards"
    - "plugins/conform.lua format-on-save with fugitive/git filetypes added to exclusion list"
    - "plugins/lsp.lua LspAttach callback hardened against invalid client, invalid buffer, and non-file buftype"
  affects:
    - "Phase 8-03: BUG-03 re-verification can now exercise guarded save/format/LSP-attach paths"
tech_stack:
  added: []
  patterns:
    - "Direct vim.ui.open() return-tuple capture: (cmd, err) — no pcall wrapper"
    - "Guard-first autosave: buftype, modifiable, modified, bufname, filereadable all checked before write"
    - "Format-on-save exclusion list extended with fugitive and git filetypes"
    - "LspAttach triple-guard: valid client, nvim_buf_is_valid(), buftype == empty string"
key_files:
  created: []
  modified:
    - ".config/nvim/lua/core/open.lua"
    - ".config/nvim/lua/core/keymaps.lua"
    - ".config/nvim/lua/plugins/conform.lua"
    - ".config/nvim/lua/plugins/lsp.lua"
decisions:
  - "D-13: vim.ui.open() wrapped in pcall dropped real errmsg; replaced with direct (cmd, err) capture"
  - "D-14: LspAttach now gates on nvim_buf_is_valid() and buftype == '' before any buffer-local extras"
  - "D-14: FocusLost autosave uses filereadable-only check (drops redundant bufexists branch)"
  - "D-14: conform.lua adds fugitive/git to exclusion list; acwrite buftype remains allowed (commit messages)"
  - "No init-order fix needed in snacks.lua or misc.lua: no concrete reproducible init-order failure found"
metrics:
  duration_minutes: 3
  tasks_completed: 2
  tasks_total: 2
  files_modified: 4
  completed_date: "2026-04-22"
---

# Phase 8 Plan 02: Plugin Runtime Hardening — Crash-Prone Flow Guards Summary

**One-liner:** Replaced pcall-wrapped vim.ui.open() with direct tuple capture, tightened FocusLost autosave guards, extended format-on-save exclusion list with fugitive/git filetypes, and added nvim_buf_is_valid() + buftype checks to the LspAttach callback.

## Tasks Completed

| Task | Name | Commit | Key Files |
|------|------|--------|-----------|
| 1 | Guard external-open, autosave, and format-on-save | d5d923d | open.lua, keymaps.lua, conform.lua |
| 2 | Harden LspAttach and attach-time highlight behavior | 0398c38 | lsp.lua |

## What Was Built

### Task 1: External-Open, Autosave, and Format-on-Save Guards

**core/open.lua — D-13 direct tuple capture:**
- Removed `pcall(vim.ui.open, target)` wrapper; pcall discards `vim.ui.open()`'s second return value, replacing the real OS error string with an empty or Lua-generated exception message
- Replaced with `local cmd, err = vim.ui.open(target)` — the documented API contract
- `if err then notify_error("Failed to open: " .. err) end` surfaces the real OS/helper error
- `if not cmd then` fallback retained for the nil-cmd-with-no-error edge case

**core/keymaps.lua — D-14 FocusLost autosave tightening:**
- Switched from `vim.bo.buftype` (shorthand scoped to buffer 0) to `vim.bo[bufnr].buftype` (explicit buffer index) for correctness in async callbacks
- Removed the `vim.fn.bufexists(bufnr) == 1` branch; `filereadable(bufname) == 1` is the sole on-disk existence gate
- Added detailed inline comments enumerating every buffer kind that the buftype guard rejects: nofile, terminal, quickfix, fugitive, snacks picker previews

**plugins/conform.lua — D-14 format-on-save exclusion list extension:**
- Added `fugitive = true` and `git = true` to the filetype exclusion table
- `fugitive` covers the `:Gstatus`/`:Git` window; `git` covers blame and log buffers opened by vim-fugitive
- `acwrite` buftype remains allowed — this covers the fugitive commit-message buffer, which is a real file the user is intentionally writing
- Added per-guard comments explaining what each guard rejects and why

### Task 2: LspAttach Hardening

**plugins/lsp.lua — D-14 three-layer guard in LspAttach callback:**

Guard 1 (pre-existing, retained): `if not client then return end`
- `vim.lsp.get_client_by_id()` returns nil for already-detached or never-registered IDs
- Any client method call (e.g. `client:supports_method()`) would panic on a nil client

Guard 2 (new): `if not vim.api.nvim_buf_is_valid(event.buf) then return end`
- An async attach event can arrive after `:bdelete` has invalidated the buffer
- Invalid buffer handles throw E523 on any `nvim_buf_*` API call
- Must come before `attach.apply_lsp()` which calls `vim.keymap.set(..., { buffer = bufnr })`

Guard 3 (new): `if vim.bo[event.buf].buftype ~= "" then return end`
- Rejects nofile, terminal, quickfix, prompt, fugitive, and snacks picker preview buffers
- Prevents buffer-local LSP keymaps and document-highlight autocmds from attaching to ephemeral or plugin-managed buffers
- The highlight lifecycle (CursorHold, CursorMoved, LspDetach autocmds) is preserved unchanged behind these guards

**snacks.lua / misc.lua — no changes:**
- Read both files as required by the task spec
- No concrete reproducible plugin init-order failure found in either file
- snacks loads via `event = "VeryLazy"` which is after LSP; no ordering conflict exists
- Documented here instead of adding speculative patches (per plan instruction)

## Verification Results

| Check | Command | Result |
|-------|---------|--------|
| open.lua tuple capture | `rg -n 'local .*cmd.*,.*err.*vim\.ui\.open'` | PASS: line 22 |
| keymaps.lua/conform.lua buftype guards | `rg -n 'buftype\|modifiable\|bufname'` | PASS: all guard lines present |
| lsp.lua attach guards | `rg -n 'if not client\|nvim_buf_is_valid\|buftype'` | PASS: lines 142, 149, 158-159 |
| highlight lifecycle present | `rg -n 'document_highlight\|clear_references\|LspDetach'` | PASS: lines 174, 180, 183 |
| startup validator (Task 1) | `./scripts/nvim-validate.sh startup` | PASS |
| startup validator (Task 2) | `./scripts/nvim-validate.sh startup` | PASS |

## Deviations from Plan

### Auto-fixed Issues

None — plan executed exactly as written.

### Scope Decisions

**snacks.lua / misc.lua: no changes made**
- Plan instruction: "Read snacks.lua and misc.lua for plugin-init-order context, but keep this task's edits inside lsp.lua unless you find a concrete reproducible init-order failure; if no such failure exists, document that in the summary instead of widening the patch set."
- Outcome: No reproducible init-order failure found. snacks uses `event = "VeryLazy"`, which fires after LSP plugin setup. No patch applied.

## Known Stubs

None. All four files wire guards directly to runtime behavior. The `--- TODO:` file-header comments were pre-existing descriptive labels, not behavioral stubs.

## Threat Flags

All four threat register entries from the plan have been mitigated:

| Threat ID | Component | Mitigation Applied |
|-----------|-----------|-------------------|
| T-08-05 | core/keymaps.lua | FocusLost autosave now rejects special/unnamed/non-modifiable buffers via five explicit guards |
| T-08-06 | plugins/conform.lua | format-on-save exclusion list extended; all four guard clauses documented |
| T-08-07 | core/open.lua | Real vim.ui.open() errmsg now surfaces to user via direct tuple capture |
| T-08-08 | plugins/lsp.lua | LspAttach gated on valid client, valid buffer, and normal file buftype |

No new security-relevant surface introduced. All changes add guards to existing code paths.

## Self-Check: PASSED

**Files exist:**
- `.config/nvim/lua/core/open.lua` — FOUND
- `.config/nvim/lua/core/keymaps.lua` — FOUND
- `.config/nvim/lua/plugins/conform.lua` — FOUND
- `.config/nvim/lua/plugins/lsp.lua` — FOUND

**Commits exist:**
- d5d923d (Task 1) — FOUND
- 0398c38 (Task 2) — FOUND

**Acceptance criteria verified:**
- `rg 'local .*cmd.*,.*err.*vim\.ui\.open' open.lua` — PASS
- `rg 'buftype|modifiable|bufname' keymaps.lua conform.lua` — PASS (all guard lines present)
- `rg 'if not client then|nvim_buf_is_valid|buftype' lsp.lua` — PASS
- `rg 'document_highlight|clear_references|LspDetach' lsp.lua` — PASS
- `./scripts/nvim-validate.sh startup` — PASS (both tasks)
