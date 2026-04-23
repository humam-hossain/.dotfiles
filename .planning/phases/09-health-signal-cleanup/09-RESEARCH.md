# Phase 9: Health Signal Cleanup - Research

**Researched:** 2026-04-22  
**Domain:** Neovim health reporting, repo-owned validation, and environment-signal classification  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

Health Audit Approach `[VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]`
- **D-01:** Before fixing, run `:checkhealth` headlessly to enumerate current ERRORs. This is the authoritative list for 9-01 fixes — don't rely solely on Phase 6 inventory (Phase 8 may have introduced or resolved health signals). `[VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]`
- **D-02:** Add a `checkhealth` subcommand to `scripts/nvim-validate.sh` (not a standalone script). Consistent with Phase 6 D-03/D-04 harness pattern. `[VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]`
- **D-03:** Subcommand output: raw text capture to `.planning/tmp/nvim-validate/checkhealth.txt` + inline PASS/FAIL verdict. Fail on any `ERROR:` line in output. WARNINGs do not cause FAIL. `[VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]`
- **D-04:** Run all providers (`checkhealth` with no arguments) — most comprehensive; catches config-caused ERRORs regardless of which plugin owns the provider. `[VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]`
- **D-05:** Add `checkhealth` after `health` in the `nvim-validate.sh all` sequence: startup → sync → smoke → health → checkhealth. `all` is the one-shot confidence gate before rollout. `[VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]`

Required Tool Checking (nvim-validate.sh health) `[VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]`
- **D-06:** `nvim-validate.sh health` extended to also fail if required tools are missing. Required tools hardcoded in bash as `REQUIRED_TOOLS='git rg'`. No Lua interop needed — the list is small and stable. `[VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]`
- **D-07:** `git` and `rg` are the only required tools (both crash-on-use if absent). All other tools in TOOL_METADATA are optional — their absence degrades features silently. `[VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]`

Custom Health Provider (9-02) `[VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]`
- **D-08:** Create `lua/config/health.lua` — a `vim.health`-based provider. Shows up as `:checkhealth config`. Needs `lua/config/` directory (new). `[VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]`
- **D-09:** Provider uses `M.check = function()` pattern per Neovim health API conventions. Six sections via `vim.health.start()`: Neovim version, required tools, optional tools, plugin load status, config guards, known environment warnings. `[VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]`
- **D-10:** Loaded on demand by Neovim — no `require()` in `init.lua`. Neovim auto-discovers health providers at `lua/<name>/health.lua`. `[VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]`
- **D-11:** All probe sections wrapped in `pcall`. If `core.health` fails to require, provider emits `vim.health.error()` with the message rather than crashing `:checkhealth`. `[VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]`
- **D-12:** Provider does NOT deduplicate against lazy.nvim's own health provider — complementary signals are acceptable. `[VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]`

Probe Function Reuse `[VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]`
- **D-13:** Export `probe_tool` and `probe_plugin` from `core/health.lua` as `M.probe_tool` and `M.probe_plugin`. `lua/config/health.lua` requires `core.health` and calls them. Single source of truth for probe logic; two output formats (JSON headless, vim.health interactive). `[VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]`
- **D-14:** Plugin probe list in `lua/config/health.lua` matches `PLUGIN_LIST` in `nvim-validate.sh` (same 11 plugins). If a plugin is added/removed, update both. `[VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]`

TOOL_METADATA Classification (HEAL-02) `[VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]`
- **D-15:** Add `required` boolean to each entry in `TOOL_METADATA` in `core/health.lua`. `required=true` → `vim.health.error()` if missing; `required=false` → `vim.health.warn()`. Classification lives in code, not docs. `[VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]`
- **D-16:** Only `git` and `rg` get `required=true`. All other tools are `required=false`. `[VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]`
- **D-17:** Add a one-line comment above `TOOL_METADATA` documenting `required` semantics: `required=true` → ERROR in `:checkhealth config` + FAIL in `nvim-validate.sh health`; `false` → WARN only. `[VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]`
- **D-18:** Install hints in `TOOL_METADATA` reviewed and updated for accuracy on Arch Linux + Neovim 0.12.1 as part of 9-02. `[VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]`

Neovim Version Check `[VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]`
- **D-19:** Health provider version guard checks `vim.version() >= {0, 12, 0}`. Running 0.12.1 on Arch Linux — config targets 0.12+. Provider emits `vim.health.error()` if below 0.12.0. `[VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]`

