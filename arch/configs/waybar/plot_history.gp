set datafile separator ","
set xdata time
set timefmt "%Y-%m-%d"
set format x "%m-%d"
set title "API Calls Over Time"
set xlabel "Date"
set ylabel "API Calls"
set grid
set terminal pngcairo size 800,400
set output "api_plot.png"
plot "api_history.csv" using 1:2 with linespoints title "API Calls"
