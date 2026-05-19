#!/bin/bash

# Actualizar el sistema
echo "Actualizando el sistema..."
sudo pacman -Syu --noconfirm

# Instalar Samba y gvfs-smb para soporte de gestores de archivos
echo "Instalando Samba y gvfs-smb..."
sudo pacman -S --noconfirm samba gvfs-smb

# Crear un directorio para compartir
# SHARE_DIR="/srv/samba/share"
SHARE_DIR="/home/$USER/samba"
echo "Creando el directorio compartido en $SHARE_DIR..."
sudo mkdir -p $SHARE_DIR
sudo chown -R nobody:nogroup $SHARE_DIR
sudo chmod -R 0775 $SHARE_DIR


# Usershares is a feature that gives non-root users the capability to add, modify, and delete their own share definitions. See smb.conf(5) § USERSHARES.

#Create a directory for usershares:
sudo mkdir /var/lib/samba/usershares
#Create a user group:
sudo groupadd -r sambashare
#Change the owner of the directory to root and the group to sambashare:
sudo chown root:sambashare /var/lib/samba/usershares
#Change the permissions of the usershares directory so that users in the group sambashare can create files. This command also sets sticky bit, which is important to prevent users from deleting usershares of other users:
sudo chmod 1770 /var/lib/samba/usershares
#Add the user to the sambashare group. Replace your_username with the name of your user:

sudo gpasswd sambashare -a $USER

# Configurar Samba
SMB_CONF="/etc/samba/smb.conf"
echo "Configurando Samba..."
sudo cp $SMB_CONF $SMB_CONF.bak  # Hacer una copia de seguridad del archivo de configuración original
sudo bash -c "cat > $SMB_CONF" <<EOL
[global]

    usershare path = /var/lib/samba/usershares
    usershare max shares = 100
    usershare allow guests = yes
    usershare owner only = yes


    workgroup = WORKGROUP
    server string = %h server (Samba, Manjaro)
    log file = /var/log/samba/%m.log
    max log size = 1000
    syslog only = no
    panic action = /usr/share/samba/panic-action %d

    # Compatibilidad con iOS/iPadOS 14.5+
    vfs object = fruit streams_xattr

[share]
    path = $SHARE_DIR
    browseable = yes
    read only = no
    guest ok = yes

# Eliminar o comentar esta sección si no se desea compartir el home de los usuarios
#[homes]
    comment = Home Directories
    browseable = no
    writable = yes
EOL

# Añadir un usuario de Samba
echo "Añadiendo un usuario de Samba..."
sudo smbpasswd -a nobody

# Configurar el firewall (puedes usar iptables o firewalld en lugar de ufw)
# echo "Configurando el firewall para permitir el tráfico de Samba..."
# sudo iptables -A INPUT -p udp --dport 137 -j ACCEPT
# sudo iptables -A INPUT -p udp --dport 138 -j ACCEPT
# sudo iptables -A INPUT -p tcp --dport 139 -j ACCEPT
# sudo iptables -A INPUT -p tcp --dport 445 -j ACCEPT
# sudo iptables-save > /etc/iptables/iptables.rules

# Iniciar y habilitar los servicios de Samba
echo "Iniciando y habilitando el servicio de Samba..."
sudo systemctl restart smb
sudo systemctl enable smb

# Habilitar y iniciar el servicio nmb para soporte de NetBIOS
echo "Iniciando y habilitando el servicio de NetBIOS..."
sudo systemctl restart nmb
sudo systemctl enable nmb

# Activar el servicio de descubrimiento de servicios web (WS-Discovery)
echo "Activando el servicio de descubrimiento de servicios web (WS-Discovery)..."
sudo pacman -S --noconfirm wsdd
sudo systemctl start wsdd
sudo systemctl enable wsdd

echo "Configuración de Samba completada con éxito."
