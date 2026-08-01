# Phase 9: Workflow Documentation & Update Contract - Research

**Researched:** 2026-07-29
**Domain:** Operator documentation / install-update contract for fork+submodule dots-hyprland adoption
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

No Phase 9 CONTEXT.md — operator chose continue without discuss-phase. All phase-local doc layout decisions are at planner/executor discretion, **except** locked product contracts inherited from PROJECT.md, REQUIREMENTS.md, and Phases 5–8 CONTEXT files (must not be reopened).

### Locked Decisions (inherited — NON-NEGOTIABLE)

**From REQUIREMENTS DOC-01 / DOC-02 + ROADMAP success criteria:**
- Docs must describe **clone → recursive submodule init → wrapper install → personal hypr hooks → dual-run expectations** end-to-end (DOC-01).
- Docs must describe **pin-bump update**: fetch/merge upstream in fork/submodule, bump parent pin, re-run setup — and state that **`exp-merge` / online cache install are non-primary** (DOC-02).
- A clean read of docs must be enough to reach a dual-run `qs -c ii` session without chat history.

**From Phase 5 (OWN):**
- Canonical path is **only** `vendor/dots-hyprland` (no sibling SoT).
- `origin` = personal fork SSH; `upstream` = end-4 HTTPS.
- Parent pin is explicit (no `branch =` auto-track in `.gitmodules`).
- Fresh clones: `git clone --recurse-submodules` or `git submodule update --init --recursive`.

**From Phase 6 (WRAP):**
- Sole Arch install entry: **`arch/dots-hyprland.sh`**.
- Allowlist: `install|install-deps|install-setups|install-files|uninstall|protect` (wrapper later grew safe uninstall/protect; still **refuses** `exp-merge` / `exp-update`).
- Safe defaults on `install` / `install-files`: `--core --skip-hyprland --skip-sysupdate`.
- Hard backup gate; never teach bare `--skip-backup` on first adoption.
- Never auto-inject `--force`. Preflight points at recursive submodule fix; never auto-init.

**From Phase 7 (LIVE):**
- Live product is **real directory** `~/.config/quickshell` (not symlink into repo).
- Personal hypr hooks: `env = ILLOGICAL_IMPULSE_VIRTUAL_ENV,~/.local/state/quickshell/.venv` + `exec-once = qs -c ii`.
- Dual-run: Waybar remains; both bars OK even if they overlap. No cutover this milestone.

**From Phase 8 (RET):**
- In-repo `.config/quickshell` **gone**; `arch/quickshell.sh` **hard-deleted** — docs must not re-teach either as current install path.
- Reinstall/repair only via `arch/dots-hyprland.sh`.
- Historical `scripts/phase0x*` may be stale — not the operator playbook.

### Claude's Discretion
- Exact doc file path(s) and section headings
- Whether playbook is one file vs split install/update
- How deeply to document uninstall/protect (wrapper has them; DOC-01/02 do not require full uninstall playbook)
- Cross-link placement in README / PROJECT / REQUIREMENTS

### Deferred Ideas (OUT OF SCOPE)
- Waybar custom module ports / full cutover (CUST-*, later)
- Full hyprland.lua session takeover
- Making `exp-merge` / `exp-update` primary
- Online curl-to-`~/.cache/dots-hyprland` as managed path
- Auto-bump submodule on every parent pull
- Wrapper `verify` subcommand (POLISH-01)
- New smoke test harness for docs (prefer grep/assert of doc content)
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DOC-01 | Documentation describes clone → submodule init (recursive) → wrapper install → personal hypr hooks → dual-run expectations | Map real commands from Phases 5–7 + current wrapper help/hooks |
| DOC-02 | Documentation describes update contract: fetch/merge upstream in fork/submodule, bump parent pin, re-run setup — and states `exp-merge` / online cache install are non-primary | Pin-bump sequence + explicit non-goals section from REQUIREMENTS Out of Scope + STACK.md |
</phase_requirements>

## Summary

Phase 9 is **documentation only**. Phases 5–8 already shipped the product path: personal fork + `vendor/dots-hyprland` pin, thin `arch/dots-hyprland.sh` wrapper (safe defaults, backup gate, allowlist, optional safe uninstall/protect, post-install hypr hook enable), live real-dir install, dual-run hooks, retirement of the in-repo Quickshell product and old installer.

