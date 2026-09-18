# Phase 30: Address Tech Debt: v0.5 Cleanup and Validation Sign-Off — Pattern Map

**Mapped:** 2026-09-18  
**Phase Directory:** `.planning/phases/30-address-tech-debt-v0-5-cleanup-and-validation-sign-off/`  
**Output File:** `30-PATTERNS.md`  
**Files Analyzed:** 10 target files (1 new assert harness, 1 new validation contract, 1 config edit, 1 test script edit, 1 orchestrator edit, 2 live script/template edits, 1 validation contract reconciliation, 2 bookkeeping edits)  
**Analogs Found:** 10 / 10 (all backed by git-tracked source code or existing live scripts in this repository)  

All analog paths below were verified against repository files and the live Linux environment. Historical assert scripts and validation artifacts are cited as structural patterns to copy from, adhering strictly to the **D-20 Frozen History Rule** (historical artifacts from earlier milestones are not modified).

---

## File Classification

| Target File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `restow/kitty/.config/kitty/kitty.conf` (**modify**) | Personal terminal configuration overlay | Read by Kitty at launch or upon `SIGUSR1` reload; symlinked to `~/.config/kitty/kitty.conf` via restow | `restow/kitty/.config/kitty/kitty.conf:1-4` (self-analog) + `vendor/dots-hyprland/dots/.config/kitty/kitty.conf` (upstream reference) | exact self-analog |
| `scripts/phase28-terminal-fuzzel-assert.sh` (**modify**) | Terminal & launcher assert / regression harness | Python probe via `kitty +runpy` against `kitty.conf`; checks loaded options dictionary; asserts float opacity within tolerance | `scripts/phase28-terminal-fuzzel-assert.sh:267-293` (self-analog) | exact self-analog |
| `bootstrap.sh` (**modify**) | Root system installer & bootstrap orchestrator | Environment export, process execution (`switchwall.sh`), stream editing (`sed -i`) on live template/script paths | `bootstrap.sh:603-611` (GTK 4 template sanitization self-analog) + `bootstrap.sh:597-641` (`generate_initial_theme()`) | exact self-analog |
| `~/.config/quickshell/ii/scripts/colors/applycolor.sh` (**modify**) | Dynamic terminal color applier & process signaler | Reads palette tokens, generates `kitty-theme.conf`, emits OS signal `SIGUSR1` to running terminal processes | `~/.config/quickshell/ii/scripts/colors/applycolor.sh:44-49` (self-analog) | exact self-analog |
| `~/.config/matugen/templates/kde/kde-material-you-colors-wrapper.sh` (**modify**) | Live Matugen KDE theme wrapper template | Invoked by `switchwall.sh` after Matugen runs; activates Python virtualenv, executes `kde-material-you-colors`, deactivates virtualenv | `~/.config/matugen/templates/kde/kde-material-you-colors-wrapper.sh:45-49` (self-analog) | exact self-analog |
| `.planning/phases/29-theme-data-contracts-verification-bootstrap-integration/29-VALIDATION.md` (**modify**) | Phase 29 Nyquist validation contract | Machine/human contract inspected by GSD milestone auditor and validation scripts | `.planning/milestones/v0.4-phases/24-address-tech-debt-bookkeeping-and-validation-cleanup/24-PATTERNS.md:681-728` + `.planning/phases/17-unblock-stow-and-restore-the-session-target/17-VALIDATION.md:1-11, 145-182` | exact cross-analog |
| `scripts/phase30-tech-debt-assert.sh` (**new**) | Dedicated Phase 30 test harness & multi-phase regression suite | Static linting, python config probes, shell execution, subagent regression runner, git status porcelain checks | `scripts/phase24-tech-debt-assert.sh:1-405` (5-section architecture, CLI `--section <1-5>`, helpers, trap, porcelain brackets) + `scripts/phase29-theme-data-contracts-assert.sh:400-439` (regression sweep loop) | exact composite |
| `.planning/phases/30-address-tech-debt-v0-5-cleanup-and-validation-sign-off/30-VALIDATION.md` (**new**) | Phase 30 Nyquist validation contract | Contract specifying testing framework, sampling frequency, per-task map, and wave 0 dependencies | `.planning/phases/29-theme-data-contracts-verification-bootstrap-integration/29-VALIDATION.md` + `.planning/milestones/v0.4-phases/24-address-tech-debt-bookkeeping-and-validation-cleanup/24-VALIDATION.md` | exact composite |
| `.planning/REQUIREMENTS.md` (**modify**) | Requirements traceability register | Audited by `/gsd-audit-milestone`; cross-referenced by roadmap and phase summaries | `.planning/REQUIREMENTS.md:6-37, 63-86` (self-analog) + Phase 24 additions in `24-PATTERNS.md:546-581` | exact self-analog |
| `.planning/ROADMAP.md` (**modify**) | Milestone roadmap specification | Read by GSD orchestration tools (`/gsd-progress`, `/gsd-plan-phase`) | `.planning/ROADMAP.md:219-238` (self-analog) + Phase 24 definition in `24-PATTERNS.md:589-617` | exact self-analog |

---

## Pattern Assignments by File

### 1. `restow/kitty/.config/kitty/kitty.conf` (Terminal Emulator Configuration)

**Role:** Personal Kitty configuration overlay managed under `restow/` to preserve user customizations (JetBrains Mono font, window margins, custom keybinds) over upstream defaults without symlink destruction.  
**Analog:** Existing `restow/kitty/.config/kitty/kitty.conf:1-4` (self-analog).  
**Data Flow:** Loaded by Kitty at startup; dynamically re-read upon receipt of `SIGUSR1` without destroying active shell sessions.

#### Pattern 1.1: Opacity Configuration Adjustment
Source: `restow/kitty/.config/kitty/kitty.conf:1-4`, `30-CONTEXT.md:D-01`, `28-UAT.md:34-36`
```conf
# Theming
include ~/.local/state/quickshell/user/generated/terminal/kitty-theme.conf
background_opacity 0.90

# Font
font_family      JetBrains Mono Nerd Font
font_size 11.0
```

