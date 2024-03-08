#!/bin/bash

echo "Configuración Interactiva de Apache"
echo "-----------------------------------"


# Verificar si el usuario tiene privilegios de superusuario
if [ "$(id -u)" != "0" ]; then
    echo "Este script debe ejecutarse con privilegios de superusuario (root)."
    exit 1
fi


# Verificar si Apache está instalado en Arch Linux
if command -v httpd > /dev/null; then
    apache_version=$(httpd -v | awk 'NR==1 {print $3}')
    echo "Apache $apache_version está instalado."



# Archivo de configuración de Apache
archivo_configuracion="/etc/httpd/conf/httpd.conf"

# Verificar si el archivo de configuración existe
if [ ! -f "$archivo_configuracion" ]; then
    echo "El archivo de configuración '$archivo_configuracion' no existe."
    exit 1
fi

# Pedir al usuario las nuevas configuraciones o usar valores predeterminados
read -p "Nuevo DocumentRoot (o dejar en blanco para mantener predeterminado '/srv/http'): " nuevo_document_root
nuevo_document_root=${nuevo_document_root:-"/srv/http"}

read -p "Nuevo Puerto (o dejar en blanco para mantener predeterminado '80'): " nuevo_puerto
nuevo_puerto=${nuevo_puerto:-"80"}

read -p "Nuevo correo del administrador (o dejar en blanco para mantener predeterminado 'you@example.com'): " nuevo_admin_email
nuevo_admin_email=${nuevo_admin_email:-"you@example.com"}


# Modificar el DocumentRoot
sed -i "s|DocumentRoot \"/srv/http\"|DocumentRoot \"$nuevo_document_root\"|g" $archivo_configuracion

# Modificar el puerto
sed -i "s|Listen 80|Listen $nuevo_puerto|g" $archivo_configuracion

# Modificar el correo del administrador
sed -i "s|ServerAdmin you@example.com|ServerAdmin $nuevo_admin_email|g" $archivo_configuracion


while true; do
    # Mostrar lista de módulos desactivados con números de identificación
    echo "Lista de módulos desactivados en $archivo_configuracion:"
    grep -E '^#LoadModule' "$archivo_configuracion" | cut -d' ' -f2,3 | nl -s ') '

    # Pedir al usuario el número del módulo que desea comentar/descomentar
    read -p "Ingrese el número del módulo que desea comentar/descomentar (o 'salir' para salir): " numero_modulo

    # Salir del bucle si el usuario quiere salir
    if [ "$numero_modulo" == "salir" ]; then
        break
    fi

    # Obtener el nombre del módulo correspondiente al número proporcionado
    modulo=$(grep -E '^#LoadModule' "$archivo_configuracion" | sed -n "${numero_modulo}p" | awk '{print $1}')

    if [ -n "$modulo" ]; then
        # Comentar o descomentar el módulo
        if grep -q "^#$modulo" "$archivo_configuracion"; then
            sed -i "s/^#$modulo/$modulo/" "$archivo_configuracion"
            echo "El módulo '$modulo' ha sido descomentado."
        elif grep -q "^$modulo" "$archivo_configuracion"; then
            sed -i "s/^$modulo/#$modulo/" "$archivo_configuracion"
            echo "El módulo '$modulo' ha sido comentado."
        else
            echo "El módulo '$modulo' no se encuentra en el archivo de configuración."
        fi
    else
        echo "Número de módulo inválido. Por favor, seleccione un número válido."
    fi
done


    exit 0
fi

# Si Apache no está instalado, instalarlo
echo "Apache no está instalado en este sistema. Instalando Apache..."

# Instalar Apache en Arch Linux usando el administrador de paquetes pacman
sudo pacman -Syu --noconfirm apache
# Habilitar y arrancar el servicio Apache
sudo systemctl enable httpd
sudo systemctl start httpd

# Abrir el puerto 80 en el firewall (puedes ajustar esto según tus necesidades)
iptables -A INPUT -p tcp --dport  -j ACCEPT
ip6tables -A INPUT -p tcp --dport 80 -j ACCEPT



user_home_dir="/home/$USER/public_html"


sudo sed -i 's/#\s*Include conf\/extra\/httpd-userdir.conf/Include conf\/extra\/httpd-userdir.conf/' "archivo_configuracion"

# Ensure the user's home directory and public_html directory are executable and readable by others
chmod o+x "$user_home_dir"
chmod o+x "$public_html_dir"
chmod -R o+r "$public_html_dir"


# Reiniciar Apache
sudo systemctl restart httpd.service
# Verificar si la instalación fue exitosa
if [ $? -eq 0 ]; then
    echo "Apache ha sido instalado correctamente."

systemctl status httpd.service
# Mostrar información sobre el servidor web
httpd -v

echo "El servicio Apache se ha iniciado automáticamente y el puerto $nuevo_puerto ha sido abierto en el firewall."

else
    echo "No se pudo instalar Apache. Por favor, revisa los mensajes de error."
    exit 1
fi


