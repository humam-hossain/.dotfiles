# Phase 16: Retire the safe profile: full-only wrapper and playbook - Pattern Map

**Mapped:** 2026-09-07
**Files analyzed:** 14 (1 new, 11 modified, 2 deleted)
**Analogs found:** 12 / 12 non-deleted

This is a shell/dotfiles repo, not an application codebase. "Role" below is read
in this repo's own vocabulary: assert-script, operator-doc, wrapper-script,
planning-artifact. Every analog path was checked with `git ls-files` and is
tracked source — no gitignored mirrors.

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `scripts/phase16-*-assert.sh` (**new**) | assert-script | batch (dry-run argv capture + grep) | `scripts/phase12-full-smoke.sh` | exact |
| `scripts/phase16-*-assert.sh` (doc ban-grep half) | assert-script | transform (file → grep verdict) | `scripts/phase10-inventory-assert.sh:211-217` (D-15 chrome ban) | exact |
| `scripts/phase12-full-smoke.sh` (rewritten body) | assert-script | batch | itself (structure kept, assertions inverted) | exact |
| `scripts/phase13-d19-assert.sh` (3rd tier + W-3) | assert-script | batch + git-drift | itself `:96,:146-158` (two-tier precedent) | exact |
| `scripts/phase13-d19-assert.sh` (W-3 fence diff) | assert-script | transform (markdown → fence → diff) | itself `:28-53` (python3 fence extractor) | exact |
| `scripts/phase14-verify.sh` (D-37 deletions) | assert-script | request-response (live probes) | itself `:370-420` | exact |
| `arch/dots-hyprland.sh` (deletion refactor) | wrapper-script | request-response (argv → exec) | itself `:1400-1495` `run_install_family` | exact (self-surgery) |
| `docs/dots-hyprland-workflow.md` | operator-doc | narrative | itself, as rewritten in Phase 15 | exact |
| `docs/phase14-adopt-runbook.md` | operator-doc (historical) | narrative | itself | exact |
| `16-DOC-SWEEP.md` (**new**) | planning-artifact / marker | record | `.planning/phases/15-playbook-safe-vs-full/15-DOC-SWEEP.md` | exact |
| `.planning/REQUIREMENTS.md`, `ROADMAP.md`, `PROJECT.md`, `STATE.md`, `v0.3-MILESTONE-AUDIT.md` | planning-artifact | record | `15-DOC-SWEEP.md` "Flagged, not edited" + "Corrections applied" tables | role-match |
| `.planning/phases/11-.../11-DISPOSITIONS.md` (W-1, W-2) | planning-artifact (frozen, overridden) | record | constrained by `scripts/phase11-dispositions-assert.sh:129-142,164-190` | n/a — constraint, not analog |
| `scripts/phase07-live-smoke.sh`, `scripts/phase14-preflight.sh` | deleted | — | — | n/a |

---

## Pattern Assignments

### `scripts/phase16-*-assert.sh` (NEW — assert-script, batch)

**Analog:** `scripts/phase12-full-smoke.sh` (163 lines, read in full)

This is the single highest-value pattern in the phase. The new script must be
structurally indistinguishable from the analog.

**Preamble — copy verbatim, changing only the header comment and phase number**
(`scripts/phase12-full-smoke.sh:1-16`):

```bash
#!/usr/bin/env bash
# Phase 12 FULL-01..05 automated smoke asserts (Nyquist validation).
# Non-mutating only: help / --dry-run / refuse / syntax. Never runs live install --full.
#
# Usage (from REPO_ROOT):
#   ./scripts/phase12-full-smoke.sh
# Exit 0 if all hard asserts pass; non-zero if any hard FAIL.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

FAIL=0
pass() { printf '[PASS] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
```

