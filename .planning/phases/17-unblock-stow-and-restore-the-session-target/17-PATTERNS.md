# Phase 17: Unblock stow and restore the session target - Pattern Map

**Mapped:** 2026-09-12
**Files analyzed:** 21 (1 new script, 1 new dotfile, 19 modified)
**Analogs found:** 20 / 21

This is a bash + dotfiles repo. "Role" means script role (installer, library, assert
harness, config overlay, git metadata, doc), not class/module. Every analog path below was
checked with `git ls-files` and is tracked source — no gitignored mirrors.

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `scripts/phase17-unblock-assert.sh` (**new**) | assert harness | batch / read-only probe | `scripts/phase16-retire-assert.sh` | exact (locked by D-20) |
| `arch/{xterm,kitty,zsh_powerlevel,yazi,btop,alacritty,nvim,define,rofi,wezterm,tmux,zsh,fish}.sh` (13 files, 13 call sites) | installer | file-I/O (symlink placement) | each other — `arch/alacritty.sh:9` is the canonical one-liner | exact (all 15 sites byte-identical in shape) |
| `arch/hyprland.sh` (2 call sites + D-03 deletion) | installer | file-I/O | `arch/waybar.sh:1-7` (for the `REPO_ROOT`/`set -x` header idiom) | role-match |
| `arch/dots-hyprland.sh` — `safe_rm_path` guard | library function | file-I/O (destructive gate) | the function's **own existing two `case` clauses** at lines 434-453 | exact (in-file self-analog) |
| `arch/dots-hyprland.sh` — dispatch guard | script entrypoint | control-flow | `arch/dots-hyprland.sh:805` `main "$@"` (the line being replaced) | exact |
| `.gitattributes` (**new**) | git metadata | config | none in repo | **no analog** — D-10 dictates content verbatim |
| `.gitignore` | git metadata | config | its own `stow/qbittorrent/…` block (lines 8-13) | exact (in-file self-analog) |
| `.config/hypr/custom/execs.lua` | config overlay | event-driven | `~/.config/hypr/hyprland/execs.lua` (vendor, untracked-by-parent) for block shape; `.config/hypr/custom/general.lua:1` for the SoT header | exact (two-source composite) |
| `docs/dots-hyprland-workflow.md` (START-03 block) | doc | prose | §8 "Known losses" (line 335ff) + the `> **Label:**` blockquote at lines 18-19 | exact |
| `docs/phase14-adopt-runbook.md:247` (F-7, 16th `-v=5`) | doc | prose | the `arch/*.sh` call-site form | role-match |

---

## Pattern Assignments

### `scripts/phase17-unblock-assert.sh` (assert harness, read-only batch)

**Analog:** `scripts/phase16-retire-assert.sh` — locked by D-20. Copy structurally.

**Header + non-mutating note** (`scripts/phase16-retire-assert.sh:1-19`) — reproduce this
shape with Phase 17 wording:

```bash
#!/usr/bin/env bash
# Phase 16 retirement contract asserts (D-35).
# Asserts the full-only install path: a bare invocation carries no residual
# profile flags, --full is accepted but never forwarded, ...
#
# Usage (from REPO_ROOT):
#   ./scripts/phase16-retire-assert.sh
# Exit 0 if all hard asserts pass; non-zero if any hard FAIL.
#
# Constraints (Phase 16):
#   - Non-mutating: syntax checks and --dry-run argv captures only.
#   - Never runs a live install, a live uninstall, or any package operation.
```

**Preamble + helpers** (`scripts/phase16-retire-assert.sh:21-28`) — copy verbatim, then add
one `info()` (see below):

```bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

FAIL=0
pass() { printf '[PASS] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
```

**`info()` helper** — D-23 needs `[INFO]`, which Phase 16 does not define. Take it verbatim
from `scripts/phase14-verify.sh:41` (and only this one line from that file):

```bash
info() { printf '[INFO] %s\n' "$1"; }
```

