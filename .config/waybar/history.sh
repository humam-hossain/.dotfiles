#!/bin/bash

set -xe

echo "[INFO] generating plots"
gnuplot ~/.config/waybar/plot_history.gp

echo "[INFO] open plots"
xdg-open ~/.config/waybar/api_plot.png

echo "[INFO] plot ping"
pushd ~/.config/waybar/
source .venv/bin/activate
python3 plot_ping_history.py
popd
