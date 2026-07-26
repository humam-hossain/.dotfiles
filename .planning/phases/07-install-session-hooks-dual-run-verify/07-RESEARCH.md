# Phase 7: Install, Session Hooks & Dual-Run Verify - Research

**Researched:** 2026-07-26  
**Domain:** Live dots-hyprland install + personal Hyprland session hooks + dual-run verification  
**Confidence:** HIGH (codebase + live machine probes); MEDIUM (Hyprland `env=` mid-session apply semantics)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Symlink break & pre-install backup
- **D-01:** Before install-files path runs: **unlink** live `~/.config/quickshell` (symlink only) and **leave the path absent** so upstream setup creates a **real directory**. Do **not** follow the symlink or delete the repo target.
- **D-02:** **No extra** operator pre-backup tarball step for Phase 7. Rely on the existing Phase 6 wrapper **interactive backup gate** only. Do **not** encourage or default to `--skip-backup` / `--allow-skip-backup`.
- **D-03:** **Stop running `qs`** before retarget/install so nothing holds the symlink path mid-rsync.
- **D-04:** Leave in-repo `.config/quickshell` **alone** this phase. Product retirement is Phase 8 after LIVE-04.

#### Install command sequence
- **D-05:** First adoption uses **one-shot** `arch/dots-hyprland.sh install` (deps + setups + files) with Phase 6 safe defaults injection (`--core --skip-hyprland --skip-sysupdate`).
- **D-06:** Plans **must** include a **dry-run first** pass (`--dry-run`) and confirm argv shows the safe defaults before the live install.
- **D-07:** Install may run **mid-session** (terminal inside Hyprland) after `qs` is stopped; apply session changes afterward via reload/restart (see D-16).
- **D-08:** On failure mid-install: **fix cause and re-run wrapper**. No automated rollback script in Phase 7.

#### Session hook placement
- **D-09:** **Keep personal hyprland config** as source of truth. Do **not** install/replace with ii `hyprland.lua` / full hypr tree this phase (consistent with `--skip-hyprland`).
- **D-10:** Add the two hooks **inline** in personal `hyprland.conf` (not a separate sourced snippet).
- **D-11:** **Commit** hooks into `.dotfiles` (`.config/hypr/hyprland.conf`) this phase so LIVE-02 is versioned.
- **D-12:** `ILLOGICAL_IMPULSE_VIRTUAL_ENV` = **`~/.local/state/quickshell/.venv`** (upstream default / `$XDG_STATE_HOME/quickshell/.venv`).
- **D-13:** Session start: **`exec-once = qs -c ii`** (plain; alongside existing waybar exec-once — do not remove waybar).

#### Dual-run verify bar policy
- **D-14:** Order: **hooks first, then verify** — commit env + exec-once, apply session changes, then check LIVE-04 (not “manual qs only then maybe hook”).
- **D-15:** Dual-run policy: **both bars OK even if they overlap**. Waybar remains current primary chrome; no layout cutover work this phase.
- **D-16:** LIVE-04 pass requires **all three**: (1) `qs` process running with config `ii`, (2) `ILLOGICAL_IMPULSE_VIRTUAL_ENV` set in the Hyprland session, (3) operator-confirmed **visible** ii shell chrome on screen.
- **D-17:** Apply session changes with **`hyprctl reload` + restart `qs`** when possible (prefer over mandatory full re-login).

### Claude's Discretion
- Exact `pkill`/`qs` stop command and whether to warn if qs was not running
- Exact hypr `env =` line syntax/spacing for the venv path (must resolve to upstream default path)
- Placement of the new lines within `hyprland.conf` (near existing exec-once block preferred)
- Exact dry-run / live install command order in plans and UAT checklist wording
- How to assert “real directory not symlink” (e.g. `test ! -L && test -d` plus presence of `ii` tree)
- Whether to also sync live `~/.config/hypr/hyprland.conf` from repo in the same plan step (D-11 commits repo; live must match for session)

### Deferred Ideas (OUT OF SCOPE)
- Retire `.config/quickshell` product tree + `arch/quickshell.sh` — Phase 8
- Full clone/install/update playbook — Phase 9
- Document restore from `~/ii-original-dots-backup` as primary recovery narrative — Phase 9 (Phase 7 recovery is re-run only)
- Waybar/rofi/swaync cutover — later milestone
- Full Lua hypr cutover — later milestone
- Wrapper `verify` subcommand — POLISH-01 / future
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| LIVE-01 | After install-files, `~/.config/quickshell` is a real installed tree synced from upstream (not a symlink to `.dotfiles/.config/quickshell`) | Pre-unlink symlink (D-01); `install_dir__sync` rsync `--delete` from `dots/.config/quickshell`; assert `! -L && -d` + `ii/shell.qml` |
| LIVE-02 | Personal Hyprland config sets `ILLOGICAL_IMPULSE_VIRTUAL_ENV` to the ii venv path and starts the shell with `qs -c ii` | Inline `env =` + `exec-once = qs -c ii` in `.config/hypr/hyprland.conf`; commit (D-11); sync live conf |
| LIVE-03 | After adoption, Waybar (and existing swaync/rofi session pieces as configured) still start — dual-run preserved | Keep waybar exec-once; `--skip-hyprland` + `--core` avoid hypr/misc overwrite; process asserts for waybar/swaync |
| LIVE-04 | Operator can verify installed ii shell is running (visible bar/shell chrome from `qs -c ii`) | qs process + config `ii`; env on qs (and ideally session); operator visual confirm |
</phase_requirements>

