# Phase 15: Playbook safe vs full - Pattern Map

**Mapped:** 2026-09-05
**Files analyzed:** 5 modified prose files + 1 report artifact
**Analogs found:** 6 / 6

This is a documentation-only phase. "Role" and "data flow" are adapted to prose:
role = the doc's job in the repo, data flow = how truth moves into and out of it.
All analogs are tracked prose or tracked scripts in this repo (verified with
`git ls-files`). No mirror paths.

## File Classification

| Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---------------|------|-----------|----------------|---------------|
| `docs/dots-hyprland-workflow.md` (rewrite in place, D-01) | canonical operator playbook | narrative-over-SoT; cites executable + planning SoTs | itself (current version) + `docs/phase14-adopt-runbook.md` | exact |
| `docs/phase14-adopt-runbook.md` (targeted corrections, D-21) | window record / recovery procedure | frozen procedure, line-level correction only | itself (structure preserved, D-02) | exact |
| `README.md` (line 7, D-20) | discovery pointer | one-line index into `docs/` | `README.md:5-11` (the block itself) | exact |
| `arch/README.md` (review only, D-20) | OS bootstrap reference | none — reviewed, no findings | n/a | reviewed / no change |
| `.planning/PROJECT.md` (lines 18, 28 only, D-22 exception) | product-surface status prose | status line corrections | `PROJECT.md:8,27` (already-correct post-adopt lines) | exact |
| Sweep report (phase artifact or a section of `15-SUMMARY.md` — discretionary) | findings record | read-only review → written findings table | `.planning/phases/15-playbook-safe-vs-full/15-RESEARCH.md` § Doc Sweep Inventory | role-match |

**Not modified, pattern sources only** (scope fence: `arch/`, `scripts/`, `.config/`, `stow/`, `vendor/` read-only this phase):
`scripts/phase14-verify.sh`, `scripts/phase13-d19-assert.sh`, `scripts/phase14-preflight.sh`, `arch/dots-hyprland.sh`.

## Pattern Assignments

### `docs/dots-hyprland-workflow.md` (playbook, rewritten in place)

**Analog:** itself, plus `docs/phase14-adopt-runbook.md` for the newer/cleaner conventions.

**Heading + numbering pattern** — `##` for numbered top sections, `###` for
sub-steps, an explicit `## Outline` anchor list, `---` between top sections,
and a closing `## See also`. Both docs use this identically
(`docs/dots-hyprland-workflow.md:36-48,302`, `docs/phase14-adopt-runbook.md:15,365`):

```markdown
## Outline

1. [Clone & recursive submodule init](#1-clone--recursive-submodule-init)
2. [Verify fork remotes & pin](#2-verify-fork-remotes--pin)
...

---

## 1. Clone & recursive submodule init
```

Anchor form is GitHub-slug with the leading number and doubled hyphen where an
`&` was dropped (`#2-verify-fork-remotes--pin`). Keep it — D-23 link integrity
covers these in-page anchors too.

**DRY / SoT-naming callout** — the sentence that makes D-11's table legal
alongside D-12's prohibition. Present verbatim in both docs
(`docs/dots-hyprland-workflow.md:16`, `docs/phase14-adopt-runbook.md:11`):

```markdown
> **Flag / subcommand details:** keep DRY — run `./arch/dots-hyprland.sh help` for the full
> allowlist, safe defaults, backup gate, uninstall, and protect behavior. This doc does not
> re-copy the entire help text.
```

The runbook's variant extends it with the exception clause — copy that shape
when the playbook needs to say "I name only these flags"
(`docs/phase14-adopt-runbook.md:11`):

> It names only the flags that are *forbidden* (section 4) and the ones the window actually uses.

Callouts are blockquote-bold (`> **Label:** …`), never GitHub `[!NOTE]`
admonitions. The one `[!WARNING]` in the repo is in `README.md:14` (Neovim
section) and is not the docs/ convention — do not adopt it.

**Command block + expected output pattern** — fenced `bash`, expectation as a
`#` comment *inside* the fence, one comment line per expected line
(`docs/dots-hyprland-workflow.md:97-103`):

```bash
git -C vendor/dots-hyprland remote -v
# expect:
#   origin   → personal fork (e.g. git@github.com:humam-hossain/dots-hyprland.git)
#   upstream → end-4 (https://github.com/end-4/dots-hyprland.git)
```

