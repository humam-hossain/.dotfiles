# Phase 5: Fork & Submodule Pin - Research

**Researched:** 2026-07-25  
**Domain:** Git ownership model — personal fork + nested submodule pin (no install)  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Create the personal fork with **`gh repo fork`** of `end-4/dots-hyprland` (not manual browser-only, not agent-discretion).
- **D-02:** **Sibling clone is irrelevant.** Do not seed from, retarget, or depend on `~/github_repo/dots-hyprland`. Everything is **fresh** — fork on GitHub, then submodule from the fork URL.
- **D-03:** Fork is **public** (default open-source fork visibility).
- **D-04:** Remote URL style: **`origin` = SSH** (`git@github.com:humam-hossain/dots-hyprland.git`), **`upstream` = HTTPS** (`https://github.com/end-4/dots-hyprland.git`). Matches `.dotfiles` SSH origin; upstream is read-only pull.
- **D-05:** Register with **`git submodule add <fork-ssh-url> vendor/dots-hyprland`** from REPO_ROOT. Do **not** `mv` a directory into `vendor/`, do **not** submodule-add end-4 URL directly, do **not** “clone then convert” as primary path.
- **D-06:** Nested submodules always via **`--recursive`** (`git submodule update --init --recursive`). OWN-03 requires shapes present.
- **D-07:** Inside the submodule after setup: **`origin` → personal fork**, **`upstream` → end-4**. Submodule add sets origin; **add `upstream` explicitly**.
- **D-08:** **Commit pin only** in parent — no `branch = main` (or similar) in `.gitmodules` that implies auto-tracking. Pin bumps are explicit parent commits. (Auto-bump on every parent pull remains out of scope per REQUIREMENTS.)
- **D-09:** First parent pin = **fork default-branch tip at submodule-add time** (whatever HEAD is on the fork when added — normally matches end-4 tip right after fork).
- **D-10:** Do **not** force-fetch/reset to upstream tip if fork tip looks slightly behind; **trust fork tip as-is** for the initial pin.
- **D-11:** Parent records **`.gitmodules` + gitlink in the same commit** — never only one of the two.
- **D-12:** Phase 5 done only when **full OWN-01 / OWN-02 / OWN-03 checklist** passes:
  1. `git remote -v` inside vendored tree shows origin→fork, upstream→end-4
  2. Parent has `vendor/dots-hyprland` in `.gitmodules` with pinned SHA
  3. `git submodule update --init --recursive` yields complete tree including nested shapes path
- **D-13:** **Canonical local path** for all dots-hyprland work after pin: **`vendor/dots-hyprland` only**. Do not develop against a sibling path as source of truth.
- **D-14:** **`~/github_repo/dots-hyprland` is left alone** — Phase 5 does not delete or rewire it. Optional operator cleanup later.
- **D-15:** Fresh `.dotfiles` clones use stock git: **`git clone --recurse-submodules`** or clone then **`git submodule update --init --recursive`**. No Phase 5 bootstrap helper script (docs in Phase 9).
- **D-16:** **Pin only — no install.** No `./setup`, no wrapper skeleton, no session hooks in Phase 5.

### Claude's Discretion
- Exact `gh repo fork` flags (`--remote-name`, whether to clone into a temp path vs only submodule-add)
- Commit message wording for the parent pin commit (style should match repo norms)
- Exact verification command sequence / smoke script shape for OWN-01–03
- Whether to document the pinned short SHA in a comment or leave it only in gitlink
- Order of operations details as long as D-01–D-16 hold

