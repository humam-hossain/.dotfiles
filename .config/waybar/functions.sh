LATITUDE=23.758492
LONGITUDE=90.390055
CACHE_DURATION=900 # 15 minutes
PER_API_CALL_COST=1.6
CACHE_FILE="$HOME/.config/waybar/api_response.json"
API_COUNT_FILE="$HOME/.config/waybar/api_count.txt"
API_HISTORY_FILE="$HOME/.config/waybar/api_history.csv"

# --- CATPPUCCIN MOCHA PALETTE ---
C_TEXT="#cdd6f4"
C_RED="#f38ba8"
C_GREEN="#a6e3a1"
C_YELLOW="#f9e2af"
C_BLUE="#89b4fa"
C_SAPPHIRE="#74c7ec"
C_SKY="#89dceb"
C_PEACH="#fab387"
C_LAVENDER="#b4befe"

# Function to get weather text description
get_weather_text() {
    local weather_code="$1"
    # (Text logic remains the same, omitted for brevity)
    # ... keep your existing case statement for text ...
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
    echo "$weather_text"
}

# Function to get weather icon (Fixed Colors)
get_weather_icon() {
    local weather_code="$1"
    local is_day="$2"
    local weather_icon weather_color

    if [[ "$is_day" == 1 ]]; then
        case "$weather_code" in
        2 | 3)
            weather_icon="⛅"
            weather_color="$C_SKY" ;;
        45 | 48)
            weather_icon="󰖑"
            weather_color="$C_LAVENDER" ;;
        51 | 53 | 55 | 56 | 57 | 61 | 63 | 65 | 66 | 67 | 80 | 81 | 82)
            weather_icon="🌧️"
            weather_color="$C_SAPPHIRE" ;;
        71 | 73 | 75 | 77 | 85 | 86)
            weather_icon="❄️"
            weather_color="$C_TEXT" ;;
        95 | 96 | 99)
            weather_icon="⛈️"
            weather_color="$C_RED" ;;
        *)
            weather_icon="☀️"
            weather_color="$C_YELLOW" ;;
        esac
    else
        case "$weather_code" in
        2 | 3)
            weather_icon="☁️"
            weather_color="$C_TEXT" ;;
        45 | 48)
            weather_icon="󰖑"
            weather_color="$C_LAVENDER" ;;
        51 | 53 | 55 | 56 | 57 | 61 | 63 | 65 | 66 | 67 | 80 | 81 | 82)
            weather_icon="🌧️"
            weather_color="$C_SAPPHIRE" ;;
        95 | 96 | 99)
            weather_icon="⛈️"
            weather_color="$C_RED" ;;
        *)
            weather_icon="󰖔"
            weather_color="$C_LAVENDER" ;;
        esac
    fi
    echo "<span color='${weather_color}' size='12000'>${weather_icon}</span>"
}

# Get temperature display (Fixed Colors)
get_temp_display() {
    local temp_2m="$1"
    local apparent_temp="$2"
    local curr_temp_2m="$3"
    local curr_apparent_temp="$4"
    local temp_display temp_color diff_temp curr_diff_temp_2m

    diff_temp=$(echo "$apparent_temp - $temp_2m" | bc)
    curr_diff_temp_2m=$(echo "$temp_2m - $curr_temp_2m" | bc)

    temp_display="<span size='11000'>🌡️</span> "

    # Trend Arrows
    if (($(echo "$curr_diff_temp_2m > 0" | bc))); then
        temp_display+="<span color='$C_RED' size='12000'>󰁞</span>"
    elif (($(echo "$curr_diff_temp_2m < 0" | bc))); then
        temp_display+="<span color='$C_GREEN' size='12000'>󰁆</span>"
    fi

    temp_display+="${temp_2m}°C"

    # Feels Like
    formatted_diff=$(printf "%.1f" "$diff_temp")
    temp_display+="[${formatted_diff}]"

    # Color Logic
    if (($(echo "$temp_2m < 15" | bc))); then
        temp_color="$C_SAPPHIRE" # Cold
    elif (($(echo "$temp_2m < 20" | bc))); then
        temp_color="$C_SKY"      # Cool
    elif (($(echo "$temp_2m < 30" | bc))); then
        temp_color="$C_GREEN"    # Comfortable
    else
        temp_color="$C_PEACH"    # Hot
    fi

    echo "<span color='${temp_color}'>${temp_display}</span>"
}

# Get humidity display (Fixed Colors)
get_humidity_display() {
    local next_humidity="$1"
    local curr_humidity="$2"
    local diff_humidity display

    diff_humidity=$(echo "$next_humidity - $curr_humidity" | bc)
    display="<span size='11000'>💧</span>"

    if (($(echo "$diff_humidity > 0" | bc))); then
        display+="<span color='$C_RED' size='12000'>󰁞</span>"
    elif (($(echo "$diff_humidity < 0" | bc))); then
        display+="<span color='$C_GREEN' size='12000'>󰁆</span>"
    fi
    display+="${next_humidity}%"

    # Humidity is always Blue/Sky in standard themes
    echo "<span color='$C_BLUE'>${display}</span>"
}