This exact `FAIL` / `pass()` / `fail()` triple is byte-identical in
`phase10-inventory-assert.sh:27-30`, `phase11-dispositions-assert.sh:28-30`,
`phase12-full-smoke.sh:14-16` and `phase13-d19-assert.sh:14-16`. Do not invent a
variant. `phase14-verify.sh:35-40` extends it with `finding()` / `info()`; the
new phase16 assert has no findings tier and must not add one.

**Tempfile + trap pattern** (`scripts/phase12-full-smoke.sh:18-26`):

```bash
WRAP="./arch/dots-hyprland.sh"
HELP_OUT="$(mktemp /tmp/p12-smoke-help-XXXXXX)"
FULL_OUT="$(mktemp /tmp/p12-smoke-full-XXXXXX)"
FILES_OUT="$(mktemp /tmp/p12-smoke-files-XXXXXX)"
# shellcheck disable=SC2064
trap 'rm -f "$HELP_OUT" "$FULL_OUT" "$FILES_OUT"' EXIT

echo "=== Phase 12 full-profile smoke (FULL-01..05, non-mutating) ==="
```

Note the `# shellcheck disable=SC2064` comment survives even though shellcheck
is not installed — it is repo convention, keep it.

**Syntax gate — first assert in the file** (`scripts/phase12-full-smoke.sh:30-35`):

```bash
if bash -n arch/dots-hyprland.sh; then
  pass "syntax: bash -n arch/dots-hyprland.sh"
else
  fail "syntax: bash -n arch/dots-hyprland.sh"
fi
```

**Dry-run argv capture — the core D-35 pattern.** The analog at
`scripts/phase12-full-smoke.sh:62-92` is the shape to invert. Note three things
the new script must preserve: `printf 'yes\n' |` feeds the gate (after D-09 the
gate is gone, so this pipe becomes unnecessary — but leaving it is harmless and
keeps the idiom), the run is wrapped in `if …; then` so a non-zero exit is its
own `fail`, and every failure branch dumps context with `sed -n '1,40p'`:

```bash
if printf 'yes\n' | "$WRAP" install --full --dry-run >"$FULL_OUT" 2>&1; then
  if grep -q 'would exec' "$FULL_OUT"; then
    pass "FULL-04 full dry-run prints would-exec"
  else
    fail "FULL-04 full dry-run missing would-exec"
    sed -n '1,40p' "$FULL_OUT" || true
  fi
  if grep -q -- '--skip-hyprland' "$FULL_OUT"; then
    fail "FULL-01 full dry-run leaked --skip-hyprland"
  else
    pass "FULL-01 full dry-run omits --skip-hyprland"
  fi
  if grep -E -- '(^|[[:space:]])--core([[:space:]]|$)' "$FULL_OUT" >/dev/null; then
    fail "FULL-01 full dry-run leaked standalone --core"
  else
    pass "FULL-01 full dry-run omits standalone --core"
  fi
  if grep 'would exec' "$FULL_OUT" | grep -q -- '--full'; then
    fail "FULL-01 would-exec line still has meta --full"
  else
    pass "FULL-01 would-exec strips meta --full"
  fi
else
  fail "FULL-04 install --full --dry-run exited non-zero"
  sed -n '1,40p' "$FULL_OUT" || true
fi
```

Two details are load-bearing and must carry into the phase16 assert:
- `--core` is matched with a **word-boundary ERE**, not `grep -q -- '--core'`,
  because `--core` is a substring of nothing here but `--skip-...` flags are
  substring-safe while `--core` is not. Reuse the exact ERE.
- The "meta flag not forwarded" assert is `grep 'would exec' … | grep -q -- '--full'`
  — it greps **only the would-exec line**, not the whole capture, because the
  wrapper legitimately prints `--full` in its own note lines. D-35's "`--full`
  is not forwarded to `./setup`" assert must use this two-stage grep, otherwise
  the D-05 ignored-note itself fails the check.

**Non-zero-exit assert (refusal shape)** (`scripts/phase12-full-smoke.sh:122-127`):

