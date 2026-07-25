# Phase 6: Thin Setup Wrapper & Safe Defaults - Context

**Gathered:** 2026-07-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Provide a `.dotfiles`-native entrypoint that drives upstream dots-hyprland `./setup` **without** destroying personal Hyprland config.

**In scope:**
- `arch/dots-hyprland.sh` thin wrapper (REPO_ROOT-relative, labeled echos)
- Subcommands: `install`, `install-deps`, `install-setups`, `install-files` → `vendor/dots-hyprland/./setup`
- Safe dual-run default flag profile (`--core --skip-hyprland`, plus agreed extras)
- Backup reminder/gate before files-touching paths; never default to `--skip-backup`
- Extra flags passthrough to `./setup` (WRAP-04)
- Preflight checks for submodule/setup presence
- Smoke tests that **do not** mutate the live machine (help/dry paths only)

**Out of scope this phase:**
- Running real install-deps/setups/files on the machine (Phase 7)
- Session hooks / `qs -c ii` / dual-run verify (Phase 7)
- Retiring local `.config/quickshell` or `arch/quickshell.sh` (Phase 8)
- Full operator playbook docs (Phase 9)
- `verify` subcommand (future POLISH-01)
- Reimplementing package lists or install steps outside `./setup`
- Auto-init / auto-fix of git submodules

**Requirements:** WRAP-01, WRAP-02, WRAP-03, WRAP-04

</domain>

<decisions>
## Implementation Decisions

### CLI surface & invocation
- **D-01:** Script path/name is **`arch/dots-hyprland.sh`**. Invocation uses **subcommands that mirror** upstream `./setup`:  
  `arch/dots-hyprland.sh install|install-deps|install-setups|install-files [flags…]`
- **D-02:** Bare invocation (no args) prints **wrapper help** and **exits 0**. Never calls `./setup` with empty args.
- **D-03:** Local help surface: **`help` / `-h` / `--help`** on the wrapper documents safe defaults, backup gate, allowlist, and examples. Subcommand help (e.g. `install -h`) is **passed through** to `./setup`.
- **D-04:** **Allowlist only the WRAP-01 four** subcommands. Refuse `uninstall`, `exp-update`, `exp-merge`, `virtmon`, `checkdeps`, `resetfirstrun`, etc. with a clear error pointing at upstream `./setup` if the operator truly needs them.

### Safe-default flag injection
- **D-05:** Safe defaults apply to **`install` and `install-files` only**. `install-deps` and `install-setups` do **not** get file-protection defaults injected.
- **D-06:** Default profile for those two subcommands: **`--core --skip-hyprland --skip-sysupdate`** (`-s`). Rationale: dual-run / protect personal hypr; skip unattended full `pacman -Syu` (matches `arch/*.sh` habit).
- **D-07:** **Never** auto-inject `-f` / `--force` or `--skip-allgreeting`. Operator must pass them intentionally if ever needed.
- **D-08:** **Never** use `--skip-hyprland-entry` as the protection default. Research: entry-only skip still renames `hyprland.conf`. Protection is **full `--skip-hyprland`**.
- **D-09:** **Passthrough merge, no auto-strip, no required `--raw` escape hatch.** Argv order:  
  `./setup <subcommand> <safe defaults…> <user flags…>`  
  User flags append after defaults (WRAP-04). Duplicates are OK if the user also passed the same long flag.
- **D-10:** Before exec, **log injected defaults and the full argv** with labeled echos (e.g. `[CONFIG] safe defaults: …` then the concrete command).

### Backup gate strictness
- **D-11:** **Hard interactive gate** before **`install` and `install-files`** only. Operator must confirm (e.g. type `yes` / press Enter per implementation) after the reminder. No gate on `install-deps` / `install-setups`.
- **D-12:** If the user passes **`--skip-backup`**, **refuse** unless they also pass an explicit override flag **`--allow-skip-backup`**. Never encourage skip on first adoption; never silently strip the flag.
- **D-13:** Gate messaging must cover: upstream backup location (e.g. `~/ii-original-dots-backup` or current upstream wording), that **Quickshell config will be overwritten**, and that **defaults keep personal `hyprland.conf` via `--skip-hyprland`**.

### Preflight & smoke-test scope
- **D-14:** Preflight before any `./setup` call: **`vendor/dots-hyprland` has `.git` (submodule initialized)** and **`setup` is executable**. Fail with clear `[FAIL]` messages.
- **D-15:** **Never auto-fix** missing submodule/setup. Print fix commands only, e.g. `git submodule update --init --recursive` (stock git; Phase 5 D-15 philosophy).
- **D-16:** Phase 6 smoke tests are **help + dry path only** — no live `install` / `install-deps` / `install-files` that mutate the machine. Cover: wrapper help; unknown subcommand refusal; preflight failure path (if testable); optional `./setup -h` via wrapper; planned argv logging without install.
- **D-17:** **No `verify` subcommand** in Phase 6. Lightweight preflight only; post-install LIVE checks are Phase 7; POLISH-01 stays future.

