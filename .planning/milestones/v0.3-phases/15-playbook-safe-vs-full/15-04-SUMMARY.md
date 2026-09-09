---
phase: 15-playbook-safe-vs-full
plan: 04
subsystem: docs
tags: [dots-hyprland, hyprland, playbook, backup-gate, overlays, quickshell]

# Dependency graph
requires:
  - phase: 15-02
    provides: "`## Profiles: safe vs full` section, the renumbered 1/2/3/4/5/10/11 spine, and the §3 gate positioned ahead of the first install invocation"
  - phase: 15-01
    provides: "the corrected `hyprctl -j status | jq -r .configProvider` probe and the `~/ii-original-dots-backup` backup-of-record"
  - phase: 15-03
    provides: "runbook §14 rollback in its corrected post-adopt state, including the anchored sha256 identity form for the backup directory"
provides:
  - "Section 4 rewritten as a full-profile walkthrough: dry-run → backup gate → live install, with the safe difference stated in place"
  - "The backup gate documented inline: exact `yes` token, `~/ii-original-dots-backup` default, content-based confirmation, dual-key `--skip-backup` refusal"
  - "Section 5 rewritten as the full session model; the safe conf-hook method demoted to one pointer sentence"
  - "`## 7. Verify after login` promoted out of section 5 as a top-level section"
  - "`## 6. Personal overlays: repo, live, fork` — DOC-04 in the playbook's own words, narrating `13-SOT-APPLY.md`"
affects: [15-05, 15-06]

actuals:
  tokens: 6672
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Backup confirmed by content (anchored `grep -qxF` over a recorded sha256 fixture), never by directory name"
    - "Operator-facing narration of a planning SoT with the SoT named alongside, rather than replacing it"

key-files:
  created:
    - .planning/phases/15-playbook-safe-vs-full/15-04-SUMMARY.md
  modified:
    - docs/dots-hyprland-workflow.md

key-decisions:
  - "The backup gate is its own `### The backup gate` subsection placed between the dry-run and the live install, because that is the order the operator meets it in — not an appendix or a note on the install command."
  - "The dry-run `# expect:` lines quote the wrapper's real captured output (`[CONFIG] full profile: no SAFE_DEFAULTS injection (DISP-02 drop-all-three)`), taken from a live `install --full --dry-run` run this session rather than paraphrased."
  - "The safe-profile difference is one sentence in the dry-run subsection and one sentence in the session model, pointing back to `Profiles: safe vs full`, so the walkthrough never forks (D-03, D-07)."
  - "Section 6's apply block is shown in full and the SoT is cited beside it with an explicit precedence sentence (`if the two ever disagree, the source of truth wins`), which is how narration stays safe without becoming a second authority (D-16, Phase 13 D-05)."
  - "The Outline was deliberately left untouched: sections 6 and 7 exist now but 8 and 9 do not, and an Outline written here would either be wrong or point at headings 15-05 has not written yet (D-23)."

patterns-established:
  - "Content-over-name backup verification: name the directory, then immediately state that its presence proves nothing and give the anchored hash comparison"
  - "Section-promotion refactor: move a `###` block whole to `##`, changing only heading level and text, and assert both the old `###` string is gone and the new `##` string is present so a copy cannot masquerade as a move"

requirements-completed: [DOC-03, DOC-04]

