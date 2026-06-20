#!/usr/bin/env bash

# Fetch updates using yay (which handles both official and AUR updates)
CACHE_FILE="/tmp/custom-checkupdates-$USER"
CACHE_TTL=300 # Cache for 5 minutes

get_updates() {
    if [ -f "$CACHE_FILE" ] && [ $(($(date +%s) - $(stat -c %Y "$CACHE_FILE"))) -lt $CACHE_TTL ]; then
        cat "$CACHE_FILE"
    else
        UPDATES=$(yay -Qu 2>/dev/null || true)
        echo "$UPDATES" > "$CACHE_FILE"
        echo "$UPDATES"
    fi
}

case $1'' in
'status')
    UPDATES=$(get_updates)
    COUNT=$(echo "$UPDATES" | grep -v '^$' | wc -l)
    TOOLTIP=$(echo "$UPDATES" | awk 1 ORS='\\n' | sed 's/\\n$//')
    jq -cn --arg count "$COUNT" --arg tooltip "$TOOLTIP" '{"text": $count, "tooltip": $tooltip}'
    ;;
'check')
    UPDATES=$(get_updates)
    COUNT=$(echo "$UPDATES" | grep -v '^$' | wc -l)
    [ $COUNT -gt 0 ]
    exit $?
    ;;
'upgrade')
    # Run update in a floating terminal overwriting the conflicting sway-session.target file
    swaymsg exec "foot --title=floating_shell yay -Syu --overwrite /usr/lib/systemd/user/sway-session.target"
    ;;
esac
