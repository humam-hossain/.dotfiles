#!/bin/bash

echo "Fetching repository list from GitHub..."
# Fetch the list once and store it in a variable
REPOS=$(gh repo list --limit 1000 --json nameWithOwner,name --jq '.[] | "\(.nameWithOwner) \(.name)"')

# Check if the list is empty to prevent errors
if [ -z "$REPOS" ]; then
    echo "No repositories found."
    exit 0
fi

# Count the total number of lines (repositories)
TOTAL_REPOS=$(echo "$REPOS" | wc -l)
CURRENT=0

# Loop through the stored list
while read -r repo dir; do
  ((CURRENT++))
  
  if [ ! -d "$dir" ]; then
    echo "[$CURRENT/$TOTAL_REPOS] Cloning $repo..."
    # Clone and send a success notification
    gh repo clone "$repo" && notify-send -t 1000 "GitHub Clone [$CURRENT/$TOTAL_REPOS]" "Successfully cloned $repo"
  else
    echo "[$CURRENT/$TOTAL_REPOS] Skipping $dir (already exists)"
    # Send a skipped notification
    notify-send -t 1000 "GitHub Clone [$CURRENT/$TOTAL_REPOS]" "Skipped $repo (Already exists)"
  fi
  
done <<< "$REPOS"

# Final notification that stays on the screen
notify-send -u critical "GitHub Clone Complete" "Finished checking and cloning $TOTAL_REPOS repositories."
