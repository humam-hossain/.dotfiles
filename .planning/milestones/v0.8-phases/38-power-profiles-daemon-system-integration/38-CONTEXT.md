# Phase 38: Power Profiles Daemon System Integration - Context

**Gathered:** 2026-09-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Install and activate `power-profiles-daemon` on Arch Linux, record it in repository package manifests (`arch/pkglist-native.txt`, `bootstrap.sh`), and verify that Quickshell's existing upstream quick-toggle (`PowerProfilesToggle.qml`) functions live.

**Zero QML Changes:** Upstream `dots-hyprland` already provides complete toggle models, 3-state cycling, icons, and D-Bus integration. This phase touches strictly OS package provisioning, systemd service enablement, and bootstrap tracking.

</domain>

<decisions>
## Implementation Decisions

### Upstream Alignment & Shell UI
- **D-01 (Strict Upstream Parity — Zero QML Modifications):** Use upstream `dots-hyprland` power profiles implementation 100% as-is. Do not create any QML overlays in `restow/quickshell/`, do not alter cycling logic, and do not add custom OSDs, popups, or scripts.
- **D-02 (Native Upstream 3-State Cycle):** Upstream `PowerProfilesToggle.qml` cycles `Power Saver` -> `Balanced` -> `Performance` via native `Quickshell.Services.UPower` talking to `net.hadess.PowerProfiles`. This works out-of-the-box once the system daemon is active.
- **D-03 (Sidebar-Only Visual Feedback):** State changes update the button icon (`energy_savings_leaf`, `airwave`, `local_fire_department`) and status text inside the Right Sidebar grid naturally without extra notifications.

### Package Provisioning & Bootstrap Automation
- **D-04 (Package Manifest Tracking):** Add `power-profiles-daemon` to `arch/pkglist-native.txt` in alphabetical order to maintain authoritative Arch package tracking.
- **D-05 (Bootstrap Integration):** In `bootstrap.sh` (`step_packages`), verify that `power-profiles-daemon` is installed, installing it if missing during reproduction on fresh machines.
- **D-06 (Idempotent Systemd Service Activation):** In `bootstrap.sh`, enable and start `power-profiles-daemon.service` with an idempotent check (`systemctl is-active --quiet power-profiles-daemon.service`) before invoking sudo to ensure zero-overhead runs on already-configured machines.
- **D-07 (Repository Verification Invariant):** `arch/dots-hyprland.sh verify --strict` maintains its strict focus on symlinks and git repository drift with zero runtime coupling.

### Power Management Policy
- **D-08 (Default Upstream Policy):** Profile switching remains purely manual via the Quickshell toggle or `powerprofilesctl`. No automated AC/battery switching scripts or udev rules are introduced; `power-profiles-daemon` manages CPU scaling and persists profile state across reboots via its standard state file.

### the agent's Discretion
- Exact check syntax in `bootstrap.sh` and verification assertion commands.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap & Requirements
- `.planning/ROADMAP.md` §Phase 38 — Phase scope, success criteria, and requirements mapping.
- `.planning/REQUIREMENTS.md` §Power Profiles Management — `POWER-01`, `POWER-02`, `POWER-03`.

### System Installation & Packaging
- `arch/pkglist-native.txt` — Authoritative native package manifest.
- `bootstrap.sh` — Prerequisite checking and service activation.
- `arch/dots-hyprland.sh` — Wrapper execution and verification contract.

### Upstream Component (Reference Only — No Edits)
- `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/models/quickToggles/PowerProfilesToggle.qml` — Existing upstream toggle model.
- `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/sidebarRight/quickToggles/androidStyle/AndroidPowerProfileToggle.qml` — Existing upstream quick toggle button.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Upstream `PowerProfilesToggle.qml`: Pre-existing component using `Quickshell.Services.UPower.PowerProfiles`.
- Upstream `AndroidQuickPanel.qml`: Already includes `"powerProfile"` in the quick toggles grid.

### Established Patterns
- **Pure System Provisioning:** No in-repo QML overrides needed; upstream code is already complete.
- **Authoritative Package Manifest:** Explicit native packages are listed in `arch/pkglist-native.txt`.
- **Idempotent Automation:** `bootstrap.sh` checks status before mutating systemd state.

### Integration Points
- `arch/pkglist-native.txt`: Insert `power-profiles-daemon` alphabetically.
- `bootstrap.sh`: Add check/install in `step_packages` and `systemctl enable --now` check.
- `net.hadess.PowerProfiles`: D-Bus system service provided by `power-profiles-daemon`.

</code_context>

<specifics>
## Specific Ideas

- **User Directives:**
  - *"everything about powerprofiles needs to be upstream default dots-hyprland. (whether i gave you decisions or not) No need to do anything else"*
  - *"i would like to keep everything default upstream powerprofile setup basically how it is in the dots-hyprland. do i need a phase for this. i think i only have to install it"*

</specifics>

<deferred>
## Deferred Ideas

- None — discussion stayed strictly within phase scope.

</deferred>

---

*Phase: 38-Power Profiles Daemon System Integration*
*Context gathered: 2026-09-22*
