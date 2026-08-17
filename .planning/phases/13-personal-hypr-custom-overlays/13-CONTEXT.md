# Phase 13: Personal hypr/custom overlays - Context

**Gathered:** 2026-08-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Express the already-locked Phase 11 D-16 must-keeps as ii-compatible `hypr/custom` Lua overlays in the parent repo, written **before** the first live full hypr files install that would rely on them, with a written repo vs live vs fork SoT policy.

**In scope (OVL-01, OVL-02, OVL-03):**
- Minimal `hypr/custom` Lua for **only** monitors (DP-1 / HDMI-A-2), workspace layout pins, and env (cursor + `ILLOGICAL_IMPULSE_VIRTUAL_ENV`)
- Overlays compatible with `hyprland.lua` require contract
- Repo files exist (or an explicit checklist-gate — **not** chosen) before Phase 14 live full hypr files
- Written SoT policy: repo vs live vs fork, and how a cold machine applies repo overlays

**Out of scope this phase:**
- Live full install / session mutation — Phase 14
- Pre-flight live→repo sync of the wider `.config` tree — Phase 14 (Phase 11 D-07)
- Applying overlays onto live `~/.config/hypr/custom/` — Phase 14 (documented apply step prepared here)
- Chrome teardown / dual-run stop — Phase 14 (D-11/D-14)
- Playbook safe-vs-full polish including overlay SoT narrative — Phase 15 (DOC-04 consumes this policy)
- Migrating autostart apps, personal binds, or chrome exec-once — Phase 11 D-17 (locked drop)
- Extra custom fluff beyond D-16
- Committing machine overlays into `vendor/dots-hyprland` / the personal fork
- Changing wrapper `--full` / SAFE_DEFAULTS (Phase 12)
- CUST-* Waybar ports, CUT-01 as a separate project

**Requirements:** OVL-01, OVL-02, OVL-03

</domain>

<decisions>
## Implementation Decisions

### Overlay SoT (OVL-03)
- **D-01:** Authoring SoT is parent-repo **`.config/hypr/custom/`**. Live `~/.config/hypr/custom/` is an applied copy, not the place you edit for the next machine. Vendor/submodule remains product SoT. — **Reversibility:** costly — Phase 14 apply + Phase 15 DOC-04 and cold-machine path all cite this tree
- **D-02:** Cold-machine apply is a **documented apply-after-install** step: after ii seeds or `ignore_existing` on `hypr/custom`, copy/rsync repo `.config/hypr/custom/` onto live `~/.config/hypr/custom/`. Phase 13 writes the files and the rule; Phase 14 runs the apply. No wrapper rewrite and no fork commits for apply. — **Reversibility:** costly — Phase 14 adopt sequence depends on this order
- **D-03:** Apply is **one-way repo → live**. Persist a live tweak by copying it back into repo `.config/hypr/custom/` (operator discipline). No sync daemon. — **Reversibility:** reversible
- **D-04:** **Never** commit these machine overlays into `vendor/dots-hyprland` or the personal fork. Fork stays product; parent `.config/hypr/custom/` is the personal layer. — **Reversibility:** costly — mixing SoT would couple pin-bumps to machine layout

### Monitor / workspace file slot
- **D-05:** All D-16 content lives under **`hypr/custom/`** slots that `hyprland.lua` actually requires — not `~/.config/hypr/monitors.lua` / `workspaces.lua` (those are optional nwg-displays root files, outside `custom/`). — **Reversibility:** costly — SoT path and apply source are this directory
- **D-06:** **Env** → `custom/env.lua`. **Monitors + workspace pins** → `custom/general.lua` (upstream `hyprland/general.lua` already uses `hl.monitor({...})`; custom general is required after it). Cursor `hyprctl setcursor` (if still needed beyond env vars) → `custom/execs.lua` as part of the env/cursor must-keep, **not** as D-17 autostart. Do not add `custom/keybinds.lua` or `custom/rules.lua` content this phase. — **Reversibility:** reversible — file split inside `custom/` is local
- **D-07:** Do **not** treat nwg-displays root `monitors.lua` / `workspaces.lua` as SoT. If research proves `custom/general.lua` cannot express workspace-to-monitor pins, stop and record the gap — do not silently switch SoT to hypr-root files.

