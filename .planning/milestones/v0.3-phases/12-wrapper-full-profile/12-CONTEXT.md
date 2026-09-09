# Phase 12: Wrapper full-profile - Context

**Gathered:** 2026-08-10
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver an **explicit opt-in full-install path** in `arch/dots-hyprland.sh` so the operator can dry-run and invoke full install (no accidental SAFE_DEFAULTS injection) without making full the default.

**In scope (FULL-01..05):**
- Documented opt-in full path that does **not** inject `--skip-hyprland` and drops the other SAFE_DEFAULTS residuals per Phase 11 D-05 (all three: no `--core`, no `--skip-hyprland`, no `--skip-sysupdate`)
- Default `install` / `install-files` **still** inject SAFE_DEFAULTS (FULL-02)
- Full path keeps backup gate and refuses bare `--skip-backup` without `--allow-skip-backup` (FULL-03)
- `--dry-run` on full path shows argv **without** unwanted SAFE_DEFAULTS injection (FULL-04)
- After full install/install-files (and install-deps on the unified `install` pipeline), PROTECT_EXPLICIT re-mark still runs (FULL-05)

**Out of scope this phase:**
- Live full install / session mutation — Phase 14
- Pre-flight live→repo sync gate — Phase 14 (D-07)
- Writing `hypr/custom` overlays — Phase 13
- Playbook safe-vs-full polish — Phase 15 (minimal help pointers only)
- Changing default SAFE_DEFAULTS on non-full paths
- Hard-enforcing INV/DISP artifact presence in the wrapper (ADOPT-01 stays Phase 14)
- Chrome teardown / dual-run stop — Phase 14 (D-11/D-14)
- Expanding PROTECT_EXPLICIT package list beyond current safe-path list
- Raw vendor `./setup` as the primary full path (wrapper `--full` becomes primary)

**Requirements:** FULL-01, FULL-02, FULL-03, FULL-04, FULL-05

</domain>

<decisions>
## Implementation Decisions

### Opt-in CLI shape
- **D-01:** Opt-in is a **wrapper-owned meta-flag `--full`** on existing subcommands — **not** a new `install-full` subcommand. Pattern matches `--dry-run` / `--allow-skip-backup` (strip before forwarding to `./setup`). — **Reversibility:** costly — help, tests, and Phase 14/15 docs will cite `--full`
- **D-02:** `--full` is accepted only on **`install` and `install-files`** — the same subcommands where SAFE_DEFAULTS are injected today (`needs_safe_defaults`). Not on bare `install-deps` / `install-setups` as a standalone full profile. — **Reversibility:** reversible
- **D-03:** When `--full` is active, **inject nothing from SAFE_DEFAULTS** — do not prepend `--core`, `--skip-hyprland`, or `--skip-sysupdate`. Operator may still pass extra upstream flags; wrapper does not re-add residual safe flags. Encodes Phase 11 D-05. — **Reversibility:** costly — first full-adopt argv contract for Phases 14–15
- **D-04:** **Rewrite `usage()` / help:** remove the note that full hypr requires calling vendor `./setup` outside this wrapper. Document wrapper `--full` as the primary full path. — **Reversibility:** reversible
- **D-05:** Default `install` / `install-files` **without** `--full` continue to inject `SAFE_DEFAULTS=(--core --skip-hyprland --skip-sysupdate)` unchanged (FULL-02 / Phase 11 D-10). — **Reversibility:** one-way if violated — accidental full default is milestone anti-goal

### Full-path confirmation gate
- **D-06:** Full path uses the **same type-yes interactive backup gate** pattern as safe install — not a stronger phrase (e.g. type `FULL`) and not a two-step gate. Messaging is full-specific. — **Reversibility:** reversible
- **D-07:** Full-path gate messaging **must** cover: no SAFE_DEFAULTS residual flags on this path; hypr conf may become `.old`; misc may overwrite when `--core` is absent; sysupdate/`pacman -Syu` may run on deps path; upstream backup dir (`~/ii-original-dots-backup`); still refuse bare `--skip-backup`. — **Reversibility:** reversible
- **D-08:** **`--dry-run` with `--full` still hits the interactive gate**, then prints would-exec argv (same order as safe `install --dry-run` today). FULL-04 is about argv content, not skipping intentionality. — **Reversibility:** reversible
- **D-09:** Bare `--skip-backup` on full path is **still refused** without `--allow-skip-backup` (FULL-03). Do **not** invent a “never allow skip on full” harder rule. — **Reversibility:** reversible

### Process gate in wrapper
- **D-10:** Phase 12 is **pure capability** — wrapper does **not** check for presence or “Complete” status of `10-INVENTORY.md` / `11-DISPOSITIONS.md`. No hard refuse, no soft warn based on planning artifacts. — **Reversibility:** costly if later hard-coded into wrapper — couples `arch/` to `.planning/` layout
- **D-11:** **ADOPT-01 process gate** (INV+DISP satisfied before live full install) remains **Phase 14 / operator discipline**, not wrapper enforcement. — **Reversibility:** costly — Phase 14 plans must enforce the process gate
- **D-12:** **No runtime policy engine** in Phase 12 — no host scan for dual-run chrome still in `exec-once`, no re-interpretation of dispositions, no “SAFE_DEFAULTS would be safer” refusal. Gate messaging is the warning. — **Reversibility:** reversible
- **D-13:** `usage()` / help **points** at playbook (`docs/dots-hyprland-workflow.md`) and INV/DISP phase artifact paths so operators know the intended sequence. Full sequence polish is Phase 15; Phase 12 only needs discoverable pointers. — **Reversibility:** reversible

