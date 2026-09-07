# Phase 16: Retire the safe profile: full-only wrapper and playbook - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-07
**Phase:** 16-retire-the-safe-profile-full-only-wrapper-and-playbook
**Areas discussed:** Profile branch in §10.3, Restore-path depth, Edit boundary, Evidence standard, Phase split, `--safe` semantics, Hook path after flip, Phase 17 roadmap entry, Wrapper surface after removals, Requirement amendment wording, Phase 16 assert scope, Rollback section, Second-pass corrections, Third-pass corrections, Fourth-pass corrections

**Note on supersession:** this discussion reversed course three times — the profile branch was collapsed, then the safe profile was retired outright, then the docs/wrapper phase split was merged back into one phase. Superseded answers are kept below with the answer that replaced them, because several of them still explain *why* the surviving decision is shaped the way it is.

---

## Profile branch in §10.3

### How should §10.3 tell the operator which profile this machine is on?

| Option | Description | Selected |
|--------|-------------|----------|
| One-command probe at top of §10.3 | `hyprctl getoption configProvider` — `lua` = full-adopted, `hyprlang` = safe. Reuses the probe §7 already documents | ✓ |
| Prose note pointing back to §7 | No new command; reader jumps sections | |
| Persisted profile marker file | New state file the wrapper writes | |

**User's choice:** the probe. **Later superseded** — the branch itself was collapsed (see Restore-path depth), so no probe is written.

### How should the full-profile apply command land in §10.3 without breaking the D-03 single-spine rule?

| Option | Description | Selected |
|--------|-------------|----------|
| One block, flag inline, one gating sentence | `./arch/dots-hyprland.sh install-files [--full]` plus one sentence gating `--full` on the probe | ✓ |
| Two labelled command blocks (safe / full) | Duplicated blocks | |
| Separate §10.5 for the full path | Second track | |

**User's choice:** one block, flag inline. **Later superseded** — §10.3 now prescribes a bare `install-files` flat.

### The bullet "Safe defaults (`--core --skip-hyprland --skip-sysupdate`) still apply on install / install-files" — keep, rewrite, or delete?

| Option | Description | Selected |
|--------|-------------|----------|
| Keep and rewrite in place | State the consequence: without `--full` the ii `hypr/` tree is not updated | ✓ |
| Delete the bullet | | |
| Keep verbatim, add a second bullet | | |

**User's choice:** conditional — *"if it no longer exists in the code then delete it."*
**Notes:** verified at the time that it still existed (`arch/dots-hyprland.sh:12`, `:1448-1449`), so it was kept and reworded. Once the merge put `SAFE_DEFAULTS` deletion in this phase, the user's own rule fired and the bullet became a delete (CONTEXT D-16).

### Does the profile distinction spread anywhere else in §10, or stay confined to §10.3?

| Option | Description | Selected |
|--------|-------------|----------|
| Confine to §10.3 | | |
| Audit all of §10 (10.1–10.4) | Sweep fork merge, pin bump, apply, protect for post-adopt falsehoods | ✓ |
| Audit §10 plus §6 apply fence | | |

**User's choice:** audit all of §10. **Notes:** survives the later reversals — CONTEXT D-18.

---

## Restore-path depth

### What does "back to dual-run" restore — live hook target only, also `stow/{waybar,rofi,swaync}`, or also the D-38 autostarts?

| Option | Description | Selected |
|--------|-------------|----------|
| Hook target only | | |
| Hook target + stow trees | | |
| Everything incl. D-38 | | |

**User's choice:** none of them — redirected: current machine state is fine, old configs just stay in the repo. No live restoration wanted.

### Given current state stays as-is and archives stay in the repo — what should the restore path be?

| Option | Description | Selected |
|--------|-------------|----------|
| Documented, not executed | Nothing runs on this machine; matches the D-18 documented-not-run precedent | ✓ |
| Documented + dry-run proof | | |
| Just state it's one-way | | |

**User's choice:** documented, not executed. **Later superseded.**

### Where does the documented restore-to-dual-run path live — new playbook section or the runbook?

| Option | Description | Selected |
|--------|-------------|----------|
| New playbook section | | |
| In the runbook | | |
| You decide | | |

**User's choice:** *"I don't need dual run anymore, so remove it completely."* No restore path is written at all. B-2 closes by retiring the destination, not by documenting the route back.

### "Remove dual-run completely" — how far does that reach?

| Option | Description | Selected |
|--------|-------------|----------|
| Docs only: retire the profile | Playbook stops presenting dual-run/safe as supported; wrapper unchanged | ✓ |
| Docs + wrapper default | | |
| Docs + delete archives | | |

