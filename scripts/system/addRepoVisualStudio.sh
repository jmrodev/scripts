#!/bin/bash

# Check if the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root."
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

# Optionally, update the package database
echo "Would you like to update the package database now? (y/n)"
read update_db

if [[ $update_db == "y" ]]; then
    pacman -Sy
    echo "Package database updated."
else
    echo "Package database not updated."
fi
