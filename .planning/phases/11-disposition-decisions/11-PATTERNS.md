# Phase 11: Disposition decisions - Pattern Map

**Mapped:** 2026-08-08  
**Files analyzed:** 3 (create/modify)  
**Analogs found:** 3 / 3  

**Scope note:** Documentation-only phase. Do **not** invent wrapper full-profile code (`arch/`), `hypr/custom` overlays, or live XDG mutation (Phases 12–14).

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.planning/phases/11-disposition-decisions/11-DISPOSITIONS.md` | config (phase SoT markdown) | transform (inventory rows → disposition enums) | `.planning/phases/10-full-install-impact-inventory/10-INVENTORY.md` | exact (phase-dir multi-section tables; columns differ) |
| `scripts/phase11-dispositions-assert.sh` (optional, Claude discretion) | utility / test harness | request-response (read markdown → PASS/FAIL exit) | `scripts/phase10-inventory-assert.sh` | exact (bash Nyquist structural assert) |
| `.planning/phases/11-disposition-decisions/11-VALIDATION.md` | config (validation contract) | batch (checkbox / task status updates during execute) | same file (already seeded) + Phase 10 validation pattern | role-match |

## Pattern Assignments

### `11-DISPOSITIONS.md` (config, transform)

**Analog:** `10-INVENTORY.md` — phase-dir SoT, axis-parallel sections, uniform markdown tables, Sources footer, explicit “no live mutation this phase” scope banner.

**Do not copy from inventory:**
- Neutral effect-only language (Phase 11 **must** write dispositions)
- Path\|Effect\|Risk\|Source\|Host present? columns → replace with D-03 columns
- Chrome **omission** (Phase 10 D-15) → Phase 11 **requires** chrome section with emerged-surface note

**Scope banner pattern** (inventory lines 7–15 — adapt wording for dispositions):

```markdown
## Scope

Committed disposition set for full-adopt planning.

- **Consumes** `10-INVENTORY.md` as SoT for paths (D-04).
- **No** wrapper edits, **no** `hypr/custom` overlays, **no** live `~/.config` mutation this phase.
- Dual-run chrome **included** here as emerged surface (omitted from inventory by Phase 10 D-15).
- Artifact SoT path: this file under the phase dir (D-01), not under `docs/`.
```

**SAFE_DEFAULTS residual narrative pattern** (inventory lines 19–44 — restate for §2 flag profile; D-10 residual unchanged):

```markdown
## SAFE_DEFAULTS residual (default install — unchanged)

From `arch/dots-hyprland.sh:12`:

SAFE_DEFAULTS=(--core --skip-hyprland --skip-sysupdate)

| Fact | Detail | Source |
|------|--------|--------|
| Triple flags | `--core`, `--skip-hyprland`, `--skip-sysupdate` | `arch/dots-hyprland.sh:12` |
| Injection scope | `install` and `install-files` only | `needs_safe_defaults` 127-131 |
| Full-profile opt-in | Future Phase 12; **not** default | D-05 / D-10 |
```

**Axis section + table header pattern** (inventory lines 56–65 — change columns to D-03):

```markdown
## Axis: drop --skip-hyprland (hypr files)

| Path | Inventory risk | Disposition | Rationale | Flag stage | Inventory source |
|------|----------------|-------------|-----------|------------|------------------|
| `~/.config/hypr/hyprland/` | HIGH | accept-upstream | … | full-profile (drop --skip-hyprland) | 10-INVENTORY.md Axis A hyprland/ row |
```

**Disposition enum (D-03) — exact tokens only:**

```text
keep-personal | migrate-to-hypr-custom | accept-upstream | merge | defer
```

**Chrome accept-remove pattern** (from RESEARCH — no inventory analog; invent only with emerged note):

```markdown
## Dual-run chrome (DISP-03)

**Emerged surface:** Waybar/rofi/swaync were **omitted** from 10-INVENTORY.md (Phase 10 D-15).
Dispositioned here by operator decision (D-11), not invented install effects.