**User's choice:** docs only. **Later superseded by the Edit boundary area**, which lifted D-19 and put the wrapper in scope. The archive half survives: `stow/{waybar,rofi,swaync}` stay in the repo untouched.

### With dual-run retired, does §10.3 still branch on profile?

| Option | Description | Selected |
|--------|-------------|----------|
| Collapse the branch — always full | No probe, no conditional | ✓ |
| Keep the probe as a safety check | | |
| Keep Area 1 as decided | | |

**User's choice:** collapse the branch. Supersedes the Area 1 probe and inline-`[--full]` decisions.

### You only run full. Should the playbook still describe safe at all?

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — as a warning, not a profile | | |
| Yes — keep the profiles section as-is | | |
| No — cut safe entirely | Playbook becomes full-only end to end | ✓ |

**User's choice:** cut safe entirely — *"I don't need nothing else anymore so full always, rest of the skip and stuff no need."*
**Notes:** sites recorded for the sweep — Purpose `:14`, Profiles section `:29-63`, `:166`, `:174`, `:190-192`, `:230`, `:243-247`, `:271`, `:398`, `:417`, `:517`.

---

## Edit boundary

### Phase 15 D-19 held that a documentation phase does not edit scripts. Does Phase 16 keep that line?

| Option | Description | Selected |
|--------|-------------|----------|
| Docs-only, keep D-19 | | |
| Docs + `scripts/` asserts | | |
| Docs + scripts + wrapper | D-19 lifted for this phase | ✓ |

**User's choice:** docs + scripts + wrapper. Supersedes the docs-only answer given in Restore-path depth.

### What exactly changes in `arch/dots-hyprland.sh`?

| Option | Description | Selected |
|--------|-------------|----------|
| Full becomes the default | Stop injecting SAFE_DEFAULTS; bare install behaves as `--full` does today | ✓ |
| Full default, no opt-in back | | |
| Keep default, warn loudly | | |

**User's choice:** full becomes the default, with a `--safe` opt-in preserved. **The `--safe` half was superseded** by the `--safe` semantics area — no `--safe` flag ships.

### Which audit leftovers does Phase 16 fix — IN-11, W-1, W-2?

| Option | Description | Selected |
|--------|-------------|----------|
| IN-11 preflight gate | | ✓ |
| W-2 archive path | | ✓ |
| W-1 stale rows | | ✓ |

**User's choice:** all three (multi-select).

### D-22 says phase artifacts are frozen records. How do we touch W-1/W-2 in 11-DISPOSITIONS.md?

| Option | Description | Selected |
|--------|-------------|----------|
| Annotate, don't rewrite | | |
| Correct W-2, annotate W-1 | | |
| Rewrite both in place | Overrides Phase 15 D-22 for these two sites | ✓ |

**User's choice:** rewrite both in place.

### W-3: playbook §6 duplicates the D-18 apply fence with no assert. In scope?

| Option | Description | Selected |
|--------|-------------|----------|
| Add a drift assert | Extension to `scripts/phase13-d19-assert.sh`, no new script | ✓ |
| Skip W-3 | | |
| Replace the copy with a pointer | | |

**User's choice:** *"you decide"* → decided: add the drift assert where the fence is already verified. Playbook block stays operator-runnable.

### Does the full-only rewrite reach `docs/phase14-adopt-runbook.md`?

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — sweep it too | Including its `--rotate-backup` text | ✓ |
| Only the `--rotate-backup` line | | |
| Leave the runbook alone | | |

**User's choice:** sweep it too. **Notes:** Phase 15 D-02 split roles hold — runbook stays the adopt narrative, playbook stays canonical.

### Flipping the default collides with REQUIREMENTS.md FULL-02 (`:34`), the Out-of-scope row (`:84`), and DOC-03 (`:48`). How handled?

| Option | Description | Selected |
|--------|-------------|----------|
| Amend requirements in this phase | Milestone stays internally consistent | ✓ |
| Keep the flag, drop the flip | | |
| Flip now, amend later | | |

**User's choice:** amend in this phase.

### Is PROJECT.md's dual-run/safe content in scope?

| Option | Description | Selected |
|--------|-------------|----------|
| Update current-state lines only | | |
| Full sweep incl. history | | ✓ |
| Leave PROJECT.md alone | | |

**User's choice:** full sweep incl. history.
**Notes:** caveat recorded rather than re-asked — per-phase delivered lines (`:102`, `:105`, `:109`, `:117`, `:119`, `:127`) are true statements about what those phases shipped, so they are marked superseded rather than rewritten into falsehood. Current-state claims (`:8`, `:41`, `:132`, `:160-161`) are rewritten outright.

