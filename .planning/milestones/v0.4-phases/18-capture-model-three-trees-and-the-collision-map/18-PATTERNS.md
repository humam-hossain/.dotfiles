# Phase 18: Capture model — three trees and the collision map - Pattern Map

**Mapped:** 2026-09-13
**Files analyzed:** 15 new/modified artifacts
**Analogs found:** 14 / 15

All analog paths below were checked with `git ls-files` and are tracked source in
this repo (no submodule mirrors, no gitignored paths). `vendor/dots-hyprland/...`
is referenced only as *read-only input data* to the generator, never as a pattern
to copy.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `scripts/gen-collision-map.sh` | utility (build-time generator) | transform (source → stdout TSV) | `scripts/phase17-unblock-assert.sh` (bash executable idiom, REPO_ROOT prologue) + `scripts/phase14-verify.sh` (fixture reader / `return 1` in command substitution) | role-match |
| `scripts/phase18-capture-model-assert.sh` | test (phase assert) | batch / request-response probes | `scripts/phase17-unblock-assert.sh` | exact |
| `collision-map.tsv` | config/data (generated artifact) | file-I/O | *(none — first TSV data artifact in repo)* | none |
| `arch/dots-hyprland.sh` → `run_verify()` | controller (wrapper subcommand) | batch read-only filesystem walk | `run_uninstall()` @ `arch/dots-hyprland.sh:648-711` | exact |
| `arch/dots-hyprland.sh` → `run_capture()` | controller (wrapper subcommand) | file-I/O (live → repo working tree) | `run_uninstall()` @ `arch/dots-hyprland.sh:648-711` | exact |
| `arch/dots-hyprland.sh` → `ALLOWLIST` (:17) | config | — | same line, existing 5-element array | exact |
| `arch/dots-hyprland.sh` → `main()` case (:790-822) | route/dispatch | request-response | existing `uninstall)` arm @ :814-821 | exact |
| `arch/dots-hyprland.sh` → `--exp-files` gate in `main()` prologue | middleware (guard) | request-response | `safe_rm_path` refusal idiom @ :440-450, `is_allowlisted` refusal @ :804-809 | role-match |
| `arch/dots-hyprland.sh` → `is_allowlisted` / `preflight` / `touches_files` / `run_install_family` | utility/middleware | — | unchanged in shape; see "No-change constraints" | exact |
| `arch/zsh.sh` (+1 starship stow line) | config/installer script | — | `arch/kitty.sh:10` | exact |
| `arch/qbittorrent.sh` (new) | config/installer script | — | `arch/kitty.sh` (whole file) | exact |
| `arch/scrutiny.sh` (+1 stow line) | config/installer script | — | `arch/kitty.sh:10` | exact |
| `stow/README.md`, `restow/README.md`, `capture/README.md` | docs | — | `docs/dots-hyprland-workflow.md` (Purpose/Prerequisites/numbered-section shape) | role-match |
| `docs/archive/README.md` | docs | — | `docs/phase14-adopt-runbook.md` (historical-record doc with dated provenance notes) | role-match |
| `scripts/nvim-validate.sh`, `scripts/nvim-audit-failures.sh` (retarget) | utility | — | their own current lines (`nvim-validate.sh:112-113,143-144,182-183`; `nvim-audit-failures.sh:24`) | exact |
| `scripts/phase13-d19-assert.sh`, `scripts/phase14-verify.sh` (fixture repoint, D-21) | test | — | their own current fixture paths | exact |
| `scripts/phase17-unblock-assert.sh:90` (`-eq 15` → `-eq 18`) | test | — | the line itself | exact |

---

## Pattern Assignments

### `scripts/phase18-capture-model-assert.sh` (test, batch)

**Analog:** `scripts/phase17-unblock-assert.sh` — the closest match in the repo and
the one the CONTEXT (D-49, D-57) names. Note the contract split: phase17 uses
three prefixes + one counter; `scripts/phase14-verify.sh` uses four prefixes + two
counters. **Phase 18 needs the four-prefix form (D-49), so copy the prefix set from
phase14 and everything else from phase17 — and say which you follow in the header,
as both predecessors do.**

