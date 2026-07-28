# Phase 8: Retire Local Quickshell Product - Research

**Researched:** 2026-07-27
**Domain:** Dotfiles product retirement — git tree deletion, old installer removal, live-install path protection
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Priority is a **working dots-hyprland install**, not historical product preservation. Live product is `~/.config/quickshell` from upstream install (Phase 7), not the in-repo tree.
- **D-02:** If the installed tree is corrupted, incomplete, or otherwise broken, **reinstall via** `arch/dots-hyprland.sh` (existing Phase 6 wrapper + safe defaults + backup gate). Do not re-run or resurrect `arch/quickshell.sh`.
- **D-03:** **No new smoke-test suite** this phase. Do not add `scripts/phase08-*-smoke.sh`, do not invert Phase 7 D-04 into a retirement gate, do not retarget phase0x assert scripts. Verification is practical: live ii install works (or was reinstalled); old materials are gone from the repo.
- **D-04:** **Hard delete** `arch/quickshell.sh` (`git rm`). No deprecation stub.
- **D-05:** **No package work** this phase — do not uninstall quickshell/ddcutil/i2c/material packages; do not move package ownership into a new script. Future deps come from dots-hyprland `./setup` via the wrapper.
- **D-06:** User considers the old script unimportant — delete it; do not mount a docs campaign. Phase 9 can clean operator narrative.
- **D-07:** Remove the entire in-repo product tree with **`git rm -r .config/quickshell`** (full delete; ~933 tracked files). Nothing under that path is salvaged into the repo.
- **D-08:** Uncommitted WIP under the tree (e.g. ToolbarTabBar/AiChat/Anime.qml) is **not important** — discard with the tree; do not commit WIP first.
- **D-09:** **Tree delete is its own commit** (atomic). Separate commits for `arch/quickshell.sh` removal and any small reference cleanups.
- **D-10:** **No annotated recovery tag** required before delete; git history is enough.
- **D-11:** After delete, clean only what would **block** or **re-teach** the old path as current (e.g. comments that instruct running `arch/quickshell.sh` as the installer). Do not rewrite v0.1 phase assert scripts (`scripts/phase04-*.py`, frozen `scripts/phase07-live-smoke.sh` D-04 expectation, etc.).
- **D-12:** Historical scripts may fail if re-run post-delete — that is acceptable. Phase 8 does not maintain them.
- **D-13:** `arch/dots-hyprland.sh` remains the **only** Arch install entry for the shell product. Pattern comments that mention quickshell.sh as a style ancestor may stay or be lightly reworded; do not reintroduce a second installer.
- **D-14:** Prefer: (1) ensure live dots-hyprland install is healthy / reinstall if needed, (2) delete in-repo tree, (3) delete `arch/quickshell.sh`, (4) minimal ref cleanup. Never use delete of the live `~/.config/quickshell` as the retirement action — only the **in-repo** tree.
- **D-15:** Do **not** re-symlink live config into the repo. LIVE-01 remains: real directory under home from upstream install.

### Claude's Discretion
- Exact reinstall command sequence if needed (dry-run then `install`, respect Phase 6 backup gate)
- Whether to touch `arch/dots-hyprland.sh` comment header that cites quickshell.sh as pattern source
- Commit message wording (atomic commits per D-09)
- How thoroughly to grep non-planning paths for stale installer mentions (minimum: nothing still *calls* deleted script as required step)

### Deferred Ideas (OUT OF SCOPE)
- Full clone/install/update operator playbook — Phase 9 (DOC-01, DOC-02)
- Updating or archiving historical phase0x assert/smoke scripts for post-retirement reality — optional polish, not Phase 8
- Deprecation stub for `arch/quickshell.sh` — explicitly rejected
- Package uninstall / ddcutil cleanup — not this phase
- Waybar/rofi/swaync cutover — later milestone
- Custom module ports into ii — later milestone
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| RET-01 | After LIVE-04 is satisfied, the in-repo v0.1 `.config/quickshell` product tree is removed from `.dotfiles` so it is no longer shipped | Safe `git rm -r .config/quickshell` after live-path health gate; live home tree untouched; atomic tree-delete commit (D-07/D-09/D-14) |
| RET-02 | `arch/quickshell.sh` is retired (removed or reduced to a deprecation stub that points at the new wrapper) so it is not a second installer | Hard `git rm arch/quickshell.sh` (D-04); only remaining code caller is none — sole non-self ref is a style comment in `arch/dots-hyprland.sh` |
</phase_requirements>

## Summary

Phase 8 is a **repo-side retirement**, not a new product build. Phase 7 already moved the live shell to a real installed tree at `~/.config/quickshell` (with `ii/shell.qml`) and personal hypr hooks (`env = ILLOGICAL_IMPULSE_VIRTUAL_ENV,…` + `exec-once = qs -c ii`). The remaining risk is **order-of-operations**: deleting the in-repo product is safe only while the live path is a real directory independent of the repo; re-running the old installer would undo that.

