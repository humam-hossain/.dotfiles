# Phase 13: Personal hypr/custom overlays - Context

**Gathered:** 2026-08-19
**Status:** Ready for planning
**Supersedes:** 2026-08-17 CONTEXT (cursor + VIRTUAL_ENV overlays dropped; apply missing-file policy tightened)

<domain>
## Phase Boundary

Express the already-locked Phase 11 D-16 **machine-layout** must-keeps as ii-compatible `hypr/custom` Lua overlays in the parent repo, written **before** the first live full hypr files install that would rely on them, with a written repo vs live vs fork SoT policy.

Operator bar for this update: **as simple and default as possible**, and a **cold machine** (clone → full install → apply) must reproduce the dual-head + workspace layout with minimum extra ritual. Overlay only what stock dots-hyprland cannot know.

**In scope (OVL-01, OVL-02, OVL-03):**
- Minimal `hypr/custom` Lua for **only** monitors (DP-1 / HDMI-A-2) and workspace layout pins
- `custom/env.lua` and `custom/execs.lua` exist as empty require slots (no env/cursor/exec content)
- Overlays compatible with `hyprland.lua` require contract
- Repo files exist before Phase 14 live full hypr files (not checklist-only)
- Written SoT policy: repo vs live vs fork, and how a cold machine applies repo overlays

**Out of scope this phase:**
- Live full install / session mutation — Phase 14
- Pre-flight live→repo sync of the wider `.config` tree — Phase 14 (Phase 11 D-07)
- Applying overlays onto live `~/.config/hypr/custom/` — Phase 14 (documented apply step prepared here)
- Chrome teardown / dual-run stop — Phase 14 (D-11/D-14)
- Playbook safe-vs-full polish including overlay SoT narrative — Phase 15 (DOC-04 consumes this policy)
- Migrating autostart apps, personal binds, or chrome exec-once — Phase 11 D-17 (locked drop)
- Personal cursor overlay (Catppuccin / `setcursor`) — dropped this discussion; upstream default cursor is fine
- `ILLOGICAL_IMPULSE_VIRTUAL_ENV` in `custom/env.lua` — dropped this discussion; upstream `hyprland/env.lua` already sets the same path
- Extra custom fluff beyond monitors + pins
- Committing machine overlays into `vendor/dots-hyprland` / the personal fork
- Changing wrapper `--full` / SAFE_DEFAULTS (Phase 12)
- Folding apply into the wrapper — not this phase (document the command; Phase 14/15 may make install-then-apply one ritual)
- CUST-* Waybar ports, CUT-01 as a separate project

**Requirements:** OVL-01, OVL-02, OVL-03 — remain **Pending** until repo overlay files exist and verify passes. This CONTEXT does not complete them.

</domain>

<decisions>
## Implementation Decisions

### Overlay SoT (OVL-03)
- **D-01:** Authoring SoT is parent-repo **`.config/hypr/custom/`**. Live `~/.config/hypr/custom/` is an applied copy, not the place you edit for the next machine. Vendor/submodule remains product SoT. — **Reversibility:** costly — Phase 14 apply + Phase 15 DOC-04 and cold-machine path all cite this tree
- **D-02:** Cold-machine apply is a **documented apply-after-install** step: after ii seeds or `ignore_existing` on `hypr/custom`, copy repo `.config/hypr/custom/` files onto live `~/.config/hypr/custom/`. Phase 13 writes the files and the rule; Phase 14 runs the apply. No wrapper rewrite and no fork commits for apply. — **Reversibility:** costly — Phase 14 adopt sequence depends on this order
- **D-03:** Apply is **one-way repo → live**. Persist a live tweak by copying it back into repo `.config/hypr/custom/` (operator discipline). No sync daemon. — **Reversibility:** reversible
- **D-04:** **Never** commit these machine overlays into `vendor/dots-hyprland` or the personal fork. Fork stays product; parent `.config/hypr/custom/` is the personal layer. — **Reversibility:** costly — mixing SoT would couple pin-bumps to machine layout
- **D-05:** SoT + apply rule lives in **`.planning/phases/13-personal-hypr-custom-overlays/13-SOT-APPLY.md`**. Phase 14 runs the command; Phase 15 DOC-04 cites it. — **Reversibility:** reversible