| Path / surface | Inventory risk | Disposition | Rationale | Flag stage | Inventory source |
|----------------|----------------|-------------|-----------|------------|------------------|
| waybar session chrome | n/a (emerged) | accept-upstream | accept-remove dual-run chrome (D-11); stop exec-once | full-profile | emerged: Phase 10 D-15; conf:64 |
```

Use enum `accept-upstream` + rationale containing **accept-remove** / D-11 — **do not** invent a sixth enum token.

**Eight-section skeleton (D-02)** — copy structure from RESEARCH recommended outline:

1. Pre-flight repo sync gate (D-07)  
2. Full-adopt flag profile (DISP-02 / D-05 / D-10)  
3. Axis A — hypr HIGH + must-keeps (DISP-01)  
4. Axis B — misc under drop `--core`  
5. Axis C — packages / sysupdate  
6. Dual-run chrome accept-remove (DISP-03)  
7. Lock / idle / paper residual (DISP-04)  
8. UNKNOWN / extra surfaces  

**Must-migrate only (D-16)** — categories from personal conf (not full conf dump):

| Category | Evidence cite | Disposition |
|----------|---------------|-------------|
| monitors | `.config/hypr/hyprland.conf:29-30` | `migrate-to-hypr-custom` |
| workspaces | conf:76-87 | `migrate-to-hypr-custom` |
| env (incl. cursor / `ILLOGICAL_IMPULSE_VIRTUAL_ENV`) | conf:106-111 | `migrate-to-hypr-custom` |

Autostart/binds/chrome exec-once → **not** migrate (D-17). Prefer **two rows** for `hyprland.conf`: primary entry `accept-upstream` (→ `.old`) + must-keep categories `migrate-to-hypr-custom`.

**HIGH path checklist (DISP-01)** — every path must appear once with disposition:

| Axis | Paths |
|------|-------|
| A | `hyprland/`, `hyprland.conf`, `hyprland.lua`, `hyprlock.conf`, `custom/`, `hyprland/scripts/` (or fold under hyprland/ with explicit cite) |
| B | `fish/`, `fontconfig/`, `kitty/`, `starship.toml` |
| C | full install/deps pipeline, `pacman -Syu`, `implicitize_old_dependencies` |

Plus MED–HIGH decision rows: `hypridle.conf`, `mpv/`, `illogical-impulse-hyprland` meta.

**Read-only cite sources (do not modify):**

| File | Use in dispositions |
|------|---------------------|
| `10-INVENTORY.md` | Path/risk/source cites |
| `arch/dots-hyprland.sh:12,127-131,1399-1407` | Residual SAFE_DEFAULTS + injection |
| `.config/hypr/hyprland.conf` | Must-keep category + chrome exec-once evidence |
| `.planning/codebase/INTEGRATIONS.md` | Dual-run chrome narrative for emerged cites |

---

### `scripts/phase11-dispositions-assert.sh` (utility, request-response) — optional

**Analog:** `scripts/phase10-inventory-assert.sh` (full file pattern).

**Imports / shell preamble** (phase10 lines 1–28):

```bash
#!/usr/bin/env bash
# Phase 11 disposition structural/lint asserts (Nyquist).
# Constraints: never rsync/cp/mv/rm into XDG; never call ./setup or arch/ without --dry-run.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

DISP="$REPO_ROOT/.planning/phases/11-disposition-decisions/11-DISPOSITIONS.md"

