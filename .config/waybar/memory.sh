#!/usr/bin/env bash

# 1. Label: System-wide usage
mem_info=$(free -h | awk '/^Mem:/ {print $3 "/" $2}')
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
    }' | sort -rn | head -10 | awk -v total_mb="$total_mem_mb" '{
        pss_kb = $1
        cmd = ""
        for (i = 2; i <= NF; i++) {
            cmd = cmd " " $i
        }
        sub(/^[ \t]+/, "", cmd)
        
        pss_gb = pss_kb / 1024 / 1024
        process_percent = (pss_kb / (total_mb * 1024)) * 100
        
        printf "%-18s %4.1fG (%4.1f%%)\\n", substr(cmd, 1, 18), pss_gb, process_percent
    }')
    # NOTICE THE \\n ABOVE in printf. This puts a literal "\n" into the string.
    
    # However, to be absolutely safe against shell expansion, we flatten it:
    # This turns physical newlines into the string "\n"
    top_processes=$(echo "$top_processes" | sed ':a;N;$!ba;s/\n/\\n/g' | sed 's/"/\\"/g')
    
    tooltip="<b>Top 10 Processes (PSS):</b>\\n<tt>$top_processes</tt>"
else
    tooltip="<b>Error:</b>\\nInstall smem package."
fi

# 3. Output JSON
# We cut the mem_info to keep it cleaner
text_label="  $mem_info (${percent}%)"

echo "{\"text\": \"$text_label\", \"tooltip\": \"$tooltip\", \"class\": \"memory\", \"percentage\": $percent}"
