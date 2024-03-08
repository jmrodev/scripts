#!/bin/bash

# Verificar si el usuario tiene privilegios de superusuario (root)
if [ "$(id -u)" != "0" ]; then
    echo "Este script debe ejecutarse con privilegios de superusuario (root)."

    # Solicitar al usuario que ingrese su contraseña para ejecutar el script con sudo
    echo "Por favor, vuelva a ejecutar este script con sudo:"
    sudo "$0" "$@"  # Ejecutar este script nuevamente con sudo

    # Salir del script actual
    exit 0
fi

check_package_installed() {
    package_name=$1
    if pacman -Qs "$package_name" &> /dev/null; then
        echo "El paquete '$package_name' ya está instalado."
    else
        echo "El paquete '$package_name' no está instalado."
        read -p "¿Desea instalar '$package_name'? (Sí/No): " response
        case "$response" in
            [Ss][Íí]|[Ss][Ii]|[Yy][Ee][Ss]) sudo pacman -S --noconfirm "$package_name" ;;
            *) echo "No se puede continuar sin el paquete '$package_name' instalado." ; exit 1 ;;
        esac
    fi
}

# Verificar si el paquete mariadb está instalado
check_package_installed "mariadb"

read -r -p "¿Desea configurar MariaDB? (Sí/No): " config_response
case "$config_response" in
    [Ss][Íí]|[Ss][Ii]|[Yy][Ee][Ss])
        echo "Continua..."
        ;;
    *)
        echo "Saliendo del script."
        exit 0
        ;;
esac

# Initialize MariaDB data directory
sudo mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql

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
read -r -p "Enter username: " username
read -r -sp "Enter password: " password
sudo mariadb -u root -e "CREATE USER '$username'@'localhost' IDENTIFIED BY '$password';"
sudo mariadb -u root -e "GRANT ALL PRIVILEGES ON *.* TO '$username'@'localhost';"
echo "User '$username' created and granted privileges."

# Create configuration file in /etc/my.cnf.d/ directory
# echo "Creating MariaDB configuration file..."
# echo "[mariadb]" | sudo tee /etc/my.cnf.d/server.cnf
# echo "datadir=/var/lib/mysql" | sudo tee -a /etc/my.cnf.d/server.cnf

echo "MariaDB setup complete."
