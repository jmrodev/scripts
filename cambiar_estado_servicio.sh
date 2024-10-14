#!/bin/bash

services=("sshd" "ufw" "httpd" "mariadb" "php-fpm.service" "phpmyadmin" "cockpit" "portainer" "zoneminder" "docker" "vboxservice" "nzbget" "prowlarr" "lidarr" "sonarr" "radarr" "readarr" "php")

echo "Selecciona la acción para cada servicio:"
echo "1. Habilitar"
echo "2. Deshabilitar"
echo "3. Detener"
echo "4. Iniciar"
echo "5. Estado"
echo "0. Salir"

for service in "${services[@]}"
do
  echo "------------------------------"
  echo "Servicio: $service"

  read -p "Elige una opción (0-5): " choice

  case $choice in
    0)
      break;;
    1)
      sudo systemctl enable $service
      echo "Servicio $service habilitado.";;
    2)
      sudo systemctl disable $service
      echo "Servicio $service deshabilitado.";;
    3)
      sudo systemctl stop $service
      echo "Servicio $service detenido.";;
    4)
      sudo systemctl start $service
      echo "Servicio $service iniciado.";;
    5)
      sudo systemctl status $service;;
    *)
      echo "Opción inválida.";;
  esac
done


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
