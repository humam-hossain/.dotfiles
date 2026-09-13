---
phase: 17-unblock-stow-and-restore-the-session-target
verified: 2026-09-13T17:32:00Z
status: human_needed
score: 5/6 must-haves verified
behavior_unverified: 1
overrides_applied: 0
verification_method: goal-backward, evidence-first — every criterion re-established
  against the working tree and the live system, not read out of a SUMMARY
assert_results:
  phase17_unblock_assert: "=== done: FAIL=0 ==="
  phase13_d19_assert: "=== Phase 13 asserts: FAIL=0 ==="
  phase11_dispositions_assert: "=== done: FAIL=1 ===  (PRE-EXISTING, reconfirmed)"
  phase10_inventory_assert: "=== done: FAIL=1 ===  (PRE-EXISTING, reconfirmed)"
  phase14_verify: "aborts on missing baseline fixture (PRE-EXISTING, reconfirmed)"
behavior_unverified_items:
  - truth: "Criterion 5 (START-02) — `systemctl --user is-active graphical-session.target`
      returns `active` after a fresh login, started from `custom/execs.lua`"
    test: "Log out of the Hyprland session and log back in. Then run
      `systemctl --user is-active graphical-session.target` and
      `systemctl --user is-active hyprland-session.service`."
    expected: "Both print `active` and exit 0. Re-running
      `bash scripts/phase17-unblock-assert.sh` then reports 5e as [PASS]
      (`graphical-session.target is ACTIVE`) instead of [INFO]."
    why_human: "An agent cannot end the operator's desktop session. The mechanism is
      present, wired and byte-identical across repo and live tree, and it was proved once
      by hand during wave 5 (journal: started 16:40:47, stopped 16:40:49 this boot), but
      the binding clause of the criterion is the post-login observation, which no
      non-mutating check can produce. Current live state is `inactive` (exit 3)."
findings:
  - id: V-1
    severity: warning
    title: "REQUIREMENTS.md still marks FIX-02, FIX-06, START-02 and START-03 as Pending"
    detail: "Only waves 1 and 2 flipped their markers (commits 80df9d9, b95917a). Waves
      3-7 modified REQUIREMENTS.md not at all, so four of the phase's seven requirement
      IDs read `[ ]` / `Pending` while their summaries read `requirements-completed`.
      Bookkeeping only — no codebase consequence — but it must be repaired before phase
      close or the milestone's coverage table undercounts this phase by four."
  - id: V-2
    severity: info
    title: "The verification brief's premise about the helper units is partly wrong"
    detail: "Empty ActiveEnterTimestamp + empty InactiveEnterTimestamp does NOT prove
      `never started this boot`. The journal proves hyprland-session.service and
      graphical-session.target DID run this boot. The conclusion the brief draws
      (the live run stopped nothing) survives, but on different evidence."
  - id: V-3
    severity: info
    title: "`FAIL=0` from the phase-17 assert does not certify criterion 5"
    detail: "Assertion 5e is `info()` on every inactive branch and `pass()` only when the
      target is already active (script lines 799-838). This is a deliberate, documented
      soft gate, not a defect — but it means the headline FAIL=0 is silent on the one
      sub-claim that is still open."
  - id: V-4
    severity: info
    title: "A tracked `.env` sits under `stow/` and the `.gitignore` pattern does not reach it"
    detail: "`git ls-files` lists stow/system_monitor/.config/system_monitor/ping/.env as
      TRACKED. The two `.env`-shaped lines at the top of .gitignore are repo-root-anchored
      and reach nothing — the file's own comment block says so. Operator-triaged as
      non-credential (outcome A) and both gitleaks scans are clean, so criterion 4 is not
      affected. Hands to Phase 18 / FIX-03. Path not opened during this verification."
  - id: V-5
    severity: info
    title: "Accepted allowlist entries cover real-but-dead credentials in published history"
    detail: "Eight of the twelve .gitleaks.toml entries accept WakaTime and AccuWeather
      keys that are `reachable from published tags v0.2 and v1.0`, each recorded as
      `credential confirmed dead by the operator` with `no rewrite performed by operator
      decision`. That satisfies D-13 (a reason per entry, no blanket baseline). It is an
      accepted risk, not a technical zero."
human_verification:
  - test: "Log out of Hyprland and log back in; then
      `systemctl --user is-active graphical-session.target`"
    expected: "`active`, exit 0 — and phase-17 assert 5e flips from [INFO] to [PASS]"
    why_human: "Only an operator can end the session; criterion 5's binding clause is the
      post-login observation"
  - test: "Flip the four stale REQUIREMENTS.md markers (FIX-02, FIX-06, START-02,
      START-03) once the re-login confirms START-02"
    expected: "All seven Phase 17 requirement rows read Complete"
    why_human: "Requires the operator's judgement on whether START-02 closes now or after
      the re-login"
---

# Phase 17: Unblock stow and restore the session target — Verification Report

