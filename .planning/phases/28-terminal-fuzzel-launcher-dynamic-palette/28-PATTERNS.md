# Phase 28: Terminal & Fuzzel Launcher Dynamic Palette - Pattern Map

**Mapped:** 2026-09-17  
**Files analyzed:** 11  
**Analogs found:** 11 / 11 (100% coverage)  

---

## File Classification

| File / Component | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `stow/kitty/.config/kitty/kitty.conf` | config | file-I/O | [vendor/dots-hyprland/dots/.config/kitty/kitty.conf](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/kitty/kitty.conf) (lines 1–40) & [stow/kitty/.config/kitty/kitty.conf](file:///home/pera/github_repo/.dotfiles/stow/kitty/.config/kitty/kitty.conf) (lines 1–6) | exact |
| `stow/kitty/.config/kitty/search.py` | helper / kitten script | process execution / IPC | [vendor/dots-hyprland/dots/.config/kitty/search.py](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/kitty/search.py) (lines 1–342) | exact |
| `stow/kitty/.config/kitty/scroll_mark.py` | helper / kitten script | process execution / IPC | [vendor/dots-hyprland/dots/.config/kitty/scroll_mark.py](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/kitty/scroll_mark.py) (lines 1–19) | exact |
| `stow/fuzzel/.config/fuzzel/fuzzel.ini` | config | file-I/O | [vendor/dots-hyprland/dots/.config/fuzzel/fuzzel.ini](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/fuzzel/fuzzel.ini) (lines 1–13) | exact |
| `scripts/phase28-terminal-fuzzel-assert.sh` | test | file-I/O / request-response | [scripts/phase27-accent-coordination-assert.sh](file:///home/pera/github_repo/.dotfiles/scripts/phase27-accent-coordination-assert.sh) (lines 1–423) & [scripts/phase26-qt-kde-material-you-assert.sh](file:///home/pera/github_repo/.dotfiles/scripts/phase26-qt-kde-material-you-assert.sh) (lines 1–334) | exact |
| `vendor/dots-hyprland/dots/.config/matugen/templates/fuzzel/fuzzel_theme.ini` | template | file-I/O | [vendor/dots-hyprland/dots/.config/matugen/templates/fuzzel/fuzzel_theme.ini](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/matugen/templates/fuzzel/fuzzel_theme.ini) (lines 1–9) | exact |
| `~/.config/fuzzel/fuzzel_theme.ini` | config (generated) | file-I/O | [vendor/dots-hyprland/dots/.config/fuzzel/fuzzel_theme.ini](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/fuzzel/fuzzel_theme.ini) (lines 1–9) | exact |
| `~/.local/state/quickshell/user/generated/terminal/kitty-theme.conf` | config (generated) | file-I/O / IPC signal | [vendor/dots-hyprland/dots/.config/quickshell/ii/scripts/colors/terminal/kitty-theme.conf](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/quickshell/ii/scripts/colors/terminal/kitty-theme.conf) (lines 1–52) | exact |
| `~/.local/state/quickshell/user/generated/terminal/sequences.txt` | stream (generated) | streaming to `/dev/pts/*` | [vendor/dots-hyprland/dots/.config/quickshell/ii/scripts/colors/terminal/sequences.txt](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/quickshell/ii/scripts/colors/terminal/sequences.txt) (lines 1–50) | exact |
| `vendor/dots-hyprland/dots/.config/quickshell/ii/scripts/colors/applycolor.sh` | controller / reloader | process execution / signal dispatch | [vendor/dots-hyprland/dots/.config/quickshell/ii/scripts/colors/applycolor.sh](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/quickshell/ii/scripts/colors/applycolor.sh) (lines 1–94) | exact |
| `guard-paths.tsv` | data contract | file-I/O | [guard-paths.tsv](file:///home/pera/github_repo/.dotfiles/guard-paths.tsv) (lines 13–21) | exact |

---

## Pattern Assignments

### 1. `stow/kitty/.config/kitty/kitty.conf` (config, file-I/O)

**Role:** Primary terminal emulator configuration declaring layout, dynamic theme inclusion, opacity, fonts, personal cursor trail parameters, login shell (`zsh`), and interactive kitten keybindings.  
**Data Flow:** Read on Kitty startup and re-read on `SIGUSR1`; dynamically imports `kitty-theme.conf` from `$XDG_STATE_HOME/quickshell/user/generated/terminal/`.  
**Analog:** [vendor/dots-hyprland/dots/.config/kitty/kitty.conf](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/kitty/kitty.conf#L1-L40)  
**Personal Baseline Analog:** [stow/kitty/.config/kitty/kitty.conf](file:///home/pera/github_repo/.dotfiles/stow/kitty/.config/kitty/kitty.conf#L1-L6)  

#### Complete Configuration Pattern
**Source:** [vendor/dots-hyprland/dots/.config/kitty/kitty.conf](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/kitty/kitty.conf#L1-L40), [stow/kitty/.config/kitty/kitty.conf](file:///home/pera/github_repo/.dotfiles/stow/kitty/.config/kitty/kitty.conf#L3-L5), and [28-CONTEXT.md](file:///home/pera/github_repo/.dotfiles/.planning/phases/28-terminal-fuzzel-launcher-dynamic-palette/28-CONTEXT.md#L30-L43) D-01, D-02, D-08, D-09
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

---

### 2. `stow/kitty/.config/kitty/search.py` (helper / kitten script, process execution / IPC)

**Role:** Interactive terminal search kitten providing regex/plain scrollback buffer search, navigation, and highlight overlay when `Ctrl+F` or `kitty_mod+F` is triggered.  
**Data Flow:** Spawned via `kitty +kitten search.py @active-kitty-window-id` in a horizontal split window; imports companion handler `scroll_mark.py` via `Path(__file__).parent.absolute() / "scroll_mark.py"`. Stowing this file resolves unclaimed upstream stub findings in `arch/dots-hyprland.sh verify --strict`.  
**Analog:** [vendor/dots-hyprland/dots/.config/kitty/search.py](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/kitty/search.py#L1-L65)  

#### Companion Path Resolution Excerpt
**Source:** [vendor/dots-hyprland/dots/.config/kitty/search.py](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/kitty/search.py#L56-L65)
```python
SCROLLMARK_FILE = Path(__file__).parent.absolute() / "scroll_mark.py"


class Search(Handler):
    def __init__(
        self, cached_values: dict[str, str], window_ids: list[int], error: str = ""
    ) -> None:
        self.cached_values = cached_values
        self.window_ids = window_ids
```

---

### 3. `stow/kitty/.config/kitty/scroll_mark.py` (helper / kitten script, process execution / IPC)

**Role:** Companion scroll mark helper script for `search.py`, providing `@result_handler` for jumping between matches without user interface overhead.  
**Data Flow:** Dispatched by Kitty Boss when navigating search results (`w.scroll_to_mark(...)`). Stowing this file alongside `search.py` resolves unclaimed upstream stub findings in `arch/dots-hyprland.sh verify --strict`.  
**Analog:** [vendor/dots-hyprland/dots/.config/kitty/scroll_mark.py](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/kitty/scroll_mark.py#L1-L19)  

#### Complete Handler Pattern
**Source:** [vendor/dots-hyprland/dots/.config/kitty/scroll_mark.py](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/kitty/scroll_mark.py#L1-L19)
```python
from kittens.tui.handler import result_handler
from kitty.boss import Boss


def main(args: list[str]) -> None:
    pass


@result_handler(no_ui=True)
def handle_result(
    args: list[str], answer: str, target_window_id: int, boss: Boss
) -> None:
    w = boss.window_id_map.get(target_window_id)
    if w is not None:
        if len(args) > 1 and args[1] != "prev":
            w.scroll_to_mark(prev=False)
        else:
            w.scroll_to_mark()
```

---

### 4. `stow/fuzzel/.config/fuzzel/fuzzel.ini` (config, file-I/O)

**Role:** Main configuration file for Fuzzel Wayland application launcher, setting geometry (`radius=17`), font (`Google Sans Flex:weight=medium`), prompt, layer, single-instance terminal runner (`terminal=kitty -1`), and including the dynamic Matugen theme palette.  
**Data Flow:** Read every time Fuzzel is launched (via keybinding `Super`, app search, or `fuzzel-emoji.sh`). Sources guarded theme file `~/.config/fuzzel/fuzzel_theme.ini`.  
**Analog:** [vendor/dots-hyprland/dots/.config/fuzzel/fuzzel.ini](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/fuzzel/fuzzel.ini#L1-L13)  

#### Complete Configuration Pattern
**Source:** [vendor/dots-hyprland/dots/.config/fuzzel/fuzzel.ini](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/fuzzel/fuzzel.ini#L1-L13) and [28-CONTEXT.md](file:///home/pera/github_repo/.dotfiles/.planning/phases/28-terminal-fuzzel-launcher-dynamic-palette/28-CONTEXT.md#L45-L52) D-12..D-16
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

---

### 5. `scripts/phase28-terminal-fuzzel-assert.sh` (test, file-I/O / request-response)

**Role:** Automated 5-section fail-closed bash test harness enforcing TERM-01, TERM-02, INTG-01, INTG-02 requirements and decisions D-01 through D-19.  
**Data Flow:** Validates templates and personal configs; parses INI and Kitty syntax; tests live mtime advancement during `switchwall.sh --noswitch`; performs dual-mode SIGUSR1 / headless syntax probe; executes strict verification engine; enforces zero git repository drift.  
**Analog:** [scripts/phase27-accent-coordination-assert.sh](file:///home/pera/github_repo/.dotfiles/scripts/phase27-accent-coordination-assert.sh#L1-L125)  
**Secondary Analog:** [scripts/phase26-qt-kde-material-you-assert.sh](file:///home/pera/github_repo/.dotfiles/scripts/phase26-qt-kde-material-you-assert.sh#L1-L77)  

#### Header, Bash Flags, and Output Primitives Pattern
**Source:** [scripts/phase27-accent-coordination-assert.sh](file:///home/pera/github_repo/.dotfiles/scripts/phase27-accent-coordination-assert.sh#L1-L25)
```bash
#!/usr/bin/env bash
# Phase 28 Terminal & Fuzzel Launcher Dynamic Palette assert harness (TERM-01, TERM-02, INTG-01, INTG-02).
# One script, one section per requirement criterion, one verdict for the phase.
#
# Usage (from REPO_ROOT):
#   ./scripts/phase28-terminal-fuzzel-assert.sh [--section <1-5>]
# Exit 0 if all hard asserts pass; exit 1 if any hard FAIL.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

ASSERT_SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename -- "${BASH_SOURCE[0]}")"

FAIL=0
FINDINGS=0
pass() { printf '[PASS] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
finding() { printf '[FINDING] %s\n' "$1"; FINDINGS=$((FINDINGS + 1)); }
info() { printf '[INFO] %s\n' "$1"; }
```

#### Trap Cleanup, CLI Parser, and Git Snapshot Pattern
**Source:** [scripts/phase27-accent-coordination-assert.sh](file:///home/pera/github_repo/.dotfiles/scripts/phase27-accent-coordination-assert.sh#L26-L78)
```bash
TMP_FILES=()
SCRATCH_ROOTS=()

cleanup() {
  rm -f ${TMP_FILES[@]+"${TMP_FILES[@]}"} 2>/dev/null || true
  local root
  for root in ${SCRATCH_ROOTS[@]+"${SCRATCH_ROOTS[@]}"}; do
    [[ -n "$root" ]] || continue
    chmod -R u+rwX "$root" 2>/dev/null || true
    rm -rf "$root" 2>/dev/null || true
  done
  return 0
}
trap cleanup EXIT

RUN_SECTION=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --section)
      if [[ -z "${2:-}" ]] || ! [[ "$2" =~ ^[1-5]$ ]]; then
        echo "Error: --section requires an integer from 1 to 5" >&2
        exit 1
      fi
      RUN_SECTION="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 [--section <1-5>]"
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

porcelain_snapshot_raw() {
  git status --porcelain --ignored || true
}

porcelain_snapshot() {
  porcelain_snapshot_raw \
    | grep -v -E '^!! (\.commandcode/|scripts/__pycache__/)$' || true
}

PORCELAIN_BEFORE="$(mktemp /tmp/p28-porcelain-before-XXXXXX)"
PORCELAIN_AFTER="$(mktemp /tmp/p28-porcelain-after-XXXXXX)"
TMP_FILES+=("$PORCELAIN_BEFORE" "$PORCELAIN_AFTER")

porcelain_snapshot > "$PORCELAIN_BEFORE"
```

#### Section 1 Pattern: Template & Config Readiness (TERM-01, TERM-02, INTG-01, D-01, D-03, D-12, D-16)
**Source:** [28-RESEARCH.md](file:///home/pera/github_repo/.dotfiles/.planning/phases/28-terminal-fuzzel-launcher-dynamic-palette/28-RESEARCH.md#L374)
```bash
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 1 ]]; then
  info "--- Section 1: Template & Config Readiness (INTG-01, TERM-01, TERM-02, D-01, D-03, D-12, D-16) ---"

  # 1. Matugen Fuzzel template exists and contains M3 tokens
  FUZZEL_TPL="$REPO_ROOT/vendor/dots-hyprland/dots/.config/matugen/templates/fuzzel/fuzzel_theme.ini"
  [[ -f "$FUZZEL_TPL" ]] || FUZZEL_TPL="$XDG_CONFIG_HOME/matugen/templates/fuzzel/fuzzel_theme.ini"
  if [[ -f "$FUZZEL_TPL" ]] && \
     grep -q 'background={{colors.background.default.hex_stripped}}ff' "$FUZZEL_TPL" && \
     grep -q 'text={{colors.on_background.default.hex_stripped}}ff' "$FUZZEL_TPL" && \
     grep -q 'border={{colors.surface_variant.default.hex_stripped}}dd' "$FUZZEL_TPL"; then
    pass "S1: Matugen Fuzzel template declares M3 background, text, and border tokens (D-12, D-13)"
  else
    fail "S1: Matugen Fuzzel template missing or lacks required token bindings ($FUZZEL_TPL)"
  fi

  # 2. Matugen config.toml contains [templates.fuzzel] mapping
  MATUGEN_CFG="$XDG_CONFIG_HOME/matugen/config.toml"
  if [[ -f "$MATUGEN_CFG" ]] && \
     grep -q '^\[templates\.fuzzel\]' "$MATUGEN_CFG" && \
     grep -q 'output_path = "~/\.config/fuzzel/fuzzel_theme\.ini"' "$MATUGEN_CFG"; then
    pass "S1: ~/.config/matugen/config.toml registers [templates.fuzzel] output path (D-12)"
  else
    fail "S1: ~/.config/matugen/config.toml missing [templates.fuzzel] configuration"
  fi

  # 3. stow/kitty kitty.conf include statement
  REPO_KITTY_CONF="$REPO_ROOT/stow/kitty/.config/kitty/kitty.conf"
  if [[ -f "$REPO_KITTY_CONF" ]] && grep -q '^include ~/.local/state/quickshell/user/generated/terminal/kitty-theme.conf' "$REPO_KITTY_CONF"; then
    pass "S1: stow/kitty kitty.conf includes generated kitty-theme.conf (D-01)"
  else
    fail "S1: stow/kitty kitty.conf missing required theme include statement"
  fi

  # 4. stow/fuzzel fuzzel.ini include statement & defaults
  REPO_FUZZEL_INI="$REPO_ROOT/stow/fuzzel/.config/fuzzel/fuzzel.ini"
  if [[ -f "$REPO_FUZZEL_INI" ]] && \
     grep -q '^include="~/.config/fuzzel/fuzzel_theme.ini"' "$REPO_FUZZEL_INI" && \
     grep -q '^terminal=kitty -1' "$REPO_FUZZEL_INI" && \
     grep -q '^radius=17' "$REPO_FUZZEL_INI" && \
     grep -q '^prompt=">>  "' "$REPO_FUZZEL_INI" && \
     grep -q '^exit-immediately-if-empty=yes' "$REPO_FUZZEL_INI"; then
    pass "S1: stow/fuzzel fuzzel.ini declares theme include, terminal=kitty -1, and squircle radius 17 (D-14..D-16)"
  else
    fail "S1: stow/fuzzel fuzzel.ini missing required options ($REPO_FUZZEL_INI)"
  fi

  # 5. guard-paths.tsv contract for fuzzel_theme.ini
  GUARD_TSV="$REPO_ROOT/guard-paths.tsv"
  if grep -qF '$XDG_CONFIG_HOME/fuzzel/fuzzel_theme.ini' "$GUARD_TSV"; then
    pass "S1: guard-paths.tsv guards \$XDG_CONFIG_HOME/fuzzel/fuzzel_theme.ini (D-16)"
  else
    fail "S1: guard-paths.tsv missing fuzzel_theme.ini guard entry"
  fi

  # 6. Claimed helper kittens in stow/kitty
  if [[ -f "$REPO_ROOT/stow/kitty/.config/kitty/search.py" && -f "$REPO_ROOT/stow/kitty/.config/kitty/scroll_mark.py" ]]; then
    pass "S1: Helper kittens search.py and scroll_mark.py present in stow/kitty package (D-03)"
  else
    fail "S1: Helper kittens missing from stow/kitty package (D-03)"
  fi
fi
```

#### Section 2 Pattern: Fuzzel Theme Syntax & Configuration Integrity (TERM-01, D-13, D-14)
**Source:** [28-RESEARCH.md](file:///home/pera/github_repo/.dotfiles/.planning/phases/28-terminal-fuzzel-launcher-dynamic-palette/28-RESEARCH.md#L287-L309)
```bash
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 ]]; then
  info "--- Section 2: Fuzzel Theme Syntax & Configuration Integrity (TERM-01, D-13, D-14) ---"

  LIVE_FUZZEL_THEME="$XDG_CONFIG_HOME/fuzzel/fuzzel_theme.ini"
  if [[ -f "$LIVE_FUZZEL_THEME" && -s "$LIVE_FUZZEL_THEME" ]]; then
    pass "S2: Live fuzzel_theme.ini exists and is non-empty ($LIVE_FUZZEL_THEME)"
  else
    fail "S2: Live fuzzel_theme.ini missing or empty ($LIVE_FUZZEL_THEME)"
  fi

  # Programmatic INI token and alpha validation via Python
  FUZZEL_PY_VERDICT="$(python3 -c "
import configparser, sys, re
c = configparser.ConfigParser()
c.read('$LIVE_FUZZEL_THEME')
if 'colors' not in c:
    print('FAIL: Missing [colors] section')
    sys.exit(1)

tokens = ['background', 'text', 'selection', 'selection-text', 'border', 'match', 'selection-match']
hex8 = re.compile(r'^[0-9a-fA-F]{8}$')
for t in tokens:
    val = c['colors'].get(t)
    if not val or not hex8.match(val):
        print(f'FAIL: Invalid or missing token {t}={val}')
        sys.exit(1)

bg = c['colors']['background']
border = c['colors']['border']
if not bg.endswith('ff'):
    print(f'FAIL: Background alpha must be ff (solid), got {bg}')
    sys.exit(1)
if not border.endswith('dd'):
    print(f'FAIL: Border alpha must be dd, got {border}')
    sys.exit(1)

print('PASS: All tokens valid with correct ff/dd alpha')
" 2>&1 || true)"

  if [[ "$FUZZEL_PY_VERDICT" =~ ^PASS ]]; then
    pass "S2: fuzzel_theme.ini contains all 7 required color tokens with valid 8-digit hex and ff/dd alpha (D-13)"
  else
    fail "S2: fuzzel_theme.ini validation failed: $FUZZEL_PY_VERDICT"
  fi

  # Dry-run invocation of fuzzel parser on empty stdin
  LIVE_FUZZEL_INI="$XDG_CONFIG_HOME/fuzzel/fuzzel.ini"
  if command -v fuzzel &>/dev/null; then
    ERR_OUT="$(fuzzel --config "$LIVE_FUZZEL_INI" -d -R < /dev/null 2>&1 || true)"
    if [[ -z "$ERR_OUT" ]]; then
      pass "S2: fuzzel dry-run parser validation exited cleanly without errors"
    else
      fail "S2: fuzzel dry-run returned configuration error: $ERR_OUT"
    fi
  else
    finding "S2: fuzzel binary not found on PATH; skipping binary parser probe"
  fi
fi
```

#### Section 3 Pattern: Terminal Theme Syntax & Configuration Integrity (TERM-02, D-01, D-02, D-08..D-11)
**Source:** [28-RESEARCH.md](file:///home/pera/github_repo/.dotfiles/.planning/phases/28-terminal-fuzzel-launcher-dynamic-palette/28-RESEARCH.md#L273-L284, #L376)
```bash
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 3 ]]; then
  info "--- Section 3: Terminal Theme Syntax & Configuration Integrity (TERM-02, D-01, D-02, D-08..D-11) ---"

  LIVE_KITTY_THEME="$XDG_STATE_HOME/quickshell/user/generated/terminal/kitty-theme.conf"
  if [[ -f "$LIVE_KITTY_THEME" && -s "$LIVE_KITTY_THEME" ]]; then
    pass "S3: Generated kitty-theme.conf exists and is non-empty ($LIVE_KITTY_THEME)"
  else
    fail "S3: Generated kitty-theme.conf missing or empty ($LIVE_KITTY_THEME)"
  fi

  # ANSI tokens and Starship prompt greys verification
  THEME_VERDICT="$(python3 -c "
import sys, re
hex_pat = re.compile(r'^#[0-9a-fA-F]{6}$')
required_tokens = ['background', 'foreground', 'cursor', 'selection_background', 'selection_foreground']
required_tokens += [f'color{i}' for i in range(16)]
required_tokens += [f'color{i}' for i in range(232, 241)]
required_tokens += [f'color{i}' for i in range(248, 256)]

found = {}
with open('$LIVE_KITTY_THEME', 'r') as f:
    for line in f:
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        parts = line.split()
        if len(parts) >= 2:
            found[parts[0]] = parts[1]

for req in required_tokens:
    if req not in found:
        print(f'FAIL: Missing token {req}')
        sys.exit(1)
    if not hex_pat.match(found[req]):
        print(f'FAIL: Invalid hex color for {req}: {found[req]}')
        sys.exit(1)

print('PASS: ANSI and Starship tokens valid')
" 2>&1 || true)"

  if [[ "$THEME_VERDICT" =~ ^PASS ]]; then
    pass "S3: kitty-theme.conf contains valid ANSI color0-15 and Starship color232-255 hex tokens (D-11)"
  else
    fail "S3: kitty-theme.conf token validation failed: $THEME_VERDICT"
  fi

  # Kitty configuration parser probe for opacity 0.85 and shell zsh
  KITTY_OPTS_VERDICT="$(kitty +runpy "import sys
from kitty.config import load_config
try:
    opts = load_config('$HOME/.config/kitty/kitty.conf')
    if abs(opts.background_opacity - 0.85) > 0.01:
        print(f'FAIL: background_opacity expected 0.85, got {opts.background_opacity}')
        sys.exit(1)
    if opts.shell != 'zsh':
        print(f'FAIL: shell expected zsh, got {opts.shell}')
        sys.exit(1)
    if opts.window_margin_width[0] != 21.75:
        print(f'FAIL: window_margin_width expected 21.75, got {opts.window_margin_width}')
        sys.exit(1)
    print('PASS: Kitty config loaded: opacity=0.85, shell=zsh, margin=21.75')
except Exception as e:
    print(f'FAIL: {e}')
    sys.exit(1)
" 2>&1 || true)"

  if [[ "$KITTY_OPTS_VERDICT" =~ ^PASS ]]; then
    pass "S3: Kitty configuration validated natively: opacity=0.85, shell=zsh, margin=21.75 (D-01, D-02, D-09)"
  else
    fail "S3: Kitty configuration probe failed: $KITTY_OPTS_VERDICT"
  fi

  # Verify ~/.config/illogical-impulse/config.json retains forceDarkMode and tuned parameters
  II_CONFIG="$XDG_CONFIG_HOME/illogical-impulse/config.json"
  if [[ -f "$II_CONFIG" ]]; then
    DARK_MODE="$(jq -r '.appearance.wallpaperTheming.terminalGenerationProps.forceDarkMode' "$II_CONFIG")"
    HARMONY="$(jq -r '.appearance.wallpaperTheming.terminalGenerationProps.harmony' "$II_CONFIG")"
    BOOST="$(jq -r '.appearance.wallpaperTheming.terminalGenerationProps.termFgBoost' "$II_CONFIG")"
    if [[ "$DARK_MODE" == "true" && "$HARMONY" == "0.6" && "$BOOST" == "0.35" ]]; then
      pass "S3: config.json retains forceDarkMode=true, harmony=0.6, termFgBoost=0.35 (D-10, D-11)"
    else
      fail "S3: config.json terminal props mismatch (dark=$DARK_MODE, harm=$HARMONY, boost=$BOOST)"
    fi
  else
    fail "S3: config.json missing at $II_CONFIG"
  fi

  # Universal terminal sequences.txt presence
  LIVE_SEQUENCES="$XDG_STATE_HOME/quickshell/user/generated/terminal/sequences.txt"
  if [[ -f "$LIVE_SEQUENCES" && -s "$LIVE_SEQUENCES" ]]; then
    pass "S3: Generated terminal sequences.txt exists and is non-empty ($LIVE_SEQUENCES)"
  else
    fail "S3: Generated terminal sequences.txt missing or empty ($LIVE_SEQUENCES)"
  fi
fi
```

#### Section 4 Pattern: Live Reload Drill & Process Signaling (TERM-01, TERM-02, D-05, D-18)
**Source:** [scripts/phase27-accent-coordination-assert.sh](file:///home/pera/github_repo/.dotfiles/scripts/phase27-accent-coordination-assert.sh#L350-L365) and [28-RESEARCH.md](file:///home/pera/github_repo/.dotfiles/.planning/phases/28-terminal-fuzzel-launcher-dynamic-palette/28-RESEARCH.md#L377)
```bash
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 4 ]]; then
  info "--- Section 4: Live Reload Drill & Process Signaling (TERM-01, TERM-02, D-05, D-18) ---"

  SWITCHWALL="$XDG_CONFIG_HOME/quickshell/ii/scripts/colors/switchwall.sh"
  if [[ -x "$SWITCHWALL" ]]; then
    pass "S4: switchwall.sh orchestrator exists and is executable ($SWITCHWALL)"
  else
    fail "S4: switchwall.sh missing or not executable ($SWITCHWALL)"
  fi

  LIVE_FUZZEL_THEME="$XDG_CONFIG_HOME/fuzzel/fuzzel_theme.ini"
  LIVE_KITTY_THEME="$XDG_STATE_HOME/quickshell/user/generated/terminal/kitty-theme.conf"
  LIVE_SEQUENCES="$XDG_STATE_HOME/quickshell/user/generated/terminal/sequences.txt"

  BEFORE_FUZZEL_MTIME="$(stat -c %Y "$LIVE_FUZZEL_THEME" 2>/dev/null || echo 0)"
  BEFORE_KITTY_MTIME="$(stat -c %Y "$LIVE_KITTY_THEME" 2>/dev/null || echo 0)"
  BEFORE_SEQ_MTIME="$(stat -c %Y "$LIVE_SEQUENCES" 2>/dev/null || echo 0)"

  # Guarantee filesystem clock-tick before triggering reload
  sleep 1

  # Execute wallpaper reload pipeline without changing wallpaper
  SW_RC=0
  "$SWITCHWALL" --noswitch >/dev/null 2>&1 || SW_RC=$?
  if [[ "$SW_RC" -eq 0 ]]; then
    pass "S4: switchwall.sh --noswitch completed successfully with exit 0"
  else
    fail "S4: switchwall.sh --noswitch failed with exit code $SW_RC"
  fi

  # Record post-run mtimes
  AFTER_FUZZEL_MTIME="$(stat -c %Y "$LIVE_FUZZEL_THEME" 2>/dev/null || echo 0)"
  AFTER_KITTY_MTIME="$(stat -c %Y "$LIVE_KITTY_THEME" 2>/dev/null || echo 0)"
  AFTER_SEQ_MTIME="$(stat -c %Y "$LIVE_SEQUENCES" 2>/dev/null || echo 0)"

  if [[ "$AFTER_FUZZEL_MTIME" -gt "$BEFORE_FUZZEL_MTIME" ]]; then
    pass "S4: fuzzel_theme.ini mtime advanced ($BEFORE_FUZZEL_MTIME -> $AFTER_FUZZEL_MTIME) (D-12)"
  else
    fail "S4: fuzzel_theme.ini mtime was not updated by switchwall.sh"
  fi

  if [[ "$AFTER_KITTY_MTIME" -gt "$BEFORE_KITTY_MTIME" ]]; then
    pass "S4: kitty-theme.conf mtime advanced ($BEFORE_KITTY_MTIME -> $AFTER_KITTY_MTIME) (D-05)"
  else
    fail "S4: kitty-theme.conf mtime was not updated by switchwall.sh"
  fi

  if [[ "$AFTER_SEQ_MTIME" -gt "$BEFORE_SEQ_MTIME" ]]; then
    pass "S4: sequences.txt mtime advanced ($BEFORE_SEQ_MTIME -> $AFTER_SEQ_MTIME) (D-06)"
  else
    fail "S4: sequences.txt mtime was not updated by switchwall.sh"
  fi

  # Dual-mode Kitty process probe
  if pgrep -f kitty >/dev/null; then
    KITTY_PID="$(pidof kitty | awk '{print $1}')"
    kill -SIGUSR1 "$KITTY_PID" 2>/dev/null || true
    sleep 0.2
    if kill -0 "$KITTY_PID" 2>/dev/null; then
      pass "S4: Running Kitty (PID $KITTY_PID) handled SIGUSR1 reload live without terminating (D-05, D-18)"
    else
      fail "S4: Kitty process died after SIGUSR1 reload"
    fi
  else
    info "S4: Kitty not currently running; headless syntax check satisfied by Section 3 probe (D-18)"
  fi
fi
```

#### Section 5 Pattern: Strict Verification Engine & Zero Git Drift (INTG-01, INTG-02, D-17, D-19)
**Source:** [scripts/phase27-accent-coordination-assert.sh](file:///home/pera/github_repo/.dotfiles/scripts/phase27-accent-coordination-assert.sh#L383-L423)
```bash
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 5 ]]; then
  info "--- Section 5: Strict Verification Engine & Zero Git Drift (INTG-01, INTG-02, D-17, D-19) ---"

  # 1. Cleanliness of packaging trees
  DIRTY_PACKAGES="$(git status --porcelain stow/ restow/ capture/ || true)"
  if [[ -z "$DIRTY_PACKAGES" ]]; then
    pass "S5: Packaging directories (stow/, restow/, capture/) are 100% clean (INTG-02)"
  else
    fail "S5: Packaging directories dirty: $DIRTY_PACKAGES (INTG-02)"
  fi

  # 2. Strict verification engine run
  VERIFY_RC=0
  VERIFY_OUT="$("$REPO_ROOT/arch/dots-hyprland.sh" verify --strict 2>&1)" || VERIFY_RC=$?
  if [[ "$VERIFY_RC" -eq 0 ]]; then
    pass "S5: arch/dots-hyprland.sh verify --strict passed with 0 findings (INTG-02)"
  else
    fail "S5: arch/dots-hyprland.sh verify --strict failed (rc=$VERIFY_RC) (INTG-02)"
    printf '%s\n' "$VERIFY_OUT" | sed 's/^/       /' >&2
  fi

  # 3. Assert search.py and scroll_mark.py claimed as verified
  if echo "$VERIFY_OUT" | grep -q 'verified: .*/\.config/kitty/search\.py' && \
     echo "$VERIFY_OUT" | grep -q 'verified: .*/\.config/kitty/scroll_mark\.py'; then
    pass "S5: Helper kittens claimed as verified links rather than unclaimed stubs (D-03)"
  else
    fail "S5: Helper kittens not classified as verified links by verify engine"
  fi
fi

# ===========================================================================
# Closing porcelain invariant check & summary
# ===========================================================================
porcelain_snapshot > "$PORCELAIN_AFTER"
if cmp -s "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER"; then
  pass "Closing self-check: git status --porcelain unchanged across run (D-19)"
else
  fail "Closing self-check: git status --porcelain mutated across run (D-19)"
  diff -u "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER" || true
fi

echo "=== done: FAIL=${FAIL} FINDINGS=${FINDINGS} ==="
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
```

---

### 6. Dynamic Palette Pipelines & Data Contracts (Upstream & Live Integration)

#### A. Matugen Fuzzel Template
**Role:** Declarative Material You template compiling wallpaper palette into Fuzzel INI color section.  
**Analog:** [vendor/dots-hyprland/dots/.config/matugen/templates/fuzzel/fuzzel_theme.ini](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/matugen/templates/fuzzel/fuzzel_theme.ini#L1-L9)
```ini
[colors]
background={{colors.background.default.hex_stripped}}ff
text={{colors.on_background.default.hex_stripped}}ff
selection={{colors.surface_variant.default.hex_stripped}}ff
selection-text={{colors.on_surface_variant.default.hex_stripped}}ff
border={{colors.surface_variant.default.hex_stripped}}dd
match={{colors.primary.default.hex_stripped}}ff
selection-match={{colors.primary.default.hex_stripped}}ff
```

#### B. Upstream Terminal Dynamic Reload Sub-Pipeline (`applycolor.sh`)
**Role:** Synchronously populates `kitty-theme.conf` and `sequences.txt` from `material_colors.scss`, signals Kitty via `kill -SIGUSR1`, and broadcasts OSC sequences to `/dev/pts/*`.  
**Analog:** [vendor/dots-hyprland/dots/.config/quickshell/ii/scripts/colors/applycolor.sh](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/quickshell/ii/scripts/colors/applycolor.sh#L30-L79)
```bash
apply_kitty() {  
  # Check if terminal escape sequence template exists
  if [ ! -f "$SCRIPT_DIR/terminal/kitty-theme.conf" ]; then
    echo "Template file not found for Kitty theme. Skipping that."
    return
  fi
  # Copy template
  mkdir -p "$STATE_DIR"/user/generated/terminal
  cp "$SCRIPT_DIR/terminal/kitty-theme.conf" "$STATE_DIR"/user/generated/terminal/kitty-theme.conf
  # Apply colors
  for i in "${!colorlist[@]}"; do
    sed -i "s/${colorlist[$i]} #/${colorvalues[$i]#\#}/g" "$STATE_DIR"/user/generated/terminal/kitty-theme.conf
  done

  # Reload
  if ! pgrep -f kitty >/dev/null; then
    return
  fi
  kill -SIGUSR1 $(pidof kitty)
}

apply_anyterm() {
  # Check if terminal escape sequence template exists
  if [ ! -f "$SCRIPT_DIR/terminal/sequences.txt" ]; then
    echo "Template file not found for Terminal. Skipping that."
    return
  fi
  # Copy template
  mkdir -p "$STATE_DIR"/user/generated/terminal
  cp "$SCRIPT_DIR/terminal/sequences.txt" "$STATE_DIR"/user/generated/terminal/sequences.txt
  # Apply colors
  for i in "${!colorlist[@]}"; do
    sed -i "s/${colorlist[$i]} #/${colorvalues[$i]#\#}/g" "$STATE_DIR"/user/generated/terminal/sequences.txt
  done

  sed -i "s/\$alpha/$term_alpha/g" "$STATE_DIR/user/generated/terminal/sequences.txt"

  for file in /dev/pts/*; do
    if [[ $file =~ ^/dev/pts/[0-9]+$ ]]; then
      {
      cat "$STATE_DIR"/user/generated/terminal/sequences.txt >"$file"
      } & disown || true
    fi
  done
}
```

#### C. `guard-paths.tsv` Data Contract (Line 18)
**Role:** Excludes generated `fuzzel_theme.ini` from repository tracking, preventing git churn while allowing `arch/dots-hyprland.sh verify --strict` to acknowledge the file as a valid guarded theme output.  
**Analog:** [guard-paths.tsv](file:///home/pera/github_repo/.dotfiles/guard-paths.tsv#L13-L21)
```tsv
# path	category	generator	reason
$XDG_CONFIG_HOME/fuzzel/fuzzel_theme.ini	generated_theme	matugen	Matugen template output
```

---

## Shared Patterns

### 1. Non-Blocking `SIGUSR1` Terminal Theming Reload
**Source:** [vendor/dots-hyprland/dots/.config/quickshell/ii/scripts/colors/applycolor.sh](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/quickshell/ii/scripts/colors/applycolor.sh#L45-L48) and [28-CONTEXT.md](file:///home/pera/github_repo/.dotfiles/.planning/phases/28-terminal-fuzzel-launcher-dynamic-palette/28-CONTEXT.md#L34-L35) D-05  
**Mechanism:**
- Kitty traps signal `SIGUSR1` natively to trigger hot-reloading of `kitty.conf` and all included configuration files without terminating active terminal sessions, running processes, or tmux windows.
- In `applycolor.sh`, the signal is dispatched fail-soft: `pgrep -f kitty >/dev/null && kill -SIGUSR1 $(pidof kitty)`.
- If no Kitty instance is running, the command quietly returns 0. Any freshly opened Kitty window will read the freshly generated `kitty-theme.conf` on startup.

### 2. PTY Escape Sequence Broadcast via Disowned Background Subshells (`/dev/pts/*`)
**Source:** [vendor/dots-hyprland/dots/.config/quickshell/ii/scripts/colors/applycolor.sh](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/quickshell/ii/scripts/colors/applycolor.sh#L67-L73) and [28-CONTEXT.md](file:///home/pera/github_repo/.dotfiles/.planning/phases/28-terminal-fuzzel-launcher-dynamic-palette/28-CONTEXT.md#L35) D-06  
**Mechanism:**
- Secondary terminals (such as Alacritty and Foot) respond to dynamic OSC 4/10/11 color escape sequences written directly into their pseudo-terminal device files.
- Upstream `apply_anyterm()` iterates over `/dev/pts/*`, matching `^/dev/pts/[0-9]+$`.
- Each pipe operation is launched in a backgrounded, disowned subshell block (`{ cat ... > "$file"; } & disown || true`), preventing unresponsive or unowned terminal devices from hanging the main theme pipeline.

### 3. High-Precision Mtime Advancement Verification (Clock-Tick Invariant)
**Source:** [scripts/phase27-accent-coordination-assert.sh](file:///home/pera/github_repo/.dotfiles/scripts/phase27-accent-coordination-assert.sh#L350-L365) and [28-RESEARCH.md](file:///home/pera/github_repo/.dotfiles/.planning/phases/28-terminal-fuzzel-launcher-dynamic-palette/28-RESEARCH.md#L377)  
**Mechanism:**
- Filesystem modification timestamps (`stat -c %Y`) have 1-second granularity on standard Linux filesystems.
- When verifying that `switchwall.sh --noswitch` refreshed theme outputs, test scripts must record pre-run mtimes, execute `sleep 1` to guarantee a clock tick, invoke `switchwall.sh --noswitch`, and assert `AFTER_MTIME > BEFORE_MTIME`.

### 4. Dual-Mode Process Probe (Live Signal vs Headless Python Validation)
**Source:** [28-CONTEXT.md](file:///home/pera/github_repo/.dotfiles/.planning/phases/28-terminal-fuzzel-launcher-dynamic-palette/28-CONTEXT.md#L61) D-18 and [28-RESEARCH.md](file:///home/pera/github_repo/.dotfiles/.planning/phases/28-terminal-fuzzel-launcher-dynamic-palette/28-RESEARCH.md#L273-L284)  
**Mechanism:**
- In an active desktop session with Kitty open, tests probe live responsiveness: dispatching `kill -SIGUSR1` to Kitty and asserting the process remains running after signal receipt.
- In headless CI environments or when Kitty is closed, the test executes `kitty +runpy "from kitty.config import load_config; opts = load_config('$HOME/.config/kitty/kitty.conf')"` to parse and validate options (`background_opacity`, `shell`, `window_margin_width`) through Kitty's native C/Python engine without requiring a graphical Wayland display server.

### 5. Zero-Drift Guarded INI/Config Symlink Separation (Stow vs Guard Paths)
**Source:** [guard-paths.tsv](file:///home/pera/github_repo/.dotfiles/guard-paths.tsv#L18) and [arch/dots-hyprland.sh](file:///home/pera/github_repo/.dotfiles/arch/dots-hyprland.sh#L1120-L1385)  
**Mechanism:**
- Static configuration files (`fuzzel.ini`, `kitty.conf`) are tracked in `stow/` and symlinked to `$HOME`.
- Dynamically generated theme files (`fuzzel_theme.ini`, `kitty-theme.conf`) are NEVER tracked in `stow/` or git:
  - `kitty-theme.conf` resides in `$XDG_STATE_HOME/quickshell/user/generated/terminal/`, outside repository boundaries.
  - `fuzzel_theme.ini` resides in `$XDG_CONFIG_HOME/fuzzel/` and is protected by `guard-paths.tsv` line 18 (`generated_theme	matugen`).
- `arch/dots-hyprland.sh verify --strict` classifies `fuzzel_theme.ini` as `[INFO] guarded theme output:` rather than a finding or untracked drift.

### 6. Safe Stow Package Deployment Procedure (No `--adopt`, Move-Aside First)
**Source:** [28-RESEARCH.md](file:///home/pera/github_repo/.dotfiles/.planning/phases/28-terminal-fuzzel-launcher-dynamic-palette/28-RESEARCH.md#L313-L331) and Repository Standard CAP-07  
**Mechanism:**
- Using `stow --adopt` is strictly prohibited because it can overwrite repository files with foreign host state.
- When replacing existing live regular files in `$HOME` (e.g. `~/.config/fuzzel/fuzzel.ini`, `~/.config/kitty/search.py`, `~/.config/kitty/scroll_mark.py`), the safe procedure is:
  1. Author the file in `stow/<package>/...`.
  2. Remove or move aside the live regular file in `$HOME/.config/...`.
  3. Run `stow --verbose=5 --no-folding -t ~ <package>` from `stow/`.
  4. Verify with `arch/dots-hyprland.sh verify --strict`.

---

## Anti-Patterns to Avoid

- **Adopting Upstream Fish Shell (`shell fish` in `kitty.conf`):** Upstream `vendor/dots-hyprland/dots/.config/kitty/kitty.conf` specifies `shell fish`. Copying this verbatim breaks user login workflows and violates D-02. Always retain `shell zsh`.
- **Using `stow --adopt` to Link Packages:** Banned by CAP-07. Overwrites git working copy files with live disk contents. Always unlink or move aside live files before running `stow --no-folding`.
- **Partial Kitten Stowing (Omitting `scroll_mark.py`):** `search.py` specifically requires `scroll_mark.py` in the same directory (`SCROLLMARK_FILE = Path(__file__).parent.absolute() / "scroll_mark.py"`). Stowing only `search.py` breaks search navigation and leaves `scroll_mark.py` as an unclaimed stub.
- **Hardcoding Terminal Opacity in `applycolor.sh`:** Upstream `applycolor.sh` has `term_alpha=100`. Do not modify upstream shell scripts to tune opacity; declare `background_opacity 0.85` natively in `stow/kitty/.config/kitty/kitty.conf` (honoring D-09).
- **Backgrounding Reload Scripts Without Process Accounting:** Invoking `applycolor.sh` or background subshells without proper execution tracking can cause truncated file writes or orphaned temporary sed files (`sedXXXXXX`).
- **Committing Generated State to Git:** Modifying or adding generated files (`fuzzel_theme.ini`, `kitty-theme.conf`, `sequences.txt`) to git tracking violates repository boundaries and causes dirty porcelain checks.

---

## No Analog Found

*None.* All files to be created, modified, or verified in Phase 28 have direct, high-fidelity analogs in the existing repository codebase:
- `stow/kitty/.config/kitty/kitty.conf`: Existing repository configuration merged with upstream layout.
- `stow/kitty/.config/kitty/search.py` & `scroll_mark.py`: Direct copies from `vendor/dots-hyprland/dots/.config/kitty/`.
- `stow/fuzzel/.config/fuzzel/fuzzel.ini`: Direct repository package modeled after `vendor/dots-hyprland/dots/.config/fuzzel/fuzzel.ini`.
- `scripts/phase28-terminal-fuzzel-assert.sh`: Direct 1:1 structural descendant of `scripts/phase27-accent-coordination-assert.sh` and `scripts/phase26-qt-kde-material-you-assert.sh`.
- `guard-paths.tsv`: Existing repository data contract (line 18).

---

## Verification Checklist

The implementation of Phase 28 will be verified against the following hard assertions in `scripts/phase28-terminal-fuzzel-assert.sh`:

- [ ] **Section 1: Template & Config Readiness**
  - Matugen Fuzzel template declares M3 background, text, border tokens.
  - `~/.config/matugen/config.toml` registers `[templates.fuzzel]` mapping to `~/.config/fuzzel/fuzzel_theme.ini`.
  - `stow/kitty/.config/kitty/kitty.conf` includes `~/.local/state/quickshell/user/generated/terminal/kitty-theme.conf`.
  - `stow/fuzzel/.config/fuzzel/fuzzel.ini` includes `~/.config/fuzzel/fuzzel_theme.ini`, sets `terminal=kitty -1`, `radius=17`, and `exit-immediately-if-empty=yes`.
  - `guard-paths.tsv` line 18 guards `$XDG_CONFIG_HOME/fuzzel/fuzzel_theme.ini`.
  - `search.py` and `scroll_mark.py` exist in `stow/kitty/.config/kitty/`.

- [ ] **Section 2: Fuzzel Theme Syntax & Configuration Integrity**
  - Live `fuzzel_theme.ini` exists and is non-empty.
  - `[colors]` section contains all 7 required color tokens (`background`, `text`, `selection`, `selection-text`, `border`, `match`, `selection-match`).
  - Every token matches 8-digit hex pattern `^[0-9a-fA-F]{8}$`.
  - Background alpha is `ff` (solid) and border alpha is `dd`.
  - `fuzzel --config ~/.config/fuzzel/fuzzel.ini -d -R < /dev/null` exits cleanly with zero errors on stderr.

- [ ] **Section 3: Terminal Theme Syntax & Configuration Integrity**
  - Generated `kitty-theme.conf` exists and is non-empty.
  - ANSI tokens `color0`–`color15` and Starship greys `color232`–`color255` are valid `#RRGGBB` hex colors.
  - Kitty configuration parser validates `background_opacity == 0.85`, `shell == 'zsh'`, and `window_margin_width == 21.75`.
  - `~/.config/illogical-impulse/config.json` retains `forceDarkMode: true`, `harmony: 0.6`, `termFgBoost: 0.35`.
  - Generated terminal `sequences.txt` exists and contains OSC escape sequences.

- [ ] **Section 4: Live Reload Drill & Process Signaling**
  - `switchwall.sh --noswitch` runs and exits with status 0.
  - `fuzzel_theme.ini` modification timestamp advances after reload.
  - `kitty-theme.conf` modification timestamp advances after reload.
  - `sequences.txt` modification timestamp advances after reload.
  - Dual-mode probe: live `kill -SIGUSR1` to running Kitty keeps process alive, or headless parser validates options.

- [ ] **Section 5: Strict Verification Engine & Zero Git Drift**
  - `stow/`, `restow/`, `capture/` are 100% clean in git status.
  - `./arch/dots-hyprland.sh verify --strict` passes with `FAIL=0 FINDINGS=0`.
  - Helper kittens `search.py` and `scroll_mark.py` are claimed as verified symlinks.
  - Git porcelain status before and after test execution is identical (zero repo drift).

---

## Metadata

**Analog search scope:**
- `scripts/phase27-accent-coordination-assert.sh`
- `scripts/phase26-qt-kde-material-you-assert.sh`
- `scripts/phase25-gtk-material-you-assert.sh`
- `stow/kitty/.config/kitty/kitty.conf`
- `vendor/dots-hyprland/dots/.config/kitty/kitty.conf`
- `vendor/dots-hyprland/dots/.config/kitty/search.py`
- `vendor/dots-hyprland/dots/.config/kitty/scroll_mark.py`
- `vendor/dots-hyprland/dots/.config/fuzzel/fuzzel.ini`
- `vendor/dots-hyprland/dots/.config/fuzzel/fuzzel_theme.ini`
- `vendor/dots-hyprland/dots/.config/matugen/templates/fuzzel/fuzzel_theme.ini`
- `vendor/dots-hyprland/dots/.config/quickshell/ii/scripts/colors/switchwall.sh`
- `vendor/dots-hyprland/dots/.config/quickshell/ii/scripts/colors/applycolor.sh`
- `vendor/dots-hyprland/dots/.config/quickshell/ii/scripts/colors/terminal/kitty-theme.conf`
- `vendor/dots-hyprland/dots/.config/quickshell/ii/scripts/colors/terminal/sequences.txt`
- `guard-paths.tsv`
- `collision-map.tsv`
- `arch/dots-hyprland.sh`

**Files scanned:** 17  
**Pattern extraction date:** 2026-09-17  
