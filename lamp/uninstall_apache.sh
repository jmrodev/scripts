#!/bin/bash

# ==============================================================================
# Script de Desinstalación de Apache en Arch Linux
# Este script detiene el servicio de Apache, desinstala el paquete y elimina
# los archivos de configuración y directorios.
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

# Lógica de desinstalación
uninstall_apache() {
    log "INFO" "--- Iniciando desinstalación de Apache HTTP Server ---"
    
    # 1. Verificar privilegios
    check_root

    # 2. Detener el servicio de Apache
    log "INFO" "Deteniendo el servicio httpd..."
    systemctl stop httpd

    # 3. Desinstalación del paquete con pacman -Rns
    log "INFO" "Desinstalando paquete 'apache' y sus archivos de configuración..."
    if pacman -Rns --noconfirm apache; then
        log "SUCCESS" "Paquete 'apache' desinstalado exitosamente."
    else
        log "ERROR" "Fallo al desinstalar el paquete 'apache'. Puede que ya no esté instalado."
    fi

    # 4. Eliminar directorios de configuración restantes
    log "INFO" "Eliminando directorios de configuración..."
    rm -rf /etc/httpd
    rm -rf /srv/http

    log "SUCCESS" "Directorios de configuración eliminados."

    # 5. Verificación final
    log "INFO" "Verificando el estado del servicio httpd..."
    if ! systemctl status httpd &>/dev/null; then
        log "SUCCESS" "El servicio httpd no está activo. Desinstalación completa."
    else
        log "WARN" "El servicio httpd aún se encuentra en un estado activo/muerto. Podría ser necesario un reinicio o limpieza manual."
    fi

    log "INFO" "--- Desinstalación de Apache finalizada ---"
}

# --- Ejecución del script ---
uninstall_apache
