#!/bin/bash
# This script installs and configures phpMyAdmin.

# Exit immediately if a command exits with a non-zero status.
set -e

echo "Starting phpMyAdmin Installation and Configuration..."
echo "-----------------------------------------------------"

# Ensure the script is run with superuser privileges
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run with superuser privileges (e.g., using sudo)."
    exit 1
fi

# --- phpMyAdmin Installation ---
if ! pacman -Qi phpmyadmin &> /dev/null; then
    echo "phpMyAdmin not found. Installing phpMyAdmin..."
    if sudo pacman -Syu --noconfirm phpmyadmin; then
        echo "phpMyAdmin installed successfully."
    else
        echo "Failed to install phpMyAdmin. Please check pacman output."
        exit 1
    fi
else
    echo "phpMyAdmin is already installed."
fi

# --- PHP Configuration for phpMyAdmin ---
PHP_INI_FILE="/etc/php/php.ini"
if [ ! -f "$PHP_INI_FILE" ]; then
    echo "Error: PHP configuration file '$PHP_INI_FILE' not found. Ensure PHP is installed and configured."
    exit 1
fi

echo "Configuring PHP extensions for phpMyAdmin in $PHP_INI_FILE..."
# Enable necessary PHP extensions (bz2 is common, mysqli should be enabled by php.sh already)
sudo sed -i 's/;extension=bz2/extension=bz2/' "$PHP_INI_FILE"
sudo sed -i 's/;extension=zip/extension=zip/' "$PHP_INI_FILE" # Often needed for import/export
# Ensure mysqli is enabled, as it's critical for phpMyAdmin
if ! grep -q "^extension=mysqli" "$PHP_INI_FILE"; then
    echo "Enabling mysqli extension in $PHP_INI_FILE..."
    sudo sed -i 's/;extension=mysqli/extension=mysqli/' "$PHP_INI_FILE"
fi


# Configure open_basedir in php.ini to include phpMyAdmin paths
# This is important for security and functionality.
# The paths /usr/share/webapps/ and /etc/webapps/ are common for phpMyAdmin on Arch.
echo "Updating open_basedir in $PHP_INI_FILE for phpMyAdmin..."
PMA_PATHS=":/usr/share/webapps/:/etc/webapps/" # Note leading colon if appending
# This sed command tries to append to an existing open_basedir or create a new one.
# It's complex due to the variability of existing open_basedir settings.
if grep -q "^open_basedir" "$PHP_INI_FILE"; then
    # If open_basedir is set and not commented out
    sudo sed -i -E "s#^(open_basedir\s*=\s*)(.*)#\1\2${PMA_PATHS}#" "$PHP_INI_FILE"
else
    # If open_basedir is commented out or not present, add it
    # This might need adjustment if other paths are expected from php.sh
    echo "open_basedir = ${PMA_PATHS#/}" | sudo tee -a "$PHP_INI_FILE" > /dev/null
fi


# --- Apache Configuration for phpMyAdmin ---
APACHE_PMA_CONF="/etc/httpd/conf/extra/phpmyadmin.conf"
APACHE_CONFIG_FILE="/etc/httpd/conf/httpd.conf"

echo "Creating Apache configuration for phpMyAdmin at $APACHE_PMA_CONF..."
# Standard phpMyAdmin Apache configuration
sudo tee "$APACHE_PMA_CONF" > /dev/null <<EOL
Alias /phpmyadmin "/usr/share/webapps/phpMyAdmin"
<Directory "/usr/share/webapps/phpMyAdmin">
    DirectoryIndex index.php
    AllowOverride All
    Options FollowSymLinks
    Require all granted
    # For Apache 2.4, ensure mod_authz_core is loaded
</Directory>
EOL
echo "phpMyAdmin Apache config file created."

# Include phpMyAdmin's Apache config in the main Apache config file if not already present
PMA_APACHE_INCLUDE_LINE="Include conf/extra/phpmyadmin.conf"
if ! grep -Fxq "$PMA_APACHE_INCLUDE_LINE" "$APACHE_CONFIG_FILE"; then
    echo "Including $APACHE_PMA_CONF in $APACHE_CONFIG_FILE..."
    echo "$PMA_APACHE_INCLUDE_LINE" | sudo tee -a "$APACHE_CONFIG_FILE" > /dev/null
