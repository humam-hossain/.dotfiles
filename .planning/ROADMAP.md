# Roadmap: Quickshell Desktop Shell

## Milestones

- ✅ **v0.1 Core Framework & Basic Bar** — Phases 1–4 (shipped 2026-07-25)
- ✅ **v0.2 Adopt dots-hyprland** — Phases 5–9 (shipped 2026-08-02)
- 🚧 **v0.3 Full ii install** — Phases 10–16 (in progress)

## Overview

v0.3 moves from dual-run adopt (SAFE_DEFAULTS: `--core --skip-hyprland --skip-sysupdate`) to a **full dots-hyprland install path** — but only after **impact inventory** and **per-surface dispositions**. Personal must-keeps migrate into `hypr/custom` Lua overlays; the wrapper's only install path is the full one and the residual defaults are retired; live adopt is gated; the playbook documents that single install path.

**Not this milestone:** Waybar custom ports (CUST-*), blind full install.

**Phase numbering:** Continues after v0.2 (last phase **9**). v0.3 starts at **Phase 10**.

## Phases

<details>
<summary>✅ v0.1 Core Framework & Basic Bar (Phases 1-4) — SHIPPED 2026-07-25</summary>

- [x] Phase 1: Shell Foundation & Theme (4/4 plans) — completed 2026-07-21
- [x] Phase 2: Core Bar Modules (13/13 plans) — completed 2026-07-23
- [x] Phase 3: System & Audio Modules (10/10 plans) — completed 2026-07-24
- [x] Phase 4: IPC, Keybinds & Integration (4/4 plans) — completed 2026-07-25

Full phase details: [milestones/v0.1-ROADMAP.md](milestones/v0.1-ROADMAP.md)  
Requirements archive: [milestones/v0.1-REQUIREMENTS.md](milestones/v0.1-REQUIREMENTS.md)  
Phase artifacts: [milestones/v0.1-phases/](milestones/v0.1-phases/)

</details>

<details>
<summary>✅ v0.2 Adopt dots-hyprland (Phases 5-9) — SHIPPED 2026-08-02</summary>

- [x] Phase 5: Fork & Submodule Pin (3/3 plans) — completed 2026-07-25
- [x] Phase 6: Thin Setup Wrapper & Safe Defaults (3/3 plans) — completed 2026-07-26
- [x] Phase 7: Install, Session Hooks & Dual-Run Verify (3/3 plans) — completed 2026-07-27
- [x] Phase 8: Retire Local Quickshell Product (3/3 plans) — completed 2026-07-28
- [x] Phase 9: Workflow Documentation & Update Contract (3/3 plans) — completed 2026-08-01

Full phase details: [milestones/v0.2-ROADMAP.md](milestones/v0.2-ROADMAP.md)  
Requirements archive: [milestones/v0.2-REQUIREMENTS.md](milestones/v0.2-REQUIREMENTS.md)  
Phase artifacts: [milestones/v0.2-phases/](milestones/v0.2-phases/)

</details>

### v0.3 Full ii install

- [x] **Phase 10: Full-install impact inventory** — Map every path/flag effect of full install vs personal configs (completed 2026-08-07)
- [x] **Phase 11: Disposition decisions** — Per-surface keep/migrate/accept/defer + staged flag choices (completed 2026-08-10)
- [x] **Phase 12: Wrapper full-profile** — Explicit opt-in full path; SAFE_DEFAULTS remain default (completed 2026-08-18)
- [x] **Phase 13: Personal hypr/custom overlays** — Migrate must-keeps; SoT policy; before live full hypr files (completed 2026-08-31)
- [x] **Phase 14: Live full adopt & verify** — Gated full install; Lua session; UAT; safe rollback guidance (completed 2026-09-05)
- [x] **Phase 15: Playbook safe vs full** — Document profiles, sequence, overlay SoT, non-goals (completed 2026-09-06)

## Phase Details

### Phase 10: Full-install impact inventory