### Agent's Discretion
- Exact confirm prompt wording / yes-token for the hard gate (as long as D-11–D-13 hold)
- Exact `[LABEL]` vocabulary beyond existing arch conventions (`[INSTALL]`, `[CONFIG]`, `[FAIL]`, `[DONE]`, etc.)
- Whether help text is a here-doc or functions; structured `main()` dispatcher shape (prefer structured generation like `arch/quickshell.sh` / research sketch)
- How to detect TTY if later needed (hard gate is always interactive for Phase 6; non-interactive policy not required unless user later asks)
- Smoke test implementation form (shell assertions in a plan task vs ad-hoc commands in SUMMARY)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Planning (v0.2)
- `.planning/PROJECT.md` — thin `arch/` wrapper around `./setup`; Arch style; dual-run; no package-list reimplementation
- `.planning/REQUIREMENTS.md` — **WRAP-01**, **WRAP-02**, **WRAP-03**, **WRAP-04**
- `.planning/ROADMAP.md` — Phase 6 goal, success criteria, plans 06-01…06-03
- `.planning/STATE.md` — Current position Phase 6
- `.planning/phases/05-fork-submodule-pin/05-CONTEXT.md` — D-13 canonical vendor path; D-15 stock submodule init; D-16 pin-only (install later)

### Research (flag / safety SoT)
- `.planning/research/SUMMARY.md` — architecture summary for adoption
- `.planning/research/STACK.md` — recommended `./setup install --core --skip-hyprland`; never `--skip-backup` first adoption; wrapper sketch
- `.planning/research/ARCHITECTURE.md` — wrapper owns UX; setup owns logic; `--skip-hyprland-entry` insufficient; default flag profile
- `.planning/research/PITFALLS.md` — Pitfall 1 (files overwrite), backup, skip-hyprland guidance

### Repo patterns
- `.planning/codebase/CONVENTIONS.md` — Bash install scripts: `REPO_ROOT`, `[LABEL]` echos, structured generation
- `.planning/codebase/ARCHITECTURE.md` — Provisioning layer; `arch/*.sh` role
- `arch/quickshell.sh` — Structured script template to mirror (functions + `main`, not package reimplementation for this phase)
- `vendor/dots-hyprland/setup` — Upstream CLI entry (`install`, `install-deps`, `install-setups`, `install-files`, …)
- `vendor/dots-hyprland/sdata/subcmd-install/options.sh` — Flag definitions (`--core`, `--skip-hyprland`, `--skip-backup`, `--skip-sysupdate`, …)

No SPEC.md for this phase — requirements fully in REQUIREMENTS.md + decisions above.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `arch/quickshell.sh` / `arch/system_monitor.sh` — structured `REPO_ROOT` + `main()` + labeled echos pattern for the new wrapper
- `vendor/dots-hyprland/setup` — executable SoT for all install steps (already present after Phase 5 pin)
- Existing `arch/*.sh` scripts — style reference only; wrapper must **not** reimplement `sdata` package lists

### Established Patterns
- `REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"` then paths relative to it
- `[INSTALL]` / `[CONFIG]` / `[VERIFY]` / `[DONE]` / `[FAIL]` tagged progress output
- `set -euo pipefail` without relying on reimplemented pacman lists for ii
- Phase 5: **canonical path** is only `vendor/dots-hyprland` (no sibling path)

### Integration Points
- New file: `arch/dots-hyprland.sh` (executable)
- Calls into: `$REPO_ROOT/vendor/dots-hyprland/./setup <subcommand> …`
- Downstream Phase 7 will run this wrapper for real deps/setups/files, then add hypr session hooks
- Phase 8 retires `arch/quickshell.sh`; Phase 6 leaves it alone

</code_context>

<specifics>
## Specific Ideas

- Default safe flag set locked as: **`--core --skip-hyprland --skip-sysupdate`**
- Override for dangerous backup skip: **`--allow-skip-backup`** (wrapper-owned flag; strip before calling setup or do not forward)
- Refuse unknown subcommands rather than silent full passthrough
- Operator education in help text is part of WRAP-03, not only Phase 9 docs

</specifics>

<deferred>
## Deferred Ideas

- Live install + session hooks + dual-run verify — Phase 7
- Retire `.config/quickshell` product tree + `arch/quickshell.sh` — Phase 8
- Full clone/install/update playbook — Phase 9
- Wrapper `verify` subcommand (qs binary, config path, submodule SHA) — POLISH-01
- Allowing `exp-update` / `exp-merge` through the wrapper — out of scope; non-primary update path
- Non-interactive CI mode for hard backup gate — not decided; Phase 6 assumes interactive operator
- Nested shapes LICENSE preflight — declined for Phase 6 (OWN-03 already Phase 5); optional later polish

None beyond phase-boundary deferrals — discussion stayed within Phase 6 scope.

</deferred>

---

*Phase: 6-Thin Setup Wrapper & Safe Defaults*
*Context gathered: 2026-07-25*
