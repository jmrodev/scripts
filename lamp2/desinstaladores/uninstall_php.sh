#!/bin/bash

echo "Desinstalando PHP y sus extensiones..."

# Función para desinstalar un paquete si está instalado
desinstalar_si_existe() {
    if pacman -Qi "$1" &> /dev/null; then
        echo "Desinstalando $1..."
        pacman -Rns --noconfirm "$1"
    else
        echo "$1 no está instalado. Omitiendo."
    fi
}

# Lista de paquetes PHP a desinstalar
paquetes_php=(
    "php" "php-gd" "php-imagick" "php-redis" "php-pgsql" "php-sqlite" 
    "php-apcu" "php-intl" "php-xdebug" "php-apache"
)

# Desinstalar cada paquete PHP
for paquete in "${paquetes_php[@]}"; do
    desinstalar_si_existe "$paquete"
done

# Eliminar archivos de configuración
rm -rf /etc/php

# Eliminar el archivo test.php si existe
rm -f /srv/http/test.php

# Eliminar test.php del directorio public_html del usuario
if [ -n "$SUDO_USER" ]; then
    rm -f "/home/$SUDO_USER/public_html/test.php"
fi

# Revertir cambios en la configuración de Apache
if [ -f /etc/httpd/conf/httpd.conf ]; then
    sed -i '/LoadModule php_module modules\/libphp.so/d' /etc/httpd/conf/httpd.conf
    sed -i '/Include conf\/extra\/php_module.conf/d' /etc/httpd/conf/httpd.conf
    if systemctl is-active --quiet httpd; then
        systemctl restart httpd
    fi
fi

echo "PHP y sus extensiones han sido desinstalados y limpiados correctamente."