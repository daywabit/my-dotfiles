#!/usr/bin/env bash
IMG_PATH="$1"

# Save current wallpaper path for session persistence
echo "$IMG_PATH" > "$HOME/.cache/current_wallpaper"

# Apply wallpaper
feh --bg-fill "$IMG_PATH"

# Run Matugen inside a fake PTY using native system python3
python3 -c "
import pty, os, time, subprocess, glob

img_path = '$IMG_PATH'
pid, fd = pty.fork()
if pid == 0:
    os.execlp('matugen', 'matugen', 'image', img_path, '-m', 'dark', '-t', 'scheme-content')
else:
    time.sleep(0.1)
    os.write(fd, b'\n')
    os.waitpid(pid, 0)

# Broadcast colors to ALL active Kitty socket endpoints
kitty_conf = '/home/daywa/.config/kitty/colors.conf'
for sock in glob.glob('/tmp/kitty*'):
    subprocess.run(['kitty', '@', '--to', f'unix:{sock}', 'set-colors', '-a', kitty_conf], stderr=subprocess.DEVNULL)
"
