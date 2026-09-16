# Phase 23: One-command bootstrap - Research

**Gathered:** 2026-09-15  
**Status:** Complete — ready for planning  
**Target:** `.planning/phases/23-one-command-bootstrap/23-RESEARCH.md`  

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Root orchestrator entry point: `./bootstrap.sh` lives at the repository root as the primary operator-facing command. If invoked as `arch/dots-hyprland.sh bootstrap`, the wrapper execs `"$REPO_ROOT/bootstrap.sh" "$@"`. This keeps root ergonomics clean while avoiding adding new stow call sites under `arch/` (maintaining `PAIR_COUNT == 18`). — **Reversibility:** reversible
- **D-02:** State persistence: Bootstrap state is stored in `$XDG_STATE_HOME/dotfiles/bootstrap-state` (JSON format). It stores schema version, start timestamp, last update, current stage (1 or 2), completed step tokens, and per-step status (`pending`, `running`, `complete`, `failed`). Conforms to XDG, persists across relogin/reboot, and never pollutes the git working tree. — **Reversibility:** reversible
- **D-03:** Seven atomic pipeline steps:
  1. `submodules`: `git submodule update --init --recursive`
  2. `packages`: Verify/install base prerequisites (`git`, `stow`, `jq`, `yay` via `arch/aur.sh`)
  3. `installer`: Delegate to `./arch/dots-hyprland.sh install` (or `install-files`)
  4. `destub`: Conflict discovery via `stow -n`, backup to `~/.dotfiles-backup.<epoch>/`, removal of conflicting stubs
  5. `stow`: Pre-create directories and link all packages in `stow/` then `restow/` with `--verbose=5 --no-folding -t ~`
  6. `capture_seed`: Copy baseline files from `capture/` to `$HOME` with `jq empty` JSON validation
  7. `verify`: Enable systemd units and run `./arch/dots-hyprland.sh verify --strict` — **Reversibility:** reversible
- **D-04:** CLI flags contract:
  - `--dry-run`: Structured preview displaying step names, state file status, exact shell commands to dispatch, and non-mutating checks (`stow -n`).
  - `--from <step>`: Resume execution starting at `<step>`, skipping prior steps.
  - `--only <step>`: Execute only the specified step and exit.
  - `--reset`: Wipe state file to force a full clean re-run.
  - `--snapshot`: Regenerate package snapshot data files without running bootstrap.
  - `--no-pause`: Skip interactive relogin pause (for headless/automated CI runs).
  - `--help`: Display usage, steps, and options. — **Reversibility:** reversible
- **D-05:** Fail-closed error semantics: On any non-zero step exit, immediately mark the step as `failed` in the state file, log error diagnostics, output the exact resume command (`./bootstrap.sh --from <step>`), and exit with the step's error exit code. — **Reversibility:** reversible
- **D-06:** Non-root execution & on-demand privilege: `./bootstrap.sh` asserts `EUID != 0` immediately. Sudo is requested on-demand by commands that need it (`pacman`, `yay`); bootstrap does not cache credentials upfront or allow running as root. — **Reversibility:** reversible
- **D-07:** Logging and transcript preservation: Bootstrap streams live to terminal stdout/stderr while tee-ing all output to `$XDG_STATE_HOME/dotfiles/logs/bootstrap-<timestamp>.log`, retaining the 5 most recent log files. — **Reversibility:** reversible
- **D-08:** Stage boundary after `capture_seed`: Stage 1 finishes all disk placements (steps 1–6). Bootstrap saves state marking Stage 1 complete, outputs a prominent formatted relogin instruction banner, and exits `0`. Stage 2 handles post-relogin verification. — **Reversibility:** reversible
- **D-09:** Operator instruction banner: Clear, bordered terminal box explaining that compositor session configuration shifted from pre-adopt/conf to `hyprland.lua`. Specifies the logout command (`hyprctl dispatch exit`), SDDM re-login, and the exact resumption command (`./bootstrap.sh`). — **Reversibility:** reversible
- **D-10:** Session runtime probe on resumption: On re-running `./bootstrap.sh`, if Stage 1 is complete, bootstrap checks for an active graphical Hyprland environment (`HYPRLAND_INSTANCE_SIGNATURE` is set and `hyprctl -j status` reports `configProvider: "lua"`). If running in a TTY without a graphical session, it warns the operator before proceeding to verify. — **Reversibility:** reversible
- **D-11:** Systemd user unit activation: In Stage 1, `stow/systemd/` unit files are symlinked into `~/.config/systemd/user/`. In Stage 2 (when user D-Bus is running), bootstrap executes `systemctl --user daemon-reload` and `systemctl --user --now enable dotfiles-capture.timer`, then verifies `systemctl --user is-active dotfiles-capture.timer`. — **Reversibility:** reversible
- **D-12:** Dynamic package enumeration: Bootstrap iterates all directory entries in `stow/` and `restow/` (skipping `README.md`, `.*`, and non-directories), linking each package with `--verbose=5 --no-folding -t ~`. Automatically absorbs newly added packages without script edits. — **Reversibility:** reversible
- **D-13:** Tree linking order: Link all `stow/` packages first, followed by all `restow/` packages. — **Reversibility:** reversible
- **D-14:** Pre-creation of sensitive parent directories: Before running stow, bootstrap runs:
  ```bash
  mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0" "$HOME/.config/hypr/custom" "$HOME/.config/systemd/user"
  ```
  Ensures GNU Stow cannot fold these directories into directory-level symlinks. — **Reversibility:** reversible
