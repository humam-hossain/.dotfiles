# Phase 9: Health Signal Cleanup - Context

**Gathered:** 2026-04-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Make `:checkhealth` trustworthy for this config: fix all config-caused ERROR entries (HEAL-01) and classify health findings so users can distinguish fix-now from optional/environment gaps (HEAL-02).

Two plans:
- 9-01 — Add `checkhealth` subcommand to validator + headless audit + fix config-caused ERRORs + fix BUG-019 (tmux.conf) + investigate/fix BUG-020 (Linux external-open)
- 9-02 — Create `lua/config/health.lua` vim.health provider + extend TOOL_METADATA with `required` tier + review install hints

</domain>

<decisions>
## Implementation Decisions

### Health Audit Approach

- **D-01:** Before fixing, run `:checkhealth` headlessly to enumerate current ERRORs. This is the authoritative list for 9-01 fixes — don't rely solely on Phase 6 inventory (Phase 8 may have introduced or resolved health signals).
- **D-02:** Add a `checkhealth` subcommand to `scripts/nvim-validate.sh` (not a standalone script). Consistent with Phase 6 D-03/D-04 harness pattern.
- **D-03:** Subcommand output: raw text capture to `.planning/tmp/nvim-validate/checkhealth.txt` + inline PASS/FAIL verdict. Fail on any `ERROR:` line in output. WARNINGs do not cause FAIL.
- **D-04:** Run all providers (`checkhealth` with no arguments) — most comprehensive; catches config-caused ERRORs regardless of which plugin owns the provider.
- **D-05:** Add `checkhealth` after `health` in the `nvim-validate.sh all` sequence: startup → sync → smoke → health → checkhealth. `all` is the one-shot confidence gate before rollout.

### Required Tool Checking (nvim-validate.sh health)

- **D-06:** `nvim-validate.sh health` extended to also fail if required tools are missing. Required tools hardcoded in bash as `REQUIRED_TOOLS='git rg'`. No Lua interop needed — the list is small and stable.
- **D-07:** `git` and `rg` are the only required tools (both crash-on-use if absent). All other tools in TOOL_METADATA are optional — their absence degrades features silently.

### Custom Health Provider (9-02)

- **D-08:** Create `lua/config/health.lua` — a `vim.health`-based provider. Shows up as `:checkhealth config`. Needs `lua/config/` directory (new).
- **D-09:** Provider uses `M.check = function()` pattern per Neovim health API conventions. Six sections via `vim.health.start()`:
  1. Neovim version
  2. Required tools (ERROR if missing)
  3. Optional tools (WARN if missing)
  4. Plugin load status (same 11 plugins as PLUGIN_LIST in nvim-validate.sh)
  5. Config guards (LSP server reachability, Neovim >= 0.12.0)
  6. Known environment warnings (tmux companion bindings, Linux external-open)
- **D-10:** Loaded on demand by Neovim — no `require()` in `init.lua`. Neovim auto-discovers health providers at `lua/<name>/health.lua`.
- **D-11:** All probe sections wrapped in `pcall`. If `core.health` fails to require, provider emits `vim.health.error()` with the message rather than crashing `:checkhealth`.
- **D-12:** Provider does NOT deduplicate against lazy.nvim's own health provider — complementary signals are acceptable.

### Probe Function Reuse

- **D-13:** Export `probe_tool` and `probe_plugin` from `core/health.lua` as `M.probe_tool` and `M.probe_plugin`. `lua/config/health.lua` requires `core.health` and calls them. Single source of truth for probe logic; two output formats (JSON headless, vim.health interactive).
- **D-14:** Plugin probe list in `lua/config/health.lua` matches `PLUGIN_LIST` in `nvim-validate.sh` (same 11 plugins). If a plugin is added/removed, update both.

### TOOL_METADATA Classification (HEAL-02)

- **D-15:** Add `required` boolean to each entry in `TOOL_METADATA` in `core/health.lua`. `required=true` → `vim.health.error()` if missing; `required=false` → `vim.health.warn()`. Classification lives in code, not docs.
- **D-16:** Only `git` and `rg` get `required=true`. All other tools are `required=false`.
- **D-17:** Add a one-line comment above `TOOL_METADATA` documenting `required` semantics: `required=true` → ERROR in `:checkhealth config` + FAIL in `nvim-validate.sh health`; `false` → WARN only.
- **D-18:** Install hints in `TOOL_METADATA` reviewed and updated for accuracy on Arch Linux + Neovim 0.12.1 as part of 9-02.

