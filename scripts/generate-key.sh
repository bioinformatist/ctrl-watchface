#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/connectiq-env.sh
source "$script_dir/connectiq-env.sh"

repo_root="$(connectiq_repo_root)"
key_dir="$repo_root/.secrets"
key_path="$key_dir/developer_key.der"

if [ -e "$key_path" ]; then
  echo "Developer key already exists: $key_path"
  exit 0
fi

if ! command -v openssl >/dev/null 2>&1; then
  echo "openssl was not found. Enter nix develop, then rerun scripts/generate-key.sh." >&2
  exit 1
fi

mkdir -p "$key_dir"
chmod 700 "$key_dir"

tmp_pem="$(mktemp)"
trap 'rm -f "$tmp_pem"' EXIT

openssl genrsa -out "$tmp_pem" 4096
openssl pkcs8 -topk8 -inform PEM -outform DER -in "$tmp_pem" -out "$key_path" -nocrypt
chmod 600 "$key_path"

echo "Developer key written to $key_path"
