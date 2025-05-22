#!/bin/bash
# This script uninstalls phpMyAdmin and removes its Apache configuration.

# Exit immediately if a command exits with a non-zero status.
set -e

echo "Starting phpMyAdmin Uninstallation..."
echo "-----------------------------------"

# Ensure the script is run with superuser privileges
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run with superuser privileges (e.g., using sudo)."
    exit 1
fi

# --- Uninstall phpMyAdmin Package ---
echo "Uninstalling phpMyAdmin package..."
if pacman -Qi phpmyadmin &> /dev/null; then
    if sudo pacman -Rns --noconfirm phpmyadmin; then
        echo "phpMyAdmin package uninstalled successfully."
    else
        echo "Failed to uninstall phpMyAdmin package. It might be a dependency or an error occurred."
    fi
else
    echo "phpMyAdmin package is not installed. Skipping package uninstallation."
fi

# --- Remove Apache Configuration for phpMyAdmin ---
APACHE_PMA_CONF="/etc/httpd/conf/extra/phpmyadmin.conf"
APACHE_CONFIG_FILE="/etc/httpd/conf/httpd.conf"
PMA_APACHE_INCLUDE_PATTERN="Include conf/extra/phpmyadmin.conf" # Pattern to search for

if [ -f "$APACHE_PMA_CONF" ]; then
    echo "Removing phpMyAdmin Apache configuration file: $APACHE_PMA_CONF..."
    if sudo rm -f "$APACHE_PMA_CONF"; then
        echo "File $APACHE_PMA_CONF removed."
    else
        echo "Failed to remove $APACHE_PMA_CONF. Check permissions."
    fi
else
    echo "phpMyAdmin Apache configuration file $APACHE_PMA_CONF not found. Skipping."
fi

# Remove the Include line from Apache's main configuration file
if [ -f "$APACHE_CONFIG_FILE" ]; then
    echo "Checking Apache main configuration for phpMyAdmin include line..."
    if grep -q "$PMA_APACHE_INCLUDE_PATTERN" "$APACHE_CONFIG_FILE"; then
        echo "Removing phpMyAdmin include line from $APACHE_CONFIG_FILE..."
        # Use sudo for sed as it modifies a root-owned file
        if sudo sed -i "/${PMA_APACHE_INCLUDE_PATTERN//\//\\/}/d" "$APACHE_CONFIG_FILE"; then
            echo "Successfully removed include line from $APACHE_CONFIG_FILE."
        else
            echo "Failed to remove include line from $APACHE_CONFIG_FILE."
        fi
    else
        echo "phpMyAdmin include line not found in $APACHE_CONFIG_FILE."
    fi
else
    echo "Apache main configuration file $APACHE_CONFIG_FILE not found. Skipping."
fi

# --- Restart Apache (if active) ---
# This is important to apply the removal of the phpMyAdmin configuration.
if command -v httpd &> /dev/null && systemctl list-units --type=service --state=active | grep -q 'httpd.service'; then
    echo "Restarting Apache to apply changes..."
    if sudo systemctl restart httpd; then
        echo "Apache restarted successfully."
    else
        echo "Warning: Failed to restart Apache. Please check 'systemctl status httpd' or 'journalctl -xeu httpd'."
    fi
else
    echo "Apache service (httpd) is not active or not installed. Skipping Apache restart."
fi

# --- Remove phpMyAdmin Web Application Directory ---
# Usually located at /usr/share/webapps/phpMyAdmin
PMA_WEBAPP_DIR="/usr/share/webapps/phpMyAdmin"
if [ -d "$PMA_WEBAPP_DIR" ]; then
    echo "Removing phpMyAdmin web application directory: $PMA_WEBAPP_DIR..."
    read -p "WARNING: This will delete all files in $PMA_WEBAPP_DIR. Are you sure? (y/N): " confirm_delete_webapp
    if [[ "$confirm_delete_webapp" =~ ^[Yy]$ ]]; then
        if sudo rm -rf "$PMA_WEBAPP_DIR"; then
            echo "Directory $PMA_WEBAPP_DIR removed."
        else
            echo "Failed to remove directory $PMA_WEBAPP_DIR."
        fi
    else
        echo "Skipping removal of $PMA_WEBAPP_DIR."
    fi
else
    echo "phpMyAdmin web application directory $PMA_WEBAPP_DIR not found. Skipping."
fi


echo "-----------------------------------"
echo "phpMyAdmin uninstallation process complete."
echo "Please review the output for any errors or warnings."
echo "-----------------------------------"
