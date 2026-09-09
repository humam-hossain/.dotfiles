# Phase 15: Playbook safe vs full - Research

**Researched:** 2026-09-05
**Domain:** Operator documentation for a dotfiles/Hyprland install wrapper — post-adopt truth reconciliation
**Confidence:** HIGH (all load-bearing claims verified by reading the source files and probing the live machine this session)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Doc topology**

- **D-01:** Rewrite `docs/dots-hyprland-workflow.md` in place. It remains the single canonical playbook (Phase 9 DOC-01/DOC-02). No second profiles doc, no split appendix.
- **D-02:** `docs/phase14-adopt-runbook.md` keeps its structure and role as the record of the 2026-09-04 adopt window. The playbook cites it for the three-tier rollback (§14) and for adopt-window detail; no content is copied into the playbook.
- **D-03:** Structure stays simple and linear. No parallel safe/full tracks, no per-section forks. One spine — clone, pin, install, session, verify, update — with profile differences stated in place.

**Reader framing**

- **D-04:** The playbook addresses a cold machine first: clone → pin → install → verify. The current post-adopt state of this machine is a short note, not the framing.
- **D-05:** The linear walkthrough walks the **full** profile end to end.
- **D-06:** The **safe** profile still gets its own explicit definition paragraph next to full's — what SAFE_DEFAULTS injects (`--core --skip-hyprland --skip-sysupdate`), what it does not touch, that dual-run is its property, and where its session hooks are documented. This is required for DOC-03 ("safe **vs** full") and does not violate D-03: it is one section on the same spine, not a second track.
- **D-07:** The playbook states plainly that the wrapper default is still safe and `--full` is opt-in wrapper-owned meta (FULL-01/FULL-02). Walking full is a documentation choice; it is not a default change. This is required so D-05 does not read as contradicting the Out of Scope row "Making full profile the default wrapper behavior".
- **D-08:** The session section documents the **full** model only: `~/.config/hypr/hyprland.lua` is the session entry, `hyprctl getoption configProvider` returns `lua`, upstream renamed the previous `~/.config/hypr/hyprland.conf` to `.old`, and personal overlays live in `~/.config/hypr/custom/`. The safe conf-hook method (`env = ILLOGICAL_IMPULSE_VIRTUAL_ENV,~/.local/state/quickshell/.venv` and `exec-once = qs -c ii` in `hyprland.conf`) gets one pointer line, not a section.
- **D-09:** Dual-run is described as a property of the safe profile only, never as a milestone goal. Under the full profile, `Waybar`, `rofi` and `swaync` are replaced by `qs -c ii`; that removal is accepted per D-11 of Phase 11, and the prior trees are archived under `stow/` per D-12. Write `Waybar/rofi/swaync` literally — never "chrome" (Phase 14 D-39).
- **D-10:** Delete the stale claims: the Purpose line promising "dual-run (`waybar` + `qs -c ii`)" as the destination, the Prerequisites line "you own personal `~/.config/hypr` (wrapper defaults **do not** replace `hyprland.conf`)" as an unconditional statement, and the §4 "No Waybar cutover required for this milestone" framing.

**Depth vs citation**

- **D-11:** Flag axes get a compact three-row table — `skip-hyprland`, `core`, `sysupdate` — each row saying what injecting it and what dropping it does to the machine. `./arch/dots-hyprland.sh help` stays the syntax SoT and is named as such; the table is narrative, not a flag reference.
- **D-12:** Do not reproduce the full wrapper flag list in the playbook.
- **D-13:** The inventory→disposition→adopt sequence is written as a **required gate before any full install**, and it appears **before** the install step, not after (ADOPT-01 is a process gate; a cold machine must not reach `--full` without it). `.planning/phases/10-full-install-impact-inventory/10-INVENTORY.md` and `.planning/phases/11-disposition-decisions/11-DISPOSITIONS.md` are cited as this machine's worked instance and as SoT for their content.
- **D-14:** The backup gate is documented inline at the full install step: what gets backed up, where it lands (this machine: `~/ii-original-dots-backup.20260904T171128Z`), and that bare `--skip-backup` is refused without `--allow-skip-backup` (FULL-03). The rollback procedure itself stays cited to the runbook — simplest split, no duplicated tiers.
- **D-15:** Post-install verification is copy-pasteable with expected output: `hyprctl getoption configProvider` → `lua`, `qs -c ii` running, overlays present under `~/.config/hypr/custom/`. No failure-branch tree; failures point at the runbook.

**Overlay policy and known losses**

- **D-16:** DOC-04 content is written in the playbook's own words: repo `.config/hypr/custom/` is the authoring SoT, apply is one-way repo→live, machine overlays are never committed into `vendor/dots-hyprland` or the fork, and the apply command is the named-file `cp -a` of `general.lua` / `env.lua` / `execs.lua`. `.planning/phases/13-personal-hypr-custom-overlays/13-SOT-APPLY.md` is cited and named as the SoT for the full policy and the in-repo verify; the playbook is narrative over it (Phase 13 D-05 stands).
- **D-17:** D-38 is documented as a short "known losses after full adopt" note: the `hyprland-session.service` / `graphical-session.target` bootstrap (which is what xdg-desktop-portal ScreenCast needs, so screen share is affected), `wl-clip-persist`, and the four workspace-pinned autostarts. Documentation only — no fix, no restoration work, no new scope. This closes STATE's "Phase 15 or its own phase" question in favour of "documented here, fix unowned".
- **D-18:** WR-02 gets a full disambiguation section for the repo copy `.config/hypr/hyprland.conf`: it is at once the rollback source, the frozen D-36 evidence, and the pre-adopt hook-injection target — and which of those roles applies under which profile. The full path does not use it as a live file.
- **D-19:** IN-11 is docs-only in this phase. The stale `--rotate-backup` "mandatory before go" line in `scripts/phase14-preflight.sh` is recorded as a deferred fix with an owner; the script is not edited by a documentation phase. If the playbook mentions `--rotate-backup` at all, it states that it must not be run post-adopt, because it would rename away rollback source 3.

**Doc sweep**

- **D-20:** The staleness sweep covers `docs/dots-hyprland-workflow.md`, `docs/phase14-adopt-runbook.md`, root `README.md`, `arch/README.md`, and `.planning` prose.
- **D-21:** In the runbook, factually false post-adopt lines are corrected. "Keep as-is" (D-02) means no content moves out of it and its structure is preserved — it does not mean falsehoods stay.
- **D-22:** The `.planning` part of the sweep is **read-only review plus a written report**, with these exceptions and guards:
  - `PROJECT.md` product-surface lines may be corrected where they are now false.
  - `STATE.md` and `ROADMAP.md` are never edited directly — only through `gsd-tools.cjs` query handlers.
  - Phase-scoped historical artifacts (`1X-CONTEXT.md`, `1X-SUMMARY.md`, `1X-VERIFICATION.md`, `10-INVENTORY.md`, `11-DISPOSITIONS.md`, `13-SOT-APPLY.md`) are frozen records of what was decided at the time. Flag staleness in the report; do not rewrite history.
- **D-23:** Cross-reference links must stay true after the rewrite (playbook "See also", runbook "See also", README pointer).

### Claude's Discretion

- Exact section numbering and headings of the rewritten playbook, within the linear shape of D-03.
- Wording and column layout of the flag-axis table (D-11) and the safe/full definition paragraphs (D-06).
- Whether the sweep report lives as its own phase artifact or as a section of the phase summary.
- Whether verification commands are presented as one block or attached to their steps.

### Deferred Ideas (OUT OF SCOPE)

- **IN-11 fix** — correct the `--rotate-backup` "mandatory before go" line in `scripts/phase14-preflight.sh`, which post-adopt would rename away rollback source 3. Needs an owning phase; out of scope for a documentation phase (D-19).
- **D-38 restoration** — restoring the `graphical-session.target` / `hyprland-session.service` bootstrap for xdg-desktop-portal ScreenCast, `wl-clip-persist`, and the four workspace-pinned autostarts. Phase 15 documents the loss only (D-17); any fix is unowned work for a later phase.
- **Dual-run restore path** — documenting how to bring Waybar/rofi/swaync back from `stow/` after a full adopt. Not written here; nothing has verified that path since the adopt.
- **CUT-01 / CUST-01..04** — Waybar module ports and cutover polish remain future requirements, untouched by this phase.
- **Staleness found in `.planning` phase artifacts** — reported, not rewritten (D-22). Any correction that matters belongs to a phase that owns that artifact.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DOC-03 | Playbook documents **safe vs full** install profiles, inventory→disposition→adopt sequence, and flag axes (`skip-hyprland` / `core` / `sysupdate`) | §Flag Axes — Verified Ground Truth (real `help` output + `SAFE_DEFAULTS` array + `--full` parse at `arch/dots-hyprland.sh:12,1410,1444-1452`); §Gate Sequence gives the ADOPT-01 ordering and the two cited artifacts |
| DOC-04 | Playbook documents hypr/custom overlay expectations and repo/live/fork SoT policy from OVL-03 | §Overlay SoT — Verified Ground Truth (verbatim `13-SOT-APPLY.md` policy + apply command); live-vs-repo overlay parity confirmed green by `scripts/phase13-d19-assert.sh` |

**Requirement wording** `[VERIFIED: .planning/REQUIREMENTS.md:48-49]`:

> - [ ] **DOC-03**: Playbook documents **safe vs full** install profiles, inventory→disposition→adopt sequence, and flag axes (`skip-hyprland` / `core` / `sysupdate`)
> - [ ] **DOC-04**: Playbook documents hypr/custom overlay expectations and repo/live/fork SoT policy from OVL-03

**Binding Out of Scope rows** `[VERIFIED: .planning/REQUIREMENTS.md:74,82]`:

> | Removing Waybar/rofi/swaync by default (CUT-01) | Only if DISP-03 explicitly accepts; default keep |
> | Making full profile the default wrapper behavior | Safe defaults remain default |

Note for the planner: the CUT-01 row is satisfied by its own escape clause — DISP-03 *did* explicitly accept, via Phase 11 D-11 (`11-DISPOSITIONS.md` §6 "Dual-run chrome (DISP-03)"). The playbook must say the removal was accepted, not that it was out of scope. D-07's "safe is still the default" sentence is what keeps the second row true.
</phase_requirements>

## Summary

This is a documentation-only phase with no external dependency surface. The research that matters is **ground truth in this repo and on this machine**, because the rewritten playbook has to be factually true after the 2026-09-04 live full adopt. I read every source file named in CONTEXT.md and probed the live session. The good news: the repo's *executable* truth — `arch/dots-hyprland.sh`, `scripts/phase14-verify.sh`, `scripts/phase13-d19-assert.sh`, `13-SOT-APPLY.md` — is accurate, internally consistent, and currently green. Both verify scripts pass (`phase13-d19-assert.sh` FAIL=0; `phase14-verify.sh` FAIL=0, FINDINGS=1, the expected D-38 finding).

