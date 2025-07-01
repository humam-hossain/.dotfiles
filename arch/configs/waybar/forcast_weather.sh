#!/usr/bin/env bash
# forecast_weather.sh - Fetch weather forecast and output JSON for Waybar custom module

# Configuration
LOG_FILE="$HOME/.config/waybar/forcast_weather.log"

# import functions
FUNCTIONS_FILE="$(dirname "$0")/functions.sh"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] get_functions_file:${LINENO}: FUNCTIONS_FILE=${FUNCTIONS_FILE}" >> "$LOG_FILE"
if [[ ! -f "$FUNCTIONS_FILE" ]]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] get_functions_file:${LINENO}: functions.sh not found at $FUNCTIONS_FILE" >> "$LOG_FILE"
    echo "{\"text\":\"functions.sh missing\",\"class\":\"error\"}"
    exit 1
fi
source "$FUNCTIONS_FILE"

# ===== UTILITY FUNCTIONS =====
# Determine if it's day or night based on current time and sunrise/sunset
get_is_day() {
    local datetime="$1"
    local sunset="$2"
    local sunrise="$3"

    local curr_sec=$(date -d "${datetime}" +%s)
    local sunrise_sec=$(date -d "${sunrise}" +%s)
    local sunset_sec=$(date -d "${sunset}" +%s)

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [DEBUG] get_is_day:${LINENO}: datetime=${datetime}, curr_sec=${curr_sec}, sunrise=${sunrise}, sunrise_sec=${sunrise_sec}, sunset=${sunset}, sunset_sec=${sunset_sec}" >> "$LOG_FILE"

    if (( curr_sec >= sunrise_sec && curr_sec < sunset_sec )); then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [DEBUG] get_is_day:${LINENO}: result=1 (day)" >> "$LOG_FILE"
        echo 1
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [DEBUG] get_is_day:${LINENO}: result=0 (night)" >> "$LOG_FILE"
        echo 0
    fi
}

# ===== WEATHER DATA FUNCTIONS =====

# Get precipitation display with trend indicators and probability
get_precipitation_display() {
    local next_precip="$1"
    local next_precip_prob="$2"
    local curr_precip="$3"
    local diff_precip display color

    diff_precip=$(echo "$next_precip - $curr_precip" | bc)
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [DEBUG] get_precipitation_display:${LINENO}: next_precip=${next_precip}, curr_precip=${curr_precip}, diff_precip=${diff_precip}, next_precip_prob=${next_precip_prob}" >> "$LOG_FILE"

    display="<span size='11000'>☔</span>"

    if (( $(echo "$diff_precip > 0" | bc) )); then
        display+="<span color='red' size='12000'>󰁞</span>"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [DEBUG] get_precipitation_display:${LINENO}: Precipitation increasing" >> "$LOG_FILE"
    elif (( $(echo "$diff_precip < 0" | bc) )); then
        display+="<span color='green' size='12000'>󰁆</span>"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [DEBUG] get_precipitation_display:${LINENO}: Precipitation decreasing" >> "$LOG_FILE"
    fi

    display+=$(printf "%.2f" "$next_precip")"mm"
    display+="<span size='10000'>[${next_precip_prob}%]</span>"

    color="#5dade2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [DEBUG] get_precipitation_display:${LINENO}: display=${display}, color=${color}" >> "$LOG_FILE"
    echo "<span color='${color}'>${display}</span>"
}

# ===== TOOLTIP FUNCTIONS =====

