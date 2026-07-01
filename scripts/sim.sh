#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/connectiq-env.sh
source "$script_dir/connectiq-env.sh"

repo_root="$(connectiq_repo_root)"
connectiq_enter_repo_home "$repo_root"
cd "$repo_root"

if [ -z "${DISPLAY:-}" ] && [ -z "${WAYLAND_DISPLAY:-}" ]; then
  echo "No graphical display was found. Run the simulator from a graphical session." >&2
  exit 1
fi

"$repo_root/scripts/build.sh"

if ! command -v connectiq-simulator >/dev/null 2>&1; then
  echo "connectiq-simulator was not found. Enter a fresh nix develop, then rerun scripts/sim.sh." >&2
  exit 1
fi

if ! command -v monkeydo >/dev/null 2>&1; then
  echo "monkeydo was not found. Enter nix develop, then rerun scripts/sim.sh." >&2
  exit 1
fi

sim_log="${TMPDIR:-/tmp}/ctrl-watchface-connectiq.log"
monkeydo_log="${TMPDIR:-/tmp}/ctrl-watchface-monkeydo.log"
rm -f "$monkeydo_log"
sim_pid=""

cleanup() {
  if [ -n "$sim_pid" ] && kill -0 "$sim_pid" 2>/dev/null; then
    kill "$sim_pid" 2>/dev/null || true
    wait "$sim_pid" 2>/dev/null || true
  fi
  rm -f "$monkeydo_log"
}

trap cleanup EXIT INT TERM

connectiq-simulator >"$sim_log" 2>&1 &
sim_pid=$!

for attempt in $(seq 1 20); do
  if ! jobs -r -p | grep -qx "$sim_pid"; then
    status=1
    wait "$sim_pid" || status=$?
    echo "Connect IQ simulator exited before monkeydo could connect. Simulator log: $sim_log" >&2
    tail -n 80 "$sim_log" >&2 || true
    rm -f "$monkeydo_log"
    exit "$status"
  fi

  if monkeydo bin/ctrl-watchface.prg fenix7x 2>&1 | tee "$monkeydo_log"; then
    rm -f "$monkeydo_log"
    exit 0
  fi
  status=$?

  if ! grep -q "Unable to connect to simulator" "$monkeydo_log"; then
    cat "$monkeydo_log" >&2
    rm -f "$monkeydo_log"
    exit "$status"
  fi

  sleep 1
done

cat "$monkeydo_log" >&2
echo "Unable to connect to simulator after waiting. Simulator log: $sim_log" >&2
tail -n 80 "$sim_log" >&2 || true
rm -f "$monkeydo_log"
exit "$status"
