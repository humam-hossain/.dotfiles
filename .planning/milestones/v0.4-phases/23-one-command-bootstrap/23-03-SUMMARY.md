---
phase: 23-one-command-bootstrap
plan: 03
subsystem: bootstrap-snapshots-and-verify
tags: [bootstrap, package-snapshots, relogin-boundary, systemd, verify-gate]
key-files:
  created:
    - arch/pkglist-native.txt
    - arch/pkglist-aur.txt
  modified:
    - bootstrap.sh
    - scripts/phase23-bootstrap-assert.sh
requirements: [BOOT-04]
requirements_completed: [BOOT-04]
status: complete
completed_at: 2026-09-15T12:15:00Z
---

# Plan 23-03: Package Snapshots, Relogin Boundary, Systemd Timer, and Verification Gate Summary

Delivered package snapshot data generation (`--snapshot`) committing `arch/pkglist-native.txt` and `arch/pkglist-aur.txt` with formatted metadata headers and deterministic sorting (`LC_ALL=C sort -u`), implemented the two-stage execution boundary across compositor relogin with the operator instruction banner and runtime session probe, wired post-relogin systemd capture timer activation (`dotfiles-capture.timer`), bound the root orchestrator exit code 1-to-1 to `arch/dots-hyprland.sh verify --strict`, and completed Sections 4 and 5 in `scripts/phase23-bootstrap-assert.sh`.

## Key Changes

1. **Package Snapshot Generation (`--snapshot`)**:
   - Implemented `generate_package_snapshots()` in `./bootstrap.sh` generating `arch/pkglist-native.txt` and `arch/pkglist-aur.txt`.
   - Determined hostname without relying on the absent `hostname` binary (`uname -n 2>/dev/null || cat /etc/hostname 2>/dev/null || echo "${HOSTNAME:-arch}"`).
   - Formatted comment headers containing Hostname, UTC Timestamp, Kernel, Pacman version, and Count.
   - Enforced deterministic alphabetical sorting via `LC_ALL=C sort -u`.
   - Isolated snapshot generation to the explicit `--snapshot` CLI flag, ensuring standard bootstrap runs (`--dry-run` or live) cause zero working-tree drift.

2. **Two-Stage Relogin Boundary & Session Probe**:
   - Implemented `show_relogin_banner()` displaying a formatted, bordered instruction box (`BOOTSTRAP: STAGE 1 COMPLETE`) informing the operator to log out via `hyprctl dispatch exit`, log back in via the display manager to activate upstream `hyprland.lua`, and re-run `./bootstrap.sh`.
   - Persisted Stage 2 marker in JSON state (`set_stage 2`) and exited 0 cleanly, while allowing `--no-pause` to bypass the pause for headless/automated test environments.
   - Implemented `probe_session_environment()` on resumption, probing `HYPRLAND_INSTANCE_SIGNATURE` and checking `hyprctl -j status` for `configProvider == "lua"`, emitting warnings if running in a non-graphical or legacy session.

3. **Stage 2 Verification Gate & Systemd Timer Activation**:
   - Implemented `run_stage2_verification()` executing `systemctl --user daemon-reload` and enabling `dotfiles-capture.timer` with active verification.
   - Delegated final verification to `"$REPO_ROOT/arch/dots-hyprland.sh" verify --strict` and returned its exact exit code directly, guaranteeing that `./bootstrap.sh` passes if and only if repository verification succeeds with zero findings.

4. **Assert Test Harness Sections 4 and 5 (`scripts/phase23-bootstrap-assert.sh`)**:
   - Implemented Section 4: validates existence, all 5 metadata headers, and deterministic `LC_ALL=C sort -C` ordering of native and AUR package snapshots, plus zero working-tree drift under standard invocations.
   - Implemented Section 5: validates `--dry-run` exit 0 on live host, strict enforcement of `PAIR_COUNT == 18` across `arch/*.sh`, and live host verification passing with zero findings.
   - Updated Section 1: verified Stage 1 relogin banner, stage 2 state transition, and `--no-pause` flag behavior.

## Verification Results

- `scripts/phase23-bootstrap-assert.sh`: PASSED (all 5 sections passing, FAIL=0, FINDINGS=0).
- `arch/dots-hyprland.sh verify --strict`: PASSED (0 failures, 0 findings, 100% clean).
- `grep -ho -- '--verbose=5 --no-folding' arch/*.sh | wc -l`: strictly 18.
- Working-tree porcelain bracket: unchanged.

## Deviations from Plan

None - plan executed exactly as written.

## Self-Check: PASSED
