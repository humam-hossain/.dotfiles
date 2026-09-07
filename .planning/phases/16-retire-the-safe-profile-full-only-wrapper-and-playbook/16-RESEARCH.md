# Phase 16: Retire the safe profile: full-only wrapper and playbook - Research

**Researched:** 2026-09-07
**Domain:** Bash wrapper refactor (deletion-heavy) + coupled operator-documentation rewrite + planning-artifact amendment, all gated by in-repo assert scripts
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Phase shape and edit boundary**

- **D-01:** One merged phase. Phase 16 changes the wrapper contract and the documentation together. No Phase 17 is added to the roadmap; the existing Phase 16 goal line is widened to cover the wrapper change instead. The earlier docs/wrapper split created three defects that all dissolve on merge — the phase assert could not check flipped argv against unchanged code, the phase gate referenced suites rewritten in the other phase, and `--full` needed a no-op alias purely to survive the inter-phase window.
- **D-02:** Phase 15 **D-19** ("a documentation phase does not edit scripts") is **lifted for this phase**. Edits reach `docs/`, `scripts/`, and `arch/dots-hyprland.sh`.
- **D-03:** Phase 15 **D-22** (phase artifacts are frozen records; no direct `ROADMAP.md` edits) is **overridden at named sites only**: the W-1 and W-2 rewrites in `.planning/phases/11-disposition-decisions/11-DISPOSITIONS.md`, and the `ROADMAP.md` milestone prose plus coverage line. The exception is recorded because no `gsd-tools.cjs` query handler edits milestone prose or success criteria. Everything else under `.planning/phases/**` and `.planning/milestones/**` stays frozen.

**Wrapper contract — `arch/dots-hyprland.sh`**

- **D-04:** Full becomes the only behavior. Delete the `SAFE_DEFAULTS` array (`:12`) and the injection branch (around `:1443-1454`, the block carrying `[CONFIG] safe defaults:` and `[CONFIG] full profile: no SAFE_DEFAULTS injection (DISP-02 drop-all-three)`). `needs_safe_defaults()` (`:141`) and the Phase 12 D-02 validation restricting `--full` to `install` / `install-files` (around `:1420-1425`) become dead and go with it. — **Reversibility:** costly — undoing the flip means reverting the wrapper, the playbook, `phase12-full-smoke.sh`, the phase16 assert and six amended requirement rows together; they are written as one consistent contract.
- **D-05:** No `--safe` flag is added. `--full` stays **parsed as an accepted no-op alias**: it prints a note that full is now the default and the flag is ignored, and it is **never forwarded to upstream `./setup`**. This avoids the unknown-flag forwarding hazard at `:1414-1416`, where unrecognized args fall through into `user_flags`, and keeps old transcripts and muscle memory working.
- **D-06:** Backups are removed entirely. Delete `backup_gate` (symbol starts `:166`; the next symbol, `is_help_only_user_flags`, starts `:196`), delete `II_BACKUP_DIR` (`:21`), and pass `--skip-backup` to `./setup` by default. The `--allow-skip-backup` dual-key guard goes with it, and `is_help_only_user_flags` (`:196`) and `user_flags_contain` (`:211`) die because their only call sites (`:1439` and `:1431`) are inside deleted code. The existing `~/ii-original-dots-backup` snapshot on disk is left untouched — this changes future installs only. **The user was told that an install which replaces the session then has no restore path, and chose to proceed.** — **Reversibility:** one-way — once an install runs with no snapshot, the pre-install configuration state is gone; re-adding the gate later cannot recover it.
- **D-07:** The protect machinery is deleted entirely — function, auto-run after install, subcommand, and the `PROTECT_EXPLICIT` array. Symbols to remove: `PROTECT_EXPLICIT` (`:230`), `resolve_real_package_name` (`:307`), `collect_installed_protect_packages` (`:316`), `collect_missing_protect_packages` (`:332`), `protect_explicit_packages` (`:349`), `install_missing_protect_packages` (`:391`), `run_protect` (`:418`). Call sites: the `protect` entry in `ALLOWLIST` (`:14`), the `--help` sections (around `:46`, `:84-90`), the post-install hooks (`:1466`, `:1486`), the subcommand dispatch (`:1523`), the `run_safe_uninstall` calls (around `:1113` and `:1170`) with the now-dead `--skip-protect`, **and the protect-preview block inside `uninstall_gate` (around `:967`)** — `uninstall_gate` is kept, so leaving that block would call a deleted function. **`print_lines` (`:296`) must NOT be deleted**: it falls inside the range the earlier notes called dead, but it has three live callers in surviving uninstall machinery (`collect_ii_meta_packages` `:500`, `collect_ii_config_targets` `:529`, `collect_ii_state_targets` `:539`). **The user was told that `protect_explicit_packages` re-marks `--asexplicit` the packages upstream `./setup` installed `--asdeps`, that without it a later `yay -Yc` or `pacman -Rns $(pacman -Qtdq)` can remove hyprland, kitty, starship, cliphist, bc and jq, and that the machine is already in the demoted state from the Phase 14 adopt — and chose to proceed.** — **Reversibility:** costly — restoring it means rebuilding the `PROTECT_EXPLICIT` package list and its four collect helpers from git history; in the meantime an orphan sweep can remove the personal stack.
- **D-08:** The ii-hook machinery is deleted entirely. Symbols: `list_hypr_ii_hook_target_files` (`:651`), `list_active_hypr_ii_hook_files` (`:668`), `list_any_hypr_ii_hook_files` (`:692`), `file_has_active_ii_hooks` (`:714`), `file_has_commented_ii_hooks` (`:720`), `warn_hypr_ii_hooks` (`:727`), `disable_hypr_ii_hooks` (`:747`), `enable_hypr_ii_hooks` (`:789`). Call sites: post-setup enable at `:1468` (dry-run) and `:1489` (real), uninstall disable at `:1146` and `:1237`, the warn calls at `:1149` and `:1239`, the `--keep-hypr-hooks` flag and its case arm (around `:1345`), and the `uninstall_gate` hook parameter. Justified by verified live state: `~/.config/hypr/hyprland.conf` no longer exists (only `.old` and `.bak`), the session loads via `hyprland.lua`, and ii supplies the hooks itself in `~/.config/hypr/hyprland/env.lua:16` (`ILLOGICAL_IMPULSE_VIRTUAL_ENV`) and `~/.config/hypr/hyprland/execs.lua:6` (`qs -c $qsConfig`). `list_hypr_ii_hook_target_files` therefore resolves to exactly one file — the repo copy `REPO_ROOT/.config/hypr/hyprland.conf` — which already carries both lines and which nothing loads. Losing `disable_hypr_ii_hooks` is acceptable: post-adopt the live hooks are inside ii's own Lua tree, which `uninstall` already removes as ii-owned config. The repo copy keeps its two hook lines as dead archive; it is not deleted, because WR-02 is still open on its roles. — **Reversibility:** costly.
- **D-09:** There is no interactive install gate at all after `backup_gate` is deleted. `install` / `install-files` run upstream `./setup` immediately, with `--skip-backup` and no type-yes prompt — `backup_gate` was the sole install confirmation (Phase 11 D-11 / D-13). **The user was told: no prompt, no backup, no undo — and chose to proceed.** — **Reversibility:** one-way, for the same reason as D-06.
- **D-10:** `uninstall` survives in stripped form. **Keeps:** `uninstall_gate` (`:936`) and its own type-yes confirm, `pacman -R` on `illogical-impulse-*` with no `-s` cascade, removal of ii configs and state, and the `--dry-run`, `--packages-only`, `--configs-only`, `--keep-venv` flags. **Loses:** protect re-marking with `--skip-protect`, and hook stripping with `--keep-hypr-hooks`.
- **D-11:** After the removals the wrapper still provides: the `preflight` submodule/executable check (`:149`), `ALLOWLIST` subcommand validation (`:14`), `--dry-run` argv preview, array-only exec (never `eval`), `cd` into `vendor/dots-hyprland`, and the stripped `uninstall`.
- **D-12:** **Anchor every wrapper removal on a symbol name, not a line range.** Line references recorded during discussion drift 2-5 lines from live source (`:1111`→`:1113`, `:1165`→`:1170`, `:732`→`:727`, `:1346`→`:1345`, `:315-348`→`:316-348`), and `backup_gate` was recorded twice with two different, both-wrong ranges. Line numbers in this document are navigation aids only.
- **D-13:** The word "safe" in "safe uninstall" means "does not run `yay -Rns`" and is unrelated to the retired safe profile. `PROTECT_EXPLICIT` was verified to contain no waybar / rofi / swaync, so only the stale *dual-run* wording at `:38`, `:60`, `:85`, `:969` was wrong — and that wording is removed along with the machinery it described.

**Documentation — `docs/dots-hyprland-workflow.md`**

- **D-14:** The playbook becomes full-only end to end. Every `install` / `install-files` example is a **bare command with no `--full`**, correct the moment the wrapper lands in the same phase. No temporary "requires the new wrapper" window note is added, and none needs removing later.
- **D-15:** Safe-profile and dual-run prose is removed, not softened. Known sites: Purpose `:14`, the whole "Profiles: safe vs full" section `:29-63`, `:166`, `:174`, `:190-192`, `:230`, `:243-247`, `:271`, `:398`, `:417`, `:517`.
- **D-16:** The bullet "Safe defaults (`--core --skip-hyprland --skip-sysupdate`) still apply on `install` / `install-files`" is **deleted**, not rewritten. It was conditionally kept during discussion under the user's own rule — "if it no longer exists in the code then delete it" — and D-04 deletes it from the code.
- **D-17:** §10.3 prescribes `./arch/dots-hyprland.sh install-files` flat. No `hyprctl getoption configProvider` profile probe, no conditional, no duplicated safe/full command blocks. The D-03 single-spine rule from Phase 15 holds.
- **D-18:** All of §10 is swept, not just §10.3 — §10.1 fork merge, §10.2 pin bump, §10.3 apply, §10.4 protect — for post-adopt falsehoods. The §10.4 protect content goes with D-07. The §10.3 apply-hop fix is the required core.
- **D-19:** The playbook stops describing the wrapper as the thing that injects ii hooks, and states that after a full adopt **ii owns them** in `hyprland/env.lua` and `hyprland/execs.lua`.
- **D-20:** Rollback. **The playbook has no rollback-tiers section of its own** — `:219`, `:428` and `:529` deliberately point at `docs/phase14-adopt-runbook.md` §14, which holds the tiers. So the playbook loses those pointers and the tier-1-source-2 framing at `:413` and `:419-428`, and **the tier list itself is replaced in the runbook only**. The replacement text: recovery is a clean reinstall from the pinned submodule, the wrapper never calls upstream `./setup uninstall`, and nothing is preserved on install. `~/ii-original-dots-backup` still exists on disk but is no longer presented as a documented rollback tier.
- **D-21:** §9 claims that go false in this phase are corrected: `:421` says `uninstall` deletes the two ii hook lines from the repo copy (untrue once D-08 lands), and `:432-438` warns against rotating the backup (moot once backups are retired and `phase14-preflight.sh` is deleted — delete that prohibition outright, the script it prohibits will not exist). WR-02 itself stays deferred.
- **D-22:** The cross-references at `:18-19`, which point at wrapper help for safe defaults, the backup gate and protect behavior, are rewritten to match the surviving flag surface.
- **D-23:** `:184-190` quotes exact wrapper output strings, including `[CONFIG] full profile: no SAFE_DEFAULTS injection (DISP-02 drop-all-three)`. Those quotes must be re-taken from **real post-change output**, which forces the ordering constraint in D-38.

**Documentation — `docs/phase14-adopt-runbook.md`**

- **D-24:** The runbook is swept by hand, including its `--rotate-backup` text and its §14 tier list (D-20). Phase 15 **D-02** split roles hold: the runbook stays the adopt-window narrative, the playbook stays canonical. Correcting falsehoods is not the same as restructuring it.
- **D-25:** §5 becomes historical narrative rather than a runnable step, because `scripts/phase14-preflight.sh` is deleted (D-33). Invocation sites: `:81`, `:84`, `:100`, `:146`, `:149`, `:153`.

**Requirements and planning-artifact amendments**

- **D-26:** `.planning/REQUIREMENTS.md` is amended in this phase so the milestone stays internally consistent. Per row:

  | Row | Treatment |
  |---|---|
  | `INV-04` (`:16`) | Rewrite: drop "and that safe dual-run install remains available after this milestone"; keep the inventory-records-`SAFE_DEFAULTS` half, which is a true statement about what Phase 10 captured. Stays checked, stays mapped to Phase 10. |
  | `DISP-03` (`:22`) | **No edit.** It reads "defaults to keep **unless explicitly accepted otherwise**", and Phase 11 D-11 explicitly accepted otherwise. Still true; stays checked, mapped to Phase 11. |
  | `FULL-01` (`:33`) | Rewrite — "documented explicit opt-in full-install path" is contradicted once full is the default. |
  | `FULL-02` (`:34`) | Rewrite — the default becomes full. |
  | `FULL-03` (`:35`) | **Delete** the row and its mapping entry (`:100`) — the backup gate is gone. |
  | `FULL-04` (`:36`) | Survives; `--dry-run` stays. Reword only its `SAFE_DEFAULTS` clause; keep checked. |
  | `FULL-05` (`:37`) | **Delete** the row and its mapping entry (`:102`) — protect is gone. |
  | `ADOPT-03` (`:43`) | Rewrite to drop the dual-run clause. |
  | `ADOPT-04` (`:44`) | **Delete** outright with its mapping entry (`:109`). With backups and protect removed no rollback guarantee is being made; deleting is more honest than rewriting. |
  | `DOC-03` (`:48`) | Rewrite to the full-only playbook contract; drop "safe vs". |
  | `CUT-01` (`:64`, Future Requirements) | Annotate as superseded — already delivered by Phase 11 D-11 and the Phase 14 adopt. Outside the coverage count. |
  | Out of Scope `:75` | Reword the reason clause "dual-run remains valid"; the row stands, CUST-01..03 remain deferred. |
  | Out of Scope `:76` | **Remove** — "Removing Waybar/rofi/swaync by default (CUT-01) \| Only if DISP-03 explicitly accepts; default keep" is contradicted. |
  | Out of Scope `:84` | **Remove** — "Making full profile the default wrapper behavior \| Safe defaults remain default" is contradicted. |

  There is no `WRAP-04` in `.planning/REQUIREMENTS.md` — no `WRAP-*` IDs at all; v0.2 requirements are archived. Earlier notes citing it were wrong.