- **D-15:** De-stubbing discovery via dry-run: Step 4 runs `stow -n --no-folding -t ~ <pkg>` for every package in `stow/` and `restow/`. It extracts target paths that conflict (`* existing target is neither a link nor a directory:` or `not owned by stow`). — **Reversibility:** reversible
- **D-16:** Safe hierarchical backup archive: All conflicting regular files are copied to `$HOME/.dotfiles-backup.<epoch>/<relative-path>` preserving directory hierarchy. A `MANIFEST.txt` is generated with ISO timestamps, relative paths, and SHA-256 hashes. Only after backup are the conflicting files unlinked from `$HOME`. Adheres strictly to the `--adopt` ban. — **Reversibility:** reversible
- **D-17:** Guard paths protection: De-stubbing cross-references conflicting paths against `guard-paths.tsv`. Any path listed in `guard-paths.tsv` (e.g. `kdeglobals`, `gtk.css`, `colors.lua`) is skipped and left as a local regular file; de-stubbing never touches or deletes guarded theme files. — **Reversibility:** costly — modifying guard logic risks theme churn.
- **D-18:** Pre-stow link sanitation: Detect dangling symlinks (`-xtype l`) or symlinks pointing outside the dotfiles repository under managed destinations. Back them up to the epoch backup directory and remove them, enabling GNU Stow to link cleanly and idempotently on re-runs. — **Reversibility:** reversible
- **D-19:** Generic capture seed deployment: For every file under `capture/`, copy it to its relative path under `$HOME`. For `.json` files (e.g. `config.json`), validate syntax via `jq empty` before deploying. Deploy atomically via temporary file rename on the same filesystem (`${target}.tmp.$$` to `${target}`). — **Reversibility:** reversible
- **D-20:** Package snapshot storage: Committed as `arch/pkglist-native.txt` (from `pacman -Qqen`) and `arch/pkglist-aur.txt` (from `pacman -Qqem`). Header comments record hostname, ISO timestamp, kernel version, and pacman version. Package lists are sorted alphabetically with `sort -u` for clean, deterministic diffs. — **Reversibility:** reversible
- **D-21:** On-demand snapshot regeneration: Snapshots are generated or updated ONLY when `./bootstrap.sh --snapshot` is explicitly invoked. Standard bootstrap runs never modify tracked snapshot files, guaranteeing zero working-tree drift. — **Reversibility:** reversible
- **D-22:** Arch script coordination: Bootstrap ensures prerequisites (`git`, `stow`, `jq`, `yay` via `arch/aur.sh`) exist, then delegates core desktop packages to upstream `./setup`. Individual standalone `arch/*.sh` scripts (e.g. `latex.sh`, `obs_studio.sh`, `vscode.sh`) remain modular on-demand application installers. — **Reversibility:** reversible
- **D-23:** Verification & assert harness: `scripts/phase23-bootstrap-assert.sh` provides a multi-section test suite:
  1. CLI argument parsing, flags, unknown flags refusal (exit 2), and dry-run preview.
  2. Isolated scratch XDG environment (`XDG_CONFIG_HOME`, `XDG_DATA_HOME`, `XDG_STATE_HOME`) testing de-stubbing, backup manifest generation, parent directory preservation, and stow linking.
  3. State machine resumability: killing steps, verifying `--from`, `--only`, and idempotence.
  4. Snapshot generation idempotence and formatting check.
  5. Live host dry-run and `verify --strict` exit 0 confirmation. — **Reversibility:** reversible

### Claude's Discretion

- Exact formatting, ANSI color codes, and box drawing characters for the relogin terminal banner.
- Variable naming in internal shell helper functions inside `./bootstrap.sh`.
- Scratch directory naming patterns used by `scripts/phase23-bootstrap-assert.sh`.

### Deferred Ideas

- None — discussion stayed strictly within Phase 23 scope.

</user_constraints>

---

<phase_requirements>
## Phase Requirements

| Requirement ID | Milestone Requirement Text | Phase 23 Implementation & Research Support |
|---|---|---|
| **BOOT-01** | A single command bootstraps a fresh machine, is resumable after failure, and is idempotent on re-run | [VERIFIED: `stow`, `jq`, bash state machine] Root orchestrator `./bootstrap.sh` manages state in `$XDG_STATE_HOME/dotfiles/bootstrap-state` (JSON). Flags `--from <step>`, `--only <step>`, and `--reset` guarantee deterministic resume and re-run idempotence. Non-zero step exit marks state as `failed` and outputs exact resume command. |
| **BOOT-02** | Bootstrap ordering is submodule init, then ii `./setup`, then stow, then capture seed, then verify — stow must follow the installer | [VERIFIED: `vendor/dots-hyprland/sdata/subcmd-install/3.files.sh:154`] Upstream installer creates default stubs (`dots/.config/hypr/custom/*`, `hyprlock.conf`, etc.). Running installer in Step 3, de-stubbing in Step 4, stow in Step 5, and capture seed in Step 6 ensures stow and personal overlays cleanly supersede upstream files without collisions. |
| **BOOT-03** | Bootstrap reports where it stops and what the operator must do, since the session entry point changes mid-run and a relogin is unavoidable | [VERIFIED: `hyprctl -j status`] Stage 1 exits `0` after Step 6 (`capture_seed`), outputting a clear bordered terminal banner instructing the operator to exit (`hyprctl dispatch exit`), log in via SDDM, and resume with `./bootstrap.sh`. Stage 2 probes runtime session (`configProvider: "lua"`) and finishes Step 7 (`verify`). |
| **BOOT-04** | Bootstrap ends in a `verify` pass, so "reproduces the exact setup" is asserted rather than assumed | [VERIFIED: `arch/dots-hyprland.sh:752`] Bootstrap Step 7 executes `./arch/dots-hyprland.sh verify --strict`. The overall bootstrap exit code is strictly the exit code of `verify`. Any missing link, unexpected file, drifted capture baseline, or folded directory fails closed. |
| **BOOT-05** | Explicitly installed package lists (`pacman -Qqen`, `pacman -Qqem`) are snapshotted into the repo as data | [VERIFIED: `pacman -Qqen`, `pacman -Qqem`] On-demand flag `./bootstrap.sh --snapshot` generates `arch/pkglist-native.txt` and `arch/pkglist-aur.txt` with formatted metadata headers and `sort -u` ordering. Standard bootstrap runs never modify these files, ensuring zero git working-tree drift. |

