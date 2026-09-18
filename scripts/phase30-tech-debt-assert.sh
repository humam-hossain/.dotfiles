#!/usr/bin/env bash
# Phase 30: Address tech debt: v0.5 cleanup and validation sign-off assert harness
# Enforces: DEBT-05, DEBT-06, DEBT-07, DEBT-08, and D-01 through D-14
#
# Usage (from REPO_ROOT):
#   ./scripts/phase30-tech-debt-assert.sh [--section <1-5>]
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

PORCELAIN_BEFORE="$(mktemp /tmp/p30-porcelain-before-XXXXXX)"
PORCELAIN_AFTER="$(mktemp /tmp/p30-porcelain-after-XXXXXX)"
TMP_FILES+=("$PORCELAIN_BEFORE" "$PORCELAIN_AFTER")

porcelain_snapshot > "$PORCELAIN_BEFORE"

# ===========================================================================
# Section 1: Kitty Visual Polish & Probe Alignment (DEBT-05, D-01..D-04)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 1 ]]; then
  info "--- Section 1: Kitty Visual Polish & Probe Alignment (DEBT-05) ---"

  # 1. Check restow/kitty/.config/kitty/kitty.conf for background_opacity 0.90
  KITTY_CONF="$REPO_ROOT/restow/kitty/.config/kitty/kitty.conf"
  if [[ -f "$KITTY_CONF" ]] && grep -q '^background_opacity 0.90' "$KITTY_CONF"; then
    pass "S1: restow/kitty/.config/kitty/kitty.conf specifies background_opacity 0.90 (D-01, DEBT-05)"
  else
    fail "S1: restow/kitty/.config/kitty/kitty.conf missing background_opacity 0.90"
  fi

  # 2. Native Kitty parser probe for opacity 0.90 via kitty +runpy
  KITTY_OPTS_VERDICT="$(kitty +runpy "import sys
from kitty.config import load_config
try:
    opts = load_config('$HOME/.config/kitty/kitty.conf')
    if abs(opts.background_opacity - 0.90) > 0.01:
        print(f'FAIL: background_opacity expected 0.90, got {opts.background_opacity}')
        sys.exit(1)
    if opts.shell != 'zsh':
        print(f'FAIL: shell expected zsh, got {opts.shell}')
        sys.exit(1)
    if opts.window_margin_width[0] != 21.75:
        print(f'FAIL: window_margin_width expected 21.75, got {opts.window_margin_width}')
        sys.exit(1)
    print('PASS: Kitty config loaded: opacity=0.90, shell=zsh, margin=21.75')
except Exception as e:
    print(f'FAIL: {e}')
    sys.exit(1)
" 2>&1 || true)"

  if [[ "$KITTY_OPTS_VERDICT" =~ ^PASS ]]; then
    pass "S1: Native Kitty config probe verified opacity 0.90, shell=zsh, margin=21.75 (D-01, D-02)"
  else
    fail "S1: Native Kitty config probe failed: $KITTY_OPTS_VERDICT"
  fi

  # 3. scripts/phase28-terminal-fuzzel-assert.sh contains 0.90 opacity probe and comments
  P28_ASSERT="$REPO_ROOT/scripts/phase28-terminal-fuzzel-assert.sh"
  if [[ -f "$P28_ASSERT" ]] && grep -q 'abs(opts.background_opacity - 0.90) > 0.01' "$P28_ASSERT" && grep -q 'opacity=0.90' "$P28_ASSERT"; then
    pass "S1: scripts/phase28-terminal-fuzzel-assert.sh aligned to 0.90 opacity with traceability (D-02)"
  else
    fail "S1: scripts/phase28-terminal-fuzzel-assert.sh not aligned to 0.90 opacity probe"
  fi

  # 4. Execute scripts/phase28-terminal-fuzzel-assert.sh --section 3
  if [[ -x "$P28_ASSERT" ]]; then
    p28_s3_rc=0
    p28_s3_out="$("$P28_ASSERT" --section 3 2>&1)" || p28_s3_rc=$?
    if [[ "$p28_s3_rc" -eq 0 ]]; then
      pass "S1: scripts/phase28-terminal-fuzzel-assert.sh --section 3 passed with 0 failures (D-02)"
    else
      fail "S1: scripts/phase28-terminal-fuzzel-assert.sh --section 3 failed with exit code $p28_s3_rc"
      printf '%s\n' "$p28_s3_out" | tail -n 10 | sed 's/^/       /' >&2
    fi
  else
    fail "S1: scripts/phase28-terminal-fuzzel-assert.sh missing or not executable"
  fi
