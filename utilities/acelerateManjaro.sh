#!/bin/bash

# Archivo de configuración
config_file="/etc/systemd/system.conf"

# Líneas a descomentar
lines_to_uncomment=(
    "DefaultTimeoutStartSec=5s"
    "DefaultTimeoutStopSec=5s"
)

# Función para descomentar una línea si existe
uncomment_line() {
    local line="$1"
    if grep -q "^#.*$line" "$config_file"; then
        # La línea está comentada, la descomentamos
        sudo sed -i "s/^#\s*$line/$line/" "$config_file"
        echo "Descomentada la línea: $line"
    elif grep -q "^$line" "$config_file"; then
        # La línea ya está descomentada
        echo "La línea ya está descomentada: $line"
    else
        # La línea no existe, la añadimos
        echo "$line" | sudo tee -a "$config_file" > /dev/null
        echo "Añadida la línea: $line"
    fi
}

# Comprobar si el archivo existe
if [ ! -f "$config_file" ]; then
    echo "El archivo $config_file no existe. No se pueden realizar cambios."
    exit 1
fi

# Descomentar o añadir las líneas
for line in "${lines_to_uncomment[@]}"; do
    uncomment_line "$line"
done

echo "Proceso completado. Por favor, revisa $config_file para verificar los cambios."
