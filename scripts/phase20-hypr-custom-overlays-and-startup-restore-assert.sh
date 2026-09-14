#!/usr/bin/env bash
# Phase 20 hypr/custom overlays and startup restore asserts (D-22).
# One script, one section per ROADMAP criterion, one verdict for the phase.
#
# Usage (from REPO_ROOT):
#   ./scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh [--section <1-7>]
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
# Section 1: SAFE-01: isolated fixture backup, stub pruning, and stow dry-run
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 1 ]]; then
  info "--- Section 1: SAFE-01 isolated fixture backup, stub pruning, and stow dry-run ---"

  S1_ROOT="$(mktemp -d /tmp/p20-assert-s1-XXXXXX)"
  SCRATCH_ROOTS+=("$S1_ROOT")

  # Setup mock repo and home
  mkdir -p "$S1_ROOT/repo/stow/testpkg/.config/testpkg"
  mkdir -p "$S1_ROOT/home/.config/testpkg"

  printf 'return "managed"\n' > "$S1_ROOT/repo/stow/testpkg/.config/testpkg/target.lua"
  printf 'return "legacy stub"\n' > "$S1_ROOT/home/.config/testpkg/target.lua"

  # 1. Timestamped backup creation
  BACKUP_EPOCH="$(date +%s)"
  BACKUP_DIR="$S1_ROOT/home/.config/testpkg.backup.$BACKUP_EPOCH"
  cp -a "$S1_ROOT/home/.config/testpkg" "$BACKUP_DIR"

  if [[ -d "$BACKUP_DIR" ]] && [[ -f "$BACKUP_DIR/target.lua" ]] && grep -q 'legacy stub' "$BACKUP_DIR/target.lua"; then
    pass "SAFE-01 (S1): timestamped backup created with intact legacy contents"
  else
    fail "SAFE-01 (S1): backup directory missing or contents corrupted"
  fi

  # 2. Stub pruning
  rm -f "$S1_ROOT/home/.config/testpkg/target.lua"
  if [[ ! -e "$S1_ROOT/home/.config/testpkg/target.lua" ]]; then
    pass "SAFE-01 (S1): legacy unmanaged stub successfully pruned prior to stow"
  else
    fail "SAFE-01 (S1): legacy stub still exists after pruning"
  fi

  # 3. Dry-run stow
  DRY_OUT="$(mktemp /tmp/p20-s1-dryout-XXXXXX)"
  TMP_FILES+=("$DRY_OUT")
  if stow -n -v --no-folding -d "$S1_ROOT/repo/stow" -t "$S1_ROOT/home" testpkg >"$DRY_OUT" 2>&1; then
    if [[ ! -e "$S1_ROOT/home/.config/testpkg/target.lua" ]]; then
      pass "SAFE-01 (S1): stow dry-run (-n) succeeded cleanly with zero filesystem modifications"
    else
      fail "SAFE-01 (S1): stow dry-run modified target filesystem"
    fi
  else
    fail "SAFE-01 (S1): stow dry-run exited non-zero"
  fi

  # 4. Actual stow execution and link identity
  if stow -v --no-folding -d "$S1_ROOT/repo/stow" -t "$S1_ROOT/home" testpkg >/dev/null 2>&1; then
    if [[ -L "$S1_ROOT/home/.config/testpkg/target.lua" ]]; then
      if [[ "$S1_ROOT/repo/stow/testpkg/.config/testpkg/target.lua" -ef "$S1_ROOT/home/.config/testpkg/target.lua" ]]; then
        pass "SAFE-01 (S1): stow link identity verified (-ef confirms matching inode)"
      else
        fail "SAFE-01 (S1): target is symlink but does not resolve to repo source"
      fi
    else
      fail "SAFE-01 (S1): target is not a symlink after stow"
    fi
  else
    fail "SAFE-01 (S1): actual stow command failed in fixture"
  fi
fi

