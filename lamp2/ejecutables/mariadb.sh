#!/bin/bash

# Install MariaDB on Arch Linux
echo "Installing MariaDB..."
sudo pacman -S mariadb

# Initialize MariaDB data directory
echo "Initializing MariaDB data directory..."
sudo mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql

# Configure supplementary service file for MariaDB
echo "Configuring supplementary service file for MariaDB..."
echo -e "[Service]\nProtectHome=false" | sudo tee /etc/systemd/system/mariadb.service.d/override.conf

# Start and enable MariaDB service
echo "Starting and enabling MariaDB service..."

sudo systemctl start mariadb
sudo systemctl enable mariadb

# Secure MariaDB installation
echo "Securing MariaDB installation..."
sudo mariadb-secure-installation

# Populate time zone tables
#echo "Populating time zone tables..."
#sudo mariadb-tzinfo-to-sql /usr/share/zoneinfo | sudo mariadb -u root -p mysql

# Create a new user and grant privileges
echo "Creating a new MariaDB user..."
read -p "Enter username: " username
read -sp "Enter password: " password
sudo mariadb -u root -e "CREATE USER '$username'@'localhost' IDENTIFIED BY '$password';"
sudo mariadb -u root -e "GRANT ALL PRIVILEGES ON *.* TO '$username'@'localhost';"
echo "User '$username' created and granted privileges."

# Create configuration file in /etc/my.cnf.d/ directory
echo "Creating MariaDB configuration file..."
echo "[mariadb]" | sudo tee /etc/my.cnf.d/server.cnf
echo "datadir=/var/lib/mysql" | sudo tee -a /etc/my.cnf.d/server.cnf

echo "MariaDB setup complete."
