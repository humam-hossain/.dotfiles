---
phase: "14"
slug: "live-full-adopt-verify"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: validated
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
- **Reading preflight output:** The preflight prints at three levels and only `[FAIL]` moves the exit code. `[FINDING]` lines are expected and do not fail a sampling run. One is load-bearing: the `ii-original-dots-backup` report fires whenever the directory exists, as it does today with a stale inner `hyprland.conf`. Clearing it requires `--rotate-backup`, an operator-only `$HOME` mutation reserved for the adopt window, so the hard blocker for it lives in the runbook's no-go list, not in the exit code (D-18). A sampling run that treats that finding as a failure is misreading the contract.
- **Before Task `14-01-06` commits:** `./scripts/phase14-preflight.sh` legitimately exits 1 on the D-15/D-35 clean-and-pushed check, because the runbook is not committed or pushed yet. That is the only tolerated failure during 14-01.
- **During the adopt window:** The preflight exit code is one input to the human go/no-go decision (D-18). The window itself produces the `script(1)` transcript, not test output.
- **After every task commit (14-02):** Re-run `./scripts/phase14-verify.sh` and append its output to `14-LIVE-VERIFY.md`.
- **Before `/gsd-verify-work`:** `./scripts/phase14-verify.sh` must exit 0. Recorded findings are allowed; hard failures are not.
- **Max feedback latency:** under 10 seconds for every automated command.

---

## Per-Task Verification Map