**Phase Goal:** The repo's own install scripts run instead of failing, cannot revert or
delete what the milestone captures, and the live session has `graphical-session.target` back
**Verified:** 2026-09-13
**Verified at HEAD:** `ec6d97d` — working tree clean (`git status --porcelain` empty)
**Status:** `human_needed`
**Score:** 5 of 6 success criteria verified; 1 present-but-behavior-unverified

---

## Overall Verdict

**Five of the six success criteria are established. The sixth — criterion 5's
`graphical-session.target` active-after-login clause — is not, and cannot be, without an
operator re-login that this verification is forbidden to perform.**

Everything the phase could deliver in the tree, it delivered. All three parts of the
goal statement hold in the codebase:

- *"install scripts run instead of failing"* — verified by execution. All 15 stow call
  sites carry the valid flag pair, all 14 host files pass `bash -n`, the installed GNU
  Stow accepts the spelling on a real simulate run, and `arch/hyprland.sh` completed a
  full end-to-end live run with exit status 0.
- *"cannot revert or delete what the milestone captures"* — verified by execution.
  `safe_rm_path` refused every fixture I threw at it, including the symlink-through-to-repo
  case that the phase's own assert script does *not* cover.
- *"the live session has `graphical-session.target` back"* — the **mechanism** is verified
  (present, wired, byte-identical repo↔live, and proved once by hand this boot). The
  **state** is not: the target is `inactive` right now, and only a login can change that.

This is a clean result, not a marginal one. The one open item is structural — the phase
was planned knowing it would end this way (VALIDATION.md §Sequencing Hazards item 2
decomposes criterion 5 into 5a-5e precisely so the re-login blocks one sub-claim rather
than the whole criterion). It is `human_needed`, not `gaps_found`.

One real inconsistency turned up that no summary flags: **four of seven requirement
markers in REQUIREMENTS.md were never flipped** (finding V-1). It is a one-line repair
with no codebase consequence, but it is a genuine divergence between what the summaries
claim and what the planning tree records.

---

## Assert Script Results (verbatim)

Both scripts run by me, from the repository root, at HEAD `ec6d97d`, on a clean tree.

```
$ bash scripts/phase17-unblock-assert.sh
...
=== done: FAIL=0 ===
```

93 output lines: 81 `[PASS]`, 0 `[FAIL]`, the rest `[INFO]` (the 5e session-target line
and the D-02 folding audit). Idempotency confirmed by contract D-20 — I ran it twice
(once to screen, once captured to a file) and both runs produced `FAIL=0` with no change
to the tree.

```
$ bash scripts/phase13-d19-assert.sh
...
=== Phase 13 asserts: FAIL=0 ===
```

17 `[PASS]`, 0 `[FAIL]`. Notably it independently re-confirms two Phase 17 facts:
`execs.lua holds exactly one hl.exec_cmd and it is the START-02 session bootstrap`, and
`live custom/execs.lua matches repo source`.

---

## Requirement Coverage

**Verified by inspection.** Union of `requirements-completed:` across all seven summaries:

| Summary | Line | `requirements-completed` |
|---|---|---|
| 17-01-SUMMARY.md | 62 | `[FIX-01, CAP-04]` |
| 17-02-SUMMARY.md | 56 | `[FIX-04]` |
| 17-03-SUMMARY.md | 62 | `[FIX-06]` |
| 17-04-SUMMARY.md | 57 | `[FIX-06]` |
| 17-05-SUMMARY.md | 63 | `[START-02, START-03]` |
| 17-06-SUMMARY.md | 49 | `[FIX-02]` |
| 17-07-SUMMARY.md | 63 | `[FIX-02]` |

Union = `{FIX-01, FIX-02, FIX-04, FIX-06, CAP-04, START-02, START-03}`.
Phase set per ROADMAP.md:78 = the same seven. **Nothing missing, nothing extra.**

**The 17-06 repair is present and correct.** `17-06-SUMMARY.md:49` now reads `[FIX-02]`,
and `17-06-PLAN.md:11` carries `requirements: [FIX-02]` — they match. The repair landed in
commit `d38d8c5` ("chore(17): close wave 7 state and repair 17-06's requirement marker"),
whose message documents the defect and the fix honestly.

### Finding V-1 — four requirement markers were never flipped

Established by execution, not inference:

```
$ git log --oneline 1f10eee..HEAD -- .planning/REQUIREMENTS.md
b95917a docs(17-02): complete the safe_rm_path repo-containment plan
80df9d9 docs(17-01): complete the stow flag sweep and assert harness plan
```

Only waves 1 and 2 touched the file. The current state:

```
15:- [x] **FIX-01**   113:| FIX-01 | Phase 17 | ... | Complete |
16:- [ ] **FIX-02**   114:| FIX-02 | Phase 17 | ... | Pending  |   <-- stale
18:- [x] **FIX-04**   115:| FIX-04 | Phase 17 | ... | Complete |
20:- [ ] **FIX-06**   116:| FIX-06 | Phase 17 | ... | Pending  |   <-- stale
27:- [x] **CAP-04**   117:| CAP-04 | Phase 17 | ... | Complete |
42:- [ ] **START-02** 118:| START-02| Phase 17 | ... | Pending |   <-- arguably correct
43:- [ ] **START-03** 119:| START-03| Phase 17 | ... | Pending |   <-- stale
```

Waves 1-2 set the convention *inside this same phase* — flip on plan completion — and
waves 3-7 did not follow it. `FIX-06` and `START-03` are unambiguously stale: both are
fully delivered and machine-asserted. `FIX-02` is stale on the criterion's wording (the
ROADMAP text is satisfied; the REQUIREMENTS.md wording carries the D-03 amendment).
`START-02` is defensibly still Pending until the re-login. **Severity: warning.** No
codebase consequence; repair before phase close.

---

## Per-Criterion Evidence

### Criterion 1 — stow flag sweep (FIX-01, CAP-04) — ✓ VERIFIED BY EXECUTION

> *No `stow` call site in `arch/` carries `-v=5`; all 15 sites across 14 files carry both
> `--verbose=5` and `--no-folding`, and `bash -n` passes on every one of those files*

**The invalid spelling is gone, repo-wide:**

```
$ grep -rn -- "-v=5" arch/ docs/
(no output)
```

**15 sites across 14 files, counted independently of the assert script:**

```
$ grep -rhoE "stow --verbose=5 --no-folding -t ~ [a-z_]+" arch/ | wc -l
15
$ grep -rlE "stow --verbose=5 --no-folding" arch/ | wc -l
14
```

**No site is missing the pair** — a negative search for any `stow ` invocation lacking it,
across both `arch/` and `docs/`, returns nothing:

```
$ grep -rnE "(^|[;&|] *)stow " arch/ docs/ | grep -v -- "--verbose=5 --no-folding"
(no output)
```

The 14 files are exactly the ones D-01 names. `arch/hyprland.sh` holds two sites
(lines 42 and 46), giving 15. `arch/necessary.sh:22` matches `stow` only as a *pacman
package name*, correctly excluded.

**`bash -n` on every one of the 14, run by me, not read from a summary:**

```
bash -n OK   arch/alacritty.sh      bash -n OK   arch/rofi.sh
bash -n OK   arch/btop.sh           bash -n OK   arch/tmux.sh
bash -n OK   arch/define.sh         bash -n OK   arch/wezterm.sh
bash -n OK   arch/fish.sh           bash -n OK   arch/xterm.sh
bash -n OK   arch/hyprland.sh       bash -n OK   arch/yazi.sh
bash -n OK   arch/kitty.sh          bash -n OK   arch/zsh.sh
bash -n OK   arch/nvim.sh           bash -n OK   arch/zsh_powerlevel.sh
```

14/14 pass.

**Behavioral, beyond the grep.** Assertion 1e does what a grep cannot — it proves the
literal *parses*, via a real `stow --verbose=5 --no-folding -n` simulate of package `btop`:

```
[PASS] 1e GNU Stow accepts --verbose=5 --no-folding (simulate run of package btop exits 0)
```

This is the strongest single piece of evidence for criterion 1: the flag spelling is not
merely written, it is accepted by the installed Stow.

**`docs/` in scope too (CAP-04 operator-doc scope).** Both stow invocations in
`docs/dots-hyprland-workflow.md` carry the pair — the kitty re-stow recipe
(`stow -R --verbose=5 --no-folding -t ~ kitty`) and the START-03 recovery fence
(`stow --verbose=5 --no-folding -t ~ systemd`). An operator copy-pasting either gets a
working command.

**Deviation, recorded and acceptable.** `arch/hyprland.sh`'s two sites use
`cd "$REPO_ROOT/stow"` rather than D-01's verbatim `cd "$(dirname "${BASH_SOURCE[0]}")/../stow"`.
This is the deliberate D-5 hoist from wave 6, documented as a "recorded departure from
D-01 for this one file" in `deferred-items.md:220` and in
`docs/dots-hyprland-workflow.md`. It adopts the idiom `arch/waybar.sh` already uses and is
held in place by assertion 2d. **Not a defect** — it is the fix for a defect.

---

### Criterion 2 — `arch/hyprland.sh` (FIX-02) — ✓ VERIFIED BY EXECUTION

> *`arch/hyprland.sh` contains no `cp -rf .config/hypr/*` and no cwd-relative path;
> running it end-to-end exits 0 and leaves `hyprctl -j status` still reporting
> `configProvider: lua`*

**Static half — verified by inspection of the file itself (all 46 lines read).**

The destructive stanza is gone. What stood at lines 24-26 is now a six-line marker comment
at lines 33-39 naming Phase 20 / HYPR-01 as the owner, and naming *what* was removed and
*why* — which is materially better than a bare `# TODO`. No `cp -rf`, no `mkdir -p ~/.config/hypr`.

