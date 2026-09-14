# Phase 21: ii bar config capture - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-15
**Phase:** 21-ii bar config capture
**Areas discussed:** JSON validation in capture, Systemd timer cadence, Bar settings baseline, Live wallpaper verification drill

---

## JSON Validation in capture

### Q1: JSON Detection and Validation
| Option | Description | Selected |
|--------|-------------|----------|
| Validate by file extension (*.json) via jq empty | Fast, fail-closed, standard on Arch/ii systems | ✓ |
| Validate with fallback to python3 -m json.tool | Fallback when jq is missing | |
| Content-sniffing / per-path configuration | Check all files regardless of extension | |

**User's choice:** Validate by file extension (*.json) using `jq empty "$live"` — fast, fail-closed, standard on Arch/ii systems.

### Q2: Validation Failure Handling
| Option | Description | Selected |
|--------|-------------|----------|
| Emit [FINDING] / [FAIL] and skip file | Keep repo mirror intact while allowing other clean files to capture, exit non-zero at end | ✓ |
| Abort entire capture run immediately | Exit 1 on first corrupt file | |
| You decide | Error reporting style consistent with D-36 and D-43 | |

**User's choice:** Emit `[FINDING]` / `[FAIL]`, skip copying that file, and exit non-zero at the end — keeps repo copy intact while allowing other clean files to capture.

### Q3: File Byte Formatting / Canonicalization
| Option | Description | Selected |
|--------|-------------|----------|
| Preserve raw bytes via cp -p | Avoids synthetic diff churn with Quickshell's 4-space internal serializer | ✓ |
| Reformat with jq into 2-space indentation | Canonical formatting | |
| You decide | Follow Phase 18 pattern | |

**User's choice:** Preserve exact raw bytes via `cp -p` — avoids synthetic diff churn with Quickshell's internal serializer (4-space indentation).

### Q4: 0-Byte and Empty JSON Handling
| Option | Description | Selected |
|--------|-------------|----------|
| Fail closed on 0-byte or empty JSON | Log [FAIL] and skip capture to protect against truncate-in-progress races | ✓ |
| Allow empty files without validation | Treat 0-byte files as valid | |
| You decide | Standard fail-closed treatment | |

**User's choice:** Fail closed: treat 0-byte or empty JSON files as invalid, log `[FAIL]` and skip capture — protects repo against truncate-in-progress races.

### Q5: Validation Depth
| Option | Description | Selected |
|--------|-------------|----------|
| Syntax-only validation (jq empty) | Format-generic, applies cleanly to any future JSON in capture/ without hardcoded schemas | ✓ |
| Syntax plus top-level key check | Require specific keys like `has("bar")` | |
| You decide | Generic syntax with object root check | |

**User's choice:** Syntax-only validation (`jq empty`) — format-generic, applies cleanly to any future JSON file in capture/ without hardcoded schemas.

### Q6: Write Atomicity
| Option | Description | Selected |
|--------|-------------|----------|
| Atomic replace via temp file | `cp -p` to temp file then `mv` prevents partial files in git tree if interrupted | ✓ |
| Direct copy | `cp -p` directly over repo file | |
| You decide | Atomic replace with trap cleanup | |

**User's choice:** Atomic replace: `cp -p -- "$live" "$repo_file.tmp.$$" && mv -f "$repo_file.tmp.$$" "$repo_file"` — prevents half-written files in git working tree if interrupted.

### Q7: Check Pipeline Position
| Option | Description | Selected |
|--------|-------------|----------|
| Validate right before copy | Check repo clean status and live existence first; skip validation if dirty or missing | ✓ |
| Validate live file first | Validate before checking repo mirror status | |
| You decide | Place validation after eligibility checks | |

**User's choice:** Validate right before copy, after checking repo clean status and live file existence — avoids unnecessary validation when repo mirror is dirty or live file missing.

### Q8: Verify Command Role
| Option | Description | Selected |
|--------|-------------|----------|
| Keep verify content-diff focused | Syntax validation is an ingest gate in run_capture; verify remains uniform across all trees | ✓ |
| Syntax-aware verify | Check syntax inside verify before diffing | |
| You decide | Follow Phase 19 VER-02 diff-only contract | |

