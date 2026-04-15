---
phase: 04-tooling-and-ecosystem-modernization
plan: 01
subsystem: LSP and Mason
tags: [neovim, lsp, mason, tooling, modernization]
provides: 0.11-native LSP baseline with vim.lsp.config()/vim.lsp.enable()
affects: .config/nvim/lua/plugins/lsp.lua, .config/nvim/lua/core/health.lua
key-files:
  created: []
  modified:
    - .config/nvim/lua/plugins/lsp.lua
    - .config/nvim/lua/core/health.lua
key-decisions:
  - "Neovim 0.11-native LSP registration using vim.lsp.config() + vim.lsp.enable() — removes lspconfig[server].setup() pattern"
  - "Separated LSP server IDs from Mason tool names into distinct tables (lsp_servers vs mason_tools)"
  - "Preserved attach.apply_lsp() for centralized keymap ownership"
  - "Added missing LSP servers to health metadata (eslint_d, ts_ls, jdtls, texlab)"
requirements-completed: [PLUG-02, TOOL-02]
duration: 10 min
completed: 2026-04-15T12:10:00Z
---

## Phase 04 Plan 01: Modernize LSP and Mason Architecture

**Objective:** Migrate Neovim config to 0.11-native LSP registration model, remove 0.10 compatibility branching, and preserve Mason-first provisioning.

## Tasks Completed

### Task 1: Migrate lsp.lua to 0.11-native server registration

**Files modified:** `.config/nvim/lua/plugins/lsp.lua`

- Replaced `vim.fn.has("nvim-0.11")` branching with direct 0.11 APIs
- Replaced `require("lspconfig")[server].setup(server)` with `vim.lsp.config(server, opts)` + `vim.lsp.enable(server)`
- Split server definitions into `lsp_servers` table (distinct from mason_tools)
- Preserved `attach.apply_lsp(event.buf)` call for central keymap ownership
- Kept blink.cmp capability extension with corrected variable naming
- Maintained diagnostics config, document highlights, inlay hints, and fidget support

**Verification:**
```bash
rg -n 'vim\.lsp\.config|vim\.lsp\.enable' .config/nvim/lua/plugins/lsp.lua  # 2 matches found
! rg -n 'has\("nvim-0\.11"\)|require\("lspconfig"\)\[[^]]+\]\.setup' .config/nvim/lua/plugins/lsp.lua  # none found
./scripts/nvim-validate.sh startup  # PASS
./scripts/nvim-validate.sh smoke     # PASS
```

### Task 2: Align health metadata with new LSP/Mason baseline

**Files modified:** `.config/nvim/lua/core/health.lua`

- Added tool metadata for newly declared LSP servers: eslint_d, ts_ls, jdtls, texlab
- All tools referenced in lsp.lua now have corresponding health entries with install hints
- Validation harness remains repo-owned and unchanged

**Verification:**
- Health metadata now covers all LSP servers and formatters declared in modernized lsp.lua

## Deviations

None — plan executed exactly as written.

## Self-Check: PASSED

- [x] lsp.lua contains vim.lsp.config() and vim.lsp.enable()
- [x] No 0.10 compatibility branching in active LSP path
- [x] attach.apply_lsp() preserved for central keymap ownership
- [x] lsp_servers and mason_tools are distinct data structures
- [x] start/startup.sh exits 0 after migration
- [x] smoke validation passes