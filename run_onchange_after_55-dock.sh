#!/bin/bash
# A minimal Dock: Finder, then these apps, then Downloads on the right.
# Edit the list and run `chezmoi apply` to rebuild it. Apps you haven't installed are skipped.
set -e
APPS=(
  "/Applications/Google Chrome.app"
  "/Applications/Ghostty.app"
  "/Applications/WebStorm.app"
  "/Applications/Visual Studio Code.app"
  "/Applications/Claude.app"
  "/Applications/Slack.app"
)
DOCKUTIL=/opt/homebrew/bin/dockutil
[ -x "$DOCKUTIL" ] || { echo "dockutil missing, skipping Dock setup"; exit 0; }
"$DOCKUTIL" --remove all --no-restart >/dev/null
for app in "${APPS[@]}"; do
  [ -d "$app" ] && "$DOCKUTIL" --add "$app" --no-restart >/dev/null
done
"$DOCKUTIL" --add "$HOME/Downloads" --view grid --display stack --sort dateadded --no-restart >/dev/null
killall Dock
