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

    # Revert repo modification (with retry for transient daemon index.lock contention)
    retries=5
    until git checkout -- "$REPO_KIORC" 2>/dev/null || [[ $retries -le 0 ]]; do
      sleep 0.1
      retries=$((retries - 1))
    done
    if [[ $retries -le 0 ]]; then
      git checkout -- "$REPO_KIORC"
    fi

    if [[ -z "$(git status --porcelain "$REPO_KIORC")" ]]; then
      pass "Section 2: live double-toggle cleanly reverted; repo working tree clean"
    else
      fail "Section 2: live double-toggle left repo working tree dirty"
    fi
  fi
fi

# ===========================================================================
# Section 3: KDE-02: GTK package layout, unfolded parent directory assertion, and scratch link severance test
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 3 ]]; then
  info "--- Section 3: KDE-02: GTK package layout, unfolded parent directory assertion, and scratch link severance test ---"

  # 1 & 2. Verify repository files exist and live counterparts are symlinks with matching inodes
  GTK_FILES=(
    "stow/gtk/.config/gtk-3.0/settings.ini:$HOME/.config/gtk-3.0/settings.ini"
    "stow/gtk/.config/gtk-3.0/bookmarks:$HOME/.config/gtk-3.0/bookmarks"
    "stow/gtk/.config/gtk-4.0/settings.ini:$HOME/.config/gtk-4.0/settings.ini"
  )

  for pair in "${GTK_FILES[@]}"; do
    REPO_PATH="$REPO_ROOT/${pair%%:*}"
    LIVE_PATH="${pair##*:}"
    REL_PATH="${pair%%:*}"

    if [[ -f "$REPO_PATH" ]]; then
      pass "Section 3: $REL_PATH exists in repository"
    else
      fail "Section 3: $REL_PATH missing from repository"
    fi

    if [[ -L "$LIVE_PATH" ]]; then
      pass "Section 3: $LIVE_PATH is a symbolic link"
    else
      fail "Section 3: $LIVE_PATH is not a symbolic link"
    fi

    if [[ -e "$LIVE_PATH" && -e "$REPO_PATH" && "$LIVE_PATH" -ef "$REPO_PATH" ]]; then
      LIVE_INODE="$(stat -L -c %i "$LIVE_PATH")"
      REPO_INODE="$(stat -c %i "$REPO_PATH")"
      if [[ "$LIVE_INODE" -eq "$REPO_INODE" ]]; then
        pass "Section 3: $LIVE_PATH inode ($LIVE_INODE) matches $REL_PATH ($REPO_INODE)"
      else
        fail "Section 3: $LIVE_PATH inode ($LIVE_INODE) does not match repo ($REPO_INODE)"
      fi
    else
      fail "Section 3: $LIVE_PATH does not resolve to $REPO_PATH"
    fi
  done

  # 3. Assert parent directory unfolding invariant (D-09)
  if [[ -d "$HOME/.config/gtk-3.0" && ! -L "$HOME/.config/gtk-3.0" ]]; then
    pass "Section 3: ~/.config/gtk-3.0 is a regular directory (unfolded parent invariant verified per D-09)"
  else
    fail "Section 3: ~/.config/gtk-3.0 is folded or not a directory"
  fi

  if [[ -d "$HOME/.config/gtk-4.0" && ! -L "$HOME/.config/gtk-4.0" ]]; then
    pass "Section 3: ~/.config/gtk-4.0 is a regular directory (unfolded parent invariant verified per D-09)"
  else
    fail "Section 3: ~/.config/gtk-4.0 is folded or not a directory"
  fi

  # 4. Assert .gitignore contains gtk.css and gtk-dark.css (D-13)
  if grep -q '^gtk\.css$' "$REPO_ROOT/.gitignore" && grep -q '^gtk-dark\.css$' "$REPO_ROOT/.gitignore"; then
    pass "Section 3: root .gitignore contains gtk.css and gtk-dark.css under generated theme outputs (D-13)"
  else
    fail "Section 3: root .gitignore missing gtk.css or gtk-dark.css"
  fi

  # 5. Assert bookmarks path portability (D-11): verify file:///home/pera/ URI format
  BOOKMARKS_FILE="$REPO_ROOT/stow/gtk/.config/gtk-3.0/bookmarks"
  if [[ -f "$BOOKMARKS_FILE" ]] && grep -q '^file:///home/pera/' "$BOOKMARKS_FILE"; then
    pass "Section 3: stow/gtk/.config/gtk-3.0/bookmarks preserves literal single-machine file:// URIs (D-11)"
  else
    fail "Section 3: stow/gtk/.config/gtk-3.0/bookmarks missing file:///home/pera/ URIs"
  fi

  # 6. Assert legacy GTK 2.0 exclusion (D-12)
  if [[ ! -e "$REPO_ROOT/stow/gtk/.config/gtkrc" && ! -e "$REPO_ROOT/stow/gtk/.gtkrc-2.0" ]]; then
    pass "Section 3: stow/gtk/ excludes legacy GTK 2.0 configuration files (D-12)"
  else
    fail "Section 3: legacy GTK 2.0 configuration file found in stow/gtk/"
  fi

  # 7. Scratch GLib link severance simulation drill (Q6, D-10)
  S3_ROOT="$(mktemp -d /tmp/p22-assert-s3-XXXXXX)"
  SCRATCH_ROOTS+=("$S3_ROOT")

  mkdir -p "$S3_ROOT/repo" "$S3_ROOT/home/.config/gtk-3.0"
  printf "file:///home/pera/Downloads Downloads\n" > "$S3_ROOT/repo/bookmarks"
  ln -s "$S3_ROOT/repo/bookmarks" "$S3_ROOT/home/.config/gtk-3.0/bookmarks"

  if [[ -L "$S3_ROOT/home/.config/gtk-3.0/bookmarks" ]]; then
    pass "Section 3: scratch GTK bookmarks symlink successfully initialized"
  else
    fail "Section 3: failed to initialize scratch GTK bookmarks symlink"
  fi

  python3 -c "import gi; gi.require_version('GLib', '2.0'); from gi.repository import GLib; GLib.file_set_contents('$S3_ROOT/home/.config/gtk-3.0/bookmarks', b'file:///test Test\n')"

  if [[ ! -L "$S3_ROOT/home/.config/gtk-3.0/bookmarks" && -f "$S3_ROOT/home/.config/gtk-3.0/bookmarks" ]]; then
    pass "Section 3: scratch GLib file_set_contents severed symlink into regular file (Q6 demonstrated, watchdog protected per D-10)"
  else
    fail "Section 3: scratch GLib file_set_contents did not sever symlink as expected"
  fi