# Create comprehensive tooltip with hourly forecast
get_tooltip() {
    local response="$1"
    local sunrise="$2"
    local sunset="$3"
    local curr_temp="$4"
    local curr_apparent_temp="$5"
    local curr_humidity="$6"
    local curr_precipitation="$7"
    local curr_pressure="$8"
    local curr_datetime_f="$9"
    local curr_weather_code_text="${10}"
    local curr_weather_text="${11}"

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] get_tooltip:${LINENO}: Entering get_tooltip" >> "$LOG_FILE"

    local hourly_count=$(jq -r '.hourly.time | length' <<< "$response")
    local max_hours=$((hourly_count < 24 ? hourly_count : 24))

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [DEBUG] get_tooltip:${LINENO}: hourly_count=${hourly_count}, max_hours=${max_hours}" >> "$LOG_FILE"

    # Tooltip header
    local tooltip="<big><b>🌤️ Weather Forecast - 24 Hours</b></big>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Updated: ${curr_datetime_f}

<b>Current Weather:</b>
${curr_weather_code_text} Weather: ${curr_weather_text}
🌡️ Temperature: ${curr_temp}°C (feels like ${curr_apparent_temp}°C)
💧 Humidity: ${curr_humidity}%
☔ Precipitation: ${curr_precipitation}mm
󰡴 Pressure: ${curr_pressure}atm

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

<b>Hourly Forecast:</b>
<tt>"

    # Generate hourly forecast entries
    for ((i = 0; i < max_hours; i++)); do
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [DEBUG] get_tooltip:${LINENO}: Generating hourly entry for i=${i}" >> "$LOG_FILE"
        tooltip+=$(generate_hourly_entry "$response" "$i" "$sunrise" "$sunset")
    done

    tooltip+="
</tt>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] get_tooltip:${LINENO}: Exiting get_tooltip" >> "$LOG_FILE"
    echo "$tooltip"
}

