#!/bin/bash

# Verificar si el usuario tiene privilegios de superusuario (root)
if [ "$(id -u)" != "0" ]; then
    echo "Este script debe ejecutarse con privilegios de superusuario (root)."

    # Solicitar al usuario que ingrese su contraseña para ejecutar el script con sudo
    echo "Por favor, vuelva a ejecutar este script con sudo:"
    sudo "$0" "$@"  # Ejecutar este script nuevamente con sudo

    # Salir del script actual
    exit 0
fi


echo "Configuración Interactiva de Apache"
echo "-----------------------------------"

check_package_installed() {
    package_name=$1
    if pacman -Qs "$package_name" &> /dev/null; then
        echo "El paquete '$package_name' ya está instalado."
    else
        echo "El paquete '$package_name' no está instalado."
        read -p "¿Desea instalar '$package_name'? (Sí/No): " response
        case "$response" in
            [Ss][Íí]|[Ss][Ii]|[Yy][Ee][Ss]) sudo pacman -S --noconfirm "$package_name" ;;
            *) echo "No se puede continuar sin el paquete '$package_name' instalado." ; exit 1 ;;
        esac
    fi
}


# Verificar si el paquete mariadb está instalado
check_package_installed "apache"

#start enable now 
sudo systemctl enable --now httpd

read -r -p "¿Desea configurar Apache? (Sí/No): " config_response
case "$config_response" in
    [Ss][Íí]|[Ss][Ii]|[Yy][Ee][Ss])
        echo "Continua..."
        ;;
    *)
        echo "Saliendo del script."
        exit 0
        ;;
esac

# Archivo de configuración de Apache
archivo_configuracion="/etc/httpd/conf/httpd.conf"

# Verificar si el archivo de configuración existe
if [ ! -f "$archivo_configuracion" ]; then
    echo "El archivo de configuración '$archivo_configuracion' no existe."
    exit 1
fi

# Pedir al usuario las nuevas configuraciones o usar valores predeterminados
read -r -p "Nuevo DocumentRoot (o dejar en blanco para mantener predeterminado '/srv/http'): " nuevo_document_root
nuevo_document_root=${nuevo_document_root:-"/srv/http"}

read -r -p "Nuevo Puerto (o dejar en blanco para mantener predeterminado '80'): " nuevo_puerto
nuevo_puerto=${nuevo_puerto:-"80"}

read -r -p "Nuevo correo del administrador (o dejar en blanco para mantener predeterminado 'you@example.com'): " nuevo_admin_email
nuevo_admin_email=${nuevo_admin_email:-"you@example.com"}

# Modificar el DocumentRoot
sed -i "s|DocumentRoot \"/srv/http\"|DocumentRoot \"$nuevo_document_root\"|g" "$archivo_configuracion"

# Modificar el puerto
sed -i "s|Listen 80|Listen $nuevo_puerto|g" "$archivo_configuracion"

# Modificar el correo del administrador
sed -i "s|ServerAdmin you@example.com|ServerAdmin $nuevo_admin_email|g" "$archivo_configuracion"

# Reiniciar httpd.service para aplicar los cambios
sudo systemctl restart httpd.service

# Verificar si la instalación/configuración fue exitosa
if [ $? -eq 0 ]; then
xdg-open http://localhost:80

    echo "Apache ha sido instalado y configurado correctamente."
    #enviar mensaje el escritorio notificacion
    notify-send "Apache ha sido instalado y configurado correctamente."

    #pasar el estado a notify
    
    systemctl status httpd.service | notify-send
else
    echo "No se pudo configurar Apache. Por favor, revisa los mensajes de error."
fi