Known Environment Warnings `[VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]`
- **D-20:** Health provider includes a "Known environment gaps" section using `vim.health.warn()`. Always shown unconditionally (not gated on `$TMUX` or OS detection). Plain language — no BUG IDs. `[VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]`
- **D-21:** BUG-019 (tmux companion bindings) warning includes the exact 4 `bind-key` entries users need to add to `.tmux.conf`. Copy-paste ready from `:checkhealth config` output. `[VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]`
- **D-22:** BUG-020 (Linux external-open) warning explains the issue and investigation steps. `[VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]`

Plugin-Owned Health ERRORs `[VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]`
- **D-23:** If a plugin's own health provider emits ERRORs due to our config (e.g., mason can't find an LSP server we configured), that is a config bug. Fix our config so the provider doesn't error. Not classified as "upstream problem." `[VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]`
- **D-24:** Treesitter missing parser warnings: environment (parsers are installed on demand). Claude's discretion — classify as env warning if they appear in the audit output. `[VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]`

Docs / Traceability `[VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]`
- **D-25:** Health provider output is self-sufficient for HEAL-02. No separate README section explaining classification. `[VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]`
- **D-26:** README validation commands table updated with `./scripts/nvim-validate.sh checkhealth` row in Phase 9 (not deferred to Phase 11). `[VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]`
- **D-27:** FAILURES.md updated — HEAL-01 and HEAL-02 entries (or phase-level row) moved to Fixed/Closed after Phase 9 passes. Consistent with Phase 6 D-12. `[VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]`
- **D-28:** Stale `--- TODO: Health snapshot for validation harness ---` comment at top of `core/health.lua` removed in 9-02. `[VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]`

BUG-019 (tmux companion bindings) `[VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]`
- **D-29:** Fixed in 9-01 — add 4 `bind-key -n C-h/j/k/l` companion entries to `.config/.tmux.conf` per vim-tmux-navigator README. `[VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]`
- **D-30:** Verified interactively: reload tmux config (`tmux source-file ~/.config/.tmux.conf`), confirm `<C-h/j/k/l>` crosses pane boundaries. BUG-019 → Fixed only after interactive confirmation. `[VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]`

BUG-020 (Linux external-open) `[VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]`
- **D-31:** Investigated and fixed in 9-01. Investigation order: (1) terminal key binding — verify `<C-S-o>` reaches Neovim via `:verbose nmap <C-S-o>`; (2) test `vim.ui.open()` directly via `:lua vim.ui.open(vim.fn.expand('%:p'))`; (3) test `xdg-open` in shell. `[VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]`
- **D-32:** If root cause is terminal stripping `<C-S-o>`: rebind external-open to `<leader>o` in `registry.lua`. `<leader>o` is currently free. `[VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]`
- **D-33:** Phase 8-02's `core/open.lua` hardening (capturing `vim.ui.open` return tuple) is correct and stays regardless of BUG-020 outcome. `[VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md; VERIFIED: .config/nvim/lua/core/open.lua]`

9-01 Task Order `[VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]`
- **D-34:** Sequence: (1) Add `checkhealth` subcommand to `nvim-validate.sh`, (2) Run headless audit and document current ERRORs, (3) Fix config-caused health ERRORs and missing guards, (4) Fix BUG-019 `.tmux.conf` companion bindings, (5) Investigate and fix BUG-020 Linux external-open. `[VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]`

### Claude's Discretion
- Exact headless nvim command to capture `:checkhealth` output. `[VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]`
- Specific ERRORs found in the audit and their fixes. `[VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]`
- Treesitter missing parser classification. `[VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]`
- Order of commits within each plan. `[VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]`
- Whether `lua/config/` directory needs any other files. `[VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]`

### Deferred Ideas (OUT OF SCOPE)
- None — discussion stayed within phase scope. `[VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]`
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| HEAL-01 | User can run `:checkhealth` without config-caused `ERROR:` entries. `[VERIFIED: .planning/REQUIREMENTS.md]` | Headless capture must audit all providers from the health buffer, then 9-01 fixes only config-caused `ERROR:` sources. `[CITED: /usr/share/nvim/runtime/lua/vim/health.lua; VERIFIED: local headless probe]` |
| HEAL-02 | User can distinguish fix-now health findings from optional environment/tooling warnings. `[VERIFIED: .planning/REQUIREMENTS.md]` | `lua/config/health.lua` should use `vim.health.error()` for required tools and `vim.health.warn()` for optional tools and environment gaps. `[CITED: /usr/share/nvim/runtime/doc/health.txt; VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]` |
</phase_requirements>

## Summary