# Generate a single hourly forecast entry
generate_hourly_entry() {
    local response="$1"
    local i="$2"
    local sunrise="$3"
    local sunset="$4"

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] generate_hourly_entry:${LINENO}: Entering generate_hourly_entry for i=${i}" >> "$LOG_FILE"

    # Extract hourly data
    local hour_datetime=$(jq -r --argjson idx "$i" '.hourly.time[$idx]' <<< "$response")
    local hour_time=$(date -d "${hour_datetime}" +'%-I:%M%p')
    local hour_weather_code=$(jq -r --argjson idx "$i" '.hourly.weather_code[$idx]' <<< "$response")
    local hour_temp=$(jq -r --argjson idx "$i" '.hourly.temperature_2m[$idx]' <<< "$response")
    local hour_apparent_temp=$(jq -r --argjson idx "$i" '.hourly.apparent_temperature[$idx]' <<< "$response")
    local hour_humidity=$(jq -r --argjson idx "$i" '.hourly.relative_humidity_2m[$idx]' <<< "$response")
    local hour_pressure=$(jq -r --argjson idx "$i" '.hourly.surface_pressure[$idx]' <<< "$response")
    local hour_pressure_atm=$(echo "scale=4; $hour_pressure * 0.0009869233" | bc | awk '{printf "%.2f", $0}')
    local hour_precipitation=$(jq -r --argjson idx "$i" '.hourly.precipitation[$idx]' <<< "$response")
    local hour_precipitation_prob=$(jq -r --argjson idx "$i" '.hourly.precipitation_probability[$idx]' <<< "$response")
    local hour_visibility=$(jq -r --argjson idx "$i" '.hourly.visibility[$idx]' <<< "$response")
    local hour_visibility_km=$(echo "scale=2; $hour_visibility / 1000" | bc | awk '{printf "%.1f", $0}')
    local hour_is_day=$(get_is_day "$hour_datetime" "$sunset" "$sunrise")

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [DEBUG] generate_hourly_entry:${LINENO}: hour_datetime=${hour_datetime}, hour_time=${hour_time}, hour_weather_code=${hour_weather_code}, hour_temp=${hour_temp}, hour_apparent_temp=${hour_apparent_temp}, hour_humidity=${hour_humidity}, hour_pressure=${hour_pressure}, hour_pressure_atm=${hour_pressure_atm}, hour_precipitation=${hour_precipitation}, hour_precipitation_prob=${hour_precipitation_prob}, hour_visibility=${hour_visibility}, hour_visibility_km=${hour_visibility_km}, hour_is_day=${hour_is_day}" >> "$LOG_FILE"

    # Get previous hour's values for comparison
    local prev_temp prev_apparent_temp prev_humidity prev_pressure prev_precipitation
    if (( i == 0 )); then
        prev_temp="$hour_temp"
        prev_apparent_temp="$hour_apparent_temp"
        prev_humidity="$hour_humidity"
        prev_pressure="$hour_pressure_atm"
        prev_precipitation="$hour_precipitation"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [DEBUG] generate_hourly_entry:${LINENO}: First hour, using current hour values for previous" >> "$LOG_FILE"
    else
        prev_temp=$(jq -r --argjson idx "$((i-1))" '.hourly.temperature_2m[$idx]' <<< "$response")
        prev_apparent_temp=$(jq -r --argjson idx "$((i-1))" '.hourly.apparent_temperature[$idx]' <<< "$response")
        prev_humidity=$(jq -r --argjson idx "$((i-1))" '.hourly.relative_humidity_2m[$idx]' <<< "$response")
        local prev_pressure_raw=$(jq -r --argjson idx "$((i-1))" '.hourly.surface_pressure[$idx]' <<< "$response")
        prev_pressure=$(echo "scale=4; $prev_pressure_raw * 0.0009869233" | bc | awk '{printf "%.2f", $0}')
        prev_precipitation=$(jq -r --argjson idx "$((i-1))" '.hourly.precipitation[$idx]' <<< "$response")
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [DEBUG] generate_hourly_entry:${LINENO}: Previous hour values: prev_temp=${prev_temp}, prev_apparent_temp=${prev_apparent_temp}, prev_humidity=${prev_humidity}, prev_pressure=${prev_pressure}, prev_precipitation=${prev_precipitation}" >> "$LOG_FILE"
    fi

    # Generate display components
    local hour_weather_code_text=$(get_weather_icon "$hour_weather_code" "$hour_is_day")
    local hour_temp_text=$(get_temp_display "$hour_temp" "$hour_apparent_temp" "$prev_temp" "$prev_apparent_temp")
    local hour_humidity_text=$(get_humidity_display "$hour_humidity" "$prev_humidity")
    local hour_pressure_text=$(get_pressure_display "$hour_pressure_atm" "$prev_pressure")
    local hour_precipitation_text=$(get_precipitation_display "$hour_precipitation" "$hour_precipitation_prob" "$prev_precipitation")
    local hour_visibility_text=$(get_visibility_display "$hour_visibility_km")
    local hour_weather_text=$(get_weather_text "$hour_weather_code")

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [DEBUG] generate_hourly_entry:${LINENO}: Display components: hour_weather_code_text=${hour_weather_code_text}, hour_temp_text=${hour_temp_text}, hour_humidity_text=${hour_humidity_text}, hour_pressure_text=${hour_pressure_text}, hour_precipitation_text=${hour_precipitation_text}, hour_visibility_text=${hour_visibility_text}, hour_weather_text=${hour_weather_text}" >> "$LOG_FILE"

    local entry=""

    # Add sunrise/sunset separators
    local sunrise_diff=$(( $(date -d "$hour_datetime" +%s) - $(date -d "$sunrise" +%s) ))
    local sunset_diff=$(( $(date -d "$hour_datetime" +%s) - $(date -d "$sunset" +%s) ))
    if (( sunrise_diff > 0 && sunrise_diff < 3600 )); then
        entry+="
        ──────────────────────────────── Sunrise: $(date -d "$sunrise" +'%-I:%M%p') ────────────────────────────────"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [DEBUG] generate_hourly_entry:${LINENO}: Sunrise separator added for hour_datetime=${hour_datetime}" >> "$LOG_FILE"
    elif (( sunset_diff > 0 && sunset_diff < 3600 )); then
        entry+="
        ──────────────────────────────── Sunset: $(date -d "$sunset" +'%-I:%M%p') ────────────────────────────────"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [DEBUG] generate_hourly_entry:${LINENO}: Sunset separator added for hour_datetime=${hour_datetime}" >> "$LOG_FILE"
    fi

    entry+="
        ${hour_time}:  ${hour_weather_code_text} ${hour_weather_text} ${hour_temp_text} ${hour_humidity_text} ${hour_pressure_text} ${hour_precipitation_text} ${hour_visibility_text}"

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] generate_hourly_entry:${LINENO}: Exiting generate_hourly_entry for i=${i}" >> "$LOG_FILE"
    echo "$entry"
}

