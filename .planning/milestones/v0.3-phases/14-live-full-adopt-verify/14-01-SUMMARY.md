---
phase: 14-live-full-adopt-verify
plan: 01
subsystem: infra
tags: [bash, hyprland, illogical-impulse, runbook, preflight, rollback, git]

# Dependency graph
requires:
  - phase: 10-full-install-impact-inventory
    provides: 10-INVENTORY.md and scripts/phase10-inventory-assert.sh, gated by the preflight's ADOPT-01 check
  - phase: 11-disposition-decisions
    provides: 11-DISPOSITIONS.md and scripts/phase11-dispositions-assert.sh, plus D-07/D-08/D-17/D-24/D-28 dispositions the runbook encodes
  - phase: 12-full-profile-wrapper
    provides: arch/dots-hyprland.sh --full path, the backup gate, and scripts/phase12-full-smoke.sh as the D-28 regression guard
  - phase: 13-personal-hypr-custom-overlays
    provides: .config/hypr/custom/ overlays, 13-SOT-APPLY.md apply fence, scripts/phase13-d19-assert.sh
provides:
  - Non-mutating go-condition preflight (scripts/phase14-preflight.sh) with a three-level PASS/FINDING/FAIL output contract
  - Opt-in --rotate-backup, the single mutating path, guarded behind its own flag
  - Complete operator runbook (docs/phase14-adopt-runbook.md) — one D-21 sequence, go/no-go gate, banned flags, three rollback tiers
  - 14-PRE-ADOPT-BASELINE.txt — the only non-circular comparison source for D-36 and D-37 after the install
  - Pre-adopt repo archive of the live hypr tree plus dolphinrc and kdeglobals (D-07)
  - PROTECT_EXPLICIT without waybar/swaync, so rollback tier 3 cannot resurrect them (D-28)
affects: [14-02 live verify, phase 15 findings follow-up, rollback]

actuals:
  tokens: 28635
  tasks: 6
  commits: 7

tech-stack:
  added: []
  patterns:
    - "Three-level assert output (PASS/FINDING/FAIL) where only FAIL moves the exit code"
    - "Opt-in mutation flag: destructive step behind its own flag, called from exactly one guarded site after all checks"
    - "Baseline-fixture comparison — record pre-mutation facts to git so post-mutation claims stay provable"

key-files:
  created:
    - scripts/phase14-preflight.sh
    - docs/phase14-adopt-runbook.md
    - .planning/phases/14-live-full-adopt-verify/14-PRE-ADOPT-BASELINE.txt
    - .config/hypr/hyprland.conf.bak
    - .config/hypr/hyprland-gui.conf
    - .config/dolphinrc
    - .config/kdeglobals
  modified:
    - arch/dots-hyprland.sh
    - .gitignore
    - .config/hypr/hyprland.conf

key-decisions:
  - "Rotation of ~/ii-original-dots-backup lives behind an opt-in --rotate-backup flag, not on the preflight's default path (recorded deviation from D-27, restored by two runbook mechanisms)"
  - "The existing stale backup is reported at the [FINDING] tier, never [FAIL], so the human checklist stays the gate (D-18)"
  - "Three extra .gitignore entries beyond .gsd/ were required for the D-15/D-35 clean-tree condition to be reachable at all"
  - "HDMI-A-2 is attached, contradicting 14-RESEARCH.md Pitfall 3; observed value recorded with a drift NOTE plus three hdmi_a2_*_pre geometry keys"

patterns-established:
  - "Finding tier: a condition only an operator-owned $HOME mutation can clear is reported, not failed, and its hard blocker lives in the human go/no-go list"
  - "Rollback inputs are proven (dry-run exit codes, archive presence), never rehearsed (D-26)"

requirements-completed: []

