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

## Milestone: v0.7 — Voice Status Bar Component & Audio Telemetry

**Shipped:** 2026-09-21  
**Phases:** 3 | **Plans:** 4 | **Tasks:** 6  
**Closeout:** override_closeout (7 debug sessions acknowledged as deferred: 5 legacy on retired bar surface + 2 v0.7 sessions resolved by gap closure; milestone audit passed with zero gaps and 100% requirements satisfied)

### What Was Built

- Centralized non-blocking Quickshell Singleton service (`Voice.qml`) with 6 `FileView` instances polling `$XDG_RUNTIME_DIR/voice-stt/` tmpfs state files, procfs `/proc/<pid>/cmdline` liveness verification, automated stale PID lock purging, drift-free `Date.now()` wall-clock duration tracking with `/proc/<pid>/stat` start-tick reload recovery, and TTS voice/backend metadata extraction
- Dedicated `VoicePill.qml` status bar pill extending `BarGroup` with `graphic_eq` Material Symbol, direct content-bound `implicitWidth` bypassing Qt 6.11 GridLayout caching, breathing 1.0↔0.5 pulse animation with fail-safe reset, Sequential Linear Flow state engine with 1500ms wrap-up linger, and dynamic `Appearance.colors.*` palette tokens
- Horizontal and vertical bar integration in `BarContent.qml` Right zone and `VerticalBarContent.qml` bottom section with responsive `useShortenedForm` suppression and inert `MouseArea` event isolation
- Hardened duration tracking against clock skew and procfs drift (G-37-6), and full vertical bar support (G-37-2)
- Three automated assertion harnesses covering state observation, liveness, duration, animation, layout, and strict repository verification

### What Worked

- **Tmpfs IPC over custom socket daemon** — leveraging existing `voice.py` CLI's runtime state file writes (`$XDG_RUNTIME_DIR/voice-stt/`) eliminated the need for a custom background IPC socket daemon, reducing complexity and keeping the service fully reactive to filesystem state.
- **Adaptive FileView polling** — switching from 500ms idle to 100ms active polling via a simple conditional expression provided responsive UI updates during speech activity without wasting CPU cycles during idle.
- **Procfs-anchored reload recovery** — recovering `startTime` from `/proc/<pid>/stat` start ticks across Quickshell shell reloads maintained accurate duration display without losing timing context.
- **Gap-closure plans from UAT** — turning the two UAT findings (vertical bar missing, duration timer stuck at 0:00) into a focused 37-02 gap closure plan fixed both issues cleanly without scope creep.
- **Direct content-bound implicitWidth** — bypassing Qt 6.11's GridLayout caching bug by binding `implicitWidth` directly to content width delivered correct BarGroup 250ms emphasized deceleration width resizing.

### What Was Inefficient

- Initial VoicePill icon used `auto_awesome` per the spec but was switched to `graphic_eq` during implementation for better visual fit — the icon decision could have been finalized during discuss-phase.
- Phase 37 `disk_status: executed` persisted as "stale verification" because a STATE.md commit (14:56:45) post-dated the verification timestamp (14:56:00) by 45 seconds, requiring a manual timestamp refresh.
- Legacy debug sessions from the retired v0.1 local bar (4 sessions) continue to flag audits across every milestone — these should be formally resolved or deleted.

### Patterns Established

- Tmpfs IPC for desktop status bar components: speech engine writes state files to `$XDG_RUNTIME_DIR/voice-stt/`, Quickshell `FileView` instances poll them asynchronously.
- Procfs liveness verification: validate `/proc/<pid>/cmdline` tokens before trusting PID state files; purge stale locks via `Quickshell.execDetached`.
- Vertical bar support as first-class: any new status bar pill must be integrated into both `BarContent.qml` and `VerticalBarContent.qml` from the start.
- Sequential Linear Flow for multi-state visual transitions: define strict state precedence hierarchy with explicit linger timers between transitions.
- Direct `implicitWidth` binding on `BarGroup` root for accurate fluid width animation.

### Key Lessons

