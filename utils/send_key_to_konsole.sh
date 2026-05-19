#!/bin/bash

# Función para mostrar el uso del script
function show_usage() {
    echo "Uso: $0 [-s SECUENCIA] [-d DELAY]"
    echo "  -s SECUENCIA   Secuencia de teclas a enviar (por ejemplo: 'ctrl+a Alt_L+x')"
    echo "  -d DELAY       Retardo en milisegundos antes de repetir la secuencia (predeterminado: 1000)"
    exit 1
}

# Variables predeterminadas
SEQUENCE="2 Return"
DELAY=1000

# Parsear los argumentos de la línea de comandos
while getopts "s:d:" opt; do
    case $opt in
        s) SEQUENCE=$OPTARG ;;
        d) DELAY=$OPTARG ;;
        *) show_usage ;;
    esac
done

# Capturar el ID de la ventana bajo el puntero del ratón
TARGET_WINDOW_ID=$(xdotool selectwindow)

# Verificar si TARGET_WINDOW_ID está definido
if [ -z "$TARGET_WINDOW_ID" ]; then
    echo "Error: No se pudo determinar el ID de la ventana."
    exit 1
fi

# Función para manejar señales de interrupción/terminación
handle_interrupt() {
    echo
    echo "Deteniendo el script..."
    exit 130
}

trap handle_interrupt SIGINT SIGTERM

# Informar al usuario
echo "Enviando la secuencia de teclas '$SEQUENCE' a la ventana $TARGET_WINDOW_ID cada $DELAY milisegundos."

# Enviar las pulsaciones de teclas a la ventana objetivo
while true; do
    xdotool key --window $TARGET_WINDOW_ID $SEQUENCE
    sleep $(echo "scale=2; $DELAY/1000" | bc)
done
