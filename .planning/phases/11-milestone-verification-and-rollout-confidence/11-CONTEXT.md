# Phase 11: Milestone Verification and Rollout Confidence - Context

**Gathered:** 2026-04-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Close out the v1.1 milestone: formally verify all 8 requirements end-to-end, update traceability documents, and refresh the README rollout guidance for v1.1 outcomes.

Two plans:
- 11-01 — Commit orphaned/pending work, run milestone verification, update REQUIREMENTS.md + PROJECT.md + FAILURES.md + ROADMAP.md
- 11-02 — Full v1.1 README refresh: Phase Change Summary, Machine Update Checklist, Post-Deploy Verification, Keymap section, Validation Harness section, install scripts

</domain>

<decisions>
## Implementation Decisions

---

### 11-01: Verification and Close-Out

**D-01: Verification evidence bar**
Cite prior artifacts. Run `nvim-validate.sh all` fresh once in 11-01. If it passes, that combined with the existing Phase 8 VERIFICATION.md + 08-UAT.md and Phase 9 VERIFICATION.md is sufficient to close BUG-02, BUG-03, HEAL-01, HEAL-02. No new interactive walkthroughs required.

**D-02: Validation artifact handling**
Note `nvim-validate.sh all PASS as of [date]` in the plan. Artifacts stay in `.planning/tmp/` (gitignored). No snapshot commit.

**D-03: Milestone close-out artifact**
No dedicated MILESTONE-VERIFICATION.md. Instead: update REQUIREMENTS.md checkboxes + final FAILURES.md sweep. This is sufficient.

**D-04: REQUIREMENTS.md close-out**
Check off BUG-02, BUG-03, HEAL-01, HEAL-02 using citation format: `✓ v1.1 Phase N — validated via nvim-validate.sh all PASS + NN-VERIFICATION.md`. Do NOT update the traceability table at the bottom.

**D-05: FAILURES.md final sweep**
Every entry must reach a terminal state. No entry may remain Pending after 11-01 commits. Valid terminal states: Fixed (with phase reference) or Won't Fix / By Design (with rationale).

**D-06: PROJECT.md close-out**
Move BUG-02, BUG-03, HEAL-01, HEAL-02 from Active to Validated section. Also move the milestone-level Active item `[ ] v1.1 bug-fix milestone removes config-caused runtime errors from keymaps, plugins, and crash-prone flows` to Validated. Do NOT change `Current Milestone: v1.1` — that is /gsd-complete-milestone's job.

**D-07: ROADMAP.md cleanup**
Fix all stale plan-count markers in a single commit:
- Phase 6: "1/2 COMPLETE" → 2/2 Complete (with date)
- Phase 7: unchecked `[ ]` plan items → `[x]`; "2/2 plans complete"
- Phase 8: "0/3" → 3/3 Complete (with date 2026-04-22)
- Phase 9: "0/2" → 2/2 Complete (with date 2026-04-23)
- Phase 10: date already 2026-04-24 (stale marker fixed in uncommitted change)

**D-08: Phase 11 ROADMAP self-mark**
After 11-02 plan commits: update ROADMAP.md Phase 11 progress row → 2/2 Complete + date.

**D-09: 11-01 task sequence**
1. Commit non-Neovim dotfiles (.config/.zprofile, .config/hypr/hyprland.conf) in a separate `chore: commit pending dotfiles changes` commit.
2. Commit Phase 10 orphaned changes in a `fix(10): commit orphaned Phase 10 changes` commit. Files: `scripts/nvim-validate.sh` (checkhealth toleration logic), `.config/nvim/lua/plugins/project.lua` (detection_methods fix), `.config/nvim/README.md` (checkhealth description + :LspInfo → :checkhealth vim.lsp updates).
3. Run `./scripts/nvim-validate.sh all` — verify PASS; investigate SMOKE_FAIL (neo-tree stale artifact from pre-Phase-8 smoke run); delete SMOKE_FAIL if `all` passes.
4. Update REQUIREMENTS.md (D-04), PROJECT.md (D-06), FAILURES.md (D-05), ROADMAP.md (D-07). Each file gets its own atomic commit.