**User's choice:** Keep verify content-diff focused — syntax validation is an ingest gate in `run_capture`, verify remains uniform across all file types.

---

## Systemd timer cadence

### Q1: Execution Interval
| Option | Description | Selected |
|--------|-------------|----------|
| Every 15 minutes | Responsive capture with negligible overhead | ✓ |
| Every 30 minutes | Balanced cadence | |
| Every 5 minutes | Near-instant capture | |

**User's choice:** 15 minutes for now (`OnUnitActiveSec=15m`, `OnBootSec=2m`, `Persistent=true`).
**Notes:** User inquired about the necessity of the timer; clarified that `config.json` is a plain file (not a symlink) due to `switchwall.sh` atomic renames, so automated synchronization into git requires a background timer.

### Q2: ExecStart Command
| Option | Description | Selected |
|--------|-------------|----------|
| Direct user-relative path | `%h/github_repo/.dotfiles/arch/dots-hyprland.sh capture` with WorkingDirectory | ✓ |
| Helper script in PATH | Symlink to ~/.local/bin/dots-hyprland | |
| You decide | Use %h-based path | |

**User's choice:** Directly execute `%h/github_repo/.dotfiles/arch/dots-hyprland.sh capture` with `WorkingDirectory=%h/github_repo/.dotfiles` — clean, no extra wrapper scripts needed.

### Q3: Priority and Logging
| Option | Description | Selected |
|--------|-------------|----------|
| Low priority (Nice=19) + journal | Silent in background, inspectable via journalctl | ✓ |
| Default priority + journal | Standard priority | |
| You decide | Low-overhead service directives | |

**User's choice:** Low priority (`Nice=19`) with `StandardOutput=journal` and `SyslogIdentifier=dotfiles-capture` — silent in background, easy to inspect via journalctl.

### Q4: Exit Status Handling
| Option | Description | Selected |
|--------|-------------|----------|
| SuccessExitStatus=0 1 | Treats skipped dirty mirrors or validation findings as clean in systemd status | ✓ |
| Strict status (no override) | Mark failed in systemctl when files are skipped | |
| You decide | Allow exit 1 as expected non-error state | |

**User's choice:** Include `SuccessExitStatus=0 1` — treats skips (dirty mirror or validation failure) as clean runs in systemd status while logging findings to journalctl.

### Q5: Enablement Wiring
| Option | Description | Selected |
|--------|-------------|----------|
| Wire into arch/hyprland.sh | Alongside existing `stow systemd` block | ✓ |
| Dedicated installer step | Separate setup command | |
| You decide | Wire into arch/hyprland.sh | |

**User's choice:** Wire into `arch/hyprland.sh` alongside the existing `stow systemd` block (`systemctl --user enable --now dotfiles-capture.timer`).

### Q6: Target & Triggers
| Option | Description | Selected |
|--------|-------------|----------|
| WantedBy=timers.target with OnStartupSec=2m | Standard practice, catches up missed runs | ✓ |
| WantedBy=graphical-session.target | Only active during graphical session | |
| You decide | Standard timers.target | |

**User's choice:** `WantedBy=timers.target` with `OnStartupSec=2m`, `OnUnitActiveSec=15m`, and `Persistent=true` — standard systemd practice, catches up missed runs after sleep/reboot.

### Q7: Change Detection Optimization
| Option | Description | Selected |
|--------|-------------|----------|
| Only copy and log when changed | Check `! cmp -s` before copying and logging; avoid disk writes when idle | ✓ |
| Always copy on every interval | Unconditional copy | |
| You decide | Optimize with cmp check | |

**User's choice:** Only copy and log when content actually changes (`! cmp -s "$live" "$repo_file"`) — avoids unnecessary disk writes and keeps journal clean when idle.

### Q8: Quiet Flag Support
| Option | Description | Selected |
|--------|-------------|----------|
| Support --quiet in run_capture | Use in service for silent background runs | ✓ |
| Standard logging without --quiet | Log everything to journal | |
| You decide | Add --quiet flag | |

**User's choice:** Support `--quiet` in `run_capture` and use it in `dotfiles-capture.service` — timer output is logged only when changes are captured, dirty mirrors are skipped, or errors occur.

