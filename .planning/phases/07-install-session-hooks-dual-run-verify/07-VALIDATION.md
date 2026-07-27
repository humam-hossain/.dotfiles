---
phase: 7
slug: install-session-hooks-dual-run-verify
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-26
---

# Phase 7 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Seeded from `07-RESEARCH.md` ## Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None — inline bash smoke asserts (Phase 5/6 style) |
| **Config file** | none |
| **Quick run command** | `bash -n arch/dots-hyprland.sh && test ! -L "$HOME/.config/quickshell" 2>/dev/null; true` |
| **Full suite command** | LIVE-01..04 assert block + conf greps (see Per-Task Verification Map) |
| **Estimated runtime** | Automated portion ~5–15s; live install itself minutes–tens of minutes |

---

## Sampling Rate

- **After every task commit:** Relevant smoke asserts that do not require live install mutation (conf greps, dry-run, `bash -n`)
- **After every plan wave:** Full LIVE-01..03 automated asserts once install has run; LIVE-04 process asserts
- **Before `/gsd:verify-work`:** All LIVE automated asserts green + operator LIVE-04 chrome confirmation
- **Max feedback latency:** ~15 seconds (automated portion only)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------------|-----------------|-----------|-------------------|-------------|--------|
| 07-01-* | 01 | 1 | LIVE-01 / D-01 | T-7-01 | Symlink unlinked; no rsync-through-symlink | smoke | `pgrep -x qs && exit 1 \|\| true; test ! -e "$HOME/.config/quickshell" \|\| test ! -L "$HOME/.config/quickshell"` | ❌ W0 | ⬜ pending |
| 07-02-* | 02 | 2 | LIVE-01 / D-06 | T-7-02 | Dry-run safe defaults; real dir + ii tree | smoke | `printf 'yes\n' \| ./arch/dots-hyprland.sh install --dry-run \| tee /tmp/p7-dry.txt; grep -q -- '--core' /tmp/p7-dry.txt; grep -q -- '--skip-hyprland' /tmp/p7-dry.txt; grep -q -- '--skip-sysupdate' /tmp/p7-dry.txt` then post-install `test ! -L ~/.config/quickshell && test -f ~/.config/quickshell/ii/shell.qml` | ✅ wrapper / ❌ post | ⬜ pending |
| 07-03-* | 03 | 3 | LIVE-02, LIVE-03, LIVE-04 | T-7-03 | Hooks committed; dual-run; env on qs | smoke + manual | conf greps + `cmp` + `pgrep waybar` + `pgrep qs` + `/proc/.../environ` + operator chrome | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

### Requirement → Test Map (from research)

| Req ID | Behavior | Test Type | Automated Command |
|--------|----------|-----------|-------------------|
| LIVE-01 | Real dir not symlink; ii tree present | smoke | `test ! -L ~/.config/quickshell && test -d ~/.config/quickshell && test -f ~/.config/quickshell/ii/shell.qml` |
| LIVE-01 | Not pointing at repo product | smoke | `case $(readlink -f ~/.config/quickshell) in */.dotfiles/.config/quickshell*) exit 1;; esac` |
| LIVE-02 | Repo conf has env + exec-once | smoke | `grep -E 'env = ILLOGICAL_IMPULSE_VIRTUAL_ENV,' .config/hypr/hyprland.conf && grep -E 'exec-once = qs -c ii' .config/hypr/hyprland.conf` |
| LIVE-02 | Live conf matches repo | smoke | `cmp -s .config/hypr/hyprland.conf ~/.config/hypr/hyprland.conf` |
| LIVE-03 | waybar still running | smoke | `pgrep -x waybar` |
| LIVE-03 | waybar exec-once not removed | smoke | `grep -E 'exec-once = waybar' .config/hypr/hyprland.conf` |
| LIVE-04 | qs process with ii | smoke | `pgrep -a qs \| grep -E -- '-c ii\|\bii\b'` |
| LIVE-04 | env on qs process | smoke | `tr '\0' '\n' < /proc/$(pgrep -n -x qs)/environ \| grep ILLOGICAL_IMPULSE_VIRTUAL_ENV` |
| LIVE-04 | Visible ii chrome | manual | Operator confirms bar/shell chrome on screen |

---

## Wave 0 Requirements

- [ ] No dedicated `scripts/phase07-live-smoke.sh` — optional; plans embed asserts inline (preferred, Phase 6 style)
- [ ] LIVE-* asserts only become meaningful **after** 07-01/07-02 mutate the machine — Wave 0 is “commands documented,” not pre-existing green CI
- [ ] Framework install: none
- [ ] Manual UAT checklist for LIVE-04 visual chrome (operator)

*Existing infrastructure covers phase needs: bash, hyprctl, pgrep — sufficient. No pytest/jest.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visible ii shell chrome on screen | LIVE-04 | Compositor visual confirmation cannot be automated reliably | After hooks applied and qs restarted: operator confirms Material/ii bar or shell chrome is visible alongside Waybar |
| Interactive backup gate answers | D-02 / LIVE-01 | Wrapper + upstream prompts require operator | Type `yes` at wrapper gate; prefer `y` at upstream backup prompt to `~/ii-original-dots-backup` |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s (automated)
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
