---
phase: "16"
slug: "retire-the-safe-profile-full-only-wrapper-and-playbook"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-09-07"
validated: "2026-09-08"
---

# Phase 16 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Hand-rolled Bash assert scripts with `pass()` / `fail()` helpers and a `FAIL` counter |
| **Config file** | none — each script is self-contained, `set -euo pipefail`, run from `REPO_ROOT` |
| **Quick run command** | `./scripts/phase12-full-smoke.sh && ./scripts/phase11-dispositions-assert.sh` |
| **Full suite command** | `./scripts/phase16-retire-assert.sh && ./scripts/phase13-d19-assert.sh && ./scripts/phase12-full-smoke.sh && ./scripts/phase11-dispositions-assert.sh && ./scripts/phase14-verify.sh` |
| **Estimated runtime** | ~30 seconds (excluding `phase14-verify.sh` live session checks) |

---

## Sampling Rate

- **After every task commit:** Run `bash -n arch/dots-hyprland.sh` (wrapper waves) or the touched file's own assert script
- **After every plan wave:** Run the four tree-clean-agnostic scripts — `phase16-retire-assert.sh`, `phase12-full-smoke.sh`, `phase11-dispositions-assert.sh`, `phase13-d19-assert.sh` (the last is expected red until the re-pin wave)
- **Before `/gsd-verify-work`:** Full suite green on a committed, clean tree, with `phase14-verify.sh` at `FAIL=0`
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

Task IDs are assigned by the planner; this map is keyed by phase decision/requirement ID. The Plan and Wave columns were filled during the post-execution audit from each plan's `requirements:` frontmatter.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| — | 16-01 | 1 | FULL-01 / FULL-02 | — | Bare `install-files --dry-run` emits none of `--core` / `--skip-hyprland` / `--skip-sysupdate` | unit (argv) | `./scripts/phase16-retire-assert.sh` | ✅ | ✅ green |
| — | 16-01 | 1 | D-05 | — | `--full` accepted, prints ignored-note, absent from would-exec argv | unit (argv) | `./scripts/phase16-retire-assert.sh` | ✅ | ✅ green |
| — | 16-01 | 1 | D-06 | — | `--skip-backup` present in would-exec argv for `install` / `install-files` | unit (argv) | `./scripts/phase16-retire-assert.sh` | ✅ | ✅ green |
| — | 16-01 | 1 | D-06 / D-09 | — | No `[CONFIG] Type 'yes' to continue` on `install --dry-run` | unit (stdout) | `./scripts/phase16-retire-assert.sh` | ✅ | ✅ green |
| — | 16-01 / 16-02 | 1–2 | D-07 | — | `protect` rejected as non-allowlisted (exit ≠ 0) | unit (exit code) | `./scripts/phase12-full-smoke.sh` | ✅ rewritten (D-34) | ✅ green |
| — | 16-01 / 16-02 | 1–2 | D-11 | — | `bash -n arch/dots-hyprland.sh` clean; `preflight` and array-exec intact | unit (syntax) | `./scripts/phase12-full-smoke.sh` | ✅ | ✅ green |
| — | 16-01 / 16-03 | 1–2 | D-10 | — | `uninstall --dry-run` exits 0 with the stripped flag set | integration (dry-run) | `./scripts/phase14-verify.sh` | ✅ | ✅ green |
| — | 16-04 | 3 | D-36 | — | Playbook §10 carries no `--skip-hyprland`; file carries no "dual-run" / "safe profile" | unit (grep) | `./scripts/phase16-retire-assert.sh` | ✅ | ✅ green |
| — | 16-06 | 4 | W-3 | — | Playbook §6 fence matches the D-18 SoT fence | unit (diff) | `./scripts/phase13-d19-assert.sh` | ✅ extended | ✅ green |
| — | 16-07 / 16-08 | 5 | W-1 | — | `11-DISPOSITIONS.md` still satisfies every required token | unit (grep) | `./scripts/phase11-dispositions-assert.sh` | ✅ | ✅ green |
| — | 16-06 | 4 | D-38 | — | Wrapper unmodified since the Phase 16 baseline `0771cc2` | unit (git) | `./scripts/phase13-d19-assert.sh` | ✅ re-pinned | ✅ green |
| — | 16-10 | 7 | ADOPT-02 / ADOPT-03 | — | Session still on the Lua entry; Waybar/rofi/swaync still stopped | integration (live) | `./scripts/phase14-verify.sh` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `scripts/phase16-retire-assert.sh` — new assert script covering FULL-01, FULL-02, D-05, D-06, D-09, D-36
- [x] `scripts/phase12-full-smoke.sh` — rewritten body for the full-only wrapper (D-34)
- [x] `scripts/phase13-d19-assert.sh` — third baseline tier plus the W-3 drift assert (D-38)
- [x] No framework install needed — the "framework" is `pass` / `fail` plus a `FAIL` counter, already present in five scripts

**Baseline recorded during research (all green, clean tree):**

```
./scripts/phase12-full-smoke.sh          → === done: FAIL=0 ===              exit 0
./scripts/phase13-d19-assert.sh          → === Phase 13 asserts: FAIL=0 ===  exit 0
./scripts/phase11-dispositions-assert.sh → === done: FAIL=0 ===              exit 0
./scripts/phase10-inventory-assert.sh    → === done: FAIL=0 ===              exit 0
./scripts/phase14-verify.sh              → === done: FAIL=0 FINDINGS=1 ===   exit 0
```

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Post-change login re-verify | D-40 | Needs a real reboot or re-login into a fresh Hyprland session; no headless equivalent | Reboot or log out and back in, then run `./scripts/phase14-verify.sh` on a committed, clean tree and confirm `FAIL=0` |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated 2026-09-08 — every requirement row in the map is covered by an automated command and every command is green.

---

## Validation Audit 2026-09-08

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

State A audit (existing VALIDATION.md). All twelve requirement rows already named an automated command; none was MISSING or PARTIAL, so no auditor agent was spawned and no test files were generated. Every command was re-run on a committed, clean tree:

```
./scripts/phase16-retire-assert.sh       → === done: FAIL=0 ===              exit 0
./scripts/phase12-full-smoke.sh          → === done: FAIL=0 ===              exit 0
./scripts/phase11-dispositions-assert.sh → === done: FAIL=0 ===              exit 0
./scripts/phase10-inventory-assert.sh    → === done: FAIL=0 ===              exit 0
./scripts/phase13-d19-assert.sh          → === Phase 13 asserts: FAIL=0 ===  exit 0
./scripts/phase14-verify.sh              → === done: FAIL=0 FINDINGS=2 ===   exit 0
```

Two deviations from the pre-audit baseline, neither a regression in Phase 16 code:

1. **`phase14-verify.sh` first ran `FAIL=1`.** The sole failure was D-35 (dirty working tree), caused by an uncommitted `16-REVIEW.md`. The report was committed and the re-run is `FAIL=0`.
2. **`FINDINGS` is 2, not the 1 that `docs/dots-hyprland-workflow.md:326` and `16-10-SUMMARY.md` quote.** The second finding is `D-38 ScreenCast portal answers AvailableSourceTypes = 'u 0', pre-adopt was 'u 7'` (`scripts/phase14-verify.sh:455`). This is live-session drift downstream of the same known compositor-target loss the first finding reports — `graphical-session.target` is inactive, so the portal now advertises no source types. It is a `finding`, not a `fail`, and it is already deferred to Phase 15. The playbook's quoted expectation is now one finding short of what a live re-run prints.