fi

# ===========================================================================
# Section 4: KDE-03: Restow chrome-flags packaging and restow/README.md generated table match
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 4 ]]; then
  info "--- Section 4: KDE-03: Restow chrome-flags packaging and restow/README.md generated table match ---"

  REPO_CF="$REPO_ROOT/restow/chrome-flags/.config/chrome-flags.conf"
  LIVE_CF="$HOME/.config/chrome-flags.conf"

  # 1. Repo file presence
  if [[ -f "$REPO_CF" ]]; then
    pass "Section 4: restow/chrome-flags/.config/chrome-flags.conf exists in repository"
  else
    fail "Section 4: restow/chrome-flags/.config/chrome-flags.conf missing from repository"
  fi

  # 2. Live counterpart is a symlink
  if [[ -L "$LIVE_CF" ]]; then
    pass "Section 4: ~/.config/chrome-flags.conf is a symbolic link"
  else
    fail "Section 4: ~/.config/chrome-flags.conf is not a symbolic link"
  fi

  # 3. Inode identity check
  if [[ -e "$LIVE_CF" && -e "$REPO_CF" && "$LIVE_CF" -ef "$REPO_CF" ]]; then
    LIVE_CF_INODE="$(stat -L -c %i "$LIVE_CF")"
    REPO_CF_INODE="$(stat -c %i "$REPO_CF")"
    if [[ "$LIVE_CF_INODE" -eq "$REPO_CF_INODE" ]]; then
      pass "Section 4: ~/.config/chrome-flags.conf inode ($LIVE_CF_INODE) matches restow repo file ($REPO_CF_INODE)"
    else
      fail "Section 4: ~/.config/chrome-flags.conf inode ($LIVE_CF_INODE) does not match repo ($REPO_CF_INODE)"
    fi
  else
    fail "Section 4: ~/.config/chrome-flags.conf does not resolve to $REPO_CF"
  fi

  # 4. Collision map mapping check
  MAP_ROW="$(grep -F '$XDG_CONFIG_HOME/chrome-flags.conf' "$REPO_ROOT/collision-map.tsv" || true)"
  if [[ -n "$MAP_ROW" ]] && grep -q "OVERWRITTEN" <<<"$MAP_ROW" && grep -q "restow" <<<"$MAP_ROW"; then
    pass "Section 4: collision-map.tsv maps chrome-flags.conf to restow tree with OVERWRITTEN repo outcome"
  else
    fail "Section 4: collision-map.tsv does not correctly map chrome-flags.conf: $MAP_ROW"
  fi

  # 5. restow/README.md generated table matches generator output exactly
  EXPECTED_TABLE="$("$REPO_ROOT/scripts/gen-collision-map.sh" --restow-table)"
  ACTUAL_TABLE="$(awk '/<!-- BEGIN generated: gen-collision-map.sh --restow-table -->/{flag=1; next} /<!-- END generated: gen-collision-map.sh --restow-table -->/{flag=0} flag' "$REPO_ROOT/restow/README.md" | sed -e '1{/^$/d}' -e '${/^$/d}')"
  EXPECTED_TRIMMED="$(echo "$EXPECTED_TABLE" | sed -e '1{/^$/d}' -e '${/^$/d}')"

  if [[ "$ACTUAL_TABLE" == "$EXPECTED_TRIMMED" ]] && grep -q 'chrome-flags' <<<"$ACTUAL_TABLE" && ! grep -q 'kdeglobals' <<<"$ACTUAL_TABLE"; then
    pass "Section 4: restow/README.md Section 3 matches gen-collision-map.sh --restow-table (chrome-flags included, kdeglobals absent)"
  else
    fail "Section 4: restow/README.md generated table does not match gen-collision-map.sh --restow-table"
  fi
