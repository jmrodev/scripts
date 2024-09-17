#!/bin/bash

# Solicitar el nombre de usuario de GitHub
read -p "Introduce tu nombre de usuario de GitHub: " USUARIO

# Solicitar la carpeta de destino, con valor predeterminado "./repositorios"
read -p "Introduce la carpeta de destino (predeterminado: ./repositorios): " CARPETA
CARPETA=${CARPETA:-./repositorios}  # Usa la carpeta predeterminada si el usuario no ingresa nada

# Crear el directorio si no existe
mkdir -p "$CARPETA"
cd "$CARPETA" || exit

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

# Menú de opciones
echo ""
echo "Seleccione una opción:"
echo "1. Hacer git pull en todos los repositorios."
echo "2. Hacer git push en todos los repositorios."
echo "3. Hacer git fetch en todos los repositorios."
echo "4. Verificar si hay cambios locales contra el remoto."
echo "5. Ver los archivos que han cambiado."

read -p "Introduce tu opción (1-5): " OPCION

# Función para recorrer los repositorios
for repo in $REPOS; do
    cd "$CARPETA/$(basename "$repo")" || continue  # Entrar a cada repositorio clonado
    echo "Entrando al repositorio: $(basename "$repo")"

    case $OPCION in
        1)
            # Hacer git pull
            echo "Realizando git pull..."
            git pull origin main
            ;;
        2)
            # Hacer git push
            echo "Realizando git push..."
            git push origin main
            ;;
        3)
            # Hacer git fetch
            echo "Realizando git fetch..."
            git fetch origin
            ;;
        4)
            # Verificar si hay cambios locales contra el remoto
            echo "Verificando si hay cambios locales..."
            git fetch origin
            UPSTREAM=${1:-'@{u}'}
            LOCAL=$(git rev-parse @)
            REMOTE=$(git rev-parse "$UPSTREAM")
            BASE=$(git merge-base @ "$UPSTREAM")

            if [ "$LOCAL" = "$REMOTE" ]; then
                echo "Tu rama está actualizada con el remoto."
            elif [ "$LOCAL" = "$BASE" ]; then
                echo "Tu rama está desactualizada con respecto al remoto. Necesitas hacer un git pull."
            elif [ "$REMOTE" = "$BASE" ]; then
                echo "Tienes cambios locales que no han sido enviados al remoto. Necesitas hacer un git push."
            else
                echo "Tu rama y el remoto han divergido. Necesitas hacer una fusión o un rebase."
            fi
            ;;
        5)
            # Ver los archivos que han cambiado
            echo "Archivos que han cambiado localmente:"
            git status -s
            ;;
        *)
            echo "Opción no válida."
            ;;
    esac

    # Volver a la carpeta de repositorios
    cd "$CARPETA" || exit
done

echo "Operación completada en todos los repositorios."

