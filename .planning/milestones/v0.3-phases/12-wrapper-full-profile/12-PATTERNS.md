# Phase 12: Wrapper full-profile - Pattern Map

**Mapped:** 2026-08-11
**Files analyzed:** 2
**Analogs found:** 2 / 2

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `arch/dots-hyprland.sh` | utility (CLI thin wrapper) | request-response (subcommand → argv build → dry-run/exec) | **self** — same file; extend existing seams | exact |
| `scripts/phase12-full-smoke.sh` (optional, discretion) | test / smoke harness | batch (non-mutating asserts) | `scripts/phase07-live-smoke.sh` | role-match |

Primary implementation surface is a **surgical edit** of one script. No new product path, controller, or service.

## Pattern Assignments

### `arch/dots-hyprland.sh` (utility, request-response)

**Analog:** `arch/dots-hyprland.sh` (in-file patterns — Phase 6/7 already established)

All Phase 12 work copies existing seams; only branch points are `--full` strip, conditional SAFE_DEFAULTS, and full gate messaging / `usage()` rewrite.

---

#### 1. SAFE_DEFAULTS constant (keep literal; FULL-02)

**Source:** lines 12–14

```bash
SAFE_DEFAULTS=(--core --skip-hyprland --skip-sysupdate)
# install* → upstream ./setup; uninstall/protect → wrapper-owned safe path
ALLOWLIST=(install install-deps install-setups install-files uninstall protect)
```

**Phase 12 rule:** Do **not** change the array contents. Full profile = skip **prepending** this array, not empty the constant.

---

#### 2. `usage()` help surface (D-04 / D-13)

**Source:** lines 23–115 — rewrite sections; keep cat heredoc style

**Imports / structure pattern** (lines 23–31):

```bash
usage() {
  cat <<'EOF'
arch/dots-hyprland.sh — thin wrapper for vendor/dots-hyprland/./setup

Usage:
  arch/dots-hyprland.sh <install|install-deps|install-setups|install-files> [flags…]
  …
EOF
}
```

**Meta-flags block to extend** (lines 92–94):

```text
Wrapper-owned meta flags (stripped; never forwarded to ./setup):
  --dry-run              Print would-exec argv and exit 0
  --allow-skip-backup    Explicit override for --skip-backup policy
```

**Add:** `--full` documentation (install / install-files only; no SAFE_DEFAULTS injection; primary full path).

**Anti-pattern text to remove** (lines 113–114):

```text
Note: once defaults inject --skip-hyprland there is no upstream undo flag.
Full hypr install requires calling vendor/dots-hyprland/./setup outside this wrapper.
```

**Replace with:** wrapper `install --full` / `install-files --full` as primary full path; keep safe-defaults section for default path; point to `docs/dots-hyprland-workflow.md` and INV/DISP artifact paths (discoverable pointers only — no Phase 15 polish).

**Examples block to extend** (lines 96–101):

```text
  ./arch/dots-hyprland.sh install
  …
  printf 'yes\n' | ./arch/dots-hyprland.sh install --dry-run
```

**Add examples:** `install --full`, `printf 'yes\n' | … install --full --dry-run`.

---

#### 3. `needs_safe_defaults` subcommand scope (D-02 — reuse, do not broaden)

**Source:** lines 126–132

```bash
# D-05: defaults only for files-touching install paths.
needs_safe_defaults() {
  case "$1" in
    install|install-files) return 0 ;;
    *) return 1 ;;
  esac
}
```

**Phase 12 rule:** `--full` is accepted only where this returns true. Prefer refuse with `[FAIL]` on e.g. `install-deps --full` rather than silent ignore (RESEARCH A1).

---

#### 4. Interactive type-yes backup gate (D-06 / D-07 / D-08)

**Source:** lines 148–160

```bash
# D-11 / D-13: hard interactive gate for install / install-files.
backup_gate() {
  echo "[CONFIG] Upstream may backup clashing paths to: ~/ii-original-dots-backup"
  echo "[CONFIG] install-files will overwrite ~/.config/quickshell (Quickshell tree / rsync --delete)."
  echo "[CONFIG] Defaults include --skip-hyprland so personal hyprland.conf is not renamed."
  echo "[CONFIG] Do NOT pass --skip-backup on first adoption."
  local ans
  read -r -p "Type 'yes' to continue: " ans
  if [[ "$ans" != "yes" ]]; then
    echo "[FAIL] Aborted (backup gate). No ./setup invoked." >&2
    exit 1
  fi
}
```

**Core pattern to copy:**
- Token must remain exactly `yes` (not `FULL`, not two-step).
- Gate runs on dry-run too (call site before dry-run branch).
- Abort → non-zero, no `./setup`.