**Goal:** Operator can see exactly what a full install would change before any disposition or mutation  
**Depends on:** v0.2 complete (live dual-run ii + SAFE_DEFAULTS wrapper)  
**Requirements:** INV-01, INV-02, INV-03, INV-04  
**Success Criteria** (what must be TRUE):

  1. A committed inventory artifact lists filesystem + package/sysupdate effects for install **without** `--skip-hyprland`, and separately for dropping `--core` and `--skip-sysupdate`
  2. Inventory includes personal hypr surfaces vs upstream hypr install behavior (conf → `.old`, hyprland sync, lua entry, lock/idle backup, custom ignore_existing)
  3. Inventory lists non-hypr clash candidates if `--core` is dropped (fish, kitty, starship, fontconfig, other present misc targets)
  4. Inventory records the SAFE_DEFAULTS install behavior as Phase 10 found it — a frozen record of what that phase captured, not a claim about what the wrapper does now (Phase 16 retired the profile; the Phase 10 record stands)

**Plans:** 5/5 plans complete

Plans:
**Wave 1**

- [x] 10-01-PLAN.md — Tracer: Wave 0 assert + inventory scaffold + SAFE_DEFAULTS residual (INV-04)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 10-02-PLAN.md — Axis A: drop `--skip-hyprland` hypr effects (INV-02)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 10-03-PLAN.md — Axis B: drop `--core` full misc catalog (INV-03)

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 10-04-PLAN.md — Axis C: packages/sysupdate effects (INV-01)

**Wave 5** *(blocked on Wave 4 completion)*

- [x] 10-05-PLAN.md — Host snapshot, UNKNOWN notes, cross-check, full assert

### Phase 11: Disposition decisions

**Goal:** Every high-risk change has an explicit human decision and staged flag profile before tooling or live adopt  
**Depends on:** Phase 10  
**Requirements:** DISP-01, DISP-02, DISP-03, DISP-04  
**Success Criteria** (what must be TRUE):

  1. Every high-risk inventory row has disposition: keep-personal / migrate-to-hypr-custom / accept-upstream / merge / defer + rationale
  2. Staged flag choices are recorded: drop `--skip-hyprland` only vs also drop `--core` vs allow sysupdate (not assumed all three)
  3. Dual-run chrome (Waybar/rofi/swaync) disposition is **keep** unless explicitly accepted otherwise
  4. hyprlock/hypridle disposition is recorded consistent with keeping hyprlock (no QS lock investment)

**Plans:** 4/4 plans complete

Plans:

**Wave 1**

- [x] 11-01-PLAN.md — Tracer: Wave 0 assert + dispositions scaffold + pre-flight + flag profile (DISP-02)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 11-02-PLAN.md — Axis A hypr HIGH dispositions (DISP-01)
- [x] 11-03-PLAN.md — Axis B misc + Axis C packages (DISP-01)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 11-04-PLAN.md — Chrome accept-remove (DISP-03) + lock/idle (DISP-04) + HIGH cross-check

### Phase 12: Wrapper full-profile

**Goal:** Operator can dry-run and invoke an explicit full-install path without making full the accidental default  
**Depends on:** Phase 11 (flag axes from DISP-02)  
**Requirements:** FULL-01, FULL-02, FULL-03, FULL-04, FULL-05  
**Success Criteria** (what must be TRUE):

  1. Documented opt-in full path does not inject `--skip-hyprland` and applies other flag drops only per DISP-02
  2. Default `install` / `install-files` still inject SAFE_DEFAULTS
  3. Full path keeps backup gate and refuses bare `--skip-backup` without allow override
  4. `--dry-run` on full path shows argv without unwanted SAFE_DEFAULTS injection
  5. After full install/deps path, PROTECT_EXPLICIT re-mark (or protect) still runs

**Plans:** 4/4 plans complete

- [x] 12-01-PLAN.md
- [x] 12-02-PLAN.md
- [x] 12-03-PLAN.md
- [x] 12-04-PLAN.md

### Phase 13: Personal hypr/custom overlays

