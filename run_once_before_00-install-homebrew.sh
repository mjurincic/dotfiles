#!/bin/bash
set -euo pipefail
if ! command -v brew >/dev/null && [ ! -x /opt/homebrew/bin/brew ]; then
  # Download first, so a failed download stops here instead of running a partial script.
  # NONINTERACTIVE skips the "Press RETURN" prompt; sudo was already unlocked by 00-0-sudo-keepalive
  installer="$(mktemp)"
  curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o "$installer"
  NONINTERACTIVE=1 /bin/bash "$installer"
  rm -f "$installer"
fi
