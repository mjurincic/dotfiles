#!/bin/bash
# macOS preferences. Runs again whenever this file changes, so edit a line and run `chezmoi apply`.
# To undo a setting: `defaults delete <domain> <key>` and log out and back in.
set -e

# --- Scrolling, trackpad, mouse ---
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false              # natural scrolling off (log out to apply)
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true                  # tap to click
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# --- Keyboard and typing (good for coding) ---
defaults write NSGlobalDomain KeyRepeat -int 2                                        # fast key repeat
defaults write NSGlobalDomain InitialKeyRepeat -int 15                                # short delay before repeat
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false                    # hold a key to repeat, not the accent popup
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false        # no autocorrect
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false        # no "." on double space
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false         # straight quotes
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false          # no -- to em dash
defaults write NSGlobalDomain AppleKeyboardUIMode -int 2                              # Tab moves between all controls

# --- Finder ---
defaults write NSGlobalDomain AppleShowAllExtensions -bool true                       # show file extensions
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"                   # list view
defaults write com.apple.finder _FXSortFoldersFirst -bool true                        # folders on top
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"                   # search the current folder
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
defaults write com.apple.finder NewWindowTarget -string "PfHm"                        # new windows open your home folder
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true          # no .DS_Store on network drives
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true              # ...or USB drives

# --- Dock ---
defaults write com.apple.dock show-recents -bool false                                # no recent apps in the Dock
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock mru-spaces -bool false                                  # keep Spaces in a fixed order

# --- Save and print dialogs ---
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true           # expanded save dialog
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false           # save to disk, not iCloud, by default

killall Finder Dock SystemUIServer 2>/dev/null || true
echo "macOS defaults applied. Log out and back in for scrolling and keyboard changes."
