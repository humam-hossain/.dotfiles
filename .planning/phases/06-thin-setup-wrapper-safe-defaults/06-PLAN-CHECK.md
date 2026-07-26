# Phase 6 Plan Check — Thin Setup Wrapper & Safe Defaults

**Checked:** 2026-07-26  
**Plans:** 06-01, 06-02, 06-03  
**Checker:** gsd-plan-checker (goal-backward)  
**Revision loop:** initial

## Phase Goal (from ROADMAP)

Provide a `.dotfiles`-native entrypoint that drives upstream setup without destroying personal Hyprland config.

**Requirements:** WRAP-01, WRAP-02, WRAP-03, WRAP-04  
**Success criteria:** wrapper → `./setup` for four subcommands; defaults include `--core --skip-hyprland`; backup gate; flag passthrough.

---

## Dimension Results

| # | Dimension | Result |
|---|-----------|--------|
| 1 | Requirement coverage | PASS |
| 2 | Task completeness | PASS |
| 3 | Dependency correctness | PASS |
| 4 | Key links planned | PASS |
| 5 | Scope sanity | PASS |
| 6 | Verification derivation (must_haves) | PASS |
| 7 | Context compliance (D-01..D-17) | PASS |
| 7b | Scope reduction | PASS |
| 7c | Architectural tier compliance | PASS |
| 8 | Nyquist compliance | PASS |
| 9 | Cross-plan data contracts | PASS |
| 10 | CLAUDE.md compliance | SKIPPED (no CLAUDE.md) |
| 11 | Research resolution | PASS (no open questions; section prose-resolved) |
| 12 | Pattern compliance | PASS |
| — | Verify command format sanity | PASS (with warnings) |
| — | Deferred / Phase 7 scope creep | PASS (explicitly excluded) |

### Dimension 1: Requirement Coverage

| Requirement | Plans | Tasks | Status |
|-------------|-------|-------|--------|
| WRAP-01 | 01, 03 | 01-T1, 01-T2, 03-T1/T2 | COVERED |
| WRAP-02 | 02, 03 | 02-T1, 02-T2, 03-T1 | COVERED |
| WRAP-03 | 02, 03 | 02-T2, 03-T1 | COVERED |
| WRAP-04 | 02, 03 | 02-T2 (exp-files), 03-T1 | COVERED |

Frontmatter `requirements:` fields include all WRAP-01..04 across the plan set (01 claims WRAP-01; 02 claims 02–04; 03 claims all four). ROADMAP SC 1–4 map to plan actions + 06-03 suite.

### Dimension 2: Task Completeness

All six tasks are `type="auto"` with `<files>`, `<action>`, `<verify><automated>`, `<done>`, plus `<read_first>` and `<acceptance_criteria>`. Threat models present on all three plans with high-severity items mitigated (allowlist, skip-backup dual-key, full `--skip-hyprland`, array exec).

### Dimension 3: Dependency Correctness

```
06-01 wave 1  depends_on: []
06-02 wave 2  depends_on: ["06-01"]
06-03 wave 3  depends_on: ["06-02"]
```

Acyclic; matches Phase 5 id style (`05-01`). No forward refs.

### Dimension 4: Key Links

- Wrapper → `vendor/dots-hyprland/setup` via array-exec after preflight (01)  
- SAFE_DEFAULTS → install|install-files argv (02)  
- backup_gate → install|install-files (02)  
- Meta flags stripped before setup (01/02)  
- Smoke suite → dry/help paths only (03)

Wiring is in task actions, not only artifact creation.

### Dimension 5: Scope Sanity

| Plan | Tasks | Files | Wave |
|------|-------|-------|------|
| 01 | 2 | 1 (`arch/dots-hyprland.sh`) | 1 |
| 02 | 2 | 1 | 2 |
| 03 | 2 | 1 | 3 |

Within budget. No package-list reimplementation; no Phase 7 live install; no verify subcommand; no auto submodule init.

### Dimension 6: must_haves

Truths are operator-observable (help, dry-run argv, gate messaging, refuse paths). Artifacts and key_links support them. Prohibitions align with D-15/D-16/D-17 and Phase 7 deferral.

### Dimension 7: Context Compliance

| Decision | Plan coverage |
|----------|----------------|
| D-01 path/subcmds | 01-T1 |
| D-02 bare help | 01-T1 |
| D-03 help + install -h passthrough | 01-T1; 03-T1 |
| D-04 allowlist | 01-T1/T2 |
| D-05..D-10 safe defaults | 02-T1 |
| D-11..D-13 backup gate / skip-backup | 02-T2 |
| D-14..D-16 preflight / smoke | 01-T2; 03-T2 |
| D-17 no verify | 01, 03 static greps |

Deferred ideas (live install, session hooks, retire QS, verify subcmd, exp-update through wrapper, non-interactive gate CI) are excluded via prohibitions.

No silent scope reduction (no “v1 static labels” style dilution of D-06/D-08/D-11).

### Dimension 7c: Architectural Tier

