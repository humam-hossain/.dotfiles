# Phase 24: Address tech debt: bookkeeping and validation cleanup - Context

**Gathered:** 2026-09-16
**Status:** Ready for planning

<domain>
## Phase Boundary

Address all accumulated technical debt, metadata inconsistencies, and validation coverage gaps identified in the Milestone v0.4 Audit (`.planning/v0.4-MILESTONE-AUDIT.md`) before archiving milestone v0.4, and realign session keybindings to ensure the Quickshell `SUPER + /` cheatsheet is 100% accurate:

1. **Bookkeeping & Traceability Synchronization (`DEBT-01`):**
   - Reconcile 10 stale `Pending` status markers in `REQUIREMENTS.md` across Phase 20 (`HYPR-01`, `HYPR-02`, `HYPR-03`, `START-01`, `SAFE-01`) and Phase 23 (`BOOT-01`, `BOOT-02`, `BOOT-03`, `BOOT-04`, `BOOT-05`) to `Complete` to match verified `[x]` status.
   - Backfill missing `requirements_completed` frontmatter in Phase 23 plan summaries (`23-01-SUMMARY.md`, `23-02-SUMMARY.md`, `23-03-SUMMARY.md` for `BOOT-01..05`) and Phase 18 plan summaries (`18-02-SUMMARY.md` for `CAP-05`, `18-03-SUMMARY.md` for `CAP-08`).
   - Formally add `DEBT-01` through `DEBT-04` to `REQUIREMENTS.md` and update `ROADMAP.md` Phase 24 requirements mapping.

2. **Nyquist Validation Compliance (`DEBT-02`):**
   - Reconcile `VALIDATION.md` files across all v0.4 phases (Phases 17, 18, 20, 21, 22, 23) to cite existing automated test scripts (`scripts/phase*-assert.sh`), update verification tables, and achieve `nyquist_compliant: true`.
   - Formally document non-blocking manual verification items (Phase 20 live startup apps, Phase 21 notification daemon delivery) as manual inspection/sampling tests.
   - Explicitly document the single-machine scratch-XDG testing boundary in `23-VALIDATION.md` per Phase 23 verification risk parameters.

3. **Repository Hygiene & Debt Disposition (`DEBT-03`):**
   - Scope the unanchored `*.socket` pattern in `.gitignore` (add exception `!stow/systemd/**` or anchor) to prevent accidental exclusion of systemd socket activation units.
   - Formally affirm operator triage in `STATE.md` that `stow/system_monitor/.config/system_monitor/ping/.env` is tracked configuration containing only local loopback parameters (non-credential).
   - Formally record the 12 gitleaks dead-credential allowlist entries in `STATE.md` as accepted historical risk.
   - Codify non-interactive test assertion for Phase 21 capture `--notify` execution path in Phase 24's assert suite.

4. **Session Keybindings & Cheatsheet Realignment (`DEBT-04`):**
   - In `stow/hypr/.config/hypr/custom/keybinds.lua`, unbind upstream `SUPER + SHIFT + L` (upstream sleep).
   - Map `SUPER + Scroll_Lock` to `Session: Sleep` (`systemctl suspend || loginctl suspend`, `{ locked = true, description = "Session: Sleep" }`).
   - Map `SUPER + SHIFT + Scroll_Lock` to `Session: Logout` (`hl.dsp.exit()`, `{ description = "Session: Logout" }`).
   - Retain `Scroll_Lock` for `Session: Lock screen` (`hyprlock`, `{ description = "Session: Lock screen" }`).
   - Audit all personal keybindings in `keybinds.lua` to ensure syntax passes `luac -p`, adheres to `"Category: Label"` taxonomy, contains zero duplicate chords, and registers cleanly in live `hyprctl binds -j` so the Quickshell cheatsheet (`SUPER + /`) displays accurate, up-to-date session controls.

5. **Phase Test Harness & Milestone Verification:**
   - Author dedicated test script `scripts/phase24-tech-debt-assert.sh` exercising all Phase 24 deliverables.
   - Enforce live reload (`hyprctl reload`) and live compositor query (`hyprctl binds -j`).
   - Ensure `arch/dots-hyprland.sh verify --strict` exits 0 with zero drift.
   - Re-run milestone audit to verify transition to clean/passed.

Out of scope:
- Retroactively modifying historical closed-phase assert scripts (e.g. `scripts/phase17-unblock-assert.sh`, `scripts/phase20-hypr-*.sh`, `scripts/phase21-capture-assert.sh`) or rewriting closed phase narrative prose; all historical artifacts remain frozen per D-20.
- Modifying upstream vendor files in `vendor/dots-hyprland`.
- Adding new package scripts or stow sites under `arch/` (maintaining `PAIR_COUNT == 18` in `scripts/phase17-unblock-assert.sh`).

