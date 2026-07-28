# Roadmap: Quickshell Desktop Shell

## Milestones

- ✅ **v0.1 Core Framework & Basic Bar** — Phases 1–4 (shipped 2026-07-25)
- 🚧 **v0.2 Adopt dots-hyprland** — Phases 5–9 (in planning)

## Overview

v0.2 retires the hand-rolled Quickshell product tree and adopts [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) as a managed dependency: personal fork, `vendor/dots-hyprland` submodule, thin `arch/` wrapper around `./setup`, live `qs -c ii` dual-running with Waybar, then delete the local product and document the operator workflow. Custom Waybar ports and full cutover are explicitly later.

**Phase numbering:** Continues after v0.1 (last phase **4**). v0.2 starts at **Phase 5**.

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

### v0.2 Adopt dots-hyprland

- [x] **Phase 5: Fork & Submodule Pin** — Personal fork, remotes, `vendor/dots-hyprland` recursive pin
- [x] **Phase 6: Thin Setup Wrapper & Safe Defaults** — `arch/dots-hyprland.sh` → `./setup` with non-destructive defaults
- [x] **Phase 7: Install, Session Hooks & Dual-Run Verify** — Live ii shell + personal hypr hooks; Waybar preserved
- [ ] **Phase 8: Retire Local Quickshell Product** — Delete in-repo QS tree; retire `arch/quickshell.sh`
- [ ] **Phase 9: Workflow Documentation & Update Contract** — Clone/install/update/dual-run playbook

## Phase Details

### Phase 5: Fork & Submodule Pin

**Goal:** Own and pin dots-hyprland inside `.dotfiles` before any install mutates the machine  
**Depends on:** v0.1 complete (no code dependency; process start)  
**Requirements:** OWN-01, OWN-02, OWN-03  
**Success Criteria** (what must be TRUE):

  1. Operator can `git remote -v` inside the vendored tree and see `origin` → personal fork and `upstream` → end-4
  2. `.dotfiles` has `vendor/dots-hyprland` registered in `.gitmodules` with a pinned submodule commit in the parent repo
  3. `git submodule update --init --recursive` yields a complete tree including nested shapes (no missing submodule paths)

**Plans:** 3/3 plans complete

Plans:

- [x] 05-01-PLAN.md
- [x] 05-02-PLAN.md
- [x] 05-03-PLAN.md

**Wave 1**

- [x] 05-01: Create personal public fork of end-4/dots-hyprland (gh; dual remotes in 05-02)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 05-02: Add `vendor/dots-hyprland` submodule + recursive init + dual remotes

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 05-03: Verify pin and nested submodules; path-scoped parent pin commit

### Phase 6: Thin Setup Wrapper & Safe Defaults

**Goal:** Provide a `.dotfiles`-native entrypoint that drives upstream setup without destroying personal Hyprland config  
**Depends on:** Phase 5  
**Requirements:** WRAP-01, WRAP-02, WRAP-03, WRAP-04  
**Success Criteria** (what must be TRUE):

  1. From REPO_ROOT, operator can invoke the wrapper for install / install-deps / install-setups / install-files and see it call `vendor/dots-hyprland/./setup` (not a reimplemented package list)
  2. Default invocation includes safe dual-run flags equivalent to `--core --skip-hyprland` (personal `hyprland.conf` not renamed by defaults)
  3. Wrapper prints or enforces a backup reminder/gate before files step and does not default to `--skip-backup`
  4. Extra flags passed to the wrapper reach `./setup` unchanged

**Plans:** 3/3 plans executed

Plans:

- [x] 06-01-PLAN.md
- [x] 06-02-PLAN.md
- [x] 06-03-PLAN.md

- [x] 06-01: Implement `arch/dots-hyprland.sh` (REPO_ROOT, subcommands, passthrough)
- [x] 06-02: Encode safe default flag profile + backup messaging
- [x] 06-03: Smoke-test wrapper help/dry paths against submodule `./setup -h`

### Phase 7: Install, Session Hooks & Dual-Run Verify