Runbook uses the same idiom compactly (`docs/phase14-adopt-runbook.md:84-86`,
`148-152`):

```bash
./scripts/phase14-preflight.sh
# expect: exit 0, and a [FINDING] line naming ii-original-dots-backup
```

This is the exact shape for the D-15 verify block. Use `# expect: …` — do not
introduce a separate "Output:" block or a two-column table for expected output.

**Literal-value blocks use `text`, not `bash`** — for paths and non-executable
literals (`docs/dots-hyprland-workflow.md:30-32,133-135,147-149,176-179`):

```text
~/ii-original-dots-backup
```

Use `text` for the SAFE_DEFAULTS triple and the backup path; use `bash` only
for things the operator pastes.

**Table pattern** — left-aligned pipe tables, header separator without
alignment colons, bolded first column for emphasis rows
(`docs/dots-hyprland-workflow.md:155-163` and `288-296`):

```markdown
| Subcommand | Role |
|------------|------|
| `install` | Full pipeline (deps + setups + files) + safe defaults + backup gate |
```

Three-column consequence table precedent for D-11's flag axes is
`docs/phase14-adopt-runbook.md:89-94` (Level / Meaning / Moves exit code) and
the Non-goals table's Path / Status / Why. Adopt Axis / Injected / Dropped.

**Citation pattern — two distinct forms, both already in use:**

1. Markdown link, used only in `## See also`
   (`docs/dots-hyprland-workflow.md:303-309`):

```markdown
## See also

- `./arch/dots-hyprland.sh help` — flag and subcommand source of truth
- `vendor/dots-hyprland` — canonical pin path (submodule)
- [`.planning/PROJECT.md`](../.planning/PROJECT.md) — product goals, non-goals, milestone checklist
- Root [`README.md`](../README.md) — cold-clone discovery pointer
```

Note the backticked link text and the em-dash gloss. Executable SoTs are listed
as bare backticks with no link; file SoTs are linked with a repo-relative
`../` path from `docs/`.

2. Bare inline backticked path, used in body prose
   (`docs/dots-hyprland-workflow.md:286`,
   `docs/phase14-adopt-runbook.md:294`): `.planning/REQUIREMENTS.md`,
   `stow/systemd/`. D-13's gate citations of `10-INVENTORY.md` /
   `11-DISPOSITIONS.md` and D-16's `13-SOT-APPLY.md` follow this form in the
   body, and additionally get full linked entries in `See also` (the runbook
   already links both — `docs/phase14-adopt-runbook.md:367-369` — so copy those
   two link lines verbatim, adjusting `../` depth is unnecessary since both docs
   live in `docs/`).

**"Known losses" phrasing pattern** — the D-17 note's analog is
`docs/phase14-adopt-runbook.md:281-303`, which splits into two `###`
sub-lists and leads each bullet with a bolded noun phrase, then the honest
qualifier:

```markdown
### Actually lost, and accepted

- **The personal `hyprland-session.service` autostart.** The unit file itself **survives** — it
  lives under `stow/systemd/` and the symlink in `~/.config/systemd/user/` is untouched. Only the
  `exec-once` line that started it dies with the renamed conf. Consequence: screen share may stop
  working.
```

Two things to carry: (a) the "survives / only X is lost" framing that prevents
overstatement, matching RESEARCH's note that `AvailableSourceTypes` is unchanged
so "screen share **may** be affected" is the accurate wording; (b) the literal
naming of the four autostarts (`google-chrome-stable`, `kitty -e tmux`, `btop`,
`discord`) rather than a summary noun. Never write "chrome" as a category noun
(Phase 14 D-39).

**Prohibition / hazard phrasing pattern** — for D-18's WR-02 role-split hazard
and the `--rotate-backup` post-adopt warning, the analog is
`docs/phase14-adopt-runbook.md:359-363`:

```markdown
### Prohibition

**The upstream vendor tree ships its own removal subcommand. Never use it.** It removes the meta
packages recursively … The three tiers above are the only supported removal paths, and they exist
precisely because the upstream one is unsafe here.
```