</domain>

<decisions>
## Implementation Decisions

### Bookkeeping & Traceability

- **D-01:** Direct update of 10 stale `Pending` status markers in `REQUIREMENTS.md` traceability table to `Complete`: `HYPR-01`, `HYPR-02`, `HYPR-03`, `START-01`, `SAFE-01` (Phase 20) and `BOOT-01`, `BOOT-02`, `BOOT-03`, `BOOT-04`, `BOOT-05` (Phase 23). All corresponding checkboxes are already `[x]` and implementations passed verification. — **Reversibility:** reversible
- **D-02:** Backfill missing `requirements_completed` frontmatter in plan summaries:
  - `23-01-SUMMARY.md`: `BOOT-01`, `BOOT-02` (root orchestrator, non-root check, CLI flags, XDG state machine)
  - `23-02-SUMMARY.md`: `BOOT-03`, `BOOT-05` (de-stubbing, stow orchestration, capture seed, package snapshots)
  - `23-03-SUMMARY.md`: `BOOT-04` (relogin session probe, systemd timers, verify --strict exit code)
  - `18-02-SUMMARY.md`: `CAP-05` (unfolded directory symlinks)
  - `18-03-SUMMARY.md`: `CAP-08` (experimental files refusal) — **Reversibility:** reversible
- **D-03:** Add explicit requirements `DEBT-01` through `DEBT-04` to `REQUIREMENTS.md` and map to Phase 24 in `ROADMAP.md`:
  - `DEBT-01`: Traceability and plan summary bookkeeping complete with zero stale status markers.
  - `DEBT-02`: Nyquist validation compliance achieved across all v0.4 phases (17-23).
  - `DEBT-03`: Repository hygiene items triaged and resolved (.gitignore scoping, .env documentation, gitleaks accepted risk, notify test coverage).
  - `DEBT-04`: Session keybindings realigned (sleep on SUPER+Scroll_Lock, logout on SUPER+SHIFT+Scroll_Lock) with 100% Quickshell cheatsheet accuracy. — **Reversibility:** reversible
- **D-04:** D-20 frozen history precedent strictly preserved: Closed-phase assert scripts and historical prose remain untouched. Historical records reflect the state at the time of phase close; fixes and new assertions are authored in Phase 24 artifacts. — **Reversibility:** permanent invariant

### Nyquist Validation Compliance

- **D-05:** Reconcile `VALIDATION.md` files for Phases 17, 18, 20, 21, 22, and 23:
  - Phase 17: Update `17-VALIDATION.md` to reference `scripts/phase17-unblock-assert.sh`, reconcile manual checks, and set `nyquist_compliant: true`.
  - Phase 18: Update `18-VALIDATION.md` to reference `scripts/phase18-capture-model-assert.sh` and set `status: validated`, `nyquist_compliant: true`.
  - Phase 20: Update `20-VALIDATION.md` to reference `scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh`, mark live app start as manual inspection, and set `status: validated`, `nyquist_compliant: true`.
  - Phase 21: Update `21-VALIDATION.md` to reference `scripts/phase21-capture-assert.sh` and Phase 24 notify assertion, set `status: validated`, `nyquist_compliant: true`.
  - Phase 22: Update `22-VALIDATION.md` to reference `scripts/phase22-kde-gtk-assert.sh` and set `status: validated`, `nyquist_compliant: true`.
  - Phase 23: Update `23-VALIDATION.md` to reference `scripts/phase23-bootstrap-assert.sh`, set `status: validated`, `nyquist_compliant: true`. — **Reversibility:** reversible
- **D-06:** Non-blocking manual verification classification: Live session autostart apps (Phase 20) and notification daemon popups (Phase 21) are classified as manual sampling/inspection tests in VALIDATION docs, preventing false negative automated test failures. — **Reversibility:** reversible
- **D-07:** Document single-machine scratch-XDG testing boundary: `23-VALIDATION.md` explicitly documents that bootstrap mechanisms (de-stubbing, manifest generation, atomic JSON state, stow linking, strict verify) are fully proven by `scripts/phase23-bootstrap-assert.sh` in scratch-XDG environments, while physical fresh-machine reproduction is noted as an accepted constraint. — **Reversibility:** reversible

### Minor Debt Triage & Hygiene

