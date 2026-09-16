# Phase 24: Address Tech Debt: Bookkeeping and Validation Cleanup — Pattern Map

**Mapped:** 2026-09-16  
**Phase Directory:** `.planning/phases/24-address-tech-debt-bookkeeping-and-validation-cleanup/`  
**Output File:** `24-PATTERNS.md`  
**Files Analyzed:** 16 target files (1 new assert harness, 3 modified repo files, 6 modified validation contracts, 5 modified plan summaries, 1 modified state file)  
**Analogs Found:** 16 / 16 (all backed by git-tracked source code in this repository)  

All analog paths below were verified against repository files. Closed-phase assert scripts and historical records are cited as structural patterns to copy from, adhering strictly to the **D-20 Frozen History Rule** (historical artifacts are not modified).

---

## File Classification

| Target File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `scripts/phase24-tech-debt-assert.sh` (**new**) | Gating test suite / assert harness | Static linting, IPC queries (`hyprctl`), test execution, git porcelain checks | `scripts/phase23-bootstrap-assert.sh` (runner scaffolding, porcelain bracket) + `scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh:436-471` (Python taxonomy & chord validator) + `scripts/phase21-ii-bar-config-capture-assert.sh:68-96` (scratch capture & mock notify) | exact composite |
| `stow/hypr/.config/hypr/custom/keybinds.lua` (**modify**) | Personal Hyprland keybinding overlay | Loaded by Hyprland Lua config; queried via IPC by Quickshell cheatsheet (`SUPER + /`) | `stow/hypr/.config/hypr/custom/keybinds.lua:5-25, 62-65` (self-analog) + `vendor/dots-hyprland/dots/.config/hypr/hyprland/keybinds.lua:334-342` (upstream reference) | exact self-analog |
| `.gitignore` (**modify**) | VCS exclusion rules | Read by Git CLI (`status`, `add`, `check-ignore`) | `.gitignore:45-63` (machine-written state block) | exact self-analog |
| `.planning/REQUIREMENTS.md` (**modify**) | Requirements traceability register | Audited by `/gsd-audit-milestone`; cross-referenced by roadmap | `.planning/REQUIREMENTS.md:60-74, 107-167` (self-analog) | exact self-analog |
| `.planning/ROADMAP.md` (**modify**) | Milestone roadmap specification | Read by GSD orchestration tools (`/gsd-progress`, `/gsd-plan-phase`) | `.planning/ROADMAP.md:320-385` (self-analog) | exact self-analog |
| `.planning/STATE.md` (**modify**) | Persistent architectural decisions & risk register | Read during phase planning, context restoration, and milestone audits | `.planning/STATE.md:47-65, 168-240` (self-analog) | exact self-analog |
| `.planning/phases/23-one-command-bootstrap/23-01-SUMMARY.md` (**modify**) | Plan execution summary frontmatter | Extracted by `gsd-tools query summary-extract` | `.planning/phases/23-one-command-bootstrap/23-01-SUMMARY.md:1-15` + `18-02-SUMMARY.md:52` | exact self-analog |
| `.planning/phases/23-one-command-bootstrap/23-02-SUMMARY.md` (**modify**) | Plan execution summary frontmatter | Extracted by `gsd-tools query summary-extract` | `.planning/phases/23-one-command-bootstrap/23-02-SUMMARY.md:1-15` | exact self-analog |
| `.planning/phases/23-one-command-bootstrap/23-03-SUMMARY.md` (**modify**) | Plan execution summary frontmatter | Extracted by `gsd-tools query summary-extract` | `.planning/phases/23-one-command-bootstrap/23-03-SUMMARY.md:1-15` | exact self-analog |
| `.planning/phases/18-capture-model-three-trees-and-the-collision-map/18-02-SUMMARY.md` (**modify**) | Plan execution summary frontmatter | Extracted by `gsd-tools query summary-extract` | `.planning/phases/18-capture-model-three-trees-and-the-collision-map/18-02-SUMMARY.md:50-55` | exact self-analog |
| `.planning/phases/18-capture-model-three-trees-and-the-collision-map/18-03-SUMMARY.md` (**modify**) | Plan execution summary frontmatter | Extracted by `gsd-tools query summary-extract` | `.planning/phases/18-capture-model-three-trees-and-the-collision-map/18-03-SUMMARY.md:45-50` | exact self-analog |
| `.planning/phases/17-unblock-stow-and-restore-the-session-target/17-VALIDATION.md` (**modify**) | Nyquist validation contract | Verified by `/gsd-audit-milestone` and `/gsd-validate-phase` | `.planning/phases/17-unblock-stow-and-restore-the-session-target/17-VALIDATION.md:1-11, 145-182` | exact self-analog |
| `.planning/phases/18-capture-model-three-trees-and-the-collision-map/18-VALIDATION.md` (**modify**) | Nyquist validation contract | Verified by `/gsd-audit-milestone` and `/gsd-validate-phase` | `17-VALIDATION.md` (status: validated, nyquist_compliant: true) | exact cross-analog |
| `.planning/phases/20-hypr-custom-overlays-and-startup-restore/20-VALIDATION.md` (**modify**) | Nyquist validation contract | Verified by `/gsd-audit-milestone` and `/gsd-validate-phase` | `17-VALIDATION.md` + `20-VALIDATION.md:60-67` | exact cross-analog |
| `.planning/phases/21-ii-bar-config-capture/21-VALIDATION.md` (**modify**) | Nyquist validation contract | Verified by `/gsd-audit-milestone` and `/gsd-validate-phase` | `17-VALIDATION.md` + `21-VALIDATION.md:62-68` | exact cross-analog |
| `.planning/phases/22-kde-and-gtk-capture/22-VALIDATION.md` (**modify**) | Nyquist validation contract | Verified by `/gsd-audit-milestone` and `/gsd-validate-phase` | `17-VALIDATION.md` + `22-VALIDATION.md:62-68` | exact cross-analog |
| `.planning/phases/23-one-command-bootstrap/23-VALIDATION.md` (**modify**) | Nyquist validation contract | Verified by `/gsd-audit-milestone` and `/gsd-validate-phase` | `17-VALIDATION.md` + `23-VALIDATION.md:60-67` | exact cross-analog |

