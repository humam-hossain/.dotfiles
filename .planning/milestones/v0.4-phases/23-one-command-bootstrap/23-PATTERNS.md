# Phase 23: One-command bootstrap - Pattern Map

**Mapped:** 2026-09-15  
**Phase Directory:** `.planning/phases/23-one-command-bootstrap/`  
**Output File:** `23-PATTERNS.md`  
**Files Analyzed:** 5 artifacts (2 new scripts, 1 modified wrapper, 2 new data snapshots)  
**Analogs Found:** 5 / 5 (all backed by tracked repository sources)  

All analog paths below were verified with `git ls-files` and represent git-tracked source code in this repository. Submodule paths under `vendor/dots-hyprland/` are cited strictly as external reference specifications, never as patterns to copy.

---

## File Classification

| Target File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `./bootstrap.sh` (**new**) | Root orchestrator / state machine controller | Pipeline execution / process dispatch / file-I/O | `arch/dots-hyprland.sh` (CLI parser, banner, strict verification gate) + `arch/aur.sh` (prerequisite verification) | exact composite |
| `scripts/phase23-bootstrap-assert.sh` (**new**) | Test suite / phase assert harness | Batch read-only & isolated scratch probe | `scripts/phase22-kde-and-gtk-capture-assert.sh` (sections, scratch fixtures) + `scripts/phase19-link-aware-verify-assert.sh` (porcelain bracket, exit code gates) | exact composite |
| `arch/dots-hyprland.sh` (**modify**) | Upstream setup wrapper / subcommand router | Request-response delegation (`exec`) | `arch/dots-hyprland.sh:17, 29-54, 1726-1740` (existing allowlist and case dispatch) | exact self-analog |
| `arch/pkglist-native.txt` (**new**) | Package snapshot data file | Static data / audit baseline | `guard-paths.tsv:1-13` (metadata header comments) + `pacman -Qqen` (deterministic sort) | role-match |
| `arch/pkglist-aur.txt` (**new**) | Package snapshot data file | Static data / audit baseline | `guard-paths.tsv:1-13` (metadata header comments) + `pacman -Qqem` (deterministic sort) | role-match |

---

## Pattern Assignments by File

### 1. `./bootstrap.sh` (Root Orchestrator & State Machine)

**Role:** Primary operator entry point; runs pipeline steps, persists JSON state, manages de-stubbing, backups, stow linking, capture seeding, operator relogin pause, and strict verification.  
**Analog:** `arch/dots-hyprland.sh` for flag parsing, error reporting, array commands, guard checks, and verification delegation; `arch/aur.sh` for prerequisite detection.

#### Pattern 1.1: Script Header, Non-Root Guard, and Arch Platform Check
Source: `arch/dots-hyprland.sh:1-12`, `23-CONTEXT.md:D-06`
```bash
#!/usr/bin/env bash
set -euo pipefail

# Physical repository root (pwd -P resolves all symlinks)
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
cd "$REPO_ROOT"

# D-06: Non-root execution gate — sudo requested on-demand by sub-tools
if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
  echo "[FAIL] ./bootstrap.sh must NOT be run as root. Run as regular operator." >&2
  exit 1
fi

# Platform assertion: Arch Linux is the sole supported target
if [[ ! -f /etc/arch-release ]]; then
  echo "[FAIL] /etc/arch-release not found. Arch Linux is required for bootstrap." >&2
  exit 1
fi
```

#### Pattern 1.2: Dual-Stream Console + Transcript Logging with Protected Descriptors
Source: `23-CONTEXT.md:D-07`, `23-RESEARCH.md:Pitfall 3`
Avoids race conditions where a detached subshell `tee` is killed on script exit before flushing stdout.
```bash
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
LOG_DIR="$XDG_STATE_HOME/dotfiles/logs"
mkdir -p "$LOG_DIR"

LOG_FILE="$LOG_DIR/bootstrap-$(date +"%Y%m%d_%H%M%S").log"

# Retain the 5 most recent log files
cleanup_old_logs() {
  local count
  count="$(find "$LOG_DIR" -maxdepth 1 -name 'bootstrap-*.log' | wc -l)"
  if ((count > 5)); then
    find "$LOG_DIR" -maxdepth 1 -name 'bootstrap-*.log' -printf '%T@ %p\n' \
      | sort -n | head -n -5 | awk '{print $2}' | xargs -r rm -f
  fi
}
cleanup_old_logs

# Duplicate standard descriptors to preserve clean exit flushing
exec 3>&1 4>&2
exec > >(tee -a "$LOG_FILE") 2>&1

cleanup_logging() {
  exec 1>&3 2>&4 3>&- 4>&-
  wait 2>/dev/null || true
}
trap cleanup_logging EXIT
```