## Summary

Phase 7 is the **first machine-mutating adoption step**: break the v0.1 live Quickshell symlink, run the Phase 6 wrapper one-shot install with safe defaults, add two personal Hyprland hooks, and prove dual-run (Waybar + `qs -c ii`). It does **not** retire the in-repo product tree (Phase 8) and does **not** take over Hyprland with ii Lua (locked `--skip-hyprland`).

Live machine state at research time confirms the critical hazard is still present: `~/.config/quickshell` is a **symlink** into `.dotfiles/.config/quickshell` (933 tracked files). If install-files runs while that symlink exists, `rsync -a --delete` from upstream writes **through the symlink into the git tree**. Unlinking first (path absent) is mandatory. [VERIFIED: live `ls -la ~/.config/quickshell` + `3.files-legacy.sh` `install_dir__sync`]

The Phase 6 wrapper is ready: `printf 'yes\n' | ./arch/dots-hyprland.sh install --dry-run` already prints argv  
`./setup install --core --skip-hyprland --skip-sysupdate`. Live install is the same without `--dry-run`, interactive `yes` at the wrapper gate, then upstream may prompt a second backup (to `~/ii-original-dots-backup`). [VERIFIED: wrapper dry-run 2026-07-26]

**Primary recommendation:** Execute three sequential plans — (1) stop qs + safe symlink unlink, (2) dry-run then live one-shot wrapper install, (3) commit/sync hypr hooks then mid-session apply + LIVE-01..04 checklist — with re-run-only recovery and no automated rollback.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Pre-install qs stop + symlink break | Host session / operator shell | — | Protects repo tree from rsync-through-symlink |
| Deps / setups / files install | Upstream `vendor/dots-hyprland/./setup` | Wrapper injects flags + backup gate | Setup is SoT; wrapper is UX only |
| Safe dual-run flag profile | `arch/dots-hyprland.sh` | Setup `SKIP_*` vars | Phase 6 already encodes `--core --skip-hyprland --skip-sysupdate` |
| Live QS tree ownership | `~/.config/quickshell` (XDG, real dir) | Vendor pin is source of rsync content | LIVE-01; not repo symlink |
| Python venv for ii scripts | `~/.local/state/quickshell/.venv` | setups `install-python-packages` | Required for ii QML Process scripts |
| Session env + autostart | Personal `hyprland.conf` | Hyprland compositor | LIVE-02; personal SoT, not ii lua |
| Dual-run bar policy | Personal exec-once (waybar kept) | qs -c ii additive | LIVE-03 / D-15 |
| LIVE verify | Operator + shell smoke asserts | — | LIVE-04 includes visual chrome |

## Standard Stack

### Core

| Tool / artifact | Version (verified) | Purpose | Why Standard |
|-----------------|-------------------|---------|--------------|
| `arch/dots-hyprland.sh` | Phase 6 (present, executable) | One-shot install entry with safe defaults + gate + `--dry-run` | WRAP complete; do not bypass with raw `./setup` for first adoption [VERIFIED: dry-run argv] |
| `vendor/dots-hyprland/setup` | Pin from Phase 5 | Upstream installer SoT | deps → setups → files [VERIFIED: executable + submodule `.git`] |
| Quickshell `qs` | 0.3.0 (Arch package) | Runtime for `qs -c ii` | Already on PATH; setup may also pull ii meta packages [VERIFIED: `qs --version`] |
| Hyprland | 0.56.0 | Compositor / session SoT via personal conf | Keep personal entry; add hooks only [VERIFIED: `hyprctl version`] |
| Personal `.config/hypr/hyprland.conf` | Live matches repo | Session hooks SoT | LIVE-02 versioned in git [VERIFIED: `cmp` live == repo] |

### Supporting

| Tool / path | Version / state | Purpose | When to Use |
|-------------|-----------------|---------|-------------|
| `~/.local/state/quickshell/.venv` | **absent today** — created by setups | ii Python packages via `uv` | After `install-setups` / full `install` |
| `uv` | 0.9.25 at `~/.local/bin/uv` | Venv + pip install for ii | Already present; setup may reinstall/use |
| `yay` | v13.0.1 | AUR deps for illogical-impulse packages | install-deps stage |
| `hyprctl` | with Hyprland 0.56.0 | reload config; inspect session | Post-hook apply (D-17) |
| `pkill` / `pgrep` | system | Stop/verify qs and waybar | Pre-install + LIVE checks |
| `~/ii-original-dots-backup` | **absent today** | Upstream backup of clashing paths | Created when operator accepts upstream backup prompt |
| Nested `shapes` submodule | LICENSE present | QML widgets under `ii/modules/.../shapes` | Already OK from Phase 5 |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| One-shot `install` | Staged `install-deps` → `install-setups` → `install-files` | Staged is safer for debugging failures; **locked D-05** is one-shot |
| Extra pre-backup tarball | Wrapper + upstream backup only | User declined extra tarball (D-02) |
| Separate sourced hypr snippet | Inline lines in `hyprland.conf` | **Locked D-10** — matches personal conf style (no `source =` today) |
| Full ii hyprland.lua entry | Personal conf hooks | Deferred; would rename conf without `--skip-hyprland` |

