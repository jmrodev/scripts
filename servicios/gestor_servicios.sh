#!/bin/bash

# Solicitar contraseña de sudo al inicio de la aplicación
PASSWORD=$(zenity --password --title="Autenticación requerida" --text="Ingrese su contraseña para gestionar servicios:")
if [ -z "$PASSWORD" ]; then
    zenity --error --title="Error" --text="No se ingresó una contraseña. La aplicación se cerrará."
    exit 1
fi

# Agregar un salto de línea al final de la contraseña
PASSWORD="$PASSWORD\n"

# Verificar que la contraseña sea correcta
echo -e "$PASSWORD" | sudo -S true 2>/dev/null
if [ $? -ne 0 ]; then
    zenity --error --title="Error" --text="Contraseña incorrecta. La aplicación se cerrará."
    exit 1
fi

# Lista de servicios
servicios=("ModemManager" "packagekit" "avahi-daemon" "colord" "nmb" "smb" "power-profiles-daemon" "rtkit-daemon" "NetworkManager-wait-online" "cups-browsed" "bluetooth" "wpa_supplicant" "org.cups.cupsd" "httpd" "webmin" "sshd")

# Función para obtener el estado de un servicio
get_status() {
    local servicio=$1
    if systemctl is-active --quiet "$servicio.service"; then
        echo "Encendido"
    else
        echo "Apagado"
    fi
}

# Crear la interfaz gráfica
while true; do
    # Crear una lista de opciones para zenity
    opciones=()
    for servicio in "${servicios[@]}"; do
        estado=$(get_status "$servicio")
        opciones+=("$servicio" "$estado")
    done

    # Mostrar la interfaz gráfica con una ventana más grande
    seleccion=$(zenity --list --title="Gestión de Servicios" --column="Servicio" --column="Estado" "${opciones[@]}" --extra-button="Salir" --width=600 --height=400)

    # Si el usuario selecciona "Salir", salir del bucle
    if [ "$seleccion" == "Salir" ]; then
        break
    fi

    # Si el usuario selecciona un servicio, mostrar opciones para iniciar/detener
    if [ -n "$seleccion" ]; then
        accion=$(zenity --list --title="Acción para $seleccion" --column="Acción" "Iniciar" "Detener" --width=300 --height=200)
        if [ "$accion" == "Iniciar" ]; then
            echo -e "$PASSWORD" | sudo -S systemctl start "$seleccion.service"
        elif [ "$accion" == "Detener" ]; then
            echo -e "$PASSWORD" | sudo -S systemctl stop "$seleccion.service"
        fi
    fi
done