### Q9: Assert Verification Strategy
| Option | Description | Selected |
|--------|-------------|----------|
| Inspect state + manual trigger | Check is-active/is-enabled, trigger via `systemctl --user start`, verify git status | ✓ |
| Temporarily shorten timer interval | Set to 5s in test | |
| You decide | Use systemctl start + schedule inspection | |

**User's choice:** Verify timer state via `systemctl --user is-active/is-enabled`, trigger a test run with `systemctl --user start dotfiles-capture.service`, and verify journal/git status immediately.

### Q10: Desktop Notification Policy
| Option | Description | Selected |
|--------|-------------|----------|
| Desktop notification on captured changes | Notify with low urgency when changes are synced | ✓ |
| Silent execution | No desktop notifications | |
| You decide | Silent by default, optional flag | |

**User's choice:** Desktop notification on captured changes — notify with low urgency (`notify-send -u low`) when changes are synced to repo mirror.

### Q11: Notification Trigger Condition
| Option | Description | Selected |
|--------|-------------|----------|
| Only notify on active captures | Low urgency when files copied; silent during no-op idle checks | ✓ |
| Notify on captures and errors | Popups on both | |
| You decide | Notify on successful capture only | |

**User's choice:** Only notify on active captures — low urgency when files are copied; stay silent during no-op idle checks.

### Q12: Notification Styling and Dispatch
| Option | Description | Selected |
|--------|-------------|----------|
| Use dots-hyprland notification | `notify-send "Title" "Body" -a "Shell" -u low` | ✓ |

**User's choice:** use dots-hyprland notification.

### Q13: Manual CLI vs Background Timer Notifications
| Option | Description | Selected |
|--------|-------------|----------|
| Add --notify flag to capture | Service runs with `--quiet --notify`; manual CLI outputs to terminal only | ✓ |
| Always notify on capture | Notify in both | |
| You decide | Use --notify flag | |

**User's choice:** Add `--notify` flag to `capture`: systemd service runs with `--quiet --notify` (notifying on desktop), while manual CLI runs output to terminal only.

### Q14: Service Timeout
| Option | Description | Selected |
|--------|-------------|----------|
| TimeoutStartSec=30s | Bounds execution time safely so capture cannot hang indefinitely | ✓ |
| Systemd default (90s) | Default timeout | |
| You decide | Standard 30s | |

**User's choice:** Add `TimeoutStartSec=30s` — bounds execution time safely so background capture cannot hang indefinitely.

### Q15: Stow Layout Location
| Option | Description | Selected |
|--------|-------------|----------|
| stow/systemd/.config/systemd/user/ | Single source of truth in stow tree | ✓ |
| Dedicated scripts directory | Authored outside stow | |
| You decide | Follow stow convention | |

**User's choice:** `stow/systemd/.config/systemd/user/` is the single source of truth — authored in repo, symlinked to $HOME via existing stow systemd flow.

### Q16: Reload on Unit Update
| Option | Description | Selected |
|--------|-------------|----------|
| daemon-reload + enable --now + restart | Immediate application without session restart | ✓ |
| daemon-reload only | Leave running timer alone | |
| You decide | Ensure timer is active | |

**User's choice:** Run `systemctl --user daemon-reload && systemctl --user enable --now dotfiles-capture.timer && systemctl --user restart dotfiles-capture.timer` — immediate application of changes without session restart.

---

## Bar settings baseline

### Q1: Baseline Adoption
| Option | Description | Selected |
|--------|-------------|----------|
| Adopt current live config.json | Captures current setup (top bar, Dhaka weather, 5 workspaces, spark icon, util toggles) | ✓ |
| Review and customize settings | Edit before capture | |
| You decide | Capture live as baseline | |

**User's choice:** Adopt current live `config.json` as the initial baseline — captures your current setup (top bar, Dhaka weather, 5 workspaces, spark icon, mic/snip buttons).

