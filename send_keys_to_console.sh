#!/bin/bash

# Función para mostrar el uso del script
function show_usage() {
    echo "Uso: $0 [-c COMANDO] [-d DELAY]"
    echo "  -c COMANDO     Comando a enviar (por ejemplo: 'ls')"
    echo "  -d DELAY       Retardo en milisegundos antes de repetir el comando (predeterminado: 1000)"
    exit 1
}

# Variables predeterminadas
COMMAND=""
DELAY=2

# Parsear los argumentos de la línea de comandos
while getopts "c:d:" opt; do
    case $opt in
        c) COMMAND=$OPTARG ;;
        d) DELAY=$OPTARG ;;
        *) show_usage ;;
    esac
done

# Si no se proporcionó un comando, pedir al usuario que lo ingrese
if [ -z "$COMMAND" ]; then
    echo "Por favor, ingresa el comando a enviar (por ejemplo: 'ls'):"
    read COMMAND
fi

# Capturar el ID de la ventana bajo el puntero del ratón
TARGET_WINDOW_ID=$(xdotool selectwindow)

# Verificar si TARGET_WINDOW_ID está definido
if [ -z "$TARGET_WINDOW_ID" ]; then
    echo "Error: No se pudo determinar el ID de la ventana."
    exit 1
fi

# Función para manejar la señal de interrupción (Ctrl+C)
trap "echo 'Deteniendo el script...'; exit 0" SIGINT

# Informar al usuario
echo "Enviando el comando '$COMMAND' a la ventana $TARGET_WINDOW_ID cada $DELAY milisegundos."

# Enviar el comando a la ventana objetivo
while true; do
    xdotool type --window $TARGET_WINDOW_ID "$COMMAND"
    xdotool key --window $TARGET_WINDOW_ID "Return"
    sleep $(echo "scale=2; $DELAY/1000" | bc)
done
