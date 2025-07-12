LATITUDE=23.758492
LONGITUDE=90.390055
CACHE_DURATION=900 # 15 minutes in seconds
PER_API_CALL_COST=1.6
CACHE_FILE="$HOME/.config/waybar/api_response.json"
API_COUNT_FILE="$HOME/.config/waybar/api_count.txt"
API_HISTORY_FILE="$HOME/.config/waybar/api_history.csv"

# Function to get weather text description
get_weather_text() {
    local weather_code="$1"
    local weather_text
    case "$weather_code" in
    0) weather_text="Clear sky" ;;
    1) weather_text="Mainly clear" ;;
    2) weather_text="Partly cloudy" ;;
    3) weather_text="Overcast" ;;
    45) weather_text="Fog" ;;
    48) weather_text="Depositing rime fog" ;;
    51) weather_text="Drizzle(Light)" ;;
    53) weather_text="Drizzle(Moderate)" ;;
    55) weather_text="Drizzle(Dense)" ;;
    56) weather_text="Freezing Drizzle(Light)" ;;
    57) weather_text="Freezing Drizzle(Dense)" ;;
    61) weather_text="Rain(Slight)" ;;
    63) weather_text="Rain(Moderate)" ;;
    65) weather_text="Rain(Heavy)" ;;
    66) weather_text="Freezing Rain(Light)" ;;
    67) weather_text="Freezing Rain(Heavy)" ;;
    71) weather_text="Snow fall(Slight)" ;;
    73) weather_text="Snow fall(Moderate)" ;;
    75) weather_text="Snow fall(Heavy)" ;;
    77) weather_text="Snow grains" ;;
    80) weather_text="Rain showers(Slight)" ;;
    81) weather_text="Rain showers(Moderate)" ;;
    82) weather_text="Rain showers(Violent)" ;;
    85) weather_text="Snow showers(Slight)" ;;
    86) weather_text="Snow showers(Heavy)" ;;
    95) weather_text="Thunderstorm(Slight or moderate)" ;;
    96) weather_text="Thunderstorm with slight hail" ;;
    99) weather_text="Thunderstorm with heavy hail" ;;
    *) weather_text="Unknown" ;;
    esac

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] get_weather_text:${LINENO}: weather_code=${weather_code}, weather_text=${weather_text}" >>"$LOG_FILE"

    echo "$weather_text"
}

# Function to get weather icon based on weather code and day/night
get_weather_icon() {
    local weather_code="$1"
    local is_day="$2"
    local weather_icon weather_color weather_size

    if [[ "$is_day" == 1 ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] get_weather_icon:${LINENO}: is_day=true, day time" >>"$LOG_FILE"
        case "$weather_code" in
        2 | 3)
            weather_icon="⛅"
            weather_color="white"
            weather_size="11000"
            ;;
        45 | 48)
            weather_icon="󰖑"
            weather_color="white"
            weather_size="12000"
            ;;
        51 | 53 | 55 | 56 | 57 | 61 | 63 | 65 | 66 | 67)
            weather_icon=""
            weather_color="white"
            weather_size="12000"
            ;;
        71 | 73 | 75 | 77)
            weather_icon="❄️"
            weather_color="white"
            weather_size="11000"
            ;;
        80 | 81 | 82 | 85 | 86)
            weather_icon="🌧️"
            weather_color="white"
            weather_size="11000"
            ;;
        95 | 96 | 99)
            weather_icon="⛈️"
            weather_color="white"
            weather_size="11000"
            ;;
        *)
            weather_icon="☀️"
            weather_color="yellow"
            weather_size="11000"
            ;;
        esac
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] get_weather_icon:${LINENO}: is_day=false, night time" >>"$LOG_FILE"
        case "$weather_code" in
        2 | 3)
            weather_icon="☁️"
            weather_color="white"
            weather_size="11000"
            ;;
        45 | 48)
            weather_icon="󰖑"
            weather_color="white"
            weather_size="12000"
            ;;
        51 | 53 | 55 | 56 | 57 | 61 | 63 | 65 | 66 | 67)
            weather_icon=""
            weather_color="white"
            weather_size="12000"
            ;;
        71 | 73 | 75 | 77)
            weather_icon="❄️"
            weather_color="white"
            weather_size="11000"
            ;;
        80 | 81 | 82 | 85 | 86)
            weather_icon="🌧️"
            weather_color="white"
            weather_size="11000"
            ;;
        95 | 96 | 99)
            weather_icon="⛈️"
            weather_color="white"
            weather_size="11000"
            ;;
        *)
            weather_icon="󰖔"
            weather_color="white"
            weather_size="12000"
            ;;
        esac
    fi

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] get_weather_icon:${LINENO}: weather_code=${weather_code}, is_day=${is_day}, weather_icon=${weather_icon}, weather_color=${weather_color}, weather_size=${weather_size}" >>"$LOG_FILE"

    echo "<span color='${weather_color}' size='${weather_size}'>${weather_icon}</span>"
}

