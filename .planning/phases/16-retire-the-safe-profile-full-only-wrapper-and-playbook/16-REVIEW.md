---
phase: 16-retire-the-safe-profile-full-only-wrapper-and-playbook
reviewed: 2026-09-08T10:22:44Z
depth: standard
diff_range: 7334498..4e72e25
files_reviewed: 9
files_reviewed_list:
  - arch/dots-hyprland.sh
  - docs/dots-hyprland-workflow.md
  - docs/phase14-adopt-runbook.md
  - scripts/phase12-full-smoke.sh
  - scripts/phase13-d19-assert.sh
  - scripts/phase14-verify.sh
  - scripts/phase16-retire-assert.sh
  - scripts/phase07-live-smoke.sh (deleted)
  - scripts/phase14-preflight.sh (deleted)
findings:
  critical: 1
  high: 2
  medium: 8
  low: 8
  total: 19
status: issues_found
---

# Phase 16: Code Review Report

**Reviewed:** 2026-09-08T10:22:44Z
**Depth:** standard
**Diff range:** `7334498..4e72e25` (paths `arch/ docs/ scripts/` only)
**Files reviewed:** 9 (7 present, 2 deleted)
**Status:** issues_found

## Summary

Phase 16 removed roughly 1,700 lines of guard machinery from `arch/dots-hyprland.sh` (SAFE_DEFAULTS injection, the backup gate, the `protect` subcommand, the hypr ii-hook injection/removal) and rewrote two operator documents to a full-only story.

The wrapper deletion itself is clean. I found **no dead references** in the surviving wrapper — `grep` for `hook`, `protect`, `PROTECT`, `II_BACKUP`, `backup_gate`, `needs_safe_defaults`, `user_flags_contain`, `is_help_only`, `SAFE_DEFAULTS`, `allow_skip` returns nothing in `arch/dots-hyprland.sh`. All five changed/added shell scripts pass `bash -n`. The wrapper-drift pin `0771cc2` in `phase13-d19-assert.sh` is correct: `git diff --name-only 0771cc2 -- arch/dots-hyprland.sh` is empty.

What the phase did **not** do cleanly:

1. It flipped install from "upstream always backs up" to "upstream never backs up," with no way for an operator to opt back in (H-01). That is more than the absence of the retired safe profile — it is an active new argv injection that suppresses a snapshot upstream would otherwise take.
2. The wrapper's one surviving mutating path, `uninstall`, contains a `rm -rf` that silently defeats both `--keep-venv` and `--packages-only` and is invisible to `--dry-run` (C-01). This pre-dates the phase but survives inside the code Phase 16 re-certified as "the one wrapper-owned path (D-07)."
3. `docs/phase14-adopt-runbook.md` was only half swept. Sections 3, 5 and 14 were converted to past-tense records; sections 4, 7 and the header blockquote were not, and they now describe a backup gate, a `--skip-backup` refusal, a protect-list re-mark and an ii-hook enable that no longer exist. The file contradicts itself: line 138 says the wrapper refuses `--skip-backup`; line 165 says the wrapper passes it unconditionally (H-02).

**On the specific ugrep vacuity question:** `scripts/phase16-retire-assert.sh` uses no complex alternations. I re-checked every ban it makes with Python `re` against `docs/dots-hyprland-workflow.md` — `dual-run`, `safe profile|safe defaults`, `SAFE_DEFAULTS`, `--skip-hyprland`, `protect`, `--allow-skip-backup` all return zero matches. **The underlying bans genuinely hold; none of them passes vacuously today.** There is still a latent vacuity class in the same shape (M-04, M-05), documented below.

**`shellcheck` is not installed on this machine** (`command -v shellcheck` → empty), so no linter findings are included. See L-08.

## Critical

### C-01: `uninstall` unconditionally `rm -rf`s the quickshell state tree, defeating `--keep-venv` and `--packages-only`

**Severity:** critical / **BLOCKER**
**File:** `arch/dots-hyprland.sh:296-300` (callers at `:470` and `:516`)
**Also affects:** `arch/dots-hyprland.sh:357-358`, `arch/dots-hyprland.sh:368` (the gate text this contradicts)
**Note:** pre-dates Phase 16 (present at `7334498:arch/dots-hyprland.sh:646`), but survives unchanged inside the path this phase rewrote and re-certified as the single wrapper-owned removal path.

`stop_running_qs 0` ends with:

```bash
  # State dir may be recreated by the process between rm and kill; clean again.
  if [[ -d "${XDG_STATE_HOME}/quickshell" ]]; then
    echo "[UNINSTALL] Re-cleaning state recreated by live process: ${XDG_STATE_HOME}/quickshell"
    rm -rf -- "${XDG_STATE_HOME}/quickshell"
  fi
```

It is called unconditionally from `run_safe_uninstall` at line 470 (before packages are even touched) and again at line 516. It receives none of `packages_only`, `configs_only` or `keep_venv`. Three consequences:

- **`uninstall --keep-venv` destroys the venv.** The gate promises at line 358: `"State: will remove ${XDG_STATE_HOME}/quickshell contents except .venv (--keep-venv)"`. The careful `--keep-venv` loop at lines 492-502 does skip `.venv` — and is then overwritten by the blanket `rm -rf` at line 299. This fires whenever a `qs`/`quickshell` process was running, which is the normal case (stopping it is the whole reason the function is called).
- **`uninstall --packages-only` destroys configs/state.** The gate prints `"[UNINSTALL] Configs/state: skipped (--packages-only)"` (line 368) and every other removal is correctly wrapped in `if ((packages_only == 0))`. This one is not.
- **`--dry-run` never shows it.** `stop_running_qs 1` returns at line 269, before the `rm`. So the preview under-reports the real plan — an operator who dry-runs `--keep-venv` sees a plan that preserves `.venv` and then loses it.

Note the guard asymmetry: every other removal in this file routes through `safe_rm_path` (`:386-408`), which refuses paths outside `$HOME` and refuses hypr paths. This `rm -rf` bypasses it.

**Fix:** thread the flags through and reuse `safe_rm_path`.

```bash
# signature: stop_running_qs <dry_run> <packages_only> <keep_venv>
stop_running_qs() {
  local dry_run="${1:-0}" packages_only="${2:-0}" keep_venv="${3:-0}"
  ...
  # State dir may be recreated by the process between rm and kill; clean again,
  # but only within the scope the caller's flags allow.
  local st="${XDG_STATE_HOME}/quickshell"
  if ((packages_only == 0)) && [[ -d "$st" ]]; then
    if ((keep_venv == 1)); then
      local child
      shopt -s nullglob dotglob
      for child in "$st"/*; do
        [[ "$(basename "$child")" == ".venv" ]] && continue
        safe_rm_path "$child"
      done
      shopt -u nullglob dotglob
    else
      safe_rm_path "$st"
    fi
  fi
}
```

Update the three call sites (`:462` dry, `:470`, `:516`) to pass `"$packages_only" "$keep_venv"`, and have the dry-run branch print the same plan it would execute.

**Should an existing suite have caught this?** Yes. `scripts/phase12-full-smoke.sh` and `scripts/phase16-retire-assert.sh` are both explicitly non-mutating and only probe the install argv; nothing in the repo asserts the uninstall flag contract at all. `phase14-verify.sh:373` only asserts `uninstall --dry-run` exits 0. A dry-run-level assert that `--keep-venv`'s plan mentions `.venv` preservation and that `--packages-only`'s plan mentions no state path would have caught the contradiction between the gate text and the code.

## High

### H-01: The wrapper now injects `--skip-backup` on every `install`/`install-files` with no opt-out, disabling upstream's only snapshot

**Severity:** high / **BLOCKER**
**File:** `arch/dots-hyprland.sh:691-694` (predicate at `:655-660`)
**Upstream effect:** `vendor/dots-hyprland/sdata/subcmd-install/3.files.sh:219` — `if [[ ! "${SKIP_BACKUP}" == true ]]; then auto_backup_configs; fi`

This is not the removal of the wrapper's own backup gate (which is deliberate and out of scope). It is a new, opposite-signed behavior:

```bash
  local -a cmd=(./setup "$subcmd")
  if touches_files "$subcmd"; then
    cmd+=(--skip-backup)
  fi
```

At `7334498` the wrapper never passed `--skip-backup`; it went the other way, **refusing** a user-supplied one unless `--allow-skip-backup` was also given (`7334498:arch/dots-hyprland.sh:1430-1435`). Phase 16 inverted that: upstream's `auto_backup_configs` is now suppressed on every single file-touching install, and there is no path back. `--full` is a no-op, user flags are appended *after* `--skip-backup`, and upstream's getopt has no `--no-skip-backup` or `--backup` to counter it — grep `options.sh:50` confirms only `skip-backup` exists in the long-option list. The only way to get a backup is to bypass the wrapper entirely and call `vendor/dots-hyprland/./setup` by hand, which the playbook (`docs/dots-hyprland-workflow.md:10`) says is not the install entry.

Combined with C-01's dry-run blindness and the fact that upstream renames `~/.config/hypr/hyprland.conf` to `.old` during the files stage, an operator re-running `install-files` after a pin bump has no snapshot of anything else the files stage overwrites (misc overlay, fish, fontconfig, `starship.toml` — see `docs/phase14-adopt-runbook.md:251`, which records `starship.toml` as "overwritten in place ... an accepted loss").

The behavior is documented (help text `:50-54`, playbook `:157-159`, runbook `:165`), so the *decision* is visible. The **defect** is that the decision has no escape hatch and the wrapper is the sole supported entry point.

**Fix:** keep the default, add the opt-out. Minimal change:

```bash
      --keep-backup)
        # Do not suppress upstream's auto_backup_configs for this run.
        keep_backup=1
        ;;
...
  local -a cmd=(./setup "$subcmd")
  if touches_files "$subcmd" && ((keep_backup == 0)); then
    cmd+=(--skip-backup)
  fi
```