#### Pattern 1.3: Closed CLI Flag Surface & Unknown Option Rejection
Source: `arch/dots-hyprland.sh:752-781` (`run_verify` parser)
Fails closed with exit code 2 on unrecognized flags, matching `arch/dots-hyprland.sh` convention.
```bash
usage() {
  cat <<'EOF'
./bootstrap.sh — Reproduce dotfiles desktop environment from a clean clone

Usage:
  ./bootstrap.sh [flags…]

Flags:
  --dry-run       Structured preview of pipeline steps and commands without mutating disk
  --from <step>   Resume execution starting at specified step, skipping prior completed steps
  --only <step>   Execute solely the specified step and exit
  --reset         Wipe persistent state file to force a fresh re-run from step 1
  --snapshot      Regenerate package snapshots (arch/pkglist-*.txt) and exit
  --no-pause      Skip interactive relogin pause (for automated headless validation)
  -h, --help      Display this help message and exit

Pipeline Steps:
  1. submodules   Update git submodules recursively
  2. packages     Verify and install base prerequisites (git, stow, jq, yay)
  3. installer    Execute upstream dots-hyprland installer via wrapper
  4. destub       Discover conflicts, archive stubs to ~/.dotfiles-backup.<epoch>/, unlink
  5. stow         Pre-create parent dirs and stow packages in stow/ then restow/
  6. capture_seed Atomically deploy baseline configs from capture/ to $HOME
  [Relogin Boundary: prompt operator to exit session and log back in]
  7. verify       Activate systemd user timer and run arch/dots-hyprland.sh verify --strict
EOF
}

DRY_RUN=0
FROM_STEP=""
ONLY_STEP=""
RESET_STATE=0
SNAPSHOT_MODE=0
NO_PAUSE=0
declare -a UNKNOWN_FLAGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --from)
      if [[ -z "${2:-}" ]]; then
        echo "[FAIL] --from requires a step argument." >&2
        exit 2
      fi
      FROM_STEP="$2"
      shift 2
      ;;
    --only)
      if [[ -z "${2:-}" ]]; then
        echo "[FAIL] --only requires a step argument." >&2
        exit 2
      fi
      ONLY_STEP="$2"
      shift 2
      ;;
    --reset)
      RESET_STATE=1
      shift
      ;;
    --snapshot)
      SNAPSHOT_MODE=1
      shift
      ;;
    --no-pause)
      NO_PAUSE=1
      shift
      ;;
    *)
      UNKNOWN_FLAGS+=("$1")
      shift
      ;;
  esac
done

if ((${#UNKNOWN_FLAGS[@]} > 0)); then
  echo "[FAIL] Unknown bootstrap flag(s): ${UNKNOWN_FLAGS[*]}" >&2
  echo "[FAIL] Run ./bootstrap.sh --help for accepted flags." >&2
  exit 2
fi
```

#### Pattern 1.4: Resumable JSON State Engine via `jq`
Source: `23-RESEARCH.md:304-346`, `23-CONTEXT.md:D-02, D-05`
State is maintained atomically via temporary files on the same filesystem.
```bash
STATE_FILE="$XDG_STATE_HOME/dotfiles/bootstrap-state"

init_state() {
  if [[ "$RESET_STATE" -eq 1 && -f "$STATE_FILE" ]]; then
    rm -f "$STATE_FILE"
  fi
  if [[ ! -f "$STATE_FILE" ]]; then
    mkdir -p "$(dirname "$STATE_FILE")"
    local now
    now="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    jq -n --arg ts "$now" '{
      schema_version: 1,
      started_at: $ts,
      updated_at: $ts,
      stage: 1,
      current_step: "submodules",
      steps: {
        submodules: { status: "pending", timestamp: null },
        packages: { status: "pending", timestamp: null },
        installer: { status: "pending", timestamp: null },
        destub: { status: "pending", timestamp: null },
        stow: { status: "pending", timestamp: null },
        capture_seed: { status: "pending", timestamp: null },
        verify: { status: "pending", timestamp: null }
      },
      last_error: null
    }' > "$STATE_FILE.tmp.$$" && mv "$STATE_FILE.tmp.$$" "$STATE_FILE"
  fi
}

set_step_status() {
  local step="$1" status="$2" err="${3:-}"
  local now
  now="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  local tmp="$STATE_FILE.tmp.$$"
  jq --arg step "$step" --arg status "$status" --arg ts "$now" --arg err "$err" '
    .updated_at = $ts |
    .current_step = $step |
    .steps[$step].status = $status |
    .steps[$step].timestamp = $ts |
    if $err != "" then .last_error = $err else . end
  ' "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
}

get_step_status() {
  local step="$1"
  if [[ -f "$STATE_FILE" ]]; then
    jq -r --arg step "$step" '.steps[$step].status // "pending"' "$STATE_FILE"
  else
    echo "pending"
  fi
}

get_stage() {
  if [[ -f "$STATE_FILE" ]]; then
    jq -r '.stage // 1' "$STATE_FILE"
  else
    echo 1
  fi
}

set_stage() {
  local stage="$1"
  local now
  now="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  local tmp="$STATE_FILE.tmp.$$"
  jq --argjson stage "$stage" --arg ts "$now" '
    .updated_at = $ts | .stage = $stage
  ' "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
}
```

