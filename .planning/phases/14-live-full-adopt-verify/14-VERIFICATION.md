---
phase: 14-live-full-adopt-verify
verified: 2026-09-05T04:20:00Z
remediated: 2026-09-05T05:05:00Z
remediated_in: 859e434
status: passed
score: 4/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification: false
verifier_stance: adversarial (goal-backward, SUMMARY claims treated as unproven)
evidence_basis: >-
  Every verdict below rests on a command this verifier ran itself against the
  live system and the primary checkout at /home/pera/github_repo/.dotfiles
  (e96b0e3, clean, == origin/main). The phase's own scripts were re-run, but no
  verdict rests on them alone — each requirement was also probed with
  independent commands (hyprctl, sha256sum, stat, pgrep, busctl, git) whose
  output is quoted here.
findings:
  warnings: 3
  warnings_remediated: 2   # W1 retracted, W2 fixed in 859e434
  warnings_open: 1         # W3 — D-38 has no owning phase; operator decision
  info: 3
  blockers: 0
---

# Phase 14: Live full adopt & verify — Verification Report

**Phase Goal (ROADMAP.md):** *Live machine runs full hypr adopt per dispositions with verified session and safe rollback guidance*
**Verified:** 2026-09-05
**Status:** passed (4/4), with 3 warnings recorded for follow-up
**Re-verification:** No — initial verification

---

## Method and stance

Starting hypothesis: tasks completed, goal missed. Every claim in `14-01-SUMMARY.md`,
`14-02-SUMMARY.md` and `14-LIVE-VERIFY.md` was treated as unproven until an
independent command reproduced it. The phase's own instruments
(`scripts/phase14-verify.sh`, `scripts/phase14-preflight.sh`) were run, but they
are the artifact under test, so no verdict below rests on them alone. The
independent probes are quoted verbatim.

One useful accident strengthens the whole ADOPT-02 verdict: the live compositor
instance is now
`efb50993780079460b0cbed1363e2166a2de1d9f_1788582140_951177913`, which is **not**
the instance recorded in `14-LIVE-VERIFY.md`
(`…_1788577451_1908478201`). The session has been restarted since the phase
record was written, and it still comes up under the Lua config manager. The
adopt is therefore proven across a re-login, not only in the one session the
phase happened to observe.

---

## Goal Achievement

### Observable Truths (ROADMAP Success Criteria 1–4 = ADOPT-01..04)

| # | Truth | Status | Evidence I observed |
|---|---|---|---|
| 1 | ADOPT-01 — live full install ran only after INV-* and DISP-* were satisfied (process gate) | ✓ VERIFIED | Gate encoded, gate exercised, gate answered — three independent facts, below |
| 2 | ADOPT-02 — session loads via the ii Lua entry, not the pre-adopt personal `hyprland.conf` | ✓ VERIFIED | Four disk facts + two live-compositor facts, across a re-login |
| 3 | ADOPT-03 — monitors/layout per disposition, `qs -c ii` runs, dual-run policy matches DISP-03 | ✓ VERIFIED | 13 live compositor assertions reproduced independently; human half operator-attested |
| 4 | ADOPT-04 — rollback guidance exists and does not use upstream `./setup uninstall` | ✓ VERIFIED | Guidance read in full; three tier-1 sources hashed by hand; prohibition present; zero references to the upstream subcommand |

**Score:** 4/4 truths verified (0 present-but-behavior-unverified).

---

## ADOPT-01 — process gate

**Verdict: ✓ VERIFIED.**

The requirement is a *process* assertion, so I verified it in three separable
layers rather than accepting the runbook's existence as proof.

**(a) The gate is encoded, and it is a real check, not a comment.**

```
$ grep -n 'ADOPT-01' scripts/phase14-preflight.sh
147:# --- ADOPT-01: Phase 10 / Phase 11 source-of-truth artifacts ---
149:  pass "ADOPT-01 INV-01 inventory present and non-empty: $INVENTORY"
151:  fail "ADOPT-01 INV-01 inventory missing or empty: $INVENTORY"
154:  pass "ADOPT-01 DISP-01 dispositions present and non-empty: $DISPOSITIONS"
159:  pass "ADOPT-01 INV-01 phase10-inventory-assert.sh exits 0"
165:  pass "ADOPT-01 DISP-01 phase11-dispositions-assert.sh exits 0"
```

