---
phase: 06-runtime-failure-inventory
reviewed: 2026-04-21T00:00:00Z
depth: standard
files_reviewed: 1
files_reviewed_list:
  - scripts/nvim-audit-failures.sh
findings:
  critical: 1
  warning: 3
  info: 2
  total: 6
status: issues_found
---

# Phase 06: Code Review Report

**Reviewed:** 2026-04-21
**Depth:** standard
**Files Reviewed:** 1
**Status:** issues_found

## Summary

`scripts/nvim-audit-failures.sh` is a bash audit wrapper that orchestrates four data sources (nvim-validate.sh outputs, health JSON, log files, TODO/FIXME comments, and git history) and writes a deduplicated FAILURES.md report. The script uses `set -euo pipefail` correctly and follows generally safe quoting practices, but contains one shell-injection vulnerability in the `jq` filter construction, one broken git flag that silently disables the entire git-log scan, and several secondary logic issues. The git-log bug means the script produces no git-history findings even when bug-related commits exist.

---

## Critical Issues

### CR-01: Shell injection via unsanitized plugin name in jq filter string

**File:** `scripts/nvim-audit-failures.sh:75`
**Issue:** The variable `$name` — sourced from JSON parsed in an earlier `jq` invocation — is interpolated directly into a double-quoted `jq` filter string that is then evaluated by `jq` as code. If a plugin entry in `health.json` has a name containing a `"` character (e.g., `foo" | @base64 | ...`), the injected text becomes part of the jq program, enabling arbitrary jq expression execution. While jq does not execute shell commands, a crafted name could exfiltrate data or corrupt output. In adversarial or third-party plugin environments this is a real risk.

```bash
# Vulnerable (line 75):
err=$(jq -r ".plugins[] | select(.name == \"$name\") | .error" "$health_json" 2>/dev/null ...)

# Fix: use --arg to pass the value as a jq variable, never interpolate into the filter:
err=$(jq -r --arg n "$name" '.plugins[] | select(.name == $n) | .error' "$health_json" 2>/dev/null | head -1 | tr '\n' ' ' | head -c 100)
```

---

## Warnings

### WR-01: `--no-merges` is in the wrong position — git-log scan silently produces no output

**File:** `scripts/nvim-audit-failures.sh:150` and `scripts/nvim-audit-failures.sh:163`
**Issue:** The flag `--no-merges` is written as `git --no-merges log ...` on both lines. `--no-merges` is a subcommand option for `git log`, not a top-level `git` flag. Git will treat this as an unknown global option and exit non-zero. Because both invocations are guarded by `2>/dev/null` and `|| true` (or the outer `if ! ...`), the failure is silently swallowed. The practical effect is that `scan_git_log` always returns early (the `if !` check at line 150 evaluates false because git exits non-zero, so the function exits without producing any git findings). The entire git history scan is broken and produces no output.

```bash
# Broken (lines 150 and 163):
git --no-merges log --all --pretty="%s"

# Fix: move --no-merges after 'log':
git log --no-merges --all --pretty="%s"
```

### WR-02: Line number silently dropped in `scan_todo_fixme` — grep `-n` output not parsed

**File:** `scripts/nvim-audit-failures.sh:123-124`
**Issue:** `grep -Hn` produces output in the format `file:linenum:matched-text`. The parsing uses `cut -d: -f1` for the file (correct) and `cut -d: -f3-` for the text (skips field 2, the line number). The line number is silently discarded and never emitted into the output record. Downstream consumers of the FAILURES.md table receive no location information for TODO/FIXME items, making them harder to act on. The variable `file` is also extracted but never used in the `echo` on line 140 — only `$text` and `$owner` appear.

```bash
# Fix: parse and emit the line number, and include file in the output record:
local file linenum text owner
file=$(echo "$line" | cut -d: -f1)
linenum=$(echo "$line" | cut -d: -f2)
text=$(echo "$line" | cut -d: -f3-)
# ... then include in echo:
echo "$text|$owner|TODO/FIXME at $file:$linenum|todo"
```

### WR-03: `xargs` used for trimming corrupts keys containing quotes

**File:** `scripts/nvim-audit-failures.sh:228`
**Issue:** `xargs` (without a command) is used to trim and normalize whitespace in the deduplication key. While this works for typical input, `xargs` interprets single quotes, double quotes, and backslashes as shell quoting metacharacters. A description containing `it's` or `"quoted"` will cause `xargs` to either mangle the key or emit an error (`xargs: unmatched single quote`), breaking deduplication silently. This is plausible given that log error messages and git commit subjects routinely contain these characters.

```bash
# Vulnerable (line 228):
key=$(echo "$description | $owner" | tr '[:upper:]' '[:lower:]' | xargs)

# Fix: use parameter expansion or sed for trimming instead of xargs:
key=$(echo "$description | $owner" | tr '[:upper:]' '[:lower:]' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
```

---

## Info

### IN-01: Dead conditional — `status` variable is always "Discovered"

**File:** `scripts/nvim-audit-failures.sh:235-239`
**Issue:** `status` is set to `"Discovered"` on line 235. The `if` block on lines 237-239 conditionally sets it to `"Discovered"` again. The branch never changes the value. This appears to be incomplete logic where different provenances were intended to produce different status values (e.g., `"Confirmed"` for health/smoke/startup sources vs `"Discovered"` for git/todo sources). As written, all entries always get `"Discovered"` regardless of provenance.

```bash
# Current dead code:
local status="Discovered"
if [[ "$provenance" == *"health"* ]] || [[ "$provenance" == *"smoke"* ]] || [[ "$provenance" == *"startup"* ]]; then
    status="Discovered"   # identical — no-op
fi

# Likely intended (example):
local status="Inferred"
if [[ "$provenance" == *"health"* ]] || [[ "$provenance" == *"smoke"* ]] || [[ "$provenance" == *"startup"* ]]; then
    status="Discovered"
fi
```

### IN-02: `stderr` from `nvim-validate.sh` is fully suppressed — loses diagnostic signal

**File:** `scripts/nvim-audit-failures.sh:264-267`
**Issue:** All four `nvim-validate.sh` invocations redirect stderr to `/dev/null`. When a check fails the script prints a generic `NOTE:` message but discards the actual error output. During debugging this makes it very difficult to understand why a check failed. Consider redirecting stderr to a log file rather than discarding it entirely.

```bash
# Current (discards all error detail):
"$SCRIPT_DIR/nvim-validate.sh" startup 2>/dev/null || echo "NOTE: startup check had issues"

# Suggested (preserve errors in a log):
local validate_log="$OUTPUT_DIR/validate-errors.log"
"$SCRIPT_DIR/nvim-validate.sh" startup 2>>"$validate_log" || echo "NOTE: startup check had issues (see $validate_log)"
```

---

_Reviewed: 2026-04-21_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
