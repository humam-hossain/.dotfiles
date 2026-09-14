---
status: diagnosed
phase: 20-hypr-custom-overlays-and-startup-restore
source: [20-01-SUMMARY.md, 20-02-SUMMARY.md, 20-03-SUMMARY.md, 20-04-SUMMARY.md]
started: 2026-09-14T15:53:32Z
updated: 2026-09-14T16:17:18Z
---

## Current Test

[testing complete]

## Tests

### 1. Operator manual post-login verification procedure
expected: Post-login autostarts (Chrome ws1, Kitty+tmux ws1, btop special:btop, Discord special:social) and graphical polkit prompt function on graphical session start
result: issue
reported: "Discord has slight issue of not properly opening in the social workspace properly first loading does open in the special:social but after that new window opens in whatever workspace i'm in. The rest is pass"
severity: minor
plan: 20-04
requirement: START-01

### 2. SAFE-01 isolated scratch fixture backup creation, stub pruning, and stow dry-run verification
expected: SAFE-01 isolated scratch fixture backup creation, stub pruning, and stow dry-run verification
result: pass
source: automated
coverage_id: D1
plan: 20-01
requirement: SAFE-01

### 3. SAFE-01 isolated fixture live undo drill and re-stow rehearsal verification
expected: SAFE-01 isolated fixture live undo drill and re-stow rehearsal verification
result: pass
source: automated
coverage_id: D2
plan: 20-01
requirement: SAFE-01

### 4. Application preferences in custom/variables.lua locked per D-16 with clean submodule
expected: Application preferences in custom/variables.lua locked per D-16 with clean submodule
result: pass
source: automated
coverage_id: D1
plan: 20-02
requirement: HYPR-03

### 5. Python GUI tool floating window rules defined in custom/rules.lua per D-17
expected: Python GUI tool floating window rules defined in custom/rules.lua per D-17
result: pass
source: automated
coverage_id: D2
plan: 20-02
requirement: HYPR-03

### 6. Environment overlay require slot configured in custom/env.lua per D-18
expected: Environment overlay require slot configured in custom/env.lua per D-18
result: pass
source: automated
coverage_id: D3
plan: 20-02
requirement: HYPR-01

### 7. Pre-adopt autostart applications restored in custom/execs.lua inside single-fire startup hook
expected: Pre-adopt autostart applications restored in custom/execs.lua inside single-fire startup hook
result: pass
source: automated
coverage_id: D4
plan: 20-02
requirement: START-01

### 8. Cursor theme settings unified to Bibata-Modern-Classic 24 in GTK-3.0 and xsettingsd
expected: Cursor theme settings unified to Bibata-Modern-Classic 24 in GTK-3.0 and xsettingsd
result: pass
source: automated
coverage_id: D5
plan: 20-02
requirement: START-01

### 9. Upstream unbind declarations in custom/keybinds.lua for 9 conflicting chords per D-06
expected: Upstream unbind declarations in custom/keybinds.lua for 9 conflicting chords per D-06
result: pass
source: automated
coverage_id: D1
plan: 20-03
requirement: HYPR-02

### 10. Personal window management, Vim navigation, audio, search, session, and special workspace keybindings
expected: Personal window management, Vim navigation, audio, search, session, and special workspace keybindings
result: pass
source: automated
coverage_id: D2
plan: 20-03
requirement: HYPR-02

### 11. Cheatsheet taxonomy format 'Category: Label' and zero duplicates across all keybindings
expected: Cheatsheet taxonomy format 'Category: Label' and zero duplicates across all keybindings
result: pass
source: automated
coverage_id: D3
plan: 20-03
requirement: HYPR-02

### 12. Live SAFE-01 migration drill and escape route rehearsal executed on live desktop session
expected: Live SAFE-01 migration drill and escape route rehearsal executed on live desktop session
result: pass
source: automated
coverage_id: D1
plan: 20-04
requirement: SAFE-01

### 13. All 6 overlay files in ~/.config/hypr/custom/ are symlinks resolving to repo inodes with no parent folding
expected: All 6 overlay files in ~/.config/hypr/custom/ are symlinks resolving to repo inodes with no parent folding
result: pass
source: automated
coverage_id: D2
plan: 20-04
requirement: HYPR-01

### 14. arch/dots-hyprland.sh verify --strict exits 0 with FAIL=0 FINDINGS=0
expected: arch/dots-hyprland.sh verify --strict exits 0 with FAIL=0 FINDINGS=0
result: pass
source: automated
coverage_id: D3
plan: 20-04
requirement: HYPR-01

## Summary

total: 14
passed: 13
issues: 1
pending: 0
skipped: 0
blocked: 0

## Gaps

- truth: "Discord windows open in special:social workspace"
  status: failed
  reason: "User reported: Discord has slight issue of not properly opening in the social workspace properly first loading does open in the special:social but after that new window opens in whatever workspace i'm in. The rest is pass"
  severity: minor
  test: 1
  root_cause: "custom/rules.lua lacks persistent window rule for discord/vesktop class to special:social workspace; only initial execs.lua hook had one-time workspace assignment"
  artifacts:
    - path: "stow/hypr/.config/hypr/custom/rules.lua"
      issue: "Missing window rule pinning class ^(discord|vesktop)$ to special:social silent"
  missing:
    - "Add hl.window_rule matching class ^(discord|vesktop)$ with workspace special:social silent in custom/rules.lua"
    - "Update phase 20 assert script section 3 to assert rule presence"
  debug_session: .planning/debug/discord-special-social-window-rule.md