Every path is anchored. The file resolves exactly one base, at line 12, before any
directory change:

```bash
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
```

and reuses it at both stow stanzas (lines 42, 46). There is no second
`$(dirname "${BASH_SOURCE[0]}")` to be evaluated from the wrong base. This is the D-5 fix,
and assertion 2d pins it:

```
[PASS] 2a arch/hyprland.sh holds neither the recursive-force copy of the repo Hyprland
       tree nor the directory creation that received it (FIX-02)
[PASS] 2b arch/hyprland.sh resolves no configuration path relative to the working directory
[PASS] 2c arch/hyprland.sh attributes Hyprland configuration placement to its owner
[PASS] 2d arch/hyprland.sh hoists exactly one resolved base and performs no directory
       change that re-resolves the script path (D-5)
```

**Live half — verified from the transcript, which I read directly (selectively, per
instruction).** This is a one-way run that cannot be repeated, so the transcript is the
only primary evidence and I treated it as such rather than trusting the LIVE-RUN summary.

The transcript's own trailer is unambiguous and is not narration:

```
Script started on 2026-09-13 17:22:39+06:00 [COMMAND="bash /home/pera/github_repo/.dotfiles/arch/hyprland.sh" ...]
...
Script done on 2026-09-13 17:22:47+06:00 [COMMAND_EXIT_CODE="0"]
```

`script -e` propagates the wrapped command's status, so `COMMAND_EXIT_CODE="0"` is the
installer's exit status, not `script`'s. **Exit 0 confirmed.**

The hoist is visible working in the transcript's very first `set -x` lines:

```
+++ dirname /home/pera/github_repo/.dotfiles/arch/hyprland.sh
++ cd /home/pera/github_repo/.dotfiles/arch/..
++ pwd
+ REPO_ROOT=/home/pera/github_repo/.dotfiles
```

One resolution, at the top. Both later stanzas then `cd /home/pera/github_repo/.dotfiles/stow`
— the same absolute path both times, which is exactly the property 2d asserts.

Both stow runs were no-ops over already-correct links, e.g.:

```
--- Skipping .config/swaync/style.css as it already points to
    ../../github_repo/.dotfiles/stow/swaync/.config/swaync/style.css
```

That is the correct outcome and is direct evidence the run did not replace a symlink with
a plain file.

**The post-condition, re-measured live by me right now — not read from the record:**

```
$ hyprctl -j status
{
    "configProvider": "lua",
    "backend": "drm"
}

$ ls -la ~/.config/hypr/hyprland.conf
ls: cannot access '/home/pera/.config/hypr/hyprland.conf': No such file or directory
```

`configProvider` is still `lua` and the pre-adopt `hyprland.conf` is still absent, hours
after the run. **The session survived the installer.** This is the substantive claim of
FIX-02 and it holds against the live system, independent of any document.

---

### Criterion 3 — `safe_rm_path` repo guard (FIX-04) — ✓ VERIFIED BY EXECUTION

> *`safe_rm_path` returns non-zero for any path under the repo root — asserted by a fixture
> case in the phase's assert script, alongside the existing `$HOME/*` and `*/.config/hypr*` cases*

The assert script's own fixtures pass:

```
[PASS] 3a safe_rm_path refuses a path inside the repo: .../.dotfiles/README.md
[PASS] 3a safe_rm_path refuses a path inside the repo: .../.dotfiles/stow
[PASS] 3a safe_rm_path refuses a path inside the repo: .../.dotfiles/vendor/dots-hyprland
[PASS] 3b safe_rm_path still refuses a path outside $HOME: /etc/passwd
[PASS] 3c safe_rm_path still refuses a hypr path: /home/pera/.config/hypr/custom
[PASS] 3d the wrapper loads cleanly in a subshell and safe_rm_path is defined
```

**I did not stop there.** The three 3a fixtures are all *literal* repo paths — they would
pass even under a naive string-prefix guard. D-05's stated reason for using `realpath -m`
on both sides is the case where a `$HOME`-shaped path reaches the repo *through a symlink*.
No fixture in the assert script exercises that. So I built one and ran it myself:

```
$ ln -sfn /home/pera/github_repo/.dotfiles/README.md "$SCRATCH/link-into-repo"
$ bash -c 'source arch/dots-hyprland.sh; ...'

--- sourced OK; type: function
[FAIL] Refusing to delete path inside the repo: .../scratchpad/link-into-repo
RESULT REFUSED(exit 1): .../scratchpad/link-into-repo
[FAIL] Refusing to delete path inside the repo: /home/pera/github_repo/.dotfiles/arch
RESULT REFUSED(exit 1): /home/pera/github_repo/.dotfiles/arch
[FAIL] Refusing to delete path outside $HOME: /etc/hosts
RESULT REFUSED(exit 1): /etc/hosts
[FAIL] Refusing to delete hypr path: /home/pera/.config/hypr/custom
RESULT REFUSED(exit 1): /home/pera/.config/hypr/custom

--- link still present? ---  lrwxrwxrwx ... link-into-repo -> .../README.md
--- repo README intact? ---  -rw-r--r-- 1 pera pera 1457 ... README.md
```

