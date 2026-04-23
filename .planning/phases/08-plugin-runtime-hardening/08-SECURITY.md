---
phase: 08
slug: plugin-runtime-hardening
status: verified
threats_open: 0
asvs_level: 1
created: 2026-04-24
---

# Phase 08 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| repo config → plugin runtime | Untrusted plugin updates and stale config assumptions cross into startup behavior | Plugin config, lock entries |
| repo validator → health evidence | Incorrect probe lists can misclassify config health and hide or invent failures | Plugin load status, tool availability |
| Neovim events → repo autocmd callbacks | Untrusted buffer/runtime state crosses into autosave, format, and LSP attach code | Buffer type, buffer validity, client state |
| repo open helper → OS opener | External command selection and failures come from the host environment, not trusted repo code | OS error strings, file paths |
| automated validator → written inventory | Tool output must be interpreted before it becomes phase truth | Startup/health log output |
| human interactive verification → written checklist | Manual workflow results become the permanent regression contract for future phases | Workflow pass/fail evidence |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-08-01 | T | `plugins/lsp.lua` | mitigate | Added `pyright` to both `lsp_servers` and `mason_lsp_servers` together; basedpyright removed; both tables verified in sync. Commit 22b1223. | closed |
| T-08-02 | D | `registry.lua`, `misc.lua` | mitigate | Removed all 4 `window.move_*` globals from registry; vim-tmux-navigator is sole `<C-h/j/k/l>` owner confirmed via `:verbose nmap`. Commit 378125d. | closed |
| T-08-03 | I | `core/health.lua`, `scripts/nvim-validate.sh` | mitigate | Removed stale `neo-tree` probe from `PLUGIN_LIST` and `cmd_smoke`; health validator passes with 11/11 plugins loaded. Commit 378125d. | closed |
| T-08-04 | T | `.config/nvim/lazy-lock.json` | mitigate | BUG-016 traced to nvim-colorizer.lua; single entry removed from lazy-lock.json; no broad refresh; startup log clean. Commit 22b1223. | closed |
| T-08-05 | D | `core/keymaps.lua` | mitigate | FocusLost autosave now rejects special/unnamed/non-modifiable buffers via five explicit guards (buftype, modifiable, modified, bufname, filereadable). Commit d5d923d. | closed |
| T-08-06 | D | `plugins/conform.lua` | mitigate | Format-on-save exclusion list extended with `fugitive` and `git` filetypes; `acwrite` (commit messages) retained. Commit d5d923d. | closed |
| T-08-07 | I | `core/open.lua` | mitigate | Replaced `pcall(vim.ui.open, target)` with direct `local cmd, err = vim.ui.open(target)`; real OS error string surfaced via notify. Commit d5d923d. | closed |
| T-08-08 | D | `plugins/lsp.lua` | mitigate | LspAttach callback now triple-gated: valid client, `nvim_buf_is_valid()`, `buftype == ""`; highlight lifecycle preserved behind guards. Commit 0398c38. | closed |
| T-08-09 | R | `FAILURES.md` | mitigate | All bug status changes tied to concrete Phase 8 evidence (commit SHAs, validator output, `:verbose nmap` verbatim). Commit f09fe5e + e11da02. | closed |
| T-08-10 | I | validator logs vs docs | mitigate | BUG-019 (tmux env gap) and BUG-020 (Linux external-open) explicitly separated from config regressions in FAILURES.md with environment-gap classification. | closed |
| T-08-11 | D | interactive workflows | mitigate | Full D-15 workflow matrix (W-01 to W-16) executed; 13/15 pass; 2 open gaps (BUG-019, BUG-020) recorded with precise failure steps — not marked complete by automation alone. | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

No accepted risks.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-04-24 | 11 | 11 | 0 | gsd-security-auditor (automated review of phase artifacts) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-04-24
