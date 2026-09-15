# Phase 23: One-command bootstrap - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-15  
**Phase:** 23-one-command-bootstrap  
**Areas discussed:** Command Interface & State Machine, Session Split & Relogin Boundary, Stow Package Orchestration & De-stubbing, Package Snapshots & Arch Script Coordination  

---

## Command Interface & State Machine

| Option | Description | Selected |
|--------|-------------|:--------:|
| Root `./bootstrap.sh` delegating to `arch/dots-hyprland.sh bootstrap` | Provides root entry point, consolidates logic in wrapper, preserves `PAIR_COUNT == 18` | ✓ |
| Standalone `./bootstrap.sh` at repository root | All orchestration in root script; calls submodules and stow directly | |
| Subcommand only: `arch/dots-hyprland.sh bootstrap` | Subcommand only, no root script | |

**User's choice:** Root `./bootstrap.sh` delegating to `arch/dots-hyprland.sh bootstrap`.  
**Notes:** Avoids adding a new script in `arch/*.sh`, preserving `scripts/phase17-unblock-assert.sh:90` `PAIR_COUNT == 18`.

| Option | Description | Selected |
|--------|-------------|:--------:|
| `$XDG_STATE_HOME/dotfiles/bootstrap-state` (JSON) | Conforms to XDG base directory specification, persists across relogins, does not dirty git | ✓ |
| `$REPO_ROOT/.bootstrap-state` (JSON, gitignored) | Co-locates state in repo working tree with .gitignore entry | |
| `$XDG_STATE_HOME/dotfiles/bootstrap-state` (plain text) | Minimal line-per-step text file | |

**User's choice:** `$XDG_STATE_HOME/dotfiles/bootstrap-state` (JSON).  
**Notes:** XDG state directory prevents git working-tree drift, ensuring `verify --strict` passes.

| Option | Description | Selected |
|--------|-------------|:--------:|
| 7 distinct atomic steps | submodules → packages → installer → destub → stow → capture_seed → verify | ✓ |
| 5 consolidated stages | init → install → stow → seed → verify | |
| 6 steps | submodules → installer → destub → stow → services → verify | |

**User's choice:** 7 distinct atomic steps (`submodules`, `packages`, `installer`, `destub`, `stow`, `capture_seed`, `verify`).  
**Notes:** Enables fine-grained `--from <step>` and `--only <step>` targeting.

| Option | Description | Selected |
|--------|-------------|:--------:|
| Standard flag set | `--dry-run`, `--from <step>`, `--only <step>`, `--reset`, `--help` | ✓ |
| Minimal flag set | `--dry-run`, `--from <step>`, `--only <step>` | |
| Extended flag set | Adds `--yes` for unattended auto-confirm | |

**User's choice:** Standard flag set (`--dry-run`, `--from <step>`, `--only <step>`, `--reset`, `--help`).  
**Notes:** `--reset` allows resetting state without manually deleting files.

| Option | Description | Selected |
|--------|-------------|:--------:|
| Fail-closed on error | Mark step 'failed', print diagnosis + exact resume command, propagate error code | ✓ |
| Interactive prompt on error | Offer [Retry / Skip / Abort] | |
| Abort & clean partial state | Clean partial state and abort | |

**User's choice:** Fail-closed on error with exact resume instruction.  
**Notes:** Fully deterministic; operator knows exactly how to resume via `./bootstrap.sh --from <step>`.

| Option | Description | Selected |
|--------|-------------|:--------:|
| Structured execution preview | Step names, state status, shell commands, non-mutating checks | ✓ |
| Terse shell command list | Raw shell commands only | |
| High-level summary | Sequence of pending steps only | |

**User's choice:** Structured execution preview.  
**Notes:** Shows command dispatches and runs `stow -n` dry checks without disk modifications.

| Option | Description | Selected |
|--------|-------------|:--------:|
| On-demand sudo | Refuse root invocation (`EUID == 0`); prompt for sudo on-demand when commands need it | ✓ |
| Strict non-root + pre-cache `sudo -v` | Pre-cache credentials upfront before package step | |
| Permissive | Warn on root but allow if `--allow-root` passed | |

**User's choice:** On-demand sudo.  
**Notes:** Strictly forbids running entire script under `sudo` to protect `$HOME` and permissions.

