# Phase 6: Thin Setup Wrapper & Safe Defaults - Pattern Map

**Mapped:** 2026-07-25  
**Files analyzed:** 1 (primary deliverable) + optional smoke harness (discretion)  
**Analogs found:** 3 / 1 primary file (plus research skeleton for policy-only paths)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `arch/dots-hyprland.sh` | utility (CLI wrapper / arch provision script) | request-response (subcommand dispatch → exec) | `arch/quickshell.sh` | role-match (structure); **not** package-install analog |
| `scripts/phase06-wrapper-smoke.sh` (optional; not required) | test | batch (non-mutating shell asserts) | Phase 5 inline plan asserts / RESEARCH smoke block | partial — no dedicated smoke scripts in tree |

**Not in scope as source edits:** `arch/quickshell.sh`, `vendor/dots-hyprland/*` (call site only), package arrays, live install.

## Pattern Assignments

### `arch/dots-hyprland.sh` (utility, request-response)

**Primary analog:** `arch/quickshell.sh` — structured generation: shebang, `set -euo pipefail` (no `set -x`), `REPO_ROOT` from `BASH_SOURCE`, header comment (pattern + divergence), functions + `main "$@"`.

**Secondary analog:** `arch/system_monitor.sh` — same REPO_ROOT + `main` shape (but uses legacy `set -x`; **do not** copy `set -x`).

**Dispatch analog (subcommand routing only):** `vendor/dots-hyprland/setup` — case on `$1` for allowlist / help / unknown; **do not** source sdata or reimplement install steps.

**Policy patterns (backup gate, safe defaults, meta-flag strip):** no in-repo arch analog — copy from `06-RESEARCH.md` Architecture Patterns / Code Examples (locked D-01..D-16).

---

#### Imports / bootstrap pattern

**Source:** `arch/quickshell.sh` lines 1–11

```bash
#!/usr/bin/env bash
set -euo pipefail

# arch/quickshell.sh — Install Quickshell + ddcutil + i2c-tools, configure i2c, symlink config.
# Pattern: mirrors arch/waybar.sh (REPO_ROOT, PACKAGES array, main dispatcher, [LABEL] echos).
# Divergence from waybar.sh: uses a single directory symlink instead of per-file copies (D-17).
# AUR packages (python-materialyoucolor-git) require yay instead of pacman.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
QS_SRC="$REPO_ROOT/.config/quickshell"
QS_DST="$HOME/.config/quickshell"
```

**Adapt for Phase 6** (from RESEARCH Pattern 1 — copy structure, **omit** `PACKAGES`):

```bash
#!/usr/bin/env bash
set -euo pipefail

# arch/dots-hyprland.sh — thin wrapper around vendor/dots-hyprland/./setup
# Pattern: arch/quickshell.sh (REPO_ROOT, main dispatcher, [LABEL] echos).
# Divergence: no package arrays; delegates all install logic to upstream setup.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
II_ROOT="$REPO_ROOT/vendor/dots-hyprland"
SETUP="$II_ROOT/setup"
SAFE_DEFAULTS=(--core --skip-hyprland --skip-sysupdate)
ALLOWLIST=(install install-deps install-setups install-files)
```

**Anti-pattern:** Do **not** copy `PACKAGES=(...)` / `yay -Sy` / `sudo pacman` from quickshell or system_monitor (WRAP-01).

---

#### Labeled echo / progress vocabulary

**Source:** `arch/quickshell.sh` (and CONVENTIONS.md)

| Label | Used in analog for | Use in wrapper for |
|-------|--------------------|--------------------|
| `[INSTALL]` | package install | logged `./setup` exec line |
| `[CONFIG]` | config/setup steps | safe defaults, backup gate facts |
| `[VERIFY]` | post-install checks | optional preflight OK (optional) |
| `[DONE]` | summary | success after setup returns (if any) |
| `[FAIL]` | (CONVENTIONS + D-14; rare in quickshell as `FAIL:` inside VERIFY) | preflight, allowlist refuse, gate abort, skip-backup refuse |
| `[SKIP]` | system_monitor optional path | not required Phase 6 |

**Concrete analog excerpts:**

```23:26:arch/quickshell.sh
install_packages() {
  echo "[INSTALL] quickshell and runtime dependencies (${PACKAGES[*]})"
  yay -Sy --noconfirm --needed "${PACKAGES[@]}"
}
```

```28:34:arch/quickshell.sh
setup_i2c() {
  echo "[CONFIG] i2c kernel module and group membership
  ...
}
```

```78:85:arch/quickshell.sh
verify_install() {
  echo "[VERIFY] checking install state"
  command -v quickshell >/dev/null || { echo "[VERIFY] FAIL: quickshell not in PATH"; exit 1; }
  ...
  echo "[VERIFY] OK"
}
```

```88:93:arch/quickshell.sh
print_summary() {
  echo "[DONE] Quickshell installed and configured."
  ...
}
```

**Wrapper mapping (D-10, D-14):** prefer `[FAIL]` (not only `[VERIFY] FAIL:`) for hard errors per CONTEXT D-14 / RESEARCH.