**D-10: SMOKE_FAIL handling**
SMOKE_FAIL contains a neo-tree module load error from a pre-Phase-8 run (neo-tree was removed in Phase 8). After `nvim-validate.sh all` passes (smoke no longer probes neo-tree), delete SMOKE_FAIL as stale cleanup.

**D-11: v2 requirements in REQUIREMENTS.md**
Leave untouched. AUTO-01, AUTO-02, PROF-01 are future milestone material.

---

### 11-02: README and Maintenance Workflow Refresh

**D-12: Phase Change Summary — v1.1 row**
Add a single combined `v1.1 Bug Fixes (Phases 7–10)` row. Content focuses on bug-fix outcomes the maintainer will notice post-upgrade:
- Keymaps no longer throw E488 errors (Phase 7)
- `:checkhealth config` shows no ERROR entries (Phase 9)
- External-open is now `<leader>o` (Phase 9 — `<C-S-o>` was terminal-stripped)
- which-key has no duplicate-prefix warnings for `<leader>e` and `<leader>b` (Phase 10)
Do NOT include validation gains or architecture changes in this row.

**D-13: Machine Update Checklist — full audit**
Audit all 6 checklist steps against v1.1. Specific known gaps:
- Step 3 sync description: replace v1.0-specific plugin list ("snacks.nvim introduced in Phase 5... noice.nvim, nvim-notify...") with generic "installs newly added plugins and uninstalls removed plugins according to the current lazy-lock.json spec."
- Step 5 `all` description: update to list all 7 subcommands (startup → sync → smoke → health → checkhealth → keymaps → formats).
- Step 6: remove "These three checks cover the Phase 5 UX-01 coherence surface." Replace with plain language.
- Remaining steps: check for any other v1.0-era jargon or stale references.

**D-14: Post-Deploy Verification — full v1.1 refresh**
Audit the entire Post-Deploy Verification section:
- Step 2 `:checkhealth` expected output: remove neo-tree from the expected-no-errors list (plugin uninstalled); add a note that which-key informational overlaps (`<Space>x/<Space>xs`, `gc/gcc`) are expected and not errors.
- Step 3 manual keymap smoke table: audit all entries against current registry.lua; add `<leader>o` (external-open) row; remove any stale entries.
- No other structural changes to the verification section.

**D-15: Rollback Instructions — skip**
Rollback Instructions section is durable generic guidance. Do not update in 11-02.

**D-16: Central Keymap Architecture section (Phase 2)**
Audit and update:
- Rename heading from "Phase 2: Central Command and Keymap Architecture" → "Central Keymap Architecture".
- Remove "Per Phase 2 architecture" phrase in the Central Keymap Rule blurb.
- Update plugin-local scope description: remove "neo-tree windows" (plugin uninstalled).
- Review domain taxonomy and mapping table for v1.1 changes (e.g., `<leader>o` external-open).

**D-17: Validation Harness section (Phase 3)**
Audit and update:
- Rename heading from "Phase 3: Validation Harness" → "Validation Harness".
- Add brief mention of `:checkhealth config` provider (`lua/config/health.lua`): shows plugin load, required tools, and known environment gaps interactively.
- Remove "Before concluding Phase 3 or starting Phase 4: `./scripts/nvim-validate.sh all`" historical setup note.
- Any other stale content in the section body.

**D-18: Phase 4 heading rename only**
Rename "Phase 4: Tooling and Ecosystem Modernization" → "Tooling and Ecosystem Modernization". No content audit of the Phase 4 section body.

**D-19: arch/nvim.sh install script**
Full audit of `arch/nvim.sh` for v1.1 accuracy. If no v1.1 changes are needed, document that it was verified unchanged. Do NOT audit `ubuntu/nvim.sh`.

**D-20: File Inventory table**
Leave as-is. Do not add `lua/config/health.lua` row.

