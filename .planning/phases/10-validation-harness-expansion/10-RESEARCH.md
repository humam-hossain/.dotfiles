# Phase 10: Validation Harness Expansion - Research

**Researched:** 2026-04-23
**Domain:** Neovim headless validation harness expansion for bug-prone flows
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### 10-01: Validator Alignment

- **D-01:** Audit PLUGIN_LIST, TOOL_LIST, and `all` sequence against v1.1 changes (pyright replacing basedpyright, neo-tree probe removed from health.lua in Phase 8). Fix any gaps found. Verified during discussion: PLUGIN_LIST and TOOL_LIST already look accurate, but the audit should confirm explicitly.
- **D-02:** Define artifact contract for 10-02 outputs in 10-01 before the regression scripts are written. New artifacts: `keymap-regression.log` and `format-regression.log` in `.planning/tmp/nvim-validate/` — consistent with `startup.log`, `smoke.log` naming.
- **D-03:** Remove stale `--- TODO: Format-on-save dispatcher` comment at line 1 of `.config/nvim/lua/plugins/conform.lua` as part of the alignment cleanup. No functional change.
- **D-04:** Fix README stale table (`.config/nvim/README.md` lines 323-327) — currently describes the Phase 3 `all` sequence (startup/sync/smoke/health only, missing `checkhealth`). Update to reflect the current `all` sequence including `checkhealth` and the new Phase 10 subcommands.

### 10-02: Regression Check Coverage

- **D-05:** Add `keymaps` subcommand to `nvim-validate.sh` — headlessly load the lazy.lua dispatcher and pcall-test it against each action string type that caused Phase 7 failures: `<cmd>...<CR>`, angle-bracket sequences (`<C-w>X`), and plain ex commands. Verify no errors thrown. Artifact: `keymap-regression.log`.
- **D-06:** Add `formats` subcommand to `nvim-validate.sh` — headlessly load conform.nvim and call the `format_on_save` guard function directly with mock buffer contexts (nofile buftype, acwrite buftype, empty buffer name). Verify the function returns the correct `false`/`{...}` values for each case. Artifact: `format-regression.log`. Direct function call — not BufWritePre headless trigger (too unreliable).
- **D-07:** LSP attach safety checks stay in CHECKLIST.md as manual steps — headless automation of pcall guard behavior in LSP attach autocmds is difficult to instrument reliably. These belong in a new "Phase 10 Regression Checks" section in `.planning/phases/06-runtime-failure-inventory/CHECKLIST.md`.
- **D-08:** CHECKLIST.md also gets a Phase 10 section as companion to the scripted checks — covers LSP attach safety and any other flows that the scripts don't reach.

### 10-02: Script Architecture

- **D-09:** New regression checks live as subcommands in `nvim-validate.sh` — consistent with Phase 9's `checkhealth` subcommand pattern, not a separate script. Single entrypoint for maintainers.
- **D-10:** `all` sequence extended to include new subcommands: startup → sync → smoke → health → checkhealth → keymaps → formats. Full pre-rollout gate in one command.
- **D-11:** Log file artifacts only: `keymap-regression.log` and `format-regression.log` in `$REPORT_DIR`. No JSON — these are simple pass/fail checks. Consistent with startup.log, smoke.log.

### 10-03: Triage Documentation

- **D-12:** TEST-03 artifact is a new "Reading validation output" section in `.config/nvim/README.md`. Explains what each artifact means, how to distinguish config bugs from env gaps (referencing the Phase 9 classification approach), and what action to take for each. No separate TRIAGE.md — README is the stable user-facing location.

### 10-04: Checkhealth Warning Fixes (New Plan)

- **D-13:** New plan 10-04 added to Phase 10. Phase 10 now has 4 plans.
- **D-14:** 10-04 starts with a fresh headless audit — run `./scripts/nvim-validate.sh checkhealth`, read `checkhealth.txt`, enumerate all WARN entries. User noted seeing overlapping keymap warnings and other warnings. Classify each: config-caused vs environment-only vs optional tool gap.
- **D-15:** Fix config-caused WARNINGs found in the audit. Environment-only or optional tool warnings → document as By Design / Won't Fix.
- **D-16:** FAILURES.md updated as warnings are resolved — consistent with Phase 6 D-12 (FAILURES.md is a living doc). Config-caused warnings that get fixed → Fixed. Environment-only → Won't Fix / By Design.

### Claude's Discretion