**Banner** (`scripts/phase16-retire-assert.sh:43`):

```bash
echo "=== Phase 16 retirement contract (non-mutating) ==="
```

**Syntax-check section** (`scripts/phase16-retire-assert.sh:45-50`) — this is the exact
shape criterion 1's `bash -n` clause wants, looped over the 14 `arch/*.sh` files:

```bash
# --- syntax ---
if bash -n arch/dots-hyprland.sh; then
  pass "syntax: bash -n arch/dots-hyprland.sh"
else
  fail "syntax: bash -n arch/dots-hyprland.sh"
fi
```

**Ban-grep section with a vacuity guard** (`scripts/phase16-retire-assert.sh:251-264`) — the
model for every "no `-v=5` survives", "no `cp -rf .config/hypr/*` survives" check. Note the
**input guard first**: a ban-grep over a missing file passes vacuously, so existence is
asserted before the ban. Reuse this pairing for the D-22 grep gate and the FIX-02 bans:

```bash
# --- input guard: a ban-grep over a missing file passes vacuously ---
if [[ -s "$PLAYBOOK" ]]; then
  pass "D-36 playbook $PLAYBOOK exists and is non-empty"
else
  fail "D-36 playbook $PLAYBOOK is missing or empty (a ban-grep over it would pass vacuously)"
fi

# --- D-36 file-wide ban: the retired session-model term ---
if grep -niE 'dual-run' "$PLAYBOOK" >/dev/null; then
  fail "D-36 playbook still names the retired session model (dual-run)"
  grep -niE 'dual-run' "$PLAYBOOK" || true
else
  pass "D-36 playbook is free of the retired session-model term"
fi
```

The `grep … || true` echo of offending lines on the failure branch is part of the pattern —
every `fail()` in this script prints the evidence that produced it.

**Scope-limited grep via extraction** (`scripts/phase16-retire-assert.sh:286-302`) — the
precedent for F-7's docs-scoped grep that must not go red on the frozen
`.planning/research/PITFALLS.md` copy. Phase 16 extracts a section and greps the extraction,
asserting the extraction is non-empty so the ban cannot pass vacuously:

```bash
UPDATE_SECTION="$(awk '/^## [0-9]+\. .*[Uu]pdate contract/,/^## [0-9]+\. [^U]/' "$PLAYBOOK")"
if [[ -n "$UPDATE_SECTION" ]]; then
  pass "D-36 update-contract section extracted from the playbook (non-empty)"
  ...
else
  fail "D-36 update-contract section extraction is empty (the ban would pass vacuously)"
fi
```

For Phase 17 the equivalent scoping is by **path list**, not by awk range: grep
`arch/ docs/` explicitly, never `-r` from `REPO_ROOT`.

**Tail** (`scripts/phase16-retire-assert.sh:303-307`) — copy verbatim, this is the D-20
closing contract:

```bash
echo "=== done: FAIL=${FAIL} ==="
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
```

**Tempfile + trap pattern** (`scripts/phase16-retire-assert.sh:32-41`) — available if a
section needs to capture output, but Phase 17 likely does not: its probes are greps and
`cmp`, not argv captures. Do not copy the `mktemp` block unless a section actually needs it.

```bash
INSTALL_OUT="$(mktemp /tmp/p16-retire-install-XXXXXX)"
# shellcheck disable=SC2064
trap 'rm -f "$INSTALL_OUT" ...' EXIT
```

---

### CONTRACT DIVERGENCE — do not mix the two assert contracts

`scripts/phase14-verify.sh` uses a **different** contract from the one D-20 locks. The
planner must not blend them.

| | `phase16-retire-assert.sh` (**D-20 governs**) | `phase14-verify.sh` (do NOT copy wholesale) |
|---|---|---|
| Prefixes | `[PASS]` `[FAIL]` `[INFO]`* | `[PASS]` `[FAIL]` `[FINDING]` `[INFO]` |
| Counters | one: `FAIL` | two: `FAIL` and `FINDINGS` |
| Closing line | `=== done: FAIL=${FAIL} ===` | `=== done: FAIL=${FAIL} FINDINGS=${FINDINGS} ===` |

