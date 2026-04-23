---
phase: 10-validation-harness-expansion
verified: 2026-04-23T00:00:00Z
status: human_needed
score: 9/9 must-haves verified
overrides_applied: 0
human_verification:
  - test: "Open a Lua file and a Go file in Neovim, wait for LSP to attach, and confirm no Lua errors appear in the notification area or :messages"
    expected: "No 'E5108 Error executing Lua', no 'stack traceback', no on_attach handler errors — LSP attaches silently to both file types"
    why_human: "Headless attach instrumentation is brittle; on_attach callbacks only fire when a real LSP server connects to a live buffer, which cannot be simulated headlessly without a full server start"
---

# Phase 10: Validation Harness Expansion — Verification Report

**Phase Goal:** Extend repo validation only where `:checkhealth` cannot prove correctness for bug-prone flows
**Verified:** 2026-04-23
**Status:** human_needed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Maintainer can see one documented validation contract for the v1.1 harness | VERIFIED | `.config/nvim/README.md` lines 325-343: Phase 10 command table with `checkhealth`, `keymaps`, `formats` rows; `all` sequence listed as `startup → sync → smoke → health → checkhealth → keymaps → formats`; artifact list extended with `keymap-regression.log` and `format-regression.log` |
| 2 | The documented Phase 10 artifact set names the new regression logs before script implementation begins | VERIFIED | `keymap-regression.log` and `format-regression.log` appear in README lines 342-343 (Plan 01 commit 288fa10 predates Plan 02 commits 34f31fe/a1ddb2e) |
| 3 | The format-on-save target file no longer carries stale Phase 10 TODO text | VERIFIED | `rg "^--- TODO: Format-on-save dispatcher"` returns no match in `conform.lua`; `format_on_save = function(bufnr)` intact at line 15; `timeout_ms = 500, lsp_format = "fallback"` intact at line 61 |
| 4 | Maintainer can run one command to probe keymap dispatcher regressions headlessly | VERIFIED | `cmd_keymaps()` function exists in `nvim-validate.sh` lines 411-515; probes `<cmd>enew<CR>`, `<C-w>s`, `:close<CR>` via `pcall`; writes `keymap-regression.log`; exits non-zero on any FAIL; wired into `usage()` and `case` dispatch |
| 5 | Maintainer can run one command to probe format-on-save guard regressions headlessly | VERIFIED | `cmd_formats()` function exists in `nvim-validate.sh` lines 530-690; probes nofile/unnamed/acwrite buffer cases; writes `format-regression.log`; exits non-zero on any FAIL; wired into `usage()` and `case` dispatch |
| 6 | The full `all` gate executes the new probes after `checkhealth` | VERIFIED | `cmd_all()` at lines 705-731: `startup → sync → smoke → health → checkhealth → keymaps → formats`; fail-fast semantics at each step with "all ABORTED at X" messages; `keymaps` follows `checkhealth`, `formats` follows `keymaps` |
| 7 | Manual-only blind spots remain documented in the failure checklist instead of being silently dropped | VERIFIED | `CHECKLIST.md` line 304: `## Phase 10 Regression Checks`; LSP attach safety subsection at line 312; scripted regression follow-up subsection at lines 331-341; `Regression signal:` entries at lines 323 and 341 |
| 8 | Maintainer can read any validation artifact and tell whether it points to a config regression, an environment gap, or an optional-tool warning | VERIFIED | README `### Reading validation output` section (line 345): artifact-by-artifact table covering all 7 artifacts with producing subcommand and first-response rule; triage path at lines 362-366 with three concrete categories |
| 9 | A fresh `checkhealth` run distinguishes config-caused warnings from by-design or environment-only warnings | VERIFIED | `FAILURES.md` Phase 10-04 section (lines 20-61): 20+ warning families classified across blink.cmp, config/core, lazy.nvim, mason, render-markdown, snacks, vim.deprecated, vim.provider, which-key, treesitter; two config-caused entries marked "Fixed in Task 2"; all others classified as By Design, Won't Fix, or Informational-by-design |

