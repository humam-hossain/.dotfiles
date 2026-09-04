# Phase 14: Live full adopt & verify - Pattern Map

**Mapped:** 2026-09-04
**Files analyzed:** 9
**Analogs found:** 6 / 9

All analog paths below were checked with `git ls-files` and are git-TRACKED source in this repo. No gitignored mirror paths appear.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `scripts/phase14-preflight.sh` | script / assert-gate | batch checks + exit code | `scripts/phase12-full-smoke.sh` (body) + `scripts/phase10-inventory-assert.sh` (flag parse) | exact |
| `scripts/phase14-verify.sh` | script / assert-gate | batch checks + exit code | `scripts/phase12-full-smoke.sh` | exact |
| `docs/phase14-adopt-runbook.md` | operator doc | human procedure | `docs/dots-hyprland-workflow.md` | exact |
| `.planning/phases/14-live-full-adopt-verify/14-PRE-ADOPT-BASELINE.txt` | fixture / recorded facts | write-once, read-later | none (partial: `13-SOT-APPLY.md` as phase-dir SoT artifact) | partial |
| `.planning/phases/14-live-full-adopt-verify/14-LIVE-VERIFY.md` | phase record | write-once report | `.planning/phases/13-personal-hypr-custom-overlays/13-SOT-APPLY.md` | role-match |
| `.planning/phases/14-live-full-adopt-verify/14-ADOPT-TRANSCRIPT.txt` | raw evidence | `script(1)` capture | none | none |
| `arch/dots-hyprland.sh` (D-28) | config array edit | n/a (2-line delete) | itself — `PROTECT_EXPLICIT` at `:230-295` | exact |
| `.config/hypr/**` (D-03 sync) | archive data | one-way live→repo | `.config/hypr/` existing tracked tree | exact |
| `.gitignore` (add `.gsd/`) | config | n/a | `.gitignore` existing patterns | exact |

## Pattern Assignments

### `scripts/phase14-preflight.sh` (script, batch checks)

**Analog:** `scripts/phase12-full-smoke.sh` for body/idioms; `scripts/phase10-inventory-assert.sh:30-47` for optional-flag parsing (needed for `--rotate-backup`, RESEARCH Pitfall 2).

**Header + preamble pattern** (`scripts/phase12-full-smoke.sh:1-16`) — copy shape verbatim, change the phase text:
```bash
#!/usr/bin/env bash
# Phase 12 FULL-01..05 automated smoke asserts (Nyquist validation).
# Non-mutating only: help / --dry-run / refuse / syntax. Never runs live install --full.
#
# Usage (from REPO_ROOT):
#   ./scripts/phase12-full-smoke.sh
# Exit 0 if all hard asserts pass; non-zero if any hard FAIL.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

FAIL=0
pass() { printf '[PASS] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
```
Phase 14 adds a third level per RESEARCH §Pattern 1 (D-14/D-38 route here, never to `fail`):
```bash
FINDINGS=0
finding() { printf '[FINDING] %s\n' "$1"; FINDINGS=$((FINDINGS + 1)); }
```

**Flag-parsing pattern** (`scripts/phase10-inventory-assert.sh:30-47`) — the shape for `--rotate-backup` and `-h`:
```bash
FULL=0
for arg in "$@"; do
  case "$arg" in
    --full) FULL=1 ;;
    -h|--help)
      cat <<'EOF'
Usage: ./scripts/phase10-inventory-assert.sh [--full]

  (default)  Structural + lint gates on 10-INVENTORY.md
  --full     Also print read-only PRESENT/ABSENT host checklist
EOF
      exit 0
      ;;
    *)
      echo "[FAIL] unknown arg: $arg" >&2
      exit 1
      ;;
  esac
done
```

**XDG path pattern** (`scripts/phase10-inventory-assert.sh:24`, same at `scripts/phase13-d19-assert.sh:22`) — never hard-code `$HOME/.config`:
```bash
XDG="${XDG_CONFIG_HOME:-$HOME/.config}"
LIVE_CUSTOM="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/custom"
```

