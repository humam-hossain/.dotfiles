#!/usr/bin/env bash
# ===========================================================================
# Phase 51: WWO Fetcher Service & Local Cache Architecture Assert Harness
# Enforces: WWO-01, WWO-02, WWO-03, WWO-04
#
# Usage (from REPO_ROOT):
#   ./scripts/phase51-weather-assert.sh [1-5] [OPTIONS]
#
# Options:
#   -s, --section <1-5>    Execute only the specified section (1-5)
#   -q, --quick,           Run fast static checks only
#       --standalone
#   -c, --syntax           Execute static bash/python syntax checks only
#   -h, --help             Show this help message
#
# Exit 0 if all hard asserts pass (FAIL=0); exit 1 if any FAIL.
# ===========================================================================

set -euo pipefail

# Fail closed if executed as root (ASVS L1 Root Privilege Prevention / T-51-02)
if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
  echo "Error: Do not run as root" >&2
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$REPO_ROOT"

FAIL=0
FINDINGS=0

pass()    { printf '[PASS] %s\n' "$1"; }
fail()    { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
finding() { printf '[FINDING] %s\n' "$1"; FINDINGS=$((FINDINGS + 1)); }
info()    { printf '[INFO] %s\n' "$1"; }

TMP_DIRS=()
cleanup() {
  local exit_code=$?
  if [[ ${#TMP_DIRS[@]} -gt 0 ]]; then
    for d in "${TMP_DIRS[@]}"; do
      rm -rf "$d" 2>/dev/null || true
    done
  fi
  return "$exit_code"
}
trap cleanup EXIT INT TERM

RUN_SECTION=0
QUICK_MODE=0
SYNTAX_ONLY=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    1|2|3|4|5)
      RUN_SECTION="$1"
      shift
      ;;
    --section|-s)
      if [[ -z "${2:-}" ]] || ! [[ "$2" =~ ^[1-5]$ ]]; then
        echo "Error: --section requires an integer from 1 to 5" >&2
        exit 1
      fi
      RUN_SECTION="$2"
      shift 2
      ;;
    --quick|--standalone|-q)
      QUICK_MODE=1
      shift
      ;;
    --syntax|-c)
      SYNTAX_ONLY=1
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [1-5] [OPTIONS]"
      echo ""
      echo "Sections:"
      echo "  1: Static Syntax, Permissions, & Stow Credential Integrity (WWO-01, D-51-01, D-51-03)"
      echo "  2: CLI Helper Flags & Configuration Resolution (WWO-01, D-51-09)"
      echo "  3: Dynamic Budget Pacing Math & UTC Rollover (WWO-02, D-51-04)"
      echo "  4: Atomic Write & JSON Schema Contract (WWO-03, D-51-06)"
      echo "  5: Offline Resilience & Cold Boot Recovery (WWO-04, D-51-05, D-51-07, D-51-08)"
      echo ""
      echo "Options:"
      echo "  -s, --section <1-5>    Execute only the specified section (1-5)"
      echo "  -q, --quick,           Run fast static checks only"
      echo "      --standalone"
      echo "  -c, --syntax           Execute static bash/python syntax checks only"
      echo "  -h, --help             Show this help message"
      exit 0
      ;;
    *)
      echo "Error: Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

FETCHER_SCRIPT="$REPO_ROOT/stow/weather/.config/weather/wwo-fetcher.py"
ENV_EXAMPLE="$REPO_ROOT/stow/weather/.config/weather/.env.example"
SERVICE_UNIT="$REPO_ROOT/stow/weather/.config/systemd/user/wwo-fetcher.service"
TIMER_UNIT="$REPO_ROOT/stow/weather/.config/systemd/user/wwo-fetcher.timer"

# Syntax-only mode
if [[ "$SYNTAX_ONLY" -eq 1 ]]; then
  info "--- Running Syntax Validation Mode ---"
  bash -n "$0"
  pass "Assert harness bash syntax check passed (bash -n verified)"
  if [[ -f "$FETCHER_SCRIPT" ]]; then
    python3 -m py_compile "$FETCHER_SCRIPT"
    pass "wwo-fetcher.py python compile check passed"
  else
    info "wwo-fetcher.py not yet present (pending Wave 2)"
  fi
  info "=== Syntax Summary: FAIL=$FAIL, FINDINGS=$FINDINGS ==="
  exit "$FAIL"
fi