**Header + constraints block** (`scripts/phase17-unblock-assert.sh:1-29` — copy the
shape, especially the explicit "Constraints" and "Contract" paragraphs):

```bash
#!/usr/bin/env bash
# Phase 17 unblock contract asserts (D-20).
# ...
# Constraints (Phase 17):
#   - Non-mutating: this script runs only greps, `bash -n`, stow simulate (-n)
#     runs and a sourced-subshell fixture. ...
#   - Contract (D-20): three prefixes [PASS] [FAIL] [INFO], ONE counter FAIL,
#     closing line `=== done: FAIL=n ===`. The sibling phase14-verify.sh uses a
#     different contract (a second counter and a fourth prefix); it is not
#     copied here beyond its info() helper line.
```

**Prologue + helpers — four-prefix variant** (`scripts/phase14-verify.sh:31-41`,
which is the form D-49 wants; phase17 lines 31-41 are the same minus `finding()`):

```bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

FAIL=0
FINDINGS=0
pass()    { printf '[PASS] %s\n' "$1"; }
fail()    { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
finding() { printf '[FINDING] %s\n' "$1"; FINDINGS=$((FINDINGS + 1)); }
info()    { printf '[INFO] %s\n' "$1"; }
```

**Section banner + closing line** (`scripts/phase17-unblock-assert.sh:42`, `:937-940`):

```bash
echo "=== Phase 17 unblock contract (non-mutating) ==="
...
echo "=== done: FAIL=${FAIL} ==="
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
```

**Behavioural (not textual) probe — stow simulate** (`scripts/phase17-unblock-assert.sh:43-52`).
This is the template for the §1/§3 tree checks and for any "does stow accept this"
question. Note the subshell `( cd … && stow … )`, the `-n` simulate flag, and the
re-run of the same command on failure to print evidence:

```bash
# Behavioral, not textual. A grep proves only that the literal is written; only
# a real stow run proves the literal parses. `-n` makes it a simulate, so the
# run plans and reports without touching the destination tree.
if ( cd "$REPO_ROOT/stow" && stow --verbose=5 --no-folding -n -t ~ btop ) >/dev/null 2>&1; then
  pass "1e GNU Stow accepts --verbose=5 --no-folding (simulate run of package btop exits 0)"
else
  fail "1e GNU Stow rejected --verbose=5 --no-folding on a simulate run of package btop"
  ( cd "$REPO_ROOT/stow" && stow --verbose=5 --no-folding -n -t ~ btop ) || true
fi
```

**Vacuity guard before every ban-grep** (`scripts/phase17-unblock-assert.sh:54-71`).
Required for §5 (`--adopt` absent) and §6 (`.config/` gone) — RESEARCH Pattern 3:

```bash
# A ban-grep over a missing directory, or over a directory holding none of the
# files it means to police, passes while observing nothing. Both scoped trees
# are asserted present and non-empty before either ban runs.
ARCH_SH_COUNT="$(find arch -maxdepth 1 -type f -name '*.sh' | wc -l || true)"
if [[ -d arch && "$ARCH_SH_COUNT" -gt 0 ]]; then
  pass "1a guard: arch/ exists and holds $ARCH_SH_COUNT *.sh files (the ban below cannot pass vacuously)"
else
  fail "1a guard: arch/ is missing or holds no *.sh file — the ban-grep would pass over nothing"
  ls -la arch 2>&1 || true
fi
```

**Cannot-be-evaluated three-way branch** (`scripts/phase17-unblock-assert.sh:196-210`).
Use this shape wherever a count is derived from a file that might be absent —
never let "0 hits because the file is gone" read as a pass:

```bash
HYPR_COPY_HITS=0
if [[ "${HYPR_INSTALLER_LINES:-0}" -gt 0 ]]; then
  HYPR_COPY_HITS="$(grep -c -F -- 'cp -rf .config/hypr/' "$HYPR_INSTALLER" || true)"
fi
if [[ "${HYPR_INSTALLER_LINES:-0}" -eq 0 ]]; then
  fail "2a cannot be evaluated: $HYPR_INSTALLER is missing or empty — a ban over nothing is not a pass"
elif [[ "$HYPR_COPY_HITS" -eq 0 ]]; then
  pass "2a ..."
else
  fail "2a ..."
  grep -n -F -- 'cp -rf .config/hypr/' "$HYPR_INSTALLER" || true
fi
```

**Anchored-pattern matching for criterion 6** (`scripts/phase17-unblock-assert.sh:213-233`).
Copy the *technique and its comment discipline*, **not the regex** — per RESEARCH
F-9, Phase 17 deliberately treats `$REPO_ROOT/.config/...` as correct, and FIX-03
bans the path regardless of anchoring, so phase 18 needs a second pattern for the
`$REPO_ROOT/` form:

```bash
# Anchored to line start or whitespace, which is the whole point of the pattern.
# ... A path anchored to the home directory (`~/.config/...`, `$HOME/.config/...`)
# or to the script's own location (`$REPO_ROOT/.config/...`) has the configuration
# component preceded by a slash, not by whitespace, and is correct — so it must
# not false-positive here or the ban would forbid the fix along with the defect.
HYPR_RELATIVE_HITS="$(grep -c -E '(^|[[:space:]])\.config/' "$HYPR_INSTALLER" || true)"
```

Scope for §6 is fixed by the user's FIX-03 decision: **the twelve moved files only**
(`.config/hypr/`, `.config/dolphinrc`, `.config/kdeglobals` relative to the repo
root), plus retargeting `scripts/nvim-validate.sh` and `scripts/nvim-audit-failures.sh`.
`ubuntu/` + `debian/` legacy readers are backlog, not this phase. `scripts/phase17-unblock-assert.sh`'s
19 hits are quoted grep *patterns* and must not be counted (RESEARCH F-9 trap 1);
`arch/dots-hyprland.sh:446`'s `*/.config/hypr` glob is a live-path belt and must
not be touched (trap 2).

**`bash -n` syntax guard with anti-shrink list guard** (`scripts/phase17-unblock-assert.sh:111-140`).
Reuse verbatim in shape for the phase-18 touched-file set; the guard on
`${#SYNTAX_FILES[@]}` is the part that matters:

```bash
SYNTAX_FILES=(
  arch/alacritty.sh
  ...
)
SYNTAX_MISSING=0
for f in "${SYNTAX_FILES[@]}"; do
  [[ -f "$f" ]] || { SYNTAX_MISSING=$((SYNTAX_MISSING + 1)); printf '  missing: %s\n' "$f"; }
done
if [[ "${#SYNTAX_FILES[@]}" -eq 14 && "$SYNTAX_MISSING" -eq 0 ]]; then
  pass "1c guard: all 14 files holding a stow call site are present (the syntax loop cannot shrink silently)"
```

**Trap-based fixture cleanup** (`scripts/phase16-retire-assert.sh:32-41` — the
repo's only multi-fixture trap; `scripts/phase14-verify.sh:353-355` is the
single-file form). Required by D-44, D-55, D-56:

```bash
INSTALL_OUT="$(mktemp /tmp/p16-retire-install-XXXXXX)"
FILES_OUT="$(mktemp /tmp/p16-retire-files-XXXXXX)"
...
trap 'rm -f "$INSTALL_OUT" "$FILES_OUT" ...' EXIT
```

For D-56's mis-filed package the fixture must live **inside** the real tree, so use
`trap 'rm -rf "$FIXTURE"' EXIT` set immediately after creation. For D-44/D-55 use
`mktemp -d` outside the repo.

**Reading a `find` result set line-by-line, sorted** (`scripts/phase17-unblock-assert.sh:925-933`).
This is the analog for the §1/§7 tree walks:

