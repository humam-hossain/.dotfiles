# Phase 11: Disposition decisions - Research

**Researched:** 2026-08-08
**Domain:** Full-install disposition set (docs artifact; maps `10-INVENTORY.md` → keep/migrate/accept/merge/defer + flag profile)
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Deliverable is a single committed file: `.planning/phases/11-disposition-decisions/11-DISPOSITIONS.md` (phase-dir SoT; not under `docs/`). — **Reversibility:** reversible
- **D-02:** One multi-section markdown document parallel to inventory axes: (1) pre-flight repo sync gate, (2) full-adopt flag profile (all three axes), (3) Axis A hypr HIGH rows + must-keep categories, (4) Axis B misc rows under dropped `--core`, (5) Axis C packages/sysupdate, (6) dual-run chrome accept-remove, (7) lock/idle/paper residual, (8) UNKNOWN / extra surfaces. — **Reversibility:** reversible
- **D-03:** Uniform disposition row columns: **Path | Inventory risk | Disposition | Rationale | Flag stage | Inventory source**. Disposition enum exactly: `keep-personal` | `migrate-to-hypr-custom` | `accept-upstream` | `merge` | `defer`. — **Reversibility:** reversible
- **D-04:** Every disposition row must cite the inventory path/row (or UNKNOWN id). Do not invent surfaces absent from `10-INVENTORY.md` without an explicit "emerged surface" note + source. — **Reversibility:** reversible
- **D-05:** Flag axes remain **independent** (Phase 10 D-09) for documentation, but **first full-adopt profile drops all three SAFE_DEFAULTS residuals**: no `--skip-hyprland`, no `--core`, no `--skip-sysupdate`. This is the greenfield full dots-hyprland install (North Star now, not a later Stage 2/3). — **Reversibility:** costly — Phase 12 FULL-* encoding and Phase 14 gates consume this; undoing reintroduces staged narrower profiles
- **D-06:** Product model: **full dots-hyprland only** + **repo personal layer**. No local Quickshell product revival. Upstream shell may still be named `ii` (`qs -c ii`); that is dots-hyprland naming, not a separate product. — **Reversibility:** costly — framing for Phases 12–15 and playbook
- **D-07:** **Pre-flight gate (required before any full files install):** sync live `~/.config` PRESENT personal configs into repo `.config/` so nothing personal exists only on live. Repo is the fresh-reinstall bootstrap for personal/dotfiles content. — **Reversibility:** costly — adopt plans must sequence capture before mutation
- **D-08:** After full adopt, **live** home is dots-hyprland-managed for replaced surfaces; **repo** retains pre-flight personal copies as archive/bootstrap material plus the small must-keep overlay set (D-16). Do **not** re-sync entire live ii tree back into `.config` as the primary SoT for product configs (vendor/submodule remains product SoT). — **Reversibility:** costly
- **D-09:** Cold-machine path intent: clone this repo → full dots-hyprland setup via wrapper full profile → apply personal must-keep overlays from repo. — **Reversibility:** reversible (docs/playbook later)
- **D-10:** SAFE_DEFAULTS on default `install` / `install-files` **unchanged** this phase (Phase 12 implements explicit opt-in full path). Dispositions describe the **intended full profile**, not live wrapper default edits. — **Reversibility:** one-way if violated — accidental default full install is milestone anti-goal
- **D-11:** Waybar / rofi / swaync session chrome disposition = **explicit accept-remove** on full adopt (overrides DISP-03 default-keep). Operator chose remove for full product cutover. — **Reversibility:** costly — CUT-01 effectively folded into full adopt; re-adding dual-run later is a new decision
- **D-12:** Chrome configs **stay in repo as archive** (pre-flight sync captures them). Stop launching from hypr `exec-once`; do not delete from repo as part of Phase 11–14 success. — **Reversibility:** reversible
- **D-13:** Launcher/notification keybinds: **rely on dots-hyprland defaults** after chrome removal. Do not require a must-remap bind list in dispositions for SUPER+N / cliphist-rofi / waybar toggle / etc. — **Reversibility:** reversible
- **D-14:** Timing: chrome stops in the **same adopt window** as full files install (when conf→`.old` / lua entry lands, personal waybar/rofi/swaync exec-once are **not** carried into must-keep overlays). — **Reversibility:** costly — no dual-run comparison boot required by plan
- **D-15:** `hyprland.conf` → will `mv` to `.old` under full adopt. Strategy: extract must-keeps → **`migrate-to-hypr-custom`**; remainder **`accept-upstream`** via dots-hyprland `hyprland/` + `hyprland.lua`. Do **not** `keep-personal` the conf as primary session entry (blocks ADOPT-02). — **Reversibility:** costly — Phase 13/14 session model
- **D-16:** Must-migrate set (**only**): **monitors** (DP-1 / HDMI-A-2 dual setup), **workspaces** layout pins, **env** machine paths (including cursor / `ILLOGICAL_IMPULSE_VIRTUAL_ENV` as needed for session). Via **`hypr/custom`** overlays — minimal custom (no extra fluff). — **Reversibility:** costly
- **D-17:** Autostart apps (Chrome, kitty+tmux, btop special, vesktop/discord), personal tool binds (define.sh, hyprshot, cliphist-rofi, special workspace binds), and chrome-related exec-once: **`accept-upstream` / drop** — not migrated. — **Reversibility:** reversible
- **D-18:** `hyprland/` dir sync (`rsync --delete`) → **`accept-upstream`**. Personal scripts under `hyprland/scripts/` already tracked in repo; pre-flight sync covers capture. No special live migrate-out task beyond D-07. — **Reversibility:** one-way on live sync without backup (backup gate still applies at install)
- **D-19:** `hyprland.lua` → **`accept-upstream`** (install entry required for dots-hyprland session model). — **Reversibility:** costly
- **D-20:** `hypr/custom/` currently ABSENT → allow ii seed on first install (`ignore_existing`), then Phase 13 populates **only** D-16 must-keeps. Earlier “custom not important” means no extra custom beyond that set — not “skip overlays entirely.” — **Reversibility:** costly
- **D-21:** `hyprpaper.conf` / wallpaper → **not important**; disposition **`accept-upstream`** / no investment (may be unused after chrome/paper dual-run ends). — **Reversibility:** reversible
- **D-22:** Extra live surfaces (`.bak`, `hyprland-gui.conf`) → **`keep-personal`** for operator backups; **`defer`** for unused gui conf if unclear. Recommended: `.bak` **`keep-personal`**, `hyprland-gui.conf` **`defer`**. Non-install targets; do not block adopt. — **Reversibility:** reversible
- **D-23:** Product still uses **hyprlock as lock mechanism** if anything locks — **no Quickshell lock screen investment**. — **Reversibility:** costly — PROJECT constraint
- **D-24:** Operator **does not use lock** and wants **no boot-risk changes**. Disposition: **leave live `hyprlock.conf` / `hypridle.conf` alone** (`keep-personal` / no-touch). Host not-firstrun already writes only `*.new` sidecars — do **not** promote `.new` to live; do **not** force firstrun replace for lock/idle this milestone. — **Reversibility:** reversible
- **D-25:** `*.new` lock/idle sidecars → **`defer`** (ignore unless operator later reviews). — **Reversibility:** reversible
- **D-26:** `hyprlock/` dir gap (UNKNOWN) → **`defer`**; not a blocker given no-touch lock policy. — **Reversibility:** reversible
- **D-27:** Because full adopt **drops `--core`**, all misc catalog rows (PRESENT collisions and greenfield ABSENT) → **`accept-upstream`** on **live** home. — **Reversibility:** one-way on live without backup — pre-flight D-07 + install backup gate are the safety net
- **D-28:** PRESENT collisions of note (fish, kitty, starship, fontconfig, mpv, dolphinrc, kdeglobals, …): live **`accept-upstream`**; personal copies remain in **repo only as archive** after pre-flight — **no post-install reapply** over live. — **Reversibility:** costly if operator later wants personal fish/kitty as active layer
- **D-29:** Packages path: **`accept-upstream`** full deps — allow `pacman -Syu`, meta `illogical-impulse-*` packages, and asdeps demotion residual. Document risk in dispositions; do not invent new protect lists here (wrapper protect/re-mark remains as implemented). — **Reversibility:** one-way for system package state
- **D-30:** `plasma-browser-integration` / optional plasmaintg: **`accept-upstream` if setup wants it** (including possible KDE pull). — **Reversibility:** costly (package footprint)
- **D-31:** Coarse already-installed `illogical-impulse-*` metas → **`accept-upstream`** (remain managed); no uninstall campaign. — **Reversibility:** reversible
- **D-32:** Phase 10 D-17 North Star (default full dots-hyprland as on a new machine) **is** the first full-adopt target (D-05). No intermediate “hypr-only Stage 1” for this operator decision set. — **Reversibility:** costly relative to prior auto draft that staged hypr-first

