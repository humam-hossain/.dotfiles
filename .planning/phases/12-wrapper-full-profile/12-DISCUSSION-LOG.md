# Phase 12: Wrapper full-profile - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-10
**Phase:** 12-Wrapper full-profile
**Areas discussed:** Opt-in CLI shape, Full-path confirmation gate, Process gate in wrapper, Post-install hooks under full

---

## Gray area selection

| Option | Description | Selected |
|--------|-------------|----------|
| Opt-in CLI shape | How operator invokes full | ✓ |
| Full-path confirmation gate | Gate strength and messaging | ✓ |
| Process gate in wrapper | INV/DISP checks vs pure capability | ✓ |
| Post-install hooks under full | PROTECT + hypr ii hooks behavior | ✓ |

**User's choice:** All four areas
**Notes:** Interactive discuss; no `--auto` / `--all`

---

## Opt-in CLI shape

### How should the operator opt into the full-install path?

| Option | Description | Selected |
|--------|-------------|----------|
| Wrapper flag --full | Meta-flag on install / install-files; strip before setup | ✓ |
| New subcommand install-full | Separate allowlisted subcommand | |
| Both flag + install-full alias | Dual entry points | |

**User's choice:** Wrapper flag --full (Recommended)

### Which install-family subcommands should accept the full profile?

| Option | Description | Selected |
|--------|-------------|----------|
| install + install-files only | Mirrors SAFE_DEFAULTS injection scope | ✓ |
| install only (not install-files alone) | Unified pipeline only | |
| All install* including install-deps | Broader full labeling | |

**User's choice:** install + install-files only (Recommended)

### When full is active, what argv should go to ./setup?

| Option | Description | Selected |
|--------|-------------|----------|
| Inject nothing from SAFE_DEFAULTS | Drop all three residual flags (D-05) | ✓ |
| Inject an explicit FULL_DEFAULTS set | Named array even if empty | |
| You decide | Claude discretion | |

**User's choice:** Inject nothing from SAFE_DEFAULTS (Recommended)

### Should usage/help still mention raw vendor ./setup for full hypr?

| Option | Description | Selected |
|--------|-------------|----------|
| Remove that note; document wrapper full path | Primary path becomes --full | ✓ |
| Keep vendor escape hatch as advanced note | Still document raw setup | |
| You decide | Claude discretion | |

**User's choice:** Remove that note; document wrapper full path (Recommended)

**Notes:** Area complete — user chose Next area (no further CLI questions).

---

## Full-path confirmation gate

### How strong should the interactive confirmation be for --full paths?

| Option | Description | Selected |
|--------|-------------|----------|
| Same type-yes gate, full-specific messaging | Reuse backup_gate pattern | ✓ |
| Stronger phrase (type FULL) | Higher friction | |
| Two-step: yes then FULL | Maximum friction | |

**User's choice:** Same type-yes gate, full-specific messaging (Recommended)

### What must the full-path gate messaging cover?

| Option | Description | Selected |
|--------|-------------|----------|
| Blast radius + backup dir + no SAFE_DEFAULTS | conf .old, misc, Syu, backup, skip-backup refuse | ✓ |
| Also cite INV/DISP artifact paths | Gate text points at planning SoT | |
| Minimal: backup only | Short like safe gate | |

**User's choice:** Blast radius + backup dir + no SAFE_DEFAULTS (Recommended)

### Does --dry-run with --full still hit the interactive gate?

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, gate then print argv | Matches safe install --dry-run | ✓ |
| Skip gate on --dry-run | Easier scripting | |
| You decide | Claude discretion | |

**User's choice:** Yes, gate then print argv (Recommended)

### Should bare --skip-backup policy change on full path?

| Option | Description | Selected |
|--------|-------------|----------|
| Same refuse without --allow-skip-backup | FULL-03 shared policy | ✓ |
| Harder: never allow skip on full | Even allow override refused | |
| You decide | Claude discretion | |

**User's choice:** Same refuse without --allow-skip-backup (Recommended)

**Notes:** Area complete — user chose Next area.

---

## Process gate in wrapper

