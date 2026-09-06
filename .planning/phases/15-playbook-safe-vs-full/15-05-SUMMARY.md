---
phase: 15-playbook-safe-vs-full
plan: 05
subsystem: docs
tags: [hyprland, dots-hyprland, illogical-impulse, operator-playbook, rollback, markdown]

# Dependency graph
requires:
  - phase: 15-04
    provides: "Playbook sections 4-7 (install walkthrough, session model, overlay policy, verify-after-login) plus the live §8 / §9 forward references this plan resolves"
  - phase: 15-03
    provides: "Runbook corrections: tier-1 source 3 named as `~/ii-original-dots-backup`, the post-adopt `--rotate-backup` caveat and the IN-11 precedent this plan reuses"
  - phase: 15-02
    provides: "Profiles safe vs full, the flag-axis table, the pre-install gate, and the already-corrected Waybar/rofi/swaync non-goals row"
  - phase: 14-live-full-adopt-verify
    provides: "The live adopt, D-38 known losses, WR-02 and IN-11 review findings, and 14-PRE-ADOPT-BASELINE.txt"
provides:
  - "`## 8. Known losses after the full adopt` — the honest cost of a full adopt (D-17), with the D-38 screen-share consequence hedged to `may`"
  - "`## 9. Three roles of the repo hyprland.conf` — WR-02 disambiguated (D-18) with the tier-2-destroys-tier-1-source-2 ordering instruction and the D-19 post-adopt rotate prohibition"
  - "A non-goals table that no longer claims the hyprland.lua/ii-hypr-tree takeover is out of scope this milestone (D-10)"
  - "The final 11-entry Outline and an updated See also, with every in-page anchor and relative link proven to resolve (D-23)"
affects: [15-06, doc-sweep, ship, milestone-close]

actuals:
  tokens: 1932
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Known-losses phrasing: bolded noun phrase, then what survives, then exactly what was lost"
    - "Bold-imperative prohibition: imperative first sentence, then the mechanism, then the bounding facts"
    - "Outline-to-section one-to-one as a mechanically assertable invariant (11 headings / 11 entries)"

key-files:
  created: []
  modified:
    - docs/dots-hyprland-workflow.md

key-decisions:
  - "Kept the deferred Waybar module ports as `CUST-01..03` rather than the plan's `CUST-01 through CUST-04`, because REQUIREMENTS.md Out of Scope defers CUST-01..03 as module ports and CUST-04 is a different requirement (machine-specific overlays beyond hypr session)"
  - "Left the already-correct Waybar/rofi/swaync cutover row's Why cell alone (15-02 had fixed it) and changed only its Status cell to record the accepted removal"
  - "Did not touch STATE.md, ROADMAP.md or REQUIREMENTS.md — the orchestrator owns wave tracking and the DOC-03/DOC-04 shared-ID gate holds until 15-06's summary lands"

patterns-established:
  - "Hazard sections state an ordered instruction plus its bounding facts, so a recovering operator neither ignores the hazard nor over-reacts to it"
  - "Stale executable messages are recorded in prose with their tracking ID and deferred owner rather than silently fixed by a documentation phase"

requirements-completed: [DOC-03]