# Get temperature display with trend indicators
get_temp_display() {
    local temp_2m="$1"
    local apparent_temp="$2"
    local curr_temp_2m="$3"
    local curr_apparent_temp="$4"

    local temp_display temp_color diff_temp curr_diff_temp_2m curr_diff_apparent_temp formatted_diff

    diff_temp=$(echo "$apparent_temp - $temp_2m" | bc)
    curr_diff_temp_2m=$(echo "$temp_2m - $curr_temp_2m" | bc)
    curr_diff_apparent_temp=$(echo "$apparent_temp - $curr_apparent_temp" | bc)

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] get_temp_display:${LINENO}: temp_2m=${temp_2m}, apparent_temp=${apparent_temp}, curr_temp_2m=${curr_temp_2m}, curr_apparent_temp=${curr_apparent_temp}, diff_temp=${diff_temp}, curr_diff_temp_2m=${curr_diff_temp_2m}, curr_diff_apparent_temp=${curr_diff_apparent_temp}" >>"$LOG_FILE"

    temp_display="<span size='11000'>🌡️</span>"

    # Temperature trend indicator
    if (($(echo "$curr_diff_temp_2m > 0" | bc))); then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] get_temp_display:${LINENO}: curr_diff_temp_2m > 0 (rising)" >>"$LOG_FILE"
        temp_display+="<span color='red' size='12000'>󰁞</span>"
    elif (($(echo "$curr_diff_temp_2m < 0" | bc))); then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] get_temp_display:${LINENO}: curr_diff_temp_2m < 0 (falling)" >>"$LOG_FILE"
        temp_display+="<span color='green' size='12000'>󰁆</span>"
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] get_temp_display:${LINENO}: curr_diff_temp_2m == 0 (steady)" >>"$LOG_FILE"
    fi

    temp_display+="${temp_2m}°C"

    # Add feels-like temperature with trend
    formatted_diff=$(printf "%.1f" "$diff_temp")
    if (($(echo "$diff_temp > 0" | bc))); then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] get_temp_display:${LINENO}: diff_temp > 0 (feels warmer)" >>"$LOG_FILE"
        temp_display+="[+${formatted_diff}"
    elif (($(echo "$diff_temp < 0" | bc))); then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] get_temp_display:${LINENO}: diff_temp < 0 (feels colder)" >>"$LOG_FILE"
        temp_display+="[${formatted_diff}"
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] get_temp_display:${LINENO}: diff_temp == 0 (feels same)" >>"$LOG_FILE"
        temp_display+="[${formatted_diff}"
    fi

    # Apparent temperature trend indicator
    if (($(echo "$curr_diff_apparent_temp > 0" | bc))); then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] get_temp_display:${LINENO}: curr_diff_apparent_temp > 0 (apparent rising)" >>"$LOG_FILE"
        temp_display+="<span color='red' size='12000'>󰁞</span>"
    elif (($(echo "$curr_diff_apparent_temp < 0" | bc))); then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] get_temp_display:${LINENO}: curr_diff_apparent_temp < 0 (apparent falling)" >>"$LOG_FILE"
        temp_display+="<span color='green' size='12000'>󰁆</span>"
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] get_temp_display:${LINENO}: curr_diff_apparent_temp == 0 (apparent steady)" >>"$LOG_FILE"
    fi
    temp_display+="]"

    # Temperature color coding
    if (($(echo "$temp_2m < 15" | bc))); then
        temp_color="#3498db" # Blue
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] get_temp_display:${LINENO}: temp_2m < 15, temp_color=${temp_color}" >>"$LOG_FILE"
    elif (($(echo "$temp_2m < 20" | bc))); then
        temp_color="#5dade2" # Light blue
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] get_temp_display:${LINENO}: temp_2m < 20, temp_color=${temp_color}" >>"$LOG_FILE"
    elif (($(echo "$temp_2m < 30" | bc))); then
        temp_color="#58d68d" # Green
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] get_temp_display:${LINENO}: temp_2m < 30, temp_color=${temp_color}" >>"$LOG_FILE"
    else
        temp_color="#ec7063" # Red
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] get_temp_display:${LINENO}: temp_2m >= 30, temp_color=${temp_color}" >>"$LOG_FILE"
    fi

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] get_temp_display:${LINENO}: temp_display=${temp_display}, temp_color=${temp_color}" >>"$LOG_FILE"

    echo "<span color='${temp_color}'>${temp_display}</span>"
}

