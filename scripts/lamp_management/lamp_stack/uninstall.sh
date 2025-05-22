#!/bin/bash

# Ensure the script is run with superuser privileges, as uninstallation tasks require it.
if [ "$(id -u)" != "0" ]; then
    echo "Este script debe ejecutarse con privilegios de superusuario (root)."
    echo "Por favor, ejecute con sudo: sudo $0"
    exit 1
fi

# Determine the directory containing the uninstaller scripts.
# This allows the script to be called from any location.
DESINSTALADORES_DIR="$(dirname "$(readlink -f "$0")")/desinstaladores"

# Function to execute individual uninstallation scripts
run_uninstaller_script() {
    local script_path="$1"
    if [ -f "$script_path" ]; then
        echo "Ejecutando script de desinstalación: $script_path..."
        # The sub-scripts are expected to handle sudo internally or also check for root.
        # Since this parent script is already run as root, sub-scripts will inherit root privileges.
        if bash "$script_path"; then
            echo "Script $script_path ejecutado correctamente."
        else
            echo "Error durante la ejecución de $script_path. Por favor, revise la salida."
            # Decide if you want to exit on error or continue with other uninstallers
            # For a full cleanup, it might be better to continue.
        fi
    else
        echo "Advertencia: Script de desinstalación $script_path no encontrado. Omitiendo."
    fi
}

echo "Iniciando el proceso de desinstalación de LAMP stack..."

# Order of uninstallation can be important to handle dependencies.
# Typically, applications are uninstalled first, then servers, then base packages.

# --- Desinstalar phpMyAdmin ---
run_uninstaller_script "$DESINSTALADORES_DIR/uninstall_phpmyadmin.sh"

# --- Desinstalar PHP ---
run_uninstaller_script "$DESINSTALADORES_DIR/uninstall_php.sh"

# --- Desinstalar MariaDB ---
run_uninstaller_script "$DESINSTALADORES_DIR/uninstall_mariadb.sh"

# --- Desinstalar Apache ---
run_uninstaller_script "$DESINSTALADORES_DIR/uninstall_apache.sh"

echo "Proceso de desinstalación de LAMP stack completado."
echo "Por favor, revise la salida para verificar que todos los componentes se hayan eliminado correctamente."
