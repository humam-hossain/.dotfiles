---
phase: "07"
slug: keymap-reliability-fixes
status: verified
threats_open: 0
asvs_level: 1
created: 2026-04-24
---

# Phase 07 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| registry data ↔ runtime key execution | Invalid action shapes turn into user-facing runtime errors on keypress | Lua callback shapes (function refs vs. strings) |
| helper scope token ↔ contextual mapping install | Wrong scope token silently drops registry-owned contextual mappings | Scope token string (plugin-local vs. plugin_local) |
| interactive verification ↔ planning artifact | BUG-01 closure depends on real keypress evidence, not only static inspection | Human keypress results recorded as doc evidence |
| living bug docs ↔ future phases | Incorrect status/docs would mislead later validation and milestone verification | FAILURES.md / CHECKLIST.md status fields |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-07-01 | Tampering | `registry.lua` action replacements | mitigate | Exact callback bodies from Phase 6 checklist used; verified by grep + startup/smoke harness (exits 0) | closed |
| T-07-02 | Denial of Service | broken shared keymaps | mitigate | All 11 eager/shared mappings moved from `M.lazy` to `M.global` with explicit Lua callback actions; all 9 target keymaps passed interactive re-verification (2026-04-22) | closed |
| T-07-03 | Tampering | `attach.lua` scope normalization (Plan 01) | mitigate | Scope token changed from `"plugin_local"` (underscore) to `"plugin-local"` (hyphen); headless helper-path check returned `plugin-local count: 4`; startup validation exits 0 | closed |
| T-07-04 | Repudiation | manual keymap verification (Plan 02) | mitigate | All 9 BUG-01 mappings re-run interactively post Plan 7-01; human verification table in 07-02-SUMMARY.md (all PASS, no Lua/E488 errors) | closed |
| T-07-05 | Tampering | `FAILURES.md` / `CHECKLIST.md` status edits | mitigate | Edits restricted to BUG-005 to BUG-012 and BUG-015 only; BUG-017 (deferred) and all By-Design/Not-a-Bug entries left untouched | closed |
| T-07-06 | Information Integrity | README patching | mitigate | README assessed post Plan 7-01; `plugin-local` hyphen form already correct; no edit made (no user-visible wording drift existed) | closed |

*Note: Plan 02 threat register used T-07-03 as ID — renumbered T-07-04/T-07-05/T-07-06 here to avoid collision with Plan 01's T-07-03 (attach.lua).*

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

No accepted risks.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-04-24 | 6 | 6 | 0 | gsd-secure-phase (static analysis from artifacts) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-04-24