### Claude's Discretion
- Exact markdown heading names and table grouping inside `11-DISPOSITIONS.md` as long as D-01–D-04 hold
- Whether LOW residual rows get individual lines or a single “accept-upstream under full profile” blurb
- Rationale wording length (one short sentence preferred)
- Optional assert/lint script for disposition enum + required columns (nice-to-have; reuse Phase 10 assert patterns if cheap)
- Exact pre-flight sync command set (rsync/cp list) — planner/research derive from PRESENT inventory + repo drift
- Whether `ILLOGICAL_IMPULSE_VIRTUAL_ENV` is listed under env migrate or assumed provided by dots-hyprland hooks after adopt

### Deferred Ideas (OUT OF SCOPE)
- CUST-01..04 Waybar custom ports — backlog; chrome archived in repo for possible later use
- Formal CUT-01 as separate milestone — effectively satisfied by D-11 for full adopt; no separate dual-run keep path required
- Promoting hyprlock/hypridle `.new` sidecars or adopting upstream lock visuals — only if operator later cares about lock
- Optional disposition assert harness (Claude discretion)
- Live host re-scan if inventory host snapshot drifts materially before full adopt
- Post-adopt reapply of personal fish/kitty/starship over live — explicitly rejected for now (D-28); reopen only if daily driver breaks
- Wrapper full profile (Phase 12), overlays (Phase 13), live adopt (Phase 14), playbook (Phase 15)
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DISP-01 | Every high-risk inventory row has explicit disposition enum + short rationale | Inventory HIGH (+ MED–HIGH treat-as-decision) row map → section 3–5/7 tables; enum D-03; must-migrate D-15/D-16 only |
| DISP-02 | Staged flag choices recorded (hypr / core / sysupdate; not assumed all three without writing them) | Flag profile section documents independent axes **and** first full-adopt drops all three (D-05/D-32); residual SAFE_DEFAULTS unchanged (D-10) |
| DISP-03 | Dual-run chrome defaults keep unless explicitly accepted otherwise | D-11 **explicit accept-remove** override; chrome section + emerged-surface note (inventory omitted chrome per Phase 10 D-15); archive-in-repo D-12 |
| DISP-04 | hyprlock/hypridle disposition consistent with hyprlock mechanism + no QS lock investment | D-23–D-26: product keeps hyprlock mechanism; operator no-touch live conf; `*.new` defer; hyprlock/ dir UNKNOWN defer |
</phase_requirements>

## Summary

Phase 11 produces a **committed disposition set** (`11-DISPOSITIONS.md`) so every high-risk inventory surface and each SAFE_DEFAULTS flag axis has an explicit human decision **before** wrapper full-profile work (Phase 12), `hypr/custom` overlays (Phase 13), or live full adopt (Phase 14). This phase is **documentation only**: no wrapper edits, no overlay files, no live `~/.config` mutation, no `./setup` install.

Evidence SoT is Phase 10’s finalized `10-INVENTORY.md` (effects + host presence + UNKNOWN). Locked CONTEXT decisions already resolve nearly every gray area: first full-adopt **drops all three** SAFE_DEFAULTS residuals; dual-run chrome is **accept-remove** (explicit DISP-03 override of ROADMAP “default keep”); must-migrate is **monitors + workspaces + env only**; lock/idle is **no-touch keep-personal** with `*.new` **defer**; misc/packages under full profile are **accept-upstream** on live with personal copies archived in repo via pre-flight sync.

**Primary recommendation:** Plan tasks that **assemble `11-DISPOSITIONS.md` as eight locked sections (D-02) with uniform D-03 columns**, cite every HIGH inventory path, document the full-adopt flag profile for Phase 12 consumption, list pre-flight sync candidates from PRESENT↔repo drift, and optionally add a cheap `scripts/phase11-dispositions-assert.sh` mirroring Phase 10’s structural assert.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Disposition artifact SoT | Docs / planning phase dir | Git commit | D-01; no runtime code owns decisions |
| Flag profile (full-adopt argv intent) | Docs (Phase 11) | Wrapper encoding (Phase 12) | D-05/D-10: document now; implement opt-in later |
| Pre-flight sync gate | Docs checklist (Phase 11) | Live adopt executor (Phase 14) | D-07 sequences capture before mutation; Phase 11 only lists candidates |
| Must-keep category extraction | Docs categories (Phase 11) | `hypr/custom` Lua (Phase 13) | D-15/D-16 decide *what*; Phase 13 writes overlays |
| Chrome accept-remove | Docs (Phase 11 DISP-03) | Session adopt (Phase 14) | Inventory omitted chrome; dispositions own explicit override |
| Lock/idle no-touch policy | Docs (Phase 11 DISP-04) | Live install behavior (auto_backup already safe on non-firstrun) | D-24 aligns with host not-firstrun `*.new` branch |
| SAFE_DEFAULTS residual on default install | Wrapper (`arch/`) | Unchanged this phase | D-10; anti-goal = accidental full default |

