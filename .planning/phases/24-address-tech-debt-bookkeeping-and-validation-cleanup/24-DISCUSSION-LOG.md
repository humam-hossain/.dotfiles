# Phase 24: Address tech debt: bookkeeping and validation cleanup - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-16
**Phase:** 24-address-tech-debt-bookkeeping-and-validation-cleanup
**Areas discussed:** Bookkeeping & Traceability, Nyquist Validation Coverage, Minor Debt Triage, Keybindings & Cheatsheet Update, Verification & Milestone Exit Gate

---

## Bookkeeping & Traceability

| Option | Description | Selected |
|--------|-------------|----------|
| Direct update to Complete | Change all 10 stale Pending markers to Complete in REQUIREMENTS.md to match verified [x] status | ✓ |
| Validate against test asserts first | Re-run test scripts for Phases 20 and 23 before flipping markers to Complete | |
| You decide | Use whichever approach best preserves audit traceability | |

**User's choice:** Direct update to Complete.
**Notes:** Checkboxes in REQUIREMENTS.md were already `[x]` and implementations passed in VERIFICATION.md. Markers were simply un-flipped from Pending.

---

## Plan Summary Backfill

| Option | Description | Selected |
|--------|-------------|----------|
| Exact backfill | Map BOOT-01..05 to 23-01/02/03-SUMMARY.md and CAP-05/08 to 18-02/03-SUMMARY.md based on actual plan deliverables | ✓ |
| Phase 23 only | Backfill BOOT-01..05 in Phase 23 summaries and leave Phase 18 summaries frozen | |
| You decide | Assign requirements to corresponding plan summaries | |

**User's choice:** Exact backfill.
**Notes:** Eliminates audit findings where requirements were verified in VERIFICATION.md but omitted in plan-level summary frontmatter.

---

## Requirements Definition

| Option | Description | Selected |
|--------|-------------|----------|
| Add explicit DEBT requirement IDs | Add DEBT-01 (bookkeeping), DEBT-02 (Nyquist validation), DEBT-03 (hygiene/minor debt), DEBT-04 (keybindings & cheatsheet) to REQUIREMENTS.md | ✓ |
| Keep requirement-free | Treat Phase 24 as a pure chore/maintenance phase in ROADMAP.md without adding new requirement IDs | |
| You decide | Choose whichever approach aligns best with existing conventions | |

**User's choice:** Add explicit DEBT requirement IDs (DEBT-01 through DEBT-04).
**Notes:** Provides 100% requirements coverage for Phase 24 in both REQUIREMENTS.md and ROADMAP.md.

---

## Historical Phase Integrity (D-20)

| Option | Description | Selected |
|--------|-------------|----------|
| Follow D-20 frozen history precedent | Preserve closed-phase prose and assert records as frozen history; only edit current planning docs and targeted summary frontmatter | ✓ |
| Sweep historical prose | Retroactively update all historical phase docs that reference stale milestone counts or legacy paths | |
| You decide | Enforce standard repository historical integrity rules | |

**User's choice:** Follow D-20 frozen history precedent.
**Notes:** Closed-phase assert scripts (e.g. `scripts/phase17-unblock-assert.sh`, `scripts/phase20-hypr-*.sh`, `scripts/phase21-capture-assert.sh`) remain frozen evidence and are not modified. Fixes and new assertions are authored in Phase 24 artifacts.

---

## Nyquist Validation Coverage

| Option | Description | Selected |
|--------|-------------|----------|
| Full reconciliation against existing test scripts | Update VALIDATION.md for Phases 17, 18, 20, 21, 22, 23 to cite existing scripts/phase*-assert.sh harnesses and achieve compliant status | ✓ |
| Update draft phases only (18, 20, 21, 22, 23) | Leave Phase 17 as partial per its historical record | |
| You decide | Bring all phases to compliant status where automated test scripts exist | |

**User's choice:** Full reconciliation against existing test scripts.
**Notes:** All v0.4 phases possess robust assert scripts in `scripts/`. Reconciling VALIDATION.md tables and frontmatter achieves 100% Nyquist compliance.

---

## Manual Verification Classification

| Option | Description | Selected |
|--------|-------------|----------|
| Document as non-blocking manual verification | Record in VALIDATION.md as manual verification steps (Sampling/Inspection) while keeping automated suite gates green | ✓ |
| Automate where possible | Add headless or non-interactive mock/check for desktop notification delivery and session state | |
| You decide | Preserve standard Nyquist manual verification classification | |

**User's choice:** Document as non-blocking manual verification.
**Notes:** Fresh-login startup apps (Chrome, kitty, btop, Discord, polkit) and live notification visual popups are documented as sampling/inspection tests.

---

## Single-Machine Testing Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Explicitly document scratch-XDG boundary | Record in 23-VALIDATION.md that bootstrap mechanisms are proven by phase23-bootstrap-assert.sh at scratch-XDG level, noting physical multi-machine testing as an accepted constraint | ✓ |
| Mark physical fresh-machine test as an open manual checklist item | Keep open item | |
| You decide | Follow Phase 23 ROADMAP verification risk guidance | |

