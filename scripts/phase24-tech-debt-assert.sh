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

# --- Section 1: Bookkeeping & Traceability (DEBT-01) ---
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

# --- Section 2: Nyquist Validation Compliance Across Phases 17–23 (DEBT-02) ---
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

# --- Section 3: Repository Hygiene & Debt Disposition (DEBT-03) ---
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 3 ]]; then
  info "--- Section 3: DEBT-03 Repository Hygiene & Debt Disposition ---"

  # 1. Gitignore pattern check
  if grep -q '^!stow/systemd/\*\*' .gitignore && grep -q '^\*\.socket' .gitignore; then
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

# --- Section 4: Session Keybindings & Cheatsheet Realignment (DEBT-04) ---
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

# --- Section 5: Strict System Verification & Zero Drift Gate ---
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
