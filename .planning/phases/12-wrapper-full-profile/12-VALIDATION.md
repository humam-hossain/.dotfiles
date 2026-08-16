---
phase: 12
slug: wrapper-full-profile
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-11
---

# Phase 12 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Source: `12-RESEARCH.md` § Validation Architecture + CONTEXT D-01..D-17.
> **No live full install this phase.** All automated checks are help / dry-run / refuse / syntax.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Inline bash smoke asserts (Phase 6/07 pattern) — no bats/pytest suite in repo |
| **Config file** | none — plan-task `<verify><automated>` commands |
| **Quick run command** | `bash -n arch/dots-hyprland.sh && ./arch/dots-hyprland.sh help >/dev/null` |
| **Full suite command** | `./scripts/phase12-full-smoke.sh` (FULL-01..05 help / dry-run / refuse; all non-mutating) |
| **Estimated runtime** | ~5–15 seconds |

---

## Sampling Rate

- **After every task commit:** `bash -n arch/dots-hyprland.sh` + the task’s automated verify block
- **After every plan wave:** Full FULL-01..05 matrix (safe residual + full drop + refuse + protect plan + help)
- **Before `/gsd-verify-work`:** Full suite green; **no** live `install --full` without `--dry-run`
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------------|-----------------|-----------|-------------------|-------------|--------|
| 12-SYN | * | * | syntax | T-12-01 | Script parses; no eval injection | unit | `bash -n arch/dots-hyprland.sh` | ✅ | ⬜ pending |
| 12-FULL-01 | * | * | FULL-01 | T-12-02 | Help documents `--full`; full dry-run argv has no SAFE_DEFAULTS residuals | smoke | help grep `--full`; `printf 'yes\n' \| install --full --dry-run` + residual absence greps | ❌ W0 | ⬜ pending |
| 12-FULL-02 | * | * | FULL-02 | T-12-02 | Default install still injects triple residual | smoke (neg) | `printf 'yes\n' \| install --dry-run` greps `--core` + `--skip-hyprland` + `--skip-sysupdate` | ✅ path | ⬜ pending |
| 12-FULL-02b | * | * | FULL-02 | T-12-02 | Default install-files still injects | smoke | same with `install-files` | ✅ path | ⬜ pending |
| 12-FULL-03 | * | * | FULL-03 | T-12-03 | Bare `--skip-backup` refused on full without allow | smoke | `install --full --skip-backup --dry-run`; expect non-zero | ❌ W0 | ⬜ pending |
| 12-FULL-03b | * | * | FULL-03 | T-12-03 | Dual-key allow; meta stripped (`--full`, `--allow-skip-backup` not forwarded) | smoke | allow + dry-run greps | ❌ W0 | ⬜ pending |
| 12-FULL-04 | * | * | FULL-04 | T-12-02 | Full dry-run shows would-exec without SAFE_DEFAULTS; gate still hit | smoke | gate + would-exec + residual absence | ❌ W0 | ⬜ pending |
| 12-FULL-05 | * | * | FULL-05 | T-12-04 | Full dry-run still plans protect re-mark (+ ii hooks) | smoke | protect-list + ii hooks greps on full dry-run output | ❌ W0 | ⬜ pending |
| 12-D02 | * | * | D-02 | T-12-02 | `--full` refused on install-deps alone | smoke | `install-deps --full --dry-run`; expect non-zero | ❌ W0 | ⬜ pending |
| 12-D04 | * | * | D-04 | — | usage no longer says full requires vendor outside wrapper | grep | `! help \| grep -qi 'Full hypr install requires calling vendor'` | ❌ W0 | ⬜ pending |
| 12-D13 | * | * | D-13 | — | Help points at playbook | grep | `help \| grep -q 'dots-hyprland-workflow'` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky/partial*

---

## Wave 0 Requirements

- [x] Implement `--full` strip + conditional SAFE_DEFAULTS injection + full gate messaging + usage rewrite in `arch/dots-hyprland.sh`
- [x] Plan-task automated verify commands for FULL-01..05 matrix (inline; no dedicated test framework required)
- [x] `scripts/phase12-full-smoke.sh` — one-command FULL-01..05 harness (`./scripts/phase12-full-smoke.sh`)
- [x] **Do not** add live full install / session mutation checks this phase

*Existing Phase 6 dry-run patterns remain the template; there is no checked-in bats/pytest suite under `tests/`.*

---

## Requirement → Automated Gate Map