Phase 9 should treat `:checkhealth` as two separate surfaces: the upstream/plugin health buffer and the repo-owned `core.health`/`config.health` signal. The reliable headless capture path is not `redir`; local runtime source shows `:checkhealth` renders into a temporary `health://` buffer through `vim.health._check()` and buffer appends, so the validator should dump buffer lines after the health run instead of scraping command output. `[CITED: /usr/share/nvim/runtime/lua/vim/health.lua; VERIFIED: local headless probe]`

The repo already has most of the prerequisites for HEAL-02: `scripts/nvim-validate.sh` has an established subcommand pattern, `core/health.lua` already owns tool and plugin probes, and `core/open.lua` already contains the correct `vim.ui.open()` tuple handling from Phase 8. The main gap is classification and alignment: `core/health.lua` still has a stale TODO banner, outdated tool descriptions such as ripgrep being described as “fzf-lua live grep” even though the stack now uses `snacks.nvim`, and no required/optional tier. `[VERIFIED: scripts/nvim-validate.sh; VERIFIED: .config/nvim/lua/core/health.lua; VERIFIED: .config/nvim/lua/core/open.lua; VERIFIED: .config/nvim/lua/plugins/snacks.lua]`

BUG-019 and BUG-020 belong in 9-01, not 9-02, because both affect whether health findings are trustworthy. `.config/.tmux.conf` currently has plain pane movement and resize bindings plus the `vim-tmux-navigator` plugin, but it does not contain the companion `bind-key -n C-h/j/k/l` forwarding layer needed for tmux pane crossing. `registry.lua` still binds external-open to `<C-S-o>`, so the Phase 9 investigation should prove whether the failure is terminal delivery, `vim.ui.open()`, or host `xdg-open`, then only rebind if the terminal never delivers the chord. `[VERIFIED: .config/.tmux.conf; VERIFIED: .config/nvim/lua/core/keymaps/registry.lua; VERIFIED: .planning/phases/06-runtime-failure-inventory/FAILURES.md; VERIFIED: .planning/phases/06-runtime-failure-inventory/CHECKLIST.md]`

**Primary recommendation:** Implement 9-01 as “capture and fix current failing health signals,” then implement 9-02 as “add repo-owned health classification without changing the capture or bug-fix surface.” `[VERIFIED: .planning/ROADMAP.md; VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]`

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Headless `:checkhealth` artifact capture | Shell validator | Neovim runtime | The report is generated by Neovim but the artifact path, exit status, and rollout contract belong to `scripts/nvim-validate.sh`. `[VERIFIED: scripts/nvim-validate.sh; CITED: /usr/share/nvim/runtime/lua/vim/health.lua]` |
| Repo-owned required/optional classification | Neovim config | Shell validator | Severity is emitted by `vim.health` in `lua/config/health.lua`, while bash should only mirror the required-tool fail gate for `git` and `rg`. `[CITED: /usr/share/nvim/runtime/doc/health.txt; VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]` |
| Plugin/provider `ERROR:` cleanup | Neovim config | Plugin runtime | Config-caused health failures originate in configured providers and should be fixed in repo code or config choices. `[VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]` |
| tmux cross-pane navigation | tmux config | Neovim config | The Neovim side is already installed via `vim-tmux-navigator`; tmux forwarding is missing in `.config/.tmux.conf`. `[VERIFIED: .config/nvim/lua/plugins/misc.lua; VERIFIED: .config/.tmux.conf; VERIFIED: FAILURES.md]` |
| Linux external-open reliability | Terminal/OS environment | Neovim config | `core/open.lua` already surfaces host errors, so remaining risk is key delivery or host opener behavior. `[VERIFIED: .config/nvim/lua/core/open.lua; VERIFIED: FAILURES.md]` |

## Repo-Specific Findings