Task IDs are seeded from the requirement-to-test map in `14-RESEARCH.md` §Validation Architecture and were substituted with the real task IDs once `14-01-PLAN.md` and `14-02-PLAN.md` were written. The requirement, test type, and command columns are binding as written.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 14-01-05 | 01 | 1 | ADOPT-01 | T-14-preflight-rotation | Backup rotation is opt-in, never an implicit side effect of a check run; the stale-backup condition is reported at the `[FINDING]` tier, not encoded as an exit code an agent could only clear by mutating `$HOME` | smoke | `bash -n scripts/phase14-preflight.sh && ./scripts/phase14-preflight.sh --help 2>&1 \| grep -q -- '--rotate-backup' && M0=$(stat -c %Y "$HOME/ii-original-dots-backup") && { ./scripts/phase14-preflight.sh >/tmp/p14-pre.txt 2>&1 \|\| true; } && test "$(stat -c %Y "$HOME/ii-original-dots-backup")" = "$M0" && grep -qE '^\[FINDING\].*ii-original-dots-backup' /tmp/p14-pre.txt && ! grep -qE '^\[FAIL\].*ii-original-dots-backup' /tmp/p14-pre.txt` | ✅ | ✅ COVERED |
| 14-01-06 | 01 | 1 | ADOPT-01 | T-14-preflight-green | Once the tree is clean and pushed, the preflight's default path exits 0 with zero `[FAIL]` lines while still surfacing the backup finding — the exit code is input 1 to the human gate (D-18) | smoke | `./scripts/phase14-preflight.sh >/tmp/p14-post.txt 2>&1 && test "$(grep -c '^\[FAIL\]' /tmp/p14-post.txt)" -eq 0 && grep -qE '^\[FINDING\].*ii-original-dots-backup' /tmp/p14-post.txt` | ✅ | ⚠ COVERED (red: unpushed commit) |
| 14-01-06 | 01 | 1 | ADOPT-01 | T-14-banned-flags | Runbook names all four banned flags, carries one unambiguous go/no-go sequence, and lists the unrotated stale backup as a hard no-go the exit code does not enforce | smoke | `grep -c . docs/phase14-adopt-runbook.md && grep -q -- '--force' docs/phase14-adopt-runbook.md && grep -q -- '--skip-backup' docs/phase14-adopt-runbook.md && grep -q -- '--firstrun' docs/phase14-adopt-runbook.md && grep -q -- '--skip-hyprland-entry' docs/phase14-adopt-runbook.md && grep -q -- '--rotate-backup' docs/phase14-adopt-runbook.md && grep -q 'FINDING' docs/phase14-adopt-runbook.md` | ✅ | ✅ COVERED |
| 14-01-06 | 01 | 1 | ADOPT-04 | T-14-setup-uninstall-drift | Rollback text names all three wrapper-owned tiers and never reaches for upstream `./setup uninstall` | smoke | `grep -q 'uninstall --configs-only' docs/phase14-adopt-runbook.md && ! grep -qE '(\./)?setup uninstall' docs/phase14-adopt-runbook.md` | ✅ | ✅ COVERED |
| 14-01-04 | 01 | 1 | ADOPT-01 | T-14-protect-list-edit | `waybar` and `swaync` leave `PROTECT_EXPLICIT`; `hyprpaper` stays; cascade protection still behaves | smoke | `! grep -qE '^  (waybar\|swaync)$' arch/dots-hyprland.sh && grep -qE '^  hyprpaper$' arch/dots-hyprland.sh && ./scripts/phase12-full-smoke.sh` | ✅ | ✅ COVERED |
| 14-01-03 | 01 | 1 | ADOPT-01 | T-14-sync-touches-custom | The D-07 live-to-repo sync never writes into `.config/hypr/custom/` | smoke | `test -z "$(git diff --name-only HEAD~1 -- .config/hypr/custom)" && ./scripts/phase13-d19-assert.sh` | ✅ | ✅ COVERED |
| 14-01-02 | 01 | 1 | ADOPT-01 | T-14-unprovable-baseline | Pre-adopt sha256 baseline is recorded before any mutation, so D-36 and D-37 stay provable | smoke | `test -s .planning/phases/14-live-full-adopt-verify/14-PRE-ADOPT-BASELINE.txt && grep -q 'hyprland.conf' .planning/phases/14-live-full-adopt-verify/14-PRE-ADOPT-BASELINE.txt` | ✅ | ✅ COVERED |
| 14-01-01 | 01 | 1 | ADOPT-01 | T-14-agent-runs-install | No agent-runnable artifact carries a mutating `install --full` without `--dry-run` | smoke | `test "$(grep -v '^[[:space:]]*#' scripts/phase14-preflight.sh \| grep -c 'install --full')" -ge 1 && test "$(grep -v '^[[:space:]]*#' scripts/phase14-preflight.sh \| grep -c 'install --full')" -eq "$(grep -v '^[[:space:]]*#' scripts/phase14-preflight.sh \| grep -c 'install --full --dry-run')"` | ✅ | ✅ COVERED |
| 14-02-03 | 02 | 2 | ADOPT-02 | T-14-skip-hyprland-entry | Session loads through the ii Lua entry, proven three independent ways | smoke | `./scripts/phase14-verify.sh` (ADOPT-02 block: `hyprland.conf.old` exists, `hyprland.lua` exists, `hyprland.conf` gone, `hyprctl -j status` reports a `configProvider` differing from `configProvider_pre` as read from `14-PRE-ADOPT-BASELINE.txt` — the absence of the observed pre-adopt token, never the presence of a guessed post-adopt one — and `hyprctl eval 'return 1+1'` is accepted) | ✅ | ✅ COVERED |
| 14-02-04 | 02 | 2 | ADOPT-03 | — | DP-1 present (enforced) and its scale compared against `dp1_scale_pre` with any difference recorded as a `[FINDING]`, never a failure (D-14); 11 workspace rules from the overlay (enforced); `qs -c ii` running; `waybar` and `swaync` not running | smoke | `./scripts/phase14-verify.sh` (ADOPT-03 block) | ✅ | ✅ COVERED |
| 14-02-04 | 02 | 2 | ADOPT-04 | T-14-rollback-inputs | Rollback inputs exist — D-26 asks for the inputs, not for a restore rehearsal | smoke | `./scripts/phase14-verify.sh` (ADOPT-04 block: `test -f ~/.config/hypr/hyprland.conf.old`; backup dir non-empty and newer than install start; repo `.config/hypr/hyprland.conf` present; `arch/dots-hyprland.sh uninstall --dry-run` and `arch/dots-hyprland.sh protect --dry-run` both exit 0) | ✅ | ✅ COVERED |
| 14-02-04 | 02 | 2 | ADOPT-03 | — | Repo tree is clean after the install apart from phase-dir transcript and verify artifacts (D-35) | smoke | `./scripts/phase14-verify.sh` (D-35 block) | ✅ | ✅ COVERED |
| 14-02-04 | 02 | 2 | ADOPT-03 | T-14-firstrun-clobber | Phase 11 D-24 held: live `hyprlock.conf` (554 bytes) and `hypridle.conf` (359 bytes) byte-identical to pre-install, `.new` sidecars unpromoted (D-37) | smoke | `./scripts/phase14-verify.sh` (D-37 block, compared against `14-PRE-ADOPT-BASELINE.txt`) | ✅ | ✅ COVERED |
| 14-02-04 | 02 | 2 | ADOPT-03 | — | The named known-loss list is confirmed rather than assumed, and the ScreenCast portal is probed explicitly; a broken portal is a recorded `[FINDING]` and a Phase 15 item, not a phase failure (D-38) | smoke | `./scripts/phase14-verify.sh` (D-38 block, including the `busctl --user` ScreenCast portal probe) | ✅ | ✅ COVERED |
| 14-02-05 | 02 | 2 | ADOPT-03 | — | The written record carries the script output, the human answers, and every finding with a disposition (D-29, D-31, D-32) | smoke | `test -s .planning/phases/14-live-full-adopt-verify/14-LIVE-VERIFY.md && grep -q '## Findings (D-14, D-38)' .planning/phases/14-live-full-adopt-verify/14-LIVE-VERIFY.md && grep -q '## Human checklist (D-29, D-30)' .planning/phases/14-live-full-adopt-verify/14-LIVE-VERIFY.md && grep -q '\[PASS\]' .planning/phases/14-live-full-adopt-verify/14-LIVE-VERIFY.md` | ✅ | ✅ COVERED |

