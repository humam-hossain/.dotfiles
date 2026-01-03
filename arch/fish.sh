set -xe

echo "[INSTALL] fish"
sudo pacman -Sy --noconfirm --needed fish starship eza

echo "[INSTALL] fisher and plugins"
fish <<'EOF'
if not functions -q fisher
    curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
end

set -l plugins "jorgebucaran/fisher" "jethrokuan/z" "jorgebucaran/autopair.fish" "PatrickF1/fzf.fish"
set -l installed (fisher list | string split -n '\n')

for p in $plugins
    if not contains -- $p $installed
        fisher install $p
    end
end
EOF

echo "[CONFIG] copying config"
mkdir -p ~/.config/fish/
cp -rf .config/fish/* ~/.config/fish/
cp .config/starship.toml ~/.config/
