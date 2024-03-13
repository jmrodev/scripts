#!/bin/bash


# Función para verificar si un paquete está instalado
is_package_installed() {
    pacman -Q "$1" &> /dev/null
}

# Verificar si Apache está instalado
if ! is_package_installed "apache"; then
    echo "Apache no está instalado. Por favor, instale Apache primero."
    exit 1
fi

# Verificar si PHP está instalado
if ! is_package_installed "php"; then
    echo "PHP no está instalado. Por favor, instale PHP primero."
    exit 1
fi

# Verificar si MariaDB está instalado
if ! is_package_installed "mariadb"; then
    echo "MariaDB no está instalado. Por favor, instale MariaDB primero."
    exit 1
fi

# Verificar si MySQL está instalado
if ! is_package_installed "mysql"; then
    echo "MySQL no está instalado. Por favor, instale MySQL primero."
    exit 1
fi

# Ruta al directorio de ejecutables
EJECUTABLES_DIR="$(dirname "$(readlink -f "$0")")/exec"

# Listar los scripts disponibles en el directorio
echo "Scripts disponibles:"
scripts=("$EJECUTABLES_DIR"/*.sh)
for ((i = 0; i < ${#scripts[@]}; i++)); do
    echo "$(($i + 1))) $(basename "${scripts[$i]}")"
done

# Solicitar al usuario que seleccione los scripts a ejecutar
echo "Ingrese el número de los scripts que desea ejecutar, separados por espacios ('todos' para ejecutar todos los scripts):"
read -r selections

# Verificar si el usuario seleccionó 'todos'
if [[ $selections == "todos" ]]; then
    # Ejecutar todos los scripts
    echo "Ejecutando todos los scripts disponibles..."
    for script in "${scripts[@]}"; do
        echo "Ejecutando $(basename "$script")"
        bash "$script"
    done
else
    # Separar las selecciones del usuario
    IFS=' ' read -r -a selected_scripts <<<"$selections"
    for selection in "${selected_scripts[@]}"; do
        index=$((selection - 1))
        if [[ $index -ge 0 && $index -lt ${#scripts[@]} ]]; then
            script="${scripts[$index]}"
            echo "Ejecutando $(basename "$script")"
            bash "$script"
        else
            echo "El número de script '$selection' no es válido."
        fi
    done
fi