**Phase 12 delta:** branch messaging for full (same `read` / token). Full themes (D-07):
- no SAFE_DEFAULTS residual injection on this path
- hypr conf may become `.old`
- misc may overwrite without `--core`
- sysupdate / `pacman -Syu` may run on deps path
- upstream backup dir `~/ii-original-dots-backup`
- still refuse bare `--skip-backup`

Structure discretion: separate `full_backup_gate` **or** `backup_gate` with a full flag — either is fine if type-yes and themes hold.

**Do not** reuse safe-path line “Defaults include --skip-hyprland so personal hyprland.conf is not renamed” on the full path (pitfall 5).

---

#### 5. Help-only gate skip + flag helpers

**Source:** lines 162–186

```bash
is_help_only_user_flags() {
  local -n _flags=$1
  …
  for f in "${_flags[@]}"; do
    case "$f" in
      -h|--help) ;;
      *) return 1 ;;
    esac
  done
  return 0
}

user_flags_contain() {
  local needle="$1"
  local -n _flags=$2
  …
}
```

**Reuse unchanged** for gate skip and bare `--skip-backup` detection.

---

#### 6. Meta-flag strip loop (D-01 — primary pattern for `--full`)

**Source:** lines 1361–1382

```bash
run_install_family() {
  local subcmd="$1"
  shift

  # Scan remaining args: strip wrapper-owned meta flags; preserve order (WRAP-04)
  local dry_run=0
  local allow_skip_backup=0
  local -a user_flags=()
  local arg
  for arg in "$@"; do
    case "$arg" in
      --dry-run)
        dry_run=1
        ;;
      --allow-skip-backup)
        allow_skip_backup=1
        ;;
      *)
        user_flags+=("$arg")
        ;;
    esac
  done
```

**Phase 12 delta (illustrative copy target):**

```bash
  local dry_run=0
  local allow_skip_backup=0
  local full=0
  local -a user_flags=()
  local arg
  for arg in "$@"; do
    case "$arg" in
      --dry-run) dry_run=1 ;;
      --allow-skip-backup) allow_skip_backup=1 ;;
      --full) full=1 ;;
      *) user_flags+=("$arg") ;;
    esac
  done

  if ((full == 1)) && ! needs_safe_defaults "$subcmd"; then
    echo "[FAIL] --full is only valid with install or install-files." >&2
    exit 1
  fi
```

**Rules:** never put `--full` in `user_flags` / `cmd`; preserve remaining flag order (WRAP-04).

---

#### 7. Bare `--skip-backup` refuse (FULL-03 / D-09)

**Source:** lines 1387–1392

```bash
  if user_flags_contain "--skip-backup" user_flags && ((allow_skip_backup == 0)); then
    echo "[FAIL] --skip-backup refused without --allow-skip-backup." >&2
    echo "[FAIL] First adoption must not skip backup. Re-run with --allow-skip-backup only if you intentionally override." >&2
    exit 1
  fi
```

**Phase 12 rule:** Shared for safe and full — no harder full-only rule. Runs **before** gate (so dry-run refuse does not hang on `read`).

---

#### 8. Gate call site (still on dry-run; D-08)

**Source:** lines 1394–1397

```bash
  if needs_safe_defaults "$subcmd" && ! is_help_only_user_flags user_flags; then
    backup_gate
  fi
```

**Phase 12 delta:** pass `full` into gate / branch messaging; keep same condition (gate on full dry-run too).

---

#### 9. Conditional SAFE_DEFAULTS injection (D-03 / FULL-01 / FULL-02)

**Source:** lines 1399–1407

```bash
  # Build argv: ./setup <sub> [SAFE_DEFAULTS…] [user flags…] (D-09)
  local -a cmd=(./setup "$subcmd")
  if needs_safe_defaults "$subcmd"; then
    echo "[CONFIG] safe defaults: ${SAFE_DEFAULTS[*]}"
    cmd+=("${SAFE_DEFAULTS[@]}")
  fi
  if ((${#user_flags[@]} > 0)); then
    cmd+=("${user_flags[@]}")
  fi
```

**Phase 12 delta:**

```bash
  local -a cmd=(./setup "$subcmd")
  if needs_safe_defaults "$subcmd" && ((full == 0)); then
    echo "[CONFIG] safe defaults: ${SAFE_DEFAULTS[*]}"
    cmd+=("${SAFE_DEFAULTS[@]}")
  elif needs_safe_defaults "$subcmd" && ((full == 1)); then
    echo "[CONFIG] full profile: no SAFE_DEFAULTS injection (DISP-02 drop-all-three)"
  fi
  if ((${#user_flags[@]} > 0)); then
    cmd+=("${user_flags[@]}")
  fi
```

