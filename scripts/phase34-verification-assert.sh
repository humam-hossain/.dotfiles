#!/usr/bin/env bash
# ===========================================================================
# Phase 34: Verification, Zero Drift & Bootstrap Integration Assert Harness
# Enforces: INTG-01, INTG-02, INTG-03, D-01 through D-16
#
# Usage (from REPO_ROOT):
#   ./scripts/phase34-verification-assert.sh [--section <1-5>] [-s <1-5>]
#
# Exit 0 if all hard asserts pass (FAIL=0); exit 1 if any hard FAIL.
# ===========================================================================

set -euo pipefail

# Fail closed if run as root
[[ "${EUID:-$(id -u)}" -ne 0 ]] || { echo "Error: Do not run as root" >&2; exit 1; }

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# Resilient Hyprland socket detection across compositor relogins
if command -v hyprctl &>/dev/null; then
  if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] || ! hyprctl -j status &>/dev/null; then
    candidate_sig="$(ls -td "/run/user/$(id -u)/hypr/"* 2>/dev/null | head -1 | xargs -r basename || true)"
    if [[ -n "$candidate_sig" ]]; then
      export HYPRLAND_INSTANCE_SIGNATURE="$candidate_sig"
    fi
  fi
fi

FAIL=0
FINDINGS=0

