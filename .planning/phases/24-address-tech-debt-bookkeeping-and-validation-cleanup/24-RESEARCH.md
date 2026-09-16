# Phase 24: Address Tech Debt: Bookkeeping and Validation Cleanup — Research

**Gathered:** 2026-09-16  
**Status:** Complete / Ready for Planning  
**Domain:** Milestone v0.4 Tech Debt, Metadata Bookkeeping, Validation Reconciliation, Desktop Session Keybinds

---

<user_constraints>
## User Constraints & Decisions

### Locked Decisions (D-01 through D-18)

- **D-01 (Traceability Reconciliation):** Directly update the 10 stale `Pending` status markers in `.planning/REQUIREMENTS.md` traceability table to `Complete`:
  - Phase 20: `HYPR-01`, `HYPR-02`, `HYPR-03`, `START-01`, `SAFE-01`
  - Phase 23: `BOOT-01`, `BOOT-02`, `BOOT-03`, `BOOT-04`, `BOOT-05`
  All corresponding checkboxes are already `[x]` and implementations passed verification.
- **D-02 (Plan Summary Backfill):** Backfill missing `requirements_completed` frontmatter in plan summaries:
  - `.planning/phases/23-one-command-bootstrap/23-01-SUMMARY.md`: `BOOT-01`, `BOOT-02` (root orchestrator, non-root check, CLI flags, XDG state machine)
  - `.planning/phases/23-one-command-bootstrap/23-02-SUMMARY.md`: `BOOT-03`, `BOOT-05` (de-stubbing, stow orchestration, capture seed, package snapshots)
  - `.planning/phases/23-one-command-bootstrap/23-03-SUMMARY.md`: `BOOT-04` (relogin session probe, systemd timers, verify --strict exit code)
  - `.planning/phases/18-capture-model-three-trees-and-the-collision-map/18-02-SUMMARY.md`: `CAP-05` (unfolded directory symlinks)
  - `.planning/phases/18-capture-model-three-trees-and-the-collision-map/18-03-SUMMARY.md`: ensure `CAP-08` (experimental files refusal) is canonically recognized by `gsd-tools` query summary-extract
- **D-03 (Requirements Registration):** Add explicit requirements `DEBT-01` through `DEBT-04` to `.planning/REQUIREMENTS.md` and map to Phase 24 in `.planning/ROADMAP.md`:
  - `DEBT-01`: Traceability and plan summary bookkeeping complete with zero stale status markers.
  - `DEBT-02`: Nyquist validation compliance achieved across all v0.4 phases (17–23).
  - `DEBT-03`: Repository hygiene items triaged and resolved (`.gitignore` scoping, `.env` documentation, gitleaks accepted risk, notify test coverage).
  - `DEBT-04`: Session keybindings realigned (sleep on `SUPER + Scroll_Lock`, logout on `SUPER + SHIFT + Scroll_Lock`) with 100% Quickshell cheatsheet accuracy.
- **D-04 (Frozen History Rule):** D-20 frozen history precedent strictly preserved: Closed-phase assert scripts and historical phase narratives remain untouched. Historical records reflect the state at the time of phase close; fixes and new assertions are authored in Phase 24 artifacts.
- **D-05 (Nyquist Reconciliation):** Reconcile `VALIDATION.md` files for Phases 17, 18, 20, 21, 22, and 23:
  - Phase 17 (`17-VALIDATION.md`): Update to reference `scripts/phase17-unblock-assert.sh`, reconcile manual checks, and set `nyquist_compliant: true`.
  - Phase 18 (`18-VALIDATION.md`): Map TBD tasks to plans 18-01..18-04, reference `scripts/phase18-capture-model-assert.sh`, set `wave_0_complete: true`, `status: validated`, `nyquist_compliant: true`.
  - Phase 20 (`20-VALIDATION.md`): Reference `scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh`, mark live app start as manual inspection, set `wave_0_complete: true`, `status: validated`, `nyquist_compliant: true`.
  - Phase 21 (`21-VALIDATION.md`): Reference `scripts/phase21-ii-bar-config-capture-assert.sh` and Phase 24 notify assertion, set `wave_0_complete: true`, `status: validated`, `nyquist_compliant: true`.
  - Phase 22 (`22-VALIDATION.md`): Reference `scripts/phase22-kde-and-gtk-capture-assert.sh`, set `wave_0_complete: true`, `status: validated`, `nyquist_compliant: true`.
  - Phase 23 (`23-VALIDATION.md`): Reference `scripts/phase23-bootstrap-assert.sh`, set `wave_0_complete: true`, `status: validated`, `nyquist_compliant: true`.
