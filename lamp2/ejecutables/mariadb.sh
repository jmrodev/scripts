#!/bin/bash

echo "Instalando y configurando MariaDB..."

# Verificar si el usuario tiene privilegios de superusuario
if [ "$(id -u)" != "0" ]; then
    echo "Este script debe ejecutarse con privilegios de superusuario (root)."
    exit 1
fi

# Instalar MariaDB
if ! pacman -Qi mariadb > /dev/null; then
    echo "Instalando MariaDB..."
    sudo pacman -Syu --noconfirm mariadb mariadb-clients
else
    echo "MariaDB ya está instalado."
fi

# Inicializar el directorio de datos de MariaDB
echo "Inicializando el directorio de datos de MariaDB..."
sudo mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql

# Configurar archivo de servicio suplementario para MariaDB
echo "Configurando archivo de servicio suplementario para MariaDB..."
sudo mkdir -p /etc/systemd/system/mariadb.service.d
echo -e "[Service]\nProtectHome=false" | sudo tee /etc/systemd/system/mariadb.service.d/override.conf

# Iniciar y habilitar el servicio de MariaDB
echo "Iniciando y habilitando el servicio de MariaDB..."
sudo systemctl start mariadb
sudo systemctl enable mariadb

# Asegurar la instalación de MariaDB
echo "Asegurando la instalación de MariaDB..."
sudo mariadb-secure-installation

# Crear un nuevo usuario y otorgar privilegios
echo "Creando un nuevo usuario de MariaDB..."
read -p "Ingrese el nombre de usuario: " username
read -sp "Ingrese la contraseña: " password
echo
sudo mariadb -u root -e "CREATE USER '$username'@'localhost' IDENTIFIED BY '$password';"
sudo mariadb -u root -e "GRANT ALL PRIVILEGES ON *.* TO '$username'@'localhost';"
sudo mariadb -u root -e "FLUSH PRIVILEGES;"
echo "Usuario '$username' creado y privilegios otorgados."

# Crear archivo de configuración en /etc/my.cnf.d/
echo "Creando archivo de configuración de MariaDB..."
sudo mkdir -p /etc/my.cnf.d
echo "[mariadb]" | sudo tee /etc/my.cnf.d/server.cnf
echo "datadir=/var/lib/mysql" | sudo tee -a /etc/my.cnf.d/server.cnf

# Configurar MariaDB para escuchar solo en localhost
echo "Configurando MariaDB para escuchar solo en localhost..."
sudo tee -a /etc/my.cnf.d/server.cnf > /dev/null <<EOL
[mariadb]
bind-address = localhost
EOL

# Reiniciar MariaDB para aplicar cambios
sudo systemctl restart mariadb

echo "MariaDB ha sido instalado y configurado correctamente."
