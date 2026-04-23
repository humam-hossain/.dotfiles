# Phase 10: Validation Harness Expansion - Pattern Map

**Mapped:** 2026-04-23
**Files analyzed:** 5
**Analogs found:** 5 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `scripts/nvim-validate.sh` | utility | batch | `scripts/nvim-validate.sh` (`cmd_smoke`, `cmd_checkhealth`, `cmd_all`) | exact |
| `.config/nvim/README.md` | utility | transform | `.config/nvim/README.md` (Phase 3 validation harness section) | exact |
| `.config/nvim/lua/plugins/conform.lua` | config | event-driven | `.config/nvim/lua/plugins/conform.lua` (`format_on_save`) | exact |
| `.planning/phases/06-runtime-failure-inventory/CHECKLIST.md` | utility | request-response | `.planning/phases/06-runtime-failure-inventory/CHECKLIST.md` (Phase 9 + regression sections) | exact |
| `.planning/phases/06-runtime-failure-inventory/FAILURES.md` | utility | transform | `.planning/phases/06-runtime-failure-inventory/FAILURES.md` (Phase 9 audit + classification tables) | exact |

## Pattern Assignments

### `scripts/nvim-validate.sh` (utility, batch)

**Analog:** `scripts/nvim-validate.sh`

**Usage + artifact contract pattern** ([scripts/nvim-validate.sh](/home/pera/github_repo/.dotfiles/scripts/nvim-validate.sh:47), lines 47-66):
```bash
usage() {
	cat <<EOF
Usage: $(basename "$0") <subcommand>

Subcommands:
  startup      Run 'nvim --headless "+qa"' against the repo config; fail non-zero
               on any error message to stderr or non-zero exit
  sync         Run headless 'Lazy! sync' with a 120s timeout; fail on timeout
               or error lines
  health       Invoke core.health.snapshot via headless nvim, write JSON to
               .planning/tmp/nvim-validate/health.json; fail on any plugin with
               loaded=false or required tool missing; warn on optional tools
```

**Subcommand structure pattern** ([scripts/nvim-validate.sh](/home/pera/github_repo/.dotfiles/scripts/nvim-validate.sh:332), lines 332-392):
```bash
cmd_smoke() {
	local log="$REPORT_DIR/smoke.log"
	echo "==> smoke: probing high-risk plugin modules..."
	...
	nvim --headless \
		-u "$REPO_ROOT/.config/nvim/init.lua" \
		--cmd "set rtp^=$REPO_ROOT/.config/nvim" \
		-l "$lua_tmp" \
		> "$log" 2>&1
	local rc=$?
	...
	if [[ $rc -ne 0 ]]; then
		echo "FAIL: smoke probe exited with code $rc" >&2
		print_tail "$log"
		return 1
	fi

	echo "PASS: smoke OK"
	return 0
}
```

**Temp Lua probe pattern** ([scripts/nvim-validate.sh](/home/pera/github_repo/.dotfiles/scripts/nvim-validate.sh:260), lines 260-325):
```bash
local lua_tmp
lua_tmp=$(mktemp)
cat > "$lua_tmp" <<LUA
local artifact = '$artifact'
vim.fn.mkdir(vim.fn.fnamemodify(artifact, ':h'), 'p')
...
vim.fn.writefile(lines, artifact)
if not ok then
  io.stderr:write('checkhealth engine error: ' .. tostring(err) .. '\n')
  vim.cmd('cq')
end
vim.cmd('qa!')
LUA
```

**Fail-fast `all` sequence pattern** ([scripts/nvim-validate.sh](/home/pera/github_repo/.dotfiles/scripts/nvim-validate.sh:399), lines 399-420):
```bash
cmd_all() {
	init
	local rc=0

	cmd_startup || rc=$?
	if [[ $rc -ne 0 ]]; then echo "==> all ABORTED at startup" >&2; exit $rc; fi
	...
	cmd_checkhealth || rc=$?
	if [[ $rc -ne 0 ]]; then echo "==> all ABORTED at checkhealth" >&2; exit $rc; fi

	echo ""
	echo "==> all PASS: startup, sync, smoke, health, checkhealth all succeeded"
	return 0
}
```

**Dispatch registration pattern** ([scripts/nvim-validate.sh](/home/pera/github_repo/.dotfiles/scripts/nvim-validate.sh:427), lines 427-438):
```bash
SUBCMD="${1:-}"
case "$SUBCMD" in
	startup)     cmd_startup ;;
	sync)        cmd_sync ;;
	health)      cmd_health ;;
	smoke)       cmd_smoke ;;
	checkhealth) cmd_checkhealth ;;
	all)         cmd_all ;;
	*)           usage; exit 2 ;;
esac
```

