---
phase: 13
slug: personal-hypr-custom-overlays
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-08-17
updated: 2026-08-31
---

# Phase 13 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> **No live apply and no live full install this phase.** Automated checks are repo file existence / content greps + D-19 fence.
>
> 2026-08-31 audit: the 2026-08-17 draft matrix was **superseded** by 2026-08-19 CONTEXT (cursor/venv overlays dropped; env.lua/execs.lua are empty require slots, `test -f` only). Those draft rows are not evidence. Commands below are the current PLAN `<verify><automated>` blocks and D-19, re-run this session.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Inline bash asserts (Phase 6/12 pattern) — no bats/pytest suite in repo |
| **Config file** | none — plan-task `<verify><automated>` commands + D-19 fence |
| **Quick run command** | `test -f .config/hypr/custom/env.lua && test -s .config/hypr/custom/general.lua && test -f .config/hypr/custom/execs.lua && test -f .planning/phases/13-personal-hypr-custom-overlays/13-SOT-APPLY.md` |
| **Full suite command** | `./scripts/phase13-d19-assert.sh` (extracts D-19 from 13-SOT-APPLY.md, `luac -p`, empty-slot checks, live-absent, wrapper unmodified) |
| **Estimated runtime** | ~2–5 seconds |

---

## Sampling Rate

- **After every task commit:** existence of the file that task created + the task’s automated verify block
- **After every plan wave:** `./scripts/phase13-d19-assert.sh`
- **Before `/gsd-verify-work`:** full suite green; **no** live apply and **no** `install --full`
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 13-01-01 | 01 | 1 | OVL-01 | T-D17-leakage | Dual-head `hl.monitor` + eleven monitor-only `hl.workspace_rule`; no root monitors/workspaces.lua; no custom keybinds/rules | smoke | PLAN 13-01-01 `<automated>` (test -s general.lua; greps DP-1/HDMI-A-2/hl.monitor/hl.workspace_rule/special:social/`scale = "auto"`; counts 2/11; prohibitions; vendor clean) | ✅ | ✅ green |
| 13-01-02 | 01 | 1 | OVL-02 | T-live-mutation | Empty `env.lua` require slot (`test -f`, no Lua statements); worktree ≠ live | smoke | PLAN 13-01-02 `<automated>` | ✅ | ✅ green |
| 13-01-03 | 01 | 1 | OVL-03 | T-vendor-pollution | Authoring SoT note; vendor/fork fence; one-way apply | smoke | PLAN 13-01-03 `<automated>` | ✅ | ✅ green |
| 13-02-01 | 02 | 2 | OVL-02 | T-live-mutation | Empty `execs.lua` require slot (`test -f`, no Lua statements) | smoke | PLAN 13-02-01 `<automated>` | ✅ | ✅ green |
| 13-02-02 | 02 | 2 | OVL-03 | T-rsync-delete / T-apply-missing-general.lua | D-18 `cp -a`; fail if general.lua missing; warn-and-continue slots; never `rsync --delete` | smoke | PLAN 13-02-02 `<automated>` | ✅ | ✅ green |
| 13-02-03 | 02 | 2 | OVL-01 | T-D17-leakage | D-19 fence extracted from 13-SOT-APPLY.md and executed from repo root | smoke | `./scripts/phase13-d19-assert.sh` (extract D-19; `bash -e`; `luac -p`) | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

Superseded draft rows (do not re-run): greps for `XCURSOR_THEME`, `ILLOGICAL_IMPULSE_VIRTUAL_ENV`, `setcursor`, and `test -s` on env.lua/execs.lua. Those were dropped in 2026-08-19 CONTEXT.

---

## Wave 0 Requirements

- [x] `.config/hypr/custom/general.lua` exists and is non-empty
- [x] `.config/hypr/custom/env.lua` exists (`test -f` only)
- [x] `.config/hypr/custom/execs.lua` exists (`test -f` only)
- [x] `13-SOT-APPLY.md` exists with D-18 apply + D-19 fence
- [x] `scripts/phase13-d19-assert.sh` extracts and runs D-19 (this audit)
- [x] **Do not** add live apply / session mutation checks this phase

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Live apply of repo custom/ onto `~/.config/hypr/custom/` | OVL-02 / D-02 | Phase 14 executes apply; this phase must not mutate live | After Phase 14: run the `cp -a` from 13-SOT-APPLY.md and confirm dual-head |
| Session actually honors `hl.workspace_rule` pins | OVL-01 | Requires live Hyprland after adopt | Phase 14: workspaces 1–5 / special:social on DP-1; 6–10 on HDMI-A-2 |
| DP-1 live scale | D-13 | Live compositor result | Phase 14: if scale is wrong, leave Phase 13 files; record in Phase 14 |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 5s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-08-31

---

## Validation Audit 2026-08-31

| Metric | Count |
|--------|-------|
| Gaps found | 4 |
| Resolved | 4 |
| Escalated | 0 |

Gaps (document, not product):
1. VALIDATION.md still `status: draft` / `nyquist_compliant: false` after execution
2. Per-task map all ⬜ pending
3. Wave 0 still claimed overlay files ABSENT
4. Draft commands expected dropped cursor/venv overlays

Resolution this session:
- Re-ran PLAN 13-01 automated[1..3] and 13-02 automated[1..2]: exit 0
- D-19 fence extracted from 13-SOT-APPLY.md: `bash -e` exit 0
- `./scripts/phase13-d19-assert.sh` FAIL=0
- PLAN 13-02 automated[3] XML one-liner was not shell-eval'd (quote split); equivalent extract+`bash -e` is the assert script and passed
- gsd-nyquist-auditor subagent 429'd; orchestrator filled gaps inline
