# Phase 13: Personal hypr/custom overlays - Pattern Map

**Mapped:** 2026-08-19
**Files analyzed:** 4
**Analogs found:** 4 / 4

**CONTEXT override (2026-08-19):** Overlay **content** is only `custom/general.lua` (`hl.monitor` + `hl.workspace_rule`). `custom/env.lua` and `custom/execs.lua` are committed **empty require slots** (no Lua statements). Do **not** copy RESEARCH Patterns 4–5 (`hl.env` / `setcursor`) or RESEARCH code examples for env/execs. Do **not** author root `monitors.lua` / `workspaces.lua`. Authoring SoT is parent-repo `.config/hypr/custom/` only.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.config/hypr/custom/general.lua` | config (session overlay) | transform (conf monitors/pins → `hl.*` after upstream general) | `vendor/dots-hyprland/dots/.config/hypr/hyprland/general.lua` + `hyprland/rules.lua` + value source `.config/hypr/hyprland.conf` | exact (API) + exact (values) |
| `.config/hypr/custom/env.lua` | config (empty require slot) | request-response (`hyprland.lua` optional `require("custom.env")`) | `vendor/dots-hyprland/dots/.config/hypr/custom/env.lua` | exact (empty seed) |
| `.config/hypr/custom/execs.lua` | config (empty require slot) | request-response (`require("custom.execs")`) | `vendor/dots-hyprland/dots/.config/hypr/custom/execs.lua` | exact (empty seed) |
| `.planning/phases/13-personal-hypr-custom-overlays/13-SOT-APPLY.md` | config (policy note) | file-I/O (document one-way `cp -a`; not executed this phase) | Phase-dir markdown (e.g. `12-PATTERNS.md` location) + `install_dir__ignore_existing` in `3.files.sh` | role-match |

Do **not** create: `custom/keybinds.lua`, `custom/rules.lua`, `custom/variables.lua`, `.config/hypr/monitors.lua`, `.config/hypr/workspaces.lua`. Do **not** modify `vendor/`.

## Pattern Assignments

### `.config/hypr/custom/general.lua` (config, transform)

**Analog (API):** `vendor/dots-hyprland/dots/.config/hypr/hyprland/general.lua` (monitors) and `hyprland/rules.lua` (workspace IDs as strings).

**Analog (values):** `.config/hypr/hyprland.conf` lines 29–30 and 76–87 only. Do not invent outputs, scales, transforms, or pins.

**Require contract** (`hyprland.lua` lines 15–27): `hyprland.general` then `custom.general` if the file exists. Additional `hl.monitor` calls overlay the generic `output=""`.

**Monitor table pattern** (`hyprland/general.lua` lines 1–7):

```lua
hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = 1
})
```

**Personal dual-head (copy field semantics from conf 29–30):**

```
monitor=DP-1,preferred,auto,auto
monitor=HDMI-A-2,preferred,auto,1.5,transform,1
```

**Prescribe (CONTEXT D-11 / D-12):**

```lua
hl.monitor({ output = "DP-1", mode = "preferred", position = "auto", scale = "auto" })
hl.monitor({ output = "HDMI-A-2", mode = "preferred", position = "auto", scale = 1.5, transform = 1 })
```

Verify **must** assert literal `scale = "auto"` on DP-1. If Lua write/verify rejects the string, change **only that field** to `1` and record the coercion in `13-SOT-APPLY.md`.

**Workspace ID string pattern** (`hyprland/rules.lua` line 84):

```lua
hl.workspace_rule({ workspace = "special:special", gaps_out = 30 })
```

Copy the **string-ID style** (`workspace = "special:social"`), **not** extra style fields. CONTEXT D-15: each rule is **monitor only** (no `default`, gaps, `no_rounding`, `no_border`).

**Personal pins (conf 76–87 exactly):**

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

**Optional one-line header** (discretion): `Authoring SoT: parent-repo .config/hypr/custom/ (see 13-SOT-APPLY.md). Do not commit into vendor/dots-hyprland.` Comments are not Lua statements that emit env/exec.

**Anti-patterns:** nwg-displays root files; copying `keybinds.lua` bind; D-17 strings (chrome, vesktop, discord, waybar, swaync, `qs -c ii`).

---

### `.config/hypr/custom/env.lua` (config, empty require slot)

**Analog:** `vendor/dots-hyprland/dots/.config/hypr/custom/env.lua` — blank / single newline, **no** `hl.env`.

**CONTEXT D-08 / D-09:** No `XCURSOR_*`. No `ILLOGICAL_IMPULSE_VIRTUAL_ENV`. Upstream `hyprland/env.lua` already sets the venv path. No `home_dir` local.

**Copy this emptiness:** file exists so `hyprland.lua` lines 10–12 can `require("custom.env")` after `hyprland.env`, and Phase 14 `cp -a` can overwrite ii seeds. 0-byte or a single newline so git tracks it. **No Lua statements.**

**Do not copy RESEARCH Pattern 4 / code example `custom/env.lua`.**

**Verify:** `test -f` only — **do not** `test -s` (CONTEXT D-19).

---

### `.config/hypr/custom/execs.lua` (config, empty require slot)

**Analog:** `vendor/dots-hyprland/dots/.config/hypr/custom/execs.lua` — blank / single newline.

**CONTEXT D-08:** No `hyprctl setcursor`. Upstream `hyprland/execs.lua` Bibata 24 is the intended cursor.

**Copy this emptiness:** exist for `hyprland.lua` lines 22–24 `require("custom.execs")`. **No** `hl.on` / `hl.exec_cmd`. **No** D-17 autostart.

**Do not copy RESEARCH Pattern 5 / setcursor `hl.on("hyprland.start", …)` example.**

**Verify:** `test -f` only — **not** `test -s`. Negative grep: no `setcursor`, no `XCURSOR_`, no `ILLOGICAL_IMPULSE_VIRTUAL_ENV`, no chrome/waybar/`qs -c ii`.

---

### `.planning/phases/13-personal-hypr-custom-overlays/13-SOT-APPLY.md` (config, file-I/O policy)

**Analog:** Phase-dir committed markdown next to CONTEXT (same pattern as Phase 12 artifacts). Apply **behavior** analog is `install_dir__ignore_existing` (`3.files.sh` lines 150–159): first full install seeds vendor `custom/` only if live dir is **absent**; later apply must overwrite named files.

```
    install_dir__ignore_existing "dots/.config/hypr/custom" "${XDG_CONFIG_HOME}/hypr/custom"