- **D-08:** Tracked `.env` in `stow/system_monitor/`: Remains tracked in repository. Formally document in `STATE.md` and `CONTEXT.md` that this file contains only local loopback daemon parameters (`BIND_HOST=127.0.0.1`, `PORT=8765`, `COLLECTION_INTERVAL=5`, `STALE_AFTER_SECONDS=15`) with zero credentials or secrets. — **Reversibility:** reversible
- **D-09:** Gitleaks allowlist entries: Formally record the 12 allowlist entries in `.gitleaks.toml` in `STATE.md` as accepted historical risk for dead credentials in published pre-v0.3 commits. — **Reversibility:** reversible
- **D-10:** Scope `.gitignore` `*.socket`: Refine line 61 of `.gitignore` to avoid ignoring potential systemd socket activation units (e.g. by adding exception `!stow/systemd/**` or qualifying the pattern). — **Reversibility:** reversible
- **D-11:** Codify Phase 21 `--notify` assertion: Author a non-interactive assertion in `scripts/phase24-tech-debt-assert.sh` verifying that `arch/dots-hyprland.sh capture --notify` formats notification arguments correctly and executes/gracefully handles notification delivery without error. — **Reversibility:** reversible

### Keybindings & Cheatsheet Realignment

- **D-12:** Keybinding reallocation in `stow/hypr/.config/hypr/custom/keybinds.lua`:
  - Add `hl.unbind("SUPER + SHIFT + L")` to the upstream unbinds block (retires upstream sleep).
  - Rebind `SUPER + Scroll_Lock` to `Session: Sleep` (`systemctl suspend || loginctl suspend`, `{ locked = true, description = "Session: Sleep" }`).
  - Rebind `SUPER + SHIFT + Scroll_Lock` to `Session: Logout` (`hl.dsp.exit()`, `{ description = "Session: Logout" }`).
  - Retain `Scroll_Lock` for `Session: Lock screen` (`hl.dsp.exec_cmd("hyprlock")`, `{ description = "Session: Lock screen" }`). — **Reversibility:** reversible
- **D-13:** Cheatsheet taxonomy & syntax validation: All personal keybindings in `keybinds.lua` must strictly follow the `"Category: Label"` description format, pass `luac -p` syntax checking, and contain zero duplicate key chords. This ensures Quickshell's `SUPER + /` cheatsheet parses and displays the complete list without malformed categories or collisions. — **Reversibility:** reversible
- **D-14:** Live reload & verification: Trigger `hyprctl reload` during verification and query `hyprctl binds -j` to confirm the live compositor registered `SUPER + Scroll_Lock` as `Session: Sleep` and `SUPER + SHIFT + Scroll_Lock` as `Session: Logout`. — **Reversibility:** reversible

### Verification & Phase Exit Gate

- **D-15:** Dedicated assert script `scripts/phase24-tech-debt-assert.sh`: Author test harness checking:
  1. REQUIREMENTS.md: 0 stale `Pending` markers, DEBT-01..04 defined.
  2. Plan summaries: Phase 23 and 18 summaries contain non-empty `requirements_completed`.
  3. Nyquist validation: VALIDATION.md files for phases 17-23 all have `nyquist_compliant: true`.
  4. Gitignore: `*.socket` pattern correctly scoped.
  5. Keybinds: `keybinds.lua` syntax passes `luac -p`, unbinds `SUPER + SHIFT + L`, binds `SUPER + Scroll_Lock` and `SUPER + SHIFT + Scroll_Lock`, zero duplicate chords, valid `"Category: Label"` taxonomy.
  6. Live compositor: `hyprctl binds -j` confirms live registration.
  7. Capture notify: `--notify` invocation passes cleanly. — **Reversibility:** reversible
- **D-16:** Milestone audit clean status: Re-running `/gsd-audit-milestone v0.4` at the end of Phase 24 must report `status: passed` (clean status with zero blocking tech debt). — **Reversibility:** reversible
- **D-17:** Inviolable verify invariant: `arch/dots-hyprland.sh verify --strict` must exit 0 with zero drift after all Phase 24 changes. — **Reversibility:** permanent invariant
- **D-18:** Commit structure: Changes committed via logical atomic commits per deliverable:
  - `fix(hypr): realign sleep and logout keybinds for cheatsheet accuracy`
  - `fix(git): scope socket ignore pattern in .gitignore`
  - `docs(traceability): reconcile requirements markers and plan summaries`
  - `docs(validation): achieve Nyquist compliance across v0.4 phases`
  - `test(24): add tech debt and validation cleanup assert script` — **Reversibility:** reversible

### Claude's Discretion

- Exact implementation helper functions inside `scripts/phase24-tech-debt-assert.sh`.
- Formatting adjustments in `VALIDATION.md` tables to cleanly present verification commands and evidence.
- Minor wording refinements in REQUIREMENTS.md requirement descriptions.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone Audit & Planning
- `.planning/v0.4-MILESTONE-AUDIT.md` — Source of truth for all identified tech debt, stale status markers, and validation gaps.
- `.planning/REQUIREMENTS.md` — Central requirements traceability table.
- `.planning/ROADMAP.md` — Milestone v0.4 roadmap and phase breakdown.
- `.planning/STATE.md` — Project state, accumulated decisions, and accepted risks.

