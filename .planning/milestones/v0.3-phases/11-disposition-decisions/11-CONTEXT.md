# Phase 11: Disposition decisions - Context

**Gathered:** 2026-08-08
**Status:** Ready for planning
**Mode:** Interactive discuss (fresh restart; supersedes 2026-08-07 `--auto` draft)

<domain>
## Phase Boundary

Produce a **committed disposition set** so every high-risk inventory row and flag axis has an explicit human-facing decision **before** wrapper full-profile work (Phase 12), overlay migration (Phase 13), or live full adopt (Phase 14).

**In scope (DISP-01..04):**
- Per high-risk `10-INVENTORY.md` row: disposition enum + short rationale
- Staged flag profile: first full-adopt argv vs residual SAFE_DEFAULTS (all three axes decided)
- Dual-run chrome (Waybar/rofi/swaync) disposition — explicit accept-remove for full adopt
- hyprlock/hypridle disposition consistent with product (hyprlock mechanism, no QS lock investment) and operator low-touch preference

**Out of scope this phase:**
- Implementing wrapper full-profile opt-in — Phase 12
- Writing hypr/custom overlay files — Phase 13
- Live full install / session mutation — Phase 14
- Playbook safe-vs-full polish — Phase 15
- Re-running Phase 10 inventory (consume as SoT; refresh host presence only if a plan task needs it for a specific UNKNOWN)
- CUST-* Waybar custom ports as a delivery project
- Reviving local Quickshell product tree

**Requirements:** DISP-01, DISP-02, DISP-03, DISP-04

</domain>

<decisions>
## Implementation Decisions

### Disposition artifact shape
- **D-01:** Deliverable is a single committed file: `.planning/phases/11-disposition-decisions/11-DISPOSITIONS.md` (phase-dir SoT; not under `docs/`). — **Reversibility:** reversible
- **D-02:** One multi-section markdown document parallel to inventory axes: (1) pre-flight repo sync gate, (2) full-adopt flag profile (all three axes), (3) Axis A hypr HIGH rows + must-keep categories, (4) Axis B misc rows under dropped `--core`, (5) Axis C packages/sysupdate, (6) dual-run chrome accept-remove, (7) lock/idle/paper residual, (8) UNKNOWN / extra surfaces. — **Reversibility:** reversible
- **D-03:** Uniform disposition row columns: **Path | Inventory risk | Disposition | Rationale | Flag stage | Inventory source**. Disposition enum exactly: `keep-personal` | `migrate-to-hypr-custom` | `accept-upstream` | `merge` | `defer`. — **Reversibility:** reversible
- **D-04:** Every disposition row must cite the inventory path/row (or UNKNOWN id). Do not invent surfaces absent from `10-INVENTORY.md` without an explicit "emerged surface" note + source. — **Reversibility:** reversible

### First full-adopt flag profile (DISP-02)
- **D-05:** Flag axes remain **independent** (Phase 10 D-09) for documentation, but **first full-adopt profile drops all three SAFE_DEFAULTS residuals**: no `--skip-hyprland`, no `--core`, no `--skip-sysupdate`. This is the greenfield full dots-hyprland install (North Star now, not a later Stage 2/3). — **Reversibility:** costly — Phase 12 FULL-* encoding and Phase 14 gates consume this; undoing reintroduces staged narrower profiles
- **D-06:** Product model: **full dots-hyprland only** + **repo personal layer**. No local Quickshell product revival. Upstream shell may still be named `ii` (`qs -c ii`); that is dots-hyprland naming, not a separate product. — **Reversibility:** costly — framing for Phases 12–15 and playbook
- **D-07:** **Pre-flight gate (required before any full files install):** sync live `~/.config` PRESENT personal configs into repo `.config/` so nothing personal exists only on live. Repo is the fresh-reinstall bootstrap for personal/dotfiles content. — **Reversibility:** costly — adopt plans must sequence capture before mutation
- **D-08:** After full adopt, **live** home is dots-hyprland-managed for replaced surfaces; **repo** retains pre-flight personal copies as archive/bootstrap material plus the small must-keep overlay set (D-16). Do **not** re-sync entire live ii tree back into `.config` as the primary SoT for product configs (vendor/submodule remains product SoT). — **Reversibility:** costly
- **D-09:** Cold-machine path intent: clone this repo → full dots-hyprland setup via wrapper full profile → apply personal must-keep overlays from repo. — **Reversibility:** reversible (docs/playbook later)
- **D-10:** SAFE_DEFAULTS on default `install` / `install-files` **unchanged** this phase (Phase 12 implements explicit opt-in full path). Dispositions describe the **intended full profile**, not live wrapper default edits. — **Reversibility:** one-way if violated — accidental default full install is milestone anti-goal

