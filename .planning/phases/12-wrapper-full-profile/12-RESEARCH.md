# Phase 12: Wrapper full-profile - Research

**Researched:** 2026-08-11
**Domain:** Bash thin wrapper (`arch/dots-hyprland.sh`) — opt-in `--full` meta-flag; SAFE_DEFAULTS injection gate; dry-run argv proof
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Opt-in CLI shape
- **D-01:** Opt-in is a **wrapper-owned meta-flag `--full`** on existing subcommands — **not** a new `install-full` subcommand. Pattern matches `--dry-run` / `--allow-skip-backup` (strip before forwarding to `./setup`). — **Reversibility:** costly — help, tests, and Phase 14/15 docs will cite `--full`
- **D-02:** `--full` is accepted only on **`install` and `install-files`** — the same subcommands where SAFE_DEFAULTS are injected today (`needs_safe_defaults`). Not on bare `install-deps` / `install-setups` as a standalone full profile. — **Reversibility:** reversible
- **D-03:** When `--full` is active, **inject nothing from SAFE_DEFAULTS** — do not prepend `--core`, `--skip-hyprland`, or `--skip-sysupdate`. Operator may still pass extra upstream flags; wrapper does not re-add residual safe flags. Encodes Phase 11 D-05. — **Reversibility:** costly — first full-adopt argv contract for Phases 14–15
- **D-04:** **Rewrite `usage()` / help:** remove the note that full hypr requires calling vendor `./setup` outside this wrapper. Document wrapper `--full` as the primary full path. — **Reversibility:** reversible
- **D-05:** Default `install` / `install-files` **without** `--full` continue to inject `SAFE_DEFAULTS=(--core --skip-hyprland --skip-sysupdate)` unchanged (FULL-02 / Phase 11 D-10). — **Reversibility:** one-way if violated — accidental full default is milestone anti-goal

#### Full-path confirmation gate
- **D-06:** Full path uses the **same type-yes interactive backup gate** pattern as safe install — not a stronger phrase (e.g. type `FULL`) and not a two-step gate. Messaging is full-specific. — **Reversibility:** reversible
- **D-07:** Full-path gate messaging **must** cover: no SAFE_DEFAULTS residual flags on this path; hypr conf may become `.old`; misc may overwrite when `--core` is absent; sysupdate/`pacman -Syu` may run on deps path; upstream backup dir (`~/ii-original-dots-backup`); still refuse bare `--skip-backup`. — **Reversibility:** reversible
- **D-08:** **`--dry-run` with `--full` still hits the interactive gate**, then prints would-exec argv (same order as safe `install --dry-run` today). FULL-04 is about argv content, not skipping intentionality. — **Reversibility:** reversible
- **D-09:** Bare `--skip-backup` on full path is **still refused** without `--allow-skip-backup` (FULL-03). Do **not** invent a “never allow skip on full” harder rule. — **Reversibility:** reversible

#### Process gate in wrapper
- **D-10:** Phase 12 is **pure capability** — wrapper does **not** check for presence or “Complete” status of `10-INVENTORY.md` / `11-DISPOSITIONS.md`. No hard refuse, no soft warn based on planning artifacts. — **Reversibility:** costly if later hard-coded into wrapper — couples `arch/` to `.planning/` layout
- **D-11:** **ADOPT-01 process gate** (INV+DISP satisfied before live full install) remains **Phase 14 / operator discipline**, not wrapper enforcement. — **Reversibility:** costly — Phase 14 plans must enforce the process gate
- **D-12:** **No runtime policy engine** in Phase 12 — no host scan for dual-run chrome still in `exec-once`, no re-interpretation of dispositions, no “SAFE_DEFAULTS would be safer” refusal. Gate messaging is the warning. — **Reversibility:** reversible
- **D-13:** `usage()` / help **points** at playbook (`docs/dots-hyprland-workflow.md`) and INV/DISP phase artifact paths so operators know the intended sequence. Full sequence polish is Phase 15; Phase 12 only needs discoverable pointers. — **Reversibility:** reversible

#### Post-install hooks under full
- **D-14:** After `--full` on `install` / `install-files` (including the deps portion of unified `install`), **PROTECT_EXPLICIT re-mark always runs** — same protect list and behavior as the safe path (FULL-05). Do not expand PROTECT_EXPLICIT in this phase. — **Reversibility:** one-way if skipped — personal stack can be left asdeps after full deps
- **D-15:** **Keep `enable_hypr_ii_hooks`** on `--full` the same as the safe path (write/enable `qs -c ii` + `ILLOGICAL_IMPULSE_VIRTUAL_ENV` in live + repo `hyprland.conf` targets). Session model nuances after conf→`.old` / lua entry are Phase 13/14 concerns; do not skip hooks in Phase 12. — **Reversibility:** reversible — Phase 14 may revisit hook targets later
- **D-16:** **`--full --dry-run` post-setup plan mirrors the real path:** print protect re-mark plan + would enable ii hooks after the would-exec argv line (same structure as safe dry-run today). — **Reversibility:** reversible
- **D-17:** **No additional post-full side effects** in Phase 12: no chrome process teardown, no pre-flight sync, no overlay writes, no session verify, no live adopt. Those belong to Phases 13–14. — **Reversibility:** reversible

