# Phase 3 Plugin Audit Rules

Phase 3 uses an aggressive audit posture. Plugins do not remain by inertia. Every plugin must earn its keep based on strong day-to-day value, reliability, and fit with the cleaned-up cross-platform config (per D-01, D-02, D-03).

## Decision Values

- `keep`: Plugin earns its place now; no Phase 3 action beyond recording; may still receive Phase 4 config modernization.
- `remove`: Plugin is deleted from spec files and lockfile in Plan 03-03; no replacement planned inside v1 scope.
- `replace`: Plugin is deleted in Plan 03-03 and a replacement is deferred to Phase 4 with the replacement target named in the rationale.

## Removal Criteria (Default Disposition)

A plugin is a removal candidate by default if ANY apply (per D-03):

- Novelty-only value (fun/cosmetic with no daily workflow benefit)
- Redundant with another plugin already kept (e.g. duplicate declaration, feature overlap)
- Weak or missing justification for cross-platform shared config
- Stale upstream (no commits in 12+ months) or archived repo
- Drift-prone: large option surface, fragile cross-plugin coupling, or unreliable lazy-load
- Optional/heavy dependencies that degrade on Linux/Windows parity (e.g. image.nvim, 3rd-party binaries)
- Lockfile-only orphan (pinned in `lazy-lock.json` with no matching spec in `lua/plugins/*.lua`)

## Keep Criteria

A plugin earns keep only if ALL apply:

- Provides daily-workflow value (editing, navigation, LSP, git, completion, file tree, search, or visible UI users depend on)
- Works reliably on Arch Linux, Debian/Ubuntu, and Windows without platform-specific forks
- Actively maintained upstream OR stable enough that "no commits" means "complete", not "abandoned"
- No functionally superior alternative already present in the keep set

## Replace Criteria

A plugin is `replace` (not `remove`) when:

- Its domain is still required (LSP, completion, tree, etc.) but the current choice fails keep criteria
- The replacement target is named explicitly (even if the swap itself is deferred to Phase 4)

## Duplicate Resolution Policy

When the same plugin is declared in multiple spec files, the inventory records one row per declaration site with decision `remove` on all but one, and the surviving declaration is chosen by owner-file fit (a domain file like `git.lua` beats a sprawl bucket like `misc.lua`).

## Lockfile-Only Entry Policy

Entries present in `lazy-lock.json` with no corresponding `lua/plugins/*.lua` spec are treated as `remove` in the inventory (orphan pins) unless they are lazy.nvim internals (e.g. `hererocks`).

## Handoff To Phase 4

This document plus `03-PLUGIN-AUDIT.md` is the sole input Plan 03-03 uses to decide which specs to delete and which lockfile entries to prune. Any plugin marked `replace` must not have its replacement installed in Phase 3; that work is deferred to Phase 4.
