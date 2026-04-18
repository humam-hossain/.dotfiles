---
phase: 06-runtime-failure-inventory
plan: 01
subsystem: validation
tags: [audit, failures, inventory, runtime]
dependency_graph:
  requires: []
  provides: [BUG-01, BUG-02, BUG-03]
  affects: []
tech_stack:
  added: [bash, jq]
  patterns: [wrapper-script, multi-source-audit, deduplication]
key_files:
  created:
    - scripts/nvim-audit-failures.sh
    - .planning/phases/06-runtime-failure-inventory/FAILURES.md
  modified: []
decisions:
  - "Script calls nvim-validate.sh internally to reuse validation checks"
  - "TODO/FIXME entries carry provenance=todo for filtering by later phases"
  - "neo-tree plugin failure detected via health check (loaded=false)"
---

# Phase 06 Plan 01: Runtime Failure Inventory Summary

**Created:** Failure audit script and unified inventory

## Metrics

- Duration: ~3 minutes (script execution)
- Tasks: 1 (auto)
- Files: 2 created
- Bug entries: 24 discovered

## Verified Must-Haves

- [x] Script runs nvim-validate.sh internally
- [x] Script scans TODO/FIXME patterns in Lua files  
- [x] Script scans git log for bug/fix/error/crash commits
- [x] FAILURES.md generated with unified inventory entries

## Failures Discovered

| ID | Description | Owner | Provenance |
|----|-------------|-------|------------|
| BUG-001 | neo-tree plugin failed to load | plugin | health |
| BUG-002 | LSP client setup TODO | plugins/lsp.lua | todo |
| BUG-003 | UI enhancements TODO | plugins/snacks | todo |
| ... | 21 more TODO entries | various | todo |

## Key Findings

1. **neo-tree plugin failure (BUG-001):** Module not found; needs installation or lazy loading fix
2. **23 TODO entries:** Placeholder comments for unimplemented features — these are Not Bugs but planned features
3. **Git scan found no bug-related commits:** History is clean of explicit bug-fix commits
4. **All tools available:** health check shows all 14 tools present

## Deviations

None - executed as planned. Script handled partial validation failures gracefully.

## Auth Gates

None - all checks run without authentication requirements.

## Known Stubs

The TODO entries in FAILURES.md are intentionally left as placeholders; they're feature declarations, not bugs. Later phases (7-9) determine which to implement.

## Threat Flags

None - this is a read-only audit phase.