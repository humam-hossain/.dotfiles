---
phase: "24"
slug: "address-tech-debt-bookkeeping-and-validation-cleanup"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-16"
---

# Phase 24 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `24-RESEARCH.md` § Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Bash Assert Harness (`scripts/phase24-tech-debt-assert.sh`) + strict verify (`arch/dots-hyprland.sh verify --strict`) |
| **Config file** | None — standalone executable assert script under `scripts/` adhering to four-prefix contract |
| **Quick run command** | `./scripts/phase24-tech-debt-assert.sh --section <1-5>` |
| **Full suite command** | `./scripts/phase24-tech-debt-assert.sh && ./arch/dots-hyprland.sh verify --strict` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run `./scripts/phase24-tech-debt-assert.sh --section <N>`
- **After every plan wave:** Run `./scripts/phase24-tech-debt-assert.sh`
- **Before `/gsd-verify-work`:** Full suite must be green (`FAIL=0`) AND `./arch/dots-hyprland.sh verify --strict` exits 0 (`FAIL=0 FINDINGS=0`)
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 24-01-01 | 01 | 1 | DEBT-04 | T-24-01 | Session keybind reallocation (SUPER+Scroll_Lock sleep, SUPER+SHIFT+Scroll_Lock logout, unbind SUPER+SHIFT+L) with `luac -p` check and zero duplicate chords | unit | `luac -p stow/hypr/.config/hypr/custom/keybinds.lua` | ✅ | ⬜ pending |
| 24-01-02 | 01 | 1 | DEBT-04 | T-24-02 | Live compositor binds query confirms session controls registration via `hyprctl binds -j` | live integration | `hyprctl binds -j \| jq -e '.[] \| select(.key == "Scroll_Lock")'` | ✅ | ⬜ pending |
| 24-01-03 | 01 | 1 | DEBT-03 | T-24-03 | Scope `*.socket` in `.gitignore` with `!stow/systemd/**` exception | unit | `git check-ignore -v stow/systemd/foo.socket \|\| true` | ✅ | ⬜ pending |
| 24-02-01 | 02 | 2 | DEBT-01 | — | Reconcile 10 stale `Pending` status markers in `REQUIREMENTS.md` across Phase 20 and 23 | docs / trace | `grep -c 'Pending' .planning/REQUIREMENTS.md` | ✅ | ⬜ pending |
| 24-02-02 | 02 | 2 | DEBT-01 | — | Backfill `requirements_completed` frontmatter in plan summaries (23-01, 23-02, 23-03, 18-02, 18-03) | docs / trace | `node /home/pera/.hermes/gsd-core/bin/gsd-tools.cjs query summary-extract .planning/phases/23-one-command-bootstrap/23-01-SUMMARY.md --fields requirements_completed` | ✅ | ⬜ pending |
| 24-02-03 | 02 | 2 | DEBT-02 | — | Reconcile `VALIDATION.md` files across Phases 17, 18, 20, 21, 22, 23 to `status: validated` and `nyquist_compliant: true` | docs / trace | `grep -c 'nyquist_compliant: true' .planning/phases/*/*-VALIDATION.md` | ✅ | ⬜ pending |
| 24-02-04 | 02 | 2 | DEBT-03 | T-24-04 | Document non-credential status of `stow/system_monitor/.../.env` and 12 gitleaks allowlist entries in `STATE.md` | docs / state | `grep -q 'system_monitor.*\.env' .planning/STATE.md` | ✅ | ⬜ pending |
| 24-03-01 | 03 | 3 | DEBT-01..04 | — | Author dedicated assert harness `scripts/phase24-tech-debt-assert.sh` covering sections 1–5 | harness | `./scripts/phase24-tech-debt-assert.sh` | ❌ W0 | ⬜ pending |
| 24-03-02 | 03 | 3 | DEBT-01..04 | T-24-05 | Strict verification gate and zero working tree drift | system check | `./arch/dots-hyprland.sh verify --strict && git status --porcelain` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `scripts/phase24-tech-debt-assert.sh` — comprehensive assertion harness covering all Phase 24 deliverables (sections 1–5)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Quickshell cheatsheet visual rendering (`SUPER + /`) | DEBT-04 | Live visual appearance inspection | Press `SUPER + /` in active Hyprland session; verify `Session` category displays `Lock screen (Scroll_Lock)`, `Sleep (SUPER + Scroll_Lock)`, and `Logout (SUPER + SHIFT + Scroll_Lock)` with clean layout and no duplicate chords. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
