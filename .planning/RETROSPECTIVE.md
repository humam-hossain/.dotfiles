# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v0.2 — Adopt dots-hyprland

**Shipped:** 2026-08-02  
**Phases:** 5 | **Plans:** 15 | **Tasks:** ~38  
**Closeout:** override_closeout (no formal milestone audit; 4 v0.1 debug sessions re-acknowledged as obsolete post product retirement)

### What Was Built

- Personal fork `humam-hossain/dots-hyprland` + `vendor/dots-hyprland` recursive submodule pin with dual remotes
- Thin `arch/dots-hyprland.sh` wrapper (SAFE_DEFAULTS, backup gate, flag passthrough) around upstream `./setup`
- Live ii install at real `~/.config/quickshell` + personal hypr env/`qs -c ii` hooks; Waybar dual-run preserved
- Retired v0.1 in-repo product (933-file tree delete + `arch/quickshell.sh` hard-delete)
- Operator playbook `docs/dots-hyprland-workflow.md` (install/adopt + pin-bump update + non-goals)

### What Worked

- **Foundation-first milestone shape** — pin → wrap → install → retire → document avoided dual-product confusion
- **Safe defaults as policy code** — `--core --skip-hyprland` + hard backup gate prevented accidental hypr conf destruction
- **Live-hold gates before destructive plans** — Phase 8 reinstall health check before tree delete kept session green
- **Per-phase verification + UAT** — all five phases verification-passed; UAT 14/14, 12/12, 9/9 on late phases
- **Single playbook SoT** — thin README link + PROJECT/REQUIREMENTS cross-links beat scattered install notes

### What Was Inefficient

- Formal `/gsd-audit-milestone` skipped again (same as v0.1) — closeout stays override path
- Four open debug sessions from retired local bar still block clean audit-open; should have been closed or marked obsolete at Phase 8
- Phase 6 SUMMARY one-liners incomplete (dates only) — milestone CLI rolled noisy accomplishments until curated
- init.manager disk_status drift on Phase 6 (partial/not_required) despite VERIFICATION passed — tooling signal noise at close

### Patterns Established

- Managed dependency layout: fork + `vendor/` submodule + thin `arch/*.sh` wrapper
- SAFE_DEFAULTS injection only on install/install-files; meta flags stripped before setup getopt
- Destructive retirement only after LIVE-04 hold green; never delete live home tree from repo plans
- Pin-bump primary update; exp-merge/online cache documented as non-primary only
- Phase numbering continues across milestones (v0.2 = phases 5–9; next starts at 10)

### Key Lessons

1. **Retire the old product only after the new path is live-verified** — symlink break → install → hooks → then delete
2. **Wrapper policy beats reimplementation** — upstream `./setup` as SoT prevents package-list bitrot
3. **Close or reclassify debug sessions when the product surface changes** — open artifacts on deleted trees poison milestone audit
4. **Document the operator path in the same milestone as the install path** — tribal knowledge otherwise becomes the real dependency

### Cost Observations

- Model mix: adaptive profile (not metered here)
- Timeline: ~8 calendar days (2026-07-25 definition → 2026-08-02 ship)
- Notable: Phase 7 live install highest wall time; Phase 8 dominated by mass delete; Phase 9 pure docs

---

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
| v0.2 | 5 | 15 | Pivoted to managed upstream dependency; retired local product |

### Cumulative Quality

| Milestone | Verification | Known Gaps at Ship | Closeout |
|-----------|--------------|--------------------|----------|
| v0.1 | All 4 phases passed | 2 reqs + 4 debug | override_closeout |
| v0.2 | All 5 phases passed | no formal audit + 4 debug (retired surface) | override_closeout |

### Top Lessons (Verified Across Milestones)

1. Prefer stock surfaces and narrow verify-only phases when integration risk is high
2. Package deferred work explicitly so incomplete requirements remain visible
3. Open debug sessions and skipped milestone audits force override_closeout — close or reclassify before ship
4. When product vehicle changes, retire the old path only after the new path is live-verified and documented