1. `scripts/nvim-validate.sh` currently supports `startup`, `sync`, `health`, `smoke`, and `all`, and `all` stops after `health`; Phase 9 can extend the existing control flow without inventing a second harness. `[VERIFIED: scripts/nvim-validate.sh]`
2. `core/health.lua` already has reusable `probe_tool()` and `probe_plugin()` functions, but they are local-only and `TOOL_METADATA` currently has no `required` tier. `[VERIFIED: .config/nvim/lua/core/health.lua]`
3. `core/health.lua` metadata drifts from the shipped stack today: `rg` is labeled as affecting “fzf-lua live grep,” but the repo now uses `snacks.nvim` for pickers. `[VERIFIED: .config/nvim/lua/core/health.lua; VERIFIED: .config/nvim/lua/plugins/snacks.lua]`
4. `core/open.lua` already follows the correct `local cmd, err = vim.ui.open(target)` pattern, so BUG-020 should not reopen Phase 8’s tuple-handling fix. `[VERIFIED: .config/nvim/lua/core/open.lua]`
5. `.config/.tmux.conf` contains `vim-tmux-navigator` in TPM plugins, but it only defines pane movement on bare `h/j/k/l` and resize on `<C-h/j/k/l>`; it does not define the navigator companion passthrough bindings. `[VERIFIED: .config/.tmux.conf]`
6. `registry.lua` still maps `file.open_external` to `<C-S-o>`, so Phase 9 should preserve that mapping unless the investigation proves the chord never reaches Neovim in the user’s terminal. `[VERIFIED: .config/nvim/lua/core/keymaps/registry.lua; VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]`
7. Local Neovim runtime docs require custom providers to expose `M.check` from `lua/<name>/health.lua` or `lua/<name>/health/init.lua`, and recommend `vim.health.start()/ok()/warn()/error()` for structured output. `[CITED: /usr/share/nvim/runtime/doc/health.txt]`
8. Local runtime source shows `:checkhealth` writes report lines into a temporary buffer via `vim.fn.append()` and only reports progress through `nvim_echo`, which is why `redir` captures progress text but not the rendered report in headless probes. `[CITED: /usr/share/nvim/runtime/lua/vim/health.lua; VERIFIED: local headless probe]`

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| Neovim | `0.12.1` | Runtime executing both headless capture and custom health providers. `[VERIFIED: local command nvim --version]` | Phase 9 targets 0.12+ behavior already reflected in repo context and local machine state. `[VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md; VERIFIED: local command nvim --version]` |
| `vim.health` | bundled with local Neovim runtime | Structured health sections and severity output. `[CITED: /usr/share/nvim/runtime/doc/health.txt]` | It is the canonical health interface and replaces deprecated `health#report_*` functions. `[CITED: /usr/share/nvim/runtime/doc/health.txt; CITED: /usr/share/nvim/runtime/doc/deprecated.txt]` |
| `scripts/nvim-validate.sh` | repo script | Headless rollout gate and artifact writer. `[VERIFIED: scripts/nvim-validate.sh]` | It already defines the validator UX and artifact directory for this repo. `[VERIFIED: scripts/nvim-validate.sh]` |
| `core.health.snapshot()` | repo module | JSON snapshot for tools/plugins/lazy state. `[VERIFIED: .config/nvim/lua/core/health.lua]` | Phase 9 should reuse its probes instead of duplicating tool/plugin checks. `[VERIFIED: .config/nvim/lua/core/health.lua; VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]` |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| tmux | `3.6a` | Verifies BUG-019 companion bindings and cross-pane behavior. `[VERIFIED: local command tmux -V]` | Needed only for the interactive BUG-019 validation path. `[VERIFIED: FAILURES.md]` |
| `xdg-open` | `1.2.1` | Linux host opener behind `vim.ui.open()` investigation. `[VERIFIED: local command xdg-open --version]` | Needed only for BUG-020 diagnosis on Linux. `[VERIFIED: FAILURES.md]` |
| `git` | `2.53.0` | Required validator/runtime dependency. `[VERIFIED: local command git --version]` | Mark as required in both bash fail gate and health provider output. `[VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]` |
| `rg` | `15.1.0` | Required search/runtime dependency. `[VERIFIED: local command rg --version]` | Mark as required in both bash fail gate and health provider output. `[VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]` |
| `jq` | `1.8.1` | Structured parsing for validator JSON inspection. `[VERIFIED: local command jq --version]` | Keep as validator helper; not part of repo-owned `:checkhealth config`. `[VERIFIED: scripts/nvim-validate.sh]` |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Headless buffer dump after `vim.health._check()` | `redir | checkhealth` | `redir` is simpler but local probes only captured progress lines, not the actual report body. `[VERIFIED: local headless probe; CITED: /usr/share/nvim/runtime/lua/vim/health.lua]` |
| Reusing `core.health` probe functions | Duplicated probe logic in `lua/config/health.lua` | Duplication would create two classification tables and drift risk immediately. `[VERIFIED: .config/nvim/lua/core/health.lua; VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]` |
| Keep `<C-S-o>` until disproven | Immediate rebind to `<leader>o` | Rebinding before key-delivery proof would mix UX changes into a bug-diagnosis plan. `[VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]` |

## Architecture Patterns

### System Architecture Diagram