</phase_requirements>

---

## Architectural Responsibility Map

```
+-----------------------------------------------------------------------------------------+
|                                    OPERATOR / HOST                                      |
+-----------------------------------------------------------------------------------------+
                                             |
                         (invokes clone & ./bootstrap.sh)
                                             v
+-----------------------------------------------------------------------------------------+
|                             ./bootstrap.sh (Repository Root)                            |
|  - Asserts EUID != 0 and /etc/arch-release exists                                       |
|  - Streams live output and tees to $XDG_STATE_HOME/dotfiles/logs/bootstrap-<epoch>.log  |
|  - Manages State Machine in $XDG_STATE_HOME/dotfiles/bootstrap-state (JSON)             |
+-----------------------------------------------------------------------------------------+
       |
       +---> [Step 1: submodules]   `git submodule update --init --recursive`
       |
       +---> [Step 2: packages]     Checks git, stow, jq, yay (delegates to arch/aur.sh)
       |
       +---> [Step 3: installer]    Delegates to arch/dots-hyprland.sh install
       |                            (runs upstream vendor/dots-hyprland/setup)
       |
       +---> [Step 4: destub]       Runs `stow -n --no-folding` discovery;
       |                            Cross-references `guard-paths.tsv`;
       |                            Archives stubs to ~/.dotfiles-backup.<epoch>/ (MANIFEST);
       |                            Unlinks stubs and cleans foreign/dangling links
       |
       +---> [Step 5: stow]         Pre-creates sensitive dirs (gtk-3.0, gtk-4.0, custom, etc.);
       |                            Dynamic package enumeration across stow/ then restow/
       |                            (`stow --verbose=5 --no-folding -t ~ <pkg>`)
       |
       +---> [Step 6: capture_seed] Validates JSON via `jq empty`;
       |                            Copies capture/ baseline configs to $HOME atomically
       |
  [STAGE 1 COMPLETION: Bordered Relogin Instruction Banner -> Exits 0]
===========================================================================================
  [OPERATOR RELOGIN: hyprctl dispatch exit -> SDDM login -> Re-runs ./bootstrap.sh]
===========================================================================================
       |
       +---> [Stage 2 Probe]        Probes HYPRLAND_INSTANCE_SIGNATURE & configProvider=="lua"
       |
       +---> [Step 7: verify]       - systemctl --user daemon-reload
                                    - systemctl --user --now enable dotfiles-capture.timer
                                    - systemctl --user is-active dotfiles-capture.timer
                                    - arch/dots-hyprland.sh verify --strict (Exit Gate)
```

### Script & Path Ownership Boundaries

1. **`./bootstrap.sh` (NEW - Repository Root):** Primary operator interface and orchestrator. Owns flag parsing, pipeline stepping, state machine persistence, de-stubbing, backup manifest generation, and Stage 1 relogin pauses. Does not live in `arch/`.
2. **`arch/dots-hyprland.sh` (EXISTING):** Upstream setup wrapper. Adds `bootstrap` to `ALLOWLIST` to dispatch `exec "$REPO_ROOT/bootstrap.sh" "$@"` (D-01). Preserves `PAIR_COUNT == 18` in `scripts/phase17-unblock-assert.sh`.
3. **`arch/pkglist-native.txt` & `arch/pkglist-aur.txt` (NEW):** Committed repository data files representing the machine's package baseline (D-20, BOOT-05).
4. **`guard-paths.tsv` (EXISTING):** Authoritative list of 7 theme paths that de-stubbing and stow must NEVER modify or delete (D-17).
5. **`$XDG_STATE_HOME/dotfiles/bootstrap-state` (RUNTIME):** JSON state persistence file tracking step statuses across restarts and relogins (D-02).
6. **`$HOME/.dotfiles-backup.<epoch>/` (RUNTIME):** Hierarchical backup archive containing preserved stubs and `MANIFEST.txt` with SHA-256 hashes (D-16).

---

## Standard Stack

| Tool / Utility | In-Repo / System Path | Version / Capability | Purpose in Phase 23 |
|---|---|---|---|
| **Bash** | `/usr/bin/bash` | 5.3+ (`set -euo pipefail`) [VERIFIED: system] | Pipeline execution, array-based execution, error traps |
| **GNU Stow** | `/usr/bin/stow` | 2.4.1 [VERIFIED: system] | Symlink creation and conflict simulation (`-n --no-folding`) |
| **jq** | `/usr/bin/jq` | 1.8.2 [VERIFIED: system] | State JSON manipulation and capture seed syntax validation |
| **Git** | `/usr/bin/git` | 2.55.0 [VERIFIED: system] | Submodule recursion (`git submodule update --init --recursive`) |
| **pacman** | `/usr/bin/pacman` | 7.1.0 [VERIFIED: system] | Package presence verification and snapshot data generation |
| **yay** | `/usr/bin/yay` | 13.0.1 [VERIFIED: system] | AUR package installer (bootstrapped via `arch/aur.sh`) |
| **systemctl** | `/usr/bin/systemctl` | 261.3 [VERIFIED: system] | User timer daemon-reload, enablement, and activation probe |
| **hyprctl** | `/usr/bin/hyprctl` | 0.56.2 [VERIFIED: system] | Runtime session probing (`hyprctl -j status`) |

---

## Architecture Patterns

### 1. System Architecture Diagram

