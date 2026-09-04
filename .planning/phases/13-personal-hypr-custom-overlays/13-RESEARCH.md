# Phase 13: Personal hypr/custom overlays - Research

**Researched:** 2026-08-17
**Domain:** dots-hyprland `hypr/custom` Lua overlays — D-16 monitors / workspace pins / env; repo vs live vs fork SoT
**Confidence:** HIGH (in-repo require contract, seeds, ignore_existing, personal conf values all Read this session; workspace-pin + monitor `transform` APIs confirmed via official Hyprland wiki Lua examples)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Overlay SoT (OVL-03)
- **D-01:** Authoring SoT is parent-repo **`.config/hypr/custom/`**. Live `~/.config/hypr/custom/` is an applied copy, not the place you edit for the next machine. Vendor/submodule remains product SoT. — **Reversibility:** costly — Phase 14 apply + Phase 15 DOC-04 and cold-machine path all cite this tree
- **D-02:** Cold-machine apply is a **documented apply-after-install** step: after ii seeds or `ignore_existing` on `hypr/custom`, copy/rsync repo `.config/hypr/custom/` onto live `~/.config/hypr/custom/`. Phase 13 writes the files and the rule; Phase 14 runs the apply. No wrapper rewrite and no fork commits for apply. — **Reversibility:** costly — Phase 14 adopt sequence depends on this order
- **D-03:** Apply is **one-way repo → live**. Persist a live tweak by copying it back into repo `.config/hypr/custom/` (operator discipline). No sync daemon. — **Reversibility:** reversible
- **D-04:** **Never** commit these machine overlays into `vendor/dots-hyprland` or the personal fork. Fork stays product; parent `.config/hypr/custom/` is the personal layer. — **Reversibility:** costly — mixing SoT would couple pin-bumps to machine layout

#### Monitor / workspace file slot
- **D-05:** All D-16 content lives under **`hypr/custom/`** slots that `hyprland.lua` actually requires — not `~/.config/hypr/monitors.lua` / `workspaces.lua` (those are optional nwg-displays root files, outside `custom/`). — **Reversibility:** costly — SoT path and apply source are this directory
- **D-06:** **Env** → `custom/env.lua`. **Monitors + workspace pins** → `custom/general.lua` (upstream `hyprland/general.lua` already uses `hl.monitor({...})`; custom general is required after it). Cursor `hyprctl setcursor` (if still needed beyond env vars) → `custom/execs.lua` as part of the env/cursor must-keep, **not** as D-17 autostart. Do not add `custom/keybinds.lua` or `custom/rules.lua` content this phase. — **Reversibility:** reversible — file split inside `custom/` is local
- **D-07:** Do **not** treat nwg-displays root `monitors.lua` / `workspaces.lua` as SoT. If research proves `custom/general.lua` cannot express workspace-to-monitor pins, stop and record the gap — do not silently switch SoT to hypr-root files.

#### Env overlay contents
- **D-08:** `custom/env.lua` **does** set cursor (`XCURSOR_THEME=Catppuccin-Mocha-Dark-Cursors`, `XCURSOR_SIZE=30`) **and** `ILLOGICAL_IMPULSE_VIRTUAL_ENV=~/.local/state/quickshell/.venv`. Keep D-16 even though upstream `hyprland/env.lua` already sets the same venv path — overlay must be self-contained after personal `hyprland.conf` becomes `.old` and Phase 12 conf-hooks no longer apply. Duplicate identical env is acceptable. — **Reversibility:** reversible
- **D-09:** Source values from repo `.config/hypr/hyprland.conf` (monitors ~29–30, workspaces ~76–87, env ~106–111). Do not invent new monitors, pins, or theme names.

#### Prep vs apply timing (OVL-02)
- **D-10:** **Write the real overlay files in the repo this phase.** OVL-02 is satisfied by committed repo files existing before Phase 14, not by a checklist-only gate. — **Reversibility:** reversible
- **D-11:** **No live `~/.config` mutation this phase.** Do not pre-seed live custom/ to win `ignore_existing`. Apply is Phase 14 after full files install. — **Reversibility:** one-way if violated — live mutation before adopt is Phase 14’s job and would skip the process gate
- **D-12:** Phase 13 also writes the **SoT + apply rule** (short committed note in phase dir or overlay-adjacent README/comment as planner chooses) so Phase 14/15 do not invent policy. Full playbook prose is Phase 15 DOC-04.

#### Locked carry-forward (do not reopen)
- **D-13:** Must-migrate set remains Phase 11 **D-16 only**: monitors (DP-1 / HDMI-A-2), workspace layout pins, env (cursor + `ILLOGICAL_IMPULSE_VIRTUAL_ENV`). Autostart apps, personal tool binds, chrome exec-once stay **dropped** (Phase 11 D-17). `hypr/custom/` may take the ii empty seed; we populate only D-16 (Phase 11 D-20).

### Claude's Discretion
- Exact Hyprland Lua table fields for `hl.monitor` / workspace pins (match personal conf semantics)
- Exact apply command (`cp -a` vs `rsync -a`) and whether it overwrites empty ii seed files
- Whether `setcursor` is required in `custom/execs.lua` or env vars suffice
- Whether `ILLOGICAL_IMPULSE_VIRTUAL_ENV` in `custom/env.lua` can be omitted later if adopt proves upstream `hyprland/env.lua` always loads first — default is **keep it** (D-08)
- Filename comments / tiny SoT note shape (D-12)
- Light assert/lint that repo custom files exist and do not contain D-17 binds/autostart

