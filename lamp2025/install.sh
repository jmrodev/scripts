#!/bin/bash

# Definir directorio base
export BASE_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Crear directorios necesarios antes de cualquier operación
mkdir -p "$BASE_DIR/logs" "$BASE_DIR/backups"

# Verificar existencia de archivos antes de importarlos
if [[ ! -f "$BASE_DIR/utils/common.sh" || ! -f "$BASE_DIR/utils/arch_helpers.sh" ]]; then
    echo "Error: No se encontraron los archivos de utilidades en $BASE_DIR/utils/"
    exit 1
fi

# Importar funciones comunes
source "$BASE_DIR/utils/common.sh"
source "$BASE_DIR/utils/arch_helpers.sh"

# Verificar permisos de root
check_root

# Verificar espacio en disco (mínimo 2GB)
check_disk_space 2048 || exit 1

# Verificar si la función update_system está definida antes de ejecutarla
if ! declare -F update_system &>/dev/null; then
    echo "Error: La función update_system no está definida."
    exit 1
fi

# Función para mostrar la barra de progreso
show_progress() {
    local duration=$1
    local interval=0.1
    local total_steps=$(echo "$duration / $interval" | bc)
    
    if [ "$total_steps" -le 0 ]; then
        echo "Error: La duración debe ser mayor que cero."
        return 1
    fi
    
    for ((i=0; i<=total_steps; i++)); do
        sleep $interval
        # Calcular el porcentaje
        local percent=$((i * 100 / total_steps))
        # Mostrar la barra de progreso
        printf "\r[%-50s] %d%%" "$(printf \"%-${percent}s\" '#' | tr ' ' '#')" "$percent"
    done
    echo
}

# Actualizar sistema
log "INFO" "Iniciando la actualización del sistema..."
echo "Actualizando el sistema, por favor espere..."
show_progress 5  # Simula un proceso de 5 segundos
if update_system; then
    log "SUCCESS" "Sistema actualizado correctamente"
else
    log "ERROR" "Error al actualizar el sistema"
    exit 1
fi

# Menú de instalación
echo -e "=== Instalador LAMP 2025 para Arch Linux ==="
echo "Seleccione los componentes a instalar:"
echo "1) Apache"
echo "2) MariaDB"
echo "3) PHP"
echo "4) phpMyAdmin"
echo "5) Instalación completa"
echo "0) Salir"

read -p "Ingrese su selección (puede seleccionar múltiples opciones, ej: 1 2 3): " -a SELECTIONS

# Procesar selecciones
for selection in "${SELECTIONS[@]}"; do
    case $selection in
        1)
            log "INFO" "Iniciando la instalación de Apache..."
            echo "Instalando Apache, por favor espere..."
            show_progress 5  # Simula un proceso de 5 segundos
            bash "$BASE_DIR/ejecutables/apache.sh"
            log "SUCCESS" "Apache instalado correctamente"
            ;;
        2)
            log "INFO" "Iniciando la instalación de MariaDB..."
            echo "Instalando MariaDB, por favor espere..."
            show_progress 5  # Simula un proceso de 5 segundos
            bash "$BASE_DIR/ejecutables/mariadb.sh"
            log "SUCCESS" "MariaDB instalado correctamente"
            ;;
        3)
            log "INFO" "Iniciando la instalación de PHP..."
            echo "Instalando PHP, por favor espere..."
            show_progress 5  # Simula un proceso de 5 segundos
            bash "$BASE_DIR/ejecutables/php.sh"
            log "SUCCESS" "PHP instalado correctamente"
            ;;
        4)
            log "INFO" "Iniciando la instalación de phpMyAdmin..."
            echo "Instalando phpMyAdmin, por favor espere..."
            show_progress 5  # Simula un proceso de 5 segundos
            bash "$BASE_DIR/ejecutables/phpmyadmin.sh"
            log "SUCCESS" "phpMyAdmin instalado correctamente"
            ;;
        5)
            log "INFO" "Iniciando la instalación de Apache..."
            echo "Instalando Apache, por favor espere..."
            show_progress 5  # Simula un proceso de 5 segundos
            bash "$BASE_DIR/ejecutables/apache.sh"
            log "INFO" "Iniciando la instalación de MariaDB..."
            echo "Instalando MariaDB, por favor espere..."
            show_progress 5  # Simula un proceso de 5 segundos
            bash "$BASE_DIR/ejecutables/mariadb.sh"
            log "INFO" "Iniciando la instalación de PHP..."
            echo "Instalando PHP, por favor espere..."
            show_progress 5  # Simula un proceso de 5 segundos
            bash "$BASE_DIR/ejecutables/php.sh"
            log "INFO" "Iniciando la instalación de phpMyAdmin..."
            echo "Instalando phpMyAdmin, por favor espere..."
            show_progress 5  # Simula un proceso de 5 segundos
            bash "$BASE_DIR/ejecutables/phpmyadmin.sh"
            log "INFO" "Instalación completa."
            echo "La instalación de LAMP se ha completado con éxito."
            ;;
        0) exit 0 ;;
        *) echo "Opción inválida: $selection" ;;
    esac
done