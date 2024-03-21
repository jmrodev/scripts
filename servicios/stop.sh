#!/bin/bash

# Verificar si se proporcionaron los servicios como argumentos
if [ $# -lt 1 ]; then
    echo "Uso: $0 servicio1 [servicio2 servicio3 ...]"
    exit 1
fi

# Detener los servicios pasados como argumentos
pkexec systemctl stop "$@"

# Verificar si los servicios se detuvieron correctamente
if [ $? -eq 0 ]; then
    # Mostrar mensaje emergente indicando que los servicios se han detenido correctamente
    kdialog --title "Servicios detenidos" --passivepopup "Los servicios se han detenido correctamente." 5

    # Esperar un momento para permitir que los servicios se estabilicen
    sleep 2

    # Verificar el estado de cada servicio y mostrar su estado
    for servicio in "$@"; do
        resultado=$(sudo systemctl is-active $servicio)
        kdialog --title "Estado del servicio $servicio" --msgbox "El servicio $servicio está en estado: $resultado"
    done
else
    # Mostrar mensaje de error si no se pudieron detener los servicios
    kdialog --error "Error al detener los servicios" "Hubo un problema al intentar detener los servicios $@."
fi
