# Phase 5: UX and Performance Polish - Context

**Gathered:** 2026-04-15
**Status:** Ready for planning

<domain>
## Phase Boundary

Finish the config with coherent UI behavior, startup efficiency wins, and clear rollout guidance. This phase completes the refactor: profile and trim startup waste, migrate the notification/dashboard/search stack to snacks.nvim, tune the statusline for tmux and non-tmux use, and document the full rollout workflow.

</domain>

<decisions>
## Implementation Decisions

### Startup profiling scope
- **D-01:** 05-01 should take an aggressive removal pass — treat profiling as another audit round, not documentation only.
- **D-02:** Target startup time: under 100ms. Profile with `:Lazy profile`, defer non-essential UI plugins, remove plugins that don't justify their startup cost.
- **D-03:** Non-essential plugins that are candidates for deferral or removal: `alpha.nvim` (replaced by snacks.dashboard), `indent-blankline` (replaced by snacks.indent), `nvim-notify` (replaced by snacks.notif), `noice.nvim` (replaced by snacks), `fzf-lua` (replaced by snacks.picker).

### snacks.nvim migration (replaces multiple plugins)
- **D-04:** Replace `noice.nvim` + `nvim-notify` with `snacks.notif`. Bottom-right toast-style notifications.
- **D-05:** Replace `alpha.nvim` with `snacks.dashboard`. Minimal/default dashboard — no ASCII art port needed.
- **D-06:** Replace `fzf-lua` with `snacks.picker`. Preserve existing keymaps exactly (`<leader>ff`, `<leader>fg`, `<leader>cd`, `<leader>cr`, etc.) — rewire to snacks.picker actions, no muscle-memory changes.
- **D-07:** Wire `snacks.lazygit` with a keymap (e.g., `<leader>gg`). lazygit is already installed as a binary.
- **D-08:** Enable `snacks.indent` — replaces `indent-blankline`.
- **D-09:** Enable `snacks.words` — LSP word highlights (auto-highlight occurrences of word under cursor).
- **D-10:** Enable `snacks.scroll` — smooth scrolling for `<C-d>`/`<C-u>`.
- **D-11:** Leave `snacks.image` disabled — image preview not needed.
- **D-12:** `snacks.terminal` and `snacks.zen` decisions deferred to Claude — enable only if they add clear value without noise.
- **D-13:** Update the Phase 3 validation harness probes to target `snacks.notif` instead of `noice`/`nvim-notify` after migration.
- **D-14:** Update `catppuccin` integration flags: remove stale `telescope = true` and `nvimtree = true`; add `snacks = true` if supported.

### Statusline behavior
- **D-15:** Keep `vim-tpipeline` — lualine pushes status to tmux as before.
- **D-16:** Set `globalstatus = true` in lualine (future-proofing for non-tmux).
- **D-17:** Guard `laststatus` on tmux presence: if `$TMUX` is set → `laststatus=0` (tmux handles display); else → `laststatus=3` (lualine shows inside Neovim). This ensures the statusline is visible outside tmux (direct terminal, Windows, VS Code).
- **D-18:** lualine section layout after noice removal is Claude's discretion — remove the noice status component, keep remaining sections sensible.

### Rollout documentation
- **D-19:** Extend `.config/nvim/README.md` with a Rollout/Update section. No new file.
- **D-20:** Section must cover: machine update checklist (clone/pull → run `arch/nvim.sh` → `:Lazy sync` → `:MasonUpdate` → validate), phase-by-phase change summary, verification steps post-deploy (run `nvim-validate.sh`, `:checkhealth`), and rollback instructions (git revert, `lazy-lock.json` restore).

### Carry-forward constraints
- **D-21:** One shared config across Linux and Windows remains locked.
- **D-22:** Keymaps remain centrally managed — snacks.picker keymaps must go through the central registry, not be scattered into the plugin spec.
- **D-23:** Validation harness must remain functional after all replacements — update probes as part of migration, not after.

