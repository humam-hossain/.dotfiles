---
status: complete
phase: 19-link-aware-verify
source: [19-01-SUMMARY.md, 19-02-SUMMARY.md, 19-03-SUMMARY.md, 19-04-SUMMARY.md, 19-05-SUMMARY.md]
started: 2026-09-14T13:56:00Z
updated: 2026-09-14T14:07:00Z
---

## Current Test

[testing complete]

## Tests

### 1. --quiet output scannability
expected: Running `./arch/dots-hyprland.sh verify --quiet` suppresses all [PASS] lines and emits only non-passing / informational lines followed by the summary line `=== done: FAIL=0 FINDINGS=0 ===`. The output is concise and easily scannable on a single terminal screen without noisy success lines.
result: pass
source: verified-by-agent
evidence: |
  Executed `./arch/dots-hyprland.sh verify --quiet`:
  - 0 [PASS] lines emitted.
  - 37 total lines output (header + 35 [INFO] lines + summary line), fits comfortably on a single terminal screen.
  - Summary line: `=== done: FAIL=0 FINDINGS=0 ===`.
  - Exit code: 0.
coverage_id: D6
plan: 19-01
requirement: VER-03

### 2. Submodule independence read-only proof (D-47)
expected: `verify` runs independently of the vendored submodule `vendor/dots-hyprland`. `run_verify()`'s body references neither `vendor/` paths nor `preflight`, and executes cleanly (exit 0) even with an uninitialized or empty submodule directory.
result: pass
source: verified-by-agent
evidence: |
  - Static gate: run_verify() body extracted (320 non-comment lines) contains 0 references to 'vendor/dots-hyprland' and 0 to 'preflight'.
  - Section 7 assert: ran scratch fixture with committed .gitmodules and empty vendor/dots-hyprland directory; verify executed cleanly to exit 0.
coverage_id: D6
plan: 19-04
requirement: VER-03

### 3. Real-tree informational lines recognition
expected: Running `./arch/dots-hyprland.sh verify` reports `FAIL=0 FINDINGS=0` with known informational lines (uncommitted repo differences from HEAD such as config.fish, dolphinrc, kdeglobals; installer backup files; unclaimed upstream stubs; and non-repo dangling steam links) with zero unexpected failures or errors.
result: pass
source: human
reported: "Operator confirmed ./arch/dots-hyprland.sh verify run on live system: 123 [PASS] lines (94 repo-side + 29 sweep), 33 expected [INFO] lines, and summary === done: FAIL=0 FINDINGS=0 === with exit 0."
coverage_id: D9
plan: 19-04
requirement: VER-03

### 4. `verify` accepts exactly -h, --help, --strict, --quiet and refuses every other argument with exit 2, writing the reason on fd 2 and the summary line on neither stream
expected: `verify` accepts exactly -h, --help, --strict, --quiet and refuses every other argument with exit 2, writing the reason on fd 2 and the summary line on neither stream
result: pass
source: automated
coverage_id: D1
plan: 19-01
requirement: VER-03

### 5. A precondition failure exits 2 before the walk starts, printing one `[FAIL] precondition: <reason>` on fd 2 and no summary line
expected: A precondition failure exits 2 before the walk starts, printing one `[FAIL] precondition: <reason>` on fd 2 and no summary line
result: pass
source: automated
coverage_id: D2
plan: 19-01
requirement: VER-03

### 6. --strict changes only the exit code and --quiet removes only [PASS] lines; neither narrows what is examined
expected: --strict changes only the exit code and --quiet removes only [PASS] lines; neither narrows what is examined
result: pass
source: automated
coverage_id: D3
plan: 19-01
requirement: VER-03

### 7. The adversarial rsync-replace test: a stowed fixture passes, `rsync -a --delete` over it makes verify exit 1 naming the path with its `stow -t` recovery, and the identical run without the rsync exits 0
expected: The adversarial rsync-replace test: a stowed fixture passes, `rsync -a --delete` over it makes verify exit 1 naming the path with its `stow -t` recovery, and the identical run without the rsync exits 0
result: pass
source: automated
coverage_id: D4
plan: 19-01
requirement: VER-04