### Dual-run chrome (DISP-03)
- **D-11:** Waybar / rofi / swaync session chrome disposition = **explicit accept-remove** on full adopt (overrides DISP-03 default-keep). Operator chose remove for full product cutover. — **Reversibility:** costly — CUT-01 effectively folded into full adopt; re-adding dual-run later is a new decision
- **D-12:** Chrome configs **stay in repo as archive** (pre-flight sync captures them). Stop launching from hypr `exec-once`; do not delete from repo as part of Phase 11–14 success. — **Reversibility:** reversible
- **D-13:** Launcher/notification keybinds: **rely on dots-hyprland defaults** after chrome removal. Do not require a must-remap bind list in dispositions for SUPER+N / cliphist-rofi / waybar toggle / etc. — **Reversibility:** reversible
- **D-14:** Timing: chrome stops in the **same adopt window** as full files install (when conf→`.old` / lua entry lands, personal waybar/rofi/swaync exec-once are **not** carried into must-keep overlays). — **Reversibility:** costly — no dual-run comparison boot required by plan

### Personal hypr must-keeps (DISP-01 / Axis A)
- **D-15:** `hyprland.conf` → will `mv` to `.old` under full adopt. Strategy: extract must-keeps → **`migrate-to-hypr-custom`**; remainder **`accept-upstream`** via dots-hyprland `hyprland/` + `hyprland.lua`. Do **not** `keep-personal` the conf as primary session entry (blocks ADOPT-02). — **Reversibility:** costly — Phase 13/14 session model
- **D-16:** Must-migrate set (**only**): **monitors** (DP-1 / HDMI-A-2 dual setup), **workspaces** layout pins, **env** machine paths (including cursor / `ILLOGICAL_IMPULSE_VIRTUAL_ENV` as needed for session). Via **`hypr/custom`** overlays — minimal custom (no extra fluff). — **Reversibility:** costly
- **D-17:** Autostart apps (Chrome, kitty+tmux, btop special, vesktop/discord), personal tool binds (define.sh, hyprshot, cliphist-rofi, special workspace binds), and chrome-related exec-once: **`accept-upstream` / drop** — not migrated. — **Reversibility:** reversible
- **D-18:** `hyprland/` dir sync (`rsync --delete`) → **`accept-upstream`**. Personal scripts under `hyprland/scripts/` already tracked in repo; pre-flight sync covers capture. No special live migrate-out task beyond D-07. — **Reversibility:** one-way on live sync without backup (backup gate still applies at install)
- **D-19:** `hyprland.lua` → **`accept-upstream`** (install entry required for dots-hyprland session model). — **Reversibility:** costly
- **D-20:** `hypr/custom/` currently ABSENT → allow ii seed on first install (`ignore_existing`), then Phase 13 populates **only** D-16 must-keeps. Earlier “custom not important” means no extra custom beyond that set — not “skip overlays entirely.” — **Reversibility:** costly
- **D-21:** `hyprpaper.conf` / wallpaper → **not important**; disposition **`accept-upstream`** / no investment (may be unused after chrome/paper dual-run ends). — **Reversibility:** reversible
- **D-22:** Extra live surfaces (`.bak`, `hyprland-gui.conf`) → **`keep-personal`** for operator backups; **`defer`** for unused gui conf if unclear. Recommended: `.bak` **`keep-personal`**, `hyprland-gui.conf` **`defer`**. Non-install targets; do not block adopt. — **Reversibility:** reversible

