---
phase: "16"
slug: "retire-the-safe-profile-full-only-wrapper-and-playbook"
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
created: "2026-09-08"
---

# Phase 16 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

The plan-time register was authored across all ten PLAN files (`register_authored_at_plan_time: true`), so this audit verifies mitigations rather than building a register retroactively. Block threshold is `high`.

---

## Trust Boundaries

Consolidated from the ten plans' `## Trust Boundaries` blocks. All three are wrapper-owned; the phase introduced no network endpoint, auth path, credential store or schema.

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| operator argv → upstream `./setup` | Every token the wrapper does not explicitly parse falls through `user_flags` into a privileged installer. This is the boundary D-05 exists to hold. | command-line flags; no secrets |
| wrapper → live filesystem | `uninstall` deletes paths under `$HOME`; `install` hands the filesystem to upstream. After D-06/D-09 nothing wrapper-owned stands in front of the install side. | user configs, state, venv — irreplaceable, no snapshot by default |
| wrapper stdout → assert scripts and published docs | Five scripts and one playbook grep this program's literal output. A reworded echo silently breaks a contract that has no compiler. | paths, flags, package names; no credentials |

---

## Threat Register

69 numbered threats (T-16-01 … T-16-69) plus the per-plan supply-chain entry T-16-SC. Rolled up by plan below; the per-threat mitigation text lives in each `16-NN-PLAN.md` under `## STRIDE Threat Register`, and the discharge evidence in the matching SUMMARY's `## Threat Flags`.

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-16-01 … T-16-04 | Tampering, EoP, DoS | wrapper argv parsing, `ALLOWLIST`, array exec, uninstall signatures | high | mitigate | `--full)` arm swallows the flag; `protect` removed from the array and its refusal asserted; array-only exec preserved; `uninstall --dry-run` exit-code check | closed |
| T-16-05 | Destruction of data | install path after D-06 / D-09 | high | accept | Accepted risk R-01 below | closed |
| T-16-06 | Denial of Service | package marks after D-07 | medium | accept | Accepted risk R-02 below | closed |
| T-16-07 | Destruction of data | `run_upstream_uninstall_dangerous` | medium | mitigate | Left byte-unchanged including its type-token guard; asserted absent from the phase diff | closed |
| T-16-08 | Information Disclosure | wrapper stdout | low | accept | Accepted risk R-03 below | closed |
| T-16-09 … T-16-13 | Tampering, DoS, Repudiation | usage heredoc, smoke suite, `trap` list, wrapper scope creep | high / medium | mitigate | Stale-token loop over the help capture; `[PASS]` floor of 12 plus a ban on deleted requirement IDs; `bash -n` plus a real run under `set -u` | closed |
| T-16-14 … T-16-18 | Destruction of data, Repudiation, Tampering, DoS | preflight rotation path, live suite as evidence, clean-tree assert, `trap` hygiene, the quoted summary line | high / medium | mitigate | Script deleted outright with a reference sweep; deletions asserted by absence; `PHASE14_PREFIX` survives; both snapshot directories confirmed untouched | closed |
| T-16-19 | Information Disclosure | verification output | low | accept | Accepted risk R-03 below | closed |
| T-16-20 … T-16-26 | Tampering, DoS, Destruction of data, Repudiation | playbook install section, unattended-install expectation, recovery narrative, the doc gate itself, ban scope, §6 fence, dead links | high / medium | mitigate | Output captured from the finalised binary; bans asserted in both directions; negative control seeds a banned term and requires a non-zero exit; relative-link resolver walks every link | closed |
| T-16-27 | Information Disclosure | operator docs | low | accept | Accepted risk R-03 below | closed |
| T-16-28 … T-16-33 | Destruction of data, DoS, Tampering, Repudiation | runbook rollback tiers, backup-rotation narrative, deleted preflight invocations, adopt-window record | high / medium | mitigate | Tiers replaced wholesale with the reinstall narrative; section count pinned at 17; recorded date and rotated-directory timestamp asserted present | closed |
| T-16-34 | Information Disclosure | operator docs | low | accept | Accepted risk R-03 below | closed |
| T-16-35 … T-16-40 | Repudiation, Tampering, DoS | wrapper drift check, tier ordering, fence-drift assert, reconciling filter, extraction idiom | high / medium | mitigate | Baseline resolved at execution time and confirmed empty-diff; newest marker tested first; negative control perturbs the fence and requires a `W-3` failure | closed |
| T-16-41 | Information Disclosure | the sweep record | low | accept | Accepted risk R-03 below | closed |
| T-16-42 … T-16-47 | Repudiation, Tampering | requirement rows, coverage arithmetic, audit findings, sibling asserts, stale evidence, scope creep | high / medium | mitigate | Row counts and coverage block asserted independently at 19; both blocker identifiers required present with a resolution citing a Phase 16 plan; `git diff --quiet HEAD` scope checks | closed |
| T-16-48 | Information Disclosure | planning artifacts | low | accept | Accepted risk R-03 below | closed |
| T-16-49 … T-16-54 | Repudiation, DoS, Destruction of data, Tampering | delivered-lines annotation, frozen artifacts, the disposition assert, archived session-chrome trees | high / medium | mitigate | Annotate-don't-rewrite enforced; `git diff --name-only` scope check; all three archive directories asserted still present | closed |
| T-16-55 | Information Disclosure | planning artifacts | low | accept | Accepted risk R-03 below | closed |
| T-16-56 … T-16-61 | Destruction of data, Repudiation, Tampering | full-file write over a tooling-managed doc, coverage arithmetic, per-phase history, open items, scope creep | high / medium | mitigate | Scoped `Edit` with a re-read before each; roadmap line asserted at nineteen; both deferred items required open and unowned; owner-assignment pattern banned | closed |
| T-16-62 | Information Disclosure | planning artifacts | low | accept | Accepted risk R-03 below | closed |
| T-16-63, T-16-64, T-16-66, T-16-67, T-16-68 | Repudiation, Tampering | gate transcript, dirty-tree gate, finding count, inline fixes, playbook expectation | high / medium | mitigate | Summary lines quoted verbatim against a floor of four zero-failure lines; clean tree asserted before the first script; finding count pinned; no file but the sweep record modified | closed — see note on T-16-66 / T-16-68 |
| T-16-65 | Denial of Service | the session after the phase | high | mitigate | The automated suites cannot distinguish a working session from a surviving one. Discharged by human re-login, recorded as UAT test 6 (`16-UAT.md`), result pass. | closed |
| T-16-69 | Information Disclosure | gate transcripts | low | accept | Accepted risk R-03 below | closed |
| T-16-SC | Tampering | package-manager installs | low | accept | Accepted risk R-04 below | closed |
| **T-16-70** | **Destruction of data** | `stop_running_qs` state re-clean, `arch/dots-hyprland.sh` | **critical** | mitigate | **Found by code review (C-01), not by the plan-time register.** The re-clean ran outside every flag guard: `--keep-venv` lost the venv, `--packages-only` lost configs/state, the blanket `rm -rf` bypassed `safe_rm_path`'s `$HOME`/hypr refusals, and `--dry-run` never showed it. Fixed in `cfa63ad`: `reclean_qs_state` takes the caller's flags, routes through `safe_rm_path`, and prints its plan under dry-run. Asserted both ways in `phase16-retire-assert.sh`. | closed |
| **T-16-71** | **Destruction of data** | `run_install_family` skip-backup injection | **high** | mitigate | **Found by code review (H-01).** `--skip-backup` was injected on every `install`/`install-files` with no counter-flag in upstream's getopt, so upstream's only snapshot was unconditionally suppressed. Fixed in `cfa63ad`: `--keep-backup` is a wrapper-owned meta flag that omits the injection for that run. Default unchanged; both directions asserted. | closed |
| **T-16-72** | **Repudiation** | `docs/phase14-adopt-runbook.md` §4, §7, header | **high** | mitigate | **Found by code review (H-02).** The runbook still told an operator to wait for a backup gate that no longer exists, so an install would proceed past the point they expected to be able to abort; line 138 contradicted line 165 of the same file. Fixed in `cfa63ad` with the past-tense record treatment used in §3/§5/§14, and the dangling rollback-tier references repointed. | closed |
| T-16-73 | Destruction of data | `collect_ii_config_targets`, `arch/dots-hyprland.sh:160-165` | medium | open | **Review M-01, unfixed.** Detection is scoped to `$qs/ii` but the removal target is the parent `~/.config/quickshell`, so any other named quickshell config the operator keeps there is collateral. Pre-dates Phase 16. | open — below `high` threshold (non-blocking) |
| T-16-74 | Tampering | `--allow-skip-backup` reaching upstream's getopt | medium | open | **Review M-02, unfixed.** The flag is no longer wrapper-owned and now falls through the catch-all to upstream as an unknown long option — the same boundary T-16-01 exists to hold, for a different flag. | open — below `high` threshold (non-blocking) |
| T-16-75 | Repudiation | ban-greps in the assert scripts | medium | open | **Review M-04/M-05, partially addressed.** Ban-greps treat a grep *error* (exit 2) as "no match" and print PASS, and some checks read capture files outside the `if` that populates them. The two new C-01 asserts added in `cfa63ad` carry an explicit vacuity guard; the pre-existing ones do not. | open — below `high` threshold (non-blocking) |
| T-16-76 | Tampering | `phase13-d19-assert.sh` shell-fence execution | medium | open | **Review M-07, unfixed.** The suite executes a shell fence extracted from a Markdown file, and Phase 16 generalized that into a reusable extractor. The input is repo-controlled, so this is a latent shape rather than a live exposure. | open — below `high` threshold (non-blocking) |

