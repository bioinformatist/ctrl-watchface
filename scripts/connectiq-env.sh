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

  export GRAVITAS_GARMIN_HOME="$garmin_home"

  if [ -f "$local_key" ] && { [ -z "${CONNECTIQ_DEVELOPER_KEY:-}" ] || [ ! -f "$CONNECTIQ_DEVELOPER_KEY" ]; }; then
    export CONNECTIQ_DEVELOPER_KEY="$local_key"
  fi
}

connectiq_enter_repo_home() {
  local repo_root="$1"
  local need_java_home=0

  connectiq_load_env "$repo_root"
  mkdir -p "$GRAVITAS_GARMIN_HOME"
  export HOME="$GRAVITAS_GARMIN_HOME"
  export XDG_CACHE_HOME="$GRAVITAS_GARMIN_HOME/.cache"
  mkdir -p "$XDG_CACHE_HOME"
  unset GRAVITAS_CONNECTIQ_JAVA_HOME_FALLBACK

  if [ -n "${CONNECTIQ_SDK_HOME:-}" ] &&
    [ -f "$CONNECTIQ_SDK_HOME/bin/monkeyc" ] &&
    ! grep -q -- "-Duser.home" "$CONNECTIQ_SDK_HOME/bin/monkeyc"; then
    need_java_home=1
  elif [ -z "${CONNECTIQ_SDK_HOME:-}" ] && command -v monkeyc >/dev/null 2>&1; then
    need_java_home=1
  fi

  if [ "$need_java_home" -eq 1 ]; then
    case " ${JAVA_TOOL_OPTIONS:-} " in
      *" -Duser.home="*) ;;
      *) export JAVA_TOOL_OPTIONS="-Duser.home=$HOME ${JAVA_TOOL_OPTIONS:-}" ;;
    esac
    export GRAVITAS_CONNECTIQ_JAVA_HOME_FALLBACK=1
  fi
}
