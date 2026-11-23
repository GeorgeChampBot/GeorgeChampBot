#!/bin/sh
# Upgrade yt-dlp before every start. YouTube regularly breaks older yt-dlp releases, so a container
# restart (manual, the weekly cron in README.md, or after a reboot) is enough to pick up a fix.
# A failed upgrade (e.g. PyPI unreachable) is not fatal: the bot starts on the version already installed.
pip3 install --no-cache-dir --quiet --upgrade "yt-dlp[default]" \
    || echo "docker-entrypoint: yt-dlp upgrade failed, continuing with the installed version" >&2
echo "docker-entrypoint: yt-dlp $(python3 -m yt_dlp --version)"

exec "$@"