**Goal:** Land a running illogical-impulse shell beside Waybar using personal session ownership  
**Depends on:** Phase 6  
**Requirements:** LIVE-01, LIVE-02, LIVE-03, LIVE-04  
**Success Criteria** (what must be TRUE):

  1. After files install, `~/.config/quickshell` is a real directory tree from upstream (not a symlink into `.dotfiles/.config/quickshell`)
  2. Personal Hyprland config sets `ILLOGICAL_IMPULSE_VIRTUAL_ENV` and starts `qs -c ii` on session start
  3. Waybar (and existing notification/launcher session pieces as currently configured) still start — dual-run intact
  4. Operator observes the installed ii/Quickshell chrome running in the Hyprland session

**Plans:** 3/3 plans complete

Plans:
**Wave 1**

- [x] 07-01-PLAN.md — Pre-install: stop qs, unlink live QS symlink, leave path absent

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 07-02-PLAN.md — Dry-run then live one-shot wrapper install; LIVE-01 real tree

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 07-03-PLAN.md — Personal hypr env + qs -c ii hooks; dual-run LIVE-02..04 verify

### Phase 8: Retire Local Quickshell Product

**Goal:** Single product path — remove the v0.1 in-repo Quickshell tree and old installer  
**Depends on:** Phase 7 (LIVE-04 must hold)  
**Requirements:** RET-01, RET-02  
**Success Criteria** (what must be TRUE):

  1. `.dotfiles` no longer ships the v0.1 `.config/quickshell` product tree as an installable source
  2. `arch/quickshell.sh` is gone or is only a deprecation stub pointing at the new wrapper (cannot install the old product path)
  3. Live session still runs ii from the installed `~/.config/quickshell` after retirement (no regression to symlink-at-repo)

**Plans:** TBD

Plans:
**Wave 1**

- [ ] 08-01: Confirm LIVE-04 checklist green on machine

**Wave 2** *(blocked on Wave 1 completion)*

- [ ] 08-02: Delete in-repo `.config/quickshell` product tree

**Wave 3** *(blocked on Wave 2 completion)*

- [ ] 08-03: Retire `arch/quickshell.sh`; grep for stale references

### Phase 9: Workflow Documentation & Update Contract

**Goal:** Operator can reinstall and update without tribal knowledge  
**Depends on:** Phases 5–8 (docs can draft earlier; complete after retirement paths exist)  
**Requirements:** DOC-01, DOC-02  
**Success Criteria** (what must be TRUE):

  1. Docs describe clone → recursive submodule init → wrapper install → hypr hooks → dual-run expectations end-to-end
  2. Docs describe pin-bump update (fetch upstream on fork/submodule, bump parent SHA, re-run setup) and explicitly mark `exp-merge` / online cache install as non-primary
  3. A new machine (or clean read of docs) has enough information to reach a dual-run ii session without reading chat history

**Plans:** TBD

Plans:

- [ ] 09-01: Write install/adopt section (aligned with `arch/*.sh` style)
- [ ] 09-02: Write update/pin-bump + non-goals (exp-merge, cutover, customs)
- [ ] 09-03: Cross-link PROJECT/REQUIREMENTS and retire any quickshell-only install docs

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Shell Foundation & Theme | v0.1 | 4/4 | Complete | 2026-07-21 |
| 2. Core Bar Modules | v0.1 | 13/13 | Complete | 2026-07-23 |
| 3. System & Audio Modules | v0.1 | 10/10 | Complete | 2026-07-24 |
| 4. IPC, Keybinds & Integration | v0.1 | 4/4 | Complete | 2026-07-25 |
| 5. Fork & Submodule Pin | v0.2 | 3/3 | Complete    | 2026-07-25 |
| 6. Thin Setup Wrapper & Safe Defaults | v0.2 | 3/3 | Complete | 2026-07-26 |
| 7. Install, Session Hooks & Dual-Run Verify | v0.2 | 3/3 | Complete    | 2026-07-27 |
| 8. Retire Local Quickshell Product | v0.2 | 0/TBD | Not started | - |
| 9. Workflow Documentation & Update Contract | v0.2 | 0/TBD | Not started | - |

**Coverage:** 15/15 v0.2 requirements mapped · LIVE-01..04 complete · RET/DOC remaining

---
*Last updated: 2026-07-27 — Phase 7 Install, Session Hooks & Dual-Run Verify complete*
