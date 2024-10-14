#
# #!/bin/bash
#
# services=("sshd" "nginx" "httpd" "mysql" "apache2" "postgresql" "redis" "memcached" "mongodb" "docker")
#
# for service in "${services[@]}"
# do
#   echo "Service: $service"
#
#   is_active=$(systemctl is-active $service)
#   if [[ $is_active == "active" ]]; then
#     echo " - Active"
#   else
#     echo " - Inactive"
#   fi
#
#   is_enabled=$(systemctl is-enabled $service)
#   if [[ $is_enabled == "enabled" ]]; then
#     echo " - Enabled"
#   else
#     echo " - Disabled"
#   fi
#
#   echo "-------------------"
# done
#!/bin/bash

services=("sshd" "nginx" "httpd" "mysql" "apache2" "postgresql" "redis" "memcached" "mongodb" "docker")

# Imprimir fila de la tabla
print_row() {
  printf "| %-15s | %-10s | %-10s |\n" "$1" "$2" "$3"
}

# Imprimir línea separadora de la tabla
print_separator() {
  printf "+-----------------+------------+------------+\n"
}

# Encabezado de la tabla
print_row "Service" "Active" "Enabled"
print_separator

# Verificar el estado y la habilitación de cada servicio
for service in "${services[@]}"
do
  is_active=$(systemctl is-active $service)
  is_enabled=$(systemctl is-enabled $service)

  print_row "$service" "$is_active" "$is_enabled"
  print_separator
done
