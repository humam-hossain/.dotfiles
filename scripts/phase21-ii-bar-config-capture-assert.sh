#!/usr/bin/env bash
# Phase 21 ii bar config capture assert harness (BAR-01, BAR-02, CAP-06).
# One script, one section per ROADMAP criterion, one verdict for the phase.
#
# Usage (from REPO_ROOT):
#   ./scripts/phase21-ii-bar-config-capture-assert.sh [--section <1-7>]
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

# ---------------------------------------------------------------------------
# CLI Argument Parsing
# ---------------------------------------------------------------------------
RUN_SECTION=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --section)
      if [[ -z "${2:-}" ]] || ! [[ "$2" =~ ^[1-7]$ ]]; then
        echo "Error: --section requires an integer from 1 to 7" >&2
        exit 1
      fi
      RUN_SECTION="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 [--section <1-7>]"
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

# ===========================================================================
# Section 1: BAR-01: Ingest validation, atomic copy, symlink refusal, and dirty repo mirror skip
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 1 ]]; then
  info "--- Section 1: Ingest validation, atomic copy, symlink refusal, and dirty repo mirror skip ---"
  S1_ROOT="$(mktemp -d /tmp/p21-assert-s1-XXXXXX)"
  SCRATCH_ROOTS+=("$S1_ROOT")

  mkdir -p "$S1_ROOT/repo/arch" "$S1_ROOT/repo/capture/testpkg/.config/testpkg" "$S1_ROOT/home/.config/testpkg"
  cp "$REPO_ROOT/arch/dots-hyprland.sh" "$S1_ROOT/repo/arch/dots-hyprland.sh"
  chmod +x "$S1_ROOT/repo/arch/dots-hyprland.sh"

  git -C "$S1_ROOT/repo" init -q
  git -C "$S1_ROOT/repo" config user.email "assert@example.com"
  git -C "$S1_ROOT/repo" config user.name "Assert Runner"

  printf '{"setting": "initial"}\n' > "$S1_ROOT/repo/capture/testpkg/.config/testpkg/config.json"
  git -C "$S1_ROOT/repo" add -A
  git -C "$S1_ROOT/repo" commit -q -m "initial commit"
  printf '{"setting": "initial"}\n' > "$S1_ROOT/home/.config/testpkg/config.json"

  # Case A: Valid update
  printf '{"setting": "updated_valid"}\n' > "$S1_ROOT/home/.config/testpkg/config.json"
  A_RC=0
  A_OUT="$(cd "$S1_ROOT/repo" && HOME="$S1_ROOT/home" ./arch/dots-hyprland.sh capture 2>&1)" || A_RC=$?
  if [[ "$A_RC" -eq 0 ]] && grep -q -- "captured:" <<<"$A_OUT" && cmp -s "$S1_ROOT/home/.config/testpkg/config.json" "$S1_ROOT/repo/capture/testpkg/.config/testpkg/config.json"; then
    pass "Section 1A: valid JSON update captured into repo mirror"
  else
    fail "Section 1A: valid JSON update failed to capture (rc=$A_RC)"
    printf '%s\n' "$A_OUT" | sed 's/^/       /' >&2
  fi
  git -C "$S1_ROOT/repo" add -A
  git -C "$S1_ROOT/repo" commit -q -m "captured valid update"

  # Case B: Unchanged skip
  B_RC=0
  B_OUT="$(cd "$S1_ROOT/repo" && HOME="$S1_ROOT/home" ./arch/dots-hyprland.sh capture 2>&1)" || B_RC=$?
  if [[ "$B_RC" -eq 0 ]] && grep -q -- "unchanged:" <<<"$B_OUT"; then
    pass "Section 1B: unchanged file skipped via cmp -s without copy"
  else
    fail "Section 1B: unchanged file not skipped via cmp -s (rc=$B_RC)"
    printf '%s\n' "$B_OUT" | sed 's/^/       /' >&2
  fi

  # Case C: 0-byte file refusal
  : > "$S1_ROOT/home/.config/testpkg/config.json"
  C_RC=0
  C_OUT="$(cd "$S1_ROOT/repo" && HOME="$S1_ROOT/home" ./arch/dots-hyprland.sh capture 2>&1)" || C_RC=$?
  if [[ "$C_RC" -ne 0 ]] && grep -q -- "invalid or empty JSON" <<<"$C_OUT" && grep -q -- "updated_valid" "$S1_ROOT/repo/capture/testpkg/.config/testpkg/config.json"; then
    pass "Section 1C: 0-byte file refused with fail-closed non-zero exit, repo intact"
  else
    fail "Section 1C: 0-byte file not correctly refused (rc=$C_RC)"
    printf '%s\n' "$C_OUT" | sed 's/^/       /' >&2
  fi

  # Case D: Corrupt syntax refusal
  printf '{"setting": "unclosed_brace' > "$S1_ROOT/home/.config/testpkg/config.json"
  D_RC=0
  D_OUT="$(cd "$S1_ROOT/repo" && HOME="$S1_ROOT/home" ./arch/dots-hyprland.sh capture 2>&1)" || D_RC=$?
  if [[ "$D_RC" -ne 0 ]] && grep -q -- "invalid or empty JSON" <<<"$D_OUT" && grep -q -- "updated_valid" "$S1_ROOT/repo/capture/testpkg/.config/testpkg/config.json"; then
    pass "Section 1D: corrupt syntax refused with fail-closed non-zero exit, repo intact"
  else
    fail "Section 1D: corrupt syntax not correctly refused (rc=$D_RC)"
    printf '%s\n' "$D_OUT" | sed 's/^/       /' >&2
  fi

  # Case E: Live symlink refusal
  rm -f "$S1_ROOT/home/.config/testpkg/config.json"
  ln -s "$S1_ROOT/repo/capture/testpkg/.config/testpkg/config.json" "$S1_ROOT/home/.config/testpkg/config.json"
  E_RC=0
  E_OUT="$(cd "$S1_ROOT/repo" && HOME="$S1_ROOT/home" ./arch/dots-hyprland.sh capture 2>&1)" || E_RC=$?
  if [[ "$E_RC" -ne 0 ]] && grep -q -- "refusing live path that is a symlink resolving into repo" <<<"$E_OUT"; then
    pass "Section 1E: live symlink resolving into repo refused (D-06, D-39)"
  else
    fail "Section 1E: live symlink not refused (rc=$E_RC)"
    printf '%s\n' "$E_OUT" | sed 's/^/       /' >&2
  fi

  # Case F: Dirty repo mirror skip
  rm -f "$S1_ROOT/home/.config/testpkg/config.json"
  printf '{"setting": "live_content"}\n' > "$S1_ROOT/home/.config/testpkg/config.json"
  printf '{"setting": "dirty_mirror"}\n' > "$S1_ROOT/repo/capture/testpkg/.config/testpkg/config.json"
  F_RC=0
  F_OUT="$(cd "$S1_ROOT/repo" && HOME="$S1_ROOT/home" ./arch/dots-hyprland.sh capture 2>&1)" || F_RC=$?
  if [[ "$F_RC" -ne 0 ]] && grep -q -- "repo mirror is dirty against HEAD" <<<"$F_OUT" && grep -q -- "dirty_mirror" "$S1_ROOT/repo/capture/testpkg/.config/testpkg/config.json"; then
    pass "Section 1F: dirty repo mirror skipped without overwrite"
  else
    fail "Section 1F: dirty repo mirror not skipped (rc=$F_RC)"
    printf '%s\n' "$F_OUT" | sed 's/^/       /' >&2
  fi
