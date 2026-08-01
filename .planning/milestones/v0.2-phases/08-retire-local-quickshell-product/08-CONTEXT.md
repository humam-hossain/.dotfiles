# Phase 8: Retire Local Quickshell Product - Context

**Gathered:** 2026-07-27
**Status:** Ready for planning

<domain>
## Phase Boundary

**Single product path:** remove the v0.1 in-repo Quickshell product and old installer so `.dotfiles` only ships the dots-hyprland adoption path (vendor pin + `arch/dots-hyprland.sh` + live installed tree).

**In scope:**
- Confirm / restore a working **installed** dots-hyprland (ii) session path if needed — reinstall via `arch/dots-hyprland.sh` when the live install is broken or corrupted
- Delete in-repo `.config/quickshell` product tree from the repo (RET-01)
- Hard-delete `arch/quickshell.sh` (RET-02)
- Grep/clean **code** references that would reintroduce the old installer path as a required step (minimal — not a docs playbook rewrite)
- Leave live `~/.config/quickshell` (real installed tree), hypr hooks, and `arch/dots-hyprland.sh` intact unless a reinstall is needed

**Out of scope this phase:**
- New smoke / regression test scripts (phase08 smoke, inverted phase07 D-04, rewrites of phase0x asserts)
- Formal LIVE-04 re-ceremony / UAT chrome checklist
- Package uninstall (ddcutil/i2c/material fonts/etc. stay on machine)
- Deprecation stub for `arch/quickshell.sh` (user chose hard delete)
- Full operator install/update docs (Phase 9 — DOC-01/02)
- Waybar cutover, custom module ports, full ii hypr takeover

**Requirements:** RET-01, RET-02  
**Depends on:** Phase 7 live install path (LIVE-01…04 already completed; reinstall via wrapper if live product is unhealthy)

</domain>

<decisions>
## Implementation Decisions

### Install health before/while retiring
- **D-01:** Priority is a **working dots-hyprland install**, not historical product preservation. Live product is `~/.config/quickshell` from upstream install (Phase 7), not the in-repo tree.
- **D-02:** If the installed tree is corrupted, incomplete, or otherwise broken, **reinstall via** `arch/dots-hyprland.sh` (existing Phase 6 wrapper + safe defaults + backup gate). Do not re-run or resurrect `arch/quickshell.sh`.
- **D-03:** **No new smoke-test suite** this phase. Do not add `scripts/phase08-*-smoke.sh`, do not invert Phase 7 D-04 into a retirement gate, do not retarget phase0x assert scripts. Verification is practical: live ii install works (or was reinstalled); old materials are gone from the repo.

### `arch/quickshell.sh` retirement
- **D-04:** **Hard delete** `arch/quickshell.sh` (`git rm`). No deprecation stub.
- **D-05:** **No package work** this phase — do not uninstall quickshell/ddcutil/i2c/material packages; do not move package ownership into a new script. Future deps come from dots-hyprland `./setup` via the wrapper.
- **D-06:** User considers the old script unimportant — delete it; do not mount a docs campaign. Phase 9 can clean operator narrative.

### In-repo `.config/quickshell` deletion
- **D-07:** Remove the entire in-repo product tree with **`git rm -r .config/quickshell`** (full delete; ~933 tracked files). Nothing under that path is salvaged into the repo.
- **D-08:** Uncommitted WIP under the tree (e.g. ToolbarTabBar/AiChat/Anime.qml) is **not important** — discard with the tree; do not commit WIP first.
- **D-09:** **Tree delete is its own commit** (atomic). Separate commits for `arch/quickshell.sh` removal and any small reference cleanups.
- **D-10:** **No annotated recovery tag** required before delete; git history is enough.

### Stale references & historical scripts
- **D-11:** After delete, clean only what would **block** or **re-teach** the old path as current (e.g. comments that instruct running `arch/quickshell.sh` as the installer). Do not rewrite v0.1 phase assert scripts (`scripts/phase04-*.py`, frozen `scripts/phase07-live-smoke.sh` D-04 expectation, etc.).
- **D-12:** Historical scripts may fail if re-run post-delete — that is acceptable. Phase 8 does not maintain them.
- **D-13:** `arch/dots-hyprland.sh` remains the **only** Arch install entry for the shell product. Pattern comments that mention quickshell.sh as a style ancestor may stay or be lightly reworded; do not reintroduce a second installer.

### Order of operations
- **D-14:** Prefer: (1) ensure live dots-hyprland install is healthy / reinstall if needed, (2) delete in-repo tree, (3) delete `arch/quickshell.sh`, (4) minimal ref cleanup. Never use delete of the live `~/.config/quickshell` as the retirement action — only the **in-repo** tree.
- **D-15:** Do **not** re-symlink live config into the repo. LIVE-01 remains: real directory under home from upstream install.