```text
./scripts/nvim-validate.sh checkhealth
  -> launch nvim --headless with repo init.lua
  -> run health engine for all providers
  -> health engine populates temporary health:// buffer
  -> Lua reads current buffer lines and writes checkhealth.txt
  -> bash scans artifact for "ERROR:"
  -> PASS/FAIL verdict

:checkhealth config
  -> Neovim discovers lua/config/health.lua
  -> provider requires core.health via pcall
  -> provider runs version/tool/plugin/config-gap probes
  -> vim.health.* emits ERROR/WARN/OK sections
  -> user sees fix-now vs optional warnings inline
```

### Recommended Project Structure

```text
.config/nvim/lua/
├── core/
│   ├── health.lua        # probe logic + JSON snapshot
│   └── open.lua          # external-open helper used by keymaps
└── config/
    └── health.lua        # vim.health provider discovered by :checkhealth config

scripts/
└── nvim-validate.sh      # startup/sync/smoke/health/checkhealth orchestration
```

### Pattern 1: Headless Health Buffer Capture
**What:** Run the health engine, then dump the `health://` buffer lines to a file instead of relying on `redir`. `[CITED: /usr/share/nvim/runtime/lua/vim/health.lua; VERIFIED: local headless probe]`  
**When to use:** `scripts/nvim-validate.sh checkhealth` and any future artifact-producing health audit. `[VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]`  
**Example:**

```lua
-- Source: /usr/share/nvim/runtime/lua/vim/health.lua + local headless probe
local old = vim.o.eventignore
vim.o.eventignore = "FileType"
local ok, err = pcall(require("vim.health")._check, "", "")
local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
vim.fn.writefile(lines, ".planning/tmp/nvim-validate/checkhealth.txt")
vim.o.eventignore = old
if not ok then
  error(err)
end
```

**Why this pattern:** The runtime implementation shows the report is assembled in a buffer and progress is emitted separately, so reading the buffer is the stable capture path. `[CITED: /usr/share/nvim/runtime/lua/vim/health.lua]`

### Pattern 2: Defensive Repo-Owned Health Provider
**What:** `lua/config/health.lua` should wrap `require("core.health")` and each probe section in `pcall`, then emit `vim.health.error()` instead of throwing. `[CITED: /usr/share/nvim/runtime/doc/health.txt; VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]`  
**When to use:** All repo-owned checks in 9-02. `[VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]`  
**Example:**

```lua
-- Source: /usr/share/nvim/runtime/doc/health.txt
local M = {}

function M.check()
  vim.health.start("Required tools")
  local ok, health = pcall(require, "core.health")
  if not ok then
    vim.health.error("Failed to load core.health: " .. tostring(health))
    return
  end

  local ok_probe, result = pcall(health.probe_tool, "git")
  if not ok_probe then
    vim.health.error("git probe crashed: " .. tostring(result))
  elseif result.available then
    vim.health.ok("git found at " .. result.path)
  else
    vim.health.error("git missing", result.install_hint)
  end
end

return M
```

### Anti-Patterns to Avoid
- **`redir`-only capture:** It misses the real report body in headless runs because `:checkhealth` renders into a buffer. `[VERIFIED: local headless probe; CITED: /usr/share/nvim/runtime/lua/vim/health.lua]`
- **Duplicating tool/plugin metadata in multiple Lua modules:** It will drift immediately from `core.health.lua` and `scripts/nvim-validate.sh`. `[VERIFIED: .config/nvim/lua/core/health.lua; VERIFIED: scripts/nvim-validate.sh]`
- **Fixing BUG-020 by rebinding first:** It hides whether the real fault is terminal key delivery, `vim.ui.open()`, or host opener configuration. `[VERIFIED: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md]`
- **Marking all missing tools as errors:** The project requirements explicitly want optional/tooling warnings preserved rather than suppressed. `[VERIFIED: .planning/PROJECT.md; VERIFIED: .planning/REQUIREMENTS.md]`

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Health report serialization | Ad hoc grep/`redir` parser | Health buffer dump after Neovim’s own health engine runs | The runtime already owns discovery, sectioning, and severity formatting. `[CITED: /usr/share/nvim/runtime/lua/vim/health.lua]` |
| Repo-specific health UI | Custom scratch-buffer rendering | `vim.health.start()/ok()/warn()/error()` | Severity and advice formatting are already standardized. `[CITED: /usr/share/nvim/runtime/doc/health.txt]` |
| tmux navigation diagnosis | Neovim-only workaround | Fix `.config/.tmux.conf` companion bindings first | Cross-pane behavior is impossible without tmux-side forwarding. `[VERIFIED: .config/.tmux.conf; VERIFIED: FAILURES.md]` |

