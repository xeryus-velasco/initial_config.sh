#!/bin/sh

#Only works on Debain based so we gotta check
#(This commented line only works in BASH) [[ "$(uname -a)" =~ Debian|Ubuntu ]] || echo "Needs apt" && exit
if [ "$(uname -a | grep -icE 'Debian|Ubuntu')" -eq 0 ];then 
  echo "This script only works on apt based systems... " 
  exit
fi

echo "Is this a laptop? (y/n)"
read -r lap
echo "do you want vim/emacs/both? Type 'b' if unsure (v/e/b)"
read -r editor
echo "Are you going to game? (y/n)"
read -r game
echo "Are you going to program? (y/n)"
read -r program
echo "Do you want to copy desktop settings. (config files) (y/n)"
read -r desktop
echo "Do you want polybar? (Unstable) (y/n)"
read -r polybar


#update repository list
sudo apt update

#First we install aptitude so we can save space and manage dependencies easier
sudo apt install aptitude -y


#~~~Summary of each program in this list. All of the following is installed no matter what.
#Neofetch shows the OS, kernel, theme, processor, ram, and other important info
#Build-essentials is for C++ developement and includes make
#Shellcheck is a command you can run to ensure scripts are written well (compiler for .sh)
#Wine64 allows us to run windows programs on linux
#Git is git (git)
#Code is VSCode
#Firefox is a web browser
sudo aptitude install neofetch build-essential shellcheck wine64 git firefox -y 
sudo snap install --classic code

#Spotify 
curl -sS https://download.spotify.com/debian/pubkey.gpg | sudo apt-key add - 
echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
sudo apt-get update && sudo apt-get install spotify-client


#Laptop check
if [ "$lap" = "y" ]; then
  sudo aptitude install tlp -y
  cd /usr/share/pulseaudio/alsa-mixer/paths/ || exit
  sed -i.bkp '/\[Element PCM\]/i \[Element Master\]\nswitch = mute\nvolume = ignore' analog-output.conf.common
  pulseaudio -k
  cd "$HOME" || exit
fi


#Editor check
#Vim is a terminal text editor that is robust
#Emacs is better than vim but not really
if [ "$editor" = "v" ]; then
  sudo aptitude install vim -y
elif [ "$editor" = "e" ]; then
  sudo aptitude install emacs -y
elif [ "$editor" = "b" ]; then
  sudo aptitude install emacs vim -y
fi


#Game check
if [ "$game" = "y" ]; then
  #install steam and lutris
  sudo add-apt-repository -y multiverse
  sudo add-apt-repository -y ppa:lutris-team/lutris
  sudo aptitude update && sudo aptitude install steam lutris -y
fi


#Programmer check
if [ "$program" = "y" ]; then
  #Basic installs
  sudo aptitude install cmake -y

  #DotNet install
  wget -q https://packages.microsoft.com/config/ubuntu/19.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
  sudo dpkg -i packages-microsoft-prod.deb

  sudo apt-get update
  sudo apt-get install apt-transport-https
  sudo apt-get update
  sudo apt-get install dotnet-sdk-3.1

  sudo apt-get update
  sudo apt-get install apt-transport-https
  sudo apt-get update
  sudo apt-get install aspnetcore-runtime-3.1

  sudo apt-get update
  sudo apt-get install apt-transport-https
  sudo apt-get update
  sudo apt-get install dotnet-runtime-3.1

  #Mono install
  sudo apt update
  sudo apt install dirmngr gnupg apt-transport-https ca-certificates

  sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF

  sudo sh -c 'echo "deb https://download.mono-project.com/repo/ubuntu stable-bionic main" > /etc/apt/sources.list.d/mono-official-stable.list'

  sudo apt update
  sudo apt install mono-complete
fi


#Desktop environment setup check
if [ "$desktop" = "y" ]; then
  #Confirm we are in the home directory for config git
  if [ "$(pwd)" != "$HOME" ]; then
    cd || echo "This script needs to be run in $HOME" && exit
  fi

  git clone --bare https://xeryus-velasco@github.com/xeryus-velasco/dotfiles.git "$HOME/.dotfiles"
  git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" pull
fi


if [ "$polybar" = "y" ]; then
  #Polybar setup
  mkdir self_compile
  cd self_compile || exit
  sudo aptitude install python3 python3-sphinx pkg-config libcairo2-dev libxcb1-dev libxcb-util0-dev libxcb-randr0-dev libxcb-composite0-dev python-xcbgen xcb-proto libxcb-image0-dev libxcbewmh-dev libxcbicccm4-dev -y
  sudo aptitude markauto python python3
  sudo aptitude install libiw-dev libpulse-dev -y
  if [ ! -d polybar ]; then
      git clone https://github.com/polybar/polybar.git
      cd polybar || exit
  else
      cd polybar || exit
      git pull
  fi

  ./build.sh -j -n -p -A
  cd || exit
fi


#GNOME desktop environment extra
if [ "$(sudo aptitude show gnome-shell | grep -c 'State: installed')" -eq 1 ]; then
  echo "Installing gnome tweaks"
  sudo aptitude install gnome-tweak-tool -y
  firefox -new-tab "https://support.system76.com/articles/customize-gnome/"
  firefox -new-tab "https://extensions.gnome.org/extension/15/alternatetab/"
  firefox -new-tab "https://extensions.gnome.org/extension/517/caffeine/"
  firefox -new-tab "https://extensions.gnome.org/extension/945/cpu-power-manager/"
  firefox -new-tab "https://extensions.gnome.org/extension/1160/dash-to-panel/"
  firefox -new-tab "https://extensions.gnome.org/extension/615/appindicator-support/"
  firefox -new-tab "https://extensions.gnome.org/extension/352/middle-click-to-close-in-overview/"
fi 