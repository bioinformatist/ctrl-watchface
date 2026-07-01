{
  lib,
  stdenv,
  fetchurl,
  unzip,
  autoPatchelfHook,
  makeWrapper,
  wrapGAppsHook,
  jdk17,
  glib,
  gtk3,
  gdk-pixbuf,
  pango,
  cairo,
  atk,
  freetype,
  fontconfig,
  libpng,
  libjpeg,
  libjpeg8,
  expat,
  zlib,
  libsecret,
  libusb1,
  systemdLibs,
  libxkbcommon,
  xorg,
  webkitgtk,
  libsoup,
  glib-networking,
  librsvg,
  gsettings-desktop-schemas,
  adwaita-icon-theme,
  hicolor-icon-theme,
  shared-mime-info,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "connectiq";
  version = "9.2.0";

  src = fetchurl {
    url = "https://developer.garmin.com/downloads/connect-iq/sdks/connectiq-sdk-lin-9.2.0-2026-06-09-92a1605b2.zip";
    hash = "sha256-SQfYRVtlHFoAqGXjZMxPGSHAVbknnHyGNMenpnc7VZM=";
  };

  nativeBuildInputs = [
    unzip
    autoPatchelfHook
    makeWrapper
    wrapGAppsHook
  ];

  dontWrapGApps = true;

  buildInputs = [
    stdenv.cc.cc.lib
    glib
    gtk3
    gdk-pixbuf
    pango
    cairo
    atk
    freetype
    fontconfig
    libpng
    libjpeg
    libjpeg8
    expat
    zlib
    libsecret
    libusb1
    systemdLibs
    libxkbcommon
    xorg.libX11
    xorg.libXext
    xorg.libXxf86vm
    xorg.libSM
    xorg.libICE
    webkitgtk
    libsoup
    glib-networking
    librsvg
    gsettings-desktop-schemas
    adwaita-icon-theme
    hicolor-icon-theme
    shared-mime-info
  ];

  dontConfigure = true;
  dontBuild = true;

  unpackPhase = ''
    runHook preUnpack
    mkdir sdk
    unzip -q "$src" -d sdk
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/opt/connectiq" "$out/bin" "$out/libexec"
    cp -r sdk/* "$out/opt/connectiq/"
    chmod -R u+w "$out/opt/connectiq"

    compiler_tools="monkeyc monkeydo monkeydoc monkeygraph monkeym barrelbuild barreltest mdd era"

    for tool in $compiler_tools connectiq; do
      if [ -f "$out/opt/connectiq/bin/$tool" ]; then
        chmod +x "$out/opt/connectiq/bin/$tool"
      fi
    done

    for tool in $compiler_tools; do
      if [ -f "$out/opt/connectiq/bin/$tool" ]; then
        substituteInPlace "$out/opt/connectiq/bin/$tool" \
          --replace "java " 'java -Duser.home="$HOME" '
      fi
    done

    cat > "$out/libexec/ciq-launch" <<'EOF'
#!${stdenv.shell}
tool=$(basename "$0")
export PATH="${jdk17}/bin:$PATH"
store="${placeholder "out"}/opt/connectiq/bin"
cache="''${XDG_CACHE_HOME:-$HOME/.cache}/connectiq/$(basename "${placeholder "out"}")/bin"

if [ ! -e "$cache/.ready" ]; then
  mkdir -p "$cache"
  for file in "$store"/*; do
    name=$(basename "$file")
    if [ "$name" = monkeybrains.jar ]; then
      cp -f "$file" "$cache/$name"
    else
      ln -sfn "$file" "$cache/$name"
    fi
  done
  touch "$cache/.ready"
fi

exec "$cache/$tool" "$@"
EOF
    chmod +x "$out/libexec/ciq-launch"

    for tool in $compiler_tools; do
      if [ -f "$out/opt/connectiq/bin/$tool" ]; then
        ln -s ../libexec/ciq-launch "$out/bin/$tool"
      fi
    done

    runHook postInstall
  '';

  postFixup = ''
    makeWrapper "$out/opt/connectiq/bin/connectiq" "$out/bin/connectiq" \
      --prefix PATH : ${lib.makeBinPath [ jdk17 ]} \
      --set GDK_BACKEND x11 \
      --unset WAYLAND_DISPLAY \
      --set GIO_EXTRA_MODULES "${glib-networking}/lib/gio/modules" \
      "''${gappsWrapperArgs[@]}"
  '';

  meta = {
    description = "Garmin Connect IQ SDK compiler and simulator";
    homepage = "https://developer.garmin.com/connect-iq/";
    license = lib.licenses.unfree;
    mainProgram = "monkeyc";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [
      binaryNativeCode
      binaryBytecode
    ];
  };
})
