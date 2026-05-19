#!/bin/bash
# tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 15
read -p "Ingrese la cantidad de caracteres para el string aleatorio: " length
read -p "¿Incluir signos? (s/n): " include_signs
read -p "¿Incluir mayúsculas? (s/n): " include_uppercase
read -p "¿Incluir números? (s/n): " include_numbers

characters='a-z'
if [[ $include_signs == "s" ]]; then
    characters+='!@#$%^&*()'
fi
if [[ $include_uppercase == "s" ]]; then
    characters+='A-Z'
fi
if [[ $include_numbers == "s" ]]; then
    characters+='0-9'
fi

random_string=$(head /dev/urandom | tr -dc "$characters" | head -c "$length")
echo "String aleatorio: $random_string"
