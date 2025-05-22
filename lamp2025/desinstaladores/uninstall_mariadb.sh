#!/bin/bash

# Importar funciones comunes
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/../utils/common.sh"
source "${SCRIPT_DIR}/../utils/arch_helpers.sh"

# Verificar permisos de root
check_root

log "INFO" "Iniciando desinstalación de MariaDB..."

# Detener y deshabilitar servicio
if systemctl is-active --quiet mariadb; then
    systemctl stop mariadb
    systemctl disable mariadb
    log "INFO" "Servicio MariaDB detenido y deshabilitado"
fi

# Desinstalar MariaDB
if pacman -Qi mariadb &>/dev/null; then
    pacman -Rns --noconfirm mariadb mariadb-clients
    log "SUCCESS" "MariaDB desinstalado"
else
    log "INFO" "MariaDB no está instalado"
fi

# Eliminar archivos de datos
if [ -d /var/lib/mysql ]; then
    rm -rf /var/lib/mysql
    log "INFO" "Directorio de datos de MariaDB eliminado"
fi

# Eliminar archivos de configuración
if [ -d /etc/mysql ]; then
    rm -rf /etc/mysql
    log "INFO" "Archivos de configuración de MariaDB eliminados"
fi

# Eliminar archivos de backup
if [ -d /var/backup/mysql ]; then
    rm -rf /var/backup/mysql
    log "INFO" "Archivos de backup de MariaDB eliminados"
fi

# Eliminar script de backup
if [ -f /etc/cron.daily/mariadb-backup ]; then
    rm -f /etc/cron.daily/mariadb-backup
    log "INFO" "Script de backup eliminado"
fi

# Eliminar credenciales guardadas
if [ -d /root/.mysql ]; then
    rm -rf /root/.mysql
    log "INFO" "Credenciales eliminadas"
fi

log "SUCCESS" "MariaDB ha sido completamente desinstalado" 