fi

# ===========================================================================
# Section 2: Environment Fallback & Signaling Robustness (DEBT-06, D-05..D-07)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 ]]; then
  info "--- Section 2: Environment Fallback & Signaling Robustness (DEBT-06) ---"

  # 1. bootstrap.sh contains virtualenv export and alignment hooks
  BOOTSTRAP="$REPO_ROOT/bootstrap.sh"
  if grep -q 'export ILLOGICAL_IMPULSE_VIRTUAL_ENV="\${ILLOGICAL_IMPULSE_VIRTUAL_ENV:-' "$BOOTSTRAP"; then
    pass "S2: bootstrap.sh exports ILLOGICAL_IMPULSE_VIRTUAL_ENV fallback before switchwall (D-05, DEBT-06)"
  else
    fail "S2: bootstrap.sh missing ILLOGICAL_IMPULSE_VIRTUAL_ENV export"
  fi

  if grep -q 'Aligned kde-material-you-colors-wrapper.sh virtualenv fallback' "$BOOTSTRAP" && \
     grep -q 'Aligned applycolor.sh Kitty process signaling' "$BOOTSTRAP"; then
    pass "S2: bootstrap.sh contains idempotent alignment hooks for wrapper and applycolor (D-06, D-07)"
  else
    fail "S2: bootstrap.sh missing alignment hooks for kde wrapper or applycolor"
  fi

  # 2. Live kde-material-you-colors-wrapper.sh parameter expansion fallback
  KDE_WRAPPER="$HOME/.config/matugen/templates/kde/kde-material-you-colors-wrapper.sh"
  if [[ -f "$KDE_WRAPPER" ]] && grep -Fq '${ILLOGICAL_IMPULSE_VIRTUAL_ENV:-$XDG_STATE_HOME/quickshell/.venv}' "$KDE_WRAPPER"; then
    pass "S2: Live kde wrapper contains parameter expansion fallback \${ILLOGICAL_IMPULSE_VIRTUAL_ENV:-...} (D-06)"
  else
    fail "S2: Live kde wrapper missing parameter expansion fallback"
  fi

  # 3. Live applycolor.sh contains atomic killall signaling and no pidof
  APPLYCOLOR="$HOME/.config/quickshell/ii/scripts/colors/applycolor.sh"
  if [[ -f "$APPLYCOLOR" ]] && grep -Fq 'killall -SIGUSR1 kitty 2>/dev/null || true' "$APPLYCOLOR" && ! grep -q 'pidof kitty' "$APPLYCOLOR"; then
    pass "S2: Live applycolor.sh uses atomic killall -SIGUSR1 kitty without pidof (D-07)"
  else
    fail "S2: Live applycolor.sh signaling not aligned to atomic killall"
  fi

  # 4. Isolated scratch sandbox drill: verify idempotent sed transformations
  SCRATCH_DIR="$(mktemp -d /tmp/p30-scratch-drill-XXXXXX)"
  SCRATCH_ROOTS+=("$SCRATCH_DIR")

  mkdir -p "$SCRATCH_DIR/.config/matugen/templates/kde"
  mkdir -p "$SCRATCH_DIR/.config/quickshell/ii/scripts/colors"

  cat << 'EOF' > "$SCRATCH_DIR/.config/matugen/templates/kde/kde-material-you-colors-wrapper.sh"
source "$(eval echo $ILLOGICAL_IMPULSE_VIRTUAL_ENV)/bin/activate"
kde-material-you-colors "$mode_flag" --color "$color"
EOF

  cat << 'EOF' > "$SCRATCH_DIR/.config/quickshell/ii/scripts/colors/applycolor.sh"
  # Reload
  if ! pgrep -f kitty >/dev/null; then
    return
  fi
  kill -SIGUSR1 $(pidof kitty)