### 8. The D-26 guard is one callable function that provably refuses two real out-of-scratch targets and admits the in-scratch one, and is the sole gate the destructive command passes through
expected: The D-26 guard is one callable function that provably refuses two real out-of-scratch targets and admits the in-scratch one, and is the sole gate the destructive command passes through
result: pass
source: automated
coverage_id: D5
plan: 19-01
requirement: VER-04

### 9. A managed file whose ancestor directory is itself a symlink into the repo produces exactly one [FAIL] for that directory, carrying an unfold command, and not one [FAIL] per file underneath it
expected: A managed file whose ancestor directory is itself a symlink into the repo produces exactly one [FAIL] for that directory, carrying an unfold command, and not one [FAIL] per file underneath it
result: pass
source: automated
coverage_id: D1
plan: 19-02
requirement: VER-01

### 10. A declared live path that is a symlink whose target does not exist is [FAIL] when the unresolved target lands under the repo (PITFALLS A-6) and [INFO] otherwise, with the raw target read by a bare `readlink` and resolved manually
expected: A declared live path that is a symlink whose target does not exist is [FAIL] when the unresolved target lands under the repo (PITFALLS A-6) and [INFO] otherwise, with the raw target read by a bare `readlink` and resolved manually
result: pass
source: automated
coverage_id: D2
plan: 19-02
requirement: VER-01

### 11. The two new link checks do not fire on the real tree, which is measured to have zero folded ancestors and zero repo-bound dangling links
expected: The two new link checks do not fire on the real tree, which is measured to have zero folded ancestors and zero repo-bound dangling links
result: pass
source: automated
coverage_id: D3
plan: 19-02
requirement: VER-01

### 12. `git` is a declared required binary: its absence is a precondition failure with exit 2, decided before the walk starts (D-23)
expected: `git` is a declared required binary: its absence is a precondition failure with exit 2, decided before the walk starts (D-23)
result: pass
source: automated
coverage_id: D4
plan: 19-02
requirement: VER-01

### 13. A cp-through destruction is reported as a content observation, not a link failure: the link still [PASS]es, verify still exits 0, and the repo file's divergence from HEAD appears as [INFO] (D-27)
expected: A cp-through destruction is reported as a content observation, not a link failure: the link still [PASS]es, verify still exits 0, and the repo file's divergence from HEAD appears as [INFO] (D-27)
result: pass
source: automated
coverage_id: D5
plan: 19-02
requirement: VER-01

### 14. A stow/ or restow/ repo-side file that exists on disk but was never committed is reported as its own [INFO] class, distinct in wording from the differs-from-HEAD one (RESEARCH Pitfall 5)
expected: A stow/ or restow/ repo-side file that exists on disk but was never committed is reported as its own [INFO] class, distinct in wording from the differs-from-HEAD one (RESEARCH Pitfall 5)
result: pass
source: automated
coverage_id: D6
plan: 19-02
requirement: VER-01

### 15. The real tree's one measured divergence is reported honestly and moves nothing: stow/fish/.config/fish/config.fish is named on an [INFO] line while the run still ends FAIL=0 FINDINGS=0
expected: The real tree's one measured divergence is reported honestly and moves nothing: stow/fish/.config/fish/config.fish is named on an [INFO] line while the run still ends FAIL=0 FINDINGS=0
result: pass
source: automated
coverage_id: D7
plan: 19-02
requirement: VER-01

### 16. The live-side sweep derives 29 managed roots deterministically from the repo trees and emits exactly one directory-level line per root
expected: The live-side sweep derives 29 managed roots deterministically from the repo trees and emits exactly one directory-level line per root
result: pass
source: automated
coverage_id: D1
plan: 19-03
requirement: VER-01

### 17. Every live entry in a managed directory gets its verdict from one classifier; the five installer artifacts in $HOME and $HOME/.config stay visible and the two non-repo dangling links stay [INFO]
expected: Every live entry in a managed directory gets its verdict from one classifier; the five installer artifacts in $HOME and $HOME/.config stay visible and the two non-repo dangling links stay [INFO]
result: pass
source: automated
coverage_id: D2
plan: 19-03
requirement: VER-01