- **D-06 (Non-blocking Manual Classification):** Live session autostart apps (Phase 20) and notification daemon popups (Phase 21) are classified as manual sampling/inspection tests in `VALIDATION.md` docs, preventing false-negative automated test failures.
- **D-07 (Scratch-XDG Boundary Documentation):** `23-VALIDATION.md` explicitly documents that bootstrap mechanisms (de-stubbing, manifest generation, atomic JSON state, stow linking, strict verify) are fully proven by `scripts/phase23-bootstrap-assert.sh` in scratch-XDG environments, while physical fresh-machine reproduction is noted as an accepted constraint.
- **D-08 (Tracked .env Triage):** `stow/system_monitor/.config/system_monitor/ping/.env` remains tracked in repository. Formally document in `.planning/STATE.md` that this file contains only local loopback daemon parameters (`BIND_HOST=127.0.0.1`, `PORT=8765`, `COLLECTION_INTERVAL=5`, `STALE_AFTER_SECONDS=15`) with zero credentials or secrets.
- **D-09 (Gitleaks Accepted Risk):** Formally record the 12 allowlist entries in `.gitleaks.toml` in `.planning/STATE.md` as accepted historical risk for dead credentials in published pre-v0.3 commits.
- **D-10 (Scope .gitignore *.socket):** Refine line 61 of `.gitignore` to avoid ignoring potential systemd socket activation units by adding the exception `!stow/systemd/**`.
- **D-11 (Codify Phase 21 --notify Assertion):** Author a non-interactive assertion in `scripts/phase24-tech-debt-assert.sh` verifying that `arch/dots-hyprland.sh capture --notify` formats notification arguments correctly and executes/gracefully handles notification delivery without error.
- **D-12 (Keybinding Reallocation in keybinds.lua):**
  - Add `hl.unbind("SUPER + SHIFT + L")` to the upstream unbinds block (retires upstream sleep).
  - Rebind `SUPER + Scroll_Lock` to `Session: Sleep` (`systemctl suspend || loginctl suspend`, `{ locked = true, description = "Session: Sleep" }`).
  - Rebind `SUPER + SHIFT + Scroll_Lock` to `Session: Logout` (`hl.dsp.exit()`, `{ description = "Session: Logout" }`).
  - Retain `Scroll_Lock` for `Session: Lock screen` (`hl.dsp.exec_cmd("hyprlock")`, `{ description = "Session: Lock screen" }`).
- **D-13 (Cheatsheet Taxonomy & Syntax Validation):** All personal keybindings in `keybinds.lua` must strictly follow `"Category: Label"` description format, pass `luac -p` syntax checking, and contain zero duplicate key chords. This ensures Quickshell's `SUPER + /` cheatsheet parses and displays the complete list without malformed categories or collisions.
- **D-14 (Live Reload & Verification):** Trigger `hyprctl reload` during verification and query `hyprctl binds -j` to confirm the live compositor registered `SUPER + Scroll_Lock` as `Session: Sleep` and `SUPER + SHIFT + Scroll_Lock` as `Session: Logout`.
- **D-15 (Dedicated Assert Script):** Author test harness `scripts/phase24-tech-debt-assert.sh` checking:
  1. REQUIREMENTS.md: 0 stale `Pending` markers, DEBT-01..04 defined.
  2. Plan summaries: Phase 23 and Phase 18 summaries contain non-empty `requirements_completed` extracted by `gsd-tools`.
  3. Nyquist validation: VALIDATION.md files for phases 17–23 all have `nyquist_compliant: true`.
  4. Gitignore: `*.socket` pattern correctly scoped via `!stow/systemd/**`.
  5. Keybinds: `keybinds.lua` syntax passes `luac -p`, unbinds `SUPER + SHIFT + L`, binds `SUPER + Scroll_Lock` and `SUPER + SHIFT + Scroll_Lock`, zero duplicate chords, valid `"Category: Label"` taxonomy.
  6. Live compositor: `hyprctl binds -j` confirms live registration.
  7. Capture notify: `--notify` invocation passes cleanly.