### Deferred Ideas (OUT OF SCOPE)
- Phase 14: run the documented apply onto live; pre-flight D-07; live `--full` adopt; chrome accept-remove
- Phase 15: playbook DOC-04 for overlay SoT + apply
- Reopening D-16 to drop overlays entirely — considered, then rejected by operator
- Stow/symlink live custom/ to repo — rejected
- Pre-seed live custom/ before full install — rejected
- nwg-displays `hypr/monitors.lua` + `hypr/workspaces.lua` as SoT — rejected unless `custom/general.lua` cannot express pins (D-07 gap)
- Wrapper `--full` changes or apply subcommand — not this phase
- CUST-01..04, CUT-01 as a separate bar project

None of the above expand Phase 13 beyond repo overlays + SoT/apply rule.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| OVL-01 | D-16 must-keeps expressed as `hypr/custom` Lua compatible with `hyprland.lua` requires | Write `custom/env.lua`, `custom/general.lua` (`hl.monitor` + `hl.workspace_rule`), `custom/execs.lua` (`setcursor` only). D-07 gap is **not** real. |
| OVL-02 | Overlay prep done (or checklist-gated) **before** first live full hypr files that need those must-keeps | D-10: commit the real repo files this phase. Do **not** apply live (D-11). |
| OVL-03 | Repo vs live vs fork SoT written and followed for committed overlays | Phase-dir SoT/apply note + file headers. Never commit into vendor/fork (D-04). |
</phase_requirements>

## Summary

Phase 13 is a **repo-only config authoring** job. There is no wrapper change, no vendor/fork commit, and no live `~/.config` mutation. Parent-repo `.config/hypr/custom/` is currently **ABSENT**. The planner must create three Lua files that `hyprland.lua` actually `require`s, plus a short committed SoT/apply note for Phases 14–15.

**Require-order correction vs CONTEXT.md canonical_refs:** CONTEXT claimed `custom.env` then hyprland defaults then `custom.general` / `custom.execs`. The live file is the opposite for env and interleaves defaults before custom overlays:

1. `hyprland.lib` + `hyprland.services` (services include seed-on-start)
2. `hyprland.env` **then** `custom.env` (if the file exists)
3. `hyprland.execs` + `hyprland.general` + rules/colors/keybinds
4. `custom.execs` **then** `custom.general` (if those files exist)
5. Optional root `workspaces.lua` / `monitors.lua` (nwg-displays — **not** SoT)
6. `hyprland.shellOverrides.main`

Because `custom.env` / `custom.general` / `custom.execs` load **after** the matching hyprland defaults, overlays override. Duplicate `ILLOGICAL_IMPULSE_VIRTUAL_ENV` is therefore correct (D-08). Additional `hl.monitor` calls in `custom/general.lua` run after the generic `output=""` default. `hl.workspace_rule({ workspace = "...", monitor = "..." })` is a first-class Hyprland Lua API — call it from `custom/general.lua` (D-06 slot). **Do not** switch SoT to root `monitors.lua` / `workspaces.lua`. **D-07 gap is closed: no stop.**

`install_dir__ignore_existing` no-ops if live `~/.config/hypr/custom` already exists, and seeds vendor stubs only when the directory is absent. After a first full install those stubs are empty (or, for vendor `keybinds.lua`, a single edit-keybinds bind). Phase 14 must **overwrite** `env.lua` / `general.lua` / `execs.lua` from the repo. Phase 13 only writes the files and the rule.

**Primary recommendation:** Create parent-repo `.config/hypr/custom/{env,general,execs}.lua` with D-16 values copied from `.config/hypr/hyprland.conf` lines 29–30, 76–87, 106–111; include `hyprctl setcursor catppuccin-mocha-dark-cursors 30` in `execs.lua` because upstream `hyprland/execs.lua` sets Bibata 24 first; write `.planning/phases/13-personal-hypr-custom-overlays/13-SOT-APPLY.md` documenting one-way `cp -a` of those three files after install; assert the three files exist and contain none of the D-17 autostart/bind strings.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Author D-16 Lua overlays | Parent repo `.config/hypr/custom/` | — | D-01 authoring SoT |
| Product hypr session / require contract | `vendor/dots-hyprland` `hyprland.lua` + `hyprland/*` | — | D-01 / D-04 product SoT |
| Seed empty custom slots on first install | `install_dir__ignore_existing` + `create_custom_config.lua` | — | Only if live dir/files absent |
| Apply overlays onto live | Phase 14 operator step (documented here) | — | D-02 / D-11 |
| SoT + apply policy text | Phase-dir `13-SOT-APPLY.md` | file-header comments | D-12; Phase 15 DOC-04 consumes |
| Playbook narrative | Phase 15 DOC-04 | this SoT note | Out of scope here |
| Wrapper `--full` | Phase 12 / `arch/dots-hyprland.sh` | — | Do not touch |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| dots-hyprland `hyprland.lua` + `hl.*` | vendor submodule pin (in-repo) | Require contract + `hl.env` / `hl.monitor` / `hl.workspace_rule` / `hl.on` / `hl.exec_cmd` | Already the session entry after full adopt |
| Personal `.config/hypr/hyprland.conf` | repo file | D-16 source values only | D-09 — do not invent |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `cp -a` (coreutils) | host | One-way apply of three overlay files | Documented apply command (Phase 14 runs it) |
| `hyprctl setcursor` | Hyprland | Runtime cursor after upstream Bibata 24 | `custom/execs.lua` on `hyprland.start` |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `custom/general.lua` `hl.workspace_rule` | Root `hypr/workspaces.lua` | **Rejected** (D-05 / D-07). API works in `custom/`. |
| `cp -a` three files | `rsync -a --delete` of whole `custom/` | `--delete` would remove live seed files we do not author (`keybinds.lua`, `rules.lua`, `variables.lua`). Do not use `--delete`. |
| `cp -a` three files | `rsync -a` without `--delete` | Equivalent. Prefer `cp -a` of the three named files — no extra tool, cannot delete siblings. |
| Env vars only for cursor | Skip `setcursor` | **Do not skip.** Upstream `hyprland/execs.lua` runs `hyprctl setcursor Bibata-Modern-Classic 24` before `custom.execs`. |
| Stow/symlink live → repo | Documented copy | **Rejected** in discuss. |

