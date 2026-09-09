# Phase 10: Full-install impact inventory - Research

**Researched:** 2026-08-04
**Domain:** dots-hyprland full-install impact inventory (static source + read-only host scan; docs artifact only)
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Deliverable is a single committed file: `.planning/phases/10-full-install-impact-inventory/10-INVENTORY.md` (phase dir SoT; not under `docs/`).
- **D-02:** One multi-section markdown document (not split files per flag axis). Sections cover SAFE_DEFAULTS residual, hypr axis, misc/`--core` axis, packages/sysupdate axis, plus host snapshot content as decided below.
- **D-03:** Include a **dated machine-specific host presence** table for **live** `~/.config` (what install would collide with on this box).
- **D-04:** Uncertain rows stay in the inventory with status **UNKNOWN** plus a research note / source to recheck — never invent certainty; never drop a surface just because proof is incomplete.
- **D-05:** Evidence = **static setup/wrapper source** + **live host scan**. Primary sources: `vendor/dots-hyprland/sdata/subcmd-install/3.files-legacy.sh` (and related files install path), `options.sh`, `arch/dots-hyprland.sh`. No live full install this phase.
- **D-06:** Host presence scan covers **live XDG only** (`~/.config`). Do **not** require dual presence columns for repo `.dotfiles/.config` in the inventory (repo may still be read as secondary research if needed; it is not a required evidence tree).
- **D-07:** **Every** inventory row must cite a concrete source (setup file/symbol/section, wrapper path, or host command/path observation) so Phase 11 can re-verify.
- **D-08:** Wrapper `--dry-run` argv proof is **optional / not required** for Phase 10. Dry-run full-profile proof belongs with Phase 12.
- **D-09:** Structure as **three independent sections**: (1) drop `--skip-hyprland`, (2) drop `--core`, (3) allow sysupdate. Do **not** primary-structure as a cross-product of staged profiles.
- **D-10:** Uniform row columns across effect tables: **Path | Effect | Risk | Source | Host present?**
- **D-11:** **SAFE_DEFAULTS residual (INV-04)** is a **dedicated top section before** the three axes — current wrapper injection and that safe install remains available after this milestone.
- **D-12:** Inventory stays **neutral** — map effects only. No recommended staged full profile or “drop all three” implication. Phase 11 owns DISP-02 choices.
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

### Deferred Ideas (OUT OF SCOPE)
- Formal dual-run chrome disposition (remove vs keep) — Phase 11 (DISP-03); inventory omits them per D-15 but Phase 11 should still record an explicit decision consistent with operator lean “can be removed.”
- Preferred staged flag profile / hypr-first soft recommend — explicitly neutral in Phase 10; Phase 11 DISP-02
- Wrapper `--dry-run` full-profile argv proof — Phase 12
- hypr/custom Lua migration of category-annotated must-keeps — Phase 13
- Live full adopt — Phase 14
- Playbook safe vs full documentation — Phase 15
- Waybar custom ports (CUST-*) — later milestone
- Repo ↔ live hypr SoT policy for overlays — Phase 13 OVL-03
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| INV-01 | Written impact inventory of every filesystem path and package/sysupdate effect of full install without `--skip-hyprland`, and separately dropping `--core` / `--skip-sysupdate` | Three independent axis sections + packages/sysupdate from `install-deps.sh`; columns Path\|Effect\|Risk\|Source\|Host present? |
| INV-02 | Personal `.config/hypr` vs upstream hypr install behavior (conf→`.old`, hyprland sync, lua entry, lock/idle auto_backup, custom ignore_existing) | File:line cites from `3.files-legacy.sh` + `3.files.sh` helpers; host scan of live hypr tree |
| INV-03 | Non-hypr personal configs that clash if `--core` dropped (fish, kitty, starship, fontconfig, **and full misc catalog**) | Full `find dots/.config` misc basenames + fish/fontconfig branches; host presence map |
| INV-04 | Current SAFE_DEFAULTS behavior; safe dual-run install remains available after this milestone | `arch/dots-hyprland.sh` SAFE_DEFAULTS injection; residual top section; dry-run proof optional |
</phase_requirements>

## Summary

Phase 10 produces a **committed neutral inventory** (`10-INVENTORY.md`) of what a **default full dots-hyprland install** would change on this machine. It is analysis-only: **no live full install**, no dispositions, no wrapper full-profile implementation. Evidence is dual-track: (1) static wrapper + upstream setup sources, (2) read-only live `~/.config` host scan.

Today the thin wrapper **always** injects `SAFE_DEFAULTS=(--core --skip-hyprland --skip-sysupdate)` for `install` / `install-files`. There is **no** wrapper opt-in full path yet (Phase 12). Inventorying “full install” means describing the blast radius of **removing** each of those three flags independently against legacy files install (`3.files-legacy.sh`, default path unless `--exp-files`) and Arch deps (`sdata/dist-arch/install-deps.sh`).

Critical host facts (scan 2026-08-04): personal `hyprland.conf` (465 lines) is SoT; `hyprland.lua` **absent**; `hypr/custom` **absent**; `installed_true` **present** (not firstrun) so lock/idle auto_backup would write `*.new` rather than replace; dual-run ii metas already installed; fish/kitty/starship/fontconfig/mpv/dolphinrc/kdeglobals present as misc collision candidates.