Document it in `usage()` under "Wrapper-owned meta flags" alongside `--dry-run` and `--full`, and add an assert in `scripts/phase16-retire-assert.sh` that `install --keep-backup --dry-run`'s would-exec line omits `--skip-backup`.

**Should an existing suite have caught this?** No — `phase16-retire-assert.sh:75-80` asserts the *presence* of `--skip-backup` as the desired D-06 contract. The suite encodes the behavior; it cannot flag it.

### H-02: `docs/phase14-adopt-runbook.md` sections 4 and 7 still instruct operators on machinery Phase 16 deleted, and contradict section 5 of the same file

**Severity:** high / **BLOCKER**
**File:** `docs/phase14-adopt-runbook.md:11`, `:138`, `:196`, `:200`, `:208`, `:121`

Plan 16-05 converted §3, §5 and §14 to past-tense records. §4, §7 and the header blockquote were left in the imperative and are now wrong:

| Line | Text | Reality |
|---|---|---|
| 11 | "run `./arch/dots-hyprland.sh help` for the full allowlist, **safe defaults, backup gate**, uninstall, and **protect** behavior" | `help` has no safe-defaults, no backup gate and no `protect` section. `protect` is not in `ALLOWLIST` (`arch/dots-hyprland.sh:14`) and `./arch/dots-hyprland.sh protect` now exits 1. |
| 138 | table row: "`--skip-backup` \| **Refused bare by the wrapper by design.** If you find yourself reaching for the override that unblocks it, stop and re-read section 3." | The wrapper **injects** `--skip-backup` itself (`:693`). There is no refusal and no override. Line 165 of this same file says so explicitly: *"Phase 16 passes `--skip-backup` to upstream unconditionally"*. The file directly contradicts itself. |
| 196 | "**Wrapper preflight and backup gate.** The gate asks for confirmation before anything touches files. Type `yes`." | There is no gate. `run_install_family` prompts for nothing; upstream's greeting is the first and only pause. An operator following this waits for a prompt that never arrives, and the install proceeds past the point they expected to be able to abort. |
| 200 | "Files stage, in this order: **backup** → misc → quickshell → …" | The backup step is skipped (H-01). |
| 208 | "**Wrapper post-install:** the protect-list re-mark and the ii hook enable." | Both deleted in `refactor(16-01)`. Nothing happens after the upstream exec. |
| 121 | "…makes it **rollback tier-1 source 3** of [section 14](#14-rollback-adopt-04-d-23-d-24)…" | §14 no longer has tiers or a "source 3" — the whole tiered rollback was replaced at `:315-319`. Dangling internal reference. |

The `--full` invocations at `:189` and `:215` still *work* (the no-op alias holds), so those are not failures, but `:192` calling `--full` "the `--full` meta flag ... and nothing else" reads as though it is load-bearing when it is announced-and-discarded.

**Fix:** finish the sweep with the same past-tense record treatment used in §3/§5. Concretely:

- Line 11: replace the enumeration with "run `./arch/dots-hyprland.sh help` for the allowlisted subcommands, the two wrapper-owned meta flags, and the uninstall flags" (matching `docs/dots-hyprland-workflow.md:18`, which is already correct).
- Line 138: replace the `--skip-backup` row. It is no longer a banned flag; it is the wrapper's own injection. Either drop the row or restate it as a record: "`--skip-backup` — at the time of this window the wrapper refused it bare. Phase 16 inverted that; the wrapper now passes it on every install (see §5)."
- Lines 196, 200, 208: mark the whole "What you will see, in upstream's own order" list as a record of the 2026-09-04 run, and add a note that steps 1 (backup gate), the backup sub-step of 5, and 6 (post-install) no longer occur.
- Line 121: repoint or delete the "tier-1 source 3 of section 14" clause.
- Outline line 30 / heading `:313` still carry `ADOPT-04`, which `scripts/phase14-verify.sh` no longer emits (the labels were renamed to `D-20`/`D-10` in this diff). Retitle or note it.

**Should an existing suite have caught this?** Partly. `scripts/phase16-retire-assert.sh:172-181` deliberately scopes its documentation ban to `docs/dots-hyprland-workflow.md` and explicitly excludes the runbook ("the adopt-window runbook is excluded for the same reason — it is a true account of what the adopt ran"). That reasoning holds for §3/§5, which *are* accounts. It does not hold for §4 and §7, which are imperatives. A narrower ban — the runbook must not contain `backup gate`, `protect-list` or `Refused bare` outside a record fence — would have caught all of these.

## Medium

### M-01: `uninstall` deletes the entire `~/.config/quickshell` tree, not just the `ii` config

**Severity:** medium / **WARNING**
**File:** `arch/dots-hyprland.sh:160-165`
**Note:** pre-dates Phase 16; unchanged by this diff apart from a comment.

