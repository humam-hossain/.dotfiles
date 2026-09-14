# Phase 21: ii-bar-config-capture - Research

**Researched:** 2026-09-15
**Domain:** Desktop Shell Configuration Capture, Systemd User Timers, Ingest Validation
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### JSON Validation & Atomic Ingest (`arch/dots-hyprland.sh capture` — BAR-01)

- **D-01:** Validation is format-generic based on file extension: any file ending in `*.json` is validated using `jq empty "$live"` before being copied to the repository mirror. — **Reversibility:** reversible
- **D-02:** Change-detection optimization: `run_capture` runs `cmp -s "$live" "$repo_file"` before validation. If the live file is byte-identical to the repository mirror, capture immediately skips it as a no-op, avoiding unnecessary disk writes and redundant `jq` subprocess forks every 15 minutes. — **Reversibility:** reversible
- **D-03:** Validation failure behavior: If `jq empty "$live"` fails or the file is 0 bytes (truncated write race), `run_capture` logs `[FAIL] invalid or empty JSON: $live`, leaves the repository mirror untouched, skips the file, and marks the run non-zero so the skipped capture is reported without destroying clean repository history. — **Reversibility:** reversible
- **D-04:** Raw formatting preservation: `capture` preserves raw file bytes and mtime via `cp -p`. No reformatting (e.g. `jq '.'`) is performed, avoiding synthetic diff churn against Quickshell's internal 4-space indented serializer. — **Reversibility:** reversible
- **D-05:** Atomic write into git working tree: File copies into the repository use a temporary file rename: `cp -p -- "$live" "$repo_file.tmp.$$" && mv -f "$repo_file.tmp.$$" "$repo_file"`. This guarantees the git working tree never observes a partial or half-written file if the capture process is interrupted. — **Reversibility:** reversible
- **D-06:** Check pipeline order: For each capturable file, `run_capture` evaluates in order: (1) resolved path security check under `capture/`, (2) `mirror_is_capturable` (repo mirror exists, tracked, clean against HEAD), (3) live path symlink refusal, (4) live path existence, (5) `cmp -s` change check, (6) format validation (`jq empty`), (7) atomic temp-file copy. — **Reversibility:** reversible
- **D-07:** `verify` remains content-diff focused: `run_verify` continues to perform link-identity and content-diff verification (`diff -u "$live" "$canonical_repo"`) without adding JSON-specific syntax parsing to `verify`. Format validation remains an ingest-time gate in `run_capture`. — **Reversibility:** reversible

#### Systemd Timer & Service Configuration (`dotfiles-capture.timer` & `service` — CAP-06)

- **D-08:** Timer cadence: `dotfiles-capture.timer` runs every 15 minutes: `OnUnitActiveSec=15m`, `OnStartupSec=2m`, `Persistent=true`, attached to `WantedBy=timers.target`. Missed runs while the system is powered down or suspended are caught up on boot. — **Reversibility:** reversible
- **D-09:** Service unit definition: `dotfiles-capture.service` is a `Type=oneshot` service executing `%h/github_repo/.dotfiles/arch/dots-hyprland.sh capture --quiet --notify` with `WorkingDirectory=%h/github_repo/.dotfiles`. — **Reversibility:** reversible
- **D-10:** Process priority & timeouts: Configured with `Nice=19`, `TimeoutStartSec=30s`, `StandardOutput=journal`, `StandardError=journal`, and `SyslogIdentifier=dotfiles-capture`. — **Reversibility:** reversible
- **D-11:** Service exit status: Configured with `SuccessExitStatus=0 1`. When `run_capture` skips dirty repository mirrors or invalid live files (which legitimately return exit code 1 per D-36/D-43), systemd does not mark the service in a red failed state, but full details remain recorded in `journalctl --user -u dotfiles-capture`. — **Reversibility:** reversible
- **D-12:** Display environment & notification dispatch: The service unit specifies `PassEnvironment=WAYLAND_DISPLAY DISPLAY DBUS_SESSION_BUS_ADDRESS`. In `run_capture`, notifications use dots-hyprland style: `notify-send "Dotfiles Capture" "Captured updates to repository" -a "Shell" -u low` executed with `|| true` so display or daemon errors are non-fatal and never abort the sync. — **Reversibility:** reversible
- **D-13:** Flag surface in `run_capture`: Accepts `--quiet` (suppresses passing/noop logs, outputs only changes or errors) and `--notify` (dispatches desktop notification only when `captured_count > 0`). Manual terminal CLI runs without `--notify` remain purely text-based. — **Reversibility:** reversible
- **D-14:** Single source of truth & enablement: Both unit files are authored in `stow/systemd/.config/systemd/user/`. `arch/hyprland.sh` enables and starts the timer: `systemctl --user daemon-reload && systemctl --user enable --now dotfiles-capture.timer && systemctl --user restart dotfiles-capture.timer`. — **Reversibility:** reversible

#### Bar Settings Baseline & Package Layout (`capture/ii/` — BAR-02)

- **D-15:** Package tree hierarchy: `config.json` resides at `capture/ii/.config/illogical-impulse/config.json`. This strictly complies with Phase 18's D-38 contract where `capture/<pkg>/<rel_to_home>` maps to `$HOME/<rel_to_home>`. — **Reversibility:** costly — changing directory structure breaks `run_capture` path resolution.
- **D-16:** Baseline adoption: The current live `~/.config/illogical-impulse/config.json` is adopted as the initial baseline in `capture/ii/`, locking active preferences (top horizontal bar, spark icon, Dhaka weather, 5 workspaces, mic/snip utility toggles). — **Reversibility:** reversible
- **D-17:** Scope exclusion: Only `config.json` is tracked in `capture/ii/`. Upstream installer state files (`installed_listfile`, `installed_true`) and runtime directories (`actions/`) are deliberately excluded from the repository. — **Reversibility:** reversible
- **D-18:** Defaults-reset recovery drill (BAR-02): Verification creates a timestamped backup (`config.json.bak.<epoch>`), resets live `config.json` to an empty state, restores the file from `capture/ii/`, reloads `qs -c ii`, and asserts all bar settings are reproduced. — **Reversibility:** reversible

