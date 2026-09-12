# Phase 17: Unblock stow and restore the session target - Research

**Researched:** 2026-09-12
**Domain:** GNU Stow invocation contract, bash script sourcing semantics, systemd user-unit lifecycle, git hygiene / secret scanning — all in-repo, all confirmatory
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**FIX-01 / CAP-04 — stow call sites**

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

**FIX-02 — arch/hyprland.sh**

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

**FIX-04 — safe_rm_path repo guard**

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

**FIX-06 / CAP-04 — repo hygiene and secret scan**

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

**START-02 / START-03 — session target and startup**

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

**Verification**

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

### Deferred Ideas (OUT OF SCOPE)

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
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| **FIX-01** | Every `stow` call site uses a valid verbosity flag — `stow -v=5` exits 1 on GNU Stow 2.4.1 at all 15 call sites across 14 `arch/*.sh` files | §Verified Defect Inventory F-1: all 15 sites enumerated with file:line; `stow -v=5` falsified live (exit 1, `Unknown option: =`). §F-7: a **16th** `-v=5` exists outside `arch/` at `docs/phase14-adopt-runbook.md:247` — outside criterion 1's scope, inside CAP-04's |
| **FIX-02** | `arch/hyprland.sh` no longer restores the pre-adopt `hyprland.conf` over the ii Lua session — lines 25-26 (`cp -rf .config/hypr/*`) are deleted and replaced with a stow invocation | §F-2: `cp -rf` located at line 26, `mkdir -p` at 25, `echo` at 24. §F-3: **new finding** — the script's *second* `cd` also breaks; `arch/hyprland.sh` is un-runnable end-to-end in **every** invocation form today. Criterion 2 cannot pass on the `cp -rf` deletion alone |
| **FIX-04** | `safe_rm_path` refuses any path inside the repo, so destructive `uninstall` paths cannot reach captured configs | §F-4: function body read verbatim at `arch/dots-hyprland.sh:428-450`, 7 call sites enumerated. §F-5: **sourcing the wrapper today is falsified** — `main "$@"` at line 805 runs `usage; exit 0`, so `safe_rm_path` is never defined in the caller. D-09 is load-bearing, and its `&&` spelling is itself a trap (§Pitfall 2) |
| **FIX-06** | Repo has `.gitattributes` (`* text=auto eol=lf`), `.gitignore` entries for generated and machine-state paths, and a secret scan over the capture trees | §F-6: no `.gitattributes`; `.gitignore` read verbatim (19 lines). §F-8: a tracked `.env` under `stow/`, plus **two dead `.gitignore` patterns** that are anchored at repo root and therefore do not cover the `stow/` copy — anchoring falsified with a decoy probe. §F-9: `.config/kdeglobals` is already tracked, so a `.gitignore` line alone is a no-op |
| **CAP-04** | Every stow invocation in the repo uses `--no-folding`, so no destination directory ever becomes a symlink into the working tree | §F-1 + §F-7 (repo-wide inventory, 16 invocations). §F-10: D-02's folding audit run — 24 repo-pointing links at maxdepth 2, of which exactly **2 are folded directories** |
| **START-02** | `graphical-session.target` is active in a live session (D-38) — `hyprland-session.service` is started from `custom/execs.lua` | §F-11: **the whole mechanism is proven live, today, without a re-login** — `systemctl --user start hyprland-session.service` took the target `inactive → active` and left the unit `linked`. This splits criterion 5 into a machine-assertable half and an operator-only half (§Validation Architecture) |
| **START-03** | The `systemctl --user disable` footgun is documented — it deletes the stow symlink for a unit in state `linked` | §F-12: **falsified live on a throwaway linked unit** — `systemctl --user disable` printed `Removed '…'` and the symlink was gone. Confirmed by `systemctl(1)` DISABLE. Recovery command verified reachable |
</phase_requirements>

---

## Summary

This phase's research is **confirmatory, not exploratory** — the ROADMAP marks it `Research: **None.**` because every defect was already located to a line. Every located fact in CONTEXT.md and the ROADMAP checked out against the live repo: 15 stow call sites across 14 files, all carrying `-v=5`; `cp -rf .config/hypr/*` at `arch/hyprland.sh:26`; `safe_rm_path` at `arch/dots-hyprland.sh:428-450`; no `.gitattributes`; both `execs.lua` copies present, empty, and byte-identical; the session unit `linked` and `graphical-session.target` inactive. **Nothing in CONTEXT.md was falsified.**

The research did, however, surface **four things the plan must absorb that were not in the located set**, each verified with a real probe rather than inferred:

1. **`arch/hyprland.sh` is un-runnable end-to-end in every invocation form today, not just because of `cp -rf`.** The *second* `cd "$(dirname "${BASH_SOURCE[0]}")/../stow"` at line 33 is evaluated from the cwd the *first* `cd` left behind, so it fails whenever `BASH_SOURCE[0]` is relative. The two surviving invocation forms are exactly the two where line 26's `cp -rf .config/hypr/*` glob has nothing to match. Criterion 2 ("running it end-to-end exits 0") therefore needs both the D-03 deletion **and** a stated invocation form.
2. **The D-09 dispatch guard, written with `&&` as CONTEXT.md spells it, makes `source` return 1** — which aborts a `set -e` assert script before it can call `safe_rm_path`. The `if … fi` spelling returns 0 and is the only source-safe form. This is a one-character-class difference that silently defeats D-21.
3. **START-02's mechanism is provable now.** Starting the service took `graphical-session.target` from `inactive` to `active` in the live session with the unit still `linked`. Only the *autostart wiring* — that `custom/execs.lua` fires it at login — needs the operator re-login. Criterion 5 is two claims, and one of them is a phase-gate check, not an operator IOU.
4. **FIX-06's real surface is bigger and differently shaped than "run gitleaks."** A `.env` file is tracked in git under `stow/`, and the two `.gitignore` patterns that look like they cover it are anchored at repo root and do not. `.config/kdeglobals` is likewise already tracked, so D-14's ignore lines are no-ops without a `git rm --cached`. A scan that reports zero findings while a tracked `.env` sits in history is a false green.

**Primary recommendation:** Plan Phase 17 as five waves ordered `FIX-01/CAP-04 → FIX-04 → FIX-06 → START-02/03 → FIX-02 (operator-gated)`, with the assert script built incrementally alongside each wave rather than at the end, and with criterion 2's end-to-end run isolated as the terminal, one-way, operator-owned task. Fix the second `cd` in `arch/hyprland.sh` (or pin the invocation form in the runbook) or criterion 2 cannot pass; spell the D-09 guard as `if … fi` or D-21 cannot run.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Symlink placement (`stow`) | Repo install scripts (`arch/*.sh`) | — | The 15 call sites are the only place the repo creates links into `$HOME` [VERIFIED: repo-wide grep, §F-1/F-7] |
| Destructive-path gating | `arch/dots-hyprland.sh` → `safe_rm_path` | — | Seven call sites all funnel through one function [VERIFIED: arch/dots-hyprland.sh:248,268,277,532,541,547,571] — a single guard clause covers every caller |
| Session bootstrap (`graphical-session.target`) | systemd user manager | Hyprland Lua config (`custom/execs.lua`) | The target has `RefuseManualStart=yes` [VERIFIED: `systemctl --user show`, §F-11], so it can only be pulled up by a `Wants=` dependency; the Lua tier only supplies the trigger |
| Hyprland config placement | **Deferred to Phase 20** (`stow/hypr/`) | repo `.config/hypr/custom/` as authoring SoT (D-18) | `stow/hypr/` does not exist yet; D-03 leaves a marker rather than inventing a tier |
| Repo hygiene / secret gating | git metadata (`.gitattributes`, `.gitignore`) + gitleaks (on-demand) | Phase 19 `verify` | D-12 keeps the scan out of any automated gate this phase |
| Verification | `scripts/phase17-unblock-assert.sh` | operator re-login + `script(1)` transcript | Two criteria have an irreducible human half (§Validation Architecture) |

---

## Verified Defect Inventory

This is the confirmatory core of the run. Every row was checked against the working tree at commit `16e9e2a` on a clean tree (`git status --porcelain` empty).

### F-1 — All 15 `stow` call sites in `arch/`, and the `-v=5` flag

All 15 lines are byte-identical in shape. Quoted verbatim from the grep output:

```
arch/alacritty.sh:9:cd "$(dirname "${BASH_SOURCE[0]}")/../stow" && stow -v=5 -t ~ alacritty
arch/btop.sh:8:cd "$(dirname "${BASH_SOURCE[0]}")/../stow" && stow -v=5 -t ~ btop
arch/define.sh:7:cd "$(dirname "${BASH_SOURCE[0]}")/../stow" && stow -v=5 -t ~ define
arch/fish.sh:26:cd "$(dirname "${BASH_SOURCE[0]}")/../stow" && stow -v=5 -t ~ fish
arch/hyprland.sh:29:cd "$(dirname "${BASH_SOURCE[0]}")/../stow" && stow -v=5 -t ~ systemd
arch/hyprland.sh:33:cd "$(dirname "${BASH_SOURCE[0]}")/../stow" && stow -v=5 -t ~ swaync
arch/kitty.sh:10:cd "$(dirname "${BASH_SOURCE[0]}")/../stow" && stow -v=5 -t ~ kitty
arch/nvim.sh:20:cd "$(dirname "${BASH_SOURCE[0]}")/../stow" && stow -v=5 -t ~ nvim
arch/rofi.sh:10:cd "$(dirname "${BASH_SOURCE[0]}")/../stow" && stow -v=5 -t ~ rofi
arch/tmux.sh:17:cd "$(dirname "${BASH_SOURCE[0]}")/../stow" && stow -v=5 -t ~ tmux
arch/wezterm.sh:10:cd "$(dirname "${BASH_SOURCE[0]}")/../stow" && stow -v=5 -t ~ wezterm
arch/xterm.sh:10:cd "$(dirname "${BASH_SOURCE[0]}")/../stow" && stow -v=5 -t ~ xterm
arch/yazi.sh:10:cd "$(dirname "${BASH_SOURCE[0]}")/../stow" && stow -v=5 -t ~ yazi
arch/zsh.sh:43:cd "$(dirname "${BASH_SOURCE[0]}")/../stow" && stow -v=5 -t ~ zsh
arch/zsh_powerlevel.sh:61:cd "$(dirname "${BASH_SOURCE[0]}")/../stow" && stow -v=5 -t ~ zsh
```

[VERIFIED: `grep -rn "stow" arch/`, 15 invocation lines, 14 distinct files; `arch/hyprland.sh` holds two] — matches D-01 exactly. `arch/necessary.sh:22` and `arch/scrutiny.sh:9,12` mention the word `stow` but are a `pacman` package name and two `sudo cp` lines respectively; neither is a call site. `arch/waybar.sh:6` names a `stow/` path but copies rather than stows.

**Note for the planner:** `arch/zsh.sh:43` and `arch/zsh_powerlevel.sh:61` both stow the **same** package (`zsh`). Two call sites, one package — a flags-only edit is still correct, but a naive "one edit per package" task decomposition would miss one.

**The `-v=5` falsification** — run against the installed stow, output pasted verbatim:

```
$ stow --version
stow (GNU Stow) version 2.4.1
$ stow -v=5 -n -t ../tgt pkgA
Unknown option: =
Unknown option: 5
stow (GNU Stow) version 2.4.1
... (usage dump) ...
EXIT=1
```

[VERIFIED: live probe against GNU Stow 2.4.1 (`pacman -Q stow` → `stow 2.4.1-1`)] The correct spelling is in stow's own usage text: `-v, --verbose[=N]  Increase verbosity (levels are from 0 to 5; -v or --verbose adds 1; --verbose=N sets level)`. `--verbose=5` is the only form that sets level 5. `--no-folding` is listed in `man stow` as a valid long option [CITED: `man stow`, GNU Stow 2.4.1; also `.planning/research/PITFALLS.md:312`].

`bash -n` passes on all 14 files **today** (before the edit) — so criterion 1's `bash -n` clause is a regression guard, not a currently-failing check [VERIFIED: `bash -n` loop over the 14 files, 14/14 OK].

### F-2 — `arch/hyprland.sh` lines 24-26

Quoted verbatim (`cat -n arch/hyprland.sh`):

```
    24	echo "[CONFIG] Hyprland Config"
    25	mkdir -p ~/.config/hypr
    26	cp -rf .config/hypr/* ~/.config/hypr/
```

[VERIFIED: arch/hyprland.sh:24-26] The file is 33 lines total, with `set -euo pipefail` at line 2 and `set -x` at line 3.

**Requirement-text discrepancy:** `REQUIREMENTS.md:16` says "lines 25-26"; CONTEXT D-03 says "lines 24-26". The `cp -rf` is at 26 in both readings; D-03 additionally removes the now-orphaned `echo` at 24. D-03 is the operative instruction and is a superset. Record the amendment as D-03 already directs.

**Line-shift consequence:** after deleting 24-26, the two stow call sites move from lines 29/33 to **26/30**. Any plan task, assert grep, or review comment that pins those line numbers must be written against the *post-edit* numbering, or against content rather than line number. Prefer content.