- **D-27:** Rewritten rows map to **Phase 16** and become checked when Phase 16 verifies. Deleted IDs drop from both the checklist and the traceability table. **v0.3 coverage falls from 22/22 to 19/19** (22 minus `FULL-03`, `FULL-05`, `ADOPT-04`).
- **D-28:** `.planning/ROADMAP.md` prose is amended under the D-03 exception: `:11` (milestone description — "wrapper gains an explicit full profile while safe defaults remain the default; playbook documents safe vs full"), `:13` ("Not this milestone: … default removal of Waybar/rofi/swaync (CUT-01)"), `:69` (Phase 10 success criterion 4, whose "remains available after this milestone" half mirrors `INV-04`), and the coverage line 22/22 → 19/19. **Leave as history:** `:52` (Phase 12 line), `:103` (Phase 11 criterion 3), `:131` (Phase 12 criterion 2), `:174` (Phase 14 criterion 3). The Phase 16 goal line itself, currently `[To be planned]`, is filled by the planner to cover the wrapper contract change plus the documentation retirement.
- **D-29:** `.planning/PROJECT.md` gets a full sweep including history, under this rule: **current-state claims are rewritten** (`:8`, `:41`, `:132`, `:160-161`); **per-phase delivered lines are marked superseded, not rewritten** (`:102`, `:105`, `:109`, `:117`, `:119`, `:127`), because they are true statements about what those phases shipped and rewriting them would make the file assert falsehoods. `:125` ("enforced by `scripts/phase14-preflight.sh`") is marked superseded on the same rule.
- **D-30:** `.planning/STATE.md` gets the same treatment. **Rewrite as current state:** `:73` ("Thin `arch/dots-hyprland.sh` only; SAFE_DEFAULTS + backup gate; array-exec `./setup`" — only array-exec survives), `:74` (personal hypr hooks for env + `qs -c ii` — ii now owns them), `:119` (Operator-Next-Step 5, "Default `install` without `--full` still injects SAFE_DEFAULTS"), and Operator Next Steps item 1 (`:113-119`), which still describes Phase 16 by its retired B-1/B-2 scope. **Mark superseded:** `:78` (v0.3 "not blind drop of SAFE_DEFAULTS" framing), `:82` (Phase 11 residual-still-default), `:83` (Phase 12 `--full` meta), `:90` (Phase 14 three-tier rollback), `:107` (IN-11 — closes with the `phase14-preflight.sh` deletion), `:149` (Phase 6), `:155` (Phase 10).
- **D-31:** `.planning/v0.3-MILESTONE-AUDIT.md` is rewritten at: **B-1** (`:27-32`, `:234`) — closed by the wrapper flip, not by adding `--full` to §10.3; **B-2** (`:33-38`, `:235`) — closed by *retiring* dual-run, not by documenting a route back to it; DISP-03 evidence (`:25`); Flow B (`:61`) and Flow C (`:65`); tech-debt IN-11 (`:70`); cosmetic INFO 2 (`:71`, moot after the `phase14-verify.sh` deletions).
- **D-32:** W-1 and W-2 are rewritten **in place** in `.planning/phases/11-disposition-decisions/11-DISPOSITIONS.md` — `:108-112` (stale migrate-to-hypr-custom rows) and `:201` (archive path says `.config/`, actual location is `stow/`). **Constraint:** `scripts/phase11-dispositions-assert.sh` gates that file. The rewrite must preserve the literal tokens `--core`, `--skip-hyprland`, `--skip-sysupdate` and `migrate-to-hypr-custom`, and must leave the D-10 residual-language sentence intact, or `:130-141` and `:164-190` of that assert fail.

**Scripts and evidence**

- **D-33:** Delete `scripts/phase07-live-smoke.sh` and `scripts/phase14-preflight.sh`. The live-smoke script asserts the protect subcommand, `--skip-protect`, hook disable, `SAFE_DEFAULTS` dry-run output and dual-run Waybar — every one of which this phase removes. The preflight script loses far more than IN-11: also the D-26 protect assert (`:277-281`), the D-13/D-27 backup rotation path (`:75-90`, `:242-267`) and the gate-fed `install --full` check (`:297-307`); the adopt it gated already happened and nothing re-runs it. **IN-11 closes by deletion**, superseding the earlier plan to fix its `--rotate-backup` message — and with it the tech-debt entry at `v0.3-MILESTONE-AUDIT.md:70` and the open-review entry at `STATE.md:107`. No Makefile, CI workflow or `.claude` hook invokes anything in `scripts/`, so neither deletion has a runner to update.
- **D-34:** Rewrite `scripts/phase12-full-smoke.sh` to the new contract rather than retiring it — one live suite per behavior. Its current assertions to replace: `FULL-01` (`:63-73`), `FULL-02` (`:96-102`, which requires the residuals to be present), `:110-111`, `FULL-03` (`:122-125`), `FULL-03b` (`:129-134`), `FULL-05` (`:143-148`), and the `install-deps --full` rejection at `:153`.
- **D-35:** Add a new `scripts/phase16-*-assert.sh` in the same evidence shape as `phase12-full-smoke.sh` — dry-run argv only, no live install. It asserts: bare `install-files --dry-run` emits none of `--core` / `--skip-hyprland` / `--skip-sysupdate`; `--full` is still accepted, prints the ignored-note, and is **not** forwarded to `./setup`. The earlier "`--safe` re-injects all three" clause is dead (D-05).
- **D-36:** The same assert carries the doc forbidden-string grep, **scoped to `docs/dots-hyprland-workflow.md` only**. It is ban-only: it forbids strings (no `--skip-hyprland` in §10, no "dual-run", no "safe profile") and never *requires* `--full`. `.planning/` artifacts legitimately carry that history, and `scripts/phase10-inventory-assert.sh:136` and `scripts/phase11-dispositions-assert.sh:139` actively require it to be present. `docs/phase14-adopt-runbook.md` is swept by hand but **not** grep-gated — it is the adopt-window historical record under Phase 15 D-02, and banning the tokens there would force rewriting a true record of what the adopt ran.
- **D-37:** `scripts/phase14-verify.sh` edits. **Delete:** `:374-378` (ADOPT-04 tier-1 source 3 presence/non-empty check on `$BACKUP_DIR`), `:386-390` (ADOPT-04 tier 3 `protect --dry-run`), `:394-420` (the D-36 backup sha256/mtime block — no future install produces a backup; the existing snapshot stays on disk, only the check goes). **Keep:** `:380-385` (tier 2 `uninstall --dry-run`, since uninstall survives) with its ADOPT-04 label rewritten, and `:313-328` (the Waybar/rofi/swaync accept-remove asserts, which the retirement reinforces). **Reword:** `:521`, whose D-38 finding text cites `PROTECT_EXPLICIT`, which will not exist.
- **D-38:** `scripts/phase13-d19-assert.sh` gets two changes. (1) **Re-pin.** Its `WRAPPER_BASE` check (`:146-158`) fails by design whenever `arch/dots-hyprland.sh` differs from the pinned `14c6828`, and the Phase 16 gate runs that script — as written the gate contradicts itself. Add a **third baseline tier** following the file's own two-tier precedent, keyed on a Phase 16 marker file (`16-DOC-SWEEP.md`), pinned to the commit that lands the wrapper rewrite. (2) **W-3.** Add the fence-drift assert here rather than in a new script: playbook §6 duplicates the Phase 13 D-18 apply fence with nothing checking the copy, and this script is already where that fence is extracted and executed. The playbook block stays operator-runnable.
- **D-39:** Leave `scripts/phase10-inventory-assert.sh` alone. `:135-136` keeps requiring "safe/default dual-run remains available" language in `10-INVENTORY.md` after `INV-04` loses that clause. That is not a conflict — the assert verifies a frozen record of what Phase 10 captured, not current policy.
- **D-40:** **Phase gate before Phase 16 closes:** the new phase16 assert, `scripts/phase13-d19-assert.sh`, the rewritten `scripts/phase12-full-smoke.sh`, `scripts/phase14-verify.sh`, `scripts/phase11-dispositions-assert.sh` (added because the W-1 rewrite can break it), plus a **post-change live login re-verify** of the session. `phase14-verify.sh`'s known D-38 `[FINDING]` stays allowed, as in Phase 15.
- **D-41:** Write `16-DOC-SWEEP.md` recording what changed where, same shape as `15-DOC-SWEEP.md`.

**Sequencing constraints**

- **D-42:** **The wrapper commit must land before the documentation commit.** The playbook quotes exact wrapper output (D-23); docs written first would quote strings the code no longer prints.
- **D-43:** The `phase13-d19-assert.sh` re-pin commit follows the wrapper commit and cites its SHA. **`16-DOC-SWEEP.md` must land in the same wave as the re-pin, ahead of the gate** — the new third tier keys on that file's presence, so between the wrapper commit and the sweep file the assert would fail on every run.

### Claude's Discretion

- **W-3 handling shape** — the user answered "you decide" on whether the duplicated §6 apply fence was in scope. Decided: in scope, as an extension to `scripts/phase13-d19-assert.sh`, no new script (D-38).
- Section ordering, heading names and prose voice inside the rewritten playbook, within the Phase 15 D-03 single-spine rule.
- The exact wording of the "superseded" annotation used in `PROJECT.md`, `STATE.md` and `REQUIREMENTS.md`, as long as one form is used consistently.
- Wave decomposition, beyond the two hard ordering constraints in D-42 and D-43.

### Deferred Ideas (OUT OF SCOPE)

- **WR-02** — the three roles of the repo copy `.config/hypr/hyprland.conf` (rollback source, frozen D-36 evidence, pre-adopt hook-injection target). The hook-injection role dies in this phase, but the question of what the file is for stays open and unowned.
- **D-38 restoration** — the `graphical-session.target` / `hyprland-session.service` bootstrap lost with the renamed conf, affecting xdg-desktop-portal ScreenCast, `wl-clip-persist`, and the four workspace-pinned autostarts. Documented as a known loss in Phase 15; still no owner. `phase14-verify.sh` keeps emitting it as an allowed `[FINDING]`.
- **`/gsd-map-codebase` re-run after this phase.** The six `.planning/codebase/` snapshots (all stamped `2026-08-21`) describe the wrapper as it is now and go false in this phase. They are dated regenerable snapshots, not hand-maintained contracts, so they are **left untouched here** and refreshed by the mapper afterwards. Sites left to the re-map: `ARCHITECTURE.md:66, :138, :141, :153, :173, :260`; `STRUCTURE.md:107`; `STACK.md:65, :89`; `CONVENTIONS.md:11, :79, :83`; `CONCERNS.md:133`; `TESTING.md:24, :60, :113, :171`.
- **Pre-milestone research and v0.2 history stay untouched** — `.planning/research/{ARCHITECTURE,FEATURES,PITFALLS,STACK,SUMMARY}.md`, `.planning/MILESTONES.md:15`, `.planning/RETROSPECTIVE.md:14, :37`. Same class as `.planning/phases/**`: records of what was true when written.
- **CUST-01..03** (Waybar ping/weather/earthquake module ports into ii) and **POLISH-01..03** remain future requirements. This phase only rewords the Out-of-Scope reason clause that justified them by dual-run.
- **`README.md`** needs no edit — its single mention of `arch/dots-hyprland.sh` (`:5`) carries no profile or backup claim.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

ROADMAP.md line 223 reads `**Requirements**: TBD` — no requirement IDs are mapped to Phase 16 today. Coverage is derived from the CONTEXT.md D-26 amendment table plus the v0.3 audit leftovers the phase closes.

| ID | Description (post-amendment) | Research Support |
|----|------------------------------|------------------|
| `FULL-01` | Rewritten: the wrapper's only install path is full — no residual injection on any subcommand | Verified injection branch at `arch/dots-hyprland.sh:1443-1454`; §"Wrapper Surgery Map" gives exact symbol anchors; §"Code Examples" gives the replacement `run_install_family` skeleton |
| `FULL-02` | Rewritten: bare `install` / `install-files` **is** the full behavior | Verified current text at `REQUIREMENTS.md:34`; the assert that proves the flip is specified in §"Validation Architecture" |
| `FULL-04` | Reworded: `--dry-run` shows argv; the `SAFE_DEFAULTS` clause drops | Verified `--dry-run` block at `:1459-1473` survives; only the mirrored protect/hook calls inside it are deleted |
| `ADOPT-03` | Rewritten: dual-run clause dropped | `phase14-verify.sh:313-328` (kept per D-37) is the executable evidence; verified green this session |
| `DOC-03` | Rewritten: full-only playbook contract | §"Playbook Sweep Inventory" is the verified site list |
| `FULL-03`, `FULL-05`, `ADOPT-04` | **Deleted** rows + mapping entries | Verified row lines `:35`, `:37`, `:44` and mapping lines `:100`, `:102`, `:109`; coverage arithmetic confirmed 22 → 19 |
| `INV-04` | Rewritten but stays mapped to Phase 10 | Verified `REQUIREMENTS.md:16`; interacts with `phase10-inventory-assert.sh:135-140` (D-39 leaves the assert alone) |
| Audit leftover `IN-11` | Closes by deleting `scripts/phase14-preflight.sh` | Verified no runner exists (no Makefile, no `.github/workflows`) |
| Audit leftover `W-1` | `11-DISPOSITIONS.md:107-110` stale migrate rows | Exact rows read this session; assert constraints enumerated |
| Audit leftover `W-2` | `11-DISPOSITIONS.md:201` archive path | Verified `.config/{waybar,rofi,swaync}` does **not** exist; `stow/` does |
| Audit leftover `W-3` | Playbook §6 fence duplicates the D-18 SoT fence | Verified byte-identical after stripping one line — exact diff recorded in §"Code Examples" |
</phase_requirements>