### Should the wrapper enforce INV/DISP process gates before allowing --full?

| Option | Description | Selected |
|--------|-------------|----------|
| Pure capability — no artifact checks | ADOPT-01 stays Phase 14 | ✓ |
| Soft warn if artifacts missing | Warn and continue | |
| Hard refuse without dispositions | Exit if 11-DISPOSITIONS missing | |

**User's choice:** Pure capability — no artifact checks (Recommended)

### If soft/hard gate exists, what counts as 'satisfied'?

| Option | Description | Selected |
|--------|-------------|----------|
| N/A — pure capability | Moot under pure capability | ✓ |
| Files exist only | Presence check | |
| Files exist + status Complete header | Status marker required | |

**User's choice:** N/A — pure capability (Recommended)

### Should --full refuse if SAFE_DEFAULTS would still be the safer choice for this machine?

| Option | Description | Selected |
|--------|-------------|----------|
| No runtime policy engine | No host/disposition reinterpretation | ✓ |
| Warn if dual-run chrome still exec-once | Soft host scan | |
| You decide | Claude discretion | |

**User's choice:** No runtime policy engine (Recommended)

### Where should the operator learn the full sequence (inventory→disp→full→overlays→adopt)?

| Option | Description | Selected |
|--------|-------------|----------|
| Wrapper help points at playbook + phase artifacts | Discoverable pointers; Phase 15 polish | ✓ |
| Wrapper help is CLI-only; sequence is docs-only | No planning paths in arch script | |
| You decide | Claude discretion | |

**User's choice:** Wrapper help points at playbook + phase artifacts (Recommended)

**Notes:** Area complete — user chose Next area.

---

## Post-install hooks under full

### After --full install/install-files, should PROTECT re-mark still run?

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — always (FULL-05) | Same PROTECT_EXPLICIT list | ✓ |
| Yes, but expand protect list for full | Scope creep risk | |
| You decide | Claude discretion | |

**User's choice:** Yes — always (Recommended / FULL-05)

### What about enable_hypr_ii_hooks on --full?

| Option | Description | Selected |
|--------|-------------|----------|
| Keep same hooks enable | Phase 12 parity with safe path | ✓ |
| Skip hooks on --full | Assume lua/ii tree owns session | |
| Defer hook policy entirely to Phase 14 | Document possible later change | |

**User's choice:** Keep same hooks enable (Recommended for Phase 12)

### On --full dry-run, what post-setup plan should be printed?

| Option | Description | Selected |
|--------|-------------|----------|
| Mirror real path: protect + hooks | Same structure as safe dry-run | ✓ |
| Protect only; note hooks TBD | Partial plan | |
| You decide | Claude discretion | |

**User's choice:** Mirror real path: protect + hooks (Recommended)

### Any other post-full wrapper side effects in Phase 12?

| Option | Description | Selected |
|--------|-------------|----------|
| None beyond protect + existing hooks | Thin Phase 12 boundary | ✓ |
| Also stop dual-run chrome processes | Scope creep → Phase 14 | |
| You decide | Claude discretion | |

**User's choice:** None beyond protect + existing hooks (Recommended)

**Notes:** Area complete — user chose Next / done with this area.

---

## Final satisfaction

| Option | Description | Selected |
|--------|-------------|----------|
| I'm ready for context | Write CONTEXT.md and finish workflow | ✓ |
| Explore more gray areas | Additional ambiguities first | |

**User's choice:** I'm ready for context

---

## Claude's Discretion

No "You decide" selections on the four decision questions. Discretion items recorded in CONTEXT.md cover help wording, gate function structure, flag parse order, and dry-run test harness shape only.

---

## Deferred Ideas

- Phase 13: hypr/custom overlays for must-keeps
- Phase 14: pre-flight sync, live full adopt, ADOPT-01 process gate, chrome stop timing, possible hook-target revisit after lua entry
- Phase 15: playbook safe vs full polish
- Rejected for this phase: install-full subcommand; hard never-allow skip-backup on full; PROTECT list expansion; chrome teardown; planning-artifact hard checks in wrapper