**Config echo before checks** (`scripts/phase10-inventory-assert.sh:49-50`):
```bash
echo "=== Phase 10 inventory asserts ==="
echo "[CONFIG] inventory=$INVENTORY"
```

**Early hard-abort on a missing precondition** (`scripts/phase10-inventory-assert.sh:53-60`) — the shape D-34 needs for `installed_true`:
```bash
if [[ -f "$INVENTORY" ]]; then
  pass "D-01 inventory file exists"
else
  fail "D-01 inventory file missing: $INVENTORY"
  echo "=== done: FAIL=${FAIL} ==="
  exit 1
fi
```

**Gate-fed dry-run capture** (`scripts/phase12-full-smoke.sh:19-25, 63-69`) — mktemp + trap + `printf 'yes\n' |`, exactly as D-05 requires:
```bash
FULL_OUT="$(mktemp /tmp/p12-smoke-full-XXXXXX)"
# shellcheck disable=SC2064
trap 'rm -f "$HELP_OUT" "$FULL_OUT" "$SAFE_OUT" "$FILES_OUT" "$ALLOW_OUT"' EXIT
...
if printf 'yes\n' | "$WRAP" install --full --dry-run >"$FULL_OUT" 2>&1; then
  if grep -q 'would exec' "$FULL_OUT"; then
    pass "FULL-04 full dry-run prints would-exec"
  else
    fail "FULL-04 full dry-run missing would-exec"
    sed -n '1,40p' "$FULL_OUT" || true
  fi
```
Note the `sed -n '1,40p' "$FULL_OUT" || true` on failure — dumping evidence on FAIL is a repo convention, keep it.

**Refuse-path assert (inverted exit code)** (`scripts/phase12-full-smoke.sh:122-126`) — the shape for asserting a forbidden flag is rejected:
```bash
if "$WRAP" install --full --skip-backup --dry-run >/tmp/p12-smoke-skip.txt 2>&1; then
  fail "FULL-03 install --full --skip-backup --dry-run should exit non-zero"
else
  pass "FULL-03 bare --skip-backup on full refused"
fi
```

**Exit pattern** (`scripts/phase12-full-smoke.sh:159-163`) — Phase 14 prints `FINDINGS` too but must not let it affect the exit code:
```bash
echo "=== done: FAIL=${FAIL} ==="
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
```

---

### `scripts/phase14-verify.sh` (script, batch checks)

**Analog:** `scripts/phase12-full-smoke.sh` (same preamble/pass/fail/exit blocks as above — do not restate, copy the same shape).

Two additional patterns from `scripts/phase13-d19-assert.sh`:

**Non-mutating constraint stated in the header** (`scripts/phase13-d19-assert.sh:2-3`) — Phase 14's verify must carry the same kind of explicit constraint line ("never kills waybar/swaync, read-only probes only"):
```bash
# Phase 13 OVL-01..03 in-repo asserts (Nyquist validation).
# Non-mutating only. Never copies onto live ~/.config/hypr/custom (D-02, D-17).
```

**Named-constant block before the checks** (`scripts/phase13-d19-assert.sh:18-22`) — Phase 14 declares `BASELINE`, `XDG`, `BACKUP_DIR` here:
```bash
SOT=".planning/phases/13-personal-hypr-custom-overlays/13-SOT-APPLY.md"
GENERAL=".config/hypr/custom/general.lua"
LIVE_CUSTOM="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/custom"
```

**Count-based content assert** (`scripts/phase13-d19-assert.sh:56-60`) — the model for asserting the 11 workspace rules and 2 monitors:
```bash
if [ -s "$GENERAL" ] && [ "$(grep -c 'hl.monitor' "$GENERAL")" -eq 2 ] && [ "$(grep -c 'hl.workspace_rule' "$GENERAL")" -eq 11 ]; then
  pass "general.lua hl.monitor==2 hl.workspace_rule==11"
else
  fail "general.lua hl.monitor==2 hl.workspace_rule==11"
fi
```