#### Key Rules & Invariants:
- **Scope Confinement (D-04):** Strictly modify line 3 (`background_opacity 0.90`). Do NOT alter fonts, margins, window controls, or search kittens.
- **Three-Tree Capture Taxonomy:** The file resides in `restow/kitty/` because upstream installer primitive `install_dir__sync` would overwrite or fold links in `stow/`.
- **Live Reload (D-03):** After editing or deploying, signal running instances via `killall -SIGUSR1 kitty 2>/dev/null || true`.

---

### 2. `scripts/phase28-terminal-fuzzel-assert.sh` (Phase 28 Regression Harness)

**Role:** Dedicated test script validating Phase 28 terminal emulator and Fuzzel launcher configuration, palette tokens, and native configuration parser compliance.  
**Analog:** Existing `scripts/phase28-terminal-fuzzel-assert.sh:267-293` (self-analog).  
**Data Flow:** Invokes `kitty +runpy` to execute embedded Python loading `~/.config/kitty/kitty.conf` into a native Kitty options object and asserts properties.

#### Pattern 2.1: Native Kitty Parser Probe Alignment with Float Tolerance
Source: `scripts/phase28-terminal-fuzzel-assert.sh:267-293`, `30-CONTEXT.md:D-02`, `30-RESEARCH.md:263-291`
```bash
  # Kitty configuration parser probe for opacity 0.90, shell zsh, and margin 21.75
  # Note: Updated from 0.85 to 0.90 per Phase 28 UAT preference and Phase 30 alignment (DEBT-05)
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
```

#### Key Rules & Invariants:
- **Tolerant Float Comparison:** Never use exact string equality for floating point values; `abs(opts.background_opacity - 0.90) > 0.01` guarantees immunity to IEEE 754 precision drift.
- **Traceability Documentation:** An explanatory comment must accompany the edit referencing Phase 28 UAT (`28-UAT.md:34-36`) and Phase 30 alignment (`DEBT-05`).
- **Unified Regression Integrity:** Section 5 of `scripts/phase29-theme-data-contracts-assert.sh` and Section 5 of `scripts/phase30-tech-debt-assert.sh` run this script. Keeping it aligned is essential for zero false positives.

---

### 3. `bootstrap.sh` (Root Bootstrap Orchestrator)

**Role:** End-to-end installer and configurator executing de-stubbing, stow/restow linking, template alignment, and initial theme generation.  
**Analog:** `bootstrap.sh:603-611` (existing GTK 4 template sanitization) and `bootstrap.sh:597-641` (`generate_initial_theme()`).  
**Data Flow:** Exports environment variables into the current subshell, runs idempotent `sed` modifications over target files, and dispatches `switchwall.sh`.

#### Pattern 3.1: Idempotent Sanitization Blocks & Virtualenv Fallback Export
Source: `bootstrap.sh:597-641`, `30-CONTEXT.md:D-05, D-06, D-07`, `30-RESEARCH.md:295-342`
```bash
generate_initial_theme() {
  local target="${1:-$HOME}"
  local switchwall="$target/.config/quickshell/ii/scripts/colors/switchwall.sh"
  local config_file="$target/.config/illogical-impulse/config.json"
  local matugen_gtk4_tpl="$target/.config/matugen/templates/gtk-4.0/gtk.css"
  local kde_wrapper="$target/.config/matugen/templates/kde/kde-material-you-colors-wrapper.sh"
  local applycolor="$target/.config/quickshell/ii/scripts/colors/applycolor.sh"

  # Sanitize GTK 4 template pseudo-class if present (Pitfall 4)
  if [[ -f "$matugen_gtk4_tpl" ]] && grep -q ':insensitive' "$matugen_gtk4_tpl"; then
    if [[ "$DRY_RUN" -eq 1 ]]; then
      echo "[DRY-RUN] Would align GTK 4 template :insensitive -> :disabled"
    else
      sed -i 's/\.boxed-list row:insensitive/\.boxed-list row:disabled/g' "$matugen_gtk4_tpl"
      echo "[FIX] Aligned GTK 4 Matugen template pseudo-class (:disabled)"
    fi
  fi

  # Align KDE wrapper virtualenv fallback (DEBT-06, D-06)
  if [[ -f "$kde_wrapper" ]] && ! grep -Fq '${ILLOGICAL_IMPULSE_VIRTUAL_ENV:-' "$kde_wrapper"; then
    if [[ "$DRY_RUN" -eq 1 ]]; then
      echo "[DRY-RUN] Would add virtualenv fallback to kde-material-you-colors-wrapper.sh"
    else
      sed -i 's|source "$(eval echo \$ILLOGICAL_IMPULSE_VIRTUAL_ENV)/bin/activate"|source "$(eval echo ${ILLOGICAL_IMPULSE_VIRTUAL_ENV:-$XDG_STATE_HOME/quickshell/.venv})/bin/activate"|g' "$kde_wrapper"
      echo "[FIX] Aligned kde-material-you-colors-wrapper.sh virtualenv fallback"
    fi
  fi

  # Harden Kitty process signaling in applycolor.sh (DEBT-06, D-07)
  if [[ -f "$applycolor" ]] && grep -q 'kill -SIGUSR1 \$(pidof kitty)' "$applycolor"; then
    if [[ "$DRY_RUN" -eq 1 ]]; then
      echo "[DRY-RUN] Would align applycolor.sh Kitty process signaling"
    else
      sed -i '/if ! pgrep -f kitty >\/dev\/null; then/,/kill -SIGUSR1 \$(pidof kitty)/c\  killall -SIGUSR1 kitty 2>/dev/null || true' "$applycolor"
      echo "[FIX] Aligned applycolor.sh Kitty process signaling"
    fi
  fi

  # Export virtualenv fallback for non-graphical runs (DEBT-06, D-05)
  export ILLOGICAL_IMPULSE_VIRTUAL_ENV="${ILLOGICAL_IMPULSE_VIRTUAL_ENV:-${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/.venv}"

  if [[ ! -f "$switchwall" ]]; then
    echo "[WARN] switchwall.sh not found at $switchwall; skipping initial theming"
    return 0
  fi
...
```

