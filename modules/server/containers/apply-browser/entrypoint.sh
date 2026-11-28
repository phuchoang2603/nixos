#!/bin/sh
set -eu

export DISPLAY=:1

Xvnc "$DISPLAY" -geometry 1440x900 -depth 24 -SecurityTypes None -localhost yes -rfbport 5900 &
while [ ! -S /tmp/.X11-unix/X1 ]; do sleep 0.2; done

websockify --web /usr/share/novnc 6080 127.0.0.1:5900 &
socat TCP-LISTEN:9222,fork,reuseaddr TCP:127.0.0.1:9221 &

rm -f /profile/SingletonLock /profile/SingletonCookie /profile/SingletonSocket

exec google-chrome-stable \
    --user-data-dir=/profile \
    --remote-debugging-port=9221 \
    --no-sandbox \
    --no-first-run \
    --no-default-browser-check \
    --window-position=0,0 \
    --window-size=1440,900 \
    about:blank