# ===== API AND CACHING FUNCTIONS =====

# Find next hour index in forecast data
find_next_hour_index() {
    local response="$1"
    local real_datetime=$(date +'%Y-%m-%dT%H:%M')
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] find_next_hour_index:${LINENO}: Entering find_next_hour_index with real_datetime=${real_datetime}" >> "$LOG_FILE"

    local idx=$(jq -r --arg now "$real_datetime" '
        .hourly.time
        | to_entries
        | map(select(.value >= $now))
        | first
        | .key // empty
    ' <<< "$response")

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [DEBUG] find_next_hour_index:${LINENO}: Initial idx from jq=${idx}" >> "$LOG_FILE"

    if [[ -z "$idx" ]]; then
        # If not found, return last index
        idx=$(jq -r '.hourly.time | length - 1' <<< "$response")
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARN] find_next_hour_index:${LINENO}: No future hour found, using last index idx=${idx}" >> "$LOG_FILE"
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] find_next_hour_index:${LINENO}: Found next hour index idx=${idx}" >> "$LOG_FILE"
    fi

    echo "$idx"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] find_next_hour_index:${LINENO}: Exiting find_next_hour_index with idx=${idx}" >> "$LOG_FILE"
}

# ===== DATA EXTRACTION FUNCTIONS =====

# Extract current weather data
extract_current_data() {
    local response="$1"

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] extract_current_data:${LINENO}: Entering extract_current_data" >> "$LOG_FILE"

    # Check if response is valid JSON
    if ! echo "$response" | jq empty 2>/dev/null; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] extract_current_data:${LINENO}: Invalid JSON response" >> "$LOG_FILE"
        echo "Error: Invalid JSON response" >&2
        return 1
    fi

    # Extract values directly without associative array
    local datetime=$(echo "$response" | jq -r '.current.time // "N/A"')
    local is_day=$(echo "$response" | jq -r '.current.is_day // "N/A"')
    local weather_code=$(echo "$response" | jq -r '.current.weather_code // "N/A"')
    local temp=$(echo "$response" | jq -r '.current.temperature_2m // "N/A"')
    local apparent_temp=$(echo "$response" | jq -r '.current.apparent_temperature // "N/A"')
    local humidity=$(echo "$response" | jq -r '.current.relative_humidity_2m // "N/A"')
    local precipitation=$(echo "$response" | jq -r '.current.precipitation // "N/A"')
    local pressure=$(echo "$response" | jq -r '.current.surface_pressure // "N/A"')

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [DEBUG] extract_current_data:${LINENO}: Extracted values: datetime=${datetime}, is_day=${is_day}, weather_code=${weather_code}, temp=${temp}, apparent_temp=${apparent_temp}, humidity=${humidity}, precipitation=${precipitation}, pressure=${pressure}" >> "$LOG_FILE"

    # Calculate atmospheric pressure (avoiding bc dependency)
    local pressure_atm="N/A"
    if [[ "$pressure" != "N/A" ]] && [[ "$pressure" =~ ^[0-9]+\.?[0-9]*$ ]]; then
        pressure_atm=$(awk "BEGIN {printf \"%.2f\", $pressure * 0.0009869233}")
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [DEBUG] extract_current_data:${LINENO}: Calculated pressure_atm=${pressure_atm}" >> "$LOG_FILE"
    fi

    # Output as space-separated values
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] extract_current_data:${LINENO}: Exiting extract_current_data" >> "$LOG_FILE"
    echo "$datetime $is_day $weather_code $temp $apparent_temp $humidity $precipitation $pressure_atm"
}

