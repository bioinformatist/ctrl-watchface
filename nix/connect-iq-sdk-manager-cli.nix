{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule (finalAttrs: {
  pname = "connect-iq-sdk-manager-cli";
  version = "0.8.4";

  src = fetchFromGitHub {
    owner = "lindell";
    repo = "connect-iq-sdk-manager-cli";
    rev = "v${finalAttrs.version}";
    hash = "sha256-NEzy+lvBAvrapR6lq7k8b/3N4Os3Q7Wx4Vfv5qcjJiU=";
  };

  vendorHash = "sha256-hkYgYVOYx18GMF8RpiRBmNtwd+uhZn197LlpdwfqW8c=";

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${finalAttrs.version}"
  ];

  doCheck = false;

  postInstall = ''
    ln -s "$out/bin/connect-iq-sdk-manager-cli" "$out/bin/connect-iq-sdk-manager"
  '';

  meta = {
    description = "Headless Garmin Connect IQ SDK Manager";
    homepage = "https://github.com/lindell/connect-iq-sdk-manager-cli";
    license = lib.licenses.mit;
    mainProgram = "connect-iq-sdk-manager-cli";
    platforms = lib.platforms.linux;
  };
})
