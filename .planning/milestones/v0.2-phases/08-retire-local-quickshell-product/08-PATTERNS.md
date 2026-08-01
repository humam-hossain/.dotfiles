# Phase 8: Retire Local Quickshell Product - Pattern Map

**Mapped:** 2026-07-27
**Files analyzed:** 6 surfaces (2 hard deletes, 1 optional edit, 0 new scripts; plus operational reinstall + inline verify)
**Analogs found:** 5 / 6 (no prior large tree `git rm` in-repo scripts; use RESEARCH + git idioms)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.config/quickshell/**` (delete ~933 tracked) | product tree / config | file-I/O (repo content removal) | No prior atomic tree-delete script; anti-pattern contrast: `arch/quickshell.sh` `symlink_config` | partial (ordering from RESEARCH + Phase 7 smoke) |
| `arch/quickshell.sh` (hard delete) | installer script (retire) | batch (destructive install) | Self as anti-pattern; style twin `arch/waybar.sh` | exact role of *what is removed* |
| `arch/dots-hyprland.sh` (optional L5 comment only) | config / wrapper | request-response (CLI allowlist) | `arch/dots-hyprland.sh` itself; header style from `arch/waybar.sh` / `arch/quickshell.sh` | exact |
| Inline live-health asserts (plan tasks only; **no new file**) | test / verify | request-response (filesystem/process) | `scripts/phase07-live-smoke.sh` LIVE-01/02 blocks **minus D-04** | exact (lift, do not rewrite file) |
| Reinstall path (ops only; **no new file**) | service / install | batch + interactive gate | `arch/dots-hyprland.sh` install / install-files | exact |
| Stale ref grep/cleanup (minimal; optional comment) | utility / cleanup | transform (text) | RESEARCH Pattern 3 classification + `arch/waybar.sh` STALE_* lists as “remove known dead surfaces” spirit | role-match |

**Explicit non-files (do not create or rewrite):**
- `scripts/phase08-*-smoke.sh` — forbidden (D-03)
- `scripts/phase07-live-smoke.sh` — leave frozen (D-04 will fail post-RET-01)
- `scripts/phase04-ipc-reload-assert.py` — leave historical
- Live `~/.config/quickshell` — never delete as retirement
- Package uninstall — out of scope (D-05)

## Pattern Assignments

### `.config/quickshell/**` (product tree delete, file-I/O)

**Analog:** No in-repo automation for large `git rm -r`. Closest **safety** analog is Phase 7 smoke LIVE-01 independence checks; closest **anti-pattern** is `arch/quickshell.sh` `symlink_config` (must never run during/after delete).

**Order pattern** (from RESEARCH Pattern 1 + D-14 — planner embeds in tasks):

```bash
# 1) Health BEFORE any git rm of product tree
test ! -L "${HOME}/.config/quickshell"
test -d "${HOME}/.config/quickshell"
test -f "${HOME}/.config/quickshell/ii/shell.qml"
case "$(readlink -f "${HOME}/.config/quickshell")" in
  */.dotfiles/.config/quickshell*) echo "FAIL: still under repo"; exit 1 ;;
esac

# 2) Tree delete — REPO only — own commit (D-07/D-09)
git rm -r .config/quickshell
# Untracked WIP leftovers (D-08): git rm only stages tracked
if [[ -e .config/quickshell ]]; then
  rm -rf .config/quickshell   # ONLY under REPO_ROOT, never $HOME
fi
test ! -e .config/quickshell
git commit -m "chore(08): remove in-repo v0.1 .config/quickshell product tree (RET-01)"
```

**Anti-pattern — do not execute** (`arch/quickshell.sh` lines 36–40):

```bash
# symlink_config — DESTROYS live real dir and points at repo product
rm -rf "$QS_DST"
ln -s "$QS_SRC" "$QS_DST"
```

**Post-delete live hold** (invert shipping, keep host product):

```bash
test ! -e "${REPO_ROOT}/.config/quickshell"
test ! -L "${HOME}/.config/quickshell"
test -f "${HOME}/.config/quickshell/ii/shell.qml"
```

**Match quality notes:** Atomic commit isolation (D-09) has no script analog — treat as git workflow constraint in plan steps.

---

### `arch/quickshell.sh` (hard delete, installer retirement)

**Analog:** File itself is the surface to remove (RET-02). Structural twin for “arch app installer” is `arch/waybar.sh` (packages + copy/symlink config) — **do not copy behavior**; use only to understand what is being retired.

**Delete pattern:**

```bash
# Separate commit from tree delete (D-09)
git rm arch/quickshell.sh
git commit -m "chore(08): remove arch/quickshell.sh old product installer (RET-02)"
test ! -e arch/quickshell.sh
```

**Why hard delete not stub:** D-04; Pitfall 10 (zombie installer). No deprecation stub file.

**Forbidden post-condition:** Any non-planning code path that still *calls* `./arch/quickshell.sh`. Current grep (non-planning): only self + one comment in `arch/dots-hyprland.sh` L5.

---

### `arch/dots-hyprland.sh` (optional comment reword; keep wrapper)

**Analog:** Same file — sole install entry (D-13). Header comment style shared with `arch/quickshell.sh` / `arch/waybar.sh`.

**Imports / header pattern** (lines 1–12) — keep structure; discretionary L5 reword only:

```1:12:arch/dots-hyprland.sh
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

