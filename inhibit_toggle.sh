#!/usr/bin/env bash

if pgrep -x systemd-inhibit >/dev/null; then
    pkill -x systemd-inhibit
else
    systemd-inhibit --what=idle --who=swayidle-inhibit --why=commanded --mode=block sleep 31536000 &
fi

# Send signal to waybar to refresh the idle inhibitor status
waybar-signal idle 2>/dev/null || pkill -RTMIN+15 waybar || true
