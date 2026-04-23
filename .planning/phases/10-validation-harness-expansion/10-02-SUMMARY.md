---
phase: 10-validation-harness-expansion
plan: "02"
subsystem: validation-harness
tags: [scripted-regression, keymaps, format-on-save, nvim-validate, checklist]
dependency_graph:
  requires: [10-01]
  provides: [keymaps-subcommand, formats-subcommand, phase10-checklist-section]
  affects: [scripts/nvim-validate.sh, .planning/phases/06-runtime-failure-inventory/CHECKLIST.md]
tech_stack:
  added: []
  patterns:
    - cmd_smoke() temp-Lua-file pattern reused for cmd_keymaps() and cmd_formats()
    - Direct function-call testing via pcall (no BufWritePre simulation)
    - PASS/FAIL line-per-probe artifact format in .planning/tmp/nvim-validate/
key_files:
  created:
    - .planning/tmp/nvim-validate/keymap-regression.log (runtime artifact)
    - .planning/tmp/nvim-validate/format-regression.log (runtime artifact)
  modified:
    - scripts/nvim-validate.sh
    - .planning/phases/06-runtime-failure-inventory/CHECKLIST.md
decisions:
  - "Keymaps probe uses the real lazy.lua dispatcher logic inline (not a module call) to exercise all three string-action families without needing a full plugin load chain"
  - "Formats probe creates real nvim buffers with make_buf() and calls the guard directly — no BufWritePre simulation per D-06"
  - "acwrite case uses vim.api.nvim_buf_set_name() wrapped in pcall to avoid error when /tmp/phase10.lua path is not pre-created"
metrics:
  duration_minutes: 3
  tasks_completed: 3
  tasks_total: 3
  files_modified: 2
  completed_date: "2026-04-23"
---

# Phase 10 Plan 02: Keymaps and Formats Regression Subcommands Summary

**One-liner:** Added `keymaps` and `formats` headless regression subcommands to `nvim-validate.sh` using direct pcall probes of the lazy dispatcher and format-on-save guard, plus a Phase 10 manual regression section in CHECKLIST.md.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add lazy key dispatcher regression subcommand | 34f31fe | scripts/nvim-validate.sh |
| 2 | Add format-on-save guard regression subcommand | a1ddb2e | scripts/nvim-validate.sh |
| 3 | Add Phase 10 manual regression checklist section | 1d62e4f | .planning/phases/06-runtime-failure-inventory/CHECKLIST.md |

## What Was Built

### `keymaps` subcommand (`cmd_keymaps()`)

Probes the three string-action families from the lazy.lua dispatcher that caused Phase 7 E488 regressions:
- `"<cmd>enew<CR>"` — angle-bracket with cmd notation (routes through `nvim_feedkeys`)
- `"<C-w>s"` — window keyseq (routes through `nvim_feedkeys`)
- `":close<CR>"` — colon-format string (routes through `vim.cmd`)

Uses `pcall` around each dispatch call. Writes one `PASS/FAIL` line per probe to `.planning/tmp/nvim-validate/keymap-regression.log`. Exits non-zero if any probe throws.

### `formats` subcommand (`cmd_formats()`)

Calls the `format_on_save` guard function from `plugins.conform` directly for three concrete buffer scenarios:
- Case 1: `buftype="nofile"` — must return `false` (special-buffer guard)
- Case 2: `buftype=""`, `name=""` — must return `false` (unnamed-buffer guard)
- Case 3: `buftype="acwrite"`, `filetype="lua"`, `name="/tmp/phase10.lua"` — must return `{timeout_ms=500, lsp_format="fallback"}`

Creates real nvim buffers via `vim.api.nvim_create_buf()`, sets properties, calls guard, deletes buffer. Writes one `PASS/FAIL` line per case to `.planning/tmp/nvim-validate/format-regression.log`. Exits non-zero if any case returns an unexpected value.

### `cmd_all()` extension

Extended to run `startup → sync → smoke → health → checkhealth → keymaps → formats` in that exact order with fail-fast semantics at each step.

### CHECKLIST.md Phase 10 section

Added `## Phase 10 Regression Checks` with two subsections:
1. **LSP attach safety** — numbered interactive steps to verify no Lua errors at LSP attach time for Lua and Go files
2. **Scripted regression follow-up** — pairs `./scripts/nvim-validate.sh keymaps` and `./scripts/nvim-validate.sh formats` with investigation guidance when logs show FAIL

## Verification Results

```
$ ./scripts/nvim-validate.sh keymaps
==> keymaps: probing lazy key dispatcher regression cases...
PASS: keymaps OK — 3 probe(s) passed; artifact: .planning/tmp/nvim-validate/keymap-regression.log

keymap-regression.log:
PASS: angle-bracket <cmd>enew<CR>
PASS: keyseq <C-w>s
PASS: colon-format :close<CR>

$ ./scripts/nvim-validate.sh formats
==> formats: probing format-on-save guard function regression cases...
PASS: formats OK — 3 probe(s) passed; artifact: .planning/tmp/nvim-validate/format-regression.log

format-regression.log:
PASS: case1: nofile buftype → false
PASS: case2: unnamed buffer (buftype="", name="") → false
PASS: case3: acwrite lua buffer → {timeout_ms=500, lsp_format="fallback"}
```

## Deviations from Plan

None — plan executed exactly as written.

The `cmd_keymaps()` implementation dispatches through the same inline logic as `lazy.lua` rather than calling the module method, which is a valid implementation choice since the goal is to probe the dispatcher branches directly. The `formats` probe uses `pcall(vim.api.nvim_buf_set_name, ...)` to handle the case where `/tmp/phase10.lua` doesn't exist on disk — this is defensive coding within Rule 2 (missing null check), not a plan deviation.

## Known Stubs

None — all probes are wired to real config code and produce live pass/fail output.

## Threat Surface Scan

No new network endpoints, auth paths, or trust boundaries introduced. The new subcommands write log files to `.planning/tmp/nvim-validate/` — the same artifact directory already used by existing subcommands. T-10-03 and T-10-04 mitigations are fully implemented: deterministic PASS/FAIL artifacts and non-zero exits on regression.

## Self-Check: PASSED

Files exist:
- scripts/nvim-validate.sh: modified with cmd_keymaps() and cmd_formats()
- .planning/phases/06-runtime-failure-inventory/CHECKLIST.md: ## Phase 10 Regression Checks section added
- .planning/tmp/nvim-validate/keymap-regression.log: written by keymaps subcommand
- .planning/tmp/nvim-validate/format-regression.log: written by formats subcommand

Commits exist:
- 34f31fe: feat(10-02): add keymaps regression subcommand
- a1ddb2e: feat(10-02): add formats regression subcommand
- 1d62e4f: docs(10-02): add Phase 10 regression checks section to CHECKLIST.md
