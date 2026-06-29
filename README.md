# Gravitas Masse

Garmin fēnix 7 watch face experiment with a wake-only central animation and low-power static rendering.

The animation is intentionally committed as fixed PNG frames under `resources/drawables/images/`. The original GIF is not needed to build or maintain this watch face.

## Development

Install the Garmin Connect IQ SDK with Garmin SDK Manager, then point the repo-local shell at it:

```sh
export CONNECTIQ_SDK_HOME=/path/to/connectiq-sdk
export CONNECTIQ_DEVELOPER_KEY=$HOME/.garmin/developer_key.der
nix develop
```

Build the watch face:

```sh
scripts/build.sh
```

The project intentionally targets only `watchface` for `fenix7`. It does not request sensor permissions; heart rate and Body Battery are read through Garmin complications when available and render as `--` otherwise.

The repo-local dev shell provides open-source tooling only. Garmin's Connect IQ SDK and the developer key stay outside the repository because the SDK is installed through Garmin SDK Manager and the key is a local secret.
