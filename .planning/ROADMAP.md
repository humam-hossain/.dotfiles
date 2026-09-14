# Roadmap: Quickshell Desktop Shell

## Milestones

- ✅ **v0.1 Core Framework & Basic Bar** — Phases 1–4 (shipped 2026-07-25)
- ✅ **v0.2 Adopt dots-hyprland** — Phases 5–9 (shipped 2026-08-02)
- ✅ **v0.3 Full ii install** — Phases 10–16 (shipped 2026-09-09)
- 🚧 **v0.4 Personal config layer** — Phases 17–23 (in progress, started 2026-09-12)

## Phases

<details>
<summary>✅ v0.1 Core Framework & Basic Bar (Phases 1-4) — SHIPPED 2026-07-25</summary>

- [x] Phase 1: Shell Foundation & Theme (4/4 plans) — completed 2026-07-21
- [x] Phase 2: Core Bar Modules (13/13 plans) — completed 2026-07-23
- [x] Phase 3: System & Audio Modules (10/10 plans) — completed 2026-07-24
- [x] Phase 4: IPC, Keybinds & Integration (4/4 plans) — completed 2026-07-25

Full phase details: [milestones/v0.1-ROADMAP.md](milestones/v0.1-ROADMAP.md)  
Requirements archive: [milestones/v0.1-REQUIREMENTS.md](milestones/v0.1-REQUIREMENTS.md)  
Phase artifacts: [milestones/v0.1-phases/](milestones/v0.1-phases/)

</details>

<details>
<summary>✅ v0.2 Adopt dots-hyprland (Phases 5-9) — SHIPPED 2026-08-02</summary>

- [x] Phase 5: Fork & Submodule Pin (3/3 plans) — completed 2026-07-25
- [x] Phase 6: Thin Setup Wrapper & Safe Defaults (3/3 plans) — completed 2026-07-26
- [x] Phase 7: Install, Session Hooks & Dual-Run Verify (3/3 plans) — completed 2026-07-27
- [x] Phase 8: Retire Local Quickshell Product (3/3 plans) — completed 2026-07-28
- [x] Phase 9: Workflow Documentation & Update Contract (3/3 plans) — completed 2026-08-01

Full phase details: [milestones/v0.2-ROADMAP.md](milestones/v0.2-ROADMAP.md)  
Requirements archive: [milestones/v0.2-REQUIREMENTS.md](milestones/v0.2-REQUIREMENTS.md)  
Phase artifacts: [milestones/v0.2-phases/](milestones/v0.2-phases/)

</details>

<details>
<summary>✅ v0.3 Full ii install (Phases 10-16) — SHIPPED 2026-09-09</summary>

- [x] Phase 10: Full-install impact inventory (5/5 plans) — completed 2026-08-07
- [x] Phase 11: Disposition decisions (4/4 plans) — completed 2026-08-10
- [x] Phase 12: Wrapper full-profile (4/4 plans) — completed 2026-08-18
- [x] Phase 13: Personal hypr/custom overlays (2/2 plans) — completed 2026-08-31
- [x] Phase 14: Live full adopt & verify (2/2 plans) — completed 2026-09-05
- [x] Phase 15: Playbook safe vs full (6/6 plans) — completed 2026-09-06
- [x] Phase 16: Retire the safe profile (10/10 plans) — completed 2026-09-08

Full phase details: [milestones/v0.3-ROADMAP.md](milestones/v0.3-ROADMAP.md)  
Requirements archive: [milestones/v0.3-REQUIREMENTS.md](milestones/v0.3-REQUIREMENTS.md)  
Phase artifacts: [milestones/v0.3-phases/](milestones/v0.3-phases/)

</details>

### 🚧 v0.4 Personal config layer (Phases 17-23) — IN PROGRESS

**Phase numbering:** Continues after v0.3 (last phase **16**). v0.4 starts at **Phase 17**.

**Ordering principle:** This is a single-operator repo on a daily-driver machine — the live desktop session *is* the production system. De-risk before bulk capture; `verify` exists before the first file is stowed; no phase may end with the session in a broken state.

