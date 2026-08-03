# Phase 10: Full-install impact inventory - Context

**Gathered:** 2026-08-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Produce a **committed written impact inventory** so the operator can see exactly what a full dots-hyprland install would change **before** any disposition decisions or live mutation.

**In scope (INV-01..04):**
- Filesystem + package/sysupdate effects of install **without** `--skip-hyprland`
- Separate sections for dropping `--core` and allowing sysupdate (not assumed together)
- Personal hypr surfaces vs upstream hypr install behavior (conf → `.old`, hyprland sync, lua entry, lock/idle auto_backup, custom ignore_existing)
- Non-hypr misc clash candidates when `--core` is dropped
- Record that wrapper SAFE_DEFAULTS remain default and safe dual-run install stays available

**Out of scope this phase:**
- Per-surface dispositions (keep/migrate/accept/merge/defer) — Phase 11
- Staged flag *choices* as approved profile — Phase 11 (DISP-02)
- Wrapper full-profile opt-in implementation — Phase 12
- hypr/custom overlay migration work — Phase 13
- Live full install — Phase 14
- Playbook safe-vs-full docs polish — Phase 15
- Implementing inventory as a live mutating install or blind drop of SAFE_DEFAULTS

**Requirements:** INV-01, INV-02, INV-03, INV-04

</domain>

<decisions>
## Implementation Decisions

### Inventory artifact shape
- **D-01:** Deliverable is a single committed file: `.planning/phases/10-full-install-impact-inventory/10-INVENTORY.md` (phase dir SoT; not under `docs/`).
- **D-02:** One multi-section markdown document (not split files per flag axis). Sections cover SAFE_DEFAULTS residual, hypr axis, misc/`--core` axis, packages/sysupdate axis, plus host snapshot content as decided below.
- **D-03:** Include a **dated machine-specific host presence** table for **live** `~/.config` (what install would collide with on this box).
- **D-04:** Uncertain rows stay in the inventory with status **UNKNOWN** plus a research note / source to recheck — never invent certainty; never drop a surface just because proof is incomplete.

### Evidence sources
- **D-05:** Evidence = **static setup/wrapper source** + **live host scan**. Primary sources: `vendor/dots-hyprland/sdata/subcmd-install/3.files-legacy.sh` (and related files install path), `options.sh`, `arch/dots-hyprland.sh`. No live full install this phase.
- **D-06:** Host presence scan covers **live XDG only** (`~/.config`). Do **not** require dual presence columns for repo `.dotfiles/.config` in the inventory (repo may still be read as secondary research if needed; it is not a required evidence tree).
- **D-07:** **Every** inventory row must cite a concrete source (setup file/symbol/section, wrapper path, or host command/path observation) so Phase 11 can re-verify.
- **D-08:** Wrapper `--dry-run` argv proof is **optional / not required** for Phase 10. Dry-run full-profile proof belongs with Phase 12.

### Flag-axis presentation
- **D-09:** Structure as **three independent sections**: (1) drop `--skip-hyprland`, (2) drop `--core`, (3) allow sysupdate. Do **not** primary-structure as a cross-product of staged profiles.
- **D-10:** Uniform row columns across effect tables: **Path | Effect | Risk | Source | Host present?**
- **D-11:** **SAFE_DEFAULTS residual (INV-04)** is a **dedicated top section before** the three axes — current wrapper injection and that safe install remains available after this milestone.
- **D-12:** Inventory stays **neutral** — map effects only. No recommended staged full profile or “drop all three” implication. Phase 11 owns DISP-02 choices.

### Personal surface depth
- **D-13:** Inside personal `hyprland.conf`, inventory uses **category annotations without dispositions**: monitors, workspaces, binds, exec-once, env, rules (and similar) as tags/notes only — no keep/migrate/accept decisions.
- **D-14:** Hypr explicit rows follow **INV-02 minimum set**: `hyprland.conf`, `hypr/hyprland/`, `hyprland.lua` (absent → install), hyprlock, hypridle, hyprpaper, `hypr/custom` (ignore_existing), **plus** any other live hypr files found by host scan under `~/.config/hypr`.
- **D-15:** **Omit dual-run chrome (Waybar/rofi/swaync) from 10-INVENTORY.md entirely** — no clash rows, no session-risk section for them. Operator stated they **can be removed**; formal dual-run disposition remains Phase 11 but inventory must not center them.
- **D-16:** For misc (`--core` drop): inventory the **full ii default misc catalog** (what a default full dots-hyprland install would place on a **new machine**) with **Host present?** marking collisions on this host. Fixed named INV-03 set (fish, kitty, starship, fontconfig) is included as part of that catalog, not as the only list.
- **D-17:** **Target vision (planning signal):** operator wants the end state of a **default full dots-hyprland install as on a completely new machine**. Phase 10 still only **inventories** that impact; it does not perform install or lock Phase 11 dispositions. Downstream phases should treat greenfield-ii default as the North Star when weighing keep-vs-accept, without inventing dispositions in the inventory itself.

