# Phase 15: Playbook safe vs full - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-05
**Phase:** 15-playbook-safe-vs-full
**Areas discussed:** Doc topology, Reader framing, Depth vs citation, Overlay + D-38, Conflict audit

---

## Gray area selection

Four areas were offered; the user selected all four.

| Area | Description | Selected |
|------|-------------|----------|
| Doc topology | One rewritten `docs/dots-hyprland-workflow.md` or a profile-split second doc, and the fate of `docs/phase14-adopt-runbook.md` | ✓ |
| Reader framing | Cold machine, this post-adopt machine, or both; replacement for the stale §4 and the `hyprland.conf` prerequisite | ✓ |
| Depth vs citation | Flag axes and the inventory→disposition→adopt sequence inline, or cited to `10-INVENTORY.md` / `11-DISPOSITIONS.md` | ✓ |
| Overlay + D-38 | Inline or cite the `13-SOT-APPLY.md` policy, plus the open `graphical-session.target` loss with no owning phase | ✓ |

Stated as locked and not reopened: canonical playbook is `docs/dots-hyprland-workflow.md` (Phase 9 DOC-01/DOC-02); `--full` is wrapper meta and the default install still injects `--core --skip-hyprland --skip-sysupdate` (Phase 12 FULL-01/FULL-02); overlay authoring SoT is the parent repo `.config/hypr/custom/` with a one-way repo→live `cp -a` apply (Phase 13 D-01/D-03/D-18); rollback never uses upstream `./setup uninstall` (ADOPT-04, Phase 14 D-23).

---

## Doc topology

### Where the safe-vs-full content lives

| Option | Description | Selected |
|--------|-------------|----------|
| Rewrite the canonical doc | Update `docs/dots-hyprland-workflow.md` in place; one doc stays the single SoT | ✓ |
| New profiles doc + link | Second doc for profiles, playbook links to it | |
| Rewrite + split appendix | Rewrite plus an appendix carrying profile detail | |

**User's choice:** Rewrite the canonical doc.

### Fate of `docs/phase14-adopt-runbook.md`

| Option | Description | Selected |
|--------|-------------|----------|
| Keep as-is, cite it | Runbook stays the frozen 2026-09-04 record; playbook cites §14 rollback and known losses; nothing copied | ✓ |
| Cite rollback, inline summary | Short rollback summary inline so no second doc is needed at a TTY | |
| Generalize into playbook | Lift go/no-go gate, banned flags, rollback tiers into the playbook; runbook demoted to history | |

**User's choice:** Keep as-is, cite it.

### Profile shape inside the doc

| Option | Description | Selected |
|--------|-------------|----------|
| Branch at §3 install | One linear spine; §3 splits into safe and full subsections | |
| Profile matrix up front | Comparison table near the top, then one narrative referencing it | |
| Two parallel tracks | Separate safe and full tracks end to end | |

**User's choice (free text):** "I would like things to be simple not branched or anything like that"
**Notes:** Read as a general steer, not just an answer to this question — it was applied again later when the user asked for "the thing that would be simple not complicated". Resolved as: one linear spine, no forks, profile differences stated in place.

### Blast radius

| Option | Description | Selected |
|--------|-------------|----------|
| Playbook + link fixes | Rewrite plus minimal cross-reference edits | |
| Playbook only | One file; stale lines elsewhere logged as deferred | |
| Playbook + doc audit | Rewrite, then sweep every doc describing install or session behaviour | |

**User's choice (free text):** "I think every doc need to be reviewed at least"
**Notes:** Made the sweep a first-class deliverable rather than a side effect.

---

## Reader framing

### Audience

| Option | Description | Selected |
|--------|-------------|----------|
| Cold machine primary | Clone → pick profile → install → verify; current machine state as a short note | ✓ |
| Both, state gate at top | "Which situation are you in" section, then one procedure | |
| Post-adopt machine primary | Document what this machine is now first, cold install second | |

**User's choice:** Cold machine primary.

### Replacement for §4 "Session hooks & dual-run"

Context given: both hook models are real — safe (`--skip-hyprland`) keeps `hyprland.conf` with the `env` + `exec-once` lines; full uses upstream `hyprland.lua`.