### 18. The two conditions the repo-side walk structurally cannot see — a stale link into the repo at an undeclared path, and a link dangling into the repo — are caught, together with the folded ancestor and the dangling-outside-repo control
expected: The two conditions the repo-side walk structurally cannot see — a stale link into the repo at an undeclared path, and a link dangling into the repo — are caught, together with the folded ancestor and the dangling-outside-repo control
result: pass
source: automated
coverage_id: D3
plan: 19-03
requirement: VER-01

### 19. An unreadable managed directory is [FAIL] naming the directory and moves the exit code to 1, never to 2
expected: An unreadable managed directory is [FAIL] naming the directory and moves the exit code to 1, never to 2
result: pass
source: automated
coverage_id: D4
plan: 19-03
requirement: VER-01

### 20. verify mutates nothing it inspects — the plan's stated prohibition, resolved by test
expected: verify mutates nothing it inspects — the plan's stated prohibition, resolved by test
result: pass
source: automated
coverage_id: D5
plan: 19-03
requirement: VER-01

### 21. capture/ content drift is a [FINDING] of its own class, never a [FAIL], and never moves the exit code on its own
expected: capture/ content drift is a [FINDING] of its own class, never a [FAIL], and never moves the exit code on its own
result: pass
source: automated
coverage_id: D1
plan: 19-04
requirement: VER-02

### 22. The two capture/ [FINDING] sources and the one capture/ [FAIL] are each proven from their own fixture
expected: The two capture/ [FINDING] sources and the one capture/ [FAIL] are each proven from their own fixture
result: pass
source: automated
coverage_id: D2
plan: 19-04
requirement: VER-02

### 23. A capture/ tree holding only README.md — the shape of the real tree today — produces no capture-tree line and cannot change the verdict; and capture-path listing order is stable across runs
expected: A capture/ tree holding only README.md — the shape of the real tree today — produces no capture-tree line and cannot change the verdict; and capture-path listing order is stable across runs
result: pass
source: automated
coverage_id: D3
plan: 19-04
requirement: VER-02

### 24. --strict exits 1 on a fixture that has findings and no failures, and the identical fixture exits 0 without the flag, with output byte-identical above the summary line
expected: --strict exits 1 on a fixture that has findings and no failures, and the identical fixture exits 0 without the flag, with output byte-identical above the summary line
result: pass
source: automated
coverage_id: D4
plan: 19-04
requirement: VER-03

### 25. Both branches of the installer's auto-backup primitive are covered, and they land on opposite sides of the link/content boundary
expected: Both branches of the installer's auto-backup primitive are covered, and they land on opposite sides of the link/content boundary
result: pass
source: automated
coverage_id: D5
plan: 19-04
requirement: VER-03

### 26. ROADMAP criterion 5 is CHECKED rather than asserted: a read-only run against the real $HOME after every fixture is torn down, failing only if it does not exit 0
expected: ROADMAP criterion 5 is CHECKED rather than asserted: a read-only run against the real $HOME after every fixture is torn down, failing only if it does not exit 0
result: pass
source: automated
coverage_id: D7
plan: 19-04
requirement: VER-03

### 27. The assert mutates nothing outside its own scratch, and the self-check that proves it covers every path the script creates
expected: The assert mutates nothing outside its own scratch, and the self-check that proves it covers every path the script creates
result: pass
source: automated
coverage_id: D8
plan: 19-04
requirement: VER-03

### 28. Wrapper drift detection is live again: `scripts/phase13-d19-assert.sh` Phase 19 tier pinned to 85dbfbc exits 0
expected: Wrapper drift detection is live again: `scripts/phase13-d19-assert.sh` Phase 19 tier pinned to 85dbfbc exits 0
result: pass
source: automated
coverage_id: D1
plan: 19-05
requirement: VER-01

### 29. Research record updated: `PITFALLS.md` entry A-6 carries Q3 atomic write analysis and findings
expected: Research record updated: `PITFALLS.md` entry A-6 carries Q3 atomic write analysis and findings
result: pass
source: automated
coverage_id: D2
plan: 19-05
requirement: VER-01

## Summary

total: 29
passed: 29
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

[none yet]
