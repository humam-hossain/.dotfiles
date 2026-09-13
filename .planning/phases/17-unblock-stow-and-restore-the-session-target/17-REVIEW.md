---
phase: 17
title: Unblock stow and restore the session target
document: code-review
status: advisory
blocking: false
reviewed-range: origin/main...HEAD
commits-reviewed: 38
findings-total: 8
findings-medium: 2
findings-low: 6
findings-high: 0
generated: 2026-09-13
---

# Phase 17 Code Review

Produced by the `execute:post` `skill:code-review` hook (`when: workflow.code_review`,
`onError: skip`). The hook is advisory: none of the findings below block phase
completion, and none were fixed as part of this review. They are recorded here so
that triage is a deliberate decision rather than an omission.

The reviewing agent could not reach the `ReportFindings` tool in its environment and
returned prose instead. The findings were transcribed here verbatim in substance, and
the two medium-severity ones were re-verified independently against the working tree
before being written down.

## Scope

`git diff origin/main...HEAD`, 38 commits. Code surface, excluding `.planning/` and
`docs/` prose:

- `arch/*.sh` — 15 stow call-site conversions plus two structural changes
- `arch/dots-hyprland.sh`
- `.config/hypr/custom/execs.lua`
- `.gitattributes`, `.gitignore`, `.gitleaks.toml`
- `scripts/phase13-d19-assert.sh`
- `scripts/phase17-unblock-assert.sh` (new, 940 lines)

Working tree was clean at review time; there were no uncommitted changes to fold into
scope.

## Checked and found correct

These were investigated and are *not* findings. They are listed so a later reader does
not re-open them:

- The `hl.on("hyprland.start", …)` coexistence claim in `execs.lua`, verified against
  `/usr/include/hyprland/src/config/lua/LuaEventHandler.hpp`: `m_callbacks` is an
  `unordered_map<string, vector<uint64_t>>`, so multiple subscribers per event are
  supported.
- The D-09 dispatch guard — sourcing has no side effects beyond `set -euo pipefail`.
- The `b32faf6` wrapper drift re-pin — still byte-identical.
- All 15 stow call sites converted, none missed.
- `--no-folding` against an already-folded package, simulated on `qbittorrent`: exits 0,
  no conflict.

Both assert scripts were executed during the review: `phase17-unblock-assert.sh` →
`FAIL=0`, `phase13-d19-assert.sh` → `FAIL=0`.

## Findings

### 1. `arch/dots-hyprland.sh:461` — medium — symlink refusal aborts an in-flight uninstall

The repo-containment clause canonicalises the candidate with `realpath -m`, which
resolves the path's *own* symlink. A symlink that merely *points* into the repository is
therefore refused, even though `rm -rf` on a symlink removes only the link and never
touches its target. The clause's own comment names exactly such a path:
`~/.config/systemd/user/hyprland-session.service`, which is a stow link.

The consequence is not a spurious message. `safe_rm_path` is called bare at
`arch/dots-hyprland.sh:271`, `:280`, `:551`, `:560`, `:566` and `:590`, all under
`set -euo pipefail`, so `return 1` aborts the entire script — mid-uninstall, after
`sudo pacman -R` has already removed the ii meta packages. If any ii config or state
target (for example `$XDG_CONFIG_HOME/quickshell` or `$II_CONFDIR`) ever becomes
stow-managed, `--uninstall` leaves a half-uninstalled system.

Verified: `safe_rm_path` on a scratchpad symlink pointing at the repository's `README.md`
returns 1. Re-verified for this record: `realpath -m` is present at line 461, and every
one of the six call sites is bare.

Suggested fix: resolve only the parent (`realpath --no-symlinks`, or short-circuit on
`[[ -L "$path" ]]`), and decide deliberately whether a refusal should `continue` rather
than kill the run.

### 2. `.gitignore:60` — medium — `*.socket` silently ignores systemd socket units

`*.socket` (alongside `*.sock` and `*.lock`) contains no slash, so it matches at any
depth. `.socket` is the extension of systemd **unit files**, which this repository
authors and tracks under `stow/systemd/.config/systemd/user/`.

Verified independently for this record:

    $ git check-ignore -v --no-index -- stow/systemd/.config/systemd/user/foo.socket
    .gitignore:60:*.socket  stow/systemd/.config/systemd/user/foo.socket

