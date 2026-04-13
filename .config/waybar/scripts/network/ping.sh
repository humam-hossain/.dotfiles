#!/bin/bash

# Ping Status Script
# Usage: ping.sh ['<format>']
#   format : optional string with %1, %2, … placeholders (or '_' for default)
#            %N maps to the Nth target in data/ping.config
#
# Targets and per-target thresholds are read from:
#   ~/.config/waybar/data/ping.config
#
# Output JSON: {"text":"<pango markup>","class":"<worst-quality>"}
# Quality class: good | medium | bad | critical | dead
#
# Example config.jsonc exec lines:
#   "exec": "ping.sh '󰒍 %1'"
#   "exec": "ping.sh '󰒍 %1 ISP: %2 GW: %3'"

# Use script-relative paths
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOG_FILE="$BASE_DIR/logs/ping.log"
DB_FILE="$BASE_DIR/data/pings.db"
CONFIG_FILE="$BASE_DIR/data/ping.config"

# Parallel-indexed arrays populated by load_config
declare -a HOSTS T1S T2S T3S LABELS

# Characters that mark a token as a shell-command fragment, not a display label.
# A token matching this pattern is treated as part of the host expression.
_SHELL_FRAG="{}'\"|\$\`()/<>\\\\"

load_config() {
    while IFS= read -r line; do
        [[ -z "$line" || "$line" == \#* ]] && continue

        # Detect if last 3 fields are numeric thresholds.
        # If so: pre = everything before them; t1/t2/t3 = last 3 fields.
        # Otherwise: whole line is host_expr; thresholds = defaults (40 100 200).
        local nf maybe_t1 maybe_t2 maybe_t3
        nf=$(awk '{print NF}' <<< "$line")
        read -r maybe_t1 maybe_t2 maybe_t3 \
            <<< "$(awk '{print $(NF-2), $(NF-1), $NF}' <<< "$line")"

        local host_expr t1 t2 t3 label=""
        if (( nf >= 4 )) && \
           [[ "$maybe_t1" =~ ^[0-9.]+$ && "$maybe_t2" =~ ^[0-9.]+$ && "$maybe_t3" =~ ^[0-9.]+$ ]]; then
            t1=$maybe_t1; t2=$maybe_t2; t3=$maybe_t3
            local pre
            pre=$(awk '{for(i=1;i<=NF-3;i++) printf "%s%s",$i,(i<NF-3?" ":""); print ""}' <<< "$line")

            # If last token of pre has no shell metacharacters and there are 2+ tokens,
            # treat it as the display label; the rest is the host expression.
            local pre_nf last_tok
            pre_nf=$(awk '{print NF}' <<< "$pre")
            last_tok=$(awk '{print $NF}' <<< "$pre")
            if (( pre_nf >= 2 )) && [[ ! "$last_tok" =~ [$_SHELL_FRAG] ]]; then
                label="$last_tok"
                host_expr=$(awk '{for(i=1;i<=NF-1;i++) printf "%s%s",$i,(i<NF-1?" ":""); print ""}' <<< "$pre")
            else
                host_expr="$pre"
            fi
        else
            t1=40; t2=100; t3=200
            host_expr="$line"
        fi

        # Evaluate host_expr: if it contains shell metacharacters, run it as a command
        local host
        if [[ "$host_expr" =~ [\ \|\$\`\(\)] ]]; then
            host=$(eval "$host_expr" 2>/dev/null | tr -d '[:space:]')
        else
            host="$host_expr"
        fi
        [[ -z "$host" ]] && continue

        HOSTS+=("$host"); T1S+=("$t1"); T2S+=("$t2"); T3S+=("$t3"); LABELS+=("$label")
    done < "$CONFIG_FILE"

    # Fallback if file missing or empty
    if [[ ${#HOSTS[@]} -eq 0 ]]; then
        HOSTS=("8.8.8.8"); T1S=(40); T2S=(100); T3S=(200); LABELS=("󰒍")
    fi
}

log_ping_history() {
    local target_host="$1"
    local ping_ms="$2"
    local datetime
    datetime=$(date '+%Y-%m-%d %H:%M:%S')

    local ms_val
    if [[ "$ping_ms" == "inf" ]]; then
        ms_val="NULL"
    else
        ms_val="$ping_ms"
    fi

    sqlite3 "$DB_FILE" "
        CREATE TABLE IF NOT EXISTS pings (
            ts          TEXT NOT NULL,
            target_host TEXT NOT NULL DEFAULT '8.8.8.8',
            ms          REAL,
            PRIMARY KEY (ts, target_host)
        );
        CREATE INDEX IF NOT EXISTS idx_ts     ON pings(ts);
        CREATE INDEX IF NOT EXISTS idx_target ON pings(target_host);
        INSERT OR IGNORE INTO pings VALUES('$datetime', '$target_host', $ms_val);
    " 2>>"$LOG_FILE"
}

quality_of() {
    local ms="$1" t1="$2" t2="$3" t3="$4"
    echo "DEBUG: quality_of ms=$ms t1=$t1 t2=$t2 t3=$t3" >> "$LOG_FILE"
    if [[ -z "$ms" ]]; then
        echo "offline"
    elif (( $(echo "$ms < $t1" | bc -l) )); then
        echo "good"
    elif (( $(echo "$ms < $t2" | bc -l) )); then
        echo "medium"
    elif (( $(echo "$ms < $t3" | bc -l) )); then
        echo "bad"
    else
        echo "critical"
    fi
}

color_of() {
    case "$1" in
        good)     echo '#00C853' ;;
        medium)   echo '#FFD600' ;;
        bad)      echo '#FF6D00' ;;
        critical) echo '#D50000' ;;
        *)        echo '#37474F' ;;
    esac
}

class_of() {
    if [[ "$1" == "offline" ]]; then echo "dead"; else echo "$1"; fi
}

quality_rank() {
    case "$1" in
        good)     echo 1 ;;
        medium)   echo 2 ;;
        bad)      echo 3 ;;
        critical) echo 4 ;;
        *)        echo 5 ;;
    esac
}

check_dependencies() {
    if ! command -v ping &>/dev/null; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] ping command not found" >>"$LOG_FILE"
        echo '{"text":"missing ping","class":"dead"}'
        exit 1
    fi
}

main() {
    check_dependencies
    load_config

    local fmt="${1:-}"
    local _use_labels=0
    if [[ -z "$fmt" || "$fmt" == "_" ]]; then
        _use_labels=1
        fmt=""
        for i in "${!HOSTS[@]}"; do
            fmt+="%$((i+1)) "
        done
        fmt="${fmt% }"
    fi

    # Ping all targets in parallel, write ms to temp files
    local tmpdir
    tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    for i in "${!HOSTS[@]}"; do
        (
            local out
            out=$(ping -c3 -i0.3 -W1 "${HOSTS[$i]}" 2>/dev/null)
            local ms
            ms=$(echo "$out" | awk -F'/' 'END{if($5~/^[0-9]/) print $5}')
            echo "${ms:-}" > "$tmpdir/$i"
        ) &
    done
    wait

    # Build output text and determine worst class
    local result="$fmt"
    local worst_rank=0
    local worst_class="good"

    for i in "${!HOSTS[@]}"; do
        local host="${HOSTS[$i]}"
        local ms
        ms=$(cat "$tmpdir/$i" 2>/dev/null)
        ms="${ms//[^0-9.]/}"  # allow decimal point

        local ms_int=""
        [[ -n "$ms" ]] && ms_int=$(printf "%.0f" "$ms")

        local quality
        quality=$(quality_of "$ms" "${T1S[$i]}" "${T2S[$i]}" "${T3S[$i]}")

        if [[ -n "$ms" ]]; then
            log_ping_history "$host" "$ms"
        else
            log_ping_history "$host" "inf"
        fi

        local color
        color=$(color_of "$quality")

        local display
        local _text
        if [[ -n "$ms" ]]; then
            if (( $(echo "$ms < 10" | bc -l) )); then
                _text=$(printf "%.2fms" "$ms")
            else
                _text="${ms_int}ms"
            fi
        else
            _text="offline"
        fi
        if (( _use_labels )) && [[ -n "${LABELS[$i]}" ]]; then
            display="<span color='${color}'>${LABELS[$i]} ${_text}</span>"
        else
            display="<span color='${color}'>${_text}</span>"
        fi

        result="${result//%$((i+1))/$display}"

        local rank
        rank=$(quality_rank "$quality")
        if (( rank > worst_rank )); then
            worst_rank=$rank
            worst_class=$(class_of "$quality")
        fi

        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] host=$host ms=${ms:-inf} quality=$quality" >>"$LOG_FILE"
    done

    printf '{"text":"%s","class":"%s"}\n' "$result" "$worst_class"
}

main "$@"