pass() { printf '[PASS] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
finding() { printf '[FINDING] %s\n' "$1"; FINDINGS=$((FINDINGS + 1)); }
info() { printf '[INFO] %s\n' "$1"; }

TMP_FILES=()
SCRATCH_ROOTS=()
SAVED_SHELL_CONFIG_RESTORE=""
SHELL_CONFIG_PATH="$XDG_CONFIG_HOME/illogical-impulse/config.json"

cleanup() {
  # Restore shell config if preserved during drill and still exists
  if [[ -n "$SAVED_SHELL_CONFIG_RESTORE" && -f "$SAVED_SHELL_CONFIG_RESTORE" ]]; then
    if [[ -f "$SHELL_CONFIG_PATH" ]]; then
      cp -p "$SAVED_SHELL_CONFIG_RESTORE" "$SHELL_CONFIG_PATH" 2>/dev/null || true
    fi
  fi

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
    --section|-s)
      if [[ -z "${2:-}" ]] || ! [[ "$2" =~ ^[1-5]$ ]]; then
        echo "Error: --section requires an integer from 1 to 5" >&2
        exit 1
      fi
      RUN_SECTION="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 [--section <1-5>]"
      echo "  -s, --section <1-5>  Execute only the specified section"
      echo "  -h, --help           Show this help message"
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

PORCELAIN_BEFORE="$(mktemp /tmp/p34-porcelain-before-XXXXXX)"
PORCELAIN_AFTER="$(mktemp /tmp/p34-porcelain-after-XXXXXX)"
TMP_FILES+=("$PORCELAIN_BEFORE" "$PORCELAIN_AFTER")

porcelain_snapshot > "$PORCELAIN_BEFORE"

# ===========================================================================
# Section 1: Data Contracts, 11/11 Symlinks & Pre-Creation Checks
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 1 ]]; then
  info "--- Section 1: Data Contracts, 11/11 Symlinks & Pre-Creation (INTG-01, INTG-02, INTG-03) ---"

  # 1. 11/11 Overlay Symlinks
  EXPECTED_OVERLAYS=(
    ".config/quickshell/ii/services/Updates.qml"
    ".config/quickshell/ii/services/Privacy.qml"
    ".config/quickshell/ii/scripts/videos/record.sh"
    ".config/quickshell/ii/scripts/system-update.sh"
    ".config/quickshell/ii/modules/ii/bar/BarContent.qml"
    ".config/quickshell/ii/modules/ii/bar/SysTray.qml"
    ".config/quickshell/ii/modules/ii/bar/UpdatesButton.qml"
    ".config/quickshell/ii/modules/ii/bar/BarGroup.qml"
    ".config/quickshell/ii/modules/ii/bar/Resources.qml"
    ".config/quickshell/ii/modules/ii/bar/Resource.qml"
    ".config/quickshell/ii/modules/ii/bar/ClockWidget.qml"
  )

  for rel in "${EXPECTED_OVERLAYS[@]}"; do
    live="$HOME/$rel"
    repo="$REPO_ROOT/restow/quickshell/$rel"
    if [[ -L "$live" && "$(readlink -f "$live")" == "$(readlink -f "$repo")" ]]; then
      pass "S1: Live overlay $rel resolves 1:1 to restow/quickshell (D-11)"
    else
      fail "S1: Live overlay $rel target mismatch or not a symlink"
    fi
  done

  # 2. Sensitive Directory Pre-Creation in bootstrap.sh (D-05)
  for req_dir in ".config/quickshell/ii/modules/ii/bar" \
                 ".config/quickshell/ii/services" \
                 ".config/quickshell/ii/scripts/videos"; do
    if grep -qF "$req_dir" "$REPO_ROOT/bootstrap.sh"; then
      pass "S1: bootstrap.sh pre-creates target directory $req_dir (D-05)"
    else
      fail "S1: bootstrap.sh missing pre-creation of $req_dir"
    fi
  done

  # 3. Dynamic colors.json Token Contract (D-03)
  COLORS_JSON="$XDG_STATE_HOME/quickshell/user/generated/colors.json"
  if [[ -s "$COLORS_JSON" ]] && jq empty "$COLORS_JSON" 2>/dev/null; then
    for token in background surface_container_low on_surface_variant secondary_container primary error; do
      if jq -e --arg t "$token" 'has($t)' "$COLORS_JSON" >/dev/null 2>&1; then
        pass "S1: colors.json defines core token: $token (D-03)"
      else
        fail "S1: colors.json missing core token: $token"
      fi
    done
  else
    fail "S1: colors.json missing or invalid JSON"
  fi

  # 4. Zero Unauthorized Hardcoded Hex Codes in restow/quickshell (D-03)
  UNAUTH_HEX="$(grep -rnE '#[0-9a-fA-F]{3,8}' "$REPO_ROOT/restow/quickshell" | grep -v '#FFA000' || true)"
  if [[ -z "$UNAUTH_HEX" ]]; then
    pass "S1: Zero unauthorized hardcoded hex codes in restow/quickshell (D-03)"
  else
    fail "S1: Found unauthorized hardcoded hex codes in restow/quickshell: $UNAUTH_HEX"
  fi
fi

