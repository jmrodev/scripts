#!/bin/bash

echo "Software instalado en Arch Linux:"
echo "----------------------------------"

# Utilizamos 'pacman' para obtener la lista de paquetes instalados y la enviamos a 'grep' para filtrar la información relevante
pacman -Qe | awk '{print $1}' | sort