### Q2: Capture Repository Directory Structure
| Option | Description | Selected |
|--------|-------------|----------|
| Stow-style package tree | `capture/ii/.config/illogical-impulse/config.json` matches Phase 18 D-38 contract | ✓ |
| Flattened path `capture/ii/config.json` | Requires changing run_capture parser | |
| You decide | Follow Phase 18 stow-style relative tree contract | |

**User's choice:** Stow-style package tree: `capture/ii/.config/illogical-impulse/config.json` — strictly matches Phase 18 D-38 layout contract (`capture/<pkg>/<rel_to_home>`).

### Q3: Tracked Files in capture/ii/
| Option | Description | Selected |
|--------|-------------|----------|
| Track only config.json | Excludes installer state files (`installed_listfile`, `installed_true`) and transient caches | ✓ |
| Track state files together | Track all files in folder | |
| You decide | Only track config.json per BAR-01 and BAR-02 | |

**User's choice:** Track only `.config/illogical-impulse/config.json` — excludes installer state files (`installed_listfile`, `installed_true`) and transient caches from git.

### Q4: Defaults-Reset Drill Procedure
| Option | Description | Selected |
|--------|-------------|----------|
| Safe live drill with timestamped backup | Backup first (`config.json.bak.<epoch>`), reset live to defaults, restore from repo, reload qs, verify | ✓ |
| Simulated scratch restore | Scratch dir only | |
| You decide | Follow SAFE-01 precedent | |

**User's choice:** Safe live drill: timestamped backup first (`config.json.bak.<epoch>`), reset live file to defaults, restore from repo `capture/ii/`, reload `qs -c ii`, and verify bar settings match exactly.

---

## Live wallpaper verification drill

### Q1: Scratch XDG Harness
| Option | Description | Selected |
|--------|-------------|----------|
| Automated scratch harness | Mock XDG env in tempdir, symlink, run switchwall logic to prove link destruction, test capture | ✓ |
| Run directly on desktop | No scratch isolation | |
| You decide | Two-stage plan | |

**User's choice:** Automated scratch harness — create mock XDG environment in temporary directory, create symlink, run `switchwall.sh` logic to prove link destruction, and confirm `capture` ingests the plain file.

### Q2: Production Session Wallpaper Drill
| Option | Description | Selected |
|--------|-------------|----------|
| Non-disruptive live drill | Require clean tree, trigger with current wallpaper (`55192173787_b8322b1190_o.jpg`), verify, revert via git checkout | ✓ |
| Switch to alternate wallpaper | Visual change | |
| You decide | Clean tree + current wallpaper | |

**User's choice:** Non-disruptive live drill — require clean working tree, trigger `switchwall.sh` with current wallpaper (`55192173787_b8322b1190_o.jpg`), verify plain file + `capture` sync, and revert any git churn via `git checkout`.

### Q3: Generated Theme Churn Recording
| Option | Description | Selected |
|--------|-------------|----------|
| Log generated theme modifications | Record empirical evidence for Phase 22 (Q7/Q8) in verification notes before checkout | ✓ |
| Revert immediately | No logging | |
| You decide | Record generated file churn | |

**User's choice:** Log generated theme file modifications in phase verification notes before reverting — records empirical evidence for Phase 22 (Q7/Q8).

### Q4: Assert Script Structure
| Option | Description | Selected |
|--------|-------------|----------|
| Single comprehensive assert script | `scripts/phase21-ii-bar-config-capture-assert.sh` covering validation, timer, capture, verify, and scratch drill | ✓ |
| Split unit and live smoke scripts | Two separate scripts | |
| You decide | Single assert script with strict exit gates | |

**User's choice:** Single comprehensive assert script `scripts/phase21-ii-bar-config-capture-assert.sh` covering JSON validation, timer status, capture execution, verify pass, and scratch switchwall drill.

---

## Claude's Discretion

- Exact temporary filename generation (`mktemp` / `tmp.$$`) and signal trap cleanup implementation in `run_capture`.
- Specific assertion helper functions and error formatting in `scripts/phase21-ii-bar-config-capture-assert.sh`.

## Deferred Ideas

- Phase 22: KDE and GTK capture (`kdeglobals`, `dolphinrc`, `gtk-3.0/settings.ini`).
- Phase 23: One-command full bootstrap orchestration (`BOOT-01`–`BOOT-05`).
