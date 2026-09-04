# Phase 14: Live full adopt & verify - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-04
**Phase:** 14-live-full-adopt-verify
**Areas discussed:** Who runs the live mutation; Process gate mechanism (ADOPT-01); Rollback depth (ADOPT-04); Verification approach (ADOPT-03); Decision review pass (conflict audit)

---

## Who runs the live mutation

Fifteen questions. Selections, in order asked:

| # | Question | Chosen | Not chosen |
|---|----------|--------|------------|
| 1 | Who pulls the trigger on the real install? | Operator runs it, agent preps | Agent runs it; Agent runs it behind a confirmation |
| 2 | What form does the prep deliverable take? | Runbook doc + smoke script | Runbook only; Preflight script only |
| 3 | Who runs the Phase 11 D-07 sync? | Agent runs it, own commit | Operator from runbook; Preflight script does it |
| 4 | How does Phase 14 complete if the install is days later? | Split plans: prep, then verify | One plan with a pause checkpoint; Close at prep, verify in Phase 15 |
| 5 | May the executor run `install --full --dry-run`? | **Pipe yes, rely on `--dry-run`** (corrected) | Originally "dry-run, gate answered no"; No wrapper invocation at all; Pipe `/dev/null` |
| 6 | Where does the operator run the real install? | Bare TTY, Hyprland stopped | Inside current session; SSH from another machine |
| 7 | What if the install dies partway? | Stop, capture, re-run same command | Stop and roll back immediately; Push through manually |
| 8 | Who applies the Phase 13 overlay, and when? | Operator, right after install, before relogin | Operator after first ii login; Agent in the verify plan |
| 9 | Where does Waybar/rofi/swaync teardown happen? | **Automatic at install, no post-verify step** (corrected) | Originally "after ii verified working"; Before the install; Same command as install |
| 10 | What if `pacman -Syu` pulls a new kernel? | Let it, reboot before ii login | Run `-Syu` separately first; Decide at the TTY |
| 11 | How does 14-02 learn what happened? | `script(1)` transcript into phase dir | Operator narrates it; Rely on wrapper logs |
| 12 | What does preflight demand of the submodule? | Pin recorded, clean, no drift | Bump to latest upstream; Whatever is checked out |
| 13 | What about the backup dir before typing yes? | Preflight asserts writable, reports content | Also snapshot `~/.config/hypr` separately; Trust the wrapper gate |
| 14 | What if live DP-1 scale is wrong? | Record in 14-02, fix in a later phase | Fix in repo and re-apply same window; Block phase completion |
| 15 | Anything required of the repo tree before install? | Clean tree, prep committed and pushed | Clean tree only; No requirement |

**Notes:** Q5 and Q9 were both replaced during the review pass — see below.

---

## Process gate mechanism (ADOPT-01)

| # | Question | Chosen | Not chosen |
|---|----------|--------|------------|
| 1 | Where does the ADOPT-01 gate live? | Runbook go/no-go checklist | Preflight exit code is the gate; Both, split by kind |
| 2 | Is the go decision recorded? | Recorded in the `script(1)` transcript | Separate signed-off checklist file; Nothing recorded |
| 3 | What are the no-go conditions? | Hard blockers plus a time and fallback condition | Mechanical blockers only; Decide in the moment |
| 4 | Does the gate cover overlay apply and teardown? | One gate for the whole window | Separate mini-gate before teardown; Only the install is gated |

**Notes:** The preflight exit code remains an input to the checklist rather than the gate itself.

---

## Rollback depth (ADOPT-04)

| # | Question | Chosen | Not chosen |
|---|----------|--------|------------|
| 1 | How deep does rollback go? | **Three tiers, escalating** (corrected) | Originally "config-level restore only"; Config restore plus targeted package removal; No rollback, roll forward only |
| 2 | What is the rollback trigger? | No usable desktop after one honest attempt | Any success criterion fails; Judgment at the time |
| 3 | Where do the rollback steps live? | Section of the runbook, pushed to GitHub | Separate `14-ROLLBACK.md`; Executable rollback script |
| 4 | Is the rollback path proven beforehand? | Prove the inputs exist, not the restore itself | Dry-run the restore commands; Written-only |

**Notes:** The tier-1/tier-2/tier-3 split was adopted after the review pass found "config-level restore only" was narrower than ADOPT-04 actually sanctions — the wrapper's own safe `uninstall` and `protect` subcommands are explicitly permitted by the requirement.

---

## Verification approach (ADOPT-03)

