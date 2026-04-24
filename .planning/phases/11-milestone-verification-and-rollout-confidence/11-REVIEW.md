---
phase: 11-milestone-verification-and-rollout-confidence
reviewed: 2026-04-24T07:02:13Z
depth: standard
files_reviewed: 6
files_reviewed_list:
  - .config/.zprofile
  - .config/hypr/hyprland.conf
  - .config/nvim/README.md
  - .config/nvim/lua/plugins/project.lua
  - scripts/nvim-validate.sh
  - arch/nvim.sh
findings:
  critical: 0
  warning: 2
  info: 5
  total: 7
status: issues_found
---

# Phase 11: Code Review Report

**Reviewed:** 2026-04-24T07:02:13Z
**Depth:** standard
**Files Reviewed:** 6
**Status:** issues_found

## Summary

Six files were reviewed: the zsh login profile, Hyprland compositor config, Neovim README, the project.nvim plugin spec, the validation harness shell script, and the Arch install script. The Hyprland config and project.lua are clean. The main actionable issues are a path mismatch in the smoke subcommand that causes failed plugin loads to be silently missed (diagnostic output only — the hard exit still fires via the rc check), a wrong Go module path in the shfmt install hint, and several documentation/annotation issues across the README and install script.

## Warnings

### WR-01: SMOKE_FAIL written to cwd but checked in REPORT_DIR — diagnostic path mismatch

**File:** `scripts/nvim-validate.sh:385` and `:410`

**Issue:** The embedded Lua script writes the failure marker to a bare relative path `'SMOKE_FAIL'` (line 385). Neovim inherits the shell's working directory — typically `REPO_ROOT` when invoked per the documented workflow. The shell then checks for the file at `$REPORT_DIR/SMOKE_FAIL` (line 410), which expands to `$REPO_ROOT/.planning/tmp/nvim-validate/SMOKE_FAIL`. These are two different paths.

