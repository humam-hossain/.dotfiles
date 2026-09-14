---
schema_version: 1
open_count: 8
waived_count: 0
fixed_count: 1
total_count: 9
last_updated: 2026-09-14T07:01:18.513Z
---

# Broken Windows Ledger

> Cross-phase defect register. With `workflow.windows_enforce` enabled, `/gsd-ship` blocks while `open_count > 0`.
> Waive with `gsd-tools windows waive <id> "<reason>"` (reason required).
> Mark fixed with `gsd-tools windows fixed <id>`.

| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |
|----|-------|------|------|------|-------------|--------|--------|-------------|-------------|
| 1 | 15 | deviation | docs/dots-hyprland-workflow.md | 401 | Playbook section 8 cites 15-DOC-SWEEP.md as carrying the D-38 restoration work as a deferred item; that section of the sweep record is still a 15-06 placeholder | open |  | 2026-09-06T06:28:36.362Z |  |
| 2 | 16 | deviation | scripts/phase12-full-smoke.sh |  | Expected-red from 16-01: asserts the retired safe-profile behavior; rewritten in plan 16-02 (D-34) | fixed |  | 2026-09-07T12:59:12.993Z | 2026-09-07T13:10:51.053Z |
| 3 | 16 | deviation | scripts/phase13-d19-assert.sh |  | Expected-red from 16-01: hard-fails on any arch/dots-hyprland.sh diff from its pinned base; re-pinned in plan 16-06 (D-38) | open |  | 2026-09-07T12:59:13.113Z |  |
| 4 | 16 | deviation | scripts/phase14-verify.sh |  | 16-03 acceptance criterion demanded file-wide absence of sha256sum, but three call sites are inside assertions D-37 keeps (check_tier1_source, check_untouched, check_sidecar); criterion satisfied in scope (the deleted D-36 backup-integrity block) rather than literally | open |  | 2026-09-07T13:19:34.277Z |  |
| 5 | 17 | deviation | scripts/phase17-unblock-assert.sh |  | Criterion 3 fixture could invoke the real rm -rf through safe_rm_path when the guard under test regresses; mitigated by shadowing rm in every fixture subshell (repo was deleted once and restored from git during 17-02) | open |  | 2026-09-12T14:27:01.669Z |  |
| 6 | 17 | deviation | scripts/phase13-d19-assert.sh |  | Script hard-coded .planning/phases/ paths that the v0.3 milestone archival moved; repaired with an archive-aware phase_artifact() resolver plus an in-the-open path rewrite on the extracted D-19 fence | open |  | 2026-09-12T14:27:01.776Z |  |
| 7 | 19 | deviation | scripts/phase17-unblock-assert.sh |  | 19-01 acceptance criterion requires phase17-unblock-assert.sh to exit 0; it is pre-existing FAIL=8 since Phase 18 removed repo-root .config/ (dispositioned in 18-VERIFICATION.md). Not fixed here — scope boundary. | open |  | 2026-09-14T04:28:00.122Z |  |
| 8 | 19 | unrun-verify | scripts/phase19-link-aware-verify-assert.sh |  | 19-01 Task 3 <human-check>: read the real-tree 'verify --quiet' output and confirm it is one-screen scannable. Deferred by workflow.human_verify_mode=end-of-phase. | open |  | 2026-09-14T04:28:00.227Z |  |
| 9 | 19 | unmet-truth | scripts/phase14-verify.sh | 407 | check_untouched() probes with stat -c %s (no deref) but sha256sum (deref): since feat(18-06) the live hyprlock.conf/hypridle.conf are symlinks into restow/, so the size reads 66 (link target length) against the fixture's 554/359 while the sha matches exactly. D-37 reports FAIL for two files whose content is byte-identical. Fix is one -L on the stat; owned by the phase14 assert, not repaired in 19-05. | open |  | 2026-09-14T07:01:18.513Z |  |

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
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-09-07T12:59:12.993Z",
    "resolved_at": "2026-09-07T13:10:51.053Z"
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
  },
  {
    "id": 4,
    "kind": "deviation",
    "phase": "16",
    "file": "scripts/phase14-verify.sh",
    "line": null,
    "description": "16-03 acceptance criterion demanded file-wide absence of sha256sum, but three call sites are inside assertions D-37 keeps (check_tier1_source, check_untouched, check_sidecar); criterion satisfied in scope (the deleted D-36 backup-integrity block) rather than literally",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-07T13:19:34.277Z",
    "resolved_at": null
  },
  {
    "id": 5,
    "kind": "deviation",
    "phase": "17",
    "file": "scripts/phase17-unblock-assert.sh",
    "line": null,
    "description": "Criterion 3 fixture could invoke the real rm -rf through safe_rm_path when the guard under test regresses; mitigated by shadowing rm in every fixture subshell (repo was deleted once and restored from git during 17-02)",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-12T14:27:01.669Z",
    "resolved_at": null
  },
  {
    "id": 6,
    "kind": "deviation",
    "phase": "17",
    "file": "scripts/phase13-d19-assert.sh",
    "line": null,
    "description": "Script hard-coded .planning/phases/ paths that the v0.3 milestone archival moved; repaired with an archive-aware phase_artifact() resolver plus an in-the-open path rewrite on the extracted D-19 fence",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-12T14:27:01.776Z",
    "resolved_at": null
  },
  {
    "id": 7,
    "kind": "deviation",
    "phase": "19",
    "file": "scripts/phase17-unblock-assert.sh",
    "line": null,
    "description": "19-01 acceptance criterion requires phase17-unblock-assert.sh to exit 0; it is pre-existing FAIL=8 since Phase 18 removed repo-root .config/ (dispositioned in 18-VERIFICATION.md). Not fixed here — scope boundary.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-14T04:28:00.122Z",
    "resolved_at": null
  },
  {
    "id": 8,
    "kind": "unrun-verify",
    "phase": "19",
    "file": "scripts/phase19-link-aware-verify-assert.sh",
    "line": null,
    "description": "19-01 Task 3 <human-check>: read the real-tree 'verify --quiet' output and confirm it is one-screen scannable. Deferred by workflow.human_verify_mode=end-of-phase.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-14T04:28:00.227Z",
    "resolved_at": null
  },
  {
    "id": 9,
    "kind": "unmet-truth",
    "phase": "19",
    "file": "scripts/phase14-verify.sh",
    "line": 407,
    "description": "check_untouched() probes with stat -c %s (no deref) but sha256sum (deref): since feat(18-06) the live hyprlock.conf/hypridle.conf are symlinks into restow/, so the size reads 66 (link target length) against the fixture's 554/359 while the sha matches exactly. D-37 reports FAIL for two files whose content is byte-identical. Fix is one -L on the stat; owned by the phase14 assert, not repaired in 19-05.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-14T07:01:18.513Z",
    "resolved_at": null
  }
]
````