### Neovim Version Check

- **D-19:** Health provider version guard checks `vim.version() >= {0, 12, 0}`. Running 0.12.1 on Arch Linux — config targets 0.12+. Provider emits `vim.health.error()` if below 0.12.0.

### Known Environment Warnings

- **D-20:** Health provider includes a "Known environment gaps" section using `vim.health.warn()`. Always shown unconditionally (not gated on `$TMUX` or OS detection). Plain language — no BUG IDs.
- **D-21:** BUG-019 (tmux companion bindings) warning includes the exact 4 `bind-key` entries users need to add to `.tmux.conf`. Copy-paste ready from `:checkhealth config` output.
- **D-22:** BUG-020 (Linux external-open) warning explains the issue and investigation steps.

### Plugin-Owned Health ERRORs

- **D-23:** If a plugin's own health provider emits ERRORs due to our config (e.g., mason can't find an LSP server we configured), that is a config bug. Fix our config so the provider doesn't error. Not classified as "upstream problem."
- **D-24:** Treesitter missing parser warnings: environment (parsers are installed on demand). Claude's discretion — classify as env warning if they appear in the audit output.

### Docs / Traceability

- **D-25:** Health provider output is self-sufficient for HEAL-02. No separate README section explaining classification.
- **D-26:** README validation commands table updated with `./scripts/nvim-validate.sh checkhealth` row in Phase 9 (not deferred to Phase 11).
- **D-27:** FAILURES.md updated — HEAL-01 and HEAL-02 entries (or phase-level row) moved to Fixed/Closed after Phase 9 passes. Consistent with Phase 6 D-12.
- **D-28:** Stale `--- TODO: Health snapshot for validation harness ---` comment at top of `core/health.lua` removed in 9-02.

### BUG-019 (tmux companion bindings)

- **D-29:** Fixed in 9-01 — add 4 `bind-key -n C-h/j/k/l` companion entries to `.config/.tmux.conf` per vim-tmux-navigator README.
- **D-30:** Verified interactively: reload tmux config (`tmux source-file ~/.config/.tmux.conf`), confirm `<C-h/j/k/l>` crosses pane boundaries. BUG-019 → Fixed only after interactive confirmation.

### BUG-020 (Linux external-open)

- **D-31:** Investigated and fixed in 9-01. Investigation order: (1) terminal key binding — verify `<C-S-o>` reaches Neovim via `:verbose nmap <C-S-o>`; (2) test `vim.ui.open()` directly via `:lua vim.ui.open(vim.fn.expand('%:p'))` and read the error from Phase 8-02's hardening; (3) test `xdg-open` in shell.
- **D-32:** If root cause is terminal stripping `<C-S-o>`: rebind external-open to `<leader>o` in `registry.lua`. `<leader>o` is currently free.
- **D-33:** Phase 8-02's `core/open.lua` hardening (capturing vim.ui.open return tuple) is correct and stays regardless of BUG-020 outcome.

### 9-01 Task Order

- **D-34:** Sequence: (1) Add `checkhealth` subcommand to `nvim-validate.sh`, (2) Run headless audit and document current ERRORs, (3) Fix config-caused health ERRORs and missing guards, (4) Fix BUG-019 `.tmux.conf` companion bindings, (5) Investigate and fix BUG-020 Linux external-open.

### Claude's Discretion

