# Phase 1: Reliability and Portability Baseline - Research

**Researched:** 2026-04-14
**Domain:** Cross-platform Neovim runtime behavior
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Buffer, Window, and Tab Model
- **D-01:** The config is buffer-first. Buffer close actions should operate on the current buffer, not implicitly on windows or the full Neovim session.
- **D-02:** Windows are layout only. Split/window management should stay separate from buffer lifecycle behavior.
- **D-03:** Tabs are explicit workspaces and must never be touched by normal buffer-close shortcuts unless the user invokes tab-specific commands directly.

### Close Semantics
- **D-04:** `<C-q>` should close the current buffer only.
- **D-05:** `<C-q>` must never implicitly exit the full Neovim session.
- **D-06:** If the current buffer has unsaved changes, close behavior should respect normal save/confirm behavior rather than force-discarding or silently quitting.

### Autosave Policy
- **D-07:** Autosave should be minimal rather than aggressive.
- **D-08:** Autosave should be limited to conservative, safe cases such as `FocusLost`, not on every `BufLeave`, `TextChanged`, or `InsertLeave`.
- **D-09:** Autosave must be restricted to normal file buffers and must not write special, unsupported, or transient buffers.

### External Open Behavior
- **D-10:** External open behavior should use one OS-aware helper that opens with the system default application.
- **D-11:** The same helper should be shared by core keymaps and neo-tree actions so behavior stays consistent across entry points.
- **D-12:** The helper should describe generic external opening, not browser-specific behavior.

### Claude's Discretion
- Exact helper/module placement for OS-aware open behavior
- Exact buffer-safety guards for autosave exclusions
- Exact user-facing keymap descriptions and command naming, as long as they preserve the decisions above

### Deferred Ideas (OUT OF SCOPE)
None - discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PLAT-01 | User can start the same config successfully on Arch Linux without Linux-specific runtime errors | Replace hardcoded `xdg-open` call sites with one `vim.ui.open()` helper and document Linux smoke checks. [VERIFIED: `.config/nvim/lua/core/keymaps.lua`, `.config/nvim/lua/plugins/neotree.lua`, `/usr/share/nvim/runtime/doc/lua.txt`] |
| PLAT-02 | User can start the same config successfully on Debian/Ubuntu without distro-specific runtime errors | Same Phase 1 portability helper removes distro-specific shell assumptions from open actions. [VERIFIED: `.config/nvim/lua/core/keymaps.lua`, `.config/nvim/lua/plugins/neotree.lua`] |
| PLAT-03 | User can start the same config successfully on Windows without shell/path/open-command failures | `vim.ui.open()` maps to `explorer.exe` on Windows and is the built-in cross-platform open API. [CITED: `/usr/share/nvim/runtime/doc/lua.txt`, `/usr/share/nvim/runtime/doc/news-0.10.txt`] |
| PLAT-04 | User-facing open/path/shell actions use OS-aware helpers instead of hardcoded platform-specific commands | Centralize external open behind one helper under `lua/core/` and reuse it from keymaps and neo-tree. [VERIFIED: `01-CONTEXT.md`, `.config/nvim/lua/core/keymaps.lua`, `.config/nvim/lua/plugins/neotree.lua`] |
| CORE-01 | User can save and quit the current buffer/window without Neovim unexpectedly closing the full session | Use `:confirm bdelete` for buffer close and leave window/tab/session exit on explicit commands only. [CITED: `/usr/share/nvim/runtime/doc/editing.txt`, `/usr/share/nvim/runtime/doc/windows.txt`, `/usr/share/nvim/runtime/doc/options.txt`] |
| CORE-02 | User can move between buffers, windows, and tabs with behavior that is consistent and documented | Neovim treats tab pages as collections of windows; closing the last window in a tab closes that tab, so normal buffer-close shortcuts must not operate by closing windows. [CITED: `/usr/share/nvim/runtime/doc/tabpage.txt`, `/usr/share/nvim/runtime/doc/windows.txt`] |
| CORE-03 | User can edit normal files without autosave/autowrite logic unexpectedly writing unsupported or special buffers | Restrict autosave to `FocusLost` and guard against non-normal `buftype` values such as `nofile`, `nowrite`, `prompt`, `quickfix`, and `terminal`. [CITED: `/usr/share/nvim/runtime/doc/options.txt`] |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- Keep one shared config repo; do not split per OS. [VERIFIED: `AGENTS.md`, `CLAUDE.md`]
- Keep OS-specific behavior guarded inside config code. [VERIFIED: `AGENTS.md`]
- Respect the existing Neovim structure: `init.lua` loads `core.options`, `core.keymaps`, then `lazy.nvim` plugin specs under `lua/plugins/`. [VERIFIED: `.config/nvim/init.lua`, `CLAUDE.md`]
- Prefer aggressive cleanup over preserving fragile legacy behavior. [VERIFIED: `AGENTS.md`]
- Treat install/update scripts in `arch/` and `ubuntu/` as part of rollout reality when validation notes mention machine updates. [VERIFIED: `CLAUDE.md`, `AGENTS.md`]
- Follow the repo commit convention `[UPDATE] description` if this research is committed. [VERIFIED: `CLAUDE.md`] 