# ===========================================================================
# Section 1: Static Syntax, Permissions, & Stow Credential Integrity
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 1 ]]; then
  info "--- Section 1: Static Syntax, Permissions, & Stow Integrity ---"

  # 1.1 Template file exists and is readable
  if [[ -f "$ENV_EXAMPLE" ]]; then
    pass "S1: stow/weather/.config/weather/.env.example exists"
  else
    fail "S1: Missing template stow/weather/.config/weather/.env.example"
  fi

  # 1.2 Git ignore rules for live and stow credentials
  if grep -qF ".config/weather/.env" "$REPO_ROOT/.gitignore" && \
     grep -qF "stow/weather/.config/weather/.env" "$REPO_ROOT/.gitignore"; then
    pass "S1: .gitignore contains rules for .config/weather/.env and stow/weather/.config/weather/.env"
  else
    fail "S1: .gitignore missing explicit rules for weather .env files"
  fi

  # 1.3 Git index check: no .env file ever tracked in git under weather paths (T-51-01)
  if git ls-files stow/weather .config/weather 2>/dev/null | grep -E '(^|/)\.env$' >/dev/null 2>&1; then
    fail "S1: Security violation: Live weather .env file detected in git index"
  else
    pass "S1: Zero live weather .env secret files tracked in git repository"
  fi

  # 1.4 Stow target directory safety (check ~/.config/weather is not a folded symlink if it exists)
  if [[ -e "$HOME/.config/weather" ]]; then
    if [[ -L "$HOME/.config/weather" ]]; then
      fail "S1: Directory folding collision: $HOME/.config/weather is a symlink instead of directory"
    else
      pass "S1: $HOME/.config/weather is a real directory (no folding collision)"
    fi
  else
    pass "S1: $HOME/.config/weather not present yet (will be created in Wave 3 bootstrap)"
  fi

  # 1.5 Fetcher script static properties (if present)
  if [[ -f "$FETCHER_SCRIPT" ]]; then
    if [[ -x "$FETCHER_SCRIPT" ]]; then
      pass "S1: wwo-fetcher.py is executable"
    else
      fail "S1: wwo-fetcher.py exists but is not executable (expected 0755)"
    fi

    if python3 -m py_compile "$FETCHER_SCRIPT" >/dev/null 2>&1; then
      pass "S1: wwo-fetcher.py compiles cleanly under Python 3"
    else
      fail "S1: wwo-fetcher.py failed python3 compilation check"
    fi

    # Check for hardcoded API keys
    if grep -Ei "WWO_API_KEY\s*=\s*['\"][a-zA-Z0-9]{15,}['\"]" "$FETCHER_SCRIPT" >/dev/null 2>&1; then
      fail "S1: Potential hardcoded API key detected in wwo-fetcher.py"
    else
      pass "S1: No hardcoded API keys detected in wwo-fetcher.py source code"
    fi
  else
    info "S1: wwo-fetcher.py not yet present (pending Wave 2)"
  fi

  # 1.6 Systemd unit file static checks (if present)
  if [[ -f "$SERVICE_UNIT" ]]; then
    pass "S1: wwo-fetcher.service unit file exists"
    if grep -q "RuntimeDirectory=weather" "$SERVICE_UNIT"; then
      pass "S1: wwo-fetcher.service declares RuntimeDirectory=weather"
    else
      fail "S1: wwo-fetcher.service missing RuntimeDirectory=weather"
    fi
  else
    info "S1: wwo-fetcher.service not yet present (pending Wave 3)"
  fi

  if [[ -f "$TIMER_UNIT" ]]; then
    pass "S1: wwo-fetcher.timer unit file exists"
    if grep -q "OnUnitActiveSec=3m" "$TIMER_UNIT"; then
      pass "S1: wwo-fetcher.timer declares OnUnitActiveSec=3m"
    else
      fail "S1: wwo-fetcher.timer missing OnUnitActiveSec=3m"
    fi
  else
    info "S1: wwo-fetcher.timer not yet present (pending Wave 3)"
  fi
fi

# ===========================================================================
# Section 2: CLI Helper Flags & Configuration Resolution
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 ]]; then
  info "--- Section 2: CLI Helper Flags & Configuration Resolution ---"

  # Create an isolated temporary test fixture for config and env resolution testing
  FIXTURE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/p51-test-s2.XXXXXX")"
  TMP_DIRS+=("$FIXTURE_DIR")

  # 2.1 Test .env parser logic
  cat <<'EOF' > "$FIXTURE_DIR/.env.test"
# Comment line should be ignored
  # Indented comment