**D-21: Version marker**
Do not add a "Current version: v1.1" header. Phase Change Summary table provides sufficient version context.

**D-22: No new maintenance sections**
11-02 only refreshes existing content. No new sections added.

**D-23: 11-02 task sequence and commit strategy**
Top-to-bottom through the README. Each logical section gets its own commit:
1. Phase Change Summary v1.1 row
2. Machine Update Checklist (6-step audit)
3. Post-Deploy Verification (full v1.1 refresh)
4. Central Keymap Architecture + Validation Harness + Phase 4 heading rename (keymap + reference docs)
5. arch/nvim.sh install script audit

### Claude's Discretion

- Exact wording of v1.1 Phase Change Summary row ("What Changed" column prose)
- Specific Phase 4 mention in step 4 ("system-binary fallback (Phase 4)") — remove phase ref or leave (Phase 4 section is in same README, so the cross-reference is still valid)
- Order of commits within 11-01 tasks 3 and 4 (REQUIREMENTS.md vs. PROJECT.md vs. FAILURES.md vs. ROADMAP.md)
- Whether Phase 3 Validation Harness section has other stale content beyond what's enumerated above

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` — Phase 11 goal, plan structure; all 8 requirements listed
- `.planning/REQUIREMENTS.md` — All v1 requirement definitions and current checkbox state
- `.planning/PROJECT.md` — Active requirements to move to Validated; milestone Active item

### Evidence artifacts (read to understand what evidence exists)
- `.planning/phases/08-plugin-runtime-hardening/08-VERIFICATION.md` — BUG-02, BUG-03 evidence (Phase 8)
- `.planning/phases/08-plugin-runtime-hardening/08-UAT.md` — BUG-02, BUG-03 UAT evidence
- `.planning/phases/09-health-signal-cleanup/09-VERIFICATION.md` — HEAL-01, HEAL-02 evidence (Phase 9)

### Living docs to update
- `.planning/phases/06-runtime-failure-inventory/FAILURES.md` — Final sweep: all entries → Fixed or Won't Fix
- `.planning/ROADMAP.md` — Fix all stale plan-count markers (Phase 6/7/8/9)

### Uncommitted Phase 10 orphans (commit first in 11-01)
- `scripts/nvim-validate.sh` — checkhealth toleration logic for known headless/env-only ERRORs
- `.config/nvim/lua/plugins/project.lua` — detection_methods = { "pattern" } fix
- `.config/nvim/README.md` — checkhealth description updates + :LspInfo → :checkhealth vim.lsp

### README primary target for 11-02
- `.config/nvim/README.md` — full document; sections in scope: Phase Change Summary, Machine Update Checklist, Post-Deploy Verification, Central Keymap Rule + Phase 2 section, Phase 3 Validation Harness section, Phase 4 heading; Rollback Instructions and File Inventory are out of scope

### Keymap registry (for smoke table and keymap section audit)
- `.config/nvim/lua/core/keymaps/registry.lua` — authoritative source for current keymap bindings; audit smoke table and domain taxonomy against this

### Install script
- `arch/nvim.sh` — audit for v1.1 accuracy; `ubuntu/nvim.sh` excluded

### Prior phase context
- `.planning/phases/10-validation-harness-expansion/10-CONTEXT.md` — D-10: `all` subcommand sequence (7 steps); D-14/D-15/D-16: warning classification and FAILURES.md workflow
- `.planning/phases/09-health-signal-cleanup/09-CONTEXT.md` — D-08/D-09: config.health provider structure; D-21: BUG-019 tmux fix (companion bindings in .tmux.conf); D-32: BUG-020 rebind to `<leader>o`
- `.planning/phases/06-runtime-failure-inventory/FAILURES.md` — D-12 living-doc pattern (Fixed/Won't Fix/By Design)

No external specs — requirements fully captured in decisions above.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scripts/nvim-validate.sh all` — runs 7 subcommands: startup → sync → smoke → health → checkhealth → keymaps → formats. Single command for milestone verification run.
- `.planning/tmp/nvim-validate/` — artifact directory. All subcommand logs land here (gitignored).
- `.config/nvim/lua/core/keymaps/registry.lua` — source of truth for 11-02 keymap section and manual smoke table audit.