#### Live Wallpaper Verification & Assert Harness (BAR-01)

- **D-19:** Two-stage verification: First stage executes in an isolated temporary `$XDG_CONFIG_HOME` scratch environment to prove `switchwall.sh:147`'s `jq ... > tmp && mv` destroys a symlink and that `capture` handles the resulting plain file. Second stage performs a live confirmation against the running desktop. — **Reversibility:** reversible
- **D-20:** Non-disruptive production wallpaper test: The live confirmation triggers `switchwall.sh` using the current wallpaper (`/home/pera/Pictures/55192173787_b8322b1190_o.jpg`). This exercises the exact `mv` rename and theme generation code paths without changing desktop visuals. Generated theme modifications (`kdeglobals`, `colors.lua`, `hyprlock/colors.conf`) are recorded in verification notes to settle Q7/Q8 for Phase 22, then cleanly reverted via `git checkout`. — **Reversibility:** reversible
- **D-21:** Comprehensive assert script: `scripts/phase21-ii-bar-config-capture-assert.sh` gates the phase by validating JSON syntax checking, timer activation, service triggers, git status output, `arch/dots-hyprland.sh verify --strict` pass, and the isolated scratch drill. — **Reversibility:** reversible

### Claude's Discretion

- Exact temporary filename patterns and cleanup trap implementations in `run_capture`.
- Specific assertion helper functions and stderr/stdout formatting in `scripts/phase21-ii-bar-config-capture-assert.sh`.

### Deferred Ideas (OUT OF SCOPE)

- Phase 22: KDE and GTK capture (`kdeglobals`, `dolphinrc`, `gtk-3.0/settings.ini`).
- Phase 23: One-command full bootstrap orchestration (`BOOT-01`–`BOOT-05`).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| **BAR-01** | `~/.config/illogical-impulse/config.json` is captured through `capture/`, and capture survives a wallpaper change (`switchwall.sh` renames over the path) | Verified `switchwall.sh:147`'s `jq ... > tmp && mv` destroys symlinks by replacing the inode; verified Quickshell's internal `FileView`/`JsonAdapter` writes through symlinks leaving them intact; established `capture/ii/.config/illogical-impulse/config.json` stow-relative hierarchy; added `cmp -s` pre-check, format-generic JSON validation (`jq empty`), non-zero size test, and atomic replace (`cp -p ... && mv -f`) in `run_capture`. |
| **BAR-02** | Personal bar settings reachable through `config.json` — position, style, auto-hide, utility buttons, workspaces, weather — are set deliberately and reproduce from the repo | Verified live settings in `~/.config/illogical-impulse/config.json` (top horizontal bar, spark icon, Dhaka weather, 5 workspaces, utility buttons: mic/snip toggles); verified scope exclusion of installer state files (`installed_listfile`, `installed_true`); designed timestamped backup drill (`config.json.bak.<epoch>`) and defaults-reset recovery with `qs -c ii`. |
| **CAP-06** | `capture` runs unattended on a systemd user timer, so `capture/` paths need no manual sync | Authored stow-managed `dotfiles-capture.service` and `dotfiles-capture.timer` under `stow/systemd/.config/systemd/user/` with 15m cadence (`OnUnitActiveSec=15m`, `OnStartupSec=2m`, `Persistent=true`, `WantedBy=timers.target`), `Nice=19`, `SuccessExitStatus=0 1`, and `PassEnvironment`; added `--quiet` and `--notify` flag surface to `run_capture` with dots-hyprland notification style; wired enablement into `arch/hyprland.sh`. |
</phase_requirements>

## Summary

Phase 21 establishes the first resident in the repository's copy-based `capture/` tree: Quickshell's (`ii`) desktop configuration file, located at `capture/ii/.config/illogical-impulse/config.json`. This phase proves the fundamental architectural justification for the `capture/` tree (as opposed to GNU Stow symlinks in `stow/` or `restow/`), implements format-generic ingest validation and change-detection optimizations in `arch/dots-hyprland.sh capture`, provisions an automated 15-minute systemd user timer (`dotfiles-capture.timer`), establishes the operator's deliberate personal bar baseline, and verifies that bar settings survive both desktop configuration changes and wallpaper switches.

The core technical justification for placing `config.json` in `capture/` rather than `stow/` was tested empirically in this research session:
1. **Experiment Q1 (Quickshell GUI settings panel):** A scratch experiment using `qs -p` confirmed that Quickshell's internal `FileView` / `JsonAdapter` mechanism writes through symbolic links without breaking them [VERIFIED: live experiment with `qs 0.2.1`]. Setting changes made via the graphical configuration panel preserve symlink identity.
2. **Experiment Q2 (Wallpaper switcher script):** Upstream's wallpaper switching script at [vendor/dots-hyprland/dots/.config/quickshell/ii/scripts/colors/switchwall.sh:147](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/quickshell/ii/scripts/colors/switchwall.sh#L147) executes `jq --arg path "$path" '.background.wallpaperPath = $path' "$SHELL_CONFIG_FILE" > "$SHELL_CONFIG_FILE.tmp" && mv "$SHELL_CONFIG_FILE.tmp" "$SHELL_CONFIG_FILE"`. The `mv` command issues a `rename()` syscall over the target path. An empirical test confirmed that `rename()` severs a symlink by unlinking the link directory entry and replacing it with the new inode of the temporary file, leaving the repository target completely detached [VERIFIED: live experiment].
3. **Requirement Wording Clarification:** D-41 and earlier requirements attributed the symlink destruction to "atomic writes" by Quickshell. This was factually imprecise: Qt/Quickshell's `FileView` preserves symlinks; it is the shell script `switchwall.sh:147`'s `mv` invocation that severs symlinks. The `capture/` model is strictly required to accommodate this external script.

