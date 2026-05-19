#!/bin/bash
# Gestor de edición de configuraciones del sistema

EDITOR_CMD=${EDITOR:-nvim}

case $1 in
    alias)   $EDITOR_CMD ~/.aliases ;;
    funcs)   $EDITOR_CMD ~/.funcs ;;
    zsh)     $EDITOR_CMD ~/.zshrc ;;
    ssh)     $EDITOR_CMD ~/.ssh/config ;;
    git)     $EDITOR_CMD ~/.gitconfig ;;
    scripts) $EDITOR_CMD ~/scripts/main_menu.sh ;;
    ayuda|--help|-h)
             echo "Uso: ./edit_configs.sh [opción]"
             echo ""
             echo "Opciones disponibles:"
             echo "  alias    - Editar alias de ZSH"
             echo "  funcs    - Editar funciones personalizadas"
             echo "  zsh      - Editar .zshrc"
             echo "  ssh      - Editar configuración de SSH"
             echo "  git      - Editar .gitconfig"
             echo "  scripts  - Editar el menú principal"
             echo "" ;;
    *)       echo "Error: Opción desconocida '$1'. Usa 'ayuda' para ver la lista." ;;
esac