### Env overlay contents
- **D-08:** `custom/env.lua` **does** set cursor (`XCURSOR_THEME=Catppuccin-Mocha-Dark-Cursors`, `XCURSOR_SIZE=30`) **and** `ILLOGICAL_IMPULSE_VIRTUAL_ENV=~/.local/state/quickshell/.venv`. Keep D-16 even though upstream `hyprland/env.lua` already sets the same venv path — overlay must be self-contained after personal `hyprland.conf` becomes `.old` and Phase 12 conf-hooks no longer apply. Duplicate identical env is acceptable. — **Reversibility:** reversible
- **D-09:** Source values from repo `.config/hypr/hyprland.conf` (monitors ~29–30, workspaces ~76–87, env ~106–111). Do not invent new monitors, pins, or theme names.

### Prep vs apply timing (OVL-02)
- **D-10:** **Write the real overlay files in the repo this phase.** OVL-02 is satisfied by committed repo files existing before Phase 14, not by a checklist-only gate. — **Reversibility:** reversible
- **D-11:** **No live `~/.config` mutation this phase.** Do not pre-seed live custom/ to win `ignore_existing`. Apply is Phase 14 after full files install. — **Reversibility:** one-way if violated — live mutation before adopt is Phase 14’s job and would skip the process gate
- **D-12:** Phase 13 also writes the **SoT + apply rule** (short committed note in phase dir or overlay-adjacent README/comment as planner chooses) so Phase 14/15 do not invent policy. Full playbook prose is Phase 15 DOC-04.

### Locked carry-forward (do not reopen)
- **D-13:** Must-migrate set remains Phase 11 **D-16 only**: monitors (DP-1 / HDMI-A-2), workspace layout pins, env (cursor + `ILLOGICAL_IMPULSE_VIRTUAL_ENV`). Autostart apps, personal tool binds, chrome exec-once stay **dropped** (Phase 11 D-17). `hypr/custom/` may take the ii empty seed; we populate only D-16 (Phase 11 D-20).

### Claude's Discretion
- Exact Hyprland Lua table fields for `hl.monitor` / workspace pins (match personal conf semantics)
- Exact apply command (`cp -a` vs `rsync -a`) and whether it overwrites empty ii seed files
- Whether `setcursor` is required in `custom/execs.lua` or env vars suffice
- Whether `ILLOGICAL_IMPULSE_VIRTUAL_ENV` in `custom/env.lua` can be omitted later if adopt proves upstream `hyprland/env.lua` always loads first — default is **keep it** (D-08)
- Filename comments / tiny SoT note shape (D-12)
- Light assert/lint that repo custom files exist and do not contain D-17 binds/autostart

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Planning / requirements
- `.planning/PROJECT.md` — v0.3 full install; personal overlays; new-machine North Star
- `.planning/REQUIREMENTS.md` — **OVL-01**, **OVL-02**, **OVL-03** (DISP/FULL/ADOPT/DOC for boundary only)
- `.planning/ROADMAP.md` — Phase 13 goal + success criteria; Phase 14/15 dependencies
- `.planning/STATE.md` — current position

### Prior phase decisions (do not re-open)
- `.planning/phases/11-disposition-decisions/11-CONTEXT.md` — D-15/D-16/D-17/D-20 must-keeps; D-08/D-09 repo overlay set + cold-machine apply
- `.planning/phases/11-disposition-decisions/11-DISPOSITIONS.md` — **SoT for what to migrate** (§3 Axis A migrate rows + D-17 drop table)
- `.planning/phases/12-wrapper-full-profile/12-CONTEXT.md` — D-15 hooks still write into `hyprland.conf` (becomes `.old` on adopt); no overlay writes in Phase 12
- `.planning/phases/10-full-install-impact-inventory/10-INVENTORY.md` — `hypr/custom` `ignore_existing` behavior; Axis A surfaces
- `.planning/phases/10-full-install-impact-inventory/10-CONTEXT.md` — D-17 North Star (default full install as on a new machine)

### Overlay / session contract (MUST read)
- `vendor/dots-hyprland/dots/.config/hypr/hyprland.lua` — require order: `custom.env` then hyprland defaults then `custom.general` / `custom.execs`; optional root `monitors.lua` / `workspaces.lua`
- `vendor/dots-hyprland/dots/.config/hypr/hyprland/general.lua` — `hl.monitor({...})` pattern to overlay
- `vendor/dots-hyprland/dots/.config/hypr/hyprland/env.lua` — already sets `ILLOGICAL_IMPULSE_VIRTUAL_ENV`
- `vendor/dots-hyprland/dots/.config/hypr/hyprland/execs.lua` — upstream `qs -c $qsConfig` + `hyprctl setcursor Bibata-Modern-Classic 24` (personal cursor must override)
- `vendor/dots-hyprland/dots/.config/hypr/hyprland/services/create_custom_config.lua` — empty seed files on hyprland.start
- `vendor/dots-hyprland/sdata/subcmd-install/3.files-legacy.sh` — `install_dir__ignore_existing` for `dots/.config/hypr/custom`
- `.config/hypr/hyprland.conf` — personal must-keep source (monitors ~29–30, workspaces ~76–87, env ~106–111)

