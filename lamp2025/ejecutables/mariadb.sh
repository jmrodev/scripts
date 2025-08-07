#!/bin/bash

# Importar funciones comunes
source "$BASE_DIR/utils/common.sh"
source "$BASE_DIR/utils/arch_helpers.sh"

# Verificar permisos de root
check_root

log "INFO" "Iniciando instalación de MariaDB..."

# Instalar MariaDB
install_package "mariadb" || exit 1
install_package "mariadb-clients" || exit 1

# Inicializar directorio de datos
log "INFO" "Inicializando directorio de datos de MariaDB..."
 mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql

# Crear directorio para backups
BACKUP_DIR="/var/backup/mysql"
mkdir -p "$BACKUP_DIR"
chown mysql:mysql "$BACKUP_DIR"

# Iniciar y habilitar servicio
enable_service "mariadb"

# Configurar MariaDB
log "INFO" "Configurando MariaDB..."

# Crear archivo de configuración personalizado
cat > /etc/my.cnf.d/custom.cnf <<EOF
[mysqld]
bind-address = 127.0.0.1
max_connections = 100
default_storage_engine = InnoDB
innodb_buffer_pool_size = 256M
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

[client]
default-character-set = utf8mb4
EOF

# Configurar contraseña root
ROOT_PASS=$(openssl rand -base64 12)
log "INFO" "Configurando contraseña root de MariaDB..."

# Asegurar instalación de forma no interactiva
mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$ROOT_PASS'; FLUSH PRIVILEGES;"
mysql -u root -p"$ROOT_PASS" -e "DELETE FROM mysql.user WHERE User='';"
mysql -u root -p"$ROOT_PASS" -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
mysql -u root -p"$ROOT_PASS" -e "DROP DATABASE IF EXISTS test;"
mysql -u root -p"$ROOT_PASS" -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
mysql -u root -p"$ROOT_PASS" -e "FLUSH PRIVILEGES;"


# Crear usuario administrativo
read -p "Nombre de usuario para administrador de MariaDB: " ADMIN_USER
while true; do
    read -s -p "Contraseña para $ADMIN_USER: " ADMIN_PASS
    echo
    read -s -p "Confirme la contraseña: " ADMIN_PASS_CONFIRM
    echo
    
    if [ "$ADMIN_PASS" = "$ADMIN_PASS_CONFIRM" ]; then
        break
    else
        echo "Las contraseñas no coinciden. Intente nuevamente."
    fi
done

# Crear usuario y otorgar privilegios
mysql -u root -p"$ROOT_PASS" <<EOF
CREATE USER '$ADMIN_USER'@'localhost' IDENTIFIED BY '$ADMIN_PASS';
GRANT ALL PRIVILEGES ON *.* TO '$ADMIN_USER'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

# Configurar backup automático
cat > /etc/cron.daily/mariadb-backup <<EOF
#!/bin/bash
BACKUP_DIR="$BACKUP_DIR"
DATE=\$(date +%Y%m%d)
mysqldump --all-databases | gzip > "\$BACKUP_DIR/full_backup_\$DATE.sql.gz"
find "\$BACKUP_DIR" -type f -mtime +7 -delete
EOF

chmod +x /etc/cron.daily/mariadb-backup

# Guardar credenciales de manera segura
mkdir -p /root/.mysql
cat > /root/.mysql/root_credentials <<EOF
[client]
user=root
password=$ROOT_PASS
EOF

chmod 600 /root/.mysql/root_credentials

log "SUCCESS" "MariaDB instalado y configurado correctamente"
echo -e "Credenciales de MariaDB guardadas en /root/.mysql/root_credentials"
echo -e "Usuario administrador: $ADMIN_USER"
