---
phase: "14"
slug: "live-full-adopt-verify"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-04"
---

# Phase 14 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Inline bash asserts — no `bats`/`pytest` suite in this repo (Phase 6/12/13 pattern) |
| **Config file** | none — plan-task `<verify><automated>` blocks plus two standalone scripts |
| **Quick run command** | `bash -n scripts/phase14-preflight.sh && bash -n scripts/phase14-verify.sh && bash -n arch/dots-hyprland.sh` |
| **Full suite command** | `./scripts/phase14-preflight.sh` (plan 14-01, pre-adopt) · `./scripts/phase14-verify.sh` (plan 14-02, post-adopt) |
| **Regression guard** | `./scripts/phase12-full-smoke.sh` — must stay `FAIL=0` after the D-28 `PROTECT_EXPLICIT` edit; `./scripts/phase13-d19-assert.sh` — guards the D-03 sync fence |
| **Estimated runtime** | preflight ~2–5 seconds; verify ~3–8 seconds |

---

## Sampling Rate

- **After every task commit (14-01):** Run `bash -n` on every script the task touched, plus that task's `<verify><automated>` block.
- **After every plan wave (14-01):** Run `./scripts/phase14-preflight.sh` in check-only mode, `./scripts/phase12-full-smoke.sh`, and `./scripts/phase13-d19-assert.sh`.
- **During the adopt window:** The preflight exit code is one input to the human go/no-go decision (D-18). The window itself produces the `script(1)` transcript, not test output.
- **After every task commit (14-02):** Re-run `./scripts/phase14-verify.sh` and append its output to `14-LIVE-VERIFY.md`.
- **Before `/gsd-verify-work`:** `./scripts/phase14-verify.sh` must exit 0. Recorded findings are allowed; hard failures are not.
- **Max feedback latency:** under 10 seconds for every automated command.

---

## Per-Task Verification Map

Task IDs are seeded from the requirement-to-test map in `14-RESEARCH.md` §Validation Architecture. The planner replaces each `{plan}-{NN}` placeholder with the real task ID when the plans are written; the requirement, test type, and command columns are binding as written.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 14-01-{NN} | 01 | 1 | ADOPT-01 | T-14-preflight-rotation | Backup rotation is opt-in, never an implicit side effect of a check run | smoke | `bash -n scripts/phase14-preflight.sh && ./scripts/phase14-preflight.sh` | ❌ W0 | ⬜ pending |
| 14-01-{NN} | 01 | 1 | ADOPT-01 | T-14-banned-flags | Runbook names all four banned flags and carries one unambiguous go/no-go sequence | smoke | `grep -c . docs/phase14-adopt-runbook.md && grep -q -- '--force' docs/phase14-adopt-runbook.md && grep -q -- '--skip-backup' docs/phase14-adopt-runbook.md && grep -q -- '--firstrun' docs/phase14-adopt-runbook.md && grep -q -- '--skip-hyprland-entry' docs/phase14-adopt-runbook.md` | ❌ W0 | ⬜ pending |
| 14-01-{NN} | 01 | 1 | ADOPT-04 | T-14-setup-uninstall-drift | Rollback text names all three wrapper-owned tiers and never reaches for upstream `./setup uninstall` | smoke | `grep -q 'uninstall --configs-only' docs/phase14-adopt-runbook.md && ! grep -qE '(\./)?setup uninstall' docs/phase14-adopt-runbook.md` | ❌ W0 | ⬜ pending |
| 14-01-{NN} | 01 | 1 | ADOPT-01 | T-14-protect-list-edit | `waybar` and `swaync` leave `PROTECT_EXPLICIT`; `hyprpaper` stays; cascade protection still behaves | smoke | `! grep -qE '^  (waybar\|swaync)$' arch/dots-hyprland.sh && grep -qE '^  hyprpaper$' arch/dots-hyprland.sh && ./scripts/phase12-full-smoke.sh` | ✅ | ⬜ pending |
| 14-01-{NN} | 01 | 1 | ADOPT-01 | T-14-sync-touches-custom | The D-07 live-to-repo sync never writes into `.config/hypr/custom/` | smoke | `test -z "$(git diff --name-only HEAD~1 -- .config/hypr/custom)" && ./scripts/phase13-d19-assert.sh` | ✅ | ⬜ pending |
| 14-01-{NN} | 01 | 1 | ADOPT-01 | T-14-unprovable-baseline | Pre-adopt sha256 baseline is recorded before any mutation, so D-36 and D-37 stay provable | smoke | `test -s .planning/phases/14-live-full-adopt-verify/14-PRE-ADOPT-BASELINE.txt && grep -q 'hyprland.conf' .planning/phases/14-live-full-adopt-verify/14-PRE-ADOPT-BASELINE.txt` | ❌ W0 | ⬜ pending |
| 14-01-{NN} | 01 | 1 | ADOPT-01 | T-14-agent-runs-install | No agent-runnable artifact carries a mutating `install --full` without `--dry-run` | smoke | `! grep -rEn 'install --full(?! *--dry-run)' --include='*-PLAN.md' .planning/phases/14-live-full-adopt-verify/ \|\| true` | ❌ W0 | ⬜ pending |
| 14-02-{NN} | 02 | 1 | ADOPT-02 | T-14-skip-hyprland-entry | Session loads through the ii Lua entry, proven three independent ways | smoke | `./scripts/phase14-verify.sh` (ADOPT-02 block: `hyprland.conf.old` exists, `hyprland.lua` exists, `hyprland.conf` gone, `hyprctl -j status` reports `configProvider != "hyprlang"`, `hyprctl eval 'return 1+1'` is accepted) | ❌ W0 | ⬜ pending |
| 14-02-{NN} | 02 | 1 | ADOPT-03 | — | DP-1 present at pre-adopt scale; 11 workspace rules from the overlay; `qs -c ii` running; `waybar` and `swaync` not running | smoke | `./scripts/phase14-verify.sh` (ADOPT-03 block) | ❌ W0 | ⬜ pending |
| 14-02-{NN} | 02 | 1 | ADOPT-04 | T-14-rollback-inputs | Rollback inputs exist — D-26 asks for the inputs, not for a restore rehearsal | smoke | `./scripts/phase14-verify.sh` (ADOPT-04 block: `test -f ~/.config/hypr/hyprland.conf.old`; backup dir non-empty and newer than install start; repo `.config/hypr/hyprland.conf` present; `arch/dots-hyprland.sh uninstall --dry-run` and `arch/dots-hyprland.sh protect --dry-run` both exit 0) | ❌ W0 | ⬜ pending |
| 14-02-{NN} | 02 | 1 | ADOPT-03 | — | Repo tree is clean after the install apart from phase-dir transcript and verify artifacts (D-35) | smoke | `./scripts/phase14-verify.sh` (D-35 block) | ❌ W0 | ⬜ pending |
| 14-02-{NN} | 02 | 1 | ADOPT-03 | T-14-firstrun-clobber | Phase 11 D-24 held: live `hyprlock.conf` (554 bytes) and `hypridle.conf` (359 bytes) byte-identical to pre-install, `.new` sidecars unpromoted (D-37) | smoke | `./scripts/phase14-verify.sh` (D-37 block, compared against `14-PRE-ADOPT-BASELINE.txt`) | ❌ W0 | ⬜ pending |
| 14-02-{NN} | 02 | 1 | ADOPT-03 | — | Screen share works; the named known-loss list is confirmed rather than assumed (D-38) | smoke | `./scripts/phase14-verify.sh` (D-38 block, including the `busctl --user` ScreenCast portal probe) | ❌ W0 | ⬜ pending |