```bash
  local qs="${XDG_CONFIG_HOME}/quickshell"
  # Signature of stock ii install-files (LIVE-01)
  if [[ -f "$qs/ii/shell.qml" ]] || [[ -d "$qs/ii" ]]; then
    targets+=("$qs")
  fi
```

The detection is scoped to `$qs/ii` but the removal target is the parent `$qs`. Quickshell supports multiple named configs side by side (`qs -c <name>`); any non-ii config the user keeps at `~/.config/quickshell/<other>` is destroyed as collateral. The gate does print the path it will remove, so it is not fully silent — but the printed target is `~/.config/quickshell`, which an operator reading a list of "ii-owned configs" would not read as "and everything else you keep there."

**Fix:** narrow the target to the detected subtree and clean the parent only if it is then empty.

```bash
  if [[ -f "$qs/ii/shell.qml" ]] || [[ -d "$qs/ii" ]]; then
    targets+=("$qs/ii")
  fi
```

and after the removal loop in `run_safe_uninstall`, `rmdir "$qs" 2>/dev/null || true`.

### M-02: `--allow-skip-backup` is no longer wrapper-owned and now reaches upstream's getopt as an unknown option

**Severity:** medium / **WARNING**
**File:** `arch/dots-hyprland.sh:670-684` (catch-all at `:680-682`); compare `:617-627`

Phase 16 kept `--full` as an announced no-op specifically so "old transcripts and scripts still work" (`:64-66`, `:676-677`). It did not give `--allow-skip-backup` the same treatment, even though it was a wrapper-owned meta flag at `7334498:arch/dots-hyprland.sh:1407-1409`. It now falls to the catch-all, lands in `user_flags`, and is forwarded:

`./arch/dots-hyprland.sh install --allow-skip-backup`
→ `./setup install --skip-backup --allow-skip-backup`
→ upstream `options.sh:47-51` `getopt` has no such long option → non-zero → the run dies with an opaque `unrecognized option` from a script the operator did not invoke.

The asymmetry is the defect: the `uninstall` path *does* handle its retired flags cleanly — `--keep-hypr-hooks`, `--skip-protect` and `--allow-skip-backup` were removed from the `case` and now hit `unknown+=` at `:618`, producing the clear `[FAIL] Unknown uninstall flag(s):` message at `:624`. The install path has no equivalent, so the same class of stale invocation fails loudly on one subcommand and confusingly on the other.

Related: a user-supplied `--skip-backup` is now silently duplicated on the argv (`./setup install --skip-backup --skip-backup`). Harmless to getopt, but the D-12 refusal that used to make that flag deliberate is gone with nothing in its place.

**Fix:** give the install family the same explicit retired-flag handling `uninstall` has:

```bash
      --allow-skip-backup|--skip-protect|--keep-hypr-hooks)
        echo "[CONFIG] $arg is a retired wrapper flag and is ignored (Phase 16)." >&2
        ;;
```

### M-03: `phase13-d19-assert.sh` W-3 error branches are dead code — `set -e` kills the suite before they can run

**Severity:** medium / **WARNING**
**File:** `scripts/phase13-d19-assert.sh:82-89` (also `:57-59`)

```bash
SOT_APPLY_FENCE="$(extract_fence "$SOT" '## Apply command (D-18)' \
  | grep -v '^# Phase 14 only')"
PB_APPLY_FENCE="$(extract_fence "$PLAYBOOK" '### Named files only')"

if [ -z "$SOT_APPLY_FENCE" ]; then
  fail "W-3 extract D-18 apply fence from $SOT (empty)"
```

The script runs under `set -euo pipefail` (`:15`). `extract_fence` raises `SystemExit` when the heading is missing (`:46`) or the fence is missing (`:51`). A failing command substitution in a simple assignment is fatal under `set -e` — confirmed:

```
$ bash -c 'set -euo pipefail; echo start; X="$(python3 -c "raise SystemExit(\"boom\")")"; echo reached'
start
boom
$ echo $?   # 1 — "reached" never printed
```

So a renamed heading in `13-SOT-APPLY.md` or in the playbook aborts the suite mid-run: the already-emitted `[PASS]` lines are printed, the `=== Phase 13 asserts: FAIL=N ===` summary never is, and the `fail "W-3 extract..."` line the author wrote for exactly this case never fires. Line 86's branch is unreachable in all cases (the `grep -v` in the pipe also trips `pipefail` when it selects nothing), so it is pure dead code. Line 58's `if [ -z "$FENCE" ]` has the same problem.

**Fix:** capture the failure instead of letting `set -e` take it.

```bash
SOT_APPLY_FENCE="$(extract_fence "$SOT" '## Apply command (D-18)' | grep -v '^# Phase 14 only' || true)"
PB_APPLY_FENCE="$(extract_fence "$PLAYBOOK" '### Named files only' || true)"
```

Same treatment for `FENCE="$(extract_fence "$SOT" '## In-repo verify (D-19)')"` at `:57`.

