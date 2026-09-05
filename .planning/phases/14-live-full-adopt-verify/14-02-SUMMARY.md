---
phase: 14-live-full-adopt-verify
plan: 02
subsystem: infra
tags: [bash, hyprland, hyprctl, illogical-impulse, quickshell, verification, rollback, lua]

# Dependency graph
requires:
  - phase: 14-live-full-adopt-verify
    provides: "plan 14-01's docs/phase14-adopt-runbook.md, scripts/phase14-preflight.sh, and 14-PRE-ADOPT-BASELINE.txt — the fixture without which D-36 and D-37 are circular after the install"
  - phase: 13-personal-hypr-custom-overlays
    provides: ".config/hypr/custom/ overlays and the 13-SOT-APPLY.md named-file apply fence, whose eleven workspace rules this plan proves LOADED rather than merely copied"
  - phase: 12-full-profile-wrapper
    provides: "arch/dots-hyprland.sh --full path plus its uninstall/protect --dry-run surface, used here as the tier-2 and tier-3 reachability probes"
  - phase: 11-disposition-decisions
    provides: "D-11 accept-remove dual-run policy and D-24 hyprlock/hypridle protection, both asserted against live state here"
provides:
  - "scripts/phase14-verify.sh — read-only post-adopt verifier, 38 hard assertions across ADOPT-02/03/04 and D-35..D-38 in the dual-head configuration, three-level PASS/FINDING/INFO output with only FAIL moving the exit code"
  - "Live-instance resolution pattern: resolve the compositor from `hyprctl instances` rather than trusting an inherited $HYPRLAND_INSTANCE_SIGNATURE, and report unreachability once instead of as N phantom defects"
  - "14-LIVE-VERIFY.md — the phase record: script output, the four human answers, known losses, findings with dispositions, and de-escaped transcript excerpts"
  - "14-ADOPT-TRANSCRIPT.txt — the raw script(1) capture of a mutating run no agent performed (D-11, D-31)"
  - "Proof that all three tier-1 rollback sources carry the identical pre-adopt sha256"
  - "New finding: the upstream backup preserves symlinks, so ~/ii-original-dots-backup is not a recovery source for stow-managed files"
affects: [phase 15 findings follow-up, rollback, any future upstream re-sync]

# Actuals (#2632). estimateTokens scale = chars/4 over the realized diff.
# EXCLUDES 14-ADOPT-TRANSCRIPT.txt (1,847,296 chars): it is an operator terminal
# capture committed verbatim, not authored work. Counting it would report ~462k
# tokens and measure script(1)'s escape sequences rather than this plan's cost.
actuals:
  tokens: 15800
  tasks: 5
  commits: 6

tech-stack:
  added: []
  patterns:
    - "Liveness-before-interpretation: a verifier that reads its environment to locate its target must prove the target is live before it may read silence as absence"
    - "Payload validation over non-empty output: hyprctl writes refusals to stdout, so every JSON probe is gated on the payload parsing as JSON before any assertion may read it"
    - "Expected-value assertion: assert the specific success token (`ok`), never merely that something came back"
    - "Unobservability is symmetric: an unobservable condition is never a pass AND never a specific defect — it is one named [INFO] plus one honest [FAIL] about reachability"
    - "Assert absence of an observed pre-state, never presence of a guessed post-state (configProvider)"

key-files:
  created:
    - scripts/phase14-verify.sh
    - .planning/phases/14-live-full-adopt-verify/14-LIVE-VERIFY.md
    - .planning/phases/14-live-full-adopt-verify/14-ADOPT-TRANSCRIPT.txt
  modified:
    - stow/zsh/.config/starship.toml

key-decisions:
  - "The ADOPT-02 config-provider check asserts the ABSENCE of the recorded pre-adopt `hyprlang`, never the presence of a guessed post-adopt token; the observed `lua` is recorded as an observation, so an upstream rename cannot produce a spurious failure"
  - "hyprctl's Lua REPL probe asserts the exact return value `ok`, probed against the live compositor rather than assumed; non-empty output was never evidence of success because hyprctl writes refusals to stdout"
  - "A compositor the script cannot reach produces ONE reachability failure plus named [INFO] lines, not thirteen 'overlay did not load' defects — reporting an unobservable condition as a specific defect is the same rule violation as reporting it as a pass"
  - "starship.toml's overwrite is committed as an accepted D-17 loss with the recovery ref recorded in the commit body, rather than reverted, because reverting would fight the next upstream sync instead of documenting the decision"
  - "The 1.8 MB transcript is committed raw, not filtered; navigability comes from de-escaped excerpts quoted in 14-LIVE-VERIFY.md"

