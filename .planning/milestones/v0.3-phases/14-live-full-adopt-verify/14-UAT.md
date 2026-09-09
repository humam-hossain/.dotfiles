---
status: complete
phase: 14-live-full-adopt-verify
source: 14-01-SUMMARY.md, 14-02-SUMMARY.md
started: 2026-09-05T11:01:35Z
updated: 2026-09-05T11:07:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Layout, workspace pinning and launcher keybind on the live session
expected: Across both monitors the ii desktop renders correctly and is usable — ii bar up, windows land where expected, workspaces open on the monitor the Phase 13 overlay pins them to (1-5 + special:social on DP-1, 6-10 on HDMI-A-2). Tapping SUPER alone opens the ii launcher (Quickshell search overlay).
result: pass
coverage_id: 14-02/D3

### 2. Adopt window was human-gated and operator-executed
expected: The one-way `install --full` adopt window opened only after you personally answered the exact-token go gate, and you ran it yourself from a bare TTY — no agent invoked the mutating install. 14-ADOPT-TRANSCRIPT.txt should match your memory of that run: the gate answered `yes`, 59 prompts each answered `y`, `yesforall` never typed.
result: pass
coverage_id: 14-02/D5

### 3. Adopt runbook is unambiguous at a bare TTY
expected: Reading docs/phase14-adopt-runbook.md end to end gives one unambiguous order for the whole adopt window — go/no-go criteria, banned flags, and three rollback tiers — legible and followable at a bare TTY under stress, with no step whose order or wording you could misread.
result: pass
coverage_id: 14-01/D5

### 4. Preflight --rotate-backup is the only mutating path and stayed unreachable by default
expected: In scripts/phase14-preflight.sh, `rotate_backup` performs a single `mv`, refuses when the backup directory is absent or the timestamped destination already exists, is called from exactly one site guarded by `ROTATE -eq 1` after all checks, and `--help` names it as the only mutating path. The default path never reaches it. (The mv itself was deliberately not executed by the agent — you exercised it at runbook section 5.)
result: pass
coverage_id: 14-01/D4

### 5. scripts/phase14-preflight.sh reports every mechanical go condition and exits 0 when they all hold
expected: scripts/phase14-preflight.sh reports every mechanical go condition and exits 0 when they all hold
result: pass
source: automated
coverage_id: 14-01/D1

### 6. The preflight's default path mutates nothing under $HOME and is safe to re-run
expected: The preflight's default path mutates nothing under $HOME and is safe to re-run
result: pass
source: automated
coverage_id: 14-01/D2

### 7. Stale ~/ii-original-dots-backup reported at the [FINDING] tier
expected: The existing stale ~/ii-original-dots-backup is reported at the [FINDING] tier, keeping the default path green while surfacing the condition
result: pass
source: automated
coverage_id: 14-01/D3

### 8. 14-PRE-ADOPT-BASELINE.txt records the pre-adopt facts D-36 and D-37 depend on
expected: 14-PRE-ADOPT-BASELINE.txt records the pre-adopt facts D-36 and D-37 depend on, committed before any mutation
result: pass
source: automated
coverage_id: 14-01/D6

### 9. Faithful pre-adopt archive of the live hypr tree plus dolphinrc and kdeglobals
expected: The repo holds a faithful pre-adopt archive of the live hypr tree plus dolphinrc and kdeglobals, in one commit, with .config/hypr/custom/ provably untouched
result: pass
source: automated
coverage_id: 14-01/D7

### 10. PROTECT_EXPLICIT membership correct and Phase 12 contract suite green
expected: waybar and swaync are out of PROTECT_EXPLICIT, hyprpaper remains, and the Phase 12 contract suite is still green
result: pass
source: automated
coverage_id: 14-01/D8

### 11. Clean tree and origin/main current before the adopt window
expected: The working tree is clean and origin/main is current, so the runbook the operator reads at a TTY is the version on GitHub
result: pass
source: automated
coverage_id: 14-01/D9

### 12. ADOPT-02 — the running session came from the ii Lua entry
expected: ADOPT-02 — the running session came from the ii Lua entry, proven three ways plus a token-free Lua REPL probe
result: pass
source: automated
coverage_id: 14-02/D1

### 13. ADOPT-03 automatable half — monitors, workspace rules, processes
expected: DP-1 enforced present, all eleven Phase 13 workspace rules live in the running compositor, qs -c ii running, Waybar/rofi/swaync gone
result: pass
source: automated
coverage_id: 14-02/D2

### 14. ADOPT-04 input half — rollback tiers and backup freshness
expected: Three tier-1 sources present and byte-identical to the pre-adopt fixture, tiers 2 and 3 reachable by dry-run, D-36 backup freshness proven
result: pass
source: automated
coverage_id: 14-02/D4

### 15. D-35..D-38 — clean tree, D-24 held, known losses probed
expected: Clean tree apart from phase artifacts, D-24 held with unpromoted sidecars, every named known loss confirmed by probe, screen-share portal probed
result: pass
source: automated
coverage_id: 14-02/D6

## Summary

total: 15
passed: 15
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

[none yet]
