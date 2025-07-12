set datafile separator ","
set xdata time
set timefmt "%Y-%m-%d"
set format x "%m-%d"
set title "API Calls Over Time"
set xlabel "Date"
set ylabel "API Calls"
set grid
set terminal pngcairo size 1920,1080
set output "~/.config/waybar/api_plot.png"
plot "~/.config/waybar/api_history.csv" using 1:2 with linespoints title "OpenMeteo Weather API Calls"

set datafile separator ","
set xdata time
set timefmt "%Y-%m-%d_%H:%M:%S"
set format x "%H:%M"
set title "Ping Response Time Over Time"
set xlabel "Time"
set ylabel "Ping (ms)"
set grid
set yrange [0:*]
set terminal pngcairo size 1920,1080
set output "~/.config/waybar/ping_plot.png"
plot "~/.config/waybar/ping_history.csv" using 1:2 with linespoints title "Ping Response Time"
