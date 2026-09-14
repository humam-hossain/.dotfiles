# Phase 21: ii bar config capture - Context

**Gathered:** 2026-09-15
**Status:** Ready for planning

<domain>
## Phase Boundary

Capture and persist the Quickshell (ii) desktop shell configuration into the repository's `capture/` tree, ensure capture survives destructive wallpaper scripts, and establish an automated systemd user timer for unattended capture:

1. **Capture Tree Resident (BAR-01):** Establish `capture/ii/.config/illogical-impulse/config.json` as the first official resident of the `capture/` tree, following the stow-relative directory hierarchy (`capture/<pkg>/<rel_to_home>`) established in Phase 18 (D-38).
2. **Pre-Capture Validation & Atomic Replace (BAR-01):** Enhance `arch/dots-hyprland.sh capture` to detect when files drift via `cmp -s`, validate JSON files using `jq empty "$live"` before writing, fail closed on 0-byte or corrupt JSON, and write to the repository mirror atomically via temp-file rename (`cp -p` to temp file then `mv`), preserving raw formatting (4-space indent) without synthetic diff churn.
3. **Automated Unattended Capture Timer (CAP-06):** Create and stow `dotfiles-capture.service` and `dotfiles-capture.timer` under `stow/systemd/.config/systemd/user/`. Configure a 15-minute cadence (`OnUnitActiveSec=15m`, `OnStartupSec=2m`, `Persistent=true`, `WantedBy=timers.target`), low priority (`Nice=19`), `SuccessExitStatus=0 1`, and wire enablement into `arch/hyprland.sh`.
4. **Desktop Notifications:** Add `--quiet` and `--notify` flag support to `run_capture`. Send low-urgency notifications (`notify-send "Dotfiles Capture" "Captured updates to repository" -a "Shell" -u low`) only when active file changes are synced to the repo mirror.
5. **Bar Settings Baseline (BAR-02):** Adopt current live `~/.config/illogical-impulse/config.json` settings (top horizontal bar, spark icon, Dhaka weather, 5 workspaces, utility toggles) as the deliberate personal baseline, excluding installer state flags (`installed_listfile`, `installed_true`).
6. **Live Wallpaper & Reset Drills:** Prove in an isolated scratch XDG environment that `switchwall.sh:147`'s `mv` destroys symlinks and that `capture` reproduces the plain file; execute a non-disruptive production wallpaper test using the current wallpaper (`55192173787_b8322b1190_o.jpg`), log generated theme file modifications for Phase 22 (Q7/Q8), and verify defaults-reset recovery with a timestamped backup drill (`config.json.bak.<epoch>`). All verified via `scripts/phase21-ii-bar-config-capture-assert.sh`.

Out of scope:
- Full KDE and GTK configuration capture (Phase 22 owns `kdeglobals`, `dolphinrc`, `gtk-3.0/settings.ini`).
- Submodule code modifications to `vendor/dots-hyprland`.
- One-command full bootstrap orchestration (Phase 23).

</domain>

<decisions>
## Implementation Decisions

### JSON Validation & Atomic Ingest (`arch/dots-hyprland.sh capture` — BAR-01)

- **D-01:** Validation is format-generic based on file extension: any file ending in `*.json` is validated using `jq empty "$live"` before being copied to the repository mirror. — **Reversibility:** reversible
- **D-02:** Change-detection optimization: `run_capture` runs `cmp -s "$live" "$repo_file"` before validation. If the live file is byte-identical to the repository mirror, capture immediately skips it as a no-op, avoiding unnecessary disk writes and redundant `jq` subprocess forks every 15 minutes. — **Reversibility:** reversible
- **D-03:** Validation failure behavior: If `jq empty "$live"` fails or the file is 0 bytes (truncated write race), `run_capture` logs `[FAIL] invalid or empty JSON: $live`, leaves the repository mirror untouched, skips the file, and marks the run non-zero so the skipped capture is reported without destroying clean repository history. — **Reversibility:** reversible
- **D-04:** Raw formatting preservation: `capture` preserves raw file bytes and mtime via `cp -p`. No reformatting (e.g. `jq '.'`) is performed, avoiding synthetic diff churn against Quickshell's internal 4-space indented serializer. — **Reversibility:** reversible
- **D-05:** Atomic write into git working tree: File copies into the repository use a temporary file rename: `cp -p -- "$live" "$repo_file.tmp.$$" && mv -f "$repo_file.tmp.$$" "$repo_file"`. This guarantees the git working tree never observes a partial or half-written file if the capture process is interrupted. — **Reversibility:** reversible
- **D-06:** Check pipeline order: For each capturable file, `run_capture` evaluates in order: (1) resolved path security check under `capture/`, (2) `mirror_is_capturable` (repo mirror exists, tracked, clean against HEAD), (3) live path symlink refusal, (4) live path existence, (5) `cmp -s` change check, (6) format validation (`jq empty`), (7) atomic temp-file copy. — **Reversibility:** reversible
- **D-07:** `verify` remains content-diff focused: `run_verify` continues to perform link-identity and content-diff verification (`diff -u "$live" "$canonical_repo"`) without adding JSON-specific syntax parsing to `verify`. Format validation remains an ingest-time gate in `run_capture`. — **Reversibility:** reversible