\* Phase 16 does not actually define `info()`; D-20's three-prefix contract requires Phase 17
to add it. Borrow **only** `scripts/phase14-verify.sh:41` for that, and take nothing else
from that file — in particular **no `finding()`, no `FINDINGS` counter, and no
`FINDINGS=n` in the closing line**.

`phase14-verify.sh:439-445` is where the D-38 finding text lives and is worth reading as
prior art for criterion 5's wording, but D-23 reclassifies that condition from `finding()`
to `info()`:

```bash
if systemctl --user is-active graphical-session.target >/dev/null 2>&1; then
  info "D-38 graphical-session.target is active"
else
  finding "D-38 graphical-session.target is inactive — hyprland-session.service lost its autostart with the renamed conf (expected). ..."
fi
```

Phase 17's version keeps the `if systemctl --user is-active … >/dev/null 2>&1` probe verbatim,
routes the true branch to `pass()` and the false branch to `info()` (D-23), and the message
names the operator re-login as the required step.

`phase14-verify.sh:460-465` is the analog for the session-unit path check:

```bash
SESSION_UNIT="stow/systemd/.config/systemd/user/hyprland-session.service"
if [[ -f "$SESSION_UNIT" ]]; then
  info "D-38 the personal session unit file SURVIVES in the repo at $SESSION_UNIT — ..."
```

---

### `arch/*.sh` — the 15 stow call sites (installer, file-I/O)

**Analog:** every site is the same line. Canonical form, `arch/alacritty.sh:9`:

```bash
cd "$(dirname "${BASH_SOURCE[0]}")/../stow" && stow -v=5 -t ~ alacritty
```

Target form (D-01 + CAP-04) — flags-only, `cd` idiom kept verbatim:

```bash
cd "$(dirname "${BASH_SOURCE[0]}")/../stow" && stow --verbose=5 --no-folding -t ~ alacritty
```

Full site list with file:line is quoted verbatim at `17-RESEARCH.md` §F-1. Two traps the
planner must encode:
- `arch/zsh.sh:43` and `arch/zsh_powerlevel.sh:61` both stow package `zsh`. Decompose by
  **call site**, never by package, or one edit is missed.
- Line numbers in `arch/hyprland.sh` shift from 29/33 to 26/30 once D-03 deletes lines 24-26.
  Write every task and every grep against **content**, not line number.

---

### `arch/hyprland.sh` (installer, file-I/O)

**Deletion target** (`arch/hyprland.sh:24-26`, quoted verbatim):

```bash
echo "[CONFIG] Hyprland Config"
mkdir -p ~/.config/hypr
cp -rf .config/hypr/* ~/.config/hypr/
```

**Surrounding section-comment idiom to match when writing the D-03 marker** — the file
labels each stanza with a bracketed echo (`arch/hyprland.sh:28`, `:32`):

```bash
echo "[CONFIG] Graphical Session Bootstrap (systemd xdg-desktop-portal fix)"
cd "$(dirname "${BASH_SOURCE[0]}")/../stow" && stow -v=5 -t ~ systemd
systemctl --user daemon-reload || true
```

