# Phase 15: Playbook safe vs full - Context

**Gathered:** 2026-09-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Documentation only. Rewrite the canonical operator playbook `docs/dots-hyprland-workflow.md` so it is true after the Phase 14 live full adopt, and so an operator can re-run either install profile without tribal knowledge. Delivers DOC-03 (safe vs full profiles, inventory→disposition→adopt sequence, flag axes) and DOC-04 (hypr/custom overlay expectations, repo/live/fork SoT policy from OVL-03). Also sweeps the repo's other prose for post-adopt staleness.

No code, wrapper, script, or session behaviour changes in this phase. No new install paths, no fix for the D-38 losses, no wrapper default change.

</domain>

<decisions>
## Implementation Decisions

### Doc topology

- **D-01:** Rewrite `docs/dots-hyprland-workflow.md` in place. It remains the single canonical playbook (Phase 9 DOC-01/DOC-02). No second profiles doc, no split appendix.
- **D-02:** `docs/phase14-adopt-runbook.md` keeps its structure and role as the record of the 2026-09-04 adopt window. The playbook cites it for the three-tier rollback (§14) and for adopt-window detail; no content is copied into the playbook.
- **D-03:** Structure stays simple and linear. No parallel safe/full tracks, no per-section forks. One spine — clone, pin, install, session, verify, update — with profile differences stated in place.

### Reader framing

- **D-04:** The playbook addresses a cold machine first: clone → pin → install → verify. The current post-adopt state of this machine is a short note, not the framing.
- **D-05:** The linear walkthrough walks the **full** profile end to end.
- **D-06:** The **safe** profile still gets its own explicit definition paragraph next to full's — what SAFE_DEFAULTS injects (`--core --skip-hyprland --skip-sysupdate`), what it does not touch, that dual-run is its property, and where its session hooks are documented. This is required for DOC-03 ("safe **vs** full") and does not violate D-03: it is one section on the same spine, not a second track.
- **D-07:** The playbook states plainly that the wrapper default is still safe and `--full` is opt-in wrapper-owned meta (FULL-01/FULL-02). Walking full is a documentation choice; it is not a default change. This is required so D-05 does not read as contradicting the Out of Scope row "Making full profile the default wrapper behavior".
- **D-08:** The session section documents the **full** model only: `~/.config/hypr/hyprland.lua` is the session entry, `hyprctl getoption configProvider` returns `lua`, upstream renamed the previous `~/.config/hypr/hyprland.conf` to `.old`, and personal overlays live in `~/.config/hypr/custom/`. The safe conf-hook method (`env = ILLOGICAL_IMPULSE_VIRTUAL_ENV,~/.local/state/quickshell/.venv` and `exec-once = qs -c ii` in `hyprland.conf`) gets one pointer line, not a section.
- **D-09:** Dual-run is described as a property of the safe profile only, never as a milestone goal. Under the full profile, `Waybar`, `rofi` and `swaync` are replaced by `qs -c ii`; that removal is accepted per D-11 of Phase 11, and the prior trees are archived under `stow/` per D-12. Write `Waybar/rofi/swaync` literally — never "chrome" (Phase 14 D-39).
- **D-10:** Delete the stale claims: the Purpose line promising "dual-run (`waybar` + `qs -c ii`)" as the destination, the Prerequisites line "you own personal `~/.config/hypr` (wrapper defaults **do not** replace `hyprland.conf`)" as an unconditional statement, and the §4 "No Waybar cutover required for this milestone" framing.

### Depth vs citation

