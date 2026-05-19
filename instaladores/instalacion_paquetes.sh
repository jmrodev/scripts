#!/bin/bash

# Function to modify repository configuration
configure_repos() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "This function must be run as root."
        exit 1
    fi

    # Define variables for the repo details
    REPO_NAME="[visual-studio-code-insiders]"
    REPO_SERVER="Server = https://nihaals.github.io/visual-studio-code-insiders-arch/"
    REPO_SIGLEVEL="SigLevel = PackageOptional"

    # Path to the pacman configuration file
    PACMAN_CONF="/etc/pacman.conf"

    # Create a backup of the existing pacman.conf file
    cp "$PACMAN_CONF" "$PACMAN_CONF.backup"

    # Function to append if not exist
    append_if_not_exist() {
        local line="$1"
        local file="$2"
        grep -qF -- "$line" "$file" || echo "$line" >> "$file"
    }

    # Append the repository to pacman.conf if not already present
    echo "Checking and adding repository if not already present..."
    append_if_not_exist "$REPO_NAME" "$PACMAN_CONF"
    append_if_not_exist "$REPO_SERVER" "$PACMAN_CONF"
    append_if_not_exist "$REPO_SIGLEVEL" "$PACMAN_CONF"

    echo "Done. Check your $PACMAN_CONF"
    echo "A backup of the original configuration is at $PACMAN_CONF.backup"

    # Exit root and prompt to continue with user-level script
    echo "Configuration updated. Please run 'manage_system.sh' as a normal user to install packages."
}

# Function to install Yay if not already installed
install_yay() {
    if ! command -v yay &> /dev/null; then
        echo "Yay is not installed. Installing Yay..."
        sudo pacman -Sy --needed git base-devel
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -si
        cd ..
        rm -rf yay
        echo "Yay installed successfully."
    else
        echo "Yay is already installed."
    fi
}

# Function to update the package database
update_package_db() {
    echo "Would you like to update the package database now? (y/n)"
    read update_db

    if [[ $update_db == "y" ]]; then
        yay -Sy
        echo "Package database updated."
    else
        echo "Package database not updated."
    fi
}

# Function to install packages
install_packages() {
    # List of packages to install
    packages=(
        base-devel
        nodejs-lts-iron
        anydesk
        apache
        axel
        base-devel
        beebeep
        blueberry
        bluez
        bluez-utils
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
        manjaro-tools-base-git
        manjaro-tools-iso-git
        manjaro-tools-yaml-git
        mongodb-tools
        mtools
        mysql-workbench
        networkmanager
        nitrogen
        nmap
        numlockx
        openssh
        papirus-icon-theme
        pavucontrol
        plasma6-themes-breath
        postman
        puppet
        q4wine
        recordmydesktop
        rofi
        rmlint
        rsyslog
        rustup
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
        vde2
        vokoscreen
        webmin
        xsensors
        xkill
        xorg-xhost
        youtube-dl-gui
        zenity
        zenmap
        zellij
    )

    # Check system hardware
    cpu_cores=$(nproc)
    ram_gb=$(free -g | awk '/^Mem:/{print $2}')

    # Conditionally add commented packages
    if [ "$cpu_cores" -ge 4 ] && [ "$ram_gb" -ge 3 ]; then
        packages+=(
            visual-studio-code-insiders-bin
            brave-bin
            datagrip
            mongodb-compass
            oracle-instantclient-basic
            oracle-instantclient-jdbc
            oracle-instantclient-odbc
            oracle-instantclient-sdk
            oracle-instantclient-sqlplus
            oracle-instantclient-tools
            wine
            wine-mono
            webalizer
            zoom
        )
    fi

    # Install packages
    install_yay
    update_package_db

    for package in "${packages[@]}"; do
        if ! pacman -Qi $package &> /dev/null; then
            echo "Installing $package..."
            yay -S --noconfirm $package
            if [ $? -ne 0 ]; then
                echo "Error installing $package."
            fi
        else
            echo "$package is already installed."
        fi
    done

    echo "All packages have been processed."
}

# Main menu
echo "Select an option:"
echo "1. Configure Repositories"
echo "2. Install Packages"
echo "3. Configure Repositories and Install Packages"
echo "4. Exit"

read choice

case $choice in
    1)
        configure_repos
        ;;
    2)
        install_packages
        ;;
    3)
        configure_repos
        echo "Now you can run this script again as a normal user to install packages."
        ;;
    4)
        echo "Exiting."
        ;;
    *)
        echo "Invalid option. Please select 1, 2, 3, or 4."
        ;;
esac
