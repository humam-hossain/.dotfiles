# Pitfalls Research

**Domain:** Cross-platform Neovim configuration modernization
**Researched:** 2026-04-14
**Confidence:** HIGH

## Critical Pitfalls

### Pitfall 1: Scattered Keymaps and Behavior Ownership

**What goes wrong:**  
Mappings live in core and plugin files, behavior overlaps, and fixing one interaction causes regressions elsewhere.

**Why it happens:**  
Configs grow incrementally; each new plugin adds “just a few” mappings.

**How to avoid:**  
Move all custom mappings into one registry, group by domain, and expose plugin actions through named command helpers.

**Warning signs:**  
Same prefix means different things, duplicated mappings, hard-to-find quit/save behavior.

**Phase to address:**  
Phase 1 or Phase 2.

---

### Pitfall 2: Platform-Specific Shell Assumptions

**What goes wrong:**  
Config works on Linux but fails on Windows because it assumes `xdg-open`, POSIX paths, or Unix-only binaries.

**Why it happens:**  
Most Neovim examples are Linux/macOS-first.

**How to avoid:**  
Create one portability layer; prefer `vim.ui.open()` and platform-aware helper functions.

**Warning signs:**  
Literal `xdg-open`, slash-specific path handling, binary names hardcoded in several files.

**Phase to address:**  
Phase 1.

---

### Pitfall 3: LSP Setup Frozen on Older Patterns

**What goes wrong:**  
Config continues using older setup patterns while Mason/LSP ecosystem shifts toward Neovim 0.11-native APIs.

**Why it happens:**  
LSP examples change gradually and old configs keep “working enough.”

**How to avoid:**  
Decide explicit baseline: either stay intentionally on older compatibility line or migrate to 0.11-native `vim.lsp.config` approach.

**Warning signs:**  
Mixed old/new API usage, ambiguous Mason behavior, setup code copied from older starter templates.

**Phase to address:**  
Phase 3.

---

### Pitfall 4: Plugin Audit Without Safety Net

**What goes wrong:**  
Plugin replacements break startup, commands, or completion behavior with no fast way to catch regressions.

**Why it happens:**  
Cleanup work removes plugins faster than validation improves.

**How to avoid:**  
Define smoke-test commands first, then refactor plugin sets in bounded slices.

**Warning signs:**  
Frequent “open Neovim and hope,” unexplained startup failures, lockfile churn without documented rationale.

**Phase to address:**  
Phase 2.

---

### Pitfall 5: Over-Customized Quit/Save Semantics

**What goes wrong:**  
Core editing flow becomes fragile; saving or closing one buffer can exit the whole editor unexpectedly.

**Why it happens:**  
Multiple autocmds and custom smart-quit logic stack up without a clear lifecycle model.

**How to avoid:**  
Simplify buffer/window semantics, define expected behaviors explicitly, then test against common workflows.

**Warning signs:**  
Confusion between tabs/buffers/windows, hidden writes, smart-quit branching that is hard to reason about.

**Phase to address:**  
Phase 1.

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Keep plugin config where it was first added | Fast local change | Architectural sprawl | Only temporarily during migration |
| Use shell commands directly in keymaps | Quick feature | Breaks portability | Rarely |
| Add more autocmds to paper over behavior bugs | Fast symptom relief | Hidden interactions and write bugs | Never as final fix |
| Keep stale plugins to avoid work | Short-term stability illusion | Ongoing maintenance drag | Never for long-lived config |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| `noice.nvim` | Misconfigure lazy event or ignore its experimental API caveats | Use documented `event = "VeryLazy"` and keep lualine integration guarded |
| Mason + LSP | Mix old handler-heavy setup with new 0.11 expectations | Choose explicit version strategy and follow official pattern |
| OS open handlers | Call `xdg-open` directly | Prefer `vim.ui.open()` |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Too many always-on UI plugins | Slow or noisy startup | Use lazy events, profile after cleanup | Noticeable as plugin count grows |
| Autosave on too many events | Frequent unexpected writes, sluggish editing | Reduce autocmd surface and add explicit conditions | Breaks during normal editing, not just scale |
| Plugin duplication of same capability | Startup cost and mapping conflicts | Make one canonical choice per domain | Immediately |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Shell-string command execution | Argument injection / path bugs | Use list-style commands or Neovim APIs |
| Blind writes on every buffer event | Unintended file modification | Restrict autosave conditions |
| Trusting plugin updates without review | Unexpected behavior changes | Pin lockfile, upgrade intentionally, smoke-test |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Inconsistent quit semantics | Editor feels broken and unpredictable | Make buffer/window lifecycle explicit |
| Too many mnemonic-less mappings | User forgets and avoids features | Group and document keymaps |
| Fancy UI before stability | Looks nice, feels fragile | Stabilize core workflows first |

## "Looks Done But Isn't" Checklist

- [ ] **Cross-platform support:** Linux and Windows both verified, not just guarded in theory
- [ ] **Keymap centralization:** no leftover custom maps hidden in plugin files
- [ ] **Plugin audit:** every plugin has keep/remove/replace rationale
- [ ] **Save/quit fixes:** tested with multiple buffers, splits, tabs, modified files
- [ ] **LSP modernization:** verified against actual Neovim baseline and plugin versions

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Broken startup after plugin cleanup | MEDIUM | revert last slice, run headless sync + health, reintroduce change incrementally |
| Broken quit/save semantics | MEDIUM | isolate core keymaps/autocmds, define expected matrix, patch behavior first |
| Windows portability break | HIGH | route failing action through platform helper, remove direct shell assumptions |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Scattered keymaps | Phase 2 | all custom mappings originate from central registry |
| Platform-specific shell assumptions | Phase 1 | open/path commands work on Linux and Windows |
| LSP setup frozen on older patterns | Phase 3 | chosen Neovim/LSP baseline documented and working |
| Plugin audit without safety net | Phase 2 | headless smoke tests documented before big replacements |
| Over-customized quit/save semantics | Phase 1 | multi-buffer quit/save scenarios behave as expected |

## Sources

- `.planning/codebase/CONCERNS.md`
- `.planning/codebase/CONVENTIONS.md`
- https://github.com/folke/noice.nvim
- https://github.com/mason-org/mason-lspconfig.nvim
- https://neovim.io/doc/user/lua.html

---
*Pitfalls research for: cross-platform Neovim configuration modernization*
*Researched: 2026-04-14*
