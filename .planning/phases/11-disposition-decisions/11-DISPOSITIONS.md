# Phase 11 — Disposition decisions

**Status:** In progress (11-02 Axis A complete; 11-03/11-04 pending)  
**Artifact SoT:** this file under `.planning/phases/11-disposition-decisions/` (D-01)  
**Consumes path SoT:** `.planning/phases/10-full-install-impact-inventory/10-INVENTORY.md` (D-04)

## Scope

Committed disposition set for **full-adopt planning** (Phases 12–14 consume this contract).

- **Consumes** `10-INVENTORY.md` as SoT for paths (D-04). Do not invent surfaces without an explicit emerged-surface note + source.
- **No** wrapper edits (`arch/dots-hyprland.sh` SAFE_DEFAULTS untouched), **no** `hypr/custom` overlays written this phase, **no** live `~/.config` mutation this phase.
- Dual-run chrome **included** here as an emerged surface (omitted from inventory by Phase 10 D-15).
- Disposition enum (D-03) exactly: `keep-personal` | `migrate-to-hypr-custom` | `accept-upstream` | `merge` | `defer`.
- Uniform row columns (D-03): **Path | Inventory risk | Disposition | Rationale | Flag stage | Inventory source**.

---

## 1. Pre-flight repo sync gate (D-07)

**Purpose:** Before any full files install, sync live `~/.config` **PRESENT personal** configs into repo `.config/` so nothing personal exists only on live. Repo is the fresh-reinstall bootstrap for personal/dotfiles content.

**Sequencing:** capture (live→repo archive) **then** adopt. Phase 14 executes; this section documents the gate only — **do not run sync commands in Phase 11**.

**D-08 product SoT after adopt:** live home is dots-hyprland-managed for replaced surfaces; repo retains pre-flight personal copies as archive/bootstrap plus the small must-keep overlay set (D-16). Do **not** re-sync the entire live `quickshell/` / ii tree back into `.config` as product SoT (vendor/submodule remains product SoT).

### Candidate classes (document only)

| Path | Live | Repo | Sync action (Phase 14) | Class |
|------|------|------|------------------------|-------|
| `fontconfig/` | PRESENT | often thinner / drift | live→repo archive if live-only or newer | live-only / both-PRESENT verify-diff |
| `mpv/` | PRESENT | may lag live | live→repo archive | live-only / both-PRESENT |
| `dolphinrc` | PRESENT | may lag | live→repo archive | live-only / both-PRESENT |
| `kdeglobals` | PRESENT | may lag | live→repo archive | live-only / both-PRESENT |
| `hypr/hyprland.conf.bak` | PRESENT | optional | archive if personal backup wanted | live-only |
| `hypr/hyprland-gui.conf` | PRESENT | optional | archive or leave live-only | live-only |
| `hypr/hyprland.conf` | PRESENT | tracked | verify-diff before adopt; archive personal | both-PRESENT |
| `hypr/hyprland/` (+ `scripts/`) | PRESENT | tracked | verify-diff; capture personal scripts | both-PRESENT |
| `hypr/hyprlock.conf`, `hypridle.conf`, `hyprpaper.conf` | PRESENT | tracked | verify-diff; lock policy is no-touch on live | both-PRESENT |
| `fish/`, `kitty/`, `starship.toml` | PRESENT | tracked | verify-diff; archive personal before drop-`--core` | both-PRESENT |
| `waybar/`, `rofi/`, `swaync/` | PRESENT | tracked chrome | **archive required** (D-12) even under accept-remove | chrome archive |
| `quickshell/` | PRESENT dual-run | not personal product SoT | do **not** treat as personal product SoT after adopt (D-08) | product boundary |

**Example command shapes (documentation only — not executed this phase):**

```bash
# Read-only drift check (Phase 14 prep)
diff -rq "$HOME/.config/hypr" .config/hypr || true
# Live→repo archive copy shapes (Phase 14 only; never run in Phase 11)
# rsync -a --delete is NOT used here; prefer explicit archive copies into repo paths
```