Bold imperative first sentence, then the mechanism, then why the safe path
exists. Use this for "do not run `--rotate-backup` post-adopt — it renames away
rollback source 3" (D-19) and for "copy tier-1 source 2 out before escalating to
tier 2" (D-18 / Pitfall 4).

**Non-goals table** — keep the existing `## 6. Non-goals` table shape
(`docs/dots-hyprland-workflow.md:288-296`) and rewrite only the two false rows
identified by RESEARCH (Waybar/rofi/swaync cutover; hyprland.lua takeover).
The bottom-line closer line is part of the pattern:

```markdown
**Bottom line:** update with **§5 pin-bump**, not exp-merge or online cache install.
```

---

### `docs/phase14-adopt-runbook.md` (correction-only edits)

**Analog:** itself. D-02 preserves structure; D-21 corrects falsehoods.

**Edit shape:** in-fence comment corrections at `334-336`, and a post-adopt
caveat sentence at `144` / `117` / `199`. The existing tier-1 fence already
carries long explanatory `#` comments inside the bash block
(`docs/phase14-adopt-runbook.md:316-336`), so the correction is written in the
same in-fence comment voice rather than as new prose above the fence:

```bash
# 3. The rotated backup directory, last because it is the source D-36 exists to distrust.
#    Use the timestamped directory section 5 created, or ~/ii-original-dots-backup/
#    if section 5 did not run.
```

Correction target (RESEARCH Correction 2/3): `~/ii-original-dots-backup` holds
the pre-adopt conf (`3d17932a…`); the timestamped directory holds a July config
(`c5c65023…`). Rewrite the comment to name `~/ii-original-dots-backup` as
source 3 and describe the timestamped directory as the rotated stale backup,
not a rollback source.

**Caveat sentence pattern** for `:144` — the existing sentence is
"…**as it does today**." The repo's precedent for a tense-scoped caveat is the
runbook's own bold-parenthetical style; add a bracketed post-adopt clause in
bold rather than deleting the section (D-02 preserves structure).

---

### `README.md` (one line)

**Analog:** the same block, `README.md:5-11`.

```markdown
**Operator playbook** (clone → recursive submodule → install → dual-run → pin-bump update):

→ [docs/dots-hyprland-workflow.md](docs/dots-hyprland-workflow.md)
```

Pattern: bold label, parenthesised arrow-separated sequence, blank line, then a
`→ [path](path)` pointer line. Keep the arrow-sequence form; replace `dual-run`
with a profile-neutral step (e.g. `install → session → verify`). The link on
line 9 is root-relative without `./` — do not change it (D-23).

---

### `.planning/PROJECT.md` (lines 18, 28 only)

**Analog:** the already-correct post-adopt lines in the same file,
`PROJECT.md:8,27`. Match their tense and density; change only the wrong probe
(`hyprctl getoption configProvider` → `hyprctl -j status` / `configProvider: lua`)
and the wrong backup path (`~/ii-original-dots-backup.20260904T171128Z` →
`~/ii-original-dots-backup`). Nothing else in this file is in scope (D-22).

---

### Sweep report (discretionary location)

**Analog:** `15-RESEARCH.md` § Doc Sweep Inventory — per-file `###` heading,
then a `| Line | Stale text | Disposition |` (or `| Severity |`) table, then a
`[VERIFIED: path:lines]` provenance tag. Files with nothing to fix get an
explicit "reviewed, no findings" statement (RESEARCH does this for
`arch/README.md`) so the record shows the review happened.

## Shared Patterns

### Verify-block / assertion idiom (pattern source only — no new script this phase)

**Source:** `scripts/phase13-d19-assert.sh:9-17` and `scripts/phase14-verify.sh:32-41`
**Apply to:** any inline `<automated>` verify block in the plans. The scope
fence forbids creating `scripts/phase15-docs-assert.sh`, so these are the shape
to mirror inline, not files to add.

```bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

FAIL=0
pass() { printf '[PASS] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
```

`phase14-verify.sh` extends it with two more levels, and the exit-code rule is
explicit in its header (`scripts/phase14-verify.sh:35-39`):

```bash
FINDINGS=0
finding() { printf '[FINDING] %s\n' "$1"; FINDINGS=$((FINDINGS + 1)); }
info() { printf '[INFO] %s\n' "$1"; }
```