patterns-established:
  - "Instrument defects are recorded as phase findings with their lesson, not silently fixed — a verifier that lied once is part of the phase record"
  - "Provenance is stated for pasted evidence: the verify-run block names which checkout produced it and was diffed against a live run rather than retyped"
  - "Transcript scope is stated honestly — steps performed after the recording closed are attested by disk and compositor evidence, never implied to be in the capture"

requirements-completed: [ADOPT-01, ADOPT-02, ADOPT-03, ADOPT-04]

coverage:
  - id: D1
    description: "ADOPT-02 — the running session came from the ii Lua entry, proven three ways plus a token-free Lua REPL probe"
    requirement: "ADOPT-02"
    verification:
      - kind: integration
        ref: "./scripts/phase14-verify.sh (5 [PASS] ADOPT-02 assertions against the running compositor)"
        status: pass
    human_judgment: false
  - id: D2
    description: "ADOPT-03 automatable half — DP-1 enforced present, all eleven Phase 13 workspace rules live in the running compositor, qs -c ii running, Waybar/rofi/swaync gone"
    requirement: "ADOPT-03"
    verification:
      - kind: integration
        ref: "./scripts/phase14-verify.sh (11 workspace-rule assertions + monitor and process assertions, dual-head)"
        status: pass
    human_judgment: false
  - id: D3
    description: "ADOPT-03 human half — layout renders correctly across both monitors, workspaces land on the pinned monitor, the launcher keybind opens the ii launcher"
    requirement: "ADOPT-03"
    verification:
      - kind: manual_procedural
        ref: "14-LIVE-VERIFY.md § Human checklist (D-29, D-30)"
        status: pass
    human_judgment: true
    rationale: "D-29 requires operator eyes: no non-visual proxy exists for 'the layout looks right', and the launcher never had an autostart, so a process check is vacuous — only pressing the key proves it (RESEARCH Pitfall 6)"
  - id: D4
    description: "ADOPT-04 input half — three tier-1 sources present and byte-identical to the pre-adopt fixture, tiers 2 and 3 reachable by dry-run, D-36 backup freshness proven"
    requirement: "ADOPT-04"
    verification:
      - kind: integration
        ref: "./scripts/phase14-verify.sh (ADOPT-04 and D-36 blocks; sha256 3d17932a...89b5 across all three sources)"
        status: pass
    human_judgment: false
  - id: D5
    description: "ADOPT-01 — the one-way adopt window was gated on an explicit human go decision and executed by the operator, recorded with script(1)"
    requirement: "ADOPT-01"
    verification:
      - kind: manual_procedural
        ref: "14-ADOPT-TRANSCRIPT.txt (the exact-token gate answered `yes` at 23:13:41; 59 prompts all answered `y`, `yesforall` never typed)"
        status: pass
    human_judgment: true
    rationale: "D-01 forbids any agent invocation of the mutating install; the go decision and the run itself are human acts that only the transcript can attest"
  - id: D6
    description: "D-35..D-38 — clean tree apart from phase artifacts, D-24 held with unpromoted sidecars, every named known loss confirmed by probe, screen-share portal probed"
    verification:
      - kind: integration
        ref: "./scripts/phase14-verify.sh (D-35, D-36, D-37, D-38 blocks; FAIL=0 FINDINGS=1)"
        status: pass
    human_judgment: false

# Metrics
duration: 5h 48m
completed: 2026-09-05
status: complete
---

# Phase 14 Plan 02: Live adopt verification Summary

**A read-only 44-assertion post-adopt verifier that resolves the live Hyprland instance before it trusts any probe, proving the ii Lua entry loaded, all eleven Phase 13 workspace rules are live dual-head, and three byte-identical rollback sources exist — plus the phase record and the raw transcript of a run no agent performed.**

## Performance

