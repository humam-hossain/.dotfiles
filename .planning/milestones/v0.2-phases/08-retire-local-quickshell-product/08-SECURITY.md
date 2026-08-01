---
phase: 8
slug: retire-local-quickshell-product
status: verified
threats_open: 0
asvs_level: 1
created: 2026-07-28
---

# Phase 8 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.
> Closed by execute-phase verify:post → secure-phase (ASVS L1, 2026-07-28).

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Operator/executor shell → live XDG QS tree | Health checks read host; reinstall (if taken) may overwrite live QS files | Host paths under `~/.config/quickshell` |
| REPO_ROOT `.config/quickshell` vs `$HOME/.config/quickshell` | Same relative name; delete must never cross into home | Path identity (repo vs home) |
| git index → working tree | Large staged deletion; untracked remnants need REPO-only cleanup | Git index + worktree under REPO |
| Installer path presence → operator muscle memory | File must be gone so it cannot re-symlink live into missing repo tree | `arch/quickshell.sh` existence |
| Wrapper comment/docs text → operator procedure | Only clean re-teaching refs; do not break wrapper behavior | Comment text / grep hits |
| Wrapper yes-token → vendor `./setup` (reinstall branch only) | Human must acknowledge backup before rsync | Backup gate token |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-8-01 | Tampering / DoS | Live `~/.config/quickshell` deleted as "retirement" | high | mitigate | REPO-scoped `git rm` only; post-assert live `ii/shell.qml`; D-14 | closed |
| T-8-02 | Tampering | Retired installer re-run / left callable | high | mitigate | Never execute; `git rm` hard delete `81ac1e0`; `test ! -e`; zero product-path greps | closed |
| T-8-03 | Tampering | Symlink regression (live → repo) | high | mitigate | Hard `test ! -L` + readlink-not-under-repo before/after; forbid re-symlink | closed |
| T-8-04 | Tampering | Rewriting historical tests hides RET failures | medium | accept | D-03/D-11 leave phase07/phase04 frozen; document expected D-04 red | closed |
| T-8-05 | Tampering / info loss | Reinstall without backup / bare skip-backup | high | mitigate | Reinstall only if health fails; dry-run + interactive gate; never bare skip-backup — **branch not taken** (health green) | closed |
| T-08-SC | Tampering | npm/pip/cargo installs | low | accept | No registry package installs this phase (D-05) | closed |

*Status: open · closed · open — below high threshold (non-blocking)*  
*register_authored_at_plan_time: true* (all three PLAN.md files contain `<threat_model>`)  
*ASVS L1: grep/assert depth sufficient when threats_open: 0*

---

## Evidence (L1)

| Threat | Evidence |
|--------|----------|
| T-8-01 | `test ! -e REPO/.config/quickshell`; `test -f $HOME/.config/quickshell/ii/shell.qml`; commit `fb91789` (933 deletions, REPO only) |
| T-8-02 | `test ! -e arch/quickshell.sh`; commit `81ac1e0`; `git grep arch/quickshell.sh -- arch scripts .config` → empty; never executed in phase |
| T-8-03 | `test ! -L $HOME/.config/quickshell`; `readlink -f` → `/home/pera/.config/quickshell` (not under `.dotfiles`) |
| T-8-04 | `git log` phase range does not modify `scripts/phase07-live-smoke.sh` or `phase04-*`; SUMMARYs document expected D-04 red |
| T-8-05 | 08-01-SUMMARY: `[SKIP] live health green — no reinstall`; no `--skip-backup` invocation |
| T-08-SC | No package manager installs in phase commits |

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-8-01 | T-8-04 | Historical phase07/phase04 scripts intentionally left broken on D-04 after RET-01 so retirement failures stay visible; not rewritten to green | plan D-03/D-11 + operator phase intent | 2026-07-28 |
| AR-8-02 | T-08-SC | No new registry installs in Phase 8; residual supply-chain risk is out of phase scope | plan D-05 | 2026-07-28 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-07-28 | 6 | 6 | 0 | orchestrator-inline (secure-phase L1; ASVS 1; register from PLAN threat models) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-07-28