Research confirms: (1) live install path is already a real directory with `ii/` layout matching vendor install SoT; (2) the only non-planning **code** reference to `arch/quickshell.sh` outside itself is a one-line pattern comment in `arch/dots-hyprland.sh`; (3) historical scripts (`phase07-live-smoke.sh` D-04, `phase04-ipc-reload-assert.py`) hardcode the in-repo tree and **must be left alone** per D-11/D-12 — they will fail post-delete and that is acceptable; (4) no stow, no package uninstall, no new smoke suite.

**Primary recommendation:** Gate on practical live-path health (inline asserts, not a new script) → `git rm -r .config/quickshell` as its own commit (discard untracked WIP) → `git rm arch/quickshell.sh` as its own commit → optional one-line comment reword on `arch/dots-hyprland.sh` → re-assert live path still real/not-under-repo.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Live ii shell runtime | Host session (`~/.config/quickshell`, `qs -c ii`) | Hyprland conf hooks | Product already installed on host; Phase 8 must not retarget it |
| In-repo product shipping | Git working tree / index | — | RET-01 is pure repo content removal |
| Old installer surface | `arch/quickshell.sh` (delete) | — | RET-02 hard delete removes second install path |
| Reinstall / repair | `arch/dots-hyprland.sh` → vendor `./setup` | Operator interactive backup gate | Only approved repair path (D-02/D-13) |
| Personal session hooks | `.config/hypr/hyprland.conf` (repo SoT) + live mirror | — | Do not strip hooks during retirement |
| Vendor pin SoT | `vendor/dots-hyprland` submodule | — | Untouched; source of reinstall files |
| Historical phase asserts | `scripts/phase0x*` (leave broken) | — | Out of maintenance this phase (D-11/D-12) |

## Standard Stack

### Core

| Tool / Surface | Version / Pin | Purpose | Why Standard |
|----------------|---------------|---------|--------------|
| `git rm -r` / `git rm` | system git | Stage deletions of tracked product tree + installer | Atomic, history-preserving removal [VERIFIED: codebase + CONTEXT D-07/D-04] |
| `arch/dots-hyprland.sh` | Phase 6 as shipped | Reinstall / repair only if live install unhealthy | WRAP-01..04; SAFE_DEFAULTS + backup gate [VERIFIED: `arch/dots-hyprland.sh`] |
| `vendor/dots-hyprland/./setup` | submodule pin | Upstream install SoT for reinstall | Never reimplement package lists [VERIFIED: Phase 5–7] |
| Bash inline asserts | system bash | Practical health + post-delete gates without new scripts | D-03 forbids new smoke suite [VERIFIED: CONTEXT] |

### Supporting

| Tool | Purpose | When to Use |
|------|---------|-------------|
| `printf 'yes\n' \| ./arch/dots-hyprland.sh install --dry-run` | Prove SAFE_DEFAULTS argv before live reinstall | Only if reinstall needed |
| `pkill -x qs` (optional) | Free file handles before reinstall-files | If reinstalling live tree mid-session |
| `git clean` / plain `rm` for untracked under tree | Discard untracked WIP after/with `git rm` | If untracked files remain under `.config/quickshell` (D-08) |
| `hyprctl reload` + env-prefixed `qs -c ii -d` | Mid-session re-verify after reinstall | Only if reinstall touched live tree |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Hard delete `arch/quickshell.sh` | Deprecation stub | Rejected (D-04) — stub is a second surface |
| `git rm -r` tree | Annotated tag then delete | Rejected (D-10) — history sufficient |
| Inline practical asserts | New `phase08-*-smoke.sh` | Rejected (D-03) |
| Leave packages alone | Uninstall ddcutil/quickshell packages | Rejected (D-05) |
| Repair via `arch/quickshell.sh` | Would re-symlink into deleted/missing repo path | Forbidden — undoes LIVE-01 |

**Installation:** None — Phase 8 installs **no** external packages.

**Version verification:** N/A (no registry packages). Tools are stock git + bash + existing wrapper.

## Package Legitimacy Audit

> Phase installs **zero** external packages (D-05). No Package Legitimacy Gate required.

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| — | — | — | — | — | N/A | No installs |

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```text
                    ┌─────────────────────────────────────┐
                    │  Operator / Executor (Phase 8)       │
                    └──────────────┬──────────────────────┘
                                   │
           (1) health gate         │         (2)(3)(4) git ops only
                   │               │               │
                   ▼               │               ▼
    ┌──────────────────────────┐   │   ┌──────────────────────────────┐
    │ LIVE host state          │   │   │ REPO (.dotfiles)              │
    │ ~/.config/quickshell/    │   │   │ .config/quickshell/  ──git rm─▶ GONE
    │   ii/shell.qml  (real)   │   │   │ arch/quickshell.sh   ──git rm─▶ GONE
    │ ~/.local/state/…/.venv   │   │   │ arch/dots-hyprland.sh  KEEP   │
    │ hypr: env + qs -c ii     │   │   │ vendor/dots-hyprland/  KEEP   │
    │ qs process → live path   │   │   │ .config/hypr hooks     KEEP   │
    └──────────▲───────────────┘   │   └──────────────────────────────┘
               │                   │
               │ if unhealthy      │
               │                   ▼
               │         ┌─────────────────────────────┐
               └─────────┤ arch/dots-hyprland.sh       │
                         │  install | install-files    │
                         │  SAFE_DEFAULTS + backup gate│
                         │  → vendor/./setup           │
                         └─────────────────────────────┘

NEVER: arch/quickshell.sh  (would rm -rf live + ln -s repo)
NEVER: rm live ~/.config/quickshell as "retirement"
NEVER: re-symlink live → repo
```

