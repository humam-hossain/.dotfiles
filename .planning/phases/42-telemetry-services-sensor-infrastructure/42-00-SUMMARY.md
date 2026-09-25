---
phase: 42-telemetry-services-sensor-infrastructure
plan: "00"
subsystem: testing
tags: [telemetry, sensor, wave0, assert-harness, nyquist]

requires:
  - phase: 41-user-experience-polish-feedback-loops-and-corner-cases
    provides: "Stable top status bar shell and verified system components"
provides:
  - "scripts/phase42-telemetry-services-assert.sh Wave 0 harness covering Sections 1–6"
  - "42-VALIDATION.md Wave 0 compliant with verified failing direction"
affects:
  - 42-01 (HardwareTelemetry.qml and StorageUsage.qml verification)
  - 42-02 (PingService.qml and server.py verification)
  - 42-03 (Full assertion run and stow integrity)

tech-stack:
  added: []
  patterns:
    - "Bash assertion harness with positional [1-6], -s/--section, -q/--quick, and --help flags"
    - "Nyquist compliance: verified failing direction before Wave 1 implementation"

key-files:
  created:
    - scripts/phase42-telemetry-services-assert.sh
  modified:
    - .planning/phases/42-telemetry-services-sensor-infrastructure/42-VALIDATION.md

key-decisions:
  - "Wave 0 scaffolding asserts sections 1–6, failing on missing singletons and clean server.py targets payload"
  - "Enforces unprivileged execution with zero RAPL root/udev dependencies (T-42-01 / D-05)"

patterns-established:
  - "Run `bash scripts/phase42-telemetry-services-assert.sh --quick` for sampling during task iterations"
  - "Run `bash scripts/phase42-telemetry-services-assert.sh <section>` for targeted plan verification"

requirements-completed: []

coverage:
  - id: HARNESS-01
    description: "Wave 0 assert script structure, permissions, and positional selector"
    requirement: "Validation harness architecture mandate (Nyquist failing direction)"
    verification:
      - kind: other
        ref: "scripts/phase42-telemetry-services-assert.sh"
        status: pass
    human_judgment: false

## Self-Check: PASSED
- `scripts/phase42-telemetry-services-assert.sh` exists and is executable
- Nyquist failing direction confirmed (7 failures across sections 2–6)
