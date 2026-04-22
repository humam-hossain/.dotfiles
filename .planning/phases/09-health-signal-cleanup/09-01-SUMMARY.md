---
phase: 09-health-signal-cleanup
plan: "01"
subsystem: validation
tags: [neovim, health, checkhealth, tmux, vim-tmux-navigator, render-markdown, nvim-validate]

# Dependency graph
requires:
  - phase: 08-plugin-runtime-hardening
    provides: core/open.lua tuple handling fix (BUG-020 Phase 8 side already correct)
  - phase: 06-runtime-failure-inventory
    provides: FAILURES.md and CHECKLIST.md living docs for BUG-019/BUG-020

provides:
  - scripts/nvim-validate.sh checkhealth subcommand with health-buffer capture
  - .planning/tmp/nvim-validate/checkhealth.txt first audit artifact
  - cmd_health REQUIRED_TOOLS fail gate for git and rg
  - render-markdown overrides.buftype config fix (resolved health ERROR)
  - .config/.tmux.conf vim-tmux-navigator companion bindings (BUG-019 automated fix)
  - Phase 9-01 audit classification (reserved/environment-only error documentation)

affects: [09-02-PLAN, health-provider-work, tmux-navigation, external-open-investigation]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Health buffer capture via Lua nvim_buf_get_lines after _check() run (not redir)"
    - "EventIgnore=FileType guard around headless health capture to suppress plugin autocommands"
    - "REQUIRED_TOOLS bash array fail gate (git, rg) in cmd_health"
    - "render-markdown buftype config under overrides.buftype not at root opts level"

key-files:
  created:
    - .planning/tmp/nvim-validate/checkhealth.txt (first Phase 9 audit artifact, 5667 lines)
  modified:
    - scripts/nvim-validate.sh (checkhealth subcommand, REQUIRED_TOOLS gate, all sequence update)
    - .config/nvim/lua/plugins/misc.lua (render-markdown overrides.buftype fix)
    - .config/nvim/README.md (validation commands table updated with checkhealth row)
    - .config/.tmux.conf (four bind-key -n C-h/j/k/l companion entries added)
    - .planning/phases/06-runtime-failure-inventory/FAILURES.md (Phase 9-01 audit section)
    - .planning/phases/06-runtime-failure-inventory/CHECKLIST.md (BUG-019 fix, BUG-020 steps)

key-decisions:
  - "Health buffer capture uses nvim_buf_get_lines(0, 0, -1) after _check() — not redir which only captures progress noise in headless mode"
  - "Error grep pattern uses PCRE '(?:^ERROR:|- \\S+ ERROR )' to match the actual '- emoji ERROR' format used in health buffer output"
  - "render-markdown buftype must be under opts.overrides.buftype, not opts.buftype (root-level is not a valid field per plugin schema)"
  - "Remaining checkhealth FAILs after fix are: core provider gap (reserved 9-02), headless-environment-only issues (render-markdown highlighter, snacks dashboard, tpipeline), missing optional tool (mmdc) — all correctly classified"
  - "tmux companion bindings added explicitly to .tmux.conf despite TPM auto-binding for resilience and discoverability (D-29)"
  - "BUG-020 investigation deferred to Task 2 checkpoint — no repo fix made without evidence (D-31/D-32 anti-pattern avoidance)"

patterns-established:
  - "Pattern 1: Headless health capture — use Lua buffer read after _check(), suppress FileType events, embed artifact path in Lua script (not via argv which is unreliable in -l mode)"
  - "Pattern 2: Health error scan — use PCRE to match both plain ERROR: and emoji-prefix format in health buffer output"

requirements-completed:
  - HEAL-01

# Metrics
duration: 11min
completed: 2026-04-22
---

# Phase 9 Plan 01: Health Signal Cleanup — Validator and First Audit Summary

**Headless `:checkhealth` validator added to nvim-validate.sh with buffer-dump capture, first audit artifact captured, render-markdown config error fixed, and tmux companion bindings added for cross-pane navigation (BUG-019 automated fix); Task 2 interactive verification pending.**