## Summary

Phase 1 does not need new plugins. The standard stack is already in the repo and in Neovim itself: use built-in `vim.ui.open()` for external open behavior, built-in `:confirm` plus `:bdelete` semantics for buffer closing, and one guarded `FocusLost` autosave path for normal file buffers only. [CITED: `/usr/share/nvim/runtime/doc/lua.txt`, `/usr/share/nvim/runtime/doc/editing.txt`, `/usr/share/nvim/runtime/doc/windows.txt`, `/usr/share/nvim/runtime/doc/options.txt`]

The current code violates the phase decisions in exactly the places the orchestrator flagged. `<C-q>` branches across `close`, `bdelete`, and `quit`; autosave writes on `FocusLost`, `BufLeave`, `TextChanged`, and `InsertLeave`; and both core keymaps and neo-tree hardcode `xdg-open`. [VERIFIED: `.config/nvim/lua/core/keymaps.lua`, `.config/nvim/lua/plugins/neotree.lua`] The plan should therefore be surgical: add one shared helper, replace the close mapping with buffer-first semantics, remove aggressive autosave events, and write a small smoke matrix for Linux and Windows. [VERIFIED: `01-CONTEXT.md`, `.planning/ROADMAP.md`]

**Primary recommendation:** Use one `lua/core/` portability helper around `vim.ui.open()`, bind `<C-q>` to a confirmable buffer delete instead of a quit state machine, and reduce autosave to a single guarded `FocusLost` autocmd. [VERIFIED: `01-CONTEXT.md`; CITED: `/usr/share/nvim/runtime/doc/lua.txt`, `/usr/share/nvim/runtime/doc/editing.txt`, `/usr/share/nvim/runtime/doc/options.txt`]

## Standard Stack

### Core

| Library / API | Version | Purpose | Why Standard |
|---------------|---------|---------|--------------|
| Neovim built-in `vim.ui.open()` | Available since Neovim 0.10; workspace has `NVIM v0.12.1` | Open files, directories, and URLs with the OS default handler | It already abstracts macOS `open`, Windows `explorer.exe`, and Linux `xdg-open`. [CITED: `/usr/share/nvim/runtime/doc/news-0.10.txt`, `/usr/share/nvim/runtime/doc/lua.txt`; VERIFIED: `nvim --version`] |
| Neovim built-in `:confirm` + `:bdelete` | Built-in | Buffer-first close semantics that respect unsaved changes | `:confirm` explicitly works with `:bdelete`, and `:bdelete` removes the buffer without turning normal buffer-close into session quit. [CITED: `/usr/share/nvim/runtime/doc/editing.txt`, `/usr/share/nvim/runtime/doc/windows.txt`] |
| Repo-local shared helper in `lua/core/` | New module for this phase | Single entry point for external open behavior reused by keymaps and neo-tree | Both call sites already live in modules that can `require(...)` shared core code without changing repo architecture. [VERIFIED: `.config/nvim/init.lua`, `.config/nvim/lua/core/keymaps.lua`, `.config/nvim/lua/plugins/neotree.lua`, `01-CONTEXT.md`] |

### Supporting

