---
phase: 5
slug: fork-submodule-pin
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-07-25
---

# Phase 5 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None — shell / git / gh assertions (no Bats/pytest/jest) |
| **Config file** | none |
| **Quick run command** | Inline OWN-01/02/03 git+gh checks (see map below) |
| **Full suite command** | Full OWN-01 + OWN-02 + OWN-03 sequence (05-03 Task 1 verify) |
| **Estimated runtime** | ~5–15 seconds |

---

## Sampling Rate

- **After every task commit:** Run the automated command for that task row
- **After every plan wave:** Run full OWN-01 + OWN-02 + OWN-03 sequence
- **Before `/gsd:verify-work`:** Full checklist green; no `./setup`, no session tests
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 05-01-T1 | 01 | 1 | OWN-01 | T-05-01 | Fork only of end-4; no tokens logged | smoke | `gh repo view humam-hossain/dots-hyprland --json name,isFork,visibility,url,parent --jq 'select(.isFork==true and .name=="dots-hyprland") \| .name'` | ✅ inline | ✅ green |
| 05-01-T2 | 01 | 1 | OWN-01 | T-05-01 / T-05-02 | Public fork; parent end-4; no secrets | smoke | `gh repo view humam-hossain/dots-hyprland --json isFork,visibility,parent --jq 'select(.isFork==true and (.visibility\|ascii_upcase)=="PUBLIC" and .parent.nameWithOwner=="end-4/dots-hyprland") \| "OWN-01-fork-ok"'` | ✅ inline | ✅ green |
| 05-02-T1 | 02 | 2 | OWN-02 | T-05-01 / T-05-06 | `.gitmodules` url = fork SSH; no branch auto-track | smoke | `test -f .gitmodules && git config -f .gitmodules --get submodule.vendor/dots-hyprland.url \| grep -q 'git@github.com:humam-hossain/dots-hyprland.git' && ! grep -E '^\s*branch\s*=' .gitmodules && test -e vendor/dots-hyprland/.git && git submodule status vendor/dots-hyprland \| grep -E '^[ +][0-9a-f]{40} vendor/dots-hyprland'` | ✅ inline | ✅ green |
| 05-02-T2 | 02 | 2 | OWN-01, OWN-03 | T-05-02 / T-05-03 | Nested shapes end-4 host; dual remotes; no setup | smoke | `git submodule update --init --recursive && test -f vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/widgets/shapes/LICENSE && ! git -C vendor/dots-hyprland submodule status --recursive \| grep -E '^-' && git -C vendor/dots-hyprland remote get-url origin \| grep -q 'git@github.com:humam-hossain/dots-hyprland.git' && git -C vendor/dots-hyprland remote get-url upstream \| grep -q 'https://github.com/end-4/dots-hyprland.git' && git -C vendor/dots-hyprland config -f .gitmodules --get-regexp url \| grep -q 'rounded-polygon-qmljs'` | ✅ inline | ✅ green |
| 05-03-T1 | 03 | 3 | OWN-01, OWN-02, OWN-03 | T-05-01 / T-05-03 | Full pre-commit OWN checklist; no setup | smoke | `SM=vendor/dots-hyprland; SHAPES="$SM/dots/.config/quickshell/ii/modules/common/widgets/shapes"; git -C "$SM" remote get-url origin \| grep -q 'git@github.com:humam-hossain/dots-hyprland.git' && git -C "$SM" remote get-url upstream \| grep -q 'https://github.com/end-4/dots-hyprland.git' && test -f .gitmodules && git config -f .gitmodules --get submodule.vendor/dots-hyprland.url \| grep -q 'git@github.com:humam-hossain/dots-hyprland.git' && ! grep -E '^\s*branch\s*=' .gitmodules && git submodule update --init --recursive && test -f "$SHAPES/LICENSE" && ! git -C "$SM" submodule status --recursive \| grep -E '^-' && PIN=$(git -C "$SM" rev-parse HEAD) && git submodule status "$SM" \| grep -q "$PIN"` | ✅ inline | ✅ green |
| 05-03-T2 | 03 | 3 | OWN-01, OWN-02, OWN-03 | T-05-02 / T-05-06 | Path-scoped pin; 160000 gitlink; push optional | smoke | `git ls-tree HEAD vendor/dots-hyprland \| grep -qE '^160000 commit [0-9a-f]{40}' && test -f .gitmodules && git rev-parse HEAD:.gitmodules >/dev/null && PIN=$(git -C vendor/dots-hyprland rev-parse HEAD) && git ls-tree HEAD vendor/dots-hyprland \| grep -q "$PIN" && git -C vendor/dots-hyprland remote get-url origin \| grep -q 'humam-hossain/dots-hyprland' && git -C vendor/dots-hyprland remote get-url upstream \| grep -q 'end-4/dots-hyprland' && test -f vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/widgets/shapes/LICENSE && ! grep -E '^\s*branch\s*=' .gitmodules` | ✅ inline | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

*All six tasks embed `<automated>` verifies in PLAN.md — no missing test files; no Wave 0 scaffold required.*

---

## Wave 0 Requirements

- [x] Embed OWN assert commands in each plan's `<verify><automated>` (inline preferred; no `scripts/phase05-submodule-assert.sh` required)
- [x] No framework install required
- [x] Do not gate on nvim-validate or quickshell session health

*Existing nvim harness is irrelevant to Phase 5. Wave 0 complete — all verifies are inline.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Sibling path left untouched | D-14 | External path not in repo | Confirm `~/github_repo/dots-hyprland` was not deleted/rewired |
| No `./setup` executed | D-16 | Destructive install is out of phase | Confirm no install ran during phase |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify (no MISSING / Wave 0 test-file gaps)
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (none — inline only)
- [x] No watch-mode flags
- [x] Feedback latency < 15s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending (map matches 05-01/02/03 PLAN verifies; execute-phase will flip task Status)


---

## Post-execute audit (2026-07-25)

All six automated task verifies re-run after pin commit `9484ee2`:

| Task | Result |
|------|--------|
| 05-01-T1 | ✅ green |
| 05-01-T2 | ✅ green (parent via owner.login+name; gh JSON lacks nameWithOwner) |
| 05-02-T1 | ✅ green |
| 05-02-T2 | ✅ green |
| 05-03-T1 | ✅ green |
| 05-03-T2 | ✅ green |

Manual D-14 sibling + D-16 no-setup: confirmed.

**Nyquist compliance:** true (inline smoke only; no framework). Status → validated.
