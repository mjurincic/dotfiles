#!/bin/bash
# Point SwiftBar at the plugins managed by chezmoi, then start it
defaults write com.ameba.SwiftBar PluginDirectory "$HOME/.config/swiftbar"
open -a SwiftBar 2>/dev/null || true
