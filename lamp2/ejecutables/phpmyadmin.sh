#!/bin/bash

echo "Instalando y configurando phpMyAdmin..."

# Verificar si el usuario tiene privilegios de superusuario
if [ "$(id -u)" != "0" ]; then
    echo "Este script debe ejecutarse con privilegios de superusuario (root)."
    exit 1
fi

# Instalar phpMyAdmin
if ! pacman -Qi phpmyadmin > /dev/null; then
    echo "Instalando phpMyAdmin..."
    sudo pacman -Syu --noconfirm phpmyadmin
else
    echo "phpMyAdmin ya está instalado."
fi

# Habilitar extensiones PHP necesarias
echo "Habilitando extensiones PHP necesarias..."
sudo sed -i 's/;extension=bz2/extension=bz2/' /etc/php/php.ini
sudo sed -i 's/;extension=zip/extension=zip/' /etc/php/php.ini

# Añadir configuraciones necesarias a php.ini (open_basedir)
echo "Configurando open_basedir en php.ini..."
sudo sed -i 's/;\(open_basedir = \).*/\1\/usr\/share\/webapps:\/etc\/webapps/' /etc/php/php.ini

# Crear archivo phpmyadmin.conf
echo "Creando archivo de configuración phpmyadmin.conf..."
sudo tee /etc/httpd/conf/extra/phpmyadmin.conf > /dev/null <<EOL
Alias /phpmyadmin "/usr/share/webapps/phpMyAdmin"
<Directory "/usr/share/webapps/phpMyAdmin">
    DirectoryIndex index.php
    AllowOverride All
    Options FollowSymlinks
    Require all granted
</Directory>
EOL

# Incluir phpmyadmin.conf en httpd.conf si no está ya incluido
if ! grep -q "Include conf/extra/phpmyadmin.conf" /etc/httpd/conf/httpd.conf; then
    echo "Incluyendo phpmyadmin.conf en httpd.conf..."
    echo "Include conf/extra/phpmyadmin.conf" | sudo tee -a /etc/httpd/conf/httpd.conf > /dev/null
fi

# Reiniciar Apache para aplicar cambios
echo "Reiniciando Apache..."
sudo systemctl restart httpd

# Configuración adicional de phpMyAdmin
echo "Configurando phpMyAdmin..."
sudo mkdir -p /usr/share/webapps/phpMyAdmin/config
sudo chown http:http /usr/share/webapps/phpMyAdmin/config
sudo chmod 750 /usr/share/webapps/phpMyAdmin/config

# Añadir blowfish_secret a config.inc.php
echo "Añadiendo blowfish_secret a config.inc.php..."
sudo tee -a /usr/share/webapps/phpMyAdmin/config.inc.php > /dev/null <<EOL
\$cfg['blowfish_secret'] = '$(openssl rand -base64 32)';
EOL

# Eliminar el directorio de configuración temporal
echo "Eliminando el directorio de configuración temporal..."
sudo rm -r /usr/share/webapps/phpMyAdmin/config

echo "phpMyAdmin ha sido instalado y configurado correctamente. Puedes acceder a él en http://localhost/phpmyadmin"