**What the `cp -rf` would actually restore.** Repo `.config/hypr/` contains, tracked in git: `custom/{env,execs,general}.lua`, `hypridle.conf`, `hyprland/scripts/launch_first_available.sh`, `hyprland-gui.conf`, `hyprland.conf`, `hyprland.conf.bak`, `hyprlock.conf`, `hyprpaper.conf` [VERIFIED: `git ls-files .config/`, 12 entries]. The live tree has `hyprland.conf` renamed to `hyprland.conf.old` and is driven by `hyprland.lua` — `hyprctl -j status` reports `"configProvider": "lua"` [VERIFIED: live `hyprctl -j status`]. So the `cp -rf` restores a `hyprland.conf` into a tree that deliberately has none. That the restored file would flip the config provider back is the premise of FIX-02 and is [ASSUMED] on Hyprland's `.conf`-over-`.lua` precedence — but the *restoration itself* is verified, and it is sufficient grounds to delete the line regardless of which file wins.

### F-3 — NEW FINDING: the second `cd` breaks, and no invocation form runs the script today

This is not in CONTEXT.md or the ROADMAP, and it blocks criterion 2 independently of `cp -rf`.

Line 29 does `cd "$(dirname "${BASH_SOURCE[0]}")/../stow"`. Line 33 does **the same `cd` again** — but by then the cwd is already `stow/`, and `BASH_SOURCE[0]` is still the *relative* path the script was invoked with. The second `cd` is therefore evaluated relative to `stow/` and fails. With `set -euo pipefail` at line 2, that aborts the script non-zero.

Falsification probe, output pasted verbatim (a two-`cd` reduction of lines 29 and 33):

```
--- A: from repo root, relative (./arch/probe.sh) ---
cd1 ok, pwd=.../cdtest/stow
./arch/probe.sh: line 5: cd: ./arch/../stow: No such file or directory   <-- FAILS
--- B: from arch/, relative (cd arch && ./probe.sh) ---
cd1 ok, pwd=.../cdtest/stow
cd2 ok, pwd=.../cdtest/stow                                              <-- works
--- C: bash <relpath> from repo root (bash arch/probe.sh) ---
cd1 ok, pwd=.../cdtest/stow
arch/probe.sh: line 5: cd: arch/../stow: No such file or directory       <-- FAILS
--- D: absolute path from anywhere ---
cd1 ok, pwd=.../cdtest/stow
cd2 ok, pwd=.../cdtest/stow                                              <-- works
```

[VERIFIED: live bash 5.3.15 probe, four invocation forms]

Now cross it with line 26. `cp -rf .config/hypr/*` is **cwd-relative** and only globs successfully when cwd is the repo root — i.e. forms **A** and **C**. Those are exactly the two forms the second `cd` kills. Forms **B** and **D**, where the `cd` survives, are the two where the glob has nothing to match and `cp` fails under `set -e`.

**Therefore `arch/hyprland.sh` cannot currently run end-to-end in any invocation form.** Deleting lines 24-26 (D-03) removes the cwd=repo-root requirement and leaves forms B and D green. Forms A and C stay broken until the second `cd` is addressed.

**Planner guidance.** D-01 locks the `cd` idiom as kept verbatim, so do **not** restructure it. Two compliant routes:
- *(recommended)* The criterion-2 run and the runbook both pin the invocation to an absolute path — `bash "$PWD/arch/hyprland.sh"` from the repo root, or `cd arch && ./hyprland.sh`. Record the pinned form in `docs/dots-hyprland-workflow.md` next to the D-04 transcript instructions, because an operator who types `./arch/hyprland.sh` gets a red run that looks like the phase failed.
- *(alternative, needs a CONTEXT amendment)* Hoist a `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"` to the top of `arch/hyprland.sh` only and make both `cd`s absolute. This is a genuine departure from D-01's "verbatim at every site" and should be raised with the operator rather than absorbed silently.

Criterion 2's own wording — "contains … no cwd-relative path" — arguably already reaches this line: `"$(dirname "${BASH_SOURCE[0]}")/../stow"` is cwd-relative whenever `BASH_SOURCE[0]` is. Flag it and let the operator rule.

### F-4 — `safe_rm_path`

Quoted verbatim from `arch/dots-hyprland.sh:427-450`:

```bash
# Remove path if it exists; refuse anything outside $HOME.
safe_rm_path() {
  local path="$1"
  if [[ ! -e "$path" && ! -L "$path" ]]; then
    echo "[UNINSTALL] skip (missing): $path"
    return 0
  fi
  case "$path" in
    "$HOME"/*) ;;
    *)
      echo "[FAIL] Refusing to delete path outside \$HOME: $path" >&2
      return 1
      ;;
  esac
  # Extra belt: never hypr
  case "$path" in
    */.config/hypr|*/.config/hypr/*)
      echo "[FAIL] Refusing to delete hypr path: $path" >&2
      return 1
      ;;
  esac
  echo "[UNINSTALL] rm -rf -- $path"
  rm -rf -- "$path"
}
```

[VERIFIED: arch/dots-hyprland.sh:427-450] Exactly the shape CONTEXT `<code_context>` describes. Call sites: lines **248** (comment), **268, 277, 532, 541, 547, 571** [VERIFIED: `grep -n safe_rm_path arch/dots-hyprland.sh`].

**Two mechanical traps in the existing body the guard must survive:**

