# Coding Conventions

**Analysis Date:** 2026-11-05

## Naming Patterns

**Files:**
- Arch installer scripts: `arch/<tool_name>.sh` — lowercase, snake_case for multi-word tools (e.g. `google_chrome.sh`, `system_monitor.sh`, `dots-hyprland.sh`).
- Test assertion harnesses: `scripts/phase<phase_number>-<topic>-assert.sh` or `.py` (e.g. `phase54.4-weather-assert.sh`, `phase50-opt-assert.sh`, `phase04-ipc-reload-assert.py`).
- QML components: `PascalCase.qml` (e.g. `WeatherPopup.qml`, `WeatherGraph.qml`, `CpuGpuPill.qml`, `BarContent.qml`).
- JavaScript utility modules: `PascalCase.js` (e.g. `WeatherGraphMath.js`).
- Standalone Python daemons: `kebab-case.py` (e.g. `wwo-fetcher.py`).
- Embedded Python utilities: `snake_case.py` (e.g. `process_tree.py`, `scroll_mark.py`).
- Neovim Lua modules: kebab-case or dot-separated under `stow/nvim/.config/nvim/lua/` (e.g. `lua/plugins/lsp.lua`, `lua/core/keymaps.lua`).
- Issue investigations: `issues/YYYY-MM-DD_<topic-description>.md`.

**Functions:**
- Bash functions: `snake_case` (e.g. `pass`, `fail`, `finding`, `cleanup`, `usage`, `cleanup_old_logs`, `safe_rm_path`).
- Python functions: `snake_case` with explicit type annotations (e.g. `def get_runtime_dir() -> str:`, `def compute_interval_minutes(...) -> float:`).
- JavaScript / QML methods: `camelCase` (e.g. `computeBezierControlPoints`, `drawHorizontalGrid`, `formatMetricValue`).
- Lua functions: `snake_case` on module table exports (`function M.setup()`, `function M.format()`).

**Variables:**
- Bash constants & paths: `SCREAMING_SNAKE_CASE` (e.g. `REPO_ROOT`, `II_ROOT`, `XDG_CONFIG_HOME`, `FAIL`, `FINDINGS`, `TESTS`).
- Bash local variables: `snake_case` (e.g. `local count`, `local temp_file`, `local exit_code`).
- Python constants: `SCREAMING_SNAKE_CASE` (e.g. `DAILY_BUDGET = 470`, `ABSOLUTE_CEILING = 500`, `MIN_INTERVAL_MINUTES = 3.0`).
- Python locals: `snake_case`.
- QML property declarations: `camelCase` (e.g. `property bool isStale: true`, `readonly property string runtimeCachePath: ...`).

**Types & Interfaces:**
- Python: Uses standard library typing primitives (`Optional[str]`, `dict[str, Any]`, `tuple[float, float]`).
- QML: Uses standard QtQuick types (`int`, `real`, `string`, `bool`, `var`, `color`).

## Code Style

**Formatting & Indentation:**
- **Bash:** 2-space indentation standard. Tabs are prohibited except inside heredocs that strip tabs (`<<-EOF`).
- **Python:** 4-space indentation following PEP 8.
- **QML:** 4-space indentation standard. Braces follow 1TBS (One True Brace Style) on the same line.
- **Lua:** 2-space or 4-space indentation enforced by `stylua` configured in Neovim `conform.nvim`.

**Shell Safety Invariants (Mandatory):**
- All Bash scripts MUST start with:
  ```bash
  #!/usr/bin/env bash
  set -euo pipefail
  ```
- Physical path resolution (resolving all symlinks):
  ```bash
  REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
  ```
  `pwd -P` is mandatory to guarantee comparison against canonical filesystem paths.
- Non-root privilege gate:
  ```bash
  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    echo "Error: Do not run as root" >&2
    exit 1
  fi
  ```
- No `eval`. Arguments must be passed using typed Bash arrays:
  ```bash
  CMD=("$BIN" "${ARGS[@]}")
  "${CMD[@]}"
  ```
- Temp file handling: Always use `mktemp` and register created paths in an array cleared by `trap cleanup EXIT`.

