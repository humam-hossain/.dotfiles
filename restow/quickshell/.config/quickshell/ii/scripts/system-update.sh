#!/usr/bin/env bash
set -euo pipefail

# Accept optional $1 terminal override (passed from Config.options.apps.terminal)
TERM_OVERRIDE="${1:-}"

# If empty, inspect ~/.config/illogical-impulse/config.json for .apps.terminal
if [[ -z "$TERM_OVERRIDE" && -f "$HOME/.config/illogical-impulse/config.json" ]]; then
    TERM_OVERRIDE="$(jq -r '.apps.terminal // empty' "$HOME/.config/illogical-impulse/config.json" 2>/dev/null || true)"
fi

# Fallback to $TERMINAL or detect installed terminal emulators
if [[ -z "$TERM_OVERRIDE" ]]; then
    if [[ -n "${TERMINAL:-}" ]]; then
        TERM_OVERRIDE="$TERMINAL"
    elif command -v kitty >/dev/null 2>&1; then
        TERM_OVERRIDE="kitty -1"
    elif command -v alacritty >/dev/null 2>&1; then
        TERM_OVERRIDE="alacritty"
    elif command -v foot >/dev/null 2>&1; then
        TERM_OVERRIDE="foot"
    elif command -v wezterm >/dev/null 2>&1; then
        TERM_OVERRIDE="wezterm"
    fi
fi

# Launch yay -Syu with terminal-specific hold flags
if [[ "$TERM_OVERRIDE" =~ ^kitty ]]; then
    if [[ "$TERM_OVERRIDE" =~ --hold ]]; then
        exec $TERM_OVERRIDE sh -c 'yay -Syu'
    else
        exec $TERM_OVERRIDE --hold sh -c 'yay -Syu'
    fi
elif [[ "$TERM_OVERRIDE" =~ ^alacritty ]]; then
    if [[ "$TERM_OVERRIDE" =~ --hold ]]; then
        exec $TERM_OVERRIDE -e sh -c 'yay -Syu'
    else
        exec $TERM_OVERRIDE --hold -e sh -c 'yay -Syu'
    fi
elif [[ "$TERM_OVERRIDE" =~ ^foot ]]; then
    if [[ "$TERM_OVERRIDE" =~ (-H|--hold) ]]; then
        exec $TERM_OVERRIDE sh -c 'yay -Syu'
    else
        exec $TERM_OVERRIDE -H sh -c 'yay -Syu'
    fi
elif [[ "$TERM_OVERRIDE" =~ ^wezterm ]]; then
    exec $TERM_OVERRIDE start -- sh -c 'yay -Syu; echo -e "\nUpdate process finished. Press enter to exit..."; read -r _'
elif [[ -n "$TERM_OVERRIDE" ]]; then
    exec $TERM_OVERRIDE -e sh -c 'yay -Syu; echo -e "\nUpdate process finished. Press enter to exit..."; read -r _'
else
    x-terminal-emulator -e sh -c 'yay -Syu; echo -e "\nUpdate process finished. Press enter to exit..."; read -r _'
fi
