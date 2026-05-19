#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYSTEM_DIR="$ROOT_DIR/system"
NETWORK_DIR="$ROOT_DIR/network"
UTILS_DIR="$ROOT_DIR/utils"
LAMP_DIR="$ROOT_DIR/lamp"
DEPENDENCY_SCRIPT="$SYSTEM_DIR/install_dependencies.sh"

handle_interrupt() {
  echo
  echo "Interrupción detectada. Saliendo..."
  exit 130
}

trap handle_interrupt SIGINT SIGTERM

print_header() {
  echo
  echo "=============================================="
  echo "  Scripts Manager (Linux / enfoque ArchLinux)"
  echo "=============================================="
  echo
}

list_scripts() {
  local dir="$1"
  local exclude_file="${2:-}"

  find "$dir" -type f \( -name "*.sh" -o -name "*.bash" \) 2>/dev/null \
    | sort \
    | while IFS= read -r script; do
        if [[ -n "$exclude_file" && "$script" == "$exclude_file" ]]; then
          continue
        fi
        if [[ -x "$script" || "$script" == *.sh || "$script" == *.bash ]]; then
          echo "$script"
        fi
      done
}

run_script() {
  local script_path="$1"

  if [[ ! -f "$script_path" ]]; then
    echo "No se encontró: $script_path"
    return
  fi

  echo
  echo "Ejecutando: $script_path"
  echo "----------------------------------------------"
  bash "$script_path"
  echo "----------------------------------------------"
  echo
  read -r -p "Presiona Enter para continuar..." _
}

show_category_menu() {
  local category_name="$1"
  local category_dir="$2"
  local exclude_file="${3:-}"

  while true; do
    mapfile -t scripts < <(list_scripts "$category_dir" "$exclude_file")

    echo
    echo "=== $category_name ==="

    if [[ ${#scripts[@]} -eq 0 ]]; then
      echo "No hay scripts disponibles en esta categoría."
      read -r -p "Presiona Enter para volver..." _
      return
    fi

    for i in "${!scripts[@]}"; do
      relative_path="${scripts[$i]#"$ROOT_DIR"/}"
      printf "%2d) %s\n" "$((i + 1))" "$relative_path"
    done
    echo " 0) Volver"

    read -r -p "Selecciona una opción: " choice

    if [[ "$choice" == "0" ]]; then
      return
    fi

    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#scripts[@]} )); then
      run_script "${scripts[$((choice - 1))]}"
    else
      echo "Opción inválida."
    fi
  done
}

main_menu() {
  while true; do
    print_header
    echo "1) Instalar dependencias base (recomendado)"
    echo "2) Menú de Sistema"
    echo "3) Menú de Red"
    echo "4) Menú de Utilidades"
    echo "5) Menú LAMP"
    echo "0) Salir"
    echo

    read -r -p "Elige una opción: " option

    case "$option" in
      1) run_script "$DEPENDENCY_SCRIPT" ;;
      2) show_category_menu "Sistema" "$SYSTEM_DIR" "$DEPENDENCY_SCRIPT" ;;
      3) show_category_menu "Red" "$NETWORK_DIR" ;;
      4) show_category_menu "Utilidades" "$UTILS_DIR" ;;
      5) show_category_menu "LAMP" "$LAMP_DIR" ;;
      0) echo "Saliendo."; exit 0 ;;
      *) echo "Opción inválida." ;;
    esac
  done
}

main_menu