**Note on the `T-14-agent-runs-install` command.** The original form used a PCRE negative lookahead
(`install --full(?! *--dry-run)`) under `grep -E`, which POSIX ERE does not support, and closed with
`|| true`, which swallowed both the resulting grep error and any real match — it could never fail.
It is replaced above with a lookahead-free count comparison, scoped to the one agent-runnable
artifact the constraint actually binds: `scripts/phase14-preflight.sh`. Comment lines are filtered
so a header that names the flag does not self-satisfy or self-invalidate the gate. The `>= 1` half
makes it non-vacuous — a script with no wrapper invocation at all fails rather than passing
silently. `arch/dots-hyprland.sh` is deliberately out of scope: it is the installer, so it carries
the mutating path by definition. `docs/phase14-adopt-runbook.md` and the two `*-PLAN.md` files are
also out of scope: they carry the mutating invocation as operator instruction, which is the whole
point of D-01, and the `--dry-run` constraint binds executable artifacts, not prose the operator
reads at a TTY.

---

## Wave 0 Requirements

- [x] `scripts/phase14-preflight.sh` — covers ADOPT-01 and ADOPT-04 input existence
- [x] `scripts/phase14-verify.sh` — covers ADOPT-02, ADOPT-03, ADOPT-04 (D-26/D-36), plus D-35, D-37, D-38
- [x] `docs/phase14-adopt-runbook.md` — covers ADOPT-01 (the go/no-go gate itself) and ADOPT-04 (D-23/D-25)
- [x] `.planning/phases/14-live-full-adopt-verify/14-PRE-ADOPT-BASELINE.txt` — must be written before any mutation; without it D-36 and D-37 are unprovable
- [x] `.gitignore` entry for `.gsd/`, or a commit of it — without this, D-35's clean-tree assert can never pass
- [x] No framework install needed — the repo has no test framework and this phase does not add one

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Monitors and layout look correct on screen after first ii login | ADOPT-03 | No non-visual proxy exists for "the layout looks right"; `hyprctl` can confirm the rule set but not the rendered result | Log in at the TTY via `start-hyprland`. Confirm DP-1 renders at the pre-adopt scale, the bar is the ii bar, and workspaces land where the overlay places them. Record the result in `14-LIVE-VERIFY.md`. |
| Launcher keybind opens the ii launcher | ADOPT-03 | `rofi` has no `exec-once`; it is bound as `$menu` at `hyprland.conf:41`, so a running-process check is vacuous | Press the launcher keybind. Confirm the ii launcher appears and rofi does not. Record the result in `14-LIVE-VERIFY.md`. |
| Operator go/no-go decision at the ADOPT-01 gate | ADOPT-01 | The gate is a human judgement over the runbook checklist; the preflight exit code is one input, not the decision | Work the runbook checklist top to bottom inside the `script(1)` session. Read every preflight line, not just the exit code — `[FINDING]` lines do not move it and the `ii-original-dots-backup` one is a hard no-go until runbook step 5 has been run. State the go or no-go decision aloud so it lands in the transcript. |
| Rotating `~/ii-original-dots-backup` before the install | ADOPT-01 | The rotation is a `$HOME` mutation reserved for the operator-owned adopt window; no agent invocation may perform it, which is why the preflight reports the condition rather than failing on it (D-13, D-18, D-27) | Inside the window, run `./scripts/phase14-preflight.sh --rotate-backup`, then re-run `./scripts/phase14-preflight.sh` and confirm the `ii-original-dots-backup` line has flipped from `[FINDING]` to `[PASS]`. Skip only if the preflight already reported the directory absent. |
| Install proceeds from a bare TTY with Hyprland stopped | ADOPT-01 | Only the operator can stop the running session and switch to a bare TTY | Stop Hyprland, switch to a bare TTY, start `script(1)`, then run `./arch/dots-hyprland.sh install --full`. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter — **not set**: 5 behaviors are documented manual-only (operator judgement, rendered layout, keybind, `$HOME` mutation, bare-TTY install). None is an automatable gap.

