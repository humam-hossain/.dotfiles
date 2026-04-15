#!/usr/bin/env bash
# =============================================================================
# nvim-validate.sh — Headless Neovim validation harness
#
# Usage:
#   ./scripts/nvim-validate.sh startup   Run headless startup smoke test
#   ./scripts/nvim-validate.sh sync      Run headless Lazy! sync with timeout
#   ./scripts/nvim-validate.sh health    Invoke core.health.snapshot, write JSON
#   ./scripts/nvim-validate.sh smoke     pcall-require high-risk plugin modules
#   ./scripts/nvim-validate.sh all       Run startup, sync, smoke, health
# =============================================================================

set -euo pipefail

# --- Repo and report dir resolution ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPORT_DIR="$REPO_ROOT/.planning/tmp/nvim-validate"

# --- Plugin and tool probe lists ---
PLUGIN_LIST="{'snacks','lualine','neo-tree','lspconfig','conform','nvim-treesitter.configs','blink.cmp','gitsigns','ufo','bufferline','which-key','render-markdown'}"
TOOL_LIST="{'stylua','black','isort','prettierd','prettier','clang-format','shfmt','rg','git','node','go','clangd','gopls','lua-language-server'}"

# --- Install hints per tool ---
declare -A TOOL_HINTS=(
	["stylua"]="cargo install stylua  OR  :MasonInstall stylua"
	["black"]="pip install black  OR  :MasonInstall black"
	["isort"]="pip install isort  OR  :MasonInstall isort"
	["prettierd"]="npm i -g @fsouza/prettierd  OR  :MasonInstall prettierd"
	["prettier"]="npm i -g prettier  OR  :MasonInstall prettier"
	["clang-format"]=" distro package (e.g. pacman -S clang)"
	["shfmt"]="go install mvdan.cc/sh/cmd/shfmt@latest  OR  :MasonInstall shfmt"
	["rg"]=" distro package (e.g. pacman -S ripgrep / apt install ripgrep)"
	["git"]=" distro package"
	["node"]=" distro package"
	["go"]=" distro package"
	["clangd"]=":MasonInstall clangd"
	["gopls"]=":MasonInstall gopls"
	["lua-language-server"]=":MasonInstall lua-language-server"
)

# =============================================================================
# Usage
# =============================================================================

usage() {
	cat <<EOF
Usage: $(basename "$0") <subcommand>

Subcommands:
  startup   Run 'nvim --headless "+qa"' against the repo config; fail non-zero
            on any error message to stderr or non-zero exit
  sync      Run headless 'Lazy! sync' with a 120s timeout; fail on timeout
            or error lines
  health    Invoke core.health.snapshot via headless nvim, write JSON to
            .planning/tmp/nvim-validate/health.json; fail on any plugin with
            loaded=false; warn on tools with available=false
  smoke     pcall-require high-risk plugin modules one by one; fail on any
            load failure
  all       Run startup, sync, smoke, health in that order; fail fast

Reports are written to: $REPORT_DIR/
EOF
}

# =============================================================================
# Init — ensure report dir exists
# =============================================================================

init() {
	mkdir -p "$REPORT_DIR"
}

# =============================================================================
# Tail helper — print last N lines of a file to stderr
# =============================================================================

print_tail() {
	local file="$1"
	local lines="${2:-50}"
	if [[ -f "$file" ]]; then
		echo "" >&2
		echo "--- last ${lines} lines of $file ---" >&2
		tail -n "$lines" "$file" >&2
		echo "---" >&2
	fi
}

# =============================================================================
# Subcommand: startup
# =============================================================================

cmd_startup() {
	local log="$REPORT_DIR/startup.log"
	echo "==> startup: running headless startup smoke..."
	nvim --headless \
		-u "$REPO_ROOT/.config/nvim/init.lua" \
		--cmd "set rtp^=$REPO_ROOT/.config/nvim" \
		+"lua vim.defer_fn(function() vim.cmd('qa!') end, 50)" \
		> "$log" 2>&1
	local rc=$?

	# Failure modes: non-zero exit OR error keywords in log
	if [[ $rc -ne 0 ]]; then
		echo "FAIL: nvim exited with code $rc" >&2
		print_tail "$log"
		return 1
	fi

	if grep -qE 'Error|E5108|E484|stack traceback' "$log" 2>/dev/null; then
		echo "FAIL: error keyword found in startup log" >&2
		print_tail "$log"
		return 1
	fi

	echo "PASS: startup OK"
	return 0
}

# =============================================================================
# Subcommand: sync
# =============================================================================

cmd_sync() {
	local log="$REPORT_DIR/sync.log"
	echo "==> sync: running Lazy! sync (120s timeout)..."
	timeout 120 nvim --headless \
		-u "$REPO_ROOT/.config/nvim/init.lua" \
		--cmd "set rtp^=$REPO_ROOT/.config/nvim" \
		+"Lazy! sync" \
		+"qa!" \
		> "$log" 2>&1
	local rc=$?

	# timeout returns 124
	if [[ $rc -eq 124 ]]; then
		echo "FAIL: Lazy! sync timed out after 120s" >&2
		print_tail "$log"
		return 1
	fi
	if [[ $rc -ne 0 ]]; then
		echo "FAIL: Lazy! sync exited with code $rc" >&2
		print_tail "$log"
		return 1
	fi

	if grep -qE 'Error|failed|stack traceback' "$log" 2>/dev/null; then
		echo "FAIL: error keyword found in sync log" >&2
		print_tail "$log"
		return 1
	fi

	echo "PASS: sync OK"
	return 0
}

# =============================================================================
# Subcommand: health
# =============================================================================

