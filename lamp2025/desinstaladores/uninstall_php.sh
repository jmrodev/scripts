#!/bin/bash

# Importar funciones comunes
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/../utils/common.sh"
source "${SCRIPT_DIR}/../utils/arch_helpers.sh"

# Verificar permisos de root
check_root

log "INFO" "Iniciando desinstalación de PHP..."

# Lista de paquetes PHP a desinstalar
PHP_PACKAGES=(
    "php"
    "php-apache"
    "php-gd"
    "php-imagick"
    "php-intl"
    "php-sqlite"
    "php-mysql"
    "php-fpm"
    "php-xdebug"
    "php-apcu"
)

# Detener servicios relacionados
if systemctl is-active --quiet php-fpm; then
    systemctl stop php-fpm
    systemctl disable php-fpm
    log "INFO" "Servicio PHP-FPM detenido y deshabilitado"
fi

# Desinstalar paquetes PHP
for package in "${PHP_PACKAGES[@]}"; do
    if pacman -Qi "$package" &>/dev/null; then
        pacman -Rns --noconfirm "$package"
        log "INFO" "Paquete $package desinstalado"
    fi
done

# Eliminar archivos de configuración
if [ -d /etc/php ]; then
    rm -rf /etc/php
    log "INFO" "Archivos de configuración de PHP eliminados"
fi

# Eliminar archivos temporales de PHP
if [ -d /var/lib/php ]; then
    rm -rf /var/lib/php
    log "INFO" "Archivos temporales de PHP eliminados"
fi

# Eliminar archivos de sesión
if [ -d /var/lib/php/sessions ]; then
    rm -rf /var/lib/php/sessions
    log "INFO" "Archivos de sesión de PHP eliminados"
fi

# Eliminar archivo de prueba PHP
DOCROOT=$(grep "^DocumentRoot" /etc/httpd/conf/httpd.conf 2>/dev/null | awk '{print $2}' | tr -d '"')
if [ -n "$DOCROOT" ] && [ -f "${DOCROOT}/info.php" ]; then
    rm -f "${DOCROOT}/info.php"
    log "INFO" "Archivo de prueba PHP eliminado"
fi

# Revertir cambios en la configuración de Apache
if [ -f /etc/httpd/conf/httpd.conf ]; then
    sed -i '/LoadModule php_module/d' /etc/httpd/conf/httpd.conf
    sed -i '/AddHandler php-script/d' /etc/httpd/conf/httpd.conf
    sed -i '/Include conf\/extra\/php_module.conf/d' /etc/httpd/conf/httpd.conf
    log "INFO" "Configuración de PHP eliminada de Apache"
    
    # Restaurar mpm_event si está comentado
    sed -i 's/^#LoadModule mpm_event_module/LoadModule mpm_event_module/' /etc/httpd/conf/httpd.conf
    
    # Reiniciar Apache si está activo
    if systemctl is-active --quiet httpd; then
        systemctl restart httpd
        log "INFO" "Apache reiniciado"
    fi
fi

log "SUCCESS" "PHP ha sido completamente desinstalado" 