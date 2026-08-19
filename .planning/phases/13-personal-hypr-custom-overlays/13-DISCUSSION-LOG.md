# Phase 13: Personal hypr/custom overlays - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-19
**Phase:** 13-Personal hypr/custom overlays
**Areas discussed:** Overlay SoT (2026-08-17), DP-1 scale encoding, Cursor override path, SoT/apply note location, Apply command shape, env.lua after cursor drop, Workspace pin identity, execs.lua comment body, Phase 13 verify bar, post-review trims (empty env.lua, fail if general.lua missing)

---

## Overlay SoT (OVL-03) — 2026-08-17

| Option | Description | Selected |
|--------|-------------|----------|
| Repo `.config/hypr/custom/` | Author and commit overlays in the parent repo. Live is an applied copy. | ✓ (after correction) |
| Live `~/.config/hypr/custom/` only | Live tree is SoT after adopt. Repo only archives. | |
| Personal fork / vendor submodule | Commit overlays inside vendor/dots-hyprland. | |

**User's choice:** Prefer `.config/hypr/custom/` so a completely new machine sets up from the repo.
**Notes:** Upstream does not require any `custom/` files. Overlays exist only to carry machine layout.

### Cold-machine apply (2026-08-17)

| Option | Description | Selected |
|--------|-------------|----------|
| Documented apply after install | Copy repo custom/ onto live after ii seed. Phase 14 runs it. | ✓ |
| Stow or symlink from repo into live | Live custom/ is a symlink/stow of repo files. | |
| Pre-seed live before full install | Write live custom/ before `./setup --full`. | |

**User's choice:** Documented apply after install.

---

## DP-1 scale encoding

| Option | Description | Selected |
|--------|-------------|----------|
| scale = "auto" | Match personal hyprland.conf line 29. | ✓ |
| scale = 1 now | Match Lua wiki / upstream generic monitor. | |
| You decide | Write "auto"; coerce to 1 on type error. | |

**User's choice:** `scale = "auto"`. HDMI-A-2 stays 1.5 + transform 1.

**Follow-ups selected:**
- If Lua rejects `"auto"` at write/verify: change only that field to `1`.
- Verify asserts the literal `scale = "auto"`.
- If Phase 14 live scale is wrong: leave Phase 13 files as written.

---

## Cursor override path

| Option | Description | Selected |
|--------|-------------|----------|
| Env + setcursor in custom/execs.lua | Override upstream Bibata 24. | |
| Env vars only | XCURSOR_* without setcursor. | |
| You decide | Include setcursor hook. | |
| Other | don’t need personal cursor | ✓ |

**User's choice:** Other → “I don't need to do cursor… default hyprland cursor is fine.”
**Notes:** Confirmed interpretation 1: drop cursor entirely. No XCURSOR_*, no setcursor. VIRTUAL_ENV was still in play until the later env.lua area and the post-review trim.

### execs.lua after cursor drop

| Option | Description | Selected |
|--------|-------------|----------|
| Omit execs.lua from the repo | Let ii seed empty live execs.lua. | |
| Commit a comment-only execs.lua | Repo still has the require slot. | |
| Other | “How this is an issue?” then continue | ✓ (commit empty slot) |

**User's choice:** After explanation of hyprland.lua require: commit empty/comment-only execs.lua. Later locked **empty file** (no SoT comment).

---

## SoT/apply note location

| Option | Description | Selected |
|--------|-------------|----------|
| 13-SOT-APPLY.md in the phase directory | Next to CONTEXT.md. | ✓ |
| Overlay-adjacent README or Lua comments | No extra file. | |
| You decide | Same as 13-SOT-APPLY.md. | |

**User's choice:** `13-SOT-APPLY.md`.

---

## Apply command shape

| Option | Description | Selected |
|--------|-------------|----------|
| cp -a the three named files | Cannot delete sibling seeds. | ✓ |
| rsync -a the custom/ directory without --delete | Extra tool; same overwrite. | |
| You decide | cp -a three files. | |

**User's choice:** `cp -a` three named files.

**Follow-ups selected:**
- Overwrite the three named files if live seeds exist.
- If live `custom/` missing: `mkdir -p` then copy.
- Missing repo source (first lock): copy whichever exist, warn, do not fail whole apply.

**Post-review change (operator agreed 2026-08-19):** fail apply if repo **`general.lua` is missing**; warn-only if `env.lua` / `execs.lua` missing. Exact setup must not silently skip the layout file.

---

## env.lua after cursor drop

| Option | Description | Selected |
|--------|-------------|----------|
| Keep ILLOGICAL_IMPULSE_VIRTUAL_ENV only | Duplicate of upstream env.lua. | ✓ (then reversed) |
| Omit VIRTUAL_ENV too — empty env.lua | Rely on upstream. | ✓ (post-review) |
| You decide | Keep VIRTUAL_ENV. | |

**User's choice (in-session):** Keep VIRTUAL_ENV only; write path as upstream Lua `home_dir .. "/.local/state/quickshell/.venv"`; pin-bumps do not auto-edit; no other vars.

**Post-review change (operator agreed):** empty `env.lua` like `execs.lua`. Upstream already sets the same default. Duplicate fights “simple and default.”

---

## Workspace pin identity

| Option | Description | Selected |
|--------|-------------|----------|
| Conf lines 76–87 exactly | 1–5 + special:social → DP-1; 6–10 → HDMI-A-2. | ✓ |
| Numbered 1–10 only; drop special:social | | |
| You decide | Copy conf 76–87. | |

**User's choice:** Conf 76–87 exactly.

**Follow-ups selected:**
- String IDs `"1"`..`"10"` and `"special:social"` (vendor has no numbered example; only `workspace = "special:special"`).
- `monitor` field only — no default/gaps/style.

---

## execs.lua comment body

| Option | Description | Selected |
|--------|-------------|----------|
| One-line policy pointer to 13-SOT-APPLY.md | | |
| Empty file | No Lua, no note. | ✓ |
| You decide | Policy pointer. | |

**User's choice:** Empty file.

---

## Phase 13 verify bar

| Option | Description | Selected |
|--------|-------------|----------|
| Files exist, no D-17, no cursor, scale=auto | In-repo smoke. OVL stays Pending until files committed and checks pass. | ✓ |
| Only that the three files exist | | |
| You decide | Files + no cursor + scale=auto + no D-17. | |

**User's choice:** Files exist, no D-17, no cursor, scale=auto.
**Notes:** After env trim, also assert **no** `ILLOGICAL_IMPULSE_VIRTUAL_ENV` in `custom/`. Do not `test -s` empty `env.lua`/`execs.lua`. CONTEXT/plans are not OVL completion.

---

## Post-review trims (simple/default + new-machine bar)

Operator asked for opinion against: (1) as simple and default as possible; (2) completely new setup, minimum effort, exact layout. Agreed to:

1. Empty `custom/env.lua` (drop VIRTUAL_ENV overlay).
2. Apply fails if `general.lua` missing; warn-only for empty slot files.

---

## Claude's Discretion

- Exact `hl.monitor` keys beyond locked fields
- 0-byte vs newline for empty Lua slots
- `13-SOT-APPLY.md` prose shape
- Verify script shape implementing D-19

## Deferred Ideas

- Phase 14 live apply + adopt; optional one-command install-then-apply
- Phase 15 DOC-04
- Stow/symlink and pre-seed live — rejected
- Personal cursor overlay — dropped
- VIRTUAL_ENV in custom/env.lua — dropped after review
- Execute existing untracked 13-01..03 PLAN.md as-is — do not; replan
