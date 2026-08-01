---
status: complete
phase: 07-install-session-hooks-dual-run-verify
source: 07-01-SUMMARY.md, 07-02-SUMMARY.md, 07-03-SUMMARY.md
started: 2026-07-27T12:05:43Z
updated: 2026-07-27T12:11:12Z
---

## Current Test

[testing complete]

## Tests

### 1. No qs or quickshell process running before install
expected: No qs or quickshell process running before install
result: pass
source: automated
coverage_id: D1
summary: 07-01

### 2. Live ~/.config/quickshell is not a symlink (path absent preferred)
expected: Live ~/.config/quickshell is not a symlink (path absent preferred)
result: pass
source: automated
coverage_id: D2
summary: 07-01

### 3. In-repo .config/quickshell product tree still present
expected: In-repo .config/quickshell product tree still present
result: pass
source: automated
coverage_id: D3
summary: 07-01

### 4. Dry-run proves SAFE_DEFAULTS argv before live mutation (D-06)
expected: Dry-run proves SAFE_DEFAULTS argv before live mutation (D-06)
result: pass
source: automated
coverage_id: D1
summary: 07-02

### 5. LIVE-01 real dir + ii/shell.qml not under .dotfiles
expected: LIVE-01 real dir + ii/shell.qml not under .dotfiles
result: pass
source: automated
coverage_id: D3
summary: 07-02

### 6. ii Python venv present post-setups
expected: ii Python venv present post-setups
result: pass
source: automated
coverage_id: D4
summary: 07-02

### 7. Personal hyprland.conf not renamed to .old
expected: Personal hyprland.conf not renamed to .old
result: pass
source: automated
coverage_id: D5
summary: 07-02

### 8. Repo hypr hooks env + qs -c ii + waybar preserved; D-11 commit
expected: Repo hypr hooks env + qs -c ii + waybar preserved; D-11 commit
result: pass
source: automated
coverage_id: D1
summary: 07-03

### 9. Live conf cmp + hyprctl reload clean + qs env-prefix restart
expected: Live conf cmp + hyprctl reload clean + qs env-prefix restart
result: pass
source: automated
coverage_id: D2
summary: 07-03

### 10. LIVE-03 waybar dual-run hard bar; swaync soft present
expected: LIVE-03 waybar dual-run hard bar; swaync soft present
result: pass
source: automated
coverage_id: D3
summary: 07-03

### 11. LIVE-04 qs -c ii process + venv env
expected: LIVE-04 qs -c ii process + venv env
result: pass
source: automated
coverage_id: D4
summary: 07-03

### 12. Operator pre-install ready for wrapper install
expected: |
  Before the live wrapper install, host was in a safe pre-install state and
  you confirmed readiness: qs/quickshell stopped, live ~/.config/quickshell
  not a symlink (path absent preferred), in-repo .config/quickshell product
  still present. You typed approved at the blocking pre-install checkpoint.
result: pass
source: re-verified
coverage_id: D4
summary: 07-01
evidence: |
  Historical gate recorded in 07-01-SUMMARY (operator typed approved).
  Residual re-check 2026-07-27: live path is real directory (post-install,
  not symlink into .dotfiles); in-repo .config/quickshell still present.
  Pre-install process stop was execution-time only (qs now correctly running
  as qs -c ii -d for dual-run).

### 13. Live one-shot wrapper install completed
expected: |
  Live install ran via ./arch/dots-hyprland.sh install only (wrapper one-shot).
  You typed yes at the backup gate (no --skip-backup). Install finished with
  [./setup]: Finished after any D-08 fix-and-re-run for package conflicts.
  Result: real ~/.config/quickshell tree + venv on host; personal hypr conf
  not replaced by full ii hypr install.
result: pass
source: re-verified
coverage_id: D2
summary: 07-02
evidence: |
  Re-check 2026-07-27: ! -L, -d, ii/shell.qml present; readlink -f
  /home/pera/.config/quickshell (not under .dotfiles); .venv present;
  hyprland.conf present, no .old; ~/ii-original-dots-backup present;
  waybar + qs -c ii -d with ILLOGICAL_IMPULSE_VIRTUAL_ENV; repo/live
  hyprland.conf cmp -s OK. Matches 07-02 SUMMARY interactive install path.

### 14. Visible ii shell chrome on screen (LIVE-04 part 3)
expected: |
  In the Hyprland session you can see illogical-impulse / Material Quickshell
  chrome (ii shell UI) on screen while waybar remains running. Dual-run bar
  overlap is expected success, not a failure. Process alone is not enough —
  chrome must be visibly present.
result: pass
reported: "in the workspace chrome logo is present"
coverage_id: D5
summary: 07-03

## Summary

total: 14
passed: 14
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

[none yet]
