# External Integrations

This document describes the external integrations, APIs, services, and databases used and configured by the dotfiles environment.

## Services and APIs

- **Wakapi / WakaTime**: The environment integrates with Wakapi (a WakaTime-compatible open-source API) via `https://wakapi.dev/api` for time-tracking and coding analytics across IDEs (`arch/wakatime.sh`).
- **GitHub**: Utilized for source control and managing upstream dependencies (specifically the `vendor/dots-hyprland` submodule from `end-4/dots-hyprland`).
- **Arch User Repository (AUR)**: Deeply integrated within the Arch Linux installation scripts (using `yay`) for retrieving and managing community-maintained software packages.

## Databases and Monitoring

- **Scrutiny**: An automated Hard Drive S.M.A.R.T monitoring solution deployed via Docker (`ghcr.io/analogj/scrutiny:master-omnibus`). It provides a WebUI (Dashboard) and handles regular disk health data collection (`arch/scrutiny.sh`).
- **InfluxDB**: Scrutiny relies on an embedded/bound InfluxDB database instance (mapped to `/opt/scrutiny/influxdb`) to store time-series disk health and performance metrics over time.

## System & IPC Integrations

- **Quickshell IPC**: The custom UI environment leverages Quickshell's inter-process communication (`qs ipc`) to dynamically interact with shell components (like toggling or reloading the status bar) for real-time state management.
- **Docker**: Container engine utilized to run persistent background services such as the Scrutiny monitor.
- **systemd**: Used for managing user-level background services, target initialization, and daemon management (`stow/systemd`).
- **Bluetooth & NetworkManager (bluez / nmcli)**: Direct system-level integrations for robust network and peripheral hardware management from inside the shell environment.
- **PipeWire / WirePlumber**: Audio backend integration configured for advanced routing, hardware compatibility, and low-latency audio processing.