| Library / API | Version | Purpose | When to Use |
|---------------|---------|---------|-------------|
| `nvim-neo-tree/neo-tree.nvim` | `v3.x` branch in repo config | File tree action integration | Keep the custom action surface, but route custom open commands through the shared helper instead of `jobstart({ "xdg-open", ... })`. [VERIFIED: `.config/nvim/lua/plugins/neotree.lua`; CITED: `https://github.com/nvim-neo-tree/neo-tree.nvim`] |
| `moll/vim-bbye` via bufferline | Present in lockfile and `bufferline.lua` | Existing alternate buffer deletion path | Audit whether Phase 1 should align bufferline close behavior with the new buffer-close policy; do not leave `<C-q>` and bufferline using different close models. [VERIFIED: `.config/nvim/lua/plugins/bufferline.lua`, `.config/nvim/lazy-lock.json`] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `vim.ui.open()` | Hardcoded `vim.fn.jobstart({ "xdg-open", path })` or shell `!xdg-open` | Hardcoded shell commands fail the Windows requirement and duplicate OS dispatch logic. [VERIFIED: `.config/nvim/lua/core/keymaps.lua`, `.config/nvim/lua/plugins/neotree.lua`; CITED: `/usr/share/nvim/runtime/doc/lua.txt`] |
| `:confirm bdelete` | Custom "smart quit" branching on window count and buffer count | The current branching already reaches `quit`, which conflicts with locked decision D-05. [VERIFIED: `.config/nvim/lua/core/keymaps.lua`, `01-CONTEXT.md`] |
| One guarded `FocusLost` autocmd | `autowriteall` or multiple write-related autocmds | `autowriteall` is broader than the locked policy, and aggressive autocmds are already the source of fragility. [CITED: `/usr/share/nvim/runtime/doc/options.txt`; VERIFIED: `.config/nvim/lua/core/keymaps.lua`, `.planning/codebase/CONCERNS.md`] |

**Installation:** No new third-party package is required for Phase 1; this phase should prefer built-in Neovim APIs and repo-local Lua modules. [CITED: `/usr/share/nvim/runtime/doc/lua.txt`, `/usr/share/nvim/runtime/doc/editing.txt`; VERIFIED: `.config/nvim/init.lua`]

## Architecture Patterns

### Recommended Project Structure

```text
.config/nvim/lua/
+-- core/
|   +-- options.lua        # editor defaults
|   +-- keymaps.lua        # central keymaps and autocmd policy
|   `-- platform.lua       # shared OS-aware open helper for Phase 1
`-- plugins/
    `-- neotree.lua        # plugin-specific mappings that call core helper
