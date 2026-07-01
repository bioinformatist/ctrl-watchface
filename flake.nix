{
  description = "Repo-local development shell for the Gravitas Masse Garmin watch face";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-ciq.url = "github:NixOS/nixpkgs/nixos-23.11";
  };

  outputs =
    { nixpkgs, nixpkgs-ciq, ... }:
    let
      systems = [
        "x86_64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      mkPkgs =
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      mkCiqPkgs =
        system:
        import nixpkgs-ciq {
          inherit system;
          config.allowUnfree = true;
        };
      mkConnectiq =
        system:
        let
          pkgsCiq = mkCiqPkgs system;
        in
        pkgsCiq.callPackage ./nix/connectiq.nix {
          adwaita-icon-theme = pkgsCiq.gnome.adwaita-icon-theme;
        };
      mkConnectiqSimulator =
        system:
        let
          pkgs = mkPkgs system;
          connectiq = mkConnectiq system;
        in
        pkgs.writeShellApplication {
          name = "connectiq-simulator";
          runtimeInputs = [
            pkgs.coreutils
            pkgs.steam-run
          ];
          text = ''
            if [ -z "''${GRAVITAS_GARMIN_HOME:-}" ]; then
              repo_root="$PWD"
              while [ "$repo_root" != "/" ] && [ ! -f "$repo_root/scripts/connectiq-env.sh" ]; do
                repo_root="$(dirname "$repo_root")"
              done

              if [ -f "$repo_root/scripts/connectiq-env.sh" ]; then
                export GRAVITAS_GARMIN_HOME="$repo_root/.garmin-home"
              fi
            fi

            if [ -n "''${GRAVITAS_GARMIN_HOME:-}" ]; then
              mkdir -p "$GRAVITAS_GARMIN_HOME"
              export HOME="$GRAVITAS_GARMIN_HOME"
              export XDG_CACHE_HOME="''${XDG_CACHE_HOME:-$GRAVITAS_GARMIN_HOME/.cache}"
              mkdir -p "$XDG_CACHE_HOME"
            fi

            exec steam-run ${connectiq}/opt/connectiq/bin/connectiq "$@"
          '';
        };
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = mkPkgs system;
          connectiq = mkConnectiq system;
          connectiqSimulator = mkConnectiqSimulator system;
        in
        {
          inherit connectiq;
          connectiq-simulator = connectiqSimulator;
          connect-iq-sdk-manager-cli = pkgs.callPackage ./nix/connect-iq-sdk-manager-cli.nix { };
          default = connectiq;
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = mkPkgs system;
          connectiq = mkConnectiq system;
          connectiqSimulator = mkConnectiqSimulator system;
          sdkManager = pkgs.callPackage ./nix/connect-iq-sdk-manager-cli.nix { };
        in
        {
          default = pkgs.mkShell {
            packages = [
              connectiq
              connectiqSimulator
              sdkManager
              pkgs.bashInteractive
              pkgs.coreutils
              pkgs.findutils
              pkgs.gnugrep
              pkgs.gnused
              pkgs.imagemagick
              pkgs.jdk17
              pkgs.libmtp
              pkgs.libxml2
              pkgs.openssl
            ];

            shellHook = ''
              repo_root="$PWD"
              while [ "$repo_root" != "/" ] && [ ! -f "$repo_root/scripts/connectiq-env.sh" ]; do
                repo_root="$(dirname "$repo_root")"
              done

              if [ -f "$repo_root/scripts/connectiq-env.sh" ]; then
                . "$repo_root/scripts/connectiq-env.sh"
                connectiq_load_env "$repo_root"
              fi

              export CIQ_HOME="${connectiq}/opt/connectiq"
              export CONNECTIQ_SDK_HOME="$CIQ_HOME"

              echo "Connect IQ SDK: ${connectiq.version}"
              echo "Garmin home: $repo_root/.garmin-home"

              if [ -n "''${CONNECTIQ_DEVELOPER_KEY:-}" ] && [ -f "$CONNECTIQ_DEVELOPER_KEY" ]; then
                echo "Developer key: $CONNECTIQ_DEVELOPER_KEY"
              else
                echo "Developer key not found. Generate a repo-local key with:"
                echo "  scripts/generate-key.sh"
              fi
            '';
          };
        }
      );
    };
}
