#!/usr/bin/env bash
# Phase 17 unblock contract asserts (D-20).
# Asserts the FIX-01 / CAP-04 stow-flag sweep: every stow invocation under
# arch/ and docs/ carries the valid --verbose=5 --no-folding spelling in that
# fixed order, the invalid short-verbosity spelling survives at zero sites in
# those two trees, the edited installer scripts still parse, and the installed
# GNU Stow actually accepts the new spelling.
#
# Usage (from REPO_ROOT):
#   ./scripts/phase17-unblock-assert.sh
# Exit 0 if all hard asserts pass; non-zero if any hard FAIL.
#
# Constraints (Phase 17):
#   - Non-mutating: this script runs only greps, `bash -n`, stow simulate (-n)
#     runs and a sourced-subshell fixture. It never runs a live install, a live
#     uninstall, or any package operation.
#   - The D-02 folding audit is read-only and reports [INFO] only. This phase
#     records the already-folded directories and hands them to Phase 18; it
#     never unfolds one.
#   - Contract (D-20): three prefixes [PASS] [FAIL] [INFO], ONE counter FAIL,
#     closing line `=== done: FAIL=n ===`. The sibling phase14-verify.sh uses a
#     different contract (a second counter and a fourth prefix); it is not
#     copied here beyond its info() helper line.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

