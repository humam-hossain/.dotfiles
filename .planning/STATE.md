---
gsd_state_version: 1.0
milestone: v0.3
milestone_name: Full ii install
current_phase: 16
current_phase_name: "Retire the safe profile: full-only wrapper and playbook"
status: executing
stopped_at: Completed 16-09-PLAN.md
last_updated: "2026-09-08T07:43:59.314Z"
last_activity: 2026-09-08
last_activity_desc: Phase 16 execution resumed (wave continue)
state_head: 4570379238f0b2a5f5431463ce50206b9cb6cb7a
progress:
  total_phases: 7
  completed_phases: 6
  total_plans: 33
  completed_plans: 32
  percent: 86
---

Total Phases: 6

# Project State

## Current Position

Phase: 16 (Retire the safe profile: full-only wrapper and playbook) — EXECUTING
Plan: 10 of 10
Status: Ready to execute
Total Plans in Phase: 10
Last activity: 2026-09-08 — Phase 16 execution resumed (wave continue)

Progress: [████████████████████] 17/17 plans ([█████████░] 86%)

## Session

**Last session:** 2026-09-08T07:43:44.742Z
**Stopped at:** Completed 16-09-PLAN.md
**Resume file:** None
**Next command:** `/gsd-execute-phase 16`

## Project Reference

See: .planning/PROJECT.md (updated 2026-09-05)

**Core value:** Desktop capability via upstream dots-hyprland + personal overlays — full session install only after known dispositions. Full adopt done (Phase 14); Phase 16 then retired the safe profile from the wrapper, the assert scripts and the operator documents, so there is one install path and nothing left to choose.  
**Current focus:** Phase 16 — Retire the safe profile: full-only wrapper and playbook

## Deferred Items

Items acknowledged and deferred at milestone close on 2026-07-25 (v0.1) and re-acknowledged 2026-08-02 (v0.2 override_closeout):

| Category | Item | Status |
|----------|------|--------|
| debug | cpu-warning-color-missing | unknown (re-acknowledged v0.2; local bar retired) |
| debug | keyboard-volume-ceiling | unknown (re-acknowledged v0.2; local bar retired) |
| debug | pavucontrol-launch-broken | unknown (re-acknowledged v0.2; local bar retired) |
| debug | ram-label-spacing | unknown (re-acknowledged v0.2; local bar retired) |
| requirement | FWK-02 (exec-once auto-start) | deferred finishing touch — revisit under upstream model |
| requirement | IPC-02 (bar toggle keybind) | deferred finishing touch — revisit under upstream model |
| backlog | Waybar cutover (CUT-01) | deferred until parity accepted; DISP-03 defaults keep dual-run **[superseded by Phase 16]** — the dual-run session ended at the Phase 14 adopt. |
| backlog | Waybar customs (CUST-01..04) | deferred past v0.3 full hypr adopt |
| process | v0.2 formal milestone audit | skipped at close; per-phase verification passed |
| requirement | D-38 `graphical-session.target` autostart (post-adopt) | **open, no owning phase** — Phase 15's criteria are documentation-only; needs an owner (14-VERIFICATION.md warning 3) |

See also: `milestones/v0.1-phases/04-ipc-keybinds-integration/04-DEFERRED.md`

## Accumulated Context

### Decisions (carry-forward)