| Option | Description | Selected |
|--------|-------------|----------|
| One section, keyed by profile | Single "Session entry" section with a safe row and a full row | |
| Full only, safe pointed elsewhere | Document the lua entry; one pointer line for the conf-hook method | ✓ |
| Two sections | Separate safe and full session sections | |

**User's choice:** Full only, safe pointed elsewhere.

### Which profile the walkthrough walks

| Option | Description | Selected |
|--------|-------------|----------|
| Full is the walked path | Narrative walks `--full`; safe named once at the install step | ✓ |
| Safe walked, full as opt-in step | Walk the wrapper default first, then a "going full" step | |
| Both commands, full narrative | §3 shows both invocations; everything after assumes full | |

**User's choice:** Full is the walked path.
**Notes:** Flagged in the later conflict audit against the Out of Scope row "Making full profile the default wrapper behavior"; resolved by requiring an explicit statement that the wrapper default is still safe (CONTEXT D-07), not by changing this choice.

### Dual-run framing

| Option | Description | Selected |
|--------|-------------|----------|
| State current, dual-run is safe-only | Full replaces Waybar/rofi/swaync with `qs -c ii`; removal accepted (D-11); trees archived under `stow/` | ✓ |
| Drop dual-run language | Remove dual-run framing entirely | |
| Keep dual-run as supported | Document dual-run post-full with restore-from-`stow/` instructions | |

**User's choice:** State current, dual-run is safe-only.

---

## Depth vs citation

### Flag axes

| Option | Description | Selected |
|--------|-------------|----------|
| Compact axis table | Three rows — `skip-hyprland`, `core`, `sysupdate` — with consequences; `help` stays syntax SoT | ✓ |
| Prose only, defer to help | One paragraph naming the axes | |
| Full flag reference | Reproduce every wrapper flag | |

**User's choice:** Compact axis table.

### inventory → disposition → adopt sequence

| Option | Description | Selected |
|--------|-------------|----------|
| Procedure + cite artifacts | Sequence written as a gate before any full install, citing `10-INVENTORY.md` / `11-DISPOSITIONS.md` as the worked instance | ✓ |
| Cite only | Pointer paragraph to Phases 10–11 | |
| Condensed tables inline | Trimmed inventory and disposition tables in `docs/` | |

**User's choice:** Procedure + cite artifacts.

### Backup gate

| Option | Description | Selected |
|--------|-------------|----------|
| Gate inline, rollback cited | Backup gate documented at the install step; recovery cited to runbook §14 | ✓ (applied) |
| Both cited | One line, everything in the runbook | |
| Gate + one-line restore | Gate inline plus a single tier-1 restore command | |

**User's choice (free text):** "Do the thing that would be simple not complicated"
**Notes:** Applied as "gate inline, rollback cited" — the option that keeps the install step complete without duplicating the rollback tiers.

### Verification depth

| Option | Description | Selected |
|--------|-------------|----------|
| Copy-pasteable checks | Named commands with expected output | ✓ |
| Prose criteria | Describe what should be true | |
| Checks + failure branches | Commands plus per-failure handling | |

**User's choice:** Copy-pasteable checks.

---

## Overlay + D-38

### DOC-04 overlay policy

| Option | Description | Selected |
|--------|-------------|----------|
| Policy inline, detail cited | Three rules plus the apply command in the playbook's own words; `13-SOT-APPLY.md` cited for full policy and verify | ✓ |
| Cite only | Pointer paragraph naming `13-SOT-APPLY.md` | |
| Move policy into playbook | Lift the policy into `docs/`, demote the phase file | |

**User's choice:** Policy inline, detail cited.

### D-38 (`graphical-session.target`, screen share, `wl-clip-persist`, four pinned autostarts)

| Option | Description | Selected |
|--------|-------------|----------|
| Document as known loss | Short "known losses after full adopt" note; documentation only, no fix | ✓ |
| Document + defer explicitly | Same note plus a named deferred item in `.planning` | |
| Leave it | Phase 15 stays purely DOC-03/DOC-04; D-38 stays unanswered | |