- **D-16 (Milestone Audit Clean Status):** Re-running `/gsd-audit-milestone v0.4` at the end of Phase 24 must report clean status with zero blocking tech debt (`status: passed`).
- **D-17 (Inviolable Verify Invariant):** `arch/dots-hyprland.sh verify --strict` must exit 0 with zero drift after all Phase 24 changes.
- **D-18 (Logical Atomic Commits):** Changes committed via logical atomic commits per deliverable:
  - `fix(hypr): realign sleep and logout keybinds for cheatsheet accuracy`
  - `fix(git): scope socket ignore pattern in .gitignore`
  - `docs(traceability): reconcile requirements markers and plan summaries`
  - `docs(validation): achieve Nyquist compliance across v0.4 phases`
  - `test(24): add tech debt and validation cleanup assert script`

### Claude's Discretion
- Implementation helper functions inside `scripts/phase24-tech-debt-assert.sh`.
- Formatting adjustments in `VALIDATION.md` tables to cleanly present verification commands and evidence.
- Minor wording refinements in `REQUIREMENTS.md` requirement descriptions.

### Deferred Ideas
- **Second Physical Arch Host Bootstrap Reproduction:** Physical fresh-machine reproduction deferred until secondary hardware is available; scratch-XDG testing satisfies mechanical verification within the single-operator environment.
- **Ubuntu/Debian Legacy Path Cleanup:** Out-of-scope reader scripts referencing legacy `.config/` remain backlog items in `.planning/todos/backlog-legacy-config-readers.md` for a future non-Arch platform phase.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| Requirement ID | Description | Success Verification |
|---|---|---|
| **DEBT-01** | Traceability and plan summary bookkeeping complete with zero stale status markers | `.planning/REQUIREMENTS.md` has 0 `Pending` markers for verified phases (17-23); plan summaries `18-02`, `18-03`, `23-01`, `23-02`, `23-03` contain valid `requirements_completed` frontmatter; `ROADMAP.md` reflects Phase 24 requirements mapping. |
| **DEBT-02** | Nyquist validation compliance achieved across all v0.4 phases (17-23) | `VALIDATION.md` files for Phases 17, 18, 20, 21, 22, 23 updated with `status: validated`, `wave_0_complete: true`, and `nyquist_compliant: true`; non-blocking manual items and scratch-XDG testing boundary documented. |
| **DEBT-03** | Repository hygiene items triaged and resolved (`.gitignore` scoping, `.env` documentation, gitleaks accepted risk, notify test coverage) | `.gitignore:61` scoped with `!stow/systemd/**`; `STATE.md` affirms non-credential status of `stow/system_monitor/.../.env` and records 12 gitleaks allowlist entries as accepted historical risk; non-interactive `--notify` assertion codified in test harness. |
| **DEBT-04** | Session keybindings realigned (sleep on `SUPER + Scroll_Lock`, logout on `SUPER + SHIFT + Scroll_Lock`) with 100% Quickshell cheatsheet accuracy | `stow/hypr/.config/hypr/custom/keybinds.lua` unbinds `SUPER + SHIFT + L`, binds `SUPER + Scroll_Lock` to sleep, `SUPER + SHIFT + Scroll_Lock` to logout, retains `Scroll_Lock` for lock screen; passes `luac -p`, zero duplicate chords, `"Category: Label"` taxonomy; `hyprctl reload` live query `hyprctl binds -j` confirms live compositor binds. |
</phase_requirements>

---

## Summary & Primary Recommendation

Phase 24 is the final hardening and debt-closure phase for milestone `v0.4 (Personal config layer)`. It transitions the milestone from `status: tech_debt` to `status: passed` by resolving all 11 audit items identified in `.planning/v0.4-MILESTONE-AUDIT.md`, reconciling the validation posture of all earlier v0.4 phases to full Nyquist compliance, and realigning Hyprland session keybindings so the desktop cheatsheet (`SUPER + /`) provides an accurate UX for locking, sleeping, and logging out.

