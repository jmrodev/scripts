#!/bin/bash
# This script uninstalls Apache HTTP Server and related configurations.

# Exit immediately if a command exits with a non-zero status.
set -e

echo "Starting Apache HTTP Server Uninstallation..."
echo "---------------------------------------------"

# Ensure the script is run with superuser privileges
# Although the parent script (uninstall.sh) should handle this,
# it's good practice for sub-scripts to also check or expect to be run with sudo.
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run with superuser privileges (e.g., using sudo)."
    exit 1
fi

# Function to attempt uninstallation of a package if it's installed
uninstall_package_if_exists() {
    local package_name="$1"
    if pacman -Qi "$package_name" &> /dev/null; then
        echo "Uninstalling $package_name..."
        if sudo pacman -Rns --noconfirm "$package_name"; then
            echo "$package_name uninstalled successfully."
        else
            echo "Failed to uninstall $package_name. It might be a dependency for other packages or an error occurred."
            # Continue anway, as we want to clean up as much as possible.
        fi
    else
        echo "$package_name is not installed. Skipping."
    fi
}

# --- Stop and Disable Apache Service ---
echo "Stopping and disabling Apache service (httpd)..."
if systemctl is-active --quiet httpd; then
    if sudo systemctl stop httpd; then
        echo "Apache service stopped."
    else
        echo "Failed to stop Apache service. It might not have been running."
    fi
fi
if systemctl is-enabled --quiet httpd; then
    if sudo systemctl disable httpd; then
        echo "Apache service disabled."
    else
        echo "Failed to disable Apache service."
    fi
fi

# --- Uninstall Packages ---
# Uninstall php-apache first as it depends on apache
uninstall_package_if_exists "php-apache"
uninstall_package_if_exists "apache"

# --- Remove Configuration and Data Directories ---
APACHE_CONFIG_DIR="/etc/httpd"
APACHE_DOC_ROOT="/srv/http" # Default, might have been changed by user

if [ -d "$APACHE_CONFIG_DIR" ]; then
    echo "Removing Apache configuration directory: $APACHE_CONFIG_DIR..."
    if sudo rm -rf "$APACHE_CONFIG_DIR"; then
        echo "Directory $APACHE_CONFIG_DIR removed."
    else
        echo "Failed to remove directory $APACHE_CONFIG_DIR. Check permissions or if it's in use."
    fi
else
    echo "Apache configuration directory $APACHE_CONFIG_DIR not found. Skipping."
fi

if [ -d "$APACHE_DOC_ROOT" ]; then
    echo "Removing default Apache document root: $APACHE_DOC_ROOT..."
    # Be cautious with rm -rf. This assumes it's the default and not a critical user directory.
    if sudo rm -rf "$APACHE_DOC_ROOT"; then
        echo "Directory $APACHE_DOC_ROOT removed."
    else
        echo "Failed to remove directory $APACHE_DOC_ROOT. Check permissions or if it's in use."
    fi
else
    echo "Default Apache document root $APACHE_DOC_ROOT not found. Skipping."
fi

# --- Firewall Rules (Illustrative - depends on firewall used) ---
# The original script had iptables rules. This is highly dependent on the firewall solution (iptables, ufw, firewalld).
# For a generic script, it's safer to instruct the user or skip this.
# For now, I will comment it out and add a note.
# echo "Attempting to remove firewall rules for port 80 (if they were added via iptables)..."
# sudo iptables -D INPUT -p tcp --dport 80 -j ACCEPT &>/dev/null || echo "iptables rule for port 80 (IPv4) not found or failed to remove."
# sudo ip6tables -D INPUT -p tcp --dport 80 -j ACCEPT &>/dev/null || echo "ip6tables rule for port 80 (IPv6) not found or failed to remove."
echo "Note: If you had manually configured firewall rules (e.g., with ufw or firewalld), please remove them for port 80/443 if no longer needed."

# --- Remove User-specific public_html (Use with caution) ---
# This was in the original script. It's potentially dangerous if the user has other content there.
# It's better to inform the user to do this manually if they wish.
# if [ -n "$SUDO_USER" ] && [ -d "/home/$SUDO_USER/public_html" ]; then
#     read -p "Do you want to remove /home/$SUDO_USER/public_html? This is not reversible. (y/N): " remove_user_html
#     if [[ "$remove_user_html" =~ ^[Yy]$ ]]; then
#         echo "Removing /home/$SUDO_USER/public_html..."
#         if sudo rm -rf "/home/$SUDO_USER/public_html"; then
#             echo "/home/$SUDO_USER/public_html removed."
#         else
#             echo "Failed to remove /home/$SUDO_USER/public_html."
#         fi
#     fi
# fi
echo "Consider manually checking for and removing user-specific web directories like '~/public_html' if they were used by Apache and are no longer needed."


echo "---------------------------------------------"
echo "Apache HTTP Server uninstallation process complete."
echo "Please review the output for any errors or warnings."
echo "---------------------------------------------"