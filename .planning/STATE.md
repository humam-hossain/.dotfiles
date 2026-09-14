---
gsd_state_version: "1.0"
milestone: v0.4
milestone_name: Personal config layer
current_phase: 22
current_phase_name: KDE and GTK capture
status: planning
stopped_at: Phase 21 complete, ready to plan Phase 22
last_updated: "2026-09-14T23:42:25.358Z"
last_activity: 2026-09-15
last_activity_desc: Phase 21 complete, transitioned to Phase 22
state_head: 66da82447304e8669941424c639126590a00b548
progress:
  total_phases: 7
  completed_phases: 5
  total_plans: 31
  completed_plans: 31
  percent: 71
---

Total Phases: 7 (Phases 17-23)

# Project State

## Current Position

Phase: 22 — KDE and GTK capture
Plan: Not started
Status: Ready to plan
Last activity: 2026-09-15 — Phase 21 complete, transitioned to Phase 22

## Session

**Last session:** 2026-09-15T05:42:00+06:00
**Stopped at:** Phase 21 complete, ready for Phase 22
**Resume file:** .planning/phases/21-ii-bar-config-capture/21-VERIFICATION.md
**Next command:** `/gsd-plan-phase 22`

## Project Reference

See: .planning/PROJECT.md (updated 2026-09-14)

**Core value:** Desktop capability via upstream dots-hyprland + personal overlays — full session install only after known dispositions. Full adopt done (Phase 14); Phase 16 then retired the safe profile from the wrapper, the assert scripts and the operator documents, so there is one install path and nothing left to choose.  
**Current focus:** Phase 22 — KDE and GTK capture
**v0.4 core value:** A fresh machine reproduces this exact desktop from a clone and one command, and everything configured afterward is captured without a manual sync step.

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
| requirement | D-38 `graphical-session.target` autostart (post-adopt) | **owned — Phase 17 / START-02** (v0.4 roadmap 2026-09-12); ships as one line in `custom/execs.lua` |

See also: `milestones/v0.1-phases/04-ipc-keybinds-integration/04-DEFERRED.md`

## Accumulated Context

### Decisions (carry-forward)

- Delivery = upstream dots-hyprland + personal fork/submodule/wrapper (not local QS rewrite)
- Submodule path fixed at `vendor/dots-hyprland`; pin-bump is primary update
- Thin `arch/dots-hyprland.sh` only; array-exec `./setup` — that is all that survives: one full-only install path, no residual-flag injection, no backup gate, no package re-marking (Phase 16)
- `--keep-backup` is the one opt-out on the full-only install path: the wrapper injects `--skip-backup` by default, and this meta flag omits it for a run so upstream's `auto_backup_configs` still fires (Phase 16 review H-01)
- The uninstall state re-clean is flag-scoped and routed through `safe_rm_path`; `--keep-venv` and `--packages-only` are honoured and `--dry-run` shows the real plan (Phase 16 review C-01)
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

- ✅ [Phase 14] `graphical-session.target` autostart died with the renamed conf (D-38). **Now owned: Phase 17 / START-02** — ships early and deliberately, because it is one line in `custom/execs.lua`, independent of the capture mechanism, and in the one directory the installer provably never touches.
- ⚠️ [Phase 14] Review WR-02 left open: the repo's `.config/hypr/hyprland.conf` is simultaneously a rollback source, frozen D-36 evidence, and a live hook-injection target. Exposure is bounded (content is in git history), but the three roles should be split.

### Roadmap Evolution

- v0.4 roadmapped 2026-09-12 — Phases **17-23**, continuing from v0.3's last phase 16. Seven phases, 33/33 requirements mapped, no orphans. Ordering is de-risk-first because the live desktop session is the production system: blockers (17) → capture model and collision map (18) → link-aware `verify` (19) → first bulk stow at `hypr/custom` (20) → `config.json` capture + timer (21) → KDE/GTK (22) → bootstrap (23).
- v0.4 deviation from the research's six-phase proposal: its P18 (collision map **and** `verify`) is split into Phases 18 and 19, so the adversarial `verify` test (VER-04) is a phase gate in its own right rather than one criterion among ten — and so `verify` provably exists before the first bulk stow in Phase 20.
- Phase 16 added as a DOC-03 gap closure, then retitled on 2026-09-07 and widened to the safe-profile retirement — full-only wrapper, full-only playbook, and the planning artifacts swept to match. Its original B-1 update-path / B-2 restore-path scope was replaced before execution began; both closed by retiring the destination rather than documenting a route to it.

## Operator Next Steps