```

This keeps policy in `core/` and plugin wiring in `plugins/`, which matches the repo's current architecture. [VERIFIED: `.config/nvim/init.lua`, `.config/nvim/lua/core/keymaps.lua`, `.config/nvim/lua/plugins/neotree.lua`, `AGENTS.md`]

### Pattern 1: Shared External-Open Helper

**What:** Put all external open behavior behind one helper that takes a path or URL and delegates to `vim.ui.open()`. [CITED: `/usr/share/nvim/runtime/doc/lua.txt`]
**When to use:** Any keymap, neo-tree command, or future command that opens a file, directory, or URL outside Neovim. [VERIFIED: `.config/nvim/lua/core/keymaps.lua`, `.config/nvim/lua/plugins/neotree.lua`]
**Example:**

```lua
-- Source: /usr/share/nvim/runtime/doc/lua.txt
vim.ui.open("https://neovim.io/")
vim.ui.open("~/path/to/file")
```

### Pattern 2: Buffer-First Close Command

**What:** Make `<C-q>` close the current buffer, not the current window or session. Use `:confirm bdelete` so modified buffers ask before discard. [CITED: `/usr/share/nvim/runtime/doc/editing.txt`, `/usr/share/nvim/runtime/doc/windows.txt`, `/usr/share/nvim/runtime/doc/options.txt`]
**When to use:** Normal user intent is "close what I am editing now" while keeping windows and tabs as separate concepts. [VERIFIED: `01-CONTEXT.md`]
**Example:**

```lua
-- Source: /usr/share/nvim/runtime/doc/editing.txt and repo keymap style
vim.keymap.set("n", "<C-q>", "<cmd>confirm bdelete<CR>", {
	desc = "Close current buffer",
})
```

### Pattern 3: Conservative Autosave

**What:** Keep one `FocusLost` autocmd and gate it so only normal file buffers are written. [VERIFIED: `01-CONTEXT.md`, `.planning/codebase/CONCERNS.md`; CITED: `/usr/share/nvim/runtime/doc/options.txt`]
**When to use:** Phase 1 only. This matches the locked policy to stay minimal and avoid hidden writes on navigation events. [VERIFIED: `01-CONTEXT.md`]
**Example:**

```lua
-- Source: repo autocmd style plus buftype rules from /usr/share/nvim/runtime/doc/options.txt
vim.api.nvim_create_autocmd("FocusLost", {
	callback = function()
		if vim.bo.buftype == "" and vim.bo.modified then
			vim.cmd("silent! write")
		end
	end,
})
```

### Anti-Patterns to Avoid

- **Linux-only shell opens:** Current `!xdg-open %:p` and `jobstart({ "xdg-open", node.path })` are exactly the hardcoded assumptions this phase is supposed to remove. [VERIFIED: `.config/nvim/lua/core/keymaps.lua`, `.config/nvim/lua/plugins/neotree.lua`]
- **Quit state machines in one mapping:** A single mapping should not decide between `close`, `bdelete`, and `quit`; that conflates buffer, window, and session lifecycles. [VERIFIED: `.config/nvim/lua/core/keymaps.lua`, `01-CONTEXT.md`; CITED: `/usr/share/nvim/runtime/doc/tabpage.txt`] 
- **Autosave on navigation/edit churn:** `BufLeave`, `InsertLeave`, and delayed `TextChanged` writes are broader than the locked policy and can hit unsupported buffers. [VERIFIED: `.config/nvim/lua/core/keymaps.lua`, `.planning/codebase/CONCERNS.md`; CITED: `/usr/share/nvim/runtime/doc/options.txt`] 

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Cross-platform external open | A manual OS switch around `xdg-open`, `explorer`, and shell escaping | `vim.ui.open()` | Neovim already ships the platform dispatch and `gx` uses it by default. [CITED: `/usr/share/nvim/runtime/doc/lua.txt`, `/usr/share/nvim/runtime/doc/various.txt`] |
| Safe modified-buffer close | A custom confirm dialog or force-delete mapping | `:confirm bdelete` | Built-in confirmation already supports `:bdelete` and preserves normal save/abandon behavior. [CITED: `/usr/share/nvim/runtime/doc/editing.txt`, `/usr/share/nvim/runtime/doc/windows.txt`] |
| Autosave policy | Several overlapping autocmds plus deferred writes | One guarded `FocusLost` autocmd | Multiple write paths are the current fragility source and are hard to reason about. [VERIFIED: `.config/nvim/lua/core/keymaps.lua`, `.planning/codebase/CONCERNS.md`] |

**Key insight:** Phase 1 should delete custom behavior, not add more of it. The safe path is to lean harder on Neovim's built-ins and reduce the number of lifecycle branches. [CITED: `/usr/share/nvim/runtime/doc/lua.txt`, `/usr/share/nvim/runtime/doc/editing.txt`; VERIFIED: `.config/nvim/lua/core/keymaps.lua`]

## Common Pitfalls

### Pitfall 1: Buffer Close Accidentally Becomes Session Quit

**What goes wrong:** The current `<C-q>` mapping reaches `quit` when there is one listed buffer and one window. [VERIFIED: `.config/nvim/lua/core/keymaps.lua`]
**Why it happens:** The mapping is counting windows and buffers and deciding lifecycle behavior in one place. [VERIFIED: `.config/nvim/lua/core/keymaps.lua`]
**How to avoid:** Make `<C-q>` always mean "delete current buffer with confirmation if needed" and keep explicit window/tab/session exits on separate commands. [VERIFIED: `01-CONTEXT.md`; CITED: `/usr/share/nvim/runtime/doc/editing.txt`, `/usr/share/nvim/runtime/doc/windows.txt`, `/usr/share/nvim/runtime/doc/tabpage.txt`]
**Warning signs:** Any branch in the final implementation that still calls `quit`, `quitall`, or `close` from the normal buffer-close mapping. [VERIFIED: `01-CONTEXT.md`, `.config/nvim/lua/core/keymaps.lua`]

### Pitfall 2: Special Buffers Get Autosaved

**What goes wrong:** Non-file buffers can be hit by broad write hooks, especially on `BufLeave`, `InsertLeave`, or `TextChanged`. [VERIFIED: `.config/nvim/lua/core/keymaps.lua`, `.planning/codebase/CONCERNS.md`]
**Why it happens:** The current policy spreads writes across four events, while Neovim documents several `buftype` values that are not normal files. [VERIFIED: `.config/nvim/lua/core/keymaps.lua`; CITED: `/usr/share/nvim/runtime/doc/options.txt`]
**How to avoid:** Guard writes with a normal-buffer predicate and keep the event surface minimal. [VERIFIED: `01-CONTEXT.md`; CITED: `/usr/share/nvim/runtime/doc/options.txt`]
**Warning signs:** Autosave code that does not explicitly check `buftype` before writing. [VERIFIED: `.config/nvim/lua/core/keymaps.lua`] 

### Pitfall 3: Two Different Buffer-Close Models Survive Phase 1

**What goes wrong:** Keymaps may switch to built-in `bdelete` semantics while bufferline still uses `Bdelete!`, producing inconsistent behavior for modified buffers. [VERIFIED: `.config/nvim/lua/plugins/bufferline.lua`, `.config/nvim/lazy-lock.json`]
**Why it happens:** Bufferline already routes close buttons through `vim-bbye`, but the current keyboard close mapping is custom Lua. [VERIFIED: `.config/nvim/lua/plugins/bufferline.lua`, `.config/nvim/lua/core/keymaps.lua`]
**How to avoid:** Decide in the plan whether Phase 1 standardizes on built-in `bdelete` everywhere or preserves `vim-bbye` intentionally with matching confirm semantics. [VERIFIED: `.config/nvim/lua/plugins/bufferline.lua`, `.planning/ROADMAP.md`]
**Warning signs:** Mouse-close and keyboard-close behave differently on modified buffers or when multiple windows show the same buffer. [VERIFIED: `.config/nvim/lua/plugins/bufferline.lua`, `.config/nvim/lua/core/keymaps.lua`] 

## Code Examples

Verified patterns from official sources:

### Open with System Default Application

```lua
-- Source: /usr/share/nvim/runtime/doc/lua.txt
vim.ui.open("https://neovim.io/")
vim.ui.open("~/path/to/file")
```

### Confirm a Potentially Destructive Buffer Command

```vim
" Source: /usr/share/nvim/runtime/doc/editing.txt
:confirm bdelete
```

### Buffer Delete Semantics

```vim
" Source: /usr/share/nvim/runtime/doc/windows.txt
:bdelete
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Shell `xdg-open` calls in mappings | `vim.ui.open()` | Neovim 0.10 added `vim.ui.open()` and wired `gx` to it. [CITED: `/usr/share/nvim/runtime/doc/news-0.10.txt`, `/usr/share/nvim/runtime/doc/various.txt`] | Removes OS-specific branching from config code. |
| No override for open backend | `vim.ui.open(..., { cmd = ... })` when needed | Neovim 0.11 added `opt.cmd`. [CITED: `/usr/share/nvim/runtime/doc/news-0.11.txt`, `/usr/share/nvim/runtime/doc/lua.txt`] | Gives a future escape hatch without changing every call site. |

