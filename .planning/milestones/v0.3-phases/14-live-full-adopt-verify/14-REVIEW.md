---
phase: 14-live-full-adopt-verify
reviewed: 2026-09-05T00:00:00Z
depth: standard
reviewer: gsd-code-reviewer (adversarial)
files_reviewed: 12
files_reviewed_list:
  - scripts/phase14-preflight.sh
  - scripts/phase14-verify.sh
  - scripts/phase13-d19-assert.sh
  - docs/phase14-adopt-runbook.md
  - .planning/phases/14-live-full-adopt-verify/14-LIVE-VERIFY.md
  - .planning/phases/14-live-full-adopt-verify/14-PRE-ADOPT-BASELINE.txt
  - .config/hypr/hyprland.conf
  - .config/hypr/hyprland.conf.bak
  - .config/hypr/hyprland-gui.conf
  - arch/dots-hyprland.sh
  - .gitignore
  - stow/zsh/.config/starship.toml
findings:
  critical: 2
  warning: 13
  info: 12
  total: 27
status: pass
status_history:
  - fail   # as reviewed; CR-01 and CR-02 open
  - pass   # after 15b0c31 closed both Criticals
remediated_in: 15b0c31
---

# Phase 14: Code Review Report

**Reviewed:** 2026-09-05
**Depth:** standard (bash-specific: quoting, `set -euo pipefail` interactions, exit-status vs output conflation, mktemp/trap hygiene, `$HOME` race safety)
**Files Reviewed:** 12
**Status:** issues_found (2 Critical)

## Summary

Two shell scripts carry the phase: `scripts/phase14-preflight.sh` (13 KB, pre-adopt go-conditions) and `scripts/phase14-verify.sh` (28 KB, post-adopt verifier). Both are well above the average quality of scripts in this class — the liveness-before-interpretation pattern, the `hypr_json` payload gate, the expected-token `hyprctl eval` assertion, and the symmetric treatment of unobservability (never a pass, never a specific defect) are genuinely good and I could not break them.

**All four binding safety invariants hold in the code as written.** I ran both scripts (read-only forms), traced the control flow by hand, and verified the wrapper's `--dry-run` branches. Details in "Verified invariants" below.

What I found instead sits one layer out from the scripts: the **rollback procedure the scripts exist to prove** has a correctness gap the verifier cannot see, and the **phase record asserts one hash-verification the verifier never performs**. The second of these is the same defect shape as commit `9cb41c5` — relocated from the script into the record.

The 13 warnings are mostly gate-weakening: assertions that pass vacuously, greps that match more than intended, and one guarantee that is a property of a markdown file rather than of code.

---

## Critical Issues

### CR-01: Rollback tier 1 leaves `hyprland.lua` in place — per the repo's own research the Lua entry then still wins, making the documented restore a probable no-op

**File:** `docs/phase14-adopt-runbook.md:308-324`

**Issue.** Tier 1 restores `~/.config/hypr/hyprland.conf` from any of three sources and then says "Then log in again with `start-hyprland`." It never removes, renames, or even mentions `~/.config/hypr/hyprland.lua`, which the adopt installed and which is present on disk right now (`phase14-verify.sh:145` passes on it). The restored state is therefore *both files present* — the exact precedence case this repo says it cannot resolve.

The repo's own artifacts make this provable, not speculative:

- `14-RESEARCH.md:755` quotes the official Hyprland wiki: *"If you don't have a `hyprland.lua` config file, your old `hyprland.conf` will be loaded, but if you do have one, `hyprland.lua` will be loaded instead."* Under that reading, tier 1 step 1 changes nothing.
- `14-RESEARCH.md:756` states plainly that which behaviour is true on 0.56.2 "is not resolvable here."
- `14-RESEARCH.md:757` concludes "it does not matter operationally" — but that conclusion is scoped to the **forward** adopt direction only ("upstream renames the conf either way"). It does not transfer to the reverse direction, and nothing in the runbook notices that.
- `scripts/phase14-verify.sh:151-158` encodes the same uncertainty in the opposite direction: it asserts `hyprland.conf` **absent** specifically because that is "correct under either reading of the 0.56.2 format preference." The verifier is careful about precedence; the rollback is not.

**Concrete failure scenario.** Section 11 produces no usable desktop. The operator, at a bare TTY with no browser and reading `~/phase14-rollback.txt`, runs:

```bash
mv ~/.config/hypr/hyprland.conf.old ~/.config/hypr/hyprland.conf
start-hyprland
```

`hyprland.lua` is still at `~/.config/hypr/hyprland.lua`. Under the wiki's stated precedence the compositor loads the Lua entry and the operator gets the identical broken ii session. Step 1 is labelled "Almost always enough," so the natural reading is "tier 1 failed" — and the operator escalates to tier 2 and tier 3, which remove packages and re-mark package explicitness. **Neither tier 2 nor tier 3 touches config-file precedence**, so no amount of escalation reaches the actual cause. This is the failure mode the whole three-tier structure exists to prevent.

**Fix.** Make tier 1 disable the Lua entry first, and say why:

```bash
### Tier 1 — restore the config

# 0. Disable the Lua entry FIRST. If both files exist the Hyprland wiki says
#    hyprland.lua wins, so restoring the .conf alone may change nothing.
#    This is a rename, not a delete — the ii entry is recoverable.
mv ~/.config/hypr/hyprland.lua ~/.config/hypr/hyprland.lua.ii-disabled

# 1. The rename upstream made in section 7. Almost always enough.
cp -a ~/.config/hypr/hyprland.conf.old ~/.config/hypr/hyprland.conf
```

Also add a matching line to `14-LIVE-VERIFY.md` § Rollback inputs: what was proven is that the **inputs** exist, not that tier 1 as written produces a pre-adopt session.

---

### CR-02: The record claims a sha256 match for two rollback sources the verifier never hashes

