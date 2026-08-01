---
phase: 7
slug: install-session-hooks-dual-run-verify
status: verified
threats_open: 0
asvs_level: 1
created: 2026-07-27
---

# Phase 7 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Operator shell → live XDG config | Unlink / install mutates host session state | Host paths under `~/.config` |
| Live `~/.config/quickshell` → repo product | Symlink edge must not become delete-into-git | Path type (symlink vs real dir) |
| Operator yes-token → setup files install | Human acknowledges backup/overwrite before rsync | Backup gate token |
| Wrapper argv → vendor `./setup` | Only allowlisted subcommands + injected safe defaults | CLI argv |
| Repo hypr SoT → live `~/.config/hypr` | Single-file copy must not wipe unrelated live-only hypr files | `hyprland.conf` contents |
| Hyprland conf → session processes | exec-once / env affect autostart and child environ | Process env + autostart |
| Operator visual confirm → LIVE-04 sign-off | Human is sole authority for on-screen chrome | Visual chrome approval |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-7-01 | Tampering | `~/.config/quickshell` symlink → rsync into git | high | mitigate | D-01 plain unlink only; LIVE-01 re-assert `! -L`, real dir + `ii/shell.qml` not under `.dotfiles`; never run `arch/quickshell.sh` | closed |
| T-7-02 | Tampering | accidental hypr conf rename / ii takeover | high | mitigate | Wrapper injects `--skip-hyprland`; soft-assert no `.old`; D-09 personal SoT; additive inline hooks only (no ii hyprland.lua) | closed |
| T-7-03 | Tampering / data loss | accidental `--skip-backup` | high | mitigate | D-02: no skip-backup on first adoption; operator `yes` at gate; `~/ii-original-dots-backup` present | closed |
| T-7-04 | Elevation of Privilege | unexpected setup subcommand | high | mitigate | Wrapper allowlist only (`install` path); Phase 6 refuses uninstall/exp-*; no raw `./setup` for first adoption | closed |
| T-7-05 | Tampering | command injection via flags | medium | accept | Residual mitigated by Phase 6 array exec; 07-03 uses fixed literal shell commands only | closed |
| T-7-06 | Tampering | re-run `arch/quickshell.sh` re-symlink | high | mitigate | Explicit forbid in all plans; not executed; live path remains real directory | closed |
| T-07-SC | Tampering | npm/pip/cargo installs | low | accept | No planner-introduced registry packages; AUR via upstream setup only | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on (`high`) count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

**Evidence (L1 re-check 2026-07-27, post-UAT):**

- `test ! -L ~/.config/quickshell` and `-d` + `ii/shell.qml` → `/home/pera/.config/quickshell` (not under `.dotfiles`)
- `~/.local/state/quickshell/.venv` present
- `~/.config/hypr/hyprland.conf` present; no `hyprland.conf.old`
- Repo+live `hyprland.conf` `cmp -s`; `env = ILLOGICAL_IMPULSE_VIRTUAL_ENV,...` and `exec-once = qs -c ii`; waybar line preserved
- `qs -c ii -d` running with `ILLOGICAL_IMPULSE_VIRTUAL_ENV` in `/proc` environ; waybar running
- `~/ii-original-dots-backup` present (backup gate honored)
- Plans/SUMMARYs: no `arch/quickshell.sh` execution; wrapper-only install

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-7-01 | T-7-05 | Flag injection residual owned by Phase 6 array-exec wrapper; Phase 7 does not re-open wrapper parsing | plan disposition (07-02/07-03) | 2026-07-27 |
| AR-7-02 | T-07-SC | No planner-introduced npm/pip/cargo; AUR packages only via upstream setup interactive path | plan disposition (all plans) | 2026-07-27 |
| AR-7-03 | T-7-05 (07-03) | Fixed-literal shell commands only in session-hook plan; no new flag parsing | plan disposition (07-03) | 2026-07-27 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-07-27 | 7 | 7 | 0 | verify-work post-hook (L1; register_authored_at_plan_time) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-07-27