**Key insight:** Phase 9 should reuse Neovim’s health engine and this repo’s existing probe module, then only add classification and artifact capture around them. `[CITED: /usr/share/nvim/runtime/lua/vim/health.lua; VERIFIED: .config/nvim/lua/core/health.lua]`

## Recommended Implementation Split

### Plan 9-01
- Add `checkhealth` to `scripts/nvim-validate.sh`, write `.planning/tmp/nvim-validate/checkhealth.txt`, and make `all` run `checkhealth` after `health`. `[VERIFIED: scripts/nvim-validate.sh; VERIFIED: 09-CONTEXT.md]`
- Use the health-buffer capture pattern, not `redir`, and scan the artifact for `ERROR:` lines only. `[VERIFIED: local headless probe; CITED: /usr/share/nvim/runtime/lua/vim/health.lua; VERIFIED: 09-CONTEXT.md]`
- Run the first audit before any fixes and treat its `ERROR:` lines as the authoritative HEAL-01 backlog. `[VERIFIED: 09-CONTEXT.md]`
- Fix config-caused health errors only, then fix BUG-019 in `.config/.tmux.conf`, then investigate BUG-020 in the specified order. `[VERIFIED: 09-CONTEXT.md; VERIFIED: FAILURES.md]`
- Keep README and FAILURES updates in this plan only where they reflect the new validator command or resolved bugs. `[VERIFIED: 09-CONTEXT.md]`

### Plan 9-02
- Export `probe_tool` and `probe_plugin` from `core/health.lua`, add `required` to `TOOL_METADATA`, and update stale install hints/affected-feature text. `[VERIFIED: .config/nvim/lua/core/health.lua; VERIFIED: 09-CONTEXT.md]`
- Create `lua/config/health.lua` with six sections: version, required tools, optional tools, plugin load status, config guards, known environment gaps. `[VERIFIED: 09-CONTEXT.md; CITED: /usr/share/nvim/runtime/doc/health.txt]`
- Keep `git` and `rg` as the only required tools in both bash and Lua surfaces. `[VERIFIED: 09-CONTEXT.md]`
- Do not change `scripts/nvim-validate.sh checkhealth` semantics in this plan; 9-02 is classification, not audit mechanics. `[VERIFIED: .planning/ROADMAP.md; VERIFIED: 09-CONTEXT.md]`

## Common Pitfalls

### Pitfall 1: `redir` Looks Successful but Produces a Useless Artifact
**What goes wrong:** The file contains only progress lines such as `checkhealth: 27% checking lazy` instead of the rendered findings. `[VERIFIED: local headless probe]`  
**Why it happens:** `:checkhealth` assembles the report in a temporary buffer and progress uses `nvim_echo`. `[CITED: /usr/share/nvim/runtime/lua/vim/health.lua]`  
**How to avoid:** Dump the buffer after the health engine runs. `[CITED: /usr/share/nvim/runtime/lua/vim/health.lua]`  
**Warning signs:** Artifact has percentages but no `OK/WARNING/ERROR` entries. `[VERIFIED: local headless probe]`

### Pitfall 2: Health Capture Trips Unrelated `FileType` Hooks
**What goes wrong:** The health buffer becomes `filetype=checkhealth`, which can trigger plugin autocommands that were never intended for the validator path. `[CITED: /usr/share/nvim/runtime/doc/health.txt; CITED: /usr/share/nvim/runtime/lua/vim/health.lua]`  
**Why it happens:** The runtime ends `_check()` by setting the buffer filetype to `checkhealth`. `[CITED: /usr/share/nvim/runtime/lua/vim/health.lua]`  
**How to avoid:** Temporarily set `eventignore=FileType` around the headless capture. `[VERIFIED: local headless probe]`  
**Warning signs:** Capture exits with errors unrelated to the health provider being audited. `[VERIFIED: local headless probe]`

### Pitfall 3: BUG-019 Is “Fixed” in Neovim but Still Broken in tmux
**What goes wrong:** Neovim owns `<C-h/j/k/l>` correctly but pane crossing still fails. `[VERIFIED: FAILURES.md; VERIFIED: CHECKLIST.md]`  
**Why it happens:** The tmux side lacks the navigator forwarding bindings. `[VERIFIED: .config/.tmux.conf; VERIFIED: FAILURES.md]`  
**How to avoid:** Treat `.config/.tmux.conf` as the source of truth for the fix and require an interactive tmux verification step. `[VERIFIED: 09-CONTEXT.md]`  
**Warning signs:** `:verbose nmap <C-h>` points to `TmuxNavigateLeft`, yet tmux pane crossing still fails. `[VERIFIED: CHECKLIST.md]`