coverage:
  - id: D1
    description: "scripts/phase14-preflight.sh reports every mechanical go condition and exits 0 when they all hold"
    requirement: "ADOPT-01"
    verification:
      - kind: integration
        ref: "./scripts/phase14-preflight.sh"
        status: pass
      - kind: other
        ref: "bash -n scripts/phase14-preflight.sh"
        status: pass
    human_judgment: false
  - id: D2
    description: "The preflight's default path mutates nothing under $HOME and is safe to re-run"
    requirement: "ADOPT-01"
    verification:
      - kind: integration
        ref: "stat -c %Y $HOME/ii-original-dots-backup unchanged across repeated default-path runs; ls -A1 entry list unchanged"
        status: pass
      - kind: other
        ref: "grep -cE 'rm -rf|rsync .*--delete' scripts/phase14-preflight.sh == 0; the only mv is inside rotate_backup, called from one flag-guarded site"
        status: pass
    human_judgment: false
  - id: D3
    description: "The existing stale ~/ii-original-dots-backup is reported at the [FINDING] tier, keeping the default path green while surfacing the condition"
    requirement: "ADOPT-01"
    verification:
      - kind: integration
        ref: "grep -qE '^\\[FINDING\\].*ii-original-dots-backup' on captured preflight output; no matching ^\\[FAIL\\] line"
        status: pass
    human_judgment: false
  - id: D4
    description: "--rotate-backup performs the single mv, refuses when the directory is absent or the timestamped destination exists, and is unreachable on the default path"
    requirement: "ADOPT-01"
    verification:
      - kind: other
        ref: "static: rotate_backup defined once, called from one site guarded by ROTATE -eq 1, after all checks; --help names it as the only mutating path"
        status: pass
    human_judgment: true
    rationale: "The mv itself was deliberately NOT executed — running it would rotate 480K of the operator's home directory outside the adopt window and would invalidate the backup_dir_* keys plan 14-02 compares against. Only its guards are proven mechanically; the operator exercises the mv at runbook section 5."
  - id: D5
    description: "docs/phase14-adopt-runbook.md gives one unambiguous order for the whole adopt window, readable at a bare TTY, with go/no-go, banned flags, and three rollback tiers"
    requirement: "ADOPT-04"
    verification:
      - kind: other
        ref: "14 required literals present; grep -c '^## [0-9]' == 14 == outline entry count; zero occurrences of the upstream removal phrase; every chrome-bearing token is exactly google-chrome-stable"
        status: pass
    human_judgment: true
    rationale: "Literal presence is mechanical, but 'unambiguous to an operator at a bare TTY under stress' is exactly the property no grep asserts. A human must read the sequence end to end before the window opens."
  - id: D6
    description: "14-PRE-ADOPT-BASELINE.txt records the pre-adopt facts D-36 and D-37 depend on, committed before any mutation"
    verification:
      - kind: other
        ref: "all 20 required keys present; 9 anchored key greps pass; sha256 keys are 64 hex chars; grep -c '^[a-z0-9_]*=' == 22"
        status: pass
    human_judgment: false
  - id: D7
    description: "The repo holds a faithful pre-adopt archive of the live hypr tree plus dolphinrc and kdeglobals, in one commit, with .config/hypr/custom/ provably untouched"
    verification:
      - kind: integration
        ref: "cmp -s against live for all four text configs; git diff --name-only HEAD~1 -- .config/hypr/custom empty; ./scripts/phase13-d19-assert.sh exit 0"
        status: pass
    human_judgment: false
  - id: D8
    description: "waybar and swaync are out of PROTECT_EXPLICIT, hyprpaper remains, and the Phase 12 contract suite is still green"
    verification:
      - kind: integration
        ref: "./scripts/phase12-full-smoke.sh -> '=== done: FAIL=0 ==='"
        status: pass
      - kind: other
        ref: "grep -cE '^  waybar$' == 0; '^  swaync$' == 0; '^  hyprpaper$' == 1; '^  kitty$' == 1"
        status: pass
    human_judgment: false
  - id: D9
    description: "The working tree is clean and origin/main is current, so the runbook the operator reads at a TTY is the version on GitHub"
    requirement: "ADOPT-04"
    verification:
      - kind: other
        ref: "git status --porcelain empty; git rev-list --count origin/main..HEAD == 0"
        status: pass
    human_judgment: false

duration: 11 min
completed: 2026-09-04
status: complete
---

# Phase 14 Plan 01: Adopt-window prep Summary

**A read-only go-condition preflight with a three-level PASS/FINDING/FAIL contract, a 14-section bare-TTY adopt runbook with three rollback tiers, and the committed pre-adopt fact fixture that keeps D-36/D-37 provable after the install.**

## Performance

- **Duration:** 11 min
- **Started:** 2026-09-04T13:39:50Z
- **Completed:** 2026-09-04T13:51:00Z
- **Tasks:** 6
- **Files modified:** 17

## Accomplishments

