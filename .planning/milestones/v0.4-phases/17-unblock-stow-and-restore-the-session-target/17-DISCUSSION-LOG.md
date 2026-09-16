# Phase 17: Unblock stow and restore the session target - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-12
**Phase:** 17-unblock-stow-and-restore-the-session-target
**Areas discussed:** hyprland.sh:25-26 replacement and stow call sites, Secret scan tool and runner, safe_rm_path repo guard, START-02 hand-sync window, Milestone consistency review

---

## hyprland.sh:25-26 replacement and stow call sites

**Q1 — What replaces `arch/hyprland.sh:24-26` (`mkdir -p` plus `cp -rf .config/hypr/*`)?**

| Option | Description | Selected |
|--------|-------------|----------|
| Delete block, leave marker comment | Remove the three lines; leave a comment naming Phase 20 / HYPR-01 as owner of hypr config placement | ✓ |
| Guarded stow, no-op until Phase 20 | Emit a stow call wrapped in an existence test so it does nothing until `stow/hypr/` appears | |
| Delete and also remove repo `.config/hypr/` | Go further and retire the whole directory now | |

**User's choice:** Delete block, leave marker comment
**Notes:** `stow/hypr/` does not exist until Phase 20, so the literal REQUIREMENTS.md wording ("replaced with a stow invocation") has nothing to invoke. ROADMAP criterion 2 only demands the absence of `cp -rf` and of any cwd-relative path. Removing repo `.config/hypr/` is FIX-03, which belongs to Phase 18.

**Q2 — How is criterion 2 proven?**

| Option | Description | Selected |
|--------|-------------|----------|
| Real run, live session, after FIX-01 lands | End-to-end execution against the production session, `hyprctl -j status` captured before and after, `script(1)` transcript per the Phase 14 convention | ✓ |
| `bash -n` plus the stow section only | Syntax check the file and exercise only the `[CONFIG]` half | |
| Real run, but strip yay and network-displays first | Run end-to-end with the slow AUR step removed | |

**User's choice:** Real run, live session, after FIX-01 lands
**Notes:** Later amended during the consistency review — run as-is, with the operator picking the moment and starting from a clean working tree. The five `sudo pacman -Sy` calls plus one `yay -Sy` carry no `-u`, which is the Arch partial-upgrade hazard; it is recorded as a deferred idea rather than fixed here.

**Q3 — Besides the flag swap, does the stow call shape change at the 15 sites?**

| Option | Description | Selected |
|--------|-------------|----------|
| Flags only, keep the `cd` idiom | `stow --verbose=5 --no-folding -t ~ PKG`, `cd "$(dirname "${BASH_SOURCE[0]}")/../stow" &&` preserved | ✓ |
| Flags plus `-d` instead of `cd` | Replace the directory change with stow's own `-d` flag | |
| Flags plus `--restow` | Add `--restow` so re-runs re-link rather than conflict | |

**User's choice:** Flags only, keep the `cd` idiom
**Notes:** Keeps FIX-01 a mechanical, reviewable edit across 14 files. `--restow` would change re-run semantics, which is Phase 18/20 territory.

**Q4 — Does this phase unfold existing folded stow state?**

| Option | Description | Selected |
|--------|-------------|----------|
| No — audit and record only | Run `find ~/.config -maxdepth 2 -type l -lname '*.dotfiles*'`, hand the list to Phase 18 | ✓ |
| Yes — restow every existing package now | Unfold everything as part of FIX-01 | |
| Defer entirely, no audit | Neither unfold nor record | |

**User's choice:** No — audit and record only
**Notes:** `--no-folding` governs new runs only, so the pre-existing folded directories stay live either way. Phase 18 owns the tree taxonomy that decides what each folded directory becomes.

---

## Secret scan tool and runner

**Q1 — Which secret-scan tool backs CAP-04 / FIX-06?**

| Option | Description | Selected |
|--------|-------------|----------|
| gitleaks plus committed `.gitleaks.toml` | Arch `extra` package, config checked in | ✓ |
| git-secrets | AWS-oriented pattern matcher | |
| Hand-rolled grep pattern list | A script of literal patterns, no dependency | |