#### Pattern 1.5: Guard Paths Loading & Exemption Check
Source: `arch/dots-hyprland.sh:1134-1165` (`guard-paths.tsv` parser)
```bash
declare -A GUARDED_PATHS=()

load_guard_paths() {
  local guard_file="$REPO_ROOT/guard-paths.tsv"
  [[ -f "$guard_file" ]] || return 0
  local g_path g_cat g_gen g_reason expanded
  while IFS=$'\t' read -r g_path g_cat g_gen g_reason || [[ -n "$g_path" ]]; do
    [[ -n "$g_path" && "$g_path" != \#* ]] || continue
    expanded="${g_path//\$XDG_CONFIG_HOME/$HOME\/.config}"
    expanded="${expanded//\$HOME/$HOME}"
    GUARDED_PATHS["$expanded"]=1
  done < "$guard_file"
}

is_guarded_path() {
  local check_path="$1"
  [[ -n "${GUARDED_PATHS["$check_path"]:-}" ]]
}
```

#### Pattern 1.6: Conflict Discovery, Safe Hierarchical Backup, and De-stubbing
Source: `23-CONTEXT.md:D-15, D-16, D-17, D-18`, `23-RESEARCH.md:351-394`
Strict adherence to the `--adopt` ban. Parses all 5 GNU Stow conflict forms.
```bash
run_destub() {
  local epoch
  epoch="$(date +%s)"
  local backup_dir="$HOME/.dotfiles-backup.$epoch"
  local manifest="$backup_dir/MANIFEST.txt"
  local destub_count=0

  load_guard_paths

  local trees=("$REPO_ROOT/stow" "$REPO_ROOT/restow")
  for tree_dir in "${trees[@]}"; do
    [[ -d "$tree_dir" ]] || continue
    for pkg_dir in "$tree_dir"/*; do
      [[ -d "$pkg_dir" ]] || continue
      local pkg
      pkg="$(basename "$pkg_dir")"
      [[ "$pkg" != "README.md" && "$pkg" != .* ]] || continue

      # Dry-run conflict simulation
      local stow_out
      stow_out="$(stow -n --no-folding -d "$tree_dir" -t "$HOME" "$pkg" 2>&1 || true)"

      local conflict_targets=()
      while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*\*[[:space:]]+cannot[[:space:]]+stow[[:space:]]+.*[[:space:]]+over[[:space:]]+existing[[:space:]]+target[[:space:]]+(.*)[[:space:]]+since[[:space:]]+neither ]]; then
          conflict_targets+=("${BASH_REMATCH[1]}")
        elif [[ "$line" =~ ^[[:space:]]*\*[[:space:]]+existing[[:space:]]+target[[:space:]]+is[[:space:]]+not[[:space:]]+owned[[:space:]]+by[[:space:]]+stow:[[:space:]]+(.*) ]]; then
          conflict_targets+=("${BASH_REMATCH[1]}")
        fi
      done <<< "$stow_out"

      for rel_path in "${conflict_targets[@]+"${conflict_targets[@]}"}"; do
        local live_path="$HOME/$rel_path"

        # D-17: Skip guard paths immediately
        if is_guarded_path "$live_path"; then
          echo "[GUARD] Preserving guarded theme path: $rel_path"
          continue
        fi

        if [[ -f "$live_path" && ! -L "$live_path" ]]; then
          # Conflicting regular file: back up with manifest then unlink
          if [[ "$DRY_RUN" -eq 1 ]]; then
            echo "[DRY-RUN] Would backup and remove stub: $rel_path"
          else
            mkdir -p "$backup_dir/$(dirname "$rel_path")"
            local sha now
            sha="$(sha256sum "$live_path" | awk '{print $1}')"
            now="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
            printf '%s  %s  %s\n' "$now" "$sha" "$rel_path" >> "$manifest"
            cp -p "$live_path" "$backup_dir/$rel_path"
            rm -f "$live_path"
            echo "[DESTUB] Archived and removed stub: $rel_path"
            destub_count=$((destub_count + 1))
          fi
        elif [[ -L "$live_path" ]]; then
          # Foreign or dangling symlink
          if [[ "$DRY_RUN" -eq 1 ]]; then
            echo "[DRY-RUN] Would remove stale symlink: $rel_path"
          else
            rm -f "$live_path"
            echo "[PRUNE] Removed stale/foreign symlink: $rel_path"
          fi
        fi
      done
    done
  done
}
```

