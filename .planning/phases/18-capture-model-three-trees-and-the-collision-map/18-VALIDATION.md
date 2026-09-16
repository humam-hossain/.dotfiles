---
phase: "18"
slug: "capture-model-three-trees-and-the-collision-map"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-09-13"
validated: "2026-09-16"
---

# Phase 18 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `18-RESEARCH.md` § Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None installed. Repo convention is standalone `scripts/phaseNN-*-assert.sh` executables using the `[PASS]` / `[FAIL]` / `[INFO]` contract |
| **Config file** | none — by design |
| **Quick run command** | `./scripts/phase18-capture-model-assert.sh` |
| **Full suite command** | `./scripts/phase18-capture-model-assert.sh && ./scripts/phase17-unblock-assert.sh && ./scripts/phase16-retire-assert.sh && ./scripts/phase14-verify.sh && ./scripts/phase13-d19-assert.sh && ./scripts/phase12-full-smoke.sh && ./scripts/phase11-dispositions-assert.sh && ./scripts/phase10-inventory-assert.sh` |
| **Estimated runtime** | ~30 seconds quick, ~120 seconds full suite |

Existing assert inventory (verified against `ls scripts/`): `phase02-config-assert.py`,
`phase03-config-assert.py`, `phase04-ipc-reload-assert.py`, `phase10-inventory-assert.sh`,
`phase11-dispositions-assert.sh`, `phase12-full-smoke.sh`, `phase13-d19-assert.sh`,
`phase14-verify.sh`, `phase16-retire-assert.sh`, `phase17-unblock-assert.sh`.

---

## Sampling Rate

- **After every task commit:** `bash -n` on every touched script, plus `./scripts/phase18-capture-model-assert.sh` for the sections already implemented
- **After every plan wave:** `./scripts/phase18-capture-model-assert.sh && ./scripts/phase17-unblock-assert.sh` — the Phase 17 call-site count changes in this phase, so it is the highest-risk regression
- **Before `/gsd-verify-work`:** the full eight-script suite must be green, matching the Phase 16 D-40 gate precedent recorded in STATE.md
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

Task IDs are mapped to Phase 18 execution plans; all requirements are verified by `./scripts/phase18-capture-model-assert.sh`.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 18-02-01 | 18-02 | 1 | CAP-01 | — | N/A | integration | `./scripts/phase18-capture-model-assert.sh` §1 | ✅ exists | ✅ green |
| 18-01-01 | 18-01 | 1 | CAP-02 | — | N/A | integration | `./scripts/phase18-capture-model-assert.sh` §2 | ✅ exists | ✅ green |
| 18-01-02 | 18-01 | 1 | CAP-03 | — | N/A | integration | `./scripts/phase18-capture-model-assert.sh` §3 | ✅ exists | ✅ green |
| 18-01-02 | 18-01 | 1 | CAP-03 (determinism, F-3) | — | N/A | unit | `./scripts/phase18-capture-model-assert.sh` §3 | ✅ exists | ✅ green |
| 18-03-01 | 18-03 | 2 | CAP-08 | T-18-flag-smuggling | `--exp-files` refused before dispatch; never forwarded to `./setup` | e2e | `./scripts/phase18-capture-model-assert.sh` §4 | ✅ exists | ✅ green |
| 18-02-02 | 18-02 | 1 | CAP-07 | — | `--adopt` absent under `arch/` and `scripts/` | unit | `./scripts/phase18-capture-model-assert.sh` §5 | ✅ exists | ✅ green |
| 18-04-01 | 18-04 | 3 | FIX-03 | — | N/A | integration | `./scripts/phase18-capture-model-assert.sh` §6 | ✅ exists | ✅ green |
| 18-04-02 | 18-04 | 3 | FIX-05 | — | `verify` returns a real exit code with the submodule de-initialised | e2e | `./scripts/phase18-capture-model-assert.sh` §7 | ✅ exists | ✅ green |
| 18-04-03 | 18-04 | 3 | CAP-05 | T-18-path-traversal | write confined under `capture/` by resolved-path comparison (D-39) | integration | `./scripts/phase18-capture-model-assert.sh` §7 | ✅ exists | ✅ green |
| 18-04-03 | 18-04 | 3 | CAP-05 (untracked mirror, F-8) | T-18-dirty-check | untracked and absent mirrors are refused, not silently accepted | integration | `./scripts/phase18-capture-model-assert.sh` §7 | ✅ exists | ✅ green |
| 18-04-03 | 18-04 | 3 | CAP-05 (D-42 dry run) | — | `--dry-run` leaves repo and `git status` unchanged | integration | `./scripts/phase18-capture-model-assert.sh` §7 | ✅ exists | ✅ green |
| 18-04-03 | 18-04 | 3 | CAP-05 (D-41 empty tree) | — | empty `capture/` exits 0 with an explicit message | integration | `./scripts/phase18-capture-model-assert.sh` §7 | ✅ exists | ✅ green |
| — | — | — | Phase 17 regression | — | N/A | regression | `./scripts/phase17-unblock-assert.sh` | ✅ exists | ✅ green |
| — | — | — | Phase 13/14 regression after the D-21 fixture repoint | — | N/A | regression | `./scripts/phase13-d19-assert.sh`, `./scripts/phase14-verify.sh` | ✅ exists | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `scripts/gen-collision-map.sh` — the generator; CAP-02, CAP-03. Must sort its `find` output (F-3) or regenerate-and-diff fires spuriously
- [x] `scripts/phase18-capture-model-assert.sh` — seven sections, one per ROADMAP success criterion; covers every phase requirement
- [x] `collision-map.tsv` — generated artifact, committed **before** any file move (D-26)
- [x] `stow/README.md`, `restow/README.md`, `capture/README.md` — CAP-01
- [x] `docs/archive/README.md` — D-27; the directory does not exist yet (`docs/` holds only `dots-hyprland-workflow.md` and `phase14-adopt-runbook.md`)
- [x] Framework install: **none** — the repo's assert-script model is the framework

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| D-15 / D-17 unfold of `~/.config/qBittorrent` | CAP-01 | D-17 explicitly declines to ship a migration script; D-18 requires qBittorrent to not be running; the window between `stow -D` and the re-stow is unsafe to automate | Quit qBittorrent. `stow -D` the package, remove the folded directory symlink, re-stow with `--no-folding`, then confirm `~/.config/qBittorrent` is a real directory whose contents are links into `stow/` |
| D-15 / D-17 unfold of `~/.config/smartmontools` | CAP-01 | Same as above | Same sequence; no running-process precondition |

The assert script checks the **end state** only — both paths are real directories whose contents are links
into `stow/`. That end state is automatable and is exactly what D-17 specifies.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated 2026-09-16