**Array exec only** — never `eval` (line 1426–1430).

---

#### 10. Dry-run would-exec + post-setup plan (FULL-04 / FULL-05 / D-16)

**Source:** lines 1409–1423

```bash
  echo "[INSTALL] ${cmd[*]}  (cwd=$II_ROOT)"

  if ((dry_run)); then
    echo "[CONFIG] dry-run: would exec from $II_ROOT: ${cmd[*]}"
    case "$subcmd" in
      install|install-deps|install-files)
        echo "[CONFIG] dry-run: after setup, would re-mark protect-list as explicit (ii demotes deps)"
        protect_explicit_packages 1 "PROTECT"
        echo "[CONFIG] dry-run: after setup, would enable ii hooks in live + repo hyprland.conf"
        enable_hypr_ii_hooks 1
        ;;
    esac
    exit 0
  fi
```

**Phase 12 rule:** Do **not** special-case `--full` out of this case arm. Full dry-run must still print protect + ii hooks plan.

---

#### 11. Live post-setup protect + hooks (FULL-05 / D-14 / D-15)

**Source:** lines 1432–1442

```bash
  case "$subcmd" in
    install|install-deps|install-files)
      echo "[PROTECT] Post-install: re-marking personal dual-run stack as explicit…"
      protect_explicit_packages 0 "PROTECT" || {
        echo "[PROTECT] WARNING: some packages could not be marked explicit; review above." >&2
      }
      enable_hypr_ii_hooks 0
      ;;
  esac
```

**Reuse:** `protect_explicit_packages` (318–357), `PROTECT_EXPLICIT` (197–262), `enable_hypr_ii_hooks` (758–803 dry-run branch). Do **not** expand protect list this phase.

**Dry-run mode inside protect** (lines 332–335):

```bash
  if ((dry_run)); then
    echo "[CONFIG] dry-run: would re-mark as explicit (survives yay -Yc / pacman -Rsu):"
    printf '[CONFIG] dry-run:   %s\n' "${present[@]}"
    return 0
  fi
```

**Dry-run mode inside enable hooks** (lines 790–793):

```bash
  if ((dry_run)); then
    echo "[CONFIG] dry-run: would enable ii hooks (uncomment/insert) in:"
    printf '[CONFIG] dry-run:   %s\n' "${files[@]}"
    return 0
  fi
```

---

#### 12. Label / error echo convention (shared)

```bash
echo "[CONFIG] …"
echo "[INSTALL] …"
echo "[PROTECT] …"
echo "[FAIL] …" >&2
exit 1
```

Keep `[LABEL]` style; full-profile log lines should use `[CONFIG]` for argv profile and gate messaging.

---

### `scripts/phase12-full-smoke.sh` (optional test, batch)

**Analog:** `scripts/phase07-live-smoke.sh`

**Only if** planner chooses a checked-in harness; RESEARCH default is **inline** plan-task asserts (no new file required).

**Imports / bootstrap** (phase07 lines 15–23):

```bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

FAIL=0
pass() { printf '[PASS] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
```

**Core dry-run feed + SAFE_DEFAULTS assert** (phase07 lines 80–114) — negative control for FULL-02:

```bash
bash -n ./arch/dots-hyprland.sh
DRY_OUT="$(mktemp)"
if printf 'yes\n' | ./arch/dots-hyprland.sh install --dry-run >"$DRY_OUT" 2>&1; then
  if grep -q -- '--core' "$DRY_OUT" \
    && grep -q -- '--skip-hyprland' "$DRY_OUT" \
    && grep -q -- '--skip-sysupdate' "$DRY_OUT" \
    && grep -qiE 'dry-run|would exec' "$DRY_OUT"; then
    pass "install --dry-run SAFE_DEFAULTS"
  else
    fail "install --dry-run SAFE_DEFAULTS (argv missing)"
  fi
  if grep -qE 'pacman -D --asexplicit|would re-mark as explicit|re-mark protect-list as explicit' "$DRY_OUT"; then
    pass "protect plan"
  fi
  if grep -qiE 'enable ii hooks|ii hooks already active|would enable ii hooks' "$DRY_OUT"; then
    pass "ii hooks plan"
  fi
fi
```

**Phase 12 full-path asserts to add** (from RESEARCH validation matrix):