- **D-11:** Flag axes get a compact three-row table — `skip-hyprland`, `core`, `sysupdate` — each row saying what injecting it and what dropping it does to the machine. `./arch/dots-hyprland.sh help` stays the syntax SoT and is named as such; the table is narrative, not a flag reference.
- **D-12:** Do not reproduce the full wrapper flag list in the playbook.
- **D-13:** The inventory→disposition→adopt sequence is written as a **required gate before any full install**, and it appears **before** the install step, not after (ADOPT-01 is a process gate; a cold machine must not reach `--full` without it). `.planning/phases/10-full-install-impact-inventory/10-INVENTORY.md` and `.planning/phases/11-disposition-decisions/11-DISPOSITIONS.md` are cited as this machine's worked instance and as SoT for their content.
- **D-14:** The backup gate is documented inline at the full install step: what gets backed up, where it lands (this machine: `~/ii-original-dots-backup.20260904T171128Z`), and that bare `--skip-backup` is refused without `--allow-skip-backup` (FULL-03). The rollback procedure itself stays cited to the runbook — simplest split, no duplicated tiers.
- **D-15:** Post-install verification is copy-pasteable with expected output: `hyprctl getoption configProvider` → `lua`, `qs -c ii` running, overlays present under `~/.config/hypr/custom/`. No failure-branch tree; failures point at the runbook.

### Overlay policy and known losses

- **D-16:** DOC-04 content is written in the playbook's own words: repo `.config/hypr/custom/` is the authoring SoT, apply is one-way repo→live, machine overlays are never committed into `vendor/dots-hyprland` or the fork, and the apply command is the named-file `cp -a` of `general.lua` / `env.lua` / `execs.lua`. `.planning/phases/13-personal-hypr-custom-overlays/13-SOT-APPLY.md` is cited and named as the SoT for the full policy and the in-repo verify; the playbook is narrative over it (Phase 13 D-05 stands).
- **D-17:** D-38 is documented as a short "known losses after full adopt" note: the `hyprland-session.service` / `graphical-session.target` bootstrap (which is what xdg-desktop-portal ScreenCast needs, so screen share is affected), `wl-clip-persist`, and the four workspace-pinned autostarts. Documentation only — no fix, no restoration work, no new scope. This closes STATE's "Phase 15 or its own phase" question in favour of "documented here, fix unowned".
- **D-18:** WR-02 gets a full disambiguation section for the repo copy `.config/hypr/hyprland.conf`: it is at once the rollback source, the frozen D-36 evidence, and the pre-adopt hook-injection target — and which of those roles applies under which profile. The full path does not use it as a live file.
- **D-19:** IN-11 is docs-only in this phase. The stale `--rotate-backup` "mandatory before go" line in `scripts/phase14-preflight.sh` is recorded as a deferred fix with an owner; the script is not edited by a documentation phase. If the playbook mentions `--rotate-backup` at all, it states that it must not be run post-adopt, because it would rename away rollback source 3.

### Doc sweep

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

</decisions>

<specifics>
## Specific Ideas

- User's repeated steer: "I would like things to be simple not branched or anything like that" and "do the thing that would be simple not complicated". When a decision is close, choose the shorter, less structured option.
- User asked for a conflict audit before the context was written; the safe-profile coverage (D-06), the "safe is still the default" statement (D-07), and gate ordering (D-13) exist because of that audit.
- "I think every doc need to be reviewed at least" — the sweep is a first-class deliverable of this phase, not a side effect of the rewrite.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### The documents being changed

- `docs/dots-hyprland-workflow.md` — the canonical playbook being rewritten in place; current outline is Purpose, Prerequisites, Canonical path, §1 clone, §2 pin, §3 install, §4 session hooks & dual-run, §5 update contract, §6 non-goals, See also
- `docs/phase14-adopt-runbook.md` — adopt-window record; §14 is the three-tier rollback (ADOPT-04) the playbook cites
- `README.md` — cold-clone discovery pointer, in the sweep
- `arch/README.md` — wrapper-local reference, in the sweep

### Requirements and scope

- `.planning/REQUIREMENTS.md` — DOC-03 and DOC-04 wording; Out of Scope rows "Making full profile the default wrapper behavior" and "Removing Waybar/rofi/swaync by default (CUT-01)"
- `.planning/ROADMAP.md` — Phase 15 goal and both success criteria
- `.planning/PROJECT.md` — Key Decisions row naming `docs/dots-hyprland-workflow.md` as the single SoT with wrapper help as flag SoT; product-surface list

### Content the playbook documents or cites

