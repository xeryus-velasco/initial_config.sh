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
if [ "$lap" == "y" ]; then
  sudo aptitude install tlp -y
  cd /usr/share/pulseaudio/alsa-mixer/paths/
  sed -i.bkp '/\[Element PCM\]/i \[Element Master\]\nswitch = mute\nvolume = ignore' analog-output.conf.common
  pulseaudio -k
  cd $HOME
fi


#Editor check
#Vim is a terminal text editor that is robust
#Emacs is better than vim but not really
if [ "$editor" == "v" ]; then
  sudo aptitude install vim -y
elif [ "$editor" == "e" ]; then
  sudo aptitude install emacs -y
elif [ "$editor" == "b" ]; then
  sudo aptitude install emacs vim -y
fi


#Game check
if [ "$game" == "y" ]; then
  #install steam and lutris
  sudo add-apt-repository -y multiverse
  sudo add-apt-repository -y ppa:lutris-team/lutris
  sudo aptitude update && sudo aptitude install steam lutris -y
fi


#Programmer check
if [ "$program" == "y" ]; then
  #Basic installs
  sudo aptitude install cmake -y

  #Jetbrains toolkit
  [ $(id -u) != "0" ] && exec sudo "$0" "$@"
  echo -e " \e[94mInstalling Jetbrains Toolbox\e[39m"
  echo ""

  function getLatestUrl() {
  USER_AGENT=('User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/59.0.3071.115 Safari/537.36')

  URL=$(curl 'https://data.services.jetbrains.com//products/releases?code=TBA&latest=true&type=release' -H 'Origin: https://www.jetbrains.com' -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: en-US,en;q=0.8' -H "${USER_AGENT[@]}" -H 'Accept: application/json, text/javascript, */*; q=0.01' -H 'Referer: https://www.jetbrains.com/toolbox/download/' -H 'Connection: keep-alive' -H 'DNT: 1' --compressed | grep -Po '"linux":.*?[^\\]",' | awk -F ':' '{print $3,":"$4}'| sed 's/[", ]//g')
  echo $URL
  }
  getLatestUrl

  FILE=$(basename ${URL})
  DEST=$PWD/$FILE

  echo ""
  echo -e "\e[94mDownloading Toolbox files \e[39m"
  echo ""
  wget -cO  ${DEST} ${URL} --read-timeout=5 --tries=0
  echo ""
  echo -e "\e[32mDownload complete!\e[39m"
  echo ""
  DIR="/opt/jetbrains-toolbox"
  echo ""
  echo  -e "\e[94mInstalling to $DIR\e[39m"
  echo ""
  if mkdir ${DIR}; then
      tar -xzf ${DEST} -C ${DIR} --strip-components=1
  fi

  chmod -R +rwx ${DIR}
  touch ${DIR}/jetbrains-toolbox.sh
  echo "#!/bin/bash" >> $DIR/jetbrains-toolbox.sh
  echo "$DIR/jetbrains-toolbox" >> $DIR/jetbrains-toolbox.sh

  ln -s ${DIR}/jetbrains-toolbox.sh /usr/local/bin/jetbrains-toolbox
  chmod -R +rwx /usr/local/bin/jetbrains-toolbox
  echo ""
  rm ${DEST}
  echo  -e "\e[32mDone.\e[39m"

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
fi


#Desktop environment setup check
if [ "$desktop" == "y" ]; then
  #Confirm we are in the home directory for config git
  if [ "$(pwd)" != "$HOME" ]; then
    cd || echo "This script needs to be run in $HOME" && exit
  fi

  git clone --bare https://xeryus-velasco@github.com/xeryus-velasco/dotfiles.git "$HOME/.dotfiles"
  git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" pull
fi

if [ "$polybar" == "y" ]; then
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
fi 

firefox -new-tab "https://support.system76.com/articles/customize-gnome/"