**Installation (operator sequence — not a package manager install):**

```bash
# From REPO_ROOT=/home/pera/github_repo/.dotfiles
# 1) Pre-install (07-01)
pkill -x qs 2>/dev/null || true
pkill -x quickshell 2>/dev/null || true
if [ -L "$HOME/.config/quickshell" ]; then
  rm "$HOME/.config/quickshell"   # removes symlink only — never rm -rf
fi
test ! -e "$HOME/.config/quickshell"   # path absent (preferred)

# 2) Dry-run then live (07-02)
printf 'yes\n' | ./arch/dots-hyprland.sh install --dry-run
# Assert log contains: ./setup install --core --skip-hyprland --skip-sysupdate
./arch/dots-hyprland.sh install
# Type yes at wrapper gate; answer upstream backup prompt (prefer y)

# 3) Hooks + apply (07-03) — after conf edit + live sync
hyprctl reload
pkill -x qs 2>/dev/null || true
ILLOGICAL_IMPULSE_VIRTUAL_ENV="$HOME/.local/state/quickshell/.venv" qs -c ii -d &
```

**Version verification:** No new language packages. Host tools verified 2026-07-26 via `command -v` / `--version` as above.

## Package Legitimacy Audit

> Phase 7 does **not** introduce npm/PyPI/crates packages via the planner. Dependency install is delegated to upstream `./setup` → Arch/AUR metapackages (`yay`). No Package Legitimacy Gate for registry packages is required for RESEARCH recommendations.

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| *(none — no new third-party language packages)* | — | — | — | — | N/A | N/A |

**Packages removed due to [SLOP] verdict:** none  
**Packages flagged as suspicious [SUS]:** none  

*Upstream AUR package names (e.g. `illogical-impulse-*`) are owned by setup’s dist-arch PKGBUILDs — do not re-list or reimplement them in plans.*

## Architecture Patterns

### System Architecture Diagram

```
[Operator terminal in Hyprland session]
        │
        ├─1─ pkill qs  ──►  (no qs holding path)
        ├─2─ unlink ~/.config/quickshell  (symlink only)
        │         path ABSENT ──X──► .dotfiles/.config/quickshell (untouched)
        │
        ├─3─ arch/dots-hyprland.sh install [--dry-run first]
        │         │  safe defaults: --core --skip-hyprland --skip-sysupdate
        │         │  backup gate: type "yes"
        │         ▼
        │    vendor/dots-hyprland/./setup install …
        │         ├─ deps-router  → yay illogical-impulse-* (network/sudo)
        │         ├─ setups       → uv venv @ ~/.local/state/quickshell/.venv
        │         │                 + i2c/video groups, ydotool, bluetooth, …
        │         └─ files        → auto_backup → rsync --delete
        │                           dots/.config/quickshell → ~/.config/quickshell
        │                           (hypr SKIPPED; misc/fish/font SKIPPED via --core)
        │
        ├─4─ Edit + commit .config/hypr/hyprland.conf
        │         env = ILLOGICAL_IMPULSE_VIRTUAL_ENV,~/.local/state/quickshell/.venv
        │         exec-once = qs -c ii
        │         (keep: waybar & swaync & hyprpaper &)
        │         sync → ~/.config/hypr/hyprland.conf
        │
        └─5─ hyprctl reload + restart qs with env
                  │
                  ▼
         Hyprland session (dual-run)
            ├─ waybar (primary chrome — LIVE-03)
            ├─ swaync / hyprpaper (existing)
            └─ qs -c ii → ~/.config/quickshell/ii/shell.qml (LIVE-04)
                  uses $ILLOGICAL_IMPULSE_VIRTUAL_ENV for python scripts
```

### Recommended Project Structure (phase touch points)

```
.dotfiles/
├── arch/
│   ├── dots-hyprland.sh          # USE — live install (do not rewrite)
│   ├── hyprland.sh               # OPTIONAL helper: cp .config/hypr/* → ~/.config/hypr/
│   └── quickshell.sh             # DO NOT re-run (would re-symlink)
├── .config/
│   ├── hypr/hyprland.conf        # MODIFY — inline env + exec-once (commit)
│   └── quickshell/               # LEAVE ALONE (Phase 8)
└── vendor/dots-hyprland/         # READ-ONLY pin — setup SoT
    ├── setup
    ├── sdata/subcmd-install/{options,2.setups,3.files,3.files-legacy}.sh
    └── dots/.config/quickshell/ii/shell.qml   # source of live tree
```

### Pattern 1: Safe symlink break before rsync