**Doc gap today:**
- Root `README.md` only covers Neovim/Tmux — **zero** dots-hyprland workflow.
- `arch/README.md` is Arch OS bootstrap (bootloader, useradd) — **not** the ii adopt path.
- Wrapper `--help` is excellent operational reference but is not a clone→pin-bump playbook and is easy to miss from a cold clone.
- PROJECT.md still has open checkbox: “Document `.dotfiles` workflow for fork/submodule/install/update”.
- Live machine may have hooks **commented out** after `uninstall` (observed: live hypr conf lines disabled by wrapper). Docs must describe how to **reach** dual-run again, not assume the operator’s current session is already dual-running.

**Primary recommendation:** Add one canonical operator playbook (suggested path: `docs/dots-hyprland-workflow.md`) with Install/Adopt + Update/Pin-bump + Non-goals, written in the same procedural bash-block style as `arch/README.md` / labeled `[INSTALL]` vocabulary of `arch/*.sh`. Link it from root `README.md` and close the PROJECT checklist. Do not resurrect `arch/quickshell.sh` narrative as a current path.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Operator playbook (DOC-01/02) | Repo docs (`docs/` + README pointers) | Wrapper `--help` as CLI SoT for flags | Cold-clone discoverability lives in markdown; flag details stay DRY via pointer to `./arch/dots-hyprland.sh help` |
| Clone + recursive submodule | Git / parent repo | `.gitmodules` | OWN-02/03; Phase 5 D-15 |
| Install / reinstall | `arch/dots-hyprland.sh` → vendor `./setup` | Interactive backup gate | WRAP + LIVE |
| Session hooks / dual-run | Personal `.config/hypr/hyprland.conf` (+ live mirror) | Wrapper `enable_hypr_ii_hooks` after install | LIVE-02; wrapper now injects on successful install |
| Pin-bump updates | Fork remotes + parent gitlink commit | Re-run wrapper install/files | DOC-02; no auto-bump |
| Non-primary paths | Docs “Non-goals” section only | Upstream `./setup` direct for exp-* | REQUIREMENTS out of scope |
| Retired product | Absent paths | Historical scripts | RET-01/02 — docs must not re-teach |

Single-tier for this phase: **documentation surfaces only** — no runtime code changes required for DOC-01/02 (optional tiny README/PROJECT edits only).

## Standard Stack

### Core

| Surface | Version / pin | Purpose | Why Standard |
|---------|---------------|---------|--------------|
| Markdown playbook | repo docs | Cold-start operator contract | DOC-01/02 need durable prose beyond CLI help [VERIFIED: README gap] |
| `arch/dots-hyprland.sh help` | current wrapper | Flag/subcommand SoT | Avoid duplicating full flag matrix in docs [VERIFIED: help text] |
| `git submodule` + dual remotes | system git | Clone + pin-bump | Phase 5 contract [VERIFIED: `.gitmodules`, `git submodule status`] |
| Personal hypr hooks | hyprland.conf | Dual-run session | LIVE-02; wrapper enable/disable [VERIFIED: `enable_hypr_ii_hooks` / uninstall disable] |

### Supporting

| Surface | Purpose | When to Use |
|---------|---------|-------------|
| Root `README.md` | One-click discoverability | Always link playbook from root |
| `.planning/PROJECT.md` | Milestone checklist close | Mark doc task done after playbook lands |
| `.planning/REQUIREMENTS.md` | Traceability | Optional note that DOC is satisfied post-verify |
| `arch/README.md` | Optional one-line pointer | Only if operators habitually open Arch OS readme |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| New `docs/dots-hyprland-workflow.md` | Only expand root README | README becomes huge; Arch/nvim mixed with shell adopt |
| New docs file | Only `arch/README.md` section | arch/README is OS install history; wrong genre |
| New docs file | Only wrapper help | Misses clone/pin-bump; not readable offline as narrative |
| Duplicate full flag list in docs | Point to `./arch/dots-hyprland.sh help` | DRY; help already complete |

**Installation:** N/A — documentation phase (no packages).

