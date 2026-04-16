# Phase 6: Add Missing VERIFICATION.md Files - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-16
**Phase:** 06-verify
**Areas discussed:** VERIFICATION format, Evidence standards, Gap handling, Phase 4 dual docs, Verification scope, File location, Review/approval, FAIL documentation, Escalation path

---

## VERIFICATION format

| Option | Description | Selected |
|--------|-------------|----------|
| Mirror Phase 3 exactly | Same sections: Requirements Verification, Success Criteria, Files Delivered, Key Decisions Traced, Summary table | |
| Adapt per phase | Tailor sections based on what matters for each phase | ✓ |
| You decide | Let executor determine appropriate format | |

**User's choice:** Adapt per phase
**Notes:** Phase 3 serves as reference template, not strict template

---

## Evidence standards

| Option | Description | Selected |
|--------|-------------|----------|
| Code + test runs | Source code presence AND functional verification (nvim-validate.sh, smoke tests) | |
| Code only | Source code presence sufficient — work was already accepted | |
| Manual review | Executor reviews code and attests to requirement satisfaction | ✓ |
| You decide | Let executor determine appropriate evidence | |

**User's choice:** Manual review
**Notes:** Executor reviews source code and attests to requirement satisfaction

---

## Gap handling

| Option | Description | Selected |
|--------|-------------|----------|
| Document as FAIL | Mark unsatisfied, log evidence why, recommend remediation | |
| Investigate first | Dig into code before marking — may already be satisfied | ✓ |
| Escalate | Flag for Phase 7/8 keymap/UX validation to handle | |
| You decide | Let executor handle as appropriate | |

**User's choice:** Investigate first
**Notes:** Before marking FAIL, dig into actual code to confirm whether requirement is met

---

## Phase 4 dual docs

| Option | Description | Selected |
|--------|-------------|----------|
| Phase 6 does both | Create both VERIFICATION.md and VALIDATION.md for Phase 4 in this phase | |
| Phase 6 + 7 split | Phase 6 creates VERIFICATION.md, Phase 7/8 keymap/UX validation creates VALIDATION.md | ✓ |
| Phase 6 VERIFICATION only | Phase 4 VALIDATION.md deferred to Phase 8 UX validation | |

**User's choice:** Phase 6 + 7 split
**Notes:** Phase 7 handles keymap gaps, Phase 8 handles UX gaps

---

## Verification scope

| Option | Description | Selected |
|--------|-------------|----------|
| All 18 requirements | Complete audit: all v1.0 requirements get verification status | ✓ |
| Gap subset only | Only the 4-5 mentioned in roadmap audit (KEY-01/02/03, PLUG-02, TOOL-02) | |
| Audit-identified only | Only phases with missing verification per audit (1, 2, 4, 5) | |

**User's choice:** All 18 requirements
**Notes:** Complete audit — every requirement gets verification status

---

## File location

| Option | Description | Selected |
|--------|-------------|----------|
| Archived milestone dirs | Write to .planning/milestones/v1.0-phases/0X-*/ directories | ✓ |
| Current phase folder | Write to .planning/phases/06-verify/ with phase references | |
| Both locations | Symlink or copy to both for accessibility | |

**User's choice:** Archived milestone dirs
**Notes:** Consistent with existing Phase 3 VERIFICATION.md location

---

## Review/approval

| Option | Description | Selected |
|--------|-------------|----------|
| Self-review only | Executor reviews code, documents, commits — no additional approval | |
| Health check required | Must run nvim-validate.sh and pass before marking PASS | ✓ |
| User review | Executor creates draft, user reviews before commit | |

**User's choice:** Health check required
**Notes:** Must run nvim-validate.sh and pass before marking any requirement as PASS

---

## FAIL documentation

| Option | Description | Selected |
|--------|-------------|----------|
| Status + evidence + remediation | Mark FAIL, cite evidence why, recommend remediation path | |
| Link to gap phase | Mark as deferred to Phase 7/8, link to the gap-closure phase | |
| You decide | Let executor determine appropriate FAIL format | ✓ |

**User's choice:** You decide
**Notes:** Executor discretion — Status, evidence why unsatisfied, remediation recommendation at minimum

---

## Escalation path

| Option | Description | Selected |
|--------|-------------|----------|
| Auto-link to 07/08 | Document gap, auto-create issue/todo linking to relevant Phase 7/8 task | |
| Flag in SUMMARY | Mark unsatisfied in VERIFICATION.md, Phase 7/8 responsible for resolution | |
| Block Phase 6 | Gap found = Phase 6 incomplete until resolved | |
| You decide | Let executor determine escalation approach | ✓ |

**User's choice:** You decide
**Notes:** How gaps route to Phase 7/8 determined by executor based on gap type

---

## Claude's Discretion

- FAIL documentation format
- Escalation approach for discovered gaps
- Phase 4 VALIDATION.md split between Phase 7 and Phase 8

## Deferred Ideas

None — discussion stayed within phase scope.
