---
phase: 12
slug: wrapper-full-profile
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
created: 2026-08-17
---

# Phase 12 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.
> Register authored at plan time (`<threat_model>` in 12-01..04 PLAN.md). ASVS L1 grep-depth.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Operator shell → wrapper | Untrusted argv (`--full`, `--skip-backup`, `--allow-skip-backup`, `--dry-run`) enters `run_install_family` | CLI flags / subcommand |
| Interactive TTY → gate | Exact `yes` token required before files-touching / dry-run would-exec | Confirmation token |
| Wrapper → `./setup` | Only stripped, allowlisted subcommands + built `cmd` array; meta never forwarded | argv array |
| Dry-run post-setup plan → operator trust | Dry-run must still plan protect re-mark + ii hooks (D-16) | Planned post-setup actions |
| Smoke harness → host | Harness must not mutate packages, hypr, or run live `install --full` | stdout greps only |
| Operator → help text | Docs influence whether full is discovered vs raw vendor setup | usage() copy |
| Help pointers → planning artifacts | Paths are advisory; must not become runtime coupling (D-10) | file path strings |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-12-01 | Elevation of privilege | Accidental full default / SAFE_DEFAULTS | critical | mitigate | `needs_safe_defaults && full==0` still injects triple; help states default injects without `--full`; smoke FULL-02 | closed |
| T-12-02 | Tampering | `--full` / allow-skip meta forwarded to setup | high | mitigate | `--full)` and `--allow-skip-backup` stripped in `run_install_family`; smoke FULL-01 / FULL-03b would-exec absence | closed |
| T-12-03 | Tampering | Bare `--skip-backup` on full | high | mitigate | Pre-gate refuse without `--allow-skip-backup` (`D-12`); smoke FULL-03 | closed |
| T-12-04 | Tampering | Dry-run mutates host | high | mitigate | `if ((dry_run)); then … exit 0` before `"${cmd[@]}"`; protect/hooks called with `dry_run=1` | closed |
| T-12-05 | Injection | cmd construction | high | mitigate | `local -a cmd=(./setup "$subcmd")` then `"${cmd[@]}"` — no `eval` | closed |
| T-12-06 | Elevation of privilege | Full gate messaging | high | mitigate | `backup_gate "$full"` D-07 blast-radius themes; no safe-path “conf protected” claim on full | closed |
| T-12-07 | Tampering | Skip gate on `--full --dry-run` | medium | mitigate | D-08: gate still runs before would-exec; non-yes aborts non-zero | closed |
| T-12-08 | Spoofing | Stronger phrase / two-step confusion | low | mitigate | D-06: same type-yes token only (`Type 'yes' to continue`) | closed |
| T-12-09 | Spoofing / misuse | usage() full path | medium | mitigate | `--full` documented as primary; vendor-outside note removed (D-04); smoke FULL-01 / D-04 | closed |
| T-12-10 | Information disclosure | INV/DISP paths in help | low | accept | Repo-local planning paths; intentional discoverability (D-13) | closed |
| T-12-11 | Elevation of privilege | Accidental process gate | high | mitigate | Pointers only in `usage()`; no filesystem existence gate in `run_install_family` | closed |
| T-12-12 | Tampering | Skip protect on full | critical | mitigate | Dry-run + real post-setup still call `protect_explicit_packages` with no `full==0` skip; smoke FULL-05 | closed |
| T-12-13 | Tampering | Skip ii hooks on full | high | mitigate | `enable_hypr_ii_hooks` still planned/run when `full==1`; smoke FULL-05 | closed |
| T-12-14 | Tampering | Smoke harness live install | high | mitigate | `scripts/phase12-full-smoke.sh` header + every `install --full` invocation includes `--dry-run` | closed |
| T-12-SC | Tampering | package installs in phase / harness | low | accept | No npm/pip/cargo/pacman install in this phase; harness only greps wrapper output | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on (`high`) count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-12-10 | T-12-10 | Help prints repo-local `10-INVENTORY.md` / `11-DISPOSITIONS.md` paths for discoverability (D-13). Not a runtime secret; no process gate. | plan 12-03 threat model | 2026-08-11 |
| AR-12-SC | T-12-SC | Phase does not install packages. Smoke harness is help / dry-run / refuse / syntax only. | plan 12-01..04 threat models | 2026-08-17 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-08-17 | 15 | 15 | 0 | gsd-verify-work / secure-phase (ASVS L1) |

L1 evidence (this run):
- `./scripts/phase12-full-smoke.sh` exit 0 (FULL-01..05 + D-02/D-04/D-13)
- `arch/dots-hyprland.sh`: meta strip (`--full)` / `--allow-skip-backup`), `full==0` SAFE_DEFAULTS inject, dry-run `exit 0` before `"${cmd[@]}"`, array exec, pre-gate skip-backup refuse, unbranched protect + ii hooks
- `usage()` lists `--full` and INV/DISP pointers; no vendor-outside full note
- Harness: every `install --full` includes `--dry-run`; no pacman/yay install

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-08-17
