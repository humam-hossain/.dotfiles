# Phase 16: Retire the safe profile: full-only wrapper and playbook - Context

**Gathered:** 2026-09-07
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase retires the safe profile from the project entirely — in the wrapper, in the documentation, and in the planning artifacts that promise it.

`arch/dots-hyprland.sh` stops injecting `SAFE_DEFAULTS`, so a bare `install` / `install-files` runs what `--full` runs today. The same phase deletes the machinery that only existed to serve the safe/dual-run model: the backup gate, the protect machinery, and the ii-hook injection machinery. `uninstall` survives in stripped form. `docs/dots-hyprland-workflow.md` is rewritten full-only end to end with bare commands, and `docs/phase14-adopt-runbook.md` is swept to match. The contradicted rows in `.planning/REQUIREMENTS.md` are amended or deleted, and `.planning/ROADMAP.md`, `.planning/PROJECT.md`, `.planning/STATE.md` and `.planning/v0.3-MILESTONE-AUDIT.md` are swept for the same falsehoods.

Because the wrapper and the documentation change in one phase, there is no window in which the docs describe behavior the code does not have. This is a deliberate merge of what was briefly planned as Phase 16 (docs) plus Phase 17 (wrapper); **no Phase 17 exists**.

The phase also closes three v0.3 audit leftovers that live in the same files: IN-11, W-1, W-2, and W-3.

**Not in this phase:** WR-02 (the three roles of the repo `.config/hypr/hyprland.conf`) and D-38 (the `graphical-session.target` autostart bootstrap lost with the renamed conf) both stay open and unowned.

</domain>

<decisions>
## Implementation Decisions

### Phase shape and edit boundary

- **D-01:** One merged phase. Phase 16 changes the wrapper contract and the documentation together. No Phase 17 is added to the roadmap; the existing Phase 16 goal line is widened to cover the wrapper change instead. The earlier docs/wrapper split created three defects that all dissolve on merge — the phase assert could not check flipped argv against unchanged code, the phase gate referenced suites rewritten in the other phase, and `--full` needed a no-op alias purely to survive the inter-phase window.
- **D-02:** Phase 15 **D-19** ("a documentation phase does not edit scripts") is **lifted for this phase**. Edits reach `docs/`, `scripts/`, and `arch/dots-hyprland.sh`.
- **D-03:** Phase 15 **D-22** (phase artifacts are frozen records; no direct `ROADMAP.md` edits) is **overridden at named sites only**: the W-1 and W-2 rewrites in `.planning/phases/11-disposition-decisions/11-DISPOSITIONS.md`, and the `ROADMAP.md` milestone prose plus coverage line. The exception is recorded because no `gsd-tools.cjs` query handler edits milestone prose or success criteria. Everything else under `.planning/phases/**` and `.planning/milestones/**` stays frozen.

### Wrapper contract — `arch/dots-hyprland.sh`

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

### Documentation — `docs/dots-hyprland-workflow.md`

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

### Documentation — `docs/phase14-adopt-runbook.md`

- **D-24:** The runbook is swept by hand, including its `--rotate-backup` text and its §14 tier list (D-20). Phase 15 **D-02** split roles hold: the runbook stays the adopt-window narrative, the playbook stays canonical. Correcting falsehoods is not the same as restructuring it.
- **D-25:** §5 becomes historical narrative rather than a runnable step, because `scripts/phase14-preflight.sh` is deleted (D-33). Invocation sites: `:81`, `:84`, `:100`, `:146`, `:149`, `:153`.

### Requirements and planning-artifact amendments

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

### Scripts and evidence

