---
phase: 10-validation-harness-expansion
plan: "01"
subsystem: validation-harness
tags: [docs, harness-contract, conform, cleanup]
dependency_graph:
  requires: []
  provides:
    - Phase 10 validation command contract in README
    - Clean conform.lua format_on_save guard source (no stale banner)
  affects:
    - .config/nvim/README.md
    - .config/nvim/lua/plugins/conform.lua
tech_stack:
  added: []
  patterns:
    - Phase 3 validation table extended to cover Phase 10 subcommands
key_files:
  created: []
  modified:
    - .config/nvim/README.md
    - .config/nvim/lua/plugins/conform.lua
decisions:
  - D-01: PLUGIN_LIST and TOOL_LIST confirmed accurate; pyright already replaced basedpyright, neo-tree probe already removed — no harness-list correction needed
  - D-02: Artifact contract defined in README before scripts written — keymap-regression.log and format-regression.log in .planning/tmp/nvim-validate/
  - D-03: Stale TODO banner removed from conform.lua line 1; guard logic untouched
  - D-04: Phase 3 README table updated — checkhealth row added, all sequence updated to include checkhealth, keymaps, formats
metrics:
  duration: ~7 minutes
  completed: 2026-04-23
  tasks_completed: 2
  files_modified: 2
---

# Phase 10 Plan 01: Validator Alignment Audit + Contract Definition Summary

**One-liner:** Phase 3 validation table and artifact contract updated to Phase 10 v1.1 spec; stale conform.lua TODO banner removed.

## What Was Done

### Task 1: Audit the existing harness contract against v1.1 decisions

Audited `scripts/nvim-validate.sh` against D-01: confirmed PLUGIN_LIST already excludes neo-tree and TOOL_LIST already reflects the pyright-era Phase 8 state — no harness-list correction needed.

Updated the Phase 3 validation table in `.config/nvim/README.md`:
- Added `checkhealth` row (was missing from Phase 3 table, only present in Phase 4 table)
- Added `keymaps` row with artifact reference (`keymap-regression.log`)
- Added `formats` row with artifact reference (`format-regression.log`)
- Updated `all` description from "startup, sync, smoke, health" to full Phase 10 sequence: `startup → sync → smoke → health → checkhealth → keymaps → formats`

Extended the Report Output list with:
- `checkhealth.txt` — full rendered `:checkhealth` output
- `keymap-regression.log` — per-action-type pcall results from the keymap dispatcher probe
- `format-regression.log` — per-buffer-context guard return values from the format-on-save probe

**Commit:** 288fa10

### Task 2: Remove stale Phase 10 TODO noise from the format-on-save source

Removed the line `--- TODO: Format-on-save dispatcher - conform.nvim ---` from the top of `.config/nvim/lua/plugins/conform.lua` (D-03 literal implementation). No functional changes — `format_on_save` guard logic, excluded filetype list, guard ordering, and return table are all unchanged.

**Commit:** 5c20eca

## Verification Results

All acceptance criteria met:

| Check | Result |
|-------|--------|
| `rg "keymap-regression.log" README.md` | PASS — 2 matches (table row + artifact list) |
| `rg "format-regression.log" README.md` | PASS — 2 matches (table row + artifact list) |
| `rg "nvim-validate.sh keymaps" README.md` | PASS — 1 match in Phase 3 table |
| `rg "nvim-validate.sh formats" README.md` | PASS — 1 match in Phase 3 table |
| `rg "startup.*checkhealth.*keymaps.*formats" README.md` | PASS — `all` row matches |
| `! rg "^--- TODO: Format-on-save dispatcher" conform.lua` | PASS — no match |
| `rg "format_on_save = function\(bufnr\)" conform.lua` | PASS — line 15 |
| `rg "timeout_ms = 500, lsp_format = .fallback." conform.lua` | PASS — line 61 |

## Deviations from Plan

None - plan executed exactly as written.

## Threat Flags

None — changes are documentation and comment removal only. No new network endpoints, auth paths, or schema changes introduced.

## Self-Check: PASSED

Files exist:
- FOUND: .config/nvim/README.md
- FOUND: .config/nvim/lua/plugins/conform.lua

Commits exist:
- 288fa10: docs(10-01): update Phase 3 harness contract to Phase 10 v1.1 spec
- 5c20eca: chore(10-01): remove stale TODO banner from conform.lua