---

## Summary

This phase is a **deletion refactor with a documentation contract attached**, not a feature build. Nothing new is installed; no external package enters the repo. The entire technical risk lives in three places: (1) deleting seven-plus Bash functions without leaving a dangling call site in the machinery that survives, (2) keeping five assert scripts green across a change designed to falsify what four of them assert, and (3) not letting the documentation quote strings the code stopped printing.

Research confirmed every load-bearing factual premise in CONTEXT.md against live source this session. The upstream `./setup` **does** accept `--skip-backup` (D-06 is feasible), the live session **has** no `~/.config/hypr/hyprland.conf` and **does** load through `hyprland.lua` with ii owning both hooks in its own Lua tree (D-08 is justified), `PROTECT_EXPLICIT` **does** contain `hyprland`, `kitty`, `starship`, `cliphist`, `bc` and `jq` and **does not** contain Waybar/rofi/swaync (D-07's warning and D-13's reading are both correct), and the two apply fences W-3 names are byte-identical after stripping exactly one comment line. All five gate scripts are green at baseline.

Research also found **four hazards CONTEXT.md does not name**, each of which would fail the phase gate if unaddressed: `phase14-verify.sh` asserts a **clean git working tree** (`D-35`, `:538-558`), so the gate cannot run on uncommitted edits; `II_BACKUP_DIR` has **two call sites beyond its definition** (`:1044-1045`, `:1248-1249`) that D-06 does not enumerate; the protect and hook machinery each have **one surviving call site in the `run_safe_uninstall` tail** (`:1245`, `:1274`) that D-07 and D-08 do not enumerate; and the playbook §7 verify block plus the `phase14-verify.sh` **FINDINGS count are coupled to each other** and to the D-37 deletions. In addition, the wrapper's removal of its own gate does **not** make install non-interactive — upstream `./setup` runs its own `pause()` and greeting, so the playbook must not claim an unattended install.

**Primary recommendation:** Sequence as five waves — (1) wrapper surgery + `bash -n` + rewritten `phase12-full-smoke.sh`, committed together; (2) `phase14-verify.sh` and `phase07-live-smoke.sh`/`phase14-preflight.sh` deletions; (3) the new `phase16` assert plus the documentation rewrite, with output strings re-captured from the wave-1 binary; (4) `16-DOC-SWEEP.md` + the `phase13-d19-assert.sh` re-pin and W-3 drift assert, committed together citing the wave-1 SHA; (5) planning-artifact amendments, then the gate on a clean tree. Anchor every wrapper edit on a symbol name via `grep -n '^symbol()'`, never on a line number from any document including this one.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Install argv construction | Wrapper (`run_install_family`) | — | The wrapper is the only place a flag decision reaches upstream argv; the injection branch at `:1443-1454` is the single seam [VERIFIED: arch/dots-hyprland.sh:1443-1454] |
| Subcommand admission | Wrapper (`ALLOWLIST` `:14` + `is_allowlisted` `:132`) | `main` dispatch `:1516-1526` | Dropping `protect` from `ALLOWLIST` is what retires the subcommand; deleting `run_protect` alone leaves a dispatch hole [VERIFIED: arch/dots-hyprland.sh:14,132,1523] |
| Backup decision | **Upstream** (`sdata/subcmd-install/3.files.sh:219`) | Wrapper (passes `--skip-backup`) | `SKIP_BACKUP` is consumed by upstream only; the wrapper's role reduces to setting one flag [VERIFIED: vendor/dots-hyprland/sdata/subcmd-install/3.files.sh:219] |
| Install confirmation prompt | **Upstream** (`pause()`, `0.greeting.sh`) | — after D-09 | Deleting `backup_gate` removes the *wrapper's* prompt; upstream's own prompts remain [VERIFIED: vendor/dots-hyprland/sdata/lib/functions.sh:64-70] |
| Session hook ownership | **ii Lua tree** (`hyprland/env.lua`, `hyprland/execs.lua`) | — after D-08 | Post-adopt ii supplies both hooks; the wrapper's injection machinery has no live target [VERIFIED: ~/.config/hypr/hyprland/env.lua:16, ~/.config/hypr/hyprland/execs.lua:6] |
| Package explicit-marking | **Nothing** after D-07 | operator (`pacman -D --asexplicit`, manual) | The capability is removed, not relocated. This is an accepted loss, recorded in D-07 |
| ii removal | Wrapper (`run_uninstall` / `uninstall_gate` / `run_safe_uninstall`) | — | Survives stripped; the only interactive gate left in the wrapper [VERIFIED: arch/dots-hyprland.sh:936,1084,1316] |
| Contract enforcement | `scripts/phase*-assert.sh` + `phase12-full-smoke.sh` | git (`WRAPPER_BASE` drift pin) | Executable asserts, not prose, are the contract of record in this repo |
| Operator narrative | `docs/dots-hyprland-workflow.md` (canonical) | `docs/phase14-adopt-runbook.md` (historical) | Phase 15 D-02 split roles; preserved here |

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| GNU Bash | 5.3.15(1) | Wrapper and all assert scripts | Already the repo's only scripting runtime for `arch/` and `scripts/` [VERIFIED: `bash --version`] |
| git | 2.55.0 | `WRAPPER_BASE` drift detection, submodule pin | `phase13-d19-assert.sh:146-158` uses `git cat-file -e` + `git diff --name-only` [VERIFIED: scripts/phase13-d19-assert.sh:146-158] |
| GNU coreutils | system | `sha256sum`, `cmp`, `diff`, `stat`, `realpath` in asserts | Existing assert vocabulary; no new dependency |
| python3 | 3.14.7 | Fence extraction in `phase13-d19-assert.sh` | The script already embeds a `python3 - <<'PY'` heredoc to pull the D-19 fence out of Markdown [VERIFIED: scripts/phase13-d19-assert.sh:28-44] |
| jq | 1.8.2 | `hyprctl -j status \| jq -r .configProvider` in playbook §7 | Already prescribed and verified working [VERIFIED: docs/dots-hyprland-workflow.md:365] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `hyprctl` | Hyprland 0.56.2 | Post-change live login re-verify (D-40) | Only in the wave-5 human checkpoint |
| `pacman` / `yay` | libalpm 16.0.1 / yay 13.0.1 | Referenced by surviving `uninstall` prose | Never invoked by any assert in this phase |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `python3` heredoc fence extraction | `awk`/`sed` range extraction | The existing script already pays the python3 cost and its extractor is proven; adding a second extraction idiom for W-3 would create two ways to do one thing. **Reuse the existing `python3` extractor pattern.** |
| New `scripts/phase16-w3-assert.sh` | Extend `phase13-d19-assert.sh` | Locked by D-38(2) — extend, do not add |
| `shellcheck` static analysis | `bash -n` syntax check | `shellcheck` is **not installed** on this machine [VERIFIED: `command -v shellcheck` → MISSING]. `bash -n` is what `phase12-full-smoke.sh:32` already runs. Do not add a `shellcheck` gate. |

**Installation:** None. This phase installs no packages.

---

## Package Legitimacy Audit

**Not applicable.** This phase installs no external packages in any ecosystem. It deletes Bash functions, rewrites Markdown, and edits existing shell scripts. `PROTECT_EXPLICIT` names Arch packages but the array is being **deleted**, not installed from; no `pacman -S` / `yay -S` is added by this phase.

- **Packages removed due to `[SLOP]` verdict:** none
- **Packages flagged as suspicious `[SUS]`:** none

The one package-adjacent risk is the *inverse* of slopsquatting and is recorded in Common Pitfalls #3: deleting `protect_explicit_packages` leaves a set of already-installed packages in the `--asdeps` state where a future orphan sweep can remove them. That is an accepted consequence under D-07, not a supply-chain finding.

---

## Wrapper Surgery Map

This is the highest-value section for the planner. Every row was confirmed by `grep -n` against live source this session. **Anchor edits on the symbol, per D-12** — the "Actual" column is provided only so the planner can size waves.

### Symbol definitions to DELETE

| Symbol | CONTEXT.md says | Actual (verified) | Drift |
|--------|-----------------|-------------------|-------|
| `SAFE_DEFAULTS` (array) | `:12` | `:12` | 0 |
| `II_BACKUP_DIR` | `:21` | `:21` | 0 |
| `needs_safe_defaults()` | `:141` | `:141` | 0 |
| `backup_gate()` | `:166` | `:166` | 0 |
| `is_help_only_user_flags()` | `:196` | `:196` | 0 |
| `user_flags_contain()` | `:211` | `:211` | 0 |
| `PROTECT_EXPLICIT` (array) | `:230` | `:230` | 0 |
| `resolve_real_package_name()` | `:307` | `:307` | 0 |
| `collect_installed_protect_packages()` | `:316` | `:316` | 0 |
| `collect_missing_protect_packages()` | `:332` | `:332` | 0 |
| `protect_explicit_packages()` | `:349` | `:349` | 0 |
| `install_missing_protect_packages()` | `:391` | `:391` | 0 |
| `run_protect()` | `:418` | `:418` | 0 |
| `list_hypr_ii_hook_target_files()` | `:651` | `:651` | 0 |
| `list_active_hypr_ii_hook_files()` | `:668` | `:668` | 0 |
| `list_any_hypr_ii_hook_files()` | `:692` | `:692` | 0 |
| `file_has_active_ii_hooks()` | `:714` | `:714` | 0 |
| `file_has_commented_ii_hooks()` | `:720` | `:720` | 0 |
| `warn_hypr_ii_hooks()` | `:727` | `:727` | 0 |
| `disable_hypr_ii_hooks()` | `:747` | `:747` | 0 |
| `enable_hypr_ii_hooks()` | `:789` | `:789` | 0 |

[VERIFIED: arch/dots-hyprland.sh — `grep -n '^[A-Za-z_][A-Za-z0-9_]*()'`, run this session]

**Refinement of D-12:** every *deletion-target* line number in CONTEXT.md is exact. The drift is concentrated entirely in the **keep-list** symbols cited to justify sparing `print_lines`:

| Keep symbol | CONTEXT.md says | Actual (verified) | Drift |
|-------------|-----------------|-------------------|-------|
| `print_lines()` | `:296` | `:296` | 0 |
| `collect_ii_meta_packages()` | `:500` | **`:486`** | −14 |
| `collect_ii_config_targets()` | `:529` | **`:505`** | −24 |
| `collect_ii_state_targets()` | `:539` | **`:532`** | −7 |

D-12's instruction still holds and is well-founded — but the practical consequence is narrower than stated: a planner deleting `:296-348` by line range would spare `print_lines` correctly, yet a planner *validating* the keep-list by the quoted line numbers would look at the wrong functions. **Confirm `print_lines` callers with `grep -n 'print_lines' arch/dots-hyprland.sh`, not by line number.** Verified callers: `:500`, `:529`, `:539` (the call sites, which is what CONTEXT.md's numbers actually point at — the definitions are 14/24/7 lines earlier).

### Call sites to remove — protect machinery

| Line | Content | In CONTEXT.md D-07? |
|------|---------|---------------------|
| `:14` | `protect` entry in `ALLOWLIST` | yes |
| `:38` | usage: `uninstall  Safe dual-run uninstall (wrapper-owned; see below)` | via D-13 |
| `:46`, `:60`, `:79`, `:84-90`, `:113` | usage prose + `--skip-protect` flag doc + example | yes |
| `:319-320`, `:335`, `:340`, `:356`, `:397`, `:456`, `:462`, `:470` | internal to deleted functions | n/a |
| `:967` | `collect_installed_protect_packages` inside `uninstall_gate` | yes (the named collision) |
| `:969` | `[UNINSTALL] Safe dual-run uninstall (wrapper-owned).` | via D-13 |
| `:995-1006` | the `skip_protect` preview branch in `uninstall_gate` | yes |
| `:1111`, `:1113` | dry-run protect branch in `run_safe_uninstall` | yes |
| `:1165`, `:1170` | real protect branch in `run_safe_uninstall` | yes |
| **`:1245-1247`** | **`if ((skip_protect == 0)); then echo "[DONE] Personal-stack packages re-marked explicit…"`** | **NO — additional site** |
| `:1348` | `--skip-protect)` case arm in `run_uninstall` | yes |
| `:1466`, `:1486` | dry-run + real post-setup calls in `run_install_family` | yes |
| `:1523` | `protect)` dispatch arm in `main` | yes |

[VERIFIED: arch/dots-hyprland.sh — `grep -n 'protect_explicit_packages\|run_protect\|…\|skip-protect'`, run this session]

### Call sites to remove — ii-hook machinery

| Line | Content | In CONTEXT.md D-08? |
|------|---------|---------------------|
| `:78` | `--keep-hypr-hooks` flag doc in usage | yes |
| `:732`, `:753`, `:795`, `:804`, `:907`, `:909`, `:926` | internal to deleted functions | n/a |
| `:963` | `list_active_hypr_ii_hook_files` inside `uninstall_gate` | via "the `uninstall_gate` hook parameter" |
| `:1027-1040` | the `keep_hypr_hooks` preview branch in `uninstall_gate` | via same |
| `:1146`, `:1148`, `:1149` | dry-run disable/warn in `run_safe_uninstall` | yes |
| `:1237`, `:1239` | real disable/warn in `run_safe_uninstall` | yes |
| **`:1271-1281`** | **`if ((keep_hypr_hooks == 0))` leftover-hook re-scan in the `run_safe_uninstall` tail** | **NO — additional site** |
| `:1345` | `--keep-hypr-hooks)` case arm in `run_uninstall` | yes |
| `:1468`, `:1489` | dry-run + real post-setup enable in `run_install_family` | yes |