**Primary recommendation:** Implement `run_capture` enhancements (flags `--quiet` and `--notify`, `cmp -s` fast-path, `[[ -s "$live" ]] && jq empty "$live"` validation, atomic temp-file replace), commit the deliberate personal baseline at `capture/ii/.config/illogical-impulse/config.json`, install and enable `dotfiles-capture.timer` via `stow/systemd/` and `arch/hyprland.sh`, and gate the phase with a comprehensive assert script (`scripts/phase21-ii-bar-config-capture-assert.sh`).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Shell Config Persistence | Live OS Filesystem (`~/.config/illogical-impulse/`) | Application (`Quickshell / ii`) | Quickshell and helper scripts read/write live JSON state during session runtime. |
| Symlink Invalidation Detection | Live Shell Scripts (`switchwall.sh`) | Kernel / VFS (`rename()`) | `switchwall.sh:147` executes `mv "$F.tmp" "$F"`, which atomically overwrites directory entries and replaces symlinks with plain files. |
| Live-to-Repo Capture Ingest | CLI Wrapper (`arch/dots-hyprland.sh capture`) | Git Working Tree (`capture/ii/`) | Evaluates path security, tests mirror cleanliness, verifies file integrity, and copies live changes into git working tree without auto-commit. |
| Ingest Validation & Guarding | CLI Wrapper (`jq empty`, `cmp -s`, `test -s`) | Local Tools (`/usr/bin/jq`) | Fails closed on 0-byte or corrupted JSON, preventing corrupted runtime state from polluting the repository mirror. |
| Automated Capture Scheduling | OS Init / Scheduler (`systemd --user`) | CLI Wrapper (`dotfiles-capture.service`) | Triggers periodic 15-minute background syncs with low priority (`Nice=19`) and displays non-intrusive notifications on active updates. |
| Drift & Link Verification | CLI Verifier (`arch/dots-hyprland.sh verify`) | Git / Repo Storage | Inverted verification contract: ensures live capture paths are plain files (never symlinks into repo) and detects content drift. |

## Standard Stack

### Core
| Tool / Component | Version | Purpose | Why Standard |
|------------------|---------|---------|--------------|
| `jq` | 1.8.2 [VERIFIED: `jq --version`] | Format-generic JSON validation (`jq empty "$live"`) | Standard POSIX tool for streaming JSON parsing and validation; exits non-zero on syntax errors [VERIFIED: in-repo test]. |
| `GNU Stow` | 2.4.1 [VERIFIED: `stow --version`] | Package symlink management for systemd user units | Established project package manager; stows `stow/systemd/` into `~/.config/systemd/user/` with `--no-folding` [VERIFIED: `arch/hyprland.sh:42`]. |
| `systemd --user` | 258.4 [VERIFIED: `systemctl --version`] | Scheduled background capture execution (`.timer` + `.service`) | Native Linux daemon for user session background jobs with journal logging, retry semantics, and low resource priority (`Nice=19`). |
| `quickshell` | 0.2.1 [VERIFIED: `qs --version`] | Desktop shell environment (`ii`) | Active Wayland desktop shell running on the host system, managing bar widgets and reading `config.json`. |
| `libnotify` (`notify-send`) | 0.8.8 [VERIFIED: `notify-send --version`] | User notification on active captures | Native desktop notification dispatcher communicating with `swaync` over D-Bus [VERIFIED: in-repo test]. |
| `cmp` | GNU diffutils [VERIFIED: `command -v cmp`] | Fast change detection (`cmp -s "$live" "$repo_file"`) | High-performance byte comparison avoiding unnecessary disk I/O and subprocess forks when files have not drifted. |

### Supporting
| Tool / Component | Version | Purpose | When to Use |
|------------------|---------|---------|-------------|
| `matugen` | 4.2.0 [VERIFIED: `matugen --version`] | Material You color palette generation | Triggered by `switchwall.sh` during wallpaper change; updates generated theme outputs. |
| `bash` | 5.3.3 [VERIFIED: `bash --version`] | Scripting runtime for wrapper and asserts | Standard project shell runtime using `set -euo pipefail`. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Copy-based `capture/` tree | GNU Stow symlink | **Rejected:** `switchwall.sh:147` executes `mv "$F.tmp" "$F"` on wallpaper changes, which severs symlinks by replacing the directory entry with a regular file inode. Symlinks cannot survive. |
| Raw copy (`cp -p`) | Pretty-printed JSON (`jq '.' > repo`) | **Rejected (D-04):** Synthesizing formatted output creates synthetic diff churn against Quickshell's internal 4-space serializer. Raw bytes and mtimes must be preserved. |
| Ingest validation (`jq empty`) | Verification-time validation (`verify`) | **Rejected (D-07):** Ingest validation gates bad writes before they hit git. `verify` is diff-focused (`cmp -s`) and must remain fast, read-only, and format-agnostic. |
| Periodic systemd timer | Filesystem watcher (`inotifywait` / `systemd.path`) | **Rejected:** Persistent file-watching services consume resident memory, risk infinite event loops when writing, and don't handle batching gracefully. A 15-minute timer with `cmp -s` is virtually zero-cost. |