Consequence: when a plugin fails to load, Neovim writes `SMOKE_FAIL` to `REPO_ROOT/SMOKE_FAIL` and exits non-zero (`cq`). The rc-check on line 418 (`if [[ $rc -ne 0 ]]`) does catch the failure and returns 1, so the subcommand still fails. However, the diagnostic branch at line 410–414 (which cats the failure details to stderr) is never reached because the file is not found at `REPORT_DIR`. The error names are therefore swallowed, making triage harder. The stray `SMOKE_FAIL` at repo root also shows up as an untracked file in `git status` (confirmed: it appeared in the conversation's initial status snapshot).

**Fix:** Pass the target path to the Lua script via an environment variable, matching the pattern already used by `cmd_keymaps` and `cmd_formats`:

```bash
# In cmd_smoke, replace the bare io.open call:
local f = io.open(os.getenv('SMOKE_FAIL_PATH') or 'SMOKE_FAIL', 'w')
```

And invoke nvim with:

```bash
SMOKE_FAIL_PATH="$REPORT_DIR/SMOKE_FAIL" nvim --headless \
    -u "$REPO_ROOT/.config/nvim/init.lua" \
    --cmd "set rtp^=$REPO_ROOT/.config/nvim" \
    -l "$lua_tmp" \
    > "$log" 2>&1
```

This makes the write path deterministic and consistent with the other probes.

---

### WR-02: Wrong Go module path for shfmt install hint

**File:** `scripts/nvim-validate.sh:38`

**Issue:** The install hint for `shfmt` reads:

```
go install mvdan.cc/sh/cmd/shfmt@latest
```

The correct module path (v3 and later) is `mvdan.cc/sh/v3/cmd/shfmt`. The path without the `v3` major-version segment resolves to an old pre-module era import and will fail or install an outdated version. The README itself has the correct path (`mvdan.cc/sh/v3/cmd/shfmt@latest`, line 403 of README.md), making this an inconsistency that will confuse anyone who copies from the harness's WARN output.

**Fix:**

```bash
["shfmt"]="go install mvdan.cc/sh/v3/cmd/shfmt@latest  OR  :MasonInstall shfmt"
```

---

## Info

### IN-01: eval without double-quoting in zprofile — command injection surface

**File:** `.config/.zprofile:7`

**Issue:** The gnome-keyring-daemon output is fed to `eval` using unquoted command substitution:

```zsh
eval $(gnome-keyring-daemon --start --components=pkcs11,secrets,ssh)
```

If `gnome-keyring-daemon` outputs variable assignments containing spaces or special characters, word-splitting will corrupt them before `eval` processes them. The safe idiom is double-quoted command substitution:

```zsh
eval "$(gnome-keyring-daemon --start --components=pkcs11,secrets,ssh)"
```

This is low-severity in practice because gnome-keyring-daemon outputs well-formed `VAR=value` lines, but the unquoted form is a latent correctness risk.

**Fix:**

```zsh
eval "$(gnome-keyring-daemon --start --components=pkcs11,secrets,ssh)"
```

---

### IN-02: pacman -Sy without -u in arch/nvim.sh — partial upgrade risk

**File:** `arch/nvim.sh:6`

**Issue:** Every `pacman` invocation uses `-Sy` (sync + refresh DB) without `-u` (upgrade). On Arch Linux, running `-Sy` without `-u` is documented as potentially dangerous: it refreshes the package database to a newer state but leaves the rest of the system unupgraded. If any of the freshly-installed packages have upgraded dependencies that the un-upgraded system does not satisfy, partial upgrades can occur. Arch wiki explicitly warns against this pattern.

**Fix:** Either add `-u` to perform a full system upgrade before installing:

```bash
sudo pacman -Syu --noconfirm --needed python-pynvim fd
```

Or accept the risk intentionally and add a comment explaining that the caller is responsible for keeping the system current before running this script. Given this is a targeted install script (not a system provisioner), the latter is reasonable:

```bash
# NOTE: caller must run `pacman -Syu` first; -Sy without -u is intentional here
# to avoid an unattended full-system upgrade in a targeted install script.
sudo pacman -Sy --noconfirm --needed python-pynvim fd
```

---

### IN-03: Stale TODO comment in project.lua

**File:** `.config/nvim/lua/plugins/project.lua:1`

**Issue:** The file opens with `--- TODO: Project scoping - project.nvim ---`. The implementation is complete (plugin is configured and the deprecated API is worked around). The TODO is a leftover annotation from a planning/drafting stage.

**Fix:** Remove the comment or replace it with a doc comment explaining the intentional `detection_methods` override:

```lua
-- project.nvim: use pattern-only detection to avoid vim.lsp.buf_get_clients()
-- deprecation warnings on Neovim 0.12+.
return {
```

---

### IN-04: Missing list item number in README smoke checklist

**File:** `.config/nvim/README.md:448`

**Issue:** Step 5 of the Phase 1 smoke checklist is rendered as a bare period instead of `5.`:

```
. **Split close**: Press `<leader>xs>` - should close only current split
```

The `5` was dropped, breaking the ordered list visually. Additionally, the keymap shown (`<leader>xs>`) has a stray trailing `>` that does not match the mapping registered in the config (`<leader>xs`).

**Fix:**

```markdown
5. **Split close**: Press `<leader>xs` - should close only current split
```

---

### IN-05: Validation table in README lists incomplete `all` subcommand sequence

**File:** `.config/nvim/README.md:257`

**Issue:** The Validation Commands table (under "Tooling and Ecosystem Modernization") lists `all` as running `startup → sync → smoke → health → checkhealth`. The actual `cmd_all` function (and the Validation Harness section on the same page, line 332) also includes `keymaps` and `formats`. The table is stale and will mislead a maintainer who relies on it as the canonical sequence reference.

**Fix:** Update the table row:

```markdown
| `./scripts/nvim-validate.sh all` | Run startup → sync → smoke → health → checkhealth → keymaps → formats in order (fail fast) |
```

---

_Reviewed: 2026-04-24T07:02:13Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
