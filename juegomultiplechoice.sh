#!/bin/bash

# Definir las preguntas y respuestas
questions=(
  "¿Cuál es la capital de Francia?"
  "¿Cuántas patas tiene un perro?"
  "¿En qué año se fundó Apple?"
  "¿Cuál es el color del cielo?"
  "¿Cuál es el resultado de 2 + 2?"
  "¿Qué animal es conocido por decir 'miau'?"
  "¿Cuál es el número de pi (π)?"
  "¿Cuál es el principal componente del aire?"
  "¿Quién escribió el libro 'Don Quijote de la Mancha'?"
  "¿Cuál es el símbolo químico del agua?"
  "¿Cuál es el planeta más grande del sistema solar?"
  "¿Qué animal es conocido por tener trompa?"
  "¿Cuántas patas tiene una araña?"
  "¿Cuál es el nombre del protagonista de la serie 'Breaking Bad'?"
  "¿Cuál es el resultado de 10 * 5?"
  "¿Qué instrumento se utiliza para medir la temperatura?"
  "¿En qué año se celebraron los primeros Juegos Olímpicos modernos?"
  "¿Cuál es la capital de Japón?"
  "¿Cuál es el símbolo químico del oxígeno?"
  "¿Cuál es el resultado de 100 / 10?"
)

choices=(
  "a) París" "b) Londres" "c) Roma" "d) Madrid" "e) Moscú"
  "a) 2" "b) 4" "c) 6" "d) 8" "e) 10"
  "a) 1976" "b) 1984" "c) 1991" "d) 2000" "e) 2010"
  "a) Azul" "b) Rojo" "c) Verde" "d) Amarillo" "e) Rosa"
  "a) 1" "b) 2" "c) 3" "d) 4" "e) 5"
  "a) Perro" "b) Gato" "c) Vaca" "d) Caballo" "e) Pájaro"
  "a) 3.1416" "b) 3.1418" "c) 3.1419" "d) 3.1422" "e) 3.1424"
  "a) Nitrógeno" "b) Oxígeno" "c) Carbono" "d) Hidrógeno" "e) Helio"
  "a) Miguel de Cervantes" "b) Federico García Lorca" "c) Gabriel García Márquez" "d) Julio Cortázar" "e) Pablo Neruda"
  "a) H2O" "b) CO2" "c) O2" "d) NaCl" "e) C6H12O6"
  "a) Júpiter" "b) Marte" "c) Venus" "d) Saturno" "e) Urano"
  "a) Elefante" "b) Rinoceronte" "c) Hipopotamo" "d) Jirafa" "e) Oso"
  "a) 6" "b) 8" "c) 10" "d) 12" "e) 14"
  "a) Walter White" "b) Jesse Pinkman" "c) Saul Goodman" "d) Skyler White" "e) Hank Schrader"
  "a) 50" "b) 15" "c) 100" "d) 5" "e) 20"
  "a) Termómetro" "b) Barómetro" "c) Pluviómetro" "d) Anemómetro" "e) Cronómetro"
  "a) 1896" "b) 1900" "c) 1924" "d) 1936" "e) 2000"
  "a) Tokio" "b) Pekín" "c) Seúl" "d) Bangkok" "e) Sídney"
  "a) O" "b) Ox" "c) Oxg" "d) Oxy" "e) O2"
  "a) 10" "b) 15" "c) 5" "d) 50" "e) 20"
)

# Inicializar el contador de respuestas correctas
score=0

# Iterar a través de las preguntas y mostrarlas utilizando `dialog`
for (( i=0; i<${#questions[@]}; i++ )); do
  question="${questions[$i]}"
  correct_answer="${choices[$((i*5))]}"
  incorrect_answers="${choices[@]:$((i*5+1)):4}"

  options=("a" "b" "c" "d" "e")

  # Mezclar las opciones de respuesta (incluyendo una opción incorrecta absurda)
  mixed_choices=()
  mixed_choices+=("$correct_answer")
  mixed_choices+=("$incorrect_answers")
  mixed_choices=($(shuf -e "${mixed_choices[@]}"))

  # Solicitar la respuesta del usuario utilizando `dialog`
  dialog --title "Pregunta $(($i+1))" --radiolist "$question" 12 60 5 "${options[@]}" "${mixed_choices[@]}" 2>/tmp/answer.txt

  # Leer la respuesta seleccionada por el usuario desde el archivo temporal
  user_answer=$(cat /tmp/answer.txt)

  # Comparar la respuesta del usuario con la respuesta correcta
  if [[ "$user_answer" == "a" ]]; then
    dialog --title "Correcto" --msgbox "¡Respuesta correcta!" 8 40
    ((score++))
  else
    dialog --title "Incorrecto" --msgbox "Respuesta incorrecta. La respuesta correcta es: $correct_answer" 10 60
  fi

  # Borrar el archivo temporal de respuesta
  rm /tmp/answer.txt
done

# Mostrar el puntaje final utilizando `dialog`
dialog --title "Puntaje Final" --msgbox "Has obtenido $score respuestas correctas de ${#questions[@]} preguntas." 10 60
