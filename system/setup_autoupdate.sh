#!/bin/bash

# Script para instalar la actualización automática al inicio (estilo jmro)
# Compatible con Arch Linux y derivados (Manjaro, EndeavourOS, etc.)

set -e

SCRIPT_PATH="/usr/local/bin/mantenimiento-inicio.sh"
AUTOSTART_DIR="$HOME/.config/autostart"
DESKTOP_FILE="$AUTOSTART_DIR/mantenimiento-visible.desktop"
USER_NAME=$(whoami)

echo "=== Instalador de Mantenimiento Automático ==="

# 1. Crear el script de mantenimiento en /usr/local/bin
echo "[+] Creando script de mantenimiento en $SCRIPT_PATH..."
sudo bash -c "cat << 'EOF' > $SCRIPT_PATH
#!/bin/bash
# Script de mantenimiento optimizado para Arch Linux
echo \"=== Iniciando Mantenimiento del Sistema ===\"
date

# Eliminar bloqueos de pacman si existen
if [ -f /var/lib/pacman/db.lck ]; then
    echo \"[-] Eliminando bloqueo de base de datos...\"
    rm -f /var/lib/pacman/db.lck
fi

# Esperar internet (máximo 30 seg)
echo \"[+] Verificando conexión a internet...\"
timeout 30s bash -c 'until ping -c 1 8.8.8.8 &>/dev/null; do sleep 2; done' || { echo \"Error: Sin internet\"; exit 1; }

# Refrescar espejos (solo si pacman-mirrors existe - Manjaro)
if command -v pacman-mirrors &>/dev/null; then
    echo \"[+] Actualizando espejos (Manjaro)...\"
    pacman-mirrors -f 5
fi

# Actualización
echo \"[+] Iniciando actualización del sistema...\"
if command -v pamac &>/dev/null; then
    pamac upgrade --no-confirm
else
    echo \"[+] Usando pacman...\"
    pacman -Syu --noconfirm
fi

# Limpieza de huérfanos
echo \"[+] Limpiando huérfanos...\"
if command -v pamac &>/dev/null; then
    pamac remove --orphans --no-confirm
else
    if [[ -n \$(pacman -Qdtq) ]]; then
        pacman -Rs \$(pacman -Qdtq) --noconfirm
    fi
fi

echo \"=== Mantenimiento finalizado: \$(date) ===\"
echo \"La ventana se cerrará automáticamente en 5 segundos...\"
sleep 5
EOF"

sudo chmod +x "$SCRIPT_PATH"
sudo chown $USER_NAME:$USER_NAME "$SCRIPT_PATH"

# 2. Configurar sudoers para no pedir contraseña
echo "[+] Configurando sudoers para $USER_NAME..."
SUDOERS_FILE="/etc/sudoers.d/99-mantenimiento-inicio"
sudo bash -c "echo '$USER_NAME ALL=(ALL) NOPASSWD: $SCRIPT_PATH' > $SUDOERS_FILE"
sudo chmod 440 "$SUDOERS_FILE"

# 3. Crear el lanzador de autostart
echo "[+] Creando lanzador en $DESKTOP_FILE..."
mkdir -p "$AUTOSTART_DIR"

# Intentar detectar terminal preferida (konsole o xterm)
TERM_CMD="xterm -geometry 80x24 -fa 'Monospace' -fs 8 -bg black -fg white -title 'Mantenimiento de Sistema' -e"
if command -v konsole &>/dev/null; then
    TERM_CMD="konsole --hold -e"
fi

cat << EOF > "$DESKTOP_FILE"
[Desktop Entry]
Type=Application
Name=Actualización de Sistema
Comment=Ejecuta mantenimiento visible al arrancar
Exec=$TERM_CMD sudo $SCRIPT_PATH
Icon=system-software-update
Terminal=false
Categories=System;
X-KDE-Autostart-Delay=10
EOF

chmod +x "$DESKTOP_FILE"

echo "=== Instalación completada con éxito ==="
echo "El sistema se actualizará automáticamente en el próximo inicio de sesión."
