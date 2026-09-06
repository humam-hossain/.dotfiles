---
schema_version: 1
open_count: 1
waived_count: 0
fixed_count: 0
total_count: 1
last_updated: 2026-09-06T06:28:36.362Z
---

# Broken Windows Ledger

> Cross-phase defect register. With `workflow.windows_enforce` enabled, `/gsd-ship` blocks while `open_count > 0`.
> Waive with `gsd-tools windows waive <id> "<reason>"` (reason required).
> Mark fixed with `gsd-tools windows fixed <id>`.

| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |
|----|-------|------|------|------|-------------|--------|--------|-------------|-------------|
| 1 | 15 | deviation | docs/dots-hyprland-workflow.md | 401 | Playbook section 8 cites 15-DOC-SWEEP.md as carrying the D-38 restoration work as a deferred item; that section of the sweep record is still a 15-06 placeholder | open |  | 2026-09-06T06:28:36.362Z |  |

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
  }
]
````