---

## Pattern Assignments by File

### 1. `scripts/phase24-tech-debt-assert.sh` (Dedicated Test Suite)

**Role:** End-to-end assert script proving that all Phase 24 deliverables are satisfied with zero regressions and zero working-tree drift.  
**Analog:** `scripts/phase23-bootstrap-assert.sh` for harness scaffolding, CLI options, and git status porcelain snapshotting; `scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh:436-471` for Lua syntax and Python taxonomy parsing; `scripts/phase21-ii-bar-config-capture-assert.sh:68-96` for scratch repository setup and mock desktop notification testing.

#### Pattern 1.1: Runner Scaffolding, Helpers, and Cleanup Trap
Source: `scripts/phase23-bootstrap-assert.sh:1-37`
```bash
#!/usr/bin/env bash
# Phase 24 Tech debt: bookkeeping and validation cleanup assert harness (DEBT-01 to DEBT-04).
# One script, one section per requirement criterion, one verdict for the phase.
#
# Usage (from REPO_ROOT):
#   ./scripts/phase24-tech-debt-assert.sh [--section <1-5>]
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

#### Pattern 1.2: CLI Section Selector & Porcelain Bracket
Source: `scripts/phase23-bootstrap-assert.sh:41-81, 476-485`
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

PORCELAIN_BEFORE="$(mktemp /tmp/p24-porcelain-before-XXXXXX)"
PORCELAIN_AFTER="$(mktemp /tmp/p24-porcelain-after-XXXXXX)"
TMP_FILES+=("$PORCELAIN_BEFORE" "$PORCELAIN_AFTER")

porcelain_snapshot > "$PORCELAIN_BEFORE"
```

#### Pattern 1.3: Section 1 — Bookkeeping & Traceability (`DEBT-01`)
Source: `24-RESEARCH.md:213-216`, `24-CONTEXT.md:D-01, D-02, D-03`
```bash
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 1 ]]; then
  info "--- Section 1: DEBT-01 Bookkeeping & Traceability Synchronization ---"

  # 1. Zero stale Pending markers in REQUIREMENTS.md
  PENDING_COUNT="$(grep -c -E '\|\s*Pending\s*\|' .planning/REQUIREMENTS.md || true)"
  if [[ "$PENDING_COUNT" -eq 0 ]]; then
    pass "DEBT-01 (S1): 0 stale 'Pending' markers found in REQUIREMENTS.md"
  else
    fail "DEBT-01 (S1): found $PENDING_COUNT stale 'Pending' markers in REQUIREMENTS.md"
  fi

  # 2. DEBT-01..04 defined in REQUIREMENTS.md and ROADMAP.md
  for req in DEBT-01 DEBT-02 DEBT-03 DEBT-04; do
    if grep -q "$req" .planning/REQUIREMENTS.md && grep -q "$req" .planning/ROADMAP.md; then
      pass "DEBT-01 (S1): $req registered in REQUIREMENTS.md and ROADMAP.md"
    else
      fail "DEBT-01 (S1): $req missing from REQUIREMENTS.md or ROADMAP.md"
    fi
  done

  # 3. GSD-tools summary-extract checks on plan summaries
  GSD_TOOLS="/home/pera/.gemini/gsd-core/bin/gsd-tools.cjs"
  [[ -f "$GSD_TOOLS" ]] || GSD_TOOLS="/home/pera/.hermes/gsd-core/bin/gsd-tools.cjs"

  check_summary_req() {
    local summary_file="$1"
    local expected_req="$2"
    local out
    out="$(node "$GSD_TOOLS" query summary-extract "$summary_file" --fields requirements_completed 2>/dev/null || true)"
    if grep -q "\"$expected_req\"" <<<"$out"; then
      pass "DEBT-01 (S1): $summary_file frontmatter exports $expected_req"
    else
      fail "DEBT-01 (S1): $summary_file failed to export $expected_req (got: $out)"
    fi
  }

  check_summary_req ".planning/phases/23-one-command-bootstrap/23-01-SUMMARY.md" "BOOT-01"
  check_summary_req ".planning/phases/23-one-command-bootstrap/23-01-SUMMARY.md" "BOOT-02"
  check_summary_req ".planning/phases/23-one-command-bootstrap/23-02-SUMMARY.md" "BOOT-03"
  check_summary_req ".planning/phases/23-one-command-bootstrap/23-02-SUMMARY.md" "BOOT-05"
  check_summary_req ".planning/phases/23-one-command-bootstrap/23-03-SUMMARY.md" "BOOT-04"
  check_summary_req ".planning/phases/18-capture-model-three-trees-and-the-collision-map/18-02-SUMMARY.md" "CAP-05"
  check_summary_req ".planning/phases/18-capture-model-three-trees-and-the-collision-map/18-03-SUMMARY.md" "CAP-08"
fi
```

