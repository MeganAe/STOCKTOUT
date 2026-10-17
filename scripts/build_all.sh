#!/usr/bin/env bash
# Compile en local pour l'OS courant (utile avant de pousser).
set -euo pipefail
cd "$(dirname "$0")/.."

flutter pub get

case "$(uname -s)" in
  Linux*)   flutter build linux --release ;;
  Darwin*)  flutter build macos --release ;;
  MINGW*|MSYS*|CYGWIN*) flutter build windows --release ;;
  *) echo "OS non reconnu : $(uname -s)"; exit 1 ;;
esac

echo "OK — voir build/"