### Key Technical Findings:
1. **Live vs Upstream Session Keybinds:** In upstream `vendor/dots-hyprland/dots/.config/hypr/hyprland/keybinds.lua`, `SUPER + SHIFT + L` is bound to `Session: Sleep` (`systemctl suspend || loginctl suspend`). In personal `stow/hypr/.config/hypr/custom/keybinds.lua`, `SUPER + Scroll_Lock` was mapped to `hl.dsp.exit()` (`Session: Logout`), while `Scroll_Lock` was mapped to `hyprlock` (`Session: Lock screen`). Crucially, `SUPER + SHIFT + L` was never unbound, causing upstream sleep to remain active alongside the custom binds. Unbinding `SUPER + SHIFT + L`, binding `SUPER + Scroll_Lock` to `Session: Sleep`, and moving `Session: Logout` to `SUPER + SHIFT + Scroll_Lock` creates an intuitive chord progression on `Scroll_Lock` while eliminating chord pollution from the cheatsheet.
2. **Cheatsheet IPC Engine:** Quickshell's `SUPER + /` cheatsheet reads keybindings via Hyprland IPC (`hyprctl binds -j`). It groups binds by the category substring preceding the first colon in the `description` field. Personal keybindings must strictly follow `"Category: Label"`.
3. **Traceability Extraction Tooling:** The milestone audit workflow relies on `gsd-tools query summary-extract <summary-file> --fields requirements_completed`. In Phase 23, summaries used `requirements: [BOOT-01]` instead of `requirements_completed: [...]` or `requirements-completed: [...]`, causing the audit extractor to return empty arrays. Backfilling these fields resolves the 5 missing requirements in the milestone audit.
4. **Validation Frontmatter:** Phases 18, 20, 21, and 22 currently have `status: draft` and `nyquist_compliant: false` because they were never post-processed with formal validation closure after execution. All automated test scripts already exist (`scripts/phase18-capture-model-assert.sh`, `scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh`, `scripts/phase21-ii-bar-config-capture-assert.sh`, `scripts/phase22-kde-and-gtk-capture-assert.sh`). Reconciling their tables and frontmatter achieves 100% Nyquist compliance.
5. **D-20 Frozen History Boundary:** As established in Phase 17 and Phase 18, closed-phase test scripts (such as `scripts/phase18-capture-model-assert.sh`) must **not** be retroactively edited. Phase 24 delivers a dedicated assert script `scripts/phase24-tech-debt-assert.sh` that validates all Phase 24 requirements, including non-interactive verification of `capture --notify`.
6. **Gitignore Scoping:** `.gitignore` line 61 currently contains `*.socket`. While harmless today because no systemd socket units are stowed, `git check-ignore -v stow/systemd/.config/systemd/user/dotfiles-capture.socket` proves that line 61 would ignore systemd socket units. Adding `!stow/systemd/**` prevents this silent exclusion.

### Primary Recommendation:
Decompose Phase 24 into three distinct plans:
1. **Plan 24-01 (Desktop & Repository Hygiene):** Keybind realignment in `keybinds.lua`, `hyprctl reload`, `.gitignore` scoping, and `STATE.md` triage recording for `.env` and gitleaks allowlist.
2. **Plan 24-02 (Bookkeeping & Nyquist Compliance):** Update `REQUIREMENTS.md`, `ROADMAP.md`, plan summaries (`18-02`, `18-03`, `23-01`, `23-02`, `23-03`), and `VALIDATION.md` for Phases 17, 18, 20, 21, 22, 23.
3. **Plan 24-03 (Assert Harness & Milestone Verification):** Author `scripts/phase24-tech-debt-assert.sh`, run strict verification (`arch/dots-hyprland.sh verify --strict`), and execute the milestone audit re-check to guarantee clean exit.

---

## Architectural Responsibility Map

| Subsystem / Area | File(s) | Role & Invariant |
|---|---|---|
| **Hyprland Keybindings** | `stow/hypr/.config/hypr/custom/keybinds.lua` | Personal keybinding definitions. Symlinked directly to `~/.config/hypr/custom/keybinds.lua`. Must pass `luac -p`, contain zero duplicate chords, and adhere to `"Category: Label"` format. |
| **Desktop Cheatsheet** | Quickshell (`SUPER + /`) | Consumes live bindings from compositor via `hyprctl binds -j`. Displays grouped categories. |
| **Git Exclusion Rules** | `.gitignore` | Ignores ephemeral/cache files while preserving tracked repo assets. Must exempt `stow/systemd/**` from `*.socket`. |
| **Project State & Triage** | `.planning/STATE.md` | Authoritative log of architectural decisions, accepted risks (12 gitleaks entries), and non-credential affirmations (`ping/.env`). |
| **Milestone Requirements** | `.planning/REQUIREMENTS.md` | Core traceability table mapping all requirements to phases. 0 stale `Pending` markers permitted. |
| **Milestone Roadmap** | `.planning/ROADMAP.md` | Phase overview, plan progression, and requirement-to-phase mapping. |
| **Plan Summaries** | `.planning/phases/*/*-SUMMARY.md` | Per-plan execution records. Must export `requirements_completed` in frontmatter. |
| **Phase Validation Contracts** | `.planning/phases/*/*-VALIDATION.md` | Nyquist feedback contracts. Must have `status: validated` and `nyquist_compliant: true`. |
| **Phase 24 Test Suite** | `scripts/phase24-tech-debt-assert.sh` | Self-contained bash assertion harness exercising all Phase 24 deliverables. |
| **System Verification** | `arch/dots-hyprland.sh` | Strict link-aware verification (`verify --strict`) and capture orchestration (`capture --notify`). Must exit 0 with zero drift. |

