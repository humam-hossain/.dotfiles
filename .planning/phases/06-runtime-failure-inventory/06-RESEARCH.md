# Phase 6: Runtime Failure Inventory and Reproduction - Research

**Researched:** 2026-04-18
**Domain:** Shell scripting, Neovim validation, failure inventory automation
**Confidence:** HIGH

## Summary

Phase 6 requires creating `scripts/nvim-audit-failures.sh` that wraps the existing `nvim-validate.sh` harness and adds TODO/FIXME scanning and git log keyword analysis. The script produces FAILURES.md (full inventory) and CHECKLIST.md (repro steps). This is a catalog-only phase—no fixes. Key findings: the existing validation harness is well-designed with `set -euo pipefail`, health.json output structure is JSON with plugin/tool status, TODO patterns are scattered across 23 Lua files, and git history has no bug/fix/error/crash commits to mine.

**Primary recommendation:** Create standalone `nvim-audit-failures.sh` that internally calls `nvim-validate.sh` and parses its outputs, then adds grep-based TODO/FIXME scan and git log analysis for a unified inventory.

---

## User Constraints (from CONTEXT.md)

### Implementation Decisions
- **D-03:** Create `scripts/nvim-audit-failures.sh` — do NOT extend `nvim-validate.sh`
- **D-04:** Single operation: `./scripts/nvim-audit-failures.sh` — no subcommands
- **D-05:** Script writes `FAILURES.md` directly to `.planning/phases/06-runtime-failure-inventory/FAILURES.md`
- **D-06:** Script auto-scans TODO/FIXME patterns in `.config/nvim/**/*.lua`
- **D-07:** Script auto-scans `git log` for commits with bug/fix/error/crash keywords
- **D-08:** For failures not reproducible by script, step-by-step instructions written as repro steps
- **D-09:** Discovered → Confirmed requires BOTH script reproduction AND manual verification
- **D-10:** Phase executor runs script → developer does manual review to promote to Confirmed

### Ownership Labels
- **D-13:** Keymap failures → `core/keymaps/` files
- **D-14:** Plugin failures → plugin config files
- **D-15:** Core config failures → `init.lua`, `core/options.lua`, `core/keymaps.lua`, `core/health.lua`
- **D-16:** External tool failures → missing tools, env setup, OS-specific issues

### Inventory Fields
- **D-19:** Table columns: `ID`, `Description`, `Owner`, `Status`, `Repro Steps`, `Provenance`, `Environment`
- **D-20:** ID format: `BUG-NNN` (e.g. `BUG-001`)
- **D-21:** Provenance: source(s) that found it (health / smoke / startup / todo / git)
- **D-22:** Environment captured once in header

### Status Workflow
- **D-24:** Full workflow: `Discovered` → `Confirmed` → `Fixed` → `Closed`
- **D-25:** Dispositions: `Won't Fix`, `By Design`, `Duplicate`, `Out of Scope`

### Scope
- **D-27:** Arch Linux only — no cross-platform validation in this phase
- **D-11:** Phase 6 does NOT fix anything — catalog only

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Automated validation | Shell script | — | Bash scripts run outside Neovim, call nvim headless |
| Health probing | Neovim Lua | — | `core/health.snapshot()` runs inside Neovim |
| TODO/FIXME scanning | Shell script | — | grep on filesystem, no Neovim needed |
| Git log analysis | Shell script | — | git commands outside Neovim |
| Inventory generation | Shell script | — | Writes markdown, no Neovim needed |
| Manual verification | Human | — | Developer interactively triggers failures |

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| bash | 5.x+ | Scripting language | Required for nvim-validate.sh wrapper |
| jq | 1.7+ | JSON parsing for health.json | Enables structured tool/plugin checks |
| git | any | Log scanning | D-07 requires git log analysis |
| nvim | 0.10+ | Headless validation | Calls nvim --headless for startup/sync/smoke/health |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| grep | any | Pattern matching | TODO/FIXME scanning, error keyword detection |
| sort/uniq | any | Deduplication | When same failure appears across sources |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| bash | python | Python adds dependency; bash already in nvim-validate.sh |
| jq | python json.tool | jq more portable for CLI JSON parsing |