---

## 2. Full-adopt flag profile (DISP-02 / D-05 / D-06 / D-09 / D-10 / D-32)

### SAFE_DEFAULTS residual (default install — unchanged this phase)

From `arch/dots-hyprland.sh:12`:

```bash
SAFE_DEFAULTS=(--core --skip-hyprland --skip-sysupdate)
```

| Fact | Detail | Source |
|------|--------|--------|
| Triple residual flags | `--core`, `--skip-hyprland`, `--skip-sysupdate` | `arch/dots-hyprland.sh:12` |
| Injection scope | `install` and `install-files` only | `needs_safe_defaults` ~127–131 |
| Argv build | Prepended before user flags | ~1399–1407 |
| Backup gate | Still runs for install / install-files | ~149–160, ~1395–1397 |

**D-10:** Residual `SAFE_DEFAULTS` on default `install` / `install-files` **remains unchanged** this phase. Default dual-run-safe install **still** injects the triple residual and **remains** available. Phase 11 does **not** edit wrapper defaults. Full profile is **opt-in intent** for Phase 12 (FULL-*).

### Independent axes (documented separately — DISP-02 / ROADMAP SC2)

| Axis | Residual flag | Drop meaning | Decided for first full-adopt? |
|------|---------------|--------------|-------------------------------|
| A — hypr files | `--skip-hyprland` | Install hyprland tree/conf/lua path | **Yes — drop** |
| B — misc / fish / fontconfig | `--core` | Misc catalog + fish + fontconfig install | **Yes — drop** |
| C — packages / sysupdate | `--skip-sysupdate` | Allow `pacman -Syu` on deps path | **Yes — drop (allow sysupdate)** |

Axes stay **independent for documentation** (Phase 10 D-09). First full-adopt profile is the **combined** decision, not an assumption that any single axis implies the others.

### First full-adopt profile (D-05 / D-32 North Star)

**First full-adopt profile drops all three residuals:** no `--skip-hyprland`, no `--core`, no `--skip-sysupdate`.

- Phase 12 encodes this as an **explicit opt-in** full path (FULL-01/02); backup gate and protect re-mark still required.
- Default install must **not** accidentally use full profile (FULL-02 boundary / D-10 anti-goal).
- Flag stage vocabulary for disposition rows: `full-profile` | `drop-skip-hyprland` | `drop-core` | `allow-sysupdate` | `residual-safe` | `n/a`.

### Product model (D-06) and cold-machine path (D-09)

- **D-06:** Product model is **full dots-hyprland only** + **repo personal layer**. No local Quickshell product revival. Upstream shell may still be named `ii` (`qs -c ii`) as dots-hyprland naming only — not a separate product.
- **D-09 cold-machine path intent:** clone this repo → full dots-hyprland setup via wrapper **full profile** → apply personal must-keep overlays from repo (playbook details Phase 15; intent recorded here).

---

## 3. Axis A — hypr HIGH + must-keeps (DISP-01)

**Complete** for all non-chrome hypr HIGH (+ MED–HIGH decision) inventory paths under drop-`--skip-hyprland` / full-profile. Lock residual narrative depth also in §7 (11-04); rows here seed DISP-01 coverage.

### Session / install targets (D-15..D-20)