### Monitor / workspace file slot
- **D-06:** All overlay **content** lives in **`custom/general.lua`** (`hl.monitor` + `hl.workspace_rule`). `custom/env.lua` and `custom/execs.lua` are committed **empty require slots** so `hyprland.lua` can require them and Phase 14 apply can overwrite ii seeds. Do not add `custom/keybinds.lua` or `custom/rules.lua`. Do not use nwg-displays root `monitors.lua` / `workspaces.lua`. — **Reversibility:** costly — SoT path and apply source are this directory
- **D-07:** D-07 stop from 2026-08-17 CONTEXT is **closed**. `hl.workspace_rule` in `custom/general.lua` can express pins. Do not silently switch SoT to hypr-root files. If live adopt fails, Phase 14 records it — do not change SoT in Phase 13.

### What the overlay contains (simple / default bar)
- **D-08:** **No personal cursor overlay.** No `XCURSOR_THEME` / `XCURSOR_SIZE` in `env.lua`. No `hyprctl setcursor` in `execs.lua`. Upstream / default Hyprland cursor (Bibata 24 from `hyprland/execs.lua`) is fine. Revises 2026-08-17 D-08 cursor half and Phase 11 D-16 cursor. — **Reversibility:** reversible
- **D-09:** **No `ILLOGICAL_IMPULSE_VIRTUAL_ENV` in `custom/env.lua`.** Upstream `hyprland/env.lua` already sets `home_dir .. "/.local/state/quickshell/.venv"` (same path as personal conf `~/.local/state/quickshell/.venv`). Duplicate overlay is not needed for default or for a cold full install. `env.lua` is an empty slot like `execs.lua`. Revises 2026-08-17 D-08 venv half. — **Reversibility:** reversible
- **D-10:** Source **monitor and workspace** values from repo `.config/hypr/hyprland.conf` only (monitors ~29–30, workspaces ~76–87). Do not invent new monitors, pins, scales, or transforms.

### Monitors
- **D-11:** DP-1: `mode = "preferred"`, `position = "auto"`, **`scale = "auto"`** (conf line 29). HDMI-A-2: `mode = "preferred"`, `position = "auto"`, **`scale = 1.5`**, **`transform = 1`** (conf line 30). Additional `hl.monitor` calls in `custom/general.lua` after upstream generic `output=""` default.
- **D-12:** Phase 13 verify **must assert the literal** `scale = "auto"` on DP-1. If Hyprland Lua rejects the string at write/verify time, change **only that field** to `1` and record the coercion in `13-SOT-APPLY.md`. Do not invent a third scale.
- **D-13:** If Phase 14 live adopt shows DP-1 at the wrong scale, **leave Phase 13 files as written**. Phase 14 records it; copy-back (D-03) is how a live fix re-enters the repo.

### Workspace pins
- **D-14:** Pins are conf lines 76–87 **exactly**: workspaces `"1"`–`"5"` and `"special:social"` → `DP-1`; `"6"`–`"10"` → `HDMI-A-2`. Lua workspace IDs are **strings** (vendor style: `workspace = "special:special"`).
- **D-15:** Each `hl.workspace_rule` is **monitor only**. No `default`, gaps, `no_rounding`, `no_border`, or other style fields.