### hyprlock / hypridle (DISP-04)
- **D-23:** Product still uses **hyprlock as lock mechanism** if anything locks — **no Quickshell lock screen investment**. — **Reversibility:** costly — PROJECT constraint
- **D-24:** Operator **does not use lock** and wants **no boot-risk changes**. Disposition: **leave live `hyprlock.conf` / `hypridle.conf` alone** (`keep-personal` / no-touch). Host not-firstrun already writes only `*.new` sidecars — do **not** promote `.new` to live; do **not** force firstrun replace for lock/idle this milestone. — **Reversibility:** reversible
- **D-25:** `*.new` lock/idle sidecars → **`defer`** (ignore unless operator later reviews). — **Reversibility:** reversible
- **D-26:** `hyprlock/` dir gap (UNKNOWN) → **`defer`**; not a blocker given no-touch lock policy. — **Reversibility:** reversible

### Misc / packages under full profile (Axes B–C)
- **D-27:** Because full adopt **drops `--core`**, all misc catalog rows (PRESENT collisions and greenfield ABSENT) → **`accept-upstream`** on **live** home. — **Reversibility:** one-way on live without backup — pre-flight D-07 + install backup gate are the safety net
- **D-28:** PRESENT collisions of note (fish, kitty, starship, fontconfig, mpv, dolphinrc, kdeglobals, …): live **`accept-upstream`**; personal copies remain in **repo only as archive** after pre-flight — **no post-install reapply** over live. — **Reversibility:** costly if operator later wants personal fish/kitty as active layer
- **D-29:** Packages path: **`accept-upstream`** full deps — allow `pacman -Syu`, meta `illogical-impulse-*` packages, and asdeps demotion residual. Document risk in dispositions; do not invent new protect lists here (wrapper protect/re-mark remains as implemented). — **Reversibility:** one-way for system package state
- **D-30:** `plasma-browser-integration` / optional plasmaintg: **`accept-upstream` if setup wants it** (including possible KDE pull). — **Reversibility:** costly (package footprint)
- **D-31:** Coarse already-installed `illogical-impulse-*` metas → **`accept-upstream`** (remain managed); no uninstall campaign. — **Reversibility:** reversible

### North Star
- **D-32:** Phase 10 D-17 North Star (default full dots-hyprland as on a new machine) **is** the first full-adopt target (D-05). No intermediate “hypr-only Stage 1” for this operator decision set. — **Reversibility:** costly relative to prior auto draft that staged hypr-first

### Claude's Discretion
- Exact markdown heading names and table grouping inside `11-DISPOSITIONS.md` as long as D-01–D-04 hold
- Whether LOW residual rows get individual lines or a single “accept-upstream under full profile” blurb
- Rationale wording length (one short sentence preferred)
- Optional assert/lint script for disposition enum + required columns (nice-to-have; reuse Phase 10 assert patterns if cheap)
- Exact pre-flight sync command set (rsync/cp list) — planner/research derive from PRESENT inventory + repo drift
- Whether `ILLOGICAL_IMPULSE_VIRTUAL_ENV` is listed under env migrate or assumed provided by dots-hyprland hooks after adopt

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Planning / requirements
- `.planning/PROJECT.md` — v0.3 full install; inventory→disposition→adopt; hyprlock mechanism; dual-run history
- `.planning/REQUIREMENTS.md` — **DISP-01**, **DISP-02**, **DISP-03**, **DISP-04** (and FULL/ADOPT/OVL for boundary only)
- `.planning/ROADMAP.md` — Phase 11 goal + success criteria; phases 12–15 dependencies
- `.planning/STATE.md` — current position (Phase 11)
- `.planning/research/FEATURES.md` — personal surfaces / flag independence (if still present)
- `.planning/research/SUMMARY.md` — milestone rationale

### Prior phase decisions (do not re-open inventory shape)
- `.planning/phases/10-full-install-impact-inventory/10-CONTEXT.md` — D-01..D-17 inventory rules; D-09 flag independence; D-12 neutral inventory; D-15 chrome omission; D-17 North Star
- `.planning/phases/10-full-install-impact-inventory/10-INVENTORY.md` — **SoT for rows to disposition** (HIGH risks, host presence, UNKNOWN)
- `.planning/phases/10-full-install-impact-inventory/10-UAT.md` — Phase 10 UAT complete 7/7
- `.planning/milestones/v0.2-phases/06-thin-setup-wrapper-safe-defaults/06-CONTEXT.md` — SAFE_DEFAULTS + backup gate
- `.planning/milestones/v0.2-phases/07-install-session-hooks-dual-run-verify/07-CONTEXT.md` — live dual-run + personal hypr hooks
- `docs/dots-hyprland-workflow.md` — current safe dual-run operator path (will be superseded for full profile in Phase 15)