#### Pattern 1.7: Stow Linking with Parent Directory Protection
Source: `23-CONTEXT.md:D-12, D-13, D-14`, `23-RESEARCH.md:399-426`
Guarantees GNU Stow never folds directories into directory-level symlinks.
```bash
run_stow_step() {
  local target="${1:-$HOME}"

  # D-14: Pre-create sensitive parent directories before stowing
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[DRY-RUN] Would pre-create sensitive parent directories"
  else
    mkdir -p "$target/.config/gtk-3.0" \
             "$target/.config/gtk-4.0" \
             "$target/.config/hypr/custom" \
             "$target/.config/systemd/user"
  fi

  # Link stow/ packages first
  for pkg_dir in "$REPO_ROOT/stow"/*; do
    [[ -d "$pkg_dir" ]] || continue
    local pkg
    pkg="$(basename "$pkg_dir")"
    [[ "$pkg" != "README.md" && "$pkg" != .* ]] || continue
    if [[ "$DRY_RUN" -eq 1 ]]; then
      echo "[DRY-RUN] stow --verbose=5 --no-folding -d $REPO_ROOT/stow -t $target $pkg"
    else
      stow --verbose=5 --no-folding -d "$REPO_ROOT/stow" -t "$target" "$pkg"
    fi
  done

  # Link restow/ packages next
  for pkg_dir in "$REPO_ROOT/restow"/*; do
    [[ -d "$pkg_dir" ]] || continue
    local pkg
    pkg="$(basename "$pkg_dir")"
    [[ "$pkg" != "README.md" && "$pkg" != .* ]] || continue
    if [[ "$DRY_RUN" -eq 1 ]]; then
      echo "[DRY-RUN] stow --verbose=5 --no-folding -d $REPO_ROOT/restow -t $target $pkg"
    else
      stow --verbose=5 --no-folding -d "$REPO_ROOT/restow" -t "$target" "$pkg"
    fi
  done
}
```

#### Pattern 1.8: Atomic Capture Seed Deployment with Syntax Validation
Source: `23-CONTEXT.md:D-19`
```bash
deploy_capture_seeds() {
  local target="${1:-$HOME}"
  local capture_root="$REPO_ROOT/capture"
  [[ -d "$capture_root" ]] || return 0

  while IFS= read -r -d '' src_file; do
    local rel_path="${src_file#"$capture_root"/}"
    # Strip the package-level directory component (e.g. illogical-impulse/.config/... -> .config/...)
    local dest_sub="${rel_path#*/}"
    local dest_file="$target/$dest_sub"

    # JSON validation before deployment
    if [[ "$src_file" == *.json ]]; then
      if ! jq empty "$src_file" 2>/dev/null; then
        echo "[FAIL] Invalid JSON syntax in capture seed: $rel_path" >&2
        return 1
      fi
    fi

    if [[ "$DRY_RUN" -eq 1 ]]; then
      echo "[DRY-RUN] Would deploy capture seed: $dest_sub"
    else
      mkdir -p "$(dirname "$dest_file")"
      local tmp_file="${dest_file}.tmp.$$"
      cp -p "$src_file" "$tmp_file"
      mv "$tmp_file" "$dest_file"
      echo "[SEED] Deployed baseline capture config: $dest_sub"
    fi
  done < <(find "$capture_root" -type f -print0)
}
```

#### Pattern 1.9: Operator Relogin Pause Banner
Source: `23-CONTEXT.md:D-08, D-09`, `23-RESEARCH.md:431-459`
```bash
show_relogin_banner() {
  local reset="\033[0m" bold="\033[1m" green="\033[32m" cyan="\033[36m"
  if [[ ! -t 1 ]]; then
    reset="" bold="" green="" cyan=""
  fi

  cat <<EOF

${bold}${cyan}┌────────────────────────────────────────────────────────────────────────┐${reset}
${bold}${cyan}│${reset}                        ${bold}${green}BOOTSTRAP: STAGE 1 COMPLETE${reset}                     ${bold}${cyan}│${reset}
${bold}${cyan}├────────────────────────────────────────────────────────────────────────┤${reset}
${bold}${cyan}│${reset} All dotfiles, overlays, and session configs have been placed on disk.  ${bold}${cyan}│${reset}
${bold}${cyan}│${reset}                                                                        ${bold}${cyan}│${reset}
${bold}${cyan}│${reset} The session entry point has changed to upstream ${bold}hyprland.lua${reset}.          ${bold}${cyan}│${reset}
${bold}${cyan}│${reset} A session relogin is mandatory to load the new desktop environment:    ${bold}${cyan}│${reset}
${bold}${cyan}│${reset}                                                                        ${bold}${cyan}│${reset}
${bold}${cyan}│${reset}   1. Exit current session:  ${bold}hyprctl dispatch exit${reset}                      ${bold}${cyan}│${reset}
${bold}${cyan}│${reset}   2. Log back in via display manager / SDDM                             ${bold}${cyan}│${reset}
${bold}${cyan}│${reset}   3. Complete bootstrap by running:                                     ${bold}${cyan}│${reset}
${bold}${cyan}│${reset}        ${bold}./bootstrap.sh${reset}                                                   ${bold}${cyan}│${reset}
${bold}${cyan}└────────────────────────────────────────────────────────────────────────┘${reset}

EOF
}
```