---

## Evidence standard

### What proves the wrapper default flip works before the phase closes?

| Option | Description | Selected |
|--------|-------------|----------|
| Dry-run + assert script | New `scripts/phase16-*-assert.sh` checking argv; no live install | ✓ |
| Dry-run + assert + live install | | |
| Dry-run transcripts only | | |

**User's choice:** dry-run + assert script, same evidence shape as `phase12-full-smoke.sh`.

### What proves the docs really are full-only with no stale safe/dual-run prose?

| Option | Description | Selected |
|--------|-------------|----------|
| Forbidden-string grep in the assert | | |
| Prose review only | | |
| Grep plus a doc-sweep record | Assert greps and fails on a hit; `16-DOC-SWEEP.md` records what changed where | ✓ |

**User's choice:** grep plus a doc-sweep record.

### `scripts/phase12-full-smoke.sh` asserts the old contract that the flip breaks. What happens to it?

| Option | Description | Selected |
|--------|-------------|----------|
| Update it to the new contract | One live suite per behavior | ✓ |
| Retire it, phase16 assert takes over | | |
| You decide | | |

**User's choice:** update it.

### What is the phase gate before Phase 16 closes?

| Option | Description | Selected |
|--------|-------------|----------|
| New assert + existing suites | | |
| New assert only | | |
| Everything incl. a live re-verify | phase16 assert, `phase13-d19-assert.sh`, updated `phase12-full-smoke.sh`, `phase14-verify.sh`, plus a post-change login re-verify | ✓ |

**User's choice:** everything incl. a live re-verify. `phase14-verify.sh`'s known D-38 `[FINDING]` stays allowed, as in Phase 15.

---

## Phase split

### The scope grew past documentation. How is it split across phases?

**User's first choice:** split — Phase 16 docs, new Phase 17 wrapper. Rationale at the time: Phase 16 stays a documentation phase whose assertions hold against unmodified code, and keeping `--full` valid across both phases means no window exists in which the docs are wrong.

**User's later instruction:** *"let's merge both 16 and 17."*

**Result:** single phase. No Phase 17 exists; the Phase 16 goal line is widened instead. The merge dissolved three defects the split had created — the Phase 16 assert could not check flipped argv against unchanged code (C-1), the phase gate referenced suites rewritten in the other phase (C-2), and `--full` needed a no-op alias purely to survive the inter-phase window (C-3).

---

## `--safe` semantics

### What does the wrapper's flag surface look like once full is the default?

**User's choice:** no `--safe`. `--full` becomes an accepted no-op alias. Backups removed entirely. Protect machinery deleted entirely.

**Notes — warnings given and accepted:**
- *Backups:* an install that replaces the session then has no restore path. The user was told and chose to proceed. `~/ii-original-dots-backup` on disk is left untouched; this changes future installs only.
- *Protect:* `protect_explicit_packages` re-marks `--asexplicit` the packages upstream `./setup` installed `--asdeps`, and runs automatically after every successful install. Without it a later `yay -Yc` or `pacman -Rns $(pacman -Qtdq)` can remove hyprland, kitty, starship, cliphist, bc, jq — and the machine is already in the demoted state from the Phase 14 adopt. The user was told and chose to proceed.
- *`--full` handling:* parsed and swallowed rather than ignored, because unrecognized args fall into `user_flags` and get forwarded to `./setup` (`arch/dots-hyprland.sh:1414-1416`).
- *"Safe uninstall":* verified that the word "safe" there means "does not run `yay -Rns`" and is unrelated to the retired profile. `PROTECT_EXPLICIT` contains no waybar / rofi / swaync, so only the *dual-run* wording at `:38`, `:60`, `:85`, `:969` was stale.

---

## Hook path after flip

### The wrapper injects ii hooks into `hyprland.conf` targets. After the full adopt that file is gone. What happens to the hook machinery?

**User's choice:** delete the hook machinery.

**Notes — live state verified before deciding:**
- `~/.config/hypr/hyprland.conf` does not exist; only `.old` and `.bak` remain. `hyprctl getoption configProvider` returns `lua`.
- ii supplies the hooks itself: `~/.config/hypr/hyprland/env.lua:16` sets `ILLOGICAL_IMPULSE_VIRTUAL_ENV`; `~/.config/hypr/hyprland/execs.lua:6` runs `qs -c $qsConfig`.
- No `qs -c ii` or `ILLOGICAL_IMPULSE` line exists in `~/.config/hypr/hyprland.lua` or `~/.config/hypr/custom/`.
- `list_hypr_ii_hook_target_files` therefore resolves to exactly one file — the repo copy, which already carries both lines and which nothing loads. So `enable_hypr_ii_hooks` edits a file with no effect on the session and reports success.
- Coupling accepted: losing `disable_hypr_ii_hooks` means uninstall no longer strips hook lines, which is fine because post-adopt the live hooks live inside ii's own Lua tree that uninstall already removes.
- The repo copy is **not** deleted — WR-02 is still open on its roles.

