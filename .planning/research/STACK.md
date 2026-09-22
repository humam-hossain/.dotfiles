# Stack Research

**Domain:** Linux Desktop Shell (Quickshell / Qt 6 QML / Hyprland / D-Bus / Arch Linux)
**Researched:** 2026-09-22
**Confidence:** HIGH

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| `power-profiles-daemon` | 0.30+ | Freedesktop D-Bus daemon (`net.hadess.PowerProfiles`) | Standard Linux power profiles daemon implemented by UPower/GNOME/KDE. Quickshell's `PowerProfilesToggle.qml` relies strictly on this D-Bus service. |
| `Quickshell` / `QtQuick` | Qt 6.11 / Quickshell Git | Wayland layer-shell UI toolkit | Primary shell architecture for dots-hyprland. Provides native `PanelWindow`, `WlrLayershell`, `MouseArea`, and animations. |
| `Quickshell.Services.Notifications` | Native | D-Bus notification server tracking | Owns tracked notification lifecycle, `attemptInvokeAction()`, and `discardNotification()`. |
| `Qt.openUrlExternally` / `xdg-open` | Qt 6 / Freedesktop | External link dispatching | Directly handles launching the user's default browser on URL activation with zero custom shell subprocess overhead. |
| ECMAScript Regex Engine | V8 / Qt QML JS | Pattern matching for OTP codes & Chromium URLs | Built directly into Qt QML engine; enables microsecond-latency text parsing for 4–8 digit verification codes and link extraction. |

### Supporting Libraries & Overlay Paths

| Library / Path | Purpose | When to Use |
|----------------|---------|-------------|
| `restow/quickshell/` | GNU Stow overlay directory | All personal QML overrides (`MediaControls.qml`, `NotificationGroup.qml`, `NotificationItem.qml`, `NotificationUtils.qml`) to keep `vendor/dots-hyprland` pristine. |
| `arch/pkglist-native.txt` | Native package inventory | Registering `power-profiles-daemon` so `./bootstrap.sh` and fresh installs automatically pull the package. |
| `arch/dots-hyprland.sh` | System installer & verifier | Enabling `power-profiles-daemon.service` during post-setup and asserting repository cleanliness via `--strict`. |

### Development & Verification Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| `qs -c ii` | Live Quickshell process | Live UI reload on QML save. |
| `powerprofilesctl` | CLI control tool for power profiles | Testing and asserting profile state transitions (`powerprofilesctl list`, `get`, `set`). |
| `notify-send` | CLI notification sender | Emitting test notifications with actions, URLs, and OTP codes for verification. |
| `arch/dots-hyprland.sh verify --strict` | Repo integrity verifier | Ensures 0 unmanaged drift and validates Stow leaf symlinks. |

## Installation

```bash
# Install power-profiles-daemon on Arch Linux
sudo pacman -S --needed power-profiles-daemon

# Enable and start the systemd service immediately
sudo systemctl enable --now power-profiles-daemon.service
```

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| `power-profiles-daemon` | `tlp` / `auto-cpufreq` / `tuned` | TLP or tuned are suited for advanced tuning, but Quickshell specifically binds to the Freedesktop `net.hadess.PowerProfiles` D-Bus API, which requires `power-profiles-daemon`. |
| `restow/quickshell/` overlays | Editing `vendor/dots-hyprland` directly | Direct edits create git churn in the submodule and break reproducibility. `restow/` preserves upstream pins. |
| Regex OTP parser in `NotificationUtils.qml` | External Python daemon | In-QML regex runs synchronously with zero process spawning overhead, eliminating latency and security risks. |

## What NOT to Use

- **Do NOT use `systemctl --user` for `power-profiles-daemon`**: It is a root system daemon running on the system bus (`/run/dbus/system_bus_socket`), not a user session service.
- **Do NOT add close buttons to `NotificationPopup.qml`**: Screen toast popups are intended to remain minimal and dismiss via hover/timeout as requested by the user.
- **Do NOT hardcode offsets for `MediaControls.qml`**: Hardcoding pixel margins breaks across varying monitor resolutions, screen scaling, and status bar configurations.