**User's choice:** gitleaks plus committed `.gitleaks.toml`
**Notes:** Amended during the consistency review — `.gitleaks.toml` is committed only if triage produces at least one allowlist entry. With zero findings an empty config is dead weight that Phases 18-19 would still have to reason about. Confirmed available as `extra/gitleaks 8.30.1-1`, not currently installed.

**Q2 — When does the scan run this phase?**

| Option | Description | Selected |
|--------|-------------|----------|
| On-demand only, wire into `verify` in Phase 19 | Manual invocation now; integration deferred | ✓ |
| Pre-commit hook now | Gate every commit immediately | |
| Capture-time gate now | Gate the capture path immediately | |

**User's choice:** On-demand only, wire into `verify` in Phase 19
**Notes:** Phase 19 owns the `verify` contract and its exit codes (VER-03); wiring the scan in before that contract exists would have to be redone.

**Q3 — How are pre-existing findings handled?**

| Option | Description | Selected |
|--------|-------------|----------|
| Triage each, allowlist with reason | Real secret removed, rotated, gitignored; accepted finding gets a one-line justification | ✓ |
| Baseline-file everything as accepted | Snapshot current findings and ignore them wholesale | |
| Block the phase until history is rewritten | Require a clean git history first | |

**User's choice:** Triage each, allowlist with reason
**Notes:** "Zero findings" in ROADMAP criterion 4 is read as zero *unreviewed* findings. A blanket baseline would satisfy the letter and not the intent.

**Q4 — What goes into `.gitignore` this phase?**

| Option | Description | Selected |
|--------|-------------|----------|
| Machine state plus generated theme paths | Caches, sockets, lockfiles, `.venv`, state dirs — plus `kdeglobals`, `Kvantum/`, both `gtk.css`, matugen output | ✓ |
| Machine state only | Leave the theme exclusions to Phase 22 | |
| Full per-tree rules now | Write ignore rules per capture tree immediately | |

**User's choice:** Machine state plus generated theme paths
**Notes:** The theme paths are already named as excluded in PROJECT.md, so they are not a new decision. Per-tree rules need Phase 18's collision map to say which tree a path belongs to.

---

## safe_rm_path repo guard

**Q1 — How does `safe_rm_path` recognise a path inside the repo?**

| Option | Description | Selected |
|--------|-------------|----------|
| `realpath -m` both, prefix compare | Resolve candidate and repo root, then compare | ✓ |
| Literal string prefix on `$path` | Compare the unresolved string | |
| `git -C check-ignore` / `rev-parse` probe | Ask git whether the path is in the repo | |

**User's choice:** `realpath -m` both, prefix compare
**Notes:** A literal compare misses a `$HOME` path that reaches the repo through a symlink — exactly what criterion 3's wording ("any path under the repo root") covers. The git probe fails when the checkout is broken, which is a state the uninstaller must still work in.

**Q2 — How is the repo root discovered inside `arch/dots-hyprland.sh`?**

| Option | Description | Selected |
|--------|-------------|----------|
| `BASH_SOURCE`-derived, computed once | `REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"` at the top of the file | ✓ |
| `git rev-parse --show-toplevel` | Ask git | |
| Hard-coded `$HOME/github_repo/.dotfiles` | Literal path | |

**User's choice:** `BASH_SOURCE`-derived, computed once
**Notes:** Matches the idiom already at `arch/waybar.sh:5` and `scripts/phase16-retire-assert.sh:23`. `-P` is added so the comparison in Q1 is against a fully resolved path.

**Q3 — How does the assert script prove the guard without risking a delete?**

| Option | Description | Selected |
|--------|-------------|----------|
| Source in a subshell, refuse-only paths | Import the function, call it on paths that must be refused, assert non-zero | ✓ |
| Run the uninstaller under `--dry-run` | Exercise the real path with deletion suppressed | |
| Copy the function body into the assert script | Test a duplicate | |

**User's choice:** Source in a subshell, refuse-only paths
**Notes:** Keeps the assert script non-mutating, per the `scripts/phase16-retire-assert.sh` header convention. A copied function body would drift from the original.

**Q4 — What happens on a refusal at run time?**

