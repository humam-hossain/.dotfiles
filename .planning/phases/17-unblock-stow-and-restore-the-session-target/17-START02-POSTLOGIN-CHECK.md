---
phase: 17
requirement: START-02
document: post-login-check
status: pending-observation
created: 2026-09-13
---

# START-02 — post-login observation

START-02 asks that `graphical-session.target` be **active in a live session**, pulled
up by `hyprland-session.service`, which `custom/execs.lua` starts from its
`hyprland.start` handler.

Everything except that observation is verified. The mechanism cannot fire in the
session that was running when Phase 17 executed: Hyprland pid 1501 started at
16:34:32, before plan 17-05 landed the hook, so the handler was never registered in
that instance. Only a fresh login can register it.

## Pre-logout state, measured 2026-09-13 at HEAD `7a5f05f`

| Fact | Command | Result |
| --- | --- | --- |
| Hook is live | `cmp -s ~/.config/hypr/custom/execs.lua .config/hypr/custom/execs.lua` | identical |
| Hook is correct | `grep -n 'hl.exec_cmd' ~/.config/hypr/custom/execs.lua` | line 19, inside the `hyprland.start` handler opened at line 18 |
| Unit is reachable | `systemctl --user is-enabled hyprland-session.service` | `linked`, exit 1 — the correct state per D-17, not an error |
| Unit is stow-managed | `readlink -f ~/.config/systemd/user/hyprland-session.service` | `/home/pera/github_repo/.dotfiles/stow/systemd/.config/systemd/user/hyprland-session.service` |
| Target is down | `systemctl --user is-active graphical-session.target` | `inactive`, exit 3 |

The target being `inactive` before the logout is what makes the post-login reading
evidence rather than a leftover.

## Run these after logging back in

```bash
systemctl --user is-active graphical-session.target
systemctl --user status hyprland-session.service --no-pager
journalctl --user -b -u hyprland-session.service -o short-precise --no-pager
```

## How to read the result

**PASS** — `is-active` prints `active` and exits 0, and the journal shows the unit
starting at login time rather than at 16:40:47 (that earlier pair is wave 5's hand
proof and its revert, not the hook firing).

Then flip START-02 in `.planning/REQUIREMENTS.md`: line 42 `- [ ]` becomes `- [x]`,
and the Phase 17 row in the coverage table becomes `Complete`. Phase 17 then closes at
7 of 7 requirements.

**FAIL** — `is-active` prints `inactive` or `failed`. The session still works; what is
missing is the bootstrap, so the xdg-desktop-portal ScreenCast path may not work.
Recover by hand, which also tells you whether the unit or the hook is at fault:

```bash
systemctl --user start hyprland-session.service
systemctl --user is-active graphical-session.target
```

If the manual start brings the target up, the unit is fine and the hook did not fire —
that is a Lua-handler defect and belongs to a new plan. If the manual start also fails,
the unit itself is at fault; read its journal.

Do not use `systemctl --user enable`. The unit is deliberately `linked`, and
`systemctl --user disable` deletes the stow symlink — see
`docs/dots-hyprland-workflow.md` § the footgun note at line 347, with its re-stow
recovery.

## Note for whoever resumes this

`scripts/phase17-unblock-assert.sh` reporting `FAIL=0` does **not** certify START-02.
Assertion 5e calls `info()` on every inactive branch and `pass()` only when the target
is already up. The assert going green is not a substitute for the reading above.