## Architecture Patterns

### System Architecture Diagram (operator journey)

```text
[Cold machine]
    │ clone .dotfiles (--recurse-submodules)
    ▼
[Parent pin + vendor/dots-hyprland]
    │ git submodule update --init --recursive  (if needed)
    │ verify origin=fork, upstream=end-4 inside vendor
    ▼
[arch/dots-hyprland.sh install --dry-run]
    │ confirm SAFE_DEFAULTS in argv
    ▼
[arch/dots-hyprland.sh install] ──backup gate (type yes)──► vendor ./setup
    │
    ├─► ~/.config/quickshell  (real dir, ii/)
    ├─► ~/.local/state/quickshell/.venv
    └─► enable hypr hooks (env + exec-once qs -c ii)
    ▼
[hyprctl reload / re-login] + waybar still running
    ▼
[Dual-run: waybar + qs -c ii]

Update path (later):
  vendor: fetch upstream → merge/rebase on fork → push origin
  parent: bump submodule SHA → commit gitlink
  machine: re-run wrapper install or install-files (gate + defaults)
```

### Recommended Doc Structure (docs)

```text
docs/
└── dots-hyprland-workflow.md   # CANONICAL playbook (create)
README.md                       # add Desktop shell section → link playbook
.planning/PROJECT.md            # check off workflow doc item
arch/dots-hyprland.sh           # unchanged SoT for flags (docs point here)
```

### Pattern 1: Procedural arch-style sections
**What:** Numbered steps with fenced bash blocks, short warnings, labeled expectations — same voice as `arch/README.md` and wrapper `[INSTALL]/`/`[FAIL]` vocabulary.
**When to use:** Every install/update step operators will copy-paste.

### Pattern 2: Single canonical playbook + thin pointers
**What:** One file owns the full contract; README/PROJECT only link.
**When to use:** Avoid three divergent copies of the same clone commands.

### Pattern 3: Explicit non-goals adjacent to update contract
**What:** DOC-02 non-primary paths live in the same doc as pin-bump so operators cannot miss the warning.
**When to use:** Always for exp-merge / online cache / auto-bump / cutover.

