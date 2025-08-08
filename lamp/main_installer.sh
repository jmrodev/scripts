#!/bin/bash

# --- Common Functions ---

# Base directory of the script
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# Function for logging messages
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

# Check for root privileges
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log "ERROR" "This script must be run as root."
        exit 1
    fi
}

# --- Installer Functions ---

















# --- Uninstaller Functions ---







# --- Restore Functions ---



# --- Main Script Logic ---

check_root

echo "=== Arch Linux LAMP Installer & Uninstaller ==="
echo "Selecciona una opción:"
echo "--- INSTALAR ---"
echo "1) Instalar Apache HTTP Server"
echo "2) Instalar PHP (para Apache)"
echo "3) Instalar MariaDB"
echo "4) Instalar TODO (Apache, PHP, MariaDB)"
echo "--- DESINSTALAR ---"
echo "5) Desinstalar Apache"
echo "6) Desinstalar PHP"
echo "7) Desinstalar MariaDB"
echo "8) Desinstalar TODO"
echo "--- OTRAS OPCIONES ---"
echo "9) Restaurar configuraciones de Apache"
echo "0) Salir"

read -p "Opción: " choice

case "$choice" in
    1) bash "$BASE_DIR/install_apache.sh" ;;
    2) bash "$BASE_DIR/install_php.sh" ;;
    3) bash "$BASE_DIR/install_mysql.sh" ;;
    4) bash "$BASE_DIR/install_apache.sh" && bash "$BASE_DIR/install_php.sh" && bash "$BASE_DIR/install_mysql.sh" ;;
    5) bash "$BASE_DIR/uninstall_apache.sh" ;;
    6) bash "$BASE_DIR/uninstall_php.sh" ;;
    7) bash "$BASE_DIR/uninstall_mysql.sh" ;;
    8)
        bash "$BASE_DIR/uninstall_apache.sh"
        bash "$BASE_DIR/uninstall_php.sh"
        bash "$BASE_DIR/uninstall_mysql.sh"
        # Assuming restore_apache_conf is now part of install_apache.sh or a separate script if needed
        # If it's a separate script, it should be called here.
        # For now, I'll remove the call as it was a function within this script.
        ;;
    9) # Assuming restore_apache_conf is now part of install_apache.sh or a separate script if needed
       # If it's a separate script, it should be called here.
       # For now, I'll remove the call as it was a function within this script.
       log "WARN" "Restore Apache config functionality needs to be implemented in a separate script if desired." ;;
    0) log "INFO" "Saliendo. ¡Adiós!" ;;
    *) log "ERROR" "Opción inválida." ;;
esac

log "INFO" "Script finalizado."