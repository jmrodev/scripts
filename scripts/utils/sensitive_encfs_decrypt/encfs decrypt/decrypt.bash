#!/bin/bash

# Rutas a los directorios cifrados
carpeta_encfs="/home/jmro/Documentos"
carpeta_privado="$carpeta_encfs/.personal_encfs"
carpeta_publico="$carpeta_encfs/personal_encfs"


# Verificar si carpeta_publico existe
if [ ! -d "$carpeta_publico" ]; then
    echo "La carpeta pública \"$carpeta_publico\" no existe. Creándola..."
    mkdir -p "$carpeta_publico"
    if [ $? -ne 0 ]; then
        echo "Error al crear la carpeta pública \"$carpeta_publico\"."
        exit 1
    else
        echo "Carpeta pública creada exitosamente."
    fi
fi
# Archivo que contiene las contrasenas
archivo_contrasenas="./contrasenas.txt"

# Verificar si el archivo de contrasenas existe
if [ ! -f "$archivo_contrasenas" ]; then
    echo "El archivo de contrasenas \"$archivo_contrasenas\" no existe."
    exit 1
fi

# Leer las contrasenas desde el archivo
contrasenas=$(cat "$archivo_contrasenas")

# Iterar sobre las contrasenas
while IFS= read -r contrasena; do
    echo "Probando contrasena: $contrasena"

    # Desbloquear el directorio cifrado con encfs
    echo "$contrasena" | encfs -f -v --stdinpass "$carpeta_privado" "$carpeta_publico"

    # Verificar el código de salida de encfs
    if [ $? -eq 0 ]; then
        echo "Contraseña correcta: $contrasena"
        exit 0
    else
        echo "Contraseña incorrecta: $contrasena"
    fi
done <<< "$contrasenas"

echo "No se encontró una contrasena válida en el archivo."
exit 1