| Path | Inventory risk | Disposition | Rationale | Flag stage | Inventory source |
|------|----------------|-------------|-----------|------------|------------------|
| `~/.config/hypr/hyprland.conf` (primary session entry) | HIGH | accept-upstream | Full adopt `mv` conf → `.old` so lua/hyprland tree becomes session entry (D-15). **Not** keep-personal as primary entry. | full-profile / drop-skip-hyprland | 10-INVENTORY.md Axis A `hyprland.conf` row |
| `hyprland.conf` must-keeps — **monitors** (DP-1 / HDMI-A-2) | HIGH (subset) | migrate-to-hypr-custom | D-16 only: dual-monitor setup → Phase 13 minimal `hypr/custom` overlay. Cite conf monitors ~29–30. | full-profile / drop-skip-hyprland | 10-INVENTORY.md Axis A `hyprland.conf` + conf categories |
| `hyprland.conf` must-keeps — **workspaces** layout pins | HIGH (subset) | migrate-to-hypr-custom | D-16 only: workspace layout pins → Phase 13 overlay. Cite conf ~76–87. | full-profile / drop-skip-hyprland | 10-INVENTORY.md Axis A `hyprland.conf` + conf categories |
| `hyprland.conf` must-keeps — **env** (cursor + `ILLOGICAL_IMPULSE_VIRTUAL_ENV`) | HIGH (subset) | migrate-to-hypr-custom | D-16 only: machine env paths including cursor theme/size and `ILLOGICAL_IMPULSE_VIRTUAL_ENV` → Phase 13 overlay. Cite conf ~106–111. | full-profile / drop-skip-hyprland | 10-INVENTORY.md Axis A `hyprland.conf` + conf categories |
| `~/.config/hypr/hyprland/` | HIGH | accept-upstream | `rsync --delete` from dots hyprland tree (D-18). Pre-flight captures personal content before sync. | full-profile / drop-skip-hyprland | 10-INVENTORY.md Axis A `hyprland/` row |
| `~/.config/hypr/hyprland/scripts/` | HIGH (subset of hyprland/) | accept-upstream | Covered by `hyprland/` dir sync `--delete` (D-18); personal scripts captured via §1 pre-flight repo archive before adopt. Explicit path for DISP-01 `rg -F`. | full-profile / drop-skip-hyprland | 10-INVENTORY.md Axis A `hyprland/scripts/` + parent `hyprland/` row |
| `~/.config/hypr/hyprland.lua` | HIGH | accept-upstream | Install entry required for dots-hyprland session (D-19). | full-profile / drop-skip-hyprland | 10-INVENTORY.md Axis A `hyprland.lua` row |
| `~/.config/hypr/custom/` | HIGH (overlay strategy) | accept-upstream | Allow ii `ignore_existing` seed on first install if ABSENT; then Phase 13 populates **only** D-16 must-keeps — no extra custom fluff (D-20). **No overlay files written this phase.** | full-profile / drop-skip-hyprland | 10-INVENTORY.md Axis A `custom/` row |

### D-17 drop — not migrate-to-hypr-custom

Category dispositions from personal `hyprland.conf` (inventory surface = hyprland.conf row). These are **accept-upstream / drop** — not must-migrate:

| Path / category | Inventory risk | Disposition | Rationale | Flag stage | Inventory source |
|-----------------|----------------|-------------|-----------|------------|------------------|
| Autostart apps (Chrome, kitty+tmux, btop special, vesktop/discord, …) | n/a (conf category) | accept-upstream | Drop personal exec-once apps; rely on upstream session model (D-17). Not migrate-to-hypr-custom. | full-profile / drop-skip-hyprland | hyprland.conf categories under 10-INVENTORY.md Axis A |
| Personal tool binds (define.sh, hyprshot, cliphist-rofi, special workspace binds, …) | n/a (conf category) | accept-upstream | Drop personal binds; not D-16 (D-17). | full-profile / drop-skip-hyprland | hyprland.conf categories under 10-INVENTORY.md Axis A |
| Chrome-related exec-once (waybar / swaync / rofi launchers) | n/a (conf category) | accept-upstream | Drop with chrome accept-remove (D-11/D-14/D-17); see §6. Not carried into must-keep overlays. | full-profile / drop-skip-hyprland | hyprland.conf + emerged chrome §6 |

### Lock / idle / paper seeds (D-24 / D-21) — authoritative narrative in §7

