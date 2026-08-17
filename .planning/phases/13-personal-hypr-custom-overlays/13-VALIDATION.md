---
phase: 13
slug: personal-hypr-custom-overlays
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-17
---

# Phase 13 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Source: `13-RESEARCH.md` § Validation Architecture + CONTEXT D-01..D-13.
> **No live apply and no live full install this phase.** All automated checks are repo file existence / content greps.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Inline bash asserts (Phase 6/12 pattern) — no bats/pytest suite in repo |
| **Config file** | none — plan-task `<verify><automated>` commands |
| **Quick run command** | `test -f .config/hypr/custom/env.lua && test -f .config/hypr/custom/general.lua && test -f .config/hypr/custom/execs.lua && test -f .planning/phases/13-personal-hypr-custom-overlays/13-SOT-APPLY.md` |
| **Full suite command** | Quick run + D-16 presence greps + D-17 absence greps + vendor-clean check |
| **Estimated runtime** | ~2–5 seconds |

---

## Sampling Rate

- **After every task commit:** existence of the file that task created + the task’s automated verify block
- **After every plan wave:** full OVL-01 / OVL-02 / OVL-03 suite
- **Before `/gsd-verify-work`:** full suite green; **no** live apply and **no** `install --full`
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 13-OVL-01 | * | * | OVL-01 | T-13-03 | Three custom Lua files express D-16 (monitors, pins, env, setcursor) | smoke | `grep -q 'DP-1' .config/hypr/custom/general.lua && grep -q 'HDMI-A-2' .config/hypr/custom/general.lua && grep -q 'workspace_rule' .config/hypr/custom/general.lua && grep -q 'special:social' .config/hypr/custom/general.lua && grep -q 'XCURSOR_THEME' .config/hypr/custom/env.lua && grep -q 'ILLOGICAL_IMPULSE_VIRTUAL_ENV' .config/hypr/custom/env.lua && grep -q 'setcursor catppuccin-mocha-dark-cursors 30' .config/hypr/custom/execs.lua` | ❌ W0 | ⬜ pending |
| 13-OVL-01b | * | * | OVL-01 | T-13-05 | No root monitors.lua / workspaces.lua; no custom keybinds/rules content | smoke (neg) | `test ! -e .config/hypr/monitors.lua && test ! -e .config/hypr/workspaces.lua && test ! -e .config/hypr/custom/keybinds.lua && test ! -e .config/hypr/custom/rules.lua` | ❌ W0 | ⬜ pending |
| 13-OVL-01c | * | * | OVL-01 | T-13-03 | No D-17 leakage | smoke (neg) | `! grep -Eiq 'google-chrome|vesktop|waybar|swaync|qs -c ii' .config/hypr/custom/*.lua` | ❌ W0 | ⬜ pending |
| 13-OVL-02 | * | * | OVL-02 | T-13-02 | Real repo files exist (not checklist-only) | smoke | `test -s .config/hypr/custom/env.lua && test -s .config/hypr/custom/general.lua && test -s .config/hypr/custom/execs.lua` | ❌ W0 | ⬜ pending |
| 13-OVL-03 | * | * | OVL-03 | T-13-01 | SoT + apply rule written | smoke | `test -s .planning/phases/13-personal-hypr-custom-overlays/13-SOT-APPLY.md && grep -q '.config/hypr/custom' .planning/phases/13-personal-hypr-custom-overlays/13-SOT-APPLY.md && grep -q 'cp -a' .planning/phases/13-personal-hypr-custom-overlays/13-SOT-APPLY.md` | ❌ W0 | ⬜ pending |
| 13-OVL-03b | * | * | OVL-03 | T-13-01 | Overlays not committed into vendor | smoke | `test -z "$(git -C vendor/dots-hyprland status --short -- dots/.config/hypr/custom)"` | ✅ vendor tree | ⬜ pending |
| 13-D08 | * | * | D-08 | — | Cursor env + venv both present | grep | `grep -q 'Catppuccin-Mocha-Dark-Cursors' .config/hypr/custom/env.lua && grep -q 'XCURSOR_SIZE' .config/hypr/custom/env.lua` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Create `.config/hypr/custom/{env,general,execs}.lua` (currently ABSENT)
- [ ] Create `13-SOT-APPLY.md`
- [ ] Plan-task automated verify commands for the matrix above (inline; no dedicated test framework)
- [ ] **Do not** add live apply / session mutation checks this phase

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Live apply of repo custom/ onto `~/.config/hypr/custom/` | OVL-02 / D-02 | Phase 14 executes apply; this phase must not mutate live | After Phase 14: run the `cp -a` from 13-SOT-APPLY.md and confirm dual-head + cursor |
| Session actually honors `hl.workspace_rule` pins | OVL-01 | Requires live Hyprland after adopt | Phase 14: workspaces 1–5 / special:social on DP-1; 6–10 on HDMI-A-2 |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