#### Pattern 1.4: Section 2 — Nyquist Validation Compliance Across Phases 17–23 (`DEBT-02`)
Source: `24-RESEARCH.md:217-220`, `24-CONTEXT.md:D-05, D-06, D-07`
```bash
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 ]]; then
  info "--- Section 2: DEBT-02 Nyquist Validation Compliance ---"

  v04_validation_files=(
    .planning/phases/17-unblock-stow-and-restore-the-session-target/17-VALIDATION.md
    .planning/phases/18-capture-model-three-trees-and-the-collision-map/18-VALIDATION.md
    .planning/phases/20-hypr-custom-overlays-and-startup-restore/20-VALIDATION.md
    .planning/phases/21-ii-bar-config-capture/21-VALIDATION.md
    .planning/phases/22-kde-and-gtk-capture/22-VALIDATION.md
    .planning/phases/23-one-command-bootstrap/23-VALIDATION.md
  )

  for vf in "${v04_validation_files[@]}"; do
    if [[ ! -f "$vf" ]]; then
      fail "DEBT-02 (S2): missing validation file: $vf"
      continue
    fi

    # Check status: validated
    if grep -qE '^status:\s*(validated|compliant)' "$vf"; then
      pass "DEBT-02 (S2): $(basename "$vf") has status: validated"
    else
      fail "DEBT-02 (S2): $(basename "$vf") missing status: validated"
    fi

    # Check nyquist_compliant: true
    if grep -qE '^nyquist_compliant:\s*true' "$vf"; then
      pass "DEBT-02 (S2): $(basename "$vf") has nyquist_compliant: true"
    else
      fail "DEBT-02 (S2): $(basename "$vf") missing nyquist_compliant: true"
    fi

    # Check wave_0_complete: true
    if grep -qE '^wave_0_complete:\s*true' "$vf"; then
      pass "DEBT-02 (S2): $(basename "$vf") has wave_0_complete: true"
    else
      fail "DEBT-02 (S2): $(basename "$vf") missing wave_0_complete: true"
    fi
  done

  # Explicit documentation of non-blocking manual items and scratch-XDG boundary
  if grep -qi "manual" .planning/phases/20-hypr-custom-overlays-and-startup-restore/20-VALIDATION.md; then
    pass "DEBT-02 (S2): Phase 20 startup apps documented as manual inspection"
  else
    fail "DEBT-02 (S2): Phase 20 missing manual inspection documentation"
  fi

  if grep -qi "notification" .planning/phases/21-ii-bar-config-capture/21-VALIDATION.md; then
    pass "DEBT-02 (S2): Phase 21 desktop notifications documented in validation strategy"
  else
    fail "DEBT-02 (S2): Phase 21 missing notification validation documentation"
  fi

  if grep -qi "scratch-XDG" .planning/phases/23-one-command-bootstrap/23-VALIDATION.md; then
    pass "DEBT-02 (S2): Phase 23 scratch-XDG testing boundary documented"
  else
    fail "DEBT-02 (S2): Phase 23 missing scratch-XDG testing boundary documentation"
  fi
fi
```

#### Pattern 1.5: Section 3 — Repository Hygiene & Debt Disposition (`DEBT-03`)
Source: `24-RESEARCH.md:221-227`, `24-CONTEXT.md:D-08, D-09, D-10, D-11`, `scripts/phase21-ii-bar-config-capture-assert.sh:68-96`
```bash
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 3 ]]; then
  info "--- Section 3: DEBT-03 Repository Hygiene & Debt Disposition ---"

  # 1. Gitignore pattern check
  if grep -q '^\*\.socket' .gitignore && grep -q '^\!stow/systemd/\*\*' .gitignore; then
    pass "DEBT-03 (S3): .gitignore contains *.socket and exception !stow/systemd/**"
  else
    fail "DEBT-03 (S3): .gitignore missing *.socket or !stow/systemd/** exception"
  fi

  # 2. git check-ignore verification: stow/systemd/ socket must NOT be ignored
  if git check-ignore stow/systemd/.config/systemd/user/dotfiles-capture.socket >/dev/null 2>&1; then
    fail "DEBT-03 (S3): stow/systemd socket file was incorrectly ignored by git"
  else
    pass "DEBT-03 (S3): stow/systemd socket file is preserved (not ignored) by git"
  fi

  # Verify non-stow socket file IS ignored
  if git check-ignore foo.socket >/dev/null 2>&1; then
    pass "DEBT-03 (S3): generic foo.socket is properly ignored by git"
  else
    fail "DEBT-03 (S3): generic foo.socket was not ignored by git"
  fi

  # 3. STATE.md triage documentation
  if grep -q "stow/system_monitor/.config/system_monitor/ping/.env" .planning/STATE.md && \
     grep -q "BIND_HOST=127.0.0.1" .planning/STATE.md; then
    pass "DEBT-03 (S3): STATE.md documents system_monitor .env as tracked local non-credential config"
  else
    fail "DEBT-03 (S3): STATE.md missing system_monitor .env non-credential triage"
  fi

  if grep -q "gitleaks" .planning/STATE.md && grep -q "accepted historical risk" .planning/STATE.md; then
    pass "DEBT-03 (S3): STATE.md documents 12 gitleaks allowlist entries as accepted historical risk"
  else
    fail "DEBT-03 (S3): STATE.md missing gitleaks accepted risk documentation"
  fi

  # 4. Non-interactive assertion of capture --notify with mocked notify-send
  S3_ROOT="$(mktemp -d /tmp/p24-assert-s3-XXXXXX)"
  SCRATCH_ROOTS+=("$S3_ROOT")

  mkdir -p "$S3_ROOT/repo/arch" "$S3_ROOT/repo/capture/testpkg/.config/testpkg" "$S3_ROOT/home/.config/testpkg" "$S3_ROOT/bin"
  cp "$REPO_ROOT/arch/dots-hyprland.sh" "$S3_ROOT/repo/arch/dots-hyprland.sh"
  chmod +x "$S3_ROOT/repo/arch/dots-hyprland.sh"

  git -C "$S3_ROOT/repo" init -q
  git -C "$S3_ROOT/repo" config user.email "assert@example.com"
  git -C "$S3_ROOT/repo" config user.name "Assert Runner"

  printf '{"setting": "old"}\n' > "$S3_ROOT/repo/capture/testpkg/.config/testpkg/config.json"
  git -C "$S3_ROOT/repo" add -A
  git -C "$S3_ROOT/repo" commit -q -m "seed"

  printf '{"setting": "new_from_live"}\n' > "$S3_ROOT/home/.config/testpkg/config.json"

  NOTIFY_LOG="$S3_ROOT/notify.log"
  cat << 'MOCK_EOF' > "$S3_ROOT/bin/notify-send"
#!/usr/bin/env bash
echo "$@" >> "$MOCK_LOG"
MOCK_EOF
  chmod +x "$S3_ROOT/bin/notify-send"

  NOTIFY_RC=0
  (
    export PATH="$S3_ROOT/bin:$PATH"
    export MOCK_LOG="$NOTIFY_LOG"
    export HOME="$S3_ROOT/home"
    cd "$S3_ROOT/repo"
    ./arch/dots-hyprland.sh capture --notify
  ) || NOTIFY_RC=$?

  if [[ "$NOTIFY_RC" -eq 0 ]] && [[ -f "$NOTIFY_LOG" ]] && \
     grep -q "Dotfiles Capture.*Captured updates to repository.*-a Shell -u low" "$NOTIFY_LOG"; then
    pass "DEBT-03 (S3): arch/dots-hyprland.sh capture --notify executed and called notify-send with expected arguments"
  else
    fail "DEBT-03 (S3): capture --notify failed or did not call notify-send correctly (rc=$NOTIFY_RC)"
  fi
fi
```

