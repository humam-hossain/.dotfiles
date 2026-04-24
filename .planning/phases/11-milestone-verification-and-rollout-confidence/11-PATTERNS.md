# Phase 11: Milestone Verification and Rollout Confidence - Pattern Map

**Mapped:** 2026-04-24
**Files analyzed:** 7
**Analogs found:** 7 / 7

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.planning/REQUIREMENTS.md` | utility | transform | `.planning/REQUIREMENTS.md` (BUG-01 close-out checkbox + citation) | exact |
| `.planning/PROJECT.md` | utility | transform | `.planning/PROJECT.md` (Phase 9/10 "Validated" section moves) | exact |
| `.planning/phases/06-runtime-failure-inventory/FAILURES.md` | utility | transform | `.planning/phases/06-runtime-failure-inventory/FAILURES.md` (Phase 9/10 terminal-state entries) | exact |
| `.planning/ROADMAP.md` | utility | transform | `.planning/ROADMAP.md` (Phase 10 progress row pattern) | exact |
| `.config/nvim/README.md` (11-02 sections) | utility | transform | `.config/nvim/README.md` (Phase 3/Phase 5 section text as written today) | exact |
| `arch/nvim.sh` | config | batch | `arch/nvim.sh` (current file — audit only, no expected change) | exact |
| `scripts/nvim-validate.sh` | utility | batch | `scripts/nvim-validate.sh` (current uncommitted orphan for Phase 10) | exact |

---

## Pattern Assignments

### `.planning/REQUIREMENTS.md` (utility, transform)

**Analog:** `.planning/REQUIREMENTS.md` — BUG-01 checkbox at line 10.

**Existing closed checkbox pattern** (line 10):
```markdown
- [x] **BUG-01**: User can invoke every documented shared keymap in milestone scope without Lua or runtime errors
```

**Target close-out citation format** (D-04 from CONTEXT.md):
```markdown
- [x] **BUG-02**: User can use core plugin workflows for search, explorer, git, LSP, and UI without config-caused runtime errors
  ✓ v1.1 Phase 8 — validated via nvim-validate.sh all PASS + 08-VERIFICATION.md
- [x] **BUG-03**: User can complete common editing sessions without crashes caused by Neovim config code
  ✓ v1.1 Phase 8 — validated via nvim-validate.sh all PASS + 08-VERIFICATION.md
- [x] **HEAL-01**: User can run `:checkhealth` without config-caused `ERROR:` entries
  ✓ v1.1 Phase 9 — validated via nvim-validate.sh all PASS + 09-VERIFICATION.md
- [x] **HEAL-02**: User can distinguish fix-now health findings from optional environment/tooling warnings
  ✓ v1.1 Phase 9 — validated via nvim-validate.sh all PASS + 09-VERIFICATION.md
```

**Constraint:** Do NOT update the Traceability table at the bottom (D-11 confirms v2 requirements untouched; D-04 confirms traceability table left as-is).

---

### `.planning/PROJECT.md` (utility, transform)

**Analog:** `.planning/PROJECT.md` — "Validated" section at lines 28-43; "Active" section at lines 45-47.

**Validated section pattern** (existing entries, lines 28-43) — copy this block structure:
```markdown
### Validated

- ✓ Config-caused E488/Lua errors removed from 9 shared keymaps; registry-driven mappings execute safely — v1.1 (BUG-01, validated Phase 7)
- ✓ ...
```

**Items to move from Active → Validated** (D-06):

From Active (lines 45-47):
```markdown
- [ ] v1.1 bug-fix milestone removes config-caused runtime errors from keymaps, plugins, and crash-prone flows
```
Becomes a new Validated entry:
```markdown
- ✓ v1.1 bug-fix milestone removes config-caused runtime errors from keymaps, plugins, and crash-prone flows — validated Phase 11
```

BUG-02, BUG-03, HEAL-01, HEAL-02 Active items (lines 46-47 currently read as validated already for Phase 9/10 items) must each be promoted. The milestone-level Active item is the primary move per D-06.

**Constraint:** Do NOT change `Current Milestone: v1.1` line.

---

### `.planning/phases/06-runtime-failure-inventory/FAILURES.md` (utility, transform)

**Analog:** `.planning/phases/06-runtime-failure-inventory/FAILURES.md` — existing terminal-state entries.

**Fixed entry pattern** (lines 143-159, representative):
```markdown
| BUG-001 | neo-tree plugin failed to load (module not found) | plugin | **Fixed** (Phase 8-01) | — | health |
```

**Won't Fix / By Design entry pattern** (lines 152-153):
```markdown
| BUG-013 | fzf-lua hidden files | plugins/fzflua.lua | **By Design** | — | static |
| BUG-014 | `<C-w>w` M.global string RHS | core/keymaps/registry.lua:167 | **Not a Bug** | `<leader>ww` | manual |
```

**Disposition Note pattern** (lines 225-254) — prose block per entry:
```markdown
**BUG-019:** [prose describing root cause, fix, and verification result] **CLOSED — FIXED.**
```

**D-05 rule:** After 11-01, every entry must have a terminal state. Valid terminals:
- `**Fixed** (Phase N-NN)` — with phase reference
- `**By Design**` — with rationale in Disposition Notes
- `**Won't Fix**` — with rationale
- `**Not a Bug**` — with rationale

