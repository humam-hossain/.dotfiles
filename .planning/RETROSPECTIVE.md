# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v0.1 — Core Framework & Basic Bar

**Shipped:** 2026-07-25  
**Phases:** 4 | **Plans:** 31 | **Tasks:** 39  
**Closeout:** override_closeout (FWK-02/IPC-02 + 4 debug sessions acknowledged)

### What Was Built

- Quickshell foundation from wholesale dots-hyprland `ii` tree (PanelLoader, Material theme, service singletons)
- Core bar modules: workspaces, clock, tray, network with D-15/D-19 layout
- System & audio: CPU→RAM→Disk rings, mute/mic icon+%, volume 130% ceiling
- Stock bar IPC (`open`/`close`/`toggle`) multi-monitor verified
- Same-PID silent soft reload via content-change file-watch
- Explicit deferred backlog for exec-once, keybind, and Waybar cutover

### What Worked

- **Wholesale foundation first** — copying the proven `ii` tree beat hand-rolling architecture
- **Dual-write config** — Config.qml + live `config.json` kept runtime and source aligned
- **Wave 0 assert harnesses** — Python stdlib scripts made phase gates objective and re-runnable
- **Narrow Phase 4 scope** — verifying stock IPC/reload without hyprland.conf edits avoided risky cutover mid-milestone
- **UAT-driven gap plans** — Phase 2/3 gap closures (forceActive pin, indicator strip, resources polish) turned real desktop pain into small plans

### What Was Inefficient

- Long Phase 2 gap cascade (02-06..02-13) after initial productization — layout UX needed more discuss-phase fidelity
- Some Phase 3 color/spacing polish reopened as debug sessions after "complete" (cpu warning color, RAM spacing)
- pavucontrol launch path needed a second pass (launch_first_available.sh + reverts)
- Milestone audit (`/gsd-audit-milestone`) was skipped; closeout used override path

### Patterns Established

- Dual-write: every runtime knob lands in both `Config.qml` and live `config.json`
- Wave 0 first: assert harness red → implement → green before human UAT
- Stock surfaces preferred: assert/UAT existing QML; fix only when verification fails
- Deferred packaging as a first-class plan (04-04) so incomplete requirements do not silently vanish
- Soft reload = file-watch content change (no inventing missing CLI)

### Key Lessons

1. **Discuss layout early with real screenshots** — bar L→R and indicator visibility drove most Phase 2 rework
2. **Productize thresholds/ceilings once, all paths** — volume 130% needed Audio + ScreenCorners + Hyprland XF86 + keyboard wpctl aligned
3. **Defer integration edits deliberately** — packaging FWK-02/IPC-02 kept Phase 4 shippable without half-done session bootstrap
4. **Close debug sessions or promote them** — open debug artifacts block clean milestone close; resolve or acknowledge explicitly

### Cost Observations

- Model mix: adaptive profile (not metered here)
- Timeline: ~5 calendar days (2026-07-20 definition → 2026-07-25 ship)
- Notable: heavy UAT/gap-plan volume in Phase 2; Phase 4 mostly verify/docs

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Phases | Plans | Key Change |
|-----------|--------|-------|------------|
| v0.1 | 4 | 31 | Established wholesale-foundation + dual-write + Wave 0 gates |

### Cumulative Quality

| Milestone | Verification | Known Gaps at Ship | Closeout |
|-----------|--------------|--------------------|----------|
| v0.1 | All 4 phases passed | 2 reqs + 4 debug | override_closeout |

### Top Lessons (Verified Across Milestones)

1. Prefer stock surfaces and narrow verify-only phases when integration risk is high
2. Package deferred work explicitly so incomplete requirements remain visible