### Deferred Ideas (OUT OF SCOPE)
- Thin setup wrapper `arch/dots-hyprland.sh` — Phase 6
- Safe defaults (`--core --skip-hyprland`), backup gate — Phase 6
- Install + session hooks + dual-run verify — Phase 7
- Retire local `.config/quickshell` + `arch/quickshell.sh` — Phase 8
- Full operator workflow docs (clone/install/update/pin-bump) — Phase 9
- Optional deletion of sibling `~/github_repo/dots-hyprland` — operator choice, not Phase 5
- Custom bootstrap script for submodules — not Phase 5 (stock git recurse; docs Phase 9)
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| OWN-01 | Operator has a personal GitHub fork of end-4/dots-hyprland with `origin` pointing at the fork and `upstream` pointing at `https://github.com/end-4/dots-hyprland.git` | `gh repo fork end-4/dots-hyprland --clone=false`; then inside `vendor/dots-hyprland` ensure origin SSH fork URL + explicit `git remote add upstream` HTTPS end-4 |
| OWN-02 | `.dotfiles` includes a git submodule at `vendor/dots-hyprland` whose URL targets the personal fork and whose commit SHA is pinned in the parent repo | `git submodule add git@github.com:humam-hossain/dots-hyprland.git vendor/dots-hyprland` (no `-b`); parent commit `.gitmodules` + mode-`160000` gitlink together |
| OWN-03 | Nested submodules inside dots-hyprland (including shapes / rounded-polygon) initialize successfully via recursive submodule update | After outer add: `git submodule update --init --recursive`; assert shapes path + `LICENSE`; status must not show `-` for shapes |
</phase_requirements>

## Summary

Phase 5 is pure **git ownership + pin surface** work. There is no application code, no package install, and no `./setup`. The machine today has **no** `.gitmodules`, **no** `vendor/`, and **no** personal fork `humam-hossain/dots-hyprland` yet. Tooling is ready: `gh` 2.96.0 authenticated as **humam-hossain**, SSH to GitHub works, git 2.55.0 is current. [VERIFIED: local machine state 2026-07-25]

Upstream `end-4/dots-hyprland` is public, default branch **`main`**, and carries **exactly one** nested submodule: shapes → `https://github.com/end-4/rounded-polygon-qmljs.git` at path `dots/.config/quickshell/ii/modules/common/widgets/shapes`. The parent only ever records the **outer** SHA; nested content appears only after `--recursive`. [VERIFIED: raw.githubusercontent.com/end-4/dots-hyprland/main/.gitmodules + sibling clone inspection]

**Primary recommendation:** Non-interactive fork with `gh repo fork end-4/dots-hyprland --clone=false`, then from REPO_ROOT `git submodule add git@github.com:humam-hossain/dots-hyprland.git vendor/dots-hyprland` (no `-b`), then `git submodule update --init --recursive`, then `git remote add upstream https://github.com/end-4/dots-hyprland.git` inside the vendored tree, then one parent commit of `.gitmodules` + gitlink only.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Create personal fork on GitHub | Git hosting (GitHub API via `gh`) | — | Ownership lives on the remote; no local app tier |
| Record submodule URL + pin | Parent git repo (`.dotfiles`) | — | Superproject owns `.gitmodules` + gitlink SHA |
| Checkout outer dots-hyprland tree | Local filesystem under `vendor/` | Git object store | Working tree materialization of the pin |
| Nested shapes/rounded-polygon | Submodule-of-submodule (inside vendor) | Parent only via recursive update | Nested pin is inside outer commit, not parent gitlink |
| Dual remotes origin/upstream | Local git config **inside** submodule | — | `upstream` is **not** stored in parent; re-add after fresh clones (docs Phase 9) |
| Install / session / wrapper | **Out of phase** | Later phases 6–7 | D-16 forbids install this phase |

## Standard Stack

### Core

| Tool | Version (verified) | Purpose | Why Standard |
|------|-------------------|---------|--------------|
| `gh` (GitHub CLI) | 2.96.0 (2026-07-02) | Create personal fork non-interactively | Official fork path per D-01; supports `--clone=false` to skip prompts [CITED: cli.github.com/manual/gh_repo_fork] |
| `git` | 2.55.0 | `submodule add` / `update --init --recursive` / commit pin | First-class submodule support; mode `160000` gitlink [CITED: git-scm.com/docs/git-submodule] |
| SSH (`git@github.com:…`) | OpenSSH; auth OK as humam-hossain | Parent + fork `origin` transport | Matches existing `.dotfiles` origin style (D-04) [VERIFIED: `ssh -T git@github.com`] |
| HTTPS | n/a | `upstream` remote to end-4 | Read-only pull remote; no write needed (D-04) |

### Supporting

| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| `gh repo view` / `gh api` | 2.96.0 | Confirm fork exists, isFork, parent | After fork; before submodule add |
| `git ls-tree` / `git submodule status --recursive` | 2.55.0 | Prove gitlink mode + nested status | OWN-02 / OWN-03 verification |
| `test -f …/shapes/LICENSE` | shell | Cheap nested-content presence check | OWN-03 gate (from project PITFALLS) [VERIFIED: sibling shapes LICENSE present] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `gh repo fork --clone=false` then submodule-add | `gh repo fork --clone` into temp then convert | Extra clone path; D-05 forbids clone-then-convert as primary |
| Submodule from fork SSH URL | Submodule from end-4 HTTPS | No personal push target — fails OWN-01/02 ownership model |
| Commit pin only (no `branch=`) | `git submodule add -b main` | Enables accidental `update --remote` drift; violates D-08 |
| Fresh fork+submodule | Retarget `~/github_repo/dots-hyprland` | Explicitly out of scope (D-02/D-14); Pitfall 4 |

**Installation:** None — no npm/pip/cargo packages. System tools only.

**Version verification:**
```bash
gh --version    # gh version 2.96.0 (2026-07-02)  [VERIFIED]
git --version   # git version 2.55.0                 [VERIFIED]
```

## Package Legitimacy Audit

> **No external packages are installed in this phase.** Stack is host `git` + `gh` only.

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| — | — | — | — | — | N/A | No packages |

**Packages removed due to [SLOP] verdict:** none  
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```text
[Operator / executor]
        |
        v
  gh repo fork end-4/dots-hyprland --clone=false
        |
        v
  GitHub: humam-hossain/dots-hyprland  (public fork, parent=end-4)
        |
        v
  REPO_ROOT (.dotfiles)
  git submodule add git@github.com:humam-hossain/dots-hyprland.git vendor/dots-hyprland
        |
        +-- writes .gitmodules  { path, url=fork SSH }   NO branch=
        +-- stages gitlink mode 160000 @ fork tip SHA
        |
        v
  git submodule update --init --recursive
        |
        +-- materializes vendor/dots-hyprland @ pinned SHA
        +-- materializes nested shapes @ outer-recorded nested SHA
        |     path: dots/.config/quickshell/ii/modules/common/widgets/shapes
        |     url:  https://github.com/end-4/rounded-polygon-qmljs.git
        |
        v
  inside vendor/dots-hyprland:
        origin  = git@github.com:humam-hossain/dots-hyprland.git   (from submodule add)
        upstream= https://github.com/end-4/dots-hyprland.git       (explicit remote add)
        |
        v
  Parent commit: .gitmodules + vendor/dots-hyprland gitlink (same commit)
        |
        v
  Success: OWN-01 + OWN-02 + OWN-03 green
  (NO ./setup, NO arch wrapper, NO session mutation)
```

### Recommended Project Structure (after phase)

```text
.dotfiles/
├── .gitmodules                          # NEW — outer submodule registry
├── vendor/
│   └── dots-hyprland/                   # NEW — gitlink checkout (canonical path)
│       ├── .gitmodules                  # nested: shapes → rounded-polygon-qmljs
│       ├── setup                        # present but NOT invoked (D-16)
│       └── dots/.config/quickshell/ii/modules/common/widgets/shapes/  # nested
└── (arch/, .config/, … unchanged this phase)
```

Expected `.gitmodules` shape (parent only — no `branch=` line):

```ini
[submodule "vendor/dots-hyprland"]
	path = vendor/dots-hyprland
	url = git@github.com:humam-hossain/dots-hyprland.git
```

[ASSUMED: exact spacing/tabs match whatever `git submodule add` emits on this git 2.55 — planner should accept stock output, not hand-edit.]

### Pattern 1: Non-interactive fork then submodule-add (no temp clone)

