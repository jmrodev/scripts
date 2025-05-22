#!/bin/bash
# This script uninstalls PHP, its common extensions, and related configurations.

# Exit immediately if a command exits with a non-zero status.
set -e

echo "Starting PHP and Extensions Uninstallation..."
echo "--------------------------------------------"

# Ensure the script is run with superuser privileges
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
            echo "Failed to uninstall $package_name. It might be a dependency or an error occurred."
        fi
    else
        echo "$package_name is not installed. Skipping."
    fi
}

# --- Uninstall PHP Packages ---
# List of common PHP packages and extensions. This might need adjustment based on what was installed.
# php-apache should be removed by uninstall_apache.sh or here if Apache is kept.
# For a full LAMP uninstall, php-apache will be removed here.
echo "Uninstalling PHP packages..."
php_packages_to_uninstall=(
    "php"
    "php-apache" # Important for Apache integration
    "php-gd"
    "php-imagick" # Example, if installed
    "php-redis"   # Example, if installed
    "php-pgsql"   # Example, if installed
    "php-sqlite"  # Example, if installed
    "php-apcu"
    "php-intl"
    "php-xdebug"  # Example, if installed
    "php-pear"    # Example, if installed
    # Add any other specific PHP extensions that were installed
)

for pkg in "${php_packages_to_uninstall[@]}"; do
    uninstall_package_if_exists "$pkg"
done

# --- Remove PHP Configuration Directory ---
PHP_CONFIG_DIR="/etc/php"
if [ -d "$PHP_CONFIG_DIR" ]; then
    echo "Removing PHP configuration directory: $PHP_CONFIG_DIR..."
    if sudo rm -rf "$PHP_CONFIG_DIR"; then
        echo "Directory $PHP_CONFIG_DIR removed."
    else
        echo "Failed to remove directory $PHP_CONFIG_DIR. Check permissions."
    fi
else
    echo "PHP configuration directory $PHP_CONFIG_DIR not found. Skipping."
fi

# --- Remove PHP Test Files ---
# Remove info.php or test.php from common webroot locations
PHP_TEST_FILE_SRV="/srv/http/info.php" # Or test.php, or prueba.php
PHP_TEST_FILE_SRV_ALT="/srv/http/test.php"
PHP_TEST_FILE_SRV_ALT2="/srv/http/prueba.php"

if [ -f "$PHP_TEST_FILE_SRV" ]; then
    echo "Removing PHP test file: $PHP_TEST_FILE_SRV..."
    sudo rm -f "$PHP_TEST_FILE_SRV"
fi
if [ -f "$PHP_TEST_FILE_SRV_ALT" ]; then
    echo "Removing PHP test file: $PHP_TEST_FILE_SRV_ALT..."
    sudo rm -f "$PHP_TEST_FILE_SRV_ALT"
fi
if [ -f "$PHP_TEST_FILE_SRV_ALT2" ]; then
    echo "Removing PHP test file: $PHP_TEST_FILE_SRV_ALT2..."
    sudo rm -f "$PHP_TEST_FILE_SRV_ALT2"
fi


# User-specific public_html test file removal (safer to inform user)
# if [ -n "$SUDO_USER" ] && [ -f "/home/$SUDO_USER/public_html/info.php" ]; then
#     echo "Removing PHP test file from /home/$SUDO_USER/public_html/info.php..."
#     sudo rm -f "/home/$SUDO_USER/public_html/info.php"
# fi
echo "Note: If you created PHP test files in user-specific directories (e.g., ~/public_html/info.php), please remove them manually."

# --- Revert Apache Configuration Changes for PHP ---
APACHE_CONFIG_FILE="/etc/httpd/conf/httpd.conf"
PHP_MODULE_LINE_PATTERN="LoadModule php_module modules/libphp.so" # Arch specific
PHP_MODULE_INCLUDE_PATTERN="Include conf/extra/php_module.conf"

if [ -f "$APACHE_CONFIG_FILE" ]; then
    echo "Removing PHP module configuration from Apache file: $APACHE_CONFIG_FILE..."
    # Use sudo for sed as it modifies a root-owned file
    if grep -q "$PHP_MODULE_LINE_PATTERN" "$APACHE_CONFIG_FILE"; then
        sudo sed -i "/${PHP_MODULE_LINE_PATTERN//\//\\/}/d" "$APACHE_CONFIG_FILE"
        echo "Removed PHP LoadModule line from $APACHE_CONFIG_FILE."
    fi
    if grep -q "$PHP_MODULE_INCLUDE_PATTERN" "$APACHE_CONFIG_FILE"; then
        sudo sed -i "/${PHP_MODULE_INCLUDE_PATTERN//\//\\/}/d" "$APACHE_CONFIG_FILE"
        echo "Removed PHP Include line from $APACHE_CONFIG_FILE."
    fi

    # Optionally, revert mpm_prefork changes if no other module requires it.
    # This is more complex as it depends on other potential Apache modules.
    # For simplicity, we might leave mpm_prefork as is or instruct user.
    echo "Note: Apache's MPM module was set to 'mpm_prefork_module' for PHP."
    echo "If you are not using other modules that require prefork, you might consider switching back to 'mpm_event_module'."
    echo "This usually involves commenting out mpm_prefork_module and uncommenting mpm_event_module in $APACHE_CONFIG_FILE."

    # Restart Apache if it's running to apply changes
    if systemctl is-active --quiet httpd; then
        echo "Restarting Apache to apply configuration changes..."
        if sudo systemctl restart httpd; then
            echo "Apache restarted successfully."
        else
            echo "Warning: Failed to restart Apache. Check 'systemctl status httpd' or 'journalctl -xeu httpd'."
        fi
    fi
else
    echo "Apache configuration file $APACHE_CONFIG_FILE not found. Skipping Apache config changes for PHP."
fi

echo "--------------------------------------------"
echo "PHP and extensions uninstallation process complete."
echo "Please review the output for any errors or warnings."
echo "--------------------------------------------"