### Prep vs apply timing (OVL-02)
- **D-16:** **Write the real overlay files in the repo this phase.** OVL-02 is satisfied by committed repo files existing before Phase 14, not by a checklist-only gate. — **Reversibility:** reversible
- **D-17:** **No live `~/.config` mutation this phase.** Do not pre-seed live custom/ to win `ignore_existing`. Apply is Phase 14 after full files install. — **Reversibility:** one-way if violated — live mutation before adopt is Phase 14’s job
- **D-18:** Apply command Phase 14 will run (document in `13-SOT-APPLY.md`, do not run now):
  1. `mkdir -p` live `~/.config/hypr/custom/` if missing
  2. **`cp -a` the three named files** (`general.lua`, `env.lua`, `execs.lua`) — never `rsync --delete`, never copy `keybinds.lua` / `rules.lua` / `variables.lua`
  3. Overwrite those three if live ii seeds exist
  4. **Fail the apply if repo `general.lua` is missing** (layout file required for exact setup)
  5. If repo `env.lua` or `execs.lua` is missing: **warn and continue** (empty slots). Do not skip the whole apply solely because a slot file is absent
  — **Reversibility:** costly — Phase 14 copies this command

### Phase 13 verify (does not complete OVL by existing as prose)
- **D-19:** In-repo checks this phase must actually run against files on disk:
  - `.config/hypr/custom/general.lua` **exists and is non-empty**
  - `.config/hypr/custom/env.lua` and `execs.lua` **exist** (empty / no Lua statements is correct; do **not** use `test -s` as the pass condition for those two)
  - `general.lua` contains `DP-1`, `HDMI-A-2`, `hl.workspace_rule`, `special:social`, and literal `scale = "auto"`
  - **No** `XCURSOR_`, `setcursor`, `ILLOGICAL_IMPULSE_VIRTUAL_ENV` in `custom/*.lua`
  - **No** D-17 leakage (chrome, vesktop/discord, waybar, swaync, `qs -c ii`, google-chrome, etc.)
  - **No** repo `.config/hypr/monitors.lua` or `workspaces.lua`; no `custom/keybinds.lua` or `custom/rules.lua`
  - `13-SOT-APPLY.md` exists and names `cp -a` plus the fail-if-`general.lua`-missing rule
- **D-20:** OVL-01/OVL-02/OVL-03 stay **Pending** until those files exist **and** D-19 checks pass. Do not treat CONTEXT.md, RESEARCH.md, or unexecuted PLAN.md as requirement completion.

### Locked carry-forward (do not reopen)
- **D-21:** Must-migrate **content** is now **monitors + workspace pins only**. Phase 11 D-16 env (cursor + `ILLOGICAL_IMPULSE_VIRTUAL_ENV`) is **not overlaid** — upstream defaults match what this machine needs. Autostart, personal binds, chrome exec-once stay **dropped** (Phase 11 D-17). `hypr/custom/` may take the ii empty seed; we populate general.lua with D-14/D-11 and leave env/execs as empty slots (Phase 11 D-20 narrowed).
- **D-22:** Phase 12 `--full` / SAFE_DEFAULTS unchanged. No wrapper apply subcommand this phase.

### Claude's Discretion
- Exact `hl.monitor` table keys beyond locked scale/position/mode/transform (match conf semantics)
- Whether empty `env.lua` / `execs.lua` are 0-byte or a single newline so git tracks them — **no Lua statements either way**
- Exact `13-SOT-APPLY.md` wording; must include D-01..D-05 and D-18 policies
- Exact verify script shape (phase-dir smoke vs inline plan `<verify>`); must implement D-19, must not `test -s` empty slots
- Whether `home_dir` local is needed in empty `env.lua` (it is not)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Planning / requirements
- `.planning/PROJECT.md` — v0.3 full install; personal overlays; new-machine North Star
- `.planning/REQUIREMENTS.md` — **OVL-01**, **OVL-02**, **OVL-03** (still Pending; DISP/FULL/ADOPT/DOC for boundary only)
- `.planning/ROADMAP.md` — Phase 13 goal + success criteria; Phase 14/15 dependencies
- `.planning/STATE.md` — current position