Matches RESEARCH map: policy/defaults/gate in wrapper; package install only upstream setup; smoke via dry-run asserts.

### Dimension 8: Nyquist

| Task | Plan | Wave | Automated | Status |
|------|------|------|-----------|--------|
| T1 scaffold | 01 | 1 | bash -n + help + uninstall refuse | ✅ |
| T2 preflight/dry | 01 | 1 | install-deps --dry-run + exp-merge refuse | ✅ |
| T1 defaults | 02 | 2 | install-deps no skip-hyprland | ✅ |
| T2 gate/skip/pass | 02 | 2 | full WRAP-02/03/04 dry block | ✅ |
| T1 full suite | 03 | 3 | full WRAP dry/help + install -h | ✅ |
| T2 preflight -x + static | 03 | 3 | trap restore + greps | ✅ |

- VALIDATION.md present  
- No watch-mode; latency ~seconds  
- Sampling: every task has `<automated>`  
- No `MISSING` Wave 0 test-file links; Wave 0 is implement wrapper itself (plan 01)  
- Non-mutating: `--dry-run` / help / chmod trap restore only  

Overall Dimension 8: **PASS**

### Dimension 9: Cross-Plan Contracts

Single artifact `arch/dots-hyprland.sh` evolved 01→02→03. SAFE_DEFAULTS constant defined in 01, injected in 02; meta-flag strip in 01 used by 02 policy. Compatible.

### Dimension 11: Research

`## Open Questions` has no unresolved items (“None blocking” + resolved notes). Acceptable for planning.

### Dimension 12: Patterns

Plans cite `arch/quickshell.sh` structure, forbid PACKAGES/yay copy, cite RESEARCH for policy-only patterns — aligns with PATTERNS.md.

---

## Warnings (non-blocking)

```yaml
issues:
  - plan: "06-02"
    dimension: "verification_derivation"
    severity: "warning"
    description: >
      Task 1 automated verify only asserts install-deps does not inject
      --skip-hyprland; install/install-files default injection is deferred to
      Task 2 acceptance/verify. Safe if Task 2 always runs in the same plan,
      but Task 1 alone cannot prove WRAP-02.
    task: 1
    fix_hint: >
      Optionally add printf 'yes\n'|install --dry-run greps to Task 1 after
      noting gate is not yet present (or keep as-is and rely on Task 2).

  - plan: "06-03"
    dimension: "requirement_coverage"
    severity: "warning"
    description: >
      Full suite dry-runs install, install-files, install-deps but not
      install-setups. WRAP-01/ROADMAP SC1 list install-setups; path is the
      same allowlisted exec, so risk is low but proof is incomplete.
    task: 1
    fix_hint: >
      Add: ./arch/dots-hyprland.sh install-setups --dry-run | grep -q setup
      and assert ! --skip-hyprland (mirrors install-deps).

  - plan: "06-01"
    dimension: "task_completeness"
    severity: "warning"
    description: >
      Acceptance criteria require -h/--help exit 0; automated verify only
      exercises bare invocation (and uninstall refuse).
    task: 1
    fix_hint: "Add ./arch/dots-hyprland.sh -h and --help exit 0 to <automated>."

  - plan: null
    dimension: "verify_command_format"
    severity: "warning"
    description: >
      Several <automated> chains use ';' between steps (e.g. grep quickshell;
      grep skip-hyprland && …). Without set -e on the outer shell, a failed
      intermediate grep can be swallowed if a later command succeeds.
    fix_hint: >
      Prefer && between all asserts, or wrap in 'set -euo pipefail; …' so
      the compound exits non-zero on first failure.

  - plan: "06-RESEARCH"
    dimension: "research_resolution"
    severity: "info"
    description: "Open Questions heading lacks '(RESOLVED)' suffix though content is resolved."
    fix_hint: "Rename to '## Open Questions (RESOLVED)' for Nyquist/research hygiene."
```

---

## Goal-Backward Summary

| Must be TRUE | Delivered by |
|--------------|--------------|
| Thin `arch/dots-hyprland.sh` → `./setup` for four subcmds, no package lists | 06-01 + 06-03 static greps |
| Defaults `--core --skip-hyprland` (+ `--skip-sysupdate` per D-06) on install/install-files only | 06-02-T1/T2 + 06-03 |
| Hard backup gate + no bare `--skip-backup` | 06-02-T2 + 06-03 |
| Extra flags after defaults (WRAP-04) | 06-02-T2 + 06-03 exp-files |
| Preflight fail-closed; no auto submodule init; no verify subcmd | 06-01-T2 + 06-03-T2 |
| Smoke help/dry only (D-16); Phase 7 not started | All plan prohibitions |

**Blockers:** 0  
**Warnings:** 4  
**Info:** 1  

Plans are executable and will achieve the phase goal if followed. Warnings are optional polish for verify robustness and install-setups proof.

## VERDICT: PASS

Run `/gsd-execute-phase 6` (or plan-phase proceed) when ready.