### Post-install hooks under full
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

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Planning / requirements
- `.planning/PROJECT.md` — v0.3 full ii install; inventory→disposition→adopt; SAFE_DEFAULTS remain default until opt-in
- `.planning/REQUIREMENTS.md` — **FULL-01**, **FULL-02**, **FULL-03**, **FULL-04**, **FULL-05** (and DISP/ADOPT/OVL for boundary only)
- `.planning/ROADMAP.md` — Phase 12 goal + success criteria; phases 13–15 dependencies
- `.planning/STATE.md` — current position (Phase 12)

### Prior phase decisions (do not re-open)
- `.planning/phases/11-disposition-decisions/11-CONTEXT.md` — D-05 full drops all three residuals; D-10 SAFE_DEFAULTS default unchanged; D-11 chrome accept-remove (Phase 14)
- `.planning/phases/11-disposition-decisions/11-DISPOSITIONS.md` — **SoT for first full-adopt flag profile** (DISP-02); process gate content for Phase 14
- `.planning/phases/10-full-install-impact-inventory/10-CONTEXT.md` — D-09 flag independence; D-08 dry-run full-profile proof belongs to Phase 12
- `.planning/phases/10-full-install-impact-inventory/10-INVENTORY.md` — blast-radius evidence for full-path gate messaging
- `.planning/milestones/v0.2-phases/06-thin-setup-wrapper-safe-defaults/06-CONTEXT.md` — SAFE_DEFAULTS, backup gate, meta flags, thin wrapper, dry-run
- `.planning/milestones/v0.2-phases/07-install-session-hooks-dual-run-verify/07-CONTEXT.md` — live dual-run + personal hypr hooks

### Install / wrapper SoT
- `arch/dots-hyprland.sh` — SAFE_DEFAULTS injection, `needs_safe_defaults`, backup gate, `--dry-run`, `--allow-skip-backup`, PROTECT re-mark, `enable_hypr_ii_hooks`
- `vendor/dots-hyprland/setup` — upstream install entry
- `vendor/dots-hyprland/sdata/subcmd-install/options.sh` — `--core`, `--skip-hyprland`, `--skip-sysupdate`, backup flags
- `docs/dots-hyprland-workflow.md` — current safe dual-run operator path (Phase 12 help points here; Phase 15 updates for full)

### Codebase maps (orientation)
- `.planning/codebase/ARCHITECTURE.md` — provisioning vs config layers; thin wrapper pattern
- `.planning/codebase/INTEGRATIONS.md` — hypr session / dual-run context (chrome stop is Phase 14)
- `.planning/codebase/STACK.md` — Arch provisioning stack

No SPEC.md for this phase — requirements fully in REQUIREMENTS.md + decisions above.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `arch/dots-hyprland.sh` — primary edit target; SAFE_DEFAULTS, meta-flag strip loop in `run_install_family`, `backup_gate`, dry-run print, post-setup protect + hooks
- `needs_safe_defaults` — currently true for `install|install-files`; full path should share that subcommand scope and branch injection off when `--full`
- `PROTECT_EXPLICIT` + `protect_explicit_packages` — reuse unchanged for FULL-05
- `enable_hypr_ii_hooks` — reuse unchanged on full path (D-15)
- Phase 6 patterns: array exec only, no `eval`; wrapper-owned flags stripped; interactive gate before dry-run/exec

### Established Patterns
- Thin wrapper around upstream `./setup`; never reimplement package lists in `arch/`
- Wrapper-owned meta flags (`--dry-run`, `--allow-skip-backup`) stripped; never forwarded
- SAFE_DEFAULTS prepended only for files-touching install paths unless full opts out
- `[LABEL]` echos; help documents defaults and gates
- Smoke tests: help + dry-run only — no live mutating full install in Phase 12

### Integration Points
- Default path: `./arch/dots-hyprland.sh install` → still SAFE_DEFAULTS
- Full path: `./arch/dots-hyprland.sh install --full` / `install-files --full` → no SAFE_DEFAULTS injection
- Phase 13 overlays prep before live full that needs must-keeps (parallel-capable with 12)
- Phase 14 consumes full path + dispositions + pre-flight for live adopt
- Phase 15 documents safe vs full using this CLI contract

</code_context>

<specifics>
## Specific Ideas

- Operator chose **recommended** options across all four gray areas — prefer thin, familiar wrapper UX over new subcommands or hard process coupling.
- Full profile = **drop all three** residuals (already locked Phase 11 D-05); Phase 12 only encodes that as `--full`.
- Intentionality comes from **`--full` flag + type-yes gate**, not from planning-doc file checks in bash.
- Dry-run must remain a trustworthy argv proof **after** the gate (scriptable with `printf 'yes\n'` as today).

</specifics>

<deferred>
## Deferred Ideas

- Phase 13: `hypr/custom` overlays for monitors/workspaces/env must-keeps (D-16 from Phase 11)
- Phase 14: pre-flight live→repo sync (D-07), live full adopt, ADOPT-01 process gate enforcement, chrome accept-remove timing (D-11/D-14), possible revisit of hook targets after lua entry is primary
- Phase 15: playbook safe vs full profile documentation polish
- Expanding PROTECT_EXPLICIT for full-only packages — rejected for Phase 12; reopen only if FULL-05 proof shows a gap
- Harder full-only never-`--skip-backup` — rejected; keep shared `--allow-skip-backup` override
- New `install-full` subcommand — rejected in favor of `--full` flag

None of the above expand Phase 12 scope beyond wrapper full-profile capability.

</deferred>

---

*Phase: 12-Wrapper full-profile*
*Context gathered: 2026-08-10*
*Interactive discuss: decisions from user selection across four gray areas*
