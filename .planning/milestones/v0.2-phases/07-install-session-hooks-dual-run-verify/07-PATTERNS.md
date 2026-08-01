# Phase 7: Install, Session Hooks & Dual-Run Verify - Pattern Map

**Mapped:** 2026-07-27  
**Files analyzed:** 6 primary touch points (1 repo source edit + host state + wrapper use + plan/verify surfaces)  
**Analogs found:** 5 / 6 (1 host-only path uses RESEARCH + inverted anti-pattern)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.config/hypr/hyprland.conf` | config | event-driven (session autostart / env at Hyprland start) | same file (existing `exec-once` + `env =` blocks) | exact |
| Live `~/.config/hypr/hyprland.conf` (sync target) | config deploy | file-I/O (single-file copy) | `arch/hyprland.sh` (bulk) **or** `arch/waybar.sh` `sync_file` (prefer single-file) | role-match |
| Live `~/.config/quickshell` (unlink → real dir via setup) | host state / install target | file-I/O (symlink break + upstream rsync) | **Anti:** `arch/quickshell.sh` `symlink_config`; **SoT:** vendor `install_dir__sync` | partial (invert anti-pattern) |
| `arch/dots-hyprland.sh` | utility (use only — **do not rewrite**) | request-response (CLI → setup) | self (Phase 6 complete) | exact (invoke, not edit) |
| Plan tasks / UAT smoke asserts (inline bash; no new script required) | test | batch (smoke asserts) | `06-03-PLAN.md` verify blocks + `arch/quickshell.sh` `verify_install` | role-match |
| `arch/quickshell.sh` | utility | file-I/O | — | **anti-pattern** — do not re-run |

**Not in scope as source edits:** `arch/dots-hyprland.sh` body, `vendor/dots-hyprland/*`, in-repo `.config/quickshell/` product tree (Phase 8), wrapper `verify` subcommand.

**Plan skeleton (roadmap):** 07-01 pre-install symlink, 07-02 wrapper install, 07-03 hypr hooks + dual-run verify — mirror Phase 6 plan YAML + task/verify shape.

---

## Pattern Assignments

### `.config/hypr/hyprland.conf` (config, event-driven)

**Analog:** Same file — personal Hyprland SoT (no `source =` includes today; D-10 inline only).

**Placement pattern — AUTOSTART / CORE UTILS** (lines 45–64):

```45:64:.config/hypr/hyprland.conf
### AUTOSTART ###
#################

# Autostart necessary processes (like notifications daemons, status bars, etc.)
# Or execute your favorite apps at launch like this:

# exec-once = $terminal
# exec-once = nm-applet &
# exec-once = waybar & hyprpaper & firefox

# INFO: SCREEN-SHARE FIX
# Bootstrap graphical-session.target so xdg-desktop-portal (ScreenCast) can start
exec-once = systemctl --user start hyprland-session.service

# INFO: KEYRING SETUP
# Authentication Agent (Crucial for GUI apps that need sudo/root)
exec-once = /usr/lib/polkit-kde-authentication-agent-1 

# INFO: CORE UTILS
exec-once = waybar & swaync & hyprpaper &
```

**Copy for LIVE-02 / D-13 / D-15:** Keep the waybar line **unchanged**. Immediately after it, add:

```conf
# Live ii shell (dual-run with waybar) — Phase 7 LIVE-02
exec-once = qs -c ii
```

**Env pattern — ENVIRONMENT VARIABLES** (lines 98–105):

```98:105:.config/hypr/hyprland.conf
#############################
### ENVIRONMENT VARIABLES ###
#############################

# See https://wiki.hyprland.org/Configuring/Environment-variables/
exec-once = hyprctl setcursor catppuccin-mocha-dark-cursors 30
env = XCURSOR_THEME,Catppuccin-Mocha-Dark-Cursors
env = XCURSOR_SIZE,30
```

**Copy for D-12 (match comma style — no space after comma):**

```conf
# illogical-impulse (Phase 7 LIVE-02) — required when --skip-hyprland skips ii env.lua
env = ILLOGICAL_IMPULSE_VIRTUAL_ENV,~/.local/state/quickshell/.venv
```

**Do not:** remove waybar; add `source =` snippet files; install ii `hyprland.lua` / full hypr tree (D-09).

**Secondary reference (upstream default path text only):** `vendor/dots-hyprland/sdata/subcmd-install/3.files.sh` ~256–257 warns that `$ILLOGICAL_IMPULSE_VIRTUAL_ENV` default is `~/.local/state/quickshell/.venv` and that **a restart is needed** for compositor-level apply — informs mid-session Pattern 4 (env-prefix qs), not a conf format to copy.

---

### Live `~/.config/hypr/hyprland.conf` sync (config deploy, file-I/O)

**Preferred analog (single-file, light):** RESEARCH Pattern 3 + discretion — do **not** default to full `arch/hyprland.sh` (packages + swaync + recursive hypr).

```bash
# After D-11 commit to repo path:
cp -f .config/hypr/hyprland.conf "$HOME/.config/hypr/hyprland.conf"
cmp -s .config/hypr/hyprland.conf "$HOME/.config/hypr/hyprland.conf"
```

**Heavier analog (avoid for Phase 7 default):** `arch/hyprland.sh` lines 19–21:

```19:21:arch/hyprland.sh
echo "[CONFIG] Hyprland config"
mkdir -p ~/.config/hypr
cp -rf .config/hypr/* ~/.config/hypr/
```

**Structured single-file analog:** `arch/waybar.sh` `sync_managed_files` / `verify_file_presence` (install -Dm + `[[ -f ]]` loop) — same “deploy then assert presence” idea if plans want labeled echos:

```104:133:arch/waybar.sh
sync_managed_files() {
  local rel

  echo "[CONFIG] sync managed waybar files"
  for rel in "${MANAGED_FILES[@]}"; do
    sync_file "$rel"
  done
}
...
verify_file_presence() {
  ...
  echo "[VERIFY] deployed files exist"
  for rel in "${MANAGED_FILES[@]}"; do
    [[ -f "$WAYBAR_DST/$rel" ]]
  done
```

**Phase 7 adaptation:** one `cp -f` + `cmp -s` is enough; labeled `[CONFIG]` / `[VERIFY]` optional for plan task text.

---

### Live `~/.config/quickshell` pre-install break (host state, file-I/O)

**Anti-pattern source (do the opposite of re-run):** `arch/quickshell.sh` `symlink_config`:

```36:41:arch/quickshell.sh
symlink_config() {
  echo "[CONFIG] symlink $QS_DST -> $QS_SRC"
  mkdir -p "$(dirname "$QS_DST")"
  rm -rf "$QS_DST"
  ln -s "$QS_SRC" "$QS_DST"
}
```

**Why anti:** `rm -rf` on a symlink path + `ln -s` recreates LIVE-01 failure mode. Phase 7 must **never** call this script after unlink.

**Correct pre-install sequence** (07-RESEARCH Pattern 1 + Code Examples — copy into 07-01 plan tasks):

```bash
# Stop qs first (D-03)
if pgrep -x qs >/dev/null || pgrep -x quickshell >/dev/null; then
  echo "[CONFIG] stopping running Quickshell"
  pkill -x qs 2>/dev/null || true
  pkill -x quickshell 2>/dev/null || true
  sleep 0.5
else
  echo "[SKIP] no qs/quickshell process"
fi
pgrep -x qs && { echo "[FAIL] qs still running"; exit 1; } || true

# Unlink only (D-01) — plain rm, never rm -rf
if [ -L "$HOME/.config/quickshell" ]; then
  echo "[CONFIG] removing QS symlink (repo target preserved)"
  rm "$HOME/.config/quickshell"
elif [ -e "$HOME/.config/quickshell" ]; then
  echo "[WARN] path exists and is not a symlink: $(ls -ld "$HOME/.config/quickshell")"
fi
test ! -L "$HOME/.config/quickshell"
# Preferred first-run: path absent so setup creates real dir
test ! -e "$HOME/.config/quickshell"
# Repo product untouched:
test -d "$(git rev-parse --show-toplevel)/.config/quickshell"
```

**Post-install SoT (read-only understanding):** vendor legacy files path installs quickshell via `install_dir__sync`:

```26:26:vendor/dots-hyprland/sdata/subcmd-install/3.files-legacy.sh
    install_dir__sync dots/.config/quickshell "$XDG_CONFIG_HOME"/quickshell
```

Plans **must not** reimplement rsync; they only order unlink → wrapper install.

**Inverted verify** (from quickshell `verify_install` which required `test -L`):

```78:85:arch/quickshell.sh
verify_install() {
  echo "[VERIFY] checking install state"
  command -v quickshell >/dev/null || { echo "[VERIFY] FAIL: quickshell not in PATH"; exit 1; }
  ...
  test -L "$QS_DST"                 || { echo "[VERIFY] FAIL: $QS_DST is not a symlink"; exit 1; }
  test -f "$QS_DST/shell.qml"       || { echo "[VERIFY] FAIL: $QS_DST/shell.qml not reachable through symlink"; exit 1; }
```

**Phase 7 LIVE-01 assert (invert symlink requirement):**

```bash
echo "[VERIFY] LIVE-01 real installed tree"
test ! -L "$HOME/.config/quickshell"
test -d "$HOME/.config/quickshell"
test -f "$HOME/.config/quickshell/ii/shell.qml"
case "$(readlink -f "$HOME/.config/quickshell")" in
  */.dotfiles/.config/quickshell|*/.dotfiles/.config/quickshell/*)
    echo "[FAIL] still under .dotfiles product path"; exit 1 ;;
esac
echo "[VERIFY] OK LIVE-01"
```

---

### `arch/dots-hyprland.sh` (utility — **invoke only**, request-response)

**Analog:** The file itself (Phase 6 deliverable). Plans copy **invocation + assert** patterns from wrapper + `06-03-PLAN.md`, not new shell code.

**Safe defaults constant** (lines 8–12):

```8:12:arch/dots-hyprland.sh
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
II_ROOT="$REPO_ROOT/vendor/dots-hyprland"
SETUP="$II_ROOT/setup"
SAFE_DEFAULTS=(--core --skip-hyprland --skip-sysupdate)
ALLOWLIST=(install install-deps install-setups install-files)
```

**Backup gate** (lines 90–101) — D-02: rely on this; do **not** add extra tarball step; do **not** encourage `--skip-backup`:

```90:101:arch/dots-hyprland.sh
backup_gate() {
  echo "[CONFIG] Upstream may backup clashing paths to: ~/ii-original-dots-backup"
  echo "[CONFIG] install-files will overwrite ~/.config/quickshell (Quickshell tree / rsync --delete)."
  echo "[CONFIG] Defaults include --skip-hyprland so personal hyprland.conf is not renamed."
  echo "[CONFIG] Do NOT pass --skip-backup on first adoption."
  local ans
  read -r -p "Type 'yes' to continue: " ans
  if [[ "$ans" != "yes" ]]; then
    echo "[FAIL] Aborted (backup gate). No ./setup invoked." >&2
    exit 1
  fi
}
```

**Dry-run then live sequence** (D-05, D-06) — copy from wrapper dry-run path + Phase 6 plan verifies:

```bash
# 07-02 Task: dry-run first (gate still needs yes)
out=$(printf 'yes\n' | ./arch/dots-hyprland.sh install --dry-run 2>&1)
echo "$out" | tee /tmp/p7-dry.txt
echo "$out" | grep -q -- '--core'
echo "$out" | grep -q -- '--skip-hyprland'
echo "$out" | grep -q -- '--skip-sysupdate'
echo "$out" | grep -q 'dry-run: would exec'
# Expected: ./setup install --core --skip-hyprland --skip-sysupdate

# Live one-shot (interactive: type yes at wrapper; prefer y at upstream backup)
./arch/dots-hyprland.sh install
```

**Dry-run implementation excerpt** (lines 198–204):

```198:204:arch/dots-hyprland.sh
  echo "[INSTALL] ${cmd[*]}  (cwd=$II_ROOT)"

  # 8) --dry-run: print would-exec, exit 0 without calling setup (D-16)
  if ((dry_run)); then
    echo "[CONFIG] dry-run: would exec from $II_ROOT: ${cmd[*]}"
    exit 0
  fi
```

**Plan-structure analog for 07-02:** `06-02-PLAN.md` / `06-03-PLAN.md` — frontmatter (`phase`, `plan`, `wave`, `depends_on`, `files_modified`, `must_haves`, `prohibitions`), `<task>` with `<read_first>`, `<action>`, `<verify><automated>…`, `<acceptance_criteria>`.

**Key prohibitions to carry into 07-02 plans:**
- Do not bypass wrapper with raw `./setup` for first adoption
- Do not live-run without dry-run-first in the same phase plan sequence
- Do not inject/encourage `--force` / `--skip-backup` / entry-only skip
- On failure: fix cause + re-run wrapper (D-08) — no rollback script

---

### Plan / UAT smoke asserts (test, batch)

**Primary analog:** Phase 6 plan verify blocks (inline bash, no dedicated smoke script by default).

Example shape from `06-03-PLAN.md` (composable `&&` suite + `/tmp` tee greps):

```text
printf 'yes\n' | ./arch/dots-hyprland.sh install --dry-run | tee /tmp/….txt | grep -q -- '--core'
```

**Secondary analog:** labeled `[VERIFY]` functions in `arch/quickshell.sh` / `arch/waybar.sh` / `arch/system_monitor.sh`.

**LIVE assert blocks to embed (from 07-RESEARCH — prefer inline in plans, not new `scripts/phase07-*.sh`):**

| Req | Assert pattern |
|-----|----------------|
| LIVE-01 | `! -L` + `-d` + `ii/shell.qml` + readlink not under `.dotfiles/.config/quickshell` |
| LIVE-02 | `grep` env + `exec-once = qs -c ii` + waybar still grepped + `cmp -s` repo↔live |
| LIVE-03 | `pgrep -x waybar`; optional swaync; waybar exec-once still in conf |
| LIVE-04 | qs cmdline has `-c ii`; qs `/proc/.../environ` has `ILLOGICAL_IMPULSE_VIRTUAL_ENV`; operator visual chrome; optional `.venv` dir |

**Mid-session apply (D-17)** — copy RESEARCH Pattern 4:

```bash
hyprctl reload
hyprctl configerrors
pkill -x qs 2>/dev/null || true
ILLOGICAL_IMPULSE_VIRTUAL_ENV="${HOME}/.local/state/quickshell/.venv" \
  qs -c ii -d
# LIVE-04 (2): inspect qs environ, not Hyprland environ after reload-only
```

**UAT double-prompt wording (Pitfall 2):** “Type `yes` at wrapper gate; prefer `y` at upstream backup to `~/ii-original-dots-backup`.”

---

### Plan document structure (meta — for 07-01…07-03)

**Analog:** `.planning/phases/06-thin-setup-wrapper-safe-defaults/06-01-PLAN.md` (and 06-02, 06-03).

Copy:
- YAML frontmatter: `phase`, `plan`, `type: execute`, `wave`, `depends_on`, `files_modified`, `autonomous`, `requirements`, `must_haves.truths/artifacts/key_links`, **`prohibitions`**
- `<objective>`, `<context>` `@` refs including `07-CONTEXT.md`, `07-RESEARCH.md`, `07-PATTERNS.md`
- Tasks with explicit **do not** lines (e.g. do not run `arch/quickshell.sh`; do not edit vendor; do not retire in-repo quickshell)
- `<verify><automated>` smoke where safe; live install plan should mark operator interaction (`user_setup` / non-autonomous) where gate + yay/sudo needed

**Suggested wave split (roadmap):**
| Plan | Wave | Mutates machine? | Primary files / host |
|------|------|------------------|----------------------|
| 07-01 | 1 | yes (qs stop + unlink) | `~/.config/quickshell` symlink only |
| 07-02 | 2 | yes (deps/setups/files) | wrapper → setup; assert LIVE-01 partial |
| 07-03 | 3 | yes (conf + reload + qs) | `.config/hypr/hyprland.conf` + live sync + LIVE-02..04 |

---

## Shared Patterns

### Labeled echo vocabulary

**Source:** `arch/quickshell.sh`, `arch/dots-hyprland.sh`, CONVENTIONS  
**Apply to:** All Phase 7 operator/plan shell steps

| Label | Use in Phase 7 |
|-------|----------------|
| `[CONFIG]` | stop qs, unlink symlink, conf hooks, live cp, mid-session env note |
| `[INSTALL]` | wrapper live install line (wrapper already logs this) |
| `[VERIFY]` | LIVE-01..04 automated asserts |
| `[FAIL]` | hard stop (qs still running, still symlink, still under .dotfiles) |
| `[SKIP]` | qs not running (optional warn) |
| `[WARN]` | path exists but not symlink; `hyprland.conf.old` present |
| `[DONE]` | phase plan completion summary |

### Wrapper safe-defaults + backup gate (do not re-open)

**Source:** `arch/dots-hyprland.sh` (`SAFE_DEFAULTS`, `backup_gate`, meta-flag strip)  
**Apply to:** 07-02 only as **caller**  
**Locked from Phase 6:** `--core --skip-hyprland --skip-sysupdate`; full skip-hyprland not entry-only; no auto `--force` / `--skip-backup`.

### Dual-run session policy

**Source:** personal conf waybar exec-once + D-15  
**Apply to:** 07-03 conf edit + LIVE-03  
**Rule:** Additive `qs -c ii` only; overlap OK; Waybar remains primary chrome.

### Error / recovery

**Source:** CONTEXT D-08  
**Apply to:** 07-02 live install  
**Rule:** No automated rollback; fix cause; re-run `./arch/dots-hyprland.sh install` (dry-run again if flags uncertain).

### Anti-patterns (shared denylist)

| Anti-pattern | Analog / reason |
|--------------|-----------------|
| `arch/quickshell.sh` after unlink | Re-symlinks; undoes LIVE-01 |
| `rm -rf ~/.config/quickshell` while symlink | Risk to repo tree; use plain `rm` on link |
| Raw `./setup` without wrapper defaults | May rename `hyprland.conf` → `.old` |
| `--skip-backup` on first adoption | D-02; wrapper refuses without `--allow-skip-backup` |
| Delete in-repo `.config/quickshell` | Phase 8 only (D-04) |
| Assume `hyprctl reload` sets compositor `env =` | A1; mid-session prefix env on qs |
| Full `bash arch/hyprland.sh` as only sync | Heavier than needed; packages/swaync side effects |

---

## No Analog Found

| File / concern | Role | Data Flow | Reason |
|----------------|------|-----------|--------|
| Compositor-level `env =` mid-session apply | session | event-driven | No in-repo helper re-exports Hyprland environ; use RESEARCH A1 + env-prefixed `qs` (partial analog: upstream warning string in `3.files.sh`) |
| Automated rollback from `~/ii-original-dots-backup` | utility | file-I/O | Explicitly out of scope; re-run only |
| Wrapper `verify` subcommand | CLI | request-response | POLISH-01 deferred; inline asserts only |

---

## Metadata

**Analog search scope:** `arch/*.sh`, `.config/hypr/hyprland.conf`, `.planning/phases/06-*`, `vendor/dots-hyprland/sdata/subcmd-install/*`, phase 07 CONTEXT/RESEARCH  
**Files scanned:** ~15 primary (wrapper, quickshell, hyprland.sh, waybar, hypr conf, 06 plans/patterns, vendor files/options snippets)  
**Pattern extraction date:** 2026-07-27  
**Planner note:** Prefer concrete excerpts above + 07-RESEARCH Code Examples; do not invent new installers or package lists.