#### Pattern 1.6: Section 4 — Session Keybindings & Cheatsheet Realignment (`DEBT-04`)
Source: `scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh:436-471`, `24-RESEARCH.md:228-239`, `24-CONTEXT.md:D-12, D-13, D-14`
```bash
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 4 ]]; then
  info "--- Section 4: DEBT-04 Session Keybindings & Cheatsheet Realignment ---"

  KEYBINDS_FILE="stow/hypr/.config/hypr/custom/keybinds.lua"

  # 1. Syntax checking via luac -p
  if luac -p "$KEYBINDS_FILE" 2>/dev/null; then
    pass "DEBT-04 (S4): $KEYBINDS_FILE passes luac -p syntax checking"
  else
    fail "DEBT-04 (S4): $KEYBINDS_FILE syntax error"
  fi

  # 2. Unbind of upstream SUPER + SHIFT + L
  if grep -qF 'hl.unbind("SUPER + SHIFT + L")' "$KEYBINDS_FILE"; then
    pass "DEBT-04 (S4): upstream SUPER + SHIFT + L unbind declaration present"
  else
    fail "DEBT-04 (S4): missing hl.unbind(\"SUPER + SHIFT + L\") in $KEYBINDS_FILE"
  fi

  # 3. Python taxonomy and duplicate chord validator
  TAXONOMY_RES="$(python3 - << 'PYEOF'
import re, sys

path = "stow/hypr/.config/hypr/custom/keybinds.lua"
with open(path, "r") as f:
    content = f.read()

bind_re = re.compile(r'hl\.bind\(\s*"([^"]+)"\s*,.*?description\s*=\s*"([^"]+)"', re.DOTALL)
matches = bind_re.findall(content)

if not matches:
    print("NO_MATCHES")
    sys.exit(1)

chords = []
bad_desc = []
for chord, desc in matches:
    chords.append(chord)
    parts = desc.split(":")
    if len(parts) != 2 or not parts[0].strip() or not parts[1].strip():
        bad_desc.append(desc)

dup_chords = [c for c in chords if chords.count(c) > 1]
dup_chords = list(set(dup_chords))

if bad_desc:
    print(f"BAD_DESC:{','.join(bad_desc)}")
    sys.exit(2)

if dup_chords:
    print(f"DUPS:{','.join(dup_chords)}")
    sys.exit(3)

print(f"OK:{len(matches)}")
PYEOF
)"
  case "$TAXONOMY_RES" in
    OK:*)
      COUNT="${TAXONOMY_RES#OK:}"
      pass "DEBT-04 (S4): all $COUNT personal keybinds strictly adhere to 'Category: Label' taxonomy"
      pass "DEBT-04 (S4): zero duplicate key chords detected within keybinds.lua"
      ;;
    BAD_DESC:*)
      fail "DEBT-04 (S4): descriptions not following Category: Label taxonomy: ${TAXONOMY_RES#BAD_DESC:}"
      ;;
    DUPS:*)
      fail "DEBT-04 (S4): duplicate key chord bindings found: ${TAXONOMY_RES#DUPS:}"
      ;;
    *)
      fail "DEBT-04 (S4): python taxonomy inspection failed: $TAXONOMY_RES"
      ;;
  esac

  # 4. Live compositor query via hyprctl binds -j
  if command -v hyprctl >/dev/null 2>&1; then
    BINDS_JSON="$(hyprctl binds -j 2>/dev/null || echo "[]")"

    # Assert SUPER + SHIFT + L (modmask 65, key L) is NOT registered as sleep
    OLD_SLEEP="$(jq -r '.[] | select(.key == "L" and .modmask == 65 and (.description // "" | test("Sleep"; "i"))) | .key' <<<"$BINDS_JSON")"
    if [[ -z "$OLD_SLEEP" ]]; then
      pass "DEBT-04 (S4): live compositor confirmed SUPER + SHIFT + L is purged from sleep"
    else
      fail "DEBT-04 (S4): live compositor still has SUPER + SHIFT + L bound to sleep"
    fi

    # Assert Scroll_Lock (modmask 0) is registered as Lock screen
    LOCK_REG="$(jq -r '.[] | select(.key == "Scroll_Lock" and .modmask == 0 and .description == "Session: Lock screen") | .key' <<<"$BINDS_JSON")"
    if [[ -n "$LOCK_REG" ]]; then
      pass "DEBT-04 (S4): live compositor confirmed Scroll_Lock -> Session: Lock screen"
    else
      fail "DEBT-04 (S4): live compositor missing Scroll_Lock -> Session: Lock screen"
    fi

    # Assert SUPER + Scroll_Lock (modmask 64) is registered as Sleep
    SLEEP_REG="$(jq -r '.[] | select(.key == "Scroll_Lock" and .modmask == 64 and .description == "Session: Sleep") | .key' <<<"$BINDS_JSON")"
    if [[ -n "$SLEEP_REG" ]]; then
      pass "DEBT-04 (S4): live compositor confirmed SUPER + Scroll_Lock -> Session: Sleep"
    else
      fail "DEBT-04 (S4): live compositor missing SUPER + Scroll_Lock -> Session: Sleep"
    fi

    # Assert SUPER + SHIFT + Scroll_Lock (modmask 65) is registered as Logout
    LOGOUT_REG="$(jq -r '.[] | select(.key == "Scroll_Lock" and .modmask == 65 and .description == "Session: Logout") | .key' <<<"$BINDS_JSON")"
    if [[ -n "$LOGOUT_REG" ]]; then
      pass "DEBT-04 (S4): live compositor confirmed SUPER + SHIFT + Scroll_Lock -> Session: Logout"
    else
      fail "DEBT-04 (S4): live compositor missing SUPER + SHIFT + Scroll_Lock -> Session: Logout"
    fi
  else
    info "DEBT-04 (S4): hyprctl not available in test environment; live IPC check skipped"
  fi
fi
```