### Systemd Timer & Service Configuration (`dotfiles-capture.timer` & `service` — CAP-06)

- **D-08:** Timer cadence: `dotfiles-capture.timer` runs every 15 minutes: `OnUnitActiveSec=15m`, `OnStartupSec=2m`, `Persistent=true`, attached to `WantedBy=timers.target`. Missed runs while the system is powered down or suspended are caught up on boot. — **Reversibility:** reversible
- **D-09:** Service unit definition: `dotfiles-capture.service` is a `Type=oneshot` service executing `%h/github_repo/.dotfiles/arch/dots-hyprland.sh capture --quiet --notify` with `WorkingDirectory=%h/github_repo/.dotfiles`. — **Reversibility:** reversible
- **D-10:** Process priority & timeouts: Configured with `Nice=19`, `TimeoutStartSec=30s`, `StandardOutput=journal`, `StandardError=journal`, and `SyslogIdentifier=dotfiles-capture`. — **Reversibility:** reversible
- **D-11:** Service exit status: Configured with `SuccessExitStatus=0 1`. When `run_capture` skips dirty repository mirrors or invalid live files (which legitimately return exit code 1 per D-36/D-43), systemd does not mark the service in a red failed state, but full details remain recorded in `journalctl --user -u dotfiles-capture`. — **Reversibility:** reversible
- **D-12:** Display environment & notification dispatch: The service unit specifies `PassEnvironment=WAYLAND_DISPLAY DISPLAY DBUS_SESSION_BUS_ADDRESS`. In `run_capture`, notifications use dots-hyprland style: `notify-send "Dotfiles Capture" "Captured updates to repository" -a "Shell" -u low` executed with `|| true` so display or daemon errors are non-fatal and never abort the sync. — **Reversibility:** reversible
- **D-13:** Flag surface in `run_capture`: Accepts `--quiet` (suppresses passing/noop logs, outputs only changes or errors) and `--notify` (dispatches desktop notification only when `captured_count > 0`). Manual terminal CLI runs without `--notify` remain purely text-based. — **Reversibility:** reversible
- **D-14:** Single source of truth & enablement: Both unit files are authored in `stow/systemd/.config/systemd/user/`. `arch/hyprland.sh` enables and starts the timer: `systemctl --user daemon-reload && systemctl --user enable --now dotfiles-capture.timer && systemctl --user restart dotfiles-capture.timer`. — **Reversibility:** reversible

### Bar Settings Baseline & Package Layout (`capture/ii/` — BAR-02)

- **D-15:** Package tree hierarchy: `config.json` resides at `capture/ii/.config/illogical-impulse/config.json`. This strictly complies with Phase 18's D-38 contract where `capture/<pkg>/<rel_to_home>` maps to `$HOME/<rel_to_home>`. — **Reversibility:** costly — changing directory structure breaks `run_capture` path resolution.
- **D-16:** Baseline adoption: The current live `~/.config/illogical-impulse/config.json` is adopted as the initial baseline in `capture/ii/`, locking active preferences (top horizontal bar, spark icon, Dhaka weather, 5 workspaces, mic/snip utility toggles). — **Reversibility:** reversible
- **D-17:** Scope exclusion: Only `config.json` is tracked in `capture/ii/`. Upstream installer state files (`installed_listfile`, `installed_true`) and runtime directories (`actions/`) are deliberately excluded from the repository. — **Reversibility:** reversible
- **D-18:** Defaults-reset recovery drill (BAR-02): Verification creates a timestamped backup (`config.json.bak.<epoch>`), resets live `config.json` to an empty state, restores the file from `capture/ii/`, reloads `qs -c ii`, and asserts all bar settings are reproduced. — **Reversibility:** reversible

### Live Wallpaper Verification & Assert Harness (BAR-01)