That directory already tracks `hyprland-session.service`. Adding a socket unit beside it
would be skipped by `git add` without a message.

The block's comment justifies these patterns as "runtime sockets and lockfiles", but a
runtime socket does not live inside a stow package. Suggested fix: scope `*.socket` out
of the pattern, or anchor it from the repository root the way the qBittorrent block
above it is anchored.

### 3. `arch/dots-hyprland.sh:504` — low — dry run and real run disagree

The dry-run branch prints `[CONFIG] dry-run: would rm -rf -- $t` without routing through
`safe_rm_path`, so `--dry-run` advertises deletions that the real run refuses. With
finding 1 in place the two disagree in a way that matters: the plan says "would remove",
the real run prints `[FAIL]` and dies. Suggested fix: extract the refusal checks into a
`safe_rm_check` predicate used by both paths.

### 4. `scripts/phase17-unblock-assert.sh:47` — low — criterion 1e can name the wrong defect

Criterion 1e conflates "GNU Stow parses `--verbose=5 --no-folding`" with "the `btop`
package stows cleanly". `stow -n` exits non-zero on any conflict, and btop rewrites
`~/.config/btop/btop.conf` on exit. If that ever replaces the symlink with a real file,
the assert reports `1e GNU Stow rejected --verbose=5 --no-folding` — the wrong diagnosis,
on the only behavioural gate in the section. Suggested fix: use a throwaway fixture
package, or separate a parse error from a conflict by matching stderr.

### 5. `scripts/phase17-unblock-assert.sh:684` — low — 4d self-scope check does not match

The 4d check is `grep -q "gitleaks\\.toml"`, which after shell expansion is the basic
regular expression `gitleaks\\.toml` — a literal backslash, then any character, then
`toml`. It only catches a regex-escaped spelling.

Verified empirically by the reviewer: a `paths = ['''^.gitleaks.toml$''']` entry — an
equally valid gitleaks regex that *does* exempt the config from its own working-tree
scan — is missed, and 4d still reports PASS. Suggested fix: `grep -qF 'gitleaks.toml'`
scoped to the `paths =` lines.

### 6. `scripts/phase17-unblock-assert.sh:511` — low — 4b sweep pins regenerable blobs

The 4b breadth sweep pins two `.planning/research/.cache/*.json` blobs by content hash in
`FIX06_SWEEP_EXPECTED`. Those live under a gitignored-but-tracked directory that GSD
research runs regenerate. A third cached blob becoming tracked, or these two being
pruned, fails the sweep with "a pattern is over-broad, or an expected path moved" — the
wrong diagnosis for a routine planning-artifact change. Suggested fix: derive the cache
expectation with a prefix match instead of pinned filenames.

### 7. `scripts/phase17-unblock-assert.sh:262` — low — 2d regex blocks the hardened form

The 2d hoist regex ends `&& pwd\)"$`, requiring `pwd` with no options. The sibling
wrapper at `arch/dots-hyprland.sh:12` deliberately uses `pwd -P` and documents it as the
hardened form. Hardening `arch/hyprland.sh` the same way would flip 2d to FAIL, claiming
the script "does not resolve its directory changes from one hoisted base" — an assert
that blocks the correct fix. Suggested fix: allow an optional `-P`.

### 8. `scripts/phase13-d19-assert.sh:163` — low — line count, not occurrence count

`EXECS_CMDS="$(grep -c 'hl\.exec_cmd' "$EXECS")"` counts matching *lines*, not
occurrences. The "exactly one `hl.exec_cmd`" claim is therefore defeated by two calls on
one line — which is how an early-landing Phase 20 START-01 entry would plausibly be
squeezed in — and inflated by a commented-out `-- hl.exec_cmd(...)`. Suggested fix:
`grep -o … | wc -l`, as `scripts/phase17-unblock-assert.sh:89` already does correctly,
and exclude `^\s*--` comment lines.

## Disposition

No finding was fixed in this phase. Findings 1 and 2 touch code this phase introduced and
are the two worth scheduling first; findings 4 through 8 are assert-script robustness
issues that would misreport a future defect rather than hide a present one.

The phase's `section_manifest` excludes `gap-closure-artifacts`, so these were not routed
into a gap-closure plan. They are carried forward through this document.
