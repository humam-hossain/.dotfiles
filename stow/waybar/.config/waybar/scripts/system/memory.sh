#!/usr/bin/env bash

# 1. Label: Free / Total in GB with decimals
# We use 'free -m' to get raw MB numbers, then divide by 1024 in awk to get GB
mem_info=$(free -m | awk '/^Mem:/ {
    used_gb = $3 / 1024;
    total_gb = $2 / 1024;
    # Format to 1 decimal place (e.g., 8.5G/15.5G)
    printf "%.1fG/%.1fG", used_gb, total_gb
}')

used_mem_mb=$(free -m | awk '/^Mem:/ {print $3}')
total_mem_mb=$(free -m | awk '/^Mem:/ {print $2}')
percent=$(( 100 * used_mem_mb / total_mem_mb ))

# 2. Tooltip: Top 10 Processes by PSS
if command -v smem &> /dev/null; then
    top_processes=$(smem -H -c "name pss" | awk '
    {
        mem[$1] += $2
    }
    END {
        for (c in mem) {
            print mem[c], c
        }
    }' | sort -rn | head -20 | awk -v total_mb="$total_mem_mb" '{
        pss_kb = $1
        cmd = ""
        for (i = 2; i <= NF; i++) {
            cmd = cmd " " $i
        }
        sub(/^[ \t]+/, "", cmd)
        
        pss_gb = pss_kb / 1024 / 1024
        process_percent = (pss_kb / (total_mb * 1024)) * 100
        
        # Escape backslashes for JSON compatibility
        gsub(/\\/, "\\\\", cmd);
        gsub(/"/, "\\\"", cmd);
        
        printf "%-18s %4.1fG (%4.1f%%)\\n", substr(cmd, 1, 18), pss_gb, process_percent
    }')
    
    # Flatten newlines for JSON
    top_processes=$(echo "$top_processes" | sed ':a;N;$!ba;s/\n/\\n/g')
    
    tooltip="<b>Top Processes (PSS):</b>\\n<tt>$top_processes</tt>"
else
    tooltip="<b>Error:</b>\\nInstall smem package."
fi

# 3. Output JSON
text_label="  $mem_info (${percent}%)"

echo "{\"text\": \"$text_label\", \"tooltip\": \"$tooltip\", \"class\": \"memory\", \"percentage\": $percent}"