# ===========================================================================
# Section 2: Material You Dynamic Theming Drill & Zero Git Churn
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 ]]; then
  info "--- Section 2: Material You Theming Drill & Zero Git Churn (INTG-01, D-01, D-04, D-12) ---"

  SWITCHWALL="$XDG_CONFIG_HOME/quickshell/ii/scripts/colors/switchwall.sh"
  COLORS_JSON="$XDG_STATE_HOME/quickshell/user/generated/colors.json"
  SHELL_CONFIG="$XDG_CONFIG_HOME/illogical-impulse/config.json"

  if [[ ! -x "$SWITCHWALL" ]]; then
    fail "S2: switchwall.sh not executable at $SWITCHWALL"
  else
    # Preserve live shell config to prevent switchwall --color JSON reformats from causing capture drift
    SAVED_SHELL_CONFIG="$(mktemp /tmp/p34-saved-config-XXXXXX)"
    TMP_FILES+=("$SAVED_SHELL_CONFIG")
    SAVED_SHELL_CONFIG_RESTORE="$SAVED_SHELL_CONFIG"
    if [[ -f "$SHELL_CONFIG" ]]; then
      cp -p "$SHELL_CONFIG" "$SAVED_SHELL_CONFIG"
    fi

    DRILL_BEFORE="$(mktemp /tmp/p34-drill-before-XXXXXX)"
    DRILL_AFTER="$(mktemp /tmp/p34-drill-after-XXXXXX)"
    TMP_FILES+=("$DRILL_BEFORE" "$DRILL_AFTER")
    porcelain_snapshot > "$DRILL_BEFORE"

    B_MTIME="$(stat -c %Y "$COLORS_JSON" 2>/dev/null || echo 0)"
    sleep 1

    # Drill A: Native switchwall.sh --noswitch
    SW_RC=0
    "$SWITCHWALL" --noswitch </dev/null >/dev/null 2>&1 || SW_RC=$?
    if [[ "$SW_RC" -eq 0 ]]; then
      pass "S2: switchwall.sh --noswitch completed successfully (D-01)"
    else
      fail "S2: switchwall.sh --noswitch failed with rc=$SW_RC"
    fi

    A_MTIME="$(stat -c %Y "$COLORS_JSON" 2>/dev/null || echo 0)"
    if [[ "$A_MTIME" -gt "$B_MTIME" ]]; then
      pass "S2: colors.json mtime advanced monotonically on native drill (D-04)"
    else
      fail "S2: colors.json mtime did not advance on native drill"
    fi

    if pgrep -x qs >/dev/null 2>&1 || pgrep -x quickshell >/dev/null 2>&1; then
      pass "S2: quickshell process remained alive during native theming (D-04)"
    else
      fail "S2: quickshell process died during native theming"
    fi

    sleep 1

    # Drill B: Fallback synthetic color seed switchwall.sh --color "#3f51b5"
    SEED_RC=0
    "$SWITCHWALL" --color "#3f51b5" </dev/null >/dev/null 2>&1 || SEED_RC=$?
    sleep 0.5
    if [[ "$SEED_RC" -eq 0 ]]; then
      pass "S2: switchwall.sh --color '#3f51b5' seed fallback completed successfully (D-01)"
    else
      fail "S2: switchwall.sh --color '#3f51b5' failed with rc=$SEED_RC"
    fi

    C_MTIME="$(stat -c %Y "$COLORS_JSON" 2>/dev/null || echo 0)"
    if [[ "$C_MTIME" -gt "$A_MTIME" ]]; then
      pass "S2: colors.json mtime advanced monotonically on color seed drill (D-04)"
    else
      fail "S2: colors.json mtime did not advance on color seed drill"
    fi

    if jq empty "$COLORS_JSON" 2>/dev/null; then
      pass "S2: colors.json generated valid JSON on color seed drill"
    else
      fail "S2: colors.json generated invalid JSON on color seed drill"
    fi

    # Restoration: Restore shell config and re-run native switchwall
    if [[ -f "$SAVED_SHELL_CONFIG" ]]; then
      cp -p "$SAVED_SHELL_CONFIG" "$SHELL_CONFIG"
    fi
    "$SWITCHWALL" --noswitch </dev/null >/dev/null 2>&1 || true
    sleep 0.5

    if pgrep -x qs >/dev/null 2>&1 || pgrep -x quickshell >/dev/null 2>&1; then
      pass "S2: quickshell process remains alive after palette restoration (D-04)"
    else
      fail "S2: quickshell process died after palette restoration"
    fi

    porcelain_snapshot > "$DRILL_AFTER"
    if cmp -s "$DRILL_BEFORE" "$DRILL_AFTER"; then
      pass "S2: Zero git churn: porcelain snapshot byte-identical before and after drill (D-12)"
    else
      fail "S2: switchwall drill caused working-tree churn"
      diff -u "$DRILL_BEFORE" "$DRILL_AFTER" || true
    fi
  fi
fi