**Approval:** validated 2026-09-05 — PARTIAL (14 automated COVERED, 1 automated COVERED-but-red on an unpushed commit, 5 manual-only)

---

## Validation Audit 2026-09-05

Ran at `verify:post` after Phase 14 UAT closed 15/15 with zero issues. Every command in the
Per-Task Verification Map was executed against the live post-adopt tree.

| Metric | Count |
|--------|-------|
| Map rows audited | 15 |
| COVERED (green) | 14 |
| COVERED (red, environmental) | 1 |
| MISSING | 0 |
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
| Manual-only (unchanged) | 5 |

**Evidence.** `bash -n` clean on `scripts/phase14-preflight.sh`, `scripts/phase14-verify.sh` and
`arch/dots-hyprland.sh`. `./scripts/phase12-full-smoke.sh` → `FAIL=0`. `./scripts/phase13-d19-assert.sh`
exit 0. `./scripts/phase14-verify.sh` → exit 0, 38 `[PASS]`, `FAIL=0 FINDINGS=1` (the known D-38
`graphical-session.target` finding, already dispositioned as a Phase 15 item). Default-path preflight
left `~/ii-original-dots-backup` mtime unchanged at `1788543226`, reported the backup condition at
`[FINDING]` and never at `[FAIL]`.

**The one red row.** `T-14-preflight-green` requires zero `[FAIL]` lines from the default preflight
path. The current run emits exactly one: `[FAIL] D-15/D-35 1 commit(s) not on origin/main`. That
commit is `c48a5af`, the UAT record this very session wrote. The assertion is doing its job — it is
a clean-and-pushed gate, and the tree is momentarily one commit ahead. It is not a coverage gap and
needs no new test; it clears on `git push`.

**No auditor spawn.** `gsd-nyquist-auditor` was not dispatched: gap analysis found zero MISSING
requirements, so there was nothing for it to fill.
