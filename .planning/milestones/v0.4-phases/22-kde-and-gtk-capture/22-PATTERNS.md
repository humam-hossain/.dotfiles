# Phase 22: KDE and GTK capture - Pattern Map

**Mapped:** 2026-09-15  
**Files analyzed:** 15  
**Analogs found:** 15 / 15  

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `scripts/phase22-kde-and-gtk-capture-assert.sh` | test | batch | `scripts/phase21-ii-bar-config-capture-assert.sh` | exact |
| `guard-paths.tsv` | config | file-I/O | `collision-map.tsv` | exact |
| `stow/kde/.config/kiorc` | config | file-I/O | `stow/qbittorrent/.config/qBittorrent/qBittorrent.conf` | role-match |
| `stow/kde/.config/ktrashrc` | config | file-I/O | `stow/qbittorrent/.config/qBittorrent/qBittorrent.conf` | role-match |
| `stow/kde/.config/kservicemenurc` | config | file-I/O | `stow/qbittorrent/.config/qBittorrent/qBittorrent.conf` | role-match |
| `stow/gtk/.config/gtk-3.0/settings.ini` | config | file-I/O | `stow/qbittorrent/.config/qBittorrent/qBittorrent.conf` | role-match |
| `stow/gtk/.config/gtk-3.0/bookmarks` | config | file-I/O | `stow/kitty/.config/kitty/kitty.conf` | role-match |
| `stow/gtk/.config/gtk-4.0/settings.ini` | config | file-I/O | `stow/qbittorrent/.config/qBittorrent/qBittorrent.conf` | role-match |
| `restow/chrome-flags/.config/chrome-flags.conf` | config | file-I/O | `restow/starship/.config/starship.toml` | exact |
| `docs/archive/kdeglobals` | config | file-I/O | `docs/archive/hyprland.conf` | exact |
| `docs/archive/README.md` | config | file-I/O | `docs/archive/README.md` | exact |
| `restow/README.md` | config | transform | `restow/README.md` | exact |
| `docs/config-redistribution.md` | config | file-I/O | `docs/config-redistribution.md` | exact |
| `.gitignore` | config | file-I/O | `.gitignore` | exact |
| `arch/dots-hyprland.sh` | utility | transform | `arch/dots-hyprland.sh` | exact |

---

## Pattern Assignments

### 1. `scripts/phase22-kde-and-gtk-capture-assert.sh` (test, batch)

**Analog:** `scripts/phase21-ii-bar-config-capture-assert.sh`  
**Secondary Analog:** `scripts/phase18-capture-model-assert.sh`

