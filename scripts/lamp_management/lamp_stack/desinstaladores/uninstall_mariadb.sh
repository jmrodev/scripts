#!/bin/bash
# This script uninstalls MariaDB and removes its data and configuration.

# Exit immediately if a command exits with a non-zero status.
set -e

echo "Starting MariaDB Uninstallation..."
echo "----------------------------------"

# Ensure the script is run with superuser privileges
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run with superuser privileges (e.g., using sudo)."
    exit 1
fi

# --- Stop and Disable MariaDB Service ---
echo "Stopping and disabling MariaDB service..."
if systemctl is-active --quiet mariadb; then
    if sudo systemctl stop mariadb; then
        echo "MariaDB service stopped."
    else
        echo "Failed to stop MariaDB service. It might not have been running."
    fi
fi
if systemctl is-enabled --quiet mariadb; then
    if sudo systemctl disable mariadb; then
        echo "MariaDB service disabled."
    else
        echo "Failed to disable MariaDB service."
    fi
fi

# --- Uninstall MariaDB Packages ---
# Also consider mariadb-clients if it was installed
echo "Uninstalling MariaDB packages (mariadb, mariadb-clients)..."
if pacman -Qi mariadb &> /dev/null; then
    if sudo pacman -Rns --noconfirm mariadb mariadb-clients; then # Attempt to remove clients too
        echo "MariaDB packages uninstalled successfully."
    else
        echo "Failed to uninstall MariaDB packages completely. Trying mariadb package alone..."
        if sudo pacman -Rns --noconfirm mariadb; then
            echo "MariaDB package uninstalled successfully."
        else
            echo "Failed to uninstall MariaDB. It might be a dependency or an error occurred."
        fi
    fi
else
    echo "MariaDB package is not installed. Skipping package uninstallation."
fi


# --- Remove MariaDB Data and Configuration Files ---
MARIADB_DATA_DIR="/var/lib/mysql"
MARIADB_CONFIG_DIR_MYSQL="/etc/mysql" # Older config location, check just in case
MARIADB_CONFIG_DIR_MYCNFD="/etc/my.cnf.d"
MARIADB_SERVICE_OVERRIDE="/etc/systemd/system/mariadb.service.d/override.conf"

echo "Removing MariaDB data directory: $MARIADB_DATA_DIR..."
if [ -d "$MARIADB_DATA_DIR" ]; then
    # Add a safety check or prompt here if this directory could contain critical non-MariaDB data,
    # though for /var/lib/mysql it's usually specific to MariaDB/MySQL.
    read -p "WARNING: This will delete all MariaDB databases in $MARIADB_DATA_DIR. Are you sure? (y/N): " confirm_delete_data
    if [[ "$confirm_delete_data" =~ ^[Yy]$ ]]; then
        if sudo rm -rf "$MARIADB_DATA_DIR"; then
            echo "MariaDB data directory $MARIADB_DATA_DIR removed."
        else
            echo "Failed to remove MariaDB data directory $MARIADB_DATA_DIR."
        fi
    else
        echo "Skipping removal of $MARIADB_DATA_DIR."
    fi
else
    echo "MariaDB data directory $MARIADB_DATA_DIR not found. Skipping."
fi

if [ -d "$MARIADB_CONFIG_DIR_MYSQL" ]; then
    echo "Removing old MariaDB config directory: $MARIADB_CONFIG_DIR_MYSQL..."
    if sudo rm -rf "$MARIADB_CONFIG_DIR_MYSQL"; then
        echo "Directory $MARIADB_CONFIG_DIR_MYSQL removed."
    else
        echo "Failed to remove directory $MARIADB_CONFIG_DIR_MYSQL."
    fi
fi

if [ -d "$MARIADB_CONFIG_DIR_MYCNFD" ]; then
    echo "Removing MariaDB config directory: $MARIADB_CONFIG_DIR_MYCNFD..."
    if sudo rm -rf "$MARIADB_CONFIG_DIR_MYCNFD"; then # This removes the whole dir including server.cnf
        echo "Directory $MARIADB_CONFIG_DIR_MYCNFD removed."
    else
        echo "Failed to remove directory $MARIADB_CONFIG_DIR_MYCNFD."
    fi
fi

if [ -f "$MARIADB_SERVICE_OVERRIDE" ]; then
    echo "Removing MariaDB service override file: $MARIADB_SERVICE_OVERRIDE..."
    if sudo rm -f "$MARIADB_SERVICE_OVERRIDE"; then
        echo "Service override file $MARIADB_SERVICE_OVERRIDE removed."
        echo "Reloading systemd daemon..."
        sudo systemctl daemon-reload
    else
        echo "Failed to remove service override file $MARIADB_SERVICE_OVERRIDE."
    fi
fi

echo "----------------------------------"
echo "MariaDB uninstallation process complete."
echo "Please review the output for any errors or warnings."
echo "----------------------------------"
