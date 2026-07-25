---
phase: 5
slug: fork-submodule-pin
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-25
---

# Phase 5 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None — shell / git assertions (no Bats/pytest/jest) |
| **Config file** | none |
| **Quick run command** | Inline OWN-01/02/03 git checks (see map below) |
| **Full suite command** | Full OWN-01 + OWN-02 + OWN-03 sequence |
| **Estimated runtime** | ~5–15 seconds |

---

## Sampling Rate

- **After every task commit:** Run the OWN checks affected by that task
- **After every plan wave:** Run full OWN-01 + OWN-02 + OWN-03 sequence
- **Before `/gsd:verify-work`:** Full checklist green; no `./setup`, no session tests
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 05-01-* | 01 | 1 | OWN-01 | T-05-01 / — | Fork URL fixed; no tokens in repo | smoke | `git -C vendor/dots-hyprland remote get-url origin`; `… upstream` | ❌ W0 (inline) | ⬜ pending |
| 05-02-* | 02 | 1–2 | OWN-02 | T-05-02 / — | `.gitmodules` URL = fork only | smoke | `git config -f .gitmodules --get submodule.vendor/dots-hyprland.url`; `git ls-tree HEAD vendor/dots-hyprland` | ❌ W0 (inline) | ⬜ pending |
| 05-03-* | 03 | 2 | OWN-03 | T-05-03 / — | Nested shapes host remains end-4 | smoke | `git submodule update --init --recursive`; `test -f vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/widgets/shapes/LICENSE` | ❌ W0 (inline) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Embed OWN assert commands in each plan's `## Verification` (preferred) OR optional `scripts/phase05-submodule-assert.sh`
- [ ] No framework install required
- [ ] Do not gate on nvim-validate or quickshell session health

*Existing nvim harness is irrelevant to Phase 5.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Sibling path left untouched | D-14 | External path not in repo | Confirm `~/github_repo/dots-hyprland` was not deleted/rewired |
| No `./setup` executed | D-16 | Destructive install is out of phase | Confirm no install ran during phase |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
