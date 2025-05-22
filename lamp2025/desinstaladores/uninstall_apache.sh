#!/bin/bash

# Importar funciones comunes
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/../utils/common.sh"
source "${SCRIPT_DIR}/../utils/arch_helpers.sh"

# Verificar permisos de root
check_root

log "INFO" "Iniciando desinstalación de Apache..."

# Detener y deshabilitar servicio
if systemctl is-active --quiet httpd; then
    systemctl stop httpd
    systemctl disable httpd
    log "INFO" "Servicio Apache detenido y deshabilitado"
fi

# Desinstalar Apache
if pacman -Qi apache &>/dev/null; then
    pacman -Rns --noconfirm apache
    log "SUCCESS" "Apache desinstalado"
else
    log "INFO" "Apache no está instalado"
fi

# Eliminar archivos de configuración
if [ -d /etc/httpd ]; then
    rm -rf /etc/httpd
    log "INFO" "Archivos de configuración de Apache eliminados"
fi

# Eliminar directorio web por defecto
if [ -d /srv/http ]; then
    rm -rf /srv/http
    log "INFO" "Directorio web por defecto eliminado"
fi

# Cerrar puertos en el firewall
if command -v iptables &>/dev/null; then
    iptables -D INPUT -p tcp --dport 80 -j ACCEPT 2>/dev/null
    iptables -D INPUT -p tcp --dport 443 -j ACCEPT 2>/dev/null
    log "INFO" "Reglas de firewall eliminadas"
fi

# Eliminar logs
if [ -d /var/log/httpd ]; then
    rm -rf /var/log/httpd
    log "INFO" "Logs de Apache eliminados"
fi

log "SUCCESS" "Apache ha sido completamente desinstalado" 