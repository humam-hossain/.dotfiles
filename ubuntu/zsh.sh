#!/usr/bin/env bash
set -xeuo pipefail

# 0. Update package lists
echo "[SYNC] Updating package lists"
sudo apt update

# 1. Install prerequisites
echo "[INSTALL] Core prerequisites (zsh, git, curl, unzip)"
sudo apt install -y \
  zsh \
  git \
  curl \
  unzip

# 2. Change default shell to zsh (if not already)
CURRENT_SHELL=$(getent passwd "$USER" | cut -d: -f7)
ZSH_PATH=$(which zsh)

if [[ "$CURRENT_SHELL" != "$ZSH_PATH" ]]; then
  echo "[CONFIG] Changing default shell to zsh"
  chsh -s "$ZSH_PATH"
else
  echo "[SKIP] Default shell is already zsh"
fi

# 3. Install Oh My Zsh (non‑interactive)
ZSH_DIR="${ZSH:-$HOME/.oh-my-zsh}"
if [[ -d "$ZSH_DIR" ]]; then
  echo "[SKIP] Oh My Zsh already installed at $ZSH_DIR"
else
  echo "[INSTALL] Oh My Zsh → $ZSH_DIR"
  export RUNZSH=no
  export KEEP_ZSHRC=yes
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# 4. Custom plugins & theme directory
ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH_DIR/custom}"

install_if_missing() {
  local url=$1
  local target=$2
  local name=$3

  if [[ -d "$target" ]]; then
    echo "[SKIP] $name already installed at $target"
  else
    echo "[INSTALL] $name → $target"
    git clone --depth=1 "$url" "$target"
  fi
}

# 4.1 powerlevel10k
install_if_missing \
  https://github.com/romkatv/powerlevel10k.git \
  "$ZSH_CUSTOM/themes/powerlevel10k" \
  "powerlevel10k theme"

# 4.2 zsh-autosuggestions
install_if_missing \
  https://github.com/zsh-users/zsh-autosuggestions.git \
  "$ZSH_CUSTOM/plugins/zsh-autosuggestions" \
  "zsh-autosuggestions plugin"

# 4.3 zsh-syntax-highlighting
install_if_missing \
  https://github.com/zsh-users/zsh-syntax-highlighting.git \
  "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" \
  "zsh-syntax-highlighting plugin"

# 4.4 zsh-autocomplete
install_if_missing \
  https://github.com/marlonrichert/zsh-autocomplete.git \
  "$ZSH_CUSTOM/plugins/zsh-autocomplete" \
  "zsh-autocomplete plugin"

echo "[DONE] All Oh My Zsh plugins/themes are present."

# 5. Copy your custom configs (adjust paths as needed)
echo "[CONFIG] Copying dotfiles"
cp -f .config/.zshrc      "$HOME/.zshrc"
cp -f .config/.p10k.zsh   "$HOME/.p10k.zsh"

echo "[COMPLETE] zsh + Oh My Zsh setup finished."
echo "🔁 Please log out and back in (or restart your terminal) to apply the new shell."

