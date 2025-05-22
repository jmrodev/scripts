#!/bin/bash
# This script installs and configures MariaDB.

# Exit immediately if a command exits with a non-zero status.
set -e

echo "Starting MariaDB Installation and Configuration..."
echo "-------------------------------------------------"

# Ensure the script is run with superuser privileges
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run with superuser privileges (e.g., using sudo)."
    exit 1
fi

# --- MariaDB Installation ---
if ! pacman -Qi mariadb &> /dev/null; then
    echo "MariaDB not found. Installing MariaDB and client..."
    if sudo pacman -Syu --noconfirm mariadb mariadb-clients; then
        echo "MariaDB installed successfully."
    else
        echo "Failed to install MariaDB. Please check pacman output."
        exit 1
    fi
else
    echo "MariaDB is already installed."
fi

# --- Initialize MariaDB Data Directory ---
# This step is crucial if MariaDB was just installed.
# It should only be run once. If /var/lib/mysql already has data, this might cause issues or do nothing.
# A better check would be to see if /var/lib/mysql is empty or doesn't exist.
if [ ! -d "/var/lib/mysql/mysql" ]; then # Check for a common subdirectory within datadir
    echo "Initializing MariaDB data directory..."
    if sudo mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql; then
        echo "MariaDB data directory initialized."
    else
        echo "Failed to initialize MariaDB data directory."
        exit 1
    fi
else
    echo "MariaDB data directory already seems to exist. Skipping initialization."
fi


# --- Configure MariaDB Service Override (Optional but good practice for some setups) ---
SERVICE_OVERRIDE_DIR="/etc/systemd/system/mariadb.service.d"
SERVICE_OVERRIDE_FILE="$SERVICE_OVERRIDE_DIR/override.conf"
echo "Configuring MariaDB service override (ProtectHome=false)..."
sudo mkdir -p "$SERVICE_OVERRIDE_DIR"
# Using printf for potentially complex content is safer than echo -e
if sudo printf "[Service]\nProtectHome=false\n" > "$SERVICE_OVERRIDE_FILE"; then
    echo "Service override configured."
    sudo systemctl daemon-reload # Reload systemd to recognize the change
else
    echo "Failed to configure service override."
    # Not exiting, as this might not be critical for all users
fi


# --- Start and Enable MariaDB Service ---
echo "Starting and enabling MariaDB service..."
if sudo systemctl enable mariadb && sudo systemctl start mariadb; then
    echo "MariaDB service enabled and started."
else
    echo "Failed to enable or start MariaDB service. Check 'systemctl status mariadb' and 'journalctl -xeu mariadb'."
    exit 1
fi

# --- Secure MariaDB Installation ---
echo "Securing MariaDB installation (mariadb-secure-installation)..."
echo "Please follow the prompts. It is recommended to set a root password, remove anonymous users, disallow remote root login, and remove the test database."
if sudo mariadb-secure-installation; then
    echo "MariaDB security script completed."
else
    echo "mariadb-secure-installation encountered an issue. Please review the output."
    # Not exiting, as user might have manually handled it or wants to proceed.
fi

# --- Create a New MariaDB User (Optional) ---
read -p "Do you want to create a new MariaDB user? (y/N): " create_new_user
if [[ "$create_new_user" =~ ^[Yy]$ ]]; then
    echo "Creating a new MariaDB user..."
    read -p "Enter username for the new MariaDB user: " db_username
    read -sp "Enter password for $db_username: " db_password
    echo
    read -sp "Confirm password for $db_username: " db_password_confirm
    echo
    if [ "$db_password" != "$db_password_confirm" ]; then
        echo "Passwords do not match. Skipping user creation."
    elif [ -z "$db_username" ] || [ -z "$db_password" ]; then
        echo "Username or password cannot be empty. Skipping user creation."
    else
        echo "Creating user '$db_username' and granting all privileges on *.* (localhost only)..."
        # Ensure to use quotes around SQL string variables and escape if necessary, though here it's simple.
        if sudo mariadb -u root -e "CREATE USER '$db_username'@'localhost' IDENTIFIED BY '$db_password'; GRANT ALL PRIVILEGES ON *.* TO '$db_username'@'localhost' WITH GRANT OPTION; FLUSH PRIVILEGES;"; then
            echo "User '$db_username' created and privileges granted successfully."
        else
            echo "Failed to create MariaDB user '$db_username'. It might already exist or there was another issue."
        fi
    fi
fi

# --- MariaDB Configuration File (my.cnf or server.cnf) ---
MARIADB_CONFIG_DIR="/etc/my.cnf.d"
MARIADB_SERVER_CONFIG_FILE="$MARIADB_CONFIG_DIR/server.cnf" # Common practice for Arch-based systems

echo "Ensuring MariaDB configuration directory exists: $MARIADB_CONFIG_DIR..."
sudo mkdir -p "$MARIADB_CONFIG_DIR"

# Add basic configuration if file doesn't exist or is empty
# A more robust approach would be to check for specific settings.
echo "Setting basic MariaDB configuration in $MARIADB_SERVER_CONFIG_FILE..."
# This creates/overwrites with a minimal config. Be careful if there's an existing complex config.
# For this script, we assume it's a fresh setup or simple override.
sudo bash -c "cat > $MARIADB_SERVER_CONFIG_FILE" <<EOL
[mariadb]
datadir=/var/lib/mysql
# bind-address = localhost # Uncomment to restrict to localhost only
# Other settings can be added here, e.g., character sets, buffer sizes
EOL
echo "Basic MariaDB configuration written."

# Example: Configure MariaDB to listen only on localhost (more secure for typical LAMP)
read -p "Do you want to configure MariaDB to listen only on localhost (recommended for security)? (Y/n): " bind_localhost
if [[ ! "$bind_localhost" =~ ^[Nn]$ ]]; then
    echo "Configuring MariaDB to bind to localhost..."
    # Check if bind-address is already set
    if grep -q "^bind-address" "$MARIADB_SERVER_CONFIG_FILE"; then
        sudo sed -i 's/^bind-address.*/bind-address = localhost/' "$MARIADB_SERVER_CONFIG_FILE"
    else # Add it under [mariadb]
        sudo sed -i '/^\[mariadb\]/a bind-address = localhost' "$MARIADB_SERVER_CONFIG_FILE"
    fi
    echo "bind-address set to localhost."
fi


# --- Restart MariaDB to Apply Changes ---
echo "Restarting MariaDB to apply configuration changes..."
if sudo systemctl restart mariadb; then
    echo "MariaDB restarted successfully."
else
    echo "Failed to restart MariaDB. Check 'systemctl status mariadb' and 'journalctl -xeu mariadb'."
    # Not exiting, but this is a significant issue.
fi

echo "-------------------------------------------------"
echo "MariaDB installation and configuration complete."
echo "Remember the root password you set during mariadb-secure-installation."
if [[ "$create_new_user" =~ ^[Yy]$ ]] && [ -n "$db_username" ]; then
    echo "User '$db_username' was also created (if successful)."
fi
echo "-------------------------------------------------"