coverage:
  - id: D1
    description: "Playbook section 8 states the four known losses of a full adopt, each leading with what survives, with the D-38 screen-share consequence hedged as a possibility"
    requirement: DOC-03
    verification:
      - kind: other
        ref: "grep gate: heading + hyprland-session.service + graphical-session.target + wl-clip-persist + google-chrome-stable + btop + discord + hyprpaper + stow/"
        status: pass
      - kind: other
        ref: "grep gate: hedged 'screen share … may' present; 3 overstated phrasings count 0; non-allowlisted chrome tokens count 0"
        status: pass
    human_judgment: false
  - id: D2
    description: "Playbook section 9 names the three roles of the repo hyprland.conf, the tier-2-destroys-tier-1-source-2 ordering hazard with its mitigation, and the D-19 post-adopt --rotate-backup prohibition with IN-11 recorded as deferred"
    requirement: DOC-03
    verification:
      - kind: other
        ref: "grep gate: heading + D-36 + --rotate-backup + IN-11 + scripts/phase14-preflight.sh + uninstall + sha256 + phase14-adopt-runbook.md"
        status: pass
      - kind: other
        ref: "git diff --name-only f54714b..HEAD -- scripts/phase14-preflight.sh (empty); ./scripts/phase13-d19-assert.sh → 15 [PASS], 0 [FAIL]"
        status: pass
    human_judgment: false
  - id: D3
    description: "Non-goals table no longer claims completed work is out of scope this milestone; the verify-subcommand row points at section 7 and scripts/phase14-verify.sh"
    requirement: DOC-03
    verification:
      - kind: other
        ref: "grep gate: 'Out of scope this milestone' count 0; CUST-01, 11-DISPOSITIONS.md, exp-merge all present"
        status: pass
    human_judgment: false
  - id: D4
    description: "Final Outline lists all eleven numbered sections one to one, and every in-page anchor and relative link in the playbook, the runbook and README.md resolves (D-23)"
    requirement: DOC-03
    verification:
      - kind: other
        ref: "anchor gate: 11 '## N.' headings, 11 outline entries, no MISSING ANCHOR under the GitHub slug transform"
        status: pass
      - kind: other
        ref: "link gate: no BROKEN <file> -> <path> across 3 prose docs; no CITED BUT MISSING for 10-INVENTORY.md / 11-DISPOSITIONS.md / 13-SOT-APPLY.md / phase14-adopt-runbook.md"
        status: pass
    human_judgment: false
  - id: D5
    description: "The playbook's claim that 15-DOC-SWEEP.md carries the D-38 restoration work as a deferred item"
    requirement: DOC-03
    verification: []
    human_judgment: true
    rationale: "The claim is written as the plan instructed, but 15-DOC-SWEEP.md's 'Flagged, not edited (D-22)' section is still '_To be filled by plan 15-06._'. The claim becomes true only when 15-06 records the D-38 deferral. A human (or 15-06's own verify) must confirm it landed."

# Metrics
duration: 12min
completed: 2026-09-06
status: complete
---

# Phase 15 Plan 05: Close the playbook — known losses, the WR-02 three roles, and link integrity Summary

**The playbook now tells a full-profile operator exactly what the adopt cost, hands a mid-rollback operator the one ordering instruction that keeps tier 1 intact, stops claiming two completed things are out of scope, and resolves every link it makes.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-09-06T06:14:00Z
- **Completed:** 2026-09-06T06:26:54Z
- **Tasks:** 3 of 3
- **Files modified:** 1

## Accomplishments

- **Section 8 (D-17)** states the four losses in the runbook's survives-first voice: the `hyprland-session.service` autostart (unit file survives under `stow/systemd/`, `graphical-session.target` inactive), `wl-clip-persist`, the four workspace-pinned autostarts named literally (`google-chrome-stable` on workspace 1, `kitty -e tmux` on workspace 1, `btop` on its special workspace, `discord` on `special:social`), and `hyprpaper` as stopped-but-installed. The D-38 consequence is written as "screen share **may** stop working" with the unchanged `AvailableSourceTypes` as the reason for the hedge (assumption A6). The section closes by owning no fix and by explaining why §7 expects one `[FINDING]`, not zero.
- **Section 9 (D-18, D-19)** is the phase's answer to WR-02. It names the three roles of `.config/hypr/hyprland.conf` — rollback tier-1 source 2, frozen D-36 evidence, and (under full) the wrapper's *only* remaining hook-injection target — then states the ordering hazard as an instruction: `uninstall` deletes the hooks, which changes the file's sha256 and flips the tier-1 source 2 check, so copy the file aside before escalating a rollback to tier 2. It bounds the hazard (git history; a forward `install` changes nothing) and adds the D-19 prohibition on running `./scripts/phase14-preflight.sh --rotate-backup` post-adopt, recording IN-11 as a deferred fix owned by a phase that owns the script.
- **Non-goals table (D-10)** no longer claims anything is out of scope this milestone. The `hyprland.lua` / ii hypr tree takeover row now records the full profile's session model and points at §5, keeping the safe-profile `--skip-hyprland` clause. The `verify`-subcommand row was repointed from the removed §4 dual-run checks to §7 and `scripts/phase14-verify.sh`.
- **Outline and See also (D-23)** finished: eleven entries for eleven numbered sections, one to one, plus four new linked `See also` entries (runbook, `10-INVENTORY.md`, `11-DISPOSITIONS.md`, `13-SOT-APPLY.md`) and corrected ROADMAP / REQUIREMENTS glosses. Every in-page anchor and every relative link across the playbook, the runbook and `README.md` was proven to resolve.

