#!/bin/bash

# Verificar si se proporcionaron los directorios de entrada y salida como argumentos
if [ $# -ne 2 ]; then
    echo "Uso: $0 directorio_de_entrada directorio_de_salida"
    exit 1
fi

input_dir="$1"
output_dir="$2"

# Verificar si el directorio de entrada existe
if [ ! -d "$input_dir" ]; then
    echo "El directorio de entrada '$input_dir' no existe."
    exit 1
fi

# Verificar si exiftool y sha256sum están instalados
if ! command -v exiftool &> /dev/null; then
    echo "exiftool no está instalado. Por favor, instálalo para usar este script."
    exit 1
fi

if ! command -v sha256sum &> /dev/null; then
    echo "sha256sum no está instalado. Por favor, instálalo para usar este script."
    exit 1
fi

# Crear el directorio de salida si no existe
mkdir -p "$output_dir"

# Archivo temporal para almacenar los hashes
hash_file=$(mktemp)

# Función para obtener la fecha del metadato de un archivo
get_metadata_date() {
    exiftool -s -s -s -d "%Y%m%d_%H%M%S" -DateTimeOriginal "$1"
}

# Función para obtener el hash de un archivo
get_file_hash() {
    sha256sum "$1" | awk '{ print $1 }'
}

# Contador para archivos sin metadatos
counter=1

# Buscar archivos en el directorio de entrada de forma recursiva
find "$input_dir" -type f -print0 | while IFS= read -r -d '' file; do
    # Obtener el hash del archivo
    file_hash=$(get_file_hash "$file")

    # Verificar si el hash ya existe en el archivo de hashes
    if grep -q "$file_hash" "$hash_file"; then
        echo "Archivo $(basename "$file") omitido (duplicado detectado)."
        continue
    fi

    # Agregar el hash al archivo de hashes
    echo "$file_hash" >> "$hash_file"

    # Obtener la fecha del metadato del archivo
    metadata_date=$(get_metadata_date "$file")

    # Obtener la extensión del archivo original
    file_extension="${file##*.}"

    if [ -z "$metadata_date" ]; then
        # Generar el nombre de archivo secuencial
        sequential_name=$(printf "%05d" "$counter")

        # Incrementar el contador
        ((counter++))

        # Mover el archivo al directorio de salida con el nombre formateado
        mv "$file" "$output_dir/$sequential_name.$file_extension"
        echo "Archivo $(basename "$file") movido a $output_dir con el nombre $sequential_name.$file_extension"
    else
        # Asegurar que no haya colisión de nombres
        new_file="$output_dir/$metadata_date.$file_extension"
        if [ -e "$new_file" ]; then
            suffix=1
            while [ -e "${new_file%.*}_$suffix.${file_extension}" ]; do
                ((suffix++))
            done
            new_file="${new_file%.*}_$suffix.${file_extension}"
        fi

        # Copiar el archivo al directorio de salida con el nombre formateado
        mv "$file" "$new_file"
        echo "Archivo $(basename "$file") movido a $output_dir con el nombre $(basename "$new_file")"
    fi
done

# Eliminar el archivo temporal de hashes
rm "$hash_file"

echo "Proceso completado."
