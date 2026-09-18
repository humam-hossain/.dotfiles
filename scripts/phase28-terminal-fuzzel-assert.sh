#!/usr/bin/env bash
# Phase 28 Terminal & Fuzzel Launcher Dynamic Palette assert harness (TERM-01, TERM-02, INTG-01, INTG-02).
# One script, one section per requirement criterion, one verdict for the phase.
#
# Usage (from REPO_ROOT):
#   ./scripts/phase28-terminal-fuzzel-assert.sh [--section <1-5>]
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

PORCELAIN_BEFORE="$(mktemp /tmp/p28-porcelain-before-XXXXXX)"
PORCELAIN_AFTER="$(mktemp /tmp/p28-porcelain-after-XXXXXX)"
TMP_FILES+=("$PORCELAIN_BEFORE" "$PORCELAIN_AFTER")

porcelain_snapshot > "$PORCELAIN_BEFORE"

# ===========================================================================
# Section 1: Template & Config Readiness (INTG-01, TERM-01, TERM-02, D-01, D-03, D-12, D-16)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 1 ]]; then
  info "--- Section 1: Template & Config Readiness (INTG-01, TERM-01, TERM-02, D-01, D-03, D-12, D-16) ---"

  # 1. Matugen Fuzzel template exists and contains M3 tokens
  FUZZEL_TPL="$REPO_ROOT/vendor/dots-hyprland/dots/.config/matugen/templates/fuzzel/fuzzel_theme.ini"
  [[ -f "$FUZZEL_TPL" ]] || FUZZEL_TPL="$XDG_CONFIG_HOME/matugen/templates/fuzzel/fuzzel_theme.ini"
  if [[ -f "$FUZZEL_TPL" ]] && \
     grep -q 'background={{colors.background.default.hex_stripped}}ff' "$FUZZEL_TPL" && \
     grep -q 'text={{colors.on_background.default.hex_stripped}}ff' "$FUZZEL_TPL" && \
     grep -q 'border={{colors.surface_variant.default.hex_stripped}}dd' "$FUZZEL_TPL"; then
    pass "S1: Matugen Fuzzel template declares M3 background, text, and border tokens (D-12, D-13)"
  else
    fail "S1: Matugen Fuzzel template missing or lacks required token bindings ($FUZZEL_TPL)"
  fi

  # 2. Matugen config.toml contains [templates.fuzzel] mapping
  MATUGEN_CFG="$XDG_CONFIG_HOME/matugen/config.toml"
  if [[ -f "$MATUGEN_CFG" ]] && \
     grep -q '^\[templates\.fuzzel\]' "$MATUGEN_CFG" && \
     grep -E -q 'output_path = ["'\'']~/\.config/fuzzel/fuzzel_theme\.ini["'\'']' "$MATUGEN_CFG"; then
    pass "S1: ~/.config/matugen/config.toml registers [templates.fuzzel] output path (D-12)"
  else
    fail "S1: ~/.config/matugen/config.toml missing [templates.fuzzel] configuration"
  fi

  # 3. restow/kitty kitty.conf include statement and cold-start seed target
  REPO_KITTY_CONF="$REPO_ROOT/restow/kitty/.config/kitty/kitty.conf"
  SEED_KITTY_THEME="$XDG_STATE_HOME/quickshell/user/generated/terminal/kitty-theme.conf"
  if [[ -f "$REPO_KITTY_CONF" ]] && grep -q '^include ~/.local/state/quickshell/user/generated/terminal/kitty-theme.conf' "$REPO_KITTY_CONF"; then
    pass "S1: restow/kitty kitty.conf includes generated kitty-theme.conf (D-01)"
  else
    fail "S1: restow/kitty kitty.conf missing required theme include statement"
  fi
  if [[ -f "$SEED_KITTY_THEME" ]]; then
    pass "S1: cold-start seed kitty-theme.conf exists on disk (D-07)"
  else
    fail "S1: cold-start seed kitty-theme.conf missing ($SEED_KITTY_THEME)"
  fi

  # 4. restow/fuzzel fuzzel.ini include statement & defaults
  REPO_FUZZEL_INI="$REPO_ROOT/restow/fuzzel/.config/fuzzel/fuzzel.ini"
  if [[ -f "$REPO_FUZZEL_INI" ]] && \
     grep -q '^include="~/.config/fuzzel/fuzzel_theme.ini"' "$REPO_FUZZEL_INI" && \
     grep -q '^terminal=kitty -1' "$REPO_FUZZEL_INI" && \
     grep -q '^radius=17' "$REPO_FUZZEL_INI" && \
     grep -q '^prompt=">>  "' "$REPO_FUZZEL_INI" && \
     grep -q '^exit-immediately-if-empty=yes' "$REPO_FUZZEL_INI"; then
    pass "S1: restow/fuzzel fuzzel.ini declares theme include, terminal=kitty -1, and squircle radius 17 (D-14..D-16)"
  else
    fail "S1: restow/fuzzel fuzzel.ini missing required options ($REPO_FUZZEL_INI)"
  fi

  # 5. guard-paths.tsv contract for fuzzel_theme.ini
  GUARD_TSV="$REPO_ROOT/guard-paths.tsv"
  if grep -qF '$XDG_CONFIG_HOME/fuzzel/fuzzel_theme.ini' "$GUARD_TSV"; then
    pass "S1: guard-paths.tsv guards \$XDG_CONFIG_HOME/fuzzel/fuzzel_theme.ini (D-16)"
  else
    fail "S1: guard-paths.tsv missing fuzzel_theme.ini guard entry"
  fi
  ROW="$(grep -F '$XDG_CONFIG_HOME/fuzzel/fuzzel_theme.ini' "$GUARD_TSV" || true)"
  IFS=$'\t' read -r c1 c2 c3 c4 <<< "$ROW"
  if [[ "$c1" == '$XDG_CONFIG_HOME/fuzzel/fuzzel_theme.ini' && "$c2" == "generated_theme" && "$c3" == "matugen" && -n "$c4" && ! "$c1" =~ [[:space:]] && ! "$c2" =~ [[:space:]] && ! "$c3" =~ [[:space:]] ]]; then
    pass "S1: fuzzel_theme.ini guard entry strictly tab-separated as generated_theme (INTG-01, D-16)"
  else
    fail "S1: fuzzel_theme.ini guard entry not properly tab-separated (INTG-01, D-16)"
  fi

  # 6. Claimed helper kittens in restow/kitty
  if [[ -f "$REPO_ROOT/restow/kitty/.config/kitty/search.py" && -f "$REPO_ROOT/restow/kitty/.config/kitty/scroll_mark.py" ]]; then
    pass "S1: Helper kittens search.py and scroll_mark.py present in restow/kitty package (D-03)"
  else
    fail "S1: Helper kittens missing from restow/kitty package (D-03)"
  fi
fi

# ===========================================================================
# Section 2: Fuzzel Theme Syntax & Configuration Integrity (TERM-01, D-13, D-14)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 ]]; then
  info "--- Section 2: Fuzzel Theme Syntax & Configuration Integrity (TERM-01, D-13, D-14) ---"

  LIVE_FUZZEL_THEME="$XDG_CONFIG_HOME/fuzzel/fuzzel_theme.ini"
  if [[ -f "$LIVE_FUZZEL_THEME" && -s "$LIVE_FUZZEL_THEME" ]]; then
    pass "S2: Live fuzzel_theme.ini exists and is non-empty ($LIVE_FUZZEL_THEME)"
  else
    fail "S2: Live fuzzel_theme.ini missing or empty ($LIVE_FUZZEL_THEME)"
  fi

  # Programmatic INI token and alpha validation via Python
  FUZZEL_PY_VERDICT="$(python3 -c "
import configparser, sys, re
c = configparser.ConfigParser()
c.read('$LIVE_FUZZEL_THEME')
if 'colors' not in c:
    print('FAIL: Missing [colors] section')
    sys.exit(1)

tokens = ['background', 'text', 'selection', 'selection-text', 'border', 'match', 'selection-match']
hex8 = re.compile(r'^[0-9a-fA-F]{8}$')
for t in tokens:
    val = c['colors'].get(t)
    if not val or not hex8.match(val):
        print(f'FAIL: Invalid or missing token {t}={val}')
        sys.exit(1)

bg = c['colors']['background']
border = c['colors']['border']
if not bg.endswith('ff'):
    print(f'FAIL: Background alpha must be ff (solid), got {bg}')
    sys.exit(1)
if not border.endswith('dd'):
    print(f'FAIL: Border alpha must be dd, got {border}')
    sys.exit(1)

print('PASS: All tokens valid with correct ff/dd alpha')
" 2>&1 || true)"

  if [[ "$FUZZEL_PY_VERDICT" =~ ^PASS ]]; then
    pass "S2: fuzzel_theme.ini contains all 7 required color tokens with valid 8-digit hex and ff/dd alpha (D-13)"
  else
    fail "S2: fuzzel_theme.ini validation failed: $FUZZEL_PY_VERDICT"
  fi

  # Dry-run invocation of fuzzel parser on empty stdin
  LIVE_FUZZEL_INI="$XDG_CONFIG_HOME/fuzzel/fuzzel.ini"
  if command -v fuzzel &>/dev/null; then
    ERR_OUT="$(fuzzel --config "$LIVE_FUZZEL_INI" -d -R < /dev/null 2>&1 || true)"
    if [[ -z "$ERR_OUT" ]]; then
      pass "S2: fuzzel dry-run parser validation exited cleanly without errors"
    else
      fail "S2: fuzzel dry-run returned configuration error: $ERR_OUT"
    fi
  else
    finding "S2: fuzzel binary not found on PATH; skipping binary parser probe"
  fi
fi

# ===========================================================================
# Section 3: Terminal Theme Syntax & Configuration Integrity (TERM-02, D-01, D-02, D-08..D-11)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 3 ]]; then
  info "--- Section 3: Terminal Theme Syntax & Configuration Integrity (TERM-02, D-01, D-02, D-08..D-11) ---"

  LIVE_KITTY_THEME="$XDG_STATE_HOME/quickshell/user/generated/terminal/kitty-theme.conf"
  if [[ -f "$LIVE_KITTY_THEME" && -s "$LIVE_KITTY_THEME" ]]; then
    pass "S3: Generated kitty-theme.conf exists and is non-empty ($LIVE_KITTY_THEME)"
  else
    fail "S3: Generated kitty-theme.conf missing or empty ($LIVE_KITTY_THEME)"
  fi

  # ANSI tokens and Starship prompt greys verification
  THEME_VERDICT="$(python3 -c "
import sys, re
hex_pat = re.compile(r'^#[0-9a-fA-F]{6}$')
required_tokens = ['background', 'foreground', 'cursor', 'selection_background', 'selection_foreground']
required_tokens += [f'color{i}' for i in range(16)]
required_tokens += [f'color{i}' for i in range(232, 241)]
required_tokens += [f'color{i}' for i in range(248, 256)]

found = {}
with open('$LIVE_KITTY_THEME', 'r') as f:
    for line in f:
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        parts = line.split()
        if len(parts) >= 2:
            found[parts[0]] = parts[1]

for req in required_tokens:
    if req not in found:
        print(f'FAIL: Missing token {req}')
        sys.exit(1)
    if not hex_pat.match(found[req]):
        print(f'FAIL: Invalid hex color for {req}: {found[req]}')
        sys.exit(1)

print('PASS: ANSI and Starship tokens valid')
" 2>&1 || true)"

  if [[ "$THEME_VERDICT" =~ ^PASS ]]; then
    pass "S3: kitty-theme.conf contains valid ANSI color0-15 and Starship color232-255 hex tokens (D-11)"
  else
    fail "S3: kitty-theme.conf token validation failed: $THEME_VERDICT"
  fi

  # Kitty configuration parser probe for opacity 0.90 per Phase 28 UAT preference (28-UAT.md) and Phase 30 alignment (DEBT-05, D-02)
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
    pass "S3: Kitty configuration validated natively: opacity=0.90, shell=zsh, margin=21.75 (D-01, D-02, D-09)"
  else
    fail "S3: Kitty configuration probe failed: $KITTY_OPTS_VERDICT"
  fi

  # Verify ~/.config/illogical-impulse/config.json retains forceDarkMode and tuned parameters
  II_CONFIG="$XDG_CONFIG_HOME/illogical-impulse/config.json"
  if [[ -f "$II_CONFIG" ]]; then
    DARK_MODE="$(jq -r '.appearance.wallpaperTheming.terminalGenerationProps.forceDarkMode' "$II_CONFIG")"
    HARMONY="$(jq -r '.appearance.wallpaperTheming.terminalGenerationProps.harmony' "$II_CONFIG")"
    BOOST="$(jq -r '.appearance.wallpaperTheming.terminalGenerationProps.termFgBoost' "$II_CONFIG")"
    if [[ "$DARK_MODE" == "true" && "$HARMONY" == "0.6" && "$BOOST" == "0.35" ]]; then
      pass "S3: config.json retains forceDarkMode=true, harmony=0.6, termFgBoost=0.35 (D-10, D-11)"
    else
      fail "S3: config.json terminal props mismatch (dark=$DARK_MODE, harm=$HARMONY, boost=$BOOST)"
    fi
  else
    fail "S3: config.json missing at $II_CONFIG"
  fi

  # Universal terminal sequences.txt presence
  LIVE_SEQUENCES="$XDG_STATE_HOME/quickshell/user/generated/terminal/sequences.txt"
  if [[ -f "$LIVE_SEQUENCES" && -s "$LIVE_SEQUENCES" ]]; then
    pass "S3: Generated terminal sequences.txt exists and is non-empty ($LIVE_SEQUENCES)"
  else
    fail "S3: Generated terminal sequences.txt missing or empty ($LIVE_SEQUENCES)"
  fi
fi

# ===========================================================================
# Section 4: Live Reload Drill & Process Signaling (TERM-01, TERM-02, D-05, D-18)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 4 ]]; then
  info "--- Section 4: Live Reload Drill & Process Signaling (TERM-01, TERM-02, D-05, D-18) ---"

  SWITCHWALL="$XDG_CONFIG_HOME/quickshell/ii/scripts/colors/switchwall.sh"
  if [[ -x "$SWITCHWALL" ]]; then
    pass "S4: switchwall.sh orchestrator exists and is executable ($SWITCHWALL)"
  else
    fail "S4: switchwall.sh missing or not executable ($SWITCHWALL)"
  fi

  LIVE_FUZZEL_THEME="$XDG_CONFIG_HOME/fuzzel/fuzzel_theme.ini"
  LIVE_KITTY_THEME="$XDG_STATE_HOME/quickshell/user/generated/terminal/kitty-theme.conf"
  LIVE_SEQUENCES="$XDG_STATE_HOME/quickshell/user/generated/terminal/sequences.txt"

  BEFORE_FUZZEL_MTIME="$(stat -c %Y "$LIVE_FUZZEL_THEME" 2>/dev/null || echo 0)"
  BEFORE_KITTY_MTIME="$(stat -c %Y "$LIVE_KITTY_THEME" 2>/dev/null || echo 0)"
  BEFORE_SEQ_MTIME="$(stat -c %Y "$LIVE_SEQUENCES" 2>/dev/null || echo 0)"

  # Guarantee filesystem clock-tick before triggering reload
  sleep 1

  # Execute wallpaper reload pipeline without changing wallpaper
  SW_RC=0
  "$SWITCHWALL" --noswitch >/dev/null 2>&1 || SW_RC=$?
  if [[ "$SW_RC" -eq 0 ]]; then
    pass "S4: switchwall.sh --noswitch completed successfully with exit 0"
  else
    fail "S4: switchwall.sh --noswitch failed with exit code $SW_RC"
  fi

  # Record post-run mtimes
  AFTER_FUZZEL_MTIME="$(stat -c %Y "$LIVE_FUZZEL_THEME" 2>/dev/null || echo 0)"
  AFTER_KITTY_MTIME="$(stat -c %Y "$LIVE_KITTY_THEME" 2>/dev/null || echo 0)"
  AFTER_SEQ_MTIME="$(stat -c %Y "$LIVE_SEQUENCES" 2>/dev/null || echo 0)"

  if [[ "$AFTER_FUZZEL_MTIME" -gt "$BEFORE_FUZZEL_MTIME" ]]; then
    pass "S4: fuzzel_theme.ini mtime advanced ($BEFORE_FUZZEL_MTIME -> $AFTER_FUZZEL_MTIME) (D-12)"
  else
    fail "S4: fuzzel_theme.ini mtime was not updated by switchwall.sh"
  fi

  if [[ "$AFTER_KITTY_MTIME" -gt "$BEFORE_KITTY_MTIME" ]]; then
    pass "S4: kitty-theme.conf mtime advanced ($BEFORE_KITTY_MTIME -> $AFTER_KITTY_MTIME) (D-05)"
  else
    fail "S4: kitty-theme.conf mtime was not updated by switchwall.sh"
  fi

  if [[ "$AFTER_SEQ_MTIME" -gt "$BEFORE_SEQ_MTIME" ]]; then
    pass "S4: sequences.txt mtime advanced ($BEFORE_SEQ_MTIME -> $AFTER_SEQ_MTIME) (D-06)"
  else
    fail "S4: sequences.txt mtime was not updated by switchwall.sh"
  fi

  # Dual-mode Kitty process probe
  if pgrep -f kitty >/dev/null; then
    KITTY_PID="$(pidof kitty 2>/dev/null | awk '{print $1}' || pgrep -f kitty | head -1)"
    kill -SIGUSR1 "$KITTY_PID" 2>/dev/null || true
    sleep 0.2
    if kill -0 "$KITTY_PID" 2>/dev/null; then
      pass "S4: Running Kitty (PID $KITTY_PID) handled SIGUSR1 reload live without terminating (D-05, D-18)"
    else
      fail "S4: Kitty process died after SIGUSR1 reload"
    fi
  else
    info "S4: Kitty not currently running; headless syntax check satisfied by Section 3 probe (D-18)"
  fi
fi

# ===========================================================================
# Section 5: Strict Verification Engine & Zero Git Drift (INTG-01, INTG-02, D-17, D-19)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 5 ]]; then
  info "--- Section 5: Strict Verification Engine & Zero Git Drift (INTG-01, INTG-02, D-17, D-19) ---"

  # 1. Cleanliness of packaging trees
  DIRTY_PACKAGES="$(git status --porcelain stow/ restow/ capture/ || true)"
  if [[ -z "$DIRTY_PACKAGES" ]]; then
    pass "S5: Packaging directories (stow/, restow/, capture/) are 100% clean (INTG-02)"
  else
    fail "S5: Packaging directories dirty: $DIRTY_PACKAGES (INTG-02)"
  fi

  # 2. Strict verification engine run
  VERIFY_RC=0
  VERIFY_OUT="$("$REPO_ROOT/arch/dots-hyprland.sh" verify --strict 2>&1)" || VERIFY_RC=$?
  if [[ "$VERIFY_RC" -eq 0 ]]; then
    pass "S5: arch/dots-hyprland.sh verify --strict passed with 0 findings (INTG-02)"
  else
    fail "S5: arch/dots-hyprland.sh verify --strict failed (rc=$VERIFY_RC) (INTG-02)"
    printf '%s\n' "$VERIFY_OUT" | sed 's/^/       /' >&2
  fi

  # 3. Assert search.py and scroll_mark.py claimed as verified
  if echo "$VERIFY_OUT" | grep -q 'verified: .*/\.config/kitty/search\.py' && \
     echo "$VERIFY_OUT" | grep -q 'verified: .*/\.config/kitty/scroll_mark\.py'; then
    pass "S5: Helper kittens claimed as verified links rather than unclaimed stubs (D-03)"
  else
    fail "S5: Helper kittens not classified as verified links by verify engine"
  fi

  # 4. Assert fuzzel_theme.ini claimed as guarded theme output
  if echo "$VERIFY_OUT" | grep -q 'guarded theme output: .*/\.config/fuzzel/fuzzel_theme\.ini'; then
    pass "S5: fuzzel_theme.ini classified as guarded theme output (D-16, INTG-01)"
  else
    fail "S5: fuzzel_theme.ini not classified as guarded theme output by verify engine"
  fi
fi

# ===========================================================================
# Closing porcelain invariant check & summary
# ===========================================================================
porcelain_snapshot > "$PORCELAIN_AFTER"
if cmp -s "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER"; then
  pass "Closing self-check: git status --porcelain unchanged across run (D-19)"
else
  fail "Closing self-check: git status --porcelain mutated across run (D-19)"
  diff -u "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER" || true
fi

echo "=== done: FAIL=${FAIL} FINDINGS=${FINDINGS} ==="
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