- Exact pcall-test patterns for the `keymaps` subcommand (which specific string values to exercise)
- Exact mock buffer context approach for the `formats` subcommand (buffer setup in headless Lua)
- Specific LSP attach safety scenarios to cover in CHECKLIST.md Phase 10 section
- README "Reading validation output" section placement within the file
- Order of commits within each plan

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TEST-01 | Maintainer can run repo validation commands to verify startup, plugin load, and health status before rollout. [VERIFIED: `.planning/REQUIREMENTS.md`] | Keep `scripts/nvim-validate.sh` as the single entrypoint, align `all` and README with the real sequence, and preserve artifact naming under `.planning/tmp/nvim-validate/`. [VERIFIED: `scripts/nvim-validate.sh`, `.config/nvim/README.md`, `10-CONTEXT.md`] |
| TEST-02 | Maintainer can reproduce and validate bug-prone keymap or plugin flows with scripts when `:checkhealth` is insufficient. [VERIFIED: `.planning/REQUIREMENTS.md`] | Add exactly two scripted blind-spot checks: lazy keymap dispatcher regression coverage and direct `format_on_save` guard coverage. Keep LSP attach in manual checklist because it is not a stable headless target. [VERIFIED: `.config/nvim/lua/core/keymaps/lazy.lua`, `.config/nvim/lua/plugins/conform.lua`, `10-CONTEXT.md`] |
| TEST-03 | Maintainer can inspect validation artifacts that clearly separate config regressions from external dependency gaps. [VERIFIED: `.planning/REQUIREMENTS.md`] | Add README triage guidance tied to existing artifacts (`startup.log`, `sync.log`, `smoke.log`, `health.json`, `checkhealth.txt`) plus the new regression logs. Reuse Phase 9 classification language instead of inventing a second taxonomy. [VERIFIED: `.config/nvim/README.md`, `.planning/phases/09-health-signal-cleanup/09-CONTEXT.md`, `scripts/nvim-validate.sh`] |
</phase_requirements>

## Summary

Phase 10 should extend the existing shell harness, not create a parallel validation system. The repo already has one authoritative entrypoint, `scripts/nvim-validate.sh`, with subcommands for `startup`, `sync`, `smoke`, `health`, `checkhealth`, and `all`; Phase 10 succeeds if it keeps that single-entrypoint model and only adds checks for flows `:checkhealth` cannot prove. [VERIFIED: `scripts/nvim-validate.sh`, `.planning/PROJECT.md`, `10-CONTEXT.md`]

The two proven blind spots are already constrained by the phase context and by repo code. First, the lazy keymap dispatcher still contains special handling for string actions, key notation, and ex commands, which is exactly the regression surface that caused Phase 7 failures. Second, `conform.nvim`'s `format_on_save` policy is a pure Lua guard function whose behavior depends on buffer state and is therefore testable directly without simulating actual save events. Those are good automation targets; LSP attach safety is not, so it stays in the manual checklist. [VERIFIED: `.config/nvim/lua/core/keymaps/lazy.lua`, `.config/nvim/lua/plugins/conform.lua`, `.planning/phases/06-runtime-failure-inventory/CHECKLIST.md`, `10-CONTEXT.md`]

Today’s repo state also shows alignment and documentation drift that planning should treat as first-class work, not cleanup trivia. The active harness already includes `checkhealth`, and newer README sections describe it, but the older Phase 3 table still documents an obsolete `all` sequence without `checkhealth`. A fresh local `checkhealth` artifact also still contains mixed warning/error output from config, optional tools, and environment-only providers, so the warning-fix plan must begin with a new classification pass rather than a hardcoded fix list copied from old notes. [VERIFIED: `.config/nvim/README.md`, `.planning/tmp/nvim-validate/checkhealth.txt`, `.planning/phases/09-health-signal-cleanup/09-CONTEXT.md`, `10-CONTEXT.md`]

