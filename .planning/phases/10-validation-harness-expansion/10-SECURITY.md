---
phase: 10
slug: validation-harness-expansion
status: verified
threats_open: 0
asvs_level: 1
created: 2026-04-24
---

# Phase 10 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| maintainer → README contract | Incorrect docs would cause maintainers to run the wrong rollout gate | human-readable text; no PII |
| shell harness → Lua guard target | Misstating the guard contract would make the regression probe validate the wrong behavior | Lua return values; no PII |
| maintainer → rollout decision | README guidance shapes whether a failing signal blocks rollout or is documented as environmental | human-readable text; no PII |
| validation artifacts → human interpretation | Poor documentation can cause operators to misclassify config regressions as harmless warnings | log file content; no PII |
| checkhealth output → warning classification | Misclassifying warnings could hide a real config defect or waste work on environment-only noise | diagnostic text; no PII |
| which-key registration → maintainer diagnostics | Duplicate-prefix warnings can obscure real issues if repo-generated noise is left untriaged | keymap strings; no PII |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-10-01 | Tampering | `.config/nvim/README.md` | mitigate | Phase 10 command names and artifact filenames copied verbatim from plan D-02/D-04; verified by SUMMARY-01 commit 288fa10 and UAT test 4 | closed |
| T-10-02 | Info Disclosure | `.config/nvim/lua/plugins/conform.lua` | mitigate | Change limited to banner removal only; `format_on_save` guard signature and return table preserved; UAT test 3 confirmed correct guard behavior | closed |
| T-10-03 | Tampering | `scripts/nvim-validate.sh` | mitigate | Existing temp-Lua and PASS/FAIL logging pattern reused for `keymaps` and `formats` subcommands; non-zero exit on regression; confirmed by SUMMARY-02 | closed |
| T-10-04 | Repudiation | `.planning/tmp/nvim-validate/*.log` | mitigate | One PASS/FAIL line per concrete probe case; subcommand fails if any expected result is wrong; UAT tests 2 & 3 confirmed log contents | closed |
| T-10-05 | Info Disclosure | `.config/nvim/README.md` | mitigate | All 7 artifact files enumerated by exact filename, paired with producing subcommand and first-response rule; SUMMARY-03 rg verification confirmed | closed |
| T-10-06 | Repudiation | README triage path | mitigate | Phase 9 categories (`config regression` / `environment gap` / `optional tool gap`) reused verbatim; no second TRIAGE.md surface; SUMMARY-03 rg verified | closed |
| T-10-07 | Info Disclosure | `.planning/phases/06-runtime-failure-inventory/FAILURES.md` | mitigate | `./scripts/nvim-validate.sh checkhealth` re-run fresh per D-14; 20+ warning families classified in FAILURES.md; commit 160d0f0 | closed |
| T-10-08 | Tampering | `repo-owned config files (whichkey.lua)` | mitigate | Config-caused which-key duplicate-prefix warnings for `<leader>e` and `<leader>b` fixed via claimed-lhs guard; all other warnings classified By Design/Won't Fix; commit ad62b87 | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

No accepted risks.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-04-24 | 8 | 8 | 0 | gsd-security-auditor (inline) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-04-24