---

## Standard Stack & Tools

| Tool / Technology | Version / Command | Purpose in Phase 24 |
|---|---|---|
| **Lua / luac** | Lua 5.4 (`luac -p`) | Syntax checking of `stow/hypr/.config/hypr/custom/keybinds.lua`. |
| **Hyprland IPC** | `hyprctl reload`, `hyprctl binds -j` | Reloads compositor configuration and queries active runtime keybindings. |
| **Python** | Python 3.14 (`python3 -c "..."`) | In-line AST/regex parsing in assert script for cheatsheet taxonomy and duplicate chord detection. |
| **Bash** | Bash 5.3 (`set -euo pipefail`) | Test execution in `scripts/phase24-tech-debt-assert.sh`. |
| **Git** | `git check-ignore`, `git diff`, `git status` | Verifying gitignore behavior and ensuring zero working tree drift. |
| **GSD Tools** | `node ~/.gemini/gsd-core/bin/gsd-tools.cjs` | Querying plan summary frontmatter via `query summary-extract`. |
| **Dotfiles Engine** | `arch/dots-hyprland.sh verify --strict` | Inviolable gate verifying link identity and zero drift. |

---

## Architecture Patterns & Pitfalls

### Pattern 1: Safe Compositor Keybind Reallocation
In Hyprland, personal overlays sit on top of upstream configurations. If an upstream keybind is not explicitly unbound using `hl.unbind("<chord>")`, Hyprland registers *both* handlers for that chord.
- **The Upstream Collision:** Upstream defines `SUPER + SHIFT + L` -> `systemctl suspend || loginctl suspend` (lines 336-337).
- **The Personal Realignment:** Personal config defines `Scroll_Lock` -> Lock, `SUPER + Scroll_Lock` -> Sleep, and `SUPER + SHIFT + Scroll_Lock` -> Logout.
- **The Solution:**
  1. Add `hl.unbind("SUPER + SHIFT + L")` to the unbind section.
  2. Map `SUPER + Scroll_Lock` with `{ locked = true, description = "Session: Sleep" }`. The `locked = true` flag ensures the sleep chord functions even when the session is locked.
  3. Map `SUPER + SHIFT + Scroll_Lock` with `{ description = "Session: Logout" }`.
  4. Run `hyprctl reload` and query `hyprctl binds -j` to verify that `modmask: 65, key: "L"` is purged, while `Scroll_Lock` modmasks 0 (Lock), 64 (Sleep), and 65 (Logout) are registered.

### Pattern 2: Quickshell Cheatsheet Taxonomy Enforcement
Quickshell parses the string after `description = "` in `hl.bind(...)`.
- Format: `"Category: Action Label"`.
- Rule: Category is everything preceding the first colon (`:`).
- Requirement: Exactly one colon separating Category and Label; both sides non-empty after trimming; zero duplicate key chords across the entire file.

### Pattern 3: Summary Frontmatter Schema Alignment
The GSD milestone audit tool (`audit-milestone.md`) uses `gsd-tools query summary-extract <summary> --fields requirements_completed`.
- In `23-01-SUMMARY.md`, `23-02-SUMMARY.md`, and `23-03-SUMMARY.md`, the frontmatter contained `requirements: [...]` instead of `requirements_completed: [...]`.
- In `18-02-SUMMARY.md`, `CAP-05` was omitted from `requirements-completed: [CAP-01, CAP-07]`.
- Normalizing all summaries to use `requirements_completed: [REQ-ID, ...]` guarantees deterministic extraction by `gsd-tools`.