[VERIFIED: arch/dots-hyprland.sh — same grep, run this session]

### Call sites to remove — backup machinery

| Line | Content | In CONTEXT.md D-06? |
|------|---------|---------------------|
| `:21` | `II_BACKUP_DIR="${BACKUP_DIR:-$HOME/ii-original-dots-backup}"` | yes |
| `:40-45`, `:51-56`, `:96` | usage: safe-defaults + Backup gate sections | yes |
| **`:1044-1046`** | **`if [[ -d "$II_BACKUP_DIR" ]]; then echo "[UNINSTALL] Install-time backup (if any) still at: $II_BACKUP_DIR"` — inside the KEPT `uninstall_gate`** | **NO — additional site** |
| **`:1248-1250`** | **`if [[ -d "$II_BACKUP_DIR" ]]; then echo "[DONE] Backup (if created at install): $II_BACKUP_DIR"` — inside the KEPT `run_safe_uninstall`** | **NO — additional site** |
| `:1352-1354` | `--allow-skip-backup)` "harmless if mixed; ignore" arm in `run_uninstall` | implied, not named |
| `:1431-1436` | the bare-`--skip-backup` refusal in `run_install_family` | yes |
| `:1439-1441` | the `backup_gate "$full"` invocation | yes |

[VERIFIED: arch/dots-hyprland.sh — `grep -n 'II_BACKUP_DIR\|backup_gate\|allow-skip-backup'`, run this session]

### Signature changes forced by the deletions

`uninstall_gate` currently takes **five** positional parameters and `run_safe_uninstall` **six**. Removing `keep_hypr_hooks` and `skip_protect` reduces them to **three** and **four**:

```
uninstall_gate()      packages_only configs_only keep_venv [keep_hypr_hooks] [skip_protect]   → 5 → 3
run_safe_uninstall()  dry_run packages_only configs_only keep_venv [keep_hypr_hooks] [skip_protect]  → 6 → 4
```

Call sites to update: `:1385` (`uninstall_gate "$packages_only" "$configs_only" "$keep_venv" "$keep_hypr_hooks" "$skip_protect"`) and `:1390` (`run_safe_uninstall "$dry_run" …`). [VERIFIED: arch/dots-hyprland.sh:1084,936,1385,1390]

> **`set -u` hazard.** The wrapper runs under `set -euo pipefail` (`:2`). Leaving a `local skip_protect="$5"` in a function now called with four arguments is an **unbound-variable abort**, not a silent no-op. Change signature and call site in the same edit.

---

## Architecture Patterns

### System Architecture Diagram

**Before (current, verified):**

```
operator argv
     │
     ▼
  main() ──► is_allowlisted(ALLOWLIST) ──► [FAIL] non-allowlisted
     │
     ├── "uninstall" ──► run_uninstall ──► uninstall_gate (type-yes)
     │                                        ├─► collect_installed_protect_packages ─┐
     │                                        └─► list_active_hypr_ii_hook_files ─────┤
     │                                     run_safe_uninstall                          │
     │                                        ├─► protect_explicit_packages ───────────┤
     │                                        └─► disable_hypr_ii_hooks ───────────────┤
     │                                                                      DELETED ◄──┘
     ├── "protect"  ──► run_protect ────────────────────────────► DELETED (whole arm)
     │
     └── install|install-deps|install-setups|install-files
              │
              ▼
         run_install_family
              ├─ strip meta: --dry-run / --allow-skip-backup / --full
              ├─ needs_safe_defaults($subcmd)? ──► --full scope check ──► DELETED
              ├─ preflight (submodule + executable)                    ──► KEPT
              ├─ refuse bare --skip-backup                             ──► DELETED
              ├─ backup_gate(full)  ── reads stdin, "yes" or abort ─── ──► DELETED
              ├─ cmd=(./setup $subcmd)
              │    └─ full==0 ? cmd+=(SAFE_DEFAULTS) : echo "full profile" ──► DELETED
              ├─ cmd+=(user_flags)
              ├─ dry_run ? print would-exec + mirror protect/hooks ──► mirror DELETED
              └─ ( cd $II_ROOT; "${cmd[@]}" )                        ──► KEPT
                     └─ post-setup: protect_explicit_packages + enable_hypr_ii_hooks ──► DELETED
```

**After (target):**

```
operator argv
     │
     ▼
  main() ──► is_allowlisted(ALLOWLIST minus "protect")
     │
     ├── "uninstall" ──► run_uninstall ──► uninstall_gate (type-yes, 3 args)
     │                                     run_safe_uninstall (4 args)
     │                                        ├─► pacman -R illogical-impulse-* (no -s)
     │                                        ├─► safe_rm_path on ii configs/state
     │                                        └─► stop_running_qs
     │
     └── install|install-deps|install-setups|install-files
              │
              ▼
         run_install_family
              ├─ strip meta: --dry-run / --full (no-op, print note, never forwarded)
              ├─ preflight (submodule + executable)
              ├─ cmd=(./setup $subcmd --skip-backup)      ◄── the only injection left
              ├─ cmd+=(user_flags)
              ├─ dry_run ? print would-exec ; exit 0
              └─ ( cd $II_ROOT; "${cmd[@]}" )
                     │
                     ▼
              upstream ./setup
                     ├─ 0.greeting.sh   (unless --skip-allgreeting)   ◄── STILL INTERACTIVE
                     ├─ pause()          (unless -f/--force)           ◄── STILL INTERACTIVE
                     ├─ 1.deps-router.sh
                     ├─ 2.setups.sh
                     └─ 3.files.sh
                           └─ SKIP_BACKUP==true → auto_backup_configs SKIPPED
```

### Recommended Wave Structure

```
wave 1  arch/dots-hyprland.sh          # surgery; bash -n; usage() rewrite
        scripts/phase12-full-smoke.sh  # rewritten to the new contract  (D-34)
        └─ one commit — this is the SHA wave 4 pins

wave 2  scripts/phase14-verify.sh      # D-37 deletions + reword
        scripts/phase07-live-smoke.sh  # deleted  (D-33)
        scripts/phase14-preflight.sh   # deleted  (D-33)

wave 3  scripts/phase16-*-assert.sh    # new  (D-35 + D-36 doc ban-grep)
        docs/dots-hyprland-workflow.md # full-only rewrite  (D-14..D-23)
        docs/phase14-adopt-runbook.md  # sweep + §14 tier replacement  (D-20, D-24, D-25)
        └─ output quotes captured from the wave-1 binary  (D-42)

wave 4  16-DOC-SWEEP.md                # marker file  (D-41)
        scripts/phase13-d19-assert.sh  # third tier pinned to wave-1 SHA + W-3 assert  (D-38)
        └─ MUST be one commit  (D-43)

wave 5  .planning/REQUIREMENTS.md      # D-26, D-27
        .planning/ROADMAP.md           # D-28
        .planning/PROJECT.md           # D-29
        .planning/STATE.md             # D-30
        .planning/v0.3-MILESTONE-AUDIT.md   # D-31
        .planning/phases/11-.../11-DISPOSITIONS.md   # W-1, W-2  (D-32)
        └─ then the D-40 gate, on a CLEAN tree
```

### Pattern 1: Symbol-anchored deletion

**What:** Locate every edit by `grep -n` on the symbol name immediately before editing; never carry a line number across an edit.
**When to use:** Every wrapper edit in this phase.
**Example:**

```bash
# Source: arch/dots-hyprland.sh convention; D-12
# Find the definition and the NEXT definition to get the true range.
grep -n '^[A-Za-z_][A-Za-z0-9_]*()' arch/dots-hyprland.sh | grep -A1 'backup_gate'
# 166:backup_gate() {
# 196:is_help_only_user_flags() {
#   → backup_gate occupies 166..195 inclusive, at this instant only.

# Re-run after EVERY deletion; all downstream numbers have shifted.
```

### Pattern 2: Delete leaf-first, from the bottom of the file up

**What:** Remove call sites before definitions, and work from the highest line number to the lowest.
**Why:** Every deletion invalidates the line numbers below it but not above it. Bottom-up editing keeps the un-edited anchors stable for the whole pass.
**Order for this phase:** `main` dispatch (`:1523`) → `run_install_family` post-setup (`:1486-1490`) → dry-run mirror (`:1465-1469`) → argv branch (`:1443-1454`) → gate call (`:1439-1441`) → skip-backup refusal (`:1431-1436`) → `--full` scope check (`:1420-1425`) → `run_uninstall` case arms (`:1345-1354`) → `run_safe_uninstall` tail (`:1271-1281`, `:1245-1250`) → mid-body (`:1237-1240`, `:1165-1172`, `:1146-1150`, `:1111-1114`) → `uninstall_gate` (`:1044-1046`, `:1027-1040`, `:995-1006`, `:963-969`) → hook functions (`:651-935`) → protect functions (`:230-295`, `:307-485`, **sparing `:296-306` `print_lines`**) → `user_flags_contain` (`:211`) → `is_help_only_user_flags` (`:196`) → `backup_gate` (`:166`) → `needs_safe_defaults` (`:141`) → `usage()` heredoc (`:23-131`) → header consts (`:21`, `:14`, `:12`).

### Pattern 3: Marker-file baseline tiering

**What:** `phase13-d19-assert.sh` switches its drift baseline on the presence of a phase-artifact file. Extend, do not replace.
**Existing shape [VERIFIED: scripts/phase13-d19-assert.sh:96,146-152]:**

```bash
LIVE_VERIFY=".planning/phases/14-live-full-adopt-verify/14-LIVE-VERIFY.md"
...
if [ -f "$LIVE_VERIFY" ]; then
  WRAPPER_BASE="14c6828"   # refactor(14-01): drop waybar and swaync from PROTECT_EXPLICIT (D-28)
else
  WRAPPER_BASE="e7e4e9f"   # feat(12-03): last phase-12 state of the wrapper
fi
```

**Third tier must be tested FIRST** — `14-LIVE-VERIFY.md` still exists, so an `elif` placed after it never fires.

### Anti-Patterns to Avoid

- **Deleting `print_lines`.** It is inside the protect block's apparent range but has three live callers in surviving uninstall machinery. Deleting it breaks `uninstall` entirely. [VERIFIED: arch/dots-hyprland.sh:296, callers at :500, :529, :539]
- **Deleting `uninstall_gate` because it references protect.** D-10 keeps the gate; only the protect *preview branch* inside it goes.
- **Leaving a `local x="$5"` after shrinking a signature.** `set -u` turns this into an abort, not a default.
- **Adding a `--safe` flag "for symmetry."** Explicitly excluded by D-05.
- **Forwarding `--full` to `./setup`.** Upstream's `getopt` long-option list does not contain `full`; the `*) echo "$0: Wrong parameters."; exit 1` arm would abort the install. [VERIFIED: vendor/dots-hyprland/sdata/subcmd-install/options.sh — `-l help,force,firstrun,fontset:,clean,skip-allgreeting,skip-alldeps,skip-allsetups,skip-allfiles,ignore-outdate,skip-sysupdate,skip-plasmaintg,skip-backup,skip-quickshell,skip-fish,skip-hyprland,skip-hyprland-entry,skip-fontconfig,skip-miscconf,core,exp-files,via-nix`]
- **Running the D-40 gate on uncommitted work.** See Pitfall 1.
- **Writing "chrome" instead of `Waybar`, `rofi`, `swaync`.** Phase 14 D-39, restated in CONTEXT.md Specific Ideas.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Suppressing the upstream backup | A wrapper-side `rm`/`mv` of `~/ii-original-dots-backup`, or an env override | Pass `--skip-backup` to `./setup` | Upstream already gates it: `if [[ ! "${SKIP_BACKUP}" == true ]]; then auto_backup_configs; fi` [VERIFIED: vendor/dots-hyprland/sdata/subcmd-install/3.files.sh:219] |
| Detecting which profile a machine is on | A `hyprctl getoption configProvider` probe | Nothing — there is one profile now (D-17) | `hyprctl getoption configProvider` returns `no such option` on Hyprland 0.56.2 [VERIFIED: `hyprctl getoption configProvider` → `no such option`, this session]. The working probe is `hyprctl -j status \| jq -r .configProvider` [VERIFIED: returns `lua`, this session] |
| W-3 fence-drift detection | A second Markdown parser, or a hand-transcribed copy of the fence in the assert | The existing `python3` fence extractor in `phase13-d19-assert.sh:28-44`, applied to both files, then `diff` | The script already extracts one fence from Markdown; a second extraction idiom guarantees the two drift |
| Proving the wrapper did not regress | A hand-written checklist in a plan | The rewritten `phase12-full-smoke.sh` + new `phase16` assert | Executable asserts are this repo's contract of record; four of them are the D-40 gate |
| Wrapper drift detection across the phase | `git diff` against the index | `git diff --name-only <pinned-SHA> -- arch/dots-hyprland.sh` | The script's own comment records why: "Bare `git diff` compares worktree against index only, so a committed change is invisible to it -- arch/dots-hyprland.sh was modified during phase 14 and still passed this check." [VERIFIED: scripts/phase13-d19-assert.sh:140-142] |
| Shell static analysis | Installing `shellcheck` mid-phase | `bash -n`, already asserted at `phase12-full-smoke.sh:32` | `shellcheck` is not installed; adding an install step widens the phase for no contract gain |

