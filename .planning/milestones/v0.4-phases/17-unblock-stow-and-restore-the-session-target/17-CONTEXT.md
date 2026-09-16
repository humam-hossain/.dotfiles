# Phase 17: Unblock stow and restore the session target - Context

**Gathered:** 2026-09-12
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase makes the repo's own install scripts runnable again, makes them incapable of
destroying what the rest of v0.4 captures, and puts `graphical-session.target` back into the
live session.

**In scope:** FIX-01 (the `-v=5` flag at all 15 stow call sites), FIX-02 (`arch/hyprland.sh`
no longer restores the pre-adopt `hyprland.conf` over the ii Lua session), FIX-04
(`safe_rm_path` refuses paths inside the repo), FIX-06 (`.gitattributes`, `.gitignore`
patterns, a re-runnable secret scan), CAP-04 (`--no-folding` at every stow call site),
START-02 (`graphical-session.target` active, started from `custom/execs.lua`), START-03
(the `systemctl --user disable` footgun documented with its recovery command).

**Out of scope:** START-01, the six remaining `exec-once` entries lost at the Phase 14
adopt — `REQUIREMENTS.md:41` maps that requirement to Phase 20, and Phase 20 criterion 4
owns its verification. Creating `stow/hypr/` (HYPR-01, Phase 20). Retiring repo-root
`.config/` (FIX-03, Phase 18). Wiring the secret scan into `verify` (Phase 19). Unfolding
the stow directories that are already folded today (Phase 18).

</domain>

<decisions>
## Implementation Decisions

### FIX-01 / CAP-04 — stow call sites

- **D-01:** All 15 call sites across the 14 `arch/*.sh` files get a flags-only edit:
  `stow --verbose=5 --no-folding -t ~ PKG`. The existing
  `cd "$(dirname "${BASH_SOURCE[0]}")/../stow" &&` idiom is kept verbatim at every site —
  no switch to `-d`, no added `--restow`. The 14 files are `arch/{xterm,kitty,zsh_powerlevel,yazi,btop,alacritty,nvim,define,hyprland,rofi,wezterm,tmux,zsh,fish}.sh`;
  `arch/hyprland.sh` holds two of the 15.
- **D-02:** This phase does **not** unfold the stow directories that are already folded.
  `--no-folding` only governs new runs, so the pre-existing folded state stays live. Audit
  and record only: run `find ~/.config -maxdepth 2 -type l -lname '*.dotfiles*'` and hand the
  resulting list to Phase 18, which owns the tree taxonomy that decides what each folded
  directory becomes. — **Reversibility:** reversible — the audit output is data; unfolding
  later is a `stow -D` plus a `stow --no-folding` per package.

### FIX-02 — arch/hyprland.sh

- **D-03:** Delete `arch/hyprland.sh` lines 24-26 (`echo "[CONFIG] Hyprland Config"`,
  `mkdir -p ~/.config/hypr`, `cp -rf .config/hypr/* ~/.config/hypr/`) outright and leave a
  marker comment naming Phase 20 / HYPR-01 as the owner of Hyprland config placement.
  `REQUIREMENTS.md:16` words FIX-02 as "deleted and replaced with a stow invocation", but
  `stow/hypr/` does not exist until Phase 20, so there is nothing to invoke yet. ROADMAP
  criterion 2 is the binding wording and asks only that the file contain no
  `cp -rf .config/hypr/*` and no cwd-relative path. Record this as a requirement-text
  amendment, the same treatment ROADMAP already gives D-41's wording in Phase 21.
  — **Reversibility:** reversible — Phase 20 adds the stow line where the marker sits.
- **D-04:** Criterion 2 is proven by a real end-to-end run of `arch/hyprland.sh` against the
  live session, **after** FIX-01 lands and never before. Capture `hyprctl -j status` before
  and after and keep a `script(1)` transcript, per the Phase 14 convention. The operator
  picks the moment and starts from a clean working tree: the script fires
  `sudo pacman -Sy --noconfirm --needed` five times plus one `yay -Sy`, and `-Sy` without
  `-u` is the Arch partial-upgrade hazard. Phase 17 does not fix those lines — they map to
  no Phase 17 requirement — but records the hazard as a finding for a later phase to own.
  — **Reversibility:** one-way — the run installs packages and syncs the pacman database on
  the production daily-driver session; there is no undo for a partial upgrade, only a
  forward `-Syu`.

