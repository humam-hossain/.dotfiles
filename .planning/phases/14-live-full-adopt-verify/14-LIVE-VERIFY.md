# Phase 14: Live adopt verification record

Post-adopt evidence for ADOPT-02, ADOPT-03 and ADOPT-04's input half, covering D-29 through D-38. The operator ran the one-way `install --full` from a bare TTY on 2026-09-04; this record holds what `scripts/phase14-verify.sh` proved against the running session, what the operator confirmed by eye, what was lost on purpose, and what is deferred. The success bar is D-32 and it is deliberately not perfection: a usable ii desktop, the Phase 13 overlay applied, Waybar/rofi/swaync gone, and findings logged. Two items are logged here as Phase 15 work rather than as phase failures, exactly as D-14 and D-38 direct.

## Verify run

Run date: 2026-09-05. HDMI-A-2 **was attached** — the run went dual-head, so the dual-head half of ADOPT-03 is proven rather than skipped. Result: `FAIL=0 FINDINGS=1`, exit 0.

The script is read-only against the live session: it never terminates a process, never asks the compositor to re-read or set a value, and never writes under `~/.config`. `grep -cE 'pkill|hyprctl reload|hyprctl keyword|rm -rf|rsync .*--delete'` over it is 0.

Provenance of the capture below: it is verbatim from the execution worktree, which is why `repo_root` reads as a path under `.claude/worktrees/`. Everything it probes — `$XDG`, the backup directory, the compositor — is the one shared live system, so the worktree affects nothing but that one line. The same script was run independently from the primary checkout at `/home/pera/github_repo/.dotfiles` against the same session and returned the same `FAIL=0 FINDINGS=1` in dual-head mode.

