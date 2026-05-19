#!/bin/bash

# Verificar si el archivo existe
if [ -f "paquetes_instalados.txt" ]; then
    # Instalar paquetes del repositorio oficial
    echo "Instalando paquetes del repositorio oficial..."
    cat paquetes_instalados.txt | grep -v "Paquetes de AUR" | sed '/^$/d' | xargs sudo pacman -S --noconfirm

    # Instalar paquetes de AUR
    echo "Instalando paquetes de AUR..."
    cat paquetes_instalados.txt | sed -n -e '/Paquetes de AUR/,$p' | sed '1d' | xargs yay -S --noconfirm

    echo "Restauración completada."
else
    echo "El archivo paquetes_instalados.txt no existe."
    exit 1
fi
