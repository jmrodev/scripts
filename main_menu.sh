#!/bin/bash

# Ruta base de los scripts organizados
BASE_DIR="/home/jmro/scripts"

# Función para mostrar el menú principal
show_main_menu() {
    echo "==============================================="
    echo "   MENÚ DE SCRIPTS (v2 Optimizado)            "
    echo "==============================================="
    echo "1) System       2) Network      3) Backup"
    echo "4) Development  5) Utilities    6) Remote"
    echo "0) Salir"
    echo "==============================================="
    read -p "Ingrese una opción: " category
}

# Función para listar y ejecutar scripts en una categoría
list_and_execute_scripts() {
    local category_dir="$1"
    local scripts=("$category_dir"/*.sh)
    
    if [ ! -d "$category_dir" ]; then
        echo "Error: La carpeta $category_dir no existe."
        return
    fi

    # Comprobación de si hay scripts .sh
    local count=0
    for f in "$category_dir"/*.sh; do
        [ -e "$f" ] && ((count++))
    done

    if [ "$count" -eq 0 ]; then
        echo "No hay scripts disponibles en esta categoría."
        return
    fi
    
    echo "-----------------------------------------------"
    local i=1
    for f in "$category_dir"/*.sh; do
        echo "$i) $(basename "$f")"
        ((i++))
    done
    echo "0) Volver al menú principal"
    echo "-----------------------------------------------"
    read -p "Ingrese una opción: " script_choice
    
    if [ "$script_choice" -eq 0 ] || [ -z "$script_choice" ]; then
        return
    fi

    # Ejecutar el script seleccionado
    local j=1
    for f in "$category_dir"/*.sh; do
        if [ "$j" -eq "$script_choice" ]; then
            bash "$f"
            return
        fi
        ((j++))
    done

    echo "Opción no válida."
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
        6) list_and_execute_scripts "$BASE_DIR/remote" ;;
        0) echo "Saliendo..."; exit 0 ;;
        *) echo "Opción no válida." ;;
    esac
done