### Claude's Discretion
- Exact help text wording and section layout in `usage()` as long as D-04 and D-13 hold
- Whether full-gate messaging is a separate function (e.g. `full_backup_gate`) or a branch inside `backup_gate` — structure is implementation detail
- How `--full` is parsed/stripped relative to other meta flags (order preservation of remaining user flags must still match WRAP-04 / existing pattern)
- Test/assert harness shape for dry-run argv proofs (help + dry-run only; no live full install this phase)
- Whether dry-run gate can be fed via `printf 'yes\n'` in automated tests the same way safe dry-run is today

### Deferred Ideas (OUT OF SCOPE)
- Phase 13: `hypr/custom` overlays for monitors/workspaces/env must-keeps (D-16 from Phase 11)
- Phase 14: pre-flight live→repo sync (D-07), live full adopt, ADOPT-01 process gate enforcement, chrome accept-remove timing (D-11/D-14), possible revisit of hook targets after lua entry is primary
- Phase 15: playbook safe vs full profile documentation polish
- Expanding PROTECT_EXPLICIT for full-only packages — rejected for Phase 12; reopen only if FULL-05 proof shows a gap
- Harder full-only never-`--skip-backup` — rejected; keep shared `--allow-skip-backup` override
- New `install-full` subcommand — rejected in favor of `--full` flag

None of the above expand Phase 12 scope beyond wrapper full-profile capability.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FULL-01 | Documented explicit opt-in full-install path that does not inject `--skip-hyprland` (other drops only per DISP-02) | `--full` meta-flag; when active inject **nothing** from `SAFE_DEFAULTS` (all three residuals dropped) |
| FULL-02 | Default `install` / `install-files` still inject SAFE_DEFAULTS | Keep existing `needs_safe_defaults` + injection when `full=0` |
| FULL-03 | Full path retains backup gate; bare `--skip-backup` refused without allow | Shared gate + existing dual-key refuse before gate; full messaging only |
| FULL-04 | `--dry-run` on full shows argv without unwanted SAFE_DEFAULTS | Gate still runs (D-08); dry-run print of `cmd` without residual flags |
| FULL-05 | After full install/deps, PROTECT_EXPLICIT re-mark still runs | Do not branch post-setup protect/hooks off for `--full`; dry-run mirrors plan |
</phase_requirements>

## Summary

Phase 12 is a **surgical bash change** in one file: `arch/dots-hyprland.sh`. There is no new package, no new subcommand, and no live full install. The wrapper already owns a meta-flag strip loop (`--dry-run`, `--allow-skip-backup`), SAFE_DEFAULTS injection for `install|install-files`, an interactive type-`yes` backup gate, dry-run argv printing, and post-setup `protect_explicit_packages` + `enable_hypr_ii_hooks`. Phase 12 adds one more stripped meta-flag — **`--full`** — and branches only the **injection** (and gate **messaging**) when it is set.

DISP-02 / Phase 11 D-05 already locked the first full-adopt flag profile: **drop all three** residuals (`--core`, `--skip-hyprland`, `--skip-sysupdate`). Encoding that as “inject nothing from SAFE_DEFAULTS” is the entire argv contract. Default paths without `--full` must keep injecting the triple residual (FULL-02 anti-goal: accidental full default).

**Primary recommendation:** Extend `run_install_family` meta-flag parse with `--full`; when `full=1` on `install|install-files`, skip `cmd+=("${SAFE_DEFAULTS[@]}")`, use full-specific gate messaging (same type-yes), keep skip-backup refuse + post-setup protect/hooks, rewrite `usage()` so wrapper `--full` is the primary full path (remove “call vendor `./setup` outside this wrapper” note), prove via help + `printf 'yes\n' | … --full --dry-run` only.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Opt-in full CLI surface (`--full`) | Wrapper (`arch/dots-hyprland.sh`) | — | Meta-flag strip; never forwarded to `./setup` |
| SAFE_DEFAULTS injection / skip | Wrapper | Upstream `./setup` consumes flags | Injection is wrapper UX; setup owns install logic |
| Backup gate + skip-backup policy | Wrapper | Upstream backup dir | Intentionality before files-touching paths |
| Dry-run argv proof | Wrapper | Plan-task smoke asserts | Non-mutating FULL-04 evidence |
| PROTECT_EXPLICIT re-mark | Wrapper | pacman `-D --asexplicit` | FULL-05; same list as safe path |
| `enable_hypr_ii_hooks` | Wrapper | live + repo `hyprland.conf` | D-15; session nuances later |
| Full-adopt process gate (INV+DISP) | **Out of phase** (Phase 14) | Operator discipline | D-10/D-11 — no `.planning/` coupling |
| Live full install / chrome stop | **Out of phase** (Phase 14) | — | D-17 |
| Playbook safe-vs-full polish | **Out of phase** (Phase 15) | Phase 12 help pointers only | D-13 |

## Standard Stack

This phase installs **no external packages**. Stack is existing bash + host tools already used by the wrapper.

### Core

