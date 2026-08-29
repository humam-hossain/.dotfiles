# Phase 13: Overlay source of truth and apply policy

Stub authored in plan 13-01. The apply command itself is filled in plan 13-02 (D-18). Do not run apply in Phase 13 (D-02, D-17).

## Authoring SoT

Authoring SoT is parent-repo `.config/hypr/custom/` (D-01, D-05). Edit overlays there. Live `~/.config/hypr/custom/` is an applied copy, not the place you edit for the next machine.

Vendor/submodule `vendor/dots-hyprland` and the personal fork remain product SoT. Never commit machine overlays into vendor or the fork (D-04).

## Apply direction

Apply is one-way repo → live after the full files install. There is no sync daemon. Persist a live tweak by copying it back into repo `.config/hypr/custom/` (D-03).

Phase 13 writes the overlay files and this rule. Phase 14 runs apply. Do not rewrite the wrapper `--full` / SAFE_DEFAULTS path in this phase (D-02, D-22).

## DP-1 scale (D-13)

If Phase 14 live adopt shows the wrong DP-1 scale, leave Phase 13 files as written. Record the live result in Phase 14; copy-back (D-03) is how a live fix re-enters the repo.

## Apply command (filled in 13-02)

Placeholder — plan 13-02 writes the D-18 `cp -a` command here (named files only; fail if repo `general.lua` is missing; warn-and-continue if slot files are missing; never `rsync --delete`; never copy keybinds/rules/variables). Do not run apply now. Do not mutate live `$HOME/.config` in Phase 13 (D-17).