1. **Finalize visual icon decisions during discuss-phase** — switching from `auto_awesome` to `graphic_eq` mid-implementation was low-cost here but could cause rework in more complex components.
2. **Commit verification after all other file changes** — the 45-second timestamp race between STATE.md and VERIFICATION.md commits caused unnecessary "stale" status; ensure verification is the final commit.
3. **Test vertical bar integration alongside horizontal** — the G-37-2 gap (VoicePill missing in vertical bar) was caught by UAT; adding vertical bar checks to the initial plan avoids gap-closure overhead.
4. **Clamp procfs-derived timestamps defensively** — clock skew between monotonic kernel ticks and wall-clock `Date.now()` can produce negative durations; always `Math.max(0, ...)`.

### Cost Observations

- Model mix: Gemini 3.8 Flash (High) / Claude Opus 4.6 (Thinking)
- Timeline: 1 calendar day (2026-09-21 definition → 2026-09-21 ship)
- Notable: 3 phases, 4 plans completed in a single intensive session with zero desktop session interruptions and all automated test suites passing.

---

## Milestone: v0.8 — Notification Experience & Shell Interaction Polish

**Shipped:** 2026-09-25  
**Phases:** 5 | **Plans:** 9 | **Tasks:** 26  
**Closeout:** verified_closeout (milestone audit passed with 17/17 requirements satisfied, 5/5 phases verified, 11/11 integrations verified, 6/6 flows verified, and all open debug sessions resolved)

### What Was Built

- `power-profiles-daemon` system service integration on Arch Linux, tracked across package manifests (`pkglist-native.txt`, `dots-hyprland.sh`, `bootstrap.sh`), enabling Quickshell's `PowerProfilesToggle.qml` quick-toggle with zero local QML overrides
- Dynamic `MediaControls.qml` positioning anchored directly beneath the top status bar's `Media` pill across active monitors with robust screen boundary clamping (`Math.min` / `Math.max`) via `GlobalStates` coordinate bridge and HoverHandler event isolation
- Notification Center quick-dismiss and smart routing in `restow/quickshell/`: 1-click 'X' close button on single sidebar cards (`NotificationGroup.qml`), smart body click routing to app D-Bus default action and web links, and QV4-safe regex OTP code extraction with 1-click "Copy [Code]" action chip (`NotificationItem.qml`, `NotificationUtils.qml`)
- Restored 10px horizontal breathing room to status bar clock/date pill (`ClockWidget.qml`) matching adjacent pills, and unified the 150% volume ceiling from a single source of truth (`config.json`) consumed by Hyprland keybinds (`custom/keybinds.lua`), Quickshell audio services (`Config.qml`, `Audio.qml`), right sidebar volume slider (`QuickSliders.qml` with 100% stop notch), and bar mouse scroll
- Consolidated test runner and regression harness (`scripts/phase41-interactions-assert.sh`) orchestrating all milestone sub-harnesses (Phases 38, 39, 40, 40.1), verifying non-invasive leaf symlinks under `restow/quickshell/`, and asserting strict zero git churn (`arch/dots-hyprland.sh verify --strict` with `FAIL=0 FINDINGS=0`)

### What Worked

- **Upstream parity first** — investigating upstream `PowerProfilesToggle.qml` showed it natively supports `net.hadess.PowerProfiles` via `Quickshell.Services.UPower`, requiring zero local QML overrides and avoiding unnecessary leaf symlink maintenance.
- **Sentinel value coordinate fallback** — using `-1` as a sentinel for `mediaPillCenterX` cleanly activated upstream center fallback when opened via keyboard shortcut or IPC without pill click.
- **QV4-compatible non-lookbehind regex** — replacing modern regex lookbehinds `(?<!...)` with non-capturing prefix boundaries `(?:^|[^0-9\-\/])` prevented engine-level `SyntaxError` in Qt's QV4 JavaScript runtime.
- **Inserted decimal phase (Phase 40.1)** — adding Phase 40.1 dynamically cleanly decoupled status bar clock padding and volume ceiling ergonomics into focused plans without disturbing the existing roadmap numbering.
- **Single source of truth for configuration** — reading `"volumeCeiling": 1.5` from `config.json` via pure Lua in Hyprland and QML in Quickshell eliminated split-brain volume ceiling discrepancies.
- **Consolidated test orchestration** — having `phase41-interactions-assert.sh` chain sub-harnesses with a porcelain baseline snapshot guaranteed zero working-tree churn across the entire suite.

### What Was Inefficient