1. **The early return at line 430-433 fires before any refusal.** A repo path that does not exist returns `0` — success — with a `skip (missing)` message. The D-21 fixture must therefore assert against paths that **exist** inside the repo, or it will pass vacuously. Good fixture candidates that exist today and are never deletable: `$REPO_ROOT/README.md`, `$REPO_ROOT/stow`, `$REPO_ROOT/vendor/dots-hyprland` (D-08's carve-out-free case).
2. **Ordering matters for the `$HOME` clause.** `$HOME` is `/home/pera` and the repo is `/home/pera/github_repo/.dotfiles` [VERIFIED: `ls -la` on the working directory], so **every repo path already passes the `$HOME/*` allow-list**. The repo refusal must be a *third* clause reached after it — which is what D-05/CONTEXT's "third refusal clause in the same function" says. A fixture that only tests "outside `$HOME`" would not exercise the new code at all.

D-05's `realpath -m` on both sides is the right call and is testable: the live `~/.config/systemd/user/hyprland-session.service` is a relative symlink into the repo [VERIFIED, §F-11], so a `$HOME`-shaped path that resolves into the repo is not hypothetical on this machine.

### F-5 — NEW FINDING: the wrapper is not sourceable today, and D-09's spelling matters

`arch/dots-hyprland.sh:805` is a bare `main "$@"`, and `main()` at 771-776 opens with:

```bash
main() {
  # 1) bare / help → wrapper usage, exit 0 (D-02, D-03)
  if [[ $# -eq 0 ]]; then
    usage
    exit 0
  fi
```

[VERIFIED: arch/dots-hyprland.sh:771-776, 805]

Sourcing it today therefore prints the usage block and calls `exit 0`, which terminates the sourcing shell before `safe_rm_path` is reachable. Falsified live:

```
$ ( source ./arch/dots-hyprland.sh; echo "REACHED: would now call safe_rm_path" )
... usage text ...
Playbook: docs/dots-hyprland-workflow.md
        <-- "REACHED" never printed
$ ( source ./arch/dots-hyprland.sh >/dev/null 2>&1; type safe_rm_path >/dev/null 2>&1 \
      && echo "safe_rm_path DEFINED" || echo "safe_rm_path UNREACHABLE" )
        <-- neither line printed; the subshell was exited
```

[VERIFIED: live probe] D-09 is load-bearing, exactly as CONTEXT says.

**But the spelling CONTEXT gives is itself a trap.** `[[ "${BASH_SOURCE[0]}" == "${0}" ]] && main "$@"` as the *last* statement of a sourced file leaves the source's return status at `1` when the guard is false, and a `set -e` caller aborts there. Falsified live with a minimal reproduction:

```
--- &&-form: sourced from a `set -euo pipefail` caller ---
before source
EXIT=1                      <-- "after source" never printed; caller aborted

--- if…fi-form: sourced from the same caller ---
before source
after source
EXIT=0                      <-- caller continues
```

[VERIFIED: live bash 5.3.15 probe, both spellings]

**Recommendation:** spell the guard as

```bash
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
```

Both forms behave identically on direct execution (`main ran`, exit 0) [VERIFIED: same probe]. Only the sourced path differs. `|| true` after the `&&` form also works but reads as an apology; the `if` form is what the assert script should be able to rely on without a comment explaining it.

**Two further consequences of sourcing, for the D-21 fixture:**
- The wrapper sets `set -euo pipefail` at line 2 and defines `REPO_ROOT`, `II_ROOT`, `SETUP`, `ALLOWLIST`, `XDG_CONFIG_HOME`, `XDG_DATA_HOME`, `XDG_STATE_HOME`, `II_CONFDIR` at global scope [VERIFIED: arch/dots-hyprland.sh:2,9-20]. `REPO_ROOT` **collides** with the assert script's own `REPO_ROOT` (`scripts/phase16-retire-assert.sh:23` uses the same name). D-21's "in a subshell" is what contains this — keep it, and do not source at the assert script's top level.
- `safe_rm_path` calling `return 1` under the caller's inherited `set -e` is fine (a `return` in a tested context does not trip `-e`), but the fixture must capture it as `if safe_rm_path "$p"; then fail; else pass; fi` rather than `safe_rm_path "$p"; rc=$?`, which *would* trip `-e`.

### F-6 — `.gitattributes` and `.gitignore` today

`.gitattributes` does not exist [VERIFIED: `ls -la .gitattributes` → `No such file or directory`]. D-10 stands unopposed.

`.gitignore` in full, quoted verbatim (19 lines):

```
.config/system_monitor/ping/data/
.config/system_monitor/ping/.env
.planning/tmp/
.claude/
.commandcode/
__pycache__/

# qBittorrent state and lock files
stow/qbittorrent/.config/qBittorrent/lockfile
stow/qbittorrent/.config/qBittorrent/ipc-socket
stow/qbittorrent/.config/qBittorrent/qBittorrent-data.conf
stow/qbittorrent/.config/qBittorrent/rss/storage.lock
stow/qbittorrent/.config/qBittorrent/rss/articles/

# GSD agent scratch + derived runtime state (Phase 14 D-15/D-35 clean-tree condition)
.gsd/
.planning/milestone.lock
.planning/state.json
.planning/research/.cache/
```

[VERIFIED: `cat -n .gitignore`, lines 1-19]

The existing `stow/qbittorrent/…` block is the **correct** precedent for D-14's machine-state patterns: fully-qualified, tree-scoped paths. Follow that shape.

### F-7 — NEW FINDING: a 16th `-v=5`, outside `arch/`

```
docs/phase14-adopt-runbook.md:247:cd stow && stow -R -v=5 -t ~ kitty
```

[VERIFIED: repo-wide grep excluding `.git/`, `vendor/`, `.planning/`, `.claude/`]

This is a **documented operator command that exits 1**. It is the documented kitty re-stow procedure, referenced again at `.planning/research/PITFALLS.md:475` as the standard recovery for an installer-destroyed symlink.

**Scope tension the planner must resolve:** criterion 1 is scoped to "`stow` call site in `arch/`", so this line is outside it. CAP-04 is scoped to "**Every** stow invocation in the repo", so it is inside. A phase that closes CAP-04 while leaving a broken copy-pasteable command in the operator runbook has not closed CAP-04.

**Recommendation:** fix it to `cd stow && stow -R --verbose=5 --no-folding -t ~ kitty` as part of the FIX-01/CAP-04 wave, and add it to the assert script's criterion-1 section as a docs-scoped grep. Note it also carries a cwd-relative `cd stow` — that is a documentation instruction rather than a script, so it is acceptable as-is provided the doc states the cwd (it does: "Packages live under `stow/`"). The `-R` (restow) is deliberate there and must be preserved.

`.planning/research/PITFALLS.md:475` carries the same string inside a frozen research artifact. Treat planning artifacts as history per the Phase 16 precedent (STATE.md, Phase 16 / 16-07 decision on frozen-record overrides) — do **not** edit it, and make the assert grep docs-scoped so it cannot go red on the frozen copy.

### F-8 — NEW FINDING: a tracked `.env`, and two `.gitignore` patterns that do not reach it

`git ls-files` lists, under the `stow/` tree:

```
stow/system_monitor/.config/system_monitor/ping/.env
stow/system_monitor/.config/system_monitor/ping/.env.example
```

[VERIFIED: `git ls-files | grep -iE "\.env|secret|token|credential|password|\.pem|\.key|id_rsa|netrc"`]

The file's **contents were deliberately not read** — the session's secret-read guard refused both `git show HEAD:…/.env` and `git check-ignore` on that path, and reading it into the transcript would be the wrong move regardless. Only its existence, path, and tracked status are reported.

`.gitignore` lines 1-2 name `.config/system_monitor/ping/data/` and `.config/system_monitor/ping/.env`. A gitignore pattern containing a non-trailing `/` is **anchored to the directory containing the `.gitignore`** — repo root here — so neither reaches the `stow/system_monitor/…` copy. Falsified with a decoy in a scratch repo:

```
$ printf '.config/probe/secret.txt\n' > .gitignore
$ git check-ignore -v .config/probe/secret.txt
.gitignore:1:.config/probe/secret.txt   .config/probe/secret.txt     exit=0  (ignored)
$ git check-ignore -v stow/pkg/.config/probe/secret.txt
                                                      exit=1  (NOT ignored)
```

[VERIFIED: live `git check-ignore` probe on a scratch repository] Consistent with [CITED: `gitignore(5)` — "If there is a separator at the beginning or middle … of the pattern, then the pattern is relative to the directory level of the particular `.gitignore` file itself"].

Compounding it: **repo-root `.config/system_monitor/` does not exist at all** — repo `.config/` contains only `dolphinrc`, `hypr/`, and `kdeglobals` [VERIFIED: `find .config -maxdepth 2`]. So `.gitignore` lines 1-2 are dead patterns pointing at a path that no longer exists, while the real file lives in `stow/` and is tracked. And `.gitignore` never un-tracks an already-tracked file in any case.

**Planner guidance for the D-13 triage.** This is the phase's most likely real finding, and it is a `git rm --cached` + rotate + re-ignore item, not an allowlist item — unless the triage establishes the file holds no live credential, in which case it needs an allowlist entry with a one-line reason per D-13. Either way, decide it deliberately. Note that a `git rm --cached` leaves the value in **history**, which gitleaks scans by default; if the triage finds a live secret, D-13's "removed, rotated, and gitignored" is satisfiable but "zero findings" on a full-history scan is not, without either a history rewrite (out of scope) or an allowlist entry recording the rotation. **Raise this with the operator before the wave runs** — it is the one FIX-06 outcome that can make criterion 4 unreachable as literally worded.

Three further inline smells found by grep over `stow/` and `.config/`, all of which appear to be pre-redacted and are triage candidates rather than findings:

```
stow/waybar/.config/waybar/config.jsonc:56  ...?apikey=REDACTED&details=true
stow/waybar/.config/waybar/config.jsonc:57  ..."API_KEY='REDACTED' && curl -s ..."
stow/zsh/.zshrc:106                         # export ANTHROPIC_AUTH_TOKEN=REDACTED
stow/zsh/.zshrc:107                         # export ANTHROPIC_API_KEY=REDACTED
```

[VERIFIED: `git grep -In -iE "(api[_-]?key|secret|password|token|passwd)[\"' ]*[:=]" -- stow/ .config/`] All four carry the literal token `REDACTED` and all four are in comments. gitleaks' entropy and pattern rules will likely pass them, but if any fires they are textbook D-13 allowlist entries.

Scan surface sizing: 96 files tracked under `stow/` + `.config/` combined [VERIFIED: `git ls-files stow/ .config/ | wc -l`]. Small enough that a full-history gitleaks run is seconds, not minutes.

### F-9 — `.config/kdeglobals` is already tracked

`git ls-files .config/` includes `.config/kdeglobals` and `.config/dolphinrc` [VERIFIED: `git ls-files .config/`, 12 entries]. D-14 adds `kdeglobals` to `.gitignore` as a generated-theme path — but a `.gitignore` line has **no effect on a tracked file**. The ignore line plus a `git rm --cached .config/kdeglobals` is the working pair.

**Scope caution:** repo-root `.config/` is Phase 18's territory (FIX-03), and deleting `.config/kdeglobals` from the index is arguably a Phase 18 redistribution decision. Recommendation: add the `.gitignore` pattern this phase (it is what D-14 asks for and it correctly governs any *future* write), record the still-tracked state as a handoff row to Phase 18 alongside D-18's `execs.lua` row, and do **not** silently `git rm --cached` a file another phase owns. If the plan does want to untrack it now, make it an explicit, separately-reviewed task.

### F-10 — D-02's folding audit, run

```
$ find ~/.config -maxdepth 2 -type l -lname '*.dotfiles*'
```

24 links [VERIFIED: live run, count confirmed]. Of those, exactly **two are directory symlinks**, i.e. actual stow folding:

```
/home/pera/.config/smartmontools  -> ../github_repo/.dotfiles/stow/smartmontools/.config/smartmontools
/home/pera/.config/qBittorrent    -> ../github_repo/.dotfiles/stow/qbittorrent/.config/qBittorrent
```

[VERIFIED: live `test -d` loop over the 24 links]

The other 22 are file-level links under `alacritty/`, `btop/`, `kitty/`, `nvim/`, `rofi/`, `swaync/`, `waybar/`, `wezterm/`, `yazi/`, plus `starship.toml` at `.config/` top level. Those directories are unfolded already and need nothing.

**This is the deliverable D-02 asks for — hand these two paths to Phase 18.** Both are packages *not* stowed by any `arch/*.sh` script (`smartmontools` is placed by `arch/scrutiny.sh` via `sudo cp`; `qbittorrent` has no installer script at all), which is why they folded: nothing ever pre-created the real destination directory. Phase 18's taxonomy has to decide what `qBittorrent/` becomes, and note that `.gitignore` already carries five `stow/qbittorrent/…` state-file exclusions (§F-6) — a folded directory means the installer/app writes *into the repo working tree*, which is precisely risk 3 in `.planning/research/PITFALLS.md:497` ("Stow folding lets the installer write into the repo working tree … **Highest**" priority).

### F-11 — START-02: the mechanism is proven live, without a re-login

Pre-state, quoted verbatim:

```
$ systemctl --user is-enabled hyprland-session.service
linked
$ systemctl --user is-active hyprland-session.service
inactive
$ systemctl --user is-active graphical-session.target
inactive
$ ls -la ~/.config/systemd/user/hyprland-session.service
lrwxrwxrwx ... hyprland-session.service -> ../../../github_repo/.dotfiles/stow/systemd/.config/systemd/user/hyprland-session.service
```

[VERIFIED: live `systemctl --user` and `ls`] — the D-38 loss is real and current, and the unit is a stow symlink into the repo.

The unit file, quoted verbatim from `stow/systemd/.config/systemd/user/hyprland-session.service:7-15`:

```
[Unit]
Description=Bootstrap graphical-session.target for bare Hyprland
Wants=graphical-session.target
Before=graphical-session.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/true
```

Its header at line 5-6 states: `Started from hyprland.conf via: exec-once = systemctl --user start hyprland-session.service` [VERIFIED: unit file lines 1-15]. `.config/hypr/hyprland.conf:57` carries that exact pre-adopt line [VERIFIED: `sed -n '55,58p'`].

**`graphical-session.target` cannot be started directly** — falsified:

```
$ systemctl --user show graphical-session.target -p RefuseManualStart
RefuseManualStart=yes
$ systemctl --user start graphical-session.target
Failed to start graphical-session.target: Operation refused, unit graphical-session.target
may be requested by dependency only (it is configured to refuse manual start/stop).
EXIT=4
```

[VERIFIED: live probe] This is why the `Wants=` indirection in the unit exists and is not incidental.

**The fix mechanism, proven end-to-end in the live session:**

```
$ systemctl --user is-active graphical-session.target   -> inactive   (exit 3)
$ systemctl --user start hyprland-session.service       -> exit 0
$ systemctl --user is-active hyprland-session.service   -> active
$ systemctl --user is-active graphical-session.target   -> active     (exit 0)
$ systemctl --user is-enabled hyprland-session.service  -> linked     (still linked — start did NOT enable)
```

[VERIFIED: live probe on systemd 261 (261.2-1-arch)] **The session was then restored to its as-found state** (`systemctl --user stop hyprland-session.service`; both back to `inactive`; the repo symlink verified intact) so that criterion 5's evidence is not contaminated by the research run.

Three consequences the plan should absorb:

1. **D-17 is verified, not just reasoned.** `start` leaves the unit `linked`. Nothing needs `enable`, and the footgun stays out of reach.
2. **`is-active` returns exit 3 when inactive**, exit 0 when active. The assert script can branch on exit status rather than parsing the word.
3. **Blast radius of starting the target is nil.** `systemctl --user list-dependencies graphical-session.target --reverse --all` returns only the target itself; its `ConsistsOf=` list (15 `plasma-*`, `xdg-*`, `gvfs-daemon`, `at-spi-*` units) is the inverse of `PartOf=`, which propagates *stop* and *restart* but never *start* [VERIFIED: live `systemctl --user show` + `list-dependencies`; [CITED: `systemd.unit(5)` — `PartOf=` "only propagate[s] stop and restart"]]. Starting the service starts nothing else.

**This splits criterion 5.** "`is-active graphical-session.target` returns `active`" is provable by a machine at any time. "…**after a fresh login, started from `custom/execs.lua`**" is the operator-only half. See §Validation Architecture.

### F-12 — START-03: the `disable` footgun, falsified live

A first attempt using a scratch `XDG_CONFIG_HOME` **failed and proves nothing** — `systemctl --user` talks to the login-time user manager, which does not re-read `XDG_CONFIG_HOME`; the unit came back `not-found`. Reported here so the plan does not repeat it: **you cannot sandbox this with `XDG_CONFIG_HOME`.**

The valid probe used a throwaway unit name in the real `~/.config/systemd/user/`, stow-shaped as a symlink to a scratch file, and was cleaned up afterwards. Output pasted verbatim:

```
$ ln -sfn <scratch>/gsd-probe-unit.service ~/.config/systemd/user/gsd-probe-unit.service
$ systemctl --user daemon-reload
$ systemctl --user is-enabled gsd-probe-unit.service
linked
$ systemctl --user disable gsd-probe-unit.service
Removed '/home/pera/.config/systemd/user/gsd-probe-unit.service'.
$ ls -la ~/.config/systemd/user/gsd-probe-unit.service
ls: cannot access '...': No such file or directory
*** SYMLINK GONE ***
```

[VERIFIED: live probe, systemd 261; the real `hyprland-session.service` symlink was confirmed intact before and after]

Corroborated affirmatively by the documentation:

> **disable UNIT…** — Disables one or more units. **This removes all symlinks to the unit files backing the specified units from the unit configuration directory**, and hence undoes any changes made by enable or link. Note that **this removes all symlinks to matching unit files, including manually created symlinks**, and not just those actually created by enable or link.

[CITED: `systemctl(1)`, DISABLE, systemd 261 local man page, lines 749-757]

A stow symlink *is* a manually created symlink in the unit configuration directory. The footgun is real and documented, and D-19's warning block is the correct deliverable.

**Recovery command, mechanism-checked.** D-19 gives `stow --verbose=5 --no-folding -t ~ systemd` then `systemctl --user daemon-reload`. Confirmed sound: `~/.config/systemd/user/` is a **real directory containing individual symlinks** (it also holds `default.target.wants/`, `pipewire.service.wants/`, `sockets.target.wants/`, and a `pipewire-session-manager.service` link into `/usr/lib`) [VERIFIED: `ls -la ~/.config/systemd/user/`], so `--no-folding` is a no-op there and stow will restore the single missing file link without disturbing the rest. `mask` as the safe alternative is correct — masking symlinks the unit to `/dev/null` in `~/.config/systemd/user/` rather than removing the existing link, and `unmask` reverses it [CITED: `systemctl(1)`, MASK]. **Note for the doc writer:** `mask` on a unit whose config-directory entry is already a stow symlink will itself want to replace that link; state in the warning block that `unmask` must be followed by the same re-stow. That nuance was not probed and is [ASSUMED].

**Also worth a line in the block:** `docs/dots-hyprland-workflow.md:344` currently reads "restoring the session bootstrap, `wl-clip-persist` and the four autostarts is **unowned work with no owning phase**". That is now stale — Phase 17 owns the session bootstrap (START-02) and Phase 20 owns the rest (START-01). The same sentence points at `.planning/phases/15-playbook-safe-vs-full/15-DOC-SWEEP.md`, but Phase 15 is archived under `.planning/milestones/v0.3-phases/`. Fix both while the warning block is being added at line 339.

### F-13 — `custom/execs.lua`, repo and live

```
repo:  ./.config/hypr/custom/{env.lua (1 B), execs.lua (1 B), general.lua (1004 B)}
live:  ~/.config/hypr/custom/{env.lua (1 B), execs.lua (1 B), general.lua (1004 B),
                              keybinds.lua (135 B), rules.lua (1 B), scripts/, variables.lua (1 B)}
```

Both `execs.lua` copies are a single `\n` (`od -c` → `0000000  \n`), and `cmp -s` reports them **identical** today [VERIFIED: `ls -la`, `od -c`, `cmp -s` on both trees]. D-22's baseline is green before the phase starts, which means the `cmp` gate will only ever go red on a genuine half-applied edit — exactly what it is for.

The header D-18 copies, verbatim from `.config/hypr/custom/general.lua:1`:

```lua
-- Authoring SoT: parent-repo .config/hypr/custom/ (see 13-SOT-APPLY.md). Do not commit into vendor/dots-hyprland.
```

[VERIFIED: `head -8 .config/hypr/custom/general.lua`]

The overlay contract, verbatim from `~/.config/hypr/hyprland.lua:15,22-24`:

```lua
require("hyprland.execs")
...
if is_file_exists(HOME .. "/.config/hypr/custom/execs.lua") then
    require("custom.execs")
end
```

[VERIFIED: `cat -n ~/.config/hypr/hyprland.lua`] — vendor first, custom second, guarded on existence. D-16's claim holds.

The shape D-16 mirrors, verbatim from `~/.config/hypr/hyprland/execs.lua:1-6`:

```lua
-- put former exec-once commands inside the func and former exec commands outside
hl.on("hyprland.start", function ()

    -- Bar, wallpaper
    hl.exec_cmd("$HOME/.config/hypr/hyprland/scripts/start_geoclue_agent.sh")
    hl.exec_cmd("qs -c $qsConfig")
```

[VERIFIED: `cat -n ~/.config/hypr/hyprland/execs.lua`] The comment is explicit that `exec-once` commands go **inside** the func — which is what D-16 specifies and what `systemctl --user start` needs (once per session, not on every reload).

**Hand-sync note.** The repo and live `custom/` directories are *not* the same directory listing — live carries four extra files. D-22's `cmp` is scoped to `execs.lua` alone, which is correct; do not widen it to a directory diff or it will go red on a difference this phase does not own.

---

## Project Constraints (from CLAUDE.md)

**No `CLAUDE.md` or `.claude/CLAUDE.md` exists in this repo, and no `.claude/skills/` or `.agents/skills/` directory exists** [VERIFIED: `ls` on all four paths → all absent]. There are therefore no project-instruction directives to honour beyond the planning artifacts. The repo's binding conventions come from `.planning/` and from the established script contracts documented below.

**Binding repo conventions (treat as project constraints):**

| Convention | Source | Constraint |
|------------|--------|-----------|
| Assert-script output contract | `scripts/phase16-retire-assert.sh:26-28`, `scripts/phase14-verify.sh:37-41` | `[PASS]` / `[FAIL]` / `[FINDING]` / `[INFO]` prefixes, `FAIL` counter, closing `=== done: FAIL=n ===`, `exit 1` iff `FAIL>0` |
| `REPO_ROOT` derivation | `arch/waybar.sh:5`, `scripts/phase16-retire-assert.sh:23` | `"$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"`; D-06 adds `-P` |
| Non-mutating asserts | `scripts/phase16-retire-assert.sh:12-14` | "Non-mutating: syntax checks and `--dry-run` argv captures only. Never runs a live install, a live uninstall, or any package operation." Phase 17's script must carry the same header note (D-20) |
| Clean tree before a live run | `docs/dots-hyprland-workflow.md:331`, `scripts/phase14-verify.sh` D-35 check | Commit before running anything that touches the live session |
| `script(1)` transcript for live runs | `docs/phase14-adopt-runbook.md`, D-04 | Every operator-owned live run is transcripted |
| Frozen planning artifacts | STATE.md Phase 16 / 16-07 decisions | `.planning/` records are history; do not retro-edit them to satisfy a new grep |

---

## Standard Stack

### Core

| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| GNU Stow | **2.4.1-1** (installed) | Symlink farm management | Already the repo's mechanism at 15 call sites [VERIFIED: `pacman -Q stow`] |
| bash | **5.3.15(1)-release** | Script runtime, `bash -n` syntax gate | `#!/usr/bin/env bash` + `set -euo pipefail` across `arch/` and `scripts/` [VERIFIED: `bash --version`] |
| systemd | **261 (261.2-1-arch)** | User unit lifecycle, `graphical-session.target` | The session-bootstrap mechanism itself [VERIFIED: `systemctl --version`] |
| git | (system) | `.gitattributes`, `.gitignore`, `check-ignore`, `ls-files` | Repo hygiene surface for FIX-06 |
| gitleaks | **8.30.1-1** in Arch `extra`, **NOT INSTALLED** | Secret scan (D-11) | Locked by D-11 [VERIFIED: `pacman -Si gitleaks` → `Repository: extra`, `Version: 8.30.1-1`; `command -v gitleaks` → not found] |

### Supporting

| Tool | Available | Purpose | When to Use |
|------|-----------|---------|-------------|
| `realpath` | yes (coreutils) | `-m` resolution for D-05's both-sides compare | FIX-04 guard |
| `cmp` | yes (diffutils) | D-22 byte-identity gate | START-02 drift probe |
| `script(1)` | yes (util-linux) | D-04 transcript | Criterion-2 operator run |
| `hyprctl` | yes | `-j status` → `configProvider` | Criterion 2 before/after |
| `shellcheck` | **NOT INSTALLED** | Static shell lint | Optional; `bash -n` is what criterion 1 requires [VERIFIED: `command -v shellcheck` → absent] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| gitleaks | trufflehog / detect-secrets / git-secrets | **None installed** [VERIFIED: `command -v` on all three → absent]. D-11 locks gitleaks; no reason to revisit |
| `bash -n` | shellcheck | shellcheck would catch the F-3 `cd` bug class and the F-5 `&&`-guard bug class that `bash -n` cannot see. **Not installed**, and criterion 1 names `bash -n`. Worth a deferred-idea row for a later phase, not a Phase 17 dependency |
| `[[ ]] && main` guard | `if [[ ]]; then main; fi` | See §F-5 — the `if` form is the only source-safe one. This is a correctness difference, not a style preference |

**Installation:**

```bash
sudo pacman -S --needed gitleaks
```

**Version verification performed:** `pacman -Si gitleaks` → `Repository: extra`, `Version: 8.30.1-1`, `URL: https://github.com/gitleaks/gitleaks`, `Licenses: MIT` [VERIFIED: live `pacman -Si`].

---

## Package Legitimacy Audit

This phase installs exactly one external package: **gitleaks**, from the Arch Linux `extra` repository.

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| `gitleaks` | **Arch `extra`** (distro-signed) | long-standing upstream project | n/a (distro repo) | `https://github.com/gitleaks/gitleaks` (per `pacman -Si` URL field) | **OK** | Approved — install with `sudo pacman -S --needed gitleaks` |

**Provenance note.** The `gsd-tools query package-legitimacy check` seam covers `npm`/`pypi`/`crates` only; Arch `extra` is outside its ecosystem set. Legitimacy here rests on the distro repository itself: `extra` packages are signed and mirrored by Arch, and `pacman -Si` resolves `gitleaks` to `Repository: extra` with upstream URL `github.com/gitleaks/gitleaks` [VERIFIED: live `pacman -Si gitleaks`].

**⚠️ Cross-ecosystem confusion vector — do NOT install from npm.** Running the seam against npm for the same name returns a **different project**:

```json
{ "name": "gitleaks", "verdict": "OK",
  "signals": { "repoUrl": "git+https://github.com/ycjcl868/gitleaks.git",
               "weeklyDownloads": 12385, "ecosystem": "npm" } }
```

[VERIFIED: `gsd-tools query package-legitimacy check --ecosystem npm gitleaks`] `ycjcl868/gitleaks` is **not** `gitleaks/gitleaks`. The npm package passes a registry existence check and still resolves to the wrong upstream — the exact failure mode the provenance rule exists to catch. **The plan must install via `pacman`, and the assert script should verify `gitleaks version` against the pacman-installed binary path, not merely that a `gitleaks` command exists on `PATH`.**

**Packages removed due to [SLOP] verdict:** none.
**Packages flagged as suspicious [SUS]:** none. (The npm homonym is not being installed; it is recorded as a hazard, not a recommendation.)

---

## Architecture Patterns

### System Architecture Diagram — the three mechanisms this phase repairs

```
 ┌──────────────────────── MECHANISM 1: stow (FIX-01 / CAP-04) ────────────────────────┐
 │                                                                                      │
 │   operator ──> arch/<pkg>.sh ──> cd .../stow ──> stow --verbose=5 --no-folding       │
 │                     │                                       │                        │
 │                     │                                       ▼                        │
 │                     │                            ~/.config/<pkg>/<file> ──symlink──┐ │
 │                     │                                       │                      │ │
 │                     │                            (--no-folding ⇒ the DIRECTORY     │ │
 │                     │                             is never a link; only files are) │ │
 │                     └── [BROKEN TODAY] -v=5 ⇒ exit 1 (F-1)                          │ │
 │                     └── [BROKEN TODAY] 2nd cd in hyprland.sh ⇒ exit 1 (F-3)         │ │
 └──────────────────────────────────────────────────────────────────────────────────┼──┘
                                                                                     │
                                                            repo working tree <──────┘
                                                                     ▲
 ┌──────────── MECHANISM 2: destructive path gating (FIX-04) ────────┼────────────────┐
 │                                                                   │                │
 │   arch/dots-hyprland.sh uninstall                                 │                │
 │        └─> 7 call sites ──> safe_rm_path(p)                       │                │
 │                                 ├─ missing?        ──> return 0 (skip)  ◀ TRAP F-4  │
 │                                 ├─ not under $HOME ──> return 1                     │
 │                                 ├─ */.config/hypr* ──> return 1                     │
 │                                 ├─ [NEW] realpath -m p under realpath -m REPO_ROOT  │
 │                                 │                   ──> return 1  ═══ blocks ═══════┘
 │                                 └─ else            ──> rm -rf -- p
 │
 │   [NEW] dispatch guard at EOF ⇒ file becomes sourceable ⇒ assert can call the fn
 │        MUST be `if …; then main "$@"; fi`  (the `&&` form returns 1 on source, F-5)
 └──────────────────────────────────────────────────────────────────────────────────────┘

 ┌──────────── MECHANISM 3: session bootstrap (START-02 / START-03) ────────────────────┐
 │                                                                                      │
 │   login ──> Hyprland ──> ~/.config/hypr/hyprland.lua                                 │
 │                               ├─ require("hyprland.execs")   (vendor, untouched)     │
 │                               └─ require("custom.execs")     ◀── the one edit        │
 │                                        │                                             │
 │                                        └─ hl.on("hyprland.start", …)                 │
 │                                             └─ hl.exec_cmd("systemctl --user start   │
 │                                                             hyprland-session.service")│
 │                                                        │                             │
 │                                                        ▼                             │
 │                              ~/.config/systemd/user/hyprland-session.service          │
 │                                   (a STOW SYMLINK into the repo — state `linked`)     │
 │                                                        │                             │
 │                                              Wants= ──> graphical-session.target      │
 │                                                        (RefuseManualStart=yes —       │
 │                                                         reachable ONLY as a dep)      │
 │                                                        │                             │
 │                                                        ▼                             │
 │                                        xdg-desktop-portal ScreenCast works            │
 │                                                                                      │
 │   ☠ FOOTGUN (START-03): `systemctl --user disable hyprland-session.service`           │
 │      deletes the stow symlink above (verified). Recovery: re-stow + daemon-reload.     │
 │      Safe alternative: `mask`.                                                        │
 └──────────────────────────────────────────────────────────────────────────────────────┘
```

### Recommended change surface

```
arch/
├── hyprland.sh              # D-03 delete 24-26 + marker; 2 stow sites (→ lines 26,30 post-edit)
├── {13 other}.sh            # flags-only edit, 13 stow sites
└── dots-hyprland.sh         # safe_rm_path 3rd clause (D-05..D-08); REPO_ROOT -P (D-06);
                             # dispatch guard at :805 (D-09) — MUST be the `if` form
.config/hypr/custom/
└── execs.lua                # authoring SoT; one hl.exec_cmd inside hl.on (D-15/D-16/D-18)
~/.config/hypr/custom/
└── execs.lua                # applied copy via one `cp` — the hand-sync window
docs/
├── dots-hyprland-workflow.md   # START-03 warning block at ~:339 (D-19); stale :344 sentence
└── phase14-adopt-runbook.md    # :247 the 16th -v=5 (F-7)
scripts/
└── phase17-unblock-assert.sh   # NEW — one section per criterion (D-20)
.gitattributes                  # NEW — `* text=auto eol=lf` (D-10)
.gitignore                      # machine-state + generated-theme patterns (D-14)
.gitleaks.toml                  # CONDITIONAL — only if triage accepts a finding (D-11)
```

### Pattern 1: the assert-script harness (copy structurally from Phase 16)

```bash
#!/usr/bin/env bash
# Phase 17 unblock contract asserts (D-20).
# Constraints (Phase 17):
#   - Non-mutating: greps, bash -n, stow --simulate, and a sourced-subshell fixture only.
#   - Never runs a live install, a live uninstall, or any package operation.
#   - Criterion 5's target check is [INFO] when inactive (D-23) — an agent cannot re-login.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

FAIL=0
pass()    { printf '[PASS] %s\n' "$1"; }
fail()    { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
info()    { printf '[INFO] %s\n' "$1"; }

echo "=== Phase 17 unblock contract (non-mutating) ==="
# ... one section per criterion ...
echo "=== done: FAIL=${FAIL} ==="
if [[ "$FAIL" -gt 0 ]]; then exit 1; fi
exit 0
```

Source for every line above: `scripts/phase16-retire-assert.sh:1-28` and `:445-458` (tail) [VERIFIED: read this session].

**Contract note the planner must settle.** `scripts/phase16-retire-assert.sh` closes with `=== done: FAIL=${FAIL} ===`; `scripts/phase14-verify.sh:524` closes with `=== done: FAIL=${FAIL} FINDINGS=${FINDINGS} ===` and defines a fourth helper `finding()` at line 40 [VERIFIED: both files read this session]. CONTEXT's `<code_context>` describes the contract as the **four**-prefix, two-counter form; **D-20 explicitly specifies the three-prefix, one-counter form** and names phase16 as the model. **D-20 governs** — it is the locked decision and the more specific instruction. Use `[PASS]`/`[FAIL]`/`[INFO]` and `=== done: FAIL=n ===`. Do not introduce a `FINDINGS` counter; D-23 routes the one non-assertable case through `[INFO]`, which is exactly why no second counter is needed.

### Pattern 2: the D-21 fixture (source in a subshell, never at top level)

```bash
# --- Criterion 3 (FIX-04): safe_rm_path refuses repo paths ---
# Sourced in a SUBSHELL: the wrapper sets `set -euo pipefail` and defines its own
# REPO_ROOT, which collides with ours. The subshell contains both.
# Paths below all EXIST (the missing-path early return at :430 would pass vacuously)
# and are all under $HOME (the $HOME allow-list at :435 passes them through to the
# new clause — that IS the case under test).
for p in "$REPO_ROOT/README.md" "$REPO_ROOT/stow" "$REPO_ROOT/vendor/dots-hyprland"; do
  if ( source "$REPO_ROOT/arch/dots-hyprland.sh"; safe_rm_path "$p" ) >/dev/null 2>&1; then
    fail "FIX-04 safe_rm_path did NOT refuse a repo path: $p"
  else
    pass "FIX-04 safe_rm_path refuses repo path: $p"
  fi
done
```

Three things this encodes, each from a verified finding: the subshell (variable collision, §F-5); existing paths (early-return trap, §F-4); `$HOME`-resident paths (the allow-list ordering, §F-4). The `if ( … ); then` form also avoids tripping the caller's `set -e` on the expected non-zero return.

### Anti-Patterns to Avoid

- **Pinning `arch/hyprland.sh` line numbers after the D-03 deletion.** The two stow sites move 29→26 and 33→30. Assert on content (`grep -c -- '--verbose=5 --no-folding'`), never on line number.
- **Widening D-22's `cmp` to a directory diff.** Live `custom/` has four files the repo copy does not (§F-13); a directory diff goes red on something this phase does not own.
- **Writing the D-09 guard with `&&`.** §F-5. It defeats D-21 silently — the assert script aborts *before* the fixture, so the run looks like an unrelated failure.
- **Editing `.planning/research/PITFALLS.md:475`** to satisfy a `-v=5` ban. Planning artifacts are frozen history (Phase 16 / 16-07 precedent). Scope the grep to `docs/` and `arch/`.
- **Adding a `.gitignore` line for an already-tracked file and calling it done.** §F-9 — `kdeglobals` is tracked; the line has no effect on it.
- **Running criterion 2 before criterion 1 lands.** `arch/hyprland.sh` holds two of the 15 broken call sites; running it first fails at line 29 *after* five `pacman -Sy` calls have already mutated the system. See §Sequencing Hazards.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Path containment check | String prefix on `$path` | `realpath -m` both sides, then prefix compare (D-05) | A `$HOME` path can reach the repo through a symlink — and does on this machine (§F-11's unit link). A string compare misses exactly the case criterion 3 names |
| Secret detection | A `grep -iE 'api_key\|token\|secret'` pass | gitleaks 8.30.1 (D-11) | Entropy analysis, full-history scanning, and a maintained rule corpus. The grep in §F-8 found 4 pre-redacted comments and would have missed a high-entropy value with no keyword next to it |
| Script-vs-sourced detection | `$0` comparison alone, or `caller` | `[[ "${BASH_SOURCE[0]}" == "${0}" ]]` in an `if` block (D-09, §F-5) | Standard, but the **`if` wrapper is the non-obvious half** — the idiomatic `&&` one-liner is the bug |
| Directory-symlink prevention | `mkdir -p` the destination before every stow | `stow --no-folding` (CAP-04) | `--no-folding` is unconditional and cannot be forgotten per-package. `.planning/research/PITFALLS.md:312`: "Prefer `--no-folding` globally — the cost is more symlinks, the benefit is that folding can never surprise you" |
| Starting `graphical-session.target` | `systemctl --user start graphical-session.target` | Start `hyprland-session.service`, let `Wants=` pull the target | `RefuseManualStart=yes` — the direct call exits 4 [VERIFIED, §F-11] |
| Un-registering a stow-managed unit | `systemctl --user disable` | `systemctl --user mask`, or just `stop` | `disable` deletes the stow symlink [VERIFIED, §F-12] |
| Line-ending normalisation | A `dos2unix` script or a pre-commit hook | `.gitattributes` with `* text=auto eol=lf` (D-10) | git's own normalisation layer; one line, no runtime |

**Key insight:** every defect in this phase is a *flag or spelling* defect, not a design defect. The repo's mechanisms are right; four invocations are spelled wrong (`-v=5`), one guard clause is absent, one `cd` is evaluated from the wrong place, and one `exec-once` line was lost. Resist the urge to restructure anything — D-01 locks the `cd` idiom, D-03 declines to invent a `stow/hypr/` that Phase 20 owns, and D-15 declines to restore five `exec-once` entries Phase 20 owns. The value of this phase is that it changes as little as possible.

---

## Runtime State Inventory

This phase edits scripts *and* live runtime state, so the inventory applies.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| **Stored data** | **None.** No database, no KV store, no vector store holds any string this phase changes. Verified by inspection: the changed strings are `-v=5` (shell scripts only), `cp -rf .config/hypr/*` (one script line), a `safe_rm_path` clause (one function), and one `hl.exec_cmd` line (one Lua file). No datastore exists in the repo | none |
| **Live service config** | **`~/.config/systemd/user/hyprland-session.service`** — a stow symlink into the repo, state `linked`, currently `inactive` [VERIFIED: §F-11]. Its *content* is unchanged by this phase (D-17: the unit needs no work). Its *runtime state* changes: inactive → active, but only on a fresh login via the new `custom/execs.lua` line | none to the unit; state change is the START-02 deliverable and is operator-triggered |
| **OS-registered state** | **`graphical-session.target`** — currently `inactive` in the running user manager [VERIFIED]. Not enabled, not masked, no `*.wants/` entries reference `hyprland-session.service` [VERIFIED: `ls -la ~/.config/systemd/user/` shows three `.wants/` dirs, none containing it]. D-17 keeps it that way | none — deliberately no `enable` |
| **Secrets / env vars** | **`stow/system_monitor/.config/system_monitor/ping/.env` — TRACKED IN GIT** [VERIFIED: `git ls-files`]. Contents not read (secret guard; deliberately). `.env.example` is tracked alongside it. The two `.gitignore` patterns intended to cover it are anchored at repo root and do not reach it [VERIFIED: §F-8] | **D-13 triage required** — decide: `git rm --cached` + rotate + correctly-scoped ignore, **or** a `.gitleaks.toml` allowlist entry with a reason. History retention makes "zero findings" conditional — raise with the operator |
| **Build artifacts / installed packages** | **gitleaks is not installed** [VERIFIED: `command -v gitleaks` → absent]; it must be installed from `extra` before criterion 4 can run. **Two folded stow directories** exist and will not un-fold from a `--no-folding` edit: `~/.config/smartmontools`, `~/.config/qBittorrent` [VERIFIED: §F-10] — D-02 explicitly declines to fix them and hands them to Phase 18. No stale egg-info, compiled binary, or image tag exists in this repo | install gitleaks; record the two folded dirs as a Phase 18 handoff |

**The canonical question — after every file in the repo is updated, what runtime systems still hold the old state?**

Three, all recorded above and all deliberately handled: (1) the running Hyprland session, which will not re-read `custom/execs.lua` until the operator re-logs in — this is criterion 5's operator half; (2) the two folded stow directories, which `--no-folding` does not retroactively unfold — D-02's accepted carry-forward; (3) git history, which retains the `.env` contents regardless of an index removal — the one item that can make criterion 4's literal wording unreachable and therefore needs an operator decision, not an executor judgement call.

---

## Common Pitfalls

### Pitfall 1: `arch/hyprland.sh` is run before FIX-01 lands, or with the wrong invocation form

**What goes wrong:** The script fires five `sudo pacman -Sy --noconfirm --needed` calls plus one `yay -Sy` (lines 6, 9, 12, 15, 21, 22) and a `sudo usermod -aG i2c` (line 18) *before* it reaches the first stow call at line 29. If line 29 still carries `-v=5`, the run aborts under `set -e` **after** the package operations have already mutated the system and synced the pacman database.
**Why it happens:** The two `arch/hyprland.sh` stow sites are among the 15 broken ones. Criterion 2's "runs end-to-end, exits 0" cannot be true until criterion 1 has landed in *this specific file*.
**How to avoid:** Sequence criterion 2 strictly after criterion 1 (the ROADMAP says so; §Sequencing Hazards gives the encoding). Additionally, pin the invocation form — `bash "$PWD/arch/hyprland.sh"` from the repo root, or `cd arch && ./hyprland.sh` — because forms A and C fail at line 33 regardless (§F-3).
**Warning signs:** `cd: ./arch/../stow: No such file or directory` in the transcript; or `Unknown option: =` at line 29 with packages already installed.

### Pitfall 2: the D-09 dispatch guard written with `&&`

**What goes wrong:** `source arch/dots-hyprland.sh` returns 1; a `set -e` assert script aborts at the `source`; `safe_rm_path` is never called; the FIX-04 section never runs. The failure is silent and misattributed — the script dies before printing its criterion-3 header.
**Why it happens:** `[[ … ]] && main "$@"` is the idiomatic one-liner, and it is correct for the *executed* case. Only the *sourced* case differs, and only under `set -e`.
**How to avoid:** `if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then main "$@"; fi` [VERIFIED: §F-5].
**Warning signs:** the assert script's output stops after the last pre-FIX-04 line with no `[FAIL]`; `echo $?` after a manual `source` prints `1`.

### Pitfall 3: the FIX-04 fixture passes vacuously

**What goes wrong:** The fixture calls `safe_rm_path "$REPO_ROOT/does-not-exist"`, hits the early return at `arch/dots-hyprland.sh:430-433`, gets `return 0` with a `skip (missing)` message — and the assert, written as "non-zero means refused", records a FAIL that looks like a bug in the guard. Or, inverted: it calls a path outside `$HOME`, gets a refusal from the *pre-existing* clause at line 436, records a PASS, and never exercises the new code at all.
**Why it happens:** Two clauses sit in front of the new one, and the repo lives *inside* `$HOME` on this machine (`/home/pera/github_repo/.dotfiles`), so every repo path sails through the `$HOME/*` allow-list.
**How to avoid:** Fixture paths must **exist** and must be **under `$HOME`**. Use `$REPO_ROOT/README.md`, `$REPO_ROOT/stow`, `$REPO_ROOT/vendor/dots-hyprland`. Keep one *negative* control that is outside `$HOME` (e.g. `/etc/passwd`) so the section proves the pre-existing clauses still work too.
**Warning signs:** the criterion-3 section passes even when the new clause is commented out. Check this explicitly during plan verification.

### Pitfall 4: the secret scan reports "zero findings" for the wrong reason

**What goes wrong:** gitleaks is run with `--no-git` or scoped to the working tree only, misses the tracked `.env` in history, and prints a green zero. Or a blanket `--baseline-path` file is generated that accepts everything, which D-13 explicitly forbids.
**Why it happens:** gitleaks has both a `git` mode (history) and a `dir`/`--no-git` mode (working tree). Default `gitleaks detect` scans history; `gitleaks dir` does not.
**How to avoid:** Run **both** — a history scan and a working-tree scan — and record both commands in the assert script so criterion 4's "re-runnable" clause is satisfied by something reproducible. Triage each finding individually (D-13). No blanket baseline.
**Warning signs:** a zero-finding result on a repo that demonstrably contains a tracked `.env` (§F-8). If the scan is green and §F-8's file is still tracked, the scan is misconfigured.

### Pitfall 5: `.gitignore` patterns written unanchored, or written for a tree that does not exist

**What goes wrong:** D-14's new patterns repeat the shape of `.gitignore:1-2` — repo-root-anchored paths into a `.config/` tree that holds only three entries — and silently cover nothing under `stow/`.
**Why it happens:** A pattern with a mid-string `/` is anchored to the `.gitignore`'s own directory [VERIFIED: §F-8 decoy probe; CITED: `gitignore(5)`].
**How to avoid:** Follow the `stow/qbittorrent/…` block's shape (fully-qualified from repo root, §F-6) for tree-specific paths, and use a **leading-`/`-free, slash-free** basename pattern (e.g. `kdeglobals`) when the intent is "anywhere in the repo". Verify each new pattern with `git check-ignore -v <path>` and put those checks in the assert script.
**Warning signs:** `git check-ignore -v` exits 1 on a path the pattern was written for.

### Pitfall 6: `XDG_CONFIG_HOME` is used to sandbox a `systemctl --user` experiment

**What goes wrong:** The probe reports `not-found` / `does not exist` and you conclude the mechanism does not work. It was never tested.
**Why it happens:** `systemctl --user` talks to the user manager started at login, which does not re-read `XDG_CONFIG_HOME` from the invoking shell. `daemon-reload` reloads *that* manager, not a hypothetical one.
**How to avoid:** Do not try. If a unit experiment is needed, use a throwaway unit name in the real `~/.config/systemd/user/` and clean up — that is how §F-12 was proven. Alternatively `systemd-run --user --scope` or a container, neither of which this phase needs.
**Warning signs:** `is-enabled` returns `not-found` for a unit whose symlink you can see on disk.

### Pitfall 7: the `-Sy` partial-upgrade hazard fires during the criterion-2 run

**What goes wrong:** `sudo pacman -Sy` without `-u` refreshes the package database without upgrading, so the next single-package install links against newer libraries than the ones on disk. On Arch this is the canonical way to break a running system, and there is no undo — only a forward `-Syu`.
**Why it happens:** `arch/hyprland.sh` carries five `sudo pacman -Sy --noconfirm --needed` (lines 6, 9, 12, 15, 21) and one `yay -Sy --noconfirm --needed` (line 22) [VERIFIED: arch/hyprland.sh].
**How to avoid:** D-04 declines to fix these — they map to no Phase 17 requirement — and instead requires the operator to pick the moment. The plan should surface the hazard in the criterion-2 task text and in the runbook, and recommend the operator run a full `sudo pacman -Syu` **immediately before** the criterion-2 run so the database refresh is a no-op.
**Warning signs:** anything in the transcript between the first `-Sy` and the end that mentions a library version mismatch.

---

## Code Examples

### The stow call-site edit (D-01, flags-only)

```bash
# BEFORE  (arch/btop.sh:8 — the shape of all 15 sites)
cd "$(dirname "${BASH_SOURCE[0]}")/../stow" && stow -v=5 -t ~ btop

# AFTER
cd "$(dirname "${BASH_SOURCE[0]}")/../stow" && stow --verbose=5 --no-folding -t ~ btop
```

Source: `arch/btop.sh:8` [VERIFIED, §F-1]; flag spellings from `stow --help` on GNU Stow 2.4.1 [VERIFIED, §F-1].

### The `custom/execs.lua` edit (D-15 / D-16 / D-18)

```lua
-- Authoring SoT: parent-repo .config/hypr/custom/ (see 13-SOT-APPLY.md). Do not commit into vendor/dots-hyprland.

-- put former exec-once commands inside the func and former exec commands outside
hl.on("hyprland.start", function ()
    -- INFO: SCREEN-SHARE FIX (D-38 / START-02)
    -- Bootstrap graphical-session.target so xdg-desktop-portal (ScreenCast) can start.
    -- graphical-session.target has RefuseManualStart=yes; this unit's Wants= pulls it up.
    hl.exec_cmd("systemctl --user start hyprland-session.service")
end)
```

Header verbatim from `.config/hypr/custom/general.lua:1`; `hl.on`/`hl.exec_cmd` shape verbatim from `~/.config/hypr/hyprland/execs.lua:1-6`; the comment text adapted from `.config/hypr/hyprland.conf:55-57` [all VERIFIED, §F-13].

### The apply hop (the hand-sync window)

```bash
cp ./.config/hypr/custom/execs.lua ~/.config/hypr/custom/execs.lua
cmp -s ./.config/hypr/custom/execs.lua ~/.config/hypr/custom/execs.lua && echo IDENTICAL
```

Phase 13 precedent, one `cp`, repo is SoT (D-18). Both copies are byte-identical today, so the `cmp` baseline is green before the edit [VERIFIED, §F-13].

### The `safe_rm_path` third clause (D-05 … D-08)

```bash
  # Extra belt: never inside this repo (FIX-04). Resolve BOTH sides — a $HOME path can
  # reach the repo through a symlink, and this repo lives under $HOME.
  local _rp _rr
  _rp="$(realpath -m -- "$path")"
  _rr="$(realpath -m -- "$REPO_ROOT")"
  case "$_rp" in
    "$_rr"|"$_rr"/*)
      echo "[FAIL] Refusing to delete path inside the repo: $path" >&2
      return 1
      ;;
  esac
```

Placement: **after** the existing `*/.config/hypr*` clause at `arch/dots-hyprland.sh:442-447` and before the `rm -rf` at line 448-449. It must come after the `$HOME/*` allow-list, not before — the repo is inside `$HOME`, so an earlier position would never be reached differently but a *replacement* of the `$HOME` clause would lose the outside-`$HOME` refusal [VERIFIED, §F-4]. `REPO_ROOT` is already in scope, defined at line 9 [VERIFIED].

### The dispatch guard (D-09 — the source-safe spelling)

```bash
# Replaces the bare `main "$@"` at arch/dots-hyprland.sh:805.
# `if … fi`, NOT `[[ … ]] && main "$@"` — the && form returns 1 when sourced, which
# aborts a `set -e` caller before it can reach safe_rm_path (Phase 17 research §F-5).
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
```

[VERIFIED: both spellings probed live, §F-5]

### The START-03 warning block skeleton (D-19)

```markdown
> **⚠ Never `systemctl --user disable` a stow-managed unit.**
> `disable` removes *all* symlinks to the unit from `~/.config/systemd/user/` —
> including manually created ones, which is exactly what a stow link is. Verified:
> `systemctl --user disable hyprland-session.service` prints
> `Removed '/home/pera/.config/systemd/user/hyprland-session.service'.` and the link is gone.
> The repo copy under `stow/systemd/` survives; only the link dies.
>
> **Recovery:**
> ```bash
> cd stow && stow --verbose=5 --no-folding -t ~ systemd
> systemctl --user daemon-reload
> ```
>
> **Safe alternative:** `systemctl --user mask <unit>` (reverse with `unmask`, then re-stow),
> or simply `systemctl --user stop <unit>`. This unit is never `enable`d — it stays in state
> `linked` and is started from `custom/execs.lua` at session start.
```

`disable` semantics [CITED: `systemctl(1)` DISABLE] and [VERIFIED: live probe, §F-12]. The recovery command's soundness confirmed against the real `~/.config/systemd/user/` layout [VERIFIED, §F-12].

---

## Sequencing Hazards

The phase description names two. Both are real; here is how plans should encode them.

### Hazard 1 — criterion 2 must run strictly after criterion 1

**Why it is real, concretely:** `arch/hyprland.sh` holds two of the 15 broken stow sites, at lines 29 and 33. Everything before line 29 is irreversible system mutation (five `pacman -Sy`, one `yay -Sy`, one `usermod -aG i2c`). A criterion-2 run before criterion 1 lands gets all of that mutation and then dies on `Unknown option: =`.

**How to encode it in the plan:**
- Put criterion 2's end-to-end run in its **own plan file**, as the phase's **last** wave, with an explicit `depends_on` naming the FIX-01/CAP-04 plan. Do not make it a task inside a multi-purpose plan — wave parallelization must not be able to schedule it early.
- Open that plan with a `checkpoint:human-verify` task whose gate is: *clean working tree (`git status --porcelain` empty), FIX-01 wave committed, `scripts/phase17-unblock-assert.sh` criterion-1 section green, `sudo pacman -Syu` just completed, `script(1)` started, `hyprctl -j status` captured*. All six, in one checkpoint, before any command runs.
- The task itself is **operator-executed, not agent-executed** — D-04 says "the operator picks the moment" and the run needs `sudo`. The agent's job is to prepare the transcript scaffolding and to parse the result afterwards.
- Record the pinned invocation form in the task text (§F-3): `bash "$PWD/arch/hyprland.sh"` or `cd arch && ./hyprland.sh`. **Not** `./arch/hyprland.sh`.
- Post-run assertions, all machine-checkable from the transcript: exit status 0; `hyprctl -j status` still `"configProvider": "lua"`; `~/.config/hypr/hyprland.conf` still absent; the systemd and swaync stow links present.

**Reversibility label for the plan:** **one-way**. Packages installed, pacman DB synced, `$USER` added to group `i2c`. There is no undo, only a forward `-Syu`.

### Hazard 2 — criterion 5 needs an operator re-login an agent cannot perform

**Why it is real:** Hyprland reads `custom/execs.lua` at session start. No `hyprctl reload` re-fires an `hl.on("hyprland.start", …)` handler. An agent cannot end the operator's session.

**But it is narrower than it looks.** §F-11 proved the *mechanism* live, today: starting the service takes the target active, and the unit stays `linked`. Criterion 5 is therefore **two claims**, and only one of them is blocked:

| Sub-claim | Machine-assertable now? | How |
|-----------|------------------------|-----|
| 5a. The repo `execs.lua` contains the literal `systemctl --user start hyprland-session.service` | **yes** | `grep -F` gate (D-22) |
| 5b. Repo and live `execs.lua` are byte-identical | **yes** | `cmp -s` (D-22) |
| 5c. The unit is `linked`, not `enabled` (D-17) | **yes** | `systemctl --user is-enabled` → `linked` |
| 5d. Starting the service activates `graphical-session.target` | **yes, and already proven** | §F-11; re-provable at will, reverts with `stop` |
| 5e. **The target is active *after a fresh login*, *because of* `custom/execs.lua`** | **no** | operator re-login only |

**How to encode it in the plan:**
- Assert 5a-5d in `scripts/phase17-unblock-assert.sh` as hard `[PASS]`/`[FAIL]` sections. They are not IOUs.
- Assert 5e per D-23: `[PASS]` when `is-active graphical-session.target` returns 0; `[INFO]` — never `[FAIL]` — when it returns 3, with a message naming the operator re-login as the required step.
- **Recommended addition:** the `[INFO]` message should distinguish *"not yet re-logged in"* from *"re-logged in and it did not work."* Have the assert script, when the target is inactive, additionally report whether `systemctl --user show hyprland-session.service -p ActiveEnterTimestamp` is empty (never started this boot) versus populated (started and stopped). That is the difference between a pending operator step and a real regression, and it costs two lines.
- Close the phase with a UAT item, not a plan task: *"Log out and back in. Run `scripts/phase17-unblock-assert.sh`. Criterion 5 must flip from `[INFO]` to `[PASS]`."* Follow the Phase 16 D-40 precedent, where the outstanding operator re-login was recorded explicitly in the sweep record with the checks still owed [per STATE.md].
- **Do not** let the phase's completion gate depend on 5e, and **do not** mark START-02 Complete in `REQUIREMENTS.md` until the operator confirms. The Phase 16 record shows exactly this pattern handled honestly.

### Hazard 3 (not in the phase description) — the FIX-06 `.env` decision can block criterion 4

See §F-8. "Zero findings" on a full-history gitleaks scan is not reachable by a `git rm --cached` alone if the tracked `.env` holds a live credential, because the value stays in history. The resolutions are: rotate + allowlist with a reason (D-13-compliant, keeps criterion 4 reachable), or a history rewrite (out of scope, and destructive to a repo with archived milestone evidence). **This is an operator decision and should be a `checkpoint:human-verify` at the top of the FIX-06 wave, before the scan is even run.** Discovering it mid-wave turns a 20-minute task into a blocked one.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `stow -v=5` | `stow --verbose=5` | `-v` gained an *optional* argument; the `-v=5` spelling was never valid getopt | All 15 (16, incl. docs) sites exit 1 today |
| Default stow folding | `--no-folding` everywhere | CAP-04 / `.planning/research/PITFALLS.md:312` | Prevents the installer writing into the repo working tree — risk 3, rated **Highest** in PITFALLS |
| `exec-once` in `hyprland.conf` | `hl.exec_cmd(...)` inside `hl.on("hyprland.start", ...)` in Lua | Phase 14 adopt (2026-09-04); `configProvider: lua` | The pre-adopt line at `.config/hypr/hyprland.conf:57` must be ported, not copied |
| Hand-rolled secret greps | gitleaks with per-finding triage | D-11 / D-13 | Entropy + history coverage the grep cannot match |
| `[[ … ]] && main "$@"` | `if [[ … ]]; then main "$@"; fi` | n/a — the `if` form was always the source-safe one | §F-5 |

**Deprecated / outdated in this repo:**
- `docs/dots-hyprland-workflow.md:344` — "unowned work with no owning phase" for the session bootstrap. Now owned (Phase 17 / START-02, Phase 20 / START-01). Update alongside the D-19 block.
- The same sentence's path `.planning/phases/15-playbook-safe-vs-full/15-DOC-SWEEP.md` — Phase 15 is archived under `.planning/milestones/v0.3-phases/`.
- `.gitignore:1-2` — anchored at a repo-root `.config/system_monitor/` that does not exist (§F-8).

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| GNU Stow | FIX-01, CAP-04, D-19 recovery | ✓ | 2.4.1-1 | — |
| bash | every script, `bash -n` gate | ✓ | 5.3.15(1) | — |
| systemd (user) | START-02, START-03 | ✓ | 261 (261.2-1-arch) | — |
| git | FIX-06 | ✓ | system | — |
| `realpath` | FIX-04 (D-05) | ✓ | coreutils | — |
| `cmp` | D-22 | ✓ | diffutils | — |
| `hyprctl` | criterion 2 | ✓ | live session, `configProvider: lua` | — |
| `script(1)` | D-04 transcript | ✓ | util-linux | — |
| **gitleaks** | **FIX-06 / criterion 4** | **✗** | — in `extra` at 8.30.1-1 | **none** — `sudo pacman -S --needed gitleaks` is a prerequisite task |
| shellcheck | optional lint | ✗ | — | `bash -n` (what criterion 1 names) |
| pacman / yay | criterion 2 run | ✓ | system | — |

**Missing dependencies with no fallback:**
- **gitleaks.** The FIX-06 wave must open with `sudo pacman -S --needed gitleaks`. No alternative scanner is installed (trufflehog, detect-secrets, git-secrets all absent [VERIFIED]) and D-11 locks the choice anyway. The install needs `sudo`, so it is an operator-adjacent step — but it is additive and reversible, unlike the criterion-2 run.

**Missing dependencies with fallback:**
- shellcheck → `bash -n`. Criterion 1 names `bash -n` explicitly, so nothing is blocked. Worth a deferred-idea row: shellcheck would have caught both §F-3 and §F-5 statically.

---

## Validation Architecture

**This is the primary deliverable of this research run.** `workflow.nyquist_validation` is `true` in `.planning/config.json` [VERIFIED]. The section below is what `17-VALIDATION.md` should be derived from.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | **None third-party.** The repo's convention is standalone bash assert scripts under `scripts/`, following the `[PASS]`/`[FAIL]`/`[INFO]` contract |
| Config file | none — each assert script is self-contained with its own `REPO_ROOT`, `FAIL` counter, and `pass()`/`fail()`/`info()` helpers |
| New artifact | `scripts/phase17-unblock-assert.sh` (D-20) — modelled on `scripts/phase16-retire-assert.sh` |
| Quick run command | `./scripts/phase17-unblock-assert.sh` |
| Full suite command | `./scripts/phase17-unblock-assert.sh && ./scripts/phase16-retire-assert.sh && ./scripts/phase13-d19-assert.sh && ./scripts/phase14-verify.sh` |
| Exit contract | `exit 1` iff `FAIL>0`; closing line `=== done: FAIL=n ===` |

**Pre-existing suites that must stay green** (the Phase 16 D-40 gate, per STATE.md): `phase16-retire` FAIL=0, `phase12-full-smoke` FAIL=0, `phase11-dispositions` FAIL=0, `phase10-inventory` FAIL=0, `phase13-d19` FAIL=0, `phase14-verify` FAIL=0 FINDINGS=1. **Note:** `phase14-verify.sh:443` emits its one allowed `[FINDING]` precisely *because* `graphical-session.target` is inactive [VERIFIED: read this session]. **After the operator re-login lands criterion 5, that script will flip to `FINDINGS=0`** and line 441's `info "D-38 graphical-session.target is active"` will fire instead. Any plan or doc that asserts the literal `FAIL=0 FINDINGS=1` — including `docs/dots-hyprland-workflow.md:328` and `:331` — becomes wrong at that moment. **Update `docs/dots-hyprland-workflow.md:328,331` as part of the START-02 wave, or the phase leaves the playbook asserting a stale expected output.** This is a cross-script coupling that neither CONTEXT.md nor the ROADMAP records.

### Phase Requirements → Test Map

| Criterion | Req | Behavior | Test type | Automated command | Exists? |
|-----------|-----|----------|-----------|-------------------|---------|
| 1a | FIX-01 | No `-v=5` at any `arch/` stow site | static grep | `! grep -rn -- '-v=5' arch/` | ❌ Wave 0 |
| 1b | FIX-01, CAP-04 | All 15 sites carry `--verbose=5` **and** `--no-folding` | static grep, counted | `[[ "$(grep -rhc -- '--verbose=5 --no-folding' arch/*.sh \| paste -sd+ \| bc)" == 15 ]]` | ❌ Wave 0 |
| 1c | FIX-01 | `bash -n` passes on all 14 files | syntax | `for f in <14 files>; do bash -n "$f"; done` | ❌ Wave 0 |
| 1d | CAP-04 | *(recommended, §F-7)* docs carry no `-v=5` | static grep | `! grep -rn -- '-v=5' docs/` | ❌ Wave 0 |
| 1e | FIX-01 | *(recommended)* a real stow dry-run accepts the new flags | behavioral, non-mutating | `cd stow && stow --verbose=5 --no-folding -n -t ~ btop` → exit 0 | ❌ Wave 0 |
| 2a | FIX-02 | No `cp -rf .config/hypr/*` in `arch/hyprland.sh` | static grep | `! grep -F 'cp -rf .config/hypr/' arch/hyprland.sh` | ❌ Wave 0 |
| 2b | FIX-02 | No cwd-relative path in `arch/hyprland.sh` | static grep | `! grep -nE '(^\|[[:space:]])\.config/' arch/hyprland.sh` | ❌ Wave 0 |
| 2c | FIX-02 | Phase 20 / HYPR-01 marker comment present | static grep | `grep -q 'HYPR-01' arch/hyprland.sh` | ❌ Wave 0 |
| **2d** | FIX-02 | **Script runs end-to-end, exit 0** | **live, one-way** | **OPERATOR — `script -c 'bash "$PWD/arch/hyprland.sh"' <transcript>`** | ❌ manual-only |
| **2e** | FIX-02 | **`configProvider` still `lua` after the run** | **live** | `hyprctl -j status \| jq -r .configProvider` → `lua` (parsed from transcript post-run) | ❌ semi-manual |
| 3a | FIX-04 | `safe_rm_path` refuses existing repo paths | fixture, non-mutating | sourced-subshell loop over 3 existing repo paths, assert non-zero (§Pattern 2) | ❌ Wave 0 |
| 3b | FIX-04 | Pre-existing `$HOME` clause still refuses | fixture (negative control) | `safe_rm_path /etc/passwd` → non-zero | ❌ Wave 0 |
| 3c | FIX-04 | Pre-existing hypr clause still refuses | fixture (negative control) | `safe_rm_path "$HOME/.config/hypr/custom"` → non-zero | ❌ Wave 0 |
| 3d | FIX-04 | The wrapper is sourceable at all (D-09) | fixture | `( source arch/dots-hyprland.sh; type -t safe_rm_path )` → `function` | ❌ Wave 0 |
| 4a | FIX-06 | `.gitattributes` exists with the exact line | static | `grep -Fxq '* text=auto eol=lf' .gitattributes` | ❌ Wave 0 |
| 4b | FIX-06 | New `.gitignore` patterns actually match their targets | behavioral | `git check-ignore -v <path>` → exit 0, per pattern | ❌ Wave 0 |
| 4c | FIX-06 | Secret scan is re-runnable and reports zero **unreviewed** findings | behavioral | `gitleaks detect --redact --exit-code 1` (history) **and** `gitleaks dir . --redact --exit-code 1` (tree) | ❌ Wave 0 |
| 4d | FIX-06 | Every accepted finding carries a reason (D-13) | static | if `.gitleaks.toml` exists, each `[[rules.allowlist]]`/`[allowlist]` entry has a comment | ❌ Wave 0, conditional |
| 5a | START-02 | Repo `execs.lua` carries the literal command | static grep (D-22) | `grep -Fq 'systemctl --user start hyprland-session.service' .config/hypr/custom/execs.lua` | ❌ Wave 0 |
| 5b | START-02 | Repo and live `execs.lua` byte-identical | behavioral (D-22) | `cmp -s .config/hypr/custom/execs.lua ~/.config/hypr/custom/execs.lua` | ❌ Wave 0 |
| 5c | START-02 | Unit is `linked`, never `enabled` (D-17) | behavioral | `[[ "$(systemctl --user is-enabled hyprland-session.service)" == linked ]]` | ❌ Wave 0 |
| 5d | START-02 | Service start activates the target (mechanism) | behavioral, **proven §F-11** | `systemctl --user start hyprland-session.service && systemctl --user is-active graphical-session.target` — *mutating; see note* | ❌ Wave 0 |
| **5e** | START-02 | **Target active after a fresh login** | **manual-only (D-23)** | `systemctl --user is-active graphical-session.target` → `[PASS]` / `[INFO]` | ❌ manual-only |
| 6a | START-03 | Warning block present in the playbook | static grep | `grep -q 'systemctl --user disable' docs/dots-hyprland-workflow.md` | ❌ Wave 0 |
| 6b | START-03 | Recovery command present | static grep | `grep -Fq 'stow --verbose=5 --no-folding -t ~ systemd' docs/dots-hyprland-workflow.md` | ❌ Wave 0 |
| 6c | START-03 | `mask` named as the safe alternative | static grep | `grep -q 'systemctl --user mask' docs/dots-hyprland-workflow.md` | ❌ Wave 0 |

**Note on 5d.** It is the only *mutating* check in the set, and D-20's non-mutating header note forbids it in the assert script. Two options: (a) keep it out of `phase17-unblock-assert.sh` and run it once, by hand, during the START-02 wave, recording the transcript — this preserves D-20; or (b) gate it behind an opt-in flag (`--live`) that the default invocation never sets. **Recommend (a)** — the mechanism is already proven (§F-11), so re-proving it on every assert run buys nothing and costs the script its non-mutating guarantee. If the plan wants a standing check, use the read-only `systemctl --user show hyprland-session.service -p ActiveEnterTimestamp` probe described in §Sequencing Hazard 2 instead.

### Sampling Rate

Nyquist framing: sample often enough that no change can land and go undetected between observations.

- **Per task commit:** `./scripts/phase17-unblock-assert.sh` — target runtime under 5 s (all greps, one `bash -n` loop, one sourced subshell, one `cmp`; the only slow member is gitleaks, which is seconds on a 96-file tree). Every task in this phase touches something the script asserts, so per-commit is the right rate.
- **Per wave merge:** the assert script **plus** the pre-existing suite that the wave could plausibly disturb:
  - FIX-01/CAP-04 wave → `+ phase16-retire-assert.sh` (it runs `bash -n arch/dots-hyprland.sh` at line 46 and captures `--dry-run` argv)
  - FIX-04 wave → `+ phase16-retire-assert.sh` (same file is edited) `+ phase13-d19-assert.sh` (it drift-pins `arch/dots-hyprland.sh` against a baseline — **any edit to that file will move the drift pin; check the baseline logic before the wave, per STATE.md's note that `16-DOC-SWEEP.md` is load-bearing for that selection**)
  - FIX-06 wave → `+ phase14-verify.sh` (it asserts a clean working tree, D-35)
  - START-02/03 wave → `+ phase14-verify.sh` (it emits the D-38 finding at line 443 — see the `FINDINGS=1 → 0` coupling above)
- **Phase gate:** full suite green on a clean tree, matching the Phase 16 D-40 gate shape: `phase17-unblock` FAIL=0, `phase16-retire` FAIL=0, `phase12-full-smoke` FAIL=0, `phase11-dispositions` FAIL=0, `phase10-inventory` FAIL=0, `phase13-d19` FAIL=0, `phase14-verify` FAIL=0 (FINDINGS=1 pre-re-login, 0 after). Transcript quoted verbatim into the phase summary, per the Phase 16 precedent.
- **Post-re-login (operator-owned, out-of-band):** `./scripts/phase17-unblock-assert.sh` re-run. Criterion 5e must flip `[INFO]` → `[PASS]`, and `phase14-verify.sh` should flip `FINDINGS=1` → `FINDINGS=0`. **This is the only observation the phase cannot schedule**; everything else is on the per-commit clock.
- **Criterion 2 (operator-owned, one-way):** one observation only. Sampled via a `script(1)` transcript with `hyprctl -j status` captured immediately before and immediately after. Not repeatable — a second run reinstalls packages — so the transcript *is* the record.

### Observation Points — what is machine-assertable vs. what needs a human

| Class | Criteria | Count | Rate |
|-------|----------|-------|------|
| **Fully automated, non-mutating** | 1a-1e, 2a-2c, 3a-3d, 4a-4d, 5a-5c, 6a-6c | **21 of 26** | per task commit |
| **Automated but mutating** — run once by hand, keep out of the assert script | 5d | 1 | once, in the START-02 wave |
| **Operator re-login only** | 5e | 1 | once, out-of-band, after the phase |
| **Operator live run, one-way** | 2d, 2e | 2 | once, terminal wave, transcripted |
| **Operator decision gate** (not a test, but a blocking observation) | FIX-06 `.env` triage (§Hazard 3) | 1 | once, before the FIX-06 wave |

**21 of 26 checks are machine-assertable on every commit.** That is a high Nyquist ratio for a phase whose headline risk is "an agent cannot end the session" — the re-login blocks exactly **one** sub-claim, not the criterion and certainly not the phase.

### Wave 0 Gaps

- [ ] `scripts/phase17-unblock-assert.sh` — the whole harness; covers criteria 1-6 (D-20)
- [ ] `sudo pacman -S --needed gitleaks` — prerequisite for 4c, **no fallback**
- [ ] Operator decision on the tracked `.env` (§F-8 / §Hazard 3) — blocks 4c's "zero findings" wording
- [ ] Pinned invocation form for `arch/hyprland.sh` recorded in `docs/dots-hyprland-workflow.md` — blocks 2d (§F-3)
- [ ] Update `docs/dots-hyprland-workflow.md:328,331` for the `FINDINGS=1 → 0` flip — otherwise the playbook asserts a stale expected output the moment criterion 5 lands
- [ ] Check `scripts/phase13-d19-assert.sh`'s drift-pin logic before editing `arch/dots-hyprland.sh` — STATE.md records that `16-DOC-SWEEP.md`'s presence selects the baseline

No test framework install is needed — the repo's convention is standalone bash scripts, and `bash` is present.

---

## Security Domain

`workflow.security_enforcement: true`, `security_asvs_level: 1` [VERIFIED: `.planning/config.json`]. This phase has no network surface, no authentication, no session tokens, and no user-facing input — it is local shell scripts plus a secret scan. The applicable categories are narrow and real.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | No auth surface |
| V3 Session Management | no | `graphical-session.target` is a systemd desktop-session target, not an auth session |
| V4 Access Control | **partially** | The `sudo` calls in `arch/hyprland.sh` (5× `pacman`, 1× `usermod -aG i2c`) run with elevated privilege. Control: they are pre-existing, operator-initiated, and transcripted (D-04). `usermod -aG i2c` widens the operator's group membership permanently — flag it in the criterion-2 task text as a durable privilege change |
| V5 Input Validation | **yes** | `safe_rm_path` is a path-validation function guarding `rm -rf`. Control: `realpath -m` canonicalisation on both sides before comparison (D-05) — the standard defence against symlink/`..` traversal. `rm -rf -- "$path"` already uses `--` to end option parsing [VERIFIED: line 449] |
| V6 Cryptography | no | No crypto is written or configured |
| V7 Error Handling & Logging | **yes** | D-07's abort-with-`[FAIL]`-naming-the-path is correct: fail closed, log the offending value. No `--force` override (D-07) |
| V8 Data Protection / V14 Configuration | **yes** | `.gitattributes` + `.gitignore` + gitleaks (FIX-06). The tracked `.env` (§F-8) is the live instance of this category |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation | Status in this phase |
|---------|--------|---------------------|----------------------|
| Path traversal / symlink escape reaching `rm -rf` | **Tampering**, Denial of Service | Canonicalise both sides (`realpath -m`), prefix-compare, fail closed | **The FIX-04 deliverable.** D-05 specifies exactly this. §F-4 documents the two clause-ordering traps that would leave it ineffective |
| Secret committed to VCS | **Information Disclosure** | Secret scanner over history + working tree; rotate on discovery; scope ignores correctly | **The FIX-06 deliverable.** §F-8 found one live instance (tracked `.env`) and two ignore patterns that do not reach it |
| Unvalidated destructive operation with no confirmation | Tampering, DoS | Explicit gate + fail-closed guard | Already present: `run_uninstall`'s exact-token `yes` gate at `arch/dots-hyprland.sh:419-424` [VERIFIED], plus `safe_rm_path` |
| Supply-chain / typosquat on a new dependency | **Spoofing**, Tampering | Install from a signed distro repo; verify upstream URL | **Live hazard here** — npm's `gitleaks` is `ycjcl868/gitleaks`, not `gitleaks/gitleaks` [VERIFIED, §Package Legitimacy Audit]. Mitigated by `pacman -S` from `extra` |
| Privilege escalation via group membership | **Elevation of Privilege** | Explicit, reviewed, documented | `usermod -aG i2c "$USER"` at `arch/hyprland.sh:18` is pre-existing and unowned by any Phase 17 requirement. **Record it as a finding in the criterion-2 transcript notes** — an operator running criterion 2 should know their groups change |
| Unattended `stow --adopt` pulling foreign content into the repo | Tampering | Ban `--adopt` from scripts | Out of scope (CAP-07, a later phase). Verified absent from all 15 sites today [VERIFIED, §F-1] — nothing to do, but do not introduce it |

**Threats introduced by this phase: zero.** Every change either removes a destructive capability (`cp -rf` deletion, `safe_rm_path` clause), adds a detection capability (gitleaks, `.gitattributes`/`.gitignore`), or restores a lost one (`graphical-session.target`, which is a *prerequisite* for the ScreenCast portal — a functionality restoration, not a new exposure). The one net-new privilege surface is the `sudo` in the criterion-2 run, which is pre-existing script content executed under an operator checkpoint.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A restored `hyprland.conf` would take precedence over `hyprland.lua` and flip `configProvider` away from `lua` | §F-2 | **Low.** Only the *rationale* for FIX-02 depends on it; the deletion is justified regardless because the `cp -rf` demonstrably restores a file the live tree deliberately renamed away, and because it writes through symlinks (a Phase 20 hazard). Criterion 2's `configProvider: lua` assertion is a direct observation and does not rest on this |
| A2 | `systemctl --user mask` on a unit whose config-directory entry is already a stow symlink will replace that link, so `unmask` must be followed by a re-stow | §F-12 | **Low.** Affects one sentence of the D-19 warning block. Mitigation: write the block so the re-stow recovery is given unconditionally ("after any `disable`, `mask`, or `unmask`, re-stow and `daemon-reload`"), which is correct either way. Or probe it with the same throwaway-unit technique §F-12 used |
| A3 | gitleaks 8.30.1's default `detect` mode scans git history while `dir` mode scans the working tree | §Pitfall 4, test 4c | **Medium.** If the sub-command names differ in 8.x, criterion 4c's command is wrong and the scan may silently cover less than intended. Mitigation: run `gitleaks --help` as the first task of the FIX-06 wave and pin the exact sub-commands in the assert script. Cheap to check, expensive to get wrong (a false green on a secret scan) |
| A4 | The `phase17-unblock-assert.sh` runtime target of "under 5 s" | §Sampling Rate | **Very low.** Affects the per-commit sampling rate recommendation only. If gitleaks is slow on full history, move 4c to per-wave and keep the rest per-commit |
| A5 | `scripts/phase13-d19-assert.sh` drift-pins `arch/dots-hyprland.sh` and will move when FIX-04/D-09 edit it | §Sampling Rate, Wave 0 | **Medium.** Derived from STATE.md's recorded Phase 16 decisions (the `0771cc2` pin, and `16-DOC-SWEEP.md` as a load-bearing marker for baseline selection), **not** from reading `phase13-d19-assert.sh` this session. If the pin is content-addressed rather than commit-addressed, the FIX-04 wave turns a green suite red and the cause is non-obvious. **Read `scripts/phase13-d19-assert.sh` during planning** |

---

## Open Questions

1. **Does criterion 1 / CAP-04 reach `docs/phase14-adopt-runbook.md:247`?**
   - What we know: it is a 16th `-v=5`, in a copy-pasteable operator command, and it exits 1 [VERIFIED, §F-7]. Criterion 1 is scoped to `arch/`; CAP-04 says "every stow invocation in the repo".
   - What's unclear: whether the operator intends CAP-04's "in the repo" to include documentation.
   - Recommendation: **fix it.** A broken documented recovery command is a worse defect than a broken script, because it fails at the moment someone is already recovering from something. Add a docs-scoped grep to the assert script (test 1d). Scope it to `docs/` so `.planning/research/PITFALLS.md:475` — frozen history — stays untouched.

2. **How is criterion 2's "no cwd-relative path" satisfied given `"$(dirname "${BASH_SOURCE[0]}")/../stow"` is itself cwd-relative when `BASH_SOURCE[0]` is?**
   - What we know: the double-`cd` failure is verified across four invocation forms (§F-3), and D-01 locks the `cd` idiom verbatim.
   - What's unclear: whether D-01's "verbatim" was written knowing the second `cd` was broken (it predates this finding).
   - Recommendation: pin the invocation form in the runbook (no code change, D-01 fully respected) **and** surface the finding to the operator. If they prefer the code fix, it is a one-line `SCRIPT_DIR` hoist in `arch/hyprland.sh` only — but that is a CONTEXT amendment and should be recorded as one, not absorbed.

3. **Can criterion 4's "zero findings" survive the tracked `.env` in git history?**
   - What we know: the file is tracked; its contents were deliberately not read; `.gitignore` does not cover it; a `git rm --cached` leaves history intact (§F-8).
   - What's unclear: whether it holds a live credential. Only the operator can say.
   - Recommendation: a `checkpoint:human-verify` at the **top** of the FIX-06 wave, before gitleaks is even installed. Three outcomes: no live secret → allowlist with a reason (D-13-compliant); live secret → rotate, `git rm --cached`, allowlist the historical blob with a reason recording the rotation; operator wants history clean → out of scope, escalate.

4. **Does `.config/kdeglobals` get untracked this phase or handed to Phase 18?**
   - What we know: it is tracked, so D-14's ignore line alone is a no-op (§F-9). Repo-root `.config/` is FIX-03 / Phase 18 territory.
   - Recommendation: add the pattern, **do not** `git rm --cached`, and add a handoff row to Phase 18 next to D-18's `execs.lua` row. If the operator wants it untracked now, make it a separately-reviewed task so it does not ride in on a hygiene commit.

5. **Which assert-script output contract — three-prefix or four?**
   - What we know: D-20 says `[PASS]`/`[FAIL]`/`[INFO]` + `=== done: FAIL=n ===` (the phase16 shape); CONTEXT's `<code_context>` describes the four-prefix, two-counter phase14 shape. Both files were read and both contracts exist in the repo [VERIFIED].
   - Recommendation: **D-20 governs** — it is the locked decision and the more specific instruction. Three prefixes, one counter. D-23 routes the single non-assertable case through `[INFO]`, which is precisely why a `FINDINGS` counter is unnecessary. Noted here only so the planner does not "fix" the script toward the other contract mid-phase.

---

## Sources

### Primary (HIGH confidence) — live probes and verbatim reads, this session

- `arch/hyprland.sh` (33 lines, full read) — lines 24-26, 29, 33
- `arch/dots-hyprland.sh:1-60, 418-470, 771-805` — `safe_rm_path`, `main`, globals, dispatch
- `arch/{alacritty,btop,define,fish,kitty,nvim,rofi,tmux,wezterm,xterm,yazi,zsh,zsh_powerlevel}.sh` — the 13 other stow sites, via `grep -rn`
- `scripts/phase16-retire-assert.sh:1-60, tail 15` — the D-20 harness model
- `scripts/phase14-verify.sh:28, 37-41, 438-465, 524, tail 12` — the four-prefix contract and the D-38 finding block
- `.gitignore` (19 lines, verbatim), `.gitattributes` (absent)
- `docs/dots-hyprland-workflow.md:325-364`, `docs/phase14-adopt-runbook.md:243-255`
- `.planning/research/PITFALLS.md` — lines 30, 84, 184, 210, 288, 312, 316-321, 475, 497, 516
- `.planning/REQUIREMENTS.md:15-20, 24-31, 35-43`; `.planning/ROADMAP.md` Phase 17 block; `.planning/STATE.md`; `.planning/config.json`
- `.config/hypr/custom/{general.lua:1, execs.lua}`, `~/.config/hypr/{hyprland.lua, custom/execs.lua, hyprland/execs.lua}`, `.config/hypr/hyprland.conf:55-57`
- `stow/systemd/.config/systemd/user/hyprland-session.service` (15 lines, full read)
- **Live falsification probes:** `stow -v=5` → exit 1; double-`cd` across 4 invocation forms; `source arch/dots-hyprland.sh` → subshell exits before `safe_rm_path`; `&&`-guard vs `if`-guard under `set -e`; `systemctl --user disable` on a throwaway `linked` unit → `Removed '…'`; `systemctl --user start hyprland-session.service` → target `inactive → active`, unit still `linked`, reverted; `systemctl --user start graphical-session.target` → exit 4 `RefuseManualStart`; `git check-ignore` anchoring decoy
- **Tool versions:** `stow (GNU Stow) version 2.4.1` / `stow 2.4.1-1`; `GNU bash 5.3.15(1)`; `systemd 261 (261.2-1-arch)`; `pacman -Si gitleaks` → `extra`, `8.30.1-1`
- `systemctl(1)` DISABLE (local man page, systemd 261, lines 749-757)
- `gsd-tools query package-legitimacy check --ecosystem npm gitleaks` — the cross-ecosystem homonym

### Secondary (MEDIUM confidence)

- `gitignore(5)` pattern-anchoring semantics — corroborated by the decoy probe above
- `systemd.unit(5)` `PartOf=` propagation semantics — corroborated by the reverse-dependency listing
- `gsd-tools query classify-confidence` — tier derivation

### Tertiary (LOW confidence)

- None. **No WebSearch, Context7, or external fetch was performed.** Every question this phase raises is answerable from the working tree and the live machine, and local evidence is strictly stronger than a web result for all of them. The `research-plan` seam was therefore not exercised for external providers; the confidence and legitimacy seams were.

---

## Metadata

**Confidence breakdown:**

- **Defect inventory:** HIGH — every located fact re-derived from the working tree this session, quoted verbatim with file:line. Nothing in CONTEXT.md was falsified.
- **Standard stack:** HIGH — all versions from live `pacman -Q` / `--version` output, not training memory. The one uninstalled dependency (gitleaks) verified against the live `pacman -Si`.
- **Architecture / mechanisms:** HIGH — the three load-bearing mechanisms (stow flags, `source`-safety, `graphical-session.target` activation) were each proven with a probe whose output is pasted in-line, including the `disable` footgun and the `RefuseManualStart` refusal.
- **Pitfalls:** HIGH for 1-6 (each tied to a probe or a verbatim read); MEDIUM for 7 (the `-Sy` hazard is well-established Arch practice, and the call sites are verified, but no partial-upgrade failure was reproduced).
- **Validation architecture:** HIGH on what is assertable (21 of 26 checks have a concrete command); MEDIUM on the gitleaks sub-command spellings (A3) and the `phase13-d19` drift-pin coupling (A5), both flagged as plan-time reads.
- **Security domain:** HIGH — narrow surface, no new exposure, one live supply-chain hazard identified and mitigated.

**Research date:** 2026-09-12
**Valid until:** 2026-10-12 (30 days — a stable, in-repo domain; the only external moving part is the gitleaks package version, and D-11 already pins the expectation at 8.30.1-1)

**Live-session side effects of this research run:** two, both reverted and verified reverted. (1) A throwaway `gsd-probe-unit.service` symlink was created in `~/.config/systemd/user/`, `disable`d as the §F-12 falsification, then removed with a `daemon-reload`; the real `hyprland-session.service` symlink was confirmed intact before and after. (2) `hyprland-session.service` was started and immediately stopped for the §F-11 probe; `graphical-session.target` returned to `inactive`, so criterion 5's evidence is uncontaminated. No repo file was modified — `git status --porcelain` was empty at the start of the run and no write occurred outside the scratchpad and this document.
