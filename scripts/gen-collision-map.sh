#!/usr/bin/env bash
# Phase 18 collision-map generator (D-03, D-58, D-59).
#
# Derives the installer collision map mechanically from a dots-hyprland source
# root and emits the complete TSV -- comment header included -- to STDOUT.
#
# Usage (from REPO_ROOT):
#   ./scripts/gen-collision-map.sh                  # the pinned submodule
#   ./scripts/gen-collision-map.sh /path/to/tree    # any other source root (D-55)
#
# Real regeneration is:
#   ./scripts/gen-collision-map.sh > collision-map.tsv
#
# Constraints:
#   - STDOUT ONLY (D-59). This script never opens collision-map.tsv for writing,
#     so an interrupted regeneration cannot leave a half-written map behind.
#   - Non-mutating. It reads the source root and runs `git rev-parse` inside it.
#     It writes nothing, anywhere.
#   - An unrecognised installer primitive is a LOUD failure (D-03): the script
#     names the primitive and its source line and exits non-zero rather than
#     defaulting to a benign-looking row. Because of that rule, every loop that
#     can reach emit_row must run in THIS shell, never inside a pipeline or a
#     command substitution -- an `exit` in a subshell leaves only the subshell
#     and lets the generator sail on (see the comment at
#     scripts/phase14-verify.sh:50-57). The loops are therefore fed by process
#     substitution (`done < <( ... )`), the technique at
#     scripts/phase17-unblock-assert.sh:933.
#   - The primitive -> (symlink_outcome, repo_outcome) lookup is hand-authored
#     from 18-RESEARCH.md "The Verified Primitive Matrix", every row of which was
#     reproduced end to end with falsification probes. It is deliberately NOT
#     transcribed from .planning/research/PITFALLS.md:285-290, which merges
#     install_dir with install_dir__ignore_existing and describes only the benign
#     one (RESEARCH F-1); copying that table produces a wrong row for the
#     $XDG_DATA_HOME/konsole destination at 3.files-legacy.sh:18.
#   - The `tree` column is DERIVED from the two outcome columns, never authored
#     (D-05). Only `stow` and `restow` are ever emitted. `capture` is not
#     derivable from an installer-scoped map and never appears here; that
#     membership is hand-assigned prose in capture/README.md.
#   - No row count is hard-coded, here or in the assert. A pin bump that adds a
#     destination must add a row, not falsify a constant.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

MODE="map"
if [[ "${1:-}" == "--restow-table" ]]; then
  MODE="table"
  shift
fi

SRC_ROOT="${1:-$REPO_ROOT/vendor/dots-hyprland}"
LEGACY_NAME="3.files-legacy.sh"
LEGACY_REL="sdata/subcmd-install/$LEGACY_NAME"
LEGACY="$SRC_ROOT/$LEGACY_REL"

# --- refusals -----------------------------------------------------------------
# A source root that cannot produce rows must fail loudly. A header-only map
# would diff clean against nothing and silently destroy the regenerate-and-diff
# signal that CAP-03 rests on.
if [[ ! -d "$SRC_ROOT/dots/.config" ]]; then
  echo "[FAIL] Source root has no dots/.config/ directory: $SRC_ROOT/dots/.config" >&2
  echo "[FAIL] Refusing to emit a header-only map -- it would diff clean against nothing." >&2
  echo "[FAIL] Fix (from REPO_ROOT): git submodule update --init --recursive vendor/dots-hyprland" >&2
  exit 1
fi

if [[ ! -s "$LEGACY" ]]; then
  echo "[FAIL] Source root has no readable $LEGACY_REL: $LEGACY" >&2
  echo "[FAIL] That file is the map's sole source; without it there is nothing to parse." >&2
  echo "[FAIL] Fix (from REPO_ROOT): git submodule update --init --recursive vendor/dots-hyprland" >&2
  exit 1
fi