### Agent's Discretion
- Exact reinstall command sequence if needed (dry-run then `install`, respect Phase 6 backup gate)
- Whether to touch `arch/dots-hyprland.sh` comment header that cites quickshell.sh as pattern source
- Commit message wording (atomic commits per D-09)
- How thoroughly to grep non-planning paths for stale installer mentions (minimum: nothing still *calls* deleted script as required step)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Planning (v0.2)
- `.planning/PROJECT.md` — Delete local `.config/quickshell` product this milestone; single live shell path
- `.planning/REQUIREMENTS.md` — **RET-01**, **RET-02** (this phase); LIVE-01…04 already complete
- `.planning/ROADMAP.md` — Phase 8 goal, success criteria, plan sketch 08-01…08-03
- `.planning/STATE.md` — Phase 7 closed; ready for Phase 8
- `.planning/phases/07-install-session-hooks-dual-run-verify/07-CONTEXT.md` — Live install + hooks; D-04 left in-repo tree alone until Phase 8
- `.planning/phases/06-thin-setup-wrapper-safe-defaults/06-CONTEXT.md` — Wrapper allowlist, safe defaults, backup gate (reinstall must use this)
- `.planning/phases/05-fork-submodule-pin/05-CONTEXT.md` — Canonical vendor path only

### Safety / pitfalls
- `.planning/research/PITFALLS.md` — **Pitfall 2** (never delete live symlink target / delete-before-verify ordering — live path must stay real dir); **Pitfall 10** (zombie installer — mitigated here by hard delete, not stub)

### Repo surfaces to change or protect
- `.config/quickshell/` — **delete entire in-repo tree** (RET-01)
- `arch/quickshell.sh` — **hard delete** (RET-02)
- `arch/dots-hyprland.sh` — **keep**; only install path for reinstall
- `vendor/dots-hyprland/` — **keep**; pin/submodule SoT
- `~/.config/quickshell` (live, not in repo) — **keep** installed ii tree; reinstall via wrapper if unhealthy
- `.config/hypr/hyprland.conf` — personal hooks for `qs -c ii` (do not strip as part of retirement)

No SPEC.md for this phase — requirements fully in REQUIREMENTS.md + decisions above.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `arch/dots-hyprland.sh` — thin wrapper for reinstall (`install` / `install-files` with safe defaults + backup gate)
- `vendor/dots-hyprland/setup` — upstream install SoT
- Live `~/.config/quickshell/ii` — real directory from Phase 7 (not symlink into repo)

### Established Patterns
- Phase 6: never auto-inject `--force` / `--skip-backup`; full `--skip-hyprland`
- Phase 7: live path must remain a real directory under home; in-repo product was deliberately left until Phase 8
- Atomic commits preferred for large tree deletion

### Integration Points
- Retirement is **repo-side only** for product tree + old installer
- Reinstall path if needed: stop qs if required → `arch/dots-hyprland.sh install` (or install-files) with operator at backup gate → session still uses personal hypr hooks
- Downstream Phase 9 documents clone → submodule → wrapper → hooks; Phase 8 only removes the dual-product confusion

### Scout notes (2026-07-27)
- ~933 tracked files under `.config/quickshell`; working tree still present
- Live `~/.config/quickshell` is **not** a symlink; contains `ii/`
- `scripts/phase07-live-smoke.sh` still expects in-repo tree present (D-04) — **do not maintain** as Phase 8 gate
- `scripts/phase04-ipc-reload-assert.py` hardcodes in-repo QML paths — **leave historical**
- Uncommitted WIP under tree is discardable

</code_context>

<specifics>
## Specific Ideas

- User: **“I only care about the new proper installation of dots-hyprland, just delete the previous materials.”**
- User: **No smoke test / verification suite** for this phase.
- User: If installed dots-hyprland is corrupted, **reinstall it** (via wrapper).
- User: `arch/quickshell.sh` is **not important — just delete**.
- User: WIP QML under the old tree is **not important — delete**.
- Success criteria from ROADMAP remain authoritative: repo no longer ships v0.1 tree; old installer gone; live session still on installed path (or restored by reinstall).

</specifics>

<deferred>
## Deferred Ideas

- Full clone/install/update operator playbook — Phase 9 (DOC-01, DOC-02)
- Updating or archiving historical phase0x assert/smoke scripts for post-retirement reality — optional polish, not Phase 8
- Deprecation stub for `arch/quickshell.sh` — explicitly rejected
- Package uninstall / ddcutil cleanup — not this phase
- Waybar/rofi/swaync cutover — later milestone
- Custom module ports into ii — later milestone

None beyond phase-boundary deferrals — discussion stayed within Phase 8 scope after user simplified verification.

</deferred>

---

*Phase: 8-Retire Local Quickshell Product*
*Context gathered: 2026-07-27*