cmd_health() {
	local json="$REPORT_DIR/health.json"
	local log="$REPORT_DIR/health.log"
	echo "==> health: invoking core.health.snapshot..."

	nvim --headless \
		-u "$REPO_ROOT/.config/nvim/init.lua" \
		--cmd "set rtp^=$REPO_ROOT/.config/nvim" \
		+"lua local h=require('core.health'); local rc=h.snapshot({ out_path='$json', plugins=$PLUGIN_LIST, tools=$TOOL_LIST }); vim.cmd(rc==0 and 'qa!' or 'cq')" \
		> "$log" 2>&1
	local rc=$?

	if [[ $rc -ne 0 ]]; then
		echo "FAIL: health invocation exited with code $rc" >&2
		print_tail "$log"
		return 1
	fi

	if [[ ! -f "$json" ]]; then
		echo "FAIL: health.json was not written" >&2
		print_tail "$log"
		return 1
	fi

	# Pretty-print
	echo "--- health.json ---"
	if command -v jq &>/dev/null; then
		jq '.' "$json"
	else
		python3 -m json.tool "$json" 2>/dev/null || cat "$json"
	fi
	echo "---"

	# Check: fail on unloaded plugins
	if command -v jq &>/dev/null; then
		local unloaded
		unloaded=$(jq -r '.plugins[] | select(.loaded == false) | .name' "$json")
		if [[ -n "$unloaded" ]]; then
			echo "FAIL: the following plugins failed to load:" >&2
			echo "$unloaded" >&2
			return 1
		fi

		# Warn on missing tools
		local missing
		missing=$(jq -r '.tools[] | select(.available == false) | .name' "$json")
		if [[ -n "$missing" ]]; then
			echo "" >&2
			echo "MISSING TOOLS:" >&2
			while IFS= read -r tool; do
				local info
				info=$(jq -r ".tools[] | select(.name == \"$tool\") | \"$tool — affects \(.affected_feature) — install: \(.install_hint)\"" "$json")
				echo "WARN: $info" >&2
			done <<< "$missing"
			echo "" >&2
		else
			echo "ALL TOOLS AVAILABLE" >&2
		fi
	else
		echo "NOTE: jq not available, skipping structured plugin/tool checks" >&2
		echo "Install jq for full health validation, or inspect $json manually." >&2
	fi

	echo "PASS: health OK"
	return 0
}

# =============================================================================
# Subcommand: smoke
# =============================================================================

cmd_smoke() {
	local log="$REPORT_DIR/smoke.log"
	echo "==> smoke: probing high-risk plugin modules..."

	# Build Lua script to pcall each plugin
	local lua_script
	lua_script=$(cat <<'LUA'
local plugins = {
  'snacks','lualine','neo-tree','lspconfig','conform',
  'nvim-treesitter.configs','blink.cmp','gitsigns',
  'ufo','bufferline','which-key','render-markdown',
}
local failed = {}
for _, name in ipairs(plugins) do
  local ok, err = pcall(require, name)
  if not ok then
    table.insert(failed, name .. ': ' .. tostring(err))
  end
end
if #failed > 0 then
  local f = io.open('SMOKE_FAIL', 'w')
  for _, msg in ipairs(failed) do f:write(msg .. '\n') end
  f:close()
  vim.cmd('cq')
else
  print('ALL_SMOKE_OK')
  vim.cmd('qa!')
end
LUA
)

	# Use a temp file for the Lua script to avoid shell quoting hell
	local lua_tmp
	lua_tmp=$(mktemp)
	printf '%s' "$lua_script" > "$lua_tmp"

	nvim --headless \
		-u "$REPO_ROOT/.config/nvim/init.lua" \
		--cmd "set rtp^=$REPO_ROOT/.config/nvim" \
		-l "$lua_tmp" \
		> "$log" 2>&1
	local rc=$?
	rm -f "$lua_tmp"

	# Check for SMOKE_FAIL marker
	if [[ -f "$REPORT_DIR/SMOKE_FAIL" ]]; then
		echo "FAIL: the following plugins failed to load:" >&2
		cat "$REPORT_DIR/SMOKE_FAIL" >&2
		rm -f "$REPORT_DIR/SMOKE_FAIL"
		print_tail "$log"
		return 1
	fi

	if [[ $rc -ne 0 ]]; then
		echo "FAIL: smoke probe exited with code $rc" >&2
		print_tail "$log"
		return 1
	fi

	echo "PASS: smoke OK"
	return 0
}

# =============================================================================
# Subcommand: all
# =============================================================================

cmd_all() {
	init
	local rc=0

	cmd_startup || rc=$?
	if [[ $rc -ne 0 ]]; then echo "==> all ABORTED at startup" >&2; exit $rc; fi

	cmd_sync || rc=$?
	if [[ $rc -ne 0 ]]; then echo "==> all ABORTED at sync" >&2; exit $rc; fi

	cmd_smoke || rc=$?
	if [[ $rc -ne 0 ]]; then echo "==> all ABORTED at smoke" >&2; exit $rc; fi

	cmd_health || rc=$?
	if [[ $rc -ne 0 ]]; then echo "==> all ABORTED at health" >&2; exit $rc; fi

	echo ""
	echo "==> all PASS: startup, sync, smoke, health all succeeded"
	return 0
}

# =============================================================================
# Main dispatch
# =============================================================================

init

SUBCMD="${1:-}"
case "$SUBCMD" in
	startup) cmd_startup ;;
	sync)    cmd_sync ;;
	health)  cmd_health ;;
	smoke)   cmd_smoke ;;
	all)     cmd_all ;;
	*)       usage; exit 2 ;;
esac
