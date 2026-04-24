# Phase 11: Milestone Verification and Rollout Confidence - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-24
**Phase:** 11-milestone-verification-and-rollout-confidence
**Areas discussed:** Verification evidence bar, Milestone close-out artifact, FAILURES.md final state, Evidence citation format, README v1.1 change summary, Post-deploy verification, Machine checklist, Maintenance workflow, PROJECT.md close-out, ROADMAP.md stale markers, SMOKE_FAIL handling, Gitignore, Traceability table, Rollback section scope, Phase 3 Validation Harness, Phase 4 heading, Orphaned Phase 10 work, Non-Neovim uncommitted files, Post-deploy :checkhealth output, 11-01 vs 11-02 boundary, Task sequences, File inventory, Version marker, v2 requirements, Validation artifact archiving, PROJECT.md milestone active item, ROADMAP Phase 6/7, Arch/Ubuntu install scripts, Manual smoke table keymaps, Phase 2 heading, Phase 4 heading rename, 11-02 commit strategy, Phase 3 legacy note, Health provider doc, Central Keymap doc, Phase refs in docs, Phase 11 ROADMAP self-mark, Non-Neovim commits, Sync step description, Step 6 phase jargon

---

## Verification evidence bar

| Option | Description | Selected |
|--------|-------------|----------|
| Cite prior artifacts | Run nvim-validate.sh all fresh; pass + prior phase VERIFICATION.md/UAT evidence = sufficient. No new interactive walkthroughs. | ✓ |
| Fresh interactive walkthroughs | New hands-on session for each unchecked requirement. | |

**User's choice:** Cite prior artifacts
**Notes:** Phases 8 and 9 already have VERIFICATION.md and UAT artifacts. A fresh `nvim-validate.sh all` PASS is the close-out trigger.

---

## Milestone close-out artifact

| Option | Description | Selected |
|--------|-------------|----------|
| REQUIREMENTS.md + FAILURES.md sweep | Update 4 unchecked checkboxes; final FAILURES.md sweep. No separate MILESTONE-VERIFICATION.md. | ✓ |
| Dedicated MILESTONE-VERIFICATION.md | Formal close-out document with all 8 requirements + evidence citations. | |

---

## FAILURES.md final state

| Option | Description | Selected |
|--------|-------------|----------|
| All Fixed or Won't Fix | No entry stays Pending. Every item must reach a terminal state. | ✓ |
| Sweep and document only | Allow some Pending if context explains why. | |

---

## Evidence citation format

| Option | Description | Selected |
|--------|-------------|----------|
| Phase ref + script pass | `✓ v1.1 Phase N — validated via nvim-validate.sh all PASS + NN-VERIFICATION.md` | ✓ |
| Detailed per-bug mapping | Enumerate each fixed bug (BUG-001, BUG-016, etc.) with FAILURES.md entry. | |

---

## README v1.1 change summary

| Option | Description | Selected |
|--------|-------------|----------|
| One combined v1.1 row | Single `v1.1 Bug Fixes (Phases 7–10)` row. | ✓ |
| Individual rows per phase | 4 rows (Phase 7, 8, 9, 10) each. | |

**Follow-up — row content:**

| Option | Description | Selected |
|--------|-------------|----------|
| Bug-fix outcomes only | Focus on what stopped breaking: keymaps, :checkhealth, <leader>o, which-key. | ✓ |
| Validation gains too | Also mention nvim-validate.sh all now runs 7 subcommands. | |

---

## Post-deploy verification

| Option | Description | Selected |
|--------|-------------|----------|
| Full v1.1 refresh | Audit entire Post-Deploy Verification section. | ✓ |
| Surgical fixes only | Fix only provably wrong content. | |

---

## Machine Update Checklist

| Option | Description | Selected |
|--------|-------------|----------|
| Full checklist audit | Audit all 6 steps for v1.1 accuracy. | ✓ |
| Step 5 description only | Only fix the `all` subcommand description. | |

---

## Maintenance workflow additions

| Option | Description | Selected |
|--------|-------------|----------|
| No new sections | 11-02 only refreshes existing content. | ✓ |
| Add v1.1 maintenance note | Add a new section for running nvim-validate.sh after config changes. | |

---

## PROJECT.md Active → Validated

| Option | Description | Selected |
|--------|-------------|----------|
| In 11-01 | Move BUG-02/03/HEAL-01/02 + milestone active item to Validated in 11-01. | ✓ |
| At /gsd-complete-milestone only | Leave Active section unchanged. | |

---

## ROADMAP.md stale markers

