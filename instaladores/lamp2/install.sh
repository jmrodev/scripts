#!/bin/bash

# Ruta al directorio de ejecutables
EJECUTABLES_DIR="$(dirname "$(readlink -f "$0")")/ejecutables"

# Ejecutar los scripts individuales
"$EJECUTABLES_DIR/apache.sh"
"$EJECUTABLES_DIR/mariadb.sh"
"$EJECUTABLES_DIR/phpmyadmin.sh"
"$EJECUTABLES_DIR/php.sh"

echo "LAMP stack ha sido instalado y configurado correctamente."
