# Phase 7: Install, Session Hooks & Dual-Run Verify - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-26
**Phase:** 7-Install, Session Hooks & Dual-Run Verify
**Areas discussed:** Symlink break & pre-install backup, Install command sequence, Session hook placement, Dual-run verify bar policy

---

## Symlink break & pre-install backup

| Option | Description | Selected |
|--------|-------------|----------|
| Unlink only | rm symlink not target; repo tree untouched | |
| Unlink + leave path absent | Same unlink; ensure nothing at path so setup creates real dir | ✓ |
| You decide | Agent picks safest unlink | |

**User's choice:** Unlink + leave path absent

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — manual pre-backup | Extra ~/dots-pre-ii-backup-$stamp before wrapper | |
| Wrapper gate only | Rely on Phase 6 yes-gate / ii backup | |
| Both, optional helper | Manual + optional one-liner | |
| Other: no need for backup | Free-text | ✓ |

**User's choice:** no need for backup  
**Notes:** Interpreted as no *extra* operator pre-backup tarball. Phase 6 hard backup gate on wrapper remains (do not skip-backup by default).

| Option | Description | Selected |
|--------|-------------|----------|
| Stop qs first | pkill/quit qs before retarget | ✓ |
| Don’t require stop | Proceed with qs running | |
| You decide | Agent chooses | |

**User's choice:** Stop qs first

| Option | Description | Selected |
|--------|-------------|----------|
| Leave repo tree alone | Phase 8 deletes product later | ✓ |
| Archive/move out of the way | Park repo tree without full retirement | |
| You decide | Minimal path for LIVE-01 | |

**User's choice:** Leave it alone until Phase 8

---

## Install command sequence

| Option | Description | Selected |
|--------|-------------|----------|
| One-shot install | `arch/dots-hyprland.sh install` | ✓ |
| Staged three steps | deps → setups → files | |
| Deps/setups staged, files last | Partial staging | |

**User's choice:** One-shot install

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — dry-run first | Confirm safe defaults argv | ✓ |
| No dry-run required | Straight to live | |
| You decide | Agent picks | |

**User's choice:** Yes — dry-run first

| Option | Description | Selected |
|--------|-------------|----------|
| OK mid-session | After stop qs; reload after | ✓ |
| Prefer TTY / outside Hypr | Cooler install | |
| You decide | Agent chooses | |

**User's choice:** OK mid-session

| Option | Description | Selected |
|--------|-------------|----------|
| Re-run wrapper after fix | No automated rollback | ✓ |
| Document restore from ii backup | UAT restore steps | |
| Both re-run + restore notes | Hybrid | |

**User's choice:** Re-run wrapper after fix

---

## Session hook placement

| Option | Description | Selected |
|--------|-------------|----------|
| Inline in hyprland.conf | Direct env + exec-once | |
| Sourced snippet file | Isolated ii-session.conf | |
| Other: keep own hyprland config | Free-text | ✓ (intent) |

**User's choice:** Keep own hyprland config (no ii hypr takeover)  
**Follow-up:** Inline lines in personal hyprland.conf selected as placement mechanism.

| Option | Description | Selected |
|--------|-------------|----------|
| Commit to .dotfiles | Version LIVE-02 in repo | ✓ |
| Live only first | Patch ~/.config/hypr only | |
| Both same change | Repo + live sync | |

**User's choice:** Commit to .dotfiles

| Option | Description | Selected |
|--------|-------------|----------|
| Default XDG path | ~/.local/state/quickshell/.venv | ✓ |
| Only if venv exists | Gate on post-install venv | |
| You decide | Agent uses upstream default | |

**User's choice:** Default XDG path

| Option | Description | Selected |
|--------|-------------|----------|
| exec-once = qs -c ii | Plain LIVE-02 | ✓ |
| exec-once with full path | /usr/bin/qs -c ii | |
| You decide | Most reliable one-liner | |

**User's choice:** exec-once = qs -c ii

| Option | Description | Selected |
|--------|-------------|----------|
| Inline lines in hyprland.conf | After clarifying personal SoT | ✓ |
| Personal sourced snippet | Still owned tree | |
| You decide | Minimal change | |

**User's choice:** Inline lines in hyprland.conf

---

## Dual-run verify bar policy

| Option | Description | Selected |
|--------|-------------|----------|
| Hook first, then verify | Commit hooks then LIVE-04 | ✓ |
| Manual qs first, then exec-once | Prove chrome before autostart | |
| You decide | Agent picks order | |

**User's choice:** Hook first, then verify

| Option | Description | Selected |
|--------|-------------|----------|
| Both bars OK even if overlap | Dual-run intentional | ✓ |
| ii must be clearly visible | Not process-only | |
| You decide | Practical UAT | |

**User's choice:** Both bars OK even if overlap

| Option | Description | Selected |
|--------|-------------|----------|
| Process + env + visible chrome | All three for LIVE-04 | ✓ |
| Visible chrome alone | Visual only | |
| Process + real tree only | No visual requirement | |

**User's choice:** Process + env + visible chrome

| Option | Description | Selected |
|--------|-------------|----------|
| hyprctl reload + restart qs | Prefer no full logout | ✓ |
| Full re-login required | Clean env apply | |
| Either is fine | Document both | |

**User's choice:** hyprctl reload + restart qs

---

## Claude's Discretion

- Exact stop-qs command / warn-if-not-running
- Exact hypr `env =` line formatting
- Line placement within hyprland.conf
- Dry-run/live plan task wording
- LIVE-01 filesystem assertion commands
- Repo→live hypr conf sync mechanics (commit required; live must match)

## Deferred Ideas

- Phase 8 product retirement
- Phase 9 full docs + restore playbook
- Later: Waybar cutover, Lua hypr cutover, wrapper verify subcommand