# --- pin (D-60) ---------------------------------------------------------------
# Read at generation time, never typed. A pin bump therefore dirties the map even
# when no row moves -- that is the intended re-review signal. `.git` presence is
# tested first so a non-checkout source root (the D-55 fake tree) cannot have
# `rev-parse` walk up into an unrelated parent repository.
PIN="unknown-not-a-git-checkout"
if [[ -e "$SRC_ROOT/.git" ]]; then
  PIN="$(git -C "$SRC_ROOT" rev-parse HEAD 2>/dev/null || true)"
  [[ -n "$PIN" ]] || PIN="unknown-not-a-git-checkout"
fi

# --- the verified primitive matrix (RESEARCH "The Verified Primitive Matrix") --
# Sets SYM and REPO for a known primitive; returns 1 for anything else.
SYM=""
REPO=""
lookup_outcomes() {
  case "$1" in
    install_file)                 SYM="preserved"; REPO="OVERWRITTEN" ;;
    install_file__auto_backup)    SYM="DESTROYED"; REPO="untouched" ;;
    install_dir)                  SYM="DESTROYED"; REPO="untouched" ;;
    install_dir__sync)            SYM="DESTROYED"; REPO="untouched" ;;
    install_dir__sync_exclude)    SYM="DESTROYED"; REPO="untouched" ;;
    install_dir__ignore_existing) SYM="preserved"; REPO="untouched" ;;
    inline_rename)                SYM="DESTROYED"; REPO="untouched" ;;
    *) return 1 ;;
  esac
}

# D-03's loud failure. Runs in the main shell; the `exit` is reachable.
require_known_primitive() {
  local prim="$1" src="$2"
  if ! lookup_outcomes "$prim"; then
    echo "[FAIL] Unrecognised installer primitive: $prim" >&2
    echo "[FAIL] Source: $src" >&2
    echo "[FAIL] The primitive matrix in this generator has no entry for it, so its" >&2
    echo "[FAIL] symlink_outcome and repo_outcome are unknown. Emitting a defaulted row" >&2
    echo "[FAIL] would be silent misinformation about a possibly destroying primitive." >&2
    echo "[FAIL] Fix: reproduce the primitive's behaviour against a symlinked destination," >&2
    echo "[FAIL] then add it to lookup_outcomes() in $0 with the observed outcomes." >&2
    exit 1
  fi
}

ROWS=()
emit_row() {
  local dest="$1" prim="$2" src="$3" tree row
  require_known_primitive "$prim" "$src"
  # D-05: derived, never authored. Two values only.
  if [[ "$SYM" == "preserved" && "$REPO" == "untouched" ]]; then
    tree="stow"
  else
    tree="restow"
  fi
  printf -v row '%s\t%s\t%s\t%s\t%s\t%s' "$dest" "$prim" "$SYM" "$REPO" "$tree" "$src"
  ROWS+=("$row")
}

# Strips the installer's quoting and brace form, and resolves the `$i` of a
# single-value `for i in ...` loop. D-06: the XDG variable stays literal.
normalize_dest() {
  local d="$1" ival="${2:-}"
  d="${d//\"/}"
  d="${d//\$\{XDG_CONFIG_HOME\}/\$XDG_CONFIG_HOME}"
  d="${d//\$\{XDG_DATA_HOME\}/\$XDG_DATA_HOME}"
  if [[ -n "$ival" ]]; then
    d="${d//\$i/$ival}"
  fi
  printf '%s' "$d"
}

# --- parse the named call sites ----------------------------------------------
IN_MISC=0
MISC_FIND_LINE=""
MISC_FIND_TEXT=""
MISC_DIR_PRIM=""
MISC_DIR_LINE=""
MISC_FILE_PRIM=""
MISC_FILE_LINE=""
LOOP_VALUES=()
GAP_LINES=()

