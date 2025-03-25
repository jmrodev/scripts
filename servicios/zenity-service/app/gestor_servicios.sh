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
    opciones=("Encender todos" "Acción global" "Apagar todos" "Acción global" "Habilitar todos" "Acción global" "Deshabilitar todos" "Acción global")
    for servicio in "${servicios[@]}"; do
        estado=$(get_status "$servicio")
        opciones+=("$servicio" "$estado")
    done

    # Mostrar la interfaz gráfica con una ventana más grande
    seleccion=$(zenity --list --title="Gestión de Servicios" --column="Servicio" --column="Estado" "${opciones[@]}" --extra-button="Salir" --width=800 --height=600)

    # Si el usuario selecciona "Salir", salir del bucle
    if [ "$seleccion" == "Salir" ]; then
        break
    fi

    # Si el usuario selecciona "Encender todos"
    if [ "$seleccion" == "Encender todos" ]; then
        for servicio in "${servicios[@]}"; do
            echo -e "$PASSWORD" | sudo -S systemctl start "$servicio.service"
        done
        zenity --info --title="Encender todos" --text="Todos los servicios han sido encendidos."
        continue
    fi

    # Si el usuario selecciona "Apagar todos"
    if [ "$seleccion" == "Apagar todos" ]; then
        for servicio in "${servicios[@]}"; do
            echo -e "$PASSWORD" | sudo -S systemctl stop "$servicio.service"
        done
        zenity --info --title="Apagar todos" --text="Todos los servicios han sido apagados."
        continue
    fi

    # Si el usuario selecciona "Habilitar todos"
    if [ "$seleccion" == "Habilitar todos" ]; then
        for servicio in "${servicios[@]}"; do
            echo -e "$PASSWORD" | sudo -S systemctl enable "$servicio.service"
        done
        zenity --info --title="Habilitar todos" --text="Todos los servicios han sido habilitados."
        continue
    fi

    # Si el usuario selecciona "Deshabilitar todos"
    if [ "$seleccion" == "Deshabilitar todos" ]; then
        for servicio in "${servicios[@]}"; do
            echo -e "$PASSWORD" | sudo -S systemctl disable "$servicio.service"
        done
        zenity --info --title="Deshabilitar todos" --text="Todos los servicios han sido deshabilitados."
        continue
    fi

    # Si el usuario selecciona un servicio, mostrar opciones para iniciar/detener/habilitar/deshabilitar
    if [ -n "$seleccion" ]; then
        accion=$(zenity --list --title="Acción para $seleccion" --column="Acción" "Iniciar" "Detener" "Habilitar" "Deshabilitar" --width=600 --height=400)
        if [ "$accion" == "Iniciar" ]; then
            echo -e "$PASSWORD" | sudo -S systemctl start "$seleccion.service"
        elif [ "$accion" == "Detener" ]; then
            echo -e "$PASSWORD" | sudo -S systemctl stop "$seleccion.service"
        elif [ "$accion" == "Habilitar" ]; then
            echo -e "$PASSWORD" | sudo -S systemctl enable "$seleccion.service"
        elif [ "$accion" == "Deshabilitar" ]; then
            echo -e "$PASSWORD" | sudo -S systemctl disable "$seleccion.service"
        fi
    fi
done
