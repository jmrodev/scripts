#!/bin/bash

echo "Mini guide to build an ISO for Manjaro"
echo "--------------------------------------"
echo "https://forum.manjaro.org/t/root-tip-how-to-mini-guide-to-build-manjaro-iso/121791"
# Obtener el nombre de usuario actual
current_user=$(whoami)

# Preguntar al usuario si el nombre de usuario actual es correcto
read  -r -p "El nombre de usuario actual es '$current_user'. ¿Es correcto? (Sí/No): " confirm
case $confirm in
    [Ss]|[Ss][Íí]|[Ss][Ii]|[Ss][Yy]) # Si el usuario confirma con Sí, sÍ, sí, si, etc.
        user="$current_user"
        ;;
    *) # Si el usuario responde No o cualquier otra cosa
        # Preguntar al usuario por su nombre de usuario
        read  -r -p "Por favor, ingresa tu nombre de usuario: " user
        ;;
esac

echo "Continuando con el nombre de usuario '$user'."


# Paso 1: Verificar espacio en disco
echo "Verifying disk space..."

# Asegúrate de que haya suficiente espacio disponible en el disco

required_space=20 # Adjust this value to your requirement
available_space=$(df -BG . | awk 'NR==2 {print $4}' | tr -d 'G')

if [ "$available_space" -ge "$required_space" ]; then
    echo "You have enough disk space ($available_space GB) to build ISO images."
else
    echo "You do not have enough disk space ($available_space GB) to build ISO images. At least $required_space GB is required."
    exit 1

fi

# Paso 2: Instalar herramientas necesarias
echo "Installing required tools..."

sudo pacman-Syu --noconfirm --needed sudo pacmangit base-devel manjaro-chrootbuild manjaro-tools-iso-git manjaro-tools-yaml-git manjaro-tools-base-git

# Paso 3: Configurar herramientas
echo "Configurando herramientas..."

if [ -d ~/.config/manjaro-tools ]; then
    echo "El directorio de configuración ya existe."
    echo "¿Desea sobrescribirlo? (Sí/No)"
    read -r response

    case $response in
        [Ss]|[Ss][Íí]|[Ss][Ii]|[Ss][Yy]) # Si el usuario responde Sí, sí, Si, sÍ, etc.
            echo "Sobrescribiendo el directorio de configuración..."
            rm -rf ~/.config/manjaro-tools
            cp -R /etc/manjaro-tools ~/.config
            echo "El directorio de configuración ha sido sobrescrito."
            ;;
        [Nn]|[Nn][Oo]) # Si el usuario responde No, no, No, nO, etc.
            echo "Saliendo sin sobrescribir el directorio de configuración."
            ;;
        *) # Si la respuesta no coincide con ninguna de las opciones
            echo "Respuesta no válida. Por favor, responda 'Sí' o 'No'."
            ;;
    esac
else
    cp -R /etc/manjaro-tools ~/.config
fi



#editar con nano?

# Preguntar al usuario si desea editar el archivo de configuración
echo "¿Quiere editar el archivo de configuración?"

while true; do
    read  -r -p "Por favor, responda 'sí' o 'no': " response

    case $response in
        [Ss]|[Ss][Íí]|[Ss][Ii]|[Ss][Yy]) # Si el usuario responde Sí, sí, Si, sÍ, etc.
            nano ~/.config/manjaro-tools/manjaro-tools.conf
            break;;
        [Nn]|[Nn][Oo]) # Si el usuario responde No, no, No, nO, etc.
            echo "Saliendo sin editar el archivo de configuración."
            break;;
        *) # Si la respuesta no coincide con ninguna de las opciones
            echo "Respuesta inválida. Por favor, responda 'sí' o 'no'."
            ;;
    esac
done


echo "Clonando repositorio..."
# Verificar si el directorio ~/iso-profiles existe
if [ -d "$HOME/iso-profiles" ]; then
    echo "El directorio ~/iso-profiles ya existe. Eliminándolo..."
    rm -rf ~/iso-profiles
fi

# Clonar el repositorio
git clone https://gitlab.manjaro.org/profiles-and-settings/iso-profiles ~/iso-profiles

echo "Configurando directorio de ejecución..."

echo "run_dir=/home/$user/iso-profiles" >~/.config/manjaro-tools/iso-profiles.conf

# Paso 4: Construir ISO
echo "Building ISO..."

