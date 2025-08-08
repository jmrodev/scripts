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
        log "INFO" "$package_name is already installed."
    else
        if ! pacman -S --noconfirm "$package_name"; then
            log "ERROR" "Failed to install $package_name."
            return 1
        fi
    fi
    log "SUCCESS" "$package_name installed successfully."
    return 0
}

# Enable and start a systemd service
enable_service() {
    local service_name="$1"
    log "INFO" "Habilitando y arrancando $service_name..."
    if systemctl is-active --quiet "$service_name"; then
        log "INFO" "$service_name is already active."
    else
        if ! systemctl enable --now "$service_name"; then
            log "ERROR" "Failed to enable and start $service_name."
            return 1
        fi
    fi
    log "SUCCESS" "$service_name enabled and started."
    return 0
}

# --- MariaDB Configuration Functions ---

configure_mariadb_security() {
    log "INFO" "Configurando la seguridad de MariaDB..."
    local security_conf="/etc/my.cnf.d/security.cnf"

    read -p "¿Deseas que MariaDB solo escuche en la dirección de loopback (localhost)? (y/n): " BIND_LOCALHOST
    if [[ "$BIND_LOCALHOST" =~ ^[Yy]$ ]]; then
        echo "[mariadb]" > "$security_conf"
        echo "bind-address = localhost" >> "$security_conf"
        log "SUCCESS" "MariaDB configurado para escuchar solo en localhost."
    fi
}

configure_mariadb_charset() {
    log "INFO" "Configurando el juego de caracteres de MariaDB..."
    local charset_conf="/etc/my.cnf.d/charset.cnf"

    read -p "¿Deseas configurar UTF8MB4 como el juego de caracteres por defecto? (y/n): " SET_UTF8MB4
    if [[ "$SET_UTF8MB4" =~ ^[Yy]$ ]]; then
        echo "[client]" > "$charset_conf"
        echo "default-character-set = utf8mb4" >> "$charset_conf"
        echo "" >> "$charset_conf"
        echo "[mariadb]" >> "$charset_conf"
        echo "collation_server = utf8mb4_unicode_ci" >> "$charset_conf"
        echo "character_set_server = utf8mb4" >> "$charset_conf"
        echo "" >> "$charset_conf"
        echo "[mariadb-client]" >> "$charset_conf"
        echo "default-character-set = utf8mb4" >> "$charset_conf"
        log "SUCCESS" "MariaDB configurado para usar UTF8MB4."
    fi
}

# --- Installation Function ---

install_mariadb() {
    log "INFO" "--- Installing MariaDB ---"
    install_package "mariadb" || return 1
    install_package "expect" || return 1

    log "INFO" "Initializing MariaDB data directory with mariadb-install-db..."
    if [[ ! -d "/var/lib/mysql/mysql" ]]; then
        # This script, part of the mariadb package, initializes the MariaDB data directory.
        mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql || { log "ERROR" "Failed to initialize MariaDB data directory."; return 1; }
        log "SUCCESS" "MariaDB data directory initialized."
    else
        log "INFO" "MariaDB data directory already initialized."
    fi

    enable_service "mariadb" || return 1

    log "INFO" "Running mysql_secure_installation to secure MariaDB."
    
    read -s -p "Enter new MariaDB root password: " MARIADB_ROOT_PASSWORD
    echo
    read -s -p "Confirm new MariaDB root password: " MARIADB_ROOT_PASSWORD_CONFIRM
    echo

    if [[ "$MARIADB_ROOT_PASSWORD" != "$MARIADB_ROOT_PASSWORD_CONFIRM" ]]; then
        log "ERROR" "Passwords do not match. Aborting secure installation."
        return 1
    fi

    chmod +x "$BASE_DIR/secure_mariadb.exp"
    if ! "$BASE_DIR/secure_mariadb.exp" "$MARIADB_ROOT_PASSWORD"; then
        log "ERROR" "Failed to run mysql_secure_installation."
        return 1
    fi

    log "SUCCESS" "MariaDB secure installation complete."

    # Post-installation configurations
    configure_mariadb_security
    configure_mariadb_charset

    log "INFO" "Reiniciando MariaDB para aplicar la nueva configuración..."
    systemctl restart mariadb || { log "ERROR" "Fallo al reiniciar MariaDB."; return 1; }
    log "SUCCESS" "MariaDB reiniciado."

    log "INFO" "Verificando la base de datos de MariaDB..."
    mariadb-check --all-databases -u root -p"$MARIADB_ROOT_PASSWORD" -c || log "WARN" "Fallo al verificar la base de datos."

    log "SUCCESS" "MariaDB installation complete."
    return 0
}