#### Pattern 1.10: Session Runtime Probe & Stage 2 Systemd Verification Gate
Source: `23-CONTEXT.md:D-10, D-11, D-23`, `arch/dots-hyprland.sh:run_verify`
```bash
probe_session_environment() {
  if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    echo "[WARN] HYPRLAND_INSTANCE_SIGNATURE is not set. Graphical session may not be active." >&2
  fi
  if command -v hyprctl &>/dev/null; then
    local provider
    provider="$(hyprctl -j status 2>/dev/null | jq -r '.configProvider // "unknown"')"
    if [[ "$provider" != "lua" ]]; then
      echo "[WARN] Active configProvider is '$provider' (expected 'lua')." >&2
    fi
  fi
}

run_stage2_verification() {
  probe_session_environment

  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[DRY-RUN] systemctl --user daemon-reload"
    echo "[DRY-RUN] systemctl --user --now enable dotfiles-capture.timer"
    echo "[DRY-RUN] $REPO_ROOT/arch/dots-hyprland.sh verify --strict"
    return 0
  fi

  echo "[STAGE 2] Activating systemd capture timer..."
  systemctl --user daemon-reload
  systemctl --user --now enable dotfiles-capture.timer
  if ! systemctl --user is-active --quiet dotfiles-capture.timer; then
    echo "[FAIL] dotfiles-capture.timer is not active." >&2
    return 1
  fi
  echo "[PASS] dotfiles-capture.timer active."

  echo "[STAGE 2] Running strict repository verification..."
  # BOOT-04: Exit code of bootstrap is strictly exit code of verify --strict
  local verify_rc=0
  "$REPO_ROOT/arch/dots-hyprland.sh" verify --strict || verify_rc=$?
  return "$verify_rc"
}
```

#### Pattern 1.11: Package Snapshot Generator (`--snapshot`)
Source: `23-CONTEXT.md:D-20, D-21`, `23-RESEARCH.md:465-500`
```bash
generate_package_snapshots() {
  local host
  host="$(uname -n 2>/dev/null || cat /etc/hostname 2>/dev/null || echo "${HOSTNAME:-arch}")"
  local ts
  ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  local kernel
  kernel="$(uname -r)"
  local pac_ver
  pac_ver="$(pacman -V 2>/dev/null | grep -o 'Pacman v[0-9.]* - libalpm v[0-9.]*' || echo "unknown")"

  local nat_file="$REPO_ROOT/arch/pkglist-native.txt"
  {
    printf '# arch/pkglist-native.txt — explicitly installed native packages\n'
    printf '# Hostname: %s\n' "$host"
    printf '# Timestamp: %s\n' "$ts"
    printf '# Kernel: %s\n' "$kernel"
    printf '# Pacman: %s\n' "$pac_ver"
    printf '# Count: %d\n' "$(pacman -Qqen | wc -l)"
    pacman -Qqen | LC_ALL=C sort -u
  } > "$nat_file.tmp.$$" && mv "$nat_file.tmp.$$" "$nat_file"

  local aur_file="$REPO_ROOT/arch/pkglist-aur.txt"
  {
    printf '# arch/pkglist-aur.txt — explicitly installed foreign/AUR packages\n'
    printf '# Hostname: %s\n' "$host"
    printf '# Timestamp: %s\n' "$ts"
    printf '# Kernel: %s\n' "$kernel"
    printf '# Pacman: %s\n' "$pac_ver"
    printf '# Count: %d\n' "$(pacman -Qqem | wc -l)"
    pacman -Qqem | LC_ALL=C sort -u
  } > "$aur_file.tmp.$$" && mv "$aur_file.tmp.$$" "$aur_file"

  echo "[SNAPSHOT] Successfully generated $nat_file and $aur_file"
}
```

---

### 2. `scripts/phase23-bootstrap-assert.sh` (Test Suite & Assert Harness)

**Role:** End-to-end automated verification script covering CLI parsing, isolated scratch environment de-stubbing, state machine resumability, package snapshot format, and live host verification.  
**Analog:** `scripts/phase22-kde-and-gtk-capture-assert.sh` and `scripts/phase19-link-aware-verify-assert.sh`.

#### Pattern 2.1: Assert Harness Preamble, Prefix Helpers, and Scratch Teardown
Source: `scripts/phase22-kde-and-gtk-capture-assert.sh:1-37`
```bash
#!/usr/bin/env bash
# Phase 23 One-command bootstrap assert harness (BOOT-01 to BOOT-05).
# One script, one section per requirement criterion, one verdict for the phase.
#
# Usage (from REPO_ROOT):
#   ./scripts/phase23-bootstrap-assert.sh [--section <1-5>]
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

#### Pattern 2.2: Git Working-Tree Porcelain Bracket
Source: `scripts/phase19-link-aware-verify-assert.sh:180-194, 1693-1701`
Guarantees that running the assert harness does not cause repository drift.
```bash
porcelain_snapshot_raw() {
  git status --porcelain --ignored || true
}

porcelain_snapshot() {
  porcelain_snapshot_raw \
    | grep -v -E '^!! (\.commandcode/|scripts/__pycache__/)$' || true
}