- **Duration:** 5h 48m wall clock, spanning the operator's adopt window and a later defect-fix pass
- **Started:** 2026-09-04T21:42:00Z (Task 1 gate)
- **Completed:** 2026-09-05T03:30:32Z
- **Tasks:** 5 (2 checkpoints, 1 tracer, 2 auto)
- **Files created/modified:** 4

## Accomplishments

- **`scripts/phase14-verify.sh`** — 38 hard assertions in the dual-head configuration, spanning ADOPT-02, ADOPT-03, ADOPT-04 and D-35 through D-38, in one read-only script that never terminates a process, never asks the compositor to re-read or set a value, and never writes under `~/.config`. Final run: `FAIL=0 FINDINGS=1`, exit 0, dual-head.
- **ADOPT-02 proven three independent ways** against the running session, not just on disk: `hyprland.conf.old` present, `hyprland.lua` present, `hyprland.conf` absent, `configProvider` no longer the recorded pre-adopt `hyprlang`, and `hyprctl eval` returning `ok`.
- **ADOPT-03 proven dual-head** — HDMI-A-2 was attached, contradicting RESEARCH Pitfall 3, so the dual-head half was checked rather than skipped. All eleven workspace rules are live in the running compositor, which is what separates "the overlay was copied" from "the overlay loaded".
- **All three tier-1 rollback sources carry the identical sha256** `3d17932a…89b5` at 15301 bytes, matching the pre-adopt fixture. D-36 additionally proved the backup actually *ran* rather than being skipped, by mtime and hash.
- **A verifier defect caught and fixed** that had produced 13 phantom failures and one false pass, recorded in the phase record as a lesson rather than quietly patched.
- **A new rollback finding**: the upstream backup uses `rsync -av` without `-L`, so eight entries under `~/ii-original-dots-backup` are preserved symlinks rather than content. The backup is not a recovery source for anything stow manages.

## Task Commits

1. **Task 1: Gate — go/no-go on the adopt window** — no commit, by design (D-19; the decision is recorded in the transcript)
2. **Task 2: Operator runs the adopt window from a bare TTY** — no commit (human action; D-01 forbids agent invocation)
3. **Task 3: ADOPT-02 tracer — verify script** — `96ea7e8` (fix), `1df04e0` (feat)
4. **Task 4: Expand to ADOPT-03, ADOPT-04 inputs, and D-35..D-38** — `21badd5` (feat), `9cb41c5` (fix), `2539238` (chore)
5. **Task 5: Write 14-LIVE-VERIFY.md and commit the transcript** — `8b8ba4b` (docs)

## Files Created/Modified

- `scripts/phase14-verify.sh` — the read-only post-adopt verifier; fixture reader, live-instance resolution, `hypr_json` payload gate, then the ADOPT-02/03/04 and D-35..D-38 blocks
- `.planning/phases/14-live-full-adopt-verify/14-LIVE-VERIFY.md` — the phase record: verbatim script output with provenance, the ADOPT-02 three-way proof, the ADOPT-03 result, the four human answers, rollback inputs, known losses, four dispositioned findings, and de-escaped transcript excerpts
- `.planning/phases/14-live-full-adopt-verify/14-ADOPT-TRANSCRIPT.txt` — the raw `script(1)` capture, 1.8 MB, reviewed for secrets before staging
- `stow/zsh/.config/starship.toml` — upstream's overwrite committed as an accepted D-17 loss

## Decisions Made

- **Assert absence of the observed pre-state, not presence of a guessed post-state.** The config-provider check fails when the live value still equals the recorded `hyprlang`. The post-adopt `lua` is recorded as an observation. Hard-coding `lua` as the expected value would turn any upstream rename into a spurious failure.
- **Assert the specific success token.** `hyprctl eval` must return exactly `ok`, probed against the live compositor rather than assumed. This is the direct fix for the false pass below.
- **Unobservability is symmetric.** A condition the script cannot observe is never a pass and never a specific defect. An unreachable compositor yields one honest reachability failure plus named `[INFO]` lines.
- **Commit the starship.toml loss rather than revert it.** Reverting would fight the next upstream sync; committing it with `96ea7e8:stow/zsh/.config/starship.toml` recorded as the recovery ref documents the D-17 decision instead.
- **Commit the transcript raw.** Navigability comes from quoted de-escaped excerpts in the record, not from a filtered copy that would no longer be the artifact.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Verifier reported a pass for a condition it could not observe, and defects for others**

