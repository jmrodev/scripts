 #!/bin/bash

# Archivo de entrada
input_file="comandos.txt"
# Archivo de salida
output_file="comandos_concatenados.txt"

# Verificar si el archivo de entrada existe
if [ ! -f "$input_file" ]; then
    echo "El archivo $input_file no existe."
    exit 1
fi

# Contador de líneas
line_count=0
# Almacenar las líneas concatenadas temporalmente
buffer=""

# Procesar cada línea
while read -r line; do
    # Limpiar la línea
    clean_line=$(echo "$line" | sed 's/^[[:space:]]*[0-9]\+[[:space:]]*//')
    # Agregar la línea limpia al buffer
    buffer+="$clean_line "
    # Incrementar el contador
    ((line_count++))

    # Cada 20 líneas, escribir al archivo de salida
    if (( line_count == 20 )); then
        echo "$buffer" >> "$output_file"
        buffer=""  # Reiniciar el buffer
        line_count=0  # Reiniciar el contador de líneas
    fi
done < "$input_file"

# Verificar si queda algo en el buffer después de terminar el bucle
if [ -n "$buffer" ]; then
    echo "$buffer" >> "$output_file"
fi

echo "Los comandos han sido procesados y guardados en $output_file."
