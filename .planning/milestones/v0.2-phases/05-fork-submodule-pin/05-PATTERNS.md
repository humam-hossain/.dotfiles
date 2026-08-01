# Phase 5: Fork & Submodule Pin - Pattern Map

**Mapped:** 2026-07-25  
**Files analyzed:** 5 (artifacts / paths; 1 optional script)  
**Analogs found:** 3 / 5 (no in-repo submodule or `vendor/` yet)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| GitHub: `humam-hossain/dots-hyprland` (fork) | remote/config | request-response (gh API) | `scripts/clone_repo.sh` (`gh repo …`) | partial — gh CLI only |
| `.gitmodules` | config | file-I/O (git-managed) | *none* — greenfield; stock `git submodule add` output | no analog |
| `vendor/dots-hyprland` (gitlink + tree) | config / third-party pin | file-I/O + nested clone | *none* in-repo; upstream nested shapes is external | no analog |
| Parent pin commit (`.gitmodules` + gitlink) | config (git history) | batch (path-scoped `git add` + commit) | Recent `chore:` / `docs(…):` commits on `main` | role-match (message style) |
| `scripts/phase05-submodule-assert.sh` (optional) | utility / test | request-response (smoke asserts) | `scripts/phase02-config-assert.py` + `scripts/nvim-validate.sh` | role-match |

**Explicitly not created this phase (deferred):** `arch/dots-hyprland.sh`, clone bootstrap helpers, any `./setup` invocation.

## Pattern Assignments

### GitHub fork `humam-hossain/dots-hyprland` (remote, request-response)

**Analog:** `scripts/clone_repo.sh` — only in-repo consumer of `gh` for repo operations.

**Imports / tooling pattern** (lines 1–5 of clone script):
```bash
#!/bin/bash

echo "Fetching repository list from GitHub..."
# Fetch the list once and store it in a variable
REPOS=$(gh repo list --limit 1000 --json nameWithOwner,name --jq '.[] | "\(.nameWithOwner) \(.name)"')
```

**Core pattern to copy (gh, not clone loop):** Prefer official `gh` over browser/API scripts; non-interactive flags; always pass **owner/repo** so bare `gh repo fork` inside `.dotfiles` cannot fork the wrong repo.

**Phase-5 canonical sequence** (from RESEARCH — no in-repo excerpt):
```bash
gh repo fork end-4/dots-hyprland --clone=false
gh repo view humam-hossain/dots-hyprland --json name,isFork,visibility,url,parent
```

**Auth pattern:** Use existing `gh` auth (humam-hossain, SSH protocol preference) — do not embed tokens. Parent origin already proves SSH style:

```text
origin  git@github.com:humam-hossain/.dotfiles.git (fetch/push)
```

**Error handling:** Treat “fork already exists” as OK (idempotent re-run); wait on `gh repo view` if submodule SSH clone hits “Repository not found” (fork propagation).

---

### `.gitmodules` (config, file-I/O)

**Analog:** **None** in `.dotfiles` (research verified: no `.gitmodules`, no `vendor/`).

**Do not hand-roll.** Let `git submodule add` emit the file. Expected shape after stock git 2.55 add (**no `branch=`**):

```ini
[submodule "vendor/dots-hyprland"]
	path = vendor/dots-hyprland
	url = git@github.com:humam-hossain/dots-hyprland.git
```

**Anti-pattern (from D-08 / research):** Never `git submodule add -b main` or `git submodule set-branch` — that writes `branch =` and enables accidental `update --remote` drift.

**Validation pattern:**
```bash
test -f .gitmodules
git config -f .gitmodules --get submodule.vendor/dots-hyprland.url
# expect: git@github.com:humam-hossain/dots-hyprland.git
! grep -E '^\s*branch\s*=' .gitmodules
```

---

### `vendor/dots-hyprland` (submodule pin, file-I/O + nested)

**Analog:** **None** in parent repo. Nested layout is **upstream’s** responsibility; parent only records outer SHA.

**Core add pattern** (stock git — sole materialization path per D-05):
```bash
REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"
test ! -e vendor/dots-hyprland
git submodule add git@github.com:humam-hossain/dots-hyprland.git vendor/dots-hyprland
# Do NOT pass -b / --branch
git submodule update --init --recursive
```