### Claude's Discretion
- Exact markdown heading names, table ordering within a section, and Risk vocabulary (e.g. HIGH/MED/LOW vs short phrases) as long as D-09–D-12 hold
- How to format UNKNOWN rows and research notes
- Whether package/sysupdate rows list meta-package groups at coarse or fine grain, as long as effects and sources are cited and INV-01 is satisfied
- Optional one-off safe-default dry-run if a plan task finds it cheap; not a success criterion

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Planning / requirements
- `.planning/PROJECT.md` — v0.3 full ii install goal; inventory before adopt; SAFE_DEFAULTS reality
- `.planning/REQUIREMENTS.md` — **INV-01**, **INV-02**, **INV-03**, **INV-04** (and later DISP/FULL for boundary only)
- `.planning/ROADMAP.md` — Phase 10 goal, success criteria, phase order 10→15
- `.planning/STATE.md` — current milestone position
- `.planning/research/FEATURES.md` — personal surfaces draft, flag independence, anti-features
- `.planning/research/SUMMARY.md` — Phase 10 rationale; inventory feeds disposition

### Prior phase decisions (do not re-open)
- `.planning/milestones/v0.2-phases/06-thin-setup-wrapper-safe-defaults/06-CONTEXT.md` — SAFE_DEFAULTS, backup gate, thin wrapper
- `.planning/milestones/v0.2-phases/07-install-session-hooks-dual-run-verify/07-CONTEXT.md` — live install under skip-hyprland; personal hypr hooks
- `docs/dots-hyprland-workflow.md` — current safe dual-run operator path

### Install / evidence SoT
- `arch/dots-hyprland.sh` — SAFE_DEFAULTS injection, backup gate, protect list, dry-run behavior
- `vendor/dots-hyprland/setup` — upstream install entry
- `vendor/dots-hyprland/sdata/subcmd-install/options.sh` — `--core`, `--skip-hyprland`, `--skip-sysupdate`, backup flags
- `vendor/dots-hyprland/sdata/subcmd-install/3.files.sh` — files install router
- `vendor/dots-hyprland/sdata/subcmd-install/3.files-legacy.sh` — hypr/misc install behaviors (conf → `.old`, sync, auto_backup, ignore_existing)
- Live host: `~/.config/hypr/` and other XDG paths (host scan only; not committed trees)

### Codebase maps (orientation)
- `.planning/codebase/ARCHITECTURE.md` — provisioning vs config layers
- `.planning/codebase/INTEGRATIONS.md` — hypr session integration (historical dual-run context; dual-run chrome omitted from inventory per D-15)
- `.planning/codebase/CONCERNS.md` — machine-specific hypr/monitor notes

No SPEC.md for this phase — requirements fully in REQUIREMENTS.md + decisions above.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `arch/dots-hyprland.sh` — documents current SAFE_DEFAULTS; source for INV-04 residual section; optional dry-run only
- `vendor/dots-hyprland/sdata/subcmd-install/3.files-legacy.sh` — primary static map of path effects for hypr + misc
- `vendor/dots-hyprland/sdata/subcmd-install/options.sh` — flag semantics for the three axes
- `.planning/research/FEATURES.md` — starter surface tables to expand into 10-INVENTORY.md (verify against setup source; do not copy blindly)
- Live `~/.config/hypr/` — hyprland.conf, hyprland/, hyprlock, hypridle, hyprpaper, backups — host scan inputs

### Established Patterns
- Thin wrapper around upstream `./setup`; never reimplement package lists in `arch/`
- Labeled echos / structured bash in wrapper; docs as committed markdown artifacts (Phase 9 playbook pattern)
- Inventory-before-mutation process for v0.3 (PROJECT + research)

### Integration Points
- Phase 11 consumes `10-INVENTORY.md` rows → dispositions
- Phase 12 uses flag-axis independence (not cross-product) when building opt-in full profile
- Playbook (`docs/dots-hyprland-workflow.md`) is **not** the inventory SoT this phase; Phase 15 updates playbook after adopt path exists

</code_context>

<specifics>
## Specific Ideas

- Operator vision: **default full dots-hyprland as if installing on a completely new machine** — inventory should make that default install’s blast radius visible (full ii misc catalog), with Host present? showing this machine’s collisions.
- Dual-run chrome (Waybar/rofi/swaync): operator said **these can be removed** → **omit from inventory entirely** (D-15); do not spend inventory rows protecting them.
- Host evidence is **live `~/.config` only**, not a required repo dual-track table.
- Uncertainty policy: **UNKNOWN + note**, keep the row.

</specifics>

<deferred>
## Deferred Ideas

- Formal dual-run chrome disposition (remove vs keep) — Phase 11 (DISP-03); inventory omits them per D-15 but Phase 11 should still record an explicit decision consistent with operator lean “can be removed.”
- Preferred staged flag profile / hypr-first soft recommend — explicitly neutral in Phase 10; Phase 11 DISP-02
- Wrapper `--dry-run` full-profile argv proof — Phase 12
- hypr/custom Lua migration of category-annotated must-keeps — Phase 13
- Live full adopt — Phase 14
- Playbook safe vs full documentation — Phase 15
- Waybar custom ports (CUST-*) — later milestone
- Repo ↔ live hypr SoT policy for overlays — Phase 13 OVL-03

</deferred>

---

*Phase: 10-Full-install impact inventory*
*Context gathered: 2026-08-04*