---

## Wave 0 Requirements

- [ ] `scripts/phase14-preflight.sh` — covers ADOPT-01 and ADOPT-04 input existence
- [ ] `scripts/phase14-verify.sh` — covers ADOPT-02, ADOPT-03, ADOPT-04 (D-26/D-36), plus D-35, D-37, D-38
- [ ] `docs/phase14-adopt-runbook.md` — covers ADOPT-01 (the go/no-go gate itself) and ADOPT-04 (D-23/D-25)
- [ ] `.planning/phases/14-live-full-adopt-verify/14-PRE-ADOPT-BASELINE.txt` — must be written before any mutation; without it D-36 and D-37 are unprovable
- [ ] `.gitignore` entry for `.gsd/`, or a commit of it — without this, D-35's clean-tree assert can never pass
- [ ] No framework install needed — the repo has no test framework and this phase does not add one

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Monitors and layout look correct on screen after first ii login | ADOPT-03 | No non-visual proxy exists for "the layout looks right"; `hyprctl` can confirm the rule set but not the rendered result | Log in at the TTY via `start-hyprland`. Confirm DP-1 renders at the pre-adopt scale, the bar is the ii bar, and workspaces land where the overlay places them. Record the result in `14-LIVE-VERIFY.md`. |
| Launcher keybind opens the ii launcher | ADOPT-03 | `rofi` has no `exec-once`; it is bound as `$menu` at `hyprland.conf:41`, so a running-process check is vacuous | Press the launcher keybind. Confirm the ii launcher appears and rofi does not. Record the result in `14-LIVE-VERIFY.md`. |
| Operator go/no-go decision at the ADOPT-01 gate | ADOPT-01 | The gate is a human judgement over the runbook checklist; the preflight exit code is one input, not the decision | Work the runbook checklist top to bottom inside the `script(1)` session. State the go or no-go decision aloud so it lands in the transcript. |
| Install proceeds from a bare TTY with Hyprland stopped | ADOPT-01 | Only the operator can stop the running session and switch to a bare TTY | Stop Hyprland, switch to a bare TTY, start `script(1)`, then run `./arch/dots-hyprland.sh install --full`. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
