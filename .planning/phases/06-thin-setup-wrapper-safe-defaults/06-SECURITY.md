---
phase: 6
slug: thin-setup-wrapper-safe-defaults
status: verified
threats_open: 0
asvs_level: 1
created: 2026-07-26
---

# Phase 6 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.
> Generated at verify:post after UAT (all 17 checks pass). Register authored at plan time (06-01..03).

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Operator argv → wrapper | Untrusted subcommand/flags; must allowlist and strip wrapper meta | CLI args (no secrets) |
| Wrapper → vendor `./setup` | Privileged install SoT; only array-exec after preflight | Subcommand + flag argv |
| Wrapper → git submodule state | Read-only preflight; must not mutate pin | Path existence / +x checks |
| Operator confirmation → files-touching setup | Human must acknowledge backup/overwrite before install/install-files | yes-token stdin |
| Defaults injection → hypr tree | Full `--skip-hyprland` protects personal conf | Flag injection only |
| Smoke harness → machine state | Phase 6 must not mutate packages or XDG configs | Dry-run / help only |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-06-01 | Elevation of Privilege | subcommand dispatch / allowlist | high | mitigate | Allowlist only `install\|install-deps\|install-setups\|install-files` (D-04); refuse uninstall/exp-*; UAT tests 3, 17 | closed |
| T-06-02 | Tampering / data loss | `--skip-backup` path | high | mitigate | Refuse bare `--skip-backup` unless `--allow-skip-backup`; never default skip-backup; strip meta before setup; UAT 12–13 | closed |
| T-06-03 | Tampering | hypr conf install | high | mitigate | Default inject full `--skip-hyprland` (not entry-only) plus `--core --skip-sysupdate` on install/install-files only; UAT 6–9 | closed |
| T-06-04 | Tampering | flag/argv handling / exec | high | mitigate | Bash array `cmd=(./setup …)` + `"${cmd[@]}"`; no shell-eval of concatenated commands; strip `--dry-run` / `--allow-skip-backup`; UAT 14, static review | closed |
| T-06-05 | Tampering | preflight / git | medium | mitigate | Require `.git` + setup `+x`; stock git fix only; never auto submodule init (D-15); UAT 16 | closed |
| T-06-06 | Information Disclosure | gate/logs | low | mitigate | Gate/log text is operational paths and flags only; no secrets; no `set -x` | closed |
| T-06-SC | Tampering | package installs | low | accept | No package-manager installs in Phase 6 (Package Legitimacy N/A) | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on (`high`) count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-06-SC | T-06-SC | Phase 6 is dry-run/help only; no npm/pip/cargo/pacman installs in the wrapper. Live package install is Phase 7 via upstream `./setup`. | plan threat model (accept) + verify-post audit | 2026-07-26 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-07-26 | 7 | 7 | 0 | verify-work post-hook (orchestrator L1 ASVS) |

### Evidence (L1)

- `arch/dots-hyprland.sh`: allowlist, preflight, backup_gate, dual-key skip-backup, SAFE_DEFAULTS, array-exec path present; no live `eval` of command strings (comment-only mention of eval).
- UAT 06-UAT.md: 17/17 pass including refuse bare skip-backup, dual-key, defaults injection scope, preflight fail-closed with +x restore, gate abort on `no`.
- 06-VERIFICATION.md: status passed; WRAP-01..04 green; no live install mutation in Phase 6.

### Short-circuit

`threats_open: 0` AND `register_authored_at_plan_time: true` AND `asvs_level: 1` → L1 grep/runtime evidence sufficient; deep auditor not required.

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-07-26