**Installation:** none. This phase installs no npm/pip/cargo/pacman packages.

**Version verification:** N/A — no new packages. In-repo APIs verified by Read this session.

## Package Legitimacy Audit

> No external packages are installed this phase.

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| — | — | — | — | — | — | No packages |

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Project Constraints (from CLAUDE.md)

No `./CLAUDE.md` or `./.claude/CLAUDE.md` exists in the project root. No additional project-instruction constraints.

## Architecture Patterns

### System Architecture Diagram

```
[personal hyprland.conf D-16 lines]
        |
        | extract (this phase, repo only)
        v
[.config/hypr/custom/env.lua] ---- hl.env after hyprland.env
[.config/hypr/custom/general.lua] - hl.monitor + hl.workspace_rule after hyprland.general
[.config/hypr/custom/execs.lua] --- hyprctl setcursor after hyprland.execs Bibata 24
[.planning/phases/13-.../13-SOT-APPLY.md]
        |
        | Phase 14 (NOT this phase)
        v
[full install] --ignore_existing--> live ~/.config/hypr/custom/ (ii seeds if ABSENT)
        |
        | documented cp -a of the three files
        v
[live custom/{env,general,execs}.lua] --required by--> hyprland.lua
        |
        x never --> vendor/dots-hyprland or personal fork
```

### Recommended Project Structure

```
.config/hypr/custom/                 # created this phase; authoring SoT
├── env.lua                          # D-08 cursor env + ILLOGICAL_IMPULSE_VIRTUAL_ENV
├── general.lua                      # D-16 monitors + workspace pins
└── execs.lua                        # setcursor only — no D-17 exec-once
.planning/phases/13-personal-hypr-custom-overlays/
└── 13-SOT-APPLY.md                  # D-12 SoT + apply rule
```

Do **not** create repo `custom/keybinds.lua` or `custom/rules.lua`. Do **not** copy vendor `custom/keybinds.lua` (it is not empty).

### Pattern 1: hyprland.lua require contract

**What:** Overlay modules load only if the file exists, and they load after the matching hyprland default (except env, which also loads after `hyprland.env`).
**When to use:** Always — this is the compatibility contract for OVL-01.
**Example:**

```lua
-- Source: vendor/dots-hyprland/dots/.config/hypr/hyprland.lua:8-41
-- Environment variables --
require("hyprland.env")
if is_file_exists(HOME .. "/.config/hypr/custom/env.lua") then
    require("custom.env")
end
-- Default configurations --
require("hyprland.execs")
require("hyprland.general")
-- Custom configurations --
if is_file_exists(HOME .. "/.config/hypr/custom/execs.lua") then
    require("custom.execs")
end
if is_file_exists(HOME .. "/.config/hypr/custom/general.lua") then
    require("custom.general")
end
-- nwg-displays support --
if is_file_exists(HOME .. "/.config/hypr/workspaces.lua") then
    require("workspaces")
end
if is_file_exists(HOME .. "/.config/hypr/monitors.lua") then
    require("monitors")
end
```

[VERIFIED: vendor/dots-hyprland/dots/.config/hypr/hyprland.lua:8-41]

### Pattern 2: Dual-head monitors after the generic default

**What:** Upstream `hyprland/general.lua` registers one catch-all monitor. Personal dual-head is additional `hl.monitor` calls in `custom/general.lua`.
**When to use:** D-16 monitors.

```lua
-- Source: vendor/dots-hyprland/dots/.config/hypr/hyprland/general.lua:1-7
hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = 1
})
```

[VERIFIED: vendor/dots-hyprland/dots/.config/hypr/hyprland/general.lua:1-7]

Personal source:

```
monitor=DP-1,preferred,auto,auto
monitor=HDMI-A-2,preferred,auto,1.5,transform,1
```

[VERIFIED: .config/hypr/hyprland.conf:29-30]

Prescribe (discretion fields match conf semantics; `transform` is official Lua):

```lua
-- Source: hyprland-wiki Configuring/Monitors (hl.monitor transform example)
hl.monitor({ output = "DP-1", mode = "preferred", position = "auto", scale = "auto" })
hl.monitor({ output = "HDMI-A-2", mode = "preferred", position = "auto", scale = 1.5, transform = 1 })
```

[CITED: /hyprwm/hyprland-wiki Configuring/Monitors — `hl.monitor({ output = "eDP-1", mode = "2880x1800@90", position = "0x0", scale = 1, transform = 1 })`]

`scale = "auto"` for DP-1 is the string from conf field 4. Wiki examples use a number. If the Lua binding rejects a string, use `scale = 1` (same as upstream default) — do not invent a third monitor or a new scale. [ASSUMED] type-coercion of `"auto"`; planner must add a verify that the file still contains `output = "DP-1"` and `output = "HDMI-A-2"`.

### Pattern 3: Workspace-to-monitor pins via `hl.workspace_rule` in `custom/general.lua`

**What:** Official Hyprland Lua API binds a workspace to a monitor. Call it from `custom/general.lua` so SoT stays under `custom/` (D-05/D-06). **D-07 gap is not triggered.**
**When to use:** D-16 workspace layout pins.

```lua
-- Source: hyprland-wiki Configuring/Workspace-Rules
hl.workspace_rule({ workspace = "name:coding", no_rounding = true, decorate = false, gaps_in = 0, gaps_out = 0, no_border = true, monitor = "DP-1" })
hl.workspace_rule({ workspace = "name:Hello", monitor = "DP-1", default = true })
```

