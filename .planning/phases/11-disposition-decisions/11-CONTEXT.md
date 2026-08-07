# Phase 11: Disposition decisions - Context

**Gathered:** 2026-08-07
**Status:** Ready for planning
**Mode:** `--auto` (yolo transition from Phase 10 UAT complete)

<domain>
## Phase Boundary

Produce a **committed disposition set** so every high-risk inventory row and flag axis has an explicit human-facing decision **before** wrapper full-profile work (Phase 12), overlay migration (Phase 13), or live full adopt (Phase 14).

**In scope (DISP-01..04):**
- Per high-risk `10-INVENTORY.md` row: disposition enum + short rationale
- Staged flag profile: which of `--skip-hyprland` / `--core` / `--skip-sysupdate` change for first full adopt (not assumed all three)
- Dual-run chrome (Waybar/rofi/swaync) disposition — default **keep** unless explicitly overridden
- hyprlock/hypridle disposition consistent with keeping hyprlock (no QS lock investment)

**Out of scope this phase:**
- Implementing wrapper full-profile opt-in — Phase 12
- Writing hypr/custom overlay files — Phase 13
- Live full install / session mutation — Phase 14
- Playbook safe-vs-full polish — Phase 15
- Re-running Phase 10 inventory (consume as SoT; refresh host presence only if a plan task needs it for a specific UNKNOWN)
- Waybar custom ports (CUST-*), CUT-01 bar cutover as a pure chrome removal project beyond DISP-03

**Requirements:** DISP-01, DISP-02, DISP-03, DISP-04

</domain>

<decisions>
## Implementation Decisions

### Disposition artifact shape
- **D-01:** Deliverable is a single committed file: `.planning/phases/11-disposition-decisions/11-DISPOSITIONS.md` (phase-dir SoT; not under `docs/`). — **Reversibility:** reversible
- **D-02:** One multi-section markdown document parallel to inventory axes: (1) staged flag profile, (2) Axis A hypr HIGH rows, (3) Axis B misc HIGH rows (only those relevant under chosen flag stage), (4) Axis C package/sysupdate rows under chosen stage, (5) dual-run chrome, (6) lock/idle, (7) residual / UNKNOWN handling. — **Reversibility:** reversible
- **D-03:** Uniform disposition row columns: **Path | Inventory risk | Disposition | Rationale | Flag stage | Inventory source**. Disposition enum exactly: `keep-personal` | `migrate-to-hypr-custom` | `accept-upstream` | `merge` | `defer`. — **Reversibility:** reversible
- **D-04:** Every disposition row must cite the inventory path/row (or UNKNOWN id). Do not invent surfaces absent from `10-INVENTORY.md` without adding an explicit "emerged surface" note + source. — **Reversibility:** reversible

### Staged flag profile (DISP-02)
- **D-05:** Flag axes remain **independent** (Phase 10 D-09). First full-adopt profile is **Stage 1 only** — not a silent drop of all three SAFE_DEFAULTS. — **Reversibility:** costly — later stages and Phase 12 profile encoding depend on this split
- **D-06 — Stage 1 (first full adopt target for Phases 12–14):**  
  - **Drop `--skip-hyprland`:** YES (required for ii hypr tree + conf→`.old` + lua entry)  
  - **Keep `--core`:** YES (do **not** drop `--core` in Stage 1 — avoids HIGH fish/kitty/starship/fontconfig/mpv dir-sync collisions)  
  - **Keep `--skip-sysupdate`:** YES (do **not** allow `pacman -Syu` in Stage 1)  
  Effective Stage 1 argv intent vs residual: drop only skip-hyprland; still inject/use `--core` and `--skip-sysupdate`. — **Reversibility:** costly — Phase 12 FULL-* and Phase 14 gates consume this
- **D-07 — Stage 2 (later, explicit re-disposition):** Drop `--core` only after each HIGH misc PRESENT row has a non-`defer` disposition. Not required for Phase 11 success if Stage 1 rows are complete; document Stage 2 as **deferred follow-up** section in `11-DISPOSITIONS.md`. — **Reversibility:** reversible
- **D-08 — Stage 3 (later, explicit re-disposition):** Allow sysupdate only with separate operator acceptance of Syu + asdeps demotion risk; default remains skip. Document as deferred. — **Reversibility:** reversible
- **D-09:** SAFE_DEFAULTS on default `install` / `install-files` **unchanged** this phase (Phase 12 implements opt-in). Dispositions describe the **intended full profile**, not live wrapper edits. — **Reversibility:** one-way if violated — accidental default full install is milestone anti-goal

