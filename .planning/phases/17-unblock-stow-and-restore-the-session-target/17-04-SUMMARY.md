---
phase: 17-unblock-stow-and-restore-the-session-target
plan: 04
subsystem: infra
tags: [gitleaks, secret-scan, allowlist, triage, assert-harness, git-history, reachability, dotfiles]

# Dependency graph
requires:
  - phase: 17-03
    provides: "`.gitleaks.toml` carrying the operator's 17-03 checkpoint dispositions, plus criterion 4 sections 4a and 4b in scripts/phase17-unblock-assert.sh and the vacuity-guard idiom they establish"
  - phase: 17-01
    provides: "scripts/phase17-unblock-assert.sh under the D-20 contract — three prefixes, one FAIL counter, closing `=== done: FAIL=n ===`"
provides:
  - "gitleaks 8.30.1-1 installed from Arch `extra`, at /usr/bin/gitleaks, pacman-owned; the 8.x sub-command spellings pinned as `gitleaks git` (history) and `gitleaks dir` (working tree), with `gitleaks detect` recorded as non-existent in 8.x"
  - "a de-blanketed `.gitleaks.toml`: twelve entries, each pinned on path AND on either a line regex or a commit SHA, every one carrying `condition = \"AND\"` and `targetRules`"
  - "two measured gitleaks config defects documented inline in `.gitleaks.toml` — the implicit `condition = \"OR\"` default, and the whole-file skip a global `paths` allowlist causes in `dir` mode"
  - "criterion 4 sections 4c and 4d in scripts/phase17-unblock-assert.sh: both scan surfaces run with --redact, a [FAIL]-on-absent-scanner guard, a pacman-ownership assertion against the name-alike hazard, and five per-entry allowlist-hygiene checks"
  - "both scan surfaces green at source: `gitleaks git .` and `gitleaks dir .` each exit 0"
  - "the operator's Category C verdict on record (both keys dead, no rotation outstanding, no rewrite, no tag touched) and the operator's source-remediation decision on the agentrouter finding"

affects: [17-05, 18-tree-taxonomy, 19]

# Tech tracking
tech-stack:
  added: [gitleaks]
  patterns:
    - "A secret-scanner allowlist entry pins path AND fingerprint component (a line regex, or the commit SHA), never a bare path — so a new credential appearing on the same path is still reported"
    - "`condition = \"AND\"` is mandatory on every entry: the gitleaks default is OR, under which a multi-key entry allowlists any finding matching ANY ONE key. An entry written as path-plus-regex and read as 'this path AND this line shape' actually means 'this whole path, OR that line shape anywhere'"
    - "`targetRules` is mandatory on every entry that carries `paths`: without it a global allowlist makes `gitleaks dir` skip the matching file wholesale before reading a byte of it, and `condition = \"AND\"` does not prevent that"
    - "Both scan surfaces are run, never one: `gitleaks git` walks history and `gitleaks dir` walks the working tree. A file deleted from the tree survives in history and an untracked file exists only in the tree, so a green on one is not a green on the other"
    - "A finding remediated at source gets NO allowlist entry. Suppression is written only for findings that still occur; writing it for a finding that no longer occurs records a decision the scanner would never have asked for"
    - "Reachability is measured before a remedy is chosen. `merge-base --is-ancestor`, `for-each-ref --contains` and `ls-remote` together distinguish 'in main', 'reachable from a published tag' and 'reachable only from a local ref' — three situations with three different correct remedies"
    - "An absent scanner is [FAIL], never a skipped section: an all-green log over a scan that never ran is the same false green as a blanket allowlist, arrived at by absence instead of by config"

key-files:
  created: []
  modified:
    - .gitleaks.toml
    - scripts/phase17-unblock-assert.sh

