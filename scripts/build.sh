#!/usr/bin/env bash
set -euo pipefail

if ! command -v monkeyc >/dev/null 2>&1; then
  echo "monkeyc was not found. Enter nix develop and set CONNECTIQ_SDK_HOME to the Garmin Connect IQ SDK." >&2
  exit 1
fi

if [ -z "${CONNECTIQ_DEVELOPER_KEY:-}" ]; then
  echo "CONNECTIQ_DEVELOPER_KEY is not set." >&2
  exit 1
fi

mkdir -p bin
monkeyc \
  -f monkey.jungle \
  -d fenix7 \
  -o bin/GravitasMasse.prg \
  -y "$CONNECTIQ_DEVELOPER_KEY"