**Primary recommendation:** Plan tasks that **assemble `10-INVENTORY.md` from cited static source + a scripted read-only host presence checklist**, structured as SAFE_DEFAULTS residual → three independent flag axes → host snapshot, with Risk = HIGH/MED/LOW and UNKNOWN rows retained.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| SAFE_DEFAULTS residual documentation | Docs / planning artifact | Wrapper source (`arch/`) | INV-04 is a written residual claim, not a code change |
| Hypr path effect map | Upstream setup files tier | Live XDG host scan | Effects owned by `3.files-legacy.sh`; presence owned by host |
| Misc/`--core` catalog | Upstream setup files tier | Live XDG host scan | Catalog from `dots/.config` find loop; collisions from host |
| Package/sysupdate effects | Upstream dist-arch deps | Host pacman query (optional) | `install-deps.sh` owns Syu/metas/asdeps; host shows already-installed metas |
| Inventory deliverable | Planning phase dir | Git commit | D-01 phase-dir SoT |
| Dispositions / full profile / overlays / live adopt | **Out of phase** | — | Phases 11–14 |

## Standard Stack

This phase installs **no new packages**. Stack is existing repo tooling + host read tools.

### Core

| Tool / Asset | Version / Path | Purpose | Why Standard |
|--------------|----------------|---------|--------------|
| `arch/dots-hyprland.sh` | repo SoT | SAFE_DEFAULTS residual proof | Thin wrapper is install entry (v0.2) |
| `vendor/dots-hyprland/sdata/subcmd-install/3.files-legacy.sh` | submodule pin | Hypr + misc path effects | Default files path (not `--exp-files`) |
| `vendor/dots-hyprland/sdata/subcmd-install/3.files.sh` | submodule pin | Install helpers (sync, auto_backup, ignore_existing) | Behavior implementations |
| `vendor/dots-hyprland/sdata/subcmd-install/options.sh` | submodule pin | Flag semantics (`--core`, skips) | Flag → SKIP_* mapping |
| `vendor/dots-hyprland/sdata/dist-arch/install-deps.sh` | submodule pin | Syu + meta PKGBUILDs + asdeps | Package/sysupdate axis |
| Host `find`/`ls`/`test`/`grep`/`pacman -Qq` | system | Read-only host presence | D-05/D-06 evidence |

### Supporting

| Asset | Purpose | When to Use |
|-------|---------|-------------|
| `.planning/research/FEATURES.md` | Starter surface tables | Seed rows only; re-verify every claim against setup source |
| `docs/dots-hyprland-workflow.md` | Current safe dual-run operator path | INV-04 “safe remains available” narrative; not inventory SoT |
| Optional `./arch/dots-hyprland.sh install --dry-run` | Prove current SAFE_DEFAULTS argv | Cheap residual proof (not required, D-08) |
| `3.files-exp.yaml` | Contrast only | Note behavioral deltas; default inventory assumes **legacy** |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Legacy `3.files-legacy.sh` | `--exp-files` YAML path | Exp is experimental; different modes (whole `hypr/` sync, soft starship). Inventory **must** default to legacy unless operator opts exp |
| Live full dry install | Static source + host scan | Live install is Phase 14; D-05 forbids mutation |
| Cross-product staged profiles | Three independent axes | D-09 / D-12 — Phase 11 chooses combinations |

**Installation:** none for Phase 10.

## Package Legitimacy Audit

> Phase 10 is a **docs/analysis artifact** phase. No external packages are installed.

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| — | — | — | — | — | N/A | No installs |

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```text
                    ┌─────────────────────────────────────┐
                    │  Operator (Phase 10 — read only)    │
                    └──────────────┬──────────────────────┘
                                   │
           ┌───────────────────────┼───────────────────────┐
           ▼                       ▼                       ▼
  ┌─────────────────┐   ┌─────────────────────┐   ┌──────────────────┐
  │ arch/dots-      │   │ vendor/.../3.files- │   │ Live host XDG    │
  │ hyprland.sh     │   │ legacy.sh + options │   │ ~/.config scan   │
  │ SAFE_DEFAULTS   │   │ + install-deps.sh   │   │ (ls/find/test)   │
  └────────┬────────┘   └──────────┬──────────┘   └────────┬─────────┘
           │                       │                       │
           │   residual claims     │  path/effect rows     │ Host present?
           └───────────┬───────────┴───────────┬───────────┘
                       ▼                       ▼
              ┌────────────────────────────────────────┐
              │  10-INVENTORY.md (committed, neutral)  │
              │  1. SAFE_DEFAULTS residual (INV-04)    │
              │  2. Axis: drop --skip-hyprland         │
              │  3. Axis: drop --core                  │
              │  4. Axis: allow sysupdate / packages   │
              │  5. Host snapshot (dated)              │
              └───────────────────┬────────────────────┘
                                  │ feeds (no mutation)
                                  ▼
                         Phase 11 dispositions
```

### Recommended Project Structure (deliverable only)

```text
.planning/phases/10-full-install-impact-inventory/
├── 10-CONTEXT.md          # locked decisions (input)
├── 10-RESEARCH.md          # this file
├── 10-INVENTORY.md         # PHASE OUTPUT (D-01)
└── (optional) plans later
```

### Pattern 1: Neutral inventory row

**What:** One row per path/effect with mandatory Source and Host present?
**When to use:** Every filesystem or package effect under the three axes.
**Example columns (D-10):**

| Path | Effect | Risk | Source | Host present? |
|------|--------|------|--------|---------------|
| `~/.config/hypr/hyprland.conf` | Renamed to `hyprland.conf.old` (not deleted) | HIGH | `3.files-legacy.sh:51-53` | yes (465 lines) |

### Pattern 2: Three independent flag axes (not cross-product)

**What:** Separate sections for (1) hypr, (2) core/misc, (3) sysupdate/packages.
**When to use:** Always for Phase 10 structure (D-09).
**Why:** Phase 11 can pick any combination without redoing inventory.

### Pattern 3: Read-only host scan recipe

**What:** Presence/absence enumeration without mutation.
**When to use:** Filling `Host present?` and D-03 snapshot.
**Safe commands only:**

