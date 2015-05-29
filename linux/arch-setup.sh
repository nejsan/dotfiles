#!/usr/bin/env bash

# Configures Arch Linux to the way I like it.
# This is entirely my own taste, but may be useful for
# other people who are interested in automating their own setup.

########################################
# Initial Setup
########################################

# Determine which directory this script is in
linux_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Include the utility script
. "$linux_dir/../scripts/utility.sh"

# Set our package manager command
pkg_mgr="sudo pacman"
is_command_installed yaourt
if $installed; then pkg_mgr=yaourt; fi

# List of packages to install
to_install=()

# Ask for the administrator password upfront
sudo -v

# Keep-alive: update existing `sudo` time stamp until this script has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Determines if the given package is installed
# $1: The name of the package to check for
# Sets $installed to true if it is
is_package_installed () {
	installed=true
	if [ -z "$($pkg_mgr -Qi $1 2>/dev/null)" ]; then
		installed=false
	fi
}

# Marks a given package for installation
# If the package is already installed, it will not be marked.
# $1: The name of the package
mark_for_installation () {
	to_install+=("$1")
}

########################################
# System Updates
########################################

echo "Performing system upgrade"

$pkg_mgr -Syu

########################################
# Dialog Software Install
########################################

is_command_installed whiptail
if ! $installed; then
	echo "Installing whiptail"

	$pkg_mgr -S libnewt
fi

# Include the dialog script
. "$linux_dir/../scripts/dialog.sh"
. "$linux_dir/../scripts/file_tools.sh"
source_prefix="linux"

########################################
# Yaourt
########################################

is_command_installed yaourt
if ! $installed; then
	yes_no "Install yaourt?"
	if $yes; then
		$pkg_mgr --noconfirm -S base-devel
		curl -O https://aur.archlinux.org/packages/pa/package-query/package-query.tar.gz
		tar zxvf package-query.tar.gz
		cd package-query
		makepkg -si
		cd ..
		curl -O https://aur.archlinux.org/packages/ya/yaourt/yaourt.tar.gz
		tar zxvf yaourt.tar.gz
		cd yaourt
		makepkg -si
		cd ..
		rm -rf yaourt* package-query*

		pkg_mgr=yaourt
	fi
fi

########################################
# CLI Software
########################################

packages=( bash-completion calc ctags dictd  gnome-keyring  htop      )
defaults=( "on"            "on" "on"  "on"   "on"           "on"      )
packages+=(mpd  msmtp mutt  ncmpcpp offlineimap python-pip python2-pip)
defaults+=("on" "on"  "off" "on"    "on"        "on"       "on"       )
packages+=(rfkill rsync texlive-core texlive-humanities               )
defaults+=("on"   "on"  "on"         "on"                             )
packages+=(texlive-pictures tmux unzip vagrant virtualbox             )
defaults+=("on"             "on" "on"  "on"    "on"                   )

# Add yaourt packages if yaourt was installed
if [ "$pkg_mgr" == "yaourt" ]; then
	packages+=(gcalcli mutt-sidebar urlview)
	defaults+=("on"    "on"         "on"   )
fi

checklist "Choose software to install:" packages[@] defaults[@]

# Process user choices
for choice in $choices; do
	choice=${packages[$choice]} # Get the name of the choice
	mark_for_installation $choice

	case $choice in
	virtualbox)
		# Install a related necessary package
		mark_for_installation virtualbox-guest-utils
	;;
	esac
done

########################################
# Graphical Software
########################################

