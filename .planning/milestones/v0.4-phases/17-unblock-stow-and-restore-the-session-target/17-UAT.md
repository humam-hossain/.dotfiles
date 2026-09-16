---
status: complete
phase: 17-unblock-stow-and-restore-the-session-target
source: [17-01-SUMMARY.md, 17-02-SUMMARY.md, 17-03-SUMMARY.md, 17-04-SUMMARY.md, 17-05-SUMMARY.md, 17-06-SUMMARY.md, 17-07-SUMMARY.md]
started: 2026-09-13T11:51:38Z
updated: 2026-09-13T11:54:46Z
---

## Current Test

[testing complete]

## Tests

### 1. [17-01 D1] All 15 stow call sites across the 14 arch/*.sh files carry the literal `--verbose=5 --no-f…
expected: All 15 stow call sites across the 14 arch/*.sh files carry the literal `--verbose=5 --no-folding` in a fixed flag order, and the invalid short-verbosity spelling survives at zero sites under arch/
result: pass
source: automated
coverage_id: D1
plan: 17-01
requirement: FIX-01

### 2. [17-01 D2] The installed GNU Stow 2.4.1 actually accepts the new spelling — proven by a real non-muta…
expected: The installed GNU Stow 2.4.1 actually accepts the new spelling — proven by a real non-mutating simulate run, not only by a grep
result: pass
source: automated
coverage_id: D2
plan: 17-01
requirement: FIX-01

### 3. [17-01 D3] `bash -n` exits 0 on all 14 arch/*.sh files that hold a stow call site after the sweep
expected: `bash -n` exits 0 on all 14 arch/*.sh files that hold a stow call site after the sweep
result: pass
source: automated
coverage_id: D3
plan: 17-01
requirement: FIX-01

### 4. [17-01 D4] The 16th invocation — the documented kitty re-stow recovery command in docs/phase14-adopt-…
expected: The 16th invocation — the documented kitty re-stow recovery command in docs/phase14-adopt-runbook.md — carries the valid flag pair with `-R` preserved, and docs/ carries zero invalid stow invocations
result: pass
source: automated
coverage_id: D4
plan: 17-01
requirement: CAP-04

### 5. [17-01 D5] scripts/phase17-unblock-assert.sh exists with the D-20 three-prefix, one-counter contract …
expected: scripts/phase17-unblock-assert.sh exists with the D-20 three-prefix, one-counter contract — no FINDINGS counter leaked in from the phase-14 contract
result: pass
source: automated
coverage_id: D5
plan: 17-01

### 6. [17-01 D6] The D-02 folding audit records the pre-existing folded directory symlinks as live [INFO] o…
expected: The D-02 folding audit records the pre-existing folded directory symlinks as live [INFO] output and hands them to Phase 18 without unfolding them
result: pass
source: verified-by-claude
evidence: |
  Ran ./scripts/phase17-unblock-assert.sh: audit section emits exactly 3 [INFO]
  lines, 0 [PASS]/[FAIL]. Executable lines of the section are find(1), readlink(1)
  and a `-d` test only — no stow, no rm/mv/ln in command position. Both recorded
  folded symlinks (~/.config/qBittorrent, ~/.config/smartmontools) still present
  and unchanged after the run. Closing [INFO] names Phase 18 as owner; ROADMAP.md
  line 65 confirms Phase 18 is "Capture model — three trees and the collision map".
coverage_id: D6
plan: 17-01

### 7. [17-01 D7] The sibling Phase 16 assert suite is still green after this wave — no regression from the …
expected: The sibling Phase 16 assert suite is still green after this wave — no regression from the flag sweep
result: pass
source: automated
coverage_id: D7
plan: 17-01

### 8. [17-02 D1] safe_rm_path returns non-zero for every existing path that resolves under the repo root — …
expected: safe_rm_path returns non-zero for every existing path that resolves under the repo root — the repo root itself, a tracked file, a stow tree, and the vendored submodule with no carve-out
result: pass
source: automated
coverage_id: D1
plan: 17-02
requirement: FIX-04

### 9. [17-02 D2] The refusal survives symlink escape: ~/.config/systemd/user/hyprland-session.service is a …
expected: The refusal survives symlink escape: ~/.config/systemd/user/hyprland-session.service is a $HOME-shaped path that resolves into stow/systemd/ and is refused by the new clause, which a literal prefix test on the unresolved path would have missed (D-05)
result: pass
source: automated
coverage_id: D2
plan: 17-02
requirement: FIX-04

### 10. [17-02 D3] The two pre-existing refusal clauses still fire after the edit — /etc/passwd is refused as…
expected: The two pre-existing refusal clauses still fire after the edit — /etc/passwd is refused as outside $HOME, ~/.config/hypr/custom is refused as a hypr path — so a green criterion 3 cannot be produced by the old clauses alone
result: pass
source: automated
coverage_id: D3
plan: 17-02
requirement: FIX-04

### 11. [17-02 D4] arch/dots-hyprland.sh is sourceable from a `set -euo pipefail` caller: the load returns 0,…
expected: arch/dots-hyprland.sh is sourceable from a `set -euo pipefail` caller: the load returns 0, defines safe_rm_path as a function, and direct execution is behaviourally unchanged (bare invocation still prints usage and exits 0)
result: pass
source: automated
coverage_id: D4
plan: 17-02
requirement: FIX-04

### 12. [17-02 D5] Criterion 3a is non-vacuous — with the new refusal clause commented out the section report…
expected: Criterion 3a is non-vacuous — with the new refusal clause commented out the section reports [FAIL] for all three repo paths and the suite closes FAIL=3, exit 1
result: pass
source: verified-by-claude
evidence: |
  Replayed the mutation procedure. Commented out the resolved-path branch
  (arch/dots-hyprland.sh:463-466), ran ./scripts/phase17-unblock-assert.sh:
  exit 1, three [FAIL] lines ("3a safe_rm_path ACCEPTED a path inside the repo"
  for README.md, stow, vendor/dots-hyprland), closing line "=== done: FAIL=3 ===".
  Criterion 3a is non-vacuous. Restored via git checkout; suite back to exit 0,
  82 [PASS] / 0 [FAIL]; working tree clean.
coverage_id: D5
plan: 17-02
requirement: FIX-04

### 13. [17-02 D6] The criterion 3 fixture cannot destroy the repo when the guard regresses: every fixture su…
expected: The criterion 3 fixture cannot destroy the repo when the guard regresses: every fixture subshell shadows `rm` with a no-op, so the same commented-out-clause run that previously deleted README.md, stow/ and vendor/dots-hyprland now leaves all three intact while still reporting FAIL
result: pass
source: verified-by-claude
evidence: |
  Static: all four subshells that INVOKE safe_rm_path (assert lines 321, 323, 336,
  346) define `rm() { ... }` after sourcing the wrapper. Lines 356/360 are the 3d
  sourceability probe and call `type -t` only, never safe_rm_path. safe_rm_path
  calls bare `rm -rf -- "$path"` (arch/dots-hyprland.sh), so the shadow intercepts.
  Live: during the D5 mutation run above, 3 [FIXTURE-GUARD] blocked lines were
  emitted, FAIL=3 was still reported, and `ls -d README.md stow vendor/dots-hyprland`
  showed all three intact. `git status --short` showed only the deliberately
  edited file.
coverage_id: D6
plan: 17-02

### 14. [17-02 D7] scripts/phase13-d19-assert.sh is green again: a Phase 17 tier pins WRAPPER_BASE=b32faf6 ah…
expected: scripts/phase13-d19-assert.sh is green again: a Phase 17 tier pins WRAPPER_BASE=b32faf6 ahead of the Phase 16 tier, and the script resolves phase artifacts through the v0.3 milestone archive instead of dying on paths the archival moved
result: pass
source: automated
coverage_id: D7
plan: 17-02

### 15. [17-02 D8] No sibling assert suite is left red by the wrapper edit — the Phase 16 retirement suite st…
expected: No sibling assert suite is left red by the wrapper edit — the Phase 16 retirement suite still closes FAIL=0
result: pass
source: automated
coverage_id: D8
plan: 17-02

### 16. [17-03 D1] .gitattributes exists at the repo root and carries `* text=auto eol=lf` as a whole line (D…
expected: .gitattributes exists at the repo root and carries `* text=auto eol=lf` as a whole line (D-10), with no working-tree churn from the normalisation
result: pass
source: automated
coverage_id: D1
plan: 17-03
requirement: FIX-06

### 17. [17-03 D2] Seventeen new .gitignore patterns (six generated-theme, eleven machine-state), each proven…
expected: Seventeen new .gitignore patterns (six generated-theme, eleven machine-state), each proven by `git check-ignore -v` exiting 0 with the match attributed to that exact pattern and to .gitignore as the source
result: pass
source: automated
coverage_id: D2
plan: 17-03
requirement: FIX-06

### 18. [17-03 D3] No new pattern is over-broad: authored source is not ignored, verified by six named negati…
expected: No new pattern is over-broad: authored source is not ignored, verified by six named negative controls plus a sweep of every tracked file under --no-index pinned to exactly three expected paths
result: pass
source: automated
coverage_id: D3
plan: 17-03
requirement: FIX-06

### 19. [17-03 D4] .config/kdeglobals remains tracked and the tracked-file exemption is observable rather tha…
expected: .config/kdeglobals remains tracked and the tracked-file exemption is observable rather than asserted — check-ignore exits non-zero on it by default and 0 under --no-index
result: pass
source: automated
coverage_id: D4
plan: 17-03
requirement: FIX-06

### 20. [17-03 D5] The criterion 4 section is non-vacuous: with .gitattributes absent, 4a reports [FAIL] rath…
expected: The criterion 4 section is non-vacuous: with .gitattributes absent, 4a reports [FAIL] rather than passing over nothing
result: pass
source: automated
coverage_id: D5
plan: 17-03
requirement: FIX-06

### 21. [17-03 D6] The criterion 4 section is non-mutating — it contains no index-writing git subcommand
expected: The criterion 4 section is non-mutating — it contains no index-writing git subcommand
result: pass
source: automated
coverage_id: D6
plan: 17-03
requirement: FIX-06

### 22. [17-03 D7] The .env disposition is an operator decision on record (outcome A) and the three REDACTED …
expected: The .env disposition is an operator decision on record (outcome A) and the three REDACTED placeholder strings carry allowlist entries with one-line reasons, each scoped to path plus the placeholder literal
result: pass
source: verified-by-claude
evidence: |
  The 17-04 confirmation the rationale defers to is now observable. Assert suite:
  "4c history scan: 'gitleaks git . --redact --no-banner' exits 0" and
  "4c working-tree scan: 'gitleaks dir . --redact --no-banner' exits 0" — zero
  findings with this config, gitleaks 8.30.1-1 at /usr/bin/gitleaks.
  No broader suppression: all 12 allowlist entries carry condition = "AND" plus
  targetRules; none names .gitleaks.toml itself. Regex replay of the three
  placeholder entries — stow/zsh/.zshrc:106, :107 and
  stow/waybar/.config/waybar/config.jsonc:55-57 — each matches only REDACTED-bearing
  lines and nothing else. Outcome A holds: the .env is still tracked
  (git ls-files) and carries no ignore rule.
coverage_id: D7
plan: 17-03
requirement: FIX-06

### 23. [17-04 D1] gitleaks is installed from Arch extra and is the Arch package rather than a cross-ecosyste…
expected: gitleaks is installed from Arch extra and is the Arch package rather than a cross-ecosystem name-alike
result: pass
source: automated
coverage_id: D1
plan: 17-04
requirement: FIX-06

### 24. [17-04 D2] Both scan surfaces run with redaction and both return the clean verdict, re-runnably and w…
expected: Both scan surfaces run with redaction and both return the clean verdict, re-runnably and with no manual step in between
result: pass
source: automated
coverage_id: D2
plan: 17-04
requirement: FIX-06

### 25. [17-04 D3] Every allowlist entry carries an adjacent written reason and is narrowly scoped — path AND…
expected: Every allowlist entry carries an adjacent written reason and is narrowly scoped — path AND fingerprint component, with condition = \"AND\" and targetRules on all twelve
result: pass
source: automated
coverage_id: D3
plan: 17-04
requirement: FIX-06

### 26. [17-04 D4] No entry contains a secret value: .gitleaks.toml is tracked, no entry names it, so it sits…
expected: No entry contains a secret value: .gitleaks.toml is tracked, no entry names it, so it sits inside the working-tree surface that scans clean
result: pass
source: automated
coverage_id: D4
plan: 17-04
requirement: FIX-06

### 27. [17-04 D5] Sections 4c and 4d are non-vacuous: every assertion was proven capable of failing against …
expected: Sections 4c and 4d are non-vacuous: every assertion was proven capable of failing against a fixture
result: pass
source: automated
coverage_id: D5
plan: 17-04
requirement: FIX-06

### 28. [17-04 D6] The Category C reachability picture is measured, not assumed, and each entry's reason stat…
expected: The Category C reachability picture is measured, not assumed, and each entry's reason states the exposure honestly
result: pass
source: verified-by-claude
evidence: |
  Re-measured all seven commit-pinned shas: none is an ancestor of HEAD or of
  origin/main (f314491). Four — 44f9bc38, 86de82ea, a5c2f3c5, ba2c4f00 — are
  reachable from tags v0.1 v0.2 v1.0 v1.1; `git ls-remote origin` returns exactly
  main, v0.2 (peeled bad5111f) and v1.0 (peeled 0a7942bf), so two of those tags are
  published. Reproduces the recorded picture exactly.
  Honesty check over the 8 commit-pinned entries: every one states "not from main",
  "dead" and "no rewrite"; the published-tag framing appears on exactly the five
  entries whose commit is tag-reachable and on none of the other three. Framing
  tracks the measurement.
  Residual: the liveness verdict itself is operator testimony, recorded and dated
  2026-09-12 in every entry — not re-derivable, and correctly labelled as testimony.
coverage_id: D6
plan: 17-04
requirement: FIX-06

### 29. [17-04 D7] Categories B and A-new are remediated at source and carry no allowlist entry
expected: Categories B and A-new are remediated at source and carry no allowlist entry
result: pass
source: automated
coverage_id: D7
plan: 17-04
requirement: FIX-06

### 30. [17-05 D1] The repo copy of custom/execs.lua carries the session-bootstrap command literal inside a h…
expected: The repo copy of custom/execs.lua carries the session-bootstrap command literal inside a hyprland.start handler, with the Phase 13 authoring-SoT header
result: pass
source: automated
coverage_id: D1
plan: 17-05
requirement: START-02

### 31. [17-05 D2] The repo copy and the live copy are byte-identical, so the hand-sync window is closed on e…
expected: The repo copy and the live copy are byte-identical, so the hand-sync window is closed on every commit
result: pass
source: automated
coverage_id: D2
plan: 17-05
requirement: START-02

### 32. [17-05 D3] hyprland-session.service is in state `linked` and never `enabled`, asserted on the printed…
expected: hyprland-session.service is in state `linked` and never `enabled`, asserted on the printed string rather than the exit status
result: pass
source: automated
coverage_id: D3
plan: 17-05
requirement: START-02

### 33. [17-05 D4] Starting the unit takes graphical-session.target from inactive to active through the unit'…
expected: Starting the unit takes graphical-session.target from inactive to active through the unit's Wants=, and the target cannot be reached any other way
result: pass
source: automated
coverage_id: D4
plan: 17-05
requirement: START-02

### 34. [17-05 D5] The live session was left in its as-found state, so criterion 5e's post-re-login evidence …
expected: The live session was left in its as-found state, so criterion 5e's post-re-login evidence is not contaminated by a hand start
result: pass
source: automated
coverage_id: D5
plan: 17-05
requirement: START-02

### 35. [17-05 D6] An inactive target is reported [INFO] naming the operator re-login, never [FAIL], and the …
expected: An inactive target is reported [INFO] naming the operator re-login, never [FAIL], and the message separates a pending step from a real regression
result: pass
source: automated
coverage_id: D6
plan: 17-05
requirement: START-02

### 36. [17-05 D7] The operator docs name the disable footgun, its recovery command, and mask as the safe alt…
expected: The operator docs name the disable footgun, its recovery command, and mask as the safe alternative for a stow-managed unit
result: pass
source: automated
coverage_id: D7
plan: 17-05
requirement: START-03

### 37. [17-05 D8] The assert script is non-mutating in the executable sense D-20 means: none of the four ver…
expected: The assert script is non-mutating in the executable sense D-20 means: none of the four verbs appears in command position
result: pass
source: automated
coverage_id: D8
plan: 17-05
requirement: START-02

### 38. [17-05 D9] The playbook's expected-output lines for the phase-14 verify script are correct both befor…
expected: The playbook's expected-output lines for the phase-14 verify script are correct both before and after the re-login that flips the finding count
result: pass
source: human
reported: "pass"
note: |
  Operator accepted on 2026-09-13. Branch structure verified: phase14-verify.sh
  routes D-38 to info() when graphical-session.target is active, finding() when
  inactive. The expected-output lines are not reproducible today — the script
  aborts with "[FAIL] baseline fixture missing:
  .planning/phases/14-live-full-adopt-verify/14-PRE-ADOPT-BASELINE.txt" (exit 1,
  0 PASS, 0 FINDING) because the fixture moved to
  .planning/milestones/v0.3-phases/14-live-full-adopt-verify/ at the v0.3 archive.
  Covered by the deferred D-4 note from plan 17-05.
coverage_id: D9
plan: 17-05
requirement: START-03

### 39. [17-05 D10] Every new assertion is non-vacuous — proven capable of failing, against fixtures only
expected: Every new assertion is non-vacuous — proven capable of failing, against fixtures only
result: pass
source: automated
coverage_id: D10
plan: 17-05
requirement: START-02

### 40. [17-05 D11] The three Phase 18 handoff rows are on disk, including the one that closes this phase's ha…
expected: The three Phase 18 handoff rows are on disk, including the one that closes this phase's hand-sync window
result: pass
source: automated
coverage_id: D11
plan: 17-05
requirement: START-02

### 41. [17-06 D1] arch/hyprland.sh holds no recursive-force copy of the repo Hyprland configuration tree, an…
expected: arch/hyprland.sh holds no recursive-force copy of the repo Hyprland configuration tree, and no directory creation feeding one
result: pass
source: automated
coverage_id: D1
plan: 17-06
requirement: FIX-02

### 42. [17-06 D2] arch/hyprland.sh resolves no configuration path relative to the working directory
expected: arch/hyprland.sh resolves no configuration path relative to the working directory
result: pass
source: automated
coverage_id: D2
plan: 17-06
requirement: FIX-02

### 43. [17-06 D3] The gap the deletion leaves is attributed to Phase 20 / HYPR-01 by a comment the assert ca…
expected: The gap the deletion leaves is attributed to Phase 20 / HYPR-01 by a comment the assert can find
result: pass
source: automated
coverage_id: D3
plan: 17-06
requirement: FIX-02

### 44. [17-06 D4] Both stow call sites survive the deletion intact, still carrying the 17-01 flag pair, and …
expected: Both stow call sites survive the deletion intact, still carrying the 17-01 flag pair, and the script still parses
result: pass
source: automated
coverage_id: D4
plan: 17-06
requirement: FIX-02

### 45. [17-06 D5] The diff contains nothing beyond the deletion and the marker — no package-install or group…
expected: The diff contains nothing beyond the deletion and the marker — no package-install or group-membership line was removed
result: pass
source: automated
coverage_id: D5
plan: 17-06
requirement: FIX-02

### 46. [17-06 D6] The privileged-token ban reaches only the criterion 2 section, and plan 17-04's section 4c…
expected: The privileged-token ban reaches only the criterion 2 section, and plan 17-04's section 4c pacman -Qo check survives unmodified
result: pass
source: automated
coverage_id: D6
plan: 17-06
requirement: FIX-02

### 47. [17-06 D7] Every criterion 2 grep names arch/hyprland.sh by path and none recurses
expected: Every criterion 2 grep names arch/hyprland.sh by path and none recurses
result: pass
source: automated
coverage_id: D7
plan: 17-06
requirement: FIX-02

### 48. [17-06 D8] The harness is still non-mutating and idempotent
expected: The harness is still non-mutating and idempotent
result: pass
source: automated
coverage_id: D8
plan: 17-06
requirement: FIX-02

### 49. [17-06 D9] Every new assertion is non-vacuous — proven capable of failing, against fixture copies onl…
expected: Every new assertion is non-vacuous — proven capable of failing, against fixture copies only
result: pass
source: automated
coverage_id: D9
plan: 17-06
requirement: FIX-02

### 50. [17-07 D1] arch/hyprland.sh runs end to end against the live session and the wrapped command exits 0
expected: arch/hyprland.sh runs end to end against the live session and the wrapped command exits 0
result: pass
source: automated
coverage_id: D1
plan: 17-07
requirement: FIX-02

### 51. [17-07 D2] The run did not revert the Phase 14 adopt — the configuration provider is unchanged and th…
expected: The run did not revert the Phase 14 adopt — the configuration provider is unchanged and the pre-adopt live conf is still absent
result: pass
source: automated
coverage_id: D2
plan: 17-07
requirement: FIX-02

### 52. [17-07 D3] The two stow packages the script places are still symbolic links resolving into the repo w…
expected: The two stow packages the script places are still symbolic links resolving into the repo working tree, not plain files
result: pass
source: automated
coverage_id: D3
plan: 17-07
requirement: FIX-02

### 53. [17-07 D4] The partial-upgrade hazard did not land
expected: The partial-upgrade hazard did not land
result: pass
source: automated
coverage_id: D4
plan: 17-07
requirement: FIX-02

### 54. [17-07 D5] The evidence record names everything the run cost, including what it could not confirm
expected: The evidence record names everything the run cost, including what it could not confirm
result: pass
source: automated
coverage_id: D5
plan: 17-07
requirement: FIX-02

### 55. [17-07 D6] The desktop session behaves normally after the run — bar running, notifications working, s…
expected: The desktop session behaves normally after the run — bar running, notifications working, screen sharing offering sources
result: pass
source: verified-by-claude
evidence: |
  Now measurable — the operator re-login the rationale waited on has happened.
  graphical-session.target active; hyprland-session.service active, state linked
  (never enabled, so the START-03 footgun stays out of reach).
  Bar: `qs -c ii` running, PID 156710.
  Notifications: org.freedesktop.Notifications owned by PID 156710, Comm=qs.
  Screen sharing: /usr/lib/xdg-desktop-portal-hyprland running; ScreenCast
  AvailableSourceTypes = 7 (monitor|window|virtual all offered).
  Not covered by this evidence: rendered pixels and an actually-completed share.
coverage_id: D6
plan: 17-07

## Summary

total: 55
passed: 55
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

[none yet]