### FIX-04 — safe_rm_path repo guard

- **D-05:** The guard resolves both sides before comparing: `realpath -m` the candidate path,
  `realpath -m` the repo root, then prefix compare. A literal string prefix on `$path` would
  miss a `$HOME` path that reaches the repo through a symlink, which is exactly the case
  criterion 3 ("any path under the repo root") is written to catch.
- **D-06:** The repo root is `BASH_SOURCE`-derived and computed once at the top of
  `arch/dots-hyprland.sh`:
  `REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"`. This matches the idiom
  already used at `arch/waybar.sh:5` and `scripts/phase16-retire-assert.sh:23`. Not
  `git rev-parse --show-toplevel` — the uninstall path must keep working with a broken or
  absent git checkout.
- **D-07:** A refusal aborts the whole run with `[FAIL]` naming the offending path. Not
  skip-and-continue, and no `--force` override: a destructive path that has reached the repo
  means the caller's assumptions are already wrong.
- **D-08:** `vendor/dots-hyprland` sits **inside** the guard. One rule, no carve-outs —
  `git submodule deinit` is the correct tool for cleaning that tree, not `rm -rf` through the
  uninstaller.
- **D-09:** `arch/dots-hyprland.sh` becomes safely sourceable by guarding its dispatch:
  `[[ "${BASH_SOURCE[0]}" == "${0}" ]] && main "$@"`. This is what lets the assert script
  exercise `safe_rm_path` as a library function, and it pays forward into Phase 18
  criterion 7, where `verify` and `capture` become their own `main`-dispatched handlers.
  — **Reversibility:** reversible — one line at the bottom of the file.

### FIX-06 / CAP-04 — repo hygiene and secret scan

- **D-10:** `.gitattributes` is created with `* text=auto eol=lf`. No `.gitattributes`
  exists in the repo today. This was not raised in discussion — it is carried straight from
  ROADMAP criterion 4 and is not open to interpretation.
- **D-11:** The secret scan is gitleaks (Arch `extra`, currently `8.30.1-1`, not yet
  installed). `.gitleaks.toml` is committed **only if** triage accepts at least one finding
  that needs an allowlist entry. With zero findings there is no config file, so Phases 18-19
  have nothing extra to reason about.
- **D-12:** On-demand invocation only this phase. No pre-commit hook and no capture-time
  gate; wiring the scan into `verify` belongs to Phase 19, which owns the `verify` contract.
- **D-13:** Every pre-existing finding is triaged individually. A real secret is removed,
  rotated, and gitignored. An accepted finding gets an allowlist entry carrying a one-line
  reason. "Zero findings" in criterion 4 means **zero unreviewed findings** — a blanket
  baseline file that accepts everything does not satisfy it.
- **D-14:** `.gitignore` gains machine-state patterns (caches, sockets, lockfiles, `.venv`,
  state directories) **and** the generated-theme paths `PROJECT.md` already excludes:
  `kdeglobals`, `Kvantum/`, both `gtk.css`, and the matugen output. Per-tree ignore rules
  wait for Phase 18's collision map, which is what tells you which tree a path belongs to.

### START-02 / START-03 — session target and startup

- **D-15:** Exactly one entry lands in `custom/execs.lua` this phase:
  `hl.exec_cmd("systemctl --user start hyprland-session.service")`. The six remaining
  `exec-once` entries lost at the Phase 14 adopt are **START-01**, which `REQUIREMENTS.md:41`
  maps to Phase 20 and ROADMAP Phase 20 criterion 4 verifies. Keeping them out here is also
  what keeps ROADMAP's `Research: **None.**` justification true — it rests on D-38's fix
  being one `systemctl --user start` line — and leaves Phase 20's open question Q4
  (the `hl.exec_cmd` rules-table key spelling for workspace pinning) to be settled by the
  experiment Phase 20 plans, rather than pre-decided here.
