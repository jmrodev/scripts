#!/bin/bash

# Listar paquetes del repositorio oficial
echo "Paquetes del repositorio oficial:" > paquetes_instalados.txt
pacman -Qqe | grep -vx "$(pacman -Qqm)" >> paquetes_instalados.txt

# Listar paquetes de AUR
echo "" >> paquetes_instalados.txt
echo "Paquetes de AUR:" >> paquetes_instalados.txt
pacman -Qqm >> paquetes_instalados.txt

echo "Se han guardado los paquetes instalados en paquetes_instalados.txt"