## Package Legitimacy Audit

No external packages (npm, PyPI, crates) are installed in Phase 21. All required CLI utilities (`jq`, `systemctl`, `stow`, `notify-send`, `cmp`, `qs`, `matugen`) are already installed and verified on the host system.

## Architecture Patterns

### System Architecture Diagram

```mermaid
flowchart TD
    subgraph Live Desktop Session
        QS[Quickshell ii Bar] -->|Reads/Writes| LIVE_CFG["~/.config/illogical-impulse/config.json\n(Plain File)"]
        SW[switchwall.sh] -->|jq > tmp && mv| LIVE_CFG
        SW -->|Calls| MAT[matugen & applycolor.sh]
        MAT -->|Generates| THEME_OUT["kdeglobals, colors.lua, hyprlock"]
    end

    subgraph Systemd User Scheduler
        TIMER["dotfiles-capture.timer\n(Every 15m)"] -->|Triggers| SVC["dotfiles-capture.service\n(Type=oneshot, Nice=19)"]
        SVC -->|Executes| WRAPPER["arch/dots-hyprland.sh capture --quiet --notify"]
    end

    subgraph Capture Ingest Pipeline
        WRAPPER --> SEC_CHECK{"Resolved Path Guard\n(Under capture/?)"}
        SEC_CHECK -->|Pass| CAP_CHECK{"mirror_is_capturable?\n(Tracked & Clean against HEAD)"}
        CAP_CHECK -->|Pass| SYM_CHECK{"Live is Symlink to Repo?"}
        SYM_CHECK -->|No| EXIST_CHECK{"Live File Exists?"}
        EXIST_CHECK -->|Yes| CMP_CHECK{"cmp -s live repo\n(Byte-identical?)"}
        CMP_CHECK -->|Different| VAL_CHECK{"Format Validation\n(jq empty && test -s)"}
        VAL_CHECK -->|Valid| ATOMIC_COPY["Atomic Replace\ncp -p live repo.tmp.$$\nmv -f repo.tmp.$$ repo"]
        ATOMIC_COPY --> NOTIFY{"--notify and\ncaptured_count > 0?"}
        NOTIFY -->|Yes| NOTIFY_SEND["notify-send (Low Urgency)"]
    end

    subgraph Git Repository
        ATOMIC_COPY -->|Writes into| REPO_CFG["capture/ii/.config/illogical-impulse/config.json\n(Unstaged Working Tree)"]
    end

    CMP_CHECK -->|Identical| NOOP["Skip (No-op)"]
    CAP_CHECK -->|Dirty/Untracked| SKIP_DIRTY["Skip (Preserve Repo State)"]
    VAL_CHECK -->|Corrupt/0-byte| FAIL_VALIDATION["[FAIL] Leave Repo Untouched"]
```

### Recommended Project Structure

```
/home/pera/github_repo/.dotfiles/
├── arch/
│   ├── dots-hyprland.sh               # run_capture enhanced with --quiet, --notify, cmp -s, jq empty, atomic replace
│   └── hyprland.sh                    # Enables & starts dotfiles-capture.timer
├── capture/
│   ├── README.md                      # Three-tree capture documentation
│   └── ii/
│       └── .config/
│           └── illogical-impulse/
│               └── config.json        # Tracked repository mirror of personal bar settings
├── stow/
│   └── systemd/
│       └── .config/
│           └── systemd/
│               └── user/
│                   ├── hyprland-session.service  # Existing session bootstrap unit
│                   ├── dotfiles-capture.service  # Oneshot capture execution service
│                   └── dotfiles-capture.timer    # 15-minute scheduled timer unit
└── scripts/
    └── phase21-ii-bar-config-capture-assert.sh   # Comprehensive Phase 21 assertion harness
```

### Pattern 1: Format-Generic Ingest Validation & Atomic Replace (BAR-01)
**What:** Validates live files before copying to git working tree mirrors and commits the copy via a temporary file rename.
**When to use:** Any capture operation from live `$HOME` into the repository working tree.
**Example:**
```bash
# Ingest pipeline within run_capture()
if [[ "$live" == *.json ]]; then
  # Pitfall: jq empty on 0 bytes returns 0; must check test -s explicitly
  if [[ ! -s "$live" ]] || ! jq empty "$live" >/dev/null 2>&1; then
    fail "invalid or empty JSON: $live"
    continue
  fi
fi

# Change detection: skip if byte-identical
if cmp -s -- "$live" "$repo_file"; then
  ((quiet == 0)) && info "unchanged: $live"
  continue
fi

# Atomic write via temporary file rename
local tmp_repo="${repo_file}.tmp.$$"
if cp -p -- "$live" "$tmp_repo" && mv -f -- "$tmp_repo" "$repo_file"; then
  pass "captured: $live -> $repo_file"
  captured_count=$((captured_count + 1))
else
  rm -f -- "$tmp_repo" 2>/dev/null || true
  fail "failed to write repo mirror: $repo_file"
fi
```