| Library / Asset | Version / Path | Purpose | Why Standard |
|-----------------|----------------|---------|--------------|
| `arch/dots-hyprland.sh` | repo SoT | Only edit target | Thin wrapper install entry since Phase 6 |
| `bash` (`set -euo pipefail`) | host | Script runtime | All `arch/*.sh` |
| `vendor/dots-hyprland/setup` | submodule pin | Upstream install SoT | Wrapper never reimplements package lists |
| `SAFE_DEFAULTS` array | `arch/dots-hyprland.sh:12` | Residual safe triple | FULL-02 residual; full drops injection of all three |
| Meta-flag strip loop | `run_install_family` ~1365–1382 | Strip wrapper-owned flags | Pattern for `--full` (D-01) |
| `needs_safe_defaults` | ~127–131 | Subcommand scope | Same scope as `--full` (D-02) |
| `backup_gate` | ~149–160 | Type-yes gate | Extend messaging for full (D-06/D-07) |
| `PROTECT_EXPLICIT` + `protect_explicit_packages` | ~197+, ~318+ | Post-install re-mark | FULL-05 / D-14 |
| `enable_hypr_ii_hooks` | ~758+ | Post-install ii hooks | D-15/D-16 |

### Supporting

| Tool / Asset | Purpose | When to Use |
|--------------|---------|-------------|
| `printf 'yes\n' \| … --dry-run` | Feed interactive gate in smoke | FULL-04 / gate messaging asserts |
| `bash -n arch/dots-hyprland.sh` | Syntax check | Every task commit |
| `./arch/dots-hyprland.sh help` | Discoverability (D-04/D-13) | FULL-01 documentation surface |
| `docs/dots-hyprland-workflow.md` | Playbook pointer target | Help text only; no Phase 15 rewrite |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `--full` meta-flag | New `install-full` subcommand | **Rejected** (D-01 / deferred) — breaks thin UX |
| Drop only `--skip-hyprland` | Drop all three residuals | **Rejected** — DISP-02 / Phase 11 D-05 is drop-all-three |
| Harder type-`FULL` gate | Same type-`yes` | **Rejected** (D-06) |
| Refuse bare `--skip-backup` forever on full | Shared `--allow-skip-backup` | **Rejected** (D-09) |
| Check INV/DISP files in wrapper | Phase 14 process gate | **Rejected** (D-10/D-11) |

**Installation:** none.

```bash
# No npm/pip/cargo. Only edit + chmod already executable:
# arch/dots-hyprland.sh
```

## Package Legitimacy Audit

> Phase 12 installs **no external packages**.

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| — | — | — | — | — | N/A | No installs |

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```text
Operator argv
  ./arch/dots-hyprland.sh <subcmd> [--full] [--dry-run] [--allow-skip-backup] [upstream flags…]
        │
        ▼
  main() allowlist
        │
        ▼
  run_install_family(subcmd, args…)
        │
        ├─ strip wrapper meta: --dry-run | --allow-skip-backup | --full  (never forward)
        │     remaining → user_flags[] (order preserved, WRAP-04)
        ├─ preflight (submodule .git + setup +x)
        ├─ if user_flags contain --skip-backup && !allow_skip_backup → FAIL (FULL-03)
        ├─ if needs_safe_defaults(subcmd) && !help-only:
        │       backup_gate / full_backup_gate  (type "yes"; messaging branches on full)
        ├─ build cmd = (./setup subcmd)
        │       if needs_safe_defaults && !full → prepend SAFE_DEFAULTS
        │       if full → prepend nothing from SAFE_DEFAULTS
        │       append user_flags
        ├─ log [INSTALL] argv
        ├─ if dry_run:
        │       print would-exec
        │       print protect plan + enable_hypr_ii_hooks plan (install|install-deps|install-files)
        │       exit 0   ← Phase 12 success proofs stop here
        └─ else:
                (cd II_ROOT; "${cmd[@]}")   ← Phase 14 live adopt only
                protect_explicit_packages
                enable_hypr_ii_hooks
```

### Recommended Project Structure

```text
arch/
└── dots-hyprland.sh          # sole implementation surface for Phase 12
docs/
└── dots-hyprland-workflow.md # help pointer only (no Phase 15 polish)
.planning/phases/12-wrapper-full-profile/
└── 12-*.md                   # planning artifacts; wrapper must NOT read these at runtime
```

No new files required for capability. Smoke may be inline plan asserts (Phase 6 style) or a small script under discretion — not a new product path.

### Pattern 1: Wrapper-owned meta-flag strip (extend for `--full`)

**What:** Scan remaining args after subcommand; set local booleans for wrapper-owned flags; never put them in `user_flags` / `cmd`.
**When to use:** Any flag that `./setup` does not understand (unknown long opts fail upstream).
**Seam today** [VERIFIED: `arch/dots-hyprland.sh:1365-1382`]:

```bash
# Source: arch/dots-hyprland.sh:1365-1382
  # Scan remaining args: strip wrapper-owned meta flags; preserve order (WRAP-04)
  local dry_run=0
  local allow_skip_backup=0
  local -a user_flags=()
  local arg
  for arg in "$@"; do
    case "$arg" in
      --dry-run)
        dry_run=1
        ;;
      --allow-skip-backup)
        allow_skip_backup=1
        ;;
      *)
        user_flags+=("$arg")
        ;;
    esac
  done
```

**Phase 12 delta:** add `local full=0` and a `--full)` arm that sets `full=1` (same strip pattern as `--dry-run`).

### Pattern 2: Conditional SAFE_DEFAULTS injection

**What:** Prepend residual safe triple only for files-touching subcommands **and only when not full**.
**Seams today** [VERIFIED: `arch/dots-hyprland.sh:12`]:

```bash
SAFE_DEFAULTS=(--core --skip-hyprland --skip-sysupdate)
```

[VERIFIED: `arch/dots-hyprland.sh:127-131`]:

```bash
needs_safe_defaults() {
  case "$1" in
    install|install-files) return 0 ;;
    *) return 1 ;;
  esac
}
```

[VERIFIED: `arch/dots-hyprland.sh:1399-1407`]:

```bash
  # Build argv: ./setup <sub> [SAFE_DEFAULTS…] [user flags…] (D-09)
  local -a cmd=(./setup "$subcmd")
  if needs_safe_defaults "$subcmd"; then
    echo "[CONFIG] safe defaults: ${SAFE_DEFAULTS[*]}"
    cmd+=("${SAFE_DEFAULTS[@]}")
  fi
```

**Phase 12 delta:** gate the `if needs_safe_defaults` body on `full == 0` (or `if needs_safe_defaults && ((full==0))`). When full, optionally log `[CONFIG] full profile: no SAFE_DEFAULTS injection` so dry-run evidence is explicit.

### Pattern 3: Backup gate still on dry-run; full messaging

**What:** Interactive type-`yes` before any files-touching path, including dry-run.
**Seam today** [VERIFIED: `arch/dots-hyprland.sh:149-160`]:

```bash
backup_gate() {
  echo "[CONFIG] Upstream may backup clashing paths to: ~/ii-original-dots-backup"
  echo "[CONFIG] install-files will overwrite ~/.config/quickshell (Quickshell tree / rsync --delete)."
  echo "[CONFIG] Defaults include --skip-hyprland so personal hyprland.conf is not renamed."
  echo "[CONFIG] Do NOT pass --skip-backup on first adoption."
  local ans
  read -r -p "Type 'yes' to continue: " ans
  if [[ "$ans" != "yes" ]]; then
    echo "[FAIL] Aborted (backup gate). No ./setup invoked." >&2
    exit 1
  fi
}
```

Call site still tied to `needs_safe_defaults` [VERIFIED: `arch/dots-hyprland.sh:1394-1397`]:

```bash
  if needs_safe_defaults "$subcmd" && ! is_help_only_user_flags user_flags; then
    backup_gate
  fi
```

**Phase 12 delta:** pass `full` into gate (or branch): full messaging per D-07 (no residual flags; conf may → `.old`; misc overwrite without `--core`; Syu may run; backup dir; still refuse bare skip-backup). Keep exact token `yes`.

### Pattern 4: Post-setup protect + hooks unchanged under full

**Seam today** [VERIFIED: `arch/dots-hyprland.sh:1411-1442`]:

```bash
  if ((dry_run)); then
    echo "[CONFIG] dry-run: would exec from $II_ROOT: ${cmd[*]}"
    case "$subcmd" in
      install|install-deps|install-files)
        echo "[CONFIG] dry-run: after setup, would re-mark protect-list as explicit (ii demotes deps)"
        protect_explicit_packages 1 "PROTECT"
        echo "[CONFIG] dry-run: after setup, would enable ii hooks in live + repo hyprland.conf"
        enable_hypr_ii_hooks 1
        ;;
    esac
    exit 0
  fi
  …
  case "$subcmd" in
    install|install-deps|install-files)
      echo "[PROTECT] Post-install: re-marking personal dual-run stack as explicit…"
      protect_explicit_packages 0 "PROTECT" || { … }
      enable_hypr_ii_hooks 0
      ;;
  esac
```

**Phase 12 rule:** do **not** exclude `--full` from these cases (D-14..D-16). Do **not** expand `PROTECT_EXPLICIT`.

### Pattern 5: usage() rewrite (D-04 / D-13)

**Current anti-pattern note to remove** [VERIFIED: `arch/dots-hyprland.sh:113-114`]:

```text
Note: once defaults inject --skip-hyprland there is no upstream undo flag.
Full hypr install requires calling vendor/dots-hyprland/./setup outside this wrapper.
```

**Replace with:** document `--full` as primary full path on `install` / `install-files`; list it under wrapper-owned meta flags; keep safe-defaults section for default path; point to `docs/dots-hyprland-workflow.md` and INV/DISP artifact paths (discoverable pointers only).

### Anti-Patterns to Avoid

- **New subcommand `install-full`:** rejected (D-01); fractures allowlist and docs.
- **Forwarding `--full` to `./setup`:** setup will reject unknown long options; must strip.
- **Partial residual drop (only skip-hyprland):** violates DISP-02 / D-03 — full = inject nothing from SAFE_DEFAULTS.
- **Skipping gate on `--full --dry-run`:** violates D-08; intentionality > convenience.
- **Reading `.planning/` from the wrapper:** violates D-10; couples product to planning layout.
- **Live full install in Phase 12 smokes:** deferred to Phase 14; smoke is help + dry-run only.
- **Expanding PROTECT_EXPLICIT “just in case”:** D-14 / deferred; reopen only with evidence.
- **Leaving usage() vendor-outside note:** confuses operators; D-04 requires rewrite.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Full install CLI | New subcommand / second wrapper | `--full` meta-flag in existing strip loop | Matches `--dry-run` / `--allow-skip-backup`; D-01 |
| Flag profile engine | Staged multi-profile state machine | Binary: inject SAFE_DEFAULTS or inject nothing | DISP-02 is drop-all-three for first full adopt |
| Process / inventory gate | File existence checks for INV/DISP | Help pointers + Phase 14 discipline | D-10/D-11 |
| Host policy engine | Scan chrome exec-once / re-read dispositions | Gate messaging text | D-12 |
| Custom protect list for full | New package arrays | Existing `PROTECT_EXPLICIT` | D-14; asdeps residual still covered |
| Package install reimplementation | Copy `sdata` lists into `arch/` | Upstream `./setup` | Thin wrapper invariant since Phase 6 |
| Eval / string exec | `eval "$cmd_str"` | Array exec `"${cmd[@]}"` | Existing T-06-04 / security pattern |
| Automated live full install test | Mutating CI install | `printf 'yes\n' \| … --full --dry-run` | Phase 12 success criteria 4; D-17 |