## Current State

### Inventory SoT (Phase 10 complete)

| Fact | Detail | Source |
|------|--------|--------|
| Artifact | `.planning/phases/10-full-install-impact-inventory/10-INVENTORY.md` | D-01 Phase 10; assert green 2026-08-08 |
| SAFE_DEFAULTS residual | `SAFE_DEFAULTS=(--core --skip-hyprland --skip-sysupdate)` injected for `install` / `install-files` only | `[VERIFIED: arch/dots-hyprland.sh:12]` + `[VERIFIED: arch/dots-hyprland.sh:127-131]` + `[VERIFIED: arch/dots-hyprland.sh:1399-1407]` |
| Host firstrun | `~/.config/illogical-impulse/installed_true` **PRESENT** → not firstrun → lock/idle get `*.new` only | `[VERIFIED: 10-INVENTORY.md host snapshot]` |
| Personal hypr SoT | `hyprland.conf` 465 lines; live ≡ repo at research time | `[VERIFIED: diff -q live vs .config/hypr/hyprland.conf → identical 2026-08-08]` |
| `hypr/custom` | ABSENT on live → ignore_existing would seed | `[VERIFIED: 10-INVENTORY.md:71]` |
| Chrome in inventory | **Omitted entirely** (Phase 10 D-15) — dispositions must use emerged-surface note | `[VERIFIED: 10-INVENTORY.md:15]` + phase10 assert D-15 ban |
| Phase 11 deliverable | Does **not** exist yet | `ls` phase dir: CONTEXT + DISCUSSION-LOG only |

### Inventory row map → disposition sections

#### HIGH effect-table rows (unique paths; host-snapshot restates excluded)