*Status: open · closed · open — below `high` threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above `workflow.security_block_on` (`high`) count toward threats_open*

**Note on T-16-66 / T-16-68.** Both pinned `phase14-verify.sh` at exactly one finding, and both held at execution time. A live re-run on 2026-09-08 prints `FINDINGS=2`: the second is `D-38 ScreenCast portal answers AvailableSourceTypes = 'u 0', pre-adopt was 'u 7'`, live-session drift downstream of the same inactive `graphical-session.target` the first finding reports. It is a finding, not a failure, and T-16-68's mitigation is precisely "record the mismatch rather than let it diverge silently" — which is what `16-VALIDATION.md` now does. `docs/dots-hyprland-workflow.md:326` still quotes `FINDINGS=1` and is now one short of a live run.

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| R-01 | T-16-05 | An install takes no snapshot and has no undo. `16-CONTEXT.md` D-06 and D-09 record that the operator was told this and chose to proceed; re-confirmed at plan 16-01's blocking checkpoint. Existing snapshots on disk are left untouched. Narrowed since acceptance: `--keep-backup` (T-16-71) now gives a per-run opt-out, so the risk is the default rather than the only behavior. | operator (`16-CONTEXT.md` D-06, D-09) | 2026-09-07 |
| R-02 | T-16-06 | After D-07 the wrapper no longer marks packages, so a later orphan sweep can remove `hyprland`, `kitty`, `starship`, `cliphist`, `bc` and `jq`. `16-CONTEXT.md` D-07 records the operator was told and chose to proceed. Flagged, not gated — rated costly, not one-way. | operator (`16-CONTEXT.md` D-07) | 2026-09-07 |
| R-03 | T-16-08, T-16-19, T-16-27, T-16-34, T-16-41, T-16-48, T-16-55, T-16-62, T-16-69 | Wrapper stdout, verification output, operator docs, the sweep record, planning artifacts and gate transcripts all print paths, flags, package names and process facts. No credential is read or echoed anywhere in the phase; the one environment variable in play, `ILLOGICAL_IMPULSE_VIRTUAL_ENV`, is a path. | phase design | 2026-09-07 |
| R-04 | T-16-SC (all ten plans) | The phase adds no `npm` / `pip` / `cargo` / `pacman` install step — it deletes one — and runs no live install or uninstall. `16-RESEARCH.md` § Package Legitimacy Audit records the ecosystem gate as not applicable, with no `[ASSUMED]`, `[SUS]` or `[SLOP]` entries. | phase design | 2026-09-07 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-09-08 | 76 | 72 | 4 (all below the `high` block threshold) | /gsd-secure-phase 16 (orchestrator, no auditor agent — L1 grep depth) |

