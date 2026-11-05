# Codebase Concerns

**Analysis Date:** 2026-11-05

## Tech Debt

**Monolithic Wrapper Script Complexity:**
- Issue: `arch/dots-hyprland.sh` is over 1,500 lines of bash managing allowlist validation, submodule preflights, installer delegation, uninstall procedures, capture workflows, and strict verification logic.
- Files: `arch/dots-hyprland.sh`
- Impact: High cognitive load when maintaining or adding subcommands; regression risks in uninstall or cleanup logic that could accidentally delete operator files.
- Fix approach: Modularize into sub-scripts under an `arch/lib/` or `arch/dots-hyprland/` directory (e.g. `verify.sh`, `uninstall.sh`, `capture.sh`), sourced by the top-level dispatcher.

**Test Harness Boilerplate Duplication:**
- Issue: Over 50 assertion suites in `scripts/phase*-assert.sh` duplicate identical bash helper functions (`pass()`, `fail()`, `_tap_desc()`, non-root execution check, and `mktemp` cleanup traps).
- Files: `scripts/phase*-assert.sh`
- Impact: Inconsistencies across older and newer assertion scripts; any enhancement to test reporting (e.g. TAP formatting) requires updating dozens of individual files.
- Fix approach: Extract shared assertion helpers into a common library `scripts/lib/assert-common.sh` and source it at the top of each phase harness.

**Debian & Ubuntu Installer Drift:**
- Issue: Shell scripts under `debian/` and `ubuntu/` are incomplete copies of the Arch installers. They provide CLI and Neovim tools but do not support Hyprland or Quickshell. Some scripts have inconsistent filenames (e.g. `debian/system_monitor.sh` vs `ubuntu/monitor_system.sh`).
- Files: `debian/*.sh`, `ubuntu/*.sh`
- Impact: Fixes made to Arch scripts do not propagate to Debian/Ubuntu mirrors; misleading expectations for operators on non-Arch distributions.
- Fix approach: Deprecate or freeze Debian/Ubuntu directories with clear documentation in `README.md` affirming Arch Linux as the sole supported environment.

**Legacy Waybar Configuration Retention:**
- Issue: `stow/waybar/` remains in the repository despite Quickshell being fully adopted since Phase 14/16.
- Files: `stow/waybar/`, `arch/waybar.sh`
- Impact: Unnecessary maintenance overhead and potential confusion over which status bar is authoritative.
- Fix approach: Move `stow/waybar/` to an `archive/` directory or document it explicitly as a fallback bar.

## Known Bugs

**USB Port Enumeration & I2C Bus Drops:**
- Symptoms: USB mouse and Wi-Fi adapter drop intermittently; `ddcutil` commands hang when querying monitor brightness over I2C/DDC.
- Files: `issues/2026-10-19_usb-port-enumeration-failures-mouse-wifi-ddcutil.md`
- Trigger: Simultaneous high USB traffic or sleep/wake power state transitions on certain motherboard USB host controllers.
- Workaround: Systemd sleep hook disabling USB auto-suspend and resetting the affected USB bus; run `ddcutil` with timeout guards.

**Wayland Compositor Frame Drops Under High Context-Switch Spikes:**
- Symptoms: Transient keyboard latency or Kitty terminal rendering stalls when background processes perform heavy procfs polling.
- Files: `issues/2026-09-30_keyboard-lag-kitty-freeze-investigation.md`, `scripts/profile-quickshell.sh`
- Trigger: Background telemetry scripts polling too frequently or spawning child processes in tight loops.
- Workaround: Fixed in Phase 50 by increasing idle telemetry cadence (1s -> 3s) and eliminating child process execution in QML timers, but heavy builds can still trigger momentary input latency.

**Intel iGPU Flickering on Cold Boot:**
- Symptoms: Flickering or black screen upon initial Hyprland startup on specific Linux kernel/Mesa versions.
- Files: `issues/2026-07-16_igpu-flickering-hang-no-display.md`
- Trigger: Early KMS init and PSR (Panel Self Refresh) power-saving features.
- Workaround: Pass kernel parameter `i915.enable_psr=0` in bootloader configuration.

## Security Considerations

**Strict Confidentiality of Rclone Configurations:**
- Risk: Exposing cloud storage OAuth tokens, client secrets, and remote credentials.
- Files: `/home/pera/.config/rclone/rclone.conf` (untracked, forbidden)
- Current mitigation: Strict repository confidentiality rule preventing reading, printing, or grepping `*rclone.conf*`. Only generic systemd unit templates are stored in `stow/rclone/`.
- Recommendations: Maintain file permission `chmod 600 ~/.config/rclone/rclone.conf` and ensure automated tools never inspect rclone configurations.

**Plaintext API Keys in Weather Environment File:**
- Risk: Accidental leakage of WorldWeatherOnline API keys to version control.
- Files: `$XDG_CONFIG_HOME/weather/.env`
- Current mitigation: Gitignored by default; template provided as `stow/weather/.config/weather/.env.example`; `.gitleaks.toml` scans for exposed tokens.
- Recommendations: Add an assertion in `scripts/phase51-weather-assert.sh` ensuring file permissions on `.env` are restricted to `0600`.

**Root Privilege Prevention:**
- Risk: Running scripts with `sudo` corrupts file ownership in `$HOME` (e.g. root-owned `.config` or `.local/state` directories).
- Files: `bootstrap.sh`, `arch/dots-hyprland.sh`, `scripts/phase*-assert.sh`
- Current mitigation: Enforced gate checking `if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then exit 1; fi`.
- Recommendations: Continue enforcing non-root execution across all new scripts.