FAIL=0
pass() { printf '[PASS] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
info() { printf '[INFO] %s\n' "$1"; }

echo "=== Phase 17 unblock contract (non-mutating) ==="

# --- criterion 1e / FIX-01: the installed GNU Stow accepts the new spelling ---
# Behavioral, not textual. A grep proves only that the literal is written; only
# a real stow run proves the literal parses. `-n` makes it a simulate, so the
# run plans and reports without touching the destination tree.
if ( cd "$REPO_ROOT/stow" && stow --verbose=5 --no-folding -n -t ~ btop ) >/dev/null 2>&1; then
  pass "1e GNU Stow accepts --verbose=5 --no-folding (simulate run of package btop exits 0)"
else
  fail "1e GNU Stow rejected --verbose=5 --no-folding on a simulate run of package btop"
  ( cd "$REPO_ROOT/stow" && stow --verbose=5 --no-folding -n -t ~ btop ) || true
fi

# --- vacuity guard for the criterion 1a / 1d ban greps ---------------------
# A ban-grep over a missing directory, or over a directory holding none of the
# files it means to police, passes while observing nothing. Both scoped trees
# are asserted present and non-empty before either ban runs.
ARCH_SH_COUNT="$(find arch -maxdepth 1 -type f -name '*.sh' | wc -l || true)"
DOCS_MD_COUNT="$(find docs -type f -name '*.md' | wc -l || true)"
if [[ -d arch && "$ARCH_SH_COUNT" -gt 0 ]]; then
  pass "1a guard: arch/ exists and holds $ARCH_SH_COUNT *.sh files (the ban below cannot pass vacuously)"
else
  fail "1a guard: arch/ is missing or holds no *.sh file — the ban-grep would pass over nothing"
  ls -la arch 2>&1 || true
fi
if [[ -d docs && "$DOCS_MD_COUNT" -gt 0 ]]; then
  pass "1d guard: docs/ exists and holds $DOCS_MD_COUNT *.md files (the ban below cannot pass vacuously)"
else
  fail "1d guard: docs/ is missing or holds no *.md file — the ban-grep would pass over nothing"
  ls -la docs 2>&1 || true
fi

# --- criterion 1a / FIX-01 + CAP-04: the invalid spelling survives nowhere ---
# Scoped by EXPLICIT path list to arch/ and docs/, never recursed from the repo
# root. The same string lives in .planning/research/PITFALLS.md, a frozen
# research artifact that is history under the Phase 16 precedent and must not
# be edited to turn this grep green.
if grep -rn -- '-v=5' arch/ docs/ >/dev/null 2>&1; then
  fail "1a the invalid short-verbosity spelling still survives under arch/ or docs/"
  grep -rn -- '-v=5' arch/ docs/ || true
else
  pass "1a the invalid short-verbosity spelling survives at zero sites under arch/ and docs/"
fi

# --- criterion 1b / FIX-01: all 15 arch/ call sites carry the valid pair ----
# A counted grep, not a ban: the fixed flag order (--verbose=5 then
# --no-folding) at every site is what makes a single literal count a complete
# audit of all 15 sites. arch/hyprland.sh holds two of them.
PAIR_COUNT="$(grep -ho -- '--verbose=5 --no-folding' arch/*.sh | wc -l || true)"
if [[ "$PAIR_COUNT" -eq 15 ]]; then
  pass "1b all 15 arch/ stow call sites carry the literal --verbose=5 --no-folding"
else
  fail "1b expected 15 arch/ sites carrying --verbose=5 --no-folding, counted $PAIR_COUNT"
  grep -rn -- '--verbose=5 --no-folding' arch/*.sh || true
  grep -rn 'stow ' arch/*.sh || true
fi

# --- criterion 1d / CAP-04: the operator doc is a named claim ---------------
# 1a already covers docs/ as part of its path list. This re-asserts the same
# ban scoped to docs/ alone so the operator-doc scope of CAP-04 is an explicit
# claim rather than a side effect of the wider grep — the 16th invocation (the
# documented kitty re-stow recovery command) is copy-pasteable and exited 1.
if grep -rn -- '-v=5' docs/ >/dev/null 2>&1; then
  fail "1d the operator docs still carry the invalid short-verbosity spelling"
  grep -rn -- '-v=5' docs/ || true
else
  pass "1d docs/ carries zero invalid stow invocations (CAP-04 operator-doc scope)"
fi

# --- criterion 1c / FIX-01: the edited installer scripts still parse --------
# `bash -n` passed on all 14 files before the sweep, so this is a regression
# guard on the edit rather than a currently-failing check. The guard in front
# of the loop asserts every path still exists: a renamed or deleted file would
# otherwise shrink the loop silently and let it pass over less than it claims.
SYNTAX_FILES=(
  arch/alacritty.sh
  arch/btop.sh
  arch/define.sh
  arch/fish.sh
  arch/hyprland.sh
  arch/kitty.sh
  arch/nvim.sh
  arch/rofi.sh
  arch/tmux.sh
  arch/wezterm.sh
  arch/xterm.sh
  arch/yazi.sh
  arch/zsh.sh
  arch/zsh_powerlevel.sh
)
SYNTAX_MISSING=0
for f in "${SYNTAX_FILES[@]}"; do
  [[ -f "$f" ]] || { SYNTAX_MISSING=$((SYNTAX_MISSING + 1)); printf '  missing: %s\n' "$f"; }
done
if [[ "${#SYNTAX_FILES[@]}" -eq 14 && "$SYNTAX_MISSING" -eq 0 ]]; then
  pass "1c guard: all 14 files holding a stow call site are present (the syntax loop cannot shrink silently)"
else
  fail "1c guard: expected 14 present call-site files, list holds ${#SYNTAX_FILES[@]} with $SYNTAX_MISSING missing"
fi
for f in "${SYNTAX_FILES[@]}"; do
  if bash -n "$f" 2>/dev/null; then
    pass "1c syntax: bash -n $f"
  else
    fail "1c syntax: bash -n $f"
    bash -n "$f" || true
  fi
done

# --- criterion 3 / FIX-04 (D-21): safe_rm_path refuses every repo path -------
# Three constraints, each from a verified trap in the function's own clause
# ordering, and each one a way this section could pass while observing nothing:
#   1. The fixture runs inside a ( ... ) SUBSHELL. Loading the wrapper imports
#      its `set -euo pipefail` and its own global REPO_ROOT, which collides with
#      this script's. The wrapper is never loaded at this script's top level.
#   2. Every fixture path must EXIST. safe_rm_path's `! -e && ! -L` early return
#      fires ahead of all three refusals and returns 0 with a skip message, so a
#      missing path would be read as "accepted" and indict a correct guard.
#   3. The positive paths must live under $HOME. The $HOME allow-list sits in
#      front of the new clause, and this repo is at /home/pera/github_repo/
#      .dotfiles — inside $HOME — so a path outside $HOME would be refused by the
#      OLDER clause and never exercise the new one at all.
# The `if ( ... ); then fail; else pass; fi` form is required: the expected
# return is non-zero, and a bare call plus `rc=$?` would trip this script's own
# `set -e` before the result could be read.
#
# NON-MUTATING BY ENFORCEMENT, NOT BY ASSUMPTION. Every path handed to
# safe_rm_path is one the function is supposed to refuse, so control is supposed
# never to reach its `rm -rf` — but "supposed to" is exactly the thing under
# test. If the guard ever regresses, an unprotected fixture would hand the real
# `rm -rf` this repo's README.md, stow/ and vendor/dots-hyprland and delete them,
# which is what happened once while this section was being written. A verifier
# whose safety depends on the correctness of the code it verifies is not safe.
# So every subshell below shadows `rm` with a no-op function AFTER loading the
# wrapper. safe_rm_path calls a bare `rm` (not `command rm`, not /usr/bin/rm), so
# the shadow intercepts it, the call still returns 0, and an accepted path is
# still reported as ACCEPTED — the assert keeps its discriminating power while
# losing its blast radius. Do not remove the shadow, and do not add a path that
# would be accepted.

# --- 3a: positive cases — existing, $HOME-resident paths inside the repo -----
FIX04_REPO_PATHS=(
  "$REPO_ROOT/README.md"
  "$REPO_ROOT/stow"
  "$REPO_ROOT/vendor/dots-hyprland"
)
for p in "${FIX04_REPO_PATHS[@]}"; do
  if [[ ! -e "$p" && ! -L "$p" ]]; then
    # Constraint 2 above: a missing path takes the early return and would be
    # scored as an acceptance. Fail loudly on the fixture, not on the guard.
    fail "3a fixture path is missing, so safe_rm_path could not be exercised on it: $p"
    continue
  fi
  if ( source "$REPO_ROOT/arch/dots-hyprland.sh" >/dev/null 2>&1; rm() { printf '[FIXTURE-GUARD] blocked: rm %s\n' "$*" >&2; }; safe_rm_path "$p" ) >/dev/null 2>&1; then
    fail "3a safe_rm_path ACCEPTED a path inside the repo: $p"
    ( source "$REPO_ROOT/arch/dots-hyprland.sh" >/dev/null 2>&1; rm() { printf '[FIXTURE-GUARD] blocked: rm %s\n' "$*" >&2; }; safe_rm_path "$p" ) || true
  else
    pass "3a safe_rm_path refuses a path inside the repo: $p"
  fi
done

# --- 3b: negative control — the pre-existing outside-$HOME clause still fires -
# Without 3b and 3c the section would still be green with the new clause
# commented out, for the wrong reason: a refusal from an older clause reads the
# same as a refusal from the new one.
FIX04_OUTSIDE="/etc/passwd"
if [[ ! -e "$FIX04_OUTSIDE" ]]; then
  fail "3b negative-control path is missing, so safe_rm_path could not be exercised on it: $FIX04_OUTSIDE"
elif ( source "$REPO_ROOT/arch/dots-hyprland.sh" >/dev/null 2>&1; rm() { printf '[FIXTURE-GUARD] blocked: rm %s\n' "$*" >&2; }; safe_rm_path "$FIX04_OUTSIDE" ) >/dev/null 2>&1; then
  fail "3b safe_rm_path ACCEPTED a path outside \$HOME: $FIX04_OUTSIDE"
else
  pass "3b safe_rm_path still refuses a path outside \$HOME: $FIX04_OUTSIDE"
fi

# --- 3c: negative control — the pre-existing hypr clause still fires ---------
FIX04_HYPR="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/custom"
if [[ ! -e "$FIX04_HYPR" && ! -L "$FIX04_HYPR" ]]; then
  fail "3c negative-control path is missing, so safe_rm_path could not be exercised on it: $FIX04_HYPR"
elif ( source "$REPO_ROOT/arch/dots-hyprland.sh" >/dev/null 2>&1; rm() { printf '[FIXTURE-GUARD] blocked: rm %s\n' "$*" >&2; }; safe_rm_path "$FIX04_HYPR" ) >/dev/null 2>&1; then
  fail "3c safe_rm_path ACCEPTED a hypr path: $FIX04_HYPR"
else
  pass "3c safe_rm_path still refuses a hypr path: $FIX04_HYPR"
fi

# --- 3d: sourceability — the D-09 dispatch guard holds ----------------------
# The prerequisite for 3a-3c. Against the unguarded wrapper the load runs
# `usage` and exits 0, so every fixture above would report the opposite of the
# truth. Asserted separately so a regression in the guard is named as one.
if ( source "$REPO_ROOT/arch/dots-hyprland.sh" >/dev/null 2>&1; [[ "$(type -t safe_rm_path)" == "function" ]] ); then
  pass "3d the wrapper loads cleanly in a subshell and safe_rm_path is defined (D-09 dispatch guard)"
else
  fail "3d loading the wrapper in a subshell did not leave safe_rm_path defined (D-09 dispatch guard regressed)"
  ( source "$REPO_ROOT/arch/dots-hyprland.sh"; type -t safe_rm_path ) || true
fi

# =============================================================================
# criterion 4 / FIX-06 — git metadata. Sections 4a and 4b.
#
# The scan half (4c, 4d) was added by plan 17-04 and lives further down, after
# section 4b. It is kept separate because it covers a different thing: 4a/4b
# assert the git metadata files, 4c/4d assert that a real scanner runs over
# both surfaces and that every accepted finding carries a written reason.
#
# NON-MUTATING. `git check-ignore` is a read-only path/pattern query — it
# consults .gitignore and the index and writes neither — and the rest of this
# section is grep, awk and `[[ ]]`. No index-writing git subcommand (add / rm /
# commit) appears below, and none belongs in an assert script — the plan's own
# ban-grep for those three verbs runs over this file, so they are named here by
# verb rather than spelled out.
# =============================================================================
echo "=== Phase 17 criterion 4 / FIX-06 git metadata (4a, 4b) ==="

# --- 4a guard: assert the input exists before asserting its content ---------
# A whole-line grep over a MISSING file exits 1, and over an EMPTY file exits 1
# too — both of which read as "the line is absent". That is the right verdict
# for the wrong reason, and it hides a deleted .gitattributes behind what looks
# like a content failure. Assert existence and non-emptiness first.
if [[ -f .gitattributes && -s .gitattributes ]]; then
  pass "4a guard: .gitattributes exists and is non-empty ($(grep -c . .gitattributes || true) non-empty line(s))"
else
  fail "4a guard: .gitattributes is missing or empty — the whole-line grep below cannot distinguish that from a wrong line"
  ls -la .gitattributes 2>&1 || true
fi

# --- 4a / D-10: the exact normalisation line, whole-line -------------------
# -F -x: fixed string, WHOLE line. A substring match would accept a commented
# `# * text=auto eol=lf` or a trailing-comment variant, neither of which is the
# D-10 line git actually honours.
if [[ -s .gitattributes ]] && grep -Fxq '* text=auto eol=lf' .gitattributes; then
  pass "4a .gitattributes carries the exact whole line '* text=auto eol=lf' (D-10)"
else
  fail "4a .gitattributes does not carry '* text=auto eol=lf' as a whole line (D-10)"
  cat -A .gitattributes 2>&1 || true
fi

# --- 4b guard: .gitignore exists and is non-empty --------------------------
if [[ -f .gitignore && -s .gitignore ]]; then
  pass "4b guard: .gitignore exists and is non-empty"
else
  fail "4b guard: .gitignore is missing or empty — every proof below would be about nothing"
  ls -la .gitignore 2>&1 || true
fi

# --- 4b / D-14: every new pattern proves itself against its target path -----
# One `git check-ignore -v` per pattern, each emitting its own pass/fail, so a
# single silently-dead pattern cannot hide behind a passing sibling. Each row is
# `pattern|probe-path`. The probe path need not exist: check-ignore is a pure
# path-versus-pattern match, which is what lets a pattern written to govern
# FUTURE writes still be proven today.
FIX06_PROOFS=(
  "kdeglobals|stow/kde/.config/kdeglobals"
  "gtk.css|stow/gtk/.config/gtk-3.0/gtk.css"
  "gtk.css|stow/gtk/.config/gtk-4.0/gtk.css"
  "Kvantum/|.config/Kvantum/kvantum.kvconfig"
  "colors.lua|.config/hypr/hyprland/colors.lua"
  "colors.conf|.config/hypr/hyprlock/colors.conf"
  "fuzzel_theme.ini|.config/fuzzel/fuzzel_theme.ini"
  ".venv/|stow/system_monitor/.config/system_monitor/ping/.venv/pyvenv.cfg"
  ".mypy_cache/|.mypy_cache/probe.json"
  ".ruff_cache/|.ruff_cache/probe.json"
  ".pytest_cache/|.pytest_cache/probe"
  "*.pyc|scripts/probe.pyc"
  "*.swp|scripts/.probe.swp"
  "*~|scripts/probe~"
  ".DS_Store|.DS_Store"
  "*.sock|stow/qbittorrent/.config/qBittorrent/probe.sock"
  "*.socket|stow/qbittorrent/.config/qBittorrent/probe.socket"
  "*.lock|stow/qbittorrent/.config/qBittorrent/probe.lock"
)

# --- 4b coverage guard: the proof table matches the file, both directions ---
# The loop below can only prove the patterns it is handed. Two ways it could
# pass while observing less than it claims: a pattern is deleted from
# .gitignore and its row quietly stops meaning anything, or a pattern is ADDED
# to .gitignore later with no row and therefore no proof. Deriving the file's
# side by content — every non-comment, non-blank line from the D-14 generated-
# theme header to EOF — and requiring set equality closes both.
FIX06_IN_FILE="$(awk '/^# Generated theme output \(D-14\)/{f=1} f && !/^#/ && NF {print}' .gitignore | sort -u)"
FIX06_DECLARED="$(printf '%s\n' "${FIX06_PROOFS[@]}" | cut -d'|' -f1 | sort -u)"
FIX06_IN_FILE_N="$(printf '%s\n' "$FIX06_IN_FILE" | grep -c . || true)"
if [[ "$FIX06_IN_FILE_N" -gt 0 && "$FIX06_IN_FILE" == "$FIX06_DECLARED" ]]; then
  pass "4b guard: all $FIX06_IN_FILE_N D-14 patterns in .gitignore have a proof row, and every proof row names a pattern still in the file"
else
  fail "4b guard: the D-14 pattern set in .gitignore and the proof table have diverged — a pattern is unproven or a proof row is stale"
  diff <(printf '%s\n' "$FIX06_IN_FILE") <(printf '%s\n' "$FIX06_DECLARED") || true
fi

for row in "${FIX06_PROOFS[@]}"; do
  FIX06_PATTERN="${row%%|*}"
  FIX06_PROBE="${row#*|}"
  # Capture before testing: the -v output is both the verdict and the evidence,
  # and `set -e` would kill the script on the non-zero exit we are measuring.
  FIX06_OUT="$(git check-ignore -v -- "$FIX06_PROBE" 2>/dev/null || true)"
  if [[ -z "$FIX06_OUT" ]]; then
    fail "4b check-ignore: pattern '$FIX06_PATTERN' does NOT reach $FIX06_PROBE (exit 1 — the pattern is dead, as .gitignore lines 1-2 are)"
    git check-ignore -v -- "$FIX06_PROBE" || true
    continue
  fi
  # `<source>:<lineno>:<pattern>\t<pathname>`. Attributing the match to the
  # EXPECTED pattern matters: without it a proof could be satisfied by some
  # unrelated pre-existing line and report green for a pattern never written.
  FIX06_SRC="$(printf '%s' "$FIX06_OUT" | cut -f1 | cut -d: -f1)"
  FIX06_HIT="$(printf '%s' "$FIX06_OUT" | cut -f1 | cut -d: -f3-)"
  if [[ "$FIX06_SRC" == ".gitignore" && "$FIX06_HIT" == "$FIX06_PATTERN" ]]; then
    pass "4b check-ignore: pattern '$FIX06_PATTERN' reaches $FIX06_PROBE"
  else
    fail "4b check-ignore: $FIX06_PROBE is ignored, but by '$FIX06_HIT' from '$FIX06_SRC', not by the expected '$FIX06_PATTERN'"
    git check-ignore -v -- "$FIX06_PROBE" || true
  fi
done

# --- 4b negative controls: authored source must NOT be ignored -------------
# Without these, an over-broad pattern that swallowed the repo would be
# celebrated by the loop above — every probe would pass. general.lua and
# hyprlock.conf are here specifically: they are what a careless `*.lua` or
# `*.conf` instead of `colors.lua` / `colors.conf` would eat.
FIX06_MUST_NOT_IGNORE=(
  arch/btop.sh
  .config/hypr/custom/general.lua
  .config/hypr/hyprlock.conf
  stow/zsh/.zshrc
  README.md
  scripts/phase17-unblock-assert.sh
)
for p in "${FIX06_MUST_NOT_IGNORE[@]}"; do
  if [[ ! -e "$p" ]]; then
    # A control over a path that no longer exists proves nothing about breadth.
    fail "4b negative control path is missing, so over-breadth could not be tested on it: $p"
  elif git check-ignore -q -- "$p"; then
    fail "4b an ignore pattern swallows authored source: $p"
    git check-ignore -v -- "$p" || true
  else
    pass "4b negative control: authored source is not ignored: $p"
  fi
done

# --- 4b breadth sweep: the whole tracked tree, not a hand-picked sample -----
# --no-index is required. By default check-ignore reports a TRACKED file as not
# ignored, which would make this sweep silently blind to exactly the over-broad
# pattern it exists to catch. Expected hits are the three below and nothing
# else: .config/kdeglobals is the generated theme file this phase deliberately
# targets, and the two research-cache blobs are matched by a pre-existing line.
FIX06_SWEEP="$(git ls-files | git check-ignore --no-index --stdin -v 2>/dev/null | cut -f2 | sort -u || true)"
FIX06_SWEEP_EXPECTED="$(printf '%s\n' \
  .config/kdeglobals \
  .planning/research/.cache/2f4b26ce890661ba0645dd78d447abbf7b378f04b5839ad8e198626b1cb1d55f.json \
  .planning/research/.cache/dfdd484be7d5ea93abf51575e0a89a7a22af4ff586b669c939200b3f1ede0a78.json \
  | sort -u)"
if [[ "$FIX06_SWEEP" == "$FIX06_SWEEP_EXPECTED" ]]; then
  pass "4b breadth sweep: across all $(git ls-files | wc -l || true) tracked files the ignore set reaches only the 3 expected generated/cache paths"
else
  fail "4b breadth sweep: the set of tracked files an ignore pattern reaches has changed — a pattern is over-broad, or an expected path moved"
  diff <(printf '%s\n' "$FIX06_SWEEP_EXPECTED") <(printf '%s\n' "$FIX06_SWEEP") || true
fi

# --- 4b / F-9: the tracked-file exemption, made observable ------------------
# The reason this plan does NOT untrack .config/kdeglobals. A gitignore line has
# no effect on a file already in the index, so the pattern governs future writes
# only. Asserting all three facts together stops a later reader concluding from
# the exit-1 alone that the pattern is broken, and stops a silent untracking
# passing unnoticed — untracking it is Phase 18's call under FIX-03.
if [[ -n "$(git ls-files .config/kdeglobals)" ]]; then
  pass "4b F-9: .config/kdeglobals is still tracked (untracking it is a Phase 18 / FIX-03 decision, not this plan's)"
else
  fail "4b F-9: .config/kdeglobals is no longer tracked — a file another phase owns was untracked"
fi
if git check-ignore -q -- .config/kdeglobals; then
  fail "4b F-9: check-ignore reports the TRACKED .config/kdeglobals as ignored, contradicting the index-aware behaviour this handoff rests on"
else
  pass "4b F-9: check-ignore exits non-zero on the tracked .config/kdeglobals — a gitignore line does not reach a tracked file"
fi
if git check-ignore -q --no-index -- .config/kdeglobals; then
  pass "4b F-9: under --no-index the 'kdeglobals' pattern does reach .config/kdeglobals, so it correctly governs any future write"
else
  fail "4b F-9: even under --no-index no pattern reaches .config/kdeglobals — the generated-theme pattern is dead"
  git check-ignore -v --no-index -- .config/kdeglobals || true
fi

# =============================================================================
# criterion 4 / FIX-06 — the scan half. Sections 4c and 4d (plan 17-04).
#
# 4a and 4b above cover git METADATA (.gitattributes, .gitignore). This half
# covers the SCAN: that a real secret scanner runs over both surfaces and that
# every finding it once reported was individually dispositioned with a written
# reason rather than blanket-suppressed.
#
# Two surfaces, deliberately both. `gitleaks git` walks commit history;
# `gitleaks dir` walks the working tree. They cover different things — a file
# deleted from the tree survives in history, and an untracked file exists only
# in the tree — so a green on one is not a green on the other. `gitleaks
# detect` does not exist in 8.x and a typo'd sub-command is a loud error, not a
# silent pass.
#
# NON-MUTATING. Both invocations are read-only walks. Neither carries
# --report-path, so neither writes a report file; the verdict is the exit code.
# Every invocation carries --redact, so no matched value can reach stdout even
# on a failure dump.
#
# Timing note (plan 17-04): the history scan reads ~2600 commits / ~35 MB in
# under 3 seconds on this repo, so it stays on the per-commit clock with the
# rest of this script rather than moving behind the per-wave sampling rate.
# =============================================================================
echo "=== Phase 17 criterion 4 / FIX-06 secret scan (4c, 4d) ==="

# --- 4c guard: a missing scanner is a loud red, never a skipped section -----
# Without this guard the two scans below would simply not run, and a reader of
# an all-green log would conclude the repo was scanned clean when nothing was
# scanned at all. That is the same "green produced by narrowing the instrument"
# failure the phase prohibits, arrived at by absence instead of by config.
GITLEAKS_BIN="$(command -v gitleaks 2>/dev/null || true)"
if [[ -n "$GITLEAKS_BIN" ]]; then
  pass "4c guard: gitleaks is on PATH at $GITLEAKS_BIN"
else
  fail "4c guard: gitleaks is not on PATH — the two scans below cannot run and MUST NOT be read as clean"
fi

# --- 4c / D-11: the binary is the Arch package, not a name-alike ------------
# `gitleaks` also names an unrelated npm package. Resolving on PATH proves only
# that something answers to the name. `pacman -Qo` ties the resolved path back
# to extra/gitleaks, which makes the homonym hazard a checked claim rather than
# an assumption. Guarded: pacman -Qo exits non-zero on an unowned file, which
# under `set -e` would abort the script rather than report.
if [[ -n "$GITLEAKS_BIN" ]]; then
  if GITLEAKS_OWNER="$(pacman -Qo "$GITLEAKS_BIN" 2>/dev/null)"; then
    pass "4c package ownership: $GITLEAKS_OWNER"
  else
    fail "4c package ownership: $GITLEAKS_BIN resolves on PATH but no pacman package owns it — it may be a cross-ecosystem homonym rather than extra/gitleaks"
  fi
fi

# --- 4c: the history surface ------------------------------------------------
# gitleaks exits 0 on no findings and non-zero when it finds something OR when
# it fails to run. Both are the wrong verdict here and both are reported, so a
# broken invocation cannot masquerade as a clean one.
if [[ -n "$GITLEAKS_BIN" ]]; then
  if gitleaks git . --redact --no-banner >/dev/null 2>&1; then
    pass "4c history scan: 'gitleaks git . --redact --no-banner' exits 0 — no unreviewed finding in git history"
  else
    fail "4c history scan: 'gitleaks git . --redact --no-banner' did not return the clean verdict"
    gitleaks git . --redact --no-banner 2>&1 | tail -20 || true
  fi
fi

# --- 4c: the working-tree surface -------------------------------------------
if [[ -n "$GITLEAKS_BIN" ]]; then
  if gitleaks dir . --redact --no-banner >/dev/null 2>&1; then
    pass "4c working-tree scan: 'gitleaks dir . --redact --no-banner' exits 0 — no unreviewed finding in the working tree"
  else
    fail "4c working-tree scan: 'gitleaks dir . --redact --no-banner' did not return the clean verdict"
    gitleaks dir . --redact --no-banner 2>&1 | tail -20 || true
  fi
fi

# --- 4d: every accepted finding carries a written reason --------------------
# Conditional by construction (D-11): the config exists if and only if the
# triage accepted at least one finding. With zero accepted findings there is no
# file and nothing is verified, so that branch emits [INFO] — not [PASS], which
# would claim a check that never ran.
if [[ -f .gitleaks.toml ]]; then
  ALLOWLIST_COUNT="$(grep -c '^\[\[allowlists\]\]' .gitleaks.toml || true)"
  COMMENT_COUNT="$(grep -c '^[[:space:]]*#' .gitleaks.toml || true)"

  if [[ "$ALLOWLIST_COUNT" -gt 0 ]]; then
    pass "4d guard: .gitleaks.toml holds $ALLOWLIST_COUNT active [[allowlists]] entr(ies) — the per-entry checks below cannot pass vacuously"
  else
    fail "4d guard: .gitleaks.toml exists but holds no active [[allowlists]] entry — either the file is a stub or every entry was commented out"
  fi

  if [[ "$COMMENT_COUNT" -gt 0 ]]; then
    pass "4d: .gitleaks.toml carries $COMMENT_COUNT comment line(s) recording the triage reasoning"
  else
    fail "4d: .gitleaks.toml carries no comment line at all — an allowlist with no written reasons"
  fi

  # Each `[[allowlists]]` header must be IMMEDIATELY followed by a description
  # carrying a substantive reason. Adjacency is the point: a reason three
  # entries away cannot be matched to the entry it excuses. 40 characters is a
  # deliberate floor — it rejects "false positive" and "not a secret", which
  # record a verdict without recording why.
  BAD_REASON="$(awk '
    /^\[\[allowlists\]\]$/ {
      hdr = NR
      if ((getline nxt) <= 0) { print hdr ": entry has no following line"; next }
      if (nxt !~ /^description = ".+"$/) { print hdr ": next line is not a description ("  nxt  ")"; next }
      body = nxt
      sub(/^description = "/, "", body); sub(/"$/, "", body)
      if (length(body) < 40) { print hdr ": description is only " length(body) " chars, too short to be a reason" }
    }
  ' .gitleaks.toml)"
  if [[ -z "$BAD_REASON" ]]; then
    pass "4d: all $ALLOWLIST_COUNT allowlist entr(ies) are immediately followed by a description line stating a reason"
  else
    fail "4d: an allowlist entry is missing an adjacent written reason"
    printf '       %s\n' "$BAD_REASON"
  fi

  # Every entry must be narrowly scoped. `condition = "AND"` is not cosmetic:
  # the gitleaks default is OR, under which a multi-key entry allowlists any
  # finding matching ANY ONE key — a blanket suppression wearing the costume of
  # a narrow one. `targetRules` is not cosmetic either: without it a global
  # allowlist carrying `paths` makes `gitleaks dir` skip the matching file
  # wholesale before reading a byte, and `condition = "AND"` does NOT prevent
  # that. Both counts must equal the entry count.
  AND_COUNT="$(grep -c '^condition = "AND"$' .gitleaks.toml || true)"
  TARGETRULES_COUNT="$(grep -c '^targetRules = ' .gitleaks.toml || true)"
  if [[ "$AND_COUNT" -eq "$ALLOWLIST_COUNT" && "$TARGETRULES_COUNT" -eq "$ALLOWLIST_COUNT" ]]; then
    pass "4d scoping: all $ALLOWLIST_COUNT entr(ies) carry both condition = \"AND\" and targetRules — no entry degrades to an OR match or to a whole-file skip"
  else
    fail "4d scoping: $AND_COUNT of $ALLOWLIST_COUNT entr(ies) carry condition = \"AND\" and $TARGETRULES_COUNT carry targetRules — an entry is broader than it reads"
    grep -n '^\[\[allowlists\]\]$\|^condition = \|^targetRules = ' .gitleaks.toml || true
  fi

  # The config must not exempt itself. .gitleaks.toml is tracked, so it sits
  # inside the 4c working-tree surface — which is what proves no entry above
  # contains a matched secret value. An entry scoped to this file's own path
  # would remove that proof.
  if grep -q "gitleaks\\\\.toml" .gitleaks.toml; then
    fail "4d self-scope: an allowlist entry names .gitleaks.toml itself — the config would exempt itself from the working-tree scan that proves it holds no secret value"
    grep -n "gitleaks\\\\.toml" .gitleaks.toml || true
  else
    pass "4d self-scope: no entry names .gitleaks.toml, so the config stays inside the 4c working-tree surface that proves it carries no matched value"
  fi
else
  info "4d: .gitleaks.toml does not exist, so zero findings were accepted and there is no allowlist to check. This is [INFO] and not [PASS] — nothing was verified."
fi

# =============================================================================
# D-02 folding audit — READ-ONLY, [INFO] only, never [PASS]/[FAIL].
#
# This section deliberately asserts nothing. `--no-folding` governs NEW stow
# runs only, so the directories that folded before this phase stay folded and
# this phase does not unfold one. The audit exists to produce a live record
# rather than a note frozen into a research artifact, and Phase 18 — which owns
# the tree taxonomy — inherits that list and decides what each folded directory
# becomes. Unfolding later is a `stow -D` plus a re-stow with --no-folding.
#
# Non-mutating by construction: the section runs `find`, `readlink` and a `-d`
# test. It invokes no stow, and removes, moves or links nothing. (The `-lname`
# predicate below is a find test, not the link-creating command it echoes.)
# =============================================================================
echo "=== Phase 17 D-02 folding audit (read-only, [INFO] only) ==="

FOLDED_COUNT=0
while IFS= read -r LINKPATH; do
  [[ -n "$LINKPATH" ]] || continue
  if [[ -d "$LINKPATH" ]]; then
    FOLDED_COUNT=$((FOLDED_COUNT + 1))
    info "D-02 folded directory symlink: $LINKPATH -> $(readlink "$LINKPATH")"
  fi
done < <(find "$HOME/.config" -maxdepth 2 -type l -lname '*.dotfiles*' 2>/dev/null | sort)

info "D-02 audit complete: $FOLDED_COUNT folded stow directory symlink(s) under \$HOME/.config. Phase 17 does not unfold them — --no-folding governs new runs only. Phase 18 owns the tree taxonomy that decides what each folded directory becomes."

echo "=== done: FAIL=${FAIL} ==="
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
