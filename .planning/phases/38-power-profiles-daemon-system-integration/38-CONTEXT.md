# Phase 38: Power Profiles Daemon System Integration - Context

**Gathered:** 2026-09-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Establish system-level power profile switching on Arch Linux via `power-profiles-daemon`, ensure systemd service lifecycle (`power-profiles-daemon.service`), update package manifests and bootstrap automation (`arch/pkglist-native.txt`, `bootstrap.sh`, `arch/dots-hyprland.sh`), and verify Quickshell's upstream `PowerProfilesToggle.qml` quick-toggle in the Right Sidebar adhering strictly to default upstream `dots-hyprland` behavior with zero custom QML modifications.

</domain>

<decisions>
## Implementation Decisions

### Upstream Alignment & Shell UI
- **D-01 (Strict Upstream Default):** Everything about power profiles must strictly match upstream `dots-hyprland` defaults. No custom QML overlays in `restow/quickshell/`, no custom OSD notifications, and no modified cycling logic. Upstream's `PowerProfilesToggle.qml` and `AndroidPowerProfileToggle.qml` are used unmodified as provided in `vendor/dots-hyprland`.
- **D-02 (Standard 3-State Cycling):** The quick toggle uses standard upstream 3-state cycling (`Power Saver` -> `Balanced` -> `Performance` -> `Power Saver`, or `Balanced` <-> `Power Saver` if performance profile is unsupported by hardware) via `Quickshell.Services.UPower`.
- **D-03 (Sidebar-Only Visual Feedback):** State changes update the quick-toggle icon (`energy_savings_leaf`, `airwave`, `local_fire_department`) and status label directly within the Right Sidebar with no desktop toast or OSD notifications.
- **D-04 (Default Grid Placement):** `powerProfile` retains its upstream default 4th slot in `Config.qml`'s quick toggle list (`network`, `bluetooth`, `easyEffects`, `powerProfile`, ...), requiring no config overrides.

### System Package & Service Provisioning
- **D-05 (Package Manifest Integration):** Add `power-profiles-daemon` to `arch/pkglist-native.txt` in alphabetical order, ensuring clean package tracking for Arch Linux.
- **D-06 (Bootstrap Package Verification):** In `bootstrap.sh` (`step_packages`), verify that `power-profiles-daemon` is installed, installing it via pacman/yay if missing during fresh reproduction.
- **D-07 (Idempotent Service Activation):** In `bootstrap.sh`, enable and start `power-profiles-daemon.service` idempotently (checking if already active/enabled first before invoking sudo) to ensure zero-overhead runs on already-configured systems.
- **D-08 (Preflight Conflict Detection):** In `bootstrap.sh`, check for active conflicting services (`tlp.service`, `auto-cpufreq.service`, `tuned.service`), safely alerting or disabling them to prevent CPU governor race conditions.
- **D-09 (Repository Verification Scope):** `arch/dots-hyprland.sh verify --strict` maintains its strict focus on symlinks and git working-tree cleanliness; runtime service health is asserted via the dedicated test harness and bootstrap step rather than failing file verification on offline systemd services.

### Power Management Policy
- **D-10 (Manual Switching & Daemon State Persistence):** Profile switching remains purely user-directed via the Quickshell toggle or `powerprofilesctl`. No automated AC/battery udev scripts or rules are introduced; `power-profiles-daemon` manages hardware governors and persists profile state across reboots via `/var/lib/power-profiles-daemon/state.ini`.

### the agent's Discretion
- Exact bash test harness structure in `scripts/phase38-power-profiles-assert.sh` verifying `powerprofilesctl`, D-Bus interface `net.hadess.PowerProfiles`, service status, and Quickshell AST syntax.
- Exact idempotent check syntax in `bootstrap.sh`.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap & Requirements
- `.planning/ROADMAP.md` §Phase 38 — Phase scope, success criteria, and requirements mapping.
- `.planning/REQUIREMENTS.md` §Power Profiles Management — `POWER-01`, `POWER-02`, `POWER-03`.
- `.planning/STATE.md` §Milestone v0.8 — Milestone position and accumulated project context.

### System Installation & Packaging
- `arch/pkglist-native.txt` — Authoritative native package manifest.
- `bootstrap.sh` — Step 2 package verification, prerequisite installation, and service activation.
- `arch/dots-hyprland.sh` — Wrapper execution and verification contract.

### Upstream Quickshell Integration
- `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/models/quickToggles/PowerProfilesToggle.qml` — Upstream QuickToggleModel using `Quickshell.Services.UPower`.
- `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/sidebarRight/quickToggles/androidStyle/AndroidPowerProfileToggle.qml` — Upstream AndroidQuickToggleButton delegate.
- `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/Config.qml` — Default toggle list containing `"powerProfile"`.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `PowerProfilesToggle.qml`: Pre-existing upstream model connecting directly to `Quickshell.Services.UPower.PowerProfiles`.
- `AndroidPowerProfileToggle.qml`: Pre-existing upstream button wrapping `PowerProfilesToggle`.
- `AndroidToggleDelegateChooser.qml`: Pre-existing delegate choice for `roleValue: "powerProfile"`.

### Established Patterns
- **Zero Upstream Modifications:** Submodule `vendor/dots-hyprland` is never modified directly. Because upstream already implements power profiles toggle logic, Phase 38 only needs to provide the system daemon and verify integration.
- **Idempotent Service Management:** Systemd user and system services are checked for active state before invoking systemctl changes.
- **Package Manifest Tracking:** Explicitly installed packages are mirrored in `arch/pkglist-native.txt`.

### Integration Points
- `arch/pkglist-native.txt`: Insert `power-profiles-daemon` alphabetically.
- `bootstrap.sh`: Add check/install for `power-profiles-daemon` in `step_packages`, and service enablement check in system configuration.
- `net.hadess.PowerProfiles`: System D-Bus interface consumed by `Quickshell.Services.UPower`.

</code_context>

<specifics>
## Specific Ideas

- **User Directives:**
  - *"power profiles everything should be default dots-hyprland basically upstream. change nothing"*
  - *"everything about powerprofiles needs to be upstream default dots-hyprland. (whether i gave you decisions or not) No need to do anything else"*

</specifics>

<deferred>
## Deferred Ideas

- None — discussion stayed strictly within phase scope.

</deferred>

---

*Phase: 38-Power Profiles Daemon System Integration*
*Context gathered: 2026-09-22*