```bash
# FULL-01 / FULL-04 — drop all three residuals
printf 'yes\n' | ./arch/dots-hyprland.sh install --full --dry-run | tee /tmp/p12-full.txt
grep -q 'would exec' /tmp/p12-full.txt
! grep -q -- '--skip-hyprland' /tmp/p12-full.txt
! grep -q -- '--skip-sysupdate' /tmp/p12-full.txt
! grep -E -- '(^|[[:space:]])--core([[:space:]]|$)' /tmp/p12-full.txt
! grep -q -- '--full' /tmp/p12-full.txt   # meta must not leak into would-exec

# FULL-05
grep -q 'protect-list' /tmp/p12-full.txt
grep -qi 'ii hooks' /tmp/p12-full.txt

# FULL-03
./arch/dots-hyprland.sh install --full --skip-backup --dry-run; test $? -ne 0

# D-02
./arch/dots-hyprland.sh install-deps --full --dry-run; test $? -ne 0

# D-04 / D-13
./arch/dots-hyprland.sh help | grep -q -- '--full'
./arch/dots-hyprland.sh help | grep -q 'dots-hyprland-workflow'
! ./arch/dots-hyprland.sh help | grep -qi 'Full hypr install requires calling vendor'
```

**Secondary analog:** `scripts/phase11-dispositions-assert.sh` — `pass`/`fail` counters and exit-at-end style (lines 28–30); not install-related content.

**Do not** copy phase07 LIVE-01 filesystem mutation checks into Phase 12 smoke.

## Shared Patterns

### Wrapper-owned meta flags

**Source:** `arch/dots-hyprland.sh` `run_install_family` strip loop (1365–1382)
**Apply to:** `--full` (new), existing `--dry-run`, `--allow-skip-backup`

- Boolean locals; case arms; remainder → `user_flags[]`
- Never forward to `./setup`
- Order of non-meta flags preserved

### SAFE_DEFAULTS injection gate

**Source:** lines 12, 127–131, 1399–1404
**Apply to:** `install` / `install-files` only

- Default: prepend triple residual
- `--full`: inject **nothing** from SAFE_DEFAULTS (all three dropped — DISP-02)

### Intentionality gate (type `yes`)

**Source:** `backup_gate` 149–160 + call site 1394–1397
**Apply to:** safe and full files-touching paths, **including** `--dry-run`

- Same token; full-specific messaging only
- Feed tests with `printf 'yes\n' |`

### Dual-key skip-backup

**Source:** lines 1387–1392
**Apply to:** safe and full equally (FULL-03 / D-09)

### Post-setup protect + ii hooks

**Source:** dry-run 1415–1421; live 1435–1442; helpers 318+, 758+
**Apply to:** `install|install-deps|install-files` including under `--full`

### Array exec / no eval

**Source:** lines 1426–1430
**Apply to:** any real exec path (Phase 14 live full)

```bash
  (
    cd "$II_ROOT"
    "${cmd[@]}"
  )
```

### `[LABEL]` logging

**Source:** throughout wrapper
**Apply to:** new full-profile `[CONFIG]` / `[FAIL]` lines

### Smoke style (non-mutating)

**Source:** `scripts/phase07-live-smoke.sh` 80–149; RESEARCH validation matrix
**Apply to:** plan verifies or optional `phase12-full-smoke.sh`

- `bash -n`
- help greps
- `printf 'yes\n' | … --dry-run`
- refuse paths expect non-zero
- **no** live `install --full` without dry-run

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| — | — | — | No greenfield product files. Full profile is absence of injection on existing path. |

Optional smoke script has a strong role-match in phase07; not listed as “no analog.”

## Anti-Patterns (do not copy)

| Anti-pattern | Why |
|--------------|-----|
| New `install-full` subcommand | Rejected D-01 |
| Forward `--full` to setup | Unknown long opt fails upstream |
| Partial residual drop | Violates DISP-02 / D-03 |
| Skip gate on `--full --dry-run` | Violates D-08 |
| Read `.planning/` INV/DISP from wrapper | Violates D-10 |
| Expand `PROTECT_EXPLICIT` “just in case” | Deferred / D-14 |
| Leave usage vendor-outside full note | Violates D-04 |
| Live full install in Phase 12 smoke | Deferred Phase 14 / D-17 |

## Metadata

**Analog search scope:** `arch/dots-hyprland.sh`, `scripts/phase07-live-smoke.sh`, `scripts/phase11-dispositions-assert.sh`, `scripts/phase10-inventory-assert.sh` (listed only)
**Files scanned:** ~5 primary (wrapper + 3 smoke/assert scripts + CONTEXT/RESEARCH)
**Pattern extraction date:** 2026-08-11
**Planner note:** Prefer citing line ranges above in PLAN action “copy from” steps; sole required edit file is `arch/dots-hyprland.sh`.
