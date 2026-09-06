# Phase 15 doc staleness sweep

Scope: the D-20 sweep of operator-facing and planning prose for post-adopt staleness, applying the D-22 rule that frozen planning artifacts are flagged here rather than rewritten, with `.planning/PROJECT.md` product-surface lines as D-22's stated correction exception.

This is a findings report, not operator instruction. Stale strings are quoted verbatim below on purpose, which is why this phase's forbidden-string assertions are scoped to the operator-facing docs and never to this file.

## Corrections applied

| File | Line | Stale text | Correction | Evidence |
|------|------|-----------|------------|----------|
| `.planning/PROJECT.md` | 18 | ``(`hyprctl getoption configProvider` → `lua`)`` | ``(`hyprctl -j status` reports `configProvider: lua`, where the pre-adopt baseline recorded `hyprlang`)`` | `hyprctl getoption configProvider` returns `no such option` on Hyprland 0.56.2 for all three spellings tried; `hyprctl -j status` returns `{"configProvider": "lua", "backend": "drm"}`. `scripts/phase14-verify.sh:168-173` reads exactly that path — `STATUS_JSON="$(hypr_json -j status)"` then `jq -r '.configProvider // empty'`. Pre-adopt value `configProvider_pre=hyprlang` from `14-PRE-ADOPT-BASELINE.txt`. |
| `.planning/PROJECT.md` | 28 | ``- Rollback: `~/ii-original-dots-backup.20260904T171128Z` (tier 1)`` | ``- Rollback: `~/ii-original-dots-backup` (tier 1)`` | The `hyprland.conf` inside `~/ii-original-dots-backup/` hashes to `3d17932a6d2dd1b61ccc509402a70c224409bb5c24c4ed70a3c55d4f4bcd89b5`, matching `hyprland_conf_sha256` in `14-PRE-ADOPT-BASELINE.txt:7`. The conf inside `~/ii-original-dots-backup.20260904T171128Z/` hashes to `c5c65023dcdb0a202c6e73e32320daf8e6343b00a394fc3bfcf8d5be39867bfe`, which is the July config recorded as `backup_dir_hyprland_conf_sha256` at line 34 — the rotated stale backup, not a rollback source. `arch/dots-hyprland.sh:21` confirms the wrapper's own default `II_BACKUP_DIR` has no timestamp suffix. |
| `docs/phase14-adopt-runbook.md` | 334-336 | ``# 3. The rotated backup directory … Use the timestamped directory section 5 created, or ~/ii-original-dots-backup/ if section 5 did not run.`` | Tier-1 source 3 now names `~/ii-original-dots-backup/`, cites the matching fixture sha256, states explicitly that the timestamped directory must not be restored from, and carries the `cp -a` line the other two tier-1 sources already had. | Same sha256 comparison as the row above. The prior wording sat inside rollback tier 1 and sent a recovering operator to the stale July config; correcting a factually false post-adopt line is D-21, and the edit is minimal and in place per D-02. Confirmed at the plan `15-01` Task 1 decision gate (option `verified`). |

## Reviewed, no findings

_To be filled by plan `15-06`._

## Flagged, not edited (D-22)

_To be filled by plan `15-06`._