### Dual-run chrome (DISP-03)
- **D-10:** Waybar / rofi / swaync session chrome disposition = **`keep`** (continue dual-run). Do **not** remove from personal hypr `exec-once` in Stage 1. — **Reversibility:** costly — CUT-01 and ADOPT-03 depend on this
- **D-11:** Phase 10 D-15 (chrome omitted from inventory; operator once said chrome *can* be removed) does **not** override DISP-03 default. Explicit accept-remove would require a future disposition revision; not auto-selected now. — **Reversibility:** reversible

### hyprlock / hypridle (DISP-04)
- **D-12:** **Keep hyprlock** as screen lock — no Quickshell lock screen investment. Live `hyprlock.conf` disposition = **`keep-personal`**. — **Reversibility:** costly — product constraint from PROJECT.md
- **D-13:** This host is **not firstrun** → legacy auto_backup writes `*.new` sidecars and leaves live conf. Disposition: live conf **`keep-personal`**; `*.new` sidecars **`defer`** (review/diff later; do not auto-promote to live). Same for `hypridle.conf`. — **Reversibility:** reversible
- **D-14:** `hyprlock/` dir gap (UNKNOWN) → **`defer`** with note to recheck before any lock conf that `source`s missing helpers; not a blocker for Stage 1 if live conf stays personal. — **Reversibility:** reversible

### High-risk hypr surface policy (DISP-01 / Axis A under Stage 1)
- **D-15:** `hyprland.conf` → will `mv` to `.old` under Stage 1. Disposition strategy: **`migrate-to-hypr-custom`** for machine-specific must-keeps (monitors, workspaces, personal env, personal exec-once beyond ii hooks, personal binds/rules the operator still needs); remainder of conf behavior **`accept-upstream`** via ii `hyprland/` + `hyprland.lua` entry. Do not `keep-personal` the conf as primary session entry (that blocks ADOPT-02). — **Reversibility:** costly — Phase 13 overlays and Phase 14 session model depend on this
- **D-16:** Must-keep migrate set (minimum from inventory category tags + PROJECT constraints): **monitors** (DP-1 / HDMI-A-2 dual setup), **workspaces** layout pins, **env** machine paths, **exec-once** personal services still required under dual-run (waybar/swaync/rofi/hyprpaper/polkit/cliphist as applicable under D-10), **binds** operator still needs that ii does not replace. Exact line extraction is Phase 13 execution; Phase 11 records the category-level migrate list + rationale. — **Reversibility:** costly
- **D-17:** `hyprland/` dir sync (`rsync --delete`) → **`accept-upstream`**. Any personal content under `hyprland/scripts/` must be migrated out **before** first Stage 1 files install or marked **`defer`** with explicit "will lose on sync" risk if left. — **Reversibility:** one-way on live sync without backup
- **D-18:** `hyprland.lua` → **`accept-upstream`** (install entry required for ii session model). — **Reversibility:** costly
- **D-19:** `hypr/custom/` currently ABSENT → **`migrate-to-hypr-custom`** strategy: allow ii seed on first install (`ignore_existing`), then Phase 13 populates must-keeps. Phase 11 disposition row documents "seed OK + own overlays after". — **Reversibility:** costly
- **D-20:** `hyprpaper.conf` (not touched by legacy hypr install) → **`keep-personal`**. — **Reversibility:** reversible
- **D-21:** Extra live surfaces (`.bak`, `hyprland-gui.conf`) → **`defer`** or **`keep-personal`** as non-install targets; do not block Stage 1. Prefer **`keep-personal`** for operator backups; **`defer`** for unused gui conf if unclear. Recommended: `.bak` **`keep-personal`**, `hyprland-gui.conf` **`defer`**. — **Reversibility:** reversible