The `fail` branches move the exit code (`scripts/phase14-preflight.sh:320-321`),
so these are hard conditions, not narration.

**(b) The upstream artifacts predate the install by weeks and still assert green.**

```
$ git log -1 --format='%h %ad' --date=iso -- .../10-INVENTORY.md
64a0352 2026-08-04 20:28:43 +0600
$ git log -1 --format='%h %ad' --date=iso -- .../11-DISPOSITIONS.md
c6dd30e 2026-08-09 23:29:07 +0600

$ ./scripts/phase10-inventory-assert.sh     -> EXIT=0  phase10 inventory asserts OK
$ ./scripts/phase11-dispositions-assert.sh  -> EXIT=0  phase11 dispositions asserts OK
$ ./scripts/phase12-full-smoke.sh           -> EXIT=0  === done: FAIL=0 ===
$ ./scripts/phase13-d19-assert.sh           -> EXIT=0  === Phase 13 asserts: FAIL=0 ===
```

**(c) The gate was actually exercised before the one-way run — disk-attested, not
narrated.** This is the check that separates "a gate exists" from "the gate was
used", and it is the strongest evidence available because it is a filesystem
artifact nobody wrote by hand:

```
$ ls -d ~/ii-original-dots-backup*
/home/pera/ii-original-dots-backup
/home/pera/ii-original-dots-backup.20260904T171128Z
```

That name can be produced by exactly one thing in this repo —
`scripts/phase14-preflight.sh:76-77`, `dest="${BACKUP_DIR}.$(date -u +%Y%m%dT%H%M%SZ)"` —
reachable only via `--rotate-backup`, whose call site (`:302`) sits *after* every
check above. A repo-wide grep for any other producer of that name returns
nothing. The rotation stamp is **2026-09-04T17:11:28Z**; the install's own gate
was answered at **23:13:41 +06:00 = 17:13:41Z**. The preflight — checks and all —
ran **2 minutes 13 seconds before** the irreversible run.

**(d) The wrapper's own exact-token gate was answered by a human, in the transcript.**

```
$ grep -a -o "Type 'yes' to continue: [a-z]*" 14-ADOPT-TRANSCRIPT.txt
Type 'yes' to continue: yes
```

De-escaped, the command the operator typed is visible on the first prompt line:
`./arch/dots-hyprland.sh install --full`. Banned flags: I grepped the transcript
for `--skip-backup`, `--firstrun`, `--skip-hyprland-entry`, `--force` — **zero
matches**. `====> yesforall` — **zero matches**.

**Unobservable, stated plainly:** whether the operator *read and dispositioned*
the `[FINDING]` line at runbook §3 is a human act with no artifact. Everything
mechanically checkable about the gate is verified; that one residue is not, and
is not claimed.

---

## ADOPT-02 — the session loads via the ii Lua entry

**Verdict: ✓ VERIFIED.** Six independent facts, four of which I collected without
touching the phase's own script.

```
$ ls -la ~/.config/hypr/
-rw-r--r-- 1 pera pera 15301 Aug 15 11:02 hyprland.conf.old
-rw-r--r-- 1 pera pera  1204 Sep  4 23:34 hyprland.lua
# hyprland.conf: ABSENT
```

```
$ hyprctl -j status
{ "configProvider": "lua", "backend": "drm" }

$ hyprctl eval 'return 1+1'
ok

$ hyprctl instances
instance efb50993780079460b0cbed1363e2166a2de1d9f_1788582140_951177913: pid 1446
```

| # | Condition | Observed |
|---|---|---|
| 1 | `hyprland.conf.old` present | Yes, 15301 bytes |
| 2 | `hyprland.lua` present | Yes, 1204 bytes |
| 3 | `hyprland.conf` **absent** | Yes — no `.conf` can win regardless of 0.56.2's precedence |
| 4 | `configProvider` ≠ recorded pre-adopt `hyprlang` | Live value `lua`; fixture records `hyprlang` |
| 5 | `hyprctl eval` returns the Lua manager's `ok` | `ok` (hyprlang refuses this call outright) |
| 6 | The Lua entry actually sources the personal overlay | `~/.config/hypr/hyprland.lua` `require("custom.general")`, `require("custom.env")`, `require("custom.execs")` — read in full |