yes_no "Install X server?"
if $yes; then

	########################################
	# X Server
	########################################

	clear
	mark_for_installation xorg-server
	mark_for_installation xf86-input-synaptics

	packages=( xfce4-panel xfce4-power-manager xfce4-session xfce4-settings)
	defaults=( "on"        "on"                "on"          "on"          )
	packages+=(xfce4-terminal xfdesktop xfwm4                              )
	defaults+=("on"           "off"     "off"                              )

	checklist "Choose XFCE components to install:" packages[@] defaults[@]

	# Process user choices
	panel_installed=false
	for choice in $choices; do
		choice=${packages[$choice]} # Get the name of the choice
		mark_for_installation $choice

		case $choice in
		xfce4-panel)
			panel_installed=true
			;;
		esac
	done

	# Allow the user to install XFCE Panel goodies
	if $panel_installed; then
		packages=( xfce4-mailwatch-plugin xfce4-weather-plugin xfce4-weather-plugin)
		defaults=( "on"                   "on"                 "on"                )
		packages+=(xfce4-whiskermenu-plugin                                        )
		defaults+=("on"                                                            )

		checklist "Choose XFCE panel goodies to install:" packages[@] defaults[@]

		# Process user choices
		for choice in $choices; do
			choice=${packages[$choice]} # Get the name of the choice
			mark_for_installation $choice
		done
	fi

	########################################
	# Graphical Software
	########################################

	packages=( accountsservice adobe-source-sans-pro-fonts chromium feh  firefox)
	defaults=( "on"            "on"                        "off"    "on" "on"   )
	packages+=(gvim lightdm-gtk-greeter rdesktop scrot slock tigervnc           )
	defaults+=("on" "off"               "on"     "on"  "on"  "on"               )
	packages+=(xmonad-contrib zathura-pdf-mupdf                                 )
	defaults+=("on"           "on"                                              )

	# Add yaourt packages if yaourt was installed
	if [ "$pkg_mgr" == "yaourt" ]; then
		packages+=(compton dropbox faba-mono-icons-git  gcalert google-chrome      )
		defaults+=("on"    "on"    "on"                 "on"    "off"              )
		packages+=(gtk-theme-iris-dark-git lightdm-webkit-theme-bevel-git mpdnotify)
		defaults+=("on"                    "on"                           "on"     )
	fi

	checklist "Choose graphical software to install:" packages[@] defaults[@]

	# Process user choices
	for choice in $choices; do
		choice=${packages[$choice]} # Get the name of the choice
		mark_for_installation $choice

		case $choice in
		faba-mono-icons-git)
			# The Moka set will fill in a lot of gaps in icon coverage
			mark_for_installation moka-icon-theme-git
		;;
		esac
	done
fi

########################################
# Package Installation
########################################

echo "Preparing to install..."
program_box "$($pkg_mgr --needed -S ${to_install[@]} >/dev/tty)" "Installing packages..."

# Post-installation
lightdm_service=false
for installed_package in "${to_install[@]}"; do
	package=${to_install[$installed_package]} # Get the name of the package

	case $installed_package in
	adobe-source-sans-pro-fonts)
		# Set this as the system font
		xfconf=`which xfconf-query`
		sudo xinit $xfconf --create --type=string -c xsettings -p /Gtk/FontName -s "Source Sans Pro 12"
	;;
	compton)
		# Set Compton to autostart
		ensure_dir_exists ~/.config/autostart
		declare -A compton_autostart
		compton_autostart['config/autostart/Compton.desktop']='.config/autostart/Compton.desktop'
		set_home_files_from_array compton_autostart
	;;
	dropbox)
		# Set Dropbox to autostart
		ensure_dir_exists ~/.config/autostart
		declare -A dropbox_autostart
		dropbox_autostart['config/autostart/dropbox.desktop']='.config/autostart/dropbox.desktop'
		set_home_files_from_array dropbox_autostart
	;;
	faba-mono-icons-git)
		# Set this as the default icon theme
		xfconf=`which xfconf-query`
		sudo xinit $xfconf --create --type=string -c xsettings -p /Net/IconThemeName -s "Faba-Mono"
	;;
	gcalert)
		# Set gcalert to autostart
		ensure_dir_exists ~/.config/autostart
		declare -A gcalert_autostart
		gcalert_autostart['config/autostart/Gcalert.desktop']='.config/autostart/Gcalert.desktop'
		set_home_files_from_array gcalert_autostart
	;;
	gtk-theme-iris-dark-git)
		# Set Iris Dark as the system theme
		xfconf=`which xfconf-query`
		sudo xinit $xfconf --create --type=string -c xsettings -p /Net/ThemeName -s "iris-dark"
	;;
	lightdm-gtk-greeter)
		lightdm_service=true
	;;
	lightdm-webkit-theme-bevel-git)
		# Set up the bevel theme
		uncomment_line_in_file "greeter-session=example-gtk-gnome" /etc/lightdm/lightdm.conf '#'
		replace_term_in_file 'example-gtk-gnome' 'lightdm-webkit-greeter' /etc/lightdm/lightdm.conf
		replace_term_in_file '#user-session=default' 'user-session=xfce' /etc/lightdm/lightdm.conf
		replace_term_in_file 'webkit-theme=webkit' 'webkit-theme=bevel' /etc/lightdm/lightdm-webkit*.conf
		lightdm_service=true
	;;
	xmonad-contrib)
		# Set Xmonad to autostart
		ensure_dir_exists ~/.config/autostart
		declare -A xmonad_autostart
		xmonad_autostart['config/autostart/Xmonad.desktop']='.config/autostart/Xmonad.desktop'
		set_home_files_from_array xmonad_autostart
	;;
	esac
