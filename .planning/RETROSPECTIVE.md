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

## Milestone: v0.5 — System-wide Material You theming

**Shipped:** 2026-09-18  
**Phases:** 6 | **Plans:** 17 | **Tasks:** 32  
**Closeout:** override_closeout (5 debug sessions acknowledged as deferred; milestone audit passed with zero gaps and 100% Nyquist compliance)

### What Was Built

- Retired legacy root-pointing Catppuccin symlinks in `~/.config/gtk-4.0/`, aligned GTK 3 & 4 `settings.ini` to `adw-gtk3-dark`, and configured dynamic Matugen CSS generation with GTK 4 `:disabled` syntax
- Integrated Qt 6 Darkly style engine, harmonized KDE apps (Dolphin, Kate, Gwenview) and FileChooser portal, and wired `kde-material-you-colors` dynamic updates to `kdeglobals` with dark luminance invariant (<0.25)
- Bound Hyprland active, inactive, and group window borders to Matugen `colors.lua`, coordinated Quickshell ii widget tokens and appearance with `colors.json`, and established live coordinated wallpaper reload via `switchwall.sh`
- Styled Fuzzel launcher with dynamic M3 palette tokens via Matugen template, and Kitty terminal emulator dynamic theming via included `kitty-theme.conf` with SIGUSR1 live signaling and 0.90 background opacity
- Relocated `fuzzel` and `kitty` to `restow/` honoring collision map derivation, reconciled `guard-paths.tsv` documenting all 8 dynamic theme outputs with 1:1 `.gitignore` parity, and hardened `./bootstrap.sh` with sensitive directory pre-creation and fail-soft fallback theming
- Resolved all audit technical debt items, brought all 6 milestone phases to 100% Nyquist compliance, added Kitty opacity and virtualenv fallback assertions, and passed full multi-phase regression sweep with zero git drift

### What Worked

- **Strict guard-paths data contract** — tracking all 8 dynamic theme outputs in `guard-paths.tsv` with 1:1 `.gitignore` parity completely prevented working tree drift across automated wallpaper switches.
- **Hierarchical ancestor matching** — enhancing the verifier with recursive ancestor directory checking correctly protected nested dynamic artifacts (e.g. inside `Kvantum/` and `kde-material-you-colors/`).
- **Dedicated assert harnesses per phase** — authoring 5-section standalone test suites with porcelain git checks before and after mutation gave rock-solid guarantees against packaging regressions.
- **Fail-soft bootstrap fallback** — implementing the `#3f51b5` color seed fallback allowed cold system bootstrap to succeed even in headless/offline environments or before wallpaper selection.
- **Asynchronous kdeglobals polling** — polling with timeout in live reload drills handled the background worker without race conditions or false failures.

### What Was Inefficient

- GTK 4 Matugen template initially emitted deprecated `:insensitive` pseudo-class, producing benign console parser warnings until remediated with `:disabled` in Phase 25 Plan 4.
- Cross-toolkit launch confusion during Phase 25 UAT (user opened Dolphin/pavucontrol-qt, which are Qt apps scoped to Phase 26) generated a temporary debug session.
- Stale validation frontmatter in Phase 29 required a dedicated Phase 30 cleanup wave to reach formal 100% Nyquist sign-off.

### Patterns Established

- Theme generation contract: all dynamic wallpaper-derived files must be listed in `guard-paths.tsv` and ignored in `.gitignore`.
- Three-tree taxonomy fidelity: packages where the upstream installer replaces directory symlinks belong in `restow/`, not `stow/`.
- Pre-creation of sensitive parent directories before `stow` prevents GNU Stow from folding directories into monolithic symlinks.
- Signal-based live reloading: `switchwall.sh` uses `SIGUSR1` for Kitty terminal updates and inotify watches for Hyprland/Quickshell without restarting the desktop session.

### Key Lessons

1. **Clarify toolkit ownership early in UAT** — testing GTK theming requires launching native GTK apps (Nautilus/pavucontrol), not Qt apps (Dolphin/pavucontrol-qt) that use a different style engine.
2. **Always validate template syntax against strict toolkit parsers** — GTK 4 CssProvider rejects GTK 3 pseudo-classes with warnings; test with target library parsers directly.
3. **Guard paths must support hierarchical matching** — directory-level guards in `guard-paths.tsv` must protect arbitrary nested child files generated by dynamic theme scripts.
4. **Sign off validation artifacts continuously** — closing VALIDATION.md files during phase execution prevents milestone audits from being blocked by bookkeeping debt.

