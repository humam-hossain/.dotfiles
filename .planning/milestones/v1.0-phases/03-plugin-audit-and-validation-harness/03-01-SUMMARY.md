# Plan 03-01 Summary

**Plan:** 03-01 — Plugin Inventory and Audit Rules
**Phase:** 03-plugin-audit-and-validation-harness
**Executed:** 2026-04-15
**Status:** Complete

## Outputs

| File | Description |
|------|-------------|
| `03-AUDIT-RULES.md` | Aggressive decision framework (keep/remove/replace) with 7 removal criteria |
| `03-PLUGIN-AUDIT.md` | Full plugin ledger: 49 effective plugin declarations + 16 lockfile orphans |

## Decision Counts

| Decision | Count |
|----------|-------|
| keep | 33 |
| remove | 15 |
| replace | 1 |
| **Total rows** | **49** |

## Handoffs to Plan 03-03

1. **Duplicate vim-fugitive removal**: Delete `tpope/vim-fugitive` from `lua/plugins/misc.lua`; keep declaration in `lua/plugins/git.lua`.
2. **catppucin lockfile fix**: Remove misspelled `catppucin` key from `lazy-lock.json`; regenerate correct `catppuccin` pin.
3. **noice.nvim `even=` typo fix**: Correct `even = "VeryLazy"` to `event = "VeryLazy"` in `lua/plugins/notify.lua`.
4. **hackerman.nvim removal**: Delete both `hackerman.nvim` and its dep `aether.nvim` from `lua/plugins/colortheme.lua`.
5. **Telescope orphan lockfile entries**: Prune `telescope.nvim`, `telescope-fzf-native.nvim`, `telescope-ui-select.nvim` from `lazy-lock.json`.
6. **none-ls.nvim orphan removal**: Prune `none-ls.nvim` from `lazy-lock.json`.
7. **lazydev.nvim orphan removal**: Prune `lazydev.nvim` from `lazy-lock.json`.
8. **LuaSnip conditional verification**: Run `Lazy! sync` and verify LuaSnip resolves correctly as transitive dep of friendly-snippets.

## Borderline Decisions (Phase 4 Review)

These plugins were kept but sit near the removal boundary. Phase 4 reviewers should evaluate carefully:

- **nvim-colorizer.lua**: Older plugin, "complete not abandoned". Most editors have color preview natively. Phase 4 should verify if removal breaks anything before deleting.
- **comfy-line-numbers.nvim**: Novelty-adjacent; column labeling for line numbers. Phase 4 should confirm active usage before finalizing keep decision.
- **tpope/vim-rhubarb**: GitHub-specific integration; niche value. Phase 4 should assess whether GitHub integration is critical for daily workflow or nice-to-have.
- **vim-tpipeline**: tmux-specific; no value outside tmux. Phase 4 should document tmux as required dep and evaluate Windows/WSL parity.
- **3rd/image.nvim**: Optional neo-tree dep; image preview. Phase 4 should evaluate whether image support in file tree is essential.
- **MeanderingProgrammer/render-markdown.nvim**: Specific markdown rendering. Phase 4 should confirm this replaces any built-in Neovim capabilities or is genuinely additive.

## Audit Method Notes

- All 17 domain subsections from the plan were created.
- Every row in every table has an explicit Decision column value (`keep`, `remove`, or `replace`) — no `TBD`, `???`, or placeholder text.
- Rationale cells reference specific rules from `03-AUDIT-RULES.md` (e.g., "novelty-only value", "lockfile-only orphan", "duplicate declaration", "required dependency", "active development").
- Transitive deps (friendly-snippets, blink-emoji, vim-bbye, nui, nvim-notify, plenary, nvim-web-devicons, nvim-window-picker, promise-async) are included with decision `keep` per the required-dependency rule.
- The `noice.nvim` typo `even = "VeryLazy"` is recorded verbatim so Plan 03-03 can grep for it.
- The `catppucin` lockfile mismatch is recorded verbatim for Plan 03-03 lockfile repair.

## Verification

- `03-AUDIT-RULES.md` contains all 8 required sections and D-01/D-02/D-03 references.
- `03-PLUGIN-AUDIT.md` contains all 17 domain subsections, duplicate resolution, lockfile drift, and decision summary.
- Decision row count: 49 (above 30 minimum threshold).
- All known drift items (duplicate fugitive, catppucin mismatch, noice typo, hackerman dormancy) are recorded with explicit decisions.