Rules carried from `scripts/phase14-verify.sh:12-16`: never `[PASS]` an
unobservable condition — emit `[INFO]` or `[FINDING]`. A grep whose target file
is missing must `fail`, not pass on an empty match. End with a
`=== done: FAIL=$FAIL … ===` line and exit non-zero if `FAIL > 0`.

### Extract-and-run, so prose and check cannot diverge

**Source:** `scripts/phase13-d19-assert.sh:28-42`
**Apply to:** the D-15 verify block, if the planner wants it self-checking.

```bash
FENCE="$(python3 - "$SOT" <<'PY'
from pathlib import Path
import sys
text = Path(sys.argv[1]).read_text()
idx = text.find("## In-repo verify (D-19)")
if idx < 0:
    raise SystemExit("D-19 heading missing")
rest = text[idx:]
start = rest.find("```bash")
end = rest.find("```", start + 7)
if start < 0 or end < 0:
    raise SystemExit("D-19 bash fence missing")
print(rest[start + 7:end].lstrip("\n"), end="")
PY
```

This is the repo's proven answer to "how do you deterministically verify prose".
Given Corrections 1 and 2, it has demonstrable value — a wrong command in the
doc becomes a failing check rather than a latent trap.

### Quoting an executable SoT verbatim rather than paraphrasing

**Source:** `arch/dots-hyprland.sh:12` and `:21`
**Apply to:** the D-11 flag-axis table and the D-14 backup note.

```bash
SAFE_DEFAULTS=(--core --skip-hyprland --skip-sysupdate)
II_BACKUP_DIR="${BACKUP_DIR:-$HOME/ii-original-dots-backup}"
```

Quote these strings byte-for-byte in the playbook so an agreement check
(`grep -oP '^SAFE_DEFAULTS=\(\K[^)]+'` → `grep -qF` in the doc) can prove the doc
has not drifted. CONTEXT.md's own instruction applies: read the current help
text, never restate remembered flags.

### Word-boundary matching in any sweep grep

**Source:** `.planning/PROJECT.md:210` — "Phase 10: Assert harness with
word-boundary D-15 lint | Avoid false positives (`profile` ⊃ `rofi`)"
**Apply to:** every Phase 15 grep for `rofi`. Use `grep -E '\brofi\b'`. The
rewritten playbook will contain "profile" many times by construction (DOC-03).
Likewise the `chrome` ban must exclude `google-chrome-stable`, which the D-17
note legitimately names.

### Scope-fence guard

**Source:** repo convention; asserted the same way both verify scripts assert
non-mutation.
**Apply to:** the phase's final verification.

```bash
git diff --quiet HEAD -- arch/ scripts/ .config/ stow/ vendor/
git diff --quiet HEAD -- scripts/phase14-preflight.sh   # D-19
git diff --quiet HEAD -- .planning/STATE.md .planning/ROADMAP.md  # D-22
```

### Bash style (CONVENTIONS.md, binding on any fence the docs ship)

**Source:** `.planning/codebase/CONVENTIONS.md:48-54,84-90`
- `set -euo pipefail`; 2-space indent; no `set -x` in operator-facing paths.
- `SCREAMING_SNAKE` constants, `snake_case` functions.
- Echo labels `[INSTALL]` `[CONFIG]` `[DONE]` `[PASS]` `[FAIL]` `[SOFT]`.
- "Do not invent a CI linter."
- `REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"` from `arch/` or `scripts/`.

## No Analog Found

None. Every file in scope has a tracked in-repo analog — in most cases the file
itself, since this phase is a correction/rewrite of existing prose rather than
new-surface creation.

One near-miss worth naming for the planner: there is **no existing
documentation-assertion script** in the repo (`scripts/phase*-assert.sh` all
assert code or live state, not prose). RESEARCH proposes
`scripts/phase15-docs-assert.sh`, but the phase scope fence makes `scripts/`
read-only. The verify shapes in RESEARCH § "Concrete command shapes for
`<automated>` verify blocks" should therefore be inlined into the plans' verify
blocks, borrowing the `pass()`/`fail()`/`FAIL` idiom above.

## Metadata

**Analog search scope:** `docs/`, repo root, `arch/`, `scripts/`, `.planning/`
**Files scanned:** 8 (all confirmed git-tracked via `git ls-files`)
**Pattern extraction date:** 2026-09-05