**Goal:** Personal must-keeps selected for migrate exist as ii-compatible `hypr/custom` overlays before live full hypr files rely on them  
**Depends on:** Phase 11 (what to migrate); may parallelize with Phase 12  
**Requirements:** OVL-01, OVL-02, OVL-03  
**Success Criteria** (what must be TRUE):

  1. Selected must-keeps (monitors, workspaces, env, exec-once, keybinds, rules as applicable) are expressed as `hypr/custom` Lua compatible with `hyprland.lua` requires
  2. Overlay prep is done or checklist-gated **before** first live full hypr files install that needs those must-keeps
  3. Repo vs live vs fork SoT policy for hypr/custom is written and used for any committed overlays

**Plans:** 2/2 plans complete

Plans:
**Wave 1**

- [x] 13-01-PLAN.md — Tracer: repo custom/general.lua dual-head + pins, empty env.lua slot, SoT fence

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 13-02-PLAN.md — Empty execs.lua slot, D-18 apply command, full D-19 verify

### Phase 14: Live full adopt & verify

**Goal:** Live machine runs full hypr adopt per dispositions with verified session and safe rollback guidance  
**Depends on:** Phases 10–13 (INV+DISP satisfied; full path ready; overlays ready)  
**Requirements:** ADOPT-01, ADOPT-02, ADOPT-03, ADOPT-04  
**Success Criteria** (what must be TRUE):

  1. Live full install runs only after INV-* and DISP-* artifacts are satisfied (process gate enforced in plan/UAT)
  2. Hyprland session loads via ii Lua entry (`hyprland.lua` / hyprland tree), not pre-adopt personal conf as primary
  3. Operator verifies monitors/layout per disposition, `qs -c ii` runs, dual-run policy matches DISP-03
  4. Rollback guidance exists that does **not** use upstream `./setup uninstall`

**Plans:** 2/2 plans complete

Plans:
**Wave 1**

- [x] 14-01-PLAN.md — Prep: adopt runbook, non-mutating preflight script, pre-adopt baseline fixture, D-07 live-to-repo `.config` archive, `PROTECT_EXPLICIT` edit, clean tree pushed (wave 1)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 14-02-PLAN.md — Operator adopt window, then post-adopt verify script, `14-LIVE-VERIFY.md` record and committed transcript (wave 2, gated on the window)

### Phase 15: Playbook safe vs full

**Goal:** Operator can re-run safe or full profiles from docs without tribal knowledge  
**Depends on:** Phases 12–14 (real paths exist); can draft earlier, complete after adopt  
**Requirements:** DOC-03, DOC-04  
**Success Criteria** (what must be TRUE):

  1. Playbook documents both install profiles as they stood at Phase 15, inventory→disposition→adopt sequence, and flag axes **[superseded by Phase 16]** — the safe profile and its machinery were retired.
  2. Playbook documents hypr/custom overlay expectations and repo/live/fork SoT policy (OVL-03)

**Plans:** 6/6 plans complete
**Wave 1**

- [x] 15-01-PLAN.md — ground-truth deviation gate + tracer: one corrected fact through README, playbook, PROJECT.md, sweep record

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 15-02-PLAN.md — playbook Purpose/Prerequisites, Profiles safe vs full + flag-axis table, the pre-install gate
- [x] 15-03-PLAN.md — runbook corrections: rollback tier-1 source 3, rotate-backup caveat, two pre-adopt-tense claims

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 15-04-PLAN.md — playbook install walkthrough, session model, overlay policy (DOC-04), verification section

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 15-05-PLAN.md — playbook known losses, three roles of the repo hyprland.conf, non-goals, final Outline + See also

**Wave 5** *(blocked on Wave 4 completion)*

- [x] 15-06-PLAN.md — doc sweep record completion, deferred fixes with owners, phase gate transcript

### Phase 16: Retire the safe profile: full-only wrapper and playbook

