#!/bin/bash

# Función para mostrar el menú de opciones
mostrar_menu() {
    echo "Selecciona una opción:"
    echo "1) Clonar repositorios"
    echo "2) Fetch en todos los repositorios"
    echo "3) Push en todos los repositorios"
    echo "4) Pull en todos los repositorios"
    echo "5) Eliminar repositorio remoto si el local no existe"
    echo "6) Detectar repositorios locales nuevos y subirlos a GitHub"
    echo "7) Listar todos los repositorios locales y remotos"
    echo "8) Verificar cambios, add y commit en repositorios locales"
    echo "9) Salir"
}

# Función para ejecutar comandos git con manejo de errores
ejecutar_git_comando() {
    if ! "$@"; then
        echo "Error al ejecutar: $*"
        return 1
    fi
}

# Función para verificar la autenticación de gh
verificar_gh_auth() {
    if ! gh auth status &>/dev/null; then
        echo "Error: No estás autenticado en GitHub CLI. Por favor, ejecuta 'gh auth login' primero."
        exit 1
    fi
}

# Verificar si gh está instalado y autenticado
if ! command -v gh &> /dev/null; then
    echo "Error: gh no está instalado. Instálalo con: sudo apt install gh"
    exit 1
fi

verificar_gh_auth

# Solicitar el nombre de usuario de GitHub
read -p "Introduce tu nombre de usuario de GitHub: " USUARIO

# Solicitar la carpeta de destino, con valor predeterminado
read -p "Introduce la carpeta de destino (predeterminado: /home/$USER/Documentos/repositorios/): " CARPETA
CARPETA=${CARPETA:-/home/$USER/Documentos/repositorios/}

# Crear el directorio si no existe
mkdir -p "$CARPETA"
cd "$CARPETA" || exit

# Solicitar el número máximo de repositorios a listar
read -p "Introduce el número máximo de repositorios a listar (predeterminado: 100): " MAX_REPOS
MAX_REPOS=${MAX_REPOS:-100}

