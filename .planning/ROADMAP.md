# Roadmap: Cross-Platform Neovim Dotfiles

## Overview

This roadmap turns the current Neovim config into a stable, cross-platform, maintainable system in five phases. The order is deliberate: fix lifecycle and portability issues first, centralize control over behavior next, create a safe validation harness before aggressive plugin churn, then modernize tooling and finish with polish and performance work.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Reliability and Portability Baseline** - Fix save/quit behavior and remove OS-specific runtime assumptions
- [ ] **Phase 2: Central Command and Keymap Architecture** - Centralize custom mappings and normalize editing commands
- [ ] **Phase 3: Plugin Audit and Validation Harness** - Audit plugin set and add repeatable safety checks
- [ ] **Phase 4: Tooling and Ecosystem Modernization** - Update LSP, formatting, and plugin integrations to current standards
- [ ] **Phase 5: UX and Performance Polish** - Refine startup cost, UI coherence, and rollout documentation

## Phase Details

### Phase 1: Reliability and Portability Baseline
**Goal**: Make the config safe to use on all target OSes and eliminate the current buffer/save/quit failure modes.
**Depends on**: Nothing (first phase)
**Requirements**: [PLAT-01, PLAT-02, PLAT-03, PLAT-04, CORE-01, CORE-02, CORE-03]
**Success Criteria** (what must be TRUE):
  1. User can save and close a buffer/window without Neovim unexpectedly exiting the entire session.
  2. User can start the config on Arch Linux, Debian/Ubuntu, and Windows without platform-specific runtime failures.
  3. User-facing open/path/shell actions no longer depend on hardcoded Linux-only commands.
  4. Buffer, window, tab, and autosave behavior is defined clearly enough to validate.
**Plans**: 3 plans

Plans:
- [x] 01-01-PLAN.md — Audit and replace platform-specific runtime commands with guarded helpers
- [x] 01-02-PLAN.md — Fix buffer/window/tab/save/quit lifecycle behavior and simplify autosave interactions
- [x] 01-03-PLAN.md — Add baseline portability verification notes and smoke scenarios for supported OSes

### Phase 2: Central Command and Keymap Architecture
**Goal**: Move all custom mappings under one maintainable control plane.
**Depends on**: Phase 1
**Requirements**: [KEY-01, KEY-02, KEY-03]
**Success Criteria** (what must be TRUE):
  1. User can inspect one central file or registry to find every custom mapping.
  2. Keymaps are grouped coherently by domain with descriptive labels and predictable prefixes.
  3. Hidden duplicate custom mappings are removed from plugin files or intentionally delegated through the central registry.
**Plans**: 3 plans

Plans:
- [x] 02-01: Design command taxonomy and central keymap registry structure
- [x] 02-02: Migrate scattered mappings into the central registry without breaking workflows
- [x] 02-03: Document keymap organization and remove stale/duplicate mapping definitions

### Phase 3: Plugin Audit and Validation Harness
**Goal**: Create a safe foundation for aggressive cleanup by auditing plugins and adding regression checks.
**Depends on**: Phase 2
**Requirements**: [PLUG-01, PLUG-03, TOOL-01, TOOL-03]
**Success Criteria** (what must be TRUE):
  1. Maintainer has an explicit keep/remove/replace decision for every current plugin.
  2. User can run documented headless smoke checks for startup, sync, and health verification.
  3. Missing external tools fail gracefully or surface actionable health guidance.
  4. Lockfile reflects the audited plugin set rather than historical drift.
**Plans**: 3 plans

Plans:
- [ ] 03-01-PLAN.md — Build plugin inventory ledger with keep/remove/replace decisions and aggressive audit rules
- [ ] 03-02-PLAN.md — Build repo-owned headless validation harness (scripts/nvim-validate.sh + core.health.snapshot)
- [ ] 03-03-PLAN.md — Apply audit decisions: refresh lazy-lock.json, fix drift items, harden missing-tool behavior

### Phase 4: Tooling and Ecosystem Modernization
**Goal**: Bring LSP, formatting, completion, and major integrations up to current Neovim ecosystem standards.
**Depends on**: Phase 3
**Requirements**: [PLUG-02, TOOL-02]
**Success Criteria** (what must be TRUE):
  1. User can use LSP, completion, formatting, tree/search, and git workflows after modernization without major regressions.
  2. Chosen plugin/tooling stack matches a documented modern baseline for the Neovim ecosystem.
  3. Outdated configuration patterns are replaced with cleaner, supported equivalents where justified.
**Plans**: 3 plans

Plans:
- [ ] 04-01: Modernize LSP and Mason architecture around chosen Neovim baseline
- [ ] 04-02: Update formatting, completion, search, tree, and git integrations to audited standards
- [ ] 04-03: Replace weak or outdated plugins/settings and normalize plugin spec patterns

### Phase 5: UX and Performance Polish
**Goal**: Finish with coherent UI behavior, better startup efficiency, and clear rollout guidance.
**Depends on**: Phase 4
**Requirements**: [UX-01, UX-02]
**Success Criteria** (what must be TRUE):
  1. User gets a coherent final UI across statusline, notifications, file tree, completion, and theme behavior.
  2. Startup/profile review removes obvious plugin waste and documents meaningful performance wins.
  3. Rollout/update guidance is clear enough to apply changes to real machines after the refactor.
**Plans**: 3 plans

Plans:
- [ ] 05-01: Profile startup and eliminate obvious plugin waste
- [ ] 05-02: Polish UI/UX interactions after architecture and tooling stabilize
- [ ] 05-03: Document rollout/update workflow, including machine update notes and verification steps

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Reliability and Portability Baseline | 0/3 | Not started | - |
| 2. Central Command and Keymap Architecture | 0/3 | Not started | - |
| 3. Plugin Audit and Validation Harness | 0/3 | Not started | - |
| 4. Tooling and Ecosystem Modernization | 0/3 | Not started | - |
| 5. UX and Performance Polish | 0/3 | Not started | - |