- **D-19:** Two-stage verification: First stage executes in an isolated temporary `$XDG_CONFIG_HOME` scratch environment to prove `switchwall.sh:147`'s `jq ... > tmp && mv` destroys a symlink and that `capture` handles the resulting plain file. Second stage performs a live confirmation against the running desktop. — **Reversibility:** reversible
- **D-20:** Non-disruptive production wallpaper test: The live confirmation triggers `switchwall.sh` using the current wallpaper (`/home/pera/Pictures/55192173787_b8322b1190_o.jpg`). This exercises the exact `mv` rename and theme generation code paths without changing desktop visuals. Generated theme modifications (`kdeglobals`, `colors.lua`, `hyprlock/colors.conf`) are recorded in verification notes to settle Q7/Q8 for Phase 22, then cleanly reverted via `git checkout`. — **Reversibility:** reversible
- **D-21:** Comprehensive assert script: `scripts/phase21-ii-bar-config-capture-assert.sh` gates the phase by validating JSON syntax checking, timer activation, service triggers, git status output, `arch/dots-hyprland.sh verify --strict` pass, and the isolated scratch drill. — **Reversibility:** reversible

### Claude's Discretion

- Exact temporary filename patterns and cleanup trap implementations in `run_capture`.
- Specific assertion helper functions and stderr/stdout formatting in `scripts/phase21-ii-bar-config-capture-assert.sh`.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` §Phase 21 — goal statement, dependencies, 4 success criteria, verification risk
- `.planning/REQUIREMENTS.md` lines 21-27, 49-51 — BAR-01, BAR-02, CAP-06

### Capture architecture and contracts
- `capture/README.md` — three-tree taxonomy capture contract, hand-assigned prose rule, inverted verification
- `.planning/phases/18-capture-model-three-trees-and-the-collision-map/18-CONTEXT.md` §D-36–D-45 — `run_capture` semantics, dirty mirror handling, and stow-style layout
- `.planning/phases/19-link-aware-verify/19-CONTEXT.md` §D-50 — `verify` inverted symlink expectation for `capture/` paths

### Upstream shell scripts and configuration
- `vendor/dots-hyprland/dots/.config/quickshell/ii/scripts/colors/switchwall.sh` lines 144-156 — `set_wallpaper_path` and `set_thumbnail_path` `mv` implementation destroying symlinks
- `~/.config/illogical-impulse/config.json` — live bar and shell configuration (top bar, Dhaka weather, 5 workspaces)
- `stow/systemd/.config/systemd/user/hyprland-session.service` — existing stow-managed systemd user unit pattern

### Installation & verification scripts
- `arch/dots-hyprland.sh` lines 1394-1515 — current `run_capture` implementation
- `arch/hyprland.sh` lines 41-44 — existing `stow systemd` block and daemon-reload
- `scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh` — reference assert script pattern

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `arch/dots-hyprland.sh run_capture`: Already implements the core capture walk, mirror capturability tests (`mirror_is_capturable`), resolved path security checks, and `--dry-run`.
- `stow/systemd/.config/systemd/user/`: Established stow package directory for systemd user units deployed to `~/.config/systemd/user/`.
- `scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh`: Established assert script structure with strict exit codes, trap cleanups, and test harness execution.

### Established Patterns
- Stow package layout across trees: `capture/<pkg>/<rel_to_home>` mirrors `stow/<pkg>/<rel_to_home>`.
- Inverted capture verification: `verify` enforces that live capture paths are plain files, never symlinks into the repo.
- Fail-closed validation: Corrupt or 0-byte files must never overwrite clean repository mirrors.
- Dots-hyprland notifications: Dispatched via `notify-send "Title" "Body" -a "Shell" -u low`.

### Integration Points
- `arch/dots-hyprland.sh capture`: Enhanced with `--quiet`, `--notify`, `cmp -s` check, `jq empty` validation, and atomic replace.
- `arch/hyprland.sh`: Systemd unit enablement point for `dotfiles-capture.timer`.
- `~/.config/illogical-impulse/config.json`: Live path captured into `capture/ii/.config/illogical-impulse/config.json`.

</code_context>

<specifics>
## Specific Ideas

- Fast idle ticks: `cmp -s "$live" "$repo_file"` skips byte-identical files before invoking `jq`, keeping periodic timer runs virtually zero-cost on CPU and disk.
- Non-disruptive live wallpaper verification: Calling `switchwall.sh` with the existing wallpaper path (`55192173787_b8322b1190_o.jpg`) fully triggers the `mv` rename and theme generation without visual desktop disruption.
- Fail-open notifications: Wrapping notification dispatches with `|| true` ensures desktop notification failures in headless or locked environments never fail the core dotfile capture.

</specifics>

<deferred>
## Deferred Ideas

- Phase 22: KDE and GTK capture (`kdeglobals`, `dolphinrc`, `gtk-3.0/settings.ini`).
- Phase 23: One-command full bootstrap orchestration (`BOOT-01`–`BOOT-05`).

</deferred>

---

*Phase: 21-ii-bar-config-capture*
*Context gathered: 2026-09-15*