**User's choice:** Explicitly document scratch-XDG boundary.
**Notes:** Aligns 23-VALIDATION.md with the explicit verification risk caveats in ROADMAP.md.

---

## Minor Debt Triage (.env & .gitignore)

| Option | Description | Selected |
|--------|-------------|----------|
| Keep tracked and formally document as non-credential | Affirm operator triage in STATE.md that stow/system_monitor/.../.env holds only local loopback daemon parameters | ✓ |
| Rename to .env.example | Untrack .env, commit .env.example, and update installer | |
| You decide | Choose whichever minimizes churn while satisfying security audits | |

**User's choice:** Keep tracked and formally document as non-credential.
**Notes:** Verified that `.env` contains only `BIND_HOST=127.0.0.1`, `PORT=8765`, `COLLECTION_INTERVAL=5`, `STALE_AFTER_SECONDS=15`.

---

## Gitignore Rule Scoping

| Option | Description | Selected |
|--------|-------------|----------|
| Refine .gitignore pattern now | Scope the socket ignore pattern (or add exception for stow/systemd/...) so valid systemd units are not accidentally ignored | ✓ |
| Keep deferred | Leave as accepted risk until a milestone introduces systemd socket activation units | |
| You decide | Apply standard gitignore scoping conventions | |

**User's choice:** Refine `.gitignore` pattern now.
**Notes:** Resolves deferred item D-7 from audit.

---

## Session Keybindings & Cheatsheet Realignment

| Option | Description | Selected |
|--------|-------------|----------|
| Full sleep/logout realignment with upstream unbind | Unbind SUPER + SHIFT + L, map SUPER + Scroll_Lock to suspend (Session: Sleep), and map SUPER + SHIFT + Scroll_Lock to logout (Session: Logout) | ✓ |
| Keep SUPER + SHIFT + L active alongside SUPER + Scroll_Lock | Alternate chord | |
| You decide | Ensure clean session keybind ergonomics without chord collisions | |

**User's choice:** Full sleep/logout realignment with upstream unbind.
**Notes:** User explicitly instructed: *"Make sure keybinding cheatsheet SUPER + / - the list that shows here is completely upto date. keybind sleep needs to be SUPER + Scroll_lock and logout needs to be SUPER + SHIFT + Scroll_lock"*. Unbinding `SUPER + SHIFT + L` ensures no obsolete sleep chord appears in Quickshell's cheatsheet.

---

## Cheatsheet Taxonomy & Live Reload

| Option | Description | Selected |
|--------|-------------|----------|
| Audit and validate all binds against cheatsheet parser | Verify that every personal keybind has a valid 'Category: Label' description, passes luac syntax validation, and registers in hyprctl binds -j without duplicate chords | ✓ |
| Update sleep and logout binds only | Touch only session binds in keybinds.lua | |
| You decide | Ensure cheatsheet display is clean and exhaustive | |

**User's choice:** Audit and validate all binds against cheatsheet parser.
**Notes:** Verified that Quickshell's cheatsheet service groups binds by the category string preceding the first colon in `description`.

---

## Phase 24 Assert Script & Exit Gates

| Option | Description | Selected |
|--------|-------------|----------|
| Author dedicated assert script | Create scripts/phase24-tech-debt-assert.sh asserting all bookkeeping, Nyquist frontmatter, gitignore scoping, and keybind changes | ✓ |
| Verification checklist only | Rely on manual VERIFICATION.md inspection | |
| You decide | Maintain standard phase test harness pattern | |

**User's choice:** Author dedicated assert script.
**Notes:** Creates `scripts/phase24-tech-debt-assert.sh` following repository standards.

---

## Milestone Audit Re-Run

| Option | Description | Selected |
|--------|-------------|----------|
| Require clean milestone audit | Re-run milestone audit at end of Phase 24 and assert that status transitions to clean/passed before /gsd-complete-milestone | ✓ |
| Assert script only | Consider Phase 24 complete once assert script and verify --strict pass | |
| You decide | Ensure readiness for milestone completion | |

**User's choice:** Require clean milestone audit.
**Notes:** Guarantees that milestone v0.4 can be completed and archived cleanly without lingering debt.

---

## Claude's Discretion

- Exact implementation helper functions inside `scripts/phase24-tech-debt-assert.sh`.
- Formatting adjustments in `VALIDATION.md` tables to cleanly present verification commands and evidence.
- Minor wording refinements in REQUIREMENTS.md requirement descriptions.

---

## Deferred Ideas

- Full physical fresh-machine bootstrap reproduction remains deferred until secondary hardware is available (scratch-XDG testing provides complete mechanical verification).
- Out-of-scope Ubuntu/Debian reader scripts referencing legacy `.config/` remain backlog items for a non-Arch platform milestone.