PORCELAIN_BEFORE="$(mktemp /tmp/p23-porcelain-before-XXXXXX)"
PORCELAIN_AFTER="$(mktemp /tmp/p23-porcelain-after-XXXXXX)"
TMP_FILES+=("$PORCELAIN_BEFORE" "$PORCELAIN_AFTER")

porcelain_snapshot > "$PORCELAIN_BEFORE"
```

#### Pattern 2.3: Section 1 — CLI Flag Parsing, Unknown Flag Refusal (Exit 2), and Delegation
Source: `23-RESEARCH.md:528-530`, `arch/dots-hyprland.sh:752-781`
```bash
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 1 ]]; then
  info "--- Section 1: CLI flags, unknown option rejection, root check, wrapper delegation ---"

  # 1. --help exits 0
  HELP_OUT="$("$REPO_ROOT/bootstrap.sh" --help 2>&1)" || true
  if grep -q "Usage:" <<<"$HELP_OUT"; then
    pass "Section 1: ./bootstrap.sh --help outputs usage"
  else
    fail "Section 1: ./bootstrap.sh --help failed to output usage"
  fi

  # 2. Unknown flag exits 2
  BOGUS_RC=0
  BOGUS_OUT="$("$REPO_ROOT/bootstrap.sh" --bogus-flag 2>&1)" || BOGUS_RC=$?
  if [[ "$BOGUS_RC" -eq 2 ]] && grep -q "Unknown bootstrap flag" <<<"$BOGUS_OUT"; then
    pass "Section 1: unknown flag correctly rejected with exit code 2"
  else
    fail "Section 1: unknown flag did not exit 2 (rc=$BOGUS_RC)"
  fi

  # 3. arch/dots-hyprland.sh bootstrap delegates to ./bootstrap.sh
  WRAP_RC=0
  WRAP_OUT="$("$REPO_ROOT/arch/dots-hyprland.sh" bootstrap --help 2>&1)" || WRAP_RC=$?
  if [[ "$WRAP_RC" -eq 0 ]] && grep -q "Usage:" <<<"$WRAP_OUT"; then
    pass "Section 1: arch/dots-hyprland.sh bootstrap successfully forwards to ./bootstrap.sh"
  else
    fail "Section 1: arch/dots-hyprland.sh bootstrap delegation failed (rc=$WRAP_RC)"
  fi
fi
```

#### Pattern 2.4: Section 2 — Isolated Scratch De-stubbing, Manifest Check, and Inode Identity
Source: `scripts/phase22-kde-and-gtk-capture-assert.sh:89-100, 509-534`
```bash
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 ]]; then
  info "--- Section 2: Isolated scratch de-stubbing, backup manifest, and stow linking ---"

  S2_ROOT="$(mktemp -d /tmp/p23-assert-s2-XXXXXX)"
  SCRATCH_ROOTS+=("$S2_ROOT")

  MOCK_REPO="$S2_ROOT/repo"
  MOCK_HOME="$S2_ROOT/home"
  mkdir -p "$MOCK_REPO/stow/testpkg/.config/testpkg" "$MOCK_REPO/arch" "$MOCK_HOME/.config/testpkg"

  # Populate mock repository and live stub
  echo "managed content" > "$MOCK_REPO/stow/testpkg/.config/testpkg/config.ini"
  echo "upstream stub content" > "$MOCK_HOME/.config/testpkg/config.ini"

  # Copy guard paths and scripts
  cp "$REPO_ROOT/guard-paths.tsv" "$MOCK_REPO/guard-paths.tsv"
  # Set up guarded live file that must NOT be pruned
  mkdir -p "$MOCK_HOME/.config"
  echo "guarded content" > "$MOCK_HOME/.config/kdeglobals"

  # Run destub and stow in scratch fixture
  # Assertions:
  # 1. $MOCK_HOME/.config/kdeglobals was NOT deleted or moved
  # 2. $MOCK_HOME/.config/testpkg/config.ini was moved to ~/.dotfiles-backup.<epoch>/
  # 3. MANIFEST.txt contains valid SHA-256 (assert via sha256sum -c)
  # 4. Inode identity check (-ef) confirms stow link:
  #    [[ "$MOCK_HOME/.config/testpkg/config.ini" -ef "$MOCK_REPO/stow/testpkg/.config/testpkg/config.ini" ]]
fi
```

#### Pattern 2.5: Section 3 — State Machine Resumability, Simulated Failure, and Idempotence
Source: `23-RESEARCH.md:531`
```bash
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 3 ]]; then
  info "--- Section 3: State machine resumability, --from, --only, --reset, idempotence ---"

  S3_ROOT="$(mktemp -d /tmp/p23-assert-s3-XXXXXX)"
  SCRATCH_ROOTS+=("$S3_ROOT")
  export XDG_STATE_HOME="$S3_ROOT/state"

  # 1. State initialization check
  # 2. Simulated failure records 'failed' status and last_error in JSON
  # 3. Running with --from resumes from target step
  # 4. Running with --only executes strictly single step
  # 5. Running with --reset wipes state file
  # 6. Re-run on complete state is 100% idempotent
