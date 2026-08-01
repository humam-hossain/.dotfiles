---
phase: 5
slug: fork-submodule-pin
status: verified
threats_open: 0
asvs_level: 1
created: 2026-07-25
verified: 2026-07-25
register_authored_at_plan_time: true
---

# Phase 5 — Security

> Pin-only phase: fork ownership + submodule registration. No install, no package managers, no session hooks.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Operator shell → GitHub API (`gh`) | Authenticated fork create/view | Auth token in keyring only |
| Operator shell → GitHub SSH | Submodule fetch / future origin | SSH keys; not logged |
| Parent repo → `.gitmodules` URL | Superproject trusts vendor source | Fork SSH URL only |
| Submodule tree → nested shapes URL | Nested dependency host | end-4/rounded-polygon-qmljs HTTPS |
| Local sibling path | Untrusted as seed | Must not convert or mv |
| Submodule working tree → machine | setup must not run (D-16) | Install scripts present but unexecuted |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-05-01 | Spoofing | Fork target / `.gitmodules` URL | high | mitigate | Outer URL only `git@github.com:humam-hossain/dots-hyprland.git`; never submodule-add end-4 as origin | closed |
| T-05-02 | Information Disclosure | gh auth / logs / commit msgs | medium | mitigate | No `set -x` around auth; no tokens in files/SUMMARY; secrets grep clean | closed |
| T-05-03 | Elevation of Privilege | `vendor/dots-hyprland/setup` | high | mitigate | D-16: setup not executed; no `arch/dots-hyprland.sh` created | closed |
| T-05-04 | Tampering | Sibling conversion | high | mitigate | D-02/D-14: sibling path left intact; fresh submodule add only | closed |
| T-05-05 | Tampering | Nested shapes host | high | mitigate | Nested URL still `end-4/rounded-polygon-qmljs`; LICENSE present | closed |
| T-05-06 | Tampering | Auto-track branch / half-pin | medium | mitigate | No `branch =` in `.gitmodules`; D-11 same commit for gitmodules+gitlink | closed |
| T-05-SC | Tampering | npm/pip/cargo installs | low | accept | No package installs this phase | closed |

*Status: open · closed · open — below high threshold (non-blocking)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-05-SC | T-05-SC | Phase is pin-only; package installs deferred to Phase 6+ wrapper | plan disposition accept | 2026-07-25 |

---

## Evidence (mitigations present)

```
.gitmodules url = git@github.com:humam-hossain/dots-hyprland.git
no branch auto-track line
git ls-tree HEAD vendor/dots-hyprland → 160000 commit 1a9ffb78…
origin (vendor) = git@github.com:humam-hossain/dots-hyprland.git
upstream (vendor) = https://github.com/end-4/dots-hyprland.git
nested shapes url = https://github.com/end-4/rounded-polygon-qmljs.git
shapes LICENSE present
sibling ~/github_repo/dots-hyprland exists
arch/dots-hyprland.sh absent
no secrets in .gitmodules
```

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-07-25 | 7 | 7 | 0 | orchestrator-inline (ASVS L1) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-07-25