| Path | Inventory risk | Disposition | Rationale | Flag stage | Inventory source |
|------|----------------|-------------|-----------|------------|------------------|
| `~/.config/hypr/hyprlock.conf` | HIGH (session lock) | keep-personal | Operator no-touch / no boot-risk lock changes (D-24). Host not-firstrun → install writes `*.new` sidecars only; do not promote `.new`. Product remains hyprlock mechanism; no Quickshell lock investment (D-23). | full-profile / drop-skip-hyprland (effect axis; live conf untouched) | 10-INVENTORY.md Axis A `hyprlock.conf` row |
| `~/.config/hypr/hypridle.conf` | MED–HIGH | keep-personal | Same no-touch policy (D-24). | full-profile / drop-skip-hyprland | 10-INVENTORY.md Axis A `hypridle.conf` row |
| `~/.config/hypr/hyprpaper.conf` | MED | accept-upstream | No investment / personal orphan policy (D-21); not a must-migrate. | full-profile / drop-skip-hyprland | 10-INVENTORY.md Axis A `hyprpaper.conf` row |

**migrate-to-hypr-custom discipline:** only monitors / workspaces / env rows above. Lock, paper, autostart, binds, chrome → never migrate-to-hypr-custom.

*Cross-ref:* §7 deepens lock residual + DISP-04 product wording (11-04). `hyprlock/` dir UNKNOWN → §8 defer (D-26). `.bak` / `hyprland-gui.conf` → §8 (D-22).

---

## 4. Axis B — misc under drop `--core` (expand in 11-03)

Stub for section gates and progressive keywords. Full HIGH rows (fish, fontconfig, kitty, starship.toml) + PRESENT MED + greenfield blurb land in **11-03**.

| Path | Inventory risk | Disposition | Rationale | Flag stage | Inventory source |
|------|----------------|-------------|-----------|------------|------------------|
| `~/.config/fish/` (stub) | HIGH | accept-upstream | FUTURE full row in 11-03: live accept under drop-`--core`; repo archive via pre-flight (D-27/D-28). | full-profile / drop-core | 10-INVENTORY.md Axis B fish row |
| `~/.config/kitty/` (stub) | HIGH | accept-upstream | FUTURE 11-03. | full-profile / drop-core | 10-INVENTORY.md Axis B kitty row |
| `~/.config/starship.toml` (stub) | HIGH | accept-upstream | FUTURE 11-03. | full-profile / drop-core | 10-INVENTORY.md Axis B starship.toml row |

Policy seed (D-28): after full adopt, live misc is dots-hyprland-managed; personal copies remain **repo only as archive**; **no post-install reapply** of personal fish/kitty/starship over live.

---

## 5. Axis C — packages / sysupdate (expand in 11-03)

Stub keywords for progressive assert: `pacman -Syu`, `illogical-impulse`, asdeps / full install-deps pipeline.

| Path | Inventory risk | Disposition | Rationale | Flag stage | Inventory source |
|------|----------------|-------------|-----------|------------|------------------|
| Full `install` / `install-deps` pipeline (stub) | HIGH | accept-upstream | FUTURE 11-03: accept full deps under first full-adopt (D-29). | full-profile / allow-sysupdate | 10-INVENTORY.md Axis C pipeline row |
| `sudo pacman -Syu` (stub) | HIGH | accept-upstream | FUTURE 11-03: allow when skip-sysupdate dropped (D-05/D-29). | full-profile / allow-sysupdate | 10-INVENTORY.md Axis C Syu row |
| `implicitize_old_dependencies` / asdeps (stub) | HIGH | accept-upstream | FUTURE 11-03: accept residual; wrapper protect re-mark remains (D-29). | full-profile / allow-sysupdate | 10-INVENTORY.md Axis C asdeps row |
| `illogical-impulse-*` metas (stub) | MED–HIGH | accept-upstream | FUTURE 11-03: remain managed; no uninstall campaign (D-31). | full-profile | 10-INVENTORY.md meta table |

Default residual install **still** injects `--skip-sysupdate` (§2 / D-10).

---

## 6. Dual-run chrome (DISP-03) — stub (complete in 11-04)

