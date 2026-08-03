# Feature Research

**Domain:** Full dots-hyprland install / personal config migration  
**Researched:** 2026-08-03  
**Confidence:** HIGH  
**Milestone:** v0.3 Full ii install

## Feature Landscape

### Table Stakes (Operator Expects These)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **Impact inventory** | Goal is identify changes before acting | MEDIUM | Diff personal vs `dots/.config` for hypr + misc; document package/sysupdate effects |
| **Disposition plan** | “Then we decide” is explicit milestone intent | LOW | Per-path: keep / migrate-to-custom / accept-upstream / merge / defer |
| **Backup before files** | Full install overwrites more surfaces | LOW | Existing gate + `~/ii-original-dots-backup`; never bare skip |
| **Full-install opt-in** | SAFE_DEFAULTS still correct default | MEDIUM | Explicit flag/profile; safe remains default |
| **Personal must-keep migration** | Monitors, workspaces, binds, exec-once, env | HIGH | Map conf → `hypr/custom/{env,execs,general,rules,keybinds,variables}.lua` |
| **Session boots on Lua entry** | Definition of full hypr install success | HIGH | `hyprland.lua` loads; conf renamed `.old`; qs + personal apps still start as decided |
| **Protect packages after deps** | Full install still asdeps-demotes shared pkgs | LOW | Existing protect hook; re-verify after full path |
| **Playbook: full vs safe** | Operator must not guess flags | LOW | Extend `docs/dots-hyprland-workflow.md` |

### Differentiators (High value for this machine)

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Staged full profiles** | Hypr-first vs hypr+misc vs +sysupdate | MEDIUM | Reduces blast radius; matches inventory findings |
| **Pre-seed `hypr/custom` before install** | `ignore_existing` preserves overlays | MEDIUM | Must seed **before** first full hypr files step if custom empty |
| **Repo ↔ live hypr dual tracking** | `.dotfiles/.config/hypr` vs `~/.config/hypr` | MEDIUM | Full install mutates live XDG; repo tree needs explicit sync policy |
| **Disposition for hyprlock/hypridle** | Product choice “keep hyprlock” vs ii files | LOW | Install uses `install_file__auto_backup` for lock/idle |
| **hyprpaper / wallpaper policy** | Personal hyprpaper not always in ii hypr set | LOW | Inventory must list non-ii personal files left behind |

### Anti-Features (Seem useful, often harmful)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Blind full install day one | “Just run without skips” | Loses dual-monitor layout, workspace map, binds, dual-run chrome | Inventory → disposition → install |
| Drop all three skips in one shot without matrix | “Full means full” | Misc conf (fish/kitty/starship) + Syu + hypr compound failure | Staged profiles; independent decisions |
| Call upstream uninstall to “reset” | Clean slate | Cascade deletes personal stack | Wrapper uninstall/protect only |
| Port Waybar customs in same milestone | Parity anxiety | Scope explosion; dual-run still valid safety net | CUST-* later unless inventory blocks session |
| Replace hyprlock with QS lock | Upstream ships lock panel | Explicit out of scope / product choice | Keep hyprlock; disposition ii hyprlock.conf carefully |
| `--skip-backup` for speed | Faster iterate | No recovery of clashing trees | Keep gate |
| Auto-accept all upstream misc | Less decision work | Overwrites personal fish/kitty/starship | Per-surface disposition under `--core` decision |

## Feature Dependencies

```
Impact inventory
    └──requires──> Knowledge of SAFE_DEFAULTS + 3.files-legacy paths
    └──feeds──> Disposition plan
                    └──requires──> Personal must-keep extraction
                    └──feeds──> Pre-seed hypr/custom (if migrate)
                                    └──feeds──> Full-install opt-in path
                                                    └──feeds──> Live full adopt
                                                                    └──requires──> Backup gate + protect
                                                                    └──feeds──> Session verify + playbook
```

### Dependency Notes

- **Inventory before install:** User-stated process; non-negotiable for this milestone.
- **Custom seed before first full hypr files:** `install_dir__ignore_existing` means empty custom stays empty only if missing; if missing, upstream seeds stubs — personal migrations must land in live custom (and ideally fork) before or immediately after with care.
- **Sysupdate independent of hypr:** Can full-hypr while keeping `--skip-sysupdate`.
- **`--core` independent of hypr:** Can install hypr without touching fish/kitty/misc.

## Personal surfaces to inventory (machine-specific)

### Hypr (primary — blocked by `--skip-hyprland` today)

| Surface | Personal today | Full install behavior |
|---------|----------------|------------------------|
| `hyprland.conf` | 466-line SoT (monitors DP-1/HDMI-A-2, workspaces, binds, exec-once waybar/swaync/qs, env) | Renamed to `hyprland.conf.old` |
| `hypr/hyprland/` | Minimal (e.g. launch script) | **Synced** from ii Lua tree |
| `hyprland.lua` | Absent | Installed as entry |
| `hyprlock.conf` | Personal | auto_backup + replace |
| `hypridle.conf` | Personal | auto_backup + replace |
| `hyprpaper.conf` | Personal | Not in standard hypr install list above — may remain orphan unless misc/other |
| `hypr/custom/` | Likely absent live | ignore_existing seed from ii stubs |

### Misc (blocked by `--core` → SKIP_MISCCONF/FISH/FONTCONFIG)

| Surface | Personal in repo? | Risk if drop `--core` |
|---------|-------------------|------------------------|
| fish | Yes | sync_exclude conf.d |
| kitty | Yes | dir sync |
| starship.toml | Yes | file replace |
| fontconfig | Maybe live | dir sync |
| rofi / swaync / waybar | Yes personal | **Not** in ii dots list as those names — lower direct clash; session exec-once still relevant |
| fuzzel, matugen, foot, wlogout, kde* | ii ships | May create new trees or clash if present live |

### Packages / sysupdate

| Surface | Full behavior | Risk |
|---------|---------------|------|
| `pacman -Syu` | Without `--skip-sysupdate` | Unattended large upgrade mid-milestone |
| Meta pkgs / asdeps | install-deps | Dual-run stack demotion — protect list |

## Complexity Estimates

| Cluster | Complexity | Why |
|---------|------------|-----|
| Inventory + disposition docs | MEDIUM | Broad surface, mostly analysis |
| Wrapper full profile | MEDIUM | Policy + flags; must not break safe default |
| hypr → custom Lua migration | HIGH | Semantics differ; monitors/workspaces/binds/execs |
| Live full adopt + UAT | HIGH | Session can brick if migration wrong |
| Playbook | LOW | Docs only |
| Waybar bar cutover | OUT | Explicit later unless forced |

## Sources

- v0.2 REQUIREMENTS future CUT-02 / POLISH notes
- `3.files-legacy.sh` install behaviors
- Personal `.config/hypr/hyprland.conf`
- ii `hyprland.lua` custom require contract
- PROJECT.md v0.3 goal statement

---
*FEATURES research for v0.3 — 2026-08-03*