## Task Commits

Each task was committed atomically:

1. **Task 1: Write section 8 — known losses after the full adopt** — `ee4232f` (docs)
2. **Task 2: Write section 9 — the three roles of the repo hyprland.conf, and the post-adopt rotate prohibition** — `c897f6a` (docs)
3. **Task 3: Correct the non-goals table, write the final Outline and See also, and prove every link resolves** — `d87f114` (docs)

**Plan metadata:** see the final `docs(15-05)` summary commit.

## Files Created/Modified

- `docs/dots-hyprland-workflow.md` — added sections 8 and 9, rewrote three non-goals rows, rewrote the Outline to eleven entries, extended and corrected See also. Final `## ` heading set (17 headings, 11 of them numbered): `Purpose`, `Prerequisites`, `Profiles: safe vs full`, `Canonical path`, `Outline`, `1. Clone & recursive submodule init`, `2. Verify fork remotes & pin`, `3. Required gate before any full install`, `4. Install via the thin wrapper`, `5. Session model after a full install`, `6. Personal overlays: repo, live, fork`, `7. Verify after login`, `8. Known losses after the full adopt`, `9. Three roles of the repo hyprland.conf`, `10. Update contract (pin-bump)`, `11. Non-goals / non-primary paths`, `See also`.

## Decisions Made

1. **`CUST-01..03`, not `CUST-01..04`.** The plan's Task 3 action asked the cutover row's Why to defer "CUST-01 through CUST-04". `REQUIREMENTS.md:57-60` defines CUST-01..03 as Waybar module ports and CUST-04 as *machine-specific overlays beyond hypr session*, and `REQUIREMENTS.md:75` (the Out of Scope row the table must stay aligned with) defers "Waybar custom module ports (CUST-01..03)". Widening to CUST-04 would have misaligned the playbook with REQUIREMENTS and mislabelled a different requirement as a module port. The row keeps `CUST-01..03`; the acceptance criterion (`names CUST-01`) is satisfied.
2. **The cutover row's Why cell was left alone.** Plan 15-02 had already rewritten it down to deferring only the module ports, exactly as this plan's own upstream handoff note 9 flagged. Only the Status cell changed, to `Cutover **done** under the full profile (Phase 11 D-11); only the ports are deferred (CUST-01..03)`, which is what "its status records that the removal happened … with Phase 11's acceptance" asked for.
3. **The `verify`-subcommand row's requirement reference was widened from `DOC-01/02` to `DOC-01..DOC-04`.** The row's pointer had to move to §7 anyway; leaving `DOC-01/02` would have implied POLISH-01 is required for the two requirements this phase delivers. This is a one-cell truth correction inside a row the plan already scoped for rewrite.
4. **No STATE.md / ROADMAP.md / REQUIREMENTS.md writes.** The execution contract fences those files to the orchestrator, and DOC-03 / DOC-04 are deliberately held open by the shared-ID gate until 15-06's summary lands. `requirements mark-complete` was therefore not run.

## Deviations from Plan

### Auto-fixed Issues

None. No Rule 1-3 auto-fix was required; the three decisions above are scoping judgments recorded in `## Decisions Made`, not defect fixes.

---

**Total deviations:** 0 auto-fixed
**Impact on plan:** None. All three tasks executed as written; the only departures from the plan's literal wording are the CUST range (aligned to REQUIREMENTS instead) and the untouched cutover Why cell (already correct from 15-02).

## Issues Encountered

**The `15-DOC-SWEEP.md` deferred-item claim is forward-looking.** Section 8 states, as the plan's Task 1 action instructed, that the sweep record "carries [the unowned restoration work] as a deferred item". As of this commit, `15-DOC-SWEEP.md`'s `## Flagged, not edited (D-22)` section still reads `_To be filled by plan 15-06._`. The claim is true only once 15-06 fills it. Recorded here and under `## Known Gaps` so 15-06 cannot close the phase without making it true. Not treated as a Rule 1 bug because the sweep record is 15-06's artifact, not this plan's.

## Known Gaps

