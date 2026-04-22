# Phase 9: Health Signal Cleanup - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-22
**Phase:** 09-health-signal-cleanup
**Areas discussed:** Health audit starting point, Custom health provider, HEAL-02 classification approach, Open bugs BUG-019 and BUG-020

---

## Health Audit Starting Point

| Option | Description | Selected |
|--------|-------------|----------|
| Run :checkhealth headlessly | Capture current output before fixing — precise and reproducible | ✓ |
| Interactive session, manual notes | Developer runs :checkhealth live and documents manually | |
| Trust Phase 6 inventory as-is | Skip new audit; fix health-tagged FAILURES.md entries directly | |

**User's choice:** Run :checkhealth headlessly

---

| Option | Description | Selected |
|--------|-------------|----------|
| Extend nvim-validate.sh with 'checkhealth' subcommand | Consistent with Phase 6 harness pattern; Phase 10 builds on it | ✓ |
| Standalone script | New scripts/nvim-checkhealth.sh — cleaner separation but second harness entry | |

**User's choice:** Extend nvim-validate.sh

---

| Option | Description | Selected |
|--------|-------------|----------|
| Raw text capture + PASS/FAIL verdict | checkhealth.txt artifact + exit code on ERROR lines | ✓ |
| Structured JSON | Parse output into severity-grouped JSON | |
| Text capture only, no verdict | No PASS/FAIL exit code | |

**User's choice:** Raw text + PASS/FAIL

---

| Option | Description | Selected |
|--------|-------------|----------|
| All providers (:checkhealth no args) | Most comprehensive — catches all config-caused ERRORs | ✓ |
| Targeted providers only | Only plugins in active stack — faster but may miss providers | |

**User's choice:** All providers

---

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — add checkhealth after health in 'all' sequence | startup→sync→smoke→health→checkhealth | ✓ |
| No — standalone call only | Keep 'all' as startup/sync/smoke/health | |

**User's choice:** Yes, add to 'all' sequence

---

## Custom Health Provider

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — create vim.health provider | lua/config/health.lua; satisfies HEAL-02 via severity levels | ✓ |
| No — only fix plugin providers | No new module; classification in docs only | |

**User's choice:** Yes, create vim.health provider

---

| Option | Description | Selected |
|--------|-------------|----------|
| lua/health.lua at root (:checkhealth health) | Simple, no new directory | |
| lua/config/health.lua (:checkhealth config) | More descriptive; needs new lua/config/ directory | ✓ |

**User's choice:** :checkhealth config (lua/config/health.lua)

---

| Option | Description | Selected |
|--------|-------------|----------|
| Tools + plugins + config guards | Three sections; covers all HEAL-01/HEAL-02 signal types | ✓ |
| Tools only | Skip plugin/config sections | |
| Config guards only | Skip tool/plugin sections | |

**User's choice:** Tools + plugins + config guards

---

| Option | Description | Selected |
|--------|-------------|----------|
| Reuse core/health.lua probe functions | Export probe_tool/probe_plugin; DRY | ✓ |
| Duplicate probe logic in lua/health.lua | Self-contained but two implementations to sync | |

**User's choice:** Reuse via export

---

| Option | Description | Selected |
|--------|-------------|----------|
| Required vs optional tier in TOOL_METADATA | required boolean in core/health.lua; ERROR vs WARN | ✓ |
| Always WARN for tools | All missing tools are warnings; errors for config bugs only | |
| You decide | Claude picks threshold | |

**User's choice:** required boolean in TOOL_METADATA

---

| Option | Description | Selected |
|--------|-------------|----------|
| LSP server reachability + Neovim version | Checks pyright/gopls/lua-ls installed; Neovim >= 0.12 | ✓ |
| Full config invariant sweep | Also check lazy-lock, conform formatters, treesitter parsers | |

**User's choice:** LSP + Neovim version

---

| Option | Description | Selected |
|--------|-------------|----------|
| Export probe_tool/probe_plugin from core/health.lua | M.probe_tool = probe_tool etc. | ✓ |
| Inline probes in lua/health.lua | Self-contained; two implementations | |

**User's choice:** Export from core/health.lua

---

| Option | Description | Selected |
|--------|-------------|----------|
| :checkhealth health (lua/health.lua) | Simpler | |
| Rename to :checkhealth config (lua/config/health.lua) | More descriptive | ✓ |

**User's choice:** :checkhealth config

---

| Option | Description | Selected |
|--------|-------------|----------|
| pcall around all probe sections | Catches broken config state gracefully | ✓ |
| No pcall — trust probes | Simpler; traceback surfaces in :checkhealth | |

