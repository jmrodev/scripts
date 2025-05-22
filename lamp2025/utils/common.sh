#!/bin/bash

echo "Base directory common: $BASE_DIR"


# Definir BASE_DIR si no está definido
BASE_DIR="$(dirname "$(readlink -f "$0")")"

echo "Base directory: $BASE_DIR"


# Función para verificar si el script se ejecuta como root
check_root() {
    echo "Verificando si el script se ejecuta como root"
    if [[ $EUID -ne 0 ]]; then
        echo "Error: Este script debe ejecutarse como root."
        exit 1
    fi
}

# Función para verificar el espacio en disco (MB)
check_disk_space() {
    echo "Verificando espacio en disco"
    local required_space=$1
    local available_space=$(df --output=avail / | tail -1)

    if (( available_space < required_space * 1024 )); then
        echo "Error: No hay suficiente espacio en disco. Se requieren al menos ${required_space}MB."
        exit 1
    fi
}

# Función para registrar logs
log() {

    echo "Registrando logs"
    local level="$1"
    echo "Level: $level"
    local message="$2"
    echo "Message: $message"
    local log_file="$BASE_DIR/logs/system.log"


echo "Log file: $log_file"

echo "Asegurando que el directorio de logs exista"
    # Asegurarse de que el directorio de logs exista
    mkdir -p "$BASE_DIR/logs"

    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $message" | tee -a "$log_file"
}

# Función para actualizar el sistema
update_system() {
    echo "Actualizando sistema"
    log "INFO" "Actualizando sistema..."
    if sudo pacman -Syu --noconfirm; then
        log "SUCCESS" "Sistema actualizado correctamente"
    else
        log "ERROR" "Error al actualizar el sistema"
        exit 1
    fi
}