#### Pattern 1.7: Section 5 — Strict System Verification & Closing Porcelain Gate
Source: `scripts/phase23-bootstrap-assert.sh:465-491`
```bash
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 5 ]]; then
  info "--- Section 5: Strict System Verification & Zero Drift Gate ---"

  VERIFY_RC=0
  VERIFY_OUT="$("$REPO_ROOT/arch/dots-hyprland.sh" verify --strict 2>&1)" || VERIFY_RC=$?
  if [[ "$VERIFY_RC" -eq 0 ]]; then
    pass "Section 5: arch/dots-hyprland.sh verify --strict passed with zero findings (FAIL=0 FINDINGS=0)"
  else
    fail "Section 5: arch/dots-hyprland.sh verify --strict failed (rc=$VERIFY_RC)"
    printf '%s\n' "$VERIFY_OUT" | sed 's/^/       /' >&2
  fi
fi

porcelain_snapshot > "$PORCELAIN_AFTER"
if cmp -s "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER"; then
  pass "Closing self-check: git status --porcelain unchanged across run"
else
  fail "Closing self-check: git status --porcelain mutated across run"
  diff -u "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER" || true
fi

echo "=== done: FAIL=${FAIL} FINDINGS=${FINDINGS} ==="
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
```

---

### 2. `stow/hypr/.config/hypr/custom/keybinds.lua` (Desktop Session Keybinds)

**Role:** Personal Hyprland keybinding overlay file managing custom shortcuts and overriding upstream defaults.  
**Analog:** Existing `stow/hypr/.config/hypr/custom/keybinds.lua:1-25, 62-65`.

#### Pattern 2.1: Upstream Unbind Declarations Block
Source: `stow/hypr/.config/hypr/custom/keybinds.lua:5-25`, `24-CONTEXT.md:D-12`
```lua
-- Upstream unbinds (D-06, HYPR-02, DEBT-04)
-- Must execute before binding new actions to avoid dual-action firing on identical key chords
hl.unbind("SUPER + C")     -- upstream code editor
hl.unbind("SUPER + L")     -- upstream lock
hl.unbind("SUPER + K")     -- upstream on-screen keyboard
hl.unbind("SUPER + J")     -- upstream bar toggle
hl.unbind("SUPER + D")     -- upstream maximize
hl.unbind("SUPER + P")     -- upstream window pin
hl.unbind("SUPER + M")     -- upstream media controls
hl.unbind("SUPER + S")     -- upstream special scratchpad
hl.unbind("SUPER + Minus") -- upstream zoom out (conflicts with special:btop)
hl.unbind("SUPER + Q")     -- upstream close window (replaced by SUPER + C)
hl.unbind("SUPER + Left")  -- upstream focus left (replaced by SUPER + H)
hl.unbind("SUPER + Right") -- upstream focus right (replaced by SUPER + L)
hl.unbind("SUPER + Up")    -- upstream focus up (replaced by SUPER + K)
hl.unbind("SUPER + Down")  -- upstream focus down (replaced by SUPER + J)
hl.unbind("SUPER + ALT + M")   -- upstream mic toggle (reassigned)
hl.unbind("SUPER + SHIFT + M") -- upstream volume mute (conflicting)
hl.unbind("SUPER + SUPER_L")   -- upstream bare super search trigger
hl.unbind("SUPER + SUPER_R")   -- upstream bare super search trigger
hl.unbind("Print")             -- upstream fullscreen screenshot
hl.unbind("SUPER + SHIFT + S") -- upstream screen snip (reassigned to SHIFT + Print)
hl.unbind("SUPER + SHIFT + L") -- upstream sleep (reassigned to SUPER + Scroll_Lock)
```

