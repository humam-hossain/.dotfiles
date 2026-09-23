#!/usr/bin/env bash
set -euo pipefail

# Accept optional $1 terminal override (e.g., from Config.options.apps.terminal)
TERM_OVERRIDE="${1:-}"

# Inspect illogical-impulse config if no argument was provided
if [[ -z "$TERM_OVERRIDE" && -f "$HOME/.config/illogical-impulse/config.json" ]]; then
    TERM_OVERRIDE="$(jq -r '.apps.terminal // empty' "$HOME/.config/illogical-impulse/config.json" 2>/dev/null || true)"
fi

# Fallback to $TERMINAL or autodetect installed terminal
if [[ -z "$TERM_OVERRIDE" ]]; then
    if [[ -n "${TERMINAL:-}" ]]; then
        TERM_OVERRIDE="$TERMINAL"
    elif command -v kitty >/dev/null 2>&1; then
        TERM_OVERRIDE="kitty"
    elif command -v alacritty >/dev/null 2>&1; then
        TERM_OVERRIDE="alacritty"
    elif command -v foot >/dev/null 2>&1; then
        TERM_OVERRIDE="foot"
    elif command -v wezterm >/dev/null 2>&1; then
        TERM_OVERRIDE="wezterm"
    else
        TERM_OVERRIDE="x-terminal-emulator"
    fi
fi

# Parse terminal command into an array to handle flags cleanly (e.g., "kitty -1")
read -ra TERM_CMD <<< "$TERM_OVERRIDE"
TERM_BIN="$(basename "${TERM_CMD[0]}")"

# Upgrade and cleanup routine to run inside the terminal
INNER_SCRIPT='
finish() {
    local status=$?
    if [[ $status -ne 0 ]]; then
        echo -e "\n\033[1;31m[!] Update encountered an error (exit code $status).\033[0m"
    else
        echo -e "\n\033[1;32m[✓] System update completed successfully.\033[0m"
    fi
    echo "Press Enter to close..."
    read -r _
}
trap finish EXIT

echo ":: Upgrading system and AUR packages..."
yay -Syu --needed --noconfirm

echo ":: Purging orphaned parallel-download artifacts..."
sudo find /var/cache/pacman/pkg/ -maxdepth 1 -name "download-*" -delete 2>/dev/null || true

echo ":: Managing package cache..."
if command -v paccache >/dev/null 2>&1; then
    # Retain the 2 most recent versions for downgrades; remove uninstalled cache
    sudo paccache -rk2
    sudo paccache -ruk0
    # Clean yay untracked build caches without touching Pacman twice
    yay -Sc --aur --noconfirm
else
    yay -Sc --noconfirm
fi
'

# Launch using the appropriate terminal execution syntax
case "$TERM_BIN" in
    kitty)
        exec "${TERM_CMD[@]}" bash -c "$INNER_SCRIPT"
        ;;
    alacritty)
        exec "${TERM_CMD[@]}" -e bash -c "$INNER_SCRIPT"
        ;;
    foot)
        exec "${TERM_CMD[@]}" bash -c "$INNER_SCRIPT"
        ;;
    wezterm)
        exec "${TERM_CMD[@]}" start -- bash -c "$INNER_SCRIPT"
        ;;
    *)
        exec "${TERM_CMD[@]}" -e bash -c "$INNER_SCRIPT"
        ;;
esac
