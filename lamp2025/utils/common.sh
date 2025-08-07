#!/bin/bash

# Definir BASE_DIR si no está definido
if [ -z "$BASE_DIR" ]; then
    BASE_DIR="$(dirname "$(readlink -f "$0")")"
fi

# Función para verificar si el script se ejecuta como root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "Error: Este script debe ejecutarse como root."
        exit 1
    fi
}

# Función para verificar el espacio en disco (MB)
check_disk_space() {
    local required_space=$1
    local available_space=$(df --output=avail / | tail -1)

    if (( available_space < required_space * 1024 )); then
        echo "Error: No hay suficiente espacio en disco. Se requieren al menos ${required_space}MB."
        exit 1
    fi
}

# Función para registrar logs
log() {
    local level="$1"
    local message="$2"
    local log_file="$BASE_DIR/logs/system.log"

    # Asegurarse de que el directorio de logs exista
    mkdir -p "$(dirname "$log_file")"

    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $message" | tee -a "$log_file"
}

# Función para verificar si un paquete está instalado
check_package() {
    pacman -Q "$1" &>/dev/null
}

# Función para instalar paquetes
install_package() {
    local package_name="$1"
    if ! check_package "$package_name"; then
        log "INFO" "Instalando $package_name..."
        if sudo pacman -S --noconfirm "$package_name"; then
            log "SUCCESS" "$package_name instalado correctamente"
        else
            log "ERROR" "Error al instalar $package_name"
            exit 1
        fi
    else
        log "INFO" "$package_name ya está instalado."
    fi
}

# Función para crear backups
create_backup() {
    local file_path="$1"
    if [ -f "$file_path" ]; then
        local backup_dir="$BASE_DIR/backups"
        mkdir -p "$backup_dir"
        cp "$file_path" "$backup_dir/$(basename "$file_path").$(date +%Y%m%d%H%M%S).bak"
        log "INFO" "Backup de $file_path creado en $backup_dir"
    fi
}

# Función para verificar si un puerto está en uso
check_port() {
    ss -tuln | grep -q ":$1 "
}