# Extract forecast data for specific hour
extract_forecast_data() {
    local response="$1"
    local index="$2"

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] extract_forecast_data:${LINENO}: Entering extract_forecast_data with index=${index}" >> "$LOG_FILE"

    local datetime=$(jq -r --argjson idx "$index" '.hourly.time[$idx]' <<< "$response")
    local time=$(date -d "${datetime}" +'%-I:%M%p')
    local weather_code=$(jq -r --argjson idx "$index" '.hourly.weather_code[$idx]' <<< "$response")
    local temp=$(jq -r --argjson idx "$index" '.hourly.temperature_2m[$idx]' <<< "$response")
    local apparent_temp=$(jq -r --argjson idx "$index" '.hourly.apparent_temperature[$idx]' <<< "$response")
    local humidity=$(jq -r --argjson idx "$index" '.hourly.relative_humidity_2m[$idx]' <<< "$response")
    local pressure=$(jq -r --argjson idx "$index" '.hourly.surface_pressure[$idx]' <<< "$response")
    local pressure_atm=$(echo "scale=4; $pressure * 0.0009869233" | bc | awk '{printf "%.2f", $0}')
    local precipitation=$(jq -r --argjson idx "$index" '.hourly.precipitation[$idx]' <<< "$response")
    local precipitation_prob=$(jq -r --argjson idx "$index" '.hourly.precipitation_probability[$idx]' <<< "$response")
    local visibility=$(jq -r --argjson idx "$index" '.hourly.visibility[$idx]' <<< "$response")
    local visibility_km=$(echo "scale=2; $visibility / 1000" | bc | awk '{printf "%.3f", $0}')

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [DEBUG] extract_forecast_data:${LINENO}: Extracted values: datetime=${datetime}, time=${time}, weather_code=${weather_code}, temp=${temp}, apparent_temp=${apparent_temp}, humidity=${humidity}, pressure=${pressure}, pressure_atm=${pressure_atm}, precipitation=${precipitation}, precipitation_prob=${precipitation_prob}, visibility=${visibility}, visibility_km=${visibility_km}" >> "$LOG_FILE"

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] extract_forecast_data:${LINENO}: Exiting extract_forecast_data" >> "$LOG_FILE"
    echo "$datetime $time $weather_code $temp $apparent_temp $humidity $pressure_atm $precipitation $precipitation_prob $visibility_km"
}