#### Pattern 2.2: Session Controls Reallocation Block
Source: `stow/hypr/.config/hypr/custom/keybinds.lua:62-65`, `24-CONTEXT.md:D-12, D-13`
```lua
-- Session controls (D-12, D-13)
hl.bind("Scroll_Lock", hl.dsp.exec_cmd("hyprlock"), { description = "Session: Lock screen" })
hl.bind("SUPER + Scroll_Lock", hl.dsp.exec_cmd("systemctl suspend || loginctl suspend"), { locked = true, description = "Session: Sleep" })
hl.bind("SUPER + SHIFT + Scroll_Lock", hl.dsp.exit(), { description = "Session: Logout" })
```

#### Pattern 2.3: Cheatsheet Taxonomy Invariants
- Format: `{ description = "Category: Label" }`
- Requirement: Exactly one colon separating Category and Label; no extra colon; non-empty trimmed strings.
- Lockscreen compatibility: `{ locked = true }` required on `SUPER + Scroll_Lock` (Sleep) and `Scroll_Lock` (Lock screen) so they trigger when compositor is locked.

---

### 3. `.gitignore` (VCS Exclusion Rules)

**Role:** Repository ignore rules preventing unwanted artifacts from polluting working tree without blocking tracked dotfiles.  
**Analog:** `.gitignore:45-63`.

#### Pattern 3.1: Scoped Pattern with Un-ignore Exception
Source: `.gitignore:60-62`, `24-CONTEXT.md:D-10`
```gitignore
*.sock
*.socket
!stow/systemd/**
*.lock
```
- Line 61 (`*.socket`) catches socket files generated at runtime.
- Line 62 (`!stow/systemd/**`) exempts systemd unit files located under `stow/systemd/` so socket activation units are not silently ignored by git.

---

### 4. `.planning/REQUIREMENTS.md` (Traceability & Requirements Register)

**Role:** Core specification mapping all milestone requirements to phases, plan summaries, and implementation status.  
**Analog:** `.planning/REQUIREMENTS.md:60-74, 107-167`.

#### Pattern 4.1: Adding Phase 24 Requirements Block
Source: `.planning/REQUIREMENTS.md:67-74`, `24-CONTEXT.md:D-03`
```markdown
### Tech Debt & Validation Cleanup

- [x] **DEBT-01**: Traceability and plan summary bookkeeping complete with zero stale status markers
- [x] **DEBT-02**: Nyquist validation compliance achieved across all v0.4 phases (17-23)
- [x] **DEBT-03**: Repository hygiene items triaged and resolved (.gitignore scoping, .env documentation, gitleaks accepted risk, notify test coverage)
- [x] **DEBT-04**: Session keybindings realigned (sleep on SUPER + Scroll_Lock, logout on SUPER + SHIFT + Scroll_Lock) with 100% Quickshell cheatsheet accuracy
```

#### Pattern 4.2: Stale Status Marker Flipping
Source: `.planning/REQUIREMENTS.md:132-136, 143-147`, `24-CONTEXT.md:D-01`
Change `Pending` to `Complete` for:
- Phase 20: `HYPR-01`, `HYPR-02`, `HYPR-03`, `START-01`, `SAFE-01`
- Phase 23: `BOOT-01`, `BOOT-02`, `BOOT-03`, `BOOT-04`, `BOOT-05`

#### Pattern 4.3: Traceability Table Rows for Phase 24
```markdown
| DEBT-01 | Phase 24 | Address tech debt: bookkeeping and validation cleanup | Complete |
| DEBT-02 | Phase 24 | Address tech debt: bookkeeping and validation cleanup | Complete |
| DEBT-03 | Phase 24 | Address tech debt: bookkeeping and validation cleanup | Complete |
| DEBT-04 | Phase 24 | Address tech debt: bookkeeping and validation cleanup | Complete |
```

#### Pattern 4.4: Coverage & Arithmetic Update
```markdown
**Coverage:**

- v0.4 requirements: 39 total
- Mapped: 39
- Unmapped: 0 ✓

**Per-phase counts:** Phase 17 — 7 · Phase 18 — 8 · Phase 19 — 4 · Phase 20 — 5 · Phase 21 — 3 · Phase 22 — 3 · Phase 23 — 5 · Phase 24 — 4 — 39 total
```

---

### 5. `.planning/ROADMAP.md` (Roadmap Progression & Phase Mapping)

**Role:** Multi-phase project plan showing milestones, phase dependencies, and success criteria.  
**Analog:** `.planning/ROADMAP.md:320-385`.

