#!/bin/bash

echo "Configuración Interactiva de Apache"
echo "-----------------------------------"

# Verificar si el usuario tiene privilegios de superusuario
if [ "$(id -u)" != "0" ]; then
    echo "Este script debe ejecutarse con privilegios de superusuario (root)."
    exit 1
fi

# Instalar Apache si no está instalado
if ! command -v httpd > /dev/null; then
    echo "Apache no está instalado en este sistema. Instalando Apache..."
    sudo pacman -Syu --noconfirm apache
    sudo systemctl enable httpd
    sudo systemctl start httpd
    echo "Apache ha sido instalado y activado."
else
    apache_version=$(httpd -v | awk 'NR==1 {print $3}')
    echo "Apache $apache_version está instalado."
fi

sudo mkdir /srv/http

# Archivo de configuración de Apache
archivo_configuracion="/etc/httpd/conf/httpd.conf"

# Verificar si el archivo de configuración existe
if [ ! -f "$archivo_configuracion" ]; then
    echo "El archivo de configuración '$archivo_configuracion' no existe."
    exit 1
fi

# Configuraciones básicas
echo "Configurando Apache..."

# Configurar User y Group
sudo sed -i 's/^User .*/User http/' $archivo_configuracion
sudo sed -i 's/^Group .*/Group http/' $archivo_configuracion

# Configurar Listen
read -p "Nuevo Puerto (o dejar en blanco para mantener predeterminado '80'): " nuevo_puerto
nuevo_puerto=${nuevo_puerto:-"80"}
sudo sed -i "s/^Listen .*/Listen $nuevo_puerto/" $archivo_configuracion

# Configurar ServerAdmin
read -p "Nuevo correo del administrador (o dejar en blanco para mantener predeterminado 'you@example.com'): " nuevo_admin_email
nuevo_admin_email=${nuevo_admin_email:-"you@example.com"}
sudo sed -i "s/^ServerAdmin .*/ServerAdmin $nuevo_admin_email/" $archivo_configuracion

# Configurar DocumentRoot
read -p "Nuevo DocumentRoot (o dejar en blanco para mantener predeterminado '/srv/http'): " nuevo_document_root
nuevo_document_root=${nuevo_document_root:-"/srv/http"}
sudo sed -i "s|^DocumentRoot \".*\"|DocumentRoot \"$nuevo_document_root\"|" $archivo_configuracion
sudo sed -i "s|<Directory \"/srv/http\">|<Directory \"$nuevo_document_root\">|" $archivo_configuracion
sudo sed -i 's/Require all denied/Require all granted/' $archivo_configuracion

# Configurar AllowOverride
sudo sed -i 's/AllowOverride None/AllowOverride All/' $archivo_configuracion

# Configurar ServerSignature y ServerTokens
sudo sed -i 's/^ServerSignature .*/ServerSignature Off/' $archivo_configuracion
sudo sed -i 's/^ServerTokens .*/ServerTokens Prod/' $archivo_configuracion

# Incluir phpmyadmin.conf si existe
if [ -f /etc/httpd/conf/extra/phpmyadmin.conf ]; then
    if ! grep -q "Include conf/extra/phpmyadmin.conf" $archivo_configuracion; then
        echo "Include conf/extra/phpmyadmin.conf" | sudo tee -a $archivo_configuracion > /dev/null
    fi
fi

# Configurar directorios de usuario
if ! grep -q "Include conf/extra/httpd-userdir.conf" $archivo_configuracion; then
    echo "Include conf/extra/httpd-userdir.conf" | sudo tee -a $archivo_configuracion > /dev/null
fi

# Configurar TLS
if ! grep -q "LoadModule ssl_module modules/mod_ssl.so" $archivo_configuracion; then
    sudo sed -i 's/^#LoadModule ssl_module/LoadModule ssl_module/' $archivo_configuracion
    sudo sed -i 's/^#LoadModule socache_shmcb_module/LoadModule socache_shmcb_module/' $archivo_configuracion
    sudo sed -i 's/^#Include conf\/extra\/httpd-ssl.conf/Include conf\/extra\/httpd-ssl.conf/' $archivo_configuracion
fi

# Reiniciar Apache para aplicar cambios
sudo systemctl restart httpd
echo "Apache ha sido configurado correctamente. Puedes probarlo visitando http://localhost/ en tu navegador web."