### Recommended Project Structure (post-phase)

```text
.dotfiles/
├── arch/
│   ├── dots-hyprland.sh     # ONLY Arch shell-product install entry
│   └── …                    # other app scripts; quickshell.sh GONE
├── .config/
│   ├── hypr/hyprland.conf   # KEEP: env + exec-once = qs -c ii
│   ├── waybar/ …            # dual-run preserved
│   └── (no quickshell/)     # product tree removed
├── vendor/dots-hyprland/    # KEEP submodule pin
└── scripts/
    ├── phase07-live-smoke.sh          # historical; D-04 will fail — leave
    └── phase04-ipc-reload-assert.py   # historical; leave
```

### Pattern 1: Delete-after-verify (mandatory order)

**What:** Confirm live install is independent of repo, then delete repo product only.
**When to use:** Always for RET-01/RET-02 (D-14; Pitfall 2 / Pitfall 8 from research).
**Example:**

```bash
# Source: Phase 7 LIVE-01 asserts + 08-CONTEXT D-14 (practical, not a new script)
# 1) Health (must pass before any git rm of product tree)
test ! -L "${HOME}/.config/quickshell"
test -d "${HOME}/.config/quickshell"
test -f "${HOME}/.config/quickshell/ii/shell.qml"
case "$(readlink -f "${HOME}/.config/quickshell")" in
  */.dotfiles/.config/quickshell*) echo "FAIL: still under repo"; exit 1 ;;
esac
test -d "${HOME}/.local/state/quickshell/.venv"

# 2) Tree delete (repo only) — own commit
git rm -r .config/quickshell
# If untracked remnants remain under path (D-08):
#   rm -rf .config/quickshell   # only under REPO_ROOT, never $HOME
git commit -m "chore(08): remove in-repo v0.1 .config/quickshell product tree"

# 3) Installer delete — separate commit
git rm arch/quickshell.sh
git commit -m "chore(08): remove arch/quickshell.sh old product installer"

# 4) Post: live path still healthy; repo product absent
test ! -e "$(git rev-parse --show-toplevel)/.config/quickshell"
test -f "${HOME}/.config/quickshell/ii/shell.qml"
```

### Pattern 2: Reinstall via wrapper only (if health fails)

**What:** Repair live install with Phase 6 wrapper; never resurrect old installer.
**When to use:** Live tree missing/corrupt/symlinked; or qs cannot load `ii`.
**Example:**

```bash
# Source: arch/dots-hyprland.sh + Phase 6/7 CONTEXT
REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

# Optional mid-session: stop qs so rsync is not fighting a live reader
pkill -x qs 2>/dev/null || true

# Dry-run first (D-06 Phase 7 habit; wrapper-owned --dry-run)
printf 'yes\n' | ./arch/dots-hyprland.sh install --dry-run
# Expect argv: ./setup install --core --skip-hyprland --skip-sysupdate

# Live reinstall (operator types exact yes at backup gate)
./arch/dots-hyprland.sh install
# Or files-only if deps already good:
# ./arch/dots-hyprland.sh install-files

# Re-assert LIVE-01 shape
test ! -L "${HOME}/.config/quickshell" && test -f "${HOME}/.config/quickshell/ii/shell.qml"
```

### Pattern 3: Minimal reference cleanup classification

**What:** Grep non-planning code; fix only paths that still *instruct or call* the old installer as current.
**When to use:** After deletes (D-11).

| Class | Examples | Action |
|-------|----------|--------|
| **Must remove** | `arch/quickshell.sh` file | `git rm` (RET-02) |
| **Must not call** | Any script invoking `./arch/quickshell.sh` | None found in non-planning code [VERIFIED: repo grep] |
| **Discretionary reword** | `arch/dots-hyprland.sh` L5: `Pattern: arch/quickshell.sh` | Optional light reword (e.g. cite `arch/waybar.sh` / generic arch style) — does not re-teach installer |
| **Leave historical** | `scripts/phase07-live-smoke.sh` D-04 in-repo present assert; `scripts/phase04-ipc-reload-assert.py` QML paths | Leave (D-11/D-12) — expected fail if re-run |
| **Leave planning history** | `.planning/**` Phase 5–7 docs mentioning old path | Leave — Phase 9 narrative, not Phase 8 |
| **Leave vendor** | `vendor/dots-hyprland/**` refs to `~/.config/quickshell` | Leave — those mean **live** XDG path, correct |
| **Keep messaging** | Wrapper backup gate text about overwriting `~/.config/quickshell` | Keep — describes live install target |