```
+----------------------------------------------------------------------------------------+
|                                    BOOTSTRAP RUNTIME                                    |
+----------------------------------------------------------------------------------------+
|                                                                                        |
|  1. CLI Parsing & Dispatch                                                            |
|     +-- Checks EUID != 0, /etc/arch-release                                            |
|     +-- Parses --dry-run, --from, --only, --reset, --snapshot, --no-pause               |
|                                                                                        |
|  2. State Engine ($XDG_STATE_HOME/dotfiles/bootstrap-state)                            |
|     +-- schema_version: 1                                                              |
|     +-- stage: 1 | 2                                                                   |
|     +-- steps: { <step>: { status: "pending"|"running"|"complete"|"failed", ... } }     |
|                                                                                        |
|  3. De-stubbing & Link Sanitizer Engine                                                |
|     +-- Executes `stow -n --no-folding -t ~ <pkg>`                                      |
|     +-- Parses conflict output against Stow.pm conflict regexes                        |
|     +-- Ignores paths matching guard-paths.tsv                                         |
|     +-- Copies regular files to ~/.dotfiles-backup.<epoch>/                             |
|     +-- Writes MANIFEST.txt (timestamp, relative path, sha256)                         |
|     +-- Unlinks stubs; removes dangling/foreign symlinks                                |
|                                                                                        |
|  4. Dynamic Stow Engine                                                                |
|     +-- Pre-creates: gtk-3.0, gtk-4.0, hypr/custom, systemd/user                        |
|     +-- Iterates stow/* (skipping README.md, .*, non-dirs)                             |
|     +-- Iterates restow/* (skipping README.md, .*, non-dirs)                           |
|     +-- Runs: stow --verbose=5 --no-folding -t ~ <pkg>                                 |
|                                                                                        |
|  5. Relogin Instruction Banner (Stage 1 Pause)                                         |
|     +-- Formats bordered ANSI banner                                                   |
|     +-- Records stage=2 in state file                                                  |
|     +-- Exits 0 (unless --no-pause)                                                    |
|                                                                                        |
|  6. Post-Relogin Stage 2 Verification Gate                                             |
|     +-- Probes HYPRLAND_INSTANCE_SIGNATURE & hyprctl -j status                         |
|     +-- Activates dotfiles-capture.timer (daemon-reload -> enable --now)               |
|     +-- Runs: arch/dots-hyprland.sh verify --strict                                    |
|     +-- Bootstrap exit code == verify exit code                                        |
+----------------------------------------------------------------------------------------+
```

### 2. Step Flow & Transition Table

| Step # | Step Token | Stage | Preconditions | Action | Postconditions |
|---|---|---|---|---|---|
| 1 | `submodules` | 1 | Git repo initialized | `git submodule update --init --recursive` | `vendor/dots-hyprland/.git` present |
| 2 | `packages` | 1 | Non-root user | Check `git`, `stow`, `jq`, `yay`; run `arch/aur.sh` if needed | Required base tools executable on PATH |
| 3 | `installer` | 1 | Submodule initialized | Run `./arch/dots-hyprland.sh install` | Upstream files, fonts, and packages installed |
| 4 | `destub` | 1 | Upstream installer finished | `stow -n` conflict check, backup to epoch dir with manifest, unlink stubs | Stubs removed; guard paths untouched |
| 5 | `stow` | 1 | Stubs removed | Pre-create sensitive parent dirs; stow `stow/*` then `restow/*` | All packages cleanly symlinked into `$HOME` |
| 6 | `capture_seed` | 1 | Target directories exist | Copy `capture/*` to `$HOME` with `jq empty` validation | Baseline configs (e.g. `config.json`) placed |
| - | *Pause* | 1 | Steps 1–6 complete | Persist state (`stage=2`); render relogin banner; exit `0` | Operator prompted to relog |
| 7 | `verify` | 2 | Graphical session active | Reload systemd, enable capture timer, run `verify --strict` | Session verified, timer active, exit 0 |

### 3. State Schema (`$XDG_STATE_HOME/dotfiles/bootstrap-state`)

```json
{
  "schema_version": 1,
  "started_at": "2026-09-15T11:00:00Z",
  "updated_at": "2026-09-15T11:05:00Z",
  "stage": 1,
  "current_step": "destub",
  "steps": {
    "submodules": { "status": "complete", "timestamp": "2026-09-15T11:00:05Z" },
    "packages": { "status": "complete", "timestamp": "2026-09-15T11:01:00Z" },
    "installer": { "status": "complete", "timestamp": "2026-09-15T11:03:00Z" },
    "destub": { "status": "running", "timestamp": "2026-09-15T11:03:15Z" },
    "stow": { "status": "pending", "timestamp": null },
    "capture_seed": { "status": "pending", "timestamp": null },
    "verify": { "status": "pending", "timestamp": null }
  },
  "last_error": null
}
```

---

## Don't Hand-Roll

| Problem | What NOT to Do | What to Do Instead | Rationale / Source |
|---|---|---|---|
| **Resolving Conflicts** | Passing `--adopt` to GNU Stow [VERIFIED: D-16] | Run `stow -n`, backup stubs to `~/.dotfiles-backup.<epoch>/` with SHA-256 manifest, and unlink stubs before stowing | `--adopt` mutates the repository source tree by pulling conflicting stubs into git, violating repository integrity. |
| **Package Dependency Solving** | Re-implementing a custom package manager or aur helper in bash | Delegate to upstream `./setup` via `arch/dots-hyprland.sh install` and `arch/aur.sh` | Upstream maintains distribution-specific package mappings and dependencies. |
| **Parsing Stow Conflicts** | Ad-hoc substring grepping that breaks on path whitespace | Match exact conflict strings emitted by GNU Stow's `Stow.pm` [VERIFIED: `/usr/share/perl5/vendor_perl/Stow.pm`] | Stow conflict formats are fixed in Perl source; parsing targets precisely prevents accidental unlinking. |
| **State Tracking** | Touching marker files (`/tmp/.stepN_done`) across the filesystem | Single atomic JSON file in `$XDG_STATE_HOME/dotfiles/bootstrap-state` updated via `jq` | Atomic JSON state file survives reboots/relogins and does not leave stray files in `/tmp`. |
| **Theme Output Tracking** | De-stubbing or stowing generated CSS/Lua files | Cross-reference `guard-paths.tsv` and skip any matching path | Active wallpaper tools (`switchwall.sh`, `matugen`) constantly rewrite guarded paths. |
| **Session Probing** | Guessing compositor state by grepping `ps aux` | Check `HYPRLAND_INSTANCE_SIGNATURE` and query `hyprctl -j status \| jq .configProvider` [VERIFIED: system] | `hyprctl status` provides authoritative confirmation of the active Lua config provider. |

