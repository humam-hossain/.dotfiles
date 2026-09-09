# Phase 10 — Full-install impact inventory

**Created:** 2026-08-04  
**Host scan refreshed:** 2026-08-04 (read-only `test -e` under live `~/.config`)  
**Status:** Final — INV-01..04 complete; host snapshot + Sources finalized 2026-08-04 (10-05)

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
| `~/.local/share/icons/illogical-impulse.svg` | `install_file` icon (runs outside SKIP_HYPRLAND case — always when files step reaches it) | LOW | `3.files-legacy.sh:79` | yes (PRESENT) |

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

**When:** Operator runs install/files **without** `--core` (re-enables the four skips that `--core` sets).  
**Independence (D-09):** This axis alone — does not imply dropping `--skip-hyprland` or allowing sysupdate.

### What `--core` skips today (so dropping re-enables)

From `options.sh:90`:

```bash
--core) SKIP_PLASMAINTG=true;SKIP_FISH=true;SKIP_FONTCONFIG=true;SKIP_MISCCONF=true;shift;;
```

| Flag / skip set by `--core` | What re-enables when dropped | Source |
|-----------------------------|------------------------------|--------|
| `SKIP_PLASMAINTG` | Optional `plasma-browser-integration` package path in deps | `options.sh:90`; `install-deps.sh:106-122` |
| `SKIP_FISH` | `~/.config/fish/` sync exclude conf.d | `options.sh:90`; `3.files-legacy.sh:30-33` |
| `SKIP_FONTCONFIG` | `~/.config/fontconfig/` dir sync (or fontset) | `options.sh:90`; `3.files-legacy.sh:37-42` |
| `SKIP_MISCCONF` | Full misc find loop over `dots/.config/*` (excl. quickshell/fish/hypr/fontconfig) + konsole share | `options.sh:90`; `3.files-legacy.sh:7-18` |

**Not controlled by `--core`:** quickshell (`SKIP_QUICKSHELL` independent — dual-run already installs it). Hypr is Axis A (`SKIP_HYPRLAND`). Do not invent dual-run chrome clash rows (D-15).

### Fish + fontconfig + plasmaintg

| Path | Effect | Risk | Source | Host present? |
|------|--------|------|--------|---------------|
| `~/.config/fish/` | `install_dir__sync_exclude` — rsync sync with `--delete` **except** `conf.d` | HIGH | `3.files-legacy.sh:30-33`; `3.files.sh:161-171` | yes (PRESENT) |
| `~/.config/fontconfig/` | `install_dir__sync` default fontset, or `dots-extra/fontsets/$FONTSET` if `--fontset` | HIGH | `3.files-legacy.sh:37-42` | yes (PRESENT) |
| `plasma-browser-integration` (package) | Optional `pacman -S` when not skipped; ~600KiB alone, can pull ~600MiB KDE if absent | MED | `install-deps.sh:106-122` | ABSENT (`pacman -Qq`) |

### Full misc catalog (SKIP_MISCCONF off)

Basenames from `find dots/.config -mindepth 1 -maxdepth 1` excluding `quickshell`, `fish`, `hypr`, `fontconfig` (pin scan 2026-08-04). Install mode from `3.files-legacy.sh:11-16`: **dirs** → `install_dir__sync` (`--delete`); **files** → `install_file` (cp -f). Plus konsole share at `3.files-legacy.sh:18`.