- **D-16:** The entry goes inside `custom/execs.lua`'s own
  `hl.on("hyprland.start", function() ... end)` block. `~/.config/hypr/hyprland.lua` requires
  `custom.execs` after `hyprland.execs`, so both handlers register against the same event;
  the vendor file at `~/.config/hypr/hyprland/execs.lua` stays untouched, which is the whole
  point of the `custom/` overlay slot.
- **D-17:** Start only — never `systemctl --user enable`. This matches the unit's own header
  comment at `stow/systemd/.config/systemd/user/hyprland-session.service:6`. Enabling would
  create `~/.config/systemd/user/*.wants/` entries and move the unit from state `linked` to
  `enabled`, which is precisely the state where the START-03 `disable` footgun becomes
  reachable. Start-only keeps it `linked`. The unit is `Type=oneshot` with
  `RemainAfterExit=yes` and `ExecStart=/usr/bin/true`, so a single start is sufficient.
- **D-18:** Authoring source of truth is the repo copy, `./.config/hypr/custom/execs.lua`,
  carrying the same header `general.lua` already uses:
  `-- Authoring SoT: parent-repo .config/hypr/custom/ (see 13-SOT-APPLY.md).` The live copy at
  `~/.config/hypr/custom/execs.lua` is produced by one `cp` and is the applied copy. This is
  the Phase 13 precedent applied unchanged.
  **Handoff to Phase 18:** this adds a row to FIX-03's redistribution table — Phase 18
  criterion 6 retires repo-root `.config/`, and `.config/hypr/custom/execs.lua` must be
  listed there as moving into `stow/hypr/` under HYPR-01. Do not let that row go missing.
  — **Reversibility:** costly — undoing it means relocating the authoring tree and updating
  every doc that names `.config/hypr/custom/` as SoT, including `13-SOT-APPLY.md` and the
  header comment already live in `general.lua`.
- **D-19:** The START-03 footgun is documented as a warning block in
  `docs/dots-hyprland-workflow.md`, beside the D-38 narrative that already sits at line 339.
  Recovery command: re-stow the package —
  `stow --verbose=5 --no-folding -t ~ systemd` — then `systemctl --user daemon-reload`. The
  block also names `systemctl --user mask` as the safe alternative to `disable` for a
  stow-managed unit.

### Verification

- **D-20:** One assert script, `scripts/phase17-unblock-assert.sh`, with a section per
  success criterion. It follows the established contract — `[PASS]` / `[FAIL]` / `[INFO]`
  lines and a closing `=== done: FAIL=n ===` — and is modelled on
  `scripts/phase16-retire-assert.sh`, including its non-mutating header note and its
  `REPO_ROOT` derivation.
- **D-21:** The FIX-04 fixture asserts by sourcing `arch/dots-hyprland.sh` in a subshell and
  calling `safe_rm_path` on refuse-only paths, asserting a non-zero return. It never passes a
  path that would reach the `rm -rf`, so the assert script stays non-mutating.
- **D-22:** The START-02 check is `cmp -s` between `./.config/hypr/custom/execs.lua` and
  `~/.config/hypr/custom/execs.lua`, reported as `[PASS]`/`[FAIL]`, plus a one-line grep gate
  for the literal string `systemctl --user start hyprland-session.service` in the repo copy.
  The grep gate uses the pattern `15-05-SUMMARY.md` established for the runbook sections and
  catches a partial edit that `cmp` alone would pass, because `cmp` passes happily when both
  copies are equally wrong. This check survives into Phase 18 as the drift probe.
- **D-23:** Criterion 5 (`systemctl --user is-active graphical-session.target`) reports
  `[PASS]` when the target is active and `[INFO]` — not `[FAIL]` — when it is inactive, with
  the message naming the operator re-login as the required step. An agent cannot end the
  session, so a `[FAIL]` here would be permanently red through no defect. The same script
  becomes the post-re-login proof.

### Claude's Discretion

- The exact wording and placement of the Phase 20 / HYPR-01 marker comment in
  `arch/hyprland.sh`.
- The precise machine-state glob list in `.gitignore` beyond the named generated-theme paths.
- Section ordering inside `scripts/phase17-unblock-assert.sh`, as long as one section maps to
  one success criterion.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone planning