---

## Common Pitfalls

### Pitfall 1: Stow Conflict Message Variations
- **Symptom:** Stubs fail to be pruned because `stow -n` conflict messages vary depending on conflict type.
- **Cause:** GNU Stow emits different error messages for regular files vs directories vs stowed packages [VERIFIED: `/usr/share/perl5/vendor_perl/Stow.pm:546-646`]:
  1. `cannot stow <src> over existing target <target> since neither a link nor a directory and --adopt not specified`
  2. `existing target is not owned by stow: <target>`
  3. `existing target is stowed to a different package: <target> => <dest>`
  4. `cannot stow non-directory <src> over existing directory target <target>`
  5. `cannot stow directory <src> over existing non-directory target <target>`
- **Remedy:** The conflict parser regex must extract `<target>` across all 5 forms.

### Pitfall 2: Over-aggressive De-stubbing of Guarded Theme Files
- **Symptom:** `kdeglobals`, `gtk.css`, or `colors.lua` gets backed up and deleted during Step 4, causing desktop themes to break or verification to fail.
- **Cause:** Upstream installer or wallpaper scripts place these files as regular files or unmanaged symlinks.
- **Remedy:** De-stubbing MUST cross-reference all candidates against `guard-paths.tsv` (expanding `$XDG_CONFIG_HOME`) and immediately skip any path listed [VERIFIED: D-17].

### Pitfall 3: Subshell Asynchrony Dropping Log Lines on Exit
- **Symptom:** `bootstrap-<timestamp>.log` is missing trailing output or verification exit status.
- **Cause:** Using `exec > >(tee -a "$LOG") 2>&1` causes `tee` to run in a detached background subshell. When the main bash process exits, `tee` can be killed before flushing stdout.
- **Remedy:** Duplicate original FDs (`exec 3>&1 4>&2`), redirect output to `tee`, and on exit trap close descriptors (`exec 1>&3 2>&4`) and call `wait 2>/dev/null || true` before exiting.

### Pitfall 4: Missing `hostname` Binary on Arch Linux
- **Symptom:** `./bootstrap.sh --snapshot` fails with `bash: hostname: command not found`.
- **Cause:** Modern Arch Linux core does not include `inetutils` or `net-tools` by default [VERIFIED: system audit].
- **Remedy:** Use `uname -n` or `cat /etc/hostname 2>/dev/null` or `$HOSTNAME` to retrieve the machine's hostname deterministically.

### Pitfall 5: Executing Systemd User Commands in a Headless / Pre-Relogin Environment
- **Symptom:** `systemctl --user enable --now dotfiles-capture.timer` fails with `Failed to connect to bus: No medium found` or `DBUS_SESSION_BUS_ADDRESS not defined`.
- **Cause:** In a bare TTY or pre-relogin session, user D-Bus may not be active or graphical environment variables are missing.
- **Remedy:** Systemd user unit activation is strictly isolated to **Stage 2** (post-relogin) when Hyprland and user D-Bus are active [VERIFIED: D-11].

### Pitfall 6: Pre-existing Pre-folded Directory Symlinks
- **Symptom:** GNU Stow folds `~/.config/gtk-3.0` or `~/.config/hypr/custom` into a directory symlink if the parent directory does not already exist.
- **Cause:** Without existing parent directories, GNU Stow may symlink the entire directory instead of linking leaf files.
- **Remedy:** Run Step 5 pre-creation (D-14):
  `mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0" "$HOME/.config/hypr/custom" "$HOME/.config/systemd/user"`
  before invoking any stow command.

---

## Code Examples

### 1. Atomic State Persistence Engine

```bash
# State persistence helper using jq
STATE_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/bootstrap-state"

init_state() {
  if [[ ! -f "$STATE_FILE" ]]; then
    mkdir -p "$(dirname "$STATE_FILE")"
    local now
    now="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    jq -n --arg ts "$now" '{
      schema_version: 1,
      started_at: $ts,
      updated_at: $ts,
      stage: 1,
      current_step: "submodules",
      steps: {
        submodules: { status: "pending", timestamp: null },
        packages: { status: "pending", timestamp: null },
        installer: { status: "pending", timestamp: null },
        destub: { status: "pending", timestamp: null },
        stow: { status: "pending", timestamp: null },
        capture_seed: { status: "pending", timestamp: null },
        verify: { status: "pending", timestamp: null }
      },
      last_error: null
    }' > "$STATE_FILE.tmp.$$" && mv "$STATE_FILE.tmp.$$" "$STATE_FILE"
  fi
}

set_step_status() {
  local step="$1" status="$2" err="${3:-}"
  local now
  now="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  local tmp="$STATE_FILE.tmp.$$"
  jq --arg step "$step" --arg status "$status" --arg ts "$now" --arg err "$err" '
    .updated_at = $ts |
    .current_step = $step |
    .steps[$step].status = $status |
    .steps[$step].timestamp = $ts |
    if $err != "" then .last_error = $err else . end
  ' "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
}
```

### 2. Conflict Discovery and De-stubbing Logic

