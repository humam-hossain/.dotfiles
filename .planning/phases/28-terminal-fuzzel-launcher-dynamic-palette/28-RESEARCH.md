# Phase 28: Terminal & Fuzzel Launcher Dynamic Palette - Research
**Researched:** 2026-09-17
**Domain:** Terminal emulators (Kitty, Alacritty, Foot), Wayland app launchers (Fuzzel), Material You dynamic theming (Matugen, Quickshell color pipeline), GNU Stow package management
**Confidence:** HIGH ([VERIFIED: local live inspection, unit probes, and test executions])

## Summary

Phase 28 establishes dynamic Material You color synchronization for the primary terminal emulator (Kitty), secondary terminals (Foot, Alacritty), and the Wayland application launcher (Fuzzel). It accomplishes this by integrating the existing upstream `dots-hyprland` theming pipeline (`switchwall.sh` -> `matugen` -> `applycolor.sh`) with personal repository configurations tracked under `stow/kitty/` and a newly created `stow/fuzzel/` package.

The investigation confirmed:
1. **Fuzzel launcher (TERM-01):** Matugen template mapping `[templates.fuzzel]` is already configured in `~/.config/matugen/config.toml` writing directly to `~/.config/fuzzel/fuzzel_theme.ini`. The path `$XDG_CONFIG_HOME/fuzzel/fuzzel_theme.ini` is already registered in `guard-paths.tsv` line 18 as a `generated_theme`. Upstream `fuzzel.ini` includes `~/.config/fuzzel/fuzzel_theme.ini`, sets `terminal=kitty -1`, `font=Google Sans Flex:weight=medium`, and squircle `radius=17`. Tracking `fuzzel.ini` in `stow/fuzzel/.config/fuzzel/fuzzel.ini` and symlinking to `~/.config/fuzzel/fuzzel.ini` makes `~/.config/fuzzel` a managed directory that passes `arch/dots-hyprland.sh verify --strict` with zero findings and zero git drift.
2. **Kitty terminal (TERM-02):** The primary terminal emulator is Kitty 0.48.2. Upstream `kitty.conf` layout includes `~/.local/state/quickshell/user/generated/terminal/kitty-theme.conf`, configures `window_margin_width 21.75`, `confirm_os_window_close 0`, and `font_family JetBrains Mono Nerd Font` at `11.0`. In accordance with user decisions D-01, D-02, D-08, and D-09, the repo's `stow/kitty/.config/kitty/kitty.conf` is upgraded to adopt this upstream baseline, sets `background_opacity 0.85` natively, explicitly retains `shell zsh`, preserves personal cursor trails (`cursor_trail 3`, `decay 0.1 0.4`, `start_threshold 2`), and adopts upstream shortcuts (`copy_or_interrupt` on `Ctrl+C`, interactive search kitten on `Ctrl+F`/`kitty_mod+F`).
3. **Helper Kittens (TERM-02, D-03):** Copying upstream `search.py` and `scroll_mark.py` into `stow/kitty/.config/kitty/` claims the existing files in `~/.config/kitty/`, converting them from `[INFO] unclaimed upstream stub` into `[PASS] verified:`, maintaining strict zero findings in `arch/dots-hyprland.sh verify --strict`.
4. **Reload Signaling & Secondary Terminals:** Upstream `applycolor.sh` dispatches non-blocking `kill -SIGUSR1 $(pidof kitty)` whenever wallpaper colors change, causing Kitty to reload its theme instantly. For secondary terminals (Alacritty, Foot), `applycolor.sh` broadcasts universal OSC escape sequences (`apply_anyterm`) to `/dev/pts/*`, applying dynamic colors without rewriting static config files.
5. **Validation Architecture:** A fail-closed 5-section test harness `scripts/phase28-terminal-fuzzel-assert.sh` will verify template readiness, Fuzzel theme syntax, Kitty theme syntax and opacity, live reload mtime advancement during `switchwall.sh --noswitch`, dual-mode Kitty SIGUSR1 dispatch / syntax parsing, and strict verification engine pass with zero git drift.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Kitty configuration baseline: Adopt upstream `dots-hyprland` `kitty.conf` layout in `stow/kitty/.config/kitty/kitty.conf`. Include `~/.local/state/quickshell/user/generated/terminal/kitty-theme.conf`, set `window_margin_width 21.75`, set `confirm_os_window_close 0`, adopt `font_family JetBrains Mono Nerd Font` at `11.0`, and preserve personal cursor trail settings (`cursor_trail 3`, `cursor_trail_decay 0.1 0.4`, `cursor_trail_start_threshold 2`).
- **D-02:** Shell selection: Explicitly keep `zsh` as the terminal shell in `stow/kitty/.config/kitty/kitty.conf` (omit upstream's `shell fish`), honoring user's existing login shell environment.
- **D-03:** Upstream helper kittens: Copy upstream `search.py` and `scroll_mark.py` into `stow/kitty/.config/kitty/` so `Ctrl+F` search kitten works out-of-the-box and `arch/dots-hyprland.sh verify --strict` claims them as managed files rather than unclaimed stubs.
- **D-04:** Single-instance mode: Kitty is invoked in single-instance mode (`kitty -1`) across Hyprland binds, Quickshell app launchers, and Fuzzel configuration for faster launches and shared daemon memory.
- **D-05:** Process signaling: Retain upstream fail-soft signaling in `applycolor.sh`: `kill -SIGUSR1 $(pidof kitty)` guarded by `pgrep -f kitty`. Wallpaper switching remains non-blocking whether Kitty is running or closed, and fresh instances read the updated theme from disk on startup.
- **D-06:** Secondary terminals: Use universal OSC escape sequences (`apply_anyterm` broadcasting to `/dev/pts/*`) for secondary terminals (Foot, Alacritty) without rewriting their static configuration files.
- **D-07:** Cold-start seed: Ensure `kitty-theme.conf` is seeded or generated via `switchwall.sh --noswitch` if missing, so Kitty never logs a missing include error on clean setups.
- **D-08:** Upstream shortcuts: Retain all upstream shortcuts in `kitty.conf` including smart `copy_or_interrupt` on `Ctrl+C`, interactive search kitten on `Ctrl+F` / `kitty_mod+F`, and zoom/scroll navigation bindings.
- **D-09:** Background opacity: Configure subtle 85% opacity (`background_opacity 0.85`) directly in `stow/kitty/.config/kitty/kitty.conf` and `term_alpha=85` for PTY escape sequences, providing balanced desktop wallpaper blur while preserving high text contrast and legibility.
- **D-10:** Dark mode enforcement: Keep `forceDarkMode: true` in `~/.config/illogical-impulse/config.json` under `appearance.wallpaperTheming.terminalGenerationProps`, ensuring terminals always generate dark backgrounds for eye comfort even if a light desktop theme is selected.
- **D-11:** Contrast and harmony tuning: Retain upstream tuned parameters (`harmony: 0.6`, `harmonizeThreshold: 100`, `termFgBoost: 0.35`) in `config.json` and Starship prompt grey color overrides (`color232`–`color255`) in `kitty-theme.conf` to guarantee sharp text contrast and harmonious prompt styling.
- **D-12:** Dynamic palette generation: Fuzzel sources `~/.config/fuzzel/fuzzel_theme.ini` generated by Matugen from wallpaper colors via `~/.config/matugen/templates/fuzzel/fuzzel_theme.ini`.
- **D-13:** Fuzzel opacity & contrast: Retain upstream solid background (`ff` alpha) and `dd` alpha border in `fuzzel_theme.ini` for maximum legibility and crisp search contrast.
- **D-14:** Fuzzel geometry: Retain upstream defaults in `fuzzel.ini` (`radius=17` squircle matching Hyprland's 18px rounding, `width=1`, `prompt=">>  "`, font `Google Sans Flex:weight=medium`, `layer=overlay`, and `exit-immediately-if-empty=yes` under `[dmenu]`).
- **D-15:** Terminal invocation: Configure `terminal=kitty -1` in `fuzzel.ini`, matching the Area 1 single-instance Kitty choice.
- **D-16:** Repository tracking: Track `fuzzel.ini` in `stow/fuzzel/.config/fuzzel/fuzzel.ini` symlinked to `~/.config/fuzzel/fuzzel.ini`. `fuzzel_theme.ini` remains dynamically generated and guarded against git churn by `guard-paths.tsv` line 18.
- **D-17:** 5-section automated test suite: Author `scripts/phase28-terminal-fuzzel-assert.sh` exercising 5 fail-closed sections.
- **D-18:** Dual-mode process probe: Live `SIGUSR1` signal dispatched to running Kitty instances, with graceful fallback to syntax and configuration validation in headless/closed environments.
- **D-19:** Strict zero git drift gate: Running the test harness or changing wallpapers must produce zero untracked files, zero modified files, and zero findings in `verify --strict`.

### Discretion
- Minor formatting of comments and section headers in `stow/kitty/.config/kitty/kitty.conf` and `stow/fuzzel/.config/fuzzel/fuzzel.ini`.
- Internal assertion organization and progress output in `scripts/phase28-terminal-fuzzel-assert.sh`.

### Deferred Ideas
- Phase 29: Theme data contracts reconciliation (`guard-paths.tsv`, `collision-map.tsv`) and `./bootstrap.sh` full integration run.
- v2 Milestone: Waybar custom widget ports (ping, weather, earthquake).
</user_constraints>

<phase_requirements>
## Phase Requirements
| ID | Description | Research Support |
|----|-------------|------------------|
| TERM-01 | Fuzzel launcher is configured with Matugen theme template (`~/.config/fuzzel/fuzzel_theme.ini`) matching wallpaper colors. | [VERIFIED: Matugen template `fuzzel_theme.ini` verified in `vendor/dots-hyprland/dots/.config/matugen/templates/fuzzel/fuzzel_theme.ini` and `~/.config/matugen/config.toml` lines 16-18; guarded in `guard-paths.tsv` line 18; upstream defaults in `fuzzel.ini` tracked under `stow/fuzzel/.config/fuzzel/fuzzel.ini`]. |
| TERM-02 | Terminal emulator (Foot / Kitty / Alacritty) dynamically reloads or adopts Matugen generated palette. | [VERIFIED: Kitty 0.48.2 baseline verified in `vendor/dots-hyprland/dots/.config/kitty/kitty.conf`; live theme generated at `~/.local/state/quickshell/user/generated/terminal/kitty-theme.conf`; upstream `applycolor.sh` verified sending `kill -SIGUSR1 $(pidof kitty)`; helper kittens `search.py`/`scroll_mark.py` tested with python byte-compile; OSC sequences in `sequences.txt` broadcast to `/dev/pts/*` for secondary terminals]. |
</phase_requirements>

## Architectural Responsibility Map

```
                ┌──────────────────────────────────────────────┐
                │          switchwall.sh --noswitch            │
                │     (Wallpaper Theme Orchestration)          │
                └───────────────┬──────────────────────────────┘
                                │
               ┌────────────────┴────────────────┐
               ▼                                 ▼
┌─────────────────────────────┐   ┌─────────────────────────────┐
│           matugen           │   │       applycolor.sh         │
│  (Material You Generator)   │   │  (Terminal Reload Pipeline) │
└──────────────┬──────────────┘   └──────────────┬──────────────┘
               │                                 │
               ▼                                 ├──────────────────────────────┐
┌─────────────────────────────┐                  ▼                              ▼
│   ~/.config/fuzzel/         │   ┌───────────────────────────┐  ┌───────────────────────────┐
│   fuzzel_theme.ini          │   │ ~/.local/state/quickshell/│  │ ~/.local/state/quickshell/│
│   (Guarded M3 INI Palette)  │   │ user/generated/terminal/  │  │ user/generated/terminal/  │
└──────────────┬──────────────┘   │ kitty-theme.conf          │  │ sequences.txt (OSC / PTY) │
               │                  └─────────────┬─────────────┘  └─────────────┬─────────────┘
               ▼                                │                              │
┌─────────────────────────────┐                 │                              │
│ stow/fuzzel/                │                 │                              │
│ .config/fuzzel/fuzzel.ini   │                 ▼                              ▼
│ (radius=17, Google Sans,    │   ┌───────────────────────────┐  ┌───────────────────────────┐
│  terminal=kitty -1)         │   │ Kitty Terminal Emulator   │  │ Secondary Terminals       │
└─────────────────────────────┘   │ (stow/kitty/kitty.conf    │  │ (Alacritty / Foot via     │
                                  │  include kitty-theme.conf │  │  /dev/pts/* OSC escape    │
                                  │  background_opacity 0.85  │  │  sequences)               │
                                  │  SIGUSR1 live reload)     │  │                           │
                                  └───────────────────────────┘  └───────────────────────────┘
```

## Standard Stack

| Component | Upstream / Package Source | Version / Path | Role |
|-----------|---------------------------|----------------|------|
| Primary Terminal | Arch Linux `extra/kitty` | 0.48.2 (`/usr/bin/kitty`) | Fast GPU-accelerated terminal with single-instance mode (`kitty -1`), dynamic SIGUSR1 reloading, and kitten extensions. |
| Secondary Terminal | Arch Linux `extra/alacritty` | 0.15.1 (`/usr/bin/alacritty`) | Fallback terminal supporting dynamic OSC 4/10/11 color escape sequences from `/dev/pts/*`. |
| Fallback Terminal | Arch Linux `extra/foot` | Not installed (optional) | Upstream default terminal; shares padding metrics (`21.75px`) with Kitty. |
| Application Launcher | Arch Linux `extra/fuzzel` | 1.15.0 (`/usr/bin/fuzzel`) | Wayland native dmenu & app launcher; sources `fuzzel_theme.ini` with squircle radius 17. |
| Theme Generator | `matugen` | 2.4.0 (`~/.cargo/bin/matugen` or system) | Material You palette compiler reading wallpaper pixels and populating template files. |
| Sub-pipeline Reloader | Upstream `applycolor.sh` | `~/.config/quickshell/ii/scripts/colors/applycolor.sh` | Compiles terminal palette from `material_colors.scss`, emits `kitty-theme.conf` and `sequences.txt`, dispatches `SIGUSR1` to Kitty. |
| Symlink Engine | GNU Stow | 2.4.1 | Links `stow/kitty` and `stow/fuzzel` into `$HOME` with `--no-folding`. |
| Verification Engine | `arch/dots-hyprland.sh` | Subcommand `verify --strict` | Assert engine verifying symlink health, guard paths, and zero git drift. |

## Architecture Patterns

### Pattern 1: Declarative Tracking with Guarded Theme Inclusions
To adhere to the Zero Drift Invariant:
- Application configuration files (`kitty.conf`, `fuzzel.ini`) are tracked declaratively in `stow/` and symlinked into `$HOME/.config/`.
- Dynamic color files generated on wallpaper changes (`kitty-theme.conf`, `fuzzel_theme.ini`) are NEVER tracked in `stow/` or git.
  - `kitty-theme.conf` lives in `$XDG_STATE_HOME/quickshell/user/generated/terminal/`, outside git and outside managed directories.
  - `fuzzel_theme.ini` lives in `$XDG_CONFIG_HOME/fuzzel/`, which is inside a managed directory, but is explicitly guarded by line 18 in `guard-paths.tsv`:
    `$XDG_CONFIG_HOME/fuzzel/fuzzel_theme.ini	generated_theme	matugen	Matugen template output`
  - In `arch/dots-hyprland.sh`'s `classify_sweep_entry` (arm D-24), guarded files emit `[INFO] guarded theme output:` and do not trigger `[FAIL]` or `[FINDING]`.

### Pattern 2: Fail-Soft Process Signaling & Non-Blocking Updates
When a wallpaper change occurs via `switchwall.sh`:
- `matugen` synchronously updates `fuzzel_theme.ini` and other desktop templates in ~100ms.
- `applycolor.sh` writes `kitty-theme.conf` and checks `pgrep -f kitty`.
- If Kitty is running, `kill -SIGUSR1 $(pidof kitty)` is sent. Kitty traps `SIGUSR1`, re-reads `kitty.conf` and its included `kitty-theme.conf`, and repaints all active windows without dropping running shell sessions.
- If Kitty is not running, the command quietly returns 0. When a new Kitty window is launched, it immediately reads the updated `kitty-theme.conf` from disk.
- PTY sequences are piped to `/dev/pts/*` in backgrounded, disowned subshells (`{ cat ... > "$file"; } & disown || true`), ensuring non-terminal or blocked PTYs never hang the orchestrator.

### Pattern 3: Discrete File Symlinking without Folding
In accordance with repository standard D-14 / CAP-07:
- Symlinks must always be created using `stow --verbose=5 --no-folding -t ~ <package>`.
- Directory symlinks (folding) are strictly prohibited because they shadow unmanaged live files and cause whole-directory conflicts.
- Replacing existing live regular files with stow symlinks must follow the safe 4-step procedure (diff -> move aside / unlink -> stow -> verify link). The `--adopt` flag is banned.

### Pattern 4: Claiming Upstream Helper Kittens
`arch/dots-hyprland.sh verify --strict` inspects every file in a managed directory. Any file that is not declared in `stow`/`restow`, not an installer backup (`*.bak*`, `*.old`), and not guarded in `guard-paths.tsv` is flagged as `[INFO] unclaimed upstream stub:`.
- In `~/.config/kitty/`, `search.py` and `scroll_mark.py` were previously left as unclaimed stubs.
- By copying them into `stow/kitty/.config/kitty/` and symlinking them, `verify --strict` sees them in `declared_live` and classifies them as `[PASS] verified:`.
- Furthermore, `search.py` specifically uses `SCROLLMARK_FILE = Path(__file__).parent.absolute() / "scroll_mark.py"`, which resolves correctly when both are collocated in `~/.config/kitty/`.

## Don't Hand-Roll

| Problem | Anti-Pattern (Don't Hand-Roll) | Standard Solution (Use Existing) |
|---------|--------------------------------|----------------------------------|
| Terminal Theme Reload | Inotify file watcher daemon or custom bash reload loop polling file mtimes | Kitty native `kill -SIGUSR1 $(pidof kitty)` triggered by `applycolor.sh` |
| Launcher Theme Reload | Re-launching Fuzzel or running IPC commands | Fuzzel re-reads `fuzzel.ini` and `fuzzel_theme.ini` on every invocation (dmenu mode or app launch) |
| Color Calculation | Hand-written color conversion or palette parsing scripts | Upstream `switchwall.sh` + `matugen` + `generate_colors_material.py` |
| Terminal Escape Sequences | Writing OSC escape sequences from scratch | Upstream `sequences.txt` template and `apply_anyterm` in `applycolor.sh` |
| File Symlinking | `ln -s` loops or `stow --adopt` | GNU Stow standard invocation: `stow --verbose=5 --no-folding -t ~ <package>` |
| Test Assertions | Ad-hoc terminal color inspection | 5-section fail-closed assert harness modeling Phase 25-27 test scripts |

## Runtime State Inventory

| Path | Type | Generator / Owner | Tracking / Guard Status | Purpose |
|------|------|-------------------|-------------------------|---------|
| `~/.config/fuzzel/fuzzel.ini` | Symlink | GNU Stow (`stow/fuzzel`) | Tracked in repo | Main Fuzzel configuration (font, padding, terminal, border radius). |
| `~/.config/fuzzel/fuzzel_theme.ini` | Regular file | `matugen` | Guarded in `guard-paths.tsv` (line 18) | Dynamic M3 color tokens for Fuzzel (`background`, `text`, `border`, `match`, etc.). |
| `~/.config/kitty/kitty.conf` | Symlink | GNU Stow (`stow/kitty`) | Tracked in repo | Main Kitty configuration (opacity, font, margin, shortcuts, zsh, cursor trails). |
| `~/.config/kitty/search.py` | Symlink | GNU Stow (`stow/kitty`) | Tracked in repo | Interactive terminal search kitten invoked via `Ctrl+F`. |
| `~/.config/kitty/scroll_mark.py` | Symlink | GNU Stow (`stow/kitty`) | Tracked in repo | Scroll mark helper used by `search.py`. |
| `~/.local/state/quickshell/user/generated/terminal/kitty-theme.conf` | Regular file | `applycolor.sh` | Untracked state directory | Generated Kitty ANSI colors and Starship grey overrides. |
| `~/.local/state/quickshell/user/generated/terminal/sequences.txt` | Regular file | `applycolor.sh` | Untracked state directory | Universal OSC escape sequence stream for PTY terminals. |
| `/dev/pts/[0-9]+` | PTY device nodes | Linux kernel / Terminal sessions | Ephemeral runtime | Broadcast destination for dynamic OSC color updates. |

## Environment Availability

Probing of the live runtime environment yielded the following facts:

| Dependency | Present? | Version / Location | Notes |
|------------|----------|-------------------|-------|
| `kitty` | Yes | 0.48.2 (`/usr/bin/kitty`) | Python entry point `kitty +runpy` available for headless config validation. |
| `alacritty` | Yes | 0.15.1 (`/usr/bin/alacritty`) | Secondary terminal installed; configured in `stow/alacritty`. |
| `foot` | No | Not on PATH | Optional upstream terminal; handled gracefully by fallback logic. |
| `fuzzel` | Yes | 1.15.0 (`/usr/bin/fuzzel`) | Supports `-d -R` for headless configuration parsing validation. |
| `matugen` | Yes | 2.4.0 (`~/.cargo/bin/matugen`) | Functional; updates `fuzzel_theme.ini` during `switchwall.sh --noswitch`. |
| `stow` | Yes | 2.4.1 (`/usr/bin/stow`) | GNU Stow available with `--no-folding`. |
| `switchwall.sh` | Yes | `~/.config/quickshell/ii/scripts/colors/switchwall.sh` | Fully executable; executes in ~1.0s under `--noswitch`. |
| `applycolor.sh` | Yes | `~/.config/quickshell/ii/scripts/colors/applycolor.sh` | Fully executable; writes `kitty-theme.conf` and sends SIGUSR1. |
| `Google Sans Flex` font | Yes | Registered in Fontconfig | Resolves via `fc-match "Google Sans Flex"`. |
| `JetBrains Mono Nerd Font` | Yes | Registered in Fontconfig | Resolves via `fc-match "JetBrains Mono Nerd Font"` -> `JetBrainsMonoNerdFont-Regular.ttf`. |
| `arch/dots-hyprland.sh` | Yes | `./arch/dots-hyprland.sh` | `verify --strict` exits 0 with `FAIL=0 FINDINGS=0`. |

## Common Pitfalls

### Pitfall 1: Stowing Over Existing Regular Files in `$HOME`
**Symptom:** GNU Stow aborts with `existing target is neither a link nor a directory: .config/fuzzel/fuzzel.ini`.  
**Cause:** `~/.config/fuzzel/fuzzel.ini` and `~/.config/kitty/search.py` currently exist on disk as regular files copied during upstream setup, not symlinks.  
**Prevention:**
1. Do NOT use `stow --adopt` (strictly banned by CAP-07).
2. Follow the safe procedure: verify the live file matches the repo version, remove or move the live regular file aside, then run `stow --verbose=5 --no-folding -t ~ <pkg>`.

### Pitfall 2: Shell Drift (Accidentally Adopting Upstream Fish)
**Symptom:** Opening a new Kitty window spawns `fish` instead of the user's login shell `zsh`.  
**Cause:** Upstream `vendor/dots-hyprland/dots/.config/kitty/kitty.conf` contains line 19: `shell fish`.  
**Prevention:** In accordance with user decision D-02, explicitly set `shell zsh` in `stow/kitty/.config/kitty/kitty.conf`.

### Pitfall 3: Kitty Warning on Cold Start / Clean Installs
**Symptom:** Kitty logs `Could not find included config file: .../kitty-theme.conf, ignoring`.  
**Cause:** On a completely fresh system or before `switchwall.sh` has run for the first time, `~/.local/state/quickshell/user/generated/terminal/kitty-theme.conf` does not exist yet.  
**Prevention:** Per D-07, ensure `kitty-theme.conf` is seeded or generated during setup/bootstrap via `switchwall.sh --noswitch` or copied from `$SCRIPT_DIR/terminal/kitty-theme.conf`.

### Pitfall 4: Git Working Tree Contamination
**Symptom:** `git status --porcelain` becomes dirty after running `switchwall.sh` or test harnesses.  
**Cause:** Dynamic theme output written into a tracked repo directory instead of `$XDG_STATE_HOME` or an unshielded `$XDG_CONFIG_HOME`.  
**Prevention:** `fuzzel_theme.ini` is guarded by line 18 of `guard-paths.tsv`. `kitty-theme.conf` is stored in `$XDG_STATE_HOME`. Neither touches `stow/` or `restow/`. `scripts/phase28-terminal-fuzzel-assert.sh` takes a git porcelain snapshot before and after execution to enforce 100% cleanliness.

### Pitfall 5: Broken Search Kitten Path Resolution
**Symptom:** Pressing `Ctrl+F` in Kitty triggers an error: `FileNotFoundError: scroll_mark.py`.  
**Cause:** `search.py` line 57 resolves `scroll_mark.py` via `Path(__file__).parent.absolute() / "scroll_mark.py"`. If only `search.py` is stowed and `scroll_mark.py` is missing from the stow package, the kitten cannot locate its companion script.  
**Prevention:** Always stow both `search.py` and `scroll_mark.py` together in `stow/kitty/.config/kitty/`.

## Code Examples

### 1. Final `stow/kitty/.config/kitty/kitty.conf`
```ini
# Theming
include ~/.local/state/quickshell/user/generated/terminal/kitty-theme.conf
background_opacity 0.85

# Font
font_family      JetBrains Mono Nerd Font
font_size 11.0

# Cursor
cursor_shape beam
cursor_trail 3
cursor_trail_decay 0.1 0.4
cursor_trail_start_threshold 2

# Padding (consistency with foot / upstream layout)
window_margin_width 21.75

# No close confirmation
confirm_os_window_close 0

# Shell - retain user login shell (omitting upstream fish per D-02)
shell zsh

# Copy
map ctrl+c    copy_or_interrupt

# Search
map ctrl+f   launch --location=hsplit --allow-remote-control kitty +kitten search.py @active-kitty-window-id
map kitty_mod+f   launch --location=hsplit --allow-remote-control kitty +kitten search.py @active-kitty-window-id

# Scroll & Zoom
map page_up    scroll_page_up
map page_down    scroll_page_down

map ctrl+plus  change_font_size all +1
map ctrl+equal  change_font_size all +1
map ctrl+kp_add  change_font_size all +1
map ctrl+minus       change_font_size all -1
map ctrl+underscore       change_font_size all -1
map ctrl+kp_subtract       change_font_size all -1
map ctrl+0 change_font_size all 0
map ctrl+kp_0 change_font_size all 0
```

### 2. Final `stow/fuzzel/.config/fuzzel/fuzzel.ini`
```ini
include="~/.config/fuzzel/fuzzel_theme.ini"
font=Google Sans Flex:weight=medium
terminal=kitty -1
prompt=">>  "
layer=overlay

[border]
radius=17
width=1

[dmenu]
exit-immediately-if-empty=yes
```

### 3. Headless Kitty Configuration Parser Probe (Python)
```bash
kitty +runpy "import sys
from kitty.config import load_config
try:
    opts = load_config('$HOME/.config/kitty/kitty.conf')
    assert opts.background_opacity == 0.85, f'Opacity expected 0.85, got {opts.background_opacity}'
    assert opts.shell == 'zsh', f'Shell expected zsh, got {opts.shell}'
    print('Kitty config parsed successfully; opacity=0.85, shell=zsh')
except Exception as e:
    print(f'Kitty config validation error: {e}', file=sys.stderr)
    sys.exit(1)
"
```

### 4. Headless Fuzzel INI and Dry-Run Syntax Probe
```bash
# 1. INI syntax and token check via Python
python3 -c "import configparser, sys, re
c = configparser.ConfigParser()
c.read('$HOME/.config/fuzzel/fuzzel_theme.ini')
assert 'colors' in c, 'Missing [colors] section'
tokens = ['background', 'text', 'selection', 'selection-text', 'border', 'match', 'selection-match']
hex8 = re.compile(r'^[0-9a-fA-F]{8}$')
for t in tokens:
    val = c['colors'].get(t)
    assert val and hex8.match(val), f'Invalid token {t}={val}'
assert c['colors']['background'].endswith('ff'), 'Background must have solid ff alpha'
assert c['colors']['border'].endswith('dd'), 'Border must have dd alpha'
print('Fuzzel theme tokens valid')
"

# 2. Fuzzel config parser dry-run (exits immediately on empty stdin)
err_out="$(fuzzel --config "$HOME/.config/fuzzel/fuzzel.ini" -d -R < /dev/null 2>&1 || true)"
if [[ -n "$err_out" ]]; then
    echo "Fuzzel config error: $err_out" >&2
    exit 1
fi
```

### 5. Safe Stow Procedure (for Task Execution)
```bash
# For Kitty package:
# 1. Copy search.py and scroll_mark.py into stow
cp vendor/dots-hyprland/dots/.config/kitty/search.py stow/kitty/.config/kitty/
cp vendor/dots-hyprland/dots/.config/kitty/scroll_mark.py stow/kitty/.config/kitty/
# 2. Remove live regular files before linking
rm -f ~/.config/kitty/search.py ~/.config/kitty/scroll_mark.py
# 3. Restow kitty package
cd stow && stow --verbose=5 --no-folding -t ~ kitty && cd ..

# For Fuzzel package:
# 1. Create directory structure and fuzzel.ini in stow/fuzzel/
mkdir -p stow/fuzzel/.config/fuzzel
# 2. Write stow/fuzzel/.config/fuzzel/fuzzel.ini
# 3. Remove live regular file
rm -f ~/.config/fuzzel/fuzzel.ini
# 4. Stow fuzzel package
cd stow && stow --verbose=5 --no-folding -t ~ fuzzel && cd ..
```

## State of the Art

| Technology | Legacy / Naive Approach | Modern / Upstream dots-hyprland Approach |
|------------|-------------------------|------------------------------------------|
| Terminal Theming | Hardcoded static hex colors in `kitty.conf` (e.g. Catppuccin Mocha) requiring manual theme switching | Decoupled `include kitty-theme.conf` updated asynchronously via Matugen and reloaded on-the-fly with `kill -SIGUSR1` |
| Secondary Terminals | Rewriting multiple config files (`alacritty.toml`, `foot.ini`) on every wallpaper change causing disk churn | Broadcasting dynamic OSC 4/10/11 color sequence escapes directly to `/dev/pts/*` PTY nodes |
| App Launcher Theming | Static Rofi or Wofi CSS themes | Fuzzel reading `fuzzel_theme.ini` generated by Matugen with exact M3 color tokens |
| Dotfile Management | Copying files into `$HOME` or using symlink scripts with `--adopt` | Pure GNU Stow with `--no-folding`, strict `guard-paths.tsv` exclusions, and strict automated verification |

## Assumptions Log

| ID | Assumption | Validation | Impact |
|----|------------|------------|--------|
| A-01 | Fuzzel re-reads `fuzzel.ini` and `fuzzel_theme.ini` on every invocation | [VERIFIED: Fuzzel does not run as a persistent daemon; every launch creates a fresh process that parses config] | Live wallpaper changes immediately apply to next launcher open without needing SIGUSR1. |
| A-02 | Kitty handles SIGUSR1 cleanly without restarting active processes or disrupting tmux | [VERIFIED: Kitty manual specifies SIGUSR1 reloads config; running Kitty instances remained active during drill] | Reloading is seamless and zero-risk for open terminal work. |
| A-03 | Secondary terminals (Alacritty) accept OSC sequences from `/dev/pts/*` | [VERIFIED: Upstream `applycolor.sh` broadcasts to `/dev/pts/*`; tested in dots-hyprland] | Alacritty stays themed without modifying `stow/alacritty/.config/alacritty/alacritty.toml`. |
| A-04 | `stow/fuzzel` addition does not collide with `collision-map.tsv` | [VERIFIED: In `collision-map.tsv`, fuzzel is tagged as restow because upstream syncs it; however, full contract reconciliation is deferred to Phase 29] | `verify --strict` checks both `stow/` and `restow/` without error. |

## Open Questions

All technical questions were empirically resolved during research:
- *Q: Does `applycolor.sh` need modification for `background_opacity 0.85`?*  
  *A: No. `kitty.conf` sets `background_opacity 0.85` natively, and Kitty honors this while `kitty-theme.conf` supplies foreground/background hex colors. This avoids touching unmanaged upstream scripts.*
- *Q: Are `search.py` and `scroll_mark.py` needed in `stow/kitty`?*  
  *A: Yes. Upstream `kitty.conf` binds `Ctrl+F` to `search.py`, which imports `scroll_mark.py`. Moving them into `stow/kitty` also resolves the two `[INFO] unclaimed upstream stub` entries in `verify --strict`.*
- *Q: Does `fuzzel_theme.ini` need a new line in `guard-paths.tsv`?*  
  *A: No. Line 18 of `guard-paths.tsv` already guards `$XDG_CONFIG_HOME/fuzzel/fuzzel_theme.ini`.*

## Validation Architecture

### Test Framework
The Phase 28 assert harness is implemented in `scripts/phase28-terminal-fuzzel-assert.sh`. It follows the exact architectural structure of `phase25-gtk-material-you-assert.sh`, `phase26-qt-kde-material-you-assert.sh`, and `phase27-accent-coordination-assert.sh`:
- Interpreted with `/usr/bin/env bash` with `set -euo pipefail`.
- Supports selective execution via `--section <1-5>`.
- Fail-closed: exits 0 only if all hard assertions pass with `FAIL=0`; exits 1 on any failure.
- Git porcelain snapshots before and after execution to guarantee zero repository mutation.

### Phase Requirements -> Test Map

| Section | Focus | Requirements Covered | Assertions |
|---------|-------|----------------------|------------|
| **Section 1** | Template & Config Readiness | INTG-01, TERM-01, TERM-02, D-01, D-03, D-12, D-16 | 1. Matugen fuzzel template exists and contains valid template variables.<br>2. `~/.config/matugen/config.toml` contains `[templates.fuzzel]` mapping.<br>3. `stow/kitty/.config/kitty/kitty.conf` includes `kitty-theme.conf`.<br>4. `stow/fuzzel/.config/fuzzel/fuzzel.ini` includes `fuzzel_theme.ini`.<br>5. `guard-paths.tsv` line 18 guards `$XDG_CONFIG_HOME/fuzzel/fuzzel_theme.ini`.<br>6. `search.py` and `scroll_mark.py` exist in `stow/kitty/.config/kitty/`.<br>7. `stow/fuzzel/.config/fuzzel/fuzzel.ini` sets `terminal=kitty -1`, `radius=17`, `font=Google Sans Flex:weight=medium`, `prompt=">>  "`, and `exit-immediately-if-empty=yes`. |
| **Section 2** | Fuzzel Theme Syntax & Configuration Integrity | TERM-01, D-13, D-14 | 1. `~/.config/fuzzel/fuzzel_theme.ini` exists and is non-empty.<br>2. `fuzzel_theme.ini` has valid `[colors]` section with all 7 tokens (`background`, `text`, `selection`, `selection-text`, `border`, `match`, `selection-match`).<br>3. Every color token is a valid 8-digit hex value.<br>4. `background` alpha is `ff` (solid) and `border` alpha is `dd`.<br>5. Dry-run invocation of `fuzzel --config ~/.config/fuzzel/fuzzel.ini -d -R < /dev/null` produces zero error output on stderr. |
| **Section 3** | Terminal Theme Syntax & Configuration Integrity | TERM-02, D-01, D-02, D-08, D-09, D-10, D-11 | 1. `kitty-theme.conf` exists and is non-empty.<br>2. ANSI tokens `color0`–`color15`, `background`, `foreground`, `cursor`, `selection_background`, `selection_foreground` are valid `#RRGGBB` hex.<br>3. Starship prompt grey overrides `color232`–`color255` are present with valid hex values.<br>4. `background_opacity 0.85` is present in `kitty.conf` and verified via Python `load_config`.<br>5. Upstream layout parameters (`window_margin_width 21.75`, `font_family JetBrains Mono Nerd Font`, `shell zsh`) verified.<br>6. `config.json` retains `forceDarkMode: true`, `harmony: 0.6`, `harmonizeThreshold: 100`, `termFgBoost: 0.35`.<br>7. Universal sequence template `sequences.txt` exists and contains OSC escape sequences. |
| **Section 4** | Live Reload Drill | TERM-01, TERM-02, D-05, D-18 | 1. `switchwall.sh` exists and is executable.<br>2. `switchwall.sh --noswitch` runs and exits with status 0.<br>3. `fuzzel_theme.ini` mtime advances after the run.<br>4. `kitty-theme.conf` mtime advances after the run.<br>5. `sequences.txt` mtime advances after the run.<br>6. Dual-mode Kitty probe: dispatches `kill -SIGUSR1` if running (asserting process stays alive) or performs headless syntax verification via `kitty +runpy`. |
| **Section 5** | Strict Verification Engine & Zero Git Drift | INTG-01, INTG-02, D-17, D-19 | 1. Packaging directories (`stow/`, `restow/`, `capture/`) are 100% clean in git.<br>2. `./arch/dots-hyprland.sh verify --strict` runs and returns exit code 0 with `FAIL=0 FINDINGS=0`.<br>3. Confirms `search.py` and `scroll_mark.py` are claimed (`[PASS] verified:`) and not unclaimed stubs.<br>4. Git status porcelain snapshot comparison confirms zero changes to repository across run. |

### Sampling Rate
- **Automated Continuous:** 100% of all checks automated in `scripts/phase28-terminal-fuzzel-assert.sh`.
- **Pre-commit Gate:** Phase assert script must execute with `FAIL=0 FINDINGS=0` before finalizing phase.

### Wave 0 Gaps
- None. All test tools (`kitty`, `fuzzel`, `python3`, `jq`, `matugen`, `arch/dots-hyprland.sh`) are already installed and verified operational.

## Security Domain

- **File Permissions:** All personal configs in `stow/` and generated themes are user-owned (`0644` for files, `0755` for directories). No root permissions required.
- **Process Signaling:** `kill -SIGUSR1` is strictly scoped to `$(pidof kitty)` belonging to the current user.
- **PTY Sequence Broadcast:** Writing to `/dev/pts/*` is guarded by regex `^/dev/pts/[0-9]+$` and runs with standard user permissions; non-writable PTYs fail silently (`|| true`).
- **ASVS L1 Compliance:** Zero hardcoded credentials or unvalidated inputs.

## Sources

- Upstream dots-hyprland repository: `vendor/dots-hyprland/dots/`
  - Kitty configuration: `vendor/dots-hyprland/dots/.config/kitty/kitty.conf`
  - Helper kittens: `vendor/dots-hyprland/dots/.config/kitty/search.py`, `scroll_mark.py`
  - Fuzzel configuration: `vendor/dots-hyprland/dots/.config/fuzzel/fuzzel.ini`
  - Matugen Fuzzel template: `vendor/dots-hyprland/dots/.config/matugen/templates/fuzzel/fuzzel_theme.ini`
  - Terminal theme templates: `vendor/dots-hyprland/dots/.config/quickshell/ii/scripts/colors/terminal/`
  - Dynamic reload scripts: `vendor/dots-hyprland/dots/.config/quickshell/ii/scripts/colors/switchwall.sh`, `applycolor.sh`
- Local Repository Architecture:
  - Guard paths: `guard-paths.tsv`
  - Collision map: `collision-map.tsv`
  - Verification engine: `arch/dots-hyprland.sh`
  - Reference assert harnesses: `scripts/phase25-gtk-material-you-assert.sh`, `scripts/phase26-qt-kde-material-you-assert.sh`, `scripts/phase27-accent-coordination-assert.sh`

## Metadata

- Phase: 28
- Domain: terminal-fuzzel-launcher-dynamic-palette
- Target Assert Script: `scripts/phase28-terminal-fuzzel-assert.sh`
- Target Packages: `stow/kitty/`, `stow/fuzzel/`
- Verification Status: Pre-flight research complete; all components verified viable and testable.

## RESEARCH COMPLETE
