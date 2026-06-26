#!/usr/bin/env python3
import os
import sys
import time
import math
import struct
import wave
import subprocess
import argparse
from datetime import datetime

# Try to import WebRTC VAD
try:
    import warnings
    warnings.filterwarnings("ignore", category=UserWarning, message="pkg_resources is deprecated")
    import webrtcvad
    HAS_VAD = True
    vad = webrtcvad.Vad(3) # Aggressiveness 3 is the most strict (speech only)
except ImportError:
    HAS_VAD = False

# Default parameters
DEFAULT_HOST = "cima-ext"
DEFAULT_DEVICE = 'plug:"dsnoop:CARD=sofhdadsp,DEV=6"'
DEFAULT_CHANNELS = 2
DEFAULT_THRESHOLD = 0.1
DEFAULT_SILENCE = 8.0
DEFAULT_PREBUFFER = 1.0

parser = argparse.ArgumentParser(description="Grabador Inteligente activado por voz (VAD)")
parser.add_argument("--host", default=DEFAULT_HOST, help="Host SSH remoto (deja vacío para grabar local)")
parser.add_argument("--device", default=DEFAULT_DEVICE, help="Dispositivo de grabación ALSA (ej: hw:0,6 o default)")
parser.add_argument("--channels", type=int, default=DEFAULT_CHANNELS, help="Contador de canales de audio (1 o 2)")
parser.add_argument("--threshold", type=float, default=DEFAULT_THRESHOLD, help="Umbral RMS para compuerta de ruido / fallback (0.0 a 1.0)")
parser.add_argument("--silence", type=float, default=DEFAULT_SILENCE, help="Segundos de silencio antes de cortar")
parser.add_argument("--prebuffer", type=float, default=DEFAULT_PREBUFFER, help="Segundos de pre-grabación para no cortar inicios")
parser.add_argument("--outdir", default=os.path.expanduser("~/recordings"), help="Directorio de salida")

args = parser.parse_args()

os.makedirs(args.outdir, exist_ok=True)

# Build command and dynamically handle device quoting for SSH
if args.host:
    escaped_device = args.device.replace('"', '\\"')
    cmd = ["ssh", args.host, "arecord", "-D", escaped_device, "-t", "raw", "-f", "S16_LE", "-r", "16000", "-c", str(args.channels), "-q"]
    print(f"🎤 Iniciando Grabación Remota en Host: {args.host}")
else:
    cmd = ["arecord", "-D", args.device, "-t", "raw", "-f", "S16_LE", "-r", "16000", "-c", str(args.channels), "-q"]
    print(f"🎤 Iniciando Grabación Local")

print(f"   Dispositivo: {args.device}")
print(f"   Canales: {args.channels}")
if HAS_VAD:
    print(f"   Filtro Inteligente: WebRTC VAD + Compuerta de Ruido (>{args.threshold} RMS)")
else:
    print(f"   Filtro Inteligente: RMS Umbral ({args.threshold})")
print(f"   Espera de Silencio: {args.silence}s")
print(f"   Pre-grabación buffer: {args.prebuffer}s")
print(f"   Guardando en: {args.outdir}")
print("   Presiona Ctrl+C para salir.\n")

# Setup values (WebRTC VAD requires exactly 10, 20, or 30ms frames)
RATE = 16000
CHUNK_DURATION = 0.030 # 30ms chunks
chunk_size = int(RATE * args.channels * 2 * CHUNK_DURATION) # 30ms chunk in bytes
pre_buffer_chunks = int(args.prebuffer / CHUNK_DURATION)
pre_buffer = []

is_recording = False
recording_frames = []
silence_chunks = 0
silence_limit_chunks = int(args.silence / CHUNK_DURATION)
output_file = None

# VAD sliding window to smooth speech detection
VAD_WINDOW_SIZE = 10     # 300ms window
VAD_TRIGGER_LEVEL = 3    # Trigger/maintain recording if at least 3 chunks in window have speech
vad_window = []

process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

try:
    while True:
        data = process.stdout.read(chunk_size)
        if not data:
            # Check stderr for errors
            err = process.stderr.read()
            if err:
                print(f"\n❌ Error de arecord/ssh: {err.decode().strip()}", file=sys.stderr)
            break
            
        count = len(data) // 2
        if count == 0:
            continue
            
        # Parse PCM samples and calculate RMS
        shorts = struct.unpack(f"{count}h", data)
        sum_squares = sum((sample / 32768.0) ** 2 for sample in shorts)
        rms = math.sqrt(sum_squares / count)
        
        # Extract mono channel for VAD
        if args.channels == 2:
            mono_shorts = shorts[::2]
        else:
            mono_shorts = shorts
        mono_data = struct.pack(f"{len(mono_shorts)}h", *mono_shorts)
        
        # Classify speech
        speech_detected = False
        if HAS_VAD:
            try:
                # Hybrid filter: requires both WebRTC VAD validation AND volume above noise floor
                speech_detected = vad.is_speech(mono_data, RATE) and (rms >= args.threshold)
            except Exception:
                speech_detected = rms >= args.threshold
        else:
            speech_detected = rms >= args.threshold
            
        # Update sliding window
        vad_window.append(1 if speech_detected else 0)
        if len(vad_window) > VAD_WINDOW_SIZE:
            vad_window.pop(0)
            
        # Decision based on density of the window
        active_speech = sum(vad_window) >= VAD_TRIGGER_LEVEL
        
        # Draw dynamic volume bar in console
        bar_len = min(int(rms * 100), 50)
        bar = "█" * bar_len + "-" * (50 - bar_len)
        status_label = "[GRABANDO] " if is_recording else "[ESPERANDO]"
        sys.stdout.write(f"\r{status_label} Vol: |{bar}| {rms:.4f} (VAD: {'SI' if speech_detected else 'NO'}) ")
        sys.stdout.flush()
        
        pre_buffer.append(data)
        if len(pre_buffer) > pre_buffer_chunks:
            pre_buffer.pop(0)
            
        if is_recording:
            recording_frames.append(data)
            if not active_speech:
                silence_chunks += 1
            else:
                silence_chunks = 0
                
            if silence_chunks >= silence_limit_chunks:
                # Stop recording
                is_recording = False
                sys.stdout.write("\n - Silencio detectado. Guardando archivo...\n")
                
                filepath = os.path.join(args.outdir, output_file)
                wf = wave.open(filepath, 'wb')
                wf.setnchannels(args.channels)
                wf.setsampwidth(2)
                wf.setframerate(RATE)
                wf.writeframes(b"".join(recording_frames))
                wf.close()
                print(f"💾 Guardado: {filepath}\n")
                recording_frames = []
                vad_window = [] # Reset VAD window for next capture
        else:
            if active_speech:
                # Trigger recording
                is_recording = True
                silence_chunks = 0
                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                output_file = f"grabacion_{timestamp}.wav"
                sys.stdout.write(f"\n⚡ Voz detectada! Iniciando grabación: {output_file}...\n")
                recording_frames = list(pre_buffer)
                
except KeyboardInterrupt:
    print("\n\nGrabador finalizado.")
finally:
    process.terminate()
