# 1. Preparar la Estructura del Directorio:
sudo mkdir /mybuild
sudo chown $USER:$USER /mybuild

# 2. Clonar los Perfiles de ISO de Manjaro:
git clone https://gitlab.manjaro.org/profiles-and-settings/iso-profiles /mybuild/iso-profiles

# 3. Crear un Perfil Personalizado (en este caso KDE):
mkdir /mybuild/iso-profiles/$USER/my-kde
cp -R /mybuild/iso-profiles/manjaro/kde /mybuild/iso-profiles/$USER/my-kde

# 4. Limpiar Paquetes Huérfanos:
pamac remove --orphans

# 5. Crear una Lista de Paquetes de tu Sistema Actual:
pacman -Qqen > ~/my-packages.txt

# 6. Crear una Lista Filtrada:
comm -23 <(sort ~/my-packages.txt) <(sort /rootfs-pkgs.txt) > /mybuild/iso-profiles/$USER/my-kde/Packages-Desktop

# 7. Preparar la Configuración Personalizada:
mkdir -p /mybuild/iso-profiles/$USER/my-kde/desktop-overlay/etc/skel
cp -R $HOME/. /mybuild/iso-profiles/$USER/my-kde/desktop-overlay/etc/skel

# 8. Construir la ISO Personalizada:
buildiso -p my-kde -t /mybuild
