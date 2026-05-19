#!/bin/bash

# Define los límites de uso de CPU o MEMORIA que consideras innecesarios.
CPU_LIMITE=80
MEM_LIMITE=80

# Encuentra el PID de la pestaña actual de Chrome en uso.
CHROME_PID=$(xdotool getwindowfocus getwindowpid)

# Encuentra procesos que estén utilizando más CPU o memoria del límite especificado, pero excluye el proceso de Chrome activo.
ps -eo pid,comm,pcpu,pmem --sort=-pcpu | awk -v cpu="$CPU_LIMITE" -v mem="$MEM_LIMITE" -v chrome_pid="$CHROME_PID" 'NR>1 {if (($3 > cpu || $4 > mem) && $1 != chrome_pid) print $1, $2, $3, $4}' | while read pid name cpu mem; do
    echo "Matando proceso $name con PID $pid (CPU: $cpu%, MEM: $mem%)"
    kill -9 $pid
done

echo "Procesos innecesarios han sido detenidos, excepto la pestaña activa de Chrome (PID: $CHROME_PID)."