1. `/gsd-plan-phase 17` — plan the unblock phase (no research needed; every defect is located to a line) ← recommended  
2. `/gsd-map-codebase` re-run — the six `.planning/codebase/` snapshots are all stamped 2026-08-21 and describe the retired wrapper  
3. Decide before Phase 23 whether a VM or container can be stood up — it is the only way to exercise the fresh-machine relogin hop; otherwise BOOT-01 is verified at the scratch-`XDG_CONFIG_HOME` level and must be labelled as such

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
| Phase 16 P10 | 17 min | 2 tasks | 1 files |
| Phase 17 P01 | 2 min | 3 tasks | 16 files |
| Phase 17 P02 | 3 min | 3 tasks | 3 files |
| Phase 18 P01 | 12 min | 3 tasks | 4 files |
| Phase 18 P02 | 8 min | 3 tasks | 5 files |
| Phase 18 P03 | 7 min | 3 tasks | 3 files |
| Phase 18 P04 | 8 min | 3 tasks | 7 files |
| Phase 19 P01 | 3 min | 3 tasks | 2 files |

## Decisions

- [Phase 5]: Created public fork humam-hossain/dots-hyprland via gh repo fork end-4/dots-hyprland --clone=false (D-01); sibling left alone (D-02/D-14)
- [Phase 6]: SAFE_DEFAULTS injection and the backup gate on arch/dots-hyprland.sh; array-exec only **[superseded by Phase 16]** — the safe profile and its machinery were retired.
- [Phase 7]: Wrapper one-shot live install; personal hypr hooks; dual-run waybar preserved
- [Phase 8]: RET-01 tree delete + RET-02 installer hard-delete; live home path protected
- [Phase 9]: Canonical playbook; pin-bump primary update; exp-merge/online cache non-primary
- [v0.2 close]: override_closeout — no formal milestone audit; 4 v0.1 debug sessions re-acknowledged (local product retired)
- [v0.3 start]: Full ii install = inventory → disposition → full profile → overlays → adopt → playbook; phases 10–15
- [v0.4 start]: Personal config layer = unblock → capture model → verify → hypr/custom → config.json → KDE/GTK → bootstrap; phases 17–23. Three capture trees (`stow/` installer-never-collides, `restow/` installer-overwrites, `capture/` writer-renames-over-the-link) replace D-41's "atomic writes" framing, which the research falsified: Qt `QSaveFile` resolves symlinks and is the *safest* writer; the real threats are the ii installer's `rsync -a --delete` / `cp -f` and `switchwall.sh`'s bare `mv`.
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
- [Phase 16]: Phase 16 gate (D-40) ran green on a clean tree at 95b86fd: phase16-retire, phase12-full-smoke, phase11-dispositions and phase10-inventory each FAIL=0, phase13-d19 FAIL=0 with the 0771cc2 drift pin and W-3 fence intact, phase14-verify FAIL=0 FINDINGS=1 — the known D-38 loss, still emitted and still allowed. Transcript quoted verbatim in 16-DOC-SWEEP.md.
- [Phase 16]: The D-40 human re-login is OUTSTANDING, not performed — the executing agent cannot end the operator's Hyprland session. The automated post-change probes (configProvider lua, qs -c ii running, waybar/swaync stopped) did run and are a weaker statement than a fresh login. Recorded as outstanding in 16-DOC-SWEEP.md's phase-gate section with the four checks the operator still owes.
- [Phase 16]: 16-10: the sweep record is the only place FULL-03, FULL-05 and ADOPT-04 are named — REQUIREMENTS.md's orphan check bans them file-wide, so its coverage note points there. The record also carries the resolved D-26-over-D-27 conflict on INV-04 and the four frozen-artifact override sites.
- [Phase 17]: Ban greps for the retired stow spelling are scoped by explicit path list to arch/ and docs/ — .planning/research/PITFALLS.md carries the same string as frozen history under the Phase 16 precedent and is never edited to make a gate green — A gate turned green by rewriting the historical record is a false green; the frozen copy is evidence, not code
- [Phase 17]: The D-02 folding audit reports [INFO] only and never [PASS]/[FAIL] — the two pre-existing folded directory symlinks are recorded and handed to Phase 18 rather than unfolded here — no-folding governs new stow runs only; unfolding is a tree-taxonomy decision Phase 18 owns
- [Phase 17]: The dispatch guard is the `if … fi` spelling, not CONTEXT D-09 conjunction form — Research F-5 falsified the conjunction form live: as the last statement of a sourced file it leaves the source return status at 1 and aborts a set -e caller before it reaches any fixture, defeating D-21 in a place that looks unrelated to the guard
- [Phase 17]: safe_rm_path repo refusal compares realpath -m resolved strings, never a literal prefix on the unresolved argument — D-05: a $HOME-shaped path can reach the repo through a symlink and one already does — ~/.config/systemd/user/hyprland-session.service resolves into stow/systemd/ and is accepted by a literal prefix test, refused by the resolved comparison
- [Phase 17]: Every assert-harness subshell exercising a destructive function shadows rm with a no-op after loading the code under test — The plan non-mutating by construction claim was conditional on the guard under test being correct; performing the plan own commented-out-clause check deleted README.md, the stow/ tree and the vendored submodule. A verifier whose safety depends on the correctness of the code it verifies is not safe. All files were restored from git and the fixture now enforces non-mutation instead of assuming it
- [Phase 17]: Wrapper drift baseline re-pinned to b32faf6 behind a new Phase 17 tier; scripts/phase13-d19-assert.sh now resolves phase artifacts through the v0.3 milestone archive — The v0.3 archival moved every .planning/phases/ path the script hard-coded, so it died before its first assert and its marker-file tier chain would have selected the Phase 12 pin; the frozen 13-SOT-APPLY.md is not edited — the path is rewritten on the extracted fence at the call site
- [Phase 18]: 18-01: the collision map's tree column is derived from the two outcome columns and holds only stow or restow; no authored override column exists — Checkpoint resolved derived-two-value (D-05). One source of truth for 'how is this file captured' is the property CAP-01 rests on; capture/ membership is consequently hand-assigned prose in capture/README.md, not derivable from the map.
- [Phase 18]: 18-01: a call site whose source argument lives under dots-extra/ is skipped as a flag-reached alternate, and both such sites are named in the map header as coverage gaps — Excluding 3.files-legacy.sh:42 (--fontset) and :66 (--via-nix) by line number would rot at the next pin bump; the source-path rule survives it and covers the D-32 accepted risk mechanically.
- [Phase 18]: 18-02: tree contracts established; stow and restow membership predicates match collision-map.tsv derived outcomes, capture/ membership is hand-assigned prose — Location alone decides how a file is captured (CAP-01)
- [Phase 18]: 18-03: wrapper main() prologue refuses --exp-files with exit 2 and names collision-map.tsv — Experimental files path uses disjoint write primitives that would void every row of collision-map.tsv (CAP-08)
- [Phase 18]: 18-04: config redistribution table committed; hyprland.conf archived in docs/archive/ and KDE configs moved to restow/ with live state adopted — Every file leaving repo-root .config is accounted for with independently revertible commits per disposition (FIX-03)
- [Phase 19]: Phase 19: unknown verify flags exit 2, not 1 (D-15) — an unknown flag means the tree was never examined; the refusal lands on fd 2 and prints no summary line
- [Phase 19]: Phase 19: --quiet gates pass() as an if block, never a trailing conjunction — that form leaves the function return status at 1 when quiet is 0 and aborts the set -euo pipefail caller at the first passing check
- [Phase 19]: Phase 19: the destructive harness guard is one callable fail-closed function whose refusal branch is proven by a three-case subshell probe against two real out-of-scratch paths, never inferred from its source text
- [Phase 20]: Six personal Hyprland custom overlays (env, execs, general, rules, keybinds, variables) managed as stow symlinks under stow/hypr/.config/hypr/custom/ with universal --no-folding
- [Phase 20]: Personal keybindings authored with 16 explicit hl.unbind calls for upstream collisions and "Category: Label" taxonomy for Quickshell cheatsheet integration
- [Phase 20]: Single-fire startup hook (hl.on("hyprland.start", ...)) restores polkit agent, Chrome, kitty, and special workspace autostarts; cursor unified to Bibata-Modern-Classic 24
- [Phase 21]: Change detection (cmp -s) evaluates before mirror_is_capturable in run_capture, skipping byte-identical files as unchanged no-ops without false dirty-mirror warnings
- [Phase 21]: JSON format validation enforces non-zero size ([[ -s "$live" ]]) and syntactic validity (jq empty), failing closed on empty or corrupt files without modifying the repository mirror
- [Phase 21]: Temporary file rename on the same filesystem (${repo_file}.tmp.$$ to $repo_file) provides atomic replacement during capture
- [Phase 21]: Systemd user units (dotfiles-capture.service oneshot and dotfiles-capture.timer 2m startup / 15m active) stowed under stow/systemd/ and enabled via arch/hyprland.sh
- [Phase 21]: Quickshell ii bar settings baseline adopted into capture/ii/.config/illogical-impulse/config.json with top bar orientation, spark icon, Dhaka weather, and 5 workspaces