**User's choice:** Document as known loss.
**Notes:** Answers the STATE question "Phase 15 scope, or its own phase" as: documented here, fix unowned. The deferred entry was written into CONTEXT anyway, since the loss list would otherwise have no forward pointer.

### IN-11 (`scripts/phase14-preflight.sh` stale `--rotate-backup` line)

| Option | Description | Selected |
|--------|-------------|----------|
| Docs only, log IN-11 | Record as a deferred fix with an owner; do not edit a phase-14 script in a doc phase | ✓ |
| Fix the printed line | Treat operator-facing script output as documentation and correct it | |
| Warn in playbook | Leave the script; playbook states `--rotate-backup` must not be run post-adopt | |

**User's choice:** Docs only, log IN-11.

### WR-02 (repo `.config/hypr/hyprland.conf` triple role)

| Option | Description | Selected |
|--------|-------------|----------|
| One line stating its role | Name it as pre-adopt config kept as rollback source and evidence | |
| Silent, stays a concern | Playbook does not mention it | |
| Full disambiguation section | Document all three roles and which wins per profile | ✓ |

**User's choice:** Full disambiguation section.

---

## Conflict audit

At the wrap-up checkpoint the user answered: "Review all the decisions thoroughly and checks if there are any conflicting decisions with the project."

Findings reported:

1. "Full is the walked path" vs the Out of Scope row "Making full profile the default wrapper behavior" and FULL-02 — no code conflict; requires an explicit statement that the wrapper default is still safe and `--full` is opt-in (CONTEXT D-07).
2. DOC-03 says "safe **vs** full", but safe had shrunk to one mention plus one pointer line — thin against roadmap criterion 1. Resolved by giving safe its own definition paragraph on the same spine, no branching (CONTEXT D-06).
3. Cold machine + full walked vs ADOPT-01 — covered by the sequence-as-gate decision, provided the gate appears before the install step (CONTEXT D-13).
4. Resolvable by wording, not reopened: the overlay text and flag table stay narrative with `13-SOT-APPLY.md` and `./arch/dots-hyprland.sh help` named as SoT; D-11 already overrides the DISP-03 default-keep, so the Waybar removal text is consistent; Phase 14 D-39 requires writing `Waybar/rofi/swaync` literally rather than "chrome".

### Runbook staleness during the sweep

| Option | Description | Selected |
|--------|-------------|----------|
| Correct false lines | Structure preserved; factual errors fixed | ✓ |
| Dated note, no rewrite | "Superseded, see playbook" note instead of an edit | |
| Log only | Record as deferred, change nothing | |

**User's choice:** Correct false lines.

### Sweep coverage

| Option | Description | Selected |
|--------|-------------|----------|
| All four | Both `docs/` files plus root `README.md` and `arch/README.md` | |
| docs/ + root README | Skip `arch/README.md` | |
| All four + `.planning` docs | Also sweep `.planning` prose | ✓ |

**User's choice:** All four + `.planning` docs.
**Notes:** Guarded in CONTEXT D-22 — the `.planning` sweep is read-only review plus a report, `STATE.md` and `ROADMAP.md` are touched only through the GSD query handlers, and phase-scoped historical artifacts are flagged rather than rewritten.

---

## Claude's Discretion

- Section numbering and headings of the rewritten playbook, within the linear shape.
- Wording and column layout of the flag-axis table and the safe/full definition paragraphs.
- Whether the sweep report is its own phase artifact or a section of the phase summary.
- Whether verification commands are one block or attached to their steps.

## Deferred Ideas

- IN-11 fix in `scripts/phase14-preflight.sh` — needs an owning phase.
- D-38 restoration (screen share bootstrap, `wl-clip-persist`, four pinned autostarts) — documented only, fix unowned.
- Dual-run restore path from `stow/` after a full adopt — unverified since the adopt, not written.
- CUT-01 / CUST-01..04 — future requirements, untouched.
- Staleness found in `.planning` phase artifacts — reported, not rewritten.

---

*Phase: 15-playbook-safe-vs-full*
*Discussion log generated: 2026-09-05*