[CITED: /hyprwm/hyprland-wiki Configuring/Workspace-Rules]

In-repo proof the same function is already used (gaps only):

```lua
hl.workspace_rule({ workspace = "special:special", gaps_out = 30 })
```

[VERIFIED: vendor/dots-hyprland/dots/.config/hypr/hyprland/rules.lua:84]

Personal source (do not add `default` — conf does not have it):

```
workspace = 1,monitor:DP-1
workspace = 2,monitor:DP-1
workspace = 3,monitor:DP-1
workspace = 4,monitor:DP-1
workspace = 5,monitor:DP-1
workspace = special:social,monitor:DP-1

workspace = 6,monitor:HDMI-A-2
workspace = 7,monitor:HDMI-A-2
workspace = 8,monitor:HDMI-A-2
workspace = 9,monitor:HDMI-A-2
workspace = 10,monitor:HDMI-A-2
```

[VERIFIED: .config/hypr/hyprland.conf:76-87]

Prescribe:

```lua
hl.workspace_rule({ workspace = "1", monitor = "DP-1" })
hl.workspace_rule({ workspace = "2", monitor = "DP-1" })
hl.workspace_rule({ workspace = "3", monitor = "DP-1" })
hl.workspace_rule({ workspace = "4", monitor = "DP-1" })
hl.workspace_rule({ workspace = "5", monitor = "DP-1" })
hl.workspace_rule({ workspace = "special:social", monitor = "DP-1" })
hl.workspace_rule({ workspace = "6", monitor = "HDMI-A-2" })
hl.workspace_rule({ workspace = "7", monitor = "HDMI-A-2" })
hl.workspace_rule({ workspace = "8", monitor = "HDMI-A-2" })
hl.workspace_rule({ workspace = "9", monitor = "HDMI-A-2" })
hl.workspace_rule({ workspace = "10", monitor = "HDMI-A-2" })
```

### Pattern 4: Env overlay (self-contained after conf → `.old`)

**What:** `hl.env` after `hyprland.env`. Keep venv even though upstream already sets it.
**When to use:** D-08.

Upstream:

```lua
hl.env("ILLOGICAL_IMPULSE_VIRTUAL_ENV", home_dir .. "/.local/state/quickshell/.venv")
```

[VERIFIED: vendor/dots-hyprland/dots/.config/hypr/hyprland/env.lua:16]

Personal source:

```
exec-once = hyprctl setcursor catppuccin-mocha-dark-cursors 30
env = XCURSOR_THEME,Catppuccin-Mocha-Dark-Cursors
env = XCURSOR_SIZE,30
env = ILLOGICAL_IMPULSE_VIRTUAL_ENV,~/.local/state/quickshell/.venv
```

[VERIFIED: .config/hypr/hyprland.conf:106-111]

Prescribe `custom/env.lua`:

```lua
hl.env("XCURSOR_THEME", "Catppuccin-Mocha-Dark-Cursors")
hl.env("XCURSOR_SIZE", "30")
hl.env("ILLOGICAL_IMPULSE_VIRTUAL_ENV", os.getenv("HOME") .. "/.local/state/quickshell/.venv")
```

### Pattern 5: Cursor override in `custom/execs.lua`

**What:** Upstream start hook sets Bibata 24. Custom start hook must run later and set the personal cursor. Env vars alone do not undo `hyprctl setcursor`.
**When to use:** always this phase (discretion resolved: **include setcursor**).

```lua
hl.exec_cmd("hyprctl setcursor Bibata-Modern-Classic 24")
```

[VERIFIED: vendor/dots-hyprland/dots/.config/hypr/hyprland/execs.lua:24]

Prescribe `custom/execs.lua` (match conf line 106; do **not** re-add `qs -c ii` or D-17 apps):

```lua
hl.on("hyprland.start", function()
    hl.exec_cmd("hyprctl setcursor catppuccin-mocha-dark-cursors 30")
end)
```

`hyprland.execs` is required at line 15; `custom.execs` at lines 22–24 — custom start handlers register after upstream and fire after Bibata. [VERIFIED: vendor/dots-hyprland/dots/.config/hypr/hyprland.lua:15-24]

### Pattern 6: ignore_existing + seed-on-start (why apply-after-install)

**What:** First full install seeds `~/.config/hypr/custom` only if the directory is absent. A later start creates missing files with a comment header. Neither path copies parent-repo overlays.
**When to use:** SoT note must tell Phase 14 to overwrite the three files after install.

```
    install_dir__ignore_existing "dots/.config/hypr/custom" "${XDG_CONFIG_HOME}/hypr/custom"
```

[VERIFIED: vendor/dots-hyprland/sdata/subcmd-install/3.files-legacy.sh:75]

```
function install_dir__ignore_existing(){
  local s=$1
  local t=$2
  if [ -d $t ];then
    echo -e "${STY_BLUE}[$0]: \"$t\" already exists, will not do anything.${STY_RST}"
  else
    echo -e "${STY_YELLOW}[$0]: \"$t\" does not exist yet.${STY_RST}"
    v rsync_dir__ignore_existing $s $t
  fi
}
```

[VERIFIED: vendor/dots-hyprland/sdata/subcmd-install/3.files.sh:150-159]

Seed file list on `hyprland.start`:

```
      baseCustomDir .. "/env.lua",
      baseCustomDir .. "/execs.lua",
      baseCustomDir .. "/general.lua",
      baseCustomDir .. "/keybinds.lua",
      baseCustomDir .. "/rules.lua",
      baseCustomDir .. "/variables.lua"
```

[VERIFIED: vendor/dots-hyprland/dots/.config/hypr/hyprland/services/create_custom_config.lua:10-16]

Header written into missing files:

```
-- This file will not be overwritten across dots-hyprland updates.
```