### Anti-Patterns to Avoid

- **Deleting live `~/.config/quickshell` as retirement:** That is the product; only delete **in-repo** `.config/quickshell`.
- **Running `arch/quickshell.sh` after tree delete:** `rm -rf "$QS_DST"; ln -s "$QS_SRC" "$QS_DST"` recreates symlink to missing/empty repo path — session death.
- **Using full `./scripts/phase07-live-smoke.sh` as Phase 8 gate:** D-04 assert requires in-repo tree present — will fail after RET-01 by design; do not “fix” the smoke script this phase (D-03/D-11).
- **One mega-commit for tree + script + docs:** Violates D-09 atomicity.
- **Package uninstall “cleanup”:** Out of scope (D-05); ddcutil presence ≠ enable polling.
- **Re-symlink live into repo “for convenience”:** Violates D-15 / LIVE-01.
- **Salvaging QML into repo before delete:** User rejected (D-07/D-08).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Reinstall ii | New pacman arrays / manual rsync of vendor dots | `arch/dots-hyprland.sh` → `./setup` | WRAP-01; upstream owns listfile/backup/rsync |
| Retirement verification suite | `scripts/phase08-*-smoke.sh` | Inline bash asserts in plan tasks | D-03 |
| Deprecation stub installer | `arch/quickshell.sh` that exits 1 with message | Hard `git rm` | D-04 |
| Rollback automation | Restore scripts from tarball | git history + wrapper reinstall | D-10; Phase 7 D-08 style |
| Historical assert modernization | Rewrite phase04/07 scripts | Leave broken | D-11/D-12 |
| Operator docs rewrite | Full README playbook | Phase 9 DOC-01/02 | Deferred |

**Key insight:** Phase 8 complexity is **safety ordering and surface classification**, not new engineering. The dangerous tool is still the old installer; deleting it is the mitigation (Pitfall 10).

## Runtime State Inventory

> Retirement/delete phase — runtime state must be checked explicitly.

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | Live `~/.config/quickshell/` real dir with `ii/` tree (installed Phase 7); `~/.local/state/quickshell/.venv` present (`pyvenv.cfg` readable); `~/.local/state/quickshell/user/` state; optional `~/ii-original-dots-backup` from Phase 7 | **Do not delete.** Reinstall via wrapper only if unhealthy. Code edit N/A for live data. |
| Live service config | Hyprland live conf has `env = ILLOGICAL_IMPULSE_VIRTUAL_ENV,~/.local/state/quickshell/.venv` and `exec-once = qs -c ii`; waybar dual-run line preserved; qs loads **live** `ii` config (`-c ii` → `~/.config/quickshell/ii/`), not repo path | **Keep.** No session cutover this phase. |
| OS-registered state | No repo-named systemd unit for the v0.1 product; `hyprland-session.service` is unrelated session bootstrap | **None** for product retirement. Do not touch systemd units. |
| Secrets/env vars | No SOPS/CI secrets keyed on `.config/quickshell` or `arch/quickshell.sh`. Session env is hypr `env =` line (path string only). | **None** — key names unchanged. |
| Build artifacts | `scripts/__pycache__/` for historical phase asserts (unrelated); in-repo tree may have untracked WIP under `.config/quickshell` | Discard untracked under **repo** tree with delete (D-08). Do not clean live home. |

**Nothing found that requires data migration of renamed keys.** After every file in the repo is updated, the live session continues from host paths already independent of the repo product (Phase 7 LIVE-01).

**Verified live shape (research session, Read/list tools):**
- `~/.config/quickshell/ii/shell.qml` exists (installed layout) [VERIFIED: filesystem]
- `~/.local/state/quickshell/.venv/pyvenv.cfg` exists (uv CPython 3.12) [VERIFIED: filesystem]
- Live + repo hypr conf both contain `qs -c ii` and `ILLOGICAL_IMPULSE_VIRTUAL_ENV` [VERIFIED: grep]
- In-repo `.config/quickshell/` still present with full product tree (to be deleted) [VERIFIED: list_dir]
- Structural difference: in-repo has root `shell.qml`; live installed has `ii/shell.qml` — session already uses installed layout [VERIFIED: filesystem]

**Note:** `.planning/codebase/CONCERNS.md` “empty quickshell tree” is **stale** relative to current working tree (full tree present). Do not plan around that outdated concern.

## Common Pitfalls

### Pitfall 1: Delete repo product while live path still symlinks to it

**What goes wrong:** Session loses config; or tools follow symlink and damage unexpected paths.
**Why it happens:** v0.1 model was `ln -s` repo → live (`arch/quickshell.sh` `symlink_config`).
**How to avoid:** Pre-delete hard gate: `test ! -L ~/.config/quickshell` and `readlink -f` not under `*/.dotfiles/.config/quickshell`. Phase 7 already broke the symlink; re-check every execution.
**Warning signs:** `test -L ~/.config/quickshell`; qs missing `shell.qml`.