### Keybindings & Desktop Shell
- `stow/hypr/.config/hypr/custom/keybinds.lua` — Source of truth for personal Hyprland keybindings and cheatsheet taxonomy.
- `vendor/dots-hyprland/dots/.config/hypr/hyprland/keybinds.lua` — Upstream keybindings reference (lines 334-342 for upstream session binds).
- `.planning/research/FEATURES.md` § "Does the cheatsheet break?" — Specifications for Quickshell `SUPER + /` cheatsheet taxonomy and `hyprctl binds -j` parsing.

### Validation & Test Harnesses
- `.planning/phases/17-unblock-stow-and-restore-the-session-target/17-VALIDATION.md`
- `.planning/phases/18-capture-model-three-trees-and-the-collision-map/18-VALIDATION.md`
- `.planning/phases/19-link-aware-verify/19-VALIDATION.md`
- `.planning/phases/20-hypr-custom-overlays-and-startup-restore/20-VALIDATION.md`
- `.planning/phases/21-ii-bar-config-capture/21-VALIDATION.md`
- `.planning/phases/22-kde-and-gtk-capture/22-VALIDATION.md`
- `.planning/phases/23-one-command-bootstrap/23-VALIDATION.md`
- `scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh` § Section 6
- `scripts/phase21-capture-assert.sh`
- `scripts/phase23-bootstrap-assert.sh`
- `arch/dots-hyprland.sh` — Strict verification entry point (`verify --strict`).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh`: Section 6 contains an embedded Python script validating luac syntax, `"Category: Label"` taxonomy, and duplicate chords in `keybinds.lua`. Reusable directly in `scripts/phase24-tech-debt-assert.sh`.
- `arch/dots-hyprland.sh`: Provides `verify --strict` and `capture --notify` commands for automated verification.
- `scripts/phase12-full-smoke.sh` & `scripts/phase23-bootstrap-assert.sh`: Established bash test runner patterns (`pass`, `fail`, `set -euo pipefail`, exit code tracking).

### Established Patterns
- **D-20 Frozen History Rule:** Historical closed-phase assert scripts and phase narratives are frozen evidence. Never edit historical scripts to make audits green; write new assertions in the current phase.
- **Cheatsheet Taxonomy Rule:** All keybindings intended for Quickshell cheatsheet display must use `{ description = "Category: Label" }` with the category preceding the first colon.
- **Pair Count Invariant:** `arch/dots-hyprland.sh` maintains strictly 18 stow sites across `arch/*.sh` (`PAIR_COUNT == 18` checked by Phase 17 assert). Do not add scripts under `arch/`.
- **Zero Drift Invariant:** Repository working tree must remain clean; `arch/dots-hyprland.sh verify --strict` must exit 0.

### Integration Points
- `stow/hypr/.config/hypr/custom/keybinds.lua` -> Symlinked to `~/.config/hypr/custom/keybinds.lua`. Edits take effect on `hyprctl reload`.
- `hyprctl binds -j` -> Live IPC query feeding Quickshell's cheatsheet service.
- `.planning/REQUIREMENTS.md` & `.planning/phases/*/*-SUMMARY.md` -> Cross-referenced by `/gsd-audit-milestone`.

</code_context>

<specifics>
## Specific Ideas

- **Cheatsheet Accuracy & Clean Display:** The user specifically emphasized: *"Make sure keybinding cheatsheet SUPER + / - the list that shows here is completely upto date. keybind sleep needs to be SUPER + Scroll_lock and logout needs to be SUPER + SHIFT + Scroll_lock"*. Unbinding upstream `SUPER + SHIFT + L` ensures no obsolete sleep chord remains in the cheatsheet list.
- **Non-credential Triage:** Affirm that `.env` in `stow/system_monitor/` only holds localhost bind parameters.

</specifics>

<deferred>
## Deferred Ideas

- **Second Physical Arch Host Bootstrap Reproduction:** Full physical fresh-machine testing remains deferred until secondary hardware is available; scratch-XDG testing satisfies mechanical verification within the single-operator environment.
- **Ubuntu/Debian Legacy Path Cleanup:** Out-of-scope reader scripts referencing legacy `.config/` remain backlog items for a future non-Arch platform phase.

</deferred>

---

*Phase: 24-address-tech-debt-bookkeeping-and-validation-cleanup*
*Context gathered: 2026-09-16*
