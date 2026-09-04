# Phase 14 live full adopt runbook

Operator playbook for the one-window live `illogical-impulse` (`ii`) full adopt on this machine: install, overlay apply, reboot, first login, verification, and rollback.

## Purpose

Phase 14 is the first phase that mutates the live machine, and **the operator runs the mutation, not an agent** (ADOPT-01, D-01). This document is the single unambiguous order for the whole window (D-21). Read it end to end before starting.

One window covers all of it: install → overlay apply → reboot → first login → verify. There is no second gate part-way through (D-21).

> **Flag / subcommand details:** keep DRY — run `./arch/dots-hyprland.sh help` for the full allowlist, safe defaults, backup gate, uninstall, and protect behavior. This document does not re-copy the help text. It names only the flags that are *forbidden* (section 4) and the ones the window actually uses.

> **Read this from GitHub or from your local copy, not from a browser you no longer have.** Section 2 stages a plain-text copy outside the config tree so section 14 is reachable from a bare TTY (D-25).

## Outline

1. [Prerequisites and scope of this window](#1-prerequisites-and-scope-of-this-window)
2. [Start the recording and stage an offline copy](#2-start-the-recording-and-stage-an-offline-copy)
3. [Go / no-go gate (ADOPT-01, D-18..D-22)](#3-go--no-go-gate-adopt-01-d-18d-22)
4. [Banned flags and prompt answers (D-22)](#4-banned-flags-and-prompt-answers-d-22)
5. [Rotate the stale backup (D-27)](#5-rotate-the-stale-backup-d-27)
6. [Stop Hyprland and switch to a bare TTY (D-06)](#6-stop-hyprland-and-switch-to-a-bare-tty-d-06)
7. [Run the install (D-07)](#7-run-the-install-d-07)
8. [Apply the Phase 13 overlay (D-08)](#8-apply-the-phase-13-overlay-d-08)
9. [Re-stow kitty (D-17)](#9-re-stow-kitty-d-17)
10. [Reboot (D-10)](#10-reboot-d-10)
11. [Log in at a TTY and start the session (D-16)](#11-log-in-at-a-tty-and-start-the-session-d-16)
12. [Verify (plan 14-02)](#12-verify-plan-14-02)
13. [Known losses (D-38)](#13-known-losses-d-38)
14. [Rollback (ADOPT-04, D-23, D-24)](#14-rollback-adopt-04-d-23-d-24)

Reference links live in [See also](#see-also) at the foot of the file.

---

## 1. Prerequisites and scope of this window

<!-- filled in Task 6 -->

---

## 2. Start the recording and stage an offline copy

<!-- filled in Task 6 -->

---

## 3. Go / no-go gate (ADOPT-01, D-18..D-22)

**The gate is this checklist, worked by a human. It is not a script's exit code.**

`./scripts/phase14-preflight.sh` is **input 1** to the gate. Run it from the repo root:

```bash
./scripts/phase14-preflight.sh
# expect: exit 0, and a [FINDING] line naming ii-original-dots-backup
```

The script prints at three levels and only the last one moves its exit code:

| Level | Meaning | Moves exit code |
|---|---|---|
| `[PASS]` | hard condition satisfied | — |
| `[FINDING]` | a condition the script deliberately declines to encode as an exit code, because clearing it requires a `$HOME` mutation reserved for this window | **no** |
| `[FAIL]` | hard condition violated | **yes** |

That split is D-18 in practice: the exit code is input 1, this checklist is the gate. A `[FINDING]` is not a pass — it is a condition you must disposition here, by hand, before deciding.

The remaining go inputs and the full no-go list are in the completed section below.

<!-- go checklist and no-go list filled in Task 6 -->

---

## 4. Banned flags and prompt answers (D-22)

<!-- filled in Task 6 -->

---

## 5. Rotate the stale backup (D-27)

<!-- filled in Task 6 -->

---

## 6. Stop Hyprland and switch to a bare TTY (D-06)

<!-- filled in Task 6 -->

---

## 7. Run the install (D-07)

<!-- filled in Task 6 -->

---

## 8. Apply the Phase 13 overlay (D-08)

<!-- filled in Task 6 -->

---

## 9. Re-stow kitty (D-17)

<!-- filled in Task 6 -->

---

## 10. Reboot (D-10)

<!-- filled in Task 6 -->

---

## 11. Log in at a TTY and start the session (D-16)

<!-- filled in Task 6 -->

---

## 12. Verify (plan 14-02)

<!-- filled in Task 6 -->

---

## 13. Known losses (D-38)

The bar stack this machine autostarts today is `Waybar/rofi/swaync`. Its autostart goes away with the renamed `hyprland.conf`; the packages themselves stay installed.

<!-- full known-loss split filled in Task 6 -->

---

## 14. Rollback (ADOPT-04, D-23, D-24)

<!-- filled in Task 6 -->

---

## See also

- [`docs/dots-hyprland-workflow.md`](./dots-hyprland-workflow.md) — canonical install/adopt playbook
- [`.planning/phases/13-personal-hypr-custom-overlays/13-SOT-APPLY.md`](../.planning/phases/13-personal-hypr-custom-overlays/13-SOT-APPLY.md) — overlay source of truth and the authoritative apply command
- [`.planning/phases/11-disposition-decisions/11-DISPOSITIONS.md`](../.planning/phases/11-disposition-decisions/11-DISPOSITIONS.md) — per-item adopt dispositions