| Path | Effect | Risk | Source | Host present? |
|------|--------|------|--------|---------------|
| `~/.config/chrome-flags.conf` | file `install_file` | LOW (greenfield) | misc loop `3.files-legacy.sh:11-16` | ABSENT |
| `~/.config/code-flags.conf` | file `install_file` | LOW (greenfield) | same | ABSENT |
| `~/.config/darklyrc` | file `install_file` | LOW (greenfield) | same | ABSENT |
| `~/.config/dolphinrc` | file `install_file` | MED (personal PRESENT collision) | same | yes (PRESENT) |
| `~/.config/foot/` | dir `install_dir__sync` `--delete` | MED (greenfield) | same | ABSENT |
| `~/.config/fuzzel/` | dir sync `--delete` | MED (greenfield) | same | ABSENT |
| `~/.config/kdeglobals` | file `install_file` | MED (personal PRESENT) | same | yes (PRESENT) |
| `~/.config/kde-material-you-colors/` | dir sync `--delete` | MED (greenfield) | same | ABSENT |
| `~/.config/kitty/` | dir sync `--delete` | HIGH (personal PRESENT) | same | yes (PRESENT) |
| `~/.config/konsolerc` | file `install_file` | LOW (greenfield) | same | ABSENT |
| `~/.config/Kvantum/` | dir sync `--delete` | MED (greenfield) | same | ABSENT |
| `~/.config/matugen/` | dir sync `--delete` | MED (greenfield) | same | ABSENT |
| `~/.config/mpv/` | dir sync `--delete` | MED–HIGH (personal PRESENT) | same | yes (PRESENT) |
| `~/.config/starship.toml` | file `install_file` | HIGH (personal PRESENT) | same | yes (PRESENT) |
| `~/.config/thorium-flags.conf` | file `install_file` | LOW (greenfield) | same | ABSENT |
| `~/.config/wlogout/` | dir sync `--delete` | MED (greenfield) | same | ABSENT |
| `~/.config/xdg-desktop-portal/` | dir sync `--delete` | MED (greenfield) | same | ABSENT |
| `~/.config/zshrc.d/` | dir sync `--delete` | LOW (greenfield) | same | ABSENT |
| `~/.local/share/konsole/` | `install_dir` (non-delete dir copy into share) | MED | `3.files-legacy.sh:18` | ABSENT |

### Named INV-03 collision set (summary)

Host PRESENT collisions if `--core` dropped: **fish, kitty, starship.toml, fontconfig, mpv, dolphinrc, kdeglobals**. Greenfield-only from named set: fuzzel, matugen, wlogout (ABSENT).

---

## Axis: allow sysupdate / package effects

**When:** Operator runs the **deps** path (`install` / `install-deps`) with `SKIP_SYSUPDATE` unset, and related always-on deps behaviors.  
**Independence (D-09):** This axis alone — does not require dropping `--core` or `--skip-hyprland`.  
**SAFE_DEFAULTS interaction (inventory only):** default wrapper injects `--skip-sysupdate` on `install` / `install-files`; dropping it is a future full-profile concern (Phase 12) — this section maps the effect only.

### Pipeline scope (files-only vs full install/deps)

| Path | Effect | Risk | Source | Host present? |
|------|--------|------|--------|---------------|
| `install-files` alone | Runs files step only — **does not** run `pacman -Syu` or meta PKGBUILD loop | LOW (no Syu) | setup files path; deps script not sourced for files-only | N/A |
| Full `install` / `install-deps` | Runs `install-deps.sh` first (deprecated removal → optional Syu → asdeps implicitize → meta build loop → optional plasmaintg) | HIGH overall | `sdata/dist-arch/install-deps.sh` whole script | N/A |
| Wrapper default `./arch/dots-hyprland.sh install` | Injects `--skip-sysupdate` via SAFE_DEFAULTS → Syu skipped; other deps steps still run unless further skips | MED under residual | `arch/dots-hyprland.sh:12`, `127-131`, `1399-1407` | N/A (wrapper) |

### Sysupdate + always-on deps side effects

| Path | Effect | Risk | Source | Host present? |
|------|--------|------|--------|---------------|
| `sudo pacman -Syu` | Full system upgrade when `SKIP_SYSUPDATE` is **unset** | HIGH | `install-deps.sh:56-58` (`case $SKIP_SYSUPDATE`) | N/A (system-wide) |
| `remove_deprecated_dependencies` | `pacman --noconfirm -Rdd` on deprecated list (old metas, `*-git` hypr stack, matugen-bin, …) — **always** on deps path | MED | `install-deps.sh:15-22`, called `:52-53` | varies per name |
| `implicitize_old_dependencies` | For each name in `previous_dependencies.conf` that is still explicit: `yay -D --asdeps` — demotes dual-run stack packages | HIGH for dual-run | `install-deps.sh:26-38`, called `:69-70` | partial (names in conf ∩ explicit pkgs) |
| `yay` bootstrap | If `yay` missing: clone/build `yay-bin` via makepkg | MED | `install-deps.sh:5-13`, `:63-67` | yes (yay typically present) |

### Coarse `illogical-impulse-*` meta PKGBUILD set

From `install-deps.sh:93-103` loop: `install-local-pkgbuild` → `yay -S --asdeps` on PKGBUILD depends, then `makepkg -Afsi`.