**Key insight:** every capability this phase needs already exists in the repo's own assert vocabulary. The phase's difficulty is *subtractive correctness*, not new machinery — so the correct instinct at every fork is "which existing thing already does this," and the answer is almost always `phase12-full-smoke.sh` (evidence shape) or `phase13-d19-assert.sh` (extraction + pinning shape).

---

## Runtime State Inventory

Required: this is a deletion/refactor phase. Every category answered explicitly.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| **Stored data** | **None affected.** No database, no datastore keyed on any string this phase changes. `~/.local/state/quickshell/.venv` exists and is referenced by the surviving `--keep-venv` flag, but is not renamed or migrated. | none |
| **Live service config** | **`~/ii-original-dots-backup` and `~/ii-original-dots-backup.20260904T171128Z` both exist on disk** [VERIFIED: `ls -d ~/ii-original-dots-backup*`, this session]. D-06 and the CONTEXT.md Specific Ideas leave both untouched. **Consequence to record, not to fix:** `phase14-verify.sh` currently hashes the contents of the first (`:402-420`) and D-37 deletes that check, so after this phase **nothing verifies the snapshot is intact**, while the directory stays on disk indefinitely. | code edit only (delete the checks); **no data migration** |
| **OS-registered state** | **None affected.** The one systemd unit in play, `hyprland-session.service`, is symlinked from `stow/systemd/` and is explicitly out of scope (deferred D-38 restoration). No Task-Scheduler/pm2/launchd analogue exists here. Verified: `phase14-verify.sh` reports the unit file "SURVIVES in the repo at stow/systemd/.config/systemd/user/hyprland-session.service — only its autostart line is gone" [VERIFIED: phase14-verify.sh output, this session] | none |
| **Secrets / env vars** | **`BACKUP_DIR` is a live environment-variable contract on BOTH sides.** The wrapper reads `II_BACKUP_DIR="${BACKUP_DIR:-$HOME/ii-original-dots-backup}"` (`:21`) and upstream independently reads `BACKUP_DIR="${BACKUP_DIR:-$HOME/ii-original-dots-backup}"` [VERIFIED: vendor/dots-hyprland/sdata/lib/environment-variables.sh:27]. Deleting `II_BACKUP_DIR` from the wrapper does **not** remove the upstream one — but with `--skip-backup` always passed, upstream never uses it. `phase14-verify.sh` also has its own `$BACKUP_DIR` (D-37 deletes the blocks that read it; check whether the variable itself becomes unused and would trip `set -u`). | code edit; **no secret rename** |
| **Build artifacts / installed packages** | **The machine is already in the demoted `--asdeps` state from the Phase 14 adopt** — this is stated in D-07 and is exactly the condition `protect_explicit_packages` existed to heal. Deleting it does **not** change any package's current mark; it removes the future ability to re-mark. The 60-entry `PROTECT_EXPLICIT` list includes `hyprland`, `hyprlock`, `hypridle`, `kitty`, `fish`, `starship`, `cliphist`, `bc`, `jq`, `python`, `pipewire`, `neovim` [VERIFIED: arch/dots-hyprland.sh:230-292 — array read verbatim this session; contains **no** `waybar`, `rofi` or `swaync`, confirming D-13]. No egg-info, no compiled binary, no npm global, no Docker tag is affected. | **no migration**; the state is left as-is by operator decision |

**Canonical question — after every file in the repo is updated, what runtime systems still have the old behavior cached, stored, or registered?**
Answer: **only the two `~/ii-original-dots-backup*` directories and the current `--asdeps` package marks.** Both are deliberately left in place. Nothing else in this phase has a runtime footprint outside the git worktree — which is why the D-40 gate is a script run plus one human login, not a migration.

---

## Common Pitfalls

### Pitfall 1: `phase14-verify.sh` fails on a dirty working tree — the gate cannot run mid-wave

**What goes wrong:** The D-40 gate includes `scripts/phase14-verify.sh`. Its final assert requires the git working tree to be clean **except** under one hard-coded prefix.
**Why it happens** [VERIFIED: scripts/phase14-verify.sh:538,553-557]:

```bash
PHASE14_PREFIX=".planning/phases/14-live-full-adopt-verify/"
...
if [[ -z "${DIRTY_OUTSIDE//[[:space:]]/}" ]]; then
  pass "D-35 git status --porcelain is clean apart from paths under $PHASE14_PREFIX"
else
  fail "D-35 working tree is dirty outside $PHASE14_PREFIX — review the diff, commit it, and record the fact as a finding in 14-LIVE-VERIFY.md"
```

Every Phase 16 edit — including the **untracked** `16-DOC-SWEEP.md` — is outside that prefix. An untracked file counts: `git status --porcelain` reports it.
**How to avoid:** Run the full gate only after every wave is committed. Within a wave, run the *other* four scripts (which do not check tree cleanliness) and defer `phase14-verify.sh` to the end.
**Warning signs:** `[FAIL] D-35 working tree is dirty outside .planning/phases/14-live-full-adopt-verify/` followed by an indented file list.
**Baseline for comparison:** on a clean tree this session the script produced `=== done: FAIL=0 FINDINGS=1 ===` [VERIFIED: `./scripts/phase14-verify.sh`, run this session].

### Pitfall 2: `phase13-d19-assert.sh` fails the moment the wrapper is touched, and stays failing until wave 4

**What goes wrong:** The script hard-fails on any wrapper diff from a pinned commit. This is not a bug — D-38(1) names it — but its *duration* is the trap: the failure spans waves 1 through 3.
**Why it happens** [VERIFIED: scripts/phase13-d19-assert.sh:146-158, and `[PASS] arch/dots-hyprland.sh unmodified since 14c6828` observed this session]:

```bash
if [ -f "$LIVE_VERIFY" ]; then
  WRAPPER_BASE="14c6828"
else
  WRAPPER_BASE="e7e4e9f"
fi
...
elif [ -z "$(git diff --name-only "$WRAPPER_BASE" -- arch/dots-hyprland.sh)" ]; then
  pass "arch/dots-hyprland.sh unmodified since $WRAPPER_BASE"
else
  fail "arch/dots-hyprland.sh changed since $WRAPPER_BASE"
```

**How to avoid:** Treat this script as **expected-red from wave 1 until wave 4 lands**, and say so in the plan so an executor does not "fix" it early by loosening the check. Three further constraints fall out:
- `git diff <BASE> -- <path>` compares BASE against the **working tree**, not against HEAD. So the wrapper must be **final** before the re-pin — any wave-5 touch-up to `arch/dots-hyprland.sh` re-breaks it.
- The new tier must be tested **before** the `$LIVE_VERIFY` tier: `14-LIVE-VERIFY.md` still exists [VERIFIED: `.planning/phases/14-live-full-adopt-verify/14-LIVE-VERIFY.md`, 27200 bytes], so an `elif` never fires.
- The marker test is a filesystem `[ -f ]`, so an **uncommitted** `16-DOC-SWEEP.md` flips the tier while simultaneously breaking Pitfall 1's clean-tree check. Commit both together (D-43).

### Pitfall 3: Deleting the wrapper's gate does NOT make install non-interactive

**What goes wrong:** D-09 says install runs "immediately, with `--skip-backup` and no type-yes prompt." That is true **of the wrapper**. It is false of the install as a whole, and a playbook that implies an unattended install will strand the operator at a prompt on a bare TTY.
**Why it happens** [VERIFIED: vendor/dots-hyprland/sdata/lib/functions.sh:64-70]:

```bash
function pause(){
  if [ ! "$ask" == "false" ];then
    printf "${STY_FAINT}${STY_SLANT}"
    local p; read -p "(Ctrl-C to abort, Enter to proceed)" p
    printf "${STY_RST}"
  fi
}
```

`ask` is set to `false` only by `-f|--force` [VERIFIED: vendor/dots-hyprland/sdata/subcmd-install/options.sh:74] or by an interactive greeting answer [VERIFIED: .../0.greeting.sh:44]. The wrapper never auto-injects `--force` (stated in its own usage at `:48`) and D-04..D-11 do not add it. Upstream `./setup` calls `pause` unconditionally on `install`, `install-deps`, `install-setups` and `install-files`, and sources `0.greeting.sh` on `install` unless `--skip-allgreeting` [VERIFIED: vendor/dots-hyprland/setup, subcommand `case` block].
**How to avoid:** the rewritten playbook §4 must say plainly that the wrapper no longer prompts and upstream still does — one greeting and at least one `Enter to proceed`. Do not describe the new default as "unattended" or "no prompts."
**Warning signs:** an operator reports the install "hung" with no output.

### Pitfall 4: `--skip-backup` must land in the `cmd` array, and only where it means something

**What goes wrong:** Two symmetrical errors. Injecting it outside the array (e.g. into a string) breaks the array-only-exec invariant (D-11). Injecting it for every install-family subcommand is accepted by upstream's `getopt` but is a lie in the dry-run preview for `install-setups`, which never reaches the backup code.
**Why it happens** [VERIFIED: vendor/dots-hyprland/sdata/subcmd-install/3.files.sh:219]: `SKIP_BACKUP` is read in exactly one place — `if [[ ! "${SKIP_BACKUP}" == true ]]; then auto_backup_configs; fi` — inside `3.files.sh`, which `setup` sources only for `install` and `install-files`. `install-deps` and `install-setups` parse the flag (same `options.sh`) and ignore it.
**How to avoid:** the planner must make an explicit call. Recommended: inject for **`install` and `install-files` only**, which preserves the true scope and gives the phase16 assert a crisp negative to test (`install-setups --dry-run` shows no `--skip-backup`). Note this reintroduces a subcommand predicate — the deleted `needs_safe_defaults` was exactly that predicate under a now-wrong name. **Recommendation:** keep a renamed one-line predicate (e.g. `touches_files()`) rather than duplicating the `case` inline twice.
**Warning signs:** dry-run output for `install-setups` carrying a flag that cannot affect it.

### Pitfall 5: The `--dry-run` mirror block and the post-setup `case` both become empty

**What goes wrong:** The two `case "$subcmd" in install|install-deps|install-files) … ;; esac` blocks exist **only** to call `protect_explicit_packages` and `enable_hypr_ii_hooks`. Deleting the calls but keeping the `case` leaves a `case` whose single arm has an empty body.
**Why it matters:** `install|install-deps|install-files)` followed immediately by `;;` is legal Bash but is dead scaffolding that the next reader will mistake for an unfinished edit. It also leaves the surrounding `echo "[CONFIG] dry-run: after setup, would…"` lines, which are now false.
**How to avoid:** delete both `case` statements entirely — the whole block at `:1463-1471` and the whole block at `:1481-1492` [VERIFIED: arch/dots-hyprland.sh:1463-1492, read this session]. What must survive from that region is only `echo "[CONFIG] dry-run: would exec from $II_ROOT: ${cmd[*]}"` + `exit 0`, and the `( cd "$II_ROOT"; "${cmd[@]}" )` subshell.

### Pitfall 6: The playbook §7 expected output is coupled to the D-37 deletions

**What goes wrong:** `docs/dots-hyprland-workflow.md:389` reads `# expect: === done: FAIL=0 FINDINGS=1 ===   (the 1 finding is the D-38 known loss)` [VERIFIED: docs/dots-hyprland-workflow.md:389]. D-37 deletes assertions from `phase14-verify.sh`. If any deleted assertion was a `finding`, the documented count goes stale in the same phase that rewrites the doc.
**Verified relief:** all three D-37 deletion targets are `pass`/`fail` pairs, not `finding` calls — `:374-378` (tier-1 source 3), `:386-390` (tier 3 protect), `:394-420` (D-36 backup) [VERIFIED: scripts/phase14-verify.sh:372-420]. The single `[FINDING]` at baseline is `D-38 graphical-session.target is inactive`, which is untouched. **So `FAIL=0 FINDINGS=1` remains correct** — but only if `:521` is *reworded* rather than deleted, since it is a `finding` in an `else` branch that does not fire on this machine.
**How to avoid:** re-run `phase14-verify.sh` after the wave-2 edit and paste the real tail into the playbook; do not carry the number forward on trust.

### Pitfall 7: The W-1 rewrite can break `phase11-dispositions-assert.sh`

**What goes wrong:** The assert greps `11-DISPOSITIONS.md` for required tokens. Rewriting the migrate rows at `:107-110` can remove the last occurrence of a required token.
**Why it happens** [VERIFIED: scripts/phase11-dispositions-assert.sh:130-190]: the script requires, among others, the three literal residual tokens; the enum token `migrate-to-hypr-custom` (checked **twice** — once in the enum loop, once as "Axis A `migrate-to-hypr-custom` present"); `hyprland.conf`; `hyprland/` or `hyprland.lua`; the D-10 residual-language regex `(remains|still|unchanged|default).{0,100}(SAFE_DEFAULTS|safe|residual|dual-run)` **or its mirror**; and a D-05 drop-all-three regex requiring `drop`-family wording within 200 characters of a residual flag token.
**How to avoid:** run `./scripts/phase11-dispositions-assert.sh` immediately after the W-1 edit, before moving on. Verified green at baseline this session.
**Warning signs:** `[FAIL] enum token migrate-to-hypr-custom missing` or `[FAIL] D-05 full-adopt / drop residual flags language missing`.

### Pitfall 8: The D-36 doc ban-grep can collide with the playbook's own surviving prose

