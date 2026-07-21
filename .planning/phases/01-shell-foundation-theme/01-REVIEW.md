---
phase: 01-shell-foundation-theme
status: issues
depth: standard
reviewed: 2026-07-21T12:50:00Z
reviewer: orchestrator-inline (gap-closure re-review after 01-04)
scope:
  - arch/fonts.sh
  - arch/quickshell.sh
  - .config/quickshell/modules/common/Config.qml
  - .config/quickshell/modules/common/Appearance.qml
  - .config/quickshell/modules/ii/bar/Workspaces.qml
  - .config/quickshell/modules/ii/notificationPopup/NotificationPopup.qml
  - .config/quickshell/modules/settings/InterfaceConfig.qml
  - prior: shapes, MessageCodeBlock, symlink_config
summary:
  critical: 0
  warning: 2
  info: 2
---

# Phase 01 Code Review (post gap-closure 01-04)

**Scope:** Gap-closure fixes for G-01-1 plus prior phase intentional changes.

**Status:** issues (advisory — no Critical)

## Findings

### Warning

1. **`arch/quickshell.sh` — `symlink_config` uses `rm -rf "$QS_DST"`** (pre-existing)
   - **Risk:** Non-symlink destination would be deleted without backup.
   - **Suggestion:** Guard with `if [ -L "$QS_DST" ] || [ ! -e "$QS_DST" ]; then ...; else die; fi`.

2. **Material Symbols system package not installed via pacman** (this session)
   - **Mitigation:** User-local fonts under `~/.local/share/fonts/MaterialSymbols` + scripts install `ttf-material-symbols-variable` on next `arch/fonts.sh` / `arch/quickshell.sh` with sudo.
   - **Risk:** New machines without user fonts or package still hit missing icons until scripts run.

### Info

1. **Config font defaults changed** from Google Sans Flex / Readex / Space Grotesk → Noto Sans + JetBrainsMono Nerd Font. Live `~/.config/illogical-impulse/config.json` also updated (outside repo) so persisted override matches.

2. **`hl.dsp.focus` → stock `workspace`** is intentional host integration (no Hyprland plugins). Upstream dots-hyprland may reintroduce plugin dispatch on wholesale updates — re-apply if needed.

### Gap-closure changes (clean)

- `widgetPadding: 0` on Workspaces — fixes BarContent undefined double.
- `notifications.monitor` alignment — NotificationPopup + InterfaceConfig.
- Appearance `m3*Dim` + palette key props — clears MaterialThemeLoader assign warnings.
- Font package lines in `arch/fonts.sh` / `arch/quickshell.sh` — correct dep for MaterialSymbol glyphs.

### Positive

- Smoke launch after fixes: `Configuration Loaded`; no m3primaryDim / forceMonitor / undefined padding / hl.dsp.focus warnings.
- Gap plan commits atomic (01-04 tasks).

## Recommendation

No Critical blockers. Re-run human UAT (`/gsd-verify-work 1`) for visual bar quality. Optional: `/gsd-code-review 1 --fix` for Warning #1 only.
