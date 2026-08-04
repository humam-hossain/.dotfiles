# Phase 10 — Full-install impact inventory

**Created:** 2026-08-04  
**Host scan refreshed:** 2026-08-04 (read-only `test -e` under live `~/.config`)  
**Status:** INV-04 residual complete; Axis A (hypr) complete (10-02); Axes B/C stubs pending 10-03/10-04; host finalize 10-05

## Scope

Neutral impact inventory of what a **default full dots-hyprland install** would change on this machine.

- **No dispositions** — effects only (Phase 11 owns keep / migrate / accept choices).
- **No live full install** this phase — evidence is static setup/wrapper source + read-only host scan (D-05).
- **Legacy files path** is the default SoT (`3.files-legacy.sh`), not `--exp-files`.
- Dual-run chrome clash rows are **omitted entirely** (D-15).
- Artifact SoT path: this file under the phase dir (D-01), not under `docs/`.

---

## SAFE_DEFAULTS residual (INV-04)

Phase 10 does **not** change the thin wrapper. The safe dual-run install path **remains** the default and **still** available after this milestone.

### Current wrapper defaults

From `arch/dots-hyprland.sh:12`:

```bash
SAFE_DEFAULTS=(--core --skip-hyprland --skip-sysupdate)
```

| Fact | Detail | Source |
|------|--------|--------|
| Triple flags | `--core`, `--skip-hyprland`, `--skip-sysupdate` | `arch/dots-hyprland.sh:12` |
| Injection scope | Applied only to `install` and `install-files` | `needs_safe_defaults` at `arch/dots-hyprland.sh:127-131` |
| Not injected for | `install-deps`, `install-setups` | same |
| Argv build | Prepended before user flags: `./setup <sub> [SAFE_DEFAULTS…] [user flags…]` | `arch/dots-hyprland.sh:1399-1407` |
| Backup gate | Still runs for install / install-files (interactive `yes`) | `arch/dots-hyprland.sh:149-160`, `1395-1397` |

### Residual claims (locked)

1. **Default install stays dual-run-safe:** `./arch/dots-hyprland.sh install` continues to inject SAFE_DEFAULTS; personal hypr is not renamed under the default path.
2. **Phase 10 is inventory-only:** no wrapper edits, no flag removal, no live mutation of `~/.config`.
3. **Full-profile opt-in is future work:** explicit opt-in to drop the triple (or subsets) is Phase 12; residual **remains** after this milestone until that opt-in exists.
4. **Optional dry-run proof (D-08, not required):** `printf 'yes\n' | ./arch/dots-hyprland.sh install --dry-run` would show SAFE_DEFAULTS in argv without calling setup — deferred; static source cites above are sufficient.

### Residual effect table

| Path | Effect | Risk | Source | Host present? |
|------|--------|------|--------|---------------|
| Wrapper default install path (`./arch/dots-hyprland.sh install`) | Injects `--core --skip-hyprland --skip-sysupdate` before user flags; dual-run-safe path remains default | LOW (protective) | `arch/dots-hyprland.sh:12`, `127-131`, `1399-1407` | N/A (wrapper) |
| `~/.config/hypr/hyprland.conf` under **default** install | **Not** renamed — protected by injected `--skip-hyprland` | LOW under residual | options.sh `SKIP_HYPRLAND`; wrapper injection | yes (465 lines) |
| `~/.config/quickshell/` under default install | Still subject to files install (not skipped by SAFE_DEFAULTS) | MED | `3.files-legacy.sh` quickshell branch; backup_gate notes | yes (dual-run) |

---

## Axis: drop --skip-hyprland (hypr files)

**When:** Operator runs install/files **without** `--skip-hyprland` (legacy files path = `3.files-legacy.sh`).  
**Independence (D-09):** This axis alone — does not imply dropping `--core` or allowing sysupdate.  
**Host firstrun state:** `~/.config/illogical-impulse/installed_true` is **PRESENT** → not firstrun → `install_file__auto_backup` writes `*.new` sidecars (does not replace live conf).