### Prior phase decisions (do not re-open except where this CONTEXT revises env/cursor)
- `.planning/phases/11-disposition-decisions/11-CONTEXT.md` — D-15/D-16/D-17/D-20; this phase narrows D-16 env out of overlays
- `.planning/phases/11-disposition-decisions/11-DISPOSITIONS.md` — **SoT for what to migrate** (§3 Axis A migrate rows + D-17 drop table)
- `.planning/phases/12-wrapper-full-profile/12-CONTEXT.md` — D-15 hooks still write into `hyprland.conf` (becomes `.old` on adopt); no overlay writes in Phase 12
- `.planning/phases/10-full-install-impact-inventory/10-INVENTORY.md` — `hypr/custom` `ignore_existing` behavior; Axis A surfaces
- `.planning/phases/10-full-install-impact-inventory/10-CONTEXT.md` — D-17 North Star (default full install as on a new machine)

### Overlay / session contract (MUST read)
- `vendor/dots-hyprland/dots/.config/hypr/hyprland.lua` — require order: `custom.env` then hyprland defaults then `custom.general` / `custom.execs`; optional root `monitors.lua` / `workspaces.lua`
- `vendor/dots-hyprland/dots/.config/hypr/hyprland/general.lua` — `hl.monitor({...})` pattern to overlay
- `vendor/dots-hyprland/dots/.config/hypr/hyprland/env.lua` — **already** sets `ILLOGICAL_IMPULSE_VIRTUAL_ENV`; do not duplicate in `custom/env.lua`
- `vendor/dots-hyprland/dots/.config/hypr/hyprland/execs.lua` — upstream `qs -c $qsConfig` + `hyprctl setcursor Bibata-Modern-Classic 24` (personal cursor **not** overlaid)
- `vendor/dots-hyprland/dots/.config/hypr/hyprland/rules.lua` — `hl.workspace_rule({ workspace = "special:special", ... })` string-ID example
- `vendor/dots-hyprland/dots/.config/hypr/hyprland/services/create_custom_config.lua` — empty seed files on hyprland.start
- `vendor/dots-hyprland/sdata/subcmd-install/3.files-legacy.sh` — `install_dir__ignore_existing` for `dots/.config/hypr/custom`
- `.config/hypr/hyprland.conf` — personal layout source (monitors ~29–30, workspaces ~76–87). Env/cursor lines are **not** overlay sources this phase.

### Install / wrapper (boundary only)
- `arch/dots-hyprland.sh` — `--full` path exists; do not change for overlays
- `docs/dots-hyprland-workflow.md` — current operator path; overlay SoT prose is Phase 15

### Codebase maps (orientation)
- `.planning/codebase/ARCHITECTURE.md` — provisioning vs config layers
- `.planning/codebase/INTEGRATIONS.md` — hypr session context
- `.planning/codebase/CONCERNS.md` — machine-specific monitors / personal knobs

### Research (orientation; this CONTEXT overrides env/cursor/setcursor prescriptions)
- `.planning/phases/13-personal-hypr-custom-overlays/13-RESEARCH.md` — require contract, `hl.monitor` / `hl.workspace_rule`, ignore_existing. **Do not** implement research’s `setcursor` or `XCURSOR_*` or `ILLOGICAL_IMPULSE_VIRTUAL_ENV` in `custom/`. **Do not** use research `test -s` on empty `env.lua`/`execs.lua`.

No SPEC.md for this phase — requirements fully in REQUIREMENTS.md + decisions above.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `vendor/dots-hyprland/dots/.config/hypr/hyprland.lua` — overlay require contract (`custom.env`, `custom.general`, `custom.execs`)
- `vendor/dots-hyprland/dots/.config/hypr/hyprland/general.lua` — `hl.monitor` API to copy/override
- `vendor/dots-hyprland/dots/.config/hypr/hyprland/env.lua` — venv path already set; custom env stays empty
- `vendor/dots-hyprland/dots/.config/hypr/custom/{env,execs,general,keybinds,rules,variables}.lua` — upstream empty seeds (live/repo custom currently ABSENT)
- `.config/hypr/hyprland.conf` — D-11/D-14 source values
- `11-DISPOSITIONS.md` §3 — migrate vs drop rows (env migrate row is intentionally not implemented as overlay content)