[VERIFIED: vendor/dots-hyprland/dots/.config/hypr/hyprland/lib/init.lua:16]

Vendor seed contents today: `env.lua` / `execs.lua` / `general.lua` / `rules.lua` / `variables.lua` are blank or a single newline. `keybinds.lua` is **not** empty:

```
hl.bind("CTRL+SUPER+ALT+Slash", hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"), {description = "Edit user keybinds"} )
```

[VERIFIED: vendor/dots-hyprland/dots/.config/hypr/custom/keybinds.lua:1]

Do **not** copy that bind into the parent repo (D-06 / D-13).

### Pattern 7: SoT + apply note (D-12)

**What:** One short committed markdown in the phase directory. Phase 14 runs the command; Phase 15 DOC-04 cites it.
**When to use:** required this phase.

Recommended path: `.planning/phases/13-personal-hypr-custom-overlays/13-SOT-APPLY.md`

Required statements (planner must include these exact policies, wording may vary):

1. Authoring SoT = parent-repo `.config/hypr/custom/`.
2. Live `~/.config/hypr/custom/` is an applied copy.
3. Vendor / personal fork is product SoT — never commit these machine overlays there.
4. Apply is one-way repo → live, after full files install (ii may have seeded empty files).
5. Apply command (discretion, prescribed):

```bash
# Run from the parent repo root AFTER full hypr files install. Phase 14 executes this.
# Overwrites ii seed env/general/execs. Does not delete keybinds.lua / rules.lua / variables.lua.
cp -a .config/hypr/custom/env.lua \
      .config/hypr/custom/general.lua \
      .config/hypr/custom/execs.lua \
      "${XDG_CONFIG_HOME:-$HOME/.config}/hypr/custom/"
```

6. Persist a live tweak by copying the file back into the repo. No sync daemon.

Also put a one-line header in each Lua file: `Authoring SoT: parent-repo .config/hypr/custom/ (see 13-SOT-APPLY.md). Do not commit into vendor/dots-hyprland.`

### Anti-Patterns to Avoid

- **Root `monitors.lua` / `workspaces.lua` as SoT:** violates D-05/D-07. API works in `custom/general.lua`.
- **Copying vendor `custom/` wholesale into the parent repo:** pulls `keybinds.lua` (D-17-adjacent bind) and empty stubs we do not own.
- **`rsync -a --delete`:** deletes live seed files we do not author.
- **Writing live `~/.config` this phase:** D-11 one-way if violated.
- **Re-adding `qs -c ii` or Chrome/kitty/btop/discord exec-once in `custom/execs.lua`:** D-13 / D-17 drop. Upstream already runs `qs -c $qsConfig`.
- **Committing overlays into `vendor/dots-hyprland`:** D-04.
- **Checklist-only OVL-02:** D-10 requires real repo files.
- **Changing `arch/dots-hyprland.sh`:** Phase 12 / out of scope.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Monitor / workspace Lua DSL | New parser or hypr-root files | `hl.monitor` + `hl.workspace_rule` | Already the ii contract |
| Apply / sync engine | Wrapper subcommand, stow, daemon | Documented `cp -a` of three files | D-02 / D-03 |
| Session chrome | custom execs for qs/waybar | Upstream `hyprland/execs.lua` | D-13 |
| Overlay product | Extra custom fluff | D-16 only | Operator does not want a personal hypr product |

**Key insight:** ii already has the overlay slots. Phase 13 only fills three of them with values that already exist in `hyprland.conf`.

## Runtime State Inventory

This phase migrates **values** from personal conf into new repo files. It does not rename a running product. Inventory is included because adopt later replaces the live session entry.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | Repo `.config/hypr/hyprland.conf` D-16 lines 29–30, 76–87, 106–111 | Copy into new Lua files; do not edit conf this phase |
| Live service config | Live `~/.config/hypr/custom/` not touched this phase (D-11) | None this phase; Phase 14 apply |
| OS-registered state | None — no systemd/user units authored here | None |
| Secrets/env vars | Cursor theme/size + `ILLOGICAL_IMPULSE_VIRTUAL_ENV` (not secrets) | Write into `custom/env.lua` |
| Build artifacts | Parent-repo `.config/hypr/custom/` currently ABSENT | Create three files |

**Nothing found in category:** OS-registered state — none (verified: this phase only adds repo Lua + a markdown note).

## Common Pitfalls

### Pitfall 1: Trusting CONTEXT.md require-order prose
**What goes wrong:** Planner writes as if `custom.env` loads before `hyprland.env`.
**Why it happens:** CONTEXT canonical_refs summarize the order incorrectly.
**How to avoid:** Follow `hyprland.lua` lines 8–33. Custom loads **after** defaults. Overrides still work.
**Warning signs:** Comments claiming custom env is the first env source.

### Pitfall 2: Treating D-07 as a stop
**What goes wrong:** Planner switches SoT to root `workspaces.lua` or blocks the phase.
**Why it happens:** No `hl.workspace()` sibling exists in-repo; only `hl.workspace_rule`.
**How to avoid:** Use `hl.workspace_rule({ workspace = "...", monitor = "..." })` in `custom/general.lua`. Official wiki documents the `monitor` field.
**Warning signs:** New `hypr/workspaces.lua` in `files_modified`.

### Pitfall 3: Applying or pre-seeding live custom/ now
**What goes wrong:** Live dir exists before full install → `ignore_existing` no-ops; or adopt skips the process gate.
**Why it happens:** Wanting overlays “already there.”
**How to avoid:** D-11. Repo files only. Phase 14 apply after full files.
**Warning signs:** Tasks that `cp` into `$HOME/.config`.