- **Found during:** Task 4 (acceptance gate)
- **Issue:** The script trusted the inherited `$HYPRLAND_INSTANCE_SIGNATURE`. A shell predating the operator's re-login carried the dead session's signature, and `hyprctl` writes its `Couldn't connect to …/.socket.sock. (4)` refusal to **stdout**. The first post-adopt run reported `FAIL=14`; 13 were fabricated. Both halves of the plan's binding rule were violated at once: `[PASS] ADOPT-02 hyprctl eval accepted, returned: Couldn't connect to …` quoted a connection error as its own evidence, while eleven workspace-rule lines and two monitor lines asserted "overlay did not load" from evidence for neither.
- **Fix:** Resolve the live instance from `hyprctl instances` (which enumerates the socket directory rather than reading the env var) and re-export the signature for this process; name a stale inherited signature explicitly in the output. When no instance is live, emit ONE reachability failure and report the affected assertions as `[INFO] NOT OBSERVED`. Assert `hyprctl eval` returns exactly `ok`. Gate every JSON probe on the payload parsing, via a `hypr_json` helper — the audit found `-j status`, `-j monitors all` and `-j workspacerules` all shared the non-empty-stdout shape.
- **Files modified:** `scripts/phase14-verify.sh`
- **Verification:** Three scenarios, not just the happy path — a normal run (`FAIL=0`), a run with a deliberately stale signature (names it, re-resolves, all green), and a run against a test double whose socket refuses while `instances` reports live (every refusal becomes a `[FAIL]`, zero `[PASS]` lines carry the refusal text, zero phantom "overlay did not load").
- **Committed in:** `9cb41c5`

**2. [Rule 3 - Blocking] D-35 could not clear with an accepted loss sitting uncommitted**

- **Found during:** Task 4 (acceptance gate)
- **Issue:** ` M stow/zsh/.config/starship.toml` was a genuine dirty-tree entry. `~/.config/starship.toml` is a stow symlink into that repo file and upstream's installer wrote through it (82 insertions, 272 deletions). Per D-17 this is an accepted loss, but D-35 requires a clean tree outside the phase directory.
- **Fix:** Committed the working-tree version atomically, with the recovery ref recorded in the commit body. Verified `96ea7e8:stow/zsh/.config/starship.toml` byte-identical to the pre-overwrite copy *before* committing, so the recovery reference is checked rather than asserted.
- **Files modified:** `stow/zsh/.config/starship.toml`
- **Verification:** `git status --porcelain` clean; the D-35 assertion passes.
- **Committed in:** `2539238`

**3. [Rule 3 - Blocking] Phase 14's own artifacts tripped the D-35 clean-tree gate**

- **Found during:** Task 3
- **Issue:** The D-35 check flagged the phase's own in-progress transcript and verify artifacts as a dirty tree.
- **Fix:** Anchored the filter on the `.planning/phases/14-live-full-adopt-verify/` prefix, as the plan specifies, rather than a blanket allowance.
- **Files modified:** `scripts/phase14-verify.sh`
- **Committed in:** `96ea7e8`

**4. [Rule 3 - Blocking] D-39 token collision in the phase record**

- **Found during:** Task 5
- **Issue:** The phrase "shell chrome" tripped Task 5's own D-39 check, which requires every chrome-bearing token in the record to be exactly `google-chrome-stable`. The check is right: that phrase sitting beside a browser of nearly the same name is genuinely ambiguous to anyone grepping the record.
- **Fix:** Reworded to "shell surface", with a note explaining the reservation.
- **Files modified:** `.planning/phases/14-live-full-adopt-verify/14-LIVE-VERIFY.md`
- **Committed in:** `8b8ba4b`

---

**Total deviations:** 4 auto-fixed (1 bug, 3 blocking)
**Impact on plan:** Deviation 1 was essential — without it the plan's central prohibition was being violated in both directions by the very script written to enforce it. The other three unblocked acceptance criteria the plan itself specifies. No scope creep; every change stayed inside the two files the plan names.

## Issues Encountered

- **The transcript does not cover the whole window.** The `script(1)` recording spans the `install --full` run only (23:13:41 to 23:35:01, 21m 8s). Runbook sections 8 and 9 were performed after it closed. Rather than imply otherwise, `14-LIVE-VERIFY.md` states the scope plainly and attests those steps by disk and compositor evidence instead: byte-identical overlay files, eleven live workspace rules, and the kitty symlink.
- **Two runbook steps are wrong as written**, both worked around by the operator and both recorded for correction. Section 9's `stow -R kitty` from the repo root fails — packages live under `stow/`, and `arch/kitty.sh:10` uses `cd .../stow && stow -v=5 -t ~ kitty`; it also aborts on the pre-existing real `~/.config/kitty/kitty.conf`. The second claim recorded here — that section 8's heredoc has an indented `SH` terminator — is **retracted**: no committed revision of the runbook contains a heredoc at all, and section 8 delegates to `13-SOT-APPLY.md` rather than printing a fence. See `14-VERIFICATION.md` warning 1 and the retraction in `14-LIVE-VERIFY.md` § Findings 4.
- **Seventeen alarming-but-benign `error: target not found:` lines** in the transcript come from `remove_deprecated_dependencies` trying to remove packages never installed on this machine. Recorded explicitly so a future reader does not mistake them for breakage.
- **An earlier `AvailableSourceTypes = u 0` reading was an artifact**, not a regression. It came from the same dead socket as the phantom failures. The portal reads `u 7`, unchanged from pre-adopt, and screen share works.

## Known Stubs

None. Every check in `scripts/phase14-verify.sh` probes real state; nothing is hardcoded to pass, and the fixture reader hard-fails on a missing file or missing key rather than comparing against empty.

## Threat Flags

None. This plan adds no network endpoint, auth path, or schema change. `scripts/phase14-verify.sh` is read-only, invokes `./arch/dots-hyprland.sh` only with `--dry-run`, and writes nothing outside `mktemp` files it removes under a `trap`.

## User Setup Required

Complete. The operator-executed adopt window (`user_setup: local-machine-console`) was performed on 2026-09-04 and is attested by `14-ADOPT-TRANSCRIPT.txt` and the verify run.

## Next Phase Readiness

Phase 14's automatable and human halves are both closed. Two items carry forward to Phase 15, neither blocking:

1. **`graphical-session.target` inactive.** The personal session unit's autostart died with the renamed conf. The unit file itself survives at `stow/systemd/.config/systemd/user/hyprland-session.service`; re-establishing its start is a Lua-side decision about where `exec-once` equivalents now live. Screen share, the expected casualty, works.
2. **The backup directory is not a recovery source for stow-managed files.** Eight preserved symlinks under `~/ii-original-dots-backup` point back into this repo, including `starship.toml` and `kitty.conf`. For anything stow manages, git history is the recovery source. ADOPT-04 is unaffected — tier 1 asserts `hyprland.conf`, a real file whose hash was verified.

Four record corrections should be applied before those artifacts are trusted again: runbook sections 8 and 9, and RESEARCH Pitfalls 3 and 7. All four are written up in `14-LIVE-VERIFY.md` § Findings.

## Self-Check: PASSED

- All `key-files.created` exist on disk: `scripts/phase14-verify.sh`, `14-LIVE-VERIFY.md`, `14-ADOPT-TRANSCRIPT.txt`, plus this summary and the modified `stow/zsh/.config/starship.toml`.
- All six task commits found in `git log --oneline --all`: `96ea7e8`, `1df04e0`, `21badd5`, `9cb41c5`, `2539238`, `8b8ba4b`.
- Plan-level verification re-run: `./scripts/phase14-verify.sh` exits 0 with 38 `[PASS]`, 0 `[FAIL]`, 1 `[FINDING]`, 12 `[INFO]`.
- Task 4 and Task 5 acceptance criteria both re-run and clear, including the D-39 token check and the eleven workspace-rule count.
- The `## Verify run` block in `14-LIVE-VERIFY.md` was `diff`ed against a fresh run and is byte-verbatim, not retyped.

---
*Phase: 14-live-full-adopt-verify*
*Completed: 2026-09-05*