# Get pressure display (Fixed Colors)
get_pressure_display() {
    local next_pressure="$1"
    local curr_pressure="$2"
    local diff_pressure display

    diff_pressure=$(echo "$next_pressure - $curr_pressure" | bc)
    display="<span size='11000'>󰡴</span> "

    if (($(echo "$diff_pressure > 0" | bc))); then
        display+="<span color='$C_RED' size='12000'>󰁞</span>"
    elif (($(echo "$diff_pressure < 0" | bc))); then
        display+="<span color='$C_GREEN' size='12000'>󰁆</span>"
    fi
    display+="${next_pressure}atm"

    echo "<span color='$C_YELLOW'>${display}</span>"
}

# Get precipitation display (Fixed Colors)
get_precipitation_display() {
    local precipitation="$1"
    # Use Sapphire for rain/water
    echo "<span color='$C_SAPPHIRE'><span size='12000'>☔</span> ${precipitation}mm</span>"
}

# Get sun times (Fixed Colors)
get_sun_times_display() {
    local sunrise_time="$1"
    local sunset_time="$2"
    
    # Sunrise = Yellow, Sunset = Lavender
    local sunrise_text="<span color='$C_YELLOW'><span size='12000'></span> ${sunrise_time}</span>"
    local sunset_text="<span color='$C_LAVENDER'><span size='12000'></span> ${sunset_time}</span>"

    echo "${sunrise_text} ${sunset_text}"
}

# Get visibility display (Fixed Colors)
get_visibility_display() {
    local next_visibility="$1"
    local display color icon="󰈈"

    if (($(echo "$next_visibility < 2" | bc))); then
        icon="󰈉"
        color="$C_RED" # Poor
    elif (($(echo "$next_visibility < 10" | bc))); then
        color="$C_YELLOW" # Moderate
    else
        color="$C_GREEN" # Good
    fi

    display="<span size='12000'>${icon}</span> ${next_visibility}km"
    echo "<span color='${color}'>${display}</span>"
}

# --- DEPENDENCY CHECK & FETCH FUNCTIONS (Keep these as they were) ---
# (Paste the rest of your fetch_weather_data and check_dependencies functions here unchanged)
# ...
fetch_weather_data() {
    local response

    # api count file
    mkdir -p "$(dirname "$API_COUNT_FILE")"
    if [[ -f "$API_COUNT_FILE" ]]; then
        api_count=$(cat "$API_COUNT_FILE")
    else
        api_count=0
    fi

    # check if api history file exists
    # Get current date in YYYY-MM-DD format
    real_datetime=$(date +%Y-%m-%d)
    last_datetime=""
    if [[ ! -f "$API_HISTORY_FILE" ]]; then
        mkdir -p "$(dirname "$API_HISTORY_FILE")"
        echo "date,api_calls" >>"$API_HISTORY_FILE"
        echo "${real_datetime},0" >>"$API_HISTORY_FILE"
    fi

    # Find the last datetime and api_calls in the API_HISTORY_FILE
    last_line=$(tail -n 1 "$API_HISTORY_FILE")
    if [[ "$last_line" =~ ^([0-9]{4}-[0-9]{2}-[0-9]{2}),([0-9.]+) ]]; then
        last_datetime="${BASH_REMATCH[1]}"
        last_api_calls="${BASH_REMATCH[2]}"
    fi

    if [[ "$real_datetime" != "$last_datetime" && -n "$last_datetime" ]]; then
        sed -i '$d' "$API_HISTORY_FILE"
        echo "${last_datetime},${api_count}" >>"$API_HISTORY_FILE"
        api_count=0
        echo "$api_count" >"$API_COUNT_FILE"
        echo "${real_datetime},0" >>"$API_HISTORY_FILE"
    fi

    if [[ -f "$CACHE_FILE" ]]; then
        response=$(cat "$CACHE_FILE")
        local curr_datetime=$(jq -r '.current.time' <<<"$response")
        local real_datetime=$(date +'%Y-%m-%dT%H:%M')
        local real_sec=$(date -d "$real_datetime" +%s)
        local curr_sec=$(date -d "$curr_datetime" +%s)

        if ((real_sec - curr_sec <= CACHE_DURATION)); then
            echo "$response"
            return
        fi
    fi

    api_count=$(echo "$api_count + ${PER_API_CALL_COST}" | bc)
    echo "$api_count" >"$API_COUNT_FILE"

    response=$(curl -s \
        "https://api.open-meteo.com/v1/forecast?latitude=${LATITUDE}&longitude=${LONGITUDE}&daily=sunrise,sunset&hourly=weather_code,temperature_2m,apparent_temperature,relative_humidity_2m,precipitation,precipitation_probability,visibility,surface_pressure&current=is_day,weather_code,apparent_temperature,temperature_2m,relative_humidity_2m,surface_pressure,precipitation&timezone=auto&temperature_unit=celsius&forecast_days=1")

    if [[ -n "$response" && "$response" != "null" ]]; then
        mkdir -p "$(dirname "$CACHE_FILE")"
        echo "$response" >"$CACHE_FILE"
    fi
    echo "$response"
}

check_dependencies() {
    for cmd in curl jq bc; do
        if ! command -v "$cmd" &>/dev/null; then
            echo "{\"text\":\" Missing $cmd\",\"class\":\"error\"}"
            exit 0
        fi
    done
}
