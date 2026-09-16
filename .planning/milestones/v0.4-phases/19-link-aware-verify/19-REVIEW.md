---
phase: 19-link-aware-verify
reviewed: 2026-09-14T13:25:00+06:00
depth: standard
files_reviewed: 3
files_reviewed_list:
  - arch/dots-hyprland.sh
  - scripts/phase13-d19-assert.sh
  - scripts/phase19-link-aware-verify-assert.sh
findings:
  critical: 0
  warning: 2
  info: 3
  total: 5
status: issues_found
---

# Phase 19: Code Review Report

**Reviewed:** 2026-09-14T13:25:00+06:00  
**Depth:** standard  
**Files Reviewed:** 3  
**Status:** issues_found  

## Summary

Advisory code review for Phase 19 ("Link-aware verify"). Source code changes reviewed:
- `arch/dots-hyprland.sh`: `run_verify()` flags, preconditions, repo-side link & content checks, and live-side sweep pass
- `scripts/phase13-d19-assert.sh`: Phase 19 marker and drift pin update
- `scripts/phase19-link-aware-verify-assert.sh`: 1,732-line test harness covering criteria 1 through 5

The implementation across Phase 19 is well-engineered, with robust defensive programming (e.g. `realpath -m --` canonicalization, quoted case patterns, `find ... -print0` handling, and thorough leak self-checks). No security vulnerabilities or critical blockers were identified. Two warnings were found: one regarding `get_main_repo_root()` sensitivity to the caller's working directory (causing 94 false failures when executed from a foreign git repo), and one regarding live-side sweep handling of folded directories and declared files. Three informational suggestions cover recovery text accuracy and test harness robustness.

## Critical Issues

*No critical issues found.*

## Warnings

### WR-01: `get_main_repo_root()` omits `-C "$REPO_ROOT"`, causing 94 false failures when invoked from another git repository

**File:** `arch/dots-hyprland.sh:723`  
**Issue:** `get_main_repo_root()` runs `git rev-parse --path-format=absolute --git-common-dir` against the process current working directory (`pwd`) rather than `$REPO_ROOT`:
```bash
get_main_repo_root() {
  local common_dir
  if common_dir="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)"; then
    dirname "$common_dir"
  else
    printf '%s\n' "$REPO_ROOT"
  fi
}
```
If `arch/dots-hyprland.sh verify` is invoked while the shell's current working directory is inside another git repository (e.g. `cd /path/to/other_repo && ~/.dotfiles/arch/dots-hyprland.sh verify`), `git rev-parse` succeeds against the foreign repo and sets `main_root` to `/path/to/other_repo`. Consequently:
1. `canonical_repo` points to non-existent paths under the foreign repository.
2. `repo_target="$(readlink -f -- "$canonical_repo" || true)"` evaluates to `""`.
3. Every live symlink check fails with `[FAIL] symlink points elsewhere: ... (expected )`, reporting `FAIL=94 FINDINGS=0`.
4. Subsequent git diff calls (`git -C "$main_root" diff --quiet HEAD -- "$repo_rel"`) target the foreign repository.

**Fix:** Pass `-C "$REPO_ROOT"` to ensure `git rev-parse` queries the repository containing the script:
```bash
get_main_repo_root() {
  local common_dir
  if common_dir="$(git -C "$REPO_ROOT" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)"; then
    dirname "$common_dir"
  else
    printf '%s\n' "$REPO_ROOT"
  fi
}
```

---

### WR-02: Live-side sweep emits `[PASS]` for folded directories and labels declared files as `unclaimed upstream stub`