- [x] **Phase 17: Unblock stow and restore the session target** — Fix the live stow/install defects, stop the repo's own scripts from being able to destroy it, ship D-38 (completed 2026-09-13)
- [x] **Phase 18: Capture model — three trees and the collision map** — A file's location determines its mechanism, and the installer map is checked-in, machine-asserted data (completed 2026-09-14)
- [x] **Phase 19: Link-aware `verify`** — A destroyed symlink becomes a loud failure instead of a clean `git status`, proven adversarially (completed 2026-09-14)
- [ ] **Phase 20: hypr/custom overlays and startup restore** — Six `*.lua` files stow-managed; personal keybinds, launcher variables, and the `exec-once` entries lost at adopt
- [ ] **Phase 21: ii bar config capture** — `config.json` through the `capture/` path plus the unattended timer
- [ ] **Phase 22: KDE and GTK capture** — Per-file `stow/kde` and `stow/gtk`, cp-through `restow/`, generated theme output guarded out
- [ ] **Phase 23: One-command bootstrap** — Clone, one command, and `verify --strict` as the exit code

## Phase Details — v0.4 Personal config layer

### Phase 17: Unblock stow and restore the session target

**Goal:** The repo's own install scripts run instead of failing, cannot revert or delete what the milestone captures, and the live session has `graphical-session.target` back
**Depends on:** Nothing (first v0.4 phase; v0.3 complete)
**Requirements:** FIX-01, FIX-02, FIX-04, FIX-06, CAP-04, START-02, START-03
**Research:** **None.** Every defect is located to a line, every mechanism is confirmed, and D-38's fix is one `systemctl --user start` line in the one directory the installer provably never touches (`install_dir__ignore_existing` is a whole-directory no-op).
**Success Criteria** (what must be TRUE):

  1. No `stow` call site in `arch/` carries `-v=5`; all 15 sites across 14 files carry both `--verbose=5` and `--no-folding`, and `bash -n` passes on every one of those files (FIX-01, CAP-04)
  2. `arch/hyprland.sh` contains no `cp -rf .config/hypr/*` and no cwd-relative path; running it end-to-end exits 0 and leaves `hyprctl -j status` still reporting `configProvider: lua` (FIX-02)
  3. `safe_rm_path` returns non-zero for any path under the repo root — asserted by a fixture case in the phase's assert script, alongside the existing `$HOME/*` and `*/.config/hypr*` cases (FIX-04)
  4. `.gitattributes` exists with `* text=auto eol=lf`; `.gitignore` carries the generated and machine-state patterns; a secret scan over the capture trees reports zero findings and is re-runnable (FIX-06)
  5. `systemctl --user is-active graphical-session.target` returns `active` after a fresh login, started from `custom/execs.lua` — and the repo copy of `execs.lua` is byte-identical to the live one (START-02)
  6. The `systemctl --user disable` footgun — it deletes the stow symlink for a unit in state `linked` — is written down in the operator docs with its recovery command (START-03)

**Verification risk:** Criterion 5 needs one operator re-login; an agent cannot end the session. Criterion 2 runs a real install script against the live session — run it after criterion 1 lands, never before.
**Known hand-sync window:** START-02 edits `custom/execs.lua` in *both* the repo and the live tree, because `stow/hypr/` does not exist yet. That duplication is closed by FIX-03 (Phase 18) and HYPR-01 (Phase 20); until then the two copies must be diffed by hand.
**Plans:** 7/7 plans complete

Plans:
**Wave 1**

- [x] 17-01-PLAN.md — tracer: assert harness (D-20) plus the FIX-01/CAP-04 flag sweep across 15 `arch/` sites and the 16th in `docs/`

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 17-02-PLAN.md — `safe_rm_path` repo-containment clause and the source-safe dispatch guard, with the sibling drift baseline re-pinned

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 17-03-PLAN.md — blocking `.env` triage gate, then `.gitattributes` and tree-qualified `.gitignore` patterns proven by `git check-ignore`

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 17-04-PLAN.md — gitleaks installed from Arch `extra`, history and working-tree scans, per-finding triage

**Wave 5** *(blocked on Wave 4 completion)*

- [x] 17-05-PLAN.md — `graphical-session.target` restored from `custom/execs.lua`, the `disable` footgun documented, Phase 18 handoff rows

**Wave 6** *(blocked on Wave 5 completion)*

- [x] 17-06-PLAN.md — `arch/hyprland.sh` pre-adopt restore deleted and attributed to Phase 20, static half of criterion 2 asserted