**Deprecated/outdated:**

- Hardcoded `xdg-open` in keymaps and neo-tree commands is outdated for a cross-platform Neovim 0.10+ baseline. [VERIFIED: `.config/nvim/lua/core/keymaps.lua`, `.config/nvim/lua/plugins/neotree.lua`; CITED: `/usr/share/nvim/runtime/doc/news-0.10.txt`] 
- Event-heavy autosave meshes are outdated for this phase because the locked decisions explicitly reject aggressive autosave. [VERIFIED: `01-CONTEXT.md`, `.config/nvim/lua/core/keymaps.lua`] 

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A practical "normal file buffer" predicate should include at least `buftype == ""`; adding `modifiable` and non-empty filename checks is likely useful but should be validated against actual plugin buffers in this config. [ASSUMED] | Architecture Patterns / Common Pitfalls | Medium - autosave may still hit an edge-case buffer or may skip a valid buffer unexpectedly. |

## Open Questions

1. **Should Phase 1 standardize buffer close on built-in `:bdelete` only, or also rework bufferline's `Bdelete!` path now?**
   What we know: bufferline already depends on `vim-bbye` and uses `Bdelete! %d` for close actions. [VERIFIED: `.config/nvim/lua/plugins/bufferline.lua`, `.config/nvim/lazy-lock.json`]
   What's unclear: whether the planner wants Phase 1 to keep that plugin behavior as-is or collapse all close actions onto one model immediately. [VERIFIED: `.planning/ROADMAP.md`]
   Recommendation: treat this as an explicit planning decision inside Plan 01-02 so keyboard and mouse close behavior do not diverge. [VERIFIED: `.planning/ROADMAP.md`]