## Performance

- **Duration:** 11 min (automated portion; Task 2 checkpoint pending human verification)
- **Started:** 2026-04-22T18:03:50Z
- **Completed:** 2026-04-22T18:15:11Z (checkpoint reached)
- **Tasks:** 1 of 2 complete; Task 2 automated pre-work complete, awaiting interactive verify
- **Files modified:** 6

## Accomplishments

- Added `cmd_checkhealth` to `scripts/nvim-validate.sh`: headless `:checkhealth` run that dumps the health:// buffer via Lua `nvim_buf_get_lines` (not redir, which only captures progress noise) to `.planning/tmp/nvim-validate/checkhealth.txt` and fails on any `- ❌ ERROR` line
- Extended `cmd_all` sequence: startup → sync → smoke → health → checkhealth (D-05)
- Added `REQUIRED_TOOLS=(git rg)` bash fail gate to `cmd_health` (D-06/D-07)
- Fixed render-markdown config bug: `buftype` was at root opts level (schema violation); moved to `opts.overrides.buftype` — resolves `buftype - expected: nil, got: table` health ERROR
- Captured first Phase 9 checkhealth audit (5667 lines); classified all remaining errors
- Added four `bind-key -n C-h/j/k/l` companion entries to `.config/.tmux.conf` (BUG-019 automated fix, D-29); sourced and verified active in running tmux session
- Updated README validation commands table with `checkhealth` row (D-26)
- Updated FAILURES.md and CHECKLIST.md with Phase 9-01 audit findings and BUG-020 investigation steps

## Task Commits

1. **Task 1: Validator checkhealth, first audit, config fixes** — `113537c` (feat)
2. **Task 2 pre-work: tmux companion bindings** — `86c1957` (fix)

## Files Created/Modified

- `scripts/nvim-validate.sh` — Added `cmd_checkhealth`, `REQUIRED_TOOLS` gate in `cmd_health`, `checkhealth` in `cmd_all` and dispatch
- `.config/nvim/lua/plugins/misc.lua` — Fixed render-markdown `overrides.buftype` config
- `.config/nvim/README.md` — Added `checkhealth` row to validation commands table
- `.config/.tmux.conf` — Added four `bind-key -n C-h/j/k/l` vim-tmux-navigator companion bindings
- `.planning/phases/06-runtime-failure-inventory/FAILURES.md` — Phase 9-01 audit classification section, BUG-019 status updated
- `.planning/phases/06-runtime-failure-inventory/CHECKLIST.md` — BUG-019 fix docs, BUG-020 investigation steps
- `.planning/tmp/nvim-validate/checkhealth.txt` — First Phase 9 audit artifact (5667 lines, not committed — generated output)

## Decisions Made

- **Health buffer capture strategy**: Use `require('vim.health')._check('', '')` then `nvim_buf_get_lines(0, 0, -1, false)` with `eventignore=FileType` guard. Redir-based capture only produces progress percentage lines in headless mode (confirmed by research). Artifact path embedded in Lua script directly rather than passed via `-l` argv (argv(0) is unreliable in -l mode).
- **Error detection pattern**: The health buffer uses `- ❌ ERROR text` format (unicode emoji), not `^ERROR:` prefix. Updated grep to PCRE `(?:^ERROR:|- \S+ ERROR )` to match both forms.
- **Remaining errors classified**: After fix, remaining errors are: `core` provider (reserved for 9-02), render-markdown highlighter (headless-only env), snacks dashboard (headless-only env), mmdc tool (missing optional), tpipeline (headless-only env). All correctly excluded from "config-caused" category.
- **BUG-020**: No repo change made without investigation evidence per D-31/D-32. Steps documented in CHECKLIST.md for Task 2 human verification.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Incorrect error grep pattern in cmd_checkhealth**
- **Found during:** Task 1 (running first audit)
- **Issue:** Initial `grep '^ERROR:'` pattern matched zero lines despite visible `❌ ERROR` entries; health buffer uses `- ❌ ERROR ` format with unicode emoji prefix
- **Fix:** Changed to PCRE `grep -nP '(?:^ERROR:|- \S+ ERROR )'` matching both plain and emoji-prefix formats
- **Files modified:** `scripts/nvim-validate.sh`
- **Verification:** Re-run correctly detected all 5 error lines
- **Committed in:** `113537c` (Task 1 commit)