### M-04: Ban-greps in the assert scripts treat a grep *error* (exit 2) as "no match" and print PASS

**Severity:** medium / **WARNING**
**File:** `scripts/phase16-retire-assert.sh:193-198`, `:201-206`, `:213-218`, `:227-232`

Every ban is written `if grep ...; then fail; else pass; fi`. `grep` exits 1 for "no match" and 2 for an error — unreadable file, bad regex, and on this machine (`ugrep 7.8.4`) also a pattern that exceeds its complexity limits. Both 1 and 2 take the `else` branch, so **any grep failure is reported as a passing ban**. The script guards file existence for `$PLAYBOOK` at `:186-190` and guards `$UPDATE_SECTION` emptiness at `:225`, which shows the author was alert to vacuity — but the exit-2 case is not covered by either guard.

I verified this is currently latent, not live: all four patterns run cleanly under ugrep here (`dual-run`, `safe profile|safe defaults`, `SAFE_DEFAULTS`, `--skip-hyprland` → exit 1 in every case), and Python `re` confirms zero real matches in the playbook. **The bans hold; they are just not error-proof.** The same shape appears in `scripts/phase12-full-smoke.sh:60`, `:83`, `:88`, `:93`, `:124`, `:135`.

**Fix:** distinguish the two.

```bash
rc=0
grep -niE 'dual-run' "$PLAYBOOK" >/dev/null || rc=$?
case "$rc" in
  0) fail "D-36 playbook still names the retired session model (dual-run)"
     grep -niE 'dual-run' "$PLAYBOOK" || true ;;
  1) pass "D-36 playbook is free of the retired session-model term" ;;
  *) fail "D-36 ban-grep for 'dual-run' errored (exit $rc) — condition not observed" ;;
esac
```

### M-05: Checks read capture files outside the `if` that populates them, so they PASS for conditions never observed

**Severity:** medium / **WARNING**
**File:** `scripts/phase16-retire-assert.sh:137-142`; `scripts/phase12-full-smoke.sh:60-71`, `:135-141`

`phase16-retire-assert.sh:137`:

```bash
# --- D-09: no wrapper-owned prompt on the install path ---
if grep -q "Type 'yes'" "$INSTALL_OUT"; then
  fail "D-09 install --dry-run still prints the exact-token gate line"
else
  pass "D-09 install path has no wrapper-owned confirmation prompt"
fi
```

`$INSTALL_OUT` is populated inside the `if` at `:50`. If that dry-run exited non-zero — a missing submodule trips `preflight` at `:112-116` — `$INSTALL_OUT` holds the `[FAIL] vendor/dots-hyprland is not an initialized submodule` text, which contains no `Type 'yes'`, and the script prints **`[PASS] D-09 install path has no wrapper-owned confirmation prompt`** for an install path it never reached. Same structure in `phase12-full-smoke.sh` at `:60` and `:67` (reading `$HELP_OUT` outside the `if` at `:48`) and at `:135` (reading `$FULL_OUT` outside the `if` at `:76`).

This never masks a green suite — the capture failure itself emits a `[FAIL]` that reds the run — but it does mean the transcript prints PASS lines for unobserved conditions, which is precisely the property `scripts/phase14-verify.sh:10-11` states as a hard rule for this project ("Never reports a `[PASS]` for a condition it could not observe").

**Fix:** move the dependent checks inside the populating `if`, or gate them:

```bash
if [[ -s "$INSTALL_OUT" ]] && grep -q 'would exec' "$INSTALL_OUT"; then
  if grep -q "Type 'yes'" "$INSTALL_OUT"; then ... fi
else
  fail "D-09 not observed: no usable install --dry-run capture"
fi
```

### M-06: `phase14-verify.sh:315` uses `pgrep -f` for a hard assert, contradicting its own contract and its own helper

**Severity:** medium / **WARNING**
**File:** `scripts/phase14-verify.sh:315-319` (correct helper sits at `:320-331`)

```bash
if pgrep -f 'qs -c ii' >/dev/null 2>&1; then
  pass "ADOPT-03 ii shell running: qs -c ii"
else
  fail "ADOPT-03 ii shell not running: qs -c ii"
fi
```

Two problems, both of which the file elsewhere shows awareness of:

1. The very next block (`:320-331`) exists because "pgrep exits 1 for 'no match' but 2, 3 and 127 for usage errors and a missing binary" and routes those to `finding` instead of `fail`. Line 315 does not use it: a `pgrep` that errors is reported as the specific defect "ii shell not running", violating the file's own header rule at `:12-14` ("an unobservable condition is never reported as a specific defect either").
2. `pgrep -f` substring-matches the full cmdline. `arch/dots-hyprland.sh:196-198` warns against exactly this idiom — *"never substring-search the full cmdline (that false-positives on shells/editors whose args mention `qs -c`)"* — and implements a `/proc`-walking `collect_qs_pids` to avoid it. Run `phase14-verify.sh` from a shell or editor whose argv mentions `qs -c ii` and you get a false `[PASS]`.

