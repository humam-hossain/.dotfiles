# Stack Research

**Domain:** Full dots-hyprland install / Hyprland Lua session cutover on existing dual-run `.dotfiles`  
**Researched:** 2026-08-03  
**Confidence:** HIGH  
**Milestone:** v0.3 Full ii install

## Recommended Stack

### Core Technologies

| Technology | Version / pin | Purpose | Why Recommended |
|------------|---------------|---------|-----------------|
| end-4/dots-hyprland (personal fork) | submodule `vendor/dots-hyprland` @ current pin | Product + installer SoT | Already adopted in v0.2; full install uses same SoT without reimplementation |
| Upstream `./setup` | vendored | deps / setups / files | Package lists and file install live here; wrapper must not reimplement |
| `arch/dots-hyprland.sh` | repo-owned | Host entry + policy | Existing SAFE_DEFAULTS, backup gate, protect/uninstall; extend for full profile |
| Hyprland + hyprland.lua | system + ii dots | Session entry after full install | Full install renames `hyprland.conf` → `.old` and loads Lua entry |
| `~/.config/hypr/custom/*.lua` | ii overlay contract | Personal must-keeps after cutover | `install_dir__ignore_existing`; entry `hyprland.lua` requires custom modules if present |
| Upstream backup dir | `~/ii-original-dots-backup` | Clash backup before files | `auto_backup_configs` in `3.files.sh`; keep gate, never bare `--skip-backup` |
| pacman / yay | Arch | deps + optional `-Syu` | Full install without `--skip-sysupdate` runs `sudo pacman -Syu` |

### Supporting Libraries / Tools

| Tool | Purpose | When to Use |
|------|---------|-------------|
| `diff` / `diff -ruN` / `git diff --no-index` | Inventory personal vs ii dots | Impact inventory phase before live full install |
| Wrapper `--dry-run` | Print argv with/without SAFE_DEFAULTS | Prove full-profile flag wiring without mutating machine |
| `arch/dots-hyprland.sh protect` | Re-mark PROTECT_EXPLICIT as `--asexplicit` | After every install/deps path (already post-hook); re-run if orphan cleanup risk |
| `hyprctl` / session restart | Verify Lua session boots | Post-adopt UAT |
| `qs -c ii` + `ILLOGICAL_IMPULSE_VIRTUAL_ENV` | Shell chrome | Already live; full hypr may also set env via ii `hyprland/env` + custom |

### Development / Operator Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| Impact inventory doc/script | Map every path full install touches | Prefer repo-documented matrix over ad-hoc notes |
| Disposition table | keep / migrate-to-custom / accept-upstream / defer | One row per clashing surface |
| Playbook section | Full vs safe profiles | Extend `docs/dots-hyprland-workflow.md` |

## Installation (conceptual)

```bash
# Safe (v0.2 default — keep available)
./arch/dots-hyprland.sh install
# → injects --core --skip-hyprland --skip-sysupdate

# Full profile (v0.3 target — explicit opt-in; design TBD)
# Must NOT silently drop SAFE_DEFAULTS without operator intent
./arch/dots-hyprland.sh install --full   # or documented vendor path
# → no --skip-hyprland; decide --core / --skip-sysupdate per disposition
# → backup gate still required
# → protect explicit packages after deps
```

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| Wrapper full-profile flag | Call `vendor/dots-hyprland/./setup` directly | Temporary only; playbook already warns this is the only path today — formalize in wrapper this milestone |
| Migrate must-keeps into `hypr/custom/*.lua` | Keep personal `hyprland.conf` forever | Rejects milestone goal (full install without skip-hyprland) |
| Staged flags (hypr first, then drop `--core`) | Big-bang full flags day one | Prefer if inventory shows high misc-config risk (fish/kitty/starship) |
| Inventory as markdown + manual diff | Automated rsync dry-run only | Automation helps but dispositions need human judgment |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Reimplement package install in `arch/` | Bitrots vs upstream meta pkgs | `./setup` + thin wrapper |
| Revive local `.config/quickshell` product | Retired v0.2 | Live installed ii tree |
| Bare `--skip-backup` | Destroys recovery path | Backup gate + `~/ii-original-dots-backup` |
| Upstream `./setup uninstall` | Cascades asdeps / can remove hyprland stack | Wrapper `uninstall` / `protect` |
| DDC/CI / ddcutil brightness | iGPU hang post-mortem | Leave backlight disabled |
| Auto-bump submodule on every pull | Breaks pin reproducibility | Explicit pin-bump |
| Blind full install without inventory | Loses monitors, workspaces, binds, exec-once | Inventory → disposition → install |

## Stack Patterns by Variant

**If only hypr session cutover is required first:**
- Drop `--skip-hyprland` (and optionally keep `--core` + `--skip-sysupdate`)
- Because misc fish/kitty/starship collisions are separable from session ownership

**If true “full rice” install is required:**
- Drop `--core` and `--skip-hyprland`; decide sysupdate deliberately
- Because `--core` is what skips fish, fontconfig, misc conf, plasma integration

**If operator wants zero unattended `-Syu`:**
- Keep `--skip-sysupdate` even on “full hypr” profile
- Because sysupdate is orthogonal to config takeover

## Version Compatibility

| Component | Compatible with | Notes |
|-----------|-----------------|-------|
| Wrapper SAFE_DEFAULTS | install + install-files only | install-deps / install-setups get no injection today |
| `install_dir__ignore_existing` on `hypr/custom` | Pre-seeded custom tree | Existing custom is **not** overwritten — seed before full install |
| `hyprland.conf` → `.old` | Presence of conf file | Live home path; repo `.config/hypr` may still need separate sync story |
| PROTECT_EXPLICIT post-hook | After install/deps | Full install still demotes shared deps to asdeps |

## Sources

- `arch/dots-hyprland.sh` (SAFE_DEFAULTS, protect, backup policy)
- `vendor/dots-hyprland/sdata/subcmd-install/{options,3.files,3.files-legacy}.sh`
- `vendor/dots-hyprland/dots/.config/hypr/hyprland.lua` + `custom/`
- `docs/dots-hyprland-workflow.md`
- `.config/hypr/hyprland.conf` (personal surface)
- `.planning/PROJECT.md` v0.3 goals

---
*STACK research for v0.3 — 2026-08-03*
