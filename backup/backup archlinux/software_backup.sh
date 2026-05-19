#!/bin/bash

# Definir nombres de archivos de copia de seguridad predeterminados
repo_backup_file="repo_packages_backup.txt"
aur_backup_file="aur_packages_backup.txt"

# Función para realizar una copia de seguridad de los paquetes instalados
backup_packages() {
    echo "Realizando copia de seguridad de los paquetes instalados..."
    pacman -Qqen > "$1"
    pacman -Qqem > "$2"
    echo "Copia de seguridad completada."
}

# Función para instalar paquetes desde un archivo
install_packages() {
    local repo_file="$1"
    local aur_file="$2"
    echo "Instalando paquetes desde los archivos $repo_file y $aur_file..."
    yay -S --needed - < "$repo_file"
    sudo pacman -S --needed - < "$repo_file"
    yay -S --needed - < "$aur_file"
    echo "Instalación completada."
}

# Menú de opciones
echo "Seleccione una opción:"
echo "1. Realizar copia de seguridad de los paquetes instalados"
echo "2. Instalar paquetes desde un archivo"
read -p "Opción: " option

# Realizar acciones basadas en la opción seleccionada
case $option in
    1)
        backup_packages "$repo_backup_file" "$aur_backup_file"
        ;;
    2)
        read -p "Ingrese la ruta completa del archivo de paquetes del repositorio: " repo_package_file
        read -p "Ingrese la ruta completa del archivo de paquetes del AUR: " aur_package_file
        if [ -f "$repo_package_file" ] && [ -f "$aur_package_file" ]; then
            install_packages "$repo_package_file" "$aur_package_file"
        else
            echo "Uno o ambos archivos especificados no existen."
        fi
        ;;
    *)
        echo "Opción no válida."
        ;;
esac