```bash
while IFS= read -r LINKPATH; do
  [[ -n "$LINKPATH" ]] || continue
  if [[ -d "$LINKPATH" ]]; then
    FOLDED_COUNT=$((FOLDED_COUNT + 1))
    info "D-02 folded directory symlink: $LINKPATH -> $(readlink "$LINKPATH")"
  fi
done < <(find "$HOME/.config" -maxdepth 2 -type l -lname '*.dotfiles*' 2>/dev/null | sort)
```

**Not from an analog — take verbatim from RESEARCH `## Code Examples`:** the CAP-08
end-to-end check (§4), the corrected two-part dirty check, and the `readlink -f`
link-ness check. No existing repo file demonstrates these.

---

### `scripts/gen-collision-map.sh` (utility/generator, transform)

**Analog:** no generator exists in the repo. Take the *executable shell* patterns
from `scripts/phase17-unblock-assert.sh` and the *fail-inside-a-function* pattern
from `scripts/phase14-verify.sh`.

**Prologue** — identical to the assert's, minus `cd "$REPO_ROOT"` semantics:
D-55/D-59 require an optional source-root argument, so the resolved default is
`"${1:-vendor/dots-hyprland}"` (RESEARCH `## Code Examples`, deterministic MISC
expansion). Everything written goes to **stdout only** (D-59); never open the map
for writing.

```bash
#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
```

**Loud-failure-inside-a-subshell caveat** (`scripts/phase14-verify.sh:50-57` —
read this comment before writing `emit_row`; it is the exact trap D-03's
"unrecognised primitive fails loudly" rule will hit if the emitter runs inside a
`$( )` or a pipeline):

```bash
# baseline_value runs inside a command substitution, so an `exit` here would only
# leave the subshell and let the script sail on with an empty value. It therefore
# `return 1`s and every call site is written `X="$(baseline_value k)" || exit 1`.
```

The RESEARCH MISC-loop example pipes `find | sort | while read`, which puts the
loop body in a subshell — an `exit 1` there will **not** kill the generator. Use a
process substitution (`done < <(…)`, as phase17:933 does) so the loud failure is
reachable.

**Error/refusal message shape** (`arch/dots-hyprland.sh:436-450` — the repo's
`[FAIL] …` to stderr + reason + fix idiom):

```bash
echo "[FAIL] Refusing to delete path outside \$HOME: $path" >&2
return 1
```

---

### `arch/dots-hyprland.sh` — `run_verify()` and `run_capture()` (controller, request-response)

**Analog:** `run_uninstall()` @ `arch/dots-hyprland.sh:648-711`. It is already a
wrapper-owned subcommand with its own `main` branch that never calls `preflight` —
exactly the shape D-48 requires.

**Flag-scan + unknown-flag rejection** (`:648-688`):

```bash
run_uninstall() {
  local dry_run=0
  local -a unknown=()
  local arg

  for arg in "$@"; do
    case "$arg" in
      -h|--help)   usage; exit 0 ;;
      --dry-run)   dry_run=1 ;;
      ...
      *)           unknown+=("$arg") ;;
    esac
  done

  if ((${#unknown[@]} > 0)); then
    echo "[FAIL] Unknown uninstall flag(s): ${unknown[*]}" >&2
    echo "[FAIL] See: ./arch/dots-hyprland.sh help" >&2
    exit 1
  fi
```

`run_capture` copies this scan and keeps only `--dry-run` (D-42) and `-h|--help`.
`run_verify` takes **no** arguments (D-53), so its scan is just the unknown-flag
rejection.

**Dry-run reporting idiom** (`run_install_family` @ `:778-782`, and `:705-707`):

```bash
if ((dry_run)); then
  echo "[CONFIG] dry-run: would exec from $II_ROOT: ${cmd[*]}"
  exit 0
fi
```

Note the wrapper's own prefix vocabulary is `[INSTALL]` / `[CONFIG]` / `[FAIL]`.
D-49 overrides this **inside `run_verify`/`run_capture` only** to the assert
vocabulary (`[PASS]` `[FAIL]` `[FINDING]` `[INFO]` + `=== done: FAIL=n ===`) — copy
those helpers from `scripts/phase14-verify.sh:36-41` into the wrapper rather than
inventing a new spelling.

