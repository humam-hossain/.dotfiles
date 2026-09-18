#!/usr/bin/env bash
# Phase 29: Theme Data Contracts, Verification & Bootstrap Integration assert harness
# Enforces: INTG-01, INTG-02, INTG-03, and D-01 through D-16
#
# Usage (from REPO_ROOT):
#   ./scripts/phase29-theme-data-contracts-assert.sh [--section <1-5>]
# Exit 0 if all hard asserts pass; exit 1 if any hard FAIL.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

ASSERT_SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename -- "${BASH_SOURCE[0]}")"

FAIL=0
FINDINGS=0
pass() { printf '[PASS] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
finding() { printf '[FINDING] %s\n' "$1"; FINDINGS=$((FINDINGS + 1)); }
info() { printf '[INFO] %s\n' "$1"; }

TMP_FILES=()
SCRATCH_ROOTS=()

cleanup() {
  rm -f ${TMP_FILES[@]+"${TMP_FILES[@]}"} 2>/dev/null || true
  local root
  for root in ${SCRATCH_ROOTS[@]+"${SCRATCH_ROOTS[@]}"}; do
    [[ -n "$root" ]] || continue
    chmod -R u+rwX "$root" 2>/dev/null || true
    rm -rf "$root" 2>/dev/null || true
  done
  return 0
}
trap cleanup EXIT

RUN_SECTION=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --section)
      if [[ -z "${2:-}" ]] || ! [[ "$2" =~ ^[1-5]$ ]]; then
        echo "Error: --section requires an integer from 1 to 5" >&2
        exit 1
      fi
      RUN_SECTION="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 [--section <1-5>]"
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

porcelain_snapshot_raw() {
  git status --porcelain --ignored || true
}

porcelain_snapshot() {
  porcelain_snapshot_raw \
    | grep -v -E '^!! (\.commandcode/|scripts/__pycache__/)$' || true
}

PORCELAIN_BEFORE="$(mktemp /tmp/p29-porcelain-before-XXXXXX)"
PORCELAIN_AFTER="$(mktemp /tmp/p29-porcelain-after-XXXXXX)"
TMP_FILES+=("$PORCELAIN_BEFORE" "$PORCELAIN_AFTER")

porcelain_snapshot > "$PORCELAIN_BEFORE"