#### Key Rules & Invariants:
- **Idempotency Guard:** Every sanitization block must test with `grep` before performing `sed -i` so subsequent bootstrap runs do not duplicate or corrupt changes.
- **Dry-Run Mode:** If `"$DRY_RUN" -eq 1`, log the prospective fix without touching the filesystem.
- **Explicit Export:** Must use `export ILLOGICAL_IMPULSE_VIRTUAL_ENV=...` so child subprocesses (`switchwall.sh`, Matugen hooks, Python runners) inherit the variable in raw TTY or SSH sessions.

---

### 4. `~/.config/quickshell/ii/scripts/colors/applycolor.sh` (Terminal Color Applier)

**Role:** Dynamic color generator script executed by Quickshell / Matugen to write terminal palette files and reload terminal emulators.  
**Analog:** Existing `~/.config/quickshell/ii/scripts/colors/applycolor.sh:44-49` (self-analog).  
**Data Flow:** Generates `~/.local/state/quickshell/user/generated/terminal/kitty-theme.conf` and signals live Kitty instances.

#### Pattern 4.1: Atomic POSIX Terminal Signaling
Source: `~/.config/quickshell/ii/scripts/colors/applycolor.sh:44-49`, `30-CONTEXT.md:D-07`, `30-RESEARCH.md:149-159`
```bash
  # Copy template
  mkdir -p "$STATE_DIR"/user/generated/terminal
  cp "$SCRIPT_DIR/terminal/kitty-theme.conf" "$STATE_DIR"/user/generated/terminal/kitty-theme.conf
  # Apply colors
  for i in "${!colorlist[@]}"; do
    sed -i "s/${colorlist[$i]} #/${colorvalues[$i]#\#}/g" "$STATE_DIR"/user/generated/terminal/kitty-theme.conf
  done

  # Reload
  killall -SIGUSR1 kitty 2>/dev/null || true
}
```

#### Key Rules & Invariants:
- **Fail-Soft Semantics:** `killall -SIGUSR1 kitty 2>/dev/null || true` delivers signals safely to running Kitty instances without throwing bash errors or aborting when Kitty is not running.
- **Elimination of Fragile Constructs:** Discards `if ! pgrep -f kitty >/dev/null; then return; fi; kill -SIGUSR1 $(pidof kitty)`, removing the bug where `pgrep -f` matched non-Kitty scripts and `pidof` failed.

---

### 5. `~/.config/matugen/templates/kde/kde-material-you-colors-wrapper.sh` (KDE Wrapper Template)

**Role:** Post-Matugen execution script generating KDE color palette (`kdeglobals`) from wallpaper colors via `kde-material-you-colors`.  
**Analog:** Existing `~/.config/matugen/templates/kde/kde-material-you-colors-wrapper.sh:45-49` (self-analog).  
**Data Flow:** Sources Python virtual environment, executes CLI utility, deactivates environment.

#### Pattern 5.1: Virtualenv Parameter Expansion Fallback
Source: `~/.config/matugen/templates/kde/kde-material-you-colors-wrapper.sh:45-49`, `30-CONTEXT.md:D-06`, `30-RESEARCH.md:347-353`
```bash
esac

source "$(eval echo ${ILLOGICAL_IMPULSE_VIRTUAL_ENV:-$XDG_STATE_HOME/quickshell/.venv})/bin/activate"
kde-material-you-colors "$mode_flag" --color "$color" -sv "$sv_num"
deactivate
```

#### Key Rules & Invariants:
- **Fallback Syntax:** Use `${ILLOGICAL_IMPULSE_VIRTUAL_ENV:-$XDG_STATE_HOME/quickshell/.venv}` inside the `eval echo` construct so that if the environment variable is not defined, it defaults safely to the canonical local state directory.
- **No Direct Submodule Edits:** This file is a live template under `~/.config/matugen/templates/kde/`. Pinned `vendor/dots-hyprland` remains untouched.

---

### 6. `.planning/phases/29-theme-data-contracts-verification-bootstrap-integration/29-VALIDATION.md` (Phase 29 Contract Reconciliation)

**Role:** Nyquist validation contract for Phase 29 tracking automated verification commands, sampling rate, and sign-off status.  
**Analog:** `.planning/milestones/v0.4-phases/24-address-tech-debt-bookkeeping-and-validation-cleanup/24-PATTERNS.md:681-728` + `.planning/phases/17-unblock-stow-and-restore-the-session-target/17-VALIDATION.md:1-11, 145-182`.  
**Data Flow:** Read by GSD milestone auditor and validation scripts.

#### Pattern 6.1: Validation Lifecycle Transition to Compliant
Source: `.planning/phases/29-theme-data-contracts-verification-bootstrap-integration/29-VALIDATION.md:1-8, 37-49, 70-80`, `30-CONTEXT.md:D-08`
```markdown
---
phase: "29"
slug: "theme-data-contracts-verification-bootstrap-integration"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-09-18"
validated: "2026-09-18"
---
```

#### Pattern 6.2: Per-Task Verification Map Updates
Update all pending task rows (`❌ W0`, `⬜ pending`) to `✅` and `✅ green`, backed by the passing 30/30 checks in `scripts/phase29-theme-data-contracts-assert.sh`:
```markdown
| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---|---|---|---|---|---|---|---|---|---|
| 29-01-01 | 01 | 0 | INTG-01 | T-29-01 | Scaffolding of test harness with fail-closed structure and argument parsing | contract | `bash scripts/phase29-theme-data-contracts-assert.sh --help` | ✅ | ✅ green |
| 29-01-02 | 01 | 1 | INTG-01 | T-29-01 | Guard paths & .gitignore parity, collision map, restow table, and PAIR_COUNT | contract | `bash scripts/phase29-theme-data-contracts-assert.sh --section 1` | ✅ | ✅ green |
| 29-01-03 | 01 | 1 | INTG-01, INTG-02 | T-29-01 | Package relocation to restow/ and strict verification engine pass | integration | `bash scripts/phase29-theme-data-contracts-assert.sh --section 3` | ✅ | ✅ green |
| 29-02-01 | 02 | 2 | INTG-01 | T-29-02 | Live theme switching zero git churn drill with porcelain brackets | integration | `bash scripts/phase29-theme-data-contracts-assert.sh --section 2` | ✅ | ✅ green |
| 29-02-02 | 02 | 2 | INTG-03 | T-29-02 | Bootstrap orchestrator destub, Catppuccin unlinking, parent dir pre-creation, fallback theming | integration | `bash scripts/phase29-theme-data-contracts-assert.sh --section 4` | ✅ | ✅ green |
| 29-02-03 | 02 | 2 | INTG-01..03 | T-29-02 | Full multi-phase v0.5 regression sweep across phase 25-28 | regression | `bash scripts/phase29-theme-data-contracts-assert.sh --section 5` | ✅ | ✅ green |
```

