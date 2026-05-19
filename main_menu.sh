#!/bin/bash

# Ruta base de los scripts organizados
BASE_DIR="/home/jmro/scripts"

# Función para mostrar el menú principal
show_main_menu() {
    echo "Seleccione una categoría:"
    echo "1) System (Mantenimiento, aceleración)"
    echo "2) Network (IPs, Puertos, MAC)"
    echo "3) Backup (Configuraciones, Paquetes)"
    echo "4) Development (React, PHP, Servers)"
    echo "5) Utilities (Duplicados, Passwords, EncFS)"
    echo "6) Instaladores (LAMP Modular, VSCode, Brew)"
    echo "7) Git (Clonación masiva)"
    echo "8) Servicios (Gestor Zenity)"
    echo "9) Juegos"
    echo "0) Salir"
    read -p "Ingrese una opción: " category
}

# Función para listar y ejecutar scripts en una categoría
list_and_execute_scripts() {
    local category_dir="$1"
    local scripts=("$category_dir"/*.sh)
    
    if [ ${#scripts[@]} -eq 0 ]; then
        echo "No hay scripts disponibles en esta categoría."
        return
    fi
    
    echo "Seleccione un script para ejecutar:"
    for i in "${!scripts[@]}"; do
        echo "$((i + 1))) $(basename "${scripts[$i]}")"
    done
    echo "0) Volver al menú principal"
    read -p "Ingrese una opción: " script_choice
    
    if [ "$script_choice" -eq 0 ]; then
        return
        elif [ "$script_choice" -ge 1 ] && [ "$script_choice" -le ${#scripts[@]} ]; then
        bash "${scripts[$((script_choice - 1))]}"
    else
        echo "Opción no válida."
    fi
}

# Menú principal
while true; do
    show_main_menu
    case $category in
        1) list_and_execute_scripts "$BASE_DIR/system" ;;
        2) list_and_execute_scripts "$BASE_DIR/network" ;;
        3) list_and_execute_scripts "$BASE_DIR/backup" ;;
        4) list_and_execute_scripts "$BASE_DIR/dev" ;;
        5) list_and_execute_scripts "$BASE_DIR/utilities" ;;
        6) list_and_execute_scripts "$BASE_DIR/instaladores" ;;
        7) list_and_execute_scripts "$BASE_DIR/git" ;;
        8) list_and_execute_scripts "$BASE_DIR/servicios" ;;
        9) list_and_execute_scripts "$BASE_DIR/games" ;;
        0) echo "Saliendo..."; exit 0 ;;
        *) echo "Opción no válida." ;;
    esac
done
