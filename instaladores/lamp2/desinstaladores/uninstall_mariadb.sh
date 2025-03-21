#!/bin/bash

echo "Desinstalando MariaDB..."

# Comprobar si el servicio MariaDB está activo antes de detenerlo
if systemctl is-active --quiet mariadb; then
    systemctl stop mariadb
    systemctl disable mariadb
fi

# Desinstalar MariaDB
pacman -Rns --noconfirm mariadb

# Eliminar archivos de datos y configuración solo si existen
[ -d /var/lib/mysql ] && rm -rf /var/lib/mysql
[ -d /etc/mysql ] && rm -rf /etc/mysql

# Eliminar el archivo de configuración en /etc/my.cnf.d/ solo si existe
[ -f /etc/my.cnf.d/server.cnf ] && rm -f /etc/my.cnf.d/server.cnf

# Eliminar el archivo de override del servicio solo si existe
[ -f /etc/systemd/system/mariadb.service.d/override.conf ] && rm -f /etc/systemd/system/mariadb.service.d/override.conf

echo "MariaDB ha sido desinstalado y limpiado correctamente."