### Pattern 2: Stow-Managed Systemd User Timer with Display Passthrough (CAP-06)
**What:** Systemd user timer and oneshot service unit deploying low-priority background sync with display environment variables passed for desktop notifications.
**When to use:** Automated periodic synchronization tasks that need to interact with the graphical user session.
**Example:**
```ini
# stow/systemd/.config/systemd/user/dotfiles-capture.service
[Unit]
Description=Capture dotfiles from live environment to repository mirror
Documentation=file://%h/github_repo/.dotfiles/capture/README.md

[Service]
Type=oneshot
WorkingDirectory=%h/github_repo/.dotfiles
ExecStart=%h/github_repo/.dotfiles/arch/dots-hyprland.sh capture --quiet --notify
Nice=19
TimeoutStartSec=30s
StandardOutput=journal
StandardError=journal
SyslogIdentifier=dotfiles-capture
PassEnvironment=WAYLAND_DISPLAY DISPLAY DBUS_SESSION_BUS_ADDRESS
SuccessExitStatus=0 1

# stow/systemd/.config/systemd/user/dotfiles-capture.timer
[Unit]
Description=Periodic capture of live dotfiles to repository mirror
Documentation=file://%h/github_repo/.dotfiles/capture/README.md

[Timer]
OnStartupSec=2m
OnUnitActiveSec=15m
Persistent=true

[Install]
WantedBy=timers.target
```

### Anti-Patterns to Avoid
- **Symlinking `config.json`:** Running `stow` on `config.json` creates a symlink from `~/.config/illogical-impulse/config.json` into the repo. The first time the operator changes wallpaper via `switchwall.sh`, the symlink is destroyed by `mv "$SHELL_CONFIG_FILE.tmp" "$SHELL_CONFIG_FILE"`, breaking synchronization silently [VERIFIED: live experiment].
- **Auto-staging or Auto-committing:** Running `git add` or `git commit` in `capture` destroys operator review and risks committing transient test changes or secrets (violating CAP-05 and D-38).
- **Relying Solely on `jq empty` Without `-s` Test:** `jq empty` on an empty 0-byte file exits with status 0! An interrupted write or truncated file will pass `jq empty` unless guarded by `[[ ! -s "$live" ]]` [VERIFIED: live experiment].
- **Formatting JSON via `jq '.'`:** Reformatting the JSON during capture alters formatting and causes massive synthetic git diffs every time Quickshell's internal serializer (which uses 4-space indent) touches the file (violating D-04).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Ingest Syntax Check | Custom regex / python validator | `/usr/bin/jq empty "$live"` + `[[ -s "$live" ]]` | `jq` is the canonical JSON parser on the system; handles all edge cases, escape characters, Unicode, and formatting variants. |
| Change Detection | Shell checksum loop (`sha256sum`) | `/usr/bin/cmp -s "$live" "$repo_file"` | `cmp` exits on the first differing byte; orders of magnitude faster than hashing large files. |
| Job Scheduling | Background daemon loop with `sleep` | `systemd --user` `.timer` and `.service` | Systemd handles missed wakeups after sleep/hibernation (`Persistent=true`), logging to journald, exit status tracking, and resource isolation (`Nice=19`). |
| In-Place File Update | Direct write `cat live > repo` | Atomic temp-file copy: `cp -p ... tmp && mv -f tmp target` | Direct redirection risks leaving partial/corrupt files in the git working tree if killed mid-operation. |

**Key insight:** The `capture/` tree exists precisely because external tools use filesystem rename primitives (`rename()`) that replace symbolic links. Respecting filesystem semantics by using atomic replacement and format validation protects the integrity of git history.

## Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| **Stored data** | Live `~/.config/illogical-impulse/config.json` (17.5 KB, 580 lines, 4-space indent). Contains active personal preferences: top bar, spark icon, Dhaka weather, 5 workspaces. [VERIFIED: `~/.config/illogical-impulse/config.json:1-580`] | Code edit / Ingest: Copy to `capture/ii/.config/illogical-impulse/config.json` and track in git. Exclude `installed_listfile` (77 KB) and `installed_true` (0 bytes). |
| **Live service config** | Active Quickshell instance PID 1503 running `qs -c ii` [VERIFIED: `qs list --all`]. | Live reload test: Assert settings reproduction upon reloading Quickshell (`qs kill -c ii && qs -d -c ii` or restart). |
| **OS-registered state** | `systemd --user` units: `dotfiles-capture.service` and `dotfiles-capture.timer` to be registered under `~/.config/systemd/user/` and enabled via `systemctl --user`. | Code edit / System registration: Stow `stow/systemd/`, run `systemctl --user daemon-reload`, and `systemctl --user enable --now dotfiles-capture.timer`. |
| **Secrets/env vars** | `config.json` contains OpenRouter model configuration stub: `model: deepseek/deepseek-r1-distill-llama-70b:free` with `key_id: "openrouter"`, but no plaintext API secret key is embedded [VERIFIED: `~/.config/illogical-impulse/config.json:2-16`]. | Verification check: Phase 18 secret scan (`FIX-06`) confirmed clean; verify no API secrets in baseline commit. |
| **Build artifacts** | Generated theme artifacts in `~/.local/state/quickshell/user/generated/` and `~/.config/hypr/hyprland/colors.lua` modified when `switchwall.sh` runs [VERIFIED: `~/.config/matugen/config.toml:1-35`]. | Verification hygiene: Clean git working tree before live wallpaper verification drill and cleanly revert generated changes via `git checkout`. |

## Common Pitfalls

### Pitfall 1: `jq empty` Exits 0 on 0-Byte Files
**What goes wrong:** If Quickshell or an external script crashes mid-write, `config.json` may be left as a 0-byte truncated file. If `run_capture` runs `jq empty "$live"`, `jq` evaluates EOF as valid zero-stream input and returns exit code 0! The 0-byte file would then overwrite the repository mirror, destroying git history.
**Why it happens:** In `jq`, `empty` takes an input and produces zero outputs. With zero input items (empty stream / 0 bytes), zero output is produced, which evaluates to success (exit 0) [VERIFIED: live experiment].
**How to avoid:** Always pair `jq empty` with a file size check: `[[ ! -s "$live" ]] || ! jq empty "$live" 2>/dev/null`.
**Warning signs:** Empty files passing validation and appearing in `git status`.

