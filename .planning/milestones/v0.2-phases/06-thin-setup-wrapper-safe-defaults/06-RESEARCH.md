# Phase 6: Thin Setup Wrapper & Safe Defaults - Research

**Researched:** 2026-07-25  
**Domain:** Bash thin wrapper around vendored `dots-hyprland/./setup` (safe defaults + backup gate)  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### CLI surface & invocation
- **D-01:** Script path/name is **`arch/dots-hyprland.sh`**. Invocation uses **subcommands that mirror** upstream `./setup`:  
  `arch/dots-hyprland.sh install|install-deps|install-setups|install-files [flags…]`
- **D-02:** Bare invocation (no args) prints **wrapper help** and **exits 0**. Never calls `./setup` with empty args.
- **D-03:** Local help surface: **`help` / `-h` / `--help`** on the wrapper documents safe defaults, backup gate, allowlist, and examples. Subcommand help (e.g. `install -h`) is **passed through** to `./setup`.
- **D-04:** **Allowlist only the WRAP-01 four** subcommands. Refuse `uninstall`, `exp-update`, `exp-merge`, `virtmon`, `checkdeps`, `resetfirstrun`, etc. with a clear error pointing at upstream `./setup` if the operator truly needs them.

#### Safe-default flag injection
- **D-05:** Safe defaults apply to **`install` and `install-files` only**. `install-deps` and `install-setups` do **not** get file-protection defaults injected.
- **D-06:** Default profile for those two subcommands: **`--core --skip-hyprland --skip-sysupdate`** (`-s`). Rationale: dual-run / protect personal hypr; skip unattended full `pacman -Syu` (matches `arch/*.sh` habit).
- **D-07:** **Never** auto-inject `-f` / `--force` or `--skip-allgreeting`. Operator must pass them intentionally if ever needed.
- **D-08:** **Never** use `--skip-hyprland-entry` as the protection default. Research: entry-only skip still renames `hyprland.conf`. Protection is **full `--skip-hyprland`**.
- **D-09:** **Passthrough merge, no auto-strip, no required `--raw` escape hatch.** Argv order:  
  `./setup <subcommand> <safe defaults…> <user flags…>`  
  User flags append after defaults (WRAP-04). Duplicates are OK if the user also passed the same long flag.
- **D-10:** Before exec, **log injected defaults and the full argv** with labeled echos (e.g. `[CONFIG] safe defaults: …` then the concrete command).

#### Backup gate strictness
- **D-11:** **Hard interactive gate** before **`install` and `install-files`** only. Operator must confirm (e.g. type `yes` / press Enter per implementation) after the reminder. No gate on `install-deps` / `install-setups`.
- **D-12:** If the user passes **`--skip-backup`**, **refuse** unless they also pass an explicit override flag **`--allow-skip-backup`**. Never encourage skip on first adoption; never silently strip the flag.
- **D-13:** Gate messaging must cover: upstream backup location (e.g. `~/ii-original-dots-backup` or current upstream wording), that **Quickshell config will be overwritten**, and that **defaults keep personal `hyprland.conf` via `--skip-hyprland`**.

#### Preflight & smoke-test scope
- **D-14:** Preflight before any `./setup` call: **`vendor/dots-hyprland` has `.git` (submodule initialized)** and **`setup` is executable**. Fail with clear `[FAIL]` messages.
- **D-15:** **Never auto-fix** missing submodule/setup. Print fix commands only, e.g. `git submodule update --init --recursive` (stock git; Phase 5 D-15 philosophy).
- **D-16:** Phase 6 smoke tests are **help + dry path only** — no live `install` / `install-deps` / `install-files` that mutate the machine. Cover: wrapper help; unknown subcommand refusal; preflight failure path (if testable); optional `./setup -h` via wrapper; planned argv logging without install.
- **D-17:** **No `verify` subcommand** in Phase 6. Lightweight preflight only; post-install LIVE checks are Phase 7; POLISH-01 stays future.

### Claude's Discretion
- Exact confirm prompt wording / yes-token for the hard gate (as long as D-11–D-13 hold)
- Exact `[LABEL]` vocabulary beyond existing arch conventions (`[INSTALL]`, `[CONFIG]`, `[FAIL]`, `[DONE]`, etc.)
- Whether help text is a here-doc or functions; structured `main()` dispatcher shape (prefer structured generation like `arch/quickshell.sh` / research sketch)
- How to detect TTY if later needed (hard gate is always interactive for Phase 6; non-interactive policy not required unless user later asks)
- Smoke test implementation form (shell assertions in a plan task vs ad-hoc commands in SUMMARY)

### Deferred Ideas (OUT OF SCOPE)
- Live install + session hooks + dual-run verify — Phase 7
- Retire `.config/quickshell` product tree + `arch/quickshell.sh` — Phase 8
- Full clone/install/update playbook — Phase 9
- Wrapper `verify` subcommand (qs binary, config path, submodule SHA) — POLISH-01
- Allowing `exp-update` / `exp-merge` through the wrapper — out of scope; non-primary update path
- Non-interactive CI mode for hard backup gate — not decided; Phase 6 assumes interactive operator
- Nested shapes LICENSE preflight — declined for Phase 6 (OWN-03 already Phase 5); optional later polish
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| WRAP-01 | Operator can run thin `arch/dots-hyprland.sh` from REPO_ROOT that invokes upstream `./setup` for `install`, `install-deps`, `install-setups`, and `install-files` without reimplementing package lists | Allowlist dispatcher + `cd "$II_ROOT" && ./setup <subcmd> …`; zero package arrays / rsync reimplementation |
| WRAP-02 | Wrapper defaults to safe dual-run profile including `--core` and `--skip-hyprland` so personal `hyprland.conf` / hyprlock are not renamed or replaced on first adoption | Inject `--core --skip-hyprland --skip-sysupdate` for `install` + `install-files` only; never `--skip-hyprland-entry` as protection |
| WRAP-03 | Wrapper surfaces a backup gate or explicit reminder before the files step and does not encourage `--skip-backup` on first adoption | Hard interactive gate on `install`/`install-files`; refuse bare `--skip-backup` unless `--allow-skip-backup`; messaging names `~/ii-original-dots-backup` + QS overwrite + hypr protection |
| WRAP-04 | Wrapper accepts additional `./setup` flags via passthrough so operators can override defaults intentionally | Argv: `./setup <sub> <defaults…> <user flags…>`; strip only wrapper-owned meta flags (`--allow-skip-backup`, recommended `--dry-run`) |
</phase_requirements>

