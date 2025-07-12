#!/bin/bash

set -xe

echo "[INFO] generating plots"
gnuplot ~/.config/waybar/plot_history.gp

echo "[INFO] open plots"
xdg-open ~/.config/waybar/api_plot.png
xdg-open ~/.config/waybar/ping_plot.png