- Delivery = upstream dots-hyprland + personal fork/submodule/wrapper (not local QS rewrite)
- Submodule path fixed at `vendor/dots-hyprland`; pin-bump is primary update
- Thin `arch/dots-hyprland.sh` only; array-exec `./setup` — that is all that survives: one full-only install path, no residual-flag injection, no backup gate, no package re-marking (Phase 16)
- Live install at `~/.config/quickshell` (real tree); ii owns the session hooks in its own Lua tree — `hyprland/env.lua` supplies the venv env and `hyprland/execs.lua` starts `qs -c ii`
- Dual-run chrome: **accept-remove on full adopt** (D-11 override of DISP-03 default-keep); configs **archive in repo** (D-12)
- Canonical playbook: `docs/dots-hyprland-workflow.md`
- v0.1 local product retired (RET-01/02); do not revive `arch/quickshell.sh`
- v0.3: full install only after impact inventory + dispositions (not blind drop of SAFE_DEFAULTS) **[superseded by Phase 16]** — the safe profile and its machinery were retired.
- Phase 10 inventory SoT: `.planning/phases/10-full-install-impact-inventory/10-INVENTORY.md` (neutral; no dispositions)
- Phase 10 UAT: 7/7 pass (6 automated coverage + 1 human confirm) — 2026-08-07
- Phase 11 disposition SoT: `.planning/phases/11-disposition-decisions/11-DISPOSITIONS.md` (committed gate for 12–14)
- Phase 11: first full-adopt drops all three SAFE_DEFAULTS residuals (D-05); residual still default (D-10); must-migrate only monitors/workspaces/env (D-16) **[superseded by Phase 16]** — the safe profile and its machinery were retired.
- Phase 12: `--full` meta on install/install-files; default still injects triple residual; smoke `./scripts/phase12-full-smoke.sh` FAIL=0 on 2026-08-18 **[superseded by Phase 16]** — the safe profile and its machinery were retired.
- Phase 12 UAT: 10/10 pass (1 human coverage confirm + 9 automated); 12-VERIFICATION.md status passed; 12-VALIDATION.md nyquist_compliant true
- Phase 13: authoring SoT = parent-repo `.config/hypr/custom/`; live is applied copy; vendor/fork product-only
- Phase 13: overlays are `general.lua` (hl.monitor + hl.workspace_rule) plus empty env.lua/execs.lua slots; apply documented not run (D-02/D-17)
- Phase 13: D-19 fence exit 0; 13-VERIFICATION.md status passed; OVL-01..03 Complete; live custom still absent
- Phase 14: live `install --full` run 2026-09-04 23:13:41–23:35:01; session now loads via `hyprland.lua` (`configProvider: lua`), `hyprland.conf` renamed to `.old`
- Phase 14: overlay applied live — `general.lua`/`env.lua`/`execs.lua` byte-identical to repo SoT; 11 workspace rules live; `qs -c ii` running; waybar/rofi/swaync stopped per D-11 accept-remove, trees still archived under `stow/` per D-12
- Phase 14: rollback is `docs/phase14-adopt-runbook.md` §14 — three tiers, tier 1 `~/ii-original-dots-backup.20260904T171128Z`; never upstream `./setup uninstall` **[superseded by Phase 16]** — the safe profile and its machinery were retired.
- Phase 14: 14-VERIFICATION.md status passed 4/4; 3 warnings raised, 2 closed in 859e434, D-38 left open
- Phase 14 UAT: 15/15 pass (11 automated coverage + 4 human checkpoints) on 2026-09-05; zero gaps, zero deferred follow-ups
- Phase 14: 14-VALIDATION.md status validated — 15 map rows, 0 MISSING, 5 manual-only, so `nyquist_compliant` stays false by design; 14-SECURITY.md status verified — 16 threats, `threats_open: 0` at ASVS L1

Full decision log: PROJECT.md Key Decisions table.  
Phase archives: `milestones/v0.2-phases/`.  
Phase 16 sweep record: `.planning/phases/16-retire-the-safe-profile-full-only-wrapper-and-playbook/16-DOC-SWEEP.md` — what the safe-profile retirement changed, file by file, and what it deliberately left as history. Read it instead of re-deriving the change set from the plan bodies.

### Resolved blockers

- [Phase 13] Live apply of the hypr/custom overlay was deferred with no owner — resolved in Phase 14; the three files are live and byte-identical to the repo SoT.
- [Phase 14] Two Critical code-review findings (rollback tier 1 a probable no-op under the wiki reading; tier-1 sources asserted non-empty but never hashed) — both closed in 15b0c31.
- [Phase 14] Review IN-11 closed by deletion in plan `16-03`, which removed `scripts/phase14-preflight.sh` — the script that printed `--rotate-backup` as mandatory before go. The adopt it gated ran on 2026-09-04 and nothing re-runs it (D-33); the same closure is recorded in `.planning/v0.3-MILESTONE-AUDIT.md` by plan `16-07`.

### Concerns carried forward

