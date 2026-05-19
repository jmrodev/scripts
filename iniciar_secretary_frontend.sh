#!/bin/bash

TARGET_DIR="${SECRETARY_FRONTEND_DIR:-$HOME/Documentos/repositorios/secretary-frontend}"

if [ ! -d "$TARGET_DIR" ]; then
  echo "No se encontró el proyecto en: $TARGET_DIR"
  exit 1
fi

cd "$TARGET_DIR" && pnpm run dev
