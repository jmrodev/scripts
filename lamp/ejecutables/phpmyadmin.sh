#!/bin/bash

# Install phpmyadmin package
sudo pacman -S phpmyadmin

# Enable PHP extensions (mariadb, iconv, bz2, and zip)
sudo sed -i 's/;extension=bz2/extension=bz2/' /etc/php/php.ini
sudo sed -i 's/;extension=zip/extension=zip/' /etc/php/php.ini

# Add necessary configurations to php.ini (open_basedir)
sudo sed -i 's/;\(open_basedir = \).*/\1\/usr/share/webapps:\/etc/webapps/' /etc/php/php.ini

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

echo "phpMyAdmin has been installed and configured. You can access it at http://localhost/phpmyadmin"
