#!/bin/bash
# Security checks. Warns about anything that's off; changes nothing on its own.
# Little Snitch (in the Brewfile) handles outgoing connections. To also block unwanted
# incoming ones with the built-in firewall, uncomment the line at the bottom.

warn() { printf '\033[33m⚠ %s\033[0m\n' "$1"; }
ok()   { printf '✓ %s\n' "$1"; }

if fdesetup status | grep -q "FileVault is On"; then ok "FileVault disk encryption is on"
else warn "FileVault is OFF: turn it on in System Settings → Privacy & Security → FileVault"; fi

if spctl --status 2>/dev/null | grep -q "assessments enabled"; then ok "Gatekeeper is on"
else warn "Gatekeeper is OFF: run 'sudo spctl --global-enable'"; fi

if csrutil status 2>/dev/null | grep -q "enabled"; then ok "System Integrity Protection is on"
else warn "System Integrity Protection is OFF"; fi

if [ -d "/Applications/Little Snitch.app" ]; then ok "Little Snitch is installed (open it once to approve its network extension)"
else warn "Little Snitch is not installed yet"; fi

# Built-in (incoming) firewall, works alongside Little Snitch:
# sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
exit 0