```
=== Phase 14 post-adopt verify (read-only against the live session) ===
[CONFIG] repo_root=/home/pera/github_repo/.dotfiles/.claude/worktrees/agent-af1038693929f038a
[CONFIG] xdg=/home/pera/.config
[CONFIG] baseline=.planning/phases/14-live-full-adopt-verify/14-PRE-ADOPT-BASELINE.txt
[CONFIG] backup_dir=/home/pera/ii-original-dots-backup
[CONFIG] baseline_captured=2026-09-04T13:42:30Z
[INFO] compositor live instance efb50993780079460b0cbed1363e2166a2de1d9f_1788577451_1908478201 — matches the signature this shell inherited
[PASS] ADOPT-02 hyprland.conf.old present: /home/pera/.config/hypr/hyprland.conf.old
[PASS] ADOPT-02 hyprland.lua present: /home/pera/.config/hypr/hyprland.lua
[PASS] ADOPT-02 hyprland.conf absent — no .conf can win over the Lua entry
[PASS] ADOPT-02 configProvider is 'lua', no longer the recorded pre-adopt 'hyprlang'
[PASS] ADOPT-02 hyprctl eval 'return 1+1' returned the expected 'ok' — the session is under the Lua config manager
[PASS] ADOPT-03 overlay source declares HDMI-A-2 scale=1.5 transform=1: .config/hypr/custom/general.lua
[PASS] ADOPT-03 DP-1 present in hyprctl -j monitors all
[PASS] ADOPT-03 DP-1 scale unchanged at 1 (pre-adopt 1)
[INFO] ADOPT-03 verification ran in DUAL-HEAD mode — HDMI-A-2 is attached
[PASS] ADOPT-03 HDMI-A-2 scale 1.5 transform 1 match the overlay
[PASS] ADOPT-03 Workspace rule 1 live on DP-1
[PASS] ADOPT-03 Workspace rule 2 live on DP-1
[PASS] ADOPT-03 Workspace rule 3 live on DP-1
[PASS] ADOPT-03 Workspace rule 4 live on DP-1
[PASS] ADOPT-03 Workspace rule 5 live on DP-1
[PASS] ADOPT-03 Workspace rule special:social live on DP-1
[PASS] ADOPT-03 Workspace rule 6 live on HDMI-A-2
[PASS] ADOPT-03 Workspace rule 7 live on HDMI-A-2
[PASS] ADOPT-03 Workspace rule 8 live on HDMI-A-2
[PASS] ADOPT-03 Workspace rule 9 live on HDMI-A-2
[PASS] ADOPT-03 Workspace rule 10 live on HDMI-A-2
[PASS] ADOPT-03 ii shell running: qs -c ii
[PASS] ADOPT-03 waybar not running (Waybar/rofi/swaync accept-remove)
[PASS] ADOPT-03 swaync not running (Waybar/rofi/swaync accept-remove)
[INFO] ADOPT-03 rofi not running — vacuous, it never had an autostart; the real check is the launcher keybind (human)
[PASS] ADOPT-04 tier-1 source 1 present and non-empty: /home/pera/.config/hypr/hyprland.conf.old
[PASS] ADOPT-04 tier-1 source 2 present and non-empty: repo .config/hypr/hyprland.conf
[PASS] ADOPT-04 tier-1 source 3 present and non-empty: /home/pera/ii-original-dots-backup
[PASS] ADOPT-04 tier 2 reachable: uninstall --dry-run exits 0
[PASS] ADOPT-04 tier 3 reachable: protect --dry-run exits 0
[PASS] D-36 backup copy present: /home/pera/ii-original-dots-backup/.config/hypr/hyprland.conf
[PASS] D-36 backup copy sha256 matches the pre-adopt fixture (3d17932a6d2dd1b61ccc509402a70c224409bb5c24c4ed70a3c55d4f4bcd89b5)
[PASS] D-36 backup copy mtime 1786770136 is newer than the recorded pre-install 1784818728 — the backup ran
[PASS] D-37 hyprlock.conf byte-identical to the pre-adopt fixture (554 bytes, c3ecd68d0359213b4029d1ffffc35c80a5dfc307b6766580251a5f44844ecd75)
[PASS] D-37 hypridle.conf byte-identical to the pre-adopt fixture (359 bytes, 6e72018489ea9fd47a5c87bd496840d23de2b48d8442620487edb2404fdc3823)
[PASS] D-37 hyprlock.conf sidecar present and unmerged: /home/pera/.config/hypr/hyprlock.conf.new
[PASS] D-37 hyprlock.conf sidecar not promoted — live copy still differs from it
[PASS] D-37 hypridle.conf sidecar present and unmerged: /home/pera/.config/hypr/hypridle.conf.new
[PASS] D-37 hypridle.conf sidecar not promoted — live copy still differs from it
[FINDING] D-38 graphical-session.target is inactive — hyprland-session.service lost its autostart with the renamed conf (expected). This is why screen share may be broken. Phase 15 item.
[INFO] D-38 ScreenCast portal answers AvailableSourceTypes = 'u 7', unchanged from pre-adopt
[INFO] D-38 the personal session unit file SURVIVES in the repo at stow/systemd/.config/systemd/user/hyprland-session.service — only its autostart line is gone, this is not a deletion
[INFO] D-38 known loss 'wl-clip-persist' CONFIRMED not running — its exec-once went with the renamed conf (expected)
[INFO] D-38 known loss (workspace-pinned autostart) 'btop' CONFIRMED not running (expected)
[INFO] D-38 known loss (workspace-pinned autostart) 'vesktop' CONFIRMED not running (expected)
[INFO] D-38 known loss (workspace-pinned autostart) 'discord' CONFIRMED not running (expected)
[INFO] D-38 known loss (workspace-pinned autostart) 'google-chrome-stable on workspace 1' — the archived conf's four pinned autostarts all went with the rename (expected)
[INFO] D-38 known loss 'hyprpaper' CONFIRMED stopped-but-INSTALLED — the binary is on PATH and hyprpaper.conf survives; nothing starts it. Wallpaper is Quickshell's job now, not breakage.
[INFO] D-38 known loss 'hyprland/scripts/launch_first_available.sh' CONFIRMED overwritten by upstream's copy (165 bytes live vs 353 bytes in the repo); the personal version is tracked at repo .config/hypr/hyprland/scripts/launch_first_available.sh
[PASS] D-35 git status --porcelain is clean apart from paths under .planning/phases/14-live-full-adopt-verify/
=== done: FAIL=0 FINDINGS=1 ===
```