| Option | Description | Selected |
|--------|-------------|:--------:|
| Terminal stream + tee to log | Live stdout/stderr + tee to `$XDG_STATE_HOME/dotfiles/logs/bootstrap-<timestamp>.log` | ✓ |
| Terminal output only | No persistent log file | |
| Log file with quiet progress | Spinner in terminal, full verbose output in log file | |

**User's choice:** Stream live to terminal + tee to log file (retaining last 5 runs).  
**Notes:** Combines operator visibility with persistent audit/debug logs.

---

## Session Split & Relogin Boundary

| Option | Description | Selected |
|--------|-------------|:--------:|
| Pause after `capture_seed` | Stage 1 finishes all disk placements; Stage 2 handles post-relogin verify | ✓ |
| Pause immediately after installer | Pause before stow; stow runs post-relogin | |
| Non-stopping with relogin prompt at end | Run all 7 steps end-to-end without pausing | |

**User's choice:** Pause after `capture_seed`.  
**Notes:** All configurations and unit files are placed on disk before relogin.

| Option | Description | Selected |
|--------|-------------|:--------:|
| Formatted banner + resume instructions | Bordered terminal box explaining session change, logout command, and resume command | ✓ |
| Interactive prompt | Press Enter to exit / c to continue | |
| Minimal output | Standard status lines only | |

**User's choice:** Formatted banner + resume instructions, with optional `--no-pause` flag for headless/CI.  
**Notes:** Provides clear guidance on why relogin is required and how to complete bootstrap.

| Option | Description | Selected |
|--------|-------------|:--------:|
| Runtime environment probe | Check `HYPRLAND_INSTANCE_SIGNATURE` & `configProvider: "lua"`; warn if in TTY | ✓ |
| Rely strictly on state file | Assume relogin occurred if Stage 1 complete | |
| Dual mode | Check static filesystem in TTY, compositor probe only in GUI | |

**User's choice:** Runtime environment probe.  
**Notes:** Verifies the session actually transitioned to Lua before running live checks.

| Option | Description | Selected |
|--------|-------------|:--------:|
| Stowed in Stage 1, enabled/started in Stage 2 | Link unit files in Stage 1; run `systemctl --user --now enable` in Stage 2 | ✓ |
| Defer all systemctl commands to Stage 2 | Only touch units in Stage 2 | |
| Enable lingering in Stage 1 | `loginctl enable-linger` to allow user bus in headless/TTY | |

**User's choice:** Stowed in Stage 1, enabled/started in Stage 2.  
**Notes:** Prevents `Failed to connect to bus` errors during pre-login/TTY bootstrap.

---

## Stow Package Orchestration & De-stubbing

| Option | Description | Selected |
|--------|-------------|:--------:|
| Dynamic directory enumeration | Iterate all directories in `stow/` and `restow/` with `--verbose=5 --no-folding -t ~` | ✓ |
| Explicit ordered manifest | Read package list from checked-in file | |
| Hardcoded bash array | Hardcode `STOW_PACKAGES` and `RESTOW_PACKAGES` | |

**User's choice:** Dynamic directory enumeration.  
**Notes:** Automatically manages any new package added to either tree without modifying script code.

| Option | Description | Selected |
|--------|-------------|:--------:|
| Detect via dry-run & backup to archive | Run `stow -n` to discover conflicts, back up to `~/.dotfiles-backup.<epoch>/`, remove stubs | ✓ |
| Preflight de-stub list | Rely strictly on `collision-map.tsv` destinations | |
| Prompt interactively | Prompt operator per conflict | |

**User's choice:** Detect via dry-run & backup to archive.  
**Notes:** Safely clears conflicts without violating the Phase 18 `--adopt` ban.

| Option | Description | Selected |
|--------|-------------|:--------:|
| `stow/` first, then `restow/` | Link non-colliding foundations first, then cp-through packages | ✓ |
| `restow/` first, then `stow/` | Link collision packages first | |
| Interleaved alphabetical | Alphabetical order across both trees | |

**User's choice:** `stow/` first, then `restow/`.  
**Notes:** Links clean packages before handling collision-exposed packages.

| Option | Description | Selected |
|--------|-------------|:--------:|
| Generic copy-seed with JSON validation | Mirror `capture/` to `$HOME`, validate JSON with `jq empty`, atomic temp-file replace | ✓ |
| Dedicated ii config.json copy | Hardcode `config.json` copy only | |
| Subcommand dispatch: `capture seed` | Dedicated subcommand | |

**User's choice:** Generic copy-seed with JSON validation.  
**Notes:** Future-proofs the capture tree if additional non-stowable files are added.

