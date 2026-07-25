---
phase: 6
slug: thin-setup-wrapper-safe-defaults
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-25
---

# Phase 6 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Seeded from `06-RESEARCH.md` ## Validation Architecture. Plans must embed
> matching `<verify><automated>` commands. Wrapper **`--dry-run`** is required
> so asserts never mutate the machine (D-16).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None — inline shell / smoke asserts (same as Phase 5) |
| **Config file** | none |
| **Quick run command** | `bash -n arch/dots-hyprland.sh && ./arch/dots-hyprland.sh -h >/dev/null` |
| **Full suite command** | WRAP-01..04 dry/help assert block (per-task map below) |
| **Estimated runtime** | ~10 seconds |

---

## Sampling Rate

- **After every task commit:** Run `bash -n arch/dots-hyprland.sh` + the task’s automated verify
- **After every plan wave:** Full WRAP-01..04 dry/help block
- **Before `/gsd:verify-work`:** Full suite must be green; confirm no live `./setup install*` mutation
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|----------------|-----------------|-----------|-------------------|-------------|--------|
| 06-01-T1 | 01 | 1 | WRAP-01 | T-06-01 | Allowlist + exec only | smoke | `test -x arch/dots-hyprland.sh && bash -n arch/dots-hyprland.sh` | ❌ W0 | ⬜ pending |
| 06-01-T2 | 01 | 1 | WRAP-01 | T-06-01 | Bare help exit 0 | smoke | `./arch/dots-hyprland.sh >/tmp/w6-help.txt; test $? -eq 0; grep -E 'install-deps\|install-setups\|install-files' /tmp/w6-help.txt` | ❌ W0 | ⬜ pending |
| 06-01-T3 | 01 | 1 | WRAP-01 | T-06-01 | Refuse uninstall | smoke | `./arch/dots-hyprland.sh uninstall; test $? -ne 0` | ❌ W0 | ⬜ pending |
| 06-02-T1 | 02 | 2 | WRAP-02 | T-06-03 | Defaults --core/--skip-hyprland | smoke | `printf 'yes\n' \| ./arch/dots-hyprland.sh install --dry-run \| grep -q -- '--core' && printf 'yes\n' \| ./arch/dots-hyprland.sh install --dry-run \| grep -q -- '--skip-hyprland'` | ❌ W0 | ⬜ pending |
| 06-02-T2 | 02 | 2 | WRAP-02 | T-06-03 | Defaults --skip-sysupdate | smoke | `printf 'yes\n' \| ./arch/dots-hyprland.sh install --dry-run \| grep -q -- '--skip-sysupdate'` | ❌ W0 | ⬜ pending |
| 06-02-T3 | 02 | 2 | WRAP-02 | T-06-03 | No defaults on install-deps | smoke | `out=$(./arch/dots-hyprland.sh install-deps --dry-run); echo "$out" \| grep -q setup; ! echo "$out" \| grep -q -- '--skip-hyprland'` | ❌ W0 | ⬜ pending |
| 06-02-T4 | 02 | 2 | WRAP-03 | T-06-02 | Gate messaging | smoke | `printf 'yes\n' \| ./arch/dots-hyprland.sh install --dry-run 2>&1 \| tee /tmp/w6-gate.txt; grep -q 'ii-original-dots-backup' /tmp/w6-gate.txt; grep -qi 'quickshell' /tmp/w6-gate.txt; grep -q 'skip-hyprland' /tmp/w6-gate.txt` | ❌ W0 | ⬜ pending |
| 06-02-T5 | 02 | 2 | WRAP-03 | T-06-02 | Refuse bare --skip-backup | smoke | `./arch/dots-hyprland.sh install --skip-backup --dry-run; test $? -ne 0` | ❌ W0 | ⬜ pending |
| 06-02-T6 | 02 | 2 | WRAP-03 | T-06-02 | allow-skip-backup meta stripped | smoke | `printf 'yes\n' \| ./arch/dots-hyprland.sh install --skip-backup --allow-skip-backup --dry-run \| tee /tmp/w6-sb.txt; grep -q -- '--skip-backup' /tmp/w6-sb.txt; ! grep -q -- '--allow-skip-backup' /tmp/w6-sb.txt` | ❌ W0 | ⬜ pending |
| 06-02-T7 | 02 | 2 | WRAP-04 | T-06-01 | Extra flags after defaults | smoke | `printf 'yes\n' \| ./arch/dots-hyprland.sh install --exp-files --dry-run \| grep -E -- '--core.*--exp-files\|--skip-hyprland.*--exp-files'` | ❌ W0 | ⬜ pending |
| 06-03-T1 | 03 | 3 | WRAP-01..04 | T-06-01..03 | Full dry/help suite | smoke | Full suite from research Validation Architecture | ❌ W0 | ⬜ pending |
| 06-03-T2 | 03 | 3 | D-14 | T-06-05 | Preflight fail closed | smoke | Preflight failure path with trap restore of setup +x | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

*Task IDs above are provisional — planner must align PLAN task IDs and embed equivalent `<automated>` verifies.*

---

## Wave 0 Requirements

- [ ] `arch/dots-hyprland.sh` — implement before automated verifies can run
- [ ] Embed WRAP assert commands in each plan’s `<verify><automated>` (inline preferred; Phase 5 style)
- [ ] Optional: `scripts/phase06-wrapper-smoke.sh` one-shot full suite — **not required** if plans embed asserts
- [ ] Framework install: none
- [ ] **Require wrapper `--dry-run`** so asserts never call real install

*Existing infrastructure: bash only; no pytest/jest. Phase 5 style inline smoke is the standard.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Real install-deps / install-files on machine | LIVE-* | Phase 7 | Not Phase 6 |
| Session `qs -c ii` dual-run | LIVE-04 | Phase 7 | Not Phase 6 |
| Non-interactive gate policy | WRAP-03 edge | Deferred | Phase 6 assumes interactive operator |

---

## Security Domain (ASVS L1)

| Threat | STRIDE | Mitigation (plan threat_model) |
|--------|--------|--------------------------------|
| Unexpected subcommand (uninstall) | Elevation / Tampering | Allowlist WRAP-01 four only |
| Accidental `--skip-backup` | Tampering / data loss | Refuse without `--allow-skip-backup` |
| Hypr conf destruction | Tampering | Default full `--skip-hyprland` |
| Command injection via flags | Tampering | Array exec; never `eval` |
| Silent auto-fix mutating git | Tampering | Never auto submodule init |
| Secrets in logs | Info disclosure | Log flags/paths only |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
