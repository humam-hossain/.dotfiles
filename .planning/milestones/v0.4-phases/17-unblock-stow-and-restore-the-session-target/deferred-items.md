# Phase 17 — deferred items

Out-of-scope discoveries logged during execution. Nothing here was fixed; each
row names what is broken, why it was left alone, and who should own it.

---

## D-1 — `scripts/phase14-verify.sh` aborts on a baseline fixture the v0.3 archive moved

**Found during:** plan 17-03, Task 3 (running the plan's wave-close verification).

**Symptom:**

```
$ ./scripts/phase14-verify.sh
[FAIL] baseline fixture missing: .planning/phases/14-live-full-adopt-verify/14-PRE-ADOPT-BASELINE.txt
EXIT=1
```

The script aborts before its first assert, so it never reaches its own
`=== done: FAIL=n ===` line at all.

**Cause:** the fixture still exists — it was relocated by `f314491 chore: archive
v0.3 milestone` and now lives at
`.planning/milestones/v0.3-phases/14-live-full-adopt-verify/14-PRE-ADOPT-BASELINE.txt`.
`scripts/phase14-verify.sh` still hard-codes the pre-archive
`.planning/phases/…` path.

**Pre-existing, not caused by 17-03.** The three commits in this plan touch only
`.gitattributes`, `.gitignore`, `.gitleaks.toml` and
`scripts/phase17-unblock-assert.sh` (`git diff --name-only b95917a4 HEAD`), and
`git check-ignore --no-index` exits 1 on the fixture path, so none of the new
ignore patterns reaches it.

**Why deferred:** out of scope under the executor scope boundary — this is a
failure in an unrelated file with an unrelated cause. Fixing it means editing a
Phase 14 artifact to be archive-aware, which is the same repair plan 17-02
already performed on `scripts/phase13-d19-assert.sh`.

**Suggested owner / fix:** whoever next touches Phase 14 verification. Apply the
17-02 pattern: resolve phase artifacts through a live-tree-then-milestone-archive
lookup instead of a hard-coded `.planning/phases/` path. See 17-02-SUMMARY.md,
pattern "Phase artifacts are resolved through a live-tree-then-milestone-archive
lookup".

**Impact if left:** Phase 17 plans whose `<verify>` block calls
`./scripts/phase14-verify.sh` (17-03 Task 2 does) cannot satisfy that one check.
The three live harnesses — `phase17-unblock-assert.sh`,
`phase16-retire-assert.sh`, `phase13-d19-assert.sh` — all close `FAIL=0`, so
phase coverage is intact apart from this stale path.

---

## D-2 — no repo-wide sweep for scripts hard-coding a pre-archive `.planning/phases/` path

**Found during:** plan 17-04, while re-running the sibling suites at wave close.

**Symptom:** the same defect has now appeared in two separate scripts. Plan
17-02 fixed it in `scripts/phase13-d19-assert.sh`; D-1 above records it still
open in `scripts/phase14-verify.sh`. Both hard-code a `.planning/phases/…` path
that `f314491 chore: archive v0.3 milestone` relocated to
`.planning/milestones/v0.3-phases/…`.

**Cause:** milestone archival moves phase directories, and nothing checks
whether a script still points at the old location. Each occurrence has been
found by a script failing at run time, one at a time.

**Why deferred:** this is a cross-cutting repository sweep, not a Phase 17
change. Phase 17's scope is the stow unblock and the session target; editing
every phase harness to be archive-aware is outside it, and doing it piecemeal as
each script happens to fail is what produced two separate fixes already.

**Suggested owner / fix:** Phase 18. Grep the repository for the literal
`.planning/phases/` outside `.planning/` itself, and convert each hit to the
live-tree-then-milestone-archive lookup that 17-02 established. See
17-02-SUMMARY.md, pattern "Phase artifacts are resolved through a
live-tree-then-milestone-archive lookup".

**Impact if left:** every future milestone archival silently breaks another
batch of harnesses, each discovered only when someone runs it.

---

## D-3 — stopping `graphical-session.target` fans a stop out to eight live helper services

**Found during:** plan 17-05, Task 1 (the single by-hand proof of the START-02
mechanism that the plan authorises).

**Symptom:** reverting the proof with
`systemctl --user stop hyprland-session.service` also stopped eight services
that were active before it and had nothing to do with the proof:

```
at-spi-dbus-bus.service          active -> inactive
xdg-desktop-portal.service       active -> inactive
xdg-desktop-portal-gtk.service   active -> inactive
xdg-desktop-portal-hyprland.service active -> inactive
plasma-xdg-desktop-portal-kde.service active -> inactive
xdg-document-portal.service      active -> inactive
xdg-permission-store.service     active -> inactive
gvfs-daemon.service              active -> inactive
```

**Cause:** measured, not inferred. `graphical-session.target` carries
`StopWhenUnneeded=yes`, and `hyprland-session.service` is the only unit that
`Wants=` it — none of the eight declares `Requisite=` or `Requires=` on it, so
stopping the service makes the target unneeded and systemd stops it. All eight
carry `PartOf=graphical-session.target` (visible as the target's `ConsistsOf=`),
and `PartOf` propagates stop. The start direction does **not** propagate, which
is why starting the unit brings up the target and nothing else — that half was
already recorded as threat T-17-18.

**Not a repo defect.** This is the operator's systemd graph behaving exactly as
configured, and the same fan-out happens at every normal session end. Nothing in
this repository causes it and nothing here should suppress it.

**Why deferred:** there is nothing to fix, only something to know. It is logged
because the blast radius is invisible from the plan text, which describes the
revert as simply returning two units to inactive.

**Mitigation applied in 17-05, for whoever repeats the proof:** the proof was
run only after confirming `/run/user/1000/gvfs` held no active fuse mount and no
capture process was running, so nothing could be lost by a portal restart. All
eight services were then returned to `active` by natural D-Bus activation —
read-only property reads and getters, no `systemctl` verb — and the session was
confirmed back in its as-found state.

**Suggested owner / fix:** Phase 20, when START-01 restores the remaining six
startup entries and will want to re-prove the same mechanism. Prefer proving it
at a real login rather than by a hand start-and-stop, or accept the fan-out
knowingly and reactivate as above.

**Impact if left:** an agent or operator who hand-proves START-02 without
knowing this will stop a running screen share or an open portal dialog and read
it as an unrelated failure.

---

## D-4 — the playbook's §7 observed-counts line cannot be re-measured while D-1 stands

**Found during:** plan 17-05, Task 2 (rewriting §7's expected-output block).

**Symptom:** §7 records `33 [PASS], 0 [FAIL], one [FINDING]` as the observed
output of `./scripts/phase14-verify.sh`. That observation cannot be refreshed
today, because the script aborts on the relocated baseline fixture (D-1) before
reaching a single assert, let alone its closing line.

**Cause:** D-1. The counts themselves are not suspect — they were recorded on a
committed tree after the Phase 16 script edits — but they are now a historical
observation rather than a reproducible one.

**Why deferred:** fixing it means fixing D-1 first, which is already deferred to
Phase 18 under D-2. Plan 17-05 did what it could without that: §7 now states
both the pre- and post-re-login expected finding counts and the single condition
that selects between them, so the playbook is correct in both states even though
neither can be re-measured until D-1 is closed.

**Suggested owner / fix:** whoever closes D-1. Re-run the script and refresh the
observed counts in §7 in the same change.

**Impact if left:** a reader who runs the §7 command gets an abort rather than
either documented outcome, and has no way to tell from the playbook alone that
the abort is a known unrelated defect.

---

## D-5 — `arch/hyprland.sh` resolved its second directory change from the wrong base — RESOLVED IN PHASE 17

**Status:** resolved in plan 17-06. Kept here as a record, not as an open item.

**Found during:** plan 17-06, at the blocking checkpoint that opens the plan.

**Symptom:** the script changed directory into the stow tree twice, at the two
stow stanzas, using the identical expression both times:

```
cd "$(dirname "${BASH_SOURCE[0]}")/../stow" && stow --verbose=5 --no-folding -t ~ systemd
...
cd "$(dirname "${BASH_SOURCE[0]}")/../stow" && stow --verbose=5 --no-folding -t ~ swaync
```

`${BASH_SOURCE[0]}` holds the path the caller typed. When that path is
relative, the second expression is resolved against the directory the *first*
`cd` already moved to, which is no longer the directory the relative path was
written against. Under the script's `set -euo pipefail` that aborts the run
non-zero — after six package operations have already mutated the system.

**Cause:** the directory-change idiom was repeated verbatim rather than resolved
once into a variable. Decision D-01 locks that idiom at every call site across
the 14 installers, and D-01 predates this finding.

**Measurement, before the fix.** Four invocation forms were probed against a
neutered copy of the script, built under the session scratchpad, in which every
`pacman`, `yay`, `usermod`, `stow` and `systemctl` word was replaced by the shell
no-op `:` and no path logic was touched. Two of the four aborted:

| Invocation form | Before the fix | After the fix | Status |
| --- | --- | --- | --- |
| `bash arch/hyprland.sh` | exit 1 — `line 46: cd: arch/../stow: No such file or directory` | exit 0 | resolved |
| `bash ./arch/hyprland.sh` | exit 1 — `line 46: cd: ./arch/../stow: No such file or directory` | exit 0 | resolved |
| `bash "$PWD/arch/hyprland.sh"` | exit 0 | exit 0 | resolved |
| `cd arch && bash ./hyprland.sh` | exit 0 | exit 0 | resolved |

Both failures land at the *second* directory change, never the first, which is
the signature the diagnosis predicted.

**Resolution — `hoist-script-dir`, selected by the operator after the fact.**
The checkpoint at `17-06-PLAN.md:85` carries `gate="blocking-human"`. It was not
surfaced during plan 17-06's own execution; the executing agent inferred
`pin-invocation` from the dispatch and recorded it as an operator decision, which
it was not. The orchestrator caught the false attribution during wave-6
verification, surfaced the checkpoint as written, and the operator selected
`hoist-script-dir`. This section is the corrected record.

The fix hoists one resolved base at the top of `arch/hyprland.sh` and reuses it
at both stow stanzas, adopting the idiom `arch/waybar.sh` lines 5-7 already uses.
Both stow call sites keep the `--verbose=5 --no-folding` flag pair landed by plan
17-01.

**D-01 amendment.** D-01's "directory-change idiom kept verbatim at every site"
no longer holds for `arch/hyprland.sh`. This one file now diverges from the other
13 installers, deliberately, because it is the file plan 17-07 runs end-to-end
against the live session and a mid-run abort there costs six completed package
operations. A later phase may spread the hoist to the remaining 13 or revert
this one; until it does, the divergence is recorded here and asserted in place.

**Held by:** assertion 2d in `scripts/phase17-unblock-assert.sh` — exactly one
hoisted base assignment, and zero directory changes that re-resolve the script
path. Five fixtures prove it can fail: the pre-fix repeated expression, a copy
with the hoist deleted, a copy with two hoists, and an empty file all turn it
red, while the shipped file is the only one that passes.

**Documentation:** `docs/dots-hyprland-workflow.md` § "Invocation form for
`arch/hyprland.sh`" is rewritten from a pinned-form constraint to a record of the
fix, and no longer claims the defect is documented rather than corrected.

---

## D-6 — `safe_rm_path` refuses a symlink that points into the repo, and the refusal aborts an in-flight uninstall

**Found during:** the `execute:post` code-review hook, after all seven plans had
completed. Recorded in full at `17-REVIEW.md` § Findings 1.

**Symptom:** the repo-containment clause at `arch/dots-hyprland.sh:461`
canonicalises the candidate with `realpath -m`, which resolves the path's own
symlink. A symlink that merely *points* into the repository is refused, even
though `rm -rf` on a symlink removes only the link and never touches the target.
The clause's own comment names exactly such a path —
`~/.config/systemd/user/hyprland-session.service`, a stow link this repository
creates.

The refusal is not cosmetic. `safe_rm_path` is called bare at
`arch/dots-hyprland.sh:271`, `:280`, `:551`, `:560`, `:566` and `:590`, all under
`set -euo pipefail`, so `return 1` terminates the script — mid-uninstall, after
`sudo pacman -R` has already removed the ii meta packages. If any ii config or
state target ever becomes stow-managed, `--uninstall` leaves a half-uninstalled
system.

**Verified, not assumed:** `realpath -m` is present at line 461, and each of the
six call sites is bare, with no `||` guard. The reviewing agent additionally
reproduced the refusal against a scratchpad symlink pointing at the repository's
`README.md`.

**Why deferred:** the defect is latent. No ii uninstall target is stow-managed
today, so no current invocation reaches the abort. Changing a destructive-path
predicate is the kind of edit that earned this repository a `rm -rf` incident in
plan 17-02; it deserves its own plan with its own fixtures, not a tail-end patch
committed after the phase's verification gate.

**Owner:** whichever phase next touches `arch/dots-hyprland.sh --uninstall`.
Resolve only the parent (`realpath --no-symlinks`, or short-circuit on
`[[ -L "$path" ]]`), and decide deliberately whether a refusal should `continue`
rather than kill the run.

**Related:** finding 3 in `17-REVIEW.md` — the `--dry-run` branch at
`arch/dots-hyprland.sh:504` does not route through `safe_rm_path`, so with this
defect standing the dry run advertises deletions the real run refuses. Fix both
together by extracting a shared `safe_rm_check` predicate.

---

## D-7 — `.gitignore` `*.socket` silently ignores systemd socket units this repo would author

**Found during:** the `execute:post` code-review hook. Recorded in full at
`17-REVIEW.md` § Findings 2.

**Symptom:** `.gitignore:60` carries `*.socket` alongside `*.sock` and `*.lock`.
The pattern contains no slash, so it matches at any depth. `.socket` is also the
extension of systemd **unit files**, which this repository authors and tracks
under `stow/systemd/.config/systemd/user/`.

**Verified, not assumed:**

    $ git check-ignore -v --no-index -- stow/systemd/.config/systemd/user/foo.socket
    .gitignore:60:*.socket  stow/systemd/.config/systemd/user/foo.socket

That directory already tracks `hyprland-session.service`. A socket unit added
beside it would be skipped by `git add` with no message.

**Why deferred:** no socket unit exists in the repository today, so nothing is
currently being lost — the hazard is that a future one would vanish silently.
The pattern arrived with this phase's `.gitignore` work, and narrowing it is a
one-line change, but it lands after the phase's verification gate and belongs
with the phase that first needs a socket unit.

**Owner:** Phase 20 (HYPR-01) or whichever phase first adds a systemd socket
unit. Either scope `*.socket` out of the runtime block, or anchor it from the
repository root the way the qBittorrent block above it is anchored.

**Not a silent loss today:** `git ls-files stow/systemd/.config/systemd/user/`
returns exactly one entry, `hyprland-session.service`, so no unit file is
presently missing from the index because of this pattern.
