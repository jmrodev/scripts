#!/bin/bash
# Variables para tamaños de ventanas de Zenity
ZENITY_LIST_WIDTH=800
ZENITY_LIST_HEIGHT=600
ZENITY_ACTION_WIDTH=600
ZENITY_ACTION_HEIGHT=400
# Directorio donde se almacenarán los scripts
SCRIPT_DIR="/home/$USER/scripts/servicios/zenity-service/app"
SCRIPTS_SUBDIR="$SCRIPT_DIR/scripts"

# Verificar si el directorio de scripts existe, y crearlo si no existe
if [ ! -d "$SCRIPTS_SUBDIR" ]; then
    mkdir -p "$SCRIPTS_SUBDIR" || { echo "Error: No se pudo crear el directorio $SCRIPTS_SUBDIR."; exit 1; }
    echo "Directorio $SCRIPTS_SUBDIR creado."
fi

# Lista de servicios
servicios=("ModemManager" "packagekit" "avahi-daemon" "colord" "nmb" "smb" "power-profiles-daemon" "rtkit-daemon" "NetworkManager-wait-online" "cups-browsed" "bluetooth" "wpa_supplicant" "org.cups.cupsd" "httpd" "webmin" "sshd")

# Crear los scripts de inicio/detención para cada servicio
for servicio in "${servicios[@]}"; do
    # Script de inicio
    cat <<EOF > "$SCRIPTS_SUBDIR/start_${servicio}.sh"
#!/bin/bash
sudo systemctl start ${servicio}.service
EOF
    
    # Script de detención
    cat <<EOF > "$SCRIPTS_SUBDIR/stop_${servicio}.sh"
#!/bin/bash
sudo systemctl stop ${servicio}.service
EOF
    
    echo "Scripts para $servicio creados en $SCRIPTS_SUBDIR."
done

# Hacer que los scripts sean ejecutables
chmod +x "$SCRIPTS_SUBDIR"/start_*.sh "$SCRIPTS_SUBDIR"/stop_*.sh || { echo "Error: No se pudieron asignar permisos ejecutables a los scripts."; exit 1; }
echo "Scripts de inicio/detención hechos ejecutables."



# Crear el script principal de gestión de servicios
cat <<EOF > "$SCRIPT_DIR/gestor_servicios.sh"
#!/bin/bash

# Solicitar contraseña de sudo al inicio de la aplicación
PASSWORD=\$(zenity --password --title="Autenticación requerida" --text="Ingrese su contraseña para gestionar servicios:")
if [ -z "\$PASSWORD" ]; then
    zenity --error --title="Error" --text="No se ingresó una contraseña. La aplicación se cerrará."
    exit 1
fi

# Agregar un salto de línea al final de la contraseña
PASSWORD="\$PASSWORD\n"

# Verificar que la contraseña sea correcta
echo -e "\$PASSWORD" | sudo -S true 2>/dev/null
if [ \$? -ne 0 ]; then
    zenity --error --title="Error" --text="Contraseña incorrecta. La aplicación se cerrará."
    exit 1
fi

# Lista de servicios
servicios=("ModemManager" "packagekit" "avahi-daemon" "colord" "nmb" "smb" "power-profiles-daemon" "rtkit-daemon" "NetworkManager-wait-online" "cups-browsed" "bluetooth" "wpa_supplicant" "org.cups.cupsd" "httpd" "webmin" "sshd")

# Función para obtener el estado de un servicio
get_status() {
    local servicio=\$1
    if systemctl is-active --quiet "\$servicio.service"; then
        echo "Encendido"
    else
        echo "Apagado"
    fi
}