#### Pattern 6.3: Sign-Off Checklist Completion
```markdown
## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 10s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** complete
```

---

### 7. `scripts/phase30-tech-debt-assert.sh` (Dedicated Test Suite & Regression Harness)

**Role:** Gating test harness proving all Phase 30 deliverables (`DEBT-05` to `DEBT-08`), Nyquist compliance across v0.5, strict packaging engine verification, and full multi-phase regression sweeps with zero git working tree churn.  
**Analog:** `scripts/phase24-tech-debt-assert.sh:1-405` (scaffolding, helpers, cleanup trap, section parsing, porcelain brackets, strict verify) + `scripts/phase29-theme-data-contracts-assert.sh:400-439` (multi-phase regression loop).

#### Pattern 7.1: Runner Scaffolding, Helpers, and Cleanup Trap
Source: `scripts/phase24-tech-debt-assert.sh:1-37`
```bash
#!/usr/bin/env bash
# Phase 30 Tech debt: v0.5 cleanup and validation sign-off assert harness (DEBT-05 to DEBT-08).
# One script, one section per requirement criterion, one verdict for the phase.
#
# Usage (from REPO_ROOT):
#   ./scripts/phase30-tech-debt-assert.sh [--section <1-5>]
# Exit 0 if all hard asserts pass; exit 1 if any hard FAIL.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

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
```

#### Pattern 7.2: CLI Section Selector & Porcelain Bracket
Source: `scripts/phase24-tech-debt-assert.sh:38-75`
```bash
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
```

#### Pattern 7.3: Section 1 — Kitty Opacity & Phase 28 Assert Alignment (`DEBT-05`)
Source: `30-RESEARCH.md:424`, `scripts/phase28-terminal-fuzzel-assert.sh:267-293`
```bash
# --- Section 1: Kitty Opacity & Phase 28 Assert Alignment (DEBT-05) ---
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 1 ]]; then
  info "--- Section 1: DEBT-05 Kitty Opacity & Phase 28 Assert Alignment ---"

  # 1. Check restow/kitty/.config/kitty/kitty.conf for background_opacity 0.90
  KITTY_CONF="$REPO_ROOT/restow/kitty/.config/kitty/kitty.conf"
  if grep -q '^background_opacity 0.90' "$KITTY_CONF"; then
    pass "DEBT-05 (S1): restow/kitty/.../kitty.conf specifies background_opacity 0.90"
  else
    fail "DEBT-05 (S1): restow/kitty/.../kitty.conf missing background_opacity 0.90"
  fi

  # 2. Native Kitty configuration parser probe for opacity 0.90
  KITTY_OPTS_VERDICT="$(kitty +runpy "import sys
from kitty.config import load_config
try:
    opts = load_config('$HOME/.config/kitty/kitty.conf')
    if abs(opts.background_opacity - 0.90) > 0.01:
        print(f'FAIL: background_opacity expected 0.90, got {opts.background_opacity}')
        sys.exit(1)
    print('PASS: background_opacity is 0.90')
except Exception as e:
    print(f'FAIL: {e}')
    sys.exit(1)
" 2>&1 || true)"

  if [[ "$KITTY_OPTS_VERDICT" =~ ^PASS ]]; then
    pass "DEBT-05 (S1): Live Kitty configuration loaded opacity 0.90 within tolerance"
  else
    fail "DEBT-05 (S1): Live Kitty configuration probe failed: $KITTY_OPTS_VERDICT"
  fi

  # 3. Phase 28 assert alignment verification
  P28_ASSERT="$REPO_ROOT/scripts/phase28-terminal-fuzzel-assert.sh"
  if grep -q 'abs(opts.background_opacity - 0.90) > 0.01' "$P28_ASSERT" && \
     grep -q 'opacity=0.90' "$P28_ASSERT"; then
    pass "DEBT-05 (S1): scripts/phase28-terminal-fuzzel-assert.sh checks 0.90 opacity"
  else
    fail "DEBT-05 (S1): scripts/phase28-terminal-fuzzel-assert.sh not aligned to 0.90"
  fi

  # 4. Phase 28 Section 3 quick run must pass
  P28_S3_RC=0
  "$P28_ASSERT" --section 3 >/dev/null 2>&1 || P28_S3_RC=$?
  if [[ "$P28_S3_RC" -eq 0 ]]; then
    pass "DEBT-05 (S1): scripts/phase28-terminal-fuzzel-assert.sh --section 3 passed"
  else
    fail "DEBT-05 (S1): scripts/phase28-terminal-fuzzel-assert.sh --section 3 failed (rc=$P28_S3_RC)"
  fi
fi
```