**Extract-and-execute-the-fence pattern** (`scripts/phase13-d19-assert.sh:27-53`) — the repo's established way to avoid duplicating a documented command. Phase 14 should reuse this if it wants to prove the D-08 apply fence from `13-SOT-APPLY.md` rather than re-typing it:
```bash
FENCE="$(python3 - "$SOT" <<'PY'
from pathlib import Path
import sys
text = Path(sys.argv[1]).read_text()
idx = text.find("## In-repo verify (D-19)")
...
PY
)"
TMP="$(mktemp /tmp/p13-d19-XXXXXX.sh)"
printf '%s' "$FENCE" >"$TMP"
if bash -e "$TMP"; then pass "..."; else fail "..."; fi
rm -f "$TMP"
```

**Live-probe bodies:** do not invent these — RESEARCH.md §Code Examples already contains verified, baseline-grounded blocks for ADOPT-02 (`hyprctl -j status`, `hyprctl eval`), ADOPT-03 (monitors, workspacerules, `pgrep`), D-37 (byte sizes + sidecars), and D-38 (`busctl` ScreenCast). Wrap those in the `pass`/`fail`/`finding` helpers above.

---

### `docs/phase14-adopt-runbook.md` (operator doc, human procedure)

**Analog:** `docs/dots-hyprland-workflow.md`

**Title + one-line role + Purpose block** (`docs/dots-hyprland-workflow.md:1-15`):
```markdown
# dots-hyprland workflow (illogical-impulse)

Canonical operator playbook for adopting **end-4/dots-hyprland** (illogical-impulse / `ii`) inside this `.dotfiles` repo.

## Purpose

After Phases 5–8 there is a **single product path**:

- **Fork + pin:** personal fork of end-4/dots-hyprland, submodule at `vendor/dots-hyprland`
- **Install entry:** only `arch/dots-hyprland.sh` (thin wrapper around vendor `./setup`)
```

**DRY pointer blockquote instead of re-copying help text** (`docs/dots-hyprland-workflow.md:16`) — the runbook must do the same for flag semantics:
```markdown
> **Flag / subcommand details:** keep DRY — run `./arch/dots-hyprland.sh help` for the full allowlist, safe defaults, backup gate, uninstall, and protect behavior. This doc does not re-copy the entire help text.
```

**Numbered anchor outline** (`docs/dots-hyprland-workflow.md:36-46`) — this is exactly the D-21 "single unambiguous order" device:
```markdown
## Outline

1. [Clone & recursive submodule init](#1-clone--recursive-submodule-init)
2. [Verify fork remotes & pin](#2-verify-fork-remotes--pin)
3. [Install via thin wrapper (dry-run → live)](#3-install-via-thin-wrapper-dry-run--live)
...
---
```
Numbered `## N. Title` sections follow, each with fenced `bash` blocks and inline `# expect:` comments (`docs/dots-hyprland-workflow.md:100-102`):
```bash
# expect:
#   origin   → personal fork (e.g. git@github.com:humam-hossain/dots-hyprland.git)
#   upstream → end-4 (https://github.com/end-4/dots-hyprland.git)
```

**Prerequisites section** (`:18-24`) is the shape for the go/no-go checklist inputs.

**Cross-doc `## See also` footer** (`:302`) — link back to `docs/dots-hyprland-workflow.md` and `13-SOT-APPLY.md`.

**D-39 constraint:** in this file specifically, never write "chrome". Write `Waybar/rofi/swaync`.

---

### `arch/dots-hyprland.sh` — D-28 edit (config array, 2-line delete)

**Analog:** the file itself. The target array is `PROTECT_EXPLICIT` at `arch/dots-hyprland.sh:230-295`. Verified line numbers:

- `arch/dots-hyprland.sh:251` → `  waybar` (under the `# Bar dual-run (arch/waybar.sh) — bc/jq used by waybar scripts` comment)
- `arch/dots-hyprland.sh:263` → `  swaync`

Current surrounding block (`:249-264`):
```bash
  # Bar dual-run (arch/waybar.sh) — bc/jq used by waybar scripts
  waybar
  curl
  jq
  bc
  python
  iputils
  playerctl
  pavucontrol
  networkmanager
  btop
  nautilus
  kitty
  swaync
```
Delete exactly the `waybar` and `swaync` lines. `hyprpaper` (`:233`) stays. `rofi` is not in the array — confirmed by inspection, so D-28's claim holds and no third deletion exists. The comment on `:249` references waybar scripts; the planner should decide whether to reword it (the remaining entries `curl`/`jq`/`bc` are still justified by other consumers listed at `:236` and elsewhere).

**Verification pattern:** `bash -n arch/dots-hyprland.sh` — the syntax gate at `scripts/phase12-full-smoke.sh:30-34`:
```bash
if bash -n arch/dots-hyprland.sh; then
  pass "syntax: bash -n arch/dots-hyprland.sh"
else
  fail "syntax: bash -n arch/dots-hyprland.sh"
fi
```

---

### `.planning/phases/14-live-full-adopt-verify/14-LIVE-VERIFY.md` (phase record)

**Analog:** `.planning/phases/13-personal-hypr-custom-overlays/13-SOT-APPLY.md` (role-match: a phase-directory markdown artifact that downstream scripts and phases read).

**Structure pattern** (`13-SOT-APPLY.md:1-3`, `:5-9`) — title, one-paragraph scope statement naming the decision IDs it encodes, then `## `-level sections each tagged with its decision ID:
```markdown
# Phase 13: Overlay source of truth and apply policy

Authoring SoT fence (D-01..D-05) plus the D-18 apply command and D-19 in-repo verify. Do not run apply in Phase 13 (D-02, D-17). Phase 14 runs apply.

## Authoring SoT

Authoring SoT is parent-repo `.config/hypr/custom/` (D-01, D-05). Edit overlays there. Live `~/.config/hypr/custom/` is an applied copy, not the place you edit for the next machine.
```

**Section heading carries the decision ID in parens** (`13-SOT-APPLY.md:17,21,57`): `## DP-1 scale (D-13)`, `## Apply command (D-18)`, `## In-repo verify (D-19)`. Phase 14 should mirror: `## ADOPT-02 proof (D-33)`, `## Known losses (D-38)`, `## Findings (D-14, D-38)`.

**Machine-extractable fence:** if any block in `14-LIVE-VERIFY.md` is meant to be re-executed, put it in a ```bash fence under a stable `## ` heading — that is the contract `scripts/phase13-d19-assert.sh:31` relies on (`text.find("## In-repo verify (D-19)")`).

---

### `.config/hypr/**` — D-03 live→repo sync (archive data)

**Analog:** the existing tracked `.config/hypr/` tree.

No code pattern to copy; the pattern is a **scope constraint**, per RESEARCH §"The D-03 sync is much smaller":
- Repo `.config/` holds only `hypr/`; everything else personal lives under `stow/`.
- Exactly three deltas exist: `hyprland.conf` differs; live-only `hyprland.conf.bak` and `hyprland-gui.conf`.
- Plus live-only `dolphinrc` (177 B) and `kdeglobals` (59 B) per Open Question 2.
- **Exclude** `.config/hypr/custom/` (D-03) and `~/.config/quickshell` (Phase 11 D-08).
- Enumerate the file list explicitly — never `rsync ~/.config .config/`.

---

## Shared Patterns