### Established Patterns
- Thin wrapper; do not reimplement `./setup` or put personal layout in the submodule
- Phase-dir SoT markdown for policy; personal runtime files live under repo `.config/`
- `ignore_existing` on `hypr/custom/` — first install seeds if ABSENT; later apply overwrites seeds from repo
- Backup gate + `--full` already exist; this phase does not touch them
- Prefer upstream default unless the new machine cannot guess it (dual-head + pins)

### Integration Points
- Repo `.config/hypr/custom/` created this phase (currently missing)
- Phase 14: full files install (conf→`.old`, lua entry) **then** documented apply of repo custom/ → live
- Phase 15 DOC-04 documents this SoT + apply
- After adopt, upstream `hyprland/execs.lua` still launches `qs -c $qsConfig` — do not re-add `qs -c ii` in custom execs
- Upstream default monitor is a single `output=""` preferred/auto/scale 1 — personal dual-head must overlay after that load

### Creative options
- `custom/general.lua` adds `hl.monitor` + `hl.workspace_rule` after the generic default (preferred over nwg-displays root files)
- Apply is a few-line documented `cp` in `13-SOT-APPLY.md`; no new wrapper subcommand required
- Empty `env.lua` / `execs.lua` may be a newline so git tracks them

</code_context>

<specifics>
## Specific Ideas

- Operator wants **simple and default**, and a **completely new setup with minimum effort** to get the **exact** dual-head + workspace layout.
- Overlay is **not** a personal hypr product — only what stock ii cannot know (this machine’s monitors and pins).
- Cursor: “don’t need personal cursor; default hyprland cursor is fine.”
- VIRTUAL_ENV duplicate dropped after review: upstream Lua already sets the same default path.
- Apply must **fail if `general.lua` is missing** so a cold machine cannot silently boot the wrong layout. Empty slot files may warn-and-continue.
- Preferred home for the layer: **`.config/hypr/custom/`** (parent repo).
- Selected **documented apply after install** (not stow/symlink, not pre-seed live).
- First 2026-08-17 discussion auto-locked several areas when operator asked to continue to plan-phase; this 2026-08-19 update re-discussed remaining discretion and then trimmed env/cursor against the simple/default + new-machine bar.

</specifics>

<deferred>
## Deferred Ideas

- Phase 14: run the documented apply onto live; pre-flight D-07; live `--full` adopt; chrome accept-remove; optionally fold apply into one install-then-apply operator command
- Phase 15: playbook DOC-04 for overlay SoT + apply
- Reopening D-16 to drop overlays entirely — considered earlier, rejected; content now narrowed to monitors + pins
- Stow/symlink live custom/ to repo — rejected
- Pre-seed live custom/ before full install — rejected
- nwg-displays `hypr/monitors.lua` + `hypr/workspaces.lua` as SoT — rejected
- Wrapper `--full` changes or apply subcommand — not this phase
- Personal cursor overlay — dropped for now; do not sneak back in
- `ILLOGICAL_IMPULSE_VIRTUAL_ENV` in `custom/env.lua` — dropped; do not sneak back in
- CUST-01..04, CUT-01 as a separate bar project
- Existing untracked `13-01-PLAN.md` / `13-02-PLAN.md` / `13-03-PLAN.md` were planned against the 2026-08-17 CONTEXT + research (cursor, VIRTUAL_ENV, `test -s` empty files, setcursor). They are **not executed** (no SUMMARY.md). Replan after this CONTEXT; do not execute those plans as-is.

None of the above expand Phase 13 beyond repo overlays + SoT/apply rule.

</deferred>

---

*Phase: 13-Personal hypr/custom overlays*
*Context gathered: 2026-08-19*
*Interactive discuss: 2026-08-17 SoT + 2026-08-19 update (cursor/venv dropped; apply fail-on-missing-general.lua)*