**The symlink-through case is refused, and nothing was deleted.** Both the decoy symlink
and the real `README.md` survived. The guard works for the exact reason D-05 says it needs
to, which the phase's own fixtures do not prove. All three clauses ($HOME allow-list, hypr
belt, repo belt) fire independently and in the documented order.

Reading the implementation (`arch/dots-hyprland.sh:431-469`) confirms the structure D-05
and D-06 specify: the repo clause sits **after** the `$HOME` allow-list rather than
replacing it, `REPO_ROOT` is `BASH_SOURCE`-derived with `pwd -P`, both sides go through
`realpath -m`, `vendor/dots-hyprland` has no carve-out (D-08), and there is no override
flag (D-07).

**D-09 dispatch guard works.** Sourcing the file executed nothing — `main` did not fire,
no output, no mutation — and `safe_rm_path` came out as a callable function. That is what
made the test above possible.

---

### Criterion 4 — repo hygiene and secret scan (FIX-06) — ✓ VERIFIED BY EXECUTION

> *`.gitattributes` exists with `* text=auto eol=lf`; `.gitignore` carries the generated and
> machine-state patterns; a secret scan over the capture trees reports zero findings and is
> re-runnable*

**`.gitattributes` — exact, single line:**

```
$ cat .gitattributes
* text=auto eol=lf
```

**`.gitignore` — both D-14 blocks present.** The generated-theme block
(`kdeglobals`, `gtk.css`, `Kvantum/`, `colors.lua`, `colors.conf`, `fuzzel_theme.ini`) and
the machine-state block (`.venv/`, `.mypy_cache/`, `.ruff_cache/`, `.pytest_cache/`,
`*.pyc`, `*.swp`, `*~`, `.DS_Store`, `*.sock`, `*.socket`, `*.lock`) — 17 patterns, each
with a `git check-ignore` proof row in the assert script, all passing.

The commentary is unusually good: it explains *why* the patterns are slash-free (anchoring
semantics), warns against "fixing" them into anchored form, and states outright that
`.config/kdeglobals` is already tracked so the pattern governs future writes only. The
assert script proves that last claim three ways (tracked, `check-ignore` exits non-zero,
`--no-index` shows the pattern would govern a future write).

The **breadth sweep** is the assertion that makes this non-vacuous — across all 577 tracked
files, the ignore set reaches only the 3 expected generated paths — plus six negative
controls confirming authored source is never swept up.

**Secret scan — re-runnability proved by me actually re-running it**, which is the only way
to prove "re-runnable":

```
$ gitleaks git . --redact --no-banner
INF 2621 commits scanned.
INF scanned ~35507026 bytes (35.51 MB) in 2.78s
INF no leaks found
(exit 0)

$ gitleaks dir . --redact --no-banner
INF scanned ~23443074 bytes (23.44 MB) in 1.56s
INF no leaks found
(exit 0)
```

Full history (2621 commits) and full working tree, both clean, on a run independent of the
assert script's. gitleaks is `/usr/bin/gitleaks`, owned by Arch package `gitleaks 8.30.1-1`
as D-11 specifies.

**"Zero findings" means zero *unreviewed* findings (D-13), and the triage holds up.** The
12 `[[allowlists]]` entries each carry a `description` stating a reason, each is scoped
with `condition = "AND"` **and** `targetRules` so none degrades into a whole-file skip, and
none names `.gitleaks.toml` itself — so the config stays inside the surface that proves it
carries no matched value. 158 comment lines record the reasoning. This is a genuine
per-finding triage, not a blanket baseline, which is exactly what D-13 demands.

See findings V-4 and V-5 for two observations that do not affect this criterion.

---

### Criterion 5 — session target (START-02) — ⚠️ PRESENT_BEHAVIOR_UNVERIFIED

> *`systemctl --user is-active graphical-session.target` returns `active` after a fresh
> login, started from `custom/execs.lua` — and the repo copy of `execs.lua` is
> byte-identical to the live one*

**Second clause — ✓ VERIFIED BY EXECUTION:**

```
$ cmp -s .config/hypr/custom/execs.lua ~/.config/hypr/custom/execs.lua && echo byte-identical
byte-identical
```

The hand-sync window ROADMAP flags as a known hazard is closed. `scripts/phase13-d19-assert.sh`
independently re-confirms it.

**Mechanism — ✓ VERIFIED BY INSPECTION.** The repo copy carries the Authoring-SoT header
(D-18), exactly one `hl.exec_cmd`, and it is the right one, inside the right handler:

```lua
hl.on("hyprland.start", function ()
    hl.exec_cmd("systemctl --user start hyprland-session.service")
end)
```

`start`, never `enable` (D-17) — and the unit state confirms the intent was honoured:

```
$ systemctl --user is-enabled hyprland-session.service
linked        (exit 1 — the documented correct state)
```

State `linked`, not `enabled`, which keeps the START-03 footgun out of reach. The stow
symlink backing it resolves correctly (see the link table below).

**First clause — ✗ NOT ESTABLISHED. This is the one open item in the phase.**

```
$ systemctl --user is-active graphical-session.target
inactive      (exit 3)
$ systemctl --user is-active hyprland-session.service
inactive      (exit 3)
```

The target is **not** active. The criterion's binding clause — `active` *after a fresh
login* — is unverifiable here because no fresh login has occurred since the mechanism was
installed, and producing one means ending the operator's session, which this verification
is explicitly forbidden to do.

Classified **PRESENT_BEHAVIOR_UNVERIFIED**, not FAILED: the code is present, wired,
byte-identical across both trees, and the mechanism was demonstrated to work once this
boot (see below). What is missing is the observation, not the implementation.

**Note V-3:** `FAIL=0` from the phase-17 assert does *not* speak to this. Assertion 5e is
`info()` on every inactive branch and `pass()` only when the target is already up (script
lines 799-838). That is a deliberate, documented design — a check that can never go green
on its own would be permanently red — but it means the headline count is silent here.

---

### Criterion 6 — the `disable` footgun (START-03) — ✓ VERIFIED BY INSPECTION

> *The `systemctl --user disable` footgun — it deletes the stow symlink for a unit in
> state `linked` — is written down in the operator docs with its recovery command*

`docs/dots-hyprland-workflow.md:347-360`. All four required elements present:

1. **The footgun, named with its verb and its mechanism** (line 347) — `disable` removes
   *every* symlink to a unit from `~/.config/systemd/user/`, including ones systemd did not
   create, "and a stow link is exactly that". It states what survives (the repo copy under
   `stow/systemd/`) and calibrates the severity honestly: "recoverable, not a data loss".
2. **The recovery command**, as a runnable fence anchored to REPO_ROOT:
   ```bash
   cd stow && stow --verbose=5 --no-folding -t ~ systemd && cd ..
   systemctl --user daemon-reload
   ```
   Both halves — the re-stow *and* the `daemon-reload` that makes the manager notice. The
   re-stow uses the criterion-1 flag pair, so the doc is self-consistent with the fix.
3. **The safe alternative** (line 358) — `mask` to prevent starting, `stop` for this
   session only; "Neither touches the link. `disable` is the one verb that does." This
   makes the warning a practice rather than only a prohibition.
4. **Scope honesty** (line 356) — the recovery is prescribed after *any* `disable`, `mask`
   or `unmask`, with the reason stated: whether `mask` replaces a stow link "was not
   measured". Recording the unmeasured case rather than guessing is the right call.

Line 360 additionally documents that `is-enabled` printing `linked` while exiting 1 is
correct rather than an error — which I confirmed live above.

---

## Session Symlink State

**Verified by execution.** All four expected links, checked for link-ness with `test -L`
and resolved with `readlink -f`:

| Path | `test -L` | `readlink -f` | Under `stow/`? |
|---|---|---|---|
| `~/.config/systemd/user/hyprland-session.service` | ✓ | `.../.dotfiles/stow/systemd/.config/systemd/user/hyprland-session.service` | ✓ |
| `~/.config/swaync/config.json` | ✓ | `.../.dotfiles/stow/swaync/.config/swaync/config.json` | ✓ |
| `~/.config/swaync/mocha.css` | ✓ | `.../.dotfiles/stow/swaync/.config/swaync/mocha.css` | ✓ |
| `~/.config/swaync/style.css` | ✓ | `.../.dotfiles/stow/swaync/.config/swaync/style.css` | ✓ |

4/4 are symlinks (not plain files), and 4/4 resolve under
`/home/pera/github_repo/.dotfiles/stow/`. The `stow/systemd` and `stow/swaync` packages
hold exactly these four files and nothing else, so coverage is complete — no expected link
is missing and no unexpected file is present. This is the T-17-22 concern (a run replacing
a symlink with a plain file) directly falsified.

---

## Re-check of the Known and Accounted-For Items

### Pre-existing failures — ✓ CONFIRMED PRE-EXISTING, reasoning holds

All three reproduce exactly as described:

```
$ bash scripts/phase11-dispositions-assert.sh
[FAIL] D-01 dispositions file missing: .../11-disposition-decisions/11-DISPOSITIONS.md
=== done: FAIL=1 ===

$ bash scripts/phase10-inventory-assert.sh
[FAIL] D-01 inventory file missing: .../10-full-install-impact-inventory/10-INVENTORY.md
=== done: FAIL=1 ===

$ bash scripts/phase14-verify.sh
[FAIL] baseline fixture missing: .planning/phases/14-live-full-adopt-verify/14-PRE-ADOPT-BASELINE.txt
       ... Aborting rather than comparing against nothing.
```

**The ancestry claim is true:**

