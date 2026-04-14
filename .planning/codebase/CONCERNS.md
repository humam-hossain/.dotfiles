# Codebase Concerns

**Analysis Date:** 2026-04-14

## Tech Debt

**Plugin/UI coupling across files:**
- Issue: `.config/nvim/lua/plugins/lualine.lua` calls `require("noice").api...` but `noice.nvim` lives in separate `.config/nvim/lua/plugins/notify.lua`
- Why: convenient cross-plugin status composition
- Impact: if `noice` load timing or config breaks, lualine path can fail at runtime
- Fix approach: guard `require("noice")`, or make lualine component conditional on plugin availability

**Global autosave behavior in core keymaps:**
- Issue: multiple unconditional write hooks in `.config/nvim/lua/core/keymaps.lua` (`FocusLost`, `BufLeave`, `TextChanged`, `InsertLeave`)
- Why: optimize for always-saved editing
- Impact: unexpected writes, possible churn on generated/temp files, harder debugging of side effects
- Fix approach: centralize autosave policy with opt-out conditions per buffer/filetype

## Known Bugs

**`noice.nvim` lazy-load key likely misspelled:**
- Symptoms: plugin may ignore intended lazy event and load unexpectedly or not by event
- Trigger: `.config/nvim/lua/plugins/notify.lua` uses `even = "VeryLazy"` instead of `event`
- Workaround: plugin may still load due to dependency chain or direct require
- Root cause: typo in plugin spec field

**Catppuccin lockfile entry likely misspelled:**
- Symptoms: lockfile contains `"catppucin"` while plugin spec names `"catppuccin"`
- Trigger: plugin update/sync workflows relying on exact names
- Workaround: none guaranteed; depends on `lazy.nvim` normalization behavior
- Root cause: stale or mistyped lock entry in `.config/nvim/lazy-lock.json`

## Security Considerations

**Shell command launch from editor:**
- Risk: mappings run `xdg-open` on current file/node path from `.config/nvim/lua/core/keymaps.lua` and `.config/nvim/lua/plugins/neotree.lua`
- Current mitigation: limited to explicit user actions
- Recommendations: keep commands argument-array based as they are now, avoid shell-string interpolation, document Linux-only assumption

**Automatic writes on buffer events:**
- Risk: sensitive or temporary files may be written unintentionally
- Current mitigation: some checks for `vim.bo.buftype == ""`
- Recommendations: add filetype/path exclusions and disable autosave for special buffers by default

## Performance Bottlenecks

**Heavy startup/config path:**
- Problem: broad plugin set with several UI-heavy modules plus extensive startup comments/config
- Measurement: no numbers in repo
- Cause: many features enabled by default and some non-lazy components (`catppuccin`, core setup)
- Improvement path: profile with `:Lazy profile`; defer nonessential plugins

**TextChanged autosave loop:**
- Problem: writes after every edit burst with 1s defer
- Measurement: no numbers in repo
- Cause: `TextChanged` autocmd in `.config/nvim/lua/core/keymaps.lua`
- Improvement path: debounce more aggressively or scope to selected filetypes/projects

## Fragile Areas

**`.config/nvim/lua/plugins/lsp.lua`:**
- Why fragile: large mixed-responsibility file covering diagnostics, attach hooks, Mason install list, and server setup
- Common failures: adding wrong Mason package/server names, capability merge issues, plugin/API version drift
- Safe modification: change one concern at time, smoke-test with `:checkhealth`, verify filetype-specific attach
- Test coverage: none

**`.config/nvim/lua/plugins/neotree.lua`:**
- Why fragile: very large option table with nested mappings and dependency-specific behavior
- Common failures: typo in nested keys, conflicting mappings, preview/window-picker regressions
- Safe modification: prefer surgical edits, test file explorer interactions manually
- Test coverage: none

## Scaling Limits

**Machine portability:**
- Current capacity: tuned for one user's Linux desktop workflow
- Limit: portability drops on macOS/Windows or minimal terminal/font setups
- Symptoms at limit: broken open-file mappings, missing icons, missing binaries, degraded UX
- Scaling path: add platform guards and documented dependency checklist

## Dependencies at Risk

**External binaries via Mason/system packages:**
- Risk: config assumes many tools exist (`black`, `isort`, `clang-format`, `prettierd`, `latexindent`, LSP servers)
- Impact: formatting/LSP silently degrade or fail when binary missing
- Migration plan: document required toolchain, add startup health reminders

**Plugin API drift:**
- Risk: large configs for `neo-tree`, `blink.cmp`, `noice`, `ufo` depend on plugin-specific option schemas
- Impact: plugin updates can break config even when Lua syntax stays valid
- Migration plan: keep `lazy-lock.json` pinned, update incrementally, smoke-test after sync

## Missing Critical Features

**Automated validation:**
- Problem: no repeatable test or health-check script committed alongside config
- Current workaround: manual startup and feature smoke tests
- Blocks: safe refactors across keymaps/plugins
- Implementation complexity: low to medium

## Test Coverage Gaps

**Startup + plugin load path:**
- What's not tested: whether all plugin modules evaluate cleanly on current Neovim/plugins
- Risk: small typos can break startup
- Priority: High
- Difficulty to test: Low with headless smoke commands

**Cross-plugin assumptions:**
- What's not tested: lualine/noice coupling, conform on save, Mason install names, neo-tree custom commands
- Risk: regressions only appear interactively
- Priority: High
- Difficulty to test: Medium

---

*Concerns audit: 2026-04-14*
*Update as issues are fixed or new ones discovered*
