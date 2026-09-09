---
phase: "14"
slug: "live-full-adopt-verify"
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
created: "2026-09-05"
---

# Phase 14 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

Register reconstructed from the `<threat_model>` blocks authored at plan time in `14-01-PLAN.md`
and `14-02-PLAN.md`, deduplicated by threat id (T-14-01, T-14-04 and T-14-10 appear in both plans;
the merged row carries both mitigations). Both `## Threat Flags` sections report no new trust-boundary
surface introduced during execution.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| repo artifact → operator at a bare TTY | The runbook is executable instruction with no interactive review; a wrong or ambiguous line becomes a wrong command on a live machine | Operator instructions, command lines, go/no-go criteria |
| agent → live `$HOME` | Prep ran as the operator's own user with full write access to `~/.config` and `~/ii-original-dots-backup` | Config files, the backup directory |
| live `$HOME` → public git repo | The D-07 archive moved live config files, two of them originally mode 0600, into a public repository | Hyprland configs, `dolphinrc`, `kdeglobals` |
| repo wrapper → upstream `./setup` | `arch/dots-hyprland.sh` composes flags around third-party install logic pinned at a submodule SHA | Flag surface, install decisions |
| operator → live system | The mutating install crosses here; it is the only mutation in the phase and no agent invocation performed it | Whole `~/.config` tree, system packages |
| live session → verify script | `hyprctl`, `busctl`, `pgrep` and `systemctl --user` read a running compositor and session bus; the script must not write back | Compositor state, session-bus replies |
| live session output → public git repo | The `script(1)` transcript captured a `sudo pacman` run and every prompt of a third-party installer | Terminal output, package names, prompt text |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-14-01 | Tampering | Agent-runnable artifacts (`scripts/phase14-preflight.sh`, `scripts/phase14-verify.sh`, both plans) | critical | mitigate | Every wrapper invocation in an executable artifact carries `--dry-run`. Preflight: `install --full` count equals `install --full --dry-run` count with comment lines filtered. Verify: the only two `$WRAP` calls are `uninstall --dry-run` (line 380) and `protect --dry-run` (line 386). The mutating form exists solely as operator prose in the runbook and in a `blocking-human` checkpoint | closed |
| T-14-02 | Denial of service | `scripts/phase14-preflight.sh` backup rotation | high | mitigate | `rotate_backup()` defined once (line 76), one call site (line 316) guarded by `[[ "$ROTATE" -eq 1 ]]` and placed after every check and after the `=== done: ===` line. `grep -cE 'rm -rf\|rsync .*--delete'` on the script is 0. A default-path run left `~/ii-original-dots-backup` mtime unchanged at `1788543226` | closed |
| T-14-03 | Denial of service | `docs/phase14-adopt-runbook.md` rollback section | high | mitigate | Runbook names `uninstall --configs-only`; a file-wide negative grep for `(\./)?setup uninstall` returns nothing. All three tiers are wrapper-owned | closed |
| T-14-04 | Tampering | Upstream `./setup` flag surface, and its firstrun branch replacing `hyprlock.conf` / `hypridle.conf` | high | mitigate | Runbook names all four banned flags (`--force`, `--skip-backup`, `--firstrun`, `--skip-hyprland-entry`) plus the `yesforall` token (2 occurrences). Mechanical half: the D-37 block in `scripts/phase14-verify.sh` (10 references) compares byte size and sha256 against the pre-adopt fixture and asserts unpromoted `.new` sidecars — a hard failure, not a finding. Live run: both files byte-identical, both sidecars unpromoted | closed |
| T-14-05 | Information disclosure | `14-ADOPT-TRANSCRIPT.txt` | high | mitigate | The runbook bans `--log-in` and `--log-io` explicitly at line 64 with the reason stated (those modes record terminal input, so a sudo password would land in a committed file). Post-hoc scan of the committed transcript for `password\|token\|api[_-]?key\|BEGIN .*PRIVATE KEY` returns 5 matches, all benign: the exact-token gate prompt, a bare `[sudo] password for pera:` prompt with no value echoed, and three upstream Quickshell filenames. No secret material present | closed |
| T-14-06 | Information disclosure | `.config/hypr/hyprland.conf.bak`, `.config/hypr/hyprland-gui.conf` (originally mode 0600) | medium | mitigate | Both files were read in full before staging. Post-hoc scan for credential, token, key, email-domain and IPv4 patterns returns 0 matches on both. `hyprland-gui.conf` is 80 bytes of HyprMod-generated border colours | closed |
| T-14-07 | Denial of service | D-07 live-to-repo sync | high | mitigate | Sync used `cp -a` over five literal paths; no `rsync`, no `--delete`, no glob, no computed path in a delete position. `git diff --name-only HEAD~1 -- .config/hypr/custom` is empty and `./scripts/phase13-d19-assert.sh` exits 0 | closed |
| T-14-08 | Denial of service | Silently skipped upstream backup (`ask=false` via greeting `n`, `--force`, or `yesforall`) | high | mitigate | The D-36 block in `scripts/phase14-verify.sh` (9 references) asserts the backup copy of `hyprland.conf` exists, matches the recorded pre-adopt sha256 `3d17932a…89b5`, and carries mtime `1786770136`, newer than the recorded pre-install `1784818728`. All three are hard failures and all three passed | closed |
| T-14-09 | Elevation of privilege | `sudo pacman` inside the adopt window | medium | accept | See Accepted Risks Log R-14-01 | closed |
| T-14-10 | Spoofing | Upstream package set | medium | transfer | Package selection is upstream's, pinned at `vendor/dots-hyprland` SHA `1a9ffb78f0c272a45f82342587dc3bec72762233` (confirmed clean by `git submodule status`, `2026.05.11-109-g1a9ffb78`). No package is chosen by this phase, so no legitimacy audit applies | closed |
| T-14-12 | Tampering | `PROTECT_EXPLICIT` cascade-protection list | medium | mitigate | Exactly two anchored array lines removed. `waybar` and `swaync` each match 0 times; `hyprpaper` and `kitty` each match exactly once, catching an over-broad deletion. `./scripts/phase12-full-smoke.sh` reports `FAIL=0` | closed |
| T-14-13 | Information disclosure | `.gitignore` change | low | accept | See Accepted Risks Log R-14-02 | closed |
| T-14-14 | Tampering | Verify script mutating its own subject to green a check | high | mitigate | `grep -cE 'pkill\|hyprctl reload\|hyprctl keyword\|rm -rf\|rsync .*--delete'` on `scripts/phase14-verify.sh` is 0, and the header carries an explicit read-only constraint line | closed |
| T-14-15 | Repudiation | The go decision, and what actually happened during a run no agent performed | medium | mitigate | The decision was spoken into the `script(1)` transcript, which is committed at `8b8ba4b`, and `14-LIVE-VERIFY.md` quotes the load-bearing excerpts (the exact-token gate answered `yes` at 23:13:41; 59 prompts each answered `y`; `yesforall` never typed) | closed |
| T-14-16 | Spoofing | A verify pass reflecting a stale or unobservable condition rather than a real one | high | mitigate | The config-provider check asserts the absence of the observed pre-adopt token rather than the presence of a guessed post-adopt one, paired with an independent `hyprctl eval 'return 1+1'` probe (11 references in the script). Unobservable conditions emit `[INFO]` or `[FINDING]`, never `[PASS]` — the rofi process probe and the D-38 portal probe both do exactly this in the live run | closed |
| T-14-17 | Denial of service | Rollback tiers 2 and 3 unreachable when needed | medium | mitigate | `scripts/phase14-verify.sh` runs `uninstall --dry-run` and `protect --dry-run` and fails on a non-zero exit (6 references). Both exit 0 in the live run, so reachability is proven while the desktop still works | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above `workflow.security_block_on` (high) count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| R-14-01 | T-14-09 | The install requires root for package operations. Scope is the operator's own machine, the command set is upstream's pinned at submodule SHA `1a9ffb78…`, and no elevated command is issued by this phase's own artifacts | Operator | 2026-09-04 |
| R-14-02 | T-14-13 | Adding `.gsd/` to `.gitignore` hides agent scratch state from git rather than exposing anything. The residual risk is only that a wanted file is later ignored, which stays visible via `git status --ignored` | Operator | 2026-09-04 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-09-05 | 16 | 16 | 0 | verify:post security step (orchestrator, ASVS L1) |

**Method.** ASVS level 1, so verification ran at grep depth against the implementation and the live
post-adopt evidence, per the workflow's L1 short-circuit. `gsd-security-auditor` was not spawned:
the register was authored at plan time in both PLAN files, `asvs_level` is 1, and preliminary
classification closed every threat, which is exactly the condition the short-circuit rule covers.
Raise `workflow.security_asvs_level` to 2 or 3 to force auditor dispatch with boundary-placement
and end-to-end trace checks.

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-09-05
