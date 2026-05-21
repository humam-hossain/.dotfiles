# Testing

**Analysis Date:** 2026-05-21

## Testing Strategy

**Approach:**
This codebase does **not** use a conventional test framework (no unit testing library, no test runner configuration). Quality assurance is achieved through:
1. **Headless Neovim validation harness** (`scripts/nvim-validate.sh`) — the primary quality enforcement mechanism
2. **Runtime failure auditing** (`scripts/nvim-audit-failures.sh`) — automated discovery and cataloging of runtime issues
3. **Health check infrastructure** (`lua/core/health.lua` + `lua/config/health.lua`) — structured diagnostics via `:checkhealth config`
4. **Defensive programming with guard clauses** — runtime checks baked into configuration (not test-driven but failure-resistant)
5. **Manual smoke testing** — users validate by opening Neovim and using features

**What is tested:**
- Neovim headless startup (no crash on `--headless +qa`)
- Plugin manager sync (`Lazy! sync` completes within 120s)
- High-risk plugin `require()` calls (each module loads without error)
- External tool availability (git, rg are required; formatters, LSP servers are optional)
- `:checkhealth` output (no unexpected ERROR lines)
- Keymap dispatcher string-action routing (three regression cases for feedkeys vs vim.cmd)
- Format-on-save guard function (nofile, unnamed, and acwrite buffer cases)

**What is NOT tested:**
- No unit tests for any Lua utility functions
- No integration tests for plugin interactions
- No E2E tests simulating actual editing workflows
- No CI pipeline — all validation is manual/on-demand
- No test coverage for platform install scripts (`arch/*.sh`, `debian/*.sh`, `ubuntu/*.sh`)
- No automated cross-platform testing (Linux only, no Windows or macOS CI)

## Test Types

### Headless Startup Smoke Test
- **File:** `scripts/nvim-validate.sh` — `cmd_startup()` (lines 108-133)
- **Approach:** Runs `nvim --headless` with the repo config, waits 50ms for `defer_fn`, exits via `qa!`
- **Pass criteria:** Exit code 0 AND no `Error|E5108|E484|stack traceback` in output
- **Report:** `startup.log` written to `.planning/tmp/nvim-validate/`

### Plugin Sync Test
- **File:** `scripts/nvim-validate.sh` — `cmd_sync()` (lines 139-170)
- **Approach:** Runs `nvim --headless` with `Lazy! sync`, 120s timeout
- **Pass criteria:** Exit code 0 (non-124 for timeout) AND no `Error|failed|stack traceback` in output
- **Report:** `sync.log` written to `.planning/tmp/nvim-validate/`

### Plugin Smoke Test
- **File:** `scripts/nvim-validate.sh` — `cmd_smoke()` (lines 365-426)
- **Approach:** `pcall(require, ...)` for 11 high-risk plugins: snacks, lualine, lspconfig, conform, nvim-treesitter.configs, blink.cmp, gitsigns, ufo, bufferline, which-key, render-markdown
- **Pass criteria:** All `pcall` calls succeed; writes `SMOKE_FAIL` file and exits 1 on any failure
- **Report:** `smoke.log` and optional `SMOKE_FAIL` marker file

### Health Snapshot Test
- **File:** `scripts/nvim-validate.sh` — `cmd_health()` (lines 176-255)
- **Approach:** Invokes `core.health.snapshot()` via headless nvim, writes `health.json`
- **Pass criteria:** JSON file exists, all plugins show `loaded=true`, required tools (git, rg) are available; missing optional tools generate warnings but do not fail
- **Report:** `health.json` written to `.planning/tmp/nvim-validate/`

### Checkhealth Test
- **File:** `scripts/nvim-validate.sh` — `cmd_checkhealth()` (lines 261-359)
- **Approach:** Headless `:checkhealth` captured to text file via `vim.health._check()` Lua API
- **Pass criteria:** No unexpected ERROR lines; tolerates known headless-only errors (highlighter, terminal graphics, mmdc tool, background job)
- **Report:** `checkhealth.txt` written to `.planning/tmp/nvim-validate/`

### Keymap Dispatcher Regression Test
- **File:** `scripts/nvim-validate.sh` — `cmd_keymaps()` (lines 432-545)
- **Approach:** Directly calls the string-action dispatch logic from `core.keymaps.lazy` with three probe cases: angle-bracket (`<cmd>enew<CR>`), keyseq (`<C-w>s`), colon-format (`:close<CR>`)
- **Pass criteria:** All three probes pass without error
- **Report:** `keymap-regression.log` written to `.planning/tmp/nvim-validate/`

### Format-on-Save Guard Regression Test
- **File:** `scripts/nvim-validate.sh` — `cmd_formats()` (lines 551-720)
- **Approach:** Creates test buffers with specific properties (nofile buftype, unnamed, acwrite), calls the `format_on_save` guard function from `conform.lua` directly
- **Pass criteria:** Case 1 (nofile → false), Case 2 (unnamed buffer → false), Case 3 (acwrite lua → `{timeout_ms=500, lsp_format="fallback"}`)
- **Report:** `format-regression.log` written to `.planning/tmp/nvim-validate/`

### Failure Audit
- **File:** `scripts/nvim-audit-failures.sh` (338 lines)
- **Approach:** Runs all validation checks, parses outputs, scans TODO/FIXME comments in Lua files, scans git log for bug-related commits; deduplicates and formats into FAILURES.md
- **Output:** `.planning/phases/06-runtime-failure-inventory/FAILURES.md`
- **Trigger:** Manual execution; requires `jq` dependency