**Copy for Phase 10:** add `cmd_keymaps` and `cmd_formats` using the existing `cmd_smoke`/`cmd_checkhealth` layout: `local log=...`, headless `nvim`, explicit PASS/FAIL lines, artifact under `$REPORT_DIR`, and `cmd_all` fail-fast insertion.

---

### `.config/nvim/README.md` (utility, transform)

**Analog:** `.config/nvim/README.md`

**Validation command table pattern** ([.config/nvim/README.md](/home/pera/github_repo/.dotfiles/.config/nvim/README.md:321), lines 321-327):
```markdown
| Command | Purpose |
|---------|---------|
| `./scripts/nvim-validate.sh startup` | Run `nvim --headless "+qa"` against this config; fail on any error message or non-zero exit |
| `./scripts/nvim-validate.sh sync` | Run headless `Lazy! sync` with a 120s timeout; fail on timeout or stack traceback |
| `./scripts/nvim-validate.sh health` | Invoke `core.health.snapshot` and write JSON to `.planning/tmp/nvim-validate/health.json`; fail on any plugin with `loaded=false` |
| `./scripts/nvim-validate.sh smoke` | pcall-require the high-risk plugin modules one by one; fail on any load failure |
| `./scripts/nvim-validate.sh all` | Run startup, sync, smoke, health in order; fail fast |
```

**Artifact list pattern** ([.config/nvim/README.md](/home/pera/github_repo/.dotfiles/.config/nvim/README.md:329), lines 329-338):
```markdown
### Report Output

All reports are written to `.planning/tmp/nvim-validate/` (gitignored):

- `startup.log` — stdout+stderr from headless startup
- `sync.log` — output from `Lazy! sync`
- `smoke.log` — per-plugin pcall results
- `health.json` — machine-readable snapshot (schema below)
- `health.log` — stderr from the health invocation
```

**Policy explanation pattern** ([.config/nvim/README.md](/home/pera/github_repo/.dotfiles/.config/nvim/README.md:355), lines 355-370):
```markdown
### Missing Tool Policy

Per Phase 3 decisions D-07 through D-09:

- Runtime startup does NOT emit `vim.notify` warnings when external tools (formatters, LSP binaries) are missing.
- Missing tools are surfaced ONLY through `./scripts/nvim-validate.sh health` and the `core.health.snapshot` JSON.
...
Example missing-tool output from `./scripts/nvim-validate.sh health`:
```

