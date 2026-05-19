#!/bin/bash

# ==============================================================================
# Script Desinstalador y Limpiador de MariaDB en Arch Linux
# Este script detiene el servicio, desinstala el paquete y elimina
# los archivos y directorios de datos y configuración de MariaDB.
# ==============================================================================

# Función para registrar mensajes con colores
log() {
    local type="$1"
    local message="$2"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    case "$type" in
        "INFO")    echo -e "[\e[34mINFO\e[0m] $timestamp $message" ;;
        "SUCCESS") echo -e "[\e[32mSUCCESS\e[0m] $timestamp $message" ;;
        "ERROR")   echo -e "[\e[31mERROR\e[0m] $timestamp $message" ;;
        "WARN")    echo -e "[\e[33mWARN\e[0m] $timestamp $message" ;;
        *)         echo -e "[\e[37mDEBUG\e[0m] $timestamp $message" ;;
    esac
}

# Verificar privilegios de root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log "ERROR" "Este script debe ser ejecutado como root."
        exit 1
    fi
}

# Lógica de desinstalación de MariaDB
uninstall_mariadb() {
    log "INFO" "--- Iniciando desinstalación de MariaDB ---"
    
    # 1. Verificar privilegios
    check_root

    # 2. Detener el servicio de MariaDB
    log "INFO" "Deteniendo el servicio mariadb..."
    systemctl stop mariadb

    # 3. Desinstalación del paquete con pacman -Rns
    log "INFO" "Desinstalando el paquete 'mariadb' y sus dependencias no utilizadas..."
    if pacman -Rns --noconfirm mariadb; then
        log "SUCCESS" "Paquete 'mariadb' desinstalado exitosamente."
    else
        log "ERROR" "Fallo al desinstalar el paquete 'mariadb'. Puede que ya no esté instalado."
    fi

    # 4. Eliminar directorios de configuración y datos restantes
    log "INFO" "Eliminando directorios de configuración y datos..."
    rm -rf /etc/mysql
    rm -rf /etc/my.cnf
    rm -rf /var/lib/mysql
    rm -rf /etc/my.cnf.d

    log "SUCCESS" "Directorios y archivos de configuración eliminados."

    # 5. Verificación final
    log "INFO" "Verificando el estado del servicio mariadb..."
    if ! systemctl status mariadb &>/dev/null; then
        log "SUCCESS" "El servicio mariadb no está activo. Desinstalación completa."
    else
        log "WARN" "El servicio mariadb aún se encuentra en un estado activo/muerto. Podría ser necesaria una limpieza manual."
    fi

    log "INFO" "--- Desinstalación de MariaDB finalizada ---"
}

# --- Ejecución del script ---
uninstall_mariadb
