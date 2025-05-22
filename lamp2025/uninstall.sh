#!/bin/bash

# Importar funciones comunes
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/utils/common.sh"
source "${SCRIPT_DIR}/utils/arch_helpers.sh"

# Verificar permisos de root
check_root

# Función para confirmar acción
confirm_action() {
    local message="$1"
    read -p "$message (s/N): " response
    case "$response" in
        [sS][iI]|[sS]) return 0 ;;
        *) return 1 ;;
    esac
}

# Agregar verificación de procesos activos antes de desinstalar
check_active_processes() {
    local service="$1"
    if pgrep -f "$service" > /dev/null; then
        log "WARNING" "Hay procesos activos de $service. Se recomienda detenerlos antes de desinstalar."
        if confirm_action "¿Desea detener los procesos de $service?"; then
            pkill -f "$service"
        fi
    fi
}

# Menú de desinstalación
echo -e "${YELLOW}=== Desinstalador LAMP 2025 para Arch Linux ===${NC}"
echo "Seleccione los componentes a desinstalar:"
echo "1) phpMyAdmin"
echo "2) PHP"
echo "3) MariaDB"
echo "4) Apache"
echo "5) Desinstalación completa"
echo "0) Salir"

read -p "Ingrese su selección (puede seleccionar múltiples opciones, ej: 1 2 3): " -a SELECTIONS

# Verificar si se debe hacer backup
if confirm_action "¿Desea realizar un backup antes de desinstalar?"; then
    BACKUP_DIR="$BASE_DIR/backups/pre_uninstall_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # Backup de configuraciones
    [ -d /etc/httpd ] && cp -r /etc/httpd "$BACKUP_DIR/"
    [ -d /etc/php ] && cp -r /etc/php "$BACKUP_DIR/"
    [ -d /etc/webapps/phpmyadmin ] && cp -r /etc/webapps/phpmyadmin "$BACKUP_DIR/"
    
    # Backup de MariaDB si está instalado
    if systemctl is-active --quiet mariadb; then
        mysqldump --all-databases > "$BACKUP_DIR/full_database_backup.sql"
    fi
    
    log "INFO" "Backup creado en $BACKUP_DIR"
fi

# Agregar antes de cada desinstalación:
check_active_processes "apache2"
check_active_processes "mysql"
check_active_processes "php"

# Procesar selecciones
for selection in "${SELECTIONS[@]}"; do
    case $selection in
        1)
            log "INFO" "Desinstalando phpMyAdmin..."
            bash "$BASE_DIR/desinstaladores/uninstall_phpmyadmin.sh"
            ;;
        2)
            log "INFO" "Desinstalando PHP..."
            bash "$BASE_DIR/desinstaladores/uninstall_php.sh"
            ;;
        3)
            log "INFO" "Desinstalando MariaDB..."
            bash "$BASE_DIR/desinstaladores/uninstall_mariadb.sh"
            ;;
        4)
            log "INFO" "Desinstalando Apache..."
            bash "$BASE_DIR/desinstaladores/uninstall_apache.sh"
            ;;
        5)
            log "INFO" "Iniciando desinstalación completa..."
            # Orden inverso al de instalación
            bash "$BASE_DIR/desinstaladores/uninstall_phpmyadmin.sh"
            bash "$BASE_DIR/desinstaladores/uninstall_php.sh"
            bash "$BASE_DIR/desinstaladores/uninstall_mariadb.sh"
            bash "$BASE_DIR/desinstaladores/uninstall_apache.sh"
            break
            ;;
        0)
            log "INFO" "Saliendo del desinstalador"
            exit 0
            ;;
        *)
            log "ERROR" "Opción inválida: $selection"
            ;;
    esac
done

# Limpiar archivos residuales
if confirm_action "¿Desea eliminar todos los archivos de configuración residuales?"; then
    rm -rf /etc/httpd 2>/dev/null
    rm -rf /etc/php 2>/dev/null
    rm -rf /etc/webapps/phpmyadmin 2>/dev/null
    rm -rf /var/lib/mysql 2>/dev/null
    log "INFO" "Archivos de configuración eliminados"
fi

echo -e "${GREEN}=== Desinstalación completada ===${NC}" 