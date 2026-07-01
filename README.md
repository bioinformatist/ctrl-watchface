# Gravitas Masse

Garmin fēnix 7X watch face experiment with a wake-only central animation and low-power static rendering.

The animation is intentionally committed as fixed PNG frames under `resources/drawables/images/`. The original GIF is not needed to build or maintain this watch face.

## Rendering Notes

The checked-in animation uses 16 two-color PNG frames, about 16 KB total. The frames are loaded once during layout and reused during updates, so each animation tick draws a single bitmap.

NES-style decomposition was considered, but these frames do not have a stable base layer: frame-to-frame changes usually cover most of the figure, and tile reuse is low. Base-plus-diff or tile-atlas encodings would save only a few kilobytes while replacing one bitmap draw with many line or tile draws per frame. A hand-built puppet sprite system could be smaller, but it would be a redraw of the animation rather than a faithful version of these frames.

## Development

The Connect IQ SDK is provided by the repo-local Nix dev shell. Garmin account state, device files, fonts, and signing keys stay in ignored local directories. See `CONTRIBUTING.md` for the development boundary.

Generate a repo-local developer key:

```sh
nix develop
scripts/generate-key.sh
```

Download Garmin device files and fonts:

```sh
scripts/ciq-setup.sh
```

This may require interactive Garmin login and Connect IQ agreement acceptance. If you already have a Garmin developer key, copy it to `.secrets/developer_key.der` instead of generating a new one.

Build the watch face:

```sh
scripts/build.sh
```

Run it in the Garmin simulator:

```sh
scripts/sim.sh
```

The simulator command keeps the terminal attached after the watch face loads. Close the simulator window or press Ctrl-C to stop it.

The project intentionally targets only `watchface` for `fenix7x`. It does not request sensor permissions; heart rate and Body Battery are read through Garmin complications when available and render as `--` otherwise.

The simulator is enough for layout, resource loading, animation, and basic lifecycle checks. Final low-power behavior, wake handling, and real complication values still need a fēnix 7X test.