```bash
# READ-ONLY — never rsync/cp/mv/rm into XDG; never run setup without --dry-run
XDG="${XDG_CONFIG_HOME:-$HOME/.config}"
# top-level presence
for p in fish kitty starship.toml fontconfig hypr quickshell mpv ...; do
  if [ -e "$XDG/$p" ]; then echo "PRESENT $XDG/$p"; else echo "ABSENT $XDG/$p"; fi
done
# hypr tree
find "$XDG/hypr" -maxdepth 3 \( -type f -o -type d \) | sort
# firstrun marker (affects auto_backup branch)
test -f "$XDG/illogical-impulse/installed_true" && echo "NOT_FIRSTRUN" || echo "FIRSTRUN_LIKELY"
# category tags only (no dispositions)
grep -nE '^(monitor|workspace|bind|exec-once|env|windowrule|layerrule)' \
  "$XDG/hypr/hyprland.conf" | head
```

### Pattern 4: Category annotations without dispositions (D-13)

**What:** Tag personal `hyprland.conf` content as monitors / workspaces / binds / exec-once / env / rules.
**When to use:** Inside hypr axis notes, not as disposition columns.
**Host counts (2026-08-04, approximate grep):** monitor=2, workspace≈28, bind≈100, exec-once≈16, env≈4, windowrule≈16, layerrule≈4.

### Anti-Patterns to Avoid

- **Cross-product “profiles” as primary structure:** Violates D-09/D-12; Phase 11 owns combinations.
- **Including Waybar/rofi/swaync clash rows:** Violates D-15 even if host has them.
- **Copying FEATURES.md blindly:** Starter only; re-cite setup source.
- **Assuming firstrun lock/idle replace on this host:** `installed_true` exists → auto_backup writes `*.new`.
- **Assuming hyprpaper is installed by hypr axis:** Not in legacy hypr install list.
- **Assuming `hypr/custom` ignore_existing merges into existing dir:** If dir exists, legacy **skips entirely**; if absent, seeds stubs.
- **Live full install or dropping SAFE_DEFAULTS “to see”:** Phase 14 only; D-05.
- **Writing dispositions into inventory:** Phase 11.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Path effect discovery | Custom installer reimplementation | Cite `3.files-legacy.sh` + helpers | Upstream SoT; pin can change |
| Flag semantics | Guess skip aliases | `options.sh` `--core` expansion | Exact SKIP_* set |
| Package blast radius | Hand-maintained full depends tree | Coarse meta PKGBUILD list from `install-deps.sh` | INV-01 satisfied at meta grain (discretion) |
| Host presence | Manual memory | Scripted `test -e` / `find` | Reproducible, dated |
| Safe residual proof | Narrative only | Wrapper source + optional `--dry-run` | Executable truth |

**Key insight:** Phase 10 value is **citation density and host honesty**, not tooling. A markdown artifact with file:line sources beats an automated inventory generator that mutates or guesses.

## Common Pitfalls

### Pitfall 1: Treating lock/idle as always replaced
**What goes wrong:** Inventory claims personal hyprlock/hypridle will be overwritten.
**Why it happens:** Reading only the `mv $t $t.old` firstrun branch.
**How to avoid:** Document both branches of `install_file__auto_backup`. On this host `~/.config/illogical-impulse/installed_true` exists → **not firstrun** → existing targets get `*.new` sidecars; personal conf stays active unless operator forces firstrun.
**Warning signs:** Inventory says “replace lock” without mentioning FIRSTRUN_FILE.

### Pitfall 2: Incomplete misc catalog (named four only)
**What goes wrong:** Only fish/kitty/starship/fontconfig listed.
**Why it happens:** INV-03 names examples; D-16 requires **full** ii default misc catalog.
**How to avoid:** Replicate the `find dots/.config/ … ! quickshell ! fish ! hypr ! fontconfig` loop basenames (18 entries on current pin) **plus** fish, fontconfig, konsole share, and plasmaintg package side of `--core`.

### Pitfall 3: Confusing `--core` with “minimal everything”
**What goes wrong:** Believing `--core` skips quickshell or hypr.
**Why it happens:** Name suggests “core only.”
**How to avoid:** `--core` = `SKIP_PLASMAINTG + SKIP_FISH + SKIP_FONTCONFIG + SKIP_MISCCONF` only (`options.sh:90`). Quickshell and hypr are independent skips.

### Pitfall 4: hyprlock subdirectory gap (legacy)
**What goes wrong:** Assuming legacy installs `hypr/hyprlock/*` helpers/colors.
**Why it happens:** Upstream tree contains `hyprlock/` and upstream `hyprlock.conf` has `source=~/.config/hypr/hyprlock/colors.conf`, but legacy only auto_backups `hyprlock.conf`.
**How to avoid:** Inventory row: `hypr/hyprlock/` **not installed by legacy**; mark UNKNOWN/gap for lock correctness if firstrun replace occurs. Note `--exp-files` would sync whole hypr tree (different path).

### Pitfall 5: custom ignore_existing semantics
**What goes wrong:** Expecting rsync merge of new stubs into existing custom.
**Why it happens:** Function name suggests `--ignore-existing` always.
**How to avoid:** If dest **dir exists**, function **no-ops entirely**. If dest **absent**, seeds from upstream (rsync ignore-existing on empty dest = full seed). Host: custom **absent** → first full hypr files would seed stubs — Phase 13 must pre-seed before relying on personal overlays.

### Pitfall 6: hyprpaper orphan
**What goes wrong:** Expecting hyprpaper.conf to be replaced or removed by hypr install.
**Why it happens:** INV-02 lists hyprpaper as personal surface.
**How to avoid:** Legacy hypr block does **not** touch hyprpaper. Personal file remains; session may still exec hyprpaper from old conf until conf→`.old`.

### Pitfall 7: Syu independence from “already have metas”
**What goes wrong:** Skipping sysupdate axis because metas already installed.
**Why it happens:** Host already has all `illogical-impulse-*` metas from dual-run.
**How to avoid:** Dropping `--skip-sysupdate` still runs `sudo pacman -Syu`. Deps path also always runs `remove_deprecated_dependencies` and `implicitize_old_dependencies` even when Syu skipped.

