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

## Milestone: v1.1 — Neovim Setup Bug Fixes

**Shipped:** 2026-04-25
**Phases:** 6 | **Plans:** 15

### What Was Built

- Ranked failure inventory (20+ bugs) via `nvim-audit-failures.sh` + `FAILURES.md` with repro steps
- All 10 BUG-01 shared keymaps fixed — M.global/M.lazy split corrected, safe lazy.lua dispatcher, Gitsigns direct Lua callbacks
- Plugin misconfigs removed: neo-tree globals cleared, pyright added to mason/lsp, `vim.tbl_flatten` deprecation eliminated
- External-open rebound from `<C-S-o>` (undeliverable in terminal) to `<leader>o` — root cause proven, not assumed
- `:checkhealth config` provider with 6 sections and required/optional severity classification
- `nvim-validate.sh` expanded with `keymaps` and `formats` regression subcommands (7 total)
- README Machine Update Checklist and Post-Deploy Verification table refreshed for rollout

### What Worked

- Failure inventory first (Phase 6) — having a ranked list with root causes made every downstream phase faster and more targeted
- `:checkhealth` as primary diagnostic before scripting — avoided building redundant validation surfaces
- Atomic commit-per-finding discipline in Phase 11 — easy to bisect and verify each fix independently
- Verification-driven planning — each phase had clear VERIFICATION.md criteria before execution started

### What Was Inefficient

- SUMMARY.md `one_liner` field not populated in most phases — CLI extraction produced garbage output, accomplishments had to be manually recovered
- Phase 8 SUMMARY frontmatter missing `requirements-completed` entries for BUG-02/BUG-03 — audit found gap, purely documentation debt
- `gsd-tools audit-open` CLI has a bug (ReferenceError: output is not defined) — had to check for open artifacts manually at milestone close

### Patterns Established

- Failure inventory phase as standard milestone opener for bug-fix cycles — gives ranked work queue before any coding
- `:checkhealth` health provider pattern: `lua/config/health.lua` with `required`/`optional` severity tiers
- `nvim-validate.sh` subcommand pattern: each logical check is a standalone `cmd_*` function, composed by `cmd_all`
- which-key guard pattern: build claimed-lhs set before registering group specs to prevent duplicate-prefix warnings

### Key Lessons

- Populate SUMMARY.md `one_liner` field — CLI tooling depends on it; blank fields cause milestone close friction
- Check `gsd-tools` CLI health before starting milestone close — audit-open bug would have blocked a less manual workflow
- Tech debt items from audit (`attach.lua` dead code, README table gaps) are fine to defer — document them in audit and move on

### Cost Observations

- Model mix: balanced profile (sonnet for execution, opus for planning/research agents)
- Sessions: ~7 days (2026-04-17 to 2026-04-25)
- Notable: 159 commits, 6 phases — lower velocity than v1.0 due to brownfield nature and interactive verification requirements

---

## Cross-Milestone Trends

| Metric | v1.0 | v1.1 |
|--------|------|------|
| Phases | 5 | 6 |
| Plans | 15 | 15 |
| Timeline | 1 day | 7 days |
| Traceability gaps | 18 requirements never updated during exec | SUMMARY one_liner field unpopulated in most phases |
| Key pattern | Central registry + headless harness | Failure inventory first; `:checkhealth` as primary diagnostic |
| Tech debt at close | None noted | 13 items, all non-blocking (dead code, cosmetics, Windows verification) |
