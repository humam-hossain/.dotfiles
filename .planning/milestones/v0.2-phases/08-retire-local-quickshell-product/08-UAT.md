---
status: complete
phase: 08-retire-local-quickshell-product
source: 08-01-SUMMARY.md, 08-02-SUMMARY.md, 08-03-SUMMARY.md
started: 2026-07-28T11:11:47Z
updated: 2026-07-28T11:15:46Z
---

## Current Test

[testing complete]

## Tests

### 1. Confirm single-product-path retirement
expected: Repo tree gone; old installer gone; wrapper sole entry; live ii real under home; desktop chrome still usable
result: pass

### 2. Live QS real dir with ii/shell.qml (not under repo)
expected: Live ~/.config/quickshell is real dir (not symlink) with ii/shell.qml, not under repo product
result: pass
source: automated
coverage_id: 08-01-D1

### 3. ii Python venv present
expected: ii Python venv present at ~/.local/state/quickshell/.venv
result: pass
source: automated
coverage_id: 08-01-D2

### 4. Repo hypr SoT still has ii hooks
expected: Repo hypr SoT still has ILLOGICAL_IMPULSE_VIRTUAL_ENV + exec-once = qs -c ii
result: pass
source: automated
coverage_id: 08-01-D3

### 5. Reinstall skipped — live health green
expected: Reinstall skipped — live health green without wrapper reinstall
result: pass
source: automated
coverage_id: 08-01-D4

### 6. In-repo .config/quickshell fully removed
expected: In-repo .config/quickshell fully removed from REPO (933 files)
result: pass
source: automated
coverage_id: 08-02-D1

### 7. Live hold after repo tree delete
expected: Live ~/.config/quickshell still real with ii/shell.qml after repo delete
result: pass
source: automated
coverage_id: 08-02-D2

### 8. Tree delete was dedicated commit
expected: Tree delete is dedicated commit; installer was still present pending 08-03
result: pass
source: automated
coverage_id: 08-02-D3

### 9. arch/quickshell.sh hard-deleted (no stub)
expected: arch/quickshell.sh hard-deleted with no stub
result: pass
source: automated
coverage_id: 08-03-D1

### 10. Wrapper sole install entry
expected: arch/dots-hyprland.sh remains sole executable install entry
result: pass
source: automated
coverage_id: 08-03-D2

### 11. No active arch/quickshell.sh product-path refs
expected: No active arch/quickshell.sh refs under arch/scripts/.config after reword
result: pass
source: automated
coverage_id: 08-03-D3

### 12. Post-retirement live + RET-01 hold
expected: Live ii hold + RET-01 tree absence after installer gone
result: pass
source: automated
coverage_id: 08-03-D4

## Summary

total: 12
passed: 12
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

[none yet]