# ===========================================================================
# Section 2: SAFE-01: isolated fixture live undo drill and re-stow rehearsal
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 ]]; then
  info "--- Section 2: SAFE-01 isolated fixture live undo drill and re-stow rehearsal ---"

  S2_ROOT="$(mktemp -d /tmp/p20-assert-s2-XXXXXX)"
  SCRATCH_ROOTS+=("$S2_ROOT")

  # Setup mock hypr repo and live home
  mkdir -p "$S2_ROOT/repo/stow/hypr_drill/.config/hypr/custom"
  mkdir -p "$S2_ROOT/home/.config/hypr/custom"

  for f in variables.lua keybinds.lua rules.lua; do
    printf 'return "repo"\n' > "$S2_ROOT/repo/stow/hypr_drill/.config/hypr/custom/$f"
    printf 'return "legacy stub"\n' > "$S2_ROOT/home/.config/hypr/custom/$f"
  done

  # 1. Take timestamped backup
  BACKUP_EPOCH="$(date +%s)"
  BACKUP_DIR="$S2_ROOT/home/.config/hypr/custom.backup.$BACKUP_EPOCH"
  cp -a "$S2_ROOT/home/.config/hypr/custom" "$BACKUP_DIR"

  # 2. Prune stubs and execute initial stow
  rm -f "$S2_ROOT/home/.config/hypr/custom/"*.lua
  stow --no-folding -d "$S2_ROOT/repo/stow" -t "$S2_ROOT/home" hypr_drill

  ALL_LINKS=1
  for f in variables.lua keybinds.lua rules.lua; do
    if [[ ! -L "$S2_ROOT/home/.config/hypr/custom/$f" ]]; then
      ALL_LINKS=0
    fi
  done
  if [[ "$ALL_LINKS" -eq 1 ]]; then
    pass "SAFE-01 (S2): initial stow created symlinks for all target files"
  else
    fail "SAFE-01 (S2): initial stow did not create all expected symlinks"
  fi

  # 3. Execute undo drill: stow -D followed by backup restoration
  stow -D --no-folding -d "$S2_ROOT/repo/stow" -t "$S2_ROOT/home" hypr_drill

  ANY_LINK=0
  for f in variables.lua keybinds.lua rules.lua; do
    if [[ -e "$S2_ROOT/home/.config/hypr/custom/$f" || -L "$S2_ROOT/home/.config/hypr/custom/$f" ]]; then
      ANY_LINK=1
    fi
  done
  if [[ "$ANY_LINK" -eq 0 ]]; then
    pass "SAFE-01 (S2): unstow (stow -D) cleanly removed all managed symlinks"
  else
    fail "SAFE-01 (S2): unstow left residual symlinks or entries in target"
  fi

  # Restore from backup
  cp -a "$BACKUP_DIR/." "$S2_ROOT/home/.config/hypr/custom/"

  RESTORE_OK=1
  for f in variables.lua keybinds.lua rules.lua; do
    TGT="$S2_ROOT/home/.config/hypr/custom/$f"
    if [[ -L "$TGT" ]] || [[ ! -f "$TGT" ]] || ! grep -q 'legacy stub' "$TGT"; then
      RESTORE_OK=0
    fi
  done
  if [[ "$RESTORE_OK" -eq 1 ]]; then
    pass "SAFE-01 (S2): backup restoration restored exact pre-stow regular files and contents"
  else
    fail "SAFE-01 (S2): backup restoration failed to restore exact files or contents"
  fi

  # 4. Re-stow after rehearsal
  rm -f "$S2_ROOT/home/.config/hypr/custom/"*.lua
  stow --no-folding -d "$S2_ROOT/repo/stow" -t "$S2_ROOT/home" hypr_drill

  RESTOW_OK=1
  for f in variables.lua keybinds.lua rules.lua; do
    SRC="$S2_ROOT/repo/stow/hypr_drill/.config/hypr/custom/$f"
    TGT="$S2_ROOT/home/.config/hypr/custom/$f"
    if [[ ! -L "$TGT" ]] || [[ ! "$SRC" -ef "$TGT" ]]; then
      RESTOW_OK=0
    fi
  done
  if [[ "$RESTOW_OK" -eq 1 ]]; then
    pass "SAFE-01 (S2): re-stow cleanly restored symlink inode identity after undo rehearsal"
  else
    fail "SAFE-01 (S2): re-stow failed to establish matching inode symlinks"
  fi
fi

