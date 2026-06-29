{
  description = "Repo-local development shell for the Gravitas Masse Garmin watch face";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              bashInteractive
              coreutils
              findutils
              gnugrep
              gnused
              imagemagick
              jdk17_headless
              libxml2
            ];

            shellHook = ''
              if [ -n "''${CONNECTIQ_SDK_HOME:-}" ] && [ -x "$CONNECTIQ_SDK_HOME/bin/monkeyc" ]; then
                export PATH="$CONNECTIQ_SDK_HOME/bin:$PATH"
              else
                echo "CONNECTIQ_SDK_HOME is not set to a Garmin Connect IQ SDK with bin/monkeyc."
                echo "Install the SDK with Garmin SDK Manager, then export CONNECTIQ_SDK_HOME=/path/to/connectiq-sdk."
              fi

              if [ -z "''${CONNECTIQ_DEVELOPER_KEY:-}" ]; then
                echo "CONNECTIQ_DEVELOPER_KEY is not set; builds need a local Garmin developer key."
              fi
            '';
          };
        }
      );
    };
}