fi

# ===========================================================================
# Section 2: BAR-01: Isolated fixture wallpaper switch symlink destruction and capture recovery drill
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 ]]; then
  info "--- Section 2: Wallpaper switch symlink destruction and capture recovery drill ---"
  DRILL_ROOT="$(mktemp -d /tmp/p21-assert-s2-XXXXXX)"
  SCRATCH_ROOTS+=("$DRILL_ROOT")

  mkdir -p "$DRILL_ROOT/repo/arch" "$DRILL_ROOT/repo/capture/ii/.config/illogical-impulse" "$DRILL_ROOT/home/.config/illogical-impulse"
  cp "$REPO_ROOT/arch/dots-hyprland.sh" "$DRILL_ROOT/repo/arch/dots-hyprland.sh"
  chmod +x "$DRILL_ROOT/repo/arch/dots-hyprland.sh"

  git -C "$DRILL_ROOT/repo" init -q
  git -C "$DRILL_ROOT/repo" config user.email "drill@example.com"
  git -C "$DRILL_ROOT/repo" config user.name "Drill Runner"

  printf '{"background": {"wallpaperPath": "/old/path.jpg"}}\n' > "$DRILL_ROOT/repo/capture/ii/.config/illogical-impulse/config.json"
  git -C "$DRILL_ROOT/repo" add -A
  git -C "$DRILL_ROOT/repo" commit -q -m "initial ii bar config"

  SHELL_CONFIG_FILE="$DRILL_ROOT/home/.config/illogical-impulse/config.json"
  ln -s "$DRILL_ROOT/repo/capture/ii/.config/illogical-impulse/config.json" "$SHELL_CONFIG_FILE"

  # Step 1: Assert symlink state before switchwall
  if [[ -L "$SHELL_CONFIG_FILE" ]]; then
    pass "Section 2: initial config.json is a symbolic link"
  else
    fail "Section 2: initial config.json is not a symbolic link"
  fi

  # Step 2: Replicate switchwall.sh:147 mv rename logic
  jq --arg path "/new/wallpaper.jpg" '.background.wallpaperPath = $path' "$SHELL_CONFIG_FILE" > "$SHELL_CONFIG_FILE.tmp"
  mv "$SHELL_CONFIG_FILE.tmp" "$SHELL_CONFIG_FILE"

  # Step 3: Assert symlink is severed to plain file
  if [[ ! -L "$SHELL_CONFIG_FILE" && -f "$SHELL_CONFIG_FILE" ]]; then
    pass "Section 2: mv severed symlink and replaced with plain file"
  else
    fail "Section 2: config.json was not converted to plain file by mv"
  fi

  # Step 4: Run capture to ingest plain file
  CAP_RC=0
  CAP_OUT="$(cd "$DRILL_ROOT/repo" && HOME="$DRILL_ROOT/home" ./arch/dots-hyprland.sh capture 2>&1)" || CAP_RC=$?
  if [[ "$CAP_RC" -eq 0 ]] && grep -q -- "captured:" <<<"$CAP_OUT"; then
    pass "Section 2: capture synchronized plain file into repo mirror"
  else
    fail "Section 2: capture failed to synchronize plain file (rc=$CAP_RC)"
    printf '%s\n' "$CAP_OUT" | sed 's/^/       /' >&2
  fi

  # Step 5: Assert git diff in fixture shows updated wallpaper path
  DIFF_OUT="$(git -C "$DRILL_ROOT/repo" diff)"
  if grep -q -- "/new/wallpaper.jpg" <<<"$DIFF_OUT"; then
    pass "Section 2: repo mirror diff reflects updated wallpaper path"
  else
    fail "Section 2: repo mirror diff missing updated wallpaper path"
    printf '%s\n' "$DIFF_OUT" | sed 's/^/       /' >&2
  fi
fi

# ===========================================================================
# Sections 3-7 Stubs (implemented in Plans 21-02 and 21-03)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 3 ]]; then
  info "Section 3: Wallpaper update confirmation (Plan 21-03 stub)"
fi
if [[ "$RUN_SECTION" -eq 4 ]]; then
  info "Section 4: Systemd user unit activation & timer scheduling (Plan 21-02 stub)"
fi
if [[ "$RUN_SECTION" -eq 5 ]]; then
  info "Section 5: End-to-end background timer drift capture (Plan 21-02 stub)"
fi
if [[ "$RUN_SECTION" -eq 6 ]]; then
  info "Section 6: Defaults-reset recovery drill (Plan 21-03 stub)"
fi
if [[ "$RUN_SECTION" -eq 7 ]]; then
  info "Section 7: Full suite verification gate (Plan 21-03 stub)"
fi

echo "=== done: FAIL=${FAIL} FINDINGS=${FINDINGS} ==="
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