**What:** Create the GitHub fork without cloning; let `git submodule add` be the sole local materialization into `vendor/dots-hyprland`.  
**When to use:** Always for this phase (D-01, D-02, D-05).  
**Example:**
```bash
# Source: https://cli.github.com/manual/gh_repo_fork
# From ANY directory — MUST pass owner/repo (bare `gh repo fork` inside .dotfiles would fork .dotfiles)
gh repo fork end-4/dots-hyprland --clone=false

# Confirm
gh repo view humam-hossain/dots-hyprland --json name,isFork,url,parent

# Source: https://git-scm.com/docs/git-submodule + https://git-scm.com/book/en/v2/Git-Tools-Submodules
cd /home/pera/github_repo/.dotfiles   # REPO_ROOT
test ! -e vendor/dots-hyprland
git submodule add git@github.com:humam-hossain/dots-hyprland.git vendor/dots-hyprland
# Do NOT pass -b / --branch  (D-08)
```

### Pattern 2: Recursive nested init + dual remotes

**What:** Outer pin alone is insufficient; recurse for shapes; add `upstream` locally for OWN-01.  
**When to use:** Immediately after every successful outer add / fresh clone.  
**Example:**
```bash
# Source: git-scm book — "foolproof" recursive form
git submodule update --init --recursive

cd vendor/dots-hyprland
# origin already points at fork URL from submodule add
git remote add upstream https://github.com/end-4/dots-hyprland.git
# Idempotent guard for re-runs:
# git remote get-url upstream 2>/dev/null || git remote add upstream https://github.com/end-4/dots-hyprland.git
git remote -v
```

**Critical nuance:** `upstream` lives in the submodule’s **local** `.git/config` (actually under parent `.git/modules/…`). It is **not** committed to the parent and will be missing on a brand-new machine until re-added. Phase 5 must establish it on this machine for OWN-01; Phase 9 documents the re-add. [CITED: docs.github.com fork upstream remote setup] [VERIFIED: git submodule model]

### Pattern 3: Single parent pin commit (gitlink + .gitmodules)

**What:** One commit records both metadata files; never half-commit.  
**When to use:** End of phase (D-11).  
**Example:**
```bash
# Source: git-scm book — commit shows mode 160000 for submodule path
cd /home/pera/github_repo/.dotfiles
# Stage only pin artifacts (working tree may have unrelated dirty QML — do not include)
git add .gitmodules vendor/dots-hyprland
git diff --cached --submodule
git commit -m "chore: pin vendor/dots-hyprland submodule"
```

**Commit message recommendation (discretion):** Match recent repo style (`chore:`, `docs(…):`). Prefer:
`chore: pin vendor/dots-hyprland submodule`  
Optional body: short SHA of pin. Do **not** put SHA only in a free-floating comment file — gitlink is authoritative (discretion: leave SHA in gitlink only).

### Anti-Patterns to Avoid

