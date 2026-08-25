#!/usr/bin/env bash

# 1. Start the awww daemon
awww-daemon &

# 2. Restore the wallpaper image
waypaper --restore &

# 3. Get the current wallpaper path from waypaper's config
WALLPAPER=$(grep "wallpaper =" ~/.config/waypaper/config.ini | cut -d '=' -f2 | xargs)

# 4. If the wallpaper file exists, run wallust on it
if [ -f "$WALLPAPER" ]; then
    wallust run "$WALLPAPER"
fi#!/usr/bin/env bash

# 1. Start the awww daemon
awww-daemon &

# 2. Restore the wallpaper image
waypaper --restore &

# 3. Get the current wallpaper path from waypaper's config
WALLPAPER=$(grep "wallpaper =" ~/.config/waypaper/config.ini | cut -d '=' -f2 | xargs)

# 4. If the wallpaper file exists, run wallust on it
if [ -f "$WALLPAPER" ]; then
    wallust run "$WALLPAPER"
fi
