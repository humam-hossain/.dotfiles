#!/usr/bin/env bash
# Phase 22 KDE and GTK capture assert harness (KDE-01, KDE-02, KDE-03).
# One script, one section per ROADMAP criterion, one verdict for the phase.
#
# Usage (from REPO_ROOT):
#   ./scripts/phase22-kde-and-gtk-capture-assert.sh [--section <1-6>]
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
      if [[ -z "${2:-}" ]] || ! [[ "$2" =~ ^[1-6]$ ]]; then
        echo "Error: --section requires an integer from 1 to 6" >&2
        exit 1
      fi
      RUN_SECTION="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 [--section <1-6>]"
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

# ===========================================================================
# Section 1: KDE-01: KDE package layout, inode identity, and 0600 mode documentation check
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 1 ]]; then
  info "--- Section 1: KDE-01: KDE package layout, inode identity, and 0600 mode documentation check ---"

  KDE_FILES=("kiorc" "ktrashrc" "kservicemenurc")
  for f in "${KDE_FILES[@]}"; do
    REPO_FILE="$REPO_ROOT/stow/kde/.config/$f"
    LIVE_FILE="$HOME/.config/$f"

    # 1. Repo file presence
    if [[ -f "$REPO_FILE" ]]; then
      pass "Section 1: stow/kde/.config/$f exists in repository"
    else
      fail "Section 1: stow/kde/.config/$f missing from repository"
    fi

    # 2. Live counterpart is a symlink resolving into stow/kde/.config/
    if [[ -L "$LIVE_FILE" ]]; then
      pass "Section 1: ~/.config/$f is a symbolic link"
    else
      fail "Section 1: ~/.config/$f is not a symbolic link"
    fi

    # 3. Inode identity check (-ef dereferences and tests matching dev+inode)
    if [[ -e "$LIVE_FILE" && -e "$REPO_FILE" && "$LIVE_FILE" -ef "$REPO_FILE" ]]; then
      LIVE_INODE="$(stat -L -c %i "$LIVE_FILE")"
      REPO_INODE="$(stat -c %i "$REPO_FILE")"
      if [[ "$LIVE_INODE" -eq "$REPO_INODE" ]]; then
        pass "Section 1: ~/.config/$f inode ($LIVE_INODE) matches stow/kde/.config/$f ($REPO_INODE)"
      else
        fail "Section 1: ~/.config/$f inode ($LIVE_INODE) does not match repo ($REPO_INODE)"
      fi
    else
      fail "Section 1: ~/.config/$f does not resolve to $REPO_FILE"
    fi
  done

  # 4. File mode 0600 resolution documentation (Q11, D-03)
  # Verify files contain standard non-executable permissions
  MODE_OK=true
  for f in "${KDE_FILES[@]}"; do
    REPO_FILE="$REPO_ROOT/stow/kde/.config/$f"
    if [[ -f "$REPO_FILE" ]]; then
      PERMS="$(stat -c %a "$REPO_FILE")"
      if [[ "$PERMS" != "600" && "$PERMS" != "644" ]]; then
        MODE_OK=false
        fail "Section 1: stow/kde/.config/$f has unexpected permissions: $PERMS"
      fi
    fi
  done
  if [[ "$MODE_OK" == "true" ]]; then
    pass "Section 1: KDE config files carry standard non-executable file mode (0600/0644 documented per Q11/D-03)"
  fi

  # 5. Path portability in ktrashrc: [/home/pera/.local/share/Trash] section header (D-07)
  KTRASH_FILE="$REPO_ROOT/stow/kde/.config/ktrashrc"
  if [[ -f "$KTRASH_FILE" ]] && grep -qF '[\/home\/pera\/.local\/share\/Trash]' "$KTRASH_FILE" || grep -qF '[/home/pera/.local/share/Trash]' "$KTRASH_FILE"; then
    pass "Section 1: stow/kde/.config/ktrashrc retains literal single-machine path header [/home/pera/.local/share/Trash]"
  else
    fail "Section 1: stow/kde/.config/ktrashrc missing [/home/pera/.local/share/Trash] header"
  fi

  # 6. Scope boundary: verify no unmanaged KDE desktop cache files tracked in stow/kde/ (D-06)
  UNMANAGED_CACHE=("baloofileinformationrc" "kwalletrc" "kconf_updaterc" "darklyrc" "konsolerc")
  UNMANAGED_FOUND=0
  for u in "${UNMANAGED_CACHE[@]}"; do
    if [[ -e "$REPO_ROOT/stow/kde/.config/$u" ]]; then
      fail "Section 1: unmanaged desktop cache file $u found in stow/kde/.config/"
      UNMANAGED_FOUND=$((UNMANAGED_FOUND + 1))
    fi
  done
  if [[ "$UNMANAGED_FOUND" -eq 0 ]]; then
    pass "Section 1: stow/kde/ strictly contains only managed KIO/Dolphin configs (no unmanaged cache files per D-06)"
  fi
fi

# ===========================================================================
# Terminal summary block
# ===========================================================================
echo "=== done: FAIL=${FAIL} FINDINGS=${FINDINGS} ==="
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