**2. [Rule 1 - Bug] Lua script argv(0) path passing failure in -l mode**
- **Found during:** Task 1 (first checkhealth run)
- **Issue:** Initial implementation passed artifact path as `-l script.lua "$artifact"` and read via `vim.fn.argv(0)`, but got `E482: Can't open file with an empty name` — argv is not reliably set in -l mode
- **Fix:** Embed artifact path directly in the Lua script via bash heredoc interpolation
- **Files modified:** `scripts/nvim-validate.sh`
- **Verification:** Second run produced 5667-line artifact successfully
- **Committed in:** `113537c` (Task 1 commit)

**3. [Rule 2 - Missing Critical] render-markdown overrides.buftype config fix**
- **Found during:** Task 1 (first audit analysis)
- **Issue:** `buftype = { nofile = { enabled = false } }` at root opts level is a schema violation (field is not valid at root); plugin health check reports `buftype - expected: nil, got: table`
- **Fix:** Moved to `overrides = { buftype = { nofile = { enabled = false } } }` per plugin schema
- **Files modified:** `.config/nvim/lua/plugins/misc.lua`
- **Verification:** Re-run checkhealth confirms `buftype` error gone from audit
- **Committed in:** `113537c` (Task 1 commit)

---

**Total deviations:** 3 auto-fixed (2 Rule 1 bugs, 1 Rule 2 missing critical)
**Impact on plan:** All auto-fixes necessary for correct validator implementation and health error resolution. No scope creep.

## Issues Encountered

- `~/.tmux.conf` is not symlinked to the dotfiles `.config/.tmux.conf` — they are separate files. Sourced the repo version directly for Task 2 pre-work verification. The deployed version will need to be updated when the dotfiles are next rolled out.

## Checkpoint: Task 2 Awaiting Interactive Verification

Task 2 automated pre-work is complete:
- Tmux companion bindings added to `.config/.tmux.conf` and sourced (`tmux source-file`)
- `bind-key -T root C-h/j/k/l` bindings confirmed active in running tmux session
- BUG-020 investigation steps documented in CHECKLIST.md

**Human verification required for:**
1. Confirm `<C-h/j/k/l>` crosses tmux pane boundaries in both directions (BUG-019 interactive close)
2. Run `:verbose nmap <C-S-o>` and record result
3. Test `:lua vim.ui.open(vim.fn.expand('%:p'))` and record result/error
4. Test `xdg-open` from shell and record result
5. Determine BUG-020 final disposition based on investigation evidence

## Next Phase Readiness

After Task 2 checkpoint is satisfied:
- BUG-019 will be closed (confirmed fixed interactively)
- BUG-020 will have a proved root cause and repo action decided
- Plan 9-02 can proceed to create `lua/config/health.lua` provider

## Known Stubs

None — all implemented functionality is wired and operational.

## Self-Check

Files created/modified verified:
- `scripts/nvim-validate.sh`: checkhealth subcommand present
- `.config/nvim/lua/plugins/misc.lua`: overrides.buftype present
- `.config/nvim/README.md`: checkhealth row in validation table
- `.config/.tmux.conf`: four bind-key -n entries present
- `.planning/phases/06-runtime-failure-inventory/FAILURES.md`: Phase 9-01 section present
- `.planning/phases/06-runtime-failure-inventory/CHECKLIST.md`: BUG-019/BUG-020 sections present

Commits verified:
- `113537c`: feat(09-01) Task 1
- `86c1957`: fix(09-01) Task 2 pre-work (tmux bindings)

## Self-Check: PASSED

---
*Phase: 09-health-signal-cleanup*
*Completed: 2026-04-22 (checkpoint — awaiting Task 2 interactive verification)*
