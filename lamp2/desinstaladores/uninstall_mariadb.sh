#!/bin/bash

echo "Desinstalando MariaDB..."

# Detener y deshabilitar el servicio MariaDB
systemctl stop mariadb
systemctl disable mariadb

# Desinstalar MariaDB
pacman -Rns --noconfirm mariadb

# Eliminar archivos de datos y configuración
rm -rf /var/lib/mysql
rm -rf /etc/mysql

# Eliminar el archivo de configuración en /etc/my.cnf.d/
rm -f /etc/my.cnf.d/server.cnf

# Eliminar el archivo de override del servicio
rm -f /etc/systemd/system/mariadb.service.d/override.conf

echo "MariaDB ha sido desinstalado y limpiado correctamente."