### Pitfall 8: Inventory dispositions creep
**What goes wrong:** “Recommend drop hypr first” language in inventory.
**Why it happens:** Planning convenience.
**How to avoid:** D-12 neutral only; put recommendations in Phase 11.

### Pitfall 9: Mutating host during “scan”
**What goes wrong:** Accidental `install-files` or rsync to prove effects.
**Why it happens:** Desire for certainty.
**How to avoid:** Plan tasks forbid non-dry-run setup; verification is file existence checks on the markdown artifact.

## Code Examples

Verified patterns from in-repo sources (read this session):

### SAFE_DEFAULTS definition + injection

```bash
# Source: arch/dots-hyprland.sh:12, 127-131, 1399-1403
SAFE_DEFAULTS=(--core --skip-hyprland --skip-sysupdate)

needs_safe_defaults() {
  case "$1" in
    install|install-files) return 0 ;;
    *) return 1 ;;
  esac
}

# Build argv: ./setup <sub> [SAFE_DEFAULTS…] [user flags…]
local -a cmd=(./setup "$subcmd")
if needs_safe_defaults "$subcmd"; then
  echo "[CONFIG] safe defaults: ${SAFE_DEFAULTS[*]}"
  cmd+=("${SAFE_DEFAULTS[@]}")
fi
```

**Dry-run residual proof (executed 2026-08-04, read-only):**
`./setup install --core --skip-hyprland --skip-sysupdate` after backup gate.

### `--core` expansion

```bash
# Source: vendor/dots-hyprland/sdata/subcmd-install/options.sh:28,90
# --core  Alias of --skip-{plasmaintg,fish,miscconf,fontconfig}
--core) SKIP_PLASMAINTG=true;SKIP_FISH=true;SKIP_FONTCONFIG=true;SKIP_MISCCONF=true;shift;;
```

### Hypr install behaviors (legacy)

```bash
# Source: 3.files-legacy.sh:50-75
install_dir__sync dots/.config/hypr/hyprland "$XDG_CONFIG_HOME"/hypr/hyprland
if [ -f "${XDG_CONFIG_HOME}/hypr/hyprland.conf" ]; then
  mv "${XDG_CONFIG_HOME}/hypr/hyprland.conf" "${XDG_CONFIG_HOME}/hypr/hyprland.conf.old"
fi
# hyprlock.conf → install_file__auto_backup
# hyprland.lua → install_file (unless --skip-hyprland-entry)
# hypridle.conf → install_file__auto_backup
install_dir__ignore_existing "dots/.config/hypr/custom" "${XDG_CONFIG_HOME}/hypr/custom"
```

### auto_backup firstrun vs not

```bash
# Source: 3.files.sh:102-119
# FIRSTRUN_FILE = ${XDG_CONFIG_HOME}/illogical-impulse/installed_true  (environment-variables.sh:28-30)
if [ -f $t ]; then
  if ${INSTALL_FIRSTRUN}; then
    v mv $t $t.old
    v cp_file $s $t
  else
    v cp_file $s $t.new   # personal target UNCHANGED
  fi
else
  v cp_file $s $t
fi
```

### Misc catalog loop + fish/fontconfig

```bash
# Source: 3.files-legacy.sh:8-43
# MISC: all dots/.config/* except quickshell, fish, hypr, fontconfig → install_dir__sync or install_file
# + dots/.local/share/konsole
# fish: install_dir__sync_exclude ... "conf.d"
# fontconfig: install_dir__sync (or fontset)
```

### Sysupdate + meta packages

```bash
# Source: sdata/dist-arch/install-deps.sh:56-58, 93-103
case $SKIP_SYSUPDATE in
  true) true;;
  *) v sudo pacman -Syu;;
esac
# metapkgs: illogical-impulse-{audio,backlight,basic,fonts-themes,kde,portal,python,
#   screencapture,toolkit,widgets,hyprland,microtex-git,quickshell-git,bibata-modern-classic-bin}
# install-local-pkgbuild uses: yay -S --asdeps "${depends[@]}"; makepkg -Afsi
```

### custom require contract (planning signal for later phases; inventory notes only)

```lua
-- Source: dots/.config/hypr/hyprland.lua (require custom.* if files exist)
require("hyprland.env")
if is_file_exists(HOME .. "/.config/hypr/custom/env.lua") then
    require("custom.env")
end
-- similarly execs, general, rules, keybinds
```

## Research Findings by Focus Area

### 1. SAFE_DEFAULTS residual + safe path (INV-04) — HIGH

| Claim | Evidence |
|-------|----------|
| Array is `--core --skip-hyprland --skip-sysupdate` | `[VERIFIED: arch/dots-hyprland.sh:12]` quote: `SAFE_DEFAULTS=(--core --skip-hyprland --skip-sysupdate)` |
| Injected only for `install` and `install-files` | `[VERIFIED: arch/dots-hyprland.sh:127-131]` |
| Prepended before user flags; no undo flag once injected | `[VERIFIED: arch/dots-hyprland.sh:1399-1407]`; help text notes full hypr needs vendor setup outside wrapper today |
| `install-deps` / `install-setups` get **no** SAFE_DEFAULTS injection | `[VERIFIED: arch/dots-hyprland.sh:127-131]` |
| Backup gate still runs for install/install-files | `[VERIFIED: arch/dots-hyprland.sh:149-160, 1395-1397]` |
| Bare `--skip-backup` refused without `--allow-skip-backup` | `[VERIFIED: arch/dots-hyprland.sh:1387-1392]` |
| Post-install protect + enable ii hooks still run | `[VERIFIED: arch/dots-hyprland.sh:1435-1442]` |
| Safe dual-run remains default after this milestone | Process: Phase 10 does not change wrapper; FULL-02 is Phase 12 requirement to **keep** defaults |
| Optional dry-run proves argv | Executed: `./setup install --core --skip-hyprland --skip-sysupdate` |