- `scripts/phase14-preflight.sh` turns every mechanical go condition into an exit code across nine check groups (D-34 `installed_true`, D-12 submodule pin, ADOPT-01 INV-01/DISP-01 artifacts + assert scripts, Phase 13 overlay readiness, D-15/D-35 porcelain + pushed, D-13/D-27 backup report, D-26 rollback inputs, runbook presence, D-05 gate-fed dry-run). It exits 0 on this machine and provably mutates nothing under `$HOME` on its default path.
- The one destructive step — rotating `~/ii-original-dots-backup` — exists only behind `--rotate-backup`, called from exactly one guarded site after every check. It was **not** executed; `$HOME` is byte-for-byte as it was.
- `docs/phase14-adopt-runbook.md` carries one D-21 sequence over 14 numbered sections: prerequisites, transcript + offline copy, the go/no-go gate with the finding-tier blocker written out in full, all four banned flags plus the `yesforall` prohibition, the mandatory rotation step, the bare-TTY switch, the install walk-through in upstream's own execution order, the overlay apply by reference to `13-SOT-APPLY.md`, `stow -R kitty`, reboot, `start-hyprland`, verify, the two known-loss lists, and three rollback tiers with an explicit prohibition on the upstream removal subcommand.
- `14-PRE-ADOPT-BASELINE.txt` records 23 keys (all 20 required) before any mutation — the only non-circular source plan 14-02 can compare D-36 and D-37 against once the live pre-adopt conf is gone.
- The D-07 live-to-repo archive landed as a single revertible commit of five enumerated `cp -a` paths, with `.config/hypr/custom/` provably untouched.
- `waybar` and `swaync` are out of `PROTECT_EXPLICIT` so rollback tier 3 cannot resurrect them; `hyprpaper` stays; `phase12-full-smoke.sh` still prints `=== done: FAIL=0 ===`.
- The tree is clean and `origin/main` is current, so the runbook is readable from a phone.

## Task Commits

1. **Task 1 (tracer): preflight + runbook go/no-go frame** — `e2d44ba` (feat)
2. **Task 2: baseline fixture + `.gitignore`** — `09d07bc` (feat)
3. **Task 2: housekeeping of pre-existing dirty entries** — `cfe17ee` (chore)
4. **Task 3: D-07 live-to-repo `.config` archive** — `b9a8d43` (feat)
5. **Task 4: `PROTECT_EXPLICIT` D-28 edit** — `14c6828` (refactor)
6. **Task 5: full go-condition set + `--rotate-backup`** — `731015f` (feat)
7. **Task 6: full runbook body, then pushed to `origin/main`** — `22e90dd` (docs)

## Files Created/Modified

- `scripts/phase14-preflight.sh` — non-mutating go-condition preflight; `--rotate-backup` is its only mutating path
- `docs/phase14-adopt-runbook.md` — 14-section operator runbook for the adopt window
- `.planning/phases/14-live-full-adopt-verify/14-PRE-ADOPT-BASELINE.txt` — 23 pre-adopt fact keys for plan 14-02
- `.config/hypr/hyprland.conf` — archive refreshed to the live pre-adopt copy
- `.config/hypr/hyprland.conf.bak`, `.config/hypr/hyprland-gui.conf`, `.config/dolphinrc`, `.config/kdeglobals` — new archive entries
- `arch/dots-hyprland.sh` — two `PROTECT_EXPLICIT` deletions plus one reworded section comment
- `.gitignore` — `.gsd/` plus three derived/transient GSD paths
- `.planning/PROJECT.md`, `.planning/STATE.md`, `stow/zsh/.zshrc`, four Phase 13 artifacts — housekeeping so the clean-tree condition is reachable

## Decisions Made