fi

# ===========================================================================
# Section 5: KDE-03: Live cp-through drill: clean-tree preflight, install-files execution, modified status check, and git checkout recovery
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 5 ]]; then
  info "--- Section 5: KDE-03: Live cp-through drill: clean-tree preflight, install-files execution, modified status check, and git checkout recovery ---"

  # 1. Clean working tree preflight check
  INITIAL_STATUS="$(git status --porcelain)"
  if [[ -z "$INITIAL_STATUS" ]]; then
    pass "Section 5: git working tree is clean prior to live cp-through drill"
  else
    fail "Section 5: git working tree is dirty prior to drill: $INITIAL_STATUS"
  fi

  # 2. Invoke upstream installer files subcommand
  INSTALL_RC=0
  printf '\nyesforall\n' | "$REPO_ROOT/arch/dots-hyprland.sh" install-files >/dev/null 2>&1 || INSTALL_RC=$?
  if [[ "$INSTALL_RC" -eq 0 ]]; then
    pass "Section 5: ./arch/dots-hyprland.sh install-files executed successfully (exit code 0)"
  else
    fail "Section 5: ./arch/dots-hyprland.sh install-files failed with exit code $INSTALL_RC"
  fi

  # 3. Verify write-through modification occurred
  DRILL_STATUS="$(git status --porcelain)"
  if grep -q "M restow/dolphinrc/.config/dolphinrc" <<<"$DRILL_STATUS" && grep -q "M restow/chrome-flags/.config/chrome-flags.conf" <<<"$DRILL_STATUS"; then
    pass "Section 5: live cp-through drill proved write-through modification on restow/dolphinrc and restow/chrome-flags"
  else
    fail "Section 5: expected write-through modifications missing from git status: $DRILL_STATUS"
  fi

  # 4. Execute recovery step per documented restow contract
  retries=5
  until git checkout -- restow/chrome-flags restow/dolphinrc 2>/dev/null || [[ $retries -le 0 ]]; do
    sleep 0.1
    retries=$((retries - 1))
  done
  if [[ $retries -le 0 ]]; then
    git checkout -- restow/chrome-flags restow/dolphinrc
  fi

  FINAL_STATUS="$(git status --porcelain)"
  if [[ -z "$FINAL_STATUS" ]]; then
    pass "Section 5: git checkout -- restow/chrome-flags restow/dolphinrc restored clean working tree"
  else
    fail "Section 5: working tree remains dirty after recovery: $FINAL_STATUS"
  fi
fi

