# Phase 6: Runtime Failure Inventory and Reproduction - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-18
**Phase:** 06-runtime-failure-inventory
**Areas discussed:** Fix scope, Inventory location, Script deliverable, Script behavior, Inventory filename, Ranking/tiers, User report sources, Script output, Health capture, Table columns (simplified), Won't fix in checklist, Checklist format, Audit execution timing, Environment column, TODO scanning, Script interface, Deduplication, Git scanning, Failure ID format, Manual confirmation, FAILURES.md updates (living doc), Audit baseline

---

## Fix Scope (D-19/D-20)

| Option | Description | Selected |
|--------|-------------|----------|
| Catalog only | Phase 6 audits, documents — no fixes. Phases 7-9 apply fixes. | ✓ |
| Fix simple issues inline | Fix trivially fixable things during audit, defer complex. | |
| Fix everything found | Phase 6 catalogs AND fixes all issues. | |

**User's choice:** Catalog only
**Notes:** Prior context (D-19/D-20) said "fix everything in Phase 6" — contradicted the roadmap structure. Removed those decisions.

---

## Inventory Location (D-29)

| Option | Description | Selected |
|--------|-------------|----------|
| .planning/phases/06-runtime-failure-inventory/ | Lives with the phase that produces it. | ✓ |
| scripts/ | Alongside nvim-validate.sh. | |
| .planning/tmp/nvim-validate/ | Alongside other validation outputs. | |

**User's choice:** `.planning/phases/06-runtime-failure-inventory/`

---

## Script Path (D-17)

| Option | Description | Selected |
|--------|-------------|----------|
| scripts/nvim-audit-failures.sh | Alongside nvim-validate.sh, consistent naming. | ✓ |
| Agent discretion | Let planner pick name and location. | |

**User's choice:** `scripts/nvim-audit-failures.sh`

---

## Inventory Format (D-13)

| Option | Description | Selected |
|--------|-------------|----------|
| Markdown | Human-readable, agent-friendly, version-control friendly. | ✓ |
| JSON | Machine-parseable, harder for agents to read inline. | |
| Both | Markdown primary, JSON secondary. | |

**User's choice:** Markdown

---

## Script Behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Calls nvim-validate.sh internally | Wraps existing checks, reuses logic. | ✓ |
| Standalone headless calls | Independent nvim calls, duplicates logic. | |
| Agent discretion | | |

**User's choice:** Calls nvim-validate.sh internally

---

## Inventory Filename

| Option | Description | Selected |
|--------|-------------|----------|
| FAILURES.md | Clear purpose-named file. | ✓ |
| 06-INVENTORY.md | GSD padded-phase naming convention. | |
| Agent discretion | | |

**User's choice:** `FAILURES.md`

---

## Ranking / Priority Tiers

| Option | Description | Selected |
|--------|-------------|----------|
| Remove all ranking | No tiers, no severity, no frequency — flat equal list. | ✓ |
| P0/P1/P2 tiers | Priority tiers for downstream phases. | |
| Numeric score | Weighted score per entry. | |

**User's choice:** Remove all ranking — "just focus on finding bugs and fixing it, everything is equal"
**Notes:** D-09, D-10, D-11, D-12 removed. Frequency column removed. Severity column removed. Impact column removed.

---

## User Report Sources (D-01)

| Option | Description | Selected |
|--------|-------------|----------|
| Git history + TODO comments | Grep git log + TODO/FIXME in Lua files. | ✓ |
| Developer notes only | Manual observation during audit. | |
| Agent discretion | | |

**User's choice:** Git history + TODO comments (both auto-scanned by script)

---

## Script Output

| Option | Description | Selected |
|--------|-------------|----------|
| Produces FAILURES.md directly | Script writes complete inventory in one run. | ✓ |
| Raw data only | Script writes raw output; human assembles FAILURES.md. | |
| Agent discretion | | |

**User's choice:** Produces FAILURES.md directly

---

## Health Capture

| Option | Description | Selected |
|--------|-------------|----------|
| Via nvim-validate.sh health | Calls existing health subcommand, parses health.json. | ✓ |
| New headless health capture | Separate nvim --headless call. | |
| Manual run + pipe | Developer runs :checkhealth manually. | |

**User's choice:** Via existing nvim-validate.sh health

---

## FAILURES.md Table Columns