fi
```

#### Pattern 2.6: Section 4 — Package Snapshot Data Format & Zero Drift Gate
Source: `23-RESEARCH.md:533`, `23-CONTEXT.md:D-20, D-21`
```bash
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 4 ]]; then
  info "--- Section 4: Package snapshot validation and zero git drift ---"

  # 1. Check arch/pkglist-native.txt and arch/pkglist-aur.txt format
  for f in "arch/pkglist-native.txt" "arch/pkglist-aur.txt"; do
    if [[ -f "$REPO_ROOT/$f" ]]; then
      # Validate required headers
      if grep -q "^# Hostname:" "$REPO_ROOT/$f" && \
         grep -q "^# Timestamp:" "$REPO_ROOT/$f" && \
         grep -q "^# Kernel:" "$REPO_ROOT/$f" && \
         grep -q "^# Pacman:" "$REPO_ROOT/$f" && \
         grep -q "^# Count:" "$REPO_ROOT/$f"; then
        pass "Section 4: $f carries all required metadata headers"
      else
        fail "Section 4: $f missing one or more metadata headers"
      fi

      # Validate deterministic sorting
      local non_comments
      non_comments="$(grep -v '^#' "$REPO_ROOT/$f")"
      if LC_ALL=C sort -C <<<"$non_comments"; then
        pass "Section 4: $f entries are deterministically sorted (LC_ALL=C sort -c)"
      else
        fail "Section 4: $f entries are not sorted"
      fi
    else
      fail "Section 4: $f does not exist"
    fi
  done

  # 2. Normal bootstrap dry-run must NOT mutate snapshots or working tree
  PORCELAIN_SNAP="$(git status --porcelain)"
  "$REPO_ROOT/bootstrap.sh" --dry-run >/dev/null 2>&1 || true
  if [[ "$PORCELAIN_SNAP" == "$(git status --porcelain)" ]]; then
    pass "Section 4: standard bootstrap invocation causes zero git working-tree drift"
  else
    fail "Section 4: standard bootstrap invocation mutated git working tree"
  fi
fi
```

#### Pattern 2.7: Section 5 — Live Host Dry-Run, PAIR_COUNT Invariant, and Strict Verification
Source: `scripts/phase17-unblock-assert.sh:89-96`, `scripts/phase22-kde-and-gtk-capture-assert.sh:536-544`
```bash
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 5 ]]; then
  info "--- Section 5: Live host dry-run, PAIR_COUNT == 18, and verify --strict ---"

  # 1. Live dry-run executes cleanly
  DRY_RC=0
  DRY_OUT="$("$REPO_ROOT/bootstrap.sh" --dry-run 2>&1)" || DRY_RC=$?
  if [[ "$DRY_RC" -eq 0 ]]; then
    pass "Section 5: ./bootstrap.sh --dry-run exited 0 on live host"
  else
    fail "Section 5: ./bootstrap.sh --dry-run failed (rc=$DRY_RC)"
    printf '%s\n' "$DRY_OUT" | sed 's/^/       /' >&2
  fi

  # 2. Invariant: PAIR_COUNT in arch/*.sh MUST remain 18
  PAIR_COUNT="$(grep -ho -- '--verbose=5 --no-folding' arch/*.sh | wc -l || true)"
  if [[ "$PAIR_COUNT" -eq 18 ]]; then
    pass "Section 5: PAIR_COUNT invariant in arch/*.sh is strictly 18"
  else
    fail "Section 5: PAIR_COUNT in arch/*.sh drifted (expected 18, counted $PAIR_COUNT)"
  fi

  # 3. Live verification exit code gate
  VERIFY_RC=0
  VERIFY_OUT="$("$REPO_ROOT/arch/dots-hyprland.sh" verify --strict 2>&1)" || VERIFY_RC=$?
  if [[ "$VERIFY_RC" -eq 0 ]]; then
    pass "Section 5: live arch/dots-hyprland.sh verify --strict passed with zero findings"
  else
    fail "Section 5: live arch/dots-hyprland.sh verify --strict failed (rc=$VERIFY_RC)"
    printf '%s\n' "$VERIFY_OUT" | sed 's/^/       /' >&2
  fi
fi
```

#### Pattern 2.8: Closing Self-Check & Exit Verdict
Source: `scripts/phase19-link-aware-verify-assert.sh:1693-1705`, `scripts/phase22-kde-and-gtk-capture-assert.sh:549-554`
```bash
# Closing self-check: porcelain comparison
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

### 3. `arch/dots-hyprland.sh` (Modifications)

**Role:** Upstream wrapper script modified to add `bootstrap` subcommand delegating to `./bootstrap.sh`.  
**Analog:** Existing `arch/dots-hyprland.sh:17, 30-34, 1726-1740`.