**Wave 7** *(blocked on Wave 6 completion)*

- [x] 17-07-PLAN.md — terminal, operator-gated: the one-way live run of `arch/hyprland.sh` under a transcript

### Phase 18: Capture model — three trees and the collision map

**Goal:** Where a file sits in the repo tells you — unambiguously, and checkably by a script — how it is captured and how it is recovered
**Depends on:** Phase 17 (`--no-folding` must be universal before any tree is stowed)
**Requirements:** CAP-01, CAP-02, CAP-03, CAP-05, CAP-07, CAP-08, FIX-03, FIX-05
**Research:** **Light.** Two open questions, both cheap: Q5 — does `install_dir__ignore_existing` really skip a *folded* `custom/` end-to-end (`[ -d symlink-to-dir ]` is true in isolation, but the end-to-end path is unproven); Q15 — `sdata/subcmd-install/3.files-exp.sh` is entirely unread and reachable via `--exp-files`, which the wrapper forwards verbatim. If an operator can pass it, every row of the collision map is void. Read it or make the wrapper refuse the flag.
**Success Criteria** (what must be TRUE):

  1. `stow/`, `restow/` and `capture/` each exist with a README stating its contract *and* its recovery command, and every `restow/` package is tagged `rsync-replace` or `cp-through` (CAP-01)
  2. A machine-readable collision map (`path → installer primitive → symlink outcome → repo outcome`) is checked in, covers every destination in `3.files-legacy.sh`, and records the submodule SHA it was derived from (CAP-02)
  3. An assert script exits non-zero when a path's tree placement contradicts the map — demonstrated by a deliberately mis-filed fixture, and by a simulated pin bump that moves a row (CAP-03)
  4. `arch/dots-hyprland.sh` rejects `--exp-files` with a non-zero exit and a message naming the collision map as the reason, rather than forwarding it to `./setup` (CAP-08)
  5. `--adopt` appears in no script under `arch/` or `scripts/`, and the ban is documented with its interactive-only, clean-tree, one-path-at-a-time exception (CAP-07)
  6. Repo-root `.config/` no longer exists; every file it held is accounted for in a redistribution table — moved to `stow/`, `restow/`, `docs/archive/`, or deleted as generated — and no script reads that path (FIX-03)
  7. `verify` and `capture` are registered in `ALLOWLIST` and dispatched by `main` as their own handlers rather than through `run_install_family`; `verify` runs to a real exit code with `vendor/dots-hyprland` de-initialised; `capture` copies live→repo for a `capture/` fixture, leaves `git diff --cached` empty, and refuses any path whose repo mirror is already dirty against `HEAD` (FIX-05, CAP-05)

**Note:** `capture/` is legitimately empty at the end of this phase — the mechanism ships here, its first real inhabitant arrives in Phase 21. Criterion 7 is therefore proven against a fixture, not a live config.
**Plans:** 11/11 plans complete

Plans:

**Wave 1**

- [x] 18-01-PLAN.md — tracer: the collision map generator, the committed map, and the assert spine that makes it unable to rot

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 18-02-PLAN.md — the three trees, their contracts and recovery commands, `docs/archive/`, and the `--adopt` ban with its exception

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 18-03-PLAN.md — refuse `--exp-files` before dispatch, prove it fires, and record the experimental primitives in PITFALLS
- [x] 18-04-PLAN.md — reconcile the redistribution against the map, archive the two retired files, move `dolphinrc` and `kdeglobals` into `restow/`

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 18-05-PLAN.md — `run_verify` and `run_capture`, the ALLOWLIST entries and the two dispatch arms

**Wave 5** *(blocked on Wave 4 completion)*

- [x] 18-06-PLAN.md — the hypr split across `stow/` and `restow/`, and repo-root `.config/` removed (repo-side only)

**Wave 6** *(blocked on Wave 5 completion)*

- [x] 18-07-PLAN.md — the `capture` fixture suite: the copy, the four refusals, the dry run and the empty tree
- [x] 18-08-PLAN.md — the starship split, three new stow call sites, and the one authorised constant (repo-side only)

**Wave 7** *(blocked on Wave 6 completion)*

- [x] 18-09-PLAN.md — retarget the live readers, repoint the two closed-phase fixtures, and assert the removal with a scoped reader scan

**Wave 8** *(blocked on Wave 7 completion)*