**What goes wrong:** A naive `grep -q -- '--skip-hyprland' docs/dots-hyprland-workflow.md` bans the token file-wide, but D-36 scopes the ban to **§10** for that token while banning "dual-run" and "safe profile" file-wide.
**Verified collision surface:** at baseline the playbook carries `dual-run` at `:45`, `:53`, `:174`, `:190-192`, `:243-248`, `:398`, `:417`, `:516-517` and `--skip-hyprland` at `:38`, `:49`, `:59`, `:492`, `:517`. Note `:247` — `| uninstall | Safe dual-run uninstall (wrapper-owned; not upstream cascade) |` — is the D-13 "safe uninstall" wording, which must change for an unrelated reason [VERIFIED: docs/dots-hyprland-workflow.md, grep this session].
**How to avoid:** implement the §10 scope by extracting the section first (`awk '/^## 10\./,/^## 11\./'`), then grepping the extract — matching D-36's stated scope exactly rather than approximating it with a file-wide ban.
**Second-order note:** the runbook §14 Prohibition already avoids the literal `./setup uninstall` token, writing "The upstream vendor tree ships its own removal subcommand. Never use it." [VERIFIED: docs/phase14-adopt-runbook.md:379]. Preserve that evasion when replacing the tiers under D-20 — reintroducing the literal could trip a future ban-grep.

### Pitfall 9: `usage()` is a quoted heredoc and is ~109 lines of the deletion surface

**What goes wrong:** `usage()` spans `:23-131` and is a `cat <<'EOF'` block [VERIFIED: arch/dots-hyprland.sh:23-24,131]. Roughly half of it documents machinery this phase deletes: the Safe-defaults block (`:40-48`), the Backup-gate block (`:50-58`), the protect flags (`:78-79`, `:84-90`), the `--allow-skip-backup` and `--full` meta descriptions (`:93-99`), eight of the fifteen examples (`:101-116`), and the closing note at `:129-130`.
**Why it matters:** `phase12-full-smoke.sh:41` asserts `grep -q -- '--full' "$HELP_OUT"` and `:59` asserts `grep -q 'dots-hyprland-workflow' "$HELP_OUT"` [VERIFIED: scripts/phase12-full-smoke.sh:38-62]. Both must keep passing — `--full` survives as a documented no-op (D-05), and the playbook pointer at `:121` must stay.
**How to avoid:** rewrite `usage()` as one deliberate replacement rather than incremental line deletions, and re-run the smoke immediately.

### Pitfall 10: `install-deps --full` changes from refused to accepted, silently

**What goes wrong:** D-05 says `--full` stays "parsed as an accepted no-op alias" without naming a scope. D-04 deletes `needs_safe_defaults`, which is the predicate the current scope check uses.
**Current behavior** [VERIFIED: arch/dots-hyprland.sh:1420-1425 and `[PASS] D-02 --full refused on install-deps` observed this session]:

```bash
  # D-02: --full only valid on install / install-files (same scope as SAFE_DEFAULTS)
  if ((full == 1)) && ! needs_safe_defaults "$subcmd"; then
    echo "[FAIL] --full is only valid with install or install-files." >&2
```

**Consequence:** after the deletions, `install-deps --full` exits 0 instead of 1. `phase12-full-smoke.sh:151-157` asserts the *refusal* and will fail. D-34 lists `:153` among the assertions to replace, so this is anticipated — but the planner must decide deliberately whether `--full` is accepted everywhere (simplest, follows from D-04) or re-scoped. **Recommendation:** accept everywhere; a no-op alias with a scope restriction is a contradiction, and the note it prints makes the behavior self-explaining.

---

## Code Examples

### Replacement `run_install_family` skeleton

Derived from the verified current body at `arch/dots-hyprland.sh:1392-1492`. Implements D-04, D-05, D-06, D-09, D-11 and the Pitfall-4 recommendation.

```bash
# Source: arch/dots-hyprland.sh:1392-1492 (current), reduced per D-04..D-11.

# Files-touching install paths — the only ones where upstream reads SKIP_BACKUP
# (vendor/dots-hyprland/sdata/subcmd-install/3.files.sh:219).
touches_files() {
  case "$1" in
    install|install-files) return 0 ;;
    *) return 1 ;;
  esac
}

run_install_family() {
  local subcmd="$1"
  shift

  local dry_run=0
  local -a user_flags=()
  local arg
  for arg in "$@"; do
    case "$arg" in
      --dry-run)
        dry_run=1
        ;;
      --full)
        # D-05: accepted no-op alias. Full is the only behavior now.
        # Never forwarded: upstream getopt has no `full` long option and would abort.
        echo "[CONFIG] --full is accepted but ignored: full is now the only install behavior."
        ;;
      *)
        user_flags+=("$arg")
        ;;
    esac
  done

  # D-11: preflight survives, unchanged.
  preflight

  # D-04: no SAFE_DEFAULTS. D-06: --skip-backup by default, where it means something.
  local -a cmd=(./setup "$subcmd")
  if touches_files "$subcmd"; then
    cmd+=(--skip-backup)
  fi
  if ((${#user_flags[@]} > 0)); then
    cmd+=("${user_flags[@]}")
  fi

  echo "[INSTALL] ${cmd[*]}  (cwd=$II_ROOT)"

  if ((dry_run)); then
    echo "[CONFIG] dry-run: would exec from $II_ROOT: ${cmd[*]}"
    exit 0
  fi

  # D-11: array exec only — never eval a concatenated command string.
  (
    cd "$II_ROOT"
    "${cmd[@]}"
  )
}
```

> **D-09/D-42 note:** there is no `backup_gate` call and no post-setup `case`. The two output strings the playbook must re-quote after this lands are the `[INSTALL] …` line and the `[CONFIG] dry-run: would exec …` line — both now carry `--skip-backup` on `install` / `install-files` and not on `install-deps` / `install-setups`.

### W-3 fence-drift assert — the exact verified relationship

The playbook §6 block and the Phase 13 SoT apply block are **byte-identical after removing exactly one line** from the SoT copy [VERIFIED this session via `diff`; the only difference reported was `1d0 < # Phase 14 only. Do not run in Phase 13 (D-02, D-17).`].

- SoT fence: `.planning/phases/13-personal-hypr-custom-overlays/13-SOT-APPLY.md:31-53` (fence body `:32-52`, 21 lines)
- Playbook copy: `docs/dots-hyprland-workflow.md:314-335` (fence body `:315-334`, 20 lines)

```bash
# Source: extends scripts/phase13-d19-assert.sh, reusing its python3 extractor idiom (:28-44).
# W-3: the playbook duplicates the D-18 apply fence; nothing checked the copy until now.

extract_fence() {
  # $1 = markdown file, $2 = heading to search for
  python3 - "$1" "$2" <<'PY'
from pathlib import Path
import sys
text = Path(sys.argv[1]).read_text()
idx = text.find(sys.argv[2])
if idx < 0:
    raise SystemExit(f"heading missing: {sys.argv[2]}")
rest = text[idx:]
start = rest.find("```bash")
end = rest.find("```", start + 7)
if start < 0 or end < 0:
    raise SystemExit("bash fence missing")
print(rest[start + 7:end].lstrip("\n"), end="")
PY
}

SOT_FENCE="$(extract_fence "$SOT" '## Apply command (D-18)' \
  | grep -v '^# Phase 14 only')"
PB_FENCE="$(extract_fence 'docs/dots-hyprland-workflow.md' '### Named files only')"

if [ "$SOT_FENCE" = "$PB_FENCE" ]; then
  pass "W-3 playbook §6 apply fence matches 13-SOT-APPLY.md D-18 fence"
else
  fail "W-3 playbook §6 apply fence has drifted from 13-SOT-APPLY.md D-18 fence"
  diff <(printf '%s' "$SOT_FENCE") <(printf '%s' "$PB_FENCE") || true
fi
```

> The `grep -v '^# Phase 14 only'` filter is **load-bearing and must be documented in the script**, or the assert fails on day one against two files that are in fact in agreement.

### Third baseline tier for `phase13-d19-assert.sh`

```bash
# Source: extends scripts/phase13-d19-assert.sh:146-158 (existing two-tier idiom).
# D-38(1) / D-43: the marker must be tested FIRST — 14-LIVE-VERIFY.md still exists.

DOC_SWEEP_16=".planning/phases/16-retire-the-safe-profile-full-only-wrapper-and-playbook/16-DOC-SWEEP.md"
LIVE_VERIFY=".planning/phases/14-live-full-adopt-verify/14-LIVE-VERIFY.md"

if [ -f "$DOC_SWEEP_16" ]; then
  WRAPPER_BASE="<SHA of the wave-1 wrapper commit>"   # feat(16-01): retire the safe profile
elif [ -f "$LIVE_VERIFY" ]; then
  WRAPPER_BASE="14c6828"   # refactor(14-01): drop waybar and swaync from PROTECT_EXPLICIT (D-28)
else
  WRAPPER_BASE="e7e4e9f"   # feat(12-03): last phase-12 state of the wrapper
fi
```

### Upstream flag surface — what the wrapper may forward

```
# Source: vendor/dots-hyprland/sdata/subcmd-install/options.sh (getopt long list, verbatim)
help, force, firstrun, fontset:, clean, skip-allgreeting, skip-alldeps,
skip-allsetups, skip-allfiles, ignore-outdate, skip-sysupdate, skip-plasmaintg,
skip-backup, skip-quickshell, skip-fish, skip-hyprland, skip-hyprland-entry,
skip-fontconfig, skip-miscconf, core, exp-files, via-nix
```

Anything not on this list reaching `./setup` hits `*) echo -e "$0: Wrong parameters."; exit 1`. `full` is **not** on the list — which is the mechanism behind D-05's "never forwarded" requirement. [VERIFIED: vendor/dots-hyprland/sdata/subcmd-install/options.sh]

---

## Playbook Sweep Inventory

Verified grep of `docs/dots-hyprland-workflow.md` (536 lines) this session. D-15's site list is accurate; these are the **additional** sites it does not name, plus the coupling notes.

| Line(s) | Content | Treatment |
|---------|---------|-----------|
| `:174` | "the wrapper default is still safe, and `--full` is opt-in" | in D-15 |
| `:183-190` | The `--full --dry-run` example + the three quoted output lines | **Re-capture from wave-1 output (D-23/D-42).** Command becomes bare `install --dry-run`. |
| `:196-219` | The whole "### The backup gate" subsection | Delete (D-06 removes what it documents) |
| `:202` | Cites `arch/dots-hyprland.sh:21` for `II_BACKUP_DIR` | **Hard-coded wrapper line number → deleted symbol.** Not in D-15. |
| `:210-215` | The `sha256sum`/`grep -qxF` backup-verification recipe | Delete with the gate |
| `:221-237` | "### Live install (full profile)" + the six blast-radius bullets | Rewrite as the only install path; drop the "(full profile)" qualifier |
| `:228` | Cites `arch/dots-hyprland.sh:177-183` (the `backup_gate` full-path echoes) | **Hard-coded wrapper line number → deleted block.** Not in D-15. |
| `:243-248` | Allowlisted-subcommands table — rows carry "safe defaults + backup gate", "Safe dual-run uninstall", and the whole `protect` row | in D-15 (`:243-247`); note the `protect` row is `:248` |
| `:252-254` | "### Hooks after successful install" — describes `enable_hypr_ii_hooks` | Delete/replace per D-19. Not individually in D-15. |
| `:314-335` | The duplicated D-18 apply fence | **Leave the fence text alone**; W-3 adds an assert around it (D-38(2)) |
| `:365-367` | `hyprctl -j status \| jq -r .configProvider` → `lua` | **Correct as written — verified working this session.** Do not "fix" it, and do not replace it with `hyprctl getoption`, which returns `no such option`. |
| `:389` | `# expect: === done: FAIL=0 FINDINGS=1 ===` | Re-verify after the wave-2 `phase14-verify.sh` edits (Pitfall 6) |
| `:398` | "None of it applies to the safe profile…" | in D-15 |
| `:409-430` | §9 roles 1–3 + the tier-2 escalation warning | D-20/D-21 |
| `:432-436` | "### Never rotate the backup after a full adopt" | Delete outright (D-21) |
| `:478` | "Same safe defaults and backup gate as first adoption." | in D-18 scope; **specific line not in D-15** |
| `:490-492` | The three §10.3 bullets, including the D-16 deletion target at `:492` | D-16 |
| `:494-503` | §10.4 protect subsection | Delete with D-07 |
| `:516-517` | §11 rows — `:517` carries "Under the safe profile personal hypr conf remains SoT via `--skip-hyprland`" | `:517` in D-15; `:516` mentions dual-run indirectly |
| `:529` | See-also pointer to the runbook "and the three-tier rollback" | D-20 |
| `:535` | "`.planning/ROADMAP.md` — Phase 15 success criteria" | **Stale after this phase → Phase 16.** Not in D-15. |

---

## Planning-Artifact Sweep — sites beyond CONTEXT.md

Verified grep this session. CONTEXT.md's D-29/D-30/D-31 site lists are correct but not exhaustive. These additional lines carry the same falsehoods and will otherwise survive the sweep.

### `.planning/PROJECT.md` (240 lines) — beyond D-29