Scan for any remaining `Pending`, `In Progress`, or blank Status cells and resolve each per the existing evidence in FAILURES.md (Phase 8/9/10 audit sections already provide evidence for all outstanding items).

---

### `.planning/ROADMAP.md` (utility, transform)

**Analog:** `.planning/ROADMAP.md` — Phase 10 progress row (line 93) and Phase 6 goal section (lines 23-31).

**Progress table row pattern** (lines 88-94):
```markdown
| Phase | Milestone | Plans Complete | Status |
|-------|-----------|----------------|--------|
| 6. Runtime Failure Inventory and Reproduction | v1.1 | 2/2 | ✅ Complete |
| 7. Keymap Reliability Fixes | 2/2 | Complete   | 2026-04-21 |
| 8. Plugin Runtime Hardening | v1.1 | 0/3 | ⬜ Pending |
| 9. Health Signal Cleanup | v1.1 | 0/2 | ⬜ Pending |
| 10. Validation Harness Expansion | 4/4 | Complete    | 2026-04-24 |
| 11. Milestone Verification and Rollout Confidence | v1.1 | 0/2 | ⬜ Pending |
```

**Plan item checkbox pattern** (Phase 6 section, lines 29-30):
```markdown
- [x] 6-01-PLAN.md — Audit current runtime failures from keymaps, plugins, crashes, and `:checkhealth`
- [ ] 6-02-PLAN.md — Create reproducible validation checklist for confirmed failures
```

**D-07 target state** (fix all stale markers in a single commit):
- Phase 6: `1/2 COMPLETE` → `2/2 Complete (2026-04-18)` in header; `[ ] 6-02` → `[x] 6-02`
- Phase 7: `[ ] 7-01` and `[ ] 7-02` → `[x]`; progress row → `2/2 Complete | 2026-04-21`
- Phase 8: `0/3` → `3/3 Complete`; all `[ ] 8-0x` → `[x]`; progress row date → `2026-04-22`
- Phase 9: `0/2` → `2/2 Complete`; all `[ ] 9-0x` → `[x]`; progress row date → `2026-04-23`
- Phase 10: progress row already has date `2026-04-24` (stale marker was fixed in uncommitted change)

**D-08 self-mark** (after 11-02 commits): Phase 11 progress row → `2/2 Complete | 2026-04-24`.

---

### `.config/nvim/README.md` — 11-02 sections (utility, transform)

**Analog:** `.config/nvim/README.md` — full document as it exists today.

#### Phase Change Summary section (lines 95-101)

**Existing row pattern** (line 97):
```markdown
| **Phase 1** | Buffer-first lifecycle; autosave runs only on `FocusLost`... | `<C-q>` closes current buffer... |
```

**New v1.1 row to insert** (D-12, after Phase 5 row):
```markdown
| **v1.1 Bug Fixes (Phases 7–10)** | Config-caused E488 keymap errors fixed; `:checkhealth config` shows no ERRORs; which-key duplicate-prefix warnings eliminated; project.nvim deprecated API removed | Keymaps execute without Lua errors; `:checkhealth config` clean; external-open rebound to `<leader>o` (terminal strips `<C-S-o>`); which-key prefix list clean |
```

#### Machine Update Checklist section (lines 38-89)

**Step 3 stale text** (lines 58-62 — current):
```markdown
   This runs `:Lazy! sync` headlessly with a 120-second timeout. It installs newly added plugins (like `folke/snacks.nvim` introduced in Phase 5) and uninstalls anything removed from the spec tree (`noice.nvim`, `nvim-notify`, `alpha.nvim`, `indent-blankline`, `fzf-lua`). Expected last line: `PASS: sync OK`.
```
**Replace with** (D-13):
```markdown
   This runs `:Lazy! sync` headlessly with a 120-second timeout. It installs newly added plugins and uninstalls removed plugins according to the current `lazy-lock.json` spec. Expected last line: `PASS: sync OK`.
```

**Step 5 stale text** (line 81 — current):
```markdown
   This runs `startup`, `sync`, `smoke`, and `health` in order and fails fast. Expected final line: `==> all PASS`. See **Post-Deploy Verification** below for what to do on failure.
```
**Replace with** (D-13 — list all 7 subcommands):
```markdown
   This runs `startup`, `sync`, `smoke`, `health`, `checkhealth`, `keymaps`, and `formats` in order and fails fast. Expected final line: `==> all PASS`. See **Post-Deploy Verification** below for what to do on failure.
```