### Pitfall 4: `rsync --delete` or copying the whole vendor custom tree
**What goes wrong:** Wipes `keybinds.lua` / `rules.lua` / `variables.lua`, or imports the vendor edit-keybinds bind.
**Why it happens:** “Sync the directory.”
**How to avoid:** `cp -a` the three authored files only.
**Warning signs:** `--delete` in the SoT note; repo `custom/keybinds.lua`.

### Pitfall 5: D-17 leakage into `execs.lua`
**What goes wrong:** Chrome, kitty, btop, vesktop/discord, `qs -c ii`, waybar, swaync land in custom execs.
**Why it happens:** Copy-paste from `hyprland.conf` autostart block (lines 55–99).
**How to avoid:** `execs.lua` may contain **only** `hyprctl setcursor catppuccin-mocha-dark-cursors 30` (plus `hl.on` wrapper / comments). Grep-fail on `google-chrome`, `kitty`, `btop`, `vesktop`, `discord`, `waybar`, `swaync`, `qs -c ii`.
**Warning signs:** Those strings in `.config/hypr/custom/`.

### Pitfall 6: Skipping `setcursor` because env vars exist
**What goes wrong:** Session keeps Bibata 24 from `hyprland/execs.lua:24`.
**Why it happens:** D-08 env looks sufficient.
**How to avoid:** Always write the setcursor start hook. Env still required (XCURSOR_* for apps).
**Warning signs:** `execs.lua` missing or empty.

### Pitfall 7: Committing into vendor / fork
**What goes wrong:** Machine layout rides on pin-bumps (D-04).
**Why it happens:** Editing the file that already lives under `vendor/dots-hyprland/dots/.config/hypr/custom/`.
**How to avoid:** Create **parent-repo** `.config/hypr/custom/`. `files_modified` must not include `vendor/`.
**Warning signs:** `git status` under `vendor/dots-hyprland`.

### Pitfall 8: First-start seed vs require race (Phase 14, document only)
**What goes wrong:** `create_custom_config.lua` creates missing files on `hyprland.start` **after** `hyprland.lua` already decided `require` (reload is commented out).
**Why it happens:** Seeds happen at start, requires happen at load.
**How to avoid:** Phase 14 apply **before** the first session that must show dual-head — or reload after apply. Mention in SoT note. Do not “fix” by writing a wrapper hook this phase.
**Warning signs:** Plan tasks that edit `create_custom_config.lua`.

## Code Examples

### custom/env.lua (complete target)

```lua
-- Authoring SoT: parent-repo .config/hypr/custom/ (see 13-SOT-APPLY.md). Do not commit into vendor/dots-hyprland.
-- Values from .config/hypr/hyprland.conf:107-111
hl.env("XCURSOR_THEME", "Catppuccin-Mocha-Dark-Cursors")
hl.env("XCURSOR_SIZE", "30")
hl.env("ILLOGICAL_IMPULSE_VIRTUAL_ENV", os.getenv("HOME") .. "/.local/state/quickshell/.venv")
```

### custom/general.lua (complete target)

```lua
-- Authoring SoT: parent-repo .config/hypr/custom/ (see 13-SOT-APPLY.md). Do not commit into vendor/dots-hyprland.
-- Monitors from .config/hypr/hyprland.conf:29-30
hl.monitor({ output = "DP-1", mode = "preferred", position = "auto", scale = "auto" })
hl.monitor({ output = "HDMI-A-2", mode = "preferred", position = "auto", scale = 1.5, transform = 1 })

-- Workspace pins from .config/hypr/hyprland.conf:76-87
hl.workspace_rule({ workspace = "1", monitor = "DP-1" })
hl.workspace_rule({ workspace = "2", monitor = "DP-1" })
hl.workspace_rule({ workspace = "3", monitor = "DP-1" })
hl.workspace_rule({ workspace = "4", monitor = "DP-1" })
hl.workspace_rule({ workspace = "5", monitor = "DP-1" })
hl.workspace_rule({ workspace = "special:social", monitor = "DP-1" })
hl.workspace_rule({ workspace = "6", monitor = "HDMI-A-2" })
hl.workspace_rule({ workspace = "7", monitor = "HDMI-A-2" })
hl.workspace_rule({ workspace = "8", monitor = "HDMI-A-2" })
hl.workspace_rule({ workspace = "9", monitor = "HDMI-A-2" })
hl.workspace_rule({ workspace = "10", monitor = "HDMI-A-2" })
```

### custom/execs.lua (complete target)

```lua
-- Authoring SoT: parent-repo .config/hypr/custom/ (see 13-SOT-APPLY.md). Do not commit into vendor/dots-hyprland.
-- Overrides hyprland/execs.lua Bibata 24. Not D-17 autostart.
hl.on("hyprland.start", function()
    hl.exec_cmd("hyprctl setcursor catppuccin-mocha-dark-cursors 30")
end)
```

### Apply command (SoT note)

```bash
cp -a .config/hypr/custom/env.lua \
      .config/hypr/custom/general.lua \
      .config/hypr/custom/execs.lua \
      "${XDG_CONFIG_HOME:-$HOME/.config}/hypr/custom/"
```

### Light assert / lint (discretion — planner should put these in `<verify>`)

```bash
test -f .config/hypr/custom/env.lua
test -f .config/hypr/custom/general.lua
test -f .config/hypr/custom/execs.lua
test -f .planning/phases/13-personal-hypr-custom-overlays/13-SOT-APPLY.md
# D-16 present
grep -q 'XCURSOR_THEME' .config/hypr/custom/env.lua
grep -q 'ILLOGICAL_IMPULSE_VIRTUAL_ENV' .config/hypr/custom/env.lua
grep -q 'DP-1' .config/hypr/custom/general.lua
grep -q 'HDMI-A-2' .config/hypr/custom/general.lua
grep -q 'special:social' .config/hypr/custom/general.lua
grep -q 'setcursor catppuccin-mocha-dark-cursors 30' .config/hypr/custom/execs.lua
# D-17 / chrome must be absent
! grep -Eiq 'google-chrome|vesktop|discord|waybar|swaync|qs -c ii' .config/hypr/custom/*.lua
# SoT fence
! git -C vendor/dots-hyprland diff --quiet -- dots/.config/hypr/custom || true
# stronger: vendor custom must be clean
git -C vendor/dots-hyprland status --short -- dots/.config/hypr/custom | test -z "$(cat)"
```