**Key insight:** Full profile is **not** a new product path — it is the **absence** of SAFE_DEFAULTS injection on the same install family, behind an explicit meta-flag and the same intentionality gate.

## Code Examples

Illustrative patterns for the planner/executor (not full implementation).

### Meta-flag parse including `--full`

```bash
# Illustrative — extend run_install_family strip loop
# Pattern source: arch/dots-hyprland.sh:1365-1382
local dry_run=0
local allow_skip_backup=0
local full=0
local -a user_flags=()
local arg
for arg in "$@"; do
  case "$arg" in
    --dry-run) dry_run=1 ;;
    --allow-skip-backup) allow_skip_backup=1 ;;
    --full) full=1 ;;
    *) user_flags+=("$arg") ;;
  esac
done

# D-02: --full only on install|install-files
if ((full == 1)) && ! needs_safe_defaults "$subcmd"; then
  echo "[FAIL] --full is only valid with install or install-files." >&2
  exit 1
fi
```

### Conditional SAFE_DEFAULTS skip

```bash
# Illustrative — replace injection block at arch/dots-hyprland.sh:1399-1407
local -a cmd=(./setup "$subcmd")
if needs_safe_defaults "$subcmd" && ((full == 0)); then
  echo "[CONFIG] safe defaults: ${SAFE_DEFAULTS[*]}"
  cmd+=("${SAFE_DEFAULTS[@]}")
elif needs_safe_defaults "$subcmd" && ((full == 1)); then
  echo "[CONFIG] full profile: no SAFE_DEFAULTS injection (DISP-02 drop-all-three)"
fi
if ((${#user_flags[@]} > 0)); then
  cmd+=("${user_flags[@]}")
fi
```

### Dry-run proof commands (smoke)

```bash
# Default still injects (FULL-02 / negative control)
printf 'yes\n' | ./arch/dots-hyprland.sh install --dry-run | tee /tmp/p12-safe.txt
grep -q -- '--core' /tmp/p12-safe.txt
grep -q -- '--skip-hyprland' /tmp/p12-safe.txt
grep -q -- '--skip-sysupdate' /tmp/p12-safe.txt

# Full drops all three (FULL-01 / FULL-04)
printf 'yes\n' | ./arch/dots-hyprland.sh install --full --dry-run | tee /tmp/p12-full.txt
grep -q 'would exec' /tmp/p12-full.txt
! grep -q -- '--skip-hyprland' /tmp/p12-full.txt
! grep -q -- '--skip-sysupdate' /tmp/p12-full.txt
# --core: must not appear as injected residual; be careful if user passed unrelated text
! grep -E -- '(^|[[:space:]])--core([[:space:]]|$)' /tmp/p12-full.txt

# Protect plan still present (FULL-05 / D-16)
grep -q 'protect-list' /tmp/p12-full.txt
grep -qi 'ii hooks' /tmp/p12-full.txt

# Bare --skip-backup still refused on full (FULL-03)
./arch/dots-hyprland.sh install --full --skip-backup --dry-run; test $? -ne 0
```

### Help surface checks (FULL-01 / D-04 / D-13)

```bash
./arch/dots-hyprland.sh help | tee /tmp/p12-help.txt
grep -q -- '--full' /tmp/p12-help.txt
grep -q 'dots-hyprland-workflow' /tmp/p12-help.txt
# Old vendor-outside primary path must be gone:
! grep -qi 'Full hypr install requires calling vendor' /tmp/p12-help.txt
```

## Common Pitfalls

### Pitfall 1: Accidental full as default (FULL-02 anti-goal)
**What goes wrong:** SAFE_DEFAULTS stop injecting for all install paths, or `--full` becomes implied.
**Why it happens:** Refactoring `needs_safe_defaults` instead of branching injection; inverting the full flag.
**How to avoid:** Keep `SAFE_DEFAULTS=(--core --skip-hyprland --skip-sysupdate)` literal; only skip prepend when `full=1`. Always run **negative** dry-run test without `--full`.
**Warning signs:** Default dry-run argv missing `--skip-hyprland`.

### Pitfall 2: Forwarding `--full` to `./setup`
**What goes wrong:** Live (or dry-run would-exec) includes `--full`; setup fails on unrecognized option.
**Why it happens:** Forgetting to add `--full` to the strip `case`.
**How to avoid:** Same arm as `--dry-run`; assert `! grep -- '--full'` on would-exec line (meta must be absent from `cmd`).
**Warning signs:** would-exec contains `--full`.

### Pitfall 3: Partial residual drop
**What goes wrong:** Full path still injects `--core` or `--skip-sysupdate` while dropping only hypr skip.
**Why it happens:** Misreading FULL-01 wording (“does not inject `--skip-hyprland`”) without DISP-02.
**How to avoid:** D-03 / Phase 11 D-05: inject **nothing** from SAFE_DEFAULTS. Assert absence of all three flags.
**Warning signs:** would-exec still shows `--core` or `--skip-sysupdate` on `--full`.

