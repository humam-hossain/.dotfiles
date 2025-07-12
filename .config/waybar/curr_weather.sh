#!/usr/bin/env bash
# weather.sh - Fetch current weather and output JSON for Waybar custom module

# Configuration: set your latitude and longitude here

LOG_FILE="$HOME/.config/waybar/curr_weather.log"

# import functions
FUNCTIONS_FILE="$(dirname "$0")/functions.sh"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] ${LINENO}: FUNCTIONS_FILE=${FUNCTIONS_FILE}" >>"$LOG_FILE"
if [[ ! -f "$FUNCTIONS_FILE" ]]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] ${LINENO}: functions.sh not found at $FUNCTIONS_FILE" >>"$LOG_FILE"
    echo "{\"text\":\"functions.sh missing\",\"class\":\"error\"}"
    exit 1
fi
source "$FUNCTIONS_FILE"

# Function to get precipitation display
get_precipitation_display() {
    local precipitation="$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] get_precipitation_display:${LINENO}: precipitation=${precipitation}" >>"$LOG_FILE"
    echo "<span color='#5dade2'><span size='12000'>☔</span> ${precipitation}mm</span>"
}

# Function to create detailed tooltip
get_tooltip() {
    local weather_icon="$1"
    local weather_text="$2"
    local temp_2m="$3"
    local apparent_temp="$4"
    local humidity="$5"
    local pressure_atm="$6"
    local precipitation="$7"
    local datetime_f="$8"

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] get_tooltip:${LINENO}: weather_icon=${weather_icon}, weather_text=${weather_text}, temp_2m=${temp_2m}, apparent_temp=${apparent_temp}, humidity=${humidity}, pressure_atm=${pressure_atm}, precipitation=${precipitation}, datetime_f=${datetime_f}" >>"$LOG_FILE"

    local tooltip_text="<big>Current Weather</big>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
${weather_icon} Weather Code: $weather_text
🌡️ Temperature: ${temp_2m}°C (feels like ${apparent_temp}°C)
💧 Humidity: ${humidity}%
󰡴  Pressure: ${pressure_atm} atm
☔ Precipitation: ${precipitation}mm

Updated: ${datetime_f}
"
    echo "$tooltip_text"
}

# Main execution starts here
main() {
    # Dependencies check
    mkdir -p "$(dirname "$LOG_FILE")"

    check_dependencies

    # Fetch weather data
    response=$(fetch_weather_data)

    if [[ -z "$response" || "$response" == "null" ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] main:${LINENO}: invalid response received!" >>"$LOG_FILE"
        echo "{\"text\":\" No data\",\"class\":\"error\"}"
        exit 0
    fi

    # Extract sunrise/sunset data
    sunrise=$(jq -r '.daily.sunrise[0]' <<<"$response")
    sunset=$(jq -r '.daily.sunset[0]' <<<"$response")
    sunrise_time=$(date -d "$sunrise" +'%-I:%M%p')
    sunset_time=$(date -d "$sunset" +'%-I:%M%p')

    # Extract current weather data
    datetime=$(jq -r '.current.time' <<<"$response")
    datetime_f=$(date -d "$datetime" +'%Y-%m-%d %-I:%M%p')
    is_day=$(jq -r '.current.is_day' <<<"$response")
    weather_code=$(jq -r '.current.weather_code' <<<"$response")
    apparent_temp=$(jq -r '.current.apparent_temperature' <<<"$response")
    temp_2m=$(jq -r '.current.temperature_2m' <<<"$response")
    humidity=$(jq -r '.current.relative_humidity_2m' <<<"$response")
    surface_pressure=$(jq -r '.current.surface_pressure' <<<"$response")
    surface_pressure_atm=$(printf "%.2f" "$(echo "scale=4; $surface_pressure * 0.0009869233" | bc -l)")
    precipitation=$(jq -r '.current.precipitation' <<<"$response")

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] main:${LINENO}: API Parsed Data: .current.time:${datetime}, .current.is_day:${is_day}, .current.weather_code:${weather_code}, .current.apparent_temperature:${apparent_temp}, .current.temperature_2m:${temp_2m}, .current.relative_humidity_2m:${humidity}, .current.surface_pressure:${surface_pressure}, .current.precipitation:${precipitation}, .daily.sunrise[0]:${sunrise}, .daily.sunrise[0]:${sunset}" >>"$LOG_FILE"

    # Generate display components using functions
    weather_code_display=$(get_weather_icon "$weather_code" "$is_day")
    temp_text=$(get_temp_display "$temp_2m" "$apparent_temp" "$temp_2m" "$apparent_temp")
    humidity_text=$(get_humidity_display "$humidity" "$humidity")
    pressure_text=$(get_pressure_display "$surface_pressure_atm" "$surface_pressure_atm")
    precipitation_text=$(get_precipitation_display "$precipitation")
    sun_times_text=$(get_sun_times_display "$sunrise_time" "$sunset_time")

    # Construct full display text
    full_text="${weather_code_display}  ${temp_text} ${humidity_text} ${pressure_text} ${precipitation_text} ${sun_times_text}"

    # Log the full display text for debugging
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] main:${LINENO}: full_text=${full_text}" >>"$LOG_FILE"

    # Create tooltip
    weather_text=$(get_weather_text "$weather_code")
    tooltip_text=$(get_tooltip "$weather_code_display" "$weather_text" "$temp_2m" "$apparent_temp" "$humidity" "$surface_pressure_atm" "$precipitation" "$datetime_f")

    # Write the full_text and tooltip_text to the log for debugging
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] main:${LINENO}: Tooltip: $tooltip_text" >>"$LOG_FILE"

    # Generate final JSON output
    output=$(jq -nc --arg text "$full_text" --arg tooltip "$tooltip_text" '{text: $text, tooltip: $tooltip}')

    echo -n "$output"
}

# Execute main function
main