| Meta package (coarse) | Effect | Risk | Source | Host present? (`pacman -Qq`) |
|----------------------|--------|------|--------|------------------------------|
| `illogical-impulse-audio` | build/install meta + asdeps depends | MED | `install-deps.sh:93` | installed |
| `illogical-impulse-backlight` | same | MED | same | installed |
| `illogical-impulse-basic` | same | MED | same | installed |
| `illogical-impulse-fonts-themes` | same | MED | same | installed |
| `illogical-impulse-kde` | same | MED | same | installed |
| `illogical-impulse-portal` | same | MED | same | installed |
| `illogical-impulse-python` | same | MED | same | installed |
| `illogical-impulse-screencapture` | same | MED | same | installed |
| `illogical-impulse-toolkit` | same | MED | same | installed |
| `illogical-impulse-widgets` | same | MED | same | installed |
| `illogical-impulse-hyprland` | same | MED–HIGH | `install-deps.sh:94` | installed |
| `illogical-impulse-microtex-git` | same | MED | `install-deps.sh:95` | installed (+ debug pkg present) |
| `illogical-impulse-quickshell-git` | same | MED | `install-deps.sh:96` | installed |
| `illogical-impulse-bibata-modern-classic-bin` | same | LOW–MED | `install-deps.sh:97` | installed |

Host already has dual-run metas installed (2026-08-04 `pacman -Qq` scan). Re-running deps still upgrades/rebuilds with `--needed` flags and still runs Syu/asdeps/deprecated steps as above.

### Optional plasmaintg + wrapper protect mitigation

| Path | Effect | Risk | Source | Host present? |
|------|--------|------|--------|---------------|
| `plasma-browser-integration` | Optional `pacman -S` when `SKIP_PLASMAINTG` unset; ~600KiB alone / ~600MiB KDE pull warning | MED | `install-deps.sh:106-122` | ABSENT (`pacman -Qq`) |
| Wrapper `protect` post-path | After install/install-deps succeed, re-marks `PROTECT_EXPLICIT` packages as `pacman -D --asexplicit` — mitigates asdeps demotion for personal dual-run stack | LOW (mitigation) | `arch/dots-hyprland.sh` protect subcommand / post-install re-mark notes (~46-60, ~192+) | N/A (wrapper behavior) |

**Deprecated removal name classes (for operator awareness, not a full expand):** `illogical-impulse-{microtex,pymyc-aur,oneui4-icons-git}`, `hyprland-qtutils`, many `*-git` hyprland stack packages, `matugen-bin` (`install-deps.sh:18-21`).

---

## Host snapshot (live ~/.config, 2026-08-04)

**Scan method:** read-only `test -e` / `pacman -Qq` only — no rsync/cp/mv/rm, no setup install (D-03, D-05).  
**Refreshed:** 2026-08-04 (finalize pass, plan 10-05). Repo dual-column not used (D-06).

### Hypr + firstrun (Axis A)

| Path | Present? | Notes |
|------|----------|-------|
| `hypr/hyprland.conf` | yes | 465 lines personal SoT; would → `.old` if hypr axis runs |
| `hypr/hyprland/` | yes | minimal + `scripts/`; subject to rsync `--delete` |
| `hypr/hyprland.lua` | no | would be created |
| `hypr/hyprlock.conf` | yes | not firstrun → expect `.new` sidecar |
| `hypr/hypridle.conf` | yes | same |
| `hypr/hyprpaper.conf` | yes | not touched by legacy hypr block |
| `hypr/custom/` | no | would seed if hypr axis runs |
| `hypr/hyprlock/` | no | legacy gap (conf may source dir) |
| `hypr/hyprland.conf.bak` | yes | personal backup; not in install list |
| `hypr/hyprland-gui.conf` | yes | personal; not in install list |
| `illogical-impulse/installed_true` | yes | **not firstrun** |
| `~/.local/share/icons/illogical-impulse.svg` | yes | always-on files step icon |

### Misc / fish / fontconfig collisions (Axis B)