| Option | Description | Selected |
|--------|-------------|----------|
| Fix all stale ROADMAP markers | Phases 6, 7, 8, 9 all corrected in one commit. | ✓ |
| Fix only phases 8 and 9 | Leave Phase 6 and 7 stale. | |

---

## SMOKE_FAIL handling

| Option | Description | Selected |
|--------|-------------|----------|
| Investigate then delete | Run nvim-validate.sh all; if passes, delete SMOKE_FAIL as stale. | ✓ |
| Delete unconditionally | Remove without investigation. | |

**Notes:** SMOKE_FAIL contains a neo-tree module load error from a pre-Phase-8 run.

---

## Gitignore (.codex, nvim.log)

| Option | Description | Selected |
|--------|-------------|----------|
| Leave as-is | Not a priority for phase 11. | ✓ |
| Yes, gitignore both | Add to .gitignore during cleanup sweep. | |

---

## Traceability table in REQUIREMENTS.md

| Option | Description | Selected |
|--------|-------------|----------|
| Leave as-is | Only update checkboxes, not the traceability table rows. | ✓ |
| Update to Complete | Also update Phase 8/9 Status column. | |

---

## Rollback section scope

| Option | Description | Selected |
|--------|-------------|----------|
| No — rollback section is durable | Generic guidance, skip in 11-02. | ✓ |
| Yes — audit rollback section too | Include in full v1.1 audit. | |

---

## Phase 3 Validation Harness audit

| Option | Description | Selected |
|--------|-------------|----------|
| Audit Phase 3 section only | Phase 3's `all` sequence description needs updating. Phase 4 leave as-is. | ✓ |
| Audit both Phase 3 and Phase 4 | Full pass on both. | |
| Skip both | Not in 11-02 scope. | |

---

## Orphaned Phase 10 work

| Option | Description | Selected |
|--------|-------------|----------|
| Commit as Phase 10 cleanup in 11-01 | `fix(10): commit orphaned Phase 10 changes` commit. Then proceed on clean baseline. | ✓ |
| Fold into 11-01 changes | Commit together with Phase 11 work. | |

---

## Non-Neovim uncommitted files

| Option | Description | Selected |
|--------|-------------|----------|
| Commit separately in 11-01 | `chore: commit pending dotfiles changes` before Neovim work. | ✓ |
| Leave uncommitted | Unrelated to Neovim milestone. | |

---

## Post-deploy :checkhealth expected output

| Option | Description | Selected |
|--------|-------------|----------|
| Update in 11-02 | Remove neo-tree; add which-key informational overlap note. | ✓ |
| Leave as-is | Stale but harmless. | |

---

## 11-01 vs 11-02 boundary

| Option | Description | Selected |
|--------|-------------|----------|
| All README changes go to 11-02 | 11-01 only touches REQUIREMENTS.md, PROJECT.md, FAILURES.md, ROADMAP.md, and code/scripts. | ✓ |
| README changes go where discovered | Fix in-plan if gap is obvious during 11-01. | |

---

## Validation artifact archiving

| Option | Description | Selected |
|--------|-------------|----------|
| Note PASS in plan, don't commit artifacts | .planning/tmp/ gitignored; local evidence only. | ✓ |
| Commit artifact snapshot | Copy key artifacts to tracked location. | |

---

## PROJECT.md milestone Active item

| Option | Description | Selected |
|--------|-------------|----------|
| Move to Validated in 11-01 | Along with BUG-02/03/HEAL-01/02. | ✓ |
| Leave Active until /gsd-complete-milestone | Milestone-level item stays until archived. | |

---

## v2 requirements

| Option | Description | Selected |
|--------|-------------|----------|
| Leave untouched | AUTO-01/02, PROF-01 are future milestone material. | ✓ |
| Note deferred in close-out | Add explicit deferred note. | |

---

## Ubuntu install script

| Option | Description | Selected |
|--------|-------------|----------|
| Arch only | Only audit arch/nvim.sh. Ubuntu is secondary. | ✓ |
| Audit both | Verify ubuntu/nvim.sh too. | |

---

## Manual smoke table keymaps

| Option | Description | Selected |
|--------|-------------|----------|
| Add <leader>o + audit all entries | Add external-open row; verify all other rows against registry.lua. | ✓ |
| Add <leader>o only | Just the new row. | |

---

## 11-01 task sequence

| Option | Description | Selected |
|--------|-------------|----------|
| Orphaned commits first, then validate, then close-out | (1) Non-Neovim dotfiles commit. (2) Phase 10 orphan commit. (3) nvim-validate.sh all. (4) Docs close-out. | ✓ |
| Validate first, then commits | Run validator before committing orphans. | |

---

## ROADMAP.md Phase 6/7 markers

