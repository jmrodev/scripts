#!/bin/bash

# Importar funciones comunes
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/../utils/common.sh"
source "${SCRIPT_DIR}/../utils/arch_helpers.sh"

# Verificar permisos de root
check_root

log "INFO" "Iniciando desinstalación de phpMyAdmin..."

# Desinstalar phpMyAdmin
if pacman -Qi phpmyadmin &>/dev/null; then
    pacman -Rns --noconfirm phpmyadmin
    log "SUCCESS" "phpMyAdmin desinstalado"
else
    log "INFO" "phpMyAdmin no está instalado"
fi

# Eliminar archivos de configuración
if [ -d /etc/webapps/phpmyadmin ]; then
    rm -rf /etc/webapps/phpmyadmin
    log "INFO" "Archivos de configuración de phpMyAdmin eliminados"
fi

# Eliminar archivos web
if [ -d /usr/share/webapps/phpMyAdmin ]; then
    rm -rf /usr/share/webapps/phpMyAdmin
    log "INFO" "Archivos web de phpMyAdmin eliminados"
fi

# Eliminar configuración de Apache
if [ -f /etc/httpd/conf/extra/phpmyadmin.conf ]; then
    rm -f /etc/httpd/conf/extra/phpmyadmin.conf
    log "INFO" "Archivo de configuración de Apache para phpMyAdmin eliminado"
fi

# Eliminar inclusión en httpd.conf
if [ -f /etc/httpd/conf/httpd.conf ]; then
    sed -i '/Include conf\/extra\/phpmyadmin.conf/d' /etc/httpd/conf/httpd.conf
    log "INFO" "Referencia a phpMyAdmin eliminada de httpd.conf"
    
    # Reiniciar Apache si está activo
    if systemctl is-active --quiet httpd; then
        systemctl restart httpd
        log "INFO" "Apache reiniciado"
    fi
fi

# Eliminar archivos temporales
if [ -d /var/lib/phpmyadmin ]; then
    rm -rf /var/lib/phpmyadmin
    log "INFO" "Archivos temporales de phpMyAdmin eliminados"
fi

# Agregar limpieza de sesiones
if [ -d /var/lib/php/sessions ]; then
    find /var/lib/php/sessions -name "sess_*" -delete
    log "INFO" "Sesiones de phpMyAdmin eliminadas"
fi

# Verificar y eliminar enlaces simbólicos
if [ -L /usr/share/webapps/phpMyAdmin ]; then
    rm -f /usr/share/webapps/phpMyAdmin
    log "INFO" "Enlaces simbólicos de phpMyAdmin eliminados"
fi

log "SUCCESS" "phpMyAdmin ha sido completamente desinstalado" 