# ===========================================================================
# Section 3: Repository Strict Verification Gate
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 3 ]]; then
  info "--- Section 3: Repository Strict Verification Gate (INTG-02, D-09, D-10) ---"

  # 1. Clean packaging trees
  DIRTY_TREES="$(git status --porcelain stow/ restow/ capture/ || true)"
  if [[ -z "$DIRTY_TREES" ]]; then
    pass "S3: Packaging trees (stow/, restow/, capture/) are 100% clean"
  else
    fail "S3: Packaging trees dirty: $DIRTY_TREES"
  fi

  # 2. Strict verification execution
  VERIFY_RC=0
  VERIFY_OUT="$("$REPO_ROOT/arch/dots-hyprland.sh" verify --strict 2>&1)" || VERIFY_RC=$?
  if [[ "$VERIFY_RC" -eq 0 ]] && printf '%s\n' "$VERIFY_OUT" | grep -q 'FINDINGS=0'; then
    pass "S3: arch/dots-hyprland.sh verify --strict passed with exit 0 and FINDINGS=0 (INTG-02)"
  else
    fail "S3: arch/dots-hyprland.sh verify --strict failed (exit code $VERIFY_RC)"
    printf '%s\n' "$VERIFY_OUT" | tail -n 25 | sed 's/^/       /' >&2
  fi
fi

# ===========================================================================
# Section 4: Isolated Bootstrap Destub & Stow Scratch Drill
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 4 ]]; then
  info "--- Section 4: Isolated Bootstrap Destub & Stow Scratch Drill (INTG-03, D-05, D-06, D-07, D-08) ---"

  S4_ROOT="$(mktemp -d /tmp/p34-assert-s4-XXXXXX)"
  SCRATCH_ROOTS+=("$S4_ROOT")
  MOCK_HOME="$S4_ROOT/home"
  MOCK_REPO="$S4_ROOT/repo"
  mkdir -p "$MOCK_HOME" "$MOCK_REPO"

  # Populate mock repo mirroring stow and restow/quickshell
  mkdir -p "$MOCK_REPO/restow/quickshell/.config/quickshell/ii/modules/ii/bar"
  mkdir -p "$MOCK_REPO/restow/quickshell/.config/quickshell/ii/services"
  mkdir -p "$MOCK_REPO/restow/quickshell/.config/quickshell/ii/scripts/videos"
  touch "$MOCK_REPO/restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml"
  touch "$MOCK_REPO/restow/quickshell/.config/quickshell/ii/services/Updates.qml"
  touch "$MOCK_REPO/restow/quickshell/.config/quickshell/ii/scripts/videos/record.sh"

  # Populate mock home with upstream regular file stubs
  mkdir -p "$MOCK_HOME/.config/quickshell/ii/modules/ii/bar"
  mkdir -p "$MOCK_HOME/.config/quickshell/ii/services"
  mkdir -p "$MOCK_HOME/.config/quickshell/ii/scripts/videos"
  echo "UPSTREAM_BAR_CONTENT" > "$MOCK_HOME/.config/quickshell/ii/modules/ii/bar/BarContent.qml"
  echo "UPSTREAM_UPDATES" > "$MOCK_HOME/.config/quickshell/ii/services/Updates.qml"
  echo "UPSTREAM_RECORD" > "$MOCK_HOME/.config/quickshell/ii/scripts/videos/record.sh"

  # Source bootstrap functions in isolation
  # shellcheck source=/dev/null
  source "$REPO_ROOT/bootstrap.sh"

  # 1. Test run_destub discovered and unlinked stubs (D-06, D-07)
  DRY_RUN=0
  destub_output="$(run_destub "$MOCK_HOME" "$MOCK_REPO" 2>&1 || true)"

  if [[ ! -e "$MOCK_HOME/.config/quickshell/ii/modules/ii/bar/BarContent.qml" && \
        ! -e "$MOCK_HOME/.config/quickshell/ii/services/Updates.qml" && \
        ! -e "$MOCK_HOME/.config/quickshell/ii/scripts/videos/record.sh" ]]; then
    pass "S4: run_destub unlinked upstream Quickshell stubs cleanly (D-06)"
  else
    fail "S4: run_destub failed to unlink stubs"
  fi

  # Verify backup directory and SHA-256 manifests
  backup_dir="$(find "$MOCK_HOME" -maxdepth 1 -type d -name ".dotfiles-backup.*" | head -1)"
  if [[ -n "$backup_dir" && ( -f "$backup_dir/MANIFEST.txt" || -f "$backup_dir/manifest.sha256" ) ]]; then
    pass "S4: run_destub created backup archive with SHA-256 manifest (D-06)"
  else
    fail "S4: run_destub backup archive or manifest missing"
  fi

  # 2. Test run_stow_step pre-creation and leaf symlinking (D-05)
  run_stow_step "$MOCK_HOME" "$MOCK_REPO" >/dev/null 2>&1 || true
  if [[ -d "$MOCK_HOME/.config/quickshell/ii/modules/ii/bar" && \
        ! -L "$MOCK_HOME/.config/quickshell/ii/modules/ii/bar" && \
        -L "$MOCK_HOME/.config/quickshell/ii/modules/ii/bar/BarContent.qml" ]]; then
    pass "S4: run_stow_step creates leaf symlinks without folding bar directory (D-05)"
  else
    fail "S4: run_stow_step failed to pre-create or folded bar directory"
  fi

  # 3. Test generate_initial_theme color priming assertion (D-08)
  mkdir -p "$MOCK_HOME/.config/quickshell/ii/scripts/colors"
  cat << 'EOF' > "$MOCK_HOME/.config/quickshell/ii/scripts/colors/switchwall.sh"
