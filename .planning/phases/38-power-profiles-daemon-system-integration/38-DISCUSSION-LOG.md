# Phase 38: Power Profiles Daemon System Integration - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-22
**Phase:** 38-Power Profiles Daemon System Integration
**Areas discussed:** System Package Provisioning & Script Anchoring, Quickshell Quick-Toggle Behavior & Feedback, Profile Switching Policy & Power Automation, Verification Harness & Assertion Strategy

---

## System Package Provisioning & Script Anchoring

| Option | Description | Selected |
|--------|-------------|----------|
| Add to arch/necessary.sh / arch/hyprland.sh and arch/pkglist-native.txt | Installs alongside base system/desktop utilities and guarantees presence on clean machine installs | |
| Create a dedicated arch/power.sh script | Encapsulates package installation, service enablement, and user permissions independently | |
| Install exclusively via bootstrap.sh step_packages | Treat it as a core system prerequisite alongside git/stow/jq/yay | ✓ |

**User's choice:** Install exclusively via bootstrap.sh step_packages — treat it as a core system prerequisite alongside git/stow/jq/yay.
**Notes:** Also record in `arch/pkglist-native.txt` per requirements.

| Option | Description | Selected |
|--------|-------------|----------|
| Idempotent sudo systemctl enable --now check in bootstrap.sh | Check if already enabled/active before prompting sudo, ensuring zero-overhead and no-op on existing setups | ✓ |
| Always run sudo systemctl enable --now unconditionally in bootstrap.sh | Check and prompt on every bootstrap run | |
| You decide | Agent chooses cleanest pattern | |

**User's choice:** Idempotent sudo systemctl enable --now check in bootstrap.sh.

| Option | Description | Selected |
|--------|-------------|----------|
| Preflight conflict detection in bootstrap.sh | Detect if tlp, auto-cpufreq, or tuned is active, and prompt or safely disable them | ✓ |
| Strict assertion failure | Halt bootstrap with an actionable message to manually disable conflicting services | |
| You decide | Handle conflicts gracefully | |

**User's choice:** Preflight conflict detection in bootstrap.sh.

| Option | Description | Selected |
|--------|-------------|----------|
| Keep arch/dots-hyprland.sh verify focused strictly on repository/symlink drift | Verify service/package health via the phase test harness and bootstrap — avoids coupling repo file verification to root systemd runtime state | ✓ |
| Add active service check to arch/dots-hyprland.sh verify | Strictly fail verify if power-profiles-daemon.service is not active | |
| You decide | Best respects existing verify strict contract | |

**User's choice:** Keep arch/dots-hyprland.sh verify focused strictly on repository/symlink drift.

---

## Quickshell Quick-Toggle Behavior & Feedback

| Option | Description | Selected |
|--------|-------------|----------|
| Rely on upstream 3-state cycling | Power Saver -> Balanced -> Performance -> Power Saver; requires 0 QML changes if daemon is active | ✓ |
| Overlay PowerProfilesToggle.qml in restow/quickshell | Custom cycling order or right-click selection | |
| You decide | Standard cycling | |

**User's choice:** Rely on upstream 3-state cycling.

| Option | Description | Selected |
|--------|-------------|----------|
| Purely in-sidebar visual feedback | Update the toggle icon and label text directly with no extra popups or toasts, keeping desktop interactions calm | ✓ |
| Trigger an OSD notification on profile switch | Show a brief desktop notification or toast showing the active profile and icon | |
| You decide | Keep minimal | |

**User's choice:** Purely in-sidebar visual feedback.

| Option | Description | Selected |
|--------|-------------|----------|
| Upstream default | Keep upstream neutral definition (toggled when not Balanced) | ✓ |
| Custom highlight | Always highlighted | |

**User's choice (User write-in):** "power profiles everything should be default dots-hyprland basically upstream. change nothing"
**Notes:** User emphasized strict compliance with upstream `dots-hyprland` defaults.

| Option | Description | Selected |
|--------|-------------|----------|
| Keep default 4th position in quick toggles grid | No config overrides or QML restow needed; works immediately once daemon runs | ✓ |
| Move powerProfile to a different slot | Config.qml overlay in restow | |

**User's choice:** Keep default 4th position in quick toggles grid.

---

## Profile Switching Policy & Power Automation

| Option | Description | Selected |
|--------|-------------|----------|
| Purely manual switching (daemon default) | power-profiles-daemon persists the user's chosen profile across boots without automatic switching scripts | ✓ |
| Automated udev / battery rule | Automatically shift to 'power-saver' on battery and restore on AC | |
| You decide | Upstream default | |

**User's choice:** Purely manual switching (daemon default).

| Option | Description | Selected |
|--------|-------------|----------|
| Explicitly assert 'balanced' baseline | Run powerprofilesctl set balanced during bootstrap setup | |
| Leave untouched | Let power-profiles-daemon initialize with its internal defaults | ✓ |

**User's choice (User write-in):** "keep default upstream"

**Overarching User Directive:**
"everything about powerprofiles needs to be upstream default dots-hyprland. (whether i gave you decisions or not) No need to do anything else"

---

## the agent's Discretion

- Automated test harness design in `scripts/phase38-power-profiles-assert.sh`.
- Idempotent conflict detection and systemctl check implementation in `bootstrap.sh`.

## Deferred Ideas

- None — discussion stayed strictly within phase scope.
