#!/usr/bin/env bash
# =============================================================================
# nvim-audit-failures.sh — Failure audit wrapper script
#
# Usage:
#   ./scripts/nvim-audit-failures.sh
#
# Runs automated audit to discover and catalog runtime failures from:
#   - nvim-validate.sh outputs (health.json, startup.log, sync.log, smoke.log)
#   - TODO/FIXME comments in Lua files
#   - Git history for bug/fix/error/crash commits
#
# Output:
#   .planning/phases/06-runtime-failure-inventory/FAILURES.md
# =============================================================================

set -euo pipefail

# --- Directory resolution ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="$REPO_ROOT/.planning/phases/06-runtime-failure-inventory"
REPORT_DIR="$REPO_ROOT/.planning/tmp/nvim-validate"
NVIM_CONFIG="$REPO_ROOT/.config/nvim"

# --- Required dependencies ---
if ! command -v jq >/dev/null 2>&1; then
	echo "ERROR: jq is required but not installed" >&2
	exit 1
fi

# --- Output file ---
FAILURES_MD="$OUTPUT_DIR/FAILURES.md"

# =============================================================================
# Helper: Get environment info
# =============================================================================

get_environment() {
	local nvim_version
	nvim_version=$(nvim --version | head -1 | tr -d '\n' || echo "unknown")

	local os_info
	os_info=$(uname -srm || echo "unknown")

	local tool_versions=""
	for tool in jq git; do
		if command -v "$tool" >/dev/null 2>&1; then
			local ver
			ver=$("$tool" --version 2>/dev/null | head -1 || echo "unknown")
			tool_versions+="$tool: $ver, "
		fi
	done
	tool_versions=${tool_versions%, }

	echo "OS: $os_info"
	echo "Neovim: $nvim_version"
	echo "Tools: ${tool_versions:-none}"
}

# =============================================================================
# Helper: Parse nvim-validate.sh outputs
# =============================================================================

parse_health_json() {
	local health_json="$REPORT_DIR/health.json"

	if [[ ! -f "$health_json" ]]; then
		return
	fi

	# Failed plugins - extract name and truncate error to single line
	jq -r '.plugins[] | select(.loaded == false) | .name' "$health_json" 2>/dev/null | while read -r name; do
		local err
		err=$(jq -r ".plugins[] | select(.name == \"$name\") | .error" "$health_json" 2>/dev/null | head -1 | tr '\n' ' ' | head -c 100)
		echo "$name plugin failed to load|plugin|$err|health"
	done

	# Missing tools
	jq -r '.tools[] | select(.available == false) | "\(.name) tool not found|tool|\(.affected_feature) — install: \(.install_hint)|health"' "$health_json" 2>/dev/null || true
}