### Pitfall 2: Treating live home delete as RET-01

**What goes wrong:** Wipes the only running product; forces emergency reinstall.
**Why it happens:** Path name collision (`.config/quickshell` in repo vs home).
**How to avoid:** All delete commands scoped to `REPO_ROOT`; never `rm -rf ~/.config/quickshell` for retirement (D-14).
**Warning signs:** Plans that `rm` `$HOME/.config/quickshell` without “reinstall only” context.

### Pitfall 3: Re-running `arch/quickshell.sh` “to fix” things mid-phase

**What goes wrong:** `rm -rf` live real dir + symlink back to repo (possibly mid-delete) — undoes LIVE-01 and can destroy installed tree.
**Why it happens:** Muscle memory; script still present until RET-02 commit.
**How to avoid:** Order D-14: health → tree delete → **then** delete script; never execute script; plans forbid it explicitly (same as Phase 7 T-7-06).
**Warning signs:** `test -L` becomes true again.

### Pitfall 4: Using phase07-live-smoke as Phase 8 success gate

**What goes wrong:** Smoke fails on D-04 (“in-repo still present”) after successful RET-01 → false failure / temptation to “fix” historical script.
**Why it happens:** Smoke freezes Phase 7 D-04.
**How to avoid:** D-03/D-11 — practical subset of LIVE-01/02 asserts **without** D-04; leave smoke file unchanged.
**Warning signs:** Plan tasks that require `./scripts/phase07-live-smoke.sh` exit 0 after tree delete.

### Pitfall 5: `git rm -r` leaves untracked WIP behind

**What goes wrong:** Directory partially remains with untracked experiments; repo still “ships” residue; dirty tree confuses later commits.
**Why it happens:** `git rm` only removes **tracked** files.
**How to avoid:** After `git rm -r`, assert path gone or only untracked leftovers; `rm -rf "$REPO_ROOT/.config/quickshell"` for remnants (repo only); D-08 discard WIP without committing first.
**Warning signs:** `test -d .config/quickshell` still true after commit; `git status` shows untracked under that path.

### Pitfall 6: Reinstall without backup gate / with `--skip-backup`

**What goes wrong:** Overwrites live configs without `~/ii-original-dots-backup`.
**Why it happens:** Operator impatience on re-run.
**How to avoid:** Wrapper refuses bare `--skip-backup`; plans must not pass `--allow-skip-backup` for routine repair unless operator explicitly overrides.
**Warning signs:** Empty/missing backup dir after files step when clashing paths existed.

### Pitfall 7: Broad doc rewrite scope creep

**What goes wrong:** Phase 8 becomes Phase 9; delays RET commits.
**Why it happens:** INTEGRATIONS.md / STRUCTURE.md / CONCERNS still describe symlink model.
**How to avoid:** D-06/D-11 — code path only; planning/codebase map docs can wait for Phase 9 or incidental touch; not blocking RET.

### Pitfall 8: Assuming stow/link farms still manage QS

**What goes wrong:** Extra “unlink stow” steps that do not exist.
**Why it happens:** Generic dotfiles folklore.
**How to avoid:** This repo has **no stow** usage [VERIFIED: repo grep]. Delivery was explicit `arch/quickshell.sh` symlink or upstream rsync only.

## Code Examples

### Live install health (practical gate — no new script)

```bash
# Source: scripts/phase07-live-smoke.sh LIVE-01/02 blocks, minus D-04 in-repo assert
# (D-03: do not invent phase08 smoke; D-11: do not rewrite phase07 smoke)

set -euo pipefail
REPO_ROOT="$(git rev-parse --show-toplevel)"

# LIVE-01 shape (must hold before and after retirement)
test ! -L "${HOME}/.config/quickshell"
test -d "${HOME}/.config/quickshell"
test -f "${HOME}/.config/quickshell/ii/shell.qml"
case "$(readlink -f "${HOME}/.config/quickshell")" in
  */.dotfiles/.config/quickshell*)
    echo "[FAIL] live path resolves under repo product" >&2
    exit 1
    ;;
esac
test -d "${HOME}/.local/state/quickshell/.venv"
test -f "${HOME}/.config/hypr/hyprland.conf"
test ! -e "${HOME}/.config/hypr/hyprland.conf.old"

# LIVE-02 hooks still present (repo SoT)
grep -E 'env = ILLOGICAL_IMPULSE_VIRTUAL_ENV,' \
  "${REPO_ROOT}/.config/hypr/hyprland.conf" >/dev/null
grep -E 'exec-once = qs -c ii' \
  "${REPO_ROOT}/.config/hypr/hyprland.conf" >/dev/null

# Optional if Hyprland session currently running:
# pgrep -a qs | grep -E -- '-c ii|\bii\b'
# pgrep -x waybar

echo "[PASS] live install health"
```