**What:** Remove the directory symlink with plain `rm` (not `rm -rf`) so only the link is deleted; leave path absent.  
**When to use:** Always before first install-files on this host (current state is symlink).  
**Example:**

```bash
# Source: PITFALLS.md Pitfall 2 + live probe 2026-07-26
if [ -L "$HOME/.config/quickshell" ]; then
  echo "[CONFIG] removing QS symlink (repo target preserved)"
  rm "$HOME/.config/quickshell"
elif [ -e "$HOME/.config/quickshell" ]; then
  echo "[WARN] path exists and is not a symlink: $(ls -ld "$HOME/.config/quickshell")"
  # D-01 only mandates unlink-symlink. Real dir is OK for re-run (rsync --delete).
fi
test ! -L "$HOME/.config/quickshell"
```

### Pattern 2: Dry-run argv gate then live one-shot

**What:** Wrapper `--dry-run` still runs backup_gate (needs `yes`), then prints would-exec argv and exits 0 without calling setup.  
**When to use:** Mandatory before first live install (D-06).  
**Example:**

```bash
# Source: arch/dots-hyprland.sh (verified dry-run output)
out=$(printf 'yes\n' | ./arch/dots-hyprland.sh install --dry-run 2>&1)
echo "$out" | grep -q -- '--core'
echo "$out" | grep -q -- '--skip-hyprland'
echo "$out" | grep -q -- '--skip-sysupdate'
echo "$out" | grep -q 'dry-run: would exec'
# Expected command line:
# ./setup install --core --skip-hyprland --skip-sysupdate
```

### Pattern 3: Personal hypr hooks (inline, additive)

**What:** Add env + exec-once next to existing AUTOSTART / ENVIRONMENT blocks; never remove waybar line.  
**When to use:** After successful files install (D-14: hooks before LIVE-04).  
**Recommended lines (discretion: match personal conf comma style, no space after comma):**

```conf
# Source: vendor uv/README.md + STACK.md + personal conf style (env = KEY,value)
# illogical-impulse (Phase 7 LIVE-02) — required when --skip-hyprland skips ii env.lua
env = ILLOGICAL_IMPULSE_VIRTUAL_ENV,~/.local/state/quickshell/.venv

# Live ii shell (dual-run with waybar)
exec-once = qs -c ii
```

**Placement (recommended):**
- `env =` under existing `### ENVIRONMENT VARIABLES ###` block (near lines 104–105 `XCURSOR_*`)
- `exec-once = qs -c ii` immediately after `exec-once = waybar & swaync & hyprpaper &` (line 64) so dual-run intent is visible

**Live sync (recommended same plan step as D-11):**

```bash
# Prefer single-file sync so other live-only hypr files are untouched:
cp -f .config/hypr/hyprland.conf "$HOME/.config/hypr/hyprland.conf"
# Or full personal hypr deploy (also copies other hypr/*):
# bash arch/hyprland.sh   # heavier; packages + swaync too
cmp -s .config/hypr/hyprland.conf "$HOME/.config/hypr/hyprland.conf"
```

### Pattern 4: Mid-session apply despite env= startup semantics

**What:** `hyprctl reload` reloads config keywords/binds but **does not re-export `env =` into the running Hyprland process environment**. New children of Hyprland keep the compositor’s original environ until Hyprland restarts. [ASSUMED: community/wiki consensus; consistent with upstream 3.files.sh warning “a restart is needed for applying it” — VERIFIED warning text in 3.files.sh]

**When to use:** After hooks are on disk (D-17 prefers reload+restart qs over mandatory re-login).

**Mid-session verify launch (recommended):**

```bash
hyprctl reload
hyprctl configerrors   # should be empty / no parse errors for new lines
pkill -x qs 2>/dev/null || true
# Inject env on the qs process so ii scripts work without full re-login:
ILLOGICAL_IMPULSE_VIRTUAL_ENV="${HOME}/.local/state/quickshell/.venv" \
  qs -c ii -d
# -d daemonizes; -c ii loads ~/.config/quickshell/ii/shell.qml
```

**Session permanence:** After next full Hyprland start (logout/login or `hyprctl dispatch exit` + relaunch), `env =` from conf applies to the compositor and all children — then plain `exec-once = qs -c ii` is enough.

### Anti-Patterns to Avoid

- **`rm -rf ~/.config/quickshell` while it is a symlink:** Risk of deleting or damaging the repo tree depending on tools/flags; use plain `rm` on the link only.
- **Re-running `arch/quickshell.sh` after unlink:** Recreates the symlink (`rm -rf "$QS_DST"; ln -s "$QS_SRC" "$QS_DST"`) and undoes LIVE-01.
- **Calling setup without wrapper safe defaults:** Omitting `--skip-hyprland` renames `hyprland.conf` → `.old`.
- **`--skip-backup` on first adoption:** Refused by wrapper unless `--allow-skip-backup`; D-02 forbids encouraging it.
- **Deleting in-repo `.config/quickshell` this phase:** Phase 8 only (D-04).
- **Assuming `hyprctl reload` alone sets `ILLOGICAL_IMPULSE_VIRTUAL_ENV` for LIVE-04:** Inject env when starting qs mid-session; optional full re-login for compositor-level env.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Install ii deps/packages | Custom pacman/yay arrays | `arch/dots-hyprland.sh install` → `./setup` | WRAP-01 / bitrot risk |
| Copy QS tree manually | Hand rsync of vendor dots | setup `install_dir__sync` | Upstream owns listfile, backup, firstrun |
| Session env via shell profile only | Export only in zshrc | Hyprland `env =` in conf | ii expects compositor-level env for child processes |
| Automated rollback | Restore scripts from tarball | Fix cause + re-run wrapper (D-08) | Explicitly out of scope |
| Wrapper `verify` subcommand | New CLI surface | Inline plan smoke asserts | POLISH-01 deferred |

