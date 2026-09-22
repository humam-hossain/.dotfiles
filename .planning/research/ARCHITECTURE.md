# Architecture Research

**Domain:** Linux Desktop Shell (Quickshell / Qt 6 QML / Hyprland / D-Bus / Arch Linux)
**Researched:** 2026-09-22
**Confidence:** HIGH

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       Top Status Bar (BarContent.qml)                       │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────────────────────────────┐  │
│  │ Left Zone    │  │ Center Zone  │  │ Right Zone                        │  │
│  │ [Weather]    │  │ [Workspaces] │  │ [Media Pill] [Voice] [Tray] [Btn] │  │
│  │ [Resources]  │  │ [Clock/Date] │  │       │                           │  │
│  └──────────────┘  └──────────────┘  └───────┼───────────────────────────┘  │
└──────────────────────────────────────────────┼──────────────────────────────┘
                                               │ dynamic geometry
                                               ▼
                        ┌─────────────────────────────────────────┐
                        │      MediaControls.qml (PanelWindow)    │
                        │ - Tracks Media pill position & screen   │
                        │ - Anchors directly beneath Media pill   │
                        │ - Clamped to screen horizontal bounds   │
                        └─────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                    System Control & Quick Toggles                           │
│  ┌──────────────────────────────┐       ┌────────────────────────────────┐  │
│  │ PowerProfilesToggle.qml      │──────▶│ D-Bus (net.hadess.PowerProfiles│  │
│  │ - Cycles profiles            │       │   via power-profiles-daemon)   │  │
│  │ - Reflects active state icon │       │ - Power Saver / Balanced /     │  │
│  │                              │       │   Performance                  │  │
│  └──────────────────────────────┘       └────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                         Notification Pipeline                               │
│                                                                             │
│  [D-Bus org.freedesktop.Notifications] ──▶ [Notifications.qml Singleton]    │
│                                                       │                     │
│                           ┌───────────────────────────┴─────────────────┐   │
│                           ▼                                             ▼   │
│           ┌──────────────────────────────┐              ┌───────────────┴┐  │
│           │ Toast (NotificationPopup.qml)│              │ Right Sidebar  │  │
│           │ - Transient screen overlay   │              │   Notification │  │
│           │ - Auto-timeout & hover pause │              │   Center       │  │
│           │ - Clean header (no 'X' btn)  │              │ (SidebarRight) │  │
│           └──────────────────────────────┘              └───────┬────────┘  │
│                                                                 │           │
│                                   ┌─────────────────────────────▼─────────┐ │
│                                   │ NotificationGroup.qml                 │ │
│                                   │ - Header 'X' close button (Sidebar)   │ │
│                                   │ - Expand/collapse group chevron       │ │
│                                   └─────────────────────────────┬─────────┘ │
│                                                                 │           │
│                                   ┌─────────────────────────────▼─────────┐ │
│                                   │ NotificationItem.qml &                │ │
│                                   │ NotificationUtils.qml                 │ │
│                                   │ - Smart body click (App D-Bus / URL)  │ │
│                                   │ - Embedded URL extraction             │ │
│                                   │ - Regex OTP detection & Copy chip     │ │
│                                   └───────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Component Responsibilities

| Component | Path | Responsibility | Implementation Details |
|-----------|------|----------------|------------------------|
| **Media Popup Anchor** | `restow/quickshell/.../modules/ii/mediaControls/MediaControls.qml` | Dynamically positions media control panel under the status bar Media pill. | Reads active screen width, resolves the Media pill's relative X coordinate or Right Zone offset, and clamps `leftMargin` so popup sits directly below the pill without off-screen clipping. |
| **Power Profile Daemon** | `power-profiles-daemon` & `arch/pkglist-native.txt` | System-wide D-Bus service governing CPU governors and EPP energy performance preferences. | Installed via pacman, activated via `systemctl enable --now power-profiles-daemon.service`, queried by Quickshell's native `PowerProfiles` service. |
| **Sidebar Quick-Close Button** | `restow/quickshell/.../modules/common/widgets/NotificationGroup.qml` | 1-click dismissal of notification groups strictly in the right sidebar. | Adds a `RippleButton` with `"close"` MaterialSymbol to `topRow` when `!popup`. Invokes `root.destroyWithAnimation()` on click. |
| **Smart Notification Body Click** | `restow/quickshell/.../modules/common/widgets/NotificationItem.qml` | Dispatches clicks on the notification body to the originating app or opens extracted links. | Adds an interactive click target on `summaryRow` and body; calls `Notifications.attemptInvokeAction(id, "default")` or invokes `Qt.openUrlExternally(url)` if an external link is present. |
| **OTP / Link Extractor** | `restow/quickshell/.../modules/common/functions/NotificationUtils.qml` | Parsing helper for verification codes and Chromium URL headers. | Utility functions: `extractOTPCode(body, summary)` returning `{ code: string } | null`, and `extractTargetUrl(body, appName)` returning target link. |
| **OTP Quick Copy Chip** | `restow/quickshell/.../modules/common/widgets/NotificationItem.qml` | Visual action chip offering 1-click OTP clipboard copy. | Rendered conditionally when `extractOTPCode()` detects a valid 4–8 digit verification code. Copies to `Quickshell.clipboardText` with instant visual feedback. |

## Overlay Architecture & Stow Taxonomy

All customized QML components live in the repo under `restow/quickshell/` and are symlinked into `~/.config/quickshell/ii/` via GNU Stow leaf symlinks:

```
restow/quickshell/.config/quickshell/ii/
├── modules/
│   ├── common/
│   │   ├── functions/
│   │   │   └── NotificationUtils.qml   # Link extraction & OTP regex
│   │   └── widgets/
│   │       ├── NotificationGroup.qml   # Header 'X' close button (sidebar only)
│   │       └── NotificationItem.qml    # Body click handler & OTP copy chip
│   └── ii/
│       ├── bar/
│       │   └── BarContent.qml          # Exposes Media pill positioning/anchor
│       └── mediaControls/
│           └── MediaControls.qml       # Dynamic horizontal positioning
```

This guarantees:
1. `vendor/dots-hyprland` submodule stays completely pristine with zero git working-tree churn.
2. `arch/dots-hyprland.sh verify --strict` passes with `0 findings`.
3. Reproducibility across fresh machines via `./bootstrap.sh`.