---

#### Core pattern: `main()` dispatcher

**Source:** `arch/quickshell.sh` lines 95–104

```bash
main() {
  install_packages
  setup_i2c
  symlink_config
  generate_theme
  verify_install
  print_summary
}

main "$@"
```

**Phase 6 shape** (same entrypoint style; body is allowlist dispatch, not install steps):

```bash
main() {
  # 1) no args / help / -h / --help → usage; exit 0 (D-02, D-03)
  # 2) allowlist check (D-04)
  # 3) scan meta flags; --skip-backup policy (D-12)
  # 4) preflight (D-14) for any path that invokes setup
  # 5) inject SAFE_DEFAULTS for install|install-files (D-05/D-06)
  # 6) backup_gate for install|install-files unless subcmd help (D-11..D-13)
  # 7) log [CONFIG]/[INSTALL] argv (D-10)
  # 8) --dry-run → print would-exec; exit 0 (RESEARCH A1)
  # 9) ( cd "$II_ROOT" && ./setup ... ) array exec (D-09)
}
main "$@"
```

---

#### Subcommand case / help / unknown (upstream router)

**Source:** `vendor/dots-hyprland/setup` lines 14–63

```14:63:vendor/dots-hyprland/setup
showhelp_global(){
printf "${STY_CYAN}NOTE:
  ...
"
}
case $1 in
  ""|help|--help|-h)showhelp_global;exit;;
  install|uninstall|exp-update|exp-merge|resetfirstrun|checkdeps|virtmon)
    SUBCMD_NAME=$1
    SUBCMD_DIR=./sdata/subcmd-$1
    shift;;
  install-deps|install-setups|install-files)
    SUBCMD_NAME=$1
    SUBCMD_DIR=./sdata/subcmd-install
    shift;;
  *)printf "${STY_RED}Unknown subcommand \"$1\".${STY_RST}\n";showhelp_global;exit 1;;
esac
```

**Copy the idea, not the full subcommand set:**

| Upstream | Wrapper |
|----------|---------|
| `""\|help\|--help\|-h` → global help | same → **wrapper** `usage` (D-02/D-03), exit 0 |
| four install* + many others | **only** `install\|install-deps\|install-setups\|install-files` |
| unknown → error + help | unknown → `[FAIL]` + point at `vendor/dots-hyprland/./setup` (D-04) |
| sources options + steps | **never** source sdata; only `exec`/`./setup` |

---

#### Argv construction (arrays, no eval)

**Source:** RESEARCH Pattern 2 (no arch script currently builds multi-flag `./setup` argv)

```bash
cmd=(./setup "$subcmd")
if needs_safe_defaults "$subcmd"; then
  echo "[CONFIG] safe defaults: ${SAFE_DEFAULTS[*]}"
  cmd+=("${SAFE_DEFAULTS[@]}")
fi
cmd+=("${user_flags[@]}")  # stripped of --allow-skip-backup / --dry-run
echo "[INSTALL] ${cmd[*]}  (cwd=$II_ROOT)"
(
  cd "$II_ROOT"
  "${cmd[@]}"
)
```

**Order locked (D-09):** `./setup <subcommand> <safe defaults…> <user flags…>`.

**Strip before exec (must not forward):** `--allow-skip-backup`, `--dry-run` (setup getopt rejects unknown long options).

---

#### Preflight without auto-fix

**Source:** RESEARCH Pattern 4 + Phase 5 D-15 philosophy; closest **style** is quickshell `verify_install` fail-and-exit.

```bash
preflight() {
  if [[ ! -e "$II_ROOT/.git" ]]; then
    echo "[FAIL] vendor/dots-hyprland is not an initialized submodule (missing .git)."
    echo "[FAIL] Fix (from REPO_ROOT): git submodule update --init --recursive"
    exit 1
  fi
  if [[ ! -x "$SETUP" ]]; then
    echo "[FAIL] $SETUP missing or not executable."
    echo "[FAIL] Fix: git submodule update --init --recursive && chmod +x vendor/dots-hyprland/setup"
    exit 1
  fi
}
```

**When:** before any invocation that needs `./setup` (including `install -h`). **Not** for bare wrapper help (D-02).  
**Never:** run `git submodule update` inside the wrapper (D-15).

---

#### Hard backup gate + refuse bare `--skip-backup`

**Source:** RESEARCH Pattern 3; backup path SoT `vendor/dots-hyprland/sdata/lib/environment-variables.sh` line 27:

```bash
BACKUP_DIR="${BACKUP_DIR:-$HOME/ii-original-dots-backup}"
```

```bash
backup_gate() {
  echo "[CONFIG] Upstream may backup clashing paths to: ~/ii-original-dots-backup"
  echo "[CONFIG] install-files will overwrite ~/.config/quickshell (rsync --delete)."
  echo "[CONFIG] Defaults include --skip-hyprland so personal hyprland.conf is not renamed."
  echo "[CONFIG] Do NOT pass --skip-backup on first adoption."
  local ans
  read -r -p "Type 'yes' to continue: " ans
  if [[ "$ans" != "yes" ]]; then
    echo "[FAIL] Aborted (backup gate). No ./setup invoked."
    exit 1
  fi
}
```