```bash
if "$WRAP" install --full --skip-backup --dry-run >/tmp/p12-smoke-skip.txt 2>&1; then
  fail "FULL-03 install --full --skip-backup --dry-run should exit non-zero"
else
  pass "FULL-03 bare --skip-backup on full refused"
fi
```

The phase16 assert has no refusals left to check (D-04 deletes the `--full`
scope check, D-06 deletes the `--skip-backup` refusal), so this shape is the one
block **not** carried over. Recorded here so the planner recognizes it as a
deliberate omission rather than an oversight.

**Summary footer — copy verbatim** (`scripts/phase12-full-smoke.sh:159-163`):

```bash
echo "=== done: FAIL=${FAIL} ==="
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
```

`phase11-dispositions-assert.sh` uses the same footer plus one extra
`printf 'phase11 dispositions asserts OK\n'` line before `exit 0`.
`phase13-d19-assert.sh` uses a variant (`=== Phase 13 asserts: FAIL=$FAIL ===`
printed in both branches). **Use the `phase12` form** — the new script is
declared to be in `phase12`'s evidence shape (D-35).

---

### `scripts/phase16-*-assert.sh` — doc forbidden-string half (D-36)

**Analog:** `scripts/phase10-inventory-assert.sh:211-217`

The ban-grep idiom already exists and is exactly what D-36 describes:
fail-if-present, dump the offending lines, never require anything.

```bash
# --- D-15 chrome ban (waybar|rofi|swaync) ---
if grep -niE '\bwaybar\b|\brofi\b|\bswaync\b' "$INVENTORY" >/dev/null; then
  fail "D-15 dual-run chrome (waybar|rofi|swaync) must be omitted"
  grep -niE '\bwaybar\b|\brofi\b|\bswaync\b' "$INVENTORY" || true
else
  pass "D-15 no waybar/rofi/swaync"
fi
```

Copy this shape for the D-36 bans on `docs/dots-hyprland-workflow.md`: no
`--skip-hyprland` in §10, no "dual-run", no "safe profile". Note the double
grep (once for the verdict, once to print evidence) with `|| true` on the second
— that `|| true` is required under `set -e`.

**Inverse — the "required token" loop** the phase16 assert must NOT use on
`docs/`, but which the planner must keep green elsewhere
(`scripts/phase11-dispositions-assert.sh:129-135`, the W-1 rewrite constraint):

```bash
for tok in --core --skip-hyprland --skip-sysupdate; do
  if grep -qF -- "$tok" "$DISP"; then
    pass "residual token $tok present"
  else
    fail "residual token $tok missing"
  fi
done
```

and the D-10 residual-language regex the W-1 rewrite must not break
(`scripts/phase11-dispositions-assert.sh:138-142`):

```bash
if grep -qiE '(remains|still|unchanged|default).{0,100}(SAFE_DEFAULTS|safe|residual|dual-run)|(SAFE_DEFAULTS|safe|residual|dual-run).{0,100}(remains|still|unchanged|default)' "$DISP"; then
  pass "D-10 residual/default still-safe language"
else
  fail "D-10 residual/default still-safe language missing"
fi
```

Same pattern guards `10-INVENTORY.md` at `scripts/phase10-inventory-assert.sh:136`
(D-39 leaves it alone).

---

### `scripts/phase13-d19-assert.sh` — third baseline tier (D-38 part 1)

**Analog:** the file's own two-tier block, `scripts/phase13-d19-assert.sh:96,140-158`:

```bash
LIVE_VERIFY=".planning/phases/14-live-full-adopt-verify/14-LIVE-VERIFY.md"
...
# Bare `git diff` compares worktree against index only, so a committed change is
# invisible to it -- arch/dots-hyprland.sh was modified during phase 14 and still
# passed this check. Compare against a pinned known-good commit instead.
#
# Which commit is the baseline is phase-dependent. Phase 13 wanted the wrapper
# untouched since phase 12. Phase 14 then changed it deliberately under D-28, so
# after that phase the known-good state is 14c6828, not e7e4e9f. Pinning both
# keeps drift detection live without asserting a premise the project has moved past.
if [ -f "$LIVE_VERIFY" ]; then
  WRAPPER_BASE="14c6828"   # refactor(14-01): drop waybar and swaync from PROTECT_EXPLICIT (D-28)
else
  WRAPPER_BASE="e7e4e9f"   # feat(12-03): last phase-12 state of the wrapper
fi
if ! git cat-file -e "${WRAPPER_BASE}^{commit}" 2>/dev/null; then
  printf '[INFO] %s\n' "arch/dots-hyprland.sh: baseline $WRAPPER_BASE not in this repo; drift not checked"
elif [ -z "$(git diff --name-only "$WRAPPER_BASE" -- arch/dots-hyprland.sh)" ]; then
  pass "arch/dots-hyprland.sh unmodified since $WRAPPER_BASE"
else
  fail "arch/dots-hyprland.sh changed since $WRAPPER_BASE"
fi
```

**Pattern to copy for the third tier:** declare a `DOC_SWEEP16=".planning/phases/16-.../16-DOC-SWEEP.md"`
path constant next to `LIVE_VERIFY`, then make it the **first** branch of the
if/elif chain (research: `14-LIVE-VERIFY.md` still exists, so an `elif` placed
after it never fires), and carry a same-line `#` comment naming the commit
subject exactly as the two existing pins do. The `git cat-file -e` /
`git diff --name-only` verdict block below is untouched.

Note this file uses `[ ... ]` / `[ -f ... ]` POSIX test throughout, not
`[[ ... ]]` — match the file's local style, which differs from `phase12`'s
`[[ "$FAIL" -gt 0 ]]` footer.

### `scripts/phase13-d19-assert.sh` — W-3 fence drift (D-38 part 2)

**Analog:** the existing python3 fence extractor in the same file, `:27-53`:

```bash
FENCE="$(python3 - "$SOT" <<'PY'
from pathlib import Path
import sys
text = Path(sys.argv[1]).read_text()
idx = text.find("## In-repo verify (D-19)")
if idx < 0:
    raise SystemExit("D-19 heading missing")
rest = text[idx:]
start = rest.find("```bash")
end = rest.find("```", start + 7)
if start < 0 or end < 0:
    raise SystemExit("D-19 bash fence missing")
print(rest[start + 7:end].lstrip("\n"), end="")
PY
)"
if [ -z "$FENCE" ]; then
  fail "extract D-19 fence from $SOT"
else
  TMP="$(mktemp /tmp/p13-d19-XXXXXX.sh)"
  printf '%s' "$FENCE" >"$TMP"
  if bash -e "$TMP"; then
    pass "D-19 fence bash -e (extracted from 13-SOT-APPLY.md)"
  else
    fail "D-19 fence bash -e (extracted from 13-SOT-APPLY.md)"
  fi
  rm -f "$TMP"