| # | Path | Axis | Inventory risk | Maps to disposition section | Locked disposition seed |
|---|------|------|----------------|-----------------------------|-------------------------|
| 1 | `~/.config/hypr/hyprland/` | A | HIGH | §3 Axis A | `accept-upstream` (D-18) |
| 2 | `~/.config/hypr/hyprland.conf` | A | HIGH | §3 Axis A + must-keeps | split: migrate categories D-16; remainder accept (D-15) |
| 3 | `~/.config/hypr/hyprland.lua` | A | HIGH | §3 Axis A | `accept-upstream` (D-19) |
| 4 | `~/.config/hypr/hyprlock.conf` | A | HIGH (session lock) | §7 lock/idle | `keep-personal` no-touch (D-24) |
| 5 | `~/.config/hypr/custom/` | A | HIGH (overlay strategy) | §3 Axis A | seed ok → Phase 13 only D-16 (D-20) |
| 6 | `~/.config/hypr/hyprland/scripts/` | A | HIGH (subset of #1) | §3 Axis A | fold under #1 `accept-upstream` + pre-flight capture (D-18) |
| 7 | `~/.config/fish/` | B | HIGH | §4 Axis B | live `accept-upstream`; repo archive (D-27/D-28) |
| 8 | `~/.config/fontconfig/` | B | HIGH | §4 Axis B | same |
| 9 | `~/.config/kitty/` | B | HIGH | §4 Axis B | same |
| 10 | `~/.config/starship.toml` | B | HIGH | §4 Axis B | same |
| 11 | Full `install` / `install-deps` pipeline | C | HIGH overall | §5 Axis C | `accept-upstream` full deps (D-29) |
| 12 | `sudo pacman -Syu` | C | HIGH | §5 Axis C | allow under full profile (D-05/D-29) |
| 13 | `implicitize_old_dependencies` | C | HIGH for dual-run | §5 Axis C | accept residual; protect re-mark remains (D-29) |

**HIGH count for DISP-01 gate:** **13 unique HIGH effect rows** (6 Axis A including scripts subset, 4 Axis B, 3 Axis C). Scripts may be one table line “covered by hyprland/ dir” with explicit cite — still must not be *missing*.

#### MED–HIGH rows (treat as decision rows; do not drop)

| Path | Axis | Maps to | Locked seed |
|------|------|---------|-------------|
| `~/.config/hypr/hypridle.conf` | A | §7 lock/idle | `keep-personal` no-touch (D-24) |
| `~/.config/mpv/` | B | §4 Axis B | live `accept-upstream` (D-27/D-28) |
| `illogical-impulse-hyprland` meta | C | §5 Axis C | `accept-upstream` remain managed (D-31) |

#### Other inventory surfaces that need disposition lines (not all HIGH)

| Surface | Risk | Section | Locked seed |
|---------|------|---------|-------------|
| `hyprpaper.conf` | MED (personal orphan) | §7 | `accept-upstream` / no investment (D-21) |
| `hyprland.conf.bak` | LOW | §8 extra | `keep-personal` (D-22) |
| `hyprland-gui.conf` | LOW | §8 extra | `defer` (D-22) |
| Full misc greenfield ABSENT catalog (chrome-flags, foot, fuzzel, …) | LOW–MED | §4 blurb or rows | live `accept-upstream` under drop-`--core` (D-27) — Claude discretion: single blurb OK for LOW greenfield |
| PRESENT MED collisions `dolphinrc`, `kdeglobals` | MED | §4 | live `accept-upstream` + pre-flight archive (D-28) |
| `plasma-browser-integration` | MED | §5 | `accept-upstream` if setup wants (D-30) |
| Coarse `illogical-impulse-*` metas (already installed) | MED | §5 | `accept-upstream` (D-31) |
| SAFE_DEFAULTS residual path | LOW (protective) | §2 flag profile | residual **unchanged** on default install (D-10); full profile drops triple (D-05) |

#### UNKNOWN / research notes → §8

| Id / Item | Status | Disposition seed |
|-----------|--------|------------------|
| `~/.config/hypr/hyprlock/` helpers/colors | UNKNOWN / gap | `defer` (D-26) |
| `previous_dependencies.conf` ∩ explicit pkgs | PARTIAL | document accept residual under D-29; no per-name invent |
| `--exp-files` deltas | OUT OF DEFAULT SCOPE | note only; inventory SoT = legacy |
| `2.setups.sh` side effects | LOW optional | optional blurb; not HIGH gate |

#### Chrome rows (not in inventory — emerged surface)

| Surface | Why not in inventory | Section | Locked seed |
|---------|----------------------|---------|-------------|
| Waybar / rofi / swaync session chrome | Phase 10 D-15 omit | §6 | **accept-remove** (D-11); archive in repo (D-12); same adopt window (D-14) |
| Chrome-related `exec-once` / binds in personal conf | Part of hyprland.conf categories, not separate inventory rows | §3 + §6 | drop / not migrate (D-17); rely on upstream defaults (D-13) |

**Chrome evidence (repo personal conf, not inventory):**

```text
# [VERIFIED: .config/hypr/hyprland.conf:64]
exec-once = waybar & swaync & hyprpaper &
# [VERIFIED: .config/hypr/hyprland.conf:259,270,277]
bind = $mainMod, N, exec, swaync-client -t -sw
bind = $mainMod, w, exec, pkill waybar && waybar &
bind = $mainMod, V, exec, cliphist list | rofi -dmenu ...
```

Repo already has `.config/{waybar,rofi,swaync}/` present for archive (D-12).

### Must-migrate category evidence (D-16 only)

From personal conf (identical live/repo):

```text
# [VERIFIED: .config/hypr/hyprland.conf:29-30] monitors
monitor=DP-1,preferred,auto,auto
monitor=HDMI-A-2,preferred,auto,1.5,transform,1

# [VERIFIED: .config/hypr/hyprland.conf:76-87] workspaces
workspace = 1,monitor:DP-1
… workspace = 10,monitor:HDMI-A-2
(+ special:social on DP-1)

# [VERIFIED: .config/hypr/hyprland.conf:106-111] env (+ cursor exec-once)
exec-once = hyprctl setcursor catppuccin-mocha-dark-cursors 30
env = XCURSOR_THEME,Catppuccin-Mocha-Dark-Cursors
env = XCURSOR_SIZE,30
env = ILLOGICAL_IMPULSE_VIRTUAL_ENV,~/.local/state/quickshell/.venv
```

**Not migrated (D-17):** Chrome/kitty/btop/vesktop autostarts, personal binds, waybar/swaync/rofi exec-once.

**Discretion on env:** list `ILLOGICAL_IMPULSE_VIRTUAL_ENV` under env migrate **or** note “may be provided by dots-hyprland hooks after adopt” — recommend **list it under env migrate** so Phase 13 does not silently drop a known dual-run requirement if hooks lag.

### Pre-flight sync candidate list (D-07)

Research scan 2026-08-08 (`test -e` live vs repo `.config/`):

| Class | Paths | Action for Phase 14 (document now) |
|-------|-------|-------------------------------------|
| **Live-only PRESENT** (must sync into repo before full files) | `fontconfig/`, `mpv/`, `dolphinrc`, `kdeglobals`, `hypr/hyprland.conf.bak`, `hypr/hyprland-gui.conf` | rsync/cp into `.config/…` as archive |
| **Both PRESENT** (verify drift; sync if live newer/different) | `hypr/hyprland.conf` (**identical** now), `hypr/hyprland/`, `hypr/hyprlock.conf`, `hypr/hypridle.conf`, `hypr/hyprpaper.conf`, `fish/`, `kitty/`, `starship.toml`, `waybar/`, `rofi/`, `swaync/` | `diff`/`rsync` gate; chrome included for archive (D-12) |
| **Live PRESENT dual-run product tree** | `quickshell/` | **Do not** treat as personal archive SoT for product (D-08); vendor remains product SoT — optional note only |
| **ABSENT greenfield** | fuzzel, matugen, wlogout, foot, … | no pre-flight; install will create under accept-upstream |

Exact commands are Claude discretion; planner should specify read-only `diff` first, then explicit `rsync -a`/`cp -a` list — **never** in Phase 11 execution of live mutation unless a plan task is explicitly “document commands only.”

## Approaches

### Approach A — Single multi-section dispositions doc (LOCKED)

Match Phase 10 inventory shape: one markdown SoT under phase dir with axis-parallel sections and uniform tables.

| Pros | Cons |
|------|------|
| Matches D-01–D-04; Phase 12/13/14 can cite one path | Large file if every LOW greenfield gets a row |
| Mirrors operator mental model (inventory → disposition) | Chrome needs emerged-surface note (not inventing from inventory) |
| Assert script can lint one file | — |

**Verdict:** **Required** by CONTEXT.

### Approach B — Split per-axis disposition files

| Pros | Cons |
|------|------|
| Smaller diffs | Violates D-01/D-02 single file |
| — | Harder Phase 14 gate “DISP-* satisfied” |

**Verdict:** Rejected (locked single artifact).

### Approach C — Staged hypr-first flag profile (prior auto draft)

Document Stage 1 drop only `--skip-hyprland`, later core/sysupdate.

| Pros | Cons |
|------|------|
| Lower blast radius per step | **Superseded** by D-05/D-32 full greenfield first adopt |
| Matches older ROADMAP “not assumed all three” *wording* if misread as “must stage” | DISP-02 is satisfied by **recording** the choice of all-three; independence remains for docs |

**Verdict:** Rejected for first full-adopt profile. Still document axes independently so Phase 12 can encode subsets later if needed — but **intended** first profile = drop all three.

### Approach D — Optional structural assert script

Clone `scripts/phase10-inventory-assert.sh` patterns: file exists, required sections, column header, enum whitelist, every HIGH path cited, chrome section present, no wrapper mutation claims.

| Pros | Cons |
|------|------|
| Cheap Nyquist gate; catches missing HIGH rows | Claude discretion; not required for DISP success |
| Reuses known bash assert style | Must **allow** waybar/rofi/swaync (opposite of Phase 10 D-15 ban) |

**Verdict:** **Recommended nice-to-have** Wave 0 or final plan task.

## Recommended Approach

1. **Write `11-DISPOSITIONS.md` only** (plus optional assert script) — no `arch/` edits, no live sync execution in Phase 11 plans unless purely documenting command text.
2. **Section skeleton exactly tracks D-02** (heading names free under discretion).
3. **Every HIGH (+ MED–HIGH decision) inventory path appears once** with D-03 columns; chrome in §6 with emerged-surface + sources (personal conf + INTEGRATIONS dual-run narrative).
4. **Flag profile §2** is the Phase 12 contract: residual triple unchanged on default; full opt-in drops all three; axes independent for documentation.
5. **Pre-flight §1** lists sync candidates from the table above; marks chrome archive required.
6. **DISP-03 / ROADMAP SC3 tension:** document **explicit override** language so success criteria “keep unless accepted otherwise” is **satisfied by D-11 accept-remove**, not contradicted.
7. **Optional** `scripts/phase11-dispositions-assert.sh` as structural gate.

**Primary recommendation:** Assemble one eight-section dispositions artifact from locked D-* seeds + inventory cites; treat Phase 11 as decision recording, not migration.

## Architecture Notes

### System flow (docs → later phases)

```text
  10-INVENTORY.md (effects, neutral)
           │
           ▼
  11-DISPOSITIONS.md  ◄── CONTEXT D-01..D-32 (locked seeds)
           │
     ┌─────┼──────────────┬────────────────┐
     ▼     ▼              ▼                ▼
  Phase 12            Phase 13         Phase 14
  FULL profile        hypr/custom      pre-flight sync
  from §2 flags       from §3 D-16     then full adopt
  (SAFE_DEFAULTS      must-keeps       per DISP + chrome
   stay default)                       accept-remove
```

### Recommended `11-DISPOSITIONS.md` structure (D-01..D-04)

```markdown
# Phase 11 — Disposition set

**Status:** Final — DISP-01..04
**Consumes:** 10-INVENTORY.md (SoT for paths)
**Does not:** edit wrapper, write overlays, mutate live home

## 1. Pre-flight repo sync gate (D-07)
- Purpose, sequencing (before any full files install)
- Candidate table: Path | Live | Repo | Sync action
- Explicit: chrome configs archive; no quickshell product re-SoT (D-08)

## 2. Full-adopt flag profile (DISP-02 / D-05 / D-10)
- Residual SAFE_DEFAULTS on default install (unchanged)
- Independent axes table (drop --skip-hyprland | drop --core | allow sysupdate)
- **First full-adopt profile:** drop all three (argv intent for Phase 12)
- Flag stage vocabulary used in row tables (e.g. `full-profile` | `residual-safe` | `n/a`)

## 3. Axis A — hypr HIGH + must-keeps (DISP-01)
- Uniform table: Path | Inventory risk | Disposition | Rationale | Flag stage | Inventory source
- hyprland.conf split note: migrate monitors/workspaces/env only
- hyprland/, lua, custom, scripts rows

## 4. Axis B — misc under drop --core
- PRESENT collisions individual rows (HIGH + notable MED)
- Greenfield ABSENT: single accept-upstream blurb OR compact table

## 5. Axis C — packages / sysupdate
- Syu, asdeps, metas, plasmaintg, full install/deps pipeline

## 6. Dual-run chrome accept-remove (DISP-03 / D-11)
- Emerged surface note (absent from inventory by Phase 10 D-15)
- accept-remove + archive-in-repo + same adopt window
- Explicit override of REQUIREMENTS/ROADMAP default-keep

## 7. Lock / idle / paper residual (DISP-04)
- hyprlock/hypridle keep-personal no-touch
- *.new defer; hyprpaper accept-upstream/no investment
- Product: hyprlock mechanism; no QS lock

## 8. UNKNOWN / extra surfaces
- hyprlock/ dir defer; .bak keep-personal; gui conf defer; PARTIAL asdeps note

## Sources
- Cite 10-INVENTORY.md sections + wrapper/setup paths as needed
```

### Uniform row columns (D-03) — verbatim enum

Disposition values **exactly**:

```text
keep-personal | migrate-to-hypr-custom | accept-upstream | merge | defer
```

| Column | Meaning |
|--------|---------|
| Path | Filesystem path, package name, or chrome surface id |
| Inventory risk | HIGH / MED–HIGH / MED / LOW from inventory (or `n/a (emerged)` for chrome) |
| Disposition | One of the five enum tokens |
| Rationale | One short sentence |
| Flag stage | Which flag drop enables the effect (`full-profile` / `drop-skip-hyprland` / `drop-core` / `allow-sysupdate` / `residual-safe` / `n/a`) |
| Inventory source | Path cite into `10-INVENTORY.md` section/row **or** UNKNOWN id **or** emerged-surface source |

**`merge` usage:** Locked seeds do not require `merge` for any row this operator set; enum must still be **allowed** by assert (DISP-01 lists it). Do not force-fit `merge` where accept/migrate/keep/defer is decided.

### Flag-profile shape Phase 12 will consume (DISP-02 / FULL-*)

Document a machine-readable-enough block Phase 12 can copy:

```markdown
### Residual default (SAFE_DEFAULTS — unchanged)
SAFE_DEFAULTS = --core --skip-hyprland --skip-sysupdate
Injected for: install, install-files
Not injected for: install-deps, install-setups

### First full-adopt profile (opt-in; Phase 12 encodes)
Drop: --skip-hyprland, --core, --skip-sysupdate
Resulting intent: full hypr files + full misc/fish/fontconfig + Syu-allowed deps path
Backup gate: still required
Protect re-mark: still required after install/deps
Default install must NOT accidentally use this profile (FULL-02)
```

Independence note (Phase 10 D-09 / this D-05): axes **can** be dropped singly in future tooling, but **this** disposition set’s first adopt target is the triple drop.

### Chrome accept-remove documentation pattern

```markdown
## Dual-run chrome (DISP-03)

**Emerged surface:** Waybar/rofi/swaync were **omitted** from 10-INVENTORY.md (Phase 10 D-15).
They are dispositioned here by operator decision, not invented install effects.

| Path / surface | Inventory risk | Disposition | Rationale | Flag stage | Inventory source |
|----------------|----------------|-------------|-----------|------------|------------------|
| waybar session chrome | n/a (emerged) | accept-upstream* | Explicit full-adopt remove; stop exec-once | full-profile (conf→.old) | emerged: Phase 10 D-15 omit; conf:64; D-11 |
| rofi launcher chrome | n/a (emerged) | accept-upstream* | Rely on ii defaults (D-13) | full-profile | emerged + conf binds |
| swaync notifications | n/a (emerged) | accept-upstream* | Same | full-profile | emerged + conf:64 |

\* Semantic label for “accept removal of personal dual-run chrome / do not migrate.”
If enum purity required, use `accept-upstream` with rationale “accept-remove dual-run chrome (D-11)” —
do **not** invent a sixth enum token. Prefer `accept-upstream` + clear rationale over new vocabulary.

**Archive:** `.config/{waybar,rofi,swaync}` remain in repo (D-12). Pre-flight ensures live→repo sync.
**Override statement:** This **explicitly accepts otherwise** vs DISP-03/ROADMAP SC3 default-keep.
```

### Optional assert script feasibility

`scripts/phase10-inventory-assert.sh` pattern is directly reusable:

| Check | Phase 10 analog | Phase 11 proposal |
|-------|-----------------|-------------------|
| File exists | `10-INVENTORY.md` | `11-DISPOSITIONS.md` |
| Required sections | SAFE_DEFAULTS, axes, host, UNKNOWN | pre-flight, flag profile, Axis A/B/C, chrome, lock/idle, UNKNOWN |
| Column header | Path\|Effect\|Risk\|… | Path\|Inventory risk\|Disposition\|Rationale\|Flag stage\|Inventory source |
| Token presence | `--core` etc. | all five enum tokens **allowed**; at least used dispositions present |
| Every HIGH cited | n/a (inventory is source) | `rg -F` each HIGH path string from inventory list |
| Chrome | **ban** waybar\|rofi\|swaync | **require** waybar **and** rofi **and** swaync + accept-remove/override language |
| No live mutation | process | fail if doc claims Phase 11 ran install / rsync to XDG as completed work |
| SAFE_DEFAULTS residual | remains available | require claim default install still injects triple (D-10) |

**Feasible:** yes, ~100–150 lines bash, no new packages. Claude discretion — recommend include as Wave 0 or final verification task.

### Anti-patterns

- **Inventing inventory paths** without emerged-surface note (violates D-04).
- **`keep-personal` on `hyprland.conf` as primary entry** (blocks ADOPT-02; violates D-15).
- **Migrating binds/autostart “just in case”** beyond D-16 (scope creep into Phase 13).
- **Editing `SAFE_DEFAULTS` in Phase 11** (D-10; belongs Phase 12).
- **Executing pre-flight rsync in Phase 11** unless plan is docs-only command listing (prefer Phase 14 gate).
- **Using Phase 10 assert chrome ban** unchanged — dispositions **must** name chrome.
- **Treating ROADMAP SC3 “keep” as blocking D-11** — SC3 is default-until-explicit; D-11 is the explicit accept.

## Standard Stack

This phase installs **no new packages**. Stack = existing repo + markdown + optional bash assert.

### Core

| Asset | Path / version | Purpose | Why standard |
|-------|----------------|---------|--------------|
| `10-INVENTORY.md` | phase 10 SoT | Rows to disposition | DISP-* consume inventory |
| `11-CONTEXT.md` | locked D-* | Decision seeds | Do not re-open |
| `arch/dots-hyprland.sh` | SAFE_DEFAULTS residual | Flag profile residual claims | Phase 12 boundary |
| `scripts/phase10-inventory-assert.sh` | assert pattern | Optional phase 11 assert | Proven Nyquist style |
| Personal `.config/hypr/hyprland.conf` | repo + live | Must-keep category source | D-16 extraction reference |

### Supporting

| Asset | Purpose |
|-------|---------|
| `.planning/codebase/INTEGRATIONS.md` | Dual-run chrome wiring narrative for emerged-surface cites |
| `docs/dots-hyprland-workflow.md` | Current safe dual-run path (will be superseded Phase 15) |
| Host `test`/`diff`/`rsync` | Pre-flight candidate verification (read-only in research; sync later) |

### Alternatives considered

| Instead of | Could use | Tradeoff |
|------------|-----------|----------|
| Single `11-DISPOSITIONS.md` | Per-axis files | Forbidden by D-01/D-02 |
| Enum `accept-remove` token | Sixth enum value | Breaks DISP-01 five-value contract; use `accept-upstream` + rationale |
| Live host re-inventory | Trust 10-INVENTORY.md | Deferred unless material drift; research refreshed presence for pre-flight only |

**Installation:** none.

## Package Legitimacy Audit

> Docs/analysis phase — **no external packages installed**.

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| — | — | — | — | — | N/A | No installs |

**Packages removed due to [SLOP] verdict:** none  
**Packages flagged as suspicious [SUS]:** none

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Re-derive install effects | New inventory from memory | `10-INVENTORY.md` cites | Drift vs Phase 10 SoT |
| Full-profile wrapper flags | Edit `SAFE_DEFAULTS` now | Phase 12 FULL-* from §2 profile | D-10 anti-goal |
| Overlay Lua for monitors | Write `hypr/custom` in Phase 11 | Phase 13 from D-16 list | Wrong phase |
| Chrome clash inventory rewrite | Add waybar rows to 10-INVENTORY | Emerged-surface section in dispositions | Phase 10 D-15 intentional omit |
| Per-package protect list expansion | New PROTECT_EXPLICIT invent | Existing wrapper protect | D-29 |
| Custom disposition enum | Free-text statuses | Five tokens only | DISP-01 / assertability |

**Key insight:** Phase 11 value is **decision completeness and Phase 12/13/14 contracts**, not new tooling or host mutation.

## Risks / Pitfalls

### Pitfall 1: Missing HIGH inventory rows
**What goes wrong:** DISP-01 fails; Phase 14 gate incomplete.  
**Why:** Scripts subset, Syu, or asdeps rows forgotten; host-snapshot restates confused with effect rows.  
**How to avoid:** Checklist of 13 unique HIGH paths above; assert `rg -F` each.  
**Warning signs:** Axis C only mentions metas, not Syu/asdeps.

### Pitfall 2: Inventing surfaces
**What goes wrong:** Dispositions cite paths never in inventory without emerged note.  
**Why:** Operator memory / INTEGRATIONS extras.  
**How to avoid:** D-04 rule; chrome is the main legitimate emerged set.  
**Warning signs:** Rows for apps not in misc catalog and not chrome/hypr extras.

### Pitfall 3: Scope creep to live mutation
**What goes wrong:** Phase 11 “helpfully” rsyncs live→repo or dry-runs full install.  
**Why:** Pre-flight feels actionable now.  
**How to avoid:** Plans document commands; execution belongs Phase 14 (or explicit docs-only task).  
**Warning signs:** PLAN steps calling `rsync` to `$HOME/.config` or non-dry-run setup.

### Pitfall 4: ROADMAP SC3 keep vs D-11 remove
**What goes wrong:** Planner/verifier treats “default keep” as hard requirement and flags accept-remove as failure — or omits override language so DISP-03 looks unmet.  
**Why:** REQUIREMENTS.md and ROADMAP SC3 word default-keep; CONTEXT D-11 overrides.  
**How to avoid:** Chrome section **must** state: “Explicit acceptance otherwise per DISP-03 / ROADMAP SC3; disposition = accept-remove (D-11).”  
**Warning signs:** Chrome section says only “remove” without tying to DISP-03 override clause.

### Pitfall 5: `keep-personal` on hyprland.conf primary
**What goes wrong:** ADOPT-02 blocked; session never switches to lua entry.  
**Why:** Fear of losing binds.  
**How to avoid:** D-15/D-16 split only; autostart/binds explicitly dropped (D-17).

### Pitfall 6: Lock migration “for completeness”
**What goes wrong:** Boot-risk lock changes operator rejected.  
**Why:** HIGH risk on hyprlock row tempts accept-upstream.  
**How to avoid:** D-24 no-touch; host not-firstrun already safe (`*.new` only).

### Pitfall 7: Expanding must-migrate set
**What goes wrong:** Phase 13 balloon; dual-run chrome sneaks into overlays via exec-once migrate.  
**Why:** Category counts (100 binds) look “important.”  
**How to avoid:** D-16 **only** monitors, workspaces, env.

### Pitfall 8: Dropping `--core` without pre-flight archive
**What goes wrong:** Personal fish/kitty/starship only on live, then rsync `--delete` / cp -f.  
**Why:** D-27 accept-upstream on live without D-07.  
**How to avoid:** §1 pre-flight lists PRESENT collisions including live-only fontconfig/mpv/dolphinrc/kdeglobals.

### Pitfall 9: Phase 10 chrome ban copy-paste into phase 11 assert
**What goes wrong:** Assert fails because dispositions correctly mention waybar.  
**How to avoid:** Invert ban → require chrome section.

### Pitfall 10: Assuming all-three drop without writing staged axes
**What goes wrong:** DISP-02 / ROADMAP SC2 “not assumed all three” fails documentation-wise.  
**How to avoid:** §2 shows three independent axis decisions **and** the combined first profile.

## Code Examples

### SAFE_DEFAULTS residual (flag profile §2 must restate)

```bash
# Source: [VERIFIED: arch/dots-hyprland.sh:12]
SAFE_DEFAULTS=(--core --skip-hyprland --skip-sysupdate)

# Source: [VERIFIED: arch/dots-hyprland.sh:127-131]
needs_safe_defaults() {
  case "$1" in
    install|install-files) return 0 ;;
    *) return 1 ;;
  esac
}
```

### Example disposition row (Axis A)

```markdown
| Path | Inventory risk | Disposition | Rationale | Flag stage | Inventory source |
|------|----------------|-------------|-----------|------------|------------------|
| `~/.config/hypr/hyprland.conf` | HIGH | migrate-to-hypr-custom + accept-upstream | Must-keeps (monitors/workspaces/env) → hypr/custom; conf→.old remainder upstream | full-profile (drop --skip-hyprland) | 10-INVENTORY.md Axis A hyprland.conf row |
```

Prefer **two rows** if single-cell multi-disposition confuses assert: one for “conf primary entry → accept-upstream (via .old)”, one for “must-keep categories → migrate-to-hypr-custom.”

### Optional assert skeleton (discretion)

```bash
# Pattern after scripts/phase10-inventory-assert.sh
DISP=".planning/phases/11-disposition-decisions/11-DISPOSITIONS.md"
test -f "$DISP"
grep -qiE 'Pre-flight|flag profile|Axis A|chrome|hyprlock' "$DISP"
grep -qiE 'Path.*Inventory risk.*Disposition.*Rationale.*Flag stage.*Inventory source' "$DISP"
for d in keep-personal migrate-to-hypr-custom accept-upstream defer; do
  grep -qF "$d" "$DISP" || echo "missing token $d"
done
# HIGH path samples
for p in hyprland.conf hyprland.lua starship.toml 'pacman -Syu' fish; do
  grep -qF "$p" "$DISP" || echo "missing HIGH cite $p"
done
# Chrome required (inverse of phase10)
grep -qiE 'waybar' "$DISP" && grep -qiE 'rofi' "$DISP" && grep -qiE 'swaync' "$DISP"
grep -qiE 'accept-remove|explicit.*remove|overrides? DISP-03|accepted otherwise' "$DISP"
# Residual safe still default
grep -qF -- '--skip-hyprland' "$DISP" && grep -qiE 'SAFE_DEFAULTS|residual|default' "$DISP"
```

## Validation Architecture

> `workflow.nyquist_validation` is **true** in `.planning/config.json`. Doc-only phase → structural/lint gates, not unit tests.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Shell/assert checklist (no Jest/pytest for planning markdown) |
| Config file | none — Wave 0 optional `scripts/phase11-dispositions-assert.sh` |
| Quick run command | `test -f .planning/phases/11-disposition-decisions/11-DISPOSITIONS.md && rg -n 'Disposition|SAFE_DEFAULTS|waybar|hyprlock|migrate-to-hypr-custom' .planning/phases/11-disposition-decisions/11-DISPOSITIONS.md` |
| Full suite command | Optional `./scripts/phase11-dispositions-assert.sh` + manual HIGH-path checklist |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| DISP-01 | Every HIGH inventory path has disposition + rationale | docs/structure | `rg -F` each HIGH path in `11-DISPOSITIONS.md`; enum tokens only | ❌ until artifact written |
| DISP-01 | Columns Path\|Inventory risk\|Disposition\|Rationale\|Flag stage\|Inventory source | docs/structure | `rg -n 'Inventory risk.*Disposition.*Rationale.*Flag stage'` | ❌ Wave 0 |
| DISP-02 | Three axes documented + first profile drops all three + residual safe default | docs/structure | `rg -n 'skip-hyprland|--core|skip-sysupdate|SAFE_DEFAULTS' 11-DISPOSITIONS.md` | ❌ |
| DISP-03 | Chrome explicit accept-remove override of default-keep | docs/lint | `rg -ni 'waybar|rofi|swaync' 11-DISPOSITIONS.md` **expect hits**; override language present | ❌ |
| DISP-04 | hyprlock/hypridle no-touch + hyprlock mechanism + no QS lock | docs/structure | `rg -n 'hyprlock|hypridle|keep-personal|Quickshell lock' 11-DISPOSITIONS.md` | ❌ |
| D-04 | No invented paths without emerged note | docs/lint | Manual: every Path cites inventory or emerged | process |
| D-10 | No claim that default wrapper already full | docs/lint | Residual SAFE_DEFAULTS still default language present | ❌ |
| D-16 | Must-migrate only monitors/workspaces/env | docs/lint | migrate-to-hypr-custom rows limited to those categories | manual/rg |
| Process | No live full install / XDG rsync as Phase 11 work | process | Plan bans; verifier reads PLAN steps | process |

### Sampling Rate

- **Per task commit:** `rg` section just written + enum spot-check  
- **Per wave merge:** full HIGH-path checklist + chrome override language  
- **Phase gate:** `11-DISPOSITIONS.md` committed; DISP-01..04 rg checks green; optional assert script exit 0  

### Wave 0 Gaps

- [ ] `11-DISPOSITIONS.md` — does not exist yet (phase output)
- [ ] Optional `scripts/phase11-dispositions-assert.sh` — nice-to-have
- [ ] HIGH-path fixture list embedded in assert or PLAN verification block
- [ ] Framework install: none (`bash`, `rg`/`grep`, `test`)

*(Nyquist for this phase = artifact structural completeness, not runtime session tests.)*

## Security Domain

> `security_enforcement` enabled (ASVS level 1). Documentation + optional read-only drift checks only.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | partial | Dispositions are trusted operator markdown; no unsanitized external paste |
| V6 Cryptography | no | — |
| V1 Architecture | yes | No live mutation; least privilege (read inventory + optional `test -e`/`diff`) |
| File system integrity | yes | Forbid install/rsync to XDG in Phase 11 execution plans |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Accidental full install while “documenting flags” | Tampering | D-10; plans ban non-dry-run setup |
| Pre-flight rsync wrong direction (repo→live) before adopt | Tampering | Document live→repo only for archive; Phase 14 sequences |
| Dispositions used as destructive runbook (“rm waybar”) | Tampering | accept-remove = stop launching / don’t migrate — not delete-from-repo (D-12) |
| Secret leakage into dispositions | Information disclosure | Cite categories/paths only; no paste of tokens from conf |
| Prompt injection via external docs | Tampering | In-repo inventory + CONTEXT primary |

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| bash | Optional assert script | ✓ | system | Inline `rg`/`test` in PLAN |
| rg or grep | Structural checks | ✓ | system | — |
| test / diff | Pre-flight candidate verification | ✓ | system | — |
| rsync | Documented pre-flight commands only | ✓ | /usr/bin/rsync | `cp -a` |
| `10-INVENTORY.md` | SoT rows | ✓ | committed | — |
| Live `~/.config` | Optional drift refresh | ✓ | host | Trust inventory host snapshot + research 2026-08-08 scan |
| Network / pacman writes | Not required | N/A | — | — |

**Missing dependencies with no fallback:** none.

**Step 2.6:** External tools only for read-only checks + future documented sync — all present. No package installs.

## Open Questions

1. **`ILLOGICAL_IMPULSE_VIRTUAL_ENV` migrate vs hooks**  
   - What we know: present in personal conf; dual-run needed it when skip-hyprland skipped ii env.lua.  
   - What’s unclear: whether full adopt lua/env hooks always set it.  
   - **Recommendation:** List under env **migrate-to-hypr-custom** (safe); Phase 13 can no-op if hooks proven.

2. **Single vs dual rows for hyprland.conf**  
   - What we know: D-15 split migrate + accept.  
   - **Recommendation:** Two table rows for assert clarity (categories vs primary entry).

3. **Optional assert script in-repo?**  
   - Discretion: **yes, cheap** — mirror phase10; invert chrome rule.

4. **Host snapshot age (2026-08-04 inventory vs 2026-08-08 research)**  
   - Research rechecked presence for pre-flight; hyprland.conf still identical.  
   - **Recommendation:** No full re-inventory; note pre-flight verify-diff at Phase 14.

5. **Enum token for chrome accept-remove**  
   - **Recommendation:** `accept-upstream` + rationale containing `accept-remove` / D-11; do not extend enum.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `accept-upstream` is the correct enum carrier for chrome accept-remove semantics | Chrome § | If planner invents non-enum token, DISP-01 assert breaks |
| A2 | Scripts HIGH row may fold under hyprland/ dir row if explicitly cited | Row map | Under-cite risk if fold without mention |
| A3 | LOW greenfield misc can be one blurb (discretion) | Axis B | DISP-01 “every high-risk” still OK; LOW not required line-by-line |
| A4 | Phase 11 will not execute pre-flight rsync | Process | If plans execute early, still OK if careful — but out of preferred sequencing |
| A5 | Live/repo hyprland.conf remain identical until Phase 14 | Pre-flight | Re-diff at adopt time |

**If wrong:** mostly documentation/assert issues, not runtime — except A4 sequencing.

## Sources

### Primary (HIGH confidence)

- `[VERIFIED: .planning/phases/11-disposition-decisions/11-CONTEXT.md]` — D-01..D-32 locked decisions (read full this session)
- `[VERIFIED: .planning/phases/10-full-install-impact-inventory/10-INVENTORY.md]` — HIGH/MED rows, axes, UNKNOWN, SAFE_DEFAULTS residual (read full)
- `[VERIFIED: .planning/REQUIREMENTS.md]` — DISP-01..04 text
- `[VERIFIED: .planning/ROADMAP.md]` — Phase 11 success criteria SC1–SC4 incl. SC3 chrome keep default
- `[VERIFIED: arch/dots-hyprland.sh:12,127-131,1399-1407]` — SAFE_DEFAULTS definition + injection
- `[VERIFIED: scripts/phase10-inventory-assert.sh]` — assert pattern (read full)
- `[VERIFIED: .config/hypr/hyprland.conf:29-30,64,76-87,106-111,259,270,277]` — monitors, chrome exec-once, workspaces, env, binds
- `[VERIFIED: host scan 2026-08-08]` — live vs repo PRESENT drift for pre-flight candidates; hyprland.conf identical

### Secondary (MEDIUM confidence)

- `[CITED: .planning/codebase/INTEGRATIONS.md]` — dual-run chrome wiring overview
- `[CITED: .planning/phases/10-full-install-impact-inventory/10-RESEARCH.md]` — structure analog, pitfalls, validation pattern
- `[CITED: docs/dots-hyprland-workflow.md]` — safe dual-run operator narrative (secondary)

### Tertiary (LOW confidence)

- `[ASSUMED]` Full-adopt upstream hooks always reinstall equivalent launcher/notification binds after chrome remove (D-13 relies on defaults)
- `[ASSUMED]` Coarse package dispositions sufficient without expanding every PKGBUILD depend

## Project Constraints (from CLAUDE.md)

No project-root `CLAUDE.md` / `.claude/CLAUDE.md` found this session. Follow CONTEXT.md locked decisions and existing conventions:

- Thin wrapper around upstream `./setup`; never reimplement package lists in `arch/`
- Do not call upstream `./setup uninstall` as rollback
- Planning artifacts under `.planning/phases/…` (phase-dir SoT)
- SAFE_DEFAULTS remain default until Phase 12 explicit opt-in
- No QS lock screen investment (product constraint)

## Metadata

**Confidence breakdown:**
- Inventory → disposition row map: **HIGH** — full inventory read + HIGH path enumeration
- Flag profile / SAFE_DEFAULTS: **HIGH** — wrapper source verified
- Chrome override documentation: **HIGH** — CONTEXT D-11 + REQUIREMENTS/ROADMAP tension explicitly analyzed
- Pre-flight candidate list: **HIGH** for presence classes; **MEDIUM** for exact rsync command flags (discretion)
- Optional assert design: **HIGH** — phase10 pattern exists

**Research date:** 2026-08-08  
**Valid until:** 30 days or until `10-INVENTORY.md` / SAFE_DEFAULTS / CONTEXT D-* change  

**Graph context:** `.planning/graphs/graph.json` absent — skipped.

**Runtime State Inventory:** Omitted (not a rename/refactor phase; docs decision artifact). Note: pre-flight concerns **future** runtime capture of live-only configs — listed under Current State, not as this-phase mutation.

**Agent skills:** none configured for `gsd-phase-researcher`.  
**Project skills dir:** none found.

## RESEARCH COMPLETE
