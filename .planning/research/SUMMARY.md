# Project Research Summary

**Project:** Quickshell Desktop Shell / `.dotfiles`  
**Domain:** Full dots-hyprland install (drop SAFE_DEFAULTS) with personal config inventory → disposition → adopt  
**Researched:** 2026-08-03  
**Confidence:** HIGH  
**Milestone:** v0.3 Full ii install

## Executive Summary

v0.3 is **not** a Waybar-customs or bar-cutover milestone. It is a **session-ownership** milestone: move from dual-run adopt (`--core --skip-hyprland --skip-sysupdate`) to a **full ii Hyprland install path**, but only after an explicit **impact inventory** and **per-surface dispositions**. The operator already stated the process: identify what full install would change (especially `.config/hypr` and other replaced configs), decide what to do, then install.

Experts treat rice full-cutover as: **diff personal vs upstream dots → migrate must-keeps into extension points (`hypr/custom/*.lua`) → explicit installer profile → backup → mutate live XDG → verify session**. The dominant risk is **compound failure**: dropping all three safe flags at once (hypr rewrite + misc conf sync + unattended `pacman -Syu`) while also removing dual-run chrome. Mitigation is architectural: inventory gate, staged flag profiles, pre-seed custom overlays, keep backup/protect policies, keep Waybar dual-run by default until a later milestone.

## Key Findings

### Recommended Stack

Keep managed-dependency stack from v0.2. Extend **wrapper policy** for an explicit full profile; do not reimplement `./setup`. Use **diff/inventory artifacts**, **`hypr/custom` Lua overlays**, upstream **backup dir**, and existing **protect** hooks.

**Core technologies:**
- **dots-hyprland submodule + `./setup`:** SoT for full file/package install  
- **`arch/dots-hyprland.sh`:** Safe default unchanged; full opt-in profile  
- **`hyprland.lua` + `hypr/custom/*`:** Personal must-keeps after conf → `.old`  
- **Impact/disposition docs:** Process SoT before mutation  
- **protect / backup gate:** Non-negotiable on full path  

### Expected Features

**Must have (table stakes):**
- Impact inventory (hypr + misc + packages/sysupdate)  
- Disposition plan per surface  
- Full-install opt-in (safe remains default)  
- Migrate personal must-keeps into `hypr/custom` (or accept loss deliberately)  
- Backup gate + protect after deps  
- Session boots on Lua entry; playbook full vs safe  

**Should have (competitive):**
- Staged profiles (hypr-only vs drop `--core` vs allow Syu)  
- Pre-seed custom before first full hypr files  
- Explicit repo vs live hypr SoT policy  
- hyprlock/hypridle disposition rows  

**Defer (later milestones):**
- Waybar customs ports (CUST-01..03)  
- Remove Waybar/rofi/swaync (CUT-01) unless disposition forces  
- Wrapper `verify` subcommand (POLISH-01) unless cheap add-on  
- QS lock screen / ddcutil brightness  

### Architecture Approach

Policy wrapper selects safe vs full argv → upstream setup mutates live XDG → personal overlays live in `hypr/custom` required by `hyprland.lua`. Inventory and disposition are first-class artifacts, not chat residue. Build order: inventory → dispositions/overlays → wrapper full profile → live adopt → playbook.

**Major components:**
1. Impact inventory artifact  
2. Disposition matrix  
3. Wrapper full profile  
4. `hypr/custom` overlay set  
5. Live full adopt + verify  
6. Playbook  

### Critical Pitfalls

1. **Blind full install** — gate adopt on inventory approval  
2. **All flags at once** — stage hypr / core / sysupdate independently  
3. **Late custom seed** — prepare overlays before destructive hypr files  
4. **Repo vs live SoT confusion** — decide tracking policy  
5. **Drop dual-run with hypr cutover** — default keep Waybar until later  
6. **Skip backup / upstream uninstall / Syu mid-cutover / asdeps** — keep v0.2 safety machinery  

## Implications for Roadmap

Phase numbering **continues at 10** (v0.2 ended at 9).

### Phase 10: Full-install impact inventory
**Rationale:** User process starts with identify changes; blocks all mutation.  
**Delivers:** Documented matrix of paths/flags/effects vs personal configs.  
**Addresses:** Inventory table stakes; pitfalls 1, 9, 12.  
**Avoids:** Blind install.

### Phase 11: Disposition decisions & overlay design
**Rationale:** “Then decide” before tooling or live install.  
**Delivers:** Approved dispositions; draft `hypr/custom` mapping for must-keeps; staged flag profile choices.  
**Addresses:** Disposition + migration design; pitfalls 2, 3, 4, 5.  

### Phase 12: Wrapper full-profile & safe defaults preserved
**Rationale:** Need a dry-runnable, documented opt-in before live adopt.  
**Delivers:** Full profile flag/path on `arch/dots-hyprland.sh`; safe still default; backup/protect unchanged.  
**Uses:** STACK wrapper extension.  
**Avoids:** Accidental full install via muscle memory.

### Phase 13: Prepare overlays & pre-full backup
**Rationale:** Custom must exist with content before/at hypr files; backup recovery path confirmed.  
**Delivers:** Live (and/or fork) custom lua; backup readiness checklist.  
**Implements:** Architecture overlay component.

### Phase 14: Live full adopt & session verify
**Rationale:** Only mutating cutover after 10–13.  
**Delivers:** Full install per dispositions; Lua session boots; protect; UAT monitors/binds/qs/lock policy.  
**Avoids:** Compound flag blast; early dual-run removal.

### Phase 15: Playbook & residual policy
**Rationale:** Encode full vs safe forever; rollback without upstream uninstall.  
**Delivers:** Updated `docs/dots-hyprland-workflow.md`; SoT policy; non-goals restated.

### Phase Ordering Rationale

- Inventory → decide → tool → prepare → mutate → document matches user intent and research dependencies.  
- Wrapper before live adopt enables dry-run proof.  
- Overlays before/with adopt respects `ignore_existing` custom semantics.  
- Playbook last (or parallel draft earlier, complete after real path exists) matches v0.2 DOC pattern.

### Research Flags

- **Phase 11:** Deep mapping of personal `hyprland.conf` → Lua custom APIs (hl.bind, execs, monitors) — needs discuss/plan research.  
- **Phase 14:** Live UAT on real multi-monitor machine — human_verify heavy.  
- **Phases 10, 12, 15:** Standard patterns; lighter research.

Phases with standard patterns (skip heavy research-phase): 10 (analysis), 12 (wrapper flags), 15 (docs).

## Watch Out For

- Treating “full install” as a single boolean instead of three flag axes  
- Porting CUST bar widgets mid-cutover  
- Calling vendor setup outside wrapper without documenting equivalent full profile  
- Assuming `hyprland.conf.old` remains a supported long-term config path  

## Sources

- `.planning/research/{STACK,FEATURES,ARCHITECTURE,PITFALLS}.md` (v0.3)  
- `arch/dots-hyprland.sh`, vendored install scripts, personal hypr, playbook  
- PROJECT.md v0.3 goals; v0.2 future CUT-02 context  

---
*Research summary for v0.3 — 2026-08-03 (inline after subagent rate-limit; content from repo SoT)*