### INV-02 / D-14 effect table

| Path | Effect | Risk | Source | Host present? |
|------|--------|------|--------|---------------|
| `~/.config/hypr/hyprland/` | `install_dir__sync` → `rsync_dir__sync` with `--delete` from `dots/.config/hypr/hyprland` | HIGH | `3.files-legacy.sh:50`; `3.files.sh:130-137` (`install_dir__sync`), `67+` (`rsync_dir__sync`) | yes (minimal tree + scripts/) |
| `~/.config/hypr/hyprland.conf` | If file exists: `mv` → `hyprland.conf.old` (disable personal conf so lua entry can load) | HIGH | `3.files-legacy.sh:51-53` | yes (465 lines, personal SoT) |
| `~/.config/hypr/hyprland.lua` | `install_file` (cp -f) unless `--skip-hyprland-entry` / `SKIP_HYPRLAND_ENTRY` | HIGH | `3.files-legacy.sh:58-62` | ABSENT → would be created |
| `~/.config/hypr/hyprlock.conf` | `install_file__auto_backup`: firstrun → replace with `.old` backup; **this host not firstrun** → write `hyprlock.conf.new` sidecar, live conf stays | HIGH (session lock) | `3.files-legacy.sh:55-57`; `3.files.sh:102-119` | yes |
| `~/.config/hypr/hypridle.conf` | same `auto_backup` branches; this host → expect `hypridle.conf.new` | MED–HIGH | `3.files-legacy.sh:64-69` (via-nix branch vs dots); `3.files.sh:102-119` | yes |
| `~/.config/hypr/custom/` | `install_dir__ignore_existing`: seed from `dots/.config/hypr/custom` **only if absent**; no-op if dir exists | HIGH (overlay strategy) | `3.files-legacy.sh:75`; `3.files.sh:150-159` | ABSENT → would seed ii stubs |
| `~/.config/hypr/hyprpaper.conf` | **Not touched** by legacy hypr install list (no install_file/sync for hyprpaper) | MED (personal orphan / policy surface) | absence from `3.files-legacy.sh:47-76` hypr case | yes |
| `~/.config/hypr/hyprlock/` (dir) | **Not installed** by legacy — only `hyprlock.conf` is auto_backup'd; upstream conf may `source` dir helpers | MED (gap) | legacy hypr case has no dir install; RESEARCH Pitfall 4 | ABSENT |
| `~/.config/illogical-impulse/installed_true` | FIRSTRUN_FILE marker controlling auto_backup branch | MED | `3.files.sh:201-209` firstrun detect; env FIRSTRUN_FILE | yes (not firstrun) |
| Fedora polkit append (conditional) | May append polkit exec-once line into `hyprland/execs.conf` on Fedora | LOW | `3.files-legacy.sh:72` | N/A (host not Fedora path assumed) |
| `~/.local/share/icons/illogical-impulse.svg` | `install_file` icon (runs outside SKIP_HYPRLAND case — always when files step reaches it) | LOW | `3.files-legacy.sh:79` | re-check in 10-05 |

### Extra live hypr surfaces (not in legacy install list)

Read-only `find` under `~/.config/hypr` (2026-08-04). Effect = not modified by legacy hypr block unless proven otherwise.

| Path | Effect | Risk | Source | Host present? |
|------|--------|------|--------|---------------|
| `~/.config/hypr/hyprland.conf.bak` | Not in install list — personal backup file left alone | LOW | host observation; not referenced in legacy hypr case | yes |
| `~/.config/hypr/hyprland-gui.conf` | Not in install list — personal/gui conf left alone | LOW | host observation | yes |
| `~/.config/hypr/hyprland/scripts/` | Nested under `hyprland/` dir sync target — **would be subject to rsync --delete** if dir sync runs | HIGH (subset of hyprland/ row) | same as `hyprland/` sync | yes |

