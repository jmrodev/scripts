#!/bin/bash

echo "Desinstalando phpMyAdmin..."

# Desinstalar phpMyAdmin
pacman -Rns --noconfirm phpmyadmin

# Eliminar archivo de configuración de Apache para phpMyAdmin
rm -f /etc/httpd/conf/extra/phpmyadmin.conf

# Eliminar la línea de inclusión en httpd.conf
if [ -f /etc/httpd/conf/httpd.conf ]; then
    sed -i '/Include conf\/extra\/phpmyadmin.conf/d' /etc/httpd/conf/httpd.conf
fi

# Reiniciar Apache si está instalado
if systemctl is-active --quiet httpd; then
    systemctl restart httpd
fi

echo "phpMyAdmin ha sido desinstalado y limpiado correctamente."