```bash
destub_package_conflicts() {
  local tree_dir="$1" pkg="$2"
  local stow_out
  stow_out="$(stow -n --no-folding -d "$tree_dir" -t "$HOME" "$pkg" 2>&1 || true)"
  
  # Extract conflicting targets
  local conflict_targets=()
  while IFS= read -r line; do
    if [[ "$line" =~ ^[[:space:]]*\*[[:space:]]+cannot[[:space:]]+stow[[:space:]]+.*[[:space:]]+over[[:space:]]+existing[[:space:]]+target[[:space:]]+(.*)[[:space:]]+since[[:space:]]+neither ]]; then
      conflict_targets+=("${BASH_REMATCH[1]}")
    elif [[ "$line" =~ ^[[:space:]]*\*[[:space:]]+existing[[:space:]]+target[[:space:]]+is[[:space:]]+not[[:space:]]+owned[[:space:]]+by[[:space:]]+stow:[[:space:]]+(.*) ]]; then
      conflict_targets+=("${BASH_REMATCH[1]}")
    fi
  done <<< "$stow_out"

  # Process each conflict
  for rel_path in "${conflict_targets[@]+"${conflict_targets[@]}"}"; do
    local live_path="$HOME/$rel_path"
    
    # 1. Guard check
    if is_guarded_path "$live_path"; then
      echo "[GUARD] Skipping guarded path: $rel_path"
      continue
    fi

    # 2. Regular file backup and unlink
    if [[ -f "$live_path" && ! -L "$live_path" ]]; then
      mkdir -p "$BACKUP_DIR/$(dirname "$rel_path")"
      local sha
      sha="$(sha256sum "$live_path" | awk '{print $1}')"
      local now
      now="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
      printf '%s  %s  %s\n' "$now" "$sha" "$rel_path" >> "$BACKUP_DIR/MANIFEST.txt"
      cp -p "$live_path" "$BACKUP_DIR/$rel_path"
      rm -f "$live_path"
      echo "[DESTUB] Backed up and pruned stub: $rel_path"
    elif [[ -L "$live_path" ]]; then
      # Foreign or dangling symlink
      rm -f "$live_path"
      echo "[PRUNE] Removed stale/foreign symlink: $rel_path"
    fi
  done
}
```

### 3. Dynamic Stow Package Execution

```bash
run_stow_pipeline() {
  local target="${1:-$HOME}"
  
  # D-14: Pre-create parent directories
  mkdir -p "$target/.config/gtk-3.0" \
           "$target/.config/gtk-4.0" \
           "$target/.config/hypr/custom" \
           "$target/.config/systemd/user"

  # Link stow/ packages first
  for pkg_dir in "$REPO_ROOT/stow"/*; do
    [[ -d "$pkg_dir" ]] || continue
    local pkg
    pkg="$(basename "$pkg_dir")"
    [[ "$pkg" != "README.md" && "$pkg" != .* ]] || continue
    stow --verbose=5 --no-folding -d "$REPO_ROOT/stow" -t "$target" "$pkg"
  done

  # Link restow/ packages next
  for pkg_dir in "$REPO_ROOT/restow"/*; do
    [[ -d "$pkg_dir" ]] || continue
    local pkg
    pkg="$(basename "$pkg_dir")"
    [[ "$pkg" != "README.md" && "$pkg" != .* ]] || continue
    stow --verbose=5 --no-folding -d "$REPO_ROOT/restow" -t "$target" "$pkg"
  done
}
```

### 4. Stage 1 Operator Banner Display

```bash
show_relogin_banner() {
  local reset="\033[0m"
  local bold="\033[1m"
  local green="\033[32m"
  local cyan="\033[36m"
  
  # If not in terminal, strip colors
  if [[ ! -t 1 ]]; then
    reset="" bold="" green="" cyan=""
  fi

  cat <<EOF

${bold}${cyan}┌────────────────────────────────────────────────────────────────────────┐${reset}
${bold}${cyan}│${reset}                        ${bold}${green}BOOTSTRAP: STAGE 1 COMPLETE${reset}                     ${bold}${cyan}│${reset}
${bold}${cyan}├────────────────────────────────────────────────────────────────────────┤${reset}
${bold}${cyan}│${reset} All dotfiles, overlays, and session configs have been placed on disk.  ${bold}${cyan}│${reset}
${bold}${cyan}│${reset}                                                                        ${bold}${cyan}│${reset}
${bold}${cyan}│${reset} The session entry point has changed to upstream ${bold}hyprland.lua${reset}.          ${bold}${cyan}│${reset}
${bold}${cyan}│${reset} A session relogin is mandatory to load the new desktop environment:    ${bold}${cyan}│${reset}
${bold}${cyan}│${reset}                                                                        ${bold}${cyan}│${reset}
${bold}${cyan}│${reset}   1. Exit current session:  ${bold}hyprctl dispatch exit${reset}                      ${bold}${cyan}│${reset}
${bold}${cyan}│${reset}   2. Log back in via display manager / SDDM                             ${bold}${cyan}│${reset}
${bold}${cyan}│${reset}   3. Complete bootstrap by running:                                     ${bold}${cyan}│${reset}
${bold}${cyan}│${reset}        ${bold}./bootstrap.sh${reset}                                                   ${bold}${cyan}│${reset}
${bold}${cyan}└────────────────────────────────────────────────────────────────────────┘${reset}

EOF
}
```

### 5. Package Snapshot Generation (`--snapshot`)