**Installation:**
```bash
# No additional deps - bash, grep, git, jq already expected
# Check jq: command -v jq || echo "jq not installed"
```

---

## Architecture Patterns

### System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                   nvim-audit-failures.sh                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐    │
│  │ nvim-validate│    │ TODO/FIXME   │    │  git log     │    │
│  │    .sh       │    │   grep scan  │    │   scan       │    │
│  │   (all)      │    │              │    │              │    │
│  └──────┬───────┘    └──────┬───────┘    └──────┬───────┘    │
│         │                   │                   │             │
│         │  health.json      │  .lua files      │  commits    │
│         │  startup.log      │  (23 files)      │  (none)     │
│         │  sync.log         │                   │             │
│         │  smoke.log        │                   │             │
│         └────────┬──────────┴────────┬──────────┘             │
│                  │                    │                        │
│                  ▼                    ▼                        │
│          ┌──────────────────────────────────┐                 │
│          │     Merge & Deduplicate          │                 │
│          │   (by description + owner)        │                 │
│          └───────────────┬──────────────────┘                 │
│                          │                                     │
│         ┌────────────────┴────────────────┐                  │
│         ▼                                 ▼                   │
│  ┌───────────────┐                 ┌───────────────┐         │
│  │ FAILURES.md   │                 │ CHECKLIST.md  │         │
│  │ (full inv.)   │                 │ (repro steps) │         │
│  └───────────────┘                 └───────────────┘         │
└─────────────────────────────────────────────────────────────────┘
```

### Recommended Project Structure
```
scripts/
├── nvim-validate.sh       # Existing validation harness (READ-ONLY)
└── nvim-audit-failures.sh # NEW: failure audit wrapper

.planning/
├── phases/06-runtime-failure-inventory/
│   ├── FAILURES.md        # Generated by script
│   └── CHECKLIST.md       # Generated after manual review
└── tmp/nvim-validate/     # Existing: health.json, logs
```

### Pattern 1: Validation Wrapper Script
**What:** Script that calls existing harness internally rather than extending it
**When to use:** When existing script has stable API and you need additional behavior without modifying it
**Example:**
```bash
#!/usr/bin/env bash
set -euo pipefail

# Call existing harness
"$SCRIPT_DIR/nvim-validate.sh" all

# Then add additional scans
TODO_FAILURES=$(grep -rHn "TODO\|FIXME" "$REPO_ROOT/.config/nvim/lua/" 2>/dev/null || true)
```

### Pattern 2: Deduplication by Content Hash
**What:** Merge entries from multiple sources by comparing description + owner
**When to use:** When same failure appears in health.json, TODO scan, and git log
**Example:**
```bash
# Pseudocode - map key = "${description}|${owner}"
declare -A SEEN
for source in health todo git; do
  for entry in $(parse_$source); do
    key=$(echo "$entry" | cut -d'|' -f1,2)
    if [[ -z "${SEEN[$key]}" ]]; then
      SEEN[$key]=1
      echo "$entry" >> failures.tmp
    fi
  done