while IFS= read -r NUMBERED; do
  LINENO_SRC="${NUMBERED%%:*}"
  LINE="${NUMBERED#*:}"
  TRIMMED="${LINE#"${LINE%%[![:space:]]*}"}"

  [[ -n "$TRIMMED" ]] || continue
  [[ "$TRIMMED" == \#* ]] && continue

  # `for i in ...; do` -- either the MISC find loop or a literal one-value loop.
  if [[ "$TRIMMED" =~ ^for[[:space:]]+i[[:space:]]+in[[:space:]]+(.*)\;[[:space:]]*do[[:space:]]*$ ]]; then
    LIST="${BASH_REMATCH[1]}"
    if [[ "$LIST" == *'$(find'* ]]; then
      IN_MISC=1
      MISC_FIND_LINE="$LINENO_SRC"
      MISC_FIND_TEXT="$TRIMMED"
      LOOP_VALUES=()
    else
      read -r -a LOOP_VALUES <<< "$LIST"
    fi
    continue
  fi

  if [[ "$TRIMMED" == done* ]]; then
    IN_MISC=0
    LOOP_VALUES=()
    continue
  fi

  [[ "$TRIMMED" == *install_* ]] || continue

  # Locate the primitive word; it is not always the first word on the line
  # (`];then install_dir__sync ...`, `*) install_file ... ;;`).
  read -r -a WORDS <<< "$TRIMMED"
  IDX=-1
  for K in "${!WORDS[@]}"; do
    if [[ "${WORDS[$K]}" == install_* ]]; then
      IDX="$K"
      break
    fi
  done
  (( IDX >= 0 )) || continue

  PRIM="${WORDS[$IDX]}"
  SRC_ARG="${WORDS[$((IDX + 1))]:-}"
  DEST_ARG="${WORDS[$((IDX + 2))]:-}"
  SRC_REF="$LEGACY_NAME:$LINENO_SRC"

  # Even a call site this map does not cover must have a known primitive.
  require_known_primitive "$PRIM" "$SRC_REF"

  if (( IN_MISC == 1 )); then
    # The MISC loop body is expanded below, from the source tree, not from here.
    # Capture only which primitive each arm of the [ -d ] / [ -f ] test uses.
    if [[ "$TRIMMED" == *"[ -d "* ]]; then
      MISC_DIR_PRIM="$PRIM"
      MISC_DIR_LINE="$LINENO_SRC"
    elif [[ "$TRIMMED" == *"[ -f "* ]]; then
      MISC_FILE_PRIM="$PRIM"
      MISC_FILE_LINE="$LINENO_SRC"
    fi
    continue
  fi

  # Alternate-source branches (dots-extra/) are reached only by a flag this repo
  # does not use -- upstream's --fontset and --via-nix. They are the two recorded
  # coverage gaps (RESEARCH F-13, D-32), not modelled destinations.
  SRC_ARG_CLEAN="${SRC_ARG//\"/}"
  if [[ "$SRC_ARG_CLEAN" == dots-extra/* ]]; then
    GAP_LINES+=("$LINENO_SRC")
    continue
  fi

  if [[ "$DEST_ARG" == *'$i'* ]]; then
    if (( ${#LOOP_VALUES[@]} == 0 )); then
      echo "[FAIL] Destination references \$i outside any resolvable loop: $SRC_REF" >&2
      echo "[FAIL] Line: $TRIMMED" >&2
      echo "[FAIL] The generator cannot name the destination, and a row naming a" >&2
      echo "[FAIL] literal \$i would be wrong in a way no reader could act on." >&2
      exit 1
    fi
    for IVAL in "${LOOP_VALUES[@]}"; do
      emit_row "$(normalize_dest "$DEST_ARG" "$IVAL")" "$PRIM" "$SRC_REF"
    done
  else
    emit_row "$(normalize_dest "$DEST_ARG")" "$PRIM" "$SRC_REF"
  fi
done < <(grep -n '' -- "$LEGACY")

# --- the MISC loop, expanded against the source tree (D-02, D-58, F-3) --------
if [[ -n "$MISC_FIND_LINE" ]]; then
  if [[ -z "$MISC_DIR_PRIM" || -z "$MISC_FILE_PRIM" ]]; then
    echo "[FAIL] The MISC loop at $LEGACY_NAME:$MISC_FIND_LINE no longer carries both a" >&2
    echo "[FAIL] [ -d ] directory arm and a [ -f ] file arm. The generator cannot tell" >&2
    echo "[FAIL] which primitive each expanded entry would be installed with." >&2
    exit 1
  fi

  # The exclusions below are reproduced verbatim from the installer. If upstream
  # changes them, the map would silently model the wrong destination set, so the
  # source line is checked against them rather than trusted.
  for EXCL in quickshell fish hypr fontconfig; do
    if [[ "$MISC_FIND_TEXT" != *"! -name '$EXCL'"* ]]; then
      echo "[FAIL] The MISC find expression at $LEGACY_NAME:$MISC_FIND_LINE no longer excludes '$EXCL'." >&2
      echo "[FAIL] Line: $MISC_FIND_TEXT" >&2
      echo "[FAIL] The generator reproduces the installer's exclusions verbatim; an upstream" >&2
      echo "[FAIL] change to them must be reviewed, not silently absorbed." >&2
      exit 1
    fi
  done

  # GNU find returns readdir order (RESEARCH F-3). LC_ALL=C sort pins both the
  # order and the collation, so `Kvantum` sorts identically on any host.
  while IFS= read -r ENTRY; do
    [[ -n "$ENTRY" ]] || continue
    if [[ -d "$SRC_ROOT/dots/.config/$ENTRY" ]]; then
      emit_row "\$XDG_CONFIG_HOME/$ENTRY" "$MISC_DIR_PRIM" "$LEGACY_NAME:$MISC_DIR_LINE"
    elif [[ -f "$SRC_ROOT/dots/.config/$ENTRY" ]]; then
      emit_row "\$XDG_CONFIG_HOME/$ENTRY" "$MISC_FILE_PRIM" "$LEGACY_NAME:$MISC_FILE_LINE"
    fi
  done < <(find "$SRC_ROOT/dots/.config/" -mindepth 1 -maxdepth 1 \
             ! -name 'quickshell' ! -name 'fish' ! -name 'hypr' ! -name 'fontconfig' \
             -exec basename {} \; | LC_ALL=C sort)
fi

# --- the inline rename, special-cased by name (D-03) --------------------------
# `mv "$XDG_CONFIG_HOME/hypr/hyprland.conf" ...conf.old` is a bare rename with no
# source file and no primitive call. Primitive parsing would silently omit it and
# the loud-failure rule would never fire, so it is matched by name. Its
# disappearance from upstream is still visible -- as a missing row in the diff.
mapfile -t LEGACY_LINES < "$LEGACY"
MV_LINE=""
for (( N = 0; N < ${#LEGACY_LINES[@]}; N++ )); do
  if [[ "${LEGACY_LINES[$N]}" == *'mv "${XDG_CONFIG_HOME}/hypr/hyprland.conf"'* ]]; then
    MV_LINE=$(( N + 1 ))
    break
  fi
done

if [[ -n "$MV_LINE" ]]; then
  IF_LINE=""
  for (( N = MV_LINE - 1; N >= 1; N-- )); do
    T="${LEGACY_LINES[$((N - 1))]}"
    T="${T#"${T%%[![:space:]]*}"}"
    if [[ "$T" == if\ * ]]; then
      IF_LINE="$N"
      break
    fi
  done
  FI_LINE=""
  for (( N = MV_LINE + 1; N <= ${#LEGACY_LINES[@]}; N++ )); do
    T="${LEGACY_LINES[$((N - 1))]}"
    T="${T#"${T%%[![:space:]]*}"}"
    if [[ "$T" == "fi" ]]; then
      FI_LINE="$N"
      break
    fi
  done
  if [[ -z "$IF_LINE" || -z "$FI_LINE" ]]; then
    echo "[FAIL] Found the inline hyprland.conf rename at $LEGACY_NAME:$MV_LINE but could not" >&2
    echo "[FAIL] resolve its enclosing if/fi block, so its source citation would be wrong." >&2
    exit 1
  fi
  emit_row "\$XDG_CONFIG_HOME/hypr/hyprland.conf" "inline_rename" "$LEGACY_NAME:$IF_LINE-$FI_LINE"
fi

# --- restow table mode (D-09, D-12, D-13) ------------------------------------
emit_restow_table() {
  local restow_dir="$REPO_ROOT/restow"
  if [[ ! -d "$restow_dir" ]]; then
    echo "[FAIL] restow directory not found: $restow_dir" >&2
    exit 1
  fi

  local -a pkgs=()
  while IFS= read -r d; do
    [[ -n "$d" ]] && pkgs+=("$(basename "$d")")
  done < <(find "$restow_dir" -mindepth 1 -maxdepth 1 -type d | LC_ALL=C sort)

  if (( ${#pkgs[@]} == 0 )); then
    echo "[FAIL] restow/ holds zero packages" >&2
    exit 1
  fi

  printf '| Package | Tag | Recovery Command |\n'
  printf '|---|---|---|\n'

  for pkg in "${pkgs[@]}"; do
    local pkg_dir="$restow_dir/$pkg"
    local tag=""
    local sample_path=""
    local has_destroyed=0
    local has_overwritten=0

    while IFS= read -r -d '' f; do
      local rel="${f#"$pkg_dir"/}"
      local xdg_target=""
      if [[ "$rel" == .config/* ]]; then
        xdg_target="\$XDG_CONFIG_HOME/${rel#.config/}"
      elif [[ "$rel" == .local/share/* ]]; then
        xdg_target="\$XDG_DATA_HOME/${rel#.local/share/}"
      else
        xdg_target="\$HOME/$rel"
      fi

      for row in "${ROWS[@]}"; do
        IFS=$'\t' read -r r_dest r_prim r_sym r_repo r_tree r_src <<< "$row"
        if [[ "$xdg_target" == "$r_dest"* || "$r_dest" == "$xdg_target"* ]]; then
          if [[ "$r_sym" == "DESTROYED" ]]; then
            has_destroyed=1
          elif [[ "$r_repo" == "OVERWRITTEN" ]]; then
            has_overwritten=1
            if [[ -z "$sample_path" ]]; then
              sample_path="restow/$pkg/$rel"
            fi
          fi
        fi
      done
    done < <(find "$pkg_dir" -type f -print0 | LC_ALL=C sort -z)

    if (( has_destroyed == 1 )); then
      tag="rsync-replace"
      printf '| `%s` | `%s` | `cd restow && stow --verbose=5 --no-folding -t ~ %s` |\n' "$pkg" "$tag" "$pkg"
    elif (( has_overwritten == 1 )); then
      tag="cp-through"
      if [[ -z "$sample_path" ]]; then
        sample_path="restow/$pkg"
      fi
      printf '| `%s` | `%s` | `git checkout -- %s && cd restow && stow --verbose=5 --no-folding -t ~ %s` |\n' "$pkg" "$tag" "$sample_path" "$pkg"
    else
      echo "[FAIL] Package '$pkg' under restow/ matches no collision-map row with a destroying or overwriting outcome" >&2
      exit 1
    fi
  done
}

if [[ "$MODE" == "table" ]]; then
  emit_restow_table
  exit 0
fi

# --- refuse an empty body -----------------------------------------------------
if (( ${#ROWS[@]} == 0 )); then
  echo "[FAIL] Parsed $LEGACY and emitted zero rows." >&2
  echo "[FAIL] A header-only map diffs clean against nothing. Refusing to emit it." >&2
  exit 1
fi

# --- header (D-01, D-60) ------------------------------------------------------
# The header is where this artifact's reasoning lives, so a future reader does
# not re-derive it -- or "fix" the map to match a host observation.
printf '# collision-map v1  pin=%s\n' "$PIN"
printf '#\n'
printf '# Generated -- do not hand-edit. Regenerate with, from REPO_ROOT:\n'
printf '#   ./scripts/gen-collision-map.sh > collision-map.tsv\n'
printf '#\n'
printf '# Columns (tab-separated):\n'
printf '# dest\tprimitive\tsymlink_outcome\trepo_outcome\ttree\tsource\n'
printf '#\n'
printf '# tree is DERIVED from the two outcome columns, never authored (D-05):\n'
printf '#   symlink preserved AND repo untouched  -> stow\n'
printf '#   symlink DESTROYED OR  repo OVERWRITTEN -> restow\n'
printf '# Those are the only two values that ever appear. `capture` is not derivable\n'
printf '# from an installer-scoped map -- no installer primitive renames over the link\n'
printf '# the way switchwall.sh and matugen do -- so capture/ membership is hand-assigned\n'
printf '# prose in capture/README.md and is deliberately absent from this column.\n'
printf '#\n'
printf '# source cites the line of the primitive call site in %s at the pin above.\n' "$LEGACY_REL"
printf '# The MISC rows cite the [ -d ] / [ -f ] arm they were installed by; the inline\n'
printf '# rename cites its whole if/fi block.\n'
printf '#\n'
printf '# ORDERING (RESEARCH F-3) -- a guarantee, not an accident: rows are emitted\n'
printf '# through LC_ALL=C sort, keyed on the whole line and therefore on dest first.\n'
printf '# GNU find returns readdir order, which differs across filesystems and after\n'
printf '# directory-entry churn; without the sort the assert regenerate-and-diff would\n'
printf '# fire spuriously on a clean tree and the real pin-bump signal would be ignored.\n'
printf '#\n'
printf '# COVERAGE (D-04): every destination %s writes, whichever XDG base it\n' "$LEGACY_NAME"
printf '# lands in -- so $XDG_DATA_HOME/konsole and $XDG_DATA_HOME/icons/... are in,\n'
printf '# alongside the $XDG_CONFIG_HOME rows. 2.setups.sh is out: its only link-touching\n'
printf '# line is a `sudo ln -s` for a systemd unit outside $HOME, which nothing here can\n'
printf '# capture. Font *package* installation and installer state are out; the fontconfig\n'
printf '# *destination* is in.\n'
printf '#\n'
printf '# NO SKIP_* COLUMN (D-06): Phase 16 retired the safe profile, so there is one\n'
printf '# install path and every SKIP_* is false on it. Paths keep their literal XDG\n'
printf '# variable and are expanded at read time, which keeps the map host-independent.\n'
printf '#\n'
printf '# install_file__auto_backup RECORDS THE FIRSTRUN OUTCOME (RESEARCH F-5).\n'
printf '# Firstrun renames the target away (`mv $t $t.old`, 3.files.sh:102) -- DESTROYED.\n'
printf '# On this host that branch is currently DISARMED, because\n'
printf '# ~/.config/illogical-impulse/installed_true exists: an install run today writes a\n'
printf '# .new sidecar and leaves hypridle.conf and hyprlock.conf intact. Deleting that\n'
printf '# marker, or passing upstream --firstrun, re-arms it. An empirical spot-check will\n'
printf '# therefore contradict these rows. The rows are right; the observation is the\n'
printf '# disarmed branch. Do NOT "correct" the map to match the host.\n'
printf '#\n'
printf '# KNOWN COVERAGE GAPS (RESEARCH F-13), neither a defect:\n'
printf '#   %s:42 -- the alternate fontconfig source under dots-extra/fontsets/,\n' "$LEGACY_NAME"
printf '#     reached only by upstream --fontset. Same destination, different source.\n'
printf '#   %s:66 -- the alternate hypridle.conf source under dots-extra/via-nix/,\n' "$LEGACY_NAME"
printf '#     reached only by --via-nix. Same destination, same primitive.\n'
printf '#   %s:72 -- the fedora-only execs.conf append, unreachable on Arch.\n' "$LEGACY_NAME"
printf '# The generator skips a call site whose SOURCE argument lives under dots-extra/;\n'
printf '# it is a flag-reached alternate, not a modelled destination.\n'
printf '#\n'
printf '# ACCEPTED RISK (D-32), stated so the gap is auditable rather than silent: the\n'
printf '# CAP-08 gate is a deny-list of exactly one flag, --exp-files. Upstream nix, core\n'
printf '# and skip-family flags still forward, and so does --fontset, which reaches\n'
printf '# %s:42 -- a fontconfig source this map does not model. That is a\n' "$LEGACY_NAME"
printf '# deliberate, recorded coverage gap, not an oversight.\n'
printf '#\n'

printf '%s\n' "${ROWS[@]}" | LC_ALL=C sort
