# Phase 41: End-to-End Verification & Repository Integrity - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-25
**Phase:** 41-end-to-end-verification-repository-integrity
**Areas discussed:** Harness Execution Strategy, Environment Resilience, Git Churn & Working-Tree Integrity, Entrypoint & Milestone Integration

---

## Harness Execution Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Hybrid first-principles assert | Dedicated end-to-end interaction tests directly in phase41-interactions-assert.sh, with sub-harnesses executed by default (skipping via --quick) | ✓ |
| Self-contained first-principles only | All cross-feature verification lives directly in phase41-interactions-assert.sh with zero sub-script dependencies | |
| Orchestrator wrapper | Primarily executes the 4 individual phase harnesses in sequence, then runs repository integrity checks | |

**User's choice:** Hybrid first-principles assert engine with modular section breakdown and default comprehensive milestone suite execution.
**Notes:** 6 distinct sections: S1 Restow symlink isolation, S2 Power profiles, S3 Media popup positioning, S4 Notification dismissal/URL/OTP, S5 Clock & Volume ceiling, S6 Repository integrity & verify --strict.

---

## Environment Resilience

| Option | Description | Selected |
|--------|-------------|----------|
| Two-tier gating (Hard AST + Soft Live) | Always fail hard on symlinks, static QML AST, regex math, and config contracts; gracefully soft-skip [SOFT] live IPC/D-Bus probes if no graphical session is active | ✓ |
| Strict live requirement | Require active graphical session and running daemons, failing hard if live probes fail | |
| Pure static/mock simulation | Do not perform live D-Bus/IPC calls; test all logic via headless JS/Lua AST parsing | |

| Tool Option | Description | Selected |
|-------------|-------------|----------|
| Fail hard on all tools | Require all tools (including powerprofilesctl, wpctl, qs) to be present on PATH or fail the entire harness | ✓ |
| Strict dependency check | Require bash, jq, node/python for static tests; treat session binaries as soft prerequisites | |

**User's choice:** Two-tier gating with strict binary prerequisites.
**Notes:** All tools are confirmed present in `/usr/bin/`. Quickshell process queries must target `-c ii` profile.

---

## Git Churn & Working-Tree Integrity

| Option | Description | Selected |
|--------|-------------|----------|
| Dual-layer churn check | Assert zero execution churn (git status delta before vs after must be identical) AND assert vendor/dots-hyprland submodule has 0 uncommitted changes | ✓ |
| Strict 100% porcelain clean check | Require git status --porcelain to be completely empty at start and end of harness run | |

| Audit Option | Description | Selected |
|--------------|-------------|----------|
| Direct execution + strict string & code audit | Execute ./arch/dots-hyprland.sh verify --strict, assert exit code 0 AND verify stdout contains FAIL=0 and FINDINGS=0; use trap cleanup with mktemp | ✓ |
| Exit code only | Check exit code 0 without parsing stdout | |

**User's choice:** Dual-layer churn check and direct strict verify audit.
**Notes:** Isolates pre-existing uncommitted files outside milestone v0.8 scope (`dolphinrc`, `lazy-lock.json`).

---

## Entrypoint & Milestone Integration

| Option | Description | Selected |
|--------|-------------|----------|
| Standard scripts/ convention | Keep scripts/phase41-interactions-assert.sh as the standalone executable harness following the phaseNN-*.sh convention without mutating arch/dots-hyprland.sh | ✓ |
| Add verify integration | Add a hook or flag in arch/dots-hyprland.sh verify to optionally run phase41-interactions-assert.sh | |

| Reporting Option | Description | Selected |
|------------------|-------------|----------|
| Milestone Closeout Verification | 41-VERIFICATION.md documents both Phase 41 assertions and the milestone v0.8 cross-phase summary table | ✓ |
| Phase 41 only | 41-VERIFICATION.md focuses strictly on INTG-01..03 requirements | |

**User's choice:** Standalone harness under `scripts/` with comprehensive milestone reporting in `41-VERIFICATION.md`.
**Notes:** Clean separation of concerns without modifying wrapper scripts.

---

## the agent's Discretion

None — all decisions captured with explicit user input and alignment.

## Deferred Ideas

- Milestone closeout staging: clean staging or commit of unrelated files (`restow/dolphinrc/.config/dolphinrc` and `stow/nvim/.config/nvim/lazy-lock.json`) deferred to milestone closeout.
