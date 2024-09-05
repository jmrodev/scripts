#!/bin/bash

# Directorio de respaldo predeterminado
BACKUP_DIR="${HOME}/backup_manjaro_config"

# Función para respaldar archivos
backup() {
    echo "Iniciando backup..."

    # Crear el directorio de respaldo si no existe
    mkdir -p "$BACKUP_DIR"

    # Función para copiar un archivo o directorio si existe
    backup_if_exists() {
        if [ -e "$1" ]; then
            cp -r "$1" "$BACKUP_DIR"
            echo "Respaldado: $1"
        else
            echo "No encontrado: $1"
        fi
    }

    # Respaldar configuraciones de usuario
    backup_if_exists "${HOME}/.config"
    backup_if_exists "${HOME}/.local/share"
    backup_if_exists "${HOME}/.bashrc"
    backup_if_exists "${HOME}/.zshrc"
    backup_if_exists "${HOME}/.profile"
    backup_if_exists "${HOME}/.bash_profile"
    backup_if_exists "${HOME}/.gitconfig"

    # Respaldar configuraciones del sistema (requiere permisos de superusuario)
    # backup_if_exists "/etc"

    echo "Backup completado en: $BACKUP_DIR"
}

# Función para restaurar archivos
restore() {
    echo "Iniciando restauración..."

    # Función para restaurar un archivo o directorio si existe en el backup
    restore_if_exists() {
        if [ -e "$BACKUP_DIR/$1" ]; then
            cp -r "$BACKUP_DIR/$1" "${HOME}/"
            echo "Restaurado: $1"
        else
            echo "No encontrado en backup: $1"
        fi
    }

    # Restaurar configuraciones de usuario
    restore_if_exists ".config"
    restore_if_exists ".local/share"
    restore_if_exists ".bashrc"
    restore_if_exists ".zshrc"
    restore_if_exists ".profile"
    restore_if_exists ".bash_profile"
    restore_if_exists ".gitconfig"

    # Restaurar configuraciones del sistema (requiere permisos de superusuario)
    # restore_if_exists "etc"

    echo "Restauración completada."
}

# Preguntar al usuario qué acción desea realizar
echo "Seleccione una opción:"
echo "1. Backup de configuraciones"
echo "2. Restaurar configuraciones"
read -p "Ingrese el número de opción (1 o 2): " OPCION

case $OPCION in
    1)
        backup
        ;;
    2)
        restore
        ;;
    *)
        echo "Opción no válida. Por favor, ingrese 1 o 2."
        exit 1
        ;;
esac
