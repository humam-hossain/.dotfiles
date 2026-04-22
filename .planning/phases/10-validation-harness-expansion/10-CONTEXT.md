# Phase 10: Validation Harness Expansion - Context

**Gathered:** 2026-04-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Extend repo validation only where `:checkhealth` cannot prove correctness for bug-prone flows. Delivers TEST-01 (validator commands aligned with v1.1 scope), TEST-02 (scripted regression checks for keymap dispatcher and format-on-save guard paths), and TEST-03 (triage documentation so maintainers can separate config regressions from env gaps).

**Scope expanded during discussion:** Phase 10 also includes a new plan (10-04) to fix config-caused `:checkhealth` WARNING entries — following the same Phase 9 pattern that fixed ERRORs. Overlapping keymap warnings and other config-caused warnings are in scope.

Plans:
- 10-01: Validator alignment audit + define artifact contract for new subcommands
- 10-02: Add `keymaps` and `formats` regression subcommands to `nvim-validate.sh`
- 10-03: README "Reading validation output" section (TEST-03 triage artifact)
- 10-04: Fresh headless warning audit → classify → fix config-caused WARNINGs

</domain>

<decisions>
## Implementation Decisions

### 10-01: Validator Alignment

- **D-01:** Audit PLUGIN_LIST, TOOL_LIST, and `all` sequence against v1.1 changes (pyright replacing basedpyright, neo-tree probe removed from health.lua in Phase 8). Fix any gaps found. Verified during discussion: PLUGIN_LIST and TOOL_LIST already look accurate, but the audit should confirm explicitly.
- **D-02:** Define artifact contract for 10-02 outputs in 10-01 before the regression scripts are written. New artifacts: `keymap-regression.log` and `format-regression.log` in `.planning/tmp/nvim-validate/` — consistent with `startup.log`, `smoke.log` naming.
- **D-03:** Remove stale `--- TODO: Format-on-save dispatcher` comment at line 1 of `.config/nvim/lua/plugins/conform.lua` as part of the alignment cleanup. No functional change.
- **D-04:** Fix README stale table (`.config/nvim/README.md` lines 323-327) — currently describes the Phase 3 `all` sequence (startup/sync/smoke/health only, missing `checkhealth`). Update to reflect the current `all` sequence including `checkhealth` and the new Phase 10 subcommands.

### 10-02: Regression Check Coverage

- **D-05:** Add `keymaps` subcommand to `nvim-validate.sh` — headlessly load the lazy.lua dispatcher and pcall-test it against each action string type that caused Phase 7 failures: `<cmd>...<CR>`, angle-bracket sequences (`<C-w>X`), and plain ex commands. Verify no errors thrown. Artifact: `keymap-regression.log`.
- **D-06:** Add `formats` subcommand to `nvim-validate.sh` — headlessly load conform.nvim and call the `format_on_save` guard function directly with mock buffer contexts (nofile buftype, acwrite buftype, empty buffer name). Verify the function returns the correct `false`/`{...}` values for each case. Artifact: `format-regression.log`. Direct function call — not BufWritePre headless trigger (too unreliable).
- **D-07:** LSP attach safety checks stay in CHECKLIST.md as manual steps — headless automation of pcall guard behavior in LSP attach autocmds is difficult to instrument reliably. These belong in a new "Phase 10 Regression Checks" section in `.planning/phases/06-runtime-failure-inventory/CHECKLIST.md`.
- **D-08:** CHECKLIST.md also gets a Phase 10 section as companion to the scripted checks — covers LSP attach safety and any other flows that the scripts don't reach.

### 10-02: Script Architecture

- **D-09:** New regression checks live as subcommands in `nvim-validate.sh` — consistent with Phase 9's `checkhealth` subcommand pattern, not a separate script. Single entrypoint for maintainers.
- **D-10:** `all` sequence extended to include new subcommands: startup → sync → smoke → health → checkhealth → keymaps → formats. Full pre-rollout gate in one command.
- **D-11:** Log file artifacts only: `keymap-regression.log` and `format-regression.log` in `$REPORT_DIR`. No JSON — these are simple pass/fail checks. Consistent with startup.log, smoke.log.

### 10-03: Triage Documentation

- **D-12:** TEST-03 artifact is a new "Reading validation output" section in `.config/nvim/README.md`. Explains what each artifact means, how to distinguish config bugs from env gaps (referencing the Phase 9 classification approach), and what action to take for each. No separate TRIAGE.md — README is the stable user-facing location.

### 10-04: Checkhealth Warning Fixes (New Plan)

- **D-13:** New plan 10-04 added to Phase 10. Phase 10 now has 4 plans.
- **D-14:** 10-04 starts with a fresh headless audit — run `./scripts/nvim-validate.sh checkhealth`, read `checkhealth.txt`, enumerate all WARN entries. User noted seeing overlapping keymap warnings and other warnings. Classify each: config-caused vs environment-only vs optional tool gap.
- **D-15:** Fix config-caused WARNINGs found in the audit. Environment-only or optional tool warnings → document as By Design / Won't Fix.
- **D-16:** FAILURES.md updated as warnings are resolved — consistent with Phase 6 D-12 (FAILURES.md is a living doc). Config-caused warnings that get fixed → Fixed. Environment-only → Won't Fix / By Design.

### Claude's Discretion