### Pitfall 4: Skipping gate on dry-run full
**What goes wrong:** Tests pipe nothing and hang, or gate is bypassed for convenience.
**Why it happens:** Assuming dry-run means non-interactive end-to-end.
**How to avoid:** D-08 — gate still runs; use `printf 'yes\n' |` as Phase 6 did. Abort path with `printf 'no\n'` still exits non-zero.
**Warning signs:** Hang on `read -r -p` in CI; or dry-run without “Type 'yes'”.

### Pitfall 5: Gate messaging still claims `--skip-hyprland` protects conf
**What goes wrong:** Full path prints safe-path messaging (“Defaults include --skip-hyprland…”) while argv has no skip — operator is misled.
**Why it happens:** Reusing `backup_gate` text verbatim for full.
**How to avoid:** D-07 full-specific messages: conf may become `.old`; misc may overwrite; Syu may run; still no bare skip-backup.
**Warning signs:** Full dry-run output still says personal hyprland.conf is not renamed.

### Pitfall 6: Post-setup protect skipped on full
**What goes wrong:** Full deps demote personal stack to asdeps; orphan cleanup later wipes hyprland/kitty/…
**Why it happens:** Special-casing full as “different pipeline” and omitting protect case.
**How to avoid:** D-14/D-16 — same post-setup case arms; dry-run must still print protect plan.
**Warning signs:** Full dry-run ends after would-exec with no protect/hooks lines.

### Pitfall 7: Accepting `--full` on `install-deps` alone
**What goes wrong:** Confusing “deps of full install” with a standalone full profile on deps-only.
**Why it happens:** Over-generalizing “full means no SAFE_DEFAULTS” to all subcommands (deps already inject none).
**How to avoid:** D-02 — accept only on `install|install-files`; refuse otherwise with clear `[FAIL]`.
**Warning signs:** `install-deps --full` silently succeeds as if it were a profile.

### Pitfall 8: Help still points operators outside the wrapper
**What goes wrong:** Operators run raw vendor `./setup` as “the full path,” bypassing gate/protect/hooks.
**Why it happens:** Leaving lines 113–114 usage note.
**How to avoid:** D-04 rewrite; examples include `install --full` and `install --full --dry-run`.
**Warning signs:** `help | grep -i 'outside this wrapper'`.

## Validation Architecture

> `workflow.nyquist_validation` is **true** in `.planning/config.json` — this section is required.
> **No live full install this phase.** All automated checks are help / dry-run / refuse / syntax.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Inline bash smoke asserts (Phase 6/07 pattern) — no bats/pytest suite in repo |
| Config file | none — plan-task `<verify><automated>` commands |
| Quick run command | `bash -n arch/dots-hyprland.sh && ./arch/dots-hyprland.sh help >/dev/null` |
| Full suite command | Quick run + FULL-01..05 dry-run/refuse matrix below (all non-mutating) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FULL-01 | Help documents `--full`; full dry-run argv has no `--skip-hyprland` (and no other SAFE_DEFAULTS residuals per DISP-02) | smoke | `./arch/dots-hyprland.sh help \| grep -q -- '--full'`; `printf 'yes\n' \| ./arch/dots-hyprland.sh install --full --dry-run \| tee /tmp/p12-full.txt`; `! grep -q -- '--skip-hyprland' /tmp/p12-full.txt`; `! grep -q -- '--skip-sysupdate' /tmp/p12-full.txt`; `! grep -E -- '(^|[[:space:]])--core([[:space:]]|$)' /tmp/p12-full.txt` | ❌ Wave 0 (impl + asserts) |
| FULL-02 | Default install still injects triple residual | smoke (negative) | `printf 'yes\n' \| ./arch/dots-hyprland.sh install --dry-run \| tee /tmp/p12-safe.txt`; `grep -q -- '--core' /tmp/p12-safe.txt && grep -q -- '--skip-hyprland' /tmp/p12-safe.txt && grep -q -- '--skip-sysupdate' /tmp/p12-safe.txt` | ❌ Wave 0 |
| FULL-02b | Default install-files still injects | smoke | same as FULL-02 with `install-files` | ❌ Wave 0 |
| FULL-03 | Bare `--skip-backup` refused on full without allow | smoke | `./arch/dots-hyprland.sh install --full --skip-backup --dry-run; test $? -ne 0` | ❌ Wave 0 |
| FULL-03b | Dual-key allow still works; meta stripped | smoke | `printf 'yes\n' \| ./arch/dots-hyprland.sh install --full --skip-backup --allow-skip-backup --dry-run \| tee /tmp/p12-sb.txt`; `grep -q -- '--skip-backup' /tmp/p12-sb.txt`; `! grep -q -- '--allow-skip-backup' /tmp/p12-sb.txt`; `! grep -q -- '--full' /tmp/p12-sb.txt` | ❌ Wave 0 |
| FULL-04 | Full dry-run shows would-exec without SAFE_DEFAULTS; gate still hit | smoke | `printf 'yes\n' \| ./arch/dots-hyprland.sh install --full --dry-run 2>&1 \| tee /tmp/p12-full4.txt`; `grep -q 'Type' /tmp/p12-full4.txt \|\| grep -q "yes" /tmp/p12-full4.txt`; `grep -q 'would exec' /tmp/p12-full4.txt`; residual absence as FULL-01 | ❌ Wave 0 |
| FULL-05 | Full dry-run still plans protect re-mark (+ ii hooks per D-16) | smoke | `grep -q 'protect-list' /tmp/p12-full.txt`; `grep -qi 'ii hooks\|enable ii hooks' /tmp/p12-full.txt` | ❌ Wave 0 |
| D-02 | `--full` refused on install-deps | smoke | `./arch/dots-hyprland.sh install-deps --full --dry-run; test $? -ne 0` | ❌ Wave 0 |
| D-04 | usage no longer says full requires vendor outside wrapper | grep | `! ./arch/dots-hyprland.sh help \| grep -qi 'Full hypr install requires calling vendor'` | ❌ Wave 0 |
| D-07 | Full gate messaging covers blast-radius themes | smoke | `printf 'yes\n' \| ./arch/dots-hyprland.sh install --full --dry-run 2>&1 \| tee /tmp/p12-gate.txt`; greps for backup dir `ii-original-dots-backup`; and full-risk themes (e.g. `.old` / sysupdate / no SAFE_DEFAULTS residual — exact strings per implementation discretion) | ❌ Wave 0 |
| D-13 | Help points at playbook | grep | `./arch/dots-hyprland.sh help \| grep -q 'dots-hyprland-workflow'` | ❌ Wave 0 |
| syntax | Script parses | unit | `bash -n arch/dots-hyprland.sh` | ✅ script exists |