### Cost Observations

- Model mix: adaptive profile
- Timeline: 3 calendar days (2026-09-16 definition → 2026-09-18 ship)
- Notable: 17 plans across 6 phases executed with zero session restarts or broken symlinks.

---

## Milestone: v0.6 — Top Status Bar Layout, Pill Styling & Component Customization

**Shipped:** 2026-09-20  
**Phases:** 4 | **Plans:** 12 | **Tasks:** 37  
**Closeout:** verified_closeout (formal milestone audit passed: 20/20 requirements satisfied, 4/4 phases verified, 13/13 integrations verified, 5/5 flows verified, 0 critical blockers, 0 tech debt)

### What Was Built

- Established personal Quickshell overlay infrastructure in `restow/quickshell/` deployed via GNU Stow leaf symlinks (`--no-folding`) without touching upstream `vendor/dots-hyprland`, hot-reloading on save.
- Modern rounded-rectangle pill geometry (12–16px corner radius, 4–6px internal padding, configurable margins, borderless backgrounds) with fluid 250ms Material 3 emphasized deceleration width resizing animation in `BarGroup.qml`.
- Systematic Tier 1 and Tier 2 component audit and formatting enhancements: definite GB RAM format (`X.X GB / Y.Y GB`), dynamic swap reveal, two-tier Amber/Red resource alerts, non-glyph clock spacer, balanced 4px tray spacing, unattended system updates (`yay -Syu --noconfirm && yay -Sc --noconfirm`), media title width clamping with ellipsis, and reactive screen recording indicators (`wf-recorder`).
- Modular 3-zone status bar layout in `BarContent.qml` (Left, Center, Right) with clean 4px inter-pill gaps, zero vertical dividers, and Option 1 Dynamic Spacing Defense (200px Media clamp and >= 180px collision buffer).
- Live interactive trial-and-error visual testing with the user across dual monitors (`DP-1` ultrawide and `HDMI-A-1`), locking in dead-center Workspaces flanked symmetrically by Weather on the left and Clock & Date on the right.
- Verified dynamic Material You palette adaptability across wallpaper switches with zero git working tree churn, hardened `./bootstrap.sh` cold machine deployment with directory pre-creation and color priming, and verified repository integrity with `arch/dots-hyprland.sh verify --strict` (0 findings).
- Comprehensive automated Nyquist test suite across four standalone multi-section test harnesses (`phase31-overlay-pill-assert.sh`, `phase32-component-formatting-assert.sh`, `phase33-layout-assert.sh`, `phase34-verification-assert.sh`).

### What Worked

