#!/bin/bash

# Verificar si el script se ejecuta con privilegios de superusuario
if [ "$(id -u)" != "0" ]; then
    echo "Este script debe ejecutarse con privilegios de superusuario (root)."
    exit 1
fi

# Ruta al directorio de ejecutables de desinstalación
DESINSTALADORES_DIR="$(dirname "$(readlink -f "$0")")/desinstaladores"

# Función para ejecutar scripts de desinstalación
ejecutar_desinstalador() {
    if [ -f "$1" ]; then
        echo "Ejecutando $1..."
        bash "$1"
    else
        echo "Advertencia: $1 no encontrado."
    fi
}

# Ejecutar los scripts individuales de desinstalación
ejecutar_desinstalador "$DESINSTALADORES_DIR/uninstall_phpmyadmin.sh"
ejecutar_desinstalador "$DESINSTALADORES_DIR/uninstall_php.sh"
ejecutar_desinstalador "$DESINSTALADORES_DIR/uninstall_mariadb.sh"
ejecutar_desinstalador "$DESINSTALADORES_DIR/uninstall_apache.sh"

echo "LAMP stack ha sido desinstalado y limpiado correctamente."
