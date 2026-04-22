# Phase 10: Validation Harness Expansion - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-23
**Phase:** 10-validation-harness-expansion
**Areas discussed:** 10-01 alignment scope, 10-02 regression coverage, 10-02 script form, all sequence, 10-03 triage artifact, additional areas (README stale table, keymap dispatcher specificity, stale TODO, artifact naming, checkhealth warnings scope)

---

## 10-01 Alignment Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Audit + tighten only | Verify PLUGIN_LIST, TOOL_LIST, `all` sequence. Small plan — most alignment happened in Phase 9. | |
| Add missing artifact output | Define where 10-02 artifacts land and their format before regression scripts are written. | |
| Both — audit + define artifact contract | Do the audit pass AND define artifact layout for 10-02 outputs upfront. | ✓ |

**User's choice:** Both — audit pass + define artifact contract for 10-02 outputs
**Notes:** README stale table and stale TODO also surfaced during scout and folded into 10-01 scope.

---

## 10-02 Regression Coverage

| Option | Description | Selected |
|--------|-------------|----------|
| Keymap dispatcher | Headless pcall-test of lazy.lua feedkeys dispatcher for action string types. | ✓ |
| Format-on-save guards | Test conform.nvim format_on_save guard function directly. | ✓ |
| Plugin crash paths (LSP attach safety) | Manual CHECKLIST.md steps — hard to headlessly automate. | ✓ |
| CHECKLIST.md extension only | No new headless scripts — extend checklist for manual steps. | ✓ |

**User's choice:** All four — headless scripts for keymap dispatcher and format-on-save, CHECKLIST.md for LSP attach safety, plus CHECKLIST.md as companion to scripted checks.

---

## 10-02 Script Form

| Option | Description | Selected |
|--------|-------------|----------|
| Subcommands in nvim-validate.sh | `keymaps` and `formats` as subcommands. Single entrypoint. Phase 9 pattern. | ✓ |
| Separate nvim-regression.sh | New script alongside validator. Phase 6 pattern. | |
| You decide | Claude picks. | |

**User's choice:** Subcommands in nvim-validate.sh

---

## all Sequence

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — add to 'all' | Regression checks run automatically with `all`. Full pre-rollout gate. | ✓ |
| No — opt-in only | `keymaps` and `formats` explicit only; `all` stays at startup→checkhealth. | |

**User's choice:** Yes — add to `all`. Final sequence: startup → sync → smoke → health → checkhealth → keymaps → formats.

---

## Checkhealth Warnings Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Fix in Phase 10 | Expand Phase 10 to include warning cleanup before Phase 11 verification. | ✓ |
| Defer to Phase 11 | Phase 10 stays focused on TEST-01/02/03 only. | |
| New phase 10.5 | Insert a dedicated warning-fix phase. | |

**User's choice:** Fix in Phase 10
**Notes:** User mentioned seeing overlapping keymap warnings and others in `:checkhealth`. This expanded Phase 10 scope to include a new plan 10-04.

---

## 10-04 Warning Plan Placement

| Option | Description | Selected |
|--------|-------------|----------|
| New plan 10-04 | Separate plan for warning investigation and fixes. | ✓ |
| Fold into 10-01 | 10-01 becomes alignment + warning cleanup. | |
| Fold into 10-02 | Warning fixes as part of regression coverage. | |

**User's choice:** New plan 10-04

---

## 10-03 Triage Artifact

| Option | Description | Selected |
|--------|-------------|----------|
| README section | "Reading validation output" in README.md. Stable, user-facing. | ✓ |
| TRIAGE.md in .planning/ | Maintainer-internal structured table. | |
| Annotated checkhealth.txt | Tag each ERROR/WARN as [CONFIG] or [ENV] in script output. | |

**User's choice:** README section

---

## Keymap Dispatcher Test Specificity

| Option | Description | Selected |
|--------|-------------|----------|
| pcall-test dispatcher patterns | Load dispatcher, pcall with each string type, verify no errors. Fast, no buffer. | ✓ |
| Full keymap fire test | Open buffer, register keymaps, feedkeys each lhs, check errors. More realistic but harder. | |

**User's choice:** pcall-test dispatcher patterns

---

## Stale TODO in conform.lua

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — remove in 10-01 cleanup | Stale comment removed as alignment cleanup. No functional change. | ✓ |
| No — leave it | Ignore — not worth a commit. | |

**User's choice:** Remove in 10-01 cleanup

---

## Artifact Naming

| Option | Description | Selected |
|--------|-------------|----------|
| Log files only | `keymap-regression.log` and `format-regression.log` in `.planning/tmp/nvim-validate/`. | ✓ |
| Structured JSON | JSON artifacts for parseable output. | |

**User's choice:** Log files only

---

## Format-on-save Test Approach

| Option | Description | Selected |
|--------|-------------|----------|
| Direct Lua function test | Call format_on_save guard with mock buffer contexts. Verify true/false returns. | ✓ |
| BufWritePre headless trigger | Open buffers, :doautocmd BufWritePre, check for errors. Harder to isolate. | |
| CHECKLIST.md manual only | Move format-on-save to manual steps only. | |

**User's choice:** Direct Lua function test

---

## 10-04 Warning Audit Approach

| Option | Description | Selected |
|--------|-------------|----------|
| Fresh audit first | Run checkhealth, enumerate WARNINGs, classify, fix config-caused. | ✓ |
| Known targets only | Skip audit — fix known overlapping-keymap warnings directly. | |

**User's choice:** Fresh audit first

---

## 10-04 Tracking

| Option | Description | Selected |
|--------|-------------|----------|
| Update FAILURES.md | Consistent with Phase 6 D-12 living-doc pattern. | ✓ |
| New WARNINGS.md artifact | Separate tracking for warning-level issues. | |

**User's choice:** Update FAILURES.md — config-caused warnings → Fixed; env-only → Won't Fix / By Design.

---

## CHECKLIST.md Phase 10 Structure

| Option | Description | Selected |
|--------|-------------|----------|
| New Phase 10 section | Add "Phase 10 Regression Checks" section to existing CHECKLIST.md. | ✓ |
| Standalone REGRESSION.md | New file in phase 10 dir for manual checks. | |
| You decide | Claude picks. | |

**User's choice:** New Phase 10 section in existing CHECKLIST.md

---

## Claude's Discretion

- Exact pcall-test string values for `keymaps` subcommand
- Mock buffer context setup approach for `formats` subcommand in headless Lua
- Specific LSP attach safety scenarios in CHECKLIST.md Phase 10 section
- README "Reading validation output" section placement within the file
- Order of commits within each plan