# Verificar si el directorio /mybuild existe
if [ -d "/mybuild" ]; then
    echo "El directorio /mybuild ya existe."
    echo "¿Desea eliminarlo y crearlo de nuevo? (Sí/No)"
    read -r response

    case $response in
        [Ss]|[Ss][Íí]|[Ss][Ii]|[Ss][Yy]) # Si el usuario responde Sí, sí, Si, sÍ, etc.
            sudo rm -rf /mybuild
            echo "El directorio /mybuild ha sido eliminado."
            sudo mkdir /mybuild
            echo "Directorio /mybuild creado nuevamente."
            ;;
        [Nn]|[Nn][Oo]) # Si el usuario responde No, no, No, nO, etc.
            echo "Saliendo sin eliminar el directorio /mybuild."
            ;;
        *) # Si la respuesta no coincide con ninguna de las opciones
            echo "Respuesta no válida. Por favor, responda 'Sí' o 'No'."
            ;;
    esac
else
    # Si el directorio no existe, crearlo
    echo "El directorio /mybuild no existe. Creando..."
    sudo mkdir /mybuild
    echo "Directorio /mybuild creado exitosamente."
fi


echo "Ajustando permisos..."
sudo chown "$user":"$user" /mybuild

echo "Clonando repositorio..."
git clone https://gitlab.manjaro.org/profiles-and-settings/iso-profiles /mybuild/iso-profiles

echo "Creacion de directorio de usuario..."
mkdir /mybuild/iso-profiles/"$user"

# Detectar el entorno de escritorio actual
current_desktop=$(echo "$XDG_CURRENT_DESKTOP" | tr '[:upper:]' '[:lower:]')

echo "Building ISO for $current_desktop..."


cp -R /mybuild/iso-profiles/manjaro/"$current_desktop" /mybuild/iso-profiles/"$user"/"$current_desktop"

echo "Limpiando paquetes huérfanos..."
sudo pacman-Rns "$(sudo pacman-Qtdq)"

echo "Creando lista de paquetes instalados..."

sudo pacman-Qqen >~/my-packages.txt

echo "Creando lista de paquetes del sistema..."

comm -23 <(sort ~/my-packages.txt) <(sort /rootfs-pkgs.txt) >/mybuild/iso-profiles/"$user"/"$current_desktop"/Packages-Desktop

mkdir -p /mybuild/iso-profiles/"$user"/"$current_desktop"/desktop-overlay/etc/skel
#cp -R "$HOME"/. /mybuild/iso-profiles/"$user"/"$current_desktop"/desktop-overlay/etc/skel
# Listar las carpetas existentes en el directorio
echo "Carpetas existentes en $HOME:"
folders=("$HOME"/*/)
for ((i = 0; i < ${#folders[@]}; i++)); do
    echo "$((i + 1)) ${folders[$i]}"
done

selected_folders=()  # Inicializar una lista vacía para almacenar las carpetas seleccionadas

# Bucle para seleccionar carpetas
while true; do
    read -r -p "Ingrese el número de la carpeta que desea incluir en la copia (o presione Enter para terminar): " selection

    # Verificar si el usuario presionó Enter para terminar la selección
    if [[ -z $selection ]]; then
        break
    fi

    index=$((selection - 1))

    # Verificar si el número de carpeta seleccionado es válido
    if [[ $index -ge 0 && $index -lt ${#folders[@]} ]]; then
        selected_folder=${folders[$index]%/}  # Eliminar la barra diagonal al final de la ruta
        selected_folders+=("$selected_folder")  # Agregar la carpeta seleccionada a la lista
        echo "La carpeta '$selected_folder' ha sido incluida en la copia."
    else
        echo "El número de carpeta '$selection' no es válido."
    fi
done

# Copiar las carpetas seleccionadas
for folder in "${selected_folders[@]}"; do
    rsync -av "$folder" /mybuild/iso-profiles/"$user"/"$current_desktop"/desktop-overlay/etc/skel
done

#preguntar si desea crear el iso

echo "Desea crear el ISO?"

while true; do
    read  -r -p "Por favor, responda 'Sí' o 'No': " response

    case $response in
        [Ss]|[Ss][Íí]|[Ss][Ii]|[Ss][Yy]) # Si el usuario responde Sí, sí, Si, sÍ, etc.
            buildiso -p "$current_desktop" -t /mybuild
            echo "ISO ha sido creado exitosamente!"
            break;;
        [Nn]|[Nn][Oo]) # Si el usuario responde No, no, No, nO, etc.
            echo "Saliendo sin crear el ISO."
            exit;;
        *) # Si la respuesta no coincide con ninguna de las opciones
            echo "Respuesta inválida. Por favor, responda 'Sí' o 'No'."
            ;;
    esac
done
