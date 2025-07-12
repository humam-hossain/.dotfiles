#!/bin/bash

# Ping Status Script
# Returns JSON with ping latency and status class

LOG_FILE="$HOME/.config/waybar/ping.log"
PING_HISTORY_FILE="$HOME/.config/waybar/ping_history.csv"

# Function to log ping history
log_ping_history() {
    local ping_ms="$1"

    if [[ ! -f "$PING_HISTORY_FILE" ]]; then
        mkdir -p "$(dirname "$PING_HISTORY_FILE")"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] log_ping_history:${LINENO}: Created PING history file at $PING_HISTORY_FILE" >>"$LOG_FILE"
        echo "date,ping_ms" >>"$PING_HISTORY_FILE"
    fi

    local datetime=$(date +%Y-%m-%d_%H:%M:%S)
    echo "${datetime},${ping_ms}" >>"$PING_HISTORY_FILE"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] log_ping_history:${LINENO}: Updated PING history with ${ping_ms}ms at $PING_HISTORY_FILE" >>"$LOG_FILE"
}

# Function to check ping status
ping_check() {
    local host="$1"
    local count="$2"

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] ping_check: Starting ping to $host with $count packets" >>"$LOG_FILE"

    # Get the raw ping output and extract ms value
    local ping_output=$(ping -c"$count" "$host" 2>/dev/null)
    local ms=$(echo "$ping_output" | awk -F'/' 'END{if($5~/^[0-9]/) print int($5)}')

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] ping_check: Extracted ms value: $ms" >>"$LOG_FILE"

    # Build JSON result and log the ms value
    local ping_result
    if [ -n "$ms" ] && [ "$ms" -gt 0 ]; then
        if [ "$ms" -lt 100 ]; then
            ping_result='{"text":"󰒍 '$ms' ms","class":"good"}'
        elif [ "$ms" -lt 200 ]; then
            ping_result='{"text":"󰒍 '$ms' ms","class":"medium"}'
        else
            ping_result='{"text":"󰒍 '$ms' ms","class":"bad"}'
        fi
        log_ping_history "$ms"
    else
        ping_result='{"text":"unable ping","class":"dead"}'
        log_ping_history "inf"
    fi

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] ping_check: ms=$ms, Result: $ping_result" >>"$LOG_FILE"
    echo "$ping_result"
}

# Function to check dependencies
check_dependencies() {
    # Check if ping command is available
    if ! command -v ping &>/dev/null; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] check_dependencies: cannot find ping command!" >>"$LOG_FILE"
        echo '{"text":"missing_dependencies","class":"dead"}'
        exit 1
    fi
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] check_dependencies: ping command found" >>"$LOG_FILE"
}

# Main function
main() {
    local target_host="${1:-8.8.8.8}"
    local ping_count="${2:-3}"

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] main: Script started with host=$target_host, count=$ping_count" >>"$LOG_FILE"

    check_dependencies
    ping_check "$target_host" "$ping_count"
}

# Run main function with command line arguments
main "$@"