coverage:
  - id: D1
    description: "A reader walks the full profile end to end — dry-run, backup gate, live install — from one linear section, and learns at the gate that bare `--skip-backup` is refused without `--allow-skip-backup`"
    requirement: DOC-03
    verification:
      - kind: other
        ref: "grep -q -- '--allow-skip-backup' && grep -q -- '--skip-backup' && grep -qE './arch/dots-hyprland.sh install --full' docs/dots-hyprland-workflow.md"
        status: pass
      - kind: other
        ref: "subcommand allowlist check against live ./arch/dots-hyprland.sh help"
        status: pass
      - kind: other
        ref: "D-12 nine-flag ceiling check over line-leading wrapper invocations"
        status: pass
    human_judgment: false
  - id: D2
    description: "A reader learns the backup lands at `~/ii-original-dots-backup` and how to confirm it by content rather than by name"
    requirement: DOC-03
    verification:
      - kind: other
        ref: "grep -q 'ii-original-dots-backup' && ! grep -qE 'ii-original-dots-backup\\.[0-9]{8}T' && grep -q 'sha256sum' docs/dots-hyprland-workflow.md"
        status: pass
    human_judgment: false
  - id: D3
    description: "A reader learns the full session model: `hyprland.lua` entry, `configProvider` reporting `lua` against the recorded pre-adopt `hyprlang`, the `.old` rename, and overlays under `~/.config/hypr/custom/`"
    requirement: DOC-03
    verification:
      - kind: other
        ref: "grep -q 'hyprland.lua' && grep -q 'hyprland.conf.old' && grep -q 'hyprlang' docs/dots-hyprland-workflow.md; grep -c getoption == 0"
        status: pass
    human_judgment: false
  - id: D4
    description: "The safe profile's two conf-hook lines are one pointer line, not a section"
    requirement: DOC-03
    verification:
      - kind: other
        ref: "! grep -qF '### Personal hypr hooks (two lines)' && grep -q 'ILLOGICAL_IMPULSE_VIRTUAL_ENV' docs/dots-hyprland-workflow.md"
        status: pass
    human_judgment: false
  - id: D5
    description: "The overlay policy in the playbook's own words — repo `.config/hypr/custom/` as authoring SoT, one-way repo to live, named files only, never into `vendor/dots-hyprland` or the fork — with `13-SOT-APPLY.md` named as the SoT it summarises"
    requirement: DOC-04
    verification:
      - kind: other
        ref: "Task 3 verify block 1 (heading, both SoT citations, cp -a, one-way phrasing, three named files) — all present"
        status: pass
      - kind: other
        ref: "grep -c rsync docs/dots-hyprland-workflow.md == 0; keybinds.lua and variables.lua both named"
        status: pass
      - kind: integration
        ref: "./scripts/phase13-d19-assert.sh"
        status: pass
    human_judgment: false
  - id: D6
    description: "The last of D-10's three stale claims is gone: the file no longer frames dual-run as intentional for this milestone"
    requirement: DOC-03
    verification: []
    human_judgment: true
    rationale: "Absence of a framing is a prose judgment, not a grep. The old §4 'No Waybar cutover required for this milestone' line is gone and section 5 now describes dual-run only as a safe-profile property, but confirming no residual framing survives anywhere needs a human read of the assembled file — 15-06 owns that phase-level read."

# Metrics
duration: 9 min
completed: 2026-09-06
status: complete
---

# Phase 15 Plan 04: Install walkthrough, session model, overlay policy Summary

**The middle of the playbook spine: section 4 now walks `install --full` from dry-run through an inline backup gate to the live install, section 5 describes the Lua session a full adopt actually produces, verification stands alone as section 7, and section 6 delivers DOC-04 by narrating `13-SOT-APPLY.md` with the named-file `cp -a` apply shown in full.**

## Performance

- **Duration:** 9 min
- **Started:** 2026-09-06T06:12:14Z
- **Completed:** 2026-09-06T06:21:00Z
- **Tasks:** 3
- **Files modified:** 1

## Accomplishments

