---
phase: 13
slug: personal-hypr-custom-overlays
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
created: 2026-08-31
---

# Phase 13 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.
> Register authored at plan time (`<threat_model>` in 13-01 and 13-02 PLAN.md). ASVS L1 grep-depth.
> gsd-security-auditor subagent 429'd this session; orchestrator re-ran L1 checks on disk (not SUMMARY/STATE markers).

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Worktree `.config/hypr/custom/` → live `~/.config/hypr/custom/` | Documented apply would copy Lua into the session tree; this phase must not cross it (D-17) | overlay Lua files |
| Parent repo → `vendor/dots-hyprland` / personal fork | Machine overlays must not enter product SoT (D-04) | custom/*.lua |
| Operator paste of apply command | A destructive apply (`rsync --delete`, missing general.lua) could wipe or skip layout | bash fence in 13-SOT-APPLY.md |
| `hyprland.lua` require → `custom/*.lua` | Overlay Lua runs in the compositor session after adopt | require("custom.*") |

ASVS L1; block on high.

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-live-mutation | Tampering | live `$HOME/.config` | high | mitigate | D-17: apply not run; `test ! -e "$HOME/.config/hypr/custom"`; worktree realpath ≠ live custom | closed |
| T-vendor-pollution | Tampering | vendor/dots-hyprland custom/ | high | mitigate | D-04: `git -C vendor/dots-hyprland status --short -- dots/.config/hypr/custom` empty | closed |
| T-rsync-delete | Denial of service | apply command in 13-SOT-APPLY.md | high | mitigate | D-18: `cp -a` named files only; Never `rsync --delete`; never copy keybinds/rules/variables | closed |
| T-apply-missing-general.lua | Denial of service | cold-machine apply | high | mitigate | D-18: abort if repo `general.lua` missing; warn-and-continue only for env.lua/execs.lua; `test -s` general.lua | closed |
| T-D17-leakage | Tampering | `custom/*.lua` autostart/apps | high | mitigate | D-19 negative greps: chrome/vesktop/discord/waybar/swaync/`qs -c ii`; dropped D-08/D-09 tokens (XCURSOR_/setcursor/ILLOGICAL_IMPULSE_VIRTUAL_ENV) | closed |
| T-13-SC | Tampering | npm/pip/cargo installs | low | accept | No package installs this phase; overlay commits are lua + SoT note only | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on (`high`) count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-13-SC | T-13-SC | Phase does not install packages. Production commits are overlay Lua + 13-SOT-APPLY.md. | plan 13-01/13-02 threat models | 2026-08-31 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-08-31 | 6 | 6 | 0 | gsd-verify-work / secure-phase inline (ASVS L1; auditor 429) |

L1 evidence (this run, re-executed — not copied from VERIFICATION.md):
- live `$HOME/.config/hypr/custom` absent
- `git -C vendor/dots-hyprland status --short -- dots/.config/hypr/custom` empty
- `13-SOT-APPLY.md` names `cp -a`, abort if general.lua missing, WARN continue for slots, Never `rsync --delete`
- D-19 fence extracted and `bash -e` exit 0 (includes negative greps)
- `./scripts/phase13-d19-assert.sh` FAIL=0
- overlay commits `4550b87..563c11c` have no package-lock / Cargo.lock / pyproject / requirements.txt / package.json

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-08-31