### Install / wrapper (boundary only)
- `arch/dots-hyprland.sh` — `--full` path exists; do not change for overlays
- `docs/dots-hyprland-workflow.md` — current operator path; overlay SoT prose is Phase 15

### Codebase maps (orientation)
- `.planning/codebase/ARCHITECTURE.md` — provisioning vs config layers
- `.planning/codebase/INTEGRATIONS.md` — hypr session context
- `.planning/codebase/CONCERNS.md` — machine-specific monitors / personal knobs

No SPEC.md for this phase — requirements fully in REQUIREMENTS.md + decisions above.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `vendor/dots-hyprland/dots/.config/hypr/hyprland.lua` — overlay require contract (`custom.env`, `custom.general`, `custom.execs`)
- `vendor/dots-hyprland/dots/.config/hypr/hyprland/general.lua` — `hl.monitor` API to copy/override
- `vendor/dots-hyprland/dots/.config/hypr/custom/{env,execs,general,keybinds,rules,variables}.lua` — upstream empty seeds (live/repo custom currently ABSENT)
- `.config/hypr/hyprland.conf` — D-16 source values
- `11-DISPOSITIONS.md` §3 — migrate vs drop rows

### Established Patterns
- Thin wrapper; do not reimplement `./setup` or put personal layout in the submodule
- Phase-dir SoT markdown for policy; personal runtime files live under repo `.config/`
- `ignore_existing` on `hypr/custom/` — first install seeds if ABSENT; later apply overwrites seeds from repo
- Backup gate + `--full` already exist; this phase does not touch them

### Integration Points
- Repo `.config/hypr/custom/` created this phase (currently missing)
- Phase 14: full files install (conf→`.old`, lua entry) **then** documented apply of repo custom/ → live
- Phase 15 DOC-04 documents this SoT + apply
- After adopt, upstream `hyprland/execs.lua` still launches `qs -c $qsConfig` — do not re-add `qs -c ii` in custom execs
- Upstream default monitor is a single `output=""` preferred/auto/scale 1 — personal dual-head must overlay after that load

### Creative options
- `custom/general.lua` can add further `hl.monitor` calls after the generic default (preferred over nwg-displays root files so SoT stays under `custom/`)
- Apply can be a few-line documented `cp`/`rsync` in the phase SoT note; no new wrapper subcommand required

</code_context>

<specifics>
## Specific Ideas

- Operator is building as if **setting up a completely new machine** must be effortless: clone repo → full install → apply repo `.config/hypr/custom/`.
- Does **not** want a personal hypr overlay product — only the D-16 must-keeps in the ii `custom/` slots dots-hyprland already loads.
- First SoT answer was “I don’t want my own custom hypr stuff, if dots-hyprland requires it then do it,” then **explicitly kept Phase 11 D-16** after being reminded overlays are optional upstream and D-16 is the machine-layout reason they exist.
- Preferred home for that layer: **`.config/hypr/custom/`** (parent repo).
- Selected **documented apply after install** (not stow/symlink, not pre-seed live).
- Remaining SoT follow-ups (one-way apply, never fork) and the other three gray areas were locked from that new-machine / repo-`custom/` policy when the operator asked to continue through `/gsd-plan-phase` without further menus.

</specifics>

<deferred>
## Deferred Ideas

- Phase 14: run the documented apply onto live; pre-flight D-07; live `--full` adopt; chrome accept-remove
- Phase 15: playbook DOC-04 for overlay SoT + apply
- Reopening D-16 to drop overlays entirely — considered, then rejected by operator
- Stow/symlink live custom/ to repo — rejected
- Pre-seed live custom/ before full install — rejected
- nwg-displays `hypr/monitors.lua` + `hypr/workspaces.lua` as SoT — rejected unless `custom/general.lua` cannot express pins (D-07 gap)
- Wrapper `--full` changes or apply subcommand — not this phase
- CUST-01..04, CUT-01 as a separate bar project

None of the above expand Phase 13 beyond repo overlays + SoT/apply rule.

</deferred>

---

*Phase: 13-Personal hypr/custom overlays*
*Context gathered: 2026-08-17*
*Interactive discuss: Overlay SoT answered; remaining areas locked from stated new-machine / repo-custom policy when operator asked to continue through plan-phase*
