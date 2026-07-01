# Contributing

This repository is a Garmin Connect IQ watch face project. It should not install Garmin tooling, simulator dependencies, device files, or signing keys into the global user environment.

## Development Boundary

The development setup follows these rules:

- Do not use `nix profile install` for this project.
- Do not change NixOS or Home Manager configuration for this project.
- Do not export Connect IQ variables from a global shell profile.
- Do not write Garmin device files into `~/.Garmin`.
- Do not commit Garmin SDK files, device files, simulator state, generated keys, or build outputs.

Nix store entries are acceptable. They are cacheable build outputs, are not added to the global `PATH`, and can be removed by normal Nix garbage collection.

The default development shell includes the GUI simulator launcher, so the first `nix develop` or simulator build may realize a large `steam-run` runtime closure. That cost stays in the Nix store; it does not install Garmin tooling or simulator libraries into the user profile.

## Toolchain Structure

The intended local layout is:

```text
nix/
  connectiq.nix
  connect-iq-sdk-manager-cli.nix
scripts/
  ciq-setup.sh
  generate-key.sh
  build.sh
  sim.sh
.garmin-home/
  .Garmin/ConnectIQ/
.secrets/
  developer_key.der
bin/
  GravitasMasse.prg
```

`nix/connectiq.nix` packages Garmin's Connect IQ SDK as an unfree, pinned binary dependency. The SDK itself stays in the Nix store, not in the repository.

`nix/connect-iq-sdk-manager-cli.nix` packages the headless Connect IQ SDK Manager CLI. It is used for agreement, login, and device/font downloads without relying on Garmin's GUI SDK Manager.

`connectiq-simulator` is a repo-local launcher for Garmin's GUI simulator. It runs only the native simulator under `steam-run` because Garmin's GTK/WebKit simulator is fragile under a plain Nix runtime. The compiler tools still run through the normal Nix package.

When launched from the development shell or from the repository checkout, `connectiq-simulator` uses `.garmin-home/` as `HOME`. Prefer `scripts/sim.sh` for normal testing because it also builds the watch face and runs `monkeydo`.

`.garmin-home/` is the repo-local Garmin home directory. Scripts set `HOME=$PWD/.garmin-home` when running SDK Manager, `monkeyc`, `connectiq`, or `monkeydo`, so device definitions and fonts land in this repository's ignored local state instead of `~/.Garmin`.

`.secrets/developer_key.der` is the repo-local signing key. Keep it private and preserve it if the same Connect IQ app ID will be updated later.

`bin/` contains generated `.prg`, `.iq`, and debug artifacts.

`mtp-detect`, `mtp-folders`, `mtp-files`, and `mtp-sendfile` are available in the development shell for physical-device debugging. They come from `libmtp` in the Nix store and are not installed into the user profile.

## First-Time Setup

Enter the development shell:

```sh
nix develop
```

Generate a local signing key:

```sh
scripts/generate-key.sh
```

Set up Garmin device files and fonts:

```sh
scripts/ciq-setup.sh
```

This setup step may require interactive Garmin account login and Connect IQ agreement acceptance. Those credentials and decisions are user-owned; do not automate them with committed secrets.

## Build And Simulator

Build the watch face:

```sh
scripts/build.sh
```

Run it in the Garmin simulator:

```sh
scripts/sim.sh
```

`scripts/sim.sh` starts the GUI simulator through `connectiq-simulator`, then loads the built `.prg` with `monkeydo`. After `monkeydo` connects, it keeps the terminal attached to the simulator until the simulator exits or the command is interrupted.

For a non-interactive smoke test, wrap the command with `timeout`, for example:

```sh
timeout 25s scripts/sim.sh
```

Exit code `124` means `timeout` stopped a still-running simulator session. That is expected when the simulator starts and `monkeydo` stays attached.

The simulator is useful for layout, resource loading, animation, and basic watch face lifecycle checks. Final low-power behavior, wake handling, and real complication values still need a fēnix 7X test.

## Physical Device Debugging

Use MTP side-loading only for development builds. End-user distribution should go through the Connect IQ Store once the watch face is ready for publication.

Build a fēnix 7X `.prg`:

```sh
nix develop -c scripts/build.sh
```

Put the watch in MTP mode, then connect it over USB. On Linux, the USB device node is usually not readable by an ordinary user, so run the MTP commands through `sudo` while resolving the tool path inside the development shell.

Confirm the watch is visible as an MTP device:

```sh
nix develop -c sh -c 'sudo "$(command -v mtp-detect)"'
```

Confirm that `GARMIN/Apps` exists:

```sh
nix develop -c sh -c 'sudo "$(command -v mtp-folders)" | grep -F "Apps"'
```

Side-load the debug build. `mtp-sendfile` uses the local file basename as the remote filename, so create a temporary 8.3-style name first and send it to the existing `GARMIN/Apps` folder:

```sh
cp bin/GravitasMasse.prg /tmp/GRVMASSE.PRG
nix develop -c sh -c 'sudo "$(command -v mtp-sendfile)" /tmp/GRVMASSE.PRG /GARMIN/Apps'
rm -f /tmp/GRVMASSE.PRG
```

Check that the file landed in the Apps folder:

```sh
nix develop -c sh -c 'sudo "$(command -v mtp-files)"' |
  awk 'BEGIN{id=""; name=""; size=""; parent=""}
       /^File ID:/ {id=$3; name=""; size=""; parent=""}
       /Filename:/ {name=$2}
       /File size/ {size=$3}
       /Parent ID:/ {parent=$3}
       /Filetype:/ {if (parent=="16777229") print id, name, size, parent}'
```

The `16777229` parent ID is the observed `GARMIN/Apps` folder ID on the test fēnix 7X. If a different watch or firmware reports a different ID, use `mtp-folders` to find the current `Apps` folder ID before filtering.

After side-loading, disconnect USB and let the watch leave MTP mode. If `Gravitas Masse` does not appear in the watch-face picker immediately, wait for the watch to process the new file or restart the watch.

Do not document this side-loading path as a user installation method in [`README.md`](README.md). It bypasses the Connect IQ Store approval and update flow.

## Store Publication

Garmin Store publication uses an `.iq` package, not the debug `.prg` copied by MTP. Garmin's published flow is to export the project, upload the `.iq` package, add the store listing, and wait for review before it appears in the Connect IQ Store.

Before preparing a Store package, check:

- `manifest.xml` lists every product intended for release.
- The app ID and `.secrets/developer_key.der` are preserved for future updates.
- The animation asset, app name, screenshots, and description are cleared for public distribution.
- Real-device behavior has been checked on a fēnix 7X, including low-power mode, wake behavior, and live complication values.

Garmin submission details are documented at <https://developer.garmin.com/connect-iq/submit-an-app/>.

## Debugging

Use the shortest loop that matches the problem:

- For compile errors, run `scripts/build.sh`.
- For layout, frame loading, and animation behavior, run `scripts/sim.sh`.
- For quick state tracing, add temporary `System.println()` calls and run in the simulator.
- For breakpoints and local variables, use Garmin's Connect IQ Visual Studio Code debugger or the SDK `mdd` command-line debugger against the generated `bin/GravitasMasse.prg` and `bin/GravitasMasse.prg.debug.xml`.
- For real low-power mode, wake behavior, complications, and on-device crashes, test on the fēnix 7X.

The repo-local SDK documentation is available inside the development shell at `$CONNECTIQ_SDK_HOME/doc/index.html`. Garmin's debugging guide is under `Core Topics -> Testing and Debugging`.

On a real watch, `System.println()` output is written only if a matching log file already exists under `/GARMIN/APPS/LOGS/`. App crash reports are written to `/GARMIN/APPS/LOGS/CIQ_LOG.YAML`.

## Troubleshooting

If `monkeyc` reports `ERROR: Invalid device id specified: 'fenix7x'`, check the repo-local device files first:

```sh
scripts/ciq-setup.sh
```

If the setup has already completed, refresh the development shell so it uses the current pinned SDK package:

```sh
direnv reload
# or
nix develop -c scripts/build.sh
```

This project keeps Garmin state under `.garmin-home/`. Do not fix this error by copying device files into `~/.Garmin`.

If `scripts/sim.sh` reports `connectiq-simulator was not found`, refresh the development shell so the simulator launcher from the current flake is on `PATH`:

```sh
direnv reload
# or
nix develop -c scripts/sim.sh
```

If `scripts/sim.sh` reports `Unable to connect to simulator`, read the simulator log printed by the script. The default log path is `/tmp/gravitas-masse-connectiq.log`. If the output also mentions the compatibility Java home fallback, refresh the development shell before debugging the watch face:

```sh
direnv reload
# or
nix develop -c scripts/sim.sh
```

## Project Scope

This repository only targets a Connect IQ `watchface` for `fenix7x`. Do not add app, widget, glance, data field, or background-service behavior unless the product scope changes explicitly.

The watch face does not request sensor permissions. Heart rate and Body Battery are read through Garmin complications when available and render as `--` otherwise.
