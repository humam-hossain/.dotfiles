set -xe

echo "[INSTALL] node"
sudo apt install -y nodejs npm

echo "[INSTALL] gemini"
sudo npm install -g @google/gemini-cli