### Pattern 4: Non-Interactive Desktop Notification Assertion
Testing `--notify` in automated assert scripts without popping intrusive desktop notifications or failing in headless test runners:
- In `arch/dots-hyprland.sh:1599`, `notify-send` is called with `|| true`.
- Testing can be performed non-destructively:
  1. Verify `./arch/dots-hyprland.sh capture --dry-run --notify` exits cleanly without argument parsing failure.
  2. In an isolated subshell fixture, create a dummy capture package, shadow `notify-send` in a local `PATH` override with a script that logs arguments, run `./arch/dots-hyprland.sh capture --notify`, and assert that the intercepted arguments match `"Dotfiles Capture" "Captured updates to repository" -a "Shell" -u low`.

### Pitfalls to Avoid:
- **Pitfall 1: Modifying Closed-Phase Assert Scripts (D-20 Violation).** Do NOT modify `scripts/phase18-capture-model-assert.sh`, `scripts/phase17-unblock-assert.sh`, etc. They are frozen historical artifacts. Any failures when running old scripts against the current repository state (e.g., phase 18 checking for an empty `capture/` tree before Phase 21 populated it) are documented historical divergences, not active regressions.
- **Pitfall 2: Modifying Files in `vendor/dots-hyprland`.** Upstream files are vendored git submodules. Never touch files under `vendor/dots-hyprland`. All custom overrides must live in `stow/hypr/.config/hypr/custom/`.
- **Pitfall 3: Breaking `verify --strict` Working Tree Cleanliness.** Edits to `.gitignore` or test scripts must not leave untracked temporary files or modified tracked files uncommitted.
- **Pitfall 4: Modifying Stow Site Count.** Never add or delete scripts under `arch/`. The invariant `PAIR_COUNT == 18` across `arch/*.sh` is asserted by multiple test harnesses.

---

## Runtime State Inventory

| State Element | Live Location / Target | How Evaluated / Changed |
|---|---|---|
| **Live Keybindings File** | `~/.config/hypr/custom/keybinds.lua` | Symlinked to `stow/hypr/.config/hypr/custom/keybinds.lua`. Editing repo file modifies live file instantly. |
| **Compositor Bind Cache** | Hyprland runtime IPC memory | Updated via `hyprctl reload`. Evaluated via `hyprctl binds -j`. |
| **Quickshell Cheatsheet** | Desktop Shell UI (`SUPER + /`) | Dynamically populated from compositor bindings on shortcut activation. |
| **Systemd Capture Timer** | `~/.config/systemd/user/dotfiles-capture.timer` | Active user timer running every 15m. Does not interfere with Phase 24 changes. |

---

## Environment Availability

All required tools are installed, verified, and operational on the host:
- `luac`: `/usr/bin/luac` (Lua 5.4.8, syntax checking operational).
- `hyprctl`: `/usr/bin/hyprctl` (IPC communication operational; `hyprctl binds -j` active).
- `git`: `/usr/bin/git` (git 2.50.1, check-ignore and working tree management operational).
- `bash`: `/usr/bin/bash` (Bash 5.3.3, robust scripting environment).
- `python3`: `/usr/bin/python3` (Python 3.14.0, AST/regex parsing operational).
- `gsd-tools`: `/home/pera/.gemini/gsd-core/bin/gsd-tools.cjs` (operational via `node`).

---

## Validation Architecture

The validation strategy for Phase 24 follows the Nyquist feedback contract: every task and plan wave has fast automated verification (< 5s latency), terminating in a comprehensive assert harness and strict system verification.

### Test Harness: `scripts/phase24-tech-debt-assert.sh`
The dedicated assertion script will be structured into five distinct sections:

1. **Section 1: Bookkeeping & Traceability (`DEBT-01`)**
   - Asserts 0 `Pending` status markers in `.planning/REQUIREMENTS.md`.
   - Asserts `DEBT-01`, `DEBT-02`, `DEBT-03`, `DEBT-04` are present in `REQUIREMENTS.md` and `ROADMAP.md`.
   - Executes `node /home/pera/.gemini/gsd-core/bin/gsd-tools.cjs query summary-extract` on `18-02`, `18-03`, `23-01`, `23-02`, and `23-03` to verify that `requirements_completed` contains `CAP-05`, `CAP-08`, `BOOT-01`, `BOOT-02`, `BOOT-03`, `BOOT-04`, `BOOT-05`.