**Apply only to:** `install`, `install-files` (D-11). Skip gate when remaining args are subcommand help (`-h` / `--help`).  
**`--skip-backup`:** refuse unless `--allow-skip-backup` also present; forward only `--skip-backup` (D-12).

---

#### Help / usage text

**Style analog:** setup `showhelp_global` (here-doc / printf block) + RESEARCH `usage()` skeleton.  
**Content requirements (WRAP-03 education):** safe defaults list + which subcommands get them; backup gate + `~/ii-original-dots-backup`; refuse `--skip-backup` without override; four-subcommand allowlist; examples; pointer to vendor `./setup` for non-allowlisted ops; note that full hypr install requires calling setup **outside** wrapper (no undo for injected `--skip-hyprland`).

---

#### Defaults matrix (copy into implementation, not from arch/)

| Subcommand | Inject `SAFE_DEFAULTS` | Backup gate | Notes |
|------------|------------------------|-------------|-------|
| `install` | Yes | Yes | Full path includes files |
| `install-files` | Yes | Yes | Files only |
| `install-deps` | No | No | Passthrough only |
| `install-setups` | No | No | Passthrough only |

`SAFE_DEFAULTS=(--core --skip-hyprland --skip-sysupdate)` — **never** `--skip-hyprland-entry`, `-f`/`--force`, or `--skip-allgreeting` (D-06..D-08).

---

### Optional: `scripts/phase06-wrapper-smoke.sh` (test, batch)

**Analog:** none first-class; use RESEARCH “Non-mutating smoke” block (lines ~545–582) and Validation Architecture test map. Prefer **inline plan `<verify>` asserts** (Phase 5 style) over a new script unless planner wants one-shot suite.

**Smoke scope (D-16):** help, allowlist refuse, dry-run argv logging, skip-backup policy, passthrough — **no** live `install*`.

## Shared Patterns

### REPO_ROOT resolution
**Source:** `arch/quickshell.sh` line 9; CONVENTIONS.md “Path Assumptions”  
**Apply to:** `arch/dots-hyprland.sh`

```bash
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
```

### Strict mode without `set -x`
**Source:** `arch/quickshell.sh` lines 1–2 (prefer over `system_monitor.sh` which uses `set -x`)  
**Apply to:** new wrapper

```bash
#!/usr/bin/env bash
set -euo pipefail
# no set -x — labeled echos instead (CONVENTIONS structured template)
```

### Header comment: Pattern + Divergence
**Source:** `arch/quickshell.sh` lines 4–7  
**Apply to:** new wrapper — document mirrors `quickshell.sh` structure; diverges by zero package arrays / exec-only to setup.

### `[LABEL]` progress output
**Source:** CONVENTIONS.md + `arch/quickshell.sh`  
**Apply to:** all operator-facing messages in wrapper (`[CONFIG]`, `[INSTALL]`, `[FAIL]`, optional `[DONE]`).

### Fail closed, print fix command (no auto-repair)
**Source:** Phase 5 D-15 + RESEARCH Pattern 4; style of quickshell verify exits  
**Apply to:** preflight submodule/setup checks.

### Array-safe exec (security V5)
**Source:** RESEARCH security + Pattern 2  
**Apply to:** building and running `./setup` argv — never `eval`.

### Upstream remains SoT for install logic
**Source:** `vendor/dots-hyprland/setup` + WRAP-01  
**Apply to:** entire phase — wrapper is UX/policy only.

## No Analog Found

| File / concern | Role | Data Flow | Reason |
|----------------|------|-----------|--------|
| Safe-default flag injection | policy | transform argv | No arch script injects flags into another installer |
| Interactive backup gate (`read -r -p` + `yes`) | policy | request-response | No arch script hard-gates before destructive config overwrite |
| Wrapper-owned meta flags (`--allow-skip-backup`, `--dry-run`) strip | middleware-like | transform | No dual-flag ownership pattern in arch/ |
| Subcommand allowlist CLI | utility | request-response | No multi-subcommand arch entrypoint; closest is vendor `setup` case (partial) |

**Planner guidance:** implement policy paths from `06-RESEARCH.md` Code Examples; structure/skeleton from `arch/quickshell.sh`.

## Metadata

**Analog search scope:** `arch/*.sh`, `vendor/dots-hyprland/setup`, `.planning/codebase/CONVENTIONS.md`, Phase 6 CONTEXT/RESEARCH  
**Files scanned:** ~33 arch scripts listed; deep-read `quickshell.sh`, `system_monitor.sh`, `setup`; CONVENTIONS structured template  
**Primary structural template:** `arch/quickshell.sh`  
**Primary policy template:** `06-RESEARCH.md` Patterns 1–4 + dispatcher skeleton  
**Pattern extraction date:** 2026-07-25
