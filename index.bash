#!/bin/bash

# Ruta al directorio principal
MAIN_DIR="./"

# Listar las carpetas disponibles en el directorio principal
echo "Carpetas disponibles:"
folders=("$MAIN_DIR"/*/)
for ((i = 0; i < ${#folders[@]}; i++)); do
    echo "$(($i + 1))) $(basename "${folders[$i]}")"
done

# Solicitar al usuario que elija la carpeta
echo "Ingrese el número de la carpeta que desea instalar (separados por espacios):"
read -r -a selections

# Iterar sobre las selecciones y ejecutar los scripts de instalación en cada carpeta seleccionada
for selection in "${selections[@]}"; do
    index=$((selection - 1))
    if [[ $index -ge 0 && $index -lt ${#folders[@]} ]]; then
        folder="${folders[$index]}"
        install_script="$folder/install.sh"
        # Verificar si existe un script de instalación en la carpeta seleccionada
        if [[ -f "$install_script" ]]; then
            echo "Instalando desde la carpeta: $(basename "$folder")"
            # Ejecutar el script de instalación en la carpeta seleccionada
            bash "$install_script"
        else
            echo "No se encontró un script de instalación en la carpeta: $(basename "$folder")"
        fi
    else
        echo "El número de carpeta '$selection' no es válido."
    fi
done