**Key insight:** Phase 7 is orchestration and session wiring, not a new installer. The failure mode is order-of-operations (symlink → rsync into git), not missing packages lists.

## Common Pitfalls

### Pitfall 1: rsync-through-symlink into the git tree

**What goes wrong:** `install_dir__sync` runs `rsync -a --delete` into `$XDG_CONFIG_HOME/quickshell`. If that path is a symlink into `.dotfiles/.config/quickshell`, the live product and git tree are merged/destroyed.  
**Why it happens:** v0.1 `arch/quickshell.sh` used directory symlink delivery.  
**How to avoid:** D-01/D-03 sequence before any files step; assert path not a symlink after install.  
**Warning signs:** `test -L ~/.config/quickshell`; `readlink -f` still under `.dotfiles`; mass unexpected git changes under `.config/quickshell`.

### Pitfall 2: Double interactive prompts (wrapper + upstream)

**What goes wrong:** Operator confuses wrapper gate with upstream backup prompt and aborts mid-way.  
**Why it happens:** Wrapper requires typing `yes`; upstream `auto_backup_configs` then asks y/N for `~/ii-original-dots-backup` unless `--skip-backup` (not used).  
**How to avoid:** UAT text: “Type `yes` at wrapper; prefer `y` at upstream backup.”  
**Warning signs:** Install stops at “Would you like to backup…”; empty `~/ii-original-dots-backup` after “success” if user chose no.

### Pitfall 3: `--skip-hyprland-entry` mistaken for protection

**What goes wrong:** conf still renamed to `.old`.  
**Why it happens:** Rename is outside the entry-only skip.  
**How to avoid:** Rely only on wrapper-injected full `--skip-hyprland` (already default).  
**Warning signs:** `hyprland.conf.old` appears; session boots different entry.

### Pitfall 4: Mid-session env not applied by reload

**What goes wrong:** LIVE-04 (2) fails if checker only inspects Hyprland `/proc/$pid/environ` after reload without restart.  
**Why it happens:** `env =` is startup-time for the compositor.  
**How to avoid:** For mid-session: start qs with env prefix; verify qs `/proc/<qs_pid>/environ`. Document optional re-login for compositor-level permanence. Upstream files step itself prints that a restart is needed for the env var.  
**Warning signs:** qs python scripts fail finding packages; `ILLOGICAL_IMPULSE_VIRTUAL_ENV` empty in qs environ.

### Pitfall 5: Re-introducing symlink via old installer

**What goes wrong:** LIVE-01 regresses.  
**Why it happens:** Habit of running `arch/quickshell.sh`.  
**How to avoid:** Plans explicitly forbid re-running it; Phase 8 retires it.  
**Warning signs:** `test -L ~/.config/quickshell` true again.

### Pitfall 6: Dual-run visual noise mistaken for failure

**What goes wrong:** Two bars overlap → operator “fails” dual-run.  
**Why it happens:** Both waybar and ii bar autostart.  
**How to avoid:** D-15 — both bars OK; Waybar remains primary chrome; no layout cutover.  
**Warning signs:** None for v0.2 — overlap is accepted.

### Pitfall 7: Long install-deps failure (network/AUR/python 3.12)

**What goes wrong:** One-shot install dies mid-deps; partial state.  
**Why it happens:** Many AUR builds; uv wants python 3.12 (`python3.12` **not** on PATH today).  
**How to avoid:** D-08 re-run wrapper after fixing cause (network, yay conflicts, missing base-devel). Do not invent rollback.  
**Warning signs:** yay errors; uv “no python 3.12”; incomplete `~/.local/state/quickshell/.venv`.

### Pitfall 8: ddcutil / i2c group side effects (non-blocking)

**What goes wrong:** setups add i2c group / modules; historical iGPU hang class if brightness polling enabled.  
**Why it happens:** ii backlight meta + setups.  
**How to avoid:** Do not “test” brightness widgets; package presence ≠ enable polling. Out of scope for LIVE pass/fail.  
**Warning signs:** `journalctl -b | grep ddcutil` growing (monitor, do not block Phase 7).

## Code Examples

### LIVE-01 assert (real directory + ii tree)