## ADOPT-02 proof (D-33)

Three independent conditions, plus a fourth token-free probe. Two are disk facts; two address the running compositor, which is the only thing that distinguishes "the Lua entry was installed" from "the Lua entry is what the session loaded".

| # | Condition | Result |
|---|---|---|
| 1 | `~/.config/hypr/hyprland.conf.old` exists | Present, 15301 bytes, sha256 `3d17932a…89b5` — byte-identical to the pre-adopt conf recorded in the fixture |
| 2 | `~/.config/hypr/hyprland.lua` exists | Present |
| 3 | `~/.config/hypr/hyprland.conf` is gone | Absent — no `.conf` can win over the Lua entry regardless of which format 0.56.2 would prefer, which is why this assertion is correct under either reading of RESEARCH Open Question 1 |
| 4 | `hyprctl -j status` no longer reports the pre-adopt provider | Live value `lua`; recorded pre-adopt value `hyprlang` |
| 5 | `hyprctl eval 'return 1+1'` | Returned `ok` |

**On the post-adopt token.** The observed value is `lua`. This is recorded as an observation, not as something the script asserted equal to a guess. The script asserts the **absence** of the recorded pre-adopt `hyprlang` and nothing more: the pre-adopt token is an observed fact captured before any mutation, the post-adopt token was not, and hard-coding a guessed-good value would have produced a spurious failure the moment upstream renamed it. `lua` is what it happens to be on 0.56.2; the assertion does not depend on that staying true.

**On the `hyprctl eval` response.** The Lua config manager answers a well-formed expression with exactly `ok`. Probed against this session, hyprlang refuses with `eval is only supported with the lua config manager`, and a dead socket answers `Couldn't connect to …`. The check asserts the expected return value; see the verify-script defect in **Findings** for why asserting merely non-empty output was wrong.

## ADOPT-03 result

Ran in **dual-head mode** — HDMI-A-2 was attached. RESEARCH Pitfall 3 predicted it absent and is wrong in the record; plan 14-01 already caught that drift and recorded three `hdmi_a2_*_pre` geometry keys in the fixture, which is what made the dual-head comparison possible here.

**Monitors.** DP-1 present (enforced). DP-1 scale `1`, unchanged from `dp1_scale_pre`. HDMI-A-2 present at scale `1.5` transform `1`, matching what `.config/hypr/custom/general.lua` declares.

**Workspace rules.** All eleven live in the running compositor, each on its declared monitor:

| Workspaces | Pinned to | Result |
|---|---|---|
| 1, 2, 3, 4, 5, `special:social` | DP-1 | 6/6 live on DP-1 |
| 6, 7, 8, 9, 10 | HDMI-A-2 | 5/5 live on HDMI-A-2 |

Their presence in the **running** compositor is the point. `test -f general.lua` proves a copy; `hyprctl -j workspacerules` proves a load. The overlay loaded.

**Shell surface — dual-run policy is accept-remove** (Phase 11 D-11 overrides DISP-03). Called "surface" rather than the usual word for a shell's visible furniture, because D-39 reserves that token in this record for the browser `google-chrome-stable` alone:

| Process | Expected | Observed |
|---|---|---|
| `qs -c ii` | running | running |
| `waybar` | not running | not running |
| `swaync` | not running | not running |
| `rofi` | vacuous — never had an autostart | not running, recorded as `[INFO]` not as a pass |

The overlay apply was named-file only, as D-18 requires. Live `~/.config/hypr/custom/general.lua`, `env.lua` and `execs.lua` are byte-identical to their repo counterparts; `keybinds.lua`, `rules.lua` and `variables.lua` are untouched ii seeds. No delete-sync ran.

## Human checklist (D-29, D-30)

Neither the script nor this checklist satisfies D-29 alone. All four answered by the operator against the running session.

