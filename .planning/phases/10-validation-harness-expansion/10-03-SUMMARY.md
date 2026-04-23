---
phase: 10-validation-harness-expansion
plan: "03"
subsystem: docs
tags: [neovim, readme, validation, triage, interpretation]

# Dependency graph
requires:
  - phase: 10-validation-harness-expansion/10-01
    provides: Phase 3 harness contract with keymaps/formats subcommand rows and artifact list
  - phase: 10-validation-harness-expansion/10-02
    provides: keymaps and formats subcommands writing keymap-regression.log and format-regression.log
  - phase: 09-health-signal-cleanup
    provides: Phase 9 classification taxonomy (config regression / environment gap / optional tool gap)

provides:
  - README.md `### Reading validation output` section with artifact-by-artifact interpretation table
  - Triage decision path reusing Phase 9 taxonomy without creating a second TRIAGE.md surface

affects: [maintainer-rollout-workflow, post-deploy-verification-docs]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Artifact interpretation: each .planning/tmp/nvim-validate/ file maps to its producing subcommand and one first-response rule"
    - "Triage taxonomy reuse: config regression / environment gap / optional tool gap from Phase 9 — no new categories"

key-files:
  created: []
  modified:
    - .config/nvim/README.md (### Reading validation output section added after Report Output list)

key-decisions:
  - "Triage guidance kept in README adjacent to harness docs per D-12 — no separate TRIAGE.md"
  - "Phase 9 classification reused verbatim: config regression → fix repo code; environment gap → document/install; optional tool gap → By Design/Won't Fix"
  - "keymap-regression.log and format-regression.log explicitly traced to keymaps/lazy.lua and plugins/conform.lua so maintainers know where to look on failure"

patterns-established: []

requirements-completed:
  - TEST-03

# Self-Check
self-check: PASSED

# Verification
verification:
  - "rg -n '### Reading validation output' .config/nvim/README.md — PASS"
  - "rg -n 'startup.log|sync.log|smoke.log|health.json|checkhealth.txt|keymap-regression.log|format-regression.log' .config/nvim/README.md — PASS (all 7 artifacts present)"
  - "rg -n 'config regression|environment gap|optional tool gap' .config/nvim/README.md — PASS"
  - "rg -n 'TRIAGE.md' .config/nvim/README.md — PASS (explicitly says do not create TRIAGE.md)"
  - "rg -n ':checkhealth config' .config/nvim/README.md — PASS"

# Metrics
duration: inline (rate-limit fallback from subagent)
completed: 2026-04-23
---

## Summary

Added `### Reading validation output` section to `.config/nvim/README.md` after the Report Output list. The section provides:

1. **Artifact interpretation table** — maps all 7 `.planning/tmp/nvim-validate/` output files to their producing subcommand and a concrete first-response rule when that artifact fails. `keymap-regression.log` and `format-regression.log` are explicitly traced to `keymaps/lazy.lua` and `plugins/conform.lua` respectively so maintainers know where to investigate on Phase 7/10 regression failures.

2. **Triage decision path** — reuses Phase 9 classification taxonomy without inventing new labels. Three categories with concrete actions: config regression → fix repo code; environment gap → document or install on target machine; optional tool gap → mark By Design/Won't Fix. Explicitly states do not create `TRIAGE.md` — guidance lives in README per D-12.