---

## Phase 17 roadmap entry

### When and how does Phase 17 land in ROADMAP.md, and what is its stated goal?

**User's choice:** add it now, before Phase 16 is planned, via the `gsd-tools.cjs` phase handler per D-22 — never a direct ROADMAP.md edit. Goal line to name every removal.

**Superseded entirely** by the merge. Nothing is added to ROADMAP.md; the existing Phase 16 goal line is widened.

---

## Wrapper surface after removals

### What is left of the wrapper once SAFE_DEFAULTS, backups, protect, and hooks are gone?

**User's choice:** no interactive install gate at all; `uninstall` survives in stripped form.

**Notes:** `backup_gate` was the sole interactive confirm for install (Phase 11 D-11 / D-13), so deleting it removes that confirmation too — no prompt, no backup, no undo. The user was told and chose to proceed. `uninstall` keeps its own `uninstall_gate` type-yes confirm, `pacman -R` with no `-s` cascade, ii config/state removal, and `--dry-run` / `--packages-only` / `--configs-only` / `--keep-venv`. What still remains overall: preflight, ALLOWLIST validation, `--dry-run` argv preview, array-only exec, `cd` into `vendor/dots-hyprland`.

---

## Requirement amendment wording

### How are the contradicted requirement rows treated?

**User's choice:** rewrite to the new contract. Rows that can no longer be true at all are deleted rather than reworded.

**Notes:** correction made during the discussion — there is no `WRAP-04` in `.planning/REQUIREMENTS.md`, and no `WRAP-*` IDs at all (v0.2 requirements are archived). Earlier notes citing `WRAP-04` alongside `ADOPT-04` as the backup guarantees were wrong. Post-merge, rewritten rows map to Phase 16 and become checked when Phase 16 verifies, rather than being left unchecked and pending against a Phase 17 that no longer exists. Coverage falls 22/22 → 19/19.

---

## Phase 16 assert scope

### The doc assert must match docs during Phase 16 and still after Phase 17 removes `--full`. How?

| Option | Description | Selected |
|--------|-------------|----------|
| Phase 16 docs omit `--full` entirely and write bare commands | The window is accepted | ✓ |
| Phase 16 docs carry `--full` explicitly | Earlier plan | |

**User's choice:** bare commands, accepting a window in which a bare `install-files` still injects SAFE_DEFAULTS — reintroducing bug B-1 until Phase 17 landed. The user was told this and accepted it; the mitigation was a temporary visible note in the playbook.

**Partially superseded by the merge:** there is no window, so no temporary note is added and none needs removing later. What survives is the assert shape — **ban-only**: it forbids strings (no `--skip-hyprland` in §10, no "dual-run", no "safe profile") and never *requires* `--full`.

---

## Rollback section

### With ADOPT-04 deleted and backups gone, what happens to the playbook's rollback tiers?

**User's choice:** replace the tiers with a short reinstall note — recovery is a clean reinstall from the pinned submodule, the wrapper never calls upstream `./setup uninstall`, and nothing is preserved on install.

**Notes:** the fourth review pass corrected the target — the playbook has no tiers section of its own; it points at `docs/phase14-adopt-runbook.md` §14, which holds them. So the playbook loses its pointers and the tier-1-source-2 framing, and the tier list is replaced in the runbook only. `~/ii-original-dots-backup` still exists on disk but is no longer presented as a documented tier.

---

## Second-pass corrections

Full re-read of every recorded decision. Self-resolving items: the Area 1 "keep and rewrite the SAFE_DEFAULTS bullet" answer dies by the user's own rule; the Area 4 "`--safe` re-injects all three" assert clause is dead; coverage math corrected to 19 (not 20); `needs_safe_defaults()` added to the removal list.

Also settled here: INV-04 rewrite shape; the second contradicted Out-of-Scope row (`:76`); deletion of the D-36 backup block in `phase14-verify.sh`; the phase retitle and directory rename (executed during the discussion via `gsd-tools phase remove` / `phase add`, with the Progress-table row and section placement repaired by hand); and the B-2 rewrite in `v0.3-MILESTONE-AUDIT.md`.

---

