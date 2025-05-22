#!/bin/bash
# This script installs and configures Apache HTTP Server.

# Exit immediately if a command exits with a non-zero status.
set -e

echo "Starting Apache HTTP Server Installation and Configuration..."
echo "--------------------------------------------------------"

# Ensure the script is run with superuser privileges
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run with superuser privileges (e.g., using sudo)."
    exit 1
fi

# --- Apache Installation ---
if ! command -v httpd &> /dev/null; then
    echo "Apache not found. Installing Apache..."
    if sudo pacman -Syu --noconfirm apache; then
        echo "Apache installed successfully."
    else
        echo "Failed to install Apache. Please check pacman output."
        exit 1
    fi
    echo "Enabling and starting Apache service..."
    if sudo systemctl enable httpd && sudo systemctl start httpd; then
        echo "Apache service enabled and started."
    else
        echo "Failed to enable or start Apache service."
        exit 1
    fi
else
    apache_version=$(httpd -v | awk 'NR==1 {print $3}')
    echo "Apache $apache_version is already installed."
    # Ensure service is running
    if ! systemctl is-active --quiet httpd; then
        echo "Apache service is not active. Starting it..."
        sudo systemctl start httpd
    fi
fi

# --- Basic Apache Configuration ---
APACHE_CONFIG_FILE="/etc/httpd/conf/httpd.conf"

if [ ! -f "$APACHE_CONFIG_FILE" ]; then
    echo "Error: Apache configuration file '$APACHE_CONFIG_FILE' not found."
    exit 1
fi

echo "Configuring Apache settings in $APACHE_CONFIG_FILE..."

# Set User and Group
echo "Setting User and Group to 'http'..."
sudo sed -i 's/^User .*/User http/' "$APACHE_CONFIG_FILE"
sudo sed -i 's/^Group .*/Group http/' "$APACHE_CONFIG_FILE"

# Configure Listen Port
read -p "Enter Apache Listen Port (default: 80): " listen_port
listen_port=${listen_port:-"80"}
echo "Setting Listen port to $listen_port..."
sudo sed -i "s/^Listen .*/Listen $listen_port/" "$APACHE_CONFIG_FILE"

# Configure ServerAdmin
read -p "Enter Server Admin Email (default: you@example.com): " admin_email
admin_email=${admin_email:-"you@example.com"}
echo "Setting ServerAdmin to $admin_email..."
sudo sed -i "s/^ServerAdmin .*/ServerAdmin $admin_email/" "$APACHE_CONFIG_FILE"

# Configure DocumentRoot
read -p "Enter DocumentRoot (default: /srv/http): " document_root
document_root=${document_root:-"/srv/http"}
echo "Setting DocumentRoot to $document_root..."
# Create the directory if it doesn't exist
sudo mkdir -p "$document_root"
sudo chown http:http "$document_root" # Ensure http user owns it
sudo sed -i "s|^DocumentRoot \".*\"|DocumentRoot \"$document_root\"|" "$APACHE_CONFIG_FILE"
# Update the corresponding Directory block
# This assumes the old DocumentRoot was /srv/http. A more robust sed might be needed if it could be anything.
sudo sed -i "s|<Directory \"/srv/http\">|<Directory \"$document_root\">|" "$APACHE_CONFIG_FILE"
echo "Ensuring 'Require all granted' for DocumentRoot..."
# This is a common setting for local development. Be cautious on production.
sudo sed -i "/<Directory \"${document_root//\//\\\/}\">/,/<\/Directory>/ s/Require all denied/Require all granted/" "$APACHE_CONFIG_FILE"


# Configure AllowOverride for .htaccess files
echo "Setting AllowOverride to All for $document_root..."
sudo sed -i "/<Directory \"${document_root//\//\\\/}\">/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/" "$APACHE_CONFIG_FILE"


# Harden server signature and tokens
echo "Setting ServerSignature Off and ServerTokens Prod for security..."
sudo sed -i 's/^ServerSignature .*/ServerSignature Off/' "$APACHE_CONFIG_FILE"
sudo sed -i 's/^ServerTokens .*/ServerTokens Prod/' "$APACHE_CONFIG_FILE"

# --- Include Optional Configurations ---

# Include phpMyAdmin configuration if it exists
PHPADMIN_CONF_EXTRA="/etc/httpd/conf/extra/phpmyadmin.conf"
if [ -f "$PHPADMIN_CONF_EXTRA" ]; then
    if ! grep -q "Include conf/extra/phpmyadmin.conf" "$APACHE_CONFIG_FILE"; then
        echo "Including phpMyAdmin configuration..."
        echo "Include conf/extra/phpmyadmin.conf" | sudo tee -a "$APACHE_CONFIG_FILE" > /dev/null
    fi
fi

# Enable user directories if httpd-userdir.conf exists
USERDIR_CONF_EXTRA="/etc/httpd/conf/extra/httpd-userdir.conf"
if [ -f "$USERDIR_CONF_EXTRA" ]; then
    if ! grep -q "Include conf/extra/httpd-userdir.conf" "$APACHE_CONFIG_FILE"; then
        echo "Enabling user directories (Include conf/extra/httpd-userdir.conf)..."
        echo "Include conf/extra/httpd-userdir.conf" | sudo tee -a "$APACHE_CONFIG_FILE" > /dev/null
    fi
fi

# Enable SSL/TLS configuration if httpd-ssl.conf exists
SSL_CONF_EXTRA="/etc/httpd/conf/extra/httpd-ssl.conf"
if [ -f "$SSL_CONF_EXTRA" ]; then
    echo "Enabling SSL/TLS modules and configuration..."
    # Uncomment SSL module loading
    sudo sed -i 's/^#\(LoadModule ssl_module modules\/mod_ssl.so\)/\1/' "$APACHE_CONFIG_FILE"
    sudo sed -i 's/^#\(LoadModule socache_shmcb_module modules\/mod_socache_shmcb.so\)/\1/' "$APACHE_CONFIG_FILE" # Arch specific name
    # Include SSL config
    if ! grep -q "Include conf/extra/httpd-ssl.conf" "$APACHE_CONFIG_FILE"; then
         echo "Include conf/extra/httpd-ssl.conf" | sudo tee -a "$APACHE_CONFIG_FILE" > /dev/null
    fi
else
    echo "SSL configuration ($SSL_CONF_EXTRA) not found. Skipping SSL setup."
fi

# --- Restart Apache ---
echo "Restarting Apache to apply changes..."
if sudo systemctl restart httpd; then
    echo "Apache restarted successfully."
else
    echo "Failed to restart Apache. Check 'systemctl status httpd' and 'journalctl -xeu httpd' for errors."
    exit 1
fi

echo "--------------------------------------------------------"
echo "Apache HTTP Server installation and configuration complete."
echo "You can test it by visiting http://localhost:$listen_port in your browser."
if [ -f "${document_root}/index.html" ]; then
    echo "An index.html file exists in your DocumentRoot."
else
    echo "Consider creating an index.html in $document_root for testing."
fi
echo "--------------------------------------------------------"