**File:** `arch/dots-hyprland.sh:1297-1304`, `1328-1348`  
**Issue:** When a managed directory is folded (i.e. the directory itself is a symlink into the repo), the repo-side walk correctly reports `[FAIL] folded ancestor directory: <dir> -> <target>`. However, during the live-side sweep:
1. At line 1328, `[[ ! -d "$sweep_root" ]]` follows symlinks, so it evaluates to false. It then executes line 1347: `pass "managed directory: $sweep_root"`, emitting a `[PASS]` for the folded directory that just failed.
2. At line 1363, `find "$sweep_root" -mindepth 1 -maxdepth 1` enumerates the files inside the folded directory. Because the directory is linked rather than individual files, `[[ -L "$entry" ]]` is false and `[[ -f "$entry" ]]` is true. In non-shared roots, this reaches Arm 7:
```bash
info "unclaimed upstream stub: $entry"
```
This classifies the repository's own declared files (`declared_live[$entry]` is 1) as "unclaimed upstream stubs".

**Fix:** In `classify_sweep_entry()` Arm 7, skip or reclassify entries that are present in `declared_live`:
```bash
      if [[ -n "${declared_live[$entry]:-}" ]]; then
        return 0
      fi
      info "unclaimed upstream stub: $entry"
      return 0
```
Additionally, consider suppressing `pass "managed directory:"` when `$sweep_root` is a symlink into the repository.

---

## Info

### IN-01: Folded ancestor remediation message attributes folding to loop package variable

**File:** `arch/dots-hyprland.sh:978`  
**Issue:** When reporting a folded ancestor directory:
```bash
fail "folded ancestor directory: $cur -> $ancestor_target — unfold with: cd $tree && stow -D --no-folding -t ~ $pkg && stow --no-folding -t ~ $pkg"
```
The `$pkg` token is taken directly from the outer loop iteration (`for pkg_dir in "$tree_dir"/*`). If multiple packages share directory hierarchy and package A was folded while package B is currently being checked, the message instructs the operator to restow package B rather than package A.  
**Fix:** Parse the actual package name from `$ancestor_target` (e.g. `${ancestor_target#"$main_root_real/$tree/"}`, taking the first path component) to ensure the recovery command always names the folded package.

---

### IN-02: Assert harness encodes workaround for `get_main_repo_root()` working-directory sensitivity

**File:** `scripts/phase19-link-aware-verify-assert.sh:292-302`  
**Issue:** In `run_fixture_verify`, the harness explicitly enforces `cd "$RUN_REPO"` and notes:
```bash
# All THREE roots must be satisfied at once, because REPO_ROOT comes from the
# copied script's own BASH_SOURCE and main_root comes from `git rev-parse` run
# in the caller's cwd, and NEITHER follows $HOME (RESEARCH Pitfall 1):
#   1. HOME points at the scratch home
#   2. the wrapper invoked is the copy inside the scratch repo
#   3. the invocation's cwd is that scratch repo
#
# Symptoms of a mis-wired harness, as opposed to a real defect in the code
# under test: a FAIL count near 94 on a fixture that stages one file, and a
# [FAIL] line reading `(expected )` with nothing after `expected`.
```
The harness accommodated the working-directory sensitivity of `get_main_repo_root()` rather than testing that `arch/dots-hyprland.sh verify` functions regardless of the caller's working directory.  
**Fix:** When fixing WR-01, add a test case running `verify` from outside `$REPO_ROOT` to ensure directory independence.

---

### IN-03: Signal handling in assert cleanup trap

**File:** `scripts/phase19-link-aware-verify-assert.sh:141`  
**Issue:** The assert script installs `trap cleanup EXIT` at line 141. If the script is aborted early via `SIGINT` (Ctrl+C) or `SIGTERM`, bash does not consistently execute an EXIT trap across all subshells and termination modes, potentially leaving temporary scratch fixtures under `/tmp/p19-*`.  
**Fix:** Trap `INT` and `TERM` signals in addition to `EXIT`:
```bash
trap cleanup EXIT INT TERM
```

---

_Reviewed: 2026-09-14T13:25:00+06:00_  
_Reviewer: Claude (gsd-code-reviewer)_  
_Depth: standard_  