#!/usr/bin/env bash
mkdir -p "$HOME/.local/state/quickshell/user/generated"
echo '{"background":"#1a1a1a"}' > "$HOME/.local/state/quickshell/user/generated/colors.json"
exit 0
EOF
  chmod +x "$MOCK_HOME/.config/quickshell/ii/scripts/colors/switchwall.sh"

  HOME="$MOCK_HOME" XDG_STATE_HOME="$MOCK_HOME/.local/state" \
    generate_initial_theme "$MOCK_HOME" >/dev/null 2>&1 || true

  if [[ -s "$MOCK_HOME/.local/state/quickshell/user/generated/colors.json" ]]; then
    pass "S4: generate_initial_theme asserts primed colors.json successfully (D-08)"
  else
    fail "S4: generate_initial_theme did not verify primed colors.json"
  fi
fi

# ===========================================================================
# Section 5: Full Milestone v0.6 Regression Sweep
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 5 ]]; then
  info "--- Section 5: Full v0.6 Milestone Regression Sweep (Phases 31, 32, 33) ---"

  for p_script in "scripts/phase31-overlay-pill-assert.sh" \
                  "scripts/phase32-component-formatting-assert.sh" \
                  "scripts/phase33-layout-assert.sh"; do
    if [[ -x "$REPO_ROOT/$p_script" ]]; then
      p_rc=0
      p_out="$("$REPO_ROOT/$p_script" 2>&1)" || p_rc=$?
      if [[ "$p_rc" -eq 0 ]]; then
        pass "S5: $p_script passed with 0 failures (D-14)"
      else
        fail "S5: $p_script failed with exit code $p_rc"
        printf '%s\n' "$p_out" | tail -n 20 | sed 's/^/       /' >&2
      fi
    else
      fail "S5: $p_script missing or not executable"
    fi
  done
fi

# Closing porcelain check & summary
porcelain_snapshot > "$PORCELAIN_AFTER"
if cmp -s "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER"; then
  pass "Closing self-check: git status --porcelain unchanged across run (D-12, D-16)"
else
  fail "Closing self-check: git status --porcelain mutated across run"
  diff -u "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER" || true
fi

echo "=== done: FAIL=${FAIL} FINDINGS=${FINDINGS} ==="
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