| # | Check | Answer |
|---|---|---|
| 1 | The layout renders correctly and the desktop is usable — the ii bar is up and windows land where expected | **Yes**, across both monitors |
| 2 | The launcher keybind opens the ii launcher | **Yes** |
| 3 | Workspaces land on the monitor the Phase 13 overlay pins them to | **Yes** |
| 4 | Screen share works | **Yes** |

**On check 2.** The binding is a tap-and-release of `SUPER` alone. `~/.config/hypr/hyprland/keybinds.lua:12` binds `SUPER + SUPER_L` to `hl.dsp.global("quickshell:searchToggleRelease")`, with `hl.dsp.exec_cmd(qsIsAlive .. " || pkill fuzzel || fuzzel")` on the following lines as the fallback for when Quickshell is dead. The operator tapped it and the Quickshell search overlay opened. This is the check RESEARCH Pitfall 6 calls for: the launcher package never had an autostart, so "rofi not running" is vacuous and only pressing the key proves anything. The script records that process probe as `[INFO]`, never as a pass, for exactly this reason.

**On check 4.** Screen share works, and the ScreenCast portal reads `AvailableSourceTypes = u 7`, unchanged from `screencast_source_types_pre`. An earlier reading of `u 0` was an artifact of the stale-signature defect below, not a real regression; the portal was never degraded. This is recorded as `[INFO]`, not as a finding. The `graphical-session.target` finding stands on its own and is unrelated to screen share working.

## Rollback inputs (ADOPT-04, D-26, D-36)

Inputs proven present. The restore itself was **not** rehearsed — D-26 asks for reachability, not for a live rollback.

**Tier 1 — the pre-adopt `hyprland.conf`.** Three sources, all carrying the identical sha256 `3d17932a6d2dd1b61ccc509402a70c224409bb5c24c4ed70a3c55d4f4bcd89b5` at 15301 bytes, matching the fixture recorded before any mutation:

| Source | Path | State |
|---|---|---|
| 1 | `~/.config/hypr/hyprland.conf.old` | Present, non-empty, sha matches |
| 2 | repo `.config/hypr/hyprland.conf` | Present, non-empty, sha matches |
| 3 | `~/ii-original-dots-backup/.config/hypr/hyprland.conf` | Present, real file, sha matches |

**D-36 — the backup actually ran.** This is the check that turns tier 1 from assumed-good into checked-good. Upstream skips `auto_backup_configs` outright when the directory already exists and the `ask` branch answers no, so "the directory is there" proves nothing by itself. Both conditions hold:

- sha256 equals the recorded pre-adopt value, so the backup holds the real pre-adopt conf and not some older copy.
- mtime `1786770136` (2026-08-15T05:02:16Z) is newer than the fixture's recorded pre-install `1784818728` (2026-07-23T14:58:48Z). The stale copy runbook step 5 rotated away has been replaced. Transcript confirms the operator answered `y` at `Would you like to backup clashing dirs/files to "/home/pera/ii-original-dots-backup"?` and that the run reported `Backup into "/home/pera/ii-original-dots-backup" finished.`

**Tiers 2 and 3 — reachability.** `./arch/dots-hyprland.sh uninstall --dry-run` and `./arch/dots-hyprland.sh protect --dry-run` each exit 0, standalone and under the verify script. Neither was run without `--dry-run`.

**D-37 — Phase 11 D-24 held.** Live `hyprlock.conf` (554 bytes) and `hypridle.conf` (359 bytes) are byte-identical to their recorded pre-adopt sha256 values, and unpromoted `.new` sidecars sit beside both. The transcript carries upstream's own statement of the branch it took: `[./setup]: It seems not a firstrun.` followed by `cp_file dots/.config/hypr/hyprlock.conf /home/pera/.config/hypr/hyprlock.conf.new`. The firstrun path, which would have replaced the live files outright, did not fire.

## Known losses (D-38)

Every item probed and reported as observed, never asserted from the runbook's expectation alone. All are expected consequences of the `hyprland.conf` rename, not breakage.