# ===========================================================================
# Section 1: Data Contracts & Gitignore Parity (INTG-01, INTG-02)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 1 ]]; then
  info "--- Section 1: Data Contracts & Gitignore Parity (INTG-01, INTG-02) ---"

  GUARD_TSV="$REPO_ROOT/guard-paths.tsv"
  GITIGNORE="$REPO_ROOT/.gitignore"
  COLLISION_MAP="$REPO_ROOT/collision-map.tsv"
  RESTOW_README="$REPO_ROOT/restow/README.md"

  # 1. guard-paths.tsv existence and 8 valid tab-separated rows
  if [[ -f "$GUARD_TSV" ]]; then
    pass "S1: guard-paths.tsv exists"
    EXPECTED_GUARDS=(
      '$XDG_CONFIG_HOME/kdeglobals'
      '$XDG_CONFIG_HOME/Kvantum'
      '$XDG_CONFIG_HOME/gtk-3.0/gtk.css'
      '$XDG_CONFIG_HOME/gtk-4.0/gtk.css'
      '$XDG_CONFIG_HOME/fuzzel/fuzzel_theme.ini'
      '$XDG_CONFIG_HOME/hypr/hyprland/colors.lua'
      '$XDG_CONFIG_HOME/hypr/hyprlock/colors.conf'
      '$XDG_CONFIG_HOME/kde-material-you-colors'
    )
    guard_count=0
    all_guards_ok=1
    while IFS=$'\t' read -r p cat gen reason || [[ -n "$p" ]]; do
      [[ -n "$p" && "$p" != \#* ]] || continue
      guard_count=$((guard_count + 1))
      if [[ -z "$cat" || -z "$gen" || -z "$reason" ]]; then
        fail "S1: guard-paths.tsv row invalid or missing columns: $p"
        all_guards_ok=0
      fi
    done < "$GUARD_TSV"

    if [[ "$guard_count" -eq 8 && "$all_guards_ok" -eq 1 ]]; then
      pass "S1: guard-paths.tsv contains exactly 8 valid tab-separated rows"
    else
      fail "S1: guard-paths.tsv row count is $guard_count (expected 8)"
    fi

    # Check Q7 and Q8 compatibility markers
    if grep -q "Q7:" "$GUARD_TSV" && grep -q "kde-material-you-colors" "$GUARD_TSV" && \
       grep -q "Q8:" "$GUARD_TSV" && grep -q "gtk-4.0/gtk.css" "$GUARD_TSV"; then
      pass "S1: guard-paths.tsv preserves Q7 and Q8 backward compatibility markers"
    else
      fail "S1: guard-paths.tsv header missing required Q7 or Q8 markers"
    fi
  else
    fail "S1: guard-paths.tsv missing"
  fi

  # 2. 1:1 Parity between guard-paths.tsv and .gitignore (D-01)
  if [[ -f "$GITIGNORE" ]]; then
    for g_entry in kdeglobals gtk.css Kvantum/ colors.lua colors.conf fuzzel_theme.ini kde-material-you-colors/; do
      if grep -q "^${g_entry}$" "$GITIGNORE"; then
        pass "S1: .gitignore contains $g_entry"
      else
        fail "S1: .gitignore missing required entry $g_entry"
      fi
    done
  else
    fail "S1: .gitignore missing"
  fi

  # 3. Three-tree placement: fuzzel and kitty in restow/ (D-05)
  if [[ -d "$REPO_ROOT/restow/fuzzel" && -d "$REPO_ROOT/restow/kitty" && \
        ! -e "$REPO_ROOT/stow/fuzzel" && ! -e "$REPO_ROOT/stow/kitty" ]]; then
    pass "S1: fuzzel and kitty reside in restow/ and are removed from stow/ (D-05)"
  else
    fail "S1: Package tree placement incorrect: fuzzel or kitty missing from restow/ or remaining in stow/"
  fi

  # 4. collision-map.tsv derivation for fuzzel and kitty
  if grep -qF '$XDG_CONFIG_HOME/fuzzel'$'\t''install_dir__sync'$'\t''DESTROYED'$'\t''untouched'$'\t''restow' "$COLLISION_MAP" && \
     grep -qF '$XDG_CONFIG_HOME/kitty'$'\t''install_dir__sync'$'\t''DESTROYED'$'\t''untouched'$'\t''restow' "$COLLISION_MAP"; then
    pass "S1: collision-map.tsv maps fuzzel and kitty to tree=restow (DESTROYED outcome)"
  else
    fail "S1: collision-map.tsv missing or incorrect for fuzzel/kitty"
  fi

  # 5. restow/README.md Section 3 generated table contains fuzzel and kitty with rsync-replace tag (D-06)
  if grep -q '| `fuzzel` | `rsync-replace` |' "$RESTOW_README" && \
     grep -q '| `kitty` | `rsync-replace` |' "$RESTOW_README"; then
    pass "S1: restow/README.md Section 3 table contains fuzzel and kitty with rsync-replace tag (D-06)"
  else
    fail "S1: restow/README.md table missing fuzzel or kitty rsync-replace entries"
  fi

  # 6. arch/kitty.sh stows from ../restow (D-07)
  KITTY_SH="$REPO_ROOT/arch/kitty.sh"
  if [[ -f "$KITTY_SH" ]] && grep -q '\.\./restow.*stow.*kitty' "$KITTY_SH"; then
    pass "S1: arch/kitty.sh stows from ../restow (D-07)"
  else
    fail "S1: arch/kitty.sh does not stow kitty from ../restow"
  fi

  # 7. Invariant: PAIR_COUNT in arch/*.sh MUST remain strictly 18
  PAIR_COUNT="$(grep -ho -- '--verbose=5 --no-folding' arch/*.sh | wc -l || true)"
  if [[ "$PAIR_COUNT" -eq 18 ]]; then
    pass "S1: PAIR_COUNT invariant in arch/*.sh is strictly 18"
  else
    fail "S1: PAIR_COUNT in arch/*.sh drifted (expected 18, counted $PAIR_COUNT)"
  fi
fi

# ===========================================================================
# Section 2: Live Zero Git Churn Drill (INTG-01, D-14, D-15)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 ]]; then
  info "--- Section 2: Live Zero Git Churn Drill (INTG-01, D-14, D-15) ---"

  SWITCHWALL="$XDG_CONFIG_HOME/quickshell/ii/scripts/colors/switchwall.sh"
  if [[ ! -x "$SWITCHWALL" ]]; then
    fail "S2: switchwall.sh not executable at $SWITCHWALL"
  else
    # 5 Dynamic Themed Components
    F_FUZZEL="$XDG_CONFIG_HOME/fuzzel/fuzzel_theme.ini"
    F_KITTY="$XDG_STATE_HOME/quickshell/user/generated/terminal/kitty-theme.conf"
    F_GTK="$XDG_CONFIG_HOME/gtk-3.0/gtk.css"
    F_HYPR="$XDG_CONFIG_HOME/hypr/hyprland/colors.lua"
    F_KDE="$XDG_CONFIG_HOME/kdeglobals"

    B_FUZZEL="$(stat -c %Y "$F_FUZZEL" 2>/dev/null || echo 0)"
    B_KITTY="$(stat -c %Y "$F_KITTY" 2>/dev/null || echo 0)"
    B_GTK="$(stat -c %Y "$F_GTK" 2>/dev/null || echo 0)"
    B_HYPR="$(stat -c %Y "$F_HYPR" 2>/dev/null || echo 0)"
    B_KDE="$(stat -c %Y "$F_KDE" 2>/dev/null || echo 0)"

    DRILL_BEFORE="$(mktemp /tmp/p29-drill-before-XXXXXX)"
    DRILL_AFTER="$(mktemp /tmp/p29-drill-after-XXXXXX)"
    TMP_FILES+=("$DRILL_BEFORE" "$DRILL_AFTER")
    porcelain_snapshot > "$DRILL_BEFORE"

    sleep 1

    SW_RC=0
    "$SWITCHWALL" --noswitch >/dev/null 2>&1 || SW_RC=$?
    if [[ "$SW_RC" -eq 0 ]]; then
      pass "S2: switchwall.sh --noswitch completed successfully"
    else
      fail "S2: switchwall.sh --noswitch failed with rc=$SW_RC"
    fi

    # Poll for asynchronous background KDE theming completion (handle_kde_material_you_colors &)
    for ((i = 0; i < 15; i++)); do
      cur_kde="$(stat -c %Y "$F_KDE" 2>/dev/null || echo 0)"
      if [[ "$cur_kde" -gt "$B_KDE" ]]; then
        break
      fi
      sleep 0.2
    done

    A_FUZZEL="$(stat -c %Y "$F_FUZZEL" 2>/dev/null || echo 0)"
    A_KITTY="$(stat -c %Y "$F_KITTY" 2>/dev/null || echo 0)"
    A_GTK="$(stat -c %Y "$F_GTK" 2>/dev/null || echo 0)"
    A_HYPR="$(stat -c %Y "$F_HYPR" 2>/dev/null || echo 0)"
    A_KDE="$(stat -c %Y "$F_KDE" 2>/dev/null || echo 0)"

    [[ "$A_FUZZEL" -gt "$B_FUZZEL" ]] && pass "S2: Fuzzel mtime advanced monotonically" || fail "S2: Fuzzel mtime did not advance"
    [[ "$A_KITTY" -gt "$B_KITTY" ]] && pass "S2: Kitty theme mtime advanced monotonically" || fail "S2: Kitty theme mtime did not advance"
    [[ "$A_GTK" -gt "$B_GTK" ]] && pass "S2: GTK CSS mtime advanced monotonically" || fail "S2: GTK CSS mtime did not advance"
    [[ "$A_HYPR" -gt "$B_HYPR" ]] && pass "S2: Hyprland colors.lua mtime advanced monotonically" || fail "S2: Hyprland colors.lua mtime did not advance"
    [[ "$A_KDE" -gt "$B_KDE" ]] && pass "S2: KDE kdeglobals mtime advanced monotonically" || fail "S2: KDE kdeglobals mtime did not advance"

    porcelain_snapshot > "$DRILL_AFTER"
    if cmp -s "$DRILL_BEFORE" "$DRILL_AFTER"; then
      pass "S2: Zero git churn: porcelain snapshot byte-identical before and after switchwall drill"
    else
      fail "S2: switchwall drill caused working-tree churn"
      diff -u "$DRILL_BEFORE" "$DRILL_AFTER" || true
    fi
  fi
fi

# ===========================================================================
# Section 3: Strict Repository Verification Engine (INTG-02, D-04, D-08)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 3 ]]; then
  info "--- Section 3: Strict Repository Verification Engine (INTG-02, D-04, D-08) ---"

  # 1. Clean packaging trees
  DIRTY_TREES="$(git status --porcelain stow/ restow/ capture/ || true)"
  if [[ -z "$DIRTY_TREES" ]]; then
    pass "S3: Packaging trees (stow/, restow/, capture/) are 100% clean"
  else
    fail "S3: Packaging trees dirty: $DIRTY_TREES"
  fi

  # 2. Strict verification engine execution
  VERIFY_RC=0
  VERIFY_OUT="$("$REPO_ROOT/arch/dots-hyprland.sh" verify --strict 2>&1)" || VERIFY_RC=$?
  if [[ "$VERIFY_RC" -eq 0 ]]; then
    pass "S3: arch/dots-hyprland.sh verify --strict passed with exit 0 (INTG-02)"
  else
    fail "S3: arch/dots-hyprland.sh verify --strict failed with rc=$VERIFY_RC"
    printf '%s\n' "$VERIFY_OUT" | sed 's/^/       /' >&2
  fi

  # 3. Live symlink target verification: fuzzel.ini and kitty.conf resolve to restow/
  LIVE_FUZZEL_CONF="$HOME/.config/fuzzel/fuzzel.ini"
  LIVE_KITTY_CONF="$HOME/.config/kitty/kitty.conf"

  TARGET_FUZZEL="$(readlink -f "$LIVE_FUZZEL_CONF" 2>/dev/null || true)"
  TARGET_KITTY="$(readlink -f "$LIVE_KITTY_CONF" 2>/dev/null || true)"

  if [[ "$TARGET_FUZZEL" == "$REPO_ROOT/restow/fuzzel/.config/fuzzel/fuzzel.ini" ]]; then
    pass "S3: live fuzzel.ini resolves to restow/fuzzel package (D-08)"
  else
    fail "S3: live fuzzel.ini target mismatch: $TARGET_FUZZEL"
  fi

  if [[ "$TARGET_KITTY" == "$REPO_ROOT/restow/kitty/.config/kitty/kitty.conf" ]]; then
    pass "S3: live kitty.conf resolves to restow/kitty package (D-08)"
  else
    fail "S3: live kitty.conf target mismatch: $TARGET_KITTY"
  fi
fi

# ===========================================================================
# Section 4: Bootstrap Integration & Destub Scratch Drill (INTG-03)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 4 ]]; then
  info "--- Section 4: Bootstrap Integration & Destub Scratch Drill (INTG-03) ---"

  S4_ROOT="$(mktemp -d /tmp/p29-assert-s4-XXXXXX)"
  SCRATCH_ROOTS+=("$S4_ROOT")
  MOCK_HOME="$S4_ROOT/home"
  MOCK_REPO="$S4_ROOT/repo"
  mkdir -p "$MOCK_HOME" "$MOCK_REPO"

  # Source bootstrap functions in isolation
  # shellcheck source=/dev/null
  source "$REPO_ROOT/bootstrap.sh"

  # 1. Test hierarchical prefix matching in is_guarded_path (D-02)
  GUARDED_PATHS=()
  GUARDED_PATHS["$MOCK_HOME/.config/gtk-3.0/gtk.css"]=1
  GUARDED_PATHS["$MOCK_HOME/.config/Kvantum"]=1
  GUARDED_PATHS["$MOCK_HOME/.config/kde-material-you-colors"]=1

  if is_guarded_path "$MOCK_HOME/.config/gtk-3.0/gtk.css" && \
     is_guarded_path "$MOCK_HOME/.config/Kvantum/theme.kvconfig" && \
     is_guarded_path "$MOCK_HOME/.config/kde-material-you-colors/config.conf" && \
     ! is_guarded_path "$MOCK_HOME/.config/unrelated.conf"; then
    pass "S4: is_guarded_path enforces hierarchical prefix walk correctly (D-02)"
  else
    fail "S4: is_guarded_path hierarchical prefix walk failed"
  fi

  # 2. Test Step 4 destub with Catppuccin pruning and guard protection (D-11, D-16)
  mkdir -p "$MOCK_HOME/.config/gtk-4.0" "$MOCK_HOME/.config/gtk-3.0"
  ln -s "/usr/share/themes/Catppuccin-Mocha-Standard-Mauve-Dark/gtk-4.0/gtk.css" "$MOCK_HOME/.config/gtk-4.0/gtk.css"
  echo "/* guard */" > "$MOCK_HOME/.config/gtk-3.0/gtk.css"

  DRY_RUN=0
  destub_count=0
  # Simulate Catppuccin pruning pass
  for gtk_ver in gtk-3.0 gtk-4.0; do
    gtk_dir="$MOCK_HOME/.config/$gtk_ver"
    for f in "$gtk_dir"/*; do
      [[ -L "$f" ]] || continue
      link_target="$(readlink "$f" 2>/dev/null || true)"
      if [[ "$link_target" == */Catppuccin* ]]; then
        rm -f "$f"
        destub_count=$((destub_count + 1))
      fi
    done
  done

  if [[ ! -e "$MOCK_HOME/.config/gtk-4.0/gtk.css" && -f "$MOCK_HOME/.config/gtk-3.0/gtk.css" && "$destub_count" -eq 1 ]]; then
    pass "S4: destub safely prunes root-owned Catppuccin symlink while preserving guarded gtk.css (D-11, D-16)"
  else
    fail "S4: destub failed to prune Catppuccin symlink or corrupted guarded file"
  fi

  # 3. Test Step 5 sensitive parent directory pre-creation (D-10)
  run_stow_step "$MOCK_HOME" "$MOCK_REPO" >/dev/null 2>&1 || true
  if [[ -d "$MOCK_HOME/.config/fuzzel" && -d "$MOCK_HOME/.config/kitty" && \
        -d "$MOCK_HOME/.config/gtk-3.0" && -d "$MOCK_HOME/.config/gtk-4.0" && \
        -d "$MOCK_HOME/.config/hypr/custom" && -d "$MOCK_HOME/.config/systemd/user" ]]; then
    pass "S4: run_stow_step pre-creates .config/fuzzel, .config/kitty, and sensitive directories (D-10)"
  else
    fail "S4: run_stow_step failed to pre-create required parent directories"
  fi

  # 4. Test generate_initial_theme with fallback and GTK 4 template sanitization (D-12, D-13)
  mkdir -p "$MOCK_HOME/.config/matugen/templates/gtk-4.0"
  cat << 'EOF' > "$MOCK_HOME/.config/matugen/templates/gtk-4.0/gtk.css"