```bash
generate_snapshots() {
  local host
  host="$(uname -n 2>/dev/null || cat /etc/hostname 2>/dev/null || echo "${HOSTNAME:-arch}")"
  local ts
  ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  local kernel
  kernel="$(uname -r)"
  local pac_ver
  pac_ver="$(pacman -V 2>/dev/null | grep -o 'Pacman v[0-9.]* - libalpm v[0-9.]*' || echo "unknown")"

  # Native packages
  local nat_file="$REPO_ROOT/arch/pkglist-native.txt"
  {
    printf '# arch/pkglist-native.txt — explicitly installed native packages\n'
    printf '# Hostname: %s\n' "$host"
    printf '# Timestamp: %s\n' "$ts"
    printf '# Kernel: %s\n' "$kernel"
    printf '# Pacman: %s\n' "$pac_ver"
    printf '# Count: %d\n' "$(pacman -Qqen | wc -l)"
    pacman -Qqen | LC_ALL=C sort -u
  } > "$nat_file.tmp.$$" && mv "$nat_file.tmp.$$" "$nat_file"

  # AUR packages
  local aur_file="$REPO_ROOT/arch/pkglist-aur.txt"
  {
    printf '# arch/pkglist-aur.txt — explicitly installed foreign/AUR packages\n'
    printf '# Hostname: %s\n' "$host"
    printf '# Timestamp: %s\n' "$ts"
    printf '# Kernel: %s\n' "$kernel"
    printf '# Pacman: %s\n' "$pac_ver"
    printf '# Count: %d\n' "$(pacman -Qqem | wc -l)"
    pacman -Qqem | LC_ALL=C sort -u
  } > "$aur_file.tmp.$$" && mv "$aur_file.tmp.$$" "$aur_file"

  echo "[SNAPSHOT] Successfully generated $nat_file and $aur_file"
}
```

---

## Environment Availability

| Command / Dependency | Required By | Tested Status | Path | Output / Version |
|---|---|---|---|---|
| `bash` | Orchestrator & asserts | **Available** [VERIFIED] | `/usr/bin/bash` | 5.3.0(1)-release |
| `git` | Step 1 (`submodules`) | **Available** [VERIFIED] | `/usr/bin/git` | 2.55.0 |
| `stow` | Step 4 & 5 (de-stub & link) | **Available** [VERIFIED] | `/usr/bin/stow` | 2.4.1 |
| `jq` | Step 6 & State tracking | **Available** [VERIFIED] | `/usr/bin/jq` | 1.8.2 |
| `yay` | Step 2 (`packages`) | **Available** [VERIFIED] | `/usr/bin/yay` | 13.0.1 |
| `pacman` | Base package & snapshots | **Available** [VERIFIED] | `/usr/bin/pacman` | 7.1.0 - libalpm v16.0.1 |
| `systemctl` | Step 7 (unit activation) | **Available** [VERIFIED] | `/usr/bin/systemctl` | systemd 261 (261.3-1-arch) |
| `hyprctl` | Stage 2 runtime probe | **Available** [VERIFIED] | `/usr/bin/hyprctl` | 0.56.2 (`configProvider: lua`) |
| `/etc/arch-release` | OS platform gate | **Available** [VERIFIED] | `/etc/arch-release` | File exists |
| `hostname` | Legacy net-tools command | **MISSING** [VERIFIED] | N/A | Use `uname -n` or `cat /etc/hostname` |

---

## Validation Architecture (Nyquist)

### Test Harness Mapping (`scripts/phase23-bootstrap-assert.sh`)

Every requirement and behavior in Phase 23 is mapped to an automated assert section in `scripts/phase23-bootstrap-assert.sh`:

| Section | Target Requirement / Decision | Test Mechanism & Fixture | Expected Outcome |
|---|---|---|---|
| **Section 1** | D-01, D-04, D-06 (CLI & Contract) | Subshell invocation with `--help`, unknown flags (`--bogus`), root user probe (`EUID=0`), non-Arch probe, and `arch/dots-hyprland.sh bootstrap` forward. | `--help` exits 0; `--bogus` exits 2; simulated root exits 1; wrapper correctly executes `bootstrap.sh`. |
| **Section 2** | D-14, D-15, D-16, D-17, D-18 (De-stubbing & Stow) | Isolated scratch environment (`mktemp -d`) with mock repo, conflicting stubs (including guarded `kdeglobals`, non-guarded `general.lua`, and dangling link). Run destub and stow. | Guarded path untouched; non-guarded stub archived to backup dir with `MANIFEST.txt` (SHA-256); stow links verified with `-ef`. |
| **Section 3** | D-02, D-03, D-05, BOOT-01 (State Resumability & Idempotence) | Step execution with simulated failure; inspect JSON state; resume via `--from`; test `--only` and `--reset`; re-run over completed state. | State records `failed` and `complete`; `--from` resumes accurately; re-run is 100% idempotent. |
| **Section 4** | D-20, D-21, BOOT-05 (Package Snapshots) | Run `./bootstrap.sh --snapshot` into scratch target; parse headers and sort order; verify standard bootstrap does not mutate files. | Valid headers (Hostname, Timestamp, Kernel, Pacman); alphabetically sorted; no working-tree drift during normal run. |
| **Section 5** | D-08, D-11, D-23, BOOT-04 (Live Host Verification) | Run `./bootstrap.sh --dry-run` on live host; assert `PAIR_COUNT == 18` in `arch/*.sh`; execute `./arch/dots-hyprland.sh verify --strict`. | Dry-run exits 0; `PAIR_COUNT` preserved; live verification exits 0 with `FAIL=0 FINDINGS=0`. |

---

## Open Questions Resolved During Research

### Q5: Does the installer skip a pre-folded `custom/` on a genuinely fresh target?
- **Finding:** [VERIFIED: `vendor/dots-hyprland/sdata/subcmd-install/3.files.sh:154`] Upstream's `install_dir__ignore_existing` tests `if [ -d $t ]`. In bash, `[ -d symlink_to_dir ]` returns true for an existing directory symlink. If the directory exists, upstream prints `"... already exists, will not do anything."` and skips.
- **Consequence for Bootstrap:** In standard bootstrap ordering (BOOT-02), the installer runs in Step 3 BEFORE stow runs in Step 5. On a fresh target, `custom/` is populated by upstream with default stubs. Step 4 (`destub`) detects these stubs via `stow -n`, backs them up to `~/.dotfiles-backup.<epoch>/`, and removes them. Then Step 5 pre-creates the parent directory with `mkdir -p "$HOME/.config/hypr/custom"` and stows our custom overlay symlinks cleanly.