# ===== MAIN EXECUTION =====
main() {
    # Check dependencies
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] main:${LINENO}: Starting main function" >> "$LOG_FILE"

    check_dependencies
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] main:${LINENO}: Dependencies checked" >> "$LOG_FILE"
    
    # Fetch weather data
    response=$(fetch_weather_data)
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] main:${LINENO}: Weather data fetched" >> "$LOG_FILE"
    
    if [[ -z "$response" || "$response" == "null" ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] main:${LINENO}: invalid response received!" >> "$LOG_FILE"
        echo "{\"text\":\" No data\",\"class\":\"error\"}"
        exit 0
    fi

    # Extract sunrise/sunset data
    sunrise=$(jq -r '.daily.sunrise[0]' <<< "$response")
    sunset=$(jq -r '.daily.sunset[0]' <<< "$response")
    sunrise_time=$(date -d "$sunrise" +'%-I:%M%p')
    sunset_time=$(date -d "$sunset" +'%-I:%M%p')
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] main:${LINENO}: Sunrise: $sunrise_time, Sunset: $sunset_time" >> "$LOG_FILE"

    # Extract current weather data
    read -r curr_datetime curr_is_day curr_weather_code curr_temp curr_apparent_temp curr_humidity curr_precipitation curr_pressure <<< "$(extract_current_data "$response")"
    curr_datetime_f=$(date -d "$curr_datetime" +'%Y-%m-%d %-I:%M%p')
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] main:${LINENO}: Current weather extracted: $curr_datetime $curr_is_day $curr_weather_code $curr_temp $curr_apparent_temp $curr_humidity $curr_precipitation $curr_pressure" >> "$LOG_FILE"

    # Get current weather display components
    curr_weather_code_text=$(get_weather_icon "$curr_weather_code" "$curr_is_day")
    curr_weather_text=$(get_weather_text "$curr_weather_code")
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] main:${LINENO}: Current weather display: $curr_weather_code_text $curr_weather_text" >> "$LOG_FILE"

    # Find next hour and extract forecast data
    next_hour_index=$(find_next_hour_index "$response")
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] main:${LINENO}: Next hour index: $next_hour_index" >> "$LOG_FILE"
    read -r next_hour_datetime next_hour_time next_hour_weather_code next_hour_temp next_hour_apparent_temp next_hour_humidity next_hour_pressure next_hour_precipitation next_hour_precipitation_prob next_hour_visibility <<< "$(extract_forecast_data "$response" "$next_hour_index")"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] main:${LINENO}: Next hour forecast: $next_hour_datetime $next_hour_time $next_hour_weather_code $next_hour_temp $next_hour_apparent_temp $next_hour_humidity $next_hour_pressure $next_hour_precipitation $next_hour_precipitation_prob $next_hour_visibility" >> "$LOG_FILE"

    # Determine if next hour is day or night
    next_hour_is_day=$(get_is_day "$next_hour_datetime" "$sunset" "$sunrise")
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] main:${LINENO}: Next hour is_day: $next_hour_is_day" >> "$LOG_FILE"

    # Generate display components for forecast
    forecast_weather_text=$(get_weather_icon "$next_hour_weather_code" "$next_hour_is_day")
    forecast_temp_text=$(get_temp_display "$next_hour_temp" "$next_hour_apparent_temp" "$curr_temp" "$curr_apparent_temp")
    forecast_humidity_text=$(get_humidity_display "$next_hour_humidity" "$curr_humidity")
    forecast_pressure_text=$(get_pressure_display "$next_hour_pressure" "$curr_pressure")
    forecast_precipitation_text=$(get_precipitation_display "$next_hour_precipitation" "$next_hour_precipitation_prob" "$curr_precipitation")
    forecast_visibility_text=$(get_visibility_display "$next_hour_visibility")
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] main:${LINENO}: Forecast display: $forecast_weather_text $forecast_temp_text $forecast_humidity_text $forecast_pressure_text $forecast_precipitation_text $forecast_visibility_text" >> "$LOG_FILE"

    # Construct full display text
    full_text="${next_hour_time}: ${forecast_weather_text} ${forecast_temp_text} ${forecast_humidity_text} ${forecast_pressure_text} ${forecast_precipitation_text} ${forecast_visibility_text}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] main:${LINENO}: Full text: $full_text" >> "$LOG_FILE"

    # Create comprehensive tooltip
    tooltip_text=$(get_tooltip "$response" "$sunrise" "$sunset" "$curr_temp" "$curr_apparent_temp" "$curr_humidity" "$curr_precipitation" "$curr_pressure" "$curr_datetime_f" "$curr_weather_code_text" "$curr_weather_text")
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] main:${LINENO}: Tooltip generated" >> "$LOG_FILE"

    # Generate and output final JSON
    output=$(jq -nc --arg text "$full_text" --arg tooltip "$tooltip_text" '{text: $text, tooltip: $tooltip}')
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] main:${LINENO}: Output JSON generated" >> "$LOG_FILE"
    echo -n "$output"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] main:${LINENO}: main function completed" >> "$LOG_FILE"
}

# Execute main function
main