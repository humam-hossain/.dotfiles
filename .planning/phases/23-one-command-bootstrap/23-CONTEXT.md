# Phase 23: One-command bootstrap - Context

**Gathered:** 2026-09-15
**Status:** Ready for planning

<domain>
## Phase Boundary

Orchestrate the complete desktop environment reproduction from a fresh git clone into a fully functioning, strictly verified desktop session via a single command (`./bootstrap.sh`):

1. **Seven-Step Pipeline:** Submodule recursion → base package prerequisites (`git`, `stow`, `jq`, `yay` via `arch/aur.sh`) → upstream dots-hyprland setup (`./setup install` / `install-files`) → de-stubbing upstream conflicts into a timestamped hierarchical backup archive → linking all `stow/` and `restow/` packages (`--no-folding`) → seeding `capture/` baselines (`config.json`) → strict verification (`arch/dots-hyprland.sh verify --strict`).
2. **Two-Stage Execution across Relogin:** Cleanly split the workflow at the session relogin boundary. Stage 1 completes all disk placements, writes state, and displays an instruction banner to relogin. Stage 2 (post-relogin) verifies the live graphical Hyprland environment, starts systemd user capture timers, and executes `verify --strict`.
3. **Resumable State Machine:** Persist state machine progress in `$XDG_STATE_HOME/dotfiles/bootstrap-state` (JSON). Support `--from <step>`, `--only <step>`, `--dry-run`, and `--reset` to guarantee deterministic recovery after interruptions and 100% idempotence on re-runs.
4. **De-Stubbing & Backup Architecture:** Detect upstream conflicts via `stow -n --no-folding`, protect all paths in `guard-paths.tsv`, back up conflicting non-link regular files into `$HOME/.dotfiles-backup.<epoch>/` with a SHA-256 `MANIFEST.txt`, clean dangling/stale symlinks, and link all packages without using `--adopt`.
5. **Committed Package Snapshots:** Snapshot explicitly installed native (`pacman -Qqen`) and foreign/AUR (`pacman -Qqem`) packages into `arch/pkglist-native.txt` and `arch/pkglist-aur.txt` with timestamp/host headers and sorted entries via an on-demand `./bootstrap.sh --snapshot` flag, keeping standard bootstrap free of working-tree drift.
6. **Strict Verification Exit Code Gate:** The final step runs `arch/dots-hyprland.sh verify --strict`; bootstrap's exit code is strictly the exit code of `verify`, ensuring zero drift.
7. **Zero Regression Footprint:** `./bootstrap.sh` resides at the repository root and coordinates actions without creating new scripts in `arch/`, preserving `PAIR_COUNT == 18` in `scripts/phase17-unblock-assert.sh`.

Out of scope:
- Reimplementing a custom package manager or full dependency solver (upstream `./setup` remains SoT).
- Debian/Ubuntu parity (Arch Linux is the sole primary target; bootstrap fails closed if `/etc/arch-release` is missing).
- Non-interactive sudo bypassing (bootstrap asserts non-root `EUID != 0` and relies on standard user-mode prompts).
- Automatic git committing of package snapshots or state files during normal bootstrap.

</domain>

<decisions>
## Implementation Decisions

### Command Interface & State Machine

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

### Session Split & Relogin Boundary

- **D-08:** Stage boundary after `capture_seed`: Stage 1 finishes all disk placements (steps 1–6). Bootstrap saves state marking Stage 1 complete, outputs a prominent formatted relogin instruction banner, and exits `0`. Stage 2 handles post-relogin verification. — **Reversibility:** reversible
- **D-09:** Operator instruction banner: Clear, bordered terminal box explaining that compositor session configuration shifted from pre-adopt/conf to `hyprland.lua`. Specifies the logout command (`hyprctl dispatch exit`), SDDM re-login, and the exact resumption command (`./bootstrap.sh`). — **Reversibility:** reversible
- **D-10:** Session runtime probe on resumption: On re-running `./bootstrap.sh`, if Stage 1 is complete, bootstrap checks for an active graphical Hyprland environment (`HYPRLAND_INSTANCE_SIGNATURE` is set and `hyprctl -j status` reports `configProvider: "lua"`). If running in a TTY without a graphical session, it warns the operator before proceeding to verify. — **Reversibility:** reversible
- **D-11:** Systemd user unit activation: In Stage 1, `stow/systemd/` unit files are symlinked into `~/.config/systemd/user/`. In Stage 2 (when user D-Bus is running), bootstrap executes `systemctl --user daemon-reload` and `systemctl --user --now enable dotfiles-capture.timer`, then verifies `systemctl --user is-active dotfiles-capture.timer`. — **Reversibility:** reversible