`docs/dots-hyprland-workflow.md:311` publishes the same fragile command to operators as the hand version of this check.

**Fix:** route through the existing rc-aware helper and match on `comm` rather than the full cmdline:

```bash
rc=0; pgrep -x qs >/dev/null 2>&1 || rc=$?
[[ $rc -ne 0 ]] && { pgrep -x quickshell >/dev/null 2>&1 || rc=$?; }
case "$rc" in
  0) pass "ADOPT-03 ii shell running (qs/quickshell)" ;;
  1) fail "ADOPT-03 ii shell not running" ;;
  *) finding "ADOPT-03 pgrep exited $rc — neither running nor absent was observed" ;;
esac
```

### M-07: `phase13-d19-assert.sh` executes a shell fence extracted from a Markdown file, and Phase 16 generalized that into a reusable extractor

**Severity:** medium / **WARNING**
**File:** `scripts/phase13-d19-assert.sh:39-54`, `:57-68`

```bash
FENCE="$(extract_fence "$SOT" '## In-repo verify (D-19)')"
...
  TMP="$(mktemp /tmp/p13-d19-XXXXXX.sh)"
  printf '%s' "$FENCE" >"$TMP"
  if bash -e "$TMP"; then
```

Whatever sits inside the first ```` ```bash ```` fence under `## In-repo verify (D-19)` in `.planning/phases/13-personal-hypr-custom-overlays/13-SOT-APPLY.md` is executed with the invoking user's privileges every time the suite runs. Phase 16 did not introduce this, but it refactored the inline extraction into a parameterized `extract_fence` with three call sites, making "markdown becomes executable code" a reusable pattern in this repo. A documentation-only edit — the exact kind of change these phases produce in bulk, and the kind a reviewer skims — is now a code-execution change. The DRY argument in the comment at `:35-38` is sound; the trust boundary is what is unremarked.

Secondary: `rm -f "$TMP"` at `:68` is not a trap, so the temp script survives if the fence exits the suite (see M-03).

**Fix:** at minimum, state the trust boundary in the header comment ("this script executes shell extracted from `13-SOT-APPLY.md`; an edit to that file is an edit to this script") and add a `trap 'rm -f "$TMP"' EXIT` so the extracted script is not left in `/tmp`. Consider bounding what the fence may contain (e.g. reject a fence containing `rm `, `sudo`, or `>` redirection into `$HOME`) before executing it.

### M-08: The playbook claims no flag can narrow the install; `install --core` narrows it

**Severity:** medium / **WARNING**
**File:** `docs/dots-hyprland-workflow.md:14` (mechanism at `arch/dots-hyprland.sh:680-682`, `:695-697`)

> "There is one install path and it is the full one: a bare `install` takes the whole ii session, and **no flag on this wrapper makes it take less**."

The wrapper strips exactly two flags (`--dry-run`, `--full`) and forwards everything else verbatim. `--core`, `--skip-hyprland`, `--skip-sysupdate`, `--skip-miscconf`, `--skip-quickshell` and the rest of `vendor/dots-hyprland/sdata/subcmd-install/options.sh:50` all pass straight through and do narrow the install. `./arch/dots-hyprland.sh install --core` reproduces most of the retired safe profile.

Nothing enforces the documented claim either: `phase12-full-smoke.sh:83-97` and `phase16-retire-assert.sh:57-73` only assert that the **wrapper** does not *inject* those flags, never that a user cannot supply them.

**Fix:** pick one. Either (a) soften the prose to "no *wrapper-owned* flag makes it take less; flags you pass are forwarded to upstream unchanged and upstream's own narrowing flags still work" — which matches `:153` and is the honest description; or (b) make the code match by refusing the retired triple:

```bash
      --core|--skip-hyprland|--skip-sysupdate)
        echo "[FAIL] $arg reproduces the retired safe profile; full is the only install behavior (D-04)." >&2
        echo "[FAIL] To narrow the install, call vendor/dots-hyprland/./setup directly." >&2
        exit 1
        ;;
```

and add the corresponding assert to `phase16-retire-assert.sh`.

## Low

### L-01: Dead `BACKUP_DIR` in `phase14-verify.sh`

**Severity:** low / **WARNING**
**File:** `scripts/phase14-verify.sh:45`, `:80`

This diff removed both consumers of `BACKUP_DIR` (the tier-1 source 3 check and the whole D-36 backup-verification block). The variable survives, is still assigned `"$HOME/ii-original-dots-backup"`, and is still printed as `[CONFIG] backup_dir=$BACKUP_DIR` in the run header — advertising a backup directory the wrapper no longer produces (H-01) and nothing checks. This is a dead reference to removed machinery of exactly the class in focus item 4.

**Fix:** delete both lines. The `baseline_value backup_dir_hyprland_conf_mtime` key it fed is also now unread in `14-PRE-ADOPT-BASELINE.txt` (leave the fixture; it is frozen evidence).

