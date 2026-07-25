# Phase 5: Fork & Submodule Pin - Context

**Gathered:** 2026-07-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Own and pin [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) inside `.dotfiles` **before any install mutates the machine**.

**In scope:**
- Personal public GitHub fork of end-4/dots-hyprland (`origin` = fork, `upstream` = end-4)
- Git submodule at `vendor/dots-hyprland` pointing at the personal fork
- Parent pin: `.gitmodules` + gitlink commit SHA recorded together
- Recursive nested submodule init (shapes / rounded-polygon)
- Verify OWN-01, OWN-02, OWN-03

**Out of scope this phase:**
- `arch/dots-hyprland.sh` wrapper (Phase 6)
- Running `./setup` / install-deps / install-files (Phase 7)
- Session hooks / dual-run (Phase 7)
- Retiring local Quickshell product (Phase 8)
- Operator docs playbook (Phase 9)
- Using or converting `~/github_repo/dots-hyprland` as the seed path

</domain>

<decisions>
## Implementation Decisions

### Fork bootstrap path
- **D-01:** Create the personal fork with **`gh repo fork`** of `end-4/dots-hyprland` (not manual browser-only, not agent-discretion).
- **D-02:** **Sibling clone is irrelevant.** Do not seed from, retarget, or depend on `~/github_repo/dots-hyprland`. Everything is **fresh** — fork on GitHub, then submodule from the fork URL.
- **D-03:** Fork is **public** (default open-source fork visibility).
- **D-04:** Remote URL style: **`origin` = SSH** (`git@github.com:humam-hossain/dots-hyprland.git`), **`upstream` = HTTPS** (`https://github.com/end-4/dots-hyprland.git`). Matches `.dotfiles` SSH origin; upstream is read-only pull.

### Submodule add method
- **D-05:** Register with **`git submodule add <fork-ssh-url> vendor/dots-hyprland`** from REPO_ROOT. Do **not** `mv` a directory into `vendor/`, do **not** submodule-add end-4 URL directly, do **not** “clone then convert” as primary path.
- **D-06:** Nested submodules always via **`--recursive`** (`git submodule update --init --recursive`). OWN-03 requires shapes present.
- **D-07:** Inside the submodule after setup: **`origin` → personal fork**, **`upstream` → end-4**. Submodule add sets origin; **add `upstream` explicitly**.
- **D-08:** **Commit pin only** in parent — no `branch = main` (or similar) in `.gitmodules` that implies auto-tracking. Pin bumps are explicit parent commits. (Auto-bump on every parent pull remains out of scope per REQUIREMENTS.)

### Initial pin selection
- **D-09:** First parent pin = **fork default-branch tip at submodule-add time** (whatever HEAD is on the fork when added — normally matches end-4 tip right after fork).
- **D-10:** Do **not** force-fetch/reset to upstream tip if fork tip looks slightly behind; **trust fork tip as-is** for the initial pin.
- **D-11:** Parent records **`.gitmodules` + gitlink in the same commit** — never only one of the two.
- **D-12:** Phase 5 done only when **full OWN-01 / OWN-02 / OWN-03 checklist** passes:
  1. `git remote -v` inside vendored tree shows origin→fork, upstream→end-4
  2. Parent has `vendor/dots-hyprland` in `.gitmodules` with pinned SHA
  3. `git submodule update --init --recursive` yields complete tree including nested shapes path

### Post-pin clone layout
- **D-13:** **Canonical local path** for all dots-hyprland work after pin: **`vendor/dots-hyprland` only**. Do not develop against a sibling path as source of truth.
- **D-14:** **`~/github_repo/dots-hyprland` is left alone** — Phase 5 does not delete or rewire it. Optional operator cleanup later.
- **D-15:** Fresh `.dotfiles` clones use stock git: **`git clone --recurse-submodules`** or clone then **`git submodule update --init --recursive`**. No Phase 5 bootstrap helper script (docs in Phase 9).
- **D-16:** **Pin only — no install.** No `./setup`, no wrapper skeleton, no session hooks in Phase 5.

