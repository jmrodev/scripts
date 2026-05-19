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
        read -r -p "¿Desea instalar '$package_name'? (Sí/No): " response
        case "$response" in
            [Ss][Íí]|[Ss][Ii]|[Yy][Ee][Ss]) sudo pacman -S --noconfirm "$package_name" ;;
            *) echo "No se puede continuar sin el paquete '$package_name' instalado." ; exit 1 ;;
        esac
    fi
}

# Verificar si el paquete mariadb está instalado
check_package_installed "phpmyadmin"



# Enable PHP extensions (mariadb, iconv, bz2, and zip)
sudo sed -i 's/;extension=bz2/extension=bz2/' /etc/php/php.ini
sudo sed -i 's/;extension=zip/extension=zip/' /etc/php/php.ini

# Add necessary configurations to php.ini (open_basedir)
# sudo sed -i 's/;\(open_basedir = \).*/\1\/usr/share/webapps:\/etc/webapps/' /etc/php/php.ini
sudo sed -i 's#;\(open_basedir = \).*#\1"/usr/share/webapps:/etc/webapps"#' /etc/php/php.ini


# Create phpmyadmin.conf file
sudo tee /etc/httpd/conf/extra/phpmyadmin.conf > /dev/null <<EOL
Alias /phpmyadmin "/usr/share/webapps/phpMyAdmin"
<Directory "/usr/share/webapps/phpMyAdmin">
    DirectoryIndex index.php
    AllowOverride All
    Options FollowSymlinks
    Require all granted
</Directory>
EOL

# Include phpmyadmin.conf in httpd.conf
echo "Include conf/extra/phpmyadmin.conf" | sudo tee -a /etc/httpd/conf/httpd.conf > /dev/null

# Restart Apache using systemd
sudo systemctl restart httpd
# pausa para que el usuario pueda ver el mensaje
echo "Apache ha sido reiniciado."

# xdg-open http://localhost/phpmyadmin

echo "phpMyAdmin has been installed and configured. You can access it at http://localhost/phpmyadmin"