| Path | Present? | Notes |
|------|----------|-------|
| `fish/` | yes | HIGH clash if `--core` dropped |
| `fontconfig/` | yes | HIGH clash |
| `kitty/` | yes | HIGH clash (dir sync `--delete`) |
| `starship.toml` | yes | HIGH clash |
| `mpv/` | yes | MED–HIGH clash |
| `dolphinrc` | yes | MED clash |
| `kdeglobals` | yes | MED clash |
| `quickshell/` | yes | dual-run already; **not** controlled by `--core` |
| `fuzzel/`, `matugen/`, `wlogout/`, `foot/`, `Kvantum/`, … | no | greenfield if misc enabled |
| `chrome-flags.conf`, `code-flags.conf`, `darklyrc`, `konsolerc`, `thorium-flags.conf` | no | greenfield files |
| `kde-material-you-colors/`, `xdg-desktop-portal/`, `zshrc.d/` | no | greenfield dirs |
| `~/.local/share/konsole/` | no | greenfield share path |

### Packages (Axis C) — read-only query

| Item | Present? | Notes |
|------|----------|-------|
| `illogical-impulse-*` metas (audio…widgets, hyprland, microtex-git, quickshell-git, bibata) | yes | dual-run already installed |
| `plasma-browser-integration` | no | ABSENT; optional if plasmaintg not skipped |

### Optional setups note (LOW, non-blocking)

`2.setups.sh` may run post-files session setups on full install; not expanded row-by-row here. Primary blast radius for Phase 10 is files + deps documented above. Source: `vendor/dots-hyprland/sdata/subcmd-install/2.setups.sh`.

---

## UNKNOWN / research notes

| Item | Status | Note | Source to recheck |
|------|--------|------|-------------------|
| `~/.config/hypr/hyprlock/` helpers/colors | UNKNOWN / gap | Upstream `hyprlock.conf` may `source` `hyprlock/colors.conf`, but legacy only auto_backups the `.conf` file — dir **not** installed | RESEARCH Pitfall 4; `3.files-legacy.sh` hypr case; upstream `dots/.config/hypr` |
| Exact host intersection of `previous_dependencies.conf` ∩ explicit pkgs | PARTIAL | Axis C documents mechanism + conf path; live per-name demotion set still machine-time dependent | `install-deps.sh:26-38`; `sdata/dist-arch/previous_dependencies.conf`; `pacman -Qeq` |
| `--exp-files` behavioral deltas | OUT OF DEFAULT SCOPE | Inventory SoT is **legacy** (`3.files-legacy.sh`); exp may sync whole `hypr/` differently — note only, not primary structure | `3.files-exp.yaml` / exp path contrast |
| `2.setups.sh` side-effect depth | LOW / optional | Setups may touch session services beyond files/deps; not blocking Phase 10 success criteria | `2.setups.sh` |
| Plasma-browser-integration KDE pull size on bare systems | DOCUMENTED | Script warns ~600MiB if KDE absent; this host package ABSENT | `install-deps.sh:106-122` |

---

## Sources

Primary evidence paths (re-openable for Phase 11 dispositions):

| Source | Role |
|--------|------|
| `arch/dots-hyprland.sh` | SAFE_DEFAULTS definition (`:12`), injection (`:127-131`, `:1399-1407`), backup gate, protect/asexplicit mitigation |
| `vendor/dots-hyprland/sdata/subcmd-install/options.sh` | Flag semantics; `--core` expansion (`:90`); skip flags |
| `vendor/dots-hyprland/sdata/subcmd-install/3.files-legacy.sh` | Default files SoT: misc loop, fish, fontconfig, hypr case |
| `vendor/dots-hyprland/sdata/subcmd-install/3.files.sh` | Helpers: `rsync_dir__sync`, `install_file__auto_backup`, `install_dir__ignore_existing`, firstrun detect |
| `vendor/dots-hyprland/sdata/dist-arch/install-deps.sh` | `pacman -Syu`, deprecated removals, asdeps implicitize, meta PKGBUILD loop, plasmaintg |
| `vendor/dots-hyprland/sdata/dist-arch/previous_dependencies.conf` | asdeps name list input |
| `vendor/dots-hyprland/sdata/subcmd-install/2.setups.sh` | Optional setups side effects (LOW note only) |
| `vendor/dots-hyprland/dots/.config/` | Misc catalog basenames (find pin) |
| Live host `~/.config` + `pacman -Qq` | Host present? columns — read-only scan **2026-08-04** |
| `.planning/phases/10-full-install-impact-inventory/10-RESEARCH.md` | Research seed; re-verified against setup sources during plans |
| `docs/dots-hyprland-workflow.md` | Secondary safe dual-run narrative only (not inventory SoT) |
| `scripts/phase10-inventory-assert.sh` | Structural/lint gate for this artifact |