fi
```

**Apply:** parameterize this heredoc over (file, heading) so it runs twice — once
against `13-SOT-APPLY.md`, once against `docs/dots-hyprland-workflow.md` §6 —
then `diff` the two extractions. Research (§Don't Hand-Roll) locks this: do not
add an `awk`/`sed` second extraction idiom, and do not hand-transcribe the fence
into the assert. The `mktemp` + `printf '%s'` + `bash -e` + `rm -f` execution
half stays as-is for the SoT fence only.

The `cmp -s` file-comparison idiom already in this file
(`scripts/phase13-d19-assert.sh:108-114`) is the fallback shape if the fences
are compared as files rather than strings.

---

### `scripts/phase12-full-smoke.sh` (rewritten body — D-34)

**Analog:** itself. Preamble (`:1-33`) and footer (`:159-163`) survive
unchanged; only the assertion bodies flip. Concrete mapping of what to invert:

| Current block | Line | New meaning |
|---|---|---|
| `FULL-01 help lists --full` | `:37-47` | help still lists `--full`, now documented as an ignored no-op alias (D-05) |
| `FULL-01/04 full dry-run argv` | `:62-92` | keep verbatim — the four omission greps are now true of **every** invocation, not just `--full` |
| `FULL-02 safe residual still injected` | `:96-106` | **invert**: bare `install --dry-run` must now omit all three |
| `FULL-02b install-files residual` | `:109-119` | **invert**: bare `install-files --dry-run` must omit `--skip-hyprland` |
| `FULL-03 bare skip-backup refuse` | `:122-127` | **delete** — refusal removed by D-06 |
| `FULL-03b dual-key allow` | `:130-141` | **delete** — `--allow-skip-backup` removed by D-06 |
| `FULL-05 protect + ii hooks plan` | `:144-150` | **invert to ban**: dry-run must NOT mention `protect-list` or `ii hooks` |
| `D-02 --full refused on install-deps` | `:153-158` | **invert**: `--full` on `install-deps` now exits 0 with the ignored-note |

---

### `scripts/phase14-verify.sh` (D-37 deletions)

**Analog:** itself. The blocks D-37 names all follow one shape
(`scripts/phase14-verify.sh:374-391`):

```bash
if [[ -d "$BACKUP_DIR" ]] && [[ -n "$(ls -A "$BACKUP_DIR" 2>/dev/null || true)" ]]; then
  pass "ADOPT-04 tier-1 source 3 present and non-empty: $BACKUP_DIR"
else
  fail "ADOPT-04 tier-1 source 3 missing or empty: $BACKUP_DIR"
fi

if printf '' | "$WRAP" uninstall --dry-run >"$UNINST_OUT" 2>&1; then
  pass "ADOPT-04 tier 2 reachable: uninstall --dry-run exits 0"
else
  fail "ADOPT-04 tier 2 unreachable: uninstall --dry-run exited non-zero"
  sed -n '1,40p' "$UNINST_OUT" || true
fi
if printf '' | "$WRAP" protect --dry-run >"$PROTECT_OUT" 2>&1; then
  pass "ADOPT-04 tier 3 reachable: protect --dry-run exits 0"
else
  fail "ADOPT-04 tier 3 unreachable: protect --dry-run exited non-zero"
  sed -n '1,40p' "$PROTECT_OUT" || true
fi
```

Keep the middle block (uninstall), delete the first and third, and delete the
`D-36` sha256/mtime block at `:394-420`. **Set -u hazard:** `BACKUP_DIR` is
defined at `scripts/phase14-verify.sh:45` and `PROTECT_OUT` is an mktemp'd
tempfile in the trap list — after deleting all readers, remove the definitions
and the trap entries too, or leave them; an unused variable is safe under
`set -u`, an unset one is not. Verify `baseline_value backup_dir_hyprland_conf_mtime`
has no remaining caller before removing it.

**Clean-tree assert that gates the whole phase** (`scripts/phase14-verify.sh:538-560`)
— the `PHASE14_PREFIX` allowance is hard-coded to Phase 14's directory, so the
D-40 gate can only run on a committed tree:

```bash
PHASE14_PREFIX=".planning/phases/14-live-full-adopt-verify/"
PORCELAIN_ALL="$(git status --porcelain || true)"
...
if [[ -z "${DIRTY_OUTSIDE//[[:space:]]/}" ]]; then
  pass "D-35 git status --porcelain is clean apart from paths under $PHASE14_PREFIX"