Fact 6 is the one the phase record does not make and I add here: the entry file
is not merely present, it is the file that pulls in the Phase 13 overlay, which
is what ties ADOPT-02 to ADOPT-03's live workspace rules rather than leaving them
two unrelated observations.

The instance signature differing from the phase record's means this held across a
re-login. The pre-adopt conf is preserved, not primary.

---

## ADOPT-03 — monitors/layout, `qs -c ii`, dual-run policy

**Verdict: ✓ VERIFIED** (automatable half by me; operator half attested).

**Monitors — probed directly, not via the phase script:**

```
$ hyprctl -j monitors all | jq -r '.[] | "\(.name) scale=\(.scale) transform=\(.transform)"'
DP-1      scale=1    transform=0   3440x1440
HDMI-A-2  scale=1.5  transform=1   1920x1080
```

Matches `.config/hypr/custom/general.lua:10` (`output = "HDMI-A-2"`, scale 1.5,
transform 1) and the fixture's `dp1_scale_pre=1`. Ran **dual-head**, so this half
is proven rather than skipped.

**Workspace rules — live in the running compositor, all eleven:**

```
$ hyprctl -j workspacerules | jq -r '.[] | "\(.workspaceString) -> \(.monitor)"'
1,2,3,4,5,special:social -> DP-1        (6/6)
6,7,8,9,10               -> HDMI-A-2    (5/5)
```

This is the load-vs-copy distinction and it lands on the right side: `test -f`
proves a copy, `hyprctl -j workspacerules` proves a load. I additionally
confirmed the overlay apply was named-file only, as D-18 requires:

```
general.lua IDENTICAL   env.lua IDENTICAL   execs.lua IDENTICAL   (live vs repo)
keybinds.lua / rules.lua / variables.lua: live-only ii seeds, no repo counterpart
```

No delete-sync ran.

**Shell surface:**

```
$ pgrep -af 'qs -c ii'
1493 qs -c ii
$ pgrep -x waybar -> rc 1   swaync -> rc 1   rofi -> rc 1
```

**Dual-run policy vs DISP-03 — checked, not assumed.** This is the clause most
open to a shifted goalpost, so I read the source requirement rather than the
phase's summary of it. `REQUIREMENTS.md:22` — DISP-03 defaults to **keep**
*"unless explicitly accepted otherwise"*. `11-DISPOSITIONS.md:199` is exactly that
explicit acceptance: *"This section explicitly accepts otherwise versus DISP-03 …
On full adopt, dual-run chrome disposition = accept-remove."* So the live state
satisfies DISP-03 through DISP-03's own escape hatch — not around it. I also
verified the *other* half of that accepted disposition, which the record asserts
but does not prove: D-12 requires the trees stay archived in the repo.

```
$ git ls-files | grep -cE '(^|/)(waybar|rofi|swaync)/'   -> 17 files under stow/{waybar,rofi,swaync}/
$ pacman -Qq waybar rofi swaync                          -> all three still installed
```

Accept-remove means *stopped launching*, and that is precisely what is on disk:
archives intact, packages intact, processes gone. Nothing was over-deleted.

**Operator-attested half (D-29, D-30).** Four checks answered in the affirmative
by the operator during the live window and recorded in
`14-LIVE-VERIFY.md § Human checklist`: layout renders across both monitors;
launcher keybind opens the ii launcher; workspaces land on the pinned monitor;
screen share works. These are taken as given per the verification brief. I did
not re-request them, and I do not mark ADOPT-03 unverified for them. Two of the
four have independent structural corroboration I collected:

- *Launcher keybind:* `~/.config/hypr/hyprland/keybinds.lua:12` binds
  `SUPER + SUPER_L` → `hl.dsp.global("quickshell:searchToggleRelease")`, and the
  Quickshell process that serves that global is pid 1493. The binding exists and
  its target is alive. Only the keypress proves the visual, which is why it is a
  human check.