```bash
# Source: qs --help config layout + vendor dots tree
test ! -L "$HOME/.config/quickshell"
test -d "$HOME/.config/quickshell"
test -f "$HOME/.config/quickshell/ii/shell.qml"
# Must NOT resolve into the repo product tree:
case "$(readlink -f "$HOME/.config/quickshell")" in
  */.dotfiles/.config/quickshell|*/.dotfiles/.config/quickshell/*)
    echo "[FAIL] still under .dotfiles product path"; exit 1 ;;
esac
# Optional: not a symlink and contains ii config name
qs -c ii --help >/dev/null 2>&1 || true  # binary still works
```

### LIVE-02 assert (conf content + live match)

```bash
REPO_ROOT="$(git rev-parse --show-toplevel)"
grep -E '^\s*env\s*=\s*ILLOGICAL_IMPULSE_VIRTUAL_ENV,' \
  "$REPO_ROOT/.config/hypr/hyprland.conf"
grep -E '^\s*exec-once\s*=\s*qs -c ii\b' \
  "$REPO_ROOT/.config/hypr/hyprland.conf"
# waybar line still present
grep -E '^\s*exec-once\s*=\s*waybar' \
  "$REPO_ROOT/.config/hypr/hyprland.conf"
cmp -s "$REPO_ROOT/.config/hypr/hyprland.conf" \
  "$HOME/.config/hypr/hyprland.conf"
```

### LIVE-03 assert (dual-run processes)

```bash
pgrep -x waybar >/dev/null
pgrep -x swaync >/dev/null || pgrep -a swaync >/dev/null
# waybar layer still present (optional)
hyprctl layers | grep -q waybar
```

### LIVE-04 assert (qs + env + operator chrome)

```bash
# (1) qs with config ii
pgrep -a qs | grep -E 'qs.*-c ii|quickshell' 
# Stronger: inspect cmdline
tr '\0' ' ' < /proc/$(pgrep -n -x qs)/cmdline; echo
# (2) env on qs process (mid-session standard)
tr '\0' '\n' < /proc/$(pgrep -n -x qs)/environ \
  | grep -qx 'ILLOGICAL_IMPULSE_VIRTUAL_ENV=.*/.local/state/quickshell/.venv\|ILLOGICAL_IMPULSE_VIRTUAL_ENV=.*/.local/state/quickshell/.venv'
# Also accept exact:
# ILLOGICAL_IMPULSE_VIRTUAL_ENV=/home/pera/.local/state/quickshell/.venv
# (3) Operator visual: Material/ii bar or shell chrome visible (manual)
test -d "$HOME/.local/state/quickshell/.venv"  # setups created venv
```

### Pre-install qs stop (discretion)

```bash
# Prefer exact names; ignore if not running (warn optional)
if pgrep -x qs >/dev/null || pgrep -x quickshell >/dev/null; then
  echo "[CONFIG] stopping running Quickshell"
  pkill -x qs 2>/dev/null || true
  pkill -x quickshell 2>/dev/null || true
  sleep 0.5
else
  echo "[SKIP] no qs/quickshell process"
fi
pgrep -x qs && { echo "[FAIL] qs still running"; exit 1; } || true
```

## State of the Art

| Old Approach (v0.1) | Current Approach (v0.2 Phase 7) | When Changed | Impact |
|---------------------|----------------------------------|--------------|--------|
| `~/.config/quickshell` → symlink into repo | Real directory from setup rsync | Phase 7 | LIVE-01; edit loop becomes fork → install-files |
| Manual/local QS product | Upstream `ii` tree under `~/.config/quickshell/ii` | Phase 7 | `qs -c ii` not bare `qs` |
| No `ILLOGICAL_IMPULSE_VIRTUAL_ENV` | Hypr `env =` + setups venv | Phase 7 | Required for ii python scripts |
| Phase 6 dry-run only | Live `install` mutates machine | Phase 7 | First real deps/setups/files |

**Deprecated/outdated for this phase:**
- `arch/quickshell.sh` as install path (still present; do not run)
- Relying on ii `hyprland/env.lua` while using `--skip-hyprland` (env must be personal)

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `hyprctl reload` does **not** re-apply `env =` into the running Hyprland process environment | Pattern 4 / Pitfall 4 | LIVE-04 (2) checks against Hyprland environ fail after reload-only; mid-session needs env-prefixed qs launch or re-login |
| A2 | Plain `rm` on a symlink never deletes the target directory | Pattern 1 | If tool/alias differs, could harm repo — verify with `ls -ld` before/after |
| A3 | Overlapping bars are acceptable operator UX for LIVE-03/04 | Dual-run policy | Operator may still want partial layout tweaks (out of scope) |
| A4 | One-shot install will succeed on this host once network/AUR/python3.12 available via setup | Pitfall 7 | May need staged re-runs or manual dep fix before LIVE green |

**If this table is empty:** N/A — assumptions listed above need planner awareness (A1 especially for D-17).

## Open Questions

1. **Does LIVE-04 (2) require compositor-level env or qs-process env?**
   - What we know: D-16 says “set in the Hyprland session”; mid-session reload cannot set compositor env (A1).
   - What's unclear: Whether operator re-login is required before phase sign-off.
   - Recommendation: Pass LIVE-04 mid-session if **qs process** has the env and chrome is visible; note in UAT that full session inheritance is verified on next Hyprland start (optional extra check). Prefer not blocking on re-login given D-17.

