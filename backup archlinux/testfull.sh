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
acpi
acpid
adobe-source-han-sans-cn-fonts
adobe-source-han-sans-jp-fonts
adobe-source-han-sans-kr-fonts
adobe-source-sans-fonts
alsa-firmware
alsa-utils
apache
arc-gtk-theme
ark
audacious
audiocd-kio
avahi
axel
b43-fwcutter
base
base-devel
beebeep
blueberry
bluedevil
bluez-utils
breeze-gtk
btrfs-progs
bzip2
calc
chafa
cockpit
cockpit-machines
cockpit-packagekit
cockpit-pcp
cockpit-podman
cockpit-storaged
composer
coreutils
cpupower
cronie
cryfs
cryptsetup
device-mapper
dhclient
dhcpcd
diffutils
dmenu
dmidecode
dmraid
dnsmasq
dolphin
dolphin-plugins
dosfstools
e2fsprogs
ecryptfs-utils
efibootmgr
elisa
encfs
exfatprogs
f2fs-tools
fastfetch
fd
fdupes
feh
ffmpeg
ffmpegthumbs
filelight
filezilla
firefox
firefox-i18n-en-us
firefox-i18n-es-ar
firewalld
fish
fwupd
fzf
giggle
gitg
github-cli
gitui
glibc-locales
gnome-themes-extra
gocryptfs
gpart
gparted
gping
grub
grub-btrfs
grub-theme-manjaro
gst-libav
gst-plugins-bad
gst-plugins-base
gst-plugins-good
gst-plugins-ugly
gtk3
gwenview
htop
hunspell-en_us
hunspell-es_ar
hyphen-en
hyphen-es
inetutils
intel-ucode
inxi
jdk11-openjdk
jdk8-openjdk
jfsutils
jq
jre8-openjdk
jre8-openjdk-headless
julia
kaccounts-providers
kamera
kate
kcalc
kde-gtk-config
kdeconnect
kdegraphics-thumbnailers
kdenetwork-filesharing
kdeplasma-addons
keditbookmarks
kfind
kgamma
khelpcenter
kimageformats5
kinfocenter
kinit
kio-extras
kitty
kmenuedit
kompare
konsole
kphotoalbum
kscreen
kscreenlocker
ksshaskpass
ksystemlog
kwallet-pam
kwalletmanager
kwayland-integration
kwin
kwrited
lazygit
less
lib32-gnutls
lib32-libcanberra
lib32-libva-intel-driver
lib32-libva-mesa-driver
lib32-libva-vdpau-driver
lib32-mesa-utils
lib32-mesa-vdpau
lib32-vulkan-intel
lib32-vulkan-radeon
libcanberra
libdvdcss
libpamac-flatpak-plugin
libreoffice-still
libreoffice-still-es
libva-intel-driver
libva-mesa-driver
libva-vdpau-driver
libvips
libxcrypt-compat
linux66
linux66-virtualbox-host-modules
logrotate
luarocks
lvm2
man-db
man-pages
man-pages-es
manjaro-alsa
manjaro-application-utility
manjaro-browser-settings
manjaro-gstreamer
manjaro-hello
manjaro-kde-settings
manjaro-modem
manjaro-pipewire
manjaro-printer
manjaro-release
manjaro-settings-manager-knotifier
manjaro-system
manjaro-tools-iso-git
manjaro-zsh-config
mariadb
mdadm
mediainfo
meld
memtest86+
memtest86+-efi
mesa-utils
mesa-vdpau
mhwd
mhwd-db
milou
mkinitcpio-openswap
mobile-broadband-provider-info
modemmanager
mtools
mtpfs
mysql-workbench
nano
nano-syntax-highlighting
neofetch
neovim
networkmanager
networkmanager-l2tp
networkmanager-openconnect
networkmanager-openvpn
networkmanager-pptp
networkmanager-vpnc
nfs-utils
nitrogen
nmap
nodejs-lts-iron
noise-suppression-for-voice
noto-fonts
noto-fonts-emoji
nss-mdns
ntfs-3g
ntp
numlockx
obsidian
ocrad
okular
ollama
openjdk11-doc
openjdk11-src
openjdk8-doc
openjdk8-src
openresolv
openssh
os-prober
oxygen-icons
oxygen5
p7zip
packagekit-qt5
pamac-cli
pamac-gtk3
pamac-tray-icon-plasma
papirus-icon-theme
partitionmanager
pavucontrol
pdfarranger
perl
perl-file-mimeinfo
perl-image-exiftool
phonon-qt5-vlc
php-apache
php-gd
phpmyadmin
plasma-browser-integration
plasma-desktop
plasma-nm
plasma-pa
plasma-systemmonitor
plasma-thunderbolt
plasma-workspace
plasma-workspace-wallpapers
plymouth
plymouth-kcm
plymouth-theme-manjaro
pnpm
poppler-data
power-profiles-daemon
powerdevil
powertop
print-manager
pulseaudio-equalizer-ladspa
puppet
python-faker
python-pillow
python-pip
python-pynvim
python-pyqt5
python-pysmbc
python-reportlab
qbittorrent
qpwgraph
qt5-imageformats
qt5-virtualkeyboard
recordmydesktop
reiserfsprogs
ripgrep
rmlint
rofi
rsync
rustup
s-nail
samba
scribus
scrot
sddm
sddm-breath-theme
sddm-kcm
shotwell
sigil
skanlite
sof-firmware
spectacle
speedtest-cli
sscg
sshfs
sshpass
sssd
sudo
sysfsutils
system-config-printer
systemd
systemsettings
telegram-desktop
terminus-font
tesseract
texinfo
texlive-basic
texlive-bin
timeshift
timeshift-autosnap-manjaro
tk
tmux
ttf-dejavu
ttf-droid
ttf-inconsolata
ttf-indic-otf
ttf-liberation
udftools
udiskie
udisks2
unarchiver
update-grub
usb_modeswitch
usbutils
vde2
ventoy
vi
virtualbox
virtualbox-guest-iso
vlc
vokoscreen
vulkan-intel
vulkan-radeon
wezterm
wget
which
wine-mono
winetricks
wireless-regdb
wpa_supplicant
xclip
xdg-desktop-portal-kde
xdg-user-dirs
xdg-utils
xdotool
xf86-input-elographics
xf86-input-evdev
xf86-input-libinput
xf86-input-void
xf86-video-amdgpu
xf86-video-ati
xf86-video-intel
xf86-video-nouveau
xfsprogs
xorg-mkfontscale
xorg-server
xorg-twm
xorg-xhost
xorg-xinit
xorg-xkill
xsel
xsensors
yakuake
yay
zellij
zenity
anydesk-bin
brave-bin
datagrip
drawio-desktop
duplex
duplicati-beta-bin
freemind
fsearch
g
gitextensions
github-desktop-bin
google-chrome
gqlplus
hardinfo2
hpuld
jdownloader2
khotkeys
manjaro-settings-manager-kcm
mongodb-compass
mongodb-tools
nagios
oracle-instantclient-jdbc
oracle-instantclient-odbc
oracle-instantclient-sdk
oracle-instantclient-sqlplus
oracle-instantclient-tools
picom-arian8j2-git
plasma-simplemenu
postman-bin
pseint
pulseeffects-legacy
q4wine-git
rsyslog
runjs-bin
shorewall
spectre-meltdown-checker
telescope
twitch-downloader-gui
unetbootin
usermin
visual-studio-code-insiders-bin
webmin
wish
youtube-dl-gui
zenmap
zoom

#necesario para github desktop
nodejs-lts-iron
#alsamixer
anydesk
apache
axel
base-devel
bat
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