### Stow Package Orchestration & De-stubbing

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

### Package Snapshots & Arch Coordination

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

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Architecture & Workflows
- `docs/dots-hyprland-workflow.md` — Authoritative full-only install and update playbook.
- `docs/config-redistribution.md` — Tree redistribution map for every configuration file.
- `restow/README.md` — Package inventory and recovery contracts for cp-through files.
- `capture/README.md` — Contract for copy-captured files subject to runtime renames.
- `collision-map.tsv` — Complete derived collision taxonomy for upstream installer primitives.
- `guard-paths.tsv` — Data contract excluding generated theme outputs from repository tracking.

### Core Scripts & Verification
- `arch/dots-hyprland.sh` — Upstream setup wrapper, allowlist, `run_verify()`, `run_capture()`.
- `scripts/phase17-unblock-assert.sh` — Closed assert test establishing `PAIR_COUNT == 18` invariant.
- `scripts/phase19-verify-assert.sh` — Verification harness and exit code contract definitions.
- `scripts/phase21-capture-assert.sh` — Systemd capture service/timer and JSON validation contract.
- `scripts/phase22-kde-and-gtk-capture-assert.sh` — Per-file stow, GUARD list enforcement, and cp-through drill.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `arch/dots-hyprland.sh`: Houses `run_verify()` (`--strict`, `--quiet`), `run_capture()`, and `run_install_family()`. Can be invoked directly by `./bootstrap.sh`.
- `arch/aur.sh`: Idempotently installs `yay` if not already installed on Arch Linux.
- `guard-paths.tsv`: Machine-readable TSV list of theme outputs that de-stubbing and stow must never touch.
- `collision-map.tsv`: Machine-readable TSV detailing installer collision classes and write primitives.

### Established Patterns
- **Array Execution:** Always execute commands via bash arrays (`"${cmd[@]}"`), never `eval` or concatenated strings.
- **Fail-Closed Verification:** Strict verification (`arch/dots-hyprland.sh verify --strict`) returns 0 on clean, 1 on drift, 2 on precondition failure.
- **Universal Stow Invariant:** Universal `--verbose=5 --no-folding -t ~` for all stow invocations.
- **Timestamped Safe Backups:** Back up conflicting live files to `.dotfiles-backup.<epoch>` with metadata before performing link replacements.

### Integration Points
- `./bootstrap.sh`: Primary entry point placed at repository root, callable directly after `git clone`.
- `$XDG_STATE_HOME/dotfiles/bootstrap-state`: Persistent state tracking JSON.
- `arch/pkglist-native.txt` & `arch/pkglist-aur.txt`: Explicit package snapshots committed as repository data.

</code_context>

<specifics>
## Specific Ideas

- Format the Stage 1 completion pause banner with an eye-catching border and clear instructions:
  ```text
  ┌────────────────────────────────────────────────────────────────────────┐
  │                        BOOTSTRAP: STAGE 1 COMPLETE                     │
  ├────────────────────────────────────────────────────────────────────────┤
  │ All dotfiles, overlays, and session configs have been placed on disk.  │
  │                                                                        │
  │ The session entry point has changed to upstream hyprland.lua.          │
  │ A session relogin is mandatory to load the new desktop environment:   │
  │                                                                        │
  │   1. Exit current session:  hyprctl dispatch exit                      │
  │   2. Log back in via display manager / SDDM                            │
  │   3. Complete bootstrap by running:                                    │
  │        ./bootstrap.sh                                                  │
  └────────────────────────────────────────────────────────────────────────┘
  ```
- Make `./bootstrap.sh` smart enough to detect when Stage 1 was already completed so re-running `./bootstrap.sh` seamlessly picks up Stage 2 without asking the user for flags.

</specifics>

<deferred>
## Deferred Ideas

- None — discussion stayed strictly within Phase 23 scope.

</deferred>

---

*Phase: 23-One-command bootstrap*
*Context gathered: 2026-09-15*
