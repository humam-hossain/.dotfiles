# Phase 6: Runtime Failure Inventory and Reproduction - Context

**Gathered:** 2026-04-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Turn known Neovim setup failures into a flat inventory with reliable repro steps and ownership labels. This phase audits runtime failures from keymaps, plugins, crashes, and `:checkhealth`, then creates a reproducible validation checklist for confirmed failures. Phase 6 is catalog-only — no fixes. Fixes belong in Phases 7-9. Scope is limited to Arch Linux (current testing platform only).
</domain>

<decisions>
## Implementation Decisions

### Failure Sources
- **D-01:** Three sources fed into the audit: (1) automated validation via `nvim-validate.sh`, (2) `:checkhealth` output parsed from `health.json`, (3) TODO/FIXME scan of `.config/nvim/**/*.lua` and git log keyword search for bug/fix/error/crash in commit messages
- **D-02:** Merge all source findings into a single unified inventory — one entry per unique failure, provenance field lists all sources that found it (e.g. "health + smoke + TODO")

### Audit Script
- **D-03:** Create `scripts/nvim-audit-failures.sh` — do NOT extend `nvim-validate.sh`
- **D-04:** Single operation: `./scripts/nvim-audit-failures.sh` — no subcommands. Internally calls `nvim-validate.sh` (reuses its startup/sync/smoke/health checks), then adds TODO/FIXME scan and git log scan on top
- **D-05:** Script writes `FAILURES.md` directly to `.planning/phases/06-runtime-failure-inventory/FAILURES.md`
- **D-06:** Script auto-scans TODO/FIXME patterns in `.config/nvim/**/*.lua` and adds findings as candidate failures with provenance='todo'
- **D-07:** Script auto-scans `git log` for commits with bug/fix/error/crash keywords and adds findings as candidate failures with provenance='git'

### Reproduction Strategy
- **D-08:** Automated script captures what it can; for failures not reproducible by script, step-by-step instructions are written as the repro steps field

### Confirmation Process
- **D-09:** A failure moves from Discovered → Confirmed when BOTH: (1) script or automated check can reproduce it, AND (2) developer manually triggers and verifies it in an interactive Neovim session
- **D-10:** Phase 6 executor agent runs the script producing Discovered entries; developer then does a manual review session to promote entries to Confirmed

### Scope: Catalog Only
- **D-11:** Phase 6 does NOT fix anything. All discovered and confirmed failures stay in the inventory for Phases 7-9 to act on
- **D-12:** FAILURES.md is a living document — Phases 7-9 update status (Confirmed → Fixed → Closed) as fixes land

### Ownership Labels
- **D-13:** Keymap failures → `core/keymaps/` files (registry, apply.lua, lazy.lua, whichkey.lua)
- **D-14:** Plugin failures → plugin config files (lsp, neotree, fzflua, etc.)
- **D-15:** Core config failures → `init.lua`, `core/options.lua`, `core/keymaps.lua`, `core/health.lua`
- **D-16:** External tool failures → missing tools, env setup, OS-specific issues

### Failure Definition
- **D-17:** Inventory errors, crashes, AND warnings — all three worth cataloging
- **D-18:** Don't filter out "normal health noise" at the script level — let the inventory entries carry the full picture

### Inventory Fields
- **D-19:** FAILURES.md table columns: `ID`, `Description`, `Owner`, `Status`, `Repro Steps`, `Provenance`, `Environment`
- **D-20:** ID format: `BUG-NNN` (e.g. `BUG-001`) — consistent with REQUIREMENTS.md naming
- **D-21:** Provenance: source(s) that found it (health / smoke / startup / todo / git), when discovered
- **D-22:** Environment: OS, distro, Neovim version, tool versions (captured once in FAILURES.md header — same for all entries on Arch Linux)
- **D-23:** No ranking, no priority tiers, no severity classification — failures are flat and equal; Phases 7-9 decide fix order

### Status Workflow
- **D-24:** Full workflow: `Discovered` → `Confirmed` → `Fixed` → `Closed`
- **D-25:** Dispositions for non-actionable entries: `Won't Fix`, `By Design`, `Duplicate`, `Out of Scope`

### Deliverables
- **D-26:** Two output files in `.planning/phases/06-runtime-failure-inventory/`:
  - `FAILURES.md` — full flat inventory with all fields per entry
  - `CHECKLIST.md` — repro checklist for Confirmed entries (and Won't Fix / By Design entries with a note); each entry: BUG-ID + numbered repro steps + expected correct outcome

### Cross-Platform
- **D-27:** Arch Linux only — no cross-platform validation in this phase

### Claude's Discretion
- Exact git log grep patterns for failure detection
- Exact health.json parsing logic
- Exact deduplication heuristics when same failure appears across multiple sources
- Priority threshold definition if tiers are ever added in later phases
- Script exit codes and error handling

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` — Phase 6 goal, requirements BUG-01, BUG-02, BUG-03; Phase 7-9 plans that consume this inventory
- `.planning/REQUIREMENTS.md` — v1 bug-fix requirements
- `.planning/PROJECT.md` — v1.1 milestone goals and constraints

### Prior phase context
- `.planning/milestones/v1.0-phases/01-reliability-and-portability-baseline/01-CONTEXT.md` — core patterns for keymaps, buffers, autosave
- `.planning/milestones/v1.0-phases/02-central-command-and-keymap-architecture/02-CONTEXT.md` — keymap registry architecture

### Existing validation
- `scripts/nvim-validate.sh` — existing validation harness that `nvim-audit-failures.sh` wraps internally
- `.config/nvim/lua/core/health.lua` — health snapshot module; `nvim-validate.sh health` writes `health.json` to `.planning/tmp/nvim-validate/`

### Codebase
- `.planning/codebase/STRUCTURE.md` — file locations for keymaps, plugins, core config

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scripts/nvim-validate.sh`: Runs startup, sync, smoke, health checks — `nvim-audit-failures.sh` calls this internally rather than duplicating logic
- `.config/nvim/lua/core/health.lua`: Tool and plugin probing; produces `health.json` that the audit script parses
- `.planning/tmp/nvim-validate/health.json`: Written by `nvim-validate.sh health` — structured plugin/tool probe results

### Established Patterns
- `nvim-validate.sh` uses `set -euo pipefail`, report dir at `.planning/tmp/nvim-validate/`, fail-fast on errors
- Health probes use `pcall(require, name)` pattern — same pattern should be referenced when identifying smoke failures

### Integration Points
- `nvim-audit-failures.sh` calls `nvim-validate.sh` (reuse, don't duplicate)
- Output lands in `.planning/phases/06-runtime-failure-inventory/` alongside this CONTEXT.md
- Phases 7-9 read `FAILURES.md` from that same directory to pick up their work

</code_context>

<specifics>
## Specific Ideas

- `BUG-001`, `BUG-002`, etc. as IDs — matches REQUIREMENTS.md `BUG-01`/`BUG-02`/`BUG-03` namespace
- Status column values: `Discovered`, `Confirmed`, `Fixed`, `Closed`, `Won't Fix`, `By Design`, `Duplicate`, `Out of Scope`
- CHECKLIST.md entry format: `## BUG-NNN — [description]` → numbered repro steps → `Expected outcome:` section
- Won't Fix / By Design entries appear in CHECKLIST.md with a `> Note: Won't Fix — [reason]` block
- Developer manually triggers each Discovered failure during a post-script review session to promote to Confirmed
- Environment captured once in FAILURES.md frontmatter/header: Arch Linux, `nvim --version` output, key tool versions

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 06-runtime-failure-inventory*
*Context gathered: 2026-04-18*