### Sampling Rate

- **Per task commit:** `bash -n arch/dots-hyprland.sh` + the task’s automated verify block
- **Per wave merge:** Full FULL-01..05 matrix (safe residual + full drop + refuse + protect plan + help)
- **Phase gate:** Full suite green before `/gsd-verify-work`; **no** live `install --full` without `--dry-run`

### Wave 0 Gaps

- [ ] Implement `--full` strip + conditional injection + full gate messaging + usage rewrite in `arch/dots-hyprland.sh`
- [ ] Plan-task automated verify commands for FULL-01..05 matrix (inline; no dedicated test framework today)
- [ ] Optional: small `scripts/phase12-full-smoke.sh` if planner prefers one harness (discretion) — **not required** if plan verifies inline
- [ ] **Do not** add live full install / session mutation checks this phase

*(Existing Phase 6 dry-run patterns remain the template; there is no checked-in bats/pytest suite under `tests/`.)*

### Concrete command cheatsheet (planner copy-paste)

```bash
# Syntax
bash -n arch/dots-hyprland.sh

# Help / discoverability
./arch/dots-hyprland.sh help | grep -E -- '--full|dots-hyprland-workflow|SAFE_DEFAULTS|safe defaults'

# Safe residual (must still inject)
printf 'yes\n' | ./arch/dots-hyprland.sh install --dry-run
printf 'yes\n' | ./arch/dots-hyprland.sh install-files --dry-run

# Full profile argv (must NOT inject residuals)
printf 'yes\n' | ./arch/dots-hyprland.sh install --full --dry-run
printf 'yes\n' | ./arch/dots-hyprland.sh install-files --full --dry-run

# Negative: bare skip-backup
./arch/dots-hyprland.sh install --full --skip-backup --dry-run   # expect non-zero

# Negative: --full on wrong subcommand
./arch/dots-hyprland.sh install-deps --full --dry-run            # expect non-zero

# Gate abort still works
printf 'no\n' | ./arch/dots-hyprland.sh install --full --dry-run # expect non-zero
```

## Security Domain

> `security_enforcement` is enabled (ASVS level 1).

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | N/A — local operator script |
| V3 Session Management | no | N/A |
| V4 Access Control | partial | Interactive type-yes gate before files-touching; dual-key for `--skip-backup` |
| V5 Input Validation | yes | Allowlist subcommands; strip unknown wrapper meta; refuse bare skip-backup; refuse `--full` off-scope |
| V6 Cryptography | no | N/A — no crypto added |
| Command injection | yes | Array exec only `"${cmd[@]}"` — never `eval` |
| Privilege | yes | Post-setup may use `sudo pacman` on real path; dry-run must not invoke setup/sudo mutate |

### Known Threat Patterns for bash install wrappers

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Accidental destructive full install | Elevation / Tampering | Opt-in `--full` + type-yes gate; default keeps SAFE_DEFAULTS |
| Bare `--skip-backup` data loss | Tampering | Refuse without `--allow-skip-backup` (shared full+safe) |
| Meta-flag leak to setup | Denial / crash | Strip `--full` / `--dry-run` / `--allow-skip-backup` |
| `eval` of argv string | Injection | Array exec only (existing) |
| Planning-doc path coupling | Info disclosure / brittle authz-by-files | No INV/DISP filesystem checks (D-10) |
| Live mutation in “tests” | Tampering | Phase 12 smokes dry-run only |

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `bash` | wrapper runtime | ✓ (script shebang) | host | — |
| `arch/dots-hyprland.sh` | all FULL-* | ✓ | repo | — |
| `vendor/dots-hyprland` submodule + `setup` +x | preflight / dry-run path | required for dry-run past preflight | pin | init submodule (not auto) |
| `printf` / coreutils | smoke gate feed | ✓ | host | — |
| Network / yay / live pacman mutate | live full install | N/A this phase | — | **out of scope** |