**Inventory residual section should state explicitly:** Phase 10 does not remove SAFE_DEFAULTS; default `./arch/dots-hyprland.sh install` continues dual-run-safe injection; full path is future explicit opt-in (Phase 12).

### 2. Hypr install behaviors (INV-02) — HIGH

| Path / behavior | Effect (legacy, SKIP_HYPRLAND=false) | Risk | Source | Host present? (2026-08-04) |
|-----------------|--------------------------------------|------|--------|----------------------------|
| `~/.config/hypr/hyprland/` | `rsync -a --delete` sync from `dots/.config/hypr/hyprland` | HIGH | `3.files-legacy.sh:50`; `rsync_dir__sync` in `3.files.sh:67-76` | yes (minimal: `scripts/launch_first_available.sh` only) |
| `~/.config/hypr/hyprland.conf` | `mv` → `hyprland.conf.old` (disable old config for lua entry) | HIGH | `3.files-legacy.sh:51-53` | yes (465 lines, personal SoT) |
| `~/.config/hypr/hyprland.lua` | `install_file` (cp -f) unless `--skip-hyprland-entry` | HIGH | `3.files-legacy.sh:58-62` | **ABSENT** → would be created |
| `~/.config/hypr/hyprlock.conf` | `install_file__auto_backup` | HIGH (session lock) | `3.files-legacy.sh:55-57`; helper `3.files.sh:102-119` | yes (personal); **not firstrun** → expect `hyprlock.conf.new` |
| `~/.config/hypr/hypridle.conf` | same auto_backup | MED–HIGH | `3.files-legacy.sh:64-69` | yes; not firstrun → `hypridle.conf.new` |
| `~/.config/hypr/custom/` | `install_dir__ignore_existing`: seed if absent; **no-op if exists** | HIGH for overlay strategy | `3.files-legacy.sh:75`; helper `3.files.sh:150-159` | **ABSENT** → would seed ii stubs |
| `~/.config/hypr/hyprpaper.conf` | **Not touched** by legacy hypr block | MED (orphan / policy) | absence from `3.files-legacy.sh` hypr case | yes (DP-1 + HDMI-A-2 wallpapers) |
| `~/.config/hypr/hyprlock/` (upstream tree) | **Not installed** by legacy (only `.conf` file) | MED (gap if conf replaced on firstrun) | upstream conf sources `hyprlock/colors.conf`; legacy has no dir install | ABSENT live |
| `hyprland.conf.bak`, `hyprland-gui.conf` | Not touched by install list | LOW | host-only extras | yes |
| Google Sans Flex font (files step, non-fedora) | May install under `~/.local/share/fonts/illogical-impulse-*` | LOW | `3.files.sh:173-192, 226-228` | not required for INV-02 but files-path side effect |
| `hyprctl reload` attempt | End of files step | LOW | `3.files.sh:237-238` | N/A |

**Personal hyprland.conf category annotations (no dispositions):**

| Category | Notes from host conf (tags only) |
|----------|----------------------------------|
| monitors | DP-1 preferred; HDMI-A-2 preferred scale 1.5 transform 1 |
| workspaces | 1–5 + special:social on DP-1; 6–10 on HDMI-A-2 |
| exec-once | session/polkit; dual-run chrome lines (omit inventory focus per D-15); `qs -c ii`; cliphist; app launches; hyprpaper |
| env | cursor theme/size; `ILLOGICAL_IMPULSE_VIRTUAL_ENV` |
| binds | large personal bind set (~100) |
| rules | windowrule + layerrule present |

**Firstrun marker:** `[VERIFIED: host]` `~/.config/illogical-impulse/installed_true` exists (0 bytes, dated 2026-08-03) → `INSTALL_FIRSTRUN=false` unless `--firstrun`.

### 3. Full misc catalog when `--core` dropped (INV-03) — HIGH

**What `--core` skips today** (so dropping it re-enables): plasmaintg, fish, fontconfig, miscconf.

**Full misc basenames from pin** (`find` excluding quickshell/fish/hypr/fontconfig) — `[VERIFIED: vendor/dots-hyprland/dots/.config listing + 3.files-legacy.sh:11-16]`:

| Path under `~/.config` | Install mode | Host present? |
|------------------------|--------------|---------------|
| `chrome-flags.conf` | file `install_file` (cp -f) | ABSENT |
| `code-flags.conf` | file | ABSENT |
| `darklyrc` | file | ABSENT |
| `dolphinrc` | file | **PRESENT** |
| `foot/` | dir sync `--delete` | ABSENT |
| `fuzzel/` | dir sync | ABSENT |
| `kdeglobals` | file | **PRESENT** |
| `kde-material-you-colors/` | dir sync | ABSENT |
| `kitty/` | dir sync | **PRESENT** |
| `konsolerc` | file | ABSENT |
| `Kvantum/` | dir sync | ABSENT |
| `matugen/` | dir sync | ABSENT |
| `mpv/` | dir sync | **PRESENT** |
| `starship.toml` | file | **PRESENT** |
| `thorium-flags.conf` | file | ABSENT |
| `wlogout/` | dir sync | ABSENT |
| `xdg-desktop-portal/` | dir sync | ABSENT |
| `zshrc.d/` | dir sync | ABSENT |
| `~/.local/share/konsole/` | dir rsync (non-delete `install_dir`) | ABSENT |

**Also re-enabled by dropping `--core` (not in misc find loop):**