| Line | Content | Class |
|------|---------|-------|
| `:6` | "Phases 10–14 complete; next is Phase 15 playbook safe vs full" | current-state, already stale (Phase 15 shipped) → **rewrite** |
| `:39` | "Safe full-install path: wrapper/playbook opt-in out of SAFE_DEFAULTS; backup gate preserved" | v0.3 goal statement → **rewrite** |
| `:43` | "Not this milestone: … dual-run removal as a pure bar cutover" | current-state → **rewrite** |
| `:10`, `:12`, `:14` | Phase 10/11/12 "delivered" lines carrying SAFE_DEFAULTS claims | delivered → **mark superseded** (same rule as D-29's `:117`/`:119`) |
| `:120`, `:121`, `:122`, `:123` | Phase 12 FULL-02..FULL-05 delivered lines | delivered → **mark superseded** (D-29 names only `:119`) |
| `:171` | "Move from protected dual-run adopt toward full ii session ownership" | current-state → **rewrite** |
| `:198`, `:199`, `:202` | Key-Decisions table rows citing `--full`, backup gate, protect | delivered → **mark superseded** |
| `:56`, `:58`, `:194` | v0.2 milestone history | **leave as history** (out of scope, same class as `.planning/phases/**`) |

### `.planning/STATE.md` (165 lines) — beyond D-30

| Line | Content | Class |
|------|---------|-------|
| `:45` | Core-value line: "remaining work is documentation" | **false the moment D-02 lifts the no-scripts rule** → rewrite |
| `:46` | "Current focus: Phase 16 — close v0.3 audit gap DOC-03 (B-1 …, B-2 dual-run restore route)" | retired scope → **rewrite** |
| `:60` | Deferred-items row: "DISP-03 defaults keep dual-run" | → **mark superseded** |
| `:111` | Roadmap Evolution: "Phase 16 added: Close gap: DOC-03 — full-profile update path and dual-run restore" | retired scope → **rewrite or supersede** |
| `:150`, `:157` | Phase 7 / Phase 12 decision-log rows | delivered → **mark superseded** |

### `.planning/v0.3-MILESTONE-AUDIT.md` (323 lines) — beyond D-31

| Line(s) | Content |
|---------|---------|
| `:18` | The DOC-03 gap `evidence:` block, which is the full B-1/B-2 narrative (D-31 names `:25` DISP-03 evidence but not this one) |
| `:78` | "Three deferred fixes recorded as unowned in 15-DOC-SWEEP.md: IN-11 …, and the dual-run restore path" |
| `:119-122` | Narrative restatement of B-1 and B-2 |
| `:161` | ADOPT-04 traceability row, `wired (IN-11)` — ADOPT-04 is being **deleted** |
| `:197-208` | Integration-flow evidence quoting `[CONFIG] full profile: no SAFE_DEFAULTS injection`, the SAFE_DEFAULTS argv, the backup gate line range and `protect_explicit_packages` |
| `:226` | Rollback narrative: "use `cp -a` restores plus the wrapper's own `uninstall` / `protect`" |
| `:243-245`, `:252-257` | Flow B / Flow C narratives naming `phase14-preflight.sh` and dual-run restoration |
| `:288-289` | "Unowned, no closing phase (3): IN-11 …, and the dual-run restore path" |
| `:311-312`, `:319` | Recommendations prescribing `install --full` for pin-bump, writing the dual-run restore path, and gating the `--rotate-backup` remediation |

> These are numerous enough that the planner should scope the audit rewrite by **section**, not by line list: the `evidence`/`issue` blocks (`:18-38`), the traceability rows (`:161`), the integration-flow section (`:190-260`) and the recommendations (`:288-320`).

### `.planning/REQUIREMENTS.md` — D-26 line references, all confirmed exact

Every line number in D-26's table was verified against the live file this session: `INV-04:16`, `DISP-03:22`, `FULL-01:33`, `FULL-02:34`, `FULL-03:35`, `FULL-04:36`, `FULL-05:37`, `ADOPT-03:43`, `ADOPT-04:44`, `DOC-03:48`, `CUT-01:64`, Out-of-Scope `:75`, `:76`, `:84`, mappings `:100`, `:102`, `:109`. Coverage block at `:113-117`. There are indeed **no `WRAP-*` IDs** in the file. Checklist arithmetic confirmed: 4 INV + 4 DISP + 3 OVL + 5 FULL + 4 ADOPT + 2 DOC = 22; minus `FULL-03`, `FULL-05`, `ADOPT-04` = **19**. [VERIFIED: .planning/REQUIREMENTS.md:13-117, read in full this session]

### `.planning/ROADMAP.md` — D-28 line references, all confirmed exact

`:11` milestone description, `:13` not-this-milestone, `:52` Phase 12 line, `:69` Phase 10 criterion 4, `:103` Phase 11 criterion 3, `:131` Phase 12 criterion 2, `:174` Phase 14 criterion 3 — all verified. The coverage line is at **`:252`**: `**Coverage:** v0.1 shipped · v0.2 shipped · v0.3 22/22 requirements mapped · 0 unmapped`. The Phase 16 entry is `:220-229` with `**Goal:** [To be planned]` at `:222` and `**Requirements**: TBD` at `:223`. [VERIFIED: .planning/ROADMAP.md]

### `.planning/phases/11-disposition-decisions/11-DISPOSITIONS.md` — W-1 / W-2 exact sites

- **W-1** is at **`:107-110`**, not `:108-112`: the three `migrate-to-hypr-custom` must-keep rows (monitors `:108`, workspaces `:109`, env `:110`) preceded by the `accept-upstream` primary-entry row at `:107`. [VERIFIED: read with line numbers this session]
- **W-2** is at `:201` exactly: `**Archive policy (D-12):** `.config/{waybar,rofi,swaync}` **remain in repo as archive** (pre-flight captures live). Success for Phases 11–14 does **not** delete these trees from the repo.` The claim is false: `.config/waybar`, `.config/rofi`, `.config/swaync` do **not** exist; `stow/waybar/.config/waybar`, `stow/rofi/.config/rofi`, `stow/swaync/.config/swaync` do. [VERIFIED: `ls -d` on both sets, this session]

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Wrapper injects `SAFE_DEFAULTS`; `--full` opts out | Full is the only behavior; `--full` is a no-op alias | This phase | Every `install`/`install-files` example in the docs loses `--full` |
| Wrapper owns a type-yes backup gate | No wrapper gate; `--skip-backup` forwarded | This phase | The only surviving wrapper prompt is `uninstall_gate` |
| Wrapper re-marks `PROTECT_EXPLICIT` after install | Capability removed | This phase | An orphan sweep can now take the personal stack (accepted, D-07) |
| Wrapper injects ii hooks into `hyprland.conf` | ii owns hooks in its own Lua tree | Phase 14 adopt (2026-09-04); machinery removed this phase | `hyprland.conf` no longer exists live; `env.lua:16` + `execs.lua:6` supply both |
| `hyprctl getoption configProvider` | `hyprctl -j status \| jq -r .configProvider` | Hyprland ≥ 0.56 (already corrected in Phase 15) | The `getoption` form returns `no such option`; the playbook already uses the correct one |
| Three-tier rollback (conf restore / uninstall / protect) | Clean reinstall from the pinned submodule | This phase (D-20) | Tiers 1 and 3 lose their machinery; tier 2 survives as `uninstall` |
| `scripts/phase14-preflight.sh` as the adopt gate | Deleted; the adopt already happened | This phase (D-33) | Closes IN-11 by deletion |

**Deprecated/outdated after this phase:**
- `arch/dots-hyprland.sh protect` — subcommand ceases to exist; anything invoking it gets `[FAIL] Unknown or non-allowlisted subcommand`
- `--skip-protect`, `--keep-hypr-hooks`, `--allow-skip-backup` — flags removed
- `scripts/phase07-live-smoke.sh`, `scripts/phase14-preflight.sh` — deleted
- `.planning/codebase/*.md` (six files, stamped `2026-08-21`) — go false; refresh deferred to a `/gsd-map-codebase` re-run

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Injecting `--skip-backup` for `install`/`install-files` only (rather than all four install-family subcommands) is the right scope | Pitfall 4, Code Examples | Low. Both are functionally safe — upstream ignores the flag where unused. Only the dry-run preview's honesty and the phase16 assert's shape differ. **Needs a planner decision, not user confirmation.** |
| A2 | `--full` becomes accepted on all install-family subcommands after `needs_safe_defaults` is deleted | Pitfall 10 | Low, but user-visible: `install-deps --full` flips from exit 1 to exit 0. D-05 does not state a scope. **Worth one line of confirmation in the plan.** |
| A3 | `run_upstream_uninstall_dangerous()` (`:1288`) and its `--upstream-dangerous` flag survive unchanged | Wrapper Surgery Map | Medium. D-10's keep/lose list is **silent** on this path. It is orthogonal to the safe profile, so keeping it is the conservative reading — but it is the only remaining route to a cascading removal, and the phase is otherwise removing safety machinery. **Confirm with the user.** |
| A4 | The wave-1 commit message will be shaped `feat(16-01): …` so the re-pin comment can cite it | Code Examples | Nil functional risk; cosmetic |
| A5 | `phase14-verify.sh`'s `$BACKUP_DIR` variable becomes unused after the D-37 deletions and can be removed | Runtime State Inventory | Low. If it is still read elsewhere and is removed, `set -u` aborts the script. Verify with `grep -n 'BACKUP_DIR' scripts/phase14-verify.sh` before deleting the declaration. |
| A6 | The `16-DOC-SWEEP.md` filename and its path under the Phase 16 directory are what `phase13-d19-assert.sh` should key on | Code Examples | Nil — D-41 and D-38 both name the file; the directory is verified as `.planning/phases/16-retire-the-safe-profile-full-only-wrapper-and-playbook/` |

**Nothing in this table is a compliance, retention, security-standard or performance claim.** The three items worth a confirmation checkpoint are A1, A2 and — most importantly — **A3**.

---

## Open Questions

1. **Does `--upstream-dangerous` survive?**
   - What we know: `run_upstream_uninstall_dangerous()` is defined at `:1288`, dispatched from `run_uninstall:1373-1376`, guarded by a `UPSTREAM-UNINSTALL` type-token, and calls `./setup uninstall` [VERIFIED: arch/dots-hyprland.sh:1288-1315,1373-1376]. `REQUIREMENTS.md:83` lists "Upstream `./setup uninstall` as rollback" as out of scope, and the runbook §14 Prohibition forbids it.
   - What's unclear: D-10 enumerates what `uninstall` keeps and loses and does not mention this path at all.
   - Recommendation: **keep it unchanged** (it is unrelated to the safe profile), and add one line to the plan recording that it was considered and kept. Raise at the plan checkpoint.

2. **Which phase does `INV-04` map to after its rewrite?**
   - What we know: D-26 says INV-04 "Stays checked, stays mapped to Phase 10." D-27 says "Rewritten rows map to **Phase 16**."
   - What's unclear: INV-04 is a rewritten row, so the two rules conflict for exactly this one ID.
   - Recommendation: follow the **specific** rule (D-26) over the general one (D-27) — keep `INV-04 | Phase 10 | Complete`. This also keeps it consistent with D-39, which deliberately leaves `phase10-inventory-assert.sh` asserting the Phase-10 record.

3. **Does the new `phase16` assert replace `phase12-full-smoke.sh` or sit beside it?**
   - What we know: D-34 rewrites the phase12 smoke "to the new contract"; D-35 adds a new phase16 assert with overlapping subject matter (residual absence, `--full` stripping).
   - What's unclear: the two will assert nearly the same things.
   - Recommendation: give them distinct jobs — **phase12 smoke = wrapper behavior** (syntax, help surface, argv, exit codes); **phase16 assert = the retirement contract** (no residual tokens anywhere in dry-run argv, the `--full` ignored-note, and the D-36 documentation ban-grep). State the split in the plan so a later reader knows which to extend.

4. **What replaces the §7 `phase14-verify.sh` pointer once ADOPT-04 is deleted?**
   - What we know: playbook `:388-392` and `:421` point at `phase14-verify.sh` and the runbook §14; D-26 deletes ADOPT-04, D-37 removes its tier checks, D-20 replaces the tier list.
   - What's unclear: whether `phase14-verify.sh` remains the "executable source of truth" the playbook calls it, once three of its assertions are gone.
   - Recommendation: keep the pointer; the script still verifies ADOPT-02/ADOPT-03 and the D-35/D-36/D-37 blocks. Reword `:392` to drop the rollback escalation clause.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| GNU Bash | wrapper + all asserts | ✓ | 5.3.15(1) | — |
| git | `WRAPPER_BASE` drift pin, submodule | ✓ | 2.55.0 | — |
| python3 | fence extraction in `phase13-d19-assert.sh` | ✓ | 3.14.7 | — |
| jq | playbook §7 `configProvider` probe | ✓ | 1.8.2 | — |
| ripgrep | sweep greps during execution | ✓ | 15.2.0 | `grep -rn` |
| hyprctl | D-40 post-change live login re-verify | ✓ | Hyprland 0.56.2 | — |
| pacman / yay | referenced by surviving `uninstall` prose only | ✓ | libalpm 16.0.1 / yay 13.0.1 | — |
| node | `gsd-tools.cjs` | ✓ | v26.8.1 | — |
| `vendor/dots-hyprland` submodule | `preflight`, upstream flag surface | ✓ | pinned `1a9ffb78` (`2026.05.11-109-g1a9ffb78`) | — |
| **shellcheck** | *not required* | ✗ | — | `bash -n`, already asserted at `phase12-full-smoke.sh:32` |
| Makefile / CI runner | *not required* | ✗ | — | none needed — **confirms D-33's "no runner to update"** [VERIFIED: no `Makefile`, no `.github/workflows`] |

**Missing dependencies with no fallback:** none.
**Missing dependencies with fallback:** `shellcheck` → `bash -n`. Do not add a shellcheck gate to this phase.

**Live-state facts the phase depends on (all verified this session):**
- `~/.config/hypr/hyprland.conf` — **absent**; only `hyprland.conf.old` (15301 B, 2026-08-15) and `hyprland.conf.bak` (14471 B, 2026-06-13) exist
- Zero `*.conf` files under `~/.config/hypr` carry active ii hooks
- `REPO_ROOT/.config/hypr/hyprland.conf` **does** carry both: `:67 exec-once = qs -c ii` and `:111 env = ILLOGICAL_IMPULSE_VIRTUAL_ENV,~/.local/state/quickshell/.venv` — so `list_hypr_ii_hook_target_files` resolves to exactly one file, confirming D-08
- `~/.config/hypr/hyprland/env.lua:16` → `hl.env("ILLOGICAL_IMPULSE_VIRTUAL_ENV", home_dir .. "/.local/state/quickshell/.venv")`
- `~/.config/hypr/hyprland/execs.lua:6` → `hl.exec_cmd("qs -c $qsConfig")`
- `hyprctl -j status` → `{"configProvider": "lua", "backend": "drm"}`; `hyprctl eval 'return 1+1'` → `ok`
- `qs -c ii` running (pid 1432)
- git working tree **clean** at research time

---

## Validation Architecture

`workflow.nyquist_validation` is `true` in `.planning/config.json` [VERIFIED: .planning/config.json].

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Hand-rolled Bash assert scripts with `pass()` / `fail()` helpers and a `FAIL` counter |
| Config file | none — each script is self-contained, `set -euo pipefail`, run from `REPO_ROOT` |
| Quick run command | `./scripts/phase12-full-smoke.sh && ./scripts/phase11-dispositions-assert.sh` |
| Full suite command | `./scripts/phase16-*-assert.sh && ./scripts/phase13-d19-assert.sh && ./scripts/phase12-full-smoke.sh && ./scripts/phase11-dispositions-assert.sh && ./scripts/phase14-verify.sh` |

### Phase Requirements → Test Map

| Req | Behavior | Test Type | Automated Command | File Exists? |
|-----|----------|-----------|-------------------|--------------|
| FULL-01/02 | Bare `install-files --dry-run` emits none of `--core` / `--skip-hyprland` / `--skip-sysupdate` | unit (argv) | `./scripts/phase16-*-assert.sh` | ❌ Wave 3 |
| D-05 | `--full` accepted, prints ignored-note, absent from would-exec argv | unit (argv) | `./scripts/phase16-*-assert.sh` | ❌ Wave 3 |
| D-06 | `--skip-backup` present in would-exec argv for `install`/`install-files` | unit (argv) | `./scripts/phase16-*-assert.sh` | ❌ Wave 3 |
| D-06/D-09 | No `[CONFIG] Type 'yes' to continue` on `install --dry-run` | unit (stdout) | `./scripts/phase16-*-assert.sh` | ❌ Wave 3 |
| D-07 | `protect` rejected as non-allowlisted (exit ≠ 0) | unit (exit code) | `./scripts/phase12-full-smoke.sh` (rewritten) | ✅ rewrite |
| D-36 | Playbook §10 carries no `--skip-hyprland`; file carries no "dual-run" / "safe profile" | unit (grep) | `./scripts/phase16-*-assert.sh` | ❌ Wave 3 |
| D-11 | `bash -n arch/dots-hyprland.sh` clean; `preflight` and array-exec intact | unit (syntax) | `./scripts/phase12-full-smoke.sh:32` | ✅ exists |
| D-10 | `uninstall --dry-run` exits 0 with the stripped flag set | integration (dry-run) | `./scripts/phase14-verify.sh:380-385` | ✅ edit label |
| W-1 | `11-DISPOSITIONS.md` still satisfies every required token | unit (grep) | `./scripts/phase11-dispositions-assert.sh` | ✅ exists |
| W-3 | Playbook §6 fence matches the D-18 SoT fence | unit (diff) | `./scripts/phase13-d19-assert.sh` (extended) | ✅ extend |
| D-38(1) | Wrapper unmodified since the Phase 16 baseline | unit (git) | `./scripts/phase13-d19-assert.sh` | ✅ re-pin |
| ADOPT-02/03 | Session still on the Lua entry; Waybar/rofi/swaync still stopped | integration (live) | `./scripts/phase14-verify.sh` | ✅ exists |
| D-40 | Post-change login re-verify | **manual-only** | human checkpoint — reboot/re-login, then `./scripts/phase14-verify.sh` | n/a |

### Sampling Rate

- **Per task commit:** `bash -n arch/dots-hyprland.sh` (wave 1) or the file's own assert
- **Per wave merge:** the four tree-clean-agnostic scripts (`phase16`, `phase12`, `phase11`, `phase13` — the last expected-red until wave 4)
- **Phase gate:** full suite green on a **committed, clean** tree, with `phase14-verify.sh` at `FAIL=0 FINDINGS=1`, plus the D-40 human login re-verify

### Wave 0 Gaps

- [ ] `scripts/phase16-<name>-assert.sh` — covers FULL-01, FULL-02, D-05, D-06, D-09, D-36 (new; D-35/D-36)
- [ ] `scripts/phase12-full-smoke.sh` — rewritten body (D-34)
- [ ] `scripts/phase13-d19-assert.sh` — third baseline tier + W-3 drift assert (D-38)
- [ ] No framework install needed — the "framework" is `pass`/`fail` + `FAIL` counter, already present in five scripts

**Baseline recorded this session (all green, clean tree):**

```
./scripts/phase12-full-smoke.sh        → === done: FAIL=0 ===                  exit 0
./scripts/phase13-d19-assert.sh        → === Phase 13 asserts: FAIL=0 ===      exit 0
                                          incl. [PASS] arch/dots-hyprland.sh unmodified since 14c6828
./scripts/phase11-dispositions-assert.sh → === done: FAIL=0 ===                exit 0
./scripts/phase10-inventory-assert.sh  → === done: FAIL=0 ===                  exit 0
./scripts/phase14-verify.sh            → === done: FAIL=0 FINDINGS=1 ===       exit 0
```

---

## Security Domain

`security_enforcement: true`, `security_asvs_level: 1` [VERIFIED: .planning/config.json].

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | No auth surface; local operator script |
| V3 Session Management | no | No application sessions (the "session" here is a compositor session) |
| V4 Access Control | **yes** | `is_allowlisted` subcommand gate (`:14`, `:132`); `safe_rm_path` refuses any path outside `$HOME` (`:1060`); `prevent_sudo_or_root` upstream. **All three must survive.** |
| V5 Input Validation | **yes** | Array-only `cmd+=()` construction; **never `eval`**; the `ALLOWLIST` check before dispatch. The `--full` swallow (D-05) is itself an input-validation control — it prevents an unrecognized token reaching upstream's `getopt`. |
| V6 Cryptography | no | The one `sha256sum` use (backup integrity) is being deleted with D-37; nothing new is added |
| V7 Error Handling / Logging | partial | `set -euo pipefail` (`:2`) must survive; shrinking function signatures without shrinking their `local x="$N"` reads is a `set -u` abort |
| V12 File & Resource | **yes** | This phase *removes* the backup safety net (D-06/D-09) and the orphan-protection net (D-07). Both are **accepted, user-confirmed risks**, recorded here rather than mitigated. |

### Known Threat Patterns for a Bash installer wrapper

| Pattern | STRIDE | Standard Mitigation | Status after this phase |
|---------|--------|---------------------|-------------------------|
| Command injection via concatenated argv | Tampering / Elevation | Array-only exec, no `eval` | **Preserved** (D-11) — the phase removes elements from the array build, not the mechanism |
| Unknown flag forwarded to a privileged installer | Tampering | Explicit parse-and-swallow of wrapper-owned meta flags | **Preserved and strengthened** — D-05 exists precisely because `:1414-1416` forwards unrecognized args |
| Arbitrary path deletion during uninstall | Destruction | `safe_rm_path` `$HOME` refusal (`:1060`) | **Preserved** (D-10 keeps the uninstall path) |
| Non-allowlisted upstream subcommand | Elevation | `ALLOWLIST` + `is_allowlisted` | **Preserved**; `protect` is *removed from* the allowlist, which is the correct direction |
| Destructive install with no undo | Destruction | was: `backup_gate` + upstream `auto_backup_configs` | **REMOVED by design.** D-06/D-09; user explicitly informed and accepted. **Record as an accepted risk in `16-SECURITY.md`, not as an open threat.** |
| Orphan sweep removing the compositor | Availability | was: `protect_explicit_packages` re-marking | **REMOVED by design.** D-07; user explicitly informed and accepted. The exposed package set is the 60-entry `PROTECT_EXPLICIT` array, including `hyprland`, `hyprlock`, `kitty`, `fish`, `starship`, `cliphist`, `bc`, `jq` |
| Cascading `yay -Rns` removal | Availability | `run_upstream_uninstall_dangerous` type-token gate | **Unchanged** — but see Open Question 1; this becomes the only remaining cascade route |
| Privileged execution as root | Elevation | Upstream `prevent_sudo_or_root` | Unchanged (upstream-owned) |

**Net security posture change:** this phase is a **deliberate net reduction** in two controls (V12 file-resource: backup; availability: orphan protection), both explicitly accepted by the user during discussion with the consequences stated. No control is reduced *accidentally*, and the four input-validation / access-control mechanisms (array-exec, allowlist, `safe_rm_path`, meta-flag swallow) all survive. The security artifact for this phase should record the two removals as **accepted risks with named user acceptance**, and verify the four survivors are intact.

---

## Sources

### Primary (HIGH confidence — read directly this session)

- `arch/dots-hyprland.sh` (1531 lines) — full symbol map, all call sites, `usage()` heredoc, `run_install_family`, `run_uninstall`, `uninstall_gate`, `run_safe_uninstall`, hook machinery, `PROTECT_EXPLICIT`
- `vendor/dots-hyprland/setup` — subcommand dispatch and `SUBCMD_DIR` routing
- `vendor/dots-hyprland/sdata/subcmd-install/options.sh` — the complete `getopt` long-option surface
- `vendor/dots-hyprland/sdata/subcmd-install/3.files.sh:12-40,219` — `auto_backup_configs` and the `SKIP_BACKUP` gate
- `vendor/dots-hyprland/sdata/lib/functions.sh:64-70` — `pause()`
- `vendor/dots-hyprland/sdata/lib/environment-variables.sh:27` — upstream `BACKUP_DIR`
- `docs/dots-hyprland-workflow.md` (536 lines) — §Purpose, §Profiles, §4, §6, §7, §8, §9, §10, §11, §See-also
- `docs/phase14-adopt-runbook.md` (387 lines) — heading map, §5 preflight sites, §14 tiers
- `.planning/REQUIREMENTS.md` (121 lines, read in full)
- `.planning/ROADMAP.md` — `:1-20`, `:50-55`, `:65-72`, `:100-106`, `:128-134`, `:170-178`, `:220-229`, `:252`
- `.planning/PROJECT.md`, `.planning/STATE.md`, `.planning/v0.3-MILESTONE-AUDIT.md` — token sweep
- `.planning/phases/11-disposition-decisions/11-DISPOSITIONS.md:100-120,195-210`
- `.planning/phases/13-personal-hypr-custom-overlays/13-SOT-APPLY.md:21-56,57-80`
- `.planning/phases/15-playbook-safe-vs-full/15-DOC-SWEEP.md` — sweep-record format
- `scripts/phase12-full-smoke.sh` (163 lines, read in full)
- `scripts/phase13-d19-assert.sh:1-44,96,120-164`
- `scripts/phase14-verify.sh:305-425,510-530,538-564`
- `scripts/phase11-dispositions-assert.sh:125-200`
- `scripts/phase10-inventory-assert.sh:128-145`
- `.planning/config.json`

### Primary — live-state probes (HIGH confidence, executed this session)

- `./scripts/phase12-full-smoke.sh`, `phase13-d19-assert.sh`, `phase11-dispositions-assert.sh`, `phase10-inventory-assert.sh`, `phase14-verify.sh` — all green; outputs quoted in §Validation Architecture
- `diff` of the two apply fences — output `1d0 < # Phase 14 only. Do not run in Phase 13 (D-02, D-17).`
- `hyprctl -j status`, `hyprctl eval`, `hyprctl getoption configProvider`, `hyprctl version`
- `ls -la ~/.config/hypr/`, active-hook scan over `~/.config/hypr/**/*.conf`, `ls -d ~/ii-original-dots-backup*`
- `git submodule status`, `git log --oneline -5 -- arch/dots-hyprland.sh`, `git cat-file -e 14c6828`, `git status --porcelain`
- `command -v` probes for bash, shellcheck, git, python3, jq, rg, pacman, yay, hyprctl, node

### Secondary (MEDIUM confidence)

- None. No web search or external documentation lookup was required or performed — every question this phase raises is answerable from repository source or live machine state, and all external search providers are disabled in `.planning/config.json` (`brave_search`, `firecrawl`, `exa_search`, `tavily_search`, `ref_search`, `perplexity`, `jina` all `false`).

### Tertiary (LOW confidence)

- None.

---

## Metadata

**Confidence breakdown:**

- **Standard stack: HIGH** — no new dependencies; every tool verified present with a version, and the one absent tool (`shellcheck`) has a fallback already in use by the existing suite.
- **Wrapper surgery map: HIGH** — every symbol definition and call site confirmed by `grep -n` against live source this session; the four sites CONTEXT.md omits were found by exhaustive grep, not inference.
- **Architecture / patterns: HIGH** — all three patterns are extracted from existing repo code (`phase13-d19-assert.sh`'s tiering and extractor, `phase12-full-smoke.sh`'s evidence shape), not invented.
- **Pitfalls: HIGH** — 8 of 10 are backed by quoted source plus an executed baseline; Pitfall 4 and Pitfall 10 are HIGH on the mechanism and rest on a planner decision, logged as A1/A2.
- **Upstream behavior: HIGH** — `--skip-backup`, `pause()` and the `getopt` surface were read from the pinned submodule at `1a9ffb78`, not from memory.
- **Documentation sweep inventory: HIGH** — grep-verified line by line against the live files.
- **Planning-artifact additions: HIGH** — grep-verified; presented as additions to CONTEXT.md's lists rather than replacements.
- **Open questions: MEDIUM** — four genuine gaps in CONTEXT.md, one of which (A3 / `--upstream-dangerous`) warrants user confirmation before planning locks.

**Research date:** 2026-09-07
**Valid until:** 2026-10-07 for the upstream-submodule findings (pin is fixed at `1a9ffb78`, so they are stable until a pin bump). **Volatile immediately:** every `arch/dots-hyprland.sh` line number in this document, from the first edit of wave 1 onward — re-grep, per D-12.
