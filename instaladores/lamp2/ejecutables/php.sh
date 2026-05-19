#!/bin/bash

echo "Instalando y configurando PHP con Apache..."

# Verificar si el usuario tiene privilegios de superusuario
if [ "$(id -u)" != "0" ]; then
    echo "Este script debe ejecutarse con privilegios de superusuario (root)."
    exit 1
fi

# Instalar PHP y php-apache
sudo pacman -Syu --noconfirm php php-apache

# Archivo de configuración de Apache
archivo_configuracion="/etc/httpd/conf/httpd.conf"

# Verificar si el archivo de configuración existe
if [ ! -f "$archivo_configuracion" ]; then
    echo "El archivo de configuración '$archivo_configuracion' no existe."
    exit 1
fi

# Configurar Apache para usar mpm_prefork y libphp
echo "Configurando Apache para usar mpm_prefork y libphp..."
sudo sed -i 's/^LoadModule mpm_event_module/#LoadModule mpm_event_module/' $archivo_configuracion
sudo sed -i 's/^#LoadModule mpm_prefork_module/LoadModule mpm_prefork_module/' $archivo_configuracion

# Añadir la línea LoadModule php_module al final de la lista de LoadModule
if ! grep -q "LoadModule php_module modules/libphp.so" $archivo_configuracion; then
    sudo sed -i '/^LoadModule/ { h; s/.*/&\nLoadModule php_module modules\/libphp.so/ } ; $ { x; s/^\n//; p; x; }' $archivo_configuracion
fi

# Añadir la línea Include conf/extra/php_module.conf al final de la lista de Include
if ! grep -q "Include conf/extra/php_module.conf" $archivo_configuracion; then
    echo "Include conf/extra/php_module.conf" | sudo tee -a $archivo_configuracion > /dev/null
fi

# Configurar PHP
echo "Configurando PHP..."
sudo sed -i 's/;date.timezone =/date.timezone = America\/Argentina\/Buenos_Aires/' /etc/php/php.ini
sudo sed -i 's/display_errors = Off/display_errors = On/' /etc/php/php.ini
sudo sed -i 's/;extension=gd/extension=gd/' /etc/php/php.ini
sudo sed -i 's/;extension=zip/extension=zip/' /etc/php/php.ini
sudo sed -i 's/;extension=pdo_mysql/extension=pdo_mysql/' /etc/php/php.ini
sudo sed -i 's/;extension=mysqli/extension=mysqli/' /etc/php/php.ini
sudo sed -i 's/;\(open_basedir = \).*/\1\/srv\/http\/:\/var\/www\/:\/home\/:\/tmp\/:\/var\/tmp\/:\/var\/cache\/:\/usr\/share\/pear\/:\/usr\/share\/webapps\/:\/etc\/webapps\//' /etc/php/php.ini

# Crear archivo de prueba PHP
document_root="/srv/http/"
if [ -d "$document_root" ]; then
    echo "<?php phpinfo(); ?>" | sudo tee "${document_root}prueba.php" > /dev/null
else
    echo "El directorio DocumentRoot '$document_root' no existe. Creándolo..."
    sudo mkdir -p "$document_root"
    echo "<?php phpinfo(); ?>" | sudo tee "${document_root}prueba.php" > /dev/null
fi

# Reiniciar Apache para aplicar cambios
sudo systemctl restart httpd

echo "PHP y Apache han sido configurados correctamente. Puedes probarlo visitando http://localhost/prueba.php en tu navegador web."