| Path / pkg | Effect | Host present? |
|------------|--------|---------------|
| `~/.config/fish/` | `install_dir__sync_exclude` with exclude `conf.d` (sync+delete except conf.d) | **PRESENT** (`conf.d` empty-ish; config.fish, functions, …) |
| `~/.config/fontconfig/` | dir sync `--delete` | **PRESENT** |
| `plasma-browser-integration` | optional pacman install if not skipped (~600KiB or pulls KDE) | package not checked required; flag axis note |

**Not skipped by `--core` (still installed under safe defaults today):**

| Path | Notes |
|------|-------|
| `~/.config/quickshell/` | Independent `SKIP_QUICKSHELL`; already dual-run installed |
| hypr | Independent `SKIP_HYPRLAND` |

**Risk posture for collisions:** kitty, starship, fish, fontconfig, mpv, dolphinrc, kdeglobals = **HIGH/MED** personal clash candidates on this host. Absent targets = greenfield create (lower clash, still “would install on new machine” per D-16/D-17).

### 4. Package/sysupdate when `--skip-sysupdate` dropped (INV-01) — HIGH

| Effect | When | Risk | Source |
|--------|------|------|--------|
| `sudo pacman -Syu` | `SKIP_SYSUPDATE` unset | HIGH (unattended full system upgrade) | `install-deps.sh:56-58` |
| `remove_deprecated_dependencies` (`pacman -Rdd` list of -git and old metas) | Always on deps path | MED | `install-deps.sh:15-22, 52-53` |
| `implicitize_old_dependencies` (`yay -D --asdeps` for names in `previous_dependencies.conf` that are explicit) | Always on deps path | HIGH for dual-run stack (bc, fish, starship, hyprlock-git names, …) | `install-deps.sh:26-38, 69-70`; `previous_dependencies.conf` |
| Meta PKGBUILD build/install via `makepkg -Afsi` + `yay -S --asdeps` depends | Always on deps path (`--needed`) | MED (rebuild/noise); asdeps demotion | `install-deps.sh:74-103` |
| Meta set (coarse grain OK) | audio, backlight, basic, fonts-themes, kde, portal, python, screencapture, toolkit, widgets, hyprland, microtex-git, quickshell-git, bibata-modern-classic-bin | MED | `install-deps.sh:93-97` |
| `plasma-browser-integration` | If not `SKIP_PLASMAINTG` | MED (size warning in script) | `install-deps.sh:106-122` |
| Wrapper post protect re-mark | After wrapper `install`/`install-deps`/`install-files` | Mitigates asdeps | `arch/dots-hyprland.sh:1435-1440` |

**Host:** all listed `illogical-impulse-*` metas already installed (dual-run). Syu is still a distinct risk if skip dropped on a future full `install`/`install-deps`.

**Note:** `install-files` alone does not run Syu; full `install` pipeline does deps first. Inventory should separate **files axes** from **deps/sysupdate axis** clearly.

### 5. How to host-scan without mutating — HIGH

**Allowed:** `ls`, `find`, `test`/`[ -e ]`, `stat`, `grep -n`, `head`/`cat` (read), `wc`, `pacman -Q`/`-Qq`, `realpath`, `date`.

**Forbidden in Phase 10 plans:** `./setup` without wrapper `--dry-run`; any `rsync`/`cp`/`mv`/`rm` into `$XDG_CONFIG_HOME` or `$HOME/ii-original-dots-backup`; `pacman -S`/`-R`/`-Syu`; editing live hypr.

**Recommended checklist script shape for executor:** print PRESENT/ABSENT for full misc catalog + hypr INV-02 set + firstrun marker; capture date; paste into inventory Host columns. Do not write under `~/.config`.

**Optional residual dry-run:** `printf 'yes\n' | ./arch/dots-hyprland.sh install --dry-run` — mutates nothing; confirms SAFE_DEFAULTS argv (already verified this research session).

### 6. Recommended plan task breakdown for `10-INVENTORY.md`

Planner should prefer **fine** granularity (config `granularity: fine`) along these waves:

| Wave | Task intent | Output fragment | Req |
|------|-------------|-----------------|-----|
| 0 | Validation harness: checklist that `10-INVENTORY.md` exists with required sections/columns; optional host-scan script under phase dir or `/tmp` that is read-only | test commands / script | Nyquist |
| 1 | Write **SAFE_DEFAULTS residual** section (INV-04) from wrapper cites + optional dry-run paste | Section 1 | INV-04 |
| 1 | Write **Axis A: drop `--skip-hyprland`** tables (INV-02 min set + extra live hypr files + category annotations) | Section 2 | INV-02 |
| 2 | Write **Axis B: drop `--core`** full misc catalog + fish/fontconfig/plasmaintg with Host present? | Section 3 | INV-03 |
| 2 | Write **Axis C: packages/sysupdate** coarse metas + Syu + deprecated/asdeps side effects | Section 4 | INV-01 |
| 3 | Write **dated host snapshot** summary (D-03); UNKNOWN rows for gaps (hyprlock/ dir legacy, exp-files deltas) | Section 5 | D-03/D-04 |
| 3 | Cross-check: every row has Source; no Waybar/rofi/swaync rows; no disposition language; commit `10-INVENTORY.md` | Final artifact | D-01, D-07, D-12, D-15 |

**Suggested inventory heading skeleton (discretion):**

1. `## SAFE_DEFAULTS residual (INV-04)`
2. `## Axis: drop --skip-hyprland (hypr files)`
3. `## Axis: drop --core (misc / fish / fontconfig / plasmaintg)`
4. `## Axis: allow sysupdate / package effects`
5. `## Host snapshot (live ~/.config, YYYY-MM-DD)`
6. `## UNKNOWN / research notes`
7. `## Sources`

**Risk vocabulary (discretion):** `HIGH` | `MED` | `LOW` plus short effect phrases already in Effect column.

### 7. `--exp-files` contrast (do not primary-structure on it)

