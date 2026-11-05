# Testing Patterns

**Analysis Date:** 2026-11-05

This repository enforces quality and correctness through **custom fail-closed assertion harnesses**, headless Neovim probe suites, and sandboxed JavaScript VM evaluation. There are no generic third-party test runners (e.g. Jest, Pytest, Bats); all verification runs via deterministic bash/python scripts in `scripts/`.

## Test Framework

**Runner:**
- Custom Bash assertion suites in `scripts/phase*-assert.sh` (53 dedicated phase harnesses).
- Headless Node.js VM sandbox (`vm.runInNewContext`) for QML Canvas drawing math.
- Headless Neovim test harness in `scripts/nvim-validate.sh` (`nvim --headless`).
- Submodule & symlink integrity gate in `arch/dots-hyprland.sh verify --strict`.

**Assertion Library:**
- Bash: Built-in `pass()`, `fail()`, `finding()`, and `info()` primitives with fail-closed exit codes.
- TAP Output: Emits Test Anything Protocol (TAP version 13) when executed with `--tap`.
- Python: Standard library `assert` and `AssertionError`.

**Run Commands:**
```bash
# Execute latest weather subsystem assertions (Sections 1-5)
./scripts/phase54.4-weather-assert.sh

# Run specific section only (e.g. Section 2: Popup sizing and placement math)
./scripts/phase54.4-weather-assert.sh --section 2

# Run assertions in TAP 13 format
./scripts/phase54.4-weather-assert.sh --tap

# Run performance and optimization assertion suite
./scripts/phase50-opt-assert.sh

# Strict repository verification (no broken symlinks, clean vendor tree)
./arch/dots-hyprland.sh verify --strict

# Headless Neovim validation suite (startup, sync, health, keymaps, formatters)
./scripts/nvim-validate.sh all

# Neovim plugin failure audit
./scripts/nvim-audit-failures.sh

# Run Quickshell resource profiler (CPU, context switches, GPU boosts)
./scripts/profile-quickshell.sh
```

## Test File Organization

**Location:**
- Harness scripts: `scripts/`
- Mock JSON fixtures: `tests/fixtures/weather/`
- Temporary test run outputs: `.planning/tmp/`

**Naming:**
- Assertion scripts: `scripts/phase<phase_number>-<topic>-assert.sh`
- Fixture files: `tests/fixtures/<domain>/<scenario>.json`

**Structure of a Standard Multi-Section Assertion Suite:**
```text
scripts/phase54.4-weather-assert.sh
├── Section 1: Static layout, deploy topology, and repository integrity
├── Section 2: Popup sizing and placement math
├── Section 3: Palette, contrast, and theme bindings
├── Section 4: Axis labels, gradient stops, and scales
└── Section 5: Canvas draw functions against a recording mock canvas
```

## Test Structure

**Standard Assertion Harness Implementation Pattern:**
```bash
#!/usr/bin/env bash
set -euo pipefail

# Fail closed if run as root
if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
  echo "Error: Do not run as root" >&2
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$REPO_ROOT"

FAIL=0
TESTS=0
TAP_MODE=0

pass() {
  TESTS=$((TESTS + 1))
  if [[ "$TAP_MODE" -eq 1 ]]; then
    printf 'ok %d - %s\n' "$TESTS" "$1"
  else
    printf '[PASS] %s\n' "$1"
  fi
}

fail() {
  TESTS=$((TESTS + 1))
  FAIL=$((FAIL + 1))
  if [[ "$TAP_MODE" -eq 1 ]]; then
    printf 'not ok %d - %s\n' "$TESTS" "$1"
  else
    printf '[FAIL] %s\n' "$1"
  fi
}

# Example assertion: AST and regex invariant verification
if grep -q "pragma ComponentBehavior: Bound" restow/quickshell/.config/quickshell/ii/services/Weather.qml; then
  pass "Weather.qml specifies bound component behavior"
else
  fail "Weather.qml missing Bound pragma"
fi

exit "$FAIL"
```

