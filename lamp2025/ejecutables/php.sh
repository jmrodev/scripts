#!/bin/bash

# Importar funciones comunes
source "$BASE_DIR/utils/common.sh"
source "$BASE_DIR/utils/arch_helpers.sh"

# Verificar permisos de root
check_root

log "INFO" "Iniciando instalación de PHP..."

# Lista de paquetes PHP necesarios
PHP_PACKAGES=(
    "php"
    "php-apache"
    "php-gd"
    "php-imagick"
    "php-intl"
    "php-sqlite"
    "php-fpm"
    "php-xdebug"
    "php-apcu"
)

# Instalar paquetes PHP
for package in "${PHP_PACKAGES[@]}"; do
    install_package "$package" || exit 1
done

# Backup de configuración original
create_backup "/etc/php/php.ini"

# Configurar PHP
log "INFO" "Configurando PHP..."

# Configuraciones básicas de PHP
sed -i 's/;date.timezone =/date.timezone = America\/Argentina\/Buenos_Aires/' /etc/php/php.ini
sed -i 's/display_errors = Off/display_errors = On/' /etc/php/php.ini
sed -i 's/max_execution_time = 30/max_execution_time = 60/' /etc/php/php.ini
sed -i 's/memory_limit = 128M/memory_limit = 256M/' /etc/php/php.ini
sed -i 's/post_max_size = 8M/post_max_size = 64M/' /etc/php/php.ini
sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 64M/' /etc/php/php.ini

# Habilitar extensiones
EXTENSIONS=(
    "gd"
    "mysqli"
    "pdo_mysql"
    "zip"
    "intl"
    "imagick"
    "apcu"
)

# Agregar verificación de extensiones
for ext in "${EXTENSIONS[@]}"; do
    if ! php -m | grep -q "^$ext$"; then
        log "WARNING" "La extensión $ext no está disponible"
        continue
    fi
    sed -i "s/;extension=${ext}/extension=${ext}/" /etc/php/php.ini
done

# Configurar PHP con Apache
log "INFO" "Configurando PHP con Apache..."

# Deshabilitar mpm_event y habilitar mpm_prefork
sed -i 's/^LoadModule mpm_event_module/#LoadModule mpm_event_module/' /etc/httpd/conf/httpd.conf
sed -i 's/^#LoadModule mpm_prefork_module/LoadModule mpm_prefork_module/' /etc/httpd/conf/httpd.conf

# Añadir módulo PHP
if ! grep -q "LoadModule php_module" /etc/httpd/conf/httpd.conf; then
    echo "LoadModule php_module modules/libphp.so" >> /etc/httpd/conf/httpd.conf
    echo "AddHandler php-script .php" >> /etc/httpd/conf/httpd.conf
    echo "Include conf/extra/php_module.conf" >> /etc/httpd/conf/httpd.conf
fi

# Crear archivo de prueba PHP
DOCROOT=$(grep "^DocumentRoot" /etc/httpd/conf/httpd.conf | awk '{print $2}' | tr -d '"')
echo "<?php phpinfo(); ?>" > "${DOCROOT}/info.php"
chown http:http "${DOCROOT}/info.php"
chmod 644 "${DOCROOT}/info.php"

# Reiniciar servicios
systemctl restart httpd

# Verificar instalación
if php -v > /dev/null 2>&1; then
    log "SUCCESS" "PHP instalado y configurado correctamente"
    echo -e "PHP está instalado y configurado"
    echo -e "Puede probar la instalación en: http://localhost/info.php"
else
    log "ERROR" "Error en la instalación de PHP"
    exit 1
fi