2. **What is the minimum Windows validation environment for this dotfiles repo?**
   What we know: Neovim treats Windows 64-bit on Windows 10 Version 2004+ as Tier 1 support. [CITED: `/usr/share/nvim/runtime/doc/support.txt`]
   What's unclear: whether the maintainer's actual Windows target has PowerShell, explorer integration, and the same install/update script coverage as Linux. [VERIFIED: `AGENTS.md`, `CLAUDE.md`; ASSUMED]
   Recommendation: keep Phase 1 smoke notes manual and explicit rather than pretending the current repo already has Windows automation. [VERIFIED: `.planning/ROADMAP.md`, `CLAUDE.md`] 

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `nvim` | All smoke validation for this phase | Yes | `NVIM v0.12.1` | None. [VERIFIED: `nvim --version`] |
| `git` | Existing lazy bootstrap and repo workflows | Yes | `git version 2.53.0` | None. [VERIFIED: `git --version`, `.config/nvim/init.lua`] |
| `rg` | Existing search workflows and likely smoke checks | Yes | `ripgrep 15.1.0` | Use `grep` if needed. [VERIFIED: `rg --version`, `AGENTS.md`] |
| Windows shell tooling (`powershell` / `pwsh`) in this Linux workspace | Manual cross-platform verification notes only | No | - | Validate on an actual Windows machine. [VERIFIED: `command -v powershell`, `command -v pwsh`] |

**Missing dependencies with no fallback:**

- None for planning. Actual Windows runtime verification still requires a Windows machine. [VERIFIED: `.planning/ROADMAP.md`, `AGENTS.md`]

**Missing dependencies with fallback:**

- PowerShell is not installed in this Linux workspace, so Windows smoke steps must remain documented/manual until Phase 3 or v2 automation work. [VERIFIED: `command -v powershell`, `command -v pwsh`, `.planning/ROADMAP.md`] 

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Shell-driven Neovim headless smoke checks, no test framework committed yet. [VERIFIED: `find .config/nvim -maxdepth 3 ...` returned no tests; `.planning/codebase/CONCERNS.md`] |
| Config file | none - see Wave 0. [VERIFIED: repo scan] |
| Quick run command | `nvim --headless "+qa"` on a normal machine; in locked-down environments, redirect writable XDG state/cache paths if needed. [VERIFIED: local command run; CITED: `/usr/share/nvim/runtime/doc/support.txt`] |
| Full suite command | `nvim --headless "+checkhealth" "+qa"` plus manual Linux and Windows interaction smoke steps. [VERIFIED: `.planning/ROADMAP.md`; CITED: `/usr/share/nvim/runtime/doc/news.txt`] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PLAT-01 | Startup on Arch Linux without Linux-only runtime failures | smoke | `nvim --headless "+qa"` | No - Wave 0 |
| PLAT-02 | Startup on Debian/Ubuntu without distro-only runtime failures | smoke | `nvim --headless "+qa"` | No - Wave 0 |
| PLAT-03 | Windows open/path/shell behavior avoids hardcoded command failures | manual smoke | `manual-only` | No - Wave 0 |
| PLAT-04 | All user-facing open actions use shared helper | grep + smoke | `rg -n "xdg-open|explorer|jobstart\\(" .config/nvim` | No - Wave 0 |
| CORE-01 | Closing current buffer never exits full session unexpectedly | manual smoke | `manual-only` | No - Wave 0 |
| CORE-02 | Buffer/window/tab behavior stays consistent and documented | manual smoke | `manual-only` | No - Wave 0 |
| CORE-03 | Autosave ignores unsupported buffers and only writes safe normal buffers | manual smoke | `manual-only` | No - Wave 0 |

### Sampling Rate

- **Per task commit:** `nvim --headless "+qa"` [VERIFIED: `.planning/ROADMAP.md`]
- **Per wave merge:** `nvim --headless "+checkhealth" "+qa"` plus one manual interaction pass. [VERIFIED: `.planning/ROADMAP.md`]
- **Phase gate:** Linux and Windows smoke matrix completed before `/gsd-verify-work`. [VERIFIED: `.planning/ROADMAP.md`, `AGENTS.md`]