**Setup & Teardown Patterns:**
```bash
# Temporary directory management with guaranteed EXIT trap
TMP_DIRS=()
cleanup() {
  for d in "${TMP_DIRS[@]}"; do
    rm -rf "$d" 2>/dev/null || true
  done
}
trap cleanup EXIT

TEST_DIR="$(mktemp -d /tmp/test-assert-XXXXXX)"
TMP_DIRS+=("$TEST_DIR")
```

## Mocking

**Headless Canvas 2D Mocking in Node.js:**
- Pure math functions in `WeatherGraphMath.js` (e.g. bezier curve fitting, canvas path creation) are evaluated without a running display server by injecting a recording mock context:
```javascript
const vm = require('vm');
const fs = require('fs');

const code = fs.readFileSync('restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherGraphMath.js', 'utf8');

const recordedCalls = [];
const mockContext = {
    beginPath: () => recordedCalls.push('beginPath'),
    moveTo: (x, y) => recordedCalls.push(`moveTo(${x},${y})`),
    bezierCurveTo: (cp1x, cp1y, cp2x, cp2y, x, y) => recordedCalls.push(`bezierCurveTo(...)`),
    stroke: () => recordedCalls.push('stroke'),
    createLinearGradient: () => ({ addColorStop: () => {} }),
};

const sandbox = { console, Math };
vm.createContext(sandbox);
vm.runInContext(code, sandbox);
// Assert that math functions correctly call mock context methods
```

**Static JSON Fixture Mocking:**
- `tests/fixtures/weather/nominal.json`: Standard 3-day forecast with hourly data.
- `tests/fixtures/weather/severe_alerts.json`: Payloads containing extreme weather warnings to verify alert banner rendering.
- `tests/fixtures/weather/sparse_offline.json`: Minimal payloads verifying cold-boot fallback resilience.

**What to Mock:**
- Wayland display server and Qt Quick scenegraph during headless testing.
- HTML5 Canvas 2D rendering context.
- External WWO API network responses.

**What NOT to Mock:**
- Physical filesystem paths and real symlink targets.
- Pacman and Git command return statuses during verification runs.
- `collision-map.tsv` and `guard-paths.tsv` files.

## Coverage & Quality Gates

**Coverage Philosophy:**
- 100% invariant requirement traceability. Each milestone phase defines formal requirement IDs (e.g. `POPUP-01`, `WWO-02`, `OPT-03`) that are directly mapped to assert functions in `scripts/phase*-assert.sh`.
- Code changes must never regress previous phase assertions.

**Pre-Commit Verification Checklist:**
1. Execute phase-specific test harness: `./scripts/phase<N>-*-assert.sh`
2. Run strict repository verification: `./arch/dots-hyprland.sh verify --strict`
3. Verify zero dirty submodule drift: `git submodule status`
4. Run secret scan: `.gitleaks.toml` patterns

## Test Types

**1. Static Invariant Tests:**
- Inspects source files using strict regex/grep to verify architectural rules (e.g. no subshell spawns in QML timers, non-root checks in bash scripts, Bound component pragmas).

**2. Sandboxed Logic Tests:**
- Evaluates JavaScript and Python algorithms (bezier math, pacing intervals, date rollovers) in headless isolation.

**3. Integration & Deployment Tests:**
- Validates that GNU Stow correctly creates leaf symlinks without folding, tests that `collision-map.tsv` is in sync with installer primitives, and tests that wrapper allowlists reject unauthorized flags.

**4. Performance Benchmark Tests:**
- Run via `scripts/profile-quickshell.sh`:
  - Captures baseline idle CPU consumption over 60 seconds (must remain <= 1.70%).
  - Counts context switches per second using `perf stat` or `/proc/stat` (target <= 75/s).
  - Checks GPU boost clock behavior (ensures telemetry pills do not trigger high-power dGPU/iGPU clocks).

---

*Testing analysis: 2026-11-05*
