#!/usr/bin/env bash
# Sets up a system to my preferences using dialog screens.
#
# Author: Kate Hart (https://github.com/codehearts)
# Depends: setdown.sh, sudo

# Get root of dotfiles repo
declare -r REPO_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
declare -r SHARED_DIR="$REPO_DIR/general"
declare -r LINUX_DIR="$REPO_DIR/linux"
declare -r MACOS_DIR="$REPO_DIR/osx"

# Print usage info
usage() {
  cat <<-'HELP'
usage: katify [-h] [--arch|--macOS]

Set up a system with Katie's preferences.
Asks for packages to install and links dotfiles into place.
If run without a system flag, no packages are installed.

Options:
  -h, --help
        Show help options
  --arch
        Install packages for an Arch Linux system
  --macOS
        Install packages and set preferences for a macOS system
HELP
  exit
}

# Include setdown.sh
source "$REPO_DIR/setdown.sh"

# Packages to install
declare -a packages

#
# Process user input
#

if [ $# -ge 1 ]; then
  case "$1" in
    --arch)
      source $REPO_DIR/katify-arch.sh
      ;;
    --macos|--macOS)
      source $REPO_DIR/katify-macOS.sh
      ;;
    *)
      usage
      ;;
  esac
fi

#
# Install pypi packages if pip is installed
#

declare -a pip_packages

# Determines if a package is installed via pip
# if pip_haspkg flask; then echo "has flask"; fi
pip_haspkg() { pip show "$1" >/dev/null; }

# Adds a pip package choice to an array if the pip package is not installed
# pip_addpkg my_choices flask on
pip_addpkg() { local -n array=$1; pip_haspkg "$2" || array+=($2 $3); }

# Asks the user to select packages and adds them to the pip package array
# pip_getpkgs 'Select pip packages to install' my_choices
pip_getpkgs() {
  declare -a choices=$(setdown_getopts "$1" $2)
  pip_packages+=("${choices[@]}")
}

if setdown_hascmd pip; then
  declare -a pip_package_choices
  pip_addpkg pip_package_choices colorz on
  pip_addpkg pip_package_choices zenbu on

  pip_getpkgs 'Pypi packages to install' pip_package_choices

  if [ "${#pip_packages[@]}" -gt 0 ]; then
    setdown_putcmd pip install --user "${pip_packages[@]}"
  fi
fi

#
# Install gems if ruby is installed
#

declare -a ruby_gems

# Determines if a ruby gem is installed
# if ruby_hasgem compass; then echo "has compass"; fi
ruby_hasgem() { gem list -i "^$1$" >/dev/null; }

# Adds a gem choice to an array if the gem is not installed
# ruby_addgem my_choices compass on
ruby_addgem() { local -n array=$1; ruby_hasgem "$2" || array+=($2 $3); }

# Asks the user to select gems and adds them to the gem array
# ruby_getgems 'Select gems to install' my_choices
ruby_getgems() {
  declare -a choices=$(setdown_getopts "$1" $2)
  ruby_gems+=("${choices[@]}")
}

if setdown_hascmd gem; then
  declare -a ruby_gem_choices
  ruby_addgem ruby_gem_choices compass on

  ruby_getgems 'Gems to install' ruby_gem_choices

  if [ "${#ruby_gems[@]}" -gt 0 ]; then
    setdown_putcmd gem install "${ruby_gems[@]}"
  fi
fi

# 
# Ask which dotfiles to set up
#

# Adds a dotfiles choice to an array if the command exists
# dotfiles_addconfig my_choices bash on
dotfiles_addconfig() { local -n dots=$1; setdown_hascmd "$2" && dots+=($2 $3); }

declare -a dotfile_choices=('shell scripts' on)
dotfiles_addconfig dotfile_choices bash        on
dotfiles_addconfig dotfile_choices compton     on
dotfiles_addconfig dotfile_choices gcalert     on
dotfiles_addconfig dotfile_choices git         on
dotfiles_addconfig dotfile_choices lightdm     on
dotfiles_addconfig dotfile_choices mpd         on
dotfiles_addconfig dotfile_choices ncmpcpp     on
dotfiles_addconfig dotfile_choices offlineimap on
dotfiles_addconfig dotfile_choices screen      on
dotfiles_addconfig dotfile_choices tmux        on
dotfiles_addconfig dotfile_choices vim         on
dotfiles_addconfig dotfile_choices X           on
dotfiles_addconfig dotfile_choices zenbu       on
setdown_hascmd msmtp       && dotfile_choices+=('msmtp templates'       off)
setdown_hascmd mutt        && dotfile_choices+=('mutt templates'        off)
setdown_hascmd offlineimap && dotfile_choices+=('offlineimap templates' off)
 