### Anti-Patterns to Avoid
- **Re-teaching `arch/quickshell.sh` or in-repo `.config/quickshell` as install path** — retired RET-01/02.
- **Documenting `exp-merge` as “the update”** — REQUIREMENTS forbids primary use.
- **Omitting `--recursive`** — nested shapes break QML (OWN-03 / Pitfall 5).
- **Teaching bare `--skip-backup` on first adoption** — Pitfall 1 / WRAP backup gate.
- **Teaching full hypr takeover / removing waybar** — dual-run is intentional (LIVE-03).
- **Documenting online cache (`~/.cache/dots-hyprland`) curl install as managed** — bypasses pin (STACK.md).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Flag encyclopedia in markdown | Re-copy entire wrapper help | `./arch/dots-hyprland.sh help` + short defaults summary | Help already maintained with uninstall/protect |
| New verify subcommand for docs | POLISH-01 early | Document manual dual-run checks | Out of scope |
| Doc test framework | bats/pytest for markdown | `rg` section presence asserts in plan verify | Matches Phase 8 “inline asserts, no new harness” culture |
| Second installer script for “docs demo” | Any new arch/*.sh | Existing wrapper only | Single product path |

## Common Pitfalls

### Pitfall 1: Playbook teaches non-recursive submodule init
**What goes wrong:** Nested shapes missing → ii widgets break.
**How to avoid:** Always show `--recurse-submodules` / `--recursive`; include a one-line shapes presence check.
**Warning signs:** Docs say only `git submodule update --init`.

### Pitfall 2: Playbook skips backup gate / encourages skip-backup
**What goes wrong:** Personal dots overwritten; hypr conf renamed if someone also drops skip-hyprland.
**How to avoid:** Show dry-run first; document typing `yes` at gate; never list bare `--skip-backup` as normal.
**Warning signs:** “Non-interactive first install” recipes with `--skip-backup`.

### Pitfall 3: Update section makes exp-merge primary
**What goes wrong:** Experimental merge becomes muscle memory; pin reproducibility lost.
**How to avoid:** Pin-bump sequence first; exp-merge under **Non-primary / experimental** with REQUIREMENTS citation.
**Warning signs:** Update section title is “exp-merge”.

### Pitfall 4: Docs assume hooks already present / ignore uninstall state
**What goes wrong:** Operator on post-uninstall machine thinks dual-run is broken forever.
**How to avoid:** Document that successful `install` enables hooks via wrapper; uninstall comments them; re-install or re-add lines restores dual-run.
**Warning signs:** Docs only say “Phase 7 already added hooks” without re-enable path.

### Pitfall 5: Stale quickshell install narrative remains discoverable
**What goes wrong:** Grep of README/arch docs still points at deleted installer.
**How to avoid:** 09-03 greps non-planning paths; replace or delete re-teaching lines.
**Warning signs:** Any “run arch/quickshell.sh” as current step.

### Pitfall 6: Sibling path `~/github_repo/dots-hyprland` presented as SoT
**What goes wrong:** Edits/pin drift off submodule (Phase 5 D-13/D-14).
**How to avoid:** Canonical path callout: only `vendor/dots-hyprland`.

## Code Examples (verified commands for docs)

### Cold clone + recursive init
```bash
# From a machine with git + SSH to GitHub
git clone --recurse-submodules git@github.com:humam-hossain/.dotfiles.git
cd .dotfiles
# If cloned without recurse:
git submodule update --init --recursive
```

### Verify ownership remotes + pin
```bash
git submodule status vendor/dots-hyprland
git -C vendor/dots-hyprland remote -v
# expect origin → humam-hossain/dots-hyprland, upstream → end-4/dots-hyprland
```

### First adoption install (safe path)
```bash
# Dry-run: must show --core --skip-hyprland --skip-sysupdate
./arch/dots-hyprland.sh install --dry-run
# Live: interactive backup gate — type yes (do NOT pass bare --skip-backup)
./arch/dots-hyprland.sh install
```

### Dual-run expectations (post-install)
```bash
test ! -L ~/.config/quickshell && test -d ~/.config/quickshell
test -f ~/.config/quickshell/ii/shell.qml
test -d ~/.local/state/quickshell/.venv
# hypr: env ILLOGICAL_IMPULSE_VIRTUAL_ENV + exec-once = qs -c ii (active, not commented)
# waybar still configured / running — dual-run intentional; overlap OK
pgrep -x waybar || true
pgrep -a qs || true
```

### Pin-bump update (primary DOC-02)
```bash
cd vendor/dots-hyprland
git fetch upstream
# merge or rebase upstream/main (or desired ref) onto fork branch; resolve; push origin
git push origin HEAD
cd ../..
git add vendor/dots-hyprland   # stage new gitlink SHA
git commit -m "chore(vendor): bump dots-hyprland pin"
# apply on machine
./arch/dots-hyprland.sh install-files   # or install if deps changed; honor backup gate
# optional: ./arch/dots-hyprland.sh protect after deps demotion
```

### Non-primary (document as NOT default)
```bash
# REFUSED by wrapper — not the update contract:
./arch/dots-hyprland.sh exp-merge    # → [FAIL] non-allowlisted
# Online cache / curl install into ~/.cache/dots-hyprland — bypasses parent pin; non-primary
# For experimental upstream tools only: vendor/dots-hyprland/./setup directly (operator owns risk)
```

## Current Codebase Facts (scout)

| Fact | Evidence |
|------|----------|
| Submodule registered | `.gitmodules` → `vendor/dots-hyprland` → fork SSH URL |
| Current pin (scout time) | `1a9ffb78…` via `git submodule status` |
| Wrapper allowlist | install*, uninstall, protect; exp-merge fails with `[FAIL]` |
| SAFE_DEFAULTS | `--core --skip-hyprland --skip-sysupdate` |
| Post-install hooks | `enable_hypr_ii_hooks` called after successful install path |
| Uninstall hooks | `disable_hypr_ii_hooks` comments live + repo lines |
| In-repo QS product | **absent** (`test ! -e .config/quickshell`) |
| `arch/quickshell.sh` | **absent** |
| Root README | nvim/tmux only — **no** ii workflow |
| Live hooks (this host) | May be commented post-uninstall — docs must cover re-enable via install |

## Validation Architecture

> Required for Nyquist VALIDATION.md generation.

### Test framework
**None** — documentation phase. Verification = content greps + structural section checks + negative greps for retired paths. No new `scripts/phase09-*` harness (match Phase 8 culture).

### Quick checks (after each doc task)
```bash
test -f docs/dots-hyprland-workflow.md
rg -n "git (clone|submodule).*recursive|submodule update --init --recursive" docs/dots-hyprland-workflow.md
rg -n "arch/dots-hyprland\.sh" docs/dots-hyprland-workflow.md
rg -n "skip-hyprland|backup|dual-run|waybar|qs -c ii|ILLOGICAL_IMPULSE" docs/dots-hyprland-workflow.md
rg -n "pin|upstream|gitlink|submodule" docs/dots-hyprland-workflow.md
rg -n "exp-merge|non-primary|not primary|experimental" docs/dots-hyprland-workflow.md
rg -n "online cache|~/.cache/dots-hyprland|cache install" docs/dots-hyprland-workflow.md
```

### Negative greps (must not re-teach)
```bash
# Playbook must not present retired installer as current step:
! rg -n 'arch/quickshell\.sh' docs/dots-hyprland-workflow.md README.md || \
  rg -n 'arch/quickshell\.sh' docs/dots-hyprland-workflow.md README.md | rg -i 'retired|do not|removed|not '
# Prefer zero instructional hits outside historical planning/
```

### Full suite (end of phase)
- All DOC-01 steps present as copy-pasteable commands
- DOC-02 pin-bump + explicit non-primary for exp-merge **and** online cache
- README links to playbook
- PROJECT checklist item for workflow docs marked done (or equivalent)
- `nyquist_compliant` aspirational: every plan task has automated `rg`/`test` verify

### Wave 0
**None** — no test framework install; existing bash + ripgrep sufficient.

### Manual-only
| Behavior | Why manual |
|----------|------------|
| “Clean read feels complete” subjective bar | Human skims playbook once on a second machine or fresh eyes |
| Visible ii chrome (LIVE-04 style) | Optional; not required to *write* docs, only to describe expectations |

## Open Questions

None blocking. Discretion items (path name, depth of uninstall docs) resolved by recommendation above: `docs/dots-hyprland-workflow.md` + README/PROJECT pointers; uninstall/protect summarized briefly with pointer to wrapper help.

## Recommendations for Planner

1. **Wave 1 / 09-01:** Create `docs/dots-hyprland-workflow.md` Install/Adopt section covering DOC-01 full chain; style match arch procedural docs; point flag details to wrapper help.
2. **Wave 2 / 09-02:** Add Update/Pin-bump + Non-goals (exp-merge, online cache, auto-bump, cutover, customs, full hypr takeover) — DOC-02.
3. **Wave 3 / 09-03:** Root README section link; PROJECT.md checkbox; light REQUIREMENTS note optional; grep-clean any non-planning re-teaching of `arch/quickshell.sh` as current installer; do not rewrite historical phase scripts.
4. **Threat model (docs):** Mis-teaching skip-backup, non-recursive init, retired installer, or exp-merge-as-primary = high severity content bugs — each plan task must assert required strings present and forbidden instructional strings absent.
5. **Do not** change wrapper behavior, submodule pin, or live machine state as part of this phase unless a doc example is wrong against code (then fix doc, not code, unless code help text contradicts DOC contract).

## RESEARCH COMPLETE

**Output:** `.planning/phases/09-workflow-documentation-update-contract/09-RESEARCH.md`

**Findings:**
- Product path is complete (Phases 5–8); only operator narrative is missing from README/docs.
- Canonical playbook should be new `docs/dots-hyprland-workflow.md` (arch/README is OS install; wrapper help is flag SoT).
- DOC-01 maps 1:1 to real commands (clone --recurse, wrapper dry-run/install, hooks, dual-run checks).
- DOC-02 primary = pin-bump + re-run setup; exp-merge refused by wrapper; online cache explicitly non-primary per STACK/REQUIREMENTS.
- Live hooks may be disabled post-uninstall — playbook must document re-enable via install, not assume always-on dual-run.