```
$ git merge-base --is-ancestor f314491 1f10eee && echo "IS ancestor"
IS ancestor
$ git log --oneline -1 f314491
f314491 chore: archive v0.3 milestone
$ git log --oneline -1 1f10eee
1f10eee docs(17): record planning completion and annotate roadmap waves
```

**And the causal story is visible in the failure messages themselves, which is stronger
evidence than the ancestry alone.** All three failures are *missing-artifact-path* failures
naming `.planning/phases/{10,11,14}-*/` files. `f314491` is titled "chore: archive v0.3
milestone" — archiving is precisely what moves those directories. The scripts hard-code
pre-archive paths. This is a mechanism, not a coincidence, and it is entirely independent
of anything Phase 17 touched: none of the three scripts appears in Phase 17's changed-file
set. **Not a Phase 17 regression.** Correctly logged as D-1 and D-2; D-2 also correctly
notes that no repo-wide sweep for other pre-archive path references has been done.

### The helper units — ⚠️ the brief's premise is partly WRONG; its conclusion survives

I was asked to re-check this and say plainly whether it still holds. **It does not hold as
stated.**

The brief says `systemctl --user show` returns both an empty `ActiveEnterTimestamp` and an
empty `InactiveEnterTimestamp` for each unit, "which means they were never started this
boot". The first half is accurate — I measured it:

| Unit | LoadState | ActiveState | UnitFileState | ActiveEnter | InactiveEnter |
|---|---|---|---|---|---|
| `hyprland-session.service` | loaded | inactive | linked | *(empty)* | *(empty)* |
| `waybar.service` | loaded | inactive | disabled | *(empty)* | *(empty)* |
| `swaync.service` | loaded | inactive | disabled | *(empty)* | *(empty)* |
| `hyprpaper.service` | loaded | inactive | disabled | *(empty)* | *(empty)* |
| `graphical-session.target` | loaded | inactive | static | *(empty)* | *(empty)* |

**But the inference from it is invalid, and the journal proves it:**

```
$ journalctl --user -b -u hyprland-session.service
2026-09-13T16:40:47+06:00 systemd[1417]: Starting Bootstrap graphical-session.target for bare Hyprland...
2026-09-13T16:40:47+06:00 systemd[1417]: Finished Bootstrap graphical-session.target for bare Hyprland.
2026-09-13T16:40:49+06:00 systemd[1417]: Stopped Bootstrap graphical-session.target for bare Hyprland.

$ journalctl --user -b -u graphical-session.target
2026-09-13T16:40:47+06:00 systemd[1417]: Reached target Current graphical user session.
2026-09-13T16:40:49+06:00 systemd[1417]: Stopped target Current graphical user session.
```

Boot was `2026-09-13 16:34:11`. So `hyprland-session.service` and `graphical-session.target`
**did run this boot** — started 16:40:47, stopped 16:40:49. Empty timestamps do not mean
"never started"; systemd garbage-collects an inactive unit and reloads it with no runtime
history, and my own `systemctl show` call is what re-loaded these (note `LoadState=loaded`
where the assert script, running minutes earlier, reported `unloaded`).

The brief's premise is correct only for `waybar.service`, `swaync.service` and
`hyprpaper.service` — those genuinely show `-- No entries --` this boot.

**The conclusion nonetheless survives, on better evidence.** The two-second window at
16:40:47-49 is wave 5's single hand proof of the mechanism, immediately reverted — exactly
what `17-05-SUMMARY.md` describes ("the revert is part of the proof") and what the assert
script's 5e branch predicts by name. The live run of `arch/hyprland.sh` started at
**17:22:39**, forty-two minutes *after* those units were already stopped. So at run time
every one of the five units was inactive, and **the live run stopped nothing.** Correct
conclusion, wrong reason.

The phase's own artifacts are more accurate here than the brief: the assert script's 5e
`[INFO]` line states the started-and-stopped fact explicitly, and `deferred-items.md` D-3
records the stop fan-out. Credit where due — the executor got this right.

**No unit was started, stopped, or restarted during this verification.** Every systemd call
I made was `show`, `is-active`, `is-enabled`, or read-only `journalctl`.

---

## Anti-Pattern Scan

23 non-`.planning/` files changed in this phase (`git diff --name-only 1f10eee..HEAD`).
Scanned all of them:

| Pattern class | Hits |
|---|---|
| `TBD` / `FIXME` / `XXX` (blocker tier) | 1 — false positive |
| `TODO` / `HACK` / `PLACEHOLDER` (warning tier) | 0 |
| "not yet implemented" / "coming soon" | 0 |

The single `XXX` hit is `scripts/phase13-d19-assert.sh:89`:
`TMP="$(mktemp /tmp/p13-d19-XXXXXX.sh)"` — the `mktemp` template placeholder, not a debt
marker. **No debt-marker gate violation.**