FAIL=0
pass() { printf '[PASS] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
```

**File-exists + section gates** (phase10 lines 53–111 — retarget paths/headings):

```bash
[[ -f "$DISP" ]] && pass "D-01 dispositions file exists" || fail "missing $DISP"

# Required sections (flexible wording)
grep -qiE 'Pre-flight|repo sync' "$DISP" || fail "section: pre-flight"
grep -qiE 'flag profile|SAFE_DEFAULTS|full-adopt' "$DISP" || fail "section: flag profile"
grep -qiE 'Axis A|hyprland|skip-hyprland' "$DISP" || fail "section: Axis A"
grep -qiE 'Axis B|drop --core|misc' "$DISP" || fail "section: Axis B"
grep -qiE 'sysupdate|packages|Axis C' "$DISP" || fail "section: Axis C"
grep -qiE 'chrome|waybar' "$DISP" || fail "section: chrome"
grep -qiE 'hyprlock|hypridle|lock' "$DISP" || fail "section: lock/idle"
grep -qiE 'UNKNOWN|extra surface' "$DISP" || fail "section: UNKNOWN/extra"
```

**Column header gate** (phase10 D-10 style, lines 113–118 — D-03 columns):

```bash
grep -qiE 'Path.*Inventory risk.*Disposition.*Rationale.*Flag stage.*Inventory source' "$DISP" \
  && pass "D-03 table header" || fail "D-03 table header missing"
```

**Enum / HIGH / residual / chrome — Phase 11 deltas vs phase10:**

| Check | Phase 10 | Phase 11 |
|-------|----------|----------|
| Chrome | **ban** waybar\|rofi\|swaync | **require** all three + accept-remove / DISP-03 override language |
| Disposition language | ban “recommend keep\|migrate” | **require** enum tokens in use |
| HIGH paths | n/a (inventory is source) | `rg -F` each HIGH path string |
| SAFE_DEFAULTS | residual still available | require residual **unchanged on default** (D-10) + full profile drops all three |

```bash
# Enum tokens present (merge may be unused — still allow if grepping whitelist only on row cells)
for d in keep-personal migrate-to-hypr-custom accept-upstream defer; do
  grep -qF "$d" "$DISP" && pass "enum $d" || fail "enum token $d missing"
done

# HIGH path samples
for p in hyprland.conf hyprland.lua starship.toml 'pacman -Syu' fish; do
  grep -qF "$p" "$DISP" && pass "HIGH cite $p" || fail "HIGH cite $p missing"
done

# Chrome REQUIRED (inverse of phase10 D-15)
grep -qiE 'waybar' "$DISP" && grep -qiE 'rofi' "$DISP" && grep -qiE 'swaync' "$DISP" \
  && pass "chrome surfaces named" || fail "chrome waybar/rofi/swaync required"
grep -qiE 'accept-remove|explicit.*remove|overrides? DISP-03|accepted otherwise' "$DISP" \
  && pass "DISP-03 override language" || fail "chrome override language missing"

# Residual default still safe
grep -qF -- '--skip-hyprland' "$DISP" && grep -qiE 'SAFE_DEFAULTS|residual|default' "$DISP" \
  && pass "D-10 residual safe default" || fail "D-10 residual claim missing"
```

**Exit pattern** (phase10 lines 267–272):

```bash
echo "=== done: FAIL=${FAIL} ==="
[[ "$FAIL" -gt 0 ]] && exit 1
printf 'phase11 dispositions asserts OK\n'
exit 0
```

**Do not copy from phase10:** D-15 chrome ban, D-12 “no disposition language” ban, host `--full` PRESENT checklist (optional only; Phase 11 docs prefer inventory cites).

---

### `11-VALIDATION.md` (config, batch status updates)

**Analog:** Already seeded at `.planning/phases/11-disposition-decisions/11-VALIDATION.md`.

**Pattern during execute:** Flip Wave 0 / per-task Status cells `⬜ pending` → `✅ green`; set frontmatter `wave_0_complete` / `nyquist_compliant` when gates pass. Do not invent new test frameworks.

**Quick gate command** (VALIDATION lines 26–27):

```bash
test -f .planning/phases/11-disposition-decisions/11-DISPOSITIONS.md && \
  rg -n 'Disposition|SAFE_DEFAULTS|waybar|hyprlock|migrate-to-hypr-custom' \
  .planning/phases/11-disposition-decisions/11-DISPOSITIONS.md
```

## Shared Patterns

### Phase-dir SoT markdown
**Source:** `10-INVENTORY.md`, Phase 10 `10-PATTERNS.md`  
**Apply to:** `11-DISPOSITIONS.md`  
- Committed under `.planning/phases/…`, not `docs/`  
- Multi-section axis-parallel structure  
- Uniform tables + Sources footer  
- Explicit phase boundary (“docs only / no live mutation”)

### Bash Nyquist assert harness
**Source:** `scripts/phase10-inventory-assert.sh`  
**Apply to:** optional `scripts/phase11-dispositions-assert.sh`  
- `set -euo pipefail`, `REPO_ROOT` via `BASH_SOURCE`  
- `pass`/`fail` + `FAIL` counter  
- Structural `grep` on single artifact  
- Never mutate XDG; never non-dry-run setup

### Flag residual documentation
**Source:** `arch/dots-hyprland.sh:12,127-131,1399-1407` + inventory residual section  
**Apply to:** §2 of `11-DISPOSITIONS.md`  
- Restate SAFE_DEFAULTS triple  
- State injection only for `install` / `install-files`  
- Independent axes for docs **and** first full-adopt = drop all three (D-05/D-32)  
- Anti-goal: default install must not become full (D-10)

### Inventory cite discipline
**Source:** CONTEXT D-04, RESEARCH row map  
**Apply to:** every disposition table row  
- Cite `10-INVENTORY.md` path/section or UNKNOWN id  
- Chrome only via **emerged-surface** note + conf/INTEGRATIONS sources  
- Do not invent misc/package surfaces absent from inventory

## Anti-patterns (planner must ban)

| Anti-pattern | Why |
|--------------|-----|
| Edit `SAFE_DEFAULTS` / implement FULL-* in Phase 11 | Phase 12 |
| Write `hypr/custom` overlays | Phase 13 |
| Execute pre-flight rsync live→repo as Phase 11 work | Phase 14 (document commands only here) |
| `keep-personal` on `hyprland.conf` as primary session entry | Blocks ADOPT-02; violates D-15 |
| Migrate binds/autostart beyond D-16 | Scope creep |
| Sixth enum token `accept-remove` | Breaks DISP-01 five-value contract |
| Copy phase10 chrome **ban** into phase11 assert | Dispositions must name chrome |
| Treat ROADMAP SC3 “default keep” as blocking D-11 | D-11 is explicit accept-otherwise |
| Re-run full Phase 10 inventory rewrite | Consume inventory as SoT |

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| — | — | — | All primary artifacts have strong analogs (inventory + phase10 assert + seeded VALIDATION) |

Chrome **section content** has no prior disposition file analog (inventory deliberately omitted chrome). Use RESEARCH chrome template + INTEGRATIONS / personal conf cites — not a new code path.

## Data flow summary

```text
10-INVENTORY.md (neutral effects) ──► row cites + risks
11-CONTEXT.md D-01..D-32          ──► locked disposition seeds
arch/dots-hyprland.sh             ──► residual flag claims (read-only)
.config/hypr/hyprland.conf        ──► must-keep categories + chrome evidence
                │
                ▼
        11-DISPOSITIONS.md  (eight sections, D-03 tables)
                │
                ▼
   optional phase11-dispositions-assert.sh  ──► structural PASS/FAIL
                │
     ┌──────────┼──────────┬────────────┐
     ▼          ▼          ▼            ▼
  Phase 12   Phase 13   Phase 14    Phase 15
  FULL flags  overlays  pre-flight  playbook
```

## Metadata

**Analog search scope:**  
`.planning/phases/10-full-install-impact-inventory/`, `scripts/phase10-inventory-assert.sh`, `scripts/phase07-live-smoke.sh` (via Phase 10 PATTERNS), `arch/dots-hyprland.sh`, `.config/hypr/hyprland.conf`, phase 11 VALIDATION/RESEARCH/CONTEXT  

**Files scanned:** ~8 primary (inventory, phase10 assert, phase10 PATTERNS, wrapper SAFE_DEFAULTS sites, validation, context, research)  
**Pattern extraction date:** 2026-08-08  
**Prior pattern map:** `10-PATTERNS.md` (assert → phase07; inventory → docs workflow; effect sources read-only)