**Emerged surface:** Waybar / rofi / swaync were **omitted** from `10-INVENTORY.md` by Phase 10 D-15. Dispositioned here by operator decision (D-11), not invented install-effect rows.

**Explicit override (seed for assert):** This **explicitly accepts otherwise** versus DISP-03 / ROADMAP default-keep — disposition intent = **accept-remove** on full adopt (D-11). Full chrome section polish = **11-04**. Configs **archive in repo** (D-12); do not delete `.config/{waybar,rofi,swaync}` from repo.

| Path / surface | Inventory risk | Disposition | Rationale | Flag stage | Inventory source |
|----------------|----------------|-------------|-----------|------------|------------------|
| waybar session chrome (stub) | n/a (emerged) | accept-upstream | accept-remove dual-run chrome (D-11); stop exec-once; archive-in-repo (D-12) | full-profile | emerged: Phase 10 D-15; conf exec-once |
| rofi launcher chrome (stub) | n/a (emerged) | accept-upstream | accept-remove (D-11); archive-in-repo (D-12) | full-profile | emerged: Phase 10 D-15 |
| swaync notifications (stub) | n/a (emerged) | accept-upstream | accept-remove (D-11); archive-in-repo (D-12) | full-profile | emerged: Phase 10 D-15 |

Enum cell = `accept-upstream` only; **accept-remove** lives in rationale (no sixth enum token).

---

## 7. Lock / idle / paper residual (DISP-04) — stub (complete in 11-04)

Product seed (D-23): lock mechanism remains **hyprlock** if anything locks; **no Quickshell lock** investment.

| Path | Inventory risk | Disposition | Rationale | Flag stage | Inventory source |
|------|----------------|-------------|-----------|------------|------------------|
| `~/.config/hypr/hyprlock.conf` (stub) | HIGH | keep-personal | No-touch / no boot-risk lock changes (D-24). Expand narrative in 11-04. | full-profile / n/a | 10-INVENTORY.md Axis A hyprlock.conf |
| `~/.config/hypr/hypridle.conf` (stub) | MED–HIGH | keep-personal | No-touch (D-24). Expand in 11-04. | full-profile / n/a | 10-INVENTORY.md Axis A hypridle.conf |
| `~/.config/hypr/hyprpaper.conf` (stub) | MED | accept-upstream | No investment (D-21). | full-profile / n/a | 10-INVENTORY.md hyprpaper.conf |

---

## 8. UNKNOWN / extra surfaces — stub (complete in 11-04)

| Path | Inventory risk | Disposition | Rationale | Flag stage | Inventory source |
|------|----------------|-------------|-----------|------------|------------------|
| `~/.config/hypr/hyprlock/` dir (stub) | UNKNOWN / gap | defer | Dir not installed by legacy; defer under no-touch lock (D-26). Expand 11-04. | n/a | 10-INVENTORY.md UNKNOWN / research notes |
| `~/.config/hypr/hyprland.conf.bak` (optional seed) | LOW | keep-personal | Personal backup left alone (D-22). | n/a | 10-INVENTORY.md extra surfaces |
| `~/.config/hypr/hyprland-gui.conf` (optional seed) | LOW | defer | Personal/gui conf not in install list (D-22). | n/a | 10-INVENTORY.md extra surfaces |

---

## Sources

- `.planning/phases/10-full-install-impact-inventory/10-INVENTORY.md` — path/risk/source SoT
- `arch/dots-hyprland.sh` — SAFE_DEFAULTS residual + injection (do not edit this phase)
- `.planning/phases/11-disposition-decisions/11-CONTEXT.md` — D-01..D-32 locked decisions
- `.planning/phases/11-disposition-decisions/11-RESEARCH.md` — eight-section outline, HIGH map
- `.config/hypr/hyprland.conf` — must-keep category evidence (cite only; no secret dump)
- `.planning/REQUIREMENTS.md` — DISP-01..04