key-decisions:
  - "Category C (ten history findings, two credentials — a WakaTime key at entropy 3.8638263 and an AccuWeather key at entropy 4.53891) is OPERATOR-dispositioned at the blocking-human checkpoint on 2026-09-12: both keys already dead or never live, no rotation outstanding, tags left alone local and remote, no history rewrite"
  - "No `git filter-repo` was run. None of the seven flagged commits is an ancestor of local HEAD or of origin/main (f3144919), so a rewrite would have rebuilt every one of ~2687 commits to remove commits main does not contain"
  - "Four of the seven (44f9bc38, a5c2f3c5, ba2c4f00, 86de82ea) ARE reachable from tags v0.1, v0.2, v1.0 and v1.1, and `git ls-remote origin` confirms v0.2 and v1.0 are published. The operator chose to leave every tag in place, so those four are allowlisted with that exposure stated in each entry's reason rather than hidden"
  - "Category B (eight findings under .claude/worktrees/) was remediated at source by removing the two stale agent worktrees, and Category A-new (the four antigravity-cli subagent worktrees) the same way. Both were verified gone by re-scan, and NEITHER received an allowlist entry"
  - "A previously unseen finding — an agentrouter token at stow/zsh/.zshrc lines 109-110, commit f1dd7f13 — was escalated rather than dispositioned by the executor. The operator chose source remediation: the four subagent-*-gsd-codebase-mapper-* worktrees and branches holding the only refs to it were removed, and the commit is now unreachable"
  - "Four working-tree findings in the untracked, gitignored .claude/gsd-file-manifest.json were dispositioned by the executor without escalation, because the claim is checkable rather than a judgement: all 735 values are 64-char lowercase hex and the four flagged ones recompute byte-for-byte as sha256 of the file each key names"
  - "The withheld .env block in .gitleaks.toml stays inactive. Neither scan flagged that path, so no entry is needed; a pre-emptive path allowlist would suppress a genuine finding if the file ever gained a real secret"
  - "The history scan stays on the per-commit clock rather than moving behind the per-wave sampling rate: ~2600 commits / ~35 MB in under 3 seconds"

patterns-established:
  - "Pattern: a scanner config is proven by running the scanner against a fixture, not by reading the config. Both defects below were found by measuring what a probe entry actually suppressed, not by inspecting the TOML"
  - "Pattern: the remedy follows the reachability measurement, not the severity of the rule name. Unreachable-from-main plus unreachable-from-any-published-ref means deleting a stale local ref, not rewriting history"
  - "Pattern: the executor escalates a finding it has not been given a verdict on, and dispositions one whose claim it can check by computation"
  - "Pattern: the config must not exempt itself — .gitleaks.toml is tracked, so it sits inside the working-tree surface that proves it holds no matched value"

requirements-completed: [FIX-06]