### Install / evidence SoT
- `arch/dots-hyprland.sh` — SAFE_DEFAULTS injection, backup gate, protect re-mark
- `vendor/dots-hyprland/sdata/subcmd-install/options.sh` — `--core`, `--skip-hyprland`, `--skip-sysupdate`
- `vendor/dots-hyprland/sdata/subcmd-install/3.files-legacy.sh` — hypr/misc effects cited in inventory
- `vendor/dots-hyprland/sdata/dist-arch/install-deps.sh` — Syu / asdeps / metas / plasmaintg

### Repo personal layer (bootstrap)
- `.config/hypr/hyprland.conf` — personal hypr SoT today (identical to live at discuss time); source for must-keep extraction
- `.config/` tree — pre-flight sync target; fresh-reinstall personal archive

### Codebase maps (orientation)
- `.planning/codebase/ARCHITECTURE.md` — provisioning vs config layers
- `.planning/codebase/INTEGRATIONS.md` — hypr exec-once dual-run chrome wiring
- `.planning/codebase/CONCERNS.md` — machine-specific monitors / personal knobs

No SPEC.md for this phase — requirements fully in REQUIREMENTS.md + decisions above.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `10-INVENTORY.md` — complete row set + risks + host presence for disposition tables
- `scripts/phase10-inventory-assert.sh` — pattern reference if a light disposition structural assert is added
- `arch/dots-hyprland.sh` — residual flags; Phase 12 encodes full profile from D-05
- Live + repo `hyprland.conf` — identical at discuss time; source for D-16 category extraction (Phase 13 executes)
- Repo `.config/{fish,kitty,starship.toml,waybar,rofi,swaync,hypr}` — partial personal tree; pre-flight must fill drift (fontconfig/mpv live-only, etc.)

### Established Patterns
- Phase-dir SoT markdown artifacts (inventory → dispositions)
- Independent flag axes in docs; full profile may still drop all three together
- Neutral inventory → explicit dispositions (no dispositions in inventory)
- Thin wrapper; no reimplementation of upstream package lists in `arch/`
- Backup gate on live install paths

### Integration Points
- Phase 12 consumes D-05 full flag profile → FULL-01 opt-in path (SAFE_DEFAULTS stay default)
- Phase 13 consumes D-15/D-16 migrate categories → minimal hypr/custom overlays
- Phase 14 consumes full DISP-* + chrome accept-remove D-11/D-14 + pre-flight D-07
- Phase 15 documents safe vs full using D-05 + chrome remove + personal layer policy

</code_context>

<specifics>
## Specific Ideas

- Repo purpose stated by operator: **all dotfiles configs for fresh reinstall** — not a temporary dump.
- “No ii, only dots-hyprland” clarified as: product is dots-hyprland; no local QS revival; `ii` may remain upstream shell name.
- Dual-run chrome **removed** on full adopt (explicit DISP-03 override); configs **archived in repo**.
- Must-keeps deliberately **narrow**: monitors + workspaces + env only.
- Lock/idle: operator does not use lock — **no boot-risk lock migration**.
- Wallpaper/hyprpaper: disposable.
- Full greenfield includes **accepting Syu/asdeps** and **plasmaintg if setup wants it**.
- Prior 2026-08-07 auto CONTEXT (hypr-only Stage 1, keep chrome, defer misc) is **superseded** by this discussion.

</specifics>

<deferred>
## Deferred Ideas

- CUST-01..04 Waybar custom ports — backlog; chrome archived in repo for possible later use
- Formal CUT-01 as separate milestone — effectively satisfied by D-11 for full adopt; no separate dual-run keep path required
- Promoting hyprlock/hypridle `.new` sidecars or adopting upstream lock visuals — only if operator later cares about lock
- Optional disposition assert harness (Claude discretion)
- Live host re-scan if inventory host snapshot drifts materially before full adopt
- Post-adopt reapply of personal fish/kitty/starship over live — explicitly rejected for now (D-28); reopen only if daily driver breaks

None of the above expand Phase 11 scope beyond recording dispositions / gates.

</deferred>

---

*Phase: 11-Disposition decisions*
*Context gathered: 2026-08-08*
*Interactive discuss: decisions from user selection across four gray areas*
