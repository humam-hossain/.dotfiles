# Testing Patterns

**Analysis Date:** 2026-04-14

## Test Framework

**Runner:**
- None found in `.config/nvim`
- No `tests/`, no `spec/`, no Lua test harness, no CI config in this subtree

**Assertion Library:**
- None found

**Run Commands:**
```bash
# No project-local automated test commands found for `.config/nvim`
```

## Test File Organization

**Location:**
- No test files found under `.config/nvim`

**Naming:**
- No established naming pattern

**Structure:**
```text
.config/nvim/
  init.lua
  lua/
    core/
    plugins/
# No colocated or separate test tree present
```

## Test Structure

**Suite Organization:**
- Not established

**Patterns:**
- Current validation is likely manual: open Neovim, sync plugins, exercise mappings/features
- `lazy-lock.json` suggests stability comes from pinned plugin revisions rather than automated tests

## Mocking

**Framework:**
- None found

**Patterns:**
- Not established

**What to Mock:**
- If tests are added later, external plugin APIs, Neovim API calls, and shell integrations (`xdg-open`, formatter binaries, LSP server presence) will need stubs or harness support

**What NOT to Mock:**
- Pure option tables and simple keymap declarations can be checked directly without deep mocks

## Fixtures and Factories

**Test Data:**
- None found

**Location:**
- None found

## Coverage

**Requirements:**
- No coverage target found

**Configuration:**
- None found

**View Coverage:**
```bash
# No coverage tooling configured
```

## Test Types

**Unit Tests:**
- Not present

**Integration Tests:**
- Not present

**E2E Tests:**
- Not present

## Common Patterns

**Current Practical Validation Path:**
```bash
nvim --headless "+Lazy! sync" +qa
nvim --headless "+checkhealth" +qa
```

**Manual Smoke Areas:**
- Startup without bootstrap errors
- LSP attach and Mason installs
- Save-format flow via `<C-s>` and `<leader>cf`
- Search/tree/navigation mappings from `fzf-lua`, `neo-tree`, `bufferline`, `ufo`

## Test Coverage Gaps

**Config Load Safety:**
- No automated proof that plugin configs compile on startup

**Keymap Behavior:**
- No regression checks for remaps, autosave, or plugin-dependent keybindings

**External Tool Assumptions:**
- No tests for missing binaries, non-Linux environments, or plugin dependency drift

---

*Testing analysis: 2026-04-14*
*Update when test patterns change*