- ⚠️ [Phase 14] `graphical-session.target` autostart died with the renamed conf (D-38). Screen share may stop working. Open, **no owning phase** — Phase 15's criteria are documentation-only. Fix is one `systemctl --user start` or one line in `custom/execs.lua`.
- ⚠️ [Phase 14] Review WR-02 left open: the repo's `.config/hypr/hyprland.conf` is simultaneously a rollback source, frozen D-36 evidence, and a live hook-injection target. Exposure is bounded (content is in git history), but the three roles should be split.

### Roadmap Evolution

- Phase 16 added as a DOC-03 gap closure, then retitled on 2026-09-07 and widened to the safe-profile retirement — full-only wrapper, full-only playbook, and the planning artifacts swept to match. Its original B-1 update-path / B-2 restore-path scope was replaced before execution began; both closed by retiring the destination rather than documenting a route to it.

## Operator Next Steps

1. `/gsd-execute-phase 16` — one plan left: `16-10` completes the sweep record's planning-artifact and phase-gate sections, then runs the D-40 gate on a clean tree plus the post-change login re-verify ← recommended  
2. Find a home for the open D-38 `graphical-session.target` autostart bootstrap — its own phase, or the next milestone; it stays open and unowned until then  
3. `/gsd-secure-phase 13` — security enforcement enabled; no `13-SECURITY.md` yet  
4. `/gsd-validate-phase 13` — `13-VALIDATION.md` still `status: draft` / `nyquist_compliant: false`  
5. `/gsd-map-codebase` re-run after Phase 16 closes — the six `.planning/codebase/` snapshots are all stamped 2026-08-21 and describe the retired wrapper

## Performance Metrics

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 05 P01 | 2min | 2 tasks | 0 files |
| Phase 06 P01 | 2min | 2 tasks | 1 files |
| Phase 07 P02 | 45min | 3 tasks | - files |
| Phase 07 P03 | 15min | 3 tasks | - files |
| Phase 08 P01 | 8min | 3 tasks | 0 files (health gate) |
| Phase 08 P02 | 5min | 3 tasks | 933 deleted |
| Phase 08 P03 | 6min | 3 tasks | 2 (1 delete + 1 comment) |
| Phase 09 P01 | 15min | 3 tasks | 1 created (playbook) |
| Phase 09 P02 | 10min | 2 tasks | 1 modified (playbook) |
| Phase 09 P03 | 10min | 3 tasks | README + PROJECT + REQUIREMENTS + playbook |
| Phase 10 P01–05 | multi-session | 6 tasks | inventory + assert harness |
| Phase 10 UAT | short | 7 tests | 10-UAT.md (7 pass, 0 issues) |
| Phase 11 P01–04 | multi-session | 9 tasks | dispositions + assert + VERIFICATION |
| Phase 11 verify | short | 14/14 | 11-VERIFICATION.md status: passed |
| Phase 12 P04 | 85 min | 2 tasks | 2 files |
| Phase 12 UAT | 2026-08-18 re-verify | 10 tests | 12-UAT.md (10 pass, 0 issues); smoke FAIL=0 |
| Phase 13 P01 | inline | 3 tasks | 3 files |
| Phase 13 P02 | inline | 3 tasks | 2 files |
| Phase 14 P01 | 11 min | 6 tasks | 17 files |
| Phase 14 P02 | operator window + verify | 5 tasks | verify script + 14-LIVE-VERIFY.md + transcript |
| Phase 16 P01 | 38 min | 3 tasks | 2 files |
| Phase 16 P02 | 10 min | 2 tasks | 2 files |
| Phase 16 P03 | 10 min | 2 tasks | 3 files |
| Phase 16 P06 | 25 min | 2 tasks | 2 files |
| Phase 16 P07 | 15 min | 2 tasks | 2 files |
| Phase 16 P08 | 11 min | 2 tasks | 2 files |
| Phase 16 P09 | 13 min | 2 tasks | 2 files |

## Decisions

