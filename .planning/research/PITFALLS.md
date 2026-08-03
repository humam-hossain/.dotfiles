# Pitfalls Research

**Domain:** Full dots-hyprland install on existing dual-run system  
**Researched:** 2026-08-03  
**Confidence:** HIGH  
**Milestone:** v0.3 Full ii install

## Critical Pitfalls

### Pitfall 1: Blind full install without inventory

**What goes wrong:**  
Session loses dual-monitor layout (DP-1 / HDMI-A-2 transform), workspace map, special workspaces, personal binds, startup apps; operator cannot reconstruct quickly.

**Why it happens:**  
Milestone temptation is “drop the skips and run install.” SAFE_DEFAULTS existed exactly because first install is destructive (`hyprland.conf` → `.old`, hyprland dir sync).

**How to avoid:**  
Hard gate: no live full install plan until IMPACT + DISPOSITION artifacts exist and are approved.

**Warning signs:**  
Plans that start with `install` without a completed inventory checkbox.

**Phase to address:**  
First phase (inventory); enforce as dependency on adopt phase.

---

### Pitfall 2: Dropping all SAFE_DEFAULTS flags at once

**What goes wrong:**  
Hypr cutover **and** fish/kitty/starship overwrite **and** unattended `pacman -Syu` fail in one window — ambiguous root cause.

**Why it happens:**  
“Full install” colloquially means no skips; flags are actually independent (`--skip-hyprland`, `--core`, `--skip-sysupdate`).

**How to avoid:**  
Staged profiles: (A) hypr-only full, (B) optional drop `--core`, (C) optional allow sysupdate. Inventory marks each independently.

**Warning signs:**  
Single requirement “remove SAFE_DEFAULTS entirely” with no per-flag disposition.

**Phase to address:**  
Disposition + wrapper profile design.

---

### Pitfall 3: Seeding `hypr/custom` too late

**What goes wrong:**  
Full hypr files use `install_dir__ignore_existing` for custom. If custom already exists as empty stubs or wrong content, personal migrations fight the tree; if operator expected install to merge personal conf automatically — it will not.

**Why it happens:**  
Upstream only seeds custom when missing; never migrates `hyprland.conf` content into Lua custom.

**How to avoid:**  
Prepare custom overlays **before** or as an explicit step immediately around first full hypr files, with checklist from disposition.

**Warning signs:**  
“Install first, port binds later” with no offline custom draft.

**Phase to address:**  
Overlay preparation phase before/with adopt.

---

### Pitfall 4: Confusing repo `.config/hypr` with live `~/.config/hypr`

**What goes wrong:**  
Edits land in git tree; Hyprland still reads broken/incomplete live Lua session (or vice versa); dual sources of truth.

**Why it happens:**  
v0.2 live QS is real home tree; hypr was always personal and often repo-managed separately from install.

**How to avoid:**  
Disposition includes explicit SoT policy for hypr after cutover (live vs repo vs fork custom).

**Warning signs:**  
Commits to repo hypr without deploy/sync step defined.

**Phase to address:**  
Disposition + adopt verify.

---

### Pitfall 5: Losing dual-run safety net in the same change as hypr cutover

**What goes wrong:**  
`custom/execs.lua` drops waybar/swaync while Lua session still broken → no bar, no notifications, hard to debug.

**Why it happens:**  
CUT-01 mentality bleeds into full hypr milestone.

**How to avoid:**  
Default disposition: keep dual-run exec-once until separate cutover milestone unless inventory proves ii chrome alone is enough **and** session UAT passed.

**Warning signs:**  
Requirements that combine “full hypr” + “remove waybar” without separate acceptance.

**Phase to address:**  
Disposition defaults; adopt success criteria.

---

### Pitfall 6: Skipping backup / using bare `--skip-backup`

**What goes wrong:**  
No `~/ii-original-dots-backup` recovery for clashing configs.

**Why it happens:**  
Speed; repeated installs feel safe.

**How to avoid:**  
Keep wrapper refuse-bare-skip-backup policy on full profile too.

**Warning signs:**  
Flags include `--skip-backup` without `--allow-skip-backup` story.

**Phase to address:**  
Wrapper full profile + adopt.