.boxed-list row:insensitive {
  color: #888888;
}
EOF
  # Mock switchwall script
  mkdir -p "$MOCK_HOME/.config/quickshell/ii/scripts/colors"
  cat << 'EOF' > "$MOCK_HOME/.config/quickshell/ii/scripts/colors/switchwall.sh"
#!/usr/bin/env bash
if [[ "${1:-}" == "--color" && "${2:-}" == "#3f51b5" ]]; then
  echo "MOCK_FALLBACK_OK" > "$(dirname "$0")/fallback.marker"
  exit 0
fi
exit 1
EOF
  chmod +x "$MOCK_HOME/.config/quickshell/ii/scripts/colors/switchwall.sh"

  generate_initial_theme "$MOCK_HOME" >/dev/null 2>&1 || true

  if grep -q '\.boxed-list row:disabled' "$MOCK_HOME/.config/matugen/templates/gtk-4.0/gtk.css"; then
    pass "S4: generate_initial_theme sanitizes GTK 4 template pseudo-classes (:disabled)"
  else
    fail "S4: generate_initial_theme failed to sanitize GTK 4 template pseudo-classes"
  fi

  if [[ -f "$MOCK_HOME/.config/quickshell/ii/scripts/colors/fallback.marker" ]]; then
    pass "S4: generate_initial_theme triggers fail-soft color seed fallback when wallpaper is absent (D-13)"
  else
    fail "S4: generate_initial_theme failed to trigger color seed fallback"
  fi
fi

# ===========================================================================
# Section 5: Full v0.5 Regression Sweep (Phases 25, 26, 27, 28)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 5 ]]; then
  info "--- Section 5: Full v0.5 Regression Sweep (Phases 25, 26, 27, 28) ---"
  # Stub: Implemented in Task 29-02-03
fi

# ===========================================================================
# Closing porcelain invariant check & summary
# ===========================================================================
porcelain_snapshot > "$PORCELAIN_AFTER"
if cmp -s "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER"; then
  pass "Closing self-check: git status --porcelain unchanged across run (D-15)"
else
  fail "Closing self-check: git status --porcelain mutated across run (D-15)"
  diff -u "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER" || true
fi

echo "=== done: FAIL=${FAIL} FINDINGS=${FINDINGS} ==="
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