## Validation Architecture

> `workflow.nyquist_validation` is **true** in `.planning/config.json` — this section is required.
> **No live apply and no live full install this phase.** All automated checks are repo file existence / content greps.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Inline bash asserts (Phase 6/12 pattern) — no bats/pytest suite in repo |
| Config file | none — plan-task `<verify><automated>` commands |
| Quick run command | `test -f .config/hypr/custom/env.lua && test -f .config/hypr/custom/general.lua && test -f .config/hypr/custom/execs.lua && test -f .planning/phases/13-personal-hypr-custom-overlays/13-SOT-APPLY.md` |
| Full suite command | Quick run + D-16 presence greps + D-17 absence greps + vendor-clean check (cheatsheet below) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| OVL-01 | Three custom Lua files express D-16 (monitors, pins, env, setcursor) | smoke | `grep -q 'DP-1' .config/hypr/custom/general.lua && grep -q 'HDMI-A-2' .config/hypr/custom/general.lua && grep -q 'workspace_rule' .config/hypr/custom/general.lua && grep -q 'special:social' .config/hypr/custom/general.lua && grep -q 'XCURSOR_THEME' .config/hypr/custom/env.lua && grep -q 'ILLOGICAL_IMPULSE_VIRTUAL_ENV' .config/hypr/custom/env.lua && grep -q 'setcursor catppuccin-mocha-dark-cursors 30' .config/hypr/custom/execs.lua` | ❌ Wave 0 (files created this phase) |
| OVL-01b | Compatible require slots only (no root monitors.lua / workspaces.lua; no custom keybinds/rules content) | smoke (negative) | `test ! -e .config/hypr/monitors.lua && test ! -e .config/hypr/workspaces.lua && test ! -e .config/hypr/custom/keybinds.lua && test ! -e .config/hypr/custom/rules.lua` | ❌ Wave 0 |
| OVL-01c | No D-17 leakage | smoke (negative) | `! grep -Eiq 'google-chrome|vesktop|^[[:space:]]*.*discord|waybar|swaync|qs -c ii' .config/hypr/custom/*.lua` | ❌ Wave 0 |
| OVL-02 | Real repo files exist before Phase 14 (not checklist-only) | smoke | `test -s .config/hypr/custom/env.lua && test -s .config/hypr/custom/general.lua && test -s .config/hypr/custom/execs.lua` | ❌ Wave 0 |
| OVL-02b | No live `~/.config` mutation in this phase’s plans | review | Plan `files_modified` must not include `$HOME/.config` or `/home/*/ .config`. Executor must not `cp` to live. | N/A (plan gate) |
| OVL-03 | SoT + apply rule written | smoke | `test -s .planning/phases/13-personal-hypr-custom-overlays/13-SOT-APPLY.md && grep -q '.config/hypr/custom' .planning/phases/13-personal-hypr-custom-overlays/13-SOT-APPLY.md && grep -q 'cp -a' .planning/phases/13-personal-hypr-custom-overlays/13-SOT-APPLY.md` | ❌ Wave 0 |
| OVL-03b | Overlays not committed into vendor | smoke | `test -z "$(git -C vendor/dots-hyprland status --short -- dots/.config/hypr/custom)"` | ✅ vendor tree exists |
| D-08 | Cursor env + venv both present | grep | `grep -q 'Catppuccin-Mocha-Dark-Cursors' .config/hypr/custom/env.lua && grep -q 'XCURSOR_SIZE' .config/hypr/custom/env.lua` | ❌ Wave 0 |
| D-09 | No invented outputs | grep | `grep -E 'output = "' .config/hypr/custom/general.lua \| grep -Ev 'DP-1\|HDMI-A-2'` must be empty | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** existence of the file that task created + the task’s automated verify block
- **Per wave merge:** full OVL-01 / OVL-02 / OVL-03 suite
- **Phase gate:** full suite green before `/gsd-verify-work`; **no** live apply and **no** `install --full`

### Wave 0 Gaps

- [ ] Create `.config/hypr/custom/{env,general,execs}.lua` (currently ABSENT)
- [ ] Create `13-SOT-APPLY.md`
- [ ] Plan-task automated verify commands for the matrix above (inline; no dedicated test framework)
- [ ] **Do not** add live apply / session mutation checks this phase

### Concrete command cheatsheet (planner copy-paste)

```bash
test -s .config/hypr/custom/env.lua
test -s .config/hypr/custom/general.lua
test -s .config/hypr/custom/execs.lua
test -s .planning/phases/13-personal-hypr-custom-overlays/13-SOT-APPLY.md

grep -q 'Catppuccin-Mocha-Dark-Cursors' .config/hypr/custom/env.lua
grep -q 'ILLOGICAL_IMPULSE_VIRTUAL_ENV' .config/hypr/custom/env.lua
grep -q 'DP-1' .config/hypr/custom/general.lua
grep -q 'HDMI-A-2' .config/hypr/custom/general.lua
grep -q 'hl.workspace_rule' .config/hypr/custom/general.lua
grep -q 'special:social' .config/hypr/custom/general.lua
grep -q 'setcursor catppuccin-mocha-dark-cursors 30' .config/hypr/custom/execs.lua
grep -q 'cp -a' .planning/phases/13-personal-hypr-custom-overlays/13-SOT-APPLY.md

test ! -e .config/hypr/monitors.lua
test ! -e .config/hypr/workspaces.lua
test ! -e .config/hypr/custom/keybinds.lua
test ! -e .config/hypr/custom/rules.lua
! grep -Eiq 'google-chrome|vesktop|waybar|swaync|qs -c ii' .config/hypr/custom/*.lua
test -z "$(git -C vendor/dots-hyprland status --short -- dots/.config/hypr/custom)"
```