else
    echo "$APACHE_PMA_CONF already included in $APACHE_CONFIG_FILE."
fi

# --- phpMyAdmin Temporary Configuration Directory and Blowfish Secret ---
PMA_WEBAPP_DIR="/usr/share/webapps/phpMyAdmin"
PMA_CONFIG_INC="$PMA_WEBAPP_DIR/config.inc.php"

# phpMyAdmin requires a blowfish_secret for cookie authentication.
# It can be auto-generated or manually set in config.inc.php.
if [ ! -f "$PMA_CONFIG_INC" ]; then
    echo "phpMyAdmin config.inc.php not found. Copying sample..."
    if [ -f "$PMA_WEBAPP_DIR/config.sample.inc.php" ]; then
        sudo cp "$PMA_WEBAPP_DIR/config.sample.inc.php" "$PMA_CONFIG_INC"
        sudo chown http:http "$PMA_CONFIG_INC" # Ensure http user can read it
        sudo chmod 640 "$PMA_CONFIG_INC"      # Restrict permissions
    else
        echo "Error: phpMyAdmin sample config not found. Cannot create config.inc.php."
        # This might mean the phpMyAdmin package is incomplete or changed.
        exit 1
    fi
fi

echo "Ensuring blowfish_secret is set in $PMA_CONFIG_INC..."
if ! grep -q "\$cfg\['blowfish_secret'\]" "$PMA_CONFIG_INC"; then
    echo "Adding new blowfish_secret to $PMA_CONFIG_INC..."
    local random_blowfish=$(openssl rand -base64 32)
    # Ensure the secret is properly quoted and escaped for sed
    sudo sed -i "/^\/\* vim: set expandtab sw=4 ts=4 sts=4: \*\//a \$cfg['blowfish_secret'] = '$random_blowfish';" "$PMA_CONFIG_INC"
else
    echo "Blowfish_secret already seems to be present in $PMA_CONFIG_INC."
    # Optionally, one could regenerate it if it's the default placeholder from sample.
fi

# Some guides mention creating a /config directory for setup, then removing.
# Modern phpMyAdmin usually handles this internally or via config.inc.php directly.
# The original script had this, so let's ensure it's handled if needed, though it might be obsolete.
PMA_TEMP_CONFIG_DIR="$PMA_WEBAPP_DIR/config"
if [ -d "$PMA_TEMP_CONFIG_DIR" ]; then
    echo "Removing temporary phpMyAdmin config directory $PMA_TEMP_CONFIG_DIR (if it exists and is empty)..."
    # Only remove if it's empty and owned by http, to be safe
    if [ "$(ls -A $PMA_TEMP_CONFIG_DIR)" ]; then
        echo "Warning: $PMA_TEMP_CONFIG_DIR is not empty. Manual review may be needed."
    else
        sudo rmdir "$PMA_TEMP_CONFIG_DIR" || echo "Could not remove $PMA_TEMP_CONFIG_DIR, or it didn't exist."
    fi
fi
# Ensure correct permissions for PMA directory
sudo chown -R http:http "$PMA_WEBAPP_DIR"
sudo find "$PMA_WEBAPP_DIR" -type d -exec chmod 750 {} \;
sudo find "$PMA_WEBAPP_DIR" -type f -exec chmod 640 {} \;


# --- Restart Apache ---
echo "Restarting Apache to apply phpMyAdmin configuration..."
if sudo systemctl restart httpd; then
    echo "Apache restarted successfully."
else
    echo "Failed to restart Apache. Check 'systemctl status httpd' and 'journalctl -xeu httpd' for errors."
    # This is critical for phpMyAdmin to work.
    exit 1
fi

echo "-----------------------------------------------------"
echo "phpMyAdmin installation and configuration complete."
echo "You should be able to access it at http://localhost/phpmyadmin"
echo "Login with your MariaDB credentials."
echo "-----------------------------------------------------"
