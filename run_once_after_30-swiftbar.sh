#!/bin/bash
# Point SwiftBar at the plugins managed by chezmoi, add it to login items so
# the menu bar weather comes back after a quit or reboot, then start it
defaults write com.ameba.SwiftBar PluginDirectory "$HOME/.config/swiftbar"
osascript -e 'tell application "System Events" to if not (exists login item "SwiftBar") then make login item at end with properties {path:"/Applications/SwiftBar.app", hidden:false}' >/dev/null 2>&1 || true
open -a SwiftBar 2>/dev/null || true
