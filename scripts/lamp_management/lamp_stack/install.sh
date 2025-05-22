#!/bin/bash

# Ruta al directorio de ejecutables
# This ensures that the script can find the other scripts in the 'ejecutables' directory,
# regardless of where 'install.sh' is called from.
EJECUTABLES_DIR="$(dirname "$(readlink -f "$0")")/ejecutables"

echo "Starting LAMP stack installation..."

# --- Install Apache ---
echo "Running Apache installation script..."
if "$EJECUTABLES_DIR/apache.sh"; then
    echo "Apache installation script completed successfully."
else
    echo "Error during Apache installation. Please check the output above."
    exit 1 # Exit if a critical step fails
fi

# --- Install MariaDB ---
echo "Running MariaDB installation script..."
if "$EJECUTABLES_DIR/mariadb.sh"; then
    echo "MariaDB installation script completed successfully."
else
    echo "Error during MariaDB installation. Please check the output above."
    exit 1
fi

# --- Install phpMyAdmin ---
# Note: phpMyAdmin typically depends on Apache and PHP, so it's installed after them.
echo "Running phpMyAdmin installation script..."
if "$EJECUTABLES_DIR/phpmyadmin.sh"; then
    echo "phpMyAdmin installation script completed successfully."
else
    echo "Error during phpMyAdmin installation. Please check the output above."
    exit 1
fi

# --- Install PHP ---
echo "Running PHP installation script..."
if "$EJECUTABLES_DIR/php.sh"; then
    echo "PHP installation script completed successfully."
else
    echo "Error during PHP installation. Please check the output above."
    exit 1
fi

echo "LAMP stack installation and configuration process completed."
echo "Please check the output of each step for any potential issues."