- **Rotation is opt-in, not default-path** (the plan's own recorded deviation from D-27, implemented as written). A default-path rotation would mutate `$HOME` from a check run and would invalidate the `backup_dir_*` fixture keys 14-02 compares against. D-27's guarantee is restored by two runbook mechanisms: an unrotated stale backup is a hard no-go, and running `--rotate-backup` is a mandatory numbered step whenever the directory exists.
- **The backup condition is reported, not failed.** Encoding it as an exit code would leave the preflight unconditionally red during prep and would push an agent toward rotating early. D-18 puts the gate in the human checklist with the exit code as one input.
- **The `uninstall --dry-run` / `protect --dry-run` probes are fed empty stdin** (`printf '' |`). Both are dry-run-only and non-mutating, but feeding stdin explicitly stops either from blocking on a prompt inside a `set -e` script.
- **`.planning/state.json` and `.planning/milestone.lock` are ignored rather than tracked.** Both are derived/transient (an index over ROADMAP.md/STATE.md, and a session lock carrying a live PID). Tracking them would re-dirty the tree on every run and break the same D-15/D-35 condition this plan exists to satisfy.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `.gitignore` needed three entries beyond `.gsd/`**
- **Found during:** Task 2
- **Issue:** The plan (following `14-RESEARCH.md` Pitfall 1) listed seven dirty entries and only `.gsd/` as unignorable. Since that survey, `.planning/milestone.lock`, `.planning/state.json`, and `.planning/research/.cache/*` had also appeared untracked. With any of them present the D-15/D-35 clean-tree condition is permanently unreachable, so Task 6 could never pass.
- **Fix:** Appended all four patterns under one commented block. `.gsd/` per the plan; the other three because they are derived or transient (session lock with a live PID, an index derived from ROADMAP.md/STATE.md, and an HTTP response cache) and tracking them would re-dirty the tree on every subsequent run.
- **Files modified:** `.gitignore`
- **Verification:** `git check-ignore -q` on each; `git status --porcelain` empty at Task 6.
- **Committed in:** `09d07bc`

**2. [Rule 1 - Bug] Baseline drift: HDMI-A-2 is attached, contradicting the planned expectation**
- **Found during:** Task 2
- **Issue:** The plan's cross-check expected `hdmi_a2_present_pre=false`, and `14-RESEARCH.md` Pitfall 3 stated HDMI-A-2 was absent from `hyprctl -j monitors all` entirely. At capture time it is attached and active at `1920x1080@60.00000 scale=1.5 transform=1`. Writing the expected value would have put a false fact into the fixture plan 14-02 compares against.
- **Fix:** Recorded the observed value `true` with a six-line `# NOTE:` drift block naming the contradiction and its consequence for 14-02's dual-head check, per the plan's own drift instruction.
- **Files modified:** `.planning/phases/14-live-full-adopt-verify/14-PRE-ADOPT-BASELINE.txt`
- **Verification:** `hyprctl -j monitors all` re-queried; fixture value matches the live query.
- **Committed in:** `09d07bc`

**3. [Rule 3 - Blocking] Task 2's key-count criterion was unsatisfiable with exactly the 20 named keys**
- **Found during:** Task 2
- **Issue:** The acceptance criterion `grep -c '^[a-z0-9_]*=' ... is at least 20` cannot reach 20 with the 20 named keys, because one of them — `configProvider_pre`, named that way to mirror `hyprctl`'s own field — is camelCase and does not match a lowercase-only character class. The literal count came to 19. Renaming the key would have contradicted the plan's explicit key list and the artifacts_produced block.
- **Fix:** Kept `configProvider_pre` as named and added three genuinely useful keys made observable by deviation 2 — `hdmi_a2_mode_pre`, `hdmi_a2_scale_pre`, `hdmi_a2_transform_pre`, the pre-adopt counterparts of the existing `dp1_*` keys and direct ADOPT-03 dual-head inputs. Not filler: without them the drift above leaves 14-02 with no comparison basis for the second head.
- **Files modified:** `.planning/phases/14-live-full-adopt-verify/14-PRE-ADOPT-BASELINE.txt`
- **Verification:** `grep -c '^[a-z0-9_]*='` = 22; all 20 named keys present; the anchored `^configProvider_pre=hyprlang$` grep in the task verify still passes.
- **Committed in:** `09d07bc`

**4. [Rule 2 - Missing Critical] Two more archive files were mode 0600 than the plan flagged for secret review**
- **Found during:** Task 3
- **Issue:** The plan named `hyprland.conf.bak` and `hyprland-gui.conf` as the mode-0600 files needing a full read before staging into a public repo (threat T-14-06). On disk `dolphinrc` and `kdeglobals` are 0600 as well. Staging them without the same review would have left two unreviewed private-mode files in a public repo.
- **Fix:** Read all four in full and ran a credential/token/host-detail pattern scan before staging. All four are clean: a prior revision of the already-public `hyprland.conf`, a single HyprMod border-colour line, Dolphin view state, and a widget style plus colour scheme. All four normalised to 0644.
- **Files modified:** `.config/hypr/hyprland.conf.bak`, `.config/hypr/hyprland-gui.conf`, `.config/dolphinrc`, `.config/kdeglobals`
- **Verification:** Full read plus `grep -nEi` scan for password/secret/token/api-key/bearer/private-key/IP/email/AWS/GitHub/Slack patterns — no matches.
- **Committed in:** `b9a8d43` (reason recorded in the commit body)

**5. [Rule 1 - Bug] Runbook section 12 corrected against observed hardware state**
- **Found during:** Task 6
- **Issue:** The plan's section-12 text instructed the runbook to say HDMI-A-2 "is currently not attached" and that the verify script degrades to single-head. Per deviation 2 it is attached. Writing the plan's wording would have shipped an instruction contradicted by the machine in front of the operator.
- **Fix:** Section 12 asks the operator to keep HDMI-A-2 connected, notes that the baseline fixture records its pre-adopt geometry for comparison, and describes the single-head degrade as the fallback rather than the default.
- **Files modified:** `docs/phase14-adopt-runbook.md`
- **Verification:** Matches `14-PRE-ADOPT-BASELINE.txt` `hdmi_a2_present_pre=true` and its drift NOTE.
- **Committed in:** `22e90dd`

---

**Total deviations:** 5 auto-fixed (2 blocking, 2 bugs, 1 missing-critical).
**Impact on plan:** All five were necessary for correctness or safety. Deviations 1 and 3 unblocked acceptance criteria that were unsatisfiable as written; 2 and 5 stopped a false fact and a false instruction from shipping; 4 closed a threat-register gap the plan under-scoped. No scope creep — no new capability was added beyond the three baseline keys, which are justified by deviation 2.

## Threat Flags

None. No new network endpoint, auth path, file-access pattern, or schema at a trust boundary was introduced. The one new privileged surface — the `mv` in `rotate_backup` — is exactly the mitigation T-14-02 called for: literal paths built from the `BACKUP_DIR` constant, no computed path in a delete position, no `rm` or `rsync` anywhere in the file, and one flag-guarded call site.

## Issues Encountered

None. The pre-existing dirty working tree described in the task brief was resolved deliberately rather than discarded: two modified tracked files and four Phase 13 artifacts were committed (`cfe17ee`), and four derived/transient paths were added to `.gitignore` (`09d07bc`). Nothing was deleted and no work that was not mine was destroyed.

## User Setup Required

None — no external service configuration required. The plan produces artifacts the operator uses; it does not require credentials or dashboard setup.

## Next Phase Readiness

Everything plan 14-02 needs is on disk and pushed:

- `14-PRE-ADOPT-BASELINE.txt` is the fixture `scripts/phase14-verify.sh` compares D-36 and D-37 against.
- `.config/hypr/hyprland.conf` is rollback tier 1's second source and the D-35 hook target.
- The runbook's section 12 is where 14-02's verify script is invoked from.

**Two things the operator must know before the window opens:**

1. **`--rotate-backup` has not been run.** `~/ii-original-dots-backup` is present and its inner `hyprland.conf` is stale (backup 2026-07-23 vs live 2026-08-15). That is deliberate — it is an operator-owned `$HOME` mutation and runbook section 5 is where it happens. Until then the preflight will keep printing the `[FINDING]` line, which is correct behavior, and the go/no-go checklist treats an unrotated stale backup as a hard no-go.
2. **HDMI-A-2 is attached now**, contradicting `14-RESEARCH.md` Pitfall 3. Plan 14-02's verify script should be written to handle *both* states — the dual-head assertions are exercisable today, and the single-head degrade path is the fallback, not the expected case.

No blockers.

---
*Phase: 14-live-full-adopt-verify*
*Completed: 2026-09-04*

## Self-Check: PASSED

All 7 files listed in `key-files.created` exist on disk (`[ -f ]`). All 7 commit
hashes in **Task Commits** resolve in `git log --oneline --all`. The plan-level
`<verification>` block was re-run end to end after Task 6: `bash -n` clean,
`./scripts/phase14-preflight.sh` exit 0 with `FAIL=0 FINDINGS=1`,
`phase12-full-smoke.sh` `=== done: FAIL=0 ===`, `phase13-d19-assert.sh` exit 0,
`phase10-inventory-assert.sh` and `phase11-dispositions-assert.sh` exit 0, tree
clean and `origin/main` current, baseline fixture non-empty. `$HOME` is
unmutated: `~/ii-original-dots-backup` still holds `.config` and `.local` with an
unchanged mtime, and no `ii-original-dots-backup.*` rotated directory exists.