**Missing dependencies with no fallback:** none for Phase 12 scope (assuming submodule already initialized as in prior phases).

**Missing dependencies with fallback:** none material.

Step 2.6 note: phase is code/config + non-mutating smokes; no new external services.

## State of the Art

| Old Approach | Current Approach (Phase 12 target) | When Changed | Impact |
|--------------|-------------------------------------|--------------|--------|
| Full hypr = call vendor `./setup` outside wrapper | Wrapper `install --full` / `install-files --full` | Phase 12 | Gate + protect + hooks preserved |
| Always inject SAFE_DEFAULTS on install paths | Inject unless `--full` | Phase 12 | Explicit opt-in full argv |
| No wrapper full dry-run proof | `printf 'yes\n' \| … --full --dry-run` | Phase 12 (from Phase 10 D-08 deferral) | FULL-04 evidence |
| Staged multi-axis soft profiles (early drafts) | Drop-all-three first full-adopt (DISP-02) | Phase 11 D-05 | Single full profile to encode |

**Deprecated/outdated:**
- Help text “Full hypr install requires calling vendor… outside this wrapper” — remove (D-04)
- Treating raw vendor `./setup` as the **primary** full path — secondary escape only for non-allowlisted experimental tools

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Refusing `--full` on non-`install`/`install-files` with non-zero exit is the preferred D-02 encoding (vs silent ignore) | Architecture / Code Examples | Low — either satisfies “accepted only”; refuse is clearer for operators |
| A2 | Optional one-line `[CONFIG] full profile: no SAFE_DEFAULTS injection` log is desirable for dry-run evidence | Code Examples | Low — not locked; greps can key off would-exec alone |
| A3 | Exact full-gate prose strings (beyond D-07 themes) are implementer wording | Pitfalls / Validation | Low — D-07 lists required themes, not fixed sentences |
| A4 | No dedicated `tests/` harness will be introduced this phase (inline plan asserts) | Validation Architecture | Low — matches Phase 6; discretion allows a small smoke script |

**If empty table were required for zero assumptions:** not applicable — four low-risk discretion encodings only; no locked-decision assumptions.

## Open Questions

1. **Exact full-gate wording**
   - What we know: D-07 theme list (no residuals; conf→`.old`; misc overwrite; Syu; backup dir; skip-backup refuse)
   - What's unclear: sentence-level copy
   - Recommendation: planner leaves wording to executor under D-07; validation greps themes not full paragraphs

2. **Smoke harness file vs inline**
   - What we know: Phase 6 used plan-task asserts; Phase 7 added a smoke script for live checks
   - What's unclear: operator preference for a `scripts/phase12-*.sh`
   - Recommendation: default inline verifies; optional script only if multi-plan reuse appears

3. **`--core` absence assertion false positives**
   - What we know: full dry-run must not inject `--core`
   - What's unclear: whether log lines might mention the word in prose (“no --core”)
   - Recommendation: prefer matching would-exec line only, or log full-profile message without spelling residual flags as bare tokens on the exec line

## Sources

### Primary (HIGH confidence)
- `arch/dots-hyprland.sh:12` — `SAFE_DEFAULTS=(--core --skip-hyprland --skip-sysupdate)`
- `arch/dots-hyprland.sh:23-115` — `usage()` including vendor-outside full note at 113–114
- `arch/dots-hyprland.sh:127-131` — `needs_safe_defaults`
- `arch/dots-hyprland.sh:149-160` — `backup_gate`
- `arch/dots-hyprland.sh:197+` / `318-357` — `PROTECT_EXPLICIT` / `protect_explicit_packages`
- `arch/dots-hyprland.sh:758+` — `enable_hypr_ii_hooks`
- `arch/dots-hyprland.sh:1361-1443` — `run_install_family` meta strip, skip-backup refuse, injection, dry-run, post-setup
- `.planning/phases/12-wrapper-full-profile/12-CONTEXT.md` — D-01..D-17 locked
- `.planning/REQUIREMENTS.md` — FULL-01..FULL-05
- `.planning/phases/11-disposition-decisions/11-CONTEXT.md` — D-05 drop-all-three
- `.planning/phases/11-disposition-decisions/11-DISPOSITIONS.md` — DISP-02 full-adopt flag profile
- `.planning/milestones/v0.2-phases/06-thin-setup-wrapper-safe-defaults/06-CONTEXT.md` + `06-VALIDATION.md` + summaries — meta-flag / dry-run proof patterns
- `docs/dots-hyprland-workflow.md` — current safe path; Phase 12 help pointer target

### Secondary (MEDIUM confidence)
- `.planning/phases/10-full-install-impact-inventory/10-RESEARCH.md` — deferred dry-run full-profile proof to Phase 12; validation style
- Phase 6/7 VALIDATION.md command shapes for `printf 'yes\n' | install --dry-run`

### Tertiary (LOW confidence)
- None material — no web research this session (bash wrapper, local SoT)

## Metadata

**Confidence breakdown:**
- Standard stack: **HIGH** — no new deps; single known edit file
- Architecture: **HIGH** — injection/strip/gate/post-setup seams read with line cites this session
- Pitfalls: **HIGH** — derived from locked anti-goals (FULL-02) + Phase 6 historical failures + DISP-02

**Research date:** 2026-08-11
**Valid until:** 30 days (stable bash wrapper; re-check only if `run_install_family` is refactored before execution)