### Established Patterns
- REQUIREMENTS.md checkbox citation format (established by BUG-01 close-out): `✓ v1.1 Phase N — validated via nvim-validate.sh all PASS + NN-VERIFICATION.md`.
- FAILURES.md status workflow (Phase 6 D-12): Fixed entries include phase and fix description; Won't Fix / By Design entries include rationale.
- Atomic commits per file/section — used in all prior phases.

### Integration Points
- `scripts/nvim-validate.sh all` exit code determines verification outcome for D-01.
- `SMOKE_FAIL` at repo root: untracked file containing neo-tree load error from pre-Phase-8 run. Delete after `all` passes.
- `.codex` (empty marker, untracked) and `nvim.log` (headless run warnings, untracked) — leave as-is.

### Uncommitted Changes (11-01 Phase 10 orphan commit)
Three files have committed-in-FAILURES.md changes that were never committed to git:
1. `scripts/nvim-validate.sh` — adds toleration for 5 known headless/env-only ERROR patterns in `cmd_checkhealth`.
2. `.config/nvim/lua/plugins/project.lua` — sets `detection_methods = { "pattern" }` to eliminate deprecated `vim.lsp.buf_get_clients()` calls.
3. `.config/nvim/README.md` — updates two checkhealth table descriptions + replaces deprecated `:LspInfo` with `:checkhealth vim.lsp` + Lua print command.

Non-Neovim uncommitted changes (commit separately, not as Phase 10 orphans):
- `.config/.zprofile` — 4 lines added (system config, unrelated to Neovim milestone)
- `.config/hypr/hyprland.conf` — 5 line changes (Hyprland window manager config, unrelated)

</code_context>

<specifics>
## Specific Ideas

- REQUIREMENTS.md citation format: `- [x] **BUG-02**: ... ✓ v1.1 Phase 8 — validated via nvim-validate.sh all PASS + 08-VERIFICATION.md`
- SMOKE_FAIL contents: neo-tree module load error (`module 'neo-tree' not found`). Expected to be stale since Phase 8 removed neo-tree from probe list. Delete after `all` PASS.
- Phase Change Summary v1.1 row example format:
  `| **v1.1 Bug Fixes (Phases 7–10)** | Config-caused E488 keymap errors fixed; :checkhealth config shows no ERRORs; which-key duplicate warnings eliminated; project.nvim deprecated API removed | Keymaps execute without Lua errors; :checkhealth config clean; external-open rebound to <leader>o (terminal strips <C-S-o>); which-key prefix list clean |`
- Post-deploy step 2 update: remove `neo-tree` from expected-clean providers list; add "Informational overlaps from which-key (`<Space>x/<Space>xs`, `gc/gcc`) are expected and not actionable."
- nvim-validate.sh tolerated ERROR patterns (from uncommitted change): `ERROR highlighter: not enabled`, `ERROR setup did not run`, `ERROR Tool not found: 'mmdc'`, `ERROR your terminal does not support the kitty graphics protocol`, `ERROR Background job is not running: dead (init not called)`.

</specifics>

<deferred>
## Deferred Ideas

- `.codex` and `nvim.log` gitignore entries — noted but not in scope for phase 11.
- `ubuntu/nvim.sh` install script audit — deferred; only `arch/nvim.sh` is in scope.
- File Inventory table update (add `lua/config/health.lua` row) — deferred; table is for quick orientation.
- Windows validation harness caveat in README — left as-is; users infer bash requirement.
- v2 requirements (AUTO-01, AUTO-02, PROF-01) — untouched; future milestone.
- REQUIREMENTS.md traceability table status update (Phase 8/9 "Pending" → "Complete") — left as-is per user decision.

</deferred>

---

*Phase: 11-milestone-verification-and-rollout-confidence*
*Context gathered: 2026-04-24*