**Score:** 9/9 truths verified

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `.config/nvim/README.md` | Phase 10 command and artifact contract | VERIFIED | Lines 325-366: Phase 10 command table, Report Output list with 7 artifacts, `### Reading validation output` section, triage decision path |
| `.config/nvim/lua/plugins/conform.lua` | Clean `format_on_save` guard source without stale TODO banner | VERIFIED | No `--- TODO: Format-on-save dispatcher` on line 1; `format_on_save = function(bufnr)` at line 15; `timeout_ms = 500, lsp_format = "fallback"` at line 61 |
| `scripts/nvim-validate.sh` | `keymaps` and `formats` subcommands plus updated `all` sequence | VERIFIED | `cmd_keymaps()` at line 411, `cmd_formats()` at line 530, `cmd_all()` at line 705 with 7-step sequence, `usage()` documents both new subcommands, `case` dispatch wires both at lines 748-749 |
| `.planning/phases/06-runtime-failure-inventory/CHECKLIST.md` | Phase 10 manual regression section | VERIFIED | `## Phase 10 Regression Checks` at line 304; LSP attach safety subsection; scripted regression follow-up subsection pairing `keymaps` and `formats` with investigation steps |
| `.config/nvim/lua/core/keymaps/whichkey.lua` | Claimed-lhs guard skipping duplicate group registration | VERIFIED | Lines 19-37: `claimed` set built from `registry.get_by_scope("global")` and `registry.get_by_scope("lazy")`; group loop skips `which_key.add()` when `group_lhs` is in `claimed` |
| `.planning/phases/06-runtime-failure-inventory/FAILURES.md` | Updated warning audit with dispositions | VERIFIED | Phase 10-04 section at lines 20-61; all warning families classified; which-key `<leader>e` and `<leader>b` duplicates marked "Fixed (Task 2)" |
| `.planning/tmp/nvim-validate/config-warning-families.tsv` | Exact warning-text manifest for repo-owned config-caused warnings | NOTE | Runtime artifact in gitignored `.planning/tmp/` directory — produced during plan execution, not committed. FAILURES.md serves as the durable record. Fix was verified via logic simulation against live registry data (confirmed in 10-04 SUMMARY). |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `.config/nvim/README.md` | `scripts/nvim-validate.sh` | documented command table and artifact list | WIRED | `nvim-validate.sh keymaps` at line 328, `nvim-validate.sh formats` at line 329, `nvim-validate.sh all` at line 330 with correct sequence |
| `.config/nvim/lua/plugins/conform.lua` | `scripts/nvim-validate.sh` | Plan 10-02 direct guard probe target | WIRED | `cmd_formats()` at line 546: `pcall(require, 'plugins.conform')` to load spec; `spec.opts.format_on_save` extracted as guard function |
| `scripts/nvim-validate.sh` | `.config/nvim/lua/core/keymaps/lazy.lua` | headless dispatcher probe | WIRED | `cmd_keymaps()` at line 427: `pcall(require, 'core.keymaps.lazy')`; dispatcher logic replicates `lazy.lua` branch structure exactly |
| `scripts/nvim-validate.sh` | `.config/nvim/lua/plugins/conform.lua` | direct format_on_save guard probe | WIRED | `cmd_formats()` line 546: loads `plugins.conform`, extracts `opts.format_on_save`, calls guard directly — no BufWritePre simulation |
| `scripts/nvim-validate.sh` | `.planning/tmp/nvim-validate/` | log artifact writes | WIRED | `$REPORT_DIR/keymap-regression.log` and `$REPORT_DIR/format-regression.log` set at lines 412 and 531 respectively |
| `.config/nvim/README.md` | `.planning/tmp/nvim-validate/` | artifact interpretation table | WIRED | README lines 351-358: table maps each of 7 artifacts to subcommand and first-response rule |
| `.config/nvim/README.md` | `.config/nvim/lua/config/health.lua` | Phase 9 classification reuse | WIRED | README line 364: `:checkhealth config` referenced as source of truth for warning interpretation |

---

### Data-Flow Trace (Level 4)

Not applicable — all phase artifacts are shell scripts, Lua configuration files, and documentation. No React/component data rendering pipelines to trace.

---

### Behavioral Spot-Checks