#### Pattern 7.4: Section 2 — Environment Fallback & Process Signaling Hardening (`DEBT-06`)
Source: `30-RESEARCH.md:425`, `bootstrap.sh:597-641`
```bash
# --- Section 2: Environment Fallback & Process Signaling Hardening (DEBT-06) ---
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 ]]; then
  info "--- Section 2: DEBT-06 Environment Fallback & Process Signaling Hardening ---"

  # 1. Check bootstrap.sh for ILLOGICAL_IMPULSE_VIRTUAL_ENV fallback export
  if grep -q 'export ILLOGICAL_IMPULSE_VIRTUAL_ENV="\${ILLOGICAL_IMPULSE_VIRTUAL_ENV:-' "$REPO_ROOT/bootstrap.sh"; then
    pass "DEBT-06 (S2): bootstrap.sh exports ILLOGICAL_IMPULSE_VIRTUAL_ENV fallback"
  else
    fail "DEBT-06 (S2): bootstrap.sh missing virtualenv fallback export"
  fi

  # 2. Check bootstrap.sh for idempotent sanitization blocks
  if grep -q 'Aligned kde-material-you-colors-wrapper.sh virtualenv fallback' "$REPO_ROOT/bootstrap.sh" && \
     grep -q 'Aligned applycolor.sh Kitty process signaling' "$REPO_ROOT/bootstrap.sh"; then
    pass "DEBT-06 (S2): bootstrap.sh contains idempotent alignment hooks for wrapper and signaler"
  else
    fail "DEBT-06 (S2): bootstrap.sh missing alignment hooks for wrapper or signaler"
  fi

  # 3. Check live kde-material-you-colors-wrapper.sh for fallback
  KDE_WRAPPER="$HOME/.config/matugen/templates/kde/kde-material-you-colors-wrapper.sh"
  if [[ -f "$KDE_WRAPPER" ]] && grep -Fq '${ILLOGICAL_IMPULSE_VIRTUAL_ENV:-$XDG_STATE_HOME/quickshell/.venv}' "$KDE_WRAPPER"; then
    pass "DEBT-06 (S2): Live kde-material-you-colors-wrapper.sh contains parameter expansion fallback"
  else
    fail "DEBT-06 (S2): Live kde-material-you-colors-wrapper.sh missing parameter expansion fallback"
  fi

  # 4. Check live applycolor.sh for killall signaling and absence of fragile constructs
  APPLYCOLOR="$HOME/.config/quickshell/ii/scripts/colors/applycolor.sh"
  if [[ -f "$APPLYCOLOR" ]] && grep -Fq 'killall -SIGUSR1 kitty 2>/dev/null || true' "$APPLYCOLOR" && \
     ! grep -q 'kill -SIGUSR1 \$(pidof kitty)' "$APPLYCOLOR"; then
    pass "DEBT-06 (S2): Live applycolor.sh contains hardened killall signaling without pidof"
  else
    fail "DEBT-06 (S2): Live applycolor.sh signaling not hardened or retains pidof"
  fi

  # 5. Scratch drill: Test idempotent sanitization in isolated sandbox
  S2_SCRATCH="$(mktemp -d /tmp/p30-scratch-s2-XXXXXX)"
  SCRATCH_ROOTS+=("$S2_SCRATCH")
  mkdir -p "$S2_SCRATCH/.config/matugen/templates/kde" "$S2_SCRATCH/.config/quickshell/ii/scripts/colors"

  # Seed mock unaligned files
  printf 'source "$(eval echo $ILLOGICAL_IMPULSE_VIRTUAL_ENV)/bin/activate"\n' > "$S2_SCRATCH/.config/matugen/templates/kde/kde-material-you-colors-wrapper.sh"
  cat << 'MOCK_EOF' > "$S2_SCRATCH/.config/quickshell/ii/scripts/colors/applycolor.sh"
  if ! pgrep -f kitty >/dev/null; then
    return
  fi
  kill -SIGUSR1 $(pidof kitty)
MOCK_EOF

  # Run sanitization sed expressions
  sed -i 's|source "$(eval echo \$ILLOGICAL_IMPULSE_VIRTUAL_ENV)/bin/activate"|source "$(eval echo ${ILLOGICAL_IMPULSE_VIRTUAL_ENV:-$XDG_STATE_HOME/quickshell/.venv})/bin/activate"|g' "$S2_SCRATCH/.config/matugen/templates/kde/kde-material-you-colors-wrapper.sh"
  sed -i '/if ! pgrep -f kitty >\/dev\/null; then/,/kill -SIGUSR1 \$(pidof kitty)/c\  killall -SIGUSR1 kitty 2>/dev/null || true' "$S2_SCRATCH/.config/quickshell/ii/scripts/colors/applycolor.sh"

  if grep -Fq '${ILLOGICAL_IMPULSE_VIRTUAL_ENV:-$XDG_STATE_HOME/quickshell/.venv}' "$S2_SCRATCH/.config/matugen/templates/kde/kde-material-you-colors-wrapper.sh" && \
     grep -Fq 'killall -SIGUSR1 kitty 2>/dev/null || true' "$S2_SCRATCH/.config/quickshell/ii/scripts/colors/applycolor.sh"; then
    pass "DEBT-06 (S2): Scratch drill verified idempotent sanitization expressions"
  else
    fail "DEBT-06 (S2): Scratch drill failed sanitization expression verification"
  fi
fi
```

