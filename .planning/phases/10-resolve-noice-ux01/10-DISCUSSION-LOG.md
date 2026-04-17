# Phase 10: Resolve noice.nvim / UX-01 - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-17
**Phase:** 10-resolve-noice-ux01
**Areas discussed:** UX-01 wording, Remove vs. keep noice

---

## UX-01 Wording

| Option | Description | Selected |
|--------|-------------|----------|
| Intentional styling choice | Keep noice permanently for cmdline popup | |
| Oversight | noice stayed by accident, revisit | |
| Remove noice entirely | Full removal makes UX-01 accurate as-is | ✓ |

**User's choice:** Remove noice entirely — UX-01 wording doesn't need updating
**Notes:** User confirmed full removal is the intent; native cmdline is acceptable

---

## Remove vs. Keep noice

| Option | Description | Selected |
|--------|-------------|----------|
| Remove noice entry only | Leave dep cleanup to lazy.nvim | |
| Planner audits deps | Safe removal, check before deleting nui.nvim | |
| Remove noice entirely | Including nui.nvim (confirmed no other users) | ✓ |

**User's choice:** Remove noice entirely — confirmed when asked about nui.nvim dep
**Notes:** grep confirmed nui.nvim not referenced anywhere else; plenary.nvim stays (todo-comments)

---

## Deferred Ideas

None.