parse_log_files() {
	local log_file
	local pattern='Error|E5108|E484|stack trace'

	for log_file in startup.log sync.log smoke.log; do
		local log_path="$REPORT_DIR/$log_file"
		if [[ -f "$log_path" ]]; then
			# Check if file has any matching content first
			if grep -qE "$pattern" "$log_path" 2>/dev/null; then
				# Extract error lines
				while IFS= read -r text; do
					# Skip if text is too generic or empty
					if [[ -z "$text" || ${#text} -lt 5 ]]; then
						continue
					fi
					# Truncate very long text
					text="${text:0:200}"

					local owner="log"
					echo "$text|${owner}|log error in $log_file|${log_file%.log}"
				done < <(grep -E "$pattern" "$log_path" 2>/dev/null || true)
			fi
		fi
	done
}

# =============================================================================
# Helper: Scan TODO/FIXME in Lua files
# =============================================================================

scan_todo_fixme() {
	# Check if any matches exist first
	if ! grep -rE "TODO|FIXME|XXX|BUG" "$NVIM_CONFIG" --include="*.lua" -q 2>/dev/null; then
		return
	fi

	# Process matches
	while IFS= read -r line; do
		# Parse: file:line:text
		local file text owner
		file=$(echo "$line" | cut -d: -f1)
		text=$(echo "$line" | cut -d: -f3-)

		# Skip empty or very short matches
		if [[ -z "$text" || ${#text} -lt 5 ]]; then
			continue
		fi
		# Skip separator lines
		if [[ "$text" =~ ^-+$ ]]; then
			continue
		fi

		owner=$(derive_owner "$file")

		# Truncate very long text
		text="${text:0:200}"

		echo "$text|$owner|TODO/FIXME comment|todo"
	done < <(grep -rE "TODO|FIXME|XXX|BUG" "$NVIM_CONFIG" --include="*.lua" -Hn 2>/dev/null || true)
}

# =============================================================================
# Helper: Scan git log for bug-related commits
# =============================================================================

scan_git_log() {
	# Check for matching commits first
	if ! git --no-merges log --all --pretty="%s" 2>/dev/null | grep -qiE 'bug|fix|error|crash|broken|fail'; then
		return
	fi

	# Process matching commits
	while IFS= read -r subject; do
		# Check if commit message contains relevant keywords
		if echo "$subject" | grep -qiE 'bug|fix|error|crash|broken|fail'; then
			local cleaned_subject
			cleaned_subject=$(echo "$subject" | head -c 150)
			local owner="git"
			echo "$cleaned_subject|$owner|bug-related commit|git"
		fi
	done < <(git --no-merges log --all --pretty="%s" 2>/dev/null || true)
}

# =============================================================================
# Helper: Derive owner from file path
# =============================================================================

derive_owner() {
	local file="$1"
	local basename
	basename=$(basename "$file")

	# Keymap failures
	if echo "$file" | grep -qE 'keymaps|which-key|lazy|apply'; then
		echo "core/keymaps/"
	# Plugin failures
	elif echo "$file" | grep -qE 'plugins/(lsp|neotree|fzflua|conform|blink|treesitter|git|ufo|notify)'; then
		echo "plugins/$(basename "$file")"
	# Plugin misc
	elif echo "$file" | grep -qE '/plugins/'; then
		local plugin_name="${basename%.lua}"
		echo "plugins/$plugin_name"
	# Core config
	elif echo "$file" | grep -qE '(init\.lua|options\.lua|keymaps\.lua|health\.lua|bootstrap)'; then
		case "$basename" in
			init.lua) echo "init.lua" ;;
			options.lua) echo "core/options.lua" ;;
			keymaps.lua) echo "core/keymaps.lua" ;;
			health.lua) echo "core/health.lua" ;;
			*) echo "core/" ;;
		esac
	# External tool
	elif echo "$file" | grep -qE '(scripts/|tool|bin/)'; then
		echo "external"
	# Default
	else
		echo "unknown"
	fi
}

# =============================================================================
# Helper: Deduplicate and format failures
# =============================================================================

deduplicate_failures() {
	# Use -A to allow empty array, add -g to create global
	declare -gA SEEN
	local bug_id=1

	# Need -r to preserve backslashes in read
	local read_result
	while IFS= read -r read_result || [[ -n "$read_result" ]]; do
		# Skip empty
		if [[ -z "$read_result" ]]; then
			continue
		fi

		# Parse fields
		local description owner provenance
		description=$(echo "$read_result" | cut -d'|' -f1)
		owner=$(echo "$read_result" | cut -d'|' -f2)
		provenance=$(echo "$read_result" | cut -d'|' -f4)

		# Normalize key for deduplication: lowercase + trim
		local key
		key=$(echo "$description | $owner" | tr '[:upper:]' '[:lower:]' | xargs)

		if [[ -z "${SEEN[$key]:-}" ]]; then
			SEEN[$key]=1
			local formatted_id
			printf -v formatted_id "BUG-%03d" "$bug_id"

			# Determine status
			local status="Discovered"
			if [[ "$provenance" == *"health"* ]] || [[ "$provenance" == *"smoke"* ]] || [[ "$provenance" == *"startup"* ]]; then
				status="Discovered"
			fi

			# Generate repro steps placeholder
			local repro="See provenance source for details"

			echo "$formatted_id|$description|$owner|$status|$repro|$provenance"
			bug_id=$((bug_id + 1))
		fi
	done
}

# =============================================================================
# Main: Run audit
# =============================================================================

main() {
	echo "==> nvim-audit-failures: starting failure audit..."

	# Ensure output dir exists
	mkdir -p "$OUTPUT_DIR"

	# --- Step 1: Run nvim-validate.sh checks individually (some may fail) ---
	echo "==> running nvim-validate.sh checks..."

	# Run each check separately, continue on failure
	"$SCRIPT_DIR/nvim-validate.sh" startup 2>/dev/null || echo "NOTE: startup check had issues"
	"$SCRIPT_DIR/nvim-validate.sh" sync     2>/dev/null || echo "NOTE: sync check had issues"
	"$SCRIPT_DIR/nvim-validate.sh" health   2>/dev/null || echo "NOTE: health check had issues"
	"$SCRIPT_DIR/nvim-validate.sh" smoke    2>/dev/null || echo "NOTE: smoke check had issues"
	# Continue even if some checks fail — we want to capture what we can

	# --- Step 2: Collect all failure sources ---
	local failures_txt="$OUTPUT_DIR/failures-raw.txt"

	# Run collectors and output to file
	{
		parse_health_json
		parse_log_files
		scan_todo_fixme
		scan_git_log
	} > "$failures_txt" || true

	# --- Step 3: Deduplicate and generate output ---
	local environment
	environment=$(get_environment)

	# Build FAILURES.md
	{
		cat <<EOF
# FAILURES.md — Runtime Failure Inventory

**Generated:** $(date -u +"%Y-%m-%dT%H:%M:%SZ")
**Status:** Discovered (requires manual confirmation)

## Environment

$environment

## Failure Inventory

| ID | Description | Owner | Status | Repro Steps | Provenance |
|----|-------------|-------|--------|--------------|-------------|
EOF

		# Process and deduplicate failures
		deduplicate_failures < "$failures_txt" | while IFS='|' read -r id desc owner status repro prov; do
			# Escape pipes for markdown table
			local esc_desc esc_owner esc_repro esc_prov
			esc_desc=$(echo "$desc" | tr '|' '\\|' | head -c 200)
			esc_owner=$(echo "$owner" | tr '|' '\\|' | head -c 50)
			esc_repro=$(echo "$repro" | tr '|' '\\|' | head -c 100)
			esc_prov=$(echo "$prov" | tr '|' '\\|' | head -c 50)

			echo "| $id | $esc_desc | $esc_owner | $status | $esc_repro | $esc_prov |"
		done
	} > "$FAILURES_MD"

	# Cleanup
	rm -f "$failures_txt"

	# --- Step 4: Report summary ---
	local count
	count=$(grep -c "BUG-" "$FAILURES_MD" || echo "0")

	echo "==> audit complete: found $count failures"
	echo "==> output written to: $FAILURES_MD"

	if [[ $count -eq 0 ]]; then
		echo "NOTE: No failures discovered. This may indicate:"
		echo "  - Validated config with no runtime issues"
		echo "  - Missing nvim-validate.sh outputs (run nvim-validate.sh first)"
		echo "  - No TODO/FIXME comments in code"
		echo "  - No bug-related commits in history"
	fi
}

# =============================================================================
# Entry point
# =============================================================================

main "$@"