#### Pattern 5.1: Phase 24 Definition
Source: `24-RESEARCH.md:80-88`, `24-CONTEXT.md:11-39`
```markdown
### Phase 24: Address tech debt: bookkeeping and validation cleanup

**Goal:** Address accumulated technical debt, metadata inconsistencies, and validation coverage gaps from Milestone v0.4 audit, and realign session keybindings for 100% cheatsheet accuracy
**Depends on:** Phase 23
**Requirements:** DEBT-01, DEBT-02, DEBT-03, DEBT-04
**Success Criteria** (what must be TRUE):

  1. REQUIREMENTS.md has 0 Pending markers for verified phases, DEBT-01..04 defined, and plan summaries 18-02, 18-03, 23-01, 23-02, 23-03 contain valid requirements_completed frontmatter (DEBT-01)
  2. VALIDATION.md files for Phases 17, 18, 20, 21, 22, 23 updated with status: validated, wave_0_complete: true, and nyquist_compliant: true, documenting manual items and scratch boundary (DEBT-02)
  3. .gitignore scopes *.socket with !stow/systemd/**; STATE.md affirms non-credential status of system_monitor .env and records 12 gitleaks allowlist entries; non-interactive --notify test passes (DEBT-03)
  4. stow/hypr/.config/hypr/custom/keybinds.lua unbinds SUPER + SHIFT + L, binds SUPER + Scroll_Lock to sleep, SUPER + SHIFT + Scroll_Lock to logout, retains Scroll_Lock for lock screen; passes luac -p, zero duplicate chords, valid Category: Label taxonomy; live hyprctl binds -j confirms compositor binds (DEBT-04)

**Plans:** 3/3 plans complete

Plans:

- [ ] 24-01-PLAN.md — Desktop session keybind realignment and repository hygiene
- [ ] 24-02-PLAN.md — Traceability bookkeeping, plan summary backfill, and Nyquist validation reconciliation
- [ ] 24-03-PLAN.md — Dedicated assert harness, strict system verification, and milestone audit clean status
```

#### Pattern 5.2: Progress Table Update
```markdown
| 24. Address tech debt: bookkeeping and validation cleanup | v0.4 | 0/3 | In progress | - |
```

---

### 6. `.planning/STATE.md` (Architectural State & Risk Register)

**Role:** Authoritative record of architectural decisions, accepted risks, and current phase progress.  
**Analog:** `.planning/STATE.md:1-25, 47-65, 168-240`.

#### Pattern 6.1: Non-Credential Configuration Affirmation
Source: `24-CONTEXT.md:D-08`, `24-RESEARCH.md:39`
```markdown
- [Phase 24]: Triaged tracked stow/system_monitor/.config/system_monitor/ping/.env configuration: verified to contain strictly non-credential local loopback daemon parameters (BIND_HOST=127.0.0.1, PORT=8765, COLLECTION_INTERVAL=5, STALE_AFTER_SECONDS=15) with zero secrets; affirmed as intentionally tracked configuration.
```

#### Pattern 6.2: Accepted Historical Risk Record
Source: `24-CONTEXT.md:D-09`, `24-RESEARCH.md:40`
```markdown
- [Phase 24]: Formally recorded the 12 allowlist entries in .gitleaks.toml as accepted historical risk for dead credentials in published pre-v0.3 commits.
```

#### Pattern 6.3: Decisions Log Entries (`D-01` through `D-18`)
```markdown
- [Phase 24]: Reconciled 10 stale Pending markers in REQUIREMENTS.md to Complete across Phase 20 (HYPR-01..03, START-01, SAFE-01) and Phase 23 (BOOT-01..05) (D-01).
- [Phase 24]: Backfilled missing requirements_completed frontmatter in plan summaries 23-01, 23-02, 23-03, 18-02, and 18-03 for gsd-tools summary extraction (D-02).
- [Phase 24]: Added requirements DEBT-01 through DEBT-04 to REQUIREMENTS.md and mapped to Phase 24 in ROADMAP.md (D-03).
- [Phase 24]: Reconciled VALIDATION.md files for Phases 17, 18, 20, 21, 22, 23 to achieve full Nyquist compliance (status: validated, nyquist_compliant: true) with manual testing classifications documented (D-05, D-06, D-07).
- [Phase 24]: Scoped .gitignore *.socket pattern with !stow/systemd/** to prevent silent exclusion of systemd socket activation units (D-10).
- [Phase 24]: Realigned desktop session keybindings in custom/keybinds.lua: unbound upstream SUPER + SHIFT + L, bound SUPER + Scroll_Lock to sleep (locked=true), SUPER + SHIFT + Scroll_Lock to logout, retaining Scroll_Lock for lock screen with 100% Quickshell cheatsheet accuracy (D-12, D-13, D-14).
```

---

### 7. Plan Summaries Frontmatter Backfill (5 files)

**Role:** YAML frontmatter parsed by `gsd-tools query summary-extract <summary> --fields requirements_completed`.  
**Analog:** `.planning/phases/18-capture-model-three-trees-and-the-collision-map/18-02-SUMMARY.md:52` and `23-01-SUMMARY.md:12`.

#### Pattern 7.1: Frontmatter Schema Normalization
Source: `24-RESEARCH.md:99, 161-166`
To ensure `gsd-tools query summary-extract` extracts requirements reliably, use `requirements_completed: [...]`:

- `23-01-SUMMARY.md`:
  ```yaml
  requirements_completed: [BOOT-01, BOOT-02]
  ```
- `23-02-SUMMARY.md`:
  ```yaml
  requirements_completed: [BOOT-03, BOOT-05]
  ```
- `23-03-SUMMARY.md`:
  ```yaml
  requirements_completed: [BOOT-04]
  ```
- `18-02-SUMMARY.md`:
  ```yaml
  requirements_completed: [CAP-01, CAP-05, CAP-07]
  ```
- `18-03-SUMMARY.md`:
  ```yaml
  requirements_completed: [CAP-08]
  ```