done
```

### Anti-Patterns to Avoid
- **Extending nvim-validate.sh:** D-03 explicitly forbids this. Create separate script.
- **Filtering health warnings at script level:** D-18 says let full picture through — let Phases 7-9 decide what's noise
- **Manual verification during script run:** D-10 says script produces Discovered, human review promotes to Confirmed

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| JSON parsing | custom Lua parser | `jq` already in nvim-validate.sh | jq handles health.json |
| Error detection in logs | shell if/else chains | `grep -qE 'Error|E5108|E484|stack trace'` | Same pattern as nvim-validate.sh |
| Plugin loading check | lua pcall loop | `nvim-validate.sh smoke` already does this | Reuse existing |
| Tool availability check | custom exe check | `health.lua` already probes tools | Produces structured output |

---

## Common Pitfalls

### Pitfall 1: Missing jq causes silent failure
**What goes wrong:** Script assumes jq is installed but fails on parsing health.json
**Why it happens:** D-22 in nvim-validate.sh shows jq is optional but the audit script needs it for structured merging
**How to avoid:** Require jq in audit script (fail fast if missing), unlike nvim-validate.sh which warns
**Warning signs:** `command -v jq || { echo "jq required for audit script"; exit 1; }`

### Pitfall 2: TODO lines incorrectly promoted to failures
**What goes wrong:** Every TODO comment becomes a BUG-NNN entry, overwhelming the inventory
**Why it happens:** D-06 says scan TODO/FIXME but doesn't say which are actual failures vs. planned features
**How to avoid:** Add provenance='todo' flag; human review during D-10 session filters planned items from actual bugs
**Warning signs:** More than 15 entries with provenance='todo' — many are likely feature placeholders

### Pitfall 3: Git log scan matches merge commits
**What goes wrong:** `--grep` matches "Merge branch 'fix/...'" in merge commits, generating noise
**Why it happens:** Default git log includes merges; --grep searches message body
**How toavoid:** Use `--no-merges` flag with git log
**Warning signs:** Commit messages showing "Merge" in output

### Pitfall 4: Duplicate entries from multiple sources
**What goes wrong:** Same failure appears in health.json (tool missing) AND in TODO scan (plugin stub)
**Why it happens:** Different sources find related issues
**How to avoid:** Deduplicate by (description + owner) key, merge provenance fields: "health + todo"
**Warning signs:** Entries with identical descriptions but different owners

---

## Code Examples

### Parse health.json for failures
```bash
# Source: nvim-validate.sh line 195-202 (jq pattern)
# Parse failed plugins
failed_plugins=$(jq -r '.plugins[] | select(.loaded == false) | "\(.name): \(.error)"' "$health_json")
# Parse missing tools
missing_tools=$(jq -r '.tools[] | select(.available == false) | .name' "$health_json")
```

### Scan TODO/FIXME patterns
```bash
# Source: grep -rHn pattern (standard Unix)
# Find all TODO/FIXME in lua files
find "$REPO_ROOT/.config/nvim" -name "*.lua" -exec grep -Hn "TODO\|FIXME\|XXX\|BUG" {} \; \
  | while IFS=: read -r file line text; do
      echo "BUG-XXX|$text|$(dirname "$file" | xargs basename)|todo|$file:$line"
    done
```

### Git log keyword scan
```bash
# Source: git log --grep (documented above)
# Find commits with bug/fix/error/crash keywords
git log --oneline --no-merges --grep="bug" --grep="fix" --grep="error" --grep="crash" --all-match \
  --pretty="%h|%s|%ai" 2>/dev/null || true
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual checkhealth | Automated nvim-validate.sh | Phase 4 | Startup/sync/smoke/health automated |
| Ad-hoc bug tracking | FAILURES.md inventory | Phase 6 | Structured failure catalog |
| No git history mining | Git log keyword scan | Phase 6 | Discover historical issues |

**Deprecated/outdated:**
- None — this is new functionality building on nvim-validate.sh

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | git log has no bug/fix/error/crash commits | D-07 git scan | Low — empty git scan means no provenance=git entries, not blocking |
| A2 | jq is available on Arch Linux | Common tools | Low — pacman install jq easy if missing |
| A3 | 23 TODO entries are actual bugs not features | TODO scan | Medium — human review during D-10 filters false positives |

---

## Open Questions

