---
phase: 10
slug: validation-harness-expansion
status: verified
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-23
last_audited: 2026-04-24
---

# Phase 10 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Shell-based validation harness around headless Neovim |
| **Config file** | `scripts/nvim-validate.sh` |
| **Quick run command** | `./scripts/nvim-validate.sh startup` |
| **Full suite command** | `./scripts/nvim-validate.sh all` |
| **Estimated runtime** | ~60 seconds |

---

## Sampling Rate

- **After every task commit:** Run `./scripts/nvim-validate.sh startup` until Phase 10 adds new subcommands, then run touched subcommand(s) directly
- **After every plan wave:** Run `./scripts/nvim-validate.sh all`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 10-01-01 | 01 | 1 | TEST-01 | T-10-01 | Validator keeps single entrypoint and aligned artifact contract | shell integration | `./scripts/nvim-validate.sh startup` | ✅ existing target | ✅ execution-ready |
| 10-02-01 | 02 | 2 | TEST-02 | T-10-02 | Headless probes exercise only proven blind spots without UI-event simulation | targeted regression | `./scripts/nvim-validate.sh keymaps` and `./scripts/nvim-validate.sh formats` | ✅ covered by Plan 10-02 Wave 0 tasking | ✅ execution-ready |
| 10-03-01 | 03 | 3 | TEST-03 | T-10-03 | Docs classify artifacts into config regressions vs env or optional-tool gaps | docs plus artifact review | `./scripts/nvim-validate.sh all` | ✅ covered by Plans 10-01 and 10-03 Wave 0 tasking | ✅ execution-ready |
| 10-04-01 | 04 | 1 | TEST-03 | T-10-04 | Fresh `checkhealth` audit classifies warnings before fixes or by-design disposition, then clears or explicitly dispositions every repo-owned warning family | headless audit | `./scripts/nvim-validate.sh checkhealth` | ✅ existing target | ✅ execution-ready |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `scripts/nvim-validate.sh` — covered by Plan 10-02 Task 1 and Task 2, which add `keymaps` and `formats` before any downstream verification depends on them
- [x] `.config/nvim/README.md` — covered by Plan 10-01 Task 1 and Plan 10-03 Tasks 1-2, which define the artifact contract and triage guidance before final phase verification
- [x] `.planning/phases/06-runtime-failure-inventory/CHECKLIST.md` — covered by Plan 10-02 Task 3, which adds the manual-only Phase 10 regression checks for LSP attach safety
- [x] `.planning/phases/06-runtime-failure-inventory/FAILURES.md` — covered by Plan 10-04 Task 1, which refreshes warning disposition after a fresh `checkhealth` audit

Wave 0 interpretation for this phase: required verification surfaces do not need to exist before planning; they need an explicit creation path before any later task depends on them. The four Phase 10 plans already provide that coverage, so Wave 0 is complete at planning time.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| LSP attach safety for protected callbacks | TEST-02 | Headless attach instrumentation is brittle and not a stable regression target | Follow new Phase 10 checklist section after running `./scripts/nvim-validate.sh all`; open representative files, confirm no attach-time errors, and record any env-only gaps separately |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved for execution

---

## Validation Audit 2026-04-24

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

All 4 automated commands verified green:
- `startup` → PASS
- `keymaps` → PASS (3 probes)
- `formats` → PASS (3 probes)
- `checkhealth` → PASS (only tolerated headless/env-only ERRORs present)
