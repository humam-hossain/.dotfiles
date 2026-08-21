# Testing Patterns

**Analysis Date:** 2026-08-21

This repo has **no unit-test framework** (no Jest, pytest, Bats, or CI test job). Verification is **assert/smoke scripts** plus Neovim headless harnesses. Do not add a JS/Python test runner unless a phase explicitly requires it. Do not treat `vendor/dots-hyprland` testers as first-party.

## Test Framework

**Runner:**
- Custom bash/Python scripts under `scripts/`
- Neovim `--headless` via `scripts/nvim-validate.sh`
- Config: none (`jest.config.*` / `vitest.config.*` / `pytest.ini` Not detected)

**Assertion Library:**
- Bash: `pass` / `fail` / `soft` helpers + `grep` / `test` / `bash -n`
- Python: `assert` + `AssertionError` / `KeyError` in `scripts/phase0{2,3,4}-*.py`

**Run Commands:**
```bash
# Phase / wrapper policy (from REPO_ROOT)
./scripts/phase02-config-assert.py
./scripts/phase03-config-assert.py
./scripts/phase04-ipc-reload-assert.py
./scripts/phase07-live-smoke.sh
./scripts/phase10-inventory-assert.sh
./scripts/phase10-inventory-assert.sh --full
./scripts/phase11-dispositions-assert.sh
./scripts/phase12-full-smoke.sh

# Neovim
./scripts/nvim-validate.sh startup
./scripts/nvim-validate.sh all
./scripts/nvim-audit-failures.sh

# Wrapper dry-run (non-mutating)
./arch/dots-hyprland.sh help
./arch/dots-hyprland.sh install --dry-run
printf 'yes\n' | ./arch/dots-hyprland.sh install --full --dry-run
./arch/dots-hyprland.sh uninstall --dry-run
```

## Test File Organization

**Location:**
- All first-party checks in `scripts/` (not co-located with `arch/` or `stow/`).
- Reports: `.planning/tmp/nvim-validate/` (startup.log, health.json, keymap-regression.log, format-regression.log).
- Planning inventories grepped by asserts: `.planning/phases/10-full-install-impact-inventory/10-INVENTORY.md`.

**Naming:**
- `phaseNN-<slug>-assert.py|sh` — Wave 0 structural/live config
- `phaseNN-*-smoke.sh` — non-mutating or live-policy smoke
- `nvim-validate.sh` / `nvim-audit-failures.sh` — editor harness

**Structure:**
```
scripts/
├── phase02-config-assert.py      # live ~/.config/illogical-impulse/config.json
├── phase03-config-assert.py
├── phase04-ipc-reload-assert.py  # QML + qs ipc
├── phase07-live-smoke.sh         # dual-run + wrapper policy
├── phase10-inventory-assert.sh   # markdown structure + optional host checklist
├── phase11-dispositions-assert.sh
├── phase12-full-smoke.sh         # --full flag / dry-run argv
├── nvim-validate.sh
├── nvim-audit-failures.sh
└── clone_repo.sh                 # not a test
```

## Test Structure

**Suite Organization:**
```bash
# Pattern from scripts/phase12-full-smoke.sh
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"
FAIL=0
pass() { printf '[PASS] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }

if bash -n arch/dots-hyprland.sh; then
  pass "syntax: bash -n arch/dots-hyprland.sh"
else
  fail "syntax: bash -n arch/dots-hyprland.sh"
fi
# ... more checks ...
exit "$FAIL"
```

Python pattern (`scripts/phase02-config-assert.py`):
```python
def main() -> int:
    if not CONFIG_PATH.is_file():
        print(f"error: missing config file: {CONFIG_PATH}", file=sys.stderr)
        return 1
    try:
        config = json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
        assert workspaces["shown"] == 4, f"bar.workspaces.shown=... want 4"
    except KeyError as exc:
        print(f"config assert FAIL: missing key {exc}", file=sys.stderr)
        return 1
    except AssertionError as exc:
        print(f"config assert FAIL: {exc}", file=sys.stderr)
        return 1
    print("config asserts OK")
    return 0
```

**Patterns:**
- Setup: resolve `REPO_ROOT`, `cd` there, `mktemp` for command capture, `trap` cleanup.
- Teardown: `trap 'rm -f "$HELP_OUT" ...' EXIT`.
- Assertion: labeled IDs (`LIVE-01`, `FULL-01`, `D-04`, `D-13`) matching planning decisions.
- Host-state branching: if `~/.config/quickshell/ii/shell.qml` missing, LIVE asserts become `[SOFT]` (`scripts/phase07-live-smoke.sh`).

## Mocking