- `.planning/ROADMAP.md` — Phase 17 goal, the six success criteria, the verification-risk
  note (criterion 5 needs an operator re-login; criterion 2 runs after criterion 1), and the
  known hand-sync window. Also Phase 18 and Phase 20 details, which bound this phase's scope.
- `.planning/REQUIREMENTS.md` — FIX-01 (line 15), FIX-02 (16), FIX-04 (18), FIX-06 (20),
  CAP-04 (27), START-01 (41, explicitly **not** this phase), START-02 (42), START-03 (43).
- `.planning/PROJECT.md` — the v0.4 milestone goal, the corrected D-41 capture decision
  (organised by installer collision class and write primitive, not by atomicity), and the
  generated-theme exclusion list.
- `.planning/STATE.md` — carry-forward decisions, including the Phase 16 C-01 finding that the
  uninstall state re-clean is already flag-scoped and routed through `safe_rm_path`.

### Mechanism and pitfalls

- `.planning/research/PITFALLS.md` — the write-primitive table (`QSaveFile` preserves links;
  `rsync -a --delete` and bare `rename(2)` destroy them; `cp -f` writes through them) and the
  design constraint that a drift check must assert link-ness (`test -L` plus `readlink -f`
  equality), not byte equality alone.
- `docs/dots-hyprland-workflow.md` — the D-38 narrative at line 339; the file this phase
  extends with the START-03 warning block.
- `docs/phase14-adopt-runbook.md` — line 307, the accepted-loss framing for the
  `hyprland-session.service` autostart, and the `script(1)` transcript convention.

### Precedent to follow

- `scripts/phase16-retire-assert.sh` — the assert-script model: `REPO_ROOT` derivation,
  `FAIL` counter, `pass()`/`fail()` helpers, non-mutating header note.
- `scripts/phase14-verify.sh` — lines 443 and 458, the existing D-38 finding text and the
  session-unit path check; the `[PASS]`/`[FAIL]`/`[FINDING]`/`[INFO]` output contract.
- `.planning/milestones/v0.3-phases/14-live-full-adopt-verify/14-CONTEXT.md` — the D-38
  accepted-loss analysis, which enumerates exactly what was lost at the adopt and what ii
  already replaces.
- `.planning/milestones/v0.3-phases/15-playbook-safe-vs-full/15-05-SUMMARY.md` — the
  grep-gate pattern reused by D-22.

### Source files under change

- `arch/hyprland.sh` — lines 24-26 deleted (D-03); two of the 15 stow call sites at lines 29
  and 33.
- `arch/dots-hyprland.sh` — `safe_rm_path` at lines 428-450 (D-05 through D-08), plus the
  dispatch guard (D-09).
- `stow/systemd/.config/systemd/user/hyprland-session.service` — the unit whose header at
  line 6 already documents how it is started; unchanged by this phase.
- `.config/hypr/custom/execs.lua` — authoring SoT, currently 1 byte (empty).
- `.config/hypr/custom/general.lua` — the header comment D-18 copies.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `safe_rm_path` at `arch/dots-hyprland.sh:428-450` already has the shape the repo guard
  needs: an early return for a missing path, then a `case` allow-list on `$HOME/*`, then a
  second `case` that refuses `*/.config/hypr` and `*/.config/hypr/*`. The repo guard is a
  third refusal clause in the same function, not a new function.
- `scripts/phase16-retire-assert.sh` supplies the whole assert harness — `REPO_ROOT`, `FAIL`,
  `pass()`, `fail()` — and can be copied structurally.
- `stow/systemd/.config/systemd/user/hyprland-session.service` already exists and is already
  stow-managed. START-02 needs no unit work at all: `Wants=graphical-session.target`,
  `Before=graphical-session.target`, `Type=oneshot`, `RemainAfterExit=yes`,
  `ExecStart=/usr/bin/true`. Only the line that starts it is missing.
- `.config/hypr/hyprland.conf:57` holds the exact pre-adopt line this phase ports:
  `exec-once = systemctl --user start hyprland-session.service`.

### Established Patterns

- The stow call idiom is uniform across all 14 files:
  `cd "$(dirname "${BASH_SOURCE[0]}")/../stow" && stow -v=5 -t ~ PKG`. That uniformity is why
  FIX-01 is a mechanical flags-only edit.