```

(`3.files-legacy.sh` line 75)

**Must include CONTEXT D-01..D-05 and D-18:**

1. Authoring SoT = parent-repo `.config/hypr/custom/`.
2. Live `~/.config/hypr/custom/` is an applied copy.
3. Vendor / personal fork = product SoT — never commit machine overlays there.
4. Apply is one-way repo → live after full files install.
5. Apply command (Phase 14 runs; **do not run in Phase 13**):

```bash
mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/hypr/custom"
# Fail if general.lua missing (layout required)
test -f .config/hypr/custom/general.lua
# env.lua / execs.lua: warn and continue if missing
cp -a .config/hypr/custom/general.lua \
      "${XDG_CONFIG_HOME:-$HOME/.config}/hypr/custom/"
# copy env.lua and execs.lua if present
```

Never `rsync --delete`. Never copy `keybinds.lua` / `rules.lua` / `variables.lua`.

6. Persist live tweaks by copy-back into the repo. No sync daemon.
7. Mention apply-then-reload / re-login before expecting dual-head (`create_custom_config.lua` seeds after require; reload is commented out).

**Verify (D-19):** file exists; names `cp -a`; names fail-if-`general.lua`-missing.

## Shared Patterns

### Require contract (OVL-01)

**Source:** `vendor/dots-hyprland/dots/.config/hypr/hyprland.lua` lines 8–41

Custom modules load **after** matching hyprland defaults, only if the file exists. Empty `env.lua` / `execs.lua` still satisfy the slot. Content overlays live in `custom.general` only.

Do **not** implement optional root `workspaces.lua` / `monitors.lua` (lines 35–41).

### Empty custom seeds vs keybinds

**Source:** vendor `custom/{env,execs,general}.lua` are blank. `custom/keybinds.lua` is **not** empty:

```lua
hl.bind("CTRL+SUPER+ALT+Slash", hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"), {description = "Edit user keybinds"} )
```

Do **not** copy `keybinds.lua` into the parent repo.

### Seed-on-start (document only)

**Source:** `hyprland/services/create_custom_config.lua` lines 2–28; header in `hyprland/lib/init.lua` lines 13–16.

Phase 14 overwrites live `env`/`general`/`execs` from repo **before** the session that must show dual-head. Phase 13 does not write `$HOME/.config`.

### Value source fence

**Source:** `.config/hypr/hyprland.conf` monitors 29–30, workspaces 76–87 only. Autostart 55–73 and env/cursor 106–111 are **not** overlay sources this phase (CONTEXT D-10 / D-21).

### Verification (inline bash, no test harness)

Match Phases 6/12: plan `<verify>` bash, repo-only.

CONTEXT D-19 (overrides RESEARCH `test -s` on env/execs and cursor/venv greps):

```bash
test -s .config/hypr/custom/general.lua
test -f .config/hypr/custom/env.lua
test -f .config/hypr/custom/execs.lua
# do NOT test -s env.lua or execs.lua
test -f .planning/phases/13-personal-hypr-custom-overlays/13-SOT-APPLY.md

grep -q 'DP-1' .config/hypr/custom/general.lua
grep -q 'HDMI-A-2' .config/hypr/custom/general.lua
grep -q 'hl.workspace_rule' .config/hypr/custom/general.lua
grep -q 'special:social' .config/hypr/custom/general.lua
grep -q 'scale = "auto"' .config/hypr/custom/general.lua
grep -q 'cp -a' .planning/phases/13-personal-hypr-custom-overlays/13-SOT-APPLY.md

test ! -e .config/hypr/monitors.lua
test ! -e .config/hypr/workspaces.lua
test ! -e .config/hypr/custom/keybinds.lua
test ! -e .config/hypr/custom/rules.lua

! grep -Eiq 'XCURSOR_|setcursor|ILLOGICAL_IMPULSE_VIRTUAL_ENV' .config/hypr/custom/*.lua
! grep -Eiq 'google-chrome|vesktop|discord|waybar|swaync|qs -c ii' .config/hypr/custom/*.lua
test -z "$(git -C vendor/dots-hyprland status --short -- dots/.config/hypr/custom)"
```

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| — | — | — | All four files have analogs. Empty env/execs match vendor seeds. `13-SOT-APPLY.md` has no prior overlay SoT note; copy **policies** from CONTEXT D-01..D-05/D-18 and **install skip** semantics from `install_dir__ignore_existing`, not a prior markdown body. |

## Metadata

**Analog search scope:** `vendor/dots-hyprland/dots/.config/hypr/`, `vendor/dots-hyprland/sdata/subcmd-install/`, `.config/hypr/hyprland.conf`, `.planning/phases/12-wrapper-full-profile/`
**Files scanned:** hyprland.lua, general.lua, rules.lua, custom/{env,execs,general,keybinds}.lua, create_custom_config.lua, lib/init.lua, 3.files.sh, 3.files-legacy.sh, hyprland.conf, 12-PATTERNS.md
**Pattern extraction date:** 2026-08-19
**RESEARCH.md:** use Patterns 1–3, 6–7 and anti-patterns; **discard** Patterns 4–5, env/execs code examples, and `test -s`/XCURSOR/setcursor verify lines.
