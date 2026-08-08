# Phase 11 — Plan Outline

**Phase:** 11-disposition-decisions  
**Goal:** Every high-risk change has an explicit human decision and staged flag profile before tooling or live adopt  
**Requirements:** DISP-01, DISP-02, DISP-03, DISP-04  
**Deliverable:** `.planning/phases/11-disposition-decisions/11-DISPOSITIONS.md` only (+ optional `scripts/phase11-dispositions-assert.sh`)  
**Mode:** Tracer-first · fine granularity · docs-only (no live install, no XDG mutation, no wrapper SAFE_DEFAULTS edit, no hypr/custom creation)

## Plans

| Plan ID | Objective | Wave | Depends On | Requirements |
|---------|-----------|------|------------|--------------|
| 11-01 | Tracer: optional assert harness + `11-DISPOSITIONS.md` eight-section skeleton + pre-flight gate (D-07) + full-adopt flag profile (DISP-02 / D-05 / D-10 residual unchanged) + sample Axis A rows proving D-03 columns end-to-end | 1 | — | DISP-02 |
| 11-02 | Axis A complete: all hypr HIGH (+ MED–HIGH decision) paths dispositioned; must-migrate only monitors/workspaces/env (D-15/D-16); conf primary accept-upstream not keep-personal; scripts fold under hyprland/ | 2 | 11-01 | DISP-01 |
| 11-03 | Axis B misc under drop `--core` (HIGH PRESENT + notable MED + greenfield blurb) + Axis C packages/sysupdate (Syu, asdeps, metas, plasmaintg, full deps pipeline) — all live accept-upstream per D-27..D-31 | 2 | 11-01 | DISP-01 |
| 11-04 | Dual-run chrome accept-remove (DISP-03 / D-11/D-12) + lock/idle no-touch (DISP-04 / D-23..D-26) + UNKNOWN/extra surfaces + full HIGH-path cross-check + VALIDATION sign-off / optional assert green | 3 | 11-02, 11-03 | DISP-03, DISP-04 |

## Wave graph

```text
Wave 1:  11-01 (tracer)
              │
     ┌────────┴────────┐
Wave 2:  11-02          11-03   (parallel; both expand 11-DISPOSITIONS.md sections — sequential file ownership if same file: prefer 11-02 then 11-03 OR single-writer sections only)
     └────────┬────────┘
Wave 3:       11-04 (chrome + lock + UNKNOWN + gate)
```

**File ownership note:** All plans touch `11-DISPOSITIONS.md`. Wave 2 plans must not overlap section ownership: 11-02 owns §3 Axis A only; 11-03 owns §4 Axis B + §5 Axis C only. 11-01 owns §1–§2 + sample §3 stubs; 11-04 owns §6–§8 + cross-check. If executor parallelization cannot guarantee section-only edits, run 11-02 then 11-03 sequentially within wave order.

## Coverage (outline-level)

| Source | Coverage plan(s) |
|--------|------------------|
| GOAL — explicit decisions + staged flag profile | 11-01..11-04 |
| DISP-01 HIGH dispositions | 11-02, 11-03 (complete rows); 11-04 cross-check |
| DISP-02 flag axes + first full profile drops all three | 11-01 |
| DISP-03 chrome accept-remove override | 11-04 |
| DISP-04 hyprlock/hypridle | 11-04 |
| D-01..D-04 artifact shape | 11-01 skeleton; all plans |
| D-05/D-10/D-32 flag profile + residual safe default | 11-01 |
| D-07/D-08 pre-flight | 11-01 |
| D-11..D-14 chrome | 11-04 |
| D-15..D-22 Axis A + extras | 11-02, 11-04 |
| D-23..D-26 lock/idle | 11-04 |
| D-27..D-31 misc/packages | 11-03 |
| Optional assert (discretion) | 11-01 create; 11-04 final green |

## Prohibitions (all plans)

- no live full install
- no XDG mutation (no rsync/cp/mv/rm into `~/.config`)
- no wrapper default full / no edit `SAFE_DEFAULTS`
- no invented inventory surfaces (chrome only via emerged-surface note)
- no hypr/custom creation this phase
- no delete chrome from repo

## OUTLINE COMPLETE