coverage:
  - id: D1
    description: "gitleaks is installed from Arch extra and is the Arch package rather than a cross-ecosystem name-alike"
    requirement: FIX-06
    verification:
      - kind: integration
        ref: "./scripts/phase17-unblock-assert.sh — [PASS] 4c guard + [PASS] 4c package ownership: /usr/bin/gitleaks is owned by gitleaks 8.30.1-1"
        status: pass
    human_judgment: false
  - id: D2
    description: "Both scan surfaces run with redaction and both return the clean verdict, re-runnably and with no manual step in between"
    requirement: FIX-06
    verification:
      - kind: integration
        ref: "./scripts/phase17-unblock-assert.sh — [PASS] 4c history scan and [PASS] 4c working-tree scan"
        status: pass
      - kind: other
        ref: "two consecutive harness runs — identical closing line `=== done: FAIL=0 ===`"
        status: pass
    human_judgment: false
  - id: D3
    description: "Every allowlist entry carries an adjacent written reason and is narrowly scoped — path AND fingerprint component, with condition = \"AND\" and targetRules on all twelve"
    requirement: FIX-06
    verification:
      - kind: integration
        ref: "./scripts/phase17-unblock-assert.sh — [PASS] 4d guard (12 active entries), [PASS] 4d reasons, [PASS] 4d scoping (12/12 AND, 12/12 targetRules), [PASS] 4d self-scope"
        status: pass
      - kind: other
        ref: "test ! -f .gitleaks.toml || grep -c '^\\s*#' .gitleaks.toml -> 158"
        status: pass
    human_judgment: false
  - id: D4
    description: "No entry contains a secret value: .gitleaks.toml is tracked, no entry names it, so it sits inside the working-tree surface that scans clean"
    requirement: FIX-06
    verification:
      - kind: integration
        ref: "./scripts/phase17-unblock-assert.sh — [PASS] 4d self-scope, together with [PASS] 4c working-tree scan"
        status: pass
    human_judgment: false
  - id: D5
    description: "Sections 4c and 4d are non-vacuous: every assertion was proven capable of failing against a fixture"
    requirement: FIX-06
    verification:
      - kind: manual_procedural
        ref: "PATH symlink farm excluding gitleaks -> [FAIL] 4c guard, both scans correctly skipped rather than passed, `=== done: FAIL=1 ===`"
        status: pass
      - kind: manual_procedural
        ref: "unowned fake gitleaks exiting 1 -> [FAIL] ownership + [FAIL] history + [FAIL] working-tree, `=== done: FAIL=3 ===`; same binary exiting 0 -> [FAIL] ownership alone, `=== done: FAIL=1 ===`"
        status: pass
      - kind: manual_procedural
        ref: "seven doctored .gitleaks.toml fixtures in a scratch repo — absent file, zero entries, zero comments, non-adjacent description, 14-char description, missing AND/targetRules, self-naming path — each turned exactly its own assertion red"
        status: pass
    human_judgment: false
  - id: D6
    description: "The Category C reachability picture is measured, not assumed, and each entry's reason states the exposure honestly"
    requirement: FIX-06
    verification:
      - kind: other
        ref: "git merge-base --is-ancestor <sha> HEAD and origin/main — non-zero for all seven; git tag --contains and git ls-remote origin — v0.2 and v1.0 published and reaching four of them"
        status: pass
    human_judgment: true
    rationale: "Whether the two credentials are genuinely dead is knowable only to the operator, who answered on 2026-09-12. The reachability facts around them are measured; the liveness verdict is testimony and is recorded as such in every entry."
  - id: D7
    description: "Categories B and A-new are remediated at source and carry no allowlist entry"
    requirement: FIX-06
    verification:
      - kind: other
        ref: "post-removal re-scan: gitleaks git . -> 0 findings across 2606 commits; gitleaks dir . -> 0 findings; git for-each-ref --contains f1dd7f13 -> empty"
        status: pass
    human_judgment: false

# Metrics
duration: 22 min
completed: 2026-09-13
status: complete
---

# Phase 17 Plan 04: The Secret Scan and Its Allowlist Summary

**gitleaks installed and pinned, two measured config defects fixed, every finding individually dispositioned — eight allowlisted with their published-tag exposure stated, twelve remediated at source with no suppression written at all — and both scan surfaces asserted in the harness.**

## Performance

- **Duration:** 22 min across two checkpoint escalations
- **Completed:** 2026-09-13
- **Tasks:** 3
- **Commits:** 2
- **Files modified:** 2 (`.gitleaks.toml`, `scripts/phase17-unblock-assert.sh`)

## The two config defects, and why they mattered

Both were found by measuring what a probe entry actually suppressed, not by
reading the TOML. Neither is visible on inspection.

**Defect 1 — `[[allowlists]]` defaults to `condition = "OR"`.** The 17-03
entries were written as `paths` plus `regexes` and read as "this path AND this
line shape". Under the default they meant "this whole path, OR that line shape
anywhere" — a blanket path suppression wearing the costume of a narrow one.
Measured on the real history scan: one probe entry with
`commits=[44f9bc38]` + `paths=[^arch/wakatime\.sh$]` suppressed **1** finding
under `condition = "AND"` and **4** under the default.

