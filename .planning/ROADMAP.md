# Roadmap: Cross-Platform Neovim Dotfiles

## Milestones

- ✅ **v1.0 Neovim Modernization** — shipped 2026-04-15
- 🚧 **v1.1 Neovim Setup Bug Fixes** — requirements defined 2026-04-17

## Phases

<details>
<summary>✅ v1.0 Neovim Modernization and follow-up closure — completed</summary>

- [x] Phase 1: Reliability and Portability Baseline
- [x] Phase 2: Central Command and Keymap Architecture
- [x] Phase 3: Plugin Audit and Validation Harness
- [x] Phase 4: Tooling and Ecosystem Modernization
- [x] Phase 5: UX and Performance Polish
- [x] Follow-up closure phases 6-12 completed before v1.1 kickoff; history remains in git and prior planning docs

</details>

### Phase 6: Runtime Failure Inventory and Reproduction
**Goal:** Turn reported and known Neovim setup failures into a ranked inventory with reliable repro steps and ownership labels
**Requirements:** BUG-01, BUG-02, BUG-03
**Depends on:** —
**Plans:** 2/2 plans complete (2026-04-18)

Plans:
- [x] 6-01-PLAN.md — Audit current runtime failures from keymaps, plugins, crashes, and `:checkhealth`
- [x] 6-02-PLAN.md — Create reproducible validation checklist for confirmed failures

### Phase 7: Keymap Reliability Fixes
**Goal:** Remove config-caused errors from shared keymaps and ensure registry-driven mappings execute safely
**Requirements:** BUG-01
**Depends on:** Phase 6
**Plans:** 2/2 plans complete

Plans:
- [x] 7-01-PLAN.md — Fix broken or miswired keymaps in registry and attachment helpers
- [x] 7-02-PLAN.md — Verify keymap execution paths and update mapping docs if behavior changed

### Phase 8: Plugin Runtime Hardening
**Goal:** Fix plugin misconfigurations and crash-prone runtime paths across core editing workflows
**Requirements:** BUG-02, BUG-03
**Depends on:** Phase 6
**Plans:** 3/3 plans complete (2026-04-22)

Plans:
- [x] 8-01-PLAN.md — Fix plugin config defects exposed by startup/smoke/runtime usage
- [x] 8-02-PLAN.md — Fix crash-prone editor flows and unsafe runtime assumptions
- [x] 8-03-PLAN.md — Re-verify core plugin workflows for search, explorer, git, LSP, and UI

### Phase 9: Health Signal Cleanup
**Goal:** Make `:checkhealth` trustworthy by fixing config-caused errors and classifying actionable warnings
**Requirements:** HEAL-01, HEAL-02
**Depends on:** Phase 6, Phase 8
**Plans:** 2/2 plans complete (2026-04-23)

Plans:
- [x] 9-01-PLAN.md — Resolve config-caused `:checkhealth` failures and missing guards
- [x] 9-02-PLAN.md — Improve health messaging for optional tools and known environment-only warnings

### Phase 10: Validation Harness Expansion
**Goal:** Extend repo validation only where `:checkhealth` cannot prove correctness for bug-prone flows
**Requirements:** TEST-01, TEST-02, TEST-03
**Depends on:** Phase 6, Phase 7, Phase 8, Phase 9
**Plans:** 4/4 plans complete

Plans:
- [x] 10-01-PLAN.md — Lock the Phase 10 validator contract and clean stale format-on-save TODO noise (completed 2026-04-23)
- [x] 10-02-PLAN.md — Add `keymaps` and `formats` regression subcommands plus Phase 10 manual follow-up checks
- [x] 10-03-PLAN.md — Add README guidance for reading validation artifacts and triaging failures
- [x] 10-04-PLAN.md — Re-audit `checkhealth` warnings, fix repo-owned warning noise, and update warning dispositions

### Phase 11: Milestone Verification and Rollout Confidence
**Goal:** Verify v1.1 bug-fix requirements end-to-end and refresh rollout guidance for stable machine updates
**Requirements:** BUG-01, BUG-02, BUG-03, HEAL-01, HEAL-02, TEST-01, TEST-02, TEST-03
**Depends on:** Phase 7, Phase 8, Phase 9, Phase 10
**Plans:** 1/2 plans executed

Plans:
- [x] 11-01-PLAN.md — Run milestone verification against requirements and regression suite
- [ ] 11-02-PLAN.md — Update README and maintenance workflow for bug-fix milestone outcomes

## Progress

| Phase | Milestone | Plans Complete | Status |
|-------|-----------|----------------|--------|
| 6. Runtime Failure Inventory and Reproduction | v1.1 | 2/2 | ✅ Complete | 2026-04-18 |
| 7. Keymap Reliability Fixes | 2/2 | Complete   | 2026-04-21 |
| 8. Plugin Runtime Hardening | v1.1 | 3/3 | ✅ Complete | 2026-04-22 |
| 9. Health Signal Cleanup | v1.1 | 2/2 | ✅ Complete | 2026-04-23 |
| 10. Validation Harness Expansion | 4/4 | Complete    | 2026-04-23 |
| 11. Milestone Verification and Rollout Confidence | 1/2 | In Progress|  |