1. **What should happen if git log returns no matches?**
   - What we know: Currently no bug/fix/error/crash commits exist
   - What's unclear: Is this a problem or expected for a new-ish config?
   - Recommendation: Log "No bug-related commits found" to audit output, continue with other sources

2. **How to handle duplicate failures from different sources?**
   - What we know: D-02 says merge into unified inventory with provenance field
   - What's unclear: Exact deduplication key — description alone? description+owner?
   - Recommendation: Use (description + owner) as key, comma-join provenance values

3. **When to stop adding entries to FAILURES.md?**
   - What we know: D-25 says Discovered entries need manual verification
   - What's unclear: Infinite loop risk if new failures keep appearing
   - Recommendation: Script captures what it can; human review is the gate

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| bash | Script execution | ✓ | 5.x | — |
| jq | JSON parsing | ✓? | 1.7+ | `pacman -S jq` |
| git | Log scanning | ✓ | any | — |
| nvim | Headless validation | ✓ | 0.12.1+ | — |

**Missing dependencies with no fallback:**
- None identified

**Missing dependencies with fallback:**
- jq (if missing) — install via system package manager

---

## Validation Architecture

> Skip this section if workflow.nyquist_validation is explicitly set to false. If absent, treat as enabled.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | bash (existing nvim-validate.sh) |
| Config file | `scripts/nvim-validate.sh` (read-only for audit script) |
| Quick run command | `./scripts/nvim-audit-failures.sh` |
| Full suite command | `./scripts/nvim-audit-failures.sh && cat FAILURES.md` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| BUG-01 | Keymap runtime errors | smoke + manual | `nvim-validate.sh smoke` + manual | ✅ (smoke) |
| BUG-02 | Plugin workflow errors | health + manual | `nvim-validate.sh health` + manual | ✅ (health) |
| BUG-03 | Config-caused crashes | startup + manual | `nvim-validate.sh startup` + manual | ✅ (startup) |
| TEST-01 | Repo validation commands | automated | `nvim-validate.sh all` | ✅ |

### Sampling Rate
- **Per task commit:** Run `./scripts/nvim-audit-failures.sh` and inspect FAILURES.md
- **Per wave merge:** Full validation via nvim-validate.sh + audit script
- **Phase gate:** Script runs, FAILURES.md generated with Discovered entries

### Wave 0 Gaps
- [ ] `scripts/nvim-audit-failures.sh` — main audit script (NEW)
- [ ] `.planning/phases/06-runtime-failure-inventory/FAILURES.md` — generated output
- [ ] `.planning/phases/06-runtime-failure-inventory/CHECKLIST.md` — generated after manual review

---

## Security Domain

> Required when `security_enforcement` is enabled (absent = enabled). Omit only if explicitly `false` in config.

This phase is a read-only audit — it scans existing files and generates reports. No security implications beyond standard shell script practices (already enforced by nvim-validate.sh's `set -euo pipefail`).

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V1 Architecture | No | N/A — not building new features |
| V2 Authentication | No | N/A — not adding auth |
| V5 Input Validation | No | N/A — not accepting user input |

---

## Sources

### Primary (HIGH confidence)
- `scripts/nvim-validate.sh` — existing validation harness, D-03/D-04 reference
- `.config/nvim/lua/core/health.lua` — health snapshot module, D-01 reference
- `.planning/phases/06-runtime-failure-inventory/06-CONTEXT.md` — phase decisions

### Secondary (MEDIUM confidence)
- `git log --grep` documentation — WebSearch results for patterns
- grep -rHn pattern usage — standard Unix tools

### Tertiary (LOW confidence)
- None

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — existing tools (bash, jq, git, nvim) are well-understood
- Architecture: HIGH — follows nvim-validate.sh pattern exactly as specified in D-03/D-04
- Pitfalls: MEDIUM — derived from shell script best practices, may have edge cases

**Research date:** 2026-04-18
**Valid until:** 30 days (stable — shell script patterns don't change frequently)