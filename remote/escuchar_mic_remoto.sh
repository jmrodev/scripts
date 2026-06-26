#!/bin/bash

# Configuración base
HOST_REMOTO=${1:-"cima-ext"}
DISPOSITIVO=${2:-'plug:\"dsnoop:CARD=sofhdadsp,DEV=6\"'}

# Función para ejecutar la transmisión
transmitir() {
    local nombre=$1
    local filtros=$2
    local bitrate=$3

    echo -e "\n--- Iniciando Modo: $nombre ---"
    echo "Host: $HOST_REMOTO | Filtros: $filtros"
    
    # Muteamos remoto y transmitimos
    ssh "$HOST_REMOTO" "amixer -q set Master mute; ffmpeg -hide_banner -loglevel error -f alsa -channels 2 -i $DISPOSITIVO -ac 1 -af \"$filtros\" -c:a libopus -b:a $bitrate -f opus -" | mpv - --no-cache --untimed
}

transmitir_pcm() {
    local nombre=$1
    local rate=$2
    local channels=$3

    echo -e "\n--- Iniciando Modo: $nombre ---"
    echo "Host: $HOST_REMOTO | Formato: PCM Raw | Rate: ${rate}Hz | Canales: $channels"
    
    # Muteamos remoto y transmitimos PCM crudo sin compresión directo a mpv
    ssh "$HOST_REMOTO" "amixer -q set Master mute; arecord -D $DISPOSITIVO -t raw -f S16_LE -r $rate -c $channels -q" | mpv - --no-cache --untimed --demuxer=rawaudio --demuxer-rawaudio-channels=$channels --demuxer-rawaudio-rate=$rate --demuxer-rawaudio-format=s16le
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
echo "6) Estéreo PCM Original Lossless (48kHz - Máxima Calidad)"
echo "q) Salir"
echo "==============================================="
read -p "Selecciona una opción: " opcion

case $opcion in
    1) transmitir "VOZ ESTÁNDAR" "highpass=f=200, lowpass=f=4000, afftdn, volume=2" "48k" ;;
    2) transmitir "SUPER GANANCIA" "afftdn, volume=8, highpass=f=150" "64k" ;;
    3) transmitir "ULTRA DENOISE" "afftdn=nr=20:nf=-25, highpass=f=200, lowpass=f=3500, volume=3" "32k" ;;
    4) transmitir "AUDIO CRUDO" "anull" "96k" ;;
    5) transmitir "BASS CUT" "highpass=f=400, volume=2" "48k" ;;
    6) transmitir_pcm "ESTÉREO PCM ORIGINAL" "48000" "2" ;;
    q) exit 0 ;;
    *) echo "Opción no válida"; exit 1 ;;
esac