| Option | Description | Selected |
|--------|-------------|:--------:|
| Pre-create sensitive parent directories | `mkdir -p ~/.config/{gtk-3.0,gtk-4.0,hypr/custom,systemd/user}` before stow | ✓ |
| Rely entirely on `stow --no-folding` | Do not pre-create directories | |
| Pre-flight check only | Fail if directory symlinks exist | |

**User's choice:** Pre-create sensitive parent directories.  
**Notes:** Mechanically prevents directory-level symlinks even on pristine filesystems.

| Option | Description | Selected |
|--------|-------------|:--------:|
| Protect guarded paths | De-stubbing skips any path listed in `guard-paths.tsv` | ✓ |
| Assert guard-paths before/after | Fail immediately if guarded path targeted | |
| De-stub strictly by stow conflicts | Assume stow naturally excludes guarded paths | |

**User's choice:** Protect guarded paths.  
**Notes:** Leaves generated theme outputs (`kdeglobals`, `gtk.css`, `colors.lua`) untouched.

| Option | Description | Selected |
|--------|-------------|:--------:|
| Hierarchical mirror in `~/.dotfiles-backup.<epoch>/` | Full directory hierarchy matching `$HOME` + `MANIFEST.txt` | ✓ |
| Flat tarball | Package into `.tar.gz` | |
| Direct rename in place | Append `.bak.<epoch>` in place | |

**User's choice:** Hierarchical mirror in `~/.dotfiles-backup.<epoch>/`.  
**Notes:** Clean inspection and trivial manual rollback if needed.

| Option | Description | Selected |
|--------|-------------|:--------:|
| Pre-stow link sanitation | Detect and remove dangling or external symlinks for managed paths | ✓ |
| Native GNU Stow handling | Rely on stow native replacement | |
| Strict refusal | Fail if mismatched links exist | |

**User's choice:** Pre-stow link sanitation.  
**Notes:** Guarantees re-runs and recovery drills link cleanly and idempotently.

---

## Package Snapshots & Arch Script Coordination

| Option | Description | Selected |
|--------|-------------|:--------:|
| `arch/pkglist-native.txt` and `arch/pkglist-aur.txt` | Checked in under `arch/` with metadata headers, sorted alphabetically | ✓ |
| `pkg/native.txt` and `pkg/aur.txt` | Top-level `pkg/` directory | |
| `arch/packages.json` | Combined JSON file | |

**User's choice:** `arch/pkglist-native.txt` and `arch/pkglist-aur.txt`.  
**Notes:** Simple text lists compatible with standard pacman tools and clean git diffs.

| Option | Description | Selected |
|--------|-------------|:--------:|
| Dedicated `--snapshot` flag | Regenerates snapshots on demand without dirtying git status during normal runs | ✓ |
| Automatic regeneration on every run | Overwrite on every bootstrap run | |
| Verify-integrated drift check | Report missing/extra packages as [INFO] | |

**User's choice:** Dedicated `--snapshot` flag (`./bootstrap.sh --snapshot`).  
**Notes:** Keeps normal bootstrap runs non-dirtying for `verify --strict`.

| Option | Description | Selected |
|--------|-------------|:--------:|
| Essential foundation + upstream setup | Install `git`, `stow`, `jq`, `yay`; upstream handles shell deps; 34 scripts stay on-demand | ✓ |
| Batch install from snapshot | Feed full package lists to pacman/yay during bootstrap | |
| Curated core arch scripts | Run a subset of `arch/*.sh` scripts | |

**User's choice:** Essential foundation + upstream `./setup`.  
**Notes:** Scope is bounded to desktop shell reproduction without forcing installation of optional heavyweight tools.

| Option | Description | Selected |
|--------|-------------|:--------:|
| Scratch isolation harness + live verify check | Test de-stubbing, stow, state machine, and idempotence in scratch XDG fixture | ✓ |
| Container / systemd-nspawn | Full container testing | |
| Live-side drill only | Test directly on host | |

**User's choice:** Scratch isolation harness + live verify check.  
**Notes:** Meets fallback criteria (b) and (c) safely without risking host destruction.

---

## Claude's Discretion

- ANSI color codes and box formatting in the relogin instruction banner.
- Scratch directory naming conventions in `scripts/phase23-bootstrap-assert.sh`.
- Variable names for internal state helper routines.

## Deferred Ideas

- None.