- **Section 4 walks full end to end (D-05, D-14).** Dry-run → backup gate → live install, in the order an operator meets them. The dry-run `# expect:` lines quote output captured from a live `./arch/dots-hyprland.sh install --full --dry-run` run this session, not from memory.
- **The backup gate is documented where it happens, with all four facts.** Exact `yes` token and the `[FAIL] Aborted (backup gate). No ./setup invoked.` abort; the `II_BACKUP_DIR` default `~/ii-original-dots-backup` quoted from `arch/dots-hyprland.sh:21`; the warning that a pre-existing directory of that name may mean upstream skipped a fresh backup, with the anchored `grep -qxF` sha256 comparison as the content check; and the dual-key `--skip-backup` / `--allow-skip-backup` refusal with an explicit statement that no skip example appears in the document.
- **Section 5 is the full session model.** Lua entry, `configProvider` reporting `lua` where the recorded pre-adopt value was `hyprlang`, `hyprland.conf.old` rename, and a four-path `text` block. The safe conf-hook method is one sentence naming the `env` and `exec-once` line kinds — its former `### Personal hypr hooks (two lines)` subsection and its verbatim fence are gone.
- **Verification promoted to `## 7. Verify after login`.** Moved whole: the after-login sentence, the six-probe fence, the `scripts/phase14-verify.sh` SoT sentence and the runbook §14 pointer all travelled together. Only the heading level and text changed.
- **DOC-04 delivered as `## 6. Personal overlays: repo, live, fork`.** Three locations and three roles, the one-way repo-to-live direction, the named-file `cp -a` apply shown in full, the abort/warn failure modes, and — the part a reader would otherwise trip on — why live `custom/` legitimately holds four more entries than the repo does.

## Task Commits

1. **Task 1: Section 4 — full install walkthrough with the backup gate inline** — `31b158c` (docs)
2. **Task 2: Section 5 — full session model; verification promoted to section 7** — `f12c8d6` (docs)
3. **Task 3: Section 6 — overlay policy in the playbook's own words (DOC-04)** — `7175705` (docs)

## Files Created/Modified

- `docs/dots-hyprland-workflow.md` — sections 4 and 5 rewritten in place; sections 6 and 7 added. 128 insertions, 28 deletions.

## Decisions Made

- **The backup gate got its own `###` subsection rather than a paragraph attached to the live-install command.** It has four independent facts and one of them (content-based confirmation) needs a fenced command; folding that into the install step would have buried the dual-key refusal under a command block.
- **The dry-run is shown as a bare `./arch/dots-hyprland.sh install --full --dry-run`, not as the help text's `printf 'yes\n' | …` pipe form.** The line-leading form is what the operator types interactively, and it is also what the plan's subcommand-allowlist check reads — the piped form would have silently escaped that check.
- **`§7`, `§8` and `§9` are written as plain text, not markdown links.** Sections 8 and 9 do not exist yet (15-05 owns them). A plain `§8` is a forward reference a reader can follow once the file is complete; a `[§8](#8-…)` link would be a dead anchor at this commit and would have failed the in-page link check.
- **`DOC-03` and `DOC-04` were deliberately not marked complete.** All six Phase 15 plans declare both IDs; `requirements ready-ids` confirms `0/2 requirement(s) ready to mark complete`. The shared-ID gate holds them open until 15-06's summary exists. `REQUIREMENTS.md` was not touched.

## Deviations from Plan

None - plan executed exactly as written.

All three tasks were executed as specified. Every `<automated>` verify block was run literally as written and passed on first execution; no auto-fix was required, so no deviation rule was invoked.

## Issues Encountered

- **The plan's task line-number references predated waves 1 and 2.** As instructed by the execution context, the file was read fresh and located by heading rather than by line number. No content was affected.
- **Two `<read_first>` sources needed live capture rather than reading.** The plan asked for "the live output of `./arch/dots-hyprland.sh help`" and for the full-profile echo lines; both were obtained by running `help` and by running `install --full --dry-run` and `install --dry-run` under `printf 'yes\n' |`. Both are read-only paths (`--dry-run` prints the would-exec argv and exits 0); `git status --porcelain` was empty immediately afterwards, confirming no scope-fence directory was touched.

## Scope Fence