## Summary

Phase 6 delivers a **single new structured bash script** — `arch/dots-hyprland.sh` — that is a UX shell around the already-pinned submodule installer at `vendor/dots-hyprland/setup`. Upstream `./setup` remains the sole source of truth for deps, setups, and file copy. The wrapper’s job is: allowlist the four WRAP-01 subcommands, inject dual-run-safe flags for files-touching paths, force an interactive backup acknowledgment, refuse accidental `--skip-backup`, log the concrete argv, then exec `./setup`. [VERIFIED: vendor/dots-hyprland/setup + sdata/subcmd-install/options.sh + 3.files-legacy.sh 2026-07-25]

Live vendor CLI (pin present, setup executable) confirms: subcommands `install|install-deps|install-setups|install-files` share `sdata/subcmd-install/options.sh`; long flags include `--core`, `--skip-hyprland`, `--skip-hyprland-entry`, `--skip-backup`, `-s/--skip-sysupdate`; bare `./setup` / `help` / `-h` print global help and exit; unknown long options fail with `unrecognized option` (so **wrapper-owned flags must be stripped** before exec). Backup directory default is `$HOME/ii-original-dots-backup`. Hypr protection requires **full `--skip-hyprland`** — not entry-only. [VERIFIED: live `./setup` help + environment-variables.sh + 3.files-legacy.sh]

**Primary recommendation:** Implement a structured `main()` script (mirror `arch/quickshell.sh`) with allowlist + preflight + defaults injection + hard `yes` gate + optional wrapper-owned `--dry-run` for non-mutating smoke tests; never reimplement `sdata` package lists.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Operator CLI entrypoint | Host provisioning (`arch/dots-hyprland.sh`) | — | Matches existing `.dotfiles` `arch/*.sh` culture |
| Subcommand routing & flag parse | Upstream `vendor/dots-hyprland/./setup` | Wrapper only allowlists + injects | Setup owns getopt + step scripts |
| Safe dual-run flag defaults | Wrapper | Setup consumes flags | Wrapper UX policy; setup implements SKIP_* vars |
| Backup reminder / hard gate | Wrapper (before exec) | Upstream `auto_backup_configs` still runs unless `--skip-backup` | Wrapper gate is adoption safety; upstream backup is second layer |
| Package install / rsync files | Upstream setup only | — | WRAP-01 forbids reimplementation |
| Personal hypr ownership | Personal `.config/hypr` (unchanged this phase) | `--skip-hyprland` prevents rename | Phase 7 adds session hooks |
| Preflight submodule readiness | Wrapper | Phase 5 pin already materializes tree | Fail closed; never auto-init (D-15) |
| Smoke / dry verification | Plan-task shell asserts | Wrapper `--dry-run` (recommended) | D-16: no live machine mutation |

## Standard Stack

### Core

| Tool / artifact | Version (verified) | Purpose | Why Standard |
|-----------------|-------------------|---------|--------------|
| Bash | 5.3.15 | Wrapper language | Universal on Arch; matches all `arch/*.sh` [VERIFIED: `bash --version`] |
| `vendor/dots-hyprland/setup` | As pinned in parent (Phase 5) | Upstream installer SoT | WRAP-01 — do not reimplement [VERIFIED: executable at vendor path] |
| `sdata/subcmd-install/options.sh` | As pinned | Flag definitions / getopt | Authoritative flag surface [VERIFIED: read options.sh] |
| Git submodule layout | git 2.55.0 | `vendor/dots-hyprland/.git` presence | Preflight D-14 [VERIFIED: gitfile → `.git/modules/vendor/dots-hyprland`] |

### Supporting

| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| `getopt` (util-linux, via setup) | host | Setup parses flags after subcommand | Only inside setup — wrapper must not re-parse setup’s full option set |
| Labeled echos `[INSTALL]`/`[CONFIG]`/`[FAIL]`/`[DONE]` | n/a | Operator UX | All wrapper progress [VERIFIED: CONVENTIONS.md + D-14] |
| Wrapper-owned `--dry-run` (recommended) | n/a | Non-mutating argv smoke | Phase 6 D-16 tests [ASSUMED: not locked; agent discretion for smoke form] |
| Wrapper-owned `--allow-skip-backup` | n/a | Explicit override for D-12 | Must **not** be forwarded to setup [VERIFIED: setup rejects unknown long opts] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Thin allowlist wrapper | Full passthrough of all setup subcommands | Violates D-04; exposes uninstall/exp-merge accidentally |
| Defaults only `--core --skip-hyprland` | Also inject `--force` for automation | Violates D-07; dangerous on first adoption |
| Protection via `--skip-hyprland-entry` | Full `--skip-hyprland` | Entry-only still renames `hyprland.conf` — **incorrect** (D-08) [VERIFIED: 3.files-legacy.sh] |
| Soft reminder only | Hard interactive gate | Soft fails WRAP-03 intent / D-11 |
| Silent strip of `--skip-backup` | Refuse unless `--allow-skip-backup` | Silent strip hides intent; D-12 requires refuse |
| Mock by chmod -x setup only | Dedicated `--dry-run` | chmod is race-prone; dry-run is cleaner for CI-like asserts |

