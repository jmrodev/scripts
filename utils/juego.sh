#!/bin/bash

# Definir las preguntas y respuestas
questions=(
  "¿Cuál es la capital de Francia?"
  "¿Cuántas patas tiene un perro?"
  "¿En qué año se fundó Apple?"
)

answers=(
  "París"
  "4"
  "1976"
)

# Inicializar el contador de respuestas correctas
score=0

# Iterar a través de las preguntas y mostrarlas utilizando `dialog`
for (( i=0; i<${#questions[@]}; i++ )); do
  question="${questions[$i]}"
  answer="${answers[$i]}"

  dialog --title "Pregunta $(($i+1))" --msgbox "$question" 8 60

  # Solicitar la respuesta del usuario utilizando `dialog`
  user_answer=$(dialog --title "Respuesta $(($i+1))" --inputbox "Ingrese su respuesta:" 8 60 3>&1 1>&2 2>&3)

  # Comparar la respuesta del usuario con la respuesta correcta
  if [[ "$user_answer" == "$answer" ]]; then
    dialog --title "Correcto" --msgbox "¡Respuesta correcta!" 8 40
    ((score++))
  else
    dialog --title "Incorrecto" --msgbox "Respuesta incorrecta. La respuesta correcta es: $answer" 10 60
  fi
done

# Mostrar el puntaje final utilizando `dialog`
dialog --title "Puntaje Final" --msgbox "Has obtenido $score respuestas correctas de ${#questions[@]} preguntas." 10 60