**Dual-remote pattern inside submodule** (OWN-01; local config, not committed to parent):
```bash
git -C vendor/dots-hyprland remote set-url origin git@github.com:humam-hossain/dots-hyprland.git
git -C vendor/dots-hyprland remote get-url upstream 2>/dev/null \
  || git -C vendor/dots-hyprland remote add upstream https://github.com/end-4/dots-hyprland.git
git -C vendor/dots-hyprland remote -v
```

**Nested OWN-03 path** (assert content, do not reimplement nested clone):
```text
vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/widgets/shapes/LICENSE
```

**Preflight / recovery** (failed partial add):
```bash
# if path blocked:
# git submodule deinit -f vendor/dots-hyprland
# git rm -f vendor/dots-hyprland
# rm -rf .git/modules/vendor/dots-hyprland
```

**Out of band:** Leave `~/github_repo/dots-hyprland` untouched (D-02/D-14). Do not `mv` into `vendor/`.

---

### Parent pin commit (config / history, batch)

**Analog:** Recent parent commit message style on `main` (verified log):

| Style | Examples |
|-------|----------|
| `docs(…):` | `docs(phase-5): add validation strategy`, `docs(05): research phase domain` |
| `chore:` | `chore: remove REQUIREMENTS.md for v0.1 milestone`, `chore: archive v0.1 milestone files` |

**Recommended message (discretion + RESEARCH):**
```text
chore: pin vendor/dots-hyprland submodule
```

**Core path-scoped commit pattern** (critical: parent has dirty QML — do not `git add -A`):
```bash
git add .gitmodules vendor/dots-hyprland
git diff --cached --submodule
git diff --cached --stat   # only .gitmodules + vendor/dots-hyprland
git commit -m "chore: pin vendor/dots-hyprland submodule"
```

**Post-commit proof (OWN-02 / D-11):**
```bash
git ls-tree HEAD vendor/dots-hyprland
# expect: 160000 commit <sha>	vendor/dots-hyprland
```

**Push:** Optional; local `HEAD` gitlink is enough for OWN checklist. Parent may already be ahead of `origin/main`.

---

### `scripts/phase05-submodule-assert.sh` (optional utility/test, smoke)

**Analog A (phase Wave-0 assert naming):** `scripts/phase02-config-assert.py`, `scripts/phase03-config-assert.py`, `scripts/phase04-ipc-reload-assert.py`

**Docstring / phase gate pattern** (lines 1–8 of phase02):
```python
#!/usr/bin/env python3
"""Phase 2 Wave 0 live-config asserts for BAR-01..04 keys.

Reads ~/.config/illogical-impulse/config.json and asserts Phase 2 decisions
(D-01..D-03, D-05, D-13, D-14, D-16). Stdlib only. Exit 0 only when all pass.

Expected to FAIL until plan 02-02 dual-writes Config defaults into live config.
"""
```

**Naming convention to copy:** `scripts/phase0N-<topic>-assert.*` — for Phase 5 prefer bash because asserts are pure git/shell (`phase05-submodule-assert.sh`).

**Analog B (bash harness structure):** `scripts/nvim-validate.sh` lines 1–24

```bash
#!/usr/bin/env bash
# =============================================================================
# nvim-validate.sh — Headless Neovim validation harness
# ...
# =============================================================================

set -euo pipefail

# --- Repo and report dir resolution ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
```

**Echo vocabulary** (from `.planning/codebase/CONVENTIONS.md` + `arch/wakatime.sh`):
```bash
echo "[VERIFY] wakatime setup"
```
Labels in use: `[INSTALL]`, `[CONFIG]`, `[COPY]`, `[VERIFY]`, `[DONE]`, `[SKIP]`.

**Suggested Phase 5 smoke body** (from RESEARCH — align labels with conventions):
```bash
#!/usr/bin/env bash
# phase05-submodule-assert.sh — OWN-01/02/03 verification only (not clone bootstrap)
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"
SM=vendor/dots-hyprland
SHAPES="$SM/dots/.config/quickshell/ii/modules/common/widgets/shapes"

echo "[VERIFY] OWN-01 remotes"
git -C "$SM" remote get-url origin | grep -q 'humam-hossain/dots-hyprland'
git -C "$SM" remote get-url upstream | grep -q 'end-4/dots-hyprland'

echo "[VERIFY] OWN-02 .gitmodules + gitlink"
test -f .gitmodules
git config -f .gitmodules --get submodule.vendor/dots-hyprland.url | grep -q 'humam-hossain/dots-hyprland'
! grep -E '^\s*branch\s*=' .gitmodules
git ls-tree HEAD "$SM" | grep -q '^160000'

echo "[VERIFY] OWN-03 nested shapes"
git submodule update --init --recursive
test -f "$SHAPES/LICENSE"
! git -C "$SM" submodule status --recursive | grep -E '^-'

echo "[DONE] OWN-01/02/03 PASS"
```