---

### Pitfall 7: Unattended `pacman -Syu` mid-cutover

**What goes wrong:**  
Large system upgrade + session rewrite; kernel/graphics/hypr updates compound risk.

**Why it happens:**  
Full install without `--skip-sysupdate` runs Syu in dist-arch deps path.

**How to avoid:**  
Default full-**hypr** profile may still pass `--skip-sysupdate` unless operator explicitly wants Syu; run Syu in a separate maintenance window.

**Warning signs:**  
“Full means no skip-sysupdate” without scheduling.

**Phase to address:**  
Disposition for sysupdate flag; adopt runbook.

---

### Pitfall 8: asdeps demotion / orphan cleanup after fuller deps

**What goes wrong:**  
Shared packages marked asdeps; later `yay -Yc` removes hyprland/kitty/etc.

**Why it happens:**  
ii install implicitize behavior (known v0.2); full deps may pull more.

**How to avoid:**  
Always run protect post-install; document re-protect; never upstream uninstall.

**Warning signs:**  
Skipping protect hook or using upstream uninstall.

**Phase to address:**  
Adopt + playbook.

---

### Pitfall 9: hyprlock product regression

**What goes wrong:**  
ii `hyprlock.conf` replaces personal lock; lock UX breaks or conflicts with “keep hyprlock / no QS lock” decision.

**Why it happens:**  
Full hypr path auto_backup + installs upstream hyprlock.conf.

**How to avoid:**  
Disposition row for hyprlock/hypridle; restore personal from backup if needed; still no QS lock screen investment.

**Warning signs:**  
No lock/idle rows in inventory.

**Phase to address:**  
Inventory + disposition + adopt UAT (lock).

---

### Pitfall 10: Re-enabling ddcutil / brightness

**What goes wrong:**  
iGPU hang (historical post-mortem).

**Why it happens:**  
Upstream backlight tooling appears during fuller install exploration.

**How to avoid:**  
Keep out of scope; do not enable DDC/CI polling.

**Warning signs:**  
Plans mentioning ddcutil enablement.

**Phase to address:**  
All phases — standing ban.

---

### Pitfall 11: Using upstream `./setup uninstall` to roll back full install

**What goes wrong:**  
Cascade package removal; session worse than before.

**Why it happens:**  
Natural “undo” impulse.

**How to avoid:**  
Rollback = restore from `~/ii-original-dots-backup` + re-enable conf / wrapper uninstall safe path only.

**Warning signs:**  
Runbooks listing upstream uninstall.

**Phase to address:**  
Playbook + adopt.

---

### Pitfall 12: Assuming `--skip-hyprland-entry` is enough

**What goes wrong:**  
Operator uses entry-only skip thinking personal conf safe; full `--skip-hyprland` was the v0.2 protection for a reason (hyprland dir sync + conf rename are the bulk of damage).

**Why it happens:**  
Two similar flags in options.sh.

**How to avoid:**  
Inventory documents both; full adopt means accepting conf rename + dir sync; partial experiments must be explicit.

**Warning signs:**  
Plans that only mention hyprland-entry.

**Phase to address:**  
Inventory + wrapper docs.

## Pitfall → Phase Map (suggested)

| Pitfall | Phase theme |
|---------|-------------|
| 1 Blind install | Inventory (block adopt) |
| 2 All flags at once | Disposition / profiles |
| 3 Late custom | Overlay prep |
| 4 Repo vs live SoT | Disposition + verify |
| 5 Drop dual-run early | Disposition default + UAT |
| 6 Skip backup | Wrapper + adopt |
| 7 Syu mid-cutover | Disposition + runbook |
| 8 asdeps | Adopt + playbook |
| 9 hyprlock | Inventory + UAT |
| 10 ddcutil | Standing out of scope |
| 11 upstream uninstall | Playbook |
| 12 entry-only confusion | Inventory + docs |

## Sources

- `arch/dots-hyprland.sh` policy comments  
- `3.files-legacy.sh` destructive behaviors  
- v0.2 RETROSPECTIVE / PROJECT constraints  
- Personal hyprland.conf complexity  

---
*PITFALLS research for v0.3 — 2026-08-03*
