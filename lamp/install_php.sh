#!/bin/bash

# --- Common Functions ---

# Base directory of the script
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# Function for logging messages
log() {
    local type="$1"
    local message="$2"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    case "$type" in
        "INFO")    echo -e "[\e[34mINFO\e[0m] $timestamp $message" ;;
        "SUCCESS") echo -e "[\e[32mSUCCESS\e[0m] $timestamp $message" ;;
        "ERROR")   echo -e "[\e[31mERROR\e[0m] $timestamp $message" ;;
        "WARN")    echo -e "[\e[33mWARN\e[0m] $timestamp $message" ;;
        *)         echo -e "[\e[37mDEBUG\e[0m] $timestamp $message" ;;
    esac
}

# Check for root privileges
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log "ERROR" "This script must be run as root."
        exit 1
    fi
}

# Install a package using pacman
install_package() {
    local package_name="$1"
    log "INFO" "Instalando $package_name..."
    if pacman -Q "$package_name" &>/dev/null; then
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

# Enable and start a systemd service
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

# Create a test page
create_test_page() {
    local docroot="$1"
    log "INFO" "Creando página de prueba PHP en $docroot..."
    mkdir -p "$docroot"
    chown http:http "$docroot"
    chmod 755 "$docroot"

    echo "<?php phpinfo(); ?>" > "$docroot/info.php"
    chown http:http "$docroot/info.php"
    log "SUCCESS" "Página de prueba PHP creada en $docroot/info.php"
    return 0
}

# --- Función de Instalación Principal ---

install_php_fpm() {
    log "INFO" "--- Iniciando instalación de PHP con PHP-FPM ---"
    check_root

    # 1. Instalar paquetes necesarios
    install_package "php" || return 1
    install_package "php-fpm" || return 1
    
    local HTTPD_CONF="/etc/httpd/conf/httpd.conf"
    local PHP_FPM_CONF="/etc/httpd/conf/extra/php-fpm.conf"
    local PHP_INI="/etc/php/php.ini"

    # Ensure php.ini exists and is not empty
    if [[ ! -s "$PHP_INI" ]]; then
        log "INFO" "php.ini no encontrado o vacío. Intentando copiar desde plantillas..."
        if [[ -f "/etc/php/php.ini-production" ]]; then
            cp "/etc/php/php.ini-production" "$PHP_INI"
            log "SUCCESS" "php.ini-production copiado a $PHP_INI."
        elif [[ -f "/etc/php/php.ini-development" ]]; then
            cp "/etc/php/php.ini-development" "$PHP_INI"
            log "SUCCESS" "php.ini-development copiado a $PHP_INI."
        else
            log "ERROR" "No se encontró php.ini ni plantillas (php.ini-production/development). La instalación de PHP podría estar incompleta."
            return 1
        fi
    fi

    # 2. Configurar Apache para PHP-FPM
    log "INFO" "Habilitando módulos de Apache necesarios..."
    sed -i 's/^#LoadModule proxy_module/LoadModule proxy_module/' "$HTTPD_CONF"
    sed -i 's/^#LoadModule proxy_fcgi_module/LoadModule proxy_fcgi_module/' "$HTTPD_CONF"
    log "SUCCESS" "Módulos de proxy habilitados."

    if [[ ! -f "$PHP_FPM_CONF" ]]; then
        log "INFO" "Creando fichero de configuración de PHP-FPM..."
        echo 'DirectoryIndex index.php index.html' > "$PHP_FPM_CONF"
        echo '<FilesMatch \.php$>' >> "$PHP_FPM_CONF"
        echo '    SetHandler "proxy:unix:/run/php-fpm/php-fpm.sock|fcgi://localhost/"' >> "$PHP_FPM_CONF"
        echo '</FilesMatch>' >> "$PHP_FPM_CONF"
        log "SUCCESS" "Fichero de configuración de PHP-FPM creado en $PHP_FPM_CONF."
    else
        log "INFO" "El fichero de configuración de PHP-FPM ya existe."
    fi

    if ! grep -q "Include conf/extra/php-fpm.conf" "$HTTPD_CONF"; then
        echo "Include conf/extra/php-fpm.conf" >> "$HTTPD_CONF"
        log "SUCCESS" "Inclusión de php-fpm.conf añadida a httpd.conf."
    else
        log "INFO" "La inclusión de php-fpm.conf ya existe en httpd.conf."
    fi

    sed -i 's|DirectoryIndex index.html|DirectoryIndex index.php index.html|' "$HTTPD_CONF"
    log "SUCCESS" "DirectoryIndex ajustado para incluir index.php."

    # 3. Configurar php.ini (opcional pero recomendado)
    if [[ -f "$PHP_INI" ]]; then
        local DEFAULT_TIMEZONE="America/Argentina/Buenos_Aires"
        read -p "¿Qué zona horaria quieres usar en PHP? (e.g., Europe/Madrid, default: $DEFAULT_TIMEZONE): " TIMEZONE
        TIMEZONE=${TIMEZONE:-$DEFAULT_TIMEZONE}
        sed -i "s|^;date.timezone =.*|date.timezone = $TIMEZONE|" "$PHP_INI"
        log "SUCCESS" "Zona horaria de PHP establecida a $TIMEZONE."

        # Preguntar si desea habilitar display_errors
        read -p "¿Deseas habilitar 'display_errors' para depuración? (y/n): " ENABLE_DISPLAY_ERRORS
        if [[ "$ENABLE_DISPLAY_ERRORS" =~ ^[Yy]$ ]]; then
            sed -i "s|^display_errors = Off|display_errors = On|" "$PHP_INI"
            log "SUCCESS" "'display_errors' habilitado en php.ini."
        else
            log "INFO" "'display_errors' se mantendrá deshabilitado."
        fi

        # Preguntar si desea habilitar OPCache
        read -p "¿Deseas habilitar OPCache para mejorar el rendimiento? (y/n): " ENABLE_OPCACHE
        if [[ "$ENABLE_OPCACHE" =~ ^[Yy]$ ]]; then
            if ! grep -q "zend_extension=opcache" "$PHP_INI"; then
                echo "zend_extension=opcache" >> "$PHP_INI"
                log "SUCCESS" "OPCache habilitado en php.ini."
            else
                log "INFO" "OPCache ya está habilitado en php.ini."
            fi
        else
            log "INFO" "OPCache se mantendrá deshabilitado."
        fi

        # Preguntar si desea instalar y habilitar APCu
        read -p "¿Deseas instalar y habilitar APCu para caché de usuario? (y/n): " INSTALL_APCU
        if [[ "$INSTALL_APCU" =~ ^[Yy]$ ]]; then
            install_package "php-apcu" || return 1
            if ! grep -q "extension=apcu" "/etc/php/conf.d/apcu.ini" &>/dev/null; then
                echo "extension=apcu" > "/etc/php/conf.d/apcu.ini"
                log "SUCCESS" "APCu habilitado en /etc/php/conf.d/apcu.ini."
            else
                log "INFO" "APCu ya está habilitado."
            fi
        else
            log "INFO" "APCu no será instalado ni habilitado."
        fi

        # Habilitar extensiones de MySQL/MariaDB
        log "INFO" "Habilitando extensiones de PHP para MariaDB..."
        echo "extension=mysqli" > /etc/php/conf.d/mysqli.ini
        echo "extension=pdo_mysql" > /etc/php/conf.d/pdo_mysql.ini
        log "SUCCESS" "Extensiones mysqli y pdo_mysql habilitadas."

        # Enable other common extensions
        log "INFO" "Habilitando otras extensiones comunes de PHP..."
        local extensions_to_enable=(
            "bz2"
            "curl"
            "gd"
            "intl"
            "openssl"
            "zip"
        )
        for ext in "${extensions_to_enable[@]}"; do
            sed -i "s/^;extension=$ext/extension=$ext/" "$PHP_INI"
            log "INFO" "Extensión $ext habilitada."
        done
        log "SUCCESS" "Extensiones comunes habilitadas."

    else
        log "ERROR" "$PHP_INI no encontrado. La instalación de PHP podría estar incompleta."
        return 1
    fi
    
    # 4. Habilitar y arrancar servicios
    enable_service "php-fpm" || return 1

    log "INFO" "Reiniciando Apache para aplicar la nueva configuración..."
    systemctl restart httpd || { log "ERROR" "Fallo al reiniciar Apache. Por favor, revisa el log de errores de Apache."; return 1; }
    log "SUCCESS" "Apache reiniciado."

    # 5. Crear página de prueba
    local DOCROOT=$(grep "^DocumentRoot" "$HTTPD_CONF" | awk -F'"' '{print $2}')
    create_test_page "$DOCROOT" || return 1

    log "SUCCESS" "Instalación de PHP completada. Accede a PHP Info en http://localhost/info.php"
    log "INFO" "Script finalizado."
}

# --- Ejecución del script ---
install_php_fpm