# Crear la interfaz gráfica
while true; do
    # Crear una lista de opciones para zenity
    opciones=("Encender todos" "Acción global" "Apagar todos" "Acción global" "Habilitar todos" "Acción global" "Deshabilitar todos" "Acción global")
    for servicio in "\${servicios[@]}"; do
        estado=\$(get_status "\$servicio")
        opciones+=("\$servicio" "\$estado")
    done

    # Mostrar la interfaz gráfica con una ventana más grande
    seleccion=\$(zenity --list --title="Gestión de Servicios" --column="Servicio" --column="Estado" "\${opciones[@]}" --extra-button="Salir" --width=$ZENITY_LIST_WIDTH --height=$ZENITY_LIST_HEIGHT)

    # Si el usuario selecciona "Salir", salir del bucle
    if [ "\$seleccion" == "Salir" ]; then
        break
    fi

    # Si el usuario selecciona "Encender todos"
    if [ "\$seleccion" == "Encender todos" ]; then
        for servicio in "\${servicios[@]}"; do
            echo -e "\$PASSWORD" | sudo -S systemctl start "\$servicio.service"
        done
        zenity --info --title="Encender todos" --text="Todos los servicios han sido encendidos."
        continue
    fi

    # Si el usuario selecciona "Apagar todos"
    if [ "\$seleccion" == "Apagar todos" ]; then
        for servicio in "\${servicios[@]}"; do
            echo -e "\$PASSWORD" | sudo -S systemctl stop "\$servicio.service"
        done
        zenity --info --title="Apagar todos" --text="Todos los servicios han sido apagados."
        continue
    fi

    # Si el usuario selecciona "Habilitar todos"
    if [ "\$seleccion" == "Habilitar todos" ]; then
        for servicio in "\${servicios[@]}"; do
            echo -e "\$PASSWORD" | sudo -S systemctl enable "\$servicio.service"
        done
        zenity --info --title="Habilitar todos" --text="Todos los servicios han sido habilitados."
        continue
    fi

    # Si el usuario selecciona "Deshabilitar todos"
    if [ "\$seleccion" == "Deshabilitar todos" ]; then
        for servicio in "\${servicios[@]}"; do
            echo -e "\$PASSWORD" | sudo -S systemctl disable "\$servicio.service"
        done
        zenity --info --title="Deshabilitar todos" --text="Todos los servicios han sido deshabilitados."
        continue
    fi

    # Si el usuario selecciona un servicio, mostrar opciones para iniciar/detener/habilitar/deshabilitar
    if [ -n "\$seleccion" ]; then
        accion=\$(zenity --list --title="Acción para \$seleccion" --column="Acción" "Iniciar" "Detener" "Habilitar" "Deshabilitar" --width=$ZENITY_ACTION_WIDTH --height=$ZENITY_ACTION_HEIGHT)
        if [ "\$accion" == "Iniciar" ]; then
            echo -e "\$PASSWORD" | sudo -S systemctl start "\$seleccion.service"
        elif [ "\$accion" == "Detener" ]; then
            echo -e "\$PASSWORD" | sudo -S systemctl stop "\$seleccion.service"
        elif [ "\$accion" == "Habilitar" ]; then
            echo -e "\$PASSWORD" | sudo -S systemctl enable "\$seleccion.service"
        elif [ "\$accion" == "Deshabilitar" ]; then
            echo -e "\$PASSWORD" | sudo -S systemctl disable "\$seleccion.service"
        fi
    fi
done
EOF

# Hacer que el script principal sea ejecutable
chmod +x "$SCRIPT_DIR/gestor_servicios.sh" || { echo "Error: No se pudo asignar permisos ejecutables al script principal."; exit 1; }
echo "Script principal de gestión de servicios creado y hecho ejecutable."

# Crear archivo .desktop para la aplicación de gestión de servicios
DESKTOP_DIR="/home/$USER/.local/share/applications"
if [ ! -d "$DESKTOP_DIR" ]; then
    mkdir -p "$DESKTOP_DIR" || { echo "Error: No se pudo crear el directorio $DESKTOP_DIR."; exit 1; }
    echo "Directorio $DESKTOP_DIR creado."
fi

cat <<EOF > "$DESKTOP_DIR/gestor_servicios.desktop"
[Desktop Entry]
Type=Application
Name=Gestor de Servicios
Exec=/home/$USER/scripts/servicios/zenity-service/app/gestor_servicios.sh
Icon=system-run
Comment=Gestiona los servicios del sistema
EOF

# Asegurar que el archivo .desktop sea ejecutable
chmod +x "$DESKTOP_DIR/gestor_servicios.desktop" || { echo "Error: No se pudo asignar permisos ejecutables al archivo .desktop."; exit 1; }
echo "Archivo .desktop para la aplicación de gestión de servicios creado en $DESKTOP_DIR."

# Mensaje final
echo "¡Configuración completada!"
echo "Puedes ejecutar la aplicación 'Gestor de Servicios' desde el menú de aplicaciones."
