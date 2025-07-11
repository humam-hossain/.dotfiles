set -xe

echo "[INSTALL] pynvim"
sudo pacman -Sy --noconfirm --needed python-pynvim

echo "[INSTALL] luarocks"
sudo pacman -Sy --noconfirm --needed luarocks

echo "[INSTALL] tree-sitter-cli"
sudo pacman -Sy --noconfirm --needed tree-sitter-cli

echo "[INSTALL] neovim"
sudo pacman -Sy --noconfirm --needed neovim

echo "[CONFIG] copying .config"
mkdir -p ~/.config/nvim/
cp -rf .config/nvim/* ~/.config/nvim/
