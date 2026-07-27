---
phase: 7
slug: install-session-hooks-dual-run-verify
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-07-26
validated: 2026-07-27
---

# Phase 7 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Seeded from `07-RESEARCH.md` ## Validation Architecture.
> Audited and closed by `/gsd:verify-work` → validate-phase post-hook (2026-07-27).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None — bash smoke script (Phase 5/6 style + durable Wave 0 script) |
| **Config file** | none |
| **Quick run command** | `./scripts/phase07-live-smoke.sh` |
| **Full suite command** | `./scripts/phase07-live-smoke.sh` + LIVE-04 chrome (UAT Test 14) |
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
| 07-01-* | 01 | 1 | LIVE-01 / D-01 | T-7-01 | Symlink unlinked; no rsync-through-symlink | smoke | residual `! -L` + real tree (post-install); pre-install gate in SUMMARY | ✅ `scripts/phase07-live-smoke.sh` | ✅ green |
| 07-02-* | 02 | 2 | LIVE-01 / D-06 | T-7-02 | Dry-run safe defaults; real dir + ii tree | smoke | `./scripts/phase07-live-smoke.sh` (D-06 dry-run + LIVE-01 block) | ✅ wrapper + smoke | ✅ green |
| 07-03-* | 03 | 3 | LIVE-02, LIVE-03, LIVE-04 | T-7-01..06 | Hooks committed; dual-run; env on qs | smoke + manual | smoke LIVE-02..04 process/env; chrome via UAT | ✅ smoke + UAT | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

### Requirement → Test Map (from research)

| Req ID | Behavior | Test Type | Automated Command | Status |
|--------|----------|-----------|-------------------|--------|
| LIVE-01 | Real dir not symlink; ii tree present | smoke | `test ! -L && -d && -f ii/shell.qml` via smoke script | ✅ green |
| LIVE-01 | Not pointing at repo product | smoke | `readlink -f` not under `*/.dotfiles/.config/quickshell` | ✅ green |
| LIVE-01 | ii Python venv | smoke | `test -d ~/.local/state/quickshell/.venv` | ✅ green |
| LIVE-01 | Personal hypr conf not `.old` | smoke | conf present, no `.old` | ✅ green |
| LIVE-01 / D-06 | Dry-run SAFE_DEFAULTS | smoke | `install --dry-run` shows `--core --skip-hyprland --skip-sysupdate` | ✅ green |
| LIVE-02 | Repo conf has env + exec-once | smoke | greps on `.config/hypr/hyprland.conf` | ✅ green |
| LIVE-02 | Live conf matches repo | smoke | `cmp -s` repo ↔ live | ✅ green |
| LIVE-03 | waybar still running | smoke | `pgrep -x waybar` | ✅ green |
| LIVE-03 | waybar exec-once not removed | smoke | `grep exec-once = waybar` | ✅ green |
| LIVE-04 | qs process with ii | smoke | `pgrep -a qs` matches `-c ii` | ✅ green |
| LIVE-04 | env on qs process | smoke | `/proc/$pid/environ` has `ILLOGICAL_IMPULSE_VIRTUAL_ENV` | ✅ green |
| LIVE-04 | Visible ii chrome | manual | Operator confirms chrome (UAT Test 14: pass) | ✅ green (UAT) |

---

## Wave 0 Requirements

- [x] Durable `scripts/phase07-live-smoke.sh` encodes LIVE automated asserts (re-runnable)
- [x] LIVE-* asserts meaningful **after** 07-01/07-02 machine mutation — suite run green post-install
- [x] Framework install: none (bash + pgrep + hypr paths sufficient)
- [x] Manual UAT checklist for LIVE-04 visual chrome — closed in `07-UAT.md` Test 14

*Existing infrastructure covers phase needs: bash, hyprctl, pgrep — sufficient. No pytest/jest.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions | Result |
|----------|-------------|------------|-------------------|--------|
| Visible ii shell chrome on screen | LIVE-04 | Compositor visual confirmation cannot be automated reliably | After hooks applied and qs restarted: operator confirms Material/ii bar or shell chrome is visible alongside Waybar | **pass** — UAT Test 14: "in the workspace chrome logo is present" |
| Interactive backup gate answers | D-02 / LIVE-01 | Wrapper + upstream prompts require operator | Type `yes` at wrapper gate; prefer `y` at upstream backup prompt to `~/ii-original-dots-backup` | **pass** — recorded in 07-02-SUMMARY; backup dir present |

---

## Validation Audit 2026-07-27

| Metric | Count |
|--------|-------|
| Gaps found | 3 task rows pending + draft VALIDATION |
| Automated asserts re-run | 15 PASS / 0 FAIL (`./scripts/phase07-live-smoke.sh`) |
| Resolved (automated) | All LIVE-01..04 process/path asserts |
| Resolved (manual via UAT) | LIVE-04 chrome + D-02 backup gate history |
| Escalated | 0 |
| Wave 0 script | `scripts/phase07-live-smoke.sh` created + green |

**Gap classification (pre → post):**

| Item | Pre | Post |
|------|-----|------|
| 07-01 smoke | MISSING (pending map) | COVERED |
| 07-02 dry-run + LIVE-01 | PARTIAL (commands only) | COVERED |
| 07-03 dual-run + env | MISSING (pending map) | COVERED |
| LIVE-04 chrome | manual-only | COVERED via UAT pass |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (`scripts/phase07-live-smoke.sh`)
- [x] No watch-mode flags
- [x] Feedback latency < 15s (automated)
- [x] `nyquist_compliant: true` set in frontmatter
- [x] `status: validated` set in frontmatter

**Approval:** validated 2026-07-27 (verify-work post-hook; FAIL=0 smoke + UAT 14/14)