| Req ID | Behavior | Automated check | Status |
|--------|----------|-----------------|--------|
| FULL-01 | Help documents `--full`; full dry-run argv has no `--skip-hyprland` (and no other SAFE_DEFAULTS residuals per DISP-02) | `./arch/dots-hyprland.sh help \| grep -q -- '--full'`; `printf 'yes\n' \| ./arch/dots-hyprland.sh install --full --dry-run \| tee /tmp/p12-full.txt`; `! grep -q -- '--skip-hyprland' /tmp/p12-full.txt`; `! grep -q -- '--skip-sysupdate' /tmp/p12-full.txt`; `! grep -E -- '(^|[[:space:]])--core([[:space:]]|$)' /tmp/p12-full.txt` | ⬜ |
| FULL-02 | Default install still injects triple residual | `printf 'yes\n' \| ./arch/dots-hyprland.sh install --dry-run \| tee /tmp/p12-safe.txt`; greps for all three residuals | ⬜ |
| FULL-02b | Default install-files still injects | same with `install-files` | ⬜ |
| FULL-03 | Bare `--skip-backup` refused on full without allow | `./arch/dots-hyprland.sh install --full --skip-backup --dry-run; test $? -ne 0` | ⬜ |
| FULL-03b | Dual-key allow still works; meta stripped | dry-run greps: `--skip-backup` present; `--allow-skip-backup` and `--full` absent | ⬜ |
| FULL-04 | Full dry-run shows would-exec without SAFE_DEFAULTS; gate still hit | gate/type-yes evidence + `would exec` + residual absence | ⬜ |
| FULL-05 | Full dry-run still plans protect re-mark (+ ii hooks per D-16) | `grep -q 'protect-list'` + ii hooks on full dry-run output | ⬜ |
| D-02 | `--full` refused on install-deps | non-zero exit | ⬜ |
| D-04 | Help no longer points full path outside wrapper | negative grep on vendor-outside note | ⬜ |
| D-13 | Help points at playbook | `dots-hyprland-workflow` in help | ⬜ |
| syntax | Script parses | `bash -n arch/dots-hyprland.sh` | ⬜ |

---

## Concrete command cheatsheet (executor copy-paste)

```bash
# Syntax
bash -n arch/dots-hyprland.sh

# Help / discoverability
./arch/dots-hyprland.sh help | grep -E -- '--full|dots-hyprland-workflow|SAFE_DEFAULTS|safe defaults'

# Safe residual (must still inject)
printf 'yes\n' | ./arch/dots-hyprland.sh install --dry-run
printf 'yes\n' | ./arch/dots-hyprland.sh install-files --dry-run

# Full profile argv (must NOT inject residuals)
printf 'yes\n' | ./arch/dots-hyprland.sh install --full --dry-run
printf 'yes\n' | ./arch/dots-hyprland.sh install-files --full --dry-run

# Negative: bare skip-backup
./arch/dots-hyprland.sh install --full --skip-backup --dry-run   # expect non-zero

# Negative: --full on wrong subcommand
./arch/dots-hyprland.sh install-deps --full --dry-run            # expect non-zero

# Gate abort still works
printf 'no\n' | ./arch/dots-hyprland.sh install --full --dry-run # expect non-zero
```

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Full-gate messaging covers all D-07 blast-radius themes with acceptable wording | D-07 | Exact strings are Claude discretion | After impl: read full dry-run stderr/stdout for no-SAFE_DEFAULTS residual, `.old` risk, misc overwrite, sysupdate, `~/ii-original-dots-backup`, bare skip-backup refuse note |
| Live full install / session mutation | FULL-* live | **Out of scope Phase 12** — Phase 14 | Do not run without `--dry-run` in this phase |

*All FULL-01..05 automated gates above are non-mutating.*

---

## Security notes (ASVS L1 planning)

| Threat | Control | Verify |
|--------|---------|--------|
| Accidental full default (anti-goal) | SAFE_DEFAULTS still inject when `full=0` | FULL-02 matrix |
| Meta-flag forwarded to `./setup` | Strip `--full` like other meta flags | FULL-03b greps |
| Bare `--skip-backup` bypass | Dual-key refuse | FULL-03 |
| Dry-run mutates system | dry-run path must not exec setup/sudo mutate | FULL-04 would-exec only |
| Command injection | Array exec `"${cmd[@]}"` only | code review / no `eval` |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter (after validate-phase)

**Approval:** pending
