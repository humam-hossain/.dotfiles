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

## Milestone: v0.4 — Personal config layer

**Shipped:** 2026-09-16  
**Phases:** 8 | **Plans:** 41 | **Tasks:** 91  
**Closeout:** override_closeout (4 v0.1 debug sessions on retired local bar re-acknowledged as deferred; milestone audit passed with zero gaps)

### What Was Built

- Universal stow flag correction (`--verbose=5 --no-folding`) across all install scripts and `safe_rm_path` repo containment clause
- Three-tree capture model (`stow/`, `restow/`, `capture/`), machine-checked `collision-map.tsv`, and wrapper `verify`/`capture` subcommands
- Link-aware `verify` suite checking symlink identity before content, with strict exit codes (0/1/2) proven adversarially against `rsync -a --delete`
- Personal `hypr/custom` Lua overlays (6 files), personal keybindings (`hl.unbind`), and startup autostart restoration (`graphical-session.target`)
- Quickshell ii bar `config.json` copy-capture surviving `switchwall.sh`, with unattended 15-minute systemd user timer
- Dolphin, KDE, and GTK per-file capture with unfolded parent directories, `guard-paths.tsv` data contract, and cp-through live recovery
- One-command idempotent bootstrap (`./bootstrap.sh`) with resumable JSON state, relogin boundary guidance, and deterministic package snapshots
- Complete technical debt reconciliation with 100% Nyquist validation across all 8 phases

### What Worked

- **Adversarial verification before bulk capture** — building link-aware `verify` (Phase 19) before mass stowing made filesystem drift immediately detectable and falsifiable.
- **Three-tree taxonomy by installer collision primitive** — separating clean stow from colliding restow and atomic-copy capture prevented silent overwrite bugs.
- **Machine-asserted data contracts** — `collision-map.tsv` and `guard-paths.tsv` generated and asserted mechanically eliminated manual guesswork and theme churn.
- **Resumable bootstrap state machine** — `./bootstrap.sh` with persistent step state allowed non-destructive testing and clean boundary handling across the relogin hop.
- **Strict exit code binding** — binding the bootstrap orchestrator's exit status directly to `verify --strict` guaranteed that a successful bootstrap leaves zero drift.

### What Was Inefficient

- Summary frontmatter metadata discrepancies (omitted `requirements_completed`) required a dedicated Phase 24 cleanup.
- Four legacy debug sessions from the retired v0.1 local bar still linger in `.planning/debug/`, triggering override closeouts across milestones.
- Stale verification flags in tooling triggered by metadata backfills required re-verifying and documenting test timestamps.

### Patterns Established

- Capture tree routing: clean files in `stow/`, colliding files in `restow/`, atomically overwritten files in `capture/`.
- Universal stow invocation: `stow --verbose=5 --no-folding` across all scripts.
- Link-first verification: always assert source inode == target inode before inspecting file content.
- Guard list exclusion: theme generation outputs must be guarded at the boundary, never captured in version control.
- Deterministic bootstrap: submodule init → setup → stow → capture seed → verify, with idempotent re-execution.

### Key Lessons

1. **Verify link identity, not just content** — tools like `rsync -a --delete` or cp-through overwrites can destroy symlink architecture while leaving contents identical to git.
2. **Never stow files rewritten by rename(2)** — applications that rename temporary files over target paths destroy symlinks; use periodic copy-capture instead.
3. **Decouple generated theme outputs from static configs** — capturing dynamic theme files results in git churn on every wallpaper change; guard them explicitly.
4. **Clean up legacy artifacts early** — debug artifacts from retired subsystems will continue to flag audits unless officially resolved or deleted.

### Cost Observations

- Model mix: adaptive profile
- Timeline: 5 calendar days (2026-09-12 definition → 2026-09-16 ship)
- Notable: 41 plans across 8 phases executed smoothly with zero production desktop outages.

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Phases | Plans | Key Change |
|-----------|--------|-------|------------|
| v0.1 | 4 | 31 | Established wholesale-foundation + dual-write + Wave 0 gates |
| v0.2 | 5 | 15 | Pivoted to managed upstream dependency; retired local product |
| v0.4 | 8 | 41 | Shipped three-tree capture model, link-aware verify, and one-command bootstrap |

### Cumulative Quality

| Milestone | Verification | Known Gaps at Ship | Closeout |
|-----------|--------------|--------------------|----------|
| v0.1 | All 4 phases passed | 2 reqs + 4 debug | override_closeout |
| v0.2 | All 5 phases passed | no formal audit + 4 debug (retired surface) | override_closeout |
| v0.4 | All 8 phases passed | 4 legacy debug (retired surface) | override_closeout |

### Top Lessons (Verified Across Milestones)

1. Prefer stock surfaces and narrow verify-only phases when integration risk is high
2. Package deferred work explicitly so incomplete requirements remain visible
3. Open debug sessions and skipped milestone audits force override_closeout — close or reclassify before ship
4. When product vehicle changes, retire the old path only after the new path is live-verified and documented
5. Verify link identity before file content — symlink-destroying primitives leave file contents matching git while corrupting live-sync architecture