**Files:**
- `scripts/phase14-verify.sh:348-357` (the assertions)
- `.planning/phases/14-live-full-adopt-verify/14-LIVE-VERIFY.md:135-141` (the claim)
- `.planning/phases/14-live-full-adopt-verify/14-02-SUMMARY.md` `provides:` block and § Accomplishments (the claim, again)

**Issue.** The verifier's ADOPT-04 block tests tier-1 sources 1 and 2 with `[[ -s ... ]]` only:

```bash
348  if [[ -s "$XDG/hypr/hyprland.conf.old" ]]; then
349    pass "ADOPT-04 tier-1 source 1 present and non-empty: ..."
353  if [[ -s "$REPO_HYPRCONF" ]]; then
354    pass "ADOPT-04 tier-1 source 2 present and non-empty: repo ..."
```

No `sha256sum`. No byte count. Only source 3 gets hashed, and only incidentally, in the separate D-36 block at `verify.sh:392-397`.

The record states something much stronger. `14-LIVE-VERIFY.md:135`: *"Three sources, all carrying the identical sha256 `3d17932a…89b5` at 15301 bytes, matching the fixture recorded before any mutation"* — followed by a table whose State column reads **"Present, non-empty, sha matches"** for source 1 and source 2. `14-02-SUMMARY.md` promises, under `provides:`, *"Proof that all three tier-1 rollback sources carry the identical pre-adopt sha256."*

That proof does not exist. Two of the three "sha matches" cells are unsourced. This is the identical defect class as Finding 3 in the record (`9cb41c5`: a `[PASS]` for a condition not observed) — moved out of the script and into the document that the phase's requirement sign-off rests on. ADOPT-04 is marked `requirements-completed` on this basis.

**Verification I performed.** I hashed all three by hand. The claim is **currently true**:

```
3d17932a6d2dd1b61ccc509402a70c224409bb5c24c4ed70a3c55d4f4bcd89b5  .config/hypr/hyprland.conf
3d17932a6d2dd1b61ccc509402a70c224409bb5c24c4ed70a3c55d4f4bcd89b5  /home/pera/.config/hypr/hyprland.conf.old
3d17932a6d2dd1b61ccc509402a70c224409bb5c24c4ed70a3c55d4f4bcd89b5  /home/pera/ii-original-dots-backup/.config/hypr/hyprland.conf
```

Nothing on disk is wrong today. The defect is that **the instrument would keep printing the same two `[PASS]` lines after either source drifted**, and the record would keep asserting a hash match that nothing checked. WR-02 below documents a live, already-wired mechanism by which source 2 drifts.

**Fix.** Hash both, against the fixture key that already exists:

```bash
HYPRLAND_CONF_SHA_PRE="$(baseline_value hyprland_conf_sha256)" || exit 1   # move above this block

check_tier1_source() {
  local label="$1" path="$2"
  if [[ ! -s "$path" ]]; then
    fail "ADOPT-04 $label missing or empty: $path"; return 0
  fi
  local got; got="$(sha256sum "$path" | cut -d' ' -f1)"
  if [[ "$got" == "$HYPRLAND_CONF_SHA_PRE" ]]; then
    pass "ADOPT-04 $label sha256 matches the pre-adopt fixture ($got): $path"
  else
    fail "ADOPT-04 $label is $got, fixture recorded $HYPRLAND_CONF_SHA_PRE — not the pre-adopt conf: $path"
  fi
}
check_tier1_source "tier-1 source 1" "$XDG/hypr/hyprland.conf.old"
check_tier1_source "tier-1 source 2 (repo)" "$REPO_HYPRCONF"
```

Then correct the two "sha matches" cells in `14-LIVE-VERIFY.md:139-140` or re-run and quote the real output.

---

## Warnings

### WR-01: Tier-1 step 1 uses `mv`, consuming the very source it restores from

**File:** `docs/phase14-adopt-runbook.md:314`

```bash
mv ~/.config/hypr/hyprland.conf.old ~/.config/hypr/hyprland.conf
```

**Issue.** `mv` destroys tier-1 source 1. After this line, `~/.config/hypr/hyprland.conf.old` no longer exists. If a later step in the recovery clobbers `~/.config/hypr/hyprland.conf` (the very next documented step, line 317, is an unconditional `cp -a` over that same path), or if the operator wants to re-attempt cleanly, source 1 is gone. The runbook's own framing at line 310 — "Three independent sources" — stops being true the moment step 1 runs.

Independently: `mv` here silently overwrites `~/.config/hypr/hyprland.conf` if it exists. Post-adopt it does not, but during a partial or re-attempted recovery it will.

**Fix.** `cp -a ~/.config/hypr/hyprland.conf.old ~/.config/hypr/hyprland.conf`. There is no reason to consume the source; `.old` costs 15 KB.

---

### WR-02: The repo's `.config/hypr/hyprland.conf` is simultaneously an immutable evidence archive and a live write target of the wrapper

**Files:** `.config/hypr/hyprland.conf` (roles), `docs/phase14-adopt-runbook.md:329-331` (tier 2), `scripts/phase14-verify.sh:353-357` + `:387` (the dependency), `arch/dots-hyprland.sh:692-712,747-782,789-829,1236-1237` (the mechanism)

**Issue.** That one file has three incompatible roles:

1. Rollback tier-1 source 2 (`runbook:317`, `verify.sh:353`).
2. The immutable pre-adopt evidence whose sha256 `3d17932a…` is frozen in `14-PRE-ADOPT-BASELINE.txt:7` and asserted by D-36.
3. **A live hook-injection target of the wrapper.** `list_hypr_ii_hook_target_files` and `list_any_hypr_ii_hook_files` (`arch/dots-hyprland.sh:669-712`) both scan `${REPO_ROOT}/.config/hypr` for `*.conf`, and the archive currently carries the hooks at lines 67 and 111 (`exec-once = qs -c ii`, `env = ILLOGICAL_IMPULSE_VIRTUAL_ENV,…`).

I confirmed role 3 by running the permitted gate-fed dry-run. Its last three lines are:

```
[CONFIG] dry-run: after setup, would enable ii hooks in live + repo hyprland.conf
[CONFIG] dry-run: ii hooks already active (no change):
[CONFIG] dry-run:   /home/pera/github_repo/.dotfiles/.config/hypr/hyprland.conf
```

**Concrete failure scenario.** The operator follows the runbook's rollback in order. Tier 1 does not recover the desktop (see CR-01). They run tier 2 as printed at line 329:

```bash
./arch/dots-hyprland.sh uninstall --configs-only
```

`run_safe_uninstall` reaches `disable_hypr_ii_hooks 0` at line 1236-1237 — reached for **any** uninstall mode, `--configs-only` included, unless `--keep-hypr-hooks` is passed, which the runbook does not mention. That function rewrites every matching file in place (`arch/dots-hyprland.sh:776-779`), deleting those two lines from the repo archive. Result: the working tree goes dirty mid-recovery with no explanation, the archive's sha256 no longer equals `hyprland_conf_sha256`, and every future D-36 / ADOPT-04 re-run is unreproducible. Because of CR-02, `phase14-verify.sh` would still print `[PASS] ADOPT-04 tier-1 source 2 present and non-empty`.

**Not classified Critical** because the content is in git history and is therefore recoverable, and because stripping ii hooks from a rolled-back conf is arguably the desired end state. The defect is that it happens silently, during recovery, to a file three other things treat as frozen.

**Fix.** Either (a) add `--keep-hypr-hooks` to the tier-2 commands in `runbook:329-331` with a one-line reason, or (b) move the pre-adopt evidence copy out of the wrapper's scan path — e.g. `.planning/phases/14-live-full-adopt-verify/hyprland.conf.pre-adopt` — and point `REPO_HYPRCONF` and `runbook:317` at it. (b) is the real fix; the evidence archive should not live where a `find -name '*.conf'` can reach it.

---

### WR-03: The preflight's clean-tree excusal is an unanchored substring match and silently excuses `.orig` / `.bak` siblings

**File:** `scripts/phase14-preflight.sh:194-212`

```bash
202  for artifact in "${PHASE14_ARTIFACTS[@]}"; do
203    hit="$(printf '%s\n' "$PORCELAIN" | grep -F -- " $artifact" || true)"
206      PORCELAIN="$(printf '%s\n' "$PORCELAIN" | grep -F -v -- " $artifact" || true)"
```

**Issue.** `grep -F` matches anywhere in the line, unanchored at both ends. Any porcelain entry whose path *contains* an excused path as a substring is dropped from the gate.

**Demonstrated, not theorised.** I ran the exact loop against a synthetic porcelain:

```
input:  ?? .planning/phases/14-live-full-adopt-verify/14-LIVE-VERIFY.md.orig
         M scripts/phase14-verify.sh.bak
         M arch/dots-hyprland.sh
result:  M arch/dots-hyprland.sh          <- the first two were silently excused
```

Both should have been hard `[FAIL]`s. `.orig` and `.rej` files are exactly what a merge conflict leaves behind, and this gate is D-15/D-35 — the condition that guarantees the runbook on GitHub is the runbook the operator is following.

Note `scripts/phase14-verify.sh:526-536` gets this right, matching a prefix via `case`. The two implementations of the same gate disagree.

**Fix.** Match whole lines against the exact porcelain form rather than a substring:

```bash
PORCELAIN="$(printf '%s\n' "$PORCELAIN" | grep -vE "^(\?\?|.[MADRCU ]) ${artifact//./\\.}$" || true)"
```

or, simpler and consistent with the verify script, parse `${line:3}` and compare with `[[ "$entry_path" == "$artifact" ]]`.

---

### WR-04: `--rotate-backup` runs even when the preflight declared no-go

**File:** `scripts/phase14-preflight.sh:297-307`

```bash
297  echo "=== done: FAIL=${FAIL} FINDINGS=${FINDINGS} ==="
299  # Rotation runs only when the flag was given, and only after every check above.
300  if [[ "$ROTATE" -eq 1 ]]; then
301    echo "=== --rotate-backup: the one mutating step in this script ==="
302    rotate_backup
303  fi
305  if [[ "$FAIL" -gt 0 ]]; then exit 1; fi
```

**Issue.** The guard is `ROTATE -eq 1` and nothing else. `FAIL` is computed, printed, and then ignored until *after* the mutation. The `--help` text (`:56-62`) says rotation "Runs every check first" — true, but it does not say the checks are advisory.

**Concrete failure scenario.** Operator is at runbook section 5. The preflight run in section 3 was green, but between then and now something changed — the vendor submodule got dirty, `installed_true` vanished, `origin/main` fell behind (I reproduced this last state: the current tree exits 1 on exactly that). They run `--rotate-backup`. It prints a wall of `[FAIL]` lines, then rotates `~/ii-original-dots-backup` anyway, then exits 1. `$HOME` has now been mutated in service of a window the same run just said not to open.

Note the `installed_true` branch (`:121-130`) *does* short-circuit with `exit 1` before rotation is reachable — so the author clearly intended failed hard conditions to block. That intent is not applied to the other eight check groups.

**Fix.**

```bash
if [[ "$ROTATE" -eq 1 ]]; then
  if [[ "$FAIL" -gt 0 ]]; then
    echo "[FAIL] refusing to rotate: ${FAIL} hard condition(s) failed above." >&2
    echo "       Fix them and re-run. Rotation mutates \$HOME and belongs only in a go window." >&2
    exit 1
  fi
  echo "=== --rotate-backup: the one mutating step in this script ==="
  rotate_backup
fi
```

---

### WR-05: The preflight's non-mutating guarantee is a property of a markdown file, not of the code

**Files:** `scripts/phase14-preflight.sh:181-186` → `scripts/phase13-d19-assert.sh:27-53`

`phase13-d19-assert.sh` extracts the first ` ```bash ` fence appearing after the `## In-repo verify (D-19)` heading in `13-SOT-APPLY.md`, writes it to a temp file, and executes it:

```bash
45    TMP="$(mktemp /tmp/p13-d19-XXXXXX.sh)"
46    printf '%s' "$FENCE" >"$TMP"
47    if bash -e "$TMP"; then
```

The preflight calls that script at line 181, on the default path, inside a script whose header (`:17-20`) promises "The default path (no arguments) performs no mv/rm/cp/rsync under `$HOME`."

**Issue.** That promise is not enforced by `phase14-preflight.sh` at all. It is a property of whatever `13-SOT-APPLY.md` happens to contain. **I read the current fence and it is clean** — 18 lines of `test`, `grep -q` and negations, no writes. So there is no live defect. But:

- the *same document* contains an apply fence with `cp -a` in it (asserted at `phase13-d19-assert.sh:86`), so a mutating fence lives two headings away from the extracted one;
- the extractor takes the **first** bash fence after the heading (`:35-36`), so inserting any fence between the heading and the verify fence silently changes what the preflight executes;
- an editor moving or renaming that heading turns the mutation guarantee off with no signal.

**Fix.** At minimum, refuse to execute a fence that contains a write verb, before running it:

```bash
if grep -nEq '(^|[[:space:];|&])(cp|mv|rm|rsync|install|ln|tee|truncate|dd|chmod|chown)([[:space:]]|$)|>[^&]' <<<"$FENCE"; then
  fail "D-19 fence contains a write verb; refusing to execute (this assert is non-mutating by contract)"
else
  ... existing bash -e ...
fi
```

Better still: stop executing prose. Keep the checks in the script and assert that the document's fence is byte-identical to them.

---

### WR-06: `pgrep` exit status is collapsed to a binary, so a `pgrep` failure reads as a `[PASS]`

**File:** `scripts/phase14-verify.sh:319-328`

```bash
319  if pgrep -x waybar >/dev/null 2>&1; then
320    fail "ADOPT-03 waybar still running — ..."
321  else
322    pass "ADOPT-03 waybar not running (Waybar/rofi/swaync accept-remove)"
```

**Issue.** `pgrep` exits 0 (matched), **1** (no match), **2** (syntax error) and **3** (fatal error) — plus 127 if procps-ng is absent from `PATH`. The script routes 1, 2, 3 and 127 all to the same `else`, which prints a `[PASS]` asserting a positive fact about the world. An error becomes evidence of absence.

This is the same shape as the defect fixed in `9cb41c5` — an unobserved condition scored as a pass — one severity band down, because `pgrep` exit 1 *is* a genuine negative signal and the failure modes are unlikely on this machine. It is called out because the phase's own binding rule says "anywhere a command's output is pattern-matched without its exit status being asserted, or where an empty/absent result is interpreted as a negative observation rather than as 'not observed'." This is the second clause, verbatim.

Note `:314` (the `qs -c ii` probe) has the opposite polarity and therefore fails closed. Only the two negative assertions at `:319` and `:324` fail open. The same conflation is present in the `[INFO]`-only probes at `:488`, `:494` and `:501`, where it matters less.

**Fix.**

```bash
proc_absent() {  # 0 = confirmed absent, 1 = confirmed present, 2 = could not observe
  pgrep -x "$1" >/dev/null 2>&1 && return 1
  (($? == 1)) && return 0
  return 2
}
case "$(proc_absent waybar; echo $?)" in
  0) pass "ADOPT-03 waybar not running (Waybar/rofi/swaync accept-remove)" ;;
  1) fail "ADOPT-03 waybar still running — dual-run policy is accept-remove" ;;
  *) fail "ADOPT-03 waybar presence NOT OBSERVED — pgrep did not answer (exit >=2). Not a pass." ;;
esac
```

---

### WR-07: The HDMI-A-2 geometry check compares against hardcoded constants while the fixture keys added for exactly that purpose sit unused

**File:** `scripts/phase14-verify.sh:216-225,260-269`; `.planning/phases/14-live-full-adopt-verify/14-PRE-ADOPT-BASELINE.txt:30-32`

```bash
216  HDMI_A2_SCALE_DECLARED="1.5"
217  HDMI_A2_TRANSFORM_DECLARED="1"
219  if [[ -f "$OVERLAY_GENERAL" ]] \
220    && grep -q "scale = ${HDMI_A2_SCALE_DECLARED}" "$OVERLAY_GENERAL" \
221    && grep -q "transform = ${HDMI_A2_TRANSFORM_DECLARED}" "$OVERLAY_GENERAL"; then
```

Three issues, in ascending order of consequence:

1. **The drift guard cannot detect the drift it exists for.** `grep -q "transform = 1"` is an unanchored substring BRE. `transform = 10` matches. `transform = 123` matches. `scale = 1.5` matches `scale = 1.55`. The `.` in `1.5` is also an unescaped any-char metacharacter, so `scale = 175` matches. If `general.lua` drifted to any of those, the guard prints `[PASS] ADOPT-03 overlay source declares HDMI-A-2 scale=1.5 transform=1` while the constants below are exactly as stale as the guard was written to prevent.
2. **Neither grep is scoped to the HDMI-A-2 block.** `general.lua` has two `hl.monitor` tables (lines 3-15). A `transform = 1` appearing on the DP-1 monitor would satisfy the guard.
3. **The fixture already carries these values and they are ignored.** `14-PRE-ADOPT-BASELINE.txt:30-32` records `hdmi_a2_scale_pre=1.5` and `hdmi_a2_transform_pre=1`. `14-01-SUMMARY.md` deviation 3 justifies adding those three keys specifically as *"direct ADOPT-03 dual-head inputs — without them the drift above leaves 14-02 with no comparison basis for the second head."* 14-02 then hardcoded the values instead. The stated justification for the fixture keys is unfulfilled and the keys are dead.

Related: `verify.sh:253` explicitly tolerates float-format variance for DP-1 (`"$DP1_SCALE_LIVE" == "${DP1_SCALE_PRE}.0"`) while `:264` compares HDMI-A-2's scale with a bare `==`. A hyprctl output-format change turns one into a tolerated pass and the other into a spurious `[FINDING]`.