**GNU Stow Invariants (Mandatory):**
- When linking packages, always specify `--verbose=5` and `--no-folding`:
  ```bash
  stow --verbose=5 --no-folding -t ~ <package-name>
  ```
- The `--adopt` flag is **strictly banned** from all automated scripts and phase assertions.

**QML Architecture Invariants (Mandatory):**
- Top of every service file:
  ```qml
  pragma Singleton
  pragma ComponentBehavior: Bound
  ```
- Root object identification: Always use `id: root`.
- Subprocess ban in polling loops: Never use `Quickshell.Io.Process` inside periodic timers. Telemetry must be read from tmpfs files via `Quickshell.Io.FileView` or direct `/proc` file streams.
- Safe cold-boot property initialization: All reactive telemetry objects must provide non-null default state dictionaries:
  ```qml
  property var current: ({
      tempC: "--",
      tempFeelsLikeC: "--",
      desc: "Offline",
      glyph: "cloud_off"
  })
  ```

## Import Organization

**QML Modules:**
1. Core QtQuick imports (`import QtQuick`, `import QtQuick.Layouts`)
2. Quickshell engine imports (`import Quickshell`, `import Quickshell.Io`)
3. Project common modules (`import qs.modules.common`, `import qs.modules.common.widgets`)
4. Project service singletons (`import qs.services`)
5. Local JavaScript math libraries (`import "WeatherGraphMath.js" as GraphMath`)

**Python Modules:**
1. Standard library imports in alphabetical order (`import argparse`, `import json`, `import os`, `import sys`, `import urllib.request`)
2. `from datetime import datetime, timezone, timedelta`
3. Third-party dependencies: strictly banned for background system daemons (pure Python standard library only).

## Error Handling

**Bash Scripts:**
- Immediate termination on unset variables and command failures via `set -euo pipefail`.
- Exit code semantics: Harnesses track `FAIL` counter and exit with `0` on total pass or non-zero status on failures:
  ```bash
  pass() { printf '[PASS] %s\n' "$1"; }
  fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
  exit "$FAIL"
  ```

**Python Daemons:**
- Wrap network operations in specific exception blocks (`urllib.error.HTTPError`, `urllib.error.URLError`, `TimeoutError`).
- Offline fallback: If network retrieval fails, load the persistent mirror file from `$XDG_STATE_HOME/weather/last_known_weather.json`, mark `is_stale: true`, and write the fallback payload to tmpfs.
- Atomic file write: Never write directly to the target cache file. Write to a temporary file (`.weather.tmp.*`) and invoke `os.replace` to prevent partial reads by the UI.

**QML Singletons:**
- Wrap JSON parsing operations in `try / catch`:
  ```javascript
  try {
      const parsed = JSON.parse(rawText);
      root.current = parsed.current;
      root.isOffline = false;
  } catch (e) {
      root.isOffline = true;
  }
  ```

## Logging

**Deployment & System Bootstrapping:**
- Dual-stream console and transcript logging in `bootstrap.sh`:
  ```bash
  LOG_FILE="$LOG_DIR/bootstrap-$(date +"%Y%m%d_%H%M%S_$$").log"
  exec 3>&1 4>&2
  exec > >(tee -a "$LOG_FILE") 2>&1
  trap cleanup_logging EXIT
  ```
- Automated FIFO log rotation retaining the 5 most recent transcripts.

**Test Assertions:**
- Supports both standard human-readable `[PASS]` / `[FAIL]` tags and TAP version 13 (`--tap` flag) for CI/CD ingestion:
  ```bash
  printf 'ok %d - %s\n' "$TESTS" "$description"
  ```

## Comments

**Header Blocks:**
- All major scripts and assertion suites must include a comprehensive ASCII header detailing purpose, enforced requirements, and usage flags.

**In-Line Decisions Reference:**
- Reference specific GSD decisions in code comments using the format `(D-<phase>-<id>)` (e.g. `// Cache Paths (D-52-03)`, `# Dynamic pacing math (D-51-01)`).

---

*Convention analysis: 2026-11-05*