**Installation:** None — no npm/pip/cargo packages. New file only: `arch/dots-hyprland.sh` (+x).

**Version verification:**
```bash
bash --version   # GNU bash, 5.3.15  [VERIFIED]
git --version    # 2.55.0            [VERIFIED]
test -x vendor/dots-hyprland/setup && echo OK
```

## Package Legitimacy Audit

> **No external packages are installed in this phase.** Host bash + existing vendor submodule only.

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| — | — | — | — | — | N/A | No packages |

**Packages removed due to [SLOP] verdict:** none  
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```text
[Operator]
    |
    v
arch/dots-hyprland.sh
    |
    +-- bare / help / -h / --help  --> print wrapper help --> exit 0
    |
    +-- unknown subcommand         --> [FAIL] + point at vendor/./setup --> exit 1
    |
    +-- allowlisted subcmd
            |
            v
        preflight: II_ROOT/.git exists AND setup executable
            | fail --> [FAIL] + print git submodule update --init --recursive (no auto-fix)
            v
        scan user argv:
            * strip wrapper meta: --allow-skip-backup, --dry-run (recommended)
            * if --skip-backup without --allow-skip-backup --> [FAIL] refuse
            v
        if subcmd in {install, install-files}:
            inject SAFE_DEFAULTS=(--core --skip-hyprland --skip-sysupdate)
            hard backup gate (interactive "yes") unless user asked subcmd -h/--help
            v
        log [CONFIG] injected defaults + full argv
            |
            +-- if --dry-run --> print would-exec line --> exit 0  (no machine mutation)
            |
            v
        cd $REPO_ROOT/vendor/dots-hyprland
        ./setup <subcmd> <defaults…> <user flags…>
            |
            +-- install        --> greeting? + deps + setups + files (flags control skips)
            +-- install-deps   --> 1.deps-router only
            +-- install-setups --> 2.setups only
            +-- install-files  --> 3.files (+ legacy hypr/qs rsync rules)
```

### Recommended Project Structure

```text
.dotfiles/
├── arch/
│   ├── dots-hyprland.sh     # NEW — thin wrapper (this phase)
│   ├── quickshell.sh        # UNTOUCHED (retire Phase 8)
│   └── …                    # style references only
└── vendor/
    └── dots-hyprland/       # Phase 5 pin — call site only
        ├── setup            # exec target
        └── sdata/subcmd-install/
            ├── options.sh   # flag SoT
            ├── 3.files.sh   # backup prompt + firstrun
            └── 3.files-legacy.sh  # hypr rename / qs rsync
```

### Pattern 1: Structured arch script (`main` + labeled echos)

**What:** Match `arch/quickshell.sh`: shebang, `set -euo pipefail` (no `set -x`), `REPO_ROOT` from `BASH_SOURCE`, functions + `main "$@"`.  
**When to use:** Always for Phase 6.  
**Example:**

```bash
#!/usr/bin/env bash
set -euo pipefail

# arch/dots-hyprland.sh — thin wrapper around vendor/dots-hyprland/./setup
# Pattern: arch/quickshell.sh (REPO_ROOT, main dispatcher, [LABEL] echos).
# Divergence: no package arrays; delegates all install logic to upstream setup.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
II_ROOT="$REPO_ROOT/vendor/dots-hyprland"
SETUP="$II_ROOT/setup"
SAFE_DEFAULTS=(--core --skip-hyprland --skip-sysupdate)

main() {
  # dispatch allowlisted subcommands → preflight → defaults → gate → exec
  :
}
main "$@"
```

[VERIFIED: arch/quickshell.sh + CONVENTIONS.md structured template]

### Pattern 2: Argv construction (defaults then user flags)

**What:** Build bash arrays; never string-concatenate then `eval`.  
**When to use:** Always for WRAP-04 passthrough.  
**Example:**

```bash
# Source: locked D-09; verified setup getopt consumes flags after subcommand
cmd=(./setup "$subcmd")
if needs_safe_defaults "$subcmd"; then
  echo "[CONFIG] safe defaults: ${SAFE_DEFAULTS[*]}"
  cmd+=("${SAFE_DEFAULTS[@]}")
fi
cmd+=("${user_flags[@]}")  # already stripped of wrapper meta flags
echo "[INSTALL] ${cmd[*]}  (cwd=$II_ROOT)"
(
  cd "$II_ROOT"
  "${cmd[@]}"
)
```

### Pattern 3: Hard backup gate + refuse `--skip-backup`

**What:** Before files-touching exec, print D-13 facts and require typed `yes`. If user argv contains `--skip-backup` and not `--allow-skip-backup`, exit non-zero without calling setup. If both present, allow (and forward `--skip-backup` to setup; **do not** forward `--allow-skip-backup`).  
**When to use:** `install` and `install-files` only (D-11).  
**Example:**

```bash
# Source: D-11..D-13; BACKUP_DIR from vendor environment-variables.sh
backup_gate() {
  echo "[CONFIG] Upstream may backup clashing paths to: ~/ii-original-dots-backup"
  echo "[CONFIG] install-files will overwrite ~/.config/quickshell (rsync --delete)."
  echo "[CONFIG] Defaults include --skip-hyprland so personal hyprland.conf is not renamed."
  echo "[CONFIG] Do NOT pass --skip-backup on first adoption."
  local ans
  read -r -p "Type 'yes' to continue: " ans
  if [[ "$ans" != "yes" ]]; then
    echo "[FAIL] Aborted (backup gate). No ./setup invoked."
    exit 1
  fi
}
```

[VERIFIED: BACKUP_DIR default `$HOME/ii-original-dots-backup` in environment-variables.sh]

### Pattern 4: Preflight without auto-fix

