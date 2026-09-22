# Phase 38: Power Profiles Daemon System Integration - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-22
**Phase:** 38-Power Profiles Daemon System Integration
**Areas discussed:** System Package Provisioning & Script Anchoring, Quickshell Quick-Toggle Behavior & Feedback, Profile Switching Policy & Power Automation, Verification Harness & Assertion Strategy

---

## Direct User Directives

1. *"everything about powerprofiles needs to be upstream default dots-hyprland. (whether i gave you decisions or not) No need to do anything else"*
2. *"i would like to keep everything default upstream powerprofile setup basically how it is in the dots-hyprland. do i need a phase for this. i think i only have to install it"*

**Key Takeaway:**
Zero QML modifications or shell development required. Upstream `dots-hyprland` already has the complete toggle and UI built. The phase consists purely of:
1. Installing `power-profiles-daemon` and enabling `power-profiles-daemon.service`.
2. Tracking `power-profiles-daemon` in `arch/pkglist-native.txt` and `bootstrap.sh`.
3. Verifying that the existing upstream toggle operates live.

---

## Package Provisioning & Script Anchoring

- **Package location:** Added to `arch/pkglist-native.txt` and checked/installed in `bootstrap.sh` (`step_packages`).
- **Service enablement:** Idempotent check in `bootstrap.sh` (`systemctl is-active --quiet power-profiles-daemon.service`) before invoking `sudo systemctl enable --now`.
- **Verification scope:** `arch/dots-hyprland.sh verify --strict` stays focused on symlinks and git working tree integrity.

---

## Upstream Shell UI & Power Policy

- **Toggle behavior:** Strictly default upstream `PowerProfilesToggle.qml` using `Quickshell.Services.UPower`.
- **Feedback:** Purely in-sidebar visual feedback (icon + label update); no desktop popups or OSDs.
- **Switching policy:** Strictly default upstream manual switching; no custom udev or automated battery scripts.
- **Grid position:** Default 4th slot in `Config.qml` quick toggles.

---

## the agent's Discretion

- Clean bash syntax for idempotent checks in `bootstrap.sh`.
- Simple assertion commands for verifying D-Bus and CLI status.

## Deferred Ideas

- None — discussion stayed strictly within phase scope.
