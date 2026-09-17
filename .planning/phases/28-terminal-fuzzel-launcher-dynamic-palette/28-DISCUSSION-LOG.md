# Phase 28: Terminal & Fuzzel Launcher Dynamic Palette - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-17
**Phase:** 28-terminal-fuzzel-launcher-dynamic-palette
**Areas discussed:** Primary Terminal & Reload Strategy, Terminal Opacity & Color Mode, Fuzzel Launcher Theming & Integration, Test Suite & Verification Criteria

---

## Primary Terminal & Reload Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Adopt upstream dots-hyprland baseline with user additions | Adopt upstream dots-hyprland kitty.conf baseline, preserving personal cursor trail settings and adding the dynamic kitty-theme.conf include | ✓ |
| Minimal edit | Keep existing stow/kitty/.config/kitty/kitty.conf unchanged except for prepending the dynamic kitty-theme.conf include line | |
| You decide | Merge upstream dots-hyprland shortcuts/settings with personal font and cursor trail preferences | |

**User's choice:** Adopt upstream dots-hyprland kitty.conf baseline, preserving personal cursor trail settings, but keep zsh (do NOT change shell to fish).
**Notes:** Explicit constraint: Keep zsh as login shell; omit upstream `shell fish`.

| Option | Description | Selected |
|--------|-------------|----------|
| Universal OSC escape sequences | Prioritize Kitty via SIGUSR1 reload, and use universal OSC escape sequences (via apply_anyterm on /dev/pts/*) for secondary terminals without rewriting their config files | ✓ |
| Dedicated Alacritty theming | Add dedicated Alacritty dynamic theme generation (generate alacritty-theme.toml from Matugen and import it in stow/alacritty/alacritty.toml) | |
| You decide | Focus verification on Kitty while keeping the universal /dev/pts broadcast active for any terminal | |

**User's choice:** Prioritize Kitty via SIGUSR1 reload, and use universal OSC escape sequences (via apply_anyterm on /dev/pts/*) for secondary terminals without rewriting their config files.
**Notes:** Secondary terminals (Foot/Alacritty) receive palette updates through `/dev/pts/*` without needing config rewrites.

| Option | Description | Selected |
|--------|-------------|----------|
| Upstream fail-soft behavior | Retain upstream fail-soft behavior: kill -SIGUSR1 with pgrep guard so wallpaper changes are non-blocking whether Kitty is open or closed, and fresh instances load the theme on launch | ✓ |
| Remote control socket | Enable Kitty remote control socket (allow_remote_control yes) and use kitty @ set-colors for runtime palette updates | |
| You decide | Standard SIGUSR1 signal reload with fail-soft guards | |

**User's choice:** Retain upstream fail-soft behavior: kill -SIGUSR1 with pgrep guard so wallpaper changes are non-blocking whether Kitty is open or closed, and fresh instances load the theme on launch.

| Option | Description | Selected |
|--------|-------------|----------|
| Ensure seed file generation | Seed kitty-theme.conf during setup or run switchwall.sh --noswitch if absent, so Kitty always has a valid include file on first launch | ✓ |
| Graceful fallback | Allow Kitty to start with default colors until the user first changes wallpaper or runs switchwall.sh | |
| You decide | Ensure file exists via setup/assert harness seed | |

**User's choice:** Ensure seed file generation: Seed kitty-theme.conf during setup or run switchwall.sh --noswitch if absent, so Kitty always has a valid include file on first launch.

| Option | Description | Selected |
|--------|-------------|----------|
| Single-instance mode (kitty -1) | Faster launch times, shared daemon, matches upstream dots-hyprland defaults | ✓ |
| Standalone instances | Each terminal window runs in complete process isolation | |
| You decide | Follow upstream dots-hyprland invocation standard (kitty -1) | |

**User's choice:** Keep single-instance mode (kitty -1) — faster launch times, shared daemon, matches upstream dots-hyprland defaults.

| Option | Description | Selected |
|--------|-------------|----------|
| Upstream margin (window_margin_width 21.75) | Gives comfortable breathing room consistent with upstream dots-hyprland design | ✓ |
| Compact padding (10px) | Balanced margin preserving more horizontal screen space for coding/cli | |
| Zero padding (window_margin_width 0) | Maximal text density edge-to-edge | |
| You decide | Adopt upstream 21.75 margin | |

**User's choice:** Upstream margin (window_margin_width 21.75) — gives comfortable breathing room consistent with upstream dots-hyprland design.

| Option | Description | Selected |
|--------|-------------|----------|
| Keep user's font JetBrainsMono Nerd Font Mono | Strict mono glyph widths with clean scaling at 11.0 | |
| Switch to upstream JetBrains Mono Nerd Font | Wider double-width icons at 11.0 | ✓ |
| You decide | Use JetBrainsMono Nerd Font Mono at 11.0 | |

**User's choice:** Switch to upstream font family JetBrains Mono Nerd Font at font size 11.0 (wider double-width icons).

| Option | Description | Selected |
|--------|-------------|----------|
| Adopt all upstream shortcuts | Smart copy_or_interrupt on Ctrl+C, interactive search kitten on Ctrl+F, zoom/scroll page bindings | ✓ |
| Minimal keybindings | Omit copy_or_interrupt and search kitten, relying only on native terminal defaults | |
| You decide | Adopt upstream shortcuts with search kitten and copy_or_interrupt | |

**User's choice:** Adopt all upstream shortcuts (smart copy_or_interrupt on Ctrl+C, interactive search kitten on Ctrl+F, zoom/scroll page bindings).

---

## Terminal Opacity & Color Mode

| Option | Description | Selected |
|--------|-------------|----------|
| 100% opaque background | Maximum text contrast and legibility, matches upstream default baseline | |
| Subtle transparency | Allows desktop blur to show through terminal background | ✓ |
| You decide | Follow upstream default (100% opaque) | |

**User's choice:** Subtle transparency like under 50% (clarified to 85% opacity / background_opacity 0.85).

| Option | Description | Selected |
|--------|-------------|----------|
| 85% opacity | background_opacity 0.85 / term_alpha=85 — subtle transparency with strong contrast and readability | ✓ |
| 70% opacity | background_opacity 0.70 / term_alpha=70 — medium transparency with noticeable background blur | |
| 50% opacity | background_opacity 0.50 / term_alpha=50 — pronounced transparency evenly balanced with text background | |

**User's choice:** 85% opacity (background_opacity 0.85 / term_alpha=85) — subtle transparency with strong contrast and readability.

| Option | Description | Selected |
|--------|-------------|----------|
| Force dark mode (forceDarkMode: true) | Terminals always maintain a dark background for eye comfort even if desktop theme is light | ✓ |
| Dynamic sync (forceDarkMode: false) | Terminal palette switches between dark and light backgrounds following global theme mode | |
| You decide | Follow baseline config (forceDarkMode: true) | |

**User's choice:** Force dark mode (forceDarkMode: true) — terminals always maintain a dark background for eye comfort even if desktop theme is light.

| Option | Description | Selected |
|--------|-------------|----------|
| Retain upstream tuned parameters | harmony: 0.6, termFgBoost: 0.35, Starship prompt color overrides for high contrast and clean prompt rendering | ✓ |
| Raw unboosted colors (termFgBoost: 0.0) | Direct unadjusted Material You tonal palette without extra foreground boosting | |
| You decide | Use upstream tuned parameters | |

**User's choice:** Retain upstream tuned parameters (harmony: 0.6, termFgBoost: 0.35, Starship prompt color overrides) for high contrast and clean prompt rendering.

---

## Fuzzel Launcher Theming & Integration

| Option | Description | Selected |
|--------|-------------|----------|
| Upstream solid background (ff alpha) | Maximum legibility and crisp search contrast with dd alpha border | ✓ |
| Translucent background (d9 / 85% alpha) | Harmonizes with the 85% terminal opacity so launcher matches terminal transparency | |
| You decide | Follow upstream default solid background (ff) | |

**User's choice:** Upstream default solid background (ff alpha) — maximum legibility and crisp search contrast with dd alpha border.

| Option | Description | Selected |
|--------|-------------|----------|
| Upstream defaults | radius=17, width=1, Google Sans Flex:weight=medium font, prompt=">>  " — aligns with Hyprland 18px rounding | ✓ |
| Custom compact geometry | radius=8, width=2 — sharper corners with thicker outline | |
| You decide | Keep upstream default geometry | |

**User's choice:** Upstream defaults (radius=17, width=1, Google Sans Flex:weight=medium font, prompt=">>  ") — aligns with Hyprland 18px rounding.

| Option | Description | Selected |
|--------|-------------|----------|
| Bind to kitty -1 | Consistent with the Area 1 single-instance choice and upstream dots-hyprland fuzzel.ini | ✓ |
| Use fallback launcher script | terminal=~/.config/hypr/hyprland/scripts/launch_first_available.sh 'kitty -1' 'alacritty' | |
| You decide | Use kitty -1 | |

**User's choice:** Bind to kitty -1 — consistent with the Area 1 single-instance choice and upstream dots-hyprland fuzzel.ini.

| Option | Description | Selected |
|--------|-------------|----------|
| Track fuzzel.ini in stow/fuzzel | stow/fuzzel/.config/fuzzel/fuzzel.ini with symlink to ~/.config/fuzzel/fuzzel.ini, while fuzzel_theme.ini remains dynamically generated and guarded | ✓ |
| Keep unmanaged | Keep ~/.config/fuzzel/fuzzel.ini managed directly by dots-hyprland setup and defer repository collision reconciliation to Phase 29 | |
| You decide | Track in stow/fuzzel for reproducible dotfiles management | |

**User's choice:** Track fuzzel.ini in stow/fuzzel/.config/fuzzel/fuzzel.ini with symlink to ~/.config/fuzzel/fuzzel.ini, while fuzzel_theme.ini remains dynamically generated and guarded.

---

## Test Suite & Verification Criteria

| Option | Description | Selected |
|--------|-------------|----------|
| 5-section fail-closed assertion harness | Matching Phase 25–27 patterns (config readiness, Fuzzel theme syntax, Kitty/PTY theme syntax, live switchwall drill, and strict zero-drift verification) | ✓ |
| Minimal smoke test | Check file existence and basic grep assertions without live switchwall drill | |
| You decide | Standard 5-section automated test harness in scripts/phase28-terminal-fuzzel-assert.sh | |

**User's choice:** 5-section fail-closed assertion harness matching Phase 25–27 patterns (config readiness, Fuzzel theme syntax, Kitty/PTY theme syntax, live switchwall drill, and strict zero-drift verification).

| Option | Description | Selected |
|--------|-------------|----------|
| Dual-mode probe | Test live SIGUSR1 signal if Kitty is active, or assert clean fail-soft handling and config syntax validation if headless/closed | ✓ |
| Strict process requirement | Fail the test if Kitty is not actively running during the harness execution | |
| You decide | Dual-mode probe with graceful headless fallback | |

**User's choice:** Dual-mode probe: test live SIGUSR1 signal if Kitty is active, or assert clean fail-soft handling and config syntax validation if headless/closed.

| Option | Description | Selected |
|--------|-------------|----------|
| Rigorous schema and mtime validation | Assert valid INI syntax, required RRGGBBAA tokens (background, match, selection, border), include link in fuzzel.ini, and live mtime update during switchwall reload | ✓ |
| Basic validation | Verify fuzzel_theme.ini exists and has non-zero byte size | |
| You decide | Comprehensive schema and mtime advancement assertions | |

**User's choice:** Rigorous schema and mtime validation: assert valid INI syntax, required RRGGBBAA tokens (background, match, selection, border), include link in fuzzel.ini, and live mtime update during switchwall reload.

| Option | Description | Selected |
|--------|-------------|----------|
| Strict zero churn | Assert git status --porcelain is 100% empty and arch/dots-hyprland.sh verify --strict exits 0 with FAIL=0 FINDINGS=0 | ✓ |
| Permissive check | Run verify --strict but treat non-zero git status as a warning rather than a fatal assertion | |
| You decide | Strict zero git drift and zero verify findings | |

**User's choice:** Strict zero churn: assert git status --porcelain is 100% empty and arch/dots-hyprland.sh verify --strict exits 0 with FAIL=0 FINDINGS=0.

---

## the agent's Discretion

- Minor formatting and section headers in `stow/kitty/.config/kitty/kitty.conf` and `stow/fuzzel/.config/fuzzel/fuzzel.ini`.
- Test assertion organization and helper functions in `scripts/phase28-terminal-fuzzel-assert.sh`.

## Deferred Ideas

- Phase 29: Theme data contracts reconciliation (`guard-paths.tsv`, `collision-map.tsv`) and `./bootstrap.sh` full integration run.
- v2 Milestone: Waybar custom widget ports (ping, weather, earthquake).