**What:** Assert submodule + executable setup; print stock git repair only.  
**When to use:** Before every setup invocation including help-passthrough? Prefer before any call that needs `./setup` — including `install -h`. Bare wrapper help does **not** need preflight (D-02).  
**Example:**

```bash
preflight() {
  if [[ ! -e "$II_ROOT/.git" ]]; then
    echo "[FAIL] vendor/dots-hyprland is not an initialized submodule (missing .git)."
    echo "[FAIL] Fix (from REPO_ROOT): git submodule update --init --recursive"
    exit 1
  fi
  if [[ ! -x "$SETUP" ]]; then
    echo "[FAIL] $SETUP missing or not executable."
    echo "[FAIL] Fix: git submodule update --init --recursive && chmod +x vendor/dots-hyprland/setup"
    exit 1
  fi
}
```

### Anti-Patterns to Avoid

- **Reimplement package lists / rsync in arch/:** Bitrots vs pin; violates WRAP-01 and Pitfall 9.  
- **Default `--skip-hyprland-entry` instead of `--skip-hyprland`:** Still renames `hyprland.conf` → `.old` [VERIFIED: 3.files-legacy.sh lines 51–53].  
- **Forward `--allow-skip-backup` to setup:** Setup getopt errors: `unrecognized option '--allow-skip-backup'` [VERIFIED: live run].  
- **Call `./setup` with empty args from bare wrapper:** Upstream prints help, but D-02 requires wrapper help and never empty setup call.  
- **Auto-inject `--force`:** Bypasses upstream interactive safety; D-07.  
- **Gate `install-deps` / `install-setups`:** Not files-touching; D-11 says no.  
- **Auto `git submodule update` inside wrapper:** D-15 forbids auto-fix.  
- **Live install in Phase 6 smoke:** D-16 / Phase 7 owns mutation.  
- **`set -x` on structured script:** Prefer labeled echos (CONVENTIONS).  
- **Source `3.files.sh` directly:** Upstream warns scripts are meant to be sourced by `./setup` only [CITED: ii.clsty.link/en/ii-qs/01setup/].

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Install ii packages | pacman/yay arrays of illogical-impulse-* | `./setup install-deps` | Metapkg graph lives in `sdata/dist-arch` |
| Copy QS / hypr configs | custom rsync in arch/ | `./setup install-files` with flags | Firstrun, backup, skip flags, listfile |
| Flag parsing for all setup options | second getopt clone | Passthrough arrays to setup | Drift on every upstream option add |
| Global help for setup subcommands | re-document every flag | Pass `install -h` through | Single SoT: options.sh `showhelp` |
| Nested shapes init | wrapper recursive update | Phase 5 pin + operator stock git | D-15; shapes already verified OWN-03 |
| Post-install qs/session verify | `verify` subcommand | Phase 7 + future POLISH-01 | D-17 |

**Key insight:** The failure mode is **policy bugs in the wrapper** (wrong default flags, missing gate), not missing install logic. Keep the wrapper thin and test policy paths without running install.

## Exact `./setup` CLI Surface (live vendor tree)

### Global router (`vendor/dots-hyprland/setup`)

| Input | Behavior | Exit |
|-------|----------|------|
| `""` / `help` / `--help` / `-h` | `showhelp_global` | 0 |
| `install` | full pipeline (greeting → deps → setups → files), skippable via flags | varies |
| `install-deps` | step 1 only (`1.deps-router.sh`) | varies |
| `install-setups` | step 2 only (`2.setups.sh`) | varies |
| `install-files` | step 3 only (`3.files.sh` → legacy/exp files) | varies |
| `uninstall` / `exp-update` / `exp-merge` / `resetfirstrun` / `checkdeps` / `virtmon` | other subcmd dirs | **wrapper must refuse** |
| unknown | error + global help | 1 |

`install-deps|install-setups|install-files` all set `SUBCMD_DIR=./sdata/subcmd-install` and source the **same** `options.sh`. [VERIFIED: setup lines 52–60]

### Install options (shared)

| Flag | Effect (options.sh) | Phase 6 stance |
|------|---------------------|----------------|
| `-h` / `--help` | print install help, exit | Passthrough for subcmd help (D-03) |
| `-f` / `--force` | `ask=false` | Never auto-inject (D-07) |
| `-s` / `--skip-sysupdate` | `SKIP_SYSUPDATE=true` | **Default inject** for install/install-files (D-06) |
| `--core` | skip plasma/fish/fontconfig/misc | **Default inject** (D-06) |
| `--skip-hyprland` | skip **all** hypr file install | **Default inject** (D-06/D-08) |
| `--skip-hyprland-entry` | skip only `hyprland.lua` install | **Never** as protection default (D-08) |
| `--skip-backup` | skip `auto_backup_configs` | Refuse unless `--allow-skip-backup` (D-12) |
| `--skip-quickshell` | skip QS tree | Do not default; would defeat goal |
| `--skip-alldeps` / `--skip-allsetups` / `--skip-allfiles` | skip whole steps | Operator passthrough only |
| `--exp-files` / `--via-nix` | experimental | Passthrough only; not defaults |

### Hypr danger (why `--skip-hyprland`)

When `SKIP_HYPRLAND` is not true, legacy files step:

1. `rsync --delete` hyprland/ tree  
2. **`mv hyprland.conf → hyprland.conf.old`** if present  
3. Install `hyprland.lua` unless `SKIP_HYPRLAND_ENTRY`  
4. Auto-backup hyprlock/hypridle  

`--skip-hyprland-entry` alone still performs the rename. [VERIFIED: 3.files-legacy.sh]

### Upstream backup (second layer)

- Default dir: `BACKUP_DIR="${BACKUP_DIR:-$HOME/ii-original-dots-backup}"`  
- Runs in `3.files.sh` unless `SKIP_BACKUP=true`  
- Interactive y/n/s when `ask` is true; if `ask=false` (`--force`), auto-backups only when backup dir missing  

