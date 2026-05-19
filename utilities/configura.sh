 #!/bin/bash
 case $1 in
    alias)   micro ~/.aliases ;;
    funcs)   micro ~/.funcs ;;
    zsh)     micro ~/.zshrc ;;
    ayuda)   echo 'configura <archivo>\n'
             echo 'Configuraciones disponibles: alias; funcs; zsh'
             echo '' ;;
    *)       echo "Aplicación desconocida: $1" ;;
  esac