### Claude's Discretion
- lualine section layout after noice component removal
- Whether to enable snacks.terminal and snacks.zen (only if clearly additive)
- Exact snacks.picker keymap wiring to match the existing fzf-lua surface
- Exact startup deferral strategy (which `event =` assignments to add/change)
- Catppuccin integration flag audit beyond the known stale entries

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` — Phase 5 goal, plan breakdown, and success criteria
- `.planning/REQUIREMENTS.md` — `UX-01` and `UX-02`
- `.planning/PROJECT.md` — project-wide constraints: one shared config, OS guards, aggressive cleanup allowed

### Locked prior-phase decisions
- `.planning/phases/01-reliability-and-portability-baseline/01-CONTEXT.md` — portability and runtime-behavior constraints
- `.planning/phases/02-central-command-and-keymap-architecture/02-CONTEXT.md` — centralized keymap architecture that all snacks mappings must respect
- `.planning/phases/04-tooling-and-ecosystem-modernization/04-CONTEXT.md` — productivity-first defaults, Mason-first policy, Neovim 0.11+ baseline

### Phase 4 handoff
- `.planning/phases/04-tooling-and-ecosystem-modernization/04-03-SUMMARY.md` — final Phase 4 state: what was normalized, what harness probes target
- `.planning/phases/03-plugin-audit-and-validation-harness/03-VALIDATION.md` — validation surfaces that must remain usable after snacks migration
- `.planning/phases/03-plugin-audit-and-validation-harness/03-VERIFICATION.md` — regression constraints from audit phase

### Existing code
- `.config/nvim/lua/plugins/notify.lua` — current noice.nvim + nvim-notify specs (targets for replacement)
- `.config/nvim/lua/plugins/lualine.lua` — current statusline config (noice component, vim-tpipeline, laststatus=0)
- `.config/nvim/lua/plugins/fzflua.lua` — current fzf-lua keymaps (must be preserved and rewired to snacks.picker)
- `.config/nvim/lua/plugins/alpha.lua` — current dashboard (target for replacement)
- `.config/nvim/lua/plugins/colortheme.lua` — catppuccin integrations (stale flags to clean up)
- `.config/nvim/lua/plugins/indent-blankline.lua` — current indent plugin (target for snacks.indent replacement)
- `.config/nvim/lua/core/keymaps/` — central keymap registry (snacks keymaps must be wired here)
- `scripts/nvim-validate.sh` — validation harness (probes must be updated after noice removal)
- `.config/nvim/README.md` — target for rollout documentation addition

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lualine.lua`: existing section layout is a clean starting point — just remove noice components and update laststatus guard
- `colortheme.lua`: catppuccin config centralizes all integration flags — one place to clean up stale entries
- Central keymap registry (Phase 2): all snacks.picker and snacks.lazygit keymaps should be registered here, not in plugin specs

### Established Patterns
- One Lua module per plugin/domain under `.config/nvim/lua/plugins/` — snacks.nvim gets a single `snacks.lua` spec
- Plugin specs use `opts = {}` or `config = function()` patterns (normalized in Phase 4)
- Keymaps go through central registry, not plugin-local `keys = {}` tables (Phase 2 constraint)
- Phase 3 validation harness probes specific plugin health by name — must be updated when targets change

### Integration Points
- `notify.lua` → `snacks.lua`: noice + nvim-notify removed, snacks.notif enabled
- `alpha.lua` → `snacks.lua`: alpha.nvim removed, snacks.dashboard enabled
- `fzflua.lua` → central keymaps: fzf-lua removed, keymaps rewired to snacks.picker actions
- `lualine.lua`: noice status component removed, laststatus guard added
- `scripts/nvim-validate.sh`: probe targets updated from noice/nvim-notify to snacks

</code_context>

<specifics>
## Specific Ideas

- User wants aggressive startup removal (treat 05-01 as a mini audit), not just lazy-load tuning.
- snacks.nvim is a broad consolidation — replaces noice, nvim-notify, alpha.nvim, fzf-lua, and indent-blankline in one package.
- Notification style: bottom-right toasts (snacks default).
- Dashboard: minimal/default — user explicitly does not want the ASCII art ported over.
- lazygit keymap: wire `snacks.lazygit` with a keymap (e.g., `<leader>gg`).
- Statusline: vim-tpipeline stays; `laststatus` is guarded on `$TMUX` so it works correctly both inside and outside tmux.
- Rollout docs: full coverage — checklist, change summary, verification, rollback.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 05-ux-and-performance-polish*
*Context gathered: 2026-04-15*