**Fix.** Read the declared values out of the overlay instead of asserting them, and use the fixture as the cross-check:

```bash
HDMI_A2_SCALE_DECLARED="$(awk '/output = "HDMI-A-2"/,/^\}/' "$OVERLAY_GENERAL" \
  | sed -n 's/.*scale[[:space:]]*=[[:space:]]*\([0-9.]*\).*/\1/p')"
HDMI_A2_SCALE_PRE="$(baseline_value hdmi_a2_scale_pre)" || exit 1
[[ "$HDMI_A2_SCALE_DECLARED" == "$HDMI_A2_SCALE_PRE" ]] \
  || finding "ADOPT-03 overlay declares scale $HDMI_A2_SCALE_DECLARED, fixture recorded $HDMI_A2_SCALE_PRE"
```

---

### WR-08: `phase13-d19-assert.sh` prints three `[PASS]` lines that cannot fail

**File:** `scripts/phase13-d19-assert.sh:119-125`

```bash
119  for f in keybinds.lua rules.lua variables.lua; do
120    if [ ! -f ".config/hypr/custom/$f" ] || ! cmp -s ".config/hypr/custom/$f" "$LIVE_CUSTOM/$f"; then
121      pass "live custom/$f left to upstream (not overwritten from repo)"
```

**Issue.** The repo's `.config/hypr/custom/` contains exactly three files — `env.lua`, `execs.lua`, `general.lua` (confirmed with `ls -la`). `keybinds.lua`, `rules.lua` and `variables.lua` do not exist there, so `[ ! -f ... ]` is unconditionally true and the loop emits three unconditional `[PASS]` lines. `26fecf2`'s commit message states these checks catch "a fence widened past the files D-18 names"; they cannot, because widening the fence requires repo copies that do not exist.

Second problem in the same condition: `! cmp -s` is also true when the **live** file is missing (cmp exits 2). "Left to upstream" and "absent from live entirely" are opposite facts and both score as a pass.

The check is not worthless — it would bite if someone added those files to the repo — but three unconditional passes are indistinguishable in the output from three real observations, which is precisely the discipline this phase spent a whole finding establishing.

**Fix.**

```bash
for f in keybinds.lua rules.lua variables.lua; do
  if [ ! -f ".config/hypr/custom/$f" ]; then
    printf '[INFO] custom/%s has no repo copy — nothing the fence could widen to\n' "$f"
  elif [ ! -f "$LIVE_CUSTOM/$f" ]; then
    fail "live custom/$f absent — expected upstream's seed"
  elif cmp -s ".config/hypr/custom/$f" "$LIVE_CUSTOM/$f"; then
    fail "live custom/$f matches the repo copy — the D-18 fence was widened"
  else
    pass "live custom/$f left to upstream (differs from the repo copy)"
  fi
done
```

---

### WR-09: `"arch/dots-hyprland.sh unmodified"` only checks the unstaged worktree diff

**File:** `scripts/phase13-d19-assert.sh:134-138`

```bash
134  if [ -z "$(git diff --name-only -- arch/dots-hyprland.sh)" ]; then
135    pass "arch/dots-hyprland.sh unmodified"
```

**Issue.** `git diff` with no revision compares the worktree to the **index**. It sees neither staged changes nor committed ones. The assertion's label claims a property ("unmodified") far broader than what it tests ("not dirty in the worktree right now").

This is materially wrong today: `arch/dots-hyprland.sh` **was** modified during this phase by commit `14c6828` ("drop waybar and swaync from PROTECT_EXPLICIT (D-28)"), and this assert still prints `[PASS] arch/dots-hyprland.sh unmodified` on every run — including inside `phase14-preflight.sh:181`. Anyone reading the preflight output reasonably concludes the wrapper is untouched by Phase 14. It is not.

**Fix.** Either rename the assertion to what it measures, or measure the thing:

```bash
# what it currently means:
pass "arch/dots-hyprland.sh has no uncommitted worktree changes"

# or, if the intent is a pinned baseline:
WRAP_SHA_EXPECTED="…"   # recorded when the wrapper was last reviewed
[ "$(git hash-object arch/dots-hyprland.sh)" = "$WRAP_SHA_EXPECTED" ] \
  && pass "arch/dots-hyprland.sh matches the reviewed baseline" \
  || fail "arch/dots-hyprland.sh differs from the reviewed baseline"
```

---

### WR-10: The phase-aware mode switch keys on an artifact written hours after the event it stands for

**File:** `scripts/phase13-d19-assert.sh:96-108`

```bash
96   LIVE_VERIFY=".planning/phases/14-live-full-adopt-verify/14-LIVE-VERIFY.md"
97   if [ ! -f "$LIVE_VERIFY" ]; then
98     if [ ! -e "$LIVE_CUSTOM" ]; then
99       pass "live $LIVE_CUSTOM absent (apply not run)"
100    else
101      fail "live $LIVE_CUSTOM absent (apply not run)"
```

**Issue.** The proxy for "the Phase 14 overlay apply has happened" is the existence of `14-LIVE-VERIFY.md`. Those two events are causally unrelated and, per this phase's own record, occurred hours apart: the apply is runbook **section 8**, executed by the operator during the window; `14-LIVE-VERIFY.md` is written in plan 14-02 **Task 5**, committed in `8b8ba4b`, after the verify run.

**Concrete failure scenario.** Anywhere in that window — which includes runbook sections 8 through 12, i.e. the reboot, the first ii login, and the verify run — `./scripts/phase13-d19-assert.sh` reports `[FAIL] live ~/.config/hypr/custom absent (apply not run)` while `~/.config/hypr/custom` is present and correct. That is exactly the inverted-assertion failure `26fecf2` was written to fix; the fix moved the inversion rather than removing it. An operator running the assert after the apply (a natural thing to do) gets a red gate mid-window and no way to tell it is spurious.

Also note the branch labels are copy-paste inverted: line 101's `fail` message reads "live … absent (apply not run)" when the failure is that it is *present*.

**Fix.** Key on the observable state, not on a document:

```bash
if [ -d "$LIVE_CUSTOM" ]; then
  # post-apply: the three named files must match the repo source
  ...
else
  printf '[INFO] live %s absent — the phase 14 apply has not run yet\n' "$LIVE_CUSTOM"
fi
```

and fix line 101's message to describe the observed condition.

---

### WR-11: The read-only proof offered for `phase14-verify.sh` does not cover the one compositor-side execution call it makes

**File:** `.planning/phases/14-live-full-adopt-verify/14-LIVE-VERIFY.md:9`

> `grep -cE 'pkill|hyprctl reload|hyprctl keyword|rm -rf|rsync .*--delete'` over it is 0.

**Issue.** That blocklist is offered as the evidence for "The script is read-only against the live session." It omits `hyprctl eval`, `hyprctl dispatch`, `hyprctl --batch`, `hyprctl setprop` and `hyprctl output`. The script does in fact call one of them — `hyprctl eval 'return 1+1'` at `verify.sh:195` — which submits Lua to the compositor's config manager for evaluation. The expression is pure and the run was in fact non-mutating; the point is that **the stated proof does not establish that**, and it passes precisely because the omitted verb is the one the script uses.

A blocklist that is validated by a grep that omits the used verb is not evidence. Whoever re-runs that grep on a future revision will get `0` regardless of what was added to the `eval` payload.

**Fix.** Replace the blocklist with an allowlist over the actual call sites:

```bash
grep -nE '\bhyprctl\b' scripts/phase14-verify.sh
# every hit must be one of: `instances -j`, `-j status`, `-j monitors all`,
# `-j workspacerules`, or `eval 'return 1+1'` — no dispatch/keyword/reload/batch.
```

and state in the record that the `eval` payload is a pure expression, which is where the read-only property of that call actually lives.

---

### WR-12: The D-38 "four pinned autostarts" probe set does not match the four in the archived conf, and the unprobed one is asserted anyway

**Files:** `scripts/phase14-verify.sh:493-500`; `.config/hypr/hyprland.conf:96-99`; `docs/phase14-adopt-runbook.md:294`

The archived conf's four workspace-pinned `exec-once` lines are:

```
96  exec-once = [workspace 1] google-chrome-stable --profile-directory='Default' …
97  exec-once = [workspace 1] kitty -e tmux
98  exec-once = [workspace special:btop silent] kitty --class btop -e btop
99  exec-once = [workspace special:social silent] sh -c '… vesktop || exec discord'
```

The verifier probes `btop`, `vesktop`, `discord` (`:493`) — three names covering two slots — and then emits, with no probe at all:

```bash
500  info "D-38 known loss (workspace-pinned autostart) 'google-chrome-stable on workspace 1' — the archived conf's four pinned autostarts all went with the rename (expected)"
```

**Issue.** Two divergences:

- `kitty -e tmux` on workspace 1 is one of the four, is named in `runbook:294`, and is **never probed by anything**. The record's Known-losses table (`14-LIVE-VERIFY.md:158-165`) also omits it, so it is unaccounted for end to end.
- Line 500 is an unconditional string that asserts a conclusion about **all four** autostarts ("all went with the rename") on the strength of probes covering two of them. It is correctly tiered `[INFO]` rather than `[PASS]`, which is why this is a Warning and not Critical — but the sentence still states as observed something the run did not observe.

There is a good reason chrome is unprobed (`pgrep -x google-chrome-stable` would not match; the process name is `chrome`). That reason is not written down, so the line reads as an oversight rather than a decision.

**Fix.**

```bash
if pgrep -x chrome >/dev/null 2>&1; then
  info "D-38 known loss 'google-chrome-stable': a chrome process is running (may be a manual launch, not the pinned autostart)"
else
  info "D-38 known loss 'google-chrome-stable on workspace 1' CONFIRMED not running (probed as 'chrome' — the binary name is not the process name)"
fi
# and add the fourth slot:
if pgrep -f 'kitty -e tmux' >/dev/null 2>&1; then
  info "D-38 known loss 'kitty -e tmux on workspace 1': running"
else
  info "D-38 known loss 'kitty -e tmux on workspace 1' CONFIRMED not running (expected)"
fi
```

---

### WR-13: The D-05 dry-run assertion checks one of the four banned flags

**File:** `scripts/phase14-preflight.sh:285-295`

```bash
286  if grep -q 'would exec' "$FULL_OUT" && ! grep -q -- '--skip-hyprland' "$FULL_OUT"; then
287    pass "D-05 gate-fed install --full --dry-run prints would-exec, no --skip-hyprland"
```

**Issue.** `runbook:131-136` names four banned flags — `-f`/`--force`, `--skip-backup`, `-F`/`--firstrun`, `--skip-hyprland-entry` — and `:138` adds `yesforall`. The mechanical check covers only the last flag. Nothing asserts that the argv the wrapper is about to exec is free of `--force`, `--skip-backup` or `--firstrun`, and nothing asserts what the would-exec line actually *is*; `grep -q 'would exec'` passes on any line containing that phrase.

`--skip-backup` is refused bare by the wrapper's own gate, and the other two are not injected on the `--full` path today, so this is a coverage gap rather than a live hole. But this grep is the only mechanical guard standing between the go/no-go gate and a wrapper regression that leaks a banned flag, and it is the check the runbook points at.

**Fix.**

```bash
WOULD_EXEC="$(grep -m1 'would exec' "$FULL_OUT" || true)"
BANNED_RE='(--force|(^| )-f( |$)|--skip-backup|--firstrun|(^| )-F( |$)|--skip-hyprland|yesforall)'
if [[ -z "$WOULD_EXEC" ]]; then
  fail "D-05 gate-fed install --full --dry-run printed no would-exec line"
elif [[ "$WOULD_EXEC" =~ $BANNED_RE ]]; then
  fail "D-05 banned flag leaked into the would-exec argv: $WOULD_EXEC"
elif [[ "$WOULD_EXEC" != *"./setup install"* ]]; then
  fail "D-05 would-exec argv is not './setup install': $WOULD_EXEC"
else
  pass "D-05 gate-fed install --full --dry-run: $WOULD_EXEC — no banned flag"
fi
```

