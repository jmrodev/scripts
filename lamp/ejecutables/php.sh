#!/bin/bash

# Instalar PHP y extensiones comunes
sudo pacman -Syu --noconfirm php php-gd php-imagick php-redis php-pgsql php-sqlite php-apcu php-intl php-xdebug

# Configurar PHP
sudo sed -i 's/;date.timezone =/date.timezone = America\/Argentina\/Buenos_Aires/' /etc/php/php.ini
sudo sed -i 's/display_errors = Off/display_errors = On/' /etc/php/php.ini
sudo sed -i 's/;extension=gd/extension=gd/' /etc/php/php.ini
sudo sed -i 's/;extension=zip/extension=zip/' /etc/php/php.ini
sudo sed -i 's/;extension=pdo_mysql/extension=pdo_mysql/' /etc/php/php.ini
sudo sed -i 's/;extension=mysqli/extension=mysqli/' /etc/php/php.ini
sudo sed -i 's/;open_basedir =/open_basedir = \/srv\/http\/:\/var\/www\/:\/home\/:\/tmp\/:\/var\/tmp\/:\/var\/cache\/:\/usr\/share\/pear\/:\/usr\/share\/webapps\/:\/etc\/webapps\//' /etc/php/php.ini

# Install php-apache
sudo pacman -S php-apache

# Comment the specified line in /etc/httpd/conf/httpd.conf
sudo sed -i 's/^LoadModule\ mpm_event_module/#LoadModule mpm_event_module/' /etc/httpd/conf/httpd.conf
# Uncomment the specified line in /etc/httpd/conf/httpd.conf
sudo sed -i 's/^#LoadModule\ mpm_prefork_module/LoadModule mpm_prefork_module/' /etc/httpd/conf/httpd.conf

# Add the LoadModule line at the end of the LoadModule list
sudo sed -i '/^LoadModule/ { h; s/.*/&\nLoadModule php_module modules\/libphp.so/ } ; $ { x; s/^\n//; p; x; }' /etc/httpd/conf/httpd.conf

# Add the Include line at the end of the Include list
echo "Include conf/extra/php_module.conf" | sudo tee -a /etc/httpd/conf/httpd.conf > /dev/null

# Apache DocumentRoot directory for a specific user (replace <username> with the actual username)
# Define document root directory
document_root="/home/$USER/public_html/"

# Check if the directory exists, if not, create it
if [ ! -d "$document_root" ]; then
    mkdir -p "$document_root"
    echo "Created directory: $document_root"
fi
# Create test.php file with PHP info content
echo "<?php phpinfo(); ?>" |  tee "${document_root}test.php" > /dev/null
sudo bash -c 'echo "<?php phpinfo(); ?>" > /srv/http/test.php'


echo "test.php file created in ${document_root}"

# Reiniciar el servidor web (por ejemplo, Apache)
sudo systemctl restart httpd

echo "PHP y extensiones han sido instaladas y configuradas correctamente con la zona horaria de Buenos Aires. El servidor web ha sido reiniciado. La configuración open_basedir ha sido aplicada. Las extensiones pdo_mysql y mysqli han sido habilitadas."