### Pitfall 4: BUG-020 Gets Masked by an Eager Rebind
**What goes wrong:** `<leader>o` works but the repo never proves why `<C-S-o>` failed. `[VERIFIED: 09-CONTEXT.md]`  
**Why it happens:** Terminal key-delivery issues and OS opener issues are different bugs. `[VERIFIED: FAILURES.md]`  
**How to avoid:** Follow the investigation order from the context before changing the mapping. `[VERIFIED: 09-CONTEXT.md]`  
**Warning signs:** `core/open.lua` emits no host error, but the original chord still does nothing. `[VERIFIED: .config/nvim/lua/core/open.lua; VERIFIED: FAILURES.md]`

## Code Examples

### Minimal Health Provider Skeleton
```lua
-- Source: /usr/share/nvim/runtime/doc/health.txt
local M = {}

function M.check()
  vim.health.start("config report")
  vim.health.ok("example ok")
  vim.health.warn("example warn", "optional advice")
  vim.health.error("example error", "fix instruction")
end

return M
```

### Validator-Side Required Tool Fail Gate
```bash
# Source: .planning/phases/09-health-signal-cleanup/09-CONTEXT.md
REQUIRED_TOOLS=(git rg)
for tool in "${REQUIRED_TOOLS[@]}"; do
  if ! jq -e --arg t "$tool" '.tools[] | select(.name == $t and .available == true)' "$json" >/dev/null; then
    echo "FAIL: required tool missing: $tool" >&2
    exit 1
  fi
done
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `health#report_*` / `vim.health.report_*` | `vim.health.start()/ok()/warn()/error()` | Deprecated in local runtime docs by Neovim 0.12-era runtime. `[CITED: /usr/share/nvim/runtime/doc/deprecated.txt]` | Use the modern API in `lua/config/health.lua` only. `[CITED: /usr/share/nvim/runtime/doc/deprecated.txt]` |
| Thinking of `:checkhealth` as message output | Treating `:checkhealth` as a generated buffer plus progress messages | Reflected in local runtime implementation. `[CITED: /usr/share/nvim/runtime/lua/vim/health.lua]` | Artifact capture should read buffer lines, not stdout text. `[CITED: /usr/share/nvim/runtime/lua/vim/health.lua]` |

**Deprecated/outdated:**
- `core/health.lua`’s ripgrep description still references `fzf-lua`, which is outdated for this repo after the `snacks.nvim` migration. `[VERIFIED: .config/nvim/lua/core/health.lua; VERIFIED: .config/nvim/lua/plugins/snacks.lua]`

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Neovim | Phase 9 capture/provider work | ✓ | `0.12.1` | — |
| tmux | BUG-019 verification | ✓ | `3.6a` | Manual note only if interactive check unavailable |
| git | Required-tool health gate | ✓ | `2.53.0` | None |
| rg | Required-tool health gate | ✓ | `15.1.0` | None |
| xdg-open | BUG-020 Linux diagnosis | ✓ | `1.2.1` | None on Linux; use direct `vim.ui.open()` diagnosis first |
| jq | Structured validator parsing | ✓ | `1.8.1` | Python/json.tool only for pretty-print, not equivalent fail gate |

**Missing dependencies with no fallback:** None on this machine. `[VERIFIED: local command probes]`

**Missing dependencies with fallback:** None on this machine. `[VERIFIED: local command probes]`

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Shell harness + headless Neovim commands. `[VERIFIED: scripts/nvim-validate.sh]` |
| Config file | none — validator behavior is encoded in `scripts/nvim-validate.sh`. `[VERIFIED: scripts/nvim-validate.sh]` |
| Quick run command | `./scripts/nvim-validate.sh health` during 9-02 and `./scripts/nvim-validate.sh checkhealth` during 9-01. `[VERIFIED: 09-CONTEXT.md; VERIFIED: scripts/nvim-validate.sh]` |
| Full suite command | `./scripts/nvim-validate.sh all`. `[VERIFIED: scripts/nvim-validate.sh; VERIFIED: 09-CONTEXT.md]` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| HEAL-01 | No config-caused `ERROR:` lines remain in headless `:checkhealth` output. `[VERIFIED: .planning/REQUIREMENTS.md]` | headless integration | `./scripts/nvim-validate.sh checkhealth` | ❌ Wave 0 |
| HEAL-02 | Required vs optional findings are clearly separated in repo-owned health output. `[VERIFIED: .planning/REQUIREMENTS.md]` | interactive + headless | `nvim --headless ... require("config.health").check()` is possible, but primary human check is `:checkhealth config`. `[CITED: /usr/share/nvim/runtime/doc/health.txt]` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `./scripts/nvim-validate.sh health` for 9-02 and `./scripts/nvim-validate.sh checkhealth` for 9-01 once added. `[VERIFIED: scripts/nvim-validate.sh; VERIFIED: 09-CONTEXT.md]`
- **Per wave merge:** `./scripts/nvim-validate.sh all`. `[VERIFIED: scripts/nvim-validate.sh]`
- **Phase gate:** `all` must pass, plus interactive tmux verification for BUG-019 and an explicit BUG-020 outcome record. `[VERIFIED: 09-CONTEXT.md; VERIFIED: FAILURES.md]`