**When-to-run checklist pattern** ([.config/nvim/README.md](/home/pera/github_repo/.dotfiles/.config/nvim/README.md:372), lines 372-376):
```markdown
- After any change in `.config/nvim/lua/plugins/*.lua`: `./scripts/nvim-validate.sh startup`
- After refreshing `lazy-lock.json`: `./scripts/nvim-validate.sh all`
- Before concluding Phase 3 or starting Phase 4: `./scripts/nvim-validate.sh all`
```

**Copy for Phase 10:** keep the same section/table/bullet style. Extend the command table and report-output list instead of inventing a second validation doc block. Put the new "Reading validation output" section near the existing validation harness documentation so command descriptions and triage guidance stay adjacent.

---

### `.config/nvim/lua/plugins/conform.lua` (config, event-driven)

**Analog:** `.config/nvim/lua/plugins/conform.lua`

**Module export pattern** ([.config/nvim/lua/plugins/conform.lua](/home/pera/github_repo/.dotfiles/.config/nvim/lua/plugins/conform.lua:2), lines 2-15):
```lua
return {
	"stevearc/conform.nvim",
	opts = {
		formatters_by_ft = {
			lua = { "stylua" },
			python = { "isort", "black" },
			javascript = { "prettierd", "prettier", stop_after_first = true },
```

**Guard-function pattern** ([.config/nvim/lua/plugins/conform.lua](/home/pera/github_repo/.dotfiles/.config/nvim/lua/plugins/conform.lua:16), lines 16-63):
```lua
format_on_save = function(bufnr)
	local bufname = vim.api.nvim_buf_get_name(bufnr)
	local ft = vim.bo[bufnr].filetype
	local buftype = vim.bo[bufnr].buftype
	...
	if buftype ~= "" and buftype ~= "acwrite" then
		return false
	end
	...
	if bufname == "" then
		return false
	end
	...
	if excluded[ft] then
		return false
	end

	return { timeout_ms = 500, lsp_format = "fallback" }
end,
```

**Comment style pattern** ([.config/nvim/lua/plugins/conform.lua](/home/pera/github_repo/.dotfiles/.config/nvim/lua/plugins/conform.lua:21), lines 21-25 and 40-43):
```lua
-- Guard 1: reject special-buffer types.
-- "acwrite" (e.g. fugitive commit message) is allowed through because
-- it is a real file that the user is intentionally editing and saving.
...
-- Guard 4: filetype exclusion list.
-- Covers commit messages, plain text, markdown, rebase scripts, diff
-- output, Neogit commit message, legacy neo-tree, quickfix, and fugitive
```

**Copy for Phase 10:** the harness should treat `format_on_save` as the stable logic boundary. Directly call this function in headless probes with controlled `vim.bo[bufnr]` and `nvim_buf_get_name()` state; do not simulate `BufWritePre`.

---

### `.planning/phases/06-runtime-failure-inventory/CHECKLIST.md` (utility, request-response)

**Analog:** `.planning/phases/06-runtime-failure-inventory/CHECKLIST.md`

**Phase-section heading pattern** ([CHECKLIST.md](/home/pera/github_repo/.dotfiles/.planning/phases/06-runtime-failure-inventory/CHECKLIST.md:13), lines 13-33):
```markdown
## Phase 9 Interactive Verification (BUG-019 and BUG-020)

### BUG-019 — tmux cross-pane traversal — FIXED AND VERIFIED

**Fix applied (Phase 9-01):** Added four `bind-key -n C-h/j/k/l` companion entries...
...
**Status: CLOSED — FIXED**
```

**Manual regression entry pattern** ([CHECKLIST.md](/home/pera/github_repo/.dotfiles/.planning/phases/06-runtime-failure-inventory/CHECKLIST.md:81), lines 81-90):
```markdown
### BUG-005 — `<leader>b` opens new buffer (was: E488 from `<cmd> enew <CR>`)
**lhs:** `<leader>b` | **Owner:** registry.lua (M.global)

1. Open Neovim
2. Press `<leader>b`

**Expected:** New empty buffer opens with no error or notification
**Regression signal:** Any E488 or Lua error in the notification area
**Fixed by:** Moved to `M.global`; action is `function() vim.cmd("enew") end`
```

**Matrix/table pattern** ([CHECKLIST.md](/home/pera/github_repo/.dotfiles/.planning/phases/06-runtime-failure-inventory/CHECKLIST.md:189), lines 189-205):
```markdown
## Verified Non-Issues

| ID | lhs | Verdict | Notes |
|----|-----|---------|-------|
| BUG-014 | `<leader>ww` | PASS | `<C-w>w` in M.global → apply.lua → vim.keymap.set, works |
```

**Copy for Phase 10:** add a new `## Phase 10 Regression Checks` section using the existing checklist idiom: short heading, numbered manual steps, explicit `Expected`, explicit `Regression signal`, and terse provenance/fix notes. Keep scripted checks out of this file except as references to the new harness commands.

---

### `.planning/phases/06-runtime-failure-inventory/FAILURES.md` (utility, transform)

**Analog:** `.planning/phases/06-runtime-failure-inventory/FAILURES.md`

**Audit summary pattern** ([FAILURES.md](/home/pera/github_repo/.dotfiles/.planning/phases/06-runtime-failure-inventory/FAILURES.md:46), lines 46-72):
```markdown
## Phase 9-01 First Checkhealth Audit (2026-04-23)

**Command:** `./scripts/nvim-validate.sh checkhealth`
**Artifact:** `.planning/tmp/nvim-validate/checkhealth.txt` (5667 lines)
**Initial exit:** FAIL (correct — errors detected before fixes)
**Post-fix exit:** FAIL (remaining errors are reserved/environment-only — documented below)
```

**Classification-table pattern** ([FAILURES.md](/home/pera/github_repo/.dotfiles/.planning/phases/06-runtime-failure-inventory/FAILURES.md:53), lines 53-63):
```markdown
| Provider | Error message | Classification | Action |
|----------|---------------|----------------|--------|
| `core` | `Failed to run healthcheck...` | **Reserved for 9-02** | None in 9-01 |
| `render-markdown` | `buftype - expected: nil, got: table` | **Config bug** | **Fixed**: moved to `overrides.buftype` in `plugins/misc.lua` |
| `snacks` | `Tool not found: 'mmdc'` | **Missing optional tool** | None — optional tool, not a config defect |
```

**Root-cause narrative pattern** ([FAILURES.md](/home/pera/github_repo/.dotfiles/.planning/phases/06-runtime-failure-inventory/FAILURES.md:75), lines 75-90):
```markdown
## Root Cause Summary

**RC-01 — lazy.lua:29 `vim.cmd(action)` with string actions**
...
Affects: all entries in `M.lazy` that use string actions.
Not affected: `M.global` entries go through `apply.lua` → `vim.keymap.set()`
```

**Inventory row pattern** ([FAILURES.md](/home/pera/github_repo/.dotfiles/.planning/phases/06-runtime-failure-inventory/FAILURES.md:95), lines 95-114):
```markdown
| ID | Description | Owner | Status | Repro Steps / lhs | Provenance |
|----|-------------|-------|--------|-------------------|------------|
| BUG-019 | tmux.conf missing vim-tmux-navigator companion bindings... | .tmux.conf (environment) | **Fixed** (Phase 9-01) ... | `<C-h/j/k/l>` in tmux | interactive |
```

**Copy for Phase 10:** record the fresh warning audit as a dated section with command, artifact, exit state, then classify each WARN into `Config bug`, `Environment-only`, `Missing optional tool`, or `By Design / Won't Fix`. Reuse the current table and status vocabulary; do not invent a new taxonomy.

---

## Shared Patterns

### Single Harness Subcommand Pattern
**Source:** [scripts/nvim-validate.sh](/home/pera/github_repo/.dotfiles/scripts/nvim-validate.sh:96)
**Apply to:** New `keymaps` and `formats` validator commands
```bash
cmd_<name>() {
	local log="$REPORT_DIR/<artifact>.log"
	echo "==> <name>: ..."
	...
	if [[ $rc -ne 0 ]]; then
		echo "FAIL: ..." >&2
		print_tail "$log"
		return 1
	fi
	echo "PASS: <name> OK"
	return 0
}
```

### Headless Lua Probe Boundary
**Source:** [scripts/nvim-validate.sh](/home/pera/github_repo/.dotfiles/scripts/nvim-validate.sh:336)
**Apply to:** Runtime-only regression checks
```bash
local lua_tmp
lua_tmp=$(mktemp)
printf '%s' "$lua_script" > "$lua_tmp"
nvim --headless \
	-u "$REPO_ROOT/.config/nvim/init.lua" \
	--cmd "set rtp^=$REPO_ROOT/.config/nvim" \
	-l "$lua_tmp" \
	> "$log" 2>&1
```

### Warning Taxonomy
**Source:** [FAILURES.md](/home/pera/github_repo/.dotfiles/.planning/phases/06-runtime-failure-inventory/FAILURES.md:53)
**Apply to:** README triage guidance and Phase 10 warning audit
```markdown
| Provider | Error message | Classification | Action |
|----------|---------------|----------------|--------|
| ... | ... | **Config bug** | fix in repo |
| ... | ... | **Environment-only** | document only |
| ... | ... | **Missing optional tool** | optional install guidance |
```

### Health Provider Required vs Optional Pattern
**Source:** [.config/nvim/lua/config/health.lua](/home/pera/github_repo/.dotfiles/.config/nvim/lua/config/health.lua:47)
**Apply to:** README explanations and warning triage
```lua
if meta.required then
	vim.health.error(
		string.format("%s not found — affects: %s", name, meta.affected_feature),
		{ "Install: " .. meta.install_hint }
	)
else
	vim.health.warn(
		string.format("%s not found — affects: %s", name, meta.affected_feature),
		{ "Install: " .. meta.install_hint }
	)
end
```

### Lazy Key Dispatcher Regression Boundary
**Source:** [.config/nvim/lua/core/keymaps/lazy.lua](/home/pera/github_repo/.dotfiles/.config/nvim/lua/core/keymaps/lazy.lua:22)
**Apply to:** `keymaps` subcommand probe cases
```lua
if ok and mod and mod[map.action] then
	mod[map.action]()
elseif type(map.action) == "function" then
	map.action()
elseif type(map.action) == "string" then
	if map.action:match("<[^>]+>") then
		vim.api.nvim_feedkeys(
			vim.api.nvim_replace_termcodes(map.action, true, false, true),
			"n",
			false
		)
	else
		vim.cmd(map.action)
	end
end
```

## No Analog Found

None. Every planned file has a direct in-repo analog or an existing section in the same file that should be extended.

## Metadata

**Analog search scope:** `scripts/`, `.config/nvim/`, `.config/nvim/lua/`, `.planning/phases/06-runtime-failure-inventory/`, `.planning/phases/10-validation-harness-expansion/`
**Files scanned:** 34 candidate files
**Pattern extraction date:** 2026-04-23