### Assert-script skeleton
**Source:** `scripts/phase12-full-smoke.sh:9-16` and `:159-163`
**Apply to:** both Phase 14 scripts
```bash
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"
FAIL=0
pass() { printf '[PASS] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
# ...checks...
echo "=== done: FAIL=${FAIL} ==="
[[ "$FAIL" -gt 0 ]] && exit 1
exit 0
```

### Header contract block
**Source:** `scripts/phase10-inventory-assert.sh:1-16`, `scripts/phase12-full-smoke.sh:1-7`, `scripts/phase13-d19-assert.sh:1-7`
**Apply to:** both Phase 14 scripts. Every repo assert script opens with: one-line purpose, an explicit mutation-scope statement, a `Usage (from REPO_ROOT):` block, and the exit-code contract. Phase 10 additionally carries an explicit `# Constraints (Phase N):` list — Phase 14 should use that form, since its mutation boundary (D-01, D-27) is the most load-bearing in the project:
```bash
# Constraints (Phase 10):
#   - Never rsync/cp/mv/rm into XDG or backup dirs
#   - Never call ./setup or arch/dots-hyprland.sh without --dry-run
#     (this script does not invoke either)
```

### Gate-fed wrapper invocation
**Source:** `scripts/phase12-full-smoke.sh:63`
**Apply to:** `scripts/phase14-preflight.sh` only (verify runs post-adopt and needs no dry-run)
```bash
printf 'yes\n' | "$WRAP" install --full --dry-run >"$FULL_OUT" 2>&1
```

### Temp-file + trap
**Source:** `scripts/phase12-full-smoke.sh:19-25`
**Apply to:** any Phase 14 check that captures command output
```bash
FULL_OUT="$(mktemp /tmp/p12-smoke-full-XXXXXX)"
# shellcheck disable=SC2064
trap 'rm -f "$FULL_OUT"' EXIT
```
Note `scripts/phase12-full-smoke.sh:122` and `:153` write to fixed `/tmp/p12-smoke-skip.txt` / `/tmp/p12-smoke-deps.txt` paths outside the trap — that is an inconsistency in the analog. Phase 14 should use `mktemp` uniformly, not copy the fixed-path variant.

### XDG indirection
**Source:** `scripts/phase10-inventory-assert.sh:24`, `scripts/phase13-d19-assert.sh:22`
**Apply to:** every live-filesystem path in both Phase 14 scripts
```bash
XDG="${XDG_CONFIG_HOME:-$HOME/.config}"
```

### Doc DRY pointer
**Source:** `docs/dots-hyprland-workflow.md:16`
**Apply to:** `docs/phase14-adopt-runbook.md` — point at `./arch/dots-hyprland.sh help` for flag semantics rather than restating them; point at `13-SOT-APPLY.md` for the overlay apply fence rather than rewriting it (RESEARCH §Don't Hand-Roll).

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `.planning/phases/14-live-full-adopt-verify/14-PRE-ADOPT-BASELINE.txt` | fixture | write-once, read-later | No prior phase recorded a machine-state fixture for later comparison. Use the generator block in RESEARCH.md §Pattern 3 verbatim; format is `key=value` lines so the verify script can source or grep it. |
| `.planning/phases/14-live-full-adopt-verify/14-ADOPT-TRANSCRIPT.txt` | raw evidence | `script(1)` capture | No prior phase captured a TTY transcript. Per RESEARCH Open Question 3: commit raw, output-only (no `--log-io`, which would capture sudo passwords). |
| `.gitignore` (`.gsd/` entry) | config | n/a | Trivial one-line append; existing patterns in `.gitignore` are the only pattern needed. Required because RESEARCH Pitfall 1 shows D-35's clean-tree assert can never pass otherwise. |

## Metadata

**Analog search scope:** `scripts/`, `docs/`, `arch/`, `.planning/phases/1{0,1,2,3}-*/`, `.config/hypr/`
**Files scanned:** 11 candidates; 6 read and excerpted
**Tracked-source gate:** all 6 analogs confirmed via `git ls-files`
**Pattern extraction date:** 2026-09-04