declare -a choices=$(setdown_getopts 'Dotfiles to set up' dotfile_choices)
for choice in "${choices[@]}"; do
  case "$choice" in
    'shell scripts')
        for script in $LINUX_DIR/shell-scripts/*; do
          name="$(basename "$script")"

          # Don't ask for sudo and copy if the files are the same
          if [ "$(cat /usr/local/sbin/"$name")" != "$(cat "$script")" ]; then
            if setdown_sudo 'Enter password to copy shell scripts'; then
              setdown_sudo_copy "$script" /usr/local/sbin/
            else
              setdown_putstr_ok 'Skipping shell script copy'
              break
            fi
          fi
        done
      ;;
    bash)
      setdown_link $SHARED_DIR/bashrc ~/.bashrc
      setdown_link $SHARED_DIR/bash_profile ~/.bash_profile
      ;;
    compton)
      setdown_link $LINUX_DIR/compton.conf ~/.compton.conf
      ;;
    gcalert)
      mkdir -p ~/.config/gcalertrc/
      setdown_link $LINUX_DIR/config/gcalert/gcalertrc ~/.config/gcalertrc/
      ;;
    git)
      setdown_link $SHARED_DIR/gitignore ~/.gitignore
      git config --global core.precomposeunicode true
      git config --global core.excludesfile ~/.gitignore
      git config --global core.editor vim
      if ! git config --global user.name; then
        git config --global user.name \
          "$(setdown_getstr 'Git name:' 'Kate Hart')"
      fi
      if ! git config --global user.email; then
        git config --global user.email \
          "$(setdown_getstr 'Git email:' 'codehearts@users.noreply.github.com')"
      fi
      ;;
    lightdm)
      if setdown_hascmd systemctl; then
        if [ "$(systemctl is-enabled lightdm)" != "enabled" ]; then
          if setdown_sudo 'Enter password to enable lightdm'; then
            sudo systemctl enable lightdm.service
          else
            setdown_putstr_ok 'Skipping lightdm service enable'
          fi
        fi
      fi
      ;;
    mpd)
      mkdir -p ~/.mpd/playlists
      mkdir -p ~/.mpd/tmp
      touch ~/.mpd/{database,log,pid,state}
      setdown_link $SHARED_DIR/mpd.conf ~/.mpd/
      ;;
    ncmpcpp)
      mkdir -p ~/.ncmpcpp
      setdown_link $SHARED_DIR/ncmpcpp/config ~/.ncmpcpp/
      setdown_link $SHARED_DIR/ncmpcpp/keys ~/.ncmpcpp/
      ;;
    offlineimap)
      if setdown_hascmd systemctl; then
        mkdir -p ~/.config/systemd/user/
        setdown_copy $LINUX_DIR/config/systemd/user/offlineimap.service \
          ~/.config/systemd/user/
        setdown_copy $LINUX_DIR/config/systemd/user/offlineimap.timer \
          ~/.config/systemd/user/

        systemctl --user daemon-reload
        systemctl --user start offlineimap.timer
        systemctl --user start offlineimap.service
        systemctl --user enable offlineimap.timer
        systemctl --user enable offlineimap.service
      fi
      ;;
    screen)
      setdown_link $SHARED_DIR/screenrc ~/.screenrc
      ;;
    tmux)
      setdown_link $SHARED_DIR/tmux.conf ~/.tmux.conf
      ;;
    vim)
      mkdir -p ~/.vim/autoload/
      setdown_link $SHARED_DIR/vimrc ~/.vimrc
      setdown_copy $SHARED_DIR/vim/autoload/plug.vim ~/.vim/autoload/
      ;;
    X)
      setdown_link $LINUX_DIR/xinitrc ~/.xinitrc
      ;;
    zenbu)
      setdown_link $LINUX_DIR/config/zenbu/ ~/.config/
      if setdown_hasstr pip_packages zenbu; then
        zenbu soft-pink
        setdown_hascmd reload-desktop && reload-desktop
      fi
      ;;
    'msmtp templates')
      mkdir -p ~/.msmtp
      setdown_copy $REPO_DIR/msmtprc-sample ~/.msmtprc-sample
      setdown_link $SHARED_DIR/msmtp/msmtp-gnome-tool.py ~/.msmtp/
      ;;
    'mutt templates')
      mkdir -p ~/.mutt
      setdown_copy $SHARED_DIR/muttrc-sample ~/.muttrc-sample
      setdown_copy $SHARED_DIR/mutt/custom_config ~/.mutt/
      setdown_copy $SHARED_DIR/mutt/school_config ~/.mutt/
      setdown_copy $SHARED_DIR/mutt/gmail_config ~/.mutt/
      setdown_copy $SHARED_DIR/mutt/mailcap-sample ~/.mutt/
      setdown_link $SHARED_DIR/mutt/add_sender_to_aliases.sh ~/.mutt/
      setdown_link $SHARED_DIR/mutt/loveless-theme ~/.mutt/
      ;;
    'offlineimap templates')
      setdown_copy $SHARED_DIR/offlineimaprc-sample ~/.offlineimaprc-sample
      setdown_link $SHARED_DIR/offlineimap.py ~/.offlineimap.py
      ;;
  esac
done

setdown_putstr_ok "Setup complete!"
clear
