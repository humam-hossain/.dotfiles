---
phase: 9
slug: workflow-documentation-update-contract
status: verified
threats_open: 0
asvs_level: 1
created: 2026-08-01
---

# Phase 9 — Security

> Per-phase security contract: threat register from plans, audit trail.
> Closed by execute-phase verify:post → secure-phase (ASVS L1, 2026-08-01).

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Playbook text → operator shell | Operators copy-paste commands; wrong steps risk personal dots | Markdown → bash |
| Playbook → live XDG + hypr | Install narrative drives setup and session hooks | Documented paths only |
| Playbook → git submodule pin | Clone/init/update must preserve recursive pin integrity | git commands |
| README discovery → playbook | Missing link reintroduces tribal knowledge | Markdown links |
| Stale installer mentions → operator | Re-teaching deleted installer undoes RET-02 | Product-facing greps |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-9-01 | Tampering | Submodule init docs omit recursive | high | mitigate | Require recurse-submodules / --recursive; acceptance greps | closed |
| T-9-02 | Tampering | Retired installer narrative | high | mitigate | Forbid instructional arch/quickshell.sh; retired framing only | closed |
| T-9-03 | Tampering / info loss | Backup gate docs / bare skip-backup | high | mitigate | Document type-yes gate; never recommend bare --skip-backup first adoption | closed |
| T-9-04 | DoS / Tampering | Hypr protection docs | high | mitigate | Document full --skip-hyprland safe defaults; dual-run keeps waybar | closed |
| T-9-05 | Tampering | Update contract (exp-merge as primary) | high | mitigate | Pin-bump primary; exp-merge + online cache explicitly non-primary | closed |
| T-9-06 | Info disclosure / Tampering | Discovery & stale refs | medium | mitigate | README + PROJECT reference playbook; neg-grep product paths | closed |
| T-9-SC | Tampering | Package installs via docs phase | low | accept | Docs only; no npm/pip/cargo | closed |

---

## Audit Evidence

- Full DOC suite: FAIL_COUNT=0 (2026-08-01)
- `test ! -e arch/quickshell.sh`
- Product-facing greps: only retired framing for quickshell.sh
- No live machine install mutated solely for doc tasks
- No `scripts/phase09-*-smoke.sh` created

## Verdict

**SECURED** — threats_open: 0
