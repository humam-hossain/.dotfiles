# Phase 17 → Phase 18 handoff

Three rows Phase 17 produced and deliberately did not act on. Each names the
owning Phase 18 requirement and the reason Phase 17 declined, so that the
decline is a recorded decision rather than an omission.

Phase 18 is *Capture model — three trees and the collision map*
(`.planning/ROADMAP.md`), and owns CAP-01/02/03/05/07/08, FIX-03 and FIX-05.

| # | Row | Owning Phase 18 requirement | Why Phase 17 declined to act |
| --- | --- | --- | --- |
| 1 | The two pre-existing folded directory symlinks under `$HOME/.config`: `qBittorrent` → `stow/qbittorrent/.config/qBittorrent` and `smartmontools` → `stow/smartmontools/.config/smartmontools`, re-emitted as `[INFO]` on every `scripts/phase17-unblock-assert.sh` run | **CAP-01** (tree contracts and recovery commands), with **CAP-02** for the collision-map row | `--no-folding` governs *new* stow runs only, so nothing Phase 17 did could unfold them. Unfolding is a `stow -D` plus a re-stow, and which tree each package belongs to — `stow/`, `restow/` or `capture/` — is the taxonomy Phase 18 defines. Unfolding first and classifying later would encode today's accident as the answer. |
| 2 | `.config/kdeglobals` is still **tracked** in git, while the new `kdeglobals` ignore pattern landed in plan 17-03 governs future writes only | **FIX-03** (retire repo-root `.config/`) | A `.gitignore` line has no effect on a file already in the index, so the pattern is correct and inert by design. Untracking it is a redistribution decision — generated output to be deleted, or a captured file to be moved — and taking it inside an unrelated hygiene commit would remove a decision surface Phase 18 is relying on. Asserted as still-tracked by `4b F-9` so a silent untracking cannot pass unnoticed. |
| 3 | The authoring copy `.config/hypr/custom/execs.lua` — created by plan 17-05 and hand-synced to `~/.config/hypr/custom/execs.lua` by one `cp` | **FIX-03**, whose redistribution table must list it as moving into `stow/hypr/`; claimed live by **HYPR-01** in Phase 20 | `stow/hypr/` does not exist yet, so Phase 17 had nowhere to put it and opened a deliberate, operator-visible hand-sync window instead. **This row is load-bearing: if it goes missing, that window is never closed.** Until it is, byte identity between the two copies is the only thing holding them together, and `scripts/phase17-unblock-assert.sh` section `5b` asserts it with `cmp -s` on every run. |

## What is already asserted, so Phase 18 does not have to re-derive it

- Row 1 is live output, not a note: the D-02 folding audit in
  `scripts/phase17-unblock-assert.sh` re-enumerates the folded symlinks on every
  run and reports `[INFO]` only. If a third one appears, it shows up there.
- Row 2 carries three assertions in section `4b F-9`: the file is still tracked,
  `git check-ignore` exits non-zero on it (an index-aware result, not a dead
  pattern), and under `--no-index` the pattern does reach it.
- Row 3 carries section `5b`, a `cmp -s` byte-identity gate scoped to that one
  file. It is scoped deliberately: the live `custom/` directory legitimately
  holds four files the repo copy does not, so a directory comparison would go
  red on a difference Phase 17 does not own.