## Third-pass corrections

Third full re-read, verified against source rather than notes. Surfaced: FULL-01 missing from the amendment list; the stale reason clause on Out-of-Scope row `:75`; DISP-03 needing no edit at all; CUT-01 already delivered; the grep gate needing to be scoped to `docs/` and then to the playbook alone; the W-1 rewrite constraints imposed by `phase11-dispositions-assert.sh`; false claims in playbook §9; the wrapper-before-docs ordering constraint forced by the quoted output at `:184-190`.

**Conflicts resolved (C-5 … C-8):** delete `scripts/phase07-live-smoke.sh`; delete `scripts/phase14-preflight.sh` (IN-11 closes by deletion); re-pin `WRAPPER_BASE` in `phase13-d19-assert.sh` as a third baseline tier, because the Phase 16 gate otherwise contradicts itself; amend the contradicted `ROADMAP.md` prose under a recorded D-22 exception. Also extended: the `phase14-verify.sh` edit beyond the D-36 block, and the `v0.3-MILESTONE-AUDIT.md` rewrite beyond B-2.

---

## Fourth-pass corrections

Fourth full re-read, every claim re-verified against live source rather than against recorded notes. Twelve self-resolving corrections, the substantive ones being: `backup_gate` had been recorded with two different and both-wrong line ranges; `is_help_only_user_flags` and `user_flags_contain` die with their only call sites; **`print_lines` must not be deleted** despite falling inside a recorded dead range, because three surviving uninstall helpers call it; the retained `uninstall_gate` calls protect machinery and needs its preview block removed too; `install_missing_protect_packages` and `run_protect` were never named by symbol; recorded line references drift 2-5 lines throughout, so removals must anchor on symbols; the playbook has no rollback-tiers section; `phase11-dispositions-assert.sh` was missing from the gate; `phase10-inventory-assert.sh` is correctly left alone; `16-DOC-SWEEP.md` must land in the same wave as the re-pin to avoid a failing window; `.planning/research/*`, `MILESTONES.md` and `RETROSPECTIVE.md` stay untouched; no runner invokes anything in `scripts/`, and `README.md` needs no edit.

### `.planning/codebase/` handling

| Option | Description | Selected |
|--------|-------------|----------|
| Leave; re-run map-codebase after | Six dated regenerable snapshots; hand-correcting duplicates the mapper's work | ✓ |
| Hand-sweep the falsified sites | | |

**User's choice:** leave them; re-run `/gsd-map-codebase` after the phase. **Supersedes the C-5 cascade** instruction to hand-sweep `TESTING.md`, `CONVENTIONS.md` and `CONCERNS.md`; those sites ride on the re-map instead. Recorded as a post-phase operator step.

### `.planning/STATE.md` handling

| Option | Description | Selected |
|--------|-------------|----------|
| Full sweep incl. history | | ✓ |
| Update current-state lines only | | |

**User's choice:** full sweep incl. history. **Notes:** caveat recorded, not re-asked — same treatment already agreed for PROJECT.md under the identical answer. Current-state claims (`:73`, `:74`, `:119`, and the Next-Steps item still describing Phase 16 by its retired B-1/B-2 scope) are rewritten; per-phase delivered lines (`:78`, `:82`, `:83`, `:90`, `:107`, `:149`, `:155`) are marked superseded.

---

## Claude's Discretion

- **W-3 handling shape** — user said "you decide"; decided as a drift assert extending `scripts/phase13-d19-assert.sh` rather than a new script.
- Section ordering, heading names and prose voice inside the rewritten playbook, within the Phase 15 D-03 single-spine rule.
- The exact wording of the "superseded" annotation used across `PROJECT.md`, `STATE.md` and `REQUIREMENTS.md`.
- Wave decomposition, beyond the two hard ordering constraints (wrapper before docs; `16-DOC-SWEEP.md` with the re-pin).

## Deferred Ideas

- **WR-02** — the three roles of the repo copy `.config/hypr/hyprland.conf`. The hook-injection role dies here; the question stays open.
- **D-38 restoration** — the `graphical-session.target` / `hyprland-session.service` bootstrap, xdg-desktop-portal ScreenCast, `wl-clip-persist`, and the four workspace-pinned autostarts. Still unowned.
- **Post-phase `/gsd-map-codebase`** to refresh the six `.planning/codebase/` snapshots.
- **CUST-01..03** and **POLISH-01..03** remain future requirements; only the dual-run justification in their Out-of-Scope reason clause is reworded.
- **Dual-run restore path** — considered at length, then retired outright at the user's direction. Recorded here so a future reader knows it was decided against, not forgotten.
