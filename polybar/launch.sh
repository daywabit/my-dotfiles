#!/usr/bin/env bash

# Terminate already running bar instances
killall -q polybar

# Wait until processes shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Launch Polybar
polybar example &