**Step 6 stale text** (lines 87-89 — current):
```markdown
   You should see the snacks.nvim dashboard, not the old alpha banner. Press `<leader>ff` to confirm `snacks.picker` opens for file search. Press `<leader>gg` to confirm `snacks.lazygit` opens the lazygit float. These three checks cover the Phase 5 UX-01 coherence surface.
```
**Replace with** (D-13 — remove phase jargon):
```markdown
   You should see the snacks.nvim dashboard. Press `<leader>ff` to confirm `snacks.picker` opens for file search. Press `<leader>gg` to confirm `snacks.lazygit` opens the lazygit float.
```

#### Post-Deploy Verification section (lines 103-143)

**Step 1 stale text** (lines 112-113 — current):
```markdown
   Expected final line: `==> all PASS`. The suite runs `startup`, `sync`, `smoke`, `health`, and `checkhealth`.
```
**Replace with** (D-14 — correct subcommand list):
```markdown
   Expected final line: `==> all PASS`. The suite runs `startup`, `sync`, `smoke`, `health`, `checkhealth`, `keymaps`, and `formats`.
```

**Step 2 stale checkhealth expected-clean list** (line 123 — current):
```markdown
   Scroll through each section. Expected: no errors (`ERROR:` lines) from `snacks`, `lazy`, `lspconfig`, `mason`, `blink.cmp`, `gitsigns`, `neo-tree`, `lualine`, `treesitter`.
```
**Replace with** (D-14 — remove neo-tree, add which-key informational note):
```markdown
   Scroll through each section. Expected: no errors (`ERROR:` lines) from `snacks`, `lazy`, `lspconfig`, `mason`, `blink.cmp`, `gitsigns`, `lualine`, `treesitter`. Informational overlaps from `which-key` (`<Space>x/<Space>xs`, `gc/gcc`) are expected and not actionable.
```

**Step 3 manual keymap smoke table** (lines 126-135 — current):
```markdown
| Keymap | Expected Behavior |
|--------|-------------------|
| `<leader>ff` | snacks.picker files float opens |
| `<leader>fg` | snacks.picker grep float opens and finds matches including in hidden files |
| `<leader>gg` | snacks.lazygit float opens the lazygit TUI |
| `<leader>cd` | snacks.picker jumps to LSP definition (on a symbol) |
| `<leader>cr` | snacks.picker lists LSP references |
| `:echo "test"` + Enter | Bottom-right notification toast appears (snacks.notif) |
```
**Add `<leader>o` row** and audit all entries against `registry.lua` (D-14). Insert after the existing rows:
```markdown
| `<leader>o` | Current file opens externally via `xdg-open` (Linux) or `vim.ui.open()` |
```

#### Central Keymap Architecture section (lines 257-313 approximate)

**Heading rename** (D-16):
- `## Phase 2: Central Command and Keymap Architecture` → `## Central Keymap Architecture`

**Central Keymap Rule blurb** (line ~259):
```markdown
Per Phase 2 architecture, all user-facing mappings are declared in `lua/core/keymaps/registry.lua`.
```
**Replace with** (D-16 — remove "Per Phase 2 architecture"):
```markdown
All user-facing mappings are declared in `lua/core/keymaps/registry.lua`.
```

**Plugin-local scope description** (line ~300):
```markdown
- **plugin-local**: Context-specific (neo-tree windows, treesitter incremental)
```
**Replace with** (D-16 — remove neo-tree, plugin is uninstalled):
```markdown
- **plugin-local**: Context-specific (treesitter incremental and similar plugin-owned contexts)
```

**Domain taxonomy table** (lines ~268-278) — audit `<leader>o` coverage. The table currently lists 8 prefixes; `<leader>o` is not a prefix-domain but a direct binding under no prefix group. No table row addition needed unless a new domain column is warranted (at planner discretion).

#### Validation Harness section (lines 316-398 approximate)

**Heading rename** (D-17):
- `## Phase 3: Validation Harness` → `## Validation Harness`

**Add `:checkhealth config` provider mention** (D-17) — insert after the Entrypoint table, before the Report Output section:
```markdown
### Interactive health provider

`:checkhealth config` (backed by `lua/config/health.lua`) shows plugin load status, required tool availability, and known environment gaps interactively inside Neovim. It is the first-line diagnostic for any setup issue not caught by the scripted harness.
```

**Remove historical setup note** (D-17) — locate and delete the sentence:
```markdown
Before concluding Phase 3 or starting Phase 4: `./scripts/nvim-validate.sh all`
```

#### Phase 4 heading rename (D-18)

**Current heading** (line ~221):
```markdown
## Phase 4: Tooling and Ecosystem Modernization
```
**Rename to:**
```markdown
## Tooling and Ecosystem Modernization
```
No content changes to the Phase 4 section body.