### L-02: `read` at EOF aborts the uninstall gate under `set -e` without printing its abort message

**Severity:** low / **WARNING**
**File:** `arch/dots-hyprland.sh:377-382`, `:568-573`

```bash
  local ans
  read -r -p "Type 'yes' to continue safe uninstall: " ans
  if [[ "$ans" != "yes" ]]; then
    echo "[FAIL] Aborted (uninstall gate). Nothing changed." >&2
    exit 1
  fi
```

With stdin closed or empty (`./arch/dots-hyprland.sh uninstall </dev/null`, or any non-interactive invocation), `read` returns 1 at EOF and `set -eo pipefail` terminates the script immediately — before the `if`. The direction is fail-closed, which is correct, but the operator gets a bare exit 1 with no explanation instead of "Nothing changed." Same at `:569` for the `UPSTREAM-UNINSTALL` prompt.

**Fix:** `read -r -p "..." ans || true` at both sites; the `!= "yes"` comparison then handles EOF correctly and prints the message.

### L-03: `uninstall --dry-run --upstream-dangerous` blocks on a confirmation prompt before printing the plan it promised

**Severity:** low / **WARNING**
**File:** `arch/dots-hyprland.sh:559-580`

`run_upstream_uninstall_dangerous` prompts for `UPSTREAM-UNINSTALL` at `:569` and only checks `dry_run` afterwards at `:577`. A `--dry-run` that demands a destructive-intent token before showing a plan defeats the point of the preview, and combined with L-02 a piped/non-interactive dry-run dies at EOF instead of printing.

**Fix:** move the `if ((dry_run)); then ... exit 0; fi` block above the `read`.

### L-04: The wrapper-drift baseline is pinned by short SHA and degrades to a silent skip

**Severity:** low / **WARNING**
**File:** `scripts/phase13-d19-assert.sh:199-212`

```bash
if ! git cat-file -e "${WRAPPER_BASE}^{commit}" 2>/dev/null; then
  printf '[INFO] %s\n' "arch/dots-hyprland.sh: baseline $WRAPPER_BASE not in this repo; drift not checked"
```

`0771cc2`, `14c6828` and `e7e4e9f` are 7-char abbreviations. If one becomes ambiguous as history grows, or the commit is unreachable after a rebase, `git cat-file -e` fails and the drift check turns itself off with an `[INFO]` that does not move `FAIL`. A check whose job is detecting drift should not have a silent off switch. (I verified `0771cc2` resolves and matches the working tree today.)

Secondary: the tier selector keys on the existence of `16-DOC-SWEEP.md` — a planning artifact unrelated to the wrapper. Any future phase touching the wrapper must remember to add a fourth branch; there is no mechanism that forces it, only the comment at `:196-198`.

**Fix:** pin full 40-char SHAs, and make an unresolvable baseline a `fail` rather than an `[INFO]`.

### L-05: `mktemp` templates hardcode `/tmp`, ignoring `TMPDIR`

**Severity:** low / **WARNING**
**File:** `scripts/phase16-retire-assert.sh:32-36`; `scripts/phase12-full-smoke.sh:29-34`; `scripts/phase13-d19-assert.sh:61`; `scripts/phase14-verify.sh:369`

`mktemp /tmp/p16-retire-install-XXXXXX` overrides any `TMPDIR` the environment sets. Where `/tmp` is read-only, noexec (which would break `bash -e "$TMP"` in `phase13-d19-assert.sh:63`), or absent, `mktemp` fails — and under `set -e` in a command substitution the whole suite dies before printing anything.

**Fix:** use `mktemp -t p16-retire-install.XXXXXX`, which honours `TMPDIR` and falls back to `/tmp`.

### L-06: `install --help` is not handled by the wrapper and is forwarded to upstream

**Severity:** low / **WARNING**
**File:** `arch/dots-hyprland.sh:670-684`; compare `:598-601`

`main` matches `help|-h|--help` only as `$1` (`:720-725`). `run_uninstall` handles `-h|--help` explicitly at `:598`. `run_install_family` does not, so `./arch/dots-hyprland.sh install --help` runs `preflight` (which can exit 1 on a machine with no submodule — help should never require one) and then execs `./setup install --skip-backup --help`, handing the operator upstream's help text where they asked for the wrapper's. Harmless but inconsistent.

**Fix:** add `-h|--help) usage; exit 0 ;;` to the `case` in `run_install_family`.

### L-07: `phase16-retire-assert.sh` under-covers the contract it names

**Severity:** low / **WARNING**
**File:** `scripts/phase16-retire-assert.sh:86-121`, `:164-170`

The script's own header claims it asserts "`--full` is accepted but never forwarded" and "the skip-backup flag is forwarded only where upstream reads it." Neither is fully covered:

- `--full` stripping is asserted for `install` only (`:153-158`). `install-files --full` and `install-deps --full` are never checked against the would-exec line; `:165-170` only asserts `install-deps --full` exits 0, not that the flag was stripped.
- The negative scope for `--skip-backup` is asserted for `install-setups` only (`:124-134`). `install-deps` — the other non-file subcommand — is never checked.