The marker comment (Claude's discretion per CONTEXT) should sit where lines 24-26 were, as a
`#` comment naming Phase 20 / HYPR-01 — not as an `echo`, since it must produce no runtime
output.

**`REPO_ROOT` header idiom** if the F-3 second-`cd` fix is taken up — `arch/waybar.sh:1-7`,
the only `arch/*.sh` that already hoists a root:

```bash
#!/usr/bin/env bash
set -euo pipefail
set -x

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WAYBAR_SRC="$REPO_ROOT/stow/waybar/.config/waybar"
WAYBAR_DST="$HOME/.config/waybar"
```

Note this is `pwd`, not `pwd -P`. D-06 adds `-P` for the `safe_rm_path` guard specifically.

---

### `arch/dots-hyprland.sh` — `safe_rm_path` repo guard (library, destructive gate)

**Analog: the function's own existing clauses.** The new guard is a *third* `case` in the
same shape, not a new function. Existing body, verbatim (`arch/dots-hyprland.sh:427-450`):

```bash
# Remove path if it exists; refuse anything outside $HOME.
safe_rm_path() {
  local path="$1"
  if [[ ! -e "$path" && ! -L "$path" ]]; then
    echo "[UNINSTALL] skip (missing): $path"
    return 0
  fi
  case "$path" in
    "$HOME"/*) ;;
    *)
      echo "[FAIL] Refusing to delete path outside \$HOME: $path" >&2
      return 1
      ;;
  esac
  # Extra belt: never hypr
  case "$path" in
    */.config/hypr|*/.config/hypr/*)
      echo "[FAIL] Refusing to delete hypr path: $path" >&2
      return 1
      ;;
  esac
  echo "[UNINSTALL] rm -rf -- $path"
  rm -rf -- "$path"
}
```

Copy from this: the `# Extra belt: …` comment style, the `echo "[FAIL] Refusing to … : $path" >&2`
message shape, the `return 1`, and the `case`-based placement. Three constraints from research:
1. The new clause must come **after** the `$HOME/*` allow-list — the repo lives at
   `/home/pera/github_repo/.dotfiles`, so every repo path already passes that clause.
2. The early `! -e && ! -L` return fires before any refusal, so the D-21 fixture must use
   paths that **exist**: `$REPO_ROOT/README.md`, `$REPO_ROOT/stow`,
   `$REPO_ROOT/vendor/dots-hyprland`.
3. D-05 wants `realpath -m` on both sides, which a `case` glob cannot express — this clause
   is an `if [[ "$resolved" == "$resolved_root"/* || "$resolved" == "$resolved_root" ]]`
   rather than a literal `case`, while keeping the message and `return 1` shape above.

**`REPO_ROOT` derivation (D-06)** — same idiom as `arch/waybar.sh:5` and
`scripts/phase16-retire-assert.sh:23`, plus `-P`:

```bash
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
```

`arch/dots-hyprland.sh` already defines a global `REPO_ROOT` (lines 9-20) — confirm whether
this is a new assignment or a `-P` upgrade of the existing one before planning the edit.

---

### `arch/dots-hyprland.sh` — dispatch guard (entrypoint, control-flow)

**Current tail** (`arch/dots-hyprland.sh:805`, preceded by the `case` in `main`):

```bash
    *)
      run_install_family "$subcmd" "$@"
      ;;
  esac
}

main "$@"
```

**Replacement — use the `if … fi` spelling, NOT the `&&` spelling CONTEXT D-09 writes.**
Research §F-5 falsified the `&&` form live: as the last statement of a sourced file it leaves
the source's return status at 1 and aborts a `set -e` caller, which silently defeats D-21.

```bash
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
```

**D-21 fixture shape** (from §F-5's two consequences) — subshell-contained because the
wrapper's global `REPO_ROOT` collides with the assert script's, and `if`-tested because a
bare call plus `rc=$?` trips `set -e`:

```bash
if ( source ./arch/dots-hyprland.sh >/dev/null 2>&1; safe_rm_path "$REPO_ROOT/README.md" ); then
  fail "FIX-04 safe_rm_path accepted a path inside the repo: README.md"
else
  pass "FIX-04 safe_rm_path refuses a path inside the repo: README.md"
fi
```

---

### `.config/hypr/custom/execs.lua` (config overlay, event-driven)

Currently 1 byte (empty). Two analogs compose the target file.

**SoT header** — `.config/hypr/custom/general.lua:1`, copy verbatim (D-18):

```lua
-- Authoring SoT: parent-repo .config/hypr/custom/ (see 13-SOT-APPLY.md). Do not commit into vendor/dots-hyprland.
```

**Block shape** — the vendor file `~/.config/hypr/hyprland/execs.lua:1-2,26` (read-only
reference; it is vendor-owned and stays untouched per D-16):

```lua
-- put former exec-once commands inside the func and former exec commands outside
hl.on("hyprland.start", function ()

    -- Bar, wallpaper
    hl.exec_cmd("$HOME/.config/hypr/hyprland/scripts/start_geoclue_agent.sh")
    ...
end)
```

**Target content (D-15/D-16):** header comment, then one `hl.on("hyprland.start", function () … end)`
block containing exactly one line:

```lua
hl.exec_cmd("systemctl --user start hyprland-session.service")
```

Ported from `.config/hypr/hyprland.conf:57`
(`exec-once = systemctl --user start hyprland-session.service`). The six other `exec-once`
entries are START-01 / Phase 20 — they must **not** appear.

**Overlay wiring proof** — `~/.config/hypr/hyprland.lua:15,22-24` shows both handlers register
against the same event, vendor first:

```lua
require("hyprland.execs")
...
if is_file_exists(HOME .. "/.config/hypr/custom/execs.lua") then
    require("custom.execs")
end
```

---

### `.gitignore` (git metadata, config)

**Analog: its own `stow/qbittorrent/…` block** (`.gitignore:8-13`) — fully-qualified,
tree-scoped paths under a `#` section header. D-14's machine-state patterns follow this shape:

```
# qBittorrent state and lock files
stow/qbittorrent/.config/qBittorrent/lockfile
stow/qbittorrent/.config/qBittorrent/ipc-socket
stow/qbittorrent/.config/qBittorrent/qBittorrent-data.conf
stow/qbittorrent/.config/qBittorrent/rss/storage.lock
stow/qbittorrent/.config/qBittorrent/rss/articles/
```

**Anti-pattern in the same file** (`.gitignore:1-2`) — do **not** copy this shape:

```
.config/system_monitor/ping/data/
.config/system_monitor/ping/.env
```

Research §F-8 falsified these: a pattern with a non-trailing `/` is anchored to the
repo root, so neither reaches the tracked `stow/system_monitor/.config/system_monitor/ping/.env`.
Repo-root `.config/system_monitor/` does not exist at all. Every new pattern must be written
tree-qualified like the qbittorrent block, and note that `.gitignore` never untracks an
already-tracked file (`.config/kdeglobals`, §F-9).

---

### `docs/dots-hyprland-workflow.md` — START-03 warning block (doc)

**Placement analog:** §8 "Known losses after the full adopt" (line 335ff), which is the D-38
narrative D-19 places this beside. Its bullet shape — **bold lead, then what survives, then
the consequence** — is the house style:

```markdown
- **The personal `hyprland-session.service` autostart.** The unit file itself **survives** — it lives under `stow/systemd/` and the symlink in `~/.config/systemd/user/` is untouched. What died with the renamed conf is the `exec-once` line that started it, so `graphical-session.target` is now inactive.
```

**Warning-block analog:** the `> **Label:** …` blockquote at lines 18-19:

```markdown
> **Flag / subcommand details:** keep DRY — run `./arch/dots-hyprland.sh help` for the allowlisted subcommands, the two wrapper-owned meta flags and the uninstall flags.
```

**Recovery-subsection analog:** `### Recovery after a bad install` (line 358) — an `###`
heading under the relevant `##` section, prose first, then the single route. D-19's recovery
command block:

```bash
stow --verbose=5 --no-folding -t ~ systemd
systemctl --user daemon-reload
```

The block must also name `systemctl --user mask` as the safe alternative to `disable` for a
stow-managed unit.

**Expected-output convention** (line 327-328) — reuse for the Phase 17 assert script if the
doc names it:

```markdown
./scripts/phase14-verify.sh
# expect: === done: FAIL=0 FINDINGS=1 ===   (the 1 finding is the D-38 known loss)
```

Phase 17's expectation is `=== done: FAIL=0 ===` (three-prefix contract, no FINDINGS).

---

### `docs/phase14-adopt-runbook.md:247` (doc, F-7)

**Current:**

```
cd stow && stow -R -v=5 -t ~ kitty
```

**Target** — apply the same flags-only edit as the `arch/` sites, preserving `-R`:

```
cd stow && stow -R --verbose=5 --no-folding -t ~ kitty
```

`.planning/research/PITFALLS.md:475` carries the same string inside a frozen research
artifact — do **not** edit it (Phase 16 frozen-record precedent), and scope the assert grep to
`arch/ docs/` so it cannot go red on the frozen copy.

---

## Shared Patterns

### Bash script preamble
**Source:** `scripts/phase16-retire-assert.sh:21-24`, `arch/hyprland.sh:1-3`, `arch/waybar.sh:1-5`
**Apply to:** every script this phase creates or edits

```bash
#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"
```

`arch/*.sh` installers additionally carry `set -x` at line 3; `scripts/*.sh` asserts do not.

### Assert output contract (D-20, three-prefix)
**Source:** `scripts/phase16-retire-assert.sh:26-28` + `scripts/phase14-verify.sh:41`
**Apply to:** `scripts/phase17-unblock-assert.sh` only

```bash
FAIL=0
pass() { printf '[PASS] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
info() { printf '[INFO] %s\n' "$1"; }
...
echo "=== done: FAIL=${FAIL} ==="
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
```

### Failure prints its own evidence
**Source:** `scripts/phase16-retire-assert.sh:55-58, 260-262`
**Apply to:** every `fail()` branch in the assert script

```bash
  fail "…"
  grep -niE '…' "$FILE" || true
```

or `sed -n '1,40p' "$CAPTURE" || true`. The `|| true` is required under `set -e`.

### Vacuity guard before any ban-grep
**Source:** `scripts/phase16-retire-assert.sh:251-256, 291-302`
**Apply to:** FIX-01 / FIX-02 / FIX-06 / D-22 grep sections

Assert the input exists and is non-empty (or that an extraction is non-empty) **before**
asserting a token is absent from it. A ban over a missing file is a false green.

### Destructive-path refusal message
**Source:** `arch/dots-hyprland.sh:435-439`
**Apply to:** the FIX-04 repo guard

```bash
echo "[FAIL] Refusing to delete path outside \$HOME: $path" >&2
return 1
```

`[FAIL]` prefix, `>&2`, the offending `$path` named inline, `return 1` (never `exit`).

### Tree-qualified gitignore patterns
**Source:** `.gitignore:8-13`
**Apply to:** every D-14 pattern

Fully-qualified from the repo root, grouped under a `#` section header. Root-anchored
`.config/…` patterns do not reach the `stow/` copies (§F-8).

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `.gitattributes` | git metadata | config | No `.gitattributes` exists in the repo (§F-6). D-10 specifies the content verbatim — `* text=auto eol=lf` — so no analog is needed. |
| `.gitleaks.toml` (conditional, D-11) | config | config | No prior secret-scan config in the repo. Created only if D-13 triage accepts a finding; format follows gitleaks' own docs, not a repo precedent. |

---

## Metadata

**Analog search scope:** `scripts/`, `arch/`, `docs/`, `.config/hypr/`, `stow/`, repo-root git metadata
**Files scanned:** 14 (5 read in full or in targeted ranges; 9 confirmed by grep inventory in RESEARCH §F-1)
**Tracked-source gate:** all 10 analog paths verified with `git ls-files` — no gitignored mirrors. The one non-tracked reference, `~/.config/hypr/hyprland/execs.lua`, is vendor-owned live state cited as a *shape* reference only and is explicitly not edited (D-16).
**Pattern extraction date:** 2026-09-12