### Wave 0 Gaps
- [ ] `scripts/nvim-validate.sh checkhealth` — missing command and artifact write path for HEAL-01. `[VERIFIED: scripts/nvim-validate.sh; VERIFIED: 09-CONTEXT.md]`
- [ ] `.config/nvim/lua/config/health.lua` — missing provider for HEAL-02. `[VERIFIED: .config/nvim/lua; VERIFIED: 09-CONTEXT.md]`
- [ ] `core.health` exports for `probe_tool` / `probe_plugin` — missing shared interface for 9-02. `[VERIFIED: .config/nvim/lua/core/health.lua]`

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Not applicable to local editor health reporting. `[ASSUMED]` |
| V3 Session Management | no | Not applicable to local editor health reporting. `[ASSUMED]` |
| V4 Access Control | no | Repo code runs inside user-owned editor session; no auth boundary is introduced in Phase 9. `[ASSUMED]` |
| V5 Input Validation | yes | Quote paths and keep artifact writes fixed to `.planning/tmp/nvim-validate/`. `[VERIFIED: scripts/nvim-validate.sh]` |
| V6 Cryptography | no | No cryptographic behavior in scope. `[ASSUMED]` |

### Known Threat Patterns for this phase

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Shell/path injection in validator command construction | Tampering | Keep file paths fixed and repo-local; avoid interpolating arbitrary user input into the command string. `[VERIFIED: scripts/nvim-validate.sh]` |
| False-negative health capture | Repudiation | Capture the full health buffer as an artifact instead of ephemeral progress text. `[CITED: /usr/share/nvim/runtime/lua/vim/health.lua]` |
| Misclassifying optional tools as required | Denial of Service | Limit hard failure to `git` and `rg` only. `[VERIFIED: 09-CONTEXT.md]` |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | ASVS V2/V3/V4/V6 are not materially applicable to this local-editor health phase. | Security Domain | Low — affects only documentation framing, not implementation. |

## Open Questions

None. The remaining unknowns are execution-time findings for the first `checkhealth` audit and BUG-020 root cause, both already scoped to 9-01. `[VERIFIED: 09-CONTEXT.md; VERIFIED: FAILURES.md]`

## Sources

### Primary (HIGH confidence)
- `.planning/phases/09-health-signal-cleanup/09-CONTEXT.md` - locked implementation decisions and plan split.
- `.planning/phases/06-runtime-failure-inventory/FAILURES.md` - BUG-019 and BUG-020 status and prior validation evidence.
- `.planning/phases/06-runtime-failure-inventory/CHECKLIST.md` - interactive repro/verification steps for tmux and external-open.
- `scripts/nvim-validate.sh` - current validator structure and command surface.
- `.config/nvim/lua/core/health.lua` - current probe implementation and tool metadata.
- `.config/nvim/lua/core/open.lua` - current `vim.ui.open()` handling.
- `.config/nvim/lua/core/keymaps/registry.lua` - current external-open mapping.
- `.config/.tmux.conf` - current tmux navigation bindings.
- `/usr/share/nvim/runtime/doc/health.txt` - official local runtime docs for custom health providers and `vim.health`.
- `/usr/share/nvim/runtime/lua/vim/health.lua` - local runtime implementation showing buffer-based report generation.
- `/usr/share/nvim/runtime/doc/deprecated.txt` - local runtime deprecation mapping for old health APIs.

### Secondary (MEDIUM confidence)
- Local headless Neovim probes run on 2026-04-22 - confirmed `redir` only captured progress text in this environment and exposed `FileType` side effects.

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - all recommendations are grounded in repo files and local Neovim runtime docs.  
- Architecture: HIGH - plan split and tier ownership are explicitly constrained by `09-CONTEXT.md` and current code layout.  
- Pitfalls: HIGH - each pitfall is backed by repo artifacts or direct local probe behavior.

**Research date:** 2026-04-22  
**Valid until:** 2026-05-22
