#!/usr/bin/env bash
set -euo pipefail

# arch/quickshell.sh — Install Quickshell + ddcutil + i2c-tools, configure i2c, symlink config.
# Pattern: mirrors arch/waybar.sh (REPO_ROOT, PACKAGES array, main dispatcher, [LABEL] echos).
# Divergence from waybar.sh: uses a single directory symlink instead of per-file copies (D-17).
# AUR packages (python-materialyoucolor-git) require yay instead of pacman.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
QS_SRC="$REPO_ROOT/.config/quickshell"
QS_DST="$HOME/.config/quickshell"

PACKAGES=(
  quickshell
  ddcutil
  i2c-tools
  python-materialyoucolor-git
  syntax-highlighting  # org.kde.syntaxhighlighting QML bindings (optional for AI code blocks)
)

install_packages() {
  echo "[INSTALL] quickshell and runtime dependencies (${PACKAGES[*]})"
  yay -Sy --noconfirm --needed "${PACKAGES[@]}"
}

setup_i2c() {
  echo "[CONFIG] i2c kernel module and group membership"
  sudo modprobe i2c-dev
  sudo usermod -aG i2c "$USER"
  echo "i2c-dev" | sudo tee /etc/modules-load.d/i2c.conf > /dev/null
  echo "[CONFIG] /etc/modules-load.d/i2c.conf written (i2c-dev will load on every boot)"
}

symlink_config() {
  echo "[CONFIG] symlink $QS_DST -> $QS_SRC"
  mkdir -p "$(dirname "$QS_DST")"
  rm -rf "$QS_DST"
  ln -s "$QS_SRC" "$QS_DST"
}

generate_theme() {
  # generate_colors_material.py prints SCSS tokens to stdout; --cache only stores the
  # source hex (used for wallpaper re-runs). MaterialThemeLoader expects colors.json
  # (snake_case keys) at ~/.local/state/quickshell/user/generated/colors.json.
  echo "[THEME] generating static Material theme colors.json"
  local gen_dir="$HOME/.local/state/quickshell/user/generated"
  local colors_json="$gen_dir/colors.json"
  mkdir -p "$gen_dir"
  python3 "$QS_DST/scripts/colors/generate_colors_material.py" \
    --color "#7aa2f7" \
    --mode dark \
    --scheme scheme-vibrant \
    --cache "$gen_dir/color.txt" \
  | python3 -c '
import json, re, sys
out = {}
for line in sys.stdin:
    m = re.match(r"\$([A-Za-z0-9_]+):\s*(#[0-9A-Fa-f]+);", line.strip())
    if not m:
        continue
    name, val = m.group(1), m.group(2)
    if name in ("darkmode", "transparent"):
        continue
    # camelCase / Pascal-ish tokens -> snake_case for MaterialThemeLoader
    snake = re.sub(r"([a-z0-9])([A-Z])", r"\1_\2", name).lower()
    out[snake] = val
path = sys.argv[1]
with open(path, "w", encoding="utf-8") as f:
    json.dump(out, f, indent=2)
    f.write("\n")
print(f"wrote {len(out)} colors to {path}", file=sys.stderr)
' "$colors_json"
  echo "[THEME] wrote $colors_json"
}

verify_install() {
  echo "[VERIFY] checking install state"
  command -v quickshell >/dev/null || { echo "[VERIFY] FAIL: quickshell not in PATH"; exit 1; }
  command -v ddcutil    >/dev/null || { echo "[VERIFY] FAIL: ddcutil not in PATH";    exit 1; }
  test -L "$QS_DST"                 || { echo "[VERIFY] FAIL: $QS_DST is not a symlink"; exit 1; }
  test -f "$QS_DST/shell.qml"       || { echo "[VERIFY] FAIL: $QS_DST/shell.qml not reachable through symlink"; exit 1; }
  test -f /etc/modules-load.d/i2c.conf || { echo "[VERIFY] FAIL: /etc/modules-load.d/i2c.conf missing"; exit 1; }
  echo "[VERIFY] OK"
}

print_summary() {
  echo "[DONE] Quickshell installed and configured."
  echo "[DONE] Run \`quickshell\` from a terminal to launch the bar (Hyprland exec-once is intentionally not modified in Phase 12)."
  echo ""
  echo "Log out and back in for i2c group to take effect (required for ddcutil)"
}

main() {
  install_packages
  setup_i2c
  symlink_config
  generate_theme
  verify_install
  print_summary
}

main "$@"
