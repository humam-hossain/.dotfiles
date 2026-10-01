---
phase: 42-telemetry-services-sensor-infrastructure
plan: "01"
subsystem: telemetry
tags: [telemetry, cpu, gpu, disk, storage, sysfs, procfs, quickshell, singletons]

requires:
  - phase: 42-00
    provides: "Validation harness scripts/phase42-telemetry-services-assert.sh"
provides:
  - "HardwareTelemetry.qml singleton with P/E-core segregation, iGPU RC6 delta load, and thermal alerts"
  - "StorageUsage.qml singleton with pure I/O-driven df polling, dynamic active disk focus, and mount classification"
affects:
  - 43-cpu-gpu-component (consumes HardwareTelemetry singleton)
  - 44-memory-storage-component (consumes StorageUsage singleton)
  - 46-left-zone-integration (consumes all status bar singletons)

tech-stack:
  added: []
  patterns:
    - "Non-blocking sysfs/procfs reads via FileView with blockLoading: true; printErrors: false"
    - "Adaptive polling cadence (1000ms active / 3000ms idle) driven by load and fastPollingRequests"
    - "Pure I/O-driven df polling: zero wakeups on idle, asynchronous Process on I/O tick deltas, on-demand refresh()"

key-files:
  created:
    - restow/quickshell/.config/quickshell/ii/services/HardwareTelemetry.qml
    - restow/quickshell/.config/quickshell/ii/services/StorageUsage.qml
  modified: []

key-decisions:
  - "D-01: Adaptive polling cadence (1000ms active, 3000ms idle) in HardwareTelemetry.qml"
  - "D-02: P-core (CPUs 0-11) and E-core (CPUs 12-19) segregation with per-thread loads"
  - "D-03: Exposes EPP energy preference and scaling governor via /sys/devices/system/cpu/cpu0/cpufreq/"
  - "D-04: Intel UHD 770 iGPU load calculated via RC6 sleep delta over sampling intervals"
  - "D-05: Zero root / wattage omission: 100% unprivileged execution with no RAPL/udev dependencies"
  - "D-06 & D-07: Single default packageTemp with peakSystemTemperature and peakDeviceLabel"
  - "D-08: Pure I/O-driven df execution with 15s cooldown and explicit refresh() on-demand"
  - "D-09 & D-10: /proc/diskstats real-time I/O % and throughput, dynamically setting activeDisk"
  - "D-11: Mount filtering classifying physical partitions and GoogleDrive FUSE mounts"

requirements-completed:
  - Foundation for CPUGPU-01
  - Foundation for CPUGPU-02
  - Foundation for CPUGPU-03
  - Foundation for CPUGPU-04
  - Foundation for MEMDSK-03
  - Foundation for MEMDSK-04

coverage:
  - id: HW-01
    description: "HardwareTelemetry.qml CPU, GPU, thermals, and unprivileged execution"
    requirement: CPUGPU-01..04
    verification:
      - kind: other
        ref: "bash scripts/phase42-telemetry-services-assert.sh 2"
        status: pass
    human_judgment: false
  - id: ST-01
    description: "StorageUsage.qml diskstats, df async parsing, and mount classification"
    requirement: MEMDSK-03..04
    verification:
      - kind: other
        ref: "bash scripts/phase42-telemetry-services-assert.sh 3"
        status: pass
    human_judgment: false

## Self-Check: PASSED
- `restow/quickshell/.config/quickshell/ii/services/HardwareTelemetry.qml` exists
- `restow/quickshell/.config/quickshell/ii/services/StorageUsage.qml` exists
- `bash scripts/phase42-telemetry-services-assert.sh 2` PASSED (20/20 checks green)
- `bash scripts/phase42-telemetry-services-assert.sh 3` PASSED (9/9 checks green)