### Personal `hyprland.conf` category annotations (D-13 — tags/counts only, no dispositions)

Live file: 465 lines. Category hit counts from read-only line-prefix scan (not a full conf dump):

| Category tag | Approx count | Notes |
|--------------|--------------|-------|
| monitors | 2 | `monitor` lines |
| workspaces | 11 | `workspace` lines |
| binds | 100 | `bind` lines |
| exec-once | 12 | startup hooks |
| env | 4 | environment |
| windowrule / layerrule | 2 / 4 | rules |
| animation | 17 | |
| general / decoration / input / misc | 1 each | section openers |
| source | 1 | include |

These tags describe **what personal surface exists** before a conf→`.old` rename. No keep/migrate/accept language.

### auto_backup branch detail (lock/idle)

From `3.files.sh:102-119` `install_file__auto_backup`:

1. Target missing → `cp_file` install fresh.
2. Target exists + **firstrun** (`INSTALL_FIRSTRUN=true`) → `mv` target to `*.old`, then install.
3. Target exists + **not firstrun** → `cp_file` source to `*.new` only; live target unchanged.

This host: marker present → branch 3 for hyprlock/hypridle.

---

## Axis: drop --core (misc / fish / fontconfig)

**When:** Operator runs install/files **without** `--core` (re-enables plasmaintg, fish, miscconf, fontconfig).  
**Stub note:** Minimum INV-03 keyword set + sample catalog; plan **10-03** fills full ii misc catalog.

| Path | Effect | Risk | Source | Host present? |
|------|--------|------|--------|---------------|
| `~/.config/fish/` | `install_dir__sync_exclude` (sync+delete except `conf.d`) | HIGH | `3.files-legacy.sh:33` | yes |
| `~/.config/kitty/` | dir `install_dir__sync` (`--delete`) | HIGH | misc find loop `3.files-legacy.sh:11-16` | yes |
| `~/.config/starship.toml` | file `install_file` (cp -f) | HIGH | misc find loop | yes |
| `~/.config/fontconfig/` | dir `install_dir__sync` (or fontset) | HIGH | `3.files-legacy.sh:41-42` | yes |
| `~/.config/fuzzel/` | dir sync | MED (greenfield if absent) | misc find loop | ABSENT |
| `~/.config/matugen/` | dir sync | MED | misc find loop | ABSENT |
| `~/.config/wlogout/` | dir sync | MED | misc find loop | ABSENT |
| `~/.config/mpv/` | dir sync | MED–HIGH | misc find loop | yes |
| `~/.config/dolphinrc` | file install | MED | misc find loop | yes |
| `~/.config/kdeglobals` | file install | MED | misc find loop | yes (research) |

*Full catalog (chrome-flags, foot, Kvantum, konsole share, …) deferred to plan 10-03.*

---

## Axis: allow sysupdate / package effects

**When:** Operator runs deps path **without** `--skip-sysupdate` (and related deps always-on behaviors).  
**Stub note:** Coarse INV-01 rows; plan **10-04** expands meta list and asdeps name set.

| Path | Effect | Risk | Source | Host present? |
|------|--------|------|--------|---------------|
| System packages via `pacman -Syu` | Full system upgrade when `SKIP_SYSUPDATE` unset | HIGH | `sdata/dist-arch/install-deps.sh:56-58` | N/A (system) |
| `illogical-impulse-*` meta PKGBUILDs | Build/install via `makepkg` + `yay -S --asdeps` depends | MED | `install-deps.sh:74-103` | yes (dual-run metas already installed) |
| Explicit packages demoted `--asdeps` | `yay -D --asdeps` for names in `previous_dependencies.conf` | HIGH for dual-run stack | `install-deps.sh:26-38, 69-70` | partial (names vary) |
| Deprecated dependency removal | `pacman -Rdd` list of old/git metas | MED | `install-deps.sh:15-22, 52-53` | varies |
| Residual: `--skip-sysupdate` still default | Under SAFE_DEFAULTS, Syu is skipped on wrapper `install` | LOW (protective) | `arch/dots-hyprland.sh:12` SAFE_DEFAULTS | N/A |