**ALLOWLIST edit** (`arch/dots-hyprland.sh:15-17` — keep the comment discipline):

```bash
# D-04: full is the only install behavior; no residual flag injection.
# install* → upstream ./setup; uninstall → the one wrapper-owned path (D-07)
ALLOWLIST=(install install-deps install-setups install-files uninstall)
```

**Dispatch branch** (`arch/dots-hyprland.sh:813-821`) — add two named arms
alongside `uninstall)`, before the `*)` catch-all. D-61 + D-48 must land in the
**same commit**; allowlist-only reaches `./setup verify`, which upstream does not
define (RESEARCH, Architectural Responsibility Map):

```bash
  case "$subcmd" in
    uninstall)
      run_uninstall "$@"
      ;;
    *)
      run_install_family "$subcmd" "$@"
      ;;
  esac
```

**`--exp-files` gate placement** (`arch/dots-hyprland.sh:790-809`) — the gate goes
**after** the help arm and **before** the allowlist `if`:

```bash
main() {
  # 1) bare / help → wrapper usage, exit 0 (D-02, D-03)
  if [[ $# -eq 0 ]]; then usage; exit 0; fi
  case "$1" in
    help|-h|--help) usage; exit 0 ;;
  esac

  # <<< D-31 --exp-files gate goes HERE >>>

  # 2) allowlist
  if ! is_allowlisted "$1"; then
    echo "[FAIL] Unknown or non-allowlisted subcommand: $1" >&2
    ...
    exit 1
  fi
```

**Guard idiom to copy for the gate body** (`safe_rm_path` @ `:444-450` — the
"extra belt" `case` with a `[FAIL] Refusing …` message on stderr):

```bash
  # Extra belt: never hypr
  case "$path" in
    */.config/hypr|*/.config/hypr/*)
      echo "[FAIL] Refusing to delete hypr path: $path" >&2
      return 1
      ;;
  esac
```

The gate differs in exiting **2** (D-33), not returning 1. Take the exact message
text from RESEARCH `## Code Examples → The --exp-files gate`.

**No-change constraints on this file:**
- `is_allowlisted` (:109-115), `preflight` (:117-129), `touches_files` (:716-721),
  `run_install_family` (:723-788) keep their current bodies. `preflight` must stay
  unreachable from `run_verify`/`run_capture` (D-47).
- The dispatch guard at `:824-833` is **not** changed (D-61); its `if`-block form
  is deliberate (Phase 17 D-09) and is what makes the file sourceable for tests.
- `safe_rm_path`'s `*/.config/hypr` case at `:446` is a live-path glob, not a repo
  path — FIX-03's grep must not touch it (RESEARCH F-9 trap 2).

---

### `arch/zsh.sh`, `arch/qbittorrent.sh` (new), `arch/scrutiny.sh` (config/installer)

**Analog:** `arch/kitty.sh` — the whole file is nine lines and is the canonical
package script shape:

```bash
#!/usr/bin/env bash
set -euo pipefail
set -x


echo "[INSTALL] kitty"
sudo pacman -Sy --noconfirm --needed kitty

echo "[CONFIG] kitty"
cd "$(dirname "${BASH_SOURCE[0]}")/../stow" && stow --verbose=5 --no-folding -t ~ kitty
```

**The stow call-site idiom** — flag order is fixed and load-bearing (it is what
lets `scripts/phase17-unblock-assert.sh:89` count one literal and call it a
complete audit). Retargeted form changes only the tree component:

```bash
cd "$(dirname "${BASH_SOURCE[0]}")/../restow" && stow --verbose=5 --no-folding -t ~ kitty
```

`arch/zsh.sh` gains exactly **one** new line (starship), placed beside the existing
`:43` invocation:

```bash
# arch/zsh.sh:43 — existing
cd "$(dirname "${BASH_SOURCE[0]}")/../stow" && stow --verbose=5 --no-folding -t ~ zsh
```

