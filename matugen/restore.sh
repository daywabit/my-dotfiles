#!/usr/bin/env bash
SAVED_WALL="$HOME/.cache/current_wallpaper"

if [ -f "$SAVED_WALL" ]; then
    WALL_PATH=$(cat "$SAVED_WALL")
    if [ -f "$WALL_PATH" ]; then
        feh --bg-fill "$WALL_PATH"
    fi
fi
