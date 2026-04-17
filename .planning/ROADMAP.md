# Roadmap: Cross-Platform Neovim Dotfiles

## Milestones

- ✅ **v1.0 Neovim Modernization** — Phases 1-5 (shipped 2026-04-15)
- 🔄 **v1.0 Gap Closure** — Phases 6-11 (in progress)

## Phases

<details>
<summary>✅ v1.0 Neovim Modernization (Phases 1-5) — SHIPPED 2026-04-15</summary>

- [x] Phase 1: Reliability and Portability Baseline (3/3 plans) — completed 2026-04-15
- [x] Phase 2: Central Command and Keymap Architecture (3/3 plans) — completed 2026-04-15
- [x] Phase 3: Plugin Audit and Validation Harness (3/3 plans) — completed 2026-04-15
- [x] Phase 4: Tooling and Ecosystem Modernization (3/3 plans) — completed 2026-04-15
- [x] Phase 5: UX and Performance Polish (3/3 plans) — completed 2026-04-15

Full archive: `.planning/milestones/v1.0-ROADMAP.md`

</details>

### Phase 6: Add Missing VERIFICATION.md Files
**Goal:** Create VERIFICATION.md for phases 1, 2, 4, 5 to satisfy Nyquist compliance
**Requirements:** KEY-01, KEY-02, KEY-03, PLUG-02, TOOL-02
**Gap Closure:** Closes tech debt gaps from audit — 4 phases missing verification

### Phase 7: Validate Keymap Requirements
**Goal:** Verify KEY-01, KEY-02, KEY-03 are satisfied through existing plans
**Requirements:** KEY-01, KEY-02, KEY-03
**Gap Closure:** Closes partial requirement status for Phase 2 keymaps

### Phase 8: Validate UX Requirements
**Goal:** Verify UX-01, UX-02 are satisfied through existing Phase 5 work
**Requirements:** UX-01, UX-02
**Gap Closure:** Closes unsatisfied requirement status for Phase 5 UX

### Phase 9: Fix Keymap Registry Integration
**Goal:** Wire the keymap registry to which-key and fix neo-tree lazy-load triggers so all three keymap requirements are actually satisfied at runtime
**Requirements:** KEY-01, KEY-02, KEY-03, TOOL-02
**Gap Closure:** Closes critical integration gaps — whichkey.register() never called, neo-tree domain-mismatched keys trigger snacks load, plugin_local scope mismatch

### Phase 10: Resolve noice.nvim / UX-01
**Goal:** Either remove noice from misc.lua entirely or update UX-01 requirement wording to reflect intentional partial retention
**Requirements:** UX-01
**Gap Closure:** Closes UX-01 partial — noice still active despite "snacks replacing noice" claim

### Phase 11: Nyquist Compliance and Tech Debt
**Goal:** Add missing VERIFICATION.md / VALIDATION.md files and fix SUMMARY.md frontmatter so phases 6-8 are Nyquist-compliant
**Requirements:** —
**Gap Closure:** Closes documentation gaps — Phase 06 missing VERIFICATION.md, Phase 07 missing VALIDATION.md, Phase 08 SUMMARY missing requirements-completed field

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Reliability and Portability Baseline | v1.0 | 3/3 | ✅ Complete | 2026-04-15 |
| 2. Central Command and Keymap Architecture | v1.0 | 3/3 | ✅ Complete | 2026-04-15 |
| 3. Plugin Audit and Validation Harness | v1.0 | 3/3 | ✅ Complete | 2026-04-15 |
| 4. Tooling and Ecosystem Modernization | v1.0 | 3/3 | ✅ Complete | 2026-04-15 |
| 5. UX and Performance Polish | v1.0 | 3/3 | ✅ Complete | 2026-04-15 |
| 6. Add Missing VERIFICATION.md Files | v1.0 Gap Closure | 1/5 | 🔄 In Progress | — |
| 7. Validate Keymap Requirements | v1.0 Gap Closure | 3/3 | Complete    | 2026-04-16 |
| 8. Validate UX Requirements | v1.0 Gap Closure | 1/1 | Complete   | 2026-04-16 |
| 9. Fix Keymap Registry Integration | v1.0 Gap Closure | 2/2 | Ready to execute | — |
| 10. Resolve noice.nvim / UX-01 | v1.0 Gap Closure | 0/0 | Complete    | 2026-04-17 |
| 11. Nyquist Compliance and Tech Debt | v1.0 Gap Closure | 0/1 | Pending | — |
