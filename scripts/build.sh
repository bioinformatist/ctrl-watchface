#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/connectiq-env.sh
source "$script_dir/connectiq-env.sh"

repo_root="$(connectiq_repo_root)"
connectiq_enter_repo_home "$repo_root"
cd "$repo_root"

if ! command -v monkeyc >/dev/null 2>&1; then
  echo "monkeyc was not found. Enter nix develop, then rerun scripts/build.sh." >&2
  exit 1
fi

if [ -z "${CONNECTIQ_DEVELOPER_KEY:-}" ] || [ ! -f "$CONNECTIQ_DEVELOPER_KEY" ]; then
  echo "Developer key not found. Run scripts/generate-key.sh or copy a key to .secrets/developer_key.der." >&2
  exit 1
fi

mkdir -p bin
monkeyc \
    -f monkey.jungle \
    -d fenix7x \
    -o bin/GravitasMasse.prg \
    -y "$CONNECTIQ_DEVELOPER_KEY" || {
  status=$?
  echo "Build failed. If monkeyc reports an invalid device id, run scripts/ciq-setup.sh and rerun through a fresh nix develop or direnv shell." >&2
  exit "$status"
}
