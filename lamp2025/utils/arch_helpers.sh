#!/bin/bash

# Importar funciones comunes
if [ -z "$BASE_DIR" ]; then
    echo "Error: BASE_DIR no está definido."
    exit 1
fi
source "$BASE_DIR/utils/common.sh"

# Función para actualizar el sistema
update_system() {
    log "INFO" "Actualizando sistema..."
    if pacman -Syu --noconfirm; then
        log "SUCCESS" "Sistema actualizado correctamente"
        return 0
    else
        log "ERROR" "Error al actualizar el sistema"
        return 1
    fi
}

# Función para verificar y habilitar servicios systemd
enable_service() {
    local service="$1"
    
    if systemctl is-active --quiet "$service"; then
        log "INFO" "Servicio $service ya está activo"
    else
        log "INFO" "Activando servicio $service..."
        systemctl enable --now "$service"
        
        if systemctl is-active --quiet "$service"; then
            log "SUCCESS" "Servicio $service activado correctamente"
            return 0
        else
            log "ERROR" "Error al activar servicio $service"
            return 1
        fi
    fi
}

# Función para verificar y configurar firewall
configure_firewall() {
    local port="$1"
    
    # Verificar si iptables está instalado
    if ! check_package "iptables"; then
        install_package "iptables"
    fi
    
    # Abrir puerto
    if iptables -C INPUT -p tcp --dport "$port" -j ACCEPT 2>/dev/null; then
        log "INFO" "Puerto $port ya está abierto"
    else
        iptables -A INPUT -p tcp --dport "$port" -j ACCEPT
        log "SUCCESS" "Puerto $port abierto en firewall"
    fi
}

# Función para verificar dependencias de Arch Linux
check_arch_dependencies() {
    local deps=("$@")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if ! check_package "$dep"; then
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        log "WARNING" "Dependencias faltantes: ${missing_deps[*]}"
        return 1
    fi
    return 0
}
