# Requirements: Cross-Platform Neovim Dotfiles

**Defined:** 2026-04-17
**Core Value:** One shared Neovim config gives a clean, modern, bug-resistant editing experience across Linux and Windows without the setup fighting the user.

## v1 Requirements

### Runtime Stability

- [x] **BUG-01**: User can invoke every documented shared keymap in milestone scope without Lua or runtime errors
- [x] **BUG-02**: User can use core plugin workflows for search, explorer, git, LSP, and UI without config-caused runtime errors
  ✓ v1.1 Phase 8 — validated via nvim-validate.sh all PASS + 08-VERIFICATION.md
- [x] **BUG-03**: User can complete common editing sessions without crashes caused by Neovim config code
  ✓ v1.1 Phase 8 — validated via nvim-validate.sh all PASS + 08-VERIFICATION.md

### Health Quality

- [x] **HEAL-01**: User can run `:checkhealth` without config-caused `ERROR:` entries
  ✓ v1.1 Phase 9 — validated via nvim-validate.sh all PASS + 09-VERIFICATION.md
- [x] **HEAL-02**: User can distinguish fix-now health findings from optional environment/tooling warnings
  ✓ v1.1 Phase 9 — validated via nvim-validate.sh all PASS + 09-VERIFICATION.md

### Validation Coverage

- [x] **TEST-01**: Maintainer can run repo validation commands to verify startup, plugin load, and health status before rollout
- [x] **TEST-02**: Maintainer can reproduce and validate bug-prone keymap or plugin flows with scripts when `:checkhealth` is insufficient
- [x] **TEST-03**: Maintainer can inspect validation artifacts that clearly separate config regressions from external dependency gaps

## v2 Requirements

### Automation

- **AUTO-01**: Maintainer can run milestone validation automatically across Linux and Windows environments
- **AUTO-02**: Maintainer can run plugin regression matrix checks against pinned and updated lockfile states

### Profiles

- **PROF-01**: User can enable machine-role-specific plugin bundles without forking the base config

## Out of Scope

| Feature | Reason |
|---------|--------|
| New editing features unrelated to bug fixing | v1.1 is stabilization-first |
| Broad plugin replacement wave | Replace only when root cause proves current plugin not worth fixing |
| Hiding optional tool warnings entirely | Better to classify and document than suppress useful signal |
| Full CI pipeline | Deferred until local validation surface is strong and stable |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| BUG-01 | Phase 7 | Complete |
| BUG-02 | Phase 8 | Complete |
| BUG-03 | Phase 8 | Complete |
| HEAL-01 | Phase 9 | Complete |
| HEAL-02 | Phase 9 | Complete |
| TEST-01 | Phase 10 | Complete |
| TEST-02 | Phase 10 | Complete |
| TEST-03 | Phase 10 | Complete |

**Coverage:**
- v1 requirements: 8 total
- Mapped to phases: 8
- Unmapped: 0 ✓

---
*Requirements defined: 2026-04-17*
*Last updated: 2026-04-17 after milestone v1.1 definition*