### Post-RET asserts (invert shipping checks)

```bash
# Source: RET-01 / RET-02 success criteria
REPO_ROOT="$(git rev-parse --show-toplevel)"

# Product no longer shipped
test ! -e "${REPO_ROOT}/.config/quickshell"
# Old installer gone (no stub)
test ! -e "${REPO_ROOT}/arch/quickshell.sh"
# Only install entry remains
test -x "${REPO_ROOT}/arch/dots-hyprland.sh"
# Live still independent
test ! -L "${HOME}/.config/quickshell"
test -f "${HOME}/.config/quickshell/ii/shell.qml"

# Grep gate: no non-planning *caller* of deleted installer
# (comment mentions may remain until discretionary cleanup)
if git -C "$REPO_ROOT" grep -n 'arch/quickshell\.sh' -- \
    'arch/' 'scripts/' '.config/' ':!.planning/**' 2>/dev/null \
  | grep -v 'Pattern:' ; then
  echo "[FAIL] active reference to arch/quickshell.sh remains" >&2
  exit 1
fi

echo "[PASS] retirement surfaces clean"
```

### Safe tree removal with untracked discard

```bash
# Source: git documentation patterns + D-07/D-08
REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

# Precondition: live health already green
git rm -r .config/quickshell

# Untracked leftovers (WIP never added): remove from disk under REPO only
if [[ -e .config/quickshell ]]; then
  rm -rf .config/quickshell
fi

test ! -e .config/quickshell
git commit -m "chore(08): remove in-repo v0.1 .config/quickshell product tree (RET-01)"
```

### Old installer anti-pattern (do not execute)

```bash
# Source: arch/quickshell.sh symlink_config — ANTI-PATTERN
# rm -rf "$HOME/.config/quickshell"
# ln -s "$REPO_ROOT/.config/quickshell" "$HOME/.config/quickshell"
# After RET-01 this points at a missing tree. Never run.
```

## State of the Art

| Old Approach (v0.1) | Current Approach (v0.2 post-Phase 7/8) | When Changed | Impact |
|---------------------|----------------------------------------|--------------|--------|
| Ship QML under `.config/quickshell` in git | Live install from `vendor/dots-hyprland` via setup | Phase 7 install; Phase 8 delete | Single product path |
| `arch/quickshell.sh` symlink deploy | `arch/dots-hyprland.sh` → `./setup` | Phase 6–8 | No second installer |
| `qs` default config at repo `shell.qml` | `qs -c ii` → `~/.config/quickshell/ii` | Phase 7 hooks | Config name `ii` |
| Dual product confusion (repo + live) | Repo does not ship QS product | Phase 8 | RET-01/02 |

**Deprecated/outdated:**
- Directory-symlink delivery of Quickshell from `.dotfiles` — retired
- `arch/quickshell.sh` as install entry — hard deleted this phase
- Phase 7 smoke D-04 “in-repo still present” — historical only after RET-01
- `.planning/codebase/CONCERNS.md` empty-tree warning — stale pre-Phase-7 map

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Approximate tracked file count ~933 under `.config/quickshell` (from CONTEXT scout) | Summary / D-07 | Commit size surprise only — use `git rm -r` regardless of count |
| A2 | No active qs process dependency on **repo** path after Phase 7 (session uses live `ii`) | Runtime State | If somehow still loading repo path, delete would break session — health gate + `qs -c ii` process check mitigates |
| A3 | Untracked WIP under tree is discardable without enumerating every file | Pitfall 5 / D-08 | User already locked discard; residual risk is only local uncommitted work loss (accepted) |
| A4 | `arch/README.md` does not currently document `quickshell.sh` as a step (grep empty) | Ref classification | If missed in another doc path, Phase 9 still owns narrative |

**If this table is empty:** N/A — small assumption set; none block planning if health gate is mandatory.

## Open Questions (RESOLVED)

1. **Is live qs currently running at execution time?**
   - What we know: Phase 7 left dual-run verified; research confirmed files on disk.
   - What's unclear: process table at the moment of Phase 8 execution (session may have restarted).
   - Recommendation: optional `pgrep` soft check during health gate; not a hard blocker if files + hooks are healthy (D-03 — no formal LIVE-04 re-ceremony).
   - RESOLVED: soft optional `pgrep` during health (08-01 Task 1 step 6); not a hard gate if files + hooks are healthy.