# Get humidity display with trend indicators
get_humidity_display() {
    local next_humidity="$1"
    local curr_humidity="$2"
    local diff_humidity display

    diff_humidity=$(echo "$next_humidity - $curr_humidity" | bc)
    display="<span size='11000'>💧</span>"

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] get_humidity_display:${LINENO}: next_humidity=${next_humidity}, curr_humidity=${curr_humidity}, diff_humidity=${diff_humidity}" >>"$LOG_FILE"

    if (($(echo "$diff_humidity > 0" | bc))); then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] get_humidity_display:${LINENO}: diff_humidity > 0 (rising)" >>"$LOG_FILE"
        display+="<span color='red' size='12000'>󰁞</span>"
    elif (($(echo "$diff_humidity < 0" | bc))); then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] get_humidity_display:${LINENO}: diff_humidity < 0 (falling)" >>"$LOG_FILE"
        display+="<span color='green' size='12000'>󰁆</span>"
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] get_humidity_display:${LINENO}: diff_humidity == 0 (steady)" >>"$LOG_FILE"
    fi
    display+="${next_humidity}%"

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] get_humidity_display:${LINENO}: display=${display}" >>"$LOG_FILE"

    echo "<span color='#3498db'>${display}</span>"
}

get_pressure_display() {
    local next_pressure="$1"
    local curr_pressure="$2"
    local diff_pressure display

    diff_pressure=$(echo "$next_pressure - $curr_pressure" | bc)
    display="<span size='11000'>󰡴</span> "

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] get_pressure_display:${LINENO}: next_pressure=${next_pressure}, curr_pressure=${curr_pressure}, diff_pressure=${diff_pressure}" >>"$LOG_FILE"

    if (($(echo "$diff_pressure > 0" | bc))); then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] get_pressure_display:${LINENO}: diff_pressure > 0 (rising)" >>"$LOG_FILE"
        display+="<span color='red' size='12000'>󰁞</span>"
    elif (($(echo "$diff_pressure < 0" | bc))); then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] get_pressure_display:${LINENO}: diff_pressure < 0 (falling)" >>"$LOG_FILE"
        display+="<span color='green' size='12000'>󰁆</span>"
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] get_pressure_display:${LINENO}: diff_pressure == 0 (steady)" >>"$LOG_FILE"
    fi
    display+="${next_pressure}atm"

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] get_pressure_display:${LINENO}: display=${display}" >>"$LOG_FILE"

    echo "<span color='#f7dc6f'>${display}</span>"
}

# Get sunrise/sunset display
get_sun_times_display() {
    local sunrise_time="$1"
    local sunset_time="$2"

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] get_sun_times_display:${LINENO}: sunrise_time=${sunrise_time}, sunset_time=${sunset_time}" >>"$LOG_FILE"

    local sunrise_text="<span color='#ffa700'><span size='12000'></span>  ${sunrise_time}</span>"
    local sunset_text="<span color='#5dade2'><span size='12000'></span>  ${sunset_time}</span>"

    echo "${sunrise_text} ${sunset_text}"
}

# Get visibility display with color coding
get_visibility_display() {
    local next_visibility="$1"
    local display color icon

    icon="󰈈"
    if (($(echo "$next_visibility < 2" | bc))); then
        icon="󰈉"
        color="#e74c3c" # Red for poor visibility
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] get_visibility_display:${LINENO}: next_visibility=${next_visibility} < 2, icon=${icon}, color=${color}" >>"$LOG_FILE"
    elif (($(echo "$next_visibility < 10" | bc))); then
        color="#f1c40f" # Yellow for moderate visibility
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] get_visibility_display:${LINENO}: next_visibility=${next_visibility} < 10, icon=${icon}, color=${color}" >>"$LOG_FILE"
    elif (($(echo "$next_visibility < 30" | bc))); then
        color="#2ecc71" # Green for good visibility
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] get_visibility_display:${LINENO}: next_visibility=${next_visibility} < 30, icon=${icon}, color=${color}" >>"$LOG_FILE"
    else
        color="blue"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] get_visibility_display:${LINENO}: next_visibility=${next_visibility} >= 30, icon=${icon}, color=${color}" >>"$LOG_FILE"
    fi

    display="<span size='12000'>${icon}</span> "
    display+="${next_visibility}km"

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] get_visibility_display:${LINENO}: display=${display}" >>"$LOG_FILE"

    echo "<span color='${color}'>${display}</span>"
}