- `.planning/phases/10-full-install-impact-inventory/10-INVENTORY.md` — impact inventory; SoT for what a full install touches (INV-01..04)
- `.planning/phases/11-disposition-decisions/11-DISPOSITIONS.md` — dispositions; §6 holds D-11 accept-remove for Waybar/rofi/swaync and D-10 on SAFE_DEFAULTS remaining unchanged
- `.planning/phases/13-personal-hypr-custom-overlays/13-SOT-APPLY.md` — overlay authoring SoT, apply direction, apply command (D-18), in-repo verify (D-19); SoT for DOC-04
- `.planning/phases/13-personal-hypr-custom-overlays/13-CONTEXT.md` — D-01..D-05 overlay policy origin
- `.planning/phases/14-live-full-adopt-verify/14-CONTEXT.md` — D-11/D-12 archive under `stow/`, D-23 rollback never uses upstream `./setup uninstall`, D-36 frozen evidence, D-38 known-loss list, D-39 write `Waybar/rofi/swaync` literally
- `.planning/phases/14-live-full-adopt-verify/14-VERIFICATION.md` — warning 3, the origin of the open D-38 item
- `.planning/STATE.md` — carried concerns WR-02, IN-11, and the D-38 ownership question this phase answers
- `.planning/codebase/CONVENTIONS.md` — repo doc and script conventions

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- `arch/dots-hyprland.sh` — the thin wrapper. Its `help` output is the flag SoT the playbook defers to; `SAFE_DEFAULTS` (`--core --skip-hyprland --skip-sysupdate`), the `--full` meta flag, the backup gate and `--allow-skip-backup` all live here. Read the current help text rather than restating remembered flags.
- `.config/hypr/custom/{general,env,execs}.lua` — the repo-side overlay source the playbook's DOC-04 section describes.
- `scripts/phase14-verify.sh` — existing post-adopt verification; the copy-pasteable checks in D-15 should agree with what it asserts rather than invent new ones.
- `scripts/phase13-d19-assert.sh` — the in-repo overlay verify referenced by `13-SOT-APPLY.md`.
- `vendor/dots-hyprland` — submodule pinned at `1a9ffb78`; the playbook's pin-verify and update-contract sections operate on it.

### Established patterns

- Playbook already cites `.planning/` paths from its "See also" section, so citing `10-INVENTORY.md`, `11-DISPOSITIONS.md` and `13-SOT-APPLY.md` from the body follows existing practice.
- Docs are prose Markdown with fenced bash blocks and numbered sections; keep that style.
- One SoT per surface: wrapper help for flags, `13-SOT-APPLY.md` for overlay policy, runbook §14 for rollback. Narrative may summarise; it must name the SoT it summarises.

### Integration points

- Live machine state the playbook must match: `hyprctl getoption configProvider` → `lua`; `~/.config/hypr/hyprland.conf` renamed `.old` by upstream; overlays applied under `~/.config/hypr/custom/`; backup at `~/ii-original-dots-backup.20260904T171128Z`; Waybar/rofi/swaync trees archived under `stow/`.
- `scripts/phase14-preflight.sh` prints the stale `--rotate-backup` instruction (IN-11) — read it, do not edit it.

</code_context>

<deferred>
## Deferred Ideas

- **IN-11 fix** — correct the `--rotate-backup` "mandatory before go" line in `scripts/phase14-preflight.sh`, which post-adopt would rename away rollback source 3. Needs an owning phase; out of scope for a documentation phase (D-19).
- **D-38 restoration** — restoring the `graphical-session.target` / `hyprland-session.service` bootstrap for xdg-desktop-portal ScreenCast, `wl-clip-persist`, and the four workspace-pinned autostarts. Phase 15 documents the loss only (D-17); any fix is unowned work for a later phase.
- **Dual-run restore path** — documenting how to bring Waybar/rofi/swaync back from `stow/` after a full adopt. Not written here; nothing has verified that path since the adopt.
- **CUT-01 / CUST-01..04** — Waybar module ports and cutover polish remain future requirements, untouched by this phase.
- **Staleness found in `.planning` phase artifacts** — reported, not rewritten (D-22). Any correction that matters belongs to a phase that owns that artifact.

</deferred>

---

*Phase: 15-playbook-safe-vs-full*
*Context gathered: 2026-09-05*
