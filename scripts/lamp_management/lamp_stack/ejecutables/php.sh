#!/bin/bash
# This script installs PHP and integrates it with Apache.

# Exit immediately if a command exits with a non-zero status.
set -e

echo "Starting PHP Installation and Apache Integration..."
echo "----------------------------------------------------"

# Ensure the script is run with superuser privileges
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run with superuser privileges (e.g., using sudo)."
    exit 1
fi

# --- PHP Installation ---
echo "Installing PHP and php-apache module..."
if sudo pacman -Syu --noconfirm php php-apache; then
    echo "PHP and php-apache installed successfully."
else
    echo "Failed to install PHP packages. Please check pacman output."
    exit 1
fi

# --- Apache Configuration for PHP ---
APACHE_CONFIG_FILE="/etc/httpd/conf/httpd.conf"
PHP_MODULE_CONF_EXTRA="/etc/httpd/conf/extra/php_module.conf" # Arch specific PHP module config

if [ ! -f "$APACHE_CONFIG_FILE" ]; then
    echo "Error: Apache configuration file '$APACHE_CONFIG_FILE' not found."
    exit 1
fi

echo "Configuring Apache for PHP module..."

# Ensure mpm_prefork_module is enabled and mpm_event_module is disabled for mod_php
# Note: For PHP-FPM setups, mpm_event_module is often preferred. This script assumes mod_php.
echo "Switching Apache to mpm_prefork_module for mod_php compatibility..."
if grep -q "^LoadModule mpm_event_module" "$APACHE_CONFIG_FILE"; then
    sudo sed -i 's/^LoadModule mpm_event_module/#LoadModule mpm_event_module/' "$APACHE_CONFIG_FILE"
fi
if grep -q "^#LoadModule mpm_prefork_module" "$APACHE_CONFIG_FILE"; then
    sudo sed -i 's/^#LoadModule mpm_prefork_module/LoadModule mpm_prefork_module/' "$APACHE_CONFIG_FILE"
fi

# Add LoadModule for php_module (libphp.so on Arch) if not present
# This is typically handled by php_module.conf now, but good to double check or ensure the include.
PHP_MODULE_LINE="LoadModule php_module modules/libphp.so"
if ! grep -Fxq "$PHP_MODULE_LINE" "$APACHE_CONFIG_FILE" && ! grep -Fxq "$PHP_MODULE_LINE" "$PHP_MODULE_CONF_EXTRA"; then
    echo "Warning: PHP module line not found automatically. Attempting to add to $APACHE_CONFIG_FILE."
    # This is a fallback, ideally it's in php_module.conf
    if ! grep -Fxq "$PHP_MODULE_LINE" "$APACHE_CONFIG_FILE"; then
      sudo sed -i '/^LoadModule/ { h; s/.*/&\n'"$PHP_MODULE_LINE"'/ } ; $ { x; s/^\n//; p; x; }' "$APACHE_CONFIG_FILE"
    fi
fi

# Include PHP module configuration file (php_module.conf) if not already included
PHP_MODULE_INCLUDE_LINE="Include conf/extra/php_module.conf"
if [ -f "$PHP_MODULE_CONF_EXTRA" ]; then
    if ! grep -Fxq "$PHP_MODULE_INCLUDE_LINE" "$APACHE_CONFIG_FILE"; then
        echo "Including $PHP_MODULE_INCLUDE_LINE in $APACHE_CONFIG_FILE..."
        echo "$PHP_MODULE_INCLUDE_LINE" | sudo tee -a "$APACHE_CONFIG_FILE" > /dev/null
    else
        echo "$PHP_MODULE_INCLUDE_LINE already present in $APACHE_CONFIG_FILE."
    fi
else
    echo "Warning: PHP module configuration file $PHP_MODULE_CONF_EXTRA not found."
fi


# --- PHP Configuration (php.ini) ---
PHP_INI_FILE="/etc/php/php.ini"
if [ ! -f "$PHP_INI_FILE" ]; then
    echo "Error: PHP configuration file '$PHP_INI_FILE' not found."
    # PHP might create it on first run or it might be an installation issue.
    # Forcing a restart of php-fpm if it exists, or Apache might help generate it.
    # However, if basic php install failed, this will also fail.
    exit 1
fi

echo "Configuring PHP settings in $PHP_INI_FILE..."

# Set timezone (example, adjust as needed)
echo "Setting timezone (e.g., America/Argentina/Buenos_Aires)..."
sudo sed -i 's#;date.timezone =.*#date.timezone = America/Argentina/Buenos_Aires#' "$PHP_INI_FILE"

# Enable error display (for development, disable on production)
echo "Enabling display_errors for development..."
sudo sed -i 's/^display_errors = Off/display_errors = On/' "$PHP_INI_FILE"
sudo sed -i 's/^display_errors = Off/display_errors = On/' "$PHP_INI_FILE" # Ensure it's On

# Enable common extensions
echo "Enabling common PHP extensions (gd, zip, pdo_mysql, mysqli)..."
sudo sed -i 's/;extension=gd/extension=gd/' "$PHP_INI_FILE"
sudo sed -i 's/;extension=zip/extension=zip/' "$PHP_INI_FILE"
sudo sed -i 's/;extension=pdo_mysql/extension=pdo_mysql/' "$PHP_INI_FILE"
sudo sed -i 's/;extension=mysqli/extension=mysqli/' "$PHP_INI_FILE"

# Configure open_basedir (adjust paths as needed for your environment)
# This is a security measure. Ensure paths are correct for your web server's DocumentRoot and other needs.
echo "Configuring open_basedir..."
OPEN_BASEDIR_PATHS="/srv/http/:/var/www/:/home/:/tmp/:/var/tmp/:/var/cache/:/usr/share/pear/:/usr/share/webapps/:/etc/webapps/"
sudo sed -i "s#;open_basedir =.*#open_basedir = ${OPEN_BASEDIR_PATHS}#" "$PHP_INI_FILE"

# --- Create PHP Test File ---
# Try to get DocumentRoot from Apache config, default to /srv/http
document_root=$(grep -i '^DocumentRoot' "$APACHE_CONFIG_FILE" | awk -F'"' '{print $2}' | head -n 1)
document_root=${document_root:-"/srv/http"} # Default if not found

PHP_TEST_FILE="${document_root}/info.php" # Changed name to info.php for clarity
echo "Creating PHP test file at $PHP_TEST_FILE..."
if [ ! -d "$document_root" ]; then
    echo "DocumentRoot '$document_root' does not exist. Creating it..."
    sudo mkdir -p "$document_root"
    sudo chown http:http "$document_root" # Ensure Apache user owns it
fi
echo "<?php phpinfo(); ?>" | sudo tee "$PHP_TEST_FILE" > /dev/null
echo "PHP test file created. Owner: $(stat -c %U:%G $PHP_TEST_FILE)"


# --- Restart Apache ---
echo "Restarting Apache to apply PHP configuration..."
if sudo systemctl restart httpd; then
    echo "Apache restarted successfully."
else
    echo "Failed to restart Apache. Check 'systemctl status httpd' and 'journalctl -xeu httpd' for errors."
    exit 1
fi

echo "----------------------------------------------------"
echo "PHP installation and Apache integration complete."
echo "You can test it by visiting http://localhost/$(basename $PHP_TEST_FILE) in your browser."
echo "Make sure Apache is serving from '$document_root'."
echo "----------------------------------------------------"
