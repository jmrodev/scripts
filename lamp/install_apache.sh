#!/bin/bash

# ==============================================================================
# Script de Instalación y Configuración Básica de Apache en Arch Linux
#
# Este script realiza la instalación interactiva de Apache. Permite al usuario
# definir el puerto de escucha y el directorio raíz de los documentos.
# ==============================================================================

# --- Funciones Comunes ---

# Directorio base del script
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# Función para registrar mensajes con colores
log() {
    local type="$1"
    local message="$2"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    case "$type" in
        "INFO")    echo -e "[\e[34mINFO\e[0m] $timestamp $message" ;; 
        "SUCCESS") echo -e "[\e[32mSUCCESS\e[0m] $timestamp $message" ;; 
        "ERROR")   echo -e "[\e[31mERROR\e[0m] $timestamp $message" ;; 
        "WARN")    echo -e "[\e[33mWARN\e[0m] $timestamp $message" ;; 
        *)
            echo -e "[\e[37mDEBUG\e[0m] $timestamp $message" ;; 
    esac
}

# Verificar privilegios de root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log "ERROR" "Este script debe ser ejecutado como root."
        exit 1
    fi
}

# Instalar un paquete usando pacman
install_package() {
    local package_name="$1"
    log "INFO" "Instalando $package_name..."
    if pacman -Q "$package_name" &>/dev/null;
    then
        log "INFO" "$package_name ya está instalado."
    else
        if ! pacman -S --noconfirm "$package_name"; then
            log "ERROR" "Fallo al instalar $package_name."
            return 1
        fi
    fi
    log "SUCCESS" "$package_name instalado exitosamente."
    return 0
}

# Habilitar y arrancar un servicio systemd
enable_service() {
    local service_name="$1"
    log "INFO" "Habilitando y arrancando $service_name..."
    if systemctl is-active --quiet "$service_name"; then
        log "INFO" "$service_name ya está activo."
    else
        if ! systemctl enable --now "$service_name"; then
            log "ERROR" "Fallo al habilitar y arrancar $service_name."
            return 1
        fi
    fi
    log "SUCCESS" "$service_name habilitado y arrancado."
    return 0
}

# Configurar firewall (ufw o iptables)
configure_firewall() {
    local port="$1"
    log "INFO" "Configurando firewall para el puerto $port..."
    if command -v ufw &>/dev/null;
    then
        if ufw status | grep -q "Status: active"; then
            if ! ufw allow "$port"/tcp;
            then
                log "WARN" "Fallo al añadir regla de ufw para el puerto $port. Podría requerir intervención manual."
            else
                log "SUCCESS" "Regla de UFW añadida para el puerto $port."
            fi
        else
            log "WARN" "UFW no está activo. Por favor, habilítalo o configura tu firewall manualmente."
        fi
    elif command -v iptables &>/dev/null;
    then
        log "INFO" "Usando iptables para la configuración del firewall. Esta es una regla básica."
        if ! iptables -C INPUT -p tcp --dport "$port" -j ACCEPT &>/dev/null;
        then
            if ! iptables -A INPUT -p tcp --dport "$port" -j ACCEPT;
            then
                log "WARN" "Fallo al añadir regla de iptables para el puerto $port. Podría requerir intervención manual."
            else
                log "SUCCESS" "Regla de iptables añadida para el puerto $port. Recuerda guardar las reglas para que persistan."
            fi
        else
            log "INFO" "La regla de iptables para el puerto $port ya existe."
        fi
    else
        log "WARN" "No se encontró un firewall común (ufw/iptables). Por favor, configura tu firewall manualmente para el puerto $port."
    fi
}

# Crear una página de prueba HTML
create_test_page() {
    local docroot="$1"
    log "INFO" "Creando página de prueba HTML en $docroot..."
    mkdir -p "$docroot"
    chown http:http "$docroot"
    chmod 755 "$docroot"

    echo "<html><body><h1>Apache is working!</h1></body></html>" > "$docroot/index.html"
    chown http:http "$docroot/index.html"
    log "SUCCESS" "Página de prueba HTML creada en $docroot/index.html"
    return 0
}

# --- Lógica de public_html ---