## Performance Bottlenecks

**Process Tree Traversal in Quickshell:**
- Problem: Generating the process tree hierarchy for the popup inspector can take 50–150ms of CPU time on systems with hundreds of processes.
- Files: `restow/quickshell/.config/quickshell/ii/scripts/resource-usage/process_tree.py`
- Cause: Iterating through every `/proc/[0-9]*/stat` and `status` entry in Python.
- Improvement path: Cache process tree snapshots or drop deep process tree introspection in favor of simple top-5 CPU consumers.

**Canvas 2D Graph Re-rendering:**
- Problem: Redrawing multiple stacked Canvas graphs during weather popup resizing or rapid metric switching triggers CPU spikes.
- Files: `restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherGraph.qml`, `WeatherGraphMath.js`
- Cause: Canvas 2D context executes software path rasterization on the UI thread.
- Improvement path: Throttle Canvas `requestPaint()` calls and pre-render gradient fills into offscreen textures.

## Fragile Areas

**Upstream Submodule Drift and Upstream Pin Bumps:**
- Files: `vendor/dots-hyprland/`, `arch/dots-hyprland.sh`
- Why fragile: If upstream alters component internal APIs, QML property names, or directory paths, personal overlays in `restow/quickshell/` can silently fail to bind or crash the desktop shell.
- Safe modification: Always run `arch/dots-hyprland.sh verify --strict` before and after bumping the submodule pin. Perform pin bumps in isolated Git branches and test with full smoke suites.
- Test coverage: Validated by `scripts/phase14-verify.sh` and `arch/dots-hyprland.sh verify`.

**Stow Collision Map Synchronization:**
- Files: `collision-map.tsv`, `scripts/gen-collision-map.sh`
- Why fragile: Upstream installer updates may introduce new destination files or alter existing primitives (e.g. changing `cp` to `rsync`). If `collision-map.tsv` is out of date, packages may be placed in `stow/` instead of `restow/`, resulting in live symlinks being silently wiped.
- Safe modification: Run `scripts/gen-collision-map.sh > collision-map.tsv` after every upstream submodule bump and verify with git diff.

**GNU Stow Directory Folding:**
- Files: `stow/`, `restow/`
- Why fragile: If an operator runs `stow` without `--no-folding`, GNU Stow folds entire subdirectories into directory symlinks rather than individual file symlinks. This breaks granular file overrides and risks wiping user files during package updates.
- Safe modification: Always link using the standard flags: `stow --verbose=5 --no-folding -t ~ <pkg>`.

## Scaling Limits

**WorldWeatherOnline Free Tier API Quota:**
- Current capacity: 500 requests per day hard ceiling.
- Limit: Paced at dynamic interval `(M_rem / max(1, 470 - calls)) >= 3.0 min`. If external fetch frequency increases or clock skew occurs, the daily quota can be exhausted, disabling weather data until UTC midnight.
- Scaling path: Maintain strict local cache lifetimes (15 minutes nominal, 3 minutes minimum interval); consider integrating Open-Meteo as an unmetered secondary fallback.

**Quickshell Scenegraph Memory Footprint:**
- Current capacity: Desktop shell operates at ~150–220 MB RAM.
- Limit: Instantiating many unloaded popups or retaining large historical telemetry arrays increases QML engine heap usage.
- Scaling path: Use lazy QML `Loader` components so popups and heavy graphs are only loaded into memory when toggled visible.

## Dependencies at Risk

**`illogical-impulse-quickshell-git` (AUR Package):**
- Risk: Tracks the master/git branch of Quickshell, which undergoes active development and breaking C++ API changes.
- Impact: A system update (`yay -Syu`) can break Quickshell compilation or break QML module bindings.
- Migration plan: Pin to tested git commit hashes in local PKGBUILD or hold the package via pacman `IgnorePkg`.

**`ddcutil`:**
- Risk: Sensitive to Linux kernel I2C module changes and hardware display controller timing quirks.
- Impact: Can cause display brightness controls to stall or freeze for up to 10 seconds.
- Migration plan: Ensure brightnessctl is used for internal laptop displays and keep ddcutil calls asynchronous with short timeouts.

## Missing Critical Features

**Automated CI/CD Validation Pipeline:**
- Problem: There is no GitHub Actions or remote CI runner configured to execute assertion suites across commits.
- Blocks: Regressions can only be detected when the operator manually runs assertion scripts locally.

**Unattended Automated First-Boot Provisioning:**
- Problem: Bootstrapping a completely fresh machine requires manual disk partitioning and bootloader setup (`arch/README.md`) before `bootstrap.sh` can be executed.

## Test Coverage Gaps

**Visual & Pixel-Level Regression Testing:**
- What's not tested: Visual layout appearance, font rendering, color contrast verification, and UI element clipping across varied monitor DPI scales.
- Files: `restow/quickshell/.config/quickshell/ii/modules/ii/bar/*.qml`
- Risk: Visual regressions (e.g. text overlapping, margin misalignments) can pass static AST checks unnoticed.
- Priority: Medium.

**Cross-Distribution Automated Testing:**
- What's not tested: Execution of `debian/*.sh` and `ubuntu/*.sh` inside fresh containerized environments.
- Files: `debian/*.sh`, `ubuntu/*.sh`
- Risk: Broken package names or missing apt dependencies when run on non-Arch hosts.
- Priority: Low (Arch is the primary target).

---

*Concerns audit: 2026-11-05*
