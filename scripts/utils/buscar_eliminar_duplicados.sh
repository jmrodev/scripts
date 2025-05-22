#!/bin/bash

# Función para mover y manejar duplicados
move_and_handle_duplicates() {
    local source_file=$1
    local destination_folder=$2
    local filename=$(basename "$source_file")
    local target="$destination_folder/$filename"

    # Crear destino si no existe
    mkdir -p "$destination_folder"

    if [[ -e "$target" ]]; then
        # El archivo ya existe en el destino, comprobamos si son iguales
        if cmp -s "$source_file" "$target"; then
            echo "El archivo '$source_file' es un duplicado y será eliminado."
            rm "$source_file"
        else
            # Los archivos tienen el mismo nombre pero son diferentes, renombrar antes de mover
            echo "El archivo '$source_file' tiene el mismo nombre que un archivo en '$destination_folder' pero son diferentes."
            local base="${filename%.*}"
            local extension="${filename##*.}"
            local newfilename="$base-$(date +%Y%m%d%H%M%S).$extension"
            local newtarget="$destination_folder/$newfilename"
            echo "Moviendo '$source_file' a '$newtarget'"
            mv "$source_file" "$newtarget"
        fi
    else
        # No existe un archivo con el mismo nombre en el destino, mover directamente
        echo "Moviendo '$source_file' a '$destination_folder'"
        mv "$source_file" "$target"
    fi
}

# Definir las extensiones de fotos y videos
photo_extensions="*.jpg *.jpeg *.png *.gif *.bmp *.tiff"
video_extensions="*.mp4 *.avi *.mov *.wmv *.flv *.mkv *.3gp"

# Procesar fotos
echo "Procesando fotos..."
find . -type f \( $(printf -- "-iname %s -o " $photo_extensions) -false \) ! -path "./Fotos/*" -print0 | while IFS= read -r -d $'\0' file; do
    move_and_handle_duplicates "$file" "./Fotos"
done

# Procesar videos
echo "Procesando videos..."
find . -type f \( $(printf -- "-iname %s -o " $video_extensions) -false \) ! -path "./Videos/*" -print0 | while IFS= read -r -d $'\0' file; do
    move_and_handle_duplicates "$file" "./Videos"
done

# Eliminar carpetas vacías
echo "Eliminando carpetas vacías..."
find . -type d -empty -exec rmdir {} +

echo "Proceso completado."