setup_user_public_html() {
    read -p "¿Deseas configurar un directorio public_html para un usuario? (y/n): " SETUP_PUBLIC_HTML
    if [[ "$SETUP_PUBLIC_HTML" =~ ^[Yy]$ ]]; then
        local sudo_user=${SUDO_USER:-$(whoami)}
        read -p "Introduce el nombre de usuario [default: $sudo_user]: " username
        username=${username:-$sudo_user}

        local user_home
        user_home=$(eval echo ~$username)

        if [[ ! -d "$user_home" ]]; then
            log "ERROR" "El directorio home del usuario '$username' no existe."
            return 1
        fi

        log "INFO" "Configurando public_html para el usuario '$username'..."

        # Habilitar mod_userdir
        sed -i 's|^#LoadModule userdir_module modules/mod_userdir.so|LoadModule userdir_module modules/mod_userdir.so|' "/etc/httpd/conf/httpd.conf"
        
        # Crear httpd-userdir.conf
        local userdir_conf="/etc/httpd/conf/extra/httpd-userdir.conf"
        if [[ ! -f "$userdir_conf" ]]; then
            echo "<IfModule userdir_module>" > "$userdir_conf"
            echo "    UserDir public_html" >> "$userdir_conf"
            echo "</IfModule>" >> "$userdir_conf"
            echo "<Directory \"/home/*/public_html\">" >> "$userdir_conf"
            echo "    AllowOverride All" >> "$userdir_conf"
            echo "    Options MultiViews Indexes SymLinksIfOwnerMatch" >> "$userdir_conf"
            echo "    Require all granted" >> "$userdir_conf"
            echo "</Directory>" >> "$userdir_conf"
            log "SUCCESS" "$userdir_conf creado."
        fi

        # Incluir httpd-userdir.conf en httpd.conf
        if ! grep -q "Include conf/extra/httpd-userdir.conf" "/etc/httpd/conf/httpd.conf"; then
            echo "Include conf/extra/httpd-userdir.conf" >> "/etc/httpd/conf/httpd.conf"
            log "SUCCESS" "Inclusión de httpd-userdir.conf añadida a httpd.conf."
        fi

        # Crear directorio public_html y establecer permisos
        sudo -u "$username" mkdir -p "$user_home/public_html"
        chmod o+x "$user_home"
        chmod o+x "$user_home/public_html"
        chmod -R o+r "$user_home/public_html"

        # Crear página de prueba
        sudo -u "$username" echo "<html><body><h1>Página de usuario de $username</h1></body></html>" > "$user_home/public_html/index.html"

        log "SUCCESS" "Directorio public_html configurado para $username. Accede a http://localhost/~$username/"
    fi
}


# --- Lógica de Instalación Principal ---

main_installation() {
    log "INFO" "--- Iniciando instalación de Apache HTTP Server ---"
    
    # 1. Verificación de privilegios
    check_root

    # 2. Instalación de Apache
    install_package "apache" || return 1

    # 3. Solicitud de configuración al usuario
    local DEFAULT_PORT=80
    read -p "¿En qué puerto quieres que Apache escuche? [default: $DEFAULT_PORT]: " PORT
    PORT=${PORT:-$DEFAULT_PORT}
    log "INFO" "Usando puerto de escucha: $PORT"

    local DEFAULT_DOCROOT="/srv/http"
    read -p "¿Cuál quieres que sea el DocumentRoot? [default: $DEFAULT_DOCROOT]: " DOCROOT
    DOCROOT=${DOCROOT:-$DEFAULT_DOCROOT}
    log "INFO" "Usando DocumentRoot: $DOCROOT"

    # 4. Configuración del archivo httpd.conf
    local HTTPD_CONF="/etc/httpd/conf/httpd.conf"
    if [[ ! -f "$HTTPD_CONF" ]]; then
        log "ERROR" "$HTTPD_CONF no encontrado. La instalación de Apache podría estar incompleta."
        return 1
    fi

    # Copia de seguridad del archivo de configuración original
    cp "$HTTPD_CONF" "${HTTPD_CONF}.bak.$(date +%Y%m%d%H%M%S)"
    log "INFO" "Copia de seguridad de $HTTPD_CONF creada."

    # Modificar Listen Port, ServerName, DocumentRoot y Directorio
    sed -i "s|^Listen.*|Listen $PORT|" "$HTTPD_CONF"
    sed -i "s|#ServerName www.example.com:80|ServerName localhost:$PORT|" "$HTTPD_CONF"
    sed -i "s|^DocumentRoot ".*"|DocumentRoot \"$DOCROOT\"|" "$HTTPD_CONF"
    sed -i "s|<Directory \"/srv/http\">|<Directory \"$DOCROOT\">|" "$HTTPD_CONF"

    # Habilitar el módulo de reescritura de URL (mod_rewrite)
    sed -i 's|^#LoadModule rewrite_module modules/mod_rewrite.so|LoadModule rewrite_module modules/mod_rewrite.so|' "$HTTPD_CONF"

    # 5. Crear DocumentRoot y página de prueba
    create_test_page "$DOCROOT" || return 1

    # 6. Configurar public_html para el usuario
    setup_user_public_html

    # 7. Habilitar y arrancar el servicio de Apache
    enable_service "httpd" || return 1

    # 8. Configuración opcional del firewall
    read -p "¿Deseas configurar el firewall para abrir el puerto $PORT? (y/n): " CONFIGURE_FIREWALL
    if [[ "$CONFIGURE_FIREWALL" =~ ^[Yy]$ ]]; then
        configure_firewall "$PORT"
    fi

    log "SUCCESS" "Instalación de Apache completada. Accede a tu sitio en http://localhost:$PORT/"
    log "INFO" "Script finalizado."
}

# --- Ejecución del script ---
main_installation
