#!/bin/bash

# Importar funciones comunes
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/../utils/common.sh"
source "${SCRIPT_DIR}/../utils/arch_helpers.sh"

# Verificar permisos de root
check_root

log "INFO" "Iniciando instalación de phpMyAdmin..."

# Verificar dependencias
check_arch_dependencies "apache" "php" "mariadb" || exit 1

# Instalar phpMyAdmin
install_package "phpmyadmin" || exit 1

# Backup de configuración original si existe
[ -f /etc/webapps/phpmyadmin/config.inc.php ] && create_backup "/etc/webapps/phpmyadmin/config.inc.php"

# Generar blowfish secret
BLOWFISH_SECRET=$(openssl rand -base64 32)

# Configurar phpMyAdmin
log "INFO" "Configurando phpMyAdmin..."

# Crear archivo de configuración
cat > /etc/webapps/phpmyadmin/config.inc.php <<EOF
<?php
\$cfg['blowfish_secret'] = '$BLOWFISH_SECRET';
\$cfg['Servers'][1]['auth_type'] = 'cookie';
\$cfg['Servers'][1]['host'] = 'localhost';
\$cfg['Servers'][1]['compress'] = false;
\$cfg['Servers'][1]['AllowNoPassword'] = false;
\$cfg['UploadDir'] = '';
\$cfg['SaveDir'] = '';
\$cfg['TempDir'] = '/tmp';
\$cfg['DefaultLang'] = 'es';
\$cfg['ServerDefault'] = 1;
\$cfg['MaxRows'] = 100;
\$cfg['MemoryLimit'] = '256M';
\$cfg['ShowPhpInfo'] = true;
\$cfg['ShowChgPassword'] = true;
EOF

# Configurar Apache para phpMyAdmin
cat > /etc/httpd/conf/extra/phpmyadmin.conf <<EOF
Alias /phpmyadmin "/usr/share/webapps/phpMyAdmin"
<Directory "/usr/share/webapps/phpMyAdmin">
    DirectoryIndex index.php
    AllowOverride All
    Options FollowSymlinks
    Require all granted
    
    <IfModule mod_php.c>
        php_admin_value upload_max_filesize 64M
        php_admin_value post_max_size 64M
        php_admin_value max_execution_time 300
        php_admin_value memory_limit 256M
    </IfModule>
</Directory>

# Proteger archivos y directorios
<Directory "/usr/share/webapps/phpMyAdmin/setup">
    Require all denied
</Directory>
<Directory "/usr/share/webapps/phpMyAdmin/libraries">
    Require all denied
</Directory>
<Directory "/usr/share/webapps/phpMyAdmin/templates">
    Require all denied
</Directory>
EOF

# Incluir configuración en Apache
if ! grep -q "Include conf/extra/phpmyadmin.conf" /etc/httpd/conf/httpd.conf; then
    echo "Include conf/extra/phpmyadmin.conf" >> /etc/httpd/conf/httpd.conf
fi

# Establecer permisos correctos
chown -R http:http /usr/share/webapps/phpMyAdmin
chmod 755 /usr/share/webapps/phpMyAdmin

# Crear directorio temporal si no existe
mkdir -p /usr/share/webapps/phpMyAdmin/tmp
chown -R http:http /usr/share/webapps/phpMyAdmin/tmp
chmod 777 /usr/share/webapps/phpMyAdmin/tmp

# Crear archivo .htaccess para seguridad adicional
cat > /usr/share/webapps/phpMyAdmin/.htaccess <<EOF
# Disable directory browsing
Options -Indexes

# Protect against XSS attacks
<IfModule mod_headers.c>
    Header set X-XSS-Protection "1; mode=block"
    Header set X-Content-Type-Options nosniff
    Header set X-Frame-Options SAMEORIGIN
</IfModule>

# Restrict access to local users
Order Deny,Allow
Deny from all
Allow from 127.0.0.1
Allow from ::1
EOF

# Reiniciar Apache
systemctl restart httpd

# Verificar instalación
if curl -s http://localhost/phpmyadmin/ | grep -q "phpMyAdmin"; then
    log "SUCCESS" "phpMyAdmin instalado y configurado correctamente"
    echo -e "${GREEN}phpMyAdmin está instalado y configurado${NC}"
    echo -e "${GREEN}Acceda a phpMyAdmin en: http://localhost/phpmyadmin${NC}"
    echo -e "${YELLOW}Nota: Por seguridad, phpMyAdmin solo es accesible desde localhost${NC}"
else
    log "ERROR" "Error en la instalación de phpMyAdmin"
    exit 1
fi 