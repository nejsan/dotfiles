#!/usr/bin/env bash

# Configures OS X to the way I like it.
# This is entirely my own taste, but may be useful for
# other people who are interested in automating their own setup.

echo "Configuring system settings!"

########################################
# Initial Setup Setup
########################################

# Ask for the administrator password upfront
sudo -v

# Keep-alive: update existing `sudo` time stamp until `.osx` has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &



########################################
# Homebrew & Cask
########################################
echo "Installing Homebrew..."

# Install Homebrew for package management
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"



echo "Done"
########################################
# Software Installation
########################################
echo "Installating software..."

brew install \
  bash \
  bash-completion \
  ctags \
  caskroom/cask/brew-cask \
  dialog \
  git

brew cask install \
  vagrant \
  virtualbox

# Set Homebrew's bash as the default shell
echo /usr/local/bin/bash | sudo tee -a /etc/shells &> /dev/null
sudo chsh -s /usr/local/bin/bash &> /dev/null



echo "Done"
########################################
# System Preferences
########################################
echo "Configuring system preferences..."

# Set the computer's name and hostname
NEW_HOSTNAME="Kopparberg"
sudo scutil --set ComputerName $NEW_HOSTNAME
sudo scutil --set LocalHostName $NEW_HOSTNAME
sudo scutil --set HostName $NEW_HOSTNAME

# Set highlight color to pink
defaults write NSGlobalDomain AppleHighlightColor -string "1.000000 0.749020 0.823529"

# Jump to the spot that's clicked on the scroll bar
defaults write NSGlobalDomain AppleScrollerPagingBehavior -int 1

# Never start the screensaver
defaults write com.apple.screensaver idleTime 0

# Use a 24 hour clock
defaults write NSGlobalDomain AppleICUForce24HourTime -bool true

# Put the display to sleep after 8 minutes on battery
sudo pmset -b displaysleep 8

# Expand save and print panels by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

# Save to disk (not to iCloud) by default
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# Play a feedback sound when adjusting volume
defaults write NSGlobalDomain com.apple.sound.beep.feedback -int 1

# Trackpad: enable tap to click for this user and for the login screen
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Trackpad: use four finger horizontal swipe to move between fullscreen apps
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerHorizSwipeGesture -int 0
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadFourFingerHorizSwipeGesture -int 2

# Trackpad: use four finger vertical swipe for mission control
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerVertSwipeGesture -int 0
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadFourFingerVertSwipeGesture -int 2


# Use scroll gesture with the Ctrl (^) modifier key to zoom
defaults write com.apple.universalaccess closeViewScrollWheelToggle -bool true
defaults write com.apple.universalaccess HIDScrollZoomModifierMask -int 262144

# Require password immediately after sleep or screen saver begins
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

# Hide icons for hard drives, servers, and removable media on the desktop
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool false
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool false
defaults write com.apple.finder ShowMountedServersOnDesktop -bool false
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool false

# Automatically hide and show the Dock
defaults write com.apple.dock autohide -bool true



echo "Done"
########################################
# Git
########################################
echo "Configuring Git..."

# Fixes an issue with tracking files with unicode in their name
git config --global core.precomposeunicode true



echo "Done"
########################################
# Safari
########################################
echo "Configuring Safari..."

# Enable the Develop menu and the Web Inspector in Safari
defaults write com.apple.Safari IncludeDevelopMenu -bool true



echo "Done"
########################################
# Terminal.app
########################################
echo "Configuring Terminal..."

# Use UTF-8
defaults write com.apple.terminal StringEncodings -array 4

# Use my own custom theme
TERM_PROFILE='inuBASHiri Dark Plain';
CURRENT_PROFILE="$(defaults read com.apple.terminal 'Default Window Settings')";
FONT='Meslo LG S Regular for Powerline.otf';
TMP_DIR="${HOME}/osx-setup-tmp";
if [ "${CURRENT_PROFILE}" != "${TERM_PROFILE}" ]; then
	mkdir -p $TMP_DIR

	# Install the necessary font
	curl -L https://github.com/powerline/fonts/raw/master/Meslo/Meslo%20LG%20S%20Regular%20for%20Powerline.otf -o "${HOME}/Library/Fonts/${FONT}" &> /dev/null

	curl -L https://raw.githubusercontent.com/nejsan/dotfiles/master/osx/terminal-themes/inuBASHiri%20Dark%20Plain.terminal -o "${TMP_DIR}/${TERM_PROFILE}.terminal" &> /dev/null
	open "${TMP_DIR}/${TERM_PROFILE}.terminal";
	sleep 1; # Wait a bit to make sure the theme is loaded

	curl -L https://raw.githubusercontent.com/nejsan/dotfiles/master/osx/terminal-themes/inuBASHiri%20Plain.terminal -o "${TMP_DIR}/inuBASHiri Plain.terminal" &> /dev/null
	open "${TMP_DIR}/inuBASHiri Plain.terminal";
	sleep 1; # Wait a bit to make sure the theme is loaded

	rm -rf $TMP_DIR

	defaults write com.apple.terminal 'Default Window Settings' -string "${TERM_PROFILE}";
	defaults write com.apple.terminal 'Startup Window Settings' -string "${TERM_PROFILE}";
fi;



echo "Done"
########################################
# TextEdit
########################################
echo "Configuring TextEdit..."

# Use plain text mode for new TextEdit documents
defaults write com.apple.TextEdit RichText -int 0

# Open and save files as UTF-8 in TextEdit
defaults write com.apple.TextEdit PlainTextEncoding -int 4
defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4



echo "Done"
########################################
# Messages
########################################
echo "Configuring Messages..."

# Disable automatic emoji substitution (i.e. use plain text smileys)
defaults write com.apple.messageshelper.MessageController SOInputLineSettings -dict-add "automaticEmojiSubstitutionEnablediMessage" -bool false



echo "Done"
########################################
# Powerline
########################################
echo "Installing Powerline..."

sudo easy_install pip
pip install --user powerline-status



echo "Done"
########################################
# OS X Software Update
########################################
echo "Opening OS X Software Update..."

# Open the App Store's software update page to check for new updates
open -a "Software Update"

echo "Done"
echo "Enjoy the system!"
echo "You should reboot to apply these changes"