Default router: `3.files.sh:221-224` sources legacy unless `EXPERIMENTAL_FILES_SCRIPT=true`.

Exp YAML differences worth UNKNOWN/note rows only:

- Whole `dots/.config/hypr` sync with excludes `custom`, `hyprlock.conf`, `hypridle.conf` → **would** install `hyprlock/` subdir and possibly touch more hypr files.
- starship/chrome flags use `soft` not hard overwrite.
- shell/terminal conditioned fish vs zsh, foot vs kitty.

Inventory default = **legacy**. If operator later uses `--exp-files`, re-inventory.

## State of the Art

| Old Approach (pre-v0.2 / naive) | Current Approach | Impact on Phase 10 |
|---------------------------------|------------------|--------------------|
| Blind `./setup install` full | SAFE_DEFAULTS dual-run wrapper | Inventory maps the gap between safe and full |
| Single “full means all flags” | Three independent axes | Inventory structure matches D-09 |
| Conf-only hypr | Lua entry + `hypr/custom` | Inventory must track conf→.old + lua + custom seed |
| Assume replace always | auto_backup firstrun vs `.new` | Host not-firstrun changes lock/idle effect |

**Deprecated/outdated for this phase:**

- Using FEATURES.md as sole evidence without re-reading setup.
- Centering dual-run chrome in inventory (D-15).
- Implementing full wrapper profile in Phase 10.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Default files path remains legacy (not exp) for inventory SoT | Hypr/misc | Exp-files would change several path effects |
| A2 | Hyprland loads `hyprland.lua` once `hyprland.conf` is renamed away (per install echo) | Hypr axis | Session entry mechanism nuances; still inventory conf→.old + lua install |
| A3 | Coarse meta-package listing satisfies INV-01 without expanding every PKGBUILD depend | Packages | Phase 11 may want finer grain for specific clash packages |
| A4 | Host scan timestamp 2026-08-04 remains representative through Phase 10 execution | Host snapshot | Re-run scan at inventory write time |

## Open Questions (RESOLVED)

1. **Legacy hyprlock/ directory gap** — **RESOLVED**
   - What we know: upstream conf sources `hyprlock/colors.conf`; legacy does not install the directory.
   - **Resolution (Phase 10):** Keep an **UNKNOWN** row in `10-INVENTORY.md` (plans 10-02 and 10-05). Do not invent install behavior. Phase 11 may disposition lock with “accept upstream + ensure hyprlock/ present” if needed — out of Phase 10 scope.

2. **Should inventory list `install-setups` side effects (groups, ydotool, gsettings)?** — **RESOLVED**
   - What we know: setups mutate system groups/modules and gsettings; somewhat independent of the three SAFE_DEFAULTS flags (`--skip-allsetups`).
   - **Resolution (Phase 10):** Optional short LOW-priority note citing `2.setups.sh` is allowed in finalize (plan 10-05 assumptions). **Does not block** inventory success criteria. Primary INV-01 axes remain the three flag axes + deps/sysupdate from `install-deps.sh`.

3. **Repo `.config/hypr` vs live drift** — **RESOLVED**
   - What we know: D-06 says repo dual column not required; wrapper enable-hooks may touch live and repo hyprland.conf.
   - **Resolution (Phase 10):** Host evidence SoT is live `~/.config` only. Optional one-line note that repo tree is not evidence SoT this phase is enough; no dual-column tables.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| bash | Wrapper dry-run / scan scripts | ✓ | system | — |
| find, ls, grep, test | Host scan | ✓ | system | — |
| rsync | (not needed Phase 10 read-only) | ✓ | /usr/bin/rsync | — |
| pacman | Optional meta presence query | ✓ | system | Skip package presence column detail |
| git + vendor submodule | Reading setup sources | ✓ | initialized | Preflight would fail install; research reads files OK |
| `./arch/dots-hyprland.sh` | Optional SAFE_DEFAULTS dry-run | ✓ | repo | Cite source only |
| Network / yay rebuild | Not required | N/A | — | — |

**Missing dependencies with no fallback:** none for Phase 10.

**Step 2.6:** External tools needed only for read-only scan + optional dry-run — all present.

## Validation Architecture

> `workflow.nyquist_validation` is **true** in `.planning/config.json`.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Shell/assert checklist (no Jest/pytest app suite for this phase) |
| Config file | none — Wave 0 adds phase-local verify commands |
| Quick run command | `test -f .planning/phases/10-full-install-impact-inventory/10-INVENTORY.md && rg -n 'SAFE_DEFAULTS|skip-hyprland|Host present' .planning/phases/10-full-install-impact-inventory/10-INVENTORY.md` |
| Full suite command | Read-only host re-scan + structural inventory checks (section headings, column headers, no disposition verbs, no waybar/rofi/swaync rows) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| INV-04 | Residual section states SAFE_DEFAULTS triple + safe remains default | docs/structure | `rg -n 'SAFE_DEFAULTS|--core --skip-hyprland --skip-sysupdate' 10-INVENTORY.md` | ❌ Wave 0 until inventory written |
| INV-02 | Hypr rows cover conf→.old, hyprland sync, lua, lock/idle, custom, hyprpaper | docs/structure | `rg -n 'hyprland.conf.old|hyprland.lua|auto_backup|ignore_existing|hyprpaper' 10-INVENTORY.md` | ❌ Wave 0 |
| INV-03 | Full misc catalog + fish/kitty/starship/fontconfig | docs/structure | `rg -n 'starship|fuzzel|matugen|wlogout|fish|fontconfig|kitty' 10-INVENTORY.md` | ❌ Wave 0 |
| INV-01 | Sysupdate + package effects section | docs/structure | `rg -n 'pacman -Syu|illogical-impulse|asdeps|skip-sysupdate' 10-INVENTORY.md` | ❌ Wave 0 |
| D-10 | Tables use Path\|Effect\|Risk\|Source\|Host present? | docs/structure | `rg -n 'Host present' 10-INVENTORY.md` | ❌ Wave 0 |
| D-12 | No disposition recommendations | docs/lint | `rg -ni 'recommend (keep|migrate|accept)|disposition:' 10-INVENTORY.md` expect no matches (or only “Phase 11”) | ❌ Wave 0 |
| D-15 | No waybar/rofi/swaync inventory rows | docs/lint | `rg -ni 'waybar|rofi|swaync' 10-INVENTORY.md` expect no clash-table hits | ❌ Wave 0 |
| D-05 | Host scan read-only | manual/process | Plan forbids non-dry-run setup; executor notes | process |
| Host freshness | Presence columns match machine | smoke | Re-run PRESENT/ABSENT loop; diff vs inventory | ❌ Wave 0 script |

