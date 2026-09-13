---
phase: 17
requirement: START-02
document: post-login-check
status: observed-pass
created: 2026-09-13
observed: 2026-09-13 17:43:39
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

---

# Observation — 2026-09-13, PASS

The operator logged out and back in. `graphical-session.target` came up.

| Fact | Evidence |
| --- | --- |
| Target is up | `systemctl --user is-active graphical-session.target` → `active` |
| Unit ran | `Active: active (exited) since Sun 2026-09-13 17:43:39 +06`, `ExecStart=/usr/bin/true (code=exited, status=0/SUCCESS)`, main PID 156725 |
| Unit is still `linked` | `Loaded: loaded (/home/pera/.config/systemd/user/hyprland-session.service; linked; preset: enabled)` — the stow link survived the logout |
| Start is new, not the wave-5 pair | journal shows `17:43:39.806068 Starting…` as a third entry, distinct from the `16:40:47.593787` start and `16:40:49.932249` stop |
| It was the hook, not a hand start | Hyprland restarted as pid 156671 at `17:43:38`; the unit started at `17:43:39.806068`, 1.2 s later. No operator command ran between them. |
| The Lua session survived | `hyprctl -j status` → `configProvider: lua`; `~/.config/hypr/hyprland.conf` still absent |

The 1.2-second gap between the compositor starting and the unit starting is the
load-bearing evidence. It places the start inside Hyprland's own startup, which is
where `hl.on("hyprland.start", …)` fires, and rules out both a leftover from the
earlier session and a manual `systemctl --user start`.

START-02 is flipped to complete in `.planning/REQUIREMENTS.md`. Phase 17 closes at 7
of 7 requirements.

## Two observations from the same login, neither a Phase 17 defect

**`plasma-xdg-desktop-portal-kde.service` is failed.** It died at `17:43:35` with
`The Wayland connection broke. Did the Wayland compositor die?` and
`status=255/EXCEPTION` — that is the old compositor (pid 1501) going down during the
logout, three seconds before the new one came up. It had also been logging
`Failed to register with host portal … Connection already associated with an
application ID` since `16:34:32`, before this phase touched anything. Pre-existing,
plus a logout artifact. It is a KDE portal on a Hyprland session and is unrelated to
the `xdg-desktop-portal-hyprland` path that `graphical-session.target` exists to serve.

**`waybar.service`, `swaync.service` and `hyprpaper.service` are all `inactive`.**
They were inactive before the logout too. `graphical-session.target` being up does not
pull them; nothing currently does. Under the ii shell, Quickshell owns the bar and the
wallpaper, so this is a changed owner rather than breakage — see the
`docs/dots-hyprland-workflow.md` adopt-cost list. START-02 asks only that the target be
active, which it is. Whether these units should be wired to the target is Phase 20's
question.
