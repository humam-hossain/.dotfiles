# Project Research: Stack for v1.2 Waybar → Quickshell Migration

**Project:** Cross-Platform Dotfiles
**Milestone:** v1.2 Waybar → Quickshell Migration
**Researched:** 2026-05-02

## New Package Dependencies (Arch Linux)

| Package | Source | Purpose |
|---------|--------|---------|
| `quickshell` | `[extra]` (0.2.1-6) | QML shell framework — all modules compiled in |
| `ddcutil` | `[extra]` | External monitor brightness via DDC/CI |
| `i2c-tools` | `[extra]` | i2c bus access required by ddcutil |

**No AUR needed.** `quickshell` in `[extra]` includes all required modules:
- Hyprland IPC (`Quickshell.Hyprland`)
- PipeWire audio (`Quickshell.Services.Pipewire`)
- MPRIS media (`Quickshell.Services.Mpris`)
- System tray (`Quickshell.Services.SystemTray`)
- Networking (`Quickshell.Networking`)

**Install script additions** (`arch/quickshell.sh`):
```bash
sudo pacman -S quickshell ddcutil i2c-tools
sudo modprobe i2c-dev
sudo usermod -aG i2c "$USER"
```
i2c group membership and module load are required at install time — cannot defer to runtime.

## Native QML Integrations (No Shell Scripts)

| Widget | QML Module | Import |
|--------|-----------|--------|
| Workspaces | `Quickshell.Hyprland` | `Hyprland.workspaces` model |
| Active window title | `Quickshell.Hyprland` | `HyprlandFocusedClient.title` |
| Volume / mute | `Quickshell.Services.Pipewire` | `PwObjectTracker` → sink audio |
| Music (MPRIS) | `Quickshell.Services.Mpris` | `Mpris.players` model |
| System tray | `Quickshell.Services.SystemTray` | `SystemTray.items` model |
| Network status | `Quickshell.Networking` | NM backend, `NetworkManager` |
| Clock | Qt built-in | `Qt.formatDateTime(new Date(), ...)` |

**`playerctl` is redundant** — `Quickshell.Services.Mpris` replaces it natively over D-Bus.
**`pactl`/`pamixer` are redundant** — `Quickshell.Services.Pipewire` replaces them natively.

## Script-Backed Integrations (Process)

| Widget | Script | Method |
|--------|--------|--------|
| Ping monitor | `ping_status.sh` | `Process` + `StdioCollector` + 5s `Timer` |
| Weather current | `curr_weather.sh` | `Process` + `StdioCollector` + 200s `Timer` |
| Weather forecast | `forcast_weather.sh` | `Process` + `StdioCollector` + 200s `Timer` |
| Memory | `memory.sh` | `Process` + `StdioCollector` + 5s `Timer` |
| Backlight | `ddcutil getvcp 10` | `Process` + `StdioCollector` + 5s `Timer` + signal on change |
| swaync count | `swaync-client -s` | `Process` + `StdioLineParser` (streaming) |
| Lock | `hyprlock` | `Process.startDetached()` on click |
| Power | `wlogout` | `Process.startDetached()` on click |

**Important:** `Process` does not expand `~` or `$HOME` in command arrays.
Use `["bash", "-c", "$HOME/.config/waybar/scripts/..."]` wrapper.

## Swaync Coexistence Constraint

**Quickshell's `NotificationServer` and swaync both claim `org.freedesktop.Notifications` on D-Bus — they cannot coexist.**

Resolution: Keep swaync as the notification daemon. Do NOT use `Quickshell.Services.Notifications.NotificationServer`. Read swaync count and state via `swaync-client -s` (streaming Process). Notification center panel calls `swaync-client -t` to toggle swaync's native panel.

## PipeWire Note

`PwObjectTracker` binding is required before reading PipeWire node audio properties — this is a non-obvious prerequisite. Volume widget phase must bind tracker first.

---
*Research completed: 2026-05-02*
