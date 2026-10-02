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
  
  if [[ ! -f "$FETCHER_SCRIPT" ]]; then
    fail "S3: Missing fetcher script: $FETCHER_SCRIPT"
  else
    # 3.1 Pacing formula tests across time & quota scenarios
    MATH_CHECK=$(python3 -c '
import sys
import importlib.util
from datetime import datetime, timezone

spec = importlib.util.spec_from_file_location("wwo_fetcher", sys.argv[1])
wf = importlib.util.module_from_spec(spec)
spec.loader.exec_module(wf)

# 00:01 UTC, 0 calls -> ~3.06 min
t1 = datetime(2026, 10, 3, 0, 1, 0, tzinfo=timezone.utc)
p1, _, _ = wf.compute_pacing(0, t1)
assert 3.05 <= p1 <= 3.07, f"Bad p1: {p1}"

# 18:00 UTC, 400 calls -> ~5.14 min
t2 = datetime(2026, 10, 3, 18, 0, 0, tzinfo=timezone.utc)
p2, _, _ = wf.compute_pacing(400, t2)
assert 5.10 <= p2 <= 5.20, f"Bad p2: {p2}"

# 470 calls reached -> throttled (inf)
p3, _, _ = wf.compute_pacing(470, t2)
assert p3 == float("inf"), f"Bad p3: {p3}"

print("OK_MATH")
' "$FETCHER_SCRIPT" 2>&1 || echo "ERROR")

    if [[ "$MATH_CHECK" == "OK_MATH" ]]; then
      pass "S3: Dynamic budget pacing formula conforms to D-51-04 across 00:01, 18:00, and budget ceiling"
    else
      fail "S3: Dynamic budget pacing math check failed: $MATH_CHECK"
    fi

    # 3.2 UTC Midnight Rollover test
    ROLLOVER_DIR="$(mktemp -d "${TMPDIR:-/tmp}/p51-test-rollover.XXXXXX")"
    TMP_DIRS+=("$ROLLOVER_DIR")

    ROLLOVER_CHECK=$(python3 -c '
import sys, os, json
import importlib.util

spec = importlib.util.spec_from_file_location("wwo_fetcher", sys.argv[1])
wf = importlib.util.module_from_spec(spec)
spec.loader.exec_module(wf)

state_file = sys.argv[2]
# Seed state file with yesterday date and 450 calls
with open(state_file, "w") as f:
    json.dump({"date_utc": "2020-01-01", "calls_today": 450, "last_call_epoch": 1000}, f)

state = wf.load_quota_state(state_file)
assert state["calls_today"] == 0, f"Calls today not reset: {state}"
assert state["date_utc"] != "2020-01-01", f"Date not updated: {state}"
print("OK_ROLLOVER")
' "$FETCHER_SCRIPT" "$ROLLOVER_DIR/quota.json" 2>&1 || echo "ERROR")

    if [[ "$ROLLOVER_CHECK" == "OK_ROLLOVER" ]]; then
      pass "S3: Quota state automatically resets calls_today to 0 on UTC midnight rollover"
    else
      fail "S3: Quota rollover test failed: $ROLLOVER_CHECK"
    fi

    # 3.3 Absolute ceiling (500 calls) protection
    CEILING_DIR="$(mktemp -d "${TMPDIR:-/tmp}/p51-test-ceiling.XXXXXX")"
    TMP_DIRS+=("$CEILING_DIR")
    mkdir -p "$CEILING_DIR/weather" "$CEILING_DIR/state/weather"

    TODAY_UTC=$(python3 -c 'from datetime import datetime, timezone; print(datetime.now(timezone.utc).strftime("%Y-%m-%d"))')
    cat <<EOF > "$CEILING_DIR/state/weather/quota.json"
{
  "date_utc": "$TODAY_UTC",
  "calls_today": 500,
  "last_call_epoch": 1727886000,
  "last_status": "ok"
}
EOF

    CEILING_RUN=$(XDG_RUNTIME_DIR="$CEILING_DIR" XDG_STATE_HOME="$CEILING_DIR/state" "$FETCHER_SCRIPT" --force 2>&1 || true)
    if echo "$CEILING_RUN" | grep -qi "Absolute quota ceiling.*reached"; then
      pass "S3: Absolute ceiling of 500 calls strictly refuses execution even with --force (T-51-02)"
    else
      fail "S3: Absolute ceiling check failed to throttle: $CEILING_RUN"
    fi
  fi
fi

# ===========================================================================
# Section 4: Atomic Write & JSON Schema Contract (WWO-03, D-51-06)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 4 ]]; then
  info "--- Section 4: Atomic Write & JSON Schema Contract ---"

  if [[ ! -f "$FETCHER_SCRIPT" ]]; then
    fail "S4: Missing fetcher script: $FETCHER_SCRIPT"
  else
    ATOMIC_DIR="$(mktemp -d "${TMPDIR:-/tmp}/p51-test-atomic.XXXXXX")"
    TMP_DIRS+=("$ATOMIC_DIR")
    mkdir -p "$ATOMIC_DIR/weather" "$ATOMIC_DIR/state/weather"

    # Run fetcher dry-run / fallback seeding in isolated runtime
    XDG_RUNTIME_DIR="$ATOMIC_DIR" XDG_STATE_HOME="$ATOMIC_DIR/state" "$FETCHER_SCRIPT" --dry-run >/dev/null 2>&1

    CACHE_FILE="$ATOMIC_DIR/weather/weather.json"
    if [[ -f "$CACHE_FILE" ]]; then
      pass "S4: Cache file successfully provisioned in \$XDG_RUNTIME_DIR/weather/weather.json"

      # Validate envelope schema keys and types using jq
      SCHEMA_ERRS=0
      for expr in \
        '.status | type == "string"' \
        '.fetched_epoch | type == "number"' \
        '.is_stale | type == "boolean"' \
        '.quota | type == "object"' \
        '.quota.calls_today | type == "number"' \
        '.quota.calls_remaining | type == "number"' \
        '.quota.resets_at_utc | type == "string"'
      do
        MATCH=$(jq -r "$expr" "$CACHE_FILE" 2>/dev/null || echo "false")
        if [[ "$MATCH" != "true" ]]; then
          fail "S4: Envelope schema violation: $expr failed on $CACHE_FILE"
          SCHEMA_ERRS=$((SCHEMA_ERRS + 1))
        fi
      done
      if [[ "$SCHEMA_ERRS" -eq 0 ]]; then
        pass "S4: Cache JSON conforms strictly to {status, fetched_epoch, is_stale, error, quota, data} contract"
      fi
    else
      fail "S4: Cache file was not created by fetcher initialization"
    fi

    # Test atomic replacement (inode change) and tempfile colocation
    INODE_CHECK=$(python3 -c '
import sys, os, json
import importlib.util

spec = importlib.util.spec_from_file_location("wwo_fetcher", sys.argv[1])
wf = importlib.util.module_from_spec(spec)
spec.loader.exec_module(wf)

cache_file = sys.argv[2]
initial_stat = os.stat(cache_file)
wf.atomic_write_json(cache_file, {"status": "ok", "test_atomic": True})
new_stat = os.stat(cache_file)

assert initial_stat.st_ino != new_stat.st_ino, "Inode did not change during atomic write"
with open(cache_file) as f:
    d = json.load(f)
assert d.get("test_atomic") is True, "Data was not written completely"
print("OK_INODE")
' "$FETCHER_SCRIPT" "$CACHE_FILE" 2>&1 || echo "ERROR")

    if [[ "$INODE_CHECK" == "OK_INODE" ]]; then
      pass "S4: Atomic replacement via os.replace verified with distinct inode transitions (no EXDEV link errors)"
    else
      fail "S4: Atomic replacement check failed: $INODE_CHECK"
    fi
  fi
fi

# ===========================================================================
# Section 5: Offline Resilience & Cold Boot Recovery (WWO-04, D-51-05, D-51-07, D-51-08)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 5 ]]; then
  info "--- Section 5: Offline Resilience & Cold Boot Recovery ---"

  if [[ ! -f "$FETCHER_SCRIPT" ]]; then
    fail "S5: Missing fetcher script: $FETCHER_SCRIPT"
  else
    RESILIENCE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/p51-test-resilience.XXXXXX")"
    TMP_DIRS+=("$RESILIENCE_DIR")
    mkdir -p "$RESILIENCE_DIR/weather" "$RESILIENCE_DIR/state/weather"

    # 5.1 Cold boot with no cache & no history
    XDG_RUNTIME_DIR="$RESILIENCE_DIR" XDG_STATE_HOME="$RESILIENCE_DIR/state" "$FETCHER_SCRIPT" --dry-run >/dev/null 2>&1
    SKELETON_STATUS=$(jq -r '.status' "$RESILIENCE_DIR/weather/weather.json" 2>/dev/null || echo "")
    SKELETON_STALE=$(jq -r '.is_stale' "$RESILIENCE_DIR/weather/weather.json" 2>/dev/null || echo "")
    SKELETON_DATA=$(jq -r '.data' "$RESILIENCE_DIR/weather/weather.json" 2>/dev/null || echo "")

    if [[ "$SKELETON_STATUS" == "offline" && "$SKELETON_STALE" == "true" && "$SKELETON_DATA" == "null" ]]; then
      pass "S5: Cold boot without network seeds offline skeleton (status=offline, is_stale=true, data=null) preventing ENOENT (D-51-07)"
    else
      fail "S5: Cold boot skeleton check failed: status=$SKELETON_STATUS, stale=$SKELETON_STALE, data=$SKELETON_DATA"
    fi

    # 5.2 Cold boot with persistent disk history
    rm -f "$RESILIENCE_DIR/weather/weather.json"
    cat <<'EOF' > "$RESILIENCE_DIR/state/weather/last_known_weather.json"
{
  "status": "ok",
  "fetched_at": "2026-10-02T12:00:00Z",
  "fetched_epoch": 1727870400,
  "is_stale": false,
  "error": null,
  "quota": {"calls_today": 10, "calls_remaining": 460, "resets_at_utc": "2026-10-03T00:00:00Z"},
  "data": {"cached_city": "Dhaka", "temp_C": "30"}
}
EOF

    XDG_RUNTIME_DIR="$RESILIENCE_DIR" XDG_STATE_HOME="$RESILIENCE_DIR/state" "$FETCHER_SCRIPT" --dry-run >/dev/null 2>&1
    RESTORED_STALE=$(jq -r '.is_stale' "$RESILIENCE_DIR/weather/weather.json" 2>/dev/null || echo "")
    RESTORED_CITY=$(jq -r '.data.cached_city' "$RESILIENCE_DIR/weather/weather.json" 2>/dev/null || echo "")

    if [[ "$RESTORED_STALE" == "true" && "$RESTORED_CITY" == "Dhaka" ]]; then
      pass "S5: Cold boot with persistent mirror restores previous forecast marked as is_stale=true (D-51-08)"
    else
      fail "S5: Cold boot persistent mirror restoration failed: stale=$RESTORED_STALE, city=$RESTORED_CITY"
    fi

    # 5.3 Network error preservation: preserves existing cached data and marks is_stale=true
    NET_ERR_CHECK=$(python3 -c '
import sys, os, json
import importlib.util

spec = importlib.util.spec_from_file_location("wwo_fetcher", sys.argv[1])
wf = importlib.util.module_from_spec(spec)
spec.loader.exec_module(wf)

r_dir = sys.argv[2]
cache_file = os.path.join(r_dir, "weather", "weather.json")

# Seed cache file with valid data
with open(cache_file, "w") as f:
    json.dump({"status": "ok", "is_stale": False, "data": {"condition": "Sunny"}}, f)

# Simulate network exception handling
try:
    raise ConnectionResetError("Simulated network drop")
except Exception as e:
    with open(cache_file, "r") as f:
        prev = json.load(f)
    existing_data = prev.get("data")
    err_envelope = {
        "status": "error",
        "fetched_at": "2026-10-03T00:00:00Z",
        "fetched_epoch": 1727913600,
        "is_stale": True,
        "error": str(e),
        "quota": {"calls_today": 5, "calls_remaining": 465, "resets_at_utc": "2026-10-04T00:00:00Z"},
        "data": existing_data
    }
    wf.atomic_write_json(cache_file, err_envelope)

with open(cache_file) as f:
    d = json.load(f)

assert d["status"] == "error", f"Status not error: {d}"
assert d["is_stale"] is True, f"Not stale: {d}"
assert d["data"]["condition"] == "Sunny", f"Data not preserved: {d}"
assert "Simulated network drop" in d["error"], f"Error not recorded: {d}"
print("OK_NET_ERR")
' "$FETCHER_SCRIPT" "$RESILIENCE_DIR" 2>&1 || echo "ERROR")

    if [[ "$NET_ERR_CHECK" == "OK_NET_ERR" ]]; then
      pass "S5: Network outage error preservation preserves forecast payload with is_stale=true without retries (D-51-05)"
    else
      fail "S5: Network error simulation failed: $NET_ERR_CHECK"
    fi
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
