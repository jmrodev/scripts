#!/usr/bin/env python3
import json
import subprocess
import sys
import time

def run_cmd(cmd):
    try:
        return subprocess.check_output(cmd, shell=True).decode('utf-8')
    except subprocess.CalledProcessError:
        return ""

def wait_for_sink(sink_name, timeout=1.5):
    start_time = time.time()
    while time.time() - start_time < timeout:
        sinks_short = run_cmd("pactl list short sinks")
        if sink_name in sinks_short:
            return True
        time.sleep(0.05)
    return False

def main():
    # Fetch cards
    cards_json = run_cmd("pactl -f json list cards")
    if not cards_json:
        print("Error: No se pudo obtener la información de las tarjetas de sonido.")
        sys.exit(1)
    
    try:
        cards = json.loads(cards_json)
    except Exception as e:
        print(f"Error parseando JSON de tarjetas: {e}")
        sys.exit(1)

    # Fetch sinks
    sinks_json = run_cmd("pactl -f json list sinks")
    sinks = []
    if sinks_json:
        try:
            sinks = json.loads(sinks_json)
        except Exception:
            pass

    options = []
    
    for card in cards:
        card_name = card.get("name", "")
        # Look for the main sound card
        if "alsa_card" not in card_name:
            continue
            
        ports = card.get("ports", {})
        profiles = card.get("profiles", {})
        
        # Speakers
        spk_port = ports.get("analog-output-speaker")
        if spk_port:
            available = spk_port.get("availability", "") != "not available"
            options.append({
                "label": "📢 Altavoces Internos" + ("" if available else " [No disponible]"),
                "type": "port",
                "card": card_name,
                "profile": "output:analog-stereo+input:analog-stereo",
                "port": "analog-output-speaker",
                "priority": 10 if available else 1
            })
            
        # Headphones
        hp_port = ports.get("analog-output-headphones")
        if hp_port:
            available = hp_port.get("availability", "") != "not available"
            options.append({
                "label": "🎧 Auriculares" + (" [Conectado]" if available else " [No disponible]"),
                "type": "port",
                "card": card_name,
                "profile": "output:analog-stereo+input:analog-stereo",
                "port": "analog-output-headphones",
                "priority": 12 if available else 2
            })
            
        # HDMI ports
        for port_name, port_info in ports.items():
            if port_name.startswith("hdmi-output-"):
                available = port_info.get("availability", "") != "not available"
                desc = port_info.get("description", "HDMI / DisplayPort")
                
                suffix = port_name.split("-")[-1] # "0", "1", "2"
                profile_base = "hdmi-stereo"
                if suffix == "1":
                    profile_base = "hdmi-stereo-extra1"
                elif suffix == "2":
                    profile_base = "hdmi-stereo-extra2"
                
                matching_profile = f"output:{profile_base}+input:analog-stereo"
                if matching_profile not in profiles:
                    matching_profile = f"output:{profile_base}"
                
                status_label = " [Conectado]" if available else " [Desconectado]"
                options.append({
                    "label": f"📺 {desc}{status_label}",
                    "type": "hdmi",
                    "card": card_name,
                    "profile": matching_profile,
                    "priority": 8 if available else 0
                })

    # External/Bluetooth sinks
    for sink in sinks:
        sink_name = sink.get("name", "")
        if "analog-stereo" in sink_name or "hdmi-stereo" in sink_name:
            continue
            
        desc = sink.get("properties", {}).get("device.description") or sink.get("description") or sink_name
        label = f"🎵 {desc}"
        if "bluez" in sink_name or "bluetooth" in sink_name.lower():
            label = f"󰋋 {desc} (Bluetooth)"
            
        options.append({
            "label": label,
            "type": "sink",
            "sink": sink_name,
            "priority": 9
        })

    # Sort options by priority descending
    options.sort(key=lambda x: x["priority"], reverse=True)

    if not options:
        print("No se encontraron salidas de audio.")
        sys.exit(0)

    # Format wofi input
    wofi_lines = [opt["label"] for opt in options]
    wofi_input = "\n".join(wofi_lines)

    # Run wofi
    try:
        proc = subprocess.Popen(
            ["wofi", "--dmenu", "--prompt", "Seleccionar salida de audio:", "--width", "400", "--height", "250"],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        selected_label, _ = proc.communicate(input=wofi_input)
        selected_label = selected_label.strip()
    except Exception as e:
        print(f"Error al ejecutar wofi: {e}")
        sys.exit(1)

    if not selected_label:
        # User cancelled
        sys.exit(0)

    # Find chosen option
    chosen = None
    for opt in options:
        if opt["label"] == selected_label:
            chosen = opt
            break

    if not chosen:
        print("Opción no válida.")
        sys.exit(1)

    # Apply choice
    if chosen["type"] == "sink":
        run_cmd(f"pactl set-default-sink {chosen['sink']}")
        print(f"Salida de audio cambiada a: {chosen['label']}")
    elif chosen["type"] == "port":
        # Set card profile first
        run_cmd(f"pactl set-card-profile {chosen['card']} {chosen['profile']}")
        sink_name = chosen["card"].replace("alsa_card", "alsa_output") + ".analog-stereo"
        if wait_for_sink(sink_name):
            run_cmd(f"pactl set-sink-port {sink_name} {chosen['port']}")
            run_cmd(f"pactl set-default-sink {sink_name}")
            print(f"Salida de audio cambiada a: {chosen['label']}")
        else:
            print(f"Error: La salida analógica no estuvo disponible a tiempo.")
    elif chosen["type"] == "hdmi":
        # Set card profile
        run_cmd(f"pactl set-card-profile {chosen['card']} {chosen['profile']}")
        profile_base = chosen["profile"].replace("output:", "").split("+")[0]
        sink_name = chosen["card"].replace("alsa_card", "alsa_output") + f".{profile_base}"
        if wait_for_sink(sink_name):
            run_cmd(f"pactl set-default-sink {sink_name}")
            print(f"Salida de audio cambiada a: {chosen['label']}")
        else:
            print(f"Error: La salida HDMI no estuvo disponible a tiempo.")

if __name__ == "__main__":
    main()