#### Pattern 7.5: Section 3 — Nyquist Validation Compliance & Requirements Traceability (`DEBT-07`)
Source: `30-RESEARCH.md:426`, `24-PATTERNS.md:176-238`
```bash
# --- Section 3: Nyquist Validation Compliance Across v0.5 & Traceability (DEBT-07) ---
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 3 ]]; then
  info "--- Section 3: DEBT-07 Nyquist Validation Compliance Across v0.5 & Traceability ---"

  v05_validation_files=(
    .planning/phases/25-gtk-material-you-theming-catppuccin-de-linking/25-VALIDATION.md
    .planning/phases/26-qt-kde-apps-material-you-harmonization/26-VALIDATION.md
    .planning/phases/27-hyprland-quickshell-ii-accent-coordination/27-VALIDATION.md
    .planning/phases/28-terminal-fuzzel-launcher-dynamic-palette/28-VALIDATION.md
    .planning/phases/29-theme-data-contracts-verification-bootstrap-integration/29-VALIDATION.md
    .planning/phases/30-address-tech-debt-v0-5-cleanup-and-validation-sign-off/30-VALIDATION.md
  )

  for vf in "${v05_validation_files[@]}"; do
    if [[ ! -f "$REPO_ROOT/$vf" ]]; then
      fail "DEBT-07 (S3): missing validation file: $vf"
      continue
    fi

    # Check status: validated
    if grep -qE '^status:\s*(validated|compliant)' "$REPO_ROOT/$vf"; then
      pass "DEBT-07 (S3): $(basename "$vf") has status: validated"
    else
      fail "DEBT-07 (S3): $(basename "$vf") missing status: validated"
    fi

    # Check nyquist_compliant: true
    if grep -qE '^nyquist_compliant:\s*true' "$REPO_ROOT/$vf"; then
      pass "DEBT-07 (S3): $(basename "$vf") has nyquist_compliant: true"
    else
      fail "DEBT-07 (S3): $(basename "$vf") missing nyquist_compliant: true"
    fi

    # Check wave_0_complete: true
    if grep -qE '^wave_0_complete:\s*true' "$REPO_ROOT/$vf"; then
      pass "DEBT-07 (S3): $(basename "$vf") has wave_0_complete: true"
    else
      fail "DEBT-07 (S3): $(basename "$vf") missing wave_0_complete: true"
    fi
  done

  # Check 29-VALIDATION.md has zero pending tasks
  P29_PENDING="$(grep -c '⬜ pending' "$REPO_ROOT/.planning/phases/29-theme-data-contracts-verification-bootstrap-integration/29-VALIDATION.md" || true)"
  if [[ "$P29_PENDING" -eq 0 ]]; then
    pass "DEBT-07 (S3): 29-VALIDATION.md has 0 pending tasks (all green)"
  else
    fail "DEBT-07 (S3): 29-VALIDATION.md has $P29_PENDING pending tasks"
  fi

  # Check REQUIREMENTS.md for DEBT-05 through DEBT-08
  for req in DEBT-05 DEBT-06 DEBT-07 DEBT-08; do
    if grep -q "$req" "$REPO_ROOT/.planning/REQUIREMENTS.md"; then
      pass "DEBT-07 (S3): $req registered in REQUIREMENTS.md"
    else
      fail "DEBT-07 (S3): $req missing from REQUIREMENTS.md"
    fi
  done

  # Zero Pending markers in REQUIREMENTS.md v1 table
  PENDING_COUNT="$(grep -c -E '\|\s*Pending\s*\|' "$REPO_ROOT/.planning/REQUIREMENTS.md" || true)"
  if [[ "$PENDING_COUNT" -eq 0 ]]; then
    pass "DEBT-07 (S3): 0 stale 'Pending' markers found in REQUIREMENTS.md"
  else
    fail "DEBT-07 (S3): found $PENDING_COUNT stale 'Pending' markers in REQUIREMENTS.md"
  fi

  # Check ROADMAP.md maps Phase 30 requirements
  if grep -q "Phase 30.*DEBT-05" "$REPO_ROOT/.planning/ROADMAP.md" || \
     grep -q "DEBT-05, DEBT-06, DEBT-07, DEBT-08" "$REPO_ROOT/.planning/ROADMAP.md"; then
    pass "DEBT-07 (S3): ROADMAP.md reflects Phase 30 DEBT requirements mapping"
  else
    fail "DEBT-07 (S3): ROADMAP.md missing Phase 30 requirements mapping"
  fi
fi
```

#### Pattern 7.6: Section 4 — Strict Verifier Gate (`DEBT-08`)
Source: `scripts/phase24-tech-debt-assert.sh:378-390`
```bash
# --- Section 4: Strict Verifier Engine Gate (DEBT-08) ---
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 4 ]]; then
  info "--- Section 4: DEBT-08 Strict Verifier Engine Gate ---"

  VERIFY_RC=0
  VERIFY_OUT="$("$REPO_ROOT/arch/dots-hyprland.sh" verify --strict 2>&1)" || VERIFY_RC=$?
  if [[ "$VERIFY_RC" -eq 0 ]]; then
    pass "DEBT-08 (S4): arch/dots-hyprland.sh verify --strict passed with zero findings (FAIL=0 FINDINGS=0)"
  else
    fail "DEBT-08 (S4): arch/dots-hyprland.sh verify --strict failed (rc=$VERIFY_RC)"
    printf '%s\n' "$VERIFY_OUT" | sed 's/^/       /' >&2
  fi
fi
```

#### Pattern 7.7: Section 5 — Full v0.5 Multi-Phase Regression Sweep (`DEBT-08`)
Source: `scripts/phase29-theme-data-contracts-assert.sh:400-422`
```bash
# --- Section 5: Full v0.5 Multi-Phase Regression Sweep (DEBT-08) ---
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 5 ]]; then
  info "--- Section 5: DEBT-08 Full v0.5 Multi-Phase Regression Sweep (Phases 25–29) ---"

  for p_script in "scripts/phase25-gtk-material-you-assert.sh" \
                  "scripts/phase26-qt-kde-material-you-assert.sh" \
                  "scripts/phase27-accent-coordination-assert.sh" \
                  "scripts/phase28-terminal-fuzzel-assert.sh" \
                  "scripts/phase29-theme-data-contracts-assert.sh"; do
    if [[ -x "$REPO_ROOT/$p_script" ]]; then
      p_rc=0
      p_out="$("$REPO_ROOT/$p_script" 2>&1)" || p_rc=$?
      if [[ "$p_rc" -eq 0 ]]; then
        pass "DEBT-08 (S5): $p_script passed cleanly with 0 failures"
      else
        fail "DEBT-08 (S5): $p_script failed with exit code $p_rc"
        printf '%s\n' "$p_out" | tail -n 20 | sed 's/^/       /' >&2
      fi
    else
      fail "DEBT-08 (S5): $p_script missing or not executable"
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
```

---

### 8. `.planning/phases/30-address-tech-debt-v0-5-cleanup-and-validation-sign-off/30-VALIDATION.md` (Phase 30 Validation Contract)

**Role:** Phase 30 validation strategy asserting test framework, sampling frequency, task-to-assertion mapping, and Nyquist sign-off.  
**Analog:** `.planning/phases/29-theme-data-contracts-verification-bootstrap-integration/29-VALIDATION.md` + `.planning/milestones/v0.4-phases/24-address-tech-debt-bookkeeping-and-validation-cleanup/24-VALIDATION.md`.

