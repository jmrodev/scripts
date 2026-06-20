#!/usr/bin/env bash

# Fetch unread notifications
NOTIFS_JSON=$(gh api notifications --cache 0s 2>/dev/null)
if [ $? -ne 0 ] || [ -z "$NOTIFS_JSON" ]; then
    NOTIFS_JSON="[]"
fi

OUTPUT=$(echo "$NOTIFS_JSON" | jq -c '
    if type == "array" then
        length as $count |
        {
            text: ($count | tostring),
            tooltip: ("Notificaciones de GitHub (" + ($count | tostring) + "):\n" + (.[0:5] | map("• \(.subject.title) (\(.repository.full_name))" | gsub("&"; "&amp;") | gsub("<"; "&lt;") | gsub(">"; "&gt;")) | join("\n")) + (if $count > 5 then "\n..." else "" end)),
            class: (if $count > 0 then "unread" else "read" end)
        }
    else
        {text: "0", tooltip: "Sin notificaciones"}
    end')

echo "$OUTPUT"
echo "$(date): $OUTPUT" >> /tmp/gh_waybar.log
