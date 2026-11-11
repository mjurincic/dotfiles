#!/bin/bash
# Ask for the admin password once, then keep sudo's timestamp fresh until chezmoi exits,
# so the rest of the install (Homebrew, casks) can run unattended.
# Nothing is stored: when chezmoi finishes, the keep-alive stops and sudo times out as usual.
sudo -v || exit 1
CHEZMOI_PID=$PPID
( while kill -0 "$CHEZMOI_PID" 2>/dev/null; do sudo -n true; sleep 50; done ) >/dev/null 2>&1 &
