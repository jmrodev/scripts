#!/bin/bash

echo "Desinstalando phpMyAdmin..."

# Desinstalar phpMyAdmin si está instalado
if pacman -Qi phpmyadmin &> /dev/null; then
    pacman -Rns --noconfirm phpmyadmin
else
    echo "phpMyAdmin no está instalado."
fi

# Eliminar archivo de configuración de Apache para phpMyAdmin si existe
if [ -f /etc/httpd/conf/extra/phpmyadmin.conf ]; then
    rm -f /etc/httpd/conf/extra/phpmyadmin.conf
fi

# Eliminar la línea de inclusión en httpd.conf si el archivo existe
if [ -f /etc/httpd/conf/httpd.conf ]; then
    sed -i '/Include conf\/extra\/phpmyadmin.conf/d' /etc/httpd/conf/httpd.conf
fi

# Reiniciar Apache si está instalado y activo
if systemctl is-active --quiet httpd; then
    systemctl restart httpd
fi

echo "phpMyAdmin ha sido desinstalado y limpiado correctamente."