**Framework:** Not detected.

**Patterns:**
```bash
# Drive interactive gates without mutating the machine
printf 'yes\n' | ./arch/dots-hyprland.sh install --dry-run
# Capture argv; grep for residual flags
"$WRAP" install --full --dry-run >"$FULL_OUT" 2>&1
grep -q -- '--skip-hyprland' "$FULL_OUT" && fail "leaked --skip-hyprland"
```

**What to Mock:**
- Do not mock pacman/yay. Use `--dry-run` and refuse live `install --full` in smoke scripts.
- Phase 10 `--full` is **read-only** `test -e` host checklist, not a mock.

**What NOT to Mock:**
- Live JSON/QML when the assert is explicitly a live gate (`phase02`, `phase04`).
- Neovim plugins: load real modules via `pcall(require, ...)` in `nvim-validate.sh smoke`.

## Fixtures and Factories

**Test Data:**
```python
# phase04 still names in-tree QML as fixture — those files are not in the repo
REPO_ROOT = Path(__file__).resolve().parent.parent
BAR_QML = REPO_ROOT / ".config" / "quickshell" / "modules" / "ii" / "bar" / "Bar.qml"
PROBE_MARKER = "// phase04-ipc-reload-assert-probe"
```

**Location:**
- Expected keys live in the assert source, not YAML fixtures.
- Inventories under `.planning/phases/` are the documents under test for phase 10/11.
- **Broken in-tree fixtures (verified 2026-08-21):**
  - `scripts/phase04-ipc-reload-assert.py` → `.config/quickshell/...` **missing** (retired product; live tree is `~/.config/quickshell`)
  - `scripts/nvim-validate.sh` → `$REPO_ROOT/.config/nvim/init.lua` **missing** (SoT is `stow/nvim/.config/nvim/init.lua`)

## Coverage

**Requirements:** None enforced (no coverage tool).

**View Coverage:**
```bash
# Not applicable. Treat PASS/FAIL labels as the report.
./scripts/phase12-full-smoke.sh
./scripts/nvim-validate.sh health   # writes .planning/tmp/nvim-validate/health.json
```

## Test Types

**Unit Tests:**
- Not used. Closest: `bash -n` syntax, grep of help text, JSON key asserts.

**Integration Tests:**
- `scripts/phase04-ipc-reload-assert.py` — `qs list` / `qs ipc` against a running shell; soft-reload PID probe.
- `scripts/phase07-live-smoke.sh` — XDG trees, dual-run waybar vs ii, wrapper uninstall policy.
- `scripts/nvim-validate.sh` — headless nvim against `$REPO_ROOT/.config/nvim` (`-u` / `rtp^=`). That path **does not exist**; SoT is `stow/nvim/.config/nvim`. Align `-u` to the stow tree or the harness cannot start.

**E2E Tests:**
- Manual operator playbook `docs/dots-hyprland-workflow.md`.
- Phase smokes **must not** run live `install --full` (`scripts/phase12-full-smoke.sh` header).

## Common Patterns

**Async Testing:**
```bash
# nvim-validate startup uses lua defer then qa
nvim --headless -u "$REPO_ROOT/.config/nvim/init.lua" \
  --cmd "set rtp^=$REPO_ROOT/.config/nvim" \
  +"lua vim.defer_fn(function() vim.cmd('qa!') end, 50)"
# Lazy sync: timeout 120; rc 124 = FAIL
```

**Error Testing:**
```bash
# Unknown CLI args must fail
./scripts/phase10-inventory-assert.sh --nope  # expect [FAIL] unknown arg
# nvim-validate fails on Error|E5108|E484|stack traceback in logs
# health: FAIL if plugin loaded=false or required tool missing; WARN optional tools
```

**Soft vs hard:**
- Hard fail → increment `FAIL`, script exits non-zero.
- Soft → print `[SOFT]`, do not fail the suite (expected after uninstall).

**Safety constraints for new tests:**
- Never `rsync`/`cp`/`mv`/`rm` into XDG from inventory asserts (`scripts/phase10-inventory-assert.sh`).
- Never call `./setup` or `arch/dots-hyprland.sh` without `--dry-run` unless the phase is explicitly a live install.
- Do not invoke upstream `./setup uninstall`.

**Adding a new check:**
1. Put it in `scripts/phaseNN-*.sh|py` matching the planning phase.
2. Label with the decision/ID from the plan (`D-xx`, `LIVE-xx`, `FULL-xx`).
3. Use `[PASS]`/`[FAIL]`; keep stdlib-only Python.
4. Document mutation (none vs live) in the file header.

---

*Testing analysis: 2026-08-21*