| Gap | Where | Owner |
|-----|-------|-------|
| `docs/dots-hyprland-workflow.md` §8 claims `15-DOC-SWEEP.md` carries the D-38 restoration work as a deferred item; the sweep record's "Flagged, not edited (D-22)" section is still a placeholder | `docs/dots-hyprland-workflow.md:401`, `.planning/phases/15-playbook-safe-vs-full/15-DOC-SWEEP.md` | plan `15-06` |

No stubs, no skipped tests, no unrun `<verify>` blocks. All ten `<automated>` assertions across the three tasks were run literally as written and exited 0.

## Threat Flags

None. No file changed in this plan introduces network, auth, filesystem or schema surface; the only modified file is operator prose. The plan's own register (T-15-22 through T-15-27) was mitigated as specified:

| Threat | Mitigation landed |
|--------|-------------------|
| T-15-22 rollback escalation destroying tier-1 source 2 | §9 states mechanism, cause and the ordered `cp -a` mitigation; asserted present |
| T-15-23 `--rotate-backup` run post-adopt | §9 prohibition with IN-11 deferred; `scripts/phase14-preflight.sh` proven unmodified across the phase range |
| T-15-24 misrepresenting the D-38 screen-share consequence | Hedge asserted present, three overstated phrasings asserted absent |
| T-15-25 non-goals claiming completed work is out of scope | `Out of scope this milestone` count pinned at 0; `11-DISPOSITIONS.md` cited |
| T-15-26 dead cross-references | Two-layer D-23 gate passed: relative-link resolution across 3 prose docs, plus cited-artifact existence by basename |
| T-15-27 upstream removal subcommand as an alternative | Dangerous-override token count 0; tiers cited to the runbook, none reproduced |

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

Ready for `15-06` (wave 5, the phase gate). What 15-06 needs to know:

1. **The playbook is structurally complete and internally consistent.** Eleven numbered sections, an eleven-entry Outline matching them one to one, and every in-page anchor and relative link proven to resolve. Any 15-06 edit that adds, removes or renames a `## N.` heading must update the Outline in the same commit or the D-23 gate fails.
2. **Fill `15-DOC-SWEEP.md`'s deferred-item section.** §8 of the playbook points there for the unowned D-38 restoration work (session bootstrap, `wl-clip-persist`, the four autostarts). Until 15-06 records it, the playbook cites a placeholder. This is the single open item this plan hands over.
3. **DOC-03 and DOC-04 remain unmarked**, as designed. `requirements ready-ids` should still report `0/2 ready` until 15-06's summary lands; nothing in this plan touched `REQUIREMENTS.md`.
4. **STATE.md and ROADMAP.md are untouched** by this plan — the orchestrator's wave-4 tracking commit is the only expected diff there.
5. **`./scripts/phase14-verify.sh` was deliberately not run** (D-35 clean-tree assertion would fail pre-commit). It belongs to 15-06's phase gate. `./scripts/phase13-d19-assert.sh` was run and holds its baseline: exit 0, 15 `[PASS]`, 0 `[FAIL]`.
6. **Prose invariants now enforceable in 15-06's sweep assertions:** non-allowlisted `chrome` tokens = 0, word-boundary `rofi` = 4 (floor of 2), `rsync` = 0, `Out of scope this milestone` = 0, `Phase 9 success criteria` = 0.

## Self-Check

**PASSED.**

Files claimed, verified present:

- `docs/dots-hyprland-workflow.md` — FOUND (33,528 bytes, 17 `## ` headings, 11 numbered)
- `.planning/phases/15-playbook-safe-vs-full/15-05-SUMMARY.md` — FOUND (this file)

Commits claimed, verified in `git log`:

- `ee4232f` — FOUND — `docs(15-05): add playbook section 8 — known losses after the full adopt`
- `c897f6a` — FOUND — `docs(15-05): add playbook section 9 — three roles of the repo hyprland.conf`
- `d87f114` — FOUND — `docs(15-05): correct non-goals table, finish the Outline and See also`

Scope fences, verified clean: `git diff --quiet HEAD -- arch/ scripts/ .config/ stow/ vendor/ .planning/STATE.md .planning/ROADMAP.md` → exit 0 after every task. `git diff --name-only f54714b..HEAD -- scripts/phase14-preflight.sh` → empty. No file deletions in any of the three commits.

---
*Phase: 15-playbook-safe-vs-full*
*Completed: 2026-09-06*