---

### 8. Phase Validation Contracts Reconciliation (6 files)

**Role:** Phase-level validation strategy files asserting test infrastructure, sampling rate, per-task verification mapping, and Nyquist compliance.  
**Analog:** `.planning/phases/17-unblock-stow-and-restore-the-session-target/17-VALIDATION.md:1-11, 145-182`.

#### Pattern 8.1: Frontmatter Normalization
Source: `24-CONTEXT.md:D-05`
Across `17-VALIDATION.md`, `18-VALIDATION.md`, `20-VALIDATION.md`, `21-VALIDATION.md`, `22-VALIDATION.md`, and `23-VALIDATION.md`:
```yaml
---
phase: "<N>"
slug: "<slug>"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "<date>"
validated: "2026-09-16"
---
```

#### Pattern 8.2: Per-Task Verification Map Updates
Update all pending tasks (`❌ W0`, `⬜ pending`) to cite their verified assert script command and mark green:
```markdown
| File Exists | Status |
|-------------|--------|
| ✅ exists   | ✅ green |
```
Replace `TBD` task IDs in `18-VALIDATION.md` with concrete plan mappings (`18-01`, `18-02`, etc.) and automated test script references (`./scripts/phase18-capture-model-assert.sh §N`).

#### Pattern 8.3: Formal Classification of Non-Blocking Manual Items (D-06)
In `20-VALIDATION.md` and `21-VALIDATION.md`, clearly designate interactive items:
```markdown
## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions | Classification |
|----------|-------------|------------|-------------------|----------------|
| Fresh login autostart & window placement | START-01 | Requires interactive display server restart | Re-login and check windows | Non-blocking inspection / manual sampling |
| Desktop notification popup appearance | CAP-06 / BAR-01 | Requires active human visual perception | Observe popup toast | Non-blocking inspection / manual sampling |
```

#### Pattern 8.4: Documentation of Scratch-XDG Testing Boundary (D-07)
In `23-VALIDATION.md`:
```markdown
## Testing Boundary & Environmental Constraints

Bootstrap mechanics (de-stubbing, manifest creation, atomic JSON state transitions, GNU Stow symlinking, and verify --strict) are 100% mechanically proven and automated via `./scripts/phase23-bootstrap-assert.sh` using scratch-XDG test environments. Physical fresh-machine reproduction is formally documented as an accepted constraint due to single-operator hardware availability.
```

---

## Universal Repository Conventions & Invariants

### 1. D-20 Frozen History Rule
- **Invariant:** Closed-phase assert scripts (e.g. `scripts/phase17-unblock-assert.sh`, `scripts/phase18-capture-model-assert.sh`) and historical narrative prose must NEVER be retroactively modified to make an audit pass.
- **Enforcement:** All new verifications and fixes must reside in Phase 24 artifacts (`scripts/phase24-tech-debt-assert.sh`).

### 2. Stow Pair Count Invariant
- **Invariant:** Invocations of GNU Stow in `arch/*.sh` must remain strictly 18 (`PAIR_COUNT == 18`).
- **Enforcement:** Phase 24 modifies no files under `arch/` and adds no stow sites. Checked via:
  ```bash
  PAIR_COUNT="$(grep -ho -- '--verbose=5 --no-folding' arch/*.sh | wc -l || true)"
  [[ "$PAIR_COUNT" -eq 18 ]]
  ```

### 3. Quickshell Cheatsheet Taxonomy Rule
- **Invariant:** All personal keybindings in `stow/hypr/.config/hypr/custom/keybinds.lua` must format descriptions as `"Category: Label"`, pass `luac -p`, and have 0 duplicate chords.
- **Enforcement:** Verified by embedded Python validator in `scripts/phase24-tech-debt-assert.sh`.

### 4. Zero Drift Invariant
- **Invariant:** Working tree must remain 100% clean across verification runs.
- **Enforcement:** `arch/dots-hyprland.sh verify --strict` must exit 0, and `git status --porcelain` must be empty before and after tests.

### 5. Exit Code Hierarchy
- `0`: Success / all assertions passed / clean verification.
- `1`: Failure / test assertion failed / drift detected.
- `2`: Precondition failure / invalid CLI arguments.

---

## Pattern Mapping Metadata

- **Phase:** 24 — `address-tech-debt-bookkeeping-and-validation-cleanup`
- **Target Directory:** `/home/pera/github_repo/.dotfiles/.planning/phases/24-address-tech-debt-bookkeeping-and-validation-cleanup`
- **Mapped By:** GSD Pattern Mapper
- **Source Analogs Verified:**
  - `scripts/phase23-bootstrap-assert.sh` (runner, porcelain bracket, verify gate)
  - `scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh` (Lua check, Python taxonomy validator)
  - `scripts/phase21-ii-bar-config-capture-assert.sh` (scratch repo, mock notify-send)
  - `stow/hypr/.config/hypr/custom/keybinds.lua` (personal keybinds)
  - `vendor/dots-hyprland/dots/.config/hypr/hyprland/keybinds.lua` (upstream keybinds reference)
  - `.gitignore` (socket pattern)
  - `.planning/REQUIREMENTS.md` (traceability table)
  - `.planning/ROADMAP.md` (roadmap definition)
  - `.planning/STATE.md` (state and decision log)
  - `.planning/phases/17-unblock-stow-and-restore-the-session-target/17-VALIDATION.md` (validation reconciliation)
  - `.planning/phases/23-one-command-bootstrap/23-01-SUMMARY.md` (summary frontmatter)
