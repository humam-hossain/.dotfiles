# Phase 30: Address tech debt: v0.5 cleanup and validation sign-off - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-18
**Phase:** 30-address-tech-debt-v0-5-cleanup-and-validation-sign-off
**Areas discussed:** Kitty Opacity & Visual Polish, Environment & Signal Robustness, Nyquist Validation & Test Harness, Traceability & Bookkeeping Structure

---

## Kitty Opacity & Visual Polish

| Option | Description | Selected |
|--------|-------------|----------|
| Update kitty.conf to 0.90 and update phase28 assert to expect 0.90 | Aligns config and test harness cleanly | ✓ |
| Update kitty.conf to 0.90 and make phase28 assert accept either 0.85 or 0.90 | Tolerates minor opacity variance | |
| You decide | Pick the cleanest convention for the codebase | |

**User's choice:** Update kitty.conf to 0.90 and update phase28 assert to expect 0.90 — aligns config and test harness cleanly  
**Notes:** Fulfills deferred UAT preference recorded in `28-UAT.md`. Confined strictly to Kitty background opacity. Live running Kitty instances signaled via `killall -SIGUSR1 kitty 2>/dev/null || true`.

---

## Environment & Signal Robustness

| Option | Description | Selected |
|--------|-------------|----------|
| Export fallback in bootstrap.sh ($XDG_STATE_HOME/quickshell/.venv) before running switchwall, and add fallback parameter expansion where sourced | Provides virtualenv fallback across all non-graphical runs | ✓ |
| Export ILLOGICAL_IMPULSE_VIRTUAL_ENV system-wide so all subshells have it outside Hyprland | Modifies shell profiles | |
| You decide | Whichever approach prevents TTY/SSH bootstrap failure with least friction | |

**User's choice:** Export fallback in bootstrap.sh ($XDG_STATE_HOME/quickshell/.venv) before running switchwall, and add fallback parameter expansion where sourced  
**Notes:** In `applycolor.sh`, replace divergent `pgrep -f kitty` / `kill -SIGUSR1 $(pidof kitty)` with `killall -SIGUSR1 kitty 2>/dev/null || true`. Apply fixes live and add idempotent alignment in `bootstrap.sh`.

---

## Nyquist Validation & Test Harness

| Option | Description | Selected |
|--------|-------------|----------|
| Reconcile 29-VALIDATION.md frontmatter and mark tasks green based on passing assert suite | Closes Phase 29 validation sign-off cleanly | ✓ |
| Run formal validation audit tool on phase 29 to generate updated artifact | Generates new audit file | |
| You decide | Ensure 29-VALIDATION.md satisfies Nyquist compliance cleanly | |

| Option | Description | Selected |
|--------|-------------|----------|
| Create scripts/phase30-tech-debt-assert.sh with 5 sections including full v0.5 regression sweep (Phases 25–29) | Proves complete regression safety for v0.5 milestone | ✓ |
| Rely on updating phase28 and phase29 assert scripts without a new phase30 assert script | Skips dedicated harness | |
| You decide | Balance thoroughness with execution time | |

**User's choice:** Reconcile 29-VALIDATION.md frontmatter and author dedicated scripts/phase30-tech-debt-assert.sh with 5-section full v0.5 regression sweep  
**Notes:** Author `30-VALIDATION.md` establishing Wave 0 harness mapping and `nyquist_compliant: true`.

---

## Traceability & Bookkeeping Structure

| Option | Description | Selected |
|--------|-------------|----------|
| Use DEBT-05 through DEBT-08 | Directly continues established technical debt taxonomy from Phase 24 | ✓ |
| Use CLEAN-01 through CLEAN-04 | Introduces milestone-specific cleanup prefix | |
| You decide | Pick whichever maintains clean traceability in REQUIREMENTS.md | |

| Option | Description | Selected |
|--------|-------------|----------|
| 2 plans: Plan 30-01 (Kitty opacity & script robustness) + Plan 30-02 (validation sign-off, phase30 harness, regression sweep) | Focused, logical separation of concerns | ✓ |
| 1 single consolidated plan | Combines all items in one run | |
| 3 plans | Granular separation | |

**User's choice:** Use DEBT-05 through DEBT-08 in REQUIREMENTS.md and structure Phase 30 into 2 plans  
**Notes:** Phase exit gate strictly mandates `scripts/phase30-tech-debt-assert.sh` passing all 5 sections, `arch/dots-hyprland.sh verify --strict` returning 0 findings, and byte-identical clean git status.

---

## the agent's Discretion

- Specific helper function names and formatting inside `scripts/phase30-tech-debt-assert.sh`.
- Minor sed pattern optimization for template alignment in `bootstrap.sh`.

## Deferred Ideas

None — discussion stayed strictly within the technical debt and validation sign-off scope cataloged in `.planning/v0.5-MILESTONE-AUDIT.md`.