**Goal:** Retire the safe profile from the project entirely, in one merged phase. `arch/dots-hyprland.sh` stops injecting `SAFE_DEFAULTS`, so a bare `install` / `install-files` runs the full behavior; the backup gate, the protect machinery and the ii-hook injection machinery go with it, `uninstall` survives stripped, and `--full` stays as an accepted no-op alias. `docs/dots-hyprland-workflow.md` is rewritten full-only end to end with bare commands and `docs/phase14-adopt-runbook.md` is swept to match, both landing after the wrapper so no quoted output goes stale. `.planning/REQUIREMENTS.md`, `ROADMAP.md`, `PROJECT.md`, `STATE.md`, `v0.3-MILESTONE-AUDIT.md` and the Phase 11 disposition record are amended for the same falsehoods, dropping v0.3 coverage from 22 to 19. Closes v0.3 audit leftovers IN-11, W-1, W-2 and W-3.
**Requirements**: FULL-01, FULL-02, FULL-04, ADOPT-02, ADOPT-03, DOC-03, INV-04, IN-11, W-1, W-2, W-3
**Depends on:** Phase 15
**Plans:** 9/10 plans executed

Plans:
**Wave 1**

- [x] 16-01-PLAN.md — wrapper surgery: full-only install path, machinery deletion, new phase16 retirement assert

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 16-02-PLAN.md — usage heredoc rewritten to the surviving surface; phase12 smoke inverted to the new contract
- [x] 16-03-PLAN.md — phase14-verify deleted probes; phase07-live-smoke and phase14-preflight removed (closes IN-11)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 16-04-PLAN.md — playbook rewritten full-only end to end; ban-only doc gate added to the phase16 assert
- [x] 16-05-PLAN.md — adopt runbook swept: preflight section becomes narrative, rollback tiers replaced

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 16-06-PLAN.md — 16-DOC-SWEEP.md written; phase13-d19 re-pinned with a third tier plus the W-3 fence-drift assert

**Wave 5** *(blocked on Wave 4 completion)*

- [x] 16-07-PLAN.md — REQUIREMENTS.md amended to 19/19; v0.3-MILESTONE-AUDIT.md blockers dispositioned
- [x] 16-08-PLAN.md — PROJECT.md swept; 11-DISPOSITIONS.md W-1 and W-2 corrected in place

**Wave 6** *(blocked on Wave 5 completion)*

- [x] 16-09-PLAN.md — ROADMAP.md milestone prose and coverage line; STATE.md swept

**Wave 7** *(blocked on Wave 6 completion)*

- [ ] 16-10-PLAN.md — sweep record completed; D-40 phase gate on a clean tree plus the post-change login re-verify

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Shell Foundation & Theme | v0.1 | 4/4 | Complete | 2026-07-21 |
| 2. Core Bar Modules | v0.1 | 13/13 | Complete | 2026-07-23 |
| 3. System & Audio Modules | v0.1 | 10/10 | Complete | 2026-07-24 |
| 4. IPC, Keybinds & Integration | v0.1 | 4/4 | Complete | 2026-07-25 |
| 5. Fork & Submodule Pin | v0.2 | 3/3 | Complete | 2026-07-25 |
| 6. Thin Setup Wrapper & Safe Defaults | v0.2 | 3/3 | Complete | 2026-07-26 |
| 7. Install, Session Hooks & Dual-Run Verify | v0.2 | 3/3 | Complete | 2026-07-27 |
| 8. Retire Local Quickshell Product | v0.2 | 3/3 | Complete | 2026-07-28 |
| 9. Workflow Documentation & Update Contract | v0.2 | 3/3 | Complete | 2026-08-01 |
| 10. Full-install impact inventory | v0.3 | 5/5 | Complete    | 2026-08-07 |
| 11. Disposition decisions | v0.3 | 4/4 | Complete    | 2026-08-10 |
| 12. Wrapper full-profile | v0.3 | 4/4 | Complete    | 2026-08-18 |
| 13. Personal hypr/custom overlays | v0.3 | 2/2 | Complete    | 2026-08-31 |
| 14. Live full adopt & verify | v0.3 | 2/2 | Complete    | 2026-09-05 |
| 15. Playbook safe vs full | v0.3 | 6/6 | Complete    | 2026-09-06 |
| 16. Retire the safe profile | v0.3 | 9/10 | In Progress|  |

**Coverage:** v0.1 shipped · v0.2 shipped · v0.3 19/19 requirements mapped · 0 unmapped

---
*Last updated: 2026-09-08 — Phase 16 plan 16-09: milestone prose, Phase 10 criterion 4 and the coverage line amended to the retirement that shipped (D-27, D-28)*
