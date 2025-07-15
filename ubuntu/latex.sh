set -xe

echo "[INSTALL] latex (recommended)"
sudo apt install -y texlive-xetex texlive-latex-recommended texlive-latex-extra texlive-fonts-recommended texlive-luatex
sudo apt install -y latexmk

echo "[DONE] usage: latexmk -xelatex -pvc main.tex"
