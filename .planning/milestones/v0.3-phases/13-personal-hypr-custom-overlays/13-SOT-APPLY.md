# Phase 13: Overlay source of truth and apply policy

Authoring SoT fence (D-01..D-05) plus the D-18 apply command and D-19 in-repo verify. Do not run apply in Phase 13 (D-02, D-17). Phase 14 runs apply.

## Authoring SoT

Authoring SoT is parent-repo `.config/hypr/custom/` (D-01, D-05). Edit overlays there. Live `~/.config/hypr/custom/` is an applied copy, not the place you edit for the next machine.

Vendor/submodule `vendor/dots-hyprland` and the personal fork remain product SoT. Never commit machine overlays into vendor or the fork (D-04).

## Apply direction

Apply is one-way repo → live after the full files install. There is no sync daemon. Persist a live tweak by copying it back into repo `.config/hypr/custom/` (D-03).

Phase 13 writes the overlay files and this rule. Phase 14 runs apply. Do not rewrite the wrapper `--full` / SAFE_DEFAULTS path in this phase (D-02, D-22).

## DP-1 scale (D-13)

If Phase 14 live adopt shows the wrong DP-1 scale, leave Phase 13 files as written. Record the live result in Phase 14; copy-back (D-03) is how a live fix re-enters the repo.

## Apply command (D-18)

Phase 14 runs this from the repo root after the full files install. **Do not run it in Phase 13.** Do not mutate live `$HOME/.config` now (D-17).

Named files only: `general.lua`, `env.lua`, `execs.lua`. Never `rsync --delete`. Never copy `keybinds.lua`, `rules.lua`, or `variables.lua`. Overwrite ii seeds if present.

Fail the apply if repo `general.lua` is missing (layout required). If repo `env.lua` or `execs.lua` is missing: warn and continue — do not skip the whole apply solely because a slot file is absent.

After apply: reload Hyprland or re-login before expecting dual-head. Upstream `create_custom_config.lua` seeds live custom files after require; reload is commented out upstream, so a re-login is the reliable way to pick up the overlay.

```bash
# Phase 14 only. Do not run in Phase 13 (D-02, D-17).
set -euo pipefail
REPO_CUSTOM=".config/hypr/custom"
LIVE_CUSTOM="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/custom"

mkdir -p "$LIVE_CUSTOM"

# Fail if repo general.lua is missing (layout required).
if [ ! -f "$REPO_CUSTOM/general.lua" ]; then
  echo "FAIL: repo $REPO_CUSTOM/general.lua is missing; abort apply" >&2
  exit 1
fi
cp -a "$REPO_CUSTOM/general.lua" "$LIVE_CUSTOM/"

for slot in env.lua execs.lua; do
  if [ -f "$REPO_CUSTOM/$slot" ]; then
    cp -a "$REPO_CUSTOM/$slot" "$LIVE_CUSTOM/"
  else
    echo "WARN: repo $REPO_CUSTOM/$slot missing; continuing without it" >&2
  fi
done
```

Persist live tweaks by copy-back into repo `.config/hypr/custom/` (D-03). No sync daemon.

## In-repo verify (D-19)

Run from repo root. This is the disk proof for OVL-01/OVL-02/OVL-03 (D-20). Do not treat CONTEXT.md, RESEARCH.md, or PLAN.md as completion.

```bash
test -s .config/hypr/custom/general.lua
test -f .config/hypr/custom/env.lua
test -f .config/hypr/custom/execs.lua
# do NOT test -s env.lua or execs.lua
test -f .planning/phases/13-personal-hypr-custom-overlays/13-SOT-APPLY.md

grep -q 'DP-1' .config/hypr/custom/general.lua
grep -q 'HDMI-A-2' .config/hypr/custom/general.lua
grep -q 'hl.workspace_rule' .config/hypr/custom/general.lua
grep -q 'special:social' .config/hypr/custom/general.lua
grep -q 'scale = "auto"' .config/hypr/custom/general.lua
grep -q 'cp -a' .planning/phases/13-personal-hypr-custom-overlays/13-SOT-APPLY.md

test ! -e .config/hypr/monitors.lua
test ! -e .config/hypr/workspaces.lua
test ! -e .config/hypr/custom/keybinds.lua
test ! -e .config/hypr/custom/rules.lua

! grep -Eiq 'XCURSOR_|setcursor|ILLOGICAL_IMPULSE_VIRTUAL_ENV' .config/hypr/custom/*.lua
! grep -Eiq 'google-chrome|vesktop|discord|waybar|swaync|qs -c ii' .config/hypr/custom/*.lua
test -z "$(git -C vendor/dots-hyprland status --short -- dots/.config/hypr/custom)"
```
