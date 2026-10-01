---
phase: 42-telemetry-services-sensor-infrastructure
plan: "02"
subsystem: telemetry
tags: [ping, network, server, daemon, memory, meminfo, singletons, quickshell]

requires:
  - phase: 42-00
    provides: "Validation harness scripts/phase42-telemetry-services-assert.sh"
provides:
  - "stow/system_monitor/.../server.py clean structured JSON targets payload"
  - "PingService.qml singleton with 5s polling and 15s offline backoff"
  - "ResourceUsage.qml restow overlay with extended memory telemetry (D-15)"
affects:
  - 44-memory-storage-component (consumes ResourceUsage extended memory fields)
  - 45-network-ping-component (consumes PingService singleton)
  - 46-left-zone-integration (consumes status bar services)

tech-stack:
  added: []
  patterns:
    - "Asynchronous XMLHttpRequest client in Quickshell with fail-soft offline backoff"
    - "Clean JSON API response with structured targets array from Python HTTP server"
    - "Restow overlay on vendor ResourceUsage.qml parsing /proc/meminfo memoryAvailable/Buffers/Cached"

key-files:
  created:
    - restow/quickshell/.config/quickshell/ii/services/PingService.qml
    - restow/quickshell/.config/quickshell/ii/services/ResourceUsage.qml
  modified:
    - stow/system_monitor/.config/system_monitor/ping/server.py
    - .gitignore

key-decisions:
  - "D-12: server.py returns clean JSON targets array with host, label, ms, quality, class, text_value, color"
  - "D-13: PingService.qml polls every 5s with 15s backoff when offline or unreachable"
  - "D-14: Exposes WAN (8.8.8.8), Gateway (192.168.0.1), and Home Server (192.168.0.104) metrics"
  - "D-15: ResourceUsage.qml parses memoryAvailable, memoryBuffers, and memoryCached from /proc/meminfo"

requirements-completed:
  - Foundation for NETPING-01
  - Foundation for NETPING-02
  - Foundation for NETPING-03
  - Foundation for NETPING-04
  - Foundation for NETPING-05
  - Foundation for MEMDSK-01
  - Foundation for MEMDSK-02

coverage:
  - id: PING-01
    description: "PingService.qml & server.py JSON schema and live API"
    requirement: NETPING-01..05
    verification:
      - kind: other
        ref: "bash scripts/phase42-telemetry-services-assert.sh 4"
        status: pass
    human_judgment: false
  - id: MEM-01
    description: "ResourceUsage.qml extended memory properties"
    requirement: MEMDSK-01..02
    verification:
      - kind: other
        ref: "bash scripts/phase42-telemetry-services-assert.sh 5"
        status: pass
    human_judgment: false

## Self-Check: PASSED
- `stow/system_monitor/.config/system_monitor/ping/server.py` modified and container rebuilt/restarted
- `restow/quickshell/.config/quickshell/ii/services/PingService.qml` exists
- `restow/quickshell/.config/quickshell/ii/services/ResourceUsage.qml` exists
- `bash scripts/phase42-telemetry-services-assert.sh 4` PASSED
- `bash scripts/phase42-telemetry-services-assert.sh 5` PASSED