| Option | Description | Selected |
|--------|-------------|----------|
| Fix all stale ROADMAP markers | Phase 6 (2/2), Phase 7 ([x] items), Phase 8 (3/3), Phase 9 (2/2) — all in one commit. | ✓ |
| Fix only phases 8 and 9 | Leave Phase 6 and 7. | |

---

## arch/nvim.sh audit scope

| Option | Description | Selected |
|--------|-------------|----------|
| Full audit | Audit arch/nvim.sh for v1.1 accuracy. Document if unchanged. | ✓ |
| Quick check only | Verify package set, leave if no changes needed. | |

---

## Phase 4 heading rename

| Option | Description | Selected |
|--------|-------------|----------|
| Rename heading only, no content audit | Rename to "Tooling and Ecosystem Modernization". No body changes. | ✓ |
| Leave as-is | Inconsistent with Phase 2/3 renames. | |

---

## 11-02 commit strategy

| Option | Description | Selected |
|--------|-------------|----------|
| One commit per logical section | Phase Change Summary / Machine Checklist / Post-Deploy / Keymap+Headings / install script. | ✓ |
| One big commit | All README changes in one commit. | |

---

## README version marker

| Option | Description | Selected |
|--------|-------------|----------|
| No — table is sufficient | Phase-by-Phase table provides version context without header maintenance overhead. | ✓ |
| Yes — add version marker | Brief milestone line above Rollout section. | |

---

## 11-02 task sequence

| Option | Description | Selected |
|--------|-------------|----------|
| Top-to-bottom | File inventory → change summary → checklist → post-deploy → keymap section → validation harness → install script. | ✓ |
| Impact-first | Machine checklist + post-deploy first, then other sections. | |

---

## Phase 11 ROADMAP self-mark

| Option | Description | Selected |
|--------|-------------|----------|
| Mark 11 complete after 11-02 | Update ROADMAP.md Phase 11 → 2/2 Complete + date after 11-02 commits. | ✓ |
| Leave for /gsd-complete-milestone | Don't self-mark. | |

---

## Sync step description

| Option | Description | Selected |
|--------|-------------|----------|
| Generalize in 11-02 | Remove v1.0-specific plugin list; use generic "installs/uninstalls per lazy-lock.json spec." | ✓ |
| Leave v1.0 plugin list | Stale but harmless. | |

---

## Step 6 phase jargon

| Option | Description | Selected |
|--------|-------------|----------|
| Remove phase reference | Replace "Phase 5 UX-01 coherence surface" with plain language. | ✓ |
| Leave as-is | Internal phase references give source context. | |

---

## Phase 2 heading rename

| Option | Description | Selected |
|--------|-------------|----------|
| Rename + fix neo-tree reference | Rename to "Central Keymap Architecture"; remove "Per Phase 2 architecture" phrase; update plugin-local scope (remove neo-tree). | ✓ |
| Keep phase numbers | Less consistent. | |

---

## Health provider doc in Validation Harness section

| Option | Description | Selected |
|--------|-------------|----------|
| Mention :checkhealth config in audit | Add brief note about lua/config/health.lua provider. | ✓ |
| Leave as-is | Post-Deploy Verification already covers it. | |

---

## Phase 3 legacy setup note

| Option | Description | Selected |
|--------|-------------|----------|
| Remove | Delete "Before concluding Phase 3 or starting Phase 4..." historical setup guidance. | ✓ |
| Keep as historical context | Harmless, gives context. | |

---

## Central Keymap doc audit

| Option | Description | Selected |
|--------|-------------|----------|
| Audit for new/changed keymaps | Review domain taxonomy, preserved keys, and scope against v1.1 registry. | ✓ |
| No — keymap section is reference, not rollout | Architecture didn't change; leave it. | |

---

## File Inventory table

| Option | Description | Selected |
|--------|-------------|----------|
| Leave as-is | Table is for orientation only. | ✓ |
| Add config/health.lua row | Add the Phase 9 new file. | |

---

## Claude's Discretion

- Exact wording of Phase Change Summary v1.1 row ("What Changed" column prose)
- Whether Phase 4 "system-binary fallback (Phase 4)" reference is updated or left in step 4
- Order of close-out doc commits within 11-01 tasks 3 and 4
- Whether Phase 3 Validation Harness section has stale content beyond enumerated items
- Specific Phase 7 keymap changes (if any) to include in Central Keymap domain taxonomy review

## Deferred Ideas

- `.codex` and `nvim.log` gitignore — noted but out of scope
- `ubuntu/nvim.sh` audit — deferred to future
- File Inventory table update — deferred
- Windows validation harness caveat — left as-is
- REQUIREMENTS.md traceability table status columns — left as-is