**Scope decision recorded:** `arch/zsh_powerlevel.sh:61` is a second `zsh` stow
call site (RESEARCH F-10) but does **not** get a starship line. The authorised
`scripts/phase17-unblock-assert.sh:90` constant therefore stays **18**
(15 + qbittorrent + scrutiny + starship).

`arch/scrutiny.sh` currently ends with docker metric collection and has no stow
line; append the `kitty.sh:10` form for `smartmontools`, keeping the tree at
`../stow` (D-15 — neither package collides).

---

### `stow/README.md`, `restow/README.md`, `capture/README.md`, `docs/archive/README.md` (docs)

**Analog for structure:** `docs/dots-hyprland-workflow.md` — `# Title` / `## Purpose`
/ `## Prerequisites` / numbered `## N. Step` sections with fenced `bash` blocks
holding copy-pasteable commands and `# expect:` annotations:

```markdown
# dots-hyprland workflow (illogical-impulse)

## Purpose
...
## Prerequisites
...
## 1. Clone & recursive submodule init
```bash
# From a machine with git + SSH to GitHub
...
# expect a line for vendor/dots-hyprland with a SHA (not a leading '-')
```
```

**Analog for the archive README's provenance style:** `docs/phase14-adopt-runbook.md`,
which records dated, commit-attributed history inline:

```markdown
# Record: this command was run on 2026-09-04 before the install.
# scripts/phase14-preflight.sh no longer exists (removed in Phase 16).
```

That is exactly D-27's requirement — each `docs/archive/` entry names why it was
retired and the commit that retired it.

**Analog for cross-linking:** root `README.md:5-11` — the repo links out to the
operator playbook rather than restating it. `restow/README.md`'s prose and D-10's
recovery text must point at the single generated table, never restate the commands
(D-12).

Each tree README carries D-12's four parts: contract paragraph, exact recovery
command, membership rule, and (for `restow/` only) the generator-owned table.
`stow/README.md` additionally records RESEARCH F-4's upstream quirk
(`install_dir__ignore_existing` short-circuits, so new upstream files under
`hypr/custom/` never appear). The CAP-07 `--adopt` ban and its documented
exception should sit beside the F-2 `mv`-aside-then-stow procedure, since stow's
own conflict message advertises the banned flag.

---

### `collision-map.tsv` (data artifact, file-I/O)

**No analog.** The repo has no checked-in TSV or generated data artifact. Format is
fully specified by D-01/D-06/D-60 and RESEARCH F-13 (29 rows: 18 MISC + 11 named).
The only transferable pattern is the **comment-header-carries-the-reasoning**
convention that `arch/dots-hyprland.sh` and the asserts use in code comments:
the header must carry the pin SHA (D-60), D-04's exclusion reasoning, D-06's
`SKIP_*` reasoning, F-3's ordering guarantee, F-5's "the destructive
`auto_backup` branch is disarmed on this host" note, and F-13's two coverage gaps.

---

### `scripts/nvim-validate.sh`, `scripts/nvim-audit-failures.sh` (retarget)

**Analog:** their own existing lines — a pure path substitution,
`$REPO_ROOT/.config/nvim` → `$REPO_ROOT/stow/nvim/.config/nvim`:

```bash
# scripts/nvim-validate.sh:112-113 (three identical pairs at :112,:143,:182)
		-u "$REPO_ROOT/.config/nvim/init.lua" \
		--cmd "set rtp^=$REPO_ROOT/.config/nvim" \

# scripts/nvim-audit-failures.sh:24
NVIM_CONFIG="$REPO_ROOT/.config/nvim"
```

These are live validation scripts, not closed-phase records, so editing them is
unrestricted (contrast D-20).

---

## Shared Patterns