| Option | Description | Selected |
|--------|-------------|----------|
| ID, description, owner, status, repro steps, provenance | Clean minimal set. | ✓ |
| ID, description, owner, status only | Minimal; repro/provenance as free text. | |
| Agent discretion | | |

**User's choice:** `ID, Description, Owner, Status, Repro Steps, Provenance, Environment`
**Notes:** Frequency, severity, impact, priority all removed per "keep it simple" direction.

---

## Won't Fix in CHECKLIST.md

| Option | Description | Selected |
|--------|-------------|----------|
| No — confirmed only | CHECKLIST.md = Confirmed entries only. | |
| Yes — include with note | Include Won't Fix / By Design with a note block. | ✓ |

**User's choice:** Include with note

---

## Checklist Format

| Option | Description | Selected |
|--------|-------------|----------|
| ID + steps + expected outcome | Links to FAILURES.md by ID, numbered steps, correct behavior. | ✓ |
| Steps only | Just numbered repro steps. | |
| Agent discretion | | |

**User's choice:** ID + numbered steps + expected outcome

---

## Audit Execution Timing

| Option | Description | Selected |
|--------|-------------|----------|
| Run during Phase 6 execution | Executor agent runs script as part of phase. | ✓ |
| Developer runs manually first | Developer runs it, commits output, then planner works from artifact. | |
| Agent discretion | | |

**User's choice:** Run during Phase 6 execution

---

## Environment Column

| Option | Description | Selected |
|--------|-------------|----------|
| Remove environment column | Arch Linux only — constant. | |
| Keep environment column | Future-proof for cross-platform resume. | ✓ |

**User's choice:** Keep environment column

---

## TODO Scanning

| Option | Description | Selected |
|--------|-------------|----------|
| Auto-scan TODO/FIXME | Script greps .config/nvim/**/*.lua. | ✓ |
| Manual only | Developer reviews TODOs manually. | |
| Agent discretion | | |

**User's choice:** Auto-scan TODO/FIXME

---

## Script Interface

| Option | Description | Selected |
|--------|-------------|----------|
| Single operation | Just run it — no subcommands. | ✓ |
| Subcommands | Like nvim-validate.sh with subcommands. | |
| Agent discretion | | |

**User's choice:** Single operation

---

## Deduplication

| Option | Description | Selected |
|--------|-------------|----------|
| One entry, provenance lists all sources | Single row per unique failure. | ✓ |
| Separate entries, linked by note | One entry per source with duplicate reference. | |
| Agent discretion | | |

**User's choice:** One entry, provenance lists all sources

---

## Git Scanning

| Option | Description | Selected |
|--------|-------------|----------|
| Auto-scan git log | Script greps git log for bug/fix/error/crash keywords. | ✓ |
| Manual only | Developer reads git log and manually adds entries. | |
| Agent discretion | | |

**User's choice:** Auto-scan git log

---

## Failure ID Format

| Option | Description | Selected |
|--------|-------------|----------|
| BUG-NNN (e.g. BUG-001) | Consistent with REQUIREMENTS.md naming. | ✓ |
| F-NNN (e.g. F-001) | Shorter, separate namespace. | |
| Agent discretion | | |

**User's choice:** `BUG-NNN`

---

## Manual Confirmation

| Option | Description | Selected |
|--------|-------------|----------|
| Developer verifies manually after script | Developer reviews Discovered entries, promotes to Confirmed. | ✓ |
| Agent does both | Executor agent handles full confirmation via headless calls. | |

**User's choice:** Developer verifies manually after script

---

## FAILURES.md as Living Document

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — living document | Phases 7-9 update status as fixes land. | ✓ |
| Frozen after Phase 6 | Snapshot only; downstream phases track separately. | |

**User's choice:** Living document

---

## Audit Baseline

| Option | Description | Selected |
|--------|-------------|----------|
| Working tree | Audit current actual state including uncommitted changes. | ✓ |
| HEAD commit only | Stash changes, clean baseline. | |

**User's choice:** Working tree

---

## Claude's Discretion

- Exact git log grep patterns for failure detection
- Exact health.json parsing logic
- Exact deduplication heuristics when same failure appears across multiple sources
- Priority threshold definition if tiers are ever added in later phases
- Script exit codes and error handling

## Deferred Ideas

None.