| # | Question | Chosen | Not chosen |
|---|----------|--------|------------|
| 1 | What form do the checks take? | Scripted checks plus a short human checklist | Scripted only; Human checklist only |
| 2 | Scripted or human for monitors/chrome/dual-run? | Both, same script | Split across two passes; Human only |
| 3 | Where do results land? | `14-LIVE-VERIFY.md` with script output and findings | Appended to the transcript; In the commit message |
| 4 | What is the success bar? | Usable ii desktop, overlay applied, Waybar/rofi/swaync gone, findings logged | Everything on the ROADMAP criteria list passes; Operator satisfaction only |
| 5 | What proves ADOPT-02? | All three: `.old` exists, `.lua` exists, `hyprctl` agrees | Any one of the three; Visual confirmation only |
| 6 | What protects the not-firstrun marker? | Preflight asserts the marker, runbook forbids `--firstrun` | Runbook note only; Trust upstream |
| 7 | How is a dirty repo tree handled? | **Invert: expect clean, dirty is a finding** (corrected) | Originally "expect it, review the diff, commit it" |
| 8 | Does anything assert the backup refreshed? | Verify script checks backup is post-install | Assume it ran; Check manually |

---

## Decision review pass (conflict audit)

The operator asked for every captured decision to be re-audited against the actual source before writing CONTEXT. Twelve findings were raised; eight resolved against the code without needing a decision, four went back to the operator.

### Resolved without a decision

- **C-4** — Dropping `waybar`/`swaync` from `PROTECT_EXPLICIT` only blocks a future `protect --install-missing`; `protect_explicit_packages` never demotes an already-explicit package, so rollback tier 1 stays coherent.
- **C-5** — "One gate for the whole window" spans a reboot that `script(1)` cannot. Resolved as two capture artifacts under one gate: the TTY transcript, and the post-reboot verify output.
- **C-6** — Nothing asserted Phase 11 D-24 actually held. Added a byte-identity assertion on live `hyprlock.conf`/`hypridle.conf` plus unpromoted `.new` sidecars.
- **C-8** — The Phase 13 `cp -a` was suspected of clobbering the upstream `custom/` seed. Verified harmless: upstream's `env.lua`, `execs.lua`, and `general.lua` are all 1 byte, same as the repo's. Recorded that the apply must stay a named-file copy so upstream's `keybinds.lua` and `scripts/__restore_video_wallpaper.sh` survive.
- **C-9** — After adopt, the repo's `.config/hypr/hyprland.conf` stops being a session entry and becomes the pre-adopt archive. Recorded for OVL-03/DOC-04.
- **C-10** — The D-07 live-to-repo sync collides with Phase 13 D-03 over `hypr/custom/`. Resolved by excluding that path from the sync.
- **C-3** — The install will not dirty the repo, contrary to the original Q7 premise. Operator chose to invert the expectation.
- **C-11** — `hyprland-session.service` (screen share) has no ii equivalent.

### Sent back to the operator

| Finding | Question | Chosen | Not chosen |
|---------|----------|--------|------------|
| C-1 | Waybar/rofi/swaync teardown cannot happen after verification | Teardown is automatic at install; no post-verify step | Split it in two; Keep Q9 literally via `custom/execs.lua` |
| C-2 | Upstream's backup silently skips when `ask=false` | Rotate the backup dir aside, plus forbid the flags | Rotate only; Rotate and snapshot hypr separately; Runbook prompt script only |
| C-7 | Losses beyond the bar stack | Accept the loss, verify screen share later | Migrate just the session service; Migrate it plus `wl-clip-persist` |
| C-12 | `cp -f` writes through the `starship.toml` stow symlink | Kitty only | Kitty and fish; Kitty, and protect starship too |

**Notes:** The operator asked twice for clarification during this pass — once on what "chrome" meant in this project (answer: Waybar, rofi, swaync — not `google-chrome`, which the live conf also autostarts, hence D-39 banning the word), and once for the backup mechanics to be explained step by step before choosing. The full install trace was walked through in execution order; it was that trace which surfaced C-12.

Operator positions recorded verbatim in CONTEXT: "I really don't need waybar rofi swaync i don't care that much"; "i don't care about starship, need to keep kitty"; "i think all these was supposed to be replaced by dots-hyprland default replacement of these programs" (correct for polkit, cliphist, wallpaper, cursor, and platform theme; not correct for the session service, `wl-clip-persist`, or the autostarts).

---

## Claude's Discretion

- Preflight script structure, check ordering, and output format.
- The exact `hyprctl` assertions satisfying D-33, provided all three conditions are covered.
- Runbook section ordering and prose, provided the single-gate sequence appears once as one unambiguous order.

---

## Deferred Ideas

- DP-1 scale correction if the live scale proves wrong (later phase).
- `hyprland-session.service` / `graphical-session.target` bootstrap for `xdg-desktop-portal` ScreenCast — revisit in Phase 15 if screen share is wanted.
- `wl-clip-persist` and the four workspace-pinned autostarts (Chrome ws1, kitty+tmux ws1, btop, Discord) — Phase 15+ `custom/execs.lua` candidates.
- Personal fish and starship as an active live layer — Phase 11 D-28 stands; only kitty gets the re-stow exception.
- Wrapper `verify` subcommand (POLISH-01) — Phase 14's verify script stays phase-scoped.