- `REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"` is the repo's established way
  of locating itself (`arch/waybar.sh:5`, `scripts/phase16-retire-assert.sh:23`). D-06 adds
  `-P` so the comparison in D-05 is against a fully resolved path.
- The Hyprland overlay contract is source-mapped in `~/.config/hypr/hyprland.lua`: it
  `require`s `hyprland.execs` first, then conditionally `custom.execs` if the file exists.
  The vendor `hyprland/execs.lua` wraps its calls in
  `hl.on("hyprland.start", function() ... end)` and uses `hl.exec_cmd("...")` — D-16 mirrors
  that shape exactly.
- Assert-script output is a hard contract across the repo:
  `[PASS]`/`[FAIL]`/`[FINDING]`/`[INFO]` plus a closing
  `=== done: FAIL=n FINDINGS=n ===`. Phase 19 (VER-03) locks it further; do not reinvent it.

### Integration Points

- The 15 stow call sites are the FIX-01/CAP-04 surface. They are also what Phase 18 depends
  on: ROADMAP states Phase 18 depends on Phase 17 because `--no-folding` must be universal
  before any tree is stowed.
- `safe_rm_path` is the chokepoint for every destructive path in the uninstaller. The Phase 16
  C-01 review already routed the state re-clean through it, so one guard clause covers every
  caller.
- The D-09 dispatch guard is the hook Phase 18 criterion 7 needs, where `verify` and `capture`
  become `ALLOWLIST`-registered, `main`-dispatched handlers.
- `custom/execs.lua` is the one file this phase touches in two places at once — repo and live.
  That duplication is the known hand-sync window, closed by FIX-03 (Phase 18) and HYPR-01
  (Phase 20). D-22's `cmp` check is what keeps it honest until then.

</code_context>

<specifics>
## Specific Ideas

- The `-Sy` hazard in `arch/hyprland.sh` was surfaced during the consistency review and
  deliberately left unfixed: five `sudo pacman -Sy --noconfirm --needed` calls plus one
  `yay -Sy --noconfirm --needed gnome-network-displays`, none of them carrying `-u`. It maps
  to no v0.4 requirement. It is recorded as a deferred idea rather than silently absorbed.
- A milestone consistency review was run over all the decisions before this file was written.
  It found and resolved one scope conflict (START-01 being pulled forward into Phase 17),
  one accepted cross-phase tension (D-18's handoff row to FIX-03), and one uncovered criterion
  (`.gitattributes`, D-10). Two simplifications were applied: conditional `.gitleaks.toml`
  (D-11) and the one-line grep gate in place of a seven-way one (D-22).

</specifics>

<deferred>
## Deferred Ideas

- **The six remaining START-01 `exec-once` entries** — `wl-clip-persist`,
  `google-chrome-stable` on workspace 1, `kitty -e tmux` on workspace 1, `btop` on
  `special:btop`, `vesktop`-or-`discord` on `special:social`, and `hyprpaper`. Owned by
  Phase 20 (START-01, ROADMAP criterion 4), after `stow/hypr/` exists. Their pre-adopt form is
  preserved at `.config/hypr/hyprland.conf:70,96-99`. The Lua spelling for workspace pinning
  is Phase 20's open question Q4, with the documented fallback
  `hyprctl dispatch exec '[workspace N silent] …'`.
- **`arch/hyprland.sh`'s `-Sy` calls** — five `sudo pacman -Sy` plus one `yay -Sy`, all
  missing `-u`, which is the Arch partial-upgrade hazard. No v0.4 requirement owns this.
- **Unfolding the already-folded stow directories** — Phase 18, informed by D-02's audit
  output and by the tree taxonomy Phase 18 defines.
- **Wiring the secret scan into `verify`** — Phase 19, which owns the `verify` contract and
  its exit codes.
- **Retiring repo-root `.config/`** — Phase 18, FIX-03. Must absorb D-18's row for
  `.config/hypr/custom/execs.lua`.

</deferred>

---

*Phase: 17-unblock-stow-and-restore-the-session-target*
*Context gathered: 2026-09-12*