# --- AUR Helper Function ---

install_aur_package() {
    local package_name="$1"
    local aur_helper
    local sudo_user="$SUDO_USER"

    if [[ -z "$sudo_user" ]]; then
        log "ERROR" "Cannot determine the user who invoked sudo. Please run this script with sudo."
        return 1
    fi

    if command -v yay &>/dev/null; then
        aur_helper="yay"
    elif command -v paru &>/dev/null; then
        aur_helper="paru"
    else
        log "WARN" "No AUR helper (yay/paru) found. Cannot install $package_name."
        return 1
    fi

    log "INFO" "Installing $package_name from AUR using $aur_helper..."
    if ! sudo -u "$sudo_user" $aur_helper -S --noconfirm "$package_name"; then
        log "ERROR" "Failed to install $package_name from AUR."
        return 1
    fi
    log "SUCCESS" "$package_name installed successfully from AUR."
    return 0
}

# --- phpMyAdmin Setup ---

setup_phpmyadmin() {
    log "INFO" "Configurando phpMyAdmin para Apache..."
    local pma_conf="/etc/httpd/conf/extra/httpd-phpmyadmin.conf"
    local pma_dir="/usr/share/webapps/phpMyAdmin"

    echo "Alias /phpmyadmin \"$pma_dir\"" > "$pma_conf"
    echo "<Directory \"$pma_dir\">" >> "$pma_conf"
    echo "    DirectoryIndex index.php" >> "$pma_conf"
    echo "    AllowOverride All" >> "$pma_conf"
    echo "    Options FollowSymLinks" >> "$pma_conf"
    echo "    Require all granted" >> "$pma_conf"
    echo "</Directory>" >> "$pma_conf"

    log "SUCCESS" "$pma_conf creado."

    if ! grep -q "Include conf/extra/httpd-phpmyadmin.conf" "/etc/httpd/conf/httpd.conf"; then
        echo "Include conf/extra/httpd-phpmyadmin.conf" >> "/etc/httpd/conf/httpd.conf"
        log "SUCCESS" "Inclusión de httpd-phpmyadmin.conf añadida a httpd.conf."
    fi

    # Set permissions for phpMyAdmin directory
    chown -R http:http "$pma_dir"
    find "$pma_dir" -type d -exec chmod 755 {} +
    find "$pma_dir" -type f -exec chmod 644 {} +

    systemctl restart httpd || { log "ERROR" "Fallo al reiniciar Apache."; return 1; }
    log "SUCCESS" "Apache reiniciado."
}


# --- Main Script Logic ---

check_root

echo "=== MariaDB Installer for Arch Linux ==="
echo "This script will install and configure MariaDB."
echo ""

install_mariadb

read -p "¿Deseas instalar phpMyAdmin (interfaz web para MariaDB)? (y/n): " INSTALL_PHPMYADMIN
if [[ "$INSTALL_PHPMYADMIN" =~ ^[Yy]$ ]]; then
    install_package "phpmyadmin" || log "WARN" "Fallo al instalar phpMyAdmin. Por favor, revisa los errores."
    setup_phpmyadmin
fi

read -p "¿Deseas instalar MyCLI (cliente de consola avanzado para MySQL/MariaDB)? (y/n): " INSTALL_MYCLI
if [[ "$INSTALL_MYCLI" =~ ^[Yy]$ ]]; then
    install_aur_package "mycli" || log "WARN" "Could not install MyCLI. It is available in the AUR as mycli."
fi

log "INFO" "Script finished."