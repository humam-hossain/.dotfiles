# Phase 8: Retire Local Quickshell Product - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-27
**Phase:** 8-Retire Local Quickshell Product
**Areas discussed:** quickshell.sh retirement shape, Delete mechanics & dirty tree, LIVE-04 re-verify gate (simplified mid-discussion), Stale refs & test debt (simplified), Install-health priority

---

## quickshell.sh retirement shape

| Option | Description | Selected |
|--------|-------------|----------|
| Fatal deprecation stub | Keep path; exit non-zero pointing at dots-hyprland.sh | |
| Hard delete the file | git rm entirely | ✓ |
| You decide | Builder picks | |

**User's choice:** Hard delete the file  
**Notes:** Later free-text: “This file is not important, just delete it.”

| Option | Description | Selected |
|--------|-------------|----------|
| No package work this phase | Leave packages installed; no uninstall | ✓ |
| Document package ownership only | Note in wrapper/docs | |
| You decide | Builder picks | |

**User's choice:** No package work this phase

| Option | Description | Selected |
|--------|-------------|----------|
| Repo code refs only | Grep/fix non-vendor code; docs Phase 9 | |
| Also fix README/runbook | Patch docs now | |
| Other | Free-text | ✓ |

**User's choice:** “This file is not important, just delete it.” (minimal fuss)

---

## Delete mechanics & dirty tree

| Option | Description | Selected |
|--------|-------------|----------|
| Single git rm -r of the tree | One deliberate delete commit | ✓ |
| Delete + annotated git tag first | Tag last v0.1 product SHA | |
| You decide | Builder picks | |

**User's choice:** Single git rm -r of the tree

| Option | Description | Selected |
|--------|-------------|----------|
| Discard WIP, then delete | Drop uncommitted QML experiments | |
| Commit WIP into history first | Then delete | |
| Other | Free-text | ✓ |

**User's choice:** “None of these are important, delete them.”

| Option | Description | Selected |
|--------|-------------|----------|
| Tree delete is its own commit | Atomic tree commit; separate for script/tests | ✓ |
| One big retirement commit | Batch everything | |
| You decide | Builder picks | |

**User's choice:** Tree delete is its own commit

| Option | Description | Selected |
|--------|-------------|----------|
| Nothing — full delete | No salvage | ✓ |
| Salvage specific paths first | User names paths | |
| You decide | Builder assumes full delete | |

**User's choice:** Nothing — full delete

---

## LIVE-04 re-verify gate → simplified

| Option | Description | Selected |
|--------|-------------|----------|
| Re-run phase07 smoke now | Pre-delete smoke | ✓ (later overridden) |
| Smoke + chrome confirm | Extra chrome glance | |
| Trust Phase 7 UAT only | Skip re-verify | |

**User's choice (initial):** Re-run phase07 smoke  

| Option | Description | Selected |
|--------|-------------|----------|
| Phase-8 smoke script | New post-delete smoke | ✓ (later overridden) |
| Manual checklist only | No new script | |
| You decide | Builder designs | |

**User's choice (initial):** Phase-8 smoke script  

| Option | Description | Selected |
|--------|-------------|----------|
| Stop — do not delete | Block on smoke fail | |
| Warn and continue if operator overrides | Allow override | ✓ (later overridden) |
| You decide | Builder encodes default | |

**User's choice (initial):** Warn + override  

| Option | Description | Selected |
|--------|-------------|----------|
| Explicit typed ack | YES_DELETE_ANYWAY style | ✓ (later overridden) |
| Env/flag override | RETIRE_FORCE=1 | |
| You decide | Builder picks | |

**User's choice (initial):** Explicit typed ack  

**Override (user free-text mid-flow):**  
“no need for smoke test or whatever. I only care about the new proper installation of dots-hyprland, just delete the previous materials. Make sure dots-hyprland setup works.”  
Later: if installed dots-hyprland is corrupted, reinstall it.

**Final locked policy:** No smoke suite; ensure/reinstall working dots-hyprland via wrapper; delete old materials.

---

## Stale refs & test debt

| Option | Description | Selected |
|--------|-------------|----------|
| Leave phase07 frozen; new phase08 smoke | Historical vs new script | ✓ (then smoke dropped entirely) |
| Invert D-04 in phase07 smoke | One script both eras | |
| You decide | Builder picks | |

**User's choice (partial):** Leave phase07 frozen + new phase08 smoke — **superseded** by “no smoke test” directive.

**phase04 asserts / historical scripts:** discussion interrupted; final CONTEXT treats them as leave-historical / out of scope for Phase 8.

---

## Install-health priority (closing)

| Option | Description | Selected |
|--------|-------------|----------|
| Don’t break the wrapper path | Delete only; no new smoke | |
| Dry-run wrapper once after delete | Light preflight | |
| Re-run full install if needed | Recovery path | |
| Other | Free-text | ✓ |

**User's choice:** “dots-hyprland that has been installed is not corrupted or anything if needed reinstall it.”

---

## Claude's Discretion

- Exact reinstall sequence if needed  
- Light comment cleanup on `arch/dots-hyprland.sh` pattern header  
- Commit message wording  
- Grep depth for stale installer mentions  

## Deferred Ideas

- Phase 9 full docs playbook  
- Historical assert/smoke maintenance  
- Deprecation stub (rejected)  
- Package uninstall  
- Waybar cutover / custom ports  
