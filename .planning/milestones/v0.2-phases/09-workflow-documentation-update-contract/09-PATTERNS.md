# Phase 9: Workflow Documentation & Update Contract - Pattern Map

**Mapped:** 2026-07-29
**Files analyzed:** 5 surfaces (1 new playbook, README link, PROJECT checklist, optional REQUIREMENTS note, negative greps)
**Analogs found:** 5 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `docs/dots-hyprland-workflow.md` (create) | docs / operator playbook | transform (prose + bash blocks) | `arch/README.md` procedural sections; wrapper `usage()` help | high |
| `README.md` (add section + link) | docs / discovery | transform (markdown link) | existing README `## Neovim` / `## T-MUX` section pattern | exact |
| `.planning/PROJECT.md` (checklist + link) | planning / project status | transform (checkbox + path) | prior PROJECT milestone checkboxes | exact |
| `.planning/REQUIREMENTS.md` (optional DOC status note) | planning / requirements | transform | REQUIREMENTS traceability table | partial (optional) |
| Negative greps / stale ref cleanup | utility / cleanup | transform (text) | Phase 8 D-11 minimal ref cleanup | high |

**Explicit non-files (do not create or rewrite as product code):**
- `arch/dots-hyprland.sh` — flag SoT; docs **point** here, do not reimplement help
- `scripts/phase09-*-smoke.sh` — forbidden (no new harness)
- `scripts/phase07-live-smoke.sh` / `phase04-*` — leave historical
- Live `~/.config/quickshell` / machine install — docs describe; do not mutate for DOC tasks
- `arch/quickshell.sh` — already deleted; do not recreate

## Pattern Assignments

### `docs/dots-hyprland-workflow.md` (canonical playbook)

**Analog:** `arch/README.md` — numbered/headed steps with fenced ```bash``` copy-paste blocks and short warnings.

**Structure pattern:**

```markdown
# dots-hyprland workflow (illogical-impulse)

## Prerequisites
## 1. Clone & recursive submodule init
## 2. Verify fork remotes & pin
## 3. Install via thin wrapper (dry-run → live)
## 4. Session hooks & dual-run expectations
## 5. Update contract (pin-bump)
## 6. Non-goals / non-primary paths
## See also
```

**Command blocks must mirror real surfaces:**

```bash
# From RESEARCH / wrapper — install path
./arch/dots-hyprland.sh install --dry-run
./arch/dots-hyprland.sh install

# Flag details stay DRY:
./arch/dots-hyprland.sh help
```

**Anti-pattern — do not document as current:**

```bash
./arch/quickshell.sh   # RETIRED — hard-deleted Phase 8
# symlink live QS into repo product tree
```

**Match quality:** High — same operator voice as arch docs; content from Phases 5–8 CONTEXT + wrapper help.

---

### `README.md` (discovery pointer)

**Analog:** Existing top-level `## Neovim config` / `## T-MUX` sections.

**Pattern:** Add `## Desktop shell (dots-hyprland)` with 2–4 lines + link to `docs/dots-hyprland-workflow.md`. Do not paste the full playbook into README.

---

### `.planning/PROJECT.md` (close open doc task)

**Analog:** Existing checked items under Key Decisions / Requirements / open checkboxes.

**Pattern:** Mark “Document `.dotfiles` workflow for fork/submodule/install/update” complete and point at the playbook path. Keep history of Phases 5–8 intact.

---

### Stale-ref cleanup (09-03)

**Analog:** Phase 8 D-11 — clean only what **re-teaches** old path as current; do not rewrite planning history or frozen scripts.

**Pattern:**

```bash
# Scope: README.md docs/ arch/ (product-facing). Exclude .planning/ historical CONTEXT.
git grep -n 'arch/quickshell\.sh' -- README.md docs arch || true
# Fix only instructional “run this installer” hits outside planning/
```

---

## Cross-Phase Patterns to Reuse

| Pattern | Source | Reuse in Phase 9 |
|---------|--------|------------------|
| SAFE_DEFAULTS + backup gate narrative | Phase 6 CONTEXT / wrapper help | Install section must include dry-run, `--skip-hyprland`, type `yes`, never bare `--skip-backup` |
| Dual-run policy | Phase 7 D-15 | Document waybar stays; overlap OK |
| Hook lines | Phase 7 D-12/D-13 + wrapper `enable_hypr_ii_hooks` | Document env + `qs -c ii`; note install enables / uninstall comments |
| Canonical vendor path only | Phase 5 D-13 | No sibling `~/github_repo/dots-hyprland` as SoT |
| Pin-only parent commits | Phase 5 D-08 | Update = explicit gitlink bump, not auto-track |
| exp-merge refused | Phase 6 allowlist | DOC-02 non-primary + show wrapper FAIL behavior optional |
| No new smoke harness | Phase 8 D-03 | VALIDATION inline greps only |

## PATTERN MAPPING COMPLETE

**Output:** `.planning/phases/09-workflow-documentation-update-contract/09-PATTERNS.md`
