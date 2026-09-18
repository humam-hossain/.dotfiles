# Phase 29: Theme Data Contracts, Verification & Bootstrap Integration - Pattern Map

**Mapped:** 2026-09-18  
**Phase:** 29 - Theme Data Contracts, Verification & Bootstrap Integration  
**Files classified:** 9  
**Analogs found:** 9 / 9 (100% coverage)  

---

## 1. Executive Summary

Phase 29 serves as the capstone integration and verification phase for Milestone v0.5 ("System-wide Material You theming"). It reconciles data contracts, guarantees zero git churn on theme generation, aligns repository tree taxonomy with mathematical installer outcomes, and validates end-to-end bootstrap integration across the complete desktop shell.

This document identifies every file created or modified in Phase 29, classifies its role and data flow, maps it to concrete existing analogs in the codebase, and provides exact, copy-pasteable code excerpts and implementation patterns. Downstream planning and implementation agents must follow these patterns to prevent regression and satisfy all phase requirements (`INTG-01`, `INTG-02`, `INTG-03`).

---

## 2. File Classification

| File / Component | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `guard-paths.tsv` | data contract | file-I/O | [guard-paths.tsv](file:///home/pera/github_repo/.dotfiles/guard-paths.tsv#L1-L22) & [scripts/phase22-kde-and-gtk-capture-assert.sh](file:///home/pera/github_repo/.dotfiles/scripts/phase22-kde-and-gtk-capture-assert.sh#L450-L495) | exact |
| `.gitignore` | exclusion rules | git status / porcelain | [.gitignore](file:///home/pera/github_repo/.dotfiles/.gitignore#L37-L44) | exact |
| `stow/` $\rightarrow$ `restow/` (`restow/fuzzel`, `restow/kitty`) | package placement (taxonomy) | symlink mapping / file-I/O | [restow/hypr](file:///home/pera/github_repo/.dotfiles/restow/hypr), [restow/dolphinrc](file:///home/pera/github_repo/.dotfiles/restow/dolphinrc), [restow/chrome-flags](file:///home/pera/github_repo/.dotfiles/restow/chrome-flags) | exact |
| `restow/README.md` | documentation / recovery table | machine-generated Markdown | [restow/README.md](file:///home/pera/github_repo/.dotfiles/restow/README.md#L46-L63) & [scripts/gen-collision-map.sh](file:///home/pera/github_repo/.dotfiles/scripts/gen-collision-map.sh#L321-L389) | exact |
| `arch/kitty.sh` | installer / stow invocation | process execution / CLI | [arch/kitty.sh](file:///home/pera/github_repo/.dotfiles/arch/kitty.sh#L1-L11) | exact |
| `arch/dots-hyprland.sh` | CLI wrapper / verify engine | filesystem traversal / link inspection | [arch/dots-hyprland.sh](file:///home/pera/github_repo/.dotfiles/arch/dots-hyprland.sh#L1135-L1167) & [arch/dots-hyprland.sh](file:///home/pera/github_repo/.dotfiles/arch/dots-hyprland.sh#L1340-L1353) | exact |
| `bootstrap.sh` | orchestrator / state machine | multi-stage execution / backup / stow | [bootstrap.sh](file:///home/pera/github_repo/.dotfiles/bootstrap.sh#L315-L325), [bootstrap.sh](file:///home/pera/github_repo/.dotfiles/bootstrap.sh#L425-L473), [bootstrap.sh](file:///home/pera/github_repo/.dotfiles/bootstrap.sh#L483-L531) | exact |
| `scripts/phase28-terminal-fuzzel-assert.sh` | regression test harness | file inspection / assertions | [scripts/phase28-terminal-fuzzel-assert.sh](file:///home/pera/github_repo/.dotfiles/scripts/phase28-terminal-fuzzel-assert.sh#L107-L155) | exact |
| `scripts/phase29-theme-data-contracts-assert.sh` | authoritative test harness | test runner / mtime check / scratch drill / regression sweep | [scripts/phase28-terminal-fuzzel-assert.sh](file:///home/pera/github_repo/.dotfiles/scripts/phase28-terminal-fuzzel-assert.sh#L1-L80) & [scripts/phase23-bootstrap-assert.sh](file:///home/pera/github_repo/.dotfiles/scripts/phase23-bootstrap-assert.sh#L100-L160) | exact |

---

## 3. Pattern Assignments & Concrete Implementation Excerpts

### 3.1. `guard-paths.tsv` (Data Contract)

**Role:** Canonical, machine-readable data contract defining dynamically generated paths that must never be committed to git or symlinked into repository packaging trees.  
**Data Flow:** Read line-by-line by `arch/dots-hyprland.sh run_verify()`, `bootstrap.sh run_destub()`, and assert suites.  
**Analogs:** [guard-paths.tsv](file:///home/pera/github_repo/.dotfiles/guard-paths.tsv#L1-L22) and [scripts/phase22-kde-and-gtk-capture-assert.sh](file:///home/pera/github_repo/.dotfiles/scripts/phase22-kde-and-gtk-capture-assert.sh#L483-L494).  

#### Critical Invariants
- Must contain exactly 8 valid tab-separated rows.
- Header comments must document the full v0.5 architecture rationale across GTK, Qt/KDE, Hyprland/Quickshell, and Terminal/Fuzzel.
- **PITFALL GUARD:** Must retain the literal markers `"Q7:"` and `"Q8:"` and their referenced strings (`kde-material-you-colors` and `gtk-4.0/gtk.css`) to prevent breaking `scripts/phase22-kde-and-gtk-capture-assert.sh:484,490`.

#### Complete Target Contract
```tsv
# guard-paths v1
#
# Paths excluded from repository tracking and live repo-symlinking.
# Enforced by arch/dots-hyprland.sh verify, bootstrap.sh, and phase assert suites.
#
# v0.5 Material You Desktop Shell Dynamic Outputs:
# 1. $XDG_CONFIG_HOME/kdeglobals: Actively churned by kde-material-you-colors on wallpaper change (Q7).
# 2. $XDG_CONFIG_HOME/Kvantum: Upstream theme engine directory synced by dots-hyprland installer.
# 3. $XDG_CONFIG_HOME/gtk-3.0/gtk.css: Dynamically generated by Matugen from wallpaper colors.
# 4. $XDG_CONFIG_HOME/gtk-4.0/gtk.css: Dynamically generated by Matugen (de-linked from root-owned Catppuccin) (Q8).
# 5. $XDG_CONFIG_HOME/fuzzel/fuzzel_theme.ini: Dynamically generated by Matugen for Fuzzel launcher.
# 6. $XDG_CONFIG_HOME/hypr/hyprland/colors.lua: Dynamically generated by Matugen for Hyprland window borders.
# 7. $XDG_CONFIG_HOME/hypr/hyprlock/colors.conf: Dynamically generated by Matugen for Hyprlock screen locker.
# 8. $XDG_CONFIG_HOME/kde-material-you-colors: Generator runtime configuration and state directory.
#
# Columns (tab-separated):
# path	category	generator	reason
$XDG_CONFIG_HOME/kdeglobals	generated_theme	kde-material-you-colors	Active wallpaper churn (Q7)
$XDG_CONFIG_HOME/Kvantum	vendor_theme	dots-hyprland	Upstream directory sync
$XDG_CONFIG_HOME/gtk-3.0/gtk.css	generated_theme	matugen	Matugen template output
$XDG_CONFIG_HOME/gtk-4.0/gtk.css	generated_theme	matugen	Root-owned theme symlink (Q8)
$XDG_CONFIG_HOME/fuzzel/fuzzel_theme.ini	generated_theme	matugen	Matugen template output
$XDG_CONFIG_HOME/hypr/hyprland/colors.lua	generated_theme	matugen	Matugen template output
$XDG_CONFIG_HOME/hypr/hyprlock/colors.conf	generated_theme	matugen	Matugen template output
$XDG_CONFIG_HOME/kde-material-you-colors	generated_theme	kde-material-you-colors	Upstream directory sync
```

---

### 3.2. `.gitignore` (Git Working-Tree Exclusion Rules)

**Role:** Root repository exclusion rules preventing dynamic theme generator side-effects from dirtying `git status --porcelain`.  
**Data Flow:** Consulted by `git` during every working-tree operation.  
**Analog:** [.gitignore](file:///home/pera/github_repo/.dotfiles/.gitignore#L37-L44).  

#### Critical Invariants
- 100% 1:1 parity with the 8 entries in `guard-paths.tsv`.
- Add `kde-material-you-colors/` under the `# Generated theme output (D-14)` section.

#### Concrete Excerpt Pattern
**Target:** [.gitignore](file:///home/pera/github_repo/.dotfiles/.gitignore#L37-L44)
```gitignore
# Generated theme output (D-14) — matugen rewrites these on every wallpaper or
# colour-scheme change, so tracking them means a diff per wallpaper.
kdeglobals
gtk.css
gtk-dark.css
Kvantum/
colors.lua
colors.conf
fuzzel_theme.ini
kde-material-you-colors/
```

---

### 3.3. Package Relocation & Three-Tree Taxonomy Alignment (`stow/` $\rightarrow$ `restow/`)

**Role:** Enforce the mathematical invariant derived from `vendor/dots-hyprland/sdata/subcmd-install/3.files-legacy.sh:14`:
$$\text{symlink outcome} = \text{DESTROYED} \implies \text{tree} = \text{restow}$$
**Data Flow:** GNU Stow links `$HOME/.config/fuzzel` and `$HOME/.config/kitty` to `restow/fuzzel` and `restow/kitty` instead of `stow/`.  
**Analogs:** [restow/hypr](file:///home/pera/github_repo/.dotfiles/restow/hypr), [collision-map.tsv](file:///home/pera/github_repo/.dotfiles/collision-map.tsv#L70-L80).  

#### Procedure Pattern
To avoid stow collisions or broken symlink pointers:
```bash
# 1. Unstow live symlinks from stow/
cd "$REPO_ROOT/stow"
stow -D --verbose=5 --no-folding -t ~ fuzzel kitty

# 2. Relocate package directories in git
cd "$REPO_ROOT"
git mv stow/fuzzel restow/fuzzel
git mv stow/kitty restow/kitty

# 3. Stow live symlinks from restow/
cd "$REPO_ROOT/restow"
stow --verbose=5 --no-folding -t ~ fuzzel kitty
```

---

### 3.4. `restow/README.md` (Package Recovery Table)

**Role:** Documents the restow tree discipline and hosts Section 3 machine-generated package recovery commands.  
**Data Flow:** Regenerated automatically by invoking `./scripts/gen-collision-map.sh --restow-table`.  
**Analogs:** [restow/README.md](file:///home/pera/github_repo/.dotfiles/restow/README.md#L46-L63) and [scripts/gen-collision-map.sh](file:///home/pera/github_repo/.dotfiles/scripts/gen-collision-map.sh#L321-L389).  

#### Generation Command
```bash
./scripts/gen-collision-map.sh --restow-table
```

#### Expected Table Content Pattern
```markdown
<!-- BEGIN generated: gen-collision-map.sh --restow-table -->
| Package | Tag | Recovery Command |
|---|---|---|
| `chrome-flags` | `cp-through` | `git checkout -- restow/chrome-flags/.config/chrome-flags.conf && cd restow && stow --verbose=5 --no-folding -t ~ chrome-flags` |
| `dolphinrc` | `cp-through` | `git checkout -- restow/dolphinrc/.config/dolphinrc && cd restow && stow --verbose=5 --no-folding -t ~ dolphinrc` |
| `fuzzel` | `rsync-replace` | `cd restow && stow --verbose=5 --no-folding -t ~ fuzzel` |
| `hypr` | `rsync-replace` | `cd restow && stow --verbose=5 --no-folding -t ~ hypr` |
| `kitty` | `rsync-replace` | `cd restow && stow --verbose=5 --no-folding -t ~ kitty` |
| `starship` | `cp-through` | `git checkout -- restow/starship/.config/starship.toml && cd restow && stow --verbose=5 --no-folding -t ~ starship` |
<!-- END generated: gen-collision-map.sh --restow-table -->
```

---

### 3.5. `arch/kitty.sh` (Standalone Installer)

**Role:** Standalone script that installs the Kitty terminal package via pacman and stows its configuration.  
**Data Flow:** Invokes GNU Stow against `restow/kitty`.  
**Analog:** [arch/kitty.sh](file:///home/pera/github_repo/.dotfiles/arch/kitty.sh#L1-L11).  

#### Critical Invariants
- Preserves the `PAIR_COUNT == 18` invariant across all `arch/*.sh` files.
- Modifies line 10 from `../stow` to `../restow` without altering `--verbose=5 --no-folding`.

#### Concrete Code Pattern
**Target:** [arch/kitty.sh](file:///home/pera/github_repo/.dotfiles/arch/kitty.sh#L1-L11)
```bash
#!/usr/bin/env bash
set -euo pipefail
set -x


echo "[INSTALL] kitty"
sudo pacman -Sy --noconfirm --needed kitty

echo "[CONFIG] kitty"
cd "$(dirname "${BASH_SOURCE[0]}")/../restow" && stow --verbose=5 --no-folding -t ~ kitty
```

---

### 3.6. `arch/dots-hyprland.sh` (Verification Engine & Guard Gate)

**Role:** Thin wrapper script providing `verify --strict`, `install`, and `install-files`.  
**Data Flow:** Traverses managed directories and validates symlink targets against `guard-paths.tsv` and repository trees.  
**Analogs:** [arch/dots-hyprland.sh](file:///home/pera/github_repo/.dotfiles/arch/dots-hyprland.sh#L1135-L1167) and [arch/dots-hyprland.sh](file:///home/pera/github_repo/.dotfiles/arch/dots-hyprland.sh#L1340-L1353).  

#### Pattern 1: Recursive Directory Check in Guard Validation Gate
Under `run_verify()` (around lines 1158–1167):
```bash
      # Assert live path is not a symlink into repo (recursive check for directories)
      if [[ -L "$expanded" ]]; then
        live_target="$(readlink -f -- "$expanded" 2>/dev/null || true)"
        if [[ "$live_target" == "$main_root_real"/* || "$live_target" == "$main_root"/* ]]; then
          fail "guard path live counterpart symlinks into repo: $expanded -> $live_target"
        fi
      elif [[ -d "$expanded" ]]; then
        while IFS= read -r -d '' sub_link; do
          live_target="$(readlink -f -- "$sub_link" 2>/dev/null || true)"
          if [[ "$live_target" == "$main_root_real"/* || "$live_target" == "$main_root"/* ]]; then
            fail "guard path live counterpart symlinks into repo: $sub_link -> $live_target"
          fi
        done < <(find "$expanded" -type l -print0 2>/dev/null || true)
      fi
      pass "guard path excluded: $g_path"
```

#### Pattern 2: Hierarchical Prefix Walk in Live-Side Sweep
In `run_verify()` classifier function `classify_entry()` (around lines 1340–1345), replace exact dictionary lookup with hierarchical prefix checking:
```bash
      # Guarded theme output check (D-24) with hierarchical prefix matching (D-02)
      local check_entry="$entry"
      local is_guarded=0
      while [[ -n "$check_entry" && "$check_entry" != "$HOME" && "$check_entry" != "/" && "$check_entry" != "." ]]; do
        if [[ -n "${guarded_entries["$check_entry"]:-}" ]]; then
          is_guarded=1
          break
        fi
        check_entry="$(dirname -- "$check_entry")"
      done

      if [[ "$is_guarded" -eq 1 ]]; then
        info "guarded theme output: $entry"
        return 0
      fi
```

---

### 3.7. `bootstrap.sh` (Idempotent Orchestrator)

**Role:** 7-step idempotent orchestrator managing submodules, packages, upstream installer, de-stubbing, stow, capture seeding, and verification.  
**Data Flow:** Coordinates disk updates, backups to `$XDG_STATE_HOME/dotfiles/destub-backups/`, and theme generation.  
**Analogs:** [bootstrap.sh](file:///home/pera/github_repo/.dotfiles/bootstrap.sh#L322-L325), [bootstrap.sh](file:///home/pera/github_repo/.dotfiles/bootstrap.sh#L425-L473), [bootstrap.sh](file:///home/pera/github_repo/.dotfiles/bootstrap.sh#L483-L525).  

#### Pattern 1: Hierarchical Prefix Walk in `is_guarded_path`
**Target:** [bootstrap.sh](file:///home/pera/github_repo/.dotfiles/bootstrap.sh#L322-L325)
```bash
is_guarded_path() {
  local check_path="${1%/}"
  local cur="$check_path"
  while [[ -n "$cur" && "$cur" != "/" && "$cur" != "." ]]; do
    if [[ -n "${GUARDED_PATHS["$cur"]:-}" ]]; then
      return 0
    fi
    cur="$(dirname -- "$cur")"
  done
  return 1
}
```

#### Pattern 2: Explicit Legacy Catppuccin Pruning in Step 4 (`run_destub`)
**Target:** [bootstrap.sh](file:///home/pera/github_repo/.dotfiles/bootstrap.sh#L470-L473)
```bash
  # D-11: Explicit legacy Catppuccin symlink pruning in GTK config directories
  for gtk_ver in gtk-3.0 gtk-4.0; do
    local gtk_dir="$target/.config/$gtk_ver"
    [[ -d "$gtk_dir" ]] || continue
    for f in "$gtk_dir"/*; do
      [[ -L "$f" ]] || continue
      local link_target
      link_target="$(readlink "$f" 2>/dev/null || true)"
      if [[ "$link_target" == */Catppuccin* || "$link_target" == */catppuccin* || "$link_target" == /usr/share/themes/Catppuccin* ]]; then
        if [[ "$DRY_RUN" -eq 1 ]]; then
          echo "[DRY-RUN] Would remove legacy Catppuccin symlink: ${f#"$target"/}"
        else
          rm -f "$f"
          echo "[PRUNE] Removed legacy Catppuccin symlink: ${f#"$target"/}"
          destub_count=$((destub_count + 1))
        fi
      fi
    done
  done
```

#### Pattern 3: Sensitive Parent Directory Pre-Creation in Step 5 (`run_stow_step`)
**Target:** [bootstrap.sh](file:///home/pera/github_repo/.dotfiles/bootstrap.sh#L487-L496)
```bash
  # D-10, D-14: Pre-create sensitive parent directories before stowing
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[DRY-RUN] Would pre-create sensitive parent directories"
  else
    mkdir -p "$target/.config/fuzzel" \
             "$target/.config/gtk-3.0" \
             "$target/.config/gtk-4.0" \
             "$target/.config/hypr/custom" \
             "$target/.config/kitty" \
             "$target/.config/systemd/user"
  fi
```

#### Pattern 4: Initial Theme Generation with Fail-Soft Color Fallback in Step 6
**Target:** [bootstrap.sh](file:///home/pera/github_repo/.dotfiles/bootstrap.sh#L568-L572)
```bash
generate_initial_theme() {
  local target="${1:-$HOME}"
  local switchwall="$target/.config/quickshell/ii/scripts/colors/switchwall.sh"
  local config_file="$target/.config/illogical-impulse/config.json"
  local matugen_gtk4_tpl="$target/.config/matugen/templates/gtk-4.0/gtk.css"

  # Sanitize GTK 4 template pseudo-class if present (Pitfall 4)
  if [[ -f "$matugen_gtk4_tpl" ]] && grep -q ':insensitive' "$matugen_gtk4_tpl"; then
    if [[ "$DRY_RUN" -eq 1 ]]; then
      echo "[DRY-RUN] Would align GTK 4 template :insensitive -> :disabled"
    else
      sed -i 's/\.boxed-list row:insensitive/\.boxed-list row:disabled/g' "$matugen_gtk4_tpl"
      echo "[FIX] Aligned GTK 4 Matugen template pseudo-class (:disabled)"
    fi
  fi

  if [[ ! -f "$switchwall" ]]; then
    echo "[WARN] switchwall.sh not found at $switchwall; skipping initial theming"
    return 0
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[DRY-RUN] Would trigger initial Material You theme generation"
    return 0
  fi

  local wp_path=""
  if [[ -f "$config_file" ]]; then
    wp_path="$(jq -r '.background.wallpaperPath // empty' "$config_file" 2>/dev/null || true)"
  fi

  echo "[THEME] Triggering initial theme generation..."
  if [[ -n "$wp_path" && -f "$wp_path" ]]; then
    echo "[THEME] Generating theme from configured wallpaper: $wp_path"
    if ! "$switchwall" --noswitch; then
      echo "[WARN] switchwall.sh --noswitch failed; falling back to color seed #3f51b5"
      "$switchwall" --color "#3f51b5" || echo "[WARN] Fallback theme generation failed"
    fi
  else
    echo "[THEME] Configured wallpaper absent or inaccessible; falling back to color seed #3f51b5"
    if ! "$switchwall" --color "#3f51b5"; then
      echo "[WARN] Fallback color seed theme generation failed"
    fi
  fi
}

step_capture_seed() {
  echo "[STEP 6/7] Seeding capture baseline and generating initial theme..."
  deploy_capture_seeds "$HOME" "$REPO_ROOT"
  generate_initial_theme "$HOME"
}
```

---

### 3.8. `scripts/phase28-terminal-fuzzel-assert.sh` (Cross-Phase Assert Alignment)

**Role:** Phase 28 regression test harness asserting terminal and launcher dynamic theming.  
**Data Flow:** Inspects package directories and verifies include statements.  
**Analog:** [scripts/phase28-terminal-fuzzel-assert.sh](file:///home/pera/github_repo/.dotfiles/scripts/phase28-terminal-fuzzel-assert.sh#L107-L155).  

#### Required Updates
Update paths and pass/fail messages on lines 108, 122, and 150:
- Line 108: `REPO_KITTY_CONF="$REPO_ROOT/restow/kitty/.config/kitty/kitty.conf"`
- Lines 111, 113: `pass "S1: restow/kitty kitty.conf ..."` / `fail "S1: restow/kitty kitty.conf ..."`
- Line 122: `REPO_FUZZEL_INI="$REPO_ROOT/restow/fuzzel/.config/fuzzel/fuzzel.ini"`
- Lines 129, 131: `pass "S1: restow/fuzzel fuzzel.ini ..."` / `fail "S1: restow/fuzzel fuzzel.ini ..."`
- Line 150: `if [[ -f "$REPO_ROOT/restow/kitty/.config/kitty/search.py" && -f "$REPO_ROOT/restow/kitty/.config/kitty/scroll_mark.py" ]]; then`
- Lines 151, 153: `pass "S1: Helper kittens ... in restow/kitty package (D-03)"` / `fail "S1: Helper kittens missing from restow/kitty package (D-03)"`

---

## 4. Test Harness Architecture: `scripts/phase29-theme-data-contracts-assert.sh`

**Role:** Authoritative, fail-closed assertion harness for Phase 29 enforcing INTG-01, INTG-02, INTG-03, and full v0.5 regression status.  
**Analogs:**
- CLI Flags & Porcelain Snapshot: [scripts/phase28-terminal-fuzzel-assert.sh](file:///home/pera/github_repo/.dotfiles/scripts/phase28-terminal-fuzzel-assert.sh#L1-L79)
- Scratch Isolation & Destub Mocking: [scripts/phase23-bootstrap-assert.sh](file:///home/pera/github_repo/.dotfiles/scripts/phase23-bootstrap-assert.sh#L300-L375)
- Regression Sweep Execution: [scripts/phase28-terminal-fuzzel-assert.sh](file:///home/pera/github_repo/.dotfiles/scripts/phase28-terminal-fuzzel-assert.sh#L390-L445)

### 4.1. Header, Primitives, and CLI Arguments
```bash
#!/usr/bin/env bash
# Phase 29: Theme Data Contracts, Verification & Bootstrap Integration assert harness
# Enforces: INTG-01, INTG-02, INTG-03, and D-01 through D-16
#
# Usage (from REPO_ROOT):
#   ./scripts/phase29-theme-data-contracts-assert.sh [--section <1-5>]
# Exit 0 if all hard asserts pass; exit 1 if any hard FAIL.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

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

PORCELAIN_BEFORE="$(mktemp /tmp/p29-porcelain-before-XXXXXX)"
PORCELAIN_AFTER="$(mktemp /tmp/p29-porcelain-after-XXXXXX)"
TMP_FILES+=("$PORCELAIN_BEFORE" "$PORCELAIN_AFTER")

porcelain_snapshot > "$PORCELAIN_BEFORE"
```

---

### 4.2. Section 1: Data Contracts & Gitignore Parity (INTG-01, INTG-02, D-01, D-03, D-05..D-07)
```bash
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 1 ]]; then
  info "--- Section 1: Data Contracts & Gitignore Parity (INTG-01, INTG-02) ---"

  GUARD_TSV="$REPO_ROOT/guard-paths.tsv"
  GITIGNORE="$REPO_ROOT/.gitignore"
  COLLISION_MAP="$REPO_ROOT/collision-map.tsv"
  RESTOW_README="$REPO_ROOT/restow/README.md"

  # 1. guard-paths.tsv existence and 8 valid tab-separated rows
  if [[ -f "$GUARD_TSV" ]]; then
    pass "S1: guard-paths.tsv exists"
    EXPECTED_GUARDS=(
      '$XDG_CONFIG_HOME/kdeglobals'
      '$XDG_CONFIG_HOME/Kvantum'
      '$XDG_CONFIG_HOME/gtk-3.0/gtk.css'
      '$XDG_CONFIG_HOME/gtk-4.0/gtk.css'
      '$XDG_CONFIG_HOME/fuzzel/fuzzel_theme.ini'
      '$XDG_CONFIG_HOME/hypr/hyprland/colors.lua'
      '$XDG_CONFIG_HOME/hypr/hyprlock/colors.conf'
      '$XDG_CONFIG_HOME/kde-material-you-colors'
    )
    guard_count=0
    all_guards_ok=1
    while IFS=$'\t' read -r p cat gen reason || [[ -n "$p" ]]; do
      [[ -n "$p" && "$p" != \#* ]] || continue
      guard_count=$((guard_count + 1))
      if [[ -z "$cat" || -z "$gen" || -z "$reason" ]]; then
        fail "S1: guard-paths.tsv row invalid or missing columns: $p"
        all_guards_ok=0
      fi
    done < "$GUARD_TSV"

    if [[ "$guard_count" -eq 8 && "$all_guards_ok" -eq 1 ]]; then
      pass "S1: guard-paths.tsv contains exactly 8 valid tab-separated rows"
    else
      fail "S1: guard-paths.tsv row count is $guard_count (expected 8)"
    fi

    # Check Q7 and Q8 compatibility markers
    if grep -q "Q7:" "$GUARD_TSV" && grep -q "kde-material-you-colors" "$GUARD_TSV" && \
       grep -q "Q8:" "$GUARD_TSV" && grep -q "gtk-4.0/gtk.css" "$GUARD_TSV"; then
      pass "S1: guard-paths.tsv preserves Q7 and Q8 backward compatibility markers"
    else
      fail "S1: guard-paths.tsv header missing required Q7 or Q8 markers"
    fi
  else
    fail "S1: guard-paths.tsv missing"
  fi

  # 2. 1:1 Parity between guard-paths.tsv and .gitignore (D-01)
  if [[ -f "$GITIGNORE" ]]; then
    for g_entry in kdeglobals gtk.css Kvantum/ colors.lua colors.conf fuzzel_theme.ini kde-material-you-colors/; do
      if grep -q "^${g_entry}$" "$GITIGNORE"; then
        pass "S1: .gitignore contains $g_entry"
      else
        fail "S1: .gitignore missing required entry $g_entry"
      fi
    done
  else
    fail "S1: .gitignore missing"
  fi

  # 3. Three-tree placement: fuzzel and kitty in restow/ (D-05)
  if [[ -d "$REPO_ROOT/restow/fuzzel" && -d "$REPO_ROOT/restow/kitty" && \
        ! -e "$REPO_ROOT/stow/fuzzel" && ! -e "$REPO_ROOT/stow/kitty" ]]; then
    pass "S1: fuzzel and kitty reside in restow/ and are removed from stow/ (D-05)"
  else
    fail "S1: Package tree placement incorrect: fuzzel or kitty missing from restow/ or remaining in stow/"
  fi

  # 4. collision-map.tsv derivation for fuzzel and kitty
  if grep -qF '$XDG_CONFIG_HOME/fuzzel'$'\t''install_dir__sync'$'\t''DESTROYED'$'\t''untouched'$'\t''restow' "$COLLISION_MAP" && \
     grep -qF '$XDG_CONFIG_HOME/kitty'$'\t''install_dir__sync'$'\t''DESTROYED'$'\t''untouched'$'\t''restow' "$COLLISION_MAP"; then
    pass "S1: collision-map.tsv maps fuzzel and kitty to tree=restow (DESTROYED outcome)"
  else
    fail "S1: collision-map.tsv missing or incorrect for fuzzel/kitty"
  fi

  # 5. restow/README.md Section 3 generated table contains fuzzel and kitty with rsync-replace tag (D-06)
  if grep -q '| `fuzzel` | `rsync-replace` |' "$RESTOW_README" && \
     grep -q '| `kitty` | `rsync-replace` |' "$RESTOW_README"; then
    pass "S1: restow/README.md Section 3 table contains fuzzel and kitty with rsync-replace tag (D-06)"
  else
    fail "S1: restow/README.md table missing fuzzel or kitty rsync-replace entries"
  fi

  # 6. arch/kitty.sh stows from ../restow (D-07)
  KITTY_SH="$REPO_ROOT/arch/kitty.sh"
  if [[ -f "$KITTY_SH" ]] && grep -q '\.\./restow.*stow.*kitty' "$KITTY_SH"; then
    pass "S1: arch/kitty.sh stows from ../restow (D-07)"
  else
    fail "S1: arch/kitty.sh does not stow kitty from ../restow"
  fi

  # 7. Invariant: PAIR_COUNT in arch/*.sh MUST remain strictly 18
  PAIR_COUNT="$(grep -ho -- '--verbose=5 --no-folding' arch/*.sh | wc -l || true)"
  if [[ "$PAIR_COUNT" -eq 18 ]]; then
    pass "S1: PAIR_COUNT invariant in arch/*.sh is strictly 18"
  else
    fail "S1: PAIR_COUNT in arch/*.sh drifted (expected 18, counted $PAIR_COUNT)"
  fi
fi
```

---

### 4.3. Section 2: Live Zero Git Churn Drill (INTG-01, D-14, D-15)
```bash
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 ]]; then
  info "--- Section 2: Live Zero Git Churn Drill (INTG-01, D-14, D-15) ---"

  SWITCHWALL="$XDG_CONFIG_HOME/quickshell/ii/scripts/colors/switchwall.sh"
  if [[ ! -x "$SWITCHWALL" ]]; then
    fail "S2: switchwall.sh not executable at $SWITCHWALL"
  else
    # 5 Dynamic Themed Components
    F_FUZZEL="$XDG_CONFIG_HOME/fuzzel/fuzzel_theme.ini"
    F_KITTY="$XDG_STATE_HOME/quickshell/user/generated/terminal/kitty-theme.conf"
    F_GTK="$XDG_CONFIG_HOME/gtk-3.0/gtk.css"
    F_HYPR="$XDG_CONFIG_HOME/hypr/hyprland/colors.lua"
    F_KDE="$XDG_CONFIG_HOME/kdeglobals"

    B_FUZZEL="$(stat -c %Y "$F_FUZZEL" 2>/dev/null || echo 0)"
    B_KITTY="$(stat -c %Y "$F_KITTY" 2>/dev/null || echo 0)"
    B_GTK="$(stat -c %Y "$F_GTK" 2>/dev/null || echo 0)"
    B_HYPR="$(stat -c %Y "$F_HYPR" 2>/dev/null || echo 0)"
    B_KDE="$(stat -c %Y "$F_KDE" 2>/dev/null || echo 0)"

    DRILL_BEFORE="$(mktemp /tmp/p29-drill-before-XXXXXX)"
    DRILL_AFTER="$(mktemp /tmp/p29-drill-after-XXXXXX)"
    TMP_FILES+=("$DRILL_BEFORE" "$DRILL_AFTER")
    porcelain_snapshot > "$DRILL_BEFORE"

    sleep 1

    SW_RC=0
    "$SWITCHWALL" --noswitch >/dev/null 2>&1 || SW_RC=$?
    if [[ "$SW_RC" -eq 0 ]]; then
      pass "S2: switchwall.sh --noswitch completed successfully"
    else
      fail "S2: switchwall.sh --noswitch failed with rc=$SW_RC"
    fi

    A_FUZZEL="$(stat -c %Y "$F_FUZZEL" 2>/dev/null || echo 0)"
    A_KITTY="$(stat -c %Y "$F_KITTY" 2>/dev/null || echo 0)"
    A_GTK="$(stat -c %Y "$F_GTK" 2>/dev/null || echo 0)"
    A_HYPR="$(stat -c %Y "$F_HYPR" 2>/dev/null || echo 0)"
    A_KDE="$(stat -c %Y "$F_KDE" 2>/dev/null || echo 0)"

    [[ "$A_FUZZEL" -gt "$B_FUZZEL" ]] && pass "S2: Fuzzel mtime advanced monotonically" || fail "S2: Fuzzel mtime did not advance"
    [[ "$A_KITTY" -gt "$B_KITTY" ]] && pass "S2: Kitty theme mtime advanced monotonically" || fail "S2: Kitty theme mtime did not advance"
    [[ "$A_GTK" -gt "$B_GTK" ]] && pass "S2: GTK CSS mtime advanced monotonically" || fail "S2: GTK CSS mtime did not advance"
    [[ "$A_HYPR" -gt "$B_HYPR" ]] && pass "S2: Hyprland colors.lua mtime advanced monotonically" || fail "S2: Hyprland colors.lua mtime did not advance"
    [[ "$A_KDE" -gt "$B_KDE" ]] && pass "S2: KDE kdeglobals mtime advanced monotonically" || fail "S2: KDE kdeglobals mtime did not advance"

    porcelain_snapshot > "$DRILL_AFTER"
    if cmp -s "$DRILL_BEFORE" "$DRILL_AFTER"; then
      pass "S2: Zero git churn: porcelain snapshot byte-identical before and after switchwall drill"
    else
      fail "S2: switchwall drill caused working-tree churn"
      diff -u "$DRILL_BEFORE" "$DRILL_AFTER" || true
    fi
  fi
fi
```

---

### 4.4. Section 3: Strict Repository Verification Engine (INTG-02, D-04, D-08)
```bash
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 3 ]]; then
  info "--- Section 3: Strict Repository Verification Engine (INTG-02, D-04, D-08) ---"

  # 1. Clean packaging trees
  DIRTY_TREES="$(git status --porcelain stow/ restow/ capture/ || true)"
  if [[ -z "$DIRTY_TREES" ]]; then
    pass "S3: Packaging trees (stow/, restow/, capture/) are 100% clean"
  else
    fail "S3: Packaging trees dirty: $DIRTY_TREES"
  fi

  # 2. Strict verification engine execution
  VERIFY_RC=0
  VERIFY_OUT="$("$REPO_ROOT/arch/dots-hyprland.sh" verify --strict 2>&1)" || VERIFY_RC=$?
  if [[ "$VERIFY_RC" -eq 0 ]]; then
    pass "S3: arch/dots-hyprland.sh verify --strict passed with exit 0 (INTG-02)"
  else
    fail "S3: arch/dots-hyprland.sh verify --strict failed with rc=$VERIFY_RC"
    printf '%s\n' "$VERIFY_OUT" | sed 's/^/       /' >&2
  fi

  # 3. Live symlink target verification: fuzzel.ini and kitty.conf resolve to restow/
  LIVE_FUZZEL_CONF="$HOME/.config/fuzzel/fuzzel.ini"
  LIVE_KITTY_CONF="$HOME/.config/kitty/kitty.conf"

  TARGET_FUZZEL="$(readlink -f "$LIVE_FUZZEL_CONF" 2>/dev/null || true)"
  TARGET_KITTY="$(readlink -f "$LIVE_KITTY_CONF" 2>/dev/null || true)"

  if [[ "$TARGET_FUZZEL" == "$REPO_ROOT/restow/fuzzel/.config/fuzzel/fuzzel.ini" ]]; then
    pass "S3: live fuzzel.ini resolves to restow/fuzzel package (D-08)"
  else
    fail "S3: live fuzzel.ini target mismatch: $TARGET_FUZZEL"
  fi

  if [[ "$TARGET_KITTY" == "$REPO_ROOT/restow/kitty/.config/kitty/kitty.conf" ]]; then
    pass "S3: live kitty.conf resolves to restow/kitty package (D-08)"
  else
    fail "S3: live kitty.conf target mismatch: $TARGET_KITTY"
  fi
fi
```

---

### 4.5. Section 4: Bootstrap Integration & Destub Scratch Drill (INTG-03, D-02, D-10, D-11, D-12, D-13, D-16)
```bash
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 4 ]]; then
  info "--- Section 4: Bootstrap Integration & Destub Scratch Drill (INTG-03) ---"

  S4_ROOT="$(mktemp -d /tmp/p29-assert-s4-XXXXXX)"
  SCRATCH_ROOTS+=("$S4_ROOT")
  MOCK_HOME="$S4_ROOT/home"
  MOCK_REPO="$S4_ROOT/repo"
  mkdir -p "$MOCK_HOME" "$MOCK_REPO"

  # Source bootstrap functions in isolation
  # shellcheck source=/dev/null
  source "$REPO_ROOT/bootstrap.sh"

  # 1. Test hierarchical prefix matching in is_guarded_path (D-02)
  GUARDED_PATHS=()
  GUARDED_PATHS["$MOCK_HOME/.config/gtk-3.0/gtk.css"]=1
  GUARDED_PATHS["$MOCK_HOME/.config/Kvantum"]=1
  GUARDED_PATHS["$MOCK_HOME/.config/kde-material-you-colors"]=1

  if is_guarded_path "$MOCK_HOME/.config/gtk-3.0/gtk.css" && \
     is_guarded_path "$MOCK_HOME/.config/Kvantum/theme.kvconfig" && \
     is_guarded_path "$MOCK_HOME/.config/kde-material-you-colors/config.conf" && \
     ! is_guarded_path "$MOCK_HOME/.config/unrelated.conf"; then
    pass "S4: is_guarded_path enforces hierarchical prefix walk correctly (D-02)"
  else
    fail "S4: is_guarded_path hierarchical prefix walk failed"
  fi

  # 2. Test Step 4 destub with Catppuccin pruning and guard protection (D-11, D-16)
  mkdir -p "$MOCK_HOME/.config/gtk-4.0" "$MOCK_HOME/.config/gtk-3.0"
  ln -s "/usr/share/themes/Catppuccin-Mocha-Standard-Mauve-Dark/gtk-4.0/gtk.css" "$MOCK_HOME/.config/gtk-4.0/gtk.css"
  echo "/* guard */" > "$MOCK_HOME/.config/gtk-3.0/gtk.css"

  DRY_RUN=0
  destub_count=0
  # Simulate Catppuccin pruning pass
  for gtk_ver in gtk-3.0 gtk-4.0; do
    gtk_dir="$MOCK_HOME/.config/$gtk_ver"
    for f in "$gtk_dir"/*; do
      [[ -L "$f" ]] || continue
      link_target="$(readlink "$f" 2>/dev/null || true)"
      if [[ "$link_target" == */Catppuccin* ]]; then
        rm -f "$f"
        destub_count=$((destub_count + 1))
      fi
    done
  done

  if [[ ! -e "$MOCK_HOME/.config/gtk-4.0/gtk.css" && -f "$MOCK_HOME/.config/gtk-3.0/gtk.css" && "$destub_count" -eq 1 ]]; then
    pass "S4: destub safely prunes root-owned Catppuccin symlink while preserving guarded gtk.css (D-11, D-16)"
  else
    fail "S4: destub failed to prune Catppuccin symlink or corrupted guarded file"
  fi

  # 3. Test Step 5 sensitive parent directory pre-creation (D-10)
  run_stow_step "$MOCK_HOME" "$MOCK_REPO" >/dev/null 2>&1 || true
  if [[ -d "$MOCK_HOME/.config/fuzzel" && -d "$MOCK_HOME/.config/kitty" && \
        -d "$MOCK_HOME/.config/gtk-3.0" && -d "$MOCK_HOME/.config/gtk-4.0" && \
        -d "$MOCK_HOME/.config/hypr/custom" && -d "$MOCK_HOME/.config/systemd/user" ]]; then
    pass "S4: run_stow_step pre-creates .config/fuzzel, .config/kitty, and sensitive directories (D-10)"
  else
    fail "S4: run_stow_step failed to pre-create required parent directories"
  fi
fi
```

---

### 4.6. Section 5: Full v0.5 Regression Sweep (INTG-01, INTG-02, INTG-03, D-14)
```bash
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 5 ]]; then
  info "--- Section 5: Full v0.5 Regression Sweep (Phases 25, 26, 27, 28) ---"

  for p_script in "scripts/phase25-gtk-material-you-assert.sh" \
                  "scripts/phase26-qt-kde-material-you-assert.sh" \
                  "scripts/phase27-accent-coordination-assert.sh" \
                  "scripts/phase28-terminal-fuzzel-assert.sh"; do
    if [[ -x "$REPO_ROOT/$p_script" ]]; then
      p_rc=0
      p_out="$("$REPO_ROOT/$p_script" 2>&1)" || p_rc=$?
      if [[ "$p_rc" -eq 0 ]]; then
        pass "S5: $p_script passed with 0 failures"
      else
        fail "S5: $p_script failed with exit code $p_rc"
        printf '%s\n' "$p_out" | tail -n 20 | sed 's/^/       /' >&2
      fi
    else
      fail "S5: $p_script missing or not executable"
    fi
  done
fi

# ===========================================================================
# Closing porcelain invariant check & summary
# ===========================================================================
porcelain_snapshot > "$PORCELAIN_AFTER"
if cmp -s "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER"; then
  pass "Closing self-check: git status --porcelain unchanged across run (D-15)"
else
  fail "Closing self-check: git status --porcelain mutated across run (D-15)"
  diff -u "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER" || true
fi

echo "=== done: FAIL=${FAIL} FINDINGS=${FINDINGS} ==="
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
```

---

## 5. Dependency & Invariant Map

| Invariant | Value / Scope | Enforced By |
|---|---|---|
| **PAIR_COUNT** | Strictly 18 occurrences of `--verbose=5 --no-folding` across `arch/*.sh` | `arch/kitty.sh`, `scripts/phase23-bootstrap-assert.sh`, `scripts/phase29-theme-data-contracts-assert.sh` |
| **Three-Tree Taxonomy** | `fuzzel` and `kitty` belong strictly in `restow/` | `collision-map.tsv:70,79`, `restow/README.md`, `scripts/gen-collision-map.sh` |
| **Q7 / Q8 Comment Markers** | Literal tokens `"Q7:"` and `"Q8:"` in `guard-paths.tsv` | `guard-paths.tsv:7,9`, `scripts/phase22-kde-and-gtk-capture-assert.sh:484,490` |
| **Zero Git Churn** | Byte-identical porcelain snapshot before and after live theme reloads | `scripts/phase29-theme-data-contracts-assert.sh` Section 2 |
| **Strict Verification** | `FAIL=0 FINDINGS=0` under `arch/dots-hyprland.sh verify --strict` | `arch/dots-hyprland.sh:1001-1375`, `bootstrap.sh:638-647` |
| **Parent Dir Pre-creation** | `.config/fuzzel`, `.config/kitty`, `.config/gtk-3.0`, `.config/gtk-4.0`, `.config/hypr/custom`, `.config/systemd/user` exist before GNU Stow runs | `bootstrap.sh:491` |

---

## 6. Verification Checklist

- [ ] `guard-paths.tsv` contains exactly 8 valid tab-separated entries.
- [ ] `guard-paths.tsv` header documents v0.5 architecture while preserving `"Q7:"` and `"Q8:"` markers.
- [ ] `.gitignore` contains `kde-material-you-colors/` with 1:1 parity to `guard-paths.tsv`.
- [ ] Packages `stow/fuzzel` and `stow/kitty` moved to `restow/fuzzel` and `restow/kitty`.
- [ ] Live symlinks in `~/.config/fuzzel` and `~/.config/kitty` point cleanly to `restow/`.
- [ ] `restow/README.md` Section 3 table regenerated via `./scripts/gen-collision-map.sh --restow-table`.
- [ ] `arch/kitty.sh` line 10 points to `../restow`, and `PAIR_COUNT == 18` across `arch/*.sh`.
- [ ] `arch/dots-hyprland.sh` implements recursive directory guard checking and hierarchical prefix matching in live sweep.
- [ ] `bootstrap.sh` implements hierarchical prefix matching in `is_guarded_path()`.
- [ ] `bootstrap.sh` Step 4 prunes legacy Catppuccin symlinks in `~/.config/gtk-3.0/` and `~/.config/gtk-4.0/`.
- [ ] `bootstrap.sh` Step 5 pre-creates `.config/fuzzel` and `.config/kitty` directories.
- [ ] `bootstrap.sh` Step 6 triggers initial theme generation with fail-soft fallback seed `#3f51b5`.
- [ ] `scripts/phase28-terminal-fuzzel-assert.sh` lines 108, 122, and 150 updated to `restow/`.
- [ ] `scripts/phase29-theme-data-contracts-assert.sh` authored with all 5 sections.
- [ ] `scripts/phase29-theme-data-contracts-assert.sh` passes with `FAIL=0 FINDINGS=0`.