2. **Section 2: Nyquist Validation Compliance (`DEBT-02`)**
   - Inspects `VALIDATION.md` for Phases 17, 18, 20, 21, 22, and 23.
   - Asserts `status: validated` (or `status: compliant`) and `nyquist_compliant: true` across all six files.
   - Verifies that manual-only items and scratch-XDG testing boundaries are formally documented.
3. **Section 3: Repository Hygiene & Debt Disposition (`DEBT-03`)**
   - Asserts `.gitignore:61` contains `*.socket` AND the exception `!stow/systemd/**` is active.
   - Uses `git check-ignore -v` to verify that a socket unit under `stow/systemd/` is NOT ignored.
   - Asserts `.planning/STATE.md` contains formal documentation of:
     - `stow/system_monitor/.config/system_monitor/ping/.env` as tracked non-credential configuration.
     - The 12 `.gitleaks.toml` allowlist entries as accepted historical risk.
   - Executes non-interactive assertion of `arch/dots-hyprland.sh capture --notify` with mocked `notify-send`.
4. **Section 4: Keybindings & Cheatsheet Realignment (`DEBT-04`)**
   - Validates `keybinds.lua` syntax via `luac -p`.
   - Asserts `hl.unbind("SUPER + SHIFT + L")` exists.
   - Runs embedded Python validator:
     - Parses all `hl.bind(...)` calls with descriptions.
     - Asserts 100% adherence to `"Category: Label"` format.
     - Asserts 0 duplicate key chords across all personal keybindings.
   - Queries live compositor via `hyprctl binds -j`:
     - Asserts `SUPER + SHIFT + L` (modmask 65, key L) is NOT registered as sleep.
     - Asserts `SUPER + Scroll_Lock` (modmask 64) is registered with description `"Session: Sleep"`.
     - Asserts `SUPER + SHIFT + Scroll_Lock` (modmask 65) is registered with description `"Session: Logout"`.
     - Asserts `Scroll_Lock` (modmask 0) is registered with description `"Session: Lock screen"`.
5. **Section 5: Strict System Verification & Zero Drift Gate**
   - Runs `./arch/dots-hyprland.sh verify --strict` and asserts exit code 0 (`FAIL=0 FINDINGS=0`).
   - Asserts `git status --porcelain` is completely clean.

---

## Security Domain

| Security Area | Standard / Threat | Phase 24 Resolution |
|---|---|---|
| **Credential Scanning** | ASVS V14 / Secret Leakage | 12 historical allowlist entries in `.gitleaks.toml` formally recorded in `STATE.md` as accepted risk for dead pre-v0.3 credentials in published tags. |
| **Tracked Configuration** | Non-credential Assurance | `stow/system_monitor/.config/system_monitor/ping/.env` verified to contain only local loopback parameters (`BIND_HOST=127.0.0.1`, `PORT=8765`, `COLLECTION_INTERVAL=5`, `STALE_AFTER_SECONDS=15`). Affirmed in `STATE.md`. |
| **Execution Boundaries** | Accidental Socket Exclusion | `.gitignore` scoped with `!stow/systemd/**` to ensure systemd socket activation units cannot be silently dropped from VCS. |
| **Session Lock Bypass** | Screen Locker Integrity | Session keybindings explicitly bind `Scroll_Lock` to `hyprlock` and `SUPER + Scroll_Lock` to suspend with `{ locked = true }`, ensuring keybindings respect desktop lock state. |

---

## Metadata & Sources

### Phase Metadata
- Phase Name: `address-tech-debt-bookkeeping-and-validation-cleanup`
- Milestone: `v0.4`
- Deliverable: Tech debt resolution, bookkeeping closure, Nyquist compliance across all v0.4 phases, Hyprland session keybind realignment.

### Canonical File References
- Context & User Decisions: `.planning/phases/24-address-tech-debt-bookkeeping-and-validation-cleanup/24-CONTEXT.md`
- Milestone Audit: `.planning/v0.4-MILESTONE-AUDIT.md`
- Project State: `.planning/STATE.md`
- Requirements: `.planning/REQUIREMENTS.md`
- Keybindings Source of Truth: `stow/hypr/.config/hypr/custom/keybinds.lua`
- Upstream Keybindings Reference: `vendor/dots-hyprland/dots/.config/hypr/hyprland/keybinds.lua`
- Ignore Rules: `.gitignore`
- System Wrapper: `arch/dots-hyprland.sh`
- Prior Assert Reference: `scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh`