The bad news, and the reason this research is load-bearing: **three factual claims that CONTEXT.md instructs the playbook to assert are wrong**, and two of them have already propagated into `PROJECT.md` and the runbook. (1) `hyprctl getoption configProvider` — named in D-08, D-15 and the CONTEXT.md integration-points list — does **not** work on this machine; it returns `no such option`. The probe that works, and the one the real verify script uses, is `hyprctl -j status | jq -r .configProvider`. (2) The adopt-time backup this machine actually holds is `~/ii-original-dots-backup`, **not** `~/ii-original-dots-backup.20260904T171128Z` as D-14 and `PROJECT.md:28` claim; the timestamped directory is the *stale, rotated* pre-existing backup and its `hyprland.conf` has a different sha256 than the pre-adopt fixture. (3) Following from (2), runbook §14's tier-1 rollback source 3 instruction points the operator at the wrong directory — a genuine safety defect in a rollback procedure, and squarely a D-21 correction.

I also found a concrete, empirically-demonstrated mechanism behind the WR-02 concern that D-18 asks the playbook to disambiguate: post-adopt, live `~/.config/hypr/hyprland.conf` no longer exists, so the repo copy is the *only* remaining hook-injection target — and `./arch/dots-hyprland.sh uninstall --dry-run` confirms it "would delete ii hooks in: …/.dotfiles/.config/hypr/hyprland.conf". That is rollback **tier 2 destroying rollback tier-1 source 2**. Escalation order in the runbook is therefore not free, and D-18's section has a real hazard to describe rather than an abstract role conflict.

**Primary recommendation:** Rewrite the playbook against the *probes the verify scripts actually run*, not against the commands quoted in CONTEXT.md. Treat D-08/D-14/D-15's specific command and path strings as superseded by the verified values in this document, flag the three corrections for the operator's confirmation, and let the sweep dispose of the same errors where they already landed in `PROJECT.md` and the runbook.

## Architectural Responsibility Map

Tiers here are documentation-surface owners, not application tiers. The repo's own rule is "one SoT per surface" `[VERIFIED: 15-CONTEXT.md:123]`; this map records who owns what so the playbook summarises rather than duplicates.

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Flag/subcommand syntax | `./arch/dots-hyprland.sh help` (executable SoT) | Playbook flag-axis table (narrative) | D-11/D-12: help is generated from the live script, so it cannot drift; the table explains consequences, not syntax |
| Install/adopt operator path | Playbook `docs/dots-hyprland-workflow.md` | — | D-01: single canonical playbook |
| Rollback procedure | Runbook `docs/phase14-adopt-runbook.md` §14 | Playbook cites, never copies | D-02/D-14: three tiers live in one place |
| Overlay authoring + apply policy | `13-SOT-APPLY.md` | Playbook narrates (DOC-04) | D-16, Phase 13 D-05 |
| What a full install touches | `10-INVENTORY.md` | Playbook cites as worked instance | D-13 |
| Per-surface adopt decisions | `11-DISPOSITIONS.md` | Playbook cites | D-13 |
| Post-adopt machine truth | `scripts/phase14-verify.sh` (executable) | Playbook D-15 verify block | The script is the only non-drifting record of what "correct" means |
| In-repo overlay truth | `scripts/phase13-d19-assert.sh` (executable) | `13-SOT-APPLY.md` D-19 fence | The script *extracts and runs* the fence from the SoT, so they cannot diverge |
| Project/product status prose | `.planning/PROJECT.md` | — | D-22 permits correcting false product-surface lines |
| Roadmap / phase state | `gsd-tools.cjs` query handlers only | — | D-22 hard guard: never edit `STATE.md` / `ROADMAP.md` directly |

## Project Constraints (from CLAUDE.md)

**No `CLAUDE.md` exists in this repo.** `[VERIFIED: find . -maxdepth 3 -name CLAUDE.md -not -path ./vendor/* → no results, this session]`

`.planning/config.json` sets `"claude_md_path": "./.claude/CLAUDE.md"` `[VERIFIED: .planning/config.json]`, but that file is absent — `.claude/` contains only `agents/`, `commands/`, `gsd-core/`, `hooks/`, `scripts/`, `worktrees/` and GSD state files. No project skills directory exists either (`.claude/skills/` and `.agents/skills/` both absent).

The governing conventions therefore come from `.planning/codebase/CONVENTIONS.md` `[VERIFIED: .planning/codebase/CONVENTIONS.md:1-80]`. The ones that bind a documentation phase:

- First-party product code lives in `arch/`, `scripts/`, `stow/`, `.config/hypr/`, `debian/`, `ubuntu/`. `vendor/dots-hyprland` is upstream — do not copy its style.
- Assert scripts are named `scripts/phaseNN-<topic>-assert.{py,sh}` or `scripts/phaseNN-*-smoke.sh`. **If** the planner adds a verification script (see Validation Architecture), `scripts/phase15-docs-assert.sh` is the conforming name.
- Bash: `set -euo pipefail`, 2-space indent, `SCREAMING_SNAKE` constants, `snake_case` functions, `[PASS]`/`[FAIL]` echo labels, accumulate a `FAIL` counter and exit non-zero if `FAIL > 0`.
- "Do not invent a CI linter."
- Docs are prose Markdown with fenced bash blocks and numbered sections `[VERIFIED: 15-CONTEXT.md:122]`.

**Relevant `config.json` workflow flags** `[VERIFIED: .planning/config.json]`: `nyquist_validation: true` (Validation Architecture section required), `security_enforcement: true` with `security_asvs_level: 1` (Security Domain section required), `commit_docs: true`, `granularity: "fine"`.

## Standard Stack

No external libraries, frameworks, or packages are introduced by this phase. The "stack" is the set of tools the playbook's own commands invoke, all already present.

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| `hyprctl` (Hyprland) | 0.56.2-2 | Session-state probes for the D-15 verify block | Ships with Hyprland; the only way to ask the compositor what config provider it loaded `[VERIFIED: hyprctl version + pacman -Q hyprland, this session]` |
| `jq` | present | Parses `hyprctl -j status` / `-j workspacerules` | Already a hard dependency of `scripts/phase14-verify.sh:173` `[VERIFIED: scripts/phase14-verify.sh:173]` |
| `git` | present | Submodule pin verify, gitlink bump | Existing playbook §1/§2/§5 |
| `pgrep` | procps | `qs -c ii` liveness, Waybar/rofi/swaync absence | Used by `phase14-verify.sh:315,323` `[VERIFIED: scripts/phase14-verify.sh:315-325]` |
| `sha256sum` | coreutils | Rollback tier-1 source identity | Used by `phase14-verify.sh` `check_tier1_source` `[VERIFIED: scripts/phase14-verify.sh:~365]` |
| `grep` / `test` | POSIX | Doc-assertion verification (see Validation Architecture) | Matches existing assert-script style |

### Supporting
| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| `luac -p` | lua | Overlay syntax check | Already invoked by `phase13-d19-assert.sh` `[VERIFIED: assert output "[PASS] luac -p .config/hypr/custom/general.lua"]` |
| `python3` | 3.14 | Extracts the D-19 fence from `13-SOT-APPLY.md` | Existing pattern in `scripts/phase13-d19-assert.sh:28-42` `[VERIFIED: scripts/phase13-d19-assert.sh:28-42]` |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `hyprctl -j status \| jq -r .configProvider` | `hyprctl eval 'return 1+1'` → `ok` | The eval probe is token-independent and works even if the JSON key is renamed upstream; `phase14-verify.sh` runs **both**. For a copy-pasteable playbook block, the `-j status` form prints the value the operator wants to see, so prefer it and mention `eval` as the backup. |
| A new `scripts/phase15-docs-assert.sh` | Inline `grep`/`test` in the plan's `<automated>` blocks | A committed script is greppable and re-runnable later; inline blocks add no repo surface. Discretion — but CONVENTIONS.md names the script pattern, and the sweep's cross-reference checks are worth keeping. |

**Installation:** None. No packages are added, removed, or upgraded by this phase.

## Package Legitimacy Audit

**Not applicable.** This phase installs no external packages in any ecosystem. No `npm install`, `pip install`, `cargo add`, or `pacman -S` appears in scope; the phase boundary is documentation-only `[VERIFIED: 15-CONTEXT.md:11]`. The Package Legitimacy Gate was therefore not run and no package verdicts are reported.

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

---

## GROUND-TRUTH CORRECTIONS — read before planning

Three claims CONTEXT.md instructs the playbook to make are **false on this machine**. Writing them as instructed would ship a playbook whose headline verification command fails on first paste. Each is verified below with the probe output.

### Correction 1 — `hyprctl getoption configProvider` does not exist

CONTEXT.md D-08, D-15 and the integration-points list all name this command `[VERIFIED: 15-CONTEXT.md:30,40,127]`. Live output:

```
$ hyprctl getoption configProvider
no such option
$ hyprctl getoption config_provider
no such option
$ hyprctl getoption misc:configProvider
no such option
```

`[VERIFIED: live probe, Hyprland 0.56.2-2, this session]`

The working probes, both of which `scripts/phase14-verify.sh` uses:

```
$ hyprctl -j status
{
    "configProvider": "lua",
    "backend": "drm"
}
$ hyprctl eval 'return 1+1'
ok
```

`[VERIFIED: live probe, this session]`

The verify script reads exactly this: `PROVIDER_LIVE="$(jq -r '.configProvider // empty' <<<"$STATUS_JSON")"` `[VERIFIED: scripts/phase14-verify.sh:173]`, where `STATUS_JSON="$(hypr_json -j status)"` `[VERIFIED: scripts/phase14-verify.sh:168]`. The Lua REPL probe asserts the exact return value: `HYPR_LUA_OK="ok"` … `EVAL_OUT="$(hyprctl eval 'return 1+1' 2>&1 || true)"` `[VERIFIED: scripts/phase14-verify.sh:193-197]`.

**Planner action:** the D-15 verify block and the D-08 session paragraph must use `hyprctl -j status | jq -r .configProvider` → `lua`. Optionally mention `hyprctl eval 'return 1+1'` → `ok` as the token-independent backup. This error has already propagated to `.planning/PROJECT.md:18` and is a sweep target (below). Because it contradicts a locked decision's literal text, it warrants a `checkpoint:human-verify` — see Assumptions Log A1.

Useful extra fact for the D-08 paragraph: the verify script asserts the *absence of the pre-adopt token*, not the presence of a guessed one, and the recorded pre-adopt value was `configProvider_pre=hyprlang` `[VERIFIED: .planning/phases/14-live-full-adopt-verify/14-PRE-ADOPT-BASELINE.txt]`. So the honest sentence is "`configProvider` now reports `lua`; before the adopt it reported `hyprlang`."

### Correction 2 — the adopt backup is `~/ii-original-dots-backup`, not the timestamped directory

CONTEXT.md D-14 says the backup on this machine landed at `~/ii-original-dots-backup.20260904T171128Z` `[VERIFIED: 15-CONTEXT.md:39,127]`. Both directories exist:

```
$ ls -ld ~/ii-original-dots-backup*
drwxr-xr-x 4 pera pera 4096 Sep  4 23:33 /home/pera/ii-original-dots-backup
drwxr-xr-x 4 pera pera 4096 Jul 27 14:22 /home/pera/ii-original-dots-backup.20260904T171128Z
```

`[VERIFIED: live probe, this session]`

Hashing the `hyprland.conf` inside each against the recorded pre-adopt fixture `hyprland_conf_sha256=3d17932a6d2dd1b61ccc509402a70c224409bb5c24c4ed70a3c55d4f4bcd89b5` `[VERIFIED: 14-PRE-ADOPT-BASELINE.txt]`:

```
3d17932a6d2dd1b61ccc509402a70c224409bb5c24c4ed70a3c55d4f4bcd89b5  ~/.config/hypr/hyprland.conf.old            ← tier-1 source 1 ✓
3d17932a6d2dd1b61ccc509402a70c224409bb5c24c4ed70a3c55d4f4bcd89b5  .config/hypr/hyprland.conf                  ← tier-1 source 2 ✓
3d17932a6d2dd1b61ccc509402a70c224409bb5c24c4ed70a3c55d4f4bcd89b5  ~/ii-original-dots-backup/.config/hypr/hyprland.conf          ← tier-1 source 3 ✓
c5c65023dcdb0a202c6e73e32320daf8e6343b00a394fc3bfcf8d5be39867bfe  ~/ii-original-dots-backup.20260904T171128Z/.config/hypr/hyprland.conf   ← STALE, not the pre-adopt conf ✗
```

`[VERIFIED: sha256sum, this session]`

The sequence that produced this: an earlier install created `~/ii-original-dots-backup` (directory mtime Jul 27, preserved through the later rename); runbook §5's `--rotate-backup` renamed it aside to `…20260904T171128Z` at 2026-09-04 17:11:28Z; then the `--full` install created a **fresh** `~/ii-original-dots-backup` holding the genuine pre-adopt configs. The verify script agrees — `BACKUP_DIR="$HOME/ii-original-dots-backup"` `[VERIFIED: scripts/phase14-verify.sh:45]` — and passes it as tier-1 source 3 and as the D-36 evidence:

> `[PASS] ADOPT-04 tier-1 source 3 present and non-empty: /home/pera/ii-original-dots-backup`
> `[PASS] D-36 backup copy sha256 matches the pre-adopt fixture (3d17932a…)`

`[VERIFIED: ./scripts/phase14-verify.sh run output, this session]`

**Planner action:** D-14's inline backup note must name `~/ii-original-dots-backup`. The timestamped directory should be described for what it is — the rotated *stale* backup, deliberately kept, not a rollback source. Same `checkpoint:human-verify` as A1 applies.

### Correction 3 — runbook §14 tier-1 source 3 points at the wrong directory (D-21 target)

`[VERIFIED: docs/phase14-adopt-runbook.md:334-336]`, verbatim:

> ```
> # 3. The rotated backup directory, last because it is the source D-36 exists to distrust.
> #    Use the timestamped directory section 5 created, or ~/ii-original-dots-backup/
> #    if section 5 did not run.
> ```

Per Correction 2, this is inverted: the timestamped directory holds a July config (`c5c65023…`), and `~/ii-original-dots-backup/` holds the actual pre-adopt conf (`3d17932a…`). An operator in a rollback following this line restores a stale config. This is the clearest instance of D-21 ("factually false post-adopt lines are corrected") and the highest-severity finding in the sweep, because it sits inside a recovery procedure.

Related, same file `[VERIFIED: docs/phase14-adopt-runbook.md:144]`:

> **Mandatory whenever the preflight's `ii-original-dots-backup` line came back as a `[FINDING]`** — which is whenever the directory exists, **as it does today**.

"as it does today" was written pre-adopt. Post-adopt the directory exists again but now *is* rollback source 3, so rotating it is exactly the wrong move. This is the runbook-side twin of IN-11 and needs a post-adopt caveat, not deletion of the section (D-02 preserves structure).

---

## Architecture Patterns

### Documentation flow

```
                     ┌─────────────────────────────────────────┐
                     │ Operator on a COLD machine (D-04 frame)  │
                     └────────────────────┬────────────────────┘
                                          │
                    docs/dots-hyprland-workflow.md  ← THE rewrite (D-01)
                                          │
        ┌──────────┬──────────┬───────────┼───────────┬──────────┬──────────┐
        ▼          ▼          ▼           ▼           ▼          ▼          ▼
     1 clone    2 pin    GATE (D-13)   3 install   4 session  5 verify  6 update
        │          │          │           │           │          │          │
        │          │          │      profile fork     │          │          │
        │          │          │      stated in place  │          │          │
        │          │          │      (D-03, D-06/07)  │          │          │
        │          │          │           │           │          │          │
        │          │          ▼           ▼           ▼          ▼          │
        │          │   ┌──────────┐  ┌─────────┐ ┌────────┐ ┌─────────┐    │
        │          │   │10-INVENT.│  │ help =  │ │hyprland│ │ -j      │    │
        │          │   │11-DISPOS.│  │ flag SoT│ │ .lua   │ │ status  │    │
        │          │   └──────────┘  └─────────┘ └────────┘ └─────────┘    │
        │          │       cited        cited     D-08      Correction 1   │
        │          │                                  │                     │
        ▼          ▼                                  ▼                     ▼
   git clone  gitlink SHA                   DOC-04 overlay section    gitlink bump
   --recurse  1a9ffb78…                     narrates 13-SOT-APPLY.md   + re-run
                                                     │
                    ┌────────────────────────────────┴──────────────┐
                    ▼                                               ▼
          repo .config/hypr/custom/  ──── one-way cp -a ────►  ~/.config/hypr/custom/
             (AUTHORING SoT)          named files only            (applied copy)
                                    general/env/execs.lua
                                            │
                                            ✗ never into vendor/ or the fork (D-04)

     ┌──────────────────── cited, never copied (D-02) ────────────────────┐
     ▼                                                                    │
  docs/phase14-adopt-runbook.md §14  ── three-tier rollback ──────────────┘
     │
     └─► tier 1 (3 config sources) → tier 2 (wrapper uninstall) → tier 3 (protect)
              ⚠ HAZARD: tier 2 mutates tier-1 source 2 — see Pitfall 4
```

### Recommended structure of the rewritten playbook

Discretionary per CONTEXT.md, but this shape satisfies D-03 (one linear spine), D-13 (gate before install), and D-06/D-07 (safe defined next to full without a second track):

```
docs/dots-hyprland-workflow.md
├── Purpose                 # D-10: drop the dual-run destination claim
├── Prerequisites           # D-10: make the ~/.config/hypr line conditional on profile
├── Profiles: safe vs full  # D-06 + D-07 — two paragraphs + D-11 flag-axis table
├── Canonical path          # unchanged (vendor/dots-hyprland only)
├── 1. Clone & submodule init
├── 2. Verify fork remotes & pin
├── 3. Before any full install: inventory → disposition → adopt   # D-13 GATE, before §4
├── 4. Install                # walks FULL end to end (D-05); backup gate inline (D-14)
├── 5. Session model          # FULL only (D-08); safe conf-hook = one pointer line
├── 6. Overlays: repo/live/fork SoT   # DOC-04 (D-16)
├── 7. Verify                 # copy-pasteable, corrected probes (D-15 + Correction 1)
├── 8. Known losses after full adopt  # D-17
├── 9. The repo .config/hypr/hyprland.conf — three roles  # D-18 (WR-02)
├── 10. Update contract (pin-bump)
├── 11. Non-goals
└── See also                  # D-23 link integrity
```

### Pattern 1: Narrative summarises, but names its SoT

Established repo practice `[VERIFIED: 15-CONTEXT.md:123]`: "One SoT per surface: wrapper help for flags, `13-SOT-APPLY.md` for overlay policy, runbook §14 for rollback. Narrative may summarise; it must name the SoT it summarises."

The current playbook already does this `[VERIFIED: docs/dots-hyprland-workflow.md:16]`:

```markdown
> **Flag / subcommand details:** keep DRY — run `./arch/dots-hyprland.sh help` for the full
> allowlist, safe defaults, backup gate, uninstall, and protect behavior. This doc does not
> re-copy the entire help text.
```

Keep this sentence's shape. It is what makes D-11's table legal alongside D-12's prohibition.

### Pattern 2: Extract-and-run, so prose and check cannot diverge

`scripts/phase13-d19-assert.sh` does not *copy* the D-19 checks — it parses the fenced block out of `13-SOT-APPLY.md` and executes it `[VERIFIED: scripts/phase13-d19-assert.sh:28-42]`:

```bash
FENCE="$(python3 - "$SOT" <<'PY'
from pathlib import Path
import sys
text = Path(sys.argv[1]).read_text()
idx = text.find("## In-repo verify (D-19)")
if idx < 0:
    raise SystemExit("D-19 heading missing")
rest = text[idx:]
start = rest.find("```bash")
end = rest.find("```", start + 7)
if start < 0 or end < 0:
    raise SystemExit("D-19 bash fence missing")
