#!/usr/bin/env bash

connectiq_repo_root() {
  local source_dir
  source_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
  cd -- "$source_dir/.." && pwd
}

connectiq_load_env() {
  local repo_root="$1"
  local local_key="$repo_root/.secrets/developer_key.der"
  local garmin_home="$repo_root/.garmin-home"

  export CTRL_WATCHFACE_GARMIN_HOME="$garmin_home"

  if [ -f "$local_key" ] && { [ -z "${CONNECTIQ_DEVELOPER_KEY:-}" ] || [ ! -f "$CONNECTIQ_DEVELOPER_KEY" ]; }; then
    export CONNECTIQ_DEVELOPER_KEY="$local_key"
  fi
}

connectiq_enter_repo_home() {
  local repo_root="$1"

  connectiq_load_env "$repo_root"
  mkdir -p "$CTRL_WATCHFACE_GARMIN_HOME"
  export HOME="$CTRL_WATCHFACE_GARMIN_HOME"
  export XDG_CACHE_HOME="$CTRL_WATCHFACE_GARMIN_HOME/.cache"
  mkdir -p "$XDG_CACHE_HOME"
}
