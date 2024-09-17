#!/bin/bash

# Ruta al directorio cifrado
carpeta_encfs="/home/jmro/Documentos/.Privado"

# Carpeta de destino
carpeta_destino="/home/jmro/Documentos/Privado"

# Archivo que contiene las contraseñas
archivo_contrasenas="./contrasenas.txt"

# Verificar si el directorio cifrado existe
if [ ! -d "$carpeta_encfs" ]; then
    echo "El directorio cifrado \"$carpeta_encfs\" no existe."
    exit 1
fi

# Verificar si la carpeta de destino existe y crearla si no existe
if [ ! -d "$carpeta_destino" ]; then
    echo "La carpeta de destino \"$carpeta_destino\" no existe. Creando carpeta..."
    mkdir -p "$carpeta_destino"
    if [ $? -ne 0 ]; then
        echo "Error al crear la carpeta de destino."
        exit 1
    fi
    echo "Carpeta de destino creada exitosamente."
fi

# Verificar si el archivo de contraseñas existe
if [ ! -f "$archivo_contrasenas" ]; then
    echo "El archivo de contraseñas \"$archivo_contrasenas\" no existe."
    exit 1
fi

# Listar los archivos disponibles en el directorio cifrado con números
echo "Archivos disponibles para desencriptar:"
archivos_disponibles=("$carpeta_encfs"/*)
contador=1
for archivo in "${archivos_disponibles[@]}"; do
    echo "$contador: $(basename "$archivo")"
    ((contador++))
done

# Solicitar al usuario que elija un archivo para desencriptar
read -p "Ingrese el número del archivo que desea desencriptar: " numero_archivo

# Verificar si el número ingresado es válido
if ! [[ "$numero_archivo" =~ ^[0-9]+$ ]]; then
    echo "Por favor, ingrese un número válido."
    exit 1
fi

# Verificar si el número ingresado está dentro del rango de archivos disponibles
if (( numero_archivo < 1 || numero_archivo > ${#archivos_disponibles[@]} )); then
    echo "El número ingresado no corresponde a un archivo válido."
    exit 1
fi

# Obtener la ruta completa del archivo seleccionado
archivo_seleccionado="${archivos_disponibles[$((numero_archivo - 1))]}"

# Leer la contraseña desde el archivo
contrasena=$(head -n 1 "$archivo_contrasenas")

# Desbloquear el archivo seleccionado con GPG
echo "$contrasena" | gpg --passphrase-fd 0 --batch -d "$archivo_seleccionado" > "$carpeta_destino/$(basename "$archivo_seleccionado")"

# Verificar el código de salida de GPG
if [ $? -eq 0 ]; then
    echo "Archivo desencriptado exitosamente."
    exit 0
else
    echo "No se pudo desencriptar el archivo."
    exit 1
fi
