#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/connectiq-env.sh
source "$script_dir/connectiq-env.sh"

repo_root="$(connectiq_repo_root)"
connectiq_enter_repo_home "$repo_root"
cd "$repo_root"

if ! command -v connect-iq-sdk-manager >/dev/null 2>&1; then
  echo "connect-iq-sdk-manager-cli was not found. Enter nix develop, then rerun scripts/ciq-setup.sh." >&2
  exit 1
fi

echo "Using repo-local Garmin home: $HOME"
echo "Garmin login and agreement state will stay under .garmin-home/."

echo "Accepting Garmin Connect IQ agreements..."
connect-iq-sdk-manager agreement accept

if ! connect-iq-sdk-manager login; then
  status=$?
  echo "Garmin login failed." >&2
  echo "If browser SSO fails, rerun with GARMIN_USERNAME and GARMIN_PASSWORD set in your shell." >&2
  exit "$status"
fi

connect-iq-sdk-manager device download --manifest manifest.xml --include-fonts