Worth noting positively: the marker comment left in `arch/hyprland.sh:33-39` where the
destructive stanza was deleted is *not* a `TODO`. It names its owner (Phase 20, HYPR-01),
its location ("exactly this point in the script"), and what was removed and why. That is a
handoff, not debt.

---

## Code Review Findings — bearing on the criteria

The review is advisory and non-blocking, and per instruction I did not let it downgrade the
verdict. Assessing only whether any finding bears on whether a criterion is *met*:

| # | Finding | Bears on a criterion? |
|---|---|---|
| 1 | `dots-hyprland.sh:461` — symlink refusal aborts an in-flight uninstall (medium) | **No.** Criterion 3 asks for non-zero on repo paths; it gets it. D-07 *specifies* abort-the-run. The finding is about uninstall UX, and D-6 in deferred-items owns it. I independently confirmed the refusal fires and deletes nothing. |
| 2 | `.gitignore:60` — `*.socket` ignores systemd socket units (medium) | **No, but latent.** Criterion 4 asks for the machine-state patterns and `git check-ignore` proves all 17 reach their targets. Real hazard for a *future* phase authoring a `.socket` unit — this repo already stows a `.service`. Correctly carried forward as D-7. |
| 3-8 | assert-script precision issues (low) | **No.** None causes a false PASS on a criterion. #7 (2d regex) and #5 (4d self-scope) could in principle weaken an assertion, but I verified both underlying facts directly rather than through those assertions. |

Findings 1 and 2 are the two mediums, both carried forward in `deferred-items.md`. That
disposition is correct.

---

## What I Could Not Verify, and Why

Stated explicitly, per the three-way distinction requested:

**Unverifiable without an action this phase forbids — 1 item:**

- **Criterion 5's `is-active` clause.** Requires ending and restarting the operator's
  Hyprland session. Forbidden by the verification's hard constraints and impossible for an
  agent in any case. Current measured state: `inactive`, exit 3. Routed to human
  verification. *This is the only success-criterion clause I could not establish.*

**Not read, by instruction — 1 path:**

- `stow/system_monitor/.config/system_monitor/ping/.env` and its `.env.example`. Skipped
  entirely; one of my commands that referenced the path was also blocked by the
  environment's own secret-read guard, which I did not attempt to work around. I
  established only its *tracked status* via `git ls-files` (a filename listing, no content)
  — see finding V-4. Both gitleaks scans cover the path and report clean, so criterion 4's
  claim over it rests on tool evidence, not on my reading it.

**Verified by inspection rather than execution — where behaviour could not be exercised
non-mutatingly:**

- Criterion 6 (documentation content — inherently a reading task).
- Criterion 2's static half (file content; its *behavioural* half was verified by
  execution via the transcript and the live `hyprctl` re-measurement).
- The `execs.lua` handler *firing* at session start — inspected for correctness (right
  handler, right event, one `hl.exec_cmd`) and demonstrated once by the 16:40:47 hand
  proof, but its automatic invocation is part of the same re-login gap as criterion 5.

**Everything else was verified by execution** — I ran the asserts, the scans, the syntax
checks, the `safe_rm_path` fixtures (including one the phase does not have), the symlink
resolutions, the unit-state queries, and the journal reads myself.

---

## Summary

| # | Criterion | Requirements | Status | Method |
|---|---|---|---|---|
| 1 | stow flag sweep, 15 sites / 14 files, `bash -n` clean | FIX-01, CAP-04 | ✓ VERIFIED | execution |
| 2 | `arch/hyprland.sh` clean, runs end-to-end, session survives | FIX-02 | ✓ VERIFIED | execution |
| 3 | `safe_rm_path` refuses any repo path | FIX-04 | ✓ VERIFIED | execution |
| 4 | `.gitattributes`, `.gitignore`, re-runnable clean secret scan | FIX-06 | ✓ VERIFIED | execution |
| 5 | `graphical-session.target` active after fresh login | START-02 | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | blocked on operator re-login |
| 6 | `disable` footgun documented with recovery | START-03 | ✓ VERIFIED | inspection |

**Score: 5/6 verified, 1 present-but-behavior-unverified.**

The phase goal is substantively achieved. The repo's install scripts run (proved by a real
end-to-end run that exited 0 and left the Lua session intact), they can no longer destroy
what the milestone captures (proved by a guard that refused every fixture including one the
phase does not test), and the session target mechanism is in place and byte-identical
across both trees. The single outstanding item is an observation only an operator can make.

**Two actions before phase close:**

1. Operator re-login, then confirm `systemctl --user is-active graphical-session.target`
   returns `active` and phase-17 assert 5e flips to `[PASS]`.
2. Repair the four stale REQUIREMENTS.md markers (finding V-1).

Neither is a defect in the delivered work.

---

_Verified: 2026-09-13 at HEAD `ec6d97d`, clean working tree_
_Verifier: Claude (gsd-verifier) — goal-backward, evidence-first_
_No unit started, stopped or restarted; no installer run; no `sudo`; no `stow` outside `-n` simulate_