- **Leaf symlink overlays under restow/** — Deploying custom QML files as discrete leaf symlinks (`stow --verbose=5 --no-folding`) inside `~/.config/quickshell/ii/` allowed live hot-reload on file save without touching vendored submodule files or breaking `git status`.
- **Zoned modularity with Option 1 Dynamic Spacing Defense** — Decoupling `BarContent.qml` into Left, Center, and Right zones while capping Media to 200px prevented component collision on narrower displays while allowing fluid expansion on ultrawide.
- **Dead-center mathematical anchoring** — Anchoring Workspaces strictly to `parent.horizontalCenter` (50% monitor width) and flanking it with Weather and Clock & Date gave the bar immediate visual symmetry and balance.
- **Continuous gap-closure plans** — Turning live UAT findings (mic duplicate, updates launcher, media truncation, screen recording telemetry) into tight gap-closure plans (32-03, 32-04, 32-05) closed all issues before milestone completion.
- **Fail-closed assertion harnesses** — Testing every plan with two-phase git porcelain invariance and explicit assertion sections guaranteed that zero working tree drift or broken symlinks escaped detection.

### What Was Inefficient

- Initial gap in Plan 32-03 disabled the wrong microphone control (disabled center toggle instead of tray mute indicator), requiring a second gap-closure plan (32-04) after user clarification.
- Screen recording via `wf-recorder` bypassed PipeWire VideoSource links, meaning Quickshell's upstream `Privacy.qml` failed to detect active recordings until process polling was introduced in 32-05.
- Milestone audit YAML parser tripped on unquoted strings in summary frontmatter, requiring a pre-audit syntax normalization commit.

### Patterns Established

- Quickshell overlay architecture: personal overrides ride in `restow/quickshell/` mapped directly to `~/.config/quickshell/ii/modules/ii/bar/` as leaf symlinks.
- Fluid pill animation: `Behavior on implicitWidth { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }` inside `BarGroup.qml` provides smooth width transitions across expanding/collapsing contents.
- Dynamic Space Defense: long text fields in status bar pills must clamp maximum width and set `elide: Text.ElideRight` to prevent displacing center-anchored modules.
- Non-PipeWire process telemetry: external CLI tools (like `wf-recorder`) should be monitored via lightweight periodic polling (`pgrep -x`) in background singletons to feed UI alert indicators.
- Verified milestone closeout: closing all debug sessions and achieving 100% audit pass enables formal `verified_closeout` without override debt.

### Key Lessons

1. **Verify user intent with visual options before removing controls** — when users report "redundant icons", pinpoint the exact visual component (e.g. system tray mute indicator vs center utility toggle).
2. **Process-level tools need process-level monitoring** — Wayland tools interacting via compositor protocols (like `wlr-screencopy`) do not appear on PipeWire graphs; combine PipeWire node watches with process status polling.
3. **Dead-center anchoring requires explicit width guards** — centering elements by anchoring to `parent.horizontalCenter` requires flanking components and side modules to have bounded widths so they never overlap.
4. **Clean up debug sessions continuously** — resolving and moving debug sessions to `resolved/` as plans complete keeps `audit-open` clean and allows a true `verified_closeout`.

### Cost Observations

- Model mix: Gemini 3.8 Flash (High) / Claude Code
- Timeline: 1 calendar day (2026-09-20 definition → 2026-09-20 ship)
- Notable: 4 phases, 12 plans, and 37 tasks completed in a single intensive session with zero desktop session interruptions and 100% automated test pass.

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Phases | Plans | Key Change |
|-----------|--------|-------|------------|
| v0.1 | 4 | 31 | Established wholesale-foundation + dual-write + Wave 0 gates |
| v0.2 | 5 | 15 | Pivoted to managed upstream dependency; retired local product |
| v0.4 | 8 | 41 | Shipped three-tree capture model, link-aware verify, and one-command bootstrap |
| v0.5 | 6 | 17 | Unified Material You theming across GTK/Qt/Hyprland/Kitty/Fuzzel with zero git churn |
| v0.6 | 4 | 12 | Shipped modular 3-zone status bar with rounded pill geometry and verified closeout |

### Cumulative Quality

| Milestone | Verification | Known Gaps at Ship | Closeout |
|-----------|--------------|--------------------|----------|
| v0.1 | All 4 phases passed | 2 reqs + 4 debug | override_closeout |
| v0.2 | All 5 phases passed | no formal audit + 4 debug (retired surface) | override_closeout |
| v0.4 | All 8 phases passed | 4 legacy debug (retired surface) | override_closeout |
| v0.5 | All 6 phases passed (100% Nyquist) | 5 debug (4 retired bar + 1 Phase 25 resolved) | override_closeout |
| v0.6 | All 4 phases passed (audit passed) | 0 gaps (5 legacy debug carried forward) | verified_closeout |

### Top Lessons (Verified Across Milestones)

1. Prefer stock surfaces and narrow verify-only phases when integration risk is high
2. Package deferred work explicitly so incomplete requirements remain visible
3. Open debug sessions and skipped milestone audits force override_closeout — close or reclassify before ship
4. When product vehicle changes, retire the old path only after the new path is live-verified and documented
5. Verify link identity before file content — symlink-destroying primitives leave file contents matching git while corrupting live-sync architecture
6. Dynamic theme outputs must be decoupled from repository tracking via explicit data contracts (`guard-paths.tsv`)
7. Reorganize layouts using modular zoning and dynamic space defense before live human visual trial-and-error
8. Use restow with leaf symlinks (`--no-folding`) for third-party QML shell modifications to maintain live hot-reload without submodule forks