2. **Upstream backup prompt non-interactive policy**
   - What we know: Wrapper gate is `yes`; upstream may still interactively ask.
   - What's unclear: Whether plans should pipe answers for upstream backup.
   - Recommendation: Keep interactive for first adoption; document expected `y`. Do not pass `--skip-backup`.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `arch/dots-hyprland.sh` | install sequence | ✓ | Phase 6 | — |
| `vendor/dots-hyprland/setup` | install | ✓ | pin present | `git submodule update --init --recursive` |
| Nested shapes | ii QML | ✓ | LICENSE present | re-init recursive |
| `qs` | LIVE-04 | ✓ | 0.3.0 | setup install-deps may refresh |
| Hyprland + `hyprctl` | session hooks | ✓ | 0.56.0 | — |
| `yay` | install-deps | ✓ | 13.0.1 | — |
| Network (AUR/build) | install-deps | assumed ✓ | — | Fix network; re-run (D-08) |
| `uv` | setups venv | ✓ | 0.9.25 | setup can install via install-uv |
| `python3.12` | uv venv -p 3.12 | ✗ (not on PATH now) | — | **Must be installed by setup deps** (or uv fetch); re-run if setups fail |
| `~/.local/state/quickshell/.venv` | ii scripts | ✗ absent | — | Created by install-setups |
| `~/ii-original-dots-backup` | upstream backup | ✗ absent | — | Created if operator accepts backup prompt |
| Live QS symlink | pre-install hazard | ✓ present | → `.dotfiles/...` | Unlink in 07-01 |

**Missing dependencies with no fallback:**
- Network/AUR access during live install (blocking if offline)

**Missing dependencies with fallback:**
- `python3.12` — setup/uv expected to provision; if fails, operator installs `python312` package then re-runs wrapper
- `.venv` — created by setups on success

## Validation Architecture

> `workflow.nyquist_validation` is **true** in `.planning/config.json` — section required.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | None — inline bash smoke asserts (Phase 5/6 style) |
| Config file | none |
| Quick run command | `bash -n arch/dots-hyprland.sh && test ! -L "$HOME/.config/quickshell" 2>/dev/null; true` |
| Full suite command | LIVE-01..04 assert block (below) + conf greps |
| Estimated runtime | Automated portion ~5–15s; live install itself minutes–tens of minutes |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| LIVE-01 | Real dir not symlink; ii tree present | smoke | `test ! -L ~/.config/quickshell && test -d ~/.config/quickshell && test -f ~/.config/quickshell/ii/shell.qml` | ❌ Wave 0 (post-install only) |
| LIVE-01 | Not pointing at repo product | smoke | `case $(readlink -f ~/.config/quickshell) in */.dotfiles/.config/quickshell*) exit 1;; esac` | ❌ Wave 0 |
| LIVE-02 | Repo conf has env + exec-once | smoke | `grep -E 'env = ILLOGICAL_IMPULSE_VIRTUAL_ENV,' .config/hypr/hyprland.conf && grep -E 'exec-once = qs -c ii' .config/hypr/hyprland.conf` | ❌ Wave 0 (after edit) |
| LIVE-02 | Live conf matches repo | smoke | `cmp -s .config/hypr/hyprland.conf ~/.config/hypr/hyprland.conf` | ❌ Wave 0 |
| LIVE-03 | waybar still running | smoke | `pgrep -x waybar` | ❌ Wave 0 |
| LIVE-03 | waybar exec-once not removed | smoke | `grep -E 'exec-once = waybar' .config/hypr/hyprland.conf` | ❌ Wave 0 |
| LIVE-04 | qs process with ii | smoke | `pgrep -a qs \| grep -E -- '-c ii\|\bii\b'` | ❌ Wave 0 |
| LIVE-04 | env on qs process | smoke | `tr '\0' '\n' < /proc/$(pgrep -n -x qs)/environ \| grep ILLOGICAL_IMPULSE_VIRTUAL_ENV` | ❌ Wave 0 |
| LIVE-04 | Visible ii chrome | manual | Operator confirms bar/shell chrome on screen | N/A |
| D-06 | Dry-run shows safe defaults | smoke | `printf 'yes\n' \| ./arch/dots-hyprland.sh install --dry-run \| tee /tmp/p7-dry.txt; grep -q -- '--core' /tmp/p7-dry.txt; grep -q -- '--skip-hyprland' /tmp/p7-dry.txt; grep -q -- '--skip-sysupdate' /tmp/p7-dry.txt` | ✅ wrapper exists |
| D-01 | Symlink gone pre-files | smoke | After 07-01: `test ! -e ~/.config/quickshell \|\| test ! -L ~/.config/quickshell` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** Relevant smoke asserts that do not require live install mutation (conf greps, dry-run, bash -n)
- **Per wave merge:** Full LIVE-01..03 automated asserts once install has run; LIVE-04 process asserts
- **Phase gate:** All LIVE automated asserts green + operator LIVE-04 chrome confirmation before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] No dedicated `scripts/phase07-live-smoke.sh` — **optional**; plans may embed asserts inline (preferred, Phase 6 style)
- [ ] LIVE-* asserts only become meaningful **after** 07-01/07-02 mutate the machine — Wave 0 is “commands documented,” not pre-existing green CI
- [ ] Framework install: none
- [ ] Manual UAT checklist for LIVE-04 visual chrome (operator)