- Exact headless nvim command to capture `:checkhealth` output (may need `--headless -c 'checkhealth' -c 'write! ...' -c 'qa!'` or similar)
- Specific ERRORs found in the audit and their fixes (depends on current `:checkhealth` output)
- Treesitter missing parser classification (env warning vs config fix)
- Order of commits within each plan
- Whether `lua/config/` directory needs any other files

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` — Phase 9 goal, requirements HEAL-01, HEAL-02, plan structure
- `.planning/REQUIREMENTS.md` — HEAL-01 and HEAL-02 acceptance criteria
- `.planning/PROJECT.md` — v1.1 milestone goals and constraints

### Failure inventory
- `.planning/phases/06-runtime-failure-inventory/FAILURES.md` — BUG-019 and BUG-020 open items; updated to Fixed/Closed after Phase 9
- `.planning/phases/06-runtime-failure-inventory/CHECKLIST.md` — repro steps for open bugs

### Files being modified
- `scripts/nvim-validate.sh` — add `checkhealth` subcommand + required tool check in `cmd_health`
- `.config/nvim/lua/core/health.lua` — export probe_tool/probe_plugin; add `required` boolean to TOOL_METADATA; remove stale TODO comment; review install hints
- `.config/.tmux.conf` — add 4 `bind-key` companion entries (BUG-019)
- `.config/nvim/lua/core/keymaps/registry.lua` — possibly rebind `<C-S-o>` to `<leader>o` for external-open (BUG-020, conditional on investigation)
- `.config/nvim/lua/core/open.lua` — may need fix if vim.ui.open behavior is root cause of BUG-020

### Files being created
- `.config/nvim/lua/config/health.lua` — new vim.health provider for `:checkhealth config` (9-02)

### Prior phase context
- `.planning/phases/08-plugin-runtime-hardening/08-CONTEXT.md` — D-13: core/open.lua error handling fix; D-09/D-10: BUG-001 already fixed
- `.planning/phases/07-keymap-reliability-fixes/07-CONTEXT.md` — D-07: BUG-017 deferred to Phase 8 (now fixed)
- `.planning/phases/06-runtime-failure-inventory/06-CONTEXT.md` — D-12: FAILURES.md is living doc; D-18: don't pre-filter noise

### External references
- vim-tmux-navigator README: companion `bind-key` entries required in `.tmux.conf` for cross-pane traversal (BUG-019 fix)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scripts/nvim-validate.sh` — harness to extend with `checkhealth` subcommand; existing patterns for cmd_* functions, REPORT_DIR, PASS/FAIL output
- `.config/nvim/lua/core/health.lua` — `probe_tool()` and `probe_plugin()` local functions to export; `TOOL_METADATA` table to extend with `required` field; `M.snapshot()` stays unchanged
- `.planning/phases/06-runtime-failure-inventory/CHECKLIST.md` — BUG-019/BUG-020 repro steps for verification

### Established Patterns
- `nvim-validate.sh` uses `set -euo pipefail`, `cmd_*()` function pattern, `REPORT_DIR=.planning/tmp/nvim-validate/`, PASS/FAIL exit codes — follow this exactly
- `core/health.lua`: `probe_plugin(name)` returns `{name, loaded, error}`. `probe_tool(name)` returns `{name, available, path, affected_feature, install_hint}`. Both will get `required` field in TOOL_METADATA.
- `PLUGIN_LIST` in `nvim-validate.sh` line 21: `{'snacks','lualine','lspconfig','conform','nvim-treesitter.configs','blink.cmp','gitsigns','ufo','bufferline','which-key','render-markdown'}` — health provider uses same 11 plugins
- `vim.health.start()` / `vim.health.ok()` / `vim.health.warn()` / `vim.health.error()` — Neovim 0.10+ health API (stable in 0.12.1)

### Integration Points
- `nvim-validate.sh all` sequence extended: startup → sync → smoke → health → checkhealth
- `lua/config/health.lua` discovered by Neovim at `:checkhealth config` — no `require` in `init.lua`
- `core/health.lua` exports feed `lua/config/health.lua` — dependency is `require('core.health')` in the provider
- `registry.lua` possibly updated for BUG-020 `<leader>o` rebind if investigation confirms terminal stripping `<C-S-o>`

</code_context>

<specifics>
## Specific Ideas

- Headless checkhealth capture command: `nvim --headless -c ':redir! >/path/to/checkhealth.txt | checkhealth | redir END | qa!'` or via Lua `vim.cmd()` wrapper — researcher should confirm the exact invocation that captures output reliably
- BUG-019 exact lines for `.tmux.conf` (from vim-tmux-navigator README):
  ```
  bind-key -n 'C-h' if-shell "$is_vim" 'send-keys C-h'  'select-pane -L'
  bind-key -n 'C-j' if-shell "$is_vim" 'send-keys C-j'  'select-pane -D'
  bind-key -n 'C-k' if-shell "$is_vim" 'send-keys C-k'  'select-pane -U'
  bind-key -n 'C-l' if-shell "$is_vim" 'send-keys C-l'  'select-pane -R'
  ```
  (exact syntax depends on vim-tmux-navigator version — researcher should verify against plugin README)
- User running Neovim 0.12.1 on Arch Linux — version guard checks `>= {0, 12, 0}`
- `<leader>o` is free in registry.lua — safe to use as external-open fallback if `<C-S-o>` investigation shows terminal stripping

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 09-health-signal-cleanup*
*Context gathered: 2026-04-22*