| Option | Description | Selected |
|--------|-------------|----------|
| Abort whole run with `[FAIL]` | Name the path and stop | ✓ |
| Skip that path, continue, warn | Carry on with the rest of the uninstall | |
| Abort but offer `--force` override | Provide an escape hatch | |

**User's choice:** Abort whole run with `[FAIL]`
**Notes:** A destructive path that reached the repo means the caller's assumptions are already wrong; continuing would act on the rest of a plan that is known to be bad.

**Q5 — Is `vendor/dots-hyprland` inside or outside the guard?**

| Option | Description | Selected |
|--------|-------------|----------|
| Inside, no carve-outs | One rule for the whole repo | ✓ |
| Carve-out so the submodule can be cleaned | Allow deletion of the vendored tree | |
| Inside but with a warning-only path | Warn rather than refuse | |

**User's choice:** Inside, no carve-outs
**Notes:** `git submodule deinit` is the correct tool for that tree. A carve-out would be the one hole an attacker of the invariant walks through.

**Q6 — Does `arch/dots-hyprland.sh` become safely sourceable?**

| Option | Description | Selected |
|--------|-------------|----------|
| Add sourced-check dispatch guard | `[[ "${BASH_SOURCE[0]}" == "${0}" ]] && main "$@"` | ✓ |
| Leave dispatch as-is, assert differently | Find another way to test | |
| Extract the function to a new lib file | Split `safe_rm_path` out | |

**User's choice:** Add sourced-check dispatch guard
**Notes:** Survived the consistency review unchanged — it pays forward into Phase 18 criterion 7, where `verify` and `capture` become `ALLOWLIST`-registered, `main`-dispatched handlers.

**Q7 — How many assert scripts does Phase 17 add?**

| Option | Description | Selected |
|--------|-------------|----------|
| One script, sections per criterion | `scripts/phase17-unblock-assert.sh` | ✓ |
| One script per requirement | Seven scripts | |
| Extend `scripts/phase14-verify.sh` | Add to the existing verify script | |

**User's choice:** One script, sections per criterion
**Notes:** Modelled on `scripts/phase16-retire-assert.sh`, using the `[PASS]`/`[FAIL]`/`[INFO]` plus `=== done: FAIL=n ===` contract. `phase14-verify.sh` is a v0.3 artefact and is not the place for v0.4 assertions.

**Q8 — How does the assert script report criterion 5 before the operator re-login?**

| Option | Description | Selected |
|--------|-------------|----------|
| `[INFO]` until re-login, then `[PASS]` | Report inactive as informational, naming re-login as the required step | ✓ |
| `[FAIL]` until it is active | Treat inactive as a failure | |
| Skip the check entirely this phase | Omit it | |

**User's choice:** `[INFO]` until re-login, then `[PASS]`
**Notes:** An agent cannot end the session, so `[FAIL]` would be permanently red through no defect. The same script becomes the post-re-login proof.

---

## START-02 hand-sync window

**Q1 — Which copy of `custom/execs.lua` is source of truth, and how does the live copy get updated?**

| Option | Description | Selected |
|--------|-------------|----------|
| Repo SoT, `cp` to live | Author in `./.config/hypr/custom/execs.lua` with the same header `general.lua` carries; one `cp` to the live path | ✓ |
| Live SoT, copy back to repo | Edit live first so it can be reloaded and tested, then copy back | |
| Symlink live to repo now | Hand-link the live path at the repo copy | |

**User's choice:** Repo SoT, `cp` to live
**Notes:** Applies the Phase 13 precedent unchanged — `general.lua` already carries `-- Authoring SoT: parent-repo .config/hypr/custom/ (see 13-SOT-APPLY.md).` A hand-made symlink would pre-empt HYPR-01 and create an unmanaged link that Phase 18's collision map would not know about.

**Q2 — How is byte-identity between the repo and live copies enforced?**

| Option | Description | Selected |
|--------|-------------|----------|
| Assert-script `cmp` check | `cmp -s` on the two paths, reported `[PASS]`/`[FAIL]` | ✓ |
| Recorded sha256 in the phase doc | Checksum written down, compared by hand | |
| Documented manual diff only | A runbook line telling the operator to diff | |

