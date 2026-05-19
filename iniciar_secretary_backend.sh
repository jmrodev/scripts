#!/bin/bash

TARGET_DIR="${SECRETARY_BACKEND_DIR:-$HOME/Documentos/repositorios/secretary-backend}"

if [ ! -d "$TARGET_DIR" ]; then
  echo "No se encontró el proyecto en: $TARGET_DIR"
  exit 1
fi

cd "$TARGET_DIR" && npm run dev
