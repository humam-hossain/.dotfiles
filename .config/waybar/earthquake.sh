#!/usr/bin/env bash

# Bangladesh Region (Lat 20-27, Lon 88-93)
# We check the last 48 hours for ANY activity > 2.0
REGION="&minlat=20&maxlat=27&minlon=88&maxlon=93"
LIMIT=1
MIN_MAG=2.0

# Fetch data
data=$(curl -s "https://www.seismicportal.eu/fdsnws/event/1/query?format=json&limit=${LIMIT}&orderby=time&minmag=${MIN_MAG}${REGION}")

# Check if data exists
if [[ -z "$data" || $(echo "$data" | jq '.features | length') -eq 0 ]]; then
    # STATUS: QUIET
    # This acts as your "Forecast": No recent signs of instability
    echo "{\"text\": \"  Quiet\", \"tooltip\": \"No earthquakes >${MIN_MAG} in BD (Last 48h)\", \"class\": \"safe\"}"
    exit 0
fi

# If there IS an earthquake, show it
props=$(echo "$data" | jq '.features[0].properties')
mag=$(echo "$props" | jq -r '.mag')
place=$(echo "$props" | jq -r '.flynn_region')
time_utc=$(echo "$props" | jq -r '.time')

# Convert time to Dhaka time
local_time=$(TZ='Asia/Dhaka' date -d "$time_utc" +'%d %b %I:%M%p')

# Calculate how long ago it was
event_ts=$(date -d "$time_utc" +%s)
now_ts=$(date +%s)
diff_hours=$(( (now_ts - event_ts) / 3600 ))

# Determine Status Icon based on recency
if (( diff_hours < 12 )); then
    status_icon="  ALERT" # Recent (<12h)
    css_class="danger"
else
    status_icon="  Activity" # Older (>12h)
    css_class="warning"
fi

echo "{\"text\": \"${status_icon}: M${mag}\", \"tooltip\": \"Location: ${place}\nTime: ${local_time} (${diff_hours}h ago)\nDepth: $(echo "$props" | jq -r '.depth')km\", \"class\": \"${css_class}\"}"