```

---

### `arch/dots-hyprland.sh` (wrapper surgery)

**Analog:** the file's own surviving structure. The target state is a
subtraction from `run_install_family` (`arch/dots-hyprland.sh:1400-1495`). The
excerpt below is the current body; the planner deletes the marked regions.

**Header constants to strip** (`arch/dots-hyprland.sh:9-21`):

```bash
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
II_ROOT="$REPO_ROOT/vendor/dots-hyprland"
SETUP="$II_ROOT/setup"
SAFE_DEFAULTS=(--core --skip-hyprland --skip-sysupdate)          # DELETE (D-04)
# install* → upstream ./setup; uninstall/protect → wrapper-owned safe path
ALLOWLIST=(install install-deps install-setups install-files uninstall protect)   # drop `protect` (D-07)
...
II_BACKUP_DIR="${BACKUP_DIR:-$HOME/ii-original-dots-backup}"      # DELETE (D-06)
```

**The argv-flag parse loop — the seam where D-05 lands**
(`arch/dots-hyprland.sh:1400-1417`):

```bash
  local -a user_flags=()
  local arg
  for arg in "$@"; do
    case "$arg" in
      --dry-run)
        dry_run=1
        ;;
      --allow-skip-backup)          # DELETE arm (D-06)
        allow_skip_backup=1
        ;;
      --full)
        # D-01: wrapper-owned meta; never forward to ./setup
        full=1
        ;;
      *)
        user_flags+=("$arg")
        ;;
    esac
  done
```

The `--full)` arm **stays** (D-05) with its body replaced by an ignored-note
echo. The `*)` catch-all is exactly the forwarding hazard CONTEXT.md D-05 names:
any arm removed from this `case` silently becomes a forwarded upstream flag.

**The injection branch — the single seam D-04 removes**
(`arch/dots-hyprland.sh:1443-1457`):

```bash
  # Build argv: ./setup <sub> [SAFE_DEFAULTS…] [user flags…] (D-09)
  local -a cmd=(./setup "$subcmd")
  if needs_safe_defaults "$subcmd" && ((full == 0)); then
    echo "[CONFIG] safe defaults: ${SAFE_DEFAULTS[*]}"
    cmd+=("${SAFE_DEFAULTS[@]}")
  elif needs_safe_defaults "$subcmd" && ((full == 1)); then
    echo "[CONFIG] full profile: no SAFE_DEFAULTS injection (DISP-02 drop-all-three)"
  fi
  if ((${#user_flags[@]} > 0)); then
    cmd+=("${user_flags[@]}")
  fi

  echo "[INSTALL] ${cmd[*]}  (cwd=$II_ROOT)"
```

Target shape (research §Architecture Patterns "After"): `local -a cmd=(./setup "$subcmd" --skip-backup)`
then straight into the `user_flags` append. Note `--skip-backup` is appended at
build time, not conditionally — it is the only injection left.

**Array-only exec — KEEP verbatim** (`arch/dots-hyprland.sh:1459-1479`):

```bash
  # --dry-run: print would-exec, exit 0 without calling setup (D-16)
  if ((dry_run)); then
    echo "[CONFIG] dry-run: would exec from $II_ROOT: ${cmd[*]}"
    case "$subcmd" in                                        # DELETE the whole mirror case (D-07/D-08)
      install|install-deps|install-files)
        echo "[CONFIG] dry-run: after setup, would re-mark protect-list as explicit (ii demotes deps)"
        protect_explicit_packages 1 "PROTECT"
        echo "[CONFIG] dry-run: after setup, would enable ii hooks in live + repo hyprland.conf"
        enable_hypr_ii_hooks 1
        ;;
    esac
    exit 0
  fi

  # Array exec only — never eval a concatenated command string (T-06-04)
  (
    cd "$II_ROOT"
    "${cmd[@]}"
  )
```

The `echo "[CONFIG] dry-run: would exec from $II_ROOT: ${cmd[*]}"` line is the
string every assert in the repo greps as `'would exec'`. It must survive byte-
compatible with that grep.

**Preflight — KEEP verbatim** (`arch/dots-hyprland.sh:148-160`), the model for
"[FAIL] …" + "[FAIL] Fix: …" + `exit 1` error reporting used throughout:

```bash
preflight() {
  if [[ ! -e "$II_ROOT/.git" ]]; then
    echo "[FAIL] vendor/dots-hyprland is not an initialized submodule (missing .git)." >&2
    echo "[FAIL] Fix (from REPO_ROOT): git submodule update --init --recursive" >&2
    exit 1
  fi
  ...
}
```

**Doomed helper whose shape shows the `set -u` signature hazard**
(`arch/dots-hyprland.sh:141-146` and `:196-198`):

```bash
needs_safe_defaults() {         # DELETE (D-04)
  case "$1" in
    install|install-files) return 0 ;;
    *) return 1 ;;
  esac
}