**User's choice:** pcall around all sections

---

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — known env warnings section with vim.health.warn() | BUG-019, BUG-020 shown inline with classification | ✓ |
| No — docs only | Keep :checkhealth config focused on config-checkable items | |

**User's choice:** Yes, inline env warning section

---

| Option | Description | Selected |
|--------|-------------|----------|
| Conditionally detect (show only if applicable) | Only show tmux warning if $TMUX set | |
| Always show all known warnings | Unconditional — simpler logic | ✓ |

**User's choice:** Always show

---

| Option | Description | Selected |
|--------|-------------|----------|
| Loaded only when :checkhealth runs | Default Neovim behavior — no startup cost | ✓ |
| Required in init.lua | Eager load — unnecessary for health providers | |

**User's choice:** Lazy (on-demand)

---

## HEAL-02 Classification Approach

| Option | Description | Selected |
|--------|-------------|----------|
| Health provider output self-sufficient | vim.health severity labels communicate classification | ✓ |
| README also documents classification | Adds README section explaining WARN vs ERROR | |

**User's choice:** Self-sufficient

---

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — FAILURES.md tracks HEAL-01/HEAL-02 closure | Move to Fixed/Closed after Phase 9 | ✓ |
| No — requirements tracked in REQUIREMENTS.md only | FAILURES.md is bug-only | |

**User's choice:** Yes, FAILURES.md tracks closure

---

| Option | Description | Selected |
|--------|-------------|----------|
| Fix config so plugin providers don't error | Treat plugin provider ERRORs as config bugs | ✓ |
| Document but don't fix | Classify as 'known upstream' | |
| Scope only to :checkhealth config | Ignore plugin provider ERRORs | |

**User's choice:** Fix our config

---

| Option | Description | Selected |
|--------|-------------|----------|
| Environment — parsers installed on demand | Treesitter warnings are not config regressions | |
| Config — ensure.installed should prevent missing parsers | Config bug if parsers missing | |
| You decide | Claude picks | ✓ |

**User's choice:** Claude's discretion (→ environment, classify as env warning)

---

| Option | Description | Selected |
|--------|-------------|----------|
| Plugin config pcall/nil guards that prevent ERRORs at health time | Config code path causes health ERROR due to unguarded call | ✓ |
| Version/capability guards | Guards for Neovim version-specific APIs | |

**User's choice:** pcall/nil guards for health-time errors

---

| Option | Description | Selected |
|--------|-------------|----------|
| 9-01: checkhealth subcommand + audit + fixes + BUG-019 + BUG-020; 9-02: health provider + TOOL_METADATA | Clean split: fix existing vs add new structure | ✓ |
| Merge into one plan | Single combined plan | |

**User's choice:** Separate plans (9-01 fixes, 9-02 provider)

---

| Option | Description | Selected |
|--------|-------------|----------|
| git and rg only | Minimal required set — both cause crash/fail if absent | ✓ |
| git, rg, node | node needed for ts-ls runtime | |
| You decide | Claude picks based on crash vs degrade | |

**User's choice:** git and rg only

---

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — same 11 plugins in both | PLUGIN_LIST in nvim-validate.sh matches health provider | ✓ |
| Health provider checks fewer | Only critical plugins | |

**User's choice:** Same 11 plugins

---

| Option | Description | Selected |
|--------|-------------|----------|
| .planning/tmp/nvim-validate/checkhealth.txt | Consistent with health.json pattern | ✓ |
| Phase dir or project root | Less consistent | |

**User's choice:** .planning/tmp/nvim-validate/checkhealth.txt

---

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — extend nvim-validate.sh health to check required tools | git and rg hardcoded in bash REQUIRED_TOOLS | ✓ |
| No — headless health stays plugin-only | Tools only in :checkhealth config interactive path | |

**User's choice:** Yes, extend health subcommand

---

| Option | Description | Selected |
|--------|-------------|----------|
| Only ERRORs cause FAIL | WARNINGs are expected; matches HEAL-01 intent | ✓ |
| Both ERRORs and WARNINGs cause FAIL | Stricter gate; high maintenance burden | |

**User's choice:** ERRORs only

---

| Option | Description | Selected |
|--------|-------------|----------|
| Stay in core/health.lua | Already there; minimal change | ✓ |
| Move to shared config module | More explicit separation | |

**User's choice:** Stay in core/health.lua

---

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — emit ERROR if below 0.11/0.12 | Catches version mismatch on new machines | |
| No — user responsibility | Skip version check | |

**User's choice:** Yes — version check (user noted: running 0.12.1; everything must work for 0.12.1)
**Notes:** Version guard threshold set to >= 0.12.0 based on user's actual version (0.12.1 on Arch Linux)