# ===========================================================================
# Section 3: HYPR-03: application defaults, rules, and vendor isolation
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 3 ]]; then
  info "--- Section 3: HYPR-03 application defaults, rules, and vendor isolation ---"

  VARS_FILE="stow/hypr/.config/hypr/custom/variables.lua"
  RULES_FILE="stow/hypr/.config/hypr/custom/rules.lua"
  ENV_FILE="stow/hypr/.config/hypr/custom/env.lua"

  # 1. Variables file assertions
  if [[ -f "$VARS_FILE" ]]; then
    pass "HYPR-03 (S3): variables.lua exists in stow tree"
    
    all_vars_ok=1
    var_patterns=(
      'terminal = "kitty"'
      'browser = "google-chrome-stable"'
      'fileManager = "dolphin"'
      'textEditor = "kitty -e nvim"'
      'taskManager = "kitty --class btop -e btop"'
      'officeSoftware = "libreoffice"'
      'workspaceGroupSize = 10'
      'hl\.env\("qsConfig", "ii"\)'
    )
    for pat in "${var_patterns[@]}"; do
      if ! grep -qE "$pat" "$VARS_FILE"; then
        all_vars_ok=0
        fail "HYPR-03 (S3): missing expected variable pattern: $pat"
      fi
    done
    if [[ "$all_vars_ok" -eq 1 ]]; then
      pass "HYPR-03 (S3): all 8 primary application variables locked per D-16"
    fi
  else
    fail "HYPR-03 (S3): variables.lua does not exist in stow tree"
  fi

  # 2. Rules file assertions
  if [[ -f "$RULES_FILE" ]]; then
    if grep -qF 'hl.window_rule({ match = { class = "^(main.py)$" }, float = true })' "$RULES_FILE" && \
       grep -qF 'hl.window_rule({ match = { class = "^(python3)$" }, float = true })' "$RULES_FILE"; then
      pass "HYPR-03 (S3): python float rules present in rules.lua per D-17"
    else
      fail "HYPR-03 (S3): python float rules missing from rules.lua"
    fi
  else
    fail "HYPR-03 (S3): rules.lua does not exist in stow tree"
  fi

  # 3. Env file assertions
  if [[ -f "$ENV_FILE" ]] && grep -q 'Authoring SoT: parent-repo' "$ENV_FILE"; then
    pass "HYPR-03 (S3): env.lua exists with authoring header per D-18"
  else
    fail "HYPR-03 (S3): env.lua missing or lacking authoring header"
  fi

  # 4. Vendor submodule cleanliness
  if git diff --exit-code vendor/dots-hyprland >/dev/null 2>&1; then
    pass "HYPR-03 (S3): vendor/dots-hyprland submodule has zero modifications"
  else
    fail "HYPR-03 (S3): vendor/dots-hyprland submodule has uncommitted modifications"
  fi
fi

# ===========================================================================
# Section 4: START-01: startup restore and lifecycle containment
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 4 ]]; then
  info "--- Section 4: START-01 startup restore and lifecycle containment ---"

  EXECS_FILE="stow/hypr/.config/hypr/custom/execs.lua"
  if [[ -f "$EXECS_FILE" ]]; then
    if grep -q 'hl\.on("hyprland\.start"' "$EXECS_FILE"; then
      pass "START-01 (S4): execs.lua registers commands inside hl.on('hyprland.start', ...)"
    else
      fail "START-01 (S4): execs.lua missing hl.on('hyprland.start', ...) single-fire lifecycle hook"
    fi

    all_execs_ok=1
    exec_cmds=(
      'systemctl --user start hyprland-session.service'
      '/usr/lib/polkit-kde-authentication-agent-1'
      '\[workspace 1\] google-chrome-stable --profile-directory=.Default. --ozone-platform-hint=auto'
      '\[workspace 1\] kitty -e tmux'
      '\[workspace special:btop silent\] kitty --class btop -e btop'
      '\[workspace special:social silent\] sh -c .command -v vesktop >/dev/null 2>&1 && exec vesktop || exec discord.'
    )
    for cmd_pat in "${exec_cmds[@]}"; do
      if ! grep -qE "$cmd_pat" "$EXECS_FILE"; then
        all_execs_ok=0
        fail "START-01 (S4): missing autostart command pattern: $cmd_pat"
      fi
    done
    if [[ "$all_execs_ok" -eq 1 ]]; then
      pass "START-01 (S4): all 6 restored autostart entries present inside startup hook"
    fi

    # Absence of wl-clip-persist
    if grep -q 'wl-clip-persist' "$EXECS_FILE"; then
      fail "START-01 (S4): wl-clip-persist found in execs.lua (should be omitted per D-03)"
    else
      pass "START-01 (S4): wl-clip-persist absent (Quickshell cliphist handles clipboard per D-03)"
    fi
  else
    fail "START-01 (S4): execs.lua does not exist in stow tree"
  fi