- [x] 18-10-PLAN.md — the generated `restow/` tag table, the mis-filed fixture, and the one-verdict summary

**Wave 9** *(blocked on Wave 8 completion)*

- [x] 18-11-PLAN.md — every live-side operation: link the five migrated packages from the main worktree root, unfold the last two folded directories, then `verify` and the eight-script phase gate

**Note on plan shape:** plans 18-04, 18-06 and 18-08 are deliberately repo-side only. Each has more than two tasks and no decision checkpoint, so each dispatches to a subagent that under the default worktree isolation runs in a per-agent worktree removed at wave teardown — a GNU Stow run from inside one creates live symlinks resolving into a directory that is about to be deleted. Every stow invocation in this phase is therefore concentrated in 18-11, which resolves the canonical main worktree root and refuses to run from a linked worktree.

### Phase 19: Link-aware `verify`

**Goal:** A destroyed symlink is a loud failure rather than a clean `git status` — the one property that makes the milestone's headline claim falsifiable
**Depends on:** Phase 18 (verify's per-path expectations are read out of the tree taxonomy and the collision map)
**Requirements:** VER-01, VER-02, VER-03, VER-04
**Research:** **Light.** The output contract is already fixed by `scripts/phase14-verify.sh` and must be reused, not reinvented. One open question: Q3 — the `QSaveFile` temp file is created in the *resolved* directory, i.e. inside the repo working tree. Whether it is ever observable in `git status` during a burst of writes decides whether a `.gitignore` rule and a dedicated stray-temp-file check are needed.
**Success Criteria** (what must be TRUE):

  1. For every `stow/` and `restow/` path, `verify` checks — in this order, failing at the first miss and before reading any content — `test -L`, `readlink -f` equals the expected repo path, no ancestor directory is a symlink into the repo, no dangling `-xtype l` (VER-01)
  2. For every `capture/` path, `verify` diffs live against repo and reports drift as its own finding class, distinct from a link failure (VER-02)
  3. `verify` exits 0 clean / 1 drift / 2 precondition failure; `--strict` promotes findings to failures; output matches the `[PASS]`/`[FAIL]`/`[FINDING]`/`[INFO]` + `=== done: FAIL=n FINDINGS=n ===` contract (VER-03)
  4. The adversarial test passes: stow a fixture file, `rsync -a --delete` over it, `verify` exits 1 and names the path — and the identical run without the rsync exits 0. A second case covers the cp-through class (link intact, repo file overwritten through it and now byte-identical to the vendor copy) (VER-04)
  5. `verify` is green on today's tree: a stowed file whose repo content differs from `HEAD` is `[INFO]` (that is capture working), and an unclaimed upstream stub beside a managed file is `[INFO]` until claimed (VER-01/VER-02 boundary)

**Verification risk — destructive by construction.** VER-04 runs `rsync -a --delete` over a stowed path on purpose. It must operate on a scratch package and a scratch target directory, and must refuse to run if its target resolves under `$HOME/.config` or into a tracked repo tree. There is no fallback that proves the same thing — a simulated failure would test the simulator.
**Plans:** 5/5 plans complete

Plans:
**Wave 1**

- [x] 19-01-PLAN.md — Tracer: argv to exit code, proven by a fixture destroyed on purpose (flag surface, preconditions, `--strict`/`--quiet`, the VER-04 rsync-replace harness)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 19-02-PLAN.md — Repo-side pass: folded ancestor directories, links dangling into the repo, the repo-vs-`HEAD` content observation, and the cp-through boundary

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 19-03-PLAN.md — The live-side sweep: bounded root set, per-directory verdicts, the nine-arm entry classifier, and the composite four-pathology fixture

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 19-04-PLAN.md — The `capture/` finding class, the `--strict` promotion, both installer auto-backup branches, and the read-only real-tree check

**Wave 5** *(blocked on Wave 4 completion)*

- [x] 19-05-PLAN.md — Close the record: the Q3 answer in PITFALLS.md, the wrapper drift re-pin, and the phase gate

### Phase 20: hypr/custom overlays and startup restore

**Goal:** Every personal Hyprland override is the same inode in the repo and in the live session, and the startup applications lost at the Phase 14 adopt are running again
**Depends on:** Phase 18 (tree placement), Phase 19 (`verify` must be able to prove the first bulk stow landed)
**Requirements:** HYPR-01, HYPR-02, HYPR-03, START-01, SAFE-01
**Research:** **None.** The override contract is fully source-mapped: `hyprland.lua` requires `custom.{env,execs,general,rules,keybinds}`, and `hyprland/keybinds.lua:3-4` requires `custom.variables` before the 194 upstream binds. `hl.unbind` is confirmed in `/usr/share/hypr/stubs/hl.meta.lua`. One question stays open — Q4, the `hl.exec_cmd` rules-table key spelling for workspace pinning — and it has a documented fallback (`hyprctl dispatch exec '[workspace N silent] …'`), so it does not gate planning.
**Success Criteria** (what must be TRUE):

  1. All six of `~/.config/hypr/custom/{env,execs,general,rules,keybinds,variables}.lua` are symlinks resolving into `stow/hypr/`, no parent directory is itself a symlink, and `verify` exits 0 for the `hypr` package (HYPR-01)
  2. Personal keybinds live in `custom/keybinds.lua`, each replaced upstream bind preceded by `hl.unbind`; `hyprctl binds -j` shows no duplicate for any replaced combination, and the ii cheatsheet groups them under their `"Category: Label"` headings (HYPR-02)
  3. App-launcher and terminal choices are set in `custom/variables.lua` only — a diff of live `hypr/hyprland/` against the pin shows zero changes (HYPR-03)
  4. After a fresh login, the polkit agent, `wl-clip-persist`, the cursor setting and the workspace-pinned applications are all live, enumerated one-for-one against the pre-adopt `exec-once` list (START-01)
  5. The escape route was rehearsed before the bulk stow, not designed after it — a timestamped `cp -a` backup exists, `stow -n --no-folding` ran first, each package is its own commit, and the documented one-line undo has been executed once and the state restored (SAFE-01)

**Verification risk — first bulk stow over live files.** The live `custom/*.lua` files are plain copies today, so `stow` will conflict on every one. Required containment: a timestamped `cp -a` backup of the live paths, `stow -n --no-folding` first, one package, one commit, and a tested one-line undo (`stow -D -t ~ hypr && cp -a <backup>/hypr/. ~/`). Criterion 4 needs an operator re-login. Note that the untracked files in `custom/` are **upstream stubs, not personal drift** — this phase is authoring, not rescuing.
**Plans:** TBD

### Phase 21: ii bar config capture

**Goal:** The bar's settings survive both the settings panel and a wallpaper change, and reach the repo with no manual step
**Depends on:** Phase 18 (`capture` mechanism), Phase 19 (`verify` proves the link state afterwards)
**Requirements:** BAR-01, BAR-02, CAP-06
**Research:** **Light.** No design question remains — the mechanism is chosen by two specified experiments. Q1: symlink a scratch `config.json` under `qs -p` with a distinct `instance.lock`, toggle a property, and confirm `FileView`/`QSaveFile` leaves the link intact. Q2: change the wallpaper and confirm `switchwall.sh:147`'s `jq … > "$F.tmp" && mv` destroys it. Q2 is the result that *justifies* the exception; D-41's stated reason ("atomic writes") is factually wrong and the requirement text should be amended to name the `mv`, not atomicity.
**Success Criteria** (what must be TRUE):

  1. `capture/ii/config.json` exists; `capture` reproduces live→repo for it, validates the JSON before writing, stages nothing, and skips when the repo mirror is dirty (BAR-01)
  2. A `switchwall.sh` wallpaper change is shown to leave `~/.config/illogical-impulse/config.json` a plain file, and the following `capture` run still picks it up — reproduced in a scratch `XDG_CONFIG_HOME` first, then confirmed once against the live session (BAR-01)
  3. `dotfiles-capture.timer` is enabled and active, its unit is stow-managed, its journal shows a successful run, and a hand-edited live `config.json` shows up in `git status` within one interval with nothing staged and nothing committed (CAP-06)
  4. Bar position, style, auto-hide, utility buttons, workspaces and weather are set deliberately, and restoring `capture/ii/config.json` over a defaults-reset live file and restarting `qs -c ii` reproduces every one of them (BAR-02)

**Verification risk — one deliberate live mutation.** Criterion 2's confirming run changes the wallpaper on the production session, which also rewrites generated theme output (`kdeglobals`, `colors.lua`, `hyprlock/colors.conf`). Containment: scratch-XDG reproduction first, clean working tree before the live run so `git checkout` reverts it, and treat the resulting churn as the measurement that settles Q7 for Phase 22. Criterion 4's defaults-reset needs a backup of `config.json` taken first.
**Plans:** TBD

### Phase 22: KDE and GTK capture

**Goal:** Dolphin, KDE and GTK settings are captured per file, with generated theme output provably excluded rather than merely avoided
**Depends on:** Phase 18 (tree placement and cp-through tagging), Phase 19 (`verify` and the GUARD assertion)
**Requirements:** KDE-01, KDE-02, KDE-03
**Research:** **Deep.** This is the only phase with genuinely open design questions, which is why it sits off the critical path. Q7 — is `kde-material-you-colors` installed and firing at all? `which` finds nothing, live `[Colors:*]` blocks are byte-identical to the pin, and `gtk-3.0/gtk.css` is *absent* despite matugen declaring it an output; the whole `kdeglobals` churn hazard may be latent. Q8 — does matugen write *through* or *replace* `~/.config/gtk-4.0/gtk.css`, which is currently a symlink into `/usr/share/themes/catppuccin-mocha-teal-standard+default/`? That conflict must be resolved before anything in that directory is managed. Q10 — do KDE apps write through a symlink under real KConfig cascade and locking, not just `QSaveFile` in isolation? Q11 — file modes: these files are `0600` live, git stores only the exec bit, and KConfig's `setPermissions` follows the link and will chmod the *repo* file. Q6 — which GTK/GNOME apps in this user's set use `g_file_set_contents`, which destroys links.
**Success Criteria** (what must be TRUE):

  1. `kiorc`, `ktrashrc` and `kservicemenurc` are symlinks into `stow/kde/`; a real Dolphin settings change leaves the link intact and updates the repo file; and the mode question is resolved — either bootstrap `chmod 600`s an explicit list, or the phase records that it does not matter and why (KDE-01)
  2. `gtk-3.0/settings.ini`, `gtk-3.0/bookmarks` and `gtk-4.0/settings.ini` are managed **per file** with neither parent directory a symlink; `gtk-3.0/gtk.css` and `gtk-4.0/gtk.css` are gitignored, and `verify` FAILs if either ever appears inside a managed tree (KDE-02)
  3. `dolphinrc` and `chrome-flags.conf` sit in `restow/` tagged cp-through; running `install-files` then `git status` shows them modified through the link, and the documented recovery `git checkout -- restow/<pkg>` restores them — exercised once, not merely written down (KDE-03)
  4. The GUARD list (`kdeglobals`, `Kvantum/`, both `gtk.css`, `fuzzel_theme.ini`, `hypr/hyprland/colors.lua`, `hyprlock/colors.conf`) is checked in as data, and the Q7/Q8 findings are recorded next to it so the exclusions are justified by measurement rather than by assumption (KDE-02)

**Verification risk — live app writes and a possible repo chmod.** Criterion 1 requires driving a real Dolphin against a scratch `kiorc` before `stow/kde/` is committed, and KConfig may chmod the repo file to `0600` on every write. Criterion 3 requires running the installer against the live session; run it with a clean working tree so the cp-through damage is the *evidence* and `git checkout` is the undo.
**Plans:** TBD

### Phase 23: One-command bootstrap

**Goal:** A clone plus one command reproduces this desktop, and the command says so by passing `verify` rather than by claiming it
**Depends on:** Phases 17-22 (bootstrap orchestrates every mechanism they build; `verify` must exist for "reproduces the exact setup" to mean anything)
**Requirements:** BOOT-01, BOOT-02, BOOT-03, BOOT-04, BOOT-05
**Research:** **Deep.** Nothing like this exists in the repo — there are 34 independent `arch/*.sh` scripts today and no orchestrator. Open: the de-stub rule (what bootstrap does when an upstream stub already occupies a path stow wants — the conflict list comes from `stow -n --no-folding` per package); Q5 (does the installer skip a pre-folded `custom/` on a genuinely fresh target); Q14 (does `systemctl --user enable` work from a TTY with no graphical session and no lingering, or does only `--now` on the timer need the post-relogin half); and the full throwaway-XDG install dry run, which validates the whole collision map at once and produces the fixture everything else is linted against.
**Success Criteria** (what must be TRUE):

  1. One documented command drives submodule init → ii `./setup` → stow → capture seed → `verify`, in that order, with stow strictly after the installer (BOOT-01, BOOT-02)
  2. Re-running the command on an already-complete machine changes nothing and exits 0; killing it at any step and re-running resumes from that step — both exercised against per-step state on disk, with `--from`, `--only` and `--dry-run` honoured (BOOT-01)
  3. The run prints where it stopped and what the operator must do next, and states plainly that the session entry point changes mid-run so a relogin between the install half and the verify half is unavoidable (BOOT-03)
  4. The last step is `verify --strict`, and its exit code is the bootstrap's exit code — a bootstrap that leaves drift cannot exit 0 (BOOT-04)
  5. `pacman -Qqen` and `pacman -Qqem` snapshots are committed as data with their date and host recorded, and re-running bootstrap regenerates them idempotently rather than appending (BOOT-05)

**Verification risk — this phase genuinely wants a second machine.** No fresh Arch host is available, and the fresh-machine claim cannot be fully proven in place. Fallback, in descending strength: (a) a VM or container if one can be stood up — the only thing that exercises the relogin hop and the empty-`$HOME` folding case together; (b) a throwaway `XDG_CONFIG_HOME` / `XDG_DATA_HOME` run of `./setup install-files` plus `stow -n --no-folding` for every package, which validates ordering, the collision map and the de-stub rule but not the session hop; (c) resumability and idempotence drills by killing the real run at each step boundary. If only (b) and (c) are achievable, BOOT-01's claim must be stated at the scratch-XDG level and labelled as such — not as a verified fresh-machine reproduction.
**Plans:** TBD

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Shell Foundation & Theme | v0.1 | 4/4 | Complete | 2026-07-21 |
| 2. Core Bar Modules | v0.1 | 13/13 | Complete | 2026-07-23 |
| 3. System & Audio Modules | v0.1 | 10/10 | Complete | 2026-07-24 |
| 4. IPC, Keybinds & Integration | v0.1 | 4/4 | Complete | 2026-07-25 |
| 5. Fork & Submodule Pin | v0.2 | 3/3 | Complete | 2026-07-25 |
| 6. Thin Setup Wrapper & Safe Defaults | v0.2 | 3/3 | Complete | 2026-07-26 |
| 7. Install, Session Hooks & Dual-Run Verify | v0.2 | 3/3 | Complete | 2026-07-27 |
| 8. Retire Local Quickshell Product | v0.2 | 3/3 | Complete | 2026-07-28 |
| 9. Workflow Documentation & Update Contract | v0.2 | 3/3 | Complete | 2026-08-01 |
| 10. Full-install impact inventory | v0.3 | 5/5 | Complete | 2026-08-07 |
| 11. Disposition decisions | v0.3 | 4/4 | Complete | 2026-08-10 |
| 12. Wrapper full-profile | v0.3 | 4/4 | Complete | 2026-08-18 |
| 13. Personal hypr/custom overlays | v0.3 | 2/2 | Complete | 2026-08-31 |
| 14. Live full adopt & verify | v0.3 | 2/2 | Complete | 2026-09-05 |
| 15. Playbook safe vs full | v0.3 | 6/6 | Complete | 2026-09-06 |
| 16. Retire the safe profile | v0.3 | 10/10 | Complete | 2026-09-08 |
| 17. Unblock stow and restore the session target | v0.4 | 7/7 | Complete    | 2026-09-13 |
| 18. Capture model — three trees and the collision map | v0.4 | 11/11 | Complete    | 2026-09-14 |
| 19. Link-aware `verify` | v0.4 | 5/5 | Complete    | 2026-09-14 |
| 20. hypr/custom overlays and startup restore | v0.4 | 0/? | Not started | - |
| 21. ii bar config capture | v0.4 | 0/? | Not started | - |
| 22. KDE and GTK capture | v0.4 | 0/? | Not started | - |
| 23. One-command bootstrap | v0.4 | 0/? | Not started | - |

**Coverage:** v0.1 shipped · v0.2 shipped · v0.3 shipped · v0.4 in progress — 35/35 requirements mapped across Phases 17-23, 0 unmapped

---
*Last updated: 2026-09-12 — v0.4 Personal config layer roadmapped (Phases 17-23)*