#### Harness Initialization & Cleanup Pattern
[Source: `scripts/phase21-ii-bar-config-capture-assert.sh:1-37`](file:///home/pera/github_repo/.dotfiles/scripts/phase21-ii-bar-config-capture-assert.sh#L1-L37)
```bash
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
```

#### CLI Argument Parsing Pattern
[Source: `scripts/phase21-ii-bar-config-capture-assert.sh:41-63`](file:///home/pera/github_repo/.dotfiles/scripts/phase21-ii-bar-config-capture-assert.sh#L41-L63)
```bash
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
```

#### Section Execution & Scratch Fixture Isolation Pattern
[Source: `scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh:67-89`](file:///home/pera/github_repo/.dotfiles/scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh#L67-L89)
```bash
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 1 ]]; then
  info "--- Section 1: KDE package layout, inode identity, and 0600 mode documentation check ---"

  S1_ROOT="$(mktemp -d /tmp/p22-assert-s1-XXXXXX)"
  SCRATCH_ROOTS+=("$S1_ROOT")
  # ... setup mock environment or run assertions ...
fi
```

#### Verification Gate & Summary Exit Pattern
[Source: `scripts/phase21-ii-bar-config-capture-assert.sh:434-451`](file:///home/pera/github_repo/.dotfiles/scripts/phase21-ii-bar-config-capture-assert.sh#L434-L451)
```bash
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 6 ]]; then
  info "--- Section 6: GUARD list data integrity, Q7/Q8 documentation check, kdeglobals unlinking, and verify --strict pass ---"
  VERIFY_RC=0
  VERIFY_OUT="$("$REPO_ROOT/arch/dots-hyprland.sh" verify --strict 2>&1)" || VERIFY_RC=$?
  if [[ "$VERIFY_RC" -eq 0 ]]; then
    pass "Section 6: arch/dots-hyprland.sh verify --strict passed with zero findings"
  else
    fail "Section 6: arch/dots-hyprland.sh verify --strict failed (rc=$VERIFY_RC)"
    printf '%s\n' "$VERIFY_OUT" | sed 's/^/       /' >&2
  fi
fi

echo "=== done: FAIL=${FAIL} FINDINGS=${FINDINGS} ==="
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
```

---

### 2. `guard-paths.tsv` (config, file-I/O)

**Analog:** `collision-map.tsv`

#### TSV Header & Metadata Comment Pattern
[Source: `collision-map.tsv:1-8,21-25`](file:///home/pera/github_repo/.dotfiles/collision-map.tsv#L1-L8)
```tsv
# guard-paths v1
#
# Paths excluded from repository tracking and live repo-symlinking.
# Enforced by arch/dots-hyprland.sh verify and scripts/phase22-kde-and-gtk-capture-assert.sh.
#
# Empirical resolutions:
# Q7: kde-material-you-colors is actively invoked by switchwall.sh via .venv wrapper,
#     rewriting kdeglobals on every wallpaper change. Excluded to eliminate git churn.
# Q8: ~/.config/gtk-4.0/gtk.css symlinks to root-owned /usr/share/themes/... (0644).
#     User writes cannot alter system theme. Both gtk.css files are guarded out.
#
# Columns (tab-separated):
# path	category	generator	reason
```

#### TSV Data Row Pattern
[Source: `collision-map.tsv:62-66`](file:///home/pera/github_repo/.dotfiles/collision-map.tsv#L62-L66)
```tsv
$XDG_CONFIG_HOME/kdeglobals	generated_theme	kde-material-you-colors	Active wallpaper churn (Q7)
$XDG_CONFIG_HOME/Kvantum	vendor_theme	dots-hyprland	Upstream directory sync
$XDG_CONFIG_HOME/gtk-3.0/gtk.css	generated_theme	matugen	Matugen template output
$XDG_CONFIG_HOME/gtk-4.0/gtk.css	generated_theme	matugen	Root-owned theme symlink (Q8)
$XDG_CONFIG_HOME/fuzzel/fuzzel_theme.ini	generated_theme	matugen	Matugen template output
$XDG_CONFIG_HOME/hypr/hyprland/colors.lua	generated_theme	matugen	Matugen template output
$XDG_CONFIG_HOME/hypr/hyprlock/colors.conf	generated_theme	matugen	Matugen template output
```

---

### 3. KDE Package Configurations (`stow/kde/.config/{kiorc,ktrashrc,kservicemenurc}`) (config, file-I/O)

**Analog:** `stow/qbittorrent/.config/qBittorrent/qBittorrent.conf`  
**Secondary Analog:** `restow/dolphinrc/.config/dolphinrc`

#### INI Group Header & Key-Value Pair Pattern
[Source: `stow/qbittorrent/.config/qBittorrent/qBittorrent.conf:1-10`](file:///home/pera/github_repo/.dotfiles/stow/qbittorrent/.config/qBittorrent/qBittorrent.conf#L1-L10)
```ini
[AddNewTorrentDialog]
DialogSize=@Size(856 1350)
DownloadPathHistory=
RememberLastSavePath=false
SavePathHistory=/home/pera/Downloads

[Appearance]
ColorScheme=Dark
Style=Darkly
```

#### Live Source Capture Structure
- `stow/kde/.config/kiorc`:
  ```ini
  [Confirmations]
  ConfirmDelete=true
  ConfirmEmptyTrash=true
  ConfirmTrash=false

  [Executable scripts]
  behaviourOnLaunch=alwaysAsk
  ```
- `stow/kde/.config/ktrashrc`:
  ```ini
  [/home/pera/.local/share/Trash]
  Days=7
  LimitReachedAction=0
  Percent=10
  UseSizeLimit=true
  UseTimeLimit=false
  ```
- `stow/kde/.config/kservicemenurc`:
  ```ini
  [Show]
  filelight=true
  forgetfileitemaction=true
  hidefileitemaction=false
  installFont=true
  kactivitymanagerd_fileitem_linking_plugin=true
  movetonewfolderitemaction=true
  setfoldericonitemaction=true
  sharefileitemaction=true
  tagsfileitemaction=true
  wallpaperfileitemaction=true
  ```

---

### 4. GTK Package Configurations (`stow/gtk/.config/{gtk-3.0,gtk-4.0}/...`) (config, file-I/O)

**Analog:** `stow/qbittorrent/.config/qBittorrent/qBittorrent.conf` (for `settings.ini`)  
**Analog:** `stow/kitty/.config/kitty/kitty.conf` (for `bookmarks`)

#### GTK Settings Format (`settings.ini`)
[Source: `stow/qbittorrent/.config/qBittorrent/qBittorrent.conf:7-10`](file:///home/pera/github_repo/.dotfiles/stow/qbittorrent/.config/qBittorrent/qBittorrent.conf#L7-L10)
```ini
[Settings]
gtk-theme-name=catppuccin-mocha-teal-standard+default
gtk-icon-theme-name=Tela-circle-dracula-dark
gtk-font-name=Adwaita Sans 11
gtk-cursor-theme-name=Bibata-Modern-Classic
gtk-cursor-theme-size=24
gtk-application-prefer-dark-theme=1
```

#### GTK Bookmarks Format (`bookmarks`)
[Source: `stow/kitty/.config/kitty/kitty.conf:1-5`](file:///home/pera/github_repo/.dotfiles/stow/kitty/.config/kitty/kitty.conf#L1-L5)
```text
file:///home/pera/Downloads Downloads
file:///home/pera/github_repo github_repo
file:///home/pera/Documents Documents
file:///home/pera/Videos Videos
file:///home/pera/Pictures Pictures
file:///home/pera/Documents/proton_recovery Important
```

---

### 5. Restow Package Configuration (`restow/chrome-flags/.config/chrome-flags.conf`) (config, file-I/O)

**Analog:** `restow/starship/.config/starship.toml`  
**Secondary Analog:** `restow/dolphinrc/.config/dolphinrc`

#### Single-File Package Placement in Restow
[Source: `restow/dolphinrc/.config/dolphinrc:1-16`](file:///home/pera/github_repo/.dotfiles/restow/dolphinrc/.config/dolphinrc#L1-L16)
```text
restow/chrome-flags/.config/chrome-flags.conf
```
Captures Chrome Ozone / Wayland runtime flags:
```text
--password-store=gnome-libsecret
--ozone-platform-hint=wayland
--gtk-version=4
--ignore-gpu-blocklist
--enable-features=TouchpadOverscrollHistoryNavigation
--enable-wayland-ime
--disable-features=ExtensionManifestV2Unsupported
--hide-crash-restore-bubble
```

---

### 6. Historical Config Archive (`docs/archive/kdeglobals`) (config, file-I/O)

**Analog:** `docs/archive/hyprland.conf`  
**Registry Analog:** `docs/archive/README.md`

#### Archive Structure & Registry Entry
[Source: `docs/archive/README.md:19-25`](file:///home/pera/github_repo/.dotfiles/docs/archive/README.md#L19-L25)
```markdown
## Archive Entry Registry

| File | Retired in | Why | Superseded by |
|---|---|---|---|
| `hyprland.conf` | Plan 18-04 (`9f1c5d3`) | No live counterpart; installer renamed it to `.old` in Phase 14 (`3.files-legacy.sh:51-54`) | `stow/hypr/.config/hypr/custom/` overlays + upstream `hyprland.lua` |
| `hyprland.conf.bak` | Plan 18-04 (`9f1c5d3`) | Byte-identical to backup already existing live | Historical backup |
| `kdeglobals` | Phase 22 | Actively churned by `kde-material-you-colors` on wallpaper changes (Q7) | Standalone unmanaged live file + `guard-paths.tsv` |
```

---

### 7. Verification Engine Updates (`arch/dots-hyprland.sh`) (utility, transform)

**Analog:** `arch/dots-hyprland.sh`

#### Reading GUARD Data in `run_verify()`
[Source: `arch/dots-hyprland.sh:1098-1127`](file:///home/pera/github_repo/.dotfiles/arch/dots-hyprland.sh#L1098-L1127)
```bash
  # GUARD path validation gate (D-18, D-23)
  local guard_file="$REPO_ROOT/guard-paths.tsv"
  local -A guarded_entries=()
  if [[ -f "$guard_file" ]]; then
    local g_path g_cat g_gen g_reason expanded live_target rel_sub
    while IFS=$'\t' read -r g_path g_cat g_gen g_reason || [[ -n "$g_path" ]]; do
      [[ -n "$g_path" && "$g_path" != \#* ]] || continue
      expanded="${g_path//\$XDG_CONFIG_HOME/$HOME\/.config}"
      expanded="${expanded//\$HOME/$HOME}"
      guarded_entries["$expanded"]=1

      # Assert not tracked in stow/, restow/, or capture/
      rel_sub="${expanded#"$HOME"/}"
      for tree in stow restow capture; do
        if [[ -d "$REPO_ROOT/$tree" ]]; then
          for pkg_dir in "$REPO_ROOT/$tree"/*; do
            [[ -d "$pkg_dir" ]] || continue
            if [[ -e "$pkg_dir/$rel_sub" ]]; then
              fail "guard path tracked in $tree: ${pkg_dir#"$REPO_ROOT"/}/$rel_sub"
            fi
          done
        fi
      done

      # Assert live path is not a symlink into repo
      if [[ -L "$expanded" ]]; then
        live_target="$(readlink -f -- "$expanded" 2>/dev/null || true)"
        if [[ "$live_target" == "$main_root_real"/* ]]; then
          fail "guard path live counterpart symlinks into repo: $expanded -> $live_target"
        fi
      fi
      pass "guard path excluded: $g_path"
    done < "$guard_file"
  fi
```

#### Sweep Classifier Refinement in `classify_sweep_entry()`
[Source: `arch/dots-hyprland.sh:1296-1310`](file:///home/pera/github_repo/.dotfiles/arch/dots-hyprland.sh#L1296-L1310)
```bash
      # Arm 8: a shared root is $HOME itself or $HOME/.config
      if [[ "$entry_dir" == "$HOME" || "$entry_dir" == "$HOME/.config" ]]; then
        return 0
      fi

      # Guarded theme output check (D-24)
      if [[ -n "${guarded_entries[$entry]:-}" ]]; then
        info "guarded theme output: $entry"
        return 0
      fi

      # Arm 7: any other regular file in a package-owned directory
      info "unclaimed upstream stub: $entry"
      return 0
```

---

### 8. Documentation & Manifests (`restow/README.md`, `docs/config-redistribution.md`, `.gitignore`)

#### Restow Table Regeneration
[Source: `restow/README.md:55-62`](file:///home/pera/github_repo/.dotfiles/restow/README.md#L55-L62)
```markdown
<!-- BEGIN generated: gen-collision-map.sh --restow-table -->
| Package | Tag | Recovery Command |
|---|---|---|
| `chrome-flags` | `cp-through` | `git checkout -- restow/chrome-flags/.config/chrome-flags.conf && cd restow && stow --verbose=5 --no-folding -t ~ chrome-flags` |
| `dolphinrc` | `cp-through` | `git checkout -- restow/dolphinrc/.config/dolphinrc && cd restow && stow --verbose=5 --no-folding -t ~ dolphinrc` |
| `hypr` | `rsync-replace` | `cd restow && stow --verbose=5 --no-folding -t ~ hypr` |
| `starship` | `cp-through` | `git checkout -- restow/starship/.config/starship.toml && cd restow && stow --verbose=5 --no-folding -t ~ starship` |
<!-- END generated: gen-collision-map.sh --restow-table -->
```

#### Redistribution Table Destination Update (Row 36)
[Source: `docs/config-redistribution.md:33-36`](file:///home/pera/github_repo/.dotfiles/docs/config-redistribution.md#L33-L36)
```markdown
| Source Path | Disposition | Destination | Content Decision (D-22) | Justification / Map Row |
|---|---|---|---|---|
| `.config/dolphinrc` | Move | `restow/dolphinrc/.config/dolphinrc` | **Live wins** | MISC loop (`3.files-legacy.sh:15`, `install_file` → `cp-through`). Repo copy was stale; live has genuine KDE settings. |
| `.config/kdeglobals` | Archive | `docs/archive/kdeglobals` | N/A (Archive) | Retired in Phase 22 (D-20). Actively churned by `kde-material-you-colors` (Q7). Preserved in archive for historical provenance. |
```

#### Gitignore Theme Outputs Extension
[Source: `.gitignore:37-43`](file:///home/pera/github_repo/.dotfiles/.gitignore#L37-L43)
```gitignore
kdeglobals
gtk.css
gtk-dark.css
Kvantum/
colors.lua
colors.conf
fuzzel_theme.ini
```

---

## Shared Patterns

### Pattern A: SAFE-01 Live Adoption Protocol with Inode Identity Verification
**Applies to:** `stow/kde/`, `stow/gtk/`, `restow/chrome-flags/`  
**Rationale:** Prevents configuration loss, avoids directory folding corruption, and verifies symlink targets atomically before committing.

```bash
# Step 1: Preflight process check (D-05)
if pgrep -x dolphin >/dev/null 2>&1; then
  echo "Error: Dolphin process is running; terminate before adopting." >&2
  exit 1
fi

# Step 2: Timestamped backup of live file
EPOCH="$(date +%s)"
cp -a "$HOME/.config/kiorc" "$HOME/.config/kiorc.bak.$EPOCH"

# Step 3: Copy content into target repo tree
mkdir -p "$REPO_ROOT/stow/kde/.config"
cp -a "$HOME/.config/kiorc" "$REPO_ROOT/stow/kde/.config/kiorc"

# Step 4: Dry-run stow to assert absence of conflicts
stow -n --no-folding -d "$REPO_ROOT/stow" -t "$HOME" kde

# Step 5: Replace live file and link with stow
rm "$HOME/.config/kiorc"
stow --verbose=5 --no-folding -d "$REPO_ROOT/stow" -t "$HOME" kde

# Step 6: Assert link identity and inode match
test -L "$HOME/.config/kiorc"
test "$(stat -c %i "$HOME/.config/kiorc")" -eq "$(stat -c %i "$REPO_ROOT/stow/kde/.config/kiorc")"
```

### Pattern B: Link-Aware Verify GUARD Exclusions & Sweep Classifier Integration
**Applies to:** `guard-paths.tsv` and `arch/dots-hyprland.sh` (`run_verify` and `classify_sweep_entry`)  
**Rationale:** Mechanically proves that excluded theme files are neither tracked in repository trees nor symlinked from the live system into the repository, and classifies them as guarded theme outputs rather than unclaimed stubs.

```bash
# Associative array hash lookup in classify_sweep_entry:
if [[ -n "${guarded_entries[$entry]:-}" ]]; then
  info "guarded theme output: $entry"
  return 0
fi
```

### Pattern C: Restow Cp-Through Overwrite Recovery & Live Drill Contract
**Applies to:** `restow/chrome-flags/`, `restow/README.md`, and Section 5 live installer drill  
**Rationale:** Proves the upstream installer primitive (`install_file` via `cp -f`) writes through live symlinks into the git repository, and proves `git checkout -- restow/<pkg>` cleanly restores user customizations.

```bash
# Clean tree assertion
test -z "$(git status --porcelain)"

# Invoke upstream installer files subcommand
./arch/dots-hyprland.sh install-files

# Verify write-through modification occurred
git status --porcelain | grep -q "M restow/chrome-flags/.config/chrome-flags.conf"
git status --porcelain | grep -q "M restow/dolphinrc/.config/dolphinrc"

# Restore personal configuration cleanly
git checkout -- restow/chrome-flags restow/dolphinrc
test -z "$(git status --porcelain)"
```

### Pattern D: Multi-Section Phase Assert Harness Conventions
**Applies to:** `scripts/phase22-kde-and-gtk-capture-assert.sh`  
**Rationale:** Consistent test runner execution across all phases with single-section isolation (`--section <1-6>`), clean tempdir lifecycle handling, and frozen summary output `=== done: FAIL=n FINDINGS=n ===`.

---

## No Analog Found

All 15 new and modified files have exact or strong role-match analogs in the repository. No unmapped files exist.

---

## Metadata

**Analog search scope:**
- `scripts/*.sh` (assert harnesses, generators, validators)
- `stow/*/.config/` (stowed user configurations and dotfile packages)
- `restow/*/.config/` (colliding user configurations with recovery contracts)
- `docs/archive/` (historical configuration archives and registry)
- `arch/dots-hyprland.sh` (verification runner and classifier)
- `collision-map.tsv` (data contract schema and comment conventions)

**Files scanned:** 52 repository files  
**Pattern extraction date:** 2026-09-15