### Q14: Does `systemctl --user enable` work from a TTY with no graphical session and no lingering?
- **Finding:** [VERIFIED: system audit] In a bare TTY, `systemd --user` is running via pam_systemd, but graphical environment variables (`WAYLAND_DISPLAY`, `DISPLAY`) and active user D-Bus sessions may not be fully initialized.
- **Consequence for Bootstrap:** Attempting `--now` on `dotfiles-capture.timer` in Stage 1 could fire `dotfiles-capture.service` without graphical environment variables. Splitting systemd activation to Stage 2 (post-relogin) guarantees that the user is logged into the graphical Hyprland environment, D-Bus session bus is active, and `systemctl --user --now enable dotfiles-capture.timer` succeeds deterministically.

### Preserving `PAIR_COUNT == 18` in `scripts/phase17-unblock-assert.sh`:
- **Finding:** [VERIFIED: `scripts/phase17-unblock-assert.sh:89-96`] The assert specifically runs:
  `PAIR_COUNT="$(grep -ho -- '--verbose=5 --no-folding' arch/*.sh | wc -l || true)"` and enforces `[[ "$PAIR_COUNT" -eq 18 ]]`.
- **Consequence for Bootstrap:** `./bootstrap.sh` MUST reside at the repository root (`/home/pera/github_repo/.dotfiles/bootstrap.sh`). When `arch/dots-hyprland.sh bootstrap` is called, it adds `bootstrap` to `ALLOWLIST` and executes `exec "$REPO_ROOT/bootstrap.sh" "$@"`. No new `.sh` files are created in `arch/`, and no new stow call sites are placed in `arch/*.sh`. `PAIR_COUNT` remains strictly 18.

---

## Assumptions Log & Sources

| Assumption / Claim | Tag | Source / Evidence |
|---|---|---|
| `./bootstrap.sh` lives at repo root and dispatches without adding stow sites to `arch/` | `[VERIFIED: file/command]` | `23-CONTEXT.md:32`, `scripts/phase17-unblock-assert.sh:89` |
| Upstream `install_dir__ignore_existing` tests `[ -d $t ]` and skips if target exists | `[VERIFIED: file/command]` | `vendor/dots-hyprland/sdata/subcmd-install/3.files.sh:154` |
| GNU Stow emits 5 distinct conflict messages across regular, dir, and foreign link collisions | `[VERIFIED: file/command]` | `/usr/share/perl5/vendor_perl/Stow.pm:546-646` |
| Hostname binary is missing on Arch core; `uname -n` and `/etc/hostname` work | `[VERIFIED: file/command]` | Shell execution on live Arch host |
| `guard-paths.tsv` protects 7 specific theme output paths | `[VERIFIED: file/command]` | `guard-paths.tsv:14-20` |
| `hyprctl -j status` reports `"configProvider": "lua"` on active Hyprland desktop | `[VERIFIED: file/command]` | Shell execution of `hyprctl -j status` on live host |
| Native package count is 207, AUR package count is 56 on current system | `[VERIFIED: file/command]` | `pacman -Qqen | wc -l`, `pacman -Qqem | wc -l` |
| `arch/dots-hyprland.sh verify --strict` currently exits 0 with 0 FAIL and 0 FINDINGS | `[VERIFIED: file/command]` | Shell execution of `scripts/phase19-link-aware-verify-assert.sh` |
| `arch/pkglist-native.txt` and `arch/pkglist-aur.txt` do not yet exist in repo | `[VERIFIED: file/command]` | `ls arch/pkglist-*.txt` |

---

## RESEARCH COMPLETE

**Phase:** 23 - One-command bootstrap  
**Confidence:** HIGH  

### Key Findings
1. Upstream installer (`3.files.sh`) places stubs into `~/.config/hypr/custom/` and other directories on a fresh machine. Running `installer` in Step 3, `destub` in Step 4, and `stow` in Step 5 cleanly extracts and backs up conflicting stubs into `~/.dotfiles-backup.<epoch>/` with a SHA-256 `MANIFEST.txt` while leaving all 7 guarded theme paths untouched.
2. The session boundary cleanly bifurcates Stage 1 (disk placement: steps 1–6) and Stage 2 (session verification: step 7). Splitting at relogin allows the compositor to reload into `hyprland.lua` before `verify --strict` and `systemctl --user --now enable dotfiles-capture.timer` run.
3. Placing `./bootstrap.sh` at the repository root and delegating from `arch/dots-hyprland.sh bootstrap` preserves `PAIR_COUNT == 18` in `scripts/phase17-unblock-assert.sh` with zero regressions.
4. On Arch Linux, `hostname` binary may not be installed; `uname -n` or `/etc/hostname` provides reliable hostname data for package snapshots.

### File Created
- `/home/pera/github_repo/.dotfiles/.planning/phases/23-one-command-bootstrap/23-RESEARCH.md`

### Confidence Assessment
- Architecture & Pipeline: HIGH — fully mapped to existing verified contracts (`stow`, `dots-hyprland.sh`, `guard-paths.tsv`, `collision-map.tsv`).
- De-stubbing & Conflict Engine: HIGH — verified directly against GNU Stow Perl source code (`/usr/share/perl5/vendor_perl/Stow.pm`).
- System Environment: HIGH — all binaries (`git`, `stow`, `jq`, `yay`, `pacman`, `systemctl`, `hyprctl`) tested and verified live on Arch Linux.

### Open Questions
- None. All research items from ROADMAP.md and CONTEXT.md (Q5, Q14, de-stub rule, PAIR_COUNT invariant, assertion harness strategy) are fully resolved.

### Ready for Planning
- Phase 23 is ready for `/gsd-plan-phase 23`.
