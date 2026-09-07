---
phase: 16-retire-the-safe-profile-full-only-wrapper-and-playbook
plan: 05
subsystem: docs
tags: [markdown, adopt-runbook, operator-docs, rollback, preflight, recovery]

# Dependency graph
requires:
  - phase: 16-03
    provides: "the two script deletions (phase14-preflight.sh and phase07-live-smoke.sh) that make the runbook's invocations of them broken instructions"
  - phase: 16-04
    provides: "the playbook's recovery paragraph in §9 that this plan's replacement text agrees with in substance"
provides:
  - "docs/phase14-adopt-runbook.md with every runnable instruction actually runnable — no deleted-script invocations, no tier-based recovery depending on deleted machinery"
  - "the rollback section replaced with a clean-reinstall narrative naming vendor/dots-hyprland as the pinned source"
  - "the pre-adopt snapshot acknowledged as present and untouched without being presented as a recovery tier"
affects: [16-06, 16-10, phase-verification]

# Actuals (#2632)
actuals:
  tokens: 4200
  tasks: 2
  commits: 2

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Historical record conversion: command fences become record-marked blocks rather than deleted, preserving evidence while preventing copy-paste execution"
    - "Substance agreement without verbatim duplication: two documents with different roles describe the same recovery path in their own voices"

key-files:
  created: []
  modified:
    - docs/phase14-adopt-runbook.md

key-decisions:
  - "Preflight command fences were converted to records rather than deleted — the evidence of what was run on 2026-09-04 stays, only the framing changed"
  - "The replacement recovery text agrees with the playbook's §9 paragraph in substance but uses the runbook's own voice and adds the pre-adopt snapshot acknowledgment"
  - "The prohibition wording that names the upstream removal capability without writing the literal command was preserved verbatim in substance"

patterns-established:
  - "Sweep-not-restructure: correcting falsehoods in a historical record while preserving its structure, section count, and factual accuracy"

requirements-completed: [ADOPT-02, IN-11, D-20, D-24, D-25]

# Coverage metadata (#1602)
coverage:
  - id: D1
    description: "Every reference to the deleted preflight script reads as an account of what was run on 2026-09-04 rather than as a step to perform now"
    requirement: "D-25"
    verification:
      - kind: other
        ref: "grep -cE '^\\s*(\\./)?scripts/phase14-preflight\\.sh' => 0; grep -qi 'removed in Phase 16' => true; grep -q '2026-09-04' => true"
        status: pass
    human_judgment: false
  - id: D2
    description: "The rollback section describes a clean reinstall from the pinned submodule rather than a tier list whose machinery has been deleted"
    requirement: "D-20"
    verification:
      - kind: other
        ref: "awk-extracted §14: no 'tier [123]', no 'three-tier'; contains 'reinstall'; contains 'vendor/dots-hyprland'; no './setup uninstall'"
        status: pass
      - kind: integration
        ref: "./scripts/phase16-retire-assert.sh => '=== done: FAIL=0 ==='"
        status: pass
    human_judgment: false
  - id: D3
    description: "The file keeps its seventeen sections and its role as the adopt-window narrative"
    requirement: "D-24"
    verification:
      - kind: other
        ref: "grep -c '^## ' => 17; grep -qF '## 14.' => true; grep -qF '## 5.' => true"
        status: pass
    human_judgment: false
  - id: D4
    description: "The pre-adopt snapshot is acknowledged as present on disk without being aimed at with a destructive command or presented as a recovery tier"
    verification:
      - kind: other
        ref: "grep -q 'ii-original-dots-backup' => true; ! grep -qiE '(rm|mv|rmdir).*ii-original-dots-backup' => true"
        status: pass
    human_judgment: false
  - id: D5
    description: "Every relative link in the file resolves to an existing path"
    verification:
      - kind: other
        ref: "link resolver walked all non-http links, stripping anchors, all file refs exist on disk"
        status: pass
    human_judgment: false

# Metrics
duration: 4 min
completed: 2026-09-07
status: complete
---

# Phase 16 Plan 05: Adopt runbook corrections Summary

**Converted the preflight and backup-rotation sections to historical narrative and replaced the three-tier rollback list with a clean-reinstall recovery paragraph naming `vendor/dots-hyprland` as the pinned source.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-09-07T13:56:00Z
- **Completed:** 2026-09-07T14:03:00Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Every invocation of the deleted `scripts/phase14-preflight.sh` in the runbook now reads as a record of the 2026-09-04 run, not as a step to perform — command fences carry record markers and no line begins with a bare invocation
- The backup-rotation section records what happened at the `20260904T171128Z` timestamp and states plainly that the mechanism is retired — no snapshot is produced on future installs
- The three-tier rollback list is replaced with three plain statements: recovery is a clean reinstall from the pinned submodule, the wrapper never calls upstream's own removal subcommand, and nothing is preserved on install
- The pre-adopt snapshot directories are acknowledged as present and untouched without being presented as a documented recovery route
- The file points to `docs/dots-hyprland-workflow.md` as the canonical operator document for install, update and recovery

## Task Commits

Each task was committed atomically:

1. **Task 1: Turn the preflight section into historical narrative** — `575f6dd` (docs)
2. **Task 2: Replace the rollback tier list with the recovery that actually exists** — `d7c889a` (docs)

**Plan metadata:** the `docs(16-05)` commit that carries this file.

## Files Created/Modified

- `docs/phase14-adopt-runbook.md` — Preflight and rotation sections converted from runnable instructions to historical narrative; rollback section body replaced wholesale from three-tier list to clean-reinstall paragraph. Section count preserved at 17.

## Decisions Made

- Command fences in the preflight sections were converted to records rather than deleted — they are evidence of what was run and stay as such
- The replacement recovery text agrees with the playbook's §9 in substance but is written in the runbook's own narrative voice
- The existing prohibition wording naming the upstream removal capability without writing the literal command was preserved in the new text

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Ready for 16-06: the adopt runbook's corrections are complete, and `scripts/phase16-retire-assert.sh` still passes at `FAIL=0`
- The file is deliberately NOT grep-gated for retired vocabulary (D-36) — it records what the adopt actually ran, including the flag names from that day

## Self-Check: PASSED

- `docs/phase14-adopt-runbook.md` — FOUND on disk, 17 sections
- Commit `575f6dd` — FOUND in `git log`
- Commit `d7c889a` — FOUND in `git log`
- Task 1 acceptance criteria: all pass (section count 17, no bare invocations, removal noted, date present, rotation mentioned with retired statement, timestamp preserved)
- Task 2 acceptance criteria: all pass (section count 17, no tier references, no literal removal command, reinstall stated, backup mentioned without destructive command, playbook linked, chrome check clean, all links resolve, assert FAIL=0)

---
*Phase: 16-retire-the-safe-profile-full-only-wrapper-and-playbook*
*Completed: 2026-09-07*