**Suggested discretionary reword (agent discretion, D-13):** e.g. `# Pattern: arch/*.sh (REPO_ROOT, main dispatcher, [LABEL] echos).` citing `arch/waybar.sh` instead of deleted installer — same commit as RET-02 or tiny follow-up cleanup commit.

**Core reinstall patterns to copy unchanged:**

**Preflight** (lines 76–88):

```76:88:arch/dots-hyprland.sh
preflight() {
  if [[ ! -e "$II_ROOT/.git" ]]; then
    echo "[FAIL] vendor/dots-hyprland is not an initialized submodule (missing .git)." >&2
    echo "[FAIL] Fix (from REPO_ROOT): git submodule update --init --recursive" >&2
    exit 1
  fi
  if [[ ! -x "$SETUP" ]]; then
    echo "[FAIL] $SETUP missing or not executable." >&2
    echo "[FAIL] Fix: git submodule update --init --recursive && chmod +x vendor/dots-hyprland/setup" >&2
    exit 1
  fi
}
```

**Backup gate** (lines 90–102) — never bypass with bare `--skip-backup`:

```90:102:arch/dots-hyprland.sh
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

**Dry-run + SAFE_DEFAULTS injection** (lines 188–204):

```188:204:arch/dots-hyprland.sh
  local -a cmd=(./setup "$subcmd")
  if needs_safe_defaults "$subcmd"; then
    echo "[CONFIG] safe defaults: ${SAFE_DEFAULTS[*]}"
    cmd+=("${SAFE_DEFAULTS[@]}")
  fi
  if ((${#user_flags[@]} > 0)); then
    cmd+=("${user_flags[@]}")
  fi

  echo "[INSTALL] ${cmd[*]}  (cwd=$II_ROOT)"

  # 8) --dry-run: print would-exec, exit 0 without calling setup (D-16)
  if ((dry_run)); then
    echo "[CONFIG] dry-run: would exec from $II_ROOT: ${cmd[*]}"
    exit 0
  fi
```

**Array exec only** (lines 206–210) — never `eval`:

```206:210:arch/dots-hyprland.sh
  (
    cd "$II_ROOT"
    "${cmd[@]}"
  )
```

**Reinstall sequence if health fails** (ops, no new file):

```bash
REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"
pkill -x qs 2>/dev/null || true   # optional mid-session
printf 'yes\n' | ./arch/dots-hyprland.sh install --dry-run
# Expect: ./setup install --core --skip-hyprland --skip-sysupdate
./arch/dots-hyprland.sh install    # interactive yes at gate
# or: ./arch/dots-hyprland.sh install-files
test ! -L "${HOME}/.config/quickshell"
test -f "${HOME}/.config/quickshell/ii/shell.qml"
```

---

### Inline live-health asserts (plan `<automated>` blocks only)

**Analog:** `scripts/phase07-live-smoke.sh` — **lift subsets into plan tasks; do not run full script as Phase 8 gate; do not rewrite file.**

**Helpers pattern** (lines 10–18) — optional if plans want labeled output; otherwise plain `test` is enough (D-03):

```10:18:scripts/phase07-live-smoke.sh
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

FAIL=0
pass() { printf '[PASS] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
soft() { printf '[SOFT] %s\n' "$1"; }
```

**LIVE-01 core** (lines 22–47) — **copy into Phase 8 pre/post gates**:

```22:47:scripts/phase07-live-smoke.sh
if test ! -L "${HOME}/.config/quickshell" \
  && test -d "${HOME}/.config/quickshell" \
  && test -f "${HOME}/.config/quickshell/ii/shell.qml"; then
  pass "LIVE-01 real dir + ii/shell.qml"
else
  fail "LIVE-01 real dir + ii/shell.qml"
fi

case "$(readlink -f "${HOME}/.config/quickshell" 2>/dev/null || true)" in
  */.dotfiles/.config/quickshell*) fail "LIVE-01 path under .dotfiles product" ;;
  *) pass "LIVE-01 path not under .dotfiles product" ;;
esac

if test -d "${HOME}/.local/state/quickshell/.venv"; then
  pass "LIVE-01 ii Python venv"
else
  fail "LIVE-01 ii Python venv"
fi

if test -f "${HOME}/.config/hypr/hyprland.conf" \
  && test ! -e "${HOME}/.config/hypr/hyprland.conf.old"; then
  pass "LIVE-01 personal hypr conf present, no .old"
else
  fail "LIVE-01 personal hypr conf present, no .old"
fi
```

**D-04 block — DO NOT use as Phase 8 success criterion** (lines 49–53):

```49:53:scripts/phase07-live-smoke.sh
if test -d "${REPO_ROOT}/.config/quickshell"; then
  pass "D-04 in-repo .config/quickshell still present"
else
  fail "D-04 in-repo .config/quickshell still present"
fi
```

After RET-01 this intentionally fails. Plans must document that full `./scripts/phase07-live-smoke.sh` is **not** the gate.

**LIVE-02 hooks** (lines 77–88) — keep asserting repo hypr SoT:

```77:88:scripts/phase07-live-smoke.sh
if grep -E 'env = ILLOGICAL_IMPULSE_VIRTUAL_ENV,' .config/hypr/hyprland.conf >/dev/null; then
  pass "LIVE-02 repo env ILLOGICAL_IMPULSE_VIRTUAL_ENV"
else
  fail "LIVE-02 repo env ILLOGICAL_IMPULSE_VIRTUAL_ENV"
fi

if grep -E 'exec-once = qs -c ii' .config/hypr/hyprland.conf >/dev/null; then
  pass "LIVE-02 repo exec-once qs -c ii"
else
  fail "LIVE-02 repo exec-once qs -c ii"
fi
```

**SAFE_DEFAULTS dry-run check** (lines 55–75) — optional when reinstall branch taken:

```55:67:scripts/phase07-live-smoke.sh
bash -n ./arch/dots-hyprland.sh
pass "bash -n arch/dots-hyprland.sh"

DRY_OUT="$(mktemp)"
# shellcheck disable=SC2064
trap 'rm -f "$DRY_OUT"' EXIT
if printf 'yes\n' | ./arch/dots-hyprland.sh install --dry-run >"$DRY_OUT" 2>&1; then
  if grep -q -- '--core' "$DRY_OUT" \
    && grep -q -- '--skip-hyprland' "$DRY_OUT" \
    && grep -q -- '--skip-sysupdate' "$DRY_OUT" \
    && grep -qiE 'dry-run|would exec' "$DRY_OUT"; then
    pass "D-06 install --dry-run SAFE_DEFAULTS"
```

**Soft dual-run** (lines 96–107, 115–120) — optional soft checks, not formal LIVE-04 re-ceremony:

```96:107:scripts/phase07-live-smoke.sh
if pgrep -x waybar >/dev/null; then
  pass "LIVE-03 waybar process"
else
  fail "LIVE-03 waybar process"
fi

if grep -E 'exec-once = waybar' .config/hypr/hyprland.conf >/dev/null; then
  pass "LIVE-03 waybar exec-once preserved"
else
  fail "LIVE-03 waybar exec-once preserved"
fi
```

---

### Stale reference cleanup (minimal)

**Analog:** RESEARCH Pattern 3 classification table; spirit of `arch/waybar.sh` `STALE_MANAGED_*` (known dead surfaces removed deliberately) — **not** copy waybar install logic.

**Classification to apply:**

| Class | Action |
|-------|--------|
| `arch/quickshell.sh` file | `git rm` |
| Callers of `./arch/quickshell.sh` | None found in `arch/` / `scripts/` / `.config/` outside self |
| `arch/dots-hyprland.sh` L5 Pattern comment | Discretionary reword |
| `scripts/phase07-live-smoke.sh` D-04, phase04 asserts | **Leave** |
| `.planning/**` historical mentions | **Leave** (Phase 9) |
| `vendor/dots-hyprland/**` live XDG paths | **Leave** |
| Wrapper backup gate text mentioning `~/.config/quickshell` | **Keep** (live target) |

**Post-RET grep gate** (from RESEARCH Code Examples):

```bash
REPO_ROOT="$(git rev-parse --show-toplevel)"
# Fail if active (non-Pattern-comment) refs remain in code paths
if git -C "$REPO_ROOT" grep -n 'arch/quickshell\.sh' -- \
    'arch/' 'scripts/' '.config/' 2>/dev/null \
  | grep -v 'Pattern:' ; then
  echo "[FAIL] active reference to arch/quickshell.sh remains" >&2
  exit 1
fi
test ! -e "${REPO_ROOT}/arch/quickshell.sh"
test -x "${REPO_ROOT}/arch/dots-hyprland.sh"
```

**waybar stale-list spirit** (lines 47–70) — only as “explicit list of dead paths to remove”; Phase 8 list is just the two retirement surfaces, not a home-side cleanup:

```47:70:arch/waybar.sh
STALE_MANAGED_FILES=(
  "$WAYBAR_DST/scripts/network/ping.sh"
  ...
)
STALE_MANAGED_DIRS=(
  "$WAYBAR_DST/analysis"
  "$WAYBAR_DST/monitor"
)
```

Do **not** invent STALE arrays that `rm` under `$HOME/.config/quickshell`.

---

### `arch/*.sh` structure (context for discretionary comment only)

**Analog:** `arch/waybar.sh` / deleted `arch/quickshell.sh` share:

```bash
#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# PACKAGES=(...)  # quickshell.sh only — not for reinstall
# main dispatcher + [LABEL] echos
```

Wrapper already follows this without package arrays. No new arch script in Phase 8.

## Shared Patterns

### Delete-after-verify ordering
**Source:** `08-RESEARCH.md` Pattern 1; LIVE-01 in `scripts/phase07-live-smoke.sh` lines 22–34  
**Apply to:** All RET-01/RET-02 tasks  
**Rule:** Health green → tree `git rm` commit → installer `git rm` commit → ref cleanup → re-assert live independent of repo.

### Never touch live home as retirement
**Source:** CONTEXT D-14/D-15; `arch/quickshell.sh` anti-pattern lines 36–40  
**Apply to:** Every delete step  
**Rule:** Scope deletes to `REPO_ROOT`. Forbid `rm -rf ~/.config/quickshell` for RET. Forbid re-symlink live → repo.

### Reinstall only via wrapper
**Source:** `arch/dots-hyprland.sh` full file  
**Apply to:** Health-fail branch only  
**Rule:** `install` / `install-files` + SAFE_DEFAULTS; interactive backup gate; dry-run first; no `--force` / bare `--skip-backup`; never `arch/quickshell.sh`.

### No new smoke suite; lift asserts inline
**Source:** `scripts/phase07-live-smoke.sh` (subset); CONTEXT D-03/D-11  
**Apply to:** Plan task verifies  
**Rule:** Embed LIVE-01/02 + post-RET absence asserts in plans. Do not create `scripts/phase08-*`. Do not “fix” phase07 D-04.

### Atomic commits
**Source:** CONTEXT D-09  
**Apply to:** git ops  
**Rule:** Separate commits: (1) tree delete, (2) `arch/quickshell.sh` delete, (3) optional comment/ref cleanup.

### Label echo style (if any script touch)
**Source:** `arch/dots-hyprland.sh`, `arch/quickshell.sh`  
**Apply to:** Optional comment-only edit  
**Rule:** `[CONFIG]` / `[FAIL]` / `[INSTALL]` prefixes; `set -euo pipefail`; `REPO_ROOT` via `BASH_SOURCE`.

## No Analog Found

| File / Surface | Role | Data Flow | Reason |
|----------------|------|-----------|--------|
| Large in-repo `git rm -r .config/quickshell` automation | migration / delete | file-I/O | No historical phase script performs multi-hundred-file tree retirement; use RESEARCH + plain git |
| Deprecation stub for old installer | middleware | request-response | Explicitly rejected (D-04) — no pattern to copy |
| Phase 8 smoke harness | test | request-response | Forbidden (D-03); use inline asserts from phase07 subset |

## Metadata

**Analog search scope:** `arch/`, `scripts/`, `.config/hypr/`, repo-wide grep for `git rm` / `arch/quickshell.sh`  
**Files scanned:** `arch/dots-hyprland.sh`, `arch/quickshell.sh`, `arch/waybar.sh`, `scripts/phase07-live-smoke.sh`, grep hits across `arch/` `scripts/` `.config/`  
**Pattern extraction date:** 2026-07-27  
**Note:** No project-root `CLAUDE.md`; conventions from phase CONTEXT/RESEARCH + existing arch scripts.