---

## Info

- **IN-01** `scripts/phase14-verify.sh:38` — `pass()` increments no counter, yet `14-02-SUMMARY.md` and `14-LIVE-VERIFY.md` quote exact pass counts ("38 `[PASS]`"). Those counts are hand-tallied and will silently drift; add a `PASSES` counter and print it in the `=== done: ===` line.
- **IN-02** `phase14-preflight.sh:108-110`, `phase14-verify.sh:341-342`, `phase13-d19-assert.sh:45` — `mktemp /tmp/…` hardcodes `/tmp` and ignores `$TMPDIR`. `mktemp` itself is safe (0600, `O_EXCL`), so this is portability, not a vulnerability. Use `mktemp -t` or bare `mktemp`.
- **IN-03** `14-PRE-ADOPT-BASELINE.txt` — 13 of its 23 keys are never read by any script: `hyprland_conf_bytes`, `hyprpaper_conf_sha256`, `submodule_pin`, `hyprland_version`, `dp1_mode_pre`, `dp1_transform_pre`, `hdmi_a2_present_pre`, `hdmi_a2_mode_pre`, `hdmi_a2_scale_pre`, `hdmi_a2_transform_pre`, `backup_dir_present_pre`, `backup_dir_hyprland_conf_sha256`, `graphical_session_target_pre`. Some are defensible as record-only; `hdmi_a2_scale_pre`/`_transform_pre` are not (see WR-07), and `backup_dir_hyprland_conf_sha256` would make a good negative assertion ("the backup is no longer the stale copy").
- **IN-04** `docs/phase14-adopt-runbook.md:73` — "nothing in this window writes to `$HOME` except the backup rotation in section 5 and upstream's own install" is contradicted four lines above by `cp docs/… ~/phase14-rollback.txt` (`:69`) and by section 9's `stow` (`:234`). Reword to "nothing writes under `~/.config` except…".
- **IN-05** `phase14-preflight.sh:174-175`, `phase13-d19-assert.sh:56` — `grep -c 'hl.monitor'` uses `.` as an unescaped any-char metacharacter, and `grep -c` counts matching **lines**, not occurrences: two `hl.workspace_rule` calls on one line would count as one. Use `grep -cF 'hl.workspace_rule('`, or `grep -o … | wc -l`.
- **IN-06** `docs/phase14-adopt-runbook.md:58` — `script <file>` truncates an existing file. A second adopt window, or a re-run after an aborted one, destroys the prior transcript with no warning. Suggest `script -a` plus a timestamped filename.
- **IN-07** `phase14-verify.sh:529` — `entry_path="${entry_path##* -> }"` keeps only a rename's destination, so a rename *out of* a tracked path *into* the phase directory is excused from the D-35 gate. Check both halves of an `R` entry.
- **IN-08** `phase14-preflight.sh:194-198` — the excusal list includes `scripts/phase14-verify.sh`, which is not under the phase directory. The gate therefore permits entering the adopt window with an uncommitted, unpushed verifier. Harmless for D-25 (the runbook is what must be readable remotely) but inconsistent with the comment at `:189-193` that describes the list as "this phase's own transcript and verify artifacts".
- **IN-09** Scope note: `arch/dots-hyprland.sh` is **not** vendored upstream code — the vendored tree is `vendor/dots-hyprland` (submodule, pinned `1a9ffb78`). `arch/dots-hyprland.sh` is a repo-authored 52 KB wrapper and it **was** modified in this phase by `14c6828` (the planned D-28 `PROTECT_EXPLICIT` edit). `git log --oneline -- arch/dots-hyprland.sh` shows no unplanned Phase 14 change. Recorded so the "unmodified vendored file" framing does not propagate.
- **IN-10** `phase14-verify.sh:100-102` — `hyprctl instances -j | … | head -1` takes an arbitrary instance when more than one compositor is live. Fail-closed (a wrong pick surfaces as `[FAIL]`s from `hypr_json`), but worth an `[INFO]` naming the instance count.
- **IN-11** `phase14-preflight.sh:246-251` — the backup `[FINDING]` always appends "Remediation: `--rotate-backup` (runbook section 5; mandatory before go)". Post-adopt that advice is stale and, if followed, would rotate away the very directory D-36 asserts against. Gate the remediation sentence on `[[ -f "$XDG/hypr/hyprland.conf" ]]` (i.e. pre-adopt).
- **IN-12** `phase14-verify.sh:516` — `$(stat -c '%s' "$REPO_LAUNCHER")` is interpolated into the message on the branch reached when `cmp -s` fails, which includes the case where `$REPO_LAUNCHER` does not exist. `stat` then writes to stderr and interpolates empty. The file is present today; guard it anyway.

---

## Verified invariants (checked, not assumed)

Recorded so these are not re-litigated. Each was confirmed by reading control flow and, where safe, by execution.

