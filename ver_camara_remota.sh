#!/bin/bash

# Configuración por defecto
HOST_REMOTO=${1:-"cima@Antigravity"}
DISPOSITIVO=${2:-"/dev/video0"}
RESOLUCION=${3:-"640x480"}
FPS=${4:-"30"}

echo "Iniciando transmisión de video..."
echo "Host: $HOST_REMOTO"
echo "Cámara: $DISPOSITIVO"
echo "Calidad: $RESOLUCION a ${FPS}fps"
echo "-----------------------------------"
echo "Presiona Ctrl+C en esta terminal o cierra la ventana de video para detener."

# Ejecutar el comando
ssh "$HOST_REMOTO" "ffmpeg -hide_banner -loglevel error -f v4l2 -framerate $FPS -video_size $RESOLUCION -i $DISPOSITIVO -f matroska -" | mpv -