---

### `arch/nvim.sh` (config, batch — audit only)

**Analog:** `arch/nvim.sh` — full file (20 lines).

**Current file content** (lines 1-20):
```bash
#!/usr/bin/env bash
set -euo pipefail
set -x

echo "[INSTALL] pynvim"
sudo pacman -Sy --noconfirm --needed python-pynvim fd

echo "[INSTALL] luarocks"
sudo pacman -Sy --noconfirm --needed luarocks

echo "[INSTALL] tree-sitter-cli"
sudo pacman -Sy --noconfirm --needed tree-sitter-cli

echo "[INSTALL] neovim"
sudo pacman -Sy --noconfirm --needed neovim

echo "[CONFIG] syncing .config"
mkdir -p ~/.config/nvim/
rsync -a --delete .config/nvim/ ~/.config/nvim/
```

**D-19 audit:** Verify the install script is accurate for v1.1. Known items to check:
- `python-pynvim` and `fd`: still needed (used by Mason and snacks.picker respectively).
- `luarocks`: still listed (lazy.nvim wants it for optional luarocks-based installs; acceptable even though no plugins currently require it).
- `tree-sitter-cli`: still needed for Treesitter parser compilation.
- `neovim`: correct.
- `rsync -a --delete .config/nvim/ ~/.config/nvim/`: correct sync command.

**Expected outcome:** No changes required. Document as "verified unchanged" in the plan. If a change is identified during audit, the changed line is the unit of the commit; the commit message is `chore(11-02): verify arch/nvim.sh unchanged for v1.1`.

---

### `scripts/nvim-validate.sh` — Phase 10 orphan commit (utility, batch)

**Analog:** `scripts/nvim-validate.sh` — current uncommitted state.

**Orphan change — checkhealth toleration pattern** (D-09 step 2, CONTEXT.md code context):

The uncommitted change adds toleration for 5 known headless/env-only ERROR patterns in `cmd_checkhealth`. The pattern follows the existing `grep -nP` exclusion approach. The 5 tolerated patterns are:
```
ERROR highlighter: not enabled
ERROR setup did not run
ERROR Tool not found: 'mmdc'
ERROR your terminal does not support the kitty graphics protocol
ERROR Background job is not running: dead (init not called)
```

This is a Phase 10 artifact. The commit message for the orphan commit is:
```
fix(10): commit orphaned Phase 10 changes
```

Files in this commit: `scripts/nvim-validate.sh`, `.config/nvim/lua/plugins/project.lua`, `.config/nvim/README.md`.

---

## Shared Patterns

### Atomic commit per file/section
**Source:** All prior phases (established pattern since Phase 6).
**Apply to:** All 11-01 and 11-02 tasks.
```
Each file or logical section gets its own atomic commit.
Commit messages follow: fix(N): ..., docs(N): ..., chore(N): ...
```

### REQUIREMENTS.md checkbox + citation format
**Source:** `.planning/REQUIREMENTS.md` line 10 (BUG-01 entry) and CONTEXT.md D-04.
**Apply to:** BUG-02, BUG-03, HEAL-01, HEAL-02 close-out.
```markdown
- [x] **{ID}**: {existing description}
  ✓ v1.1 Phase {N} — validated via nvim-validate.sh all PASS + {NN}-VERIFICATION.md
```

### FAILURES.md terminal state + disposition note
**Source:** `.planning/phases/06-runtime-failure-inventory/FAILURES.md` — Fixed/By Design entries throughout.
**Apply to:** Any entry without a terminal state after 11-01.
```markdown
Inventory table: | {ID} | {desc} | {owner} | **Fixed** (Phase N-NN) | ... |
Disposition note block: **{ID}:** [prose] **CLOSED — FIXED.**
```

### PROJECT.md Validated section move
**Source:** `.planning/PROJECT.md` lines 28-43 (Validated section) and lines 45-47 (Active section).
**Apply to:** The v1.1 milestone-level Active item and any BUG/HEAL items not yet promoted.
```markdown
- ✓ {description} — v1.1 (validated Phase {N})
```

### README section text — no phase-specific jargon
**Source:** `.config/nvim/README.md` current Rollout section (generic guidance pattern).
**Apply to:** All 11-02 section edits. Audit for phrases like "Phase N architecture", "Phase N UX-01 coherence surface", "introduced in Phase N", and replace with outcome-focused or generic language.

---

## No Analog Found

All files in scope have direct existing analogs. No new file is being created; all work is modification of existing living documents.

---

## Metadata

**Analog search scope:** `.planning/`, `.config/nvim/README.md`, `scripts/nvim-validate.sh`, `arch/nvim.sh`
**Files scanned:** 12
**Pattern extraction date:** 2026-04-24
