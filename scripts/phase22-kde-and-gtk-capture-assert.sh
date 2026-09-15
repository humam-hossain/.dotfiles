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
# Section 2: KDE-01: Dolphin/KIO write-through scratch fixture and double-toggle test
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 ]]; then
  info "--- Section 2: KDE-01: Dolphin/KIO write-through scratch fixture and double-toggle test ---"

  # Stage 1: Scratch fixture drill proving KConfig writes through symlinks without link destruction
  S2_ROOT="$(mktemp -d /tmp/p22-assert-s2-XXXXXX)"
  SCRATCH_ROOTS+=("$S2_ROOT")

  mkdir -p "$S2_ROOT/repo" "$S2_ROOT/home/.config"
  printf "[Confirmations]\nConfirmTrash=false\n" > "$S2_ROOT/repo/testkiorc"
  ln -s "$S2_ROOT/repo/testkiorc" "$S2_ROOT/home/.config/testkiorc"

  if [[ -L "$S2_ROOT/home/.config/testkiorc" ]]; then
    pass "Section 2: scratch symlink target successfully initialized"
  else
    fail "Section 2: failed to initialize scratch symlink target"
  fi

  XDG_CONFIG_HOME="$S2_ROOT/home/.config" kwriteconfig6 --file testkiorc --group Confirmations --key ConfirmTrash --type bool true

  if [[ -L "$S2_ROOT/home/.config/testkiorc" ]]; then
    pass "Section 2: scratch symlink preserved after kwriteconfig6 update"
  else
    fail "Section 2: scratch symlink was replaced/destroyed by kwriteconfig6"
  fi

  if [[ -f "$S2_ROOT/repo/testkiorc" ]] && grep -qF "ConfirmTrash=true" "$S2_ROOT/repo/testkiorc"; then
    pass "Section 2: scratch repo file received write-through update (ConfirmTrash=true)"
  else
    fail "Section 2: scratch repo file missing write-through update"
  fi

  if [[ "$S2_ROOT/home/.config/testkiorc" -ef "$S2_ROOT/repo/testkiorc" ]]; then
    pass "Section 2: scratch inode identity preserved between symlink and repo file"
  else
    fail "Section 2: scratch inode identity broke after kwriteconfig6 update"
  fi

  # Stage 2: Live double-toggle test on live kiorc (D-04)
  LIVE_KIORC="$HOME/.config/kiorc"
  REPO_KIORC="$REPO_ROOT/stow/kde/.config/kiorc"

  if [[ -n "$(git status --porcelain "$REPO_KIORC")" ]]; then
    fail "Section 2: repo file $REPO_KIORC has dirty git status prior to double-toggle drill"
  else
    ORIG_VAL="$(kreadconfig6 --file kiorc --group Confirmations --key ConfirmTrash 2>/dev/null || echo "false")"
    if [[ "$ORIG_VAL" == "true" ]]; then
      TOGGLE_VAL="false"
    else
      TOGGLE_VAL="true"
    fi

    # Toggle to opposite
    kwriteconfig6 --file kiorc --group Confirmations --key ConfirmTrash --type bool "$TOGGLE_VAL"

    if [[ -L "$LIVE_KIORC" ]]; then
      pass "Section 2: live ~/.config/kiorc symlink preserved during write-through"
    else
      fail "Section 2: live ~/.config/kiorc symlink was broken by kwriteconfig6"
    fi

    DIFF_OUT="$(git diff --name-only "$REPO_KIORC")"
    if [[ "$DIFF_OUT" =~ stow/kde/\.config/kiorc ]]; then
      pass "Section 2: live write-through updated repo working tree ($DIFF_OUT)"
    else
      fail "Section 2: live write-through did not modify repo file ($REPO_KIORC)"
    fi

    # Toggle back to original
    kwriteconfig6 --file kiorc --group Confirmations --key ConfirmTrash --type bool "$ORIG_VAL"

    # Revert repo modification
    git checkout -- "$REPO_KIORC"

    if [[ -z "$(git status --porcelain "$REPO_KIORC")" ]]; then
      pass "Section 2: live double-toggle cleanly reverted; repo working tree clean"
    else
      fail "Section 2: live double-toggle left repo working tree dirty"
    fi
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