Both gaps are one-line copies of checks the file already contains. Neither is currently violated (`touches_files` at `:655-660` is correct), but the assert does not prove it.

**Fix:** add the two missing captures and mirror the existing check bodies.

### L-08: `shellcheck` is not available, so no lint gate ran on 560 lines of new/changed shell

**Severity:** low / **WARNING**
**File:** environment

`command -v shellcheck` is empty on this machine. The phase added `scripts/phase16-retire-assert.sh` (241 lines) and materially rewrote four other shell files with no static analysis beyond `bash -n` (which the suites do run — `phase16-retire-assert.sh:43`, `phase12-full-smoke.sh:41`). `bash -n` catches syntax only; every finding above (M-03's `set -e` interaction, M-04's exit-code conflation, L-02's `read` under `set -e`) is in `shellcheck`'s or a careful reviewer's range and outside `bash -n`'s.

**Fix:** install `shellcheck` and add it to the assert suites next to the existing `bash -n` calls:

```bash
if command -v shellcheck >/dev/null 2>&1; then
  if shellcheck -S warning arch/dots-hyprland.sh scripts/*.sh; then
    pass "shellcheck -S warning clean"
  else
    fail "shellcheck -S warning reported issues"
  fi
else
  fail "shellcheck not installed — lint gate not observed"
fi
```

(`fail`, not a silent skip, per the project's own "never PASS for an unobserved condition" rule.)

## Verified clean

Recording what I checked and found sound, so a re-review does not redo it:

- **No dead references in the surviving wrapper.** `grep -n "hook\|protect\|PROTECT\|II_BACKUP\|backup_gate\|needs_safe_defaults\|user_flags_contain\|is_help_only\|SAFE_DEFAULTS\|allow_skip" arch/dots-hyprland.sh` → no output. `SAFE_DEFAULTS`, `II_BACKUP_DIR`, `backup_gate`, `protect_explicit_packages`, `enable_hypr_ii_hooks`, `disable_hypr_ii_hooks`, `list_active_hypr_ii_hook_files`, `warn_hypr_ii_hooks`, `collect_installed_protect_packages`, `needs_safe_defaults`, `is_help_only_user_flags` and `user_flags_contain` are all fully gone, definitions and call sites both.
- **No references to the two deleted scripts outside `.planning/` and their own record fences.** The four hits in `docs/phase14-adopt-runbook.md` (`:81`, `:87-88`, `:104`, `:154-159`) are all inside past-tense records that explicitly say "no longer exists (removed in Phase 16)", and none is a bare runnable invocation.
- **The `--full` no-op alias works as described.** `:675-679` strips it before argv construction; `:147-158` of the assert proves the `[CONFIG]` note and the absence from the would-exec line.
- **The `--skip-backup` scoping predicate is correct.** `touches_files` (`:655-660`) matches upstream: `3.files.sh:219` is the only reader of `SKIP_BACKUP`, and `setup:104-124` shows `install-setups` and `install-deps` never source `3.files.sh`.
- **Argv construction is safe.** Array-only exec (`:708-711`, `:581-584`), no `eval`, no concatenated command string, `cd` inside a subshell so the parent's cwd is unaffected and a failing `cd` aborts under the inherited `set -e`.
- **No hardcoded secrets, no injection surface, no `eval`, no unquoted expansions in a destructive position** across the five shell files. All `rm -rf` targets are `--`-terminated and quoted; `XDG_STATE_HOME`/`XDG_CONFIG_HOME`/`XDG_DATA_HOME` all carry `:-` defaults (`:17-19`) so no target can collapse to a bare path. `safe_rm_path` (`:386-408`) correctly refuses outside `$HOME` and refuses hypr — the one bypass is C-01.
- **All five changed shell files pass `bash -n`.**
- **The wrapper-drift pin is accurate.** `git diff --name-only 0771cc2 -- arch/dots-hyprland.sh` is empty.
- **The playbook's `awk` update-contract range extractor works** (`phase16-retire-assert.sh:224`): `## 10. Update contract (pin-bump)` matches the start pattern and `## 11. Non-goals` terminates the range. It would silently over-extend if a section immediately after the update contract ever began with `U`, but that is not the case today and the `-n "$UPDATE_SECTION"` guard at `:225` covers the empty-extraction failure mode.
- **The playbook (`docs/dots-hyprland-workflow.md`) is internally consistent with the wrapper** on every command it quotes. `install --dry-run`, `install-files --dry-run`, `install-setups --dry-run`, `install`, `install-files`, `install-deps`, `./scripts/phase13-d19-assert.sh`, `./scripts/phase14-verify.sh` all behave as documented. Only `:14` overstates (M-08) and `:311` publishes the fragile `pgrep -f` idiom (M-06).

---

_Reviewed: 2026-09-08T10:22:44Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
