# CONCERNS

> Risks, technical debt, and items needing attention in the `.dotfiles` repository.

## 🔴 Critical — Uncommitted Quickshell Deletion

**39 files** under `.config/quickshell/` (37 QML + 2 `qmldir`) are **deleted in the working tree but still tracked in git HEAD** (unstaged deletions; `git status` shows ` D` for each). The `.config/quickshell/` directory currently appears empty on disk.

- This is **in-progress, uncommitted work** — intent is ambiguous (removal? replacement? work-in-progress?).
- `arch/quickshell.sh` still references the config and would symlink a now-empty directory.
- Hyprland `hyprland.conf` does not currently `exec-once` quickshell (per quickshell.sh note: "Hyprland exec-once is intentionally not modified"), so the session is not broken by the deletion.
- **Action**: confirm with the user whether this deletion should be committed, reverted, or left as-is before any commit of the codebase map touches the working tree. Do **not** stage or revert these deletions without explicit confirmation.

## 🟠 High — ddcutil Re-introduction Risk

The incident post-mortem (`issues/2026-07-16_igpu-flickering-hang-no-display.md`) documents a system crash caused partly by **ddcutil DDC/CI bus hammering** (~10,764 failed calls in 3 hours, saturating the DP I2C bus and interfering with GPU link management). The resolution disabled the ddcutil Waybar module.

However, `arch/quickshell.sh` **re-installs `ddcutil` + `i2c-tools`**, loads `i2c-dev`, and adds the user to the `i2c` group — re-introducing the exact dependency that caused the crash. The Quickshell `BacklightService` would presumably use it for monitor brightness control.
- **Risk**: reviving ddcutil polling (especially an aggressive polling widget) could re-trigger display instability on the same hardware.
- **Mitigation already in place**: the post-mortem exists; the Waybar backlight module was disabled. But there is no guard preventing a Quickshell backlight widget from polling ddcutil at a harmful rate.
- **Action**: if Quickshell is restored, ensure any backlight widget uses a sane polling interval and failure backoff; reference the post-mortem.

## 🟠 High — No CI / No Automated Validation Gate

There is no continuous integration. All validation (`scripts/nvim-validate.sh`, provisioning `verify()` steps) is manual. Regressions in nvim config, install scripts, or QML can land without any automated check.
- The nvim harness is thorough but must be run by hand (or by an agent).
- Shell scripts are not shellchecked in any automated way.
- **Action**: consider a pre-commit hook or a lightweight GitHub Actions workflow running `shellcheck` on `*.sh` and `scripts/nvim-validate.sh startup` on nvim changes.

## 🟡 Medium — Personal / Non-Portable Configuration

The repo is a **personal** environment with machine-specific values that reduce portability:
- `arch/README.md` contains a hardcoded root **UUID** (`3778e853-...` and `e8a2b95d-...`) in bootloader examples.
- `hyprland.conf` hardcodes monitor names (`DP-1`, `HDMI-A-2`) and a transform/rotation for a specific dual-monitor setup.
- Kernel cmdline referenced `i915.force_probe=!4680 xe.force_probe=4680` (now removed) — iGPU-specific.
- `.zshrc` conda aliases assume `~/miniconda3` with a `darkconda` env.
- Repo path assumed `~/github_repo/.dotfiles`.
- `google-chrome-stable --profile-directory='Default'` autostart is profile-specific.
- **Action**: acceptable for a personal dotfiles repo, but document machine-specific knobs in one place if multi-machine use grows.

## 🟡 Medium — Provisioning Script Drift Between Generations

Two script generations coexist (legacy linear vs. structured with `verify()`), and three distro trees (arch/debian/ubuntu) are maintained in parallel by hand. This invites drift:
- debian/ubuntu scripts are subsets with **no `verify()` step** and no parity test against arch.
- `ubuntu/monitor_system.sh` vs `debian/system_monitor.sh` naming inconsistency for the same ping monitor.
- Some Arch-only features (AUR, quickshell, bluetooth, wifi, audio, google_chrome, vscode) have no debian/ubuntu equivalent — users on those distros get a reduced environment with no warning.
- **Action**: consider a shared library (`scripts/lib/`) for common functions (REPO_ROOT resolution, verify helpers, labeled echos) to reduce duplication.

## 🟡 Medium — Secrets / Env Handling

- `.config/system_monitor/ping/.env` is correctly **gitignored**, and `.env.example` is committed — good practice.
- `data/` (SQLite history) is gitignored — good.
- However, `BIND_HOST=0.0.0.0` is the **default for debian/ubuntu** (LAN-exposed ping server on port 8765) with no auth. On a trusted home LAN this is fine, but it is an unauthenticated HTTP endpoint exposing network latency data.
- **Action**: document the LAN-exposure default explicitly; consider loopback default with opt-in LAN.

## 🟡 Medium — Missing Tooling Validation for Non-nvim Subsystems

Only Neovim has a real validation harness. Hyprland, Waybar, swaync, rofi, quickshell, tmux, and shell configs have no automated validation. Misconfigurations surface only at session start or runtime.
- **Action**: at minimum, a `hyprctl --batch` config parse check and `waybar -c config.jsonc -s style.css --validate` (if supported) would catch syntax errors early.

## 🟢 Low — Documentation Cadence

- nvim README is excellent and comprehensive (511 lines, phase history, rollback).
- waybar and system_monitor have README + PRD.
- Top-level `README.md` is sparse (just resource links) and does not explain the overall repo layout, the three-distro script model, or how to bootstrap a fresh machine end-to-end.
- **Action**: expand top-level README with a "fresh install" quickstart pointing to `arch/README.md` + the provisioning order in INTEGRATIONS.md.

## 🟢 Low — Stale / Mixed Tooling References

- `starship.toml` exists but starship is **disabled** in `.zshrc` (Powerlevel10k is used instead). Two prompt configs maintained for one used.
- nvim README "Tooling and Ecosystem Modernization" section still mentions fzf-lua and neo-tree in places while the phase summary says they were replaced by snacks.nvim — minor doc drift.
- **Action**: prune the unused starship config or re-enable it intentionally; reconcile nvim README's tooling section with the snacks.nvim migration.

## 🟢 Low — `set -x` in Production Scripts

Legacy scripts use `set -x` which dumps every command to stderr. Useful for debugging an install, but noisy and can leak environment values (e.g., during `.env` sourcing in `system_monitor.sh`, though that script is structured and avoids `set -x`). Acceptable for personal provisioning scripts.