- [Phase 5]: Created public fork humam-hossain/dots-hyprland via gh repo fork end-4/dots-hyprland --clone=false (D-01); sibling left alone (D-02/D-14)
- [Phase 6]: SAFE_DEFAULTS injection and the backup gate on arch/dots-hyprland.sh; array-exec only **[superseded by Phase 16]** — the safe profile and its machinery were retired.
- [Phase 7]: Wrapper one-shot live install; personal hypr hooks; dual-run waybar preserved
- [Phase 8]: RET-01 tree delete + RET-02 installer hard-delete; live home path protected
- [Phase 9]: Canonical playbook; pin-bump primary update; exp-merge/online cache non-primary
- [v0.2 close]: override_closeout — no formal milestone audit; 4 v0.1 debug sessions re-acknowledged (local product retired)
- [v0.3 start]: Full ii install = inventory → disposition → full profile → overlays → adopt → playbook; phases 10–15
- [Phase 10]: Neutral 10-INVENTORY.md + phase10-inventory-assert.sh; INV-01..04 verified + UAT; SAFE_DEFAULTS residual intact **[superseded by Phase 16]** — the safe profile and its machinery were retired.
- [Phase 11]: 11-DISPOSITIONS.md eight sections; DISP-01..04 complete; full-adopt drops triple residual (D-05); chrome accept-remove (D-11); lock keep-personal (D-24); assert green; VERIFICATION passed 2026-08-10
- [Phase 12]: D-14/D-15/D-16: existing post-setup arms already run when full==1; no wrapper edit — Task 1 official verify passed; no full==0 skip around protect/hooks
- [Phase 12]: Nyquist one-command suite is ./scripts/phase12-full-smoke.sh; execute left nyquist_compliant false; 12-VALIDATION.md now `nyquist_compliant: true` (validated 2026-08-18)
- [Phase 12]: UAT 10/10 + live smoke FAIL=0 on 2026-08-18; ROADMAP `[x]` completed 2026-08-18; FULL-01..05 marked Complete in REQUIREMENTS.md
- [Phase 13]: CONTEXT updated 2026-08-19: overlay content is monitors + workspace pins only; empty env.lua/execs.lua slots; apply fails if general.lua missing. Cursor and VIRTUAL_ENV overlays dropped.
- [Phase 13]: 13-01/13-02 executed; D-19 fence exit 0; 13-VERIFICATION.md status passed; ROADMAP `[x]` via `phase.complete` 2026-08-31; OVL-01..03 Complete; live apply deferred to Phase 14
- [Phase 14]: live full adopt executed behind the preflight gate (backup rotated 17:11:28Z, install gate answered 17:13:41Z); ADOPT-01..04 verified 4/4; ROADMAP `[x]` via `phase.complete` 2026-09-05
- [Phase 14]: code review returned 2 Critical + 13 Warning at 8b0ae39; both Criticals and 4 Warnings closed in 15b0c31, `14-REVIEW.md` flipped to pass; 9 Warnings + 12 Info dispositioned open (WR-02 is the one worth revisiting)
- [Phase 14]: a recorded correction naming a runbook heredoc defect was retracted — no revision of the runbook contains a heredoc; the paste failure was real, its cause was never captured
- [Phase 16]: 16-01: one-way removals confirmed by the operator (proceed) — the wrapper-owned install backup and the install confirmation prompt are both gone (D-06, D-09) — Reversibility gate satisfied at the Task 1 blocking-human checkpoint; existing on-disk snapshots left untouched, upstream greeting and pause still apply
- [Phase 16]: 16-01: upstream --skip-backup is scoped to install / install-files by a new touches_files predicate, not appended unconditionally — Upstream reads SKIP_BACKUP only in 3.files.sh, sourced for those two subcommands; scoping keeps the dry-run preview truthful and gives the assert a crisp negative on install-setups (A1)
- [Phase 16]: 16-01: --full is accepted on all four install-family subcommands as an announced no-op; install-deps --full flips from exit 1 to exit 0 — The scope check used the predicate D-04 deletes; a no-op alias with a scope restriction is self-contradictory (A2)
- [Phase 16]: 16-03: ADOPT-04 was retired from every message in scripts/phase14-verify.sh, not just from the surviving removal probe — D-26 deletes the ADOPT-04 row from REQUIREMENTS.md this phase, so a live [PASS] line citing it would name a requirement with no definition anywhere in the repo. The two surviving pre-adopt conf probes now cite D-20 and the removal probe cites D-10; assertions, hashing and pass/fail structure are unchanged (message-only).
- [Phase 16]: 16-03: the sha256sum file-wide absence criterion was satisfied in scope, not literally — Three of its four call sites are inside assertions D-37 explicitly keeps (check_tier1_source, check_untouched, check_sidecar). Deletion of the backup-integrity block is proven instead by the absence of backup_dir_hyprland_conf_mtime, 'D-36 backup' and BK_CONF. Recorded as WINDOWS.md id 4.
- [Phase 16]: 16-03: IN-11 closed by deletion of scripts/phase14-preflight.sh, not by fixing its --rotate-backup message — D-33 supersedes the earlier fix-the-message plan. The script gated an adopt that ran on 2026-09-04 and nothing re-runs it; running it today would rename away a rollback source. Post-deletion sweep outside .git/, .planning/ and docs/ returned RUNNERS:none. Two artifacts still record IN-11 as open until wave 5: v0.3-MILESTONE-AUDIT.md (plan 16-07) and STATE.md (plan 16-09).
- [Phase 16]: Wrapper drift baseline re-pinned to 0771cc2, resolved at execution time — git log -1 on arch/dots-hyprland.sh plus an empty-diff confirmation is self-correcting; a SHA copied from a planning document would be wrong because the wrapper was split across plans 16-01 and 16-02
- [Phase 16]: 16-DOC-SWEEP.md is a load-bearing marker, not only a record — scripts/phase13-d19-assert.sh selects its wrapper drift baseline by testing for the file's presence, so moving or renaming it silently reverts the comparison to the Phase 14 pin
- [Phase 16]: 16-07: INV-04 keeps its Phase 10 traceability mapping although its text was rewritten — D-26 says it stays at Phase 10; D-27 says rewritten rows map to Phase 16. The two conflict for exactly this one ID. The specific rule governs, and it is what keeps the row consistent with D-39, which deliberately leaves scripts/phase10-inventory-assert.sh requiring the retired language in the frozen Phase 10 record.
- [Phase 16]: 16-07: the phase supersession-annotation form is a bold bracketed suffix followed by a short clause naming what delivered or retired the claim, as in **[superseded by Phase 16]** — the safe profile and its machinery were retired. CONTEXT.md left the wording to the executor as long as one form is used across REQUIREMENTS.md, PROJECT.md and STATE.md. First applied to CUT-01 in REQUIREMENTS.md; plans 16-08 and 16-09 reuse it verbatim, in the two clause variants 16-08 fixed.
- [Phase 16]: 16-07: the three retired requirement IDs are not named anywhere in REQUIREMENTS.md, not even in the coverage note explaining the 22-to-19 drop — The plan's own orphan check bans FULL-03, FULL-05 and ADOPT-04 file-wide, so a coverage note naming them reads as an orphan. The note describes what each row promised instead, and points at 16-DOC-SWEEP.md for the identifiers.
- [Phase 16]: 16-07: the milestone audit's status: gaps_found and its scores block are left as the 2026-09-06 measurement; findings are dispositioned in place with added disposition and resolution keys — Rewriting the scores would make the audit assert numbers it never measured. A dispositioned metadata block plus a disposition_note records the later state without restructuring the audit or erasing its findings (A21).
- [Phase 16]: 16-07: Flow A was retired out of the end-to-end completion count rather than left counted as broken; Flow C moved to complete, and both section headings state the audit-time and post-disposition counts — A22 required restating a flow honestly rather than silently upgrading it. Flow A's destination no longer exists, so broken would misdescribe it; Flow C's apply hop is now one flat install-files, which is what closed B-1.
- [Phase 16]: 16-09: the ROADMAP coverage line was recomputed to 19/19 from the live REQUIREMENTS.md arithmetic, not from the plan prose — the plan text and the requirement set are checked against each other because a coverage line that disagrees with the requirement set produces a milestone-audit finding that is an artifact of bookkeeping rather than of the work
- [Phase 16]: 16-09: Phase 15's success criterion 1 was amended and annotated rather than frozen as history — the task's forbidden-string gate bans 'documents safe vs full' file-wide and D-28's leave-as-history list names only Phases 11, 12 and 14. The criterion still records what Phase 15 shipped; only the banned literal changed.
- [Phase 16]: 16-09: three historical entries lost a banned token while keeping their claim — the Phase 6 decision row, the annotation-form decision entry and operator next step 2. Each of the plan's gates is file-wide while its prose instruction is site-scoped, so a mark-as-history-only treatment left the gate red; the resolution changes the token form and preserves the assertion.
