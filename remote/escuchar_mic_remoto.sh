#!/bin/bash

# Configuración base
HOST_REMOTO=${1:-"cima-ext"}
DISPOSITIVO=${2:-"hw:0,6"}

# Función para ejecutar la transmisión
transmitir() {
    local nombre=$1
    local filtros=$2
    local bitrate=$3

    echo -e "\n--- Iniciando Modo: $nombre ---"
    echo "Host: $HOST_REMOTO | Filtros: $filtros"
    
    # Muteamos remoto y transmitimos
    ssh "$HOST_REMOTO" "amixer -q set Master mute; ffmpeg -hide_banner -loglevel error -f alsa -i $DISPOSITIVO -ac 1 -af \"$filtros\" -c:a libopus -b:a $bitrate -f opus -" | mpv - --no-cache --untimed
}

# Menú interactivo
clear
echo "==============================================="
echo "   MENÚ DE ESCUCHA REMOTA (CIMA-EXT)           "
echo "==============================================="
echo "1) Voz Optimizada (Estándar - Limpio)"
echo "2) Super Ganancia (Para voces lejanas/susurros)"
echo "3) Ultra Reducción de Ruido (Fondo muy ruidoso)"
echo "4) Modo Crudo (Sin filtros - Máxima fidelidad)"
echo "5) Solo Agudos (Corta retumbos y graves)"
echo "q) Salir"
echo "==============================================="
read -p "Selecciona una opción: " opcion

case $opcion in
    1) transmitir "VOZ ESTÁNDAR" "highpass=f=200, lowpass=f=4000, afftdn, volume=2" "48k" ;;
    2) transmitir "SUPER GANANCIA" "afftdn, volume=8, highpass=f=150" "64k" ;;
    3) transmitir "ULTRA DENOISE" "afftdn=nr=20:nf=-25, highpass=f=200, lowpass=f=3500, volume=3" "32k" ;;
    4) transmitir "AUDIO CRUDO" "anull" "96k" ;;
    5) transmitir "BASS CUT" "highpass=f=400, volume=2" "48k" ;;
    q) exit 0 ;;
    *) echo "Opción no válida"; exit 1 ;;
esac