EOF

  # First transformation pass (simulating bootstrap)
  sed -i 's|source "$(eval echo \$ILLOGICAL_IMPULSE_VIRTUAL_ENV)/bin/activate"|source "$(eval echo ${ILLOGICAL_IMPULSE_VIRTUAL_ENV:-$XDG_STATE_HOME/quickshell/.venv})/bin/activate"|g' \
    "$SCRATCH_DIR/.config/matugen/templates/kde/kde-material-you-colors-wrapper.sh"
  sed -i '/if ! pgrep -f kitty >\/dev\/null; then/,/kill -SIGUSR1 \$(pidof kitty)/c\  killall -SIGUSR1 kitty 2>/dev/null || true' \
    "$SCRATCH_DIR/.config/quickshell/ii/scripts/colors/applycolor.sh"

  # Second transformation pass (simulating idempotent re-run)
  if ! grep -Fq '${ILLOGICAL_IMPULSE_VIRTUAL_ENV:-' "$SCRATCH_DIR/.config/matugen/templates/kde/kde-material-you-colors-wrapper.sh"; then
    sed -i 's|source "$(eval echo \$ILLOGICAL_IMPULSE_VIRTUAL_ENV)/bin/activate"|source "$(eval echo ${ILLOGICAL_IMPULSE_VIRTUAL_ENV:-$XDG_STATE_HOME/quickshell/.venv})/bin/activate"|g' \
      "$SCRATCH_DIR/.config/matugen/templates/kde/kde-material-you-colors-wrapper.sh"
  fi
  if grep -q 'kill -SIGUSR1 \$(pidof kitty)' "$SCRATCH_DIR/.config/quickshell/ii/scripts/colors/applycolor.sh"; then
    sed -i '/if ! pgrep -f kitty >\/dev\/null; then/,/kill -SIGUSR1 \$(pidof kitty)/c\  killall -SIGUSR1 kitty 2>/dev/null || true' \
      "$SCRATCH_DIR/.config/quickshell/ii/scripts/colors/applycolor.sh"
  fi

  if grep -Fq '${ILLOGICAL_IMPULSE_VIRTUAL_ENV:-$XDG_STATE_HOME/quickshell/.venv}' "$SCRATCH_DIR/.config/matugen/templates/kde/kde-material-you-colors-wrapper.sh" && \
     grep -Fq 'killall -SIGUSR1 kitty 2>/dev/null || true' "$SCRATCH_DIR/.config/quickshell/ii/scripts/colors/applycolor.sh"; then
    pass "S2: Isolated scratch drill confirmed idempotent transformation and syntax stability (D-06, D-07)"
  else
    fail "S2: Isolated scratch drill failed idempotent transformation check"
  fi
fi

# ===========================================================================
# Section 3: Nyquist Compliance & Traceability Sign-Off (DEBT-07, D-08..D-12)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 3 ]]; then
  info "--- Section 3: Nyquist Compliance & Traceability Sign-Off (DEBT-07) ---"

  # 1. Validation contract status check for all Milestone v0.5 phases (25..30)
  for p in 25 26 27 28 29 30; do
    v_file="$(find "$REPO_ROOT/.planning/phases" -maxdepth 2 -name "${p}-VALIDATION.md" | head -1)"
    if [[ -n "$v_file" && -f "$v_file" ]]; then
      if grep -q 'status:\s*validated' "$v_file" && \
         grep -q 'nyquist_compliant:\s*true' "$v_file" && \
         grep -q 'wave_0_complete:\s*true' "$v_file"; then
        pass "S3: Phase $p validation contract ($v_file) is marked validated and Nyquist-compliant (D-08, D-10)"
      else
        fail "S3: Phase $p validation contract ($v_file) missing validated, nyquist_compliant, or wave_0_complete flag"
      fi
    else
      fail "S3: Phase $p validation contract (${p}-VALIDATION.md) not found"
    fi
  done

  # 2. 29-VALIDATION.md has 0 pending tasks
  P29_VAL="$(find "$REPO_ROOT/.planning/phases" -maxdepth 2 -name "29-VALIDATION.md" | head -1)"
  if [[ -n "$P29_VAL" && -f "$P29_VAL" ]]; then
    # Look for pending marker in task rows or status
    p29_pending="$(grep -c -i 'pending' "$P29_VAL" || true)"
    if [[ "$p29_pending" -eq 0 ]]; then
      pass "S3: 29-VALIDATION.md has 0 pending tasks / markers (D-08)"
    else
      fail "S3: 29-VALIDATION.md contains $p29_pending pending markers"
    fi
  else
    fail "S3: 29-VALIDATION.md not found"
  fi

  # 3. REQUIREMENTS.md registers DEBT-05 through DEBT-08 with 0 stale Pending markers
  REQ_FILE="$REPO_ROOT/.planning/REQUIREMENTS.md"
  if [[ -f "$REQ_FILE" ]]; then
    for req in DEBT-05 DEBT-06 DEBT-07 DEBT-08; do
      if grep -q "$req" "$REQ_FILE"; then
        pass "S3: $req registered in REQUIREMENTS.md (D-11)"
      else
        fail "S3: $req missing from REQUIREMENTS.md"
      fi
    done

    stale_pending="$(grep -c -E '\|\s*Pending\s*\|' "$REQ_FILE" || true)"
    if [[ "$stale_pending" -eq 0 ]]; then
      pass "S3: REQUIREMENTS.md contains 0 stale 'Pending' markers (D-11)"
    else
      fail "S3: REQUIREMENTS.md contains $stale_pending stale 'Pending' markers"
    fi
  else
    fail "S3: .planning/REQUIREMENTS.md not found"
  fi

  # 4. ROADMAP.md Phase 30 requirements mapping
  ROADMAP_FILE="$REPO_ROOT/.planning/ROADMAP.md"
  if [[ -f "$ROADMAP_FILE" ]]; then
    if grep -q 'DEBT-05' "$ROADMAP_FILE" && \
       grep -q 'DEBT-06' "$ROADMAP_FILE" && \
       grep -q 'DEBT-07' "$ROADMAP_FILE" && \
       grep -q 'DEBT-08' "$ROADMAP_FILE"; then
      pass "S3: ROADMAP.md maps DEBT-05 through DEBT-08 to Phase 30 (D-12)"
    else
      fail "S3: ROADMAP.md missing DEBT-05..DEBT-08 mapping for Phase 30"
    fi
  else
    fail "S3: .planning/ROADMAP.md not found"
  fi
