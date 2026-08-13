#!/usr/bin/env bash
set -euo pipefail
set -x



# 1. Define Paths
# Explicitly set ZSH_CUSTOM to ~/.zsh
ZSH_CUSTOM="$HOME/.zsh"
PLUGIN_DIR="$ZSH_CUSTOM/plugins"

echo ">> Setting up Zsh Environment..."
echo ">> Plugin Directory: $PLUGIN_DIR"

# 2. Install Zsh & Starship (Arch Linux)
# Uses -Syu to prevent partial upgrade issues common in Arch
echo "[INSTALL] Updating system and installing zsh + starship..."
sudo pacman -Sy --noconfirm --needed zsh starship git

# 3. Clone Plugins
# Function to clone or skip
install_plugin() {
    local name="$1"
    local url="$2"
    local dir="$PLUGIN_DIR/$name"

    if [ -d "$dir" ]; then
        echo "[SKIP] $name already installed."
    else
        echo "[INSTALL] $name..."
        git clone --depth=1 "$url" "$dir"
    fi
}

mkdir -p "$PLUGIN_DIR"

install_plugin "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions.git"
install_plugin "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting.git"
install_plugin "zsh-autocomplete" "https://github.com/marlonrichert/zsh-autocomplete.git"

# 4. Copy Configs
echo "[CONFIG] copying .zshrc"
cd "$(dirname "${BASH_SOURCE[0]}")/../stow" && stow -v=5 -t ~ zsh

# 5. Set Default Shell
current_shell=$(basename "$SHELL")
if [ "$current_shell" != "zsh" ]; then
    echo "[CONFIG] Changing default shell to zsh..."
    # We use chsh for the current user. 
    # This usually prompts for a password.
    chsh -s "$(which zsh)"
else
    echo "[SKIP] Default shell is already zsh."
fi

echo ">> Setup complete! Please log out and log back in."