- **D-33:** Delete `scripts/phase07-live-smoke.sh` and `scripts/phase14-preflight.sh`. The live-smoke script asserts the protect subcommand, `--skip-protect`, hook disable, `SAFE_DEFAULTS` dry-run output and dual-run Waybar — every one of which this phase removes. The preflight script loses far more than IN-11: also the D-26 protect assert (`:277-281`), the D-13/D-27 backup rotation path (`:75-90`, `:242-267`) and the gate-fed `install --full` check (`:297-307`); the adopt it gated already happened and nothing re-runs it. **IN-11 closes by deletion**, superseding the earlier plan to fix its `--rotate-backup` message — and with it the tech-debt entry at `v0.3-MILESTONE-AUDIT.md:70` and the open-review entry at `STATE.md:107`. No Makefile, CI workflow or `.claude` hook invokes anything in `scripts/`, so neither deletion has a runner to update.
- **D-34:** Rewrite `scripts/phase12-full-smoke.sh` to the new contract rather than retiring it — one live suite per behavior. Its current assertions to replace: `FULL-01` (`:63-73`), `FULL-02` (`:96-102`, which requires the residuals to be present), `:110-111`, `FULL-03` (`:122-125`), `FULL-03b` (`:129-134`), `FULL-05` (`:143-148`), and the `install-deps --full` rejection at `:153`.
- **D-35:** Add a new `scripts/phase16-*-assert.sh` in the same evidence shape as `phase12-full-smoke.sh` — dry-run argv only, no live install. It asserts: bare `install-files --dry-run` emits none of `--core` / `--skip-hyprland` / `--skip-sysupdate`; `--full` is still accepted, prints the ignored-note, and is **not** forwarded to `./setup`. The earlier "`--safe` re-injects all three" clause is dead (D-05).
- **D-36:** The same assert carries the doc forbidden-string grep, **scoped to `docs/dots-hyprland-workflow.md` only**. It is ban-only: it forbids strings (no `--skip-hyprland` in §10, no "dual-run", no "safe profile") and never *requires* `--full`. `.planning/` artifacts legitimately carry that history, and `scripts/phase10-inventory-assert.sh:136` and `scripts/phase11-dispositions-assert.sh:139` actively require it to be present. `docs/phase14-adopt-runbook.md` is swept by hand but **not** grep-gated — it is the adopt-window historical record under Phase 15 D-02, and banning the tokens there would force rewriting a true record of what the adopt ran.
- **D-37:** `scripts/phase14-verify.sh` edits. **Delete:** `:374-378` (ADOPT-04 tier-1 source 3 presence/non-empty check on `$BACKUP_DIR`), `:386-390` (ADOPT-04 tier 3 `protect --dry-run`), `:394-420` (the D-36 backup sha256/mtime block — no future install produces a backup; the existing snapshot stays on disk, only the check goes). **Keep:** `:380-385` (tier 2 `uninstall --dry-run`, since uninstall survives) with its ADOPT-04 label rewritten, and `:313-328` (the Waybar/rofi/swaync accept-remove asserts, which the retirement reinforces). **Reword:** `:521`, whose D-38 finding text cites `PROTECT_EXPLICIT`, which will not exist.
- **D-38:** `scripts/phase13-d19-assert.sh` gets two changes. (1) **Re-pin.** Its `WRAPPER_BASE` check (`:146-158`) fails by design whenever `arch/dots-hyprland.sh` differs from the pinned `14c6828`, and the Phase 16 gate runs that script — as written the gate contradicts itself. Add a **third baseline tier** following the file's own two-tier precedent, keyed on a Phase 16 marker file (`16-DOC-SWEEP.md`), pinned to the commit that lands the wrapper rewrite. (2) **W-3.** Add the fence-drift assert here rather than in a new script: playbook §6 duplicates the Phase 13 D-18 apply fence with nothing checking the copy, and this script is already where that fence is extracted and executed. The playbook block stays operator-runnable.
- **D-39:** Leave `scripts/phase10-inventory-assert.sh` alone. `:135-136` keeps requiring "safe/default dual-run remains available" language in `10-INVENTORY.md` after `INV-04` loses that clause. That is not a conflict — the assert verifies a frozen record of what Phase 10 captured, not current policy.
- **D-40:** **Phase gate before Phase 16 closes:** the new phase16 assert, `scripts/phase13-d19-assert.sh`, the rewritten `scripts/phase12-full-smoke.sh`, `scripts/phase14-verify.sh`, `scripts/phase11-dispositions-assert.sh` (added because the W-1 rewrite can break it), plus a **post-change live login re-verify** of the session. `phase14-verify.sh`'s known D-38 `[FINDING]` stays allowed, as in Phase 15.
- **D-41:** Write `16-DOC-SWEEP.md` recording what changed where, same shape as `15-DOC-SWEEP.md`.

### Sequencing constraints

- **D-42:** **The wrapper commit must land before the documentation commit.** The playbook quotes exact wrapper output (D-23); docs written first would quote strings the code no longer prints.
- **D-43:** The `phase13-d19-assert.sh` re-pin commit follows the wrapper commit and cites its SHA. **`16-DOC-SWEEP.md` must land in the same wave as the re-pin, ahead of the gate** — the new third tier keys on that file's presence, so between the wrapper commit and the sweep file the assert would fail on every run.

### Claude's Discretion