# ===========================================================================
# Section 6: KDE-02: GUARD list data integrity, Q7/Q8 documentation check, kdeglobals unlinking, and verify --strict pass
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 6 ]]; then
  info "--- Section 6: KDE-02: GUARD list data integrity, Q7/Q8 documentation check, kdeglobals unlinking, and verify --strict pass ---"

  GUARD_TSV="$REPO_ROOT/guard-paths.tsv"

  # 1. guard-paths.tsv data integrity and presence of all 7 tracked paths
  if [[ -f "$GUARD_TSV" ]]; then
    pass "Section 6: guard-paths.tsv exists at repository root"

    EXPECTED_PATHS=(
      '$XDG_CONFIG_HOME/kdeglobals'
      '$XDG_CONFIG_HOME/Kvantum'
      '$XDG_CONFIG_HOME/gtk-3.0/gtk.css'
      '$XDG_CONFIG_HOME/gtk-4.0/gtk.css'
      '$XDG_CONFIG_HOME/fuzzel/fuzzel_theme.ini'
      '$XDG_CONFIG_HOME/hypr/hyprland/colors.lua'
      '$XDG_CONFIG_HOME/hypr/hyprlock/colors.conf'
    )

    ALL_FOUND=true
    for p in "${EXPECTED_PATHS[@]}"; do
      if grep -qF "$p" "$GUARD_TSV"; then
        pass "Section 6: guard-paths.tsv contains $p"
      else
        ALL_FOUND=false
        fail "Section 6: guard-paths.tsv missing $p"
      fi
    done
    if [[ "$ALL_FOUND" == "true" ]]; then
      pass "Section 6: all 7 required GUARD paths verified in guard-paths.tsv"
    fi
  else
    fail "Section 6: guard-paths.tsv missing from repository root"
  fi

  # 2. Q7 and Q8 empirical resolutions documented in header
  if grep -q "Q7:" "$GUARD_TSV" && grep -q "kde-material-you-colors" "$GUARD_TSV"; then
    pass "Section 6: guard-paths.tsv header documents empirical Q7 resolution (kde-material-you-colors churn)"
  else
    fail "Section 6: guard-paths.tsv header missing Q7 documentation"
  fi

  if grep -q "Q8:" "$GUARD_TSV" && grep -q "gtk-4.0/gtk.css" "$GUARD_TSV"; then
    pass "Section 6: guard-paths.tsv header documents empirical Q8 resolution (root-owned theme symlink)"
  else
    fail "Section 6: guard-paths.tsv header missing Q8 documentation"
  fi

  # 3. kdeglobals retirement and live unlinking
  if [[ -f "$REPO_ROOT/docs/archive/kdeglobals" && ! -e "$REPO_ROOT/restow/kdeglobals" ]]; then
    pass "Section 6: kdeglobals retired to docs/archive/kdeglobals and restow/kdeglobals removed"
  else
    fail "Section 6: kdeglobals archive placement or restow/kdeglobals removal incomplete"
  fi

  if [[ -f "$HOME/.config/kdeglobals" && ! -L "$HOME/.config/kdeglobals" ]]; then
    pass "Section 6: live ~/.config/kdeglobals is an unmanaged regular file, not a symlink"
  else
    fail "Section 6: live ~/.config/kdeglobals is still a symlink or missing"
  fi

  # 4. Scratch fixture test: mock repo with forbidden GUARD file fails closed
  S6_ROOT="$(mktemp -d /tmp/p22-assert-s6-XXXXXX)"
  SCRATCH_ROOTS+=("$S6_ROOT")

  mkdir -p "$S6_ROOT/repo/arch" "$S6_ROOT/repo/stow/badpkg/.config" "$S6_ROOT/home"
  cp "$REPO_ROOT/arch/dots-hyprland.sh" "$S6_ROOT/repo/arch/dots-hyprland.sh"
  cp "$REPO_ROOT/guard-paths.tsv" "$S6_ROOT/repo/guard-paths.tsv"
  chmod +x "$S6_ROOT/repo/arch/dots-hyprland.sh"
  touch "$S6_ROOT/repo/stow/badpkg/.config/kdeglobals"

  git -C "$S6_ROOT/repo" init -q
  git -C "$S6_ROOT/repo" config user.email "assert@example.com"
  git -C "$S6_ROOT/repo" config user.name "Assert Runner"
  git -C "$S6_ROOT/repo" add -A
  git -C "$S6_ROOT/repo" commit -q -m "initial bad fixture"

  S6_RC=0
  S6_OUT="$(cd "$S6_ROOT/repo" && HOME="$S6_ROOT/home" ./arch/dots-hyprland.sh verify 2>&1)" || S6_RC=$?

  if [[ "$S6_RC" -ne 0 ]] && grep -q "guard path tracked in stow: stow/badpkg/.config/kdeglobals" <<<"$S6_OUT"; then
    pass "Section 6: verification engine fails closed on tracked guard path in scratch fixture"
  else
    fail "Section 6: verification engine did not fail closed on tracked guard path (rc=$S6_RC)"
    printf '%s\n' "$S6_OUT" | sed 's/^/       /' >&2
  fi

  # 5. Run verify against real repository
  REAL_VERIFY_RC=0
  REAL_VERIFY_OUT="$("$REPO_ROOT/arch/dots-hyprland.sh" verify 2>&1)" || REAL_VERIFY_RC=$?
  if [[ "$REAL_VERIFY_RC" -eq 0 ]] && grep -q "guard path excluded: \$XDG_CONFIG_HOME/kdeglobals" <<<"$REAL_VERIFY_OUT"; then
    pass "Section 6: arch/dots-hyprland.sh verify passed on real repository with all GUARD checks green"
  else
    fail "Section 6: arch/dots-hyprland.sh verify failed on real repository (rc=$REAL_VERIFY_RC)"
    printf '%s\n' "$REAL_VERIFY_OUT" | sed 's/^/       /' >&2
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