fi

# ===========================================================================
# Section 4: Strict System Verifier Gate (DEBT-08, D-14)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 4 ]]; then
  info "--- Section 4: Strict System Verifier Gate (DEBT-08, D-14) ---"

  VERIFY_SCRIPT="$REPO_ROOT/arch/dots-hyprland.sh"
  if [[ -x "$VERIFY_SCRIPT" ]]; then
    v_rc=0
    v_out="$("$VERIFY_SCRIPT" verify --strict 2>&1)" || v_rc=$?
    if [[ "$v_rc" -eq 0 ]] && printf '%s\n' "$v_out" | grep -q 'FINDINGS=0'; then
      pass "S4: ./arch/dots-hyprland.sh verify --strict passed with 0 findings (D-14)"
    else
      fail "S4: ./arch/dots-hyprland.sh verify --strict failed (exit code $v_rc)"
      printf '%s\n' "$v_out" | tail -n 20 | sed 's/^/       /' >&2
    fi
  else
    fail "S4: arch/dots-hyprland.sh missing or not executable"
  fi
fi

# ===========================================================================
# Section 5: Multi-Phase Regression Sweep (Phases 25–29) (DEBT-08, D-09, D-14)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 5 ]]; then
  info "--- Section 5: Multi-Phase Regression Sweep (Phases 25–29) ---"

  for p_script in "scripts/phase25-gtk-material-you-assert.sh" \
                  "scripts/phase26-qt-kde-material-you-assert.sh" \
                  "scripts/phase27-accent-coordination-assert.sh" \
                  "scripts/phase28-terminal-fuzzel-assert.sh" \
                  "scripts/phase29-theme-data-contracts-assert.sh"; do
    if [[ -x "$REPO_ROOT/$p_script" ]]; then
      p_rc=0
      p_out="$("$REPO_ROOT/$p_script" 2>&1)" || p_rc=$?
      if [[ "$p_rc" -eq 0 ]]; then
        pass "S5: $p_script passed cleanly with 0 failures (D-09, D-14)"
      else
        fail "S5: $p_script failed with exit code $p_rc"
        printf '%s\n' "$p_out" | tail -n 20 | sed 's/^/       /' >&2
      fi
    else
      fail "S5: $p_script missing or not executable"
    fi
  done
fi

# ===========================================================================
# Closing porcelain invariant check & summary
# ===========================================================================
porcelain_snapshot > "$PORCELAIN_AFTER"
if cmp -s "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER"; then
  pass "Closing self-check: git status --porcelain unchanged across run (D-14)"
else
  fail "Closing self-check: git status --porcelain mutated across run (D-14)"
  diff -u "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER" || true
fi

echo "=== done: FAIL=${FAIL} FINDINGS=${FINDINGS} ==="
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