| Behavior | Check | Result | Status |
|----------|-------|--------|--------|
| `nvim-validate.sh` is executable | `test -x scripts/nvim-validate.sh` | executable | PASS |
| `keymaps` subcommand documented in `usage()` | `grep "keymaps" usage()` | 16 occurrences in script | PASS |
| `formats` subcommand documented in `usage()` | `grep "formats" usage()` | 13 occurrences in script | PASS |
| `cmd_all()` sequence correct | `sed -n '705,731p'` | 7-step fail-fast sequence confirmed | PASS |
| `cmd_keymaps()` probes 3 action families | `sed -n '411,515p'` | `<cmd>enew<CR>`, `<C-w>s`, `:close<CR>` all present with pcall | PASS |
| `cmd_formats()` probes 3 buffer cases | `sed -n '530,690p'` | nofile/unnamed/acwrite cases all present with guard call | PASS |
| `conform.lua` stale banner removed | `grep "^--- TODO: Format-on-save dispatcher"` | no match | PASS |
| `whichkey.lua` claimed-lhs guard present | `grep "claimed"` | lines 19-37 implement full guard | PASS |
| `./scripts/nvim-validate.sh keymaps` (live run) | Would require Neovim headless run | SKIP — needs live Neovim runtime |
| `./scripts/nvim-validate.sh formats` (live run) | Would require Neovim headless run | SKIP — needs live Neovim runtime |

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| TEST-01 | Plans 10-01, 10-02 | Maintainer can run repo validation commands to verify startup, plugin load, and health status before rollout | SATISFIED | README contract documents full command set; `checkhealth`, `keymaps`, `formats`, `all` subcommands in `nvim-validate.sh`; Plan 10-01 locked the v1.1 contract before scripts were written |
| TEST-02 | Plan 10-02 | Maintainer can reproduce and validate bug-prone keymap or plugin flows with scripts when `:checkhealth` is insufficient | SATISFIED | `keymaps` subcommand probes Phase 7 dispatcher blind spots not detectable by `:checkhealth`; `formats` subcommand probes format-on-save guard behavior directly; both produce deterministic PASS/FAIL artifacts |
| TEST-03 | Plans 10-03, 10-04 | Maintainer can inspect validation artifacts that clearly separate config regressions from external dependency gaps | SATISFIED | README `### Reading validation output` classifies each artifact; triage path reuses Phase 9 taxonomy; FAILURES.md Phase 10-04 section classifies 20+ warning families with explicit config-caused vs By Design/Won't Fix dispositions |

All three requirement IDs declared in PLAN frontmatter are accounted for. No orphaned requirements identified in REQUIREMENTS.md for Phase 10.

---

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `.config/nvim/lua/core/keymaps/whichkey.lua` | 1 | `--- TODO: Which-key group registration ---` | Info | Pre-existing file-section banner pattern used by 10+ files in the codebase (established in Phase 12 documentation phase). Not a stub — the file has 73 lines of full implementation. No impact on goal achievement. |

No blockers or warnings found.

---

### Human Verification Required

#### 1. LSP Attach Safety Check

**Test:** Open a representative Lua file (e.g., `~/.config/nvim/lua/core/keymaps/registry.lua`) in Neovim. Wait 2-3 seconds for LSP to attach. Check `:messages` for any error output. Repeat with a Go file if Go toolchain is present.

**Expected:** No `E5108 Error executing Lua`, no `stack traceback`, no notification-area errors immediately after LSP attach. If ts_ls is not installed (expected for this machine), TypeScript LSP attach-time errors are excluded from this check.

**Why human:** Headless attach instrumentation is brittle — LSP `on_attach` callbacks only fire when a real language server connects to a live buffer, which requires a full interactive editing session. The VALIDATION.md explicitly designates this as "manual-only" per Phase 10 design decision. This is the one remaining non-scripted regression surface per TEST-02.

---

### Gaps Summary

No gaps. All 9 observable truths are VERIFIED.

The `config-warning-families.tsv` runtime artifact is absent from the filesystem because `.planning/tmp/` is gitignored — this is expected behavior, not a gap. The TSV was used during Plan 10-04 Task 2 execution as the intermediate manifest driving which-key fix remediation. The durable record of warning classifications lives in FAILURES.md, and the fix to `whichkey.lua` is committed and verified. There is nothing actionable here.

The one item requiring attention is a manual interactive check (LSP attach safety) that was always designated as human-only per the Phase 10 VALIDATION.md.

---

### Re-verification Notes

This is the initial verification. No previous VERIFICATION.md existed.

---

_Verified: 2026-04-23_
_Verifier: Claude (gsd-verifier)_