#### Pattern 3.1: ALLOWLIST Update
Source: `arch/dots-hyprland.sh:17`
```bash
# Existing:
# ALLOWLIST=(install install-deps install-setups install-files uninstall verify capture)
# Modified:
ALLOWLIST=(install install-deps install-setups install-files uninstall verify capture bootstrap)
```

#### Pattern 3.2: Usage Documentation
Source: `arch/dots-hyprland.sh:29-35, 46-54`
```bash
# Add to Usage block:
#   arch/dots-hyprland.sh bootstrap [flags…]
# Add to Allowlisted subcommands:
#   bootstrap        Root orchestrator: runs the full reproduction pipeline via ./bootstrap.sh
```

#### Pattern 3.3: Case Dispatcher Routing
Source: `arch/dots-hyprland.sh:1726-1740`
Direct process replacement (`exec`) forwards flags without modifying the argument list or creating new stow sites in `arch/`.
```bash
  case "$subcmd" in
    bootstrap)
      exec "$REPO_ROOT/bootstrap.sh" "$@"
      ;;
    uninstall)
      run_uninstall "$@"
      ;;
    verify)
      run_verify "$@"
      ;;
    capture)
      run_capture "$@"
      ;;
    *)
      run_install_family "$subcmd" "$@"
      ;;
  esac
```

---

### 4. `arch/pkglist-native.txt` & `arch/pkglist-aur.txt` (Data Files)

**Role:** Static committed package lists representing explicitly installed packages on the reference system.  
**Analog:** `guard-paths.tsv:1-13` (for metadata comment headers) + `pacman -Qqen` / `pacman -Qqem`.

#### Pattern 4.1: File Header Structure
```text
# arch/pkglist-native.txt — explicitly installed native packages
# Hostname: arch
# Timestamp: 2026-09-15T05:25:49Z
# Kernel: 7.2.4-arch1-2
# Pacman: Pacman v7.1.0 - libalpm v16.0.1
# Count: 207
alacritty
android-tools
at
autoconf-archive
base
base-devel
...
```

```text
# arch/pkglist-aur.txt — explicitly installed foreign/AUR packages
# Hostname: arch
# Timestamp: 2026-09-15T05:25:49Z
# Kernel: 7.2.4-arch1-2
# Pacman: Pacman v7.1.0 - libalpm v16.0.1
# Count: 56
affine-bin
anydesk-bin
brave-bin
catppuccin-cursors-mocha
catppuccin-gtk-theme-mocha
...
```

---

## Universal Repository Conventions & Invariants

### 1. Array Execution Over String Concatenation / Eval
- **Rule:** Never execute commands with `eval` or concatenated strings.
- **Source:** `arch/dots-hyprland.sh:39-40`, `scripts/phase19-link-aware-verify-assert.sh`
- **Pattern:**
  ```bash
  local -a cmd=("$REPO_ROOT/arch/dots-hyprland.sh" "verify" "--strict")
  "${cmd[@]}"
  ```

### 2. Standard Exit Code Hierarchy
- **Rule:**
  - `0`: Success / clean verification / operation completed without drift.
  - `1`: Failure / unrecoverable runtime error / live filesystem drift detected.
  - `2`: Precondition failure / invalid CLI flags / unknown option before execution starts.
- **Source:** `arch/dots-hyprland.sh:776-781, 1711`

### 3. The Universal Stow Invariant
- **Rule:** All invocations of GNU Stow must carry `--verbose=5 --no-folding -t <target>`.
- **Source:** `scripts/phase17-unblock-assert.sh:85-96`
- **Constraint:** `./bootstrap.sh` must remain at the repository root and must NOT add any lines matching `--verbose=5 --no-folding` inside `arch/*.sh`, preserving `PAIR_COUNT == 18`.

### 4. Banned Flags & Primitives
- **`stow --adopt`:** Strictly banned. Never adopt stubs into the repository source tree. Use `stow -n` discovery, backup to `$HOME/.dotfiles-backup.<epoch>/`, and unlink stubs before stowing.
- **`hostname` binary:** Banned on Arch Linux core. Use `uname -n`, `cat /etc/hostname`, or `$HOSTNAME`.
- **`rm -rf` without guard:** Destructive actions must only touch verified stubs or temporary directories created by `mktemp -d`. Never remove paths in `guard-paths.tsv`.

---

## Pattern Mapping Metadata

- **Phase:** 23 - One-command bootstrap
- **Target Directory:** `/home/pera/github_repo/.dotfiles/.planning/phases/23-one-command-bootstrap`
- **Mapped By:** GSD Pattern Mapper
- **Files Analyzed:**
  - `arch/dots-hyprland.sh` (wrapper analog)
  - `scripts/phase22-kde-and-gtk-capture-assert.sh` (assert analog)
  - `scripts/phase19-link-aware-verify-assert.sh` (assert & porcelain analog)
  - `scripts/phase17-unblock-assert.sh` (invariant gate analog)
  - `guard-paths.tsv` (theme guard analog)
  - `arch/aur.sh` (prerequisite installer analog)