**Lost with the renamed conf** — these were `exec-once` lines inside the personal `hyprland.conf`, which is now `hyprland.conf.old`:

| Item | Status |
|---|---|
| `wl-clip-persist` | Confirmed not running |
| `btop` (workspace-pinned autostart) | Confirmed not running |
| `vesktop` (workspace-pinned autostart) | Confirmed not running |
| `discord` (workspace-pinned autostart) | Confirmed not running |
| `google-chrome-stable` on workspace 1 (workspace-pinned autostart) | Confirmed — the archived conf's four pinned autostarts all went with the rename |
| `hyprland-session.service` autostart | Confirmed gone (see the note below) |

**Not deletions, despite appearances:**

- **The personal session unit file survives.** `stow/systemd/.config/systemd/user/hyprland-session.service` is still in the repo. Only its autostart is gone, because the line that started it lived in the renamed conf. Read this as an unstarted unit, not a removed one.
- **`hyprpaper` is stopped-but-installed.** The binary is on PATH and `hyprpaper.conf` survives; nothing starts it. Wallpaper is Quickshell's job now. `PROTECT_EXPLICIT` did its work — the package was not swept up by orphan cleanup, and the transcript's closing `[PROTECT] All protect-list packages are now explicit; orphan cleanup will not remove them.` records that.
- **`hyprland/scripts/launch_first_available.sh` was overwritten, not deleted.** 165 bytes live (upstream's) versus 353 bytes in the repo (the personal one). **RESEARCH Pitfall 7 is wrong in the record** — it predicts a deletion. The personal version is tracked at repo `.config/hypr/hyprland/scripts/launch_first_available.sh` and is recoverable from there.
- **`starship.toml` was overwritten, and that is D-17 working as designed.** `~/.config/starship.toml` is a stow symlink into `stow/zsh/.config/starship.toml`, so upstream's `cp_file dots/.config/starship.toml /home/pera/.config/starship.toml` wrote straight through it into the repo working tree — 82 insertions, 272 deletions. `starship.toml` was deliberately left out of `PROTECT_EXPLICIT`, so the adopt was expected to take it and it did. Committed as an accepted loss in `2539238`. **The personal configuration is recoverable from `git show 96ea7e8:stow/zsh/.config/starship.toml`**, verified byte-identical to the pre-overwrite copy before that commit was made. See the finding below on why the backup directory is *not* a second source for it.
- **`kitty.conf` was restored by re-stow.** The symlink `~/.config/kitty/kitty.conf -> ../../github_repo/.dotfiles/stow/kitty/.config/kitty/kitty.conf` is in place. Upstream's displaced file sits alongside at `~/.config/kitty/kitty.conf.upstream`, and the two upstream kittens `scroll_mark.py` and `search.py` remain inert beside it, as runbook section 9 predicted.

## Findings (D-14, D-38)

None of these block the phase. D-32's bar is a usable ii desktop with the overlay applied and findings logged, and that bar is met.

**1. `graphical-session.target` is inactive** — the only `[FINDING]` the script emitted.
- *Observed:* `systemctl --user is-active graphical-session.target` reports inactive. The personal session unit's autostart died with the renamed conf.
- *Blocks?* No. Screen share was expected to be the casualty and it **works** — the ScreenCast portal reads `u 7`, unchanged from pre-adopt. The practical impact is narrower than the runbook anticipated.
- *Next:* Phase 15. The unit file survives at `stow/systemd/.config/systemd/user/hyprland-session.service`; re-establishing its start is a Lua-side decision about where `exec-once` equivalents now live.

**2. The backup directory is not a recovery source for stow-managed files.** Discovered while verifying the starship.toml loss; not previously recorded.
- *Observed:* upstream backs up with `rsync -av`, without `-L`. Eight entries under `~/ii-original-dots-backup` are therefore **preserved symlinks**, not content — including `.config/starship.toml` and `.config/kitty/kitty.conf`, both of which point back into this repo. `~/ii-original-dots-backup/.config/starship.toml` now resolves to the *overwritten* repo file, so it holds none of the original.
- *Blocks?* No, and it does not weaken ADOPT-04. Tier 1 is asserted specifically on `hyprland.conf`, which is a real file in the backup (15301 bytes, sha verified). The gap is confined to files that were symlinks in `~/.config` to begin with.
- *Next:* record the correct rule — for anything stow manages, git history is the recovery source and the backup directory is not. The personal `starship.toml` has exactly one source: `96ea7e8:stow/zsh/.config/starship.toml`.

**3. Verify-script defect: a pass reported for a condition it could not observe (fixed in `9cb41c5`).**
- *Observed:* the first post-adopt run reported `FAIL=14`. Thirteen were fabricated. `hyprctl` resolves its socket from `$HYPRLAND_INSTANCE_SIGNATURE`, and the shell running the verify predated the operator's re-login, so it still carried the dead session's signature. `hyprctl` writes its `Couldn't connect to …/.socket.sock. (4)` refusal to **stdout**, exactly where the script looked for an answer. That produced both halves of the same rule violation at once: a `[PASS] ADOPT-02 hyprctl eval accepted, returned: Couldn't connect to …` — a connection error quoted as its own evidence — and eleven workspace-rule lines plus two monitor lines claiming "overlay did not load", which asserts an unobservable condition as a specific defect. The plan's binding rule is that verification must not report a pass for a condition it could not observe; reporting it as a defect is the same violation in the other direction. The earlier `u 0` ScreenCast reading came from the same dead socket.
- *Blocks?* No — it was a defect in the instrument, not in the adopt. Every underlying condition was already green once probed against the live compositor.
- *Fix:* the script now resolves the live instance from `hyprctl instances`, which enumerates the socket directory instead of reading the env var, and re-exports the signature for its own process. A stale inherited signature is named explicitly in the output, since that is the diagnostic the next operator needs. When no instance is live, one hard failure says the compositor is unreachable and names which assertions could not be observed; those then report `[INFO] NOT OBSERVED`. `hyprctl eval` asserts the expected return value `ok`. A `hypr_json` helper gates every JSON-backed probe on the payload actually parsing, because non-empty stdout was never evidence of success. Verified three ways: a normal run, a run with a deliberately stale signature, and a run against a test double whose socket refuses while `instances` reports live.
- *Lesson for the record:* a verification script that reads its environment to find its target must prove the target is live before it may interpret silence as absence.

**4. Record corrections carried forward.** Four artifacts are wrong in the record and should not be trusted as written by later phases:
- *Runbook section 9's `stow -R kitty` from the repo root fails.* There is no `kitty` package at the repo root — packages live under `stow/`, and `arch/kitty.sh:10` uses `cd "$(dirname …)/../stow" && stow -v=5 -t ~ kitty`. It also aborts on the pre-existing real `~/.config/kitty/kitty.conf`. The operator ran the corrected form; the symlink is in place and the displaced file is at `~/.config/kitty/kitty.conf.upstream`.
- *Runbook section 8's heredoc is unusable as printed.* Its `SH` terminator is indented, and a plain `<<` heredoc requires the terminator at column 0, so pasting it hangs the shell at `heredoc>`. The operator ran the three named `cp -a` calls directly — same three files, same order, no delete-sync, `keybinds.lua`/`rules.lua`/`variables.lua` untouched. Verified: live and repo copies of `general.lua`, `env.lua` and `execs.lua` are byte-identical.
- *RESEARCH Pitfall 7 predicts `launch_first_available.sh` deleted.* It was overwritten. See Known losses.
- *RESEARCH Pitfall 3 predicts HDMI-A-2 absent.* It is attached. See ADOPT-03 result.

## Transcript excerpts (D-11, D-19)

`14-ADOPT-TRANSCRIPT.txt` is committed alongside this record, raw. It is 1.8 MB of `script(1)` output carrying per-character terminal escapes; the excerpts below are de-escaped for reading, and the raw file is what is committed.

**Scope, stated honestly.** The recording covers the `install --full` run only — `Script started on 2026-09-04 23:13:41+06:00` through the shell prompt at `11:35:01 PM`, 21m 8s. Runbook sections 8 and 9 (the overlay apply and the kitty re-stow) were performed **after** it closed and are therefore **not** in the transcript. They are attested instead by disk and compositor evidence in this record: the byte-identical overlay files, the eleven live workspace rules, and the kitty symlink.

**The go decision (D-19)** — the wrapper's exact-token gate, answered at 23:13:41:

```
[CONFIG] FULL PROFILE: no SAFE_DEFAULTS residual injection on this path.
[CONFIG] FULL PROFILE: personal hyprland.conf may be renamed to .old by upstream install.
[CONFIG] FULL PROFILE: sysupdate / pacman -Syu may run on the deps portion of install.
[CONFIG] FULL PROFILE: upstream may backup clashing paths to: ~/ii-original-dots-backup
[CONFIG] FULL PROFILE: bare skip-backup is still refused without dual-key allow override.
[CONFIG] Do NOT pass bare skip-backup on first adoption.
[CONFIG] Type 'yes' to continue (exact token required).
Type 'yes' to continue: yes
[CONFIG] full profile: no SAFE_DEFAULTS injection (DISP-02 drop-all-three)
[INSTALL] ./setup install  (cwd=/home/pera/github_repo/.dotfiles/vendor/dots-hyprland)
```

**D-22 compliance.** Fifty-nine prompts were answered across the run, every one of them `y`. `yesforall` appears only in upstream's menu text and was never typed. No `s` (skip), no `e` (exit), no `-f`/`--force`, no `--skip-backup`, no `-F`/`--firstrun`, no `--skip-hyprland-entry`.

**The backup confirmation:**

```
Would you like to backup clashing dirs/files to "/home/pera/ii-original-dots-backup"?
  y = Yes, backup
  n/s = No, skip to next
====> y
OK, doing backup...
[./setup]: Command "mkdir -p /home/pera/ii-original-dots-backup/.config" finished.
...
Backup into "/home/pera/ii-original-dots-backup" finished.
```

**The `hyprland.conf` rename echo** — upstream naming the ADOPT-02 mechanism in its own words, immediately followed by the not-firstrun branch that D-37 depends on:

```
[./setup]: Command "rsync_dir__sync dots/.config/hypr/hyprland /home/pera/.config/hypr/hyprland" finished.
hyprland.conf has been renamed to hyprland.conf.old. This is to allow the new lua config to load.
[./setup]: "/home/pera/.config/hypr/hyprlock.conf" already exists.
[./setup]: It seems not a firstrun.
[./setup]: Next command:
cp_file dots/.config/hypr/hyprlock.conf /home/pera/.config/hypr/hyprlock.conf.new
```

**The `starship.toml` overwrite** — the accepted D-17 loss, recorded as it happened:

```
[./setup]: Found target: dots/.config/starship.toml
The command below overwrites the destination.
[./setup]: Next command:
cp_file dots/.config/starship.toml /home/pera/.config/starship.toml
====> y
```

**Failures and re-runs: none.** The install completed in a single pass; there was no re-run. One block of output reads alarming and is not. `remove_deprecated_dependencies` emitted seventeen `error: target not found:` lines — `illogical-impulse-microtex`, `quickshell-git`, `hyprland-git`, `matugen-bin` and others — because it attempts to remove packages that were never installed on this machine. That is the expected no-op, and the step reported `[./setup]: Command "remove_deprecated_dependencies" finished.` Do not read those lines as breakage.

**The clean finish:**

```
[PROTECT] All protect-list packages are now explicit; orphan cleanup will not remove them.
[INSTALL] ii hooks already active:
[INSTALL]   /home/pera/github_repo/.dotfiles/.config/hypr/hyprland.conf
```

**Pre-commit review.** The transcript was read for secrets before staging. It contains one `[sudo] password for pera:` prompt and no password — the recording was made output-only, as D-22 requires, so `--log-in`/`--log-io` never captured keystrokes. No tokens, API keys, or private key material of any shape. The only host paths are under `/home/pera`, which the planning artifacts already carry throughout.