**User's choice:** Assert-script `cmp` check
**Notes:** Machine-checked on every run, and the check survives into Phase 18 as the drift probe. A recorded hash goes stale on every edit.

**Q3 — Which `exec-once` entries land in `custom/execs.lua` in Phase 17?**

| Option | Description | Selected |
|--------|-------------|----------|
| All seven now | Session service plus the whole D-38 accepted-loss set | ✓ (later reverted) |
| Session service only | Just `systemctl --user start hyprland-session.service` | ✓ (final) |
| Six now, hyprpaper deferred | Everything except the wallpaper daemon | |

**User's choice:** Initially "all seven now"; reverted to "session service only" during the consistency review.
**Notes:** The revert is the single substantive change the review produced. `REQUIREMENTS.md:41` maps the other six entries to **START-01**, which ROADMAP assigns to Phase 20 and verifies in Phase 20 criterion 4. Keeping them out also preserves ROADMAP's `Research: None` justification for Phase 17 — which rests on D-38's fix being one `systemctl --user start` line — and leaves Phase 20's open question Q4 (the `hl.exec_cmd` rules-table key spelling for workspace pinning) to be settled by the experiment Phase 20 already plans.

**Q4 — Where is the START-03 footgun documented and what is the recovery step?**

| Option | Description | Selected |
|--------|-------------|----------|
| `docs/dots-hyprland-workflow.md` | Warning block beside the existing D-38 narrative at line 339 | ✓ |
| New `docs/phase17-startup-runbook.md` | A dedicated runbook | |
| Header comment in the unit file | Extend the existing comment block in the `.service` | |

**User's choice:** `docs/dots-hyprland-workflow.md`
**Notes:** Recovery is `stow --verbose=5 --no-folding -t ~ systemd` followed by `systemctl --user daemon-reload`; the block also names `systemctl --user mask` as the safe alternative. An operator about to run `systemctl --user disable` is not reading the unit file, which is why the unit-header option was rejected.

**Q5 — How does `custom/execs.lua` structure its entries relative to the vendor file?**

| Option | Description | Selected |
|--------|-------------|----------|
| Own `hl.on` block | `hl.on("hyprland.start", function() ... end)` in the custom file | ✓ |
| Bare `hl.exec_cmd` calls, no wrapper | Top-level calls at require time | |
| Edit the vendor file directly | Append into `hyprland/execs.lua` | |

**User's choice:** Own `hl.on` block
**Notes:** `hyprland.lua` requires `custom.execs` after `hyprland.execs`, so both handlers register against the same event. Bare calls would run at require time, changing ordering relative to the vendor entries. Editing vendor is exactly what the `custom/` overlay exists to avoid, and is wiped on the next ii update.

**Q6 — How do the four workspace-pinned autostarts carry their `[workspace N]` targeting in Lua?**

| Option | Description | Selected |
|--------|-------------|----------|
| Keep the dispatch prefix in the string | `hl.exec_cmd("[workspace 1] google-chrome-stable …")` | ✓ (later withdrawn) |
| Drop the pinning, plain `exec_cmd` | No workspace targeting | |
| Use a windowrule instead of the prefix | Assign by class in `custom/rules.lua` | |

**User's choice:** Withdrawn during the consistency review.
**Notes:** No workspace-pinned entry lands in Phase 17 once Q3 was reverted, so the question does not arise here. It is ROADMAP Phase 20's open question Q4, which has its own documented fallback (`hyprctl dispatch exec '[workspace N silent] …'`).

**Q7 — What does the assert script check about `custom/execs.lua` beyond the `cmp`?**

| Option | Description | Selected |
|--------|-------------|----------|
| `cmp` plus a grep gate on all seven | Literal-substring grep per command | ✓ (scaled to one) |
| `cmp` identity only | Trust the contents | |
| `cmp` plus a Lua syntax check | `luac -p` on the repo copy | |

**User's choice:** `cmp` plus a grep gate, scaled down to a single line during the consistency review.
**Notes:** The gate now greps for the literal `systemctl --user start hyprland-session.service`. It still catches the failure `cmp` alone cannot — a partial edit that both copies share, so they compare equal while being equally wrong.

