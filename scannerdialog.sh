#!/bin/bash

dialog --title "Escanear puertos" --msgbox "Este script realizará un escaneo de puertos en el host 127.0.0.1 utilizando Nmap. Se guardarán los resultados en el archivo 'allport' en el formato Grepable (oG)." 10 60

dialog --title "Confirmación" --yesno "¿Desea ejecutar el escaneo de puertos con permisos de superusuario?" 8 60

if [[ $? -eq 0 ]]; then
  sudo dialog --infobox "Ejecutando escaneo de puertos..." 5 40
  sudo nmap -p- --open -sS --min-rate 5000 -vvv -n -Pn 127.0.0.1 -oG allport
else
  dialog --infobox "Ejecutando escaneo de puertos..." 5 40
  nmap -p- --open -sS --min-rate 5000 -vvv -n -Pn 127.0.0.1 -oG allport
fi

dialog --title "Finalizado" --msgbox "El escaneo de puertos ha finalizado. Los resultados se han guardado en el archivo 'allport'." 10 60