Audit inputs: the ten PLAN threat registers, the six SUMMARY `## Threat Flags` blocks that exist, `16-UAT.md` (81/81 pass), and `16-REVIEW.md` (19 findings, committed this session).

The plan-time register classified 0 open. The code review raised three security-classed defects outside that register — C-01 critical, H-01 and H-02 high — none of which had a mitigation or a documented acceptance. They were registered as T-16-70/71/72, the operator chose to fix rather than accept, and all three were fixed in `cfa63ad` with matching asserts. Four medium findings (T-16-73…76) remain open below the block threshold and are recorded here rather than fixed.

Verification after the fixes, on a committed clean tree:

```
./scripts/phase16-retire-assert.sh       → === done: FAIL=0 ===              exit 0
./scripts/phase12-full-smoke.sh          → === done: FAIL=0 ===              exit 0
./scripts/phase11-dispositions-assert.sh → === done: FAIL=0 ===              exit 0
./scripts/phase10-inventory-assert.sh    → === done: FAIL=0 ===              exit 0
./scripts/phase13-d19-assert.sh          → === Phase 13 asserts: FAIL=0 ===  exit 0
./scripts/phase14-verify.sh              → === done: FAIL=0 FINDINGS=2 ===   exit 0
```

The wrapper drift baseline was re-pinned from `0771cc2` to `cfa63ad` in the same session — the pin went red as designed when the wrapper changed, and the new pin's blob is byte-identical to the working tree.

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-09-08
