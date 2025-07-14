set -xe

echo "[INSTALL] pynvim"
sudo apt install -y python3-pynvim

echo "[INSTALL] luarocks"
sudo apt install -y luarocks

echo "[INSTALL] tree-sitter-cli"
sudo apt install -y tree-sitter-cli

echo "[INSTALL] neovim"
sudo apt update
sudo apt install -y software-properties-common
sudo add-apt-repository ppa:neovim-ppa/unstable
sudo apt update
sudo apt install -y neovim

echo "[CONFIG] copying .config"
mkdir -p ~/.config/nvim/
cp -rf .config/nvim/* ~/.config/nvim/