**Planner note:** RESEARCH prefers **inline plan Verification** over a committed script to minimize surface (D-15 forbids framing this as clone bootstrap). If added, it is re-runnable gate only.

---

## Shared Patterns

### SSH origin remote style
**Source:** live `git remote -v` on parent  
**Apply to:** Fork `origin` URL + `.gitmodules` `url`  
```text
git@github.com:humam-hossain/<repo>.git
```
Mirror for dots-hyprland: `git@github.com:humam-hossain/dots-hyprland.git`.

### Bash strict mode + labeled output
**Source:** `.planning/codebase/CONVENTIONS.md` (lines 7–22), `arch/*.sh`  
**Apply to:** Optional assert script only  
```bash
#!/usr/bin/env bash
set -euo pipefail
# Prefer [VERIFY]/[DONE] over set -x for verification (avoid auth noise)
```

### REPO_ROOT resolution
**Source:** `scripts/nvim-validate.sh` lines 22–23; structured `arch/` scripts  
**Apply to:** Any script run from `scripts/`  
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
```
For one-off plan commands, prefer `git rev-parse --show-toplevel`.

### Phase Wave-0 assert scripts
**Source:** `scripts/phase02-config-assert.py` … `phase04-ipc-reload-assert.py`  
**Apply to:** Optional OWN harness  
- Name: `phase0N-*-assert.*`  
- Exit 0 only when all gates pass  
- Stdlib / stock tools only (no new test framework)  
- Document expected fail-until-green in header if useful  

### No unit-test framework
**Source:** `.planning/codebase/TESTING.md`  
**Apply to:** All Phase 5 verification  
- Smoke/integration shell asserts only  
- No Bats/pytest/jest install  
- nvim-validate is **out of phase** — do not gate OWN on it  

### Commit message conventional prefixes
**Source:** `git log` on parent  
**Apply to:** Pin commit  
- Prefer `chore:` for structural pin  
- Planning docs use `docs(05):` / `docs(phase-5):` — keep pin commit separate from docs noise  

### Path-scoped staging under dirty trees
**Source:** RESEARCH machine preflight + D-11  
**Apply to:** Parent pin commit  
```bash
git add .gitmodules vendor/dots-hyprland   # never git add -A for pin
git diff --cached --stat                   # reject if .qml appears
```

### Security (ASVS-light)
**Source:** RESEARCH Security Domain  
**Apply to:** All executor steps  
- Fixed URLs only (locked D-04/D-05)  
- No tokens in scripts/logs  
- Do not run `vendor/dots-hyprland/setup` (D-16)  
- After recursive init, shapes nested URL should remain end-4/rounded-polygon-qmljs  

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `.gitmodules` | config | file-I/O | Repo has never used git submodules; accept stock `git submodule add` output |
| `vendor/dots-hyprland` | third-party pin | nested clone | No `vendor/` tree; sibling `~/github_repo/dots-hyprland` is **out of band** (D-02) — not a pattern to copy |
| Nested shapes submodule | nested pin | recursive update | Lives inside outer commit; parent does not re-declare it |

Planner should use **05-RESEARCH.md** Code Examples + git-scm / gh docs for these, not invent hand-maintained SHA files or tarball vendors.

## Metadata

**Analog search scope:**  
- Repo root (`.gitmodules`, `vendor/`)  
- `scripts/` (gh, validate, phase asserts)  
- `arch/` (bash conventions, `[VERIFY]`)  
- `.planning/codebase/{CONVENTIONS,TESTING,STRUCTURE}.md`  
- `git log` / `git remote -v`  

**Files scanned:** ~15 scripts + 3 codebase docs + live git state  
**Pattern extraction date:** 2026-07-25  
**Strong matches used:** 3 (`clone_repo.sh`/`gh`, phase assert scripts, commit/`chore` + CONVENTIONS) — stopped per 3–5 analog rule  
