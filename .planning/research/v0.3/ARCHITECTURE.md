# Architecture Research

**Domain:** Full dots-hyprland install on dual-run `.dotfiles`  
**Researched:** 2026-08-03  
**Confidence:** HIGH  
**Milestone:** v0.3 Full ii install

## Standard Architecture (post-v0.3 target)

### System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     Operator / Playbook                          │
│   safe profile (default)  |  full profile (explicit opt-in)     │
├─────────────────────────────────────────────────────────────────┤
│                  arch/dots-hyprland.sh (policy)                  │
│  SAFE_DEFAULTS | FULL_PROFILE | backup gate | protect | dry-run │
├───────────────────────────────┬─────────────────────────────────┤
│     vendor/dots-hyprland      │     Personal / overlays          │
│     ./setup (SoT install)     │     hypr/custom/*.lua            │
│     dots/.config/*            │     disposition matrix           │
├───────────────────────────────┴─────────────────────────────────┤
│                     Live XDG ($HOME)                             │
│  ~/.config/hypr/{hyprland.lua, hyprland/, custom/, lock, idle}   │
│  ~/.config/quickshell (ii)   │  optional misc if not --core      │
│  dual-run Waybar until later cutover (still valid)               │
└─────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| Impact inventory | Enumerate every path/flag effect of full install | Doc + optional script vs `dots/.config` and personal trees |
| Disposition matrix | Human decisions per surface | Markdown table committed under `.planning/` or `docs/` |
| Wrapper profiles | Safe default vs full opt-in argv | Extend `arch/dots-hyprland.sh` |
| Upstream `./setup` | Actual file/package mutation | Unchanged SoT |
| `hypr/custom` overlays | Personal must-keeps after Lua entry | Lua modules required by `hyprland.lua` |
| Fork pin | Durable custom + upstream tracking | Commits on fork; parent submodule bump |
| Protect list | Prevent asdeps orphan death | Existing wrapper post-hook |
| Playbook | Operator procedure | `docs/dots-hyprland-workflow.md` |

## Recommended Project Structure (changes)

```
.dotfiles/
├── arch/dots-hyprland.sh          # MODIFY: full profile / no-SAFE opt-in
├── docs/dots-hyprland-workflow.md # MODIFY: full vs safe; inventory procedure
├── docs/ii-full-install-impact.md # NEW (or .planning/): inventory + dispositions
├── .config/hypr/                  # POLICY: how repo tracks live after Lua cutover
│   └── (may gain custom/ mirrors or document live-only custom)
├── vendor/dots-hyprland/          # PIN: custom lua may live on fork checkout
│   └── dots/.config/hypr/custom/  # optional: ship personal overlays via fork
└── .planning/
    ├── REQUIREMENTS.md
    └── research/                  # this milestone research
```

## Integration Points

### 1. Wrapper ↔ setup flags

| Today | v0.3 need |
|-------|-----------|
| Always inject SAFE_DEFAULTS on install/install-files | Opt-in path that omits some/all of `--core --skip-hyprland --skip-sysupdate` |
| No upstream undo for skip-hyprland once injected | Full profile must build argv without those flags |
| Backup gate + refuse bare `--skip-backup` | Keep for full profile |
| protect after install/deps | Keep |

### 2. Personal conf ↔ ii Lua

```
Personal hyprland.conf (monitors, workspaces, exec-once, binds, env)
        │
        ▼ extract
hypr/custom/{env,execs,general,rules,keybinds,variables}.lua
        │
        ▼ required by
hyprland.lua → hyprland/* defaults + custom/*
```

** renames:** live `hyprland.conf` → `hyprland.conf.old` (recovery reference, not active).

### 3. Repo `.config/hypr` ↔ live `~/.config/hypr`

Full install mutates **live** XDG. Repo tree is separate unless operator rsyncs/stows.

Architecture decision needed in disposition phase:
- A) Live is SoT for hypr after cutover; repo stores only custom overlays + docs
- B) Repo mirrors custom/ and critical files via existing dotfiles deploy path
- C) Fork carries custom; parent only documents

### 4. Dual-run chrome

Full hypr install does **not** require removing Waybar/rofi/swaync. exec-once migration into `custom/execs.lua` decides whether dual-run continues.

## Data Flow — Full adopt sequence

```
1. Inventory (read-only)
   personal trees + ii dots + flag matrix → IMPACT.md
2. Disposition (human)
   IMPACT.md → DISPOSITIONS (keep/migrate/accept/defer)
3. Prepare overlays
   Write hypr/custom on live (and/or fork) per dispositions
   Snapshot/backup confirmation
4. Full install (mutating)
   wrapper full profile → ./setup install[-files]
   backup gate → files (hypr rename/sync, optional misc)
5. Heal
   protect explicit; fix any broken exec-once
6. Verify
   hypr loads lua; monitors; qs -c ii; dual-run policy as decided
7. Document
   playbook + pin any fork custom commits
```

## Build Order (phase-oriented, continues at 10)

1. **Inventory tooling/docs** — no session mutation  
2. **Disposition + custom migration design** — still reversible  
3. **Wrapper full-profile** — dry-run provable; safe default unchanged  
4. **Prepare overlays + backup** — seed custom before destructive hypr files  
5. **Live full adopt + verify** — single careful cutover window  
6. **Playbook + residual policy** — full vs safe forever documented  

Optional split: hypr-only full first; drop `--core` later as sub-phase if inventory warrants.

## New vs Modified

| Item | Kind |
|------|------|
| Impact inventory artifact | NEW |
| Disposition artifact | NEW |
| `hypr/custom` personal content | NEW (live ± fork) |
| Wrapper full profile flag/path | MODIFY |
| Playbook full section | MODIFY |
| SAFE default path | UNCHANGED (must remain default) |
| Upstream setup | UNCHANGED |
| Waybar customs ports | OUT of architecture this milestone |
| Product retirement | DONE (v0.2) |

## Anti-Patterns

| Pattern | Why bad |
|---------|---------|
| Full install then “fix” missing binds from memory | No inventory; high thrash |
| Editing only repo `.config/hypr` expecting live Lua to pick it up | Live XDG is what Hyprland reads |
| Putting must-keeps in `hyprland/` upstream tree on fork without custom | Pin-bumps fight personal edits; custom is the extension point |
| Mixing CUST bar ports into full hypr phase | Different risk domain |

## Sources

- `arch/dots-hyprland.sh`
- `3.files-legacy.sh`, `3.files.sh`, `options.sh`
- `dots/.config/hypr/hyprland.lua`
- v0.2 architecture (managed dependency) — still base layer

---
*ARCHITECTURE research for v0.3 — 2026-08-03*
