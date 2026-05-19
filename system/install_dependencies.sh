#!/usr/bin/env bash

set -euo pipefail

SUDO=""
if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  SUDO="sudo"
fi

detect_manager() {
  if command -v pacman >/dev/null 2>&1; then
    echo "pacman"
  elif command -v apt-get >/dev/null 2>&1; then
    echo "apt"
  elif command -v dnf >/dev/null 2>&1; then
    echo "dnf"
  elif command -v zypper >/dev/null 2>&1; then
    echo "zypper"
  else
    echo ""
  fi
}

is_arch_like() {
  if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    [[ "${ID:-}" =~ ^(arch|manjaro)$ ]] || [[ "${ID_LIKE:-}" == *"arch"* ]]
  else
    return 1
  fi
}

install_with_pacman() {
  local packages=(
    bash coreutils grep sed gawk findutils
    curl wget git openssh
    nmap dialog zenity fzf
    net-tools iproute2
    python python-pip
  )

  if is_arch_like; then
    packages+=(base-devel)
  fi

  echo "Instalando dependencias con pacman..."
  $SUDO pacman -Sy --needed --noconfirm "${packages[@]}"
}

install_with_apt() {
  local packages=(
    bash coreutils grep sed gawk findutils
    curl wget git openssh-client
    nmap dialog zenity fzf
    net-tools iproute2
    python3 python3-pip
  )

  echo "Instalando dependencias con apt..."
  $SUDO apt-get update
  $SUDO apt-get install -y "${packages[@]}"
}

install_with_dnf() {
  local packages=(
    bash coreutils grep sed gawk findutils
    curl wget git openssh-clients
    nmap dialog zenity fzf
    net-tools iproute
    python3 python3-pip
  )

  echo "Instalando dependencias con dnf..."
  $SUDO dnf install -y "${packages[@]}"
}

install_with_zypper() {
  local packages=(
    bash coreutils grep sed gawk findutils
    curl wget git openssh
    nmap dialog zenity fzf
    net-tools iproute2
    python3 python3-pip
  )

  echo "Instalando dependencias con zypper..."
  $SUDO zypper --non-interactive install "${packages[@]}"
}

main() {
  local manager
  manager="$(detect_manager)"

  if [[ -z "$manager" ]]; then
    echo "No se encontró un gestor de paquetes soportado (pacman/apt/dnf/zypper)."
    exit 1
  fi

  case "$manager" in
    pacman) install_with_pacman ;;
    apt) install_with_apt ;;
    dnf) install_with_dnf ;;
    zypper) install_with_zypper ;;
    *)
      echo "Gestor de paquetes no soportado: $manager"
      exit 1
      ;;
  esac

  echo
  echo "Dependencias base instaladas correctamente."
}

main "$@"
