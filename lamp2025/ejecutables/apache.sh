#!/bin/bash

# Importar funciones comunes
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
echo "Script directory apache: $SCRIPT_DIR"
source "${SCRIPT_DIR}/../utils/common.sh"
source "${SCRIPT_DIR}/../utils/arch_helpers.sh"

# Verificar permisos de root
check_root

log "INFO" "Iniciando instalación de Apache..."

# Instalar Apache
install_package "apache" || exit 1

# Backup de configuración original
create_backup "/etc/httpd/conf/httpd.conf"

# Configurar Apache
log "INFO" "Configurando Apache..."

# Verificar puerto
DEFAULT_PORT=80
read -p "Puerto para Apache (default: 80): " PORT
PORT=${PORT:-$DEFAULT_PORT}

if ! check_port "$PORT"; then
    log "ERROR" "Puerto $PORT en uso. Seleccione otro puerto."
    exit 1
fi

# Configurar DocumentRoot
DEFAULT_DOCROOT="/srv/http"
read -p "DocumentRoot (default: /srv/http): " DOCROOT
DOCROOT=${DOCROOT:-$DEFAULT_DOCROOT}

# Crear DocumentRoot si no existe
mkdir -p "$DOCROOT"
chown http:http "$DOCROOT"
chmod 755 "$DOCROOT"

# Modificar configuración de Apache
sed -i "s|^Listen.*|Listen $PORT|" /etc/httpd/conf/httpd.conf
sed -i "s|^DocumentRoot.*|DocumentRoot \"$DOCROOT\"|" /etc/httpd/conf/httpd.conf
sed -i "s|^<Directory \"/srv/http\">|<Directory \"$DOCROOT\">|" /etc/httpd/conf/httpd.conf

# Configuraciones de seguridad
sed -i 's|^ServerSignature.*|ServerSignature Off|' /etc/httpd/conf/httpd.conf
sed -i 's|^ServerTokens.*|ServerTokens Prod|' /etc/httpd/conf/httpd.conf

# Habilitar módulos necesarios
sed -i 's|^#LoadModule rewrite_module|LoadModule rewrite_module|' /etc/httpd/conf/httpd.conf
sed -i 's|^#LoadModule deflate_module|LoadModule deflate_module|' /etc/httpd/conf/httpd.conf
sed -i 's|^#LoadModule headers_module|LoadModule headers_module|' /etc/httpd/conf/httpd.conf

# Configurar firewall
configure_firewall "$PORT"

# Crear página de prueba
echo "<html><body><h1>Apache está funcionando correctamente</h1></body></html>" > "$DOCROOT/index.html"
chown http:http "$DOCROOT/index.html"

# Iniciar y habilitar servicio
enable_service "httpd"

# Verificar instalación
if systemctl is-active --quiet httpd; then
    log "SUCCESS" "Apache instalado y configurado correctamente"
    echo -e "${GREEN}Apache está funcionando en http://localhost:$PORT${NC}"
else
    log "ERROR" "Error en la instalación de Apache"
    exit 1
fi
