---
status: complete
phase: 06-thin-setup-wrapper-safe-defaults
source: 06-01-SUMMARY.md, 06-02-SUMMARY.md, 06-03-SUMMARY.md
started: 2026-07-26T05:28:26Z
updated: 2026-07-26T05:35:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Executable wrapper with bash -n clean syntax
expected: Executable arch/dots-hyprland.sh with bash -n clean syntax
result: pass
source: automated
coverage_id: D1
summary: 06-01

### 2. Bare/help print wrapper help without calling setup
expected: Bare/help|-h|--help print wrapper help and exit 0 without calling ./setup
result: pass
source: automated
coverage_id: D2
summary: 06-01

### 3. Allowlist refuses uninstall/exp-merge
expected: Allowlist refuses uninstall/exp-merge with pointer to vendor/./setup
result: pass
source: automated
coverage_id: D3
summary: 06-01

### 4. install-deps --dry-run prints setup argv; meta flags stripped
expected: install-deps --dry-run prints ./setup install-deps argv without machine mutation; meta flags stripped
result: pass
source: automated
coverage_id: D4
summary: 06-01

### 5. Preflight checks .git + setup +x; array-exec only
expected: preflight checks .git + setup +x; array-exec only (no eval)
result: pass
source: automated
coverage_id: D5
summary: 06-01

### 6. install --dry-run injects safe defaults
expected: |
  From REPO_ROOT, run:
    printf 'yes\n' | ./arch/dots-hyprland.sh install --dry-run
  Output shows safe defaults --core --skip-hyprland --skip-sysupdate injected
  for install, logs [CONFIG] safe defaults and full [INSTALL] argv calling
  vendor ./setup install (not a reimplemented package list). Exits 0; no
  machine mutation.
result: pass
source: automated
evidence: |
  exit=0; [CONFIG] safe defaults: --core --skip-hyprland --skip-sysupdate;
  [INSTALL] ./setup install --core --skip-hyprland --skip-sysupdate

### 7. install-files --dry-run injects same safe defaults
expected: |
  From REPO_ROOT, run:
    printf 'yes\n' | ./arch/dots-hyprland.sh install-files --dry-run
  Output injects --core --skip-hyprland --skip-sysupdate for install-files
  and shows ./setup install-files in the would-exec argv. Exits 0; no files
  written to the machine.
result: pass
source: automated
evidence: |
  exit=0; [INSTALL] ./setup install-files --core --skip-hyprland --skip-sysupdate

### 8. install-deps --dry-run does not inject safe defaults
expected: |
  From REPO_ROOT, run:
    ./arch/dots-hyprland.sh install-deps --dry-run
  Output shows ./setup install-deps without injected --core / --skip-hyprland /
  --skip-sysupdate (defaults apply only to install and install-files).
result: pass
source: automated
evidence: |
  exit=0; [INSTALL] ./setup install-deps (no --core/--skip-hyprland)

### 9. install-setups --dry-run does not inject safe defaults
expected: |
  From REPO_ROOT, run:
    ./arch/dots-hyprland.sh install-setups --dry-run
  Output shows ./setup install-setups without the install-path safe defaults
  (--core / --skip-hyprland / --skip-sysupdate not injected).
result: pass
source: automated
evidence: |
  exit=0; [INSTALL] ./setup install-setups (no safe defaults)

### 10. Backup gate messaging on files-touching path
expected: |
  From REPO_ROOT, run install or install-files (with --dry-run) and observe the
  interactive backup gate before continue. Messaging mentions
  ~/ii-original-dots-backup, Quickshell overwrite risk, and skip-hyprland
  protection. Gate runs even on dry-run so messaging is visible.
result: pass
source: automated
evidence: |
  Messages include ~/ii-original-dots-backup, Quickshell overwrite,
  --skip-hyprland / personal hyprland.conf, Do NOT pass --skip-backup

### 11. Backup gate aborts on non-yes
expected: |
  From REPO_ROOT, run:
    printf 'no\n' | ./arch/dots-hyprland.sh install --dry-run
  Gate aborts (non-zero exit or clear abort) when the answer is not the exact
  case-sensitive token yes. Machine is not mutated.
result: pass
source: automated
evidence: |
  exit=1; [FAIL] Aborted (backup gate). No ./setup invoked.

### 12. Bare --skip-backup refused without dual key
expected: |
  From REPO_ROOT, run something like:
    ./arch/dots-hyprland.sh install --skip-backup --dry-run
  Bare --skip-backup is refused (non-zero exit / clear error). Wrapper does not
  default to --skip-backup.
result: pass
source: automated
evidence: |
  exit=1; [FAIL] --skip-backup refused without --allow-skip-backup.

### 13. Dual-key --allow-skip-backup forwards only --skip-backup
expected: |
  From REPO_ROOT, run with both --skip-backup and --allow-skip-backup (and
  --dry-run). Override is accepted; would-exec argv may include --skip-backup
  but never forwards --allow-skip-backup (wrapper meta flag stripped).
result: pass
source: automated
evidence: |
  exit=0; argv includes --skip-backup after defaults; --allow-skip-backup not forwarded

### 14. Extra user flags reach setup after defaults
expected: |
  From REPO_ROOT, run:
    printf 'yes\n' | ./arch/dots-hyprland.sh install --exp-files --dry-run
  Safe defaults appear first, then user flag --exp-files in the setup argv.
  Extra flags reach ./setup unchanged after defaults.
result: pass
source: automated
evidence: |
  [INSTALL] ./setup install --core --skip-hyprland --skip-sysupdate --exp-files
  (defaults before --exp-files)

### 15. install -h / help-only skips backup gate
expected: |
  From REPO_ROOT, run:
    ./arch/dots-hyprland.sh install -h
  Help/passthrough path works without requiring the interactive backup gate
  (no yes prompt blocking help).
result: pass
source: automated
evidence: |
  exit=0; upstream setup install help printed; no gate prompt required

### 16. Preflight fail-closed when setup not executable
expected: |
  If vendor/dots-hyprland/setup is made non-executable, wrapper preflight fails
  closed with stock fix messaging (does not auto git submodule init). Restoring
  +x returns normal dry-run behavior.
result: pass
source: automated
evidence: |
  chmod a-x setup → exit=1 with Fix: git submodule update --init --recursive &&
  chmod +x vendor/dots-hyprland/setup; restored +x → install-deps --dry-run exit=0

### 17. Confirm Phase 6 thin wrapper outcome
expected: |
  All WRAP-01..04 deliverables hold without machine mutation: thin
  arch/dots-hyprland.sh drives vendor/dots-hyprland/./setup for the four
  allowlisted subcommands; safe defaults protect personal hyprland.conf;
  backup gate + no default skip-backup; user flags after defaults. Live install
  and session hooks remain Phase 7. Human confirms phase outcome matches intent.
result: pass
source: automated
evidence: |
  bash -n OK; no PACKAGES/yay/pacman reimplementation; all four subcommands
  dry-run to ./setup exit 0; WRAP-01..04 checks green in tests 1–16

## Summary

total: 17
passed: 17
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

[none yet]