- **W-3 handling shape** — the user answered "you decide" on whether the duplicated §6 apply fence was in scope. Decided: in scope, as an extension to `scripts/phase13-d19-assert.sh`, no new script (D-38).
- Section ordering, heading names and prose voice inside the rewritten playbook, within the Phase 15 D-03 single-spine rule.
- The exact wording of the "superseded" annotation used in `PROJECT.md`, `STATE.md` and `REQUIREMENTS.md`, as long as one form is used consistently.
- Wave decomposition, beyond the two hard ordering constraints in D-42 and D-43.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### The code being changed
- `arch/dots-hyprland.sh` — the wrapper. All of D-04 through D-13 land here. Anchor on symbol names, not the line numbers quoted in this document (D-12).

### The documents being changed
- `docs/dots-hyprland-workflow.md` — the canonical playbook (Phase 9 DOC-01/DOC-02, rewritten in Phase 15). Full-only rewrite target.
- `docs/phase14-adopt-runbook.md` — the 2026-09-04 adopt-window narrative. Swept, not restructured; holds the §14 rollback tiers being replaced.

### Requirements and roadmap
- `.planning/REQUIREMENTS.md` — the 22 v0.3 rows; amendment table in D-26, coverage math in D-27.
- `.planning/ROADMAP.md` — milestone prose `:11`, `:13`, Phase 10 criterion `:69`, coverage line, Phase 16 goal line.
- `.planning/PROJECT.md` — current-state vs history sweep (D-29).
- `.planning/STATE.md` — current-state vs history sweep (D-30).
- `.planning/v0.3-MILESTONE-AUDIT.md` — B-1, B-2, W-1, W-2, W-3, IN-11 originate here; rewrite sites in D-31.

### Prior-phase records this phase depends on or edits
- `.planning/phases/11-disposition-decisions/11-DISPOSITIONS.md` — D-10 residual language, D-11 accept-remove of Waybar/rofi/swaync, D-12 `stow/` archive. W-1 (`:108-112`) and W-2 (`:201`) rewritten in place.
- `.planning/phases/13-personal-hypr-custom-overlays/13-SOT-APPLY.md` — SoT for the repo→live overlay apply policy and the D-18 fence that `phase13-d19-assert.sh` extracts and W-3 duplicates.
- `.planning/phases/15-playbook-safe-vs-full/15-CONTEXT.md` — D-02 (split roles of playbook vs runbook), D-03 (single spine), D-19 (lifted by D-02 here), D-22 (overridden by D-03 here).
- `.planning/phases/15-playbook-safe-vs-full/15-DOC-SWEEP.md` — the format `16-DOC-SWEEP.md` follows.

### Test and assert scripts
- `scripts/phase12-full-smoke.sh` — rewritten to the new contract (D-34).
- `scripts/phase13-d19-assert.sh` — re-pinned and extended (D-38).
- `scripts/phase14-verify.sh` — targeted deletions and rewordings (D-37).
- `scripts/phase11-dispositions-assert.sh` — constrains the W-1 rewrite; added to the gate (D-32, D-40).
- `scripts/phase10-inventory-assert.sh` — read to confirm it is left alone (D-39).
- `scripts/phase07-live-smoke.sh`, `scripts/phase14-preflight.sh` — deleted (D-33).

### Archives referenced but not touched
- `stow/waybar/.config/waybar`, `stow/rofi/.config/rofi`, `stow/swaync/.config/swaync` — the dual-run trees archived by Phase 11 D-12. They stay in the repo, untouched; W-2 corrects the path claim that points at them.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`scripts/phase12-full-smoke.sh`** — the evidence shape for the new phase16 assert: `--dry-run` argv capture, per-requirement `pass`/`fail` helpers, no live mutation. Copy the structure, invert the assertions.
- **`scripts/phase13-d19-assert.sh` two-tier `WRAPPER_BASE` pattern** — the file already switches baseline commit by marker-file presence. The Phase 16 re-pin is a third tier in the same idiom, not a new mechanism.
- **`15-DOC-SWEEP.md`** — the doc-sweep record format `16-DOC-SWEEP.md` reuses.
- **`print_lines` (`arch/dots-hyprland.sh:296`)** — survives the protect deletion and stays in use by the three `collect_ii_*` helpers.

