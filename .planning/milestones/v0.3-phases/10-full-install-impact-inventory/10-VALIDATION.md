---
phase: 10
slug: full-install-impact-inventory
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-08-04
---

# Phase 10 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Source: `10-RESEARCH.md` § Validation Architecture + CONTEXT D-01..D-17.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Shell assert script (bash; no Jest/pytest app suite) |
| **Config file** | none — Wave 0 adds `scripts/phase10-inventory-assert.sh` |
| **Quick run command** | `./scripts/phase10-inventory-assert.sh` |
| **Full suite command** | `./scripts/phase10-inventory-assert.sh --full` (structural + optional read-only host re-scan consistency notes) |
| **Estimated runtime** | ~2–5 seconds |

---

## Sampling Rate

- **After every task commit:** Run `./scripts/phase10-inventory-assert.sh`
- **After every plan wave:** Run `./scripts/phase10-inventory-assert.sh --full`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------------|-----------------|-----------|-------------------|-------------|--------|
| 10-01-01 | 01 | 1 | Nyquist W0 | T-10-01 | Read-only assert only; no setup install | docs/structure | `test -x scripts/phase10-inventory-assert.sh && bash -n scripts/phase10-inventory-assert.sh` | ✅ | ✅ green |
| 10-01-02 | 01 | 1 | INV-04 | T-10-01 | No live mutation while writing residual | docs/structure | `./scripts/phase10-inventory-assert.sh` (INV-04 section gates) | ✅ | ✅ green |
| 10-02-01 | 02 | 2 | INV-02 | T-10-01 | Cite static sources only for hypr effects | docs/structure | `./scripts/phase10-inventory-assert.sh` (hypr axis gates) | ✅ | ✅ green |
| 10-03-01 | 03 | 2 | INV-03 | T-10-01 | Full misc catalog; no chrome rows | docs/structure | `./scripts/phase10-inventory-assert.sh` (misc axis gates) | ✅ | ✅ green |
| 10-04-01 | 04 | 2 | INV-01 | T-10-01 | Package/sysupdate effects documented, not executed | docs/structure | `./scripts/phase10-inventory-assert.sh` (sysupdate axis gates) | ✅ | ✅ green |
| 10-05-01 | 05 | 3 | D-03/D-07/D-12/D-15 | T-10-01/T-10-02 | Host scan read-only; no dispositions | docs/lint | `./scripts/phase10-inventory-assert.sh --full` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `scripts/phase10-inventory-assert.sh` — structural + lint gates for `10-INVENTORY.md` (INV-01..04, D-10 columns, D-12 dispositions, D-15 chrome ban)
- [x] Optional read-only host presence printer invoked by `--full` (PRESENT/ABSENT only; never writes under `~/.config`)
- [x] Framework install: none (bash + `rg`/`grep`/`test`)

---

## Requirement → Automated Gate Map

| Req ID | Behavior | Automated check (assert script) |
|--------|----------|----------------------------------|
| INV-04 | SAFE_DEFAULTS residual section | Heading + literals `--core`, `--skip-hyprland`, `--skip-sysupdate`, `SAFE_DEFAULTS`, claim that safe install remains default/available |
| INV-02 | Hypr axis effects | Rows/mentions: `hyprland.conf.old` (or conf→`.old`), `hyprland.lua`, `auto_backup` or firstrun/`.new`, `ignore_existing` or `hypr/custom`, `hyprpaper` |
| INV-03 | Full misc + named set | `fish`, `kitty`, `starship`, `fontconfig`, plus at least `fuzzel`, `matugen`, `wlogout`, `mpv` (full-catalog signal) |
| INV-01 | Sysupdate/packages | `pacman -Syu` or Syu wording, `illogical-impulse` meta, `asdeps` or `skip-sysupdate` |
| D-10 | Table columns | Header line containing `Path`, `Effect`, `Risk`, `Source`, `Host present` |
| D-12 | Neutral inventory | Fail if disposition verbs as recommendations (`recommend keep/migrate/accept`, `disposition:`) outside Phase-11 deferral notes |
| D-15 | No dual-run chrome | Fail if `waybar`, `rofi`, or `swaync` appear as inventory clash rows (case-insensitive table hits) |
| D-01 | Artifact path | File exists at `.planning/phases/10-full-install-impact-inventory/10-INVENTORY.md` |
| D-05 | Read-only process | Plan bans live setup; assert script itself must not call setup without `--dry-run` and must not rsync/cp/mv/rm into XDG |

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Host presence columns match machine at write time | D-03, D-06 | Live XDG drifts; assert can re-print presence but human confirms table honesty | Re-run assert `--full` host section; spot-check 5 PRESENT and 5 ABSENT rows against `ls ~/.config` |
| Every row Source is re-openable | D-07 | File:line cites need human open | Spot-check 3 hypr + 3 misc + 2 package Sources open in editor |
| Optional SAFE_DEFAULTS dry-run argv | INV-04 | Optional per D-08 | `printf 'yes\n' \| ./arch/dots-hyprland.sh install --dry-run` shows `--core --skip-hyprland --skip-sysupdate` |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 5s
- [x] `nyquist_compliant: true` set in frontmatter after Wave 0 lands

**Approval:** Phase 10 complete — assert `--full` green; INV-01..04 inventory finalized 2026-08-04