### Misc / packages under Stage 1 (Axes B–C)
- **D-22:** Because Stage 1 **keeps `--core`**, HIGH misc PRESENT collisions (fish, kitty, starship, fontconfig, mpv, dolphinrc, kdeglobals, …) are **not mutated by Stage 1 files path**. Record each HIGH PRESENT row as **`defer`** (Stage 2) with rationale "protected by retained `--core`" — still satisfies DISP-01 visibility without forcing keep/accept now. — **Reversibility:** reversible
- **D-23:** ABSENT greenfield misc rows under retained `--core` → no Stage 1 effect; optional bulk note **`defer` (N/A Stage 1)** rather than per-row noise. Planner may collapse ABSENT+core-retained into one summary table. — **Reversibility:** reversible
- **D-24:** `pacman -Syu` / full deps HIGH effects → **`defer`** under Stage 1 (skip-sysupdate retained). Document asdeps demotion risk as **accepted residual of deps path even with skip-sysupdate** where inventory says always-on; disposition = **`defer`** mitigation detail to Phase 12 protect/re-mark (already in wrapper) — do not invent new protect lists here. — **Reversibility:** reversible
- **D-25:** Coarse `illogical-impulse-*` metas already installed → **`accept-upstream`** (remain managed); no uninstall. plasma-browser-integration ABSENT → **`defer`** / leave skipped under `--core` Stage 1. — **Reversibility:** reversible

### North Star vs staging
- **D-26:** Phase 10 D-17 North Star (greenfield full ii default) remains the **long-term** vision. Stage 1 is the **first safe step** toward that vision (hypr adopt only). Stage 2/3 move closer to greenfield; they are not rejected — only sequenced. — **Reversibility:** reversible

### Claude's Discretion
- Exact markdown heading names and table grouping inside `11-DISPOSITIONS.md` as long as D-01–D-04 hold
- Whether LOW residual rows get individual lines or a single "no change under Stage 1" blurb
- Rationale wording length (one short sentence preferred)
- Optional assert/lint script for disposition enum + required columns (nice-to-have; not required unless research shows cheap reuse of Phase 10 assert patterns)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Planning / requirements
- `.planning/PROJECT.md` — v0.3 full ii install; inventory→disposition→adopt; keep hyprlock; dual-run until cutover
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
- `docs/dots-hyprland-workflow.md` — current safe dual-run operator path

### Install / evidence SoT
- `arch/dots-hyprland.sh` — SAFE_DEFAULTS injection, backup gate, protect re-mark
- `vendor/dots-hyprland/sdata/subcmd-install/options.sh` — `--core`, `--skip-hyprland`, `--skip-sysupdate`
- `vendor/dots-hyprland/sdata/subcmd-install/3.files-legacy.sh` — hypr/misc effects cited in inventory
- `vendor/dots-hyprland/sdata/dist-arch/install-deps.sh` — Syu / asdeps / metas

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
- `arch/dots-hyprland.sh` — documents residual flags; Phase 12 will encode Stage 1 profile from DISP-02
- Live `~/.config/hypr/hyprland.conf` — source for Phase 13 must-keep extraction (not edited this phase)

### Established Patterns
- Phase-dir SoT markdown artifacts (inventory → dispositions)
- Independent flag axes (not cross-product primary structure)
- Neutral inventory → explicit dispositions (no dispositions in inventory)
- Thin wrapper; no reimplementation of upstream package lists in `arch/`

### Integration Points
- Phase 12 consumes D-06 Stage 1 flag profile → FULL-01 opt-in path
- Phase 13 consumes D-15/D-16 migrate categories → hypr/custom overlays
- Phase 14 consumes full DISP-* satisfaction + dual-run policy D-10
- Phase 15 documents safe vs full using Stage 1 + deferred Stage 2/3

</code_context>

<specifics>
## Specific Ideas

- Greenfield full ii remains North Star (Phase 10 D-17) but **sequenced**: Stage 1 = hypr full adopt only.
- Host not-firstrun → lock/idle stay live personal with `.new` sidecars (inventory fact).
- Dual-run chrome **keep** for Stage 1 despite earlier "can remove" signal — DISP-03 + ROADMAP success criteria win.
- Machine-specific monitors (DP-1, HDMI-A-2) are must-migrate categories, not accept-blind.

</specifics>

<deferred>
## Deferred Ideas

- Stage 2: drop `--core` + per-row keep/accept for fish/kitty/starship/fontconfig/mpv/… (after Stage 1 session stable)
- Stage 3: allow sysupdate + asdeps demotion acceptance
- Explicit accept-remove for Waybar/rofi/swaync (CUT-01) — only if operator revises D-10
- CUST-01..04 Waybar custom ports — backlog, not Phase 11
- Optional disposition assert harness (Claude discretion)
- Live host re-scan if inventory host snapshot drifts materially before Stage 1 adopt

None of the above expand Phase 11 scope beyond recording defer rows / follow-up sections.

</deferred>

---

*Phase: 11-Disposition decisions*
*Context gathered: 2026-08-07*
*Auto mode: decisions selected as recommended defaults from REQUIREMENTS + Phase 10 context + ROADMAP success criteria*