---

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — review and update hints for Arch + Neovim 0.12 | Ensure accuracy for primary platform | ✓ |
| No — hints are good enough | Not worth a review pass | |

**User's choice:** Yes, review and update

---

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — exact bind-key lines in warning message | Copy-paste ready from :checkhealth config | ✓ |
| Just describe, link to plugin README | Less convenient | |

**User's choice:** Yes, include exact lines

---

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — remove stale TODO comment | It's done and misleading | ✓ |
| Leave it | Not worth touching | |

**User's choice:** Remove stale TODO

---

| Option | Description | Selected |
|--------|-------------|----------|
| Both: capture artifact + inline PASS/FAIL | .planning/tmp/nvim-validate/checkhealth.txt + exit code | ✓ |
| Inline PASS/FAIL only | No artifact | |

**User's choice:** Both

---

| Option | Description | Selected |
|--------|-------------|----------|
| No — plain language, no BUG IDs | Health output is for maintainer at terminal; no internal tracking IDs | ✓ |
| Yes — include BUG IDs | Traceability to FAILURES.md | |

**User's choice:** Plain language, no BUG IDs

---

| Option | Description | Selected |
|--------|-------------|----------|
| Hardcode required tools in bash (git, rg) | Simple; no Lua interop | ✓ |
| Lua emits required list, bash reads it | DRY but complex | |

**User's choice:** Hardcode in bash

---

| Option | Description | Selected |
|--------|-------------|----------|
| No — complementary, not overlapping | Double signal for same issue is OK | ✓ |
| Yes — skip if lazy health already covered | Cross-provider state is fragile | |

**User's choice:** Complementary (no dedup)

---

| Option | Description | Selected |
|--------|-------------|----------|
| M.check = function() with vim.health.start() sections | Standard Neovim health API | ✓ |
| Other structure | Non-standard | |

**User's choice:** Standard M.check pattern

---

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — README validation commands table updated | Adds checkhealth subcommand row | ✓ |
| No — defer to Phase 11 | Avoid partial updates | |

**User's choice:** Yes, update README in Phase 9

---

## Open Bugs BUG-019 and BUG-020

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — add bind-key entries to .config/.tmux.conf in 9-01 | Small edit; straightforward; .tmux.conf is in repo | ✓ |
| No — document only, stay in health provider warning | Keep BUG-019 Open; user applies manually | |

**User's choice:** Fix in 9-01

---

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — investigate root cause and fix in Phase 9 | Three candidates: terminal, vim.ui.open, xdg-open | ✓ |
| No — defer to Phase 10 or 11 | BUG-020 is feature bug, not health issue | |

**User's choice:** Fix in Phase 9

---

| Option | Description | Selected |
|--------|-------------|----------|
| Both in 9-01 (with checkhealth audit + error fixes) | One 'fix all remaining open bugs' plan | ✓ |
| Separate 9-03 plan | Cleaner scope separation | |

**User's choice:** Both in 9-01

---

| Option | Description | Selected |
|--------|-------------|----------|
| Terminal key binding first | :verbose nmap <C-S-o> → vim.ui.open() test → xdg-open test | ✓ |
| xdg-open first | Test xdg-open in shell before Neovim | |
| vim.ui.open() first | Read error from Phase 8-02 hardening | |

**User's choice:** Terminal key binding first

---

| Option | Description | Selected |
|--------|-------------|----------|
| Remap to <leader>o | User specified: "if possible" | ✓ |
| Terminal-specific workaround | Configure terminal emulator to forward <C-S-o> | |
| You decide | Claude picks after investigation | |

**User's choice:** `<leader>o` if terminal strips `<C-S-o>`
**Notes:** `<leader>o` confirmed free in registry.lua

---

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — interactive tmux verification required | Reload tmux config + confirm pane crossing before marking Fixed | ✓ |
| No — code review sufficient | 4 bind-key lines are from README | |

**User's choice:** Yes, interactive verification required

---

| Option | Description | Selected |
|--------|-------------|----------|
| Separate task group after audit tasks | Clear sequence in 9-01 | ✓ |
| Interleaved with health fixes | Less structured | |

**User's choice:** Separate task group

---

## Claude's Discretion

- Exact headless nvim command to capture :checkhealth output
- Specific ERRORs found in audit and their fixes
- Treesitter missing parser warnings: classify as environment (on-demand install expected)
- Order of commits within each plan
- Whether lua/config/ directory needs other files
- TOOL_METADATA `required` comment wording

## Deferred Ideas

None — discussion stayed within phase scope.