`git diff --quiet HEAD -- arch/ scripts/ .config/ stow/ vendor/ .planning/STATE.md .planning/ROADMAP.md` passed after every task. `docs/phase14-adopt-runbook.md` was read but not modified. `./scripts/phase13-d19-assert.sh` holds its baseline: exit 0, 15 `[PASS]`, 0 `[FAIL]`.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

**Playbook `## ` heading state handed to 15-05:**

```
## Purpose
## Prerequisites
## Profiles: safe vs full
## Canonical path
## Outline
## 1. Clone & recursive submodule init
## 2. Verify fork remotes & pin
## 3. Required gate before any full install
## 4. Install via the thin wrapper
## 5. Session model after a full install
## 6. Personal overlays: repo, live, fork
## 7. Verify after login
## 10. Update contract (pin-bump)
## 11. Non-goals / non-primary paths
## See also
```

Nine `## N.` headings; 8 and 9 are the gap 15-05 fills.

**What 15-05 must know:**

1. **The Outline is still the wave-2 seven-entry list (1, 2, 3, 4, 5, 10, 11).** It does not mention 6 or 7. 15-05 writes the final Outline once 8 and 9 exist, per D-23. The in-page anchor check currently passes because the Outline points only at headings that exist — adding an entry for a heading before it is written is the failure mode that check exists to catch.
2. **Three forward references are already live in the prose and must resolve when 15-05 lands.** `§8` (from section 5, for the `Waybar` / `rofi` / `swaync` losses), `§9` (from section 4's hooks paragraph and again from section 5, for the roles of the repo `.config/hypr/hyprland.conf` copy). All three are plain text, not links, so they will not break the anchor check — but they are promises the reader will try to follow.
3. **Section 4 sends the reader to `§7` after login and to `§3` before installing.** Both targets exist. Do not renumber 7 without updating that sentence.
4. **The D-38 wording is unclaimed here.** Section 5 says only that `Waybar`, `rofi` and `swaync` are not part of the full session and that `§8` lists the cost. The "screen share **may** be affected" phrasing (A6) is 15-05's to write; nothing in this plan pre-commits it.
5. **The anchor-integrity check is reproducible.** Slugs are derived as `lowercase → strip non-`[a-z0-9 -]` → spaces to hyphens`, so `## 6. Personal overlays: repo, live, fork` → `#6-personal-overlays-repo-live-fork` and `## 7. Verify after login` → `#7-verify-after-login`. Those are the two Outline entries 15-05 will need to add.

**What 15-06 must know:**

- `DOC-03` and `DOC-04` are both still open in `REQUIREMENTS.md` by design. All six plans declare them, so the shared-ID gate keeps them open until 15-06's summary lands. 15-06 is the plan whose `update_requirements` step will finally mark them.
- `./scripts/phase14-verify.sh` was **not** run in this plan's verifies, per the plan's own `<verification>` note: it asserts a clean working tree (D-35) and would fail pre-commit. It runs at the phase gate in 15-06.

**No blockers.**

## Self-Check: PASSED

Files claimed created/modified, verified on disk:

- `FOUND: docs/dots-hyprland-workflow.md`
- `FOUND: .planning/phases/15-playbook-safe-vs-full/15-04-SUMMARY.md`

Commits claimed, verified in `git log --oneline --all`:

- `FOUND: 31b158c`
- `FOUND: f12c8d6`
- `FOUND: 7175705`

All ten task-level `<automated>` verify blocks (four in Task 1, three in Task 2, three in Task 3) re-run and exiting 0. Final consolidated state: `rsync=0`, `UPSTREAM-UNINSTALL`/`upstream-dangerous`=0, non-allowlisted `chrome` tokens=0, `getoption`=0, rotated-backup form=0, `## N.` headings=9, every in-page anchor resolves, `phase13-d19-assert.sh` exit 0 with 15 `[PASS]` and 0 `[FAIL]`.

---
*Phase: 15-playbook-safe-vs-full*
*Completed: 2026-09-06*
