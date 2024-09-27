#!/bin/bash

echo "Desinstalando Apache..."

# Función para desinstalar un paquete si está instalado
desinstalar_si_existe() {
    if pacman -Qi "$1" &> /dev/null; then
        echo "Desinstalando $1..."
        pacman -Rns --noconfirm "$1"
    else
        echo "$1 no está instalado. Omitiendo."
    fi
}

# Detener y deshabilitar el servicio Apache
systemctl stop httpd
systemctl disable httpd

# Desinstalar php-apache primero para evitar problemas de dependencias
desinstalar_si_existe "php-apache"

# Desinstalar Apache
desinstalar_si_existe "apache"

# Eliminar archivos de configuración
rm -rf /etc/httpd

# Eliminar directorio de documentos web
rm -rf /srv/http

# Cerrar el puerto 80 en el firewall (y cualquier otro puerto que se haya abierto)
iptables -D INPUT -p tcp --dport 80 -j ACCEPT 2>/dev/null
ip6tables -D INPUT -p tcp --dport 80 -j ACCEPT 2>/dev/null

# Eliminar el directorio public_html en el directorio home del usuario
if [ -n "$SUDO_USER" ]; then
    rm -rf "/home/$SUDO_USER/public_html"
fi

echo "Apache ha sido desinstalado y limpiado correctamente."