### Script prologue
**Source:** `scripts/phase17-unblock-assert.sh:31-34`
**Apply to:** every new `scripts/*.sh`; `arch/*.sh` uses the `set -euo pipefail` + `set -x` variant (`arch/kitty.sh:1-3`)
```bash
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"
```
`arch/dots-hyprland.sh:12` uses `pwd -P` deliberately (D-06) because `safe_rm_path`
compares against a realpath-resolved candidate — do not "fix" the inconsistency.

### Output vocabulary
**Source:** `scripts/phase14-verify.sh:24-41` (four prefixes, two counters)
**Apply to:** `scripts/phase18-capture-model-assert.sh`, `run_verify()`, `run_capture()` (D-49)
```bash
#   [PASS]     hard condition satisfied
#   [FAIL]     hard condition violated — moves the exit code
#   [FINDING]  observed condition recorded ...
#   [INFO]     a condition this run could not observe, named rather than skipped
```
Note D-43 diverges from phase14 here: in `capture`, a `[FINDING]` **does** move the
exit code. State that divergence in the function's header comment.

### Refusal messages
**Source:** `arch/dots-hyprland.sh:436-450`, `:804-809`, `:685-687`
**Apply to:** the `--exp-files` gate, `run_capture`'s per-path refusals, `run_verify`'s unknown-flag arm
```bash
echo "[FAIL] Unknown or non-allowlisted subcommand: $1" >&2
echo "[FAIL] Allowlisted: ${ALLOWLIST[*]}" >&2
echo "[FAIL] For other ops use vendor/dots-hyprland/./setup directly." >&2
exit 1
```
Every refusal is multi-line: what was refused, why, and the fix. `preflight`
(`:119-122`) is the clearest instance of the "Fix (from REPO_ROOT): …" line.

### Trap-based cleanup
**Source:** `scripts/phase16-retire-assert.sh:32-41`
**Apply to:** all three assert fixtures (D-44, D-55, D-56)

### Vacuity guard before a ban-grep
**Source:** `scripts/phase17-unblock-assert.sh:54-71`
**Apply to:** assert §5 and §6

### Stow call-site literal
**Source:** `arch/kitty.sh:10`
**Apply to:** all five touched/new call sites. `arch/hyprland.sh:42,46` shows the
`$REPO_ROOT`-based variant carrying the same literal — both are counted by
`scripts/phase17-unblock-assert.sh:89`.

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `collision-map.tsv` | data | file-I/O | No checked-in data artifact of any format exists in the repo. Format is fully specified by D-01/D-06/D-60; ordering guarantee by F-3; row set by F-13. |

Three *behaviours* also have no in-repo analog and must come from RESEARCH
`## Code Examples` rather than from a file:
- the two-part dirty check (`git ls-files --error-unmatch` + `git diff --quiet HEAD --`) — F-8
- the `readlink -f` link-ness check — D-46 / `PITFALLS.md:30`
- the deterministic `LC_ALL=C sort` MISC-loop expansion — F-3

## Closed-Record Constraints (do not violate)

- `scripts/phase17-unblock-assert.sh`: **one** authorised edit, `-eq 15` → `-eq 18`
  at line 90, with a comment naming D-19 and D-08. Lines 433-435 (qBittorrent probe
  patterns) and the 14-element `SYNTAX_FILES` list at :115-135 stay untouched
  (F-11 — adding `arch/qbittorrent.sh`/`arch/scrutiny.sh` does not change that
  count, so it stays green). Emit an `[INFO]` from the phase-18 assert noting the
  now-stale "all 14 files" message rather than editing it.
- `scripts/phase13-d19-assert.sh` and `scripts/phase14-verify.sh`: fixture paths
  repointed only (D-21), because the file they read is being deleted.
- `.planning/research/PITFALLS.md:288`: corrected by splitting the conflated
  `install_dir` / `install_dir__ignore_existing` row (F-1), riding along with
  D-35's authorised Q15 addition.

## Metadata

**Analog search scope:** `scripts/`, `arch/`, `docs/`, repo root, `stow/`
**Files scanned:** 14 read; 5 strong analogs extracted
**Tracked-source check:** `git ls-files` confirmed for every analog path named
**Pattern extraction date:** 2026-09-13
