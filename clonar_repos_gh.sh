#!/bin/bash

# Solicitar el nombre de usuario de GitHub
read -p "Introduce tu nombre de usuario de GitHub: " USUARIO

# Solicitar la carpeta de destino, con valor predeterminado "./repositorios"
read -p "Introduce la carpeta de destino (predeterminado: ./repositorios): " CARPETA
CARPETA=${CARPETA:-./repositorios}  # Usa la carpeta predeterminada si el usuario no ingresa nada

# Crear el directorio si no existe
mkdir -p "$CARPETA"
cd "$CARPETA"

# Verificar si gh está instalado y autenticado
if ! command -v gh &> /dev/null; then
    echo "Error: gh no está instalado. Instálalo con: sudo apt install gh"
    exit 1
fi

# Obtener la lista de todos los repositorios (públicos y privados) del usuario
REPOS=$(gh repo list "$USUARIO" --limit 100 --json nameWithOwner -q ".[].nameWithOwner")

# Verificar si se obtuvieron repositorios
if [ -z "$REPOS" ]; then
    echo "No se encontraron repositorios para el usuario: $USUARIO. Verifica el nombre del usuario."
    exit 1
fi

# Clonar los repositorios
for repo in $REPOS; do
    echo "Clonando https://github.com/$repo..."
    gh repo clone "$repo"
done

echo "Todos los repositorios han sido descargados."