Wrapper gate is **in addition to** this — first adoption must not rely on operator noticing the upstream prompt alone. [VERIFIED: 3.files.sh `auto_backup_configs`]

### Official docs alignment

- `--core` = more minimal install (mainly Hyprland + Quickshell surface) [CITED: https://ii.clsty.link/en/ii-qs/01setup/]  
- Documented subcommands include install-deps / install-setups / install-files  
- Docs stress rsync override risk on update — reinforces backup messaging  

## Recommended Technical Approach (prescriptive)

### File

- Path: `arch/dots-hyprland.sh`  
- Mode: executable (`chmod +x`)  
- Style: structured generation (functions + `main`), not linear legacy `set -x` scripts  

### Control flow (ordered)

1. **Parse position 1**  
   - no args / `help` / `-h` / `--help` → wrapper `usage`, exit 0  
   - not in allowlist → `[FAIL]`, mention `vendor/dots-hyprland/./setup`, exit 1  
   - allowlisted → `subcmd=$1; shift`  

2. **Scan remaining args (wrapper meta)**  
   - Detect `--dry-run` (recommended, strip)  
   - Detect `--allow-skip-backup` (strip)  
   - Detect `--skip-backup` (keep for setup if allowed)  
   - Detect `-h` / `--help` among remaining (subcommand help path)  
   - All other args preserved in order for WRAP-04  

3. **`--skip-backup` policy (before preflight or after — before exec is required)**  
   - If `--skip-backup` present and `--allow-skip-backup` absent → `[FAIL]` with guidance, exit 1  
   - If both present → proceed; forward only `--skip-backup`  

4. **Preflight** (D-14) for any path that will invoke setup (including `install -h`)  

5. **Defaults injection** if `subcmd` ∈ {`install`,`install-files`} and not only documenting? **Always inject for those two even with `-h`** — harmless; getopt phase 1 still exits on help. Simpler code.  

6. **Backup gate** if `subcmd` ∈ {`install`,`install-files`} **and** remaining args are not solely help (`-h`/`--help`).  
   - Recommended yes-token: exact `yes` (case-sensitive) — clear, scriptable with `printf 'yes\n' |` for dry tests.  

7. **Log** injected defaults + full command line (D-10)  

8. **Dry-run exit** if requested (recommended)  

9. **`cd "$II_ROOT" && ./setup …`** with array argv  

### Wrapper-owned flags (must strip)

| Flag | Forward to setup? | Role |
|------|-------------------|------|
| `--allow-skip-backup` | **No** | D-12 override |
| `--dry-run` | **No** | D-16 smoke (agent discretion; strongly recommended) |

### Defaults matrix

| Subcommand | Inject `--core --skip-hyprland --skip-sysupdate` | Backup gate | Notes |
|------------|--------------------------------------------------|-------------|-------|
| `install` | Yes | Yes | Full path includes files step |
| `install-files` | Yes | Yes | Files only |
| `install-deps` | No | No | Flags still passthrough |
| `install-setups` | No | No | Flags still passthrough |

### Help text must document (WRAP-03 education)

- Safe defaults list and which subcommands get them  
- Backup gate behavior + `~/ii-original-dots-backup`  
- `--skip-backup` requires `--allow-skip-backup`  
- Allowlist of four subcommands  
- Examples:  
  - `./arch/dots-hyprland.sh install`  
  - `./arch/dots-hyprland.sh install-deps`  
  - `./arch/dots-hyprland.sh install-files --exp-files` (passthrough example)  
  - Point to `vendor/dots-hyprland/./setup` for non-allowlisted ops  

### Known limitation (document in help; locked by D-09)

There is **no** upstream `--no-skip-hyprland`. Once defaults inject `--skip-hyprland`, user flags cannot “undo” it via a positive flag. Full hypr install requires calling `vendor/dots-hyprland/./setup install` **directly** (outside wrapper) or a future wrapper escape hatch (out of scope). Duplicates of the same skip flag are OK.

## Common Pitfalls

### Pitfall 1: Forwarding wrapper meta flags to setup
**What goes wrong:** `./setup: unrecognized option '--allow-skip-backup'` (or `--dry-run`).  
**Why:** setup getopt long list is closed.  
**How to avoid:** Strip meta flags while scanning; only forward setup-known flags.  
**Warning signs:** Immediate setup failure before any install step.

### Pitfall 2: Using `--skip-hyprland-entry` as “safe”
**What goes wrong:** Personal `hyprland.conf` renamed to `.old`; session entry broken.  
**Why:** Rename is outside the entry skip branch.  
**How to avoid:** Default full `--skip-hyprland` only (D-08).  
**Warning signs:** `hyprland.conf.old` appears after install-files.

### Pitfall 3: Running real install during Phase 6 verification
**What goes wrong:** Live `~/.config/quickshell` / packages mutated before Phase 7 readiness (symlink retarget, etc.).  
**Why:** Temptation to “prove” wrapper end-to-end.  
**How to avoid:** `--dry-run` + help passthrough only (D-16).  
**Warning signs:** Plan tasks invoke `install-deps` without dry-run.

### Pitfall 4: Soft gate / default `--skip-backup`
**What goes wrong:** First adoption overwrites configs with no recoverable backup.  
**Why:** Convenience flags.  
**How to avoid:** Hard `yes` gate; refuse bare `--skip-backup`.  
**Warning signs:** Help text that suggests `--skip-backup` for normal use.

### Pitfall 5: Reimplementing setup in arch style
**What goes wrong:** Divergent package sets; pin updates don’t fix wrapper.  
**Why:** Other `arch/*.sh` own their package arrays.  
**How to avoid:** Zero package arrays in this file; only exec setup.  
**Warning signs:** `PACKAGES=(` appears in `dots-hyprland.sh`.

### Pitfall 6: Preflight auto-init
**What goes wrong:** Surprising network/git mutations; conflicts with pin philosophy.  
**Why:** “Helpful” wrapper.  
**How to avoid:** Print fix commands only (D-15).  
**Warning signs:** Wrapper runs `git submodule update`.

### Pitfall 7: Gate on deps/setups
**What goes wrong:** Annoying friction; operators skip wrapper.  
**Why:** Over-generalizing “files safety”.  
**How to avoid:** Gate only install + install-files (D-11).

### Pitfall 8: Stringy argv / eval
**What goes wrong:** Word-splitting; injection if flags ever carry spaces.  
**Why:** Logging convenience.  
**How to avoid:** Bash arrays end-to-end; log with `"${cmd[*]}"` for display only.

## Code Examples

### Full dispatcher skeleton (implementation reference)

```bash
#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
II_ROOT="$REPO_ROOT/vendor/dots-hyprland"
SETUP="$II_ROOT/setup"
SAFE_DEFAULTS=(--core --skip-hyprland --skip-sysupdate)
ALLOWLIST=(install install-deps install-setups install-files)

usage() {
  cat <<'EOF'
arch/dots-hyprland.sh — thin wrapper for vendor/dots-hyprland/./setup

Usage:
  arch/dots-hyprland.sh <install|install-deps|install-setups|install-files> [flags…]
  arch/dots-hyprland.sh help|-h|--help

Safe defaults (install, install-files only):
  --core --skip-hyprland --skip-sysupdate

Backup gate (install, install-files):
  Interactive confirmation required.
  Upstream backup dir: ~/ii-original-dots-backup
  QS config will be overwritten; hyprland.conf protected via --skip-hyprland.
  --skip-backup is refused unless also passing --allow-skip-backup.

Other setup subcommands (uninstall, exp-update, …):
  Use vendor/dots-hyprland/./setup directly.
EOF
}

is_allowlisted() {
  local s="$1" a
  for a in "${ALLOWLIST[@]}"; do [[ "$s" == "$a" ]] && return 0; done
  return 1
}

needs_safe_defaults() {
  [[ "$1" == "install" || "$1" == "install-files" ]]
}

preflight() { … }      # D-14
backup_gate() { … }    # D-11..D-13
# … scan_args, main …
```

### Non-mutating smoke (recommended)

```bash
# WRAP-01 help surfaces
./arch/dots-hyprland.sh >/tmp/whelp.out
test $? -eq 0
grep -q 'install-files' /tmp/whelp.out

# WRAP-01 allowlist
./arch/dots-hyprland.sh uninstall 2>/tmp/werr.out; test $? -ne 0
grep -q 'vendor/dots-hyprland' /tmp/werr.out

# WRAP-02 defaults visible without install
printf 'yes\n' | ./arch/dots-hyprland.sh install --dry-run >/tmp/wdry.out
grep -q -- '--core' /tmp/wdry.out
grep -q -- '--skip-hyprland' /tmp/wdry.out
grep -q -- '--skip-sysupdate' /tmp/wdry.out
grep -q 'vendor/dots-hyprland\|./setup' /tmp/wdry.out

# install-deps does NOT inject defaults
./arch/dots-hyprland.sh install-deps --dry-run >/tmp/wdeps.out
! grep -q -- '--skip-hyprland' /tmp/wdeps.out

# WRAP-03 refuse skip-backup
./arch/dots-hyprland.sh install --skip-backup --dry-run; test $? -ne 0

# WRAP-03 allow with override (still dry)
printf 'yes\n' | ./arch/dots-hyprland.sh install --skip-backup --allow-skip-backup --dry-run >/tmp/wskip.out
grep -q -- '--skip-backup' /tmp/wskip.out
! grep -q -- '--allow-skip-backup' /tmp/wskip.out

# WRAP-04 passthrough
printf 'yes\n' | ./arch/dots-hyprland.sh install-files --exp-files --dry-run >/tmp/wpt.out
grep -q -- '--exp-files' /tmp/wpt.out

# Subcommand help (non-mutating setup path)
./arch/dots-hyprland.sh install -h 2>&1 | grep -q -- '--skip-hyprland'
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `./install.sh` at repo root | `./setup install` | Upstream CLI rename (noted in setup help) | Wrapper targets `setup`, not install.sh |
| Online curl → `~/.cache/dots-hyprland` | Submodule pin + arch wrapper | v0.2 project decision | Reproducible pin; no cache path as SoT |
| Local `arch/quickshell.sh` symlink product | Upstream install-files → real XDG tree | v0.2 (retire Phase 8) | Phase 6 does not touch quickshell.sh |
| Full rice install flags | Dual-run: `--core --skip-hyprland` | v0.2 research + D-06 | Protects personal hypr session |

**Deprecated/outdated for this phase:**
- Treating `--skip-hyprland-entry` as sufficient protection  
- Reimplementing dist-arch PKGBUILDs in arch/  
- Phase 6 live install verification  

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Wrapper should implement `--dry-run` (not locked in CONTEXT) for D-16 smoke | Technical approach / Validation | Without it, argv tests need fragile chmod mocks or risk live install |
| A2 | Gate yes-token should be exact `yes` (case-sensitive) | Pattern 3 | Planner may pick Enter-to-continue; either OK if D-11 holds — pick one and test it |
| A3 | Inject defaults even when user passes `install -h` | Technical approach | Harmless if wrong; only code simplicity tradeoff |
| A4 | No shellcheck in CI required (tool missing on host) | Environment | Plans should use `bash -n` not shellcheck |

**If this table is empty:** — not empty; A1 is the only planning-relevant discretion item.

## Open Questions

None blocking. Locked decisions + live vendor tree fully specify behavior.

Resolved without user input:
- Backup path string for messaging: `~/ii-original-dots-backup` (upstream default).  
- Whether setup accepts duplicate long flags: yes (getopt re-processes; booleans stay true).  
- Whether `--allow-skip-backup` can be forwarded: no (unrecognized).  

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| bash | Wrapper runtime | ✓ | 5.3.15 | — |
| git | Preflight messaging / submodule | ✓ | 2.55.0 | — |
| `vendor/dots-hyprland/.git` | Preflight | ✓ | pin from Phase 5 | Operator: `git submodule update --init --recursive` |
| `vendor/dots-hyprland/setup` executable | Exec target | ✓ | pinned | — |
| shellcheck | Optional lint | ✗ | — | `bash -n arch/dots-hyprland.sh` |
| bats/pytest/jest | Test framework | ✗ | — | Inline shell asserts (Phase 5 pattern) |
| Live `./setup install*` mutation | Phase 6 smoke | N/A — **forbidden** | — | `--dry-run` + help only |

**Missing dependencies with no fallback:** none for Phase 6 implementation.  

**Missing dependencies with fallback:** shellcheck → `bash -n`.

Step 2.6: external tools are host bash/git only; vendor tree already present from Phase 5.

## Validation Architecture

> `workflow.nyquist_validation` is enabled (true) in `.planning/config.json`.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | None — inline shell / smoke asserts (same as Phase 5) |
| Config file | none |
| Quick run command | `bash -n arch/dots-hyprland.sh && ./arch/dots-hyprland.sh -h >/dev/null` |
| Full suite command | WRAP-01..04 dry/help assert block (below) |
| Estimated runtime | < 10 seconds |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| WRAP-01 | Script exists, executable, structured | smoke | `test -x arch/dots-hyprland.sh && bash -n arch/dots-hyprland.sh` | ❌ Wave 0 after implement |
| WRAP-01 | Bare help exits 0; documents four subcommands | smoke | `./arch/dots-hyprland.sh >/tmp/w6-help.txt; test $? -eq 0; grep -E 'install-deps|install-setups|install-files' /tmp/w6-help.txt` | ❌ |
| WRAP-01 | Allowlist refuses `uninstall` / `exp-update` | smoke | `./arch/dots-hyprland.sh uninstall; test $? -ne 0` | ❌ |
| WRAP-01 | Dry-run shows `./setup` + subcommand (not package arrays) | smoke | `printf 'yes\n' \| ./arch/dots-hyprland.sh install --dry-run \| tee /tmp/w6-i.txt \| grep -E './setup\|setup install'`; `! grep -E 'pacman -S\|yay -S' arch/dots-hyprland.sh` | ❌ |
| WRAP-01 | Subcommand help passthrough non-mutating | smoke | `./arch/dots-hyprland.sh install -h 2>&1 \| grep -q -- '--skip-hyprland'` | ❌ |
| WRAP-02 | Defaults include `--core` and `--skip-hyprland` for install | smoke | `printf 'yes\n' \| ./arch/dots-hyprland.sh install --dry-run \| grep -q -- '--core' && printf 'yes\n' \| ./arch/dots-hyprland.sh install --dry-run \| grep -q -- '--skip-hyprland'` | ❌ |
| WRAP-02 | Defaults also include `--skip-sysupdate` | smoke | `printf 'yes\n' \| ./arch/dots-hyprland.sh install --dry-run \| grep -q -- '--skip-sysupdate'` | ❌ |
| WRAP-02 | Defaults apply to install-files | smoke | `printf 'yes\n' \| ./arch/dots-hyprland.sh install-files --dry-run \| grep -q -- '--skip-hyprland'` | ❌ |
| WRAP-02 | Defaults do **not** apply to install-deps | smoke | `out=$(./arch/dots-hyprland.sh install-deps --dry-run); echo "$out" \| grep -q setup; ! echo "$out" \| grep -q -- '--skip-hyprland'` | ❌ |
| WRAP-02 | Script never uses `--skip-hyprland-entry` as default inject | smoke | `! grep -n 'SAFE_DEFAULTS=.*skip-hyprland-entry' arch/dots-hyprland.sh; grep -q 'skip-hyprland' arch/dots-hyprland.sh` | ❌ |
| WRAP-03 | Gate messaging mentions backup dir + QS overwrite + hypr protection | smoke | `printf 'yes\n' \| ./arch/dots-hyprland.sh install --dry-run 2>&1 \| tee /tmp/w6-gate.txt; grep -q 'ii-original-dots-backup' /tmp/w6-gate.txt; grep -qi 'quickshell' /tmp/w6-gate.txt; grep -q 'skip-hyprland' /tmp/w6-gate.txt` | ❌ |
| WRAP-03 | Gate aborts without yes (no setup) | smoke | `printf 'no\n' \| ./arch/dots-hyprland.sh install --dry-run; test $? -ne 0` | ❌ |
| WRAP-03 | `--skip-backup` alone refused | smoke | `./arch/dots-hyprland.sh install --skip-backup --dry-run; test $? -ne 0` | ❌ |
| WRAP-03 | `--skip-backup` + `--allow-skip-backup` accepted; meta flag not forwarded | smoke | `printf 'yes\n' \| ./arch/dots-hyprland.sh install --skip-backup --allow-skip-backup --dry-run \| tee /tmp/w6-sb.txt; grep -q -- '--skip-backup' /tmp/w6-sb.txt; ! grep -q -- '--allow-skip-backup' /tmp/w6-sb.txt` | ❌ |
| WRAP-03 | Help does not encourage `--skip-backup` as default | smoke | `./arch/dots-hyprland.sh -h \| tee /tmp/w6-h2.txt; grep -q 'allow-skip-backup\|refuse\|Do NOT' /tmp/w6-h2.txt` | ❌ |
| WRAP-04 | Extra flags appear after defaults in dry-run argv | smoke | `printf 'yes\n' \| ./arch/dots-hyprland.sh install --exp-files --dry-run \| grep -E -- '--core.*--exp-files\|--skip-hyprland.*--exp-files'` | ❌ |
| WRAP-04 | install-deps passthrough without defaults | smoke | `./arch/dots-hyprland.sh install-deps -s --dry-run \| grep -q -- '-s\|--skip-sysupdate'` | ❌ |
| D-14 | Preflight fails clearly if setup not executable | smoke | `chmod -x vendor/dots-hyprland/setup; ./arch/dots-hyprland.sh install-deps --dry-run; ec=$?; chmod +x vendor/dots-hyprland/setup; test $ec -ne 0` | ❌ (use trap restore) |
| D-02 | Bare invocation never runs setup | smoke | `./arch/dots-hyprland.sh 2>&1 \| tee /tmp/w6-bare.txt; test $? -eq 0; ! grep -q 'Next command' /tmp/w6-bare.txt` | ❌ |

### Sampling Rate

- **Per task commit:** `bash -n arch/dots-hyprland.sh` + relevant row command  
- **Per wave merge:** Full WRAP-01..04 dry/help block  
- **Phase gate:** Full suite green; confirm no live `./setup install*` mutation occurred  

### Wave 0 Gaps

- [ ] `arch/dots-hyprland.sh` — implement before automated verifies can run  
- [ ] Embed WRAP assert commands in each plan’s `<verify><automated>` (inline preferred; Phase 5 style)  
- [ ] Optional: tiny `scripts/phase06-wrapper-smoke.sh` if planner wants one-shot full suite — **not required** if plans embed asserts  
- [ ] Framework install: none  
- [ ] **Require wrapper `--dry-run`** (or equivalent) so asserts never call real install — planner should treat A1 as default design choice  

*(If dry-run is rejected: only help/allowlist/static-grep tests remain fully safe; argv logging tests become manual-only.)*

### Manual-only (not Phase 6 success criteria)

| Behavior | Why manual / deferred |
|----------|----------------------|
| Real `install-deps` / `install-files` on machine | Phase 7 |
| Session `qs -c ii` | Phase 7 LIVE-* |
| Non-interactive gate policy | Deferred explicitly |

## Security Domain

> `security_enforcement` enabled; ASVS level 1.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | N/A — local operator script |
| V3 Session Management | no | N/A |
| V4 Access Control | partial | Refuse root if documenting setup’s `prevent_sudo_or_root`; wrapper runs as user |
| V5 Input Validation | yes | Allowlist subcommands; argv arrays (no `eval`); strip unknown-to-setup meta flags |
| V6 Cryptography | no | N/A |

### Known Threat Patterns for bash install wrappers

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Unexpected subcommand (uninstall) via wrapper | Elevation / Tampering | Allowlist only WRAP-01 four (D-04) |
| Accidental `--skip-backup` | Tampering / DoS (data loss) | Refuse without `--allow-skip-backup` (D-12) |
| Hypr conf destruction | Tampering | Default `--skip-hyprland` (D-06/D-08) |
| Command injection via flags | Tampering | Array exec only; never `eval "$flags"` |
| Running as root → wrong ownership on `~/.config` | Elevation | Document/respect setup `prevent_sudo_or_root`; operator runs as user |
| Silent auto-fix mutating git | Tampering | D-15 never auto-fix |
| Secrets in logs | Information disclosure | Do not log env secrets; only flags/paths |

## Sources

### Primary (HIGH confidence)

- `vendor/dots-hyprland/setup` — subcommand router, help, install-* mapping [VERIFIED: read + live `./setup -h`]  
- `vendor/dots-hyprland/sdata/subcmd-install/options.sh` — full flag list / getopt [VERIFIED]  
- `vendor/dots-hyprland/sdata/subcmd-install/3.files.sh` — backup gate upstream, BACKUP usage [VERIFIED]  
- `vendor/dots-hyprland/sdata/subcmd-install/3.files-legacy.sh` — hyprland.conf rename; SKIP_HYPRLAND vs ENTRY [VERIFIED]  
- `vendor/dots-hyprland/sdata/lib/environment-variables.sh` — `BACKUP_DIR` default [VERIFIED]  
- Live probe: `./setup install --allow-skip-backup` → `unrecognized option` [VERIFIED]  
- `arch/quickshell.sh`, `.planning/codebase/CONVENTIONS.md` — structured script pattern [VERIFIED]  
- `.planning/phases/06-…/06-CONTEXT.md` — D-01..D-17 locked [VERIFIED]  
- `.planning/REQUIREMENTS.md` — WRAP-01..04 [VERIFIED]  
- Phase 5 pin presence under `vendor/dots-hyprland` [VERIFIED]

### Secondary (MEDIUM confidence)

- https://ii.clsty.link/en/ii-qs/01setup/ — `--core`, install-* subcommands, rsync override warnings [CITED]  
- `.planning/research/{STACK,ARCHITECTURE,PITFALLS,SUMMARY}.md` — adoption model [VERIFIED local; originally multi-source]

### Tertiary (LOW confidence)

- Exact operator preference for yes-token vs Enter-to-continue (discretion)  
- Whether planner prefers embedded asserts vs `scripts/phase06-wrapper-smoke.sh`

## Project Constraints (from CLAUDE.md)

No `./CLAUDE.md` or `./.claude/CLAUDE.md` present in the repo at research time. Conventions taken from `.planning/codebase/CONVENTIONS.md` and existing `arch/*.sh` (see Architecture Patterns).

## Metadata

**Confidence breakdown:**
- Standard stack: **HIGH** — host bash + live vendor setup; no third-party packages  
- Architecture: **HIGH** — locked decisions map 1:1 onto verified setup behavior  
- Pitfalls: **HIGH** — hypr rename, backup, getopt unknown flags verified in tree  

**Research date:** 2026-07-25  
**Valid until:** 2026-08-24 (30 days; re-check if submodule pin moves and changes `options.sh` / files scripts)
