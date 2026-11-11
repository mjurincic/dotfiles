#!/bin/bash
# Use Touch ID for sudo. /etc/pam.d/sudo_local survives macOS updates (Sonoma and later).
# To undo: sudo rm /etc/pam.d/sudo_local
set -e
F=/etc/pam.d/sudo_local
if ! grep -qs '^auth.*pam_tid.so' "$F"; then
  echo 'auth       sufficient     pam_tid.so' | sudo tee -a "$F" >/dev/null
  echo "Touch ID for sudo enabled."
fi