**Q8 — Does Phase 17 also `systemctl --user enable` the unit?**

| Option | Description | Selected |
|--------|-------------|----------|
| `exec_cmd` start only, never enable | Start from `execs.lua`, leave the unit in state `linked` | ✓ |
| Enable it once, drop the `exec_cmd` | Let systemd start it on its own | |
| Both enable and start | Belt and braces | |

**User's choice:** `exec_cmd` start only, never enable
**Notes:** Matches the unit's own header comment at line 6. Enabling would create `~/.config/systemd/user/*.wants/` entries and move the unit from `linked` to `enabled` — the exact state in which the START-03 `disable` footgun becomes reachable. The unit is `Type=oneshot` with `RemainAfterExit=yes`, so one start suffices.

---

## Milestone consistency review

At the close of discussion the user asked for a review of all captured decisions against the
milestone: conflicts, and anywhere a simpler path existed. All twenty decisions were re-checked
against `.planning/ROADMAP.md` (Phases 17 through 23), `.planning/REQUIREMENTS.md`, and
`.planning/PROJECT.md`.

**Conflicts found**

| Finding | Resolution |
|---------|-----------|
| **C1** — "All seven `exec-once` entries" pulls START-01 out of Phase 20. `REQUIREMENTS.md:41` maps it to Phase 20; ROADMAP Phase 20 criterion 4 verifies it; ROADMAP Phase 17's `Research: None` rests on the fix being *one* line; Phase 20's open Q4 was being pre-decided without its experiment. | Reverted to session-service-only. Q6 withdrawn, Q7's gate scaled from seven greps to one. |
| **C2** — Repo SoT `./.config/hypr/custom/execs.lua` sits in a directory Phase 18 criterion 6 (FIX-03) deletes. | Accepted, because the Phase 13 precedent already names that path. CONTEXT.md now carries the explicit handoff row so Phase 18's redistribution table cannot lose it. |

**Gap found**

| Finding | Resolution |
|---------|-----------|
| **G1** — `.gitattributes` with `* text=auto eol=lf` is required by ROADMAP criterion 4 and was never discussed. No such file exists in the repo. | Locked into CONTEXT.md as D-10, a mandatory non-discussed item. |

**Simplifications considered**

| Finding | Outcome |
|---------|---------|
| **S1** — the seven-way grep gate | Applied, as a consequence of C1's revert. |
| **S2** — `.gitleaks.toml` committed unconditionally, even when empty | Applied — committed only if triage produces at least one allowlist entry. |
| **S3** — the end-to-end run of `arch/hyprland.sh` fires five `sudo pacman -Sy` calls plus one `yay -Sy`, none carrying `-u` | Not applied. Run as-is; the operator picks the moment with a clean working tree. Fixing the flag maps to no v0.4 requirement, so it is recorded as a deferred idea. |

**Held unchanged after review**

- `realpath -m` prefix comparison — a literal string compare misses the symlink route into the
  repo, which is the case criterion 3 is written to catch.
- The sourced-check dispatch guard — it pays forward into Phase 18 criterion 7.

---

## Claude's Discretion

- Wording and placement of the Phase 20 / HYPR-01 marker comment in `arch/hyprland.sh`.
- The precise machine-state glob list in `.gitignore`, beyond the named generated-theme paths.
- Section ordering inside `scripts/phase17-unblock-assert.sh`, provided one section maps to one
  success criterion.

## Deferred Ideas

- The six remaining START-01 `exec-once` entries — `wl-clip-persist`, `google-chrome-stable` on
  workspace 1, `kitty -e tmux` on workspace 1, `btop` on `special:btop`, `vesktop`-or-`discord`
  on `special:social`, `hyprpaper`. Phase 20, after `stow/hypr/` exists.
- `arch/hyprland.sh`'s five `sudo pacman -Sy` calls plus one `yay -Sy`, all missing `-u`. No
  v0.4 requirement owns this.
- Unfolding the already-folded stow directories — Phase 18, informed by the audit this phase
  records.
- Wiring the secret scan into `verify` — Phase 19.
- Retiring repo-root `.config/` — Phase 18, FIX-03; must absorb the `execs.lua` row.
