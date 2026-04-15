# Retrospective

## Milestone: v1.0 — Neovim Modernization

**Shipped:** 2026-04-15
**Phases:** 5 | **Plans:** 15

### What Was Built

- Cross-platform OS-aware open helper via `vim.ui.open()` — no more hardcoded Linux commands
- Buffer-first lifecycle: confirm-on-close, conservative FocusLost autosave
- Central keymap registry with domain taxonomy — all plugins now consume registry keys
- Full plugin audit: keep/remove/replace decisions, lockfile refresh, 3 plugins dropped
- Headless validation harness (`nvim-validate.sh` + `core/health.lua`) for CI-style checks
- Neovim 0.11-native LSP migration; format-on-save with filetype safety policy
- snacks.nvim consolidation (replaced 5 plugins); polished statusline and catppuccin theme
- Rollout documentation: machine checklist, phase summary, verification steps, rollback guide

### What Worked

- Sequential phase ordering was correct — reliability first, then keymaps, then audit/harness, then tooling, then polish
- Aggressive plugin replacement (allow-all-cleanup stance) prevented scope creep and hesitation
- Headless validation harness adds long-term value beyond this milestone — good invest vs cost
- snacks.nvim consolidation was smooth; single well-maintained plugin beats 5 separate ones
- Format-on-save safety policy (filetype exclusion list) was the right design — no noise

### What Was Inefficient

- REQUIREMENTS.md traceability table was never updated during execution — all 18 rows stayed "Pending" until milestone completion; traceability was only recoverable from SUMMARY.md evidence
- STATE.md "stopped_at" field was stale (showed "Phase 5 context gathered" even at 100% completion)
- Phase 3 summaries (03-01 and 03-03) were sparse — key decisions not extracted cleanly by CLI

### Patterns Established

- `vim.ui.open()` as the canonical cross-platform open primitive — use it everywhere
- Central keymap registry pattern: one file per keymap domain, plugins declare no raw `vim.keymap.set` calls
- Headless validation via `nvim --headless` with repo rtp override — portable and repo-owned
- snacks.nvim as the UX consolidation hub for dashboard, indent, input, notifier, scope

### Key Lessons

- Update traceability table as requirements complete — don't leave it for milestone close
- Keep STATE.md "stopped_at" current through execution, not just context sessions
- Summary files need a one-liner field populated for clean CLI extraction — add it to SUMMARY.md template usage going forward

### Cost Observations

- Model mix: balanced profile (sonnet for execution)
- Sessions: ~1 day execution (2026-04-14 init, 2026-04-15 completion)
- Notable: high velocity — 15 plans in under 24 hours, mostly due to well-scoped phases with clear success criteria

---

## Cross-Milestone Trends

| Metric | v1.0 |
|--------|------|
| Phases | 5 |
| Plans | 15 |
| Timeline | 1 day |
| Traceability gaps | 18 requirements never updated during exec |
| Key pattern | Central registry + headless harness |