fi

# ===========================================================================
# Section 5: D-04: cursor theme consistency across toolkits
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 5 ]]; then
  info "--- Section 5: D-04 cursor theme consistency across toolkits ---"

  GTK3_FILE="$HOME/.config/gtk-3.0/settings.ini"
  XSETTINGS_FILE="$HOME/.config/xsettingsd/xsettingsd.conf"

  # 1. GTK-3 settings
  if [[ -f "$GTK3_FILE" ]]; then
    if grep -q '^gtk-cursor-theme-name=Bibata-Modern-Classic$' "$GTK3_FILE" && \
       grep -q '^gtk-cursor-theme-size=24$' "$GTK3_FILE"; then
      pass "D-04 (S5): GTK-3 settings.ini aligned to Bibata-Modern-Classic 24"
    else
      fail "D-04 (S5): GTK-3 settings.ini cursor theme/size not matching Bibata-Modern-Classic 24"
    fi
  else
    fail "D-04 (S5): $GTK3_FILE does not exist"
  fi

  # 2. XSettings config
  if [[ -f "$XSETTINGS_FILE" ]]; then
    if grep -q '^Gtk/CursorThemeName "Bibata-Modern-Classic"$' "$XSETTINGS_FILE" && \
       grep -q '^Gtk/CursorThemeSize 24$' "$XSETTINGS_FILE"; then
      pass "D-04 (S5): xsettingsd.conf aligned to Bibata-Modern-Classic 24"
    else
      fail "D-04 (S5): xsettingsd.conf cursor theme/size not matching Bibata-Modern-Classic 24"
    fi
  else
    fail "D-04 (S5): $XSETTINGS_FILE does not exist"
  fi

  # 3. Absence of legacy Catppuccin cursor overrides
  catppuccin_leak=0
  if grep -q 'catppuccin-mocha-blue-cursors' "$GTK3_FILE" 2>/dev/null; then
    catppuccin_leak=1
    fail "D-04 (S5): legacy catppuccin cursor found in GTK-3 settings.ini"
  fi
  if grep -q 'catppuccin-mocha-blue-cursors' "$XSETTINGS_FILE" 2>/dev/null; then
    catppuccin_leak=1
    fail "D-04 (S5): legacy catppuccin cursor found in xsettingsd.conf"
  fi
  if [[ "$catppuccin_leak" -eq 0 ]]; then
    pass "D-04 (S5): legacy catppuccin-mocha-blue-cursors purged from both toolkit configs"
  fi
fi

