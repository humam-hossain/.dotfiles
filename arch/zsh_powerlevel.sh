#!/usr/bin/env bash
set -euo pipefail
set -x


echo "[INSTALL] zsh"
sudo pacman -Sy --noconfirm --needed zsh

echo "[CONFIG] default shell zsh"
chsh -s $(which zsh)

echo "[INSTALL] oh-my-zsh"
ZSH_DIR="${ZSH:-$HOME/.oh-my-zsh}"
ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH_DIR/custom}"

if [ -d "$ZSH_DIR" ]; then
	echo "[SKIP] Oh My Zsh already installed in $ZSH_DIR"
else
	echo "[INSTALL] Oh My Zsh to $ZSH_DIR"
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# 1. powerlevel10k
THEME_DIR="$ZSH_CUSTOM/themes/powerlevel10k"
if [ -d "$THEME_DIR" ]; then
	echo "[SKIP] powerlevel10k already installed in $THEME_DIR"
else
	echo "[INSTALL] powerlevel10k → $THEME_DIR"
	git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$THEME_DIR"
fi

# 2. zsh-autosuggestions
AUTO_SUG_DIR="$ZSH_CUSTOM/plugins/zsh-autosuggestions"
if [ -d "$AUTO_SUG_DIR" ]; then
	echo "[SKIP] zsh-autosuggestions already installed in $AUTO_SUG_DIR"
else
	echo "[INSTALL] zsh-autosuggestions → $AUTO_SUG_DIR"
	git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git "$AUTO_SUG_DIR"
fi

# 3. zsh-syntax-highlighting
SYNTAX_DIR="$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
if [ -d "$SYNTAX_DIR" ]; then
	echo "[SKIP] zsh-syntax-highlighting already installed in $SYNTAX_DIR"
else
	echo "[INSTALL] zsh-syntax-highlighting → $SYNTAX_DIR"
	git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "$SYNTAX_DIR"
fi

# 4. zsh-autocomplete
AUTO_CPL_DIR="$ZSH_CUSTOM/plugins/zsh-autocomplete"
if [ -d "$AUTO_CPL_DIR" ]; then
	echo "[SKIP] zsh-autocomplete already installed in $AUTO_CPL_DIR"
else
	echo "[INSTALL] zsh-autocomplete → $AUTO_CPL_DIR"
	git clone --depth=1 https://github.com/marlonrichert/zsh-autocomplete.git "$AUTO_CPL_DIR"
fi

echo "[DONE] all Oh My Zsh plugins/themes are present."

echo "[CONFIG] copying .zshrc"
cp -f .config/.zshrc ~/.zshrc

echo "[CONFIG] copying .zprofile"
cp -f .config/.zprofile ~/.zprofile

echo "[CONFIG] copying .p10k.zsh"
cp -f .config/.p10k.zsh ~/.p10k.zsh