### Sampling Rate

- **Per task commit:** structural `rg` checks for section just written
- **Per wave merge:** full structural suite above
- **Phase gate:** `10-INVENTORY.md` committed; all INV-01..04 rg checks green; host snapshot dated; no disposition/chrome violations

### Wave 0 Gaps

- [ ] `10-INVENTORY.md` — does not exist yet (phase output)
- [ ] Optional `scripts/phase10-host-scan.sh` or plan-inline read-only scan — not required to live in repo; if added, must be read-only
- [ ] Structural verify commands in PLAN verification blocks — framework install: none (use `rg`/`test`)

*(Existing project has no unit test harness for planning markdown; Nyquist here = artifact + scan checks.)*

## Security Domain

> `security_enforcement` enabled (ASVS level 1). Phase is documentation + read-only host inspection.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | partial | Inventory is trusted operator markdown; still avoid unsanitized paste of untrusted web content into artifact |
| V6 Cryptography | no | — |
| V1 Architecture | yes | No live mutation; least privilege scan (read-only) |
| File system integrity | yes | Forbid install/rsync to XDG in plans |

### Known Threat Patterns for this phase

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Accidental destructive install during “research” | Elevation / Tampering | D-05; dry-run only; plan bans live setup |
| Inventory as social-engineering vector (“run these rm commands”) | Tampering | Neutral effects only; no shell fix-it recipes that mutate |
| Leaking secrets into inventory | Information disclosure | Do not paste API keys; hypr conf categories only, not credential files |
| Prompt injection via fetched docs | Tampering | In-repo sources primary; treat external text as data |

## Project Constraints (from CLAUDE.md)

No project-root `CLAUDE.md` / `.claude/CLAUDE.md` found this session. Follow CONTEXT.md locked decisions and existing wrapper/playbook conventions:

- Thin wrapper around upstream `./setup`; never reimplement package lists in `arch/`
- Do not call upstream `./setup uninstall` as rollback path
- Planning artifacts committed under `.planning/`
- Live product configs under XDG, not assumed repo-symlinked for ii quickshell

## Sources

### Primary (HIGH confidence)

- `[VERIFIED: arch/dots-hyprland.sh]` — SAFE_DEFAULTS, backup gate, protect, dry-run injection (lines 12, 127–131, 149–160, 1387–1443)
- `[VERIFIED: vendor/dots-hyprland/sdata/subcmd-install/options.sh]` — flag help + `--core` expansion (lines 18–28, 80–90)
- `[VERIFIED: vendor/dots-hyprland/sdata/subcmd-install/3.files-legacy.sh]` — misc/fish/fontconfig/hypr behaviors (lines 8–79)
- `[VERIFIED: vendor/dots-hyprland/sdata/subcmd-install/3.files.sh]` — helpers auto_backup, sync, ignore_existing, firstrun, backup (lines 102–159, 201–224)
- `[VERIFIED: vendor/dots-hyprland/sdata/dist-arch/install-deps.sh]` — Syu, metas, asdeps, plasmaintg (lines 15–22, 56–122)
- `[VERIFIED: vendor/dots-hyprland/sdata/lib/environment-variables.sh:27-30]` — `BACKUP_DIR`, `FIRSTRUN_FILE`, `INSTALLED_LISTFILE`
- `[VERIFIED: host scan 2026-08-04]` — live `~/.config` presence, hypr tree, firstrun marker, meta packages
- `[VERIFIED: optional dry-run]` — `printf 'yes\n' | ./arch/dots-hyprland.sh install --dry-run` → SAFE_DEFAULTS argv

### Secondary (MEDIUM confidence)

- `[CITED: vendor/.../3.files-exp.yaml]` — experimental files behavior contrast
- `[CITED: .planning/research/FEATURES.md]` — starter surfaces (re-verified against setup)
- `[CITED: docs/dots-hyprland-workflow.md]` — safe dual-run operator narrative
- `[CITED: vendor/.../dots/.config/hypr/hyprland.lua]` — custom require contract

### Tertiary (LOW confidence)

- `[ASSUMED]` Hyprland runtime always prefers `hyprland.lua` after conf rename without extra DM config
- `[ASSUMED]` Coarse meta listing sufficient for INV-01 without full depends expansion

## Metadata

**Confidence breakdown:**
- Standard stack: **HIGH** — in-repo SoT, no new deps
- Architecture: **HIGH** — locked CONTEXT + verified install paths
- Pitfalls: **HIGH** — firstrun/custom/hyprpaper/misc catalog verified against code + host
- Package/sysupdate fine-grain depends: **MEDIUM** — coarse metas verified; full depends not expanded

**Research date:** 2026-08-04  
**Valid until:** 30 days or until vendor submodule pin / wrapper SAFE_DEFAULTS change  

**Graph context:** `.planning/graphs/graph.json` absent — skipped.

**Runtime State Inventory:** Omitted (not a rename/refactor/migration phase; greenfield docs artifact).

## RESEARCH COMPLETE
