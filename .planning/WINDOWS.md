---
schema_version: 1
open_count: 3
waived_count: 0
fixed_count: 0
total_count: 3
last_updated: 2026-09-07T12:59:13.113Z
---

# Broken Windows Ledger

> Cross-phase defect register. With `workflow.windows_enforce` enabled, `/gsd-ship` blocks while `open_count > 0`.
> Waive with `gsd-tools windows waive <id> "<reason>"` (reason required).
> Mark fixed with `gsd-tools windows fixed <id>`.

| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |
|----|-------|------|------|------|-------------|--------|--------|-------------|-------------|
| 1 | 15 | deviation | docs/dots-hyprland-workflow.md | 401 | Playbook section 8 cites 15-DOC-SWEEP.md as carrying the D-38 restoration work as a deferred item; that section of the sweep record is still a 15-06 placeholder | open |  | 2026-09-06T06:28:36.362Z |  |
| 2 | 16 | deviation | scripts/phase12-full-smoke.sh |  | Expected-red from 16-01: asserts the retired safe-profile behavior; rewritten in plan 16-02 (D-34) | open |  | 2026-09-07T12:59:12.993Z |  |
| 3 | 16 | deviation | scripts/phase13-d19-assert.sh |  | Expected-red from 16-01: hard-fails on any arch/dots-hyprland.sh diff from its pinned base; re-pinned in plan 16-06 (D-38) | open |  | 2026-09-07T12:59:13.113Z |  |

````json
[
  {
    "id": 1,
    "kind": "deviation",
    "phase": "15",
    "file": "docs/dots-hyprland-workflow.md",
    "line": 401,
    "description": "Playbook section 8 cites 15-DOC-SWEEP.md as carrying the D-38 restoration work as a deferred item; that section of the sweep record is still a 15-06 placeholder",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-06T06:28:36.362Z",
    "resolved_at": null
  },
  {
    "id": 2,
    "kind": "deviation",
    "phase": "16",
    "file": "scripts/phase12-full-smoke.sh",
    "line": null,
    "description": "Expected-red from 16-01: asserts the retired safe-profile behavior; rewritten in plan 16-02 (D-34)",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-07T12:59:12.993Z",
    "resolved_at": null
  },
  {
    "id": 3,
    "kind": "deviation",
    "phase": "16",
    "file": "scripts/phase13-d19-assert.sh",
    "line": null,
    "description": "Expected-red from 16-01: hard-fails on any arch/dots-hyprland.sh diff from its pinned base; re-pinned in plan 16-06 (D-38)",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-07T12:59:13.113Z",
    "resolved_at": null
  }
]
````