## Test Framework

**Runner:**
- No standard test framework (no jest, vitest, pytest, etc.)
- Custom bash harness: `scripts/nvim-validate.sh` acts as both test runner and test orchestrator
- All tests run headless via `nvim --headless` with the repo config

**Configuration:**
- No test config files (no `jest.config.*`, `vitest.config.*`, `pytest.ini`, etc.)
- Validation config is hardcoded in `scripts/nvim-validate.sh` (lines 27-46): `PLUGIN_LIST`, `TOOL_LIST`, `TOOL_HINTS` associative array
- Plugin list must stay synchronized with the plugin list in `lua/config/health.lua` (documented via comment: "must match PLUGIN_LIST in scripts/nvim-validate.sh")

**Run Commands:**
```bash
./scripts/nvim-validate.sh all              # Run all validation checks (fail fast)
./scripts/nvim-validate.sh startup          # Quick startup smoke test only
./scripts/nvim-validate.sh health           # Health snapshot only
./scripts/nvim-validate.sh keymaps          # Keymap regression only
./scripts/nvim-validate.sh formats          # Format guard regression only
./scripts/nvim-audit-failures.sh            # Full failure audit + FAILURES.md generation
```

**Coverage Commands:**
```bash
scripts/nvim-validate.sh checkhealth        # Full :checkhealth report
```

## Test Coverage

**Areas with active coverage:**
| Area | Test | File |
|------|------|------|
| Neovim startup | Headless smoke test | `nvim-validate.sh` startup |
| Plugin manager sync | Lazy! sync with timeout | `nvim-validate.sh` sync |
| Plugin module loading | pcall-require smoke | `nvim-validate.sh` smoke |
| External tool availability | Health snapshot probe | `nvim-validate.sh` health |
| Config health | Structured `:checkhealth` | `nvim-validate.sh` checkhealth |
| Keymap dispatch logic | 3-case string-action probe | `nvim-validate.sh` keymaps |
| Format-on-save guards | 3-case buffer scenario probe | `nvim-validate.sh` formats |
| Runtime failures | Multi-source audit + catalog | `nvim-audit-failures.sh` |

**Areas lacking coverage:**
- **Lua utility functions**: `core/open.lua` (`M.open()`, `M.open_current_buffer()`), `core/keymaps/apply.lua` functions have no dedicated tests
- **Plugin configuration correctness**: No tests verify that plugin opts tables produce expected behavior
- **LSP server setup**: No test that LSP servers start or attach correctly
- **Treesitter parser installation**: No validation of parser availability or compatibility
- **Cross-platform behavior**: No Windows or macOS test runs
- **Script installation**: Platform install scripts (`arch/*.sh`, etc.) are never validated in CI
- **QML component rendering**: No visual or functional tests for QuickShell bar
- **Waybar scripts**: No tests for weather, network, memory, or alert scripts
- **Performance/latency**: No benchmarks or timeout-sensitive tests beyond the 120s Lazy sync limit

**Notable testing gaps:**
- No automated **regression test suite** that runs on every change
- No test for the **auto-save guard** logic in `core/keymaps.lua` (multi-condition FocusLost handler)
- No test for **health.lua snapshot** function beyond manual invocation
- No coverage of **error path behavior** (what happens when a tool is missing, a plugin fails, etc.)

## Quality Patterns

**Code Review:**
- No formal code review process detected — this is a personal dotfiles repo
- Cross-reference comment IDs (`D-04`, `D-08`, `D-11`, etc.) suggest design decisions are tracked, enabling self-review
- `AGENTS.md` contains the project's quality standards as documented GSD workflow constraints

**Verification Approaches:**
1. **Guard clause pattern** (defensive): Functions check preconditions at entry and return early. Example from `lsp.lua` LspAttach:
   ```lua
   local client = vim.lsp.get_client_by_id(event.data.client_id)
   if not client then return end
   if not vim.api.nvim_buf_is_valid(event.buf) then return end
   if buftype ~= "" then return end
   ```
2. **Headless validation harness**: All tests run non-interactively, suitable for manual or future automated execution
3. **Health check infrastructure**: Structured diagnostics at `:checkhealth config`, with `core.health.snapshot()` for machine-readable output
4. **Design decision documentation**: Inline `D-NNN` references trace implementation choices back to decisions, enabling impact analysis
5. **Fail-fast startup**: Critical failures (lazy.nvim clone failure) throw `error()` immediately rather than silently degrading

**Quality Automation:**
- **None** — no CI pipeline, no pre-commit hooks, no automated test execution
- All quality checks are **manual/on-demand** via `scripts/nvim-validate.sh` and `scripts/nvim-audit-failures.sh`
- `stylua` formatting is available via `conform.nvim` but is editor-triggered, not automated

**Linting:**
- No eslint, shellcheck, or other linter configuration found
- `.luarc.json` configures Lua language server with `LuaJIT` runtime and `vim` as a known global — this enables IDE diagnostics but is not a linting step
- `stylua` is available as a formatter but there is no `.stylua.toml` config file
- No shellcheck directives or configurations for shell scripts (despite 70+ `.sh` files)

**Shell Script Quality Patterns:**
- Consistent `set -euo pipefail` across all shell scripts (strict mode)
- `set -x` used in platform install scripts for traceability
- Variable quoting is generally correct but inconsistent — some scripts quote all variables, some do not
- Platform scripts (`arch/*.sh`) lack error handling — no `if [[ $? -ne 0 ]]` checks after `sudo pacman` commands
- No input validation in most shell scripts

---

*Testing analysis: 2026-05-21*
