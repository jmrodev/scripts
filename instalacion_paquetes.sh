#!/bin/bash

# # Check if the script is run as root
# if [ "$(id -u)" -ne 0 ]; then
#     echo "This script must be run as root."
#     exit 1
# fi

# # Define variables for the repo details
 REPO_NAME="[visual-studio-code-insiders]"
 REPO_SERVER="Server = https://nihaals.github.io/visual-studio-code-insiders-arch/"
 REPO_SIGLEVEL="SigLevel = PackageOptional"

# # Path to the pacman configuration file
 PACMAN_CONF="/etc/pacman.conf"

# # Create a backup of the existing pacman.conf file
 cp "$PACMAN_CONF" "$PACMAN_CONF.backup"

# # Function to append if not exist
 append_if_not_exist() {
     local line="$1"
     local file="$2"
        sudo grep -qF -- "$line" "$file" || echo "$line" >> "$file"
 }

# # Append the repository to pacman.conf if not already present
 echo "Checking and adding repository if not already present..."
 append_if_not_exist "$REPO_NAME" "$PACMAN_CONF"
 append_if_not_exist "$REPO_SERVER" "$PACMAN_CONF"
 append_if_not_exist "$REPO_SIGLEVEL" "$PACMAN_CONF"

 echo "Done. Check your $PACMAN_CONF"
 echo "A backup of the original configuration is at $PACMAN_CONF.backup"

# Instalar Yay si no está instalado
if ! command -v yay &> /dev/null
then
    echo "Yay no está instalado. Instalando Yay..."
    sudo pacman -Sy --needed git base-devel
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si
    cd ..
    rm -rf yay
    echo "Yay instalado correctamente."
else
    echo "Yay ya está instalado."
fi

# Optionally, update the package database
 echo "Would you like to update the package database now? (y/n)"
 read update_db

 if [[ $update_db == "y" ]]; then
     yay -Sy
     echo "Package database updated."
 else
     echo "Package database not updated."
 fi

# Actualizar sistema
#echo "Actualizando sistema..."
#sudo pacman -Syu

# Lista de paquetes para instalar desde los repositorios oficiales y AUR
paquetes=(
#necesario para github desktop
nodejs-lts-iron
#alsamixer
anydesk
apache
axel
base-devel
beebeep
blueberry
bluez
bluez-utils
brave-bin
calc
cockpit
cockpit-machines
cockpit-packagekit
cockpit-pcp
cockpit-podman
cockpit-storaged
compton
cryfs
cups
datagrip
dmenu
drawio-desktop
encfs
feh
firewalld
fsearch
git
gitextensions
github-cli
github-desktop-bin
gnome-search-tool
gocryptfs
google-chrome
gpart
gparted
gping
gqlplus
hardinfo
hpuld
htop
jdownloader2
jdk-openjdk
java-runtime-common
kcontacts5
kio-extras
kpeople5
kphotoalbum
ksshaskpass
lib32-gnutls
libvips
manjaro-kde-settings
manjaro-settings-manager-kcm
manjaro-tools-base-git
manjaro-tools-iso-git
manjaro-tools-yaml-git
mongodb-compass
mongodb-tools
mtools
mysql-workbench
nagios
networkmanager
nitrogen
#nodejs
nmap
numlockx
#oci-cli
openssh
oracle-instantclient-basic
oracle-instantclient-jdbc
oracle-instantclient-odbc
oracle-instantclient-sdk
oracle-instantclient-sqlplus
oracle-instantclient-tools
papirus-icon-theme
pavucontrol
phpmyadmin
plasma6-themes-breath
postman
pulseaudio-bluetooth
pulseaudio-equalizer-ladspa
pulseeffects-legacy
puppet
q4wine
recordmydesktop
rofi
rmlint
rsyslog
rustup
#scratch-desktop
scrot
scribus
sddm-breath-theme
shorewall
shotwell
sigil
sshpass
sssd
sscg
speedtest-cli
telescope
telegram-desktop
udisks2
udftools
usermin
ventoy
virtualbox
virtualbox-guest-iso
vde2
visual-studio-code-insiders-bin
vokoscreen
#webalizer
webmin
winetricks
wine
wine-mono
xsensors
#xkill
xorg-xhost
youtube-dl-gui
zenity
zenmap
zellij
zoom

)

# Instalar paquetes
for paquete in "${paquetes[@]}"
do
    if ! pacman -Qi $paquete &> /dev/null
    then
        echo "Instalando $paquete..."
        yay -S --noconfirm $paquete
        if [ $? -ne 0 ]; then
            echo "Error al instalar $paquete."
        fi
    else
        echo "El paquete $paquete ya está instalado."
    fi
done

echo "Todos los paquetes han sido procesados."
