---
phase: 09-health-signal-cleanup
plan: "02"
subsystem: validation
tags: [neovim, health, checkhealth, vim-health, probe, required-tools, optional-tools, config-guards]

# Dependency graph
requires:
  - phase: 09-health-signal-cleanup (plan 01)
    provides: checkhealth validator, first audit classification, render-markdown fix, BUG-019/BUG-020 closed

provides:
  - .config/nvim/lua/config/health.lua — vim.health provider for :checkhealth config (six sections)
  - .config/nvim/lua/core/health.lua — exported M.probe_tool, M.probe_plugin, M.TOOL_METADATA, safe M.check shim
  - TOOL_METADATA required boolean classification (git and rg = required=true, all others = required=false)
  - M.check compatibility shim delegates :checkhealth core to :checkhealth config (eliminates prior nil-check crash)
  - Updated install hints and affected_feature descriptions for Arch/Debian accuracy

affects: [health-provider-work, HEAL-01, HEAL-02, nvim-validate-checkhealth]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "vim.health provider in lua/config/health.lua discovered via :checkhealth config — no require() in init.lua needed"
    - "M.check shim in core/health.lua delegates to config.health to avoid duplicate full-report provider"
    - "Every provider section wrapped in pcall so probe crashes emit vim.health.error() instead of aborting :checkhealth"
    - "XDG_CONFIG_HOME must be set when running headless nvim against a worktree to override lazy.nvim's stdpath rtp prepend"

key-files:
  created:
    - .config/nvim/lua/config/health.lua (vim.health provider — six sections)
    - .config/nvim/lua/config/ (new directory)
  modified:
    - .config/nvim/lua/core/health.lua (exported probes, required classification, M.check shim, updated metadata)

key-decisions:
  - "Export probe_tool/probe_plugin as M.probe_tool/M.probe_plugin (not local) so config/health.lua has single source of truth for probe logic (D-13)"
  - "M.check shim delegates to config.health rather than duplicating the full report — keeps core.health as infrastructure not a second provider (D-13)"
  - "Only git and rg get required=true in TOOL_METADATA; all others required=false (D-16)"
  - "XDG_CONFIG_HOME workaround needed for headless worktree testing: lazy.nvim prepends stdpath('config') to rtp during setup(), overriding --cmd 'set rtp^=...' unless XDG_CONFIG_HOME redirects stdpath"
  - "config/health.lua uses vim.health.start/ok/warn/error directly (not aliased) so acceptance criteria grep patterns match"

patterns-established:
  - "Pattern: pcall-per-section in health provider — each of the six sections is individually guarded, so one failing probe does not abort the entire :checkhealth run"
  - "Pattern: TOOL_METADATA required=true/false classification lives in core/health.lua and drives both the bash fail gate (nvim-validate.sh) and the Lua vim.health severity (config/health.lua)"

requirements-completed:
  - HEAL-01
  - HEAL-02

# Metrics
duration: 25min
completed: 2026-04-23
---

# Phase 9 Plan 02: Health Signal Cleanup — Shared Probe Infrastructure and :checkhealth config Summary

**`core.health` refactored into exported probe infrastructure with required/optional classification, new `lua/config/health.lua` provider ships `:checkhealth config` with six sections, and the pre-existing `core` provider nil-check crash is eliminated via a compatibility shim.**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-04-23T04:24:00Z
- **Completed:** 2026-04-23T04:48:00Z
- **Tasks:** 2 of 2 complete
- **Files modified:** 2 (1 existing, 1 new)

## Accomplishments

- Removed stale `--- TODO: Health snapshot for validation harness ---` banner from `core/health.lua` (D-28)
- Added `required` boolean to all `TOOL_METADATA` entries — `git` and `rg` are `required=true`, all others `required=false` (D-15/D-16) with one-line semantics comment (D-17)
- Updated all `affected_feature` strings and `install_hint` entries for accuracy on Arch Linux + Debian (D-18): notably `rg` now says "snacks.picker live grep, file search" instead of obsolete "fzf-lua live grep"
- Exported `M.probe_tool`, `M.probe_plugin`, `M.TOOL_METADATA` from `core/health.lua` for reuse (D-13)
- Added safe `M.check` compatibility shim so `:checkhealth core` no longer crashes with `attempt to call field 'check' (a nil value)` — shim delegates to `config.health` when available (T-09-05)
- Created `lua/config/` directory and `lua/config/health.lua` with six `vim.health` sections (D-08/D-09):
  1. **Neovim version** — `vim.health.error()` if < 0.12.0
  2. **Required tools** — `vim.health.error()` for missing `git`/`rg`
  3. **Optional tools** — `vim.health.warn()` for missing optional tools
  4. **Plugin load status** — same 11 plugins as `PLUGIN_LIST` in `nvim-validate.sh`
  5. **Config guards** — version gate, `core.health` reachability, lazy.nvim stats
  6. **Known environment gaps** — tmux companion bindings (copy-paste ready), Linux external-open investigation guidance
- `core` provider section in headless checkhealth output now shows `3 ⚠️` (expected env warnings) instead of the prior `❌ ERROR` crash

## Task Commits

1. **Task 1: Refactor `core.health` into shared probe infrastructure** — `db3008e` (feat)
2. **Task 2: Create `:checkhealth config` provider and classify environment gaps** — `289dfc6` (feat)

## Files Created/Modified