#### Pattern 8.1: Validation Contract Architecture
Source: `24-VALIDATION.md:1-81`, `29-VALIDATION.md:1-80`
```markdown
---
phase: "30"
slug: "address-tech-debt-v0-5-cleanup-and-validation-sign-off"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-09-18"
validated: "2026-09-18"
---

# Phase 30 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `30-RESEARCH.md` § Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Standalone Bash Assert Harness (`scripts/phase30-tech-debt-assert.sh`) + strict verify (`arch/dots-hyprland.sh verify --strict`) |
| **Config file** | `scripts/phase30-tech-debt-assert.sh` adhering to four-prefix contract |
| **Quick run command** | `./scripts/phase30-tech-debt-assert.sh --section <1-5>` |
| **Full suite command** | `./scripts/phase30-tech-debt-assert.sh && ./arch/dots-hyprland.sh verify --strict` |
| **Estimated runtime** | ~12 seconds (including full 5-phase regression sweep) |

---

## Sampling Rate

- **After every task commit:** Run `./scripts/phase30-tech-debt-assert.sh --section <N>` matching the task domain
- **After every plan wave:** Run `./scripts/phase30-tech-debt-assert.sh`
- **Before `/gsd-verify-work`:** Full suite must be green (`FAIL=0`) AND `./arch/dots-hyprland.sh verify --strict` exits 0 (`FAIL=0 FINDINGS=0`)
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---|---|---|---|---|---|---|---|---|---|
| 30-01-01 | 01 | 1 | DEBT-05 | T-30-01 | Kitty background opacity 0.90 update in restow/ and live SIGUSR1 signal | integration | `./scripts/phase30-tech-debt-assert.sh --section 1` | ✅ exists | ✅ green |
| 30-01-02 | 01 | 1 | DEBT-05 | T-30-01 | Align Phase 28 assert harness lines 273, 282, 289 to expect 0.90 opacity | regression | `./scripts/phase28-terminal-fuzzel-assert.sh --section 3` | ✅ exists | ✅ green |
| 30-01-03 | 01 | 1 | DEBT-06 | T-30-02 | Bootstrap virtualenv export fallback and idempotent sanitization blocks | unit / drill | `./scripts/phase30-tech-debt-assert.sh --section 2` | ✅ exists | ✅ green |
| 30-01-04 | 01 | 1 | DEBT-06 | T-30-02 | Direct alignment of live kde-material-you wrapper and applycolor.sh signaling | integration | `./scripts/phase30-tech-debt-assert.sh --section 2` | ✅ exists | ✅ green |
| 30-02-01 | 02 | 0 | DEBT-08 | T-30-03 | Scaffold dedicated Phase 30 assert harness with fail-closed structure | harness | `./scripts/phase30-tech-debt-assert.sh --help` | ✅ exists | ✅ green |
| 30-02-02 | 02 | 2 | DEBT-07 | — | Reconcile 29-VALIDATION.md to validated and nyquist_compliant: true | contract | `./scripts/phase30-tech-debt-assert.sh --section 3` | ✅ exists | ✅ green |
| 30-02-03 | 02 | 2 | DEBT-07 | — | Sync REQUIREMENTS.md and ROADMAP.md with DEBT-05..08 definitions | bookkeeping | `./scripts/phase30-tech-debt-assert.sh --section 3` | ✅ exists | ✅ green |
| 30-02-04 | 02 | 2 | DEBT-08 | T-30-04 | Strict system verification gate and clean working tree porcelain check | system check | `./scripts/phase30-tech-debt-assert.sh --section 4` | ✅ exists | ✅ green |
| 30-02-05 | 02 | 2 | DEBT-08 | T-30-05 | Full v0.5 multi-phase regression sweep across phases 25 through 29 | regression | `./scripts/phase30-tech-debt-assert.sh --section 5` | ✅ exists | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `scripts/phase30-tech-debt-assert.sh` — standalone assertion harness covering sections 1–5 with fail-closed reporting

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions | Classification |
|---|---|---|---|---|
| Live Kitty background transparency perception | DEBT-05 | Visual aesthetic verification | Launch Kitty or observe active window over desktop wallpaper | Non-blocking inspection / visual confirmation |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 15s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** complete
```

---

### 9. `.planning/REQUIREMENTS.md` (Requirements Traceability Register)

**Role:** Master register of all user and architectural requirements across milestones.  
**Analog:** `.planning/REQUIREMENTS.md:6-37, 63-86` (self-analog) + Phase 24 additions in `24-PATTERNS.md:546-581`.  
**Data Flow:** Read by `/gsd-audit-milestone` to compute completion percentage and verify zero unmapped requirements.

#### Pattern 9.1: Registering Phase 30 Technical Debt Requirements Block
Source: `30-CONTEXT.md:D-11`, `.planning/REQUIREMENTS.md:32-37`
```markdown
### DEBT (Technical Debt & Validation Cleanup)

- [x] **DEBT-05**: Kitty background opacity updated to 0.90 in `restow/kitty/.config/kitty/kitty.conf`, aligned in `scripts/phase28-terminal-fuzzel-assert.sh`, and signaled live via POSIX SIGUSR1.
- [x] **DEBT-06**: Virtualenv parameter expansion fallback in `bootstrap.sh` and `kde-material-you-colors-wrapper.sh` prevents non-graphical execution failure, and Kitty signaling in `applycolor.sh` is hardened to `killall -SIGUSR1 kitty 2>/dev/null || true` with idempotent bootstrap alignment.
- [x] **DEBT-07**: `29-VALIDATION.md` reconciled from `status: draft`, `nyquist_compliant: false` to `status: validated`, `nyquist_compliant: true`, `wave_0_complete: true`, and all 6 tasks marked green backed by passing 30/30 assertions in `scripts/phase29-theme-data-contracts-assert.sh`.
- [x] **DEBT-08**: Dedicated test harness `scripts/phase30-tech-debt-assert.sh` with 5 automated sections, `30-VALIDATION.md` authored, and full v0.5 regression sweep (Phases 25–29) passes fail-closed.
```

#### Pattern 9.2: Traceability Table Rows for Phase 30
```markdown
| DEBT-05 | Phase 30 | Complete |
| DEBT-06 | Phase 30 | Complete |
| DEBT-07 | Phase 30 | Complete |
| DEBT-08 | Phase 30 | Complete |
```

#### Pattern 9.3: Coverage & Arithmetic Update
```markdown
**Coverage:**

- v1 requirements: 19 total
- Mapped to phases: 19
- Unmapped: 0 ✓
```

---

### 10. `.planning/ROADMAP.md` (Milestone Roadmap Specification)