**Defect 2 — a global allowlist carrying `paths` makes `gitleaks dir` skip the
file wholesale**, before reading a byte of it, and `condition = "AND"` does not
prevent it. Only `targetRules` does. Measured with a fixture holding a
live-shaped `export ANTHROPIC_API_KEY=<40 random characters>` at
`stow/zsh/.zshrc`: the built-in ruleset reported it ("scanned ~66 bytes, leaks
found: 1"), and under the 17-03 config it went **completely unseen** ("scanned
~0 bytes, no leaks found", with `DBG skipping file: global allowlist
path=stow/zsh/.zshrc`). This was not hypothetical — `debian/wakatime.sh`,
`ubuntu/wakatime.sh` and `arch/wakatime.sh` all exist in the working tree and
were in line to be blinded the same way.

Defect 1 was actively hiding two real findings, which is how the agentrouter
token below came to light.

## The findings, by category and by disposition

| Category | Count | Where | Disposition |
| --- | --- | --- | --- |
| A | 4 | `.claude/gsd-file-manifest.json`, working tree | Allowlisted on proof — sha256 digests, not credentials |
| B | 8 | `.claude/worktrees/`, working tree | **Remediated at source.** No allowlist entry |
| C | 10 | 5 paths across 7 history commits | Allowlisted, 8 entries, operator verdict |
| A-new | 2 | `stow/zsh/.zshrc` lines 109-110, commit `f1dd7f13` | **Remediated at source.** No allowlist entry |

**Category A — decided by the executor, not escalated,** because the claim is
checkable rather than a judgement. All 735 values in the manifest are exactly 64
lowercase hex characters, and the four flagged ones recompute byte-for-byte as
`sha256` of the file each key names, against both the repo-local and the
user-level `.claude` runtime root. The rule fires because those *key names*
contain credential-shaped words (`secrets`, `token`, `api`) next to a
high-entropy value. The file is untracked and gitignored, so it cannot reach a
commit.

**Category B — remediated, then verified gone.** The two stale agent worktrees
under `.claude/worktrees/` were removed on the operator's decision. The
working-tree scan was re-run afterwards and no finding under that path remains.
Because they no longer occur, **no suppression was written for them** — an
allowlist entry for a finding the scanner would never raise again records a
decision nobody asked for, and would quietly outlive the reason for it.

**Category C — the operator's call, with the exposure stated in every entry.**
Two credentials: a WakaTime API key (entropy 3.8638263) across the three
`wakatime.sh` installers, and an AccuWeather API key (entropy 4.53891) across
the two `waybar/config.jsonc` files. The operator's verdict on 2026-09-12: both
keys already dead or never live; leave the tags alone.

The reachability picture was measured before any remedy was considered, and it
changed the remedy entirely:

- **None** of the seven commits is an ancestor of local `HEAD` or of
  `origin/main` (= `f3144919`). Main's history is already clean of them. A
  `git filter-repo` would have rewritten every one of ~2687 commits in order to
  remove commits that main does not contain.
- **Four** of the seven — `44f9bc38`, `a5c2f3c5`, `ba2c4f00`, `86de82ea` — are
  reachable from tags, and `git ls-remote origin` shows v0.2 (peeled
  `bad5111f`) and v1.0 (peeled `0a7942bf`) are **published** on
  `git@github.com:humam-hossain/.dotfiles.git`. Per-tag reach: v0.1 4/7
  (unpushed), v0.2 4/7 (pushed), v0.3 0/7, v1.0 4/7 (pushed), v1.1 4/7
  (unpushed).

So each of the eight entries carries the honest framing rather than a
reassuring one: *reachable from published tags v0.2 and v1.0 but not from main;
credential confirmed dead by the operator on 2026-09-12; no rewrite performed
by operator decision.* Each pins one commit AND one path under
`condition = "AND"`. A line regex is deliberately not used: the only regex that
would pin the line further is the secret value itself, and writing a matched
value into this file is prohibited.

## The finding nobody had seen

With defect 1 fixed, the history scan surfaced two findings that the OR-default
had been suppressing: an **agentrouter** token — not a first-party Anthropic
key — at `stow/zsh/.zshrc` lines 109-110, commit `f1dd7f13` ("refactor: migrate
dotfiles management to GNU Stow", 2026-08-14), entropy 4.907336, one distinct
value across both lines. Today's `.zshrc` carries `REDACTED` on the
corresponding lines, so it was redacted later.

This was escalated rather than dispositioned: the executor had no verdict on it
and one was not inferable.

Exposure, measured:

- Not an ancestor of `HEAD`, not of `origin/main`.
- **No tag reaches it**, local or published. `ls-remote origin` returns exactly
  three refs — `main`, `v0.2`, `v1.0` — and none reaches it.
- Value absent from the working tree and from `origin/main`.
- Reachable from exactly four refs:
  `subagent-{Arch,Concerns,Quality,Tech}-Focus-Mapper-gsd-codebase-mapper-*`,
  all four at commit `6094683`, checked out in worktrees under
  `~/.gemini/antigravity-cli/`. Those worktrees were registered in **this**
  repo's `git worktree list`; antigravity-cli owned only the checkout
  directories.
- That history line is **disjoint** from main: `git merge-base 6094683
  origin/main` returns nothing. 845 commits on that side, 1027 on main, zero
  shared. All four worktrees were clean and untouched since 2026-08-14.
- Diagnostic: restricted to `HEAD`'s ancestry with no allowlist at all, the
  whole repo scans to zero. Every one of the baseline findings lives off main.

**Operator decision: remediate at source.** The four worktrees were removed and
the four branches deleted. `git for-each-ref --contains f1dd7f13` now returns
empty, and the post-removal history scan reads 2606 commits and reports no
leaks. No allowlist entry was written for it, and no tag was touched.

## Task Commits

| Task | Commit | Subject |
| --- | --- | --- |
| 1 | (no repo delta) | gitleaks 8.30.1-1 installed from Arch `extra`; sub-command spellings pinned |
| 2 | `be1a28a` | fix(17-04): de-blanket the gitleaks allowlist and disposition triaged findings |
| 3 | `99a7314` | test(17-04): assert criterion 4c/4d with both scan surfaces and per-entry reasons |

## What 4c and 4d assert

**4c — the scanner itself.** A `[FAIL]` when `gitleaks` is not on `PATH`, never
a silent skip. A `pacman -Qo` ownership assertion, so the cross-ecosystem
name-alike hazard is a checked claim rather than an assumption — `gitleaks`
also names an unrelated npm package, and resolving on `PATH` proves only that
something answers to the name. Then both invocations, each carrying `--redact`
so no matched value can reach stdout even on a failure dump, and neither
carrying `--report-path` so neither writes a file. Both surfaces are run
because they cover different things.

**4d — the allowlist's hygiene,** conditional per D-11: with no accepted
findings there is no config and the section emits `[INFO]`, not `[PASS]`,
because nothing was verified. When the config exists it asserts a non-zero entry
count (so the per-entry checks cannot pass vacuously), the presence of comment
lines, that every entry is *immediately* followed by a `description` of at least
40 characters — adjacency is the point, since a reason three entries away cannot
be matched to the entry it excuses, and the 40-character floor rejects "false
positive" and "not a secret", which record a verdict without recording why —
that all twelve entries carry both `condition = "AND"` and `targetRules`, and
that no entry names `.gitleaks.toml` itself.

## Non-vacuity evidence

Every new assertion was proven capable of failing, against fixtures only. No
safety clause was disabled in a real script and no fixture ran a recursive
delete.

| Fixture | Result |
| --- | --- |
| `PATH` symlink farm excluding gitleaks | `[FAIL] 4c guard`; both scans skipped rather than passed; `FAIL=1` |
| Unowned fake `gitleaks` exiting 1 | `[FAIL]` ownership + history + working-tree; `FAIL=3` |
| Same fake exiting 0 | `[FAIL]` ownership alone; `FAIL=1` |
| `.gitleaks.toml` absent | `[INFO]` branch, no `[PASS]` claimed |
| Config with zero `[[allowlists]]` | `[FAIL] 4d guard` |
| Config with zero comment lines | `[FAIL] 4d` comments |
| Entry whose next line is not a `description` | `[FAIL] 4d` reasons |
| `description = "false positive"` (14 chars) | `[FAIL] 4d` reasons |
| Entry missing `condition`/`targetRules` | `[FAIL] 4d scoping` |
| Entry naming `.gitleaks.toml` | `[FAIL] 4d self-scope` |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] The 17-03 allowlist entries had to be rewritten
before the scan could be trusted.** The plan's task 2 assumed the existing
entries were correctly scoped. They were not — see the two defects above — and
a scan run against them would have produced a green that proved nothing. The
de-blanketing landed in `be1a28a` before any triage was recorded.

**2. [Rule 1 - Blocking] A second `blocking-human` checkpoint was raised that
the plan did not anticipate.** The agentrouter finding was invisible until
defect 1 was fixed, so no plan written before that point could have scheduled a
decision for it. It was escalated rather than dispositioned, and the operator
chose source remediation.

**3. [Rule 3 - Blocking] The stale-header comment above section 4a said 4c and
4d were "deliberately ABSENT".** True when 17-03 wrote it, false once this plan
landed them. Updated in `99a7314` to point at the new sections instead.

---

**Total deviations:** 3 auto-fixed (2 blocking, 1 missing critical)
**Impact on plan:** No scope creep. Deviations 1 and 2 are consequences of the
same config defect; deviation 3 is a comment kept truthful.

## Issues Encountered

**`scripts/phase14-verify.sh` exits 1 — pre-existing, deferred, not fixed.**
Unchanged from 17-03. It hard-codes a baseline fixture path that
`f314491 chore: archive v0.3 milestone` relocated. Logged as D-1 in
`deferred-items.md`.

This is now the third phase-17 wave to meet a script hard-coding a pre-archive
`.planning/phases/` path — 17-02 fixed the same defect in
`phase13-d19-assert.sh`, and D-1 records it in `phase14-verify.sh`. A sweep for
the pattern belongs in Phase 18; it is out of scope here.

## Known Stubs

None. The withheld `.env` block in `.gitleaks.toml` remains commented out on
purpose, and both scans confirmed it is not needed: neither surface flagged that
path.

## Threat Flags

- **T-17-03 (spoofing, cross-ecosystem homonym) — mitigated and asserted.** The
  binary is asserted pacman-owned in 4c, not merely present. `git status`
  carries no npm lockfile.
- **Residual, accepted by the operator:** two credentials remain reachable from
  published tags v0.2 and v1.0. The operator's verdict is that both are dead.
  Should either turn out to be live, the allowlist is what would keep the
  scanner quiet about it — the entries name the exposure explicitly so a later
  reader can re-open the question.

## User Setup Required

None outstanding. `gitleaks` was installed by the operator during this plan
(`sudo pacman -S --needed gitleaks`) and is now a prerequisite for a green
harness run: its absence is reported as `[FAIL] 4c guard`.

## Next Phase Readiness

**Ready for 17-05.** It inherits a harness closing `=== done: FAIL=0 ===` with
criteria 1, 3, 4a, 4b, 4c and 4d all live, a working tree and a git history that
both scan clean, and `.gitleaks.toml` as the written record of every accepted
finding.

**Open, not blocking:** `scripts/phase14-verify.sh` (deferred-items.md D-1), and
the hard-coded-archive-path sweep suggested for Phase 18.

## Self-Check: PASSED

- `.gitleaks.toml` — found on disk, 12 active `[[allowlists]]`, all with
  `condition = "AND"` and `targetRules`.
- `scripts/phase17-unblock-assert.sh` — found, `bash -n` clean, closes
  `=== done: FAIL=0 ===` on two consecutive runs with identical closing lines.
- `gitleaks git .` and `gitleaks dir .` — both exit 0.
- Commits `be1a28a` and `99a7314` — both present in `git log`.
- Sibling suites re-run: `phase16-retire-assert.sh` closes
  `=== done: FAIL=0 ===`; `phase13-d19-assert.sh` closes
  `=== Phase 13 asserts: FAIL=0 ===`.
- All task `<acceptance_criteria>` re-run and passing; all plan `<verify>`
  commands re-run, with the single `phase14-verify.sh` failure documented above
  as pre-existing and out of scope.

---
*Phase: 17-unblock-stow-and-restore-the-session-target*
*Completed: 2026-09-13*