**Note:** `install-files` alone does not run Syu; full `install` pipeline runs deps first. Files axes and deps/sysupdate axis are independent (D-09).

---

## Host snapshot (live ~/.config, 2026-08-04)

Read-only presence check at inventory write time (`test -e` only; no mutation). Full re-scan and column refresh planned in **10-05**.

| Path under `~/.config` | Present? | Notes |
|------------------------|----------|-------|
| `hypr/hyprland.conf` | yes | 465 lines personal SoT |
| `hypr/hyprland/` | yes | minimal |
| `hypr/hyprland.lua` | no | would install on hypr axis |
| `hypr/hyprlock.conf` | yes | auto_backup → `.new` if not firstrun |
| `hypr/hypridle.conf` | yes | same |
| `hypr/hyprpaper.conf` | yes | not touched by legacy hypr |
| `hypr/custom/` | no | would seed if hypr axis runs |
| `hypr/hyprlock/` | no | legacy gap |
| `illogical-impulse/installed_true` | yes | not firstrun |
| `fish/` | yes | clash if `--core` dropped |
| `kitty/` | yes | clash |
| `starship.toml` | yes | clash |
| `fontconfig/` | yes | clash |
| `mpv/` | yes | clash |
| `dolphinrc` | yes | clash |
| `fuzzel/` | no | greenfield if core dropped |
| `matugen/` | no | greenfield |
| `wlogout/` | no | greenfield |

---

## UNKNOWN / research notes

| Item | Status | Note | Source to recheck |
|------|--------|------|-------------------|
| `~/.config/hypr/hyprlock/` helpers/colors | UNKNOWN / gap | Upstream `hyprlock.conf` may `source` `hyprlock/colors.conf`, but legacy only auto_backups the `.conf` file — dir not installed | RESEARCH open Q1 / Pitfall 4; `3.files-legacy.sh` hypr case; upstream dots tree |
| Exact `previous_dependencies.conf` asdeps name set on this host | UNKNOWN | Coarse row only; expand with live `pacman -Qe` cross-check in 10-04 | `install-deps.sh` + conf file |
| `--exp-files` behavioral deltas | OUT OF DEFAULT SCOPE | Inventory assumes legacy; exp may sync whole `hypr/` differently | `3.files-exp.yaml` contrast only |
| Plasma-browser-integration size/pull when core dropped | UNKNOWN | Optional pacman path if plasmaintg not skipped | `install-deps.sh:106-122` |

---

## Sources

Primary evidence paths (re-openable for Phase 11):

| Source | Role |
|--------|------|
| `arch/dots-hyprland.sh` | SAFE_DEFAULTS definition, injection, backup gate, dry-run |
| `vendor/dots-hyprland/sdata/subcmd-install/3.files-legacy.sh` | Legacy hypr + misc + fish/fontconfig path effects (default SoT) |
| `vendor/dots-hyprland/sdata/subcmd-install/3.files.sh` | Helpers: rsync sync, auto_backup, ignore_existing |
| `vendor/dots-hyprland/sdata/subcmd-install/options.sh` | Flag semantics (`--core`, `--skip-hyprland`, `--skip-sysupdate`) |
| `vendor/dots-hyprland/sdata/dist-arch/install-deps.sh` | `pacman -Syu`, metas, asdeps, deprecated removals |
| Live host `~/.config` | Host present? columns (read-only scan 2026-08-04) |
| `.planning/phases/10-full-install-impact-inventory/10-RESEARCH.md` | Assembled research cites (seed; re-verify against setup) |
| `docs/dots-hyprland-workflow.md` | Secondary safe dual-run narrative only (not inventory SoT) |