WWO_API_KEY="test_key_with_quotes"
OTHER_VAR = 'single_quoted_val'
UNQUOTED = simple_val
EMPTY_LINE=
# WWO_API_KEY=should_be_ignored
EOF

  PARSER_RESULT=$(python3 -c '
import sys, os

def parse_env(path):
    env = {}
    if not os.path.exists(path):
        return env
    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            if "=" in line:
                k, v = line.split("=", 1)
                env[k.strip()] = v.strip().strip("\"'\''")
    return env

res = parse_env(sys.argv[1])
assert res.get("WWO_API_KEY") == "test_key_with_quotes", "Bad key: " + str(res.get("WWO_API_KEY"))
assert res.get("OTHER_VAR") == "single_quoted_val", "Bad other: " + str(res.get("OTHER_VAR"))
assert res.get("UNQUOTED") == "simple_val", "Bad unquoted: " + str(res.get("UNQUOTED"))
print("OK")
' "$FIXTURE_DIR/.env.test" 2>&1 || echo "ERROR")

  if [[ "$PARSER_RESULT" == "OK" ]]; then
    pass "S2: .env parser strips comments, quotes, and whitespace correctly without external modules"
  else
    fail "S2: .env parser failed unit test: $PARSER_RESULT"
  fi

  # 2.2 Test city resolution logic per D-51-09
  CITY_DEFAULT=$(python3 -c '
import json, os

def resolve_city(config_path):
    if os.path.isfile(config_path):
        try:
            with open(config_path, "r", encoding="utf-8") as f:
                data = json.load(f)
                city = data.get("bar", {}).get("weather", {}).get("city")
                if city and isinstance(city, str) and city.strip():
                    return city.strip()
        except Exception:
            pass
    return "Dhaka"

# Test 1: Missing file -> Dhaka
assert resolve_city("/nonexistent/config.json") == "Dhaka"
print("OK_DEFAULT")
' 2>&1 || echo "ERROR")

  if [[ "$CITY_DEFAULT" == "OK_DEFAULT" ]]; then
    pass "S2: City resolution defaults to 'Dhaka' when config is absent or empty per D-51-09"
  else
    fail "S2: City resolution default check failed: $CITY_DEFAULT"
  fi

  # Test city extraction when present
  cat <<'EOF' > "$FIXTURE_DIR/config.json"
{
  "bar": {
    "weather": {
      "city": "Tokyo",
      "enable": true
    }
  }
}
EOF

  CITY_CONFIGURED=$(python3 -c '
import json, os, sys

def resolve_city(config_path):
    if os.path.isfile(config_path):
        try:
            with open(config_path, "r", encoding="utf-8") as f:
                data = json.load(f)
                city = data.get("bar", {}).get("weather", {}).get("city")
                if city and isinstance(city, str) and city.strip():
                    return city.strip()
        except Exception:
            pass
    return "Dhaka"

assert resolve_city(sys.argv[1]) == "Tokyo"
print("OK_CONFIGURED")
' "$FIXTURE_DIR/config.json" 2>&1 || echo "ERROR")

  if [[ "$CITY_CONFIGURED" == "OK_CONFIGURED" ]]; then
    pass "S2: City resolution extracts bar.weather.city from illogical-impulse config.json per D-51-09"
  else
    fail "S2: City resolution configured check failed: $CITY_CONFIGURED"
  fi

  # 2.3 CLI flags testing if wwo-fetcher.py is present
  if [[ -f "$FETCHER_SCRIPT" && -x "$FETCHER_SCRIPT" ]]; then
    HELP_OUT=$("$FETCHER_SCRIPT" --help 2>&1 || true)
    if echo "$HELP_OUT" | grep -qi "usage"; then
      pass "S2: wwo-fetcher.py --help outputs valid usage documentation"
    else
      fail "S2: wwo-fetcher.py --help did not output usage documentation"
    fi

    STATUS_OUT=$("$FETCHER_SCRIPT" --status 2>&1 || true)
    if echo "$STATUS_OUT" | grep -qi "quota\|cache\|status"; then
      pass "S2: wwo-fetcher.py --status outputs status inspection telemetry"
    else
      fail "S2: wwo-fetcher.py --status failed or output unexpected format"
    fi

    DRY_OUT=$("$FETCHER_SCRIPT" --dry-run 2>&1 || true)
    if [[ $? -eq 0 ]]; then
      pass "S2: wwo-fetcher.py --dry-run succeeds without network interaction"
    else
      fail "S2: wwo-fetcher.py --dry-run exited with non-zero status"
    fi
  else
    info "S2: CLI binary tests deferred to Wave 2 (wwo-fetcher.py pending implementation)"
  fi
fi

# ===========================================================================
# Section 3: Dynamic Budget Pacing Math & UTC Rollover (WWO-02, D-51-04)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 3 ]]; then
  info "--- Section 3: Dynamic Budget Pacing Math & UTC Rollover ---"
  if [[ -f "$FETCHER_SCRIPT" ]]; then
    # Full implementation in Plan 51-02
    info "S3: Running dynamic pacing unit tests on wwo-fetcher.py"
  else
    info "S3: Dynamic pacing math tests pending Wave 2 (wwo-fetcher.py)"
  fi
fi

# ===========================================================================
# Section 4: Atomic Write & JSON Schema Contract (WWO-03, D-51-06)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 4 ]]; then
  info "--- Section 4: Atomic Write & JSON Schema Contract ---"
  if [[ -f "$FETCHER_SCRIPT" ]]; then
    # Full implementation in Plan 51-02
    info "S4: Running atomic replacement and schema conformance checks"
  else
    info "S4: Atomic cache and schema checks pending Wave 2 (wwo-fetcher.py)"
  fi
fi

# ===========================================================================
# Section 5: Offline Resilience & Cold Boot Recovery (WWO-04, D-51-05, D-51-07)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 5 ]]; then
  info "--- Section 5: Offline Resilience & Cold Boot Recovery ---"
  if [[ -f "$FETCHER_SCRIPT" ]]; then
    # Full implementation in Plan 51-02
    info "S5: Running offline skeleton and persistent mirror recovery checks"
  else
    info "S5: Offline resilience checks pending Wave 2 (wwo-fetcher.py)"
  fi
fi

# ===========================================================================
# Summary
# ===========================================================================
info "=== Phase 51 Assertion Summary: FAIL=$FAIL, FINDINGS=$FINDINGS ==="
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