# Fetch weather data with intelligent caching
fetch_weather_data() {
    local response

    # api count file
    mkdir -p "$(dirname "$API_COUNT_FILE")"
    if [[ -f "$API_COUNT_FILE" ]]; then
        api_count=$(cat "$API_COUNT_FILE")
    else
        api_count=0
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] fetch_weather_data:${LINENO}: API count file not found or empty, initializing api_count=${api_count}" >>"$LOG_FILE"
    fi

    # check if api history file exists
    # Get current date in YYYY-MM-DD format
    real_datetime=$(date +%Y-%m-%d)
    last_datetime=""
    if [[ ! -f "$API_HISTORY_FILE" ]]; then
        mkdir -p "$(dirname "$API_HISTORY_FILE")"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] fetch_weather_data:${LINENO}: Created API history file at $API_HISTORY_FILE" >>"$LOG_FILE"

        echo "date,api_calls" >>"$API_HISTORY_FILE"
        echo "${real_datetime},0" >>"$API_HISTORY_FILE"
    fi

    # Find the last datetime and api_calls in the API_HISTORY_FILE
    last_line=$(tail -n 1 "$API_HISTORY_FILE")
    if [[ "$last_line" =~ ^([0-9]{4}-[0-9]{2}-[0-9]{2}),([0-9.]+) ]]; then
        last_datetime="${BASH_REMATCH[1]}"
        last_api_calls="${BASH_REMATCH[2]}"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] fetch_weather_data:${LINENO}: last_datetime=${last_datetime}, last_api_calls=${last_api_calls}" >>"$LOG_FILE"
    fi

    if [[ "$real_datetime" != "$last_datetime" && -n "$last_datetime" ]]; then
        # Rewrite the last line with last_datetime and current api_count
        sed -i '$d' "$API_HISTORY_FILE"
        echo "${last_datetime},${api_count}" >>"$API_HISTORY_FILE"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] fetch_weather_data:${LINENO}: Updated API_HISTORY_FILE for previous day: ${last_datetime},${api_count}" >>"$LOG_FILE"

        # reset for new day
        api_count=0
        echo "$api_count" >"$API_COUNT_FILE"
        echo "${real_datetime},0" >>"$API_HISTORY_FILE"
    fi

    # Check cache validity
    if [[ -f "$CACHE_FILE" ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] fetch_weather_data:${LINENO}: ${CACHE_FILE} found!" >>"$LOG_FILE"

        response=$(cat "$CACHE_FILE")
        local curr_datetime=$(jq -r '.current.time' <<<"$response")
        local real_datetime=$(date +'%Y-%m-%dT%H:%M')
        local real_sec=$(date -d "$real_datetime" +%s)
        local curr_sec=$(date -d "$curr_datetime" +%s)

        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] fetch_weather_data:${LINENO}: api updated at ${curr_datetime}, real datetime ${real_datetime}" >>"$LOG_FILE"

        # Use cache if less than 15 minutes old
        if ((real_sec - curr_sec <= CACHE_DURATION)); then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] fetch_weather_data:${LINENO}: api response is still valid! api response expires in $((real_sec - curr_sec)) seconds" >>"$LOG_FILE"
            echo "$response"
            return
        fi
    fi

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] fetch_weather_data:${LINENO}: api response has expired, fetching new data from open-meteo" >>"$LOG_FILE"

    # Fetch fresh data
    api_count=$(echo "$api_count + ${PER_API_CALL_COST}" | bc)
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] fetch_weather_data:${LINENO}: Incrementing api_count by ${PER_API_CALL_COST}" >>"$LOG_FILE"
    echo "$api_count" >"$API_COUNT_FILE"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] fetch_weather_data:${LINENO}: API request count: $api_count" >>"$LOG_FILE"

    response=$(curl -s \
        "https://api.open-meteo.com/v1/forecast?latitude=${LATITUDE}&longitude=${LONGITUDE}&daily=sunrise,sunset&hourly=weather_code,temperature_2m,apparent_temperature,relative_humidity_2m,precipitation,precipitation_probability,visibility,surface_pressure&current=is_day,weather_code,apparent_temperature,temperature_2m,relative_humidity_2m,surface_pressure,precipitation&timezone=auto&temperature_unit=celsius&forecast_days=1")

    if [[ -n "$response" && "$response" != "null" ]]; then
        # Create cache directory and save response
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] fetch_weather_data:${LINENO}: valid api data received from open-meteo" >>"$LOG_FILE"

        mkdir -p "$(dirname "$CACHE_FILE")"
        echo "$response" >"$CACHE_FILE"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] API data refreshed, API cost: ${api_count}" >&2
    fi

    echo "$response"
}

# Check dependencies
check_dependencies() {
    for cmd in curl jq bc; do
        if ! command -v "$cmd" &>/dev/null; then
            echo "{\"text\":\" Missing $cmd\",\"class\":\"error\"}"
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] ${LINENO}: one or more dependencies(curl, jq, bc) missing" >>"$LOG_FILE"
            exit 0
        fi
    done
}