### Established Patterns
- **Array-only exec, never `eval`** — the wrapper builds `cmd+=(...)` and execs the array. The flip removes elements from that build; it does not change the mechanism.
- **`ALLOWLIST` gating** — subcommands are validated against `:14` before dispatch. Dropping `protect` from the array is what actually retires the subcommand; deleting `run_protect` alone would leave a dispatch hole.
- **Unrecognized args fall into `user_flags` and are forwarded to `./setup`** (`:1414-1416`). This is why `--full` must be explicitly parsed and swallowed rather than simply ignored (D-05).
- **Frozen phase artifacts** — `.planning/phases/**` and `.planning/milestones/**` record what a phase shipped and are not rewritten when later phases contradict them. This phase overrides that at exactly two sites (D-03) and applies the superseded-marking rule everywhere else (D-29, D-30).
- **Assert scripts gate planning documents, not just code** — `phase10-inventory-assert.sh` and `phase11-dispositions-assert.sh` grep `.planning/` prose for required tokens. Any rewrite of those documents must be checked against the asserts first (D-32, D-39).

### Integration Points
- **`SAFE_DEFAULTS` injection branch (`~:1443-1454`)** is the single point where the profile decision reaches argv. Everything else in D-04 is dead code that falls out once it goes.
- **`uninstall_gate` (`:936`) is kept but calls protect machinery at `~:967`** — this is the one place where a "delete protect" and a "keep uninstall" decision physically collide. The preview block inside the gate must go with the machinery (D-07).
- **ii owns the session hooks post-adopt** — `~/.config/hypr/hyprland/env.lua:16` and `~/.config/hypr/hyprland/execs.lua:6`. This is what makes the wrapper's hook machinery inert and deletable (D-08), and what the playbook must say instead (D-19).
- **`docs/dots-hyprland-workflow.md:184-190`** embeds literal wrapper stdout. It is the coupling that forces wrapper-before-docs ordering (D-42).
- **`16-DOC-SWEEP.md` becomes a load-bearing marker file**, not just a record — `phase13-d19-assert.sh` keys its third baseline tier on it (D-38, D-43).

</code_context>

<specifics>
## Specific Ideas

- The user's own rule for stale documentation, stated during discussion and applied in D-16: *"if it no longer exists in the code then delete it."* Prefer deletion over softening throughout the sweep.
- *"I don't need dual run anymore, so remove it completely."* — B-2 closes by retiring the destination, not by documenting a route back to it. No restore-to-dual-run path is written anywhere.
- *"I don't need nothing else anymore so full always, rest of the skip and stuff no need."* — the playbook is full-only end to end, not full-with-a-safe-appendix.
- Current live machine state stays exactly as it is. Nothing in this phase runs against the live session except the post-change login re-verify in D-40. Archived trees stay in the repo; `~/ii-original-dots-backup` stays on disk.
- Write `Waybar`, `rofi`, `swaync` literally — never "chrome" (Phase 14 D-39).

</specifics>

<deferred>
## Deferred Ideas

- **WR-02** — the three roles of the repo copy `.config/hypr/hyprland.conf` (rollback source, frozen D-36 evidence, pre-adopt hook-injection target). The hook-injection role dies in this phase, but the question of what the file is for stays open and unowned.
- **D-38 restoration** — the `graphical-session.target` / `hyprland-session.service` bootstrap lost with the renamed conf, affecting xdg-desktop-portal ScreenCast, `wl-clip-persist`, and the four workspace-pinned autostarts. Documented as a known loss in Phase 15; still no owner. `phase14-verify.sh` keeps emitting it as an allowed `[FINDING]`.
- **`/gsd-map-codebase` re-run after this phase.** The six `.planning/codebase/` snapshots (all stamped `2026-08-21`) describe the wrapper as it is now and go false in this phase. They are dated regenerable snapshots, not hand-maintained contracts, so they are **left untouched here** and refreshed by the mapper afterwards. Sites left to the re-map: `ARCHITECTURE.md:66, :138, :141, :153, :173, :260`; `STRUCTURE.md:107`; `STACK.md:65, :89`; `CONVENTIONS.md:11, :79, :83`; `CONCERNS.md:133`; `TESTING.md:24, :60, :113, :171`.
- **Pre-milestone research and v0.2 history stay untouched** — `.planning/research/{ARCHITECTURE,FEATURES,PITFALLS,STACK,SUMMARY}.md`, `.planning/MILESTONES.md:15`, `.planning/RETROSPECTIVE.md:14, :37`. Same class as `.planning/phases/**`: records of what was true when written.
- **CUST-01..03** (Waybar ping/weather/earthquake module ports into ii) and **POLISH-01..03** remain future requirements. This phase only rewords the Out-of-Scope reason clause that justified them by dual-run.
- **`README.md`** needs no edit — its single mention of `arch/dots-hyprland.sh` (`:5`) carries no profile or backup claim.

</deferred>

---

*Phase: 16-Retire the safe profile: full-only wrapper and playbook*
*Context gathered: 2026-09-07*