### Pitfall 2: `switchwall.sh` Destroys Symlinks via `rename()`
**What goes wrong:** If `~/.config/illogical-impulse/config.json` is stowed as a symlink pointing into the repo, running `switchwall.sh` breaks the symlink, turning `config.json` into an unlinked regular file. Edits in the GUI then no longer propagate to the repo, and git thinks the file was removed.
**Why it happens:** At [vendor/dots-hyprland/dots/.config/quickshell/ii/scripts/colors/switchwall.sh:147](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/quickshell/ii/scripts/colors/switchwall.sh#L147), the script runs `mv "$SHELL_CONFIG_FILE.tmp" "$SHELL_CONFIG_FILE"`. In Linux, the `rename` syscall removes the destination directory entry (the symlink) and replaces it with the temporary file inode [VERIFIED: live experiment].
**How to avoid:** Never stow `config.json`. Keep it in `capture/` as an unlinked plain file that is synchronized into git by `run_capture`.
**Warning signs:** `test -L ~/.config/illogical-impulse/config.json` failing after a wallpaper change.

### Pitfall 3: Directory Traversal Path Mismatch (`capture/ii/config.json` vs `capture/ii/.config/...`)
**What goes wrong:** The phase summary notes `capture/ii/config.json`, but `arch/dots-hyprland.sh:1467-1468` derives live paths as `rel="${repo_file#"$pkg_dir"/}"` and `live="$HOME/$rel"`. If placed at `capture/ii/config.json`, `run_capture` looks for `$HOME/config.json` instead of `$HOME/.config/illogical-impulse/config.json`.
**Why it happens:** Phase 18 established the stow-relative package structure across all three trees: `capture/<pkg>/<rel_to_home>`.
**How to avoid:** Store the file strictly at `capture/ii/.config/illogical-impulse/config.json` (D-15) [VERIFIED: `arch/dots-hyprland.sh:1464-1469`].
**Warning signs:** `run_capture` logging `live counterpart missing: /home/pera/config.json`.

### Pitfall 4: Phase 18 Closed Assert False Failure
**What goes wrong:** Running `scripts/phase18-capture-model-assert.sh` lines 921-926 checks if the real repository's `capture/` tree is empty (`grep -q "capture/ is empty"`). Once `capture/ii/` is added, this check fails if Phase 18's script is re-run.
**Why it happens:** Phase 18 was closed when `capture/` was legitimately empty. The assertion checked the real tree state at that historical moment.
**How to avoid:** Document that Phase 18 asserts were scoped to Phase 18's milestone state. Do not modify closed assert scripts (per Phase 18 F-11); Phase 21 asserts own the populated tree checks.

### Pitfall 5: Systemd Unit Notification Failures in Headless / Non-Graphical Contexts
**What goes wrong:** When `dotfiles-capture.service` runs via systemd timer, `notify-send` fails because standard systemd user services do not inherit graphical display environment variables by default.
**Why it happens:** Systemd user manager runs independently of the Wayland compositor and doesn't know `$WAYLAND_DISPLAY` or `$DBUS_SESSION_BUS_ADDRESS` unless passed.
**How to avoid:** Add `PassEnvironment=WAYLAND_DISPLAY DISPLAY DBUS_SESSION_BUS_ADDRESS` to the service unit, and ensure all notification dispatches inside `run_capture` append `|| true` (D-12).

## Code Examples

### In-Repo Verification: `switchwall.sh:147` Symlink Destruction
[VERIFIED: vendor/dots-hyprland/dots/.config/quickshell/ii/scripts/colors/switchwall.sh:144-149]
```bash
set_wallpaper_path() {
    local path="$1"
    if [ -f "$SHELL_CONFIG_FILE" ]; then
        jq --arg path "$path" '.background.wallpaperPath = $path' "$SHELL_CONFIG_FILE" > "$SHELL_CONFIG_FILE.tmp" && mv "$SHELL_CONFIG_FILE.tmp" "$SHELL_CONFIG_FILE"
    fi
}
```

### In-Repo Verification: `run_capture` Live-to-Repo Path Derivation
[VERIFIED: arch/dots-hyprland.sh:1464-1469]
```bash
  for pkg_dir in "${packages[@]}"; do
    pkg="$(basename "$pkg_dir")"
    while IFS= read -r -d '' repo_file; do
      rel="${repo_file#"$pkg_dir"/}"
      live="$HOME/$rel"
```

### In-Repo Verification: `mirror_is_capturable` Guard
[VERIFIED: arch/dots-hyprland.sh:1440-1455]
```bash
  mirror_is_capturable() {
    local p="$1"
    if [[ ! -e "$p" ]]; then
      finding "repo mirror does not exist: $p"
      return 1
    fi
    if ! git ls-files --error-unmatch -- "$p" >/dev/null 2>&1; then
      finding "repo mirror is untracked (no HEAD version to recover): $p"
      return 1
    fi
    if ! git diff --quiet HEAD -- "$p"; then
      finding "repo mirror is dirty against HEAD: $p"
      return 1
    fi
    return 0
  }
```

### In-Repo Verification: Systemd Stow Point in `arch/hyprland.sh`
[VERIFIED: arch/hyprland.sh:41-44]
```bash
echo "[CONFIG] Graphical Session Bootstrap (systemd xdg-desktop-portal fix)"
cd "$REPO_ROOT/stow" && stow --verbose=5 --no-folding -t ~ systemd
systemctl --user daemon-reload || true
```

### In-Repo Verification: Quickshell `FileView` Configuration Loader
[VERIFIED: vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/Config.qml:64-77]
```qml
    FileView {
        id: configFileView
        path: root.filePath
        watchChanges: true
        blockWrites: root.blockWrites
        onFileChanged: fileReloadTimer.restart()
        onAdapterUpdated: fileWriteTimer.restart()
        onLoaded: root.ready = true
        onLoadFailed: error => {
            if (error == FileViewError.FileNotFound) {
                writeAdapter();
            }
        }
```

### In-Repo Verification: Matugen Theme Outputs
[VERIFIED: ~/.config/matugen/config.toml:8-15]
```toml
[templates.hyprland]
input_path = '~/.config/matugen/templates/hyprland/colors.lua'
output_path = '~/.config/hypr/hyprland/colors.lua'

[templates.hyprlock]
input_path = '~/.config/matugen/templates/hyprland/hyprlock-colors.conf'
output_path = '~/.config/hypr/hyprlock/colors.conf'
```

### In-Repo Verification: Live Bar Settings
[VERIFIED: ~/.config/illogical-impulse/config.json:200-245]
```json
    "bar": {
        "autoHide": {
            "enable": false,
            "hoverRegionWidth": 2,
            "pushWindows": false,
            "showWhenPressingSuper": {
                "delay": 140,
                "enable": true
            }
        },
        "borderless": false,
        "bottom": false,
        "cornerStyle": 0,
        "floatStyleShadow": true,
        "topLeftIcon": "spark",
        "utilButtons": {
            "showColorPicker": true,
            "showDarkModeToggle": false,
            "showKeyboardToggle": true,
            "showMicToggle": true,
            "showPerformanceProfileToggle": true,
            "showScreenRecord": false,
            "showScreenSnip": true
        },
        "weather": {
            "city": "Dhaka",
            "enable": true,
            "enableGPS": false,
            "fetchInterval": 10,
            "useUSCS": false
        },
        "workspaces": {
            "alwaysShowNumbers": true,
            "monochromeIcons": true,
            "numberMap": [],
            "showAppIcons": true,
            "showNumberDelay": 300,
            "shown": 5,
            "useNerdFont": false
        }
    }
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Assumption that Quickshell "atomic writes" break symlinks | Verified that `FileView` preserves symlinks; only `switchwall.sh:147`'s `mv` destroys them | Phase 21 Research (2026-09-15) | Clarified justification for `capture/` exception; documents the precise filesystem mechanism. |
| Manual CLI sync (`./arch/dots-hyprland.sh capture`) | Unattended systemd user timer (`dotfiles-capture.timer`) with low priority (`Nice=19`) | Phase 21 (CAP-06) | Captures live config drifts every 15m without human intervention or manual sync commands. |
| Unconditional file copying on capture | `cmp -s` fast-path skipping unchanged files before JSON validation | Phase 21 (D-02) | Eliminates disk writes and `jq` forks during periodic timer runs when no config changes occurred. |
| Empty `capture/` tree (`README.md` only) | Inhabited `capture/ii/.config/illogical-impulse/config.json` | Phase 21 (BAR-01) | Establishes the first real dotfile resident in the copy-based capture tree. |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `switchwall.sh` triggers in live desktop without disrupting display when called with current wallpaper path (`55192173787_b8322b1190_o.jpg`) | Live Wallpaper Verification | Low; visually verified wallpaper is identical; generated theme files are cleanly reverted via git checkout. |
| A2 | Quickshell reload via `qs kill -c ii && qs -d -c ii` reproduces UI without full session logout | Defaults-Reset Recovery | Low; Quickshell is designed as a modular standalone Wayland shell client that restarts cleanly. |

## Open Questions

None. All technical questions regarding `FileView` symlink behavior, `switchwall.sh:147` `mv` symlink destruction, JSON validation edge cases, and systemd user timer integration were resolved empirically during this research session.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `jq` | Ingest JSON validation | ✓ | 1.8.2 | — (Core dependency, present) |
| `systemd` / `systemctl` | Unattended capture scheduling | ✓ | 258.4 | Cron or manual capture |
| `stow` | Package symlinking | ✓ | 2.4.1 | Manual symlinking |
| `quickshell` (`qs`) | Bar runtime & restart drill | ✓ | 0.2.1 | — |
| `notify-send` | Desktop notifications | ✓ | 0.8.8 | Silent console logging |
| `cmp` | Byte-level drift check | ✓ | GNU diffutils | `diff -q` |
| `matugen` | Color generation in `switchwall.sh` | ✓ | 4.2.0 | — |
| `python3` | Submodule scripts | ✓ | 3.14.7 | — |

**Missing dependencies with no fallback:** None.
**Missing dependencies with fallback:** None.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Bash Test Harness (`scripts/phase21-ii-bar-config-capture-assert.sh`) |
| Config file | None (self-contained executable assert script) |
| Quick run command | `./scripts/phase21-ii-bar-config-capture-assert.sh --section <1-7>` |
| Full suite command | `./scripts/phase21-ii-bar-config-capture-assert.sh && ./arch/dots-hyprland.sh verify --strict` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| **BAR-01** | Ingest validation (`jq empty`, 0-byte check), atomic copy, symlink refusal, and dirty repo mirror skip | integration / unit | `./scripts/phase21-ii-bar-config-capture-assert.sh --section 1` | ❌ Wave 0 Gap |
| **BAR-01** | Scratch XDG drill proving `switchwall.sh:147` `mv` destroys link & `capture` picks up plain file | integration | `./scripts/phase21-ii-bar-config-capture-assert.sh --section 2` | ❌ Wave 0 Gap |
| **BAR-01** | Live wallpaper confirmation run with `55192173787_b8322b1190_o.jpg` & clean theme revert | live integration | `./scripts/phase21-ii-bar-config-capture-assert.sh --section 3` | ❌ Wave 0 Gap |
| **CAP-06** | Systemd user timer enabled, active, stowed, and oneshot service journal verification | systemd integration | `./scripts/phase21-ii-bar-config-capture-assert.sh --section 4` | ❌ Wave 0 Gap |
| **CAP-06** | Drift capture drill: hand-edited live file captured to unstaged git status within interval | live integration | `./scripts/phase21-ii-bar-config-capture-assert.sh --section 5` | ❌ Wave 0 Gap |
| **BAR-02** | Personal bar settings baseline check & defaults-reset recovery drill with `config.json.bak.<epoch>` | integration | `./scripts/phase21-ii-bar-config-capture-assert.sh --section 6` | ❌ Wave 0 Gap |
| **BAR-01, BAR-02, CAP-06** | Overall tree integrity via strict link-aware verification | system check | `./arch/dots-hyprland.sh verify --strict` | ✅ Exists |

### Sampling Rate
- **Per task commit:** Run the relevant assert section: `./scripts/phase21-ii-bar-config-capture-assert.sh --section <N>`
- **Per wave merge:** Run full assert suite: `./scripts/phase21-ii-bar-config-capture-assert.sh`
- **Phase gate:** Full assert suite green AND `./arch/dots-hyprland.sh verify --strict` exits 0 with `FAIL=0 FINDINGS=0` before completing phase.

### Wave 0 Gaps
- [ ] `scripts/phase21-ii-bar-config-capture-assert.sh` — gating assert script for Phase 21.
- [ ] `capture/ii/.config/illogical-impulse/config.json` — repository mirror of deliberate personal bar baseline.
- [ ] `stow/systemd/.config/systemd/user/dotfiles-capture.service` — systemd user service unit.
- [ ] `stow/systemd/.config/systemd/user/dotfiles-capture.timer` — systemd user timer unit.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V5 Input Validation | yes | Ingest-time JSON validation (`jq empty "$live"` and non-zero check `[[ -s "$live" ]]`) ensures malformed, truncated, or hostile live JSON never overwrites clean git mirrors. Path canonicalization (`realpath -m`) verifies files remain strictly under `capture/`. Symlink refusal ensures live symlinks pointing into the repository are rejected. |
| V4 Access Control | yes | Directory permissions on user config directories (`0700` / `0755`); systemd user units run under user UID with unprivileged capabilities (`Nice=19`). |
| V6 Cryptography | no | No cryptographic primitives manipulated. Secret scan (`FIX-06`) ensures no API keys or tokens are committed to `config.json`. |

### Known Threat Patterns for Linux Desktop Shell Configuration Capture

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Incomplete / Partial File Write | Tampering | Copy live file to a unique temporary PID file (`$repo_file.tmp.$$`) before executing atomic `mv -f`. Git working tree never observes an incomplete write. |
| Malformed / 0-byte Overwrite Race | Denial of Service | Fail closed: evaluate `[[ -s "$live" ]]` and `jq empty "$live"`. If invalid or empty, log `[FAIL]` and skip without touching the repository mirror. |
| Symlink Traversal / Repo Escape | Elevation of Privilege | Test canonicalized destination path: ensure `realpath -m "$repo_file"` has prefix `$REPO_ROOT/capture/`. Refuse any live path that is a symlink into the repository. |
| Dirty Mirror Inadvertent Clobber | Tampering | Check `git diff --quiet HEAD -- "$repo_file"`. If the repository mirror has uncommitted edits, capture refuses to overwrite it, protecting human edits. |

## Sources

### Primary (HIGH confidence)
- `vendor/dots-hyprland/dots/.config/quickshell/ii/scripts/colors/switchwall.sh:144-149` — `set_wallpaper_path` implementation destroying symlinks via `mv` [VERIFIED: in-repo file].
- `arch/dots-hyprland.sh:1440-1518` — `run_capture` and `mirror_is_capturable` implementation [VERIFIED: in-repo file].
- `arch/hyprland.sh:41-44` — Systemd user stow and daemon-reload call site [VERIFIED: in-repo file].
- `~/.config/illogical-impulse/config.json:1-580` — Live configuration schema and deliberate personal preferences [VERIFIED: live file].
- `capture/README.md:1-54` — Three-tree taxonomy and inverted verification contract [VERIFIED: in-repo file].
- Live host terminal test: Quickshell 0.2.1 `FileView` symlink write-through confirmation [VERIFIED: live test].
- Live host terminal test: `mv` over symlink replacement confirmation [VERIFIED: live test].
- Live host terminal test: `jq empty` on 0-byte file evaluation [VERIFIED: live test].

### Secondary (MEDIUM confidence)
- `.planning/phases/18-capture-model-three-trees-and-the-collision-map/18-CONTEXT.md` — Capture model decisions D-36 through D-45 [CITED].
- `.planning/phases/19-link-aware-verify/19-CONTEXT.md` — Link-aware verification decisions D-50 through D-53 [CITED].

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — All tools (`jq`, `stow`, `systemctl`, `qs`, `cmp`, `notify-send`) tested and verified on the live system.
- Architecture: HIGH — Empirically proven why `switchwall.sh:147` severs symlinks and why `capture/` copy model is necessary.
- Pitfalls: HIGH — 0-byte `jq empty` behavior and path structure pitfalls identified and verified with working mitigations.

**Research date:** 2026-09-15
**Valid until:** 2026-10-15