- Exact pcall-test patterns for the `keymaps` subcommand (which specific string values to exercise)
- Exact mock buffer context approach for the `formats` subcommand (buffer setup in headless Lua)
- Specific LSP attach safety scenarios to cover in CHECKLIST.md Phase 10 section
- README "Reading validation output" section placement within the file
- Order of commits within each plan

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` — Phase 10 goal, plan structure, TEST-01/02/03 requirements
- `.planning/REQUIREMENTS.md` — TEST-01, TEST-02, TEST-03 acceptance criteria
- `.planning/PROJECT.md` — v1.1 milestone goals and constraints (scripts added only where `:checkhealth` insufficient)

### Existing validator (primary extension target)
- `scripts/nvim-validate.sh` — full harness; subcommands startup/sync/health/smoke/checkhealth/all; patterns to follow for new keymaps/formats subcommands
- `.planning/tmp/nvim-validate/` — artifact directory; new log files land here

### Failure inventory and checklist (update targets)
- `.planning/phases/06-runtime-failure-inventory/FAILURES.md` — living inventory; 10-04 warning fixes update status here
- `.planning/phases/06-runtime-failure-inventory/CHECKLIST.md` — Phase 10 section to be added for LSP attach safety manual checks

### Files being modified
- `scripts/nvim-validate.sh` — add `keymaps` and `formats` subcommands; extend `all` sequence
- `.config/nvim/README.md` — fix stale table (lines 323-327); add "Reading validation output" section
- `.config/nvim/lua/plugins/conform.lua` — remove stale TODO comment at line 1

### Format-on-save guard implementation (test target)
- `.config/nvim/lua/plugins/conform.lua` — `format_on_save` guard function with 4 guards (buftype, modifiable, empty name, filetype exclusion list); `formats` subcommand tests this function directly

### Prior phase context
- `.planning/phases/09-health-signal-cleanup/09-CONTEXT.md` — D-02/D-03: checkhealth subcommand pattern; D-03: artifact at checkhealth.txt; classification approach for ERRORs (same approach applied to WARNINGs in 10-04)
- `.planning/phases/08-plugin-runtime-hardening/08-CONTEXT.md` — D-09: neo-tree probe removal; D-11: pyright replacement; these changes drove 10-01 alignment need
- `.planning/phases/06-runtime-failure-inventory/06-CONTEXT.md` — D-12: FAILURES.md living-doc pattern; D-24/D-25: status workflow

No external specs — requirements fully captured in decisions above.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scripts/nvim-validate.sh`: Full harness — `cmd_*()` function pattern, `REPORT_DIR`, `PASS`/`FAIL` output, `print_tail()` helper, `init()` for mkdir. New subcommands follow this exact pattern.
- `.config/nvim/lua/plugins/conform.lua`: `format_on_save` is a Lua function with 4 guard checks (buftype, modifiable, empty name, filetype). The `formats` subcommand calls this function directly with mock buffer state — no BufWritePre needed.
- `.config/nvim/lua/core/keymaps/lazy.lua`: The Phase 7 feedkeys dispatcher at line 29 (now fixed). The `keymaps` subcommand pcall-tests the dispatcher against the three string types that previously caused errors.
- `.planning/tmp/nvim-validate/`: Artifact dir already created by `init()`. New `.log` files land here.

### Established Patterns
- `nvim-validate.sh` uses `set -euo pipefail`, `cmd_*()` function per subcommand, `local log="$REPORT_DIR/<name>.log"`, PASS/FAIL echo + `return 1` on failure — follow exactly.
- `smoke` subcommand pattern: write a Lua tmp file, run headless nvim with `-l $lua_tmp`, check for failure markers — `keymaps` and `formats` subcommands use the same pattern.
- `all` sequence: fail-fast with early `echo "==> all ABORTED at <step>"` pattern per subcommand.

### Integration Points
- `nvim-validate.sh all` extended: startup → sync → smoke → health → checkhealth → keymaps → formats. README `all` description updated to match.
- `conform.lua` format_on_save guard is a closure over buffer state — the headless test will need to construct mock `vim.bo[bufnr]` state to exercise each guard branch.
- CHECKLIST.md at `.planning/phases/06-runtime-failure-inventory/CHECKLIST.md` receives a new Phase 10 section after existing Phase 7/8/9 sections.

</code_context>

<specifics>
## Specific Ideas

- `keymaps` subcommand test strings — the three confirmed-broken types from Phase 7: `"<cmd>enew<CR>"` (angle-bracket with cmd), `"<C-w>s"` (window keyseq), `":close<CR>"` (colon-format). Feed each through the dispatcher and confirm no vim.cmd error.
- `formats` mock buffer contexts to test: `{ buftype = "nofile", name = "" }` → expect false; `{ buftype = "", name = "", modifiable = true }` → expect false (unnamed); `{ buftype = "acwrite", modifiable = true, ft = "lua", name = "/some/file.lua" }` → expect format options table.
- README stale table at lines 323-327 is missing the `checkhealth` row and has wrong `all` description ("startup, sync, smoke, health" only). Both gaps are fixed in 10-01.
- 10-04 audit command: `./scripts/nvim-validate.sh checkhealth` then inspect `.planning/tmp/nvim-validate/checkhealth.txt` for WARN lines — same audit approach Phase 9 used for ERRORs.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 10-validation-harness-expansion*
*Context gathered: 2026-04-23*