| Invariant | Verdict | How verified |
|---|---|---|
| Preflight mutates nothing under `$HOME` on the default path | **Holds** | Ran `./scripts/phase14-preflight.sh` (exit 1 on the unpushed-commit condition only). The sole `mv` is `phase14-preflight.sh:87`, inside `rotate_backup`, whose only call site is `:302` guarded by `[[ "$ROTATE" -eq 1 ]]` at `:300`; `ROTATE` is set only by `--rotate-backup` at `:96`. No `rm`/`rsync`/`cp` anywhere in the file. Temp files are `/tmp` only, cleaned by the `EXIT` trap at `:112`. Caveats: WR-04 (rotation not gated on `FAIL`) and WR-05 (the guarantee is transitively delegated to a markdown fence). |
| Verify does not mutate live session or config state | **Holds** | Ran `./scripts/phase14-verify.sh` (`FAIL=0 FINDINGS=1`, exit 0). No `pkill`, no `hyprctl reload`/`keyword`/`dispatch`, no `rm -rf`, no `rsync`, no redirection under `$XDG` or `$HOME`. The only environment write is `export HYPRLAND_INSTANCE_SIGNATURE` at `:106`, process-local. Temp files `/tmp` only, trap at `:344`. Caveat: WR-11 — the *proof offered in the record* is weaker than the property, which does hold. |
| No mutating `install --full` in scripts or runbook | **Holds** | The only `install --full` in a script is `phase14-preflight.sh:285`, gate-fed and `--dry-run`. `docs/phase14-adopt-runbook.md:181` and `:207` carry the bare form, but they are the operator's own step, explicitly framed at `:178`: "This is the real mutating run and it is **yours to type**. No agent runs it." That is the required content of an adopt runbook and is **not** a violation. |
| `uninstall --dry-run` / `protect --dry-run` are genuinely non-mutating | **Holds** | Read both branches. `run_safe_uninstall` returns at `arch/dots-hyprland.sh:1108-1153` (`exit 0`) before any `safe_rm_path`, `pacman -R`, `stop_running_qs 0` or `disable_hypr_ii_hooks 0`. `run_protect` at `:448-470` passes `dry_run` down to `protect_explicit_packages` (`:363-367`) and `install_missing_protect_packages` (`:404-409`); both return before their `sudo pacman` calls. |
| `~/ii-original-dots-backup` is never rotated, moved or modified outside `--rotate-backup` | **Holds** | One `mv` in the phase's scripts (`phase14-preflight.sh:87`), flag-guarded as above. `phase14-verify.sh` touches `$BACKUP_DIR` only via `[[ -d ]]`, `ls -A`, `sha256sum` and `stat` (`:358`, `:386-400`). `rotate_backup` refuses on a missing source (`:79-82`) and on an existing destination (`:83-86`); no `rm` on any path. |
| No remaining "output matched without exit status asserted" of the `9cb41c5` shape | **Mostly holds** | `hypr_json` (`:124-131`) gates all three JSON probes on `jq -e 'type'`, so a `Couldn't connect to …` string on stdout cannot be read as a payload. `hyprctl eval` asserts the exact token `ok` (`:197`). `busctl` (`:468-477`) routes a failure to `finding`, never to a pass. `systemctl is-active` (`:461`) routes a failure to `finding`. The residue is WR-06 (`pgrep`) and, at `[INFO]` tier, WR-12. |
| No secrets in the in-scope config files | **Holds** | `grep -nEi 'password\|secret\|api[_-]?key\|token\|bearer\|BEGIN .*PRIVATE KEY\|[A-Za-z0-9+/]{40,}='` over `.config/hypr/hyprland.conf`, `.conf.bak`, `hyprland-gui.conf` and `stow/zsh/.config/starship.toml` — no matches. |
| `arch/dots-hyprland.sh` unmodified relative to intent | **Holds** | `git log --oneline -- arch/dots-hyprland.sh` shows `14c6828` as the only Phase 14 commit, matching the planned D-28 `PROTECT_EXPLICIT` deletion. See IN-09 on the "vendored" framing. |

**Not re-reported** (already in the record): runbook §9's `stow -R kitty`; runbook §8's indented heredoc terminator; the `starship.toml` D-17 loss; `graphical-session.target` inactive (D-38); the backup directory's eight preserved symlinks.

**Also disproved and therefore not reported:** I initially suspected `set -e` would abort `phase14-preflight.sh:142-144` and `phase14-verify.sh:527` on their `[[ … ]] && cmd` lines. It does not — bash exempts a failing non-final command in an `&&` list. Confirmed by execution before discarding.

---

_Reviewed: 2026-09-05_
_Reviewer: Claude (gsd-code-reviewer), adversarial stance_
_Depth: standard_


---

## Remediation (orchestrator, commit `15b0c31`)

The findings below were closed after the review was written. The review text
above is preserved as reviewed — it is the record of what was found, not of what
is currently true.

| Finding | Disposition |
|---|---|
| CR-01 rollback tier 1 leaves `hyprland.lua` in place | **Fixed.** Tier 1 now moves `~/.config/hypr/hyprland.lua` aside as step 0, with the precedence ambiguity and the forward-only scope of RESEARCH's conclusion stated inline. |
| CR-02 sha match claimed for two sources never hashed | **Fixed.** `check_tier1_source` hashes sources 1 and 2 against the pre-adopt fixture. `HYPRLAND_CONF_SHA_PRE` hoisted to line 82 so it is defined before first use. Verified: all three sources hash `3d17932a…89b5`. |
| WR-01 tier 1 step 1 used `mv`, consuming source 1 | **Fixed.** `cp -a`. |
| WR-03 unanchored `grep -F` excusal | **Fixed.** Exact porcelain path match; `.orig` and `.bak` look-alikes no longer excused. |
| WR-06 `pgrep` collapsed exits 2/3/127 into PASS | **Fixed.** Only exit 1 means "checked, absent"; other exits record a finding. |
| WR-08 unconditional PASS on the D-18 fence check | **Fixed.** Asserts the observable property — the repo never grew a copy to widen the fence with. |
| WR-09 bare `git diff` blind to committed drift | **Fixed.** Baseline pinned per phase (`e7e4e9f` before phase 14, `14c6828` after, since D-28 deliberately moved the known-good state). |

The fix for WR-09 immediately surfaced the drift it was blind to (`14c6828`,
the deliberate D-28 change), confirming the check now works.

**Not actioned.** WR-02, WR-04, WR-05, WR-07, WR-10 through WR-13 and the 12
Info findings are recorded and left open. WR-02 in particular is a genuine
design tension — the repo's `.config/hypr/hyprland.conf` serves as rollback
source, frozen D-36 evidence, and live hook-injection target simultaneously —
but its content is in git history, so the exposure is bounded.

Post-remediation state, all re-run: `phase14-verify.sh` `FAIL=0 FINDINGS=1`;
`phase14-preflight.sh` `FAIL=0 FINDINGS=1`; regression suite (phases 10–13)
four of four green.