**Role:** Central tracking document mapping phases to requirements, dependencies, and success criteria.  
**Analog:** `.planning/ROADMAP.md:219-238` (self-analog) + Phase 24 definition in `24-PATTERNS.md:589-617`.  
**Data Flow:** Read by `/gsd-progress` and `/gsd-plan-phase`.

#### Pattern 10.1: Phase 30 Definition Block
Source: `30-CONTEXT.md:D-12, D-13`, `30-RESEARCH.md:76-89`
```markdown
### Phase 30: Address tech debt: v0.5 cleanup and validation sign-off

**Goal:** Address accumulated technical debt, visual polish preferences, environment fallback robustness, and validation coverage gaps from Milestone v0.5 audit, establishing 100% Nyquist compliance and multi-phase regression coverage.
**Depends on:** Phase 29
**Requirements:** DEBT-05, DEBT-06, DEBT-07, DEBT-08
**Success Criteria** (what must be TRUE):

  1. Kitty opacity is updated to 0.90 in `restow/kitty/.config/kitty/kitty.conf`, aligned in `scripts/phase28-terminal-fuzzel-assert.sh`, and live running instances reload without dropping active shell sessions (DEBT-05)
  2. `bootstrap.sh` exports `ILLOGICAL_IMPULSE_VIRTUAL_ENV` fallback and idempotently aligns live `kde-material-you-colors-wrapper.sh` virtualenv parameter expansion and `applycolor.sh` Kitty signaling (`killall -SIGUSR1 kitty 2>/dev/null || true`) (DEBT-06)
  3. `29-VALIDATION.md` reconciled to `status: validated`, `nyquist_compliant: true`, and all 6 tasks marked green, backed by 30/30 passing assertions in `scripts/phase29-theme-data-contracts-assert.sh` (DEBT-07)
  4. Dedicated test harness `scripts/phase30-tech-debt-assert.sh` passes all 5 sections fail-closed, `./arch/dots-hyprland.sh verify --strict` exits 0 with `FAIL=0 FINDINGS=0`, and full multi-phase regression sweep across Phases 25–29 passes with zero git working tree churn (DEBT-08)

**Plans:** 2/2 plans complete

Plans:

- [ ] 30-01-PLAN.md — Visual polish, environment fallback, and script signaling robustness
- [ ] 30-02-PLAN.md — Validation sign-off, Phase 30 assert harness, full regression sweep, and milestone closeout readiness
```

#### Pattern 10.2: Progress Table Update
```markdown
| 30. Address tech debt: v0.5 cleanup and validation sign-off | v0.5 | 0/2 | In progress | - |
```

---

## Universal Repository Conventions & Invariants

### 1. D-20 Frozen History Rule
- **Invariant:** Closed-phase assert scripts (e.g. `scripts/phase24-tech-debt-assert.sh`, `scripts/phase29-theme-data-contracts-assert.sh`) and historical narrative records must NEVER be retroactively modified to make an audit pass.
- **Enforcement:** All new verifications and fixes must reside in Phase 30 artifacts (`scripts/phase30-tech-debt-assert.sh`), except for explicitly allowed assert threshold alignment (D-02 for `scripts/phase28-terminal-fuzzel-assert.sh`).

### 2. Confined Kitty Visual Tuning
- **Invariant:** Visual adjustments are strictly confined to Kitty background opacity (`background_opacity 0.90`). Fuzzel launcher alpha (`0.95`), terminal margins, borders, and color palettes must remain exactly as established in Phase 28.
- **Enforcement:** Checked via native options probe in Section 1 of `scripts/phase30-tech-debt-assert.sh`.

### 3. Fail-Soft POSIX Process Signaling
- **Invariant:** Signals sent to desktop applications from automated scripts must use `killall -SIGUSR1 <binary> 2>/dev/null || true` rather than custom `pgrep`/`pidof` pipelines.
- **Enforcement:** Tested in Section 2 of `scripts/phase30-tech-debt-assert.sh`.

### 4. Zero Drift Working Tree Gate
- **Invariant:** Running test harnesses, bootstrap drills, or regression sweeps must leave the git working tree 100% byte-identical.
- **Enforcement:** Captured via `PORCELAIN_BEFORE` and `PORCELAIN_AFTER` comparisons using `git status --porcelain`.

### 5. Strict System Verification Exit Code Binding
- **Invariant:** `./arch/dots-hyprland.sh verify --strict` must always exit 0 with `FAIL=0 FINDINGS=0`.
- **Enforcement:** Gated in Section 4 of `scripts/phase30-tech-debt-assert.sh`.

### 6. Exit Code Hierarchy
- `0`: Success / all assertions passed / clean verification.
- `1`: Failure / test assertion failed / drift detected.
- `2`: Precondition failure / invalid CLI arguments.

---

## Pattern Mapping Metadata

- **Phase:** 30 — `address-tech-debt-v0-5-cleanup-and-validation-sign-off`
- **Target Directory:** `/home/pera/github_repo/.dotfiles/.planning/phases/30-address-tech-debt-v0-5-cleanup-and-validation-sign-off`
- **Mapped By:** GSD Pattern Mapper
- **Source Analogs Verified:**
  - `restow/kitty/.config/kitty/kitty.conf` (Kitty opacity config)
  - `scripts/phase28-terminal-fuzzel-assert.sh` (Kitty opacity parser probe)
  - `bootstrap.sh` (Template sanitization & virtualenv fallback export)
  - `~/.config/quickshell/ii/scripts/colors/applycolor.sh` (Process signaling)
  - `~/.config/matugen/templates/kde/kde-material-you-colors-wrapper.sh` (Virtualenv parameter expansion)
  - `.planning/phases/29-theme-data-contracts-verification-bootstrap-integration/29-VALIDATION.md` (Validation reconciliation)
  - `scripts/phase24-tech-debt-assert.sh` (5-section tech debt assert architecture)
  - `scripts/phase29-theme-data-contracts-assert.sh` (Multi-phase regression sweep loop)
  - `.planning/REQUIREMENTS.md` (Requirements register & traceability table)
  - `.planning/ROADMAP.md` (Milestone roadmap specification)