# Menú de opciones
while true; do
    mostrar_menu
    read -p "Elige una opción [1-9]: " OPCION

    case $OPCION in
        1)
            # Clonar los repositorios
            REPOS=$(gh repo list "$USUARIO" --limit $MAX_REPOS --json nameWithOwner -q ".[].nameWithOwner")
            if [ -z "$REPOS" ]; then
                echo "No se encontraron repositorios para el usuario: $USUARIO. Verifica el nombre del usuario."
                continue
            fi
            for repo in $REPOS; do
                if [ ! -d "$(basename "$repo")" ]; then
                    echo "Clonando https://github.com/$repo..."
                    gh repo clone "$repo" || echo "Error al clonar $repo"
                else
                    echo "El repositorio $repo ya existe localmente. Omitiendo."
                fi
            done
            echo "Proceso de clonación completado."
            ;;
        2)
            # Fetch en todos los repositorios
            for dir in */; do
                if [ -d "$dir/.git" ]; then
                    echo "Haciendo fetch en $dir..."
                    (cd "$dir" && ejecutar_git_comando git fetch --all)
                fi
            done
            echo "Fetch completo en todos los repositorios."
            ;;
        3)
            # Push en todos los repositorios
            for dir in */; do
                if [ -d "$dir/.git" ]; then
                    echo "Haciendo push en $dir..."
                    (cd "$dir" && ejecutar_git_comando git push --all)
                fi
            done
            echo "Push completo en todos los repositorios."
            ;;
        4)
            # Pull en todos los repositorios
            for dir in */; do
                if [ -d "$dir/.git" ]; then
                    echo "Haciendo pull en $dir..."
                    (cd "$dir" && ejecutar_git_comando git pull --all)
                fi
            done
            echo "Pull completo en todos los repositorios."
            ;;
        5)
            # Eliminar repositorio remoto si el local no existe
            REPOS=$(gh repo list "$USUARIO" --limit $MAX_REPOS --json nameWithOwner -q ".[].nameWithOwner")
            for repo in $REPOS; do
                REPO_NAME=$(basename "$repo")
                if [ ! -d "$REPO_NAME" ]; then
                    read -p "El repositorio local '$REPO_NAME' no existe. ¿Deseas eliminar el repositorio remoto $repo? [y/n]: " CONFIRMAR
                    if [[ "$CONFIRMAR" =~ ^[Yy]$ ]]; then
                        echo "Eliminando el repositorio remoto $repo..."
                        gh repo delete "$repo" --confirm || echo "Error al eliminar $repo"
                    else
                        echo "Repositorio remoto $repo no eliminado."
                    fi
                fi
            done
            echo "Proceso de eliminación de repositorios completado."
            ;;
        6)
            # Detectar repositorios locales sin remotos y subirlos a GitHub
            for dir in */; do
                if [ -d "$dir/.git" ]; then
                    cd "$dir" || continue
                    REMOTE_URL=$(git config --get remote.origin.url 2>/dev/null)
                    if [ -z "$REMOTE_URL" ]; then
                        echo "El repositorio local '${dir%/}' no tiene un repositorio remoto."
                        read -p "¿Deseas crear un repositorio remoto en GitHub y hacer push? [y/n]: " CONFIRMAR_CREAR
                        if [[ "$CONFIRMAR_CREAR" =~ ^[Yy]$ ]]; then
                            REPO_NAME=${dir%/}
                            echo "Creando repositorio remoto en GitHub para '$REPO_NAME'..."
                            if gh repo create "$USUARIO/$REPO_NAME" --public --source=. --remote=origin; then
                                echo "Repositorio remoto '$REPO_NAME' creado."
                                BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)
                                if git push -u origin "$BRANCH_NAME"; then
                                    echo "Push realizado al repositorio remoto '$REPO_NAME'."
                                else
                                    echo "Error al hacer push al repositorio remoto '$REPO_NAME'."
                                fi
                            else
                                echo "Error al crear el repositorio remoto '$REPO_NAME'."
                            fi
                        else
                            echo "No se creó el repositorio remoto para '${dir%/}'."
                        fi
                    fi
                    cd ..
                fi
            done
            echo "Proceso de creación de repositorios remotos completado."
            ;;
        7)
            # Listar todos los repositorios locales y remotos
            echo "Repositorios locales:"
            for dir in */; do
                if [ -d "$dir/.git" ]; then
                    echo "  - ${dir%/}"
                fi
            done
            echo "Repositorios remotos:"
            gh repo list "$USUARIO" --limit $MAX_REPOS --json nameWithOwner -q ".[].nameWithOwner" | sed 's/^/  - /'
            ;;
        8)
            # Verificar cambios, add y commit en repositorios locales
            for dir in */; do
                if [ -d "$dir/.git" ]; then
                    echo "Verificando cambios en $dir..."
                    cd "$dir" || continue
                    
                    if ! git diff --quiet || ! git diff --staged --quiet; then
                        echo "Se encontraron cambios en $dir"
                        git status
                        
                        read -p "¿Deseas hacer add de estos cambios? [y/n]: " CONFIRMAR_ADD
                        if [[ "$CONFIRMAR_ADD" =~ ^[Yy]$ ]]; then
                            git add .
                            echo "Cambios añadidos al staging area."
                            
                            read -p "Introduce el mensaje para el commit: " COMMIT_MSG
                            if [ -n "$COMMIT_MSG" ]; then
                                if git commit -m "$COMMIT_MSG"; then
                                    echo "Commit realizado con éxito."
                                else
                                    echo "Error al realizar el commit."
                                fi
                            else
                                echo "No se realizó el commit debido a que el mensaje estaba vacío."
                            fi
                        else
                            echo "No se realizaron cambios en $dir."
                        fi
                    else
                        echo "No hay cambios en $dir."
                    fi
                    
                    cd ..
                fi
            done
            echo "Proceso de verificación de cambios completado."
            ;;
        9)
            echo "Saliendo del script."
            exit 0
            ;;
        *)
            echo "Opción inválida. Por favor, selecciona una opción entre 1 y 9."
            ;;
    esac
done
