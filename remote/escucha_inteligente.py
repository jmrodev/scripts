#!/usr/bin/env python3
import os
import sys
import time
import math
import struct
import subprocess
import argparse

# Try to import WebRTC VAD
try:
    import warnings
    warnings.filterwarnings("ignore", category=UserWarning, message="pkg_resources is deprecated")
    import webrtcvad
    HAS_VAD = True
    vad = webrtcvad.Vad(3)
except ImportError:
    HAS_VAD = False

# Default parameters
DEFAULT_HOST = "cima-ext"
DEFAULT_DEVICE = 'plug:"dsnoop:CARD=sofhdadsp,DEV=6"'
DEFAULT_CHANNELS = 2
DEFAULT_THRESHOLD = 0.1
DEFAULT_SILENCE = 8  # Slightly shorter silence timeout for live listening (2 seconds)
DEFAULT_PREBUFFER = 0.5

parser = argparse.ArgumentParser(description="Escucha Inteligente en Vivo con VAD (Squelch)")
parser.add_argument("--host", default=DEFAULT_HOST, help="Host SSH remoto (deja vacío para local)")
parser.add_argument("--device", default=DEFAULT_DEVICE, help="Dispositivo de grabación ALSA")
parser.add_argument("--channels", type=int, default=DEFAULT_CHANNELS, help="Contador de canales (1 o 2)")
parser.add_argument("--threshold", type=float, default=DEFAULT_THRESHOLD, help="Umbral RMS para compuerta de ruido")
parser.add_argument("--silence", type=float, default=DEFAULT_SILENCE, help="Segundos de silencio antes de silenciar parlantes")
parser.add_argument("--prebuffer", type=float, default=DEFAULT_PREBUFFER, help="Segundos de pre-grabación para no cortar inicios")

args = parser.parse_args()

# Build capture command and dynamically handle device quoting for SSH
if args.host:
    escaped_device = args.device.replace('"', '\\"')
    cmd = ["ssh", args.host, "arecord", "-D", escaped_device, "-t", "raw", "-f", "S16_LE", "-r", "16000", "-c", str(args.channels), "-q"]
    print(f"🔊 Iniciando Escucha Inteligente desde: {args.host}")
else:
    cmd = ["arecord", "-D", args.device, "-t", "raw", "-f", "S16_LE", "-r", "16000", "-c", str(args.channels), "-q"]
    print(f"🔊 Iniciando Escucha Inteligente Local")

print(f"   Dispositivo: {args.device}")
print(f"   Canales: {args.channels}")
if HAS_VAD:
    print(f"   Filtro: WebRTC VAD + Compuerta de Ruido (>{args.threshold} RMS)")
else:
    print(f"   Filtro: RMS Umbral ({args.threshold})")
print(f"   Tiempo de Squelch (espera de silencio): {args.silence}s")
print("   Presiona Ctrl+C para salir.\n")

# Audio settings
RATE = 16000
CHUNK_DURATION = 0.030
chunk_size = int(RATE * args.channels * 2 * CHUNK_DURATION)

# VAD sliding window
VAD_WINDOW_SIZE = 10
VAD_TRIGGER_LEVEL = 3
vad_window = []

# Silence count
silence_limit_chunks = int(args.silence / CHUNK_DURATION)
silence_chunks = silence_limit_chunks # start in silent state

is_playing = False

# Spawn arecord capture
capture_process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

# Spawn mpv player configured for raw audio stream
mpv_cmd = [
    "mpv", "-", 
    "--no-cache", 
    "--untimed", 
    f"--demuxer-rawaudio-channels={args.channels}",
    "--demuxer-rawaudio-rate=16000",
    "--demuxer-rawaudio-format=s16le",
    "--demuxer=rawaudio"
]
player_process = subprocess.Popen(mpv_cmd, stdin=subprocess.PIPE, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

try:
    while True:
        data = capture_process.stdout.read(chunk_size)
        if not data:
            err = capture_process.stderr.read()
            if err:
                print(f"\n❌ Error: {err.decode().strip()}", file=sys.stderr)
            break
            
        count = len(data) // 2
        if count == 0:
            continue
            
        shorts = struct.unpack(f"{count}h", data)
        sum_squares = sum((sample / 32768.0) ** 2 for sample in shorts)
        rms = math.sqrt(sum_squares / count)
        
        if args.channels == 2:
            mono_shorts = shorts[::2]
        else:
            mono_shorts = shorts
        mono_data = struct.pack(f"{len(mono_shorts)}h", *mono_shorts)
        
        # VAD speech detection
        speech_detected = False
        if HAS_VAD:
            try:
                speech_detected = vad.is_speech(mono_data, RATE) and (rms >= args.threshold)
            except Exception:
                speech_detected = rms >= args.threshold
        else:
            speech_detected = rms >= args.threshold
            
        # Update window
        vad_window.append(1 if speech_detected else 0)
        if len(vad_window) > VAD_WINDOW_SIZE:
            vad_window.pop(0)
            
        active_speech = sum(vad_window) >= VAD_TRIGGER_LEVEL
        
        if active_speech:
            silence_chunks = 0
            is_playing = True
        else:
            silence_chunks += 1
            if silence_chunks >= silence_limit_chunks:
                is_playing = False
                
        # Audio output routing (Squelch logic)
        try:
            if is_playing:
                player_process.stdin.write(data)
            else:
                # Send digital silence (zeros) to keep the mpv buffer active with zero latency
                player_process.stdin.write(b'\x00' * len(data))
            player_process.stdin.flush()
        except OSError:
            # Player process died (e.g. closed by user)
            break
            
        # Terminal visualizer
        bar_len = min(int(rms * 100), 50)
        bar = "█" * bar_len + "-" * (50 - bar_len)
        status_label = "[ ESCUCHANDO ]" if is_playing else "[ SILENCIADO ]"
        sys.stdout.write(f"\r{status_label} Vol: |{bar}| {rms:.4f} (VAD: {'SI' if speech_detected else 'NO'}) ")
        sys.stdout.flush()
        
except KeyboardInterrupt:
    print("\n\nEscucha finalizada.")
finally:
    capture_process.terminate()
    player_process.terminate()