2. **Discretionary comment reword on `arch/dots-hyprland.sh` L5?**
   - What we know: only non-self code mention of `arch/quickshell.sh` in `arch/` + `scripts/` + `.config/`.
   - What's unclear: whether operator wants zero residual string vs harmless ancestry comment.
   - Recommendation: Prefer light reword in the same commit as script deletion or tiny follow-up commit (D-09 allows separate cleanup commit) — e.g. “Pattern: arch/*.sh REPO_ROOT + main dispatcher + [LABEL] echos.”
   - RESOLVED: prefer light Pattern reword on `arch/dots-hyprland.sh` L5 as a separate D-09 cleanup commit (08-03 Task 2).

3. **Reinstall needed or not?**
   - What we know: filesystem evidence shows healthy live tree + venv + hooks.
   - What's unclear: runtime chrome at execution moment.
   - Recommendation: Plans start with health gate; branch to reinstall tasks only on failure (do not force reinstall if green).
   - RESOLVED: health gate first (08-01 Task 1); reinstall branch only on failure (08-01 Task 2).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `git` | `git rm`, commits | ✓ (repo is git project) | system | — |
| `bash` | wrapper + inline asserts | ✓ | system | — |
| `arch/dots-hyprland.sh` | reinstall path | ✓ | Phase 6 shipped | — |
| `vendor/dots-hyprland` submodule | reinstall SoT | ✓ (`.gitmodules` present) | pin in parent | `git submodule update --init --recursive` |
| `qs` on PATH | optional process check / mid-session restart | ✓ expected (Phase 7 installed `illogical-impulse-quickshell-git`) | host | reinstall via wrapper |
| Live `~/.config/quickshell/ii` | health gate | ✓ (research Read) | host | `./arch/dots-hyprland.sh install` or `install-files` |
| `~/.local/state/quickshell/.venv` | ii python tools | ✓ (`pyvenv.cfg`) | uv 0.9.25 / CPython 3.12 | reinstall setups via wrapper |
| New npm/pip packages | — | N/A | — | not used |
| stow | — | ✗ not used in repo | — | N/A |

**Missing dependencies with no fallback:** none identified for happy path.

**Missing dependencies with fallback:** unhealthy live tree → wrapper reinstall (interactive).

**Step 2.6 note:** External runtime deps already provisioned in Phase 7; Phase 8 primarily needs git + existing wrapper.

## Validation Architecture

> `workflow.nyquist_validation` is **true** in `.planning/config.json`. Dimension 8 must be practical **without** a new smoke suite (D-03).

### Test Framework

| Property | Value |
|----------|-------|
| Framework | None — **inline bash asserts in plan task `<automated>` blocks** (no new `scripts/phase08-*`) |
| Config file | none |
| Quick run command | Inline health subset (see Code Examples) — copy into plan verifies |
| Full suite command | Health subset + post-RET absence asserts + optional `pgrep` dual-run soft checks |
| Estimated runtime | &lt; 5s for asserts; reinstall path minutes–tens of minutes if triggered |

**Explicit non-gates:**
- `./scripts/phase07-live-smoke.sh` — **not** Phase 8 gate (D-04 will fail post-RET-01)
- `scripts/phase04-ipc-reload-assert.py` / phase02/03 asserts — **not** maintained
- No pytest/jest/bats

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| RET-01 pre | Live path real dir + `ii/shell.qml` not under repo | smoke (inline) | `test ! -L && -d && -f ii/shell.qml`; `readlink -f` case | ❌ Wave 0 not needed — commands only |
| RET-01 pre | venv present | smoke (inline) | `test -d ~/.local/state/quickshell/.venv` | inline |
| RET-01 pre | hypr hooks present | smoke (inline) | `grep` env + `qs -c ii` in repo conf | inline |
| RET-01 post | In-repo tree absent | smoke (inline) | `test ! -e "$REPO_ROOT/.config/quickshell"` | inline |
| RET-02 post | `arch/quickshell.sh` absent | smoke (inline) | `test ! -e "$REPO_ROOT/arch/quickshell.sh"` | inline |
| RET-02 post | Wrapper remains only entry | smoke (inline) | `test -x arch/dots-hyprland.sh`; allowlist still works `--dry-run` optional | existing wrapper |
| LIVE-01 hold | After deletes, live still real/not symlink | smoke (inline) | same LIVE-01 path asserts | inline |
| LIVE-03 soft | waybar still configured/running | smoke (inline, soft if no session) | `grep exec-once = waybar`; optional `pgrep -x waybar` | inline |
| Neg | Must not reintroduce symlink installer call | grep | `git grep arch/quickshell.sh` on arch/scripts/config excluding harmless Pattern comment | inline |

### Sampling Rate

- **Per task commit:** Run the asserts that task just made true (e.g. after tree commit → path absent + live still healthy)
- **Per wave merge:** Full post-RET set (tree gone, script gone, live healthy)
- **Phase gate:** All RET automated asserts green; no requirement for formal LIVE-04 chrome re-UAT (D-03)
- **Max feedback latency:** &lt; 5s for pure asserts

### Wave 0 Gaps

- [ ] **None for new test files** — D-03 forbids new smoke scripts
- [ ] Framework install: none
- [ ] Planner must embed inline verify commands in each plan task (not reference a missing phase08 script)
- [ ] Planner must **document** that `phase07-live-smoke.sh` is expected red on D-04 after RET-01 so executors do not thrash

*(If no gaps: existing bash + filesystem tools cover all phase requirements without new harness files.)*

### Recommended plan-shaped verify blocks

| Plan sketch | Verify focus |
|-------------|--------------|
| 08-01 health | LIVE-01/02 inline; branch to reinstall only on fail |
| 08-02 tree delete | `git rm -r`; path absent; live untouched; own commit |
| 08-03 script + refs | `git rm arch/quickshell.sh`; grep classification; live still healthy |

## Security Domain

> `security_enforcement` enabled (ASVS L1). Phase is destructive to **repo** content only; host product must remain intact.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | partial | Fixed paths only; no new user input parsers; wrapper already validates allowlist/flags |
| V6 Cryptography | no | — |
| V1 Architecture / path integrity | yes | Order gate: never delete live; never re-symlink; hard-delete zombie installer |

### Known Threat Patterns for this phase

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Delete live home tree by path confusion | Tampering / DoS | REPO_ROOT-scoped `git rm` only; explicit forbid `$HOME` delete for RET |
| Re-run `arch/quickshell.sh` → symlink regression | Tampering | Hard delete installer (RET-02); plans forbid execution while it still exists |
| rsync/reinstall through accidental symlink | Tampering | Pre-reinstall `test ! -L`; Phase 7 lesson |
| Accidental `--skip-backup` on repair install | Tampering / info loss | Wrapper refuse without `--allow-skip-backup`; do not encourage |
| Command injection via freestyle flags | Tampering | Reuse Phase 6 array-exec wrapper only; no `eval` |
| Package/script supply chain | — | No new packages this phase |

### Phase 8 threat sketch (for planner SECURITY.md)

| Threat ID | Severity | Disposition |
|-----------|----------|-------------|
| T-8-01 Live path deleted as “retirement” | high | mitigate — D-14 + verify live exists after |
| T-8-02 Old installer re-run / left callable | high | mitigate — D-04 hard delete + grep |
| T-8-03 Symlink regression | high | mitigate — health asserts before/after |
| T-8-04 Scope creep rewriting historical tests hides real RET failures | medium | accept/mitigate — D-03/D-11 leave historical; use dedicated asserts |
| T-8-05 Interactive reinstall without backup | high | mitigate — existing wrapper gate |

## Project Constraints (from CLAUDE.md)

No project-root `CLAUDE.md` / `AGENTS.md` / `.claude/CLAUDE.md` found at research time. Constraints come from `.planning` docs + `08-CONTEXT.md` locked decisions (treated as authoritative).

Relevant carry-forward project constraints from PROJECT.md / REQUIREMENTS:
- Upstream `./setup` is install SoT; thin wrapper only
- Primary target Arch
- No ddcutil polling investment
- Keep hyprlock; dual-run Waybar until later cutover
- Do not continue hand-rolled local QS as primary product

## Sources

### Primary (HIGH confidence)
- `.planning/phases/08-retire-local-quickshell-product/08-CONTEXT.md` — locked D-01…D-15
- `.planning/REQUIREMENTS.md` — RET-01, RET-02; LIVE-01…04 complete
- `.planning/ROADMAP.md` — Phase 8 success criteria
- `arch/quickshell.sh` — symlink anti-pattern (`rm -rf` + `ln -s`)
- `arch/dots-hyprland.sh` — reinstall entry, SAFE_DEFAULTS, backup gate, sole Pattern comment ref
- `scripts/phase07-live-smoke.sh` — LIVE asserts + D-04 historical in-repo check
- `.planning/research/PITFALLS.md` — Pitfall 2 (symlink/delete order), 8 (delete-before-verify), 10 (zombie installer)
- `.planning/phases/07-*/07-VERIFICATION.md`, `07-SECURITY.md`, `07-VALIDATION.md` — live install proven
- Filesystem: `~/.config/quickshell/ii/shell.qml`, `~/.local/state/quickshell/.venv/pyvenv.cfg`, hypr hooks

### Secondary (MEDIUM confidence)
- `.planning/codebase/INTEGRATIONS.md` / `STRUCTURE.md` / `TESTING.md` — describe old symlink model (stale for post-Phase-8 reality; useful for ref classification)
- `.planning/codebase/CONCERNS.md` — **stale** empty-tree claim; noted for planner to ignore
- Phase 6/7 CONTEXT — reinstall constraints

### Tertiary (LOW confidence)
- Exact untracked WIP file enumeration at execution time (D-08: discard all — no need to list)
- Whether qs process is running at future execution moment (A2)

## Metadata

**Confidence breakdown:**
- Standard stack: **HIGH** — no new libraries; git + existing wrapper only
- Architecture: **HIGH** — Phase 7 established live path; retirement order locked in CONTEXT + pitfalls research
- Pitfalls: **HIGH** — documented in PITFALLS.md and proven by Phase 7 anti-patterns
- Reference classification: **HIGH** for non-planning code grep; **MEDIUM** for how much `.planning/**` text to touch (deferred to Phase 9 by D-06)

**Research date:** 2026-07-27
**Valid until:** 2026-08-27 (stable domain — git ops + local paths; re-check live health at execution)