*(Existing infrastructure: bash, hyprctl, pgrep — sufficient. No pytest/jest.)*

### Recommended plan-level verify snippets

**07-01 (pre-install):**
```bash
pgrep -x qs && exit 1 || true
test ! -L "$HOME/.config/quickshell"
# path preferably absent:
test ! -e "$HOME/.config/quickshell"
# repo product still intact:
test -d "$(git rev-parse --show-toplevel)/.config/quickshell" || true  # may exist as product tree
```

**07-02 (install):**
```bash
# dry-run first (above)
# after live install:
test ! -L "$HOME/.config/quickshell" && test -f "$HOME/.config/quickshell/ii/shell.qml"
test -d "$HOME/.local/state/quickshell/.venv"
# hypr conf NOT renamed:
test -f "$HOME/.config/hypr/hyprland.conf"
test ! -f "$HOME/.config/hypr/hyprland.conf.old"  # soft assert — warn if present
```

**07-03 (hooks + dual-run):**
```bash
# conf greps + cmp (LIVE-02)
# pgrep waybar + qs (LIVE-03/04)
# env on qs (LIVE-04)
# checkpoint:human-verify visible chrome
```

## Security Domain

> `security_enforcement` enabled (ASVS L1).

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | Desktop session, not app auth |
| V4 Access Control | partial | sudo/yay for package install — operator interactive only |
| V5 Input Validation | yes | Wrapper allowlist + array exec (Phase 6); no `eval` of flags |
| V6 Cryptography | no | — |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| rsync through symlink into git tree | Tampering | Unlink before files; assert `! -L` |
| Accidental hypr conf rename | Tampering | `--skip-hyprland` injected; never entry-only |
| Accidental `--skip-backup` | Tampering / data loss | Wrapper refuse without `--allow-skip-backup`; D-02 |
| Unexpected setup subcommand (uninstall) | Elevation | Wrapper allowlist only WRAP-01 four |
| Command injection via flags | Tampering | Array exec in wrapper (no eval) |
| Re-run old symlink installer | Tampering | Do not run `arch/quickshell.sh`; Phase 8 retire |
| Privilege via yay/sudo install | Elevation | Interactive operator; no unattended `--force` injection |

## Sources

### Primary (HIGH confidence)

- `arch/dots-hyprland.sh` — dry-run argv, backup gate, safe defaults [VERIFIED: executed 2026-07-26]
- `vendor/dots-hyprland/sdata/subcmd-install/3.files-legacy.sh` — `install_dir__sync` quickshell; `--skip-hyprland` behavior [VERIFIED: read]
- `vendor/dots-hyprland/sdata/subcmd-install/3.files.sh` — backup, hyprctl reload, ILLOGICAL env warning [VERIFIED: read]
- `vendor/dots-hyprland/sdata/subcmd-install/options.sh` — `--core` expands to skip plasma/fish/font/misc [VERIFIED: read]
- `vendor/dots-hyprland/sdata/uv/README.md` — default venv path + hypr env note [VERIFIED: read]
- `vendor/dots-hyprland/sdata/lib/package-installers.sh` — uv venv at `$XDG_STATE_HOME/quickshell/.venv`, python 3.12 [VERIFIED: read]
- `vendor/dots-hyprland/dots/.config/hypr/hyprland/env.lua` — upstream sets `…/.local/state/quickshell/.venv` [VERIFIED: read]
- Live probes: symlink target, qs 0.3.0, Hyprland 0.56.0, waybar pid, no .venv yet, live hypr matches repo [VERIFIED: 2026-07-26]
- `.planning/phases/07-…/07-CONTEXT.md` — locked D-01…D-17
- `.planning/phases/06-…/06-CONTEXT.md` + wrapper implementation
- `.planning/research/{SUMMARY,ARCHITECTURE,PITFALLS,STACK}.md`

### Secondary (MEDIUM confidence)

- WebSearch on Hyprland `env=` vs `hyprctl reload` — reload does not re-export env [ASSUMED/MEDIUM: not from official wiki fetch success; aligns with upstream “restart needed” string]

### Tertiary (LOW confidence)

- Exact AUR package set and install duration on this machine (depends on mirror/cache)

## Metadata

**Confidence breakdown:**
- Standard stack: **HIGH** — wrapper + setup + live tools verified on machine
- Architecture: **HIGH** — install path and hypr coexistence verified in vendor sources
- Pitfalls: **HIGH** for symlink/rsync and skip-hyprland; **MEDIUM** for mid-session env apply
- LIVE verify commands: **HIGH** for filesystem/process; **MEDIUM** for compositor env semantics

**Research date:** 2026-07-26  
**Valid until:** 2026-08-25 (30 days; pin/setup flags stable; re-probe live symlink state if machine changes)
