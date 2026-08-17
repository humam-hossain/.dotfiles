---
status: complete
phase: 12-wrapper-full-profile
source: [12-01-SUMMARY.md, 12-02-SUMMARY.md, 12-03-SUMMARY.md, 12-04-SUMMARY.md]
started: 2026-08-17T00:00:00Z
updated: 2026-08-17T09:31:46Z
---

## Current Test

[testing complete]

## Tests

### 1. Confirm Automated Test Coverage
expected: |
  All 9 deliverables for this phase were deterministically covered by automated tests.

  Please review the auto-covered list below and confirm it looks correct.

  12-01:
  - D1: install --full --dry-run would-exec omits all three SAFE_DEFAULTS residuals and strips --full
    covered by: printf 'yes\n' | ./arch/dots-hyprland.sh install --full --dry-run
  - D2: Default install --dry-run still injects SAFE_DEFAULTS triple residual
    covered by: printf 'yes\n' | ./arch/dots-hyprland.sh install --dry-run
  - D3: install-files --full/--dry-run parity + install-deps --full refuse
    covered by: install-files --full --dry-run residual absence; install-deps --full non-zero

  12-02:
  - D1: Full dry-run hits type-yes gate with D-07 themes then would-exec
    covered by: printf yes | install --full --dry-run gate+would-exec greps
  - D2: Bare skip-backup on full refused; dual-key allow strips meta
    covered by: install --full --skip-backup refuse; dual-key allow dry-run

  12-03:
  - D1: help lists --full and no longer tells operators to leave the wrapper for full hypr
    covered by: ./arch/dots-hyprland.sh help greps for --full and negative vendor-outside note
  - D2: help points at playbook and INV/DISP artifact paths
    covered by: help greps dots-hyprland-workflow 10-INVENTORY 11-DISPOSITIONS

  12-04 (new since last UAT):
  - D1: Full dry-run still plans protect re-mark and ii hooks; real-path arms not skipped when full==1
    covered by: printf yes | install --full --dry-run greps protect-list + ii hooks; install-files --full --dry-run protect-list
  - D2: scripts/phase12-full-smoke.sh exits 0 on FULL-01..05 non-mutating matrix
    covered by: ./scripts/phase12-full-smoke.sh
result: pass

### 2. install --full --dry-run would-exec omits all three SAFE_DEFAULTS residuals and strips --full
expected: install --full --dry-run would-exec omits all three SAFE_DEFAULTS residuals and strips --full
result: pass
source: automated
coverage_id: D1

### 3. Default install --dry-run still injects SAFE_DEFAULTS triple residual
expected: Default install --dry-run still injects SAFE_DEFAULTS triple residual
result: pass
source: automated
coverage_id: D2

### 4. install-files --full/--dry-run parity + install-deps --full refuse
expected: install-files --full/--dry-run parity + install-deps --full refuse
result: pass
source: automated
coverage_id: D3

### 5. Full dry-run hits type-yes gate with D-07 themes then would-exec
expected: Full dry-run hits type-yes gate with D-07 themes then would-exec
result: pass
source: automated
coverage_id: D1

### 6. Bare skip-backup on full refused; dual-key allow strips meta
expected: Bare skip-backup on full refused; dual-key allow strips meta
result: pass
source: automated
coverage_id: D2

### 7. help lists --full and no longer tells operators to leave the wrapper for full hypr
expected: help lists --full and no longer tells operators to leave the wrapper for full hypr
result: pass
source: automated
coverage_id: D1

### 8. help points at playbook and INV/DISP artifact paths
expected: help points at playbook and INV/DISP artifact paths
result: pass
source: automated
coverage_id: D2

### 9. Full dry-run still plans protect re-mark and ii hooks; real-path arms not skipped when full==1
expected: Full dry-run still plans protect re-mark and ii hooks; real-path arms not skipped when full==1
result: pass
source: automated
coverage_id: D1

### 10. scripts/phase12-full-smoke.sh exits 0 on FULL-01..05 non-mutating matrix
expected: scripts/phase12-full-smoke.sh exits 0 on FULL-01..05 non-mutating matrix
result: pass
source: automated
coverage_id: D2

## Summary

total: 10
passed: 10
issues: 0
pending: 0
skipped: 0

## Gaps

[none yet]