done

if $lightdm_service; then
	sudo systemctl start lightdm.service

	if [ "$(sudo systemctl is-enabled lightdm.service)" != "enabled" ]; then
		sudo systemctl enable lightdm.service
	fi
fi

########################################
# Package Cleanup
########################################

# Only do this if there are orphans to remove
if [ -n "$($pkg_mgr -Qqtd)" ]; then
	program_box "$pkg_mgr -Rns $($pkg_mgr -Qqtd)" "Cleaning orphaned packages..."
fi

########################################
# Linux Software Configs
########################################

configs=( compton mpdnotify tint2 xfce4-terminal xmonad xprofile)
default=( "on"    "on"      "off" "on"           "on"   "on"    )

checklist "Choose Linux config files to set up:" configs[@] default[@]

# Process user choices
for choice in $choices; do
	choice=${configs[$choice]} # Get the name of the choice
	case $choice in
	compton)
		infobox "Linking compton files"

		declare -A compton_files
		compton_files['compton.conf']='.compton.conf'
		set_home_files_from_array compton_files
		;;
	mdpnotify)
		infobox "Linking mpdnotify files"

		ensure_dir_exists ~/.config/mpdnotify

		declare -A mpdnotify_files
		mpdnotify_files['config/mpdnotify/config']='.config/mpdnotify/config'
		mpdnotify_files['config/mpdnotify/nocover.png']='.config/mpdnotify/nocover.png'
		set_home_files_from_array mpdnotify_files
		;;
	tint2)
		infobox "Linking tint2 config"

		ensure_dir_exists ~/.config/tint2

		declare -A tint2_files
		tint2_files['config/tint2/default.tint2rc']='.config/tint2/tint2rc'
		set_home_files_from_array tint2_files
		;;
	xfce4-terminal)
		# Download the font I use for my terminal config
		program_box "$pkg_mgr --needed -S otf-meslo-powerline-git" "Installing terminal font..."

		infobox "Linking XFCE Terminal config"

		ensure_dir_exists ~/.config/xfce4/terminal

		declare -A xfce_terminal_files
		xfce_terminal_files['config/xfce4/terminal/accels.scm']='.config/xfce4/terminal/accels.scm'
		xfce_terminal_files['config/xfce4/terminal/terminalrc']='.config/xfce4/terminal/terminalrc'
		set_home_files_from_array xfce_terminal_files
		;;
	xmonad)
		infobox "Linking Xmonad config"

		ensure_dir_exists ~/.xmonad

		declare -A xmonad_files
		xmonad_files['xmonad/xmonad.hs']='.xmonad/xmonad.hs'
		set_home_files_from_array xmonad_files
		;;
	xprofile)
		infobox "Linking xprofile config"

		declare -A xprofile_files
		xprofile_files['xprofile']='.xprofile'
		set_home_files_from_array xprofile_files
		;;
	esac
done



infobox "Done. Enjoy your system!"