# ===========================================================================
# Section 6: HYPR-02: keybind unbinds and cheatsheet taxonomy
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 6 ]]; then
  info "--- Section 6: HYPR-02 keybind unbinds and cheatsheet taxonomy ---"

  KEYBINDS_FILE="stow/hypr/.config/hypr/custom/keybinds.lua"
  if [[ -f "$KEYBINDS_FILE" ]]; then
    pass "HYPR-02 (S6): keybinds.lua exists in stow tree"

    # 1. Lua syntax check
    if luac -p "$KEYBINDS_FILE" >/dev/null 2>&1; then
      pass "HYPR-02 (S6): keybinds.lua passes luac syntax validation"
    else
      fail "HYPR-02 (S6): keybinds.lua failed luac syntax validation"
    fi

    # 2. Verify all 9 unbind chords
    unbind_chords=(
      'hl\.unbind\("SUPER \+ C"\)'
      'hl\.unbind\("SUPER \+ L"\)'
      'hl\.unbind\("SUPER \+ K"\)'
      'hl\.unbind\("SUPER \+ J"\)'
      'hl\.unbind\("SUPER \+ D"\)'
      'hl\.unbind\("SUPER \+ P"\)'
      'hl\.unbind\("SUPER \+ M"\)'
      'hl\.unbind\("SUPER \+ S"\)'
      'hl\.unbind\("SUPER \+ Minus"\)'
    )
    all_unbinds_ok=1
    for ub in "${unbind_chords[@]}"; do
      if ! grep -qE "$ub" "$KEYBINDS_FILE"; then
        all_unbinds_ok=0
        fail "HYPR-02 (S6): missing unbind declaration: $ub"
      fi
    done
    if [[ "$all_unbinds_ok" -eq 1 ]]; then
      pass "HYPR-02 (S6): all 9 upstream unbind declarations present per D-06"
    fi

    # 3. Python verification for cheatsheet taxonomy and non-duplication
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
        pass "HYPR-02 (S6): all $COUNT keybinds strictly adhere to 'Category: Label' taxonomy"
        pass "HYPR-02 (S6): zero duplicate key chords detected within keybinds.lua"
        ;;
      BAD_DESC:*)
        fail "HYPR-02 (S6): descriptions not following Category: Label taxonomy: ${TAXONOMY_RES#BAD_DESC:}"
        ;;
      DUPS:*)
        fail "HYPR-02 (S6): duplicate key chord bindings found: ${TAXONOMY_RES#DUPS:}"
        ;;
      *)
        fail "HYPR-02 (S6): python taxonomy inspection failed: $TAXONOMY_RES"
        ;;
    esac
  else
    fail "HYPR-02 (S6): keybinds.lua does not exist in stow tree"
  fi
fi

# ===========================================================================
# Section 7: HYPR-01: live overlay link identity and no parent directory folding
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 7 ]]; then
  info "--- Section 7: HYPR-01 live overlay link identity and no parent directory folding ---"

  CUSTOM_DIR="$HOME/.config/hypr/custom"

  # 1. Assert custom dir is real directory and not a symlink (no folding)
  if [[ -d "$CUSTOM_DIR" ]] && [[ ! -L "$CUSTOM_DIR" ]]; then
    pass "HYPR-01 (S7): ~/.config/hypr/custom is a real directory (universal --no-folding preserved)"
  else
    fail "HYPR-01 (S7): ~/.config/hypr/custom is missing or folded into a symlink"
  fi

  # 2. Assert each of the 6 files is a symlink with matching inode identity
  overlay_files=(
    env.lua
    execs.lua
    general.lua
    keybinds.lua
    rules.lua
    variables.lua
  )

  all_overlay_ok=1
  for f in "${overlay_files[@]}"; do
    live_path="$CUSTOM_DIR/$f"
    repo_path="$REPO_ROOT/stow/hypr/.config/hypr/custom/$f"

    if [[ ! -L "$live_path" ]]; then
      all_overlay_ok=0
      fail "HYPR-01 (S7): live path is not a symlink: $live_path"
    elif [[ ! -e "$live_path" ]]; then
      all_overlay_ok=0
      fail "HYPR-01 (S7): live symlink is broken: $live_path"
    elif [[ ! "$repo_path" -ef "$live_path" ]]; then
      all_overlay_ok=0
      fail "HYPR-01 (S7): inode mismatch between repo ($repo_path) and live ($live_path)"
    else
      pass "HYPR-01 (S7): verified link identity: $live_path -> $repo_path"
    fi
  done

  if [[ "$all_overlay_ok" -eq 1 ]]; then
    pass "HYPR-01 (S7): all 6 overlay files have confirmed link inode identity with repository source"
  fi

  # 3. dots-hyprland.sh verify --strict gate
  VERIFY_OUT="$(mktemp /tmp/p20-s7-verify-XXXXXX)"
  TMP_FILES+=("$VERIFY_OUT")
  if "$REPO_ROOT/arch/dots-hyprland.sh" verify --strict >"$VERIFY_OUT" 2>&1; then
    pass "HYPR-01 (S7): arch/dots-hyprland.sh verify --strict passed cleanly (FAIL=0 FINDINGS=0)"
  else
    fail "HYPR-01 (S7): arch/dots-hyprland.sh verify --strict failed"
    sed 's/^/  [VERIFY-FAIL] /' "$VERIFY_OUT" >&2 || true
  fi
fi

# ===========================================================================
# Terminal Summary
# ===========================================================================
echo "=== done: FAIL=${FAIL} FINDINGS=${FINDINGS} ==="
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