- *Screen share:* `busctl --user get-property … ScreenCast AvailableSourceTypes`
  → `u 7`, byte-equal to the fixture's `screencast_source_types_pre=u 7`. The
  portal is not degraded relative to pre-adopt.

The phase's own script correctly refuses to count `rofi not running` as a pass
(it emits `[INFO] … vacuous`). That refusal is right and I confirm it: the
launcher never had an autostart, so its absence proves nothing.

---

## ADOPT-04 — rollback guidance without upstream `./setup uninstall`

**Verdict: ✓ VERIFIED.**

**The guidance exists and I read it in full.** `docs/phase14-adopt-runbook.md:302-360`
(§14), three escalating tiers:

- **Tier 1** — restore the config from three sources, preceded by a step-0
  `mv ~/.config/hypr/hyprland.lua ~/.config/hypr/hyprland.lua.ii-disabled` with
  the precedence ambiguity written out inline (the CR-01 remediation is present
  in the file, not just in the review's table). Sources are copied with `cp -a`,
  not `mv`, so restoring from source 1 does not consume it (WR-01 remediation
  present).
- **Tier 2** — `./arch/dots-hyprland.sh uninstall --configs-only|--packages-only`.
- **Tier 3** — `./arch/dots-hyprland.sh protect --install-missing`.

**The prohibition is explicit** (§14 "Prohibition"): *"The upstream vendor tree
ships its own removal subcommand. Never use it."*

**The negative check passes:**

```
$ grep -niE 'setup uninstall' docs/phase14-adopt-runbook.md
(no matches, exit 1)
$ grep -n 'upstream-dangerous' docs/phase14-adopt-runbook.md 14-LIVE-VERIFY.md
(no matches)
```

I did check the obvious way this could be quietly false: `arch/dots-hyprland.sh:1288-1304`
*does* contain a `run_upstream_uninstall_dangerous()` that runs `./setup uninstall`
as-is. It is a Phase 12 escape hatch behind a five-line warning wall and an exact
`UPSTREAM-UNINSTALL` token prompt, and it is referenced by **none** of the Phase 14
rollback guidance. ADOPT-04 constrains the guidance, and the guidance is clean.

**The rollback inputs are real, hashed by me rather than taken from the record:**

```
$ sha256sum ~/.config/hypr/hyprland.conf.old .config/hypr/hyprland.conf \
            ~/ii-original-dots-backup/.config/hypr/hyprland.conf
3d17932a6d2dd1b61ccc509402a70c224409bb5c24c4ed70a3c55d4f4bcd89b5  (all three)
$ stat -c '%s' on all three -> 15301 (all three)

$ grep hyprland_conf_sha256 14-PRE-ADOPT-BASELINE.txt
hyprland_conf_sha256=3d17932a6d2dd1b61ccc509402a70c224409bb5c24c4ed70a3c55d4f4bcd89b5
```

Three independent tier-1 sources, all byte-identical to the fixture recorded
before any mutation. **The backup demonstrably ran rather than being skipped** —
the fixture's pre-adopt backup copy hashed `c5c65023…` at mtime `1784818728`; the
current one hashes `3d17932a…` at mtime `1786770136`. The stale copy was replaced,
which is the fact `auto_backup_configs`' skip-when-present branch makes worth
checking.

Tiers 2 and 3 reachable: `uninstall --dry-run` and `protect --dry-run` each exit 0
(confirmed under the verify run; I did not invoke either without `--dry-run`).

D-24/D-37 held, verified independently:
`hyprlock.conf` = `c3ecd68d…` (554 B) and `hypridle.conf` = `6e720184…` (359 B),
both byte-equal to the fixture, with unpromoted `.new` sidecars beside each
(`cmp` between live and `.new` differs — the sidecars were not merged).

---

## Instrument re-runs (secondary evidence)

Run from the primary checkout, not a worktree — which also settles the record's
provenance caveat about the pasted output being produced under `.claude/worktrees/`:

| Script | Result | Exit |
|---|---|---|
| `./scripts/phase14-verify.sh` | 38 `[PASS]`, 0 `[FAIL]`, 1 `[FINDING]`, `repo_root=/home/pera/github_repo/.dotfiles` | 0 |
| `./scripts/phase14-preflight.sh` | `FAIL=0 FINDINGS=1` | 0 |
| `./scripts/phase10-inventory-assert.sh` | `phase10 inventory asserts OK` | 0 |
| `./scripts/phase11-dispositions-assert.sh` | `phase11 dispositions asserts OK` | 0 |
| `./scripts/phase12-full-smoke.sh` | `=== done: FAIL=0 ===` | 0 |
| `./scripts/phase13-d19-assert.sh` | `=== Phase 13 asserts: FAIL=0 ===` | 0 |

Working tree: `git status --porcelain` empty. `HEAD` = `origin/main` = `e96b0e3`.

**Spot-check of the instrument itself** (it is the artifact under test):
`check_tier1_source()` at `phase14-verify.sh:358-371` genuinely computes
`sha256sum` and compares against `$HYPRLAND_CONF_SHA_PRE`, with a `fail` branch —
the CR-02 remediation is real code, not a table entry. The D-35 check
(`:538-558`) parses porcelain per-entry and prefix-matches on
`.planning/phases/14-live-full-adopt-verify/`, so it is not the unanchored
`grep -F` the review flagged. Nothing in either script is hardcoded to pass.

**Anti-pattern scan** over `scripts/phase14-preflight.sh`, `scripts/phase14-verify.sh`,
`scripts/phase13-d19-assert.sh`, `docs/phase14-adopt-runbook.md`,
`arch/dots-hyprland.sh`: zero `TBD`/`FIXME`/`XXX`, zero `TODO`/`HACK`/`PLACEHOLDER`.

---

## Findings

None of these block the phase goal. All three warnings are reported, not fixed,
per the verification brief.

### ⚠️ WARNING 1 — The record describes a runbook defect that does not exist in any committed revision

`14-LIVE-VERIFY.md § Findings 4` states: *"Runbook section 8's heredoc is unusable
as printed. Its `SH` terminator is indented, and a plain `<<` heredoc requires the
terminator at column 0, so pasting it hangs the shell at `heredoc>`."* The same
claim appears in `14-02-SUMMARY.md § Issues Encountered`.

I checked. It is not there:

```
$ for c in $(git log --format=%h -- docs/phase14-adopt-runbook.md); do
    git show $c:docs/phase14-adopt-runbook.md | grep -cE "<<'?SH'?"; done
0   (15b0c31)
0   (22e90dd)
0   (e2d44ba)
```

All three committed revisions of the runbook contain **zero** heredocs. §8
(`docs/phase14-adopt-runbook.md:214-230`) is a delegation-by-reference to
`13-SOT-APPLY.md § "Apply command (D-18)"` and contains no fence to paste. That
fence, in both of its committed revisions, is a plain ```bash block with no
heredoc either (`grep -c "<<"` → 0). A repo-wide search for an indented `SH`
terminator across `docs/` and the Phase 13/14 planning trees returns nothing.

**What this means.** The operator hit a real paste failure during the live window
— that is not in doubt — but it was not in the artifact the record names, so the
"correction carried forward" for §8 cannot be applied: there is nothing to
correct. Most likely the fence pasted came from a session message rather than the
committed runbook.

**Impact on the goal: none.** The outcome is independently verified — live and
repo `general.lua`, `env.lua`, `execs.lua` are byte-identical, the eleven
workspace rules are live, and the three ii seed files are untouched. The overlay
was applied correctly by whatever route.

**Why it is a warning anyway:** this phase's binding standard is *do not assert
what you did not observe*, and a record correction pointing at a non-existent
defect is a claim the artifacts contradict. A future reader following §8's
"correction" will look for a heredoc and find none.

### ⚠️ WARNING 2 — Runbook §9's `stow -R kitty` is still wrong in the shipped file

The record flags it (`14-LIVE-VERIFY.md § Findings 4`) but the runbook was never
corrected. `docs/phase14-adopt-runbook.md:233-236` still reads:

```bash
stow -R kitty
# run from the repo root
```

There is no `kitty` package at the repo root — packages live under `stow/`, and
the repo's own `arch/kitty.sh:10` uses
`cd "$(dirname …)/../stow" && stow -v=5 -t ~ kitty`. It also aborts on a
pre-existing real `~/.config/kitty/kitty.conf`. Unlike Warning 1, this defect is
real and is still in a shipped deliverable that a future re-adopt would follow.

The live outcome is fine — the operator ran the corrected form:

```
$ ls -l ~/.config/kitty/
kitty.conf -> ../../github_repo/.dotfiles/stow/kitty/.config/kitty/kitty.conf
kitty.conf.upstream   scroll_mark.py   search.py
```

**Recommendation:** correct §9 in Phase 15 (or as a one-line docs fix). Not a
Phase 14 goal failure — ADOPT-04's rollback guidance is §14 and is unaffected.

### ⚠️ WARNING 3 — The D-38 follow-up is routed to a phase whose scope does not cover it

`14-LIVE-VERIFY.md` and both summaries defer the inactive
`graphical-session.target` to "Phase 15". I read Phase 15's roadmap contract:

> **Goal:** Operator can re-run safe or full profiles from docs without tribal knowledge
> 1. Playbook documents safe vs full profiles, inventory→disposition→adopt sequence, and flag axes
> 2. Playbook documents hypr/custom overlay expectations and repo/live/fork SoT policy (OVL-03)

Phase 15 is documentation-only. Neither success criterion covers re-establishing
the personal session unit's autostart, which is a Lua-side `custom/execs.lua`
change. Under the deferral test this is **not** a clean match, so I do not record
it as deferred — it is an open item with no owning phase.

Confirmed live and unchanged:

```
$ systemctl --user is-active graphical-session.target   -> inactive
$ busctl … ScreenCast AvailableSourceTypes              -> u 7  (== pre-adopt fixture)
$ ls -l stow/systemd/.config/systemd/user/hyprland-session.service  -> present, 659 B
```

The unit file survives; only its autostart is gone; screen share — the anticipated
casualty — works. **Human decision requested:** add the autostart restoration to
Phase 15's scope explicitly, or open it as its own phase/backlog item. Leaving it
as prose in a phase record is how it gets lost.

### ℹ️ INFO 1 — Post-adopt, the preflight prints remediation advice that is now harmful (open review finding IN-11)

Reproduced live just now:

```
$ ./scripts/phase14-preflight.sh
[FINDING] D-13/D-27 ii-original-dots-backup exists … Remediation:
          ./scripts/phase14-preflight.sh --rotate-backup (runbook section 5; mandatory before go).
```

The remediation sentence (`scripts/phase14-preflight.sh:263`) is unconditional.
Pre-adopt it was correct; post-adopt, following it renames away
`~/ii-original-dots-backup` — the very directory D-36 asserts against and ADOPT-04
tier-1 source 3. Bounded: it is a rename, not a delete, and tier-1 sources 1 and 2
are unaffected, so ADOPT-04 survives it. The review's suggested gate
(`[[ -f "$XDG/hypr/hyprland.conf" ]]`, i.e. pre-adopt only) is still unimplemented.

### ℹ️ INFO 2 — ADOPT-04 tier-1 source 3 is hashed in a different block than sources 1 and 2

`check_tier1_source` is applied to sources 1 and 2 (`phase14-verify.sh:372-373`);
source 3 gets only a presence/non-empty check (`:374-378`), with its hash asserted
separately in the D-36 block. Net coverage is complete — I confirmed all three
hashes by hand — but the CR-02 remediation note reads as though all three go
through the same function. Cosmetic, no coverage gap.

### ℹ️ INFO 3 — Bookkeeping ran ahead of verification

`REQUIREMENTS.md:41-44` and `:106-109` already mark ADOPT-01..04 `[x] Complete`,
while `ROADMAP.md` still shows Phase 14 as `1/2 plans` / `In Progress` with
`14-02-PLAN.md` unchecked, despite `14-02-SUMMARY.md` carrying `status: complete`.
Neither affects the verdict — I verified all four requirements independently of
their checkbox state — but the ROADMAP needs the orchestrator's completion pass.

---

## Deliberately not treated as failures

Per the phase's own dispositions and the verification brief, these are recorded
and confirmed, not counted against the goal:

| Item | Confirmed by me | Disposition |
|---|---|---|
| `graphical-session.target` inactive | `systemctl --user is-active` → inactive | D-38, one `[FINDING]`, see Warning 3 |
| `stow/zsh/.config/starship.toml` overwritten through its stow symlink | committed in `2539238`; recovery ref `96ea7e8:stow/zsh/.config/starship.toml` | Accepted loss, D-17 |
| `~/ii-original-dots-backup` holds preserved symlinks for stow-managed files | tier-1 `hyprland.conf` is a real 15301-byte file, hash verified | Finding 2 in `14-LIVE-VERIFY.md`; ADOPT-04 unaffected |
| WR-02, WR-04, WR-05, WR-07, WR-10..WR-13 and 12 Info review findings | recorded in `14-REVIEW.md` | Deliberately left open |
| Four autostarts, `wl-clip-persist`, `hyprpaper` stopped | reproduced via the verify run's `[INFO]` block | D-38 known losses, expected |

---

## Gaps Summary

**No blockers. The ROADMAP goal is achieved.**

*"Live machine runs full hypr adopt per dispositions"* — the full profile ran
(`install --full`, gate answered `yes`, no banned flags), and the delivered state
matches the Phase 11 dispositions item by item: overlay surfaces migrated and
**loaded**, lock/idle kept with sidecars unpromoted, dual-run chrome stopped but
archived and installed, hyprpaper accepted.

*"with verified session"* — the session is under the Lua config manager, proven
across a re-login the phase record did not witness, with all eleven overlay
workspace rules live and `qs -c ii` running.

*"and safe rollback guidance"* — three tiers exist, three tier-1 sources all
carry the pre-adopt hash, and the upstream removal subcommand is explicitly
prohibited and referenced nowhere.

Three warnings carry forward, none of which touches the four requirements: a
record correction that points at a defect no committed artifact contains
(Warning 1), a real and still-uncorrected runbook step (Warning 2), and a
follow-up item routed to a phase that does not scope it (Warning 3). Warnings 2
and 3 want an owner before Phase 15 closes.

---

_Verified: 2026-09-05_
_Verifier: Claude (gsd-verifier), adversarial stance — goal-backward_

---

## Remediation of the recorded warnings (859e434)

Two of the three warnings were closed after this report was written. The verdict
is unchanged — all three were record- and doc-level, none touched the four
requirement verdicts.

**Warning 1 — closed by retraction.** Confirmed independently before acting:
`grep -cE "<<-?'?SH'?"` returns 0 against all three committed revisions of
`docs/phase14-adopt-runbook.md`, and section 8 delegates by reference to
`13-SOT-APPLY.md` § "Apply command (D-18)", which contains no heredoc either.
The described defect exists in no artifact. `14-LIVE-VERIFY.md` § Findings 4 and
`14-02-SUMMARY.md` now carry explicit retractions in place of the claim. The
paste failure itself was real; its true cause was never captured, and the
records now say that rather than naming a plausible but false one.

**Warning 2 — fixed.** `docs/phase14-adopt-runbook.md:233-236` printed
`stow -R kitty` to be run from the repo root. Packages live under `stow/`, so
that resolves no package, and without `-t ~` stow targets the repo's parent
directory. Replaced with `cd stow && stow -R -v=5 -t ~ kitty`, matching
`arch/kitty.sh:10`, plus a note stating both constraints so a future re-adopt
does not repeat the failure.

**Warning 3 — open, deliberately.** The D-38 `graphical-session.target` item is
recorded as deferred to Phase 15, but Phase 15's two success criteria in
`ROADMAP.md:195-196` are documentation-only and do not scope re-establishing the
session-unit autostart. The item therefore has no owning phase. Choosing an
owner is a roadmap scope decision and is left to the operator; it is recorded
here as open rather than silently rescoped or quietly dropped.