**Primary recommendation:** Extend `scripts/nvim-validate.sh` with `keymaps` and `formats`, update `all` and README to match the true artifact contract, and treat `checkhealth` warning cleanup as a fresh classification-driven audit. [VERIFIED: `scripts/nvim-validate.sh`, `.config/nvim/README.md`, `10-CONTEXT.md`]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Validation command dispatch | Repo shell harness | Headless Neovim runtime | Subcommand orchestration, artifact paths, and pass/fail policy live in `scripts/nvim-validate.sh`; Neovim only executes probes. [VERIFIED: `scripts/nvim-validate.sh`] |
| Health/status validation | Headless Neovim runtime | Repo shell harness | `core.health.snapshot()` and `:checkhealth` own health signal generation; the shell wraps them and turns output into artifacts and exit codes. [VERIFIED: `scripts/nvim-validate.sh`, `.config/nvim/lua/config/health.lua`] |
| Keymap regression validation | Headless Neovim runtime | Repo shell harness | The bug-prone behavior is Lua dispatcher logic in `core/keymaps/lazy.lua`; bash should only launch and log the probe. [VERIFIED: `.config/nvim/lua/core/keymaps/lazy.lua`, `10-CONTEXT.md`] |
| Format-on-save guard regression validation | Headless Neovim runtime | Repo shell harness | The policy is encoded in `conform.lua` as a Lua function over buffer state, so the runtime owns assertions and bash owns lifecycle/logging. [VERIFIED: `.config/nvim/lua/plugins/conform.lua`, `10-CONTEXT.md`] |
| Triage guidance | README/docs | FAILURES.md | Maintainer-facing decision rules belong in README; historical issue disposition belongs in FAILURES.md. [VERIFIED: `.config/nvim/README.md`, `.planning/phases/06-runtime-failure-inventory/FAILURES.md`, `10-CONTEXT.md`] |

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `bash` script harness | repo-owned [VERIFIED: `scripts/nvim-validate.sh`] | Single validation entrypoint and artifact contract | The repo already standardizes on `cmd_*()` subcommands, `REPORT_DIR`, and fail-fast `all`; Phase 10 should extend this instead of introducing a second harness. [VERIFIED: `scripts/nvim-validate.sh`, `10-CONTEXT.md`] |
| Neovim headless runtime | `NVIM v0.12.2` on this machine [VERIFIED: `nvim --version`] | Executes startup, health, smoke, `:checkhealth`, and new regression probes | Headless Neovim is required because the target regressions live in Lua runtime behavior, not static text. [VERIFIED: `nvim --version`, `scripts/nvim-validate.sh`, `.config/nvim/lua/core/keymaps/lazy.lua`, `.config/nvim/lua/plugins/conform.lua`] |
| Repo health provider (`config.health` + `core.health`) | repo-owned [VERIFIED: `.config/nvim/lua/config/health.lua`] | First-line config/tool/environment diagnostics | Neovim’s official health API is explicitly designed for plugin/config checks, and this repo already uses it as the primary diagnostic contract. [CITED: https://neovim.io/doc/user/health/] [VERIFIED: `.config/nvim/lua/config/health.lua`, `.planning/PROJECT.md`] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `jq` | `jq-1.8.1` [VERIFIED: `jq --version`] | Pretty-print and query `health.json` | Use when structured JSON inspection is needed; the harness already falls back to `python3 -m json.tool` if `jq` is absent. [VERIFIED: `scripts/nvim-validate.sh`] |
| `python3` | `Python 3.14.4` [VERIFIED: `python3 --version`] | JSON pretty-print fallback | Only a fallback for `health.json`; not a primary validation dependency. [VERIFIED: `scripts/nvim-validate.sh`] |
| `timeout` | `GNU coreutils 9.10` [VERIFIED: `timeout --version`] | Bounds `Lazy! sync` runtime | Keep using it for sync on environments that provide GNU coreutils; document platform expectations explicitly. [VERIFIED: `scripts/nvim-validate.sh`] |
| `rg` | `15.1.0` [VERIFIED: `rg --version`] | Required search tool for repo workflows and health checks | Already classified as a required tool in health metadata; do not duplicate that logic elsewhere. [VERIFIED: `scripts/nvim-validate.sh`, `.config/nvim/lua/config/health.lua`, `.planning/tmp/nvim-validate/health.json`] |
| `git` | `2.53.0` [VERIFIED: `git --version`] | Required git workflow dependency | Already classified as required in health metadata; keep triage aligned with that classification. [VERIFIED: `scripts/nvim-validate.sh`, `.planning/tmp/nvim-validate/health.json`] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Add subcommands to `nvim-validate.sh` | Create a separate regression script | Rejected by locked decision D-09; separate scripts would duplicate artifact path logic and split the maintainer entrypoint. [VERIFIED: `10-CONTEXT.md`, `scripts/nvim-validate.sh`] |
| Direct Lua probe of `format_on_save` | Trigger real `BufWritePre` headlessly | Rejected by locked decision D-06; event-driven save simulation is less reliable than calling the guard function directly. [VERIFIED: `10-CONTEXT.md`, `.config/nvim/lua/plugins/conform.lua`] |
| Script LSP attach flows headlessly | Keep in checklist/manual verification | The context already marks LSP attach automation as difficult to instrument reliably; planner should not force brittle fake automation here. [VERIFIED: `10-CONTEXT.md`, `.planning/phases/06-runtime-failure-inventory/CHECKLIST.md`] |

**Installation:**
```bash
# No new package ecosystem is required for Phase 10.
# Work extends the existing repo-owned shell + Neovim validation stack.
```

## Architecture Patterns

### System Architecture Diagram

```text
Maintainer command
  |
  v
scripts/nvim-validate.sh <subcommand>
  |
  +--> startup/sync/smoke/health/checkhealth
  |      |
  |      v
  |    headless nvim loads repo config
  |      |
  |      +--> core.health snapshot -> health.json
  |      +--> :checkhealth providers -> checkhealth.txt
  |      +--> module probes/log output -> *.log
  |
  +--> keymaps (new)
  |      |
  |      v
  |    headless Lua probe -> lazy key dispatcher branches
  |      |
  |      v
  |    keymap-regression.log
  |
  +--> formats (new)
         |
         v
       headless Lua probe -> conform format_on_save guard branches
         |
         v
       format-regression.log

Artifacts in .planning/tmp/nvim-validate/
  |
  v
README triage guidance + FAILURES.md disposition updates
```

### Recommended Project Structure

```text
scripts/
├── nvim-validate.sh          # Single validation entrypoint

.config/nvim/lua/
├── core/keymaps/lazy.lua     # Dispatcher regression target
├── plugins/conform.lua       # format_on_save regression target
└── config/health.lua         # Primary health diagnostic surface

.planning/tmp/nvim-validate/
├── startup.log
├── sync.log
├── smoke.log
├── health.json
├── checkhealth.txt
├── keymap-regression.log     # New
└── format-regression.log     # New
```

### Pattern 1: Single Harness, Many Subcommands
**What:** Keep every automated regression check under `scripts/nvim-validate.sh` as a `cmd_*()` function with consistent artifact naming and fail-fast behavior. [VERIFIED: `scripts/nvim-validate.sh`, `10-CONTEXT.md`]
**When to use:** Any repo-owned automated validation added in v1.1 that is meant to be part of the pre-rollout gate. [VERIFIED: `.planning/PROJECT.md`, `10-CONTEXT.md`]
**Example:**
```bash
# Source: scripts/nvim-validate.sh
cmd_health || rc=$?
if [[ $rc -ne 0 ]]; then echo "==> all ABORTED at health" >&2; exit $rc; fi
```

### Pattern 2: Probe Logic in Lua, Orchestration in Bash
**What:** Let bash launch Neovim, create temp scripts, and manage exit codes; let Lua exercise the actual config code paths being validated. [VERIFIED: `scripts/nvim-validate.sh`] 
**When to use:** Any validation of runtime behavior that depends on Neovim APIs or plugin config state. [VERIFIED: `scripts/nvim-validate.sh`, `.config/nvim/lua/core/keymaps/lazy.lua`, `.config/nvim/lua/plugins/conform.lua`]
**Example:**
```lua
-- Source: https://neovim.io/doc/user/health/
local M = {}
M.check = function()
  vim.health.start("foo report")
  vim.health.ok("Setup is correct")
end
return M
```

### Pattern 3: Health First, Script Only the Blind Spots
**What:** Use `:checkhealth` and repo-owned health providers for environment/config diagnostics, and add custom scripts only when health cannot prove behavior. [CITED: https://neovim.io/doc/user/health/] [VERIFIED: `.planning/PROJECT.md`, `10-CONTEXT.md`]
**When to use:** Any future validation expansion in this repo. [VERIFIED: `.planning/PROJECT.md`]

### Anti-Patterns to Avoid

- **Separate regression harnesses:** Do not create `scripts/nvim-validate-keymaps.sh` or similar. It fragments the artifact contract and contradicts D-09. [VERIFIED: `10-CONTEXT.md`]
- **Event-simulation theater:** Do not fake `BufWritePre` or LSP attach just to claim automation coverage. The direct guard function is reliable; the attach path is not. [VERIFIED: `10-CONTEXT.md`, `.config/nvim/lua/plugins/conform.lua`]
- **Duplicate health taxonomy:** Do not invent new README labels that disagree with Phase 9’s config-vs-env-vs-optional classification. [VERIFIED: `.planning/phases/09-health-signal-cleanup/09-CONTEXT.md`, `.planning/phases/06-runtime-failure-inventory/FAILURES.md`] 
- **Static warning lists in docs:** Do not hardcode current warnings into README guidance. Warning inventories change; the doc should teach interpretation, not freeze a transient machine state. [VERIFIED: `.planning/tmp/nvim-validate/checkhealth.txt`, `10-CONTEXT.md`] 

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Health reporting | Custom text parser for all diagnostics | `:checkhealth` + repo `config.health` provider | Neovim already provides the standard reporting surface and section API. [CITED: https://neovim.io/doc/user/health/] [VERIFIED: `.config/nvim/lua/config/health.lua`] |
| Regression command entrypoints | Multiple ad hoc shell scripts | `nvim-validate.sh` subcommands | Existing harness already owns exit policy, temp file handling, and artifact locations. [VERIFIED: `scripts/nvim-validate.sh`] |
| Format-on-save behavior checks | Synthetic full save workflow runner | Direct call to `format_on_save(bufnr)` with controlled buffer state | The guard function already exposes the policy boundary directly. [VERIFIED: `.config/nvim/lua/plugins/conform.lua`, `10-CONTEXT.md`] |
| LSP attach automation | Mocked attach event framework | Manual checklist section | The phase context explicitly marks this path as unstable for headless automation. [VERIFIED: `10-CONTEXT.md`] |

**Key insight:** This phase is about reducing uncertainty, not maximizing automation count. Add the minimum automation that directly covers proven blind spots, and leave unstable UI/runtime edges in checklist form. [VERIFIED: `.planning/PROJECT.md`, `10-CONTEXT.md`]

## Common Pitfalls

### Pitfall 1: Expanding Past the Proven Blind Spots
**What goes wrong:** The plan turns into a general-purpose test framework or broad CI redesign. [VERIFIED: `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`]
**Why it happens:** It is easy to confuse “more scripts” with “better validation.” [VERIFIED: `.planning/PROJECT.md`] 
**How to avoid:** Constrain automation to the two flows named in D-05 and D-06, plus the warning audit in 10-04. [VERIFIED: `10-CONTEXT.md`] 
**Warning signs:** New plans start mentioning unrelated plugin workflows that Phase 8 or Phase 11 already owns. [VERIFIED: `.planning/ROADMAP.md`] 

### Pitfall 2: Letting README and Harness Drift Apart
**What goes wrong:** Maintainers run the wrong commands or misread missing artifacts because docs describe an older harness sequence. [VERIFIED: `.config/nvim/README.md`, `scripts/nvim-validate.sh`]
**Why it happens:** The README already contains both updated and stale validation descriptions. [VERIFIED: `.config/nvim/README.md`] 
**How to avoid:** Treat 10-01 as artifact-contract alignment, not mere wording cleanup. [VERIFIED: `10-CONTEXT.md`] 
**Warning signs:** Two README sections disagree on what `all` runs or what files should appear in `.planning/tmp/nvim-validate/`. [VERIFIED: `.config/nvim/README.md`] 

### Pitfall 3: Hardcoding Today’s Warning Inventory
**What goes wrong:** The plan bakes in a stale list of `checkhealth` warnings/errors instead of starting from a fresh audit. [VERIFIED: `10-CONTEXT.md`, `.planning/tmp/nvim-validate/checkhealth.txt`] 
**Why it happens:** Warning output depends on local environment, plugin state, and Neovim version. [CITED: https://neovim.io/doc/user/health/] [VERIFIED: `.planning/tmp/nvim-validate/checkhealth.txt`] 
**How to avoid:** Make the first task of 10-04 a new `checkhealth` run, then classify findings into config-caused, optional-tool, and environment-only buckets. [VERIFIED: `10-CONTEXT.md`] 
**Warning signs:** A plan proposes fixing specific warning lines without re-running `./scripts/nvim-validate.sh checkhealth`. [VERIFIED: `10-CONTEXT.md`] 

### Pitfall 4: Testing Headless Behavior Through the Wrong Interface
**What goes wrong:** A headless probe fails because it simulated UI/editor events instead of calling the actual pure logic boundary. [VERIFIED: `.config/nvim/lua/plugins/conform.lua`, `10-CONTEXT.md`] 
**Why it happens:** Save events and attach events are more brittle than direct function calls. [VERIFIED: `10-CONTEXT.md`] 
**How to avoid:** Probe `format_on_save(bufnr)` directly and keep LSP attach in checklist form. [VERIFIED: `.config/nvim/lua/plugins/conform.lua`, `10-CONTEXT.md`] 
**Warning signs:** The plan contains `autocmd` replay machinery or buffer-write event emulation. [VERIFIED: `10-CONTEXT.md`] 

## Code Examples

Verified patterns from official sources and repo code:

### Repo Health Provider Shape
```lua
-- Source: https://neovim.io/doc/user/health/
local M = {}
M.check = function()
  vim.health.start("foo report")
  vim.health.ok("Setup is correct")
end
return M
```

### Current Keymap Dispatcher Branching
```lua
-- Source: .config/nvim/lua/core/keymaps/lazy.lua
elseif type(map.action) == "string" then
  if map.action:match("<[^>]+>") then
    vim.api.nvim_feedkeys(
      vim.api.nvim_replace_termcodes(map.action, true, false, true),
      "n",
      false
    )
  else
    vim.cmd(map.action)
  end
end
```

### Current Format Guard Boundary
```lua
-- Source: .config/nvim/lua/plugins/conform.lua
if buftype ~= "" and buftype ~= "acwrite" then
  return false
end
if not vim.bo[bufnr].modifiable then
  return false
end
if bufname == "" then
  return false
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `startup`/`sync`/`smoke`/`health` only in `all` | `checkhealth` is now part of the authoritative harness gate | Phase 9 [VERIFIED: `.planning/phases/09-health-signal-cleanup/09-CONTEXT.md`, `scripts/nvim-validate.sh`] | Phase 10 must update stale docs before adding more checks. [VERIFIED: `.config/nvim/README.md`] |
| Manual interpretation of mixed health findings | Repo-owned `config.health` plus documented classification of config vs env vs optional | Phase 9 [VERIFIED: `.config/nvim/lua/config/health.lua`, `.planning/phases/09-health-signal-cleanup/09-CONTEXT.md`] | Phase 10 triage docs should explain artifact reading, not invent a second health system. [VERIFIED: `10-CONTEXT.md`] |
| Manual reproduction of keymap/format regressions | Targeted scripted probes for proven blind spots | Phase 10 goal [VERIFIED: `.planning/ROADMAP.md`, `10-CONTEXT.md`] | Adds repeatability without duplicating `:checkhealth`. [VERIFIED: `.planning/PROJECT.md`] |

**Deprecated/outdated:**
- Older README validation table under the Phase 3 section is outdated because it omits `checkhealth` from `all`. [VERIFIED: `.config/nvim/README.md`, `scripts/nvim-validate.sh`] 

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Native Windows environments may not provide GNU `timeout`, so any plan that treats `timeout` as universally available should document whether the harness is expected to run under Git Bash/MSYS, WSL, or another POSIX layer. [ASSUMED] | Environment Availability / Common Pitfalls | Medium — rollout guidance could be incomplete for Windows maintainers. |

## Open Questions

1. **Should the roadmap be updated to reflect the new 10-04 plan?**
   - What we know: `10-CONTEXT.md` says Phase 10 now has 4 plans, including 10-04 warning cleanup. [VERIFIED: `10-CONTEXT.md`]
   - What's unclear: `.planning/ROADMAP.md` still lists 3 plans for Phase 10. [VERIFIED: `.planning/ROADMAP.md`]
   - Recommendation: Make plan-count alignment an explicit early planning task so downstream artifacts stop disagreeing. [VERIFIED: `10-CONTEXT.md`, `.planning/ROADMAP.md`]

2. **What shell contract is supported for Windows validation runs?**
   - What we know: The project is explicitly cross-platform, but the validator is a bash script that already uses GNU-style `timeout`. [VERIFIED: `AGENTS.md`, `.planning/PROJECT.md`, `scripts/nvim-validate.sh`]
   - What's unclear: Whether Windows maintainers are expected to use Git Bash, WSL, or only run a subset of commands. [VERIFIED: `.planning/PROJECT.md`, `scripts/nvim-validate.sh`] 
   - Recommendation: The plan should at least document the expected shell/runtime for Windows execution, even if no code change lands in this phase. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `nvim` | All harness subcommands | ✓ | `NVIM v0.12.2` [VERIFIED: `nvim --version`] | — |
| `jq` | Pretty-printing and structured inspection of `health.json` | ✓ | `jq-1.8.1` [VERIFIED: `jq --version`] | `python3 -m json.tool` already implemented in script. [VERIFIED: `scripts/nvim-validate.sh`] |
| `python3` | JSON fallback | ✓ | `Python 3.14.4` [VERIFIED: `python3 --version`] | `cat` as last-resort display fallback already exists. [VERIFIED: `scripts/nvim-validate.sh`] |
| `timeout` | `sync` subcommand guard | ✓ | `GNU coreutils 9.10` [VERIFIED: `timeout --version`] | None implemented in script. [VERIFIED: `scripts/nvim-validate.sh`] |
| `rg` | Repo workflows and required-tool health checks | ✓ | `15.1.0` [VERIFIED: `rg --version`] | None; classified as required by health metadata. [VERIFIED: `.planning/tmp/nvim-validate/health.json`] |
| `git` | Repo workflows and required-tool health checks | ✓ | `2.53.0` [VERIFIED: `git --version`] | None; classified as required by health metadata. [VERIFIED: `.planning/tmp/nvim-validate/health.json`] |

**Missing dependencies with no fallback:**
- None on this Linux research machine. [VERIFIED: command probes in this session]

**Missing dependencies with fallback:**
- None on this Linux research machine. [VERIFIED: command probes in this session]

**Environment-specific caveat:**
- A fresh `checkhealth` run in this sandbox wrote `checkhealth.txt` but the process log also showed an `EROFS` write failure under `vim.loader` cache output from `/home/pera/.cache/nvim/luac/...`. Treat this as an execution-environment caveat for the research session, not a locked repo defect. [VERIFIED: `.planning/tmp/nvim-validate/checkhealth.log`] 

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Shell-based validation harness around headless Neovim. [VERIFIED: `scripts/nvim-validate.sh`] |
| Config file | none — behavior lives directly in `scripts/nvim-validate.sh`. [VERIFIED: `scripts/nvim-validate.sh`] |
| Quick run command | `./scripts/nvim-validate.sh startup` for low-cost sanity; `./scripts/nvim-validate.sh keymaps` and `./scripts/nvim-validate.sh formats` become quick regression probes once added. [VERIFIED: `scripts/nvim-validate.sh`, `10-CONTEXT.md`] |
| Full suite command | `./scripts/nvim-validate.sh all` after Phase 10 extends the sequence through `keymaps` and `formats`. [VERIFIED: `10-CONTEXT.md`] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| TEST-01 | Maintainer can verify startup, plugin load, and health state before rollout. [VERIFIED: `.planning/REQUIREMENTS.md`] | shell/headless integration | `./scripts/nvim-validate.sh all` [VERIFIED: `scripts/nvim-validate.sh`] | ✅ |
| TEST-02 | Maintainer can reproduce bug-prone keymap/plugin flows when `:checkhealth` is insufficient. [VERIFIED: `.planning/REQUIREMENTS.md`] | targeted headless regression | `./scripts/nvim-validate.sh keymaps` and `./scripts/nvim-validate.sh formats` [VERIFIED: `10-CONTEXT.md`] | ❌ Wave 0 |
| TEST-03 | Maintainer can separate config regressions from environment/tool gaps by reading artifacts. [VERIFIED: `.planning/REQUIREMENTS.md`] | docs + artifact interpretation | `./scripts/nvim-validate.sh all` plus README triage section [VERIFIED: `10-CONTEXT.md`, `.config/nvim/README.md`] | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `./scripts/nvim-validate.sh startup` until new subcommands land; then run the touched subcommand(s) directly. [VERIFIED: `scripts/nvim-validate.sh`, `10-CONTEXT.md`]
- **Per wave merge:** `./scripts/nvim-validate.sh all`. [VERIFIED: `scripts/nvim-validate.sh`, `10-CONTEXT.md`]
- **Phase gate:** Full suite green and README/checklist/FAILURES alignment complete before `/gsd-verify-work`. [VERIFIED: `10-CONTEXT.md`] 

### Wave 0 Gaps

- [ ] `scripts/nvim-validate.sh` needs `keymaps` and `formats` subcommands. [VERIFIED: `scripts/nvim-validate.sh`, `10-CONTEXT.md`]
- [ ] `.config/nvim/README.md` needs one authoritative “Reading validation output” section and stale validation table cleanup. [VERIFIED: `.config/nvim/README.md`, `10-CONTEXT.md`]
- [ ] `.planning/phases/06-runtime-failure-inventory/CHECKLIST.md` needs a Phase 10 regression section for manual-only flows such as LSP attach safety. [VERIFIED: `10-CONTEXT.md`, `.planning/phases/06-runtime-failure-inventory/CHECKLIST.md`]
- [ ] `.planning/phases/06-runtime-failure-inventory/FAILURES.md` needs warning-status updates as 10-04 lands. [VERIFIED: `10-CONTEXT.md`, `.planning/phases/06-runtime-failure-inventory/FAILURES.md`]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Not applicable to a local Neovim validation harness. [VERIFIED: `.planning/PROJECT.md`, `scripts/nvim-validate.sh`] |
| V3 Session Management | no | Not applicable to a local Neovim validation harness. [VERIFIED: `.planning/PROJECT.md`] |
| V4 Access Control | no | Not applicable; no user/role boundary exists in this phase. [VERIFIED: `.planning/PROJECT.md`] |
| V5 Input Validation | yes | Shell strict mode (`set -euo pipefail`) plus explicit subcommand dispatch and controlled temp-file use. [VERIFIED: `scripts/nvim-validate.sh`] |
| V6 Cryptography | no | No cryptographic behavior in scope. [VERIFIED: `scripts/nvim-validate.sh`, `10-CONTEXT.md`] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Shell argument/dispatch mistakes | Tampering | Keep fixed subcommand case dispatch; do not eval arbitrary user input. [VERIFIED: `scripts/nvim-validate.sh`] |
| False confidence from stale artifacts | Repudiation | Always regenerate artifacts before classification and update README/checklist to match current outputs. [VERIFIED: `.planning/tmp/nvim-validate/checkhealth.txt`, `10-CONTEXT.md`] |
| Hiding real regressions behind broad `silent!` or weak grep rules | Tampering | Preserve explicit PASS/FAIL logic and artifact inspection paths. [VERIFIED: `scripts/nvim-validate.sh`] |

## Sources

### Primary (HIGH confidence)

- [Neovim health docs](https://neovim.io/doc/user/health/) - `:checkhealth`, `health.lua`, `check()` contract, and `vim.health.start/ok/warn/error`. [CITED: https://neovim.io/doc/user/health/]
- [Neovim starting docs](https://neovim.io/doc/user/starting/) - `--headless`, `-l`, and headless CLI behavior. [CITED: https://neovim.io/doc/user/starting/]
- [scripts/nvim-validate.sh](/home/pera/github_repo/.dotfiles/scripts/nvim-validate.sh:1) - current harness architecture, artifact paths, and `all` sequencing. [VERIFIED: `scripts/nvim-validate.sh`]
- [.config/nvim/lua/core/keymaps/lazy.lua](/home/pera/github_repo/.dotfiles/.config/nvim/lua/core/keymaps/lazy.lua:1) - dispatcher branches Phase 10 must regression-test. [VERIFIED: `.config/nvim/lua/core/keymaps/lazy.lua`]
- [.config/nvim/lua/plugins/conform.lua](/home/pera/github_repo/.dotfiles/.config/nvim/lua/plugins/conform.lua:1) - direct `format_on_save` guard function under test. [VERIFIED: `.config/nvim/lua/plugins/conform.lua`]
- [.config/nvim/lua/config/health.lua](/home/pera/github_repo/.dotfiles/.config/nvim/lua/config/health.lua:1) - existing primary health provider and classification surface. [VERIFIED: `.config/nvim/lua/config/health.lua`]
- [.config/nvim/README.md](/home/pera/github_repo/.dotfiles/.config/nvim/README.md:244) - current validation command docs and stale table drift. [VERIFIED: `.config/nvim/README.md`]
- [10-CONTEXT.md](/home/pera/github_repo/.dotfiles/.planning/phases/10-validation-harness-expansion/10-CONTEXT.md:1) - locked decisions and exact phase scope. [VERIFIED: `10-CONTEXT.md`]

### Secondary (MEDIUM confidence)

- [.planning/tmp/nvim-validate/health.json](/home/pera/github_repo/.dotfiles/.planning/tmp/nvim-validate/health.json:1) - current machine’s health snapshot and dependency availability. [VERIFIED: live run in this session]
- [.planning/tmp/nvim-validate/checkhealth.txt](/home/pera/github_repo/.dotfiles/.planning/tmp/nvim-validate/checkhealth.txt:1) - current warning/error mix proving 10-04 needs a fresh audit. [VERIFIED: live run in this session]
- [.planning/tmp/nvim-validate/checkhealth.log](/home/pera/github_repo/.dotfiles/.planning/tmp/nvim-validate/checkhealth.log:1) - sandbox-specific `vim.loader` EROFS caveat for this session. [VERIFIED: live run in this session]

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - The harness, health provider, and target Lua code are all present and directly inspected in this session. [VERIFIED: `scripts/nvim-validate.sh`, `.config/nvim/lua/config/health.lua`, `.config/nvim/lua/core/keymaps/lazy.lua`, `.config/nvim/lua/plugins/conform.lua`]
- Architecture: HIGH - Phase scope is tightly constrained by locked decisions and an existing harness pattern. [VERIFIED: `10-CONTEXT.md`, `.planning/PROJECT.md`]
- Pitfalls: MEDIUM - Repo-specific drift is verified, but some platform-execution implications for Windows remain partially assumed. [VERIFIED: `.config/nvim/README.md`, `.planning/PROJECT.md`] [ASSUMED]

**Research date:** 2026-04-23
**Valid until:** 2026-05-23