### Wave 0 Gaps

- [ ] Add a committed smoke script or README snippet so validation is not tribal knowledge. [VERIFIED: no tests or smoke scripts found]
- [ ] Add a documented manual matrix for: startup, `<C-q>` on modified/unmodified buffers, split close, tab isolation, core open action, neo-tree open action. [VERIFIED: `.planning/ROADMAP.md`, `01-CONTEXT.md`]
- [ ] Decide whether validation commands should set temporary XDG state/cache dirs in CI-like environments. Current sandbox runs showed write-path noise under the real home directory. [VERIFIED: local `nvim --headless` and `nvim --headless '+checkhealth' '+qa'` runs] 

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | n/a for this phase. [VERIFIED: phase scope in `.planning/ROADMAP.md`] |
| V3 Session Management | no | n/a for this phase. [VERIFIED: phase scope in `.planning/ROADMAP.md`] |
| V4 Access Control | no | n/a for this phase. [VERIFIED: phase scope in `.planning/ROADMAP.md`] |
| V5 Input Validation | yes | Pass paths/URLs through `vim.ui.open()` or list-style command args; do not shell-interpolate user-controlled paths. [CITED: `/usr/share/nvim/runtime/doc/lua.txt`; VERIFIED: `.planning/codebase/CONCERNS.md`] |
| V6 Cryptography | no | n/a for this phase. [VERIFIED: phase scope in `.planning/ROADMAP.md`] |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Shell-string command execution for external open | Tampering | Use `vim.ui.open()` or argument-array command APIs only. [CITED: `/usr/share/nvim/runtime/doc/lua.txt`; VERIFIED: `.planning/codebase/CONCERNS.md`] |
| Hidden writes to special buffers | Tampering | Restrict autosave to normal file buffers and keep event surface minimal. [CITED: `/usr/share/nvim/runtime/doc/options.txt`; VERIFIED: `.planning/codebase/CONCERNS.md`, `01-CONTEXT.md`] |
| Buffer-close shortcut exits the whole editor | Denial of Service | Remove `quit` branches from normal buffer-close behavior. [VERIFIED: `.config/nvim/lua/core/keymaps.lua`, `01-CONTEXT.md`] |

## Sources

### Primary (HIGH confidence)

- `/usr/share/nvim/runtime/doc/lua.txt` - `vim.ui.open()` semantics and examples
- `/usr/share/nvim/runtime/doc/news-0.10.txt` - `vim.ui.open()` introduction
- `/usr/share/nvim/runtime/doc/news-0.11.txt` - `vim.ui.open({ cmd = ... })`
- `/usr/share/nvim/runtime/doc/editing.txt` - `:confirm`, `ZZ`, `ZQ`, quit behavior
- `/usr/share/nvim/runtime/doc/windows.txt` - `:bdelete` semantics and hidden-buffer behavior
- `/usr/share/nvim/runtime/doc/options.txt` - `autowrite`, `autowriteall`, `buftype`, `confirm`
- `/usr/share/nvim/runtime/doc/tabpage.txt` - tab pages are collections of windows
- `/usr/share/nvim/runtime/doc/various.txt` - `gx` mapped to `vim.ui.open()`
- `/usr/share/nvim/runtime/doc/support.txt` - supported platform matrix
- `https://github.com/nvim-neo-tree/neo-tree.nvim` - v3.x custom commands and mappings

### Secondary (MEDIUM confidence)

- `.planning/phases/01-reliability-and-portability-baseline/01-CONTEXT.md` - locked decisions and canonical references
- `.planning/ROADMAP.md` - phase scope and plan split
- `.planning/REQUIREMENTS.md` - required outcomes
- `.planning/codebase/CONCERNS.md` - known autosave and portability risks
- `.config/nvim/lua/core/keymaps.lua` - current failure modes
- `.config/nvim/lua/plugins/neotree.lua` - current Linux-only open behavior
- `.config/nvim/lua/plugins/bufferline.lua` - existing `vim-bbye` close path
- `.config/nvim/init.lua` - module loading pattern

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - built mostly from official Neovim docs and direct repo inspection.
- Architecture: HIGH - matches existing repo boundaries and locked phase decisions.
- Pitfalls: HIGH - current code already exhibits the failure modes the docs warn about.

**Research date:** 2026-04-14
**Valid until:** 2026-05-14