## Security Domain

> `security_enforcement` is enabled (ASVS level 1). Block on: high.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | N/A — local config files |
| V3 Session Management | no | N/A |
| V4 Access Control | partial | Overlays must not land in vendor/fork (D-04); live apply is Phase 14 only |
| V5 Input Validation | yes | Copy D-09 values verbatim; do not interpolate untrusted input into Lua |
| V6 Cryptography | no | N/A |
| Command injection | yes | `hl.exec_cmd` argument is a fixed `hyprctl setcursor …` string — no `eval`, no user concat |
| Privilege | yes | No sudo; no live `~/.config` writes this phase |

### Known Threat Patterns for machine-layout overlays

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Machine layout committed into vendor | Tampering | D-04; vendor-clean grep; `files_modified` excludes `vendor/` |
| Live mutation before adopt | Tampering | D-11; plans must not write `$HOME/.config` |
| D-17 / chrome reintroduced via execs | Elevation of dual-run | Negative grep on D-17 strings |
| `rsync --delete` wipes ii custom siblings | Tampering / Denial | Prescribe `cp -a` of three named files |
| Accidental root monitors.lua SoT | Tampering | D-05; negative `test ! -e` |
| Smoke/apply mutates live in Phase 13 | Tampering | Validation is repo greps only |

Planner **must** include a `<threat_model>` block in every PLAN.md (ASVS L1, block on high). Suggested IDs: T-13-01 vendor commit (high), T-13-02 live mutation (high), T-13-03 D-17 leakage (medium), T-13-04 delete-sync (medium), T-13-05 invented outputs (low).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Parent repo write to `.config/hypr/custom/` | OVL-01/02 | ✓ (dir currently ABSENT — create) | — | mkdir |
| `vendor/dots-hyprland` `hyprland.lua` contract | OVL-01 | ✓ submodule | pin | do not vendor-edit |
| `.config/hypr/hyprland.conf` | D-09 values | ✓ | repo | — |
| `cp` / coreutils | documented apply | ✓ host | — | — |
| Live Hyprland session / `hyprctl` | apply verification | N/A this phase | — | Phase 14 |
| Network / pacman | — | N/A | — | no packages |

**Missing dependencies with no fallback:** none for Phase 13 scope.

**Missing dependencies with fallback:** `scale = "auto"` Lua type — fallback `scale = 1` if binding requires a number.

## State of the Art

| Old Approach | Current Approach (Phase 13 target) | When Changed | Impact |
|--------------|-------------------------------------|--------------|--------|
| Personal `hyprland.conf` is session SoT | Conf becomes `.old` on full adopt; D-16 lives in `hypr/custom` Lua | Phase 11 D-15/D-16; executed Phase 13 | Cold machine = clone → full install → apply custom/ |
| No parent-repo `hypr/custom/` | Three Lua files + SoT note | Phase 13 | OVL-01/02/03 |
| CONTEXT require-order summary | Follow `hyprland.lua` (defaults then custom) | This research | Custom still overrides |
| nwg-displays root files as possible pin SoT | `hl.workspace_rule` in `custom/general.lua` | This research (D-07 closed) | No hypr-root files |

**Deprecated/outdated:**
- CONTEXT.md line claiming `custom.env` loads before `hyprland.env` — do not copy that order into plans
- CONTEXT.md “upstream empty seeds” for **all** custom files — `keybinds.lua` is not empty; do not copy it
- Checklist-only OVL-02 — rejected (D-10)

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `hl.monitor` accepts `scale = "auto"` as in conf | Pattern 2 | Low — fallback `scale = 1`; outputs still correct |
| A2 | `hl.workspace_rule` `monitor` field works when called from `custom/general.lua` (not only `rules.lua`) | Pattern 3 | Low — it is a global `hl.*` call; wiki does not file-gate it. If live adopt fails, Phase 14 records it — do not switch SoT in Phase 13. |
| A3 | `cp -a` of three files is the apply command Phase 14 will run | Pattern 7 | Low — equivalent `rsync -a` without `--delete` is acceptable; SoT note must name one |
| A4 | Custom `hyprland.start` handlers run after `hyprland/execs.lua` because they register later | Pattern 5 | Medium — if event order is not registration order, cursor may stay Bibata until reload. Still write the hook; Phase 14 can reload. |
| A5 | No dedicated `tests/` harness this phase | Validation Architecture | Low — matches Phases 6/12 |

## Open Questions

1. **`scale = "auto"` vs numeric**
   - What we know: conf uses `auto` for DP-1; wiki Lua examples use numbers
   - What's unclear: Lua binding type
   - Recommendation: write `"auto"` to match D-09; if executor hits a type error, change only that field to `1`

2. **Phase 14 apply timing vs first session**
   - What we know: requires happen at load; seeds happen on start; reload in `create_custom_config.lua` is commented out
   - What's unclear: whether operator will apply before first login
   - Recommendation: SoT note says apply after files install **and reload / re-login** before expecting dual-head. No wrapper work.

3. **Exact SoT filename**
   - What we know: D-12 allows phase-dir note or overlay-adjacent README/comment
   - Recommendation: `13-SOT-APPLY.md` in the phase dir (Phase 15 can find it next to CONTEXT) **plus** one-line file headers

**D-07 stop condition:** not triggered. Workspace-to-monitor pins are expressible in `custom/general.lua` via `hl.workspace_rule`.