is_help_only_user_flags() {     # DELETE (D-06)
  local -n _flags=$1
```

`local -n` nameref parameter passing is this file's convention for array args —
relevant when shrinking `uninstall_gate` 5→3 and `run_safe_uninstall` 6→4: the
positional `local x="$5"` reads must be deleted in the same edit as the call
site, or `set -u` aborts (research §Signature changes).

---

### `16-DOC-SWEEP.md` (NEW — planning-artifact + load-bearing marker)

**Analog:** `.planning/phases/15-playbook-safe-vs-full/15-DOC-SWEEP.md`

**Preamble pattern** (`15-DOC-SWEEP.md:1-9`):

```markdown
# Phase 15 doc staleness sweep

Scope: the D-20 sweep of operator-facing and planning prose for post-adopt staleness, applying the D-22 rule that frozen planning artifacts are flagged here rather than rewritten, with `.planning/PROJECT.md` product-surface lines as D-22's stated correction exception.

This is a findings report, not operator instruction. Stale strings are quoted verbatim below on purpose, which is why this phase's forbidden-string assertions are scoped to the operator-facing docs and never to this file.

## Corrections applied

Scope of this sweep (D-20): `docs/dots-hyprland-workflow.md`, `docs/phase14-adopt-runbook.md`, `README.md`, `arch/README.md`, and `.planning` prose.
```

The second paragraph is directly reusable: it is the standing justification for
why D-36's ban-grep is scoped to `docs/dots-hyprland-workflow.md` only and never
to the sweep file itself.

**Section skeleton** (`15-DOC-SWEEP.md` headings): `## Corrections applied` with
one `### <file path>` subsection per file, then `## Reviewed, no findings`,
`## Flagged, not edited (D-22)`, `## Deferred fixes`, `## Phase gate`.

**Per-file correction table** — four columns, stale text quoted verbatim in
backticks, `Severity` ∈ HIGH/MEDIUM/LOW, correction cites the plan that made it
(`15-DOC-SWEEP.md:20-32`):

```markdown
| Line | Stale text | Correction | Severity |
|------|-----------|------------|----------|
| 14 | "This playbook is the Install/Adopt source of truth so a cold machine can reach dual-run (`waybar` + `qs -c ii`) without tribal knowledge." | Deleted the dual-run destination claim (Plan 15-01) | HIGH |
| 193 | "### Dual-run (intentional this milestone)" | Deleted, contradicts D-09 (Plan 15-02) | LOW |
```

The `## Flagged, not edited (D-22)` section is the model for D-29/D-30's
"marked superseded, not rewritten" rule — reuse its table form so one
superseded-annotation vocabulary is used across `PROJECT.md`, `STATE.md` and
`REQUIREMENTS.md` (Claude's Discretion item 3).

---

## Shared Patterns

### Assert-script skeleton
**Source:** `scripts/phase12-full-smoke.sh:9-16` + `:159-163`
**Apply to:** the new `scripts/phase16-*-assert.sh`; preserved unchanged in the
`phase12` / `phase13` / `phase14` rewrites.

```bash
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"
FAIL=0
pass() { printf '[PASS] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
# … asserts …
echo "=== done: FAIL=${FAIL} ==="
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
```

### Every assert is an `if/else` with both branches present
**Source:** universal across all five assert scripts.
**Apply to:** every new assert.
There is no bare `grep -q … && pass`. A condition that cannot be observed emits
`[INFO]` (`scripts/phase13-d19-assert.sh:155`,
`scripts/phase14-verify.sh:40`) and never a silent skip. Failure branches print
evidence via `sed -n '1,40p' "$OUT" || true` or a repeated `grep … || true`.

### Header block declares constraints, not just usage
**Source:** `scripts/phase14-verify.sh:1-29`, `scripts/phase11-dispositions-assert.sh:1-18`
**Apply to:** the new phase16 assert.
Every script opens with `Usage (from REPO_ROOT):`, the exit contract
("Exit 0 if all hard asserts pass; non-zero if any hard FAIL"), and an explicit
`Constraints (Phase N):` list of what it will never do. For phase16 that list is:
non-mutating, dry-run argv only, never runs a live install, ban-grep scoped to
`docs/dots-hyprland-workflow.md` only.

### Path constants at the top, never inline
**Source:** `scripts/phase13-d19-assert.sh:19-23`, `scripts/phase10-inventory-assert.sh:24-25`,
`scripts/phase11-dispositions-assert.sh:25-26`

```bash
SOT=".planning/phases/13-personal-hypr-custom-overlays/13-SOT-APPLY.md"
LIVE_CUSTOM="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/custom"
XDG="${XDG_CONFIG_HOME:-$HOME/.config}"
```

Note the split convention: assert scripts `cd "$REPO_ROOT"` then use **relative**
paths for repo files (`phase12`, `phase13`) or `"$REPO_ROOT/…"` absolute
(`phase10`, `phase11`). Either is acceptable; be internally consistent within
one file.

### `[LABEL]` prefixed stdout in the wrapper
**Source:** `arch/dots-hyprland.sh:5` (stated convention), used at `:1443-1461`
**Apply to:** every surviving/new wrapper echo, including the D-05 ignored-note.
Labels in use: `[CONFIG]`, `[INSTALL]`, `[FAIL]`, `[PROTECT]`, `[UNINSTALL]`,
`[DONE]`. The D-05 note should use `[CONFIG]`. All `[FAIL]` lines go to `>&2`.

### Symbol-anchored, bottom-up deletion
**Source:** research §Pattern 1/2, grounded in `arch/dots-hyprland.sh` structure.
**Apply to:** every wrapper edit.

```bash
grep -n '^[A-Za-z_][A-Za-z0-9_]*()' arch/dots-hyprland.sh | grep -A1 'backup_gate'
# 166:backup_gate() {
# 196:is_help_only_user_flags() {
#   → backup_gate occupies 166..195 inclusive, at this instant only.
```

Confirm `print_lines` survival with `grep -n 'print_lines' arch/dots-hyprland.sh`,
never by the line numbers quoted in CONTEXT.md.

---

## No Analog Found

None. Every file this phase creates or modifies has a tracked in-repo analog,
which is the research's own conclusion (§Don't Hand-Roll: "every capability this
phase needs already exists in the repo's own assert vocabulary"). The planner
should not import patterns from RESEARCH.md's external examples for any file.

Two files are **deleted** and therefore have no pattern assignment:
`scripts/phase07-live-smoke.sh`, `scripts/phase14-preflight.sh` (D-33). Neither
has a runner (no Makefile, no CI workflow, no `.claude` hook), so deletion is
the whole change.

---

## Metadata

**Analog search scope:** `scripts/`, `arch/`, `docs/`, `.planning/phases/15-*/`
**Files scanned:** 9 (5 assert scripts, the wrapper, 2 docs, 1 sweep record)
**Tracked-source check:** `git ls-files` run against all 9 analog paths — all tracked, no gitignored mirrors
**Pattern extraction date:** 2026-09-07