print(rest[start + 7:end].lstrip("\n"), end="")
PY
```

This is the strongest available answer to "how do you deterministically verify prose?" and it is already proven in this repo. If the planner wants the playbook's D-15 verify block to be self-checking, this is the pattern to reuse — extract the block from the playbook and run it, so a wrong command in the doc is a failing test rather than a latent trap. Given Correction 1, that protection has demonstrable value here.

### Pattern 3: Never PASS an unobservable condition

`scripts/phase14-verify.sh` header, verbatim `[VERIFIED: scripts/phase14-verify.sh:12-16]`:

> Never reports a [PASS] for a condition it could not observe. An unobservable condition emits [INFO] or [FINDING], never a pass and never a silent skip. The same rule runs in the other direction: an unobservable condition is never reported as a specific defect either.

Any Phase 15 verification the planner writes should honour this. A `grep` that cannot find the playbook file must FAIL loudly, not silently pass on an empty match.

### Anti-Patterns to Avoid

- **Restating remembered flags.** CONTEXT.md explicitly warns "Read the current help text rather than restating remembered flags" `[VERIFIED: 15-CONTEXT.md:113]`. Corrections 1 and 2 exist because remembered strings drifted from reality.
- **Writing "chrome".** Phase 14 D-39 requires `Waybar/rofi/swaync` literally `[VERIFIED: 15-CONTEXT.md:31]`. Note the repo's own D-15 lint precedent: word-boundary matching, because `profile` contains `rofi` `[VERIFIED: .planning/PROJECT.md:210]`. Any grep the planner writes for `rofi` must use `\brofi\b` or it will match `profile` throughout the playbook.
- **Editing `STATE.md` / `ROADMAP.md` directly.** D-22 hard guard.
- **Rewriting frozen phase artifacts.** D-22: flag, don't rewrite.
- **Editing `scripts/phase14-preflight.sh`.** D-19: docs-only this phase; read it, don't fix it.
- **Copying runbook §14 tiers into the playbook.** D-14/D-02: cite only.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Proving the session is on the Lua entry | A bespoke config-file inspection | `hyprctl -j status \| jq -r .configProvider`, plus `hyprctl eval 'return 1+1'` | Both already implemented and dispositioned in `phase14-verify.sh:168-200`; file inspection cannot tell you what the compositor *loaded* |
| Post-adopt machine verification | A new verify script for the playbook | Cite and reuse `scripts/phase14-verify.sh` | It is green today, encodes ADOPT-02/03/04 + D-36/D-37/D-38, and already refuses to pass unobservable conditions |
| In-repo overlay verification | New overlay checks in the playbook | Cite `scripts/phase13-d19-assert.sh` / `13-SOT-APPLY.md` §D-19 | 15 asserts, currently all PASS; D-16 says the playbook narrates the SoT, not replaces it |
| Flag reference | A full flag table in the playbook | `./arch/dots-hyprland.sh help` | D-12 forbids it, and the help text is generated from the live script so it cannot go stale |
| Rollback instructions | A playbook rollback section | Runbook §14 citation | D-02/D-14 |
| Backup rotation guidance | New rotation prose | Nothing — record IN-11 as deferred | D-19; and post-adopt rotation is actively harmful (Pitfall 3) |

**Key insight:** every claim the playbook needs to make already has an executable owner in this repo that is currently green. The failure mode in this phase is not missing information — it is *re-typing* information that an existing script already asserts, and typing it slightly wrong. Corrections 1 and 2 are exactly that failure, caught before it shipped. Prefer "cite the script, quote its probe verbatim" over "describe the check in prose".

## Common Pitfalls

### Pitfall 1: Writing the CONTEXT.md verification command as-is

**What goes wrong:** The playbook's headline verification, `hyprctl getoption configProvider`, returns `no such option`. The first operator to paste it concludes the adopt failed.
**Why it happens:** D-08/D-15 were written from memory of what the check *means*, not from the script that performs it. `getoption` reads Hyprland config *variables*; `configProvider` is compositor *status*, exposed only through `hyprctl -j status`.
**How to avoid:** Use `hyprctl -j status | jq -r .configProvider`. Cross-check every command in the rewritten playbook against `scripts/phase14-verify.sh` before committing.
**Warning signs:** any playbook command that appears nowhere in `scripts/*.sh`.

### Pitfall 2: Naming the timestamped directory as the backup

**What goes wrong:** The playbook tells the operator their rollback material is in `~/ii-original-dots-backup.20260904T171128Z`, which contains a July config, not the pre-adopt one.
**Why it happens:** The timestamp *looks* like the adopt date (2026-09-04), so it reads as "the backup from the adopt". It is actually the timestamp of the **rotation that moved the old backup aside** immediately before the adopt.
**How to avoid:** Name `~/ii-original-dots-backup` (the fresh one). Verify with `sha256sum` against `14-PRE-ADOPT-BASELINE.txt` rather than trusting the name.
**Warning signs:** a backup directory whose mtime predates the adopt window.

### Pitfall 3: Recommending `--rotate-backup` post-adopt (IN-11)

**What goes wrong:** `scripts/phase14-preflight.sh:264` still prints, verbatim `[VERIFIED: scripts/phase14-preflight.sh:264]`:

> `BK_MSG="$BK_MSG Remediation: ./scripts/phase14-preflight.sh --rotate-backup (runbook section 5; mandatory before go)."`

Post-adopt, `~/ii-original-dots-backup` *is* rollback tier-1 source 3. Rotating renames it away.
**Why it happens:** The message is unconditional and was correct pre-adopt.
**How to avoid:** D-19 — the script is not edited this phase. If the playbook mentions `--rotate-backup`, it states it must not be run post-adopt. Record IN-11 as a deferred fix with an owner.
**Warning signs:** any post-adopt preflight run that reports the backup line as a `[FINDING]` and offers rotation as the remedy.
**Bounded:** it is a rename, not a delete, and tier-1 sources 1 and 2 are unaffected `[VERIFIED: .planning/STATE.md:106]`.

### Pitfall 4: Treating the runbook's rollback tiers as independently safe (WR-02 / D-18)

**What goes wrong:** Rollback tier 2 destroys the byte-identity of rollback tier-1 source 2.

Post-adopt, live `~/.config/hypr/hyprland.conf` does not exist `[VERIFIED: ls ~/.config/hypr/ this session — only hyprland.conf.old and hyprland.conf.bak]`, so the wrapper's hook-target list resolves to the repo copy alone `[VERIFIED: arch/dots-hyprland.sh list_hypr_ii_hook_target_files]`:

```bash
local -a candidates=(
  "${XDG_CONFIG_HOME}/hypr/hyprland.conf"
  "${REPO_ROOT}/.config/hypr/hyprland.conf"
)
```

Demonstrated live:

```
$ ./arch/dots-hyprland.sh uninstall --dry-run
[CONFIG] dry-run: would delete ii hooks in:
[CONFIG] dry-run:   /home/pera/github_repo/.dotfiles/.config/hypr/hyprland.conf
```

`[VERIFIED: live dry-run, this session]`

The repo copy currently carries both hook lines — `exec-once = qs -c ii` at line 67 and `env = ILLOGICAL_IMPULSE_VIRTUAL_ENV,~/.local/state/quickshell/.venv` at line 111 `[VERIFIED: .config/hypr/hyprland.conf:67,111]` — and hashes to the pre-adopt fixture. Deleting them changes its sha256, so `phase14-verify.sh`'s `check_tier1_source 2` flips to `[FAIL]`, and the operator loses a rollback source *while escalating the rollback*.
**Why it happens:** the file legitimately holds three roles (rollback source, frozen D-36 evidence, hook-injection target) and the wrapper only knows about the third.
**How to avoid:** D-18's section states the role split and the ordering consequence — copy source 2 out before escalating to tier 2. Content is recoverable from git history, so exposure is bounded `[VERIFIED: .planning/STATE.md:105]`.
**Warning signs:** `phase14-verify.sh` reporting `ADOPT-04 tier-1 source 2 is <sha>, fixture recorded 3d17932a…`.
**Currently latent:** a forward install reports `ii hooks already active (no change)` `[VERIFIED: install-files --dry-run, this session]`, so only `uninstall` triggers it.

### Pitfall 5: `rofi` matching `profile` in sweep greps

**What goes wrong:** A `grep -c rofi` over a playbook full of the word "profile" returns nonsense; a "forbidden string" assertion built on it fails permanently.
**Why it happens:** substring matching. The repo hit this before — `10-INVENTORY.md`'s assert harness needed word-boundary lint for exactly this reason `[VERIFIED: .planning/PROJECT.md:210]`: "Phase 10: Assert harness with word-boundary D-15 lint | Avoid false positives (`profile` ⊃ `rofi`)".
**How to avoid:** `grep -E '\brofi\b'` in every Phase 15 assertion. This phase's playbook will contain the word "profile" many times by construction (DOC-03).
**Warning signs:** a `rofi` count far exceeding the number of times the trio is mentioned.

### Pitfall 6: Letting D-05 read as a default change

**What goes wrong:** The playbook walks `--full` end to end (D-05) and a reader concludes full is now the default, contradicting `REQUIREMENTS.md`'s Out of Scope row.
**Why it happens:** the linear spine has one walkthrough, and it is the full one.
**How to avoid:** D-07's explicit sentence. The wrapper's own help is unambiguous and quotable `[VERIFIED: ./arch/dots-hyprland.sh help, this session]`: "Default install / install-files without --full still inject the triple."
**Warning signs:** no occurrence of the words "default" and "safe" in the same paragraph as `--full`.

## Code Examples

### Flag Axes — Verified Ground Truth (D-11 source material)

The three axes, with what injecting and dropping each does. Verified against the script, not memory.

`SAFE_DEFAULTS` verbatim `[VERIFIED: arch/dots-hyprland.sh:12]`:

```bash
SAFE_DEFAULTS=(--core --skip-hyprland --skip-sysupdate)
```

Injection logic verbatim `[VERIFIED: arch/dots-hyprland.sh:1444-1452]`:

```bash
local -a cmd=(./setup "$subcmd")
if needs_safe_defaults "$subcmd" && ((full == 0)); then
  echo "[CONFIG] safe defaults: ${SAFE_DEFAULTS[*]}"
  cmd+=("${SAFE_DEFAULTS[@]}")
elif needs_safe_defaults "$subcmd" && ((full == 1)); then
  echo "[CONFIG] full profile: no SAFE_DEFAULTS injection (DISP-02 drop-all-three)"
fi
```

`--full` scope guard verbatim `[VERIFIED: arch/dots-hyprland.sh:1420-1424]`:

```bash
# D-02: --full only valid on install / install-files (same scope as SAFE_DEFAULTS)
if ((full == 1)) && ! needs_safe_defaults "$subcmd"; then
  echo "[FAIL] --full is only valid with install or install-files." >&2
  echo "[FAIL] Refusing --full on subcommand: $subcmd" >&2
```

Real `help` text for the axes `[VERIFIED: ./arch/dots-hyprland.sh help, this session]`:

```
Safe defaults (injected for install and install-files only — unless --full):
  --core --skip-hyprland --skip-sysupdate
  Protects personal hyprland.conf (full --skip-hyprland, not entry-only).
  Skips unattended full system package upgrade. install-deps / install-setups get no injection.
  Never auto-injects --force or --skip-allgreeting.
```

Full-path blast radius, verbatim from the gate `[VERIFIED: arch/dots-hyprland.sh:177-183]`:

```bash
echo "[CONFIG] FULL PROFILE: no SAFE_DEFAULTS residual injection on this path."
echo "[CONFIG] FULL PROFILE: personal hyprland.conf may be renamed to .old by upstream install."
echo "[CONFIG] FULL PROFILE: misc overlay may overwrite when core residual is absent."
echo "[CONFIG] FULL PROFILE: sysupdate / pacman -Syu may run on the deps portion of install."
echo "[CONFIG] FULL PROFILE: upstream may backup clashing paths to: ~/ii-original-dots-backup"
echo "[CONFIG] FULL PROFILE: bare skip-backup is still refused without dual-key allow override."
```

Assembled table the planner can adapt (all three rows sourced above, plus `PROJECT.md:165` for the drop-`--skip-hyprland` effects `[VERIFIED: .planning/PROJECT.md:165]`):

| Axis | Injected (safe default) | Dropped (`--full`) |
|------|-------------------------|--------------------|
| `--skip-hyprland` | Personal `hyprland.conf` is not renamed or replaced. Full skip, not entry-only. | Upstream renames `hyprland.conf` → `.old`, syncs the ii `hypr/hyprland` Lua tree, installs `hyprland.lua`, backs up/replaces hyprlock + hypridle. |
| `--core` | Core install path only; misc overlay not applied. | Misc overlay may overwrite; without `--core` the install also touches fish/kitty/starship/misc. |
| `--skip-sysupdate` | No unattended full system upgrade. | `pacman -Syu` may run on the deps portion of `install`. |

**Scope note for the table:** injection applies to `install` and `install-files` only; `install-deps` and `install-setups` get no injection at all `[VERIFIED: help text, "install-deps / install-setups get no injection"]`.

### Backup gate — Verified Ground Truth (D-14 source material)

Refusal logic verbatim `[VERIFIED: arch/dots-hyprland.sh:1430-1434]`:

```bash
# D-12: refuse bare --skip-backup unless --allow-skip-backup (before gate)
if user_flags_contain "--skip-backup" user_flags && ((allow_skip_backup == 0)); then
  echo "[FAIL] --skip-backup refused without --allow-skip-backup." >&2
  echo "[FAIL] First adoption must not skip backup. Re-run with --allow-skip-backup only if you intentionally override." >&2
```

The gate token is exact `[VERIFIED: arch/dots-hyprland.sh:~190]`:

```bash
echo "[CONFIG] Type 'yes' to continue (exact token required)."
local ans
read -r -p "Type 'yes' to continue: " ans
if [[ "$ans" != "yes" ]]; then
  echo "[FAIL] Aborted (backup gate). No ./setup invoked." >&2
```

Backup dir default `[VERIFIED: arch/dots-hyprland.sh:21]`:

```bash
II_BACKUP_DIR="${BACKUP_DIR:-$HOME/ii-original-dots-backup}"
```

Note this confirms Correction 2 independently: the wrapper's own default — the path upstream backs up to — has no timestamp suffix.

### Post-install verification — corrected D-15 block

Copy-pasteable, every command verified live this session, expected output as observed:

```bash
# 1. The compositor is on the Lua entry (was 'hyprlang' pre-adopt)
hyprctl -j status | jq -r .configProvider
# expect: lua

# 2. Token-independent confirmation the Lua config manager is live
hyprctl eval 'return 1+1'
# expect: ok

# 3. The ii shell is running
pgrep -f 'qs -c ii' >/dev/null && echo "qs -c ii running"
# expect: qs -c ii running

# 4. Upstream renamed the previous conf; no .conf can win over the Lua entry
test -f ~/.config/hypr/hyprland.lua     && echo "lua entry present"
test -f ~/.config/hypr/hyprland.conf.old && echo "pre-adopt conf archived"
test ! -f ~/.config/hypr/hyprland.conf   && echo "no competing hyprland.conf"

# 5. Personal overlays applied
ls ~/.config/hypr/custom/{general,env,execs}.lua

# 6. Full check — the executable SoT for everything above
./scripts/phase14-verify.sh
# expect: === done: FAIL=0 FINDINGS=1 ===   (the 1 finding is D-38, see Known losses)
```

`[VERIFIED: each command run live this session; phase14-verify.sh output "=== done: FAIL=0 FINDINGS=1 ==="]`

Failures point at `docs/phase14-adopt-runbook.md` §14, per D-15. No failure-branch tree.

### Overlay SoT — Verified Ground Truth (DOC-04 / D-16 source material)

Policy verbatim `[VERIFIED: .planning/phases/13-personal-hypr-custom-overlays/13-SOT-APPLY.md:7-13,25]`:

> Authoring SoT is parent-repo `.config/hypr/custom/` (D-01, D-05). Edit overlays there. Live `~/.config/hypr/custom/` is an applied copy, not the place you edit for the next machine.
>
> Vendor/submodule `vendor/dots-hyprland` and the personal fork remain product SoT. Never commit machine overlays into vendor or the fork (D-04).
>
> Apply is one-way repo → live after the full files install. There is no sync daemon. Persist a live tweak by copying it back into repo `.config/hypr/custom/` (D-03).
>
> Named files only: `general.lua`, `env.lua`, `execs.lua`. Never `rsync --delete`. Never copy `keybinds.lua`, `rules.lua`, or `variables.lua`. Overwrite ii seeds if present.

Apply command verbatim `[VERIFIED: 13-SOT-APPLY.md:31-53]`:

```bash
set -euo pipefail
REPO_CUSTOM=".config/hypr/custom"
LIVE_CUSTOM="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/custom"

mkdir -p "$LIVE_CUSTOM"

# Fail if repo general.lua is missing (layout required).
if [ ! -f "$REPO_CUSTOM/general.lua" ]; then
  echo "FAIL: repo $REPO_CUSTOM/general.lua is missing; abort apply" >&2
  exit 1
fi
cp -a "$REPO_CUSTOM/general.lua" "$LIVE_CUSTOM/"

for slot in env.lua execs.lua; do
  if [ -f "$REPO_CUSTOM/$slot" ]; then
    cp -a "$REPO_CUSTOM/$slot" "$LIVE_CUSTOM/"
  else
    echo "WARN: repo $REPO_CUSTOM/$slot missing; continuing without it" >&2
  fi
done
```

**Live-vs-repo state confirming the one-way model** — note the asymmetry the playbook should explain: repo `.config/hypr/custom/` holds exactly the three named files, while live `~/.config/hypr/custom/` additionally holds `keybinds.lua`, `rules.lua`, `variables.lua` and `scripts/` — upstream ii seeds that the apply deliberately never touches `[VERIFIED: ls of both directories, this session]`. `phase13-d19-assert.sh` asserts precisely this: `[PASS] repo has no custom/keybinds.lua — D-18 fence cannot widen to it` (same for `rules.lua`, `variables.lua`) `[VERIFIED: assert run output, this session]`.

Fork-boundary check, verbatim from the D-19 fence `[VERIFIED: 13-SOT-APPLY.md:82]`:

```bash
test -z "$(git -C vendor/dots-hyprland status --short -- dots/.config/hypr/custom)"
```

### Known losses — Verified Ground Truth (D-17 source material)

Every claim confirmed on the live machine this session:

| Item | Live state | Evidence |
|------|-----------|----------|
| `hyprland-session.service` | `inactive` | `systemctl --user is-active hyprland-session.service` → `inactive` |
| `graphical-session.target` | `inactive` | `systemctl --user is-active graphical-session.target` → `inactive` |
| Unit file itself | **survives** | symlink `~/.config/systemd/user/hyprland-session.service → …/stow/systemd/.config/systemd/user/hyprland-session.service` |
| `wl-clip-persist` | not running | `pgrep -a wl-clip-persist` → no match |
| `hyprpaper` | stopped-but-installed | `pgrep -x hyprpaper` → no match; `~/.config/hypr/hyprpaper.conf` present |
| Waybar / swaync | not running | `pgrep -x` → no match; `phase14-verify.sh` `[PASS] … accept-remove` |
| Archived trees | present | `stow/waybar`, `stow/rofi`, `stow/swaync` all exist |

`[VERIFIED: live probes, this session]`

`phase14-verify.sh` reports the ScreenCast consequence as a FINDING, not a failure `[VERIFIED: phase14-verify.sh run output, this session]`:

> `[FINDING] D-38 graphical-session.target is inactive — hyprland-session.service lost its autostart with the renamed conf (expected). This is why screen share may be broken. Phase 15 item.`
> `[INFO] D-38 ScreenCast portal answers AvailableSourceTypes = 'u 7', unchanged from pre-adopt`
> `[INFO] D-38 the personal session unit file SURVIVES in the repo at stow/systemd/.config/systemd/user/hyprland-session.service — only its autostart line is gone, this is not a deletion`

The runbook's own framing, which the playbook should stay consistent with `[VERIFIED: docs/phase14-adopt-runbook.md:293-296]`, names the four workspace-pinned autostarts: `google-chrome-stable` on workspace 1, `kitty -e tmux` on workspace 1, `btop` on its special workspace, and `discord` on `special:social`.

Useful nuance for D-17's honesty: the portal's `AvailableSourceTypes` is *unchanged*, so "screen share **may** be affected" is the accurate wording — the loss is the session-bootstrap target, not the portal itself. Do not overstate it as "screen share is broken".

## Doc Sweep Inventory (D-20 / D-22 scope)

The sweep is a first-class deliverable `[VERIFIED: 15-CONTEXT.md:73]`. Here is the enumerated, file:line scope so the planner can bound it rather than leave it open-ended.

### `docs/dots-hyprland-workflow.md` — rewritten in place (D-01)

D-10's three named targets, quoted verbatim:

| Line | Stale text | Disposition |
|------|-----------|-------------|
| 14 | "This playbook is the Install/Adopt source of truth so a cold machine can reach dual-run (`waybar` + `qs -c ii`) without tribal knowledge." | Delete the dual-run destination (D-10) |
| 23 | "**Hyprland** session already running; you own personal `~/.config/hypr` (wrapper defaults **do not** replace `hyprland.conf`)" | Make conditional on profile (D-10) |
| 196–197 | "- `qs -c ii` runs alongside — **both bars OK** even if they overlap" / "- **No Waybar cutover** required for this milestone" | Delete the framing (D-10) |

Additional stale lines found this session, not named in D-10 but inside the rewrite scope:

| Line | Stale text | Why stale |
|------|-----------|-----------|
| 41 | Outline entry "Session hooks & dual-run expectations" | §4 is being replaced by the full session model (D-08) |
| 145–149 | "At the **backup gate**, type `yes`… Upstream backup directory: `~/ii-original-dots-backup`" | The path is right; the surrounding text describes only the safe path and needs the full-path gate messaging (D-14) |
| 174–181 | "### Personal hypr hooks (two lines)" + the two-line block presented as the session model | Now the *safe*-profile method only; D-08 demotes to a one-line pointer |
| 193 | "### Dual-run (intentional this milestone)" | Contradicts D-09 |
| 293 | "\| **Full Waybar / rofi / swaync cutover** \| Out of scope this milestone \| Dual-run is intentional; custom ports deferred (CUST-*). \|" | The removal was accepted (Phase 11 D-11); only the *module ports* remain deferred |
| 294 | "\| **Full hyprland.lua / ii hypr tree takeover** \| Out of scope this milestone \| Personal hypr conf remains SoT via `--skip-hyprland`. \|" | Directly false — this is exactly what the Phase 14 adopt did |
| 296 | "use manual dual-run checks in §4" | §4 is being replaced |
| 168 | "…so personal hypr gets the dual-run lines in **both** `~/.config/hypr/hyprland.conf` and the repo `.config/hypr/hyprland.conf`" | Live `hyprland.conf` no longer exists post-adopt; only the repo copy remains a target (Pitfall 4, D-18) |
| 161–162 | Subcommand table rows describing `uninstall` / `protect` as "dual-run" | Wording only; the behaviour is unchanged. Low priority. |

`[VERIFIED: docs/dots-hyprland-workflow.md, read in full this session]`

### `docs/phase14-adopt-runbook.md` — corrections only, structure preserved (D-02 / D-21)

| Line | Stale/false text | Severity |
|------|-----------------|----------|
| 334–336 | Tier-1 rollback source 3 points at the timestamped directory | **HIGH** — Correction 3; wrong config in a recovery path |
| 144 | "which is whenever the directory exists, **as it does today**" | MEDIUM — pre-adopt framing; post-adopt the directory is rollback source 3 and must not be rotated |
| 117 | "`~/ii-original-dots-backup` exists on this machine today and the `hyprland.conf` inside it is older than the live one." | MEDIUM — was true pre-adopt, false now (it is now byte-identical to the pre-adopt fixture) |
| 199 | "`custom/` is seeded, and only because live currently has none." | LOW — "currently" is a pre-adopt tense; live now has the applied overlay |

`[VERIFIED: docs/phase14-adopt-runbook.md:117,144,199,334-336]`

Structure to preserve (D-02) — full section list `[VERIFIED: grep of headings, this session]`: Purpose, Outline, 1 Prerequisites, 2 Recording, 3 Go/no-go gate, 4 Banned flags, 5 Rotate stale backup, 6 Stop Hyprland, 7 Run install, 8 Apply overlay, 9 Re-stow kitty, 10 Reboot, 11 Log in, 12 Verify, 13 Known losses, 14 Rollback, See also. **§14 is the three-tier rollback the playbook cites** — tier 1 (three config sources, opened by moving `hyprland.lua` aside), tier 2 (`./arch/dots-hyprland.sh uninstall --configs-only`), tier 3 (`protect`), plus a Prohibition against upstream `./setup uninstall`.

### `README.md` — one line

| Line | Stale text | Disposition |
|------|-----------|-------------|
| 7 | "**Operator playbook** (clone → recursive submodule → install → dual-run → pin-bump update):" | Replace `dual-run` with the profile-neutral sequence; the link on line 9 stays valid (D-23) |

`[VERIFIED: README.md:7,9]`

### `arch/README.md` — **nothing stale**

Read in full (145 lines). It is entirely Arch OS bootstrap: pacman base install, `useradd`, `visudo`, `bootctl`, `loader.conf`, `arch.conf`, `efibootmgr`, chroot exit. It contains **zero** references to dots-hyprland, dual-run, Waybar/rofi/swaync, `hyprland.conf`, or the wrapper. `[VERIFIED: arch/README.md, read in full this session — grep for dual-run|waybar|hyprland|dots-hyprland returns no matches]`

The sweep should record this explicitly as "reviewed, no findings" so the planner does not budget work for it.

### `.planning` prose — read-only review + report, with the `PROJECT.md` exception (D-22)

`PROJECT.md` product-surface lines that are **now false** and fall inside D-22's correction exception:

| Line | False text | Correction |
|------|-----------|------------|
| 18 | "…the session now loads through `hyprland.lua` (`hyprctl getoption configProvider` → `lua`)…" | Wrong probe — Correction 1. Should be `hyprctl -j status` → `configProvider: lua` |
| 28 | "Rollback: `~/ii-original-dots-backup.20260904T171128Z` (tier 1) + `hyprland.conf.old`; runbook `docs/phase14-adopt-runbook.md` §14" | Wrong directory — Correction 2. Should be `~/ii-original-dots-backup` |

`[VERIFIED: .planning/PROJECT.md:18,28]`

Lines that are **correct and should not be touched** (checked because they contain trigger words): `PROJECT.md:8,27,161,220` all already state the post-adopt truth ("Waybar/rofi/swaync no longer dual-run", "accept-removed at the Phase 14 full adopt (D-11)"). `PROJECT.md:41,43,56,58,105,109,117,132,194,197` are historical milestone/phase records or forward-looking backlog and are correct in their tense. `[VERIFIED: .planning/PROJECT.md, grep review this session]`

Guarded — flag in the report, never edit:

- `STATE.md`, `ROADMAP.md` — `gsd-tools.cjs` query handlers only (D-22). Note `STATE.md:104` currently records the D-38 item as "**no owning phase**"; D-17 answers it. That state change goes through the tooling, not an edit.
- Frozen phase artifacts — `1X-CONTEXT.md`, `1X-SUMMARY.md`, `1X-VERIFICATION.md`, `10-INVENTORY.md`, `11-DISPOSITIONS.md`, `13-SOT-APPLY.md`. **Includes `15-CONTEXT.md` itself**, which carries the Correction 1 and 2 errors at lines 30, 39, 40, 127. Flag them in the report; the playbook is written correctly regardless.

### Cross-reference integrity (D-23) — current baseline: all green

Every relative link in the three prose docs resolves today `[VERIFIED: link-existence loop over docs/dots-hyprland-workflow.md, docs/phase14-adopt-runbook.md, README.md, this session]`:

```
OK  docs/dots-hyprland-workflow.md -> ../.planning/PROJECT.md
OK  docs/dots-hyprland-workflow.md -> ../.planning/REQUIREMENTS.md
OK  docs/dots-hyprland-workflow.md -> ../.planning/ROADMAP.md
OK  docs/dots-hyprland-workflow.md -> ../README.md
OK  docs/phase14-adopt-runbook.md  -> ./dots-hyprland-workflow.md
OK  docs/phase14-adopt-runbook.md  -> ../.planning/phases/13-personal-hypr-custom-overlays/13-SOT-APPLY.md
OK  docs/phase14-adopt-runbook.md  -> ../.planning/phases/11-disposition-decisions/11-DISPOSITIONS.md
```

The rewrite adds citations to `10-INVENTORY.md` (D-13) and `13-SOT-APPLY.md` (D-16); both files exist `[VERIFIED: ls, this session]`. The "See also" currently cites Phase 9 success criteria (line 308) — that reference should become Phase 15's.

## Runtime State Inventory

This is a documentation phase, not a rename/refactor of runtime state — but the *subject* of the documentation is live runtime state, so the categories are answered for what the playbook must assert.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None. No database, datastore, or keyed record is touched or described. | None |
| Live service config | `hyprland-session.service` symlink present but unit `inactive`; `graphical-session.target` `inactive` (D-38). Not changed by this phase — documented only per D-17. | Documentation only (D-17) |
| OS-registered state | Hyprland session running under the Lua config provider (`configProvider: lua`, was `hyprlang`); `qs -c ii` running as pid 1523; Waybar/swaync not running. Read-only observation. | None — documented in the D-15 verify block |
| Secrets/env vars | None. The only env var named is `ILLOGICAL_IMPULSE_VIRTUAL_ENV`, and only as a quoted safe-profile hook line. | None |
| Build artifacts | None. No package is installed or rebuilt. `vendor/dots-hyprland` stays pinned at `1a9ffb78f0c272a45f82342587dc3bec72762233` (`2026.05.11-109-g1a9ffb78`) `[VERIFIED: git submodule status, this session]`. | None |

**Working tree:** clean at research time `[VERIFIED: git status --short → empty, this session]`.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `hyprctl` | D-15 verify block | ✓ | Hyprland 0.56.2 (pkg 0.56.2-2) | — |
| running Hyprland instance | D-15 live probes | ✓ | instance `efb5099…_1788603184_1977123164` | Verify script emits `[INFO]`, never a false pass |
| `jq` | `configProvider` probe | ✓ | present | `hyprctl eval` as token-independent backup |
| `git` | pin verify, sweep | ✓ | present | — |
| `python3` | D-19 fence extraction in `phase13-d19-assert.sh` | ✓ | 3.14 (per `__pycache__` tags) | — |
| `luac` | overlay syntax check | ✓ | present (assert passes) | — |
| `pacman` | version confirmation only | ✓ | present | — |
| `scripts/phase14-verify.sh` | cited verification | ✓ | runs green: FAIL=0, FINDINGS=1 | — |
| `scripts/phase13-d19-assert.sh` | cited overlay verify | ✓ | runs green: FAIL=0, 15 PASS | — |

**Missing dependencies with no fallback:** none.
**Missing dependencies with fallback:** none.

Caveat worth recording: the D-15 verify block's first three commands require an **active Hyprland session**. A cold-machine reader following the playbook will be at a TTY at that point. The playbook should say the verify step runs after login, matching runbook §11→§12 ordering `[VERIFIED: docs/phase14-adopt-runbook.md:257,269]`.

## Validation Architecture

`workflow.nyquist_validation` is `true` `[VERIFIED: .planning/config.json]`, so this section is required. For a documentation phase, "validation" means deterministically verifying **prose claims**: required strings present, forbidden strings absent, links resolving, and quoted commands agreeing with the real scripts.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Bash assert script, repo-native pattern (no test runner exists or should be invented — CONVENTIONS.md: "Do not invent a CI linter") |
| Config file | none — the pattern is a self-contained `scripts/phaseNN-*-assert.sh` |
| Quick run command | `./scripts/phase15-docs-assert.sh` (to be created in Wave 0) |
| Full suite command | `./scripts/phase15-docs-assert.sh && ./scripts/phase13-d19-assert.sh && ./scripts/phase14-verify.sh` |

Existing precedent to copy: `scripts/phase13-d19-assert.sh` and `scripts/phase14-verify.sh` — both `set -euo pipefail`, `pass()`/`fail()` helpers, `FAIL` counter, non-zero exit `[VERIFIED: scripts/phase13-d19-assert.sh:9-17, scripts/phase14-verify.sh:32-41]`.

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DOC-03 | Playbook names both profiles | unit | `grep -qi 'safe profile' docs/dots-hyprland-workflow.md && grep -q '\-\-full' docs/dots-hyprland-workflow.md` | ❌ Wave 0 |
| DOC-03 | Flag-axis table covers all three axes | unit | `for f in skip-hyprland core skip-sysupdate; do grep -q -- "--$f" docs/dots-hyprland-workflow.md \|\| exit 1; done` | ❌ Wave 0 |
| DOC-03 | Safe defaults quoted match the script | agreement | see "Agreement checks" below | ❌ Wave 0 |
| DOC-03 | Gate precedes install (D-13 ordering) | ordering | see "Ordering check" below | ❌ Wave 0 |
| DOC-03 | Gate cites both artifacts | unit | `grep -q '10-INVENTORY.md' … && grep -q '11-DISPOSITIONS.md' …` | ❌ Wave 0 |
| DOC-03 | D-07 safe-is-still-default statement present | unit | `grep -qiE 'default.*(safe\|SAFE_DEFAULTS)' docs/dots-hyprland-workflow.md` | ❌ Wave 0 |
| DOC-04 | Overlay SoT + one-way direction stated | unit | `grep -q '.config/hypr/custom' … && grep -qiE 'one-way\|repo *→ *live\|repo->live' …` | ❌ Wave 0 |
| DOC-04 | Named-file `cp -a` apply, no `rsync --delete` | unit | `grep -q 'cp -a' … && ! grep -q 'rsync --delete' …` | ❌ Wave 0 |
| DOC-04 | Fork/vendor boundary stated | unit | `grep -q 'vendor/dots-hyprland' docs/dots-hyprland-workflow.md` | ❌ Wave 0 |
| DOC-04 | `13-SOT-APPLY.md` named as SoT | unit | `grep -q '13-SOT-APPLY.md' docs/dots-hyprland-workflow.md` | ❌ Wave 0 |
| D-09/D-39 | Literal trio, never "chrome" | forbidden-string | `! grep -qiE '\bchrome\b' docs/dots-hyprland-workflow.md` ⚠ see note | ❌ Wave 0 |
| D-10 | Three stale claims gone | forbidden-string | see "Forbidden strings" below | ❌ Wave 0 |
| D-15 | Verify block uses the working probe | agreement | `grep -q 'j status' … && ! grep -q 'getoption configProvider' …` | ❌ Wave 0 |
| D-23 | All relative links resolve | link check | see "Link check" below | ❌ Wave 0 |
| D-19 | preflight script untouched | guard | `git diff --quiet HEAD -- scripts/phase14-preflight.sh` | ❌ Wave 0 |
| D-22 | STATE/ROADMAP untouched | guard | `git diff --quiet HEAD -- .planning/STATE.md .planning/ROADMAP.md` | ❌ Wave 0 |

⚠ **`chrome` caveat:** the D-38 known-losses note legitimately names `google-chrome-stable` as one of the four workspace-pinned autostarts. A bare `\bchrome\b` ban would fire on it. Use `! grep -qiE '\bchrome\b' <(grep -v 'google-chrome' docs/dots-hyprland-workflow.md)`, or ban the specific phrasings (`dual-run chrome`, `bar chrome`, `shell chrome`). The planner must not ship the naive form.

### Concrete command shapes for `<automated>` verify blocks

Each has an observable failing signal. All follow the repo's `[PASS]`/`[FAIL]` convention.

**Agreement check — quoted safe defaults match the script.** Failing signal: the playbook drifts from `SAFE_DEFAULTS` after a future wrapper change.

```bash
PLAYBOOK="docs/dots-hyprland-workflow.md"
# Extract the array from the wrapper, verbatim, and require the doc to quote it.
SD="$(grep -oP '^SAFE_DEFAULTS=\(\K[^)]+' arch/dots-hyprland.sh)"   # → --core --skip-hyprland --skip-sysupdate
if grep -qF -- "$SD" "$PLAYBOOK"; then
  pass "playbook quotes SAFE_DEFAULTS verbatim: $SD"
else
  fail "playbook does not quote the live SAFE_DEFAULTS ($SD) — flag-axis table has drifted from arch/dots-hyprland.sh:12"
fi
```

**Agreement check — every `dots-hyprland.sh` subcommand the playbook names is allowlisted.** Failing signal: the doc invents or retains a refused subcommand.

```bash
HELP="$(./arch/dots-hyprland.sh help)"
for sub in $(grep -oP 'dots-hyprland\.sh \K[a-z-]+' "$PLAYBOOK" | sort -u); do
  case "$sub" in help) continue ;; esac
  if grep -qE "^  $sub " <<<"$HELP"; then
    pass "subcommand '$sub' is allowlisted in help"
  else
    fail "playbook names '$sub' but ./arch/dots-hyprland.sh help does not allowlist it"
  fi
done
```

**Agreement check — the verify block's compositor probe is the one the real script runs.** Failing signal: Correction 1 regressing.

```bash
if grep -q 'getoption configProvider' "$PLAYBOOK"; then
  fail "playbook uses 'hyprctl getoption configProvider' — returns 'no such option' on Hyprland 0.56.2; use 'hyprctl -j status'"
elif grep -q -- '-j status' "$PLAYBOOK" && grep -q 'configProvider' "$PLAYBOOK"; then
  pass "playbook uses the -j status probe, matching scripts/phase14-verify.sh:168-173"
else
  fail "playbook has no configProvider probe — D-15 verification is missing"
fi
```

**Agreement check — the backup path matches the wrapper default.** Failing signal: Correction 2 regressing.

```bash
if grep -qE 'ii-original-dots-backup\.[0-9]{8}T' "$PLAYBOOK"; then
  fail "playbook names the ROTATED (stale) backup dir as a rollback source — the adopt backup is ~/ii-original-dots-backup"
elif grep -q 'ii-original-dots-backup' "$PLAYBOOK"; then
  pass "playbook names the backup dir matching arch/dots-hyprland.sh:21 II_BACKUP_DIR default"
else
  fail "playbook does not name the backup directory — D-14 requires it inline at the install step"
fi
```

**Ordering check — D-13 gate appears before the install step.** Failing signal: gate written as a postscript.

```bash
GATE="$(grep -n '10-INVENTORY.md' "$PLAYBOOK" | head -1 | cut -d: -f1)"
INST="$(grep -nE '^\s*\./arch/dots-hyprland\.sh install' "$PLAYBOOK" | head -1 | cut -d: -f1)"
if [[ -n "$GATE" && -n "$INST" && "$GATE" -lt "$INST" ]]; then
  pass "D-13 inventory/disposition gate (line $GATE) precedes first install command (line $INST)"
else
  fail "D-13 violated: gate at '${GATE:-none}', first install at '${INST:-none}' — ADOPT-01 is a process gate and must come first"
fi
```

**Forbidden strings — D-10's three deleted claims.** Failing signal: a stale claim survives the rewrite.

```bash
declare -A FORBIDDEN=(
  ["dual-run (\`waybar\` + \`qs -c ii\`)"]="D-10: dual-run is no longer the destination"
  ["No Waybar cutover"]="D-10: the cutover framing is false post-adopt"
  ["wrapper defaults **do not** replace"]="D-10: unconditional claim; true only under the safe profile"
)
for s in "${!FORBIDDEN[@]}"; do
  if grep -qF -- "$s" "$PLAYBOOK"; then
    fail "stale claim survives: '$s' — ${FORBIDDEN[$s]}"
  else
    pass "stale claim removed: '$s'"
  fi
done
```

**Link check — D-23 cross-reference integrity.** Failing signal: a citation added by the rewrite points nowhere.

```bash
for f in docs/dots-hyprland-workflow.md docs/phase14-adopt-runbook.md README.md; do
  base="$(dirname "$f")"
  grep -o '](\.\{0,2\}/[^)]*)' "$f" | sed 's/](\(.*\))/\1/' | while read -r l; do
    if [[ -e "$base/$l" ]]; then
      pass "link resolves: $f -> $l"
    else
      fail "BROKEN link: $f -> $l"
    fi
  done
done
```

**Existence check — bare-path citations resolve too** (the playbook cites `.planning/...` paths in prose, not only as Markdown links):

```bash
for p in \
  .planning/phases/10-full-install-impact-inventory/10-INVENTORY.md \
  .planning/phases/11-disposition-decisions/11-DISPOSITIONS.md \
  .planning/phases/13-personal-hypr-custom-overlays/13-SOT-APPLY.md \
  docs/phase14-adopt-runbook.md ; do
  if grep -qF "$(basename "$p")" "$PLAYBOOK"; then
    [[ -f "$p" ]] && pass "cited artifact exists: $p" || fail "playbook cites missing artifact: $p"
  fi
done
```

**Scope guards — the phase fence is documentation-only.** Failing signal: the phase edited code.

```bash
if git diff --quiet HEAD -- arch/ scripts/ .config/ stow/ vendor/; then
  pass "scope fence held: no code/script/config changes in this phase"
else
  fail "scope violation: documentation phase modified $(git diff --name-only HEAD -- arch/ scripts/ .config/ stow/ vendor/ | tr '\n' ' ')"
fi
```

### Sampling Rate

- **Per task commit:** `./scripts/phase15-docs-assert.sh`
- **Per wave merge:** `./scripts/phase15-docs-assert.sh && ./scripts/phase13-d19-assert.sh`
- **Phase gate:** all three scripts green before `/gsd-verify-work`. `phase14-verify.sh` must still report `FAIL=0 FINDINGS=1` — the one finding is D-38 and is expected; a second finding means something regressed.

### Wave 0 Gaps

- [ ] `scripts/phase15-docs-assert.sh` — covers DOC-03, DOC-04, D-10, D-13, D-15, D-19, D-22, D-23 and the scope fence
- [ ] Framework install: none required — bash + grep + git only

Note: no `conftest`-style shared fixture is needed; the two existing assert scripts are self-contained and this one should be too.

## Security Domain

`workflow.security_enforcement` is `true`, `security_asvs_level: 1` `[VERIFIED: .planning/config.json]`.

### Applicable ASVS Categories

This phase writes Markdown prose. It ships no code, no service, no endpoint, no authentication surface, and no data handling. Most ASVS categories are vacuous here; they are answered rather than skipped.

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | No auth surface. The only credential mention is SSH-to-GitHub as a *prerequisite*, not something the doc configures |
| V3 Session Management | no | "Session" here means a Hyprland desktop session, not a web session |
| V4 Access Control | no | No access-control logic |
| V5 Input Validation | no | No input is processed. (The wrapper's own flag allowlist and `--skip-backup` dual-key gate are Phase 12 controls, unchanged) |
| V6 Cryptography | no | `sha256sum` is used for **integrity comparison against a recorded fixture**, not for a security control. Nothing is hand-rolled |
| V7 Error Handling & Logging | partial | Documented commands must not instruct the operator to suppress failures. Existing scripts already exit non-zero on `FAIL` |
| V12 File & Resource | partial | The doc instructs `cp -a` and `mv` operations under `$HOME`. All are named-file, never `rsync --delete` (13-SOT-APPLY.md D-18) |
| V14 Configuration | yes | The playbook's real security-relevant job: not documenting a destructive command incorrectly |

### Known Threat Patterns for this stack

The threats here are **operator-safety**, not attacker-driven. The realistic harm model is "a correct-looking instruction destroys the operator's ability to recover".

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Documenting the wrong rollback source (Correction 3) | Denial of Service (self-inflicted; loss of recovery) | Verify every named path by `sha256sum` against `14-PRE-ADOPT-BASELINE.txt` before writing it |
| Documenting `--rotate-backup` as post-adopt remediation (IN-11) | Tampering (renames away rollback source 3) | D-19: state it must not be run post-adopt |
| Documenting rollback tier 2 without the tier-1 side effect (WR-02) | Tampering (uninstall mutates the rollback source) | D-18 section states the ordering hazard; copy source 2 aside before escalating |
| Documenting bare `--skip-backup` casually | Denial of Service (no backup taken) | Quote the wrapper's dual-key refusal verbatim (FULL-03); never show a bare-`--skip-backup` example |
| Documenting upstream `./setup uninstall` as rollback | Elevation/DoS via package cascade | Explicitly out of scope in `REQUIREMENTS.md`; runbook §14 has a Prohibition. `--upstream-dangerous` requires typing `UPSTREAM-UNINSTALL` `[VERIFIED: help text]` — never present it as an option |
| Recommending `yay -Yc` / `pacman -Rns $(pacman -Qtdq)` after an ii install | Denial of Service (orphan cleanup deletes hyprland/kitty/fish) | The wrapper's `protect` subcommand exists precisely for this `[VERIFIED: help text]`. If the playbook mentions orphan cleanup at all, it must pair it with `protect` |

**Control that carries the security weight of this phase:** the Validation Architecture agreement checks. A doc assertion that fails when the playbook's quoted command diverges from the real script is the only durable defence against Corrections 1–3 recurring.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Safe dual-run: personal `hyprland.conf` + `qs -c ii` alongside Waybar/rofi/swaync | Full profile: `hyprland.lua` is the session entry, Waybar/rofi/swaync retired | Phase 14, 2026-09-04 | The playbook's entire §4 premise is obsolete |
| `hyprland.conf` hook injection as *the* session model | Hook injection is the **safe-profile** method only; live `hyprland.conf` no longer exists here | Phase 14 adopt | D-08: full model documented, safe gets a pointer line |
| `--skip-hyprland` always injected | `--full` opt-in drops all three residuals; default still injects | Phase 12 (FULL-01/FULL-02), smoke 2026-08-18 | D-06/D-07 must state both |
| `configProvider` = `hyprlang` | `configProvider` = `lua` | Phase 14 adopt | The pre-adopt value is recorded in `14-PRE-ADOPT-BASELINE.txt` |
| DISP-03 "default keep" for Waybar/rofi/swaync | Accept-remove per Phase 11 D-11 | Phase 11 | The `REQUIREMENTS.md` Out of Scope row's escape clause fired; the playbook must not repeat "out of scope this milestone" |

**Deprecated/outdated:**

- `hyprctl getoption configProvider` — never worked on Hyprland 0.56.2; use `hyprctl -j status`.
- Playbook §4 "Dual-run (intentional this milestone)" — superseded by the full session model.
- Playbook §6 rows for "Full Waybar / rofi / swaync cutover" and "Full hyprland.lua / ii hypr tree takeover" as out-of-scope — both happened.
- Runbook §14 tier-1 source 3 wording — points at the stale rotated backup.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The planner should override CONTEXT.md's literal `hyprctl getoption configProvider` (D-08/D-15) and `~/ii-original-dots-backup.20260904T171128Z` (D-14) strings with the verified values in Corrections 1–2. The *corrections themselves* are `[VERIFIED]`; what is `[ASSUMED]` is that the user wants the true value rather than the literal decision text. | Ground-Truth Corrections | Low technical risk, but it is a deviation from a locked decision. **Recommend a `checkpoint:human-verify` before the playbook is written**, presenting the probe output. |
| A2 | Correcting runbook §14 tier-1 source 3 (Correction 3) falls inside D-21's "factually false post-adopt lines are corrected" and does not violate D-02's "keeps its structure". | Doc Sweep | If read as structural change, the correction stalls — leaving a wrong instruction in a recovery path. Worth one confirmation. |
| A3 | The sweep should record `arch/README.md` as "reviewed, no findings" rather than skipping it silently. | Doc Sweep | None material; affects only sweep-report completeness. |
| A4 | `scripts/phase15-docs-assert.sh` is the right artifact for the Validation Architecture, versus inline `<automated>` blocks. CONVENTIONS.md names the script pattern but the choice is CONTEXT.md discretion. | Validation Architecture | A script adds a repo file to a "documentation only" phase. If the user reads the scope fence strictly as "no new files outside docs", use inline blocks instead. **Worth confirming** — the fence says "No code, wrapper, script, or session behaviour changes", which arguably forbids a new script. |
| A5 | The `STATE.md` D-38 ownership answer (D-17 closes it in favour of "documented here, fix unowned") is applied via `gsd-tools.cjs`, not by editing the file. | Doc Sweep | Violating D-22's hard guard if done wrong. |
| A6 | "Screen share **may** be affected" is the accurate D-17 wording, since the portal's `AvailableSourceTypes` is unchanged and only the session-bootstrap target is inactive. | Known losses | Overstating it as "screen share is broken" would misrepresent a documented FINDING. |

## Open Questions (RESOLVED)

> **All four resolved at planning time, 2026-09-05.** Each carries an inline `**RESOLVED:**` line naming
> the decision taken and the artifact it landed in. Nothing here is outstanding; the section is kept as the
> record of how each was decided.

1. **Does the scope fence permit `scripts/phase15-docs-assert.sh`?**
   - What we know: `nyquist_validation: true` requires a Validation Architecture; CONVENTIONS.md names the `phaseNN-*-assert.sh` pattern; the repo has two working precedents.
   - What's unclear: CONTEXT.md's fence reads "No code, wrapper, script, or session behaviour changes in this phase" `[VERIFIED: 15-CONTEXT.md:11]`. A *new verification* script is not a *behaviour* change, but it is a script.
   - Recommendation: ask at planning time. Default to inline `<automated>` blocks in the plan if unresolved — the command shapes above work either way.
   - **RESOLVED: no new script.** The fence is read strictly — `scripts/phase15-docs-assert.sh` is not created and every assertion lives inline in a task `<verify><automated>` block. Landed in `15-VALIDATION.md` § Test Infrastructure (the **Scope note**, which cites this question and research assumption A4) and in the `<verify>` blocks of all six plans. The `arch/`, `scripts/`, `.config/`, `stow/`, `vendor/` fence is itself asserted per task by `git diff --quiet HEAD` and across the whole range at the `15-06` phase gate.

2. **Should Correction 3 (runbook rollback) be fixed in this phase or raised as a deferred item?**
   - What we know: D-21 explicitly authorises correcting false post-adopt lines in the runbook.
   - What's unclear: it is the highest-severity finding and touches a recovery procedure, which some would want reviewed separately.
   - Recommendation: fix it here — it is a one-line correction, D-21 covers it, and leaving a wrong rollback source documented is worse than the change.
   - **RESOLVED: fixed in this phase, behind a blocking human gate.** Correction 3 is written by `15-03` Task 1, and the D-21-vs-D-02 boundary call is put to the developer first by the `checkpoint:decision` in `15-01` (`15-01-PLAN.md`, the `Write Corrections 1 and 2 here, defer Correction 3` option). Landed as assumption A2 in `15-01-PLAN.md` and `15-03-PLAN.md` Flagged Assumptions, and as the `15-03 T1` rollback row in `15-VALIDATION.md`. The runbook's structure is protected mechanically by the 17-section heading-count assertion, so the correction cannot silently become a rewrite.

3. **Does the D-06 safe-profile paragraph need the dual-run *restore* path?**
   - What we know: CONTEXT.md defers "Dual-run restore path" explicitly, noting nothing has verified it since the adopt.
   - What's unclear: a reader on a cold machine choosing safe never needs restore; a reader on *this* machine might ask.
   - Recommendation: honour the deferral. One sentence saying the archived trees are under `stow/` and the restore path is unverified is enough.
   - **RESOLVED: deferral honoured.** The playbook says the trees are archived under `stow/` and stops there; no restore procedure is written. Landed as the `Open-3` row in `15-05-PLAN.md` Flagged Assumptions (section 8 wording) and as the `Dual-run restore path` row, owner `unowned`, in the `## Deferred fixes` table `15-06` Task 2 writes into `15-DOC-SWEEP.md`.

4. **How much of `.planning` prose beyond `PROJECT.md` warrants review?**
   - What we know: D-22 scopes it to read-only review + report, with `PROJECT.md` the only editable exception. I reviewed `PROJECT.md`, `REQUIREMENTS.md`, `STATE.md`, `ROADMAP.md`, `CONVENTIONS.md` and the cited phase artifacts.
   - What's unclear: whether every `1X-*.md` under `.planning/phases/` needs a line-by-line read for the report, or a targeted grep for the known-stale patterns suffices.
   - Recommendation: targeted grep for the four known patterns (`getoption configProvider`, timestamped backup dir, `dual-run` as destination, "no owning phase" for D-38). Exhaustive reading of ~15 frozen artifacts is high cost for a report that changes nothing.
   - **RESOLVED: targeted grep, and the method is disclosed in the report.** `15-06` Task 2 runs the four-pattern grep over `.planning/` and is required to state in `15-DOC-SWEEP.md` which files were reviewed that way rather than read in full, and why — so a later reader knows the review's depth instead of assuming completeness. Landed as assumption `A-06-1` in `15-06-PLAN.md` and as an acceptance criterion on that task.

## Sources

### Primary (HIGH confidence — read or executed this session)
- `arch/dots-hyprland.sh` (1531 lines) — `SAFE_DEFAULTS:12`, `II_BACKUP_DIR:21`, `backup_gate:165-195`, `list_hypr_ii_hook_target_files`, `enable_hypr_ii_hooks:789`, `run_install_family:1395-1470`
- `./arch/dots-hyprland.sh help` — full live output captured
- `scripts/phase14-verify.sh` — read + executed (FAIL=0, FINDINGS=1)
- `scripts/phase13-d19-assert.sh` — read + executed (FAIL=0, 15 PASS)
- `scripts/phase14-preflight.sh` — read only (IN-11 line 264), never executed
- `docs/dots-hyprland-workflow.md` — read in full (309 lines)
- `docs/phase14-adopt-runbook.md` — outline + §5, §13, §14, See also
- `README.md`, `arch/README.md` — read in full
- `.planning/REQUIREMENTS.md`, `.planning/PROJECT.md`, `.planning/STATE.md`, `.planning/ROADMAP.md`, `.planning/config.json`, `.planning/codebase/CONVENTIONS.md`
- `.planning/phases/13-personal-hypr-custom-overlays/13-SOT-APPLY.md` — read in full
- `.planning/phases/14-live-full-adopt-verify/14-PRE-ADOPT-BASELINE.txt` — read in full
- Live probes: `hyprctl version`, `hyprctl -j status`, `hyprctl eval`, `hyprctl getoption` (×3 spellings), `hyprctl instances`, `pacman -Q hyprland`, `systemctl --user is-active` (×2), `pgrep` (×5), `sha256sum` (×4), `ls -ld ~/ii-original-dots-backup*`, `git submodule status`, `git status --short`
- Live dry-runs (non-mutating): `install-files --dry-run`, `uninstall --dry-run`

### Secondary (MEDIUM confidence)
- `.planning/phases/11-disposition-decisions/11-DISPOSITIONS.md` — heading structure only (§6 "Dual-run chrome (DISP-03)" confirmed present); body not read in full
- `.planning/phases/10-full-install-impact-inventory/10-INVENTORY.md` — existence and size confirmed; contents not read (cited by the playbook, not quoted)

### Tertiary (LOW confidence)
- None. No web search or external documentation was consulted — this phase has no external dependency surface, and every claim was resolvable against repo files or live probes.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — every tool version confirmed by direct invocation; no packages added
- Architecture / doc topology: HIGH — derived from files read in full this session
- Flag axes (DOC-03): HIGH — quoted verbatim from `arch/dots-hyprland.sh` and live `help` output
- Overlay SoT (DOC-04): HIGH — quoted verbatim from `13-SOT-APPLY.md`; live/repo parity confirmed green
- Ground-truth corrections: HIGH — each backed by pasted probe output and sha256 comparison
- Sweep inventory: HIGH for `docs/`, `README.md`, `arch/README.md`, `PROJECT.md` (read in full or grep-reviewed); MEDIUM for the breadth of `.planning/phases/` frozen artifacts (targeted grep, not exhaustive read)
- Pitfalls: HIGH — Pitfalls 1–4 were each reproduced live this session; Pitfall 5 cites the repo's own prior incident
- Validation Architecture: HIGH for command shapes (patterns copied from two working scripts); MEDIUM on whether a new script is in scope (Open Question 1)

**Research date:** 2026-09-05
**Valid until:** 2026-10-05 (30 days — stable local repo; invalidated earlier by any change to `arch/dots-hyprland.sh`, either verify script, or a re-login that changes session state)