- **`gh repo fork` with no args inside `.dotfiles`:** Forks the wrong repo (`.dotfiles` itself). Always pass `end-4/dots-hyprland`. [CITED: cli.github.com/manual/gh_repo_fork]
- **`git submodule add` of end-4 URL:** No personal push target; fails ownership model (Pitfall 4).
- **`mv ~/github_repo/dots-hyprland vendor/`:** No gitlink; fresh clones empty (Pitfall 4; D-02/D-05).
- **`git submodule add -b main`:** Writes `branch =` → auto-tracking temptation (D-08).
- **`git submodule update --init` without `--recursive`:** shapes empty; OWN-03 fails (Pitfall 5).
- **Running `./setup` or writing `arch/dots-hyprland.sh`:** Out of scope (D-16).
- **Committing unrelated dirty QML with the pin:** Parent is currently dirty on several `.config/quickshell/*` files — pin commit must be path-scoped. [VERIFIED: `git status`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Create GitHub fork | Manual browser multi-click / raw API scripts | `gh repo fork … --clone=false` | Official non-interactive path; auth already configured |
| Vendor third-party tree | Copy/rsync/tarball into `vendor/` | `git submodule add` | Needs URL + gitlink for reproducible clones |
| Nested dependency fetch | Custom recursive clone script | `git submodule update --init --recursive` | Stock git; D-15 forbids Phase 5 bootstrap helper |
| Pin tracking | Hand-maintained SHA file | Superproject gitlink (mode 160000) | Git-native; `git submodule status` reads it |
| Dual remote setup | Rewrite `.gitmodules` to invent upstream | `git remote add upstream` inside submodule | Upstream is local clone config, not superproject metadata |

**Key insight:** The hard parts of submodule ownership are already solved by git + gh. Custom conversion from the sibling clone is the main failure mode (Pitfall 4) — and is locked out by D-02.

## Common Pitfalls

### Pitfall 1: Sibling → fork conversion (avoid entirely)
**What goes wrong:** origin left as end-4; `mv` into vendor; no gitlink; unreproducible clones.  
**Why it happens:** “We already have `~/github_repo/dots-hyprland`.”  
**How to avoid:** D-02/D-14 — leave sibling alone; fresh fork + `submodule add` only.  
**Warning signs:** `vendor/dots-hyprland` is a normal dir without gitfile; `origin` still end-4.  
**Source:** `.planning/research/PITFALLS.md` Pitfall 4 [VERIFIED: sibling origin is still end-4 HTTPS]

### Pitfall 2: Nested shapes not initialized
**What goes wrong:** Outer tree present; `shapes/` empty; later QML import failures.  
**Why it happens:** Habit of `update --init` without `--recursive`.  
**How to avoid:** Always `--recursive`; assert `LICENSE` on shapes path.  
**Warning signs:** `git submodule status --recursive` shows `-` prefix on shapes.  
**Source:** PITFALLS Pitfall 5 + upstream `.gitmodules` [VERIFIED]

### Pitfall 3: Existing path / index blocks `submodule add`
**What goes wrong:** `git submodule add` errors if path exists or path already in index as normal tree.  
**Why it happens:** Partial prior attempts; accidental `mkdir vendor/dots-hyprland`.  
**How to avoid:** Preflight `test ! -e vendor/dots-hyprland`; if failed prior add, clean with `git submodule deinit`, `git rm`, remove `.git/modules/vendor/dots-hyprland` before retry. [CITED: git-scm book “Switching from subdirectories to submodules”]  
**Warning signs:** `'vendor/dots-hyprland' already exists in the index`

### Pitfall 4: Half-recorded pin
**What goes wrong:** Only `.gitmodules` committed, or only working tree present without gitlink — clones get empty vendor.  
**Why it happens:** Manual edits; forgetting to `git add` the gitlink path.  
**How to avoid:** D-11 — one commit; verify `git ls-tree HEAD vendor/dots-hyprland` shows `160000`. [CITED: git-scm book]  
**Warning signs:** Fresh clone leaves empty `vendor/dots-hyprland`

### Pitfall 5: `branch =` auto-tracking in `.gitmodules`
**What goes wrong:** Later `git submodule update --remote` silently moves pin without intentional parent commit.  
**Why it happens:** `git submodule add -b main` or `git submodule set-branch`.  
**How to avoid:** Never pass `-b` on add (D-08); grep `.gitmodules` for `branch`.  
**Warning signs:** `.gitmodules` contains `branch = main`

### Pitfall 6: Fork race / “repo not found” right after fork
**What goes wrong:** Immediate `submodule add` fails resolving fork URL.  
**Why it happens:** Brief GitHub eventual consistency after fork create.  
**How to avoid:** After fork, `gh repo view humam-hossain/dots-hyprland` until success; retry submodule add. [ASSUMED: rare; common operational knowledge]  
**Warning signs:** `ERROR: Repository not found` on first SSH clone of brand-new fork

### Pitfall 7: Dirty parent working tree pollutes pin commit
**What goes wrong:** Unrelated QML modifications land in the pin commit.  
**Why it happens:** Parent currently has modified files under `.config/quickshell/`. [VERIFIED: git status]  
**How to avoid:** `git add .gitmodules vendor/dots-hyprland` only; review `git diff --cached --stat` before commit.  
**Warning signs:** Cached diff includes `.qml` paths

### Pitfall 8: Assuming `upstream` survives fresh clones
**What goes wrong:** OWN-01 green on this machine; new clone only has `origin`.  
**Why it happens:** Remote config is local to submodule checkout.  
**How to avoid:** Phase 5 establishes upstream here; Phase 9 documents re-add; do not invent a Phase 5 bootstrap script (D-15).  
**Warning signs:** Fresh clone `git -C vendor/dots-hyprland remote` shows only origin

## Code Examples

### Canonical execution sequence (planner should follow this order)

```bash
# === 05-01 Fork ===
# Source: https://cli.github.com/manual/gh_repo_fork
gh repo fork end-4/dots-hyprland --clone=false
# If fork already exists, gh typically reports and exits successfully — treat as OK [ASSUMED: idempotent message text may vary by gh version]

gh repo view humam-hossain/dots-hyprland --json name,isFork,visibility,url,parent

# === 05-02 Submodule add + recursive ===
# Source: https://git-scm.com/docs/git-submodule
REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"
test ! -e vendor/dots-hyprland
git submodule add git@github.com:humam-hossain/dots-hyprland.git vendor/dots-hyprland
git submodule update --init --recursive

# Dual remotes (OWN-01) — Source: https://docs.github.com/.../fork-a-repo (upstream remote)
git -C vendor/dots-hyprland remote -v
git -C vendor/dots-hyprland remote get-url upstream 2>/dev/null \
  || git -C vendor/dots-hyprland remote add upstream https://github.com/end-4/dots-hyprland.git
# Ensure origin is SSH fork (submodule add should already set this)
git -C vendor/dots-hyprland remote set-url origin git@github.com:humam-hossain/dots-hyprland.git

# === 05-03 Verify + parent commit ===
# OWN-01
git -C vendor/dots-hyprland remote -v
# expect:
#   origin    git@github.com:humam-hossain/dots-hyprland.git (fetch/push)
#   upstream  https://github.com/end-4/dots-hyprland.git (fetch/push)

# OWN-02
grep -E 'branch\s*=' .gitmodules && exit 1 || true   # must be empty
git config -f .gitmodules --get submodule.vendor/dots-hyprland.url
# expect: git@github.com:humam-hossain/dots-hyprland.git
git submodule status
# expect: " <40-hex> vendor/dots-hyprland (...)"  — leading space = clean match to index

# OWN-03
SHAPES="vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/widgets/shapes"
test -f "$SHAPES/LICENSE"
git -C vendor/dots-hyprland submodule status --recursive
# shapes line must NOT start with '-'

# Parent pin commit (D-11) — path-scoped
git add .gitmodules vendor/dots-hyprland
git diff --cached --submodule
git diff --cached --stat   # only .gitmodules + vendor/dots-hyprland
git commit -m "chore: pin vendor/dots-hyprland submodule"

# Post-commit proof of gitlink
git ls-tree HEAD vendor/dots-hyprland
# expect: 160000 commit <sha>  vendor/dots-hyprland
```

### OWN verification smoke (discretion — recommended Wave 0 script shape)

No unit-test framework exists in this repo (see TESTING.md). Prefer a small bash assert script under e.g. `scripts/phase05-submodule-assert.sh` **or** inline plan verification commands. Either is fine; script is optional and is **not** a clone bootstrap helper (D-15 still holds).

```bash
#!/usr/bin/env bash
# Suggested verification-only smoke (not a clone bootstrap)
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
# no leading '-' on any recursive status line for uninitialized
! git -C "$SM" submodule status --recursive | grep -E '^-'

echo "[DONE] OWN-01/02/03 PASS"
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Hand-rolled local `.config/quickshell` product (v0.1) | Managed upstream via fork + submodule pin | v0.2 Phase 5 | Ownership moves to GitHub fork; pin in parent |
| Sibling clone at `~/github_repo/dots-hyprland` (origin=end-4) | Canonical `vendor/dots-hyprland` only | Phase 5 (D-13) | Sibling becomes irrelevant |
| Floating / unpinned checkout | Superproject gitlink SHA pin, no `branch=` | Phase 5 (D-08/D-09) | Reproducible clones; explicit pin bumps later |

**Deprecated/outdated for this phase:**
- Using sibling path as SoT after pin exists
- `git submodule update --remote` as default update (implies branch tracking)
- Reimplementing nested clone logic outside stock git

## Current Machine Preflight (research snapshot)

| Check | Result | Implication for plan |
|-------|--------|----------------------|
| `.gitmodules` | **Absent** | Greenfield add |
| `vendor/` | **Absent** | Path free for submodule add |
| `humam-hossain/dots-hyprland` | **Does not exist yet** | Must run `gh repo fork` first |
| `gh` auth | humam-hossain, protocol ssh, scopes include `repo` | Fork allowed |
| SSH GitHub | Authenticated | Submodule SSH URL works |
| Sibling clone | Exists; origin=end-4 HTTPS; shapes initialized | **Ignore** (D-02/D-14) |
| Parent dirty | Several unstaged QML mods + untracked noise | Path-scope pin commit |
| Parent branch | `main` ahead of `origin/main` by 9 commits | Local docs commits not pushed — unrelated to pin |
| `.gitignore` vendor | **Not ignored** | Submodule will be trackable |

[VERIFIED: local probes 2026-07-25]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Exact `.gitmodules` whitespace/key name matches stock `git submodule add` output | Architecture Patterns | Cosmetic only if planner over-specifies file content |
| A2 | `gh repo fork` when fork already exists is safe/idempotent enough to re-run | Code Examples | Re-run may need “ignore already exists” handling — plan should tolerate existing fork |
| A3 | Brief GitHub eventual-consistency delay after fork is possible | Pitfall 6 | May need one retry on submodule add |
| A4 | Public fork of public repo is the default (D-03) without extra visibility flag | Standard Stack | Extremely low risk; gh has no `--public` flag on fork in current help |

**If this table is empty:** N/A — four low-risk assumptions listed; none block planning.

## Open Questions

1. **Should Phase 5 add a committed verification script under `scripts/`?**
   - What we know: Repo has no general test framework; nvim has `scripts/nvim-validate.sh`; conventions use `[VERIFY]` labels.
   - What's unclear: User did not lock a script vs inline plan checks (discretion).
   - Recommendation: Prefer **inline verification commands in PLAN** for minimal surface; optional small assert script only if planner wants re-runnable gate. Do not frame it as clone bootstrap (D-15).

2. **Should parent pin commit be pushed to `origin` in this phase?**
   - What we know: Parent is already 9 commits ahead; push not required for local OWN checklist.
   - What's unclear: Whether executor should `git push` after pin.
   - Recommendation: Commit locally is required for D-11 proof via `git ls-tree HEAD`; **push is optional** unless operator wants remote backup — not required for OWN success criteria as written.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `gh` CLI | OWN-01 fork create | ✓ | 2.96.0 | — (blocking if missing) |
| `gh` auth (humam-hossain) | Fork API | ✓ | keyring token, `repo` scope | Re-auth `gh auth login` |
| `git` | Submodule add/update/commit | ✓ | 2.55.0 | — |
| SSH to `github.com` | Fork origin submodule URL | ✓ | auth as humam-hossain | — |
| Network (GitHub) | Fork + clone submodule + nested shapes | ✓ (assumed online) | — | Blocking offline |
| `vendor/dots-hyprland` free path | submodule add | ✓ (absent) | — | Clean failed partial add first |
| Disk for ~25k-line upstream tree | Checkout | ✓ | end-4 size ~24787 KB API | — |

**Missing dependencies with no fallback:** none detected  
**Missing dependencies with fallback:** none  

Step 2.6 complete — external tools present.

## Validation Architecture

> `workflow.nyquist_validation` is **true** in `.planning/config.json` — section required.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | **None** — no Bats/pytest/jest; repo uses shell orchestration asserts [VERIFIED: `.planning/codebase/TESTING.md`] |
| Config file | none |
| Quick run command | Inline OWN checks (see below) or optional `scripts/phase05-submodule-assert.sh` if added |
| Full suite command | Same as quick for this phase (git-state assertions only) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| OWN-01 | origin→fork SSH, upstream→end-4 HTTPS inside vendor | smoke / integration | `git -C vendor/dots-hyprland remote get-url origin`; `… upstream` | ❌ Wave 0 (commands in plan; optional script) |
| OWN-02 | `.gitmodules` url=fork; gitlink mode 160000; no `branch=` | smoke | `git config -f .gitmodules --get submodule.vendor/dots-hyprland.url`; `git ls-tree HEAD vendor/dots-hyprland`; `! grep branch .gitmodules` | ❌ Wave 0 |
| OWN-03 | Nested shapes present after recursive update | smoke | `git submodule update --init --recursive`; `test -f …/shapes/LICENSE`; recursive status no `-` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** Run the OWN checks affected by that task (01→remotes after fork+upstream; 02→gitmodules/gitlink; 03→shapes).
- **Per wave merge:** Full OWN-01+02+03 sequence.
- **Phase gate:** Full checklist green before `/gsd-verify-work`; **no** `./setup`, no session tests.

### Wave 0 Gaps

- [ ] No automated OWN assert harness yet — planner should either embed verification commands in each plan’s `## Verification` or add an optional `scripts/phase05-submodule-assert.sh` in Wave 0 of plan 05-03
- [ ] No framework install required
- [ ] Do **not** gate on nvim-validate or quickshell session health (out of phase)

*(Existing nvim harness is irrelevant to Phase 5.)*

## Security Domain

> `security_enforcement` enabled (ASVS level 1) in config.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | partial | Use existing `gh` auth + SSH keys; do not embed tokens in repo or scripts |
| V3 Session Management | no | No app sessions |
| V4 Access Control | partial | Fork is **public** (D-03) — intentional; no private secrets in vendor tree |
| V5 Input Validation | minimal | Only fixed URLs/paths from locked decisions; no free-form user URL input in automation |
| V6 Cryptography | no | No new crypto; transport via SSH/HTTPS stock git |

### Known Threat Patterns for git fork + submodule

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Submodule URL substitution (dependency confusion / malicious fork URL) | Spoofing / Tampering | Locked URL `git@github.com:humam-hossain/dots-hyprland.git`; verify `.gitmodules` after add |
| Committing secrets into vendor checkout | Information Disclosure | Phase does not edit vendor content; never copy machine secrets into submodule |
| Accidental run of upstream `./setup` as root | Elevation | D-16 forbids setup; do not execute `vendor/dots-hyprland/setup` |
| SSH key / token leakage in logs | Information Disclosure | Avoid `set -x` around auth; `gh` already configured via keyring |
| Nested submodule points at unexpected host | Tampering | Assert shapes URL remains `end-4/rounded-polygon-qmljs` from upstream `.gitmodules` after recursive init |

## Sources

### Primary (HIGH confidence)

- Local machine probes: no `.gitmodules`/`vendor/`; gh auth; SSH; fork missing; sibling remotes/shapes — 2026-07-25
- `https://raw.githubusercontent.com/end-4/dots-hyprland/main/.gitmodules` — nested shapes entry only
- `https://cli.github.com/manual/gh_repo_fork` — `--clone=false` non-interactive fork
- `https://git-scm.com/docs/git-submodule` — add/update/status/`--recursive`; `-b` writes branch tracking
- `https://git-scm.com/book/en/v2/Git-Tools-Submodules` — gitlink mode 160000; clone recurse; recursive update
- `https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/fork-a-repo` — upstream remote pattern
- `.planning/research/PITFALLS.md` — Pitfalls 4 & 5 (sibling conversion; nested shapes)
- `.planning/phases/05-fork-submodule-pin/05-CONTEXT.md` — locked D-01…D-16
- `.planning/codebase/TESTING.md` — no unit-test framework
- `.planning/config.json` — nyquist_validation true; security_enforcement true

### Secondary (MEDIUM confidence)

- Web research synthesis on pin-without-branch and nested submodule practices (cross-checked against official git docs)
- `gh api repos/end-4/dots-hyprland` — size/default_branch/pushed_at

### Tertiary (LOW confidence)

- Exact idempotent stdout text when re-forking an existing repo (A2)
- GitHub fork propagation latency (A3)

## Metadata

**Confidence breakdown:**
- Standard stack: **HIGH** — tools verified installed; official docs for gh/git
- Architecture: **HIGH** — locked decisions + verified empty vendor + verified upstream `.gitmodules`
- Pitfalls: **HIGH** — project PITFALLS + official submodule caveats + live dirty-tree observation

**Research date:** 2026-07-25  
**Valid until:** 2026-08-25 (30 days — git/gh mechanics stable; recheck only if gh major version or upstream nested layout changes)