### Agent's Discretion
- Exact `gh repo fork` flags (`--remote-name`, whether to clone into a temp path vs only submodule-add)
- Commit message wording for the parent pin commit (style should match repo norms)
- Exact verification command sequence / smoke script shape for OWN-01–03
- Whether to document the pinned short SHA in a comment or leave it only in gitlink
- Order of operations details as long as D-01–D-16 hold

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Planning (v0.2)
- `.planning/PROJECT.md` — v0.2 goal: personal fork + `vendor/dots-hyprland` submodule; install later via thin wrapper
- `.planning/REQUIREMENTS.md` — **OWN-01**, **OWN-02**, **OWN-03** (this phase); WRAP/LIVE/RET/DOC for later phases
- `.planning/ROADMAP.md` — Phase 5 goal, success criteria, plans 05-01…05-03
- `.planning/STATE.md` — Current position Phase 5
- `.planning/research/SUMMARY.md` — Architecture: ownership remote → pin surface → setup later
- `.planning/research/PITFALLS.md` — **Pitfall 4** (sibling→fork+submodule conversion failures), **Pitfall 5** (nested shapes not initialized)

### Repo / tooling context
- `.planning/codebase/STRUCTURE.md` — No `vendor/` today; `arch/` install style
- `.planning/codebase/ARCHITECTURE.md` — Provisioning layer; third-party boundary expectations
- `.dotfiles` remote style: `git@github.com:humam-hossain/.dotfiles.git` (SSH origin pattern to match for fork)

### Upstream (external — not in-repo)
- `https://github.com/end-4/dots-hyprland` — upstream source of truth for fork
- Nested shapes submodule (inside dots-hyprland): `dots/.config/quickshell/ii/modules/common/widgets/shapes` → `https://github.com/end-4/rounded-polygon-qmljs.git`

No SPEC.md for this phase — requirements fully in REQUIREMENTS.md + decisions above.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- None for submodule pin itself — no existing `.gitmodules` or `vendor/` tree in `.dotfiles`
- `gh` CLI available and authenticated as **humam-hossain** (fork does not exist yet: `humam-hossain/dots-hyprland` unresolved)
- Sibling checkout at `~/github_repo/dots-hyprland` exists but is **out of band** per D-02/D-14 (origin still end-4; not a personal fork)

### Established Patterns
- Parent repo uses **SSH** for `origin` — mirror for fork origin (D-04)
- Nested submodule pattern is **upstream’s**: one nested entry for shapes; parent only records outer SHA; recursive init required
- No reimplementation of package lists in this phase (and not in v0.2 wrappers either — Phase 6)

### Integration Points
- New paths: `.gitmodules`, `vendor/dots-hyprland/` (gitlink + checkout)
- Downstream Phase 6 will call `vendor/dots-hyprland/./setup` — pin must be complete and recursive first
- Phase 9 documents clone `--recurse-submodules` (D-15); Phase 5 only establishes the pin, not the full playbook

</code_context>

<specifics>
## Specific Ideas

- GitHub user for fork: **humam-hossain** → expected repo `humam-hossain/dots-hyprland`
- Submodule path **fixed** by PROJECT/REQUIREMENTS: `vendor/dots-hyprland`
- User explicitly: *“what exists in ~/github_repo/dots-hyprland/ is irrelevant. Do things fresh”* — reinforced by D-02, D-13, D-14

</specifics>

<deferred>
## Deferred Ideas

- Thin setup wrapper `arch/dots-hyprland.sh` — Phase 6
- Safe defaults (`--core --skip-hyprland`), backup gate — Phase 6
- Install + session hooks + dual-run verify — Phase 7
- Retire local `.config/quickshell` + `arch/quickshell.sh` — Phase 8
- Full operator workflow docs (clone/install/update/pin-bump) — Phase 9
- Optional deletion of sibling `~/github_repo/dots-hyprland` — operator choice, not Phase 5
- Custom bootstrap script for submodules — not Phase 5 (stock git recurse; docs Phase 9)

None — discussion stayed within phase scope (wrapper skeleton explicitly declined).

</deferred>

---

*Phase: 5-Fork & Submodule Pin*
*Context gathered: 2026-07-25*