- Initial OTP regex used lookbehinds supported in Node.js but unsupported in Qt 6.8 QV4, which wasn't caught until UAT; running regex tests inside Quickshell's engine earlier would have avoided the gap closure plan.
- Initial toast notification cards had height animation stutter from 0 because `Behavior on implicitHeight` was enabled during component instantiation; disabling the animation during initial load resolved the issue.

### Patterns Established

- Two-tier assertion pattern: hard fail on static AST / symlink topology, soft skip on interactive live GUI if running headless or missing runtime prerequisites.
- Non-lookbehind regex for Quickshell QML: always use boundary markers `(?:^|[^...])` and capture groups instead of lookbehinds for QV4 engine compatibility.
- Unified configuration contracts: store shell tuning parameters in `~/.config/illogical-impulse/config.json` and consume via pure Lua in Hyprland and `Config.qml` in Quickshell.
- Initial animation gating: disable property Behaviors until component initialization completes (`root.initialized`) to prevent startup visual lag and mask thrashing.

### Key Lessons

1. **Verify JavaScript engine compatibility early** — Qt's QV4 engine does not support ES2018+ features like regex lookbehinds; test regex logic in `qs` or avoid lookbehinds by default.
2. **Audit open debug sessions before close** — moving resolved debug sessions to `.planning/debug/resolved/` keeps the artifact audit clean and allows a true `verified_closeout`.
3. **Suppress initial load animations** — animating height or opacity during component creation causes perceptible visual stutter; gate animation behaviors on initial layout completion.
4. **Single configuration source of truth prevents drift** — binding both compositor keybinds and shell sliders to the same config file eliminates subtle volume or parameter mismatch bugs.

### Cost Observations

- Model mix: Gemini 3.8 Flash (High)
- Timeline: 4 calendar days (2026-09-22 definition → 2026-09-25 ship)
- Notable: 5 phases, 9 plans, 26 tasks executed with clean test assertion suites and 0 working tree churn.

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
| v0.7 | 3 | 4 | Voice telemetry service + status bar pill with tmpfs IPC, procfs liveness, and dual-bar integration |
| v0.8 | 5 | 9 | Integrated power-profiles-daemon, dynamic media anchoring, notification quick-dismiss & smart routing, unified volume ceiling, and consolidated test harness |

### Cumulative Quality

| Milestone | Verification | Known Gaps at Ship | Closeout |
|-----------|--------------|--------------------|----------|
| v0.1 | All 4 phases passed | 2 reqs + 4 debug | override_closeout |
| v0.2 | All 5 phases passed | no formal audit + 4 debug (retired surface) | override_closeout |
| v0.4 | All 8 phases passed | 4 legacy debug (retired surface) | override_closeout |
| v0.5 | All 6 phases passed (100% Nyquist) | 5 debug (4 retired bar + 1 Phase 25 resolved) | override_closeout |
| v0.6 | All 4 phases passed (audit passed) | 0 gaps (5 legacy debug carried forward) | verified_closeout |
| v0.7 | All 3 phases passed (audit passed) | 0 gaps (7 debug acknowledged: 5 legacy + 2 resolved) | override_closeout |
| v0.8 | All 5 phases passed (audit passed) | 0 gaps (all debug sessions resolved) | verified_closeout |

### Top Lessons (Verified Across Milestones)

1. Prefer stock surfaces and narrow verify-only phases when integration risk is high
2. Package deferred work explicitly so incomplete requirements remain visible
3. Open debug sessions and skipped milestone audits force override_closeout — close or reclassify before ship
4. When product vehicle changes, retire the old path only after the new path is live-verified and documented
5. Verify link identity before file content — symlink-destroying primitives leave file contents matching git while corrupting live-sync architecture
6. Dynamic theme outputs must be decoupled from repository tracking via explicit data contracts (`guard-paths.tsv`)
7. Reorganize layouts using modular zoning and dynamic space defense before live human visual trial-and-error
8. Use restow with leaf symlinks (`--no-folding`) for third-party QML shell modifications to maintain live hot-reload without submodule forks
9. Tmpfs IPC + procfs liveness is a lightweight, daemon-free pattern for desktop service status integration
10. Quickshell QV4 engine requires avoiding regex lookbehinds and gating initial layout animations to prevent visual stutter