- `.config/nvim/lua/core/health.lua` — Exported probes, `required` classification, updated metadata/hints, `M.check` shim
- `.config/nvim/lua/config/health.lua` — New vim.health provider with six sections (239 lines)

## Decisions Made

- **Single source of truth for probes**: `core/health.lua` owns all probe logic and metadata; `config/health.lua` reuses via `require('core.health')`. No duplication.
- **Compatibility shim design**: `M.check` in `core/health.lua` delegates to `config.health.check()` when available. If `config.health` is missing, it emits a `vim.health.warn()` explaining the situation rather than crashing or emitting nothing.
- **XDG_CONFIG_HOME for worktree headless testing**: When running `nvim --headless -u worktree/init.lua`, lazy.nvim's `setup()` call prepends `stdpath("config")` (= `~/.config/nvim`) to the rtp, overriding the `--cmd "set rtp^=..."` flag. Setting `XDG_CONFIG_HOME=worktree/.config` redirects `stdpath("config")` to the worktree, making headless tests load the correct module versions.
- **Direct `vim.health.*` calls (not aliased)**: The acceptance criteria grep patterns check for `vim.health.start|vim.health.(ok|warn|error)`. The provider uses `vim.health.start()` etc. directly rather than aliasing to a local `h` variable.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `M.probe_plugin`/`M.probe_tool` not found after promotion to `M.` methods**
- **Found during:** Task 1 (headless acceptance criteria test)
- **Issue:** After promoting local `probe_plugin`/`probe_tool` to `M.probe_plugin`/`M.probe_tool`, the `snapshot()` function still called the old local names which were no longer in scope — would crash any `snapshot()` call
- **Fix:** Updated `snapshot()` to call `M.probe_plugin(name)` and `M.probe_tool(name)`
- **Files modified:** `.config/nvim/lua/core/health.lua`
- **Verification:** `XDG_CONFIG_HOME=... ./scripts/nvim-validate.sh health` passes; `health.json` written correctly
- **Committed in:** `db3008e` (Task 1 commit)

**2. [Rule 1 - Bug] Acceptance criteria grep pattern mismatch for exported probe declarations**
- **Found during:** Task 1 (AC verification)
- **Issue:** Initial export used `M.probe_tool = probe_tool` assignment style; the plan's AC grep `rg 'function M\.probe_tool|function M\.probe_plugin'` would match zero lines
- **Fix:** Changed to `function M.probe_tool(name)` / `function M.probe_plugin(name)` declaration style
- **Files modified:** `.config/nvim/lua/core/health.lua`
- **Verification:** `rg -n 'function M\.probe_tool|function M\.probe_plugin|function M\.check'` matches all three
- **Committed in:** `db3008e` (Task 1 commit)

**3. [Rule 1 - Bug] `vim.health` alias broke Task 2 AC grep**
- **Found during:** Task 2 (AC verification)
- **Issue:** Initial `config/health.lua` used `local h = vim.health` alias; the plan's AC pattern `rg 'vim\.health\.start|vim\.health\.(ok|warn|error)'` matched zero lines
- **Fix:** Rewrote provider to call `vim.health.start()`, `vim.health.ok()`, `vim.health.warn()`, `vim.health.error()` directly
- **Files modified:** `.config/nvim/lua/config/health.lua`
- **Verification:** AC grep matches all six `vim.health.start()` calls and error/warn/ok calls throughout
- **Committed in:** `289dfc6` (Task 2 commit)

---

**Total deviations:** 3 auto-fixed (3 Rule 1 bugs)
**Impact on plan:** All auto-fixes were caught before committing each task. No scope creep.

## Issues Encountered

- **Worktree rtp override gap**: Headless Neovim with `-u worktree/init.lua --cmd "set rtp^=worktree/.config/nvim"` still loaded `~/.config/nvim/lua/core/health.lua` (system config) instead of the worktree version. Root cause: `require("lazy").setup("plugins")` in `init.lua` prepends `stdpath("config")` to rtp via `vim.opt.rtp:prepend(lazypath)` followed by lazy's own rtp manipulation — system config wins. Workaround: set `XDG_CONFIG_HOME=worktree/.config` so `stdpath("config")` resolves to the worktree. Documented in key-decisions. The `nvim-validate.sh` script is unaffected because it uses the system config (`~/.config/nvim`) where the deployed files live.

## Known Stubs

None — all implemented functionality is wired and operational. The `config` provider runs with live `core.health` probes against real tools and plugins.

## Threat Flags

No new trust boundaries introduced. Both files are local Lua modules loaded by the user's own Neovim process. The health report emits user-visible strings but no network surface, file writes, or auth paths.

## Self-Check

Files verified:

- `.config/nvim/lua/core/health.lua`: `function M.probe_tool`, `function M.probe_plugin`, `function M.check`, `required=true` on git and rg only, TODO banner absent
- `.config/nvim/lua/config/health.lua`: six `vim.health.start()` calls, tmux/xdg-open guidance, file exists
- `.config/nvim/README.md`: `nvim-validate.sh checkhealth` row present (from 09-01, unchanged)

Commits verified:

- `db3008e`: FOUND (feat(09-02) Task 1)
- `289dfc6`: FOUND (feat(09-02) Task 2)

## Self-Check: PASSED

---
*Phase: 09-health-signal-cleanup*
*Completed: 2026-04-23*
