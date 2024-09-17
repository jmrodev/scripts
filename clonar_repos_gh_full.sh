#!/bin/bash

# Función para mostrar el menú de opciones
mostrar_menu() {
    echo "Selecciona una opción:"
    echo "1) Clonar repositorios"
    echo "2) Fetch en todos los repositorios"
    echo "3) Push en todos los repositorios"
    echo "4) Pull en todos los repositorios"
    echo "5) Salir"
}

# Solicitar el nombre de usuario de GitHub
read -p "Introduce tu nombre de usuario de GitHub: " USUARIO

# Solicitar la carpeta de destino, con valor predeterminado "./repositorios"
read -p "Introduce la carpeta de destino (predeterminado: /home/jmro/Documentos/repositorios/): " CARPETA
CARPETA=${CARPETA:-/home/jmro/Documentos/repositorios/}  # Usa la carpeta predeterminada si el usuario no ingresa nada

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

# Menú de opciones
while true; do
    mostrar_menu
    read -p "Elige una opción [1-5]: " OPCION

    case $OPCION in
        1)
            # Clonar los repositorios
            for repo in $REPOS; do
                echo "Clonando https://github.com/$repo..."
                gh repo clone "$repo"
            done
            echo "Todos los repositorios han sido clonados."
            ;;
        2)
            # Fetch en todos los repositorios
            for dir in */; do
                if [ -d "$dir/.git" ]; then
                    echo "Haciendo fetch en $dir..."
                    (cd "$dir" && git fetch)
                fi
            done
            echo "Fetch completo en todos los repositorios."
            ;;
        3)
            # Push en todos los repositorios
            for dir in */; do
                if [ -d "$dir/.git" ]; then
                    echo "Haciendo push en $dir..."
                    (cd "$dir" && git push)
                fi
            done
            echo "Push completo en todos los repositorios."
            ;;
        4)
            # Pull en todos los repositorios
            for dir in */; do
                if [ -d "$dir/.git" ]; then
                    echo "Haciendo pull en $dir..."
                    (cd "$dir" && git pull)
                fi
            done
            echo "Pull completo en todos los repositorios."
            ;;
        5)
            echo "Saliendo del script."
            exit 0
            ;;
        *)
            echo "Opción inválida. Por favor, selecciona una opción entre 1 y 5."
            ;;
    esac
done
